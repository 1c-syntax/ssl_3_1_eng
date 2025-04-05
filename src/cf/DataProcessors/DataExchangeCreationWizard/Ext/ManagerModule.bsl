///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// For internal use.
//
Procedure ExportConnectionSettingsForSubordinateDIBNode(ConnectionSettings) Export
	
	SetPrivilegedMode(True);
	
	JSONText = "";
	Try
		JSONText = ExchangeMessagesTransport.ConnectionSettingsINJSON(ConnectionSettings);
	Except
		Raise;
	EndTry;
		
	Constants.SubordinateDIBNodeSettings.Set(JSONText);
	
	ExchangePlans.RecordChanges(ConnectionSettings.InfobaseNode,
		Metadata.Constants.SubordinateDIBNodeSettings);
	
EndProcedure

#Region CheckConnectionToCorrespondent

// For internal use.
//
Procedure OnStartTestConnection(ConnectionSettings, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = DataExchangeServer.BackgroundJobKey(ConnectionSettings.ExchangePlanName,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Checking connection %1'"), ConnectionSettings.TransportID));

	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1 connection check is already in progress.'"), ConnectionSettings.TransportID);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ConnectionSettings", ConnectionSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Check connection to peer: %1.'"), ConnectionSettings.TransportID);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.TestCorrespondentConnection",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

Procedure OnWaitForTestConnection(HandlerParameters, ContinueWait = True) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

Procedure OnCompleteConnectionTest(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region SaveSynchronizationSettings

// For internal use.
//
Procedure OnStartSaveSynchronizationSettings(SynchronizationSettings, HandlerParameters, ContinueWait = True) Export
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(SynchronizationSettings.ExchangeNode);
	
	BackgroundJobKey = DataExchangeServer.BackgroundJobKey(ExchangePlanName,
		NStr("en = 'Save data synchronization settings'"));

	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Saving data synchronization settings for ""%1"" is already in progress.'"), ExchangePlanName);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("SynchronizationSettings", SynchronizationSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Save data synchronization settings: %1'"), ExchangePlanName);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.SaveSynchronizationSettings1",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnWaitForSaveSynchronizationSettings(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteSaveSynchronizationSettings(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region DeleteDataSynchronizationSetting

// For internal use.
//
Procedure OnStartDeleteSynchronizationSettings(DeletionSettings, HandlerParameters, ContinueWait = True) Export
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(DeletionSettings.ExchangeNode);
	
	BackgroundJobKey = DataExchangeServer.BackgroundJobKey(ExchangePlanName,
		NStr("en = 'Delete data synchronization settings'"));

	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Deletion of data synchronization settings for ""%1"" is already in progress.'"), ExchangePlanName);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("DeletionSettings", DeletionSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Delete data synchronization settings: %1'"), ExchangePlanName);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.DeleteSynchronizationSetting",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnWaitForDeleteSynchronizationSettings(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteSynchronizationSettingsDeletion(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region DataRegistrationForInitialExport

// For internal use.
//
Procedure OnStartRecordDataForInitialExport(RegistrationSettings, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Register data for initial export (%1)'"),
		RegistrationSettings.ExchangeNode);

	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Data registration for initial export to ""%1"" is already running.'"),
			RegistrationSettings.ExchangeNode);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("RegistrationSettings", RegistrationSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Register data for initial export (%1)'"),
		RegistrationSettings.ExchangeNode);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.RegisterDataForInitialExport",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnWaitForRecordDataForInitialExport(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteDataRecordingForInitialExport(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region XDTOSettingsImport

// For internal use.
//
Procedure OnStartImportXDTOSettings(ImportSettings, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Import XDTO settings (%1)'"),
		ImportSettings.ExchangeNode);

	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Import of XDTO settings for ""%1"" is already in progress.'"),
			ImportSettings.ExchangeNode);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ImportSettings", ImportSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Import XDTO settings (%1)'"),
		ImportSettings.ExchangeNode);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.ImportXDTOCorrespondentSettings",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnWaitForImportXDTOSettings(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteImportXDTOSettings(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region MigrationToWebService

Procedure ChangeNodeTransportInWS(Node, Endpoint, CorrespondentDataArea) Export
	
	TransportSettings = New Structure; 
	TransportSettings.Insert("InternalPublication", True);
	TransportSettings.Insert("Endpoint", "");
	TransportSettings.Insert("CorrespondentEndpoint", Endpoint);
	TransportSettings.Insert("PeerInfobaseName", "");
	TransportSettings.Insert("CorrespondentDataArea", CorrespondentDataArea);
	
	Try
		
		ExchangeMessagesTransport.SaveTransportSettings(Node, "SM", TransportSettings, True);
		
		RecordStructure = New Structure("Peer", Node);
		DataExchangeInternal.DeleteRecordSetFromInformationRegister(RecordStructure,"DataAreaExchangeTransportSettings");
		
		JobSchedule = Catalogs.DataExchangeScenarios.DefaultJobSchedule();
		Catalogs.DataExchangeScenarios.CreateScenario(Node, JobSchedule, True);
			
	Except
		
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeWebService.EventLogEventTransportChangedOnWS(),
			EventLogLevel.Error, , , ErrorMessage);
		
		Raise ErrorMessage;
		
	EndTry;
		
EndProcedure

Procedure ChangeTransportOfPeerNodeOnWS(Node, Endpoint, CorrespondentEndpoint, DataArea) Export
		
	SetPrivilegedMode(True);
	
	ModuleMessagesExchangeTransportSettings = Common.CommonModule("InformationRegisters.MessageExchangeTransportSettings");
	TransportSettingsWS = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(CorrespondentEndpoint);
	
	ExchangePlanName = Node.Metadata().Name;
	EndpointCode = Common.ObjectAttributeValue(Endpoint,"Code");
	
	SetPrivilegedMode(False);
	
	Try
		
		InterfaceVersions = DataExchangeCached.CorrespondentVersions(TransportSettingsWS);
		
	Except
		
		ErrorMessageInCorrespondent = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeDeletionEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessageInCorrespondent);
		
		Raise ErrorMessageInCorrespondent;
		
	EndTry;

	ErrorMessage = "";
	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("WebServiceAddress", TransportSettingsWS.WSWebServiceURL);
	ConnectionParameters.Insert("UserName", TransportSettingsWS.WSUserName);
	ConnectionParameters.Insert("Password", TransportSettingsWS.WSPassword);
	
	Proxy = DataExchangeWebService.WSProxy(ConnectionParameters, ErrorMessage);
	
	CorrespondentNodeCode = DataExchangeCached.GetThisNodeCodeForExchangePlan(ExchangePlanName);
	CorrespondentDataArea = SessionParameters["DataAreaValue"];
	
	Parameters = New Structure;
	Parameters.Insert("ExchangePlanName", ExchangePlanName);
	Parameters.Insert("CorrespondentNodeCode", CorrespondentNodeCode);
	Parameters.Insert("CorrespondentEndpoint", EndpointCode);
	Parameters.Insert("CorrespondentDataArea", CorrespondentDataArea);
	
	Try
		
		Proxy.ChangeNodeTransportToWSInt(XDTOSerializer.WriteXDTO(Parameters), DataArea);
		 
	Except
		
		ErrorMessageInCorrespondent = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeDeletionEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessageInCorrespondent);
		
		Raise ErrorMessageInCorrespondent;
		
	EndTry;
		
