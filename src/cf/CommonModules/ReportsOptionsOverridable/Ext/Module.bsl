///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Sets the settings that are used as standard for subsystem objects.
//
// Parameters:
//   Settings - Structure - :
//       * OutputReportsInsteadOfOptions - Boolean - :
//           
//           
//           
//       * OutputDetails1 - Boolean - :
//           
//           
//           
//       * Search - Structure - :
//           ** InputHint - String -  the hint text is displayed in the search field when no search is specified.
//               As an example, we recommend specifying frequently used application configuration terms.
//       * OtherReports - Structure - :
//           ** CloseAfterChoice - Boolean -  whether to close the form after selecting the report hyperlink.
//               Truth - to close the "Other reports" after selecting.
//               False - do not close.
//               The default value is: True.
//           ** ShowCheckBox - Boolean -  whether to show the close after Selection checkbox.
//               True - show the "Close this window after switching to another report" checkbox.
//               False - do not show the checkbox.
//               Default: Lie.
//       * EditOptionsAllowed - Boolean -  show advanced report settings
//               and commands to change the report variant.
//
// Example:
//	Customization.Search.Podskazite = NBC("EN = 'For example, cost price'");
//	Customization.Other reports.Zakryvateli = Lie;
//	Customization.Other reports.Showflag = True;
//	Customization.Allowed To Change Options = False;
//
Procedure OnDefineSettings(Settings) Export

	
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Defines the sections of the command interface that provide report panels.
// You need to add metadata to the Sections for the first-level subsystems
// that contain commands for calling report panels.
//
// Parameters:
//  Sections - ValueList - :
//      * Value - MetadataObjectSubsystem
//                 - String - 
//                   
//      * Presentation - String -  title of the report panel in this section.
//
// Example:
//	Sections.Add (Metadata.Subsystems.Survey, NSTR ("ru = 'Survey reports'"));
//	Sections.Add(Variationdescription.ID of the initial page (), NSTR("ru = 'Main reports'"));
//
Procedure DefineSectionsWithReportOptions(Sections) Export
	
	
	
EndProcedure

// Sets advanced configuration report settings, such as:
// - description of the report;
// - search fields: names of fields, parameters, and selections (for reports not based on SKD);
// - placement in sections of the command interface
//   (the initial configuration for placing reports on subsystems is automatically determined from the metadata,
//    and it does not need to be duplicated);
// - enabled flag (for contextual reports);
// - output mode in report panels (with or without grouping by report);
// - and other.
// 
// The procedure specifies only the settings for reports (and report variants) of the configuration.
// To configure reports from configuration extensions, include them in the pluggable reports and Processing subsystem.
//
// To set settings, use the following auxiliary procedures and functions:
//   report Options.Opasayutsya, 
//   Report variantss.Obisnuieste, 
//   Report variantss.Set the output mode for the report panel, 
//   Report variantss.Set up a report in the Manager module.
//
// By changing the report settings, you can change the settings of all its variants.
// However, if you explicitly get the report variant settings, they will become independent,
// i.e. they will no longer inherit settings changes from the report.
//   
// The functional options of a predefined report variant are combined with the functional options of this report according to the rules:
// (Fo1_report OR Fo2_report) And (Fo3_variant OR Fo4_variant).
// However, only functional report options apply to custom report options
// - they are disabled only when the entire report is disabled.
//
// Parameters:
//   Settings - ValueTable - :
//       * Report - CatalogRef.ExtensionObjectIDs
//               - CatalogRef.AdditionalReportsAndDataProcessors
//               - CatalogRef.MetadataObjectIDs
//               - String - 
//       * Metadata - MetadataObjectReport -  the report metadata.
//       * UsesDCS - Boolean -  indicates whether the report uses the main SKD.
//       * VariantKey - String -  the identifier of the version of the report.
//       * DetailsReceived - Boolean -  indicates that the string description has already been received.
//       * Enabled              - Boolean - 
//       * DefaultVisibility - Boolean -  if False, the report option is hidden in the report panel by default.
//       * ShouldShowInOptionsSubmenu - Boolean -   
//                                                
//       * Description - String - 
//       * LongDesc - String -  explanation of the purpose of the report.
//       * Location - Map of KeyAndValue - :
//             ** Key - MetadataObject -  the subsystem that hosts the report or report variant.
//             ** Value - String -  the settings in the subsystem (group) - "", "Important", "Stacie".
//       * SearchSettings - Structure - :
//             ** FieldDescriptions - String -  field names of the report variant.
//             ** FilterParameterDescriptions - String -  the names settings option of the report.
//             ** Keywords - String -  additional terminology (including specialized or outdated).
//             ** TemplatesNames - String -  used instead of field Names.
//       * SystemInfo - Structure -  other service information.
//       * Type - String -  the list of type identifiers.
//       * IsOption - Boolean -  indication that a description of the report refers to the version of the report.
//       * FunctionalOptions - Array of String - :
//       * GroupByReport - Boolean -  indicates whether options should be grouped by base report.
//       * MeasurementsKey - String -  ID of the report performance measurement.
//       * MainOption - String -  ID of the main version of the report.
//       * DCSSettingsFormat - Boolean -  indicates whether settings are stored in the SKD format.
//       * DefineFormSettings - Boolean - 
//           
//           
//           :
//               
//               
//               //
//               
//               
//               
//                See ReportsClientServer.DefaultReportSettings
//               //
//               
//               	
//               
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
//  
//	
//  
//	
//	
//
Procedure CustomizeReportsOptions(Settings) Export

	
	
