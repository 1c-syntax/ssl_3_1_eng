///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Opens a message creation form.
//
// Parameters:
//  EmailSendOptions  - See EmailOperationsClient.EmailSendOptions.
//  FormClosingNotification - NotifyDescription - procedure to be executed after closing
//                                                  the message sending form.
//
Procedure CreateNewEmailMessage(EmailSendOptions = Undefined, FormClosingNotification = Undefined) Export
	
	SendOptions = EmailSendOptions();
	If EmailSendOptions <> Undefined Then
		CommonClientServer.SupplementStructure(SendOptions, EmailSendOptions, True);
	EndIf;
	
	InfoForSending = EmailServerCall.InfoForSending(SendOptions);
	SendOptions.Insert("ShowAttachmentSaveFormatSelectionDialog", InfoForSending.ShowAttachmentSaveFormatSelectionDialog);
	SendOptions.Insert("FormClosingNotification", FormClosingNotification);
	
	If TypeOf(SendOptions.Recipient) = Type("String") Then
		SendOptions.Recipient = ListOfRecipientsFromString(SendOptions.Recipient);
	EndIf;
	
	If InfoForSending.HasAvailableAccountsForSending Then
		CreateNewEmailMessageAccountChecked(True, SendOptions);
	Else
		ResultHandler = New NotifyDescription("CreateNewEmailMessageAccountChecked", ThisObject, SendOptions);
		If InfoForSending.CanAddNewAccounts Then
			OpenForm("Catalog.EmailAccounts.Form.AccountSetupWizard", 
				New Structure("ContextMode", True), , , , , ResultHandler);
		Else
			MessageText = NStr("en = 'To send messages, set up the email account.
				|Contact the administrator.';");
			NotifyDescription = New NotifyDescription("CheckAccountForSendingEmailExistsCompletion", ThisObject, ResultHandler);
			ShowMessageBox(NotifyDescription, MessageText);
		EndIf;
	EndIf;
	
EndProcedure

// Returns an empty structure with email sending parameters.
//
// Returns:
//  Structure - parameters for filling the sending form for a new message (all optional):
//   * Sender - CatalogRef.EmailAccounts - account used to
//                   send the email message.
//                 - ValueList - list of accounts available for selection in the following format:
//                     ** Presentation - String - email name.
//                     ** Value - CatalogRef.EmailAccounts - an account.
//    
//   * Recipient - String - list of addresses in the following format:
//                           [RecipientPresentation1] <Address1>; [[RecipientPresentation2] <Address2>;…]
//                - ValueList:
//                   ** Presentation - String - an addressee presentation.
//                   ** Value      - String - an email address.
//                - Array - Array of structures describing recipients:
//                   ** Address                        - String - an email recipient address.
//                   ** Presentation                - String - an addressee presentation.
//                   ** ContactInformationSource - CatalogRef - contact information owner.
//   
//   * Cc - ValueList
//           - String - See the "Recipient" field description.
//   * BCCs - ValueList
//                  - String - See the "Recipient" field description.
//   * Subject - String - an email subject.
//   * Text - String - an email body.
//
//   * Attachments - Array - files to be attached (described as structures):
//     ** Presentation - String - an attachment file name.
//     ** AddressInTempStorage - String - address of binary data or spreadsheet document in temporary storage.
//     ** Encoding - String - an attachment encoding (used if it differs from the message encoding).
//     ** Id - String - (optional) used to store images displayed in the message body.
//   
//   * DeleteFilesAfterSending - Boolean - delete temporary files after sending the message.
//   * SubjectOf - AnyRef - an email subject.
//
Function EmailSendOptions() Export
	EmailParameters = New Structure;
	
	EmailParameters.Insert("Sender", Undefined);
	EmailParameters.Insert("Recipient", Undefined);
	EmailParameters.Insert("Cc", Undefined);
	EmailParameters.Insert("BCCs", Undefined);
	EmailParameters.Insert("Subject", Undefined);
	EmailParameters.Insert("Text", Undefined);
	EmailParameters.Insert("Attachments", Undefined);
	EmailParameters.Insert("DeleteFilesAfterSending", Undefined);
	EmailParameters.Insert("SubjectOf", Undefined);
	
	Return EmailParameters;
EndFunction

// If a user has no email account configured for sending emails, does one of the following depending on the access rights: starts
// the email account setup wizard, or displays a message that email cannot be sent.
// The procedure is intended for scenarios that require email account setup before requesting additional
// sending parameters.
//
// Parameters:
//  ResultHandler - NotifyDescription - procedure to be executed after the check is completed.
//                                              True returns if there is an available
//                                              account for sending emails.
//
Procedure CheckAccountForSendingEmailExists(ResultHandler) Export
	If EmailServerCall.HasAvailableAccountsForSending() Then
		ExecuteNotifyProcessing(ResultHandler, True);
	Else
		If EmailServerCall.CanAddNewAccounts() Then
			OpenForm("Catalog.EmailAccounts.Form.AccountSetupWizard", 
				New Structure("ContextMode", True), , , , , ResultHandler);
		Else	
			MessageText = NStr("en = 'To send messages, set up the email account.
				|Contact the administrator.';");
			NotifyDescription = New NotifyDescription("CheckAccountForSendingEmailExistsCompletion", ThisObject, ResultHandler);
			ShowMessageBox(NotifyDescription, MessageText);
		EndIf;
	EndIf;
EndProcedure

// Opens an error dialog.
// Besides the error message, it contains the possible reasons and troubleshooting tips.
// 
// Parameters:
//  Account - CatalogRef.EmailAccounts
//  Title - String - Title of the opening form.
//  ErrorText - String - Original exception text. We recommend to pass BriefErrorPresentation.
//
Procedure ReportConnectionError(Account, Title, ErrorText) Export
	
	OpenForm("Catalog.EmailAccounts.Form.ValidatingAccountSettings", 
		New Structure("Account, Title, ErrorText", Account, Title, ErrorText));
	
EndProcedure

#EndRegion

#Region Internal

Procedure GoToEmailAccountInputDocumentation() Export
	
	FileSystemClient.OpenURL("https://its.1c.eu/bmk/bsp_email_account");
	
EndProcedure

Procedure PasswordFieldStartChoice(Item, Attribute, StandardProcessing) Export
	
	StandardProcessing = False;
	Attribute = Item.EditText;
	Item.PasswordMode = Not Item.PasswordMode;
	If Item.PasswordMode Then
		Item.ChoiceButtonPicture = PictureLib.CharsBeingTypedShown;
	Else
		Item.ChoiceButtonPicture = PictureLib.CharsBeingTypedHidden;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Continues the CreateNewEmailMessage procedure.
Procedure CreateNewEmailMessageAccountChecked(AccountSetUp, SendOptions) Export
	
	If AccountSetUp <> True Then
		Return;
	EndIf;
	
	If SendOptions.ShowAttachmentSaveFormatSelectionDialog Then
		NotifyDescription = New NotifyDescription("CreateNewEmailMessagePrepareAttachments", ThisObject, SendOptions);
		OpenForm("CommonForm.SelectAttachmentFormat", , , , , , NotifyDescription);
		Return;
	EndIf;
	
	CreateNewEmailMessageAttachmentsPrepared(True, SendOptions);
	
EndProcedure

Procedure CreateNewEmailMessagePrepareAttachments(SettingsForSaving, SendOptions) Export
	If TypeOf(SettingsForSaving) <> Type("Structure") Then
		Return;
	EndIf;
	
	EmailServerCall.PrepareAttachments(SendOptions.Attachments, SettingsForSaving);
	
	CreateNewEmailMessageAttachmentsPrepared(True, SendOptions);
EndProcedure

// Continues the CreateNewEmailMessage procedure.
Procedure CreateNewEmailMessageAttachmentsPrepared(AttachmentsPrepared, SendOptions)

	If AttachmentsPrepared <> True Then
		Return;
	EndIf;
	
	FormClosingNotification = SendOptions.FormClosingNotification;
	SendOptions.Delete("FormClosingNotification");
	
	StandardProcessing = True;
	EmailOperationsClientOverridable.BeforeOpenEmailSendingForm(SendOptions, FormClosingNotification, StandardProcessing);
	
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.Interactions") 
		And StandardSubsystemsClient.ClientRunParameters().OutgoingEmailsCreationAvailable Then
		ModuleInteractionsClient = CommonClient.CommonModule("InteractionsClient");
		ModuleInteractionsClient.OpenEmailSendingForm(SendOptions, FormClosingNotification);
	Else
		OpenSimpleSendEmailMessageForm(SendOptions, FormClosingNotification);
	EndIf;
	
EndProcedure

// Client interface function supporting simplified call of simple
// form for editing new message. Messages sent using simple
// form are not saved to the infobase.
//
// For parameters, see the CreateNewEmailMessage function description.
//
Procedure OpenSimpleSendEmailMessageForm(EmailParameters, OnCloseNotifyDescription)
	OpenForm("CommonForm.SendMessage", EmailParameters, , , , , OnCloseNotifyDescription);
EndProcedure

Procedure CheckAccountForSendingEmailExistsCompletion(ResultHandler) Export
	ExecuteNotifyProcessing(ResultHandler, False);
EndProcedure

Procedure ValidateAccountSettings(Account, Form) Export
	
	Parameters = New Structure("Account", Account);
	OpenForm("Catalog.EmailAccounts.Form.ValidatingAccountSettings", Parameters, Form);
	
EndProcedure

Function ListOfRecipientsFromString(Val Recipients)
	
	Result = New ValueList;
	
	EmailsFromString = CommonClientServer.EmailsFromString(Recipients);
	For Each AddrDetails In EmailsFromString Do
		If ValueIsFilled(AddrDetails.Address) Then
			Result.Add(AddrDetails.Address, AddrDetails.Alias);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion
