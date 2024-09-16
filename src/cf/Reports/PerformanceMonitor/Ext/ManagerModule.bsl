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
	
	ReportsOptionsAvailable = PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.ReportsOptions");
	If ReportsOptionsAvailable Then
		ModuleReportsOptions = PerformanceMonitorInternal.CommonModule("ReportsOptions");
		
		OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformanceMonitorByKeyOperations"); // See ReportsOptions.OptionDetails		
		OptionSettings.LongDesc = 
			NStr("en = 'Provides Apdex metrics.';");
			
		OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformanceMonitorComparison"); // See ReportsOptions.OptionDetails
		OptionSettings.LongDesc = 
			NStr("en = 'Compares Apdex metrics during a period';");
			
		OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformanceMonitorPeriodInColumns"); // See ReportsOptions.OptionDetails
		OptionSettings.LongDesc = 
			NStr("en = 'Provides Apdex metrics by period.';");
	EndIf;
			
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
