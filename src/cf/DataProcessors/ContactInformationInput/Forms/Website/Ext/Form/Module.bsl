﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ContactInformationKind = Parameters.ContactInformationKind;
	If Not ValueIsFilled(ContactInformationKind) Then
		Raise NStr("en = 'Cannot execute command for the object. Contact information is invalid.';");
	EndIf;
	ContactInformationType = Enums.ContactInformationTypes.WebPage;
	
	Title = ?(IsBlankString(Parameters.Title), String(ContactInformationKind), Parameters.Title);
	
	FieldValues = DefineAddressValue(Parameters);
	
	If IsBlankString(FieldValues) Then
		Data = ContactsManager.NewContactInformationDetails(ContactInformationType);
	ElsIf ContactsManagerClientServer.IsJSONContactInformation(FieldValues) Then
		Data = ContactsManagerInternal.JSONToContactInformationByFields(FieldValues, Enums.ContactInformationTypes.WebPage);
	Else
		
		If ContactsManagerInternalCached.IsLocalizationModuleAvailable() 
			And ContactsManagerClientServer.IsXMLContactInformation(FieldValues) Then
				
				ModuleContactsManagerLocalization = Common.CommonModule("ContactsManagerLocalization");
				ReadResults = New Structure;
				ContactInformation = ModuleContactsManagerLocalization.ContactsFromXML(FieldValues, ContactInformationType, ReadResults);
				If ReadResults.Property("ErrorText") Then
					// 
					ContactInformation.Presentation = Parameters.Presentation;
				EndIf;
				
				Data = ContactsManagerInternal.ContactInformationToJSONStructure(ContactInformation, ContactInformationType);
				
		Else
			Data = ContactsManager.NewContactInformationDetails(ContactInformationType);
			Data.value = FieldValues;
			Data.comment = Parameters.Comment;
		EndIf;
		
	EndIf;
	
	Address        = Data.value;
	Description = TrimAll(Parameters.Presentation);
	Comment  = Data.comment;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Close(SelectionResult(Address, Description, Comment));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function DefineAddressValue(Var_Parameters)
	
	If ValueIsFilled(Var_Parameters.Value) Then
		FieldValues = Var_Parameters.Value;
	Else
		FieldValues = Var_Parameters.FieldValues;
	EndIf;
	
	Return FieldValues;
	
EndFunction

&AtServerNoContext
Function SelectionResult(Address, Description, Comment)
	
	ContactInformationType = Enums.ContactInformationTypes.WebPage;
	WebsiteDescription = ?(ValueIsFilled(Description), Description, Address);
	
	ContactInformation         = ContactsManagerClientServer.NewContactInformationDetails(ContactInformationType );
	ContactInformation.value   = TrimAll(Address);
	ContactInformation.name    = TrimAll(WebsiteDescription);
	ContactInformation.comment = TrimAll(Comment);
	
	ChoiceData = ContactsManagerInternal.ToJSONStringStructure(ContactInformation);
	
	Result = New Structure();
	Result.Insert("Type",                  ContactInformationType);
	Result.Insert("Address",                Address);
	Result.Insert("ContactInformation", ContactsManager.ContactInformationToXML(ChoiceData, Description, ContactInformationType));
	Result.Insert("Value",             ChoiceData);
	Result.Insert("Presentation",        WebsiteDescription);
	Result.Insert("Comment",          ContactInformation.comment);
	
	Return Result
	
EndFunction

#EndRegion