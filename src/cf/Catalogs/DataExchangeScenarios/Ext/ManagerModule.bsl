///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// Returns the details of an object that is not recommended to edit
// by processing a batch update of account details.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("GUIDScheduledJob");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

#EndRegion

#EndRegion

#Region Private

Procedure CreateScenario(
		InfobaseNode,
		Schedule = Undefined,
		UseScheduledJob = True) Export
	
	Cancel = False;
	
	Description = NStr("en = 'Synchronize data with %1 automatically';");
	Description = StringFunctionsClientServer.SubstituteParametersToString(Description,
			String(InfobaseNode));
	
	ExchangeTransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(InfobaseNode);
	
	DataExchangeScenario = CreateItem();
	
	// 
	DataExchangeScenario.Description = Description;
	DataExchangeScenario.UseScheduledJob = UseScheduledJob;
	
	// 
	UpdateScheduledJobData(Cancel, Schedule, DataExchangeScenario);
	
	// 
	TableRow = DataExchangeScenario.ExchangeSettings.Add();
	TableRow.ExchangeTransportKind = ExchangeTransportKind;
	TableRow.CurrentAction = Enums.ActionsOnExchange.DataImport;
	TableRow.InfobaseNode = InfobaseNode;
	
	TableRow = DataExchangeScenario.ExchangeSettings.Add();
	TableRow.ExchangeTransportKind = ExchangeTransportKind;
	TableRow.CurrentAction = Enums.ActionsOnExchange.DataExport;
	TableRow.InfobaseNode = InfobaseNode;
	
	DataExchangeScenario.Write();
	
EndProcedure

Function DefaultJobSchedule() Export
	
	Months = New Array;
	Months.Add(1);
	Months.Add(2);
	Months.Add(3);
	Months.Add(4);
	Months.Add(5);
	Months.Add(6);
	Months.Add(7);
	Months.Add(8);
	Months.Add(9);
	Months.Add(10);
	Months.Add(11);
	Months.Add(12);
	
	WeekDays = New Array;
	WeekDays.Add(1);
	WeekDays.Add(2);
	WeekDays.Add(3);
	WeekDays.Add(4);
	WeekDays.Add(5);
	WeekDays.Add(6);
	WeekDays.Add(7);
	
	Schedule = New JobSchedule;
	Schedule.WeekDays                = WeekDays;
	Schedule.RepeatPeriodInDay = 900; // 
	Schedule.DaysRepeatPeriod        = 1; // 
	Schedule.Months                   = Months;
	
	Return Schedule;
EndFunction

// Gets the schedule of a scheduled task.
// If a scheduled task is not set, it returns an empty schedule (by default).
//
Function GetDataExchangeExecutionSchedule(ExchangeExecutionSettings) Export
	
	ScheduledJobObject = ScheduledJobByID(ExchangeExecutionSettings.GUIDScheduledJob);
	
	If ScheduledJobObject <> Undefined Then
		
		JobSchedule = ScheduledJobObject.Schedule;
		
	Else
		
		JobSchedule = New JobSchedule;
		
	EndIf;
	
	Return JobSchedule;
	
EndFunction

Procedure UpdateScheduledJobData(Cancel, JobSchedule, CurrentObject) Export
	
	If Cancel Then
		Return;
	EndIf;

	If IsBlankString(CurrentObject.Code) Then	
		CurrentObject.SetNewCode();		
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		
		CreateUpdateScheduledJobInService(JobSchedule, CurrentObject);	
		
	Else
	
		// 
		ScheduledJobObject = CreateScheduledJobIfNecessary(Cancel, CurrentObject);
				
		// 
		SetScheduledJobParameters(ScheduledJobObject, JobSchedule, CurrentObject);
		
		// 
		WriteScheduledJob(Cancel, ScheduledJobObject);
		
		// 
		CurrentObject.GUIDScheduledJob = String(ScheduledJobObject.UUID);
	
	EndIf;
	
EndProcedure

Function CreateScheduledJobIfNecessary(Cancel, CurrentObject)
	
	ScheduledJobObject = ScheduledJobByID(CurrentObject.GUIDScheduledJob);
	
	// 
	If ScheduledJobObject = Undefined Then
		JobParameters = New Structure("Metadata", Metadata.ScheduledJobs.DataSynchronization);
		ScheduledJobObject = ScheduledJobsServer.AddJob(JobParameters);
	EndIf;
	
	Return ScheduledJobObject;
	
EndFunction

Procedure SetScheduledJobParameters(ScheduledJobObject, JobSchedule, CurrentObject)
		
	ScheduledJobParameters = New Array;
	ScheduledJobParameters.Add(CurrentObject.Code);
	
	ScheduledJobDescription = NStr("en = 'Exchange data by scenario: %1';");
	ScheduledJobDescription = StringFunctionsClientServer.SubstituteParametersToString(ScheduledJobDescription, TrimAll(CurrentObject.Description));
	
	ScheduledJobObject.Description  = Left(ScheduledJobDescription, 120);
	ScheduledJobObject.Use = CurrentObject.UseScheduledJob;
	ScheduledJobObject.Parameters     = ScheduledJobParameters;
	
	// 
	If JobSchedule <> Undefined Then
		ScheduledJobObject.Schedule = JobSchedule;
	EndIf;
	
EndProcedure

// Records a routine task.
//
// Parameters:
//  Cancel                     - Boolean -  flag of failure. If errors were detected during the procedure
//                                       , the failure flag is set to True.
//  ScheduledJobObject - 
// 
Procedure WriteScheduledJob(Cancel, ScheduledJobObject)
	
	SetPrivilegedMode(True);
	
	Try
		
		// 
		ScheduledJobObject.Write();
		
	Except
		
		MessageString = NStr("en = 'Couldn''t save the exchange schedule. Error details: %1';");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		DataExchangeServer.ReportError(MessageString, Cancel);
		
	EndTry;
	
EndProcedure

Procedure CreateUpdateScheduledJobInService(JobSchedule, CurrentObject)
	
	JobObject = Undefined;
	If ValueIsFilled(CurrentObject.GUIDScheduledJob) Then
		JobGUID = New UUID(CurrentObject.GUIDScheduledJob);
		JobObject = ScheduledJobsServer.Job(JobGUID);
	EndIf;
	
	DataArea = SessionParameters["DataAreaValue"];
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	TimeZone = ModuleSaaSOperations.GetTimeZoneOfDataArea(DataArea);
	ScheduledStartTime = ToLocalTime(CurrentUniversalDate(), TimeZone);
		
	If JobObject = Undefined Then
		
		ProcedureParameters = New Array;
		ProcedureParameters.Add(CurrentObject.Code);
		
		Var_Key = JobGUID;
		
		JobParameters = New Structure;
		JobParameters.Insert("Key", Left(Var_Key, 120));
		JobParameters.Insert("MethodName"    , "DataExchangeInternalPublication.RunDataExchangeByScenario");
		JobParameters.Insert("DataArea", DataArea);
		JobParameters.Insert("Use", True);
		JobParameters.Insert("ScheduledStartTime", ScheduledStartTime);
		JobParameters.Insert("Parameters", ProcedureParameters);
		JobParameters.Insert("Use", CurrentObject.UseScheduledJob);
		
		If JobSchedule <> Undefined Then
			JobParameters.Insert("Schedule", JobSchedule);
		EndIf;
		
		ModuleJobsQueue = Common.CommonModule("JobsQueue");
		JobObject = ModuleJobsQueue.AddJob(JobParameters);
		
		JobGUID = JobObject.UUID();
		
	Else
		
		JobParameters = New Structure;
		JobParameters.Insert("Use", CurrentObject.UseScheduledJob);
		JobParameters.Insert("ScheduledStartTime", ScheduledStartTime);
		
		If JobSchedule <> Undefined Then
			JobParameters.Insert("Schedule", JobSchedule);
		EndIf;
		
		ModuleJobsQueue = Common.CommonModule("JobsQueue");
		ModuleJobsQueue.ChangeJob(JobObject.Id, JobParameters);

	EndIf;
		
	CurrentObject.GUIDScheduledJob = String(JobGUID);

EndProcedure

// Returns a scheduled task by GUID.
//
// Parameters:
//  JobUUID - String -  a string with the GUID of the scheduled task.
// 
// Returns:
//  Undefined        - 
//  
//
Function ScheduledJobByID(Val JobUUID) Export
	
	If IsBlankString(JobUUID) Then
		Return Undefined;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("UUID", New UUID(JobUUID));
	
	SetPrivilegedMode(True);
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	
	If Jobs.Count() = 0 Then
		Return Undefined;
	EndIf;

	Return Jobs[0];
	
