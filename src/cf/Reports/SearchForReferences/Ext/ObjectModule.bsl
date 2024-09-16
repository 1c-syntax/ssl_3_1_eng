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
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	
	// 
	Settings = SettingsComposer.GetSettings();
	RefSet = Settings.DataParameters.FindParameterValue( New DataCompositionParameter("RefSet") );
	If RefSet <> Undefined Then
		RefSet = RefSet.Value;
	EndIf;
	Title = TitleByRefSet(RefSet);
	SettingsComposer.FixedSettings.OutputParameters.SetParameterValue("Title", Title);
	
	CompositionProcessor = CompositionProcessor(DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
EndProcedure

#EndRegion

#Region Private

Function CompositionProcessor(DetailsData = Undefined, GeneratorType = "DataCompositionTemplateGenerator")
	
	Settings = SettingsComposer.GetSettings();
	
	// 
	ParameterValue = Settings.DataParameters.FindParameterValue( New DataCompositionParameter("RefSet") ).Value;
	ValueType = TypeOf(ParameterValue);
	If ValueType = Type("ValueList") Then
		ReferencesArrray = ParameterValue.UnloadValues();
	ElsIf ValueType = Type("Array") Then
		ReferencesArrray = ParameterValue;
	Else
		ReferencesArrray = New Array;
		If ParameterValue <>Undefined Then
			ReferencesArrray.Add(ParameterValue);
		EndIf;
	EndIf;
	
	// 
	For Each OutputParameter In SettingsComposer.FixedSettings.OutputParameters.Items Do
		If OutputParameter.Use Then
			Item = Settings.OutputParameters.FindParameterValue(OutputParameter.Parameter);
			If Item <> Undefined Then
				Item.Use = True;
				Item.Value      = OutputParameter.Value;
			EndIf;
		EndIf;
	EndDo;
	
	// 
	UsageInstances = Common.UsageInstances(ReferencesArrray);
	
	// 
	For Each Ref In ReferencesArrray Do
		If UsageInstances.Find(Ref, "Ref") = Undefined Then
			More = UsageInstances.Add();
			More.Ref = Ref;
			More.AuxiliaryData = True;
		EndIf;
	EndDo;
		
	ExternalData = New Structure;
	ExternalData.Insert("UsageInstances", UsageInstances);
	
	// Perform
	TemplateComposer = New DataCompositionTemplateComposer;
	Template = TemplateComposer.Execute(DataCompositionSchema, Settings, DetailsData, , Type(GeneratorType));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Template, ExternalData, DetailsData);
	
	Return CompositionProcessor;
EndFunction

Function TitleByRefSet(Val RefSet)

	If TypeOf(RefSet) = Type("ValueList") Then
		TotalRefs = RefSet.Count();
		If TotalRefs = 1 Then
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Occurrences of %1';"), Common.SubjectString(RefSet[0].Value));
		ElsIf TotalRefs > 1 Then
		
			EqualType = True;
			FirstRefType = TypeOf(RefSet[0].Value);
			For Position = 0 To TotalRefs - 1 Do
				If TypeOf(RefSet[Position].Value) <> FirstRefType Then
					EqualType = False;
					Break;
				EndIf;
			EndDo;
			
			If EqualType Then
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Occurrences of %1 (%2)';"), 
					RefSet[0].Value.Metadata().Presentation(),
					TotalRefs);
			Else		
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Occurrences (%1)';"), 
					TotalRefs);
			EndIf;
		EndIf;
		
	EndIf;
		
	Return NStr("en = 'Item occurrences';");

EndFunction

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf