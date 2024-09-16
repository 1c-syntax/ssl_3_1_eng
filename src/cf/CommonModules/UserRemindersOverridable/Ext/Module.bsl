///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Overrides the subsystem settings.
//
// Parameters:
//  Settings - Structure:
//   * Schedules1 - Map of KeyAndValue:
//      ** Key     - String -  the timesheet view;
//      ** Value - JobSchedule -  version of the schedule.
//   * StandardIntervals - Array -  contains string representations of time intervals.
//
Procedure OnDefineSettings(Settings) Export
	
EndProcedure

// Overrides the array of object details that you can set the reminder time for.
// For example, you can hide the details with dates that are official or do not make sense for 
// setting reminders: the date of the document or task, and others.
// 
// Parameters:
//  Source - AnyRef -  link to the object that is being formed for an array of details with dates;
//  AttributesWithDates - Array -  the names of the details (from the metadata) that contain dates.
//
Procedure OnFillSourceAttributesListWithReminderDates(Source, AttributesWithDates) Export
	
EndProcedure

#EndRegion
