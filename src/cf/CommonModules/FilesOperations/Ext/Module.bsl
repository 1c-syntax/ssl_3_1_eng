///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns the binary data of the file.
//
// Parameters:
//  AttachedFile - DefinedType.AttachedFile -  link to the directory element with the file.
//
//  RaiseException1 - Boolean -  if you specify False, the function will return Undefined
//                     			  instead of calling exceptions, and the log entry level will be downgraded to "Warning".
//                                The default value is True.
//
// Returns:
//  BinaryData, Undefined - 
//                               
//                               
//                               
//
// Example:
//  Saving file data on the server:
//	Datafile = Workfiles.Binary Data Files(File, False);
//	If The File Data <> Is Undefined Then
//		Data files.Write(Pathfile);
//	Conicelli;
//
Function FileBinaryData(Val AttachedFile, Val RaiseException1 = True) Export
	
	CommonClientServer.CheckParameter("FilesOperations.FileBinaryData", "AttachedFile", 
		AttachedFile, Metadata.DefinedTypes.AttachedFile.Type);
	
	FileObject1 = FilesOperationsInternal.FileObject1(AttachedFile);
	If (FileObject1 = Undefined Or FileObject1.IsFolder) And Not RaiseException1 Then
		Return Undefined;
	EndIf;
	
	CommonClientServer.Validate(FileObject1 <> Undefined, 
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of parameter %1';"), "AttachedFile"),
		"FilesOperations.FileBinaryData");
	CommonClientServer.Validate(Not FileObject1.IsFolder, 
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of parameter %1 (file folder: ""%2"")';"),
			"AttachedFile", Common.SubjectString(AttachedFile)),
		"FilesOperations.FileBinaryData");
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If FileObject1.DeletionMark Then
		FilesOperationsInternal.ReportErrorFileNotFound(FileObject1, RaiseException1);
		Return Undefined;
	EndIf;
	
	If FileObject1.FileStorageType = Enums.FileStorageTypes.InInfobase Then
		
		Result = FileFromInfobaseStorage(FileObject1.Ref);
		If TypeOf(Result) = Type("ValueStorage") Then
			Result = Result.Get();
			If TypeOf(Result) = Type("BinaryData") Then
				Return Result;
			EndIf;
		EndIf;
		
		FilesOperationsInternal.ReportErrorFileNotFound(FileObject1, RaiseException1);
		Return Undefined;
			
	Else
		Return FilesOperationsInVolumesInternal.FileData(AttachedFile, RaiseException1);
	EndIf;
	
EndFunction

// Returns the binary data of the file.
//
// Parameters:
//  AttachedFiles - Array of DefinedType.AttachedFile - 
//                                                                       
//
//  RaiseException1 - Boolean -  if you specify False, the function will return Undefined
//                     			  instead of calling exceptions, and the log entry level will be downgraded to "Warning".
//                                The default value is True.
//
// Returns:
//  Map of KeyAndValue:
//   * Key - DefinedType.AttachedFile -  
//   * Value - BinaryData - 
//                               
//                               
//                               
//
Function BinaryFilesData(Val AttachedFiles, Val RaiseException1 = True) Export
	
	If AttachedFiles.Count() = 0 Then
		Return New Map;
	EndIf;
	
	CommonClientServer.CheckParameter("FilesOperations.FileBinaryData", "AttachedFile", 
		AttachedFiles[0], Metadata.DefinedTypes.AttachedFile.Type);
		
	FileType = TypeOf(AttachedFiles[0]);
	For IndexOf = 1 To AttachedFiles.Count() - 1 Do
		If TypeOf(AttachedFiles[IndexOf]) <> FileType Then
			Raise NStr("en = 'All attachments must be of the same type.';");
		EndIf;
	EndDo;
	
	AllowedAttachments = New Array;
	HasRightsToObjects = Common.ObjectsAttributesValues(AttachedFiles, "Ref", True);
	For Each HasRightsToObject In HasRightsToObjects Do
		AllowedAttachments.Add(HasRightsToObject.Key); 
	EndDo; 
	
	FileObjectMetadata = Metadata.FindByType(FileType);
	
	HasCurrentVersionAttribute = Common.HasObjectAttribute("FileOwner", FileObjectMetadata)
		And Common.HasObjectAttribute("CurrentVersion", FileObjectMetadata);
		
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
		
	If HasCurrentVersionAttribute Then
		If FilesOperationsInternalCached.IsDeduplicationCompleted() Then
			QueryText =
			"SELECT
			|	AttachedFiles.Ref AS Ref,
			|	AttachedFiles.FileStorageType AS FileStorageType,
			|	AttachedFiles.Volume AS Volume,
			|	AttachedFiles.DeletionMark AS DeletionMark,
			|	FileRepository.BinaryDataStorage.BinaryData AS FileStorage1
			|FROM
			|	&TableAttachedFiles AS AttachedFiles
			|		LEFT JOIN InformationRegister.FileRepository AS FileRepository
			|		ON AttachedFiles.Ref = FileRepository.File
			|WHERE
			|	AttachedFiles.Ref IN (&AttachedFiles)
			|	AND AttachedFiles.CurrentVersion = VALUE(Catalog.FilesVersions.EmptyRef)
			|
			|UNION ALL
			|
			|SELECT
			|	AttachedFiles.Ref,
			|	AttachedFiles.FileStorageType,
			|	AttachedFiles.Volume,
			|	AttachedFiles.DeletionMark,
			|	FileRepository.BinaryDataStorage.BinaryData
			|FROM
			|	&TableAttachedFiles AS AttachedFiles
			|		LEFT JOIN InformationRegister.FileRepository AS FileRepository
			|		ON AttachedFiles.CurrentVersion = FileRepository.File
			|WHERE
			|	AttachedFiles.Ref IN (&AttachedFiles)
			|	AND AttachedFiles.CurrentVersion <> VALUE(Catalog.FilesVersions.EmptyRef)";
		Else
			QueryText =
			"SELECT
			|	AttachedFiles.Ref AS Ref,
			|	AttachedFiles.FileStorageType AS FileStorageType,
			|	AttachedFiles.Volume AS Volume,
			|	AttachedFiles.DeletionMark AS DeletionMark,
			|	CASE
			|		WHEN FileRepository.File IS NULL
			|			THEN DeleteFilesBinaryData.FileBinaryData
			|		ELSE FileRepository.BinaryDataStorage.BinaryData
			|	END AS FileStorage1
			|FROM
			|	&TableAttachedFiles AS AttachedFiles
			|		LEFT JOIN InformationRegister.FileRepository AS FileRepository
			|		ON AttachedFiles.Ref = FileRepository.File
			|		LEFT JOIN InformationRegister.DeleteFilesBinaryData AS DeleteFilesBinaryData
			|		ON AttachedFiles.Ref = DeleteFilesBinaryData.File
			|WHERE
			|	AttachedFiles.Ref IN (&AttachedFiles)
			|	AND AttachedFiles.CurrentVersion = VALUE(Catalog.FilesVersions.EmptyRef)
			|
			|UNION ALL
			|
			|SELECT
			|	AttachedFiles.Ref,
			|	AttachedFiles.FileStorageType,
			|	AttachedFiles.Volume,
			|	AttachedFiles.DeletionMark,
			|	CASE
			|		WHEN FileRepository.File IS NULL
			|			THEN DeleteFilesBinaryData.FileBinaryData
			|		ELSE FileRepository.BinaryDataStorage.BinaryData
			|	END
			|FROM
			|	&TableAttachedFiles AS AttachedFiles
			|		LEFT JOIN InformationRegister.FileRepository AS FileRepository
			|		ON AttachedFiles.CurrentVersion = FileRepository.File
			|		LEFT JOIN InformationRegister.DeleteFilesBinaryData AS DeleteFilesBinaryData
			|		ON AttachedFiles.CurrentVersion = DeleteFilesBinaryData.File
			|WHERE
			|	AttachedFiles.Ref IN (&AttachedFiles)
			|	AND AttachedFiles.CurrentVersion <> VALUE(Catalog.FilesVersions.EmptyRef)";
		EndIf;
	Else
		If FilesOperationsInternalCached.IsDeduplicationCompleted() Then
			QueryText =
			"SELECT
			|	AttachedFiles.Ref AS Ref,
			|	AttachedFiles.FileStorageType AS FileStorageType,
			|	AttachedFiles.Volume AS Volume,
			|	AttachedFiles.DeletionMark AS DeletionMark,
			|	FileRepository.BinaryDataStorage.BinaryData AS FileStorage1
			|FROM
			|	&TableAttachedFiles AS AttachedFiles
			|		LEFT JOIN InformationRegister.FileRepository AS FileRepository
			|		ON AttachedFiles.Ref = FileRepository.File
			|WHERE
			|	AttachedFiles.Ref IN (&AttachedFiles)";
		Else
			QueryText =
			"SELECT
			|	AttachedFiles.Ref AS Ref,
			|	AttachedFiles.FileStorageType AS FileStorageType,
			|	AttachedFiles.Volume AS Volume,
			|	AttachedFiles.DeletionMark AS DeletionMark,
			|	CASE
			|		WHEN FileRepository.File IS NULL
			|			THEN DeleteFilesBinaryData.FileBinaryData
			|		ELSE FileRepository.BinaryDataStorage.BinaryData
			|	END AS FileStorage1
			|FROM
			|	&TableAttachedFiles AS AttachedFiles
			|		LEFT JOIN InformationRegister.FileRepository AS FileRepository
			|		ON AttachedFiles.Ref = FileRepository.File
			|		LEFT JOIN InformationRegister.DeleteFilesBinaryData AS DeleteFilesBinaryData
			|		ON AttachedFiles.Ref = DeleteFilesBinaryData.File
			|WHERE
			|	AttachedFiles.Ref IN (&AttachedFiles)";
		EndIf;
	EndIf;
	
	Query = New Query;
	Query.Text = StrReplace(QueryText, "&TableAttachedFiles", FileObjectMetadata.FullName());
	Query.SetParameter("AttachedFiles", AllowedAttachments);
	Selection = Query.Execute().Select();
	
	BinaryFilesData = New Map;
	While Selection.Next() Do
		If Selection.FileStorageType = Enums.FileStorageTypes.InInfobase Then
			BinaryData = Undefined;
			If Selection.FileStorage1 <> Null Then
				BinaryData = Selection.FileStorage1.Get();
			EndIf;
			If BinaryData = Undefined Then
				FilesOperationsInternal.ReportErrorFileNotFound(Selection.Ref, RaiseException1);
			Else
				BinaryFilesData.Insert(Selection.Ref, BinaryData);
			EndIf;
		Else
			BinaryData = FilesOperationsInVolumesInternal.FileData(Selection.Ref, RaiseException1);
			If BinaryData <> Undefined Then
				BinaryFilesData.Insert(Selection.Ref, BinaryData);
			EndIf;
		EndIf;
	EndDo;
	
	Return BinaryFilesData;
	
EndFunction

