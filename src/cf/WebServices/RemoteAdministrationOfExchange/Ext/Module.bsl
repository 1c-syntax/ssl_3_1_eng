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
Function ScheduleDataExchangeExecution(AreasForDataExchangeString)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return "";
	EndIf;
		
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	
	AreasForDataExchange = ValueFromStringInternal(AreasForDataExchangeString);
	
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
Function ExecuteDataExchangeScenarioActionInFirstInfobase(ScenarioRowIndex, DataExchangeScenarioString)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return "";
	EndIf;
		
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	
	DataExchangeScenario = ValueFromStringInternal(DataExchangeScenarioString);
	
	ScenarioRow = DataExchangeScenario[ScenarioRowIndex];
	
	Var_Key = ScenarioRow.ExchangePlanName + ScenarioRow.InfobaseNodeCode + ScenarioRow.ThisNodeCode;
	
	Parameters = New Array;
	Parameters.Add(ScenarioRowIndex);
	Parameters.Add(DataExchangeScenario);
	
	JobParameters = New Structure;
	JobParameters.Insert("MethodName"    , "DataExchangeSaaS.ExecuteDataExchangeScenarioActionInFirstInfobase");
	JobParameters.Insert("Parameters"    , Parameters);
	JobParameters.Insert("Key"         , Var_Key);
	JobParameters.Insert("DataArea", ScenarioRow.ValueOfSeparatorOfFirstInformationBase);
	
	Try
		SetPrivilegedMode(True);
		ModuleJobsQueue.AddJob(JobParameters);
	Except
		If ErrorInfo().Description <> ModuleJobsQueue.GetExceptionTextJobsWithSameKeyDuplication() Then
			Raise;
		EndIf;
	EndTry;
	
	Return "";
EndFunction

// Corresponds to the StartExchangeExecutionInSecondDatabase operation
Function ExecuteDataExchangeScenarioActionInSecondInfobase(ScenarioRowIndex, DataExchangeScenarioString)
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return "";
	EndIf;
		
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	
	DataExchangeScenario = ValueFromStringInternal(DataExchangeScenarioString);
	
	ScenarioRow = DataExchangeScenario[ScenarioRowIndex];
	
	Var_Key = ScenarioRow.ExchangePlanName + ScenarioRow.InfobaseNodeCode + ScenarioRow.ThisNodeCode;
	
	Parameters = New Array;
	Parameters.Add(ScenarioRowIndex);
	Parameters.Add(DataExchangeScenario);
	
	JobParameters = New Structure;
	JobParameters.Insert("MethodName"    , "DataExchangeSaaS.ExecuteDataExchangeScenarioActionInSecondInfobase");
	JobParameters.Insert("Parameters"    , Parameters);
	JobParameters.Insert("Key"         , Var_Key);
	JobParameters.Insert("DataArea", ScenarioRow.ValueOfSeparatorOfSecondInformationBase);
	
	Try
		SetPrivilegedMode(True);
		ModuleJobsQueue.AddJob(JobParameters);
	Except
		If ErrorInfo().Description <> ModuleJobsQueue.GetExceptionTextJobsWithSameKeyDuplication() Then
			Raise;
		EndIf;
	EndTry;
	
	Return "";
	
EndFunction

// Corresponds to the TestConnection operation
Function TestConnection(SettingsStructureString, TransportKindAsString, ErrorMessage)
	
	Cancel = False;
	
	// 
	DataExchangeServer.CheckExchangeMessageTransportDataProcessorAttachment(Cancel,
			ValueFromStringInternal(SettingsStructureString),
			Enums.ExchangeMessagesTransportTypes[TransportKindAsString],
			ErrorMessage);
	
	If Cancel Then
		Return False;
	EndIf;
	
	// 
	Try
		DataExchangeSaaSCached.GetExchangeServiceWSProxy();
	Except
		ErrorMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	Return True;
EndFunction

#EndRegion
