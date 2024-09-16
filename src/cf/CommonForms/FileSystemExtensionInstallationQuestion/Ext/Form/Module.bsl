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
	
	If Not IsBlankString(Parameters.SuggestionText) Then
		Items.DecorationNote.Title = Parameters.SuggestionText
			+ Chars.LF
			+ NStr("en = 'Do you want to install it?';");
		
	ElsIf Not Parameters.CanContinueWithoutInstalling Then
		Items.DecorationNote.Title =
			NStr("en = 'This operation requires 1C:Enterprise Extension.
			           |Do you want to install it?';");
	EndIf;
	
	If Not Parameters.CanContinueWithoutInstalling Then
		Items.ContinueWithoutInstalling.Title = NStr("en = 'Cancel';");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure InstallAndContinue(Command)
	
	Notification = New NotifyDescription("InstallAndContinueCompletion", ThisObject);
	BeginInstallFileSystemExtension(Notification);
	
EndProcedure

&AtClient
Procedure ContinueWithoutInstalling(Command)
	
	Close("DoNotPrompt");
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure InstallAndContinueCompletion(Context) Export
	
	Notification = New NotifyDescription("InstallAndContinueAfterAttachExtension", ThisObject);
	BeginAttachingFileSystemExtension(Notification);
	
EndProcedure

&AtClient
Procedure InstallAndContinueAfterAttachExtension(Attached, Context) Export
	
	If Attached Then
		Close("ExtensionAttached");
	Else
		Close("ContinueWithoutInstalling");
	EndIf;
	
EndProcedure

#EndRegion
