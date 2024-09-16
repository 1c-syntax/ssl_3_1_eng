///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region PublicBusinessStatistics

// 
// 
// 
// 
//
// Parameters:
//  OperationName	- String	-  the name of the statistics operation, in case of absence, a new one is created.
//  Value	- Number		-  the quantitative value of the statistics operation.
//
Procedure WriteBusinessStatisticsOperation(OperationName, Value) Export
    
    If RegisterBusinessStatistics() Then 
        WriteParameters = New Structure("OperationName,Value, EntryType");
        WriteParameters.OperationName = OperationName;
        WriteParameters.Value = Value;
        WriteParameters.EntryType = 0;
        
        WriteBusinessStatisticsOperationInternal(WriteParameters);
    EndIf;
    
EndProcedure

// 
// 
// 
// 
// 
//
// Parameters:
//  OperationName      - String -  the name of the statistics operation, in case of absence, a new one is created.
//  Value         - Number  -  the quantitative value of the statistics operation.
//  Replace         - Boolean -  defines the replacement mode of an existing record.
//                              True - before recording, the existing record will be deleted.
//                              False - if the record already exists, the new data is ignored.
//                              Default value: False.
//  UniqueKey - String -  the key to control the uniqueness of the record, the maximum length is 100. If omitted,
//                              an MD5 hash of the unique user ID and session number is used.
//                              Default value: Undefined.
//
Procedure WriteBusinessStatisticsOperationHour(OperationName, Value, Replace = False, UniqueKey = Undefined) Export
    
    If RegisterBusinessStatistics() Then
        WriteParameters = New Structure("OperationName, UniqueKey, Value, Replace, EntryType");
        WriteParameters.OperationName = OperationName;
        WriteParameters.UniqueKey = UniqueKey;
        WriteParameters.Value = Value;
        WriteParameters.Replace = Replace;
        WriteParameters.EntryType = 1;
        
        WriteBusinessStatisticsOperationInternal(WriteParameters);
    EndIf;
    
EndProcedure

// 
// 
// 
// 
// 
//
// Parameters:
//  OperationName      - String -  the name of the statistics operation, in case of absence, a new one is created.
//  Value         - Number  -  the quantitative value of the statistics operation.
//  Replace         - Boolean -  defines the replacement mode of an existing record.
//                              True - before recording, the existing record will be deleted.
//                              False - if the record already exists, the new data is ignored.
//                              Default value: False.
//  UniqueKey - String -  the key to control the uniqueness of the record, the maximum length is 100. If omitted,
//                              an MD5 hash of the unique user ID and session number is used.
//                              Default value: Undefined.
//
Procedure WriteBusinessStatisticsOperationDay(OperationName, Value, Replace = False, UniqueKey = Undefined) Export
    
    If RegisterBusinessStatistics() Then
        WriteParameters = New Structure("OperationName, UniqueKey, Value, Replace, EntryType");
        WriteParameters.OperationName = OperationName;
        WriteParameters.UniqueKey = UniqueKey;
        WriteParameters.Value = Value;
        WriteParameters.Replace = Replace;
        WriteParameters.EntryType = 2;
        
        WriteBusinessStatisticsOperationInternal(WriteParameters);
    EndIf;
    
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Procedure ShowMonitoringCenterSettings(OwnerForm, FormParameters) Export
	OpenForm("DataProcessor.MonitoringCenterSettings.Form.MonitoringCenterSettings",
		FormParameters, OwnerForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

Procedure ShowSendSettingOfContactInfo(OwnerForm) Export
	OpenForm("DataProcessor.MonitoringCenterSettings.Form.SendContactInformation",,
		OwnerForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#EndRegion

#Region Private

Procedure WriteBusinessStatisticsOperationInternal(WriteParameters)
    
    MonitoringCenterApplicationParameters = MonitoringCenterClientInternal.GetApplicationParameters();
    Measurements = MonitoringCenterApplicationParameters["Measurements"][WriteParameters.EntryType];
    
    Measurement = New Structure("EntryType, Key, StatisticsOperation, Value, Replace");
    Measurement.EntryType = WriteParameters.EntryType;
    Measurement.StatisticsOperation = WriteParameters.OperationName;
    Measurement.Value = WriteParameters.Value;
    
    If Measurement.EntryType = 0 Then
        
        Measurements.Add(Measurement);
        
    Else
        
        If WriteParameters.UniqueKey = Undefined Then
            Measurement.Key = MonitoringCenterApplicationParameters["ClientInformation"]["ClientParameters"]["UserHash"];
        Else
            Measurement.Key = WriteParameters.UniqueKey;
        EndIf;
        
        Measurement.Replace = WriteParameters.Replace;
        
        If Not (Measurements[Measurement.Key] <> Undefined And Not Measurement.Replace) Then
            Measurements.Insert(Measurement.Key, Measurement);
        EndIf;
        
    EndIf;
        
EndProcedure

Function RegisterBusinessStatistics()
    
    ParameterName = "StandardSubsystems.MonitoringCenter";
    
    If ApplicationParameters[ParameterName] = Undefined Then
        ApplicationParameters.Insert(ParameterName, MonitoringCenterClientInternal.GetApplicationParameters());
    EndIf;
        
    Return ApplicationParameters[ParameterName]["RegisterBusinessStatistics"];
    
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
Procedure AfterUpdateID(Result, AdditionalParameters) Export	
	If Result <> Undefined Then
		Notify("IDUpdateMonitoringCenter", Result);
	EndIf;	
EndProcedure

#EndRegion