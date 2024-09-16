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
	ReportSettings.LongDesc = NStr("en = 'Task list and summary.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "CurrentTasks");
	OptionSettings.LongDesc = NStr("en = 'All tasks in progress by the specified due date.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformerDisciplineSummary");
	OptionSettings.LongDesc = NStr("en = 'Overdue tasks and tasks completed on schedule summary by assignee.';");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf