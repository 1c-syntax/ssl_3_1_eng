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
	 Or Not AccessRight("View", Metadata.Reports.UserAccountsChanges)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	Presentation = Undefined;
	
	If Parameters.FormName = "Catalog.Users.Form.ListForm"
	 Or Parameters.FormName = "Catalog.ExternalUsers.Form.ListForm" Then
		
		Presentation = NStr("en = 'User account change history';");
		
	ElsIf Parameters.FormName = "Catalog.Users.Form.ItemForm"
	      Or Parameters.FormName = "Catalog.ExternalUsers.Form.ItemForm" Then
		
		Presentation = NStr("en = 'User account change history';");
	EndIf;
	
	If Presentation = Undefined Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.Presentation = Presentation;
	Command.Manager = "Report.UserAccountsChanges";
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
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.LongDesc = 
		NStr("en = 'Reads the event log and shows you the changes in the properties of infobase users for the given time period.';");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
