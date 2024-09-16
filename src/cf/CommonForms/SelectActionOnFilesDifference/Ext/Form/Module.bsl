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
	
	FillPropertyValues(
		ThisObject,
		Parameters,
		"ChangeDateInWorkingDirectory,
		|ChangeDateInFileStorage,
		|FullFileNameInWorkingDirectory,
		|SizeInWorkingDirectory,
		|SizeInFileStorage,
		|Message,
		|Title");
		
	TestNewer = " (" + NStr("en = 'newer';") + ")";
	If ChangeDateInWorkingDirectory > ChangeDateInFileStorage Then
		ChangeDateInWorkingDirectory = String(ChangeDateInWorkingDirectory) + TestNewer;
	Else
		ChangeDateInFileStorage = String(ChangeDateInFileStorage) + TestNewer;
	EndIf;
	
	Items.Message.Height = StrLineCount(Message) + 2;
	
	If Parameters.FileOperation = "PutInFileStorage" Then
		
		Items.FormOpenExistingFile.Visible = False;
		Items.FormGetFromStorage.Visible    = False;
		Items.FormInto.DefaultButton   = True;
		
	ElsIf Parameters.FileOperation = "OpenInWorkingFolder" Then
		
		Items.FormInto.Visible  = False;
		Items.FormDontPut.Visible = False;
		Items.FormOpenExistingFile.DefaultButton = True;
	Else
		Raise NStr("en = 'Unknown file operation.';");
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		Items.MessageIcon.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenExistingFile(Command)
	
	Close("OpenExistingFile");
	
EndProcedure

&AtClient
Procedure Into(Command)
	
	Close("Into");
	
EndProcedure

&AtClient
Procedure GetFromApplication(Command)
	
	Close("GetFromStorageAndOpen");
	
EndProcedure

&AtClient
Procedure DontPut(Command)
	
	Close("DontPut");
	
EndProcedure

&AtClient
Procedure OpenDirectory(Command)
	
	FilesOperationsInternalClient.OpenExplorerWithFile(FullFileNameInWorkingDirectory);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close("Cancel");
	
EndProcedure

#EndRegion
