///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If Not HasFilesInVolumes() Then
		ShowMessageBox(, NStr("en = 'No files in volumes.';"));
		Return;
	EndIf;
	
	OpenForm("CommonForm.SelectPathToVolumeFilesArchive", , CommandExecuteParameters.Source);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function HasFilesInVolumes()
	
	Return FilesOperationsInternal.HasFilesInVolumes();
	
EndFunction

#EndRegion
