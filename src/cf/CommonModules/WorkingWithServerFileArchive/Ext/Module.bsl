///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns file binary data extracted from the ZIP archive.
//
// Parameters:
//  BinaryZipArchiveData	- BinaryData - Binary file data.
//  AttachedFile		- DefinedType.AttachedFile - a reference to the catalog item with file.
//
// Returns:
//  - BinaryData
//  - Undefined
//
Function BinaryDataOfFileExtractedFromZipArchive(BinaryZipArchiveData, AttachedFile) Export

	Result = Undefined;

	If TypeOf(BinaryZipArchiveData) = Type("BinaryData") Then

		ErrorDescription = NStr("en = 'Error extracting file from ZIP archive'");
		
		TempDirectory = NewTemporaryDirectoryForWorkingWithZipArchive(ErrorDescription);

		Try
			AttributesValues = Common.ObjectAttributesValues(AttachedFile, "Description,Extension");

			NameOfExtractedFile = CommonClientServer.GetNameWithExtension(AttributesValues.Description, AttributesValues.Extension);

			DataOfExtractedFile = ExtractFileFromZipArchive(BinaryZipArchiveData, NameOfExtractedFile, TempDirectory);

			Result = New BinaryData(DataOfExtractedFile.FileName);

			DeleteTemporaryDirectoryForWorkingWithZipArchive(TempDirectory);

		Except

			DeleteTemporaryDirectoryForWorkingWithZipArchive(TempDirectory);

		    ErrorInfo = ErrorInfo();
		    Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, ErrorDescription);

		    Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);			
		EndTry;
	EndIf;

	Return Result;

EndFunction

// Checks if storing files in binary storage is available.
// SSL supports binary storage starting from 1C:Enterprise v. 8.3.26.1000.
// File infobases don't support binary storage.
// Distributed infobases don't support binary storage.
//
// Returns:
//  Boolean
//
Function BinaryDataStoresAreAvailable() Export	

	Result = Not Common.FileInfobase();

	If Result Then
		Result = Not Common.IsDistributedInfobase()
	EndIf;	

	If Result Then
		Result = ChangesInFileStorageMethodsAreAvailable();
	EndIf;

	Return Result;

EndFunction

// Retrieves the minimum 1C:Enterprise version with updated file storage options.
//	Now, files can be stored in binary storage. Old storage methods were renamed.
// 
// Returns:
//  Boolean
//
Function ChangesInFileStorageMethodsAreAvailable() Export

	Result = True;	

	Info = New SystemInfo;
	MinVersion = MinimumRequiredVersionOfPlatformForWorkingWithBinaryDataStores();

	If CommonClientServer.CompareVersions(
		Info.AppVersion, MinVersion) < 0 Then
		Result = False;
	EndIf;	
	
	Return Result;

EndFunction

// Checks if the application supports file archives.
// Only CORP applications support file archives.
// File infobases don't support file archives.
// Distributed infobases don't support file archives.
//
// Returns:
//  Boolean
//
Function FileArchiveIsAvailable() Export

	Result = FilesOperationsInternal.FilesSettings().FileArchiveIsAvailable;

	If Result Then
		Result = Not Common.FileInfobase();
	EndIf;

	If Result Then
		Result = Not Common.IsDistributedInfobase()
	EndIf;

	Return Result;

EndFunction

// Returns the storage option in storage volumes matching the specified file storage option.
//
// Parameters:
//  FileStorageMethod - String - Refer to Constant.FilesStorageMethod.
//
// Returns:
//  - EnumRef.WaysToStoreFiles	- In case the passed storage method is InInfobaseAndVolumesOnDisk.
//  - String									- In case the passed storage method is InInfobaseAndVolumesOnDisk.
//
Function StorageMethodForSelectingStorageVolumes(Val FileStorageMethod = "") Export

	If Not ValueIsFilled(FileStorageMethod) Then
		FileStorageMethod = FilesStorageMethod();
	EndIf;	

	If FileStorageMethod = "InVolumesOnHardDrive" Then
		Result = Enums.WaysToStoreFiles.InNetworkDirectories;
	ElsIf FileStorageMethod = "InBuiltInBinaryDataStorage" Then
		Result = Enums.WaysToStoreFiles.InBuiltInStorage;
	ElsIf FileStorageMethod = "InExternalBinaryDataStorage" Then
		Result = Enums.WaysToStoreFiles.InExternalStorageUsingS3Protocol;
	ElsIf FileStorageMethod = "InInfobaseAndVolumesOnHardDrive" Then
		Result = "InVolumesWithAnyStorageMethod";
	EndIf;

	Return Result;

EndFunction

// Returns an array of attribute names from the BinaryDataStorage catalog
// matching the specified file storage method.
//
// Parameters:
//  FilesStorageMethod - String - Refer to Constant.FilesStorageMethod.
//
// Returns:
//  Array
//
Function FileStorageAttributesNamesByStorageMethod(FilesStorageMethod) Export

	Result = New Array;
	Result.Add("BinaryData");

	If FilesStorageMethod = "InBuiltInBinaryDataStorage" Then

		Result.Add("BinaryDataInOperationalBuiltInStorage");

	ElsIf FilesStorageMethod = "InExternalBinaryDataStorage" Then

		Result.Add("BinaryDataInOperationalExternalStorage");

	ElsIf FilesStorageMethod = "InInfobaseAndVolumesOnHardDrive" Then

		Result.Add("BinaryDataInOperationalBuiltInStorage");
		Result.Add("BinaryDataInOperationalExternalStorage");

	EndIf;

	Return Result;

EndFunction

// Controls the visibility of the ImageNumberIsArchive field on the list form
// based on the use of file archive functionality.
// 
// Parameters:
//   Form - ClientApplicationForm
//
Procedure VisibilityOfListFieldImageNumberIsArchive(FormField) Export

	FormField.Visible = UseFileArchive();

EndProcedure

#Region ConfigurationSubsystemsEventHandlers

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.InitialFilling	= True;
	Handler.SharedData			= True;
	Handler.Version				= "3.1.12.38";
	Handler.Procedure			= "WorkingWithServerFileArchive.InitialFillingOfConstants";
	Handler.ExecutionMode		= "Seamless";
	
	Handler = Handlers.Add();
	Handler.InitialFilling	= True;
	Handler.Version				= "3.1.12.38";
	Handler.Procedure			= "WorkingWithServerFileArchive.InitialFillingInSettingsForWorkingWithFileArchive";
	Handler.ExecutionMode		= "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version				= "3.1.12.38";	
	Handler.Comment			= NStr("en = 'Populating new attributes in the Storage volumes catalog'");
	Handler.SharedData			= True;
	Handler.Procedure			= "Catalogs.FileStorageVolumes.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode		= "Seamless";

	Handler = Handlers.Add();
	Handler.Version				= "3.1.12.38";
	Handler.Comment			= NStr("en = 'Completing missing information on deduplicated file storage.'");
	Handler.Id		= New UUID("c36f86c4-77e8-4fe9-a07e-798d85929cf9");
	Handler.Procedure			= "InformationRegisters.InformationAboutStoringDeduplicatedFiles.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode		= "Deferred";
	Handler.UpdateDataFillingProcedure = "InformationRegisters.InformationAboutStoringDeduplicatedFiles.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure	= "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToRead      = "InformationRegister.FileRepository";
	Handler.ObjectsToChange    = "InformationRegister.InformationAboutStoringDeduplicatedFiles";
	Handler.ObjectsToLock   = "InformationRegister.FileRepository";
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Order	= "Any";

EndProcedure

#EndRegion

#EndRegion

#Region Private

// Populates the list with the available storage options for file storage volumes.
//
// Parameters:
//  ChoiceList			- ValueList - a value list to be filled in.
//  TypeOfFileStorageVolume	- EnumRef.TypesOfFileStorage
//
Procedure FileStorageMethodFillSelectionList(ChoiceList, TypeOfFileStorageVolume) Export

	ChoiceList.Add(Enums.WaysToStoreFiles.InNetworkDirectories);

	If BinaryDataStoresAreAvailable() Then
		ChoiceList.Add(Enums.WaysToStoreFiles.InExternalStorageUsingS3Protocol);
		If TypeOfFileStorageVolume = Enums.TypesOfFileStorage.OperationalStorage Then	
			ChoiceList.Add(Enums.WaysToStoreFiles.InBuiltInStorage);	
		EndIf;
	EndIf;

EndProcedure

// Returns the FilesStorageMethod constant value.
//
// Returns:
//  String - See Constant.FilesStorageMethod
//
Function FilesStorageMethod() Export

	SetPrivilegedMode(True);
	Result = Constants.FilesStorageMethod.Get();

	Return Result;

EndFunction

// Returns the value of constant ShouldUseFileArchive.
//
// Returns:
//  Boolean - See Constant.UseFileArchive
//
Function UseFileArchive() Export

	SetPrivilegedMode(True);
	Result = Constants.UseFileArchive.Get();

	Return Result;

EndFunction

// Returns the value of constant TransferredFilesPortionSize.
//
// Returns:
//  Number - See Constant.PortionSizeOfFilesBeingMoved
//
Function PortionSizeOfFilesBeingMoved()

	SetPrivilegedMode(True);
	Result = Constants.PortionSizeOfFilesBeingMoved.Get();

	If Result = 0 Then
		Result = SizeOfPortionOfFilesBeingMovedIsDefaultValue();
	EndIf;
	
	Return Result;

EndFunction

// Returns the value of constant UserNotificationTextForUnavailableArchivedFile.
//
// Returns:
//  String - See Constant.TextInformingUserAboutUnavailabilityOfFileInArchive
//
Function TextInformingUserAboutUnavailabilityOfFileInArchive() Export

	SetPrivilegedMode(True);
	Result = Constants.TextInformingUserAboutUnavailabilityOfFileInArchive.Get();
	SetPrivilegedMode(False);

	If Not ValueIsFilled(Result) Then
		Result = TextInformingUserAboutUnavailabilityOfFileInArchiveDefaultValue();
	EndIf;

	Return Result;	

EndFunction

// Returns the name of the attribute of the BinaryDataStorage catalog matching the specified volume storage method.
//
// Parameters:
//  FilesStorageMethod - EnumRef. ... - Refer to the FilesStorageMethod attribute of the FileStorageVolumes catalog.
//
// Returns:
//  String
//
Function NameOfBinaryDataStorageAttributeForVolumeStorageMethod(VolumeStorageMethod) Export

	Result = "";

	If VolumeStorageMethod = Enums.WaysToStoreFiles.InBuiltInStorage Then

		Result = "BinaryDataInOperationalBuiltInStorage";

	ElsIf VolumeStorageMethod = Enums.WaysToStoreFiles.InExternalStorageUsingS3Protocol Then

		Result = "BinaryDataInOperationalExternalStorage";

	EndIf;

	Return Result;	

EndFunction

// Returns the storage option matching the specified file storage option.
//
// Parameters:
//  FileStorageMethod - String - Refer to Constant.FilesStorageMethod.
//
// Returns:
//  EnumRef.FileStorageTypes
//
Function FileStorageTypeByStorageMethod(Val FileStorageMethod = "") Export

	If IsBlankString(FileStorageMethod) Then
		FileStorageMethod = FilesStorageMethod();
	EndIf;

	If FileStorageMethod = "InVolumesOnHardDrive" Then
		Result = Enums.FileStorageTypes.InVolumesOnHardDrive;
	ElsIf FileStorageMethod = "InBuiltInBinaryDataStorage" Then
		Result = Enums.FileStorageTypes.InBuiltInBinaryDataStorage;
	ElsIf FileStorageMethod = "InExternalBinaryDataStorage" Then
		Result = Enums.FileStorageTypes.InExternalBinaryDataStorage;
	ElsIf FileStorageMethod = "InInfobaseAndVolumesOnHardDrive" Then
		Result = Enums.FileStorageTypes.InVolumesVolumeIsNotDefined;
	Else
		Result = Enums.FileStorageTypes.InInfobase;
	EndIf;

	Return Result;

EndFunction

// Returns the file storage type that matches the specified storage volume or volume storage option.
//
// Parameters:
//  VolumeOrFileStorageMethod - CatalogRef.FileStorageVolumes, EnumRef.FilesStorageMethods
//
// Returns:
//  - EnumRef.FileStorageTypes
//  - Undefined
//
Function StorageTypeByFileStorageVolume(VolumeOrFileStorageMethod = Undefined) Export

	If ValueIsFilled(VolumeOrFileStorageMethod) Then

		If TypeOf(VolumeOrFileStorageMethod) = Type("CatalogRef.FileStorageVolumes") Then
			StorageMethod = Common.ObjectAttributeValue(VolumeOrFileStorageMethod, "FilesStorageMethod");
		Else
			StorageMethod = VolumeOrFileStorageMethod;
		EndIf;

		If StorageMethod = Enums.WaysToStoreFiles.InNetworkDirectories Then
			Result = Enums.FileStorageTypes.InVolumesOnHardDrive;
		ElsIf StorageMethod = Enums.WaysToStoreFiles.InBuiltInStorage Then
			Result = Enums.FileStorageTypes.InBuiltInBinaryDataStorage;
		ElsIf StorageMethod = Enums.WaysToStoreFiles.InExternalStorageUsingS3Protocol Then
			Result = Enums.FileStorageTypes.InExternalBinaryDataStorage;
		Else
			Result = Undefined;
		EndIf;
	Else
		Result = Enums.FileStorageTypes.InInfobase;
	EndIf;

	Return Result;

EndFunction

// Verifies that the archive contains the attachment associated with the passed item of the BinaryDataStorage catalog.
//
// Parameters:
//  Var_BinaryDataStorage - CatalogRef.BinaryDataStorage
//
// Returns:
//  Boolean
//
Function BinaryDataStoreIsPresentInFileArchive(Var_BinaryDataStorage) Export

	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	CatalogBinaryDataStorage.Ref AS Ref
		|FROM
		|	Catalog.BinaryDataStorage AS CatalogBinaryDataStorage
		|		INNER JOIN InformationRegister.FileRepository AS FileRepository
		|		ON (CatalogBinaryDataStorage.Ref = &BinaryDataStorage)
		|			AND CatalogBinaryDataStorage.Ref = FileRepository.BinaryDataStorage
		|		LEFT JOIN InformationRegister.FilesInfo AS FilesInfo
		|		ON (FileRepository.File = FilesInfo.File)
		|			AND (NOT FilesInfo.DeletionMark)
		|		LEFT JOIN Catalog.FilesVersions AS FilesVersions
		|		ON (FileRepository.File = FilesVersions.Ref)
		|			AND (NOT FilesVersions.Owner.DeletionMark)
		|WHERE
		|	NOT ISNULL(FilesInfo.DeletionMark, ISNULL(FilesVersions.DeletionMark, FALSE))
		|	AND ISNULL(FilesInfo.DateOfTransferToArchive, ISNULL(FilesVersions.DateOfTransferToArchive, DATETIME(1, 1, 1))) <> DATETIME(1, 1, 1)";

	Query.SetParameter("BinaryDataStorage", Var_BinaryDataStorage);

	Return Not Query.Execute().IsEmpty();

EndFunction

// Verifies that the archive contains the attachment.
//
// Parameters:
//  AttachedFile - DefinedType.AttachedFile, CatalogRef.FilesVersions - Reference to the catalog item
//                                                                                           that contains the file.
//
// Returns:
//  Boolean
//
Function FileHasBeenTransferredToFileArchive(AttachedFile) Export

	Result = False;

	If ValueIsFilled(AttachedFile) Then 
		If TypeOf(AttachedFile) = Type("CatalogRef.FilesVersions") Then

			DateOfTransferToArchive = Common.ObjectAttributeValue(AttachedFile, "DateOfTransferToArchive");

		ElsIf TypeOf(AttachedFile) = Type("CatalogRef.Files") Then

			CurrentFileVersion = Common.ObjectAttributeValue(AttachedFile, "CurrentVersion");

			DateOfTransferToArchive = Common.ObjectAttributeValue(CurrentFileVersion, "DateOfTransferToArchive");

		Else

			Query = New Query;
			Query.Text = 
				"SELECT
				|	FilesInfo.DateOfTransferToArchive AS DateOfTransferToArchive
				|FROM
				|	InformationRegister.FilesInfo AS FilesInfo
				|WHERE
				|	FilesInfo.File = &File";

			Query.SetParameter("File", AttachedFile);

			SetPrivilegedMode(True);
			
			DataSelection = Query.Execute().Select();
			If DataSelection.Next() Then
				DateOfTransferToArchive = DataSelection.DateOfTransferToArchive;
			Else
				DateOfTransferToArchive = Date(1,1,1);			
			EndIf;
		EndIf;

		Result = ValueIsFilled(DateOfTransferToArchive);

	EndIf;

	Return Result;

EndFunction

// Returns a structure containing the hash result of the binary data.
//
// Parameters:
//  BinaryData - BinaryData, Undefined
//
// Returns:
//  Structure - 
//
Function ResultOfHashingBinaryData(BinaryData) Export

	Hashing = New DataHashing(HashFunction.SHA256);

	IsEmptyBinaryData = (BinaryData = Undefined);
	If IsEmptyBinaryData Then
		EmptyBinaryData = GetBinaryDataFromString("");
		Hashing.Append(EmptyBinaryData);
		Size = EmptyBinaryData.Size();
	Else
		Hashing.Append(BinaryData);
		Size = BinaryData.Size();
	EndIf;
	Hash = GetBase64StringFromBinaryData(Hashing.HashSum);	

	Result = ParametersOfBinaryDataHashingResult();
	
	Result.IsEmptyBinaryData = IsEmptyBinaryData;
	Result.Size = Size;
	Result.Hash = Hash;

	Return Result;

EndFunction

// Returns information on the BinaryDataStorage catalog item that matches the specified hash and size.
//
// Parameters:
//  Hash		- String - A Base64 string generated by the 1C:Enterprise method GetBase64StringFromBinaryData.
//  Size	- Number
//
// Returns:
//  Structure - Information on the BinaryDataStorage catalog item:
//   * BinaryDataStorageRef - CatalogRef.BinaryDataStorage - If a matching BinaryDataStorage
//                                                                                catalog item has been found.
//									 - Undefined - If no matching BinaryDataStorage catalog item has been found.
//   * StoredDataSize			 - Number - The size of the binary data in bytes.
//
Function InformationAboutBinaryDataStorageElementByHashAndSize(Hash, Size) Export

	Result = New Structure;
	Result.Insert("BinaryDataStorageRef"	, Undefined);
	Result.Insert("StoredDataSize"			, 0);
	
	Query = New Query;
	Query.SetParameter("Hash"		, Hash);
	Query.SetParameter("Size"	, Size);
	Query.Text =
		"SELECT
		|	BinaryDataStorage.Ref AS BinaryDataStorageRef,
		|	STOREDDATASIZE(BinaryDataStorage.BinaryData) AS StoredDataSize
		|FROM
		|	Catalog.BinaryDataStorage AS BinaryDataStorage
		|WHERE
		|	BinaryDataStorage.Hash = &Hash
		|	AND BinaryDataStorage.Size = &Size";

	Selection = Query.Execute().Select();

	If Selection.Next() Then
		FillPropertyValues(Result, Selection);
	EndIf;

	Return Result;

EndFunction

// Populates attachment attributes FileStorageType and Volume with data obtained from information register DeduplicatedFilesStorageInformation.
//
// Parameters:
//  AttachedFile	- DefinedType.AttachedFileObject, CatalogObject.FilesVersions - Catalog item object the file belongs to.
//  BinaryData		- BinaryData - binary file data.
//
Procedure FillInFilePropertiesForExistingBinaryDataStorageItem(AttachedFile, BinaryData) Export

	If TypeOf(BinaryData) <> Type("BinaryData") Or Not BinaryDataStoresAreAvailable() Then
		Return;
	EndIf;

	InformationAboutFileStorage = StorageParametersOfDeduplicatedFile(BinaryData);
	If InformationAboutFileStorage <> Undefined Then
		FillPropertyValues(AttachedFile, InformationAboutFileStorage);
	EndIf;	

EndProcedure

// Returns a structure with deduplicated file storage parameters retrieved from information register DeduplicatedFilesStorageInformation.
//
// Parameters:
//  BinaryData			- BinaryData - The binary data for which the item of the BinaryDataStorage catalog needs to be retrieved.
//  Var_BinaryDataStorage - CatalogRef.BinaryDataStorage - Used for optimization when the BinaryDataStorage
//                                                                       catalog item is already known.
//  TypeOfFileStorage		- EnumRef.TypesOfFileStorage
//
// Returns:
//  - Structure		- In case no deduplicated file storage parameters exist in DeduplicatedFilesStorageInformation.
//  - Undefined	- In case no deduplicated file storage parameters exist in DeduplicatedFilesStorageInformation.
//
Function StorageParametersOfDeduplicatedFile(BinaryData, Var_BinaryDataStorage = Undefined, TypeOfFileStorage = Undefined)

	SetPrivilegedMode(True);
	
	If ValueIsFilled(Var_BinaryDataStorage) Then
		BinaryDataStorageRef = Var_BinaryDataStorage;
	Else
		BinaryDataStorageRef = BinaryDataStorageElementForBinaryData(BinaryData);
	EndIf;

	If ValueIsFilled(BinaryDataStorageRef) Then
		Result = InformationRegisters.InformationAboutStoringDeduplicatedFiles.InformationAboutStoringDeduplicatedFiles(BinaryDataStorageRef, TypeOfFileStorage);
	Else
		Result = Undefined;
	EndIf;	

	Return Result;

EndFunction

// Returns the item of the BinaryDataStorage catalog that matches the specified binary data.
//
// Parameters:
//  BinaryData - BinaryData - Attachment binary data.
//
// Returns:
//  - CatalogRef.BinaryDataStorage - If the catalog item is found.
//  - Undefined - If the catalog item is found.
//
Function BinaryDataStorageElementForBinaryData(BinaryData)

	HashingResult = ResultOfHashingBinaryData(BinaryData);

	InformationAboutBinaryDataStore = InformationAboutBinaryDataStorageElementByHashAndSize(HashingResult.Hash, HashingResult.Size);
	Result = InformationAboutBinaryDataStore.BinaryDataStorageRef;	

	Return Result;

EndFunction

// Returns a vacant storage volume suitable for storing the attachment.
//
// Parameters:
//  AttachedFile		- DefinedType.AttachedFileObject
//                      		- See FilesOperationsInVolumesInternal.FileAddingOptions
//  FilesStorageTyoe		- EnumRef.FileStorageTypes
//  TypeOfFileStorageVolume	- EnumRef.TypesOfFileStorage
//
// Returns:
//   CatalogRef.FileStorageVolumes
//
Function FreeStorageVolumeByFileStorageType(AttachedFile, FilesStorageTyoe, TypeOfFileStorageVolume) Export

	MethodOfStorageInVolumes = StorageMethodForSearchingStorageVolumesByFileStorageType(FilesStorageTyoe);

	Result = FilesOperationsInVolumesInternal.FreeVolume(AttachedFile, TypeOfFileStorageVolume, MethodOfStorageInVolumes);

	Return Result;

EndFunction

// Returns a structure of parameters used for writing binary data to the files' binary storage attributes.
//
// Returns:
//  Structure
//
Function ParametersOfEntryInInformationDatabase() Export

	Result = New Structure;
	Result.Insert("FileStorageType");
	Result.Insert("Volume");
	Result.Insert("PathToFile"					, "");
	Result.Insert("ThisIsEntryInFileArchive"	, False);
	Result.Insert("DoNotModifyBinaryData"	, False);
	Result.Insert("BinaryDataOfArchive");

	Return Result;

EndFunction

// Returns a structure of parameters used for writing
// binary data to the files' binary storage attributes.
//
// Parameters:
//  AttachedFile - DefinedType.AttachedFile, DefinedType.AttachedFileObject, Structure -
//                       Source of parameter values.
//
// Returns:
//  Structure
//
Function CompletedParametersOfEntryInInformationDatabase(AttachedFile) Export

	Result = ParametersOfEntryInInformationDatabase();

	If Common.IsReference(TypeOf(AttachedFile)) Then
		AttributesValues = Common.ObjectAttributesValues(AttachedFile, "FileStorageType,Volume,PathToFile");
		FillPropertyValues(Result, AttributesValues);
	Else
		FillPropertyValues(Result, AttachedFile);
	EndIf;

	Return Result;

EndFunction

// Populates the following attachment's attributes: FileStorageType, Volume, PathToFile.
//
// Parameters:
//  AttachedFile	- DefinedType.AttachedFileObject, CatalogObject.FilesVersions - Catalog item object the file belongs to
//  BinaryData		- BinaryData - Binary file data
//  Size				- Number
//  Extension			- String
//
Procedure FillInFileStorageParameters(AttachedFile, BinaryData, Size, Extension) Export
	
	AttachedFile.FileStorageType = Undefined;
	AttachedFile.Volume = Undefined;
	AttachedFile.PathToFile = Undefined;

	FillInFilePropertiesForExistingBinaryDataStorageItem(AttachedFile, BinaryData);
	
	If Not ValueIsFilled(AttachedFile.FileStorageType) Then
		AttachedFile.FileStorageType = FilesOperationsInternal.FileStorageType(Size, Extension);

		If AttachedFile.FileStorageType <> Enums.FileStorageTypes.InInfobase Then
			
			AttachedFile.Volume = FreeStorageVolumeByFileStorageType(AttachedFile, 
																												AttachedFile.FileStorageType,
																												Enums.TypesOfFileStorage.OperationalStorage);
			If AttachedFile.FileStorageType = Enums.FileStorageTypes.InVolumesVolumeIsNotDefined Then
				AttachedFile.FileStorageType = StorageTypeByFileStorageVolume(AttachedFile.Volume);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Creates a temporary folder and returns its full path.
