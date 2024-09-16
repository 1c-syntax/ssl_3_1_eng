///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonOverridable.OnAddMetadataObjectsRenaming.
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Library = "StandardSubsystems";
	
	Common.AddRenaming(Total,
		"2.2.1.12",
		"Subsystem.SetupAndAdministration",
		"Subsystem.Administration",
		Library);
	
EndProcedure

// Defines the sections where the report panel is available.
//   For more information, see Description of the procedure used
//   by the departments of the general module of the report options.
//
// Parameters:
//   Sections - ValueList
//
Procedure OnDefineSectionsWithReportOptions(Sections) Export
	
	Subsystem = Metadata.Subsystems.Find("Administration");
	
	If Subsystem <> Undefined Then
		Sections.Add(Subsystem, NStr("en = 'Administrator reports';"));
	EndIf;
	
EndProcedure

// Parameters:
//  Sections - See AdditionalReportsAndDataProcessorsOverridable.GetSectionsWithAdditionalReports.Sections
//
Procedure OnDefineSectionsWithAdditionalReports(Sections) Export
	
	Subsystem = Metadata.Subsystems.Find("Administration");
	
	If Subsystem <> Undefined Then
		Sections.Add(Subsystem);
	EndIf;
	
EndProcedure

// Parameters:
//  Sections - See AdditionalReportsAndDataProcessorsOverridable.GetSectionsWithAdditionalReports.Sections
//
Procedure OnDefineSectionsWithAdditionalDataProcessors(Sections) Export
	
	Subsystem = Metadata.Subsystems.Find("Administration");
	
	If Subsystem <> Undefined Then
		Sections.Add(Subsystem);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
