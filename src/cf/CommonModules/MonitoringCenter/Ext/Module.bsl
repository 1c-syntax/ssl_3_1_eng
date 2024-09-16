///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region Common

// Checks the subsystem status.
// Returns:
//  Boolean - 
//
Function MonitoringCenterEnabled() Export
	MonitoringCenterParameters = New Structure("EnableMonitoringCenter, ApplicationInformationProcessingCenter");
	MonitoringCenterParameters = MonitoringCenterInternal.GetMonitoringCenterParametersExternalCall(
		MonitoringCenterParameters);
	Return MonitoringCenterParameters.EnableMonitoringCenter
		Or MonitoringCenterParameters.ApplicationInformationProcessingCenter;
EndFunction

// It includes the Central Monitoring subsystem.
//
Procedure EnableSubsystem() Export

	MonitoringCenterParameters = MonitoringCenterInternal.GetMonitoringCenterParameters();

	MonitoringCenterParameters.EnableMonitoringCenter = True;
	MonitoringCenterParameters.ApplicationInformationProcessingCenter = False;

	MonitoringCenterInternal.SetMonitoringCenterParametersExternalCall(MonitoringCenterParameters);
	SchedJob = MonitoringCenterInternal.GetScheduledJobExternalCall("StatisticsDataCollectionAndSending", True);
	MonitoringCenterInternal.SetDefaultScheduleExternalCall(SchedJob);

EndProcedure

// Disables the Monitoring Center subsystem.
//
Procedure DisableSubsystem() Export

	MonitoringCenterParameters = MonitoringCenterInternal.GetMonitoringCenterParameters();

	MonitoringCenterParameters.EnableMonitoringCenter = False;
	MonitoringCenterParameters.ApplicationInformationProcessingCenter = False;

	MonitoringCenterInternal.SetMonitoringCenterParametersExternalCall(MonitoringCenterParameters);
	MonitoringCenterInternal.DeleteScheduledJobExternalCall("StatisticsDataCollectionAndSending");

EndProcedure

// Returns a string representation of the ID of the information base in the monitoring center.
// Returns:
//  String - 
//
Function InfoBaseID() Export

	ParametersToGet = New Structure;
	ParametersToGet.Insert("EnableMonitoringCenter");
	ParametersToGet.Insert("ApplicationInformationProcessingCenter");
	ParametersToGet.Insert("DiscoveryPackageSent");
	ParametersToGet.Insert("LastPackageNumber");
	ParametersToGet.Insert("InfoBaseID");
	MonitoringCenterParameters = MonitoringCenterInternal.GetMonitoringCenterParameters(ParametersToGet);

	If (MonitoringCenterParameters.EnableMonitoringCenter
		Or MonitoringCenterParameters.ApplicationInformationProcessingCenter)
		And MonitoringCenterParameters.DiscoveryPackageSent Then
		Return String(MonitoringCenterParameters.InfoBaseID);
	EndIf;
	
	// 
	Return "";

EndFunction

#EndRegion

#Region BusinessStatistics

// Records a business statistics operation.
//
// Parameters:
//  OperationName	- String	-  the name of the statistics operation, in case of absence, a new one is created.
//  Value	- Number		-  the quantitative value of the statistics operation.
//  Comment	- String	-  arbitrary comment.
//  Separator	- String	-  the value separator in the operation name, if the separator is not a dot.
//
Procedure WriteBusinessStatisticsOperation(OperationName, Value, Comment = Undefined, Separator = ".") Export
	If WriteBusinessStatisticsOperations() Then
		InformationRegisters.StatisticsOperationsClipboard.WriteBusinessStatisticsOperation(OperationName, Value, Comment,
			Separator);
	EndIf;
EndProcedure

// Records a unique operation of business statistics in the context of an hour.
// Checks uniqueness when recording.
//
// Parameters:
//  OperationName      - String -  the name of the statistics operation, in case of absence, a new one is created.
//  UniqueKey - String -  the key to control the uniqueness of the record, the maximum length is 100.
//  Value         - Number  -  the quantitative value of the statistics operation.
//  Replace         - Boolean -  defines the replacement mode of an existing record.
//                              True - before recording, the existing record will be deleted.
//                              False - if the record already exists, the new data is ignored.
//                              Default value: False.
//
Procedure WriteBusinessStatisticsOperationHour(OperationName, UniqueKey, Value, Replace = False) Export

	WriteParameters = New Structure("OperationName, UniqueKey, Value, Replace, EntryType, RecordPeriod");
	WriteParameters.OperationName = OperationName;
	WriteParameters.UniqueKey = UniqueKey;
	WriteParameters.Value = Value;
	WriteParameters.Replace = Replace;
	WriteParameters.EntryType = 1;
	WriteParameters.RecordPeriod = BegOfHour(CurrentUniversalDate());

	MonitoringCenterInternal.WriteBusinessStatisticsOperationInternal(WriteParameters);

EndProcedure

// Records a unique operation of business statistics in the context of the day.
// Checks uniqueness when recording.
//
// Parameters:
//  OperationName      - String -  the name of the statistics operation, in case of absence, a new one is created.
//  UniqueKey - String -  the key to control the uniqueness of the record, the maximum length is 100.
//  Value         - Number  -  the quantitative value of the statistics operation.
//  Replace         - Boolean -  defines the replacement mode of an existing record.
//                              True - before recording, the existing record will be deleted.
//                              False - if the record already exists, the new data is ignored.
//                              Default value: False.
//
Procedure WriteBusinessStatisticsOperationDay(OperationName, UniqueKey, Value, Replace = False) Export

	WriteParameters = New Structure("OperationName, UniqueKey, Value, Replace, EntryType, RecordPeriod");
	WriteParameters.OperationName = OperationName;
	WriteParameters.UniqueKey = UniqueKey;
	WriteParameters.Value = Value;
	WriteParameters.Replace = Replace;
	WriteParameters.EntryType = 2;
	WriteParameters.RecordPeriod = BegOfDay(CurrentUniversalDate());

	MonitoringCenterInternal.WriteBusinessStatisticsOperationInternal(WriteParameters);

EndProcedure


// Returns the registration status of business statistics.
// Returns:
//  Boolean - 
//
Function WriteBusinessStatisticsOperations() Export
	MonitoringCenterParameters = New Structure("EnableMonitoringCenter, ApplicationInformationProcessingCenter, RegisterBusinessStatistics");

	MonitoringCenterInternal.GetMonitoringCenterParameters(MonitoringCenterParameters);

	Return (MonitoringCenterParameters.EnableMonitoringCenter
		Or MonitoringCenterParameters.ApplicationInformationProcessingCenter)
		And MonitoringCenterParameters.RegisterBusinessStatistics;
EndFunction

#EndRegion

#Region ConfigurationStatistics

// Records statistics on configuration objects.
//
// Parameters:
//  MetadataNamesMap - Structure:
//   * Key		- String - 	 	the name of the metadata object.
//   * Value	- String - 	 	the text of the data sampling request
//							, the Quantity field must be present. If the Quantity is zero,
//                          then no recording occurs.
//
Procedure WriteConfigurationStatistics(MetadataNamesMap) Export
	Parameters = New Map;
	For Each CurMetadata In MetadataNamesMap Do
		Parameters.Insert(CurMetadata.Key, New Structure("Query, StatisticsOperations, StatisticsKind",
			CurMetadata.Value, , 0));
	EndDo;

	If Common.DataSeparationEnabled() And Common.SubsystemExists(
		"CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		DataAreaRow = Format(ModuleSaaSOperations.SessionSeparatorValue(), "NG=0");
	Else
		DataAreaRow = "0";
	EndIf;
	DataAreaRef = InformationRegisters.StatisticsAreas.GetRef(DataAreaRow);

	InformationRegisters.ConfigurationStatistics.Write(Parameters, DataAreaRef);
EndProcedure

// Records statistics on the configuration object.
//
// Parameters:
//  ObjectName -	String	-  the name of the statistics operation, in case of absence, a new one is created.
//  Value - 		Number	-  the quantitative value of the statistics operation. If the value
//                            is zero, then no recording occurs.
//
Procedure WriteConfigurationObjectStatistics(ObjectName, Value) Export

	If Value <> 0 Then
		StatisticsOperation = MonitoringCenterCached.GetStatisticsOperationRef(ObjectName);

		If Common.DataSeparationEnabled() And Common.SubsystemExists(
			"CloudTechnology.Core") Then
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			DataAreaRow = Format(ModuleSaaSOperations.SessionSeparatorValue(), "NG=0");
		Else
			DataAreaRow = "0";
		EndIf;
		DataAreaRef = InformationRegisters.StatisticsAreas.GetRef(DataAreaRow);

		RecordSet = InformationRegisters.ConfigurationStatistics.CreateRecordSet();
		RecordSet.Filter.StatisticsOperation.Set(StatisticsOperation);

		NewRecord1 = RecordSet.Add();
		NewRecord1.StatisticsAreaID = DataAreaRef;
		NewRecord1.StatisticsOperation = StatisticsOperation;
		NewRecord1.Value = Value;
		RecordSet.Write(True);
	EndIf;

EndProcedure

#EndRegion

#EndRegion