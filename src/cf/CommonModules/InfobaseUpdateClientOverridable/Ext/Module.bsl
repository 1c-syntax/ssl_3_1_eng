///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called when you click on a hyperlink or double-click on a cell 
// in a table document with a description of system changes (the General layout of the system change Description).
//
// Parameters:
//   Area - SpreadsheetDocumentRange -  the area of the document 
//             where the click occurred.
//
Procedure OnClickUpdateDetailsDocumentHyperlink(Val Area) Export
	
	

EndProcedure

// Called in the handler before the system starts Working, checks whether it can
// be updated to the current version of the program.
//
// Parameters:
//  DataVersion - String -  the version of the main configuration data that is being updated
//                          (from the version information register of the Subsystems).
//
Procedure OnDetermineUpdateAvailability(Val DataVersion) Export
	
	
	
EndProcedure

#EndRegion
