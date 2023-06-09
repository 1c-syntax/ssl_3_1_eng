﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ReportsOptions

// Set report form settings.
//
// Parameters:
//   Form - ClientApplicationForm
//         - Undefined
//   VariantKey - String
//                - Undefined
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.OnDefineSelectionParameters = True;
	Settings.Events.OnDefineSettingsFormItemsProperties = True;
	
	Settings.ImportSchemaAllowed = True;
	Settings.EditSchemaAllowed = True;
	Settings.RestoreStandardSchemaAllowed = True;
	
	Settings.ImportSettingsOnChangeParameters = Reports.UniversalReport.ImportSettingsOnChangeParameters();
EndProcedure

// See ReportsOverridable.OnCreateAtServer
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	EditOptionsAllowed = CommonClientServer.StructureProperty(
		Form.ReportSettings, "EditOptionsAllowed", False);
	
	If EditOptionsAllowed Then
		Form.ReportSettings.SettingsFormAdvancedMode = 1;
	EndIf;
	
	CommonClientServer.SetFormItemProperty(Form.Items, "SelectSettings", "Visible", False);
	CommonClientServer.SetFormItemProperty(Form.Items, "ShouldSaveSettings", "Visible", False);
	CommonClientServer.SetFormItemProperty(Form.Items, "ShareSettings", "Visible", False);
EndProcedure

// See ReportsOverridable.OnDefineSelectionParameters.
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	AvailableValues = CommonClientServer.StructureProperty(
		SettingsComposer.Settings.AdditionalProperties, "AvailableValues", New Structure);
	
	Try
		ValuesForSelection = CommonClientServer.StructureProperty(
			AvailableValues, StrReplace(SettingProperties.DCField, "DataParameters.", ""));
	Except
		ValuesForSelection = Undefined;
	EndTry;
	
	If ValuesForSelection <> Undefined Then 
		SettingProperties.RestrictSelectionBySpecifiedValues = True;
		SettingProperties.ValuesForSelection = ValuesForSelection;
	EndIf;
EndProcedure

// Called in the event handler of the report form after executing the form code.
// See "Managed form extension for reports.BeforeLoadOptionAtServer" in Syntax Assistant.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   Settings - DataCompositionSettings - settings to load into the settings composer.
//
Procedure BeforeLoadVariantAtServer(Form, Settings) Export
	CurrentSchemaKey = Undefined;
	Schema = Undefined;
	
	IsImportedSchema = False;
	
	If TypeOf(Settings) = Type("DataCompositionSettings") Or Settings = Undefined Then
		If Settings = Undefined Then
			AdditionalSettingsProperties = SettingsComposer.Settings.AdditionalProperties;
		Else
			AdditionalSettingsProperties = Settings.AdditionalProperties;
		EndIf;
		
		If Form.ReportFormType = ReportFormType.Main
			And (Form.DetailsMode
			Or (Form.CurrentVariantKey <> "Main"
			And Form.CurrentVariantKey <> "Main")) Then 
			
			AdditionalSettingsProperties.Insert("ReportInitialized", True);
		EndIf;
		
		SchemaBinaryData = CommonClientServer.StructureProperty(
			AdditionalSettingsProperties, "DataCompositionSchema");
		
		If TypeOf(SchemaBinaryData) = Type("BinaryData") Then
			IsImportedSchema = True;
			CurrentSchemaKey = BinaryDataHash(SchemaBinaryData);
			Schema = Reports.UniversalReport.ExtractSchemaFromBinaryData(SchemaBinaryData);
		EndIf;
	EndIf;
	
	If IsImportedSchema Then
		SchemaKey = CurrentSchemaKey;
		ReportsServer.AttachSchema(ThisObject, Form, Schema, SchemaKey);
	EndIf;
EndProcedure

// 
//
// Parameters:
//   Context - Arbitrary
//   SchemaKey - String
//   VariantKey - String
//                - Undefined
//   NewDCSettings - DataCompositionSettings
//                    - Undefined
//   NewDCUserSettings - DataCompositionUserSettings
//                                    - Undefined
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	CurrentSchemaKey = Undefined;
	
	If NewDCSettings = Undefined Then 
		NewDCSettings = SettingsComposer.Settings;
	EndIf;
	
	IsImportedSchema = False;
	SchemaBinaryData = CommonClientServer.StructureProperty(
		NewDCSettings.AdditionalProperties, "DataCompositionSchema");
	
	If TypeOf(SchemaBinaryData) = Type("BinaryData") Then
		CurrentSchemaKey = BinaryDataHash(SchemaBinaryData);
		If CurrentSchemaKey <> SchemaKey Then
			Schema = Reports.UniversalReport.ExtractSchemaFromBinaryData(SchemaBinaryData);
			IsImportedSchema = True;
		EndIf;
	EndIf;
	
	ResetSettings = CommonClientServer.StructureProperty(NewDCSettings.AdditionalProperties, "ResetSettings", False);
		
	AvailableValues = Undefined;
	FixedParameters = Reports.UniversalReport.FixedParameters(
		NewDCSettings, NewDCUserSettings, AvailableValues);
	
	If CurrentSchemaKey = Undefined Then 
		CurrentSchemaKey = FixedParameters.MetadataObjectType
			+ "/" + FixedParameters.MetadataObjectName
			+ "/" + FixedParameters.TableName;
		CurrentSchemaKey = Common.TrimStringUsingChecksum(CurrentSchemaKey, 100);
		
		If CurrentSchemaKey <> SchemaKey Then
			SchemaKey = "";
			Schema = Reports.UniversalReport.DataCompositionSchema(FixedParameters);
		EndIf;
	EndIf;
		
	If ResetSettings And Schema = Undefined Then
	    Schema = Reports.UniversalReport.DataCompositionSchema(FixedParameters);
	EndIf;	
			
	If CurrentSchemaKey <> Undefined And (CurrentSchemaKey <> SchemaKey Or ResetSettings) Then
		SchemaKey = CurrentSchemaKey;
		ReportsServer.AttachSchema(ThisObject, Context, Schema, SchemaKey);
		
		If IsImportedSchema Then
			Reports.UniversalReport.SetStandardImportedSchemaSettings(
				ThisObject, SchemaBinaryData, NewDCSettings, NewDCUserSettings);
		Else
			Reports.UniversalReport.CustomizeStandardSettings(
				ThisObject, FixedParameters, NewDCSettings, NewDCUserSettings);
		EndIf;
		
		If TypeOf(Context) = Type("ClientApplicationForm") Then
			// Переопределение.
			SSLSubsystemsIntegration.BeforeLoadVariantAtServer(Context, NewDCSettings);
			ReportsOverridable.BeforeLoadVariantAtServer(Context, NewDCSettings);
			BeforeLoadVariantAtServer(Context, NewDCSettings);
			
			TablesToUse = ReportsOptions.TablesToUse(DataCompositionSchema);
			TablesToUse.Add(Metadata().FullName());
			Context.ReportSettings.Insert("TablesToUse", TablesToUse);
		ElsIf TypeOf(Context) = Type("Structure") Then
			SchemaURL = CommonClientServer.StructureProperty(Context, "SchemaURL");
			If Not IsTempStorageURL(SchemaURL) Then 
				Context.Insert("SchemaURL", PutToTempStorage(Schema, New UUID));
			EndIf;
		EndIf;
	Else
		Reports.UniversalReport.SetFixedParameters(
			ThisObject, FixedParameters, NewDCSettings, NewDCUserSettings);
	EndIf;
			
	SettingsComposer.Settings.AdditionalProperties.Insert("AvailableValues", AvailableValues);
	
	Reports.UniversalReport.SetStandardReportHeader(
		Context, NewDCSettings, FixedParameters, AvailableValues);
EndProcedure

// It is called after defining form item properties connected to user settings.
// See ReportsServer.СвойстваЭлементовФормыНастроек()
// It allows to override properties for report personalization purposes.
//
// Parameters:
//  FormType - ReportFormType - See Syntax Assistant.
//  ItemsProperties - See ReportsServer.SettingsFormItemsProperties
//  UserSettings - DataCompositionUserSettingsItemCollection - items of current
//                              user settings that affect the creation of linked form items.
//
Procedure OnDefineSettingsFormItemsProperties(FormType, ItemsProperties, UserSettings) Export 
	If FormType <> ReportFormType.Main Then 
		Return;
	EndIf;
	
	GroupProperties = ReportsServer.FormItemsGroupProperties();
	GroupProperties.Group = ChildFormItemsGroup.AlwaysHorizontal;
	ItemsProperties.Groups.Insert("FixedParameters", GroupProperties);
	
	FixedParameters = New Structure("Period, MetadataObjectType, MetadataObjectName, TableName");
	MarginWidth = New Structure("MetadataObjectType, MetadataObjectName, TableName", 20, 35, 20);
	
	For Each SettingItem In UserSettings Do 
		If TypeOf(SettingItem) <> Type("DataCompositionSettingsParameterValue")
			Or Not FixedParameters.Property(SettingItem.Parameter) Then 
			Continue;
		EndIf;
		
		FieldProperties = ItemsProperties.Fields.Find(
			SettingItem.UserSettingID, "SettingID");
		
		If FieldProperties = Undefined Then 
			Continue;
		EndIf;
		
		FieldProperties.GroupID = "FixedParameters";
		
		ParameterName = String(SettingItem.Parameter);
		If ParameterName <> "Period" Then 
			FieldProperties.TitleLocation = FormItemTitleLocation.None;
			FieldProperties.Width = MarginWidth[ParameterName];
			FieldProperties.HorizontalStretch = False;
		EndIf;
	EndDo;
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region EventsHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	Settings = SettingsComposer.GetSettings();
	
	Reports.UniversalReport.OutputSubordinateRecordsCount(Settings, DataCompositionSchema, StandardProcessing);
	
	If StandardProcessing Then 
		Return;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, Settings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,, DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region Private

// Returns binary data hash.
//
// Parameters:
//   BinaryData - BinaryData - data, from which hash is calculated.
//
Function BinaryDataHash(BinaryData)
	DataHashing = New DataHashing(HashFunction.MD5);
	DataHashing.Append(BinaryData);
	Return StrReplace(DataHashing.HashSum, " ", "") + "_" + Format(BinaryData.Size(), "NG=");
EndFunction

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf