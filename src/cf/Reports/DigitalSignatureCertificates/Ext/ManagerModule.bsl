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
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Return;
	EndIf;
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "DigitalSignatureCertificates");
	OptionSettings.LongDesc = NStr("en = 'Digital signature certificates valid in this year.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ExpiringSoon");
	OptionSettings.LongDesc = NStr("en = 'Expiring certificates.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "MRLOARequired");
	OptionSettings.LongDesc = NStr("en = 'Certificates that require MR LOA.'");
		
EndProcedure

// Specify the report form settings.
//
// Parameters:
//   Form - ClientApplicationForm
//         - Undefined
//   VariantKey - String
//                - Undefined
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	If VariantKey = "MRLOARequired" Or VariantKey = "ExpiringSoon" Then
		Settings.EditStructureAllowed = False;
	EndIf;
	Settings.GenerateImmediately = True;
	
EndProcedure

// See ReportsOptionsOverridable.DefineObjectsWithReportCommands.
Procedure OnDefineObjectsWithReportCommands(Objects) Export
	
	Objects.Add(Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates);
	
EndProcedure

// End StandardSubsystems.ReportsOptions

// Standard subsystems.Pluggable commands

// Defines settings for integrating the report with configuration functionality. 
//
// Parameters:
//  InterfaceSettings4 - Structure - Object integration settings:
//   * Location - Array of MetadataObject - objects to which an object is attached.
//   * AddReportCommands    - Boolean - the AddReportCommands function is defined in the object manager module. 
//   * CustomizeReportOptions   - Boolean - the CustomizeReportOptions function is defined in the object manager module. 
//   * DefineFormSettings  - Boolean - the DefineFormSettings function is defined in the object manager module. 
//
Procedure OnDefineSettings(InterfaceSettings4) Export
	
	InterfaceSettings4.CustomizeReportOptions = True;
	InterfaceSettings4.DefineFormSettings = True;
	InterfaceSettings4.AddReportCommands = True;
	InterfaceSettings4.Location.Add(Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#EndIf