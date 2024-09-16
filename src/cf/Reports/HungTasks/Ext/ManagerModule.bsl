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
	ReportSettings.LongDesc = NStr("en = 'Unassigned tasks analysis (tasks not assigned to any users).';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UnassignedTasksSummary");
	OptionSettings.LongDesc = NStr("en = 'Unassigned tasks summary (tasks assigned to blank roles).';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UnassignedTasksByPerformers");
	OptionSettings.LongDesc = NStr("en = 'Unassigned tasks (tasks assigned to blank roles).';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UnassignedTasksByAddressingObjects");
	OptionSettings.LongDesc = NStr("en = 'Unassigned tasks by business objects.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "OverdueTasks");
	OptionSettings.LongDesc = NStr("en = 'Unassigned and overdue tasks (tasks not assigned to any users).';");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf