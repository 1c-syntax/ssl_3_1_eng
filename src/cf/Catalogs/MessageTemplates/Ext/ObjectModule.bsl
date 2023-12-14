///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	If FillingData <> Undefined Then
		
		If Common.SubsystemExists("StandardSubsystems.Interactions")
			And TypeOf(FillingData) = Type("DocumentRef.OutgoingEmail") Then
				FillOnBasisOutgoingEmail(FillingData, FillingText, StandardProcessing);
		ElsIf TypeOf(FillingData) = Type("Structure") Then 
				FillBasedOnStructure(FillingData, FillingText, StandardProcessing);
		EndIf;
		
	EndIf;
EndProcedure

#EndRegion

#Region Private

Procedure FillOnBasisOutgoingEmail(FillingData, FillingText, StandardProcessing)
	
	TemplateAttributes = New Array;
	TemplateAttributes.Add("Subject");
	TemplateAttributes.Add("HTMLText");
	TemplateAttributes.Add("Text");
	TemplateAttributes.Add("TextType");
	
	TemplateInformation = Common.ObjectAttributesValues(FillingData, TemplateAttributes);
	
	EmailSubject                             = TemplateInformation.Subject;
	HTMLEmailTemplateText                 = TemplateInformation.HTMLText;
	MessageTemplateText                     = TemplateInformation.Text;
	EmailSubject                             = TemplateInformation.Subject;
	Description                           = TemplateInformation.Subject;
	ForEmails        = True;
	ForSMSMessages                     = False;
	InputOnBasisParameterTypeFullName = NStr("en = 'Common';");
	EmailTextType = Enums.EmailEditingMethods.NormalText;
	
	If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperationsInternal = Common.CommonModule("EmailOperationsInternal");
		HTMLEmailsTextTypes = ModuleEmailOperationsInternal.EmailTextsType("HTML");
		HTMLEmailsWithPicturesTextsTypes = ModuleEmailOperationsInternal.EmailTextsType("HTMLWithPictures");
		
		If TemplateInformation.TextType = HTMLEmailsTextTypes
			Or TemplateInformation.TextType = HTMLEmailsWithPicturesTextsTypes Then
			EmailTextType = Enums.EmailEditingMethods.HTML;
		EndIf;
	
	EndIf;
	
EndProcedure

Procedure FillBasedOnStructure(FillingData, FillingText, StandardProcessing)
	
	TemplateParameters = MessageTemplates.TemplateParametersDetails();
	CommonClientServer.SupplementStructure(TemplateParameters, FillingData, True);
	
	FillPropertyValues(ThisObject, TemplateParameters);
	AttachmentFormat = New ValueStorage(TemplateParameters.AttachmentsFormats);
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("ForSMSMessages")
		And FillingData.ForSMSMessages Then
			TemplateParameters.TemplateType = "SMS";
	EndIf;
	
	If ValueIsFilled(TemplateParameters.ExternalDataProcessor) Then
		TemplateByExternalDataProcessor = True;
	EndIf;
	
	If ValueIsFilled(TemplateParameters.FullAssignmentTypeName) Then
		ObjectMetadata = Common.MetadataObjectByFullName(TemplateParameters.FullAssignmentTypeName);
		InputOnBasisParameterTypeFullName = TemplateParameters.FullAssignmentTypeName;
		Purpose= ObjectMetadata.Presentation();
		ForInputOnBasis = True;
	EndIf;
	
	If TemplateParameters.TemplateType = "MailMessage" Then
		
		ForSMSMessages              = False;
		ForEmails = True;
		EmailSubject                      = TemplateParameters.Subject;
		
		If TemplateParameters.EmailFormat1 = Enums.EmailEditingMethods.HTML Then
			HTMLEmailTemplateText = StrReplace(TemplateParameters.Text, Chars.LF, "<BR>");
			EmailTextType        = Enums.EmailEditingMethods.HTML;
		Else
			MessageTemplateText = StrReplace(TemplateParameters.Text, "<BR>", Chars.LF);
			EmailTextType    = Enums.EmailEditingMethods.NormalText;
		EndIf;
		
	ElsIf TemplateParameters.TemplateType = "SMS" Then
		
		ForSMSMessages              = True;
		ForEmails = False;
		SMSTemplateText                 = TemplateParameters.Text;
		SendInTransliteration            = TemplateParameters.Transliterate;
		
	ElsIf TemplateParameters.TemplateType = "Shared" Then
		
		ForSMSMessages              = False;
		ForEmails = False;
		
	EndIf;
	
	If TypeOf(TemplateParameters.PrintCommands) = Type("Array") Then
		
		For Each PrintCommand In TemplateParameters.PrintCommands Do
			String = PrintFormsAndAttachments.Add();
			String.Id = PrintCommand;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf