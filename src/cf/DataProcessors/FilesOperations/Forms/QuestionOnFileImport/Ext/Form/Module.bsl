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
	
	TooBigFiles = Parameters.TooBigFiles;
	
	MaxFileSize = Int(FilesOperations.MaxFileSize() / (1024 * 1024));
	
	Message = StringFunctionsClientServer.SubstituteParametersToString(
	    NStr("en = 'Some files exceed the size limit (%1 MB) and will not be added to the storage.
	               |Do you want to continue the upload?';"),
	    String(MaxFileSize) );
	
	Title = Parameters.Title;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

#EndRegion
