///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Report = FilesOperationsInternal.FilesImportGenerateReport(Parameters.ArrayOfFilesNamesWithErrors);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReportSelection(Item, Area, StandardProcessing)
	
#If Not WebClient Then
	// 
	If StrFind(Area.Text, ":\") > 0 Or StrFind(Area.Text, ":/") > 0 Then
		FilesOperationsInternalClient.OpenExplorerWithFile(Area.Text);
	EndIf;
#EndIf
	
EndProcedure

#EndRegion
