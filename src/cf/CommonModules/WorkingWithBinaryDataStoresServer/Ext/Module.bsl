///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Configures the set of stored data items for the attributes of catalog BinaryDataStorage and information register BinaryDataStorageLocations, 
//  used for storing file binary data.
//
// Parameters:
//  AttributesForFileStorage - Array - Names of the BinaryDataStorage catalog attributes being processed.
//											See WorkingWithServerFileArchive.FileStorageAttributesNamesByStorageMethod.
//
Procedure ConfigureCompositionOfStoredDataForAttributes_(Val AttributesForFileStorage) Export

	If AttributesForFileStorage.Count() = 0 Then
		Return;
	EndIf;

	If Not WorkingWithServerFileArchive.BinaryDataStoresAreAvailable() Then
		Return;
	EndIf;

	FilesStorageMethod = WorkingWithServerFileArchive.FilesStorageMethod();
	If FilesStorageMethod = "InVolumesOnHardDrive" Then
		Return;
	EndIf;	

	InitialStateOfMonopolyRegime = ExclusiveMode();

	SetExclusiveModeForChangingCompositionOfStoredData(InitialStateOfMonopolyRegime);

	For Each ProcessedAttributes In AttributesForFileStorage Do
		// @skip-check query-in-loop - 
		ConfigureCompositionOfStoredDataForAttributes(ProcessedAttributes);
	EndDo;

	If InitialStateOfMonopolyRegime <> ExclusiveMode() Then
		SetExclusiveMode(False);
	EndIf;

EndProcedure

// Verifies that no binary data storages are connected.
//
// Returns:
//  Boolean
//
Function ThereAreNoBinaryDataStores() Export

	Return Not BinaryDataStorage.GetBinaryDataStorageAvailability() And BinaryDataExternalStorages.Count() = 0;

EndFunction

// Checks whether it is necessary to configure the stored data structure for connected binary data storages.
//
// Parameters:
//  AttributeName			- String - Name of the file binary data storage attribute. 
//									   The term "attribute" refers to the following metadata object properties:
//                    * BinaryData - Attribute of the BinaryDataStorage catalog.
//                    * BinaryDataInArchive								- Resource of information register BinaryDataStorageLocations.
//                    * BinaryDataInOperationalBuiltInStorage	- Resource of information register BinaryDataStorageLocations.
//                    * BinaryDataInOperationalExternalStorage		- Resource of information register BinaryDataStorageLocations.
//  FilesStorageMethod	- String - Refer to Constant.FilesStorageMethod.
//
// Returns:
//  Boolean
//
Function YouNeedToConfigureCompositionOfStoredDataForAttributes(AttributeName, FilesStorageMethod = "") Export

	Result = False;

	MetadataObject = MetadataObjectForFileStorageAttributes(AttributeName);	

	If AttributeName = "BinaryData" Then

		Result = Not StorageCompositionIsConfiguredForAttributes(AttributeName, , MetadataObject);

	ElsIf AttributeName = "BinaryDataInArchive" Then

		If WorkingWithServerFileArchive.UseFileArchive() Then

			NameOfExternalStorageOfFileArchive = NameOfExternalStorageOfFileStorageVolume(Enums.TypesOfFileStorage.ArchivalStorage);

			If Not IsBlankString(NameOfExternalStorageOfFileArchive) 
				And Not ThereIsErrorInSettingsOfBinaryDataStore(AttributeName, NameOfExternalStorageOfFileArchive) Then

				Result = Not StorageCompositionIsConfiguredForAttributes(AttributeName, NameOfExternalStorageOfFileArchive, MetadataObject);
            EndIf;
		EndIf;
	Else

		If Not ValueIsFilled(FilesStorageMethod) Then
			FilesStorageMethod = WorkingWithServerFileArchive.FilesStorageMethod();
		EndIf;

		If AttributeName = "BinaryDataInOperationalBuiltInStorage" 
				And (FilesStorageMethod = "InInfobaseAndVolumesOnHardDrive" Or FilesStorageMethod = "InBuiltInBinaryDataStorage") Then

			VolumeOfOperationalStorage = StorageVolumeThatPlacesDataInBuiltInStorage();
			If VolumeOfOperationalStorage <> Undefined 			
					And Not ThereIsErrorInSettingsOfBinaryDataStore(AttributeName) Then

				Result = Not StorageCompositionIsConfiguredForAttributes(AttributeName, , MetadataObject);

			EndIf;

		ElsIf AttributeName = "BinaryDataInOperationalExternalStorage"
				And (FilesStorageMethod = "InInfobaseAndVolumesOnHardDrive" Or FilesStorageMethod = "InExternalBinaryDataStorage") Then

			NameOfExternalOnlineStorage = NameOfExternalStorageOfFileStorageVolume(Enums.TypesOfFileStorage.OperationalStorage);

			If Not IsBlankString(NameOfExternalOnlineStorage)
				And Not ThereIsErrorInSettingsOfBinaryDataStore(AttributeName, NameOfExternalOnlineStorage) Then

				Result = Not StorageCompositionIsConfiguredForAttributes(AttributeName, NameOfExternalOnlineStorage, MetadataObject);
			EndIf;
		EndIf;
	EndIf;

	Return Result;

