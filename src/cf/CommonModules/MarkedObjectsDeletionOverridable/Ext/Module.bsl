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
// See MarkedObjectsDeletionClient.ShowObjectsMarkedForDeletion 
//
// Parameters:
//  Objects - Array of MetadataObject -  metadata objects, which will be added to the list forms to hide the commands
//                                         marked for deletion.
//
// Example:
//	
//	
//
Procedure OnDefineObjectsWithShowMarkedObjectsCommand(Objects) Export
	
EndProcedure

// 
// 
// Parameters:
//  Context - Structure -  
//                          
//  ObjectsToDelete - Array of AnyRef - 
// 
Procedure BeforeDeletingAGroupOfObjects(Context, ObjectsToDelete) Export
	
EndProcedure

// 
// 
// 
// 
// Parameters:
//  Context - See MarkedObjectsDeletionOverridable.BeforeDeletingAGroupOfObjects.Context
//  Success - Boolean - 
//
Procedure AfterDeletingAGroupOfObjects(Context, Success) Export
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
// 
// 
//  
//  See Common.SubordinateObjects.
//
// Parameters:
//   Parameters - Structure:
//     * Interactive - Boolean -  True if the user started deleting marked objects;
//                                False if deletion is started according to the schedule of a scheduled task.
//
Procedure BeforeSearchForItemsMarkedForDeletion(Parameters) Export
	
EndProcedure

#EndRegion

#EndRegion
