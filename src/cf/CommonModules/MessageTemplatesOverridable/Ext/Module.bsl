///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Defines the composition of assignments and General details in message templates 
//
// Parameters:
//  Settings - Structure:
//    * TemplatesSubjects - ValueTable - :
//         ** Name           - String -  unique name of the destination.
//         ** Presentation - String -  representation of the option.
//         ** Template         - String -  name of the SKD layout, if the details are defined using the SKD.
//         ** DCSParametersValues - Structure -  values of SCD parameters for the current subject of the message template.
//    * CommonAttributes - ValueTree - :
//         ** Name            - String -  the unique name of the shared prop.
//         ** Presentation  - String -  representation of general props.
//         ** Type            - Type    -  the types of common props. By default, a string.
//    * UseArbitraryParameters  - Boolean -  specifies whether custom
//                                                    parameters can be used in message templates.
//    * DCSParametersValues - Structure -  General values of the SCD parameters for all layouts where the composition of the details
//                                          is determined by the SCD tools.
//    * ExtendedRecipientsList - Boolean - 
//                                              
//
Procedure OnDefineSettings(Settings) Export
	
	
	
EndProcedure

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes - ValueTreeRowCollection - :
//    * Name            - String -  unique name of the prop.
//    * Presentation  - String - 
//    * FullPresentation - String - 
//    * Type            - Type    - 
//    * ToolTip      - String -  extended information about the bank details.
//    * ArbitraryParameter - Boolean - 
//    * Format         - String -  format for output values for numbers, dates, strings, and Boolean values. 
//                                For example, "DLF=D" for a date.
//    * Parent - ValueTreeRow, Undefined - 
//  Attachments - ValueTable - :
//    * Name            - String -  the unique name of the attachment.
//    * Id  - String -  id of the attachment.
//    * Presentation  - String -  representation of the option.
//    * ToolTip      - String -  extended information about the attachment.
//    * FileType       - String -  the attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl", etc.
//    * ParameterName   - String -  the service parameter. Not intended for use.
//    * Attribute       - String -  the service parameter. Not intended for use.
//    * Status         - String -  the service parameter. Not intended for use.
//    * PrintManager - String -  the service parameter. Not intended for use.
//    * PrintParameters - Structure -  the service parameter. Not intended for use.
//  TemplateAssignment  - String  -  the purpose of the message template, for example, "Notification of a client or order change".
//  AdditionalParameters - See MessageTemplates.TemplateParametersDetails
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, TemplateAssignment, AdditionalParameters) Export
	
	

EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure:
//    * AttributesValues - Map of KeyAndValue - :
//      ** Key     - String -  name of the prop in the template;
//      ** Value - String -  the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - :
//      ** Key     - String -  name of the prop in the template;
//      ** Value - String -  the fill value in the template.
//    * Attachments - Map of KeyAndValue:
//      ** Key     - String -  name of the attachment in the template;
//      ** Value - BinaryData
//                  - String - 
//    * AdditionalParameters - Structure:
//       ** MessageKind - String - 
//       ** DCSParametersValues - Structure - 
//       ** SendImmediately - Boolean - 
//       ** MessageParameters - Structure -  
//                               
//       ** Account - CatalogRef.EmailAccounts, Undefined -  
//                         
//       ** ArbitraryParameters - Map - 
//       ** PrintForms - Array - 
//       ** ConvertHTMLForFormattedDocument - Boolean -  
//                                                     
//                                                    
//       ** SettingsForSaving - See PrintManagement.SettingsForSaving.
//  TemplateAssignment - String -    full name of the destination message template.
//  MessageSubject - AnyRef - 
//  TemplateParameters - See MessageTemplates.TemplateParametersDetails
//
Procedure OnCreateMessage(Message, TemplateAssignment, MessageSubject, TemplateParameters) Export
	
	

EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable:
//     * PhoneNumber - String -  phone number where the SMS message will be sent;
//     * Presentation - String -  representation of the recipient of an SMS message;
//     * Contact       - Arbitrary -  the contact that the phone number belongs to.
//  TemplateAssignment - String -  ID of the template destination
//  MessageSubject - AnyRef -  a reference to the object that is the data source.
//                   - Structure  - :
//    * SubjectOf               - AnyRef -  reference to the object that is the data source;
//    * MessageKind - String -  type of generated message: "e-mail" or " SMS Message";
//    * ArbitraryParameters - Map -  filled in list of custom parameters;
//    * SendImmediately - Boolean -  flag for instant sending;
//    * MessageParameters - Structure -  additional message parameters.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, TemplateAssignment, MessageSubject) Export
	
EndProcedure

// Fills in the list of mail recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - :
//     * SendingOption - String - 
//     * Address           - String -  e-mail address of the recipient;
//     * Presentation   - String -  representation of the email recipient;
//     * Contact         - Arbitrary -  the contact that the email address belongs to.
//  TemplateAssignment - String -  ID of the template destination.
//  MessageSubject - AnyRef -  a reference to the object that is the data source.
//                   - Structure  - :
//    * SubjectOf               - AnyRef -  reference to the object that is the data source;
//    * MessageKind - String -  type of generated message: "e-mail" or " SMS Message";
//    * ArbitraryParameters - Map -  filled in list of custom parameters;
//    * SendImmediately - Boolean -  indicates whether the message was sent instantly;
//    * MessageParameters - Structure -  additional message parameters;
//    * ConvertHTMLForFormattedDocument - Boolean -  flag converting the HTML text
//             of a message containing images in the message text due to the features of displaying images
//             in a formatted document;
//    * Account - CatalogRef.EmailAccounts -  account for sending the email.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, TemplateAssignment, MessageSubject) Export
	
	
	
EndProcedure

// 

// See also updating the information base undefined.customizingmachine infillingelements
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
EndProcedure

// See also updating the information base undefined.At firstfillingelements
//
// Parameters:
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	
	
EndProcedure

// See also updating the information base undefined.customizingmachine infillingelements
//
// Parameters:
//  Object                  - CatalogObject.PerformerRoles -  the object to fill in.
//  Data                  - ValueTableRow -  data for filling in the object.
//  AdditionalParameters - Structure:
//   * PredefinedData - ValueTable -  the data filled in in the procedure for the initial filling of the elements.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

#EndRegion

