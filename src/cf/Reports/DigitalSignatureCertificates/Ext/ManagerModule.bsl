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
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Return;
	EndIf;
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "DigitalSignatureCertificates");
	OptionSettings.LongDesc = NStr("en = 'Digital signature certificates valid in this year.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ExpiringSoon");
	OptionSettings.LongDesc = NStr("en = 'Expiring certificates.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "IndividualCertificateIssuanceRequired");
	OptionSettings.LongDesc = NStr("en = 'Employees'' certificates issued by non-governmental CA and who require a certificate for individuals.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "EmployeesCertificates");
	OptionSettings.LongDesc = NStr("en = 'Employees'' certificates.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "MRLOARequired");
	OptionSettings.LongDesc = NStr("en = 'Certificates that require MR LOA.';");
		
EndProcedure

// To set up a report form.
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

// Defines the report integration settings with configuration mechanisms. 
//
// Parameters:
//  InterfaceSettings4 - See AttachableCommands.AttachableObjectSettings
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