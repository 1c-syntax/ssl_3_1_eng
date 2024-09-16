///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	
	ReportSettings.DefineFormSettings = True;
	
	OptionSettingsHorizontal = ReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettingsHorizontal.LongDesc = NStr("en = 'Horizontal arrangement of columns with dimensions, resources, and register attributes.';");
	OptionSettingsHorizontal.SearchSettings.Keywords = NStr("en = 'Document register records';");
	OptionSettingsHorizontal.Enabled = False;
	OptionSettingsHorizontal.ShouldShowInOptionsSubmenu = True;
	
	OptionSettingsVertical = ReportsOptions.OptionDetails(Settings, ReportSettings, "Additional");
	OptionSettingsVertical.LongDesc = NStr("en = 'Vertical arrangement of columns with dimensions, resources, and attributes allows you to arrange data more compactly to view registers with a large number of columns.';");
	OptionSettingsVertical.SearchSettings.Keywords = NStr("en = 'Document register records';");
	OptionSettingsVertical.Enabled = False;
	OptionSettingsVertical.ShouldShowInOptionsSubmenu = True;
	
EndProcedure

// To call from the procedure, the report variantdefinable.Before adding team reports.
// 
// Parameters:
//  ReportsCommands - ValueTable - :
//       * Id - String -  command ID.
//       * Presentation - String   -  representation of the team in the form.
//       * Importance      - String   -  the suffix of the group in the submenu where this command should be output.
//       * Order       - Number    -  the order in which the team is placed in the group. Used for setting up for a specific
//                                    workplace.
//       * Picture      - Picture -  picture of the team.
//       * Shortcut - Shortcut -  keyboard shortcut to quickly call a command.
//       * ParameterType - TypeDescription -  types of objects that this command is intended for.
//       * VisibilityInForms    - String -  comma-separated form names that the command should be displayed in.
//       * FunctionalOptions - String -  comma-separated names of functional options that define the visibility of the command.
//       * VisibilityConditions    - Array -  determines the visibility of the command depending on the context.
//       * ChangesSelectedObjects - Boolean -  determines whether the command is available.
//       * MultipleChoice - Boolean
//                            - Undefined - 
//             
//             
//       * WriteMode - String -  actions related to writing an object that are performed before the command handler.
//       * FilesOperationsRequired - Boolean -  if True, the web client offers
//             to install an extension to work with 1C:Company.
//       * Manager - String -  full name of the metadata object responsible for executing the command.
//       * FormName - String -  name of the form that you want to open or get to run the command.
//       * VariantKey - String -  name of the report variant to open when running the command.
//       * FormParameterName - String -  name of the form parameter to pass the link or array of links to.
//       * FormParameters - Undefined
//                        - Structure - 
//       * Handler - String -  description of the procedure that processes the main action of the command.
//       * AdditionalParameters - Structure -  parameters of the handler specified in the Handler.
//  Parameters                   - Structure -  a structure containing parameters for connecting the command.
//  DocumentsWithRecordsReport - Array
//                              - Undefined - 
//                                
//                                
//                                
//
// Returns:
//  ValueTableRow, Undefined - 
//
Function AddDocumentRecordsReportCommand(ReportsCommands, Parameters, DocumentsWithRecordsReport = Undefined) Export
	
	If Not AccessRight("View", Metadata.Reports.DocumentRegisterRecords) Then
		Return Undefined;
	EndIf;
	
	CommandParameterTypeDetails = CommandParameterTypeDetails(ReportsCommands, Parameters, DocumentsWithRecordsReport);
	If CommandParameterTypeDetails = Undefined Then
		Return Undefined;
	EndIf;
	
	Command                    = ReportsCommands.Add();
	Command.Presentation      = NStr("en = 'Document register records';");
	Command.MultipleChoice = False;
	Command.FormParameterName  = "";
	Command.Importance           = "SeeAlso";
	Command.ParameterType       = CommandParameterTypeDetails;
	Command.Manager           = "Report.DocumentRegisterRecords";
	Command.Shortcut    = New Shortcut(Key.A, False, True, True);
	
	Return Command;
	
EndFunction

// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.DocumentRegisterRecords);
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.DocumentRegisterRecords);
	DescriptionOfReport.Enabled = False;
	
EndProcedure

// See ReportsOptionsOverridable.BeforeAddReportCommands.
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	AddDocumentRecordsReportCommand(ReportsCommands, Parameters);
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Private

Function CommandParameterTypeDetails(Val ReportsCommands, Val Parameters, Val DocumentsWithRecordsReport)
	
	If Not Parameters.Property("Sources") Then
		Return Undefined;
	EndIf;
	
	SourcesStrings = Parameters.Sources.Rows;
	
	If DocumentsWithRecordsReport <> Undefined Then
		DetachReportFromDocuments(ReportsCommands);
		DocumentsWithReport = New Map;
		For Each DocumentWithReport In DocumentsWithRecordsReport Do
			DocumentsWithReport[DocumentWithReport] = True;
		EndDo;	
	Else	
		DocumentsWithReport = Undefined;
	EndIf;
	
	DocumentsTypesWithRegisterRecords = New Array;
	For Each SourceRow1 In SourcesStrings Do
		
		DataRefType = SourceRow1.DataRefType;
		
		If TypeOf(DataRefType) = Type("Type") Then
			DocumentsTypesWithRegisterRecords.Add(DataRefType);
		ElsIf TypeOf(DataRefType) = Type("TypeDescription") Then
			CommonClientServer.SupplementArray(DocumentsTypesWithRegisterRecords, DataRefType.Types());
		EndIf;
		
	EndDo;
	
	DocumentsTypesWithRegisterRecords = CommonClientServer.CollapseArray(DocumentsTypesWithRegisterRecords);
	
	IndexOf = DocumentsTypesWithRegisterRecords.Count() - 1;
	While IndexOf >= 0 Do
		If Not IsConnectedType(DocumentsTypesWithRegisterRecords[IndexOf], DocumentsWithReport) Then
			DocumentsTypesWithRegisterRecords.Delete(IndexOf);
		EndIf;
		IndexOf = IndexOf - 1;
	EndDo;	
	
	Return ?(DocumentsTypesWithRegisterRecords.Count() > 0, New TypeDescription(DocumentsTypesWithRegisterRecords), Undefined);
	
EndFunction

Procedure DetachReportFromDocuments(ReportsCommands)
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Manager", "Report.DocumentRegisterRecords");
	FoundRows = ReportsCommands.FindRows(TheStructureOfTheSearch);
	
	For Each FoundRow In FoundRows Do
		ReportsCommands.Delete(FoundRow);
	EndDo;
	
EndProcedure

Function IsConnectedType(TypeToCheck, DocumentsWithRecordsReport)
	
	MetadataObject = Metadata.FindByType(TypeToCheck);
	If MetadataObject = Undefined Then
		Return False;
	EndIf;
	
	If DocumentsWithRecordsReport <> Undefined And DocumentsWithRecordsReport[MetadataObject] = Undefined Then
		Return False;
	EndIf;
	
	If Not Common.IsDocument(MetadataObject) Then
		Return False;
	EndIf;
	
	If MetadataObject.Posting <> Metadata.ObjectProperties.Posting.Allow
		Or MetadataObject.RegisterRecords.Count() = 0 Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#EndIf