EndProcedure

// Registers changes in the names of report variants.
// It is used for updating to preserve referential integrity,
// in particular to save user settings and settings for sending reports.
// The old variant name is reserved and cannot be used in the future.
// If there were several changes, then each change must be registered
// by specifying the latest (current) change in the current variant name.) name of the report variant.
// Since the names of report variants are not displayed in the user interface,
// we recommend setting them in such a way that you don't need to change them later.
// In the Changes, you must add descriptions of changes to the names
// of report variants connected to the subsystem.
//
// Parameters:
//   Changes - ValueTable - :
//       * Report - MetadataObject -  the report metadata in the scheme which has changed the name of the option.
//       * OldOptionName - String -  the old variant name, before the change.
//       * RelevantOptionName - String -  the current (last current) name of the option.
//
// Example:
//	Change = Changes.Add ();
//	Change.Report = Metadata.Reports.<ReportName>;
//	Change.Stroymateriala = "<Stroymateriala>";
//	Change.Up-To-Date Variant = "<Up-To-Date Variant>";
//
Procedure RegisterChangesOfReportOptionsKeys(Changes) Export
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Defines configuration objects whose manager modules have a procedure for adding Report commands
// describing commands for opening contextual reports.
// For the syntax of the Add Report Commands procedure, see the documentation.
//
// Parameters:
//  Objects - Array -  metadata objects (metadata Objects) with report commands.
//
Procedure DefineObjectsWithReportCommands(Objects) Export
	
EndProcedure

// Define a list of global report commands.
// The event occurs when the reuse module is called.
//
// Parameters:
//  ReportsCommands - ValueTable - :
//   * Id - String   -  command ID.
//   * Presentation - String   -  representation of the team in the form.
//   * Importance      - String   -  the suffix of the group in the submenu where this command should be output.
//                                Allowed to use: "Important", "Normal" and "Stacie".
//   * Order       - Number    -  the order in which the team is placed in the group. Used for setting up for a specific
//                                workplace.
//   * Picture      - Picture -  picture of the team.
//   * Shortcut - Shortcut -  keyboard shortcut to quickly call a command.
//   * ParameterType - TypeDescription -  types of objects that this command is intended for.
//   * VisibilityInForms    - String -  comma-separated form names that the command should be displayed in.
//                                    Used when the composition of teams differs for different forms.
//   * FunctionalOptions - String -  comma-separated names of functional options that define the visibility of the command.
//   * VisibilityConditions    - Array -  determines the visibility of the command depending on the context.
//                                    To register conditions, use the procedure
//                                    Pluggable commands.Dobasefinalization().
//                                    Conditions are combined by "And".
//   * ChangesSelectedObjects - Boolean -  determines whether the command is available in a situation
//                                         where the user does not have permission to change the object.
//                                         If True, the button will not be available in the situation described above.
//                                         Optional. Default: Lie.
//   * MultipleChoice - Boolean
//                        - Undefined - 
//                                         
//                                         
//   * IsNonContextual - Boolean - 
//                              
//   * WriteMode - String - :
//                 
//                                  
//                                  
//                 
//                 
//                 
//                 
//                 
//   * FilesOperationsRequired - Boolean -  if True, the web client offers
//                                        to install an extension for working with 1C:Company.
//                                        Optional. Default: Lie.
//   * Manager - String - 
//                         
//   * FormName - String -  name of the form that you want to open or get to run the command.
//                         If no Handler is specified, the "Open" method is called for the form.
//   * VariantKey - String -  name of the report variant to open when running the command.
//   * FormParameterName - String -  name of the form parameter to pass the link or array of links to.
//   * FormParameters - Undefined
//                    - Structure - 
//   * Handler - String - 
//                  
//                  :
//                  
//                  
//   * AdditionalParameters - Structure -  parameters of the handler specified in the Handler.
//
//  Parameters - Structure - :
//   * FormName - String -  full name of the form.
//   
//  StandardProcessing - Boolean -  if set to False, the "add report Commands" event of the object Manager will not
//                                  be called.
//
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
EndProcedure

#EndRegion
