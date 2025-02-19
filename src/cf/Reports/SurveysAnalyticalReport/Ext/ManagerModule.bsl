///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ReportsOptions

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ViewAnswersSimpleQuestions");
	OptionSettings.LongDesc = NStr("en = 'View respondents'' answers to basic questions.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ViewTableQuestionsFlatView");
	OptionSettings.LongDesc = 
		NStr("en = 'View respondents'' answers to question charts.
		|Results are displayed as a grouped list.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ViewTableQuestionsTableView");
	OptionSettings.LongDesc = 
		NStr("en = 'View respondents'' answers to question charts.
		|Each answer is displayed as a table.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "SimpleQuestionsAnswerCount");
	OptionSettings.LongDesc = NStr("en = 'View the distribution of answers to basic questions.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "SimpleQuestionsAggregatedIndicators");
	OptionSettings.LongDesc = 
		NStr("en = 'View the average, minimum, and maximum for numeric answers to basic questions.
		|';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "TableQuestionsAnswerCount");
	OptionSettings.LongDesc = 
		NStr("en = 'View the distribution of numeric answers in question charts.
		|';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "TableQuestionsAggregatedParameters");
	OptionSettings.LongDesc = 
		NStr("en = 'View the average, minimum, and maximum for numeric answers to question charts.
		|';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "SimpleQuestionsAnswerCountComparisonBySurveys");
	OptionSettings.LongDesc = 
		NStr("en = 'Comparative analysis of answers to basic survey questions.
		|';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "TableQuestionsAggregatedParametersComparisonBySurveys");
	OptionSettings.LongDesc = 
		NStr("en = 'Comparative analysis of the aggregated answers to question charts in surveys.
		|';");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf