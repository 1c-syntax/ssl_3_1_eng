﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Describes a template parameter for their use in external data processors.
//
// Parameters:
//  ParametersTable           - ValueTable - a table with parameters.
//  ParameterName                - String - a list of email recipients.
//  TypeDetails                - TypeDescription - a parameter type.
//  IsPredefinedParameter - Boolean - if False, this is an arbitrary parameter, otherwise, a main parameter.
//  ParameterPresentation      - String - a parameter presentation to be displayed.
//
Procedure AddTemplateParameter(ParametersTable, ParameterName, TypeDetails, IsPredefinedParameter, ParameterPresentation = "") Export

	NewRow                             = ParametersTable.Add();
	NewRow.ParameterName                = ParameterName;
	NewRow.TypeDetails                = TypeDetails;
	NewRow.IsPredefinedParameter = IsPredefinedParameter;
	NewRow.ParameterPresentation      = ?(IsBlankString(ParameterPresentation),ParameterName, ParameterPresentation);
	
EndProcedure

// Initializes the message structure that has to be returned by the external data processor from the template.
//
// Returns:
//   Structure - 
//
Function InitializeMessageStructure() Export
	
	MessageStructure = New Structure;
	MessageStructure.Insert("SMSMessageText", "");
	MessageStructure.Insert("EmailSubject", "");
	MessageStructure.Insert("EmailText", "");
	MessageStructure.Insert("AttachmentsStructure", New Structure);
	MessageStructure.Insert("HTMLEmailText", "<HTML></HTML>");
	
	Return MessageStructure;
	
EndFunction

// Initializes the Recipients structure to fill in possible message recipients.
//
// Returns:
//   Structure - 
//
Function InitializeRecipientsStructure() Export
	
	Return New Structure("Recipient", New Array);
	
EndFunction

// Template parameter constructor.
//
// Returns:
//  Structure - 
//   * Subject - String - a subject of templates (for emails).
//   * Text - String - a template text.
//   * SignatureAndSeal - Boolean - indicates whether there is a signature and a seal in print forms.
//   * MessageParameters - Structure - additional message parameters.
//   * Description - String - a message template description.
//   * Ref - Undefined - a reference to catalog item.
//   * TemplateOwner - Undefined - a context template owner.
//   * DCSParameters - Map - a parameter set on receiving data using DCS.
//   * Parameters - Map - template parameters.
//   * Template - String - a DCS template name.
//   * SelectedAttachments - Map - selected print forms and attachments for the template.
//   * AttachmentsFormats - ValueList - a format in which print forms are saved.
//   * ExpandRefAttributes - Boolean - if True, reference attributes have their attributes available.
//   * TemplateByExternalDataProcessor - Boolean - if True, a template is generated by an external data processor.
//   * ExternalDataProcessor - Undefined - an external data processor reference.
//   * Sender - String - a sender email.
//   * Transliterate - Boolean - if True, the names of report files will 
//                                   contain only Latin letters and digits. This ensures compatibility between
//                                   different operating systems. For example, the "Счет на оплату.pdf" 
//                                   file will be saved as "Schet na oplaty.pdf".
//   * PackToArchive - Boolean - indicates that attached print forms are to be archived
//                                upon sending.
//   * EmailFormat1 - EnumRef.EmailEditingMethods - an email text kind: HTML or NormalText.
//   * FullAssignmentTypeName - String - a full name of the metadata object based on which a message is created.
//   * Purpose - String - a message template assignment.
//   * TemplateType - String - the options are Email or SMSMessage.
//
Function TemplateParametersDetails() Export
	Result = New Structure;
	
	Result.Insert("Text",                           "");
	Result.Insert("Subject",                            "");
	Result.Insert("TemplateType",                      "MailMessage");
	Result.Insert("Purpose",                      "");
	Result.Insert("FullAssignmentTypeName",         "");
	Result.Insert("PackToArchive",                 False);
	Result.Insert("TransliterateFileNames",    False);
	Result.Insert("Transliterate",              False);
	Result.Insert("Sender",                     "");
	Result.Insert("ExternalDataProcessor",                Undefined);
	Result.Insert("TemplateByExternalDataProcessor",        False);
	Result.Insert("ExpandRefAttributes", True);
	Result.Insert("AttachmentsFormats",                 New ValueList);
	Result.Insert("SelectedAttachments",               New Map);
	Result.Insert("Template",                           "");
	Result.Insert("Parameters",                       New Map);
	Result.Insert("DCSParameters",                    New Map);
	Result.Insert("TemplateOwner",                 Undefined);
	Result.Insert("Ref",                          Undefined);
	Result.Insert("Attachments",                        New Map);
	Result.Insert("PrintCommands",                   New Array);
	Result.Insert("Description",                    "");
	Result.Insert("MessageParameters",              New Structure);
	Result.Insert("AddAttachedFiles",    False);
	Result.Insert("SignatureAndSeal",                  False);
	Result.Insert("ExtendedRecipientsList",    False);
	Result.Insert("AddAttachedFiles",    False);
	Result.Insert("EmailFormat1",                    PredefinedValue("Enum.EmailEditingMethods.HTML"));
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function EmailTemplateName() Export
	Return "Email";
EndFunction

Function SMSTemplateName() Export
	Return "SMS";
EndFunction

Function CommonID() Export
	Return "Shared";
EndFunction

Function CommonIDPresentation() Export
	Return NStr("en = 'Common';");
EndFunction

// Parameters:
//  Template - CatalogRef.MessageTemplates
//  SubjectOf - AnyRef
//  UUID - UUID
// Returns:
//  Structure:
//    * AdditionalParameters - Structure:
//       ** ConvertHTMLForFormattedDocument - Boolean
//       ** MessageKind - String
//       ** SendImmediately - Boolean
//       ** Account - CatalogRef.EmailAccounts
//       ** PrintForms - Array
//       ** SettingsForSaving - Arbitrary
//       ** ArbitraryParameters - Map
//       ** DCSParametersValues - Structure
//
Function SendOptionsConstructor(Template, SubjectOf, UUID) Export
	
	SendOptions = New Structure();
	SendOptions.Insert("Template", Template);
	SendOptions.Insert("SubjectOf", SubjectOf);
	SendOptions.Insert("UUID", UUID);
	SendOptions.Insert("AdditionalParameters", New Structure);
	SendOptions.AdditionalParameters.Insert("ConvertHTMLForFormattedDocument", False);
	SendOptions.AdditionalParameters.Insert("MessageKind", "");
	SendOptions.AdditionalParameters.Insert("ArbitraryParameters", New Map);
	SendOptions.AdditionalParameters.Insert("SendImmediately", False);
	SendOptions.AdditionalParameters.Insert("MessageParameters", New Structure);
	SendOptions.AdditionalParameters.Insert("Account", Undefined);
	SendOptions.AdditionalParameters.Insert("PrintForms", New Array);
	SendOptions.AdditionalParameters.Insert("SettingsForSaving");
	SendOptions.AdditionalParameters.Insert("DCSParametersValues", New Structure);
	
	Return SendOptions;
	
EndFunction

Function ArbitraryParametersTitle() Export
	Return NStr("en = 'Custom';");
EndFunction

// Handler of the subscription to FormGetProcessing event for overriding file form.
//
// Parameters:
//  Source                 - CatalogManager - the *AttachedFiles catalog manager.
//  FormType                 - String - a standard form name.
//  Parameters                - Structure - form parameters.
//  SelectedForm           - String - a name or metadata object of the form to open.
//  AdditionalInformation - Structure - additional information of the form opening.
//  StandardProcessing     - Boolean - indicates whether standard (system) event processing is executed.
//
Procedure DetermineAttachedFileForm(Source, FormType, Parameters,
				SelectedForm, AdditionalInformation, StandardProcessing) Export
				
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		
		ModuleFilesOperationsInternalServerCall = Common.CommonModule("FilesOperationsInternalServerCall");
		ModuleFilesOperationsInternalServerCall.DetermineAttachedFileForm(Source, FormType, Parameters,
				SelectedForm, AdditionalInformation, StandardProcessing);
		
	EndIf;
		
	#Else
		
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		
		If TypeOf(SelectedForm) = Type("String") Then
			ModuleFilesOperationsInternalServerCall = CommonClient.CommonModule("FilesOperationsInternalServerCall");
			ModuleFilesOperationsInternalServerCall.DetermineAttachedFileForm(Source, FormType, Parameters,
					SelectedForm, AdditionalInformation, StandardProcessing);
		EndIf;
		
	EndIf;
			
	#EndIf
	
EndProcedure

#EndRegion
