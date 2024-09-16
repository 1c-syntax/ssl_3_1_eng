///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ObsoleteProceduresAndFunctions

// Deprecated.
//
// Returns:
//   Undefined - 
//
Function CreateNewJob() Export
	
	Return Undefined;
	
EndFunction

// Deprecated.
//
// Parameters:
//   Job - ScheduledJob -  routine task.
//
// Returns:
//   Undefined - 
//
Function GetJobID(Val Job) Export
	
	Return Undefined;
	
EndFunction

// Deprecated.
//
// Parameters:
//   Job - ScheduledJob -  routine task.
//   Use - Boolean -  flag for using a scheduled task.
//   Parameters - Array -  parameters of a routine task.
//   Schedule - JobSchedule -  schedule of a routine task.
//
Procedure SetJobParameters(Job, Use, Parameters, Schedule) Export
	
	Return;
	
EndProcedure

// Deprecated.
//
// Parameters:
//   Job - ScheduledJob -  routine task.
//
// Returns:
//   Undefined - 
//
Function GetJobParameters(Val Job) Export
	
	Return Undefined;
	
EndFunction

// Deprecated.
//
// Parameters:
//   Id - UUID -  ID of the scheduled task.
//
// Returns:
//   Undefined - 
//
Function FindJob(Val Id) Export
	
	Return Undefined;
	
EndFunction

// Deprecated.
//
// Parameters:
//   Job - ScheduledJob -  routine task.
//
Procedure DeleteJob(Val Job) Export
	
	Return;
	
EndProcedure

#EndRegion

#EndRegion
