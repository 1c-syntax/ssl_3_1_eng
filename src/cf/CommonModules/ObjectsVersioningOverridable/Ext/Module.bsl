///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Call to obtain a versioned table documents during the recording of the version of the object.
// A table document is attached to the object version if the report on the object version requires
// replacing the "technogenic" table part of the object with its representation as a table document.
//
// Parameters:
//  Ref             - AnyRef -  versioned configuration object.
//  SpreadsheetDocuments - Structure:
//   * Key     - String    - 
//   * Value - Structure:
//    ** Description - String            -  name of the table document;
//    ** Data       - SpreadsheetDocument -  versioned table document.
//
Procedure OnReceiveObjectSpreadsheetDocuments(Ref, SpreadsheetDocuments) Export
	
EndProcedure

// Called after parsing the object version read from the register
//  . it can be used for additional processing of the version parsing result.
// 
// Parameters:
//  Ref    - AnyRef -  versioned configuration object.
//  Result - Structure -  the result of the evaluation version of subsystem versioning.
//
Procedure AfterParsingObjectVersion(Ref, Result) Export
	
EndProcedure

// Called after defining the object's details from the form 
// Data register.Versions of objects.Webrequestevent.
// 
// Parameters:
//  Ref           - AnyRef       -  versioned configuration object.
//  AttributeTree - FormDataTree -  tree of object details.
//
Procedure OnSelectObjectAttributes(Ref, AttributeTree) Export
	
EndProcedure

// Called when getting a view of the object's props.
// 
// Parameters:
//  Ref                - AnyRef -  versioned configuration object.
//  AttributeName          - String      -  Markusica, as it is set in the Configurator.
//  AttributeDescription - String      -  output parameter, you can override the resulting synonym.
//  Visible             - Boolean      -  output details in reports by version.
//
Procedure OnDetermineObjectAttributeDescription(Ref, AttributeName, AttributeDescription, Visible) Export
	
EndProcedure

// Adds details to the object that are stored separately from the object or in the service part of the object itself
// that is not intended for output in reports.
//
// Parameters:
//  Object - CatalogObject
//         - DocumentObject
//         - ChartOfCalculationTypesObject
//         - ChartOfAccountsObject
//         - ChartOfCharacteristicTypesObject -
//           
//  AdditionalAttributes - ValueTable - 
//                                              :
//   * Id - Arbitrary -  unique ID of the Bank details. Required when restoring from
//                                    the object version in the case when the props value is stored separately from the object.
//   * Description - String -  name of the prop.
//   * Value - Arbitrary -  the value of the props.
//
Procedure OnPrepareObjectData(Object, AdditionalAttributes) Export 
	
	
	
EndProcedure

// Restores the values of object details that are stored separately from the object.
//
// Parameters:
//  Object - CatalogObject
//         - DocumentObject
//         - ChartOfCalculationTypesObject
//         - ChartOfAccountsObject
//         - ChartOfCharacteristicTypesObject -
//           :
//   * Ref - AnyRef
//  AdditionalAttributes - ValueTable - 
//                                              :
//   * Id - Arbitrary -  unique ID of the Bank details.
//   * Description - String -  name of the prop.
//   * Value - Arbitrary -  the value of the props.
//
Procedure OnRestoreObjectVersion(Object, AdditionalAttributes) Export
	
	
	
EndProcedure

#EndRegion