EndFunction

// Removes a node from all data exchange scenarios.
// If the script is empty after that, the script is deleted.
//
Procedure ClearRefsToInfobaseNode(Val InfobaseNode) Export

	Query = New Query(
		"SELECT DISTINCT
		|	DataExchangeScenariosExchangeSettings.Ref AS DataExchangeScenario
		|FROM
		|	Catalog.DataExchangeScenarios.ExchangeSettings AS DataExchangeScenariosExchangeSettings
		|WHERE
		|	DataExchangeScenariosExchangeSettings.InfobaseNode = &InfobaseNode");
	
	Query.SetParameter("InfobaseNode", InfobaseNode);
	
	ScenariosTable = Query.Execute().Unload();
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("Catalog.DataExchangeScenarios");
    	LockItem.DataSource = ScenariosTable;
		LockItem.UseFromDataSource("Ref", "DataExchangeScenario");
		Block.Lock();
		
		For Each ScenariosRow In ScenariosTable Do
			LockDataForEdit(ScenariosRow.DataExchangeScenario);
			DataExchangeScenario = ScenariosRow.DataExchangeScenario.GetObject(); // CatalogObject.DataExchangeScenarios
			
			DeleteExportToDataExchangeScenarios(DataExchangeScenario, InfobaseNode);
			DeleteImportToDataExchangeScenarios(DataExchangeScenario, InfobaseNode);
			
			DataExchangeScenario.Write();
			
			If DataExchangeScenario.ExchangeSettings.Count() = 0 Then
				DataExchangeScenario.Delete();
			EndIf;
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure DeleteExportToDataExchangeScenarios(DataExchangeScenario, InfobaseNode) Export
	
	DeleteRowInDataExchangeScenario(DataExchangeScenario, InfobaseNode, Enums.ActionsOnExchange.DataExport);
	
EndProcedure

Procedure DeleteImportToDataExchangeScenarios(DataExchangeScenario, InfobaseNode) Export
	
	DeleteRowInDataExchangeScenario(DataExchangeScenario, InfobaseNode, Enums.ActionsOnExchange.DataImport);
	
EndProcedure

Procedure AddExportToDataExchangeScenarios(DataExchangeScenario, InfobaseNode) Export
	
	If TypeOf(DataExchangeScenario) = Type("CatalogRef.DataExchangeScenarios") Then
		BeginTransaction();
		Try
		    Block = New DataLock;
		    LockItem = Block.Add("Catalog.DataExchangeScenarios");
		    LockItem.SetValue("Ref", DataExchangeScenario);
		    Block.Lock();
		    
			LockDataForEdit(DataExchangeScenario);
			ScenarioObject = DataExchangeScenario.GetObject();
			
			AddDataExchangeScenarioSettingsRows(
				ScenarioObject.ExchangeSettings, InfobaseNode, Enums.ActionsOnExchange.DataExport);

		    ScenarioObject.Write();

		    CommitTransaction();
		Except
		    RollbackTransaction();
			Raise;
		EndTry;
	Else
		AddDataExchangeScenarioSettingsRows(
			DataExchangeScenario.ExchangeSettings, InfobaseNode, Enums.ActionsOnExchange.DataExport);
	EndIf;
	
EndProcedure

Procedure AddImportToDataExchangeScenarios(DataExchangeScenario, InfobaseNode) Export
	
	If TypeOf(DataExchangeScenario) = Type("CatalogRef.DataExchangeScenarios") Then
		BeginTransaction();
		Try
		    Block = New DataLock;
		    LockItem = Block.Add("Catalog.DataExchangeScenarios");
		    LockItem.SetValue("Ref", DataExchangeScenario);
		    Block.Lock();
		    
			LockDataForEdit(DataExchangeScenario);
			ScenarioObject = DataExchangeScenario.GetObject();
			
			AddDataExchangeScenarioSettingsRows(
				ScenarioObject.ExchangeSettings, InfobaseNode, Enums.ActionsOnExchange.DataImport);

		    ScenarioObject.Write();

		    CommitTransaction();
		Except
		    RollbackTransaction();
			Raise;
		EndTry;
	Else
		AddDataExchangeScenarioSettingsRows(
			DataExchangeScenario.ExchangeSettings, InfobaseNode, Enums.ActionsOnExchange.DataImport);
	EndIf;
	
EndProcedure

Procedure AddDataExchangeScenarioSettingsRows(
		ExchangeSettings, InfobaseNode, CurrentAction)
		
	ExchangeTransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(InfobaseNode);
	
	If CurrentAction = Enums.ActionsOnExchange.DataExport Then
		// 
		MaxIndex = ExchangeSettings.Count() - 1;
		
		For IndexOf = 0 To MaxIndex Do
			
			ReverseIndex = MaxIndex - IndexOf;
			
			TableRow = ExchangeSettings[ReverseIndex];
			
			// 
			If TableRow.CurrentAction = CurrentAction Then
				
				NewRow = ExchangeSettings.Insert(ReverseIndex + 1);
				
				NewRow.InfobaseNode = InfobaseNode;
				NewRow.ExchangeTransportKind    = ExchangeTransportKind;
				NewRow.CurrentAction    = CurrentAction;
				
				Break;
			EndIf;
			
		EndDo;
		
		// 
		Filter = New Structure("InfobaseNode, CurrentAction", InfobaseNode, CurrentAction);
		If ExchangeSettings.FindRows(Filter).Count() = 0 Then
			
			NewRow = ExchangeSettings.Add();
			
			NewRow.InfobaseNode = InfobaseNode;
			NewRow.ExchangeTransportKind    = ExchangeTransportKind;
			NewRow.CurrentAction    = CurrentAction;
			
		EndIf;
	ElsIf CurrentAction = Enums.ActionsOnExchange.DataImport Then
		// 
		For Each TableRow In ExchangeSettings Do
			
			If TableRow.CurrentAction = CurrentAction Then // 
				
				NewRow = ExchangeSettings.Insert(ExchangeSettings.IndexOf(TableRow));
				
				NewRow.InfobaseNode = InfobaseNode;
				NewRow.ExchangeTransportKind    = ExchangeTransportKind;
				NewRow.CurrentAction    = CurrentAction;
				
				Break;
			EndIf;
			
		EndDo;
		
		// 
		Filter = New Structure("InfobaseNode, CurrentAction", InfobaseNode, CurrentAction);
		If ExchangeSettings.FindRows(Filter).Count() = 0 Then
			
			NewRow = ExchangeSettings.Insert(0);
			
			NewRow.InfobaseNode = InfobaseNode;
			NewRow.ExchangeTransportKind    = ExchangeTransportKind;
			NewRow.CurrentAction    = CurrentAction;
			
		EndIf;
	EndIf;
	
EndProcedure

Procedure DeleteRowInDataExchangeScenario(DataExchangeScenario, InfobaseNode, ActionOnExchange)
	
	If TypeOf(DataExchangeScenario) = Type("CatalogRef.DataExchangeScenarios") Then
		BeginTransaction();
		Try
		    Block = New DataLock;
		    LockItem = Block.Add("Catalog.DataExchangeScenarios");
		    LockItem.SetValue("Ref", DataExchangeScenario);
		    Block.Lock();
		    
			LockDataForEdit(DataExchangeScenario);
			ScenarioObject = DataExchangeScenario.GetObject();
			
			DeleteDataExchangeSettingsRowsFromScenario(ScenarioObject.ExchangeSettings, InfobaseNode, ActionOnExchange);

		    ScenarioObject.Write();

		    CommitTransaction();
		Except
		    RollbackTransaction();
			Raise;
		EndTry;
	Else
		DeleteDataExchangeSettingsRowsFromScenario(DataExchangeScenario.ExchangeSettings, InfobaseNode, ActionOnExchange)
	EndIf;
	
EndProcedure

Procedure DeleteDataExchangeSettingsRowsFromScenario(ExchangeSettings, InfobaseNode, ActionOnExchange)
	
	Cnt = ExchangeSettings.Count() - 1;
	While Cnt >= 0 Do
		
		TableRow = ExchangeSettings[Cnt];
		
		If TableRow.InfobaseNode = InfobaseNode
			And TableRow.CurrentAction = ActionOnExchange Then
			
			ExchangeSettings.Delete(Cnt);
			
		EndIf;
		
		Cnt = Cnt - 1;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf