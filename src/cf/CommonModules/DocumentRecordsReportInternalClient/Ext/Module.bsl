///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// 
// 
//
// Parameters:
//   ReportForm          - ClientApplicationForm -  report form.
//   Item              - FormField        -  table document.
//   Area              - SpreadsheetDocumentRange -  selected value.
//   StandardProcessing - Boolean -  indicates whether standard event processing is being performed.
//
Procedure SpreadsheetDocumentSelectionHandler(ReportForm, Item, Area, StandardProcessing) Export
	
	If ReportForm.ReportSettings.FullName = "Report.DocumentRegisterRecords" Then
		
		If Area.AreaType = SpreadsheetDocumentCellAreaType.Rectangle
			And TypeOf(Area.Details) = Type("Structure") Then
			OpenRegisterFormFromRecordsReport(ReportForm, Area.Details, StandardProcessing);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Opens the register form with selection by Registrar
//
// Parameters:
//   ReportForm      - ClientApplicationForm -  report form.
//   Details      - Structure:
//      * RegisterType - 
//      * RegisterName - 
//      * Recorder - 
//                      
//   StandardProcessing - Boolean  -  indicates whether standard (system) event processing is performed.
//
Procedure OpenRegisterFormFromRecordsReport(ReportForm, Details, StandardProcessing)

	StandardProcessing = False;
	
	UserSettings    = New DataCompositionUserSettings;
	Filter                        = UserSettings.Items.Add(Type("DataCompositionFilter"));
	FilterElement                = Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = New DataCompositionField(Details.RecorderFieldName);
	FilterElement.RightValue = Details.Recorder;
	FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterElement.Use  = True;
	
	RegisterFormName = StringFunctionsClientServer.SubstituteParametersToString("%1.%2.ListForm",
		Details.RegisterType, Details.RegisterName);
	
	RegisterForm = GetForm(RegisterFormName);
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Field",          Details.RecorderFieldName);
	FilterParameters.Insert("Value",      Details.Recorder);
	FilterParameters.Insert("ComparisonType",  DataCompositionComparisonType.Equal);
	FilterParameters.Insert("Use", True);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ToUserSettings", True);
	AdditionalParameters.Insert("ReplaceCurrent",       True);
	
	AddFilter(RegisterForm.List.SettingsComposer, FilterParameters, AdditionalParameters);
	
	RegisterForm.Open();
	
EndProcedure

// Adds a selection to the linker's selection collection or selection group
//
// Parameters:
//   StructureItem        - DataCompositionSettingsComposer
//                           - DataCompositionSettings - 
//   FilterParameters         - Structure - :
//     * Field                - String -  name of the field to add the selection to.
//     * Value            - Arbitrary -  CD selection value (default: Undefined).
//     * ComparisonType        - DataCompositionComparisonType -  type of CD comparisons (default: Undefined).
//     * Use       - Boolean -  indicates whether selection is used (default: True).
//   AdditionalParameters - Structure - :
//     * ToUserSettings - Boolean -  whether to add a CD to the user settings (by default: Lie).
//     * ReplaceCurrent       - Boolean -  indicates whether the existing selection by field is completely replaced (default: True).
//
// Returns:
//   DataCompositionFilterItem - 
//
Function AddFilter(StructureItem, FilterParameters, AdditionalParameters = Undefined)
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ToUserSettings", False);
		AdditionalParameters.Insert("ReplaceCurrent",       True);
	Else
		If Not AdditionalParameters.Property("ToUserSettings") Then
			AdditionalParameters.Insert("ToUserSettings", False);
		EndIf;
		If Not AdditionalParameters.Property("ReplaceCurrent") Then
			AdditionalParameters.Insert("ReplaceCurrent", True);
		EndIf;
	EndIf;
	
	If TypeOf(FilterParameters.Field) = Type("String") Then
		NewField = New DataCompositionField(FilterParameters.Field);
	Else
		NewField = FilterParameters.Field;
	EndIf;
	
	ExistingUserSettingID = Undefined;
	
	If TypeOf(StructureItem) = Type("DataCompositionSettingsComposer") Then
		Filter = StructureItem.Settings.Filter;
		
		If AdditionalParameters.ToUserSettings Then
			
			For Each Item In Filter.Items Do
				If Item.LeftValue = NewField Then
					ExistingUserSettingID = Item.UserSettingID;
					ExistingFilter = Item;
					Break;
				EndIf;
			EndDo;
			
			For Each SettingItem In StructureItem.UserSettings.Items Do
				If SettingItem.UserSettingID =
					StructureItem.Settings.Filter.UserSettingID Then
					Filter = SettingItem;
				EndIf;
			EndDo;
		EndIf;
	
	ElsIf TypeOf(StructureItem) = Type("DataCompositionSettings") Then
		Filter = StructureItem.Filter;
	Else
		Filter = StructureItem;
	EndIf;
	
	FilterElement = Undefined;
	If AdditionalParameters.ReplaceCurrent Then
		For Each Item In Filter.Items Do
	
			If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then
				Continue;
			EndIf;
	
			If Item.LeftValue = NewField Then
				FilterElement = Item;
			EndIf;
	
		EndDo;
		
		If ExistingUserSettingID <> Undefined Then
			FilterElement = ExistingFilter;
			For Each Item In StructureItem.UserSettings.Items Do
				If Item.UserSettingID = ExistingUserSettingID Then
					Item.Use  = FilterParameters.Use;
					Item.ComparisonType   = ?(FilterParameters.ComparisonType = Undefined, DataCompositionComparisonType.Equal,
						FilterParameters.ComparisonType);
					Item.RightValue = FilterParameters.Value;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	If FilterElement = Undefined Then
		FilterElement = Filter.Items.Add(Type("DataCompositionFilterItem"));
	EndIf;
	FilterElement.Use  = FilterParameters.Use;
	FilterElement.LeftValue  = NewField;
	FilterElement.ComparisonType   = ?(FilterParameters.ComparisonType = Undefined, DataCompositionComparisonType.Equal,
		FilterParameters.ComparisonType);
	FilterElement.RightValue = FilterParameters.Value;
	
	Return FilterElement;
	
EndFunction

#EndRegion