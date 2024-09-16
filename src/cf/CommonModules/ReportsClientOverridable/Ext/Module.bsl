///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Occurs after the report is generated: after the background task is completed.
// Allows you to override the processing of the report generation result.
//
// Parameters:
//   ReportForm - ClientApplicationForm
//               - ManagedFormExtensionForReports - :
//                   * Report - ReportObject -  the data structure of the form is similar to the report object.
//
//  ReportCreated - Boolean -  True if the report was generated successfully.
//
Procedure AfterGenerate(ReportForm, ReportCreated) Export
	
EndProcedure

// 
// 
//
// Parameters:
//   ReportForm - ClientApplicationForm
//               - ManagedFormExtensionForReports - :
//                   * Report - ReportObject -  the data structure of the form is similar to the report object.
//
//   Item     - FormField        -  table document.
//   Details - Arbitrary     -  the value of the decoding point, series, or chart value.
//   StandardProcessing - Boolean  -  indicates whether standard (system) event processing is performed.
//
Procedure DetailProcessing(ReportForm, Item, Details, StandardProcessing) Export
	
EndProcedure

// 
// 
//
// Parameters:
//   ReportForm - ClientApplicationForm
//               - ManagedFormExtensionForReports - :
//                   * Report - ReportObject -  the data structure of the form is similar to the report object.
//
//   Item     - FormField        -  table document.
//   Details - Arbitrary     -  the value of the decoding point, series, or chart value.
//   StandardProcessing - Boolean  -  indicates whether standard (system) event processing is performed.
//
Procedure AdditionalDetailProcessing(ReportForm, Item, Details, StandardProcessing) Export
	
EndProcedure

// 
//  See ReportsOverridable.OnCreateAtServer
//
// Parameters:
//   ReportForm - ClientApplicationForm
//               - ManagedFormExtensionForReports - :
//                   * Report - ReportObject -  the data structure of the form is similar to the report object.
//
//   Command     - FormCommand     -  the command that was called.
//   Result   - Boolean           -  True if the command call was processed.
//
Procedure HandlerCommands(ReportForm, Command, Result) Export
	
	
	
EndProcedure

// 
//
// Parameters:
//   ReportForm - ClientApplicationForm
//               - ManagedFormExtensionForReports - :
//                   * Report - ReportObject -  the data structure of the form is similar to the report object.
//
//   SelectionConditions - Structure:
//    * FieldName              - String - 
//    * LayoutItem    - DataCompositionAvailableParameter
//                           - DataCompositionFilterAvailableField - 
//    * AvailableTypes        - TypeDescription  - 
//    * Marked           - ValueList - 
//    * ChoiceParameters      - Array of ChoiceParameter - 
// 
//   ClosingNotification1 - NotifyDescription - 
//                           
//
//   StandardProcessing - Boolean - 
//                                   
//
Procedure AtStartValueSelection(ReportForm, SelectionConditions, ClosingNotification1, StandardProcessing) Export
	
	
	
EndProcedure

// 
// 
//
// Parameters:
//   ReportForm - ClientApplicationForm
//               - ManagedFormExtensionForReports - :
//                   * Report - ReportObject -  the data structure of the form is similar to the report object.
//
//   ValueSelected - Arbitrary     -  the result of the selection in the subordinate form.
//   ChoiceSource    - ClientApplicationForm -  the form where the selection was made.
//   Result         - Boolean           -  True if the selection result is processed.
//
Procedure ChoiceProcessing(ReportForm, ValueSelected, ChoiceSource, Result) Export
	
EndProcedure

// 
// 
//
// Parameters:
//   ReportForm - ClientApplicationForm
//               - ManagedFormExtensionForReports - :
//                   * Report - ReportObject -  the data structure of the form is similar to the report object.
//
//   Item     - FormField        -  table document.
//   Area     - SpreadsheetDocumentRange -  selected value.
//   StandardProcessing - Boolean -  indicates whether standard event processing is being performed.
//
Procedure SpreadsheetDocumentSelectionHandler(ReportForm, Item, Area, StandardProcessing) Export
	
EndProcedure

// 
// 
//
// Parameters:
//   ReportForm - ClientApplicationForm
//               - ManagedFormExtensionForReports - :
//                   * Report - ReportObject -  the data structure of the form is similar to the report object.
//
//   EventName  - String           -  event ID for receiving forms.
//   Parameter    - Arbitrary     -  extended information about the event.
//   Source    - ClientApplicationForm
//               - Arbitrary -  event source.
//   NotificationProcessed - Boolean -  indicates that the event was processed.
//
Procedure NotificationProcessing(ReportForm, EventName, Parameter, Source, NotificationProcessed) Export
	
EndProcedure

// Handler for clicking the period selection button in a separate form.
//  If the configuration uses its own period selection dialog,
//  then the standard Processing parameter should be set to False,
//  and the selected period should be returned to the result Handler.
//
// Parameters:
//   ReportForm - ClientApplicationForm
//               - ManagedFormExtensionForReports - :
//                   * Report - ReportObject -  the data structure of the form is similar to the report object.
//
//   Period - StandardPeriod -  value of the linker setting corresponding to the selected period.
//
//   StandardProcessing - Boolean -  if True, the standard period selection dialog will be used.
//       If set to False, the standard dialog will not open.
//
//   ResultHandler - NotifyDescription - 
//       :
//       
//       
//
Procedure OnClickPeriodSelectionButton(ReportForm, Period, StandardProcessing, ResultHandler) Export
	
	
	
EndProcedure

#EndRegion
