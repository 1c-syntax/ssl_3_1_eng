///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Function ListPresentation(Collection, ColumnName = "", MaxChars = 60) Export
	Result = New Structure;
	Result.Insert("Total", 0);
	Result.Insert("LengthOfFull", 0);
	Result.Insert("LengthOfShort", 0);
	Result.Insert("Short", "");
	Result.Insert("Full", "");
	Result.Insert("MaximumExceeded", False);
	For Each Object In Collection Do
		ValuePresentation = String(?(ColumnName = "", Object, Object[ColumnName]));
		If IsBlankString(ValuePresentation) Then
			Continue;
		EndIf;
		If Result.Total = 0 Then
			Result.Total        = 1;
			Result.Full       = ValuePresentation;
			Result.LengthOfFull = StrLen(ValuePresentation);
		Else
			Full       = Result.Full + ", " + ValuePresentation;
			LengthOfFull = Result.LengthOfFull + 2 + StrLen(ValuePresentation);
			If Not Result.MaximumExceeded And LengthOfFull > MaxChars Then
				Result.Short          = Result.Full;
				Result.LengthOfShort    = Result.LengthOfFull;
				Result.MaximumExceeded = True;
			EndIf;
			Result.Total        = Result.Total + 1;
			Result.Full       = Full;
			Result.LengthOfFull = LengthOfFull;
		EndIf;
	EndDo;
	If Result.Total > 0 And Not Result.MaximumExceeded Then
		Result.Short       = Result.Full;
		Result.LengthOfShort = Result.LengthOfFull;
		Result.MaximumExceeded = Result.LengthOfFull > MaxChars;
	EndIf;
	Return Result;
EndFunction

// Returns the template of the default theme for e-mail delivery.
Function SubjectTemplate(AllParametersOfFilesAndEmailText = Undefined) Export
	If AllParametersOfFilesAndEmailText <> Undefined Then 
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1 dated %2';"), "[" + AllParametersOfFilesAndEmailText.MailingDescription + "]",
			"[" + AllParametersOfFilesAndEmailText.ExecutionDate + "(DLF='D')]");
	Else
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1 dated %2';"), "[MailingDescription]", "[ExecutionDate(DLF='D')]");
	EndIf;
EndFunction

// Returns the default archive name template.
Function ArchivePatternName(AllParametersOfFilesAndEmailText = Undefined) Export
	If AllParametersOfFilesAndEmailText <> Undefined Then
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1 dated %2';"), "[" + AllParametersOfFilesAndEmailText.MailingDescription + "]",
			"[" + AllParametersOfFilesAndEmailText.ExecutionDate + "(DF='yyyy-MM-dd')]");
	Else
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1 dated %2';"), "[MailingDescription]", "[ExecutionDate(DF='yyyy-MM-dd')]");
	EndIf;
EndFunction

// Constructor for the value of the delivery parametersthe function perform dispatch.
//
// Returns:
//   Structure - 
//     :
//       * Author - CatalogRef.Users -  author of the mailing list.
//       * UseFolder            - Boolean -  to deliver the reports in a folder of the subsystem "Working with files".
//       * UseNetworkDirectory   - Boolean -  deliver reports to a file system folder.
//       * UseFTPResource        - Boolean -  to deliver reports via FTP.
//       * UseEmail - Boolean - 
//
//     :
//       * Folder - CatalogRef.FilesFolders - 
//
//     :
//       * NetworkDirectoryWindows - String -  directory of the file system (local on the server or network).
//       * NetworkDirectoryLinux   - String - 
//
//     :
//       * Owner            - CatalogRef.ReportMailings
//       * Server              - String -  name of the FTP server.
//       * Port                - Number  -  port of the FTP server.
//       * Login               - String -  name of the FTP server user.
//       * Password              - String -  password of the FTP server user.
//       * Directory             - String -  path to the folder on the FTP server.
//       * PassiveConnection - Boolean - 
//
//     :
//       * Account - CatalogRef.EmailAccounts -  to send a mail message.
//       * Recipients - Map of KeyAndValue - :
//           ** Key - CatalogRef -  recipient.
//           ** Value - String - 
//
//     :
//       * Archive - Boolean -  archive all generated report files into a single archive.
//                                 Archiving may be required, for example, when sending charts in html format.
//       * ArchiveName    - String -  archive name.
//       * ArchivePassword - String -  backup password.
//       * TransliterateFileNames - Boolean - 
//       * CertificateToEncrypt - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - 
//           
//       * MailingRecipientType - TypeDescription
//                                - Undefined
//
//     :
//       * Personalized - Boolean -  the mailing list is personalized by the recipients.
//           The default value is False.
//           If you set the value to True, each recipient will receive a report with a selection based on it.
//           To do this, you should set the selection in the reports "[Recipient] " according to the details that match the type of recipient.
//           Applicable only for mail delivery only,
//           so when set to True, other delivery methods are disabled.
//       * NotifyOnly - Boolean -  False - send only notifications (do not attach generated reports).
//       * BCCs    - Boolean -  False - if True, then when sending it, instead of "To", "hidden copies" are filled in.
//       * SubjectTemplate      - String -              message subject.
//       * TextTemplate1    - String -              message body.
//       * FormatsParameters - Map of KeyAndValue:
//           ** Key - EnumRef.ReportSaveFormats
//           ** Value - Structure:
//                *** Extension - String
//                *** FileType - SpreadsheetDocumentFileType
//                *** Name - String
//       * EmailParameters - See EmailSendOptions
//       * ShouldInsertReportsIntoEmailBody - Boolean
//       * ShouldAttachReports - Boolean
//       * ShouldSetPasswordsAndEncrypt - Boolean
//       * ReportsForEmailText - Array of Map
//
Function DeliveryParameters() Export
	
	DeliveryParameters = New Structure;
	DeliveryParameters.Insert("ExecutionDate", Undefined);
	DeliveryParameters.Insert("Join", Undefined);
	DeliveryParameters.Insert("StartCommitted", False);
	DeliveryParameters.Insert("Author", Undefined);
	DeliveryParameters.Insert("EmailParameters", EmailSendOptions());
	
	DeliveryParameters.Insert("RecipientsSettings", New Map);
	DeliveryParameters.Insert("Recipients", Undefined);
	DeliveryParameters.Insert("Account", Undefined);
	DeliveryParameters.Insert("BulkEmail", "");
	
	DeliveryParameters.Insert("HTMLFormatEmail", False);
	DeliveryParameters.Insert("Personalized", False);
	DeliveryParameters.Insert("TransliterateFileNames", False);
	DeliveryParameters.Insert("NotifyOnly", False);
	DeliveryParameters.Insert("BCCs", False);
	
	DeliveryParameters.Insert("UseEmail", False);
	DeliveryParameters.Insert("UseFolder", False);
	DeliveryParameters.Insert("UseNetworkDirectory", False);
	DeliveryParameters.Insert("UseFTPResource", False);
	
	DeliveryParameters.Insert("Directory", Undefined);
	DeliveryParameters.Insert("NetworkDirectoryWindows", Undefined);
	DeliveryParameters.Insert("NetworkDirectoryLinux", Undefined);
	DeliveryParameters.Insert("TempFilesDir", "");
	
	DeliveryParameters.Insert("Owner", Undefined);
	DeliveryParameters.Insert("Server", Undefined);
	DeliveryParameters.Insert("Port", Undefined);
	DeliveryParameters.Insert("PassiveConnection", False);
	DeliveryParameters.Insert("Login", Undefined);
	DeliveryParameters.Insert("Password", Undefined);
	
	DeliveryParameters.Insert("Folder", Undefined);
	DeliveryParameters.Insert("Archive", False);
	DeliveryParameters.Insert("ArchiveName", ArchivePatternName());
	DeliveryParameters.Insert("ArchivePassword", Undefined);
	DeliveryParameters.Insert("CertificateToEncrypt", Undefined);
		
	DeliveryParameters.Insert("FillRecipientInSubjectTemplate", False);
	DeliveryParameters.Insert("FillRecipientInMessageTemplate", False);
	DeliveryParameters.Insert("FillGeneratedReportsInMessageTemplate", False);
	DeliveryParameters.Insert("FillDeliveryMethodInMessageTemplate", False);
	DeliveryParameters.Insert("RecipientReportsPresentation", "");
	DeliveryParameters.Insert("SubjectTemplate", SubjectTemplate());
	DeliveryParameters.Insert("TextTemplate1", "");
	
	DeliveryParameters.Insert("FormatsParameters", New Map);
	DeliveryParameters.Insert("TransliterateFileNames", False);
	DeliveryParameters.Insert("GeneralReportsRow", Undefined);
	DeliveryParameters.Insert("AddReferences", "");
	
	DeliveryParameters.Insert("TestMode", False);
	DeliveryParameters.Insert("HadErrors", False);
	DeliveryParameters.Insert("HasWarnings", False);
	DeliveryParameters.Insert("ExecutedToFolder", False);
	DeliveryParameters.Insert("ExecutedToNetworkDirectory", False);
	DeliveryParameters.Insert("ExecutedAtFTP", False);
	DeliveryParameters.Insert("ExecutedByEmail", False);
	DeliveryParameters.Insert("ExecutedPublicationMethods", "");
	DeliveryParameters.Insert("Recipient", Undefined);
	DeliveryParameters.Insert("Images", New Structure);
	DeliveryParameters.Insert("Personal", False);
	DeliveryParameters.Insert("MailingRecipientType", Undefined);
	DeliveryParameters.Insert("ShouldInsertReportsIntoEmailBody", True);
	DeliveryParameters.Insert("ShouldAttachReports", False);
	DeliveryParameters.Insert("ShouldSetPasswordsAndEncrypt", False);
	DeliveryParameters.Insert("ReportsForEmailText", New Map);
	DeliveryParameters.Insert("ReportsTree", Undefined);
	
	Return DeliveryParameters;
	
EndFunction

// 
//
// Returns:
//   Structure - :
//     * Whom - Array
//            - String - 
//            - Array - :
//                * Address         - String -  postal address (must be filled in).
//                * Presentation - String -  destination name.
//            - String - 
//
//     * MessageRecipients - Array - :
//       ** Address - String -  email address of the message recipient.
//       ** Presentation - String -  representation of the addressee.
//
//     * Cc        - Array
//                    - String - 
//
//     * BCCs - Array
//                    - String - 
//
//     * Subject       - String -  (required) subject of the email message.
//     * Body       - String -  (required) text of the email message (plain text in win-1251 encoding).
//
//     * Attachments - Array - :
//       ** Presentation - String -  attachment file name;
//       ** AddressInTempStorage - String -  address of the attachment's binary data in temporary storage.
//       ** Encoding - String -  encoding of the attachment (used if it differs from the encoding of the message).
//       ** Id - String -  (optional) used to mark images displayed in the message body.
//
//     * ReplyToAddress - String - 
//     * BasisIDs - String -  IDs of the bases of this message.
//     * ProcessTexts  - Boolean -  the need to process the message texts when sending.
//     * RequestDeliveryReceipt  - Boolean -  need to request a delivery notification.
//     * RequestReadReceipt - Boolean -  need to request a read notification.
//     * TextType - String
//                 - EnumRef.EmailTextTypes
//                 - InternetMailTextType - 
//                   :
//                   
//                   
//                                                 
//                   
//                                                 
//     * Importance  - InternetMailMessageImportance
//
Function EmailSendOptions() Export
	
	EmailParameters = New Structure;
	EmailParameters.Insert("Whom", New Array);
	EmailParameters.Insert("MessageRecipients", New Array);
	EmailParameters.Insert("Cc", New Array);
	EmailParameters.Insert("BCCs", New Array);
	EmailParameters.Insert("Subject", "");
	EmailParameters.Insert("Body", "");
	EmailParameters.Insert("Attachments", New Map);
	EmailParameters.Insert("ReplyToAddress", "");
	EmailParameters.Insert("BasisIDs", "");
	EmailParameters.Insert("ProcessTexts", False);
	EmailParameters.Insert("RequestDeliveryReceipt", False);
	EmailParameters.Insert("RequestReadReceipt", False);
	EmailParameters.Insert("TextType", "PlainText");
	EmailParameters.Insert("Importance", "");
	
	Return EmailParameters;
	
EndFunction

// 
//
// Returns:
//   Structure - :
//     * Ref - CatalogRef.ReportMailings
//     * Author - CatalogRef.Users
//     * RecipientsEmailAddressKind - CatalogRef.ContactInformationKinds
//     * Personal - Boolean
//     * Recipients - CatalogTabularSection.ReportMailings.Recipients
//                    - ValueTable:
//                      ** Recipient - DefinedType.BulkEmailRecipient
//                      ** Excluded - Boolean
//     * MailingRecipientType - CatalogRef.MetadataObjectIDs
//                              - CatalogRef.ExtensionObjectIDs
//
Function RecipientsParameters() Export
	
	RecipientsParameters = New Structure;
	RecipientsParameters.Insert("Ref", PredefinedValue("Catalog.ReportMailings.EmptyRef"));
	RecipientsParameters.Insert("Author", PredefinedValue("Catalog.Users.EmptyRef"));
	RecipientsParameters.Insert("RecipientsEmailAddressKind", PredefinedValue("Catalog.ContactInformationKinds.EmptyRef"));
	RecipientsParameters.Insert("Personal", False);
	RecipientsParameters.Insert("Recipients", Undefined);
	RecipientsParameters.Insert("MailingRecipientType", Undefined);
	
	Return RecipientsParameters;
	
EndFunction

#EndRegion