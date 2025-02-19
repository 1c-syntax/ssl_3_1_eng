///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// 
// 
// 
// 
// Parameters:
//  TypeCommands - Structure:
//   * Key - String - 
//   * Value - See ContactsManager.CommandProperties
//  Type - EnumRef.ContactInformationTypes - contact information type.
//
Procedure WhenDefiningCommandsOfTypeOfContactInformation(TypeCommands, Type) Export
	
	
EndProcedure

// 
//
// Parameters:
//  ContactInformationInJSON - String - contact information in the internal JSON format.
//  ContactInformationToXML  - String - 
//  ExpectedType              - EnumRef.ContactInformationTypes -  
//                              
//
Procedure WhenConvertingContactInformationFromJSONToXML(Val ContactInformationInJSON, ContactInformationToXML, ExpectedType = Undefined) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  Text - String - 
//  ContactInformation - XDTODataObject -  
//  ExpectedKind - EnumRef.ContactInformationTypes - 
//  ConversionResult - Structure:
//    * InfoCorrected - Boolean -  
//                          - Undefined - 
//  SettingsOfConversion - See ContactsManager.ContactInformationConversionSettings
//
Procedure OnConvertContactInformationFromXML(Val Text, ContactInformation, Val ExpectedKind = Undefined, ConversionResult = Undefined, SettingsOfConversion = Undefined) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  ContactInformation - String - 
//  JSONContactInformation - String -  
//  Type - EnumRef.ContactInformationTypes - 
//  SettingsOfConversion - Structure
//
Procedure OnConvertContactInformationToJSONStructure(ContactInformation, JSONContactInformation, Type, SettingsOfConversion) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  Data - See ContactsManagerClientServer.ContactInformationDetails
//  Result - See ContactsManager.ContactInfoFieldsToConvert 
//  StandardProcessing - Boolean - 
// 
Procedure WhenConvertingContactInformationToXMLN(Val Data, Result, StandardProcessing) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  FieldValues - String - 
//  Result - XDTODataObject - 
//  Presentation - String - 
//  ExpectedType - EnumRef.ContactInformationTypes - 
// 
Procedure OnConvertPhoneToXDTOObject(FieldValues, Result, Presentation = "", ExpectedType = Undefined) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  FieldValues - String - 
//  Result - XDTODataObject - 
//  Presentation - String - 
//  ExpectedType - EnumRef.ContactInformationTypes - 
// 
Procedure OnConvertFaxToXDTOObject(FieldValues, Result, Presentation = "", ExpectedType = Undefined) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  ContactInformation - String - 
//  Comment - String -  
// 
Procedure OnSetContactInformationComment(ContactInformation, Val Comment) Export
	
	
EndProcedure

//  
//
// Parameters:
//  XMLString - String - contact information in XML format.
//  Type - EnumRef.ContactInformationTypes - 
//
Procedure OnDefineContactInformationType(Val XMLString, Type) Export
EndProcedure

// 
// 
// Parameters:
//  Text - String - a contact information presentation.
//  Result - XDTODataObject - 
//  ExpectedKind - EnumRef.ContactInformationTypes - contact information type.
//
Procedure OnConvertXDTOContactInformationByPresentation(Text, Result, ExpectedKind) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  XDTOInformationObject - XDTODataObject - 
//  ContactInformationToXML - String - 
//
Procedure OnConvertXDTOContactInformationToXML(XDTOInformationObject, ContactInformationToXML) Export
	
	
EndProcedure

// 
// 
// Parameters: 
//   XMLData - String - 
//   CompositionRow - String -  
//
Procedure OnGetContactInformationCompositionString(XMLData, CompositionRow) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  Source - XDTODataObject - 
//  Result - String - 
//
Procedure OnFillTabularSectionAttributesForWebPage(Source, Result) Export
	
	
EndProcedure

// Compares two instances of contact information.
//
// Parameters:
//    Data1 - XDTODataObject - object with contact information.
//            - String     - contact information in XML format.
//            - Structure  - contact information details. The expected fields are:
//                 * FieldValues - String
//                                 - Structure
//                                 - ValueList
//                                 - Map - contact information fields.
//                 * Presentation - String - A presentation.
//                                            Used in cases when the "FieldValues" parameter is missing the "Presentation" field.
//                 * Comment - String - a comment. Used when a comment cannot be extracted
//                                          from FieldValues.
//                 * ContactInformationKind - CatalogRef.ContactInformationKinds
//                                           - EnumRef.ContactInformationTypes
//                                           - Structure -
//                                             Used in cases where the type cannot be identified using "FieldsValues".
//    Data2 - XDTODataObject
//            - String
//            - Structure - — see details of the Data1 parameter.
//    Result - ValueTable:
//      * Path      - String - XPath identifying a different value. The "ContactInformationType" value
//                             means that passed contact information sets have different types.
//      * LongDesc  - String - details of a different attribute in terms of the subject field.
//      * Value1 - String - a value matching the object passed in the Data1 parameter.
//      * Value2 - String - a value matching the object passed in Data2 parameter.
//
//
// Returns:
//     ValueTable: - A table of diff fields with the following columns:
//        * Path      - String - XPath identifying a different value. The "ContactInformationType" value
//                               means that passed contact information sets have different types.
//        * LongDesc  - String - details of a different attribute in terms of the subject field.
//        * Value1 - String - a value matching the object passed in the Data1 parameter.
//        * Value2 - String - a value matching the object passed in Data2 parameter.
//
Procedure OnDetermineContactInformationDifferences(Val Data1, Val Data2, Result) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  CountryByClassifier - ValueTableRow:
//    * Code                - String - 
//    * Description       - String - 
//    * DescriptionFull - String - 
//    * CodeAlpha2          - String - 
//    * CodeAlpha3          - String - 
//
Procedure ПриПроверкеСтраныПослеПоискаСтраныПоКлассификатору(CountryByClassifier) Export

	
EndProcedure

#EndRegion

#Region Internal

Procedure AdjustContactInformation(Form, CIRow, ConversionResult) Export
	
	
EndProcedure

#EndRegion

