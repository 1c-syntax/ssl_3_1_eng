///////////////////////////////////////////////////////////////////////////////////////////////////////
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
	
	User = Parameters.User;
	ServiceUserPassword = Parameters.ServiceUserPassword;
	OldEmail = Parameters.OldEmail;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ChangeEmailAddress(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	QueryText = "";
	If Not ValueIsFilled(OldEmail) Then
		QueryText =
			NStr("en = 'The email address of the service user is changed.
			           |Subscriber owners and administrators cannot change the user parameters from now on.';")
			+ Chars.LF
			+ Chars.LF;
	EndIf;
	QueryText = QueryText + NStr("en = 'Do you want to change the email address?';");
	
	ShowQueryBox(
		New NotifyDescription("ChangeEmailFollowUp", ThisObject),
		QueryText,
		QuestionDialogMode.YesNoCancel);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CreateEmailAddressChangeRequest()
	
	SSLSubsystemsIntegration.OnCreateRequestToChangeEmail(NewEmailAddress,
		User, ServiceUserPassword);
	
EndProcedure

&AtClient
Procedure ChangeEmailFollowUp(Response, Context) Export
	
	If Response = DialogReturnCode.Yes Then
		
		Try
			CreateEmailAddressChangeRequest();
		Except
			ServiceUserPassword = "";
			AttachIdleHandler("CloseForm", 0.1, True);
			Raise;
		EndTry;
		
		ShowMessageBox(
			New NotifyDescription("ChangeEmailAddressCompletion", ThisObject, Context),
			NStr("en = 'A confirmation request is sent to the specified email address.
			           |The email address will be changed after the confirmation.';"));
		
	ElsIf Response = DialogReturnCode.No Then
		ChangeEmailAddressCompletion(Context);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeEmailAddressCompletion(Context) Export
	
	Close();
	
EndProcedure

&AtClient
Procedure CloseForm()
	
	Close(ServiceUserPassword);
	
EndProcedure

#EndRegion
