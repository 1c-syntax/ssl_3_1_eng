///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Overrides the subsystem settings.
//
// Parameters:
//  Settings - Structure:
//   * CanReceiveEmails - Boolean -  show email receiving settings in accounts.
//                                       Default value: False for basic configuration versions
//                                       , True for other versions.
//   * ShouldUsePOP3Protocol - Boolean - 
//                                         
//
Procedure OnDefineSettings(Settings) Export

EndProcedure

// Allows you to perform additional operations after sending an email message.
//
// Parameters:
//  EmailParameters - Structure - :
//   * Whom      - Array -  (required) Internet address of the email recipient.
//                 Address-string - postal address.
//                 View-string - name of the recipient.
//
//   * MessageRecipients - Array - :
//                            * ContactInformationSource - CatalogRef -  owner of the contact information.
//                            * Address - String -  email address of the message recipient.
//                            * Presentation - String -  representation of the addressee.
//
//   * Cc      - Array - :
//                   * Address         - String -  postal address (must be filled in).
//                   * Presentation - String -  destination name.
//                  
//                - String - 
//
//   * BCCs - Array
//                  - String - see the description of the Copy field.
//
//   * Subject       - String -  (required) subject of the email message.
//   * Body       - String -  (required) text of the email message (plain text in win-1251 encoding).
//   * Importance   - InternetMailMessageImportance
//   * Attachments   - Map of KeyAndValue:
//                   * Key     - String -  the name of the attachment
//                   * Value - BinaryData
//                              - String - 
//                              - Structure:
//                                 * BinaryData - BinaryData -  binary attachment data.
//                                 * Id  - String -  attachment ID, used for storing images
//                                                             displayed in the message body.
//
//   * ReplyToAddress - Map - see the description of the To field.
//   * Password      - String - 
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
Procedure AfterEmailSending(EmailParameters) Export
	
	
	
EndProcedure

// 
// 
//
//   Parameters:
//  EmailMessagesIDs - ValueTable:
//   * Sender - CatalogRef.EmailAccounts
//   * EmailID - String
//   * RecipientAddress - String - 
//
Procedure BeforeGetEmailMessagesStatuses(EmailMessagesIDs) Export
	
EndProcedure

// 
// 
//
// Parameters:
//  DeliveryStatuses - ValueTable:
//   * Sender - CatalogRef.EmailAccounts
//   * EmailID - String 
//   * RecipientAddress - String - 
//   * Status - EnumRef.EmailMessagesStatuses 
//   * StatusChangeDate - Date
//   * Cause - String - 
//
Procedure AfterGetEmailMessagesStatuses(DeliveryStatuses) Export
	
EndProcedure

#EndRegion
