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

	Settings.GenerateImmediately = True;
	Settings.Print.TopMargin = 5;
	Settings.Print.LeftMargin = 5;
	Settings.Print.BottomMargin = 5;
	Settings.Print.RightMargin = 5;
	
	Settings.Events.OnCreateAtServer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm -  report form.
//   Cancel - Boolean -  it is passed from the parameters of the standard handler to the server "as is".
//   StandardProcessing - Boolean -  it is passed from the parameters of the standard handler to the server "as is".
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Return;
	EndIf;
	
	// 
	If Users.IsFullUser() Then
		ModuleReportsServer = Common.CommonModule("ReportsServer");
		Command = Form.Commands.Add("ExtendActionSignatures");
		Command.Action  = "Attachable_Command";
		Command.Title = NStr("en = 'Renew signatures.';");
		Command.ToolTip = NStr("en = 'Renew signatures.';");
		ModuleReportsServer.OutputCommand(Form, Command, "Settings");
	EndIf;
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion
	
#Region EventHandlers

// Parameters:
//  ResultDocument - SpreadsheetDocument
//  DetailsData - DataCompositionDetailsData
//  StandardProcessing - Boolean
//
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ComposerSettings = SettingsComposer.GetSettings();
	
	If Not ComposerSettings.AdditionalProperties.Property("VariantKey") Then
		QueryOptions = New Structure;
		QueryOptions.Insert("RequireImprovementSignatures", True);
		QueryOptions.Insert("RequiredAddArchiveTags", True);
		QueryOptions.Insert("rawsignatures", True);
	Else
		QueryOptions = New Structure;
		QueryOptions.Insert(ComposerSettings.AdditionalProperties.VariantKey, True);
	EndIf;
	
	Query = DigitalSignatureInternal.RequestForExtensionSignatureCredibility(QueryOptions);
	DigitalSignatures = Query.Execute().Unload();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ComposerSettings, DetailsData);
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("DigitalSignatures", DigitalSignatures);
		
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion
	
#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf