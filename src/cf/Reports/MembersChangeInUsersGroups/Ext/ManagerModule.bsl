///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.ReportsOptions

// See ReportsOptionsOverridable.BeforeAddReportCommands.
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions")
	 Or Not AccessRight("View", Metadata.Reports.MembersChangeInUsersGroups)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	Presentation = Undefined;
	
	If Parameters.FormName = "Catalog.Users.Form.ListForm" Then
		Presentation = NStr("en = 'User group membership changes'");
		VariantKey = "MembersChangeInUsersGroups";
		
	ElsIf Parameters.FormName = "Catalog.Users.Form.ItemForm" Then
		Presentation = NStr("en = 'User group membership changes'");
		VariantKey = "MembersChangeInUsersGroups";
		
	ElsIf Parameters.FormName = "Catalog.ExternalUsers.Form.ListForm" Then
		Presentation = NStr("en = 'External user group membership changes'");
		VariantKey = "MembersChangeInExternalUsersGroups";
		
	ElsIf Parameters.FormName = "Catalog.ExternalUsers.Form.ItemForm" Then
		Presentation = NStr("en = 'External user group membership changes'");
		VariantKey = "MembersChangeInExternalUsersGroups";
	EndIf;
	
	If Presentation = Undefined Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.Presentation = Presentation;
	Command.Manager = "Report.MembersChangeInUsersGroups";
	Command.VariantKey = VariantKey;
	Command.OnlyInAllActions = True;
	Command.Importance = "SeeAlso";
	
	If VariantKey = "MembersChangeInExternalUsersGroups" Then
		Command.FunctionalOptions = "UseExternalUsers";
	EndIf;
	
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
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "MembersChangeInUsersGroups");
	OptionSettings.LongDesc =
		NStr("en = 'Reads the event log and displays the changes in user group membership for the specified time period, considering the group hierarchy.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "MembersChangeInExternalUsersGroups");
	OptionSettings.FunctionalOptions.Add("UseExternalUsers");
	OptionSettings.LongDesc =
		NStr("en = 'Reads the event log and displays the changes in external user group membership for the specified time period, considering the group hierarchy.'");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
