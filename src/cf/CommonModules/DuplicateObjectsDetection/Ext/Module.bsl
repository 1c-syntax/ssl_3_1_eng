///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// 
//
// Parameters:
//     SearchArea - String -  name of the data table (full metadata name) of the search area.
//                              For Example, " Directory.Nomenclature". Search is supported in reference books, 
//                              plans for types of characteristics, types of calculations, and plans of accounts.
//     SampleObject - AnyRef, CatalogObject - 
//     AdditionalParameters - Arbitrary -  parameter to pass to the Manager's event handlers.
//
// Returns:
//     ValueTable:
//       * Ref       - AnyRef -  the link of the item.
//       * Code          - String
//                      - Number - 
//       * Description - String -  name of the element.
//       * Parent     - AnyRef -  parent of the duplicate group. If the Parent is empty, the element is
//                                      the parent of the duplicate group.
//       * OtherFields - Arbitrary -  the value of the corresponding selection fields and criteria for comparing duplicates.
// 
Function FindItemDuplicates(Val SearchArea, Val SampleObject, Val AdditionalParameters) Export
	
	DuplicatesSearchParameters = New Structure;
	DuplicatesSearchParameters.Insert("PrefilterComposer");
	DuplicatesSearchParameters.Insert("DuplicatesSearchArea", SearchArea);
	DuplicatesSearchParameters.Insert("TakeAppliedRulesIntoAccount", True);
	
	// 
	DuplicatesSearchParameters.Insert("SearchRules", New ValueTable);
	DuplicatesSearchParameters.SearchRules.Columns.Add("Attribute", New TypeDescription("String"));
	DuplicatesSearchParameters.SearchRules.Columns.Add("Rule",  New TypeDescription("String"));
	
	// See DataProcessor.DuplicateObjectsDetection
	DuplicatesSearchParameters.PrefilterComposer = New DataCompositionSettingsComposer;
	SearchAreaMetadata = Common.MetadataObjectByFullName(SearchArea);
	AvailableFilterAttributes = AvailableFilterAttributesNames(SearchAreaMetadata.StandardAttributes);
	AvailableFilterAttributes = ?(IsBlankString(AvailableFilterAttributes), ",", AvailableFilterAttributes)
		+ AvailableFilterAttributesNames(SearchAreaMetadata.Attributes);
	QueryText = "SELECT * FROM #Table";
	QueryText = StrReplace(QueryText, "*", Mid(AvailableFilterAttributes, 2));
	QueryText = StrReplace(QueryText, "#Table", SearchArea);
	
	CompositionSchema = New DataCompositionSchema;
	DataSource = CompositionSchema.DataSources.Add();
	DataSource.DataSourceType = "Local";
	
	DataSet = CompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Query = QueryText;
	DataSet.AutoFillAvailableFields = True;
	
	DuplicatesSearchParameters.PrefilterComposer.Initialize(
		New DataCompositionAvailableSettingsSource(CompositionSchema));
	
	SearchProcessing = DataProcessors.DuplicateObjectsDetection.Create();
	
	UseAppliedRules = SearchProcessing.HasSearchForDuplicatesAreaAppliedRules(SearchArea);
	If UseAppliedRules Then
		AppliedParameters = DuplicatesSearchParameters(DuplicatesSearchParameters.SearchRules, 
			DuplicatesSearchParameters.PrefilterComposer);
		SearchAreaManager = SearchProcessing.SearchForDuplicatesAreaManager(SearchArea);
		SearchAreaManager.DuplicatesSearchParameters(AppliedParameters, AdditionalParameters);
		DuplicatesSearchParameters.Insert("AdditionalParameters", AdditionalParameters);
	EndIf;
	
	DuplicatesGroups = SearchProcessing.DuplicatesGroups(DuplicatesSearchParameters, SampleObject);
	Result = DuplicatesGroups.DuplicatesTable;
	
	For Each Item In Result.FindRows(New Structure("Parent", Undefined)) Do
		Result.Delete(Item);
	EndDo;
	EmptyRef = SearchAreaManager.EmptyRef();
	For Each Item In Result.FindRows(New Structure("Ref", EmptyRef)) Do
		Result.Delete(Item);
	EndDo;
	
	Return Result; 
EndFunction

// 
//
// Parameters:
//  ReplacementPairs		 - See Common.ReplaceReferences.ReplacementPairs
//  ReplacementParameters	 - See Common.RefsReplacementParameters
//
Procedure SupplementDuplicatesWithLinkedSubordinateObjects(ReplacementPairs, ReplacementParameters) Export
	
	ObjectsLinks = Common.SubordinateObjects();
	SubordinateObjectsLinks = SubordinateObjectsLinksByTypes();
	SubordinateObjectsDetails = New Map;

	For Each LinkRow In ObjectsLinks Do
		AddSubordinateObjectsLinks(SubordinateObjectsLinks, LinkRow);	
    	FillObjectDetails(SubordinateObjectsDetails, LinkRow);
	EndDo;
	
	ReplacementTables = New Map;
	For Each OriginalDuplicate In ReplacementPairs Do
		SelectUsedLinks(OriginalDuplicate.Value, SubordinateObjectsLinks);
		AddToReplacementTables(OriginalDuplicate, ReplacementTables, SubordinateObjectsLinks);
	EndDo;

	Filter = New Structure("Used", True);
	UsedLinks = SubordinateObjectsLinks.Copy(Filter);
	If UsedLinks.Count() = 0 Then
		Return;
	EndIf;
	UsedLinks.Sort("Key");
	
	TempTablesManager = New TempTablesManager;
	PutReplacementsTablesInQuery(TempTablesManager, ReplacementTables);

	FoundDuplicatesTables = New Map;
	PackageParts = New Array;
	Position = 0;
	While Position <= UsedLinks.Count() - 1 Do
		
		SubordinateObjectName = UsedLinks[Position].Key;
		SubordinateObjectDetails = SubordinateObjectsDetails[SubordinateObjectName];
		Filter = New Structure("Key, Used", SubordinateObjectName, True);
		SubordinateObjectLinks = SubordinateObjectsLinks.FindRows(Filter);
		PackageParts.Add(ObjectsForReplacementQueryText( SubordinateObjectDetails, SubordinateObjectLinks));
		
		FoundDuplicatesTables.Insert(SubordinateObjectDetails.Key, PackageParts.Count() * 3 - 1); //  
		Position = Position + SubordinateObjectLinks.Count();
	
	EndDo;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = StrConcat(PackageParts, Common.QueryBatchSeparator());	
	Result = Query.ExecuteBatch();
	
	For Each Replacement In FoundDuplicatesTables Do
		
		NotPickedReplacements = New Array;
		SubordinateObjectDetails = SubordinateObjectsDetails[Replacement.Key];
		PickedReplacements = Result[Replacement.Value].Unload();
		
		AddFoundKeysToDuplicates(PickedReplacements, ReplacementPairs, NotPickedReplacements);
		
		If ValueIsFilled(SubordinateObjectDetails.SearchMethodModuleName) 
			And NotPickedReplacements.Count() > 0 Then
			ExecuteSearchByAppliedRules(UsedLinks, NotPickedReplacements, SubordinateObjectDetails,
				ReplacementPairs);
		EndIf;
	
	EndDo;
	
EndProcedure

// 
//
// Parameters:
//  InitialString - String - 
//                            
//  SearchString   - String - 
//  Separator    - String - 
//                            
//  SearchParameters - See ParametersOfSearchForSimilarStrings.
//
// Example:
//  
//  
//  
//  
//
// Returns:
//  String - 
//
Function FindSimilarStrings(InitialString, SearchString, Separator = "~", SearchParameters = Undefined) Export
	
	CreateAddIn = TypeOf(SearchParameters) <> Type("Structure")
		Or Not SearchParameters.Property("SearchAddIn")
		Or SearchParameters.SearchAddIn = Undefined;
	
	StringsComparisonForSimilarity = ParametersOfSearchForSimilarStrings(CreateAddIn);
	If TypeOf(SearchParameters) = Type("Structure") Then
		FillPropertyValues(StringsComparisonForSimilarity, SearchParameters, , ?(CreateAddIn, "SearchAddIn", ""));
	EndIf;
	
	SearchAddIn = StringsComparisonForSimilarity.SearchAddIn;
	ExceptionWords = Lower(StrConcat(StringsComparisonForSimilarity.ExceptionWords, Separator));
	
	RowIndexes = SearchAddIn.StringSearch(Lower(SearchString), Lower(InitialString), "~", 
		StringsComparisonForSimilarity.SmallStringsLength, StringsComparisonForSimilarity.SmallStringsMatchPercentage, 
		StringsComparisonForSimilarity.StringsMatchPercentage, ExceptionWords);
	
	Return RowIndexes;
	
EndFunction

// 
// 
// Parameters:
//  AttachAddInSSL - Boolean - 
//                                  
//                                  
// 
// Returns:
//  Structure:
//     * StringsMatchPercentage          - Number - 
//     * SmallStringsMatchPercentage - Number - 
//     * SmallStringsLength             - Number - 
//     * ExceptionWords - Array of String
//     * SearchAddIn - AddInObject
//
Function ParametersOfSearchForSimilarStrings(AttachAddInSSL = True) Export
	
	Result = New Structure;
	Result.Insert("StringsMatchPercentage", 90);
	Result.Insert("SmallStringsMatchPercentage", 80);
	Result.Insert("SmallStringsLength", 30);
	Result.Insert("ExceptionWords", New Array);
	If AttachAddInSSL Then
		SetSafeModeDisabled(True);
		FuzzySearch1 = Common.AttachAddInFromTemplate("FuzzyStringMatchExtension", 
			"CommonTemplate.StringSearchAddIn");
		If FuzzySearch1 = Undefined Then
			Raise NStr("en = 'Cannot attach the fuzzy search add-in. See the Event log for details.';");
		EndIf;
		Result.Insert("SearchAddIn", FuzzySearch1);
	Else
		Result.Insert("SearchAddIn", Undefined);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

// Called when searching for possible duplicates to filter where possible duplicates appear
// in the duplicate search workplace at the last step of the assistant
//
// Returns:
//   Array of Type
//
Function TypesToExcludeFromPossibleDuplicates() Export

	TypesToExclude = New Array;
	SSLSubsystemsIntegration.OnAddTypesToExcludeFromPossibleDuplicates(TypesToExclude);		
	Return TypesToExclude;

EndFunction

Function CheckCanReplaceItemsString(ReplacementPairs, ReplacementParameters) Export
	
	Result = "";
	Errors = CheckCanReplaceItems(ReplacementPairs, ReplacementParameters);
	For Each KeyValue In Errors Do
		Result = Result + Chars.LF + KeyValue.Value;
	EndDo;
	Return TrimAll(Result);
	
EndFunction

Function CheckCanReplaceItems(ReplacementPairs, ReplacementParameters) Export
	
	If ReplacementPairs.Count() = 0 Then
		Return New Map;
	EndIf;
	
	For Each Item In ReplacementPairs Do
		TheFirstControl = Item.Key;
		Break;
	EndDo;
	
	Result = New Map;
	
	MetadataObjectName = TheFirstControl.Metadata().FullName();
	ObjectInfo = ObjectsWithDuplicatesSearch()[MetadataObjectName];
	If ObjectInfo <> Undefined And (ObjectInfo = "" 
		Or StrFind(ObjectInfo, "CanReplaceItems") > 0) Then
		ManagerModule = Common.ObjectManagerByRef(TheFirstControl);
		Result = ManagerModule.CanReplaceItems(ReplacementPairs, ReplacementParameters);
	EndIf;
	
	DuplicateObjectsDetectionOverridable.OnDefineItemsReplacementAvailability(MetadataObjectName, ReplacementPairs, 
		ReplacementParameters, Result);
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.SearchForReferences);
EndProcedure

// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	
	If AttachableCommandsKinds.Find("Administration", "Name") = Undefined Then
		
		Kind = AttachableCommandsKinds.Add();
		Kind.Name         = "Administration";
		Kind.SubmenuName  = "Service";
		Kind.Title   = NStr("en = 'Tools';");
		Kind.Order     = 80;
		Kind.Picture    = PictureLib.ServiceSubmenu;
		Kind.Representation = ButtonRepresentation.PictureAndText;	
		
	EndIf;
	
EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	AttachedObjects = ObjectsWithDuplicatesMergeCommands();
	For Each AttachedObject In AttachedObjects Do
		
		If AccessRight("Update", AttachedObject)
			And Sources.Rows.Find(AttachedObject, "Metadata") <> Undefined Then
			
			Command = Commands.Add();
			Command.Kind = "Administration";
			Command.Importance = "SeeAlso";
			Command.Presentation = NStr("en = 'Merge selected items…';");
			Command.WriteMode = "NotWrite";
			Command.VisibilityInForms = "ListForm";
			Command.MultipleChoice = True;
			Command.Handler = "DuplicateObjectsDetectionClient.MergeSelectedItems";
			Command.OnlyInAllActions = True;
			Command.Order = 40;
			
			Command = Commands.Add();
			Command.Kind = "Administration";
			Command.Importance = "SeeAlso";
			Command.Presentation = NStr("en = 'Replace selected items…';");
			Command.WriteMode = "NotWrite";
			Command.VisibilityInForms = "ListForm";
			Command.MultipleChoice = True;
			Command.Handler = "DuplicateObjectsDetectionClient.ReplaceSelected";
			Command.OnlyInAllActions = True;
			Command.Order = 40;
			
		EndIf;	
	
	EndDo;

EndProcedure

#EndRegion

#Region Private

// See DataProcessor.DuplicateObjectsDetection.
Function AvailableFilterAttributesNames(Val MetadataCollection)
	Result = "";
	StoreType = Type("ValueStorage");
	
	For Each Attribute In MetadataCollection Do
		IsStorage = Attribute.Type.ContainsType(StoreType);
		If Not IsStorage Then
			Result = Result + "," + Attribute.Name;
		EndIf
	EndDo;
	
	Return Result;
EndFunction

Procedure DefineUsageInstances(Val RefSet, Val ResultAddress) Export
	
	SearchTable = Common.UsageInstances(RefSet);
	
	Filter = New Structure("IsInternalData", False);
	ActualRows = SearchTable.FindRows(Filter);
	
	Result = SearchTable.Copy(ActualRows, "Ref");
	Result.Columns.Add("Occurrences", New TypeDescription("Number"));
	Result.FillValues(1, "Occurrences");
	
	Result.Indexes.Add("Ref");
	
	Result.GroupBy("Ref", "Occurrences");
	For Each Ref In RefSet Do
		If Result.Find(Ref, "Ref") = Undefined Then
			Result.Add().Ref = Ref;
		EndIf;
	EndDo;
	
	PutToTempStorage(Result, ResultAddress);
EndProcedure

// Replaces links in all data in the information database. 
//
// Parameters:
//     Parameters - Structure:
//       * ReplacementPairs - Map of KeyAndValue:
//           * Key     - AnyRef -  what we are looking for (double).
//           * Value - AnyRef -  what we replace (the original).
//           Links to themselves and empty search links will be ignored.
//       * DeletionMethod - String -  optional. What to do with the duplicate after a successful replacement.
//           ""- By default. Do not take any action.
//           "Mark" - Mark for deletion.
//           "Directly" - Delete directly.
//     ResultAddress - String - :
//       * Ref - AnyRef -  the link that was replaced.
//       * ErrorObject - Arbitrary - 
//       * ErrorObjectPresentation - String -  string representation of the error object.
//       * ErrorType - String - :
//                              
//                              
//                              
//                              
//                                                    
//                              
//       * ErrorText - String -  detailed description of the error.
//
Procedure ReplaceReferences(Parameters, Val ResultAddress) Export
	
	RefsReplacementParameters = Common.RefsReplacementParameters();
	RefsReplacementParameters.DeletionMethod = Parameters.DeletionMethod;
	RefsReplacementParameters.IncludeBusinessLogic = True;
	RefsReplacementParameters.ReplacePairsInTransaction = False;
	
	Result = Common.ReplaceReferences(Parameters.ReplacementPairs, RefsReplacementParameters);
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

// Generates a table of served metadata objects and their General settings.
//
// Returns:
//   ValueTable:
//       * FullName             - String   -  full name of the metadata of the table object.
//       * ItemPresentation - String   -  representation of the element for the user.
//       * ListPresentation   - String   -  list view for the user.
//       * Removed                - Boolean   -  this is a metadata object with the "Delete" prefix.
//       * EventDuplicateSearchParameters      - Boolean -  the Manager module defines a handler for element Substitutionability.
//       * EventOnDuplicatesSearch            - Boolean -  the Manager module defines a handler for searchable Parameters.
//       * EventCanReplaceItems - Boolean -  in the module Manager defined handler Preposterously.
//
Function MetadataObjectsSettings() Export
	Settings = New ValueTable;
	Settings.Columns.Add("Kind",                   New TypeDescription("String"));
	Settings.Columns.Add("FullName",             New TypeDescription("String"));
	Settings.Columns.Add("ItemPresentation", New TypeDescription("String"));
	Settings.Columns.Add("ListPresentation",   New TypeDescription("String"));
	Settings.Columns.Add("Removed",                New TypeDescription("Boolean"));
	Settings.Columns.Add("EventDuplicateSearchParameters",      New TypeDescription("Boolean"));
	Settings.Columns.Add("EventOnDuplicatesSearch",            New TypeDescription("Boolean"));
	Settings.Columns.Add("EventCanReplaceItems", New TypeDescription("Boolean"));
	
	ListOfObjects = ObjectsWithDuplicatesSearch();
	RegisterMetadataCollection(Settings, ListOfObjects, Metadata.Catalogs, "Catalog");
	RegisterMetadataCollection(Settings, ListOfObjects, Metadata.Documents, "Document");
	RegisterMetadataCollection(Settings, ListOfObjects, Metadata.ChartsOfAccounts, "ChartOfAccounts");
	RegisterMetadataCollection(Settings, ListOfObjects, Metadata.ChartsOfCalculationTypes, "ChartOfCalculationTypes");
	RegisterMetadataCollection(Settings, ListOfObjects, Metadata.ChartsOfCharacteristicTypes, "ChartOfCharacteristicTypes");
	
	Result = Settings.Copy(New Structure("Removed", False));
	Result.Sort("ListPresentation");
	
	Return Result;
EndFunction

Function ObjectsWithDuplicatesSearch() Export
	
	ListOfObjects = New Map;
	SSLSubsystemsIntegration.OnDefineObjectsWithSearchForDuplicates(ListOfObjects);
	DuplicateObjectsDetectionOverridable.OnDefineObjectsWithSearchForDuplicates(ListOfObjects);
	Return ListOfObjects;

EndFunction

Procedure RegisterMetadataCollection(Settings, ListOfObjects, MetadataCollection, Kind)
	
	For Each MetadataObject In MetadataCollection Do
		If Not AccessRight("View", MetadataObject)
			Or Not Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject) Then
			Continue; // 
		EndIf;
		
		TableRow = Settings.Add();
		TableRow.Kind = Kind;
		TableRow.FullName = MetadataObject.FullName();
		TableRow.Removed = StrStartsWith(MetadataObject.Name, "Delete");
		TableRow.ItemPresentation = Common.ObjectPresentation(MetadataObject);
		TableRow.ListPresentation = Common.ListPresentation(MetadataObject);
		
		Events = ListOfObjects[TableRow.FullName];
		If TypeOf(Events) = Type("String") Then
			If IsBlankString(Events) Then
				TableRow.EventDuplicateSearchParameters      = True;
				TableRow.EventOnDuplicatesSearch            = True;
				TableRow.EventCanReplaceItems = True;
			Else
				TableRow.EventDuplicateSearchParameters      = StrFind(Events, "DuplicatesSearchParameters") > 0;
				TableRow.EventOnDuplicatesSearch            = StrFind(Events, "OnSearchForDuplicates") > 0;
				TableRow.EventCanReplaceItems = StrFind(Events, "CanReplaceItems") > 0;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

// Representation of the subsystem. Used when writing to the log and in other places.
Function SubsystemDescription(ForUser) Export
	LanguageCode = ?(ForUser, Common.DefaultLanguageCode(), "");
	Return NStr("en = 'Duplicate cleaner';", LanguageCode);
EndFunction

// Parameters:
//  SearchRules - ValueTable:
//    * Attribute - String 
//    * Rule - String 
//  PrefilterComposer - DataCompositionSettingsComposer
//
// Returns:
//  Structure:
//    * SearchRules - ValueTable:
//        ** Attribute - String
//        ** Rule - String
//    * StringsComparisonForSimilarity - Structure:
//        ** StringsMatchPercentage - Number
//        ** SmallStringsMatchPercentage - Number
//        ** SmallStringsLength - Number
//        ** ExceptionWords - Array
//    * FilterComposer - DataCompositionSettingsComposer
//    * ComparisonRestrictions - Array
//    * ItemsCountToCompare - Number
//
Function DuplicatesSearchParameters(SearchRules, PrefilterComposer) Export
	
	StringsComparisonForSimilarity = New Structure;
	StringsComparisonForSimilarity.Insert("StringsMatchPercentage", 90);
	StringsComparisonForSimilarity.Insert("SmallStringsMatchPercentage", 80);
	StringsComparisonForSimilarity.Insert("SmallStringsLength", 30);
	StringsComparisonForSimilarity.Insert("ExceptionWords", New Array);
	
	Result = New Structure;
	Result.Insert("SearchRules",        SearchRules);
	Result.Insert("StringsComparisonForSimilarity", StringsComparisonForSimilarity);
	Result.Insert("FilterComposer",    PrefilterComposer);
	Result.Insert("ComparisonRestrictions", New Array);
	Result.Insert("ItemsCountToCompare", 1500);
	Result.Insert("HideInsignificantDuplicates", True);
	Return Result;
	
EndFunction

#Region ReplaceDuplicatesInDimensionKeys

// See Common.SubordinateObjectsLinksByTypes.
Function SubordinateObjectsLinksByTypes() Export

	Return Common.SubordinateObjectsLinksByTypes();

EndFunction 

Procedure AddSubordinateObjectsLinks(SubordinateObjectsLinks, LinkRow)
	
	KeyAttributes = StringFunctionsClientServer.SplitStringIntoSubstringsArray(LinkRow.LinksFields,",",,True);
	SubordinateObjectName = LinkRow.SubordinateObject.FullName();
	For Each AttributeName In KeyAttributes Do
		
		If CommonClientServer.HasAttributeOrObjectProperty(
				LinkRow.SubordinateObject.StandardAttributes, AttributeName) Then
		
			AttributeType = LinkRow.SubordinateObject.StandardAttributes[AttributeName];
			For Each AttributeType In AttributeType.Type.Types() Do
				
				Record = SubordinateObjectsLinks.Add();	
				Record.Key = SubordinateObjectName;
				Record.AttributeType = AttributeType;
				Record.AttributeName = AttributeName;
				
			EndDo;
			
		ElsIf CommonClientServer.HasAttributeOrObjectProperty(
				LinkRow.SubordinateObject.Attributes, AttributeName) Then
			
			AttributeType = LinkRow.SubordinateObject.Attributes[AttributeName];
			For Each AttributeType In AttributeType.Type.Types() Do
				
				Record = SubordinateObjectsLinks.Add();	
				Record.Key = SubordinateObjectName;
				Record.AttributeType = AttributeType;
				Record.AttributeName = AttributeName;
				
			EndDo;
			
		Else 
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Link field %1 does not exist in metadata object %2';"), 
				AttributeName, SubordinateObjectName);
			Raise ErrorDescription;
		EndIf;
			
	EndDo;

EndProcedure

Procedure FillObjectDetails(SubordinateObjectsDetails, LinkRow)
	
	SubordinateObjectName = LinkRow.SubordinateObject.FullName();
	KeyAttributes = StringFunctionsClientServer.SplitStringIntoSubstringsArray(LinkRow.LinksFields,",",,True);
	
	ObjectDetails = NewSubordinateObjectDetails();
	ObjectDetails.Key = SubordinateObjectName;
	ObjectDetails.KeyAttributes = KeyAttributes;
	ObjectDetails.SearchMethodModuleName = LinkRow.OnSearchForReferenceReplacement;
	ObjectDetails.RunAutoSearch = LinkRow.RunReferenceReplacementsAutoSearch;
	
	SubordinateObjectsDetails.Insert(SubordinateObjectName, ObjectDetails);

EndProcedure

Function NewSubordinateObjectDetails()

	ObjectDetails = New Structure;
	ObjectDetails.Insert("Key");
	ObjectDetails.Insert("KeyAttributes");
	ObjectDetails.Insert("SearchMethodModuleName");
	ObjectDetails.Insert("RunAutoSearch");
	Return ObjectDetails;

EndFunction

Procedure SelectUsedLinks(Duplicate1, SubordinateObjectsLinks) 

	If SubordinateObjectsLinks.Find(TypeOf(Duplicate1), "AttributeType") = Undefined Then
		Return;	
	EndIf;
	
	RefMetadata = Duplicate1.Metadata();
	If SubordinateObjectsLinks.Find(RefMetadata, "Metadata") <> Undefined Then
		Return;
	EndIf;
	
	UsedLinks = SubordinateObjectsLinks.FindRows(New Structure("AttributeType",TypeOf(Duplicate1)));
	For Each Link In UsedLinks Do
		
		Link.Metadata = RefMetadata;
		Link.Used = True;
		
	EndDo;
	
EndProcedure

// Parameters:
//   ReplacementTable - ValueTable:
//   * Ref - AnyRef
//   * Replacement - AnyRef
//   ReplacementPairs - Map
//   NotPickedReplacements - Array of AnyRef
//
Procedure AddFoundKeysToDuplicates(ReplacementTable, ReplacementPairs, NotPickedReplacements)

	For Each FoundDuplicate In ReplacementTable Do
	
		If FoundDuplicate.Replacement = NULL Then
			NotPickedReplacements.Add(FoundDuplicate);	
		Else
			ReplacementPairs.Insert(FoundDuplicate.Ref, FoundDuplicate.Replacement);
		EndIf;	
		
	EndDo;
	
EndProcedure

// Parameters:
//   FoundDuplicate - ValueTableRow:
//   * Ref - AnyRef
//   * Replacement - AnyRef
//   SubordinateObjectDetails - Arbitrary
//   UsedLinks - ValueTable:
//   * Key - Type
//   * AttributeType - String
//   * AttributeName - String
//   * Used - Boolean
//   * Metadata - MetadataObject
// Returns:
//   Structure:
//   * UsedLinks - ValueTable:
//     ** Key - Type
//     ** AttributeType - String
//     ** AttributeName - String
//     ** Used - Boolean
//     ** Metadata - MetadataObject
//   * ValueToReplace - AnyRef 
//
Function NewReplacementParameters(FoundDuplicate, SubordinateObjectDetails, UsedLinks)

	ReplacementParameters = New Structure;
	ReplacementParameters.Insert("ValueToReplace", FoundDuplicate.Ref);
	ReplacementParameters.Insert("UsedLinks",
		UsedLinks.Copy(New Structure("Key",SubordinateObjectDetails.Key)));
	ReplacementParameters.Insert("KeyAttributesValue", New Structure);
	
	KeyAttributes = SubordinateObjectDetails.KeyAttributes;	
	For Each KeyAttribute In KeyAttributes Do
		ReplacementParameters.KeyAttributesValue.Insert(KeyAttribute, FoundDuplicate[KeyAttribute]);
	EndDo;

	Return ReplacementParameters;

EndFunction

Function ObjectsForReplacementQueryText(SubordinateObjectDetails, Links)

	QueryText = QueryTemplate();

	KeyName = StrReplace(SubordinateObjectDetails.Key, ".", "");
	KeyTable = SubordinateObjectDetails.Key;

	NotAttributesToChange = "";
	AttributesToChange = "";
	KeysValue = "";
	ValueAttributesToChange = "";
	ConnectionValueOfAttributesToReplace = "";
	LinksByKey = "";
	
	AttributesToChangeArray = New Array;
	If SubordinateObjectDetails.RunAutoSearch Then
	
		For Each Link In Links Do
			AttributesToChangeArray.Add(Link.AttributeName);
		EndDo;	
	
	EndIf;
	
	For Each KeyAttribute In SubordinateObjectDetails.KeyAttributes Do
		
		Value = "UNION" // @query-part
			+ StrReplace(" SELECT
							|	Tab.Ref AS Ref,
							|	&NotAttributesToChange,
							|	&AttributesToChange
							|FROM
							|	#KeyTable AS Tab
							|WHERE
							|	&KeyAttribute IN 
							|	(SELECT
							|		Tab.Original
							|	FROM
							|		ReplacementTable AS Tab)", "&KeyAttribute","Tab." + KeyAttribute);
		KeysValue = KeysValue + Value;
		
		Value = StringFunctionsClientServer.SubstituteParametersToString("Tab.%1 = Replacement.%1 ", KeyAttribute);
		LinksByKey = LinksByKey + ?(IsBlankString(LinksByKey), Value, "And " + Value);
							
		If AttributesToChangeArray.Find(KeyAttribute) <> Undefined Then
			
			Value = StringFunctionsClientServer.SubstituteParametersToString("Tab.%1 AS %1", KeyAttribute);
			AttributesToChange = AttributesToChange + ?(IsBlankString(AttributesToChange),Value, ","+Value);
			
			Value = StringFunctionsClientServer.SubstituteParametersToString("CASE WHEN Replacement%1.Original IS NULL THEN Tab.%1 ELSE Replacement%1.Duplicate1 END AS %1", KeyAttribute);
			ValueAttributesToChange = ValueAttributesToChange + ?(IsBlankString(ValueAttributesToChange),Value, ","+Value);
		
			Value = StringFunctionsClientServer.SubstituteParametersToString(" LEFT JOIN ReplacementTable AS Replacement%1
								|ON Tab.%1 = Replacement%1.Original", KeyAttribute);
			ConnectionValueOfAttributesToReplace = ConnectionValueOfAttributesToReplace + Value;
			
		Else
			
			Value =  StringFunctionsClientServer.SubstituteParametersToString("Tab.%1 AS %1", KeyAttribute);
			NotAttributesToChange = NotAttributesToChange + ?(IsBlankString(NotAttributesToChange),Value, ","+Value);

		EndIf;
		
	EndDo;

	AddToQueryText(QueryText, "#KeysValue", KeysValue);
	AddToQueryText(QueryText, "LEFT JOIN #ConnectionValueOfAttributesToReplace ON TRUE", ConnectionValueOfAttributesToReplace);
	AddToQueryText(QueryText, "&LinksByKey", LinksByKey);
	AddToQueryText(QueryText, "&NotAttributesToChange", ?(IsBlankString(NotAttributesToChange), "UNDEFINED", NotAttributesToChange));
	AddToQueryText(QueryText, "&AttributesToChange",  ?(IsBlankString(AttributesToChange), "UNDEFINED", AttributesToChange));
	
	AddToQueryText(QueryText, "#KeyTable", KeyTable);
	AddToQueryText(QueryText, "#KeyName", KeyName);
	
	Return QueryText;

EndFunction

Function QueryTemplate()
	
	Return "
	|SELECT
	|	Tab.Ref AS Ref,
	|	&NotAttributesToChange,
	|	&AttributesToChange
	|INTO #KeyNameSourceData
	|FROM
	|	#KeyTable AS Tab
	|WHERE
	|	FALSE" + "
	|
	|#KeysValue
	|;
	|" + "
	|SELECT
	|	Tab.Ref AS Ref,
	|	&NotAttributesToChange,
	|	&AttributesToChange
	|INTO #KeyNameTheValueOfTheDetailsAfterReplacement
	|FROM
	|	#KeyNameSourceData AS Tab
	|   LEFT JOIN #ConnectionValueOfAttributesToReplace ON TRUE
	|;
	|SELECT
	|	Tab.Ref AS Ref,
	|	Replacement.Ref AS Replacement,
	|	&NotAttributesToChange,
	|	&AttributesToChange
	|FROM
	|	#KeyNameTheValueOfTheDetailsAfterReplacement AS Tab
	|	LEFT JOIN #KeyTable AS Replacement
	|	ON Tab.Ref <> Replacement.Ref
	|	AND &LinksByKey 
	|
	|";

EndFunction

Procedure AddToQueryText(QueryText, ParameterName, Text)

	QueryText = StrReplace(QueryText, ParameterName, Text);

EndProcedure

Procedure AddToReplacementTables(OriginalDuplicate, ReplacementTables, SubordinateObjectsLinks) 

	KeyAttributeMetadata = OriginalDuplicate.Key.Metadata();
	KeyAttributeTableName = KeyAttributeMetadata.FullName();
	SearchKey = StrReplace(KeyAttributeTableName,".",""); 
	If SubordinateObjectsLinks.Find(KeyAttributeMetadata, "Metadata") = Undefined Then
		Return;
	EndIf;
	
	ReplacementTable = ReplacementTables[SearchKey];
	If ReplacementTable = Undefined Then
		Types = New Array;
		Types.Add(TypeOf(OriginalDuplicate.Key));
		OriginalRefType = New TypeDescription(Types);

		ReplacementTable = New ValueTable;
		ReplacementTable.Columns.Add("Original", OriginalRefType);
		ReplacementTable.Columns.Add("Duplicate1", OriginalRefType);
		
		ReplacementTables.Insert(SearchKey, ReplacementTable);
	EndIf;
	
	ReplacementString = ReplacementTable.Add();
	ReplacementString.Original = OriginalDuplicate.Key;
	ReplacementString.Duplicate1 = OriginalDuplicate.Value;

EndProcedure

Procedure PutReplacementsTablesInQuery(TempTablesManager, ReplacementTables)

	QueryParts = New Array;
	Separator = Chars.LF + "UNION ALL" + Chars.LF;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	QueryText = "
	|SELECT
	|	UNDEFINED AS Original,
	|	UNDEFINED AS Duplicate1
	|INTO ReplacementTable 
	|WHERE 
	|	FALSE";
	
	InsertQueryTemplate = "
	|SELECT
	|	Tab.Original AS Original,
	|	Tab.Duplicate1 AS Duplicate1
	|INTO TT_TableName
	|FROM
	|	&TableName AS Tab";
	
	MergeQueryTemplate = "
	|SELECT
	|	Tab.Original AS Original,
	|	Tab.Duplicate1 AS Duplicate1
	|FROM
	|	TT_TableName AS Tab";

	For Each ValuesTable In ReplacementTables Do
	
		QueryParts.Add(StrReplace(InsertQueryTemplate, "TableName", ValuesTable.Key));			
		Query.SetParameter(ValuesTable.Key, ValuesTable.Value); 
		QueryText = QueryText + Separator + StrReplace(MergeQueryTemplate, "TableName", ValuesTable.Key);
		
	EndDo;
	
	QueryText = QueryText + Chars.LF + "INDEX BY Original";
	
	QueryParts.Add(QueryText);
	Query.Text = StrConcat(QueryParts, Common.QueryBatchSeparator());
	Query.Execute();

EndProcedure

Procedure ExecuteSearchByAppliedRules(Val UsedLinks, Val NotPickedReplacements, Val SubordinateObjectDetails, Val ReplacementPairs)
	
	Var SearchMethodParameters, Cnt;
	
	For Cnt = 0 To NotPickedReplacements.Count() - 1 Do
		
		NotPickedReplacements[Cnt] = NewReplacementParameters(
			NotPickedReplacements[Cnt],
			SubordinateObjectDetails,
			UsedLinks);	
		
	EndDo;
	
	SearchMethodParameters = New Array;
	SearchMethodParameters.Add(ReplacementPairs);
	SearchMethodParameters.Add(NotPickedReplacements);
	Common.ExecuteConfigurationMethod(
		SubordinateObjectDetails.SearchMethodModuleName+".OnSearchForReferenceReplacement",
		SearchMethodParameters);

EndProcedure

Function ObjectsWithDuplicatesMergeCommands()

	ObjectsWithCommands = New Array;
	DuplicateObjectsDetectionOverridable.OnDefineObjectsWithReferenceReplacementDuplicatesMergeCommands(ObjectsWithCommands);
	Return ObjectsWithCommands;

EndFunction

#EndRegion

#EndRegion