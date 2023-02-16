///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Parameters:
//  Interval - Number
//
Procedure AttachServerNotificationReceiptCheckHandler(Interval = 1) Export
	
	If Interval < 1 Then
		Interval = 1;
	ElsIf Interval > 60 Then
		Interval = 60;
	EndIf;
	
	AttachIdleHandler("ServerNotificationsReceiptCheckHandler", Interval, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart(Parameters) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If Not ClientParameters.Property("ServerNotifications") Then
		Return;
	EndIf;
	
	ServerNotificationsParameters = ClientParameters.ServerNotifications; // See ServerNotifications.ServerNotificationsParametersThisSession
	DataReceiptStatus = DataReceiptStatus();
	FillPropertyValues(DataReceiptStatus, ServerNotificationsParameters);
	Parameters.RetrievedClientParameters.Insert("ServerNotifications");
	Parameters.CountOfReceivedClientParameters = Parameters.CountOfReceivedClientParameters + 1;
	
	SessionDate = CommonClient.SessionDate();
	DataReceiptStatus.StatusUpdateDate = SessionDate;
	DataReceiptStatus.LastReceivedMessageDate = SessionDate;
	DataReceiptStatus.LastRecurringDataSendDate = SessionDate;
	
	DataReceiptStatus.IsCheckAllowed = True;
	AttachServerNotificationReceiptCheckHandler();
	
EndProcedure

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	DataReceiptStatus = DataReceiptStatus();
	
	If DataReceiptStatus.ServiceAdministratorSession Then
		Return;
	EndIf;
	
	DataReceiptStatus.IsRecurringDataSendEnabled = True;
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckAndReceiveServerNotifications() Export
	
	DataReceiptStatus = DataReceiptStatus();
	If Not DataReceiptStatus.IsCheckAllowed Then
		Return;
	EndIf;
	
	Interval = DataReceiptStatus.MinimumPeriod;
	AreChatsActive = DataReceiptStatus.CollaborationSystemConnected
		And DataReceiptStatus.IsNewPersonalMessageHandlerAttached
		And DataReceiptStatus.LastReceivedMessageDate + 60 > CommonClient.SessionDate();
	
	AdditionalParameters = New Map;
	ChatsParametersKeyName = "StandardSubsystems.Core.ChatsIDs";
	
	TimeConsumingOperationsClient.BeforeRecurringClientDataSendToServer(AdditionalParameters,
		AreChatsActive, Interval);
	
	CurrentSessionDate = CommonClient.SessionDate();
	ShouldSendDataRecurrently = False;
	
	If DataReceiptStatus.LastRecurringDataSendDate + 60 < CurrentSessionDate Then
		If DataReceiptStatus.IsRecurringDataSendEnabled Then
			SSLSubsystemsIntegrationClient.BeforeRecurringClientDataSendToServer(AdditionalParameters);
			CommonClientOverridable.BeforeRecurringClientDataSendToServer(AdditionalParameters);
			ShouldSendDataRecurrently = True;
		EndIf;
		DataReceiptStatus.LastRecurringDataSendDate = CurrentSessionDate;
		MessagesForEventLog = ApplicationParameters["StandardSubsystems.MessagesForEventLog"];
		If DataReceiptStatus.PersonalChatID = Undefined
		   And CollaborationSystem.InfoBaseRegistered() Then
			AdditionalParameters.Insert(ChatsParametersKeyName, False);
		EndIf;
	EndIf;
	
	If AreNotificationsReceived(DataReceiptStatus)
	   And Not ValueIsFilled(AdditionalParameters)
	   And Not ValueIsFilled(MessagesForEventLog) Then
		
		AttachServerNotificationReceiptCheckHandler(Interval);
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.UsersSessions") Then
		ModuleIBConnectionsClient = CommonClient.CommonModule("IBConnectionsClient");
		ModuleIBConnectionsClient.BeforeRecurringClientDataSendToServer(AdditionalParameters);
	EndIf;
	
	CommonCallParameters = CommonServerCallNewParameters();
	CommonCallParameters.LastNotificationDate    = DataReceiptStatus.LastNotificationDate;
	CommonCallParameters.MinCheckInterval   = DataReceiptStatus.MinimumPeriod;
	CommonCallParameters.AdditionalParameters     = AdditionalParameters;
	CommonCallParameters.ShouldSendDataRecurrently = ShouldSendDataRecurrently;
	CommonCallParameters.MessagesForEventLog =
		ApplicationParameters["StandardSubsystems.MessagesForEventLog"];
	
	CommonCallResult = ServerNotificationsInternalServerCall.SessionUndeliveredServerNotifications(
		CommonCallParameters);
	
	If CommonCallParameters.MessagesForEventLog <> Undefined Then
		CommonCallParameters.MessagesForEventLog.Clear();
	EndIf;
	
	AdditionalResults = CommonCallResult.AdditionalResults;
	ChatsIDs = AdditionalResults.Get(ChatsParametersKeyName);
	If ChatsIDs <> Undefined Then
		FillPropertyValues(DataReceiptStatus, ChatsIDs);
		AttachNewMessageHandler(DataReceiptStatus);
	EndIf;
	
	For Each ServerNotification In CommonCallResult.ServerNotifications Do
		ProcessServerNotificationOnClient(DataReceiptStatus, ServerNotification);
	EndDo;
	
	TimeConsumingOperationsClient.AfterRecurringReceiptOfClientDataOnServer(
		AdditionalResults, AreChatsActive, Interval);
	
	If CommonClient.SubsystemExists("StandardSubsystems.UsersSessions") Then
		ModuleIBConnectionsClient = CommonClient.CommonModule("IBConnectionsClient");
		ModuleIBConnectionsClient.AfterRecurringReceiptOfClientDataOnServer(
			AdditionalResults);
	EndIf;
	
	If ShouldSendDataRecurrently Then
		SSLSubsystemsIntegrationClient.AfterRecurringReceiptOfClientDataOnServer(
			AdditionalResults);
		CommonClientOverridable.AfterRecurringReceiptOfClientDataOnServer(
			AdditionalResults);
	EndIf;
	
	DataReceiptStatus.LastNotificationDate        = CommonCallResult.LastNotificationDate;
	DataReceiptStatus.MinimumPeriod               = CommonCallResult.MinCheckInterval;
	DataReceiptStatus.CollaborationSystemConnected = CommonCallResult.CollaborationSystemConnected;
	DataReceiptStatus.StatusUpdateDate         = CommonClient.SessionDate();
	
	If Interval > DataReceiptStatus.MinimumPeriod Then
		Interval = DataReceiptStatus.MinimumPeriod;
	EndIf;
	
	AttachServerNotificationReceiptCheckHandler(Interval);
	
EndProcedure

Procedure ProcessServerNotificationOnClient(DataReceiptStatus, ServerNotification)
	
	If IsNotificationReceived(DataReceiptStatus, ServerNotification) Then
		Return;
	EndIf;
	
	NameOfAlert = ServerNotification.NameOfAlert;
	Result     = ServerNotification.Result;
	
	Notification = DataReceiptStatus.Notifications.Get(NameOfAlert);
	If Notification = Undefined Then
		Return;
	EndIf;
	
	DataProcessorModule = CommonClient.CommonModule(Notification.NotificationReceiptModuleName);
	Try
		DataProcessorModule.OnReceiptServerNotification(NameOfAlert, Result);
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot execute the ""%1"" procedure due to:
			           |%2';"),
			Notification.NotificationReceiptModuleName + ".OnReceiptServerNotification",
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		EventLogClient.AddMessageForEventLog(
			NStr("en = 'Server notifications.An error occurred when processing the received message';",
				CommonClient.DefaultLanguageCode()),
			"Error",
			ErrorText);
	EndTry;
	
EndProcedure

Function AreNotificationsReceived(DataReceiptStatus)
	
	AttachNewMessageHandler(DataReceiptStatus);
	
	Boundary = DataReceiptStatus.StatusUpdateDate + DataReceiptStatus.MinimumPeriod;
	
	Inventory = Boundary - CommonClient.SessionDate();
	
	If Inventory > 0 Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// See NewReceiptStatus
Function DataReceiptStatus() Export
	
	AppParameterName = "StandardSubsystems.Core.ServerNotifications";
	DataReceiptStatus = ApplicationParameters.Get(AppParameterName);
	If DataReceiptStatus = Undefined Then
		DataReceiptStatus = NewReceiptStatus();
		ApplicationParameters.Insert(AppParameterName, DataReceiptStatus);
	EndIf;
	
	Return DataReceiptStatus;
	
EndFunction

// Returns:
//  Structure:
//   * LastNotificationDate - Date
//   * MinCheckInterval - Number
//   * AdditionalParameters - Map
//   * MessagesForEventLog - 
//   * ShouldSendDataRecurrently - Boolean
//
Function CommonServerCallNewParameters() Export
	
	Result = New Structure;
	Result.Insert("LastNotificationDate",  '00010101');
	Result.Insert("MinCheckInterval", 60);
	Result.Insert("AdditionalParameters", New Map);
	Result.Insert("MessagesForEventLog", Undefined);
	Result.Insert("ShouldSendDataRecurrently", False);
	
	Return Result;
	
EndFunction

// Returns:
//  Structure:
//   * IsCheckAllowed - Boolean -
//   * ServiceAdministratorSession - Boolean
//   * IsRecurringDataSendEnabled - Boolean -
//   * Checking - Boolean
//   * SessionKey - See ServerNotifications.SessionKey
//   * IBUserID - UUID
//   * StatusUpdateDate - Date
//   * LastReceivedMessageDate - Date
//   * MinimumPeriod - Number -
//   * LastNotificationDate - Date
//   * Notifications - See CommonOverridable.OnAddServerNotifications.Notifications
//   * ReceivedNotifications - Array of String -
//   * CollaborationSystemConnected - Boolean
//   * PersonalChatID - Undefined -
//                                    - CollaborationSystemConversationID - 
//        
//
//   * GlobalChatID - Undefined -
//                                   - CollaborationSystemConversationID - 
//        
//   * PersonalChatID - String -
//        
//   * GlobalChatID  - String -
//        
//   * IsNewPersonalMessageHandlerAttached - Boolean
//   * IsNewGlobalMessageHandlerAttached - Boolean
//   * IsNewPersonalMessageHandlerAttachStarted - Boolean
//   * IsNewGlobalMessageHandlerAttachStarted - Boolean
//   * LastRecurringDataSendDate - Date
//
Function NewReceiptStatus()
	
	State = New Structure;
	State.Insert("IsCheckAllowed", False);
	State.Insert("ServiceAdministratorSession", False);
	State.Insert("IsRecurringDataSendEnabled", False);
	State.Insert("Checking", False);
	State.Insert("SessionKey", "");
	State.Insert("IBUserID",
		CommonClientServer.BlankUUID());
	State.Insert("StatusUpdateDate", '00010101');
	State.Insert("LastReceivedMessageDate", '00010101');
	State.Insert("MinimumPeriod", 60);
	State.Insert("LastNotificationDate", '00010101');
	State.Insert("Notifications", New Map);
	State.Insert("ReceivedNotifications", New Array);
	State.Insert("CollaborationSystemConnected", False);
	State.Insert("PersonalChatID", Undefined);
	State.Insert("GlobalChatID", Undefined);
	State.Insert("IsNewPersonalMessageHandlerAttached", False);
	State.Insert("IsNewGlobalMessageHandlerAttached", False);
	State.Insert("IsNewPersonalMessageHandlerAttachStarted", False);
	State.Insert("IsNewGlobalMessageHandlerAttachStarted", False);
	State.Insert("LastRecurringDataSendDate", '00010101');
	
	Return State;
	
EndFunction

Procedure AttachNewMessageHandler(DataReceiptStatus)
	
	If DataReceiptStatus.PersonalChatID <> Undefined
	   And Not DataReceiptStatus.IsNewPersonalMessageHandlerAttached
	   And Not DataReceiptStatus.IsNewPersonalMessageHandlerAttachStarted Then
		
		Context = New Structure("DataReceiptStatus", DataReceiptStatus);
		Try
			CollaborationSystem.BeginAttachNewMessagesHandler(
				New NotifyDescription("AfterAttachingNewPersonalMessageHandler", ThisObject, Context,
					"AfterNewPersonalMessageHandlerAttachError", ThisObject),
				New CollaborationSystemConversationID(DataReceiptStatus.PersonalChatID),
				New NotifyDescription("OnReceiptNewInteractionSystemPersonalMessage", ThisObject, Context,
					"OnInteractionSystemNewPersonalMessageReceiptError", ThisObject),
				Undefined);
		Except
			AfterNewPersonalMessageHandlerAttachError(ErrorInfo(), False, Context);
		EndTry;
	EndIf;
	
	If DataReceiptStatus.GlobalChatID <> Undefined
	   And Not DataReceiptStatus.IsNewGlobalMessageHandlerAttached
	   And Not DataReceiptStatus.IsNewGlobalMessageHandlerAttachStarted Then
		
		Context = New Structure("DataReceiptStatus", DataReceiptStatus);
		Try
			CollaborationSystem.BeginAttachNewMessagesHandler(
				New NotifyDescription("AfterAttachingNewGroupMessageHandler", ThisObject, Context,
					"AfterNewGlobalMessageHandlerAttachError", ThisObject),
				New CollaborationSystemConversationID(DataReceiptStatus.GlobalChatID),
				New NotifyDescription("OnReceiptNewInteractionSystemGlobalMessage", ThisObject, Context,
					"OnInteractionSystemNewGlobalMessageReceiptError", ThisObject),
				Undefined);
		Except
			AfterNewGlobalMessageHandlerAttachError(ErrorInfo(), False, Context);
		EndTry;
	EndIf;
	
EndProcedure

Procedure AfterAttachingNewPersonalMessageHandler(Context) Export
	
	Context.DataReceiptStatus.IsNewPersonalMessageHandlerAttachStarted = False;
	Context.DataReceiptStatus.IsNewPersonalMessageHandlerAttached = True;
	
EndProcedure

Procedure AfterNewPersonalMessageHandlerAttachError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	Context.DataReceiptStatus.IsNewPersonalMessageHandlerAttachStarted = False;
	
	EventLogClient.AddMessageForEventLog(
		NStr("en = 'Server notifications.An error occurred when connecting the handler of new personal messages';",
			CommonClient.DefaultLanguageCode()),
		"Error",
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
EndProcedure

Procedure OnReceiptNewInteractionSystemPersonalMessage(Message, Context) Export
	
	OnReceiptNewInteractionSystemMessage(Message, Context);
	
EndProcedure

Procedure OnInteractionSystemNewPersonalMessageReceiptError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	EventLogClient.AddMessageForEventLog(
		NStr("en = 'Server notifications.An error occurred when receiving a new personal message';",
			CommonClient.DefaultLanguageCode()),
		"Error",
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
EndProcedure

Procedure AfterAttachingNewGroupMessageHandler(Context) Export
	
	Context.DataReceiptStatus.IsNewGlobalMessageHandlerAttachStarted = False;
	Context.DataReceiptStatus.IsNewGlobalMessageHandlerAttached = True;
	
EndProcedure

Procedure AfterNewGlobalMessageHandlerAttachError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	Context.DataReceiptStatus.IsNewGlobalMessageHandlerAttachStarted = False;
	
	EventLogClient.AddMessageForEventLog(
		NStr("en = 'Server notifications.An error occurred when connecting the handler of new common messages';",
			CommonClient.DefaultLanguageCode()),
		"Error",
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
EndProcedure

Procedure OnReceiptNewInteractionSystemGlobalMessage(Message, Context) Export
	
	OnReceiptNewInteractionSystemMessage(Message, Context);
	
EndProcedure

Procedure OnInteractionSystemNewGlobalMessageReceiptError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	EventLogClient.AddMessageForEventLog(
		NStr("en = 'Server notifications.An error occurred when receiving a new common message';",
			CommonClient.DefaultLanguageCode()),
		"Error",
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
EndProcedure

// Parameters:
//  Message - CollaborationSystemMessage
//  Context  - Structure:
//    * DataReceiptStatus - See NewReceiptStatus
//
Procedure OnReceiptNewInteractionSystemMessage(Message, Context)
	
	DataReceiptStatus = Context.DataReceiptStatus;
	
	If Not DataReceiptStatus.IsCheckAllowed
	 Or ApplicationParameters = Undefined Then
		Return;
	EndIf;
	
	DataReceiptStatus.LastReceivedMessageDate = CommonClient.SessionDate();
	
	Try
		Data = Message.Data; // See ServerNotifications.MessageNewData
	Except
		ErrorInfo = ErrorInfo();
		LongDesc = New Structure;
		LongDesc.Insert("Date", Message.Date);
		LongDesc.Insert("Id", String(Message.ID));
		LongDesc.Insert("Conversation", String(Message.Conversation));
		LongDesc.Insert("Text", TrimAll(Message.Text));
		LongDesc.Insert("DetailErrorDescription",
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		ServerNotificationsInternalServerCall.LogErrorGettingDataFromMessage(LongDesc);
		Return;
	EndTry;
	
	If TypeOf(Data) <> Type("Structure")
	 Or Not Data.Property("NameOfAlert") Then
		Return;
	EndIf;
	
	If Data.NameOfAlert <> "NoServerNotifications" Then
		If Data.SMSMessageRecipients <> Undefined Then
			SessionsKeys = Data.SMSMessageRecipients.Get(DataReceiptStatus.IBUserID);
			If TypeOf(SessionsKeys) <> Type("Array")
			 Or SessionsKeys.Find(DataReceiptStatus.SessionKey) = Undefined
			   And SessionsKeys.Find("*") = Undefined Then
				Return;
			EndIf;
		EndIf;
		ProcessServerNotificationOnClient(DataReceiptStatus, Data);
		If Not Data.WasSentFromQueue Then
			Return;
		EndIf;
	EndIf;
	
	LastNotificationDate = Data.Errors.Get(DataReceiptStatus.IBUserID);
	If LastNotificationDate = Undefined Then
		LastNotificationDate = Data.Errors.Get("AllUsers");
		If LastNotificationDate = Undefined Then
			LastNotificationDate = Data.AddedOn;
			DataReceiptStatus.StatusUpdateDate = CommonClient.SessionDate();
		EndIf;
	EndIf;
	If DataReceiptStatus.LastNotificationDate < LastNotificationDate Then
		DataReceiptStatus.LastNotificationDate = LastNotificationDate;
	EndIf;
	
EndProcedure

Function IsNotificationReceived(DataReceiptStatus, ServerNotification)
	
	If ServerNotification.AddedOn < DataReceiptStatus.LastNotificationDate Then
		Return True;
	EndIf;
	
	ReceivedNotifications = DataReceiptStatus.ReceivedNotifications;
	
	If ReceivedNotifications.Find(ServerNotification.NotificationID) <> Undefined Then
		Return True;
	EndIf;
	
	ReceivedNotifications.Add(ServerNotification.NotificationID);
	If ReceivedNotifications.Count() > 100 Then
		ReceivedNotifications.Delete(0);
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion
