///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

//  Returns a custom report as a table document.
//  It is based on the values of the "node information Base" and "additional Registration" details.
//
//  Parameters:
//       FullMetadataName - String -  restriction.
//       Presentation       - String -  the result parameter.
//       SimplifiedMode     - Boolean -  select the layout.
//
//  Returns:
//      SpreadsheetDocument - 
//
Function GenerateUserSpreadsheetDocument(FullMetadataName = "", Presentation = "", SimplifiedMode = False) Export
	SetPrivilegedMode(True);
	
	CompositionData = InitializeComposer();
	
	If IsBlankString(FullMetadataName) Then
		DetailsData = New DataCompositionDetailsData;
		VariantName = "UserData1"; 
	Else
		DetailsData = Undefined;
		VariantName = "DetailsByObjectKind"; 
	EndIf;
	
	// 
	FiltersSettings = CompositionData.SettingsComposer.GetSettings();
	
	// 
	CompositionData.SettingsComposer.LoadSettings(
		CompositionData.CompositionSchema.SettingVariants[VariantName].Settings);
	
	// 
	AddDataCompositionFilterValues(CompositionData.SettingsComposer.Settings.Filter.Items, 
		FiltersSettings.Filter.Items);
	
	Parameters = CompositionData.CompositionSchema.Parameters;
	Parameters.Find("CreationDate").Value = CurrentSessionDate();
	Parameters.Find("SimplifiedMode").Value  = SimplifiedMode;
	
	Parameters.Find("CommonSynchronizationParameterText").Value = DataExchangeServer.DataSynchronizationRulesDetails(InfobaseNode);
	Parameters.Find("AdditionalParameterText").Value     = AdditionalParameterText();
	
	If Not IsBlankString(FullMetadataName) Then
		Parameters.Find("ListPresentation").Value = Presentation;
		
		FilterItems1 = CompositionData.SettingsComposer.Settings.Filter.Items;
		
		Item = FilterItems1.Add(Type("DataCompositionFilterItem"));
		Item.LeftValue  = New DataCompositionField("FullMetadataName");
		Item.Presentation  = Presentation;
		Item.ComparisonType   = DataCompositionComparisonType.Equal;
		Item.RightValue = FullMetadataName;
		Item.Use  = True;
	EndIf;
	
	ComposerSettings = CompositionData.SettingsComposer.GetSettings();
	If SimplifiedMode Then
		// 
		FieldsToHide = New Structure("CountByGeneralRules, RegistrationAdditionally, CommonCount, NoExport, CanExportObject");
		For Each Group In ComposerSettings.Structure Do
			HideSelectionFields(Group.Selection.Items, FieldsToHide)
		EndDo;
		// 
		GroupCount = ComposerSettings.Structure.Count();
		If GroupCount > 0 Then
			ComposerSettings.Structure.Get(GroupCount - 1).Name = "EmptyFooter";
		EndIf;
	EndIf;

	TemplateComposer = New DataCompositionTemplateComposer;
	Template = TemplateComposer.Execute(CompositionData.CompositionSchema, ComposerSettings, DetailsData, , Type("DataCompositionTemplateGenerator"));
	ExternalDataSets = New Structure("NodeCompositionMetadataTable", CompositionData.NodeCompositionMetadataTable);
	
	Processor = New DataCompositionProcessor;
	Processor.Initialize(Template, ExternalDataSets, DetailsData, True);
	
	Output = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	Output.SetDocument(New SpreadsheetDocument);
	
	Return New Structure("SpreadsheetDocument, Details, CompositionSchema",
		Output.Output(Processor), DetailsData, CompositionData.CompositionSchema);
EndFunction

//  Returns data as a two-level tree, the first level is the metadata type, and the second level is objects.
//  It is based on the values of the "node information Base" and "additional Registration" details.
//
//  Parameters:
//      MetadataNamesList - Array -  full metadata names to limit the query.
//                                      Can be a collection of elements with the field "of Polnoekrannyj".
//  Returns:
//      ValueTree - 
//
Function GenerateValueTree(MetadataNamesList = Undefined) Export
	SetPrivilegedMode(True);
	
	CompositionData = InitializeComposer(MetadataNamesList);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	Template = TemplateComposer.Execute(CompositionData.CompositionSchema, CompositionData.SettingsComposer.GetSettings(), , , 
		Type("DataCompositionValueCollectionTemplateGenerator"));
	ExternalDataSets = New Structure("NodeCompositionMetadataTable", CompositionData.NodeCompositionMetadataTable);
	
	Processor = New DataCompositionProcessor;
	Processor.Initialize(Template, ExternalDataSets, , True);
	
	Output = New DataCompositionResultValueCollectionOutputProcessor;
	Output.SetObject(New ValueTree);
	ResultTree = Output.Output(Processor);
	
	Return ResultTree;
EndFunction

//  Initializes the entire object.
//
//  Parameters:
//      Source - String
//               - UUID - 
//
//  Returns:
//    DataProcessorObject.InteractiveExportChange - 
//
Function InitializeThisObject(Val Source = "") Export
	
	If TypeOf(Source)=Type("String") Then
		If IsBlankString(Source) Then
			Return ThisObject;
		EndIf;
		Source = GetFromTempStorage(Source);
	EndIf;
		
	FillPropertyValues(ThisObject, Source, , "AllDocumentsFilterComposer, AdditionalRegistration, AdditionalNodeScenarioRegistration");
	
	DataExchangeServer.FillValueTable(AdditionalRegistration, Source.AdditionalRegistration);
	DataExchangeServer.FillValueTable(AdditionalNodeScenarioRegistration, Source.AdditionalNodeScenarioRegistration);
	
	// 
	If IsBlankString(Source.AllDocumentsComposerAddress) Then
		Data = CommonFilterSettingsComposer();
	Else
		Data = GetFromTempStorage(Source.AllDocumentsComposerAddress);
	EndIf;
		
	AllDocumentsFilterComposer = New DataCompositionSettingsComposer;
	AllDocumentsFilterComposer.Initialize(
		New DataCompositionAvailableSettingsSource(Data.CompositionSchema));
	AllDocumentsFilterComposer.LoadSettings(Data.Settings);
	
	If IsBlankString(Source.AllDocumentsComposerAddress) Then
		AllDocumentsComposerAddress = PutToTempStorage(Data, Source.FormStorageAddress);
	Else 
		AllDocumentsComposerAddress = Source.AllDocumentsComposerAddress;
	EndIf;
		
	Return ThisObject;
EndFunction

//  Saves the data of this object in temporary storage.
//
//  Parameters:
//      StorageAddress - String
//                     - UUID - 
//
//  Returns:
//      String - 
//
Function SaveThisObject(Val StorageAddress) Export
	Data = New Structure;
	For Each Meta In Metadata().Attributes Do
		Name = Meta.Name;
		Data.Insert(Name, ThisObject[Name]);
	EndDo;
	
	ComposerData = CommonFilterSettingsComposer();
	Data.Insert("AllDocumentsComposerAddress", PutToTempStorage(ComposerData, StorageAddress));
	
	Return PutToTempStorage(Data, StorageAddress);
EndFunction

//  Returns linker data for General selections of the "information database Node".
//  It is based on the values of the "node information Database" and "additional Registration" details.
//
//  Parameters:
//      SchemaSavingAddress - String
//                           - UUID - 
//                             
//
// Returns:
//      Structure:
//          * Settings       - DataCompositionSettings -  the settings of the linker.
//          * CompositionSchema - DataCompositionSchema     -  scheme of the layout.
//
Function CommonFilterSettingsComposer(SchemaSavingAddress = Undefined) Export
	
	SavedOption = ExportOption;
	ExportOption = 1;
	SavingAddress = ?(SchemaSavingAddress = Undefined, New UUID, SchemaSavingAddress);
	Data = InitializeComposer(Undefined, True, SavingAddress);
	ExportOption = SavedOption;
	
	Result = New Structure;
	Result.Insert("Settings",  Data.SettingsComposer.Settings);
	Result.Insert("CompositionSchema", Data.CompositionSchema);
	
	Return Result;
EndFunction

//  Returns the linker for selecting one type of metadata for the node "nodeinformation Database".
//
//  Parameters:
//      FullMetadataName  - String -  name of the table to build the linker for. Perhaps there will 
//                                      be IDs for "all documents" or "all reference books"
//                                      or a link to the group.
//      Presentation        - String -  representation of the object in the selection.
//      Filter                - DataCompositionFilter -  selecting the layout to fill in.
//      SchemaSavingAddress - String
//                           - UUID - 
//                             
//
// Returns:
//      DataCompositionSettingsComposer - 
//
Function SettingsComposerByTableName(FullMetadataName, Presentation = Undefined, Filter = Undefined, SchemaSavingAddress = Undefined) Export
	
	CompositionSchema = New DataCompositionSchema;
	
	Source = CompositionSchema.DataSources.Add();
	Source.Name = "Source";
	Source.DataSourceType = "local";
	
	TablesToAdd = EnlargedMetadataGroupComposition(FullMetadataName);
	
	For Each TableName In TablesToAdd Do
		AddSetToCompositionSchema(CompositionSchema, TableName, Presentation);
	EndDo;
	
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(New DataCompositionAvailableSettingsSource(
		PutToTempStorage(CompositionSchema, SchemaSavingAddress)));
	
	If Filter <> Undefined Then
		AddDataCompositionFilterValues(Composer.Settings.Filter.Items, Filter.Items);
		Composer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	EndIf;
	
	Return Composer;
EndFunction

// Returns:
//     String - 
//
Function BaseNameForForm() Export
	Return Metadata().FullName() + "."
EndFunction

// Returns:
//     String - 
//
Function AllDocumentsFilterGroupTitle() Export
	Return NStr("en = 'All documents';");
EndFunction

// Returns:
//     String - 
//
Function AllCatalogsFilterGroupTitle() Export
	Return NStr("en = 'All catalogs';");
EndFunction

//  Returns a description of the period and selection as a string.
//
//  Parameters:
//      Period - StandardPeriod     -  period for describing the selection.
//      Filter  - DataCompositionFilter -  selecting the data layout for the description.
//      EmptyFilterDetails - String -  the value returned if the selection is empty.
// Returns:
//     String - 
//
Function FilterPresentation(Period, Filter, Val EmptyFilterDetails = Undefined) Export
	Return DataExchangeServer.ExportAdditionFilterPresentation(Period, Filter, EmptyFilterDetails);
EndFunction

//  Returns a description of the detailed selection for the "additional Registration"item.
//
//  Parameters:
//      EmptyFilterDetails - String -  the value returned if the selection is empty.
// Returns:
//     String - 
//
Function DetailedFilterPresentation(Val EmptyFilterDetails=Undefined)
	Return DataExchangeServer.DetailedExportAdditionPresentation(AdditionalRegistration, EmptyFilterDetails);
EndFunction

// The identifier of the service object group metadata to All documents.
// Returns:
//     String - 
//
Function AllDocumentsID() Export
	// 
	Return DataExchangeServer.ExportAdditionAllDocumentsID();
EndFunction

// Returns:
//     String - 
//
Function AllCatalogsID() Export
	// 
	Return DataExchangeServer.ExportAdditionAllCatalogsID();
EndFunction

//  Adds a selection to the end of the selection with possible field corrections.
//
//  Parameters:
//      DestinationItems - DataCompositionFilterItemCollection -  receiver.
//      SourceItems - DataCompositionFilterItemCollection - source.
//      FieldsMap - Map of KeyAndValue - :
//                          * Key -  
//                          * Value - 
//                          
//                          
//                          
//
Procedure AddDataCompositionFilterValues(DestinationItems, SourceItems, FieldsMap = Undefined) Export
	
	For Each Item In SourceItems Do
		
		Type=TypeOf(Item);
		FilterElement = DestinationItems.Add(Type);
		FillPropertyValues(FilterElement, Item);
		If Type=Type("DataCompositionFilterItemGroup") Then
			AddDataCompositionFilterValues(FilterElement.Items, Item.Items, FieldsMap);
			
		ElsIf FieldsMap<>Undefined Then
			SourceFieldAsString = Item.LeftValue;
			For Each KeyValue In FieldsMap Do
				ControlNewField     = Lower(KeyValue.Key);
				ControlLength     = 1 + StrLen(ControlNewField);
				ControlSourceField = Lower(Left(SourceFieldAsString, ControlLength));
				If ControlSourceField=ControlNewField Then
					FilterElement.LeftValue = New DataCompositionField(KeyValue.Value);
					Break;
				ElsIf ControlSourceField=ControlNewField + "." Then
					FilterElement.LeftValue = New DataCompositionField(KeyValue.Value + Mid(SourceFieldAsString, ControlLength));
					Break;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

//  Returns an item in the list of values by view.
//
//  Parameters:
//      ValueList - ValueList -  list to search for.
//      Presentation  - String         -  parameter to search for.
//
// Returns:
//   - ValueListItem - 
//   - Undefined  - 
//
Function FindByPresentationListItem(ValueList, Presentation)
	For Each ListItem In ValueList Do
		If ListItem.Presentation=Presentation Then
			Return ListItem;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction

//  Performs additional registration based on the current object data.
//
Procedure RecordAdditionalChanges() Export
	
	If ExportOption <= 0 Then
		// 
		Return;
	EndIf;
	
	ChangesTree = GenerateValueTree();
	
	SetPrivilegedMode(True);
	For Each GroupRow In ChangesTree.Rows Do
		For Each String In GroupRow.Rows Do
			If String.ToExportCount > 0 Then
				DataExchangeEvents.RecordDataChanges(InfobaseNode, String.RegistrationObject, False);
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

//  Returns a list of values from the views of possible settings.
//
//  Parameters:
//      ExchangeNode - ExchangePlanRef -  exchange node for the returned settings. If not specified, the 
//                                      current value of the "node information Database" attribute is used.
//      Variants - Array             -  if specified, we filter the restored settings by options
//                                      0-no selection, 1-selection of all documents, 2-detailed, 3 - node scenario.
//
//  Returns:
//      ValueList - 
//
Function ReadSettingsListPresentations(ExchangeNode = Undefined, Variants = Undefined) Export
	
	SettingsParameters = SettingsParameterStructure(ExchangeNode);
	
	SetPrivilegedMode(True);    
	VariantList = CommonSettingsStorage.Load(
	SettingsParameters.ObjectKey, SettingsParameters.SettingsKey,
	SettingsParameters, SettingsParameters.User);
	
	PresentationsList = New ValueList;
	If VariantList<>Undefined Then
		For Each Item In VariantList Do
			If Variants=Undefined Or Variants.Find(Item.Value.ExportOption)<>Undefined Then
				PresentationsList.Add(Item.Presentation, Item.Presentation);
			EndIf;
		EndDo;
	EndIf;
	
	Return PresentationsList;
EndFunction

//  Restores the values of the current object's details from the specified list item.
//
//  Parameters:
//      Presentation       - String -  view of settings to restore.
//      Variants            - Array -  if specified, we filter the restored settings by options
//                                     0-no selection, 1-selection of all documents, 2-detailed, 3 - node scenario.
//      FormStorageAddress - String
//                          - UUID - 
//
// Returns:
//      Boolean - 
//
Function RestoreCurrentAttributesFromSettings(Presentation, Variants = Undefined, FormStorageAddress = Undefined) Export
	
	VariantList = ReadSettingsList(Variants);
	ListItem = FindByPresentationListItem(VariantList, Presentation);
	
	Result = ListItem<>Undefined;
	If Result Then
		UnchangedData = New Structure("InfobaseNode");
		FillPropertyValues(UnchangedData, ThisObject);
		FillPropertyValues(ThisObject, ListItem.Value);
		FillPropertyValues(ThisObject, UnchangedData);
		
		// 
		Data = CommonFilterSettingsComposer();
		AllDocumentsFilterComposer = New DataCompositionSettingsComposer;
		AllDocumentsFilterComposer.Initialize(New DataCompositionAvailableSettingsSource(Data.CompositionSchema));
		AllDocumentsFilterComposer.LoadSettings(ListItem.Value._AllDocumentsFilterComposerSettings1);
		
		// 
		If FormStorageAddress<>Undefined Then
			AllDocumentsComposerAddress = PutToTempStorage(Data, FormStorageAddress);
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

//  Saves the values of the current object's details in accordance with the specified view.
//
//  Parameters:
//      Presentation         - String -  view settings.
//
Procedure SaveCurrentValuesInSettings(Presentation) Export
	VariantList = ReadSettingsList();
	
	ListItem = FindByPresentationListItem(VariantList, Presentation);
	If ListItem=Undefined Then
		ListItem = VariantList.Add(, Presentation);
		VariantList.SortByPresentation();
	EndIf;
	
	AttributesToSave = "InfobaseNode, ExportOption, AllDocumentsFilterPeriod, AdditionalRegistration,
		|NodeScenarioFilterPeriod, AdditionalNodeScenarioRegistration, NodeScenarioFilterPresentation";
	
	ListItem.Value = New Structure(AttributesToSave);
	FillPropertyValues(ListItem.Value, ThisObject);
	
	ListItem.Value.Insert("_AllDocumentsFilterComposerSettings1", AllDocumentsFilterComposer.Settings);
	
	SettingsParameters = SettingsParameterStructure();
	
	SetPrivilegedMode(True);
	CommonSettingsStorage.Save(
		SettingsParameters.ObjectKey, SettingsParameters.SettingsKey, 
		VariantList, 
		SettingsParameters, SettingsParameters.User);
EndProcedure

//  Removes the settings option from the list.
//
//  Parameters:
//      Presentation          - String -  view settings.
//
Procedure DeleteSettingsOption(Presentation) Export
	VariantList = ReadSettingsList();
	ListItem = FindByPresentationListItem(VariantList, Presentation);
	
	If ListItem<>Undefined Then
		VariantList.Delete(ListItem);
		VariantList.SortByPresentation();
		SaveSettingsList(VariantList);
	EndIf;
	
EndProcedure

// Returns an array of the names of the metadata tables in the composite parameter type "of Polnoekrannyj".
// Based on the current value of the requisite "Userinformation".
//
// Parameters:
//      FullMetadataName - String
//                          - ValueTree - 
//                            
//                            
//
// Returns:
//      Array -  metadata names.
//
Function EnlargedMetadataGroupComposition(FullMetadataName) Export
	
	If TypeOf(FullMetadataName) <> Type("String") Then
		// 
		CompositionTables = New Array;
		For Each GroupRow In FullMetadataName.Rows Do
			For Each GroupCompositionRow In GroupRow.Rows Do
				CompositionTables.Add(GroupCompositionRow.FullMetadataName);
			EndDo;
		EndDo;
		
	ElsIf FullMetadataName = AllDocumentsID() Then
		// 
		AllData = DataExchangeCached.ExchangePlanContent(InfobaseNode.Metadata().Name, True, False);
		CompositionTables = AllData.UnloadColumn("FullMetadataName");
		
	ElsIf FullMetadataName = AllCatalogsID() Then
		// 
		AllData = DataExchangeCached.ExchangePlanContent(InfobaseNode.Metadata().Name, False, True);
		CompositionTables = AllData.UnloadColumn("FullMetadataName");
		
	Else
		// 
		CompositionTables = New Array;
		CompositionTables.Add(FullMetadataName);
		
	EndIf;
	
	// 
	NotExportMode = Enums.ExchangeObjectExportModes.NotExport;
	ExportModes   = DataExchangeCached.UserExchangePlanComposition(InfobaseNode);
	
	Position = CompositionTables.UBound();
	While Position >= 0 Do
		If ExportModes[CompositionTables[Position]] = NotExportMode Then
			CompositionTables.Delete(Position);
		EndIf;
		Position = Position - 1;
	EndDo;
	
	Return CompositionTables;
EndFunction

//  Constructor for value tables. Generates a table with columns of any type.
//
//  Parameters:
//      ColumnsList  - String -  comma-separated list of table column names.
//      IndexList1 - String -  comma-separated list of table indexes.
//
// Returns:
//      ValueTable - 
//
Function ValueTable(ColumnsList, IndexList1 = "")
	ResultTable2 = New ValueTable;
	
	For Each KeyValue In (New Structure(ColumnsList)) Do
		ResultTable2.Columns.Add(KeyValue.Key);
	EndDo;
	For Each KeyValue In (New Structure(IndexList1)) Do
		ResultTable2.Indexes.Add(KeyValue.Key);
	EndDo;
	
	Return ResultTable2;
EndFunction

//  Adds a single selection element to the list.
//
//  Parameters:
//      FilterItems1  - DataCompositionFilterItem -  reference to the object being checked.
//      DataPathField - String -  the data path for the element to add.
//      Var_ComparisonType    - DataCompositionComparisonType -  comparison view for the element being added.
//      Value        - Arbitrary -  comparison value for the element being added.
//      Presentation    -String -  optional field representation.
//      
Procedure AddFilterItem(FilterItems1, DataPathField, Var_ComparisonType, Value, Presentation = Undefined)
	
	Item = FilterItems1.Add(Type("DataCompositionFilterItem"));
	Item.Use  = True;
	Item.LeftValue  = New DataCompositionField(DataPathField);
	Item.ComparisonType   = Var_ComparisonType;
	Item.RightValue = Value;
	
	If Presentation<>Undefined Then
		Item.Presentation = Presentation;
	EndIf;
EndProcedure

//  Adds a data set with a single "Link" field by table name to the layout schema.
//
//  Parameters:
//      DataCompositionSchema - DataCompositionSchema -  the schema that is being added to.
//      
//      
//
Procedure AddSetToCompositionSchema(DataCompositionSchema, TableName, Presentation = Undefined)
	
	QueryText = StrReplace("SELECT MetadataTableName.Ref AS Ref FROM &TableName AS MetadataTableName", "&TableName", TableName);
	
	Set = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	Set.Query = QueryText;
	Set.AutoFillAvailableFields = True;
	Set.DataSource = DataCompositionSchema.DataSources.Get(0).Name;
	Set.Name = "Set" + Format(DataCompositionSchema.DataSets.Count()-1, "NZ=; NG=");
	
	Field = Set.Fields.Add(Type("DataCompositionSchemaDataSetField"));
	Field.Field = "Ref";
	Field.Title = ?(Presentation=Undefined, DataExchangeServer.ObjectPresentation(TableName), Presentation);
	
EndProcedure

//  Sets data sets to the schema and initializes the linker.
//  It is based on the values of the following details:
//    "node of the information Database", "additional Registration", 
//    "loading Options", "Periodoforavsehdocuments", "Linkeroforavsehdocuments".
//
//  Parameters:
//      MetadataNamesList - Array -  names of metadata (trees of values of the constraint group, service
//                                      IDs
//                                      "all documents" or "all NSI") for which the schema will be built. 
//                                      If not specified, then for the entire node composition.
//
//      LimitUsageWithFilter - Boolean -  flag indicating that the layout will be initialized only
//                                                  for selecting upload elements.
//
//      SchemaSavingAddress - String
//                           - UUID - 
//                             
//
//  Returns:
//      Structure:
//         * NodeCompositionMetadataTable - ValueTable -  description of the node composition.
//         * CompositionSchema - DataCompositionSchema -  initiated value.
//         * SettingsComposer - DataCompositionSettingsComposer -  initiated value.
//
Function InitializeComposer(MetadataNamesList = Undefined, LimitUsageWithFilter = False, SchemaSavingAddress = Undefined)
	
	NodeCompositionMetadataTable = DataExchangeCached.ExchangePlanContent(InfobaseNode.Metadata().Name);
	CompositionSchema = GetTemplate("DataCompositionSchema");
	
	// 
	ItemsSetsCounts = CompositionSchema.DataSets.Find("TotalItemsCount").Items;
	
	// 
	SetItemsChanges = CompositionSchema.DataSets.Find("ChangeRecords").Items;
	While SetItemsChanges.Count() > 1 Do
		// 
		SetItemsChanges.Delete(SetItemsChanges[1]);
	EndDo;
	DataSource = CompositionSchema.DataSources.Get(0).Name;
	
	// 
	MetadataNamesFilter = New Map;
	If MetadataNamesList <> Undefined Then
		If TypeOf(MetadataNamesList) = Type("Array") Then
			For Each MetaName1 In MetadataNamesList Do
				MetadataNamesFilter.Insert(MetaName1, True);
			EndDo;
		Else
			For Each Item In MetadataNamesList Do
				MetadataNamesFilter.Insert(Item.FullMetadataName, True);
			EndDo;
		EndIf;
	EndIf;
	
	ChangeRequestTemplate =
	"SELECT DISTINCT ALLOWED
	|	AliasOfTheRegistrationTable.Ref  AS RegistrationObject,
	|	&FullNameOfTheMetadataTableType      AS RegistrationObjectType,
	|	&RegistrationReasonAutomatically    AS RegistrationReason
	|FROM
	|	&FullNameOfTheMetadataTable AS AliasOfTheRegistrationTable
	|WHERE AliasOfTheRegistrationTable.Node = &InfobaseNode";
	
	RequestTemplateQuantity =
	"SELECT ALLOWED
	|	&FullNameOfTheMetadataTableType                 AS Type,
	|	COUNT(AliasOfTheRegistrationTable.Ref) AS CommonCount
	|FROM
	|	&FullNameOfTheMetadataTable AS AliasOfTheRegistrationTable";
	
	// 
	For Each String In NodeCompositionMetadataTable Do
		
		FullMetadataName = String.FullMetadataName;
		If MetadataNamesList <> Undefined And MetadataNamesFilter[FullMetadataName] <> True Then
			Continue;
		EndIf;
		
		ReplacementStringType = StringFunctionsClientServer.SubstituteParametersToString("Type(%1)", FullMetadataName);
		ReplacementRowChangeTable = StringFunctionsClientServer.SubstituteParametersToString("%1.Changes", FullMetadataName);
		ReplacementRowTable = StringFunctionsClientServer.SubstituteParametersToString("%1", FullMetadataName);
		MetadataSetName = StrReplace(FullMetadataName, ".", "_");
		
		SetName = "Automatically_" + MetadataSetName;
		If SetItemsChanges.Find(SetName) = Undefined Then
			
			Set = SetItemsChanges.Add(Type("DataCompositionSchemaDataSetQuery"));
			Set.AutoFillAvailableFields = Not LimitUsageWithFilter;
			Set.DataSource = DataSource;
			Set.Name = SetName;
			
			QueryText = StrReplace(ChangeRequestTemplate, "&FullNameOfTheMetadataTableType", ReplacementStringType);
			QueryText = StrReplace(QueryText, "&FullNameOfTheMetadataTable", ReplacementRowChangeTable);
			Set.Query = QueryText;
			
		EndIf;
		
		SetName = "Count_" + MetadataSetName;
		If ItemsSetsCounts.Find(SetName) = Undefined Then
			
			Set = ItemsSetsCounts.Add(Type("DataCompositionSchemaDataSetQuery"));
			Set.AutoFillAvailableFields = True;
			Set.DataSource = DataSource;
			Set.Name = SetName;
		
			QueryText = StrReplace(RequestTemplateQuantity, "&FullNameOfTheMetadataTableType", ReplacementStringType);
			QueryText = StrReplace(QueryText, "&FullNameOfTheMetadataTable", ReplacementRowTable);
			Set.Query = QueryText;
			
		EndIf;
		
	EndDo;
	
	// 
	If ExportOption = 1 Then
		// 
		AdditionalChangesTable = ValueTable("FullMetadataName, Filter, Period, PeriodSelection");
		String = AdditionalChangesTable.Add();
		String.FullMetadataName = AllDocumentsID();
		String.PeriodSelection        = True;
		String.Period              = AllDocumentsFilterPeriod;
		String.Filter               = AllDocumentsFilterComposer.Settings.Filter;
		
	ElsIf ExportOption = 2 Then
		// 
		AdditionalChangesTable = AdditionalRegistration;
		
	Else
		// 
		AdditionalChangesTable = New ValueTable;
		
	EndIf;
	
	RequestTemplateAdvanced =
	"SELECT ALLOWED
	|	AliasOfTheRegistrationTable.Ref  AS RegistrationObject,
	|	&FullNameOfTheMetadataTableType AS RegistrationObjectType,
	|	&RegistrationReasonAdvanced   AS RegistrationReason
	|FROM
	|	&FullNameOfTheMetadataTable AS AliasOfTheRegistrationTable";
	
	// 
	For Each String In AdditionalChangesTable Do
		FullMetadataName = String.FullMetadataName;
		CurrentFilter = String.Filter; // DataCompositionFilter
		
		If MetadataNamesList <> Undefined And MetadataNamesFilter[FullMetadataName] <> True Then
			Continue;
		EndIf;
		
		TablesToAdd = EnlargedMetadataGroupComposition(FullMetadataName);
		For Each NameOfTableToAdd In TablesToAdd Do
			If MetadataNamesList <> Undefined And MetadataNamesFilter[NameOfTableToAdd] <> True Then
				Continue;
			EndIf;
			
			ReplacementStringType = StringFunctionsClientServer.SubstituteParametersToString("Type(%1)", NameOfTableToAdd);
			
			SetName = "More_" + StrReplace(NameOfTableToAdd, ".", "_");
			If SetItemsChanges.Find(SetName) = Undefined Then 
				
				Set = SetItemsChanges.Add(Type("DataCompositionSchemaDataSetQuery"));
				Set.DataSource = DataSource;
				Set.AutoFillAvailableFields = True;
				Set.Name = SetName;
				
				QueryText = StrReplace(RequestTemplateAdvanced, "&FullNameOfTheMetadataTableType", ReplacementStringType);
				QueryText = StrReplace(QueryText, "&FullNameOfTheMetadataTable", NameOfTableToAdd);
				Set.Query = QueryText;
				
				// 
				AddingOptions = New Structure;
				AddingOptions.Insert("NameOfTableToAdd", NameOfTableToAdd);
				AddingOptions.Insert("CompositionSchema",       CompositionSchema);
				AddTabularSectionCompositionAdditionalSets(CurrentFilter.Items, AddingOptions)
				
			EndIf;
			
		EndDo;
	EndDo;
	
	// 
	Parameters = CompositionSchema.Parameters;
	Parameters.Find("InfobaseNode").Value = InfobaseNode;
	
	AutomaticallyParameter = Parameters.Find("RegistrationReasonAutomatically");
	AutomaticallyParameter.Value = NStr("en = 'By common rules';");
	
	AdditionallyParameter = Parameters.Find("RegistrationReasonAdvanced");
	AdditionallyParameter.Value = NStr("en = 'Additional registration';");
	
	ParameterByRef = Parameters.Find("RegistrationReasonByRef");
	ParameterByRef.Value = NStr("en = 'By reference';");
	
	If LimitUsageWithFilter Then
		Fields = CompositionSchema.DataSets.Find("ChangeRecords").Fields;
		Restriction = Fields.Find("RegistrationObjectType").UseRestriction;
		Restriction.Condition = True;
		Restriction = Fields.Find("RegistrationReason").UseRestriction;
		Restriction.Condition = True;
		
		Fields = CompositionSchema.DataSets.Find("NodeCompositionMetadataTable").Fields;
		Restriction = Fields.Find("ListPresentation").UseRestriction;
		Restriction.Condition = True;
		Restriction = Fields.Find("Presentation").UseRestriction;
		Restriction.Condition = True;
		Restriction = Fields.Find("FullMetadataName").UseRestriction;
		Restriction.Condition = True;
		Restriction = Fields.Find("Periodic3").UseRestriction;
		Restriction.Condition = True;
	EndIf;
	
	SettingsComposer = New DataCompositionSettingsComposer;
	
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(
		PutToTempStorage(CompositionSchema, SchemaSavingAddress)));
	SettingsComposer.LoadSettings(CompositionSchema.DefaultSettings);
	
	If AdditionalChangesTable.Count() > 0 Then 
		
		If LimitUsageWithFilter Then
			SettingsRoot = SettingsComposer.FixedSettings;
		Else
			SettingsRoot = SettingsComposer.Settings;
		EndIf;
		
		// 
		FilterGroup = SettingsRoot.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.Use = True;
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		FilterItems1 = FilterGroup.Items;
		
		// 
		AddFilterItem(FilterGroup.Items, "RegistrationReason", DataCompositionComparisonType.Equal, AutomaticallyParameter.Value);
		AddFilterItem(FilterGroup.Items, "RegistrationReason", DataCompositionComparisonType.Equal, ParameterByRef.Value);
		
		For Each String In AdditionalChangesTable Do
			FullMetadataName = String.FullMetadataName;
			CurrentFilter = String.Filter; // DataCompositionFilter
			FilterPeriod1 = String.Period; // StandardPeriod
			
			If MetadataNamesList <> Undefined And MetadataNamesFilter[FullMetadataName] <> True Then
				Continue;
			EndIf;
			
			TablesToAdd = EnlargedMetadataGroupComposition(FullMetadataName);
			For Each NameOfTableToAdd In TablesToAdd Do
				If MetadataNamesList <> Undefined And MetadataNamesFilter[NameOfTableToAdd] <> True Then
					Continue;
				EndIf;
				
				FilterGroup = FilterItems1.Add(Type("DataCompositionFilterItemGroup"));
				FilterGroup.Use = True;
				
				AddFilterItem(FilterGroup.Items, "FullMetadataName", DataCompositionComparisonType.Equal, NameOfTableToAdd);
				AddFilterItem(FilterGroup.Items, "RegistrationReason",  DataCompositionComparisonType.Equal, AdditionallyParameter.Value);
				
				If String.PeriodSelection Then
					StartDate    = FilterPeriod1.StartDate;
					EndDate = FilterPeriod1.EndDate;
					If StartDate <> '00010101' Then
						AddFilterItem(FilterGroup.Items, "RegistrationObject.Date", DataCompositionComparisonType.GreaterOrEqual, StartDate);
					EndIf;
					If EndDate <> '00010101' Then
						AddFilterItem(FilterGroup.Items, "RegistrationObject.Date", DataCompositionComparisonType.LessOrEqual, EndDate);
					EndIf;
				EndIf;
				
				// 
				AddingOptions = New Structure;
				AddingOptions.Insert("NameOfTableToAdd", NameOfTableToAdd);
				AddTabularSectionCompositionAdditionalFilters(
					FilterGroup.Items, CurrentFilter.Items, AddingOptions);
			EndDo;
		EndDo;
		
	EndIf;
	
	Return New Structure("NodeCompositionMetadataTable,CompositionSchema,SettingsComposer", 
		NodeCompositionMetadataTable, CompositionSchema, SettingsComposer);
EndFunction

Procedure AddTabularSectionCompositionAdditionalSets(SourceItems, AddingOptions)
	
	NameOfTableToAdd = AddingOptions.NameOfTableToAdd;
	CompositionSchema       = AddingOptions.CompositionSchema;
	
	SharedSet     = CompositionSchema.DataSets.Find("ChangeRecords");
	DataSource = CompositionSchema.DataSources.Get(0).Name; 
	
	ObjectMetadata = Metadata.FindByFullName(NameOfTableToAdd);
	If ObjectMetadata = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Invalid metadata name ""%1"" for registration at node ""%2"".';"),
				NameOfTableToAdd, InfobaseNode);
	EndIf;
	
	QueryTextTemplate2 = 
	"SELECT ALLOWED
	|	Ref                            AS RegistrationObject,
	|	&NameOfTableToAddType         AS RegistrationObjectType,
	|	&RegistrationReasonAdvanced  AS RegistrationReason
	|	,&AllTabularSectionFields
	|FROM
	|	&NameOfTableToAdd";
	
	For Each Item In SourceItems Do
		
		If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then 
			AddTabularSectionCompositionAdditionalSets(Item.Items, AddingOptions);
			Continue;
		EndIf;
		
		// 
		FieldName = Item.LeftValue;
		If StrStartsWith(FieldName, "Ref.") Then
			FieldName = Mid(FieldName, 8);
		ElsIf StrStartsWith(FieldName, "RegistrationObject.") Then
			FieldName = Mid(FieldName, 19);
		Else
			Continue;
		EndIf;
			
		Position = StrFind(FieldName, "."); 
		TableName   = Left(FieldName, Position - 1);
		TabularSectionMetadata = ObjectMetadata.TabularSections.Find(TableName);
			
		If Position = 0 Then
			// 
			Continue;
		ElsIf TabularSectionMetadata = Undefined Then
			// 
			Continue;
		EndIf;
		
		// 
		DataPath = Mid(FieldName, Position + 1);
		If StrStartsWith(DataPath + ".", "Ref.") Then
			// 
			Continue;
		EndIf;
		
		Alias = StrReplace(NameOfTableToAdd, ".", "") + TableName;
		SetName = "More_" + Alias;
		Set = SharedSet.Items.Find(SetName);
		If Set <> Undefined Then
			Continue;
		EndIf;
		
		Set = SharedSet.Items.Add(Type("DataCompositionSchemaDataSetQuery"));
		Set.AutoFillAvailableFields = True;
		Set.DataSource = DataSource;
		Set.Name = SetName;
		
		AllTabularSectionFields = TabularSectionAttributesForQuery(TabularSectionMetadata, Alias);
		NameOfTheAdditionalSelectionQueryTableToBeAdded = StringFunctionsClientServer.SubstituteParametersToString("%1.%2", NameOfTableToAdd, TableName);
		
		ReplacementString = StringFunctionsClientServer.SubstituteParametersToString("Type(%1)", NameOfTableToAdd);
		QueryText = StrReplace(QueryTextTemplate2, "&NameOfTableToAddType", ReplacementString);
		QueryText = StrReplace(QueryText, ",&AllTabularSectionFields", AllTabularSectionFields.QueryFields);
		QueryText = StrReplace(QueryText, "&NameOfTableToAdd", NameOfTheAdditionalSelectionQueryTableToBeAdded);
		Set.Query = QueryText;
		
		For Each FieldName In AllTabularSectionFields.FieldsNames Do
			Field = Set.Fields.Find(FieldName);
			If Field = Undefined Then
				Field = Set.Fields.Add(Type("DataCompositionSchemaDataSetField"));
				Field.DataPath = FieldName;
				Field.Field        = FieldName;
			EndIf;
			Field.AttributeUseRestriction.Condition = True;
			Field.AttributeUseRestriction.Field    = True;
			Field.UseRestriction.Condition = True;
			Field.UseRestriction.Field    = True;
		EndDo;
		
	EndDo;
		
EndProcedure

Procedure AddTabularSectionCompositionAdditionalFilters(DestinationItems, SourceItems, AddingOptions)
	
	NameOfTableToAdd = AddingOptions.NameOfTableToAdd;
	MetaObject1 = Metadata.FindByFullName(NameOfTableToAdd);
	
	For Each Item In SourceItems Do
		// 
		
		Type = TypeOf(Item); 
		If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then
			// 
			FilterElement = DestinationItems.Add(Type);
			FillPropertyValues(FilterElement, Item);
			
			AddTabularSectionCompositionAdditionalFilters(
				FilterElement.Items, Item.Items, AddingOptions);
			Continue;
		EndIf;
		
		// 
		FieldName = String(Item.LeftValue);
		If FieldName = "Ref" Then
			FilterElement = DestinationItems.Add(Type);
			FillPropertyValues(FilterElement, Item);
			FilterElement.LeftValue = New DataCompositionField("RegistrationObject");
			Continue;
			
		ElsIf StrStartsWith(FieldName, "Ref.") Then
			FieldName = Mid(FieldName, 8);
			
		ElsIf StrStartsWith(FieldName, "RegistrationObject.") Then
			FieldName = Mid(FieldName, 19);
			
		Else
			FilterElement = DestinationItems.Add(Type);
			FillPropertyValues(FilterElement, Item);
			Continue;
			
		EndIf;
			
		Position    = StrFind(FieldName, "."); 
		TableName = Left(FieldName, Position - 1);
		
		MetaTabularSection = MetaObject1.TabularSections.Find(TableName);
		MetaAttributes      = MetaObject1.Attributes.Find(TableName);
			
		If Position = 0
			Or MetaAttributes <> Undefined
			Or Common.IsStandardAttribute(MetaObject1.StandardAttributes, TableName) Then
			// 
			FilterElement = DestinationItems.Add(Type);
			FillPropertyValues(FilterElement, Item);
			FilterElement.LeftValue = New DataCompositionField("RegistrationObject." + FieldName);
			Continue;
			
		ElsIf MetaTabularSection = Undefined Then
			// 
			FilterElement = DestinationItems.Add(Type);
			FillPropertyValues(FilterElement, Item);
			FilterElement.LeftValue  = New DataCompositionField("FullMetadataName");
			FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
			FilterElement.Use  = True;
			FilterElement.RightValue = "";
			
			Continue;
		EndIf;
		
		// 
		DataPath = Mid(FieldName, Position + 1);
		If StrStartsWith(DataPath + ".", "Ref.") Then
			// 
			FilterElement = DestinationItems.Add(Type);
			FillPropertyValues(FilterElement, Item);
			FilterElement.LeftValue = New DataCompositionField("RegistrationObject." + Mid(DataPath, 8));
			
		ElsIf DataPath <> "LineNumber" And DataPath <> "Ref"
			And MetaTabularSection.Attributes.Find(DataPath) = Undefined Then
			// 
			FilterElement = DestinationItems.Add(Type);
			FillPropertyValues(FilterElement, Item);
			FilterElement.LeftValue  = New DataCompositionField("FullMetadataName");
			FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
			FilterElement.Use  = True;
			FilterElement.RightValue = "";
			
		Else
			// 
			FilterElement = DestinationItems.Add(Type);
			FillPropertyValues(FilterElement, Item);
			DataPath = StrReplace(NameOfTableToAdd + TableName, ".", "") + DataPath;
			FilterElement.LeftValue = New DataCompositionField(DataPath);
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use only.
//
// Parameters:
//   MetaTabularSection - MetadataObjectTabularSection -  metadata of the table part.
//   Prefix - String -  prefix of the prop name.
//
Function TabularSectionAttributesForQuery(Val MetaTabularSection, Val Prefix = "")
	
	QueryFields = ", LineNumber AS " + Prefix + "LineNumber
	              |, Ref      AS " + Prefix + "Ref
	              |";
	
	FieldsNames  = New Array;
	FieldsNames.Add(Prefix + "LineNumber");
	FieldsNames.Add(Prefix + "Ref");
	
	For Each MetaAttribute In MetaTabularSection.Attributes Do
		Name       = MetaAttribute.Name;
		Alias = Prefix + Name;
		QueryFields = QueryFields + ", " + Name + " AS " + Alias + Chars.LF;
		FieldsNames.Add(Alias);
	EndDo;
	
	Return New Structure("QueryFields, FieldsNames", QueryFields, FieldsNames);
EndFunction

//  Returns key parameters for saving settings in the context of the exchange plan for all users.
//
//  Parameters:
//      ExchangeNode - ExchangePlanRef -  link to the exchange node for the returned settings. If not specified,
//                                      the current value of the "node information Database" attribute is used.
//
//  Returns:
//      SettingsDescription - 
//
Function SettingsParameterStructure(ExchangeNode = Undefined)
	Node = ?(ExchangeNode=Undefined,  InfobaseNode, ExchangeNode);
	
	Meta = Node.Metadata();
	
	Presentation = Meta.ExtendedObjectPresentation;
	If IsBlankString(Presentation) Then
		Presentation = Meta.ObjectPresentation;
	EndIf;
	If IsBlankString(Presentation) Then
		Presentation = String(Meta);
	EndIf;
	
	SettingsParameters = New SettingsDescription();
	SettingsParameters.Presentation = Presentation;
	SettingsParameters.ObjectKey   = "InteractiveExportSettingsOptions";
	SettingsParameters.SettingsKey  = Meta.Name;
	SettingsParameters.User  = "*";
	
	Return SettingsParameters;
EndFunction

// Returns a list of settings values for the current value of the "information database Node".
//
// Parameters:
//      Variants - Array -  if specified, we filter the restored settings by options
//                          0-no selection, 1-selection of all documents, 2-detailed, 3 - node scenario.
//
//  Returns:
//      ValueList -  customization.
//
Function ReadSettingsList(Variants = Undefined)
	SettingsParameters = SettingsParameterStructure();
	
	SetPrivilegedMode(True);
	VariantList = CommonSettingsStorage.Load(
		SettingsParameters.ObjectKey, SettingsParameters.SettingsKey, 
		SettingsParameters, SettingsParameters.User);
		
	If VariantList=Undefined Then
		Result = New ValueList;
	ElsIf Variants=Undefined Then
		Result = VariantList;
	Else
		Result = VariantList;
		Position = Result.Count() - 1;
		While Position>=0 Do
			If Variants.Find(Result[Position].Value.ExportOption)=Undefined Then
				Result.Delete(Position);
			EndIf;
			Position = Position - 1
		EndDo;
	EndIf;
		
	Return Result;
EndFunction

// Saves a list of settings values for the current value of the "information database Node".
//
//  Parameters:
//      VariantList - ValueList -  a saved list of options.
//
Procedure SaveSettingsList(VariantList)
	SettingsParameters = SettingsParameterStructure();
	
	SetPrivilegedMode(True);
	If VariantList.Count()=0 Then
		CommonSettingsStorage.Delete(
			SettingsParameters.ObjectKey, SettingsParameters.SettingsKey, SettingsParameters.User);
	Else
		CommonSettingsStorage.Save(
			SettingsParameters.ObjectKey, SettingsParameters.SettingsKey, 
			VariantList, 
			SettingsParameters, SettingsParameters.User);
	EndIf;        
EndProcedure

// Returns a description of a variant of all additional parameters.
//
Function AdditionalParameterText()
	
	If ExportOption = 0 Then
		// 
		Return NStr("en = 'No additional data.';");
		
	ElsIf ExportOption = 1 Then
		AllDocumentsText = AllDocumentsFilterGroupTitle();
		Result = FilterPresentation(AllDocumentsFilterPeriod, AllDocumentsFilterComposer, AllDocumentsText);
		Return StrReplace(Result, "RegistrationObject.", AllDocumentsText + ".")
		
	ElsIf ExportOption = 2 Then
		Return DetailedFilterPresentation();
		
	EndIf;
	
	Return "";
EndFunction

// Returns a structure with the object's details.
//
Function ThisObjectInStructureForBackgroundJob() Export
	ResultStructure1 = New Structure();

	For Each Meta In Metadata().Attributes Do
		AttributeName = Meta.Name;
		If AttributeName = "AllDocumentsFilterComposer" Then
			Continue;
		EndIf;
		
		ResultStructure1.Insert(AttributeName, ThisObject[AttributeName]);
	EndDo;
	// 
	ResultStructure1.Insert("AllDocumentsFilterComposer");

	// 
	ResultStructure1.Insert("AllDocumentsFilterComposerSettings1", AllDocumentsFilterComposer.Settings);
	
	Return ResultStructure1;
EndFunction

Procedure HideSelectionFields(GroupItems, Val FieldsToHide)
	TypeGroup = Type("DataCompositionSelectedFieldGroup");
	For Each GroupItem2 In GroupItems Do
		If TypeOf(GroupItem2)=TypeGroup Then
			HideSelectionFields(GroupItem2.Items, FieldsToHide)
		Else
			FieldName = StrReplace(String(GroupItem2.Field), ".", "");
			If Not IsBlankString(FieldName) And FieldsToHide.Property(FieldName) Then
				GroupItem2.Use = False;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf