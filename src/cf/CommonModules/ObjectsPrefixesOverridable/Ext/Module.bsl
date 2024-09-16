///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Event handler for changing the object number.
// The handler is designed to calculate the base number of an object
// when the standard way to get the base number without losing information is impossible.
// The handler is called only if the processed object numbers and codes
// were formed in a non-standard way, not in the format of BSP numbers and codes.
//
// Parameters:
//  Object - DocumentObject
//         - BusinessProcessObject
//         - TaskObject - 
//           
//  Number - String -  number of the current object to extract the base number from.
//  BasicNumber - String -  base number of the object. 
//           The base object number means the object
//           number minus all prefixes (the is prefix, the company
//           prefix, the division prefix, the user prefix, and so on).
//  StandardProcessing - Boolean -  the flag of standard processing. The default values are True.
//           If this parameter is set to False in the handler,
//           standard processing will not be performed.
//           Standard processing gets the base code from the right to the first non-numeric character.
//           For example, for the code "AA00005/12/368", standard processing returns "368".
//           However, the base code for the object will be "5/12/368".
//
Procedure OnChangeNumber(Object, Val Number, BasicNumber, StandardProcessing) Export
	
	
	
EndProcedure

// The event handler when you change the code of the object.
// The handler is designed to calculate the base code of an object
// when the standard way to get the base code without losing information is impossible.
// The handler is called only if the processed object numbers and codes
// were formed in a non-standard way, not in the format of BSP numbers and codes.
//
// Parameters:
//  Object - CatalogObject
//         - ChartOfCharacteristicTypesObject - 
//           
//  Code - String -  code of the current object to extract the base code from.
//  BasicCode - String -  base code of the object. The basic object code means the object
//           code minus all prefixes (the is prefix, the company
//           prefix, the division prefix, the user prefix, and so on).
//  StandardProcessing - Boolean -  the flag of standard processing. The default values are True.
//           If this parameter is set to False in the handler,
//           standard processing will not be performed.
//           Standard processing gets the base code from the right to the first non-numeric character.
//           For example, for the code "AA00005/12/368", standard processing returns "368".
//           However, the base code for the object will be "5/12/368".
//
Procedure OnChangeCode(Object, Val Code, BasicCode, StandardProcessing) Export
	
EndProcedure

// In the procedure, you need to fill in the "Objects" parameter for those metadata objects
// for which the link to the company is located in the details with a name other than the standard name "Company".
//
// Parameters:
//  Objects - ValueTable:
//     * Object - MetadataObject -  a metadata object for which you specify a detail
//                that contains a link to the company.
//     * Attribute - String -  name of the account that contains the link to the company.
//
Procedure GetPrefixGeneratingAttributes(Objects) Export
	
	
	
EndProcedure

#EndRegion