EndFunction

#EndRegion

#Region Private

#Region BackupOfBuiltInBinaryDataStorage

// Method of sheduled job BackupOfBuiltInBinaryDataStorage.
//
Procedure BackupOfBuiltInBinaryDataStorage() Export

	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.BackupOfBuiltInBinaryDataStorage);

	If Not WorkingWithServerFileArchive.BinaryDataStoresAreAvailable() Then
		Return;
	EndIf;

	If BackgroundTaskOfCreatingBackupCopyOfHDDIsRunning() Then
		Return;
	EndIf;
	
	NewBackupCopyOfBuiltInHDD();

EndProcedure

Function BackgroundTaskOfCreatingBackupCopyOfHDDIsRunning()

	ScheduledJob = Metadata.ScheduledJobs.BackupOfBuiltInBinaryDataStorage;

	Filter = New Structure;
	Filter.Insert("MethodName", ScheduledJob.MethodName);
	Filter.Insert("State", BackgroundJobState.Active);
	CurrentBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	
	If CurrentBackgroundJobs.Count() = 1 Then
		BackgroundTaskOfCurrentSession = GetCurrentInfoBaseSession().GetBackgroundJob();
		Result = BackgroundTaskOfCurrentSession = Undefined;
		If Not Result Then
			Result = BackgroundTaskOfCurrentSession.UUID <> CurrentBackgroundJobs[0].UUID;
		EndIf;
	Else
		Result = CurrentBackgroundJobs.Count() > 0;
	EndIf;

	Return Result;
	
EndFunction

Procedure NewBackupCopyOfBuiltInHDD()

	SetPrivilegedMode(True);

	WriteToLogOfHDBackupEventRegistration(
												NStr("en = 'Scheduled backing up of internal binary data storage started.'",
												Common.DefaultLanguageCode()));

	EventLogComment = "";
	BackupStorageDirectory = VerifiedDirectoryForStoringBackupFilesOfBuiltInHDD(EventLogComment);

	If Not ValueIsFilled(BackupStorageDirectory) Then

			WriteToLogOfHDBackupEventRegistration(EventLogComment, EventLogLevel.Error);

		Return;
	EndIf;

	FileNameOfNewBackup = "";
	TypeOfBackup = Enums.TypesOfBackupsOfBuiltInBinaryDataStorage.EmptyRef();

	FullBackupFileName = FileNameOfLastFullBackup();
	If ValueIsFilled(FullBackupFileName) Then
		PathToFullBackupFile = BackupStorageDirectory + FullBackupFileName;
		If FileExists(PathToFullBackupFile) Then
			FileNameOfNewBackup = NewBackupFileName();
			FilePathOfNewDifferentialCopy = BackupStorageDirectory + FileNameOfNewBackup;

			Try
				BinaryDataStorage.CreateDifferentialBackup(FilePathOfNewDifferentialCopy, PathToFullBackupFile);
			Except
				
				ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				
				WriteToLogOfHDBackupEventRegistration(ErrorDescription, EventLogLevel.Error);
				Return;
															
			EndTry;
			
			TypeOfBackup = Enums.TypesOfBackupsOfBuiltInBinaryDataStorage.Differential;
		EndIf;
	EndIf;

	If FileNameOfNewBackup = "" Then
		FileNameOfNewBackup = NewBackupFileName(True);
		PathToFileOfNewFullBackup = BackupStorageDirectory + FileNameOfNewBackup;

		Try
			BinaryDataStorage.CreateFullBackup(PathToFileOfNewFullBackup);
		Except
			
			ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			WriteToLogOfHDBackupEventRegistration(ErrorDescription, EventLogLevel.Error);
			Return;
														
		EndTry;		

		TypeOfBackup = Enums.TypesOfBackupsOfBuiltInBinaryDataStorage.Full;
	EndIf;

	InformationRegisters.BackupHistoryOfBuiltInBinaryDataStorage.AddRecord(TypeOfBackup, CurrentSessionDate(), FileNameOfNewBackup);
	
	WriteToLogOfHDBackupEventRegistration(
												NStr("en = 'Scheduled backing up of internal binary data storage completed.'",
												Common.DefaultLanguageCode()));

EndProcedure
											
Function VerifiedDirectoryForStoringBackupFilesOfBuiltInHDD(ErrorDescription = "")

	Result = DirectoryForStoringBackupFilesOfBuiltInHDD();
	
	If Not ValueIsFilled(Result) Then
		ErrorDescription = NStr("en = 'Constant is required: Backup directory for the built-in binary data storage'");
	Else
		Result = CommonClientServer.AddLastPathSeparator(Result);

		If Not FileExists(Result) Then

			MessageTemplate = NStr("en = 'Directory specified for storing backups of internal binary data storage does not exist
									|%1'");
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, Result);

			Result = "";
		EndIf;		
	EndIf;

	Return Result;

EndFunction

Function FileNameOfLastFullBackup()

	Query = New Query;
	Query.Text = 
		"SELECT
		|	BackupHistoryOfBuiltInBinaryDataStorage.BackupFileName AS BackupFileName
		|FROM
		|	(SELECT
		|		BackupHistoryOfBuiltInBinaryDataStorage.TypeOfBackup AS TypeOfBackup,
		|		MAX(BackupHistoryOfBuiltInBinaryDataStorage.CreationDate) AS CreationDate
		|	FROM
		|		InformationRegister.BackupHistoryOfBuiltInBinaryDataStorage AS BackupHistoryOfBuiltInBinaryDataStorage
		|	WHERE
		|		BackupHistoryOfBuiltInBinaryDataStorage.TypeOfBackup = &TypeOfBackup
		|		AND BackupHistoryOfBuiltInBinaryDataStorage.CreationDate <= &CreationDate
		|	
		|	GROUP BY
		|		BackupHistoryOfBuiltInBinaryDataStorage.TypeOfBackup) AS DateOfLastFullBackup
		|		INNER JOIN InformationRegister.BackupHistoryOfBuiltInBinaryDataStorage AS BackupHistoryOfBuiltInBinaryDataStorage
		|		ON DateOfLastFullBackup.TypeOfBackup = BackupHistoryOfBuiltInBinaryDataStorage.TypeOfBackup
		|			AND DateOfLastFullBackup.CreationDate = BackupHistoryOfBuiltInBinaryDataStorage.CreationDate";

	Query.SetParameter("TypeOfBackup", Enums.TypesOfBackupsOfBuiltInBinaryDataStorage.Full);
	Query.SetParameter("CreationDate", CurrentSessionDate());

	DataSelection = Query.Execute().Select();
	If DataSelection.Next() Then
		Result = TrimAll(DataSelection.BackupFileName);
	Else
		Result = "";
	EndIf;

	Return Result;

EndFunction

Function FileExists(PathToFile)

	Result = Not IsBlankString(PathToFile);

	If Result Then
		File = New File(PathToFile);
		Result = File.Exists();
	EndIf;

	Return Result;

EndFunction

