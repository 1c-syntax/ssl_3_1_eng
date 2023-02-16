///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Defines the object manager to call applied rules.
//
// Parameters:
//   DataSearchAreaName - String - area name (full metadata name).
//
// Returns:
//   CatalogsManager, ChartsOfCharacteristicTypesManager,
//   ChartsOfAccountsManager, ChartsOfCalculationTypesManager - Object manager.
//
Function SearchForDuplicatesAreaManager(Val DataSearchAreaName) Export
	DataSearchArea = Common.MetadataObjectByFullName(DataSearchAreaName);
	
	If Metadata.Catalogs.Contains(DataSearchArea) Then
		Return Catalogs[DataSearchArea.Name];
		
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(DataSearchArea) Then
		Return ChartsOfCharacteristicTypes[DataSearchArea.Name];
		
	ElsIf Metadata.ChartsOfAccounts.Contains(DataSearchArea) Then
		Return ChartsOfAccounts[DataSearchArea.Name];
		
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(DataSearchArea) Then
		Return ChartsOfCalculationTypes[DataSearchArea.Name];
		
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Invalid type of ""%1"" metadata object.';"), DataSearchAreaName);
EndFunction

// 
// 
//
// Parameters:
//     SearchParameters - See DuplicateObjectsDetection.DuplicatesSearchParameters
//     SampleObject - AnyRef, CatalogObject -
//
// Returns:
//   Structure:
//       * DuplicatesTable - ValueTable:
//           ** Ref       - AnyRef - an item reference.
//           ** Code          - String
//                           - Number - 
//           ** Description - String - an item description.
//           ** Parent     - AnyRef - a parent of the duplicates group. If the Parent is empty, the item is
//                                           parent for the duplicates group.
//           ** OtherFields - Arbitrary - a value of the corresponding filter fields and criteria for comparing duplicates.
//       * ErrorDescription - Undefined - No errors occurred.
//                        - String - 
//     * ReturnedLessThanFound - Boolean - True if the size of the returned batch exceeds the limit.
//     * UsageInstances - See Common.UsageInstances
//
Function DuplicatesGroups(Val SearchParameters, Val SampleObject = Undefined) Export
	
	Var UsageInstances;
	FullMetadataObjectName = SearchParameters.DuplicatesSearchArea;
	MetadataObject = Common.MetadataObjectByFullName(FullMetadataObjectName);
	
	// Refine the input parameters.
	ReturnedBatchSize = CommonClientServer.StructureProperty(SearchParameters, "MaxDuplicates");
	If Not ValueIsFilled(ReturnedBatchSize) Then
		ReturnedBatchSize = 0; // 
	EndIf;
	
	CalculateUsageInstances = CommonClientServer.StructureProperty(SearchParameters, "CalculateUsageInstances");
	If TypeOf(CalculateUsageInstances) <> Type("Boolean") Then
		CalculateUsageInstances = False;
	EndIf;
	
	HideInsignificantDuplicates = CommonClientServer.StructureProperty(SearchParameters, "CalculateUsageInstances");
	If Not ValueIsFilled(HideInsignificantDuplicates) Then
		HideInsignificantDuplicates = True;
	EndIf;
	
	// Call the DuplicatesSearchParameters handler.
	HasSearchRules = False;
	FieldsNamesToCompareForEquality = ""; // 
	FieldsNamesToCompareForSimilarity   = ""; // 
	AdditionalFieldsNames = ""; // 
	ItemsCountToCompare = 0;  // 
	AdditionalParameters = CommonClientServer.StructureProperty(SearchParameters, "AdditionalParameters");
	SearchAreaManager = Undefined;
	
	AppliedSearchParameters = DuplicateObjectsDetection.DuplicatesSearchParameters(SearchParameters.SearchRules, 
		SearchParameters.PrefilterComposer);
	If HasSearchForDuplicatesAreaAppliedRules(FullMetadataObjectName) Then	
		SearchAreaManager = Common.ObjectManagerByFullName(FullMetadataObjectName);
		SearchAreaManager.DuplicatesSearchParameters(AppliedSearchParameters, AdditionalParameters);
		HasSearchRules = SearchParameters.TakeAppliedRulesIntoAccount;
	EndIf;
		
	StandardProcessing = True;
	DuplicateObjectsDetectionOverridable.OnDefineDuplicatesSearchParameters(FullMetadataObjectName,
		AppliedSearchParameters, AdditionalParameters, StandardProcessing);
	If Not StandardProcessing Then
		HasSearchRules = HasSearchRules Or SearchParameters.TakeAppliedRulesIntoAccount;	
	EndIf;		
		
	If HasSearchRules Then
		AllAdditionalFields = New Map;
		For Each Restriction In AppliedSearchParameters.ComparisonRestrictions Do
			For Each TableField In New Structure(Restriction.AdditionalFields) Do
				FieldName = TableField.Key;
				If AllAdditionalFields[FieldName] = Undefined Then
					AdditionalFieldsNames = AdditionalFieldsNames + ", " + FieldName;
					AllAdditionalFields[FieldName] = True;
				EndIf;
			EndDo;
		EndDo;
		AdditionalFieldsNames = Mid(AdditionalFieldsNames, 2);
		ItemsCountToCompare = AppliedSearchParameters.ItemsCountToCompare;
	EndIf;
	
	For Each String In SearchParameters.SearchRules Do
		If String.Rule = "Equal" Then
			FieldsNamesToCompareForEquality = FieldsNamesToCompareForEquality + ", " + String.Attribute;
		ElsIf String.Rule = "Like" Then
			FieldsNamesToCompareForSimilarity = FieldsNamesToCompareForSimilarity + ", " + String.Attribute;
		EndIf
	EndDo;
	FieldsNamesToCompareForEquality = Mid(FieldsNamesToCompareForEquality, 2);
	FieldsNamesToCompareForSimilarity   = Mid(FieldsNamesToCompareForSimilarity, 2);
	
	FieldsToCompareForEquality   = New Structure(FieldsNamesToCompareForEquality);
	FieldsToCompareForSimilarity     = New Structure(FieldsNamesToCompareForSimilarity);
	AdditionalFields = New Structure(AdditionalFieldsNames);
	
	// Generate filter conditions.
	Characteristics = New Structure;
	Characteristics.Insert("CodeLength", 0);
	Characteristics.Insert("NumberLength", 0);
	Characteristics.Insert("DescriptionLength", 0);
	Characteristics.Insert("Hierarchical", False);
	Characteristics.Insert("HierarchyType", Undefined);
	
	FillPropertyValues(Characteristics, MetadataObject);
	
	HasDescription = Characteristics.DescriptionLength > 0;
	HasCode          = Characteristics.CodeLength > 0;
	HasNumber        = Characteristics.NumberLength > 0;
	
	// Set aliases of additional fields so that they do not overlap with other fields.
	CandidatesTable = CandidatesTable();
	
	FieldsNamesInQuery = AvailableFilterAttributes(MetadataObject);
	If Not HasCode Then
		If HasNumber Then 
			FieldsNamesInQuery = FieldsNamesInQuery + ", Number AS Code";
		Else
			FieldsNamesInQuery = FieldsNamesInQuery + ", UNDEFINED AS Code";
		EndIf;
	EndIf;
	If Not HasDescription Then
		FieldsNamesInQuery = FieldsNamesInQuery + ", Ref AS Description";
	EndIf;
	FieldsNamesInChoice  = StrSplit(FieldsNamesToCompareForEquality + "," + FieldsNamesToCompareForSimilarity, ",", False);
	
	AdditionalFieldsDetails = New Map;
	SequenceNumber = 0;
	For Each TableField In AdditionalFields Do
		FieldName   = TableField.Key;
		Alias = "Addl" + Format(SequenceNumber, "NZ=; NG=") + "_" + FieldName;
		AdditionalFieldsDetails.Insert(Alias, FieldName);
		
		FieldsNamesInQuery = FieldsNamesInQuery + "," + FieldName + " AS " + Alias;
		FieldsNamesInChoice.Add(Alias);
		SequenceNumber = SequenceNumber + 1;
	EndDo;
	
	QueryText = "SELECT ALLOWED * FROM #Table";
	QueryText = StrReplace(QueryText, "*", FieldsNamesInQuery);
	QueryText = StrReplace(QueryText, "#Table", FullMetadataObjectName);
	
	// Schema population.
	DCSchema = New DataCompositionSchema;
	
	DCSchemaDataSource = DCSchema.DataSources.Add();
	DCSchemaDataSource.Name = "DataSource1";
	DCSchemaDataSource.DataSourceType = "Local";
	
	DataSet = DCSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Name = "DataSet1";
	DataSet.DataSource = "DataSource1";
	DataSet.Query = QueryText;
	DataSet.AutoFillAvailableFields = True;
	
	// Composer initialization.
	DCSettingsComposer = New DataCompositionSettingsComposer;
	DCSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DCSchema));
	DCSettingsComposer.LoadSettings(SearchParameters.PrefilterComposer.Settings);
	DCSettings = DCSettingsComposer.Settings;
	
	// Поля.
	DCSettings.Selection.Items.Clear();
	For Each FieldName In FieldsNamesInChoice Do
		DCField = New DataCompositionField(TrimAll(FieldName));
		AvailableDCField = DCSettings.SelectionAvailableFields.FindField(DCField);
		If AvailableDCField = Undefined Then
			WriteLogEvent(DuplicateObjectsDetection.SubsystemDescription(False),
				EventLogLevel.Warning, MetadataObject, SampleObject,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Field %1 does not exist.';"), String(DCField)));
			Continue;
		EndIf;
		SelectedDCField = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedDCField.Field = DCField;
	EndDo;
	SelectedDCField = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedDCField.Field = New DataCompositionField("Ref");
	SelectedDCField = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedDCField.Field = New DataCompositionField("Code");
	SelectedDCField = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedDCField.Field = New DataCompositionField("Description");
	SelectedDCField = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedDCField.Field = New DataCompositionField("DeletionMark");
	If Characteristics.Hierarchical
			And Characteristics.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
		
		SelectedDCField = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedDCField.Field = New DataCompositionField("IsFolder");
		
		SelectedDCField = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedDCField.Field = New DataCompositionField("Parent");
	EndIf;
	
	// Сортировки.
	DCSettings.Order.Items.Clear();
	DCOrderItem = DCSettings.Order.Items.Add(Type("DataCompositionOrderItem"));
	DCOrderItem.Field = New DataCompositionField("Ref");
	
	// Filters.
	//
	If MetadataObject = Metadata.Catalogs.Users Then
		DCFilterItem = DCSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		DCFilterItem.LeftValue  = New DataCompositionField("IsInternal");
		DCFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
		DCFilterItem.RightValue = False;
	EndIf;
	
	// Structure
	DCSettings.Structure.Clear();
	DCGroup = DCSettings.Structure.Add(Type("DataCompositionGroup"));
	DCGroup.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	DCGroup.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
	
	// Read original data.
	If SampleObject = Undefined Then
		SampleObjectsSelection = InitializeDCSelection(DCSchema, DCSettingsComposer.GetSettings());
	Else
		ValueTable = ObjectIntoValueTable(SampleObject, AdditionalFieldsDetails);
		If Not HasCode And Not HasNumber Then
			ValueTable.Columns.Add("Code", New TypeDescription("Undefined"));
		EndIf;
		SampleObjectsSelection = InitializeVTSelection(ValueTable);
	EndIf;
	
	// Preparing DCS to read the duplicate data.
	CandidatesFilters = New Map;
	FieldsNames = StrSplit(FieldsNamesToCompareForEquality, ",", False);
	For Each FieldName In FieldsNames Do
		FieldName = TrimAll(FieldName);
		DCFilterItem = DCSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		DCFilterItem.LeftValue = New DataCompositionField(FieldName);
		DCFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
		CandidatesFilters.Insert(FieldName, DCFilterItem);
	EndDo;
	DCFilterItem = DCSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DCFilterItem.LeftValue = New DataCompositionField("Ref");
	DCFilterItem.ComparisonType = ?(SampleObject = Undefined, DataCompositionComparisonType.Greater, DataCompositionComparisonType.NotEqual);
	CandidatesFilters.Insert("Ref", DCFilterItem);
	
	If Characteristics.Hierarchical
			And Characteristics.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
		
		DCFilterItem = DCSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		DCFilterItem.LeftValue = New DataCompositionField("IsFolder");
		DCFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
		CandidatesFilters.Insert("IsFolder", DCFilterItem);
		
		OrGroup = DCSettings.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		AndGroup = OrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
		AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		DCFilterItem = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
		DCFilterItem.LeftValue = New DataCompositionField("IsFolder");
		DCFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
		DCFilterItem.RightValue = False;
		
		AndGroup = OrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
		AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		DCFilterItem = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
		DCFilterItem.LeftValue = New DataCompositionField("IsFolder");
		DCFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
		DCFilterItem.RightValue = True;
		
		DCFilterItem = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
		DCFilterItem.LeftValue = New DataCompositionField("Parent");
		DCFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
		CandidatesFilters.Insert("Parent", DCFilterItem);
	EndIf;
	
	// Result and search cycle
	DuplicatesCollection = DuplicatesCollection(SearchParameters, FieldsToCompareForSimilarity, FieldsToCompareForEquality);
	DuplicatesTable = DuplicatesCollection.DuplicatesTable;

	Result = New Structure;
	Result.Insert("DuplicatesTable", DuplicatesTable);
	Result.Insert("ErrorDescription");
	Result.Insert("ReturnedLessThanFound", False);
	Result.Insert("UsageInstances");
	
	FieldsStructure = New Structure;
	FieldsStructure.Insert("AdditionalFieldsDetails", AdditionalFieldsDetails);
	FieldsStructure.Insert("IdentityFieldsStructure",     FieldsToCompareForEquality);
	FieldsStructure.Insert("SimilarityFieldsStructure",          FieldsToCompareForSimilarity);
	FieldsStructure.Insert("IdentityFieldsList",        FieldsNamesToCompareForEquality);
	FieldsStructure.Insert("SimilarityFieldsList",             FieldsNamesToCompareForSimilarity);
	
	While NextSelectionItem(SampleObjectsSelection) Do
		SampleItem = SampleObjectsSelection.CurrentItem;
		
		// Setting filters for candidate selection.
		For Each FilterElement In CandidatesFilters Do
			FilterElement.Value.RightValue = SampleItem[FilterElement.Key];
		EndDo;
		
		// Selection of data candidates from DBMS.
		CandidatesSelection = InitializeDCSelection(DCSchema, DCSettings);
		DuplicatesCandidates = CandidatesSelection.DCOutputProcessor.Output(CandidatesSelection.DCProcessor);
		
		If FieldsToCompareForSimilarity.Count() > 0 Then
			
			StringsComparisonForSimilarity = AppliedSearchParameters.StringsComparisonForSimilarity;
			Try
				ParametersOfSearchForSimilarStrings = DuplicateObjectsDetection.ParametersOfSearchForSimilarStrings();
			Except
				Result.ErrorDescription = 
					NStr("en = 'Cannot attach the fuzzy search add-in. See the Event log for details.';");
				Return Result;
			EndTry;
			FillPropertyValues(ParametersOfSearchForSimilarStrings, StringsComparisonForSimilarity);
			
			For Each TableField In FieldsToCompareForSimilarity Do
				
				FieldName = TableField.Key;       
				ValueOfField = New Array;
				For Each TableRow In DuplicatesCandidates Do
					ValueOfField.Add(StrReplace(TableRow[FieldName], "~", "\u126"));
				EndDo;
				RequiredRows = StrConcat(ValueOfField, "~");
				SearchRow1 = SampleItem[FieldName];
				
				RowIndexes = DuplicateObjectsDetection.FindSimilarStrings(RequiredRows, SearchRow1, "~", ParametersOfSearchForSimilarStrings);
				
				If IsBlankString(RowIndexes) Then
					Continue;
				EndIf;
				
				For Each RowIndex In StrSplit(RowIndexes, ",") Do
					If IsBlankString(RowIndex) Then
						Continue;
					EndIf;
					DuplicateItem1 = DuplicatesCandidates.Get(RowIndex);
					
					If HasSearchRules Then
						AddCandidatesRow(CandidatesTable, SampleItem, DuplicateItem1, FieldsStructure);
						If CandidatesTable.Count() = ItemsCountToCompare Then
							RegisterDuplicatesByAppliedRules(DuplicatesCollection, FullMetadataObjectName, SearchAreaManager, 
								SampleItem, CandidatesTable, FieldsStructure, AdditionalParameters);
							CandidatesTable.Clear();
						EndIf;
					Else
						RegisterDuplicate(DuplicatesCollection, SampleItem, DuplicateItem1, FieldsStructure);
					EndIf;
					
				EndDo;
				
			EndDo;
		Else
			For Each DuplicateItem1 In DuplicatesCandidates Do
				
				If HasSearchRules Then
					AddCandidatesRow(CandidatesTable, SampleItem, DuplicateItem1, FieldsStructure);
					If CandidatesTable.Count() = ItemsCountToCompare Then
						RegisterDuplicatesByAppliedRules(DuplicatesTable, FullMetadataObjectName, SearchAreaManager, 
							SampleItem, CandidatesTable, FieldsStructure, AdditionalParameters);
						CandidatesTable.Clear();
					EndIf;
				Else
					RegisterDuplicate(DuplicatesCollection, SampleItem, DuplicateItem1, FieldsStructure);
				EndIf;
				
			EndDo;
		EndIf;
		
		// Processing the rest of the applied rule table.
		If HasSearchRules Then
			RegisterDuplicatesByAppliedRules(DuplicatesCollection, FullMetadataObjectName, SearchAreaManager, 
				SampleItem, CandidatesTable, FieldsStructure, AdditionalParameters);
			CandidatesTable.Clear();
		EndIf;
		
		// Process pending duplicates.
		DeleteNotSignificantDuplicates(DuplicatesCollection);	
		DeleteNotSignificantGroups(DuplicatesCollection);
		
		// Consider restriction.
		If ReturnedBatchSize > 0 And (DuplicatesTable.Count() > ReturnedBatchSize) Then
				Result.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Too many duplicates were found. First %1 items are shown.';"), ReturnedBatchSize); 
				Result.ReturnedLessThanFound = True;
			Break;
		EndIf;
				
	EndDo;
	
	// Compute occurrences.
	If CalculateUsageInstances Then
		
		TimeConsumingOperations.ReportProgress(0, "CalculateUsageInstances");
		
		ObjectsRefs1 = New Array;
		For Each DuplicatesRow In DuplicatesTable Do
			If ValueIsFilled(DuplicatesRow.Ref) Then
				ObjectsRefs1.Add(DuplicatesRow.Ref);
			EndIf;
		EndDo;
		
		UsageInstances = SearchForReferences(ObjectsRefs1);
		UsageInstances = UsageInstances.Copy(
			UsageInstances.FindRows(New Structure("AuxiliaryData", False)));
		UsageInstances.Indexes.Add("Ref");
		Result.UsageInstances = UsageInstances;
		
	EndIf;
	
	Return Result;
EndFunction

// Determining whether the object has applied rules.
//
// Parameters:
//     AreaManager - ManagerCatalog - a manager of the object to be checked.
//
// Returns:
//     Boolean - 
//
Function HasSearchForDuplicatesAreaAppliedRules(Val ObjectName) Export
	
	ObjectInfo = DuplicateObjectsDetection.ObjectsWithDuplicatesSearch()[ObjectName];
	Return ObjectInfo <> Undefined And (ObjectInfo = "" Or StrFind(ObjectInfo, "DuplicatesSearchParameters") > 0);
	
EndFunction

// Handler of background search for duplicates.
//
// Parameters:
//     Parameters       - Structure - data to be analyzed.
//     ResultAddress - String    - a temporary storage address to save the result.
//
Procedure BackgroundSearchForDuplicates(Val Parameters, Val ResultAddress) Export
	
	PrefilterComposer = New DataCompositionSettingsComposer;
	PrefilterComposer.Initialize( New DataCompositionAvailableSettingsSource(Parameters.CompositionSchema) );
	PrefilterComposer.LoadSettings(Parameters.PrefilterComposerSettings);
	Parameters.Insert("PrefilterComposer", PrefilterComposer);
	
	SearchRules = New ValueTable;
	SearchRules.Columns.Add("Attribute", New TypeDescription("String") );
	SearchRules.Columns.Add("Rule",  New TypeDescription("String") );
	SearchRules.Indexes.Add("Attribute");
	For Each Rule In Parameters.SearchRules Do
		FillPropertyValues(SearchRules.Add(), Rule);
	EndDo;
	Parameters.Insert("SearchRules", SearchRules);
	Parameters.Insert("CalculateUsageInstances", True);
	
	Result = DuplicatesGroups(Parameters);
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

#EndRegion

#Region Private

// Handler of background deletion of duplicates.
//
// Parameters:
//     Parameters       - Structure - data to be analyzed.
//     ResultAddress - String    - a temporary storage address to save the result.
//
Procedure BackgroundDuplicateDeletion(Val Parameters, Val ResultAddress) Export
	
	ReplacementParameters = New Structure;
	ReplacementParameters.Insert("IncludeBusinessLogic", False);
	ReplacementParameters.Insert("TakeAppliedRulesIntoAccount", Parameters.TakeAppliedRulesIntoAccount);
	ReplacementParameters.Insert("ReplacePairsInTransaction", False);
	ReplacementParameters.Insert("DeletionMethod", Parameters.DeletionMethod);
	
	ReplaceReferences(Parameters.ReplacementPairs, ReplacementParameters, ResultAddress);
	
EndProcedure

// Converts an object to a table for adding to a query.
Function ObjectIntoValueTable(Val DataObject, Val AdditionalFieldsDetails)
	Result = New ValueTable;
	DataString1 = Result.Add();
	
	MetadataObjects1 = DataObject.Metadata();
	
	For Each MetaAttribute In MetadataObjects1.StandardAttributes  Do
		Name = MetaAttribute.Name;
		Result.Columns.Add(Name, MetaAttribute.Type);
		DataString1[Name] = DataObject[Name];
	EndDo;
	
	For Each MetaAttribute In MetadataObjects1.Attributes Do
		Name = MetaAttribute.Name;
		Result.Columns.Add(Name, MetaAttribute.Type);
		DataString1[Name] = DataObject[Name];
	EndDo;
	
	For Each KeyAndValue In AdditionalFieldsDetails Do
		Name1 = KeyAndValue.Key;
		Name2 = KeyAndValue.Value;
		Result.Columns.Add(Name1, Result.Columns[Name2].ValueType);
		DataString1[Name1] = DataString1[Name2];
	EndDo;
	
	Return Result;
EndFunction

// An additional analysis of duplicates candidates with the OnDuplicatesSearch handler.
//
Procedure RegisterDuplicatesByAppliedRules(ResultTreeRows, Val FullMetadataObjectName, Val SearchAreaManager, 
	Val MainData, Val CandidatesTable, Val FieldsStructure, Val AdditionalParameters)
	
	If CandidatesTable.Count() = 0 Then
		Return;
	EndIf;
	
	If SearchAreaManager <> Undefined Then
		SearchAreaManager.OnSearchForDuplicates(CandidatesTable, AdditionalParameters);
	EndIf;
	DuplicateObjectsDetectionOverridable.OnSearchForDuplicates(FullMetadataObjectName, CandidatesTable, AdditionalParameters);
	
	Data1 = New Structure;
	Data2 = New Structure;
	
	FoundItems = CandidatesTable.FindRows(New Structure("IsDuplicates", True));
	For Each CandidatesPair In FoundItems Do
		Data1.Insert("Ref",       CandidatesPair.Ref1);
		Data1.Insert("Code",          CandidatesPair.Fields1.Code);
		Description1 = CandidatesPair.Fields1.Description;// String
		Data1.Insert("Description", Description1);
		Data1.Insert("DeletionMark", CandidatesPair.Fields1.DeletionMark);
		
		Data2.Insert("Ref",       CandidatesPair.Ref2);
		Data2.Insert("Code",          CandidatesPair.Fields2.Code);
		Data2.Insert("Description", CandidatesPair.Fields2.Description);
		Data2.Insert("DeletionMark", CandidatesPair.Fields2.DeletionMark);
		
		For Each KeyValue In FieldsStructure.IdentityFieldsStructure Do
			FieldName = KeyValue.Key;
			Data1.Insert(FieldName, CandidatesPair.Fields1[FieldName]);
			Data2.Insert(FieldName, CandidatesPair.Fields2[FieldName]);
		EndDo;
		For Each KeyValue In FieldsStructure.SimilarityFieldsStructure Do
			FieldName = KeyValue.Key;
			Data1.Insert(FieldName, CandidatesPair.Fields1[FieldName]);
			Data2.Insert(FieldName, CandidatesPair.Fields2[FieldName]);
		EndDo;
		
		RegisterDuplicate(ResultTreeRows, Data1, Data2, FieldsStructure);
	EndDo;
EndProcedure

// Add a row to the candidate table for the applied method.
//
// Details
// 
// Parameters:
//   CandidatesTable - See CandidatesTable
//   MainItemData - Structure:
//   * Ref - AnyRef
//   * Description - String
//   * Code - String
//   * DeletionMark - Boolean
//   CandidateData - Structure:
//   * Ref - AnyRef
//   * Description - String
//   * Code - String
//   * DeletionMark - Boolean
//   FieldsStructure - Structure
// Returns:
//   ValueTableRow
//
Function AddCandidatesRow(CandidatesTable,  Val MainItemData, Val CandidateData, Val FieldsStructure)
	
	String = CandidatesTable.Add();
	String.IsDuplicates = False;
	String.Ref1  = MainItemData.Ref;
	String.Ref2  = CandidateData.Ref;
	
	String.Fields1 = New Structure("Code, Description, DeletionMark", 
		MainItemData.Code, MainItemData.Description, MainItemData.DeletionMark);
	String.Fields2 = New Structure("Code, Description, DeletionMark", 
		CandidateData.Code, CandidateData.Description, CandidateData.DeletionMark);
	
	For Each KeyValue In FieldsStructure.IdentityFieldsStructure Do
		FieldName = KeyValue.Key;
		String.Fields1.Insert(FieldName, MainItemData[FieldName]);
		String.Fields2.Insert(FieldName, CandidateData[FieldName]);
	EndDo;
	
	For Each KeyValue In FieldsStructure.SimilarityFieldsStructure Do
		FieldName = KeyValue.Key;
		String.Fields1.Insert(FieldName, MainItemData[FieldName]);
		String.Fields2.Insert(FieldName, CandidateData[FieldName]);
	EndDo;
	
	For Each KeyValue In FieldsStructure.AdditionalFieldsDetails Do
		ColumnName = KeyValue.Value;
		FieldName    = KeyValue.Key;
		
		String.Fields1.Insert(ColumnName, MainItemData[FieldName]);
		String.Fields2.Insert(ColumnName, CandidateData[FieldName]);
	EndDo;
	
	Return String;
EndFunction

// Add the found duplicate to the result tree.
//
Procedure RegisterDuplicate(DuplicatesCollection, Val Item1, Val Item2, Val FieldsStructure)
	
	DuplicatesTable = DuplicatesCollection.DuplicatesTable;
	NotSignificantDuplicates = DuplicatesCollection.NotSignificantDuplicates;
	// Defining which item is already added to duplicates.
	DuplicatesRow1 = DuplicatesTable.Find(Item1.Ref, "Ref");
	DuplicatesRow2 = DuplicatesTable.Find(Item2.Ref, "Ref");
	
	NotSignificantDuplicatesRow1 = NotSignificantDuplicates.Find(Item1.Ref);
	NotSignificantDuplicatesRow2 = NotSignificantDuplicates.Find(Item2.Ref);
	
	Duplicate1Registered = (DuplicatesRow1 <> Undefined) Or (NotSignificantDuplicatesRow1 <> Undefined);
	Duplicate2Registered = (DuplicatesRow2 <> Undefined) Or (NotSignificantDuplicatesRow2 <> Undefined);
	
	// 
	// 
	If Duplicate1Registered And Duplicate2Registered
		Or NotSignificantDuplicatesRow1 <> Undefined
		Or NotSignificantDuplicatesRow2 <> Undefined Then
		
		Return;
	EndIf;
	
	// Before registering a duplicate, determine a reference to the group of duplicates.
	If Duplicate1Registered Then
		DuplicatesGroupsRef = ?(ValueIsFilled(DuplicatesRow1.Parent), DuplicatesRow1.Parent, DuplicatesRow1.Ref);
	ElsIf Duplicate2Registered Then
		DuplicatesGroupsRef = ?(ValueIsFilled(DuplicatesRow2.Parent), DuplicatesRow2.Parent, DuplicatesRow2.Ref);
	Else // Register a group of duplicates.
		DuplicatesGroup = DuplicatesTable.Add();
		DuplicatesGroup.Ref = Item1.Ref;
		DuplicatesGroupsRef = DuplicatesGroup.Ref;
	EndIf;
	
	ListOfProperties = "Ref,Code,Description,DeletionMark," + FieldsStructure.IdentityFieldsList + "," + FieldsStructure.SimilarityFieldsList;
	
	If Not Duplicate1Registered Then
			
		DuplicateInfo = DuplicatesTable.Add();
		FillPropertyValues(DuplicateInfo, Item1, ListOfProperties);
		DuplicateInfo.Parent = DuplicatesGroupsRef;
		
		If DuplicateInfo.DeletionMark Then
			DuplicatesCollection.DuplicatesToCheck.Add(DuplicateInfo.Ref);	
		EndIf;
		
	EndIf;
	
	If Not Duplicate2Registered Then
			
		DuplicateInfo = DuplicatesTable.Add();
		FillPropertyValues(DuplicateInfo, Item2, ListOfProperties);
		DuplicateInfo.Parent = DuplicatesGroupsRef;
		
		If DuplicateInfo.DeletionMark Then
			DuplicatesCollection.DuplicatesToCheck.Add(DuplicateInfo.Ref);	
		EndIf;
		
	EndIf;
	
	If DuplicatesCollection.DuplicatesToCheck.Count() >= DuplicatesCollection.ItemsCountToCompare Then
		DeleteNotSignificantDuplicates(DuplicatesCollection);	
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// For offline work.

// [ОбщегоНазначения.МестаИспользования]
Function SearchForReferences(Val RefSet, Val ResultAddress = "")
	
	Return Common.UsageInstances(RefSet, ResultAddress);
	
EndFunction

// [ОбщегоНазначения.ЗаменитьСсылки]
Procedure ReplaceReferences(Val ReplacementPairs, Val Parameters = Undefined, Val ResultAddress = "")
	
	Result = Common.ReplaceReferences(ReplacementPairs, Parameters);
	
	If ResultAddress <> "" Then
		PutToTempStorage(Result, ResultAddress);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Miscellaneous.

Function AvailableFilterAttributes(MetadataObject)
	AttributesArray = New Array;
	For Each AttributeMetadata1 In MetadataObject.StandardAttributes Do
		If AttributeMetadata1.Type.ContainsType(Type("ValueStorage")) Then
			Continue;
		EndIf;
		AttributesArray.Add(AttributeMetadata1.Name);
	EndDo;
	For Each AttributeMetadata1 In MetadataObject.Attributes Do
		If AttributeMetadata1.Type.ContainsType(Type("ValueStorage")) Then
			Continue;
		EndIf;
		AttributesArray.Add(AttributeMetadata1.Name);
	EndDo;
	Return StrConcat(AttributesArray, ",");
EndFunction

// Parameters:
//  DCSchema - DataCompositionSchema
//  DCSettings - DataCompositionSettings
//
// Returns:
//  Structure:
//    * Table - ValueTable:
//        ** IndexOf - Number
//        ** UBound - Number
//    * CurrentItem - ValueTableRow:
//        ** Ref - AnyRef
//    * IndexOf - Number
//    * UBound - Number
//    * DCProcessor - DataCompositionProcessor
//    * DCOutputProcessor - DataCompositionResultValueCollectionOutputProcessor
// 
Function InitializeDCSelection(DCSchema, DCSettings)
	Selection = New Structure("Table, CurrentItem, IndexOf, UBound, DCProcessor, DCOutputProcessor");
	DCTemplateComposer = New DataCompositionTemplateComposer;
	DCTemplate = DCTemplateComposer.Execute(DCSchema, DCSettings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	
	Selection.DCProcessor = New DataCompositionProcessor;
	Selection.DCProcessor.Initialize(DCTemplate);
	
	Selection.Table = New ValueTable;
	Selection.IndexOf = -1;
	Selection.UBound = -100;
	
	Selection.DCOutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	Selection.DCOutputProcessor.SetObject(Selection.Table);
	
	Return Selection;
EndFunction

Function InitializeVTSelection(ValueTable)
	Selection = New Structure("Table, CurrentItem, IndexOf, UBound, DCProcessor, DCOutputProcessor");
	Selection.Table = ValueTable;
	Selection.IndexOf = -1;
	Selection.UBound = ValueTable.Count() - 1;
	Return Selection;
EndFunction

Function NextSelectionItem(Selection)
	If Selection.IndexOf >= Selection.UBound Then
		If Selection.DCProcessor = Undefined Then
			Return False;
		EndIf;
		If Selection.UBound = -100 Then
			Selection.DCOutputProcessor.BeginOutput();
		EndIf;
		Selection.Table.Clear();
		Selection.IndexOf = -1;
		Selection.UBound = -1;
		While Selection.UBound = -1 Do
			DCResultItem = Selection.DCProcessor.Next();
			If DCResultItem = Undefined Then
				Selection.DCOutputProcessor.EndOutput();
				Return False;
			EndIf;
			Selection.DCOutputProcessor.OutputItem(DCResultItem);
			Selection.UBound = Selection.Table.Count() - 1;
		EndDo;
	EndIf;
	Selection.IndexOf = Selection.IndexOf + 1;
	Selection.CurrentItem = Selection.Table[Selection.IndexOf];
	Return True;
EndFunction

// Deletes duplicates that are marked for deletion and have no occurrences. 
// 
//
Procedure DeleteNotSignificantDuplicates(DuplicatesCollection)
	
	// Don't delete unimportant duplicates since there are no restrictions.
	If Not DuplicatesCollection.HideInsignificantDuplicates Then
		Return;
	EndIf;
	
	DuplicatesTable = DuplicatesCollection.DuplicatesTable;
	DuplicatesToCheck = DuplicatesCollection.DuplicatesToCheck;
	 
	// There's enough items to output. Don't check duplicates. 
	If DuplicatesTable.Count() - DuplicatesToCheck.Count() <= DuplicatesCollection.ItemsCountToCompare Then
		
		UsageInstances = SearchForReferences(DuplicatesToCheck);
		UsageInstances.Indexes.Add("Ref, AuxiliaryData");
		
		For Cnt = 0 To DuplicatesToCheck.UBound() Do
			
			DuplicatesToCheck1 = DuplicatesTable.FindRows(New Structure("Ref", DuplicatesToCheck[Cnt]));	
			For Each Duplicate1 In DuplicatesToCheck1 Do
				
				If Duplicate1.Parent = Undefined Then
					Continue;
				EndIf;
				
				UsageInstancesInternal = UsageInstances.FindRows(New Structure("Ref, AuxiliaryData", Duplicate1.Ref, False));
				If UsageInstancesInternal.Count() = 0 And Duplicate1.DeletionMark Then
					
					FillPropertyValues(DuplicatesCollection.NotSignificantDuplicates.Add(), Duplicate1);	
					DuplicatesCollection.ProcessedGroups.Insert(Duplicate1.Parent);
					DuplicatesTable.Delete(Duplicate1);
					
				EndIf;
				
			EndDo;
		EndDo;
				
	EndIf;
	
	DuplicatesToCheck.Clear();
	TimeConsumingOperations.ReportProgress(DuplicatesTable.Count(), "RegisterDuplicate");

EndProcedure

// Deletes groups and their items if there is only one item in the group
Procedure DeleteNotSignificantGroups(DuplicatesCollection)

	DuplicatesTable = DuplicatesCollection.DuplicatesTable;
	For Each DuplicatesGroup In DuplicatesCollection.ProcessedGroups Do
		
		Duplicates = DuplicatesTable.FindRows(New Structure("Parent", DuplicatesGroup.Key));
		If Duplicates.Count() = 1 Then
			DuplicatesTable.Delete(Duplicates[0]);
		EndIf;
		
		Group = DuplicatesTable.Find(DuplicatesGroup.Key, "Ref");
		If Group <> Undefined Then
			DuplicatesTable.Delete(Group);	
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns:
//   ValueTable:
//   * Ref - AnyRef 
//
Function DuplicatesTable(FieldsToCompareForSimilarity, FieldsToCompareForEquality)
	
	DuplicatesTable = New ValueTable;
	DuplicatesTable.Columns.Add("Ref");
	For Each TableField In FieldsToCompareForEquality Do
		If DuplicatesTable.Columns.Find(TableField.Key) = Undefined Then
			DuplicatesTable.Columns.Add(TableField.Key);
		EndIf;
	EndDo;
	
	For Each TableField In FieldsToCompareForSimilarity Do
		If DuplicatesTable.Columns.Find(TableField.Key) = Undefined Then
			DuplicatesTable.Columns.Add(TableField.Key);
		EndIf;
	EndDo;
	
	RequiredColumns2 = StrSplit("Code,Description,Parent,DeletionMark,IsFolder", ",");
	For Each TableFieldName In RequiredColumns2 Do
		If DuplicatesTable.Columns.Find(TableFieldName) = Undefined Then
			DuplicatesTable.Columns.Add(TableFieldName);
		EndIf;
	EndDo;
	
	DuplicatesTable.Indexes.Add("Ref");
	DuplicatesTable.Indexes.Add("Parent");
	DuplicatesTable.Indexes.Add("Ref, Parent,IsFolder");
	
	Return DuplicatesTable;
EndFunction

// Returns:
//   Structure:
//   * NotSignificantDuplicates - ValueTable:
//   ** Ref - AnyRef
//   ** Parent - AnyRef
//   ** Ref - AnyRef
//   ** Parent - AnyRef
//   * ProcessedGroups - Map
//   * HideInsignificantDuplicates - Boolean
//   * DuplicatesToCheck - Array
//   * ItemsCountToCompare - Arbitrary
//                                     - Undefined
//   * DuplicatesTable - See DuplicatesTable
//
Function DuplicatesCollection(Val SearchParameters, FieldsToCompareForSimilarity, FieldsToCompareForEquality)
	
	DuplicatesCollection = New Structure;
	DuplicatesCollection.Insert("DuplicatesTable", DuplicatesTable(FieldsToCompareForSimilarity, FieldsToCompareForEquality));
	DuplicatesCollection.Insert("ItemsCountToCompare", 
		CommonClientServer.StructureProperty(SearchParameters, "MaxDuplicates", 0));
	DuplicatesCollection.Insert("DuplicatesToCheck", New Array);
	
	 DuplicatesCollection.Insert("HideInsignificantDuplicates", False);
	If SearchParameters.Property("HideInsignificantDuplicates")
		And SearchParameters.HideInsignificantDuplicates = True
			Or DuplicatesCollection.ItemsCountToCompare = 0 Then
	
	    DuplicatesCollection.HideInsignificantDuplicates = True;
	EndIf;
	 
	DuplicatesCollection.Insert("ProcessedGroups", New Map);	
	
	NotSignificantDuplicates = Undefined;
	
	NotSignificantDuplicates = New ValueTable;
	NotSignificantDuplicates.Columns.Add("Ref");
	NotSignificantDuplicates.Columns.Add("Parent");
	
	NotSignificantDuplicates.Indexes.Add("Ref");	
	
	DuplicatesCollection.Insert("NotSignificantDuplicates", NotSignificantDuplicates);
	Return DuplicatesCollection;

EndFunction

// Returns:
//   ValueTable:
//   * Ref1 - AnyRef
//   * Fields1 - Structure:
//   ** Description - String
//   ** Code - String
//   * Ref2 - AnyRef
//   * Fields2 - Structure:
//   ** Description - String
//   ** Code - String
//   * IsDuplicates - Boolean
//
Function CandidatesTable()
	CandidatesTable = New ValueTable;
	CandidatesColumns = CandidatesTable.Columns;
	CandidatesColumns.Add("Ref1");
	CandidatesColumns.Add("Fields1");
	CandidatesColumns.Add("Ref2");
	CandidatesColumns.Add("Fields2");
	CandidatesColumns.Add("IsDuplicates", New TypeDescription("Boolean"));
	CandidatesTable.Indexes.Add("IsDuplicates");
	Return CandidatesTable;
EndFunction

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf