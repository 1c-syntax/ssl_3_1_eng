﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns the path to the user's working directory.
Function UserWorkingDirectory() Export
	
	Return FilesOperationsInternalClientCached.UserWorkingDirectory();
	
EndFunction

// Opens the folder form with a list of files.
//
// Parameters:
//   StandardProcessing - Boolean -  passed "as is "from the parameters of the"Open" handler.
//   Folder - CatalogRef.Files - 
//
Procedure ReportsMailingViewFolder(StandardProcessing, Folder) Export
	
	StandardProcessing = False;
	FormParameters = New Structure("Folder", Folder);
	OpenForm("Catalog.Files.Form.Files", FormParameters, , Folder);
	
EndProcedure

Procedure MoveFiles() Export
	
	OpenForm("DataProcessor.FileTransfer.Form");
	
EndProcedure

// 
//
// Parameters:
//  ExecutionParameters - Structure:
//       * ResultHandler - NotifyDescription
//                              - Undefined -  
//       * FullFileName - String -  optional. The full path and file name on the client.
//             If not specified, a dialog will open to select a file.
//       * FileOwner - AnyRef -  file owner.
//       * OwnerForm - ClientApplicationForm -  the form from which the file creation is called.
//       * NotOpenCardAfterCreateFromFile - Boolean
//             - 
//       * NameOfFileToCreate - String -  optional. New file name.
//
Procedure AddFormFileSystemWithExtension(ExecutionParameters) Export
	
	Result = AddFromFileSystemWithExtensionSynchronous(ExecutionParameters);
	If Not Result.FileAdded Then
		If ValueIsFilled(Result.ErrorText) Then
			ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, Result.ErrorText, Undefined);
		Else
			ReturnResult(ExecutionParameters.ResultHandler, Undefined);
		EndIf;
		Return;
	EndIf;
	
	If ExecutionParameters.NotOpenCardAfterCreateFromFile <> True Then
		FormParameters = New Structure("OpenCardAfterCreateFile", True);
		OnCloseNotifyDescription = CompletionHandler(ExecutionParameters.ResultHandler);
		FilesOperationsClient.OpenFileForm(Result.FileRef,, FormParameters, OnCloseNotifyDescription); 
	Else
		ReturnResult(ExecutionParameters.ResultHandler, Result);
	EndIf;
	
EndProcedure

// 
//
// Parameters: 
//  ExecutionParameters - Structure:
//       * FullFileName - String -  optional. The full path and file name on the client.
//                                   If not specified, a synchronous dialog will be opened to select a file.
//       * FileOwner - AnyRef -  file owner.
//       * UUID - UUID -  id of the form to store the file.
//       * NameOfFileToCreate - String -  optional. New file name.
//
// Returns:
//   Structure:
//       * FileAdded - Boolean -  whether the operation was completed successfully.
//       * FileRef - CatalogRef.Files
//       * ErrorText - String
//
Function AddFromFileSystemWithExtensionSynchronous(ExecutionParameters) Export
	
	Result = New Structure;
	Result.Insert("FileAdded", False);
	Result.Insert("FileRef",   Undefined);
	Result.Insert("ErrorText",  "");
	
	DIalogBoxFilter = ?(ExecutionParameters.Property("SelectionDialogFilter"),
		ExecutionParameters.SelectionDialogFilter, StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'All files (%1)|%1';"), GetAllFilesMask()));
		
	If Not ExecutionParameters.Property("FullFileName") Then
		// 
		FileDialog = New FileDialog(FileDialogMode.Open);
		FileDialog.Multiselect = False;
		FileDialog.Title = NStr("en = 'Select file';");
		FileDialog.Filter = DIalogBoxFilter;
		FileDialog.Directory = FilesOperationsInternalServerCall.FolderWorkingDirectory(ExecutionParameters.FileOwner);
		If Not FileDialog.Choose() Then
			Return Result;
		EndIf;
		ExecutionParameters.Insert("FullFileName", FileDialog.FullFileName);
	EndIf;
	
	If Not ExecutionParameters.Property("NameOfFileToCreate") Then
		ExecutionParameters.Insert("NameOfFileToCreate", Undefined);
	EndIf;
	
	FileToAdd = New File(ExecutionParameters.FullFileName);
	If Not FileToAdd.Exists() Then
		ErrorText = NStr("en = 'The file does not exist:
			|%1';");
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, 
			ExecutionParameters.FullFileName);
		Return Result;
	EndIf;

	If ExecutionParameters.Property("MaximumSize")
		And ExecutionParameters.MaximumSize > 0
		And FileToAdd.Size() > ExecutionParameters.MaximumSize*1024*1024 Then
		
		ErrorText = NStr("en = 'The file size exceeds %1 MB.';");
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, 
			ExecutionParameters.MaximumSize);
		
		Return Result;
		
	EndIf;
	
	CheckCanImportFile(FileToAdd);
	
	CommonSettings = CommonFilesOperationsSettings();
	ExtractFilesTextsAtClient = Not CommonSettings.ExtractTextFilesOnServer;
	If ExtractFilesTextsAtClient Then
		TempTextStorageAddress = ExtractTextToTempStorage(FileToAdd.FullName,
			ExecutionParameters.OwnerForm.UUID);
	Else
		TempTextStorageAddress = "";
	EndIf;
		
	// 
	TempFileStorageAddress = "";
	
	Files = New Array;
	LongDesc = New TransferableFileDescription(FileToAdd.FullName, "");
	Files.Add(LongDesc);
	
	PlacedFiles = New Array;
	FilesPut = PutFiles(Files, PlacedFiles, , False, ExecutionParameters.OwnerForm.UUID);
	If Not FilesPut Then
		Return Result;
	EndIf;
	
	If PlacedFiles.Count() = 1 Then
		TempFileStorageAddress = PlacedFiles[0].Location;
	EndIf;
	
	FileNameAndExtension = FileNameAndExtension(FileToAdd);
	FileExtention = FileNameAndExtension.FileExtention;
	FileNameWithoutExtension = FileNameAndExtension.FileNameWithoutExtension;
	
	FileEncrypted = Lower(FileExtention) = Lower(EncryptedFilesExtension());
	
	If FileEncrypted Then
		ForUnencryptedFile = New File(FileNameWithoutExtension);
		FileNameAndExtension = FileNameAndExtension(ForUnencryptedFile);
		FileExtention = FileNameAndExtension.FileExtention;
		FileNameWithoutExtension = FileNameAndExtension.FileNameWithoutExtension;
	EndIf;

	If ExecutionParameters.NameOfFileToCreate <> Undefined Then
		CreationName = ExecutionParameters.NameOfFileToCreate;
	Else
		CreationName = FileNameWithoutExtension;
	EndIf;
	
	// 
	Try
		
		If FilesOperationsInternalClientCached.IsDirectoryFiles(ExecutionParameters.FileOwner) Then
			
			FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion", FileToAdd);
			FileInfo1.TempFileStorageAddress = TempFileStorageAddress;
			FileInfo1.TempTextStorageAddress = TempTextStorageAddress;
			FileInfo1.WriteToHistory = True;
			FileInfo1.BaseName = CreationName;
			FileInfo1.ExtensionWithoutPoint = FileExtention;
			FileInfo1.Encrypted = FileEncrypted;
			Result.FileRef = FilesOperationsInternalServerCall.CreateFileWithVersion(ExecutionParameters.FileOwner, FileInfo1);
			
		Else
			
			FileParameters = FilesOperationsInternalClientServer.FileAddingOptions();
			FileParameters.FilesOwner = ExecutionParameters.FileOwner;
			FileParameters.BaseName = FileNameWithoutExtension;
			FileParameters.ExtensionWithoutPoint = FileExtention;
			
			Result.FileRef = FilesOperationsInternalServerCall.AppendFile(FileParameters,
				TempFileStorageAddress,
				TempTextStorageAddress);
				
		EndIf;
		
		Result.FileAdded = True;
		
	Except
		Result.ErrorText = ErrorCreatingNewFile(ErrorInfo());
	EndTry;
	
	If Result.ErrorText <> "" Then
		Return Result;
	EndIf;
	
	NotificationParameters = FileWriteNotificationParameters();
	NotificationParameters.Owner = ExecutionParameters.FileOwner;
	NotificationParameters.FileOwner = NotificationParameters.Owner;
	NotificationParameters.File = Result.FileRef;
	NotificationParameters.IsNew = True;
	Notify("Write_File", NotificationParameters, Result.FileRef);
	
	ShowUserNotification(
		NStr("en = 'Created:';"),
		GetURL(Result.FileRef),
		Result.FileRef,
		PictureLib.DialogInformation);
	
	Return Result;
	
EndFunction

// Continuation of the attached file Client procedure.Add files.
Procedure AddFilesAddInSuggested(FileSystemExtensionAttached1, AdditionalParameters) Export
	
	FileOwner = AdditionalParameters.FileOwner;
	FormIdentifier = AdditionalParameters.FormIdentifier;
	
	If Not AdditionalParameters.Property("Filter") Then
		AdditionalParameters.Insert("Filter","");
	EndIf;
	
	If FileSystemExtensionAttached1 Then
		
		Filter = AdditionalParameters.Filter;
		OpenCardAfterCreateFromFile = False;
		If AdditionalParameters.Property("NotOpenCardAfterCreateFromFile") Then
			OpenCardAfterCreateFromFile = Not AdditionalParameters.NotOpenCardAfterCreateFromFile;
		EndIf;
		
		SelectedFiles = New Array;
		
		If Not AdditionalParameters.Property("FullFileName") Then
			SelectingFile = New FileDialog(FileDialogMode.Open);
			SelectingFile.Multiselect = True;
			SelectingFile.Title = NStr("en = 'Select file';");
			SelectingFile.Filter = ?(ValueIsFilled(Filter), Filter, NStr("en = 'All files';") + " (*.*)|*.*");
			If SelectingFile.Choose() Then
				SelectedFiles = SelectingFile.SelectedFiles;
			EndIf;
		Else
			SelectedFiles.Add(AdditionalParameters.FullFileName);
		EndIf;
		
		NameOfFileToCreate = "";
		If AdditionalParameters.Property("NameOfFileToCreate") Then
			NameOfFileToCreate = AdditionalParameters.NameOfFileToCreate;
		EndIf;
		
		If SelectedFiles.Count() > 0  Then
			AttachedFilesArray = New Array;
			PutSelectedFilesInStorage(
				SelectedFiles,
				FileOwner,
				AttachedFilesArray,
				FormIdentifier,
				NameOfFileToCreate,
				AdditionalParameters.FilesGroup);
			
			If AttachedFilesArray.Count() = 1 And OpenCardAfterCreateFromFile Then
				AttachedFile = AttachedFilesArray[0];
				
				ShowUserNotification(
					NStr("en = 'Created:';"),
					GetURL(AttachedFile),
					AttachedFile,
					PictureLib.DialogInformation);
				
				FormParameters = New Structure("IsNew", True);
				FilesOperationsClient.OpenFileForm(AttachedFile,, FormParameters)
			EndIf;
			
			If AttachedFilesArray.Count() > 0 Then
				NotifyChanged(AttachedFilesArray[0]);
				NotifyChanged(FileOwner);
				NotificationParameters = FileWriteNotificationParameters();
				NotificationParameters.Owner = FileOwner;
				NotificationParameters.FileOwner = NotificationParameters.Owner;
				NotificationParameters.File = AttachedFilesArray[0];
				NotificationParameters.IsNew = True;
				Notify("Write_File", NotificationParameters, AttachedFilesArray);
			EndIf;
			
			If AdditionalParameters.Property("ResultHandler")
				And AdditionalParameters.ResultHandler <> Undefined Then
				ExecuteNotifyProcessing(AdditionalParameters.ResultHandler, AttachedFilesArray);
			EndIf;
			
		EndIf;
		
	Else // 
		NotifyDescription = New NotifyDescription("AddFilesCompletion", ThisObject, AdditionalParameters);
		PutSelectedFilesInStorageWeb(NotifyDescription, FileOwner, FormIdentifier);
	EndIf;
	
EndProcedure

// Displays a standard warning.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  CommandPresentation - String -  the name of the command that requires the extension to execute.
//
Procedure ShowFileSystemExtensionRequiredMessageBox(ResultHandler, CommandPresentation = "") Export
	If Not ClientSupportsSynchronousCalls() Then
		WarningText = NStr("en = 'The ""%1"" command is not available in Google Chrome and Mozilla Firefox.';");
	Else
		WarningText = NStr("en = 'To run the ""%1"" command,
			|install 1C:Enterprise Extension.';");
	EndIf;
	If ValueIsFilled(CommandPresentation) Then
		WarningText = StrReplace(WarningText, "%1", CommandPresentation);
	Else
		WarningText = StrReplace(WarningText, " ""%1""", "");
	EndIf;
	ReturnResultAfterShowWarning(ResultHandler, WarningText, Undefined);
EndProcedure

// Saves the path to the user's working directory in the settings.
//
// Parameters:
//  DirectoryName - String -  directory name.
//
Procedure SetUserWorkingDirectory(DirectoryName) Export
	
	FilesOperationsInternalServerCall.SetUserWorkingDirectory(DirectoryName);
	
EndProcedure

// Returns the "My Documents" folder + the name of the current user or
// the previously used folder for uploading.
//
Function DumpDirectory() Export
	
	Path = "";
	
#If Not WebClient And Not MobileClient Then
	
	Path = CommonServerCall.CommonSettingsStorageLoad("ExportFolderName", "ExportFolderName");
	
	If Path = Undefined Then
		If Not StandardSubsystemsClient.IsBaseConfigurationVersion() Then
			Path = MyDocumentsDirectory();
			CommonServerCall.CommonSettingsStorageSave(
				"ExportFolderName", "ExportFolderName", Path);
		EndIf;
	EndIf;
	
#EndIf
	
	Return Path;
	
EndFunction

// Shows the user a file selection dialog and returns
// an array of selected files to import.
//
Function FilesToImport() Export
	
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.FullFileName     = "";
	OpenFileDialog.Filter             = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'All files (%1)|%1';"), GetAllFilesMask());
	OpenFileDialog.Multiselect = True;
	OpenFileDialog.Title          = NStr("en = 'Select files';");
	
	FileNamesArray = New Array;
	
	If OpenFileDialog.Choose() Then
		FilesArray = OpenFileDialog.SelectedFiles;
		
		For Each FileName In FilesArray Do
			FileNamesArray.Add(FileName);
		EndDo;
		
	EndIf;
	
	Return FileNamesArray;
	
EndFunction

// Checks the file name for invalid characters.
//
// Parameters:
//  FileName - String-  the file name to check.
//
//  DeleteInvalidCharacters - Boolean -  True specifies to delete invalid
//             characters from the passed string.
//
Procedure CorrectFileName(FileName, DeleteInvalidCharacters = False) Export
	
	// 
	// 
	
	ExceptionStr = CommonClientServer.GetProhibitedCharsInFileName();
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'A file name cannot contain the following characters: %1';"), ExceptionStr);
	
	Result = True;
	
	FoundProhibitedCharsArray =
		CommonClientServer.FindProhibitedCharsInFileName(FileName);
	
	If FoundProhibitedCharsArray.Count() <> 0 Then
		
		Result = False;
		
		If DeleteInvalidCharacters Then
			FileName = CommonClientServer.ReplaceProhibitedCharsInFileName(FileName, "");
		EndIf;
		
	EndIf;
	
	If Not Result Then
		Raise ErrorText;
	EndIf;
	
EndProcedure

// Recursively traverses directories and counts the number of files and their total size.
Procedure GetFileListSize(Path, FilesArray, TotalSize, TotalFilesCount) Export
	
	For Each SelectedFile In FilesArray Do
		
		If SelectedFile.IsDirectory() Then
			NewPath = String(Path);
			
			NewPath = NewPath + GetPathSeparator();
			
			NewPath = NewPath + String(SelectedFile.Name);
			FilesArrayInDirectory = FindFiles(NewPath, GetAllFilesMask());
			
			If FilesArrayInDirectory.Count() <> 0 Then
				GetFileListSize(
					NewPath, FilesArrayInDirectory, TotalSize, TotalFilesCount);
			EndIf;
		
			Continue;
		EndIf;
		
		TotalSize = TotalSize + SelectedFile.Size();
		TotalFilesCount = TotalFilesCount + 1;
		
	EndDo;
	
EndProcedure

// Returns the path to the folder of the view
// "C:\Documents and Settings\USER NAME\Application Data\1C\Files8\".
//
Function SelectPathToUserDataDirectory() Export
	
	DirectoryName = "";
	If FileSystemExtensionAttached1() Then
		DirectoryName = UserDataWorkDir();
	EndIf;
	
	Return DirectoryName;
	
EndFunction

// Opens Windows Explorer and selects the specified file.
Function OpenExplorerWithFile(Val FullFileName) Export
	
	FileOnHardDrive = New File(FullFileName);
	
	If Not FileOnHardDrive.Exists() Then
		Return False;
	EndIf;
	
	FileSystemClient.OpenExplorer(FileOnHardDrive.FullName);
	
	Return True;
	
EndFunction

// 
//
//  Returns:
//   Boolean - 
//
Function FileSystemExtensionAttached1() Export
	If ClientSupportsSynchronousCalls() Then
		Return AttachFileSystemExtension();
	Else
		Return False;
	EndIf;
EndFunction

// Description of procedure  See CommonClient.ShowFileSystemExtensionInstallationQuestion.
//
Procedure ShowFileSystemExtensionInstallationQuestion(NotifyDescription) Export
	If Not ClientSupportsSynchronousCalls() Then
		ExecuteNotifyProcessing(NotifyDescription, False);
	Else
		FileSystemClient.AttachFileOperationsExtension(NotifyDescription);
	EndIf;
EndProcedure

Procedure SendFilesViaEmail(FilesArray, FormIdentifier, SendOptions, IsFile = False) Export
	
	If FilesArray.Count() = 0 Then
		Return;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("FilesArray", FilesArray);
	Parameters.Insert("FormIdentifier", FormIdentifier);
	Parameters.Insert("IsFile", IsFile);
	Parameters.Insert("SendOptions", SendOptions);
	
	NotifyDescription = New NotifyDescription("SendFileViaEmailAccountSettingOffered", ThisObject, Parameters);
	If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
		ModuleEmailOperationsClient.CheckAccountForSendingEmailExists(NotifyDescription);
	EndIf;
	
EndProcedure

Procedure SendFileViaEmailAccountSettingOffered(AccountSetUp, AdditionalParameters) Export
	
	If AccountSetUp <> True Then
		Return;
	EndIf;
	
	AttachmentsList = FilesOperationsInternalServerCall.PutFilesInTempStorage(AdditionalParameters);
	SendOptions = AdditionalParameters.SendOptions;
	
	SendOptions.Insert("Attachments", AttachmentsList);
	SendOptions.Insert("DeleteFilesAfterSending", True);
	
	ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
	ModuleEmailOperationsClient.CreateNewEmailMessage(SendOptions);
	
EndProcedure

Function FileUpdateParameters(ResultHandler, ObjectRef, FormIdentifier) Export
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	HandlerParameters.Insert("FormIdentifier", FormIdentifier);
	HandlerParameters.Insert("StoreVersions");
	HandlerParameters.Insert("CurrentUserEditsFile");
	HandlerParameters.Insert("BeingEditedBy");
	HandlerParameters.Insert("CurrentVersionAuthor");
	HandlerParameters.Insert("PassedFullFilePath", "");
	HandlerParameters.Insert("CreateNewVersion");
	HandlerParameters.Insert("VersionComment");
	HandlerParameters.Insert("ShouldShowUserNotification", True);
	HandlerParameters.Insert("ApplyToAll", False);
	HandlerParameters.Insert("UnlockFiles1", True);
	HandlerParameters.Insert("Encoding");
	Return HandlerParameters;
	
EndFunction	

// Click the "Show service files" command in the file list.
//
// Parameters:
//  List - DynamicList
//
// Returns:
//  Boolean - 
//
Function ShowServiceFilesClick(List) Export
	
	FilterElement = CommonClientServer.FindFilterItemByPresentation(List.Filter.Items, "HideInternal");
	If FilterElement = Undefined Then
		Return False;
	EndIf;
	
	ShowServiceFiles = FilterElement.Use;
	FilterElement.Use = Not ShowServiceFiles;
	Return ShowServiceFiles;
	
EndFunction

// Saves the edited file to the IB and removes the lock from it.
//
// Parameters:
//   Parameters - See FileUpdateParameters.
//
Procedure EndEditAndNotify(Parameters) Export
	
	If Parameters.ObjectRef = Undefined Then
		ReturnResult(Parameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", Parameters.ResultHandler);
	ExecutionParameters.Insert("CommandParameter", Parameters.ObjectRef);
	Handler = New NotifyDescription("EndEditAndNotifyCompletion", ThisObject, ExecutionParameters);
	
	HandlerParameters = FileUpdateParameters(Handler, Parameters.ObjectRef, Parameters.FormIdentifier);
	HandlerParameters.CreateNewVersion = Parameters.CreateNewVersion;
	EndEdit(HandlerParameters);
	
EndProcedure

// Saves the file in the information database, but does not release it.
Procedure SaveFileChangesWithNotification(ResultHandler, CommandParameter, FormIdentifier) Export
	
	If CommandParameter = Undefined Then
		ReturnResult(ResultHandler, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("CommandParameter", CommandParameter);
	
	Handler = New NotifyDescription("SaveFileChangesWithNotificationCompletion", ThisObject, ExecutionParameters);
	HandlerParameters = FileUpdateParameters(Handler, CommandParameter, FormIdentifier);
	SaveFileChanges(HandlerParameters);
	
EndProcedure

// Returns a string representation of the extensions associated with the file type.
//
// Parameters:
//   FileType - String -  For file types, see Fill in the list of file types.
//
Function ExtensionsByFileType(FileType) Export
	
	If FileType = "Pictures" Then
		Return "JPG JPEG JP2 JPG2 PNG BMP TIFF";
	ElsIf FileType = "OfficeDocuments" Then
		Return "DOC DOCX DOCM DOT DOTX DOTM XLS XLSX XLSM XLT XLTM XLSB PPT PPTX PPTM PPS PPSX PPSM POT POTX POTM"
			+ "ODT OTT ODP OTP ODS OTS ODC OTC ODF OTF ODM OTH SDW STW SXW STC SXC SDC SDD STI";
	Else
		Return "";
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// 
//
// Parameters:
//   AttachedFilesOwner - AnyRef -  owner of the attached files.
//   Form - ClientApplicationForm -  form of the file owner.
//   Command - FormCommand - 
//   ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient - CommonModule - 
//     
//
// Returns:
//   Boolean
//
Function Is1CDocumentManagementUsedForFileStorage(AttachedFilesOwner, Form = Undefined,
		Command = Undefined, ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient = Undefined) Export
	
	UseEDIToStoreObjectFiles = False;
	
	// IntegrationWith1CDocumentManagementSubsystem
	If CommonClient.SubsystemExists("IntegrationWith1CDocumentManagementSubsystem") Then
		DMILVersion = "0.0.0.0";
		StandardSubsystemsClient.ClientRunParameters().Property("DMILVersion", DMILVersion);
		If CommonClientServer.CompareVersions(DMILVersion, "3.0.2.4") >= 0 Then
			ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient = CommonClient.CommonModule(
				"Integration1CDocumentManagementCommonClient");
			If Form = Undefined Then
				Form = New Structure("UseAttachedFiles1CDocumentManagement", True);
			EndIf;
			UseEDIToStoreObjectFiles =
				ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient.UseEDIToStoreObjectFiles(
					Form,
					Command,
					AttachedFilesOwner);
		EndIf;
	EndIf;
	// End IntegrationWith1CDocumentManagementSubsystem
	
	Return UseEDIToStoreObjectFiles;
	
EndFunction

// 
//
// Parameters:
//   AttachedFilesOwner - AnyRef -  owner of the attached files.
//   Form - ClientApplicationForm -  form of the file owner.
//   CommandExecuteParameters - CommandExecuteParameters - 
//
Procedure OpenFormAttachedFiles1CDocumentManagement(AttachedFilesOwner, Form = Undefined,
		CommandExecuteParameters = Undefined) Export
	
	// IntegrationWith1CDocumentManagementSubsystem
	DMILVersion = "0.0.0.0";
	StandardSubsystemsClient.ClientRunParameters().Property("DMILVersion", DMILVersion);
	ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient = CommonClient.CommonModule(
		"Integration1CDocumentManagementCommonClient");
	
	If CommonClientServer.CompareVersions(DMILVersion, "3.0.2.7") >= 0 Then
		Parameters = ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient.ParametrsOpeningFileList(Form);
		If CommandExecuteParameters <> Undefined Then
			Parameters.Uniqueness = CommandExecuteParameters.Uniqueness;
			Parameters.Window = CommandExecuteParameters.Window;
		EndIf;
		ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient.OpenFormAttachedFiles(
			AttachedFilesOwner,
			Parameters);
	Else
		ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient.OpenAttachedFiles(
			AttachedFilesOwner);
	EndIf;
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Check the object's data signatures in the table.
// 
// Parameters:
//  Form - ClientApplicationForm - :
//    * Object - FormDataStructure - 
//                  
//               
//
//    * DigitalSignatures - FormDataCollection:
//       * SignatureValidationDate - Date -  the return value. Date of verification.
//       * Status              - String -  the return value. The result of the check.
//       * SignatureAddress        - String -  address of the signature data in temporary storage.
//
//  RefToBinaryData - BinaryData -  binary data of the file.
//                         - String - 
//
//  SelectedRows - Array -  property of the form table of the electronic Signature parameter.
//                   - Undefined - 
//  FileData      - See FilesOperations.FileData
//
Procedure VerifySignatures(Form, RefToBinaryData, SelectedRows = Undefined, FileData = Undefined) Export
	
	// 
	// 
	
	If FileData = Undefined Then
		FileData = Form.Object; // 
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	AdditionalParameters.Insert("SignedObject", FileData.Ref);
	AdditionalParameters.Insert("RowsForCheckingByMachineReadableLOA", New Array);
	
	If Not FileData.Encrypted Then
		CheckSignaturesAfterPrepareData(RefToBinaryData, AdditionalParameters);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",              NStr("en = 'Decrypt file';"));
	DataDetails.Insert("DataTitle",       NStr("en = 'File';"));
	DataDetails.Insert("Data",                RefToBinaryData);
	DataDetails.Insert("Presentation",         FileData.Ref);
	DataDetails.Insert("Object",                FileData.Ref);
	DataDetails.Insert("EncryptionCertificates", FileData.Ref);
	DataDetails.Insert("NotifyOnCompletion",   False);
	
	FollowUpHandler = New NotifyDescription("AfterFileDecryptionOnCheckSignature", ThisObject, AdditionalParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continue with the check Signatures procedure.
Procedure CheckSignaturesAfterCheckRow(SignatureVerificationResult, AdditionalParameters) Export
	
	Result = SignatureVerificationResult.Result;
	SignatureRow = AdditionalParameters.SignatureRow;
	
	RowData = SignatureRowData();
	CheckResult = RowData.CheckResult;
	FillPropertyValues(RowData, SignatureRow);
		
	RowData.SignatureValidationDate = CommonClient.SessionDate();
	RowData.SignatureCorrect      = (Result = True);
	RowData.IsVerificationRequired = SignatureVerificationResult.IsVerificationRequired;
	If ValueIsFilled(SignatureVerificationResult.SignatureType) Then
		RowData.SignatureType        = SignatureVerificationResult.SignatureType;
	EndIf;
	If ValueIsFilled(SignatureVerificationResult.DateActionLastTimestamp) Then
		RowData.DateActionLastTimestamp = SignatureVerificationResult.DateActionLastTimestamp;
	EndIf;
	
	FillPropertyValues(CheckResult, SignatureVerificationResult);
	CheckResult.IsAdditionalAttributesCheckedManually = False;
	CheckResult.AdditionalAttributesManualCheckAuthor = Undefined;
	CheckResult.AdditionalAttributesManualCheckJustification = "";
	RowData.CheckResult = CheckResult;
	
	If SignatureRow.Property("ErrorDescription") Then
		
		If TypeOf(Result) = Type("String") Then
			RowData.ErrorDescription = Result;
		EndIf;
		FilesOperationsInternalClientServer.FillSignatureStatus(RowData, CommonClient.SessionDate());
	Else
		If CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ModuleDigitalSignatureClientServer = CommonClient.CommonModule("DigitalSignatureClientServer");
			ModuleDigitalSignatureClientServer.FillSignatureStatus(RowData, CommonClient.SessionDate());
		EndIf;
	EndIf;
		
	
	FillPropertyValues(SignatureRow, RowData);
	
	CheckSignaturesLoopStart(AdditionalParameters);

EndProcedure

Procedure ExtendActionSignatures(Form, RenewalOptions, FollowUpHandler) Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;

	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.OpenRenewalFormActionsSignatures(
		Form, RenewalOptions, FollowUpHandler);
		
EndProcedure


// For the file form.
//
// Parameters:
//   Form - ClientApplicationForm
//   IsNew - Boolean - 
//
Procedure SetCommandsAvailabilityOfDigitalSignaturesList(Form, IsNew) Export
	
	Items = Form.Items;
	HasSignatures = (Form.DigitalSignatures.Count() <> 0);
	
	DigitalSignaturesOpen = Items.DigitalSignaturesOpen; // FormButton
	DigitalSignaturesOpen.Enabled = HasSignatures;
	
	DigitalSignaturesCheck = Items.DigitalSignaturesCheck; // FormButton
	DigitalSignaturesCheck.Enabled = HasSignatures And Not IsNew;
	
	DigitalSignaturesCheckEverything = Items.DigitalSignaturesCheckEverything; // FormButton
	DigitalSignaturesCheckEverything.Enabled = HasSignatures And Not IsNew;
	
	DigitalSignaturesSave = Items.DigitalSignaturesSave; // FormButton
	DigitalSignaturesSave.Enabled = HasSignatures;
	
	DigitalSignaturesDelete = Items.DigitalSignaturesDelete; // FormButton
	DigitalSignaturesDelete.Enabled = HasSignatures And Not IsNew;
	
	DigitalSignaturesExtendActionSignatures = Items.DigitalSignaturesExtendActionSignatures; // FormButton
	DigitalSignaturesExtendActionSignatures.Enabled = HasSignatures And Not IsNew;
	
EndProcedure

// For the file form.
//
// Parameters:
//   Form - ClientApplicationForm
//
Procedure SetCommandsAvailabilityOfEncryptionCertificatesList(Form) Export
	
	Object   = Form.Object;
	Items = Form.Items;
	
	EncryptionCertificatesOpen = Items.EncryptionCertificatesOpen; // FormButton
	EncryptionCertificatesOpen.Enabled = Object.Encrypted;
	
EndProcedure

#Region Scanning


// Opens the scan and view image dialog.
// 
// Parameters:
//  ExecutionParameters - Structure:
//   * ResultHandler - 
//   * FileOwner - 
//   * OwnerForm - 
//   * IsFile - Boolean
//  ScanningParameters - See FilesOperationsClient.ScanningParameters.
//
Procedure AddFromScanner(ExecutionParameters, ScanningParameters = Undefined) Export
	
#If MobileClient Then
	
	ResultType = ExecutionParameters.ResultType;
	
	MultimediaData = MultimediaTools.MakePhoto();
	If MultimediaData = Undefined Then
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	BaseName = "img_" + Format(CommonClient.SessionDate(), "DF=yyyyMMdd_hhmmss");
	
	ScanningResult = ScanningResult();
		
	If ResultType = FilesOperationsClient.ConversionResultTypeBinaryData() Then
		ScanningResult.BinaryData = MultimediaData.GetBinaryData();
		ExecuteNotifyProcessing(ExecutionParameters.ResultHandler, ScanningResult);
	ElsIf ResultType = FilesOperationsClient.ConversionResultTypeFileName() Then
		ImageData = MultimediaData.GetBinaryData();
		// 
		TempFileName = GetTempFileName(MultimediaData.FileExtention);
		// 
		ImageData.Write(TempFileName);
		ScanningResult.FileName = TempFileName;
		
		ExecuteNotifyProcessing(ExecutionParameters.ResultHandler, ScanningResult);
	Else
		
		FileParameters = FilesOperationsInternalClientServer.FileAddingOptions();
		FileParameters.FilesOwner = ExecutionParameters.FileOwner;
		FileParameters.BaseName = BaseName;
		FileParameters.ExtensionWithoutPoint = MultimediaData.FileExtention;
		
		FileAddress = PutToTempStorage(MultimediaData.GetBinaryData(),
			ExecutionParameters.OwnerForm.UUID);
			
		ScanningResult.Insert("FileAdded", True);
		ScanningResult.Insert("FileRef", FilesOperationsInternalServerCall.AppendFile(FileParameters, FileAddress));
		ReturnResult(ExecutionParameters.ResultHandler, ScanningResult);
	EndIf;
	
#Else
	
	ClientID = ClientID();
	
	If ScanningParameters = Undefined Then
		ScanningParameters = FilesOperationsClient.ScanningParameters(True);
	EndIf;
	
	FormParameters = New Structure("FileOwner, IsFile, NotOpenCardAfterCreateFromFile, OneFileOnly, ResultType");
	FillPropertyValues(FormParameters, ExecutionParameters);
	FormParameters.Insert("ClientID", ClientID);
	FormParameters.Insert("ScanningParameters", ScanningParameters);
	
	OnCloseNotifyDescription = CompletionHandler(ExecutionParameters.ResultHandler);
	OpenForm("DataProcessor.Scanning.Form.ScanningResult", FormParameters, 
		ExecutionParameters.OwnerForm, , , , OnCloseNotifyDescription);
	
#EndIf
	
EndProcedure

Function ScanningResult() Export
	Result = New Structure;
	Result.Insert("ErrorText", "");
	Result.Insert("FileAdded", False);
	Result.Insert("FileRef");	
	Result.Insert("BinaryData");
	Result.Insert("FileName");
	Return Result;
EndFunction

Function ClientID() Export
	SystemInfo = New SystemInfo();
	Return SystemInfo.ClientID;
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// 

// Open the file version.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  FileData             - Structure
//  UUID - Unique form identifier.
//
Procedure OpenFileVersion(ResultHandler, FileData, UUID = Undefined) Export
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("FileData", FileData);
	HandlerParameters.Insert("UUID", UUID);
	
	Handler = New NotifyDescription("OpenFileVersionAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonClientOverridable.BeforeExit
Procedure BeforeExit(Cancel, Warnings) Export
	
	Response = CheckLockedFilesOnExit();
	If Response = Undefined Then 
		Return;
	EndIf;
	
	If TypeOf(Response) <> Type("Structure") Then
		Return;
	EndIf;
	
	UserWarning = StandardSubsystemsClient.WarningOnExit();
	UserWarning.HyperlinkText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Open list of locked files (%1)';"),
		Response.LockedFilesCount);
	UserWarning.WarningText = NStr("en = 'Some files are being edited, and their changes are not propagated to the app.';");
	
	ActionOnClickHyperlink = UserWarning.ActionOnClickHyperlink;
	
	ApplicationWarningForm = Undefined;
	Response.Property("ApplicationWarningForm", ApplicationWarningForm);
	ApplicationWarningFormParameters = Undefined;
	Response.Property("ApplicationWarningFormParameters", ApplicationWarningFormParameters);
	
	Form = Undefined;
	Response.Property("Form", Form);
	FormParameters = Undefined;
	Response.Property("FormParameters", FormParameters);
	
	If ApplicationWarningForm <> Undefined Then 
		ActionOnClickHyperlink.ApplicationWarningForm = ApplicationWarningForm;
		ActionOnClickHyperlink.ApplicationWarningFormParameters = ApplicationWarningFormParameters;
	EndIf;
	If Form <> Undefined Then 
		ActionOnClickHyperlink.Form = Form;
		ActionOnClickHyperlink.FormParameters = FormParameters;
	EndIf;
	
	Warnings.Add(UserWarning);
	
EndProcedure

Function FileWriteNotificationParameters(Event = "") Export
	EventParameters = New Structure;
	EventParameters.Insert("Event", Event);
	EventParameters.Insert("IsNew", False);
	EventParameters.Insert("Owner");
	EventParameters.Insert("FileOwner"); // 
	EventParameters.Insert("File");
	Return EventParameters;
EndFunction

Procedure NotifyOfFilesModification(Files, FileWriteNotificationParameters = Undefined) Export
	If TypeOf(Files) <> Type("Array") Then
		FilesForNotification = CommonClientServer.ValueInArray(Files);
	Else
		FilesForNotification = Files;
	EndIf;
	
	If FileWriteNotificationParameters = Undefined Then
		FileWriteNotificationParameters = FileWriteNotificationParameters();
	EndIf;
	
	For Each File In FilesForNotification Do
		Notify("Write_File", FileWriteNotificationParameters, File);
	EndDo;
	
EndProcedure

#Region TextExtraction

Procedure ExtractVersionText(FileOrFileVersion, FileAddress, Extension, UUID,
	Encoding = Undefined) Export

#If Not WebClient Then
	FileNameWithPath = GetTempFileName(Extension);
	
	If Not GetFile(FileAddress, FileNameWithPath, False) Then
		Return;
	EndIf;
	
	// 
	If IsTempStorageURL(FileAddress) Then
		DeleteFromTempStorage(FileAddress);
	EndIf;
	
	ExtractionResult = "NotExtracted";
	TempTextStorageAddress = "";
	
	Text = "";
	If FileNameWithPath <> "" Then
		
		// 
		Cancel = False;
		Text = ExtractText1(FileNameWithPath, Cancel, Encoding);
		
		If Cancel = False Then
			ExtractionResult = "Extracted";
			
			If Not IsBlankString(Text) Then
				TempFileName = GetTempFileName();
				TextFile = New TextWriter(TempFileName, TextEncoding.UTF8);
				TextFile.Write(Text);
				TextFile.Close();
				
				ImportResult1 = PutFileFromHardDriveInTempStorage(TempFileName, , UUID);
				If ImportResult1 <> Undefined Then
					TempTextStorageAddress = ImportResult1;
				EndIf;
				
				Try
					DeleteFiles(TempFileName);
				Except
					EventLogClient.AddMessageForEventLog(EventLogEvent(),
						"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
				EndTry;	
			EndIf;
		Else
			// 
			// 
			ExtractionResult = "FailedExtraction";
		EndIf;
		
	EndIf;
	
	Try
		DeleteFiles(FileNameWithPath);
	Except
		EventLogClient.AddMessageForEventLog(EventLogEvent(),
			"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
	EndTry;	
	
	FilesOperationsInternalServerCall.RecordTextExtractionResult(
		FileOrFileVersion, ExtractionResult, TempTextStorageAddress);
		
#EndIf

EndProcedure

#EndRegion

Procedure CheckDirAvailability(NotificationOfResult, DirectoryName) Export
	TestDirectoryName = DirectoryName + GetPathSeparator()+ "CheckAccess";
	Context = New Structure;
	Context.Insert("NotificationOfResult", NotificationOfResult);
	Context.Insert("TestDirectoryName", TestDirectoryName);
	
	Notification = New NotifyDescription("CheckDirAvailabilityAfterCreated", ThisObject, 
		Context, "CheckDirAvailabilityCreationError", ThisObject);
	BeginCreatingDirectory(Notification, TestDirectoryName);
EndProcedure

Procedure SpreadsheetDocumentSelectionHandler(ReportForm, Item, Area, StandardProcessing) Export
	
	If ReportForm.ReportSettings.FullName <> "Report.VolumeIntegrityCheck" Then
		Return;
	EndIf;
	
	If Area.Details = "VolumeIntegrityCheck.RecoverFiles" Then
		StandardProcessing = False;
		Volume = ReportForm.Report.SettingsComposer.Settings.DataParameters.Items.Find("Volume").Value;
		Job = FilesOperationsInternalServerCall.RunFilesRecovery(Volume, ReportForm.UUID);

		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ReportForm",  ReportForm);
		
		CallbackOnCompletion = New NotifyDescription("AfterFilesRecovered", ThisObject, AdditionalParameters);

		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ReportForm);
		IdleParameters.Title = NStr("en = 'Restoring file info';");
		IdleParameters.OutputIdleWindow = True;
		
		TimeConsumingOperationsClient.WaitCompletion(Job, CallbackOnCompletion, IdleParameters);
	EndIf;

EndProcedure

#EndRegion

#Region Private

Procedure SetModificationUniversalTime(PathToFile, NewTimeOfChange)
	If Not ValueIsFilled(NewTimeOfChange) Then
		Return;
	EndIf;
	
	File = New File(PathToFile);
	If File.Exists() Then
		File.SetModificationUniversalTime(NewTimeOfChange);
	EndIf;
EndProcedure

// Returns True if a file with this extension can be downloaded.
Function CheckExtentionOfFileToDownload(FileExtention, RaiseException1 = True)
	
	CommonSettings = CommonFilesOperationsSettings();
	If Not CommonSettings.FilesImportByExtensionDenied Then
		Return True;
	EndIf;
	
	If FilesOperationsInternalClientServer.FileExtensionInList(
		CommonSettings.DeniedExtensionsList, FileExtention) Then
		
		If RaiseException1 Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Uploading files with the ""%1"" extension is not allowed.
				           |Please contact the administrator.';"),
				FileExtention);
		Else
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

Function EncryptedFilesExtension()
	
	If CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
		Return ModuleDigitalSignatureClient.PersonalSettings().EncryptedFilesExtension;
	Else
		Return "p7m";
	EndIf;
	
EndFunction

// Extract text from a file and return it as a string.
Function ExtractText1(FullFileName, Cancel = False, Encoding = Undefined)
	
	ExtractedText = "";
	
	Try
		File = New File(FullFileName);
		If Not File.Exists() Then
			Cancel = True;
			Return ExtractedText;
		EndIf;
	Except
		Cancel = True;
		Return ExtractedText;
	EndTry;
	
	Dismiss = False;
	CommonSettings = CommonFilesOperationsSettings();
	
#If Not WebClient And Not MobileClient Then
	
	FileNameExtension =
		CommonClientServer.GetFileNameExtension(FullFileName);
	
	FileExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
		CommonSettings.TextFilesExtensionsList, FileNameExtension);
	
	If FileExtensionInList Then
		Return FilesOperationsInternalClientServer.ExtractTextFromTextFile(
			FullFileName, Encoding, Cancel);
	EndIf;
	
	Try
		Extracting = New TextExtraction(FullFileName);
		ExtractedText = Extracting.GetText();
	Except
		// 
		ExtractedText = "";
		Dismiss = True;
	EndTry;
		
#EndIf
	
	If IsBlankString(ExtractedText) Then
		
		FileNameExtension =
			CommonClientServer.GetFileNameExtension(FullFileName);
		
		FileExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
			CommonSettings.FilesExtensionsListOpenDocument, FileNameExtension);
		
		If FileExtensionInList Then
			Return FilesOperationsInternalClientServer.ExtractOpenDocumentText(FullFileName, Cancel);
		EndIf;
		
	EndIf;
	
	If Dismiss Then
		Cancel = True;
	EndIf;
	
	Return ExtractedText;
	
EndFunction

// Returns the path to the user's working data directory. This directory is used
// as the initial value for the user's working directory.
//
// Parameters:
//  Notification - NotifyDescription - 
//   :
//     * Directory        - String -  full name of the user's working data directory.
//     * ErrorDescription - String -  error text if the folder could not be retrieved.
//
Procedure GetUserDataWorkingDirectory(Notification)
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	
	BeginGettingUserDataWorkDir(New NotifyDescription(
		"GetUserDataWorkingDirectoryAfterGet", ThisObject, Context,
		"GetUserDataWorkingDirectoryAfterGetDataError", ThisObject));
	
EndProcedure

// Continue with the procedure to get the working directory of the user's Data.
Procedure GetUserDataWorkingDirectoryAfterGetDataError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	Result = New Structure;
	Result.Insert("Directory", "");
	Result.Insert("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Cannot retrieve the user''s working directory. Reason:
		           |%1';"), ErrorProcessing.BriefErrorDescription(ErrorInfo)));
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Continue with the procedure to get the working directory of the user's Data.
Procedure GetUserDataWorkingDirectoryAfterGet(UserDataDir, Context) Export
	
	Result = New Structure;
	Result.Insert("Directory", UserDataDir);
	Result.Insert("ErrorDescription", "");
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Continue with the check Signatures procedure.
Procedure CheckSignaturesLoopStart(AdditionalParameters)
	
	If AdditionalParameters.Collection.Count() <= AdditionalParameters.IndexOf + 1 Then
		
		
		Return;
	EndIf;
	
	AdditionalParameters.IndexOf = AdditionalParameters.IndexOf + 1;
	Item = AdditionalParameters.Collection[AdditionalParameters.IndexOf];
	
	AdditionalParameters.Insert("SignatureRow", ?(TypeOf(Item) <> Type("Number"), Item,
		AdditionalParameters.Form.DigitalSignatures.FindByID(Item)));
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	SignatureVerificationParameters = ModuleDigitalSignatureClient.SignatureVerificationParameters();
	SignatureVerificationParameters.ResultAsStructure = True;
	
	ModuleDigitalSignatureClient.VerifySignature(
		New NotifyDescription("CheckSignaturesAfterCheckRow", ThisObject, AdditionalParameters),
		AdditionalParameters.Data,
		AdditionalParameters.SignatureRow.SignatureAddress,
		Undefined,
		AdditionalParameters.SignatureRow.SignatureDate, SignatureVerificationParameters);
	
EndProcedure

// Checks the properties of the file in the working directory and in the file storage,
// if necessary, checks with the user and returns one of the actions:
// "Open Existing", "Take storagesopen","Cancel".
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  FileNameWithPath - String -  the full name of the file with the path in the working directory.
// 
//  FileData    - Structure:
//                   Size Is A Number.
//                   Datatypeconversion - Date.
//                   In Workcatalogenachtension-Boolean.
//
Procedure ActionOnOpenFileInWorkingDirectory(ResultHandler, FileNameWithPath, FileData)
	
	If FileData.Property("UpdatePathFromFileOnHardDrive") Then
		ReturnResult(ResultHandler, "GetFromStorageAndOpen");
		Return;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("FileOperation", "OpenInWorkingFolder");
	Parameters.Insert("FullFileNameInWorkingDirectory", FileNameWithPath);
	
	File = New File(Parameters.FullFileNameInWorkingDirectory);
	
	Parameters.Insert("ChangeDateUniversalInFileStorage",
		FileData.UniversalModificationDate);
	Parameters.Insert("ChangeDateUniversalInWorkingDirectory",
		File.GetModificationUniversalTime());
	Parameters.Insert("ChangeDateInWorkingDirectory",
		ToLocalTime(Parameters.ChangeDateUniversalInWorkingDirectory));
	Parameters.Insert("ChangeDateInFileStorage",
		ToLocalTime(Parameters.ChangeDateUniversalInFileStorage));
	Parameters.Insert("SizeInWorkingDirectory", File.Size());
	Parameters.Insert("SizeInFileStorage", FileData.Size);
	
	DateDifference = Parameters.ChangeDateUniversalInWorkingDirectory
	           - Parameters.ChangeDateUniversalInFileStorage;
	
	If DateDifference < 0 Then
		DateDifference = -DateDifference;
	EndIf;
	
	If DateDifference <= 1 Then // 
		
		If Parameters.SizeInFileStorage <> 0
		   And Parameters.SizeInFileStorage <> Parameters.SizeInWorkingDirectory Then
			// 
			
			Parameters.Insert("Title",
				NStr("en = 'Different file sizes';"));
			
			Parameters.Insert("Message",
				NStr("en = 'The size of the local file copy differs from the size of the file stored in the application.
				           |
				           |Do you want to update the local file
				           |or open the local file without updating it?';"));
		Else
			ReturnResult(ResultHandler, "OpenExistingFile");
			Return;
		EndIf;
		
	ElsIf Parameters.ChangeDateUniversalInWorkingDirectory
	        < Parameters.ChangeDateUniversalInFileStorage Then
		// 
		If FileData.InWorkingDirectoryForRead = False Then
			Parameters.Insert("Title", NStr("en = 'Newer file version in application';"));
			Parameters.Insert("Message",
				NStr("en = 'The file in the application was modified
				           |later than its local copy.
				           |
				           |Do you want to retrieve the file from the application
				           |or open the local copy?';"));
		Else
			ReturnResult(ResultHandler, "GetFromStorageAndOpen");
			Return;
		EndIf;
	
	ElsIf Parameters.ChangeDateUniversalInWorkingDirectory
	        > Parameters.ChangeDateUniversalInFileStorage Then
		// 
		
		If FileData.InWorkingDirectoryForRead = False
		   And FileData.BeingEditedBy = UsersClient.AuthorizedUser() Then
			
			// 
			ReturnResult(ResultHandler, "OpenExistingFile");
			Return;
		Else
			// 
			Parameters.Insert("Title", NStr("en = 'Newer local file version';"));
			Parameters.Insert(
				"Message",
				NStr("en = 'The local file copy was modified later than the file in the application. The local copy might have been edited.
				           |
				           |Do you want to open the local copy or replace it with the file
				           |from the application?';"));
		EndIf;
	EndIf;
	
	OpenForm("CommonForm.SelectActionOnFilesDifference", Parameters, , , , , ResultHandler, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

// Returns the "My Documents" folder.
//
Function MyDocumentsDirectory()
	Return DocumentsDir();
EndFunction

// Returns the path to the user's working directory.
//
// Parameters:
//  Notification - NotifyDescription - 
//   :
//     * Directory        - String -  full name of the user's working directory.
//     * ErrorDescription - String -  error text if the folder could not be retrieved.
//
Procedure GetUserWorkingDirectory(Notification)
	
	ParameterName = "StandardSubsystems.WorkingDirectoryAccessCheckExecuted";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, False);
	EndIf;
	
	DirectoryName =
		StandardSubsystemsClient.ClientRunParameters().PersonalFilesOperationsSettings.PathToLocalFileCache;
	
	// 
	If DirectoryName <> Undefined
		And Not IsBlankString(DirectoryName)
		And ApplicationParameters["StandardSubsystems.WorkingDirectoryAccessCheckExecuted"] Then
		
		Result = New Structure;
		Result.Insert("Directory", DirectoryName);
		Result.Insert("ErrorDescription", "");
		
		ExecuteNotifyProcessing(Notification, Result);
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("Directory", DirectoryName);
	
	GetUserDataWorkingDirectory(New NotifyDescription(
		"GetUserWorkingDirectoryAfterGetDataDirectory", ThisObject, Context));
	
EndProcedure

// Continue the procedure to get the user's working Directory.
Procedure GetUserWorkingDirectoryAfterGetDataDirectory(Result, Context) Export
	
	If ValueIsFilled(Result.ErrorDescription) Then
		ExecuteNotifyProcessing(Context.Notification, Result);
		Return;
	EndIf;
	
#If Not WebClient Then
	
	If Result.Directory <> Context.Directory Then
		// 
		Try
			CreateDirectory(Context.Directory);
			TestDirectoryName = Context.Directory + "CheckAccess\";
			CreateDirectory(TestDirectoryName);
			DeleteFiles(TestDirectoryName);
		Except
			// 
			// 
			Context.Directory = Undefined;
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
		EndTry;
	EndIf;
	
#EndIf
	
	ApplicationParameters["StandardSubsystems.WorkingDirectoryAccessCheckExecuted"] = True;
	
	If Context.Directory = Undefined Then
		SetUserWorkingDirectory(Result.Directory);
	Else
		Result.Directory = Context.Directory;
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Shows a reminder about how to work with a file in the web client,
// if the "Show hints when editing files" setting is enabled.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//
Procedure OutputNotificationOnEdit(ResultHandler)
	PersonalSettings = PersonalFilesOperationsSettings();
	If PersonalSettings.ShowTooltipsOnEditFiles = True Then
		If Not FileSystemExtensionAttached1() Then
			ReminderText = 
				NStr("en = 'You will be prompted to open or save the file.
				|
				|1. Click Save.
				|
				|2. Select a directory to save the file and remember its name 
				|(you will need it to edit and put the file back to the application).
				|
				|3. To edit the file, open the previously selected directory,
				|find the saved file, and open it.';");
				
			SystemInfo = New SystemInfo;
			If StrFind(SystemInfo.UserAgentInformation, "Firefox") <> 0 Then
				ReminderText = ReminderText
				+ "
				|
				|"
				+ NStr("en = '(By default Mozilla Firefox saves files to ""My Documents"" directory.)';");
			EndIf;
			Buttons = New ValueList;
			Buttons.Add("Continue", NStr("en = 'Continue';"));
			Buttons.Add("Cancel", NStr("en = 'Cancel';"));
			ReminderParameters = New Structure;
			ReminderParameters.Insert("Picture", PictureLib.DialogInformation);
			ReminderParameters.Insert("CheckBoxText",
				NStr("en = 'Do not show this message again';"));
			ReminderParameters.Insert("Title",
				NStr("en = 'Get file to view or edit';"));
			StandardSubsystemsClient.ShowQuestionToUser(
				ResultHandler, ReminderText, Buttons, ReminderParameters);
			
			Return;
		EndIf;
	EndIf;
	ReturnResult(ResultHandler, True);
EndProcedure

// Continue with the check Signatures procedure.
Procedure CheckSignaturesAfterPrepareData(Data, AdditionalParameters)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	If AdditionalParameters.SelectedRows = Undefined Then
		Collection = AdditionalParameters.Form.DigitalSignatures;
	Else
		Collection = AdditionalParameters.SelectedRows;
	EndIf;
	
	If CommonClient.SubsystemExists("CloudTechnology.DigitalSignatureSaaS") Then
		ModuleDigitalSignatureSaaSClient = CommonClient.CommonModule("DigitalSignatureSaaSClient");
		UseDigitalSignatureSaaS = ModuleDigitalSignatureSaaSClient.UsageAllowed();
	Else
		UseDigitalSignatureSaaS = False;
	EndIf;
	
	UseACloudSignature = False;
	If CommonClient.SubsystemExists("StandardSubsystems.DSSElectronicSignatureService") Then
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		UseACloudSignature = TheDSSCryptographyServiceModuleClient.UseCloudSignatureService();
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	
	If UseDigitalSignatureSaaS
	 Or UseACloudSignature
	 Or Not ModuleDigitalSignatureClient.VerifyDigitalSignaturesOnTheServer() Then
		
		AdditionalParameters.Insert("Data", Data);
		AdditionalParameters.Insert("Collection", Collection);
		AdditionalParameters.Insert("ModuleDigitalSignatureClient", ModuleDigitalSignatureClient);
		AdditionalParameters.Insert("IndexOf", -1);
		CheckSignaturesLoopStart(AdditionalParameters);
		Return;
	EndIf;
	
	If TypeOf(Data) = Type("BinaryData") Then
		DataAddress = PutToTempStorage(Data, AdditionalParameters.FormIdentifier);
	Else
		DataAddress = Data;
	EndIf;
	
	RowsData = New Array;
	
	For Each Item In Collection Do
		SignatureRow = ?(TypeOf(Item) <> Type("Number"), Item,
			AdditionalParameters.Form.DigitalSignatures.FindByID(Item));
		
		RowData = SignatureRowData();
		FillPropertyValues(RowData, SignatureRow);
		RowsData.Add(RowData);
		
	EndDo;
	
	FilesOperationsInternalServerCall.VerifySignatures(DataAddress, RowsData, AdditionalParameters.SignedObject);
	
	IndexOf = 0;
	For Each Item In Collection Do
		SignatureRow = ?(TypeOf(Item) <> Type("Number"), Item,
			AdditionalParameters.Form.DigitalSignatures.FindByID(Item));
		FillPropertyValues(SignatureRow, RowsData[IndexOf]);
		IndexOf = IndexOf + 1;
	EndDo;
	
EndProcedure

Function SignatureRowData()
	
	ModuleDigitalSignatureClientServer = CommonClient.CommonModule("DigitalSignatureClientServer");
	Return ModuleDigitalSignatureClientServer.ResultOfSignatureValidationOnForm();
	
EndFunction

// 
//
// Parameters:
//  SelectedFiles                 - Array of String -  file paths.
//  FileOwner                  - DefinedType.FilesOwner -  a link to the owner of the file.
//  Customizationsfiles - Structure.
//  AttachedFilesArray      - Array of DefinedType.AttachedFile -  the return value. it is filled with links
//                                   to the added files.
//  FormIdentifier             - UUID -  Unique form identifier.
//
Procedure PutSelectedFilesInStorage(Val SelectedFiles,
                                            Val FileOwner,
                                            AttachedFilesArray,
                                            Val FormIdentifier,
                                            Val NameOfFileToCreate = "",
                                            Val FilesGroup = Undefined)
	
	CommonSettings = CommonFilesOperationsSettings();
	
	CurrentPosition = 0;
	
	LastSavedFile = Undefined;
	
	For Each FullFileName In SelectedFiles Do
		
		CurrentPosition = CurrentPosition + 1;		
		File = New File(FullFileName);		
		CheckCanImportFile(File);
		
		If CommonSettings.ExtractTextFilesOnServer Then
			TempTextStorageAddress = "";
		Else
			TempTextStorageAddress = ExtractTextToTempStorage(FullFileName, FormIdentifier);
		EndIf;
	
		ModificationTimeUniversal = File.GetModificationUniversalTime();
		
		UpdateFileSavingState(SelectedFiles, File, CurrentPosition, NameOfFileToCreate);
		LastSavedFile = File;
		
		Files = New Array;
		LongDesc = New TransferableFileDescription(File.FullName, "");
		Files.Add(LongDesc);
		
		PlacedFiles = New Array;		
		If Not PutFiles(Files, PlacedFiles, , False, FormIdentifier) Then
			CommonClient.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Cannot put the ""%1"" file in the application.';"),
					File.FullName) );
			Continue;
		EndIf;
		
		TempFileStorageAddress = PlacedFiles[0].Location;
		
		FileNameAndExtension = FileNameAndExtension(File);
		FileExtention = FileNameAndExtension.FileExtention;
		FileNameWithoutExtension = FileNameAndExtension.FileNameWithoutExtension;
	
		BaseName = ?(IsBlankString(NameOfFileToCreate), FileNameWithoutExtension, NameOfFileToCreate);
		
		FileParameters = FilesOperationsInternalClientServer.FileAddingOptions();
		FileParameters.FilesGroup = FilesGroup;
		FileParameters.FilesOwner = FileOwner;
		FileParameters.BaseName = BaseName;
		FileParameters.ExtensionWithoutPoint = FileExtention;
		FileParameters.ModificationTimeUniversal = ModificationTimeUniversal;
		
		AttachedFile = FilesOperationsInternalServerCall.AppendFile(FileParameters,
			TempFileStorageAddress, TempTextStorageAddress);		
		If AttachedFile = Undefined Then
			Continue;
		EndIf;
		
		AttachedFilesArray.Add(AttachedFile);
		
	EndDo;
	
	UpdateFileSavingState(SelectedFiles, LastSavedFile, , BaseName);
	
EndProcedure

Procedure UpdateFileSavingState(Val SelectedFiles,
											 Val File,
											 Val CurrentPosition = Undefined,
											 NameOfFileToCreate = "");
	
	If File = Undefined Then
		Return;
	EndIf;
	
	FileNameToSave = ?(IsBlankString(NameOfFileToCreate), File.Name, NameOfFileToCreate);
	
	SizeInMB = FilesOperationsInternalClientServer.FileSizePresentation(File.Size() / (1024 * 1024));
	
	If SelectedFiles.Count() > 1 Then
		If CurrentPosition = Undefined Then
			ShowUserNotification(NStr("en = 'Save files';"),, NStr("en = 'The files are saved.';"));
		EndIf;
	Else
		If CurrentPosition = Undefined Then
			ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'File ""%1"" (%2 MB) is saved.';"),
				FileNameToSave,
				SizeInMB);
			ShowUserNotification(NStr("en = 'Save files';"), , ExplanationText, PictureLib.DialogInformation);
		EndIf;
	EndIf;
	
EndProcedure

// 
// 
// Parameters:
//  ResultHandler    - NotifyDescription - 
//                            :
//                             
//                                                       
//                             
//                                                                      
//  FileOwner           - 
//  
//  FormIdentifier      - Unique form identifier.
//
Procedure PutSelectedFilesInStorageWeb(ResultHandler, Val FileOwner, Val FormIdentifier)
	
	Parameters = New Structure;
	Parameters.Insert("FileOwner", FileOwner);
	Parameters.Insert("ResultHandler", ResultHandler);
	
	NotifyDescription = New NotifyDescription("PutSelectedFilesInStorageWebCompletion", ThisObject, Parameters);
	BeginPutFile(NotifyDescription, , ,True, FormIdentifier);
	
EndProcedure

// Continue the procedure to place the selected files in the storage area of the Web.
Procedure PutSelectedFilesInStorageWebCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	Handler = AdditionalParameters.ResultHandler; // NotifyDescription
	If Not Result Then
		ExecuteNotifyProcessing(Handler, Undefined);
		Return;
	EndIf;
	
	FileOwner = AdditionalParameters.FileOwner;
	PathStructure = CommonClientServer.ParseFullFileName(SelectedFileName);
	FilesGroup = ?(Handler.AdditionalParameters.Property("FilesGroup"),
		Handler.AdditionalParameters.FilesGroup, "");
	
	If Not IsBlankString(PathStructure.Extension) Then
		Extension = CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension);
		BaseName = PathStructure.BaseName;
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot put the ""%1"" file in the application.';"),
			SelectedFileName);
	EndIf;
	
	CheckExtentionOfFileToDownload(Extension);
	
	CommonSettings = CommonFilesOperationsSettings();
	FileToImportSize = GetFromTempStorage(Address).Size();
	If FileToImportSize > CommonSettings.MaxFileSize Then
		
		SizeInMB     = FileToImportSize / (1024 * 1024);
		SizeInMBMax = CommonSettings.MaxFileSize / (1024 * 1024);
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The size of file ""%1"" (%2 MB)
			|exceeds the limit (%3 MB).';"),
			SelectedFileName,
			FilesOperationsInternalClientServer.FileSizePresentation(SizeInMB),
			FilesOperationsInternalClientServer.FileSizePresentation(SizeInMBMax));
		
		Raise ErrorDescription;
		
	EndIf;
	
	FileParameters = FilesOperationsInternalClientServer.FileAddingOptions();
	FileParameters.FilesOwner = FileOwner;
	FileParameters.BaseName = BaseName;
	FileParameters.ExtensionWithoutPoint = Extension;
	If ValueIsFilled(FilesGroup) Then
		FileParameters.FilesGroup = FilesGroup;
	EndIf;
	
	// 
	AttachedFile = FilesOperationsInternalServerCall.AppendFile(
		FileParameters, Address);
		
	ExecuteNotifyProcessing(Handler, AttachedFile);
	
EndProcedure

// Checks whether the File can be released.
//
// Parameters:
//  ObjectRef - CatalogRef.Files -  file.
//
//  EditedByCurrentUser - Boolean -
//                  the file is edited by the current user.
//
//  BeingEditedBy  - CatalogRef.Users -  the person who took the file.
//
//  ErrorString - String -  which returns the reason for the error in case of failure
//                 (for example, "the File is occupied by another user").
//
// Returns:
//  Boolean -  
//
Function AbilityToUnlockFile(ObjectRef,
                                  EditedByCurrentUser,
                                  BeingEditedBy,
                                  ErrorString = "") Export
	
	If EditedByCurrentUser Then 
		Return True;
	ElsIf Not ValueIsFilled(BeingEditedBy) Then
		ErrorString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot unlock file ""%1""
			           |because it is not locked.';"),
			String(ObjectRef));
		Return False;
	Else
		If UsersClient.IsFullUser() Then
			Return True;
		EndIf;
		
		ErrorString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot unlock file ""%1""
			           |because it is locked by ""%2"".';"),
			String(ObjectRef),
			String(BeingEditedBy));
		Return False;
	EndIf;
	
EndFunction

Procedure UnlockFiles(ListOfFiles) Export
	FilesArray = New Array;
	For Each ListItem In ListOfFiles.SelectedRows Do
		RowData = ListOfFiles.RowData(ListItem); // DefinedType.AttachedFile
		If Not AbilityToUnlockFile(
				RowData.Ref,
				RowData.CurrentUserEditsFile,
				RowData.BeingEditedBy) Then
			Continue;
		EndIf;
		FilesArray.Add(RowData.Ref);
	EndDo;
	
	If FilesArray.Count() = 0 Then 
		Return;
	EndIf;
	
	FilesData = FilesOperationsInternalServerCall.UnlockFiles(FilesArray);
	
	// 
	Handler = New NotifyDescription;
	For Each File In FilesArray Do
		FileVersion = FilesData.FilesVersions.Get(File);
		DeleteFileFromWorkingDirectory(Handler, FileVersion, True);
	EndDo;
	
	StandardSubsystemsClient.SetClientParameter("LockedFilesCount", 
		FilesData.LockedFilesCount);
	If FilesArray.Count() > 1 Then
		NotifyChanged(TypeOf(FilesArray[0]));
		Notify("Write_File", FileWriteNotificationParameters(), Undefined);
	Else	
		NotifyChanged(FilesArray[0]);
		Notify("Write_File", FileWriteNotificationParameters(), FilesArray[0]);
	EndIf;

EndProcedure

// Releases the file without updating it.
//
// Parameters:
//  FileData             - Structure
//  UUID - 
//
Procedure UnlockFileWithoutQuestion(FileData, UUID = Undefined)
	
	FilesOperationsInternalServerCall.UnlockFile(FileData, UUID);
	ChangeLockedFilesCount();
	
	ExtensionAttached = FileSystemExtensionAttached1();
	If ExtensionAttached Then
		ReregisterFileInWorkingDirectory(FileData, True, FileData.OwnerWorkingDirectory <> "");
	EndIf;
	
	ShowUserNotification(NStr("en = 'The file is released.';"),
		FileData.URL, FileData.FullVersionDescription, PictureLib.DialogInformation);
	
EndProcedure

// Moves files to the specified folder.
//
// Parameters:
//  ObjectsRef - Array -  array of files.
//
//  Folder         - CatalogRef.FilesFolders -  the folder
//                  to move files to.
//
Procedure MoveFilesToFolder(ObjectsRef, Folder) Export
	
	FilesData = FilesOperationsInternalServerCall.MoveFiles(ObjectsRef, Folder);
	
	For Each FileData In FilesData Do
		
		ShowUserNotification(
			NStr("en = 'Move file';"),
			FileData.URL,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'File ""%1""
				           |is moved to folder ""%2"".';"),
				String(FileData.Ref),
				String(Folder)),
			PictureLib.DialogInformation);
		
	EndDo;
	
EndProcedure

// Extract the text from the file and put it in temporary storage.
Function ExtractTextToTempStorage(FullFileName, UUID = "", Cancel = False,
	Encoding = Undefined)
	
	TempStorageAddress = "";
	
	#If Not WebClient Then
		
		Text = ExtractText1(FullFileName, Cancel, Encoding);
		
		If IsBlankString(Text) Then
			Return "";
		EndIf;
		
		TempFileName = GetTempFileName();
		TextFile = New TextWriter(TempFileName, TextEncoding.UTF8);
		TextFile.Write(Text);
		TextFile.Close();
		
		ImportResult1 = PutFileFromHardDriveInTempStorage(TempFileName, , UUID);
		If ImportResult1 <> Undefined Then
			TempStorageAddress = ImportResult1;
		EndIf;
	
		Try	
			DeleteFiles(TempFileName);
		Except
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
		EndTry;	
		
	#EndIf
	
	Return TempStorageAddress;
	
EndFunction

// Returns a string constant for generating log messages.
//
// Returns:
//   String
//
Function EventLogEvent()
	
	Return NStr("en = 'Files';", CommonClient.DefaultLanguageCode());
	
EndFunction

// Returns the text of the error message about creating a new file.
//
// Parameters:
//  ErrorInfo - ErrorInfo
//
Function ErrorCreatingNewFile(ErrorInfo)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Cannot create a file due to:
		           |%1';"),
		ErrorProcessing.BriefErrorDescription(ErrorInfo));

EndFunction

// Checks the file extension and size.
//
// Parameters:
//   File - File
//   RaiseException1 - Boolean
//   FilesWithErrors - Array of Structure:
//     * FileName - String
//     * Error - String
//
Function CheckCanImportFile(File, RaiseException1 = True, FilesWithErrors = Undefined)
	
	CommonSettings = CommonFilesOperationsSettings();
	
	// 
	If File.Size() > CommonSettings.MaxFileSize Then
		
		SizeInMB     = File.Size() / (1024 * 1024);
		SizeInMBMax = CommonSettings.MaxFileSize / (1024 * 1024);
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The size of file ""%1"" (%2 MB)
			           |exceeds the limit (%3 MB).';"),
			File.Name,
			FilesOperationsInternalClientServer.FileSizePresentation(SizeInMB),
			FilesOperationsInternalClientServer.FileSizePresentation(SizeInMBMax));
		
		If RaiseException1 Then
			Raise ErrorDescription;
		EndIf;
		
		Record = New Structure;
		Record.Insert("FileName", File.FullName);
		Record.Insert("Error",   ErrorDescription);
		
		FilesWithErrors.Add(Record);
		Return False;
	EndIf;
	
	// 
	If Not CheckExtentionOfFileToDownload(File.Extension, False) Then
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Uploading files with the ""%1"" extension is not allowed.
			           |Please contact the administrator.';"),
			File.Extension);
		
		If RaiseException1 Then
			Raise ErrorDescription;
		EndIf;
		
		Record = New Structure;
		Record.Insert("FileName", File.FullName);
		Record.Insert("Error",   ErrorDescription);
		
		FilesWithErrors.Add(Record);
		Return False;
	EndIf;
	
	// 
	If StrStartsWith(File.Name, "~")
		And File.GetHidden() Then
		
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Finish editing the File and place it on the server.
//
// Parameters:
//   Parameters - See FileUpdateParameters.
//
Procedure EndEdit(Parameters)
	
	Handler = New NotifyDescription("FinishEditAfterInstallExtension", ThisObject, Parameters);
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// 
Procedure FinishEditAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	ExecutionParameters.Insert("FileData", Undefined);
	
	If FileSystemExtensionAttached1() Then
		FinishEditWithExtension(ExecutionParameters);
	Else
		FinishEditWithoutExtension(ExecutionParameters);
	EndIf;
EndProcedure

// 
Procedure FinishEditWithExtension(ExecutionParameters)
	// 
	// 
	// 
	
	FileData = FilesOperationsInternalServerCall.FileDataAndWorkingDirectory(ExecutionParameters.ObjectRef);
	ExecutionParameters.FileData = FileData;
	
	// 
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		FileData.Ref,
		FileData.CurrentUserEditsFile,
		FileData.BeingEditedBy,
		ErrorText);
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("FullFilePath", ExecutionParameters.PassedFullFilePath);
	If ExecutionParameters.FullFilePath = "" Then
		ExecutionParameters.FullFilePath = FileData.FullFileNameInWorkingDirectory;
	EndIf;
	
	// 
	ExecutionParameters.Insert("NewVersionFile", New File(ExecutionParameters.FullFilePath));
	
	If Not ValueIsFilled(ExecutionParameters.FullFilePath)
	 Or Not ExecutionParameters.NewVersionFile.Exists() Then
		
		If ExecutionParameters.ApplyToAll = False Then
			If Not IsBlankString(ExecutionParameters.FullFilePath) Then
				WarningString = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Cannot store file
					           |""%1"" (%2)
					           |to the application as it does not exist in the working directory.
					           |
					           |Do you want to release the file?';"),
					String(FileData.Ref),
					ExecutionParameters.FullFilePath);
			Else
				WarningString = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Cannot store file ""%1""
					           |to the application as it does not exist in the working directory.
					           |
					           |Do you want to release the file?';"),
					String(FileData.Ref));
			EndIf;
			
			Handler = New NotifyDescription("FinishEditWithExtensionAfterRespondQuestionUnlockFile", ThisObject, ExecutionParameters);
			ShowQueryBox(Handler, WarningString, QuestionDialogMode.YesNo);
		Else
			FinishEditWithExtensionAfterRespondQuestionUnlockFile(-1, ExecutionParameters)
		EndIf;
		
		Return;
	EndIf;
	
	Try
		ReadOnly = ExecutionParameters.NewVersionFile.GetReadOnly();
		ExecutionParameters.NewVersionFile.SetReadOnly(Not ReadOnly);
		ExecutionParameters.NewVersionFile.SetReadOnly(ReadOnly);
	Except
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot store file ""%1"" to the working directory.
				|Probably, the directory is in use by another app.';"),
			String(FileData.Ref));
		Raise ErrorText + Chars.LF + Chars.LF + ErrorProcessing.DetailErrorDescription(ErrorInfo());
	EndTry;
	
	// 
	If ExecutionParameters.CreateNewVersion = Undefined Then
		
		ExecutionParameters.CreateNewVersion = FileData.StoreVersions;
		If FileData.StoreVersions Then
			// 
			// 
			CreateNewVersionAvailability = FileData.CurrentVersionAuthor = FileData.BeingEditedBy;
			
			ReturnFile = New Structure;
			ReturnFile.Insert("FileRef", FileData.Ref);
			ReturnFile.Insert("VersionComment", "");
			ReturnFile.Insert("CreateNewVersion", ExecutionParameters.CreateNewVersion);
			ReturnFile.Insert("CreateNewVersionAvailability", CreateNewVersionAvailability);
			
			Handler = New NotifyDescription("CompleteEditingWithExtensionAfterPutFileOnServer", ThisObject, ExecutionParameters);
			OpenForm("DataProcessor.FilesOperations.Form.SaveFileToInfobaseForm", ReturnFile, , , , , Handler);
			
		Else
			FinishEditWithExtensionAfterCheckNewVersion(ExecutionParameters);
		EndIf;
		
	Else // 
		
		If FileData.StoreVersions Then
			
			// 
			// 
			If FileData.CurrentVersionAuthor <> FileData.BeingEditedBy Then
				ExecutionParameters.CreateNewVersion = True;
			EndIf;
			
		Else
			ExecutionParameters.CreateNewVersion = False;
		EndIf;
		
		FinishEditWithExtensionAfterCheckNewVersion(ExecutionParameters);
	EndIf;
	
EndProcedure

// 
Procedure FinishEditWithExtensionAfterRespondQuestionUnlockFile(Response, ExecutionParameters) Export
	If Response <> -1 Then
		If Response = DialogReturnCode.Yes Then
			ExecutionParameters.UnlockFiles1 = True;
		Else
			ExecutionParameters.UnlockFiles1 = False;
		EndIf;
	EndIf;
	
	If ExecutionParameters.UnlockFiles1 Then
		UnlockFileWithoutQuestion(ExecutionParameters.FileData, ExecutionParameters.FormIdentifier);
		ReturnResult(ExecutionParameters.ResultHandler, True);
	Else
		ReturnResult(ExecutionParameters.ResultHandler, False);
	EndIf;
EndProcedure

// 
Procedure CompleteEditingWithExtensionAfterPutFileOnServer(Result, ExecutionParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If Result.ReturnCode <> DialogReturnCode.OK Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.CreateNewVersion = Result.CreateNewVersion;
	ExecutionParameters.VersionComment = Result.VersionComment;
	
	FinishEditWithExtensionAfterCheckNewVersion(ExecutionParameters);
	
EndProcedure

// 
Procedure FinishEditWithExtensionAfterCheckNewVersion(ExecutionParameters)
	
	If Not ExecutionParameters.FileData.Encrypted Then
		FinishEditWithExtensionAfterCheckEncrypted(ExecutionParameters);
		Return;
	EndIf;
	
	// 
	
	EncryptFileBeforePutFileInFileStorage(ExecutionParameters);
	
EndProcedure

// 
Procedure FinishEditWithExtensionAfterCheckEncrypted(ExecutionParameters)
	
	FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion", ExecutionParameters.NewVersionFile);
	FileInfo1.Comment = ExecutionParameters.VersionComment;
	FileInfo1.StoreVersions = ExecutionParameters.CreateNewVersion;
	
	If ExecutionParameters.Property("AddressAfterEncryption") Then
		FileInfo1.TempFileStorageAddress = ExecutionParameters.AddressAfterEncryption;
	Else
		Files = New Array;
		LongDesc = New TransferableFileDescription(ExecutionParameters.FullFilePath, "");
		Files.Add(LongDesc);
		
		PlacedFiles = New Array;
		Try
			FilesPut = PutFiles(Files, PlacedFiles,, False, ExecutionParameters.FormIdentifier);
		Except
			ErrorInfo = ErrorInfo();
			
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot store the file to the application. Reason:
				|""%1""
				|
				|Do you want to retry?';"),
				ErrorProcessing.BriefErrorDescription(ErrorInfo));
			
			Notification  = New NotifyDescription("FinishEditWithExtensionAfterCheckEncryptedRepeat", ThisObject, ExecutionParameters);
			ShowQueryBox(Notification, QueryText, QuestionDialogMode.RetryCancel);
			Return;
		EndTry;
		
		If Not FilesPut Then
			ReturnResult(ExecutionParameters.ResultHandler, False);
			Return;
		EndIf;
		
		If PlacedFiles.Count() = 1 Then
			FileInfo1.TempFileStorageAddress = PlacedFiles[0].Location;
		EndIf;
	EndIf;
	
	CommonFilesOperationsSettings = CommonFilesOperationsSettings();
	If Not CommonFilesOperationsSettings.ExtractTextFilesOnServer Then
		Try
			FileInfo1.TempTextStorageAddress = ExtractTextToTempStorage(ExecutionParameters.FullFilePath,
				ExecutionParameters.FormIdentifier,, ExecutionParameters.Encoding);
		Except
			FinishEditWithExtensionExceptionProcessing(ErrorInfo(), ExecutionParameters);
			Return;
		EndTry;
	EndIf;
	
	DontChangeRecordInWorkingDirectory = False;
	If ExecutionParameters.PassedFullFilePath <> "" Then
		DontChangeRecordInWorkingDirectory = True;
	EndIf;
	
	Try
		VersionUpdated = FilesOperationsInternalServerCall.SaveChangesAndUnlockFile(ExecutionParameters.FileData, FileInfo1, 
			DontChangeRecordInWorkingDirectory, ExecutionParameters.FullFilePath, UserWorkingDirectory(), 
			ExecutionParameters.FormIdentifier);
	Except
		FinishEditWithExtensionExceptionProcessing(ErrorInfo(), ExecutionParameters);
		Return;
	EndTry;
	
	ChangeLockedFilesCount();
	
	ExecutionParameters.Insert("VersionUpdated", VersionUpdated);
	NewVersion = ExecutionParameters.FileData.CurrentVersion;
	
	If ExecutionParameters.PassedFullFilePath = "" Then
		
		PersonalFilesOperationsSettings = PersonalFilesOperationsSettings();
		DeleteFileFromLocalFileCacheOnCompleteEdit = PersonalFilesOperationsSettings.DeleteFileFromLocalFileCacheOnCompleteEdit;
		If ExecutionParameters.FileData.OwnerWorkingDirectory <> "" Then
			DeleteFileFromLocalFileCacheOnCompleteEdit = False;
		EndIf;
		
		If DeleteFileFromLocalFileCacheOnCompleteEdit Then
			Handler = New NotifyDescription("FinishEditWithExtensionAfterDeleteFileFromWorkingDirectory", ThisObject, ExecutionParameters);
			DeleteFileFromWorkingDirectory(Handler, NewVersion, DeleteFileFromLocalFileCacheOnCompleteEdit);
			Return;
		Else
			File = New File(ExecutionParameters.FullFilePath);
			File.SetReadOnly(True);
		EndIf;
	EndIf;
	
	FinishEditWithExtensionAfterDeleteFileFromWorkingDirectory(-1, ExecutionParameters);
	
EndProcedure

// 
//
Procedure FinishEditWithExtensionAfterCheckEncryptedRepeat(Result, Parameter) Export
	If Result = DialogReturnCode.Retry Then
		FinishEditWithExtensionAfterCheckEncrypted(Parameter);
	EndIf;
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure FinishEditWithExtensionAfterDeleteFileFromWorkingDirectory(Result, ExecutionParameters) Export
	
	If ExecutionParameters.ShouldShowUserNotification Then
		If ExecutionParameters.VersionUpdated Then
			NoteTemplate = NStr("en = 'File ""%1""
			                             |is updated and released.';");
		Else
			NoteTemplate = NStr("en = 'File ""%1""
			                             |is not modified and released.';");
		EndIf;
		
		ShowUserNotification(
			NStr("en = 'Editing completed';"),
			ExecutionParameters.FileData.URL,
			StringFunctionsClientServer.SubstituteParametersToString(
				NoteTemplate, String(ExecutionParameters.FileData.Ref)),
			PictureLib.DialogInformation);
		
		If Not ExecutionParameters.VersionUpdated Then
			Handler = New NotifyDescription("FinishEditWithExtensionAfterShowNotification", ThisObject, ExecutionParameters);
			ShowInformationFileWasNotModified(Handler);
			Return;
		EndIf;
	EndIf;
	
	FinishEditWithExtensionAfterShowNotification(-1, ExecutionParameters);
	
EndProcedure

// 
Procedure FinishEditWithExtensionAfterShowNotification(Result, ExecutionParameters) Export
	
	If TypeOf(Result) = Type("Structure") And Result.NeverAskAgain Then
		CommonServerCall.CommonSettingsStorageSave(
			"ApplicationSettings", "ShowFileNotModifiedFlag", False,,, True);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure FinishEditWithExtensionExceptionProcessing(ErrorInfo, ExecutionParameters)
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Cannot store the ""%1"" file
			|from the computer to the application. Reason:
			|%2.';"),
		String(ExecutionParameters.FileData.Ref),
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	EventLogClient.AddMessageForEventLog(EventLogEvent(),
		"Warning", MessageText,, True);
	QueryText = MessageText + Chars.LF + Chars.LF + NStr("en = 'Retry the operation?';");
	Handler = New NotifyDescription("FinishEditWithExtensionAfterRespondQuestionRepeat", 
		ThisObject, ExecutionParameters);
	ShowQueryBox(Handler, QueryText, QuestionDialogMode.RetryCancel);
	
EndProcedure

// 
Procedure FinishEditWithExtensionAfterRespondQuestionRepeat(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Cancel Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	FinishEditWithExtensionAfterCheckEncrypted(ExecutionParameters);
	
EndProcedure

// 
Procedure FinishEditWithoutExtension(ExecutionParameters)
	// 
	
	If ExecutionParameters.FileData = Undefined Then
		FileDataParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataParameters.GetBinaryDataRef = False;
		
		ExecutionParameters.FileData  = FilesOperationsInternalServerCall.FileData(ExecutionParameters.ObjectRef,,FileDataParameters);
		ExecutionParameters.StoreVersions                      = ExecutionParameters.FileData.StoreVersions;
		ExecutionParameters.CurrentUserEditsFile = ExecutionParameters.FileData.CurrentUserEditsFile;
		ExecutionParameters.BeingEditedBy                        = ExecutionParameters.FileData.BeingEditedBy;
		ExecutionParameters.CurrentVersionAuthor                 = ExecutionParameters.FileData.CurrentVersionAuthor;
		ExecutionParameters.Encoding                          = ExecutionParameters.FileData.CurrentVersionEncoding;
	EndIf;
	
	// 
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		ExecutionParameters.ObjectRef,
		ExecutionParameters.CurrentUserEditsFile,
		ExecutionParameters.BeingEditedBy,
		ErrorText);
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("FullFilePath", "");
	
	If ExecutionParameters.CreateNewVersion = Undefined Then
		
		ExecutionParameters.CreateNewVersion = True;
		CreateNewVersionAvailability = True;
		
		If ExecutionParameters.StoreVersions Then
			ExecutionParameters.CreateNewVersion = True;
			
			// 
			// 
			If ExecutionParameters.CurrentVersionAuthor <> ExecutionParameters.BeingEditedBy Then
				CreateNewVersionAvailability = False;
			Else
				CreateNewVersionAvailability = True;
			EndIf;
		Else
			ExecutionParameters.CreateNewVersion = False;
			CreateNewVersionAvailability = False;
		EndIf;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("FileRef",                    ExecutionParameters.ObjectRef);
		ParametersStructure.Insert("VersionComment",            "");
		ParametersStructure.Insert("CreateNewVersion",            ExecutionParameters.CreateNewVersion);
		ParametersStructure.Insert("CreateNewVersionAvailability", CreateNewVersionAvailability);
		
		Handler = New NotifyDescription("CompleteEditingWithoutExtensionAfterPutFileOnServer", ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SaveFileToInfobaseForm", ParametersStructure, , , , , Handler);
		
	Else // 
		
		If ExecutionParameters.StoreVersions Then
			
			// 
			// 
			If ExecutionParameters.CurrentVersionAuthor <> ExecutionParameters.BeingEditedBy Then
				ExecutionParameters.CreateNewVersion = True;
			EndIf;
			
		Else
			ExecutionParameters.CreateNewVersion = False;
		EndIf;
		
		FinishEditWithoutExtensionAfterCheckNewVersion(ExecutionParameters)
		
	EndIf;
	
EndProcedure

// 
Procedure CompleteEditingWithoutExtensionAfterPutFileOnServer(Result, ExecutionParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If Result.ReturnCode <> DialogReturnCode.OK Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.CreateNewVersion = Result.CreateNewVersion;
	ExecutionParameters.VersionComment = Result.VersionComment;
	
	FinishEditWithoutExtensionAfterCheckNewVersion(ExecutionParameters);
	
EndProcedure

// 
Procedure FinishEditWithoutExtensionAfterCheckNewVersion(ExecutionParameters)
	
	Handler = New NotifyDescription("FinishEditWithoutExtensionAfterReminder", ThisObject, ExecutionParameters);
	ShowReminderBeforePutFile(Handler);
	
EndProcedure

// 
Procedure FinishEditWithoutExtensionAfterReminder(Result, ExecutionParameters) Export
	
	If Result = DialogReturnCode.Cancel Or Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") And Result.Property("NeverAskAgain") And Result.NeverAskAgain Then
		CommonServerCall.CommonSettingsStorageSave(
			"ApplicationSettings", "ShowTooltipsOnEditFiles", False,,, True);
	EndIf;
	
	Handler = New NotifyDescription("FinishEditWithoutExtensionAfterImportFile", ThisObject, ExecutionParameters);
	BeginPutFile(Handler, , ExecutionParameters.FullFilePath, , ExecutionParameters.FormIdentifier);
	
EndProcedure

// 
Procedure FinishEditWithoutExtensionAfterImportFile(Put, Address, SelectedFileName, ExecutionParameters) Export
	
	If Not Put Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("ImportedFileAddress", Address);
	ExecutionParameters.Insert("SelectedFileName", SelectedFileName);
	
	If ExecutionParameters.FileData = Undefined Then
		FileDataParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataParameters.GetBinaryDataRef = False;
		FileData = FilesOperationsInternalServerCall.FileData(ExecutionParameters.ObjectRef,,FileDataParameters);
	Else
		FileData = ExecutionParameters.FileData;
	EndIf;
	If Not FileData.Encrypted Then
		FinishEditWithoutExtensionAfterEncryptFile(Null, ExecutionParameters);
		Return;
	EndIf;
	If CertificatesNotSpecified(FileData.EncryptionCertificatesArray) Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	// 
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",            NStr("en = 'Encrypt file';"));
	DataDetails.Insert("DataTitle",     NStr("en = 'File';"));
	DataDetails.Insert("Data",              Address);
	DataDetails.Insert("Presentation",       ExecutionParameters.ObjectRef);
	DataDetails.Insert("CertificatesSet",   ExecutionParameters.ObjectRef);
	DataDetails.Insert("NoConfirmation",    True);
	DataDetails.Insert("NotifyOnCompletion", False);
	
	FollowUpHandler = New NotifyDescription("FinishEditWithoutExtensionAfterEncryptFile",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Encrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure FinishEditWithoutExtensionAfterEncryptFile(DataDetails, ExecutionParameters) Export
	
	If DataDetails = Null Then
		Address = ExecutionParameters.ImportedFileAddress;
		
	ElsIf Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	Else
		If TypeOf(DataDetails.EncryptedData) = Type("BinaryData") Then
			Address = PutToTempStorage(DataDetails.EncryptedData,
				ExecutionParameters.FormIdentifier);
		Else
			Address = DataDetails.EncryptedData;
		EndIf;
	EndIf;
	
	FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion");
	
	FileInfo1.TempFileStorageAddress = Address;
	FileInfo1.Comment = ExecutionParameters.VersionComment;
	
	PathStructure = CommonClientServer.ParseFullFileName(ExecutionParameters.SelectedFileName);
	If Not IsBlankString(PathStructure.Extension) Then
		FileInfo1.ExtensionWithoutPoint = CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension);
		FileInfo1.BaseName = PathStructure.BaseName;
	EndIf;
	FileInfo1.StoreVersions = ExecutionParameters.CreateNewVersion;
	
	Try
		Result = FilesOperationsInternalServerCall.SaveChangesAndUnlockFileByRef(ExecutionParameters.ObjectRef,
			FileInfo1, ExecutionParameters.FullFilePath, UserWorkingDirectory(), 
			ExecutionParameters.FormIdentifier);
		ExecutionParameters.FileData = Result.FileData;
	Except
		FinishEditExceptionHandler(ErrorInfo(), ExecutionParameters);
		Return;
	EndTry;
	
	ChangeLockedFilesCount();
	
	If ExecutionParameters.ShouldShowUserNotification Then
		If Result.Success Then
			NoteTemplate = NStr("en = 'File ""%1""
			                             |is updated and released.';");
		Else
			NoteTemplate = NStr("en = 'File ""%1""
			                             |is not modified and released.';");
		EndIf;
		
		ShowUserNotification(
			NStr("en = 'Editing completed';"),
			ExecutionParameters.FileData.URL,
			StringFunctionsClientServer.SubstituteParametersToString(
				NoteTemplate, String(ExecutionParameters.FileData.Ref)),
			PictureLib.DialogInformation);
		
		If Not Result.Success Then
			Handler = New NotifyDescription("FinishEditWithoutExtensionAfterShowNotification", ThisObject, ExecutionParameters);
			ShowInformationFileWasNotModified(Handler);
			Return;
		EndIf;
	EndIf;
	
	FinishEditWithoutExtensionAfterShowNotification(-1, ExecutionParameters);
	
EndProcedure

// 
Procedure FinishEditWithoutExtensionAfterShowNotification(Result, ExecutionParameters) Export
	
	If TypeOf(Result) = Type("Structure") And Result.Property("NeverAskAgain") And Result.NeverAskAgain Then
		CommonServerCall.CommonSettingsStorageSave(
			"ApplicationSettings","ShowFileNotModifiedFlag", False,,, True);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

// 
Procedure FinishEditExceptionHandler(ErrorInfo, ExecutionParameters)
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Cannot store the ""%1"" file
		           |from the computer to the application. Reason:
		           |""%2"".
		           |
		           |Do you want to retry?';"),
		String(ExecutionParameters.ObjectRef),
		ErrorProcessing.BriefErrorDescription(ErrorInfo));
	
	Handler = New NotifyDescription("FinishEditWithoutExtensionAfterRespondQuestionRepeat", ThisObject, ExecutionParameters);
	ShowQueryBox(Handler, ErrorText, QuestionDialogMode.RetryCancel);
	
EndProcedure

// 
Procedure FinishEditWithoutExtensionAfterRespondQuestionRepeat(Response, ExecutionParameters) Export
	If Response = DialogReturnCode.Cancel Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
	Else
		FinishEditWithoutExtensionAfterCheckNewVersion(ExecutionParameters);
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//                       :
//    * Result               - Boolean -  True if the file is updated.
//    * AdditionalParameters - Arbitrary -  the value that was specified when creating the object
//                              Description of the announcement.
//  FileData        - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//  FormIdentifier - UUID -  unique form ID.
//
Procedure UpdateFromFileOnHardDrive(ResultHandler, FileData, FormIdentifier,
	FileAddingOptions = Undefined)
	
	If Not FileSystemExtensionAttached1() Then
		ReturnResult(ResultHandler, False);
		Return;
	EndIf;
		
	Dialog = New FileDialog(FileDialogMode.Open);
	
	If Not IsBlankString(FileData.OwnerWorkingDirectory) Then
		ChoicePath = FileData.OwnerWorkingDirectory;
	Else
		ChoicePath = CommonServerCall.CommonSettingsStorageLoad("ApplicationSettings", "FolderForUpdateFromFile");
	EndIf;
	
	If ChoicePath = Undefined Or ChoicePath = "" Then
		ChoicePath = MyDocumentsDirectory();
	EndIf;
	
	Dialog.Title                   = NStr("en = 'Select file';");
	Dialog.Preview     = False;
	Dialog.CheckFileExist = False;
	Dialog.Multiselect          = False;
	Dialog.Directory                     = ChoicePath;
	
	Dialog.FullFileName = CommonClientServer.GetNameWithExtension(
		FileData.FullVersionDescription, FileData.Extension);
	
	If FileAddingOptions <> Undefined
		And FileAddingOptions.Property("SelectionDialogFilter")
		And Not IsBlankString(FileAddingOptions.SelectionDialogFilter) Then
		
		Dialog.Filter = FileAddingOptions.SelectionDialogFilter;
		
	Else
		
		EncryptedFilesExtension = "";
		
		If CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
			
			If ModuleDigitalSignatureClient.UseEncryption() Then
				EncryptedFilesExtension =
					ModuleDigitalSignatureClient.PersonalSettings().EncryptedFilesExtension;
			EndIf;
		EndIf;
		
		If ValueIsFilled(EncryptedFilesExtension) Then
			Filter = NStr("en = 'File (*.%1)|*.%1|Encrypted file (*.%2)|*.%2';") + "|"
					+ StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'All files (%1)|%1';"), GetAllFilesMask());
			Dialog.Filter = StringFunctionsClientServer.SubstituteParametersToString(Filter, FileData.Extension, EncryptedFilesExtension);
		Else
			Filter = NStr("en = 'All files (%1)|%1';") + "|"
					+ StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'All files (%1)|%1';"), GetAllFilesMask());
			Dialog.Filter = StringFunctionsClientServer.SubstituteParametersToString(Filter, FileData.Extension);
		EndIf;
		
	EndIf;
	
	If Not Dialog.Choose() Then
		ReturnResult(ResultHandler, False);
		Return;
	EndIf;
	
	ChoicePathPrevious = ChoicePath;
	FileOnHardDrive = New File(Dialog.FullFileName);
	
	If FileAddingOptions <> Undefined
		And FileAddingOptions.Property("MaximumSize")
		And FileAddingOptions.MaximumSize > 0
		And FileOnHardDrive.Size() > FileAddingOptions.MaximumSize*1024*1024 Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The file size exceeds %1 MB.';"), FileAddingOptions.MaximumSize);
		ReturnResultAfterShowWarning(ResultHandler, ErrorText, False);
		Return;
		
	EndIf;
	
	ChoicePath = FileOnHardDrive.Path;
	If IsBlankString(FileData.OwnerWorkingDirectory) Then
		If ChoicePathPrevious <> ChoicePath Then
			CommonServerCall.CommonSettingsStorageSave("ApplicationSettings", "FolderForUpdateFromFile",  ChoicePath);
		EndIf;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData",          FileData);
	ExecutionParameters.Insert("FormIdentifier",   FormIdentifier);
	ExecutionParameters.Insert("DialogBoxFullFileName", Dialog.FullFileName);
	ExecutionParameters.Insert("CreateNewVersion",   Undefined);
	ExecutionParameters.Insert("VersionComment",   Undefined);
	
	ExecutionParameters.Insert("FileOnHardDrive", New File(ExecutionParameters.DialogBoxFullFileName));
	ExecutionParameters.Insert("FileNameAndExtensionOnHardDrive", ExecutionParameters.FileOnHardDrive.Name);
	ExecutionParameters.Insert("FileName", ExecutionParameters.FileOnHardDrive.BaseName);
	
	ExecutionParameters.Insert("ChangeTimeSelected",
		ExecutionParameters.FileOnHardDrive.GetModificationUniversalTime());
	
	ExecutionParameters.Insert("FileExtensionOnHardDrive",
		CommonClientServer.ExtensionWithoutPoint(ExecutionParameters.FileOnHardDrive.Extension));
	
	ExecutionParameters.Insert("EncryptedFilesExtension", EncryptedFilesExtension);
	
	ExecutionParameters.Insert("FileEncrypted", Lower(ExecutionParameters.FileExtensionOnHardDrive)
		= Lower(ExecutionParameters.EncryptedFilesExtension));
		
	CheckCanImportFile(FileOnHardDrive);
	If Not ExecutionParameters.FileEncrypted Then
		UpdateFromFileOnHardDriveFollowUp(ExecutionParameters);
		Return;
	EndIf;
	
	// 
	Position = StrFind(ExecutionParameters.FileNameAndExtensionOnHardDrive, ExecutionParameters.FileExtensionOnHardDrive);
	ExecutionParameters.FileNameAndExtensionOnHardDrive = Left(ExecutionParameters.FileNameAndExtensionOnHardDrive, Position - 2);
	
	// 
	ExecutionParameters.Insert("DialogBoxFullFileNamePrevious", ExecutionParameters.DialogBoxFullFileName);
	Position = StrFind(ExecutionParameters.DialogBoxFullFileName, ExecutionParameters.FileExtensionOnHardDrive);
	ExecutionParameters.DialogBoxFullFileName = Left(ExecutionParameters.DialogBoxFullFileName, Position - 2);
	
	TempFileNonEncrypted = New File(ExecutionParameters.DialogBoxFullFileName);
	
	ExecutionParameters.FileExtensionOnHardDrive = CommonClientServer.ExtensionWithoutPoint(
		TempFileNonEncrypted.Extension);
	
	// 
	
	Files = New Array;
	FileDetails = New TransferableFileDescription(ExecutionParameters.DialogBoxFullFileNamePrevious);
	Files.Add(FileDetails);
	
	BeginPuttingFiles(New NotifyDescription("UpdateFromFileOnHardDriveBeforeDecryption", ThisObject, ExecutionParameters),
		Files, , False, ExecutionParameters.FormIdentifier);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure UpdateFromFileOnHardDriveBeforeDecryption(Files, ExecutionParameters) Export
	
	If Not ValueIsFilled(Files) Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",              NStr("en = 'Decrypt file';"));
	DataDetails.Insert("DataTitle",       NStr("en = 'File';"));
	DataDetails.Insert("Data",                Files[0].Location);
	DataDetails.Insert("Presentation",         ExecutionParameters.FileData.Ref);
	DataDetails.Insert("EncryptionCertificates", New Array);
	DataDetails.Insert("NotifyOnCompletion",   False);
	
	FollowUpHandler = New NotifyDescription("UpdateFromFileOnHardDriveAfterDecryption",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// 
Procedure UpdateFromFileOnHardDriveAfterDecryption(DataDetails, ExecutionParameters) Export
	
	If Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If TypeOf(DataDetails.DecryptedData) = Type("BinaryData") Then
		FileAddress = PutToTempStorage(DataDetails.DecryptedData,
			ExecutionParameters.FormIdentifier);
	Else
		FileAddress = DataDetails.DecryptedData;
	EndIf;
	
	ExecutionParameters.Insert("FileAddress", FileAddress);
	
	TransmittedFiles = New Array;
	FileDetails = New TransferableFileDescription(ExecutionParameters.DialogBoxFullFileName, FileAddress);
	TransmittedFiles.Add(FileDetails);
	
	If Not GetFiles(TransmittedFiles, , , False) Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	SetModificationUniversalTime(ExecutionParameters.DialogBoxFullFileName, 
		ExecutionParameters.ChangeTimeSelected);
	
	ExecutionParameters.FileEncrypted = False;
	
	UpdateFromFileOnHardDriveFollowUp(ExecutionParameters);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure UpdateFromFileOnHardDriveFollowUp(ExecutionParameters)
	
	ExecutionParameters.FileData = FilesOperationsInternalServerCall.FileDataAndWorkingDirectory(ExecutionParameters.FileData.Ref);
	PreviousVersion = ExecutionParameters.FileData.Version;
	FileNameAndExtensionInInfobase = CommonClientServer.GetNameWithExtension(
		ExecutionParameters.FileData.FullVersionDescription, ExecutionParameters.FileData.Extension);
	CommonInternalClient.ShortenFileName(FileNameAndExtensionInInfobase);
	ExecutionParameters.Insert("FileDateInDatabase", ExecutionParameters.FileData.UniversalModificationDate);
	
	If ExecutionParameters.ChangeTimeSelected < ExecutionParameters.FileDateInDatabase Then // 
		
#If MobileClient Then
		QuestionTextTemplate = NStr("en = 'File ""%1"" to be imported from the device 
			|was modified earlier than the file in the application:
			|
			| the file to be imported was modified on %2,
			| the file in the application was modified on %3.
			|
			|Do you want to replace the file with the older version from the device?';");
#Else
		QuestionTextTemplate = NStr("en = 'File ""%1"" to be imported from the computer 
			|was modified earlier than the file in the application:
			|
			| the file to be imported was modified on %2,
			| the file in the application was modified on %3.
			|
			|Do you want to replace the file with the older version from the computer?';");
#EndIf
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(QuestionTextTemplate,
			String(ExecutionParameters.FileData.Ref),
			ToLocalTime(ExecutionParameters.ChangeTimeSelected),
			ToLocalTime(ExecutionParameters.FileDateInDatabase));
		
		NotifyDescription = New NotifyDescription("UpdateFromFileOnDiskOldVersion", ThisObject, ExecutionParameters);
		ShowQueryBox(NotifyDescription, QueryText, QuestionDialogMode.YesNo);
		Return;

	EndIf;
	
	// 
	InWorkingDirectoryForRead = True;
	InOwnerWorkingDirectory = False;
	FullFileName = "";
	FileInWorkingDirectory = FileInLocalFilesCache(Undefined, PreviousVersion,
		FullFileName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	
#If Not WebClient And Not MobileClient Then
	If ExecutionParameters.FileData.CurrentUserEditsFile And FileInWorkingDirectory Then
		// 
		Try
			SelectedFile = New File(FullFileName);
			ReadOnly = SelectedFile.GetReadOnly();
			SelectedFile.SetReadOnly(Not ReadOnly);
			SelectedFile.SetReadOnly(ReadOnly);
		Except
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'File ""%1"" is being edited.
					|Finish editing and try again.';"),
				FullFileName);
			ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, Undefined);
			Return;
		EndTry;
	EndIf;
#EndIf
		
	If FileInWorkingDirectory And ExecutionParameters.FileNameAndExtensionOnHardDrive <> FileNameAndExtensionInInfobase Then
		Handler = New NotifyDescription("UpdateFromFileOnHardDriveAfterDeleteFileFromWorkingDirectory", ThisObject, ExecutionParameters);
		DeleteFileFromWorkingDirectory(Handler, ExecutionParameters.FileData.CurrentVersion, True);
		Return;
	EndIf;
	
	UpdateFromFileOnHardDriveAfterDeleteFileFromWorkingDirectory(-1, ExecutionParameters);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure UpdateFromFileOnDiskOldVersion(Result, ExecutionParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.ChangeTimeSelected = ExecutionParameters.FileDateInDatabase;
	UpdateFromFileOnHardDriveFollowUp(ExecutionParameters);
		
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure UpdateFromFileOnHardDriveAfterDeleteFileFromWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result <> -1 Then
		If Result.Success <> True Then
			ReturnResult(ExecutionParameters.ResultHandler, False);
			Return;
		EndIf;
	EndIf;
	
	ExecutionParameters.Insert("CurrentUserEditsFile", 
		ExecutionParameters.FileData.CurrentUserEditsFile);
	If Not ExecutionParameters.FileData.CurrentUserEditsFile Then
		
		ErrorText = "";
		CanLockFile = FilesOperationsClientServer.WhetherPossibleLockFile(ExecutionParameters.FileData, ErrorText);
		If Not CanLockFile Then
			ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, Undefined);
			Return;
		EndIf;
		
		ErrorText = "";
		
		FileLockParameters = FilesOperationsInternalClientServer.FileLockParameters();
		FileLockParameters.UUID = ExecutionParameters.FormIdentifier;
		FileLockParameters.RaiseException1 = False;
		
		FileLocked1 = FilesOperationsInternalServerCall.LockFile(ExecutionParameters.FileData, ErrorText, 
			FileLockParameters);
		If Not FileLocked1 Then 
			ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, Undefined);
			Return;
		EndIf;
		
		ForReading = False;
		InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
		ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
		
	EndIf;
	
	NewFullFileName = "";
	ExecutionParameters.FileData.Insert("UpdatePathFromFileOnHardDrive", ExecutionParameters.DialogBoxFullFileName);
	ExecutionParameters.FileData.Extension = CommonClientServer.ExtensionWithoutPoint(
		ExecutionParameters.FileExtensionOnHardDrive);
	
	// 
	Handler = New NotifyDescription("UpdateFromFileOnHardDriveAfterGetFileToWorkingDirectory", ThisObject, 
		ExecutionParameters);
	GetVersionFileToWorkingDirectory(Handler, ExecutionParameters.FileData, NewFullFileName, 
		ExecutionParameters.FormIdentifier);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure UpdateFromFileOnHardDriveAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	// 
	If ExecutionParameters.FileEncrypted Then
		FilesOperationsInternalServerCall.CheckEncryptedFlag(ExecutionParameters.FileData.Ref, ExecutionParameters.FileEncrypted);
	EndIf;
	
	PassedFullFilePath = "";
	
	Handler = New NotifyDescription("UpdateFromFileOnHardDriveAfterFinishEdit", ThisObject, ExecutionParameters);
	If ExecutionParameters.CurrentUserEditsFile Then // 
		HandlerParameters = FileUpdateParameters(Handler, ExecutionParameters.FileData.Ref, ExecutionParameters.FormIdentifier);
		HandlerParameters.PassedFullFilePath = PassedFullFilePath;
		HandlerParameters.CreateNewVersion = ExecutionParameters.CreateNewVersion;
		HandlerParameters.VersionComment = ExecutionParameters.VersionComment;
		SaveFileChanges(HandlerParameters);
	Else
		HandlerParameters = FileUpdateParameters(Handler, ExecutionParameters.FileData.Ref, ExecutionParameters.FormIdentifier);
		HandlerParameters.StoreVersions = ExecutionParameters.FileData.StoreVersions;
		HandlerParameters.CurrentUserEditsFile = ExecutionParameters.FileData.CurrentUserEditsFile;
		HandlerParameters.BeingEditedBy = ExecutionParameters.FileData.BeingEditedBy;
		HandlerParameters.CurrentVersionAuthor = ExecutionParameters.FileData.CurrentVersionAuthor;
		HandlerParameters.PassedFullFilePath = PassedFullFilePath;
		HandlerParameters.CreateNewVersion = ExecutionParameters.CreateNewVersion;
		HandlerParameters.VersionComment = ExecutionParameters.VersionComment;
		EndEdit(HandlerParameters);
	EndIf;
	
EndProcedure

// 
Procedure UpdateFromFileOnHardDriveAfterFinishEdit(EditResult, ExecutionParameters) Export
	
	If ExecutionParameters.FileEncrypted Then
		DeleteFileWithoutConfirmation(ExecutionParameters.DialogBoxFullFileName);
	EndIf;
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Marks the file as busy for editing.

// 
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - :
//      * Result - Boolean -    True if the operation was completed successfully.
//      * AdditionalParameters - Arbitrary -  the value that was specified when creating the object
//                                Description of the announcement.
//  ObjectRef            - CatalogRef.Files -  file.
//  UUID - UUID -  unique form ID.
//
Procedure LockFileByRef(ResultHandler, ObjectRef, UUID = Undefined)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	HandlerParameters.Insert("UUID", UUID);
	
	Handler = New NotifyDescription("LockFileByRefAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// 
Procedure LockFileByRefAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FileData", Undefined);
	
	ErrorText = "";
	FileDataReceivedAndFileLocked = FilesOperationsInternalServerCall.GetFileDataAndLockFile(
		ExecutionParameters.ObjectRef, ExecutionParameters.FileData, ErrorText, ExecutionParameters.UUID);
		
	If Not FileDataReceivedAndFileLocked Then // 
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	If FileSystemExtensionAttached1() Then
		ForReading = False;
		InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
		ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
	EndIf;
	
	FileData = ExecutionParameters.FileData; // See FilesOperationsInternalServerCall.FileData
	ShowUserNotification(
		NStr("en = 'Edit file';"),
		ExecutionParameters.FileData.URL,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'File ""%1""
			           |is locked for editing.';"), String(FileData.Ref)),
		PictureLib.DialogInformation);
	
	ChangeLockedFilesCount(1);
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Marks files as occupied for editing.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  FilesArray - Array -  array of files.
//
Procedure LockFilesByRefs(ResultHandler, Val FilesArray)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("FilesArray", FilesArray);
	
	Handler = New NotifyDescription("LockFilesByRefsAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// 
Procedure LockFilesByRefsAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	// 
	FilesData = New Array;
	FilesOperationsInternalServerCall.GetDataForFilesArray(ExecutionParameters.FilesArray, FilesData);
	InArrayBoundary  = FilesData.UBound();
	
	For Indus = 0 To InArrayBoundary Do
		FileData = FilesData[InArrayBoundary - Indus];
		
		ErrorString = "";
		If Not FilesOperationsClientServer.WhetherPossibleLockFile(FileData, ErrorString)
		 Or ValueIsFilled(FileData.BeingEditedBy) Then // 
			
			FilesData.Delete(InArrayBoundary - Indus);
		EndIf;
	EndDo;
	
	// 
	LockedFilesCount = 0;
	
	For Each FileData In FilesData Do
		
		If Not FilesOperationsInternalServerCall.LockFile(FileData, "") Then 
			Continue;
		EndIf;
		
		If FileSystemExtensionAttached1() Then
			ForReading = False;
			InOwnerWorkingDirectory = FileData.OwnerWorkingDirectory <> "";
			ReregisterFileInWorkingDirectory(FileData, ForReading, InOwnerWorkingDirectory);
		EndIf;
		
		LockedFilesCount = LockedFilesCount + 1;
	EndDo;
	
	ShowUserNotification(
		NStr("en = 'Lock files';"),
		,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Files (%1 out of %2) are locked for editing.';"),
			LockedFilesCount,
			ExecutionParameters.FilesArray.Count()),
		PictureLib.DialogInformation);
	
	ChangeLockedFilesCount(FilesData.Count());
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Opens the file for editing.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  ObjectRef            - CatalogRef.Files -  file.
//  UUID - UUID -  the ID of the form.
//  OwnerWorkingDirectory - String -  the owner's working directory.
//
Procedure EditFileByRef(ResultHandler, ObjectRef,
	UUID = Undefined, OwnerWorkingDirectory = Undefined)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	HandlerParameters.Insert("UUID", UUID);
	HandlerParameters.Insert("OwnerWorkingDirectory", OwnerWorkingDirectory);
	
	Handler = New NotifyDescription("EditFileByRefAfterInstallExtension", ThisObject, HandlerParameters);
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// 
Procedure EditFileByRefAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FileData", Undefined);
	ExecutionParameters.Insert("ExtensionAttached", FileSystemExtensionAttached1());
	ExecutionParameters.Insert("FileIsAlreadyEditedByCurrentUser", False);
	
	Result = FilesOperationsInternalServerCall.BorrowFileToEdit(ExecutionParameters.ObjectRef,
		ExecutionParameters.UUID, ExecutionParameters.OwnerWorkingDirectory);
		
	ExecutionParameters.FileData = Result.FileData;
	ExecutionParameters.FileIsAlreadyEditedByCurrentUser = Result.FileIsAlreadyEditedByCurrentUser;
	If Not Result.DataReceived Then
		StandardProcessing = True;
		FilesOperationsClientOverridable.OnFileCaptureError(ExecutionParameters.FileData, StandardProcessing);
		
		If StandardProcessing Then
			// 
			ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, 
				Result.MessageText, False);
			Return;
		EndIf;
		
		ReturnResult(ExecutionParameters.ResultHandler, True);
		Return;
	EndIf;
	
	If Not ExecutionParameters.FileIsAlreadyEditedByCurrentUser Then
		ChangeLockedFilesCount(1);
	EndIf;
	
	If ExecutionParameters.ExtensionAttached Then
		ForReading = False;
		InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
		ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
	EndIf;
	
	FileData = ExecutionParameters.FileData; // See FilesOperationsInternalServerCall.FileData
	
	ShowUserNotification(NStr("en = 'Edit files';"),
		ExecutionParameters.FileData.URL,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'File ""%1""
			           |is locked for editing.';"), String(FileData.Ref)),
			PictureLib.DialogInformation);
	
	If ExecutionParameters.FileData.Version.IsEmpty() Then 
		ReturnResultAfterShowValue(ExecutionParameters.ResultHandler, FileData.Ref, True);
		Return;
	EndIf;
	
	If ExecutionParameters.ExtensionAttached Then
		Handler = New NotifyDescription("EditFileByRefWithExtensionAfterGetFileToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(Handler, ExecutionParameters.FileData, "",
			ExecutionParameters.UUID);
	Else
		FillTemporaryFormID(ExecutionParameters.UUID, ExecutionParameters);
		Handler = New NotifyDescription("EditFileByRefCompletion", ThisObject, ExecutionParameters);
		OpenFileWithoutExtension(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID);
	EndIf;
	
EndProcedure

// 
Procedure EditFileByRefWithExtensionAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result.FileReceived = True Then
		UUID = ?(ExecutionParameters.Property("UUID"),
			ExecutionParameters.UUID, Undefined);
		OpenFileWithApplication(ExecutionParameters.FileData, Result.FullFileName, UUID);
	EndIf;
	
	FileIsAlreadyEditedByCurrentUser = False;
	If Not ExecutionParameters.FileIsAlreadyEditedByCurrentUser Then
		FileIsAlreadyEditedByCurrentUser = True;
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, FileIsAlreadyEditedByCurrentUser);
	
EndProcedure

// 
Procedure EditFileByRefCompletion(Result, ExecutionParameters) Export
	
	ClearTemporaryFormID(ExecutionParameters);
	
	ReturnResult(ExecutionParameters.ResultHandler, Result = True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Opens the file for editing.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  FileData             - Structure
//  UUID - Unique form identifier.
//
Procedure EditFile(ResultHandler, FileData, UUID = Undefined) Export
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("FileData", FileData);
	HandlerParameters.Insert("UUID", UUID);
	
	Handler = New NotifyDescription("EditFileAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// 
Procedure EditFileAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ErrorText = "";
	CanLockFile = FilesOperationsClientServer.WhetherPossibleLockFile(
		ExecutionParameters.FileData,
		ErrorText);
	If Not CanLockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	// 
	If Not ValueIsFilled(ExecutionParameters.FileData.BeingEditedBy) Then
		Handler = New NotifyDescription("EditFileAfterLockFile", ThisObject, ExecutionParameters);
		LockFile(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID);
		Return;
	EndIf;
	
	EditFileAfterLockFile(-1, ExecutionParameters);
	
EndProcedure

// 
//
// Parameters:
//   FileData - See FilesOperationsInternalServerCall.FileDataToOpen
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataToOpen
//
Procedure EditFileAfterLockFile(FileData, ExecutionParameters) Export
	
	If FileData = Undefined Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If FileData <> -1 Then
		ExecutionParameters.FileData = FileData;
	EndIf;
	
	// 
	If ExecutionParameters.FileData.Version.IsEmpty() Then 
		ReturnResultAfterShowValue(
			ExecutionParameters.ResultHandler, ExecutionParameters.FileData.Ref, True);
		Return;
	EndIf;
	
	If FileSystemExtensionAttached1() Then
		Handler = New NotifyDescription(
			"EditFileWithExtensionAfterGetFileToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(
			Handler,
			ExecutionParameters.FileData,
			"",
			ExecutionParameters.UUID);
	Else
		FillTemporaryFormID(ExecutionParameters.UUID, ExecutionParameters);
		
		Handler = New NotifyDescription("EditFileWithoutExtensionCompletion", ThisObject, ExecutionParameters);
		OpenFileWithoutExtension(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID);
	EndIf;
	
EndProcedure

// 
Procedure EditFileWithExtensionAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result.FileReceived = True Then
		UUID = ?(ExecutionParameters.Property("UUID"),
			ExecutionParameters.UUID, Undefined);
		OpenFileWithApplication(ExecutionParameters.FileData, Result.FullFileName, UUID);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Result.FileReceived = True);
	
EndProcedure

// 
Procedure EditFileWithoutExtensionCompletion(Result, ExecutionParameters) Export
	
	ClearTemporaryFormID(ExecutionParameters);
	
	ReturnResult(ExecutionParameters.ResultHandler, Result = True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
//
// Parameters:
//   ExtensionInstalled - Boolean
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataToOpen
//
Procedure OpenFileVersionAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	If FileSystemExtensionAttached1() Then
		Handler = New NotifyDescription("OpenFileVersionAfterGetFileToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(
			Handler,
			ExecutionParameters.FileData,
			"",
			ExecutionParameters.UUID);
	Else
		Address = FilesOperationsInternalServerCall.GetURLToOpen(
			ExecutionParameters.FileData.Version, ExecutionParameters.UUID);
		
		FileName = CommonClientServer.GetNameWithExtension(
			ExecutionParameters.FileData.FullVersionDescription, ExecutionParameters.FileData.Extension);
		
		GetFile(Address, FileName, True);
		
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	EndIf;
	
EndProcedure

// 
Procedure OpenFileVersionAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result.FileReceived Then
		UUID = ?(ExecutionParameters.Property("UUID"),
			ExecutionParameters.UUID, Undefined);
		OpenFileWithApplication(ExecutionParameters.FileData, Result.FullFileName, UUID);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Releases the files without upgrading.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  FilesArray - Array -  array of files.
//
Procedure UnlockFilesByRefs(ResultHandler, Val FilesArray)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("FilesArray", FilesArray);
	
	Handler = New NotifyDescription("UnlockFilesByRefsAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// 
Procedure UnlockFilesByRefsAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	// 
	ExecutionParameters.Insert("FilesData", New Array);
	FilesOperationsInternalServerCall.GetDataForFilesArray(ExecutionParameters.FilesArray, ExecutionParameters.FilesData);
	InArrayBoundary = ExecutionParameters.FilesData.UBound();
	
	// 
	For Indus = 0 To InArrayBoundary Do
		
		FileData = ExecutionParameters.FilesData[InArrayBoundary - Indus]; // See FilesOperationsInternalServerCall.FileData
		
		ErrorText = "";
		CanUnlockFile = AbilityToUnlockFile(
			FileData.Ref,
			FileData.CurrentUserEditsFile,
			FileData.BeingEditedBy,
			ErrorText);
		If Not CanUnlockFile Then
			ExecutionParameters.FilesData.Delete(InArrayBoundary - Indus);
		EndIf;
		
	EndDo;
	
	If Not FileSystemExtensionAttached1() Then
		Return;
	EndIf;
	
	Handler = New NotifyDescription("UnlockFilesByRefsAfterRespondQuestionCancelEdit", ThisObject, ExecutionParameters);
	
	ShowQueryBox(
		Handler,
		NStr("en = 'If you cancel editing,
		           |you will lose the changes.
		           |
		           |Do you want to continue?';"),
		QuestionDialogMode.YesNo,
		,
		DialogReturnCode.No);
	
EndProcedure

// 
//
// Parameters:
//   Response - DialogReturnCode
//         - Undefined
//   ExecutionParameters - Structure:
//     * FilesData - Array of See FilesOperations.FileData
//
Procedure UnlockFilesByRefsAfterRespondQuestionCancelEdit(Response, ExecutionParameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	// 
	For Each FileData In ExecutionParameters.FilesData Do
		
		Parameters = FileUnlockParameters(Undefined, FileData.Ref);
		Parameters.StoreVersions = FileData.StoreVersions;
		Parameters.CurrentUserEditsFile = FileData.CurrentUserEditsFile;
		Parameters.BeingEditedBy = FileData.BeingEditedBy;
		Parameters.DontAskQuestion = True;
		UnlockFile(Parameters);
		
	EndDo;
	
	ShowUserNotification(
		NStr("en = 'Cancel file editing';"),,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'File editing canceled (%1 out of %2).';"),
			ExecutionParameters.FilesData.Count(),
			ExecutionParameters.FilesArray.Count()),
		PictureLib.DialogInformation);
	
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Returns:
//   Structure:
//    * ResultHandler    - NotifyDescription
//                              - Undefined - 
//                                
//    * ObjectRef            - CatalogRef.Files -  file.
//    * Version                  - CatalogRef.FilesVersions -  file version.
//    * StoreVersions           - Boolean -  store versions.
//    * EditedByCurrentUser - Boolean -  the file is edited by the current user.
//    * BeingEditedBy             - CatalogRef.Users -  who took the file.
//    * UUID - UUID -  ID of the managed form.
//    * DontAskQuestion        - Boolean -  do not ask the question " Canceling file editing
//                                         may cause you to lose your changes. Continue?".
//
Function FileUnlockParameters(ResultHandler, ObjectRef) Export
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	HandlerParameters.Insert("Version");
	HandlerParameters.Insert("StoreVersions");
	HandlerParameters.Insert("CurrentUserEditsFile");
	HandlerParameters.Insert("BeingEditedBy");
	HandlerParameters.Insert("UUID");
	HandlerParameters.Insert("DontAskQuestion", False);
	Return HandlerParameters;
	
EndFunction	

// Releases the file without updating it.
//
// Parameters:
//  FileUnlockParameters - See FileUnlockParameters.
//
Procedure UnlockFile(FileUnlockParameters)
	
	Handler = New NotifyDescription("UnlockFileAfterInstallExtension", ThisObject, FileUnlockParameters);
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// 
Procedure UnlockFileAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FileData", Undefined);
	ExecutionParameters.Insert("ContinueWork", True);
	
	If ExecutionParameters.StoreVersions = Undefined Then
		FileDataParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataParameters.GetBinaryDataRef = False;
		
		FileData = FilesOperationsInternalServerCall.FileData(
			?(ExecutionParameters.ObjectRef <> Undefined, ExecutionParameters.ObjectRef, ExecutionParameters.Version),,FileDataParameters);
		
		If Not ValueIsFilled(ExecutionParameters.ObjectRef) Then
			ExecutionParameters.ObjectRef = FileData.Ref;
		EndIf;
		ExecutionParameters.StoreVersions                      = FileData.StoreVersions;
		ExecutionParameters.CurrentUserEditsFile = FileData.CurrentUserEditsFile;
		ExecutionParameters.BeingEditedBy                        = FileData.BeingEditedBy;
		
		ExecutionParameters.FileData = FileData;
		
	EndIf;
	
	// 
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		ExecutionParameters.ObjectRef,
		ExecutionParameters.CurrentUserEditsFile,
		ExecutionParameters.BeingEditedBy,
		ErrorText);
	
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	If ExecutionParameters.DontAskQuestion = False Then
		ExecutionParameters.ResultHandler = CompletionHandler(ExecutionParameters.ResultHandler);
		Handler = New NotifyDescription("UnlockFileAfterRespondQuestionCancelEdit", ThisObject, ExecutionParameters);
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'If you cancel editing file
			           |""%1"",
			           |you might lose the changes.
			           |
			           |Do you want to continue?';"),
			String(ExecutionParameters.ObjectRef));
		ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No);
		Return;
	EndIf;
	
	UnlockFileAfterRespondQuestionCancelEdit(-1, ExecutionParameters);
	
EndProcedure

// 
Procedure UnlockFileAfterRespondQuestionCancelEdit(Response, ExecutionParameters) Export
	
	If Response <> -1 Then
		If Response = DialogReturnCode.Yes Then
			ExecutionParameters.ContinueWork = True;
		Else
			ExecutionParameters.ContinueWork = False;
		EndIf;
	EndIf;
	
	If ExecutionParameters.ContinueWork Then
		
		FilesOperationsInternalServerCall.GetFileDataAndUnlockFile(ExecutionParameters.ObjectRef,
			ExecutionParameters.FileData, ExecutionParameters.UUID);
		NotifyChanged(TypeOf(ExecutionParameters.ObjectRef));
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), ExecutionParameters.ObjectRef);
		
		If FileSystemExtensionAttached1() Then
			ForReading = True;
			InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
			ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
		EndIf;
		
		If Not ExecutionParameters.DontAskQuestion Then
			ShowUserNotification(
				NStr("en = 'File released';"),
				ExecutionParameters.FileData.URL,
				ExecutionParameters.FileData.FullVersionDescription,
				PictureLib.DialogInformation);
		EndIf;
		
		ChangeLockedFilesCount();
		
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Start recording of the file changes.
//
// Parameters:
//   FileUpdateParameters - See FileUpdateParameters.
//
Procedure SaveFileChanges(FileUpdateParameters) 
	
	Handler = New NotifyDescription("SaveFileChangesAfterInstallExtensions", ThisObject, FileUpdateParameters);
	ShowFileSystemExtensionInstallationQuestion(Handler);
		
EndProcedure

// 
Procedure SaveFileChangesAfterInstallExtensions(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FileData", Undefined);
	ExecutionParameters.Insert("TempStorageAddress", Undefined);
	ExecutionParameters.Insert("FullFilePath", Undefined);
	
	If FileSystemExtensionAttached1() Then
		SaveFileChangesWithExtension(ExecutionParameters);
	Else
		SaveFileChangesWithoutExtension(ExecutionParameters);
	EndIf;
	
EndProcedure

// 
Procedure SaveFileChangesWithExtension(ExecutionParameters)
	// 
	
	FileData = FilesOperationsInternalServerCall.FileDataAndWorkingDirectory(ExecutionParameters.ObjectRef);
	ExecutionParameters.FileData = FileData;
	ExecutionParameters.StoreVersions = FileData.StoreVersions;
	
	// 
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		FileData.Ref,
		FileData.CurrentUserEditsFile,
		FileData.BeingEditedBy,
		ErrorText);
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	ExecutionParameters.FullFilePath = ExecutionParameters.PassedFullFilePath;
	If ExecutionParameters.FullFilePath = "" Then
		ExecutionParameters.FullFilePath = FileData.FullFileNameInWorkingDirectory;
	EndIf;
	
	// 
	ExecutionParameters.Insert("NewVersionFile", New File(ExecutionParameters.FullFilePath));
	If Not ExecutionParameters.NewVersionFile.Exists() Then
		If Not IsBlankString(ExecutionParameters.FullFilePath) Then
			WarningString = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot store
						   |the ""%1"" file
				           |to the application as it does not exist on the computer:
				           |%2.
				           |
				           |Do you want to release the file?';"),
				String(FileData.Ref),
				ExecutionParameters.FullFilePath);
		Else
			WarningString = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot store
						   |the ""%1"" file
				           |to the application as it does not exist on the computer:
				           |
				           |Do you want to release the file?';"),
				String(FileData.Ref));
		EndIf;
		
		Handler = New NotifyDescription("SaveFileChangesWithExtensionAfterRespondQuestionUnlockFile", ThisObject, ExecutionParameters);
		ShowQueryBox(Handler, WarningString, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	// 
	If ExecutionParameters.CreateNewVersion = Undefined Then
		
		ExecutionParameters.CreateNewVersion = True;
		CreateNewVersionAvailability = True;
		
		If FileData.StoreVersions Then
			ExecutionParameters.CreateNewVersion = True;
			
			// 
			// 
			If FileData.CurrentVersionAuthor <> FileData.BeingEditedBy Then
				CreateNewVersionAvailability = False;
			Else
				CreateNewVersionAvailability = True;
			EndIf;
		Else
			ExecutionParameters.CreateNewVersion = False;
			CreateNewVersionAvailability = False;
			SaveFileChangesWithExtensionAfterCheckNewVersion(ExecutionParameters);
			Return;
		EndIf;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("FileRef",                    FileData.Ref);
		ParametersStructure.Insert("VersionComment",            "");
		ParametersStructure.Insert("CreateNewVersion",            ExecutionParameters.CreateNewVersion);
		ParametersStructure.Insert("CreateNewVersionAvailability", CreateNewVersionAvailability);
		
		Handler = New NotifyDescription("SaveFileChangesWithExtensionAfterPutFileOnServer", ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SaveFileToInfobaseForm", ParametersStructure, , , , , Handler);
		
	Else // 
		
		If ExecutionParameters.StoreVersions Then
			
			// 
			// 
			If ExecutionParameters.CurrentVersionAuthor <> ExecutionParameters.BeingEditedBy Then
				ExecutionParameters.CreateNewVersion = True;
			EndIf;
			
		Else
			ExecutionParameters.CreateNewVersion = False;
		EndIf;
		
		SaveFileChangesWithExtensionAfterCheckNewVersion(ExecutionParameters);
		
	EndIf;
	
EndProcedure

// 
Procedure SaveFileChangesWithExtensionAfterRespondQuestionUnlockFile(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		UnlockFileWithoutQuestion(ExecutionParameters.FileData, ExecutionParameters.FormIdentifier);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, False);
	
EndProcedure

// 
Procedure SaveFileChangesWithExtensionAfterPutFileOnServer(Result, ExecutionParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ReturnCode = Result.ReturnCode;
	If ReturnCode <> DialogReturnCode.OK Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.CreateNewVersion = Result.CreateNewVersion;
	ExecutionParameters.VersionComment = Result.VersionComment;
	
	SaveFileChangesWithExtensionAfterCheckNewVersion(ExecutionParameters);
	
EndProcedure

// 
Procedure SaveFileChangesWithExtensionAfterCheckNewVersion(ExecutionParameters)
	
	If Not ExecutionParameters.FileData.Encrypted Then
		SaveFileChangesWithExtensionAfterCheckEncrypted(ExecutionParameters);
		Return;
	EndIf;
	
	// 
	
	EncryptFileBeforePutFileInFileStorage(ExecutionParameters);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure SaveFileChangesWithExtensionAfterCheckEncrypted(ExecutionParameters)
	
	FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion", ExecutionParameters.NewVersionFile);
	FileInfo1.Comment = ExecutionParameters.VersionComment;
	FileInfo1.StoreVersions = ExecutionParameters.CreateNewVersion;
	
	If ExecutionParameters.Property("AddressAfterEncryption") Then
		FileInfo1.TempFileStorageAddress = ExecutionParameters.AddressAfterEncryption;
	Else
		Files = New Array;
		LongDesc = New TransferableFileDescription(ExecutionParameters.FullFilePath, "");
		Files.Add(LongDesc);
		
		PlacedFiles = New Array;
		FilesPut = PutFiles(Files, PlacedFiles, , False, ExecutionParameters.FormIdentifier);
		
		If Not FilesPut Then
			ReturnResult(ExecutionParameters.ResultHandler, True);
			Return;
		EndIf;
		
		If PlacedFiles.Count() = 1 Then
			FileInfo1.TempFileStorageAddress = PlacedFiles[0].Location;
		EndIf;
	EndIf;
	
	CommonFilesOperationsSettings = CommonFilesOperationsSettings();
	DirectoryName = UserWorkingDirectory();
	
	RelativeFilePath = "";
	If ExecutionParameters.FileData.OwnerWorkingDirectory <> "" Then // 
		RelativeFilePath = ExecutionParameters.FullFilePath;
	Else
		Position = StrFind(ExecutionParameters.FullFilePath, DirectoryName);
		If Position <> 0 Then
			RelativeFilePath = Mid(ExecutionParameters.FullFilePath, StrLen(DirectoryName) + 1);
		EndIf;
	EndIf;
	
	If Not CommonFilesOperationsSettings.ExtractTextFilesOnServer Then
		FileInfo1.TempTextStorageAddress = ExtractTextToTempStorage(ExecutionParameters.FullFilePath,
			ExecutionParameters.FormIdentifier);
	Else
		FileInfo1.TempTextStorageAddress = "";
	EndIf;
	
	DontChangeRecordInWorkingDirectory = False;
	If ExecutionParameters.PassedFullFilePath <> "" Then
		DontChangeRecordInWorkingDirectory = True;
	EndIf;
	
	VersionUpdated = FilesOperationsInternalServerCall.SaveFileChanges(ExecutionParameters.FileData.Ref, FileInfo1, 
		DontChangeRecordInWorkingDirectory, RelativeFilePath, ExecutionParameters.FullFilePath, 
		ExecutionParameters.FileData.OwnerWorkingDirectory <> "", ExecutionParameters.FormIdentifier);
	If ExecutionParameters.ShouldShowUserNotification Then
		If VersionUpdated Then
			ShowUserNotification(
				NStr("en = 'New version saved';"),
				ExecutionParameters.FileData.URL,
				ExecutionParameters.FileData.FullVersionDescription,
				PictureLib.DialogInformation);
		Else
			ShowUserNotification(
				NStr("en = 'New version not saved';"),,
				NStr("en = 'The file is not changed.';"),
				PictureLib.DialogInformation);
			Handler = New NotifyDescription("SaveFileChangesWithExtensionAfterShowNotification", ThisObject, ExecutionParameters);
			ShowInformationFileWasNotModified(Handler);
			Return;
		EndIf;
	EndIf;
	
	SaveFileChangesWithExtensionAfterShowNotification(-1, ExecutionParameters);
	
EndProcedure

// 
Procedure SaveFileChangesWithExtensionAfterShowNotification(Result, ExecutionParameters) Export
	
	If  TypeOf(Result) = Type("Structure") And Result.Property("NeverAskAgain") And Result.NeverAskAgain Then
		CommonServerCall.CommonSettingsStorageSave(
			"ApplicationSettings","ShowFileNotModifiedFlag", False,,, True);
		RefreshReusableValues();
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

// 
Procedure SaveFileChangesWithoutExtension(ExecutionParameters)
	
	If ExecutionParameters.StoreVersions = Undefined Then
		FileDataParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataParameters.GetBinaryDataRef = False;
		
		ExecutionParameters.FileData = FilesOperationsInternalServerCall.FileData(ExecutionParameters.ObjectRef,,FileDataParameters);
		ExecutionParameters.StoreVersions                      = ExecutionParameters.FileData.StoreVersions;
		ExecutionParameters.CurrentUserEditsFile = ExecutionParameters.FileData.CurrentUserEditsFile;
		ExecutionParameters.BeingEditedBy                        = ExecutionParameters.FileData.BeingEditedBy;
		ExecutionParameters.CurrentVersionAuthor                 = ExecutionParameters.FileData.CurrentVersionAuthor;
	EndIf;
	
	// 
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		ExecutionParameters.ObjectRef,
		ExecutionParameters.CurrentUserEditsFile,
		ExecutionParameters.BeingEditedBy,
		ErrorText);
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, False);
		Return;
	EndIf;
	
	ExecutionParameters.FullFilePath = "";
	If ExecutionParameters.CreateNewVersion = Undefined Then
		
		// 
		ExecutionParameters.CreateNewVersion = True;
		CreateNewVersionAvailability = True;
		
		If ExecutionParameters.StoreVersions Then
			ExecutionParameters.CreateNewVersion = True;
			
			// 
			// 
			If ExecutionParameters.CurrentVersionAuthor <> ExecutionParameters.BeingEditedBy Then
				CreateNewVersionAvailability = False;
			Else
				CreateNewVersionAvailability = True;
			EndIf;
		Else
			ExecutionParameters.CreateNewVersion = False;
			CreateNewVersionAvailability = False;
		EndIf;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("FileRef",                    ExecutionParameters.ObjectRef);
		ParametersStructure.Insert("VersionComment",            "");
		ParametersStructure.Insert("CreateNewVersion",            ExecutionParameters.CreateNewVersion);
		ParametersStructure.Insert("CreateNewVersionAvailability", CreateNewVersionAvailability);
		
		Handler = New NotifyDescription("SaveFileChangesWithoutExtensionAfterPutFileOnServer", ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SaveFileToInfobaseForm", ParametersStructure, , , , , Handler);
		
	Else // 
		
		If ExecutionParameters.StoreVersions Then
			
			// 
			// 
			If ExecutionParameters.CurrentVersionAuthor <> ExecutionParameters.BeingEditedBy Then
				ExecutionParameters.CreateNewVersion = True;
			EndIf;
			
		Else
			ExecutionParameters.CreateNewVersion = False;
		EndIf;
		
		SaveFileChangesWithoutExtensionAfterCheckNewVersion(ExecutionParameters);
		
	EndIf;
	
EndProcedure

// 
Procedure SaveFileChangesWithoutExtensionAfterPutFileOnServer(Result, ExecutionParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If Result.ReturnCode <> DialogReturnCode.OK Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.CreateNewVersion = Result.CreateNewVersion;
	ExecutionParameters.VersionComment = Result.VersionComment;
	
	SaveFileChangesWithoutExtensionAfterCheckNewVersion(ExecutionParameters);
	
EndProcedure

// 
Procedure SaveFileChangesWithoutExtensionAfterCheckNewVersion(ExecutionParameters)
	
	Handler = New NotifyDescription("SaveFileChangesWithoutExtensionAfterReminder", ThisObject, ExecutionParameters);
	ShowReminderBeforePutFile(Handler);
	
EndProcedure

// 
Procedure SaveFileChangesWithoutExtensionAfterReminder(Result, ExecutionParameters) Export
	
	If Result.Value = DialogReturnCode.OK Then
		
		If  TypeOf(Result) = Type("Structure") And Result.Property("NeverAskAgain") And Result.NeverAskAgain Then
			CommonServerCall.CommonSettingsStorageSave(
				"ApplicationSettings", "ShowTooltipsOnEditFiles", False,,, True);
		EndIf;
		Handler = New NotifyDescription("SaveFileChangesWithoutExtensionAfterImportFile", ThisObject, ExecutionParameters);
		BeginPutFile(Handler, , ExecutionParameters.FullFilePath, , ExecutionParameters.FormIdentifier);
		
	EndIf;
	
EndProcedure

// 
Procedure SaveFileChangesWithoutExtensionAfterImportFile(Put, Address, SelectedFileName, ExecutionParameters) Export
	
	If Not Put Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("ImportedFileAddress", Address);
	ExecutionParameters.Insert("SelectedFileName", SelectedFileName);
	
	If ExecutionParameters.FileData = Undefined Then
		FileDataParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataParameters.GetBinaryDataRef = False;
		FileData = FilesOperationsInternalServerCall.FileData(ExecutionParameters.ObjectRef,,FileDataParameters);
	Else
		FileData = ExecutionParameters.FileData;
	EndIf;
	If Not FileData.Encrypted Then
		SaveFileChangesWithoutExtensionAfterEncryptFile(Null, ExecutionParameters);
		Return;
	EndIf;
	If CertificatesNotSpecified(FileData.EncryptionCertificatesArray) Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	// 
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",            NStr("en = 'Encrypt file';"));
	DataDetails.Insert("DataTitle",     NStr("en = 'File';"));
	DataDetails.Insert("Data",              Address);
	DataDetails.Insert("Presentation",       ExecutionParameters.ObjectRef);
	DataDetails.Insert("CertificatesSet",   ExecutionParameters.ObjectRef);
	DataDetails.Insert("NoConfirmation",    True);
	DataDetails.Insert("NotifyOnCompletion", False);
	
	FollowUpHandler = New NotifyDescription("SaveFileChangesWithoutExtensionAfterEncryptFile",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Encrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// 
Procedure SaveFileChangesWithoutExtensionAfterEncryptFile(DataDetails, ExecutionParameters) Export
	
	If DataDetails = Null Then
		Address = ExecutionParameters.ImportedFileAddress;
		
	ElsIf Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	Else
		If TypeOf(DataDetails.EncryptedData) = Type("BinaryData") Then
			Address = PutToTempStorage(DataDetails.EncryptedData,
				ExecutionParameters.FormIdentifier);
		Else
			Address = DataDetails.EncryptedData;
		EndIf;
	EndIf;
	
	FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion");
	ExecutionParameters.TempStorageAddress = Address;
	FileInfo1.TempFileStorageAddress = Address;
	FileInfo1.StoreVersions = ExecutionParameters.CreateNewVersion;
	
	PathStructure = CommonClientServer.ParseFullFileName(ExecutionParameters.SelectedFileName);
	If Not IsBlankString(PathStructure.Extension) Then
		FileInfo1.ExtensionWithoutPoint = CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension);
		FileInfo1.BaseName = PathStructure.BaseName;
	EndIf;
	
	Result = FilesOperationsInternalServerCall.GetFileDataAndSaveFileChanges(ExecutionParameters.ObjectRef, FileInfo1, 
		"", ExecutionParameters.FullFilePath, False, ExecutionParameters.FormIdentifier);
	ExecutionParameters.FileData = Result.FileData;
	If ExecutionParameters.ShouldShowUserNotification Then
		ShowUserNotification(
			NStr("en = 'The new version is saved.';"),
			ExecutionParameters.FileData.URL,
			ExecutionParameters.FileData.FullVersionDescription,
			PictureLib.DialogInformation);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure


// For procedures save changes to the File, finish Editing.
Procedure EncryptFileBeforePutFileInFileStorage(ExecutionParameters)
	
	If CertificatesNotSpecified(ExecutionParameters.FileData.EncryptionCertificatesArray) Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	// 
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",            NStr("en = 'Encrypt file';"));
	DataDetails.Insert("DataTitle",     NStr("en = 'File';"));
	DataDetails.Insert("Data",              ExecutionParameters.FullFilePath);
	DataDetails.Insert("Presentation",       ExecutionParameters.ObjectRef);
	DataDetails.Insert("CertificatesSet",   ExecutionParameters.ObjectRef);
	DataDetails.Insert("NoConfirmation",    True);
	DataDetails.Insert("NotifyOnCompletion", False);
	
	FollowUpHandler = New NotifyDescription("EncryptFileBeforePutFileInFileStorageAfterFileEncryption",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Encrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// 
Procedure EncryptFileBeforePutFileInFileStorageAfterFileEncryption(DataDetails, ExecutionParameters) Export
	
	If DataDetails = Null Then
		Address = ExecutionParameters.ImportedFileAddress;
		
	ElsIf Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	Else
		If TypeOf(DataDetails.EncryptedData) = Type("BinaryData") Then
			Address = PutToTempStorage(DataDetails.EncryptedData,
				ExecutionParameters.FormIdentifier);
		Else
			Address = DataDetails.EncryptedData;
		EndIf;
	EndIf;
	
	ExecutionParameters.Insert("AddressAfterEncryption", Address);
	
	FinishEditWithExtensionAfterCheckEncrypted(ExecutionParameters);
	
EndProcedure

// For procedures save changes to the File, finish Editing.
Function CertificatesNotSpecified(CertificatesArray)
	
	If CertificatesArray.Count() = 0 Then
		ShowMessageBox(,
			NStr("en = 'Certificates of the encrypted file are not specified.
			           |Please decrypt the file and then encrypt it again.';"));
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Marks the file as busy for editing.

// Marks the file as busy for editing.
//
// Parameters:
//   ResultHandler - NotifyDescription
//                        - Undefined - 
//   FileData - Structure
//
Procedure LockFile(ResultHandler, FileData, UUID)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler",    ResultHandler);
	HandlerParameters.Insert("FileData",             FileData);
	HandlerParameters.Insert("UUID", UUID);
	
	Handler = New NotifyDescription("LockFileAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// 
//
// Parameters:
//   ExtensionInstalled - Boolean
//   ExecutionParameters   - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure LockFileAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ErrorText = "";
	CanLockFile = FilesOperationsClientServer.WhetherPossibleLockFile(
		ExecutionParameters.FileData,
		ErrorText);
	If Not CanLockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, Undefined);
		Return;
	EndIf;
	
	ErrorText = "";
	
	FileLockParameters = FilesOperationsInternalClientServer.FileLockParameters();
	FileLockParameters.UUID = ExecutionParameters.UUID;
	
	FileLocked1 = FilesOperationsInternalServerCall.LockFile(ExecutionParameters.FileData,
		ErrorText, FileLockParameters);
	
	If Not FileLocked1 Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, ErrorText, Undefined);
		Return;
	EndIf;
	
	If FileSystemExtensionAttached1() Then
		ForReading = False;
		InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
		ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
	EndIf;
	
	ShowUserNotification(
		NStr("en = 'Edit files';"),
		ExecutionParameters.FileData.URL,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'File ""%1""
			           |is locked for editing.';"),
			String(ExecutionParameters.FileData.Ref)),
		PictureLib.DialogInformation);
	
	ChangeLockedFilesCount(1);
	
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters.FileData);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Continuation of the attached file Client procedure.Add files.
Procedure AddFilesCompletion(AttachedFile, AdditionalParameters) Export
	
	If AttachedFile = Undefined Then
		Return;
	EndIf;
	
	FileOwner = AdditionalParameters.FileOwner;
	NotifyChanged(AttachedFile);
	NotifyChanged(FileOwner);
	
	NotificationParameters = FileWriteNotificationParameters();
	NotificationParameters.Owner = FileOwner;
	NotificationParameters.FileOwner = NotificationParameters.Owner;
	NotificationParameters.File = AttachedFile;
	NotificationParameters.IsNew = True;
	Notify("Write_File", NotificationParameters, AttachedFile);
	
	If AdditionalParameters.Property("ResultHandler")
		And AdditionalParameters.ResultHandler <> Undefined Then
		AttachedFilesArray = New Array;
		AttachedFilesArray.Add(AttachedFile);
		ExecuteNotifyProcessing(AdditionalParameters.ResultHandler, AttachedFilesArray);
	EndIf;
	
	OpenCardAfterCreateFromFile = False;
	If AdditionalParameters.Property("NotOpenCardAfterCreateFromFile") Then
		OpenCardAfterCreateFromFile = Not AdditionalParameters.NotOpenCardAfterCreateFromFile;
	EndIf;
	If OpenCardAfterCreateFromFile Then
		
		ShowUserNotification(
			NStr("en = 'Create';"),
			GetURL(AttachedFile),
			AttachedFile,
			PictureLib.DialogInformation);
		FilesOperationsClient.OpenFileForm(AttachedFile);
			
	EndIf;
		
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

////////////////////////////////////////////////////////////////////////////////
// 

// Parameters:
//  FullFileName - String
//
Procedure DeleteFileWithoutConfirmation(FullFileName)
	
	File = New File(FullFileName);
	If File.Exists() Then
		Try
			File.SetReadOnly(False);
			DeleteFiles(FullFileName);
		Except
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot delete the file in the working directory:
					|""%1"".
					|It might be locked by another application.
					|
					|%2';"),
				FullFileName, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", MessageText,, True);
		EndTry;	
	EndIf;
	
EndProcedure

// Deleting a file with the readonly attribute removed.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Structure
//                       - Undefined - 
//                         
//  FullFileName - String -    full file name.
//  Ask a question-Boolean-ask a question about deletion.
//  Question header - the question header Line-adds text to the deletion question.
//
Procedure DeleteFile(Val ResultHandler, FullFileName)
	
	DeleteFileWithoutConfirmation(FullFileName);
	ReturnResult(ResultHandler, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Retrieves a File from the file store to the working directory
// and returns the path to this file.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  FileData        - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//  Fullfile name-String.
//  ForReading           - Boolean -  False for reading, True for editing.
//  FormIdentifier - UUID -  the ID of the form.
//
Procedure GetVersionFileToLocalFilesCache(ResultHandler, FileData, ForReading,
	FormIdentifier, AdditionalParameters)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("ForReading", ForReading);
	ExecutionParameters.Insert("FormIdentifier", FormIdentifier);
	ExecutionParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	ExecutionParameters.Insert("FullFileName", "");
	ExecutionParameters.Insert("FileReceived", False);	
	InWorkingDirectoryForRead = True;
	InOwnerWorkingDirectory = False;
	
	FileInWorkingDirectory = FileInLocalFilesCache(FileData,
		FileData.Version, ExecutionParameters.FullFileName,
		InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	If Not FileInWorkingDirectory Then
		GetFromServerAndRegisterInLocalFilesCache(ExecutionParameters);
		Return;
	EndIf;

	// 
	If ExecutionParameters.FullFileName = "" Then
		CommonClient.MessageToUser(
			NStr("en = 'Cannot get the file from the application to the working directory.';"));
		ReturnResult(ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	// 
	// 
	Handler = New NotifyDescription("GetVersionFileToLocalFilesCacheAfterActionChoice", 
		ThisObject, ExecutionParameters);
	ActionOnOpenFileInWorkingDirectory(Handler, ExecutionParameters.FullFileName, FileData);
	
EndProcedure

// 
Procedure GetVersionFileToLocalFilesCacheAfterActionChoice(Result, ExecutionParameters) Export
	
	If Result = "GetFromStorageAndOpen" Then
		
		Handler = New NotifyDescription("GetVersionFileToLocalFilesCacheAfterDelete", ThisObject, ExecutionParameters);
		DeleteFile(Handler, ExecutionParameters.FullFileName);
		
	ElsIf Result = "OpenExistingFile" Then
		
		If ExecutionParameters.FileData.InWorkingDirectoryForRead <> ExecutionParameters.ForReading Then
			InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
			
			RegegisterInWorkingDirectory(
				ExecutionParameters.FileData.Version,
				ExecutionParameters.FullFileName,
				ExecutionParameters.ForReading,
				InOwnerWorkingDirectory);
		EndIf;
		
		ExecutionParameters.FileReceived = True;
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		
	Else // 
		ExecutionParameters.FullFileName = "";
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	EndIf;
	
EndProcedure

// 
//
Procedure GetVersionFileToLocalFilesCacheAfterDelete(FileDeleted, ExecutionParameters) Export
	
	GetFromServerAndRegisterInLocalFilesCache(ExecutionParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  FileData  - Structure
//  FullFileName - String -  the full file name is returned here.
//  FormIdentifier - UUID -  the ID of the form.
//
Procedure GetVersionFileToWorkingDirectory(ResultHandler, FileData, FullFileName,
	FormIdentifier = Undefined, AdditionalParameters = Undefined) Export
	
	DirectoryName = UserWorkingDirectory();	
	If DirectoryName = Undefined Or IsBlankString(DirectoryName) Then
		ReturnResult(ResultHandler, New Structure("FileReceived, FullFileName", False, FullFileName));
		Return;
	EndIf;
	
	If FileData.OwnerWorkingDirectory = "" 
		Or FileData.Version <> FileData.CurrentVersion And ValueIsFilled(FileData.CurrentVersion) Then
		GetVersionFileToLocalFilesCache(ResultHandler, FileData, FileData.ForReading,
			FormIdentifier, AdditionalParameters);
	Else
		
		If Not CanAccessWorkingDirectory(FileData.OwnerWorkingDirectory, FileData.Owner) Then
			GetVersionFileToLocalFilesCache(ResultHandler, FileData, FileData.ForReading,
			FormIdentifier, AdditionalParameters);
			Return;
		EndIf;
			
		GetVersionFileToFolderWorkingDirectory(ResultHandler, FileData, FullFileName, FileData.ForReading,
			FormIdentifier, AdditionalParameters);
	EndIf;
	
EndProcedure

Function CanAccessWorkingDirectory(OwnerWorkingDirectory, Owner)
	Result = False;
	// 
	Try
		// 
		// 
		InformationAboutTheCatalog = New File(OwnerWorkingDirectory);
		If Not InformationAboutTheCatalog.Exists() Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'The directory of the %1 file folder does not exist.';"), 
				Owner);
		EndIf;
		CreateDirectory(OwnerWorkingDirectory);
		TestDirectoryName = OwnerWorkingDirectory + "CheckAccess\";
		CreateDirectory(TestDirectoryName);
		DeleteFiles(TestDirectoryName);
		Result = True;
	Except
		// 
		// 
		EventLogMessage = NStr("en = 'Working directory %1 for file folder %2 is not found or there is no save permission. Default settings are restored.';");
		EventLogMessage = StringFunctionsClientServer.SubstituteParametersToString(EventLogMessage, 
			OwnerWorkingDirectory, Owner);
		OwnerWorkingDirectory = "";
		
		FilesOperationsInternalServerCall.CleanUpWorkingDirectory(Owner);
		
		EventLogClient.AddMessageForEventLog(
			NStr("en = 'File management';", CommonClient.DefaultLanguageCode()),
			"Warning",
			EventLogMessage,
			CommonClient.SessionDate(),
			True);
	EndTry;
	Return Result;
EndFunction

// See the procedure of the same name in the general module of worksfilamiclient.
Procedure GetAttachedFile(Notification, AttachedFile, FormIdentifier, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	AdditionalDefaultParameters = New Structure;
	AdditionalDefaultParameters.Insert("ForEditing", False);
	AdditionalDefaultParameters.Insert("FileData",       Undefined);
	FillPropertyValues(AdditionalDefaultParameters, AdditionalParameters);
	
	Context = New Structure;
	Context.Insert("Notification",         Notification);
	Context.Insert("AttachedFile", AttachedFile);
	Context.Insert("FormIdentifier", FormIdentifier);
	
	CommonClientServer.SupplementStructure(Context, AdditionalDefaultParameters);
	
	If TypeOf(Context.FileData) <> Type("Structure")
		Or Not ValueIsFilled(Context.FileData.RefToBinaryFileData) Then
		
		Context.Insert("FileData", FilesOperationsInternalServerCall.GetFileData(
			Context.AttachedFile, Context.FormIdentifier, True, Context.ForEditing));
	EndIf;
	
	Context.Insert("ErrorTitle",
		NStr("en = 'Cannot get the file from the application. Reason:';") + Chars.LF);
	
	If Context.ForEditing
	   And Context.FileData.BeingEditedBy <> UsersClient.AuthorizedUser() Then
		
		Result = New Structure;
		Result.Insert("FullFileName", "");
		Result.Insert("ErrorDescription", Context.ErrorTitle 
			+ StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The file is locked by %1.';"), String(Context.FileData.BeingEditedBy)));
		ExecuteNotifyProcessing(Context.Notification, Result);
		Return;
	EndIf;
	
	Context.Insert("ForEditing", ValueIsFilled(Context.FileData.BeingEditedBy));
	FileSystemClient.AttachFileOperationsExtension(New NotifyDescription(
		"GetAttachedFileAfterAttachExtension", ThisObject, Context));
	
EndProcedure

// Continue the procedure to get the joined File.
Procedure GetAttachedFileAfterAttachExtension(ExtensionAttached, Context) Export
	
	If Not ExtensionAttached Then
		Result = New Structure;
		Result.Insert("FullFileName", "");
		Result.Insert("ErrorDescription", Context.ErrorTitle
			+ NStr("en = '1C:Enterprise Extension is not installed.';"));
		ExecuteNotifyProcessing(Context.Notification, Result);
		Return;
	EndIf;
	
	GetUserWorkingDirectory(New NotifyDescription(
		"GetAttachedFileAfterGetWorkingDirectory", ThisObject, Context));
	
EndProcedure

// Continue the procedure to get the joined File.
Procedure GetAttachedFileAfterGetWorkingDirectory(Result, Context) Export
	
	If ValueIsFilled(Result.ErrorDescription) Then
		Result = New Structure;
		Result.Insert("FullFileName", "");
		Result.Insert("ErrorDescription", Context.ErrorTitle + Result.ErrorDescription);
		ExecuteNotifyProcessing(Context.Notification, Result);
		Return;
	EndIf;
	
	Context.Insert("UserWorkingDirectory", Result.Directory);
	Context.Insert("FileDirectory", Context.UserWorkingDirectory + Context.FileData.RelativePath);
	Context.Insert("FullFileName", Context.FileDirectory + Context.FileData.FileName);
	
	FileOperations = New Array;
	
	Action = New Structure;
	Action.Insert("Action", "CreateDirectory");
	Action.Insert("File", Context.FileDirectory);
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("en = 'Cannot create the directory. Reason:';"));
	FileOperations.Add(Action);
	
	Action = New Structure;
	Action.Insert("Action", "SetProperties1");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Properties", New Structure("ReadOnly", False));
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("en = 'Cannot change the ""Read-only"" property. Reason:';"));
	FileOperations.Add(Action);
	
	Action = New Structure;
	Action.Insert("Action", "Get");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Address", Context.FileData.RefToBinaryFileData);
	Action.Insert("ErrorTitle", Context.ErrorTitle);
	FileOperations.Add(Action);
	
	FileProperties = New Structure;
	FileProperties.Insert("ReadOnly", Not Context.ForEditing);
	FileProperties.Insert("UniversalModificationTime", Context.FileData.UniversalModificationDate);
	
	Action = New Structure;
	Action.Insert("Action", "SetProperties1");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Properties", FileProperties);
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("en = 'Cannot set the file properties. Reason:';"));
	FileOperations.Add(Action);
	
	ProcessFile(New NotifyDescription(
			"GetAttachedFileAfterProcessFile", ThisObject, Context),
		FileOperations, Context.FormIdentifier);
	
EndProcedure

// Continue the procedure to get the joined File.
Procedure GetAttachedFileAfterProcessFile(ActionsResult, Context) Export
	
	Result = New Structure;
	
	If ValueIsFilled(ActionsResult.ErrorDescription) Then
		Result.Insert("FullFileName", "");
		Result.Insert("ErrorDescription", ActionsResult.ErrorDescription);
	Else
		Result.Insert("FullFileName", Context.FullFileName);
		Result.Insert("ErrorDescription", "");
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// See the procedure of the same name in the general module of the attached Client.
Procedure PutAttachedFile(Notification, AttachedFile, FormIdentifier, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification",                Notification);
	Context.Insert("AttachedFile",        AttachedFile);
	Context.Insert("FormIdentifier",        FormIdentifier);
	Context.Insert("FileData",               Undefined);
	Context.Insert("FullNameOfFileToPut", Undefined);
	AdditionalParameters.Property("FileData",    Context.FileData);
	AdditionalParameters.Property("FullFileName", Context.FullNameOfFileToPut);
	
	If TypeOf(Context.FileData) <> Type("Structure") Then
		Context.Insert("FileData", FilesOperationsInternalServerCall.GetFileData(
			Context.AttachedFile, Context.FormIdentifier, False));
	EndIf;
	
	Context.Insert("ErrorTitle",
		NStr("en = 'Cannot store the local file to the application. Reason:';") + Chars.LF);
	
	FileSystemClient.AttachFileOperationsExtension(New NotifyDescription(
		"PutAttachedFileAfterAttachExtension", ThisObject, Context));
	
EndProcedure

// Continue the procedure to place the joined File.
Procedure PutAttachedFileAfterAttachExtension(ExtensionAttached, Context) Export
	
	If Not ExtensionAttached Then
		Result = New Structure;
		Result.Insert("ErrorDescription", Context.ErrorTitle
			+ NStr("en = '1C:Enterprise Extension is not installed.';"));
		ExecuteNotifyProcessing(Context.Notification, Result);
		Return;
	EndIf;
	
	GetUserWorkingDirectory(New NotifyDescription(
		"PutAttachedFileAfterGetWorkingDirectory", ThisObject, Context));
	
EndProcedure

// Continue the procedure to place the joined File.
Procedure PutAttachedFileAfterGetWorkingDirectory(Result, Context) Export
	
	If ValueIsFilled(Result.ErrorDescription) Then
		ErrorResult = New Structure;
		ErrorResult.Insert("ErrorDescription", Context.ErrorTitle + Result.ErrorDescription);
		ExecuteNotifyProcessing(Context.Notification, ErrorResult);
		Return;
	EndIf;
	
	Context.Insert("UserWorkingDirectory", Result.Directory);
	Context.Insert("FileDirectory",   Context.UserWorkingDirectory + Context.FileData.RelativePath);
	Context.Insert("FullFileName", Context.FileDirectory + Context.FileData.FileName);
	
	File = New File(Context.FullFileName);
	
	File.BeginCheckingExistence(New NotifyDescription(
		"PlaceTheAttachedFileAfterReceivingTheWorkingDirectoryContinued",
		ThisObject,
		Context));
	
EndProcedure

Procedure PlaceTheAttachedFileAfterReceivingTheWorkingDirectoryContinued(FileExists, Context) Export
	If Not FileExists Then
		// 
		Context.Insert("FileDirectory",   Context.UserWorkingDirectory);
		Context.Insert("FullFileName", Context.FileData.FullFileNameInWorkingDirectory);
		
		If IsBlankString(Context.FileData.FullFileNameInWorkingDirectory) Then
			// 
			UnlockFileWithoutQuestion(Context.FileData, Context.FormIdentifier);
			Return;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Context.FullNameOfFileToPut) Then
		Context.FullNameOfFileToPut = Context.FullFileName;
	EndIf;
	
	FileDetails = New TransferableFileDescription(Context.FullFileName);
	Files = New Array;
	Files.Add(FileDetails);
	
	FileOperations = New Array;
	
	Calls = New Array;
	
	If Context.FullFileName <> Context.FullNameOfFileToPut Then
		Action = New Structure;
		Action.Insert("Action", "CreateDirectory");
		Action.Insert("File", Context.FileDirectory);
		Action.Insert("ErrorTitle", Context.ErrorTitle
			+ NStr("en = 'Cannot create the directory. Reason:';"));
		FileOperations.Add(Action);
		
		Action = New Structure;
		Action.Insert("Action", "SetProperties1");
		Action.Insert("File",  Context.FullFileName);
		Action.Insert("Properties", New Structure("ReadOnly", False));
		Action.Insert("ErrorTitle", Context.ErrorTitle
			+ NStr("en = 'Cannot change the ""Read-only"" property. Reason:';"));
		FileOperations.Add(Action);
		
		Action = New Structure;
		Action.Insert("Action", "CopyFromSource");
		Action.Insert("File",     Context.FullFileName);
		Action.Insert("Source", Context.FullNameOfFileToPut);
		Action.Insert("ErrorTitle", Context.ErrorTitle
			+ NStr("en = 'Cannot copy the file. Reason:';"));
		FileOperations.Add(Action);
		AddCall(Calls, "BeginCopyingFile", Context.FullNameOfFileToPut, Context.FullFileName, Undefined, Undefined);
	EndIf;
	
	Action = New Structure;
	Action.Insert("Action", "SetProperties1");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Properties", New Structure("ReadOnly", True));
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("en = 'Cannot change the ""Read-only"" property. Reason:';"));
	FileOperations.Add(Action);
	
	Context.Insert("FileProperties", New Structure);
	Context.FileProperties.Insert("UniversalModificationTime");
	Context.FileProperties.Insert("BaseName");
	Context.FileProperties.Insert("Extension");
	
	Action = New Structure;
	Action.Insert("Action", "GetProperties");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Properties", Context.FileProperties);
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("en = 'Cannot get the file properties. Reason:';"));
	FileOperations.Add(Action);
	
	Context.Insert("PlacementAction", New Structure);
	Context.PlacementAction.Insert("Action", "Into");
	Context.PlacementAction.Insert("File",  Context.FullFileName);
	Context.PlacementAction.Insert("ErrorTitle", Context.ErrorTitle);
	FileOperations.Add(Context.PlacementAction);
	AddCall(Calls, "BeginPuttingFiles", Files, Undefined, False, Context.FormIdentifier);
	
	Context.Insert("FileOperations", FileOperations);
	
	BeginRequestingUserPermission(New NotifyDescription(
		"PutAttachedFileAfterGetPermissions", ThisObject, Context), Calls);
EndProcedure

Procedure AddCall(Calls, Method, P1, P2, P3, P4)
	
	Call = New Array;
	Call.Add(Method);
	Call.Add(P1);
	Call.Add(P2);
	Call.Add(P3);
	Call.Add(P4);
	
	Calls.Add(Call);
	
EndProcedure

// Continue the procedure to place the joined File.
Procedure PutAttachedFileAfterGetPermissions(PermissionsGranted, Context) Export
	
	If PermissionsGranted Then
		ProcessFile(New NotifyDescription(
				"PutAttachedFileAfterProcessFile", ThisObject, Context),
			Context.FileOperations, Context.FormIdentifier);
	EndIf;
		
EndProcedure

// Continue the procedure to place the joined File.
Procedure PutAttachedFileAfterProcessFile(ActionsResult, Context) Export
	
	Result = New Structure;
	
	If ValueIsFilled(ActionsResult.ErrorDescription) Then
		Result.Insert("ErrorDescription", ActionsResult.ErrorDescription);
		ExecuteNotifyProcessing(Context.Notification, Result);
		Return;
	EndIf;
	
	Result.Insert("ErrorDescription", "");
	
	Extension = Context.FileProperties.Extension;
	
	FileInfo = New Structure;
	FileInfo.Insert("UniversalModificationDate",   Context.FileProperties.UniversalModificationTime);
	FileInfo.Insert("FileAddressInTempStorage", Context.PlacementAction.Address);
	FileInfo.Insert("TempTextStorageAddress", "");
	FileInfo.Insert("BaseName",               Context.FileProperties.BaseName);
	FileInfo.Insert("Extension",                     Right(Extension, StrLen(Extension)-1));
	FileInfo.Insert("BeingEditedBy",                    Undefined);
	
	Try
		FilesOperationsInternalServerCall.UpdateAttachedFile(
			Context.AttachedFile, FileInfo);
	Except
		ErrorInfo = ErrorInfo();
		Result.Insert("ErrorDescription", Context.ErrorTitle + Chars.LF
			+ ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// 

// The procedure opens Windows Explorer by positioning itself on the File.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  FileData          - See FilesOperationsInternalServerCall.FileData
//
Procedure FileDirectory(ResultHandler, FileData) Export
	
	// 
	If FileData.Version.IsEmpty() Then 
		Return;
	EndIf;
	
	#If WebClient Then
		If Not FileSystemExtensionAttached1() Then
			ShowFileSystemExtensionRequiredMessageBox(ResultHandler);
			Return;
		EndIf;
	#EndIf
	
	FullFileName = GetFilePathInWorkingDirectory(FileData);
	If OpenExplorerWithFile(FullFileName) Then
		Return;
	EndIf;
	
	FileName = CommonClientServer.GetNameWithExtension(
		FileData.FullVersionDescription, FileData.Extension);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("FileData", FileData);
	HandlerParameters.Insert("FileName", FileName);
	HandlerParameters.Insert("FullFileName", FullFileName);
	Handler = New NotifyDescription("FileDirectoryAfterRespondQuestionGetFile", ThisObject, HandlerParameters);
	
	QuestionButtons = New ValueList;
	QuestionButtons.Add(DialogReturnCode.Yes, NStr("en = 'Save and open the directory';"));
	QuestionButtons.Add(DialogReturnCode.No, NStr("en = 'Cancel';"));
	ShowQueryBox(Handler,
		StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'The file directory does not exist. Probably file ""%1"" was never opened on this computer.
			|Do you want to save a local file copy and open its directory?';"),
			FileName),
		QuestionButtons);
	
EndProcedure

// 
Procedure FileDirectoryAfterRespondQuestionGetFile(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		Handler = New NotifyDescription("FileDirectoryAfterGetFileToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(Handler, ExecutionParameters.FileData, ExecutionParameters.FullFileName);
	Else
		FileDirectoryAfterGetFileToWorkingDirectory(-1, ExecutionParameters);
	EndIf;
	
EndProcedure

// 
Procedure FileDirectoryAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result <> -1 Then
		ExecutionParameters.FullFileName = Result.FullFileName;
		OpenExplorerWithFile(ExecutionParameters.FullFileName);
	EndIf;
	
	// 
	If IsTempStorageURL(ExecutionParameters.FileData.CurrentVersionURL) Then
		DeleteFromTempStorage(ExecutionParameters.FileData.CurrentVersionURL);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  Ref  - CatalogRef.Files -  file.
//  DeleteInWorkingDirectory - Boolean -  delete even in the working directory.
//
Procedure DeleteFileFromWorkingDirectory(ResultHandler, Ref, DeleteInWorkingDirectory = False)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("Ref", Ref);
	ExecutionParameters.Insert("Success", False);
	ExecutionParameters.Insert("DirectoryName", UserWorkingDirectory());
	
	ExecutionParameters.Insert("FullFileNameFromRegister", Undefined);
	
	InOwnerWorkingDirectory = False;
	ExecutionParameters.FullFileNameFromRegister = FilesOperationsInternalServerCall.FullFileNameInWorkingDirectory(
		ExecutionParameters.Ref, ExecutionParameters.DirectoryName, False, InOwnerWorkingDirectory);
	
	If ExecutionParameters.FullFileNameFromRegister <> "" Then
		
		// 
		If Not InOwnerWorkingDirectory Or DeleteInWorkingDirectory = True Then
			
			FileOnHardDrive = New File(ExecutionParameters.FullFileNameFromRegister);
			
			If FileOnHardDrive.Exists() Then
				FileOnHardDrive.SetReadOnly(False);
				
				CompletionHandler = New NotifyDescription("DeleteFileFromWorkingDirectoryAfterDeleteFile", ThisObject);
				RegisterCompletionHandler(ExecutionParameters, CompletionHandler);
				
				DeleteFile(ExecutionParameters, ExecutionParameters.FullFileNameFromRegister);
				If ExecutionParameters.AsynchronousDialog.Open = True Then
					Return;
				EndIf;
				
				DeleteFileFromWorkingDirectoryAfterDeleteFile(
					ExecutionParameters.AsynchronousDialog.ResultWhenNotOpen, ExecutionParameters);
				Return;
				
			EndIf;
		EndIf;
	EndIf;
	
	DeleteFileFromWorkingDirectoryCompletion(ExecutionParameters);
	
EndProcedure

// 
Procedure DeleteFileFromWorkingDirectoryAfterDeleteFile(Result, ExecutionParameters) Export
	
	PathWithSubdirectory = ExecutionParameters.DirectoryName;
	Position = StrFind(ExecutionParameters.FullFileNameFromRegister, GetPathSeparator());
	If Position <> 0 Then
		PathWithSubdirectory = PathWithSubdirectory + Left(ExecutionParameters.FullFileNameFromRegister, Position);
	EndIf;
	
	FilesArrayInDirectory = FindFiles(PathWithSubdirectory, "*");
	If FilesArrayInDirectory.Count() = 0 Then
		If PathWithSubdirectory <> ExecutionParameters.DirectoryName Then
			Try
				DeleteFiles(PathWithSubdirectory);
			Except
				EventLogClient.AddMessageForEventLog(EventLogEvent(),
					"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
			EndTry;	
		EndIf;
	EndIf;
	
	DeleteFileFromWorkingDirectoryCompletion(ExecutionParameters);
	
EndProcedure

// 
Procedure DeleteFileFromWorkingDirectoryCompletion(ExecutionParameters)
	
	If ExecutionParameters.FullFileNameFromRegister = "" Then
		FilesOperationsInternalServerCall.DeleteFromRegister(ExecutionParameters.Ref);
	Else
		FileOnHardDrive = New File(ExecutionParameters.FullFileNameFromRegister);
		If Not FileOnHardDrive.Exists() Then
			FilesOperationsInternalServerCall.DeleteFromRegister(ExecutionParameters.Ref);
		EndIf;
	EndIf;
	
	ExecutionParameters.Success = True;
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Free up space for placing the file - if there is space, it does nothing.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  VersionAttributes  - See FilesOperationsInternalServerCall.FileData
//
Procedure ClearSpaceInWorkingDirectory(ResultHandler, VersionAttributes)

#If WebClient Then
	// 
	ReturnResultAfterShowWarning(
		ResultHandler,
		NStr("en = 'You can clear the working directory only in the thin client.';"),
		Undefined);
	Return;
#EndIf
	
	MaxSize1 = PersonalFilesOperationsSettings().LocalFileCacheMaxSize;
	
	// 
	// 
	If MaxSize1 = 0 Then
		Return;
	EndIf;
	
	DirectoryName = UserWorkingDirectory();
	
	FilesArray = FindFiles(DirectoryName, GetAllFilesMask());
	
	WorkingDirectoryFilesSize = 0;
	TotalFilesCount = 0;
	// 
	GetFileListSize(DirectoryName, FilesArray, WorkingDirectoryFilesSize, TotalFilesCount);
	
	Size = VersionAttributes.Size;
	If WorkingDirectoryFilesSize + Size > MaxSize1 Then
		CleanUpWorkingDirectory(ResultHandler, WorkingDirectoryFilesSize, Size, False); // 
	EndIf;
	
EndProcedure

// Clearing the working directory - to free up space-first removes files 
// that have been placed in the working directory for a long time.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  WorkingDirectoryFilesSize  - Number -  size of files in the working directory.
//  SizeOfFileToAdd - Number -  the size of the file to add.
//  ClearEverything - Boolean -  delete all files in the folder (not just until the required amount of disk space is available).
//
Procedure CleanUpWorkingDirectory(ResultHandler, WorkingDirectoryFilesSize, SizeOfFileToAdd, ClearEverything) Export
	
#If WebClient Then
	ReturnResultAfterShowWarning(ResultHandler, NStr("en = 'You can clear the working directory only in the thin client.';"), Undefined);
	Return;
#EndIf
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("WorkingDirectoryFilesSize", WorkingDirectoryFilesSize);
	HandlerParameters.Insert("SizeOfFileToAdd", SizeOfFileToAdd);
	HandlerParameters.Insert("ClearEverything", ClearEverything);
	
	ClearWorkingDirectoryStart(HandlerParameters);
	
EndProcedure

// 
Procedure ClearWorkingDirectoryStart(ExecutionParameters)
	
	DirectoryName = UserWorkingDirectory();
	
	TableOfFiles = New Array;
	FilesArray = FindFiles(DirectoryName, "*");
	ProcessFilesTable(DirectoryName, FilesArray, TableOfFiles);
	
	// 
	//  
	FilesOperationsInternalServerCall.SortStructuresArray(TableOfFiles);
	
	PersonalSettings = PersonalFilesOperationsSettings();
	MaxSize1 = PersonalSettings.LocalFileCacheMaxSize;
	
	AverageFileSize = 1000;
	If TableOfFiles.Count() <> 0 Then
		AverageFileSize = ExecutionParameters.WorkingDirectoryFilesSize / TableOfFiles.Count();
	EndIf;
	
	If ExecutionParameters.ClearEverything Then
		AmountOfFreeSpaceRequired = 0;
	Else
		AmountOfFreeSpaceRequired = MaxSize1 / 10;
		If AverageFileSize * 3 / 2 > AmountOfFreeSpaceRequired Then
			AmountOfFreeSpaceRequired = AverageFileSize * 3 / 2;
		EndIf;
	EndIf;
	
	SpaceLeft = ExecutionParameters.WorkingDirectoryFilesSize + ExecutionParameters.SizeOfFileToAdd;
	ExecutionParameters.Insert("DirectoryName", DirectoryName);
	ExecutionParameters.Insert("MaxSize1", MaxSize1);
	ExecutionParameters.Insert("SpaceLeft", SpaceLeft);
	ExecutionParameters.Insert("AmountOfFreeSpaceRequired", AmountOfFreeSpaceRequired);
	ExecutionParameters.Insert("TableOfFiles", TableOfFiles);
	ClearWorkingDirectoryForFileToOpen(ExecutionParameters);
	
EndProcedure

// Parameters:
//   ExecutionParameters - Structure:
//     * TableOfFiles - Array of See FilesInWorkingDirectoryData
//
Procedure ClearWorkingDirectoryForFileToOpen(ExecutionParameters)
	
	IndexOf = 0;
	Title = NStr("en = 'Clearing working directory';");
	Text = NStr("en = 'Please wait…';");
	Status(Title, 1, Text);
	For Each Item In ExecutionParameters.TableOfFiles Do
		
		IndexOf = IndexOf + 1;
		
		FullPath = ExecutionParameters.DirectoryName + Item.Path;
		FileOnHardDrive = New File(FullPath);
		FileOnHardDrive.SetReadOnly(False);
		DeleteFile(ExecutionParameters, FullPath);
		
		PathWithSubdirectory = ExecutionParameters.DirectoryName;
		Position = StrFind(Item.Path, GetPathSeparator());
		If Position <> 0 Then
			PathWithSubdirectory = ExecutionParameters.DirectoryName + Left(Item.Path, Position);
		EndIf;
		
		// 
		FilesArrayInDirectory = FindFiles(PathWithSubdirectory, "*");
		If FilesArrayInDirectory.Count() = 0 Then
			If PathWithSubdirectory <> ExecutionParameters.DirectoryName Then
				Try
					DeleteFiles(PathWithSubdirectory);
				Except
					EventLogClient.AddMessageForEventLog(EventLogEvent(),
						"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
				EndTry;	
			EndIf;
		EndIf;
		
		FilesOperationsInternalServerCall.DeleteFromRegister(Item.Version);
		
		If ExecutionParameters.AmountOfFreeSpaceRequired > 0 Then
			ExecutionParameters.SpaceLeft = ExecutionParameters.SpaceLeft - Item.Size;
			If ExecutionParameters.SpaceLeft < ExecutionParameters.MaxSize1 - ExecutionParameters.AmountOfFreeSpaceRequired Then
				Return; // 
			EndIf;
		EndIf;
		
		If IndexOf % 10 = 0 Then
			Progress = ?(ExecutionParameters.AmountOfFreeSpaceRequired > 0,
				(ExecutionParameters.AmountOfFreeSpaceRequired - ExecutionParameters.SpaceLeft) * 100 / ExecutionParameters.AmountOfFreeSpaceRequired,
				IndexOf * 100 / ExecutionParameters.TableOfFiles.Count());
			Status(Title, Progress, Text);
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Get the File from the server and register it in the local cache.
//
// Parameters:
//   ExecutionParameters - Structure:
//     * ResultHandler - NotifyDescription
//                            - Undefined - 
//     * FileData - See FilesOperationsInternalServerCall.FileData
//     * FullFileNameInWorkingDirectory - String -  the full file name is returned here.
//     * FileDateInDatabase - Date -  date of the file in the database.
//     * ForReading - Boolean -  the file has been placed for reading.
//     * FormIdentifier - UUID -  the ID of the form.
//
Procedure GetFromServerAndRegisterInLocalFilesCache(Val ExecutionParameters)
	
	ExecutionParameters = CommonClient.CopyRecursive(ExecutionParameters);
	ExecutionParameters.Insert("InOwnerWorkingDirectory", ExecutionParameters.FileData.OwnerWorkingDirectory <> "");
	ExecutionParameters.Insert("DirectoryName", "");
	ExecutionParameters.Insert("DirectoryNamePreviousValue", "");
	ExecutionParameters.Insert("FileName", "");
	ExecutionParameters.Insert("FullPathMaxSize", 260);
	ExecutionParameters.Insert("FileReceived", False);
	
	If ExecutionParameters.FullFileName = "" Then
		ExecutionParameters.DirectoryName = UserWorkingDirectory();
		ExecutionParameters.DirectoryNamePreviousValue = ExecutionParameters.DirectoryName;
		
		// 
		ExecutionParameters.FileName = ExecutionParameters.FileData.FullVersionDescription;
		If Not IsBlankString(ExecutionParameters.FileData.Extension) Then 
			ExecutionParameters.FileName = CommonClientServer.GetNameWithExtension(
				ExecutionParameters.FileName, ExecutionParameters.FileData.Extension);
		EndIf;
		
		CommonInternalClient.ShortenFileName(ExecutionParameters.FileName);
		
		ExecutionParameters.FullFileName = "";
		If Not IsBlankString(ExecutionParameters.FileName) Then
			ExecutionParameters.FullFileName = ExecutionParameters.DirectoryName 
				+ FilesOperationsInternalClientServer.UniqueNameByWay(ExecutionParameters.DirectoryName,
					ExecutionParameters.FileName);
		EndIf;
		
		If IsBlankString(ExecutionParameters.FileName) Then
			ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
			Return;
		EndIf;
		
		ExecutionParameters.FullPathMaxSize = 260;
		If Lower(ExecutionParameters.FileData.Extension) = "xls" Or Lower(ExecutionParameters.FileData.Extension) = "xlsx" Then
			// 
			ExecutionParameters.FullPathMaxSize = 218;
		EndIf;
		
		MaxFileNameLength = ExecutionParameters.FullPathMaxSize - 5; // 
		
		If ExecutionParameters.InOwnerWorkingDirectory = False Then
#If Not WebClient Then
			If StrLen(ExecutionParameters.FullFileName) > ExecutionParameters.FullPathMaxSize Then
				UserDirectoryPath = UserDataDir();
				MaxFileNameLength = ExecutionParameters.FullPathMaxSize - StrLen(UserDirectoryPath);
				
				// 
				If StrLen(ExecutionParameters.FileName) > MaxFileNameLength Then
					
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'The file path (working directory + file name) is longer than %1 characters:
						           |%2';"),
						ExecutionParameters.FullPathMaxSize,
						ExecutionParameters.FullFileName);
					MessageText = MessageText + Chars.CR + Chars.CR
						+ NStr("en = 'Please choose a shorter file name.';");
					ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, 
						MessageText, ExecutionParameters);
					Return;
					
				EndIf;
				
				GetFromServerAndRegisterInLocalFilesCacheOfferSelectDirectory(-1, ExecutionParameters);
				Return;
				
			EndIf;
#EndIf
		EndIf;
		
	EndIf;
	
	GetFromServerAndRegisterInLocalFilesCacheFollowUp(ExecutionParameters);
	
EndProcedure

// 
Procedure GetFromServerAndRegisterInLocalFilesCacheOfferSelectDirectory(Response, ExecutionParameters)
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'The file path (working directory + file name) is longer than %1 characters:
		|%2
		|
		|Do you want to select a different main working directory?';"),
		ExecutionParameters.FullPathMaxSize,
		ExecutionParameters.FullFileName);
	Handler = New NotifyDescription("GetFromServerAndRegisterInLocalFilesCacheStartToSelectDirectory", ThisObject, ExecutionParameters);
	ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

// 
Procedure GetFromServerAndRegisterInLocalFilesCacheStartToSelectDirectory(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.No Then
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	// 
	Title = NStr("en = 'Select another main working directory';");
	DirectorySelected1 = ChoosePathToWorkingDirectory(ExecutionParameters.DirectoryName, Title, False);
	If Not DirectorySelected1 Then
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	ExecutionParameters.FullFileName = ExecutionParameters.DirectoryName 
		+ FilesOperationsInternalClientServer.UniqueNameByWay(
		ExecutionParameters.DirectoryName,
		ExecutionParameters.FileName);
	
	// 
	If StrLen(ExecutionParameters.FullFileName) <= ExecutionParameters.FullPathMaxSize Then
		Handler = New NotifyDescription("GetFromServerAndRegisterInLocalFilesCacheAfterMoveWorkingDirectoryContent", ThisObject, ExecutionParameters);
		MoveWorkingDirectoryContent(Handler, ExecutionParameters.DirectoryNamePreviousValue, ExecutionParameters.DirectoryName);
	Else
		GetFromServerAndRegisterInLocalFilesCacheOfferSelectDirectory(-1, ExecutionParameters);
	EndIf;
	
EndProcedure

// 
Procedure GetFromServerAndRegisterInLocalFilesCacheAfterMoveWorkingDirectoryContent(ContentMoved, ExecutionParameters) Export
	
	If ContentMoved Then
		SetUserWorkingDirectory(ExecutionParameters.DirectoryName);
		GetFromServerAndRegisterInLocalFilesCacheFollowUp(ExecutionParameters);
	Else
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	EndIf;
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure GetFromServerAndRegisterInLocalFilesCacheFollowUp(ExecutionParameters)
	
#If Not WebClient Then
	If ExecutionParameters.InOwnerWorkingDirectory = False Then
		ClearSpaceInWorkingDirectory(Undefined, ExecutionParameters.FileData);
	EndIf;
#EndIf
	
	// 
	ExecutionParameters.FileName = CommonClientServer.GetNameWithExtension(
		ExecutionParameters.FileData.FullVersionDescription,
		ExecutionParameters.FileData.Extension);
	CommonInternalClient.ShortenFileName(ExecutionParameters.FileName);
	
	FileOnHardDriveByName = New File(ExecutionParameters.FullFileName);
	NameAndExtensionInPath = FileOnHardDriveByName.Name;
	Position = StrFind(ExecutionParameters.FullFileName, NameAndExtensionInPath);
	PathToFile = "";
	If Position <> 0 Then
		PathToFile = Left(ExecutionParameters.FullFileName, Position - 1); // -
	EndIf;
	
	PathToFile = CommonClientServer.AddLastPathSeparator(PathToFile);
	ExecutionParameters.Insert("ParameterFilePath", PathToFile);
	
	ExecutionParameters.FullFileName = PathToFile + ExecutionParameters.FileName; // 
	
	If ExecutionParameters.FileData.Property("UpdatePathFromFileOnHardDrive") Then
		
		FileCopy(ExecutionParameters.FileData.UpdatePathFromFileOnHardDrive, ExecutionParameters.FullFileName);
		GetFromServerAndRegisterInLocalFilesCacheCompletion(ExecutionParameters);
		
		Return;
	EndIf;
	
	If ExecutionParameters.FileData.Encrypted Then
		
		If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			Return;
		EndIf;
		
		FillTemporaryFormID(ExecutionParameters.FormIdentifier, ExecutionParameters);
		
		ReturnStructure = FilesOperationsInternalServerCall.FileDataAndBinaryData(
			ExecutionParameters.FileData.Version,, ExecutionParameters.FormIdentifier);
		
		DataDetails = New Structure;
		DataDetails.Insert("Operation",              NStr("en = 'Decrypt file';"));
		DataDetails.Insert("DataTitle",       NStr("en = 'File';"));
		DataDetails.Insert("Data",                ReturnStructure.BinaryData);
		DataDetails.Insert("Presentation",         ExecutionParameters.FileData.Ref);
		DataDetails.Insert("EncryptionCertificates", ExecutionParameters.FileData.Ref);
		DataDetails.Insert("NotifyOnCompletion",   False);
		
		FollowUpHandler = New NotifyDescription(
			"GetFromServerAndRegisterInLocalFilesCacheAfterDecryption",
			ThisObject,
			ExecutionParameters);
		
		ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
		ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
		
		Return;
	EndIf;
	
	GetFromServerAndRegisterInLocalFilesCacheFileSending(ExecutionParameters);
	
EndProcedure

// 
Procedure GetFromServerAndRegisterInLocalFilesCacheAfterDecryption(DataDetails, ExecutionParameters) Export
	
	If Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	If TypeOf(DataDetails.DecryptedData) = Type("BinaryData") Then
		FileAddress = PutToTempStorage(DataDetails.DecryptedData,
			ExecutionParameters.FormIdentifier);
		FileData = ExecutionParameters.ResultHandler.AdditionalParameters.FileData;
		FileData.Encoding = FilesOperationsInternalClientServer.DetermineBinaryDataEncoding(DataDetails.DecryptedData, FileData.Extension);
	Else
		FileAddress = DataDetails.DecryptedData;
	EndIf;
	
	GetFromServerAndRegisterInLocalFilesCacheFileSending(ExecutionParameters, FileAddress);
	
EndProcedure

// 
Procedure GetFromServerAndRegisterInLocalFilesCacheFileSending(ExecutionParameters, FileAddress = Undefined)
	
	If FileAddress = Undefined Then
		If ExecutionParameters.FileData.Version <> ExecutionParameters.FileData.CurrentVersion Then
			FileAddress = FilesOperationsInternalServerCall.GetURLToOpen(
				ExecutionParameters.FileData.Version, ExecutionParameters.FormIdentifier);
		Else
			FileAddress = ExecutionParameters.FileData.RefToBinaryFileData;
		EndIf;
	EndIf;
	
	TransmittedFiles = New Array;
	LongDesc = New TransferableFileDescription(ExecutionParameters.FullFileName, FileAddress);
	TransmittedFiles.Add(LongDesc);
	
#If WebClient Then
	If ExecutionParameters.AdditionalParameters <> Undefined 
		And ExecutionParameters.AdditionalParameters.Property("OpenFile") Then
			
		OperationArray = New Array;
		
		CallDetails = New Array;
		CallDetails.Add("GetFiles");
		CallDetails.Add(TransmittedFiles);
		CallDetails.Add(Undefined);  // 
		CallDetails.Add(ExecutionParameters.ParameterFilePath);
		CallDetails.Add(False);          // 
		OperationArray.Add(CallDetails);
		
		CallDetails = New Array;
		CallDetails.Add("RunApp");
		CallDetails.Add(ExecutionParameters.FullFileName);
		OperationArray.Add(CallDetails);
		
		If Not RequestUserPermission(OperationArray) Then
			// 
			ClearTemporaryFormID(ExecutionParameters);
			ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
			Return;
		EndIf;
		
	EndIf;
#EndIf
	
	ObtainedFiles = New Array;
	If Not GetFiles(TransmittedFiles, ObtainedFiles , , False) Then
		ClearTemporaryFormID(ExecutionParameters);
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	// 
	If IsTempStorageURL(FileAddress) Then
		DeleteFromTempStorage(FileAddress);
	EndIf;
	
	// 
	SetModificationUniversalTime(ExecutionParameters.FullFileName, 
		ExecutionParameters.FileData.UniversalModificationDate);
	
	GetFromServerAndRegisterInLocalFilesCacheCompletion(ExecutionParameters);
	
EndProcedure

// 
Procedure GetFromServerAndRegisterInLocalFilesCacheCompletion(ExecutionParameters)
	
	FileOnHardDrive = New File(ExecutionParameters.FullFileName);
	
	// 
	FileSize = FileOnHardDrive.Size();
	
	FileOnHardDrive.SetReadOnly(ExecutionParameters.ForReading);
	
	ExecutionParameters.DirectoryName = UserWorkingDirectory();
	
	FilesOperationsInternalServerCall.PutFileInformationInRegister(ExecutionParameters.FileData.Version,
		ExecutionParameters.FullFileName, ExecutionParameters.DirectoryName, ExecutionParameters.ForReading, FileSize,
		ExecutionParameters.InOwnerWorkingDirectory);
	
	If ExecutionParameters.FileData.Size <> FileSize Then
		
		If Not ExecutionParameters.FileData.Property("UpdatePathFromFileOnHardDrive") Then
			
			FilesOperationsInternalServerCall.UpdateSizeOfFileAndVersion(ExecutionParameters.FileData, 
				FileSize, ExecutionParameters.FormIdentifier);
			
			NotifyChanged(ExecutionParameters.FileData.Ref);
			NotifyChanged(ExecutionParameters.FileData.Version);
			
			NotificationParameters = FileWriteNotificationParameters();
			NotificationParameters.File = ExecutionParameters.FileData.Ref;
			NotificationParameters.Event = "FileDataChanged";
			NotificationParameters.IsNew = False;
			
			Notify("Write_File", NotificationParameters, ExecutionParameters.FileData.Ref);
		EndIf;
	EndIf;
	
	ClearTemporaryFormID(ExecutionParameters);
	
	ExecutionParameters.FileReceived = True;
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Retrieves a File from the file storage to the working directory of the folder
// and returns the path to this file.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  FileData        - See FilesOperationsInternalServerCall.FileData
//  FullFileName     - String -  the return value.
//  ForReading           - Boolean -  False for reading, True for editing.
//  FormIdentifier - UUID
//
Procedure GetVersionFileToFolderWorkingDirectory(ResultHandler, FileData, FullFileName,
	ForReading, FormIdentifier, AdditionalParameters)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FullFileName", FullFileName);
	ExecutionParameters.Insert("ForReading", ForReading);
	ExecutionParameters.Insert("FormIdentifier", FormIdentifier);
	ExecutionParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	ExecutionParameters.Insert("FileReceived", False);
	
	// 
	FileName = FileData.FullVersionDescription;
	If Not IsBlankString(FileData.Extension) Then 
		FileName = CommonClientServer.GetNameWithExtension(FileName, FileData.Extension);
	EndIf;
	
	CommonInternalClient.ShortenFileName(FileName);
	
	If ExecutionParameters.FullFileName = "" Then
		ExecutionParameters.FullFileName = FileData.OwnerWorkingDirectory + FileName;
		Handler = New NotifyDescription("GetVersionFileToFolderWorkingDirectoryAfterCheckPathLength", 
			ThisObject, ExecutionParameters);
		CheckFullPathMaxLengthInWorkingDirectory(Handler, FileData, ExecutionParameters.FullFileName, FileName);
	Else
		GetVersionFileToFolderWorkingDirectoryFollowUp(ExecutionParameters);
	EndIf;
	
EndProcedure

// 
Procedure GetVersionFileToFolderWorkingDirectoryAfterCheckPathLength(Result, ExecutionParameters) Export
	
	If Result = False Then
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	Else
		GetVersionFileToFolderWorkingDirectoryFollowUp(ExecutionParameters);
	EndIf;
	
EndProcedure

// 
Procedure GetVersionFileToFolderWorkingDirectoryFollowUp(ExecutionParameters)
	
	// 
	FileInfo1 = FilesOperationsInternalServerCall.FilesInfoInWorkingDir(
		CommonClientServer.ValueInArray(ExecutionParameters.FullFileName));
	FileInfo1 = FileInfo1[ExecutionParameters.FullFileName];
	ExecutionParameters.Insert("FileIsInRegister", FileInfo1.FileIsInRegister);
	Version            = FileInfo1.File;
	Owner          = FileInfo1.Owner;
	InRegisterForReading = FileInfo1.InRegisterForReading;
	InRegisterFolder    = FileInfo1.InRegisterFolder;
	
	FileOnHardDrive = New File(ExecutionParameters.FullFileName);
	FileOnHardDriveExists = FileOnHardDrive.Exists();
	
	// 
	If ExecutionParameters.FileIsInRegister And Not FileOnHardDriveExists Then
		FilesOperationsInternalServerCall.DeleteFromRegister(Version);
		ExecutionParameters.FileIsInRegister = False;
	EndIf;
	
	If Not ExecutionParameters.FileIsInRegister And Not FileOnHardDriveExists Then
		GetFromServerAndRegisterInFolderWorkingDirectory(
			ExecutionParameters.ResultHandler,
			ExecutionParameters.FileData,
			ExecutionParameters.FullFileName,
			ExecutionParameters.FileData.UniversalModificationDate,
			ExecutionParameters.ForReading,
			ExecutionParameters.FormIdentifier,
			ExecutionParameters.AdditionalParameters);
		Return;
	EndIf;
	
	// 
	
	If ExecutionParameters.FileIsInRegister And Version <> ExecutionParameters.FileData.CurrentVersion Then
		
		If Owner = ExecutionParameters.FileData.Ref And InRegisterForReading = True Then
			// 
			// 
			// 
			GetFromServerAndRegisterInFolderWorkingDirectory(
				ExecutionParameters.ResultHandler,
				ExecutionParameters.FileData,
				ExecutionParameters.FullFileName,
				ExecutionParameters.FileData.UniversalModificationDate,
				ExecutionParameters.ForReading,
				ExecutionParameters.FormIdentifier,
				ExecutionParameters.AdditionalParameters);
			Return;
		EndIf;
		
		If ExecutionParameters.FileData.Owner = InRegisterFolder Then // 
			WarningText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The working directory contains file
				           |""%1""
				           |that matches another file stored in the application.
				           |
				           |It is recommended that you rename one of the files in the application.';"),
				ExecutionParameters.FullFileName);
		Else
			WarningText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The working directory contains file
				           |""%1""
				           |that matches another file stored in the application.
				           |
				           |It is recommended that you select another working directory for one of the application folders.
				           |(Two folders cannot have the same working directory.)';"),
				ExecutionParameters.FullFileName);
		EndIf;
		
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, WarningText, ExecutionParameters);
		Return;
	EndIf;
	
	// 
	// 
	
	// 
	Handler = New NotifyDescription("GetVersionsFileToFolderWorkingDirectoryAfterActionChoice", ThisObject, ExecutionParameters);
	
	ActionOnOpenFileInWorkingDirectory(
		Handler,
		ExecutionParameters.FullFileName,
		ExecutionParameters.FileData);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters - Structure:
//     * AdditionalParameters - See GetVersionFileToFolderWorkingDirectory.AdditionalParameters
//
Procedure GetVersionsFileToFolderWorkingDirectoryAfterActionChoice(Result, ExecutionParameters) Export
	
	If Result = "GetFromStorageAndOpen" Then
		
		// 
		DeleteFileWithoutConfirmation(ExecutionParameters.FullFileName);
		GetFromServerAndRegisterInLocalFilesCache(ExecutionParameters);
		
	ElsIf Result = "OpenExistingFile" Then
		
		If ExecutionParameters.FileData.InWorkingDirectoryForRead <> ExecutionParameters.ForReading
			Or Not ExecutionParameters.FileIsInRegister Then
			
			InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
			RegegisterInWorkingDirectory(ExecutionParameters.FileData.Version, 
				ExecutionParameters.FullFileName, ExecutionParameters.ForReading, InOwnerWorkingDirectory);
		EndIf;
		
		ExecutionParameters.FileReceived = True;
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		
	Else // 
		ExecutionParameters.FullFileName = "";
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Get the File from the server and register it in the working directory.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  FileData  - See FilesOperationsInternalServerCall.FileData
//  FullFileNameInWorkingDirectory - String -  the full file name is returned here.
//  FileDateInDatabase - Date -  date of the file in the database.
//  ForReading - Boolean -  the file has been placed for reading.
//  FormIdentifier - UUID -  the ID of the form.
//  AdditionalParameters - Arbitrary -  additional processing parameters.
//
Procedure GetFromServerAndRegisterInFolderWorkingDirectory(ResultHandler, FileData, 
	FullFileNameInWorkingDirectory, FileDateInDatabase, ForReading, FormIdentifier, AdditionalParameters)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FullFileNameInWorkingDirectory", FullFileNameInWorkingDirectory);
	ExecutionParameters.Insert("FileDateInDatabase", FileDateInDatabase);
	ExecutionParameters.Insert("ForReading", ForReading);
	ExecutionParameters.Insert("FormIdentifier", FormIdentifier);
	ExecutionParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	ExecutionParameters.Insert("FullFileName", "");
	ExecutionParameters.Insert("FileReceived", False);
	
	InWorkingDirectoryForRead = True;
	InOwnerWorkingDirectory = False;
	
	FileInWorkingDirectory = FileInLocalFilesCache(FileData,
		FileData.Version, ExecutionParameters.FullFileName,
		InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	If Not FileInWorkingDirectory Then
		ExecutionParameters.Insert("FullFileName", ExecutionParameters.FullFileNameInWorkingDirectory);
		GetFromServerAndRegisterInLocalFilesCache(ExecutionParameters);
		Return;
	EndIf;

	// 
	If ExecutionParameters.FullFileName = "" Then
		CommonClient.MessageToUser(
			NStr("en = 'Cannot get the file from the application to the working directory.';"));
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		Return;
	EndIf;
	
	// 
	// 
	Handler = New NotifyDescription("GetFromServerAndRegisterInFolderWorkingDirectoryAfterActionChoice", 
		ThisObject, ExecutionParameters);
	ActionOnOpenFileInWorkingDirectory(Handler, ExecutionParameters.FullFileName,
		ExecutionParameters.FileData);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters - Structure:
//     * AdditionalParameters - See GetFromServerAndRegisterInFolderWorkingDirectory.AdditionalParameters
//
Procedure GetFromServerAndRegisterInFolderWorkingDirectoryAfterActionChoice(Result, ExecutionParameters) Export
	
	If Result = "GetFromStorageAndOpen" Then
		
		// 
		DeleteFileWithoutConfirmation(ExecutionParameters.FullFileName);		
		GetFromServerAndRegisterInLocalFilesCache(ExecutionParameters);
		
	ElsIf Result = "OpenExistingFile" Then
		
		If ExecutionParameters.FileData.InWorkingDirectoryForRead <> ExecutionParameters.ForReading Then
			InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
			RegegisterInWorkingDirectory(ExecutionParameters.FileData.Version,
				ExecutionParameters.FullFileName, ExecutionParameters.ForReading, InOwnerWorkingDirectory);
		EndIf;
		
		ExecutionParameters.FileReceived = True;
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
		
	Else // 
		ExecutionParameters.FullFileName = "";
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Checks the maximum length, if necessary - changes the working directory and transfers files.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  FileData  - See FilesOperationsInternalServerCall.FileData
//  FullFileName - String -  full file name.
//  NormalFileName - String - 
//
Procedure CheckFullPathMaxLengthInWorkingDirectory(ResultHandler, FileData, 
	FullFileName, NormalFileName)
	
#If WebClient Then
	ReturnResult(ResultHandler, True);
	Return;
#EndIf
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FullFileName", FullFileName);
	ExecutionParameters.Insert("NormalFileName", NormalFileName);
	
	ExecutionParameters.Insert("DirectoryNamePreviousValue", FileData.OwnerWorkingDirectory);
	ExecutionParameters.Insert("FullPathMaxSize", 260);
	If Lower(FileData.Extension) = "xls" Or Lower(FileData.Extension) = "xlsx" Then
		// 
		ExecutionParameters.FullPathMaxSize = 218;
	EndIf;
	
	MaxFileNameLength = ExecutionParameters.FullPathMaxSize - 5; // 
	If StrLen(ExecutionParameters.FullFileName) <= ExecutionParameters.FullPathMaxSize Then
		ReturnResult(ResultHandler, True);
		Return;
	EndIf;
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'The file path (working directory + file name) is longer than %1 characters:
		           |%2';"),
		ExecutionParameters.FullPathMaxSize,
		ExecutionParameters.FullFileName);
	
	UserDirectoryPath = UserDataDir();
	MaxFileNameLength = ExecutionParameters.FullPathMaxSize - StrLen(UserDirectoryPath);
	
	// 
	If StrLen(ExecutionParameters.NormalFileName) > MaxFileNameLength Then
		MessageText = MessageText + Chars.CR + Chars.CR
			+ NStr("en = 'Please choose a shorter file name.';");
		ReturnResultAfterShowWarning(ResultHandler, MessageText, False);
		Return;
	EndIf;
	
	// 
	// 
	If StrLen(FileData.OwnerWorkingDirectory) > ExecutionParameters.FullPathMaxSize - 5 Then
		MessageText = MessageText + Chars.CR + Chars.CR
			+ NStr("en = 'Please rename the folders or move the current folder to another one.';");
		ReturnResultAfterShowWarning(ResultHandler, MessageText, False);
		Return;
	EndIf;
	
	CheckFullPathMaxLengthInWorkingDirectorySuggestChooseDirectory(ExecutionParameters);
	
EndProcedure

// 
Procedure CheckFullPathMaxLengthInWorkingDirectorySuggestChooseDirectory(ExecutionParameters)
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'The full file path (working directory + file name) is longer than %1 characters:
		|%2
		|
		|Do you want to select a different main working directory?
		|(The working directory content will be moved to the selected directory.)';"),
		ExecutionParameters.FullPathMaxSize, ExecutionParameters.FullFileName);
	Handler = New NotifyDescription("CheckFullPathMaxLengthInWorkingDirectoryStartChooseDirectory", ThisObject, ExecutionParameters);
	ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

// 
Procedure CheckFullPathMaxLengthInWorkingDirectoryStartChooseDirectory(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.No Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	// 
	Title = NStr("en = 'Select another working directory';");
	DirectorySelected1 = ChoosePathToWorkingDirectory(ExecutionParameters.FileData.OwnerWorkingDirectory, Title, True);
	If Not DirectorySelected1 Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.FullFileName = ExecutionParameters.FileData.OwnerWorkingDirectory + ExecutionParameters.NormalFileName;
	
	// 
	If StrLen(ExecutionParameters.FullFileName) <= ExecutionParameters.FullPathMaxSize Then
		Handler = New NotifyDescription("CheckFullPathMaxLengthInWorkingDirectoryAfterMoveWorkingDirectoryContent", ThisObject, ExecutionParameters);
		MoveWorkingDirectoryContent(Handler, ExecutionParameters.DirectoryNamePreviousValue, ExecutionParameters.FileData.OwnerWorkingDirectory);
	Else
		CheckFullPathMaxLengthInWorkingDirectorySuggestChooseDirectory(ExecutionParameters);
	EndIf;
	
EndProcedure

// 
Procedure CheckFullPathMaxLengthInWorkingDirectoryAfterMoveWorkingDirectoryContent(ContentMoved, ExecutionParameters) Export
	
	If ContentMoved Then
		// 
		// 
		// 
		FilesOperationsInternalServerCall.SaveFolderWorkingDirectoryAndReplacePathsInRegister(
			ExecutionParameters.FileData.Owner,
			ExecutionParameters.FileData.OwnerWorkingDirectory,
			ExecutionParameters.DirectoryNamePreviousValue);
	EndIf;
	ReturnResult(ExecutionParameters.ResultHandler, ContentMoved);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Copies all files in the specified folder to another folder.
//
// Parameters:
//   ResultHandler - NotifyDescription
//                        - Undefined - 
//   SourceDirectory  - String -  previous folder name.
//   RecipientDirectory  - String -  the new directory name.
//
Procedure CopyDirectoryContent1(ResultHandler, Val SourceDirectory, Val RecipientDirectory)
	
	Result = New Structure;
	Result.Insert("ErrorOccurred",           False);
	Result.Insert("ErrorFullFileName",   "");
	Result.Insert("ErrorInfo",       "");
	Result.Insert("CopiedFilesAndFolders", New Array);
	Result.Insert("OriginalFilesAndFolders",  New Array);
	
	CopyDirectoryContent(Result, SourceDirectory, RecipientDirectory);
	
	If Result.ErrorOccurred Then
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot copy file
			           |""%1"".
			           |Probably it is locked by another application.
			           |
			           |Do you want to retry?';"),
			Result.ErrorFullFileName);
		
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("ResultHandler", ResultHandler);
		ExecutionParameters.Insert("SourceDirectory", SourceDirectory);
		ExecutionParameters.Insert("RecipientDirectory", RecipientDirectory);
		ExecutionParameters.Insert("Result", Result);
		
		Handler = New NotifyDescription("CopyDirectoryContentAfterRespondQuestion", 
			ThisObject, ExecutionParameters);
		
		ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo);
	Else
		ReturnResult(ResultHandler, Result);
	EndIf;
	
EndProcedure

// 
Procedure CopyDirectoryContentAfterRespondQuestion(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.No Then
		ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters.Result);
	Else
		CopyDirectoryContent1(
			ExecutionParameters.ResultHandler,
			ExecutionParameters.SourceDirectory,
			ExecutionParameters.RecipientDirectory);
	EndIf;
	
EndProcedure

// Copies all files in the specified folder to another folder.
//
// Parameters:
//   Result - Structure -  See CopyDirectoryContent1
//   SourceDirectory  - String -  previous folder name.
//   RecipientDirectory  - String -  the new directory name.
//
Procedure CopyDirectoryContent(Result, SourceDirectory, RecipientDirectory)
	
	RecipientDirectory = CommonClientServer.AddLastPathSeparator(RecipientDirectory);
	SourceDirectory = CommonClientServer.AddLastPathSeparator(SourceDirectory);
	
	CreateDirectory(RecipientDirectory);
	
	Result.CopiedFilesAndFolders.Add(RecipientDirectory);
	Result.OriginalFilesAndFolders.Add(SourceDirectory);
	
	SourceFiles1 = FindFiles(SourceDirectory, "*");
	
	For Each SourceFile2 In SourceFiles1 Do
		
		SourceFullFileName = SourceFile2.FullName;
		SourceFileName2       = SourceFile2.Name;
		FullRecipientFileName = RecipientDirectory + SourceFileName2;
		
		If SourceFile2.IsDirectory() Then
			
			CopyDirectoryContent(Result, SourceFullFileName, FullRecipientFileName);
			If Result.ErrorOccurred Then
				Return;
			EndIf;
			
		Else
			
			Result.OriginalFilesAndFolders.Add(SourceFullFileName);
			
			RecipientFile = New File(FullRecipientFileName);
			If RecipientFile.Exists() Then
				// 
				Result.CopiedFilesAndFolders.Add(FullRecipientFileName);
			Else
				Try
					FileCopy(SourceFullFileName, FullRecipientFileName);
				Except
					Result.ErrorOccurred         = True;
					Result.ErrorInfo     = ErrorInfo();
					Result.ErrorFullFileName = SourceFullFileName;
					Return;
				EndTry;
				Result.CopiedFilesAndFolders.Add(FullRecipientFileName);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Moves all files in the working directory to another directory (including those taken for editing).
//
// Parameters:
//   ResultHandler - NotifyDescription
//                        - Undefined - 
//   SourceDirectory - String -  previous folder name.
//   RecipientDirectory - String -  the new directory name.
//
Procedure MoveWorkingDirectoryContent(ResultHandler, SourceDirectory, RecipientDirectory) Export
	
	// 
	If StrFind(Lower(RecipientDirectory), Lower(SourceDirectory)) <> 0 Then
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The destination working directory
			           |""%1""
			           |is included in the source working directory
			           |""%2"".';"),
			RecipientDirectory,
			SourceDirectory);
		ReturnResultAfterShowWarning(ResultHandler, WarningText, False);
		Return;
	EndIf;
	
	// 
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultHandler", ResultHandler);
	HandlerParameters.Insert("SourceDirectory", SourceDirectory);
	HandlerParameters.Insert("RecipientDirectory", RecipientDirectory);
	Handler = New NotifyDescription("MoveWorkingDirectoryContentAfterCopyToNewDirectory", ThisObject, HandlerParameters);
	
	CopyDirectoryContent1(Handler, SourceDirectory, RecipientDirectory);
	
EndProcedure

// 
Procedure MoveWorkingDirectoryContentAfterCopyToNewDirectory(Result, ExecutionParameters) Export
	
	If Result.ErrorOccurred Then
		// 
		
		Handler = New NotifyDescription(
			"MoveWorkingDirectoryContentAfterCancelAndClearRecipient",
			ThisObject,
			ExecutionParameters);
		
		DeleteDirectoryContent(Handler, Result.CopiedFilesAndFolders); // 
	Else
		// 
		Handler = New NotifyDescription(
			"MoveWorkingDirectoryContentAfterSuccessAndClearSource",
			ThisObject,
			ExecutionParameters);
		
		DeleteDirectoryContent(Handler, Result.OriginalFilesAndFolders);
	EndIf;
	
EndProcedure

// 
Procedure MoveWorkingDirectoryContentAfterCancelAndClearRecipient(RecipientDirectoryCleareed, ExecutionParameters) Export
	
	ReturnResult(ExecutionParameters.ResultHandler, False);
	
EndProcedure

// 
Procedure MoveWorkingDirectoryContentAfterSuccessAndClearSource(SourceDirectoryCleared, ExecutionParameters) Export
	
	If SourceDirectoryCleared Then
		// 
		ReturnResult(ExecutionParameters.ResultHandler, True);
	Else
		// 
		Handler = New NotifyDescription("MoveWorkingDirectoryContentAfterSuccessAndCancelClearing", ThisObject, ExecutionParameters);
		CopyDirectoryContent1(Handler, ExecutionParameters.RecipientDirectory, ExecutionParameters.SourceDirectory);
	EndIf;
	
EndProcedure

// 
Procedure MoveWorkingDirectoryContentAfterSuccessAndCancelClearing(Result, ExecutionParameters) Export
	
	// 
	If Result.ErrorOccurred Then
		// 
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot copy files from directory
			           |""%1""
			           |back to directory
			           |""%2"".';"),
			ExecutionParameters.RecipientDirectory,
			ExecutionParameters.SourceDirectory);
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, WarningText, False);
	Else
		// 
		ReturnResult(ExecutionParameters.ResultHandler, False);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
//
// Parameters:
//   ResultHandler - NotifyDescription
//                        - Undefined - 
//   CopiedFilesAndFolders - Array of String -  file and folder paths.
//
Procedure DeleteDirectoryContent(ResultHandler, CopiedFilesAndFolders)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("CopiedFilesAndFolders", CopiedFilesAndFolders);
	DeleteDirectoryContentStart(ExecutionParameters);
	
EndProcedure

// 
Procedure DeleteDirectoryContentStart(ExecutionParameters)
	
	UpperBound = ExecutionParameters.CopiedFilesAndFolders.Count() - 1;
	For IndexOf = 0 To UpperBound Do
		Path = ExecutionParameters.CopiedFilesAndFolders[UpperBound - IndexOf];
		File = New File(Path);
		If Not File.Exists() Then
			Continue; // 
		EndIf;
		
		Try
			If File.IsFile() And File.GetReadOnly() Then
				File.SetReadOnly(False);
			EndIf;
			DeleteFiles(Path);
		Except
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot delete the file in the working directory:
					|""%1"".
					|It might be locked by another application.
					|
					|%2';"),
				Path, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", MessageText,, True);
		EndTry;
	EndDo;
	
	ReturnResult(ExecutionParameters.ResultHandler, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Import with auxiliary operations (checking the size limit, deleting files, and showing
// errors during import).
//
// Parameters:
//  ExecutionParameters - See FilesImportParameters.
//
Procedure ExecuteFilesImport(Val ExecutionParameters) Export
	
	InternalParameters = CommonClient.CopyRecursive(ExecutionParameters);
	Handler = New NotifyDescription("FilesImportAfterCheckSizes", ThisObject, InternalParameters);
	CheckMaxFilesSize(Handler, InternalParameters);
	
EndProcedure

// 
Procedure FilesImportAfterCheckSizes(Result, ExecutionParameters) Export
	
	If Result.Success = False Then
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("TotalFilesCount", Result.TotalFilesCount);
	If ExecutionParameters.TotalFilesCount = 0 Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, NStr("en = 'No files to add';"), Undefined);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("FirstFolderWithSameName", Undefined);
	ExecutionParameters.Insert("FolderForAddingCurrent", Undefined);
	ExecutionParameters.Insert("SelectedFilesInBoundary", ExecutionParameters.SelectedFiles.Count()-1);
	ExecutionParameters.Insert("SelectedFilesIndex", -1);
	ExecutionParameters.Insert("Indicator", 0);
	ExecutionParameters.Insert("Counter", 0);
	ExecutionParameters.Insert("FilesArray", New Array);
	ExecutionParameters.Insert("ArrayOfFilesNamesWithErrors", New Array);
	ExecutionParameters.Insert("AllFilesStructureArray", New Array);
	ExecutionParameters.Insert("AllFoldersArray", New Array);
	ExecutionParameters.Insert("FilesArrayOfThisDirectory", Undefined);
	ExecutionParameters.Insert("FolderName", Undefined);
	ExecutionParameters.Insert("Path", Undefined);
	ExecutionParameters.Insert("FolderAlreadyFound", Undefined);
	
	CompletionHandler = New NotifyDescription("ImportFilesLoopContinueImportAfterRecurringQuestions", ThisObject);
	RegisterCompletionHandler(ExecutionParameters, CompletionHandler);
	FilesImportLoop(ExecutionParameters);
	
EndProcedure

// 
Procedure FilesImportLoop(ExecutionParameters)
	
	ExecutionParameters.SelectedFilesIndex = ExecutionParameters.SelectedFilesIndex + 1;
	For IndexOf = ExecutionParameters.SelectedFilesIndex To ExecutionParameters.SelectedFilesInBoundary Do
		ExecutionParameters.SelectedFilesIndex = IndexOf;
		FileName = ExecutionParameters.SelectedFiles[IndexOf];
		
		SelectedFile = New File(FileName.Value);
		
		DirectorySelected = False;
		If SelectedFile.Exists() Then
			DirectorySelected = SelectedFile.IsDirectory();
		EndIf;
		
		If DirectorySelected Then
			ExecutionParameters.Path = FileName.Value;
			ExecutionParameters.FilesArrayOfThisDirectory = FindFilesPseudo(ExecutionParameters.PseudoFileSystem, ExecutionParameters.Path);
			
			ExecutionParameters.FolderName = SelectedFile.Name;
			
			ExecutionParameters.FolderAlreadyFound = False;
			
			If FilesOperationsInternalServerCall.HasFolderWithThisName(
					ExecutionParameters.FolderName,
					ExecutionParameters.FilesGroup,
					ExecutionParameters.FirstFolderWithSameName) Then
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Folder ""%1"" already exists.
					           |
					           |Do you want to continue the upload?';"),
					ExecutionParameters.FolderName);
				Handler = New NotifyDescription("FilesImportLoopAfterRespondQuestionContinue", ThisObject, ExecutionParameters);
				ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo);
				Return;
			EndIf;
			FilesImportLoopContinueImport(ExecutionParameters);
			If ExecutionParameters.AsynchronousDialog.Open = True Then
				Return;
			EndIf;
		Else
			ExecutionParameters.FilesArray.Add(SelectedFile);
		EndIf;
	EndDo;
	
	If ExecutionParameters.FilesArray.Count() <> 0 Then
		CompletionHandler = New NotifyDescription("ImportFilesAfterLoopAfterRecurringQuestions", ThisObject);
		RegisterCompletionHandler(ExecutionParameters, CompletionHandler);
		ImportFilesRecursively(ExecutionParameters.Owner, ExecutionParameters.FilesArray, ExecutionParameters);
		
		If ExecutionParameters.AsynchronousDialog.Open = True Then
			Return;
		EndIf;
	EndIf;
	
	FilesImportAfterLoopFollowUp(ExecutionParameters);
	
EndProcedure

// 
Procedure FilesImportLoopAfterRespondQuestionContinue(Response, ExecutionParameters) Export
	
	If Response <> DialogReturnCode.No Then
		FilesImportLoopContinueImport(ExecutionParameters);
	EndIf;
	
	FilesImportLoop(ExecutionParameters);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * AllFoldersArray - Array
//
Procedure FilesImportLoopContinueImport(ExecutionParameters)
	
	If Not ExecutionParameters.FolderAlreadyFound Then
		PathSeparator = GetPathSeparator();
		WorkingDirectory  = ExecutionParameters.Path + ?(Right(ExecutionParameters.Path, 1) = PathSeparator, "", PathSeparator);
		If FilesOperationsInternalClientCached.IsDirectoryFiles(ExecutionParameters.Owner) Then
			ExecutionParameters.FolderForAddingCurrent = FilesOperationsInternalServerCall.CreateFilesFolder(
				ExecutionParameters.FolderName, ExecutionParameters.Owner, , , WorkingDirectory);
		Else		
			ExecutionParameters.FolderForAddingCurrent = ExecutionParameters.Owner;
			ExecutionParameters.FilesGroup = FilesOperationsInternalServerCall.CreateFilesFolder(
				ExecutionParameters.FolderName, ExecutionParameters.Owner, , ExecutionParameters.FilesGroup, WorkingDirectory);
		EndIf;	
	EndIf;
	
	// 
	ImportFilesRecursively(ExecutionParameters.FolderForAddingCurrent, ExecutionParameters.FilesArrayOfThisDirectory, ExecutionParameters);
	If ExecutionParameters.AsynchronousDialog.Open = True Then
		Return;
	EndIf;
	
	ExecutionParameters.AllFoldersArray.Add(ExecutionParameters.Path);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * AllFoldersArray - Array
//
Procedure ImportFilesLoopContinueImportAfterRecurringQuestions(Result, ExecutionParameters) Export
	
	ExecutionParameters.AsynchronousDialog.Open = False;
	ExecutionParameters.AllFoldersArray.Add(ExecutionParameters.Path);
	FilesImportLoop(ExecutionParameters);
	
EndProcedure

// 
Procedure ImportFilesAfterLoopAfterRecurringQuestions(Result, ExecutionParameters) Export
	
	FilesImportAfterLoopFollowUp(ExecutionParameters);
	
EndProcedure

// 
Procedure FilesImportAfterLoopFollowUp(ExecutionParameters)
	
	If ExecutionParameters.AllFilesStructureArray.Count() > 1 Then
		StateText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The upload is completed. Files uploaded: %1.';"), String(ExecutionParameters.AllFilesStructureArray.Count()) );
		ShowUserNotification(StateText);
	EndIf;
	
	If ExecutionParameters.ShouldDeleteAddedFiles = True Then
		DeleteFilesAfterAdd(ExecutionParameters.AllFilesStructureArray, ExecutionParameters.AllFoldersArray);
	EndIf;
	
	If ExecutionParameters.AllFilesStructureArray.Count() = 1 Then
		Item0 = ExecutionParameters.AllFilesStructureArray[0];
		Ref = GetURL(Item0.File);
		ShowUserNotification(
			NStr("en = 'Updated:';"),
			Ref,
			Item0.File,
			PictureLib.DialogInformation);
	EndIf;
	
	// 
	If ExecutionParameters.ArrayOfFilesNamesWithErrors.Count() <> 0 Then
		Parameters = New Structure;
		Parameters.Insert("ArrayOfFilesNamesWithErrors", ExecutionParameters.ArrayOfFilesNamesWithErrors);
		
		OpenForm("DataProcessor.FilesOperations.Form.ReportForm", Parameters);
	EndIf;
	
	If ExecutionParameters.SelectedFiles.Count() <> 1 Then
		ExecutionParameters.FolderForAddingCurrent = Undefined;
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	
EndProcedure

// Deletes files after importing or uploading.
Procedure DeleteFilesAfterAdd(AllFilesStructureArray, AllFoldersArray)
	
	For Each Item In AllFilesStructureArray Do
		SelectedFile = New File(Item.FileName);
		Try
			SelectedFile.SetReadOnly(False);
			DeleteFiles(SelectedFile.FullName);
		Except
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot delete the file after it was added to the application:
					|""%1"".
					|It might be locked by another application.
					|
					|%2';"),
				SelectedFile.FullName, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", MessageText,, True);
		EndTry;	
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
// 
// Parameters:
//   ResultHandler - NotifyDescription
//                        - Undefined - 
//   FileData  - Structure
//   UUID - UUID -  id of the form..
//
Procedure SaveAs(ResultHandler, FileData, UUID) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("UUID", UUID);
	
	If FileSystemExtensionAttached1() Then
		SaveAsWithExtension(ExecutionParameters);
	Else
		SaveAsWithoutExtension(ExecutionParameters);
	EndIf;
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure SaveAsWithExtension(ExecutionParameters)
	
	// 
	ExecutionParameters.Insert("PathToFileInCache", "");
	If ExecutionParameters.FileData.CurrentUserEditsFile Then
		InWorkingDirectoryForRead = True;
		InOwnerWorkingDirectory = False;
		ExecutionParameters.Insert("FullFileName", "");
		
		FileInWorkingDirectory = FileInLocalFilesCache(ExecutionParameters.FileData, ExecutionParameters.FileData.Version, ExecutionParameters.FullFileName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
		If FileInWorkingDirectory Then
			
			FileDateInDatabase = ExecutionParameters.FileData.UniversalModificationDate;
			
			VersionFile = New File(ExecutionParameters.FullFileName);
			FileDateOnHardDrive = VersionFile.GetModificationUniversalTime();
			
			If FileDateOnHardDrive > FileDateInDatabase Then // 
				FormOpenParameters = New Structure;
				FormOpenParameters.Insert("File", ExecutionParameters.FullFileName);
				
				Message = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'The local copy of file ""%1""
					           |was modified later than the file in the application.
					           |The local copy might have been edited.';"),
					String(ExecutionParameters.FileData.Ref));
				
				FormOpenParameters.Insert("Message", Message);
				
				Handler = New NotifyDescription("SaveAsWithExtensionAfterRespondQuestionDateNewer", ThisObject, ExecutionParameters);
				OpenForm("DataProcessor.FilesOperations.Form.FileCreationModeForSaveAs", FormOpenParameters, , , , , Handler, FormWindowOpeningMode.LockWholeInterface);
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	SaveAsWithExtensionFollowUp(ExecutionParameters);
	
EndProcedure

// 
Procedure SaveAsWithExtensionAfterRespondQuestionDateNewer(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Cancel Or Response = Undefined Then
		ReturnResult(ExecutionParameters.ResultHandler, "");
		Return;
	EndIf;
	
	If Response = 1 Then // 
		ExecutionParameters.PathToFileInCache = ExecutionParameters.FullFileName;
	EndIf;
	
	SaveAsWithExtensionFollowUp(ExecutionParameters);
	
EndProcedure

// 
Procedure SaveAsWithExtensionFollowUp(ExecutionParameters)
	
	ExecutionParameters.Insert("ChoicePath", ExecutionParameters.FileData.FolderForSaveAs);
	If ExecutionParameters.ChoicePath = Undefined Or ExecutionParameters.ChoicePath = "" Then
		ExecutionParameters.ChoicePath = MyDocumentsDirectory();
	EndIf;
	
	ExecutionParameters.Insert("SaveDecrypted", False);
	ExecutionParameters.Insert("EncryptedFilesExtension", "");
	
	If ExecutionParameters.FileData.Encrypted Then
		Handler = New NotifyDescription("SaveAsWithExtensionAfterSaveModeChoice",
			ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SelectEncryptedFileSaveMode", , , , , ,
			Handler, FormWindowOpeningMode.LockWholeInterface);
	Else
		SaveAsWithExtensionAfterSaveModeChoice(-1, ExecutionParameters);
	EndIf;
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure SaveAsWithExtensionAfterSaveModeChoice(Result, ExecutionParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ExecutionParameters.EncryptedFilesExtension = Result.EncryptedFilesExtension;
		
		If Result.SaveDecrypted = 1 Then
			ExecutionParameters.SaveDecrypted = True;
		Else
			ExecutionParameters.SaveDecrypted = False;
		EndIf;
		
	ElsIf Result <> -1 Then
		ReturnResult(ExecutionParameters.ResultHandler, "");
		Return;
	EndIf;
	
	If Not ExecutionParameters.SaveDecrypted Then
		SaveAsWithExtensionAfterDecryption(-1, ExecutionParameters);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ReturnStructure = FilesOperationsInternalServerCall.FileDataAndBinaryData(ExecutionParameters.FileData.Version,, 
		ExecutionParameters.UUID);
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",              NStr("en = 'Decrypt file';"));
	DataDetails.Insert("DataTitle",       NStr("en = 'File';"));
	DataDetails.Insert("Data",                ReturnStructure.BinaryData);
	DataDetails.Insert("Presentation",         ExecutionParameters.FileData.Ref);
	DataDetails.Insert("Object",                ExecutionParameters.FileData.Ref);
	DataDetails.Insert("EncryptionCertificates", ExecutionParameters.FileData.Ref);
	DataDetails.Insert("NotifyOnCompletion",   False);
	
	FollowUpHandler = New NotifyDescription("SaveAsWithExtensionAfterDecryption", ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure SaveAsWithExtensionAfterDecryption(DataDetails, ExecutionParameters) Export
	
	If DataDetails <> -1 Then
		If Not DataDetails.Success Then
			ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
			Return;
		EndIf;
	
		If TypeOf(DataDetails.DecryptedData) = Type("BinaryData") Then
			FileAddress = PutToTempStorage(DataDetails.DecryptedData,
				ExecutionParameters.UUID);
		Else
			FileAddress = DataDetails.DecryptedData;
		EndIf;
	Else
		If ExecutionParameters.FileData.Property("RefToBinaryFileData") Then
			FileAddress = ExecutionParameters.FileData.RefToBinaryFileData;
			ExecutionParameters.FileData.Insert("FullVersionDescription", ExecutionParameters.FileData.Description);
		Else
			FileAddress = ExecutionParameters.FileData.CurrentVersionURL;
			If ExecutionParameters.FileData.CurrentVersion <> ExecutionParameters.FileData.Version Then
				FileAddress = FilesOperationsInternalServerCall.GetURLToOpen(
					ExecutionParameters.FileData.Version, ExecutionParameters.UUID);
			EndIf;
		EndIf;
	EndIf;
	
	NameWithExtension = CommonClientServer.GetNameWithExtension(
		ExecutionParameters.FileData.FullVersionDescription, ExecutionParameters.FileData.Extension);
	
	Extension = ExecutionParameters.FileData.Extension;
	
	If ExecutionParameters.FileData.Encrypted
	   And Not ExecutionParameters.SaveDecrypted Then
		
		If Not IsBlankString(ExecutionParameters.EncryptedFilesExtension) Then
			NameWithExtension = NameWithExtension + "." + ExecutionParameters.EncryptedFilesExtension;
			Extension = ExecutionParameters.EncryptedFilesExtension;
		EndIf;
	EndIf;
	
	SelectingFile = New FileDialog(FileDialogMode.Save);
	SelectingFile.Multiselect = False;
	SelectingFile.FullFileName = NameWithExtension;
	SelectingFile.DefaultExt = Extension;
	Filter = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'All files (*.%1)|*.%1';"), Extension);
	SelectingFile.Filter = Filter;
	SelectingFile.Directory = ExecutionParameters.ChoicePath;
	
	If Not SelectingFile.Choose() Then
		ReturnResult(ExecutionParameters.ResultHandler, New Structure);
		Return;
	EndIf;
	
	FullFileName = SelectingFile.FullFileName;
	
	File = New File(FullFileName);
	
	If File.Exists() Then
		If ExecutionParameters.PathToFileInCache <> FullFileName Then
			Try
				File.SetReadOnly(False);
				DeleteFiles(SelectingFile.FullFileName);
			Except
				EventLogClient.AddMessageForEventLog(EventLogEvent(),
					"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
			EndTry;	
		EndIf;
	EndIf;
	
	If ExecutionParameters.PathToFileInCache <> "" Then
		If ExecutionParameters.PathToFileInCache <> FullFileName Then
			FileCopy(ExecutionParameters.PathToFileInCache, SelectingFile.FullFileName);
		EndIf;
	Else
		TransmittedFiles = New Array;
		LongDesc = New TransferableFileDescription(FullFileName, FileAddress);
		TransmittedFiles.Add(LongDesc);
		
		PathToFile = File.Path;
		PathToFile = CommonClientServer.AddLastPathSeparator(PathToFile);
		
		If GetFiles(TransmittedFiles,, PathToFile, False) Then
			
			// 
			If IsTempStorageURL(FileAddress) Then
				DeleteFromTempStorage(FileAddress);
			EndIf;
			
			SetModificationUniversalTime(FullFileName, 
				ExecutionParameters.FileData.UniversalModificationDate);
			
		EndIf;
	EndIf;
	
	ShowUserNotification(NStr("en = 'File saved';"), , FullFileName);
	
	ChoicePathPrevious = ExecutionParameters.ChoicePath;
	ExecutionParameters.ChoicePath = File.Path;
	If ChoicePathPrevious <> ExecutionParameters.ChoicePath Then
		CommonServerCall.CommonSettingsStorageSave("ApplicationSettings", "FolderForSaveAs", ExecutionParameters.ChoicePath);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, New Structure("FullFileName", FullFileName));
	
EndProcedure

// 
Procedure SaveAsWithoutExtension(ExecutionParameters)
	
	ExecutionParameters.Insert("SaveDecrypted", False);
	ExecutionParameters.Insert("EncryptedFilesExtension", "");
	
	If ExecutionParameters.FileData.Encrypted Then
		Handler = New NotifyDescription("SaveAsWithoutExtensionAfterSaveModeChoice",
			ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SelectEncryptedFileSaveMode", , , , , ,
			Handler, FormWindowOpeningMode.LockWholeInterface);
	Else
		SaveAsWithoutExtensionAfterSaveModeChoice(-1, ExecutionParameters);
	EndIf;
	
EndProcedure

// 
Procedure SaveAsWithoutExtensionAfterSaveModeChoice(Result, ExecutionParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ExecutionParameters.EncryptedFilesExtension = Result.EncryptedFilesExtension;
		
		If Result.SaveDecrypted = 1 Then
			ExecutionParameters.SaveDecrypted = True;
		Else
			ExecutionParameters.SaveDecrypted = False;
		EndIf;
		
	ElsIf Result <> -1 Then
		ReturnResult(ExecutionParameters.ResultHandler, "");
		Return;
	EndIf;
	
	FillTemporaryFormID(ExecutionParameters.UUID, ExecutionParameters);
	
	Handler = New NotifyDescription("SaveAsWithoutExtensionCompletion", ThisObject, ExecutionParameters);
	OpenFileWithoutExtension(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID,
		False, ExecutionParameters.SaveDecrypted, ExecutionParameters.EncryptedFilesExtension);
	
EndProcedure

// 
Procedure SaveAsWithoutExtensionCompletion(Result, ExecutionParameters) Export
	
	ClearTemporaryFormID(ExecutionParameters);
	
	If Result <> True Then
		Return;
	EndIf;
	
	If Not ExecutionParameters.SaveDecrypted
	   And ExecutionParameters.FileData.Encrypted
	   And ValueIsFilled(ExecutionParameters.EncryptedFilesExtension) Then
		
		Extension = ExecutionParameters.EncryptedFilesExtension;
	Else
		Extension = ExecutionParameters.FileData.Extension;
	EndIf;
	
	FileName = CommonClientServer.GetNameWithExtension(
		ExecutionParameters.FileData.FullVersionDescription, Extension);
	
	ReturnResult(ExecutionParameters.ResultHandler, New Structure("FullFileName", FileName));
	
EndProcedure

// The continuation of the procedure, Remotevalidation.Sobrenaturales.
Procedure SaveFileAsAfterSave(Result, CompletionHandler) Export
	
	If CompletionHandler = Undefined Then
		Return;
	EndIf;
	
	PathToFile = "";
	If TypeOf(Result) = Type("Structure")
		And Result.Property("FullFileName") Then
		
		PathToFile = Result.FullFileName;
	EndIf;
	
	ExecuteNotifyProcessing(CompletionHandler, PathToFile);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Shows a reminder - if the setting is enabled.
//
// Parameters:
//   ResultHandler - NotifyDescription
//                        - Undefined - 
//
Procedure ShowReminderBeforePutFile(ResultHandler)
	
	PersonalSettings = PersonalFilesOperationsSettings();
	If PersonalSettings.ShowTooltipsOnEditFiles = True Then
		If Not FileSystemExtensionAttached1() Then
			ReminderText = 
				NStr("en = 'You will be prompted to select a file
				|to commit.
				|
				|Please select the file from the directory
				|that you specified when you started editing the file.';");
				
			Buttons = New ValueList;
			Buttons.Add("Continue", NStr("en = 'Continue';"));
			Buttons.Add("Cancel", NStr("en = 'Cancel';"));
			ReminderParameters = New Structure;
			ReminderParameters.Insert("Picture", PictureLib.DialogInformation);
			ReminderParameters.Insert("CheckBoxText",
				NStr("en = 'Do not show this message again';"));
			ReminderParameters.Insert("Title",
				NStr("en = 'Store file';"));
			StandardSubsystemsClient.ShowQuestionToUser(
				ResultHandler, ReminderText, Buttons, ReminderParameters);
			Return;
		EndIf;
	EndIf;
	ReturnResult(ResultHandler, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Check the file size limit.
// Returns False if there are files that exceed the size limit,
// and the user selected "Cancel"in the warning dialog about the presence of such files.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  CheckParameters - Structure:
//    * SelectedFiles - Array -  array of "File" objects.
//    * Recursively - Boolean -  recursively crawl the subdirectories.
//    * PseudoFileSystem - Map -  for a row (directory), returns an array
//                                             of rows (subdirectories and files).
//
Procedure CheckMaxFilesSize(ResultHandler, CheckParameters)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("TotalFilesCount", 0);
	ExecutionParameters.Insert("Success", False);
	
	ArrayOfTooBigFiles = New Array;
	
	Path = "";
	
	FilesArray = New Array;
	
	For Each FileName In CheckParameters.SelectedFiles Do
		
		Path = FileName.Value;
		SelectedFile = New File(Path);
		
		SelectedFile = New File(FileName.Value);
		DirectorySelected = False;
		
		If SelectedFile.Exists() Then
			DirectorySelected = SelectedFile.IsDirectory();
		EndIf;
		
		If DirectorySelected Then
			FilesArrayOfThisDirectory = FindFilesPseudo(CheckParameters.PseudoFileSystem, Path);
			FindTooBigFiles(FilesArrayOfThisDirectory, ArrayOfTooBigFiles, CheckParameters.Recursively, 
				ExecutionParameters.TotalFilesCount, CheckParameters.PseudoFileSystem);
		Else
			FilesArray.Add(SelectedFile);
		EndIf;
	EndDo;
	
	If FilesArray.Count() <> 0 Then
		FindTooBigFiles(FilesArray, ArrayOfTooBigFiles, CheckParameters.Recursively, 
			ExecutionParameters.TotalFilesCount, CheckParameters.PseudoFileSystem);
	EndIf;
	
	// 
	If ArrayOfTooBigFiles.Count() <> 0 Then 
		TooBigFiles = New ValueList;
		Parameters = New Structure;
		
		For Each File In ArrayOfTooBigFiles Do
			BigFile = New File(File);
			FileSizeInMB = Int(BigFile.Size() / (1024 * 1024));
			StringText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 (%2 MB)';"), String(File), String(FileSizeInMB));
			TooBigFiles.Add(StringText);
		EndDo;
		
		Parameters.Insert("TooBigFiles", TooBigFiles);
		Parameters.Insert("Title", NStr("en = 'File upload warning';"));
		
		Handler = New NotifyDescription("CheckFileSizeLimitAfterRespondQuestion", ThisObject, ExecutionParameters);
		OpenForm("DataProcessor.FilesOperations.Form.QuestionOnFileImport", Parameters, , , , , Handler, FormWindowOpeningMode.LockWholeInterface);
		Return;
	EndIf;
	
	ExecutionParameters.Success = True;
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	
EndProcedure

// 
Procedure CheckFileSizeLimitAfterRespondQuestion(Response, ExecutionParameters) Export
	
	ExecutionParameters.Success = (Response = DialogReturnCode.OK);
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Shows a reminder - if the setting is enabled.
//
// Parameters:
//   ResultHandler - NotifyDescription
//                        - Undefined - 
//
Procedure ShowInformationFileWasNotModified(ResultHandler)
	
	PersonalSettings = PersonalFilesOperationsSettings();
	If PersonalSettings.ShowFileNotModifiedFlag Then
		ReminderText = NStr("en = 'Cannot create a new version because the file has not been modified. The comment is discarded.';");
		Buttons = QuestionDialogMode.OK;
		ReminderParameters = New Structure;
		ReminderParameters.Insert("LockWholeInterface", True);
		ReminderParameters.Insert("Picture", PictureLib.DialogInformation);
		ReminderParameters.Insert("CheckBoxText",
			NStr("en = 'Do not show this message again';"));
		ReminderParameters.Insert("Title",
			NStr("en = 'Information';"));
		StandardSubsystemsClient.ShowQuestionToUser(
			ResultHandler, ReminderText, Buttons, ReminderParameters);
	Else
		ReturnResult(ResultHandler, Undefined);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
Procedure EndEditAndNotifyCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		Notify("Write_File", FileWriteNotificationParameters("EditFinished"), ExecutionParameters.CommandParameter);
		NotifyChanged(ExecutionParameters.CommandParameter);
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), ExecutionParameters.CommandParameter);
		Notify("Write_File", FileWriteNotificationParameters("VersionSaved"), ExecutionParameters.CommandParameter);
		
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Result);
	
EndProcedure

// Saves the edited files to the IB and removes the lock.
//
// Parameters:
//   Parameters - See FileUpdateParameters.
//
Procedure FinishEditByRefsWithNotification(Parameters) Export
	
	If TypeOf(Parameters.FilesArray) <> Type("Array") Then
		ReturnResult(Parameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	Handler = New NotifyDescription("FinishEditByRefsAfterInstallExtension", ThisObject, Parameters);
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// 
Procedure FinishEditByRefsAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FilesData", New Array);
	FilesOperationsInternalServerCall.GetDataForFilesArray(ExecutionParameters.FilesArray, ExecutionParameters.FilesData);
	
	// 
	FilesData = ExecutionParameters.FilesData; // Array of See FilesOperationsInternalServerCall.FileData -
	For Each FileData In FilesData Do
		
		HandlerParameters = FileUpdateParameters(Undefined, FileData.Ref, ExecutionParameters.FormIdentifier);
		FillPropertyValues(HandlerParameters, ExecutionParameters);
		HandlerParameters.Insert("FileData", Undefined);
		HandlerParameters.StoreVersions = FileData.StoreVersions;
		HandlerParameters.CurrentUserEditsFile = FileData.CurrentUserEditsFile;
		HandlerParameters.BeingEditedBy = FileData.BeingEditedBy;
		HandlerParameters.CurrentVersionAuthor = FileData.BeingEditedBy;
		HandlerParameters.Encoding = FileData.CurrentVersionEncoding;
		If ExecutionParameters.CanCreateFileVersions Then
			HandlerParameters.CreateNewVersion = ExecutionParameters.StoreVersions;
		Else
			HandlerParameters.CreateNewVersion = False;
		EndIf;
		HandlerParameters.ApplyToAll = True;
		
		If ExtensionInstalled Then
			FinishEditWithExtension(HandlerParameters);
		Else
			FinishEditWithoutExtension(HandlerParameters);
		EndIf;
	EndDo;
	
	ShowUserNotification(NStr("en = 'Commit files';"),,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Commit files (%1 of %2).';"),
			ExecutionParameters.FilesData.Count(),
			ExecutionParameters.FilesArray.Count()),
			PictureLib.DialogInformation);
	
	ResultHandler = New NotifyDescription("FinishEditFilesArrayWithNotificationCompletion", ThisObject, ExecutionParameters);
	ReturnResult(ResultHandler, True);

EndProcedure

Procedure FinishEditFilesArrayWithNotificationCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		
		For Each FileRef In ExecutionParameters.FilesArray Do
			
			Notify("Write_File", FileWriteNotificationParameters("EditFinished"), FileRef);
			NotifyChanged(FileRef);
			Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), FileRef);
			Notify("Write_File", FileWriteNotificationParameters("VersionSaved"), FileRef);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds files by dragging and dropping them to the list of files.
//
// Parameters:
//  FileOwner      - AnyRef -  file owner.
//  FormIdentifier - Unique form identifier.
//  FileNamesArray   - Array of String - 
//
Procedure AddFilesWithDrag(Val FileOwner, Val FormIdentifier, Val FileNamesArray) Export
	
	AttachedFilesArray = New Array;
	PutSelectedFilesInStorage(
		FileNamesArray,
		FileOwner,
		AttachedFilesArray,
		FormIdentifier);
	
	If AttachedFilesArray.Count() = 1 Then
		AttachedFile = AttachedFilesArray[0];
		
		ShowUserNotification(
			NStr("en = 'Create';"),
			GetURL(AttachedFile),
			AttachedFile,
			PictureLib.DialogInformation);
		
		FormParameters = New Structure("AttachedFile, IsNew", AttachedFile, True);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFile", FormParameters, , AttachedFile);
	EndIf;
	
	If AttachedFilesArray.Count() > 0 Then
		NotifyChanged(AttachedFilesArray[0]);
		NotifyChanged(FileOwner);
		FileWriteNotificationParameters = FileWriteNotificationParameters();
		FileWriteNotificationParameters.IsNew = True;
		FileWriteNotificationParameters.Owner = FileOwner;
		FileWriteNotificationParameters.FileOwner = FileWriteNotificationParameters.Owner;
		Notify("Write_File", FileWriteNotificationParameters, AttachedFilesArray);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Blocks the file for editing and opens it.
Procedure EditWithNotification(ResultHandler, ObjectRef,
	UUID = Undefined, OwnerWorkingDirectory = Undefined) Export
	
	If ObjectRef = Undefined Then
		ReturnResult(ResultHandler, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("ObjectRef", ObjectRef);
	Handler = New NotifyDescription("EditWithNotificationCompletion", ThisObject, ExecutionParameters);
	EditFileByRef(Handler, ObjectRef, UUID, OwnerWorkingDirectory);
	
EndProcedure

// 
Procedure EditWithNotificationCompletion(FileEdited, ExecutionParameters) Export
	
	If FileEdited Then
		NotifyChanged(ExecutionParameters.ObjectRef);
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), ExecutionParameters.ObjectRef);
		Notify("Write_File", FileWriteNotificationParameters("FileWasEdited"), ExecutionParameters.ObjectRef);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Locks a file or multiple files.
//
// Parameters:
//   ResultHandler - NotifyDescription
//                        - Undefined - 
//   CommandParameter - 
//   
//
Procedure LockWithNotification(ResultHandler, CommandParameter, UUID = Undefined) Export
	
	If CommandParameter = Undefined Then
		ReturnResult(ResultHandler, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("CommandParameter", CommandParameter);
	If TypeOf(CommandParameter) = Type("Array") Then
		Handler = New NotifyDescription("LockWithNotificationFilesArrayCompletion", ThisObject, ExecutionParameters);
		LockFilesByRefs(Handler, CommandParameter);
	Else
		Handler = New NotifyDescription("LockWIthNotificationOneFileCompletion", ThisObject, ExecutionParameters);
		LockFileByRef(Handler, CommandParameter, UUID)
	EndIf;
	
EndProcedure

// 
Procedure LockWithNotificationFilesArrayCompletion(Result, ExecutionParameters) Export
	
	NotifyChanged(Type("CatalogRef.Files"));
	For Each FileRef In ExecutionParameters.CommandParameter Do
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), FileRef);
		NotifyChanged(FileRef);
	EndDo;
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

// 
Procedure LockWIthNotificationOneFileCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		NotifyChanged(ExecutionParameters.CommandParameter);
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), ExecutionParameters.CommandParameter);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Frees a previously occupied file.
//
// Parameters:
//   Parameters - See FileUnlockParameters.
//
Procedure UnlockFileWithNotification(Parameters) Export
	
	If Parameters.ObjectRef = Undefined Then
		ReturnResult(Parameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", Parameters.ResultHandler);
	ExecutionParameters.Insert("CommandParameter", Parameters.ObjectRef);
	If TypeOf(Parameters.ObjectRef) = Type("Array") Then
		Handler = New NotifyDescription("UnlockFileWithNotificationFilesArrayCompletion", ThisObject, ExecutionParameters);
		UnlockFilesByRefs(Handler, Parameters.ObjectRef);
	Else
		Handler = New NotifyDescription("UnlockFileWithNotificationOneFileCompletion", ThisObject, ExecutionParameters);
		UnlockParameters = FileUnlockParameters(Handler, Parameters.ObjectRef);
		UnlockParameters.StoreVersions = Parameters.StoreVersions;
		UnlockParameters.CurrentUserEditsFile = Parameters.CurrentUserEditsFile;
		UnlockParameters.BeingEditedBy = Parameters.BeingEditedBy;
		UnlockParameters.UUID = Parameters.UUID;
		UnlockFile(Parameters);
	EndIf;
	
EndProcedure

// 
Procedure UnlockFileWithNotificationFilesArrayCompletion(Result, ExecutionParameters) Export
	
	NotifyChanged(Type("CatalogRef.Files"));
	For Each FileRef In ExecutionParameters.CommandParameter Do
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), FileRef);
	EndDo;
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

// 
Procedure UnlockFileWithNotificationOneFileCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		
		NotifyChanged(ExecutionParameters.CommandParameter);
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), ExecutionParameters.CommandParameter);
		
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Open the file.
//
// Parameters:
//   ResultHandler - NotifyDescription
//                        - Undefined - 
//   FileData             - Structure
//   UUID - UUID -  shapes.
//
Procedure OpenFileWithNotification(ResultHandler, FileData, UUID = Undefined, ForEditing = True) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("ForEditing", ForEditing);
	ExecutionParameters.Insert("UUID", UUID);
	
	// 
	If Not ExecutionParameters.FileData.Property("Owner") Or Not ValueIsFilled(ExecutionParameters.FileData.Owner) Then
		NotifyDescription = New NotifyDescription("OpenFileAddInSuggested", FilesOperationsInternalClient, ExecutionParameters);
		ShowFileSystemExtensionInstallationQuestion(NotifyDescription);
		Return;
	EndIf;
	
	// 
	If ExecutionParameters.FileData.Version.IsEmpty() And ExecutionParameters.FileData.StoreVersions Then
		Handler = New NotifyDescription("OpenFileWithNotificationCompletion", ThisObject, ExecutionParameters);
		ShowValue(Handler, ExecutionParameters.FileData.Ref);
		Return;
	EndIf;
	
	Handler = New NotifyDescription("OpenFileWithNotificationAfterInstallExtension", ThisObject, ExecutionParameters);
	ShowFileSystemExtensionInstallationQuestion(Handler);
	
EndProcedure

// 
Procedure OpenFileWithNotificationAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	If FileSystemExtensionAttached1() Then
		Handler = New NotifyDescription("OpenFileWithNotificationWithExtensionAfterGetVersionToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(
			Handler,
			ExecutionParameters.FileData,
			"",
			ExecutionParameters.UUID,
			New Structure("OpenFile", True));
	Else
		FillTemporaryFormID(ExecutionParameters.UUID, ExecutionParameters);
		
		Handler = New NotifyDescription("OpenFileWithNotificationCompletion", ThisObject, ExecutionParameters);
		OpenFileWithoutExtension(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID);
	EndIf;
	
EndProcedure

// 
Procedure OpenFileWithNotificationWithExtensionAfterGetVersionToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result.FileReceived = True Then
		FileOnHardDrive = New File(Result.FullFileName);
		FileOnHardDrive.SetReadOnly(Not ExecutionParameters.ForEditing);
		UUID = ?(ExecutionParameters.Property("UUID"),
			ExecutionParameters.UUID, Undefined);
		OpenFileWithApplication(ExecutionParameters.FileData, Result.FullFileName, UUID);
	EndIf;
	
	OpenFileWithNotificationCompletion(Result.FileReceived = True, ExecutionParameters);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure OpenFileWithNotificationCompletion(Result, ExecutionParameters) Export
	
	ClearTemporaryFormID(ExecutionParameters);
	
	If Result <> True Then
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Event", "FileOpened");
	Notify("FileOpened", NotificationParameters, ExecutionParameters.FileData.Ref);
	
EndProcedure


Procedure OpenFileWithoutExtension(Notification, FileData, FormIdentifier,
		WithNotification = True, SaveDecrypted = True, EncryptedFilesExtension = "")
	
	Context = New Structure;
	Context.Insert("Notification",             Notification);
	Context.Insert("FileData",            FileData);
	Context.Insert("FormIdentifier",     FormIdentifier);
	Context.Insert("WithNotification",       WithNotification);
	Context.Insert("SaveDecrypted", SaveDecrypted);
	Context.Insert("EncryptedFilesExtension", EncryptedFilesExtension);
	
	If Context.SaveDecrypted
		And FileData.Encrypted Then
		
		If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ExecuteNotifyProcessing(Context.Notification, False);
			Return;
		EndIf;
		
		ReturnStructure = FilesOperationsInternalServerCall.FileDataAndBinaryData(
			FileData.Version,, FormIdentifier);
		
		DataDetails = New Structure;
		DataDetails.Insert("Operation",              NStr("en = 'Decrypt file';"));
		DataDetails.Insert("DataTitle",       NStr("en = 'File';"));
		DataDetails.Insert("Data",                ReturnStructure.BinaryData);
		DataDetails.Insert("Presentation",         FileData.Ref);
		DataDetails.Insert("Object",                FileData.Ref);
		DataDetails.Insert("EncryptionCertificates", FileData.Ref);
		DataDetails.Insert("NotifyOnCompletion",   False);
		
		FollowUpHandler = New NotifyDescription(
			"OpenFileWithoutExtensionAfterDecryption", ThisObject, Context);
		
		ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
		ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
		Return;
		
	EndIf;
	
	Context.Insert("FileAddress", FileData.RefToBinaryFileData);
	
	OpenFileWithoutExtensionReminder(Context);
	
EndProcedure

// 
Procedure OpenFileWithoutExtensionAfterDecryption(DataDetails, Context) Export
	
	If Not DataDetails.Success Then
		ExecuteNotifyProcessing(Context.Notification, False);
		Return;
	EndIf;
	
	If TypeOf(DataDetails.DecryptedData) = Type("BinaryData") Then
		FileAddress = PutToTempStorage(DataDetails.DecryptedData,
			Context.FormIdentifier);
	Else
		FileAddress = DataDetails.DecryptedData;
	EndIf;
	
	Context.Insert("FileAddress", FileAddress);
	
	OpenFileWithoutExtensionReminder(Context);
	
EndProcedure

// 
Procedure OpenFileWithoutExtensionReminder(Context)
	
	If Context.WithNotification
		And Context.FileData.CurrentUserEditsFile Then
		
		OutputNotificationOnEdit(New NotifyDescription(
		"OpenFileWithoutExtensionFileSending", ThisObject, Context));
	Else
		OpenFileWithoutExtensionFileSending(True, Context);
	EndIf;
	
EndProcedure

// 
Procedure OpenFileWithoutExtensionFileSending(Result, Context) Export
	
	If (TypeOf(Result) = Type("Structure") And Result.Value = "Cancel") Or Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") And Result.Property("NeverAskAgain") And Result.NeverAskAgain Then
		FilesOperationsInternalServerCall.ShowTooltipsOnEditFiles(False);
	EndIf;
	
	If Not Context.SaveDecrypted
		And Context.FileData.Encrypted
		And ValueIsFilled(Context.EncryptedFilesExtension) Then
		
		Extension = Context.EncryptedFilesExtension;
	Else
		Extension = Context.FileData.Extension;
	EndIf;
	
	FileName = CommonClientServer.GetNameWithExtension(
		Context.FileData.FullVersionDescription, Extension);
	
	GetFile(Context.FileAddress, FileName, True);
	
	ExecuteNotifyProcessing(Context.Notification, True);
	
EndProcedure

// Fills in the temporary form ID for cases when you don't need
// to return data in temporary storage to the calling code, such
// as in the Open, open file Catalog procedures in the shared workfile Client module.
//
Procedure FillTemporaryFormID(FormIdentifier, ExecutionParameters)
	
	If ValueIsFilled(FormIdentifier) Then
		Return;
	EndIf;
	
	ExecutionParameters.Insert("TempForm", GetForm("DataProcessor.FilesOperations.Form.QuestionForm")); // 
	FormIdentifier = ExecutionParameters.TempForm.UUID;
	StandardSubsystemsClient.SetFormStorageOption(ExecutionParameters.TempForm, True);
	
EndProcedure

// Cancels storing the temporary ID that was previously filled in.
Procedure ClearTemporaryFormID(ExecutionParameters)
	
	If ExecutionParameters.Property("TempForm") Then
		StandardSubsystemsClient.SetFormStorageOption(ExecutionParameters.TempForm, False);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
Procedure SaveFileChangesWithNotificationCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), ExecutionParameters.CommandParameter);
		Notify("Write_File", FileWriteNotificationParameters("VersionSaved"), ExecutionParameters.CommandParameter);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Result);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
Procedure UpdateFromFileOnHardDriveWithNotification(
	ResultHandler,
	FileData,
	FormIdentifier,
	FileAddingOptions = Undefined) Export
	
	If Not FileSystemExtensionAttached1() Then
		ShowFileSystemExtensionRequiredMessageBox(ResultHandler);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	Handler = New NotifyDescription("UpdateFromFileOnHardDriveWithNotificationCompletion", ThisObject, ExecutionParameters);
	UpdateFromFileOnHardDrive(Handler, FileData, FormIdentifier, FileAddingOptions);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure UpdateFromFileOnHardDriveWithNotificationCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		NotifyChanged(ExecutionParameters.FileData.Ref);
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), ExecutionParameters.FileData.Ref);
		Notify("Write_File", FileWriteNotificationParameters("VersionSaved"), ExecutionParameters.FileData.Ref);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Encrypted file.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  FileData - See FilesOperationsInternalServerCall.FileData
//  UUID - UUID -  the ID of the form.
//
Procedure Encrypt(ResultHandler, FileData, UUID) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("UUID", UUID);
	ExecutionParameters.Insert("Success", False);
	ExecutionParameters.Insert("DataArrayToStoreInDatabase", New Array);
	ExecutionParameters.Insert("ThumbprintsArray", New Array);
	
	If ExecutionParameters.FileData.Encrypted Then
		WarningText = NStr("en = 'File ""%1"" is already encrypted.';");
		WarningText = StrReplace(WarningText, "%1", String(ExecutionParameters.FileData.Ref));
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, WarningText, ExecutionParameters);
		Return;
	EndIf;
	
	If ValueIsFilled(ExecutionParameters.FileData.BeingEditedBy) Then
		WarningText = NStr("en = 'Cannot encrypt the file because it is locked.';");
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, WarningText, ExecutionParameters);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	// 
	
	VersionsArray = FilesOperationsInternalServerCall.FileDataAndURLOfAllFileVersions(ExecutionParameters.FileData.Ref,
		ExecutionParameters.UUID);
	
	If VersionsArray.Count() = 0 Then
		ReturnResult(ExecutionParameters.ResultHandler, False);
		Return;
	EndIf;
	
	ExecutionParameters.DataArrayToStoreInDatabase = New Array;
	
	FilePresentation = String(ExecutionParameters.FileData.Ref);
	If ExecutionParameters.FileData.VersionsCount > 1 Then
		FilePresentation = FilePresentation + " (" + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Versions: %1';"), ExecutionParameters.FileData.VersionsCount) + ")";
	EndIf;
	PresentationsList = New ValueList;
	PresentationsList.Add(ExecutionParameters.FileData.Ref, FilePresentation);
	
	DataSet = New Array;
	
	For Each VersionProperties In VersionsArray Do
		
		CurrentExecutionParameters = New Structure;
		CurrentExecutionParameters.Insert("ExecutionParameters", ExecutionParameters);
		CurrentExecutionParameters.Insert("VersionRef", VersionProperties.VersionRef);
		CurrentExecutionParameters.Insert("FileAddress",   VersionProperties.VersionURL);
		
		DataElement = New Structure;
		DataElement.Insert("Data", VersionProperties.VersionURL);
		
		DataElement.Insert("ResultPlacement", New NotifyDescription(
			"OnGetEncryptedData", ThisObject, CurrentExecutionParameters));
		
		DataSet.Add(DataElement);
	EndDo;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",            NStr("en = 'Encrypt file';"));
	DataDetails.Insert("DataTitle",     NStr("en = 'File';"));
	DataDetails.Insert("DataSet",         DataSet);
	DataDetails.Insert("SetPresentation", NStr("en = 'Files (%1)';"));
	DataDetails.Insert("PresentationsList", PresentationsList);
	DataDetails.Insert("NotifyOnCompletion", False);
	
	FollowUpHandler = New NotifyDescription("AfterFileEncryption", ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Encrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Parameters:
//   CurrentExecutionParameters - Structure:
//     * ExecutionParameters - Structure:
//       ** DataArrayToStoreInDatabase - Array
//
Procedure OnGetEncryptedData(Parameters, CurrentExecutionParameters) Export
	
	ExecutionParameters = CurrentExecutionParameters.ExecutionParameters;
	
	EncryptedData = Parameters.DataDetails.CurrentDataSetItem.EncryptedData;
	If TypeOf(EncryptedData) = Type("BinaryData") Then
		TempStorageAddress = PutToTempStorage(EncryptedData,
			ExecutionParameters.UUID);
	Else
		TempStorageAddress = EncryptedData;
	EndIf;
	
	DataToWriteAtServer = New Structure;
	DataToWriteAtServer.Insert("TempStorageAddress", TempStorageAddress);
	DataToWriteAtServer.Insert("VersionRef", CurrentExecutionParameters.VersionRef);
	DataToWriteAtServer.Insert("FileAddress",   CurrentExecutionParameters.FileAddress);
	DataToWriteAtServer.Insert("TempTextStorageAddress", "");
	
	ExecutionParameters.DataArrayToStoreInDatabase.Add(DataToWriteAtServer);
	
	ExecuteNotifyProcessing(Parameters.Notification, New Structure);
	
EndProcedure

// End of the Encrypt procedure. Called from the electronic Signature subsystem.
Procedure AfterFileEncryption(DataDetails, ExecutionParameters) Export
	
	ExecutionParameters.Success = DataDetails.Success;
	
	If DataDetails.Success Then
		If TypeOf(DataDetails.EncryptionCertificates) = Type("String") Then
			ExecutionParameters.Insert("ThumbprintsArray", GetFromTempStorage(
				DataDetails.EncryptionCertificates));
		Else
			ExecutionParameters.Insert("ThumbprintsArray", DataDetails.EncryptionCertificates);
		EndIf;
		NotifyOfFileChange(ExecutionParameters.FileData);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Decryption of the file.

// Decryption of the file.
//
// Parameters:
//  ResultHandler - NotifyDescription
//                       - Undefined - 
//  FileRef  - CatalogRef.Files -  file.
//  UUID - UUID -  the ID of the form.
//  FileData  - See FilesOperationsInternalServerCall.FileData
//
Procedure Decrypt(ResultHandler, FileRef, UUID, FileData) Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileRef", FileRef);
	ExecutionParameters.Insert("UUID", UUID);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("Success", False);
	ExecutionParameters.Insert("DataArrayToStoreInDatabase", New Array);
	
	// 
	
	VersionsArray = FilesOperationsInternalServerCall.FileDataAndURLOfAllFileVersions(
		ExecutionParameters.FileRef, ExecutionParameters.UUID);
	
	ExecutionParameters.DataArrayToStoreInDatabase = New Array;
	
	ExecutionParameters.Insert("ExtractTextFilesOnServer",
		CommonFilesOperationsSettings().ExtractTextFilesOnServer);
	
	FilePresentation = String(FileData.Ref);
	If FileData.VersionsCount > 1 Then
		FilePresentation = FilePresentation + " (" + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Versions: %1';"), FileData.VersionsCount) + ")";
	EndIf;
	PresentationsList = New ValueList;
	PresentationsList.Add(FileData.Ref, FilePresentation);
	
	EncryptionCertificates = New Array;
	EncryptionCertificates.Add(FileData.Ref);
	
	DataSet = New Array;
	
	For Each VersionProperties In VersionsArray Do
		
		CurrentExecutionParameters = New Structure;
		CurrentExecutionParameters.Insert("ExecutionParameters", ExecutionParameters);
		CurrentExecutionParameters.Insert("VersionRef", VersionProperties.VersionRef);
		CurrentExecutionParameters.Insert("FileAddress",   VersionProperties.VersionURL);
		
		DataElement = New Structure;
		DataElement.Insert("Data", VersionProperties.VersionURL);
		
		DataElement.Insert("ResultPlacement", New NotifyDescription(
			"OnGetDecryptedData", ThisObject, CurrentExecutionParameters));
		
		DataSet.Add(DataElement);
	EndDo;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",              NStr("en = 'Decrypt file';"));
	DataDetails.Insert("DataTitle",       NStr("en = 'File';"));
	DataDetails.Insert("DataSet",           DataSet);
	DataDetails.Insert("SetPresentation",   NStr("en = 'Files (%1)';"));
	DataDetails.Insert("PresentationsList",   PresentationsList);
	DataDetails.Insert("EncryptionCertificates", EncryptionCertificates);
	DataDetails.Insert("NotifyOnCompletion",   False);
	
	FollowUpHandler = New NotifyDescription("AfterFileDecryption", ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Parameters:
//   CurrentExecutionParameters - Structure:
//     * ExecutionParameters - Structure:
//       ** FileData - See FilesOperationsInternalServerCall.FileData
//       ** DataArrayToStoreInDatabase - Array
//
Procedure OnGetDecryptedData(Parameters, CurrentExecutionParameters) Export
	
	ExecutionParameters = CurrentExecutionParameters.ExecutionParameters;
	
	DecryptedData = Parameters.DataDetails.CurrentDataSetItem.DecryptedData;
	If TypeOf(DecryptedData) = Type("BinaryData") Then
		TempStorageAddress = PutToTempStorage(DecryptedData,
			ExecutionParameters.UUID);
		#If Not WebClient Then
			DecodedBinaryData = DecryptedData;
		#EndIf
	Else
		TempStorageAddress = DecryptedData;
		#If Not WebClient Then
			DecodedBinaryData = GetFromTempStorage(TempStorageAddress);
		#EndIf
	EndIf;
	
	TempTextStorageAddress = "";
	#If Not WebClient Then
		If Not ExecutionParameters.ExtractTextFilesOnServer Then
			FullFilePath = GetTempFileName(ExecutionParameters.FileData.Extension);
			DecodedBinaryData.Write(FullFilePath);
			
			TempTextStorageAddress = ExtractTextToTempStorage(FullFilePath, ExecutionParameters.UUID);
			Try
				DeleteFiles(FullFilePath);
			Except
				EventLogClient.AddMessageForEventLog(EventLogEvent(),
					"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
			EndTry;	
		EndIf;
	#EndIf
	
	DataToWriteAtServer = New Structure;
	DataToWriteAtServer.Insert("TempStorageAddress", TempStorageAddress);
	DataToWriteAtServer.Insert("VersionRef", CurrentExecutionParameters.VersionRef);
	DataToWriteAtServer.Insert("FileAddress",   CurrentExecutionParameters.FileAddress);
	DataToWriteAtServer.Insert("TempTextStorageAddress", TempTextStorageAddress);
	ExecutionParameters.DataArrayToStoreInDatabase.Add(DataToWriteAtServer);
	
	ExecuteNotifyProcessing(Parameters.Notification, New Structure);
	
EndProcedure

// Completion of the Decrypt procedure. Called from the electronic Signature subsystem.
Procedure AfterFileDecryption(DataDetails, ExecutionParameters) Export
	
	ExecutionParameters.Success = DataDetails.Success;
	
	If DataDetails.Success Then
		NotifyOfFileChange(ExecutionParameters.FileData);
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, ExecutionParameters);
	
EndProcedure

// Continue with the check Signatures procedure. Called from the electronic Signature subsystem.
Procedure AfterFileDecryptionOnCheckSignature(DataDetails, AdditionalParameters) Export
	
	If Not DataDetails.Success Then
		Return;
	EndIf;
	
	CheckSignaturesAfterPrepareData(DataDetails.DecryptedData, AdditionalParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

////////////////////////////////////////////////////////////////////////////////
// 

// Creates a new file interactively with a dialog for selecting the File creation mode.
//
// Parameters:
//   See FilesOperationsClient.AppendFile
//   ().
//
Procedure AppendFile(
	ResultHandler,
	FileOwner,
	OwnerForm,
	CreateMode = 1,
	AddingOptions = Undefined) Export
	
	ExecutionParameters = New Structure;
	If AddingOptions = Undefined
		Or TypeOf(AddingOptions) = Type("Boolean") Then
		
		ExecutionParameters.Insert("MaximumSize", 0);
		ExecutionParameters.Insert("SelectionDialogFilter",  StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'All files (%1)|%1';"), GetAllFilesMask()));
		ExecutionParameters.Insert("NotOpenCardAfterCreateFromFile", ?(AddingOptions = Undefined, False, AddingOptions));
		
	Else
		ExecutionParameters.Insert("MaximumSize", AddingOptions.MaximumSize);
		ExecutionParameters.Insert("SelectionDialogFilter", AddingOptions.SelectionDialogFilter);
		ExecutionParameters.Insert("NotOpenCardAfterCreateFromFile", AddingOptions.NotOpenCard);
	EndIf;
	
	ExecutionParameters.Insert("ResultHandler", ResultHandler);
	ExecutionParameters.Insert("FileOwner", FileOwner);
	ExecutionParameters.Insert("OwnerForm", OwnerForm);
	ExecutionParameters.Insert("IsFile", True);
	
	Handler = New NotifyDescription("AddAfterCreationModeChoice", ThisObject, ExecutionParameters);
	
	FormParameters = New Structure;
	FormParameters.Insert("CreateMode", CreateMode);
	
	Context = New Structure;
	Context.Insert("FormParameters", FormParameters);
	Context.Insert("Handler", Handler);
	
	FormParameters.Insert("ScanCommandAvailable", ScanAvailable());
	
	OpenForm("Catalog.Files.Form.FormNewItem", FormParameters, , , , , Context.Handler);
	
EndProcedure

Procedure AddFileFromFileSystem(FileOwner, OwnerForm) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler",                    Undefined);
	ExecutionParameters.Insert("FileOwner",                           FileOwner);
	ExecutionParameters.Insert("OwnerForm",                           OwnerForm);
	ExecutionParameters.Insert("IsFile",                                 True);
	
	AddAfterCreationModeChoice(2, ExecutionParameters);
	
EndProcedure

// Creates a new file interactively in the specified way.
//
// Parameters:
//   CreateMode - Number - 
//       
//       
//       
//   ExecutionParameters - Structure -  For types of values and descriptions, see the Workfile Client.Add a file().
//       * Result handler.
//       
//       
//       
//
Procedure AddAfterCreationModeChoice(CreateMode, ExecutionParameters) Export
	
	ExecutionParameters.Insert("NotOpenCardAfterCreateFromFile", True);
	
	If CreateMode = 1 Then // 
		AddBasedOnTemplate(ExecutionParameters);
	ElsIf CreateMode = 2 Then // 
		If FileSystemExtensionAttached1() Then
			AddFormFileSystemWithExtension(ExecutionParameters);
		Else
			AddFromFileSystemWithoutExtension(ExecutionParameters);
		EndIf;
	ElsIf CreateMode = 3 Then // 
		AddingOptions = FilesOperationsClient.AddingFromScannerParameters();
		FillPropertyValues(AddingOptions, ExecutionParameters);
		AddFromScanner(AddingOptions);
	Else
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	EndIf;
	
EndProcedure

// 
Procedure AddBasedOnTemplate(ExecutionParameters) Export
	
	// 
	FormParameters = New Structure;
	FormParameters.Insert("SelectTemplate1", True);
	FormParameters.Insert("CurrentRow", PredefinedValue("Catalog.FilesFolders.Templates"));
	Handler = New NotifyDescription("AddBasedOnTemplateAfterTemplateChoice", ThisObject, ExecutionParameters);
	OpeningMode = FormWindowOpeningMode.LockWholeInterface;
	OpenForm("Catalog.Files.Form.ChoiceForm", FormParameters, , , , , Handler, OpeningMode);
	
EndProcedure

// 
Procedure AddBasedOnTemplateAfterTemplateChoice(Result, ExecutionParameters) Export
	
	If Result = Undefined Then
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CreateMode", "FromTemplate");
	FormParameters.Insert("FilesStorageCatalogName",
		?(ExecutionParameters.Property("FilesStorageCatalogName"),
		ExecutionParameters.FilesStorageCatalogName, 
		FilesOperationsInternalServerCall.FileStoringCatalogName(ExecutionParameters.FileOwner)));
		
	OnCloseNotifyDescription = CompletionHandler(ExecutionParameters.ResultHandler);
	FilesOperationsClient.CopyAttachedFile(ExecutionParameters.FileOwner, Result, FormParameters, OnCloseNotifyDescription); 
	
EndProcedure

// 
Procedure AddFromFileSystemWithoutExtension(ExecutionParameters)
	
	// 
	ChoiceDialog = New FileDialog(FileDialogMode.Open);
	If ExecutionParameters.Property("SelectionDialogFilter") Then
		ChoiceDialog.Filter = ExecutionParameters.SelectionDialogFilter;
	EndIf;
	
	Handler = New NotifyDescription("AddFromFileSystemWithoutFileSystemExtensionAfterImportFile", ThisObject, ExecutionParameters);
	BeginPutFile(Handler, , ChoiceDialog, , ExecutionParameters.OwnerForm.UUID);
	
EndProcedure

// 
Procedure AddFromFileSystemWithoutFileSystemExtensionAfterImportFile(Put, Address, SelectedFileName, ExecutionParameters) Export
	
	If Not Put Then
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("FileAdded", False);
	Result.Insert("FileRef",   Undefined);
	Result.Insert("ErrorText",  "");
	
	PathStructure = CommonClientServer.ParseFullFileName(SelectedFileName);
	If IsBlankString(PathStructure.Extension) Then
		QueryText = NStr("en = 'Select a file with an extension.';");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Retry, NStr("en = 'Select another file';"));
		Buttons.Add(DialogReturnCode.Cancel);
		Handler = New NotifyDescription("AddFromFileSystemWithoutExtensionAfterRespondQuestionContinue", ThisObject, ExecutionParameters);
		ShowQueryBox(Handler, QueryText, Buttons);
		Return;
	EndIf;
	
	If ExecutionParameters.Property("MaximumSize")
		And ExecutionParameters.MaximumSize > 0 Then
		
		FileSize = GetFromTempStorage(Address).Size();
		If FileSize > ExecutionParameters.MaximumSize*1024*1024 Then
			
			ErrorText = NStr("en = 'The file size exceeds %1 MB.';");
			Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, 
				ExecutionParameters.MaximumSize);
			ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, Result.ErrorText, Undefined);
			Return;
			
		EndIf;
		
	EndIf;
	
	// 
	Try
		
		If FilesOperationsInternalClientCached.IsDirectoryFiles(ExecutionParameters.FileOwner) Then
			
			FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion");
			FileInfo1.TempFileStorageAddress = Address;
			FileInfo1.BaseName = PathStructure.BaseName;
			FileInfo1.ExtensionWithoutPoint = CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension);
			Result.FileRef = FilesOperationsInternalServerCall.CreateFileWithVersion(ExecutionParameters.FileOwner, FileInfo1);
			Result.FileAdded = True;
			
		Else
			
			FileParameters = FilesOperationsInternalClientServer.FileAddingOptions();
			FileParameters.FilesOwner = ExecutionParameters.FileOwner;
			FileParameters.BaseName = PathStructure.BaseName;
			FileParameters.ExtensionWithoutPoint = CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension);
			
			Result.FileRef = FilesOperationsInternalServerCall.AppendFile(FileParameters,Address);
			Result.FileAdded = True;
			
		EndIf;
		
	Except
		Result.ErrorText = ErrorCreatingNewFile(ErrorInfo());
	EndTry;
	If Result.ErrorText <> "" Then
		ReturnResultAfterShowWarning(ExecutionParameters.ResultHandler, Result.ErrorText, Undefined);
		Return;
	EndIf;
	
	NotificationParameters = FileWriteNotificationParameters();
	NotificationParameters.Owner = ExecutionParameters.FileOwner;
	NotificationParameters.File = Result.FileRef;
	NotificationParameters.IsNew = True;
	Notify("Write_File", NotificationParameters, Result.FileRef);
	
	ShowUserNotification(
		NStr("en = 'Created:';"),
		GetURL(Result.FileRef),
		Result.FileRef,
		PictureLib.DialogInformation);
	
	If ExecutionParameters.NotOpenCardAfterCreateFromFile <> True Then
		FormParameters = New Structure("OpenCardAfterCreateFile", True);
		OnCloseNotifyDescription = CompletionHandler(ExecutionParameters.ResultHandler);
		FilesOperationsClient.OpenFileForm(Result.FileRef,, FormParameters, OnCloseNotifyDescription);
	Else
		ReturnResult(ExecutionParameters.ResultHandler, Result);
	EndIf;
	
EndProcedure

// 
Procedure AddFromFileSystemWithoutExtensionAfterRespondQuestionContinue(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Retry Then
		AddFromFileSystemWithoutExtension(ExecutionParameters);
	Else
		ReturnResult(ExecutionParameters.ResultHandler, Undefined);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Parameters:
//  Form - ClientApplicationForm
//
Procedure ReadSignaturesCertificates(Form) Export
	
	If Form.DigitalSignatures.Count() = 0 Then
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("Form", Form);
	Context.Insert("ModuleDigitalSignatureClient",
		CommonClient.CommonModule("DigitalSignatureClient"));
	Context.Insert("ModuleDigitalSignatureInternalClientServer",
		CommonClient.CommonModule("DigitalSignatureInternalClientServer"));
	
	If Context.ModuleDigitalSignatureClient.VerifyDigitalSignaturesOnTheServer() Then
		Return;
	EndIf;
	
	BeginAttachingCryptoExtension(New NotifyDescription(
		"ReadSignaturesCertificatesAfterAttachExtension", ThisObject, Context));
	
EndProcedure

// Continue the procedure to read the certificate of Signatures.
Procedure ReadSignaturesCertificatesAfterAttachExtension(Attached, Context) Export
	
	If Not Attached Then
		Return;
	EndIf;
	
	Context.ModuleDigitalSignatureClient.CreateCryptoManager(New NotifyDescription(
			"ReadSignaturesCertificatesAfterCreateCryptoManager", ThisObject, Context),
		"GetCertificates", False);
	
EndProcedure

// Continue the procedure to read the certificate of Signatures.
Procedure ReadSignaturesCertificatesAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager") Then
		Return;
	EndIf;
	
	Context.Insert("IndexOf", -1);
	Context.Insert("CryptoManager", Result);
	ReadSignaturesCertificatesLoopStart(Context);
	
EndProcedure

// Continue the procedure to read the certificate of Signatures.
//
// Parameters:
//   Context - Structure:
//    * Form - ClientApplicationForm
//
Procedure ReadSignaturesCertificatesLoopStart(Context)
	
	If Context.Form.DigitalSignatures.Count() <= Context.IndexOf + 1 Then
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("TableRow", Context.Form.DigitalSignatures[Context.IndexOf]);
	
	If ValueIsFilled(Context.TableRow.Thumbprint) Then
		ReadSignaturesCertificatesLoopStart(Context);
		Return;
	EndIf;
	
	// 
	Signature = GetFromTempStorage(Context.TableRow.SignatureAddress);
	
	If Not ValueIsFilled(Signature) Then
		ReadSignaturesCertificatesLoopStart(Context);
		Return;
	EndIf;
	
	Context.CryptoManager.BeginGettingCertificatesFromSignature(New NotifyDescription(
			"ReadSignaturesCertificatesLoopAfterGetCertificatesFromSignature", ThisObject, Context,
			"ReadSignatureCertificatesLoopAfterGetCertificatesFromSignatureError", ThisObject),
		Signature);
	
EndProcedure

// Continue the procedure to read the certificate of Signatures.
Procedure ReadSignatureCertificatesLoopAfterGetCertificatesFromSignatureError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	ReadSignaturesCertificatesLoopStart(Context);
	
EndProcedure

// Continue the procedure to read the certificate of Signatures.
Procedure ReadSignaturesCertificatesLoopAfterGetCertificatesFromSignature(Certificates, Context) Export
	
	If Certificates.Count() = 0 Then
		ReadSignaturesCertificatesLoopStart(Context);
		Return;
	EndIf;
	
	Try
		If Certificates.Count() = 1 Then
			Certificate = Certificates[0]; // CryptoCertificate
		ElsIf Certificates.Count() > 1 Then
			Certificate = Context.ModuleDigitalSignatureInternalClientServer.CertificatesInOrderToRoot(Certificates)[0]; // CryptoCertificate
		EndIf;
	Except
		ReadSignaturesCertificatesLoopStart(Context);
		Return;
	EndTry;

	Context.Insert("Certificate", Certificate);
	Certificate.BeginUnloading(New NotifyDescription(
		"ReadSignaturesCertificatesLoopAfterExportCertificate", ThisObject, Context,
		"ReadSignatureCertificatesLoopAfterExportCertificateError", ThisObject));
	
EndProcedure

// Continue the procedure to read the certificate of Signatures.
Procedure ReadSignatureCertificatesLoopAfterExportCertificateError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	ReadSignaturesCertificatesLoopStart(Context);
	
EndProcedure

// Continue the procedure to read the certificate of Signatures.
//
// Parameters:
//   Context - Structure:
//    * Form - ClientApplicationForm
//
Procedure ReadSignaturesCertificatesLoopAfterExportCertificate(CertificateData, Context) Export
	
	TableRow = Context.TableRow;
	
	TableRow.Thumbprint = Base64String(Context.Certificate.Thumbprint);
	TableRow.CertificateAddress = PutToTempStorage(CertificateData, Context.Form.UUID);
	TableRow.CertificateOwner = Context.ModuleDigitalSignatureClient.SubjectPresentation(Context.Certificate);
	
	ReadSignaturesCertificatesLoopStart(Context);
	
EndProcedure


// At the end of the Encrypt notifies.
// Parameters:
//  FilesArrayInWorkingDirectoryToDelete - Array -  array of file path strings.
//  FileOwner  - AnyRef -  file owner.
//  FileRef  - CatalogRef.Files -  file.
//
Procedure InformOfEncryption(FilesArrayInWorkingDirectoryToDelete,
                                   FileOwner,
                                   FileRef) Export
	
	NotifyChanged(FileRef);
	Notify("Write_File", FileWriteNotificationParameters("AttachedFileEncrypted"), FileOwner);
	Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), FileRef);
	
	// 
	For Each FullFileName In FilesArrayInWorkingDirectoryToDelete Do
		DeleteFileWithoutConfirmation(FullFileName);
	EndDo;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.InformOfObjectEncryption(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'File: %1';"), FileRef));
	
EndProcedure

// At the end of Decrypt notifies.
// Parameters:
//  FileOwner  - AnyRef -  file owner.
//  FileRef  - CatalogRef.Files -  file.
//
Procedure InformOfDecryption(FileOwner, FileRef) Export
	
	NotifyChanged(FileRef);
	Notify("Write_File", FileWriteNotificationParameters("AttachedFileEncrypted"), FileOwner);
	Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), FileRef);
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.InformOfObjectDecryption(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'File: %1';"), FileRef));
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 
//
Procedure SignFile(AttachedFile, FileData, FormIdentifier,
			CompletionHandler = Undefined, HandlerOnGetSignature = Undefined, SignatureParameters = Undefined) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("CompletionHandler", CompletionHandler);
	ExecutionParameters.Insert("AttachedFile",   AttachedFile);
	ExecutionParameters.Insert("FileData",          FileData);
	ExecutionParameters.Insert("FormIdentifier",   FormIdentifier);
	
	FollowUpHandler = New NotifyDescription("AfterAddSignatures", ThisObject, ExecutionParameters);
	If Not CheckSignPossibility(FileData, CompletionHandler, FollowUpHandler, ExecutionParameters) Then
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("ShowComment", True);
	
	SignArrayOfFiles = TypeOf(AttachedFile) = Type("Array");
	
	If SignArrayOfFiles And AttachedFile.Count() > 1 Then
		
		DataDetails.Insert("Operation",            NStr("en = 'Sign files';"));
		DataDetails.Insert("DataTitle",     NStr("en = 'Files';"));
		
		DataSet = New Array;
		FileIndex = 0;
		For Each File In AttachedFile Do
			
			DescriptionOfFileData = New Structure;
			DescriptionOfFileData.Insert("Presentation", File);
			DescriptionOfFileData.Insert("Data", ExecutionParameters.FileData[FileIndex].RefToBinaryFileData);
			
			If HandlerOnGetSignature = Undefined Then
				DescriptionOfFileData.Insert("Object", File);
			Else
				DescriptionOfFileData.Insert("Object", HandlerOnGetSignature);
			EndIf;
			
			DataSet.Add(DescriptionOfFileData);
			FileIndex = FileIndex + 1;
			
		EndDo;
		
		DataDetails.Insert("DataSet", DataSet);
		DataDetails.Insert("SetPresentation", "Files (%1)");
		
	Else
		
		DataDetails.Insert("Operation",        NStr("en = 'Sign file';"));
		DataDetails.Insert("DataTitle", NStr("en = 'File';"));
		
		If SignArrayOfFiles Then
			DataDetails.Insert("Presentation", AttachedFile[0]);
			DataDetails.Insert("Data", ExecutionParameters.FileData[0].RefToBinaryFileData);
			If HandlerOnGetSignature = Undefined Then
				DataDetails.Insert("Object", AttachedFile[0]);
			Else
				DataDetails.Insert("Object", HandlerOnGetSignature);
			EndIf;
		Else
			DataDetails.Insert("Presentation", AttachedFile);
			DataDetails.Insert("Data", ExecutionParameters.FileData.RefToBinaryFileData);
			If HandlerOnGetSignature = Undefined Then
				DataDetails.Insert("Object", AttachedFile);
			Else
				DataDetails.Insert("Object", HandlerOnGetSignature);
			EndIf;
		EndIf;
		
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	SigningParameters = ModuleDigitalSignatureClient.NewSignatureType();
	If SignatureParameters <> Undefined Then
		FillPropertyValues(SigningParameters, SignatureParameters);
	EndIf;
	ModuleDigitalSignatureClient.Sign(DataDetails, FormIdentifier, FollowUpHandler, SigningParameters);
	
EndProcedure

// Completing the Signfile, addfile Signature procedures.
Procedure AfterAddSignatures(DataDetails, ExecutionParameters) Export
	
	If TypeOf(DataDetails) <> Type("Structure")
		Or Not DataDetails.Property("Success") Then
		
		ExecuteNotifyProcessing(ExecutionParameters.CompletionHandler, False);
		Return;
	EndIf;
	
	If DataDetails.Success Then
		If TypeOf(ExecutionParameters.AttachedFile) = Type("Array") Then
			
			For Each File In ExecutionParameters.AttachedFile Do
				NotifyChanged(File);
				Notify("Write_File", FileWriteNotificationParameters(), File);
			EndDo;
			
		Else
			NotifyChanged(ExecutionParameters.AttachedFile);
			Notify("Write_File", FileWriteNotificationParameters(), ExecutionParameters.AttachedFile);
		EndIf;
	EndIf;
	
	If ExecutionParameters.CompletionHandler <> Undefined Then
		ExecuteNotifyProcessing(ExecutionParameters.CompletionHandler, DataDetails.Success);
	EndIf;
	
EndProcedure

// 
Procedure AddSignatureFromFile(File, FormIdentifier, CompletionHandler) Export
	
	FileProperties = FilesOperationsInternalServerCall.FileDataAndBinaryData(File, , FormIdentifier);
	FileData = FileProperties.FileData;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("CompletionHandler", CompletionHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FormIdentifier", FormIdentifier);
	
	If Not CheckSignPossibility(ExecutionParameters.FileData,
		CompletionHandler, CompletionHandler, ExecutionParameters) Then
		
		Return;
		
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("DataTitle",     NStr("en = 'File';"));
	DataDetails.Insert("Presentation",       FileData.Ref);
	DataDetails.Insert("ShowComment", True);
	DataDetails.Insert("Data",              FileProperties.BinaryData);
	
	DataDetails.Insert("Object",
		New NotifyDescription("OnGetSignatures", ThisObject, ExecutionParameters));
	
	FollowUpHandler = New NotifyDescription("AfterSignFile",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.AddSignatureFromFile(DataDetails,, FollowUpHandler);
	
EndProcedure

// Continue with the add file Signature procedure.
// Called from the electronic Signature subsystem after preparing signatures from files for a non
// -standard way to add a signature to an object.
//
// Parameters:
//   Context - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure OnGetSignatures(Parameters, Context) Export
	
	FilesOperationsInternalServerCall.AddSignatureToFile(
		Context.FileData.Ref,
		Parameters.DataDetails.Signatures,
		Context.FormIdentifier);
	
	ExecuteNotifyProcessing(Parameters.Notification, New Structure);
	
EndProcedure

// Completing the add file Signature procedure.
Procedure AfterSignFile(DataDetails, ExecutionParameters) Export
	
	If TypeOf(DataDetails) <> Type("Structure")
		Or Not DataDetails.Property("Success") Then
		
		ExecuteNotifyProcessing(ExecutionParameters.CompletionHandler, False);
		Return;
	EndIf;
	
	If DataDetails.Success Then
		NotifyOfFileChange(ExecutionParameters.FileData);
	EndIf;
	
	ReturnResult(ExecutionParameters.CompletionHandler, DataDetails.Success);
	
EndProcedure

// For post-File and post-File signing procedures.
Procedure NotifyOfFileChange(FileData)
	
	NotifyChanged(FileData.Ref);
	NotifyChanged(FileData.CurrentVersion);
	
	Notify("Write_File", FileWriteNotificationParameters("AttachedFileSigned"), FileData.Owner);
	
EndProcedure

// Saves a file with an electronic signature.
Procedure SaveFileWithSignature(File, FormIdentifier) Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToSave(File);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FormIdentifier", FormIdentifier);
	
	DataDetails = New Structure;
	DataDetails.Insert("DataTitle",     NStr("en = 'File';"));
	DataDetails.Insert("Presentation",       ExecutionParameters.FileData.Ref);
	DataDetails.Insert("ShowComment", True);
	DataDetails.Insert("Object",              ExecutionParameters.FileData.Ref);
	
	DataDetails.Insert("Data",
		New NotifyDescription("OnSaveFileData", ThisObject, ExecutionParameters));
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.SaveDataWithSignature(DataDetails);
	
EndProcedure

// Continue the procedure to save the file with the signatures.
// Called from the electronic Signature subsystem after selecting signatures to save.
//
Procedure OnSaveFileData(Parameters, Context) Export
	
	AdditionalParameters = New Structure("Notification", Parameters.Notification);
	HandlerNotifications = New NotifyDescription("OnSaveFileDataReturnResult", ThisObject, AdditionalParameters);
	SaveAs(HandlerNotifications, Context.FileData, Context.FormIdentifier);
	
EndProcedure

// Continue the procedure to save the file with the signatures.
// Called from the electronic Signature subsystem after selecting signatures to save.
//
Procedure OnSaveFileDataReturnResult(Result, AdditionalParameters) Export

	If TypeOf(Result) = Type("String") Then
		Result = ?(ValueIsFilled(Result), New Structure("FullFileName", Result), New Structure);
	EndIf;
	ExecuteNotifyProcessing(AdditionalParameters.Notification, Result);

EndProcedure

Function CheckSignPossibility(FileData, CompletionHandler, ResultHandler, ExecutionParameters)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return False;
	EndIf;
	
	If TypeOf(FileData) = Type("Array") Then
		
		Warnings = New Array;
		For Each File In FileData Do
			If ValueIsFilled(File.BeingEditedBy) Then
				Warnings.Add(FilesOperationsInternalClientServer.MessageAboutInvalidSigningOfLockedFile(File.Ref));
				Continue;
			EndIf;
			
			If File.Encrypted Then
				Warnings.Add(FilesOperationsInternalClientServer.MessageAboutInvalidSigningOfEncryptedFile(File.Ref));
				Continue;
			EndIf;
		EndDo;
		
		If Warnings.Count() > 0 Then
			ReturnResultAfterShowWarning(ResultHandler, StrConcat(Warnings, Chars.LF), ExecutionParameters);
			Return False;
		EndIf;
		
	Else
	
		If ValueIsFilled(FileData.BeingEditedBy) Then
			WarningText = FilesOperationsInternalClientServer.MessageAboutInvalidSigningOfLockedFile();
			ReturnResultAfterShowWarning(ResultHandler, WarningText, ExecutionParameters);
			Return False;
		EndIf;
		
		If FileData.Encrypted Then
			WarningText = FilesOperationsInternalClientServer.MessageAboutInvalidSigningOfEncryptedFile();
			ReturnResultAfterShowWarning(CompletionHandler, WarningText, ExecutionParameters);
			Return False;
		EndIf;
	
	EndIf;
	
	Return True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Returns:
//  Structure:
//    * ResultHandler      - NotifyDescription -  a handler who needs to pass the result of the import.
//    * Owner                  - DefinedType.AttachedFilesOwner -  the folder or owner object to which
//                                                                                 the imported files are added.
//    * FilesGroup              - DefinedType.AttachedFile -  the group of files that
//                                                                       the imported files are added to.
//    * SelectedFiles            - ValueList -  the imported object File.
//    * Indicator                 - Number -  a number from 0 to 100 indicates progress.
//    * Comment               - String -  comment.
//    * StoreVersions             - Boolean -  store versions.
//    * ShouldDeleteAddedFiles - Boolean -  delete files selected Files after import is complete.
//    * Recursively                - Boolean -  recursively crawl the subdirectories.
//    * FormIdentifier        - UUID -  the ID of the form.
//    * PseudoFileSystem     - Map -  file system emulation-for a string (directory) returns an array
//                                                 of strings (subdirectories and files).
//    * Encoding                 - String -  encoding for text files.
//    * AddedFiles          - Array -  added files, output parameter.
//
Function FilesImportParameters() Export
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ResultHandler");
	ExecutionParameters.Insert("Owner");
	ExecutionParameters.Insert("FilesGroup");
	ExecutionParameters.Insert("SelectedFiles");
	ExecutionParameters.Insert("Comment");
	ExecutionParameters.Insert("StoreVersions");
	ExecutionParameters.Insert("ShouldDeleteAddedFiles");
	ExecutionParameters.Insert("Recursively");
	ExecutionParameters.Insert("FormIdentifier");
	ExecutionParameters.Insert("PseudoFileSystem", New Map);
	ExecutionParameters.Insert("Encoding");
	ExecutionParameters.Insert("AddedFiles", New Array);
	Return ExecutionParameters;
EndFunction

// 
// 
//
// Parameters:
//  ExecutionParameters   - Structure:
//    * ResultHandler      - NotifyDescription
//                                - Structure - 
//                                  
//    * Owner                  - AnyRef -  file owner.
//    * SelectedFiles            - Array
//                                - ValueList - 
//    * Indicator                 - Number -  a number from 0 to 100 indicates progress.
//    * ArrayOfFilesNamesWithErrors - Array -  array of file names with errors.
//    * AllFilesStructureArray  - Array -  array of structures for all files.
//    * Comment               - String -  comment.
//    * StoreVersions             - Boolean -  store versions.
//    * ShouldDeleteAddedFiles - Boolean -  delete files selected Files after import is complete.
//    * Recursively                - Boolean -  recursively crawl the subdirectories.
//    * TotalFilesCount       - Number -  the total number of imported files.
//    * Counter                   - Number -  counter of processed files (not necessarily the file will be uploaded).
//    * FormIdentifier        - UUID -  the ID of the form.
//    * PseudoFileSystem     - Map -  file system emulation-for a string (directory) returns an array
//                                                 of strings (subdirectories and files).
//    * AddedFiles          - Array -  added files, output parameter.
//    * AllFoldersArray           - Array -  an array of all the folders.
//    * Encoding                 - String -  encoding for text files.
//
Procedure ImportFilesRecursively(Owner, SelectedFiles, ExecutionParameters)
	
	InternalParameters = New Structure;
	For Each KeyAndValue In ExecutionParameters Do
		InternalParameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	InternalParameters.ResultHandler = ExecutionParameters;
	InternalParameters.Owner = Owner;
	InternalParameters.SelectedFiles = SelectedFiles;
	
	InternalParameters.Insert("FoldersArrayForQuestionWhetherFolderAlreadyExists", New Array);
	ImportFilesRecursivelyWithoutDialogBoxes(InternalParameters.Owner, InternalParameters.SelectedFiles, InternalParameters, True); 
	If InternalParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Count() = 0 Then
		// 
		ReturnResult(InternalParameters.ResultHandler, Undefined);
		Return;
	EndIf;
	
	//  
	// 
	// 
	InternalParameters.SelectedFiles = New Array;
	InternalParameters.Insert("FolderToAddToSelectedFiles", Undefined);
	ImportFilesRecursivelySetNextQuestion(InternalParameters);
	
EndProcedure

// 
//
// Parameters:
//  ExecutionParameters - Structure:
//   * SelectedFiles - Array
//   * FolderToAddToSelectedFiles - File
//   * FoldersArrayForQuestionWhetherFolderAlreadyExists - Array
//
Procedure ImportFilesRecursivelySetNextQuestion(ExecutionParameters)
	
	ExecutionParameters.ResultHandler = CompletionHandler(ExecutionParameters.ResultHandler);
	ExecutionParameters.FolderToAddToSelectedFiles = ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists[0];
	ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Delete(0);
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Folder ""%1"" already exists.
		           |Do you want to continue the upload?';"),
		ExecutionParameters.FolderToAddToSelectedFiles.Name);
	
	Handler = New NotifyDescription("FilesImportRecursivelyAfterRespondQuestion", ThisObject, ExecutionParameters);
	
	ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

// 
//
// Parameters:
//   ExecutionParameters - Structure:
//     * SelectedFiles - Array
//
Procedure FilesImportRecursivelyAfterRespondQuestion(Response, ExecutionParameters) Export
	
	If Response <> DialogReturnCode.No Then
		ExecutionParameters.SelectedFiles.Add(ExecutionParameters.FolderToAddToSelectedFiles);
	EndIf;
	
	// 
	If ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Count() = 0 Then
		ImportFilesRecursivelyWithoutDialogBoxes(ExecutionParameters.Owner,	ExecutionParameters.SelectedFiles, ExecutionParameters,
			False); // 
		
		If ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Count() = 0 Then
			// 
			ReturnResult(ExecutionParameters.ResultHandler, Undefined);
			Return;
		Else
			// 
			ExecutionParameters.SelectedFiles = New Array;
		EndIf;
	EndIf;
	
	ImportFilesRecursivelySetNextQuestion(ExecutionParameters);
	
EndProcedure

// 
// 
//
// Parameters:
//  Owner            - AnyRef -  file owner.
//  SelectedFiles      - Array -  array of File objects.
//  ExecutionParameters - See ImportFilesRecursively.ExecutionParameters
//  AskQuestionFolderAlreadyExists - Boolean -  True only for the first level of recursion.
//
Procedure ImportFilesRecursivelyWithoutDialogBoxes(Val Owner, Val SelectedFiles, Val ExecutionParameters, Val AskQuestionFolderAlreadyExists)
	
	Var FirstFolderWithSameName;
	
	For Each SelectedFile In SelectedFiles Do
		
		If Not SelectedFile.Exists() Then
			Record = New Structure;
			Record.Insert("FileName", SelectedFile.FullName);
			Record.Insert("Error", NStr("en = 'No file on the computer.';"));
			ExecutionParameters.ArrayOfFilesNamesWithErrors.Add(Record);
			Continue;
		EndIf;
		
		Try
			
			If SelectedFile.Extension = ".lnk" Then
				SelectedFile = DereferenceLnkFile(SelectedFile);
			EndIf;
			
			If SelectedFile.IsDirectory() Then
				
				If ExecutionParameters.Recursively = True Then
					NewPath = String(SelectedFile.Path);
					NewPath = CommonClientServer.AddLastPathSeparator(NewPath);
					NewPath = NewPath + String(SelectedFile.Name);
					FilesArray = FindFilesPseudo(ExecutionParameters.PseudoFileSystem, NewPath);
					
					// 
					If FilesArray.Count() <> 0 Then
						FileName = SelectedFile.Name;
						
						If FilesOperationsInternalServerCall.HasFolderWithThisName(FileName, ExecutionParameters.FilesGroup, FirstFolderWithSameName) Then
							
							If AskQuestionFolderAlreadyExists Then
								ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Add(SelectedFile);
								Continue;
							EndIf;
						EndIf;
						
						FilesFolderRef = FilesOperationsInternalServerCall.CreateFilesFolder(FileName, Owner,,ExecutionParameters.FilesGroup);
						If FilesOperationsInternalClientCached.IsDirectoryFiles(FilesFolderRef) Then
							// 
							// 
							ImportFilesRecursivelyWithoutDialogBoxes(FilesFolderRef, FilesArray, ExecutionParameters, True);
						Else
							CurrentFilesGroup = ExecutionParameters.FilesGroup;
							ExecutionParameters.FilesGroup = FilesFolderRef;
							// 
							// 
							ImportFilesRecursivelyWithoutDialogBoxes(Owner, FilesArray, ExecutionParameters, True);
							ExecutionParameters.FilesGroup = CurrentFilesGroup;
						EndIf;
						
						ExecutionParameters.AllFoldersArray.Add(NewPath);
					EndIf;
				EndIf;
				
				Continue;
			EndIf;
			
			If Not CheckCanImportFile(
			          SelectedFile, False, ExecutionParameters.ArrayOfFilesNamesWithErrors) Then
				Continue;
			EndIf;
			
			// 
			ExecutionParameters.Counter = ExecutionParameters.Counter + 1;
			// 
			ExecutionParameters.Indicator = Int(ExecutionParameters.Counter * 100 / ExecutionParameters.TotalFilesCount);
			SizeInMB = SelectedFile.Size() / (1024 * 1024);
			LabelMore = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Processing file ""%1"" (%2 MB)…';"),
				SelectedFile.Name, 
				FilesOperationsInternalClientServer.FileSizePresentation(SizeInMB));
				
			StateText = NStr("en = 'Uploading files from your computer...';");
			
			Status(StateText,
				ExecutionParameters.Indicator,
				LabelMore,
				PictureLib.DialogInformation);
			
			// 
			TempFileStorageAddress = "";
			
			Files = New Array;
			LongDesc = New TransferableFileDescription(SelectedFile.FullName, "");
			Files.Add(LongDesc);
			
			PlacedFiles = New Array;			
			If Not PutFiles(Files, PlacedFiles, , False, ExecutionParameters.FormIdentifier) Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Cannot put the file in the ""%1"" temporary storage.';"),
					SelectedFile.FullName);
			EndIf;
			
			If PlacedFiles.Count() = 1 Then
				TempFileStorageAddress = PlacedFiles[0].Location;
			EndIf;
			
			If Not CommonFilesOperationsSettings().ExtractTextFilesOnServer Then
				TempTextStorageAddress = ExtractTextToTempStorage(SelectedFile.FullName,
					ExecutionParameters.FormIdentifier, , ExecutionParameters.Encoding);
			Else
				TempTextStorageAddress = "";
			EndIf;
			
			// 
			ImportFile1(SelectedFile, Owner, ExecutionParameters, TempFileStorageAddress, TempTextStorageAddress);
				
		Except
			ErrorInfo = ErrorInfo();
			
			ErrorMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo);
			CommonClient.MessageToUser(ErrorMessage);
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Error", ErrorProcessing.DetailErrorDescription(ErrorInfo),,True);
			
			Record = New Structure;
			Record.Insert("FileName", SelectedFile.FullName);
			Record.Insert("Error", ErrorMessage);
			ExecutionParameters.ArrayOfFilesNamesWithErrors.Add(Record);
			
		EndTry;
	EndDo;
	
EndProcedure

// Parameters:
//
// ExecutionParameters - See ImportFilesRecursively.ExecutionParameters
//
Procedure ImportFile1(Val SelectedFile, Val Owner, Val ExecutionParameters, Val TempFileStorageAddress, Val TempTextStorageAddress) 

	If FilesOperationsInternalClientCached.IsDirectoryFiles(ExecutionParameters.Owner) Then
		
		FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion", SelectedFile);
		FileInfo1.TempFileStorageAddress = TempFileStorageAddress;
		FileInfo1.TempTextStorageAddress = TempTextStorageAddress;
		FileInfo1.Comment = ExecutionParameters.Comment;
		FileInfo1.Encoding = ExecutionParameters.Encoding;

		FileRef = FilesOperationsInternalServerCall.CreateFileWithVersion(Owner, FileInfo1);
		
	Else
		
		FileParameters = FilesOperationsInternalClientServer.FileAddingOptions();
		FileParameters.FilesOwner = ExecutionParameters.Owner;
		FileParameters.BaseName = SelectedFile.BaseName;
		FileParameters.ExtensionWithoutPoint = CommonClientServer.ExtensionWithoutPoint(SelectedFile.Extension);
		FileParameters.FilesGroup = ExecutionParameters.FilesGroup;
		
		FileRef = FilesOperationsInternalServerCall.AppendFile(FileParameters,
			TempFileStorageAddress, TempTextStorageAddress,ExecutionParameters.Comment);
		
	EndIf;
	
	If ExecutionParameters.Encoding <> Undefined Then
		FilesOperationsInternalServerCall.WriteFileVersionEncoding(FileRef, ExecutionParameters.Encoding); 
	EndIf;
	
	DeleteFromTempStorage(TempFileStorageAddress);
	If Not IsBlankString(TempTextStorageAddress) Then
		DeleteFromTempStorage(TempTextStorageAddress);
	EndIf;
	
	AddedFileAndPath = New Structure("FileRef, Path", FileRef, SelectedFile.Path);
	ExecutionParameters.AddedFiles.Add(AddedFileAndPath);
	
	Record = New Structure;
	Record.Insert("FileName", SelectedFile.FullName);
	Record.Insert("File", FileRef);
	ExecutionParameters.AllFilesStructureArray.Add(Record);

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
//
// Parameters:
//  CurrentVersion  - CatalogRef.FilesVersions -  file version.
//  NewName       - String -  new file name.
//
Procedure RefreshInformationInWorkingDirectory(CurrentVersion, NewName) Export
	
	DirectoryName = UserWorkingDirectory();
	FullFileName = "";	
	InWorkingDirectoryForRead = True;
	InOwnerWorkingDirectory = False;	
	FileInWorkingDirectory = FileInLocalFilesCache(Undefined, CurrentVersion,
		FullFileName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	If Not FileInWorkingDirectory Then
		Return;
	EndIf;
	
	File = New File(FullFileName);
	OnlyName = File.Name;
	FileSize = File.Size();
	PathWithoutName = Left(FullFileName, StrLen(FullFileName) - StrLen(OnlyName));
	NewFullName = PathWithoutName + NewName + File.Extension;
	MoveFile(FullFileName, NewFullName);
	
	FilesOperationsInternalServerCall.DeleteFromRegister(CurrentVersion);
	FilesOperationsInternalServerCall.PutFileInformationInRegister(CurrentVersion,
		NewFullName, DirectoryName, InWorkingDirectoryForRead, FileSize, InOwnerWorkingDirectory);
	
EndProcedure

// 
// 
// Parameters:
//  FileData  - See FilesOperationsInternalServerCall.FileData
//  ForReading - Boolean -  the file has been placed for reading.
//  InOwnerWorkingDirectory - Boolean -  the file is in the owner's working directory (not the main working directory).
//
Procedure ReregisterFileInWorkingDirectory(FileData, ForReading, InOwnerWorkingDirectory)
	
	If FileData.Version.IsEmpty() Then 
		Return;
	EndIf;

	FullFileName = "";	
	InWorkingDirectoryForRead = True;
	FileInWorkingDirectory = FileInLocalFilesCache(FileData, FileData.CurrentVersion, FullFileName, 
		InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	If Not FileInWorkingDirectory Then
		Return;
	EndIf;
	
	DirectoryName = UserWorkingDirectory();
	FilesOperationsInternalServerCall.PutFileInformationInRegister(FileData.CurrentVersion, FullFileName, 
		DirectoryName, ForReading, 0, InOwnerWorkingDirectory);
	File = New File(FullFileName);
	File.SetReadOnly(ForReading);
	
EndProcedure

// This function is intended for opening the file by the corresponding application.
//
// Parameters:
//  FileData  - See FilesOperationsInternalServerCall.FileData
//  FileToOpenName - String -  full file name.
//  OwnerID - UUID -  ID of the owner form.
//
Procedure OpenFileWithApplication(FileData, FileToOpenName, OwnerID = Undefined)
	
	If Not FileSystemExtensionAttached1() Then
		Return;
	EndIf;
		
	PersonalFilesOperationsSettings = PersonalFilesOperationsSettings();
	
	TextFilesOpeningMethod = PersonalFilesOperationsSettings.TextFilesOpeningMethod;
	If TextFilesOpeningMethod = PredefinedValue("Enum.OpenFileForViewingMethods.UsingBuiltInEditor") Then
		
		TextFilesExtension = PersonalFilesOperationsSettings.TextFilesExtension;
		If FilesOperationsInternalClientServer.FileExtensionInList(TextFilesExtension, FileData.Extension) Then
			
			FormParameters = New Structure;
			FormParameters.Insert("File", FileData.Ref);
			FormParameters.Insert("FileData", FileData);
			FormParameters.Insert("FileToOpenName", FileToOpenName);
			FormParameters.Insert("OwnerID", OwnerID);
			
			OpenForm("DataProcessor.FilesOperations.Form.EditTextFile", 
				FormParameters, , FileData.Ref);
			Return;
			
		EndIf;
		
	EndIf;
	
#If Not MobileClient Then
	If Lower(FileData.Extension) = Lower("grs") Then
		
		Schema = New GraphicalSchema; 
		Schema.Read(FileToOpenName);
		
		FormCaption = CommonClientServer.GetNameWithExtension(
			FileData.FullVersionDescription, FileData.Extension);
		
		Schema.Show(FormCaption, FileToOpenName);
		Return;
		
	EndIf;
#EndIf
	
	If Lower(FileData.Extension) = Lower("mxl") Then
		
		Files = New Array;
		Files.Add(New TransferableFileDescription(FileToOpenName));
		PlacedFiles = New Array;
		If Not PutFiles(Files, PlacedFiles, , False) Then
			Return;
		EndIf;
		SpreadsheetDocument = PlacedFiles[0].Location;
		
		FormParameters = StandardSubsystemsClient.SpreadsheetEditorParameters();
		FormParameters.DocumentName = CommonClientServer.GetNameWithExtension(
			FileData.FullVersionDescription, FileData.Extension);
		FormParameters.PathToFile = FileToOpenName;
		If Not FileData.ForReading Then
			FormParameters.Insert("AttachedFile", FileData.Ref);
		EndIf;
		StandardSubsystemsClient.ShowSpreadsheetEditor(SpreadsheetDocument, FormParameters);
		
		Return;
		
	EndIf;
	
	// 
	FileSystemClient.OpenFile(FileToOpenName);
	
EndProcedure

// Returns parameters for working with busy files.
// Returns:
//	Undefined - if there are no editable files or you don't need to work with them.
//	Structure - a structure with passed parameters.
// 
Function CheckLockedFilesOnExit()
	
	If UsersClient.IsExternalUserSession() Then
		Return Undefined;
	EndIf;
	
	PersonalFilesOperationsSettings = StandardSubsystemsClient.ClientParameter("PersonalFilesOperationsSettings");
	ShowLockedFilesOnExit = PersonalFilesOperationsSettings.ShowLockedFilesOnExit;
	
	If Not ShowLockedFilesOnExit Then
		Return Undefined;
	EndIf;
	
	LockedFilesCount = LockedFilesCount();
	If Not LockedFilesCount > 0 Then
		Return Undefined;
	EndIf;
	
	CurrentUser = UsersClient.AuthorizedUser();
	
	ApplicationWarningFormParameters = New Structure;
	ApplicationWarningFormParameters.Insert("MessageQuestion",      NStr("en = 'Exit the app?';"));
	ApplicationWarningFormParameters.Insert("MessageTitle",   NStr("en = 'The following files are locked:';"));
	ApplicationWarningFormParameters.Insert("Title",            NStr("en = 'Exit application';"));
	ApplicationWarningFormParameters.Insert("BeingEditedBy",          CurrentUser);
	
	ApplicationWarningForm = "DataProcessor.FilesOperations.Form.LockedFilesListWithQuestion";
	Form                         = "DataProcessor.FilesOperations.Form.FilesToEdit";
	
	ReturnParameters = New Structure;
	ReturnParameters.Insert("ApplicationWarningForm", ApplicationWarningForm);
	ReturnParameters.Insert("ApplicationWarningFormParameters", ApplicationWarningFormParameters);
	ReturnParameters.Insert("Form", Form);
	ReturnParameters.Insert("ApplicationWarningForm", ApplicationWarningForm);
	ReturnParameters.Insert("LockedFilesCount", LockedFilesCount);
	
	Return ReturnParameters;
	
EndFunction

// Returns the value of the client parameter number of occupied Files.
//
Function LockedFilesCount()
	
	Return StandardSubsystemsClient.ClientParameter("LockedFilesCount");
	
EndFunction

// Changes the value of the client parameter number of occupied Files.
//
Procedure ChangeLockedFilesCount(ChangeValue = -1) Export
	
	StandardSubsystemsClient.SetClientParameter(
		"LockedFilesCount", LockedFilesCount() + ChangeValue);
	
EndProcedure

// Returns:
//   Structure:
//     * Path - String
//     * Size - Number
//     * Version - DefinedType.AttachedFile
//     * PutFileInWorkingDirectoryDate - Date
//
Function FilesInWorkingDirectoryData()
	
	Return New Structure("Path, Size, Version, PutFileInWorkingDirectoryDate");
	
EndFunction

// Recursively traversing files in the working directory and collecting information about them.
//
// Parameters:
//  Path - String -  path of the working directory.
//  FilesArray - Array of DefinedType.AttachedFile
//  TableOfFiles - Array of See FilesInWorkingDirectoryData - 
//
Procedure ProcessFilesTable(Val Path, Val FilesArray, Val TableOfFiles)
	
#If Not WebClient Then
	Var Version;
	Var PutFileDate;
	
	DirectoryName = UserWorkingDirectory();
	FilesToAnalize = New Array;
	For Each SelectedFile In FilesArray Do
		
		If SelectedFile.IsDirectory() Then
			NewPath = String(Path);
			NewPath = NewPath + GetPathSeparator();
			NewPath = NewPath + String(SelectedFile.Name);
			FilesArrayInDirectory = FindFiles(NewPath, GetAllFilesMask());
			
			If FilesArrayInDirectory.Count() <> 0 Then
				ProcessFilesTable(NewPath, FilesArrayInDirectory, TableOfFiles);
			EndIf;
		
			Continue;
		EndIf;
		
		// 
		If StrStartsWith(SelectedFile.Name, "~") And SelectedFile.GetHidden() Then
			Continue;
		EndIf;
		
		RelativePath = Mid(SelectedFile.FullName, StrLen(DirectoryName) + 1);
		FilesToAnalize.Add(RelativePath);
	EndDo;
	
	FilesInfo = FilesOperationsInternalServerCall.FilesInfoInWorkingDir(FilesToAnalize);
	For Each FileInfoKey In FilesInfo Do
		RelativePath = FileInfoKey.Key;
		FileInfo1 = FileInfoKey.Value;
		// 
		// 
		PutFileDate = ?(FileInfo1.FileIsInRegister, FileInfo1.PutFileDate, Date('00010101'));
		
		// 
		If Not FileInfo1.FileIsInRegister 
			Or FileInfo1.FileIsInRegister And Not FileInfo1.EditedByCurrentUser Then
			Record = FilesInWorkingDirectoryData();
			Record.Path = RelativePath;
			Record.Size = SelectedFile.Size();
			Record.Version = FileInfo1.File;
			Record.PutFileInWorkingDirectoryDate = PutFileDate;
			TableOfFiles.Add(Record);
		EndIf;
	EndDo;
	
#EndIf
	
EndProcedure

// 
// 
//
// Parameters:
//  FileData  - Structure
//
// Returns:
//   String
//
Function GetFilePathInWorkingDirectory(FileData)
	
	PathToReturn = "";
	FullFileName = "";
	DirectoryName = UserWorkingDirectory();
	
	FullFileName = FileData.FullFileNameInWorkingDirectory;
	
	If FullFileName <> "" Then
		FileOnHardDrive = New File(FullFileName);
		If FileOnHardDrive.Exists() Then
			Return FullFileName;
		EndIf;
	EndIf;
	
	FileName = FileData.FullVersionDescription;
	Extension = FileData.Extension;
	If Not IsBlankString(Extension) Then 
		FileName = CommonClientServer.GetNameWithExtension(FileName, Extension);
	EndIf;
	
	CommonInternalClient.ShortenFileName(FileName);
	
	FullFileName = "";
	If Not IsBlankString(FileName) Then
		If Not IsBlankString(FileData.OwnerWorkingDirectory) Then
			FullFileName = FileData.OwnerWorkingDirectory + FileData.FullVersionDescription + "." + FileData.Extension;
		Else
			FullFileName = FilesOperationsInternalClientServer.UniqueNameByWay(DirectoryName, FileName);
		EndIf;
	EndIf;
	
	If IsBlankString(FileName) Then
		Return "";
	EndIf;
	
	// 
	ForReading = True;
	InOwnerWorkingDirectory = FileData.OwnerWorkingDirectory <> "";
	FilesOperationsInternalServerCall.WriteFullFileNameToRegister(FileData.Version, FullFileName, ForReading, InOwnerWorkingDirectory);
	
	If FileData.OwnerWorkingDirectory = "" Then
		PathToReturn = DirectoryName + FullFileName;
	Else
		PathToReturn = FullFileName;
	EndIf;
	
	Return PathToReturn;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Returns:
//   See FilesOperations.FilesOperationSettings
//
Function PersonalFilesOperationsSettings() Export
	
	Return StandardSubsystemsClient.ClientRunParameters().PersonalFilesOperationsSettings;
	
EndFunction

// Returns a structure containing various personal settings.
Function CommonFilesOperationsSettings()
	
	CommonSettings = StandardSubsystemsClient.ClientRunParameters().CommonFilesOperationsSettings;
	
	// 
	// 
	
	Return CommonSettings;
	
EndFunction

// Parameters:
//  FileData - See FilesOperationsInternalServerCall.FileData
//  CurrentVersion  - CatalogRef.FilesVersions
//  FullFileName - String - 
//  InWorkingDirectoryForRead - Boolean -  the file has been placed for reading.
//  InOwnerWorkingDirectory - Boolean -  the file is in the owner's working directory (not the main working directory).
//
// Returns:
//  Boolean
//
Function FileInLocalFilesCache(FileData, CurrentVersion, FullFileName, InWorkingDirectoryForRead, 
	InOwnerWorkingDirectory)
	
	FullFileName = "";
	
	// 
	If FileData <> Undefined And FileData.CurrentVersion = CurrentVersion Then
		FullFileName = FileData.FullFileNameInWorkingDirectory;
		InWorkingDirectoryForRead = FileData.InWorkingDirectoryForRead;
	Else
		InWorkingDirectoryForRead = True;
		DirectoryName = UserWorkingDirectory();
		FullFileName = FilesOperationsInternalServerCall.FullFileNameInWorkingDirectory(CurrentVersion, 
			DirectoryName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	EndIf;
	
	If FullFileName <> "" Then
		FileOnHardDrive = New File(FullFileName);
		If FileOnHardDrive.Exists() Then
			Return True;
		Else
			FullFileName = "";
			FilesOperationsInternalServerCall.DeleteFromRegister(CurrentVersion);
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// Select the path to the working directory.
// Parameters:
//  DirectoryName  - String -  previous folder name.
//  Title  - String -  the title of the form, select the directory path.
//  OwnerWorkingDirectory - String-   the owner's working directory.
//
// Returns:
//   Boolean  -  whether the operation was completed successfully.
//
Function ChoosePathToWorkingDirectory(DirectoryName, Title, OwnerWorkingDirectory) Export
	
	Mode = FileDialogMode.ChooseDirectory;
	OpenFileDialog = New FileDialog(Mode);
	OpenFileDialog.FullFileName = "";
	OpenFileDialog.Directory = DirectoryName;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = Title;
	
	If OpenFileDialog.Choose() Then
		
		DirectoryName = OpenFileDialog.Directory;
		DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
		
		// 
		Try
			CreateDirectory(DirectoryName);
			TestDirectoryName = DirectoryName + "CheckAccess\";
			CreateDirectory(TestDirectoryName);
			DeleteFiles(TestDirectoryName);
		Except
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);

			// 
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Error writing to directory ""%1"".
				           |Invalid path or insufficient permissions.';"),
				DirectoryName);
			ShowMessageBox(, ErrorText);
			Return False;
		EndTry;
		
		If OwnerWorkingDirectory = False Then
#If Not WebClient Then
			FilesArrayInDirectory = FindFiles(DirectoryName, GetAllFilesMask());
			If FilesArrayInDirectory.Count() <> 0 Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'The selected working directory 
					           |""%1""
					           |contains files.
					           |
					           |Please select another directory.';"),
					DirectoryName);
				ShowMessageBox(, ErrorText);
				Return False;
			EndIf;
#EndIf
		EndIf;
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Re-register in the working directory with a different Start flag.
// Parameters:
//  CurrentVersion  - CatalogRef.FilesVersions -  file version.
//  FullFileName - String -  full file name.
//  ForReading - Boolean -  the file has been placed for reading.
//  InOwnerWorkingDirectory - Boolean -  the file is in the owner's working directory (not the main working directory).
//
Procedure RegegisterInWorkingDirectory(CurrentVersion, FullFileName, ForReading, InOwnerWorkingDirectory)
	
	DirectoryName = UserWorkingDirectory();
	
	FilesOperationsInternalServerCall.PutFileInformationInRegister(CurrentVersion, FullFileName, DirectoryName, ForReading, 0, InOwnerWorkingDirectory);
	File = New File(FullFileName);
	File.SetReadOnly(ForReading);
	
EndProcedure

// Recursive File traversal-to determine the file size.
// Parameters:
//  FilesArray - Array -  array of "File" objects.
//  ArrayOfTooBigFiles - Array -  array of files.
//  Recursively - Boolean -  recursively crawl the subdirectories.
//  TotalFilesCount - Number -  the total number of imported files.
//  PseudoFileSystem - Map -  file system emulation-for a string (directory) returns an array of strings
//                                         (subdirectories and files).
//
Procedure FindTooBigFiles(
				FilesArray,
				ArrayOfTooBigFiles,
				Recursively,
				TotalFilesCount,
				Val PseudoFileSystem) 
	
	MaxFileSize1 = CommonFilesOperationsSettings().MaxFileSize;
	
	For Each SelectedFile In FilesArray Do
		
		If SelectedFile.Exists() Then
			
			If SelectedFile.Extension = ".lnk" Then
				SelectedFile = DereferenceLnkFile(SelectedFile);
			EndIf;
			
			If SelectedFile.IsDirectory() Then
				
				If Recursively Then
					NewPath = String(SelectedFile.Path);
					NewPath = CommonClientServer.AddLastPathSeparator(NewPath);
					NewPath = NewPath + String(SelectedFile.Name);
					FilesArrayInDirectory = FindFilesPseudo(PseudoFileSystem, NewPath);
					
					// Recursion
					If FilesArrayInDirectory.Count() <> 0 Then
						FindTooBigFiles(FilesArrayInDirectory, ArrayOfTooBigFiles, Recursively, TotalFilesCount, PseudoFileSystem);
					EndIf;
				EndIf;
			
				Continue;
			EndIf;
			
			TotalFilesCount = TotalFilesCount + 1;
			
			// 
			If SelectedFile.Size() > MaxFileSize1 Then
				ArrayOfTooBigFiles.Add(SelectedFile.FullName);
				Continue;
			EndIf;
		
		EndIf;
	EndDo;
	
EndProcedure

// Returns an array of files, emulating the work of Naytifiles - but not by file system, but by Matching
//  if the pseudo-file System is empty-works with the file system.
//
Function FindFilesPseudo(Val PseudoFileSystem, Path)
	
	If PseudoFileSystem.Count() = 0 Then
		Files = FindFiles(Path, GetAllFilesMask());
		Return Files;
	EndIf;
	
	Files = New Array;
	
	ValueFound1 = PseudoFileSystem.Get(String(Path));
	If ValueFound1 <> Undefined Then
		For Each FileName In ValueFound1 Do
			FileFromList = New File(FileName);
			Files.Add(FileFromList);
		EndDo;
	EndIf;
	
	Return Files;
	
EndFunction

// Dereference lnk file
// Parameters:
//  SelectedFile - File -  an object of the File type.
//
// Returns:
//   String - 
//
Function DereferenceLnkFile(SelectedFile)
	
#If Not WebClient And Not MobileClient Then
	ShellApplication = New COMObject("shell.application");
	FullPath = ShellApplication.NameSpace(SelectedFile.Path);// 
	FileName = FullPath.items().item(SelectedFile.Name); // 
	Ref = FileName.GetLink();
	Return New File(Ref.path);
#EndIf
	
	Return SelectedFile;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 
// 
//
Procedure CompareFiles(FormIdentifier, FirstFile, SecondFile, Extension, VersionOwner = Undefined) Export
	
	FileVersionsComparisonMethod = Undefined;
	
	ExtensionSupported = (
		Extension = "txt"
		Or Extension = "md"
		Or Extension = "doc"
		Or Extension = "docx"
		Or Extension = "rtf"
		Or Extension = "htm"
		Or Extension = "html"
		Or Extension = "mxl"
		Or Extension = "odt");
	
	If Not ExtensionSupported Then
		WarningText =
		NStr("en = 'File comparison supports only the following formats:
			|   Text document (.txt, .md)
			|   RTF document (.rtf)
			|   Microsoft Word document (.doc, .docx)
			|   HTML document (.html, .htm)
			|   Spreadsheet document (.mxl)
			|   OpenDocument text document (.odt)';");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	If Extension = "odt" Then
		FileVersionsComparisonMethod = "OpenOfficeOrgWriter";
	ElsIf Extension = "htm" Or Extension = "html" Then
		FileVersionsComparisonMethod = "MicrosoftOfficeWord";
	ElsIf Extension = "mxl" Then
		FileVersionsComparisonMethod = "CompareSpreadsheetDocuments";
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("FileVersionsComparisonMethod", FileVersionsComparisonMethod);
	ExecutionParameters.Insert("CurrentStep",              "Step1ChooseVersionComparisonMethod");
	ExecutionParameters.Insert("FileData1",            Undefined);
	ExecutionParameters.Insert("FileData2",            Undefined);
	ExecutionParameters.Insert("Result1",              Undefined);
	ExecutionParameters.Insert("Result2",              Undefined);
	ExecutionParameters.Insert("FullFileName1",         "");
	ExecutionParameters.Insert("FullFileName2",         "");
	ExecutionParameters.Insert("UUID", FormIdentifier);
	ExecutionParameters.Insert("Ref1",                 FirstFile);
	ExecutionParameters.Insert("Ref2",                 SecondFile);
	ExecutionParameters.Insert("VersionOwner",          VersionOwner);
	CompareFilesInternal(ExecutionParameters);
	
EndProcedure

Procedure CompareFilesInternal(ExecutionParameters)
	
	If ExecutionParameters.CurrentStep = "Step1ChooseVersionComparisonMethod" Then
		If ExecutionParameters.FileVersionsComparisonMethod = Undefined Then
			PersonalSettings = PersonalFilesOperationsSettings();
			ExecutionParameters.FileVersionsComparisonMethod = PersonalSettings.FileVersionsComparisonMethod;
			If ExecutionParameters.FileVersionsComparisonMethod = Undefined Then
				Handler = New NotifyDescription("CompareFilesProcessingResult", ThisObject, ExecutionParameters);
				OpenForm("DataProcessor.FilesOperations.Form.SelectVersionCompareMethod",, ThisObject,,,, Handler);
				Return;
			EndIf;
		EndIf;
		ExecutionParameters.CurrentStep = "Step2GetDataFiles";
	EndIf;
	
	If ExecutionParameters.CurrentStep = "Step2GetDataFiles" Then
		
		If ExecutionParameters.Property("VersionOwner") And ValueIsFilled(ExecutionParameters.VersionOwner) Then
			ExecutionParameters.FileData1 = FilesOperationsInternalServerCall.FileDataToOpen(
				ExecutionParameters.VersionOwner, ExecutionParameters.Ref1, ExecutionParameters.UUID);
			ExecutionParameters.FileData2 = FilesOperationsInternalServerCall.FileDataToOpen(
				ExecutionParameters.VersionOwner, ExecutionParameters.Ref2, ExecutionParameters.UUID);
		Else
			ExecutionParameters.FileData1 = FilesOperationsInternalServerCall.FileDataToOpen(
				ExecutionParameters.Ref1, Undefined, ExecutionParameters.UUID);
			ExecutionParameters.FileData2 = FilesOperationsInternalServerCall.FileDataToOpen(
				ExecutionParameters.Ref2, Undefined, ExecutionParameters.UUID);
		EndIf;
		
		ExecutionParameters.CurrentStep = "Step3GetFirstFile";
	EndIf;
	
	If ExecutionParameters.CurrentStep = "Step3GetFirstFile" Then
		Handler = New NotifyDescription("CompareFilesProcessingResult", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(Handler, ExecutionParameters.FileData1, 
			ExecutionParameters.FullFileName1);
		Return;
	EndIf;
	
	If ExecutionParameters.CurrentStep = "Step4GetSecondFile" Then
		Handler = New NotifyDescription("CompareFilesProcessingResult", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(Handler, ExecutionParameters.FileData2, 
			ExecutionParameters.FullFileName2);
		Return;
	EndIf;
	
	If ExecutionParameters.CurrentStep = "Step5CompareFiles" Then
		If Not ExecutionParameters.Result1 Or Not ExecutionParameters.Result2 Then
			Return;
		EndIf;	
		
		FileHeaderTemplate = NStr("en = '%1 (version # %2)';");
		FirstFileData = ExecutionParameters.FileData1; // See FilesOperationsInternalServerCall.FileData
		FileName1 = CommonClientServer.GetNameWithExtension(FirstFileData.FullVersionDescription,
			FirstFileData.Extension);
		FileTitle1 = StringFunctionsClientServer.SubstituteParametersToString(FileHeaderTemplate,
			FileName1, ExecutionParameters.FileData1.VersionNumber);
			
		SecondFileData = ExecutionParameters.FileData2; // See FilesOperationsInternalServerCall.FileData
		FileName2 = CommonClientServer.GetNameWithExtension(SecondFileData.FullVersionDescription,
			SecondFileData.Extension);
		FileTitle2 = StringFunctionsClientServer.SubstituteParametersToString(FileHeaderTemplate,
			FileName2, ExecutionParameters.FileData2.VersionNumber);
			
		If ExecutionParameters.FileData1.VersionNumber < ExecutionParameters.FileData2.VersionNumber Then
			FullFileNameLeft  = ExecutionParameters.FullFileName1;
			FileHeaderLeft  = FileTitle1;
			FullFileNameRight = ExecutionParameters.FullFileName2;
			FileHeaderRight = FileTitle2;
		Else
			FullFileNameLeft  = ExecutionParameters.FullFileName2;
			FileHeaderLeft  = FileTitle2;
			FullFileNameRight = ExecutionParameters.FullFileName1;
			FileHeaderRight = FileTitle1;
		EndIf;
			
		ExecuteCompareFiles(FullFileNameLeft, FullFileNameRight,
			ExecutionParameters.FileVersionsComparisonMethod,
			FileHeaderLeft, FileHeaderRight);
	EndIf;
	
EndProcedure

Procedure CompareFilesProcessingResult(Result, ExecutionParameters) Export

	If ExecutionParameters.CurrentStep = "Step1ChooseVersionComparisonMethod" Then
		If Result <> DialogReturnCode.OK Then
			Return;
		EndIf;
		
		PersonalSettings = PersonalFilesOperationsSettings();
		ExecutionParameters.FileVersionsComparisonMethod = PersonalSettings.FileVersionsComparisonMethod;
		If ExecutionParameters.FileVersionsComparisonMethod = Undefined Then
			Return;
		EndIf;
		ExecutionParameters.CurrentStep = "Step2GetDataFiles";
		
	ElsIf ExecutionParameters.CurrentStep = "Step3GetFirstFile" Then
		ExecutionParameters.Result1      = Result.FileReceived;
		ExecutionParameters.FullFileName1 = Result.FullFileName;
		ExecutionParameters.CurrentStep = "Step4GetSecondFile";
		
	ElsIf ExecutionParameters.CurrentStep = "Step4GetSecondFile" Then
		ExecutionParameters.Result2      = Result.FileReceived;
		ExecutionParameters.FullFileName2 = Result.FullFileName;
		ExecutionParameters.CurrentStep = "Step5CompareFiles";
	EndIf;
	
	CompareFilesInternal(ExecutionParameters);

EndProcedure

Procedure ExecuteCompareFiles(PathToFile1, PathToFile2, FileVersionsComparisonMethod, TitleLeft = "", TitleRight = "") Export
	
	Try
		If FileVersionsComparisonMethod = "MicrosoftOfficeWord" Then
			CompareMicrosoftWordFiles(PathToFile1, PathToFile2);
		ElsIf FileVersionsComparisonMethod = "OpenOfficeOrgWriter" Then 
			CompareOpenOfficeOrgWriterFiles(PathToFile1, PathToFile2);
		ElsIf FileVersionsComparisonMethod = "CompareSpreadsheetDocuments" Then
			CompareSpreadsheetDocuments1(PathToFile1, PathToFile2, TitleLeft, TitleRight);
		EndIf;
		
	Except
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot compare the files. Reason: %1';"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EventLogClient.AddMessageForEventLog(
			NStr("en = 'Files.Compare files';", CommonClient.DefaultLanguageCode()),
			"Error", ErrorMessage, , True);
		Raise ErrorMessage;
	EndTry;
	
EndProcedure

Procedure CompareOpenOfficeOrgWriterFiles(Val PathToFile1, Val PathToFile2)
	
#If Not WebClient And Not MobileClient Then
	
	// 
	File1 = New File(PathToFile1);
	File1.SetReadOnly(False);
	
	File2 = New File(PathToFile2);
	File2.SetReadOnly(False);
	
	// 
	Try
		ServiceManagerObject = New COMObject("com.sun.star.ServiceManager");
		DesktopObject = ServiceManagerObject.createInstance("com.sun.star.frame.Desktop");
		DispatcherHelperObject = ServiceManagerObject.createInstance("com.sun.star.frame.DispatchHelper");
	Except
		EventLogClient.AddMessageForEventLog(
			NStr("en = 'Files.Compare files';", CommonClient.DefaultLanguageCode()),
			"Error", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
		Raise ErrorProcessing.BriefErrorDescription(ErrorInfo()) + Chars.LF 
			+ NStr("en = 'Install or reinstall OpenOffice.org Writer.';");
	EndTry;	
	
	// 
	DocumentParameters = New COMSafeArray("VT_VARIANT", 1);
	RunMode = AssignValueToProperty(ServiceManagerObject,
		"MacroExecutionMode",
		0); // const short NEVER_EXECUTE = 0
	DocumentParameters.SetValue(0, RunMode);
	
	// 
	DesktopObject.loadComponentFromURL(ConvertToURL(PathToFile2), "_blank", 0, DocumentParameters);
	
	CurrentWindow = DesktopObject.getCurrentFrame();
	
	// 
	CompareParameters = New COMSafeArray("VT_VARIANT", 1);
	CompareParameters.SetValue(0, AssignValueToProperty(ServiceManagerObject, "ShowTrackedChanges", True));
	DispatcherHelperObject.executeDispatch(CurrentWindow, ".uno:ShowTrackedChanges", "", 0, CompareParameters);
	
	// 
	CallParameters = New COMSafeArray("VT_VARIANT", 1);
	CallParameters.SetValue(0, AssignValueToProperty(ServiceManagerObject, "URL", ConvertToURL(PathToFile1)));
	DispatcherHelperObject.executeDispatch(CurrentWindow, ".uno:CompareDocuments", "", 0, CallParameters);

#EndIf

EndProcedure

Procedure CompareMicrosoftWordFiles(PathToFile1, PathToFile2)
	
#If Not WebClient And Not MobileClient Then
	
	Try
		WordObject = New COMObject("Word.Application");
	Except
		EventLogClient.AddMessageForEventLog(
			NStr("en = 'Files.Compare files';", CommonClient.DefaultLanguageCode()),
			"Error", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
		Raise ErrorProcessing.BriefErrorDescription(ErrorInfo()) + Chars.LF 
			+ NStr("en = 'Install or reinstall Microsoft Word.';");
	EndTry;	
	WordObject.Visible = 0;
	WordObject.WordBasic.DisableAutoMacros(1);
	
	Document = WordObject.Documents.Open(PathToFile1);
	Try
		WordObject.ActiveWindow.ActivePane.View.Type = 1; // wdNormalView = 1
		Document.Merge(PathToFile2, 2, 0, 0); // MergeTarget:=wdMergeTargetSelected, DetectFormatChanges:=False, UseFormattingFrom:=wdFormattingFromCurrent
	Except
		EventLogClient.AddMessageForEventLog(
			NStr("en = 'Files.Compare files';", CommonClient.DefaultLanguageCode()),
			"Error", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
		Raise ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;	
	
	WordObject.Visible = 1;
	WordObject.Activate();
	
	Document.Close();

#EndIf

EndProcedure

Procedure CompareSpreadsheetDocuments1(PathToFile1, PathToFile2, TitleLeft, TitleRight)
	
	Files = New Array;
	Files.Add(New TransferableFileDescription(PathToFile1));
	Files.Add(New TransferableFileDescription(PathToFile2));
	
	PlacedFiles = New Array;
	If Not PutFiles(Files, PlacedFiles, , False) Then
		Return;
	EndIf;
	
	FormOpenParameters = StandardSubsystemsClient.SpreadsheetComparisonParameters();
	FormOpenParameters.TitleLeft = TitleLeft;
	FormOpenParameters.TitleRight = TitleRight;
	FormOpenParameters.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Compare %1 to %2';"), TitleLeft, TitleRight);
	StandardSubsystemsClient.ShowSpreadsheetComparison(PlacedFiles[0].Location, 
		PlacedFiles[1].Location, FormOpenParameters);
	
EndProcedure

// This function converts the Windows file name to an OpenOffice URL.
Function ConvertToURL(FileName)
	
	Return "file:///" + StrReplace(FileName, "\", "/");
	
EndFunction

// Creating a structure for OpenOffice parameters.
Function AssignValueToProperty(Object, PropertyName, PropertyValue)
	
	Properties = Object.Bridge_GetStruct("com.sun.star.beans.PropertyValue");
	Properties.Name = PropertyName;
	Properties.Value = PropertyValue;
	
	Return Properties;
	
EndFunction

// Returns the user data directory inside the standard application data directory.
// This directory can be used to store files captured by the current user.
// To use this method on the web client, you must first enable the extension for working with 1C:Company.
//
Function UserDataDir()
	
	#If WebClient Or MobileClient Then
		Return UserDataWorkDir();
	#Else
		If Not CommonClient.IsWindowsClient() Then
			Return UserDataWorkDir();
		Else
			Shell = New COMObject("WScript.Shell");
			UserDataDir = Shell.ExpandEnvironmentStrings("%APPDATA%");
			Return CommonClientServer.AddLastPathSeparator(UserDataDir);
		EndIf;
	#EndIf
	
EndFunction

// Opens the drag and drop form.
Procedure OpenDragFormFromOutside(FolderForAdding, FileNamesArray) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("FolderForAdding", FolderForAdding);
	FormParameters.Insert("FileNamesArray",   FileNamesArray);
	
	OpenForm("Catalog.Files.Form.DragForm", FormParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
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
//               
//             
//             
//
//   
//

// Displays the warning window, and after closing it, calls the handler with the specified result.
Procedure ReturnResultAfterShowWarning(Handler, WarningText, Result)
	
	If Handler <> Undefined Then
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Handler", CompletionHandler(Handler));
		HandlerParameters.Insert("Result", Result);
		Handler = New NotifyDescription("ReturnResultAfterCloseSimpleDialog", ThisObject, HandlerParameters);
		ShowMessageBox(Handler, WarningText);
	Else
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

// Displays the value view window, and after closing it, calls the handler with the specified result.
Procedure ReturnResultAfterShowValue(Handler, Value, Result)
	
	If Handler <> Undefined Then
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Handler", CompletionHandler(Handler));
		HandlerParameters.Insert("Result", Result);
		Handler = New NotifyDescription("ReturnResultAfterCloseSimpleDialog", ThisObject, HandlerParameters);
		ShowValue(Handler, Value);
	Else
		ShowValue(, Value);
	EndIf;
	
EndProcedure

// 
Procedure ReturnResultAfterCloseSimpleDialog(Structure) Export
	
	If TypeOf(Structure.Handler) = Type("NotifyDescription") Then
		ExecuteNotifyProcessing(Structure.Handler, Structure.Result);
	EndIf;
	
EndProcedure

// Returns the result of a direct call when no dialogs were opened.
Procedure ReturnResult(Handler, Result) Export
	
	Handler = PrepareHandlerForDirectCall(Handler, Result);
	If TypeOf(Handler) = Type("NotifyDescription") Then
		ExecuteNotifyProcessing(Handler, Result);
	EndIf;
	
EndProcedure

// Records information necessary for the preparation of a handler for asynchronous dialogue.
Procedure RegisterCompletionHandler(ExecutionParameters, CompletionHandler) Export
	
	AsynchronousDialog = New Structure;
	AsynchronousDialog.Insert("Module",                 CompletionHandler.Module);
	AsynchronousDialog.Insert("ProcedureName",           CompletionHandler.ProcedureName);
	AsynchronousDialog.Insert("Open",                 False);
	AsynchronousDialog.Insert("ResultWhenNotOpen", Undefined);
	ExecutionParameters.Insert("AsynchronousDialog", AsynchronousDialog);
	
EndProcedure

// Preparation of a handler for asynchronous dialogue.
Function CompletionHandler(HandlerOrStructure)
	
	Handler = Undefined;
	If TypeOf(HandlerOrStructure) = Type("Structure") Then
		SetLockingFormFlag(HandlerOrStructure, True);
		AsynchronousDialog = Undefined;
		If HandlerOrStructure.Property("AsynchronousDialog", AsynchronousDialog) Then
			Handler = New NotifyDescription(AsynchronousDialog.ProcedureName, AsynchronousDialog.Module,	
				HandlerOrStructure);
		EndIf;
	Else
		Handler = HandlerOrStructure;
	EndIf;
	Return Handler;
	
EndFunction

Procedure SetLockingFormFlag(ExecutionParameters, Value) Export
	
	// 
	If ExecutionParameters.Property("ResultHandler") Then
		ExecutionParameters.ResultHandler = CompletionHandler(ExecutionParameters.ResultHandler);
	EndIf;
	AsynchronousDialog = Undefined;
	If ExecutionParameters.Property("AsynchronousDialog", AsynchronousDialog) Then
		AsynchronousDialog.Open = Value;
	EndIf;
	
EndProcedure

Function LockingFormOpen(ExecutionParameters) Export
	
	AsynchronousDialog = Undefined;
	If ExecutionParameters.Property("AsynchronousDialog", AsynchronousDialog) Then
		Return AsynchronousDialog.Open;
	EndIf;
	Return False;
	
EndFunction

// Preparing a direct call handler without opening a dialog.
Function PrepareHandlerForDirectCall(HandlerOrStructure, Result)
	
	If TypeOf(HandlerOrStructure) = Type("Structure") Then
		If HandlerOrStructure.Property("AsynchronousDialog") Then
			HandlerOrStructure.AsynchronousDialog.ResultWhenNotOpen = Result;
		EndIf;
		Return Undefined; // 
	Else
		Return HandlerOrStructure;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
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
//  Notification - NotifyDescription - 
//   :
//     * ErrorDescription - String -  error text if one of the actions failed.
//     * Results     - Array - :
//             * File       - File -  initialized file object.
//                          - Undefined - 
//             * Exists - Boolean -  False if the file does not exist.
//
//  FileOperations - Array - :
//    * Action - String    -  Get Properties, Set Properties, Delete, Copy From Source,
//                             Create A Directory, Get It, And Place It.
//    * File     - String    -  full name of the file on the computer.
//               - File      - 
//    * Properties - see properties that can be obtained or set.
//    * Source - String    -  the full name of the file on the computer from which you want to create a copy.
//    * Address    - String    -  the address of the file's binary data, such as the address of temporary storage.
//    * ErrorTitle - String -  the text to which you want to add a newline and the errors view.
//
Procedure ProcessFile(Notification, FileOperations, FormIdentifier = Undefined)
	
	Context = New Structure;
	Context.Insert("Notification",         Notification);
	Context.Insert("FileOperations",    FileOperations);
	Context.Insert("FormIdentifier", FormIdentifier);
	
	Context.Insert("ActionsResult", New Structure);
	Context.ActionsResult.Insert("ErrorDescription", "");
	Context.ActionsResult.Insert("Results", New Array);
	
	Context.Insert("IndexOf", -1);
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the Processfile procedure.
//
// Parameters:
//   Context - Structure:
//     * ActionsResult - Structure:
//       ** Results - Array
//
Procedure ProcessFileLoopStart(Context)
	
	If Context.IndexOf + 1 >= Context.FileOperations.Count() Then
		ExecuteNotifyProcessing(Context.Notification, Context.ActionsResult);
		Return;
	EndIf;
	
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("ActionDetails", Context.FileOperations[Context.IndexOf]);
	
	Context.Insert("Result",  New Structure);
	Context.Result.Insert("File", Undefined);
	Context.Result.Insert("Exists", False);
	
	Context.ActionsResult.Results.Add(Context.Result);
	
	Context.Insert("PropertiesForGetting", New Structure);
	Context.Insert("PropertiesForInstalling", New Structure);
	
	Action = Context.ActionDetails.Action;
	File = Context.ActionDetails.File;
	FullFileName = ?(TypeOf(File) = Type("File"), File.FullName, File);
	
	If Action = "Delete" Then
		BeginDeletingFiles(New NotifyDescription(
			"ProcessFileAfterDeleteFiles", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), FullFileName);
		Return;
	
	ElsIf Action = "CopyFromSource" Then
		BeginCopyingFile(New NotifyDescription(
			"ProcessFileAfterCopyFile", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.ActionDetails.Source, FullFileName);
		Return;
	
	ElsIf Action = "CreateDirectory" Then
		BeginCreatingDirectory(New NotifyDescription(
			"ProcessFileAfterCreateDirectory", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), FullFileName);
		Return;
	
	ElsIf Action = "Get" Then
		FileDetails = New TransferableFileDescription(FullFileName, Context.ActionDetails.Address);
		FilesToObtain = New Array;
		FilesToObtain.Add(FileDetails);
		BeginGettingFiles(New NotifyDescription(
				"ProcessFileAfterGetFiles", ThisObject, Context,
				"ProcessFileAfterError", ThisObject),
			FilesToObtain, , False);
		Return;
	
	ElsIf Action = "Into" Then
		FileDetails = New TransferableFileDescription(FullFileName);
		Files = New Array;
		Files.Add(FileDetails);
		BeginPuttingFiles(New NotifyDescription(
				"ProcessFileAfterPutFiles", ThisObject, Context,
				"ProcessFileAfterError", ThisObject),
			Files, , False, Context.FormIdentifier);
		Return;
	
	ElsIf Action = "GetProperties" Then
		Context.Insert("PropertiesForGetting", Context.ActionDetails.Properties);
		
	ElsIf Action = "SetProperties1" Then
		Context.Insert("PropertiesForInstalling", Context.ActionDetails.Properties);
	EndIf;
	
	Context.Insert("File", ?(TypeOf(File) = Type("File"), File, New File(File)));
	Context.Result.Insert("File", Context.File);
	FillPropertyValues(Context.PropertiesForGetting, Context.File);
	Context.File.BeginCheckingExistence(New NotifyDescription(
		"ProcessFileAfterCheckExistence", ThisObject, Context,
		"ProcessFileAfterError", ThisObject));
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	If TypeOf(ErrorInfo) = Type("ErrorInfo") Then
		Context.ActionsResult.ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	Else
		Context.ActionsResult.ErrorDescription = ErrorInfo;
	EndIf;
	
	If Context.ActionDetails.Property("ErrorTitle") Then
		Context.ActionsResult.ErrorDescription = Context.ActionDetails.ErrorTitle
			+ Chars.LF + Context.ActionsResult.ErrorDescription;
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, Context.ActionsResult);
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterDeleteFiles(Context) Export
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterCopyFile(CopiedFile, Context) Export
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterCreateDirectory(DirectoryName, Context) Export
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterGetFiles(ObtainedFiles, Context) Export
	
	If TypeOf(ObtainedFiles) <> Type("Array") Or ObtainedFiles.Count() = 0 Then
		ProcessFileAfterError(NStr("en = 'Getting the file was canceled.';"), Undefined, Context);
		Return;
	EndIf;
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterPutFiles(PlacedFiles, Context) Export
	
	If TypeOf(PlacedFiles) <> Type("Array") Or PlacedFiles.Count() = 0 Then
		ProcessFileAfterError(NStr("en = 'Storing the file was canceled.';"), Undefined, Context);
		Return;
	EndIf;
	
	Context.ActionDetails.Insert("Address", PlacedFiles[0].Location);
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the Processfile procedure.
//
// Parameters:
//  Exists - Boolean
//  Context- Structure:
//   * Result - Structure
//
Procedure ProcessFileAfterCheckExistence(Exists, Context) Export
	
	Context.Result.Insert("Exists", Exists);
	
	If Not Context.Result.Exists Then
		ProcessFileLoopStart(Context);
		Return;
	EndIf;
	
	If Context.PropertiesForGetting.Count() = 0 Then
		ProcessFileAfterCheckIsFile(Null, Context);
		
	ElsIf Context.PropertiesForGetting.Property("Modified") Then
		Context.File.BeginGettingModificationTime(New NotifyDescription(
			"ProcessFileAfterGetModificationTime", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetModificationTime(Null, Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterGetModificationTime(Modified, Context) Export
	
	If Modified <> Null Then
		Context.PropertiesForGetting.Modified = Modified;
	EndIf;
	
	If Context.PropertiesForGetting.Property("UniversalModificationTime") Then
		Context.File.BeginGettingModificationUniversalTime(New NotifyDescription(
			"ProcessFileAfterGetUniversalModificationTime", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetUniversalModificationTime(Null, Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterGetUniversalModificationTime(UniversalModificationTime, Context) Export
	
	If UniversalModificationTime <> Null Then
		Context.PropertiesForGetting.UniversalModificationTime = UniversalModificationTime;
	EndIf;
	
	If Context.PropertiesForGetting.Property("ReadOnly") Then
		Context.File.BeginGettingReadOnly(New NotifyDescription(
			"ProcessFileAfterGetReadOnly", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetReadOnly(Null, Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterGetReadOnly(ReadOnly, Context) Export
	
	If ReadOnly <> Null Then
		Context.PropertiesForGetting.ReadOnly = ReadOnly;
	EndIf;
	
	If Context.PropertiesForGetting.Property("Invisibility") Then
		Context.File.BeginGettingHidden(New NotifyDescription(
			"ProcessFileAfterGetInvisibility", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetInvisibility(Null, Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
//
// Parameters:
//  Invisibility - Boolean
//  Context - Structure:
//     * File - File
//     * PropertiesForGetting - Structure:
//       ** Size - Number
//       ** IsDirectory - Boolean
//
Procedure ProcessFileAfterGetInvisibility(Invisibility, Context) Export
	
	If Invisibility <> Null Then
		Context.PropertiesForGetting.Invisibility = Invisibility;
	EndIf;
	
	If Context.PropertiesForGetting.Property("Size") Then
		Context.File.BeginGettingSize(New NotifyDescription(
			"ProcessFileAfterGetSize", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetSize(Null, Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterGetSize(Size, Context) Export
	
	If Size <> Null Then
		Context.PropertiesForGetting.Size = Size;
	EndIf;
	
	If Context.PropertiesForGetting.Property("IsDirectory") Then
		Context.File.BeginCheckingIsDirectory(New NotifyDescription(
			"ProcessFileAfterCheckIsDirectory", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterCheckIsDirectory(Null, Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterCheckIsDirectory(IsDirectory, Context) Export
	
	If IsDirectory <> Null Then
		Context.PropertiesForGetting.IsDirectory = IsDirectory;
	EndIf;
	
	If Context.PropertiesForGetting.Property("IsFile") Then
		Context.File.BeginCheckingIsFile(New NotifyDescription(
			"ProcessFileAfterCheckIsFile", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterCheckIsFile(Null, Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterCheckIsFile(IsFile, Context) Export
	
	If IsFile <> Null Then
		Context.PropertiesForGetting.IsFile = IsFile;
	EndIf;
	
	If Context.PropertiesForInstalling.Count() = 0 Then
		ProcessFileAfterSetInvisibility(Context);
		
	ElsIf Context.PropertiesForInstalling.Property("Modified") Then
		Context.File.BeginSettingModificationTime(New NotifyDescription(
			"ProcessFileAfterSetModificationTime", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.PropertiesForInstalling.Modified);
	Else
		ProcessFileAfterSetModificationTime(Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterSetModificationTime(Context) Export
	
	If Context.PropertiesForInstalling.Property("UniversalModificationTime") Then
		Context.File.BeginSettingModificationUniversalTime(New NotifyDescription(
			"ProcessFileAfterSetUniversalModificationTime", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.PropertiesForInstalling.UniversalModificationTime);
	Else
		ProcessFileAfterSetUniversalModificationTime(Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterSetUniversalModificationTime(Context) Export
	
	If Context.PropertiesForInstalling.Property("ReadOnly") Then
		Context.File.BeginSettingReadOnly(New NotifyDescription(
			"ProcessFileAfterSetReadOnly", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.PropertiesForInstalling.ReadOnly);
	Else
		ProcessFileAfterSetReadOnly(Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterSetReadOnly(Context) Export
	
	If Context.PropertiesForInstalling.Property("Invisibility") Then
		Context.File.BeginSettingHidden(New NotifyDescription(
			"ProcessFileAfterSetInvisibility", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.PropertiesForInstalling.Invisibility);
	Else
		ProcessFileAfterSetInvisibility(Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterSetInvisibility(Context) Export
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// 
Function PutFileFromHardDriveInTempStorage(FullFileName, FileAddress = "", UUID = Undefined)
	If Not FileSystemExtensionAttached1() Then
		Return Undefined;
	EndIf;
	WhatToUpload = New Array;
	WhatToUpload.Add(New TransferableFileDescription(FullFileName, FileAddress));
	ImportResult1 = New Array;
	FileImported = PutFiles(WhatToUpload, ImportResult1, , False, UUID);
	If Not FileImported Or ImportResult1.Count() = 0 Then
		Return Undefined;
	EndIf;
	Return ImportResult1[0].Location;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Procedure InitAddIn(NotificationOfReturn, SuggestInstall = False) Export
	
	If Not ScanAvailable() Then 
		AddInAttachmentResult = CommonInternalClient.AddInAttachmentResult();
		AddInAttachmentResult.Attached = False;
		AddInAttachmentResult.ErrorDescription = NStr("en = 'Scanning is supported on Windows and Linux only.';");
		ExecuteNotifyProcessing(NotificationOfReturn, AddInAttachmentResult);
		Return;
	EndIf;
	
	ConnectionParameters = CommonClient.AddInAttachmentParameters();
	ConnectionParameters.ExplanationText = NStr("en = 'To continue, attach a scanning add-in.';");
	ConnectionParameters.SuggestInstall = SuggestInstall;
	
	ComponentDetails = FilesOperationsInternalClientServer.ComponentDetails();
	CommonClient.AttachAddInFromTemplate(NotificationOfReturn, ComponentDetails.ObjectName, ComponentDetails.FullTemplateName, ConnectionParameters);
	
EndProcedure

Function ScanAvailable(IsSettingsCheck = False) Export
	
	If IsSettingsCheck Then
		#If MobileClient Then
			Return MultimediaTools.PhotoSupported();
		#ElsIf WebClient Then
			Return False;
		#Else
			Return CommonClient.ClientPlatformType() = PlatformType.Windows_x86 
			Or CommonClient.ClientPlatformType() = PlatformType.Windows_x86_64
			Or CommonClient.ClientPlatformType() = PlatformType.Linux_x86 
			Or CommonClient.ClientPlatformType() = PlatformType.Linux_x86_64;
		#EndIf
	Else
		#If MobileClient Or WebClient Then
			Return False;
		#Else
			Return CommonClient.ClientPlatformType() = PlatformType.Windows_x86 
			Or CommonClient.ClientPlatformType() = PlatformType.Windows_x86_64
			Or CommonClient.ClientPlatformType() = PlatformType.Linux_x86 
			Or CommonClient.ClientPlatformType() = PlatformType.Linux_x86_64;
		#EndIf
	EndIf;
	
EndFunction

// 
Function EnumDevices(Form, Attachable_Module) Export
	
	Devices = ConnectedDevices(Form, Attachable_Module);
	
	Return Devices;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 
//
Function ClientSupportsSynchronousCalls()
	
#If WebClient Then
	// 
	SystemInfo = New SystemInfo;
	ApplicationInformationArray = StrSplit(SystemInfo.UserAgentInformation, " ", False);
	
	For Each ApplicationInformation In ApplicationInformationArray Do
		If StrFind(ApplicationInformation, "Chrome") > 0 Or StrFind(ApplicationInformation, "Firefox") > 0 Then
			Return False;
		EndIf;
	EndDo;
#EndIf
	
	Return True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Select the file opening mode and start editing.
// Options "Edit", "Cancel".
//
// Parameters:
//   FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure SelectModeAndEditFile(ResultHandler, FileData, CommandEditAvailability) Export
	
	PersonalSettings = PersonalFilesOperationsSettings();
	ResultOpen = ?(FileData.CurrentUserEditsFile And CommandEditAvailability,
		"Edit", PersonalSettings.FileOpeningOption);
	
	OpeningMethod = PersonalSettings.TextFilesOpeningMethod;
	If OpeningMethod = PredefinedValue("Enum.OpenFileForViewingMethods.UsingBuiltInEditor") Then
		
		ExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
			PersonalSettings.TextFilesExtension,
			FileData.Extension);
		
		If ExtensionInList Then
			ReturnResult(ResultHandler, ResultOpen);
			Return;
		EndIf;
		
	EndIf;
	
	OpeningMethod = PersonalSettings.GraphicalSchemasOpeningMethod;
	If OpeningMethod = PredefinedValue("Enum.OpenFileForViewingMethods.UsingBuiltInEditor") Then
		
		ExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
			PersonalSettings.GraphicalSchemasExtension,
			FileData.Extension);
		
		If ExtensionInList Then
			ReturnResult(ResultHandler, ResultOpen);
			Return;
		EndIf;
		
	EndIf;
	
	// 
	If Not ValueIsFilled(FileData.BeingEditedBy)
		And PersonalSettings.PromptForEditModeOnOpenFile = True
		And CommandEditAvailability Then
		
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("ResultHandler", ResultHandler);
		Handler = New NotifyDescription("SelectModeAndEditFileCompletion", ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.OpeningModeChoiceForm", , , , , , Handler, FormWindowOpeningMode.LockWholeInterface);
		Return;
	EndIf;
	
	ReturnResult(ResultHandler, ResultOpen);
	
EndProcedure

Procedure SelectModeAndEditFileCompletion(Result, ExecutionParameters) Export
	
	ResultOpen = "Open";
	ResultEdit = "Edit";
	ResultCancel = "Cancel";
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.ResultHandler, ResultCancel);
		Return;
	EndIf;
	
	If Result.HowToOpen = 1 Then
		ReturnResult(ExecutionParameters.ResultHandler, ResultEdit);
		Return;
	EndIf;
	
	ReturnResult(ExecutionParameters.ResultHandler, ResultOpen);
	
EndProcedure

// 
// 
// Parameters:
//  Items - FormItems:
//    * List - FormTable
// 
// Returns:
//  Boolean
//
Function FileCommandsAvailable(Items) Export
	
	FileRef = Items.List.CurrentRow;
	
	If FileRef = Undefined Then 
		Return False;
	EndIf;
	
	If TypeOf(Items.List.CurrentRow) = Type("DynamicListGroupRow") Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////////
// 

Procedure DoPrintFileWithStamp(Ref, UUID) Export
	
	FileData = FilesOperationsInternalServerCall.GetFileData(
		Ref, UUID, True);
	
	If FileData.Encrypted Then
		EncryptionCertificatesArray = FileData.EncryptionCertificatesArray;
		GetDecryptedDataForPrinting(FileData, UUID);
	Else
		PrintFileWithStamp(FileData);
	EndIf;
	
EndProcedure

Procedure GetDecryptedDataForPrinting(FileData, UUID)
	
	FollowUpHandler = New NotifyDescription("PrintFileWithStampAfterDecryption", ThisObject,
		New Structure("FileData, UUID", FileData, UUID));
		
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ExecuteNotifyProcessing(FollowUpHandler, False);
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation", NStr("en = 'Decrypt file';"));
	DataDetails.Insert("DataTitle", NStr("en = 'File';"));
	DataDetails.Insert("Data", FileData.RefToBinaryFileData);
	DataDetails.Insert("Presentation", FileData.Ref);
	DataDetails.Insert("EncryptionCertificates",
		PutToTempStorage(FileData.EncryptionCertificatesArray, UUID));
	DataDetails.Insert("NotifyOnCompletion", False);

	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Decrypt(DataDetails,, FollowUpHandler);
	
EndProcedure

Procedure PrintFileWithStampAfterDecryption(DataDetails, Context) Export
	
	If Not DataDetails.Success Then
		Return;
	EndIf;
	
	If TypeOf(DataDetails.DecryptedData) = Type("BinaryData") Then
		FileAddress = PutToTempStorage(DataDetails.DecryptedData,
			Context.UUID);
	Else
		FileAddress = DataDetails.DecryptedData;
	EndIf;
	
	Context.FileData.RefToBinaryFileData = FileAddress;
		
	PrintFileWithStamp(Context.FileData);
	
EndProcedure

Procedure PrintFileWithStamp(FileData)
	
	Document = FilesOperationsInternalServerCall.DocumentWithStamp(FileData);
	
	DocumentName3 = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 (with stamp)';"), 
				FileData.Description);
	
	If TypeOf(Document) = Type("SpreadsheetDocument") Then
		If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
			ModulePrintManagerClient = CommonClient.CommonModule("PrintManagementClient");
			PrintFormID = "AttachedFile";
			Document.Protection = False;
			
			PrintFormsCollection = ModulePrintManagerClient.NewPrintFormsCollection(PrintFormID);
			PrintForm = ModulePrintManagerClient.PrintFormDetails(PrintFormsCollection, PrintFormID);
			PrintForm.TemplateSynonym = DocumentName3;
			PrintForm.SpreadsheetDocument = Document;
			
			ModulePrintManagerClient.PrintDocuments(PrintFormsCollection);
		Else
			Document.Print(PrintDialogUseMode.Use);
		EndIf;
	Else
		FileSystemClient.OpenFile(Document, , DocumentName3+".docx");
	EndIf;
	
EndProcedure

// 

// Continue the OpenFile procedure.
Procedure OpenFileAddInSuggested(FileSystemExtensionAttached1, AdditionalParameters) Export
	
	FileData = AdditionalParameters.FileData;
	ForEditing = AdditionalParameters.ForEditing;
	
	If FileSystemExtensionAttached1 Then
		
		UserWorkingDirectory = UserWorkingDirectory();
		FullFileNameAtClient = UserWorkingDirectory + FileData.RelativePath + FileData.FileName;
		FileOnHardDrive = New File(FullFileNameAtClient);
		
		AdditionalParameters.Insert("ForEditing", ForEditing);
		AdditionalParameters.Insert("UserWorkingDirectory", UserWorkingDirectory);
		AdditionalParameters.Insert("FileOnHardDrive", FileOnHardDrive);
		AdditionalParameters.Insert("FullFileNameAtClient", FullFileNameAtClient);
		
		If ValueIsFilled(FileData.BeingEditedBy) And ForEditing And FileOnHardDrive.Exists() Then
			FileOnHardDrive.SetReadOnly(False);
			GetFile = False;
		ElsIf FileOnHardDrive.Exists() Then
			NotifyDescription = New NotifyDescription("OpenFileDialogShown", ThisObject, AdditionalParameters);
			ShowDialogNeedToGetFileFromServer(NotifyDescription, FullFileNameAtClient, FileData, ForEditing);
			Return;
		Else
			GetFile = True;
		EndIf;
		
		OpenFileDialogShown(GetFile, AdditionalParameters);
	Else
		NotifyDescription = New NotifyDescription("OpenFileReminderShown", ThisObject, AdditionalParameters);
		OutputNotificationOnEdit(NotifyDescription);
	EndIf;
	
EndProcedure

// Continue the OpenFile procedure.
Procedure OpenFileReminderShown(ReminderResult, AdditionalParameters) Export
	
	If ReminderResult = DialogReturnCode.Cancel Or ReminderResult = Undefined Then
		Return;
	EndIf;
	
	FileData = AdditionalParameters.FileData;
	GetFile(FileData.RefToBinaryFileData, FileData.FileName, True);
	
EndProcedure

// Continue the OpenFile procedure.
Procedure OpenFileDialogShown(GetFile, AdditionalParameters) Export
	
	If GetFile = Undefined Then
		Return;
	EndIf;
	
	FileData = AdditionalParameters.FileData;
	ForEditing = AdditionalParameters.ForEditing;
	UserWorkingDirectory = AdditionalParameters.UserWorkingDirectory;
	FileOnHardDrive = AdditionalParameters.FileOnHardDrive;
	FullFileNameAtClient = AdditionalParameters.FullFileNameAtClient;
	
	CanOpenFile = True;
	If GetFile Then
		FullFileNameAtClient = "";
		CanOpenFile = GetFileToWorkingDirectory(
			FileData.RefToBinaryFileData,
			FileData.RelativePath,
			FileData.UniversalModificationDate,
			FileData.FileName,
			UserWorkingDirectory,
			FullFileNameAtClient);
	EndIf;
		
	If CanOpenFile Then
		
		If ForEditing Then
			FileOnHardDrive.SetReadOnly(False);
		Else
			FileOnHardDrive.SetReadOnly(True);
		EndIf;
		
		UUID = ?(AdditionalParameters.Property("UUID"),
			AdditionalParameters.UUID, Undefined);
			
		OpenFileWithApplication(FileData, FullFileNameAtClient, UUID);
		
	EndIf;
		
EndProcedure

Function GetFileToWorkingDirectory(Val FileBinaryDataAddress,
                                    Val RelativePath,
                                    Val UniversalModificationDate,
                                    Val FileName,
                                    Val UserWorkingDirectory,
                                    FullFileNameAtClient)
	
	If UserWorkingDirectory = Undefined
	 Or IsBlankString(UserWorkingDirectory) Then
		
		Return False;
	EndIf;
	
	DirectoryForSave = UserWorkingDirectory + RelativePath;
	
	Try
		CreateDirectory(DirectoryForSave);
	Except
		ErrorMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessage = NStr("en = 'An error occurred when creating a directory on the computer:';") + " " + ErrorMessage;
		CommonClient.MessageToUser(ErrorMessage);
		Return False;
	EndTry;
	
	File = New File(DirectoryForSave + FileName);
	If File.Exists() Then
		Try
			File.SetReadOnly(False);
			DeleteFiles(DirectoryForSave + FileName);
		Except
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
		EndTry;	
	EndIf;
	
	FileToReceive = New TransferableFileDescription(DirectoryForSave + FileName, FileBinaryDataAddress);
	FilesToObtain = New Array;
	FilesToObtain.Add(FileToReceive);
	
	ObtainedFiles = New Array;
	
	If GetFiles(FilesToObtain, ObtainedFiles, , False) Then
		FullFileNameAtClient = ObtainedFiles[0].FullName;
		SetModificationUniversalTime(FullFileNameAtClient, UniversalModificationDate);
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Parameters:
//   FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure ShowDialogNeedToGetFileFromServer(ResultHandler, Val FileNameWithPath, Val FileData, Val ForEditing)
	
	StandardFileData = New Structure;
	StandardFileData.Insert("UniversalModificationDate", FileData.UniversalModificationDate);
	StandardFileData.Insert("Size",                       FileData.Size);
	StandardFileData.Insert("InWorkingDirectoryForRead",     Not ForEditing);
	StandardFileData.Insert("BeingEditedBy",                  FileData.BeingEditedBy);
	
	// 
	// 
	
	Parameters = New Structure;
	Parameters.Insert("ResultHandler", ResultHandler);
	Parameters.Insert("FileNameWithPath", FileNameWithPath);
	NotifyDescription = New NotifyDescription("ShowDialogNeedToGetFileFromServerActionDefined", ThisObject, Parameters);
	ActionOnOpenFileInWorkingDirectory(NotifyDescription, FileNameWithPath, StandardFileData);
	
EndProcedure

// Continue the procedure to show the directory and get the file Server.
Procedure ShowDialogNeedToGetFileFromServerActionDefined(Action, AdditionalParameters) Export
	FileNameWithPath = AdditionalParameters.FileNameWithPath;
	
	If Action = "GetFromStorageAndOpen" Then
		File = New File(FileNameWithPath);
		Try
			File.SetReadOnly(False);
			DeleteFiles(FileNameWithPath);
		Except
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
			Result = Undefined;	
		EndTry;	
		Result = True;
	ElsIf Action = "OpenExistingFile" Then
		Result = False;
	Else // 
		Result = Undefined;
	EndIf;
	
	ExecuteNotifyProcessing(AdditionalParameters.ResultHandler, Result);
	
EndProcedure

Function IsReadyForScanning(Form, Attachable_Module) Export 
	IsDevicePresent = IsDevicePresent(Form, Attachable_Module);
	
	If IsDevicePresent Then
		Try
			ConnectedDevices(Form, Attachable_Module);
			Return True;
		Except
			Return False;
		EndTry;
	EndIf;
	Return False;
EndFunction

Function ConnectedDevices(Form, Attachable_Module)
	WriteScanLog("EnumDevices.Start");
	Try
		Devices = Attachable_Module.EnumDevices();
		ConnectedDevices = StrSplit(Devices, Chars.LF, False);
		WriteScanLog("EnumDevices.Result", 
			StringFunctionsClientServer.SubstituteParametersToString("EnumDevices() = %1", 
			StrConcat(ConnectedDevices, "|")));
	Except   
		ConnectedDevices = New Array;
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteScanLog("EnumDevices", ErrorPresentation, True);
		ShowScanError(Form, NStr("en = 'Cannot get the list of devices';"), ErrorPresentation);
	EndTry;
	Return ConnectedDevices;
EndFunction

// Returns the configuration of the scanner by name.
//
// Parameters:
//   Attachable_Module - 
//   DeviceName - String -  name of the scanner.
//   SettingName  - String -  name of the setting,
//       such as" XRESOLUTION", or" PIXELTYPE", or" ROTATION", or"SUPPORTEDSIZES".
//
// Returns:
//   Number - 
//
Function ScannerSetting(Form, Attachable_Module, DeviceName, SettingName) Export
	
	If Not ScanAvailable(True) Then
		Return -1;
	EndIf;
	
	Try
		WriteScanLog("GetSetting.Start", 
			StringFunctionsClientServer.SubstituteParametersToString("GetSetting(%1, %2)", 
				DeviceName, SettingName));
		SettingValue = Attachable_Module.GetSetting(DeviceName, SettingName);
		WriteScanLog("GetSetting.Result", 
			StringFunctionsClientServer.SubstituteParametersToString("GetSetting(%1, %2) = %3", 
				DeviceName, SettingName, SettingValue));
		
		Return SettingValue;
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteScanLog("GetSetting", ErrorPresentation, True);
		ShowScanError(Form, NStr("en = 'Cannot get the device settings.';"), ErrorPresentation);
		Return -1;
	EndTry;
	
EndFunction

Function IsDevicePresent(Form, Attachable_Module, ShowError_ = True) Export
	WriteScanLog("IsDevicePresent.Start");
	Try
		IsDevicePresent = Attachable_Module.IsDevicePresent();
		WriteScanLog("IsDevicePresent.Result", 
			StringFunctionsClientServer.SubstituteParametersToString("IsDevicePresent() = %1", IsDevicePresent));
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteScanLog("IsDevicePresent", ErrorPresentation, True);
		If ShowError_ Then
			ShowScanError(Form, NStr("en = 'Cannot check for devices';"), ErrorPresentation);
		EndIf;
		IsDevicePresent = False;
	EndTry;
	
	Return IsDevicePresent;
	
EndFunction

Procedure BeginScan(Form, Attachable_Module, ScanningParameters) Export
	
	DeflateParameter = ?(Upper(PictureFormat) = "JPG", ScanningParameters.JPGQuality, ScanningParameters.TIFFDeflation);
	EventText = "BeginScan" + StringFunctionsClientServer.SubstituteParametersToString("(%1, %2, %3, %4, %5, %6, %7, %8, %9)", 
		ScanningParameters.ShowDialogBox,
		ScanningParameters.SelectedDevice,
		ScanningParameters.PictureFormat,
		ScanningParameters.Resolution,
		ScanningParameters.Chromaticity,
		ScanningParameters.Rotation,
		ScanningParameters.PaperSize,
		DeflateParameter,
		ScanningParameters.DuplexScanning);
	WriteScanLog("BeginScan.Start", EventText);
		
	Try
		Attachable_Module.BeginScan(
			ScanningParameters.ShowDialogBox,
			ScanningParameters.SelectedDevice,
			ScanningParameters.PictureFormat,
			ScanningParameters.Resolution,
			ScanningParameters.Chromaticity,
			ScanningParameters.Rotation,
			ScanningParameters.PaperSize,
			DeflateParameter,
			ScanningParameters.DuplexScanning);
		WriteScanLog("BeginScan.Result", EventText);
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteScanLog("BeginScan", ErrorPresentation, True);
		ShowScanError(Form, NStr("en = 'Cannot scan the document';"), ErrorPresentation);
	EndTry;
	
EndProcedure

Procedure EnableScanLog(Attachable_Module, ContinueNotification, Val Restart_1 = False) Export 
	ClientID = ClientID();
	ScanLogParameters = FilesOperationsInternalServerCall.ScanLogParameters(ClientID);
	
	If Not Restart_1 Then
		Restart_1 = ScanLogParameters.ScanLogStartDate = Date(1,1,1);
	EndIf;
	
	NameOfLogFile = ScanLogParameters.NameOfLogFile;
	
	If Restart_1 And NameOfLogFile <> Undefined Then
		SetLogFileName(Attachable_Module, "");
		LogFile1 = New File(NameOfLogFile);
		If LogFile1.Exists() Then
			DeleteFiles(NameOfLogFile);
		EndIf;
	EndIf;	
	
	ScanLogCatalog = ScanLogParameters.ScanLogCatalog;
	UseScanLogDirectory  = ScanLogParameters.UseScanLogDirectory;
	
	Context = New Structure;
	Context.Insert("Attachable_Module", Attachable_Module);
	Context.Insert("ContinueNotification", ContinueNotification);
	
	NotificationAfterTempDirectoryToAttachLogFilesCreated = New NotifyDescription("NotificationAfterTempDirectoryToAttachLogFilesCreated",
		ThisObject, Context);      
	
	If UseScanLogDirectory And ScanLogCatalog <> Undefined Then
		Context = New Structure;
		Context.Insert("NotificationAfterTempDirectoryToAttachLogFilesCreated",
			NotificationAfterTempDirectoryToAttachLogFilesCreated);
		Context.Insert("ScanLogCatalog", ScanLogCatalog);
		Context.Insert("ClientID", ClientID);
		
		CheckResultNotification = New NotifyDescription("AfterScanLogDirAvailabilityChecked", ThisObject, Context);	
		CheckDirAvailability(CheckResultNotification, ScanLogCatalog);
		
	ElsIf Restart_1 And Not ValueIsFilled(NameOfLogFile) Then
		FileSystemClient.CreateTemporaryDirectory(NotificationAfterTempDirectoryToAttachLogFilesCreated);
	ElsIf Restart_1 Then
		Context = New Structure;
		Context.Insert("NameOfLogFile", NameOfLogFile);
		Context.Insert("NotificationAfterTempDirectoryToAttachLogFilesCreated",
			NotificationAfterTempDirectoryToAttachLogFilesCreated);
	
		CheckResultNotification = New NotifyDescription("AfterLogFileDirAvailabilityChecked", ThisObject, Context);
		LogFile1 = New File(NameOfLogFile);
		CheckDirAvailability(CheckResultNotification, LogFile1.Path);
	Else
		ExecuteNotifyProcessing(ContinueNotification);
	EndIf;
	
EndProcedure

Procedure AfterLogFileDirAvailabilityChecked(Result, ExternalContext) Export
	Notification = ExternalContext.NotificationAfterTempDirectoryToAttachLogFilesCreated;
	Attachable_Module = Notification.AdditionalParameters.Attachable_Module;
	If Not Result.Success Then
		FileSystemClient.CreateTemporaryDirectory(Notification);
	Else
		SetLogFileName(Attachable_Module, ExternalContext.NameOfLogFile);
		If Notification.AdditionalParameters.ContinueNotification <> Undefined Then
			ExecuteNotifyProcessing(Notification.AdditionalParameters.ContinueNotification);
		EndIf;
	EndIf;
	
EndProcedure

Procedure AfterScanLogDirAvailabilityChecked(Result, ExternalContext) Export
	If Not Result.Success Then
		FilesOperationsInternalServerCall.ResetScanLogDirectoryParameters(ExternalContext.ClientID);
		WriteScanLog("ComponentFile", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot access the scan log directory: %1. Your choice is not saved.';"), ExternalContext.ScanLogCatalog), True);
		ScanningSettings1 = New Structure;
		ScanningSettings1.Insert("ScanLogCatalog", "");
		ScanningSettings1.Insert("UseScanLogDirectory", False);
		Notify("ScanSettingsChanged", ScanningSettings1); 
		FileSystemClient.CreateTemporaryDirectory(ExternalContext.NotificationAfterTempDirectoryToAttachLogFilesCreated);
	Else
		ExecuteNotifyProcessing(ExternalContext.NotificationAfterTempDirectoryToAttachLogFilesCreated, 
			ExternalContext.ScanLogCatalog);
	EndIf;
	
EndProcedure

Procedure SetLogFileName(Attachable_Module, NameOfLogFile) 
	WriteScanLog("LogFilePath.ValueSetting", 
		StringFunctionsClientServer.SubstituteParametersToString("LogFilePath = %1", NameOfLogFile));
	Try
		Attachable_Module.LogFilePath = NameOfLogFile;
		WriteScanLog("LogFilePath.IsValueSet");
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteScanLog("LogFilePath", ErrorPresentation, True);
	EndTry;
EndProcedure

Procedure NotificationAfterTempDirectoryToAttachLogFilesCreated(ScanLogCatalog, Context) Export
		
	NameOfLogFile = ScanLogCatalog + GetPathSeparator() + "ImageScan.log";
	Attachable_Module = Context.Attachable_Module;
	SetLogFileName(Attachable_Module, NameOfLogFile);
	FilesOperationsInternalServerCall.SetScanLogStartParameters(NameOfLogFile);
	If Context.ContinueNotification <> Undefined Then
		ExecuteNotifyProcessing(Context.ContinueNotification);
	EndIf;
			
EndProcedure

Procedure WriteScanLog(Event, Comment = "", IsError = False) Export 
	
	EventLogClient.AddMessageForEventLog(
		NStr("en = 'Scan images';", CommonClient.DefaultLanguageCode()) + "." + Event,
		?(IsError, "Error", "Information"), Comment,, True);
	
EndProcedure

Procedure ShowScanError(Form, Title, DetailErrorDescription, AssistanceRequiredMode = False) Export

	FormOpenParameters = New Structure("Title, DetailErrorDescription", 
		Title, DetailErrorDescription);
	FormOpenParameters.Insert("ScannerName", Form.ScannerName);
	FormOpenParameters.Insert("ShowScannerDialog", Form.ShowScannerDialog);
	FormOpenParameters.Insert("AssistanceRequiredMode", AssistanceRequiredMode);
	FormOpenParameters.Insert("Resolution", Form.ResolutionEnum);
	
	Context = New Structure("AssistanceRequiredMode", AssistanceRequiredMode);
	AfterErrorFormClosed = New NotifyDescription("AfterErrorFormClosed", Form, Context);
	OpenForm("DataProcessor.Scanning.Form.ScanningError", FormOpenParameters, Form,,,, AfterErrorFormClosed);
	
EndProcedure

Function HasScanErrorOccurred() Export
	
	ScanJobParameters = CommonServerCall.CommonSettingsStorageLoad("ScanAddIn", "ScanJobParameters", Undefined);
	Return ScanJobParameters <> Undefined;
	
EndFunction

Procedure DeleteScanError(Attachable_Module, CompletionNotification = Undefined, ShouldClearAddInLog = True) Export
	
	CommonServerCall.CommonSettingsStorageSave("ScanAddIn", "ScanJobParameters", Undefined);
	EnableScanLog(Attachable_Module, CompletionNotification, ShouldClearAddInLog);
	
EndProcedure

Procedure GetTechnicalInformation(DetailErrorDescription, NotificationOnCompletion = Undefined) Export
	
	OpenFileDialog = New FileDialog(FileDialogMode.Save);
	OpenFileDialog.FullFileName = NStr("en = 'Technical information';");
	Filter = NStr("en = 'Issue report';") + "(*.zip)|*.zip";
	OpenFileDialog.Filter = Filter;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("en = 'Save technical information about the issue';");
	If Not OpenFileDialog.Choose() Then
		Return;
	EndIf;
	FilesNames = OpenFileDialog.SelectedFiles;
	If FilesNames.Count() = 0 Then
		Return;
	EndIf;
		
	Context = New Structure();
	Context.Insert("DetailErrorDescription", DetailErrorDescription);
	Context.Insert("NotificationAfterTechnicalInfoObtained", NotificationOnCompletion);
	Context.Insert("FileName", FilesNames[0]);
	NotifyDescription = New NotifyDescription("AfterLogFilesTempDirectoryCreated", ThisObject, Context);
	FileSystemClient.CreateTemporaryDirectory(NotifyDescription);

EndProcedure

Procedure AfterLogFilesTempDirectoryCreated(DirectoryName, Context) Export
#If Not WebClient Then	
	TempFilesDir = DirectoryName + GetPathSeparator();
	TechnicalInformation = FilesOperationsInternalServerCall.TechnicalInformation();
	
	FilesForDeletion = New Array;
	RecordZIP = New ZipFileWriter(Context.FileName);
	NameOfLogFile = TechnicalInformation.NameOfLogFile;
	If NameOfLogFile = Undefined Then
		WriteScanLog("ComponentFile", NStr("en = 'Specify the name of the scanning add-in log file.';"), True);
	Else
		Log_File = New File(NameOfLogFile);
		LogFileNameForSaving = "";
		
		If Log_File.Exists() Then
			LogFileNameForSaving = TempFilesDir + "ImageScan.log";
			MoveFile(NameOfLogFile, LogFileNameForSaving);
			RecordZIP.Add(LogFileNameForSaving);
		Else
			WriteScanLog("ComponentFile", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The scanning add-in log file does not exist. %1';"), 
				NameOfLogFile), True);
		EndIf;
	EndIf;
	
	ContextOutgoing = New Structure;
	Context.Insert("RecordZIP", RecordZIP);
	Context.Insert("FilesForDeletion", FilesForDeletion);
	Context.Insert("TempFilesDir", TempFilesDir);
	Context.Insert("TechnicalInformation", TechnicalInformation);
	
	Text =  NStr("en = 'Computer information:';") + Chars.LF + StandardSubsystemsClient.SupportInformation();
	Context.Insert("SummaryInfoText", Text);
		
	NotifyDescription = New NotifyDescription("SummaryInfoAfterAddInObtained", ThisObject, Context);
	InitAddIn(NotifyDescription, True);
#EndIf
EndProcedure

Procedure SummaryInfoAfterAddInObtained(InitializationResult, Context) Export
#If Not WebClient Then
	SummaryInfoText = Context.SummaryInfoText;
	TechnicalInformation = Context.TechnicalInformation;
	FilesForDeletion = Context.FilesForDeletion;
	RecordZIP = Context.RecordZIP;
	AddInInformation = "";
	Attachable_Module = Undefined;
	If InitializationResult.Attached Then
		Try
			Attachable_Module = InitializationResult.Attachable_Module;
			VersionComponents = Attachable_Module.Version();
			AddInInformation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = '%1 add-in version: %2';"), "ImageScan", VersionComponents);
		Except
			WriteScanLog("Version", ErrorProcessing.DetailErrorDescription(ErrorInfo()), True);
		EndTry;
	Else
		Return;
	EndIf;
	
	SummaryInfoText = SummaryInfoText + Chars.LF + AddInInformation
		+ Chars.LF + Chars.LF + NStr("en = 'Technical information';") + ":" 
		+ Chars.LF + Context.DetailErrorDescription
		+ Chars.LF + Chars.LF;
		
	If CommonClient.FileInfobase() Then
		WorkMode = ?(CommonClient.ClientConnectedOverWebServer(),
			NStr("en = 'File mode via web';"), NStr("en = 'File';"));
	Else
		WorkMode = NStr("en = 'Client/server';");
	EndIf;
	
	SummaryInfoText = SummaryInfoText + NStr("en = 'Infobase operation mode';")+ " - " + WorkMode;
	
	SummaryInfoFileName = Context.TempFilesDir + "SummaryInformation.txt";
	
	SummaryInfoText = SummaryInfoText + Chars.LF 
		+ TechnicalInformation.TechnicalInfoOnExtensionsAndSubsystemsVersions + Chars.LF;
	SummaryInformation = GetBinaryDataFromString(SummaryInfoText);
	SummaryInformation.Write(SummaryInfoFileName);
	FilesForDeletion.Add(SummaryInfoFileName);
	RecordZIP.Add(SummaryInfoFileName);
	
	LogFileName = Context.TempFilesDir + "EventLog.xml";
	EventLog = TechnicalInformation.EventLog; // BinaryData
	EventLog.Write(LogFileName); // 
	FilesForDeletion.Add(LogFileName);
	RecordZIP.Add(LogFileName); 
	
	CompletionContext = New Structure;
	CompletionContext.Insert("SummaryInfoFileName", SummaryInfoFileName);
	RecordZIP.Write();
	For Each FileToDelete In FilesForDeletion Do
		DeleteFiles(FileToDelete);
	EndDo;
	CompletionNotification = New NotifyDescription("SummaryInfoAfterAddInObtainedAndScanErrorDeleted", ThisObject, Context);
	DeleteScanError(Attachable_Module, CompletionNotification);
#EndIf
EndProcedure

Procedure SummaryInfoAfterAddInObtainedAndScanErrorDeleted(Result, Context) Export
	If Context.NotificationAfterTechnicalInfoObtained <> Undefined Then
		ExecuteNotifyProcessing(Context.NotificationAfterTechnicalInfoObtained);
	EndIf; 
EndProcedure

#Region FilesAndVersionsDataDeletion

Procedure DeleteData(CompletionHandler, FileOrVersion, UUID) Export
	
	If Not ValueIsFilled(FileOrVersion) Then
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("FileOrVersion",           FileOrVersion);
	Context.Insert("CompletionHandler",    CompletionHandler);
	Context.Insert("UUID", UUID);
	
	If TypeOf(FileOrVersion) <> Type("CatalogRef.FilesVersions") Then
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Do you want to delete the %1 file permanently?';"),
			String(FileOrVersion));
		TitleText = NStr("en = 'Delete file';");
	Else
		QueryText   = NStr("en = 'Do you want to delete the file version permanently?';");
		TitleText = NStr("en = 'Delete file version';");
	EndIf;
	
	ShowQueryBox(New NotifyDescription("DeleteDataAfterRespondQuestion", ThisObject, Context),
		QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.No, TitleText, DialogReturnCode.No);
	
EndProcedure

Procedure DeleteDataAfterRespondQuestion(Response, Context) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Result = FilesOperationsInternalServerCall.FilesDeletionResult(
		CommonClientServer.ValueInArray(Context.FileOrVersion),
		Context.UUID);
	Result = Result[Context.FileOrVersion];
	
	If Result.Files.Count() > 0 Then
		Result.Insert("FileToRemoveIndex", 0);
		Result.Insert("CompletionHandler", Context.CompletionHandler);
		StartRemoveFileFromCache(Result);
	Else
		NotifyOfDataDeletion(Context.CompletionHandler, Result.WarningText);
	EndIf;
	
EndProcedure

Procedure StartRemoveFileFromCache(Context)
	
	Notification = New NotifyDescription("AfterRemoveFileFromCache", ThisObject, Context);
	DeleteFileFromWorkingDirectory(Notification, Context.Files[Context.FileToRemoveIndex], True);
	
EndProcedure

Procedure AfterRemoveFileFromCache(DeletionResult, Context) Export
	
	If Context.FileToRemoveIndex < Context.Files.Count() - 1 Then
		Context.FileToRemoveIndex = Context.FileToRemoveIndex + 1;
		StartRemoveFileFromCache(Context);
		Return;
	EndIf;
	
	NotifyOfDataDeletion(Context.CompletionHandler, Context.WarningText)
	
EndProcedure

Procedure NotifyOfDataDeletion(CompletionHandler, WarningText)
	
	Notify("Write_File", FileWriteNotificationParameters());
	If Not IsBlankString(WarningText) Then
		ShowMessageBox(CompletionHandler, WarningText);
	ElsIf CompletionHandler <> Undefined Then
		ExecuteNotifyProcessing(CompletionHandler);
	EndIf;
	
EndProcedure

Procedure ChangeFilterByDeletionMark(Area, CommandButton) Export
	
	CommandButton.Check = Not CommandButton.Check;
	CommonClientServer.ChangeFilterItems(Area, "DeletionMark",
		"HideDeletionMarkByDefault", False, DataCompositionComparisonType.Equal,
		Not CommandButton.Check, DataCompositionSettingsItemViewMode.Inaccessible);
		
EndProcedure

Procedure DeleteFilesData(CompletionHandler, FilesOrVersions, UUID) Export
	
	If FilesOrVersions.Count() = 0 Then
		ExecuteNotifyProcessing(CompletionHandler, Undefined);
	EndIf;
	
	Context = New Structure;
	Context.Insert("FilesOrVersions",           FilesOrVersions);
	Context.Insert("CompletionHandler",    CompletionHandler);
	Context.Insert("UUID", UUID);
	
	FileOrVersion = FilesOrVersions[0];
	If FilesOrVersions.Count() = 1 Then
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Do you want to delete the %1 file permanently?';"),
			String(FileOrVersion));
		TitleText = NStr("en = 'Delete file';");
	Else
		QueryText = NStr("en = 'Do you want to delete the files permanently?';");
		TitleText = NStr("en = 'Delete files';");
	EndIf;
	
	ShowQueryBox(New NotifyDescription("DeleteFilesDataAfterQuestionAnswered", ThisObject, Context),
		QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.No, TitleText, DialogReturnCode.No);
EndProcedure

Procedure DeleteFilesDataAfterQuestionAnswered(Response, Context) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	DeletionResults = FilesOperationsInternalServerCall.FilesDeletionResult(
		Context.FilesOrVersions, Context.UUID);
		
	Warnings = New Map;
	Result = New Structure("Files,FileToRemoveIndex,CompletionHandler,WarningText", New Array, 0);
	
	For Each DeletionResult In DeletionResults Do
		If DeletionResult.Value.Files.Count() > 0 Then
			CommonClientServer.SupplementArray(Result.Files, DeletionResult.Value.Files);
		Else
			Warnings.Insert(DeletionResult.Key, DeletionResult.Value.WarningText);
		EndIf;
	EndDo;
	
	If Result.Files.Count() > 0 Then
		
		Result.Insert("FileToRemoveIndex", 0);
		Result.Insert("CompletionHandler", Context.CompletionHandler);
		
		StartRemoveFileFromCache(Result);
		
	EndIf;
	
	If Warnings.Count() > 0 Then
		WarningText = "";
		For Each Warning In Warnings Do
			WarningText = ?(WarningText = "", "", Chars.LF)
				+ StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1: %2';"), Warning.Key, Warning.Value);
		EndDo;
		NotifyOfDataDeletion(Context.CompletionHandler, WarningText);
	EndIf;
	
EndProcedure
	
#EndRegion

Procedure CheckDirAvailabilityAfterCreated(TestDirectoryName, Context) Export
	
	Notification = New NotifyDescription("CheckDirAvailabilityAfterDeleted", ThisObject, 
		Context, "CheckDirAvailabilityDeletionError", ThisObject);
	BeginDeletingFiles(Notification, TestDirectoryName);
	
EndProcedure

Function DirAvailabilityCheckResult()
	Result = New Structure;
	Result.Insert("Success", False);
	Result.Insert("Create", False);
	Result.Insert("Delete", False);
	Result.Insert("ErrorInfo");
	Return Result;
EndFunction

Procedure CheckDirAvailabilityAfterDeleted(Context) Export
	
	Result = DirAvailabilityCheckResult();
	Result.Success = True;
	Result.Create = True;
	Result.Delete = True;
	
	ExecuteNotifyProcessing(Context.NotificationOfResult, Result);
	
EndProcedure

Procedure CheckDirAvailabilityCreationError(ErrorInfo, StandardProcessing, Context) Export
	
	Result = DirAvailabilityCheckResult();
	Result.ErrorInfo = ErrorInfo;
	StandardProcessing = False;
	
	ExecuteNotifyProcessing(Context.NotificationOfResult, Result);

EndProcedure

Procedure CheckDirAvailabilityDeletionError(ErrorInfo, StandardProcessing, Context) Export
	
	Result = DirAvailabilityCheckResult();
	Result.Create = True;
	Result.ErrorInfo = ErrorInfo;
	StandardProcessing = False;
	
	ExecuteNotifyProcessing(Context.NotificationOfResult, Result);

EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
Procedure AfterFilesRecovered(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		ProgressDetailedInfo = GetFromTempStorage(Result.ResultAddress);
		If ProgressDetailedInfo.Processed < ProgressDetailedInfo.Total Then
			Message = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Restored file info: %1 out of %1. For details, see Event log.';"),
				ProgressDetailedInfo.Processed, ProgressDetailedInfo.Total);
			ShowUserNotification(NStr("en = 'Restore file info';"),,
				Message, PictureLib.DialogExclamation, UserNotificationStatus.Important);
		ElsIf ProgressDetailedInfo.Total > 0 Then
			ShowUserNotification(NStr("en = 'Restore file info';"),,
				NStr("en = 'File info is restored. Updating the report…';"));
		Else
			ShowMessageBox(, NStr("en = 'No corrupted files to recover.';"));
			Return;
		EndIf;
		
		AdditionalParameters.ReportForm.ComposeResult();
		
	ElsIf Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
	EndIf;
	
EndProcedure

Function FileNameAndExtension(File)
#If MobileClient Then
	PresentationOnMobileDevice = File.GetMobileDeviceLibraryFilePresentation();
	FileExtention = CommonClientServer.GetFileNameExtension(PresentationOnMobileDevice);
	FileNameWithoutExtension = StrReplace(PresentationOnMobileDevice, "." + FileExtention, "");
#Else
	FileExtention = CommonClientServer.ExtensionWithoutPoint(File.Extension);
	FileNameWithoutExtension = File.BaseName;
#EndIf
	Result = New Structure;
	Result.Insert("FileExtention", FileExtention);
	Result.Insert("FileNameWithoutExtension", FileNameWithoutExtension);
	
	Return Result;
EndFunction

#EndRegion
