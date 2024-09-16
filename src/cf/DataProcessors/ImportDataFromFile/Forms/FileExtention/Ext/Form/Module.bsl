///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	If SaveAsFileType = 0 Then
		Result = "xlsx";
	ElsIf SaveAsFileType = 1 Then
		Result = "csv";
	ElsIf SaveAsFileType = 3 Then
		Result = "xls";
	ElsIf SaveAsFileType = 4 Then
		Result = "ods";
	Else
		Result = "mxl";
	EndIf;
	Close(Result);
EndProcedure

&AtClient
Procedure InstallAddonForFacilitatingWorkWithFiles(Command)
	BeginInstallFileSystemExtension(Undefined);
EndProcedure

#EndRegion








