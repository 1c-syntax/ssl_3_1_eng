///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns a value table containing settings for managing the file archive.
// Used by scheduled job TransferFilesBetweenOperationalStorageAndFileArchive.
//
// Returns:
//  ValueTable
//
Function GetSettingsForWorkingWithFileArchiveForTransferringFiles() Export

	Query = New Query;
	Query.Text = GetQueryTextOfCurrentSettingsForWorkingWithFileArchive(True);

	Return Query.Execute().Unload();

EndFunction

// Returns the default retention period in days.
//
// Returns:
//  Number
//
Function GetNumberOfDaysOfStorageFromDefaultSetting() Export

	Result = 0;

	Query = New Query;
	Query.Text =
       "SELECT
       |	FileArchiveWorkSettings.TransferToFileArchiveInDays AS TransferToFileArchiveInDays
       |FROM
       |	InformationRegister.FileArchiveWorkSettings AS FileArchiveWorkSettings
       |WHERE
       |	FileArchiveWorkSettings.FileOwner = UNDEFINED
       |	AND FileArchiveWorkSettings.FileOwnerType = UNDEFINED";

	DataSelection = Query.Execute().Select();
	If DataSelection.Next() Then
		Result = DataSelection.TransferToFileArchiveInDays;
	EndIf;

	If Result = 0 Then
		Result = GetDefaultValueForTransferToFileArchiveInDays();
	EndIf;

	Return Result;

EndFunction

#EndRegion

#Region Private

// Adds an entry to the information register.
// 
Procedure AddRecord(RecordStructure) Export

	RecordSet = CreateRecordSet();
	RecordSet.Filter.FileOwner.Set(RecordStructure["FileOwner"]);
	RecordSet.Filter.FileOwnerType.Set(RecordStructure["FileOwnerType"]);

	Record = RecordSet.Add();
	FillPropertyValues(Record, RecordStructure);

	RecordSet.Write(True);

EndProcedure

// Deletes an entry from the information register.
//
Procedure DeleteRecord(FileOwner, FileOwnerType) Export
	
	Set = CreateRecordSet();
	Set.Filter.FileOwner.Set(FileOwner);
	Set.Filter.FileOwnerType.Set(FileOwnerType);
	Set.Write();	
	
EndProcedure 

Function StructureOfRecord() Export
	
	Result = New Structure;
	Result.Insert("FileOwner");
	Result.Insert("FileOwnerType");
	Result.Insert("Action");
	Result.Insert("TransferToFileArchiveInDays");
	Result.Insert("IsFile");
	
	Return Result;
	
EndFunction

Procedure UpdateFileArchiveWorkSettings()
	
	MetadataCatalogs = Metadata.Catalogs;
	
	FilesOwnersTable = New ValueTable;
	FilesOwnersTable.Columns.Add("FileOwner",     New TypeDescription("CatalogRef.MetadataObjectIDs"));
	FilesOwnersTable.Columns.Add("FileOwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	FilesOwnersTable.Columns.Add("IsFile",           New TypeDescription("Boolean"));
	
	For Each Catalog In MetadataCatalogs Do
		
		If Catalog.Attributes.Find("FileOwner") = Undefined Then
			Continue;
		EndIf;
		
		FilesOwnersTypes = Catalog.Attributes.FileOwner.Type.Types();
		For Each OwnerType In FilesOwnersTypes Do
			
			NewRow = FilesOwnersTable.Add();
			NewRow.FileOwner = Common.MetadataObjectID(OwnerType);
			NewRow.FileOwnerType = Common.MetadataObjectID(Catalog);
			If Not StrEndsWith(Catalog.Name, FilesOperationsInternal.CatalogSuffixAttachedFiles()) Then
				NewRow.IsFile = True;
			EndIf;
			
		EndDo;
		
	EndDo;

	Query = New Query; Query.TempTablesManager = New TempTablesManager;
	Query.Text =
		"SELECT
		|	FilesOwnersTable.FileOwner AS FileOwner,
		|	FilesOwnersTable.FileOwnerType AS FileOwnerType,
		|	FilesOwnersTable.IsFile AS IsFile
		|INTO FilesOwnersTable
		|FROM
		|	&FilesOwnersTable AS FilesOwnersTable
		|
		|INDEX BY
		|	FileOwner,
		|	IsFile
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FileArchiveWorkSettings.FileOwner AS FileOwner,
		|	FileArchiveWorkSettings.FileOwnerType AS FileOwnerType,
		|	FileArchiveWorkSettings.IsFile AS IsFile,
		|	MetadataObjectIDs.Ref AS ObjectID
		|INTO SubordinateSettings
		|FROM
		|	InformationRegister.FileArchiveWorkSettings AS FileArchiveWorkSettings
		|		LEFT JOIN Catalog.MetadataObjectIDs AS MetadataObjectIDs
		|		ON FileArchiveWorkSettings.FileOwner <> UNDEFINED
		|			AND FileArchiveWorkSettings.FileOwnerType <> UNDEFINED
		|			AND (VALUETYPE(FileArchiveWorkSettings.FileOwner) = VALUETYPE(MetadataObjectIDs.EmptyRefValue))
		|WHERE
		|	FileArchiveWorkSettings.FileOwner <> UNDEFINED
		|		AND FileArchiveWorkSettings.FileOwnerType <> UNDEFINED		
		|		AND VALUETYPE(FileArchiveWorkSettings.FileOwner) <> TYPE(Catalog.MetadataObjectIDs)
		|
		|INDEX BY
		|	ObjectID,
		|	IsFile,
		|	FileOwnerType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FileArchiveWorkSettings.FileOwner AS FileOwner,
		|	FileArchiveWorkSettings.FileOwnerType AS FileOwnerType,
		|	FileArchiveWorkSettings.IsFile AS IsFile,
		|	FALSE AS NewSetting
		|FROM
		|	InformationRegister.FileArchiveWorkSettings AS FileArchiveWorkSettings
		|		LEFT JOIN FilesOwnersTable AS FilesOwnersTable
		|		ON FileArchiveWorkSettings.FileOwner = FilesOwnersTable.FileOwner
		|			AND FileArchiveWorkSettings.IsFile = FilesOwnersTable.IsFile
		|			AND FileArchiveWorkSettings.FileOwnerType = FilesOwnersTable.FileOwnerType
		|WHERE
		|	FilesOwnersTable.FileOwner IS NULL
		|	AND VALUETYPE(FileArchiveWorkSettings.FileOwner) = TYPE(Catalog.MetadataObjectIDs)
		|
		|UNION ALL
		|
		|SELECT
		|	SubordinateSettings.FileOwner,
		|	SubordinateSettings.FileOwnerType,
		|	SubordinateSettings.IsFile,
		|	FALSE
		|FROM
		|	SubordinateSettings AS SubordinateSettings
		|		LEFT JOIN FilesOwnersTable AS FilesOwnersTable
		|		ON SubordinateSettings.FileOwnerType = FilesOwnersTable.FileOwnerType
		|			AND SubordinateSettings.IsFile = FilesOwnersTable.IsFile
		|			AND SubordinateSettings.ObjectID = FilesOwnersTable.FileOwner
		|WHERE
		|	FilesOwnersTable.FileOwner IS NULL";
	
	Query.Parameters.Insert("FilesOwnersTable", FilesOwnersTable);
	CommonSettingsTable = Query.Execute().Unload();
	
	SettingsForDelete = CommonSettingsTable.FindRows(New Structure("NewSetting", False));
	For Each Setting In SettingsForDelete Do

		DeleteRecord(Setting.FileOwner, Setting.FileOwnerType);

	EndDo;
	
EndProcedure

Function GetDefaultValueForTransferToFileArchiveInDays()

	Return 365;

EndFunction

// Returns:
//   ValueTable:
//   * FileOwner						- AnyRef
//   * OwnerID				- CatalogRef.MetadataObjectIDs
//   * ThisIsDetailedFileTransferSetup	- Boolean
//   * FileOwnerType					- CatalogRef.MetadataObjectIDs
//   * TransferToFileArchiveInDays		- Number
//   * Action								- EnumRef.ActionsInFileArchiveWorkSettings
//   * IsFile								- Boolean
//
Function CurrentSettingsForWorkingWithFileArchive() Export

	SetPrivilegedMode(True);

	UpdateFileArchiveWorkSettings();

	Query = New Query;
	Query.Text = GetQueryTextOfCurrentSettingsForWorkingWithFileArchive();

	Return Query.Execute().Unload();

EndFunction

Function GetQueryTextOfCurrentSettingsForWorkingWithFileArchive(RequestForRoutineTask = False)

	Result = 
		"SELECT
		|	FileArchiveWorkSettings.FileOwner AS FileOwner,
		|	MetadataObjectIDs.Ref AS OwnerID,
		|	CASE
		|		WHEN VALUETYPE(MetadataObjectIDs.Ref) <> VALUETYPE(FileArchiveWorkSettings.FileOwner)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThisIsDetailedFileTransferSetup,
		|	FileArchiveWorkSettings.FileOwnerType AS FileOwnerType,
		|	FileArchiveWorkSettings.TransferToFileArchiveInDays AS TransferToFileArchiveInDays,
		|	FileArchiveWorkSettings.Action AS Action,
		|	&AdditionalField,
		|	FileArchiveWorkSettings.IsFile AS IsFile
		|FROM
		|	InformationRegister.FileArchiveWorkSettings AS FileArchiveWorkSettings
		|		LEFT JOIN Catalog.MetadataObjectIDs AS MetadataObjectIDs
		|		ON FileArchiveWorkSettings.FileOwner <> UNDEFINED
		|		AND FileArchiveWorkSettings.FileOwnerType <> UNDEFINED
		|		AND (VALUETYPE(FileArchiveWorkSettings.FileOwner) = VALUETYPE(MetadataObjectIDs.EmptyRefValue))";

	If Not RequestForRoutineTask Then
		Result = StrReplace(Result, "&AdditionalField,", "");
	EndIf;

	If RequestForRoutineTask Then

		Result = StrReplace(Result, "&AdditionalField,", 
		"	CASE
		|		WHEN VALUETYPE(MetadataObjectIDs.Ref) <> VALUETYPE(FileArchiveWorkSettings.FileOwner)
		|			THEN MetadataObjectIDs.Ref
		|		ELSE FileArchiveWorkSettings.FileOwner
		|	END AS CommonOwnerId,");

		Result = Result + "
		|WHERE
		|	FileArchiveWorkSettings.FileOwner <> UNDEFINED
		|	AND FileArchiveWorkSettings.FileOwnerType <> UNDEFINED"
	EndIf;

	Return Result;

EndFunction

#EndRegion

#EndIf