// Returns information about the file. It is used in various file management commands
// and as the value of the file Data parameter in other procedures and functions.
// 
// Parameters:
//  AttachedFile                    - DefinedType.AttachedFile -  link to the directory element with the file.
//  AdditionalParameters               - See FilesOperationsClientServer.FileDataParameters.
//  DeleteGetRefToBinaryData - Boolean -  deprecated, additional Parameters should be used.
//  DeleteForEditing              - Boolean -  deprecated, additional Parameters should be used.
//
// Returns:
//  Structure, Undefined - 
//    
//    
//    
//    :
//    * Ref                             - DefinedType.AttachedFile -  link to the directory element with the file.
//    * RefToBinaryFileData        - String - 
//    * Owner                           - DefinedType.FilesOwner - 
//    * RelativePath                  - String -  relative path of the file. 
//    * UniversalModificationDate       - Date   - 
//    * FileName                           - String - 
//    * Description                       - String - 
//    * Extension                         - String -  file extension without a dot.
//    * Size                             - Number  -  file size in bytes.
//    * BeingEditedBy                        - CatalogRef.Users
//                                         - CatalogRef.ExternalUsers
//                                         - Undefined - 
//    * LockedDate                          - Date   - 
//    * SignedWithDS                         - Boolean -  indicates that the file is signed.
//    * Encrypted                         - Boolean -  indicates that the file is encrypted.
//    * EncryptionCertificatesArray       - See DigitalSignature.EncryptionCertificates
//    * DeletionMark                    - Boolean - 
//    * URL                - String -     
//    * StoreVersions                      - Boolean - 
//    * CurrentVersion                      - DefinedType.AttachedFile -  if the file directory supports creating
//                                              versions, it contains a link to the current version of the file. Otherwise, it contains
//                                              a link to the file.
//    * Version                             - DefinedType.AttachedFile - 
//    * VersionNumber                        - Number -  if the file directory supports creating versions, it contains
//                                                   the current version number of the file, otherwise it is 0.
//    * CurrentVersionAuthor                 - CatalogRef.FileSynchronizationAccounts
//                                         - CatalogRef.Users
//                                         - CatalogRef.ExternalUsers - 
//    * Volume                                - CatalogRef.FileStorageVolumes -  the storage volume of the file.
//    * Author                              - CatalogRef.FileSynchronizationAccounts
//                                         - CatalogRef.Users
//                                         - CatalogRef.ExternalUsers - 
//    * TextExtractionStatus             - String - 
//    * FullVersionDescription           - String -  if the file directory supports creating versions, it contains the full
//                                              name of the current version of the file. Otherwise, it contains the full
//                                              name of the file.
//    * CurrentVersionEncoding             - String -  encoding of the text file.
//    * ForReading                           - Boolean -  indicates that the file is being edited by a user other than the current user.
//    * FullFileNameInWorkingDirectory     - String -  path to the file in the working directory.
//    * InWorkingDirectoryForRead           - Boolean -  the file in the working directory is marked read-only.
//    * OwnerWorkingDirectory            - String -  path to the owner's working directory.
//    * FolderForSaveAs               - String -  path to the save folder.
//    * FileBeingEdited                  - Boolean -  indicates that the file is busy for editing.
//    * CurrentUserEditsFile - Boolean -  indicates that the file is currently being edited by the current user.
//    * Encoding                          - String -  encoding of the text file.
//    * IsInternal                          - Boolean -  indicates that the file is a service file.
//
// Example:
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
Function FileData(Val AttachedFile, Val AdditionalParameters = Undefined,
	Val DeleteGetRefToBinaryData = True, Val DeleteForEditing = False) Export
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		
		ForEditing = ?(AdditionalParameters.Property("ForEditing"), AdditionalParameters.ForEditing, False);
		FormIdentifier = ?(AdditionalParameters.Property("FormIdentifier"), AdditionalParameters.FormIdentifier, Undefined);
		RaiseException1 = ?(AdditionalParameters.Property("RaiseException1"), AdditionalParameters.RaiseException1, True);
		GetBinaryDataRef = ?(AdditionalParameters.Property("GetBinaryDataRef"), 
			AdditionalParameters.GetBinaryDataRef, True);
		
	Else
		ForEditing = DeleteForEditing;
		FormIdentifier = AdditionalParameters;
		RaiseException1 = True;
		GetBinaryDataRef = DeleteGetRefToBinaryData;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(AttachedFile);
	
	CommonClientServer.CheckParameter("FilesOperations.FileData", "AttachedFile",
		AttachedFile, Metadata.DefinedTypes.AttachedFile.Type);
		
	FileObject1 = AttachedFile.GetObject();
	If RaiseException1 Then
		CommonClientServer.Validate(FileObject1 <> Undefined, 
			StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Attachment ""%1"" (%2) not found';"),
			String(AttachedFile), AttachedFile.Metadata()));
	ElsIf FileObject1 = Undefined Then
		Return Undefined;
	EndIf;
	
	If ForEditing And Not ValueIsFilled(FileObject1.BeingEditedBy) Then
		FileObject1.Lock();
		FilesOperationsInternal.BorrowFileToEditServer(FileObject1);
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	RefToBinaryFileData = Undefined;
	
	VersionsStorageSupported = (TypeOf(AttachedFile) = Type("CatalogRef.Files"));
	FilesVersioningUsed = VersionsStorageSupported
		And AttachedFile.StoreVersions And ValueIsFilled(AttachedFile.CurrentVersion);
	
	If GetBinaryDataRef Then
		If FilesVersioningUsed Then
			BinaryData = FileBinaryData(AttachedFile.CurrentVersion, RaiseException1);
		Else
			BinaryData = FileBinaryData(AttachedFile, RaiseException1);
		EndIf;
		If TypeOf(FormIdentifier) = Type("UUID") Then
			RefToBinaryFileData = PutToTempStorage(BinaryData, FormIdentifier);
		Else
			RefToBinaryFileData = PutToTempStorage(BinaryData);
		EndIf;
		
	EndIf;
	
	Result = New Structure;
	Result.Insert("Ref",                       AttachedFile);
	Result.Insert("RefToBinaryFileData",  RefToBinaryFileData);
	Result.Insert("RelativePath",            GetObjectID(FileObject1.FileOwner) + "\");
	Result.Insert("UniversalModificationDate", FileObject1.UniversalModificationDate);
	Result.Insert("FileName",                     CommonClientServer.GetNameWithExtension(FileObject1.Description, FileObject1.Extension));
	Result.Insert("Description",                 FileObject1.Description);
	Result.Insert("Extension",                   FileObject1.Extension);
	Result.Insert("Size",                       FileObject1.Size);
	Result.Insert("BeingEditedBy",                  FileObject1.BeingEditedBy);
	Result.Insert("SignedWithDS",                   FileObject1.SignedWithDS);
	Result.Insert("Encrypted",                   FileObject1.Encrypted);
	Result.Insert("StoreVersions",                FileObject1.StoreVersions);
	Result.Insert("DeletionMark",              FileObject1.DeletionMark);
	Result.Insert("LockedDate",                    FileObject1.LockedDate);
	Result.Insert("Owner",                     FileObject1.FileOwner);
	Result.Insert("CurrentVersionAuthor",           FileObject1.ChangedBy);
	Result.Insert("URL", GetURL(AttachedFile));
	
	Common.ShortenFileName(Result.FileName);
	
	FileObjectMetadata = Metadata.FindByType(TypeOf(AttachedFile));
	HasAbilityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", FileObjectMetadata);
	
	If HasAbilityToStoreVersions And ValueIsFilled(AttachedFile.CurrentVersion) Then
		FilesOperationsInternal.FillAdditionalFileData(Result, AttachedFile, AttachedFile.CurrentVersion);
	Else
		FilesOperationsInternal.FillAdditionalFileData(Result, AttachedFile, Undefined);
	EndIf;
	
	Result.Insert("FileBeingEdited",            ValueIsFilled(FileObject1.BeingEditedBy));
	Result.Insert("CurrentUserEditsFile",
		?(Result.FileBeingEdited, FileObject1.BeingEditedBy = Users.AuthorizedUser(), False) );
		
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
		If FileObject1.Encrypted Then
			Result.Insert("EncryptionCertificatesArray", ModuleDigitalSignature.EncryptionCertificates(AttachedFile));
		EndIf;
	EndIf;
	
	File = ?(FilesVersioningUsed, AttachedFile.CurrentVersion, AttachedFile);
	Result.Insert("Encoding", InformationRegisters.FilesEncoding.DefineFileEncoding(File, FileObject1.Extension));
	
	Result.Insert("IsInternal", False);
	If CommonClientServer.HasAttributeOrObjectProperty(FileObject1, "IsInternal") Then
		Result.IsInternal = FileObject1.IsInternal;
	EndIf;
	
	Return Result;
	
EndFunction

// 
//
// Parameters:
//  FileOwner - DefinedType.AttachedFilesOwner
//  Files         - Array of DefinedType.AttachedFile - 
//
Procedure FillFilesAttachedToObject(Val FileOwner, Val Files) Export
	
	If Not ValueIsFilled(FileOwner)
		Or TypeOf(FileOwner) = Type("CatalogRef.MetadataObjectIDs") Then
		Return;
	EndIf;
	
	AttachedFilesToObject = FilesOperationsInternal.AttachedFilesToObject(FileOwner);
	For Each AttachedFile In AttachedFilesToObject Do
		Files.Add(AttachedFile);
	EndDo;
	
EndProcedure

// Returns a new file reference for the specified file owner.
// In particular, the link is used when adding a file to the Addfile function.
//
// Parameters:
//  FilesOwner - DefinedType.AttachedFilesOwner -  the object to which
//                   you want to attach the file to add.
//
//  CatalogName - Undefined -  calculate the owner reference (allowed
//                   when there is only one reference, otherwise an exception will be thrown).
//
//                 - String - 
//                            
//  
// Returns:
//  DefinedType.AttachedFile - 
//
Function NewRefToFile(FilesOwner, CatalogName = Undefined) Export
	
	CatalogName = FilesOperationsInternal.FileStoringCatalogName(
		FilesOwner, CatalogName);
	Return Catalogs[CatalogName].GetRef();
	
EndFunction

// Updates file properties without taking into account versions: binary data, text, date of change,
// and other optional properties. Use only for files that do not store versions.
//
// Parameters:
//  AttachedFile - DefinedType.AttachedFile -  link to the directory element with the file.
//  FileInfo - Structure:
//     * FileAddressInTempStorage - String -  the address of the new binary data of the file.
//     * TempTextStorageAddress - String -  the address of the new binary data of the text
//                                                 extracted from the file.
//     * BaseName               - String -  optional, if the property is not specified or is not filled in,
//                                                 then it will not be changed.
//     * UniversalModificationDate   - Date   -  optional, the date of the last modification of the file, if
//                                                 the property is not specified or not filled in, then
//                                                 the current session date will be set.
//     * Extension                     - String -  optional, new file extension.
//     * BeingEditedBy                    - AnyRef -  optional, a new user editing the file.
//     * Encoding                      - String -  optional, the encoding in which the file is saved.
//                                                 For a list of supported encodings, see the help for
//                                                 the global context method "Get Binary Strings".
//
Procedure RefreshFile(Val AttachedFile, Val FileInfo) Export
	
	FilesOperationsInternal.RefreshFile(FileInfo, AttachedFile);
	
EndProcedure

// Returns the name of the attached files object form by owner.
//
// Parameters:
//  FilesOwner - DefinedType.AttachedFilesOwner -  the object to which
//                       you want to attach the file to add.
//
// Returns:
//  String - 
//
Function FilesObjectFormNameByOwner(Val FilesOwner) Export
	
	ErrorTitle = NStr("en = 'Error getting the form name of the attachment.';");
	ErrorEnd = NStr("en = 'Cannot get the form.';");
	
	CatalogName = FilesOperationsInternal.FileStoringCatalogName(
		FilesOwner, "", ErrorTitle, ErrorEnd);
	
	FullMetadataObjectName1 = "Catalog." + CatalogName;
	
	AttachedFileMetadata1 = Metadata.Catalogs.Find(CatalogName);
	
	If AttachedFileMetadata1.DefaultObjectForm = Undefined Then
		FormName = FullMetadataObjectName1 + ".ObjectForm";
	Else
		FormName = AttachedFileMetadata1.DefaultObjectForm.FullName();
	EndIf;
	
	Return FormName;
	
EndFunction

// Determines whether the file to be added can be attached to the file owner.
//
// Parameters:
//  FilesOwner - DefinedType.AttachedFilesOwner -  the object to which
//                       you want to attach the file to add.
//  CatalogName - String -  if specified, it checks whether files are added to the specified storage.
//                            Otherwise, the directory name will be determined by its owner.
//
// Returns:
//  Boolean - 
//
Function CanAttachFilesToObject(FilesOwner, CatalogName = "") Export
	
	CatalogName = FilesOperationsInternal.FileStoringCatalogName(
		FilesOwner, CatalogName);
	
	CatalogAttachedFiles = Metadata.Catalogs.Find(CatalogName);
	
	StoredFileTypes = Metadata.DefinedTypes.AttachedFile.Type;
	
	Return CatalogAttachedFiles <> Undefined
		And AccessRight("Insert", CatalogAttachedFiles)
		And StoredFileTypes.ContainsType(Type("CatalogRef." + CatalogName))
		And Not StoredFileTypes.ContainsType(TypeOf(FilesOwner));
	
EndFunction

// Adds a new file from the file system.
// If the file directory supports storing versions, the first version of the file will be created.
// 
// Parameters:
//   FilesOwner    - DefinedType.AttachedFilesOwner -  the object to which
//                       you want to attach the file to add.
//   FilePathOnHardDrive - String - 
//                       
//
// Returns:
//  DefinedType.AttachedFile - 
//
Function AddFileFromHardDrive(FilesOwner, FilePathOnHardDrive) Export
	
	If Not ValueIsFilled(FilesOwner) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'The %1 parameter value is not set in %2.';"), 
			"FilesOwner","FilesOperations.AddFileFromHardDrive");
	EndIf;
	
	File = New File(FilePathOnHardDrive);
	
	BinaryData = New BinaryData(FilePathOnHardDrive);
	TempFileStorageAddress = PutToTempStorage(BinaryData);
	
	TempTextStorageAddress = "";
	
	If FilesOperationsInternal.ExtractTextFilesOnServer() Then
		// 
		TempTextStorageAddress = ""; 
	Else
		// 
		If Common.IsWindowsServer() Then
			Text = FilesOperationsInternal.ExtractTextFromFileOnHardDrive(FilePathOnHardDrive);
			TempTextStorageAddress = New ValueStorage(Text);
		EndIf;
	EndIf;
	
	FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion", File);
	FileInfo1.TempFileStorageAddress = TempFileStorageAddress;
	FileInfo1.TempTextStorageAddress = TempTextStorageAddress;
	Return FilesOperationsInternalServerCall.CreateFileWithVersion(FilesOwner, FileInfo1);
	
EndFunction

// The event handler before writing the file owner objects,
// marks the attached files for deletion when the owner object is marked.
// Only suitable for documents.
//
// Parameters:
//  Source        - DocumentObject -  a document with attached files.
//  Cancel           - Boolean -  standard pre-recording handler parameter. 
//  WriteMode     - DocumentWriteMode -  standard pre-recording handler parameter.    
//  PostingMode - DocumentPostingMode -  standard pre-recording handler parameter.
//
Procedure SetDeletionMarkOfDocumentsBeforeWrite(Source, Cancel, WriteMode, PostingMode) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Source.DeletionMark <> Common.ObjectAttributeValue(Source.Ref, "DeletionMark") Then
		MarkToDeleteAttachedFiles(Source);
	EndIf;
	
EndProcedure

// The event handler before writing the file owner objects,
// marks the attached files for deletion when the owner object is marked.
// Suitable for reference objects other than documents.
//
// Parameters:
//  Source - DefinedType.AttachedFilesOwnerObject -  an object with attached files.
//  Cancel    - Boolean -  standard pre-recording handler parameter.
//
Procedure SetFilesDeletionMarkBeforeWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If StandardSubsystemsServer.IsMetadataObjectID(Source) Then
		Return;
	EndIf;
	
	If Source.DeletionMark <> Common.ObjectAttributeValue(Source.Ref, "DeletionMark") Then
		MarkToDeleteAttachedFiles(Source);
	EndIf;
	
EndProcedure

// 
// 
// 
// Parameters:
//   AdditionalAttributes - String
//                           - Array - 
//                           
//                           - Structure - 
//                           
//
// Returns:
//   Structure:
//      * Author                       - CatalogRef.Users
//                                    - CatalogRef.ExternalUsers
//                                    - CatalogRef.FileSynchronizationAccounts - 
//                                    
//                                    
//      * FilesOwner              - DefinedType.AttachedFilesOwner -  the object to which
//                                    you want to attach the file to add.
//                                    The default value is Undefined.
//      * BaseName            - String -  file name without extension.
//                                    The default value is "".
//      * ExtensionWithoutPoint          - String -  file extension (without the dot at the beginning).
//                                    The default value is "".
//      * ModificationTimeUniversal - Date -  date and time when the file was modified (UTC+0: 00). If the parameter takes the value
//                                    Undefined. when adding a file, the modification time will be set to
//                                    the result of executing the function current universal Date().
//                                    The default value is Undefined.
//      * FilesGroup                - DefinedType.AttachedFile -  the directory group with files to
//                                    add the new file to.
//                                    The default value is Undefined.
//      * IsInternal                   - Boolean -  if True, then the file will be hidden from users.
//                                    The default value is False.
//
Function FileAddingOptions(AdditionalAttributes = Undefined) Export
	
	Return FilesOperationsInternalClientServer.FileAddingOptions(AdditionalAttributes);
	
EndFunction

// Creates an object in the directory for storing the file and fills in its details with the passed properties.
//
// Parameters:
//   FileParameters                 - See FilesOperations.FileAddingOptions.
//   FileAddressInTempStorage - String -  an address that points to binary data in temporary storage.
//   TempTextStorageAddress - String -  an address that points to the extracted text from a file in temporary storage.
//   LongDesc                       - String -  text description of the file.
//   NewRefToFile              - Undefined -  if the file owner has only one file storage directory.
//                                  - DefinedType.AttachedFile - 
//                                    
//                                    
//                                    
// 
// Returns:
//   DefinedType.AttachedFile - 
//
Function AppendFile(FileParameters,
                     Val FileAddressInTempStorage,
                     Val TempTextStorageAddress = "",
                     Val LongDesc = "",
                     Val NewRefToFile = Undefined) Export
	
	FilesOwner     = FileParameters.FilesOwner;
	BaseName   = CommonClientServer.ReplaceProhibitedCharsInFileName(FileParameters.BaseName);
	ExtensionWithoutPoint = CommonClientServer.ReplaceProhibitedCharsInFileName(FileParameters.ExtensionWithoutPoint);
	
	If Not ValueIsFilled(FilesOwner) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The %1 parameter value is not set in %2.';"), "FileParameters.FilesOwner", "FilesOperations.AppendFile");
	EndIf;
	
	BinaryData = GetFromTempStorage(FileAddressInTempStorage); // BinaryData
	CommonClientServer.CheckParameter("FilesOperations.AppendFile",
		"FileAddressInTempStorage", BinaryData, Type("BinaryData"));
	
	FilesGroup = Undefined;
	If FileParameters.Property("FilesGroup")
		And ValueIsFilled(FileParameters.FilesGroup)
		And Not FilesOperationsInternal.IsFilesFolder(FilesOwner) Then
		
		FilesGroup = FileParameters.FilesGroup;
	EndIf;
	
	If Not ValueIsFilled(ExtensionWithoutPoint) Then
		FileNameParts = StrSplit(BaseName, ".", False);
		If FileNameParts.Count() > 1 Then
			ExtensionWithoutPoint = FileNameParts[FileNameParts.Count() - 1];
			BaseName = Left(BaseName, StrLen(BaseName) - (StrLen(ExtensionWithoutPoint) + 1));
		EndIf;
	EndIf; 

	If Lower(ExtensionWithoutPoint) = Lower(EncryptedFilesExtension()) Then
		ForUnencryptedFile = New File(BaseName);
		ExtensionWithoutPoint = ForUnencryptedFile.Extension;
		BaseName = ForUnencryptedFile.BaseName;
		FileParameters.Insert("Encrypted", True);
	EndIf;
	
	BaseName = CommonClientServer.ReplaceProhibitedCharsInFileName(BaseName);
	ExtensionWithoutPoint = CommonClientServer.ReplaceProhibitedCharsInFileName(ExtensionWithoutPoint); 
	
	ModificationTimeUniversal = FileParameters.ModificationTimeUniversal;
	If Not ValueIsFilled(ModificationTimeUniversal)
		Or ModificationTimeUniversal > CurrentUniversalDate() Then
		ModificationTimeUniversal = CurrentUniversalDate();
	EndIf;
	
	ErrorTitle = NStr("en = 'Error adding attachment.';");
	
	If NewRefToFile = Undefined Then
		CatalogName = FilesOperationsInternal.FileStoringCatalogName(FilesOwner, "", ErrorTitle,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'In this case, parameter ""%1"" is required.';"), "NewRefToFile"));
		
		NewRefToFile = Catalogs[CatalogName].GetRef();
	Else
		
		If Not Catalogs.AllRefsType().ContainsType(TypeOf(NewRefToFile))
			Or Not ValueIsFilled(NewRefToFile) Then
			
			Raise NStr("en = 'Error adding attachment.
				|A reference to the new file is required.';");
		EndIf;
		
		CatalogName = FilesOperationsInternal.FileStoringCatalogName(
			FilesOwner, NewRefToFile.Metadata().Name, ErrorTitle);
		
	EndIf;
	
	StoreVersions = StrCompare(CatalogName, Metadata.Catalogs.Files.Name) = 0;
	
	AttachedFile = Catalogs[CatalogName].CreateItem(); // DefinedType.AttachedFileObject
	AttachedFile.SetNewObjectRef(NewRefToFile);
	
	AttachedFile.FileOwner                = FilesOwner;
	AttachedFile.UniversalModificationDate = ModificationTimeUniversal;
	AttachedFile.CreationDate                 = CurrentSessionDate();
	AttachedFile.LongDesc                     = LongDesc;
	AttachedFile.Description                 = BaseName;
	AttachedFile.Size                       = BinaryData.Size();
	AttachedFile.Extension                   = ExtensionWithoutPoint;
	AttachedFile.FileStorageType             = FilesOperationsInternal.FileStorageType(AttachedFile.Size,
		AttachedFile.Extension);
	AttachedFile.ChangedBy                      = FileParameters.Author;
	AttachedFile.StoreVersions                = StoreVersions;
	If FileParameters.Property("Encrypted") Then
		AttachedFile.Encrypted                   = FileParameters.Encrypted;
	EndIf;
	
	If FilesGroup <> Undefined Then
		AttachedFile.Parent = FilesGroup;
	EndIf;
	
	FillPropertyValues(AttachedFile, FileParameters);
	
	AttachedFile.Volume        = Catalogs.FileStorageVolumes.EmptyRef();
	AttachedFile.PathToFile = "";
	AttachedFile.Fill(Undefined);
		
	FullTextSearchUsing = Metadata.ObjectProperties.FullTextSearchUsing.Use;
	ExtractText = Metadata.Catalogs[CatalogName].FullTextSearch = FullTextSearchUsing;
	
	If ExtractText And CommonClientServer.StructureProperty(FileParameters, "Encrypted", False) <> True Then
		
		TextExtractionResult = FilesOperationsInternal.ExtractText1(TempTextStorageAddress,
			BinaryData, AttachedFile.Extension);
		
		AttachedFile.TextStorage = TextExtractionResult.TextStorage;
		AttachedFile.TextExtractionStatus = TextExtractionResult.TextExtractionStatus;
		
	Else
		AttachedFile.TextStorage = New ValueStorage("");
		AttachedFile.TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
	EndIf;
	
	If Not ValueIsFilled(AttachedFile.ChangedBy) Then
		AttachedFile.ChangedBy = Users.AuthorizedUser();
	EndIf;
	
	Context = FilesOperationsInternal.FileUpdateContext(AttachedFile, FileAddressInTempStorage, NewRefToFile);
	FileManager = FilesOperationsInternal.FilesManager(AttachedFile);
	FileManager.BeforeUpdatingTheFileData(Context);
	
	BeginTransaction();
	Try
		
		FileManager.BeforeWritingFileData(Context, AttachedFile);
		AttachedFile.Write();
		
		If StoreVersions Then
			
			If AttachedFile.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
				FileProperties = FilesOperationsInVolumesInternal.FilePropertiesInVolume(AttachedFile.Ref);
				FileAddressInTempStorage = FilesOperationsInVolumesInternal.FullFileNameInVolume(FileProperties);
				SourceFile = New File(FileAddressInTempStorage);
				FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion", SourceFile);
			Else
				FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion");
				FileInfo1.ExtensionWithoutPoint = ExtensionWithoutPoint;
				FileInfo1.BaseName   = BaseName;
				FileInfo1.Size             = AttachedFile.Size;
			EndIf;
			
			FileInfo1.TempFileStorageAddress   = CommonClientServer.StructureProperty(
																Context, 
																"PathToFile",
																FileAddressInTempStorage);
			FileInfo1.TempTextStorageAddress  = TempTextStorageAddress;
			FileInfo1.WriteToHistory                = True;
			
			Version = FilesOperationsInternal.CreateVersion(AttachedFile.Ref, FileInfo1);
			FilesOperationsInternal.UpdateVersionInFile(AttachedFile.Ref, Version, TempTextStorageAddress);
		Else
			FileManager.WhenUpdatingFileData(Context, AttachedFile.Ref);
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorInfo = ErrorInfo();
		
		MessageTemplate = NStr("en = 'Error adding attachment ""%1"":
			|%2';");
		EventLogComment = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			BaseName + "." + ExtensionWithoutPoint,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
		WriteLogEvent(
			NStr("en = 'Files.Add attachment';",
			Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			,
			,
			EventLogComment);
		
		FileManager.AfterUpdatingTheFileData(Context, False);
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			BaseName + "." + ExtensionWithoutPoint,
			ErrorProcessing.BriefErrorDescription(ErrorInfo));
			
	EndTry;
	
	FileManager.AfterUpdatingTheFileData(Context, True);
	
	FilesOperationsOverridable.OnCreateFile(AttachedFile.Ref);
	Return AttachedFile.Ref;
	
EndFunction

// Returns personal settings for working with files.
//
// Returns:
//  Structure:
//    * ShowLockedFilesOnExit        - Boolean -  exists only if the
//                                                                  file management subsystem is implemented.
//    * PromptForEditModeOnOpenFile    - Boolean -  exists only if the
//                                                                  file management subsystem is implemented.
//    * ShowSizeColumn                          - Boolean -  exists only if the
//                                                                  file management subsystem is implemented.
//    * ActionOnDoubleClick                     - String -  exists only if the
//                                                                  file management subsystem is implemented.
//    * FileVersionsComparisonMethod                      - String -  exists only if the
//                                                                  file management subsystem is implemented.
//    * GraphicalSchemasExtension                       - String -  list of extensions for graphic diagrams.
//    * GraphicalSchemasOpeningMethod                   - EnumRef.OpenFileForViewingMethods -  method
//                                                       for opening graphic diagrams.
//    * TextFilesExtension                         - String -  file extensions for open document formats.
//    * TextFilesOpeningMethod                     - EnumRef.OpenFileForViewingMethods -  method
//                                                       for opening text files.
//    * LocalFileCacheMaxSize           - Number -  specifies the maximum size of the local file cache.
//    * ShowFileNotModifiedFlag          - Boolean -  show files at shutdown.
//    * ShowTooltipsOnEditFiles       - Boolean -  and the web client shows hints when
//                                                                  editing files.
//    * PathToLocalFileCache                        - String -  path to the local file cache.
//    * IsFullUser                      - Boolean - 
//                                                           
//    * DeleteFileFromLocalFileCacheOnCompleteEdit - Boolean -  deleting files from the local cache when
//                                                                              editing is complete.
//
Function FilesOperationSettings() Export
	
	Return FilesOperationsInternalCached.FilesOperationSettings().PersonalSettings;
	
EndFunction

// Returns the maximum file size.
//
// Returns:
//  Number - 
//
Function MaxFileSize() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	SeparationEnabledAndAvailableUsage = (Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable());
		
	ConstantName = ?(SeparationEnabledAndAvailableUsage, "MaxDataAreaFileSize", "MaxFileSize");
	
	MaxFileSize = Constants[ConstantName].Get();
	
	If Not ValueIsFilled(MaxFileSize) Then
		MaxFileSize = 52428800; // 
	EndIf;
	
	If SeparationEnabledAndAvailableUsage Then
		GlobalMaxFileSize = Constants.MaxFileSize.Get();
		GlobalMaxFileSize = ?(ValueIsFilled(GlobalMaxFileSize),
			GlobalMaxFileSize, 52428800);
		MaxFileSize           = Min(MaxFileSize, GlobalMaxFileSize);
	EndIf;
	
	Return MaxFileSize;
	
EndFunction

// Returns the maximum file size of the provider.
//
// Returns:
//  Number - 
//
Function MaxFileSizeCommon() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	MaxFileSize = Constants.MaxFileSize.Get();
	
	If MaxFileSize = Undefined
	 Or MaxFileSize = 0 Then
		
		MaxFileSize = 50*1024*1024; // 
	EndIf;
	
	Return MaxFileSize;
	
EndFunction

// Saves settings for working with files.
//
// Parameters:
//  FilesOperationSettings - Structure - :
//     * ShowFileNotModifiedFlag        - Boolean -  optional. Show a message if the file has not
//                                                      been modified.
//     * ShowLockedFilesOnExit      - Boolean -  optional. Show files at shutdown.
//     * ShowSizeColumn                        - Boolean - 
//                                                      
//     * TextFilesExtension                       - String -  file extensions for open document formats.
//     * TextFilesOpeningMethod                   - EnumRef.OpenFileForViewingMethods -  method
//                                                      for opening text files.
//     * GraphicalSchemasExtension                     - String -  list of image file extensions.
//     * ShowTooltipsOnEditFiles     - Boolean -  optional. Show hints
//                                                      when editing files in the web client.
//     * PromptForEditModeOnOpenFile  - Boolean -  optional. Select the editing mode when
//                                                      opening the file.
//     * FileVersionsComparisonMethod                    - EnumRef.FileVersionsComparisonMethods -
//                                                        optional. Method for comparing versions and files.
//     * ActionOnDoubleClick                   - EnumRef.DoubleClickFileActions -  optional.
//     * GraphicalSchemasOpeningMethod                 - EnumRef.OpenFileForViewingMethods -
//                                                        optional. Method for opening the file for viewing.
//
Procedure SaveFilesOperationSettings(FilesOperationSettings) Export
	
	FilesOperationSettingsObjectsKeys = FilesOperationSettingsObjectsKeys();
	
	For Each Setting In FilesOperationSettings Do
		
		ObjectKeySettings = FilesOperationSettingsObjectsKeys[Setting.Key];
		If ObjectKeySettings <> Undefined Then
			If StrStartsWith(ObjectKeySettings, "OpenFileSettings\") Then
				SettingFilesType = StrReplace(ObjectKeySettings, "OpenFileSettings\", "");
				Common.CommonSettingsStorageSave(ObjectKeySettings,
					StrReplace(Setting.Key, SettingFilesType, ""), Setting.Value);
			Else
				Common.CommonSettingsStorageSave(ObjectKeySettings, Setting.Key, Setting.Value);
			EndIf;
			
		EndIf;
	
	EndDo;
	
EndProcedure

// Returns object details that can be edited
// by processing group changes to details.
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	AttributesToEdit = New Array;
	AttributesToEdit.Add("LongDesc");
	AttributesToEdit.Add("BeingEditedBy");
	
	Return AttributesToEdit;
	
EndFunction

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
// Parameters:
//   FilesOwner - DefinedType.AttachedFilesOwner -  the owner is the receiver of the files.
//   Source - String - 
//                       
//   Receiver - String - 
//                       
//
// Returns:
//  Map of KeyAndValue:
//   * Key     - DefinedType.AttachedFile - 
//                                                     
//   * Value - DefinedType.AttachedFile -  generated file.
//
Function MoveFilesBetweenStorageCatalogs(Val FilesOwner, Val Source = Undefined,
	Val Receiver = Undefined) Export
	
	If Not ValueIsFilled(FilesOwner) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The %1 parameter value is not set in %2.';"), 
			"FilesOwner","FilesOperations.ConvertFilesToAttachedFiles");
	EndIf;
	
	If Source = Undefined Or Receiver = Undefined Then
		CatalogNames = FilesOperationsInternal.FileStorageCatalogNames(FilesOwner, True);
		For Each CatalogName In CatalogNames Do
			If Source = Undefined And Not CatalogName.Value Then
				Source = Metadata.Catalogs[CatalogName.Key].FullName();
			EndIf;
			
			If Receiver = Undefined And CatalogName.Value Then
				Receiver = Metadata.Catalogs[CatalogName.Key].FullName();
			EndIf;
		EndDo;
	EndIf;

	ErrorTitle = NStr("en = 'Error converting attachments.';");
	
	If Source = Receiver Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTitle + Chars.LF
			+ NStr("en = 'Destination catalog is same as source catalog (%1).';"),
			Source);
	EndIf;
	
	DestinationName = Metadata.FindByFullName(Receiver).Name;
	
	Result = New Map;
	CatalogName = FilesOperationsInternal.FileStoringCatalogName(
	FilesOwner, DestinationName, ErrorTitle);
	
	SourceFiles = FilesOperationsInternal.GetAllSubordinateFiles(FilesOwner, Source);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	AttachedFilesManager = Catalogs[CatalogName];
	
	HasObjectVersioning = Metadata.Catalogs.Files.FullName() = Source;
	
	For Each SourceFile1 In SourceFiles Do
		BeginTransaction();
		Try
			
			DataLock = New DataLock;
			DataLockItem = DataLock.Add(Source);
			DataLockItem.SetValue("Ref", SourceFile1);
			DataLock.Lock();
			
			SourceFileObject = SourceFile1.GetObject();
			If SourceFileObject <> Undefined And Not SourceFileObject.DeletionMark Then
				
				If HasObjectVersioning Then
					CorrectRef = True;
					If ValueIsFilled(SourceFileObject.CurrentVersion) Then
						CurrentVersionObject = SourceFileObject.CurrentVersion.GetObject();
						If CurrentVersionObject <> Undefined Then
							DataLock = New DataLock;
							DataLockItem = DataLock.Add(Metadata.Catalogs.FilesVersions.FullName());
							DataLockItem.SetValue("Ref", SourceFileObject.CurrentVersion);
							DataLock.Lock();
						Else
							CorrectRef = False;
						EndIf;
						
					Else
						CurrentVersionObject = SourceFileObject;
					EndIf;
					
					If CorrectRef Then
						// 
						RefToAttachedFile = CreateAttachedFileBasedOnFile(FilesOwner, 
							AttachedFilesManager, SourceFileObject, CurrentVersionObject);
						
						If ValueIsFilled(SourceFileObject.CurrentVersion) Then
							CurrentVersionObject.AdditionalProperties.Insert("FileConversion", True);
							CurrentVersionObject.Write();
						EndIf;
						
						SourceFileObject.AdditionalProperties.Insert("FileConversion", True);
						SourceFileObject.Write();
						Result.Insert(SourceFileObject.Ref, RefToAttachedFile);
					EndIf;
				Else
					// 
					RefToAttachedFile = CreateAttachedFileBasedOnFile(FilesOwner, 
						AttachedFilesManager, SourceFileObject);
					
					SourceFileObject.AdditionalProperties.Insert("FileConversion", True);
					SourceFileObject.Write();
					Result.Insert(SourceFileObject.Ref, RefToAttachedFile);
				EndIf;
			EndIf;
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
	Return Result;
	
EndFunction

// Event handler for writing the file owner form to the server.
//
// Parameters:
//  Cancel           - Boolean  -  standard parameter event of the form.
//  CurrentObject   - DefinedType.AttachedFilesOwnerObject -  standard parameter event of the form.
//  WriteParameters - Structure -  standard parameter event of the form.
//  Form           - ClientApplicationForm - 
//
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters, Form) Export
	
	If TypeOf(Form) = Type("ClientApplicationForm") Then
		FilesOperationsParameters = Form.FilesOperationsParameters;
		SettingsOfFileManagementInForm = FilesOperationsParameters.SettingsOfFileManagementInForm;
	Else
		SettingsOfFileManagementInForm = SettingsOfFileManagementInForm();
		SettingsOfFileManagementInForm.DuplicateAttachedFiles = Not ValueIsFilled(Form.Key) 
			And Form.Property("CopyingValue") And ValueIsFilled(Form.CopyingValue);
		If SettingsOfFileManagementInForm.DuplicateAttachedFiles Then
			SettingsOfFileManagementInForm.Insert("CopyingValue", Form.CopyingValue);
		EndIf;
	EndIf;
		
	If SettingsOfFileManagementInForm.DuplicateAttachedFiles Then
		
		FilesOperationsInternal.CopyAttachedFiles(
			SettingsOfFileManagementInForm.CopyingValue, CurrentObject.Ref);
	EndIf;
	
EndProcedure

// Places hyperlinks and fields of attached files on the form.
//
// Parameters:
//  Form               - ClientApplicationForm -  connection form.
//  ItemsToAdd1 - Structure
//                      - Array - 
//                      
//                       See FilesOperations.FilesHyperlink
//                      
//  SettingsOfFileManagementInForm - See FilesOperations.SettingsOfFileManagementInForm.
//                      
//
// Example:
//  1. Adding a hyperlink to attached files:
//   Parameteryperlinks = work with Files.Gipersalivaciu();
//   Parameter of the hyperlink.Placement = " Command Panel";
//   Work with files.Precontamination(GetObject, Parametrisierung);
//
//  2. Adding an image field:
//   Parametersfields = Workfiles.Polifila();
//   Parametritis.Pathname = " Object.Filerting";
//   Parametritis.Pucklerstrasse = "Adreslerini";
//   Work with files.Precontamination(GetObject, Parametrial);
//
//  3. Adding multiple controls:
//   addable Elements = New Array;
//   Adding elements.Add(Parametrisierung);
//   Adding elements.Add (Field Parametres);
//   Work with files.Append To The Server(This Is The Object That You Are Adding Elements To);
//
Procedure OnCreateAtServer(Form, ItemsToAdd1 = Undefined, SettingsOfFileManagementInForm = Undefined) Export
	
	If ItemsToAdd1 = Undefined Then
		Return;
	EndIf;
	
	If SettingsOfFileManagementInForm = Undefined Then
		SettingsOfFileManagementInFormAdvanced = SettingsOfFileManagementInForm();
	Else
		SettingsOfFileManagementInFormAdvanced = Common.CopyRecursive(SettingsOfFileManagementInForm); 
	EndIf;
	
	If Not Form.Parameters.Property("CopyingValue") And (Not Form.Parameters.Property("Key") 
		Or Not ValueIsFilled(Form.Parameters.Key)) Then
		SettingsOfFileManagementInFormAdvanced.DuplicateAttachedFiles = False;
	Else
		SettingsOfFileManagementInFormAdvanced.Insert("CopyingValue", Form.Parameters.CopyingValue);
	EndIf;
		
	If TypeOf(ItemsToAdd1) = Type("Structure") Then
		ItemParameters = ItemsToAdd1;
		ItemsToAdd1 = New Array;
		ItemsToAdd1.Add(ItemParameters);
	EndIf;
	
	ItemCount = ItemsToAdd1.Count();
	For IndexOf = 1 To ItemCount Do
		
		ItemToAdd = ItemsToAdd1[ItemCount - IndexOf];
		If ItemToAdd.Property("Visible")
			And Not ItemToAdd.Visible Then
			ItemsToAdd1.Delete(ItemCount - IndexOf);
		EndIf;
		
	EndDo;
	
	If ItemsToAdd1.Count() = 0 Then
		Return;
	EndIf;
	
	FormAttributes = Form.GetAttributes();
	
	AttributesToBeAdded = New Array;
	If FormAttributeByName(FormAttributes, "FilesOperationsParameters") = Undefined Then
		AttributesToBeAdded.Add(New FormAttribute("FilesOperationsParameters", New TypeDescription()));
	EndIf;
	
	For IndexOf = 0 To ItemsToAdd1.UBound() Do
		
		ItemNumber = Format(IndexOf, "NZ=0; NG=");
		ItemToAdd = ItemsToAdd1[IndexOf];
		If Not ItemToAdd.Property("DataPath") Then
			Continue;
		EndIf;
		
		If StrFind(ItemToAdd.DataPath, ".") Then
			FullDataPath = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
				ItemToAdd.DataPath, ".", True, True);
		Else
			FullDataPath = New Array;
			FullDataPath.Add(ItemToAdd.DataPath);
		EndIf;
		
		PlacementAttribute = FormAttributeByName(FormAttributes, FullDataPath[0]);
		If PlacementAttribute <> Undefined Then
			
			AttributePath1 = FullDataPath[0];
			For AttributeIndex = 1 To FullDataPath.UBound() Do
				
				SubordinateAttributes = Form.GetAttributes(AttributePath1);
				PlacementAttribute   = FormAttributeByName(SubordinateAttributes, FullDataPath[AttributeIndex]);
				If PlacementAttribute = Undefined Then
					Break;
				EndIf;
				
				AttributePath1 = AttributePath1 + "." + FullDataPath[AttributeIndex];
			EndDo;
			
		EndIf;
		
		If PlacementAttribute = Undefined Then
			
			TypeAttachedFiles = Metadata.DefinedTypes.AttachedFile.Type;
			PlacementAttribute = New FormAttribute("AttachedFileField" + ItemNumber, TypeAttachedFiles);
			AttributesToBeAdded.Add(PlacementAttribute);
			
			PlacementAttribute = Form["AttachedFileField" + ItemNumber];
			ItemToAdd.DataPath = "AttachedFileField" + ItemNumber;
			
		EndIf;
		
		If ItemToAdd.Property("ShowPreview")
			And ItemToAdd.ShowPreview Then
			
			If FormAttributeByName(FormAttributes, ItemToAdd.PathToPictureData) = Undefined Then
				
				PictureAttribute = New FormAttribute("AttachedFilePictureField" + ItemNumber,
					New TypeDescription("String"));
				AttributesToBeAdded.Add(PictureAttribute);
				
				ItemToAdd.PathToPictureData = "AttachedFilePictureField" + ItemNumber;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If AttributesToBeAdded.Count() > 0 Then
		Form.ChangeAttributes(AttributesToBeAdded);
	EndIf;
	
	FormElementsDetails = New Array;
	For IndexOf = 0 To ItemsToAdd1.UBound() Do
		
		ItemToAdd = ItemsToAdd1[IndexOf];
		FullOwnerDataPath = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			ItemToAdd.Owner, ".", True, True);
		
		AttachedFilesOwner = FormAttributeByName(FormAttributes, FullOwnerDataPath[0]);
		If AttachedFilesOwner = Undefined Then
			Continue;
		EndIf;
		
		AttributePath1 = FullOwnerDataPath[0];
		For AttributeIndex = 1 To FullOwnerDataPath.UBound() Do
			
			SubordinateAttributes         = Form.GetAttributes(AttributePath1);
			AttachedFilesOwner = FormAttributeByName(SubordinateAttributes, FullOwnerDataPath[AttributeIndex]);
			If AttachedFilesOwner = Undefined Then
				Break;
			EndIf;
			
			AttributePath1 = AttributePath1 + FullOwnerDataPath[AttributeIndex];
			
		EndDo;
		
		AttachedFilesOwner = Form[FullOwnerDataPath[0]];
		For Counter = 1 To FullOwnerDataPath.UBound() Do
			AttachedFilesOwner = AttachedFilesOwner[FullOwnerDataPath[Counter]];
		EndDo;
		
		FilesStorageCatalogName = FilesOperationsInternal.FileStoringCatalogName(
			AttachedFilesOwner, "", "", "");
			
		FileCatalogType = Type("CatalogRef." + FilesStorageCatalogName);
		MetadataOfCatalogWithFiles = Metadata.FindByType(FileCatalogType);
		
		If Not AccessRight("Read", MetadataOfCatalogWithFiles) Then
			Continue;
		EndIf;
		
		SynchronizationInfo = FilesOperationsInternal.SynchronizationInfo(AttachedFilesOwner);
		FilesBeingEditedInCloudService = SynchronizationInfo.Count() > 0;
		
		AdditionAvailable = Not FilesBeingEditedInCloudService
			And AccessRight("InteractiveInsert", MetadataOfCatalogWithFiles);
		AvailableUpdate = Not FilesBeingEditedInCloudService
			And AccessRight("Update", MetadataOfCatalogWithFiles);
		
		ItemParameters = New Structure;
		ItemParameters.Insert("OneFileOnly"          , False);
		ItemParameters.Insert("MaximumSize"      , 0);
		ItemParameters.Insert("SelectionDialogFilter"     , "");
		ItemParameters.Insert("DisplayCount"    , False);
		ItemParameters.Insert("PathToPictureData"  , "");
		ItemParameters.Insert("PathToPlacementAttribute", "");
		ItemParameters.Insert("NonselectedPictureText", "");
		FillPropertyValues(ItemParameters, ItemToAdd);
		
		ItemNumber = Format(IndexOf, "NZ=0; NG=");
		GroupName = "AttachedFilesManagementGroup" + ItemNumber;
		GroupTitle = NStr("en = 'Attachment management';") + " "+ ItemNumber;
		
		FormItemParameters = New Structure;
		FormItemParameters.Insert("GroupName",          GroupName);
		FormItemParameters.Insert("GroupTitle",    GroupTitle);
		FormItemParameters.Insert("ItemNumber",      ItemNumber);
		FormItemParameters.Insert("AvailableUpdate",  AvailableUpdate);
		FormItemParameters.Insert("AdditionAvailable", AdditionAvailable);
		
		If SettingsOfFileManagementInFormAdvanced.DuplicateAttachedFiles 
			 And ValueIsFilled(SettingsOfFileManagementInFormAdvanced.CopyingValue) Then
			 AttachedFilesOwner = SettingsOfFileManagementInFormAdvanced.CopyingValue;
		EndIf;
		
		If ItemToAdd.Property("DataPath") Then
			
			ItemParameters.PathToPlacementAttribute = ItemToAdd.DataPath;
			CreateFileField(Form, ItemToAdd, AttachedFilesOwner, FormItemParameters);
			
		Else
			CreateFilesHyperlink(Form, ItemToAdd, AttachedFilesOwner, FormItemParameters);
		EndIf;
		
		ItemParameters.Insert("PathToOwnerData", ItemToAdd.Owner);
		FormElementsDetails.Add(ItemParameters);
		
	EndDo;
	FilesOperationsParameters = New Structure("FormElementsDetails", New FixedArray(FormElementsDetails));
	FilesOperationsParameters.Insert("SettingsOfFileManagementInForm", New FixedStructure(SettingsOfFileManagementInFormAdvanced));
	
	Form["FilesOperationsParameters"] = New FixedStructure(FilesOperationsParameters);
	
EndProcedure

// Initializes the parameter structure for placing a hyperlink of attached files on the form.
//
// Returns:
//  Structure - :
//    * Owner                   - String -  name of the attribute that contains a link to the owner of the attached files.
//                                 The default value is " Object.Link".
//    * Location                 - String
//                                 - Undefined - 
//                                 
//                                 
//                                 
//                                 
//                                 
//    * Title                  - String -  the title of the hyperlink. The default value is "Files".
//    * DisplayTitleRight  - Boolean -  if the parameter is set to True, the header
//                                 will be displayed after the add commands, otherwise it will be displayed before the add commands.
//                                 The default value is True;
//    * DisplayCount       - Boolean -  if the parameter is set to True, it displays
//                                 the number of attached files in the header. The default value is True.
//    * AddFiles2             - Boolean -  if you specify False, there will be no commands for adding files.
//                                 The default value is True.
//    * ShapeRepresentation          - String -  string representation of the "figure Display" property for
//                                 commands for adding attached files. The default value is "auto".
//    * Visible                  - Boolean -  if the parameter is set to False, the hyperlink
//                                 will not be placed on the form. The parameter makes sense only for the global disable visibility
//                                 in the procedure Remotefilenamecharset.When defining hyperlink files.
//
Function FilesHyperlink() Export
	
	HyperlinkParameters = New Structure;
	HyperlinkParameters.Insert("Owner",                  "Object.Ref");
	HyperlinkParameters.Insert("Location",                "AttachedFilesManagement");
	HyperlinkParameters.Insert("Title",                 NStr("en = 'Attachments';"));
	HyperlinkParameters.Insert("DisplayTitleRight", True);
	HyperlinkParameters.Insert("DisplayCount",      True);
	HyperlinkParameters.Insert("AddFiles2",            True);
	HyperlinkParameters.Insert("ShapeRepresentation",         "Auto");
	HyperlinkParameters.Insert("Visible",                 True);
	
	FilesOperationsOverridable.OnDefineFilesHyperlink(HyperlinkParameters);
	
	Return HyperlinkParameters;
	
EndFunction

// Initializes the parameter structure for placing the attached file field on the form.
//
// Returns:
//  Structure - :
//    * Owner                  - String -  name of the attribute that contains a link to the owner of the attached files.
//                                The default value is " Object.Link".
//    * Location                - String
//                                - Undefined - 
//                                
//                                
//                                
//                                
//    * DataPath               - String
//                                - Undefined - 
//                                
//                                
//                                
//    * PathToPictureData    - String
//                                - Undefined - 
//                                
//                                
//                                
//    * OneFileOnly            - Boolean -  if set to True,
//                                only one file can be attached using the add commands. After adding the first file, the "Add" command
//                                will replace the existing file with the file selected by the user, and clicking on 
//                                the title will open the file for viewing. The default value is False.
//    * ShowPreview    - Boolean -  if the parameter is set to True, it adds
//                                a preview area of the attached file to the form. The default value is True.
//    * NonselectedPictureText  - String -  displayed in the image preview field if 
//                                the image is missing. The default value is "Add image".
//    * Title                 - String -  if the header differs from an empty string, it adds the header
//                                of the attached file field to the form. The default value is "".
//    * OutputFileTitle    - Boolean -  if the parameter is set to True, it adds a hyperlink
//                                whose header corresponds to the short file name. If the value
//                                of the "Title" parameter is different from "", the file title will be added after the General title
//                                of the control. The default value is False.
//    * ShowCommandBar - Boolean -  if the parameter is set to True, the commands will be placed in 
//                                the command panel on the form and in the context menu of the preview element, otherwise
//                                only in the context menu of the preview element. The default value is True.
//    * AddFiles2            - Boolean -  if you specify False, there will be no commands for adding files.
//                                The default value is True.
//    * NeedSelectFile              - Boolean -  if the parameter is set to True, it adds a command to select a file
//                                from the attached files. The default value is True.
//    * ViewFile         - Boolean -  if the parameter is set to True, it adds a command to open
//                                the file for viewing. The default value is True.
//    * EditFile         - String -  if the parameter is set to "in Form", it adds a command
//                                to open the attached file form. If the parameter takes the value
//                                "Directly", it adds commands for editing the file, saving and undoing
//                                changes. If it is set to "non-Edit", no editing commands will be added
//                                . The default value is "in Form".
//    * ClearFile               - Boolean -  if the parameter is set to True, it adds a command to clear 
//                                the owner's props. The default value is True.
//    * MaximumSize        - Number -  limit on the size of the file (in megabytes) that can be downloaded from the file system.
//                                If it is set to 0, the size check is not performed. This property is ignored
//                                if it takes a value greater than specified in the maximum file Size constant.
//                                The default value is 0.
//    * SelectionDialogFilter       - String -  the filter that is set in the selection dialog when adding a file.
//                                For the format, see the Filter property of the Dialog File Selection object in the Syntax Assistant.
//                                The default value is "All files (*.*)|*.*"
//
Function FileField() Export
	
	FieldParameters = New Structure;
	FieldParameters.Insert("Owner",                  "Object.Ref");
	FieldParameters.Insert("Location",                "AttachedFilesManagement");
	FieldParameters.Insert("DataPath",               "AttachedFileField");
	FieldParameters.Insert("PathToPictureData",    Undefined);
	FieldParameters.Insert("OneFileOnly",            False);
	FieldParameters.Insert("ShowPreview",    True);
	FieldParameters.Insert("NonselectedPictureText",  NStr("en = 'Add image';"));
	FieldParameters.Insert("Title",                 "");
	FieldParameters.Insert("OutputFileTitle",    False);
	FieldParameters.Insert("ShowCommandBar", True);
	FieldParameters.Insert("AddFiles2",            True);
	FieldParameters.Insert("NeedSelectFile",              True);
	FieldParameters.Insert("ViewFile",         True);
	FieldParameters.Insert("EditFile",         "InForm");
	FieldParameters.Insert("ClearFile",               True);
	FieldParameters.Insert("MaximumSize",        0);
	FieldParameters.Insert("SelectionDialogFilter", 
		StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'All files (%1)|%1';"), GetAllFilesMask()));
	
	Return FieldParameters;
	
EndFunction

// Determines whether there are active file storage volumes.
// If there is at least one file storage volume, it will return True.
//
// Returns:
//  Boolean - 
//
Function HasFileStorageVolumes() Export
	
	Return FilesOperationsInVolumesInternal.HasFileStorageVolumes();
	
EndFunction

// Adds an electronic signature to the file.
//
// Parameters:
//  AttachedFile - DefinedType.AttachedFile -  link to the directory element with the file.
//
//  SignatureProperties    - See DigitalSignatureClientServer.NewSignatureProperties
//                     
//                     
//  FormIdentifier - UUID -  if specified, it is used when locking the object.
//
Procedure AddSignatureToFile(AttachedFile, SignatureProperties, FormIdentifier = Undefined) Export
	
	If Common.IsReference(TypeOf(AttachedFile)) Then
		AttributesStructure1 = Common.ObjectAttributesValues(AttachedFile, "BeingEditedBy, Encrypted");
		AttachedFileRef = AttachedFile;
	Else
		AttributesStructure1 = New Structure("BeingEditedBy, Encrypted");
		AttributesStructure1.BeingEditedBy = AttachedFile.BeingEditedBy;
		AttributesStructure1.Encrypted  = AttachedFile.Encrypted;
		AttachedFileRef = AttachedFile.Ref;
	EndIf;
	
	CommonClientServer.CheckParameter("AttachedFiles.AddSignatureToFile", "AttachedFile", 
		AttachedFileRef, Metadata.DefinedTypes.AttachedFile.Type);
		
	If ValueIsFilled(AttributesStructure1.BeingEditedBy) Then
		Raise FilesOperationsInternalClientServer.MessageAboutInvalidSigningOfLockedFile(AttachedFileRef);
	EndIf;
	
	If AttributesStructure1.Encrypted Then
		Raise FilesOperationsInternalClientServer.MessageAboutInvalidSigningOfEncryptedFile(AttachedFileRef);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
		ModuleDigitalSignature.AddSignature(AttachedFile, SignatureProperties, FormIdentifier);
	EndIf;
	
EndProcedure

// When programmatically copying a Source, it creates copies of all
// attached files from the Recipient. For interactive copying, you must use
// the procedure for working with Files.When writing to the server.
// The source and Destination must be objects of the same type.
//
// Parameters:
//  Source   - AnyRef -  an object that has attached files to copy.
//  Recipient - AnyRef -  the object that the attached files are copied to.
//
Procedure CopyAttachedFiles(Val Source, Val Recipient) Export
	
	FilesOperationsInternal.CopyAttachedFiles(Source, Recipient);
	
EndProcedure

// 
//
// Returns:
//  Structure - :
//    * DuplicateAttachedFiles - Boolean - 
//                                   
//
Function SettingsOfFileManagementInForm() Export
	
	SettingsOfFileManagementInForm = New Structure;
	SettingsOfFileManagementInForm.Insert("DuplicateAttachedFiles", False);
	
	Return SettingsOfFileManagementInForm;
	
EndFunction

// 
// 
// Parameters:
//  ClientID - UUID - 
// 
// Returns:
//   See FilesOperationsClientServer.UserScanSettings
//
Function GetUserScanSettings(ClientID) Export
	
	Result = FilesOperationsClientServer.UserScanSettings();
	
	Result.ShowScannerDialog = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/ShowScannerDialog", 
		ClientID, True);
	
	Result.DeviceName = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/DeviceName", 
		ClientID, "");
	
	Result.ScannedImageFormat = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/ScannedImageFormat", 
		ClientID, Enums.ScannedImageFormats.PNG);
	If Result.ScannedImageFormat = Enums.ScannedImageFormats.EmptyRef() Then
		Result.ScannedImageFormat = Enums.ScannedImageFormats.PNG;	
	EndIf;
	
	Result.ShouldSaveAsPDF = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/ShouldSaveAsPDF", 
		ClientID, False);
	
	Result.MultipageStorageFormat = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/MultipageStorageFormat", 
		ClientID, Enums.MultipageFileStorageFormats.TIF);
	
	Result.Resolution = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/Resolution", 
		ClientID);
	
	Result.Chromaticity = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/Chromaticity", 
		ClientID);
	
	Result.Rotation = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/Rotation", 
		ClientID);
	
	Result.PaperSize = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/PaperSize", 
		ClientID);
	
	Result.DuplexScanning = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/DuplexScanning", 
		ClientID);
	
	Result.UseImageMagickToConvertToPDF =  Common.CommonSettingsStorageLoad(
		"ScanningSettings1/UseImageMagickToConvertToPDF", 
		ClientID, False);
		
	Result.JPGQuality = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/JPGQuality", 
		ClientID, 100);
	
	Result.TIFFDeflation = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/TIFFDeflation", 
		ClientID, Enums.TIFFCompressionTypes.NoCompression);
	
	Result.PathToConverterApplication = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/PathToConverterApplication", 
		ClientID, ""); // ImageMagick
		
	Result.ScanLogCatalog = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/ScanLogCatalog", 
		ClientID, ""); 
		
	Result.UseScanLogDirectory = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/UseScanLogDirectory", 
		ClientID, False);
		
	Return Result;
EndFunction

// 
//
// Parameters:
//  UserScanSettings - See FilesOperationsClientServer.UserScanSettings
//  ClientID - UUID
//
Procedure SaveUserScanSettings(UserScanSettings, ClientID) Export

	Result = New Array;
	
	Result.Add(FilesOperationsInternal.ScanningSettings("ShowScannerDialog",
		UserScanSettings.ShowScannerDialog, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("DeviceName",
		UserScanSettings.DeviceName, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("ScannedImageFormat",
		UserScanSettings.ScannedImageFormat, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("ShouldSaveAsPDF",
		UserScanSettings.ShouldSaveAsPDF, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("MultipageStorageFormat",
		UserScanSettings.MultipageStorageFormat, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("Resolution",
		UserScanSettings.Resolution, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("Chromaticity",
		UserScanSettings.Chromaticity, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("Rotation",
		UserScanSettings.Rotation, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("PaperSize",
		UserScanSettings.PaperSize, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("DuplexScanning",
		UserScanSettings.DuplexScanning, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("UseImageMagickToConvertToPDF",
		UserScanSettings.UseImageMagickToConvertToPDF, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("JPGQuality",
		UserScanSettings.JPGQuality, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("TIFFDeflation",
		UserScanSettings.TIFFDeflation, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("PathToConverterApplication",
		UserScanSettings.PathToConverterApplication, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("ScanLogCatalog",
		UserScanSettings.ScanLogCatalog, ClientID));
	Result.Add(FilesOperationsInternal.ScanningSettings("UseScanLogDirectory",
		UserScanSettings.UseScanLogDirectory, ClientID));
	
	CommonServerCall.CommonSettingsStorageSaveArray(Result, True);
EndProcedure

#Region ForCallsFromOtherSubsystems

// ElectronicInteraction

// 

// Transfers information about electronic signatures of a file from the tabular part of the file to the information register.
//
// Parameters:
//   Parameters - Structure -  parameters for executing the deferred update handler.
//
Procedure MoveDigitalSignaturesAndEncryptionCertificatesToInformationRegisters(Parameters) Export  // 
	// 
EndProcedure

// End ElectronicInteraction

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
// 
// 
// Parameters:
//   FilesOwner    - DefinedType.AttachedFilesOwner -  the file folder or object
//                       to attach the file to.
//   FilePathOnHardDrive - String - 
//                       
//
// Returns:
//  DefinedType.AttachedFile - 
//
Function CreateFileBasedOnFileOnHardDrive(FilesOwner, FilePathOnHardDrive) Export
	
	Return AddFileFromHardDrive(FilesOwner, FilePathOnHardDrive);
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  Source                 - CatalogManager -  directory Manager with the name "*Attached files".
//  FormType                 - String -  name of the standard form.
//  Parameters                - Structure -  shape parameter.
//  SelectedForm           - String -  name or metadata object of the form to open.
//  AdditionalInformation - Structure -  additional information for opening the form.
//  StandardProcessing     - Boolean -  indicates whether standard (system) event processing is performed.
//
Procedure DetermineAttachedFileForm(Source, FormType, Parameters,
	SelectedForm, AdditionalInformation, StandardProcessing) Export
	
	FilesOperationsClientServer.DetermineAttachedFileForm(
		Source, FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing);
	
EndProcedure

// Deprecated.
//
//  
// 
//
// 
// 
// 
//
// Parameters:
//   FilesOwner - AnyRef -  a reference to the object that is being converted.
//   CatalogName - String -  if conversion to the specified storage is required.
//
Procedure ChangeFilesStoragecatalog(Val FilesOwner, CatalogName = Undefined) Export
	
	If Not ValueIsFilled(FilesOwner) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The %1 parameter value is not set in %2.';"), "FilesOwner","FilesOperations.ChangeFilesStoragecatalog");
	EndIf;
	
	ErrorTitle = NStr("en = 'Error converting attachments.';");
	CatalogName = FilesOperationsInternal.FileStoringCatalogName(
		FilesOwner, CatalogName, ErrorTitle);
	
	SetSafeModeDisabled(True);	
	SetPrivilegedMode(True);
	
	SourceFiles = FilesOperationsInternal.GetAllSubordinateFiles(FilesOwner);
	AttachedFilesManager = Catalogs[CatalogName];
	
	For Each SourceFile1 In SourceFiles Do
		BeginTransaction();
		Try
		
			DataLock = New DataLock;
			DataLockItem = DataLock.Add(Metadata.Catalogs.Files.FullName());
			DataLockItem.SetValue("Ref", SourceFile1);
			DataLock.Lock();

			SourceFileObject = SourceFile1.GetObject();
			If SourceFileObject = Undefined Or SourceFileObject.DeletionMark Then
				CommitTransaction();
				Continue;
			EndIf;
			
			If ValueIsFilled(SourceFileObject.CurrentVersion) Then
				DataLock = New DataLock;
				DataLockItem = DataLock.Add(Metadata.Catalogs.FilesVersions.FullName());
				DataLockItem.SetValue("Ref", SourceFileObject.CurrentVersion);
				DataLock.Lock();
				
				CurrentVersionObject = SourceFileObject.CurrentVersion.GetObject();
			Else
				CurrentVersionObject = SourceFileObject;
			EndIf;
			
			RefToNew = AttachedFilesManager.GetRef();
			AttachedFile = AttachedFilesManager.CreateItem(); // DefinedType.AttachedFileObject
			AttachedFile.SetNewObjectRef(RefToNew);
			
			AttachedFile.FileOwner                = FilesOwner;
			AttachedFile.Description                 = SourceFileObject.Description;
			AttachedFile.Author                        = SourceFileObject.Author;
			AttachedFile.UniversalModificationDate = CurrentVersionObject.UniversalModificationDate;
			AttachedFile.CreationDate                 = SourceFileObject.CreationDate;
			
			AttachedFile.Encrypted                   = SourceFileObject.Encrypted;
			AttachedFile.ChangedBy                      = CurrentVersionObject.Author;
			AttachedFile.LongDesc                     = SourceFileObject.LongDesc;
			AttachedFile.SignedWithDS                   = SourceFileObject.SignedWithDS;
			AttachedFile.Size                       = CurrentVersionObject.Size;
			
			AttachedFile.Extension                   = CurrentVersionObject.Extension;
			AttachedFile.BeingEditedBy                  = SourceFileObject.BeingEditedBy;
			AttachedFile.TextStorage               = SourceFileObject.TextStorage;
			AttachedFile.FileStorageType             = CurrentVersionObject.FileStorageType;
			AttachedFile.DeletionMark              = SourceFileObject.DeletionMark;
			
			// 
			AttachedFile.Volume                          = CurrentVersionObject.Volume;
			AttachedFile.PathToFile                   = CurrentVersionObject.PathToFile;
			
			For Each EncryptionCertificateRow In SourceFileObject.DeleteEncryptionCertificates Do
				NewRow = AttachedFile.DeleteEncryptionCertificates.Add();
				FillPropertyValues(NewRow, EncryptionCertificateRow);
			EndDo;
			
			If ValueIsFilled(SourceFileObject.CurrentVersion) Then
				For Each DigitalSignatureString In CurrentVersionObject.DeleteDigitalSignatures Do
					NewRow = AttachedFile.DeleteDigitalSignatures.Add();
					FillPropertyValues(NewRow, DigitalSignatureString);
				EndDo;
			EndIf;
			AttachedFile.Fill(Undefined);
			
			AttachedFile.Write();
			
			If AttachedFile.FileStorageType = Enums.FileStorageTypes.InInfobase Then
				//  
				FileStorage1 = FileFromInfobaseStorage(CurrentVersionObject.Ref);
				
				InformationRegisters.FileRepository.WriteBinaryData(RefToNew, FileStorage1.Get());
			EndIf;
			
			CurrentVersionObject.DeletionMark = True;
			SourceFileObject.DeletionMark = True;
			
			// 
			If CurrentVersionObject.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
				CurrentVersionObject.PathToFile = "";
				CurrentVersionObject.Volume = Catalogs.FileStorageVolumes.EmptyRef();
				SourceFileObject.PathToFile = "";
				SourceFileObject.Volume = "";
				If ValueIsFilled(SourceFileObject.CurrentVersion) Then
					FilesOperationsInternal.MarkForDeletionFileVersions(SourceFileObject.Ref, CurrentVersionObject.Ref);
				EndIf;
			EndIf;
			
			If ValueIsFilled(SourceFileObject.CurrentVersion) Then
				CurrentVersionObject.AdditionalProperties.Insert("FileConversion", True);
				CurrentVersionObject.Write();
			EndIf;
			
			SourceFileObject.AdditionalProperties.Insert("FileConversion", True);
			SourceFileObject.Write();
			
			CommitTransaction();
		
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

// Deprecated. 
//  
// 
//
// 
// 
// 
// 
//
// Parameters:
//   FilesOwner - DefinedType.AttachedFilesOwner -  the owner is the receiver of the files.
//   CatalogName - String -  if conversion to the specified storage is required.
//
// Returns:
//  Map of KeyAndValue:
//   * Key     - CatalogRef.Files -  a migrated file that is marked for deletion after migration.
//   * Value - DefinedType.AttachedFile -  generated file.
//
Function ConvertFilesToAttachedFiles(Val FilesOwner, CatalogName = Undefined) Export
	
	Return MoveFilesBetweenStorageCatalogs(FilesOwner, Metadata.Catalogs.Files.FullName(), CatalogName);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function EncryptedFilesExtension() Export
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
		Return ModuleDigitalSignature.PersonalSettings().EncryptedFilesExtension;
	Else
		Return "p7m";
	EndIf;
	
EndFunction

// Utility function for converting Filesconnected
//
Function CreateAttachedFileBasedOnFile(Val FilesOwner, Val AttachedFilesManager, 
	Val SourceFileObject, Val CurrentVersionObject = Undefined)
	
	RefToNew = AttachedFilesManager.GetRef(); // DefinedType.AttachedFile
	AttachedFile = AttachedFilesManager.CreateItem(); // DefinedType.AttachedFileObject
	AttachedFile.SetNewObjectRef(RefToNew);
	
	VersioningUsed = True;
	
	If CurrentVersionObject = Undefined Then
		VersioningUsed = False;
		CurrentVersionObject = New Structure;
		CurrentVersionObject.Insert("UniversalModificationDate", SourceFileObject.UniversalModificationDate);
		CurrentVersionObject.Insert("Description", SourceFileObject.Description);
		CurrentVersionObject.Insert("Author", SourceFileObject.Author);
		CurrentVersionObject.Insert("CreationDate", SourceFileObject.CreationDate);
		CurrentVersionObject.Insert("Size", SourceFileObject.Size);
		CurrentVersionObject.Insert("Extension", SourceFileObject.Extension);
		CurrentVersionObject.Insert("FileStorageType", SourceFileObject.FileStorageType);
		CurrentVersionObject.Insert("Volume", SourceFileObject.Volume);
		CurrentVersionObject.Insert("PathToFile", SourceFileObject.PathToFile);
		CurrentVersionObject.Insert("CurrentVersion", Undefined);
		CurrentVersionObject.Insert("DeleteDigitalSignatures", SourceFileObject.DeleteDigitalSignatures.Unload());
		CurrentVersionObject.Insert("Ref", SourceFileObject.Ref);
	EndIf;
	
	AttachedFile.FileOwner                = FilesOwner;
	AttachedFile.Description                 = SourceFileObject.Description;
	AttachedFile.Author                        = SourceFileObject.Author;
	AttachedFile.UniversalModificationDate = CurrentVersionObject.UniversalModificationDate;
	AttachedFile.CreationDate                 = SourceFileObject.CreationDate;
	
	AttachedFile.Encrypted                   = SourceFileObject.Encrypted;
	AttachedFile.ChangedBy                      = CurrentVersionObject.Author;
	AttachedFile.LongDesc                     = SourceFileObject.LongDesc;
	AttachedFile.SignedWithDS                   = SourceFileObject.SignedWithDS;
	AttachedFile.Size                       = CurrentVersionObject.Size;
	
	AttachedFile.Extension                   = CurrentVersionObject.Extension;
	AttachedFile.BeingEditedBy                  = SourceFileObject.BeingEditedBy;
	AttachedFile.TextStorage               = SourceFileObject.TextStorage;
	AttachedFile.FileStorageType             = CurrentVersionObject.FileStorageType;
	AttachedFile.DeletionMark              = SourceFileObject.DeletionMark;
	
	// 
	AttachedFile.Volume                          = CurrentVersionObject.Volume;
	AttachedFile.PathToFile                   = CurrentVersionObject.PathToFile;
	
	For Each EncryptionCertificateRow In SourceFileObject.DeleteEncryptionCertificates Do
		NewRow = AttachedFile.DeleteEncryptionCertificates.Add();
		FillPropertyValues(NewRow, EncryptionCertificateRow);
	EndDo;
	
	If Not VersioningUsed Or ValueIsFilled(SourceFileObject.CurrentVersion) Then
		For Each DigitalSignatureString In CurrentVersionObject.DeleteDigitalSignatures Do
			NewRow = AttachedFile.DeleteDigitalSignatures.Add();
			FillPropertyValues(NewRow, DigitalSignatureString);
		EndDo;
	EndIf;
	AttachedFile.Fill(Undefined);
	
	AttachedFile.Write();
	
	If AttachedFile.FileStorageType = Enums.FileStorageTypes.InInfobase Then
		FileStorage1 = FileFromInfobaseStorage(CurrentVersionObject.Ref);
		
		// 
		// 
		If FileStorage1 <> Undefined Then
			SetPrivilegedMode(True);
			InformationRegisters.FileRepository.WriteBinaryData(RefToNew, FileStorage1.Get());
			SetPrivilegedMode(False);
		EndIf;
	EndIf;
	
	If VersioningUsed Then
		CurrentVersionObject.DeletionMark = True;
	EndIf;
	
	SourceFileObject.DeletionMark  = True;
	
	// 
	If CurrentVersionObject.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
		CurrentVersionObject.PathToFile        = "";
		CurrentVersionObject.Volume               = Catalogs.FileStorageVolumes.EmptyRef();
		SourceFileObject.PathToFile         = "";
		SourceFileObject.Volume                = "";
		If ValueIsFilled(SourceFileObject.CurrentVersion) Then
			FilesOperationsInternal.MarkForDeletionFileVersions(SourceFileObject.Ref, CurrentVersionObject.Ref);
		EndIf;
	EndIf;
	
	FilesOperationsOverridable.OnCreateFile(RefToNew);
	Return RefToNew;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Returns the entity key of the settings file.
// 
Function FilesOperationSettingsObjectsKeys()
	
	FilesOperationSettingsObjectsKeys = New Map;
	
	FilesOperationSettingsObjectsKeys.Insert("PromptForEditModeOnOpenFile" ,"OpenFileSettings");
	FilesOperationSettingsObjectsKeys.Insert("ActionOnDoubleClick",                  "OpenFileSettings");
	FilesOperationSettingsObjectsKeys.Insert("FileOpeningOption",                            "OpenFileSettings");
	FilesOperationSettingsObjectsKeys.Insert("ShowSizeColumn" ,                      "ApplicationSettings");
	FilesOperationSettingsObjectsKeys.Insert("ShowLockedFilesOnExit",     "ApplicationSettings");
	FilesOperationSettingsObjectsKeys.Insert("FileVersionsComparisonMethod",                   "FileComparisonSettings");
	
	FilesOperationSettingsObjectsKeys.Insert("TextFilesExtension" ,      "OpenFileSettings\TextFiles");
	FilesOperationSettingsObjectsKeys.Insert("TextFilesOpeningMethod" ,  "OpenFileSettings\TextFiles");
	FilesOperationSettingsObjectsKeys.Insert("GraphicalSchemasExtension" ,    "OpenFileSettings\GraphicalSchemas");
	FilesOperationSettingsObjectsKeys.Insert("GraphicalSchemasOpeningMethod" ,"OpenFileSettings\GraphicalSchemas");
	FilesOperationSettingsObjectsKeys.Insert("ShowTooltipsOnEditFiles" ,"ApplicationSettings");
	FilesOperationSettingsObjectsKeys.Insert("ShowFileNotModifiedFlag" ,   "ApplicationSettings");
	
	Return FilesOperationSettingsObjectsKeys;
	
EndFunction

// Marks / removes the delete mark for attached files.
Procedure MarkToDeleteAttachedFiles(Val Source, CatalogName = Undefined)
	
	If Source.IsNew() Then
		Return;
	EndIf;
	
	SourceRefDeletionMark = Common.ObjectAttributeValue(Source.Ref, "DeletionMark");	
	If Source.DeletionMark = SourceRefDeletionMark Then
		Return;
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Try
		CatalogNames = FilesOperationsInternal.FileStorageCatalogNames(TypeOf(Source.Ref));
	Except
		Raise NStr("en = 'Error marking attachments for deletion.';")
			+ Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	
	QueryTexts = New Array;
	QueryTemplate =
		"SELECT ALLOWED
		|	Files.Ref AS Ref,
		|	Files.BeingEditedBy AS BeingEditedBy
		|FROM
		|	&CatalogName AS Files
		|WHERE
		|	Files.FileOwner = &FileOwner";
	
	For Each CatalogNameDescription In CatalogNames Do
		
		FullCatalogName = "Catalog." + CatalogNameDescription.Key;
		QueryText = StrReplace(QueryTemplate, "&CatalogName", FullCatalogName);
		If QueryTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "SELECT ALLOWED", "SELECT"); // @query-part-1, @query-part-2
		EndIf;
		QueryTexts.Add(QueryText);
		
	EndDo;
	
	Query = New Query(StrConcat(QueryTexts, Chars.LF + "UNION ALL" + Chars.LF + Chars.LF)); // @query-part
	Query.SetParameter("FileOwner", Source.Ref);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Source.DeletionMark And ValueIsFilled(Selection.BeingEditedBy) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot delete ""%1""
				           |as it contains the ""%2"" attachment locked for editing.';"),
				Common.SubjectString(Source.Ref),
				String(Selection.Ref));
		EndIf;
		
		BeginTransaction();
		Try
			Block = New DataLock();
			LockItem = Block.Add(Selection.Ref.Metadata().FullName());
			LockItem.SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			FileObject1 = Selection.Ref.GetObject();
			FileObject1.Lock();
			FileObject1.SetDeletionMark(Source.DeletionMark);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise; 
		EndTry
		
	EndDo;
	
EndProcedure

// Returns the ID of the owner of the attached file.
Function GetObjectID(Val FilesOwner)
	
	QueryText =
		"SELECT
		|	FilesExist.ObjectID
		|FROM
		|	InformationRegister.FilesExist AS FilesExist
		|WHERE
		|	FilesExist.ObjectWithFiles = &ObjectWithFiles";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ObjectWithFiles", FilesOwner);
	ExecutionResult = Query.Execute();
	
	If ExecutionResult.IsEmpty() Then
		Return "";
	EndIf;
	
	Selection = ExecutionResult.Select();
	Selection.Next();
	
	Return Selection.ObjectID;
	
EndFunction

// Returns binary file data from the information database.
//
// Parameters:
//   FileRef - 
//
// Returns:
//   ValueStorage -  binary data of the file.
//
Function FileFromInfobaseStorage(FileRef) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	FileRepository.BinaryDataStorage.BinaryData AS FileBinaryData
	|FROM
	|	InformationRegister.FileRepository AS FileRepository
	|WHERE
	|	FileRepository.File = &FileRef";
	
	Query.SetParameter("FileRef", FileRef);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.FileBinaryData;
	EndIf;
	
	If FilesOperationsInternalCached.IsDeduplicationCompleted() Then
		Return Undefined;
	EndIf;
	
	Query.Text = 
	"SELECT
	|	DeleteFilesBinaryData.FileBinaryData AS FileBinaryData
	|FROM
	|	InformationRegister.DeleteFilesBinaryData AS DeleteFilesBinaryData
	|WHERE
	|	DeleteFilesBinaryData.File = &FileRef";
	Selection = Query.Execute().Select();
	
	Return ?(Selection.Next(), Selection.FileBinaryData, Undefined);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Handler for subscribing to the pre-Recording event to fill in the auto details of the attached file.
//
// Parameters:
//  Source   - CatalogObject -  directory object with the name "*Attached files".
//  Cancel      - Boolean -  parameter passed to the event subscription before Recording.
//
Procedure ExecuteActionsBeforeWriteAttachedFile(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Source.AdditionalProperties.Property("FileConversion") Then
		Return;
	EndIf;
	
	If TypeOf(Source) = Type("CatalogObject.FilesVersions") Then
		If Not Source.IsNew() And Not Users.IsFullUser() Then
			FormerValue = Common.ObjectAttributesValues(Source.Ref, "Author");
			CheckIfTheFileAuthorHasChanged(FormerValue, Source);
		EndIf;
		Return;
	EndIf;
	
	If Source.IsNew() Then
		// 
		If Not FilesOperationsInternal.HasRight("AddFilesAllowed", Source.FileOwner) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Insufficient rights to add files to folder ""%1.""';"),
				String(Source.FileOwner));
			Raise(MessageText, ErrorCategory.AccessViolation);
		EndIf;
	Else
		
		If Users.IsFullUser() Then
			FormerValue = Common.ObjectAttributesValues(Source.Ref, "DeletionMark");
		Else	
			FormerValue = Common.ObjectAttributesValues(Source.Ref, 
				"DeletionMark, Author, BeingEditedBy, ChangedBy");
			CheckIfTheFileAuthorHasChanged(FormerValue, Source);
		EndIf;
		
		DeletionMarkChanged = Source.DeletionMark <> FormerValue.DeletionMark;
		If DeletionMarkChanged Then
			If Not FilesOperationsInternal.HasRight("FilesDeletionMark", Source.FileOwner) Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Insufficient rights to mark files in folder ""%1"" for deletion.';"),
					String(Source.FileOwner));
				Raise(MessageText, ErrorCategory.AccessViolation);
			EndIf;
		EndIf;
		
		If DeletionMarkChanged And ValueIsFilled(Source.BeingEditedBy) Then
				
			If Source.BeingEditedBy = Users.AuthorizedUser() Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Cannot perform the operation because file ""%1"" file is locked for editing.';"),
					Source.Description);
			Else
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Cannot perform the operation because user %2
						|is editing file ""%1"".';"),
					Source.Description, String(Source.BeingEditedBy));
			EndIf;
			Raise MessageText;
			
		EndIf;
		
		WriteSignedObject = False;
		If Source.AdditionalProperties.Property("WriteSignedObject") Then
			WriteSignedObject = Source.AdditionalProperties.WriteSignedObject;
		EndIf;
		
		If WriteSignedObject <> True Then
			
			AttributesStructure1 = Common.ObjectAttributesValues(Source.Ref,
				"SignedWithDS, Encrypted, BeingEditedBy");
			
			RefSigned    = AttributesStructure1.SignedWithDS;
			RefEncrypted  = AttributesStructure1.Encrypted;
			RefLocked       = ValueIsFilled(AttributesStructure1.BeingEditedBy);
			Locked3 = ValueIsFilled(Source.BeingEditedBy);
			
			If Not Source.IsFolder And Source.SignedWithDS And RefSigned And Locked3 And Not RefLocked Then
				Raise NStr("en = 'Cannot edit the file because it has been signed.';");
			EndIf;
			
			If Not Source.IsFolder And Source.Encrypted And RefEncrypted And Source.SignedWithDS And Not RefSigned Then
				Raise NStr("en = 'Cannot sign an encrypted file.';");
			EndIf;
			
		EndIf;
		
		CatalogSupportsPossibitityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", Metadata.FindByType(TypeOf(Source)));
		
		If Not Source.IsFolder And CatalogSupportsPossibitityToStoreVersions And ValueIsFilled(Source.CurrentVersion) Then
			
			CurrentVersionAttributes = Common.ObjectAttributesValues(Source.CurrentVersion, "Description");
			
			// 
			// 
			If CurrentVersionAttributes.Description <> Source.Description
			   And ValueIsFilled(Source.CurrentVersion) Then
				
				DataLock = New DataLock;
				DataLockItem = DataLock.Add(
					Metadata.FindByType(TypeOf(Source.CurrentVersion)).FullName());
				
				DataLockItem.SetValue("Ref", Source.CurrentVersion);
				DataLock.Lock();
				
				Object = Source.CurrentVersion.GetObject();
				
				If Object <> Undefined Then
					SetSafeModeDisabled(True);
					SetPrivilegedMode(True);
					Object.Description = Source.Description;
					// 
					Object.AdditionalProperties.Insert("FileRenaming", True);
					Object.Write();
					SetPrivilegedMode(False);
					SetSafeModeDisabled(False);
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(Source.FileOwner) Then
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'The owner of file
			|""%1"" is blank.';"), Source.Description);
		
		If InfobaseUpdate.InfobaseUpdateInProgress() Then
			WriteLogEvent(NStr("en = 'Files.Error writing file during infobase update';", Common.DefaultLanguageCode()),
				EventLogLevel.Error,, Source.Ref, ErrorDescription);
		Else
			Raise ErrorDescription;
		EndIf;
		
	EndIf;
	
	If Source.IsFolder Then
		Source.PictureIndex = 2;
	Else
		Source.PictureIndex = FilesOperationsInternalClientServer.IndexOfFileIcon(Source.Extension);
	EndIf;
	
	If Source.IsNew() And Not ValueIsFilled(Source.Author) Then
		Source.Author = Users.AuthorizedUser();
	EndIf;
	
EndProcedure

// Handler for subscribing to the pre-Delete event to delete data associated with the attached file.
//
// Parameters:
//  Source   - CatalogObject -  directory object with the name "*Attached files".
//  Cancel      - Boolean -  parameter passed to the event subscription before Recording.
//
Procedure ExecuteActionsBeforeDeleteAttachedFile(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If TypeOf(Source) = Type("CatalogObject.FilesVersions") Then
		Return;
	EndIf;
	
	FilesOperationsInternal.BeforeDeleteAttachedFileServer(
		Source.Ref,
		Source.FileOwner,
		Source.Volume,
		Source.FileStorageType,
		Source.PathToFile);
	
EndProcedure

// Handler for subscribing to the Record event to update data associated with the attached file.
//
// Parameters:
//  Source   - CatalogObject -  directory object with the name "*Attached files".
//  Cancel      - Boolean -  parameter passed to the event subscription before Recording.
//
Procedure ExecuteActionsOnWriteAttachedFile(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		WriteFileDataToRegisterDuringExchange(Source);
		Return;
	EndIf;
	
	If TypeOf(Source) = Type("CatalogObject.FilesVersions") Then
		Return;
	EndIf;
	
	FilesOperationsInternal.OnWriteAttachedFileServer(Source.FileOwner, Source);
		
	FilesOperationsInternal.UpdateTextExtractionQueueState(
		Source.Ref, Source.TextExtractionStatus);
	
EndProcedure

Procedure WriteFileDataToRegisterDuringExchange(Val Source)
	
	Var FileBinaryData;
	
	If Source.AdditionalProperties.Property("FileBinaryData", FileBinaryData) Then
		SetPrivilegedMode(True);
		InformationRegisters.FileRepository.WriteBinaryData(Source.Ref, FileBinaryData);
		SetPrivilegedMode(False);
		
		Source.AdditionalProperties.Delete("FileBinaryData");
	EndIf;
	
EndProcedure

// Handler for subscribing to the event before Recording the owner of the attached file.
// Marks related files for deletion.
//
// Parameters:
//  Source - DefinedType.AttachedFilesOwnerObject -  owner of the attached file, except for the document Object.
//  Cancel    - Boolean -  indicates that the recording was rejected.
// 
Procedure SetAttachedFilesDeletionMarks(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If StandardSubsystemsServer.IsMetadataObjectID(Source) Then
		Return;
	EndIf;
	
	MarkToDeleteAttachedFiles(Source);

EndProcedure

// Handler for subscribing to the event before Recording the owner of the attached file.
// Marks related files for deletion.
//
// Parameters:
//  Source        - DocumentObject -  owner of the attached file.
//  Cancel           - Boolean -  parameter passed to the event subscription before Recording.
//  WriteMode     - Boolean -  parameter passed to the event subscription before Recording.
//  PostingMode - Boolean -  parameter passed to the event subscription before Recording.
// 
Procedure SetAttachedDocumentFilesDeletionMark(Source, Cancel, WriteMode, PostingMode) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	MarkToDeleteAttachedFiles(Source);
	
EndProcedure

Procedure CheckIfTheFileAuthorHasChanged(Val FormerValue, Val Source)
	
	ChangedTheAuthorOf = Source.Author <> FormerValue.Author;
	If ChangedTheAuthorOf Then
		Raise(NStr("en = 'Insufficient rights to change the file author.';"), ErrorCategory.AccessViolation);
	EndIf;
	
	If TypeOf(Source) = Type("CatalogObject.FilesVersions") Then
		Return;
	EndIf;
		
	CurrentUser = Users.AuthorizedUser();
	If Source.BeingEditedBy <> FormerValue.BeingEditedBy
		And (InvalidAuthor(Source.BeingEditedBy, CurrentUser) 
			Or InvalidAuthor(FormerValue.BeingEditedBy, CurrentUser)) Then
		Raise(NStr("en = 'Insufficient rights to edit the file.';"), ErrorCategory.AccessViolation);
	EndIf;
	
	If Source.ChangedBy <> FormerValue.ChangedBy
		And (InvalidAuthor(Source.ChangedBy, CurrentUser) 
			Or InvalidAuthor(FormerValue.ChangedBy, CurrentUser)) Then
		Raise(NStr("en = 'Insufficient rights to edit the file.';"), ErrorCategory.AccessViolation);
	EndIf;

EndProcedure

Function InvalidAuthor(AuthorLink, CurrentUser)
	
	// 
	Return AuthorLink <> Undefined And Not AuthorLink.IsEmpty() 
		And TypeOf(AuthorLink) <> Type("CatalogRef.FileSynchronizationAccounts")
		And AuthorLink <> CurrentUser; 
	
EndFunction	

////////////////////////////////////////////////////////////////////////////////
// 

Procedure CreateFilesHyperlink(Form, ItemToAdd, AttachedFilesOwner, HyperlinkParameters)
	
	GroupName          = HyperlinkParameters.GroupName;
	ItemNumber      = HyperlinkParameters.ItemNumber;
	AdditionAvailable = HyperlinkParameters.AdditionAvailable;

	CommandPrefix             = FilesOperationsClientServer.CommandsPrefix();
	ImportFileCommandName    = FilesOperationsClientServer.ImportFileCommandName();
	CreateFromTemplateCommandName = FilesOperationsClientServer.CreateFromTemplateCommandName();
	ScanCommandName      = FilesOperationsClientServer.ScanCommandName();
	OpenListCommandName    = FilesOperationsClientServer.OpenListCommandName();
	
	FormCommandProperties = New Structure;
	FormCommandProperties.Insert("Representation", ButtonRepresentation.Text);
	FormCommandProperties.Insert("Action", "Attachable_AttachedFilesPanelCommand");
	
	If ItemToAdd.Location = "CommandBar" Then
		PlacementItem = Form.CommandBar;
	Else
		PlacementItem = Form.Items.Find(ItemToAdd.Location);
	EndIf;
	
	Compositor = FormGroupType.CommandBar;
	IsButtonsGroup = False;
	If PlacementItem <> Undefined
		And TypeOf(PlacementItem) = Type("FormGroup") Then
		
		IsButtonsGroup = PlacementItem.Type = FormGroupType.ButtonGroup
			Or PlacementItem.Type = FormGroupType.CommandBar;
		Compositor = ?(IsButtonsGroup, FormGroupType.ButtonGroup, Compositor);
		If PlacementItem.Type = FormGroupType.UsualGroup
			Or PlacementItem.Type = FormGroupType.Page
			Or IsButtonsGroup Then
			
			ParentElement   = PlacementItem;
			PlacementItem = Undefined;
		EndIf;
		
	EndIf;
	
	PlacementOnFormGroup = Form.Items.Insert(GroupName, Type("FormGroup"), 
		ParentElement, PlacementItem); // FormGroup
	PlacementOnFormGroup.Title = HyperlinkParameters.GroupTitle;
	PlacementOnFormGroup.Type = Compositor;
	
	SubmenuAdd = Undefined;
	If ItemToAdd.AddFiles2
		And AdditionAvailable Then
		
		SubmenuAdd = Form.Items.Add("AddingFileSubmenu" + ItemNumber, Type("FormGroup"),
			PlacementOnFormGroup); // FormGroup
		
		SubmenuAdd.Type         = FormGroupType.Popup;
		SubmenuAdd.Picture    = PictureLib.Clip;
		SubmenuAdd.Title   = NStr("en = 'Attach files';");
		SubmenuAdd.ToolTip   = NStr("en = 'Attach files';");
		SubmenuAdd.Representation = ButtonRepresentation.Picture;
		
		ImportFile_           = Form.Commands.Add(CommandPrefix + ImportFileCommandName + "_" + ItemNumber);
		ImportFile_.Action  = "Attachable_AttachedFilesPanelCommand";
		CommandTitle = NStr("en = 'Upload local file';");
		ImportFile_.ToolTip = CommandTitle;
		ImportFile_.Title = CommandTitle + "...";
		
		LoadButton = AddButtonOnForm(Form, CommandPrefix + ImportFileCommandName + ItemNumber, PlacementOnFormGroup, ImportFile_.Name);
		LoadButton.Picture    = PictureLib.Clip;
		LoadButton.Visible   = False;
		LoadButton.Representation = ButtonRepresentation.Picture;
		
		If ValueIsFilled(ItemToAdd.ShapeRepresentation) Then
			LoadButton.ShapeRepresentation = ButtonShapeRepresentation[ItemToAdd.ShapeRepresentation];
			SubmenuAdd.ShapeRepresentation = ButtonShapeRepresentation[ItemToAdd.ShapeRepresentation];
		EndIf;
		
		LoadButtonFromSubmenu = AddButtonOnForm(Form, 
			ImportFileCommandName + NameOfAdditionalCommandFromSubmenu() + ItemNumber, SubmenuAdd, ImportFile_.Name);
		LoadButtonFromSubmenu.Representation = ButtonRepresentation.Text;
		
		CreateByTemplate = Form.Commands.Add(CommandPrefix + CreateFromTemplateCommandName + "_" + ItemNumber);
		CreateByTemplate.Title = NStr("en = 'Create from template…';");
		FillPropertyValues(CreateByTemplate, FormCommandProperties);
		
		AddButtonOnForm(Form, CreateFromTemplateCommandName + ItemNumber, SubmenuAdd, CreateByTemplate.Name);
		
		Scan = Form.Commands.Add(CommandPrefix + ScanCommandName + "_" + ItemNumber);
		Scan.Title = NStr("en = 'Scan…';");
		FillPropertyValues(Scan, FormCommandProperties);
		
		AddButtonOnForm(Form, ScanCommandName + ItemNumber, SubmenuAdd, Scan.Name);
		
	EndIf;
	
	OpenListCommand = Form.Commands.Add(CommandPrefix + OpenListCommandName + "_" + ItemNumber);
	FillPropertyValues(OpenListCommand, FormCommandProperties);
	
	If ItemToAdd.DisplayTitleRight
		Or Not ItemToAdd.AddFiles2 Then
		GoToHyperlink = AddButtonOnForm(Form, CommandPrefix + OpenListCommandName + ItemNumber,
			PlacementOnFormGroup, OpenListCommand.Name);
	Else
		GoToHyperlink = Form.Items.Insert(CommandPrefix + OpenListCommandName + ItemNumber,
			Type("FormButton"), PlacementOnFormGroup, SubmenuAdd);
			
		GoToHyperlink.CommandName = OpenListCommand.Name;
	EndIf;
	
	GoToHyperlink.Type = ?(IsButtonsGroup, FormButtonType.CommandBarHyperlink, FormButtonType.Hyperlink);
	GoToHyperlink.Title = ItemToAdd.Title;
	If ItemToAdd.DisplayCount Then
		
		AttachedFilesCount = FilesOperationsInternalServerCall.AttachedFilesCount(AttachedFilesOwner);
		If AttachedFilesCount > 0 Then
			GoToHyperlink.Title = GoToHyperlink.Title + " ("
				+ Format(AttachedFilesCount, "NG=") + ")";
		EndIf;
		
	EndIf;
			
EndProcedure

Procedure CreateFileField(Form, ItemToAdd, AttachedFilesOwner, FileFieldParameters)
	
	GroupName          = FileFieldParameters.GroupName;
	ItemNumber      = FileFieldParameters.ItemNumber;
	AvailableUpdate  = FileFieldParameters.AvailableUpdate;
	AdditionAvailable = FileFieldParameters.AdditionAvailable;
	
	FormCommandProperties = New Structure;
	FormCommandProperties.Insert("Action",    "Attachable_AttachedFilesPanelCommand");
	FormCommandProperties.Insert("Representation", ButtonRepresentation.Text);
	
	FormCommandPropertiesPicture = New Structure;
	FormCommandPropertiesPicture.Insert("Action",    "Attachable_AttachedFilesPanelCommand");
	FormCommandPropertiesPicture.Insert("Representation", ButtonRepresentation.Picture);
	
	LoadButtonProperties = New Structure;
	LoadButtonProperties.Insert("Title",            NStr("en = 'Upload…';"));
	LoadButtonProperties.Insert("Representation",          ButtonRepresentation.Text);
	LoadButtonProperties.Insert("ToolTipRepresentation", ToolTipRepresentation.None);
	
	SelectionButtonProperties = New Structure;
	SelectionButtonProperties.Insert("Title",            NStr("en = 'Select from attachments…';"));
	SelectionButtonProperties.Insert("Representation",          ButtonRepresentation.Text);
	SelectionButtonProperties.Insert("ToolTipRepresentation", ToolTipRepresentation.None);
	
	GroupPropertiesWithoutDisplay = New Structure;
	GroupPropertiesWithoutDisplay.Insert("Type",                 FormGroupType.UsualGroup);
	GroupPropertiesWithoutDisplay.Insert("ToolTip",           "");
	GroupPropertiesWithoutDisplay.Insert("Group",         ChildFormItemsGroup.Vertical);
	GroupPropertiesWithoutDisplay.Insert("ShowTitle", False);
	
	If StrFind(ItemToAdd.DataPath, ".") Then
		FullDataPath = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			ItemToAdd.DataPath, ".", True, True);
	Else
		FullDataPath = New Array;
		FullDataPath.Add(ItemToAdd.DataPath);
	EndIf;
	
	PlacementAttribute = Form[FullDataPath[0]];
	For Counter = 1 To FullDataPath.UBound() Do
		PlacementAttribute = PlacementAttribute[FullDataPath[Counter]]; // DefinedType.AttachedFile
	EndDo;
	
	ItemToAdd.AddFiles2 = ItemToAdd.AddFiles2 And AdditionAvailable;
	PlacementItem = Form.Items.Find(ItemToAdd.Location);
	
	If PlacementItem <> Undefined
		And TypeOf(PlacementItem) = Type("FormGroup")
		And (PlacementItem.Type = FormGroupType.UsualGroup
		Or PlacementItem.Type = FormGroupType.Page) Then
		
		ParentElement   = PlacementItem;
		PlacementItem = Undefined;
		
	EndIf;
	
	PlacementOnFormGroup = Form.Items.Insert(GroupName, Type("FormGroup"), 
		ParentElement, PlacementItem); // FormGroup
	PlacementOnFormGroup.Title = FileFieldParameters.GroupTitle;
	
	OneFileOnlyText = ?(ItemToAdd.OneFileOnly, FilesOperationsClientServer.OneFileOnlyText(), "");
	FillPropertyValues(PlacementOnFormGroup, GroupPropertiesWithoutDisplay);
	
	HeaderGroup = Form.Items.Add("AttachedFilesManagementGroupHeader" + ItemNumber,
		Type("FormGroup"), PlacementOnFormGroup); // FormGroup
	HeaderGroup.Title = NStr("en = 'Attachment management';") + " " + ItemNumber;
	
	FillPropertyValues(HeaderGroup, GroupPropertiesWithoutDisplay);
	HeaderGroup.Group = ChildFormItemsGroup.AlwaysHorizontal;
	
	If ItemToAdd.ShowPreview Then
		
		PreviewItem = Form.Items.Add("AttachedFilePictureField" + ItemNumber,
			Type("FormField"), PlacementOnFormGroup); // FormFieldExtensionForATextBox
		
		PreviewItem.Title                  = NStr("en = 'Attachment picture';") + " " + ItemNumber;
		PreviewItem.Type                        = FormFieldType.PictureField;
		PreviewItem.TextColor                 = StyleColors.NotSelectedPictureTextColor;
		PreviewItem.DataPath                = ItemToAdd.PathToPictureData;
		PreviewItem.Hyperlink                = True;
		PreviewItem.PictureSize             = PictureSize.Proportionally;
		PreviewItem.TitleLocation         = FormItemTitleLocation.None;
		PreviewItem.AutoMaxWidth     = False;
		PreviewItem.AutoMaxHeight     = False;
		PreviewItem.VerticalStretch     = True;
		PreviewItem.EnableDrag    = True;
		PreviewItem.HorizontalStretch   = True;
		PreviewItem.NonselectedPictureText   = ItemToAdd.NonselectedPictureText;
		PreviewItem.FileDragMode = FileDragMode.AsFileRef;
		
		PreviewContextMenu = PreviewItem.ContextMenu;
		PreviewContextMenu.EnableContentChange = False;
		
		ContextMenuAddGroup = Form.Items.Add("FileAddingGroupContextMenu" + ItemNumber,
			Type("FormGroup"), PreviewContextMenu); // FormGroup
		ContextMenuAddGroup.Title = NStr("en = 'Context menu ""Add file""';") + " " + ItemNumber;
		ContextMenuAddGroup.Type = FormGroupType.ButtonGroup;
		
		If ValueIsFilled(PlacementAttribute)
			And Common.IsReference(TypeOf(PlacementAttribute)) Then
			
			RefToBinaryData = Undefined;
			
			DataParameters = FilesOperationsClientServer.FileDataParameters();
			DataParameters.RaiseException1 = False;
			DataParameters.FormIdentifier = Form.UUID;
			
			FileData = FileData(PlacementAttribute, DataParameters);
			If FileData <> Undefined Then
				
				RefToBinaryData = FileData.RefToBinaryFileData;
				BinaryDataValue = GetFromTempStorage(RefToBinaryData);
				If BinaryDataValue = Undefined Then
					PreviewItem.TextColor = StyleColors.ErrorNoteText;
					PreviewItem.NonselectedPictureText = NStr("en = 'No image';");
				EndIf;
				
			EndIf;
			
			Form[ItemToAdd.PathToPictureData] = RefToBinaryData;
			
		EndIf;
		
		PreviewItem.SetAction("Click", "Attachable_PreviewFieldClick");
		PreviewItem.SetAction("Drag", "Attachable_PreviewFieldDrag");
		PreviewItem.SetAction("DragCheck",
			"Attachable_PreviewFieldCheckDragging");
		
	EndIf;
	
	If Not IsBlankString(ItemToAdd.Title) Then
		
		TitleDecoration = Form.Items.Add("AttachedFilesManagementTitle" + ItemNumber,
			Type("FormDecoration"), HeaderGroup);
		TitleDecoration.Type                      = FormDecorationType.Label;
		TitleDecoration.Title                = ItemToAdd.Title + ":";
		TitleDecoration.VerticalStretch   = False;
		TitleDecoration.HorizontalStretch = False;
		
	EndIf;
	
	If ItemToAdd.OutputFileTitle Then
		
		FileTitle = Form.Commands.Add("AttachedFileTitle_" + OneFileOnlyText + ItemNumber);
		FillPropertyValues(FileTitle, FormCommandProperties);
		
		TitleHyperlink = Form.Items.Add("AttachedFileTitle" + ItemNumber,
			Type("FormButton"), HeaderGroup);
		
		TitleHyperlink.Type = FormButtonType.Hyperlink;
		TitleHyperlink.CommandName = FileTitle.Name;
		TitleHyperlink.AutoMaxWidth = False;
		If Not ValueIsFilled(PlacementAttribute) Then
			FileTitle.ToolTip       = "";
			TitleHyperlink.Title = NStr("en = 'upload';");
		ElsIf Common.IsReference(TypeOf(PlacementAttribute)) Then
			FileTitle.ToolTip       = NStr("en = 'Open file';");
			AttachedFileAttributes  = Common.ObjectAttributesValues(PlacementAttribute, "Description, Extension");
			TitleHyperlink.Title = AttachedFileAttributes.Description
				+ ?(StrStartsWith(AttachedFileAttributes.Extension, "."), "", ".")
				+ AttachedFileAttributes.Extension;
		EndIf;
		
	EndIf;
	
	PictureAdd1 = ?(ItemToAdd.ShowPreview, PictureLib.Camera,
		PictureLib.Clip);
	
	If ItemToAdd.ShowCommandBar Then
		
		GroupCommandBar = Form.Items.Find("GroupCommandBar" + ItemToAdd.Location);
		SuppliedItemsGroup = Undefined;
		If GroupCommandBar = Undefined Then
			GroupCommandBar = Form.Items.Add("AttachedFilesManagementCommandBar" + ItemNumber,
				Type("FormGroup"), HeaderGroup);
		
			GroupCommandBar.Type = FormGroupType.CommandBar;
			GroupCommandBar.HorizontalStretch = True;
		Else
			Form.Items.Move(GroupCommandBar, HeaderGroup);
			SuppliedItemsGroup = Form.Items.Add("AttachmentsManagement1CSuppliedCommandsGroup" + ItemNumber,
				Type("FormGroup"), GroupCommandBar); // FormGroup
			SuppliedItemsGroup.Title = NStr("en = 'Attachment management command';") 
				+ " " + ItemNumber;
			SuppliedItemsGroup.Type = FormGroupType.ButtonGroup;
			For Each SuppliedItem In GroupCommandBar.ChildItems Do
				Form.Items.Move(SuppliedItem, SuppliedItemsGroup);
			EndDo;
		EndIf;
		
		SubmenuAdd = Form.Items.Add("AddingFileSubmenu" + ItemNumber,
			Type("FormGroup"), GroupCommandBar);
		
		SubmenuAdd.Type         = FormGroupType.Popup;
		SubmenuAdd.Picture    = PictureAdd1;
		SubmenuAdd.Title   = NStr("en = 'Overwrite';");
		SubmenuAdd.Representation = ButtonRepresentation.Picture;
		
		SubmenuGroup = Form.Items.Add("FileAddingGroup" + ItemNumber,
			Type("FormGroup"), SubmenuAdd); // FormGroup
		ContextMenuAddGroup.Title = NStr("en = 'Add files';") + " " + ItemNumber;
		SubmenuGroup.Type = FormGroupType.ButtonGroup;
		
	EndIf;
	
	CommandPrefix = FilesOperationsClientServer.CommandsPrefix();
	
	If ItemToAdd.AddFiles2 Then
		
		CommandNameWithPrefix = CommandPrefix + FilesOperationsClientServer.ImportFileCommandName();
		
		ImportFile_ = Form.Commands.Add(CommandNameWithPrefix + "_" + OneFileOnlyText + ItemNumber);
		ImportFile_.Action  = "Attachable_AttachedFilesPanelCommand";
		ImportFile_.ToolTip = NStr("en = 'Upload local file';");
		
		If ItemToAdd.ShowCommandBar Then
			
			LoadButton = AddButtonOnForm(Form, CommandNameWithPrefix + ItemNumber,
				GroupCommandBar, ImportFile_.Name);
			
			LoadButton.Picture    = PictureAdd1;
			LoadButton.Visible   = False;
			LoadButton.Representation = ButtonRepresentation.Picture;
			
			LoadButtonFromSubmenu = AddButtonOnForm(Form, 
				CommandNameWithPrefix + NameOfAdditionalCommandFromSubmenu() + ItemNumber,
				SubmenuGroup, ImportFile_.Name);
			
			FillPropertyValues(LoadButtonFromSubmenu, LoadButtonProperties);
			
		EndIf;
		
		If ItemToAdd.ShowPreview Then
			
			LoadButtonFromContextMenu = AddButtonOnForm(Form, 
				CommandNameWithPrefix + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,
				ContextMenuAddGroup, ImportFile_.Name);
			
			FillPropertyValues(LoadButtonFromContextMenu, LoadButtonProperties);
			
		EndIf;
		
		If Not ItemToAdd.OneFileOnly Then
			
			CommandNameWithPrefix = CommandPrefix + FilesOperationsClientServer.CreateFromTemplateCommandName();
			
			CreateByTemplate = Form.Commands.Add(CommandNameWithPrefix + "_" + ItemNumber);
			CreateByTemplate.Title = NStr("en = 'Create from template…';");
			FillPropertyValues(CreateByTemplate, FormCommandProperties);
		
			If ItemToAdd.ShowCommandBar Then
				AddButtonOnForm(Form, CommandNameWithPrefix + ItemNumber,
					SubmenuGroup, CreateByTemplate.Name);
			EndIf;
			
			If ItemToAdd.ShowPreview Then
				AddButtonOnForm(Form, 
					CommandNameWithPrefix + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,
					ContextMenuAddGroup, CreateByTemplate.Name);
			EndIf;
		
			CommandNameWithPrefix = CommandPrefix + FilesOperationsClientServer.ScanCommandName();
			
			Scan = Form.Commands.Add(CommandNameWithPrefix + "_" + ItemNumber);
			Scan.Title = ?(Common.IsMobileClient(), NStr("en = 'Take a photograph…';"), NStr("en = 'Scan…';"));
			FillPropertyValues(Scan, FormCommandProperties);
		
			If ItemToAdd.ShowCommandBar Then
				AddButtonOnForm(Form, CommandNameWithPrefix + ItemNumber,
					SubmenuGroup, Scan.Name);
			EndIf;
			
			If ItemToAdd.ShowPreview Then
				AddButtonOnForm(Form, CommandNameWithPrefix + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,
					ContextMenuAddGroup, Scan.Name);
			EndIf;
					
		EndIf;
				
	EndIf;
	
	If ItemToAdd.NeedSelectFile
		And AvailableUpdate Then
		
		CommandNameWithPrefix = CommandPrefix + FilesOperationsClientServer.SelectFileCommandName();
		
		SelectFile           = Form.Commands.Add(CommandNameWithPrefix + "_" + ItemNumber);
		SelectFile.Action  = "Attachable_AttachedFilesPanelCommand";
		SelectFile.ToolTip = NStr("en = 'Select a file from attached ones.';");
		
		If ItemToAdd.ShowCommandBar Then
			
			ChooseFileButton = AddButtonOnForm(Form, CommandNameWithPrefix + ItemNumber,
				SubmenuAdd, SelectFile.Name);
			
			FillPropertyValues(ChooseFileButton, SelectionButtonProperties);
			
		EndIf;
		
		If ItemToAdd.ShowPreview Then
			
			ChooseFromContextMenuButton = AddButtonOnForm(Form, 
				FilesOperationsClientServer.SelectFileCommandName() + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,
				PreviewContextMenu, SelectFile.Name);
			FillPropertyValues(ChooseFromContextMenuButton, SelectionButtonProperties);
			
		EndIf;
		
	EndIf;
	
	If ItemToAdd.ViewFile Then
		
		ViewFile1 = Form.Commands.Add(CommandPrefix + FilesOperationsClientServer.ViewFileCommandName() + "_" + ItemNumber);
		ViewFile1.Title = NStr("en = 'View';");
		FillPropertyValues(ViewFile1, FormCommandProperties);
		
		If ItemToAdd.OneFileOnly Then
			ViewFile1.Picture = PictureLib.OpenSelectedFile;
			ViewFile1.Representation = ButtonRepresentation.Picture;
		EndIf;
		
		If ItemToAdd.ShowCommandBar Then
			AddButtonOnForm(Form, FilesOperationsClientServer.ViewFileCommandName() + ItemNumber, GroupCommandBar, ViewFile1.Name);
		EndIf;
		
	EndIf;
	
	If ItemToAdd.ClearFile
		And AvailableUpdate Then
		
		Zap           = Form.Commands.Add(CommandPrefix + FilesOperationsClientServer.ClearCommandName() + "_" + ItemNumber);
		Zap.Picture  = PictureLib.InputFieldClear;
		Zap.Title = NStr("en = 'Clear';");
		Zap.ToolTip = Zap.Title;
		FillPropertyValues(Zap, FormCommandPropertiesPicture);
		
		If ItemToAdd.ShowCommandBar Then
			AddButtonOnForm(Form, "Zap" + ItemNumber, GroupCommandBar, Zap.Name);
		EndIf;
		
		If ItemToAdd.ShowPreview Then
			AddButtonOnForm(Form, 
				FilesOperationsClientServer.ClearCommandName() + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,
				PreviewContextMenu, Zap.Name);
		EndIf;
		
	EndIf;
	
	EditFile = Undefined;
	If ItemToAdd.EditFile = "InForm" Then
		
		EditFile           = Form.Commands.Add(CommandPrefix + FilesOperationsClientServer.OpenFormCommandName() + "_" + ItemNumber);
		EditFile.Picture  = PictureLib.InputFieldOpen;
		EditFile.Title = NStr("en = 'Open card';");
		EditFile.ToolTip = NStr("en = 'Open the attachment card.';");
		FillPropertyValues(EditFile, FormCommandPropertiesPicture);
		
		If ItemToAdd.ShowCommandBar Then
			AddButtonOnForm(Form, FilesOperationsClientServer.EditFileCommandName() + ItemNumber, GroupCommandBar, EditFile.Name);
		EndIf;
		
		If ItemToAdd.ShowPreview Then
			AddButtonOnForm(Form, 
				FilesOperationsClientServer.EditFileCommandName() + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,
				PreviewContextMenu, EditFile.Name);
		EndIf;
		
	ElsIf ItemToAdd.EditFile = "Directly"
		And AvailableUpdate Then
		
		EditFile           = Form.Commands.Add(CommandPrefix + FilesOperationsClientServer.EditFileCommandName() + "_" + ItemNumber);
		EditFile.Picture  = PictureLib.Change;
		EditFile.Title = NStr("en = 'Edit';");
		EditFile.ToolTip = NStr("en = 'Open the file for editing.';");
		FillPropertyValues(EditFile, FormCommandPropertiesPicture);
		
		PutFile           = Form.Commands.Add(CommandPrefix + FilesOperationsClientServer.PutFileCommandName() + "_" + ItemNumber);
		PutFile.Picture  = PictureLib.EndFileEditing;
		PutFile.Title = NStr("en = 'Commit';");
		PutFile.ToolTip = NStr("en = 'Save the file and release it in the infobase.';");
		FillPropertyValues(PutFile, FormCommandPropertiesPicture);
		
		CancelEdit = Form.Commands.Add(
			CommandPrefix + FilesOperationsClientServer.CancelEditCommandName() + "_" + ItemNumber);
		
		CancelEdit.Picture  = PictureLib.UnlockFile;
		CancelEdit.Title = NStr("en = 'Cancel editing';");
		CancelEdit.ToolTip = NStr("en = 'Release a locked file.';");
		FillPropertyValues(CancelEdit, FormCommandPropertiesPicture);
		
		FileDataParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataParameters.RaiseException1 = False;
		FileDataParameters.GetBinaryDataRef = False;
		
		PlacementFileData = FileData(PlacementAttribute, FileDataParameters);
		
		If ItemToAdd.ShowCommandBar Then
			
			DirectEditingGroup = Form.Items.Add(
				"DirectEditingGroup" + ItemNumber,
				Type("FormGroup"), GroupCommandBar);
			
			DirectEditingGroup.Type = FormGroupType.ButtonGroup;
			DirectEditingGroup.Representation = ButtonGroupRepresentation.Compact;
		
			EditButton1 = AddButtonOnForm(Form,
				CommandPrefix + FilesOperationsClientServer.EditFileCommandName() + ItemNumber,
				DirectEditingGroup, EditFile.Name);
		
			PlaceButton = AddButtonOnForm(Form, CommandPrefix + FilesOperationsClientServer.PutFileCommandName() + ItemNumber,
				DirectEditingGroup, PutFile.Name);
		
			CancelButton1 = AddButtonOnForm(Form, CommandPrefix + FilesOperationsClientServer.CancelEditCommandName() + ItemNumber,
				DirectEditingGroup, CancelEdit.Name);
			
			SetEditingAvailability(PlacementFileData, EditButton1, CancelButton1, PlaceButton);
			
		EndIf;
		
		If ItemToAdd.ShowPreview Then
			
			EditingGroupInMenu = Form.Items.Add(
				"EditingGroupInMenu" + ItemNumber,
				Type("FormGroup"), PreviewContextMenu);
			
			EditingGroupInMenu.Type = FormGroupType.ButtonGroup;
			
			EditButton1 = AddButtonOnForm(Form, 
				FilesOperationsClientServer.EditFileCommandName() + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,
				EditingGroupInMenu, EditFile.Name);
		
			CancelButton1 = AddButtonOnForm(Form, 
				FilesOperationsClientServer.PutFileCommandName() + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,
				EditingGroupInMenu, PutFile.Name);
		
			PlaceButton = AddButtonOnForm(Form, 
				FilesOperationsClientServer.CancelEditCommandName() + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,
				EditingGroupInMenu, CancelEdit.Name);
			
			SetEditingAvailability(PlacementFileData, EditButton1, CancelButton1, PlaceButton);
			
		EndIf;
		
	EndIf;
	
	If ItemToAdd.ShowCommandBar And SuppliedItemsGroup <> Undefined Then
		 Form.Items.Move(SuppliedItemsGroup, GroupCommandBar);
	EndIf;
	
EndProcedure

Procedure SetEditingAvailability(FileData, EditButton1, CancelButton1, PlaceButton)
	
	If FileData <> Undefined Then
		EditButton1.Enabled = Not FileData.FileBeingEdited;
		CancelButton1.Enabled = FileData.FileBeingEdited And FileData.CurrentUserEditsFile;
		PlaceButton.Enabled = FileData.FileBeingEdited And FileData.CurrentUserEditsFile;
	Else
		CancelButton1.Enabled = False;
		PlaceButton.Enabled = False;
		EditButton1.Enabled = False;
	EndIf;

EndProcedure

Function AddButtonOnForm(Form, ButtonName, Parent, CommandName)
	
	FormButton = Form.Items.Add(ButtonName, Type("FormButton"), Parent);
	FormButton.CommandName = CommandName;
	Return FormButton;
	
EndFunction

Function FormAttributeByName(FormAttributes, AttributeName)
	
	For Each Attribute In FormAttributes Do
		If Attribute.Name = AttributeName Then
			Return Attribute;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

Function NameOfAdditionalCommandFromSubmenu()
	Return "FromSubmenu";
EndFunction

#EndRegion