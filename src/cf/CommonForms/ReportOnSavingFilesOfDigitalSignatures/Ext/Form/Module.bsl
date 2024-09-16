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
	
	Text = Parameters.Text;
	DirectoryWithFiles = Parameters.DirectoryWithFiles;
	
	Items.FormOpenFilesFolder.Visible = ValueIsFilled(DirectoryWithFiles);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenFilesFolder(Command)
	
	FileSystemClient.OpenExplorer(DirectoryWithFiles);
	
EndProcedure

#EndRegion
