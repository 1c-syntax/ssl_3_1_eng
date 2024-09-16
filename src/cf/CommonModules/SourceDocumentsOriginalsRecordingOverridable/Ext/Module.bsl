///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Defines configuration objects that contain commands for tracking originals of primary documents in their list forms,
//
// Parameters:
//  ListOfObjects - Array of String -  object managers with the add print Command procedure.
//
Procedure OnDefineObjectsWithOriginalsAccountingCommands(ListOfObjects) Export
	
	

EndProcedure

// 
//
// Parameters:
//  ListOfObjects - Map of KeyAndValue:
//          * Key - MetadataObject
//          * Value - String -  the name of the tabular part in which employees are stored.
//
Procedure WhenDeterminingMultiEmployeeDocuments(ListOfObjects) Export
	
	

EndProcedure

// Fills in the table of original accounting values
// If the procedure body is left empty, the states will be tracked across all printed forms of connected objects.
// If you add objects connected to the accounting subsystem of originals and their printed forms to the table of values,
// then the states will be tracked only by them.
//  
// Parameters:
//   AccountingTableForOriginals - ValueTable - :
//              * MetadataObject - MetadataObject
//              * Id - String -  layout ID.
//
// Example:
//	 
//	 
//	 
//
Procedure FillInTheOriginalAccountingTable(AccountingTableForOriginals) Export	
	
	

EndProcedure

#EndRegion
