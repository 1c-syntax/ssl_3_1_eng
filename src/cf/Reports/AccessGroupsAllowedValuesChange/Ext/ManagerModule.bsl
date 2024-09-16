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

// See ReportsOptionsOverridable.BeforeAddReportCommands.
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions")
	 Or Not Common.SubsystemExists("StandardSubsystems.AccessManagement")
	 Or Not AccessRight("View", Metadata.Reports.AccessGroupsAllowedValuesChange)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
	ParametersForReports = ModuleAccessManagementInternal.ParametersForReports();
	
	If Parameters.FormName <> ParametersForReports.AccessGroupsListFormFullName
	   And Parameters.FormName <> ParametersForReports.AccessGroupsItemFormFullName
	   And Parameters.FormName <> ParametersForReports.ProfilesListFormFullName
	   And Parameters.FormName <> ParametersForReports.ProfilesItemFormFullName Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.Presentation = NStr("en = 'Changes in allowed access group values';");
	Command.Manager = "Report.AccessGroupsAllowedValuesChange";
	Command.VariantKey = "Main";
	Command.OnlyInAllActions = True;
	Command.Importance = "SeeAlso";
	
EndProcedure

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Return;
	EndIf;
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ReportSettings.DefineFormSettings = True;
	ReportSettings.GroupByReport = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.Enabled = Common.SubsystemExists("StandardSubsystems.AccessManagement");
	OptionSettings.LongDesc =
		NStr("en = 'Reads the event log and displays the changes in allowed access group values considering value group changes for the given time period.';");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
