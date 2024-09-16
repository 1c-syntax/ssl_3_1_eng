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
	ReportSettings.LongDesc = NStr("en = 'Business process list and summary.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "BusinessProcessesList");
	OptionSettings.LongDesc = NStr("en = 'Business processes of certain types for the specified period.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "StatisticsByKinds");
	OptionSettings.LongDesc = NStr("en = 'Pivot chart of all active and completed business processes.';");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf