﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	UnusedFilesTable = Reports.IrrelevantFilesVolume.UnusedFilesTable();
	
	StandardProcessing = False;
	
	ResultDocument.Clear();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	Settings = SettingsComposer.GetSettings();
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("DataVolumeTotal", DataVolumeTotal());
	ExternalDataSets.Insert("IrrelevantFilesVolume", UnusedFilesTable);
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, Settings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ReportIsBlank = Common.CommonModule("ReportsServer").ReportIsBlank(ThisObject, CompositionProcessor);
		SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	EndIf;
EndProcedure

#EndRegion

#Region Private

Function DataVolumeTotal()
	
	SetPrivilegedMode(True);
	Query = New Query(FilesOperationsInternal.FullFilesVolumeQueryText());
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf