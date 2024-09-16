///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Called when production calendars are changed.
//
Procedure PlanUpdateOfDataDependentOnBusinessCalendars(Val UpdateConditions) Export
	
	If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
		
		ModuleJobsQueue = Common.CommonModule("JobsQueue");
		
		MethodParameters = New Array;
		MethodParameters.Add(UpdateConditions);
		MethodParameters.Add(New UUID);

		JobParameters = New Structure;
		JobParameters.Insert("MethodName", "CalendarSchedulesInternal.UpdateDataDependentOnBusinessCalendars");
		JobParameters.Insert("Parameters", MethodParameters);
		JobParameters.Insert("RestartCountOnFailure", 3);
		JobParameters.Insert("DataArea", -1);
		
		SetPrivilegedMode(True);
		ModuleJobsQueue.AddJob(JobParameters);
		
	EndIf;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert("CalendarSchedulesInternal.UpdateDataDependentOnBusinessCalendars");
	
EndProcedure

#EndRegion

#Region Private

// The procedure for calling from the job queue is placed there in the scheduled update of data-dependent production Calendars.
// 
// Parameters:
//  UpdateConditions - 
//  FileID - 
//
Procedure UpdateDataDependentOnBusinessCalendars(Val UpdateConditions, Val FileID) Export
	
	If Common.SubsystemExists("CloudTechnology.SuppliedData") Then
		
		ModuleSuppliedData = Common.CommonModule("SuppliedData");
		
		// 
		AreasForUpdate = ModuleSuppliedData.AreasRequiringProcessing(
			FileID, "BusinessCalendarsData");
			
		// 
		DistributeBusinessCalendarsDataToDependentData(UpdateConditions, AreasForUpdate, 
			FileID, "BusinessCalendarsData");
			
	EndIf;
		
EndProcedure

// Fills in data that is dependent on production calendars based on production calendar data for all ODS.
//
// Parameters:
//  UpdateConditions - ValueTable -  table with conditions for updating graphs.
//  AreasForUpdate - 
//  FileID - 
//  HandlerCode - String -   the handler code.
//
Procedure DistributeBusinessCalendarsDataToDependentData(Val UpdateConditions, 
	Val AreasForUpdate, Val FileID, Val HandlerCode)
	
	If Not Common.SubsystemExists("CloudTechnology.Core")
		Or Not Common.SubsystemExists("CloudTechnology.SuppliedData") Then
		Return;
	EndIf;
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	UpdateConditions.GroupBy("BusinessCalendarCode, Year");
	
	For Each DataArea In AreasForUpdate Do
		Try
			SetPrivilegedMode(True);
			ModuleSaaSOperations.SignInToDataArea(DataArea);
			SetPrivilegedMode(False);
		Except
			// 
			// 
			SetPrivilegedMode(True);
			ModuleSaaSOperations.SignOutOfDataArea();
			SetPrivilegedMode(False);
			Continue;
		EndTry;
		BeginTransaction();
		Try
			CalendarSchedules.FillDataDependentOnBusinessCalendars(UpdateConditions);
			ModuleSuppliedData.AreaProcessed(FileID, HandlerCode, DataArea);
			CommitTransaction();
		Except
			RollbackTransaction();
			WriteLogEvent(NStr("en = 'Calendar schedules.Distribute business calendars';", Common.DefaultLanguageCode()),
									EventLogLevel.Error,,,
									ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		SetPrivilegedMode(True);
		ModuleSaaSOperations.SignOutOfDataArea();
		SetPrivilegedMode(False);
	EndDo;
	
EndProcedure

#EndRegion
