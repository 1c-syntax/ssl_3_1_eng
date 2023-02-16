///////////////////////////////////////////////////////////////////////////////////////////////////////
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

// StandardSubsystems.BatchEditObjects

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("LongDesc");
	Result.Add("Author");
	Result.Add("AuthorOnly");
	
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowRead
	|WHERE
	|	Custom = FALSE
	|	OR AuthorOnly = FALSE
	|	OR IsAuthorizedUser(Author)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	IsAuthorizedUser(Author)";
	
	Restriction.TextForExternalUsers1 = Restriction.Text;
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf

#Region EventsHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	// 
	// 
	If FormType = "ObjectForm" Then
		OptionRef1 = CommonClientServer.StructureProperty(Parameters, "Key");
		If Not ValueIsFilled(OptionRef1) Then
			Raise NStr("en = 'You can create a report option only from a report form.';");
		EndIf;
		
		OpeningParameters = ReportsOptions.OpeningParameters(OptionRef1);
		
		ReportsOptionsClientServer.AddKeyToStructure(OpeningParameters, "RunMeasurements", False);
		
		If OpeningParameters.ReportType = "BuiltIn" Or OpeningParameters.ReportType = "Extension" Then
			Kind = "Report";
		ElsIf OpeningParameters.ReportType = "Additional" Then
			Kind = "ExternalReport";
			If Not OpeningParameters.Property("Connected") Then
				ReportsOptions.OnAttachReport(OpeningParameters);
			EndIf;
			If Not OpeningParameters.Connected Then
				Raise NStr("en = 'You can open an external report option only from a report form.';");
			EndIf;
		Else
			Raise NStr("en = 'You can open an external report option only from a report form.';");
		EndIf;
		
		FullReportName = Kind + "." + OpeningParameters.ReportName;
		
		UniqueKey = ReportsClientServer.UniqueKey(FullReportName, OpeningParameters.VariantKey);
		OpeningParameters.Insert("PrintParametersKey",        UniqueKey);
		OpeningParameters.Insert("WindowOptionsKey", UniqueKey);
		
		StandardProcessing = False;
		If OpeningParameters.ReportType = "Additional" Then // 
			SelectedForm = "Catalog.ReportsOptions.ObjectForm";
			Parameters.Insert("ReportFormOpeningParameters", OpeningParameters);
			Return;
		EndIf;
		SelectedForm = FullReportName + ".Form";
		CommonClientServer.SupplementStructure(Parameters, OpeningParameters);
	EndIf;
EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	Fields.Add("Description");
	Fields.Add("Ref");
	Fields.Add("Custom");
	Fields.Add("PredefinedOption");
	Fields.Add("ReportType");
	StandardProcessing = False;
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If ReportsOptionsServerCall.IsPredefinedReportOption(Data) Then
		Data.Ref = Data.PredefinedOption;
	EndIf;
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNativeLanguagesSupportClientServer = Common.CommonModule("NationalLanguageSupportClientServer");
		ModuleNativeLanguagesSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	EndIf;
#Else
	If CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNativeLanguagesSupportClientServer = CommonClient.CommonModule("NationalLanguageSupportClientServer");
		ModuleNativeLanguagesSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	EndIf;
#EndIf
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Update handlers.

// Registers data for an update in the InfobaseUpdate exchange plan.
//  See application development standards: Parallel mode of deferred update.
//
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export 
	Query = New Query("
	|SELECT
	|	Variants.Ref
	|FROM
	|	Catalog.ReportsOptions AS Variants
	|WHERE
	|	Variants.Report = &UniversalReport
	|	AND Variants.Custom
	|");
	UniversalReport = Common.MetadataObjectID(Metadata.Reports.UniversalReport);
	Query.SetParameter("UniversalReport", UniversalReport);
	
	References = Query.Execute().Unload().UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, References);
EndProcedure

// Processes data registered in the InfobaseUpdate exchange plan
//  see application development standards and methods: parallel mode of deferred update.
//
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export 
	MetadataObject = Metadata.Catalogs.ReportsOptions;
	FullObjectName = MetadataObject.FullName();
	
	Processed = 0;
	Declined = 0;
	
	Variant = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, FullObjectName);
	While Variant.Next() Do 
		Try
			Reports.UniversalReport.DetermineOptionDataSource(Variant.Ref);
			Processed = Processed + 1;
		Except
			// 
			Declined = Declined + 1;
			
			CommentTemplate = NStr("en = 'Cannot identify the data source for report option %1.
				|It might be corrupted and cannot be recovered.
				|
				|Details: %2.';");
			Comment = StringFunctionsClientServer.SubstituteParametersToString(
				CommentTemplate, Variant.Ref, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(
				InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				MetadataObject,
				Variant.Ref,
				Comment);
		EndTry;
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	If Processed = 0 And Declined <> 0 Then
		MessageTemplate = NStr("en = 'Couldn''t process (skipped) some report options: %1';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, Declined);
		
		Raise MessageText;
	Else
		CommentTemplate = NStr("en = 'Yet another batch of report options is processed: %1';");
		Comment = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, Processed);
		WriteLogEvent(
			InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Information,
			MetadataObject,,
			Comment);
	EndIf;
EndProcedure

#EndRegion

#EndIf