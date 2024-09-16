///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Sets the value of the constant dateappearance of re-used Valuespro.
// The current date of the computer (server) is used as the set value.
// When the value of this constant is changed, the re-used values 
// for the data exchange subsystem become irrelevant and require reinitialization.
// 
Procedure ResetObjectsRegistrationMechanismCache() Export
	
	DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
	
EndProcedure

#EndRegion

#Region Internal

// Returns the status of the background task.
// Used to implement the logic of long-running operations.
//
// Parameters:
//  JobID - UUID -  ID of the background task to get
//                                                   the status for.
// 
// Returns:
//  String - :
//   
//   
//   
//
Function JobState(Val JobID) Export
	
	Try
		Result = ?(TimeConsumingOperations.JobCompleted(JobID), "Completed", "Active");
	Except
		Result = "Failed";
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return Result;
EndFunction

// Deletes the data synchronization setting.
//
Procedure DeleteSynchronizationSetting(Val InfobaseNode) Export
	
	DataExchangeServer.DeleteSynchronizationSetting(InfobaseNode);
	
EndProcedure

#EndRegion

#Region Private

// Performs the data exchange process separately for each exchange setup line.
// The data exchange process consists of two stages:
// - initialization of the exchange-preparation of the data exchange subsystem for the exchange process
// - data exchange        - the process of reading the message file and then uploading this data to the is 
//                          or uploading changes to the message file.
// The initialization stage is performed once per session and is stored in the session cache on the server 
// until the session is restarted or the data exchange subsystem resets reused values.
// Reused values are reset when data changes that affect the data exchange process
// (transport settings, exchange execution settings, selection settings on exchange plan nodes).
//
// The exchange can be performed completely for all lines of the script,
// or it can be performed for a separate line of the PM exchange script.
//
// Parameters:
//  Cancel                     - Boolean -  failure flag; raised if an error occurs during script execution.
//  ExchangeExecutionSettings - CatalogRef.DataExchangeScenarios -  a reference
//                              list element that will be used for data exchange.
//  LineNumber               - Number -  number of the line that will be used for data exchange.
//                              If not specified, then the data exchange will be executed for all rows.
// 
Procedure ExecuteDataExchangeByDataExchangeScenario(Cancel, ExchangeExecutionSettings, LineNumber = Undefined) Export
	
	DataExchangeServer.ExecuteDataExchangeByDataExchangeScenario(Cancel, ExchangeExecutionSettings, LineNumber);
	
EndProcedure

// Records the successful execution of data exchange in the system.
//
Procedure RecordDataExportInTimeConsumingOperationMode(Val InfobaseNode, Val StartDate) Export
	
	SetPrivilegedMode(True);
	
	ActionOnExchange = Enums.ActionsOnExchange.DataExport;
	
	ExchangeSettingsStructure = New Structure;
	ExchangeSettingsStructure.Insert("InfobaseNode", InfobaseNode);
	ExchangeSettingsStructure.Insert("ExchangeExecutionResult", Enums.ExchangeExecutionResults.Completed2);
	ExchangeSettingsStructure.Insert("ActionOnExchange", ActionOnExchange);
	ExchangeSettingsStructure.Insert("ProcessedObjectsCount", 0);
	ExchangeSettingsStructure.Insert("EventLogMessageKey", DataExchangeServer.EventLogMessageKey(InfobaseNode, ActionOnExchange));
	ExchangeSettingsStructure.Insert("StartDate", StartDate);
	ExchangeSettingsStructure.Insert("EndDate", CurrentSessionDate());
	ExchangeSettingsStructure.Insert("IsDIBExchange", DataExchangeCached.IsDistributedInfobaseNode(InfobaseNode));
	
	DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);
	
EndProcedure

// Detects an emergency termination of data exchange.
//
Procedure WriteExchangeFinishWithError(Val InfobaseNode,
												Val ActionOnExchange,
												Val StartDate,
												Val ErrorMessageString) Export
	
	SetPrivilegedMode(True);
	
	DataExchangeServer.WriteExchangeFinishWithError(InfobaseNode,
											ActionOnExchange,
											StartDate,
											ErrorMessageString);
EndProcedure

// Returns an indication that the register recordset does not contain data.
//
Function RegisterRecordSetIsEmpty(RecordStructure, RegisterName) Export
	
	// 
	RecordSet = InformationRegisters[RegisterName].CreateRecordSet(); // InformationRegisterRecordSet
	
	For Each FilterElement In RecordSet.Filter Do
		FilterValue = Undefined;
		If RecordStructure.Property(FilterElement.Name, FilterValue) Then
			FilterElement.Set(FilterValue);
		EndIf;
	EndDo;
	
	RecordSet.Read();
	
	Return RecordSet.Count() = 0;
	
EndFunction

// Returns the key of the log message for the action string.
//
Function EventLogMessageKeyByActionString(InfobaseNode, ActionOnStringExchange) Export
	
	SetPrivilegedMode(True);
	
	Return DataExchangeServer.EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange[ActionOnStringExchange]);
	
EndFunction

// Returns a structure with selection data for the log.
//
Function EventLogFilterData(InfobaseNode, Val ActionOnExchange) Export
	
	If TypeOf(ActionOnExchange) = Type("String") Then
		
		ActionOnExchange = Enums.ActionsOnExchange[ActionOnExchange];
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	DataExchangesStates = DataExchangeServer.DataExchangesStates(InfobaseNode, ActionOnExchange);
	
	Filter = New Structure;
	Filter.Insert("EventLogEvent", DataExchangeServer.EventLogMessageKey(InfobaseNode, ActionOnExchange));
	Filter.Insert("StartDate",                DataExchangesStates.StartDate);
	Filter.Insert("EndDate",             DataExchangesStates.EndDate);
	
	Return Filter;
	
EndFunction

// Returns an array of all reference types defined in the configuration.
//
Function AllConfigurationReferenceTypes() Export
	
	Return DataExchangeCached.AllConfigurationReferenceTypes();
	
EndFunction

Function DataExchangeOption(Val Peer) Export
	
	SetPrivilegedMode(True);
	
	Return DataExchangeServer.DataExchangeOption(Peer);
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Retrieves a list of metadata for node objects that are not allowed to be uploaded.
// Uploading is not allowed if the table is marked as non-Upload in the rules for registering exchange plan objects.
//
// Parameters:
//     InfobaseNode - ExchangePlanRef -  link to the exchange plan node being analyzed.
//
// Returns:
//     Array - 
//
Function NotExportedNodeObjectsMetadataNames(Val InfobaseNode) Export
	Result = New Array;
	
	NotExportMode = Enums.ExchangeObjectExportModes.NotExport;
	ExportModes   = DataExchangeCached.UserExchangePlanComposition(InfobaseNode);
	For Each KeyValue In ExportModes Do
		If KeyValue.Value=NotExportMode Then
			Result.Add(KeyValue.Key);
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

// Checks whether the specified exchange node is the main one.
//
// Parameters:
//   InfobaseNode - ExchangePlanRef -  link to the exchange plan node
//       to check whether it is the main one or not.
//
// Returns:
//   Boolean
//
Function IsMasterNode(Val InfobaseNode) Export
	
	Return ExchangePlans.MasterNode() = InfobaseNode;
	
EndFunction

// Creates a request to clear permissions for the node (on deletion).
//
Function RequestToClearPermissionsToUseExternalResources(Val InfobaseNode) Export
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	Query = ModuleSafeModeManager.RequestToClearPermissionsToUseExternalResources(InfobaseNode);
	Return CommonClientServer.ValueInArray(Query);
	
EndFunction

Procedure DownloadExtensions() Export
	
	If Not Users.IsFullUser(, True, False) Then
		Return;
	EndIf;
	
	InfobaseNode = ExchangePlans.MasterNode();
		
	If InfobaseNode <> Undefined Then
		
		DataExchangeServer.DisableDataExchangeMessageImportRepeatBeforeStart();
		
		SetPrivilegedMode(True);
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", True);
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("DownloadingExtensions", True);
		SetPrivilegedMode(False);
		
		// 
		DataExchangeServer.UpdateDataExchangeRules();
		
		TransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(InfobaseNode);
					
		ExchangeParameters = DataExchangeServer.ExchangeParameters();
		ExchangeParameters.ExchangeMessagesTransportKind = TransportKind;
		ExchangeParameters.ExecuteImport1 = True;
		ExchangeParameters.ExecuteExport2 = False;		
		ExchangeParameters.TimeConsumingOperationAllowed = False;
		ExchangeParameters.ParametersOnly = True;
						
		Cancel = False;
		Try			
			
			DataExchangeServer.ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, Cancel);
			
		Except
			
			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EventLogEvent = NStr("en = 'Data exchange.Load extension';", Common.DefaultLanguageCode());
			WriteLogEvent(EventLogEvent, EventLogLevel.Error, , , ErrorMessage);
						
		EndTry;
			
		DataExchangeInternal.DisableLoadingExtensionsThatChangeTheDataStructure();	
		
	EndIf;
	
EndProcedure

// Parameters:
//   ObjectNode - ExchangePlanObject
//
Function CheckTheNeedForADeferredNodeEntry(Val ObjectNode) Export
	
	PropertiesToExclude = New Array;
	PropertiesToExclude.Add("SentNo");
	PropertiesToExclude.Add("ReceivedNo");
	PropertiesToExclude.Add("DeletionMark");
	PropertiesToExclude.Add("Code");
	PropertiesToExclude.Add("Description");
	
	If Common.DataSeparationEnabled() Then
		FullMetadataName = ObjectNode.Ref.Metadata().FullName();
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		
		MainDataSeparator        = ModuleSaaSOperations.MainDataSeparator();
		AuxiliaryDataSeparator = ModuleSaaSOperations.AuxiliaryDataSeparator();
		
		If ModuleSaaSOperations.IsSeparatedMetadataObject(FullMetadataName, MainDataSeparator) Then
			PropertiesToExclude.Add(MainDataSeparator);
		EndIf;
		
		If ModuleSaaSOperations.IsSeparatedMetadataObject(FullMetadataName, AuxiliaryDataSeparator) Then
			PropertiesToExclude.Add(AuxiliaryDataSeparator);
		EndIf;
		
	EndIf;
	
	NodeType = Type("ExchangePlanObject." + ObjectNode.Ref.Metadata().Name);
	NodeBeforeWrite = FormDataToValue(ObjectNode, NodeType); //ExchangePlanObject
		
	Result = New Structure;
	Result.Insert("ALongTermOperationIsRequired"	, False);
	Result.Insert("ThereIsAnActiveBackgroundTask" 	, False);
	Result.Insert("NodeStructureAddress"				, Undefined);
	
	If Not ObjectNode.Ref.IsEmpty()
		And Not ObjectNode.ThisNode
		And DataExchangeEvents.DataDiffers1(NodeBeforeWrite, ObjectNode.Ref.GetObject(), , StrConcat(PropertiesToExclude, ","))
		And DataExchangeInternal.ChangesRegistered(ObjectNode.Ref) Then
		
		Result.ALongTermOperationIsRequired = True;
		
		//
		Filter = New Structure;
		Filter.Insert("Key",      "DeferredNodeWriting");
		Filter.Insert("State", BackgroundJobState.Active);

		ActiveBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
		Result.ThereIsAnActiveBackgroundTask = ActiveBackgroundJobs.Count() > 0;
		
		//
		NodeStructure = New Structure;
	
		NodeMetadata = NodeBeforeWrite.Ref.Metadata();
		
		For Each Attribute In NodeMetadata.Attributes Do
			NodeStructure.Insert(Attribute.Name, NodeBeforeWrite[Attribute.Name]);			
		EndDo;
		
		For Each Table In NodeMetadata.TabularSections Do		
			Tab = NodeBeforeWrite[Table.Name].Unload();
			NodeStructure.Insert(Table.Name, Tab);				
		EndDo;
		
		Result.NodeStructureAddress = PutToTempStorage(NodeStructure, New UUID);
					
	EndIf;
	
	Return Result;
	
EndFunction

Function CheckAndRegisterCOMConnector(Val SettingsStructure_) Export
	
	If TypeOf(SettingsStructure_) <> Type("Structure") Then
		SettingsStructure_ = InformationRegisters.DataExchangeTransportSettings.TransportSettings(
			SettingsStructure_, Enums.ExchangeMessagesTransportTypes.COM)
	EndIf;
		
	Result = DataExchangeServer.EstablishExternalConnectionWithInfobase(SettingsStructure_);
	
	If Result.Join = Undefined Then
		Return False;
	EndIf;
	
	Result = Undefined;
	
	Return True;
	
EndFunction

#EndRegion