Function NewBackupFileName(ThisIsCompleteCopy = False)

	BackupType = ?(ThisIsCompleteCopy, "Full", "Differential");
	CopyCreationDate = Format(CurrentSessionDate(), "DF=ddMMyyyy_HHmmss");

	Return StringFunctionsClientServer.SubstituteParametersToString("%1_%2.sbd", BackupType, CopyCreationDate);

EndFunction

Procedure WriteToLogOfHDBackupEventRegistration(Val MessageText, Val Level = Undefined)

	If Level = Undefined Then
		Level = EventLogLevel.Information;
	EndIf;

	WriteLogEvent(EventOfLogOfRegistrationOfBackupOfBuiltInHDD(), Level,,, MessageText);

EndProcedure

Function EventOfLogOfRegistrationOfBackupOfBuiltInHDD()
	
	Return NStr("en = 'Backing up internal binary data storage'", Common.DefaultLanguageCode());
	
EndFunction

Function DirectoryForStoringBackupFilesOfBuiltInHDD()

	SetPrivilegedMode(True);

	If Common.IsWindowsServer() Then

		Result = Constants.DirectoryOfBackupsOfBuiltInBinaryDataStorageForWindows.Get();

	Else

		Result = Constants.DirectoryOfBackupsOfBuiltInBinaryDataStorageForLinux.Get();

	EndIf;

	Return Result;

EndFunction

#EndRegion

#Region ConfiguringCompositionOfStoredData

// Updates the stored data structure for the binary data storage assigned to the file storage volume.
//
// Parameters:
//  TypeOfFileStorageVolume		- EnumRef.TypesOfFileStorage
//  FilesStorageMethod		- EnumRef.WaysToStoreFiles
//  NameOfBinaryDataStore	- String - Used only for file storage option InExternalStorageUsingS3Protocol
//
Procedure ChangeCompositionOfStoredData(TypeOfFileStorageVolume, FilesStorageMethod, NameOfBinaryDataStore) Export

	If Not ValueIsFilled(FilesStorageMethod) Or FilesStorageMethod = Enums.WaysToStoreFiles.InNetworkDirectories Then
		Return;		
	EndIf;

	SetPrivilegedMode(True);

	ErrorDescriptionText = "";
	
	If TypeOfFileStorageVolume = Enums.TypesOfFileStorage.ArchivalStorage Then
		NameOfStorageAttribute = "BinaryDataInArchive";
	Else
		NameOfStorageAttribute = WorkingWithServerFileArchive.NameOfBinaryDataStorageAttributeForVolumeStorageMethod(FilesStorageMethod);
	EndIf;

	If ThereIsErrorInSettingsOfBinaryDataStore(NameOfStorageAttribute, NameOfBinaryDataStore, ErrorDescriptionText) Then
		Raise ErrorDescriptionText;
	EndIf;

	MetadataObjectOfStorageAttribute = Undefined;

	If Not StorageCompositionIsConfiguredForAttributes(NameOfStorageAttribute, NameOfBinaryDataStore, MetadataObjectOfStorageAttribute) Then

		InitialStateOfMonopolyRegime = ExclusiveMode();

		SetExclusiveModeForChangingCompositionOfStoredData(InitialStateOfMonopolyRegime);

		ConfigureCompositionOfStoredDataForAttributes(NameOfStorageAttribute, MetadataObjectOfStorageAttribute, NameOfBinaryDataStore);

		If InitialStateOfMonopolyRegime <> ExclusiveMode() Then
			SetExclusiveMode(False);
		EndIf;
	EndIf;

EndProcedure

Function TypeOfFileStorageByAttributeName(AttributeName)

	If AttributeName = "BinaryDataInArchive" Then
		Result = Enums.TypesOfFileStorage.ArchivalStorage;
	Else
		Result = Enums.TypesOfFileStorage.OperationalStorage;
	EndIf;

	Return Result;
	
EndFunction

Function StorageCompositionIsConfiguredForAttributes(AttributeName, NameOfExternalBinaryDataStore = "", MetadataObject = Undefined)

	Result = False;

	MetadataObject = MetadataObjectForFileStorageAttributes(AttributeName, MetadataObject);

	If AttributeName = "BinaryDataInArchive" Or AttributeName = "BinaryDataInOperationalExternalStorage" Then
		
		If Not ValueIsFilled(NameOfExternalBinaryDataStore) Then
			NameOfExternalBinaryDataStore = NameOfExternalStorageOfFileStorageVolume(TypeOfFileStorageByAttributeName(AttributeName));
		EndIf;

		If ValueIsFilled(NameOfExternalBinaryDataStore) Then
			ExternalBinaryDataStorage = BinaryDataExternalStorages.Find(NameOfExternalBinaryDataStore);

			If ExternalBinaryDataStorage <> Undefined Then
				CompositionOfStoredStorageData = ExternalBinaryDataStorage.StoredDataContent;
				ElementOfCompositionOfStoredData = CompositionOfStoredStorageData.Find(MetadataObject);

				If ElementOfCompositionOfStoredData <> Undefined 
						And ElementOfCompositionOfStoredData.Location = UsingSafeModeStorage("Use") Then

					Result = True;
				EndIf;
			EndIf;
		EndIf

	ElsIf AttributeName = "BinaryDataInOperationalBuiltInStorage" Then

		Result = AttributeIsUsedAsPartOfStoredDataOfBuiltInStorage(AttributeName, MetadataObject);

	ElsIf AttributeName = "BinaryData" Then

		Result = UseOfAttributesIsExplicitlyDisabledInAllBinaryDataStores(AttributeName, MetadataObject);

	EndIf;

	Return Result;

EndFunction

Procedure SetExclusiveModeForChangingCompositionOfStoredData(CurrentStateOfMonopolyRegime)

	If Not CurrentStateOfMonopolyRegime Then

		Try
			SetExclusiveMode(True);
		Except

			ErrorTemplate = NStr("en = 'Failed to set exclusive mode for configuring
										|attributes used in binary data storages:
										|%1'");

			ErrorInfo	= ErrorInfo();
			ErrorDescriptionText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, ErrorProcessing.BriefErrorDescription(ErrorInfo));			

			Raise ErrorDescriptionText;

		EndTry;
	EndIf;	
	
EndProcedure

Procedure ConfigureCompositionOfStoredDataForAttributes(AttributeName, MetadataObject = Undefined, NameOfExternalStorage = "")

	AttributeMetadataObject = MetadataObjectForFileStorageAttributes(AttributeName, MetadataObject);

	If AttributeName = "BinaryData" Then

		Location = UsingSafeModeStorage("DontUse");

		StoredDataContent = Undefined;
		// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
		Execute("StoredDataContent = BinaryDataStorage.GetStoredDataContent()");
		// ACC:487-on

		If SetElementOfCompositionOfStoredDataForAttribute(StoredDataContent, AttributeMetadataObject, Location) Then

			// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
			Execute("BinaryDataStorage.SetStoredDataContent(StoredDataContent)");
			// ACC:487-on			
		EndIf;

		For Each ExternalStorage In BinaryDataExternalStorages Do
			If SetElementOfCompositionOfStoredDataForAttribute(ExternalStorage.StoredDataContent, AttributeMetadataObject, Location) Then
				ExternalStorage.Write();
			EndIf;
		EndDo;
	ElsIf AttributeName = "BinaryDataInArchive" Or AttributeName = "BinaryDataInOperationalExternalStorage" Then

		NameOfExternalStorage = NameOfExternalStorageOfFileStorageVolume(TypeOfFileStorageByAttributeName(AttributeName), NameOfExternalStorage);

		NamesOfExcludedRepositories = NamesOfExcludedRepositories(NameOfExternalStorage);

		RemoveAttributesFromStoredDataOfAllRepositories(AttributeName, NamesOfExcludedRepositories, AttributeMetadataObject);

		If Not IsBlankString(NameOfExternalStorage) Then

			ExternalStorage = BinaryDataExternalStorages.Find(NameOfExternalStorage);
			If ExternalStorage <> Undefined Then
			
				Location = UsingSafeModeStorage("Use");

				If SetElementOfCompositionOfStoredDataForAttribute(ExternalStorage.StoredDataContent, AttributeMetadataObject, Location) Then
					ExternalStorage.Write();
				EndIf;
			EndIf;
		EndIf;
		
	ElsIf AttributeName = "BinaryDataInOperationalBuiltInStorage" Then

		NamesOfExcludedRepositories = NamesOfExcludedRepositories("BuiltInStorage");

		RemoveAttributesFromStoredDataOfAllRepositories(AttributeName, NamesOfExcludedRepositories);

		Location = UsingSafeModeStorage("Use");

		StoredDataContent = Undefined;
		// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
		Execute("StoredDataContent = BinaryDataStorage.GetStoredDataContent()");
		// ACC:487-on		
		If SetElementOfCompositionOfStoredDataForAttribute(StoredDataContent, AttributeMetadataObject, Location) Then
			// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
			Execute("BinaryDataStorage.SetStoredDataContent(StoredDataContent)");
			// ACC:487-on
		EndIf;
	EndIf;

EndProcedure

Procedure RemoveAttributesFromStoredDataOfAllRepositories(AttributeName, NamesOfExcludedRepositories = Undefined, MetadataObject = Undefined)

	AttributeMetadataObject = MetadataObjectForFileStorageAttributes(AttributeName, MetadataObject);

	If Not(NamesOfExcludedRepositories <> Undefined And NamesOfExcludedRepositories.Find("BuiltInStorage") <> Undefined) Then

		StoredDataContent = Undefined;
		// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
		Execute("StoredDataContent = BinaryDataStorage.GetStoredDataContent()");
		// ACC:487-on		
		If RemoveAttributesFromStoredData(StoredDataContent, AttributeMetadataObject) Then
			// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
			Execute("BinaryDataStorage.SetStoredDataContent(StoredDataContent)");
			// ACC:487-on			
		EndIf;
	EndIf;

	For Each ExternalStorage In BinaryDataExternalStorages Do

		If NamesOfExcludedRepositories <> Undefined And NamesOfExcludedRepositories.Find(ExternalStorage.Name) <> Undefined Then
			Continue;
		EndIf;

		If RemoveAttributesFromStoredData(ExternalStorage.StoredDataContent, AttributeMetadataObject) Then
			ExternalStorage.Write();
		EndIf;
	EndDo

EndProcedure

Function RemoveAttributesFromStoredData(StoredDataContent, MetadataObject)

	Result = False;

	ElementOfCompositionOfStoredData = StoredDataContent.Find(MetadataObject);
	If ElementOfCompositionOfStoredData <> Undefined Then
		StoredDataContent.Delete(ElementOfCompositionOfStoredData);
		Result = True;
	EndIf;

	Return Result;

EndFunction

Function UseOfAttributesIsExplicitlyDisabledInAllBinaryDataStores(AttributeName, MetadataObject = Undefined)

	Result = ThereAreNoBinaryDataStores();

	If Not Result Then

		DisabledInBuiltInStorage = Not BinaryDataStorage.GetBinaryDataStorageAvailability();

		If Not DisabledInBuiltInStorage Then

			CompositionOfStoredStorageData = Undefined;
			// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
			Execute("CompositionOfStoredStorageData = BinaryDataStorage.GetStoredDataContent()");
			// ACC:487-on

			MetadataObjectValue = MetadataObjectForFileStorageAttributes(AttributeName, MetadataObject);
			ElementOfCompositionOfStoredData = CompositionOfStoredStorageData.Find(MetadataObjectValue);

			If ElementOfCompositionOfStoredData <> Undefined Then
				DisabledInBuiltInStorage = ElementOfCompositionOfStoredData.Location = UsingSafeModeStorage("DontUse");
			EndIf;
		EndIf;

		DisabledInExternalStorage = BinaryDataExternalStorages.Count() = 0;

		If Not DisabledInExternalStorage Then

			DisabledInExternalStorage = True;

	        MetadataObjectValue = MetadataObjectForFileStorageAttributes(AttributeName, MetadataObject);

			For Each ExternalStorage In BinaryDataExternalStorages Do
				CompositionOfStoredStorageData = ExternalStorage.StoredDataContent;
				ElementOfCompositionOfStoredData = CompositionOfStoredStorageData.Find(MetadataObjectValue);

				If ElementOfCompositionOfStoredData = Undefined 
						Or ElementOfCompositionOfStoredData.Location = UsingSafeModeStorage("Use") Then

					DisabledInExternalStorage = False;
					Break
				EndIf;
			EndDo;
		EndIf;
		
		Result = DisabledInBuiltInStorage And DisabledInExternalStorage;
	EndIf;

	Return Result;

EndFunction

Function AttributeIsUsedAsPartOfStoredDataOfBuiltInStorage(AttributeName, MetadataObject = Undefined)

	Result = False;	

	If BinaryDataStorage.GetBinaryDataStorageAvailability() Then

		CompositionOfStoredStorageData = Undefined;
		// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
		Execute("CompositionOfStoredStorageData = BinaryDataStorage.GetStoredDataContent()");
		// ACC:487-on

		MetadataObjectValue = MetadataObjectForFileStorageAttributes(AttributeName, MetadataObject);
		ElementOfCompositionOfStoredData = CompositionOfStoredStorageData.Find(MetadataObjectValue);

		If ElementOfCompositionOfStoredData <> Undefined Then
			Result = ElementOfCompositionOfStoredData.Location = UsingSafeModeStorage("Use");
		EndIf;
	EndIf;

	Return Result;

EndFunction

Function NameOfExternalStorageOfFileStorageVolume(TypeOfFileStorageVolume, NameOfExternalStorage = "")

	If ValueIsFilled(NameOfExternalStorage) Then

		Result = NameOfExternalStorage;

	Else

		Result = "";

		Query = New Query;
		Query.Text = 
		"SELECT
		|	FileStorageVolumes.NameOfBinaryDataStore AS NameOfBinaryDataStore
		|FROM
		|	Catalog.FileStorageVolumes AS FileStorageVolumes
		|WHERE
		|	NOT FileStorageVolumes.DeletionMark
		|	AND FileStorageVolumes.TypeOfFileStorageVolume = &TypeOfFileStorageVolume
		|	AND FileStorageVolumes.FilesStorageMethod = VALUE(Enum.WaysToStoreFiles.InExternalStorageUsingS3Protocol)";

		Query.SetParameter("TypeOfFileStorageVolume", TypeOfFileStorageVolume);

		DataSelection = Query.Execute().Select();
		If DataSelection.Next() Then
			Result = DataSelection.NameOfBinaryDataStore;
		EndIf;		
	EndIf;

	Return Result;

EndFunction

Function ThereIsErrorInSettingsOfBinaryDataStore(AttributeName, Val NameOfExternalStorage = "", ErrorDescription = "")

	Result = False;

	If AttributeName = "BinaryDataInArchive" Or AttributeName = "BinaryDataInOperationalExternalStorage" Then

		Result = BinaryDataExternalStorages.Count() = 0;

		If Result Then
			ErrorDescription = NStr("en = 'No external binary data storages are connected'");
		EndIf;

		If Not Result Then

			TypeOfStorageVolume = TypeOfFileStorageByAttributeName(AttributeName);

			NameOfExternalStorage = NameOfExternalStorageOfFileStorageVolume(TypeOfStorageVolume, NameOfExternalStorage);

			Result = IsBlankString(NameOfExternalStorage);

			If Result Then
				ErrorDescription = NStr("en = 'Couldn''t  determine name of external binary data storage'");
			EndIf;

			If Not Result Then
				ExternalBinaryDataStorage = BinaryDataExternalStorages.Find(NameOfExternalStorage);

				Result = ExternalBinaryDataStorage = Undefined;

				If Result Then
					ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
												NStr("en = 'External binary data storage not found: %1'"),
												NameOfExternalStorage);
				EndIf;

				If Not Result Then
					Result = ExternalBinaryDataStorage.ReadWriteMode = BinaryDataStorageReadWriteMode.ReadOnly;

					If Result Then
						ErrorDescription = TextOfErrorThatCannotBeWrittenToBinaryDataStore();
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	ElsIf AttributeName = "BinaryDataInOperationalBuiltInStorage" Then

		HDDUsageMode = BinaryDataStorage.GetBinaryDataStorageUseMode();
		Result = HDDUsageMode <> BinaryDataStorageUseMode.Enable;

		If Result Then
			ErrorDescription = NStr("en = 'Internal binary data storage unavailable'");
		EndIf;

		If Not Result Then
			Result = BinaryDataStorage.GetBinaryDataStorageReadWriteMode() = BinaryDataStorageReadWriteMode.ReadOnly;
			If Result Then
				ErrorDescription = TextOfErrorThatCannotBeWrittenToBinaryDataStore(False);
			EndIf;
		EndIf;
	EndIf;

	Return Result;

EndFunction

Function TextOfErrorThatCannotBeWrittenToBinaryDataStore(ExternalStorage = True)
	
	If ExternalStorage Then
		Result = NStr("en = 'External data storage is read-only.
							|Write permission is disabled in the storage settings.'");

	Else
		Result = NStr("en = 'Internal data storage is read-only.
							|Write permission is disabled in the storage settings.'");		
	EndIf;
	
	Return Result;
	
EndFunction

Function SetElementOfCompositionOfStoredDataForAttribute(StoredDataContent, MetadataObject, Location)

	ElementOfCompositionOfStoredData = StoredDataContent.Find(MetadataObject);

	If ElementOfCompositionOfStoredData <> Undefined Then
		If ElementOfCompositionOfStoredData.Location = Location Then
			Return False;
		Else
			StoredDataContent.Delete(ElementOfCompositionOfStoredData);
		EndIf;
	EndIf;

	StoredDataContent.Add(MetadataObject, Location);

	Return True;

EndFunction

Function NamesOfExcludedRepositories(StorageNames = "")

	Result = Undefined;

	If Not IsBlankString(StorageNames) Then
		Result = StrSplit(StorageNames, ",", False);
	EndIf;

	Return Result;

EndFunction

Function StorageVolumeThatPlacesDataInBuiltInStorage()

	Result = Undefined;

	Query = New Query;
	Query.Text = 
	"SELECT
	|	FileStorageVolumes.Ref AS VolumeOfOperationalStorage
	|FROM
	|	Catalog.FileStorageVolumes AS FileStorageVolumes
	|WHERE
	|	NOT FileStorageVolumes.DeletionMark
	|	AND FileStorageVolumes.TypeOfFileStorageVolume = VALUE(Enum.TypesOfFileStorage.OperationalStorage)
	|	AND FileStorageVolumes.FilesStorageMethod = VALUE(Enum.WaysToStoreFiles.InBuiltInStorage)";

	DataSelection = Query.Execute().Select();
	If DataSelection.Next() Then
		Result = DataSelection.VolumeOfOperationalStorage;
	EndIf;

	Return Result;

EndFunction

Function MetadataObjectForFileStorageAttributes(AttributeName, MetadataObject = Undefined)

	Result = MetadataObject;
	If MetadataObject = Undefined Then
		If AttributeName = "BinaryData" Then
			Result = Metadata.Catalogs.BinaryDataStorage.Attributes[AttributeName];
		Else
			Result = Metadata.InformationRegisters.BinaryDataStorageLocations.Resources[AttributeName];
		EndIf;
	EndIf;

	Return Result;

EndFunction

Function UsingSafeModeStorage(Location)

	BRParameters = New Structure;
	BRParameters.Insert("Location", Undefined);
	
	If WorkingWithServerFileArchive.ChangesInFileStorageMethodsAreAvailable() Then

		If Location = "Use" Then
			Algorithm = "Parameters.Location = BinaryDataStorageLocationUse.Use";
		ElsIf Location = "DontUse" Then
			Algorithm = "Parameters.Location = BinaryDataStorageLocationUse.DontUse";
		EndIf;

		Try
			Common.ExecuteInSafeMode(Algorithm, BRParameters);	
		Except
			ErrorInfo = ErrorInfo();
		EndTry;

	EndIf;

	Return BRParameters.Location;

EndFunction

#EndRegion

// See StandardSubsystemsServer.WhenDefiningMethodsThatAreAllowedToBeCalledAsArbitraryCode
Procedure WhenDefiningMethodsThatAreAllowedToBeCalledAsArbitraryCode(Methods) Export
	
	Methods.Insert("BackupOfBuiltInBinaryDataStorage", True);
	
EndProcedure

#EndRegion