﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure;
	If TypeOf(CommandExecuteParameters.Source) = Type("ClientApplicationForm") Then
		If CommandExecuteParameters.Source.FormName =
			"Catalog.Users.Form.ListForm" Then
			FormParameters.Insert("Filter", "Users");
		ElsIf CommandExecuteParameters.Source.FormName =
			"Catalog.ExternalUsers.Form.ListForm" Then
			FormParameters.Insert("Filter", "ExternalUsers");
		EndIf;
	EndIf;
	
	OpenForm(
		"Catalog.Users.Form.InfoBaseUsers",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