//
// Parameters:
//  ErrorDescriptionString - String - Extended error text
//
// Returns:
//  String - Full path to the temporary directory.
//
Function NewTemporaryDirectoryForWorkingWithZipArchive(ErrorDescriptionString = "")

	Try

		TemporaryFileDirectory = FileSystem.CreateTemporaryDirectory();

	Except

		ErrorDescriptionTemplate = NStr("en = '""%1""
			|Temporary directory for the ZIP archive was not created
			|""%2""'");

		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorDescriptionTemplate,
			ErrorDescriptionString,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));

		WriteLogEvent(NStr("en = 'File archive operations'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ExceptionString);

		Raise ExceptionString;

	EndTry;

	Return TemporaryFileDirectory;

EndFunction

// Retrieves the file entry extracted from a ZIP archive. If a file with the specified name is not found,
// returns the first entry in the archive.
//
// Parameters:
//  ZIPReader				- ZipFileReader - ZIP archive.
//  NameOfExtractedFile	- String - Full name of the extracted file.
//
// Returns:
//  ZipFileEntries	- A ZIP file entry, if found by the passed filename, or the first entry in the archive if no matching file is found.
//  Undefined - If the ZIP entry could not be determined.		
//
Function ElementOfExtractedFile(ZIPReader, NameOfExtractedFile)

	Result = ZIPReader.Items.Find(NameOfExtractedFile);

	If Result = Undefined Then
		If ZIPReader.Items.Count() > 0 Then
			Result = ZIPReader.Items[0];
		Else
			Result = Undefined;
		EndIf;
	EndIf;

	Return Result;

EndFunction

Function PrepareBinaryDataForRecording(DataToWrite)

	If TypeOf(DataToWrite) = Type("BinaryData") Then
		Result = New ValueStorage(DataToWrite, New Deflation(9));
	Else
		Result = DataToWrite;
	EndIf;

	Return Result;

EndFunction

Function MinimumRequiredVersionOfPlatformForWorkingWithBinaryDataStores()
	
	Return "8.3.26.1000";
	
EndFunction

Function SizeOfPortionOfFilesBeingMovedIsDefaultValue()
	Return 10;
EndFunction

Function TextInformingUserAboutUnavailabilityOfFileInArchiveDefaultValue()

	Return NStr("en = 'To get the file, contact the administrator'");

EndFunction

Function StorageMethodForSearchingStorageVolumesByFileStorageType(FileStorageType)

	If FileStorageType = Enums.FileStorageTypes.InExternalBinaryDataStorage Then
		Result = Enums.WaysToStoreFiles.InExternalStorageUsingS3Protocol;
	ElsIf FileStorageType = Enums.FileStorageTypes.InBuiltInBinaryDataStorage Then
		Result = Enums.WaysToStoreFiles.InBuiltInStorage;
	ElsIf FileStorageType = Enums.FileStorageTypes.InVolumesVolumeIsNotDefined Then
		Result = "InVolumesWithAnyStorageMethod";
	Else
		Result = Enums.WaysToStoreFiles.InNetworkDirectories;
	EndIf;		

	Return Result;

EndFunction

Function ParametersOfBinaryDataHashingResult()

	Result = New Structure;
	Result.Insert("IsEmptyBinaryData", False);
	Result.Insert("Size"					, 0);
	Result.Insert("Hash"					, "");	

	Return Result;

EndFunction

Procedure DeleteTemporaryDirectoryForWorkingWithZipArchive(TempDirectory)

	Try
		DeleteFiles(TempDirectory);
	Except

		ErrorDescriptionTemplate = NStr("en = 'Couldn''t delete the temporary directory created for the ZIP archive
			|%1
			|%2'");

		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorDescriptionTemplate,
			TempDirectory,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));		
		
		WriteLogEvent(NStr("en = 'File archive operations'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ExceptionString);		
	EndTry;	
	
EndProcedure

Function TemporaryDirectoryForNonUniqueFile(TempDirectory, FileName)

	FileOnHardDrive = New File(TempDirectory + FileName);
	If FileOnHardDrive.Exists() Then
		UniqueName = FilesOperationsInternalClientServer.UniqueNameByWay(TempDirectory, FileName);

		Result = TempDirectory + StrReplace(UniqueName, FileName, "");
	Else
		Result = TempDirectory;
	EndIf;

	Return Result;

EndFunction

Procedure InitialFillingOfConstants() Export

	Constants.PortionSizeOfFilesBeingMoved.Set(
				SizeOfPortionOfFilesBeingMovedIsDefaultValue());

	Constants.TextInformingUserAboutUnavailabilityOfFileInArchive.Set(
				TextInformingUserAboutUnavailabilityOfFileInArchiveDefaultValue());
	
EndProcedure

Procedure InitialFillingInSettingsForWorkingWithFileArchive() Export
	
	RecordsetIsDefaultValue = InformationRegisters.FileArchiveWorkSettings.CreateRecordSet();

	RecordsetIsDefaultValue.Filter.FileOwner.Set(Undefined);
	RecordsetIsDefaultValue.Filter.FileOwnerType.Set(Undefined);
	
	RsRecording = RecordsetIsDefaultValue.Add();
	RsRecording.FileOwner						= Undefined;
	RsRecording.FileOwnerType					= Undefined;
	RsRecording.TransferToFileArchiveInDays	= 365;	
	
	InfobaseUpdate.WriteData(RecordsetIsDefaultValue);	
	
EndProcedure

// Creates a ZIP archive file and adds the passed file to it.
//
// Parameters:
//  PathToArchiveFile		- String - Path to the ZIP archive.
//  PathToArchivedFile	- String - Path to the source file.
//
// Returns:
//  Structure
//
Function PackFileIntoZipArchive(PathToArchiveFile, PathToArchivedFile)

	ZipArchiveFile = New File(PathToArchiveFile);
	If ZipArchiveFile.Exists() Then
		DeleteFiles(PathToArchiveFile);
	EndIf;

	RecordZIP = New ZipFileWriter(PathToArchiveFile);
	RecordZIP.Add(PathToArchivedFile, ZIPStorePathMode.DontStorePath);
	RecordZIP.Write();

	ZipArchiveFile = New File(PathToArchiveFile);

	Result = New Structure;
	Result.Insert("FileName"	, PathToArchiveFile);
	Result.Insert("Size"		, ZipArchiveFile.Size());	

	Return Result;

EndFunction

// Extracts a file with the specified name from a ZIP archive to the designated directory.
//
// Parameters:
//  BinaryZipArchiveData - BinaryData - Binary ZIP archive data.
//  NameOfExtractedFile	- String - Full name of the extracted file.
//  TempDirectory		- String - Destination directory.
//
// Returns:
//  Structure
//
Function ExtractFileFromZipArchive(BinaryZipArchiveData, NameOfExtractedFile, TempDirectory)

	ReadStream = BinaryZipArchiveData.OpenStreamForRead();

	ZIPReader = New ZipFileReader(ReadStream);

	ElementOfExtractedFile = ElementOfExtractedFile(ZIPReader, NameOfExtractedFile);

	If ElementOfExtractedFile = Undefined Then 
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'File not found in ZIP archive: %1'"), NameOfExtractedFile);
	EndIf;

	TemporaryDirectoryForFileExtraction = TemporaryDirectoryForNonUniqueFile(TempDirectory, NameOfExtractedFile);

	ZIPReader.Extract(ElementOfExtractedFile, TemporaryDirectoryForFileExtraction);

	PathToExtractedFile = TemporaryDirectoryForFileExtraction + ElementOfExtractedFile.OriginalName;

	ZIPReader.Close();
	ReadStream.Close();

	ExtractedFile = New File(PathToExtractedFile);
	If ExtractedFile.Exists() Then
		Result = New Structure;
		Result.Insert("FileName"	, PathToExtractedFile);
		Result.Insert("Size"		, ExtractedFile.Size());
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Failed to extract file from ZIP archive: %1'"), NameOfExtractedFile);
	EndIf;

	Return Result;

EndFunction

#Region TransferringFilesBetweenOperationalStorageAndFileArchive

// Method of sheduled job TransferFilesBetweenOperationalStorageAndFileArchive.
//
// Parameters:
//  Parameters		- Structure - Arbitrary ProcedureParameters. 
//									See TimeConsumingOperations.ExecuteInBackground
//                           for the ProcedureName parameter
//  ResultAddress - String    - Address of the temporary storage where the result will be stored.
//									See TimeConsumingOperations.ExecuteInBackground
//                                for the ProcedureName parameter
//
Procedure TransferFilesBetweenOperationalStorageAndFileArchive(Parameters = Undefined, ResultAddress = Undefined) Export

	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.TransferringFilesBetweenOperationalStorageAndFileArchive);
	
	If Not UseFileArchive() Then
		Return;
	EndIf;

	SetPrivilegedMode(True);

	FileTransferSettings = InformationRegisters.FileArchiveWorkSettings.GetSettingsForWorkingWithFileArchiveForTransferringFiles();
	MigrationSettingsForMetadataObjects = FileTransferSettings.FindRows(New Structure("ThisIsDetailedFileTransferSetup", False));

	If MigrationSettingsForMetadataObjects.Count() > 0 Then

		PortionSize = PortionSizeOfFilesBeingMoved();

		QueryText = QueryTextOfPortionOfFiles(PortionSize);

		AdditionalTransferParameters = AdditionalFileTransferOptions();
		AdditionalTransferParameters.QueryTextForReceivingPortionOfFilesToTransferToArchive = QueryText;

		QueryText = QueryTextOfPortionOfFiles(PortionSize, False);
		AdditionalTransferParameters.QueryTextForGettingPortionOfFilesToRestoreFromArchive = QueryText;
		AdditionalTransferParameters.FilesStorageMethod = FilesStorageMethod();
		
		NumberOfDaysOfStorageByDefault = InformationRegisters.FileArchiveWorkSettings.GetNumberOfDaysOfStorageFromDefaultSetting();

		For Each Setting In MigrationSettingsForMetadataObjects Do

			ExceptionsArray = New Array;

			DetailedSettings = FileTransferSettings.FindRows(New Structure(
																"CommonOwnerId, ThisIsDetailedFileTransferSetup",
																Setting.CommonOwnerId,
																True));

			If DetailedSettings.Count() > 0 Then
				NumberOfDaysOfStorageOfParent = NumberOfDaysOfStorageBeforeTransferToFileArchive(Setting, NumberOfDaysOfStorageByDefault);					
					
				For Each DetalizedSetting In DetailedSettings Do

					PerformFileOfOperations(DetalizedSetting, ExceptionsArray, NumberOfDaysOfStorageOfParent, AdditionalTransferParameters);

				EndDo;
			EndIf;

			PerformFileOfOperations(Setting, ExceptionsArray, NumberOfDaysOfStorageByDefault, AdditionalTransferParameters);

		EndDo;
	EndIf; 
	
EndProcedure

Procedure PerformFileOfOperations(Setting, ExceptionsArray, NumberOfDaysOfStorageOfParent, AdditionalTransferParameters)

	NumberOfDaysOfOperationalStorage = NumberOfDaysOfStorageBeforeTransferToFileArchive(Setting, NumberOfDaysOfStorageOfParent);
	
	TransferFilesToFileArchive(Setting, ExceptionsArray, NumberOfDaysOfOperationalStorage, AdditionalTransferParameters);

	RecoverFilesFromFileArchive(Setting, ExceptionsArray, NumberOfDaysOfOperationalStorage, AdditionalTransferParameters);

	ExceptionsArray.Add(Setting.FileOwner);

EndProcedure

Procedure RecoverFilesFromFileArchive(Setting, ExceptionsArray, NumberOfDaysOfOperationalStorage, AdditionalTransferParameters)

	TempTablesManager = New TempTablesManager;

	FillInTemporaryTableForFileRecovery(Setting, ExceptionsArray, NumberOfDaysOfOperationalStorage, TempTablesManager);

	InformationForVolumeSelection				= InformationAboutFilesForVolumeSelection();
	InformationAboutSelectedStorageVolume	= Undefined;

	LastRef = EmptyLinkToAttachedFile(Setting);

	QueryText = AdditionalTransferParameters.QueryTextForGettingPortionOfFilesToRestoreFromArchive;

	FilesToTransfer = NextBatchOfFiles(TempTablesManager, LastRef, QueryText);

	While FilesToTransfer.Count() > 0 Do

		ErrorDescriptionString = ErrorDescriptionStringOfOperationsWithTemporaryDirectory(False);

		For Each ProcessedFile In FilesToTransfer Do

			If ProcessedFile.NumberOfDeduplicatedFiles > 0 Then
				//@skip-warning Query выполняется не для всех итераций цикла.
				If Not FileHasBeenTransferredToFileArchive(ProcessedFile.AttachedFile) Then
					Continue;
				EndIf;
			EndIf;

			TempDirectory = NewTemporaryDirectoryForWorkingWithZipArchive(ErrorDescriptionString);

			AttachedFileRef = ProcessedFile.AttachedFile;
			
			Block = New DataLock;
			DataLockItem = Block.Add(AttachedFileRef.Metadata().FullName());
			DataLockItem.SetValue("Ref", AttachedFileRef);
			
			DataLockItem = Block.Add(Metadata.InformationRegisters.FilesInfo.FullName());
			DataLockItem.SetValue("File", AttachedFileRef);
			
			DataLockItem = Block.Add(Metadata.InformationRegisters.FileRepository.FullName());
			DataLockItem.SetValue("File", AttachedFileRef);			

			BeginTransaction();
			Try

				Block.Lock();
				
				OperationParametersList = ParametersForPerformingRecoveryOfOperation();
				OperationParametersList.TempDirectory	= TempDirectory;

				ExtractedFile = FileExtractedFromZipArchive(ProcessedFile, OperationParametersList);

				NewFileStorageType = Undefined;

				If ValueIsFilled(ProcessedFile.FileStorageTypeOperational) Then
					NewFileStorageType = ProcessedFile.FileStorageTypeOperational;

					InformationAboutStorageVolume = InformationAboutStorageVolume();
					InformationAboutStorageVolume.Ref				= ProcessedFile.VolumeIsOperational;
					InformationAboutStorageVolume.NewFileStorageType = NewFileStorageType;

					OperationParametersList.ReceivedStorageParameters	= True;

				Else

					BinaryData = New BinaryData(ExtractedFile.FileName);

					FileStorageOptions = StorageParametersOfDeduplicatedFile(
																			BinaryData, 
																			ProcessedFile.BinaryDataStorage,
																			Enums.TypesOfFileStorage.OperationalStorage);

					If FileStorageOptions <> Undefined Then
						NewFileStorageType = FileStorageOptions.FileStorageType;

						InformationAboutStorageVolume = InformationAboutStorageVolume();
						InformationAboutStorageVolume.Ref				= FileStorageOptions.Volume;
						InformationAboutStorageVolume.NewFileStorageType = NewFileStorageType;

						OperationParametersList.ReceivedStorageParameters = True;
					EndIf;
				EndIf;

				NewFileStorageTypeIsPredefined = ValueIsFilled(NewFileStorageType);

				If Not NewFileStorageTypeIsPredefined Then

					FileSize = FileSize(ExtractedFile.FileName);
					// A deduplicated file may be transferred to a disk volume.
					// In this case, a copy of each deduplicated file will be stored on disk.
					// Therefore, when selecting a storage volume, the total required free space is taken into account.
					InformationForVolumeSelection.Size = Max(1, ProcessedFile.NumberOfDeduplicatedFiles) * FileSize;

					NewFileStorageType = FilesOperationsInternal.FileStorageType(InformationForVolumeSelection.Size, ProcessedFile.Extension);

					If NewFileStorageType = Enums.FileStorageTypes.InInfobase Then

						InformationAboutStorageVolume = InformationAboutStorageVolume();
						InformationAboutStorageVolume.NewFileStorageType = NewFileStorageType;

					Else
						If InformationAboutSelectedStorageVolume = Undefined 
								Or InformationAboutSelectedStorageVolume.MaximumSize <> 0 And InformationAboutSelectedStorageVolume.FreeVolume_ - InformationForVolumeSelection.Size < 0 Then

							InformationAboutSelectedStorageVolume = SelectStorageVolume(InformationForVolumeSelection, 
																					Enums.TypesOfFileStorage.OperationalStorage,
																					NewFileStorageType);
						EndIf;

						InformationAboutStorageVolume = InformationAboutSelectedStorageVolume;

						// If a file is transferred to a volume that stores data on a disk partition, the volume
						// space is reduced by the file size, since files in such volumes are deduplicated.
						If InformationAboutStorageVolume.NewFileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
							FileSize = InformationForVolumeSelection.Size;
						EndIf;
					EndIf;
				EndIf;

				OperationParametersList.InformationAboutStorageVolume = InformationAboutStorageVolume;

				// @skip-check query-in-loop - 
				RecoverFileFromFileArchive(ProcessedFile, ExtractedFile, OperationParametersList);

				If Not NewFileStorageTypeIsPredefined Then
					If ValueIsFilled(NewFileStorageType) And NewFileStorageType <> Enums.FileStorageTypes.InInfobase Then
						If InformationAboutStorageVolume.MaximumSize <> 0 Then

							InformationAboutStorageVolume.FreeVolume_ = InformationAboutStorageVolume.FreeVolume_ - FileSize;

						EndIf;					
					EndIf;
				EndIf;

				CommitTransaction();

			Except

				RollbackTransaction();

				ExceptionString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				RecordFileTransferEventInRegistrationLog(ExceptionString, EventLogLevel.Error);

				DeleteTemporaryDirectory(TempDirectory, ErrorDescriptionString);
				Continue;
			EndTry;

			DeleteTemporaryDirectory(TempDirectory, ErrorDescriptionString);

		EndDo;

		LastRef = ProcessedFile.AttachedFile;

		// @skip-check query-in-loop - 
		FilesToTransfer = NextBatchOfFiles(TempTablesManager, LastRef, QueryText);

	EndDo;	

EndProcedure

Procedure FillInTemporaryTableForFileRecovery(ConfiguringFileTransfer, ExceptionsArray, NumberOfDaysOfOperationalStorage, TempTablesManager)
	
	SetPrivilegedMode(True);

	If ConfiguringFileTransfer.ThisIsDetailedFileTransferSetup Then
		FileOwner		= ConfiguringFileTransfer.OwnerID;
		ExceptionItem	= ConfiguringFileTransfer.FileOwner;
	Else
		FileOwner		= ConfiguringFileTransfer.FileOwner;
		ExceptionItem	= Undefined;
	EndIf;	

	QueryText = QueryTextForRecoveringFilesFromFileArchive(FileOwner, ConfiguringFileTransfer, ExceptionsArray, ExceptionItem);

	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;

	Query.SetParameter("OwnerType"		, TypeOf(Common.ObjectAttributeValue(FileOwner, "EmptyRefValue")));
	Query.SetParameter("DaysCount"		, NumberOfDaysOfOperationalStorage);
	Query.SetParameter("DateOfProcessing"		, CurrentSessionDate());
	Query.SetParameter("RecoverAllFiles", ConfiguringFileTransfer.Action = Enums.ActionsInFileArchiveWorkSettings.NotTransferToArchive);

	If ExceptionsArray.Count() > 0 Then

		Query.SetParameter("ExceptionsArray", ExceptionsArray);

	EndIf;

	If ConfiguringFileTransfer.ThisIsDetailedFileTransferSetup Then

		Query.SetParameter("SelectionBasedOnDetailedSettings", ExceptionItem);

	EndIf;	

	Query.Execute();	

EndProcedure

Function QueryTextForRecoveringFilesFromFileArchive(FileOwner, Setting, ExceptionsArray, ExceptionItem)

	FilesCatalogAttributes = Common.ObjectAttributesValues(Setting.FileOwnerType, "FullName, Name");

	FilesOwnerMedatada = Common.MetadataObjectByID(FileOwner);
	FilesOwnerFullName = FilesOwnerMedatada.FullName();

	FilesObjectMetadata = Common.MetadataObjectByID(Setting.FileOwnerType);
	HasAbilityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", FilesObjectMetadata);

	BatchQueryText = New Array;

	If HasAbilityToStoreVersions Then

		FilesVersionsCatalog	= Common.MetadataObjectID(FilesObjectMetadata.Attributes.CurrentVersion.Type.Types()[0]);
		FilesVersionsMetadata	= Common.MetadataObjectByID(FilesVersionsCatalog);

		FullFilesVersionsCatalogName = FilesVersionsMetadata.FullName();

		QueryText = 
           "SELECT
           |	FilesVersions.Ref AS AttachedFile,
           |	FilesVersions.FileStorageType AS FileStorageType,
           |	FilesVersions.Volume AS Volume,
           |	FilesVersions.PathToFile AS PathToFile,
           |	ISNULL(FileRepository.BinaryDataStorage, VALUE(Catalog.BinaryDataStorage.EmptyRef)) AS BinaryDataStorage,
           |	FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive) AS ThisIsOnDiskStorage,
           |	FilesVersions.Description AS Description,
           |	FilesVersions.Extension AS Extension,
           |	FilesVersions.Owner AS FileForRecordingInformation,
           |	FilesVersions.VersionNumber AS VersionNumber,
           |	Files.FileOwner AS FileOwner,
           |	DATEADD(FilesVersions.CreationDate, DAY, &DaysCount) AS PlannedDateOfTransferToArchive,
           |	FilesVersions.Presentation AS FilePresentation
           |INTO VT_PreparingDataForRecovery
           |FROM
           |	#FullFilesCatalogName AS Files
           |		INNER JOIN #FullFilesVersionsCatalogName AS FilesVersions
           |		ON Files.Ref = FilesVersions.Owner
           |			AND (NOT Files.DeletionMark)
           |			AND (NOT FilesVersions.DeletionMark)
           |			AND (&ThisIsNotGroup)
           |			AND (VALUETYPE(Files.FileOwner) = &OwnerType)
           |			AND (&SelectionBasedOnDetailedSettings)
           |			AND (&SelectionByExceptions)
           |			AND (CASE
           |				WHEN FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
           |					THEN (CAST(FilesVersions.PathToFile AS STRING(100))) <> """"
           |							OR NOT FilesVersions.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				WHEN FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InExternalBinaryDataStorage)
           |					THEN NOT FilesVersions.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				ELSE FALSE
           |			END)
           |			AND (FilesVersions.DateOfTransferToArchive <> DATETIME(1,1,1))
           |		LEFT JOIN InformationRegister.FileRepository AS FileRepository
           |		ON (FilesVersions.Ref = FileRepository.File)";

		QueryText = StrReplace(QueryText, "#FullFilesCatalogName"		, FilesCatalogAttributes.FullName);
		QueryText = StrReplace(QueryText, "#FullFilesVersionsCatalogName", FullFilesVersionsCatalogName);

		BatchQueryText.Add(QueryText);

	Else // Not HasAbilityToStoreVersions

		QueryText = 
           "SELECT
           |	Files.Ref AS AttachedFile,
           |	Files.FileStorageType AS FileStorageType,
           |	Files.Volume AS Volume,
           |	Files.PathToFile AS PathToFile,
           |	ISNULL(FileRepository.BinaryDataStorage, VALUE(Catalog.BinaryDataStorage.EmptyRef)) AS BinaryDataStorage,
           |	Files.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive) AS ThisIsOnDiskStorage,
           |	Files.Description AS Description,
           |	Files.Extension AS Extension,
           |	Files.Ref AS FileForRecordingInformation,
           |	0 AS VersionNumber,
           |	Files.FileOwner AS FileOwner,
           |	DATEADD(Files.CreationDate, DAY, &DaysCount) AS PlannedDateOfTransferToArchive,
           |	Files.Presentation AS FilePresentation
           |INTO VT_PreparingDataForRecovery
           |FROM
           |	#FileOwnerType AS Files
           |		INNER JOIN #CatalogFileOwner AS CatalogFileOwner
           |		ON Files.FileOwner = CatalogFileOwner.Ref
           |			AND (NOT CatalogFileOwner.DeletionMark)
           |			AND (NOT Files.DeletionMark)
           |			AND (&ThisIsNotGroup)
           |			AND (VALUETYPE(Files.FileOwner) = &OwnerType)
           |			AND (&SelectionBasedOnDetailedSettings)
           |			AND (&SelectionByExceptions)
           |			AND (CASE
           |				WHEN Files.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
           |					THEN (CAST(Files.PathToFile AS STRING(100))) <> """"
           |							OR NOT Files.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				WHEN Files.FileStorageType = VALUE(Enum.FileStorageTypes.InExternalBinaryDataStorage)
           |					THEN NOT Files.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				ELSE FALSE
           |			END)
           |		INNER JOIN InformationRegister.FilesInfo AS FilesInfo
           |		ON Files.Ref = FilesInfo.File
           |			AND (FilesInfo.DateOfTransferToArchive <> DATETIME(1,1,1))
           |		LEFT JOIN InformationRegister.FileRepository AS FileRepository
           |		ON Files.Ref = FileRepository.File";

		QueryText = StrReplace(QueryText, "#FileOwnerType", "Catalog." + FilesCatalogAttributes.Name);
		QueryText = StrReplace(QueryText, "#CatalogFileOwner", FilesOwnerFullName);		   

		BatchQueryText.Add(QueryText);

	EndIf;	

	QueryText = 
           "SELECT DISTINCT
           |	VT_PreparingDataForRecovery.BinaryDataStorage AS BinaryDataStorage
           |INTO VT_DataForCheckingDeduplication
           |FROM
           |	VT_PreparingDataForRecovery AS VT_PreparingDataForRecovery
           |WHERE
           |	NOT VT_PreparingDataForRecovery.ThisIsOnDiskStorage
           |
           |INDEX BY
           |	VT_PreparingDataForRecovery.BinaryDataStorage
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |SELECT
           |	FileRepository.BinaryDataStorage AS BinaryDataStorage,
           |	COUNT(*) AS NumberOfDeduplicatedFiles,
           |	COUNT(*) - SUM(CASE
           |			WHEN ISNULL(FilesInfo.DateOfTransferToArchive, ISNULL(FilesVersions.DateOfTransferToArchive, DATETIME(1, 1, 1))) <> DATETIME(1, 1, 1)
           |				THEN CAST(1 AS NUMBER(17, 0))
           |			ELSE 0
           |		END) > 0 AS SubjectToRecoveryDueToNewFiles
           |INTO TT_DeduplicatedFiles
           |FROM
           |	VT_DataForCheckingDeduplication AS VT_DataForCheckingDeduplication
           |		INNER JOIN InformationRegister.FileRepository AS FileRepository
           |		ON VT_DataForCheckingDeduplication.BinaryDataStorage = FileRepository.BinaryDataStorage
           |		LEFT JOIN InformationRegister.FilesInfo AS FilesInfo
           |		ON (FileRepository.File = FilesInfo.File)
           |		LEFT JOIN Catalog.FilesVersions AS FilesVersions
           |		ON (FileRepository.File = FilesVersions.Ref)
           |			AND (NOT FilesVersions.Owner.DeletionMark)
           |WHERE
           |	NOT ISNULL(FilesInfo.DeletionMark, ISNULL(FilesVersions.DeletionMark, FALSE))
           |
           |GROUP BY
           |	FileRepository.BinaryDataStorage
           |
           |HAVING
           |	COUNT(*) > 1
           |
           |INDEX BY
           |	FileRepository.BinaryDataStorage
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |SELECT
           |	VT_PreparingDataForRecovery.AttachedFile AS AttachedFile,
           |	VT_PreparingDataForRecovery.FileStorageType AS FileStorageType,
           |	VT_PreparingDataForRecovery.Volume AS Volume,
           |	VT_PreparingDataForRecovery.PathToFile AS PathToFile,
           |	VT_PreparingDataForRecovery.BinaryDataStorage AS BinaryDataStorage,
           |	VT_PreparingDataForRecovery.Description AS Description,
           |	VT_PreparingDataForRecovery.Extension AS Extension,
           |	VT_PreparingDataForRecovery.FileForRecordingInformation AS FileForRecordingInformation,
           |	VT_PreparingDataForRecovery.VersionNumber AS VersionNumber,
           |	VT_PreparingDataForRecovery.FileOwner AS FileOwner,
           |	NOT VT_PreparingDataForRecovery.ThisIsOnDiskStorage AS ReceiveBinaryData,
           |	ISNULL(TT_DeduplicatedFiles.NumberOfDeduplicatedFiles, 0) AS NumberOfDeduplicatedFiles,
           |	ISNULL(InformationAboutStoringDeduplicatedFiles.FileStorageType, VALUE(Enum.FileStorageTypes.EmptyRef)) AS FileStorageTypeOperational,
           |	ISNULL(InformationAboutStoringDeduplicatedFiles.Volume, VALUE(Catalog.FileStorageVolumes.EmptyRef)) AS VolumeIsOperational,
           |	"""" AS PathToFileIsOperational,
           |	VT_PreparingDataForRecovery.FilePresentation AS FilePresentation
           |INTO VT_DataToTransfer
           |FROM
           |	VT_PreparingDataForRecovery AS VT_PreparingDataForRecovery
           |		LEFT JOIN TT_DeduplicatedFiles AS TT_DeduplicatedFiles
           |		ON VT_PreparingDataForRecovery.BinaryDataStorage = TT_DeduplicatedFiles.BinaryDataStorage
           |		LEFT JOIN InformationRegister.InformationAboutStoringDeduplicatedFiles AS InformationAboutStoringDeduplicatedFiles
           |		ON VT_PreparingDataForRecovery.BinaryDataStorage = InformationAboutStoringDeduplicatedFiles.BinaryDataStorage
           |			AND (InformationAboutStoringDeduplicatedFiles.TypeOfFileStorage = VALUE(Enum.TypesOfFileStorage.OperationalStorage))
           |WHERE
           |	(&RecoverAllFiles
           |			OR ISNULL(TT_DeduplicatedFiles.SubjectToRecoveryDueToNewFiles, FALSE)
           |			OR VT_PreparingDataForRecovery.PlannedDateOfTransferToArchive > &DateOfProcessing)
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |DROP VT_DataForCheckingDeduplication
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |DROP TT_DeduplicatedFiles
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |DROP VT_PreparingDataForRecovery";

	BatchQueryText.Add(QueryText);

	QueryText = StrConcat(BatchQueryText, Common.QueryBatchSeparator());

	If ExceptionsArray.Count() > 0 Then
		QueryText = StrReplace(QueryText, "&SelectionByExceptions", "NOT Files.FileOwner IN HIERARCHY (&ExceptionsArray)");
	Else 
		QueryText = StrReplace(QueryText, "&SelectionByExceptions", "TRUE");
	EndIf;

	If ExceptionItem <> Undefined Then
		QueryText = StrReplace(QueryText, "&SelectionBasedOnDetailedSettings", "Files.FileOwner IN HIERARCHY (&SelectionBasedOnDetailedSettings)");
	Else
		QueryText = StrReplace(QueryText, "&SelectionBasedOnDetailedSettings", "TRUE");
	EndIf;

	If FilesObjectMetadata.Hierarchical Then
		QueryText = StrReplace(QueryText, "&ThisIsNotGroup", "NOT Files.IsFolder");
	Else
		QueryText = StrReplace(QueryText, "&ThisIsNotGroup", "TRUE");
	EndIf;

	Return QueryText;

EndFunction

Procedure TransferFilesToFileArchive(Setting, ExceptionsArray, NumberOfDaysOfOperationalStorage, AdditionalTransferParameters)

	If Setting.Action = Enums.ActionsInFileArchiveWorkSettings.NotTransferToArchive Then
		Return;
	EndIf;

	TempTablesManager = New TempTablesManager;

	FillingInTemporaryTableForTransferringFiles(Setting, ExceptionsArray, NumberOfDaysOfOperationalStorage, TempTablesManager);

	InformationForVolumeSelection	= InformationAboutFilesForVolumeSelection();
	InformationAboutStorageVolume	= Undefined;

	LastRef = EmptyLinkToAttachedFile(Setting);

	FilesToTransfer = NextBatchOfFiles(TempTablesManager, LastRef, AdditionalTransferParameters.QueryTextForReceivingPortionOfFilesToTransferToArchive);

	While FilesToTransfer.Count() > 0 Do

		ErrorDescriptionString = ErrorDescriptionStringOfOperationsWithTemporaryDirectory(True);

		For Each ProcessedFile In FilesToTransfer Do

			If ProcessedFile.NumberOfDeduplicatedFiles > 0 Then
				If Not ProcessedFile.SubjectToConditionalTransfer Then
					If ProcessedFile.FileBeingEdited Then
						Continue;
					EndIf;
					
					//@skip-warning Query выполняется не для всех итераций цикла.
					If FileHasBeenTransferredToFileArchive(ProcessedFile.AttachedFile) Then
						Continue;
					EndIf;
				ElsIf ProcessedFile.ConditionallyTransferredToArchive Then
					Continue;
				EndIf;
			EndIf;
			
			TempDirectory = NewTemporaryDirectoryForWorkingWithZipArchive(ErrorDescriptionString);
			
			AttachedFileRef = ProcessedFile.AttachedFile;
			
			Block = New DataLock;
			DataLockItem = Block.Add(AttachedFileRef.Metadata().FullName());
			DataLockItem.SetValue("Ref", AttachedFileRef);
			
			DataLockItem = Block.Add(Metadata.InformationRegisters.FilesInfo.FullName());
			DataLockItem.SetValue("File", AttachedFileRef);
			
			DataLockItem = Block.Add(Metadata.InformationRegisters.FileRepository.FullName());
			DataLockItem.SetValue("File", AttachedFileRef);

			BeginTransaction();			
			Try   

				Block.Lock();

				If ProcessedFile.SubjectToConditionalTransfer Then

					If Not ProcessedFile.ConditionallyTransferredToArchive Then

						PerformConditionalFileTransfer(ProcessedFile);

					EndIf;

				Else			

					OperationParametersList = ParametersOfTransferOfOperationExecution();
					OperationParametersList.TempDirectory	= TempDirectory;

					NewZipArchive = ZipArchiveOfFileToBeTransferred(ProcessedFile, OperationParametersList);

					FileSize = NewZipArchive.Size;
					// A deduplicated file may be transferred to a disk volume.
					// In this case, a copy of each deduplicated file will be stored on disk.
					// Therefore, when selecting a storage volume, the total required free space is taken into account.
					InformationForVolumeSelection.Size = Max(1, ProcessedFile.NumberOfDeduplicatedFiles) * FileSize;

					If InformationAboutStorageVolume = Undefined 
							Or InformationAboutStorageVolume.MaximumSize <> 0 And InformationAboutStorageVolume.FreeVolume_ - InformationForVolumeSelection.Size < 0 Then
						// File archives can contain only disk volumes or S3 volumes; therefore, the value VolumeUndefinedInVolumes is used.
						InformationAboutStorageVolume = SelectStorageVolume(InformationForVolumeSelection, 
																	Enums.TypesOfFileStorage.ArchivalStorage,
																	Enums.FileStorageTypes.InVolumesVolumeIsNotDefined);
					EndIf;

					OperationParametersList.InformationAboutStorageVolume = InformationAboutStorageVolume;

					// @skip-check query-in-loop - 
					TransferFileToFileArchive(ProcessedFile, NewZipArchive, OperationParametersList);

					If InformationAboutStorageVolume.MaximumSize <> 0 Then

						// If a file is transferred to a volume that stores data on a disk partition, the volume
						// space is reduced by the file size, since files in such volumes are deduplicated.
						If InformationAboutStorageVolume.NewFileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
							FileSize = InformationForVolumeSelection.Size;
						EndIf;

						InformationAboutStorageVolume.FreeVolume_ = InformationAboutStorageVolume.FreeVolume_ - FileSize;

					EndIf;				
				EndIf;
				CommitTransaction();
			Except
				RollbackTransaction();

				ExceptionString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				RecordFileTransferEventInRegistrationLog(ExceptionString, EventLogLevel.Error);
				
				DeleteTemporaryDirectory(TempDirectory, ErrorDescriptionString);
				Continue;				
			EndTry;
		EndDo;

		DeleteTemporaryDirectory(TempDirectory, ErrorDescriptionString);

		LastRef = ProcessedFile.AttachedFile;

		// @skip-check query-in-loop - 
		FilesToTransfer = NextBatchOfFiles(TempTablesManager, LastRef, AdditionalTransferParameters.QueryTextForReceivingPortionOfFilesToTransferToArchive);

	EndDo;

EndProcedure

Function InformationAboutStorageVolume()

	Result = New Structure;
	Result.Insert("Ref"					, Catalogs.FileStorageVolumes.EmptyRef());
	Result.Insert("MaximumSize"		, 0);
	Result.Insert("FreeVolume_"			, 0);
	Result.Insert("VolumePath"				, "");
	Result.Insert("NewFileStorageType"	, Enums.FileStorageTypes.EmptyRef());

	Return Result;

EndFunction

Function SelectStorageVolume(AttachedFile, TypeOfFileStorageVolume, FileStorageType)

	NewFileStorageType = FileStorageType;

	Result = InformationAboutStorageVolume();

	FreeVolume = FreeStorageVolumeByFileStorageType(AttachedFile, NewFileStorageType, TypeOfFileStorageVolume);
	If NewFileStorageType = Enums.FileStorageTypes.InVolumesVolumeIsNotDefined Then
		NewFileStorageType = StorageTypeByFileStorageVolume(FreeVolume);
	EndIf;	

	VolumeAttributeValues = Common.ObjectAttributesValues(FreeVolume, "Ref, MaximumSize");

	Result.Ref				= VolumeAttributeValues.Ref;
	Result.MaximumSize	= VolumeAttributeValues.MaximumSize;

	If Result.MaximumSize <> 0 Then

		Result.FreeVolume_ = Result.MaximumSize * 1024 * 1024 - FilesOperationsInVolumesInternal.VolumeSize(FreeVolume);

	EndIf;

	Result.NewFileStorageType = NewFileStorageType;
	If NewFileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
		Result.VolumePath = FilesOperationsInVolumesInternal.FullVolumePath(FreeVolume);
	EndIf;

	Return Result;

EndFunction

Procedure RecoverFileFromFileArchive(ProcessedFile, ExtractedFile, OperationParametersList)

	AttributesToChange = New Structure;
	AttributesToChange.Insert("Volume"						, OperationParametersList.InformationAboutStorageVolume.Ref);
	AttributesToChange.Insert("FileStorageType"			, OperationParametersList.InformationAboutStorageVolume.NewFileStorageType);
	AttributesToChange.Insert("ConditionallyTransferredToArchive"	, False); // Reset the archivation flag
	AttributesToChange.Insert("DateOfTransferToArchive"		, Date(1,1,1));	

	If OperationParametersList.InformationAboutStorageVolume.NewFileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then

		If ProcessedFile.NumberOfDeduplicatedFiles = 0 Then

			RestoreExtractedFileToOperatingVolumeOnDisk(ProcessedFile, ExtractedFile, OperationParametersList);

			DeleteSourceFile = False;

			If ProcessedFile.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
				DeleteSourceFile = True;
			Else
				InformationRegisters.FileRepository.DeleteBinaryData(ProcessedFile.AttachedFile);
			EndIf;

			AttributesToChange.Insert("PathToFile", OperationParametersList.NewPathToFileInsideVolume);
			ChangeAttributesOfAttachedFile(ProcessedFile, AttributesToChange);

			If DeleteSourceFile Then
				FilesOperationsInVolumesInternal.DeleteFile(OperationParametersList.OriginalFilePath);
			EndIf;

		Else

			DeduplicatedFiles = DeduplicatedFilesByBinaryDataStorage(ProcessedFile.BinaryDataStorage, True);

			For Each DeduplicatedFile In DeduplicatedFiles Do

				RestoreExtractedFileToOperatingVolumeOnDisk(DeduplicatedFile, ExtractedFile, OperationParametersList);
				InformationRegisters.FileRepository.DeleteBinaryData(DeduplicatedFile.AttachedFile);

				AttributesToChange.Insert("PathToFile", OperationParametersList.NewPathToFileInsideVolume);
				ChangeAttributesOfAttachedFile(DeduplicatedFile, AttributesToChange);

			EndDo;
		EndIf;

	Else

		AttributesToChange.Insert("PathToFile", "");
		BinaryDataOfProcessedFile = New BinaryData(ExtractedFile.FileName);

		RecordingParametersVIB = ParametersOfEntryInInformationDatabase();
		FillPropertyValues(RecordingParametersVIB, AttributesToChange);

		If ProcessedFile.NumberOfDeduplicatedFiles = 0 Then

			DeleteSourceFile = False;			

			If ProcessedFile.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then

				If OperationParametersList.ReceivedStorageParameters Then
					// The operational storage parameters have already been retrieved, so we only need to update the attachment attributes
					// and add an entry to the FileRepository information register. The binary data remains unchanged.
					RecordingParametersVIB.DoNotModifyBinaryData = True;
				EndIf;

				InformationRegisters.FileRepository.WriteBinaryData(ProcessedFile.AttachedFile, BinaryDataOfProcessedFile, RecordingParametersVIB);

				DeleteSourceFile = True;
			Else
				RestoreFileToOnlineStorage(ProcessedFile.BinaryDataStorage, BinaryDataOfProcessedFile, OperationParametersList);
			EndIf;

			ChangeAttributesOfAttachedFile(ProcessedFile, AttributesToChange);

			If DeleteSourceFile Then
				FilesOperationsInVolumesInternal.DeleteFile(OperationParametersList.OriginalFilePath);
			EndIf;
			
		Else

			RestoreFileToOnlineStorage(ProcessedFile.BinaryDataStorage, BinaryDataOfProcessedFile, OperationParametersList);

			DeduplicatedFiles = DeduplicatedFilesByBinaryDataStorage(ProcessedFile.BinaryDataStorage, True);

			For Each DeduplicatedFile In DeduplicatedFiles Do
				ChangeAttributesOfAttachedFile(DeduplicatedFile, AttributesToChange);
			EndDo;
		EndIf
	EndIf;

EndProcedure

Procedure RestoreFileToOnlineStorage(Var_BinaryDataStorage, BinaryData, OperationParametersList)

	FileStorageType = OperationParametersList.InformationAboutStorageVolume.NewFileStorageType;

	ValuesOfStorageAttributes = New Structure;
	ValuesOfStorageAttributes.Insert("BinaryDataInArchive", Undefined);	

	If Not OperationParametersList.ReceivedStorageParameters Then

		AddChangeableBinaryDataStorageAttributes(ValuesOfStorageAttributes, FileStorageType, BinaryData);

		RecordingParametersVIB = ParametersOfEntryInInformationDatabase();	
		RecordingParametersVIB.FileStorageType			= FileStorageType;
		RecordingParametersVIB.Volume						= OperationParametersList.InformationAboutStorageVolume.Ref;

		InformationRegisters.InformationAboutStoringDeduplicatedFiles.AddRecord(Var_BinaryDataStorage, RecordingParametersVIB);
	EndIf;

	WriteBinaryDataToInformationBase(Var_BinaryDataStorage, ValuesOfStorageAttributes);	

	InformationRegisters.InformationAboutStoringDeduplicatedFiles.DeleteRecord(Var_BinaryDataStorage, Enums.TypesOfFileStorage.ArchivalStorage);												

EndProcedure

Procedure TransferFileToFileArchive(ProcessedFile, ZipArchive, OperationParametersList)

	AttributesToChange = New Structure;
	AttributesToChange.Insert("Volume"						, OperationParametersList.InformationAboutStorageVolume.Ref);
	AttributesToChange.Insert("FileStorageType"			, OperationParametersList.InformationAboutStorageVolume.NewFileStorageType);
	AttributesToChange.Insert("ConditionallyTransferredToArchive"	, False);
	AttributesToChange.Insert("DateOfTransferToArchive"		, CurrentSessionDate());	

	If OperationParametersList.InformationAboutStorageVolume.NewFileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then

		If ProcessedFile.NumberOfDeduplicatedFiles = 0 Then

			TransferZipArchiveToArchiveVolumeOnDisk(ProcessedFile, ZipArchive, OperationParametersList);			

			DeleteSourceFile = False;
			If ProcessedFile.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
				DeleteSourceFile = True;
			Else
				InformationRegisters.FileRepository.DeleteBinaryData(ProcessedFile.AttachedFile);
			EndIf;

			AttributesToChange.Insert("PathToFile", OperationParametersList.NewPathToFileInsideVolume);
			ChangeAttributesOfAttachedFile(ProcessedFile, AttributesToChange);

			If DeleteSourceFile Then
				FilesOperationsInVolumesInternal.DeleteFile(OperationParametersList.OriginalFilePath);
			EndIf;
		Else

			DeduplicatedFiles = DeduplicatedFilesByBinaryDataStorage(ProcessedFile.BinaryDataStorage);

			For Each DeduplicatedFile In DeduplicatedFiles Do

				TransferZipArchiveToArchiveVolumeOnDisk(DeduplicatedFile, ZipArchive, OperationParametersList);
				InformationRegisters.FileRepository.DeleteBinaryData(DeduplicatedFile.AttachedFile);

				AttributesToChange.Insert("PathToFile", OperationParametersList.NewPathToFileInsideVolume);				
				ChangeAttributesOfAttachedFile(DeduplicatedFile, AttributesToChange);

			EndDo;
		EndIf;
	Else
        // Transfer to S3 archive storage
		// If the file was stored in internal storage, only the storage attribute is updated.
		// If the file was stored on disk, the system locates or creates a BinaryDataStorage and
		// adds a record to FileRepository information register.

		AttributesToChange.Insert("PathToFile", "");

		If ProcessedFile.NumberOfDeduplicatedFiles = 0 Then

			DeleteSourceFile = False;

			If ProcessedFile.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
				// Transfer the file from the disk to the internal storage. (Should be checked for deduplicated elements.)
				BinaryDataOfProcessedFile = New BinaryData(OperationParametersList.OriginalFilePath);
				BinaryDataStorageRef = BinaryDataStorageElementForBinaryData(BinaryDataOfProcessedFile);

				If BinaryDataStorageRef <> Undefined Then
					If BinaryDataStoreIsPresentInFileArchive(BinaryDataStorageRef) Then
						// The common binary data storage has been moved to the archive, so no transfer is required.
						// The attachment's storage parameters are updated using data from DeduplicatedFilesStorageInformation.
						// Attribute TransferToArchiveDate is set to the current session date.
						TypeOfStorageOfDeduplicatedFiles = Enums.TypesOfFileStorage.ArchivalStorage;
					Else
						// The common binary data storage is absent from the archive, so no transfer is required.
						// The attachment's storage parameters are updated using data from DeduplicatedFilesStorageInformation.
						// Attribute TransferToArchiveDate is cleared, and MarkedAsArchived is set to True.
						TypeOfStorageOfDeduplicatedFiles = Enums.TypesOfFileStorage.OperationalStorage;
						AttributesToChange.Insert("ConditionallyTransferredToArchive"	, True);
						AttributesToChange.Insert("DateOfTransferToArchive"		, Date(1,1,1));
					EndIf;

					InformationAboutFileStorage = InformationRegisters.InformationAboutStoringDeduplicatedFiles.InformationAboutStoringDeduplicatedFiles(
																								BinaryDataStorageRef,
																								TypeOfStorageOfDeduplicatedFiles);

					If InformationAboutFileStorage = Undefined Then

						Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
														"en = 'The ""Deduplicated file storage information"" information register is missing an entry
														|for the ""Binary data storage"" catalog: %1. Storage method: %2'"),
														BinaryDataStorageRef,
														TypeOfStorageOfDeduplicatedFiles);
					EndIf;
					
					FillPropertyValues(AttributesToChange, InformationAboutFileStorage);
					
					InformationRegisters.FileRepository.AddRecord(ProcessedFile.AttachedFile, BinaryDataStorageRef);
					
				Else
					// Create in the BinaryDataStorage catalog a new item whose binary data will be stored in the file archive.
					RecordingParametersVIB = ParametersOfEntryInInformationDatabase();
					FillPropertyValues(RecordingParametersVIB,AttributesToChange);
					RecordingParametersVIB.ThisIsEntryInFileArchive = True;
					RecordingParametersVIB.BinaryDataOfArchive = New BinaryData(ZipArchive.FileName);
					
					InformationRegisters.FileRepository.WriteBinaryData(ProcessedFile.AttachedFile, BinaryDataOfProcessedFile, RecordingParametersVIB);
				EndIf;

				DeleteSourceFile = True;
			Else
				// Deduplication is not supported for disk storage. Therefore, for a file with a different storage type,
				// a BinaryDataStorage catalog item has already been created. The data must be moved from the operational storage attribute
				// to the archival storage attribute, and the attachment's attributes must be updated.
				TransferZipArchiveToArchiveVolumeS3Storage(ProcessedFile, ZipArchive, OperationParametersList);
			EndIf;

			ChangeAttributesOfAttachedFile(ProcessedFile, AttributesToChange);

			If DeleteSourceFile Then
				FilesOperationsInVolumesInternal.DeleteFile(OperationParametersList.OriginalFilePath);
			EndIf;

		Else
			// Deduplication is not supported for disk storage. Therefore, the presence of other deduplicated files indicates that
			// a BinaryDataStorage directory item has already been created. You should move the binary data from the operational storage attribute to
			// the archive storage attribute and update the attributes of all deduplicated files by setting the storage parameters and
			// the TransferToArchiveDate attribute.
			TransferZipArchiveToArchiveVolumeS3Storage(ProcessedFile, ZipArchive, OperationParametersList);

			DeduplicatedFiles = DeduplicatedFilesByBinaryDataStorage(ProcessedFile.BinaryDataStorage);

			For Each DeduplicatedFile In DeduplicatedFiles Do

				ChangeAttributesOfAttachedFile(DeduplicatedFile, AttributesToChange);

			EndDo;
		EndIf;
	EndIf;

EndProcedure

Function ParametersOfTransferOfOperationExecution()

	Result = New Structure;
	Result.Insert("InformationAboutStorageVolume");
	Result.Insert("ZipArchiveNameWithoutExtension"	, "");
	Result.Insert("ZipArchiveExtension"		, "");
	Result.Insert("NewPathToFileInsideVolume"	, "");
	Result.Insert("OriginalFilePath"			, "");
	Result.Insert("TempDirectory"			, "");

	Return Result;

EndFunction

Function ParametersForPerformingRecoveryOfOperation()

	Result = New Structure;
	Result.Insert("InformationAboutStorageVolume");
	Result.Insert("NewPathToFileInsideVolume"		, "");
	Result.Insert("OriginalFilePath"				, "");
	Result.Insert("TempDirectory"				, "");
	Result.Insert("ReceivedStorageParameters"		, False);
	Result.Insert("FilesStorageMethod"			, "");

	Return Result;

EndFunction

Procedure AddChangeableBinaryDataStorageAttributes(AttributesToChange, FileStorageType, AttributeValue = Undefined)

	AttributeName = WorkingWithFilesInBinaryDataWarehouseIsService.DetermineAttributesOfBinaryDataStorageByFileStorageType(FileStorageType);
	If AttributeName <> Undefined Then
		AttributesToChange.Insert(AttributeName, AttributeValue);
	EndIf;

EndProcedure

Procedure WriteBinaryDataToInformationBase(Var_BinaryDataStorage, ValuesOfStorageAttributes)

	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);

	BeginTransaction();
	Try

		If ValuesOfStorageAttributes.Property("BinaryData") Then

			Block = New DataLock;
			Block.Add("Catalog.BinaryDataStorage").SetValue("Ref", Var_BinaryDataStorage);
			Block.Lock();

			BinaryDataStorageObject = Var_BinaryDataStorage.GetObject();
			BinaryDataStorageObject.Lock();
			
			BinaryDataStorageObject.BinaryData = PrepareBinaryDataForRecording(ValuesOfStorageAttributes.BinaryData);
			BinaryDataStorageObject.Write();

		EndIf;
		
		If UseBinaryDataStorageLocations(ValuesOfStorageAttributes) Then

			ValuesOfRecordAttributes = New Structure;
			For Each AttributeValue In ValuesOfStorageAttributes Do
				
				If AttributeValue.Key <> "BinaryData" Then
					ValuesOfRecordAttributes.Insert(AttributeValue.Key, PrepareBinaryDataForRecording(AttributeValue.Value));
				EndIf;
				
			EndDo;

			InformationRegisters.BinaryDataStorageLocations.AddEditEntry(Var_BinaryDataStorage, ValuesOfRecordAttributes);
		EndIf;

		CommitTransaction();	
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

Function UseBinaryDataStorageLocations(ValuesOfStorageAttributes)

	For Each ValueOfStorageAttribute In ValuesOfStorageAttributes Do
		If ValueOfStorageAttribute.Key = "BinaryDataInArchive"
				Or ValueOfStorageAttribute.Key = "BinaryDataInOperationalBuiltInStorage"
				Or ValueOfStorageAttribute.Key = "BinaryDataInOperationalExternalStorage" Then
			Return True;
		EndIf;
	EndDo;

	Return False;	

EndFunction

Procedure RestoreExtractedFileToOperatingVolumeOnDisk(ProcessedFile, ExtractedFile, OperationParametersList)

	PathToSourceFile = ExtractedFile.FileName;

	FileProperties = FilesOperationsInVolumesInternal.FilePropertiesInVolume();
	FileProperties.Description	= ProcessedFile.Description;
	FileProperties.Extension	= ProcessedFile.Extension;
	FileProperties.Volume			= OperationParametersList.InformationAboutStorageVolume.Ref;
	FileProperties.PathToFile	= "";
	FileProperties.VersionNumber	= ProcessedFile.VersionNumber;
	FileProperties.FileOwner = ProcessedFile.FileOwner;

	PathToCopyFile = FilesOperationsInVolumesInternal.FullFileNameInVolume(FileProperties);

	OperationParametersList.NewPathToFileInsideVolume = Mid(PathToCopyFile, StrLen(OperationParametersList.InformationAboutStorageVolume.VolumePath) + 1);

	CopyVerificationFile(PathToSourceFile, PathToCopyFile);
	
EndProcedure

Procedure CopyVerificationFile(PathToSourceFile, PathToCopyFile)
		
	SourceFileSize = FileSize(PathToSourceFile);
	
	CopyFile(PathToSourceFile, PathToCopyFile);
	
	CopyFileSize = FileSize(PathToCopyFile);

	If SourceFileSize <> CopyFileSize Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'The size of the original and copied file does not match
					|		
					|Original file
					|Path: %1
					|Size: %2
					|
					|Copied file
					|Path: %3
					|Size: %4'"), PathToSourceFile, SourceFileSize, PathToCopyFile, CopyFileSize);
	EndIf;
	
EndProcedure

Procedure TransferZipArchiveToArchiveVolumeOnDisk(ProcessedFile, ZipArchive, OperationParametersList, GenerateNewZipArchiveName = False)

	PathToSourceFile = ZipArchive.FileName;
	
	FileProperties = FilesOperationsInVolumesInternal.FilePropertiesInVolume();
	FileProperties.Description	= ?(GenerateNewZipArchiveName, FileNameOfNewZipArchive(), OperationParametersList.ZipArchiveNameWithoutExtension);
	FileProperties.Extension	= OperationParametersList.ZipArchiveExtension;
	FileProperties.Volume			= OperationParametersList.InformationAboutStorageVolume.Ref;
	FileProperties.PathToFile	= "";
	FileProperties.VersionNumber	= ProcessedFile.VersionNumber;
	FileProperties.FileOwner = ProcessedFile.FileOwner;

	PathToCopyFile = FilesOperationsInVolumesInternal.FullFileNameInVolume(FileProperties);

	OperationParametersList.NewPathToFileInsideVolume = Mid(PathToCopyFile, StrLen(OperationParametersList.InformationAboutStorageVolume.VolumePath) + 1);

	CopyVerificationFile(PathToSourceFile, PathToCopyFile);

EndProcedure

Procedure TransferZipArchiveToArchiveVolumeS3Storage(ProcessedFile, ZipArchive, OperationParametersList)

	ValuesOfStorageAttributes = New Structure;
	ValuesOfStorageAttributes.Insert("BinaryDataInArchive", New BinaryData(ZipArchive.FileName));
	AddChangeableBinaryDataStorageAttributes(ValuesOfStorageAttributes, ProcessedFile.FileStorageType);

	WriteBinaryDataToInformationBase(ProcessedFile.BinaryDataStorage, ValuesOfStorageAttributes);

	RecordingParametersVIB = ParametersOfEntryInInformationDatabase();	
	RecordingParametersVIB.FileStorageType			= OperationParametersList.InformationAboutStorageVolume.NewFileStorageType;
	RecordingParametersVIB.Volume						= OperationParametersList.InformationAboutStorageVolume.Ref;
	RecordingParametersVIB.ThisIsEntryInFileArchive	= True;

	InformationRegisters.InformationAboutStoringDeduplicatedFiles.AddRecord(
										ProcessedFile.BinaryDataStorage, 
										RecordingParametersVIB);

	InformationRegisters.InformationAboutStoringDeduplicatedFiles.DeleteRecord(ProcessedFile.BinaryDataStorage, Enums.TypesOfFileStorage.OperationalStorage);

EndProcedure

Function InformationAboutFilesForVolumeSelection()

	Result = New Structure;
	Result.Insert("Size"			, 0);
	Result.Insert("Description"	, "");
	Result.Insert("Extension"		, "");

	Return Result;

EndFunction

Function FileSize(PathToFile, RaiseException1 = True)

	Result = 0;

	File = New File(PathToFile);
	If File.Exists() Then
		Result = File.Size();
	ElsIf RaiseException1 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'File ""%1"" is not found.'"), PathToFile);		
	EndIf;

	Return Result;

EndFunction

Function PropertiesOfExtractedFile()

	Result = New Structure;
	Result.Insert("FileName"		, "");
	Result.Insert("NameWithExtension", "");
	Result.Insert("Size"			, 0);

	Return Result;

EndFunction

Function FileExtractedFromZipArchive(ProcessedFile, OperationParametersList)

	Result = PropertiesOfExtractedFile();

	Try

		TempDirectory = OperationParametersList.TempDirectory;

		If ProcessedFile.FileStorageType <> Enums.FileStorageTypes.InVolumesOnHardDrive Then
			
			BinaryZipArchiveData = FileBinaryData(ProcessedFile, False);

		Else
			PathToArchiveFile = FilesOperationsInVolumesInternal.FullFileNameInVolume(
											New Structure("Volume, PathToFile", ProcessedFile.Volume, ProcessedFile.PathToFile));

			FileOnHardDrive = New File(PathToArchiveFile);
			If Not FileOnHardDrive.Exists() Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'File ""%1"" is not found.'"), PathToArchiveFile);
			EndIf;

			OperationParametersList.OriginalFilePath = PathToArchiveFile;

			BinaryZipArchiveData = New BinaryData(PathToArchiveFile);
		EndIf;

		NameOfExtractedFile = CommonClientServer.GetNameWithExtension(ProcessedFile.Description, ProcessedFile.Extension);

		DataOfExtractedFile = ExtractFileFromZipArchive(BinaryZipArchiveData, NameOfExtractedFile, TempDirectory);

		Result.Size = DataOfExtractedFile.Size;

		Result.FileName			= DataOfExtractedFile.FileName;
		Result.NameWithExtension	= NameOfExtractedFile;

	Except
		ErrorDescriptionTemplate = NStr("en = 'Failed to extract file from ZIP archive.
			|Archive: %2
			|File: %1'");

		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorDescriptionTemplate,
			NameOfExtractedFile,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));

		Raise ExceptionString;
	EndTry;

	Return Result;

EndFunction

Function ZipArchiveOfFileToBeTransferred(ProcessedFile, OperationParametersList)

	Try	

		TempDirectory = OperationParametersList.TempDirectory;

		If ProcessedFile.FileStorageType <> Enums.FileStorageTypes.InVolumesOnHardDrive Then
			PathToArchivedFile = PathToFileBeingProcessedInTemporaryDirectory(ProcessedFile, TempDirectory);

			FileBinaryData = FileBinaryData(ProcessedFile);

			If TypeOf(FileBinaryData) <> Type("BinaryData") Then
				ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
														NStr("en = 'The file data has an invalid type.
															|Expected BinaryData, got %1'"), TypeOf(FileBinaryData));
				Raise ExceptionString;
			EndIf;
			
			FileBinaryData.Write(PathToArchivedFile);
		Else
			PathToArchivedFile = FilesOperationsInVolumesInternal.FullFileNameInVolume(
											New Structure("Volume, PathToFile", ProcessedFile.Volume, ProcessedFile.PathToFile));

			FileOnHardDrive = New File(PathToArchivedFile);
			If Not FileOnHardDrive.Exists() Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'File to add to archive not found: %1.'"), PathToArchivedFile);
			EndIf;											

			OperationParametersList.OriginalFilePath = PathToArchivedFile;
		EndIf;

		NameOfArchiveFileWithoutExtension = FileNameOfNewZipArchive();
		ArchiveFileName = CommonClientServer.GetNameWithExtension(NameOfArchiveFileWithoutExtension, "zip");

		PathToArchiveFile = TempDirectory + ArchiveFileName;

		NewZipArchive = PackFileIntoZipArchive(PathToArchiveFile, PathToArchivedFile);

		OperationParametersList.ZipArchiveNameWithoutExtension = NameOfArchiveFileWithoutExtension;
		OperationParametersList.ZipArchiveExtension		= "zip";

	Except	

		ErrorDescriptionTemplate = NStr("en = 'Couldn''t move file %1.
			|The ZIP archive was not created:
			|%2.'");

		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorDescriptionTemplate,
			ProcessedFile.Description + "." + ProcessedFile.Extension,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));

		Raise ExceptionString;

	EndTry;

	Return NewZipArchive;

EndFunction

Function FileNameOfNewZipArchive()

	Return String(New UUID);

EndFunction

Function FileBinaryData(ProcessedFile, ThisIsTransferToFileArchive = True)

	Result = ProcessedFile.FileBinaryData;

	If TypeOf(Result) = Type("ValueStorage") Then
		Result = Result.Get();
		If TypeOf(Result) = Type("BinaryData") Then
			Return Result;
		EndIf;
	EndIf;

	If ThisIsTransferToFileArchive Then
		If Not ValueIsFilled(Result) Or TypeOf(Result) <> Type("BinaryData") Then
			Result = FilesOperations.FileBinaryData(ProcessedFile.AttachedFile);
		EndIf;
	EndIf;

	Return Result;

EndFunction

Function PathToFileBeingProcessedInTemporaryDirectory(ProcessedFile, TempDirectory = "")

	SetPrivilegedMode(True);

	If TempDirectory = "" Then
		ErrorDescriptionString = ErrorDescriptionStringOfOperationsWithTemporaryDirectory(True);
		TempDirectory = NewTemporaryDirectoryForWorkingWithZipArchive(ErrorDescriptionString);
	EndIf;

	FileName = CommonClientServer.GetNameWithExtension(ProcessedFile.Description, ProcessedFile.Extension);

	Return TempDirectory + FileName;

EndFunction

Procedure PerformConditionalFileTransfer(ProcessedFile)

	AttributesToChange = New Structure;
	AttributesToChange.Insert("ConditionallyTransferredToArchive", True);
	ChangeAttributesOfAttachedFile(ProcessedFile, AttributesToChange);	

EndProcedure

Procedure ChangeAttributesOfAttachedFile(ProcessedFile, AttributesToChange)

	FileRef = ProcessedFile.AttachedFile;

	ThereAreAttributesThatAreMissingInAttributes = ThereAreAttributesThatAreMissingInAttributes(AttributesToChange, FileRef);
	
	Block = New DataLock;
	DataLockItem = Block.Add(FileRef.Metadata().FullName());
	DataLockItem.SetValue("Ref", FileRef);

	If ThereAreAttributesThatAreMissingInAttributes Then	
		DataLockItem = Block.Add(Metadata.InformationRegisters.FilesInfo.FullName());
		DataLockItem.SetValue("File", ProcessedFile.FileForRecordingInformation);
	EndIf;
	
	BeginTransaction();	
	Try

		Block.Lock();

		FileObject1 = FileRef.GetObject();
		FileObject1.Lock();
		
		FillPropertyValues(FileObject1, AttributesToChange);
		FileObject1.Write();

		If ThereAreAttributesThatAreMissingInAttributes Then

			SetOfPCRecords = InformationRegisters.FilesInfo.CreateRecordSet();
			SetOfPCRecords.Filter.File.Set(ProcessedFile.FileForRecordingInformation);
			SetOfPCRecords.Read();
			
			If SetOfPCRecords.Count() = 1 Then
				RsRecording = SetOfPCRecords[0];
			Else
				RsRecording = SetOfPCRecords.Add();
			EndIf;
			
			If Not ValueIsFilled(RsRecording.File) Then
				RsRecording.File = ProcessedFile.FileForRecordingInformation;
				FillPropertyValues(RsRecording, ProcessedFile.FileForRecordingInformation);
			EndIf;

			FillPropertyValues(RsRecording, AttributesToChange);		

			SetOfPCRecords.Write();

		EndIf;

		CommitTransaction();

	Except
		RollbackTransaction();

		NameForLog = CommonClientServer.GetNameWithExtension(ProcessedFile.Description,
			ProcessedFile.Extension);

		Error = DataProcessors.FileTransfer.TransferError(FileRef, ErrorInfo());
		Error.FileName = NameForLog;

		PresentationOfFileLink = PresentationOfAttachedFile(FileRef, ProcessedFile.FilePresentation);
		
		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
															NStr("en = 'Couldn''t move file %1
															|%2
															|due to:
															|%3"".'"),
															PresentationOfFileLink, 
															NameForLog, Error.DetailErrorDescription);

		Raise ExceptionString;

	EndTry;		

EndProcedure

Function PresentationOfAttachedFile(AttachedFileRef, FilePresentation)
	
	AttachedFileMetadata = AttachedFileRef.Metadata();

	ObjectPresentation = AttachedFileMetadata.ObjectPresentation;
	If IsBlankString(ObjectPresentation) Then
		ObjectPresentation = AttachedFileMetadata.Presentation();
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", FilePresentation, ObjectPresentation);	

EndFunction

Function ThereAreAttributesThatAreMissingInAttributes(AttributesToChange, FileRef)

	Result = False;
	
	Attributes = FileRef.Metadata().Attributes;
	For Each Attribute In AttributesToChange Do
		If Attributes.Find(Attribute.Key) = Undefined Then
			Result = True;
			Break;
		EndIf;
	EndDo;

	Return Result;

EndFunction

Function EmptyLinkToAttachedFile(Setting)

	If Setting.IsFile Then
		Result = Catalogs.FilesVersions.EmptyRef();
	Else
		Result = Common.ObjectAttributeValue(Setting.FileOwnerType, "EmptyRefValue");
	EndIf;

	Return Result;

EndFunction

Procedure FillingInTemporaryTableForTransferringFiles(ConfiguringFileTransfer, ExceptionsArray, NumberOfDaysOfOperationalStorage, TempTablesManager)

	SetPrivilegedMode(True);

	If ConfiguringFileTransfer.ThisIsDetailedFileTransferSetup Then
		FileOwner		= ConfiguringFileTransfer.OwnerID;
		ExceptionItem	= ConfiguringFileTransfer.FileOwner;
	Else
		FileOwner		= ConfiguringFileTransfer.FileOwner;
		ExceptionItem	= Undefined;
	EndIf;	

	QueryText = QueryTextForTransferringFilesToFileArchive(FileOwner, ConfiguringFileTransfer, ExceptionsArray, ExceptionItem);

	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;

	Query.SetParameter("OwnerType"	, TypeOf(Common.ObjectAttributeValue(FileOwner, "EmptyRefValue")));
	Query.SetParameter("DaysCount"	, NumberOfDaysOfOperationalStorage);
	Query.SetParameter("DateOfProcessing"	, CurrentSessionDate());
	
	EmptyUsers = New Array;
	EmptyUsers.Add(Undefined);
	EmptyUsers.Add(Catalogs.Users.EmptyRef());
	EmptyUsers.Add(Catalogs.ExternalUsers.EmptyRef());
	EmptyUsers.Add(Catalogs.FileSynchronizationAccounts.EmptyRef());
	
	Query.SetParameter("EmptyUsers", EmptyUsers);

	If ExceptionsArray.Count() > 0 Then

		Query.SetParameter("ExceptionsArray", ExceptionsArray);

	EndIf;

	If ConfiguringFileTransfer.ThisIsDetailedFileTransferSetup Then

		Query.SetParameter("SelectionBasedOnDetailedSettings", ExceptionItem);

	EndIf;	

	Query.Execute();

EndProcedure

Function NextBatchOfFiles(TempTablesManager, LastRef, QueryText)

	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryText;
	Query.SetParameter("LastRef", LastRef);

	Return Query.Execute().Unload();

EndFunction

Function QueryTextOfPortionOfFiles(PortionSize, ThisIsTransferToFileArchive = True)

	Result = 
       "SELECT TOP 10
       |	VT_DataToTransfer.AttachedFile AS AttachedFile,
       |	VT_DataToTransfer.FilePresentation AS FilePresentation,	   
       |	VT_DataToTransfer.FileStorageType AS FileStorageType,
       |	VT_DataToTransfer.BinaryDataStorage AS BinaryDataStorage,
       |	VT_DataToTransfer.Volume AS Volume,
       |	VT_DataToTransfer.PathToFile AS PathToFile,
       |	VT_DataToTransfer.Description AS Description,
       |	VT_DataToTransfer.Extension AS Extension,
       |	VT_DataToTransfer.NumberOfDeduplicatedFiles AS NumberOfDeduplicatedFiles,
       |	VT_DataToTransfer.FileForRecordingInformation AS FileForRecordingInformation,
       |	VT_DataToTransfer.VersionNumber AS VersionNumber,
       |	VT_DataToTransfer.FileOwner AS FileOwner,
       |	&AdditionalFields AS AdditionalFields,
       |	&BinaryDataField AS FileBinaryData
       |FROM
       |	VT_DataToTransfer AS VT_DataToTransfer
       |		LEFT JOIN Catalog.BinaryDataStorage AS BinaryDataWarehouseCatalog
       |		ON VT_DataToTransfer.BinaryDataStorage = BinaryDataWarehouseCatalog.Ref
       |			AND (VT_DataToTransfer.ReceiveBinaryData)
       |		LEFT JOIN InformationRegister.BinaryDataStorageLocations AS BinaryDataStorageLocations
       |		ON VT_DataToTransfer.BinaryDataStorage = BinaryDataStorageLocations.BinaryDataStorage
       |WHERE
       |	VT_DataToTransfer.AttachedFile > &LastRef
       |
       |ORDER BY
       |	AttachedFile";
	
	If ThisIsTransferToFileArchive Then

		Result = StrReplace(Result, "&BinaryDataField", 
	       "ISNULL(CASE
	       |			WHEN VT_DataToTransfer.FileStorageType = VALUE(Enum.FileStorageTypes.InInfobase)
	       |				THEN BinaryDataWarehouseCatalog.BinaryData
	       |			WHEN VT_DataToTransfer.FileStorageType = VALUE(Enum.FileStorageTypes.InBuiltInBinaryDataStorage)
		   |				THEN ISNULL(BinaryDataStorageLocations.BinaryDataInOperationalBuiltInStorage, UNDEFINED)
	       |			WHEN VT_DataToTransfer.FileStorageType = VALUE(Enum.FileStorageTypes.InExternalBinaryDataStorage)
	       |		   		THEN ISNULL(BinaryDataStorageLocations.BinaryDataInOperationalExternalStorage, UNDEFINED)
	       |			ELSE UNDEFINED
	       |		END, UNDEFINED)");

		Result = StrReplace(Result, "&AdditionalFields AS AdditionalFields", 
			"VT_DataToTransfer.ConditionallyTransferredToArchive AS ConditionallyTransferredToArchive,
	       	|	VT_DataToTransfer.SubjectToConditionalTransfer AS SubjectToConditionalTransfer,
			|	VT_DataToTransfer.FileBeingEdited AS FileBeingEdited");

	Else
		Result = StrReplace(Result, "&BinaryDataField", "ISNULL(BinaryDataStorageLocations.BinaryDataInArchive, UNDEFINED)");

		Result = StrReplace(Result, "&AdditionalFields AS AdditionalFields",
			"VT_DataToTransfer.FileStorageTypeOperational AS FileStorageTypeOperational,
			|	VT_DataToTransfer.VolumeIsOperational AS VolumeIsOperational,
			|	VT_DataToTransfer.PathToFileIsOperational AS PathToFileIsOperational");
	EndIf;

	If PortionSize <> 10 Then
		Result = StrReplace(Result, "10", Format(PortionSize, "NG=0"));
	EndIf;	

	Return Result;

EndFunction

Function QueryTextForTransferringFilesToFileArchive(FileOwner, Setting, ExceptionsArray, ExceptionItem)

	FilesCatalogAttributes = Common.ObjectAttributesValues(Setting.FileOwnerType, "FullName, Name");

	FilesOwnerMedatada = Common.MetadataObjectByID(FileOwner);
	FilesOwnerFullName = FilesOwnerMedatada.FullName();

	FilesObjectMetadata = Common.MetadataObjectByID(Setting.FileOwnerType);
	HasAbilityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", FilesObjectMetadata);

	BatchQueryText = New Array;

	If HasAbilityToStoreVersions Then

		FilesVersionsCatalog	= Common.MetadataObjectID(FilesObjectMetadata.Attributes.CurrentVersion.Type.Types()[0]);
		FilesVersionsMetadata	= Common.MetadataObjectByID(FilesVersionsCatalog);

		FullFilesVersionsCatalogName = FilesVersionsMetadata.FullName();

		QueryText = 
           "SELECT
           |	FilesVersions.Ref AS AttachedFile,
           |	FilesVersions.FileStorageType AS FileStorageType,
           |	FilesVersions.Volume AS Volume,
           |	FilesVersions.PathToFile AS PathToFile,
           |	ISNULL(FileRepository.BinaryDataStorage, VALUE(Catalog.BinaryDataStorage.EmptyRef)) AS BinaryDataStorage,
           |	FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive) AS ThisIsOnDiskStorage,
           |	FilesVersions.Description AS Description,
           |	FilesVersions.Extension AS Extension,
           |	FilesVersions.Owner AS FileForRecordingInformation,
           |	FilesVersions.VersionNumber AS VersionNumber,
           |	Files.FileOwner AS FileOwner,
           |	FilesVersions.ConditionallyTransferredToArchive AS ConditionallyTransferredToArchive,
           |	FilesVersions.Presentation AS FilePresentation
           |INTO VT_PreparingDataForTransfer
           |FROM
           |	#FullFilesCatalogName AS Files
           |		INNER JOIN #FullFilesVersionsCatalogName AS FilesVersions
           |		ON Files.Ref = FilesVersions.Owner
           |			AND (NOT Files.DeletionMark)
           |			AND (NOT FilesVersions.DeletionMark)
           |			AND (&ThisIsNotGroup)
           |			AND (VALUETYPE(Files.FileOwner) = &OwnerType)
           |			AND (&SelectionBasedOnDetailedSettings)
           |			AND (&SelectionByExceptions)
           |			AND (CASE
           |				WHEN FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
           |					THEN (CAST(FilesVersions.PathToFile AS STRING(100))) <> """"
           |							OR NOT FilesVersions.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				WHEN FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InBuiltInBinaryDataStorage)
           |						OR FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InExternalBinaryDataStorage)
           |					THEN NOT FilesVersions.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				ELSE TRUE
           |			END)
           |			AND (DATEADD(FilesVersions.CreationDate, DAY, &DaysCount) <= &DateOfProcessing)
           |			AND (FilesVersions.DateOfTransferToArchive = DATETIME(1,1,1))
           |			AND (Files.CurrentVersion <> FilesVersions.Ref
           |				OR Files.BeingEditedBy IN (&EmptyUsers))
           |		LEFT JOIN InformationRegister.FileRepository AS FileRepository
           |		ON (FilesVersions.Ref = FileRepository.File)";

		QueryText = StrReplace(QueryText, "#FullFilesCatalogName", FilesCatalogAttributes.FullName);
		QueryText = StrReplace(QueryText, "#FullFilesVersionsCatalogName", FullFilesVersionsCatalogName);

		BatchQueryText.Add(QueryText);

	Else // Not HasAbilityToStoreVersions

		QueryText = 
           "SELECT
           |	Files.Ref AS AttachedFile,
           |	Files.FileStorageType AS FileStorageType,
           |	Files.Volume AS Volume,
           |	Files.PathToFile AS PathToFile,
           |	ISNULL(FileRepository.BinaryDataStorage, VALUE(Catalog.BinaryDataStorage.EmptyRef)) AS BinaryDataStorage,
           |	Files.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive) AS ThisIsOnDiskStorage,
           |	Files.Description AS Description,
           |	Files.Extension AS Extension,
           |	Files.Ref AS FileForRecordingInformation,
           |	0 AS VersionNumber,
           |	Files.FileOwner AS FileOwner,
           |	FilesInfo.ConditionallyTransferredToArchive AS ConditionallyTransferredToArchive,
           |	Files.Presentation AS FilePresentation
           |INTO VT_PreparingDataForTransfer
           |FROM
           |	#FileOwnerType AS Files
           |		INNER JOIN #CatalogFileOwner AS CatalogFileOwner
           |		ON Files.FileOwner = CatalogFileOwner.Ref
           |			AND (NOT CatalogFileOwner.DeletionMark)
           |			AND (NOT Files.DeletionMark)
           |			AND (&ThisIsNotGroup)
           |			AND (VALUETYPE(Files.FileOwner) = &OwnerType)
           |			AND (&SelectionBasedOnDetailedSettings)
           |			AND (&SelectionByExceptions)
           |			AND (CASE
           |				WHEN Files.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
           |					THEN (CAST(Files.PathToFile AS STRING(100))) <> """"
           |							OR NOT Files.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				WHEN Files.FileStorageType = VALUE(Enum.FileStorageTypes.InBuiltInBinaryDataStorage)
           |						OR Files.FileStorageType = VALUE(Enum.FileStorageTypes.InExternalBinaryDataStorage)
           |					THEN NOT Files.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				ELSE TRUE
           |			END)
           |			AND (DATEADD(Files.CreationDate, DAY, &DaysCount) <= &DateOfProcessing)
           |			AND (Files.BeingEditedBy IN (&EmptyUsers))
           |		INNER JOIN InformationRegister.FilesInfo AS FilesInfo
           |		ON Files.Ref = FilesInfo.File
           |			AND (FilesInfo.DateOfTransferToArchive = DATETIME(1,1,1))
           |		LEFT JOIN InformationRegister.FileRepository AS FileRepository
           |		ON Files.Ref = FileRepository.File";

		QueryText = StrReplace(QueryText, "#FileOwnerType", "Catalog." + FilesCatalogAttributes.Name);
		QueryText = StrReplace(QueryText, "#CatalogFileOwner", FilesOwnerFullName);		   

		BatchQueryText.Add(QueryText);

	EndIf;

	QueryText = 
           "SELECT DISTINCT
           |	VT_PreparingDataForTransfer.BinaryDataStorage AS BinaryDataStorage
           |INTO VT_DataForCheckingDeduplication
           |FROM
           |	VT_PreparingDataForTransfer AS VT_PreparingDataForTransfer
           |WHERE
           |	NOT VT_PreparingDataForTransfer.ThisIsOnDiskStorage
           |
           |INDEX BY
           |	VT_PreparingDataForTransfer.BinaryDataStorage
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |SELECT
           |	FileRepository.BinaryDataStorage AS BinaryDataStorage,
           |	COUNT(*) AS NumberOfDeduplicatedFiles,
           |	COUNT(*) - SUM(CASE
           |			WHEN ISNULL(FilesInfo.ConditionallyTransferredToArchive, ISNULL(FilesVersions.ConditionallyTransferredToArchive, FALSE))
           |				THEN CAST(1 AS NUMBER(17, 0))
           |			ELSE 0
           |		END) AS CriteriaForConditionalTransfer,
           |	MAX(CASE
           |			WHEN NOT FilesVersions.Ref IS NULL
           |				THEN FilesVersions.Owner.CurrentVersion = FilesVersions.Ref
           |						AND NOT FilesVersions.Owner.BeingEditedBy IN (&EmptyUsers)
           |			ELSE NOT FilesInfo.BeingEditedBy IN (&EmptyUsers)
           |		END) AS FileBeingEdited
           |INTO TT_DeduplicatedFiles
           |FROM
           |	VT_DataForCheckingDeduplication AS VT_DataForCheckingDeduplication
           |		INNER JOIN InformationRegister.FileRepository AS FileRepository
           |		ON VT_DataForCheckingDeduplication.BinaryDataStorage = FileRepository.BinaryDataStorage
           |		LEFT JOIN InformationRegister.FilesInfo AS FilesInfo
           |		ON (FileRepository.File = FilesInfo.File)
           |		LEFT JOIN Catalog.FilesVersions AS FilesVersions
           |		ON (FileRepository.File = FilesVersions.Ref)
           |			AND (NOT FilesVersions.Owner.DeletionMark)
           |WHERE
           |	NOT ISNULL(FilesInfo.DeletionMark, ISNULL(FilesVersions.DeletionMark, FALSE))
           |
           |GROUP BY
           |	FileRepository.BinaryDataStorage
           |
           |HAVING
           |	COUNT(*) > 1
           |
           |INDEX BY
           |	FileRepository.BinaryDataStorage
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |SELECT
           |	VT_PreparingDataForTransfer.AttachedFile AS AttachedFile,
           |	VT_PreparingDataForTransfer.FileStorageType AS FileStorageType,
           |	VT_PreparingDataForTransfer.Volume AS Volume,
           |	VT_PreparingDataForTransfer.PathToFile AS PathToFile,
           |	VT_PreparingDataForTransfer.BinaryDataStorage AS BinaryDataStorage,
           |	VT_PreparingDataForTransfer.Description AS Description,
           |	VT_PreparingDataForTransfer.Extension AS Extension,
           |	VT_PreparingDataForTransfer.FileForRecordingInformation AS FileForRecordingInformation,
           |	VT_PreparingDataForTransfer.VersionNumber AS VersionNumber,
           |	VT_PreparingDataForTransfer.FileOwner AS FileOwner,
           |	CASE
           |		WHEN ISNULL(TT_DeduplicatedFiles.CriteriaForConditionalTransfer, 0) = 1
           |			THEN VT_PreparingDataForTransfer.ConditionallyTransferredToArchive
           |		WHEN ISNULL(TT_DeduplicatedFiles.CriteriaForConditionalTransfer, 0) > 1
           |			THEN TRUE
           |		ELSE FALSE
           |	END AS SubjectToConditionalTransfer,
           |	NOT VT_PreparingDataForTransfer.ThisIsOnDiskStorage
           |		AND NOT CASE
           |				WHEN ISNULL(TT_DeduplicatedFiles.CriteriaForConditionalTransfer, 0) = 1
           |					THEN VT_PreparingDataForTransfer.ConditionallyTransferredToArchive
           |				WHEN ISNULL(TT_DeduplicatedFiles.CriteriaForConditionalTransfer, 0) > 1
           |					THEN TRUE
           |				ELSE FALSE
           |			END AS ReceiveBinaryData,
           |	ISNULL(TT_DeduplicatedFiles.NumberOfDeduplicatedFiles, 0) AS NumberOfDeduplicatedFiles,
           |	VT_PreparingDataForTransfer.ConditionallyTransferredToArchive AS ConditionallyTransferredToArchive,
           |	ISNULL(TT_DeduplicatedFiles.FileBeingEdited, FALSE) AS FileBeingEdited,
           |	VT_PreparingDataForTransfer.FilePresentation AS FilePresentation
           |INTO VT_DataToTransfer
           |FROM
           |	VT_PreparingDataForTransfer AS VT_PreparingDataForTransfer
           |		LEFT JOIN TT_DeduplicatedFiles AS TT_DeduplicatedFiles
           |		ON VT_PreparingDataForTransfer.BinaryDataStorage = TT_DeduplicatedFiles.BinaryDataStorage
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |DROP VT_DataForCheckingDeduplication
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |DROP TT_DeduplicatedFiles
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |DROP VT_PreparingDataForTransfer";

	BatchQueryText.Add(QueryText);

	Separator = 
	"
	|;
	|/////////////////////////////////////////////////////////////
	|";

	QueryText = StrConcat(BatchQueryText, Separator);

	If ExceptionsArray.Count() > 0 Then
		QueryText = StrReplace(QueryText, "&SelectionByExceptions", "NOT Files.FileOwner IN HIERARCHY (&ExceptionsArray)");
	Else 
		QueryText = StrReplace(QueryText, "&SelectionByExceptions", "TRUE");
	EndIf;

	If ExceptionItem <> Undefined Then
		QueryText = StrReplace(QueryText, "&SelectionBasedOnDetailedSettings", "Files.FileOwner IN HIERARCHY (&SelectionBasedOnDetailedSettings)");
	Else
		QueryText = StrReplace(QueryText, "&SelectionBasedOnDetailedSettings", "TRUE");
	EndIf;

	If FilesObjectMetadata.Hierarchical Then
		QueryText = StrReplace(QueryText, "&ThisIsNotGroup", "NOT Files.IsFolder");
	Else
		QueryText = StrReplace(QueryText, "&ThisIsNotGroup", "TRUE");
	EndIf;

	Return QueryText;

EndFunction

Function NumberOfDaysOfStorageBeforeTransferToFileArchive(ConfiguringFileTransfer, DefaultValue)

	If ConfiguringFileTransfer.TransferToFileArchiveInDays = 0 Then
		Result = DefaultValue;
	Else
		Result = ConfiguringFileTransfer.TransferToFileArchiveInDays;
	EndIf;	

	Return Result;

EndFunction

Procedure DeleteTemporaryDirectory(FullFileName, Val ErrorDescriptionHeader = Undefined, Val RaiseException1 = False)

	If IsBlankString(FullFileName) Then
		Return;
	EndIf;

	Try
		DeleteFiles(FullFileName);
	Except
		
		If ErrorDescriptionHeader = Undefined Then
			ErrorDescriptionHeader = NStr("en = 'File transfer error'");
		EndIf;

		ErrorDescriptionTemplate = NStr("en = '%1 
			|Temporary directory not deleted:
			|%2.'");

		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorDescriptionTemplate,
			ErrorDescriptionHeader,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		RecordFileTransferEventInRegistrationLog(ExceptionString, EventLogLevel.Error);			

		If RaiseException1 Then;
			Raise ExceptionString;
		EndIf;

	EndTry;

EndProcedure

Function ErrorDescriptionStringOfOperationsWithTemporaryDirectory(ThisIsTransferToFileArchive)

	If ThisIsTransferToFileArchive Then
		Result = NStr("en = 'Error transferring files to archive'");
	Else
		Result = NStr("en = 'Error restoring file from archive'");
	EndIf;

	Return Result;

EndFunction

Procedure RecordFileTransferEventInRegistrationLog(Val MessageText, Val Level = Undefined)

	If Level = Undefined Then
		Level = EventLogLevel.Information;
	EndIf;

	WriteLogEvent(FileTransferRegistrationLogEvent(), Level,,, MessageText);

EndProcedure

Function FileTransferRegistrationLogEvent()

	Return NStr("en = 'File archive operations'", Common.DefaultLanguageCode());

EndFunction

Function DeduplicatedFilesByBinaryDataStorage(Var_BinaryDataStorage, OnlyFilesInArchive = False)

	Query = New Query;	
	Query.Text = 
		"SELECT
		|	FileRepository.File AS AttachedFile,
		|	ISNULL(FilesVersions.Description, ISNULL(FilesInfo.Description, """")) AS Description,
		|	ISNULL(FilesVersions.Extension, ISNULL(FilesInfo.Extension, """")) AS Extension,
		|	ISNULL(FilesVersions.Owner, FileRepository.File) AS FileForRecordingInformation,
		|	ISNULL(FilesVersions.VersionNumber, 0) AS VersionNumber,
		|	ISNULL(FilesVersions.Owner.FileOwner, ISNULL(FilesInfo.FileOwner, UNDEFINED)) AS FileOwner
		|FROM
		|	InformationRegister.FileRepository AS FileRepository
		|		LEFT JOIN InformationRegister.FilesInfo AS FilesInfo
		|		ON FileRepository.File = FilesInfo.File
		|			AND (NOT FilesInfo.DeletionMark)
		|		LEFT JOIN Catalog.FilesVersions AS FilesVersions
		|		ON FileRepository.File = FilesVersions.Ref
		|			AND (NOT FilesVersions.Owner.DeletionMark)
		|WHERE
		|	FileRepository.BinaryDataStorage = &BinaryDataStorage
		|	AND NOT ISNULL(FilesInfo.DeletionMark, ISNULL(FilesVersions.DeletionMark, FALSE))
		|	AND (&AllFiles
		|			OR ISNULL(FilesInfo.DateOfTransferToArchive, ISNULL(FilesVersions.DateOfTransferToArchive, DATETIME(1, 1, 1))) <> DATETIME(1, 1, 1))";

	Query.SetParameter("BinaryDataStorage"	, Var_BinaryDataStorage);
	Query.SetParameter("AllFiles"				, Not OnlyFilesInArchive);

	Return Query.Execute().Unload();

EndFunction

Function AdditionalFileTransferOptions()

	Result = New Structure;
	Result.Insert("QueryTextForReceivingPortionOfFilesToTransferToArchive"			, "");
	Result.Insert("QueryTextForGettingPortionOfFilesToRestoreFromArchive"	, "");
	Result.Insert("FilesStorageMethod"										, "");

	Return Result;

EndFunction

#EndRegion

// See StandardSubsystemsServer.WhenDefiningMethodsThatAreAllowedToBeCalledAsArbitraryCode
Procedure WhenDefiningMethodsThatAreAllowedToBeCalledAsArbitraryCode(Methods) Export
	
	Methods.Insert("InitialFillingOfConstants");
	Methods.Insert("InitialFillingInSettingsForWorkingWithFileArchive");
	Methods.Insert("TransferFilesBetweenOperationalStorageAndFileArchive", True);
	
EndProcedure

#EndRegion