///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Sends a single email.
// The function may raise an exception that needs to be handled.
//
// Parameters:
//  UserAccountOrConnection - CatalogRef.EmailAccounts -  the mailbox to
//                                                                   send from.
//                             - InternetMail - 
//                
//  MailMessage - InternetMailMessage -  the email being sent.
//
// Returns:
//  Structure - :
//   * WrongRecipients - Map of KeyAndValue - :
//    ** Key     - String -  recipient address;
//    ** Value - String -  error text.
//   * SMTPEmailID - String -  unique message ID assigned when sending via SMTP.
//   * IMAPEmailID - String -  a unique message ID assigned when sending over the IMAP Protocol.
//
Function SendMail(UserAccountOrConnection, MailMessage) Export
	
	Return EmailOperationsInternal.SendMail(UserAccountOrConnection, MailMessage);
	
EndFunction

// Sends multiple emails.
// The function may raise an exception that needs to be handled.
// If at least one email was successfully sent before the sending error occurred, no exception is thrown,
// so when processing the function result, you need to check which emails were not sent.
//
// Parameters:
//  UserAccountOrConnection - CatalogRef.EmailAccounts -  the mailbox to
//                                                                   send from.
//                             - InternetMail - 
//  
//  Emails - Array of InternetMailMessage -  collection of mail messages. The collection element is an Internet mail Message.
//  ErrorText - String -  the error message in the case when they managed to send all the letters.
//
// Returns:
//  Map of KeyAndValue:
//   * Key     - InternetMailMessage -  sending email;
//   * Value - Structure - :
//    ** WrongRecipients - Map of KeyAndValue - :
//     *** Key     - String -  recipient address;
//     *** Value - String -  error text.
//    ** SMTPEmailID - String -  unique message ID assigned when sending via SMTP.
//    ** IMAPEmailID - String -  a unique message ID assigned when sending over the IMAP Protocol.
//
Function SendEmails(UserAccountOrConnection, Emails, ErrorText = Undefined) Export
	
	Return EmailOperationsInternal.SendEmails(UserAccountOrConnection, Emails, ErrorText);
	
EndFunction

// 
// 
// 
//
// Parameters:
//   UserAccountOrConnection - CatalogRef.EmailAccounts - 
//                              
//                              - InternetMail - 
//   ImportParameters - Structure:
//     * Columns - Array -  array of column
//                          name strings column names must match the object's fields
//                          Internet mail message.
//     * TestMode - Boolean -  used for checking the connection to the server.
//     * GetHeaders - Boolean -  if True, the returned set contains only
//                                       email headers.
//     * Filter - Structure - 
//     * HeadersIDs - Array -  headers or IDs of messages
//                                    that you want to get full messages for.
//     * CastMessagesToType - Boolean -  return a set of received mail messages
//                                    as a table of values with simple types. By default, True.
//
// Returns:
//  ValueTable, Boolean - :
//   * Importance - InternetMailMessageImportance
//   * Attachments - InternetMailAttachments -  if the attachments are other mail messages,
//                 they are not returned themselves, but their attachments are returned-binary
//                 data and their texts as binary data, recursively.
//   * PostingDate - Date
//   * DateReceived - Date
//   * Title - String
//   * SenderName - String
//   * Id - Array of String
//   * Cc - InternetMailAddresses
//   * ReplyTo - InternetMailAddresses
//   * Sender - String
//                 - InternetMailAddress
//   * Recipients - InternetMailAddresses
//   * Size - Number
//   * Texts - InternetMailTexts
//   * Encoding - String
//   * NonASCIISymbolsEncodingMode - InternetMailMessageNonASCIISymbolsEncodingMode
//   * Partial - Boolean -  filled in if the status is True. In testing mode, it returns True.
//
Function DownloadEmailMessages(Val UserAccountOrConnection, Val ImportParameters = Undefined) Export
	
	Var Account;
	
	If TypeOf(UserAccountOrConnection) <> Type("InternetMail") Then
		Account = UserAccountOrConnection;
	EndIf;
	
	If Account <> Undefined Then
		UseForReceiving = Common.ObjectAttributeValue(Account, "UseForReceiving");
		If Not UseForReceiving Then
			Raise NStr("en = 'The account is not intended to receive messages.';");
		EndIf;
	EndIf;
	
	If ImportParameters = Undefined Then
		ImportParameters = New Structure;
	EndIf;
	
	Result = EmailOperationsInternal.DownloadMessages(UserAccountOrConnection, ImportParameters);
	Return Result;
	
