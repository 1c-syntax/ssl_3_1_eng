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

// Returns the deduplicated file storage parameters for the specified
// BinaryDataStorage catalog item and storage type.
//
// Parameters:
//  BinaryDataStorageRef	- CatalogRef.BinaryDataStorage - Value of the BinaryDataStorage dimension.
//  TypeOfFileStorage				- EnumRef.TypesOfFileStorage, Undefined - Value of FilesStorageKind dimension.
//
// Returns:
//  - Structure - If storage parameters exist, contains the following parameters: FileStorageType, Volume, PathToFile.
//  - Undefined - If storage parameters exist, contains the following parameters: FileStorageType, Volume, PathToFile.
//
Function InformationAboutStoringDeduplicatedFiles(BinaryDataStorageRef, TypeOfFileStorage = Undefined) Export

	If TypeOfFileStorage = Undefined Then
		TypeOfFileStorage = Enums.TypesOfFileStorage.OperationalStorage;
	EndIf;

	Query = New Query;
	Query.SetParameter("BinaryDataStorage"	, BinaryDataStorageRef);
	Query.SetParameter("TypeOfFileStorage"		, TypeOfFileStorage);
	Query.Text = 
		"SELECT
		|	InformationAboutStoringDeduplicatedFiles.FileStorageType AS FileStorageType,
		|	InformationAboutStoringDeduplicatedFiles.Volume AS Volume,
		|	"""" AS PathToFile
		|FROM
		|	InformationRegister.InformationAboutStoringDeduplicatedFiles AS InformationAboutStoringDeduplicatedFiles
		|WHERE
		|	InformationAboutStoringDeduplicatedFiles.BinaryDataStorage = &BinaryDataStorage
		|	AND InformationAboutStoringDeduplicatedFiles.TypeOfFileStorage = &TypeOfFileStorage";

	DataSelection = Query.Execute().Select();
	If DataSelection.Next() Then

		Result = New Structure("FileStorageType,Volume,PathToFile");
		FillPropertyValues(Result, DataSelection);

	Else
		Result = Undefined;
	EndIf;

	Return Result;

EndFunction

// Adds an entry to the information register.
//
// Parameters:
//  BinaryDataStorageRef	- CatalogRef.BinaryDataStorage - Value of the BinaryDataStorage dimension.
//  RecordingParametersVIB				- Structure - See WorkingWithServerFileArchive.ParametersOfEntryInInformationDatabase
//
Procedure AddRecord(BinaryDataStorageRef, RecordingParametersVIB) Export

	If RecordingParametersVIB.ThisIsEntryInFileArchive Then
		TypeOfFileStorage = Enums.TypesOfFileStorage.ArchivalStorage;
	Else
		TypeOfFileStorage = Enums.TypesOfFileStorage.OperationalStorage;
	EndIf;

	Set = CreateRecordSet();
	Set.Filter.BinaryDataStorage.Set(BinaryDataStorageRef);
	Set.Filter.TypeOfFileStorage.Set(TypeOfFileStorage);

	Record = Set.Add();
	Record.BinaryDataStorage	= BinaryDataStorageRef;
	Record.TypeOfFileStorage		= TypeOfFileStorage;
	Record.FileStorageType			= RecordingParametersVIB.FileStorageType;
	Record.Volume						= RecordingParametersVIB.Volume;

	Set.Write();

EndProcedure

// Deletes an entry from the information register.
//
// Parameters:
//  BinaryDataStorageRef	- CatalogRef.BinaryDataStorage - Value of the BinaryDataStorage dimension.
//  TypeOfFileStorage				- EnumRef.TypesOfFileStorage, Undefined - Value of FilesStorageKind dimension.
//
Procedure DeleteRecord(BinaryDataStorageRef, TypeOfFileStorage = Undefined) Export
	
	Block = New DataLock();
	
	LockItem = Block.Add("InformationRegister.InformationAboutStoringDeduplicatedFiles");
	LockItem.SetValue("BinaryDataStorage", BinaryDataStorageRef);

	RecordSet = CreateRecordSet();
	RecordSet.Filter.BinaryDataStorage.Set(BinaryDataStorageRef);
	
	If ValueIsFilled(TypeOfFileStorage) Then
		RecordSet.Filter.TypeOfFileStorage.Set(TypeOfFileStorage);	
	
		LockItem.SetValue("TypeOfFileStorage", TypeOfFileStorage);
	
	EndIf;	

	BeginTransaction();
	Try

		Block.Lock();

		RecordSet.Write();

		CommitTransaction();

	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

#Region UpdateHandlers

// Registers objects on the InfobaseUpdate exchange plan
// for which entries need to be added to the register.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export

	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	FileRepository.BinaryDataStorage AS Ref
	|FROM
	|	InformationRegister.FileRepository AS FileRepository";

	QueryResult = Query.Execute().Unload();
	InfobaseUpdate.MarkForProcessing(Parameters, QueryResult.UnloadColumn("Ref"));

EndProcedure

// Version update handler for v.<?>:
// - Adds entries to information register DeduplicatedFilesStorageInformation
// for the used BinaryDataStorage catalog items.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export

	BinaryDataStores = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.BinaryDataStorage");

	If BinaryDataStores.Count() > 0 Then

		RegisterMetadata		= Metadata.InformationRegisters.InformationAboutStoringDeduplicatedFiles;
		RegisterPresentation	= RegisterMetadata.Presentation();		
		ProcedureName			= RegisterMetadata.FullName() + "." + "ProcessDataForMigrationToNewVersion";

		ObjectsProcessed = 0;
		ObjectsWithIssuesCount = 0;

		While BinaryDataStores.Next() Do

			DataLock = New DataLock;
			DataLockItem = DataLock.Add("InformationRegister.InformationAboutStoringDeduplicatedFiles");
			DataLockItem.SetValue("BinaryDataStorage", BinaryDataStores.Ref);
			DataLockItem.SetValue("TypeOfFileStorage"		, Enums.TypesOfFileStorage.OperationalStorage);

			RecordingParametersVIB = WorkingWithServerFileArchive.ParametersOfEntryInInformationDatabase();
			RecordingParametersVIB.FileStorageType = Enums.FileStorageTypes.InInfobase;			

			BeginTransaction();
			Try		

				DataLock.Lock();		

				AddRecord(BinaryDataStores.Ref, RecordingParametersVIB);

				InfobaseUpdate.MarkProcessingCompletion(BinaryDataStores.Ref);
				ObjectsProcessed = ObjectsProcessed + 1;
				CommitTransaction();
				
			Except

				RollbackTransaction();

				ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;

				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Couldn''t add an entry to the ""Deduplicated file storage information"" information register
					|for the ""Binary data storage"" catalog item %1 due to:
					|%2'"), 
					BinaryDataStores.Ref, ErrorProcessing.DetailErrorDescription(ErrorInfo()));

				InfobaseUpdate.WriteErrorToEventLog(
					RegisterMetadata,
					RegisterPresentation,
					MessageText);

			EndTry;
		EndDo;

		If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Couldn''t process (skipped) some items of the ""Binary data storage"" catalog: %1'"), 
				ObjectsWithIssuesCount);
			Raise MessageText;
		EndIf;

		WriteLogEvent(
			InfobaseUpdate.EventLogEvent(), 
			EventLogLevel.Information, RegisterMetadata, ,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Procedure %1 processed yet another batch of records: %2.'"),
				ProcedureName,
				ObjectsProcessed));
	EndIf;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.BinaryDataStorage");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf