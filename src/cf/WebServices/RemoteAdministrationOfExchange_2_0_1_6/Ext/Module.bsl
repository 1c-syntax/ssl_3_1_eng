///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 

// Corresponds to the GetExchangePlans operation
Function GetConfigurationExchangePlans()
	
	Return StrConcat(DataExchangeSaaSCached.DataSynchronizationExchangePlans(), ",");
EndFunction

// Corresponds to the PrepareExchangeExecution operation
Function ScheduleDataExchangeExecution(DataExchangeAreasXDTO)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return "";
	EndIf;
		
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	
	AreasForDataExchange = XDTOSerializer.ReadXDTO(DataExchangeAreasXDTO);
	
	SetPrivilegedMode(True);
	
	For Each Item In AreasForDataExchange Do
		
		SeparatorValue = Item.Key;
		DataExchangeScenario = Item.Value;
		
		Parameters = New Array;
		Parameters.Add(DataExchangeScenario);
		
		JobParameters = New Structure;
		JobParameters.Insert("MethodName"    , "DataExchangeSaaS.ExecuteDataExchange");
		JobParameters.Insert("Parameters"    , Parameters);
		JobParameters.Insert("Key"         , "1");
		JobParameters.Insert("DataArea", SeparatorValue);
		
		Try
			ModuleJobsQueue.AddJob(JobParameters);
		Except
			If ErrorInfo().Description <> ModuleJobsQueue.GetExceptionTextJobsWithSameKeyDuplication() Then
				Raise;
			EndIf;
		EndTry;
		
	EndDo;
	
	Return "";
EndFunction

// Corresponds to the StartExchangeExecutionInFirstDatabase operation
Function ExecuteDataExchangeScenarioActionInFirstInfobase(ScenarioRowIndex, DataExchangeScenarioXDTO)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return "";
	EndIf;
		
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	
	DataExchangeScenario = XDTOSerializer.ReadXDTO(DataExchangeScenarioXDTO);
	
	ScenarioRow = DataExchangeScenario[ScenarioRowIndex];
	
	Var_Key = ScenarioRow.ExchangePlanName + ScenarioRow.InfobaseNodeCode + ScenarioRow.ThisNodeCode;
	
	ExchangeMode = DataExchangeMode(DataExchangeScenario);
	
	If ExchangeMode = "Manual" Then
		
		Parameters = New Array;
		Parameters.Add(ScenarioRowIndex);
		Parameters.Add(DataExchangeScenario);
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		
		SetPrivilegedMode(True);
		ModuleSaaSOperations.SetSessionSeparation(True, ScenarioRow.ValueOfSeparatorOfFirstInformationBase);
		SetPrivilegedMode(False);
		
		ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(
			"DataExchangeSaaS.ExecuteDataExchangeScenarioActionInFirstInfobase",
			Parameters,
			Var_Key);
			
		SetPrivilegedMode(True);
		ModuleSaaSOperations.SetSessionSeparation(False);
		SetPrivilegedMode(False);
		
	ElsIf ExchangeMode = "Automatic" Then
		
		Try
			Parameters = New Array;
			Parameters.Add(ScenarioRowIndex);
			Parameters.Add(DataExchangeScenario);
			
			JobParameters = New Structure;
			JobParameters.Insert("DataArea", ScenarioRow.ValueOfSeparatorOfFirstInformationBase);
			JobParameters.Insert("MethodName", "DataExchangeSaaS.ExecuteDataExchangeScenarioActionInFirstInfobase");
			JobParameters.Insert("Parameters", Parameters);
			JobParameters.Insert("Key", Var_Key);
			JobParameters.Insert("Use", True);
			
			SetPrivilegedMode(True);
			ModuleJobsQueue.AddJob(JobParameters);
		Except
			If ErrorInfo().Description <> ModuleJobsQueue.GetExceptionTextJobsWithSameKeyDuplication() Then
				Raise;
			EndIf;
		EndTry;
		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Unknown data exchange mode: %1';"), String(ExchangeMode));
	EndIf;
	
	Return "";
EndFunction

// Corresponds to the StartExchangeExecutionInSecondDatabase operation
Function ExecuteDataExchangeScenarioActionInSecondInfobase(ScenarioRowIndex, DataExchangeScenarioXDTO)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return "";
	EndIf;
		
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	
	DataExchangeScenario = XDTOSerializer.ReadXDTO(DataExchangeScenarioXDTO);
	
	ScenarioRow = DataExchangeScenario[ScenarioRowIndex];
	
	Var_Key = ScenarioRow.ExchangePlanName + ScenarioRow.InfobaseNodeCode + ScenarioRow.ThisNodeCode;
	
	ExchangeMode = DataExchangeMode(DataExchangeScenario);
	
	If ExchangeMode = "Manual" Then
		
		Parameters = New Array;
		Parameters.Add(ScenarioRowIndex);
		Parameters.Add(DataExchangeScenario);
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		
		SetPrivilegedMode(True);
		ModuleSaaSOperations.SetSessionSeparation(True, ScenarioRow.ValueOfSeparatorOfSecondInformationBase);
		SetPrivilegedMode(False);
		
		ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(
			"DataExchangeSaaS.ExecuteDataExchangeScenarioActionInSecondInfobase",
			Parameters,
			Var_Key);
			
		SetPrivilegedMode(True);
		ModuleSaaSOperations.SetSessionSeparation(False);
		SetPrivilegedMode(False);
		
	ElsIf ExchangeMode = "Automatic" Then
		
		Try
			Parameters = New Array;
			Parameters.Add(ScenarioRowIndex);
			Parameters.Add(DataExchangeScenario);
			
			JobParameters = New Structure;
			JobParameters.Insert("DataArea", ScenarioRow.ValueOfSeparatorOfSecondInformationBase);
			JobParameters.Insert("MethodName", "DataExchangeSaaS.ExecuteDataExchangeScenarioActionInSecondInfobase");
			JobParameters.Insert("Parameters", Parameters);
			JobParameters.Insert("Key", Var_Key);
			JobParameters.Insert("Use", True);
			
			SetPrivilegedMode(True);
			ModuleJobsQueue.AddJob(JobParameters);
		Except
			If ErrorInfo().Description <> ModuleJobsQueue.GetExceptionTextJobsWithSameKeyDuplication() Then
				Raise;
			EndIf;
		EndTry;
		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Unknown data exchange mode: %1';"), String(ExchangeMode));
	EndIf;
	
	Return "";
EndFunction

// Corresponds to the TestConnection operation
Function TestConnection(SettingsStructureXTDO, TransportKindAsString, ErrorMessage)
	
	Cancel = False;
	
	// 
	DataExchangeServer.CheckExchangeMessageTransportDataProcessorAttachment(Cancel,
			XDTOSerializer.ReadXDTO(SettingsStructureXTDO),
			Enums.ExchangeMessagesTransportTypes[TransportKindAsString],
			ErrorMessage);
	
	If Cancel Then
		Return False;
	EndIf;
	
	Return True;
EndFunction

// Corresponds to the Ping operation
Function Ping()
	
	// 
	Return Undefined;
	
EndFunction

//

Function DataExchangeMode(DataExchangeScenario)
	
	Result = "Manual";
	
	If DataExchangeScenario.Columns.Find("Mode") <> Undefined Then
		Result = DataExchangeScenario[0].Mode;
	EndIf;
	
	Return Result;
EndFunction

#EndRegion
