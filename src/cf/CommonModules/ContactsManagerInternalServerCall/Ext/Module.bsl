///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// 
//
//  Parameters:
//      Text        - String -  submission of contact information
//      Expected Type-Reference Link.Types of contactinformation
//                   - EnumRef.ContactInformationTypes - 
//                     
//      Comment  - String - 
//
//  Returns:
//      String - JSON
//
Function ContactsByPresentation(Val Text, Val ExpectedKind, Val Comment) Export
	
	ContactInformation = ContactsManagerInternal.ContactsByPresentation(Text, ExpectedKind);
	ContactInformation.comment = Comment;
	Return ContactsManagerInternal.ToJSONStringStructure(ContactInformation);
		
EndFunction

// Returns a string consisting of the values of contact information.
//
//  Parameters:
//      XMLData - String -  XML data for contact information.
//
//  Returns:
//      String - 
//      
//
Function ContactInformationCompositionString(Val XMLData) Export;
	
	If ContactsManagerInternalCached.IsLocalizationModuleAvailable() Then
		ModuleContactsManagerLocalization = Common.CommonModule("ContactsManagerLocalization");
		Return ModuleContactsManagerLocalization.ContactInformationCompositionString(XMLData);
	EndIf;
	
	Return "";
	
EndFunction

// Parameters:
//  Data - See ContactsManagerClientServer.ContactInformationDetails
// 
// Returns:
//  Structure:
//    * XMLData1 - String 
//    * ContactInformationType - EnumRef.ContactInformationTypes
//                              - Undefined
//
Function TransformContactInformationXML(Val Data) Export
	
	Result = ContactsManager.ContactInfoFieldsToConvert();
	
	If ContactsManagerInternalCached.IsLocalizationModuleAvailable() Then
		ModuleContactsManagerLocalization = Common.CommonModule("ContactsManagerLocalization");
		Return ModuleContactsManagerLocalization.TransformContactInformationXML(Data);
	EndIf;
	
	If ContactsManagerClientServer.IsJSONContactInformation(Data.FieldValues) Then
		ContactInformationFields = ContactsManager.ContactInformationBasicInfo(Data.FieldValues);
		FillPropertyValues(Result, ContactInformationFields);
	Else
		Result.Presentation           = Data.Presentation;
		Result.ContactInformationType = Data.ContactInformationKind;
	EndIf;
	
	Return Result;

	
EndFunction

// Returns a found link or creates a new country in the world and returns a link to it.
// 
// Parameters:
//  CountryCode - String 
// 
// Returns:
//   See ContactsManager.WorldCountryByCodeOrDescription
//
Function WorldCountryByClassifierData(Val CountryCode) Export
	
	Return ContactsManager.WorldCountryByCodeOrDescription(CountryCode);
	
EndFunction

// Populates the collection with links to countries found or created in the world.
//
Procedure WorldCountriesCollectionByClassifierData(Collection) Export
	
	For Each KeyValue In Collection Do
		Collection[KeyValue.Key] =  ContactsManager.WorldCountryByCodeOrDescription(KeyValue.Value.Code);
	EndDo;
	
EndProcedure

// Fills in the list of address options for auto-selection based on the text entered by the user.
//
Procedure AutoCompleteAddress(Val Text, ChoiceData) Export
	
	ContactsManagerInternal.AutoCompleteAddress(Text, ChoiceData);
	
EndProcedure

#EndRegion
