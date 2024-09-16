///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// 
//  See ReportMailing.SetFormatsParameters.
//
// Parameters:
//   FormatsList - ValueList:
//       * Value      - EnumRef.ReportSaveFormats -  format link.
//       * Presentation - String -  the presentation format.
//       * Check       - Boolean -  indicates that the format is used by default.
//       * Picture      - Picture -  image format.
//
// Example:
//	
//	
//
Procedure OverrideFormatsParameters(FormatsList) Export
	
	
	
EndProcedure

// 
//  See ReportMailing.AddItemToRecipientsTypesTable.
// 
// 
//   
//   
//   
//   
//   
//   
//
// Parameters:
//   TypesTable  - ValueTable -  type description table.
//   AvailableTypes - Array -  available type.
//
// Example:
//	Settings = New Structure;
//	Customization.Insert ("Maintype", Type ("Reference Link.Contractors"));
//	Customization.Insert ("Views", Managing Contact Information.Type Of Contact Informationname ("Emailcontagent"));
//	Sending reports.Add An Element To The Table Of Recipient Types(Table Of Types, Available Types, Settings);
//
Procedure OverrideRecipientsTypesTable(TypesTable, AvailableTypes) Export
	
EndProcedure

// Allows you to define your own handler for saving a table document to a format.
// Important:
//   If non-standard processing is used (standard processing is changed to False),
//   then the full Filename must contain the full file name with the extension.
//
// Parameters:
//   StandardProcessing - Boolean -  indicates whether the standard subsystem mechanisms are used for saving to a format.
//   SpreadsheetDocument    - SpreadsheetDocument -  stored the table document.
//   Format               - EnumRef.ReportSaveFormats -  the format in which the table
//                                                                        document is saved.
//   FullFileName       - String -  full file name.
//       Passed without an extension if the format was added in the application configuration.
//
// Example:
//	
//		
//		
//		
//	
//
Procedure BeforeSaveSpreadsheetDocumentToFormat(StandardProcessing, SpreadsheetDocument, Format, FullFileName) Export
	
	
	
EndProcedure

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
// Parameters:
//   RecipientsParameters - CatalogRef.ReportMailings
//                        - Structure -  parameters for creating mailing list recipients.
//   Query - Query - 
//   StandardProcessing - Boolean - 
//   Result - Map of KeyAndValue - 
//                                               :
//       * Key     - CatalogRef - 
//       * Value - String - 
// 
Procedure BeforeGenerateMailingRecipientsList(RecipientsParameters, Query, StandardProcessing, Result) Export

	

EndProcedure

// Allows you to exclude reports that are not ready for integration with the mailing list.
//   The specified reports are used as an exclusive filter when selecting reports.
//
// Parameters:
//   ReportsToExclude - Array -  list of reports in the form of objects with the object Metadata type: Report
//                       that are connected to the "report Options" storage, but do not support integration with mailings.
//
Procedure DetermineReportsToExclude(ReportsToExclude) Export
	
	
	
EndProcedure

// Allows you to redefine the parameters for generating the sent report.
//
// Parameters:
//  GenerationParameters - Structure:
//    * DCUserSettings - DataCompositionUserSettings -  report settings
//                                    set for the corresponding mailing list.
//  AdditionalParameters - Structure:
//    * Report - CatalogRef.ReportsOptions -  link to the storage of settings for the version of the report being sent.
//    * Object - ReportObject -  object of the report being sent.
//    * DCS - Boolean -  indicates that the report is being built using the data layout system.
//    * DCSettingsComposer - DataCompositionSettingsComposer -  layout of settings for the report to be sent.
//
Procedure OnPrepareReportGenerationParameters(GenerationParameters, AdditionalParameters) Export 
	
	
	
EndProcedure

// 
// 
// 
// Parameters:
//   BulkEmailType - String - 
//   MailingRecipientType        - TypeDescription
//                                 - Undefined - 
//   AdditionalTextParameters - Structure - :
//     * Key     - String - 
//     * Value - String -  representation of the argument.
//
//  Example:
//	
//		
//		
//		
//	
//
Procedure OnDefineEmailTextParameters(BulkEmailType, MailingRecipientType, AdditionalTextParameters) Export
	
	
	
EndProcedure

// 
// 
// 
// Parameters:
//   BulkEmailType - String - 
//   MailingRecipientType - TypeDescription
//   Recipient - DefinedType.BulkEmailRecipient - 
//              - Undefined - 
//   AdditionalTextParameters - Structure - :
//     * Key     - String - 
//     * Value - String -  representation of the argument.
// 
// Example:
//	
//		
//		
//		
//		
//	
//
Procedure OnReceiveEmailTextParameters(BulkEmailType, MailingRecipientType, Recipient, AdditionalTextParameters) Export
	
	
	
EndProcedure

#EndRegion
