///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Calculates the totals of all accounting registers and accumulations that have them enabled.
Procedure CalculateTotals() Export
	
	SessionDate = CurrentSessionDate();
	AccumulationRegisterPeriod  = EndOfMonth(AddMonth(SessionDate, -1)); // 
	AccountingRegisterPeriod = EndOfMonth(SessionDate); // 
	
	Cache = SplitCheckCache();
	
	// 
	KindBalance = Metadata.ObjectProperties.AccumulationRegisterType.Balance;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType <> KindBalance Then
			Continue;
		EndIf;
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccumulationRegisterManager = AccumulationRegisters[MetadataRegister.Name]; // AccumulationRegisterManager
		If AccumulationRegisterManager.GetMaxTotalsPeriod() >= AccumulationRegisterPeriod Then
			Continue;
		EndIf;
		AccumulationRegisterManager.SetMaxTotalsPeriod(AccumulationRegisterPeriod);
		If Not AccumulationRegisterManager.GetTotalsUsing()
			Or Not AccumulationRegisterManager.GetPresentTotalsUsing() Then
			Continue;
		EndIf;
		AccumulationRegisterManager.RecalcPresentTotals();
	EndDo;
	
	// 
	For Each MetadataRegister In Metadata.AccountingRegisters Do
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccountingRegisterManager = AccountingRegisters[MetadataRegister.Name]; // AccountingRegisterManager
		If AccountingRegisterManager.GetTotalsPeriod() >= AccountingRegisterPeriod Then
			Continue;
		EndIf;
		AccountingRegisterManager.SetMaxTotalsPeriod(AccountingRegisterPeriod);
		If Not AccountingRegisterManager.GetTotalsUsing()
			Or Not AccountingRegisterManager.GetPresentTotalsUsing() Then
			Continue;
		EndIf;
		AccountingRegisterManager.RecalcPresentTotals();
	EndDo;
	
	// 
	If LocalFileOperationMode() Then
		TotalsParameters = TotalsAndAggregatesParameters();
		TotalsParameters.TotalsCalculationDate = BegOfMonth(SessionDate);
		WriteTotalsAndAggregatesParameters(TotalsParameters);
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Version              = "2.4.1.1";
	Handler.Procedure           = "TotalsAndAggregatesManagementInternal.UpdateScheduledJobUsage";
	Handler.ExecutionMode     = "Seamless";
	Handler.Id       = New UUID("16ec32f9-d68f-4283-9e6f-924a8655d2e4");
	Handler.Comment         = NStr("en = 'Toggles the update and rebuild schedule for aggregates.';");
	
EndProcedure

// See InfobaseUpdateSSL.AfterUpdateInfobase.
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
		Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
	
	If Not LocalFileOperationMode() Then
		Return;
	EndIf;
	
	// 
	// 
	
	GenerateTotalsAndAggregatesParameters();
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplateList.
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.UpdateAggregates.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.RebuildAggregates.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.TotalsPeriodSetup.Name);
	
EndProcedure

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	If Not LocalFileOperationMode() Then
		Return;
	EndIf;
	
	ProcessMetadata = Metadata.DataProcessors.ShiftTotalsBoundary;
	If Not AccessRight("Use", ProcessMetadata) Then
		Return;
	EndIf;
	
	ProcessFullName = ProcessMetadata.FullName();
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	Sections = ModuleToDoListServer.SectionsForObject(ProcessFullName);
	
	Prototype = New Structure("HasToDoItems, Important, Form, Presentation, ToolTip");
	Prototype.HasToDoItems = MustMoveTotalsBorder();
	Prototype.Important   = True;
	Prototype.Form    = ProcessFullName + ".Form";
	Prototype.Presentation = NStr("en = 'Optimize performance';");
	Prototype.ToolTip     = NStr("en = 'Speed up document posting and report generation.
		|Required monthly procedure, this might take a while. ';");
	
	For Each Section In Sections Do
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = StrReplace(Prototype.Form, ".", "") + StrReplace(Section.FullName(), ".", "");
		ToDoItem.Owner       = Section;
		FillPropertyValues(ToDoItem, Prototype);
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 

// Handler for the routine task "setperiodarasscounted Totals".
Procedure TotalsPeriodSetupJobHandler() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.TotalsPeriodSetup);
	
	CalculateTotals();
	
EndProcedure

// Handler for the routine task "updating Aggregates".
Procedure UpdateAggregatesJobHandler() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.UpdateAggregates);
	
	UpdateAggregates();
	
EndProcedure

// Handler for the routine task "rebuilding Units".
Procedure RebuildAggregatesJobHandler() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.RebuildAggregates);
	
	RebuildAggregates();
	
EndProcedure

// For internal use.
Procedure UpdateAggregates()
	
	Cache = SplitCheckCache();
	
	// 
	TurnoversKind = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType <> TurnoversKind Then
			Continue;
		EndIf;
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccumulationRegisterManager = AccumulationRegisters[MetadataRegister.Name];
		If Not AccumulationRegisterManager.GetAggregatesMode()
			Or Not AccumulationRegisterManager.GetAggregatesUsing() Then
			Continue;
		EndIf;
		// 
		AccumulationRegisterManager.UpdateAggregates();
	EndDo;
EndProcedure

// For internal use.
Procedure RebuildAggregates()
	
	Cache = SplitCheckCache();
	
	// 
	TurnoversKind = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType <> TurnoversKind Then
			Continue;
		EndIf;
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccumulationRegisterManager = AccumulationRegisters[MetadataRegister.Name];
		If Not AccumulationRegisterManager.GetAggregatesMode()
			Or Not AccumulationRegisterManager.GetAggregatesUsing() Then
			Continue;
		EndIf;
		// 
		AccumulationRegisterManager.RebuildAggregatesUsing();
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Returns True if the is is running in file mode and partitioning is disabled.
Function LocalFileOperationMode()
	Return Common.FileInfobase() And Not Common.DataSeparationEnabled();
EndFunction

// Determines the relevance of totals and aggregates. If there are no registers, it returns True.
Function MustMoveTotalsBorder() Export
	Parameters = TotalsAndAggregatesParameters();
	Return Parameters.HasTotalsRegisters And AddMonth(Parameters.TotalsCalculationDate, 2) < CurrentSessionDate();
EndFunction

// Gets the value of the constant "parameters of totals and Aggregates".
Function TotalsAndAggregatesParameters()
	SetPrivilegedMode(True);
	Parameters = Constants.TotalsAndAggregatesParameters.Get().Get();
	If TypeOf(Parameters) <> Type("Structure") Or Not Parameters.Property("HasTotalsRegisters") Then
		Parameters = GenerateTotalsAndAggregatesParameters();
	EndIf;
	Return Parameters;
EndFunction

// Re-fills the constant "parameters of totals and Aggregates".
Function GenerateTotalsAndAggregatesParameters()
	Parameters = New Structure;
	Parameters.Insert("HasTotalsRegisters", False);
	Parameters.Insert("TotalsCalculationDate",  '39991231235959'); // 
	
	KindBalance = Metadata.ObjectProperties.AccumulationRegisterType.Balance;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType = KindBalance Then
			AccumulationRegisterManager = AccumulationRegisters[MetadataRegister.Name]; // AccumulationRegisterManager
			Date = AccumulationRegisterManager.GetMaxTotalsPeriod() + 1;
			Parameters.HasTotalsRegisters = True;
			Parameters.TotalsCalculationDate  = Min(Parameters.TotalsCalculationDate, Date);
		EndIf;
	EndDo;
	
	If Not Parameters.HasTotalsRegisters Then
		Parameters.Insert("TotalsCalculationDate", '00010101');
	EndIf;
	
	WriteTotalsAndAggregatesParameters(Parameters);
	
	Return Parameters;
EndFunction

// Writes the value of the constant "parameters of totals and Aggregates".
Procedure WriteTotalsAndAggregatesParameters(Parameters) Export
	Constants.TotalsAndAggregatesParameters.Set(New ValueStorage(Parameters));
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// [2.3.4.7] Updates the use of routine tasks for updating Units and rebuilding Units.
Procedure UpdateScheduledJobUsage() Export
	// 
	HasRegistersWithAggregates = HasRegistersWithAggregates();
	UpdateScheduledJob(Metadata.ScheduledJobs.UpdateAggregates, HasRegistersWithAggregates);
	UpdateScheduledJob(Metadata.ScheduledJobs.RebuildAggregates, HasRegistersWithAggregates);
	
	// 
	UpdateScheduledJob(Metadata.ScheduledJobs.TotalsPeriodSetup, True);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Auxiliary for the update userregistration Tasks procedure.
