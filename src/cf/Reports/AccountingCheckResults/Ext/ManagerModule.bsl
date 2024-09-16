﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
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
	
	OptionSettingsMain = ReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettingsMain.LongDesc = NStr("en = 'Displays the data integrity check results.';");
	OptionSettingsMain.SearchSettings.Keywords = NStr("en = 'Report on object issues';");
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.AccountingCheckResults);
	ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AccountingCheckResults).Enabled = False;
	
EndProcedure

// See ReportsOptionsOverridable.BeforeAddReportCommands
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	If Not AccessRight("View", Metadata.Reports.AccountingCheckResults) Then
		Return;
	EndIf;
	
	If Not StrStartsWith(Parameters.FormName, Metadata.Catalogs.AccountingCheckRules.FullName()) Then
		Return;
	EndIf;
	
	Command                   = ReportsCommands.Add();
	Command.Presentation     = NStr("en = 'Data integrity check results';");
	Command.FormParameterName = "";
	Command.Importance          = "SeeAlso";
	Command.VariantKey      = "Main";
	Command.Manager          = "Report.AccountingCheckResults";
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
