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

#Region Public

#Region ForCallsFromOtherSubsystems

// See ReportsOptionsOverridable.BeforeAddReportCommands.
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Return;
	EndIf;
	
	If Not AccessRight("View", Metadata.Reports.AccessRightsAnalysis)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	AreUsers = False;
	AddUsersRightsCommand(ReportsCommands, Parameters, AreUsers);
	
	If Not AreUsers And AccessManagement.ProductiveOption() Then
		AddRightsToDataElementCommand(ReportsCommands, Parameters);
	EndIf;
	
	AddRightsByValueCommand(ReportsCommands, Parameters);
	
EndProcedure

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Return;
	EndIf;
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	ReportSettings.DefineFormSettings = True;
	SubsystemForAdministration = Metadata.Subsystems.Find("Administration");
	SubsystemForMonitoring = ?(SubsystemForAdministration = Undefined, Undefined,
		SubsystemForAdministration.Subsystems.Find("UserMonitoring"));
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "AccessRightsAnalysis");
	OptionSettings.LongDesc = NStr("en = 'Shows user rights to infobase tables (you can enable grouping by reports).'");
	If SubsystemForMonitoring <> Undefined Then
		OptionSettings.Location.Insert(SubsystemForMonitoring, "Important");
	EndIf;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UsersRightsToTables");
	OptionSettings.LongDesc = NStr("en = 'Shows user rights to infobase tables.'");
	OptionSettings.Enabled = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UserRightsToTables");
	OptionSettings.LongDesc = NStr("en = 'Shows individual user''s rights to different infobase tables.'");
	OptionSettings.Enabled = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UsersRightsToTable");
	OptionSettings.LongDesc = NStr("en = 'Shows different users'' rights to the same infobase table.'");
	OptionSettings.Enabled = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UserRightsToTable");
	OptionSettings.LongDesc = NStr("en = 'Shows user''s rights to one infobase table with record-level restriction settings (RLS).'");
	OptionSettings.Enabled = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UserRightsToReportTables");
	OptionSettings.LongDesc = NStr("en = 'Shows individual user''s rights to different infobase tables used in a separate report.'");
	OptionSettings.Enabled = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UsersRightsToReportTables");
	OptionSettings.LongDesc = NStr("en = 'Shows different users'' rights to different infobase tables used in a separate report.'");
	OptionSettings.Enabled = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UserRightsToReportsTables");
	OptionSettings.LongDesc = NStr("en = 'Shows individual user''s rights to different infobase tables grouped by reports.'");
	OptionSettings.Enabled = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UsersRightsToObject");
	OptionSettings.LongDesc = NStr("en = 'Displays the calculated user permissions for an infobase object (for example, a document or catalog item).'");
	OptionSettings.Enabled = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UsersRightsByAllowedValue");
	OptionSettings.LongDesc = NStr("en = 'Displays users with access to infobase objects (for example, documents and catalog items) based on the selected value (company, warehouse, and so on).'");
	OptionSettings.Enabled = False;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Intended for procedure "HideExcessDataFields".
// 
//
// Parameters:
//  DataSetName - String - Dataset name as it is specified in DCS.
//  DataPaths - String - "*": All fields are available.
//              - Array of String - Only the specified fields are available.
//              - Map of KeyAndValue:
//                 * Key - String - Name of the unavailable field.
//                 * Value - Boolean - For example, "False".
//  OriginalScheme - DataCompositionSchema - Schema whose field availability is obtained.
//  CurrentSchema  - DataCompositionSchema - Schema where the field availability is being configured.
//
Procedure HideDataFieldsExceptSpecified(DataSetName, DataPaths, OriginalScheme, CurrentSchema) Export
	
	If DataSetName = "*" Then
		DataFields = CurrentSchema.CalculatedFields;
		OriginalDataFields = OriginalScheme.CalculatedFields;
	Else
		DataFields = CurrentSchema.DataSets[DataSetName].Fields;
		OriginalDataFields = OriginalScheme.DataSets[DataSetName].Fields;
	EndIf;
	
	For Each DataField In DataFields Do
		If DataPaths = "*"
		 Or TypeOf(DataPaths) = Type("Array")
		   And DataPaths.Find(DataField.DataPath) <> Undefined
		 Or TypeOf(DataPaths) = Type("Map")
		   And DataPaths.Get(DataField.DataPath) = Undefined Then
			
			OriginalDataField = OriginalDataFields.Find(DataField.DataPath);
			If OriginalDataField = Undefined Then
				Continue;
			EndIf;
			FillPropertyValues(DataField.UseRestriction,
				OriginalDataField.UseRestriction);
			If TypeOf(DataField) <> Type("DataCompositionSchemaCalculatedField") Then
				FillPropertyValues(DataField.AttributeUseRestriction,
					OriginalDataField.AttributeUseRestriction);
			EndIf;
			Continue;
		EndIf;
		
		DataField.UseRestriction.Field = True;
		DataField.UseRestriction.Condition = True;
		DataField.UseRestriction.Group = True;
		DataField.UseRestriction.Order = True;
		If TypeOf(DataField) <> Type("DataCompositionSchemaCalculatedField") Then
			FillPropertyValues(DataField.AttributeUseRestriction,
				DataField.UseRestriction);
		EndIf;
	EndDo;
	
EndProcedure

// For internal use only.
Procedure SetGroupingUsage(GroupName, Use,
			DCSettings, DCUserSettings) Export
	
	Item = FindGroupItemByName(DCSettings.Structure, GroupName);
	If Item <> Undefined Then
		Setting = DCUserSettings.Items.Find(Item.UserSettingID);
		If Setting = Undefined Then
			Item.Use = Use;
		Else
			Setting.Use = Use;
		EndIf;
	EndIf;
	
EndProcedure

// Intended for function "GroupByMasterReportsEnabled".
Function FindGroupItemByName(ItemsCollection, Name)
	
	Result = Undefined;
	
	For Each Item In ItemsCollection Do
		If TypeOf(Item) <> Type("DataCompositionGroup")
		   And TypeOf(Item) <> Type("DataCompositionTableGroup")
		   And TypeOf(Item) <> Type("DataCompositionTable") Then
			Continue;
		EndIf;
		If Item.Name = Name Then
			Result = Item;
		ElsIf TypeOf(Item) = Type("DataCompositionTable") Then
			Result = FindGroupItemByName(Item.Rows, Name);
			If Result = Undefined Then
				Result = FindGroupItemByName(Item.Columns, Name);
			EndIf;
		Else
			Result = FindGroupItemByName(Item.Structure, Name);
		EndIf;
		If Result <> Undefined Then
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns:
//  TypeDescription
//
Function DetailsOfAccessKindGroupAndValueTypes(AllTypes = Undefined) Export
	
	UsedAccessKinds = AccessManagementInternal.UsedAccessKinds();
	
	Types = New Array;
	ValueTable = AccessManagementInternalCached.AccessKindsGroupsAndValuesTypes();
	For Each SpecificationRow In ValueTable Do
		If TypeOf(SpecificationRow.AccessKind) = Type("CatalogRef.Users")
		 Or TypeOf(SpecificationRow.AccessKind) = Type("CatalogRef.ExternalUsers") Then
			Continue;
		EndIf;
		Type = TypeOf(SpecificationRow.GroupAndValueType);
		If AllTypes <> Undefined Then
			AllTypes.Add(Type);
		EndIf;
		If UsedAccessKinds.Get(SpecificationRow.AccessKind) <> Undefined Then
			Types.Add(Type);
		EndIf;
	EndDo;
	
	Types.Add(Type("CatalogRef.Users"));
	Types.Add(Type("CatalogRef.UserGroups"));
	If AllTypes <> Undefined Then
		AllTypes.Add(Type("CatalogRef.Users"));
		AllTypes.Add(Type("CatalogRef.UserGroups"));
	EndIf;
	
	If ExternalUsers.UseExternalUsers() Then
		Types.Add(Type("CatalogRef.ExternalUsers"));
		Types.Add(Type("CatalogRef.ExternalUsersGroups"));
		If AllTypes <> Undefined Then
			AllTypes.Add(Type("CatalogRef.ExternalUsers"));
			AllTypes.Add(Type("CatalogRef.ExternalUsersGroups"));
		EndIf;
	EndIf;
	
	Return New TypeDescription(Types);
	
EndFunction

// Parameters:
//  DetailsDataAddress - String - the address of the temporary report details data storage.
//  Details - DataCompositionDetailsID - details item.
//
// Returns:
//  Structure:
//   * DetailsFieldName1 - String
//   * FieldList - Map of KeyAndValue:
//    ** Key - String
//    ** Value - Arbitrary
//   * CanUseRolesRightsReport - Boolean
//
Function DetailsParameters(DetailsDataAddress, Details) Export
	
	DetailsData = GetFromTempStorage(DetailsDataAddress); // DataCompositionDetailsData
	DetailsItem = DetailsData.Items[Details];

	FieldList = New Map;
	FillFieldsList(FieldList, DetailsItem);
	
	DetailsFieldName1 = "";
	For Each Simple In DetailsItem.GetFields() Do
		DetailsFieldName1 = Simple.Field;
		Break;
	EndDo;
	
	Result = New Structure;
	Result.Insert("DetailsFieldName1", DetailsFieldName1);
	Result.Insert("FieldList", FieldList);
	Result.Insert("CanUseRolesRightsReport",
		AccessRight("View", Metadata.Reports.RolesRights));
	
	ParameterFormatName = New DataCompositionParameter("NameFormat");
	IsRolesRightsReport = DetailsData.Settings.DataParameters.Items.Find(ParameterFormatName) <> Undefined;
	
	DetailsValue = FieldList.Get(DetailsFieldName1);
	FullObjectName = FieldList.Get("FullObjectName");
	
	If (DetailsFieldName1 = "ReportTitleMetadataObject"
	      Or DetailsFieldName1 = "MetadataObject"
	      Or DetailsFieldName1 = "FilterTitle"
	      Or DetailsFieldName1 = "Report")
	   And ValueIsFilled(DetailsValue)
	 Or IsRolesRightsReport
	   And ValueIsFilled(FullObjectName)
	   And FieldList.Get("NameOfRole") = Undefined Then
		
		If IsRolesRightsReport Then
			MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
		Else
			MetadataObject = Common.MetadataObjectByID(DetailsValue, False);
		EndIf;
		If TypeOf(MetadataObject) = Type("MetadataObject") Then
			Try
				URL = GetURL(MetadataObject);
			Except
				If Metadata.CommonForms.Contains(MetadataObject) Then
					URL = "e1cib/app/" + MetadataObject.FullName();
				Else
					URL = ""; // A URL might not be provided.
				EndIf;
			EndTry;
			If (StrFind(URL, "/command/") > 0
			      Or StrStartsWith(URL, "e1cib/list/")
			      Or StrStartsWith(URL, "e1cib/app/"))
			   And AccessRight("View", MetadataObject) Then
				FieldList.Insert("MetadataObjectURL", URL);
			EndIf;
			FieldList.Insert("MetadataObjectFullName", MetadataObject.FullName());
		EndIf;
	EndIf;
	
	If IsRolesRightsReport Then
		Return Result;
	EndIf;
	
	AccessGroup = FieldList.Get("AccessGroup");
	If Not AccessRight("View", Metadata.Catalogs.AccessGroups)
	 Or ValueIsFilled(AccessGroup)
	   And TypeOf(AccessGroup) = Type("CatalogRef.AccessGroups")
	   And Not AccessManagement.ReadingAllowed(AccessGroup) Then
		
		FieldList.Delete("AccessGroup");
	EndIf;
	
	AccessValue = FieldList.Get("AccessValue");
	If TypeOf(AccessValue) = Type("String") Then
		BlankRefs = AccessManagementInternal.EmptyAccessValueReferences();
		FoundRow = BlankRefs.Find(AccessValue, "Presentation");
		If FoundRow <> Undefined Then
			FieldList.Insert("AccessValue", FoundRow.EmptyRef);
		EndIf;
	EndIf;
	
	ValueMetadata = Metadata.FindByType(TypeOf(DetailsValue));
	If ValueMetadata = Undefined
	 Or Not AccessRight("View", ValueMetadata)
	 Or ValueIsFilled(DetailsValue)
	   And Not AccessManagement.ReadingAllowed(DetailsValue) Then
		
		FieldList.Delete(DetailsFieldName1);
		DetailsValue = Undefined;
	EndIf;
	
	If ValueIsFilled(DetailsValue)
	   And DetailsFieldName1 = "OwnerOrUserSettings"
	   And Metadata.DefinedTypes.RightsSettingsOwner.Type.ContainsType(TypeOf(DetailsValue))
	   And Not AccessManagement.HasRight("RightsManagement", DetailsValue) Then
		
		FieldList.Delete(DetailsFieldName1);
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//   FieldList - Map
//   DetailsItem - DataCompositionFieldDetailsItem
//                      - DataCompositionGroupDetailsItem
//
Procedure FillFieldsList(FieldList, DetailsItem)
	
	If TypeOf(DetailsItem) = Type("DataCompositionFieldDetailsItem") Then
		For Each Simple In DetailsItem.GetFields() Do
			If FieldList[Simple.Field] = Undefined Then
				FieldList.Insert(Simple.Field, Simple.Value);
			EndIf;
		EndDo;
	EndIf;
		
	For Each Parent In DetailsItem.GetParents() Do
		FillFieldsList(FieldList, Parent);
	EndDo;
	
EndProcedure

// Returns a table containing access restriction kind by metadata object right.
// If no record is returned, that means this right has no restrictions.
//  
//
// Parameters:
//  ForExternalUsers - Boolean, Undefined - If "True", return restrictions for external users.
//     If "False", return restrictions for internal users. If "Undefined", return restrictions for all users.
//    This applies only to universal restrictions.
//
//  ShouldAddIsAuthorizedUser - Boolean - Add the "Users" or
//    "ExternalUsers" access type with the "IsAuthorizedUser" flag if
//    the table is verified only using the "IsAuthorizedUser" function.
//    
//
//  AllTablesWithRestriction - Array of CatalogRef.MetadataObjectIDs
//                          - Array of CatalogRef.ExtensionObjectIDs - Return value.
//                              If an array is specified, tables for which RLS is configured using
//                              the "AccessManagement" subsystem are added to it.
//                          - Undefined - Optional.
//
// Returns:
//  ValueTable:
//   * ForExternalUsers - Boolean - If False, restrict the access for internal users.
//                                 If True, restrict the access for external users.
//                                 This column is applicable only to universal restrictions.
//   * Table       - CatalogRef.MetadataObjectIDs
//                   - CatalogRef.ExtensionObjectIDs - Table ID.
//   * AccessKind    - DefinedType.AccessValue - "ReadRightByID", "EditByIDRight".
//      In the high-performance mode, this corresponds to the presence of one of
//        the following functions in the object's access restriction:
//          1. "ReadObjectAllowed", "EditObjectAllowed", "ReadListAllowed", "EditListAllowed",
//            "IsAuthorizedUser", "AccessRight", "RoleAvailable".
//            2. "Enum.AdditionalAccessValues.AccessAllowed<Restriction disabled>.
//            3. "Enum.AdditionalAccessValues.AccessDenied<Access denied> (restriction "WHERE FALSE").
//          
//            
//            
//            
//        
//        
//   * Presentation - String - Access kind presentation.
//   * Right         - String - Read, Update.
//   * IsAuthorizedUser - Boolean - Can be "True" if
//      the "ShouldAddIsAuthorizedUser" parameter is enabled.
//
Function AccessRestrictionKinds(ForExternalUsers = Undefined, ShouldAddIsAuthorizedUser = False,
			AllTablesWithRestriction = Undefined) Export
	
	UniversalRestriction =
		AccessManagementInternal.LimitAccessAtRecordLevelUniversally(True, True);
	
	If Not UniversalRestriction Then
		Cache = AccessManagementInternalCached.MetadataObjectsRightsRestrictionsKinds();
		
		If CurrentSessionDate() < Cache.UpdateDate + 60*30 Then
			Return Cache.Table;
		EndIf;
	EndIf;
	
	AccessKindsValuesTypes =
		AccessManagementInternalCached.ValuesTypesOfAccessKindsAndRightsSettingsOwners().Get(); // ValueTable
	
	Query = New Query;
	PermanentRestrictionKinds = AccessManagementInternalCached.PermanentMetadataObjectsRightsRestrictionsKinds();
	Query.SetParameter("PermanentRestrictionKinds", PermanentRestrictionKinds);
	
	If UniversalRestriction Then
		Query.Text =
		"SELECT
		|	PermanentRestrictionKinds.ForExternalUsers AS ForExternalUsers,
		|	PermanentRestrictionKinds.FullName AS FullName,
		|	PermanentRestrictionKinds.Table AS Table,
		|	PermanentRestrictionKinds.Right AS Right,
		|	PermanentRestrictionKinds.AccessKind AS AccessKind,
		|	PermanentRestrictionKinds.IsAuthorizedUser AS IsAuthorizedUser
		|INTO PermanentRestrictionKinds
		|FROM
		|	&PermanentRestrictionKinds AS PermanentRestrictionKinds
		|WHERE
		|	&FilterForExternalUsers
		|	AND &FilterIsAuthorizedUser
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AccessTypesWithView.AccessKind AS AccessKind,
		|	AccessTypesWithView.Presentation AS Presentation
		|INTO AccessTypesWithView
		|FROM
		|	&AccessTypesWithView AS AccessTypesWithView
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TablesWithRestrictionDisabled.ForExternalUsers AS ForExternalUsers,
		|	TablesWithRestrictionDisabled.FullName AS FullName,
		|	TablesWithRestrictionDisabled.Table AS Table,
		|	TablesWithRestrictionDisabled.Right AS Right,
		|	TablesWithRestrictionDisabled.AccessKind AS AccessKind,
		|	TablesWithRestrictionDisabled.Presentation AS Presentation
		|INTO TablesWithRestrictionDisabled
		|FROM
		|	&TablesWithRestrictionDisabled AS TablesWithRestrictionDisabled
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	AccessRestrictionKinds.ForExternalUsers AS ForExternalUsers,
		|	AccessRestrictionKinds.Table AS Table,
		|	AccessRestrictionKinds.Right AS Right,
		|	AccessRestrictionKinds.AccessKind AS AccessKind,
		|	AccessRestrictionKinds.Presentation AS Presentation,
		|	AccessRestrictionKinds.IsAuthorizedUser AS IsAuthorizedUser
		|FROM
		|	(SELECT
		|		PermanentRestrictionKinds.ForExternalUsers AS ForExternalUsers,
		|		PermanentRestrictionKinds.Table AS Table,
		|		CASE
		|			WHEN NOT TablesWithRestrictionDisabled.FullName IS NULL
		|				THEN TablesWithRestrictionDisabled.Right
		|			ELSE PermanentRestrictionKinds.Right
		|		END AS Right,
		|		CASE
		|			WHEN NOT TablesWithRestrictionDisabled.FullName IS NULL
		|				THEN TablesWithRestrictionDisabled.AccessKind
		|			ELSE PermanentRestrictionKinds.AccessKind
		|		END AS AccessKind,
		|		CASE
		|			WHEN NOT TablesWithRestrictionDisabled.FullName IS NULL
		|				THEN TablesWithRestrictionDisabled.Presentation
		|			ELSE ISNULL(AccessTypesWithView.Presentation, &RepresentationUnknownAccessType)
		|		END AS Presentation,
		|		CASE
		|			WHEN NOT TablesWithRestrictionDisabled.FullName IS NULL
		|				THEN FALSE
		|			ELSE PermanentRestrictionKinds.IsAuthorizedUser
		|		END AS IsAuthorizedUser
		|	FROM
		|		PermanentRestrictionKinds AS PermanentRestrictionKinds
		|			LEFT JOIN TablesWithRestrictionDisabled AS TablesWithRestrictionDisabled
		|			ON (TablesWithRestrictionDisabled.ForExternalUsers = PermanentRestrictionKinds.ForExternalUsers)
		|				AND (TablesWithRestrictionDisabled.FullName = PermanentRestrictionKinds.FullName)
		|				AND (TablesWithRestrictionDisabled.Right = PermanentRestrictionKinds.Right)
		|				AND (PermanentRestrictionKinds.IsAuthorizedUser = FALSE)
		|			LEFT JOIN AccessTypesWithView AS AccessTypesWithView
		|			ON (AccessTypesWithView.AccessKind = PermanentRestrictionKinds.AccessKind)
		|	WHERE
		|		PermanentRestrictionKinds.AccessKind <> UNDEFINED
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TablesWithRestrictionDisabled.ForExternalUsers,
		|		TablesWithRestrictionDisabled.Table,
		|		TablesWithRestrictionDisabled.Right,
		|		TablesWithRestrictionDisabled.AccessKind,
		|		TablesWithRestrictionDisabled.Presentation,
		|		FALSE
		|	FROM
		|		TablesWithRestrictionDisabled AS TablesWithRestrictionDisabled
		|			LEFT JOIN PermanentRestrictionKinds AS PermanentRestrictionKinds
		|			ON (PermanentRestrictionKinds.ForExternalUsers = TablesWithRestrictionDisabled.ForExternalUsers)
		|				AND (PermanentRestrictionKinds.FullName = TablesWithRestrictionDisabled.FullName)
		|	WHERE
		|		PermanentRestrictionKinds.FullName IS NULL
		|		AND TablesWithRestrictionDisabled.Table <> UNDEFINED) AS AccessRestrictionKinds";
		
		If TypeOf(ForExternalUsers) = Type("Boolean") Then
			Query.SetParameter("ForExternalUsers", ForExternalUsers);
			Query.Text = StrReplace(Query.Text, "&FilterForExternalUsers",
				"PermanentRestrictionKinds.ForExternalUsers = &ForExternalUsers");
		Else
			Query.Text = StrReplace(Query.Text, "&FilterForExternalUsers", "TRUE");
		EndIf;
		Query.SetParameter("AccessTypesWithView",
			AccessTypesWithView(AccessKindsValuesTypes, False));
		Query.SetParameter("RepresentationUnknownAccessType",
			RepresentationUnknownAccessType());
		TablesWithRestrictionDisabled = TablesWithRestrictionDisabled(ForExternalUsers,
			PermanentRestrictionKinds);
		Query.SetParameter("TablesWithRestrictionDisabled", TablesWithRestrictionDisabled);
	Else
		Query.SetParameter("AccessKindsValuesTypes", AccessKindsValuesTypes);
		Query.SetParameter("UsedAccessKinds",
			AccessTypesWithView(AccessKindsValuesTypes, True));
		// ACC:96-off - No.434. Using JOIN is acceptable as the rows should be unique and
		// the result will be cached.
		Query.Text =
		"SELECT
		|	PermanentRestrictionKinds.Table AS Table,
		|	PermanentRestrictionKinds.Right AS Right,
		|	PermanentRestrictionKinds.AccessKind AS AccessKind,
		|	PermanentRestrictionKinds.ObjectTable AS ObjectTable,
		|	PermanentRestrictionKinds.IsAuthorizedUser AS IsAuthorizedUser
		|INTO PermanentRestrictionKinds
		|FROM
		|	&PermanentRestrictionKinds AS PermanentRestrictionKinds
		|WHERE
		|	&FilterIsAuthorizedUser
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AccessKindsValuesTypes.AccessKind AS AccessKind,
		|	AccessKindsValuesTypes.ValuesType AS ValuesType
		|INTO AccessKindsValuesTypes
		|FROM
		|	&AccessKindsValuesTypes AS AccessKindsValuesTypes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	UsedAccessKinds.AccessKind AS AccessKind,
		|	UsedAccessKinds.Presentation AS Presentation
		|INTO UsedAccessKinds
		|FROM
		|	&UsedAccessKinds AS UsedAccessKinds
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	PermanentRestrictionKinds.Table AS Table,
		|	""Read"" AS Right,
		|	VALUETYPE(RowsSets.AccessValue) AS ValuesType
		|INTO VariableRestrictionKinds
		|FROM
		|	InformationRegister.AccessValuesSets AS SetsNumbers
		|		INNER JOIN PermanentRestrictionKinds AS PermanentRestrictionKinds
		|		ON (PermanentRestrictionKinds.Right = ""Read"")
		|			AND (PermanentRestrictionKinds.AccessKind = UNDEFINED)
		|			AND (VALUETYPE(SetsNumbers.Object) = VALUETYPE(PermanentRestrictionKinds.ObjectTable))
		|			AND (SetsNumbers.Read)
		|		INNER JOIN InformationRegister.AccessValuesSets AS RowsSets
		|		ON (RowsSets.Object = SetsNumbers.Object)
		|			AND (RowsSets.SetNumber = SetsNumbers.SetNumber)
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	PermanentRestrictionKinds.Table,
		|	""Update"",
		|	VALUETYPE(RowsSets.AccessValue)
		|FROM
		|	InformationRegister.AccessValuesSets AS SetsNumbers
		|		INNER JOIN PermanentRestrictionKinds AS PermanentRestrictionKinds
		|		ON (PermanentRestrictionKinds.Right = ""Update"")
		|			AND (PermanentRestrictionKinds.AccessKind = UNDEFINED)
		|			AND (VALUETYPE(SetsNumbers.Object) = VALUETYPE(PermanentRestrictionKinds.ObjectTable))
		|			AND (SetsNumbers.Update)
		|		INNER JOIN InformationRegister.AccessValuesSets AS RowsSets
		|		ON (RowsSets.Object = SetsNumbers.Object)
		|			AND (RowsSets.SetNumber = SetsNumbers.SetNumber)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PermanentRestrictionKinds.Table AS Table,
		|	PermanentRestrictionKinds.Right AS Right,
		|	PermanentRestrictionKinds.AccessKind AS AccessKind,
		|	PermanentRestrictionKinds.IsAuthorizedUser AS IsAuthorizedUser
		|INTO AllRightsRestrictionsKinds
		|FROM
		|	PermanentRestrictionKinds AS PermanentRestrictionKinds
		|		LEFT JOIN AccessKindsValuesTypes AS AccessKindsValuesTypes
		|		ON PermanentRestrictionKinds.AccessKind = AccessKindsValuesTypes.AccessKind
		|WHERE
		|	PermanentRestrictionKinds.AccessKind <> UNDEFINED
		|	AND (NOT AccessKindsValuesTypes.AccessKind IS NULL
		|			OR VALUETYPE(PermanentRestrictionKinds.AccessKind) = TYPE(Enum.AdditionalAccessValues))
		|
		|UNION
		|
		|SELECT
		|	VariableRestrictionKinds.Table,
		|	VariableRestrictionKinds.Right,
		|	AccessKindsValuesTypes.AccessKind,
		|	FALSE
		|FROM
		|	VariableRestrictionKinds AS VariableRestrictionKinds
		|		INNER JOIN AccessKindsValuesTypes AS AccessKindsValuesTypes
		|		ON (VariableRestrictionKinds.ValuesType = VALUETYPE(AccessKindsValuesTypes.ValuesType))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllRightsRestrictionsKinds.Table AS Table,
		|	AllRightsRestrictionsKinds.Right AS Right,
		|	AllRightsRestrictionsKinds.AccessKind AS AccessKind,
		|	AllRightsRestrictionsKinds.IsAuthorizedUser AS IsAuthorizedUser,
		|	ISNULL(UsedAccessKinds.Presentation, """") AS Presentation
		|FROM
		|	AllRightsRestrictionsKinds AS AllRightsRestrictionsKinds
		|		LEFT JOIN UsedAccessKinds AS UsedAccessKinds
		|		ON AllRightsRestrictionsKinds.AccessKind = UsedAccessKinds.AccessKind
		|WHERE
		|	(NOT UsedAccessKinds.AccessKind IS NULL
		|			OR AllRightsRestrictionsKinds.IsAuthorizedUser)";
		// ACC:96-on
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&FilterIsAuthorizedUser",
		?(ShouldAddIsAuthorizedUser, "TRUE",
			"PermanentRestrictionKinds.IsAuthorizedUser = FALSE"));
	
	Upload0 = Query.Execute().Unload();
	
	If Not UniversalRestriction Then
		Cache.Table = Upload0;
		Cache.UpdateDate = CurrentSessionDate();
	EndIf;
	
	If AllTablesWithRestriction <> Undefined Then
		TablesWithRestriction = PermanentRestrictionKinds.Copy(, "Table");
		If UniversalRestriction Then
			For Each SpecificationRow In TablesWithRestrictionDisabled Do
				TablesWithRestriction.Add().Table = SpecificationRow.Table;
			EndDo;
		EndIf;
		TablesWithRestriction.GroupBy("Table");
		AllTablesWithRestriction = TablesWithRestriction.UnloadColumn("Table");
	EndIf;
	
	Return Upload0;
	
EndFunction

// For function AccessRestrictionKinds.
Function AccessTypesWithView(AccessKindsValuesTypes, UsedOnly)
	
	AccessKinds = AccessKindsValuesTypes.Copy(, "AccessKind");
	
	AccessKinds.GroupBy("AccessKind");
	AccessKinds.Columns.Add("Presentation", New TypeDescription("String", , New StringQualifiers(150)));
	UsedAccessKinds = AccessManagementInternal.UsedAccessKinds();
	
	IndexOf = AccessKinds.Count()-1;
	While IndexOf >= 0 Do
		String = AccessKinds[IndexOf];
		AccessKindProperties = AccessManagementInternal.AccessKindProperties(String.AccessKind);
		
		If AccessKindProperties = Undefined Then
			RightsSettingsOwnerMetadata = Metadata.FindByType(TypeOf(String.AccessKind));
			If RightsSettingsOwnerMetadata = Undefined Then
				String.Presentation = RepresentationUnknownAccessType();
			Else
				String.Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Rights settings for %1'"),
					RightsSettingsOwnerMetadata.Presentation());
			EndIf;
			
		ElsIf Not UsedOnly
		      Or UsedAccessKinds.Get(AccessKindProperties.Ref) <> Undefined Then
			
			String.Presentation = AccessManagementInternal.AccessKindPresentation(AccessKindProperties);
		Else
			AccessKinds.Delete(String);
		EndIf;
		
		IndexOf = IndexOf - 1;
	EndDo;
	
	NewRow = AccessKinds.Add();
	NewRow.AccessKind = Enums.AdditionalAccessValues.Undefined;
	NewRow.Presentation = RestrictionPresentationWithoutAccessKinds();
	
	Return AccessKinds;
	
EndFunction

// Intended for functions "AccessRestrictionKinds", "AccessKindsWithPresentation".
Function RepresentationUnknownAccessType()
	
	Return NStr("en = 'Unknown access kind'");
	
EndFunction

// For function AccessRestrictionKinds.
Function TablesWithRestrictionDisabled(ForExternalUsers, PermanentRestrictionKinds)
	
	IDsTypes = New Array;
	IDsTypes.Add(Type("CatalogRef.MetadataObjectIDs"));
	IDsTypes.Add(Type("CatalogRef.ExtensionObjectIDs"));
	
	Result = New ValueTable;
	Result.Columns.Add("ForExternalUsers", New TypeDescription("Boolean"));
	Result.Columns.Add("FullName",
		Metadata.Catalogs.MetadataObjectIDs.Attributes.FullName.Type);
	Result.Columns.Add("Table",    New TypeDescription(IDsTypes));
	Result.Columns.Add("Right",      New TypeDescription("String", , New StringQualifiers(20)));
	Result.Columns.Add("AccessKind", AccessManagementInternalCached.DetailsOfAccessValuesTypesAndRightsSettingsOwners());
	Result.Columns.Add("Presentation", New TypeDescription("String", , New StringQualifiers(150)));
	
	ActiveParameters = AccessManagementInternal.ActiveAccessRestrictionParameters(
		Undefined, Undefined, False);
	
	If ForExternalUsers <> True Then
		AddTablesWithRestrictionDisabled(Result, ActiveParameters, PermanentRestrictionKinds, False);
	EndIf;
	If ForExternalUsers <> False Then
		AddTablesWithRestrictionDisabled(Result, ActiveParameters, PermanentRestrictionKinds, True);
	EndIf;
	FullNames = Result.UnloadColumn("FullName");
	NameIdentifiers = Common.MetadataObjectIDs(FullNames, False);
	For Each String In Result Do
		String.Table = NameIdentifiers.Get(String.FullName);
	EndDo;
	
	Return Result;
	
EndFunction

// Intended for function "UnrestrictedTables".
Procedure AddTablesWithRestrictionDisabled(TablesWithRestrictionDisabled,
			ActiveParameters, PermanentRestrictionKinds, ForExternalUsers)
	
	If ForExternalUsers Then
		AdditionalContext = ActiveParameters.AdditionalContext.ForExternalUsers;
	Else
		AdditionalContext = ActiveParameters.AdditionalContext.ForUsers;
	EndIf;
	
	ListsWithDisabledRestriction       = AdditionalContext.ListsWithDisabledRestriction;
	ListsWithReadRestrictionDisabled = AdditionalContext.ListsWithReadRestrictionDisabled;
	ListRestrictionsProperties           = AdditionalContext.ListRestrictionsProperties;
	
	For Each KeyAndValue In ListRestrictionsProperties Do
		FullName = KeyAndValue.Key;
		Properties = KeyAndValue.Value;
		AccessKind = Undefined;
		Rights = "Read,Update";
		
		If Properties.AccessDenied Then
			AccessKind    = Enums.AdditionalAccessValues.AccessDenied;
			Presentation = "<" + NStr("en = 'Access denied'") + ">";
			
		ElsIf ListsWithDisabledRestriction.Get(FullName) <> Undefined Then
			AccessKind    = Enums.AdditionalAccessValues.AccessAllowed;
			Presentation = "<" + NStr("en = 'Restriction disabled'") + ">";
		Else
			If ListsWithReadRestrictionDisabled.Get(FullName) <> Undefined Then
				NewRow = TablesWithRestrictionDisabled.Add();
				NewRow.ForExternalUsers = ForExternalUsers;
				NewRow.FullName = FullName;
				NewRow.Right = "Read";
				NewRow.AccessKind = Enums.AdditionalAccessValues.AccessAllowed;
				NewRow.Presentation = "<" + NStr("en = 'Read restriction disabled'") + ">";
				Rights = "Update";
			EndIf;
			If Not ValueIsFilled(Properties.UsedAccessValuesTypes.Get()) Then
				Filter = New Structure("FullName, ForExternalUsers", FullName, ForExternalUsers);
				If Rights = "Update" Then
					Filter.Insert("Right", "Update");
				EndIf;
				If PermanentRestrictionKinds.FindRows(Filter).Count() > 0 Then
					AccessKind    = Enums.AdditionalAccessValues.Undefined;
					Presentation = RestrictionPresentationWithoutAccessKinds();
				EndIf;
			EndIf;
		EndIf;
		
		If AccessKind = Undefined Then
			Continue;
		EndIf;
		
		For Each Right In StrSplit(Rights, ",") Do
			NewRow = TablesWithRestrictionDisabled.Add();
			NewRow.ForExternalUsers = ForExternalUsers;
			NewRow.FullName = FullName;
			NewRow.Right = Right;
			NewRow.AccessKind = AccessKind;
			NewRow.Presentation = Presentation;
		EndDo;
	EndDo;
	
EndProcedure

Function RestrictionPresentationWithoutAccessKinds() Export
	Return "<" + NStr("en = 'Restriction without access kinds'") + ">";
EndFunction


Procedure AddUsersRightsCommand(ReportsCommands, Parameters, AreUsers)
	
	VariantPresentation = NStr("en = 'User rights'");
	OnlyInAllActions = False;
	OptionImportance = "";
	
	If Parameters.FormName = "Catalog.Users.Form.ListForm"
	 Or Parameters.FormName = "Catalog.ExternalUsers.Form.ListForm" Then
		
		AreUsers = True;
		If Not Users.IsFullUser() Then
			Return;
		EndIf;
		VariantKey = "UsersRightsToTables";
		
	ElsIf Parameters.FormName = "Catalog.Users.Form.ItemForm"
	      Or Parameters.FormName = "Catalog.ExternalUsers.Form.ItemForm" Then
		
		AreUsers = True;
		If Not Users.IsFullUser() Then
			Return;
		EndIf;
		VariantKey = "UserRightsToTables";
		VariantPresentation = NStr("en = 'User rights'");
	Else
		If Not Users.IsFullUser() Then
			VariantKey = "UserRightsToTable";
			VariantPresentation = NStr("en = 'User rights'");
		Else
			VariantKey = "UsersRightsToTable";
		EndIf;
		OnlyInAllActions = True;
		OptionImportance = "SeeAlso";
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.VariantKey = VariantKey;
	Command.Presentation = VariantPresentation;
	Command.OnlyInAllActions = OnlyInAllActions;
	Command.MultipleChoice = True;
	Command.Importance = OptionImportance;
	Command.Manager = "Report.AccessRightsAnalysis";
	
EndProcedure

Procedure AddRightsToDataElementCommand(ReportsCommands, Parameters)
	
	AddCommand = True;
	VariantPresentation = UsersRightsToObjectOptionPresentation(Parameters, AddCommand);
	
	If Not AddCommand Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.VariantKey = "UsersRightsToObject";
	Command.Presentation = VariantPresentation;
	Command.OnlyInAllActions = True;
	Command.MultipleChoice = False;
	Command.Importance = "SeeAlso";
	Command.Manager = "Report.AccessRightsAnalysis";
	Command.ParameterType = AccessManagementInternalCached.DataElementsTypes();
	
EndProcedure

Procedure AddRightsByValueCommand(ReportsCommands, Parameters)
	
	If Not Users.IsFullUser() Then
		Return;
	EndIf;
	
	AllTypes = New Array;
	TypeOfUsedValues = DetailsOfAccessKindGroupAndValueTypes(AllTypes);
	
	AddCommand = False;
	For Each Type In Parameters.SourcesTypes Do
		If TypeOfUsedValues.ContainsType(Type) Then
			AddCommand = True;
			Break;
		EndIf;
	EndDo;
	
	If Not AddCommand Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.VariantKey = "UsersRightsByAllowedValue";
	Command.Presentation = NStr("en = 'Rights by allowed value'");
	Command.OnlyInAllActions = True;
	Command.MultipleChoice = False;
	Command.Importance = "SeeAlso";
	Command.Manager = "Report.AccessRightsAnalysis";
	Command.ParameterType = New TypeDescription(AllTypes);
	
EndProcedure

Function UsersRightsToObjectOptionPresentation(Parameters, AddCommand)
	
	MetadataObjectKind = Upper(StrSplit(Parameters.FormName, ".")[0]);
	Result = Null;
	
	If Upper(MetadataObjectKind) = Upper("ExchangePlan") Then
		Result = NStr("en = 'Rights to exchange plan'");
		
	ElsIf Upper(MetadataObjectKind) = Upper("Catalog") Then
		Result = NStr("en = 'Rights to catalog item'");
		
	ElsIf Upper(MetadataObjectKind) = Upper("Document")
	      Or Upper(MetadataObjectKind) = Upper("DocumentJournal") Then
		
		Result = NStr("en = 'Rights to document'");
		
	ElsIf Upper(MetadataObjectKind) = Upper("ChartOfCharacteristicTypes") Then
		Result = NStr("en = 'Rights to CCT'");
		
	ElsIf Upper(MetadataObjectKind) = Upper("ChartOfAccounts") Then
		Result = NStr("en = 'Rights to CA'");
		
	ElsIf Upper(MetadataObjectKind) = Upper("ChartOfCalculationTypes") Then
		Result = NStr("en = 'Access rights that apply to calculation type'");
		
	ElsIf Upper(MetadataObjectKind) = Upper("InformationRegister")
	      Or Upper(MetadataObjectKind) = Upper("AccumulationRegister")
	      Or Upper(MetadataObjectKind) = Upper("AccountingRegister")
	      Or Upper(MetadataObjectKind) = Upper("CalculationRegister") Then
		
		Result = NStr("en = 'Access rights that apply to register row'");
		AddCommand = False;
		
	ElsIf Upper(MetadataObjectKind) = Upper("BusinessProcess") Then
		Result = NStr("en = 'Access rights that apply to business process'");
		
	ElsIf Upper(MetadataObjectKind) = Upper("Task") Then
		Result = NStr("en = 'Access rights that apply to task'");
	EndIf;
	
	If Result = Null Then
		AddCommand = False;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf

