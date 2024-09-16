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
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, True);
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "");
	OptionSettings.LongDesc = 
		NStr("en = 'Information about the survey respondents,
		|and response statistics.';");
	OptionSettings.SearchSettings.FieldDescriptions = 
		NStr("en = 'Respondent
		|Survey
		|Question
		|Response';");
	OptionSettings.SearchSettings.FilterParameterDescriptions = 
		NStr("en = 'Survey
		|Report type';");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf