///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// 
// 
//
// Parameters:
//   Form - ClientApplicationForm -  report form.
//         - ManagedFormExtensionForReports
//         - Structure:
//           * ReportSettings - See ReportsClientServer.DefaultReportSettings
//   Cancel - Boolean -  indicates that the form was not created.
//   StandardProcessing - Boolean -  indicates whether standard (system) event processing is performed.
//
// Example:
//	
//	
//	
//	
//	
//	
//	
//	
//	
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	
	
EndProcedure

// 
// 
//
// Parameters:
//   Form - ClientApplicationForm -  report form or report settings.
//   NewDCSettings - DataCompositionSettings -  settings to upload to the settings Builder.
//
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	
	
	
EndProcedure

//  
// 
// 
// 
// Parameters:
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForReports
//        - Undefined -  report form.
//  SettingProperties - Structure - :
//      * DCField - DataCompositionField -  output setting.
//      * TypeDescription - TypeDescription -  type of output setting.
//      * ValuesForSelection - ValueList -  specify the objects that will be offered to the user in the selection list.
//                            Complements the list of objects that the user has already selected earlier.
//                            However, you should not assign a new list of values to this parameter.
//      * SelectionValuesQuery - Query -  to specify the query to select objects that you want to Supplement 
//                               Values for the selection. The first column (with index 0) should select the object
//                               to add to the selection Value.Value.
//                               To disable AutoFill in the query property, select Values.The text should be written
//                               as an empty string.
//      * RestrictSelectionBySpecifiedValues - Boolean -  specify True to restrict the user's selection
//                                                to the values specified in the selection Value (its final state).
//      * Type - String
//
// Example:
//   1. for all settings of the reference Link type.Users hide and do not allow to select marked for deletion, 
//   invalid and service users.
//
//   If The Properties Of The Configuration.Apisination.Stereotip(Type("Spravochniki.Users")) Then
//     Properties of the configuration.Restrict Selectionsreferences = True;
//     Properties of the configuration.Values for the selection.Clear();
//     Properties of the configuration.Zaproszenie.Text =
//       " SELECT Link from directory.Users
//       |WHERE not marked as Deleted and not Invalid AND not Official";
//   Conicelli;
//
//   2. For setting "Size" to provide additional value for selection.
//
//   If The Properties Of The Configuration.Poland = New Precompounding("Parametrizing.Size") Then
//     Properties of the configuration.Values for the selection.Add(10000000, NSTR ("ru = 'More Than 10 MB'"));
//   Conicelli;
//
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	
EndProcedure

// Allows you to set a list of frequently used fields that will be displayed in the submenu for the context menu commands 
// "Insert field on the left", "Insert grouping below", etc.  
//
// Parameters:
//   Form - ClientApplicationForm -  report form.
//   MainField - Array of String -  names are often used in the report field.
//
Procedure WhenDefiningTheMainFields(Form, MainField) Export 
	
	
	
EndProcedure

#EndRegion
