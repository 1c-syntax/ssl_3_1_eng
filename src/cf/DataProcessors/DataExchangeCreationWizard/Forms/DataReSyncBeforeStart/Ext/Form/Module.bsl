///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InfobaseNode = DataExchangeServer.MasterNode();
	IsStandaloneWorkplace = DataExchangeServer.IsStandaloneWorkplace();
	UserName = InfoBaseUsers.CurrentUser().Name;
	
	If InfobaseNode = Undefined Then
		
		Raise NStr("en = 'The infobase is neither a standalone workstation nor a distributed infobase.'", Common.DefaultLanguageCode());
		
	EndIf;
	
	If IsStandaloneWorkplace Then
		Items.ConnectionParametersPages.CurrentPage = Items.SWPPage;
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		AccountPasswordRecoveryAddress = ModuleStandaloneMode.AccountPasswordRecoveryAddress();
		TimeConsumingOperationAllowed = True;
				
		If ExchangeMessagesTransport.DataSynchronizationPasswordSpecified(InfobaseNode) Then
			AuthenticationData = ExchangeMessagesTransport.DataSynchronizationPassword(InfobaseNode);
			Password = AuthenticationData.Password;
		EndIf;	
		
	EndIf;
	
	FillInInformationAboutMessageFromArchiveAtServer();
	
	NodeNameLabel = NStr("en = 'Cannot install the application update received from
		|""%1"".
		|See <a href = ""%2"">Event log</a> for technical information.'");
	Items.NodeNameHelpText.Title = 
		StringFunctions.FormattedString(NodeNameLabel, String(InfobaseNode), "EventLog");
	
	SetFormItemsView();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("FillInInformationAboutMessageFromArchive", 60, False);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NodeNameHelpTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters,,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ContinueUploadingMessageFromArchiveOnChange(Item)
	
	Items.ConnectionParametersPages.Visible = Not ContinueUploadingMessageFromArchive;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SyncAndContinue(Command)
	
	WarningText = "";
	HasErrors = False;
	
	CheckUpdateRequired();
	
	If UpdateStatus = "NoUpdateRequired" Then
		
		SynchronizeAndContinueWithoutIBUpdate();
		
	ElsIf UpdateStatus = "InfobaseUpdate" Then
		
		SynchronizeAndContinueWithIBUpdate();
		
	ElsIf UpdateStatus = "ConfigurationUpdate" Then
		
		WarningText = NStr("en = 'Changes that have not been applied yet were received from the main node.
			|Open Designer and update the database configuration.'");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotSyncAndContinue(Command)
	
	DoNotSyncAndContinueAtServer();
	
	Close("Continue");
	
EndProcedure

&AtClient
Procedure ExitApplication(Command)
	
	If ValueIsFilled(ParametersOfExchangeHandler) Then
		CancelJobExecution(ParametersOfExchangeHandler.OperationID);
	EndIf;

	DetachIdleHandler("WhileWaitingForDataExchangeMessageToLoadWithoutUpdatingInfobase");
	DetachIdleHandler("WhileWaitingForUpdateDataExchangeMessageToLoad");

	Close();
		
EndProcedure

&AtClient
Procedure ConnectionParameters(Command)

	FormParameters = New Structure("Peer", InfobaseNode);
	
	OpenForm("Catalog.ExchangeMessageTransportSettings.Form.TransportSettingPanel",
		FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ForgotPassword(Command)
	ExchangeMessagesTransportClient.OpenInstructionHowToChangeDataSynchronizationPassword(AccountPasswordRecoveryAddress);
EndProcedure

&AtClient
Procedure OpenMessageFromArchive(Command)
	
	If Not ValueIsFilled(PeriodOfRecordingArchiveMessage) Then
		CommonClient.MessageToUser(NStr("en = 'The archived message is missing'"));
		Return;
	EndIf;
	
	RecordStructure = New Structure("Period, InfobaseNode", PeriodOfRecordingArchiveMessage, InfobaseNode);
	
	ValueType = Type("InformationRegisterRecordKey.ArchiveOfExchangeMessages");
	WriteParameters = New Array(1);
	WriteParameters[0] = RecordStructure;
	
	RecordKey = New(ValueType, WriteParameters);
	
	WriteParameters = New Structure;
	WriteParameters.Insert("Key", RecordKey);
	
	OpenForm("InformationRegister.ArchiveOfExchangeMessages.Form.RecordForm", 
		WriteParameters,
		ThisObject,
		UUID);
	
EndProcedure

#EndRegion

#Region Private

#Region NoInfobaseUpdateScenario

&AtClient
Procedure SynchronizeAndContinueWithoutIBUpdate()
	
	AttachIdleHandler("AtBeginningOfDownloadOfDataExchangeMessageWithoutUpdatingInfobase", 0.1, True);
	
	SettingUpFormElementsForLongTermOperation(True);

EndProcedure

&AtClient
Procedure AtBeginningOfDownloadOfDataExchangeMessageWithoutUpdatingInfobase()
	
	ContinueWait = True;
	WhenYouStartDownloadingDataExchangeMessageWithoutUpdatingInfobaseAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitIdleHandlerParameters(
			ParametersOfExchangeWaitingHandler);
		
		AttachIdleHandler("WhileWaitingForDataExchangeMessageToLoadWithoutUpdatingInfobase",
			ParametersOfExchangeWaitingHandler.CurrentInterval, True);
	Else
		AttachIdleHandler("AtEndOfLoadingDataExchangeMessageWithoutUpdatingInfobase", 0.1, True);
	EndIf;

EndProcedure

&AtServer
Procedure WhenYouStartDownloadingDataExchangeMessageWithoutUpdatingInfobaseAtServer(ContinueWait) 
	
	AuthenticationData = New Structure;
	
	If IsStandaloneWorkplace Then
		AuthenticationData.Insert("UserName", UserName);
		AuthenticationData.Insert("Password", Password);
	EndIf;
			
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ContinueUploadingMessageFromArchive", ContinueUploadingMessageFromArchive);
	ProcedureParameters.Insert("InfobaseNode", InfobaseNode);
	ProcedureParameters.Insert("AuthenticationData",   AuthenticationData);
	ProcedureParameters.Insert("HasErrors",             False);
	
	OperationStartDate = CurrentSessionDate();
	
	ParametersOfExchangeHandler = Undefined;
	
	ModuleDataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleDataExchangeCreationWizard.AtBeginningOfDownloadOfDataExchangeMessageWithoutUpdatingInfobase(ProcedureParameters,
		ParametersOfExchangeHandler, ContinueWait);      
		
EndProcedure

&AtClient
Procedure WhileWaitingForDataExchangeMessageToLoadWithoutUpdatingInfobase()
	
	ContinueWait = False;
	WhileWaitingForDataExchangeMessageToLoadWithoutUpdatingInfobaseAtServer(ParametersOfExchangeHandler, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(ParametersOfExchangeWaitingHandler);
		
		AttachIdleHandler("WhileWaitingForDataExchangeMessageToLoadWithoutUpdatingInfobase",
			ParametersOfExchangeWaitingHandler.CurrentInterval, True);
	Else
		AttachIdleHandler("AtEndOfLoadingDataExchangeMessageWithoutUpdatingInfobase", 0.1, True);
	EndIf;

EndProcedure

&AtServerNoContext
Procedure WhileWaitingForDataExchangeMessageToLoadWithoutUpdatingInfobaseAtServer(HandlerParameters, ContinueWait)
	
	ModuleDataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleDataExchangeCreationWizard.WhileWaitingForMessageToLoadBeforeUpdatingInformationBase(HandlerParameters, ContinueWait);
	
EndProcedure

&AtClient
Procedure AtEndOfLoadingDataExchangeMessageWithoutUpdatingInfobase()
	
	ErrorMessage = "";
	
	WhenDownloadOfDataExchangeMessageIsCompletedWithoutUpdatingInfobaseATServer(ParametersOfExchangeHandler, ErrorMessage);
	
	If Not IsBlankString(ErrorMessage) Then
		CommonClient.MessageToUser(ErrorMessage,,,, HasErrors);
	EndIf;
	
	SynchronizeAndContinueWithoutIBUpdateCompletion();
	
	SyncAndContinueCompletion();
	
EndProcedure

&AtServerNoContext
Procedure WhenDownloadOfDataExchangeMessageIsCompletedWithoutUpdatingInfobaseATServer(HandlerParameters, ErrorMessage)
	
	CompletionStatus = Undefined;
	
	ModuleDataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleDataExchangeCreationWizard.UponCompletionOfMessageDownloadBeforeUpdatingInformationBase(HandlerParameters, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		If CompletionStatus.Result <> Undefined And CompletionStatus.Result.Cancel Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		EndIf;
	EndIf; 

EndProcedure  

&AtServer
Procedure SynchronizeAndContinueWithoutIBUpdateCompletion()
	
	// The repeat mode should be enabled in the following cases:
	// 1. Metadata with a later configuration version is imported (an infobase update required).
	// - If "Cancel" is set to "True", it cannot proceed as duplicates of generated data might occur.
	// - If "Cancel" is set to "False", an infobase update error might occur requiring re-import of the message.
	// 2. Metadata with the same configuration version is imported (no infobase update required).
	// - If "Cancel" is set to "True" and the startup proceeds, an error might occur
	//   (for example, because predefined items were not imported).
	// - If "Cancel" is set to "False", you can proceed as the import can be done later
	//   (if import fails, you can also import a new exchange message later).
	
	SetPrivilegedMode(True);
	
	If Not HasErrors Then
		
		Return;
		
	ElsIf ConfigurationChanged() Then
		If Not Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(True);
		EndIf;
		WarningText = NStr("en = 'Changes to be applied were received from the main node.
			|Open Designer and update the database configuration.'");
	Else
		
		If InfobaseUpdate.InfobaseUpdateRequired() Then
			EnableDataExchangeMessageImportRecurrenceBeforeStart();
		EndIf;
		
		WarningText = NStr("en = 'Receiving data from the master node is completed with errors.
			|For more information, see the event log.'");
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ScenarioWithInfobaseUpdate

&AtClient
Procedure SynchronizeAndContinueWithIBUpdate()
	
	AttachIdleHandler("AtBeginningOfDownloadMessageExchangesDataWithUpdate", 0.1, True);
	
	SettingUpFormElementsForLongTermOperation(True);
	
EndProcedure

&AtClient
Procedure AtBeginningOfDownloadMessageExchangesDataWithUpdate()
	
	ContinueWait = True;
	AtBeginningOfDownloadUpdateDataExchangeMessageIsAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitIdleHandlerParameters(
			ParametersOfExchangeWaitingHandler);
		
		AttachIdleHandler("WhileWaitingForUpdateDataExchangeMessageToLoad",
			ParametersOfExchangeWaitingHandler.CurrentInterval, True);
	Else
		AttachIdleHandler("WhenDownloadIsCompleteMessageExchangesDataWithUpdate", 0.1, True);
	EndIf;

EndProcedure

&AtServer
Procedure AtBeginningOfDownloadUpdateDataExchangeMessageIsAtServer(ContinueWait) 
	
	AuthenticationData = New Structure;
	
	If IsStandaloneWorkplace Then
		AuthenticationData.Insert("UserName", UserName);
		AuthenticationData.Insert("Password", Password);
	EndIf;

	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ContinueUploadingMessageFromArchive", ContinueUploadingMessageFromArchive);
	ProcedureParameters.Insert("InfobaseNode", InfobaseNode);
	ProcedureParameters.Insert("AuthenticationData",   AuthenticationData);
	ProcedureParameters.Insert("HasErrors",             HasErrors);
	
	OperationStartDate = CurrentSessionDate();
	
	ParametersOfExchangeHandler = Undefined;
	
	ModuleDataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleDataExchangeCreationWizard.AtBeginningOfDownloadMessageExchangesDataWithUpdate(ProcedureParameters,
		ParametersOfExchangeHandler, ContinueWait);      
		
EndProcedure

&AtClient
Procedure WhileWaitingForUpdateDataExchangeMessageToLoad()
	
	ContinueWait = False;
	WhileWaitingForUpdateDataExchangeMessageToLoadAtServer(ParametersOfExchangeHandler, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(ParametersOfExchangeWaitingHandler);
		
		AttachIdleHandler("WhileWaitingForUpdateDataExchangeMessageToLoad",
			ParametersOfExchangeWaitingHandler.CurrentInterval, True);
	Else
		AttachIdleHandler("WhenDownloadIsCompleteMessageExchangesDataWithUpdate", 0.1, True);
	EndIf;

EndProcedure  

&AtServerNoContext
Procedure WhileWaitingForUpdateDataExchangeMessageToLoadAtServer(HandlerParameters, ContinueWait)
	
	ModuleDataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleDataExchangeCreationWizard.WhileWaitingForUpdateDataExchangeMessageToLoad(HandlerParameters, ContinueWait);
	
EndProcedure

&AtClient
Procedure WhenDownloadIsCompleteMessageExchangesDataWithUpdate()
	
	ErrorMessage = "";
	
	WhenDownloadIsCompleteUpdateDataExchangeMessageIsAtServer(ParametersOfExchangeHandler, ErrorMessage);
	
	If Not IsBlankString(ErrorMessage) Then
		CommonClient.MessageToUser(ErrorMessage,,,, HasErrors);
	EndIf;
	
	SynchronizeAndContinueWithIBUpdateCompletion();
	
	SyncAndContinueCompletion();

EndProcedure

&AtServerNoContext
Procedure WhenDownloadIsCompleteUpdateDataExchangeMessageIsAtServer(HandlerParameters, ErrorMessage)
	
	CompletionStatus = Undefined;
	
	ModuleDataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleDataExchangeCreationWizard.WhenDownloadIsCompleteMessageExchangesDataWithUpdate(HandlerParameters, CompletionStatus);
	
	If CompletionStatus.Cancel Then
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		If CompletionStatus.Result <> Undefined And CompletionStatus.Result.Cancel Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		EndIf;
	EndIf;
	
EndProcedure  

&AtServer
Procedure SynchronizeAndContinueWithIBUpdateCompletion()
	
	SetPrivilegedMode(True);
	
	If Not HasErrors Then
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		
		If Not Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(True);
		EndIf;
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart(
			"SkipImportPriorityDataBeforeStart", True);
		
	ElsIf ConfigurationChanged() Then
			
		If Not Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(True);
		EndIf;
		WarningText = NStr("en = 'Changes to be applied were received from the main node.
			|Open Designer and update the database configuration.'");
		
	Else
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		
		EnableDataExchangeMessageImportRecurrenceBeforeStart();
		
		WarningText = NStr("en = 'Receiving data from the master node is completed with errors.
			|For more information, see the event log.'");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region NoSyncScenario

&AtServer
Procedure DoNotSyncAndContinueAtServer()
	
	SetPrivilegedMode(True);
	
	If Not InfobaseUpdate.InfobaseUpdateRequired() Then
		If Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(False);
			DataExchangeServer.ClearDataExchangeMessageFromMasterNode();
		EndIf;
	EndIf;
	
	DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart(
		"SkipImportDataExchangeMessageBeforeStart", True);
	
EndProcedure

#EndRegion

&AtServer
Procedure CheckUpdateRequired()
	
	SetPrivilegedMode(True);
	
	If ConfigurationChanged() Then
		UpdateStatus = "ConfigurationUpdate";
	ElsIf InfobaseUpdate.InfobaseUpdateRequired() Then
		UpdateStatus = "InfobaseUpdate";
	Else
		UpdateStatus = "NoUpdateRequired";
	EndIf;
	
EndProcedure

&AtClient
Procedure SyncAndContinueCompletion()
	
	SetFormItemsView();
	
	If IsBlankString(WarningText) Then
		
		ShowUserNotification(NStr("en = 'Standalone mode'"),
			,
			NStr("en = 'Data resync is complete.'"),
			PictureLib.Information32,
			UserNotificationStatus.Important);
		
		Close("Continue");
	Else
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

// Sets the RetryDataExchangeMessageImportBeforeStart constant value to True.
// Clears exchange messages received from the master node.
//
&AtServer
Procedure EnableDataExchangeMessageImportRecurrenceBeforeStart()
	
	DataExchangeServer.ClearDataExchangeMessageFromMasterNode();
	
	Constants.RetryDataExchangeMessageImportBeforeStart.Set(True);
	
EndProcedure

&AtServer
Procedure SetFormItemsView()
	
	If DataExchangeServer.LoadDataExchangeMessage()
		And InfobaseUpdate.InfobaseUpdateRequired() Then
		
		Items.FormNotSyncAndContinue.Visible = False;
		Items.DoNotSyncHelpText.Visible = False;
	Else
		Items.FormNotSyncAndContinue.Visible = True;
		Items.DoNotSyncHelpText.Visible = True;
	EndIf;
	
	Items.PanelMain.CurrentPage = ?(TimeConsumingOperation, Items.TimeConsumingOperation, Items.Begin);
	Items.TimeConsumingOperationButtonsGroup.Visible = TimeConsumingOperation;
	Items.MainButtonsGroup.Visible = Not TimeConsumingOperation;
	
EndProcedure

&AtClient
Procedure FillInInformationAboutMessageFromArchive()
	
	FillInInformationAboutMessageFromArchiveAtServer();
	
EndProcedure  

&AtServer
Procedure FillInInformationAboutMessageFromArchiveAtServer()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ArchiveOfExchangeMessagesSliceLast.Period AS Period
	|FROM
	|	InformationRegister.ArchiveOfExchangeMessages.SliceLast(, InfobaseNode = &InfobaseNode) AS ArchiveOfExchangeMessagesSliceLast";
	
	Query.SetParameter("InfobaseNode", InfobaseNode);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then 
		Items.OpenMessageFromArchive.Title = NStr("en = '<No archived message>'");
		Items.ContinueUploadingMessageFromArchive.ReadOnly = True;
		
		ContinueUploadingMessageFromArchive = False;
		PeriodOfRecordingArchiveMessage = Date(1,1,1);
	Else
		Selection = QueryResult.Select();
		Selection.Next();
		
		Items.OpenMessageFromArchive.Title = StrTemplate(NStr("en = 'Archived message from %1.'"), Format(Selection.Period, "DLF=DT"));
		Items.ContinueUploadingMessageFromArchive.ReadOnly = False;
		
		PeriodOfRecordingArchiveMessage = Selection.Period;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingUpFormElementsForLongTermOperation(LongTermOperationIsBeingPerformed)
	
	If LongTermOperationIsBeingPerformed Then
		Items.PanelMain.CurrentPage = Items.TimeConsumingOperation;
		Items.MainButtonsGroup.Visible = False;
		Items.TimeConsumingOperationButtonsGroup.Visible = True;
	Else
		Items.PanelMain.CurrentPage = Items.Begin; 
		Items.MainButtonsGroup.Visible = True;
		Items.TimeConsumingOperationButtonsGroup.Visible = False;
	EndIf;

EndProcedure

&AtServerNoContext
Procedure CancelJobExecution(Val TaskID_)
	
	TimeConsumingOperations.CancelJobExecution(TaskID_);
	
EndProcedure

#EndRegion