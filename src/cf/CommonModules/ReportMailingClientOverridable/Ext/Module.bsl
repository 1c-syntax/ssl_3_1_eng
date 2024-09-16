///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Handler for activating the report's SKD custom configuration line.
//
// Parameters:
//   Report - FormDataCollectionItem - 
//       :
//         * FullName - String -  full name of the report. For example: "Report.ReportName".
//         * VariantKey - String -  the key version of the report.
//         * Report - CatalogRef.ReportsOptions -  link to the report option.
//         * Presentation - String - 
//       :
//         * ChangesMade - Boolean -  it should be set to True when the report's user settings change.
//   DCSettingsComposer - DataCompositionSettingsComposer - 
//       :
//       * UserSettings - DataCompositionUserSettings -  all custom report settings.
//       All other properties are read-only.
//   DCID - DataCompositionID - 
//       :
//       	
//   ValueViewOnly - Boolean -  check whether the Value column can be edited directly.
//       If set to True, you should define a handler for selecting the value in the event "firstselect Settings".
//
Procedure OnActivateRowSettings(Report, DCSettingsComposer, DCID, ValueViewOnly) Export
	
EndProcedure

// Handler for the start of selecting a value for the report's custom SCD configuration line.
//
// Parameters:
//   Report - FormDataCollectionItem - 
//       :
//         * FullName - String -  full name of the report. For example: "Report.ReportName".
//         * VariantKey - String -  the key version of the report.
//         * Report - CatalogRef.ReportsOptions -  link to the report option.
//         * Presentation - String - 
//       :
//         * ChangesMade - Boolean -  it should be set to True when the report's user settings change.
//   DCSettingsComposer - DataCompositionSettingsComposer - 
//       :
//       * UserSettings - DataCompositionUserSettings -  all custom report settings.
//       All other properties are read-only.
//   DCID - DataCompositionID - 
//       :
//       	
//   StandardProcessing - Boolean -  if True, the standard selection dialog will be used.
//       If you use custom event handling, set it to False.
//   Handler - NotifyDescription - 
//       :
//       
//       
//
Procedure OnSettingChoiceStart(Report, DCSettingsComposer, DCID, StandardProcessing, Handler) Export
	
EndProcedure

// Handler for clearing values for the report's custom SCD configuration line.
//
// Parameters:
//   Report - FormDataCollectionItem - 
//       :
//         * FullName - String -  full name of the report. For example: "Report.ReportName".
//         * VariantKey - String -  the key version of the report.
//         * Report - CatalogRef.ReportsOptions -  link to the report option.
//         * Presentation - String - 
//       :
//         * ChangesMade - Boolean -  it should be set to True when the report's user settings change.
//   DCSettingsComposer - DataCompositionSettingsComposer - 
//       :
//       * UserSettings - DataCompositionUserSettings -  all custom report settings.
//       All other properties are read-only.
//   DCID - DataCompositionID - 
//       :
//       	
//   StandardProcessing - Boolean -  if True, the setting value will be cleared.
//       If the setting value should not be cleared, it should be set to False.
//
Procedure OnSettingsClear(Report, DCSettingsComposer, DCID, StandardProcessing) Export
	
EndProcedure

#EndRegion