EndFunction

// Get available email accounts.
//
//  Parameters:
//   ForSending  - Boolean -  select only accounts that are configured to send mail.
//   ForReceiving - Boolean -  select only accounts that are configured to receive mail.
//   IncludingSystemEmailAccount - Boolean -  enable the system account if configured for sending/receiving.
//
// Returns:
//  ValueTable - :
//   * Ref       - CatalogRef.EmailAccounts -  user account;
//   * Description - String - 
//   * Address        - String -  email address.
//
Function AvailableEmailAccounts(Val ForSending = Undefined,
								Val ForReceiving  = Undefined,
								Val IncludingSystemEmailAccount = True) Export
	
	If Not AccessRight("Read", Metadata.Catalogs.EmailAccounts) Then
		Return New ValueTable;
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED
	|	EmailAccounts.Ref AS Ref,
	|	EmailAccounts.Description AS Description,
	|	EmailAccounts.Email AS Address,
	|	CASE
	|		WHEN EmailAccounts.Ref = VALUE(Catalog.EmailAccounts.SystemEmailAccount)
	|			THEN 0
	|		ELSE 1
	|	END AS Priority
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.DeletionMark = FALSE
	|	AND CASE
	|			WHEN &ForSending = UNDEFINED
	|				THEN TRUE
	|			ELSE EmailAccounts.UseForSending = &ForSending
	|		END
	|	AND CASE
	|			WHEN &ForReceiving = UNDEFINED
	|				THEN TRUE
	|			ELSE EmailAccounts.UseForReceiving = &ForReceiving
	|		END
	|	AND CASE
	|			WHEN &IncludingSystemEmailAccount
	|				THEN TRUE
	|			ELSE EmailAccounts.Ref <> VALUE(Catalog.EmailAccounts.SystemEmailAccount)
	|		END
	|	AND EmailAccounts.Email <> """"
	|	AND CASE
	|			WHEN EmailAccounts.UseForReceiving
	|				THEN EmailAccounts.IncomingMailServer <> """"
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN EmailAccounts.UseForSending
	|				THEN EmailAccounts.OutgoingMailServer <> """"
	|			ELSE TRUE
	|		END
	|	AND (EmailAccounts.AccountOwner = VALUE(Catalog.Users.EmptyRef)
	|			OR EmailAccounts.AccountOwner = &CurrentUser)
	|
	|ORDER BY
	|	Priority,
	|	Description";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.Parameters.Insert("ForSending", ForSending);
	Query.Parameters.Insert("ForReceiving", ForReceiving);
	Query.Parameters.Insert("IncludingSystemEmailAccount", IncludingSystemEmailAccount);
	Query.Parameters.Insert("CurrentUser", Users.CurrentUser());
	
	Return Query.Execute().Unload();
	
EndFunction

// 
//
// Returns:
//  CatalogRef.EmailAccounts
//
Function SystemAccount() Export
	
	Return Catalogs.EmailAccounts.SystemEmailAccount;
	
EndFunction

// 
//
// Returns:
//  Boolean
//
Function CheckSystemAccountAvailable() Export
	
	Return EmailOperationsInternal.CheckSystemAccountAvailable();
	
EndFunction

// 
// 
//
// Returns:
//  Boolean
//
Function CanSendEmails() Export
	
	If AccessRight("Update", Metadata.Catalogs.EmailAccounts) Then
		Return True;
	EndIf;
	
	If Not AccessRight("Read", Metadata.Catalogs.EmailAccounts) Then
		Return False;
	EndIf;
		
	QueryText = 
	"SELECT ALLOWED TOP 1
	|	1 AS Count
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	NOT EmailAccounts.DeletionMark
	|	AND EmailAccounts.UseForSending
	|	AND EmailAccounts.Email <> """"
	|	AND EmailAccounts.OutgoingMailServer <> """"
	|	AND (EmailAccounts.AccountOwner = VALUE(Catalog.Users.EmptyRef)
	|			OR EmailAccounts.AccountOwner = &CurrentUser)";
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("CurrentUser", Users.CurrentUser());
	Selection = Query.Execute().Select();
	
	Return Selection.Next();
	
EndFunction

// Checks whether the account is configured to send and/or receive mail.
//
// Parameters:
//  Account - CatalogRef.EmailAccounts -  check the account;
//  ForSending  - Boolean -  check the parameters required for sending mail;
//  ForReceiving - Boolean -  check the parameters required for receiving mail.
// 
// Returns:
//  Boolean - 
//
Function AccountSetUp(Account, Val ForSending = Undefined, Val ForReceiving = Undefined) Export
	
	Parameters = Common.ObjectAttributesValues(Account, "Email,IncomingMailServer,OutgoingMailServer,UseForReceiving,UseForSending,ProtocolForIncomingMail");
	If ForSending = Undefined Then
		ForSending = Parameters.UseForSending;
	EndIf;
	If ForReceiving = Undefined Then
		ForReceiving = Parameters.UseForReceiving;
	EndIf;
	
	Return Not (IsBlankString(Parameters.Email) 
		Or ForReceiving And IsBlankString(Parameters.IncomingMailServer)
		Or ForSending And (IsBlankString(Parameters.OutgoingMailServer)
			Or (Parameters.ProtocolForIncomingMail = "IMAP" And IsBlankString(Parameters.IncomingMailServer))));
		
EndFunction

// 
//
// Parameters:
//  Account     - CatalogRef.EmailAccounts - 
//  ErrorMessage - String - 
//  AdditionalMessage - String - 
//
Procedure CheckSendReceiveEmailAvailability(Account, ErrorMessage, AdditionalMessage) Export
	
	EmailOperationsInternal.CheckSendReceiveEmailAvailability(Account, 
		ErrorMessage, AdditionalMessage);
	
EndProcedure

// Checks whether the HTML document contains links to resources loaded via http (s).
//
// Parameters:
//  HTMLDocument - HTMLDocument -  the HTML document in which you want to perform the validation.
//
// Returns:
//  Boolean - 
//
Function HasExternalResources(HTMLDocument) Export
	
	Return EmailOperationsInternal.HasExternalResources(HTMLDocument);
	
EndFunction

// Removes HTML scripts and event handlers from the document, and clears links to resources loaded via http(s).
//
// Parameters:
//  HTMLDocument - HTMLDocument -  the HTML document in which you want to clear the insecure content.
//  DisableExternalResources - Boolean -  indicates whether to clear links to resources uploaded via http(s).
// 
Procedure DisableUnsafeContent(HTMLDocument, DisableExternalResources = True) Export
	
	EmailOperationsInternal.DisableUnsafeContent(HTMLDocument, DisableExternalResources);
	
EndProcedure

// 
// 
// Parameters:
//   ErrorText - String - 
// 	
// Returns:
//  Structure:
//   * PossibleReasons - Array of FormattedString
//   * MethodsToFixError - Array of FormattedString
//
Function ExplanationOnError(ErrorText) Export
	
	Return EmailOperationsInternal.ExplanationOnError(ErrorText);
	
EndFunction

// 
// 
// Parameters:
//  ErrorInfo - ErrorInfo
//  LanguageCode - String -  the language code of the props. For example, "ru".
//  EnableVerboseRepresentationErrors - Boolean - 
//  
// Returns:
//  String
//
Function ExtendedErrorPresentation(ErrorInfo, LanguageCode, EnableVerboseRepresentationErrors = True) Export
	
	Return EmailOperationsInternal.ExtendedErrorPresentation(
		ErrorInfo, LanguageCode, EnableVerboseRepresentationErrors);
	
EndFunction

// 
//
// Returns:
//  Structure:
//    * DeliveryReceiptAddresses - String
//    * ReadReceiptAddresses - String
//    * Importance - String
//    * Attachments - String
//    * PostingDate - String
//    * DateReceived - String
//    * Header - String
//    * UID - String
//    * MessageID - String
//    * SenderName - String
//    * Categories - String
//    * Encoding - String
//    * Cc - String
//    * ReplyTo - String
//    * From - String
//    * To - String
//    * Size - String
//    * Bcc - String
//    * PostingDateOffset - String
//    * ParseStatus - String
//    * Subject - String
//    * Texts - String
//    * NonASCIISymbolsEncodingMode - String
//    * RequestDeliveryReceipt - String
//    * RequestReadReceipt - String
//    * Partial - String
//
Function InternetMailMessageFields() Export
	
	MessageFields = New Structure;

	MessageFields.Insert("DeliveryReceiptAddresses", "DeliveryReceiptAddresses"); 
	MessageFields.Insert("ReadReceiptAddresses", "ReadReceiptAddresses");
	MessageFields.Insert("Importance", "Importance");
	MessageFields.Insert("Attachments", "Attachments");
	MessageFields.Insert("PostingDate", "PostingDate");
	MessageFields.Insert("DateReceived", "DateReceived");
	MessageFields.Insert("Header", "Header");
	MessageFields.Insert("SenderName", "SenderName");
	MessageFields.Insert("UID", "UID");
	MessageFields.Insert("MessageID", "MessageID");
	MessageFields.Insert("Categories", "Categories");
	MessageFields.Insert("Encoding", "Encoding");
	MessageFields.Insert("Cc", "Cc");
	MessageFields.Insert("ReplyTo", "ReplyTo");
	MessageFields.Insert("From", "From");
	MessageFields.Insert("To", "To");
	MessageFields.Insert("Size", "Size");
	MessageFields.Insert("Bcc", "Bcc");
	MessageFields.Insert("PostingDateOffset", "PostingDateOffset");
	MessageFields.Insert("ParseStatus", "ParseStatus");
	MessageFields.Insert("Subject", "Subject");
	MessageFields.Insert("Texts", "Texts");
	MessageFields.Insert("NonASCIISymbolsEncodingMode", "NonASCIISymbolsEncodingMode");
	MessageFields.Insert("RequestDeliveryReceipt", "RequestDeliveryReceipt");
	MessageFields.Insert("RequestReadReceipt", "RequestReadReceipt");
	MessageFields.Insert("Partial", "Partial");
	
	Return MessageFields;
	
EndFunction

// Generates a message based on the passed parameters.
//
// Parameters:
//  Account - CatalogRef.EmailAccounts -  link to the
//                 email account.
//  EmailParameters - Structure - :
//
//   * Whom - Array
//          - String - 
//          - Array - :
//              * Address         - String -  postal address (must be filled in).
//              * Presentation - String -  destination name.
//          - String - 
//
//   * MessageRecipients - Array - :
//      ** Address - String -  email address of the message recipient.
//      ** Presentation - String -  representation of the addressee.
//
//   * Cc        - Array
//                  - String - 
//
//   * BCCs - Array
//                  - String - 
//
//   * Subject       - String -  (required) subject of the email message.
//   * Body       - String -  (required) text of the email message (plain text in win-1251 encoding).
//   * Importance   - InternetMailMessageImportance
//
//   * Attachments - Array - :
//     ** Presentation - String -  attachment file name;
//     ** AddressInTempStorage - String -  address of the attachment's binary data in temporary storage.
//     ** Encoding - String -  encoding of the attachment (used if it differs from the encoding of the message).
//     ** Id - String -  (optional) used to mark images displayed in the message body.
//
//   * ReplyToAddress - Map
//                 - String - see the description of the To field.
//   * BasisIDs - String -  IDs of the bases of this message.
//   * ProcessTexts  - Boolean -  the need to process the message texts when sending.
//   * RequestDeliveryReceipt  - Boolean -  need to request a delivery notification.
//   * RequestReadReceipt - Boolean -  need to request a read notification.
//   * TextType   - String
//                 - EnumRef.EmailTextTypes
//                 - InternetMailTextType - 
//                  :
//                  
//                  
//                                                 
//                                                 
//                  
//                                                 
//
// Returns:
//  InternetMailMessage - 
//
Function PrepareEmail(Account, EmailParameters) Export
	
	If TypeOf(Account) <> Type("CatalogRef.EmailAccounts")
		Or Not ValueIsFilled(Account) Then
		Raise NStr("en = 'The account is not specified or specified incorrectly.';");
	EndIf;
	
	If EmailParameters = Undefined Then
		Raise NStr("en = 'The mail sending parameters are not specified.';");
	EndIf;
	
	RecipientValType = ?(EmailParameters.Property("Whom"), TypeOf(EmailParameters.Whom), Undefined);
	CcType = ?(EmailParameters.Property("Cc"), TypeOf(EmailParameters.Cc), Undefined);
	BCCs = CommonClientServer.StructureProperty(EmailParameters, "BCCs");
	
	If RecipientValType = Undefined And CcType = Undefined And BCCs = Undefined Then
		Raise NStr("en = 'No recipient is selected.';");
	EndIf;
	
	If RecipientValType = Type("String") Then
		EmailParameters.Whom = CommonClientServer.ParseStringWithEmailAddresses(EmailParameters.Whom);
	ElsIf RecipientValType <> Type("Array") Then
		EmailParameters.Insert("Whom", New Array);
	EndIf;
	
	If CcType = Type("String") Then
		EmailParameters.Cc = CommonClientServer.ParseStringWithEmailAddresses(EmailParameters.Cc);
	ElsIf CcType <> Type("Array") Then
		EmailParameters.Insert("Cc", New Array);
	EndIf;
	
	If TypeOf(BCCs) = Type("String") Then
		EmailParameters.BCCs = CommonClientServer.ParseStringWithEmailAddresses(BCCs);
	ElsIf TypeOf(BCCs) <> Type("Array") Then
		EmailParameters.Insert("BCCs", New Array);
	EndIf;
	
	If EmailParameters.Property("ReplyToAddress") And TypeOf(EmailParameters.ReplyToAddress) = Type("String") Then
		EmailParameters.ReplyToAddress = CommonClientServer.ParseStringWithEmailAddresses(EmailParameters.ReplyToAddress);
	EndIf;
	
	Return EmailOperationsInternal.PrepareEmail(Account, EmailParameters);
	
EndFunction

// 
//
// Parameters:
//  Account - CatalogRef.EmailAccounts - 
//  ForReceiving - Boolean - 
//                          
//  
// Returns:
//   InternetMail
//
Function ConnectToEmailAccount(Val Account, Val ForReceiving = False) Export
	
	Return EmailOperationsInternal.ConnectToEmailAccount(Account, ForReceiving);
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Sends mail messages.
// The function may raise an exception that needs to be handled.
//
// Parameters:
//  Account - CatalogRef.EmailAccounts -  link to the
//                 email account.
//  SendOptions - Structure - :
//
//   * Whom - Array
//          - String - 
//          - Array - :
//              * Address         - String -  postal address (must be filled in).
//              * Presentation - String -  destination name.
//          - String - 
//
//   * MessageRecipients - Array - :
//      ** Address - String -  email address of the message recipient.
//      ** Presentation - String -  representation of the addressee.
//
//   * Cc        - Array
//                  - String - 
//
//   * BCCs - Array
//                  - String - 
//
//   * Subject       - String -  (required) subject of the email message.
//   * Body       - String -  (required) text of the email message (plain text in win-1251 encoding).
//   * Importance   - InternetMailMessageImportance
//
//   * Attachments - Array - :
//     ** Presentation - String -  attachment file name;
//     ** AddressInTempStorage - String -  address of the attachment's binary data in temporary storage.
//     ** Encoding - String -  encoding of the attachment (used if it differs from the encoding of the message).
//     ** Id - String -  (optional) used to mark images displayed in the message body.
//
//   * ReplyToAddress - Map
//                 - String - see the description of the To field.
//   * BasisID  - String - 
//   * BasisIDs - String -  IDs of the bases of this message.
//   * ProcessTexts  - Boolean -  the need to process the message texts when sending.
//   * RequestDeliveryReceipt  - Boolean -  need to request a delivery notification.
//   * RequestReadReceipt - Boolean -  need to request a read notification.
//   * TextType   - String
//                 - EnumRef.EmailTextTypes
//                 - InternetMailTextType - 
//                  :
//                  
//                  
//                                                 
//                                                 
//                  
//                                                 
//   * Join - InternetMail -  an existing connection to the mail server. If not specified, a new one is created.
//   * MailProtocol - String -  if set to "IMAP", then the letter will be sent by IMAP, if
//                              set to "All", then SMTP and IMAP, if none is specified
//                              according to the SMTP Protocol. This parameter only makes sense if there is a valid connection
//                              specified in the Connection parameter. Otherwise, the Protocol will be detected
//                              automatically when the connection is established.
//   * MessageID - String -  (returned parameter) ID of the sent mail message on the SMTP server;
//   * MessageIDIMAPSending - String -  (returned parameter) ID of the sent mail
//                                         message on the IMAP server;
//   * WrongRecipients - Map -  
//                                          
//
//  DeleteConnection - InternetMail -  the parameter is deprecated, see the parameter Dispatch parameters.Connection.
//  DeleteMailProtocol - String     -  the parameter is deprecated, see the parameter Dispatch parameters.The protocol of the post office.
//
// Returns:
//  String - 
//
Function SendEmailMessage(Val Account, Val SendOptions,
	Val DeleteConnection = Undefined, DeleteMailProtocol = "") Export
	
	If DeleteConnection <> Undefined Then
		SendOptions.Insert("Join", DeleteConnection);
	EndIf;
	
	If Not IsBlankString(DeleteMailProtocol) Then
		SendOptions.Insert("MailProtocol", DeleteMailProtocol);
	EndIf;
	
	If TypeOf(Account) <> Type("CatalogRef.EmailAccounts")
		Or Not ValueIsFilled(Account) Then
		Raise NStr("en = 'The account is not specified or specified incorrectly.';");
	EndIf;
	
	If SendOptions = Undefined Then
		Raise NStr("en = 'The mail sending parameters are not specified.';");
	EndIf;
	
	RecipientValType = ?(SendOptions.Property("Whom"), TypeOf(SendOptions.Whom), Undefined);
	CcType = ?(SendOptions.Property("Cc"), TypeOf(SendOptions.Cc), Undefined);
	BCCs = CommonClientServer.StructureProperty(SendOptions, "BCCs");
	
	If RecipientValType = Undefined And CcType = Undefined And BCCs = Undefined Then
		Raise NStr("en = 'No recipient is selected.';");
	EndIf;
	
	If RecipientValType = Type("String") Then
		SendOptions.Whom = CommonClientServer.ParseStringWithEmailAddresses(SendOptions.Whom);
	ElsIf RecipientValType <> Type("Array") Then
		SendOptions.Insert("Whom", New Array);
	EndIf;
	
	If CcType = Type("String") Then
		SendOptions.Cc = CommonClientServer.ParseStringWithEmailAddresses(SendOptions.Cc);
	ElsIf CcType <> Type("Array") Then
		SendOptions.Insert("Cc", New Array);
	EndIf;
	
	If TypeOf(BCCs) = Type("String") Then
		SendOptions.BCCs = CommonClientServer.ParseStringWithEmailAddresses(BCCs);
	ElsIf TypeOf(BCCs) <> Type("Array") Then
		SendOptions.Insert("BCCs", New Array);
	EndIf;
	
	If SendOptions.Property("ReplyToAddress") And TypeOf(SendOptions.ReplyToAddress) = Type("String") Then
		SendOptions.ReplyToAddress = CommonClientServer.ParseStringWithEmailAddresses(SendOptions.ReplyToAddress);
	EndIf;
	
	EmailOperationsInternal.SendMessage(Account, SendOptions);
	EmailOperationsOverridable.AfterEmailSending(SendOptions);
	
	If SendOptions.WrongRecipients.Count() > 0 Then
		ErrorText = NStr("en = 'The following email addresses were declined by mail server:';");
		For Each WrongRecipient In SendOptions.WrongRecipients Do
			ErrorText = ErrorText + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString("%1: %2",
				WrongRecipient.Key, WrongRecipient.Value);
		EndDo;
		Raise ErrorText;
	EndIf;
	
	Return SendOptions.MessageID;
	
EndFunction

#EndRegion

#EndRegion
