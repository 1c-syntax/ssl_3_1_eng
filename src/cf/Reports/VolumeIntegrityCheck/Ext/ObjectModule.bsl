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

#Region EventHandlers  

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	Settings = SettingsComposer.GetSettings();
	ParameterVolume = Settings.DataParameters.Items.Find("Volume");
	If ParameterVolume <> Undefined Then
		Volume = ParameterVolume.Value;
	EndIf;
	
	FilesTableOnHardDrive = Reports.VolumeIntegrityCheck.FilesOnHardDrive(Volume);
		
	StandardProcessing = False;
		
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("VolumeCheckTable", FilesTableOnHardDrive);	
	TemplateComposer = New DataCompositionTemplateComposer;	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, Settings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	ResultDocument.Clear();	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);                                                        
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Cell = ResultDocument.Area(ResultDocument.TableHeight + 2, 1, ResultDocument.TableHeight + 2, 2);
		Cell.Merge();
		ModuleReportsServer = Common.CommonModule("ReportsServer");
		ModuleReportsServer.OutputHyperlink(Cell, "VolumeIntegrityCheck.RecoverFiles", NStr("en = 'Restore';"));
	EndIf;
	
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", FilesTableOnHardDrive.Count() = 0);
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ReportSettings = SettingsComposer.GetSettings();
	Volume = ReportSettings.DataParameters.Items.Find("Volume").Value;
	
	If Not ValueIsFilled(Volume) Then
		Common.MessageToUser(
			NStr("en = 'Please fill the ""Volume"" parameter.';"), , );
		Cancel = True;
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf