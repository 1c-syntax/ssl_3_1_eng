///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens the form for creating a new message.
//
// Parameters:
//  EmailSendOptions  - See EmailOperationsClient.EmailSendOptions.
//  FormClosingNotification - NotifyDescription -  the procedure to transfer control to after closing
//                                                  the email sending form.
//
Procedure CreateNewEmailMessage(EmailSendOptions = Undefined, FormClosingNotification = Undefined) Export
	
	SendOptions = EmailMessageCompositionParameters();
	If EmailSendOptions <> Undefined Then
		CommonClientServer.SupplementStructure(SendOptions, EmailSendOptions, True);
	EndIf;
	
	InfoForSending = EmailServerCall.InfoForSending(SendOptions);
	SendOptions.ShowAttachmentSaveFormatSelectionDialog = InfoForSending.ShowAttachmentSaveFormatSelectionDialog;
	SendOptions.FormClosingNotification = FormClosingNotification;
	
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

// Returns an empty structure with parameters for sending the message.
//
// Returns:
//  Structure - :
//   * Sender - CatalogRef.EmailAccounts -  the account that
//                   the email message can be sent from;
//                 - ValueList - :
//                     ** Presentation - String - 
//                     ** Value - CatalogRef.EmailAccounts -  user account.
//    
//   * Recipient - String - :
//                           
//                - ValueList:
//                   ** Presentation - String - 
//                   ** Value      - String -  postal address.
//                - Array - :
//                   ** Address                        - String -  email address of the message recipient;
//                   ** Presentation                - String -  representation of the addressee;
//                   ** ContactInformationSource - CatalogRef -  owner of the contact information.
//   
//   * Cc - ValueList
//           - String - see the description of the Recipient field.
//   * BCCs - ValueList
//                  - String - see the description of the Recipient field.
//   * Subject - String -        message subject.
//   * Text - String -        message body.
//
//   * Attachments - Array - :
//     ** Presentation - String -  attachment file name;
//     ** AddressInTempStorage - String -  address of binary data or a table document in temporary storage.
//     ** Encoding - String -  encoding of the attachment (used if it differs from the encoding of the message).
//     ** Id - String -  (optional) used to mark images displayed in the message body.
//   
//   * DeleteFilesAfterSending - Boolean -  delete temporary files after sending a message.
//   * SubjectOf - AnyRef -  subject of the letter.
//   * IsInteractiveRecipientSelection - Boolean -  
// 				 
// 				 
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
	EmailParameters.Insert("IsInteractiveRecipientSelection", False);
	
	Return EmailParameters;
EndFunction

// 
// 
// 
// 
//
// Parameters:
//  ResultHandler - NotifyDescription -  the procedure in which you want to transfer code execution after verification.
//                                              The result returns True if there is
//                                              an account available for sending mail. Otherwise, it returns False.
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

// 
// 
// 
// Parameters:
//  Account - CatalogRef.EmailAccounts
//  Title - String - 
//  ErrorText - String - 
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

// Continue with the create new Message procedure.
Procedure CreateNewEmailMessageAccountChecked(AccountSetUp, SendOptions) Export
	
	If AccountSetUp <> True Then
		Return;
	EndIf;
	
	If SendOptions.ShowAttachmentSaveFormatSelectionDialog Then
		NotifyDescription = New NotifyDescription("CreateNewEmailMessagePrepareAttachments", ThisObject, SendOptions);
		CommonClient.ShowAttachmentsFormatSelection(NotifyDescription, Undefined);
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

// Continue with the create new Message procedure.
Procedure CreateNewEmailMessageAttachmentsPrepared(AttachmentsPrepared, SendOptions, IsRecipientsSelected = False)

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
	
	SendOptions.Insert("FormClosingNotification", FormClosingNotification);
	
	FormParameters = New Structure;
	FormParameters.Insert("Recipients", SendOptions.Recipient);
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print")
		And SendOptions.IsInteractiveRecipientSelection 
		And (SendOptions.Property("DisableRecipientSelection") = False Or SendOptions.DisableRecipientSelection = False)   
		And ValueIsFilled(SendOptions.Recipient) And SendOptions.Recipient.Count() > 1 Then
		
		FormParameters.Insert("ShouldSkipAttachmentFormatSelection", True);
		
		NotifyDescription = New NotifyDescription("AfterRecipientsSelected", ThisObject, SendOptions);
		ModulePrintManagerInternalClient = CommonClient.CommonModule("PrintManagementInternalClient");
		
		ModulePrintManagerInternalClient.OpenNewMailPreparationForm(ThisObject, 
			FormParameters, NotifyDescription);
		
		Return;
	EndIf;

	AfterRecipientsSelected(FormParameters, SendOptions);
	
EndProcedure

Procedure AfterRecipientsSelected(Result, SendOptions) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	FormClosingNotification = SendOptions.FormClosingNotification;
	SendOptions.Delete("FormClosingNotification");
	SendOptions.Recipient = Result.Recipients;
	
	If CommonClient.SubsystemExists("StandardSubsystems.Interactions") 
		And StandardSubsystemsClient.ClientRunParameters().OutgoingEmailsCreationAvailable Then
		ModuleInteractionsClient = CommonClient.CommonModule("InteractionsClient");
		ModuleInteractionsClient.OpenEmailSendingForm(SendOptions, FormClosingNotification);
	Else
		OpenSimpleSendEmailMessageForm(SendOptions, FormClosingNotification);
	EndIf;
	
EndProcedure

// An interface client function that supports a simplified call to a simple
// form of editing a new letter. When sending a letter through a simple
// form, the messages are not saved in the information database.
//
// For parameters, see the description of the Create New Message function.
//
Procedure OpenSimpleSendEmailMessageForm(EmailParameters, OnCloseNotifyDescription)
	OpenForm("CommonForm.SendMessage", EmailParameters, , , , , OnCloseNotifyDescription);
EndProcedure

Procedure CheckAccountForSendingEmailExistsCompletion(ResultHandler) Export
	ExecuteNotifyProcessing(ResultHandler, False);
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

Function EmailMessageCompositionParameters()
	EmailParameters = EmailSendOptions();
	EmailParameters.Insert("ShowAttachmentSaveFormatSelectionDialog", False);
	EmailParameters.Insert("FormClosingNotification", Undefined);
	Return EmailParameters;
EndFunction

#EndRegion
