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
	
	ReportSettings.DefineFormSettings = True;
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.ReportDistributionControl);
	
EndProcedure

// See ReportsOptionsOverridable.DefineObjectsWithReportCommands.
Procedure OnDefineObjectsWithReportCommands(Objects) Export
	
	Objects.Add(Metadata.Catalogs.ReportMailings);
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf