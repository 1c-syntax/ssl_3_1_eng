///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// 
// 
//
// 
//  See ToDoListServer.ToDoList.
// 
// 
//
//
// See ToDoListServer.ToDoList.
////
//
//
//
//
// Parameters:
//  ToDoList - Array -  Manager modules or General modules,
//                         for example: Documents.Customer's Order, Current Sales.
// Example:
//  Current week.Add(Documents.Customer's order);
//
Procedure OnDetermineToDoListHandlers(ToDoList) Export
	
	
	
EndProcedure

// Sets the initial order of sections in the to-do panel.
//
// Parameters:
//  Sections - Array -  an array of sections of the command interface.
//                     The sections in the to-do panel are displayed in
//                     the order in which they were added to the array.
//
Procedure OnDetermineCommandInterfaceSectionsOrder(Sections) Export
	
	
	
EndProcedure

// Defines current tasks that will not be displayed to the user.
//
// Parameters:
//  ToDoItemsToDisable - Array -  a string array of IDs of current Affairs that you want to disable.
//
Procedure OnDisableToDos(ToDoItemsToDisable) Export
	
EndProcedure

// Allows you to change some settings of the subsystem.
//
// Parameters:
//  Parameters - Structure:
//     * OtherToDoItemsTitle - String -  title of the section that displays
//                            cases that are not related to the command interface sections.
//                            Applicable for cases whose placement in the panel
//                            is determined by the current task Server function.Section for the object.
//                            If not specified, the cases are displayed in a group with the heading
//                            "other cases".
//
Procedure OnDefineSettings(Parameters) Export
	
	
	
EndProcedure

// Allows you to set query parameters that are common to multiple current cases.
//
// For example, if the "current Date" parameter is set in several handlers for getting current cases
// , then you can set the parameter in this
// procedure, and make a call to the procedure in the handler for generating the case
// Current date.Set the General query parameter (), which will set this parameter.
//
// Parameters:
//  Query - Query -  the request being executed.
//  CommonQueryParameters - Structure -  the total value to calculate the current Affairs.
//
Procedure SetCommonQueryParameters(Query, CommonQueryParameters) Export
	
EndProcedure

#EndRegion