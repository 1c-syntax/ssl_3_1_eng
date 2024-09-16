///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called when the data changes, the production of calendars.
// If partitioning is enabled, it is performed in non-partitioned mode.
//
// Parameters:
//  UpdateConditions - ValueTable:
//    * BusinessCalendarCode - String -  code of the production calendar whose data has changed;
//    * Year                           - Number  -  the calendar year for which the data changed.
//
Procedure OnUpdateBusinessCalendars(UpdateConditions) Export
	
EndProcedure

// Called when the data changes, dependent on the production of the calendars.
// If partitioning is enabled, it is performed in data regions.
//
// Parameters:
//  UpdateConditions - ValueTable:
//    * BusinessCalendarCode - String -  code of the production calendar whose data has changed;
//    * Year                           - Number  -  the calendar year for which the data changed.
//
Procedure OnUpdateDataDependentOnBusinessCalendars(UpdateConditions) Export
	
EndProcedure

// Called when registering a deferred data update handler that depends on production calendars.
// Add the metadata names of the objects 
// that you want to block from being used while the production calendars are being updated to the objects that are being Blocked.
//
// Parameters:
//  ObjectsToLock - Array -  names of metadata for blocked objects.
//
Procedure OnFillObjectsToBlockDependentOnBusinessCalendars(ObjectsToLock) Export
	
EndProcedure

// Called when registering a deferred data update handler that depends on production calendars.
// Add the names of object metadata to the changeable Objects, 
// which will change when updating production calendars.
//
// Parameters:
//  ObjectsToChange - Array -  names of metadata for the objects being modified.
//
Procedure OnFillObjectsToChangeDependentOnBusinessCalendars(ObjectsToChange) Export
	
EndProcedure

#EndRegion
