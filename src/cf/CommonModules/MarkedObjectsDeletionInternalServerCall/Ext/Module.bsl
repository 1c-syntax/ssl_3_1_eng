///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// 
//
// Parameters:
//   Changes - Structure:
//   * Use - Boolean -  flag for using a scheduled task
//   * Schedule - JobSchedule -  set schedule for a scheduled task.
//
// Returns:
//   Boolean
//
Procedure SetDeleteOnScheduleMode(Changes) Export

	If Not Users.IsFullUser(,, False) Then
		Raise(NStr("en = 'Insufficient rights to perform the operation.';"), ErrorCategory.AccessViolation);
	EndIf;

	Parameters = New Structure;
	Parameters.Insert("Use", Changes.Use);
	Parameters.Insert("Schedule", Changes.Schedule);
	JobID = ScheduledJobsServer.UUID(
		Metadata.ScheduledJobs.MarkedObjectsDeletion);
	ScheduledJobsServer.ChangeJob(JobID, Parameters);

EndProcedure

// Returns the schedule of a scheduled task.
//
// Returns:
//   Structure:
//   * DetailedDailySchedules - Array
//   * Use - Boolean
//   * DataSeparationEnabled - Boolean
//
Function ModeDeleteOnSchedule() Export
	Result = New Structure;
	Result.Insert("Use", False);
	Result.Insert("Schedule", CommonClientServer.ScheduleToStructure(
		New JobSchedule));
	Result.Insert("DataSeparationEnabled", Common.DataSeparationEnabled());

	Filter = New Structure;
	Filter.Insert("Metadata", Metadata.ScheduledJobs.MarkedObjectsDeletion);
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	If Jobs.Count() > 0 Then
		Jobs = Jobs[0];
		Result.Use = Jobs.Use;
		If Result.DataSeparationEnabled Then
			Result.Schedule = Jobs.Schedule;
		Else
			Result.Schedule = ScheduledJobsServer.JobSchedule(
				Jobs.UUID, True);
		EndIf;
	EndIf;

	Return Result;

EndFunction

// See MarkedObjectsDeletion.DeleteOnScheduleCheckBoxValue
Function DeleteOnScheduleCheckBoxValue() Export
	Return ModeDeleteOnSchedule().Use;
EndFunction

Procedure SaveViewSettingForItemsMarkedForDeletion(FormName, ListName, CheckMarkValue) Export
	SettingsKey = MarkedObjectsDeletionInternal.SettingsKey(FormName, ListName);
	Common.FormDataSettingsStorageSave(FormName, SettingsKey, CheckMarkValue);
EndProcedure

#EndRegion