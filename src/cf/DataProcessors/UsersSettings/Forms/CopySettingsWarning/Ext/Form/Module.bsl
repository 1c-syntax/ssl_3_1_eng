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
	
	OpenFormsToCopy = Parameters.OpenFormsToCopy;
	Items.GroupActiveUsers.Visible    = Parameters.HasActiveUsersRecipients;
	Items.OpenFormsWithSettingsBeingCopiedGroup.Visible = ValueIsFilled(OpenFormsToCopy);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ActiveUsersListClick(Item)
	
	StandardSubsystemsClient.OpenActiveUserList();
	
EndProcedure

&AtClient
Procedure MessageOpenFormsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	ShowMessageBox(, OpenFormsToCopy);
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Copy(Command)
	
	If Parameters.Action <> "CopyAndClose" Then
		Close();
	EndIf;
	
	Result = New Structure("Action", Parameters.Action);
	Close(Result);
	
EndProcedure

#EndRegion
