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
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.Enabled = False;
	OptionSettings.LongDesc = NStr("en = 'Search for occurrences.';");
EndProcedure

// To call from the procedure, the report variantdefinable.Before adding team reports.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//   ValueTableRow, Undefined - 
//
Function AddUsageInstanceCommand(ReportsCommands) Export
	If Not AccessRight("View", Metadata.Reports.SearchForReferences) Then
		Return Undefined;
	EndIf;
	Command = ReportsCommands.Add();
	Command.Presentation      = NStr("en = 'Occurrences';");
	Command.MultipleChoice = True;
	Command.Importance           = "SeeAlso";
	Command.FormParameterName  = "Filter.RefSet";
	Command.VariantKey       = "Main";
	Command.Manager           = "Report.SearchForReferences";
	Command.Shortcut    = New Shortcut(Key.V, False, True, True);
	Command.OnlyInAllActions = True;
	Return Command;
EndFunction

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf