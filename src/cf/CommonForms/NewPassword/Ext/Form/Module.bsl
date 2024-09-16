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
	
	ForExternalUser = Parameters.ForExternalUser;
	NewPassword = NewPassword(ForExternalUser);
	
	If Common.IsMobileClient() Then
		Items.FormClose.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateAnotherOne(Command)
	
	NewPassword = NewPassword(ForExternalUser);
	
EndProcedure

&AtServerNoContext
Function NewPassword(ForExternalUser)
	
	PasswordProperties = Users.PasswordProperties();
	PasswordProperties.MinLength = 8;
	PasswordProperties.Complicated = True;
	PasswordProperties.ConsiderSettings = ?(ForExternalUser, "ForExternalUsers", "ForUsers");
	
	Return Users.CreatePassword(PasswordProperties);
	
EndFunction

#EndRegion
