///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public


// Opens the window for selecting a template for generating an email or SMS message based on the template
// for the item passed in the subject parameter.
//
// Parameters:
//  MessageSubject            - DefinedType.MessageTemplateSubject
//                              - String - 
//                                
//                                
//                                
//  MessageKind                - String -  "Message" for email and "Messagesms" for SMS messages.
//  OnCloseNotifyDescription - NotifyDescription - :
//     * Result - Boolean -  if True, the message was created.
//     * MessageParameters - Structure
//                          - Undefined -  
//  TemplateOwner             - DefinedType.MessageTemplateOwner -  the owner of the templates. If not specified, the
//                                              template selection window displays all available templates for the specified
//                                              subject of the message.
//  MessageParameters          - Structure -    additional information for a message that 
//                                             which is transferred in property of Parametrisable parameter Parametrisable
//                                             procedure SaloneSatellite.When forming a message. 
//
Procedure GenerateMessage(MessageSubject, MessageKind, OnCloseNotifyDescription = Undefined, 
	TemplateOwner = Undefined, MessageParameters = Undefined) Export
	
	FormParameters = MessageFormParameters(MessageSubject, MessageKind, TemplateOwner, MessageParameters);
	ShowGenerateMessageForm(OnCloseNotifyDescription, FormParameters);
	
EndProcedure

// Opens a form for selecting a template.
//
// Parameters:
//  Notification - NotifyDescription - :
//      * Result - CatalogRef.MessageTemplates -  selected template.
//      * AdditionalParameters - Structure -  the value that was specified when creating the message Description object.
//  MessageKind                - String -  "Message" for email and "Messagesms" for SMS messages.
//  TemplateSubject   - AnyRef
//                   - String - 
//  TemplateOwner  - DefinedType.MessageTemplateOwner -  the owner of the templates. If omitted, the template selection window
//                                              displays all available templates for the specified message Subject.
//
Procedure SelectTemplate(Notification, MessageKind = "MailMessage", TemplateSubject = Undefined, TemplateOwner = Undefined) Export
	
	If TemplateSubject = Undefined Then
		TemplateSubject = "Shared";
	EndIf;
	
	FormParameters = MessageFormParameters(TemplateSubject, MessageKind, TemplateOwner, Undefined);
	FormParameters.Insert("ChoiceMode", True);
	
	ShowGenerateMessageForm(Notification, FormParameters);
	
EndProcedure

// Shows the form of the message template.
//
// Parameters:
//  Value - CatalogRef.MessageTemplates
//           - Structure
//           - AnyRef - 
 //                    
 //                    
//                      See MessageTemplatesClientServer.TemplateParametersDetails.
//                     
//                     
//  OpeningParameters - Structure - :
//    * Owner - Arbitrary -  a form or control of another form.
//    * Uniqueness - Arbitrary -  the key whose value will be used to search for already open forms.
//    * URL - String -  sets the navigation link returned by the form.
//    * OnCloseNotifyDescription - NotifyDescription -  contains a description of the procedure that will be called after
//                                                         the form is closed.
//    * WindowOpeningMode - FormWindowOpeningMode -  specifies the mode for opening the managed form window.
//
Procedure ShowTemplateForm(Value, OpeningParameters = Undefined) Export
	
	FormOpenParameters = FormParameters(OpeningParameters);
	
	FormParameters = New Structure;
	If TypeOf(Value) = Type("Structure") Then
		FormParameters.Insert("Basis", Value);
		FormParameters.Insert("TemplateOwner", Value.TemplateOwner);
	ElsIf TypeOf(Value) = Type("CatalogRef.MessageTemplates") Then
		FormParameters.Insert("Key", Value);
	Else
		FormParameters.Insert("TemplateOwner", Value);
		FormParameters.Insert("Key", Value);
	EndIf;

	OpenForm("Catalog.MessageTemplates.ObjectForm", FormParameters, FormOpenParameters.Owner,
		FormOpenParameters.Uniqueness,, FormOpenParameters.URL,
		FormOpenParameters.OnCloseNotifyDescription, FormOpenParameters.WindowOpeningMode);
EndProcedure

// Returns parameters for opening the message template form.
//
// Parameters:
//  FillingData - Arbitrary - 
//                                    :
//                                    
// 
// Returns:
//  Structure - :
//   * Owner - Arbitrary -  a form or control of another form.
//   * Uniqueness - Arbitrary -  the key whose value will be used to search for already open forms.
//   * URL - String -  sets the navigation link returned by the form.
//   * OnCloseNotifyDescription - NotifyDescription -  contains a description of the procedure that will be called after
//                                                       the form is closed.
//   * WindowOpeningMode - FormWindowOpeningMode -  specifies the mode for opening the managed form window.
//
Function FormParameters(FillingData) Export
	OpeningParameters = New Structure();
	OpeningParameters.Insert("Owner", Undefined);
	OpeningParameters.Insert("Uniqueness", Undefined);
	OpeningParameters.Insert("URL", Undefined);
	OpeningParameters.Insert("OnCloseNotifyDescription", Undefined);
	OpeningParameters.Insert("WindowOpeningMode", Undefined);
	
	If FillingData <> Undefined Then
		FillPropertyValues(OpeningParameters, FillingData);
	EndIf;
	
	Return OpeningParameters;
	
EndFunction

#EndRegion

#Region Internal

// Opens the window for selecting a template for generating an email or SMS message for the specified subject
// The subject of the message and returns the generated template.
//
// Parameters:
//  MessageSubject            - AnyRef
//                              - String - 
//                                
//  MessageKind                - String -  "Message" for email and "Messagesms" for SMS messages.
//  OnCloseNotifyDescription - NotifyDescription - :
//     * Result - Structure -  if True, the message was created.
//     * MessageParameters - Structure
//                          - Undefined -  
//  TemplateOwner         - DefinedType.MessageTemplateOwner -  the owner of the templates. If omitted, the
//                            template selection window displays all available templates for the specified message Subject.
//  MessageParameters     - Structure -    additional information for a message that 
//                                        which is transferred in property of Parametrisable parameter Parametrisable
//                                        procedure SaloneSatellite.When forming a message. 
//
Procedure PrepareMessageFromTemplate(MessageSubject, MessageKind, OnCloseNotifyDescription = Undefined, 
	TemplateOwner = Undefined, MessageParameters = Undefined) Export
	
	FormParameters = MessageFormParameters(MessageSubject, MessageKind, TemplateOwner, MessageParameters);
	FormParameters.Insert("PrepareTemplate", True);
	
	ShowGenerateMessageForm(OnCloseNotifyDescription, FormParameters);
	
EndProcedure

Procedure SendMail(Ref, Parameters) Export
	AdditionalParameters = New Structure("MessageSourceFormName", "");
	AdditionalParameters.MessageSourceFormName = Parameters.Form.FormName;
	
	GenerateMessage(Ref, "MailMessage",,, AdditionalParameters);
EndProcedure

Procedure SendSMS(Ref, Parameters) Export
	AdditionalParameters = New Structure("MessageSourceFormName", "");
	AdditionalParameters.MessageSourceFormName = Parameters.Form.FormName;
	
	GenerateMessage(Ref, "SMSMessage",,, AdditionalParameters);
EndProcedure
	
#EndRegion

#Region Private

Function MessageFormParameters(TemplateSubject, MessageKind, TemplateOwner, MessageParameters)
	
	FormParameters = New Structure();
	FormParameters.Insert("SubjectOf",            TemplateSubject);
	FormParameters.Insert("MessageKind",       MessageKind);
	FormParameters.Insert("TemplateOwner",    TemplateOwner);
	FormParameters.Insert("MessageParameters", MessageParameters);
	
	Return FormParameters;
	
EndFunction

Procedure ShowGenerateMessageForm(OnCloseNotifyDescription, FormParameters)
	
	AdditionalParameters = New Structure("Notification", OnCloseNotifyDescription);
	Notification = New NotifyDescription("ExecuteClosingNotification", ThisObject, AdditionalParameters);
	OpenForm("Catalog.MessageTemplates.Form.GenerateMessage", FormParameters, ThisObject,,,, Notification);
	
EndProcedure

Procedure ExecuteClosingNotification(Result, AdditionalParameters) Export
	If Result <> Undefined Then 
		ExecuteNotifyProcessing(AdditionalParameters.Notification, Result);
	EndIf;
EndProcedure

#EndRegion


