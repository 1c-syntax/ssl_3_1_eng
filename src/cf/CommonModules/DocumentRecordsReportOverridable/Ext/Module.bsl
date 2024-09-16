///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Allows you to add additional registers to the document movement registers.
//
// Parameters:
//    Document - DocumentRef -  the document is a collection of movements which need to be supplemented.
//    RegistersWithRecords - Map of KeyAndValue:
//        * Key     - MetadataObject -  register as a metadata object.
//        * Value - String           -  name of the Registrar's field.
//
Procedure OnDetermineRegistersWithRecords(Document, RegistersWithRecords) Export
	
	
	
EndProcedure

// Allows you to calculate the number of records for additional sets added by the procedure
// When defining registersmovements.
//
// Parameters:
//    Document - DocumentRef -  the document is a collection of movements which need to be supplemented.
//    CalculatedCount - Map of KeyAndValue:
//        * Key     - String -  the full name of the case (an underscore is used instead of dots).
//        * Value - Number  -  calculated number of entries.
//
Procedure OnCalculateRecordsCount(Document, CalculatedCount) Export
	
	
	
EndProcedure

// Allows you to add or redefine a collection of data sets for displaying document movements.
//
// Parameters:
//    Document - DocumentRef -  a document whose collection of movements needs to be updated.
//    DataSets - Array -  information about data sets (type of Structure element).
//
Procedure OnPrepareDataSet(Document, DataSets) Export
	
	
	
EndProcedure

#EndRegion