Procedure UpdateScheduledJob(ScheduledJobMetadata, Use)
	FoundItems = ScheduledJobsServer.FindJobs(New Structure("Metadata", ScheduledJobMetadata));
	For Each Job In FoundItems Do
		Changes = New Structure("Use", Use);
		// 
		If Not ScheduleFilled(Job.Schedule)
			And Not Common.DataSeparationEnabled() Then
			Changes.Insert("Schedule", DefaultSchedule(ScheduledJobMetadata));
		EndIf;
		ScheduledJobsServer.ChangeJob(Job, Changes);
	EndDo;
EndProcedure

// Determines whether the scheduled task schedule is set.
//
// Parameters:
//   Schedule - JobSchedule -  schedule of a routine task.
//
// Returns:
//   Boolean - 
//
Function ScheduleFilled(Schedule)
	Return Schedule <> Undefined
		And String(Schedule) <> String(New JobSchedule);
EndFunction

// Returns the schedule of a scheduled task by default.
//   Used instead of the "metadata Object: routine Task" property.Schedule",
//   because it always has the value Undefined.
//
Function DefaultSchedule(ScheduledJobMetadata)
	Schedule = New JobSchedule;
	Schedule.DaysRepeatPeriod = 1;
	If ScheduledJobMetadata = Metadata.ScheduledJobs.UpdateAggregates Then
		Schedule.BeginTime = Date(1, 1, 1, 01, 00, 00);
		AddDetailedSchedule(Schedule, "BeginTime", Date(1, 1, 1, 01, 00, 00));
		AddDetailedSchedule(Schedule, "BeginTime", Date(1, 1, 1, 14, 00, 00));
	ElsIf ScheduledJobMetadata = Metadata.ScheduledJobs.RebuildAggregates Then
		Schedule.BeginTime = Date(1, 1, 1, 03, 00, 00);
		SetWeekDays(Schedule, "6");
	ElsIf ScheduledJobMetadata = Metadata.ScheduledJobs.TotalsPeriodSetup Then
		Schedule.BeginTime = Date(1, 1, 1, 01, 00, 00);
		Schedule.DayInMonth = 5;
	Else
		Return Undefined;
	EndIf;
	Return Schedule;
EndFunction

// Auxiliary for the timesheet function.
Procedure AddDetailedSchedule(Schedule, Var_Key, Value)
	DetailedSchedule = New JobSchedule;
	FillPropertyValues(DetailedSchedule, New Structure(Var_Key, Value));
	Array = Schedule.DetailedDailySchedules;
	Array.Add(DetailedSchedule);
	Schedule.DetailedDailySchedules = Array;
EndProcedure

// Auxiliary for the timesheet function.
Procedure SetWeekDays(Schedule, WeekDaysInRow)
	WeekDays = New Array;
	RowsArray = StrSplit(WeekDaysInRow, ",", False);
	For Each WeekDayNumberRow In RowsArray Do
		WeekDays.Add(Number(TrimAll(WeekDayNumberRow)));
	EndDo;
	Schedule.WeekDays = WeekDays;
EndProcedure

Function SplitCheckCache()
	Cache = New Structure;
	Cache.Insert("SaaSModel", Common.DataSeparationEnabled());
	If Cache.SaaSModel Then
		If Common.SubsystemExists("CloudTechnology.Core") Then
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			MainDataSeparator = ModuleSaaSOperations.MainDataSeparator();
			AuxiliaryDataSeparator = ModuleSaaSOperations.AuxiliaryDataSeparator();
		Else
			MainDataSeparator = Undefined;
			AuxiliaryDataSeparator = Undefined;
		EndIf;
		
		Cache.Insert("InDataArea",                   Common.SeparatedDataUsageAvailable());
		Cache.Insert("MainDataSeparator",        MainDataSeparator);
		Cache.Insert("AuxiliaryDataSeparator", AuxiliaryDataSeparator);
	EndIf;
	Return Cache;
EndFunction

Function MetadataObjectAvailableOnSplit(Cache, MetadataObject)
	If Not Cache.SaaSModel Then
		Return True;
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject(MetadataObject);
	Else
		IsSeparatedMetadataObject = False;
	EndIf;
	
	Return Cache.InDataArea = IsSeparatedMetadataObject;
EndFunction

Function HasRegistersWithAggregates()
	Cache = SplitCheckCache();
	TurnoversKind = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType <> TurnoversKind Then
			Continue;
		EndIf;
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccumulationRegisterManager = AccumulationRegisters[MetadataRegister.Name];
		If Not AccumulationRegisterManager.GetAggregatesMode()
			Or Not AccumulationRegisterManager.GetAggregatesUsing() Then
			Continue;
		EndIf;
		Return True;
	EndDo;
	
	Return False;
EndFunction

#EndRegion