EndProcedure

#EndRegion

Function DataExchangeSettingsFormatVersion() Export
	
	Return "1.2";
	
EndFunction

// For internal use.
//
Procedure OnStartGetDataExchangeSettingOptions(UUID, HandlerParameters, ContinueWait) Export
	
	StandardSettingsTable = Undefined;
	OnGetAvailableDataSynchronizationSettings(StandardSettingsTable);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultAddressDefaultSettings", PutToTempStorage(StandardSettingsTable, UUID));
	
	If Common.SubsystemExists("OnlineUserSupport.DataExchangeWithExternalSystems") Then
		ContinueWait = True;
		
		SettingVariants = ExternalSystemsDataExchangeSettingsOptionDetails();
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("SettingVariants", SettingVariants);
		ProcedureParameters.Insert("ExchangeNode",       Undefined);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.BackgroundJobDescription = NStr("en = 'Get available setup options for data exchange with external systems'");
		ExecutionParameters.WaitCompletion = 0;
		
		BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
			"DataExchangeWithExternalSystems.OnGetDataExchangeSettingsOptions",
			ProcedureParameters,
			ExecutionParameters);
			
		HandlerParameterExternalSystems = Undefined;	
		OnStartTimeConsumingOperation(BackgroundJob, HandlerParameterExternalSystems, ContinueWait);
		
		HandlerParameters.Insert("HandlerParameterExternalSystems", HandlerParameterExternalSystems);
		
	EndIf;
	
EndProcedure

// For internal use.
//
Procedure OnWaitForGetDataExchangeSettingOptions(HandlerParameters, ContinueWait) Export
	
	If HandlerParameters.Property("HandlerParameterExternalSystems") Then
		OnWaitTimeConsumingOperation(HandlerParameters.HandlerParameterExternalSystems, ContinueWait);
	Else
		ContinueWait = False;
	EndIf;
	
EndProcedure

// For internal use.
//
// Parameters:
//   HandlerParameters - Structure - Long-running operation parameters.
//   Result - Structure:
//   * SettingsExternalSystems - Structure:
//                    * ErrorCode - String
//                    * ErrorMessage - String
//                    * SettingVariants - ValueTable
// 
Procedure OnCompleteGettingDataExchangeSettingsOptions(HandlerParameters, Result) Export
	
	Result = New Structure;
	Result.Insert("ExchangeDefaultSettings", GetFromTempStorage(HandlerParameters.ResultAddressDefaultSettings));
	
	If HandlerParameters.Property("HandlerParameterExternalSystems") Then
		
		SettingsExternalSystems = New Structure;
		SettingsExternalSystems.Insert("ErrorCode"); // SettingsReceived, NoSettings, Error, OnlineSupportNotConnected
		SettingsExternalSystems.Insert("ErrorMessage");
		SettingsExternalSystems.Insert("SettingVariants");
		
		CompletionStatusExternalSystems = Undefined;
		OnCompleteTimeConsumingOperation(HandlerParameters.HandlerParameterExternalSystems, CompletionStatusExternalSystems);
		
		If CompletionStatusExternalSystems.Cancel Then
			SettingsExternalSystems.ErrorCode = "BackgroundJobError";
			SettingsExternalSystems.ErrorMessage = CompletionStatusExternalSystems.ErrorMessage;
		Else
			FillPropertyValues(SettingsExternalSystems, CompletionStatusExternalSystems.Result);
		EndIf;
		
		Result.Insert("SettingsExternalSystems", SettingsExternalSystems);
		
	EndIf;
	
EndProcedure

Function ExternalSystemsDataExchangeSettingsOptionDetails() Export
	
	SettingVariants = New ValueTable;
	SettingVariants.Columns.Add("ExchangePlanName",                                 New TypeDescription("String"));
	SettingVariants.Columns.Add("SettingID",                         New TypeDescription("String"));
	SettingVariants.Columns.Add("NewDataExchangeCreationCommandTitle", New TypeDescription("String"));
	SettingVariants.Columns.Add("BriefExchangeInfo",                      New TypeDescription("FormattedString"));
	SettingVariants.Columns.Add("DetailedExchangeInformation",                    New TypeDescription("String"));
	SettingVariants.Columns.Add("ExchangeCreateWizardTitle",               New TypeDescription("String"));
	SettingVariants.Columns.Add("PeerInfobaseName",                     New TypeDescription("String"));
	SettingVariants.Columns.Add("ConnectionParameters");
	
	Return SettingVariants;
	
EndFunction

Function SettingOptionDetailsStructure() Export
	
	SettingOptionDetails = New Structure;
	SettingOptionDetails.Insert("NewDataExchangeCreationCommandTitle", "");
	SettingOptionDetails.Insert("BriefExchangeInfo", New FormattedString(""));
	SettingOptionDetails.Insert("DetailedExchangeInformation", "");
	SettingOptionDetails.Insert("ExchangeCreateWizardTitle", "");
	SettingOptionDetails.Insert("PeerInfobaseName", "");
	
	Return SettingOptionDetails;
	
EndFunction

Procedure ConfigureDataExchange(ConnectionSettings) Export
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		
		// Creating/updating the exchange plan node.
		CreateUpdateExchangePlanNodes(ConnectionSettings);
		
		// Loading message transport settings.
		If ValueIsFilled(ConnectionSettings.TransportID) Then
			
			ExchangeMessagesTransport.SaveTransportSettings(
				ConnectionSettings.InfobaseNode,
				ConnectionSettings.TransportID,
				ConnectionSettings.TransportSettings,
				True);
			
		EndIf;
		
		// Updating the infobase prefix constant value.
		If IsBlankString(GetFunctionalOption("InfobasePrefix"))
			And Not IsBlankString(ConnectionSettings.SourceInfobasePrefix) Then
			
			DataExchangeServer.SetInfobasePrefix(ConnectionSettings.SourceInfobasePrefix);
			
		EndIf;
		
		If DataExchangeCached.IsDistributedInfobaseExchangePlan(ConnectionSettings.ExchangePlanName)
			And ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup" Then
			
			Constants.SubordinateDIBNodeSetupCompleted.Set(True);
			Constants.UseDataSynchronization.Set(True);
			Constants.NotUseSeparationByDataAreas.Set(True);
			
			DataExchangeServer.SetDefaultDataImportTransactionItemsCount();
			
			// Importing rules as exchange rules are not migrated to DIB.
			DataExchangeServer.UpdateDataExchangeRules();
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure FillConnectionSettingsFromXMLString(
	ConnectionSettings, FileNameXMLString, IsFile = False, IsOnlineConnection = False, TransportID = "") Export
	
	If Not ValueIsFilled(TransportID) Then
		
		If StrFind(FileNameXMLString, "COM") Then
			TransportID = "COM";
		Else
			TransportID = "WS";
		EndIf;
		
	EndIf;
	
	ConnectionSettingsFromXML = ExchangeMessagesTransport.ConnectionSettingsFromXML(FileNameXMLString, TransportID);
	ExchangeMessagesTransport.CheckAndFillInXMLConnectionSettings(ConnectionSettings, ConnectionSettingsFromXML);
	
EndProcedure

#EndRegion

#Region Private

#Region TimeConsumingOperations1

// For internal use.
//
Procedure OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait = True)
	
	InitializeTimeConsumingOperationHandlerParameters(HandlerParameters, BackgroundJob);
	
	If BackgroundJob.Status = "Running" Then
		HandlerParameters.ResultAddress       = BackgroundJob.ResultAddress;
		HandlerParameters.OperationID = BackgroundJob.JobID;
		HandlerParameters.TimeConsumingOperation    = True;
		
		ContinueWait = True;
		Return;
	ElsIf BackgroundJob.Status = "Completed2" Then
		HandlerParameters.ResultAddress    = BackgroundJob.ResultAddress;
		HandlerParameters.TimeConsumingOperation = False;
		
		ContinueWait = False;
		Return;
	Else
		HandlerParameters.ErrorMessage = BackgroundJob.BriefErrorDescription;
		If ValueIsFilled(BackgroundJob.DetailErrorDescription) Then
			WriteLogEvent(
				DataExchangeServer.DataExchangeEventLogEvent(), 
				EventLogLevel.Error,
				Metadata.DataProcessors.DataExchangeCreationWizard,
				,
				BackgroundJob.DetailErrorDescription);
		EndIf;
		
		HandlerParameters.Cancel = True;
		HandlerParameters.TimeConsumingOperation = False;
		
		ContinueWait = False;
		Return;
	EndIf;
	
EndProcedure

// For internal use.
//
Procedure OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait = True)
	
	If HandlerParameters.Cancel
		Or Not HandlerParameters.TimeConsumingOperation Then
		ContinueWait = False;
		Return;
	EndIf;
	
	JobCompleted = False;
	Try
		JobCompleted = TimeConsumingOperations.JobCompleted(HandlerParameters.OperationID);
	Except
		HandlerParameters.Cancel             = True;
		HandlerParameters.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , HandlerParameters.ErrorMessage);
	EndTry;
		
	If HandlerParameters.Cancel Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ContinueWait = Not JobCompleted;
	
EndProcedure

// For internal use.
//
Procedure OnCompleteTimeConsumingOperation(HandlerParameters,
		CompletionStatus = Undefined)
	
	CompletionStatus = New Structure;
	CompletionStatus.Insert("Cancel",             False);
	CompletionStatus.Insert("ErrorMessage", "");
	CompletionStatus.Insert("Result",         Undefined);
	
	If HandlerParameters.Cancel Then
		FillPropertyValues(CompletionStatus, HandlerParameters, "Cancel, ErrorMessage");
	Else
		CompletionStatus.Result = GetFromTempStorage(HandlerParameters.ResultAddress);
	EndIf;
	
	HandlerParameters = Undefined;
		
EndProcedure

Procedure InitializeTimeConsumingOperationHandlerParameters(HandlerParameters, BackgroundJob)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("BackgroundJob",          BackgroundJob);
	HandlerParameters.Insert("Cancel",                   False);
	HandlerParameters.Insert("ErrorMessage",       "");
	HandlerParameters.Insert("TimeConsumingOperation",      False);
	HandlerParameters.Insert("OperationID",   Undefined);
	HandlerParameters.Insert("ResultAddress",         Undefined);
	HandlerParameters.Insert("AdditionalParameters", New Structure);
	
EndProcedure

#EndRegion

Procedure OnGetAvailableDataSynchronizationSettings(SettingsTable1)
	
	SettingsTable1 = New ValueTable;
	SettingsTable1.Columns.Add("ExchangePlanName",                                 New TypeDescription("String"));
	SettingsTable1.Columns.Add("SettingID",                         New TypeDescription("String"));
	SettingsTable1.Columns.Add("CorrespondentConfigurationName",                  New TypeDescription("String"));
	SettingsTable1.Columns.Add("CorrespondentConfigurationDescription",         New TypeDescription("String"));
	SettingsTable1.Columns.Add("NewDataExchangeCreationCommandTitle", New TypeDescription("String"));
	SettingsTable1.Columns.Add("ExchangeCreateWizardTitle",               New TypeDescription("String"));
	SettingsTable1.Columns.Add("BriefExchangeInfo",                      New TypeDescription("String"));
	SettingsTable1.Columns.Add("DetailedExchangeInformation",                    New TypeDescription("String"));
	SettingsTable1.Columns.Add("IsDIBExchangePlan",                               New TypeDescription("Boolean"));
	SettingsTable1.Columns.Add("IsXDTOExchangePlan",                              New TypeDescription("Boolean"));
	SettingsTable1.Columns.Add("ExchangePlanNameToMigrateToNewExchange",          New TypeDescription("String"));
	
	ExchangePlansList = ExchangePlansForSynchronizationSetup();
	
	For Each ExchangePlanName In ExchangePlansList Do
		
		FillTableWithExchangePlanSettingsOptions(SettingsTable1, ExchangePlanName);

	EndDo;
	
	DeleteObsoleteSettingsOptionsSaaS(SettingsTable1);
	
EndProcedure

Function ExchangePlansForSynchronizationSetup()
	
	ExchangePlansList = New Array;
	
	IsFullUser = Users.IsFullUser(, True);
	
	SaaSModel = Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable();
	
	If SaaSModel Then
		ModuleDataExchangeSaaSCached = Common.CommonModule("DataExchangeSaaSCached");
		ExchangePlansList = ModuleDataExchangeSaaSCached.DataSynchronizationExchangePlans();
	Else
		ExchangePlansList = DataExchangeCached.SSLExchangePlans();
	EndIf;
	
	For Indus = -ExchangePlansList.UBound() To 0 Do
		
		ExchangePlanName = ExchangePlansList[-Indus];
		
		If (Not IsFullUser
				And DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName))
			Or Not DataExchangeCached.ExchangePlanUsageAvailable(ExchangePlanName) Then
			// Creating a DIB exchange requires system administrator rights.
			ExchangePlansList.Delete(-Indus);
		EndIf;
		
	EndDo;
	
	Return ExchangePlansList;
	
EndFunction

Procedure FillTableWithExchangePlanSettingsOptions(SettingsTable1, ExchangePlanName)
	
	ExchangeSettings = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName,
		"ExchangeSettingsOptions, ExchangePlanNameToMigrateToNewExchange");
	
	For Each SettingsMode In ExchangeSettings.ExchangeSettingsOptions Do
		PredefinedSetting = SettingsMode.SettingID;
		
		SettingsValuesForOption = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName,
			"UseDataExchangeCreationWizard,
			|CorrespondentConfigurationName,
			|CorrespondentConfigurationDescription,
			|NewDataExchangeCreationCommandTitle,
			|ExchangeCreateWizardTitle,
			|BriefExchangeInfo,
			|DetailedExchangeInformation",
			PredefinedSetting);
			
		If Not SettingsValuesForOption.UseDataExchangeCreationWizard Then
			Continue;
		EndIf;
		
		SettingString = SettingsTable1.Add();
		FillPropertyValues(SettingString, SettingsValuesForOption);
		
		SettingString.ExchangePlanName = ExchangePlanName;
		SettingString.SettingID = PredefinedSetting;
		SettingString.IsDIBExchangePlan  = DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName);
		SettingString.IsXDTOExchangePlan = DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName);
		SettingString.ExchangePlanNameToMigrateToNewExchange = ExchangeSettings.ExchangePlanNameToMigrateToNewExchange;
		
	EndDo;
	
EndProcedure

Procedure DeleteObsoleteSettingsOptionsSaaS(SettingsTable1)
	
	SaaSModel = Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable();
		
	If Not SaaSModel Then
		Return;
	EndIf;
	
	XTDOExchangePlans     = New Array;
	ObsoleteSettings = New Array;
	
	For Each SettingString In SettingsTable1 Do
		If SettingString.IsXDTOExchangePlan Then
			If XTDOExchangePlans.Find(SettingString.ExchangePlanName) = Undefined Then
				XTDOExchangePlans.Add(SettingString.ExchangePlanName);
			EndIf;
			Continue;
		EndIf;
		If Not ValueIsFilled(SettingString.ExchangePlanNameToMigrateToNewExchange) Then
			Continue;
		EndIf;
		ObsoleteSettings.Add(SettingString);
	EndDo;
	
	XDTOSettingsTable = SettingsTable1.Copy(New Structure("IsXDTOExchangePlan", True));
	
	SettingsForDelete = New Array;
	For Each SettingString In ObsoleteSettings Do
		For Each XTDOExchangePlan In XTDOExchangePlans Do
			SettingsMode = DataExchangeServer.ExchangeSetupOptionForCorrespondent(
				XTDOExchangePlan, SettingString.CorrespondentConfigurationName);
			If Not ValueIsFilled(SettingsMode) Then
				Continue;
			EndIf;
			XDTOSettings = XDTOSettingsTable.FindRows(New Structure("SettingID", SettingsMode));	
			If XDTOSettings.Count() > 0 Then
				SettingsForDelete.Add(SettingString);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	For Cnt = 1 To SettingsForDelete.Count() Do
		SettingsTable1.Delete(SettingsForDelete[Cnt - 1]);
	EndDo;
	
EndProcedure

Procedure TestCorrespondentConnection(Parameters, ResultAddress) Export
	
	CheckResult = New Structure;
	CheckResult.Insert("ConnectionIsSet", False);
	CheckResult.Insert("ConnectionAllowed",   False); 
	CheckResult.Insert("InterfaceVersions",       Undefined);
	CheckResult.Insert("ErrorMessage",      "");
	
	CheckResult.Insert("CorrespondentParametersReceived", False);
	CheckResult.Insert("CorrespondentParameters",         Undefined);
	
	CheckResult.Insert("ThisNodeExistsInPeerInfobase", False);
	CheckResult.Insert("ThisInfobaseHasPeerInfobaseNode", False);
	CheckResult.Insert("NodeToDelete", Undefined);
	
	CheckResult.Insert("CorrespondentExchangePlanName","");
	
	Transport = ExchangeMessagesTransport.Initialize(Parameters.ConnectionSettings);
	
	If Transport.ConnectionIsSet() Then
		
		CheckResult.ConnectionIsSet = True;
		CheckResult.ConnectionAllowed   = True;
		
	Else
		
		ErrorMessage = Transport.ErrorMessage;
		
	EndIf;
	
	PutToTempStorage(CheckResult, ResultAddress);
	
EndProcedure

Function SaveConnectionSettings1(ConnectionSettings) Export
		
	SetPrivilegedMode(True);
	
	Result = New Structure;
	Result.Insert("ConnectionSettingsSaved", False);
	Result.Insert("HasDataToMap",    False); // For offline transport only.
	Result.Insert("ExchangeNode",                    Undefined);
	Result.Insert("ErrorMessage",             "");
	Result.Insert("XMLConnectionSettingsString",  "");
	Result.Insert("JSONConnectionSettingsString", "");
	
	Cancel = False;
	
	FixDuplicateSynchronizationSettings(ConnectionSettings, Result, Cancel);
		
	If Cancel Then
		Return Result;
	EndIf;
	
	// Save the node and connection settings to the infobase.
	Try
		ConfigureDataExchange(ConnectionSettings);
	Except
		Cancel = True;
		Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , Result.ErrorMessage);
		Return Result;
	EndTry;
	
	// Save the connection settings on the peer infobase side for online connections,
	// or send a message with XDTO settings for offline connections.
	TransportID = ConnectionSettings.TransportID;
	TransportParameters = ExchangeMessagesTransport.TransportParameters(TransportID);

	If TransportParameters.DirectConnection Then
		
		Parameters = ExchangeMessagesTransport.InitializationParameters();
		Parameters.Peer = ConnectionSettings.InfobaseNode;
		FillPropertyValues(Parameters, ConnectionSettings); 
		
		Transport = ExchangeMessagesTransport.Initialize(Parameters);
		
		If Not Transport.SaveSettingsInCorrespondent(ConnectionSettings) Then
			Cancel = True;
			Result.ErrorMessage = Transport.ErrorMessage;
		EndIf;
		
	ElsIf Not DataExchangeCached.IsDistributedInfobaseExchangePlan(ConnectionSettings.ExchangePlanName) Then
		
		Result.XMLConnectionSettingsString = ExchangeMessagesTransport.ConnectionSettingsInXML(ConnectionSettings);
		Result.JSONConnectionSettingsString = ExchangeMessagesTransport.ConnectionSettingsINJSON(ConnectionSettings);
	
	EndIf;
		
	// Export for offline exchange via IFDE
	If Not TransportParameters.DirectConnection Then
		If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
		
			If ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup" Then
				// Getting an exchange message with XDTO settings.
				ExchangeParameters = DataExchangeServer.ExchangeParameters();
				ExchangeParameters.ExecuteImport1 = True;
				ExchangeParameters.ExecuteExport2 = False;
				ExchangeParameters.TransportID = ConnectionSettings.TransportID;
				
				// Errors that occur when getting messages via the common channels are not critical.
				// It's acceptable if there's no exchange message at all.
				CancelReceipt = False;
				AdditionalParameters = New Structure;
				Try
					DataExchangeServer.ExecuteDataExchangeForInfobaseNode(
						ConnectionSettings.InfobaseNode, ExchangeParameters, CancelReceipt, AdditionalParameters);
				Except
					// Avoiding exceptions is crucial for successfully saving the setting.
					// 
					Cancel = True; 
					Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
					
					WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
					EventLogLevel.Error, , , Result.ErrorMessage);
				EndTry;
				
				If AdditionalParameters.Property("DataReceivedForMapping") Then
					Result.HasDataToMap = AdditionalParameters.DataReceivedForMapping;
				EndIf;
			Else
				// Sending an exchange message with XDTO settings.
				ExchangeParameters = DataExchangeServer.ExchangeParameters();
				ExchangeParameters.ExecuteImport1 = False;
				ExchangeParameters.ExecuteExport2 = True;
				ExchangeParameters.TransportID = ConnectionSettings.TransportID;
				
				Try
					DataExchangeServer.ExecuteDataExchangeForInfobaseNode(
						ConnectionSettings.InfobaseNode, ExchangeParameters, Cancel);
				Except
					Cancel = True;
					Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
					
					WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
						EventLogLevel.Error, , , Result.ErrorMessage);
				EndTry;
			EndIf;
			
		ElsIf Not DataExchangeCached.IsDistributedInfobaseExchangePlan(ConnectionSettings.ExchangePlanName)
			And Not DataExchangeCached.IsStandardDataExchangeNode(ConnectionSettings.ExchangePlanName) Then
			
			Parameters = ExchangeMessagesTransport.InitializationParameters(TransportID);
			Parameters.Peer = ConnectionSettings.InfobaseNode;
			FillPropertyValues(Parameters, ConnectionSettings); 
		
			Transport = ExchangeMessagesTransport.Initialize(Parameters);
			
			Result.HasDataToMap = Transport.GetData();
			
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		Result.ConnectionSettingsSaved = True;
		Result.ExchangeNode = ConnectionSettings.InfobaseNode;
	Else
		DataExchangeServer.DeleteSynchronizationSetting(ConnectionSettings.InfobaseNode);
		
		Result.ConnectionSettingsSaved = False;
		Result.ExchangeNode = Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure FixDuplicateSynchronizationSettings(ConnectionSettings, Result, Cancel)

	If ConnectionSettings.FixDuplicateSynchronizationSettings Then
		
		ManagerExchangePlan = ExchangePlans[ConnectionSettings.ExchangePlanName];
		
		If ConnectionSettings.ThisNodeExistsInPeerInfobase Then
						
			BeginTransaction();
			Try
				
				ThisNode = ManagerExchangePlan.ThisNode();
				
				DataLock = New DataLock;
				
				DataLockItem = DataLock.Add("ExchangePlan." + ConnectionSettings.ExchangePlanName);
				DataLockItem.SetValue("Ref", ThisNode);
						
				DataLock.Lock();

				NewCode = String(New UUID);
				
				ExchangeNodeObject = ThisNode.GetObject();
				ExchangeNodeObject.Code = NewCode;
				ExchangeNodeObject.DataExchange.Load = True;
				ExchangeNodeObject.Write();
								
				ConnectionSettings.NodeCode = NewCode;
				ConnectionSettings.PredefinedNodeCode = NewCode;
				
				CommitTransaction();
				
			Except

				RollbackTransaction();
				
				Cancel = True;
				
				Information = ErrorInfo();
				Result.ErrorMessage = ErrorProcessing.BriefErrorDescription(Information);
							
				WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
					EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(Information));
				
			EndTry;
		
		EndIf;
		
		NodeRef1 = ManagerExchangePlan.FindByCode(ConnectionSettings.DestinationInfobaseID);
		TheNodeExistsInThisDatabase = Not NodeRef1.IsEmpty();
		
		If TheNodeExistsInThisDatabase And ConnectionSettings.ThisInfobaseHasPeerInfobaseNode Then
	
			Try
				
				DataExchangeServer.DeleteSynchronizationSetting(NodeRef1);
				
			Except
				
				Cancel = True;
				
				Information = ErrorInfo();
				Result.ErrorMessage = ErrorProcessing.BriefErrorDescription(Information);
					
				WriteLogEvent(DataExchangeServer.DataExchangeDeletionEventLogEvent(),
					EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(Information));
					
			EndTry;
			
		EndIf;
				
	EndIf;
	
EndProcedure
	
Procedure ImportXDTOCorrespondentSettings(Parameters, ResultAddress) Export
	
	ImportSettings = Undefined;
	Parameters.Property("ImportSettings", ImportSettings);
	
	Result = New Structure;
	Result.Insert("SettingsImported",             True);
	Result.Insert("DataReceivedForMapping", False);
	Result.Insert("ErrorMessage",              "");
	
	// Getting an exchange message with XDTO settings.
	ExchangeParameters = DataExchangeServer.ExchangeParameters();
	ExchangeParameters.ExecuteImport1 = True;
	ExchangeParameters.ExecuteExport2 = False;
	ExchangeParameters.TransportID = ExchangeMessagesTransport.DefaultTransport(ImportSettings.ExchangeNode); 
	
	AdditionalParameters = New Structure;
	
	Cancel = False;
	Try
		DataExchangeServer.ExecuteDataExchangeForInfobaseNode(
			ImportSettings.ExchangeNode, ExchangeParameters, Cancel, AdditionalParameters);
	Except
		Cancel = True;
		Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , Result.ErrorMessage);
	EndTry;
		
	If Cancel Then
		Result.SettingsImported = False; 
		If IsBlankString(Result.ErrorMessage) Then
			Result.ErrorMessage = NStr("en = 'Cannot get peer application parameters.'");
		EndIf;
	Else
		CorrespondentSettings = DataExchangeXDTOServer.SupportedPeerInfobaseFormatObjects(
			ImportSettings.ExchangeNode, "SendReceive");
		Result.SettingsImported = (CorrespondentSettings.Count() > 0);
		
		If Result.SettingsImported Then
			If AdditionalParameters.Property("DataReceivedForMapping") Then
				Result.DataReceivedForMapping = AdditionalParameters.DataReceivedForMapping;
			EndIf;
		EndIf;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure SaveSynchronizationSettings1(Parameters, ResultAddress) Export
	
	SynchronizationSettings = Undefined;
	Parameters.Property("SynchronizationSettings", SynchronizationSettings);
	
	Result = New Structure;
	Result.Insert("SettingsSaved", True);
	Result.Insert("ErrorMessage",  "");
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(SynchronizationSettings.ExchangeNode);
	
	If DataExchangeServer.HasExchangePlanManagerAlgorithm("OnSaveDataSynchronizationSettings", ExchangePlanName) Then
		BeginTransaction();
		Try
			Block = New DataLock;
		    LockItem = Block.Add(Common.TableNameByRef(SynchronizationSettings.ExchangeNode));
		    LockItem.SetValue("Ref", SynchronizationSettings.ExchangeNode);
		    Block.Lock();
			
			ObjectNode = SynchronizationSettings.ExchangeNode.GetObject(); // ExchangePlanObject
			ExchangePlans[ExchangePlanName].OnSaveDataSynchronizationSettings(ObjectNode,
				SynchronizationSettings.FillingData);
			ObjectNode.Write();
			
			If Not DataExchangeServer.SynchronizationSetupCompleted(SynchronizationSettings.ExchangeNode) Then
				DataExchangeServer.CompleteDataSynchronizationSetup(SynchronizationSettings.ExchangeNode);
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			Result.SettingsSaved = False;
			Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
				EventLogLevel.Error, , , Result.ErrorMessage);
		EndTry;
	Else
		If Not DataExchangeServer.SynchronizationSetupCompleted(SynchronizationSettings.ExchangeNode) Then
			DataExchangeServer.CompleteDataSynchronizationSetup(SynchronizationSettings.ExchangeNode);
		EndIf;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure DeleteSynchronizationSetting(Parameters, ResultAddress) Export
	
	DeletionSettings = Undefined;
	Parameters.Property("DeletionSettings", DeletionSettings);
	
	Result = New Structure;
	Result.Insert("SettingDeleted",                 True);
	Result.Insert("SettingDeletedInCorrespondent",  DeletionSettings.DeleteSettingItemInCorrespondent);
	Result.Insert("ErrorMessage",                "");
	Result.Insert("ErrorMessageInCorrespondent", "");
	
	// 1. Optional: Delete the sync setting in the peer application.
	If DeletionSettings.DeleteSettingItemInCorrespondent Then
		DeleteSynchronizationSettingInCorrespondent(DeletionSettings, Result);
		If Not Result.SettingDeletedInCorrespondent Then
			Result.SettingDeleted = False;
			Result.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot delete the synchronization setting in %1: %2.
				|
				|Try to delete it later or clear the ""Also delete the setting in…"" check box.'"),
				String(DeletionSettings.ExchangeNode),
				Result.ErrorMessageInCorrespondent);
				
			PutToTempStorage(Result, ResultAddress);
			Return;
		EndIf;
	EndIf;
	
	// 2. Delete the sync setting in this application.
	Try
		DataExchangeServer.DeleteSynchronizationSetting(DeletionSettings.ExchangeNode);
	Except
		Information = ErrorInfo();
		Result.SettingDeleted  = False;
		Result.ErrorMessage = ErrorProcessing.BriefErrorDescription(Information);
		
		WriteLogEvent(DataExchangeServer.DataExchangeDeletionEventLogEvent(),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(Information));
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure DeleteSynchronizationSettingInCorrespondent(DeletionSettings, Result)
	
	SetPrivilegedMode(True);
	
	Parameters = ExchangeMessagesTransport.InitializationParameters();
	Parameters.Peer = DeletionSettings.ExchangeNode;
	Parameters.AuthenticationData = DeletionSettings.AuthenticationData;
	
	Transport = ExchangeMessagesTransport.Initialize(Parameters);
	
	If Not Transport.DeleteSynchronizationSettingInCorrespondent() Then
		
		Result.ErrorMessageInCorrespondent = Transport.ErrorMessage;
		Result.SettingDeletedInCorrespondent = False;
		
	EndIf;
	
EndProcedure

Procedure RegisterDataForInitialExport(Parameters, ResultAddress) Export
	
	RegistrationSettings = Undefined;
	Parameters.Property("RegistrationSettings", RegistrationSettings);
	
	Result = New Structure;
	Result.Insert("DataRegistered", True);
	Result.Insert("ErrorMessage",      "");
	
	ReceivedNo = Common.ObjectAttributeValue(RegistrationSettings.ExchangeNode, "ReceivedNo");
	
	Try
		DataExchangeServer.RegisterDataForInitialExport(RegistrationSettings.ExchangeNode, , ReceivedNo = 0);
	Except
		Result.DataRegistered = False;
		Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.RegisterDataForInitialExportEventLogEvent(),
			EventLogLevel.Error, , , Result.ErrorMessage);
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Function NodeCode(ConnectionSettings)
	
	If ConnectionSettings.UsePrefixesForExchangeSettings
		Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings Then
		
		Return ConnectionSettings.SourceInfobasePrefix;
			
	Else
		
		Return ConnectionSettings.SourceInfobaseID;
		
	EndIf;
	
EndFunction

Function CorrespondentNodeCode(ConnectionSettings)
	
	If ConnectionSettings.UsePrefixesForExchangeSettings
		Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings Then
		
		Return ConnectionSettings.DestinationInfobasePrefix;
			
	Else
		
		Return ConnectionSettings.DestinationInfobaseID;
		
	EndIf;
	
EndFunction

Procedure CreateUpdateExchangePlanNodes(ConnectionSettings)
	
	ThisNodeCode  = NodeCode(ConnectionSettings);
	NewNodeCode = CorrespondentNodeCode(ConnectionSettings);
	RestoreExchangeSettings = TypeOf(ConnectionSettings) = Type("Structure") 
		And ConnectionSettings.Property("RestoreExchangeSettings")
		And StrFind(ConnectionSettings.RestoreExchangeSettings, "Restoring");
		
	ManagerExchangePlan = ExchangePlans[ConnectionSettings.ExchangePlanName]; // ExchangePlanManager
	
	// Refreshing predefined node code of this base if it is not filled in.
	ThisNode = ManagerExchangePlan.ThisNode();
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("ExchangePlan." + ConnectionSettings.ExchangePlanName);
		LockItem.SetValue("Ref", ThisNode);
		Block.Lock();
		
		ThisNodeProperties = Common.ObjectAttributesValues(ThisNode, "Code, Description");
		ThisNodeCodeInDatabase          = ThisNodeProperties.Code;
		ThisNodeDescriptionInBase = ThisNodeProperties.Description;
		
		UpdateCode          = False;
		UpdateDescription = False;
		
		If IsBlankString(ThisNodeCodeInDatabase) Then
			UpdateCode          = True;
			UpdateDescription = True;
		ElsIf ThisNodeCodeInDatabase <> ThisNodeCode Then
			If Not Common.DataSeparationEnabled()
				And Not DataExchangeServer.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName)
				And (ConnectionSettings.UsePrefixesForExchangeSettings
					Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings)
				And DataExchangeCached.ExchangePlanNodes(ConnectionSettings.ExchangePlanName).Count() = 0 Then
				
				UpdateCode = True;
				
			EndIf;
		EndIf;
			
		If RestoreExchangeSettings Then
			UpdateCode = True;
		EndIf;
		
		If Not UpdateDescription
			And Not Common.DataSeparationEnabled()
			And ThisNodeDescriptionInBase <> ConnectionSettings.ThisInfobaseDescription Then
			UpdateDescription = True;
		EndIf;
		
		If UpdateCode Or UpdateDescription Then
			ThisNodeObject = ThisNode.GetObject();
			If UpdateCode Then
				ThisNodeObject.Code = ThisNodeCode;
				ThisNodeCodeInDatabase  = ThisNodeCode;
			EndIf;
			If UpdateDescription Then
				ThisNodeObject.Description = ConnectionSettings.ThisInfobaseDescription;
			EndIf;
			ThisNodeObject.AdditionalProperties.Insert("GettingExchangeMessage");
			ThisNodeObject.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	CreateNewNode = False;
	
	// Get the peer infobase's node.
	If DataExchangeCached.IsDistributedInfobaseExchangePlan(ConnectionSettings.ExchangePlanName)
		And ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup" Then
		
		MasterNode = DataExchangeServer.MasterNode();
		
		If MasterNode = Undefined Then
			
			Raise NStr("en = 'The master node is not defined.
							|Probably this infobase is not a subordinate DIB node.'");
		EndIf;
		
		NewNode = MasterNode.GetObject();
		
		// Transferring common data from the predefined node.
		ThisNodeObject = ThisNode.GetObject();
		
		MetadataOfExchangePlan = NewNode.Metadata();
		SharedDataString = DataExchangeServer.ExchangePlanSettingValue(ConnectionSettings.ExchangePlanName,
			"CommonNodeData", ConnectionSettings.ExchangeSetupOption);
		
		SharedData = StrSplit(SharedDataString, ", ", False);
		For Each ItemCommonData In SharedData Do
			If MetadataOfExchangePlan.TabularSections.Find(ItemCommonData) = Undefined Then
				FillPropertyValues(NewNode, ThisNodeObject, ItemCommonData);
			Else
				NewNode[ItemCommonData].Load(ThisNodeObject[ItemCommonData].Unload());
			EndIf;
		EndDo;
	Else
		// Create or update a node.
		NewNodeRef = ManagerExchangePlan.FindByCode(NewNodeCode);
		
		CreateNewNode = NewNodeRef.IsEmpty();
		
		If CreateNewNode Then
			NewNode = ManagerExchangePlan.CreateNode();
			NewNode.Code = NewNodeCode;
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The %1 application prefix value is not unique (""%2""). A synchronization setting with the specified prefix already exists.
				|To continue, specify a unique infobase prefix different from the current one in %1.'"),
				ConnectionSettings.SecondInfobaseDescription, NewNodeCode);
		EndIf;
		
		NewNode.Description = ConnectionSettings.SecondInfobaseDescription;
		
		If Common.HasObjectAttribute("SettingsMode", Metadata.ExchangePlans[ConnectionSettings.ExchangePlanName]) Then
			NewNode.SettingsMode = ConnectionSettings.ExchangeSetupOption;
		EndIf;
		
		If CreateNewNode Then
			NewNode.Fill(Undefined);
		EndIf;
		
		If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
			If ValueIsFilled(ConnectionSettings.ExchangeFormatVersion) Then
				NewNode.ExchangeFormatVersion = ConnectionSettings.ExchangeFormatVersion;
			EndIf;
		EndIf;
		
	EndIf;
	
	// Reset message counters.
	NewNode.SentNo = 0;
	NewNode.ReceivedNo     = 0;
	
	If RestoreExchangeSettings Then
		NewNode.SentNo = ConnectionSettings.ReceivedNo;
		NewNode.ReceivedNo = ConnectionSettings.SentNo;
	EndIf;
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable()
		And DataExchangeServer.IsSeparatedSSLExchangePlan(ConnectionSettings.ExchangePlanName) Then
		
		NewNode.RegisterChanges = True;
		
	EndIf;
	
	If ValueIsFilled(ConnectionSettings.RefToNew) Then
		NewNode.SetNewObjectRef(ConnectionSettings.RefToNew);
	EndIf;
	
	NewNode.DataExchange.Load = True;
	NewNode.Write();
	
	If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
		If ConnectionSettings.SupportedObjectsInFormat <> Undefined Then
			InformationRegisters.XDTODataExchangeSettings.UpdateCorrespondentSettings(NewNode.Ref,
				"SupportedObjects", ConnectionSettings.SupportedObjectsInFormat.Get());
		EndIf;
		
		DataExchangeLoopControl.UpdateCircuit(ConnectionSettings.ExchangePlanName);

		RecordStructure = New Structure;
		RecordStructure.Insert("InfobaseNode", NewNode.Ref);
		RecordStructure.Insert("CorrespondentExchangePlanName", ConnectionSettings.CorrespondentExchangePlanName);
		
		DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "XDTODataExchangeSettings");
		
	EndIf;
	
	ConnectionSettings.InfobaseNode = NewNode.Ref;
	
	// Shared node data.
	InformationRegisters.CommonInfobasesNodesSettings.UpdatePrefixes(
		ConnectionSettings.InfobaseNode,
		?(ConnectionSettings.UsePrefixesForExchangeSettings
			Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings, ConnectionSettings.SourceInfobasePrefix, ""),
		ConnectionSettings.DestinationInfobasePrefix);
		
	InformationRegisters.CommonInfobasesNodesSettings.SetNameOfCorrespondentExchangePlan(
		ConnectionSettings.InfobaseNode,
		ConnectionSettings.CorrespondentExchangePlanName);
			
	If CreateNewNode
		And Not Common.DataSeparationEnabled() Then
		DataExchangeServer.UpdateDataExchangeRules();
	EndIf;
	
	If ThisNodeCode <> ThisNodeCodeInDatabase
		And DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName)
		And (ConnectionSettings.UsePrefixesForExchangeSettings
			Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings) Then
		// Node in the correspondent base needs recoding.
		StructureTemporaryCode = New Structure;
		StructureTemporaryCode.Insert("Peer", ConnectionSettings.InfobaseNode);
		StructureTemporaryCode.Insert("NodeCode",       ThisNodeCode);
		
		DataExchangeInternal.AddRecordToInformationRegister(StructureTemporaryCode, "PredefinedNodesAliases");
	EndIf;

EndProcedure

Function GettingCorrespondentParameters(ConnectionSettings) Export
	
	SetPrivilegedMode(True);
	
	InitializationParameters = ExchangeMessagesTransport.InitializationParameters();
	FillPropertyValues(InitializationParameters, ConnectionSettings);
	
	Transport = ExchangeMessagesTransport.Initialize(InitializationParameters);
	CorrespondentParameters = Transport.CorrespondentParameters(ConnectionSettings);
	
	Return CorrespondentParameters;
	
EndFunction

#EndRegion

#EndIf