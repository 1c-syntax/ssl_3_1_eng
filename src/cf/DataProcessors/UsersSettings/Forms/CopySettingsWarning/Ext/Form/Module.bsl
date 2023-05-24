﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlersForm

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	OpenFormsToCopy = Parameters.OpenFormsToCopy;
	Items.GroupActiveUsers.Visible    = Parameters.HasActiveUsersRecipients;
	Items.OpenFormsWithSettingsBeingCopiedGroup.Visible = ValueIsFilled(OpenFormsToCopy);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ActiveUserListClick(Item)
	
	StandardSubsystemsClient.OpenActiveUserList();
	
EndProcedure

&AtClient
Procedure MessageOpenFormsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	ShowMessageBox(, OpenFormsToCopy);
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Copy(Command)
	
	If Parameters.Action <> "CopyAndClose" Then
		Close();
	EndIf;
	
	Result = New Structure("Action", Parameters.Action);
	Close(Result);
	
EndProcedure

#EndRegion