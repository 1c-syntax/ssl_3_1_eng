///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InfobaseNode = DataExchangeServer.MasterNode();
	IsStandaloneWorkplace = DataExchangeServer.IsStandaloneWorkplace();
	UserName = InfoBaseUsers.CurrentUser().Name;
	
	If InfobaseNode = Undefined Then
		
		Raise NStr("en = 'The infobase is neither a standalone workstation nor a distributed infobase.';", Common.DefaultLanguageCode());
		
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
	
	NodeNameLabel = NStr("en = 'Cannot install the application update received from
		|""%1"".
		|See <a href = ""%2"">Event log</a> for technical information.';");
	Items.NodeNameHelpText.Title = 
		StringFunctions.FormattedString(NodeNameLabel, String(InfobaseNode), "EventLog");
	
	SetFormItemsView();
	
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

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SyncAndContinue(Command)
	
	WarningText = "";
	HasErrors = False;
	TimeConsumingOperation = False;
	
	CheckUpdateRequired();
	
	If UpdateStatus = "NoUpdateRequired" Then
		
		SynchronizeAndContinueWithoutIBUpdate();
		
	ElsIf UpdateStatus = "InfobaseUpdate" Then
		
		SynchronizeAndContinueWithIBUpdate();
		
	ElsIf UpdateStatus = "ConfigurationUpdate" Then
		
		WarningText = NStr("en = 'Changes that have not been applied yet were received from the main node.
			|Open Designer and update the database configuration.';");
		
	EndIf;
	
	If Not TimeConsumingOperation Then
		
		SyncAndContinueCompletion();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotSyncAndContinue(Command)
	
	DoNotSyncAndContinueAtServer();
	
	Close("Continue");
	
EndProcedure

&AtClient
Procedure ExitApplication(Command)
	
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

#EndRegion

#Region Private

#Region NoInfobaseUpdateScenario

&AtClient
Procedure SynchronizeAndContinueWithoutIBUpdate()
	
	ImportDataExchangeMessageWithoutUpdating();
	SynchronizeAndContinueWithoutIBUpdateCompletion();
		
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
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		
		// If the message is imported, reimporting is not required.
		If Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(False);
		EndIf;
		Constants.RetryDataExchangeMessageImportBeforeStart.Set(False);
		
		Try
			ExportMessageAfterInfobaseUpdate();
		Except
			// If import fails, resume the startup and run import in 1C:Enterprise mode.
			// 
			EventLogMessageKey = DataExchangeServer.DataExchangeEventLogEvent();
			WriteLogEvent(EventLogMessageKey,
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	ElsIf ConfigurationChanged() Then
		If Not Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(True);
		EndIf;
		WarningText = NStr("en = 'Changes to be applied were received from the main node.
			|Open Designer and update the database configuration.';");
	Else
		
		If InfobaseUpdate.InfobaseUpdateRequired() Then
			EnableDataExchangeMessageImportRecurrenceBeforeStart();
		EndIf;
		
		WarningText = NStr("en = 'Receiving data from the master node is completed with errors.
			|For more information, see the event log.';");
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ExportMessageAfterInfobaseUpdate()
	
	// The repeat mode can be disabled if messages are imported and the infobase is updated successfully.
	DataExchangeServer.DisableDataExchangeMessageImportRepeatBeforeStart();
	
	Try
		If GetFunctionalOption("UseDataSynchronization") Then
			
			InfobaseNode = DataExchangeServer.MasterNode();
			
			If InfobaseNode <> Undefined Then
				
				ExecuteExport = True;
				
				TransportID = ExchangeMessagesTransport.DefaultTransport(InfobaseNode);
				
				If ExecuteExport Then
					
					AuthenticationData = New Structure;
					If IsStandaloneWorkplace Then
						AuthenticationData.Insert("UserName", UserName);
						AuthenticationData.Insert("Password", Password);
					EndIf;
					
					// Export only.
					Cancel = False;
					
					ExchangeParameters = DataExchangeServer.ExchangeParameters();
					ExchangeParameters.TransportID = TransportID;
					ExchangeParameters.ExecuteImport1 = False;
					ExchangeParameters.ExecuteExport2 = True;
					ExchangeParameters.AuthenticationData = AuthenticationData;
					ExchangeParameters.TheTimeoutOnTheServer = 15;
						
					DataExchangeServer.ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, Cancel);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	Except
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

&AtServer
Procedure ImportDataExchangeMessageWithoutUpdating()
	
	Try
		ImportMessageBeforeInfobaseUpdate();
	Except
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		HasErrors = True;
	EndTry;
	
	SetFormItemsView();
	
EndProcedure

&AtServer
Procedure ImportMessageBeforeInfobaseUpdate()
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
			"SkipImportDataExchangeMessageBeforeStart") Then
		Return;
	EndIf;
	
	If GetFunctionalOption("UseDataSynchronization") Then
		
		If InfobaseNode <> Undefined Then
			
			SetPrivilegedMode(True);
			DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", True);
			SetPrivilegedMode(False);
			
			// Updating object registration rules before importing data.
			DataExchangeServer.UpdateDataExchangeRules();
			
			TransportID = ExchangeMessagesTransport.DefaultTransport(InfobaseNode);
			
			OperationStartDate = CurrentSessionDate();
			
			AuthenticationData = New Structure;
			If IsStandaloneWorkplace Then
				AuthenticationData.Insert("UserName", UserName);
				AuthenticationData.Insert("Password", Password);
			EndIf;			
			
			// Import only.
			ExchangeParameters = DataExchangeServer.ExchangeParameters();
			ExchangeParameters.TransportID = TransportID;
			ExchangeParameters.ExecuteImport1 = True;
			ExchangeParameters.ExecuteExport2 = False;
			
			ExchangeParameters.TimeConsumingOperationAllowed = TimeConsumingOperationAllowed;
			ExchangeParameters.TimeConsumingOperation          = TimeConsumingOperation;
			ExchangeParameters.OperationID       = OperationID;
			ExchangeParameters.FileID          = FileID;
			ExchangeParameters.AuthenticationData        = AuthenticationData;
			ExchangeParameters.TheTimeoutOnTheServer   = 15;
			
			DataExchangeServer.ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, HasErrors);
			
			TimeConsumingOperationAllowed = ExchangeParameters.TimeConsumingOperationAllowed;
			TimeConsumingOperation          = ExchangeParameters.TimeConsumingOperation;
			OperationID       = ExchangeParameters.OperationID;
			FileID          = ExchangeParameters.FileID;
			AuthenticationData        = ExchangeParameters.AuthenticationData;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ScenarioWithInfobaseUpdate

&AtClient
Procedure SynchronizeAndContinueWithIBUpdate()
	
	ImportDataExchangeMessageWithUpdate();
	SynchronizeAndContinueWithIBUpdateCompletion();
	
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
			|Open Designer and update the database configuration.';");
		
	Else
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		
		EnableDataExchangeMessageImportRecurrenceBeforeStart();
		
		WarningText = NStr("en = 'Receiving data from the master node is completed with errors.
			|For more information, see the event log.';");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ImportDataExchangeMessageWithUpdate()
	
	Try
		ImportPriorityDataToSubordinateDIBNode();
	Except
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		HasErrors = True;
	EndTry;
	
	SetFormItemsView();
	
EndProcedure

&AtServer
Procedure ImportPriorityDataToSubordinateDIBNode()
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
			"SkipImportDataExchangeMessageBeforeStart") Then
		Return;
	EndIf;
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
			"SkipImportPriorityDataBeforeStart") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", True);
	SetPrivilegedMode(False);
	
	CheckDataSynchronizationEnabled();
	
	If GetFunctionalOption("UseDataSynchronization") Then
		
		InfobaseNode = DataExchangeServer.MasterNode();
		
		If InfobaseNode <> Undefined Then
			
			TransportID = ExchangeMessagesTransport.DefaultTransport(InfobaseNode);
			
			If TransportID = Undefined Then
				Catalogs.ExchangeMessageTransportSettings.ProcessDataForMigrationToNewVersion();
				TransportID = ExchangeMessagesTransport.DefaultTransport(InfobaseNode);
			EndIf;
			
			ParameterName = "StandardSubsystems.DataExchange.RecordRules."
				+ DataExchangeCached.GetExchangePlanName(InfobaseNode);
			RegistrationRulesUpdated = StandardSubsystemsServer.ApplicationParameter(ParameterName);
			If RegistrationRulesUpdated = Undefined Then
				DataExchangeServer.UpdateDataExchangeRules();
			EndIf;
			RegistrationRulesUpdated = StandardSubsystemsServer.ApplicationParameter(ParameterName);
			If RegistrationRulesUpdated = Undefined Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Cannot update data registration rules cache for exchange plan ""%1""';"),
					DataExchangeCached.GetExchangePlanName(InfobaseNode));
			EndIf;
			
			OperationStartDate = CurrentSessionDate();
			
			AuthenticationData = New Structure;
			If IsStandaloneWorkplace Then
				AuthenticationData.Insert("UserName", UserName);
				AuthenticationData.Insert("Password", Password);
			EndIf;
			
			// Importing application parameters only.
			ExchangeParameters = DataExchangeServer.ExchangeParameters();
			ExchangeParameters.TransportID = TransportID;
			ExchangeParameters.ExecuteImport1 = True;
			ExchangeParameters.ExecuteExport2 = False;
			ExchangeParameters.ParametersOnly   = True;
			
			ExchangeParameters.TimeConsumingOperationAllowed = TimeConsumingOperationAllowed;
			ExchangeParameters.TimeConsumingOperation          = TimeConsumingOperation;
			ExchangeParameters.OperationID       = OperationID;
			ExchangeParameters.FileID          = FileID;
			ExchangeParameters.AuthenticationData         = AuthenticationData;	
			ExchangeParameters.TheTimeoutOnTheServer    = 15;
						
			DataExchangeServer.ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, HasErrors);
			
			TimeConsumingOperationAllowed = ExchangeParameters.TimeConsumingOperationAllowed;
			TimeConsumingOperation          = ExchangeParameters.TimeConsumingOperation;
			OperationID       = ExchangeParameters.OperationID;
			FileID          = ExchangeParameters.FileID;
			
		EndIf;
		
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
Procedure CheckDataSynchronizationEnabled()
	
	If Not GetFunctionalOption("UseDataSynchronization") Then
		
		If Common.DataSeparationEnabled() Then
			
			UseDataSynchronization = Constants.UseDataSynchronization.CreateValueManager();
			UseDataSynchronization.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
			UseDataSynchronization.DataExchange.Load = True;
			UseDataSynchronization.Value = True;
			UseDataSynchronization.Write();
			
		Else
			
			If DataExchangeServer.GetExchangePlansInUse().Count() > 0 Then
				
				UseDataSynchronization = Constants.UseDataSynchronization.CreateValueManager();
				UseDataSynchronization.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
				UseDataSynchronization.DataExchange.Load = True;
				UseDataSynchronization.Value = True;
				UseDataSynchronization.Write();
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
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

#EndRegion