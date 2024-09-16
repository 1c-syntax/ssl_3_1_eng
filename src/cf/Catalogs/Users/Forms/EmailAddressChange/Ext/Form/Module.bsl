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
	
	OldEmail = Parameters.OldEmail;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeEmailAddress(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(OldEmail) Then
		QueryText =
			NStr("en = 'The service user''s email address will be set.
			           |Subscriber owners and administrators will no longer be able to change the user parameters.
			           |
			           |Do you want to set the email address?';");
	Else
		QueryText = NStr("en = 'Do you want to change the email address?';");
	EndIf;
	
	ShowQueryBox(
		New NotifyDescription("ChangeEmailFollowUp", ThisObject),
		QueryText,
		QuestionDialogMode.YesNoCancel);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChangeEmailFollowUp(Response, Context) Export
	
	If Response = DialogReturnCode.Yes Then
		Close(NewEmailAddress);
	ElsIf Response = DialogReturnCode.No Then
		Close(Undefined);
	EndIf;
	
EndProcedure

#EndRegion
