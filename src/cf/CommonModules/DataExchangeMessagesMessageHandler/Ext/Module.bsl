///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Gets a list of message handlers that this subsystem processes.
// 
// Parameters:
//  Handlers - ValueTable -  for the composition of the fields, see the Exchange of messages.A new table of message processors.
// 
Procedure GetMessagesChannelsHandlers(Handlers) Export
	
	AddMessageChannelHandler("DataExchange\ApplicationSoftware\ExchangeCreation",                 DataExchangeMessagesMessageHandler, Handlers);
	AddMessageChannelHandler("DataExchange\ApplicationSoftware\DeleteExchange",                 DataExchangeMessagesMessageHandler, Handlers);
	AddMessageChannelHandler("DataExchange\ApplicationSoftware\SetDataAreaPrefix", DataExchangeMessagesMessageHandler, Handlers);
	
EndProcedure

// Processes the message body from the channel according to the algorithm of the current message channel.
//
// Parameters:
//  MessagesChannel - String -  ID of the message channel from which the message was received.
//  Body  - Arbitrary -  body of the message received from the channel to be processed.
//  Sender    - ExchangePlanRef.MessagesExchange -  the endpoint that is the sender of the message.
//
Procedure ProcessMessage(MessagesChannel, Body, Sender) Export
	
	Try
		
		SetDataArea(Body.DataArea);
		
		If MessagesChannel = "DataExchange\ApplicationSoftware\ExchangeCreation" Then
			
			CreateDataExchangeInInfobase(
									Sender,
									Body.Settings,
									Body.NodeFiltersSetting,
									Body.DefaultNodeValues,
									Body.ThisNodeCode,
									Body.NewNodeCode);
			
		ElsIf MessagesChannel = "DataExchange\ApplicationSoftware\DeleteExchange" Then
			
			DeleteDataExchangeFromInfobase(Sender, Body.ExchangePlanName, Body.NodeCode, Body.DataArea);
			
		ElsIf MessagesChannel = "DataExchange\ApplicationSoftware\SetDataAreaPrefix" Then
			
			SetDataAreaPrefix(Body.Prefix);
			
		EndIf;
		
	Except
		CancelDataAreaSetup();
		Raise;
	EndTry;
	
	CancelDataAreaSetup();
	
EndProcedure

#EndRegion

#Region Private

// For compatibility, if the correspondent has a BSP version lower than BSP 2.1.2
//
Procedure CreateDataExchangeInInfobase(Sender, Settings, NodeFiltersSetting, DefaultNodeValues, ThisNodeCode, NewNodeCode)
	
	// 
	Directory = New File(Settings.FILEDataExchangeDirectory);
	
	If Not Directory.Exists() Then
		
		Try
			CreateDirectory(Directory.FullName);
		Except
			
			// 
			SendMessageExchangeCreationError(Number(ThisNodeCode), Number(NewNodeCode),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()), Sender);
			
			WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Return;
		EndTry;
	EndIf;
	
	BeginTransaction();
	Try
		
		CorrespondentDataArea = Number(NewNodeCode);
		ExchangePlanName              = Settings.ExchangePlanName;
		CorrespondentCode           = DataExchangeSaaS.ExchangePlanNodeCodeInService(CorrespondentDataArea);
		CorrespondentDescription  = Settings.SecondInfobaseDescription;
		NodeFiltersSetting      = New Structure;
		
		CorrespondentEndpoint = DataExchangeSaaS.EndpointsExchangePlanManager().FindByCode(
			Settings.CorrespondentEndpoint);
		
		If CorrespondentEndpoint.IsEmpty() Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Endpoint with ID %1 not found in peer infobase.';"),
				Settings.CorrespondentEndpoint);
		EndIf;
		
		// 
		ConnectionSettings = New Structure;
		ConnectionSettings.Insert("ExchangePlanName",              ExchangePlanName);
		ConnectionSettings.Insert("CorrespondentCode",           CorrespondentCode);
		ConnectionSettings.Insert("CorrespondentDescription",  CorrespondentDescription);
		ConnectionSettings.Insert("CorrespondentEndpoint", CorrespondentEndpoint);
		ConnectionSettings.Insert("Settings",                   NodeFiltersSetting);
		ConnectionSettings.Insert("Prefix",                     "");
		ConnectionSettings.Insert("Peer"); // 
		
		DataExchangeSaaS.CreateExchangeSetting(
			ConnectionSettings,
			,
			True);
			
		Peer = ConnectionSettings.Peer;
		
		// 
		RecordStructure = New Structure;
		RecordStructure.Insert("Peer", Peer);
		RecordStructure.Insert("CorrespondentEndpoint", CorrespondentEndpoint);
		RecordStructure.Insert("DataExchangeDirectory", Settings.FILERelativeInformationExchangeDirectory);
		
		InformationRegisters.DataAreaExchangeTransportSettings.UpdateRecord(RecordStructure);
		
		// 
		DataExchangeServer.RegisterDataForInitialExport(Peer);
		
		// 
		SendMessageOperationSuccessful(Number(ThisNodeCode), Number(NewNodeCode), Sender);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		// 
		SendMessageExchangeCreationError(Number(ThisNodeCode), Number(NewNodeCode),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()), Sender);
		
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
EndProcedure

// For compatibility, if the correspondent has a BSP version lower than BSP 2.1.2
//
Procedure DeleteDataExchangeFromInfobase(Sender, ExchangePlanName, NodeCode, DataArea)
	
	// 
	SendMessageOperationSuccessful(DataArea, Number(NodeCode), Sender);
	
EndProcedure

Procedure SetDataAreaPrefix(Val Prefix)
	
	If Common.SubsystemExists("CloudTechnology") Then
	
		SetPrivilegedMode(True);
		
		ManagerOfConstant = Constants["DataAreaPrefix"];
		
		If IsBlankString(ManagerOfConstant.Get()) Then
			
			ManagerOfConstant.Set(Format(Prefix, "ND=2; NLZ=; NG=0"));
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure SetDataArea(Val DataArea)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	
	ModuleSaaSOperations.SetSessionSeparation(True, DataArea);
	
EndProcedure

Procedure CancelDataAreaSetup()
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	
	ModuleSaaSOperations.SetSessionSeparation(False);
	
EndProcedure

Procedure SendMessageOperationSuccessful(Code1, Code2, Endpoint)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleMessagesExchange = Common.CommonModule("MessagesExchange");
	
	BeginTransaction();
	Try
		
		Body = New Structure("Code1, Code2", Code1, Code2);
		
		ModuleMessagesExchange.SendMessage("DataExchange\ApplicationSoftware\Response\ActionSuccessful", Body, Endpoint);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(EventLogEventMessagesSending(),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

Procedure SendMessageExchangeCreationError(Code1, Code2, ErrorString, Endpoint)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleMessagesExchange = Common.CommonModule("MessagesExchange");
	
	BeginTransaction();
	Try
		
		Body = New Structure("Code1, Code2, ErrorString", Code1, Code2, ErrorString);
		
		ModuleMessagesExchange.SendMessage("DataExchange\ApplicationSoftware\Response\ExchangeCreationError", Body, Endpoint);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(EventLogEventMessagesSending(),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

Procedure AddMessageChannelHandler(Canal, ChannelHandler, Handlers)
	
	Handler = Handlers.Add();
	Handler.Canal = Canal;
	Handler.Handler = ChannelHandler;
	
EndProcedure

Function EventLogEventMessagesSending()
	
	Return NStr("en = 'Send messages';", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion
