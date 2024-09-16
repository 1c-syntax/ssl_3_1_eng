///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Additional default report settings that define:
//  * Whether the report is generated when opened;
//  * Plug-in event handlers;
//  * Print setting;
//  * Using the calculated indicators function;
//  * Rights.
//
// Returns:
//   Structure - :
//       
//       * GenerateImmediately - Boolean -  the default value for the "Generate immediately" checkbox.
//           When this option is enabled, the report will be generated after opening,
//           after selecting user settings, or after selecting a different report option.
//       
//       * OutputSelectedCellsTotal - Boolean -  if True, the auto-sum field will be displayed in the report.
//       
//       * EditStructureAllowed - Boolean -  if False, the "Structure" tab will be hidden in the report settings.
//           If True, the "Structure" tab is displayed for reports on the SKD: in advanced mode,
//           as well as in simple mode, if the use of groupings check boxes are displayed in the user settings.
//       
//       * EditOptionsAllowed - Boolean -  if False, the buttons for changing the report options are blocked. 
//           If the current user does not have the rights to "save user Data" and "Add" 
//           the reference list of report Options, it is forcibly set to False.
//
//       * SelectAndEditOptionsWithoutSavingAllowed - Boolean -  if True,
//           you can select and configure predefined report options, but you can't save 
//           your settings. For example, it can be set for contextual reports (opened with parameters) 
//           that have several options.
//
//       * ControlItemsPlacementParameters - Structure
//                                                  - Undefined - Variants:
//           - Undefined - 
//           - Structure - 
//                         :
//               ** Filter           - Array -  like the next property.
//               ** DataParameters - Structure - :
//                    *** Field                     - String -  name of the field to display.
//                    *** HorizontalStretch - Boolean -  value of the form field property.
//                    *** AutoMaxWidth   - Boolean -  value of the form field property.
//                    *** Width                   - Number  - 
//
//            :
//
//               
//               
//               
//               
//               
//               
//
//               
//
//               
//               
//
//               
//
//       * ImportSettingsOnChangeParameters - Array - 
//                                                    
//                                                    
//
//               :
//               
//               
//               
//               
//
//                
//               
//               
//               
//               
//               //		
//               
//               
//
//               
//               
//               
//               
//                
//               
//               
//
//       * SearchFields - Array of String -  a collection of names of data layout fields that participate in universal search.
//       * PeriodRepresentationOption - EnumRef.PeriodPresentationOptions -  defines a variant
//           of the period representation on the report form.
//       * PeriodVariant - EnumRef.PeriodOptions -  defines a variant of the period selection form.
//       * DisableStandardContextMenu - Boolean - 
//           
//       * HideBulkEmailCommands - Boolean - 
//           
//       * Print - Structure - :
//           ** TopMargin - Number -  top indent when printing (in millimeters).
//           ** LeftMargin  - Number -  left margin when printing (in millimeters).
//           ** BottomMargin  - Number -  bottom indent when printing (in millimeters).
//           ** RightMargin - Number -  indent to the right when printing (in millimeters).
//           ** PageOrientation - PageOrientation -  "Portrait" or "Landscape".
//           ** FitToPage - Boolean -  automatically adjust the zoom to the page size.
//           ** PrintScale - Number -  scale of the image (in percent).
//       * Events - Structure - :
//           ** OnCreateAtServer - Boolean - 
//               :
//               
//               // See ReportsOverridable.OnCreateAtServer.
//               
//               	
//               
//           
//           ** BeforeImportSettingsToComposer - Boolean - 
//               :
//               
//               
//               
//               
//               
//               
//               
//               //
//               
//               	
//               
//           
//           ** AfterLoadSettingsInLinker - Boolean - 
//               :
//               
//               
//               
//               //
//               
//               	
//               
//           
//           ** BeforeLoadVariantAtServer - Boolean - 
//               :
//               
//               // See ReportsOverridable.BeforeLoadVariantAtServer.
//               
//               	
//               
//           
//           ** OnLoadVariantAtServer - Boolean - 
//               :
//               
//               
//               
//               
//               
//               
//               
//               //
//               
//               	
//               
//           
//           ** OnLoadUserSettingsAtServer - Boolean - 
//               :
//               
//               
//               
//               
//               //
//               
//               	
//               
//           
//           ** BeforeFillQuickSettingsBar - Boolean - 
//               :
//               
//               
//               
//               
//               //
//               
//               	
//               
//           
//           ** AfterQuickSettingsBarFilled - Boolean - 
//               :
//               
//               
//               
//               
//               //
//               
//               	
//               
//           
//           ** OnDefineSelectionParameters - Boolean - 
//               :
//               
//               // See ReportsOverridable.OnDefineSelectionParameters.
//               
//               	
//               
//           
//           ** OnDefineUsedTables - Boolean - 
//               :
//               
//               
//               
//               
//               //
//               
//               	
//               
//           
//           ** WhenDefiningTheMainFields - Boolean - 
//               :
//               
//               // See ReportsOverridable.WhenDefiningTheMainFields.
//                
//               	
//               
//           
//           ** BeforeFormationReport - Boolean - 
//               :
//               
//               
//               
//               
//               
//               
//               //
//               
//               	
//               
//
Function DefaultReportSettings() Export
	Settings = New Structure;
	Settings.Insert("GenerateImmediately", False);
	Settings.Insert("OutputSelectedCellsTotal", True);
	Settings.Insert("EditStructureAllowed", True);
	Settings.Insert("EditOptionsAllowed", True);
	Settings.Insert("SelectAndEditOptionsWithoutSavingAllowed", False);
	Settings.Insert("ControlItemsPlacementParameters", Undefined);
	Settings.Insert("HideBulkEmailCommands", False);
	Settings.Insert("ImportSchemaAllowed", False);
	Settings.Insert("EditSchemaAllowed", False);
	Settings.Insert("RestoreStandardSchemaAllowed", False);
	Settings.Insert("ImportSettingsOnChangeParameters", New Array);
	Settings.Insert("SearchFields", New Array);
	Settings.Insert("PeriodRepresentationOption", PredefinedValue("Enum.PeriodPresentationOptions.Standard"));
	Settings.Insert("PeriodVariant", PredefinedValue("Enum.PeriodOptions.Standard"));
	Settings.Insert("DisableStandardContextMenu", False);
	
	Print = New Structure;
	Print.Insert("TopMargin", 10);
	Print.Insert("LeftMargin", 10);
	Print.Insert("BottomMargin", 10);
	Print.Insert("RightMargin", 10);
	Print.Insert("PageOrientation", PageOrientation.Portrait);
	Print.Insert("FitToPage", True);
	Print.Insert("PrintScale", Undefined);
	
	Settings.Insert("Print", Print);
	
	Events = New Structure;
	Events.Insert("OnCreateAtServer", False);
	Events.Insert("BeforeImportSettingsToComposer", False);
	Events.Insert("AfterLoadSettingsInLinker", False);
	Events.Insert("BeforeLoadVariantAtServer", False);
	Events.Insert("OnLoadVariantAtServer", False);
	Events.Insert("OnLoadUserSettingsAtServer", False);
	Events.Insert("BeforeFillQuickSettingsBar", False);
	Events.Insert("AfterQuickSettingsBarFilled", False);
	Events.Insert("OnDefineSelectionParameters", False);
	Events.Insert("OnDefineUsedTables", False);
	Events.Insert("OnDefineSettingsFormItemsProperties", False);
	Events.Insert("WhenDefiningTheMainFields", False);
	Events.Insert("BeforeFormationReport", False);
	
	Settings.Insert("Events", Events);
	
	Return Settings;
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
//
// Returns:
//   Structure:
//
Function GetDefaultReportSettings() Export
	Return DefaultReportSettings();
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Returns:
//  String
//
Function CommandNamePrefixWithReportOptionPreSave() Export
	
	Return "SaveVariant" + "_";
	
EndFunction

// Finds a parameter in the layout settings by its name.
// If the user setting does not exist (for example, if the parameter is not displayed in the user settings),
// it searches for the parameter value in the option settings.
//
// Parameters:
//   DCSettings - DataCompositionSettings
//               - Undefined -
//       
//   DCUserSettings - DataCompositionUserSettings
//                               - Undefined -
//       
//   ParameterName - String -  parameter name. Must meet the requirements for forming variable names.
//
// Returns:
//   Structure - :
//       
//       
//
Function FindParameter(DCSettings, DCUserSettings, ParameterName) Export
	Return FindParameters(DCSettings, DCUserSettings, ParameterName)[ParameterName];
EndFunction

// Finds the General setting by the user setting ID.
//
// Parameters:
//   Settings - DataCompositionSettings -  collections of settings.
//   Id - String -  ID of the user setting.
//   Hierarchy - Array -  collection of data layout structure settings.
//   UserSettings - DataCompositionUserSettings -  collection of user settings.
//
Function GetObjectByUserID(Settings, Id, Hierarchy = Undefined, UserSettings = Undefined) Export
	If Hierarchy = Undefined
		And TypeOf(UserSettings) = Type("DataCompositionUserSettings") Then 
		
		FoundItems1 =
			UserSettings.GetMainSettingsByUserSettingID(Id);
		
		If FoundItems1.Count() > 0 Then 
			Return FoundItems1[0];
		EndIf;
	EndIf;
	
	If Hierarchy <> Undefined Then
		Hierarchy.Add(Settings);
	EndIf;
	
	SettingType = TypeOf(Settings);
	
	If SettingType <> Type("DataCompositionSettings") Then
		
		If Settings.UserSettingID = Id Then
			
			Return Settings;
			
		ElsIf SettingType = Type("DataCompositionNestedObjectSettings") Then
			
			Return GetObjectByUserID(Settings.Settings, Id, Hierarchy);
			
		ElsIf SettingType = Type("DataCompositionTableStructureItemCollection")
			Or SettingType = Type("DataCompositionChartStructureItemCollection")
			Or SettingType = Type("DataCompositionSettingStructureItemCollection") Then
			
			For Each NestedItem In Settings Do
				SearchResult = GetObjectByUserID(NestedItem, Id, Hierarchy);
				If SearchResult <> Undefined Then
					Return SearchResult;
				EndIf;
			EndDo;
			
			If Hierarchy <> Undefined Then
				Hierarchy.Delete(Hierarchy.UBound());
			EndIf;
			
			Return Undefined;
			
		EndIf;
		
	EndIf;
	
	If Settings.Selection.UserSettingID = Id Then
		Return Settings.Selection;
	ElsIf Settings.ConditionalAppearance.UserSettingID = Id Then
		Return Settings.ConditionalAppearance;
	EndIf;
	
	If SettingType <> Type("DataCompositionTable") And SettingType <> Type("DataCompositionChart") Then
		If Settings.Filter.UserSettingID = Id Then
			Return Settings.Filter;
		ElsIf Settings.Order.UserSettingID = Id Then
			Return Settings.Order;
		EndIf;
	EndIf;
	
	If SettingType = Type("DataCompositionSettings") Then
		SearchResult = FindSettingItem(Settings.DataParameters, Id);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
	EndIf;
	
	If SettingType <> Type("DataCompositionTable") And SettingType <> Type("DataCompositionChart") Then
		SearchResult = FindSettingItem(Settings.Filter, Id);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
	EndIf;
	
	SearchResult = FindSettingItem(Settings.ConditionalAppearance, Id);
	If SearchResult <> Undefined Then
		Return SearchResult;
	EndIf;
	
	If SettingType = Type("DataCompositionTable") Then
		
		SearchResult = GetObjectByUserID(Settings.Rows, Id, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
		SearchResult = GetObjectByUserID(Settings.Columns, Id, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
	ElsIf SettingType = Type("DataCompositionChart") Then
		
		SearchResult = GetObjectByUserID(Settings.Points, Id, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
		SearchResult = GetObjectByUserID(Settings.Series, Id, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
	Else
		
		SearchResult = GetObjectByUserID(Settings.Structure, Id, Hierarchy);
		If SearchResult <> Undefined Then
			Return SearchResult;
		EndIf;
		
	EndIf;
	
	If Hierarchy <> Undefined Then
		Hierarchy.Delete(Hierarchy.UBound());
	EndIf;
	
	Return Undefined;
EndFunction

// Finds an available setting for a selection or parameter.
//
// Parameters:
//   Settings - DataCompositionSettings -  collections of settings.
//   SettingItem - DataCompositionFilterItem
//                    - DataCompositionSettingsParameterValue
//                    - DataCompositionNestedObjectSettings - 
//
// Returns:
//   Availablepolecomponsedata, availableparameterscomponsedata,
//       Available objectconfigurationcomposedata-Found available setting.
//   Undefined - if the available setting does not exist.
//
Function FindAvailableSetting(Settings, SettingItem) Export
	Type = TypeOf(SettingItem);
	If Type = Type("DataCompositionFilterItem") Then
		
		FilterElement = SettingItem;
		
		If ValueIsFilled(SettingItem.UserSettingID) Then 
			FilterElement = GetObjectByUserID(
				Settings, SettingItem.UserSettingID);
		EndIf;
		
		Return FindAvailableDCField(Settings, FilterElement.LeftValue);
		
	ElsIf Type = Type("DataCompositionSettingsParameterValue") Then
		
		Return FindAvailableDCParameter(Settings, SettingItem.Parameter);
		
	ElsIf Type = Type("DataCompositionNestedObjectSettings") Then
		
		Return Settings.AvailableObjects.Items.Find(SettingItem.ObjectID);
		
	EndIf;
	
	Return Undefined;
EndFunction

// Finds parameters and selections by value.
//
// Parameters:
//   Settings - DataCompositionUserSettings
//             - Array - 
//               
//   Filter               - Structure:
//       * Use - Boolean -  using the settings.
//       * Value      - Undefined -  setting value.
//   SettingsItems    - Undefined
//                       - DataCompositionUserSettingsItemCollection
//                       - DataCompositionFilterItemCollection - 
//                         
//                         
//   Result           - Array
//                       - Undefined - see the return value.
//
// Returns:
//   Array - 
//
Function SettingsItemsFiltered(Settings, Filter, SettingsItems = Undefined, Result = Undefined) Export
	IsUserSettings = (TypeOf(Settings) = Type("DataCompositionUserSettings"));
	
	If SettingsItems = Undefined Then 
		SettingsItems = ?(IsUserSettings, Settings.Items, Settings);
	EndIf;
	
	If Result = Undefined Then
		Result = New Array;
	EndIf;
	
	For Each Item In SettingsItems Do
		ItemToAnalyse = Undefined;
		
		If IsUserSettings Then 
			ItemToAnalyse = Settings.Items.Find(Item.UserSettingID);
		EndIf;
		
		If ItemToAnalyse = Undefined Then 
			ItemToAnalyse = Item;
		EndIf;
		
		If TypeOf(ItemToAnalyse) = Type("DataCompositionFilterItem") 
			And ItemToAnalyse.Use = Filter.Use
			And ItemToAnalyse.RightValue = Filter.Value Then
			
			Result.Add(ItemToAnalyse);
			
		ElsIf TypeOf(ItemToAnalyse) = Type("DataCompositionSettingsParameterValue") 
			And ItemToAnalyse.Use = Filter.Use
			And ItemToAnalyse.Value = Filter.Value Then
			
			Result.Add(ItemToAnalyse);
			
		ElsIf TypeOf(ItemToAnalyse) = Type("DataCompositionFilter")
			Or TypeOf(ItemToAnalyse) = Type("DataCompositionFilterItemGroup") Then
			
			If ValueIsFilled(ItemToAnalyse.UserSettingID) Then 
				
				FoundItems1 = Settings.GetMainSettingsByUserSettingID(
					ItemToAnalyse.UserSettingID); // DataCompositionFilter, DataCompositionFilterItemGroup
				
				If FoundItems1.Count() > 0 Then
					CurrentSettingsItems = FoundItems1.Get(0); // DataCompositionFilter, DataCompositionFilterItemGroup
					SettingsItemsFiltered(Settings, Filter, CurrentSettingsItems.Items, Result);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

Function SettingItemIndexByPath(Val Path, ItemProperty = Undefined) Export 
	AvailableProperties = StrSplit("Use, Value, List", ", ", False);
	For Each ItemProperty In AvailableProperties Do 
		If StrEndsWith(Path, ItemProperty) Then 
			Break;
		EndIf;
	EndDo;
	
	IndexDetails = New TypeDescription("Number");
	
	ElementIndex = StrReplace(Path, "SettingsComposerUserSettingsItem", "");
	ElementIndex = StrReplace(ElementIndex, ItemProperty, "");
	
	Return IndexDetails.AdjustValue(ElementIndex);
EndFunction

Function SettingTypeAsString(Type) Export
	If Type = Type("DataCompositionSettings") Then
		Return "Settings";
	ElsIf Type = Type("DataCompositionNestedObjectSettings") Then
		Return "NestedObjectSettings";
	
	ElsIf Type = Type("DataCompositionFilter") Then
		Return "Filter";
	ElsIf Type = Type("DataCompositionFilterItem") Then
		Return "FilterElement";
	ElsIf Type = Type("DataCompositionFilterItemGroup") Then
		Return "FilterItemsGroup";
	
	ElsIf Type = Type("DataCompositionSettingsParameterValue") Then
		Return "SettingsParameterValue";
	
	ElsIf Type = Type("DataCompositionGroup") Then
		Return "Group";
	ElsIf Type = Type("DataCompositionGroupFields") Then
		Return "GroupFields";
	ElsIf Type = Type("DataCompositionGroupFieldCollection") Then
		Return "GroupFieldsCollection";
	ElsIf Type = Type("DataCompositionGroupField") Then
		Return "GroupingField";
	ElsIf Type = Type("DataCompositionAutoGroupField") Then
		Return "AutoGroupField";
	
	ElsIf Type = Type("DataCompositionSelectedFields") Then
		Return "SelectedFields";
	ElsIf Type = Type("DataCompositionSelectedField") Then
		Return "SelectedField";
	ElsIf Type = Type("DataCompositionSelectedFieldGroup") Then
		Return "SelectedFieldsGroup";
	ElsIf Type = Type("DataCompositionAutoSelectedField") Then
		Return "AutoSelectedField";
	
	ElsIf Type = Type("DataCompositionOrder") Then
		Return "Order";
	ElsIf Type = Type("DataCompositionOrderItem") Then
		Return "OrderItem";
	ElsIf Type = Type("DataCompositionAutoOrderItem") Then
		Return "AutoOrderItem";
	
	ElsIf Type = Type("DataCompositionConditionalAppearance") Then
		Return "ConditionalAppearance";
	ElsIf Type = Type("DataCompositionConditionalAppearanceItem") Then
		Return "ConditionalAppearanceItem";
	
	ElsIf Type = Type("DataCompositionSettingStructure") Then
		Return "SettingsStructure_";
	ElsIf Type = Type("DataCompositionSettingStructureItemCollection") Then
		Return "SettingsStructureItemCollection";
	
	ElsIf Type = Type("DataCompositionTable") Then
		Return "Table";
	ElsIf Type = Type("DataCompositionTableGroup") Then
		Return "TableGroup";
	ElsIf Type = Type("DataCompositionTableStructureItemCollection") Then
		Return "TableStructureItemCollection";
	
	ElsIf Type = Type("DataCompositionChart") Then
		Return "Chart";
	ElsIf Type = Type("DataCompositionChartGroup") Then
		Return "ChartGroup";
	ElsIf Type = Type("DataCompositionChartStructureItemCollection") Then
		Return "ChartStructureItemCollection";
	
	ElsIf Type = Type("DataCompositionDataParameterValues") Then
		Return "DataParametersValues";
	
	Else
		Return "";
	EndIf;
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated.
Function SupplementList(DestinationList, SourceList, ToControlType = Undefined, AddNewItems = True) Export
	
	If DestinationList = Undefined Or SourceList = Undefined Then
		Return Undefined;
	EndIf;
	
	Return CommonClientServer.SupplementList(DestinationList, SourceList, ToControlType, AddNewItems);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Finds parameters in the layout settings by its name.
// If the parameter does not exist in the user settings, it is searched in the option settings.
//
// Parameters:
//   DCSettings - DataCompositionSettings
//               - Undefined -
//       
//   DCUserSettings - DataCompositionUserSettings
//                               - Undefined -
//       
//   ParameterNames - String -  the names of the parameters separated by commas.
//       The name of each parameter must meet the requirements for creating variable names.
//
// Returns:
//   Structure - :
//       
//       
//
Function FindParameters(DCSettings, DCUserSettings, ParameterNames)
	Result = New Structure;
	RequiredParameters1 = New Map;
	NamesArray = StrSplit(ParameterNames, ",", False);
	Count = 0;
	For Each ParameterName In NamesArray Do
		RequiredParameters1.Insert(TrimAll(ParameterName), True);
		Count = Count + 1;
	EndDo;
	
	If DCUserSettings <> Undefined Then
		For Each DCItem In DCUserSettings.Items Do
			If TypeOf(DCItem) = Type("DataCompositionSettingsParameterValue") Then
				ParameterName = String(DCItem.Parameter);
				If RequiredParameters1[ParameterName] = True Then
					Result.Insert(ParameterName, DCItem);
					RequiredParameters1.Delete(ParameterName);
					Count = Count - 1;
					If Count = 0 Then
						Break;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	If Count > 0 Then
		For Each KeyAndValue In RequiredParameters1 Do
			If DCSettings <> Undefined Then
				DCItem = DCSettings.DataParameters.Items.Find(KeyAndValue.Key);
			Else
				DCItem = Undefined;
			EndIf;
			Result.Insert(KeyAndValue.Key, DCItem);
		EndDo;
	EndIf;
	
	Return Result;
EndFunction

// Finds the available setting for the data layout field.
//
// Parameters:
//   DCSettings - DataCompositionSettings
//               - DataCompositionGroup - 
//   
//        - DataCompositionField -  field name.
//
// Returns:
//   DataCompositionAvailableField
//   Undefined - when an available field setting does not exist.
//
Function FindAvailableDCField(DCSettings, DCField)
	If DCField = Undefined Then
		Return Undefined;
	EndIf;
	
	If TypeOf(DCSettings) = Type("DataCompositionGroup")
		Or TypeOf(DCSettings) = Type("DataCompositionTableGroup")
		Or TypeOf(DCSettings) = Type("DataCompositionChartGroup") Then
		
		AvailableSetting = DCSettings.Filter.FilterAvailableFields.FindField(DCField);
	Else
		AvailableSetting = DCSettings.FilterAvailableFields.FindField(DCField);
	EndIf;
	
	If AvailableSetting <> Undefined Then
		Return AvailableSetting;
	EndIf;
	
	StructuresArray = New Array;
	StructuresArray.Add(DCSettings.Structure);
	While StructuresArray.Count() > 0 Do
		
		DCStructure = StructuresArray[0];
		StructuresArray.Delete(0);
		
		For Each DCStructureItem In DCStructure Do
			
			If TypeOf(DCStructureItem) = Type("DataCompositionNestedObjectSettings") Then
				
				AvailableSetting = DCStructureItem.Settings.FilterAvailableFields.FindField(DCField);
				If AvailableSetting <> Undefined Then
					Return AvailableSetting;
				EndIf;
				
				StructuresArray.Add(DCStructureItem.Settings.Structure);
				
			ElsIf TypeOf(DCStructureItem) = Type("DataCompositionGroup") Then
				
				AvailableSetting = DCStructureItem.Filter.FilterAvailableFields.FindField(DCField);
				If AvailableSetting <> Undefined Then
					Return AvailableSetting;
				EndIf;
				
				StructuresArray.Add(DCStructureItem.Structure);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return Undefined;
EndFunction

// Finds an available setting for the data layout parameter.
//
// Parameters:
//   DCSettings - DataCompositionSettings -  collections of settings.
//   DCParameter - DataCompositionParameter -  parameter name.
//
// Returns:
//   DataCompositionAvailableParameter, Undefined - 
//
Function FindAvailableDCParameter(DCSettings, DCParameter)
	If DCParameter = Undefined Then
		Return Undefined;
	EndIf;
	
	If DCSettings.DataParameters.AvailableParameters <> Undefined Then
		// 
		AvailableSetting = DCSettings.DataParameters.AvailableParameters.FindParameter(DCParameter);
		If AvailableSetting <> Undefined Then
			Return AvailableSetting;
		EndIf;
	EndIf;
	
	StructuresArray = New Array;
	StructuresArray.Add(DCSettings.Structure);
	While StructuresArray.Count() > 0 Do
		
		DCStructure = StructuresArray[0];
		StructuresArray.Delete(0);
		
		For Each DCStructureItem In DCStructure Do
			
			If TypeOf(DCStructureItem) = Type("DataCompositionNestedObjectSettings") Then
				
				If DCStructureItem.Settings.DataParameters.AvailableParameters <> Undefined Then
					// 
					AvailableSetting = DCStructureItem.Settings.DataParameters.AvailableParameters.FindParameter(DCParameter);
					If AvailableSetting <> Undefined Then
						Return AvailableSetting;
					EndIf;
				EndIf;
				
				StructuresArray.Add(DCStructureItem.Settings.Structure);
				
			ElsIf TypeOf(DCStructureItem) = Type("DataCompositionGroup") Then
				
				StructuresArray.Add(DCStructureItem.Structure);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return Undefined;
EndFunction

// Defines values of the Groupelements type depending on the type of comparison (priority) or the original value.
//
// Parameters:
//  Condition - DataCompositionComparisonType
//          - Undefined - 
//  
//                   - FoldersAndItems - 
//                     
//
// Returns:
//   FoldersAndItems - 
//
Function GroupsAndItemsTypeValue(SourceValue, Condition = Undefined) Export
	If Condition <> Undefined Then 
		If Condition = DataCompositionComparisonType.InListByHierarchy
			Or Condition = DataCompositionComparisonType.NotInListByHierarchy Then 
			If SourceValue = FoldersAndItems.Folders
				Or SourceValue = FoldersAndItemsUse.Folders Then 
				Return FoldersAndItems.Folders;
			Else
				Return FoldersAndItems.FoldersAndItems;
			EndIf;
		ElsIf Condition = DataCompositionComparisonType.InHierarchy
			Or Condition = DataCompositionComparisonType.NotInHierarchy Then 
			Return FoldersAndItems.Folders;
		EndIf;
	EndIf;
	
	If TypeOf(SourceValue) = Type("FoldersAndItems") Then 
		Return SourceValue;
	ElsIf SourceValue = FoldersAndItemsUse.Items Then
		Return FoldersAndItems.Items;
	ElsIf SourceValue = FoldersAndItemsUse.FoldersAndItems Then
		Return FoldersAndItems.FoldersAndItems;
	ElsIf SourceValue = FoldersAndItemsUse.Folders Then
		Return FoldersAndItems.Folders;
	EndIf;
	
	Return FoldersAndItems.Auto;
EndFunction

// Loads new settings to the linker without resetting user settings.
//
// Parameters:
//  SettingsComposer - DataCompositionSettingsComposer -  where to upload the settings.
//  Settings - DataCompositionSettings -  downloadable option settings.
//  UserSettings - DataCompositionUserSettings
//                            - Undefined - 
//                              
//  FixedSettings - DataCompositionSettings
//                         - Undefined - 
//                           
//
Function LoadSettings(SettingsComposer, Settings, UserSettings = Undefined, FixedSettings = Undefined) Export
	SettingsImported = (TypeOf(Settings) = Type("DataCompositionSettings")
		And Settings <> SettingsComposer.Settings);
	
	If SettingsImported Then
		If TypeOf(UserSettings) <> Type("DataCompositionUserSettings") Then
			UserSettings = SettingsComposer.UserSettings;
		EndIf;
		
		If TypeOf(FixedSettings) <> Type("DataCompositionSettings") Then 
			FixedSettings = SettingsComposer.FixedSettings;
		EndIf;
		
		AvailableValues = CommonClientServer.StructureProperty(
			SettingsComposer.Settings.AdditionalProperties, "AvailableValues");
		
		If AvailableValues <> Undefined Then 
			Settings.AdditionalProperties.Insert("AvailableValues", AvailableValues);
		EndIf;
		
		SettingsComposer.LoadSettings(Settings);
	EndIf;
	
	If TypeOf(UserSettings) = Type("DataCompositionUserSettings")
		And UserSettings <> SettingsComposer.UserSettings Then
		SettingsComposer.LoadUserSettings(UserSettings);
	EndIf;
	
	If TypeOf(FixedSettings) = Type("DataCompositionSettings")
		And FixedSettings <> SettingsComposer.FixedSettings Then
		SettingsComposer.LoadFixedSettings(FixedSettings);
	EndIf;
	
	Return SettingsImported;
EndFunction

Procedure NotifyOfSettingsChange(Form) Export 
	
	If Not Form.UserSettingsModified Then 
		Return;
	EndIf;
	
	StateText = NStr("en = 'Settings changed. To run the report, click ""Generate"".';");
	DisplayReportState(Form, StateText);
	
EndProcedure

// Parameters:
//  Form - ClientApplicationForm
//  StateText - String
//  PictureStateValue - Undefined
//
Procedure DisplayReportState(Form, Val StateText = "", Val PictureStateValue = Undefined) Export 
	
	ReportField = Form.Items.Find("ReportSpreadsheetDocument");
	If ReportField = Undefined Then 
		Return;
	EndIf;
	
	ShowStatus = Not IsBlankString(StateText);
	
	If PictureStateValue = Undefined Or Not ShowStatus Then 
		PictureStateValue = New Picture;
	EndIf;
	
	StatePresentation = ReportField.StatePresentation;
	StatePresentation.Visible = ShowStatus;
	StatePresentation.AdditionalShowMode = 
		?(ShowStatus, AdditionalShowMode.Irrelevance, AdditionalShowMode.DontUse);
	StatePresentation.Picture = PictureStateValue;
	StatePresentation.Text = StateText;

	ReportField.ReadOnly = ShowStatus 
		Or ReportField.Output = UseOutput.Disable;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Finds the General configuration of the layout data by ID.
Function FindSettingItem(SettingItem, UserSettingID)
	// 
	
	Groups = New Array;
	Groups.Add(SettingItem.Items);
	IndexOf = 0;
	
	While IndexOf < Groups.Count() Do
		
		ItemsCollection = Groups[IndexOf];
		IndexOf = IndexOf + 1;
		For Each SubordinateItem In ItemsCollection Do
			If TypeOf(SubordinateItem) = Type("DataCompositionSelectedFieldGroup") Then
				// 
			ElsIf TypeOf(SubordinateItem) = Type("DataCompositionParameterValue") Then
				// 
				Groups.Add(SubordinateItem.NestedParameterValues);
			ElsIf SubordinateItem.UserSettingID = UserSettingID Then
				// 
				Return SubordinateItem;
			Else
				// 
				If TypeOf(SubordinateItem) = Type("DataCompositionFilterItemGroup") Then
					Groups.Add(SubordinateItem.Items);
				ElsIf TypeOf(SubordinateItem) = Type("DataCompositionSettingsParameterValue") Then
					Groups.Add(SubordinateItem.NestedParameterValues);
				EndIf;
			EndIf;
		EndDo;
		
	EndDo;
	
	Return Undefined;
EndFunction

// Returns the value of the data parameter for the data layout field.
//
// Parameters:
//  Settings - DataCompositionSettings -  the current report settings.
//  UserSettings - DataCompositionUserSettingsItemCollection  -  current user
//                              settings for the report.
//  Field - DataCompositionField -  the field that is the search criteria.
//
// Returns:
//   DataCompositionParameterValue, Undefined - 
//
Function ChoiceParameterValue(Settings, UserSettings, Field, OptionChangeMode)
	Value = DataParameterValueByField(Settings, UserSettings, Field, OptionChangeMode);
	
	If Value = Undefined Then 
		FilterItems1 = Settings.Filter.Items;
		FindFilterItemsFieldValues(Field, FilterItems1, UserSettings, Value, OptionChangeMode);
	EndIf;
	
	If TypeOf(Value) = Type("StandardBeginningDate") Then 
		Return Value.Date;
	EndIf;
	
	If TypeOf(Value) = Type("StandardPeriod") Then 
		Return Value.EndDate;
	EndIf;
	
	Return Value;
EndFunction

// Returns the value of the data layout parameter found in the data layout field.
//
// Parameters:
//  Settings - DataCompositionSettings -  settings in which the search is performed.
//  UserSettings - DataCompositionUserSettingsItemCollection -  collection of current
//                              user settings.
//
// Returns:
//   DataCompositionParameterValue, Undefined - 
//                                                     
//
Function DataParameterValueByField(Settings, UserSettings, Field, OptionChangeMode)
	If TypeOf(Settings) <> Type("DataCompositionSettings") Then 
		Return Undefined;
	EndIf;
	
	SettingsItems = Settings.DataParameters.Items;
	For Each Item In SettingsItems Do 
		UserItem1 = UserSettings.Find(Item.UserSettingID);
		ItemToAnalyse = ?(OptionChangeMode Or UserItem1 = Undefined, Item, UserItem1);
		
		Fields = New Array;
		Fields.Add(New DataCompositionField(String(Item.Parameter)));
		Fields.Add(New DataCompositionField("DataParameters." + String(Item.Parameter)));
		
		If ItemToAnalyse.Use
			And (Fields[0] = Field Or Fields[1] = Field)
			And ValueIsFilled(ItemToAnalyse.Value)
			And TypeOf(ItemToAnalyse.Value) <> Type("ValueList") Then 
			
			Return ItemToAnalyse.Value;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

Procedure FindFilterItemsFieldValues(Field, FilterItems1, UserSettings, Value, OptionChangeMode)
	If ValueIsFilled(Value) Then 
		Return;
	EndIf;
	
	For Each Item In FilterItems1 Do 
		UserItem1 = UserSettings.Find(Item.UserSettingID);
		ItemToAnalyse = ?(OptionChangeMode Or UserItem1 = Undefined, Item, UserItem1);
		
		If TypeOf(ItemToAnalyse) = Type("DataCompositionFilterItemGroup") Then 
			FindFilterItemsFieldValues(Field, Item.Items, UserSettings, Value, OptionChangeMode);
		Else
			If Item.LeftValue = Field
				And ItemToAnalyse.Use
				And ItemToAnalyse.ComparisonType = DataCompositionComparisonType.Equal
				And ValueIsFilled(ItemToAnalyse.RightValue) Then 
				
				Value = ItemToAnalyse.RightValue; 
				Break;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Returns a representation of the conditional design element.
//
// Parameters:
//  DCItem - DataCompositionConditionalAppearanceItem  -  the design element whose representation you want to define.
//  DCOptionSetting - DataCompositionSettings -  current report option settings.
//
// Returns:
//   String - 
//
Function ConditionalAppearanceItemPresentation(DCItem, DCOptionSetting, State) Export
	AppearancePresentation = AppearancePresentation(DCItem.Appearance);
	If AppearancePresentation = "" Then
		AppearancePresentation = NStr("en = 'No decoration';");
	EndIf;
	InfoFromOptionIsAvailable = (DCOptionSetting <> Undefined And DCOptionSetting <> DCItem);
	
	FieldsPresentation = FormattedFieldsPresentation(DCItem.Fields, State);
	If FieldsPresentation = "" And InfoFromOptionIsAvailable Then
		FieldsPresentation = FormattedFieldsPresentation(DCOptionSetting.Fields, State);
	EndIf;
	If FieldsPresentation = "" Then
		FieldsPresentation = NStr("en = 'All fields';");
	Else
		FieldsPresentation = NStr("en = 'Fields:';") + " " + FieldsPresentation;
	EndIf;
	
	FilterPresentation = FilterPresentation(DCItem.Filter, DCItem.Filter.Items, State);
	If FilterPresentation = "" And InfoFromOptionIsAvailable Then
		FilterPresentation = FilterPresentation(DCOptionSetting.Filter, DCOptionSetting.Filter.Items, State);
	EndIf;
	If FilterPresentation = "" Then
		Separator = "";
	Else
		Separator = "; ";
		FilterPresentation = NStr("en = 'Criteria:';") + " " + FilterPresentation;
	EndIf;
	
	Return AppearancePresentation + " (" + FieldsPresentation + Separator + FilterPresentation + ")";
EndFunction

Function AppearancePresentation(DCAppearance)
	Presentation = "";
	For Each DCItem In DCAppearance.Items Do
		If DCItem.Use Then
			AvailableDCParameter = DCAppearance.AvailableParameters.FindParameter(DCItem.Parameter);
			If AvailableDCParameter <> Undefined And ValueIsFilled(AvailableDCParameter.Title) Then
				KeyPresentation = AvailableDCParameter.Title;
			Else
				KeyPresentation = String(DCItem.Parameter);
			EndIf;
			
			If TypeOf(DCItem.Value) = Type("Color") Then
				ValuePresentation = ColorPresentation(DCItem.Value);
			Else
				ValuePresentation = String(DCItem.Value);
			EndIf;
			
			Presentation = Presentation
				+ ?(Presentation = "", "", ", ")
				+ KeyPresentation
				+ ?(ValuePresentation = "", "", ": " + ValuePresentation);
		EndIf;
	EndDo;
	Return Presentation;
EndFunction

// Parameters:
//  Color - Color
// Returns:
//  String
//
Function ColorPresentation(Color)
	If Color.Type = ColorType.StyleItem Then
		Presentation = String(Color);
		Presentation = Mid(Presentation, StrFind(Presentation, ":")+1);
		Presentation = NameToPresentation(Presentation);
	ElsIf Color.Type = ColorType.WebColor
		Or Color.Type = ColorType.WindowsColor Then
		Presentation = StrLeftBeforeChar(String(Color), " (");
	ElsIf Color.Type = ColorType.Absolute Then
		Presentation = String(Color);
		If Presentation = "0, 0, 0" Then
			Presentation = NStr("en = 'Black';");
		ElsIf Presentation = "255, 255, 255" Then
			Presentation = NStr("en = 'White';");
		EndIf;
	ElsIf Color.Type = ColorType.AutoColor Then
		Presentation = NStr("en = 'Auto';");
	Else
		Presentation = "";
	EndIf;
	Return Presentation;
EndFunction

Function NameToPresentation(Val InitialString)
	Result = "";
	IsFirstSymbol = True;
	For CharacterNumber = 1 To StrLen(InitialString) Do
		CharCode = CharCode(InitialString, CharacterNumber);
		Char = Char(CharCode);
		If IsFirstSymbol Then
			If Not IsBlankString(Char) Then
				Result = Result + Char;
				IsFirstSymbol = False;
			EndIf;
		Else
			If (CharCode >= 65 And CharCode <= 90)
				Or (CharCode >= 1040 And CharCode <= 1071) Then
				Char = " " + Lower(Char);
			ElsIf Char = "_" Then
				Char = " ";
			EndIf;
			Result = Result + Char;
		EndIf;
	EndDo;
	Return Result;
EndFunction

Function FormattedFieldsPresentation(FormattedDCFields, State)
	Presentation = "";
	
	For Each FormattedDCField In FormattedDCFields.Items Do
		If Not FormattedDCField.Use Then
			Continue;
		EndIf;
		
		AvailableDCField = FormattedDCFields.AppearanceFieldsAvailableFields.FindField(FormattedDCField.Field);
		If AvailableDCField = Undefined Then
			State = "DeletionMark";
			FieldPresentation = String(FormattedDCField.Field);
		Else
			If ValueIsFilled(AvailableDCField.Title) Then
				FieldPresentation = AvailableDCField.Title;
			Else
				FieldPresentation = String(FormattedDCField.Field);
			EndIf;
		EndIf;
		Presentation = Presentation + ?(Presentation = "", "", ", ") + FieldPresentation;
		
	EndDo;
	
	Return Presentation;
EndFunction

Function FilterPresentation(DCNode, DCRowSet, State)
	Presentation = "";
	
	For Each DCItem In DCRowSet Do
		If Not DCItem.Use Then
			Continue;
		EndIf;
		
		If TypeOf(DCItem) = Type("DataCompositionFilterItemGroup") Then
			
			GroupPresentation = String(DCItem.GroupType);
			NestedItemsPresentation = FilterPresentation(DCNode, DCItem.Items, State);
			If NestedItemsPresentation = "" Then
				Continue;
			EndIf;
			ItemPresentation = GroupPresentation + "(" + NestedItemsPresentation + ")";
			
		ElsIf TypeOf(DCItem) = Type("DataCompositionFilterItem") Then
			
			AvailableDCFilterField = DCNode.FilterAvailableFields.FindField(DCItem.LeftValue);
			If AvailableDCFilterField = Undefined Then
				State = "DeletionMark";
				FieldPresentation = String(DCItem.LeftValue);
			Else
				If ValueIsFilled(AvailableDCFilterField.Title) Then
					FieldPresentation = AvailableDCFilterField.Title;
				Else
					FieldPresentation = String(DCItem.LeftValue);
				EndIf;
			EndIf;
			
			ValuePresentation = String(DCItem.RightValue);
			
			If DCItem.ComparisonType = DataCompositionComparisonType.Equal Then
				ConditionPresentation = "=";
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotEqual Then
				ConditionPresentation = "<>";
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.Greater Then
				ConditionPresentation = ">";
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual Then
				ConditionPresentation = ">=";
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.Less Then
				ConditionPresentation = "<";
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.LessOrEqual Then
				ConditionPresentation = "<=";
			
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.InHierarchy Then
				ConditionPresentation = NStr("en = 'In group';");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotInHierarchy Then
				ConditionPresentation = NStr("en = 'Not in group';");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.InList Then
				ConditionPresentation = NStr("en = 'In list';");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotInList Then
				ConditionPresentation = NStr("en = 'Not in list';");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.InListByHierarchy Then
				ConditionPresentation = NStr("en = 'In list including subordinate objects';");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
				ConditionPresentation = NStr("en = 'Not in list including subordinate objects';");
			
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.Contains Then
				ConditionPresentation = NStr("en = 'Contains';");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotContains Then
				ConditionPresentation = NStr("en = 'Does not contain';");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.Like Then
				ConditionPresentation = NStr("en = 'Matches pattern';");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotLike Then
				ConditionPresentation = NStr("en = 'Does not match pattern';");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.BeginsWith Then
				ConditionPresentation = NStr("en = 'Begins with';");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotBeginsWith Then
				ConditionPresentation = NStr("en = 'Does not begin with';");
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.Filled Then
				ConditionPresentation = NStr("en = 'Not blank';");
				ValuePresentation = "";
			ElsIf DCItem.ComparisonType = DataCompositionComparisonType.NotFilled Then
				ConditionPresentation = NStr("en = 'Blank';");
				ValuePresentation = "";
			EndIf;
			
			ItemPresentation = TrimAll(FieldPresentation + " " + ConditionPresentation + " " + ValuePresentation);
			
		Else
			Continue;
		EndIf;
		
		Presentation = Presentation + ?(Presentation = "", "", ", ") + ItemPresentation;
		
	EndDo;
	
	Return Presentation;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other

Function CopyRecursive(Val Node, Val WhatToCopy, Val WhereToInsert, Val IndexOf, Map = Undefined, WithoutStructure = False) Export
	If Map = Undefined Then
		Map = New Map;
	EndIf;
	
	ElementType = TypeOf(WhatToCopy);
	CopyingParameters = CopyingParameters(ElementType, WhereToInsert, WithoutStructure);
	
	If CopyingParameters.ItemTypeMustBeSpecified Then
		If IndexOf = Undefined Then
			NewRow = WhereToInsert.Add(ElementType);
		Else
			NewRow = WhereToInsert.Insert(IndexOf, ElementType);
		EndIf;
	Else
		If IndexOf = Undefined Then
			NewRow = WhereToInsert.Add();
		Else
			NewRow = WhereToInsert.Insert(IndexOf);
		EndIf;
	EndIf;
	
	FillPropertiesRecursively(Node, NewRow, WhatToCopy, Map, CopyingParameters);
	
	Return NewRow;
EndFunction

Function CopyingParameters(ElementType, Collection, WithoutStructure = False)
	Result = New Structure;
	Result.Insert("ItemTypeMustBeSpecified", False);
	Result.Insert("ExcludeProperties", Undefined);
	Result.Insert("HasSettings", False);
	Result.Insert("HasItems", False);
	Result.Insert("HasSelection", False);
	Result.Insert("HasFilter", False);
	Result.Insert("HasOutputParameters", False);
	Result.Insert("HasDataParameters", False);
	Result.Insert("HasUserFields", False);
	Result.Insert("HasGroupFields", False);
	Result.Insert("HasOrder", False);
	Result.Insert("HasStructure", False);
	Result.Insert("HasConditionalAppearance", False);
	Result.Insert("HasColumnsAndRows", False);
	Result.Insert("HasSeriesAndDots", False);
	Result.Insert("HasNestedParametersValues", False);
	Result.Insert("HasFieldsAndDecorations", False);
	
	If ElementType = Type("DataCompositionSelectedFieldGroup")
		Or ElementType = Type("DataCompositionFilterItemGroup") Then
		
		Result.ItemTypeMustBeSpecified = True;
		Result.ExcludeProperties = "Parent";
		Result.HasItems = True;
		
	ElsIf ElementType = Type("DataCompositionSelectedField")
		Or ElementType = Type("DataCompositionAutoSelectedField")
		Or ElementType = Type("DataCompositionFilterItem") Then
		
		Result.ExcludeProperties = "Parent";
		Result.ItemTypeMustBeSpecified = True;
		
	ElsIf ElementType = Type("DataCompositionParameterValue")
		Or ElementType = Type("DataCompositionSettingsParameterValue") Then
		
		Result.ExcludeProperties = "Parent";
		
	ElsIf ElementType = Type("DataCompositionGroupField")
		Or ElementType = Type("DataCompositionAutoGroupField")
		Or ElementType = Type("DataCompositionOrderItem")
		Or ElementType = Type("DataCompositionAutoOrderItem") Then
		
		Result.ItemTypeMustBeSpecified = True;
		
	ElsIf ElementType = Type("DataCompositionConditionalAppearanceItem") Then
		
		Result.HasFilter = True;
		Result.HasFieldsAndDecorations = True;
		
	ElsIf ElementType = Type("DataCompositionGroup")
		Or ElementType = Type("DataCompositionTableGroup")
		Or ElementType = Type("DataCompositionChartGroup")Then
		
		Result.ExcludeProperties = "Parent";
		CollectionType = TypeOf(Collection);
		If CollectionType = Type("DataCompositionSettingStructureItemCollection") Then
			Result.ItemTypeMustBeSpecified = True;
			ElementType = Type("DataCompositionGroup"); // 
		EndIf;
		
		Result.HasSelection = True;
		Result.HasFilter = True;
		Result.HasOutputParameters = True;
		Result.HasGroupFields = True;
		Result.HasOrder = True;
		Result.HasStructure = Not WithoutStructure;
		Result.HasConditionalAppearance = True;
		
	ElsIf ElementType = Type("DataCompositionTable") Then
		
		Result.ExcludeProperties = "Parent";
		Result.ItemTypeMustBeSpecified = True;
		
		Result.HasSelection = True;
		Result.HasColumnsAndRows = True;
		Result.HasOutputParameters = True;
		
	ElsIf ElementType = Type("DataCompositionChart") Then
		
		Result.ExcludeProperties = "Parent";
		Result.ItemTypeMustBeSpecified = True;
		
		Result.HasSelection = True;
		Result.HasSeriesAndDots = True;
		Result.HasOutputParameters = True;
		
	ElsIf ElementType = Type("DataCompositionNestedObjectSettings") Then
		
		Result.ExcludeProperties = "Parent";
		Result.ItemTypeMustBeSpecified = True;
		Result.HasSettings = True;
		
		Result.HasSelection = True;
		Result.HasFilter = True;
		Result.HasOutputParameters = True;
		Result.HasDataParameters = True;
		Result.HasUserFields = True;
		Result.HasOrder = True;
		Result.HasStructure = Not WithoutStructure;
		Result.HasConditionalAppearance = True;
		
	ElsIf ElementType <> Type("FormDataTreeItem") Then 
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1 copy is not supported.';"), ElementType);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the configuration element that is filled in based on the same type of element.
//
// Parameters:
//  Node - DataCompositionSettings -  the report settings.
//  WhatToFill - DataCompositionSettings
//               - DataCompositionSelectedFields
//               - DataCompositionFilter
//               - DataCompositionGroup
//               - DataCompositionTable
//               - DataCompositionChart
//               - DataCompositionConditionalAppearanceItem - 
//  FillWithWhat - DataCompositionSettings
//               - DataCompositionSelectedFields
//               - DataCompositionFilter
//               - DataCompositionGroup
//               - DataCompositionTable
//               - DataCompositionChart
//               - DataCompositionConditionalAppearanceItem - 
//
// Returns:
//   DataCompositionSettings,
//   Selected polesreferences,
//   Oberkommandierenden,
//   Grouping
//   Of Data Sets, Tables Of Data Sets,
//   For a chart of data templates,
//   the wordformationcomposition Element is the setting element that is being filled in.
//
Function FillPropertiesRecursively(Node, WhatToFill, FillWithWhat, Map = Undefined, CopyingParameters = Undefined, WithoutStructure = False) Export
	If Map = Undefined Then
		Map = New Map;
	EndIf;
	
	If CopyingParameters = Undefined Then
		CopyingParameters = CopyingParameters(TypeOf(FillWithWhat), Undefined, WithoutStructure);
	EndIf;
	
	If CopyingParameters.ExcludeProperties <> "*" Then
		FillPropertyValues(WhatToFill, FillWithWhat, , CopyingParameters.ExcludeProperties);
	EndIf;
	
	IsDataTreeFormItem = TypeOf(FillWithWhat) = Type("FormDataTreeItem");
	If IsDataTreeFormItem Then
		Map.Insert(FillWithWhat, WhatToFill);
		
		NestedItemsCollection = ?(IsDataTreeFormItem, FillWithWhat.GetItems(), FillWithWhat.Rows);
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = ?(IsDataTreeFormItem, WhatToFill.GetItems(), WhatToFill.Rows);
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
			EndDo;
		EndIf;
		
		Return WhatToFill;
	EndIf;
		
	OldID = Node.GetIDByObject(FillWithWhat);
	NewID1 = Node.GetIDByObject(WhatToFill);
	Map.Insert(OldID, NewID1);
	
	If CopyingParameters.HasSettings Then
		WhatToFill.SetIdentifier(FillWithWhat.ObjectID);
		WhatToFill = WhatToFill.Settings; // 
		FillWithWhat = FillWithWhat.Settings; // 
	EndIf;
	
	If CopyingParameters.HasItems Then
		NestedItemsCollection = FillWithWhat.Items; // DataCompositionSelectedFieldCollection, DataCompositionFilterItemCollection
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.Items;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasSelection Then
		//   
		FillPropertyValues(WhatToFill.Selection, FillWithWhat.Selection, , "SelectionAvailableFields, Items");
		//   
		NestedItemsCollection = FillWithWhat.Selection.Items;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.Selection.Items;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasFilter Then
		//   
		FillPropertyValues(WhatToFill.Filter, FillWithWhat.Filter, , "FilterAvailableFields, Items");
		//   
		NestedItemsCollection = FillWithWhat.Filter.Items;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.Filter.Items;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, New Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasOutputParameters Then
		//   
		//       
		//       
		//       
		//       
		//       
		//   
		NestedItemsCollection = FillWithWhat.OutputParameters.Items;
		If NestedItemsCollection.Count() > 0 Then
			NestedItemsNode = WhatToFill.OutputParameters;
			For Each SubordinateRow In NestedItemsCollection Do
				DCParameterValue = NestedItemsNode.FindParameterValue(SubordinateRow.Parameter);
				If DCParameterValue <> Undefined Then
					FillPropertyValues(DCParameterValue, SubordinateRow);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasDataParameters Then
		//   
		//   
		NestedItemsCollection = FillWithWhat.DataParameters.Items;
		If NestedItemsCollection.Count() > 0 Then
			NestedItemsNode = WhatToFill.DataParameters;
			For Each SubordinateRow In NestedItemsCollection Do
				DCParameterValue = NestedItemsNode.FindParameterValue(SubordinateRow.Parameter);
				If DCParameterValue <> Undefined Then
					FillPropertyValues(DCParameterValue, SubordinateRow);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasUserFields Then
		//   
		//   
		NestedItemsCollection = FillWithWhat.UserFields.Items;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.UserFields.Items;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasGroupFields Then
		//   
		//   
		NestedItemsCollection = FillWithWhat.GroupFields.Items;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.GroupFields.Items;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, New Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasOrder Then
		//   
		FillPropertyValues(WhatToFill.Order, FillWithWhat.Order, , "OrderAvailableFields, Items");
		//   
		NestedItemsCollection = FillWithWhat.Order.Items;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.Order.Items;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasStructure Then
		//   
		//       
		//       
		FillPropertyValues(WhatToFill.Structure, FillWithWhat.Structure);
		NestedItemsCollection = FillWithWhat.Structure;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.Structure;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasConditionalAppearance Then
		//   
		FillPropertyValues(WhatToFill.ConditionalAppearance, FillWithWhat.ConditionalAppearance, , "FilterAvailableFields, FieldsAvailableFields, Items");
		//   
		NestedItemsCollection = FillWithWhat.ConditionalAppearance.Items;
		If NestedItemsCollection.Count() > 0 Then
			NewNestedItemsCollection = WhatToFill.ConditionalAppearance.Items;
			For Each SubordinateRow In NestedItemsCollection Do
				CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
			EndDo;
		EndIf;
	EndIf;
	
	If CopyingParameters.HasColumnsAndRows Then
		//   
		NestedItemsCollection = FillWithWhat.Columns;
		NewNestedItemsCollection = WhatToFill.Columns;
		OldID = Node.GetIDByObject(NestedItemsCollection);
		NewID1 = Node.GetIDByObject(NewNestedItemsCollection);
		Map.Insert(OldID, NewID1);
		For Each SubordinateRow In NestedItemsCollection Do
			CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
		EndDo;
		//   
		NestedItemsCollection = FillWithWhat.Rows;
		NewNestedItemsCollection = WhatToFill.Rows;
		OldID = Node.GetIDByObject(NestedItemsCollection);
		NewID1 = Node.GetIDByObject(NewNestedItemsCollection);
		Map.Insert(OldID, NewID1);
		For Each SubordinateRow In NestedItemsCollection Do
			CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
		EndDo;
	EndIf;
	
	If CopyingParameters.HasSeriesAndDots Then
		//   
		NestedItemsCollection = FillWithWhat.Series;
		NewNestedItemsCollection = WhatToFill.Series;
		OldID = Node.GetIDByObject(NestedItemsCollection);
		NewID1 = Node.GetIDByObject(NewNestedItemsCollection);
		Map.Insert(OldID, NewID1);
		For Each SubordinateRow In NestedItemsCollection Do
			CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
		EndDo;
		//   
		NestedItemsCollection = FillWithWhat.Points;
		NewNestedItemsCollection = WhatToFill.Points;
		OldID = Node.GetIDByObject(NestedItemsCollection);
		NewID1 = Node.GetIDByObject(NewNestedItemsCollection);
		Map.Insert(OldID, NewID1);
		For Each SubordinateRow In NestedItemsCollection Do
			CopyRecursive(Node, SubordinateRow, NewNestedItemsCollection, Undefined, Map);
		EndDo;
	EndIf;
	
	If CopyingParameters.HasNestedParametersValues Then
		//   
		For Each SubordinateRow In FillWithWhat.NestedParameterValues Do
			CopyRecursive(Node, SubordinateRow, WhatToFill.NestedParameterValues, Undefined, Map);
		EndDo;
	EndIf;
	
	If CopyingParameters.HasFieldsAndDecorations Then
		For Each FormattedField In FillWithWhat.Fields.Items Do
			FillPropertyValues(WhatToFill.Fields.Items.Add(), FormattedField);
		EndDo;
		For Each Source In FillWithWhat.Appearance.Items Do
			Receiver = WhatToFill.Appearance.FindParameterValue(Source.Parameter);
			If Receiver <> Undefined Then
				FillPropertyValues(Receiver, Source, , "Parent");
				For Each NestedSource In Source.NestedParameterValues Do
					NestedDestination = WhatToFill.Appearance.FindParameterValue(Source.Parameter);
					If NestedDestination <> Undefined Then
						FillPropertyValues(NestedDestination, NestedSource, , "Parent");
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
		
	Return WhatToFill;
EndFunction

Function AddUniqueValueToList(List, Value, Presentation, Use) Export
	If TypeOf(List) <> Type("ValueList")
		Or (Not ValueIsFilled(Value) And Not ValueIsFilled(Presentation)) Then
		Return Undefined;
	EndIf;
	
	ListItem = List.FindByValue(Value);
	
	If ListItem = Undefined Then
		ListItem = List.Add();
		ListItem.Value = Value;
	EndIf;
	
	If ValueIsFilled(Presentation) Then
		ListItem.Presentation = Presentation;
	ElsIf Not ValueIsFilled(ListItem.Presentation) Then
		ListItem.Presentation = String(Value);
	EndIf;
	
	If Use And Not ListItem.Check Then
		ListItem.Check = True;
	EndIf;
	
	Return ListItem;
EndFunction

Function ValuesByList(Values, OnlyFilledValues = False) Export
	If TypeOf(Values) = Type("ValueList") Then
		List = Values;
	Else
		List = New ValueList;
		If TypeOf(Values) = Type("Array") Then
			List.LoadValues(Values);
		ElsIf ValueIsFilled(Values) Then
			List.Add(Values);
		EndIf;
	EndIf;
	
	If Not OnlyFilledValues Then 
		Return List;
	EndIf;
	
	IndexOf = List.Count() - 1;
	While IndexOf >= 0 Do 
		Item = List[IndexOf];
		If Not ValueIsFilled(Item.Value) Then 
			List.Delete(Item);
		EndIf;
		IndexOf = IndexOf - 1;
	EndDo;
	
	Return List;
EndFunction

Function StrLeftBeforeChar(String, Separator, Balance = Undefined)
	Position = StrFind(String, Separator);
	If Position = 0 Then
		StringBeforeDot = String;
		Balance = "";
	Else
		StringBeforeDot = Left(String, Position - 1);
		Balance = Mid(String, Position + 1);
	EndIf;
	Return StringBeforeDot;
EndFunction

Function FindTableRows(TableAttribute1, RowData) Export
	If TypeOf(TableAttribute1) = Type("FormDataCollection") Then // 
		Return TableAttribute1.FindRows(RowData);
	ElsIf TypeOf(TableAttribute1) = Type("FormDataTree") Then // 
		Return FindRecursively(TableAttribute1.GetItems(), RowData);
	Else
		Return Undefined;
	EndIf;
EndFunction

Function FindRecursively(RowsSet, RowData, FoundItems = Undefined)
	If FoundItems = Undefined Then
		FoundItems = New Array;
	EndIf;
	For Each TableRow In RowsSet Do
		ValuesMatch = True;
		For Each KeyAndValue In RowData Do
			If TableRow[KeyAndValue.Key] <> KeyAndValue.Value Then
				ValuesMatch = False;
				Break;
			EndIf;
		EndDo;
		If ValuesMatch Then
			FoundItems.Add(TableRow);
		EndIf;
		FindRecursively(TableRow.GetItems(), RowData, FoundItems);
	EndDo;
	Return FoundItems;
EndFunction

Procedure CastValueToType(Value, TypeDescription) Export
	If TypeOf(Value) = Type("ValueList") Then 
		For Each ListItem In Value Do 
			If Not TypeDescription.ContainsType(TypeOf(ListItem.Value)) Then
				ListItem.Value = TypeDescription.AdjustValue();
			EndIf;
		EndDo;
	Else
		If Not TypeDescription.ContainsType(TypeOf(Value)) Then
			Value = TypeDescription.AdjustValue();
		EndIf;
	EndIf;
EndProcedure

// The index of the image in the collection of Piktogramredaktilo.
Function PictureIndex(Type, State = Undefined) Export
	If Type = "Group" Then
		IndexOf = 1;
	ElsIf Type = "Item" Then
		IndexOf = 4;
	ElsIf Type = "Group"
		Or Type = "TableGroup"
		Or Type = "ChartGroup" Then
		IndexOf = 7;
	ElsIf Type = "Table" Then
		IndexOf = 10;
	ElsIf Type = "Chart" Then
		IndexOf = 11;
	ElsIf Type = "NestedObjectSettings" Then
		IndexOf = 12;
	ElsIf Type = "DataParameters" Then
		IndexOf = 14;
	ElsIf Type = "DataParameter" Then
		IndexOf = 15;
	ElsIf Type = "Filters" Then
		IndexOf = 16;
	ElsIf Type = "FilterElement" Then
		IndexOf = 17;
	ElsIf Type = "SelectedFields" Then
		IndexOf = 18;
	ElsIf Type = "Sorts" Then
		IndexOf = 19;
	ElsIf Type = "ConditionalAppearance" Then
		IndexOf = 20;
	ElsIf Type = "Settings" Then
		IndexOf = 21;
	ElsIf Type = "Structure" Then
		IndexOf = 22;
	ElsIf Type = "Resource" Then
		IndexOf = 23;
	ElsIf Type = "Warning" Then
		IndexOf = 24;
	ElsIf Type = "Error" Then
		IndexOf = 25;
	Else
		IndexOf = -2;
	EndIf;
	
	If State = "DeletionMark" Then
		IndexOf = IndexOf + 1;
	ElsIf State = "Predefined" Then
		IndexOf = IndexOf + 2;
	EndIf;
	
	Return IndexOf;
EndFunction

Function UniqueKey(FullReportName, VariantKey) Export
	Result = FullReportName;
	If ValueIsFilled(VariantKey) Then
		Result = Result + "/VariantKey." + VariantKey;
	EndIf;
	Return Result;
EndFunction

Function SettingItemCondition(Item, LongDesc) Export 
	Condition = DataCompositionComparisonType.Equal;
	
	If TypeOf(Item) = Type("DataCompositionFilterItem") Then 
		Condition = Item.ComparisonType;
	ElsIf TypeOf(Item) = Type("DataCompositionSettingsParameterValue")
		And LongDesc.ValueListAllowed Then 
		Condition = DataCompositionComparisonType.InList;
	EndIf;
	
	Return Condition;
EndFunction

Function IsListComparisonKind(Var_ComparisonType) Export 
	ComparisonsTypes = New Array;
	ComparisonsTypes.Add(DataCompositionComparisonType.InList);
	ComparisonsTypes.Add(DataCompositionComparisonType.NotInList);
	ComparisonsTypes.Add(DataCompositionComparisonType.InListByHierarchy);
	ComparisonsTypes.Add(DataCompositionComparisonType.NotInListByHierarchy);
	
	Return ComparisonsTypes.Find(Var_ComparisonType) <> Undefined;
EndFunction

Function ChoiceParameters(Settings, UserSettings, SettingItem, OptionChangeMode = False) Export 
	ChoiceParameters = New Array;
	
	SettingItemDetails = FindAvailableSetting(Settings, SettingItem);
	If SettingItemDetails = Undefined Then 
		Return New FixedArray(ChoiceParameters);
	EndIf;
	
	Parameters = SettingItemDetails.GetChoiceParameters(); // DataCompositionChoiceParameters
	For Each Parameter In Parameters Do 
		If ValueIsFilled(Parameter.Name) Then
			ChoiceParameters.Add(New ChoiceParameter(Parameter.Name, Parameter.Value));
		EndIf;
	EndDo;
	
	Parameters = SettingItemDetails.GetChoiceParameterLinks(); // DataCompositionChoiceParameterLinks
	For Each Parameter In Parameters Do 
		If Not ValueIsFilled(Parameter.Name) Then
			Continue;
		EndIf;
		
		Value = ChoiceParameterValue(Settings, UserSettings, Parameter.Field, OptionChangeMode);
		If ValueIsFilled(Value) Then 
			ChoiceParameters.Add(New ChoiceParameter(Parameter.Name, Value));
		EndIf;
	EndDo;
	
	Return New FixedArray(ChoiceParameters);
EndFunction

Function NameOfTheDefaultSettingEvent() Export 
	
	Return "DefaultSettings";
	
EndFunction

Function PasteFromClipboardCommandName() Export
	
	Return "PasteFromClipboard";
	
EndFunction

Function ReportFormUpdateParameters(Val EventName = "") Export
	
	Result = New Structure;
	// 
	Result.Insert("EventName", EventName);
	Result.Insert("VariantModified", False);
	Result.Insert("UserSettingsModified", False);
	Result.Insert("Result", New Structure);
	Result.Insert("ReportObjectOrFullName", "");
	Result.Insert("DCSettingsComposer", Undefined);
	Result.Insert("DCSettings", Undefined);
	Result.Insert("DCUserSettings", Undefined);
	Result.Insert("ClearOptionSettings", False);
	Result.Insert("ResetCustomSettings", False);
	Result.Insert("UpdateOptionSettings", False);
	Result.Insert("ReportObjectOrFullName", "");
	Result.Insert("Regenerate", False);
	Result.Insert("Directly", False);
	// 
	Result.Insert("SettingsFormAdvancedMode", 0);
	Result.Insert("SettingsFormPageName", "");
	// ReportSettingsForm
	Result.Insert("FiltersConditions", Undefined);
	Result.Insert("Result", New Structure("ExpandTreesNodes", New Array));
	Result.Insert("Abort", False);
	
	Return Result;
		
EndFunction

#EndRegion
