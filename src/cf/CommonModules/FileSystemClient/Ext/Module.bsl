///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region FilesImport

// Displays the file selection dialog and places the selected file in temporary storage.
// Combines the work of the global context methods beginmessage of a File and beginmessage of Files,
// returning an identical result regardless of whether the extension for working with 1C is enabled or not:Company.
// Limitations:
//   Not used for selecting directories - this option is not supported by the web client.
//
// Parameters:
//   CompletionHandler - NotifyDescription - 
//                             :
//      * FileThatWasPut - Undefined - 
//                       - Structure    - :
//                           ** Location  - String -  location of data in temporary storage.
//                           ** Name       - String - 
//                                        
//                                        
//                                        
//      * AdditionalParameters - Arbitrary -  the value that was specified when creating the object
//                                Description of the announcement.
//   ImportParameters         - See FileSystemClient.FileImportParameters.
//   FileName                  - String -  the full path to the file that will be offered to the user at the beginning
//                             of an interactive selection or placed in temporary storage in a non-interactive one. If
//                             non-interactive mode is selected and the parameter is empty, an exception is thrown.
//   AddressInTempStorage - String -  the address where the file will be saved.
//
// Example:
//   Alert = New Message Descriptor ("Select File After File Placemark", This Object, Context);
//   Boot Parameters = Filesystem Client.Parameters of the upload file();
//   Boot parameters.Form ID = Unique Identifier;
//   Filobasidiella.Upload A File(Notification, Upload Parameters);
//
Procedure ImportFile_(
		CompletionHandler, 
		ImportParameters = Undefined, 
		FileName = "",
		AddressInTempStorage = "") Export
	
	If ImportParameters = Undefined Then
		ImportParameters = FileImportParameters();
	ElsIf Not ImportParameters.Interactively
		And IsBlankString(FileName) Then
		Raise NStr("en = 'Import in non-interactive mode failed. The name of the file to import is not specified.';");
	EndIf;
	
	If Not ValueIsFilled(ImportParameters.FormIdentifier) Then
		ImportParameters.FormIdentifier = New UUID;
	EndIf;
	
	FileDetails = New TransferableFileDescription(FileName, AddressInTempStorage);
	ImportParameters.Insert("FilesToUpload", FileDetails);
	
	ImportParameters.Dialog.FullFileName     = FileName;
	ImportParameters.Dialog.Multiselect = False;
	ShowPutFile(CompletionHandler, ImportParameters);
	
EndProcedure

// Displays the file selection dialog and places the selected files in temporary storage.
// Combines the work of the global context methods beginmessage of a File and beginmessage of Files,
// returning an identical result regardless of whether the extension for working with 1C is enabled or not:Company.
// Limitations:
//   Not used for selecting directories - this option is not supported by the web client.
//   Multiple selection is not supported in the web client if the extension for working with 1C is not installed:Company.
//
// Parameters:
//   CompletionHandler - NotifyDescription - 
//                             :
//      * PlacedFiles - Undefined - 
//                        - Array - :
//                           ** Location  - String -  location of data in temporary storage.
//                           ** Name       - String - 
//                                        
//                                        
//                                        
//                           ** FullName - String - 
//                                         
//                                         
//                                         
//                           ** FileName  - String -  name of the file with the extension.
//      * AdditionalParameters - Arbitrary -  the value that was specified when creating the message Description object.
//   ImportParameters    - See FileSystemClient.FileImportParameters.
//   FilesToUpload     - Array -  contains objects of the file Descriptiontransmitability type. It can be filled in completely
//                        . in this case, the downloaded files will be saved to the specified addresses. It can be
//                        partially filled in - only the names of array elements are filled in. In this case, the uploaded files will
//                        be placed in the new temporary storage. The array may be empty. In this case, the set
//                        of files to be placed is determined by the values specified in the upload Parameters parameter. If
//                        non-interactive mode is selected in the download parameters and the downloadable Files parameter is not filled in,
//                        an exception is thrown.
//
// Example:
//   Alert = New Message Descriptiondescription ("Upload An Extension Of The File List", This Object, Context);
//   Boot Parameters = Filesystem Client.Parameters of the upload file();
//   Boot parameters.Form ID = Unique Identifier;
//   Filobasidiella.Upload Files(Notification, Upload Parameters);
//
Procedure ImportFiles(
		CompletionHandler, 
		ImportParameters = Undefined,
		FilesToUpload = Undefined) Export
	
	If ImportParameters = Undefined Then
		ImportParameters = FileImportParameters();
	EndIf;
	
	If Not ImportParameters.Interactively
		And (FilesToUpload = Undefined 
		Or (TypeOf(FilesToUpload) = Type("Array")
		And FilesToUpload.Count() = 0)) Then
		
		Raise NStr("en = 'Import in non-interactive mode failed. The files to import are not specified.';");
		
	EndIf;
	
	If FilesToUpload = Undefined Then
		FilesToUpload = New Array;
	EndIf;
	
	If Not ValueIsFilled(ImportParameters.FormIdentifier) Then
		ImportParameters.FormIdentifier = New UUID;
	EndIf;
	
	ImportParameters.Dialog.Multiselect = True;
	ImportParameters.Insert("FilesToUpload", FilesToUpload);
	ShowPutFile(CompletionHandler, ImportParameters);
	
EndProcedure

#EndRegion

#Region ModifiesStoredData

// Retrieves the file and saves it to the user's local file system.
//
// Parameters:
//   CompletionHandler      - NotifyDescription
//                             - Undefined -  
//                                              :
//      * ObtainedFiles         - Undefined -  the files have not been received.
//                                - Array - 
//      * AdditionalParameters - Arbitrary -  the value that was specified when creating the message Description object.
//   AddressInTempStorage - String -  location of data in temporary storage.
//   FileName                  - String -  the full path where the received file should be saved, or the name of the file
//                                        with the extension.
//   SavingParameters       - See FileSystemClient.FileSavingParameters
//
// Example:
//   Alert = New Description Of The Message ("Save The Certificate After Receiving Files", This Object, Context);
//   Save Parameters = Filesystem Client.File Save Parametersfile ();
//   Filesystem Client.Save The File(Notification, Context.Adressability, Filename, Parametrelerine);
//
Procedure SaveFile(CompletionHandler, AddressInTempStorage, FileName = "",
	SavingParameters = Undefined) Export
	
	If SavingParameters = Undefined Then
		SavingParameters = FileSavingParameters();
	EndIf;
	
	FileData = New TransferableFileDescription(FileName, AddressInTempStorage);
	
	FilesToSave = New Array;
	FilesToSave.Add(FileData);
	
	ShowDownloadFiles(CompletionHandler, FilesToSave, SavingParameters);
	
EndProcedure

// Retrieves files and saves them to the user's local file system.
// To save files in non-interactive mode, the name property of the Savedefiles parameter must contain
// the full path to the saved file, or if the Name property contains only the name of the file with the extension, you must
// fill in the Directory property of the save Parameters dialog item. Otherwise
// , an exception will be thrown.
//
// Parameters:
//   CompletionHandler - NotifyDescription
//                        - Undefined - 
//                             :
//     * ObtainedFiles         - Undefined -  the files have not been received.
//                               - Array - 
//     * AdditionalParameters - Arbitrary -  the value that was specified when creating the object
//                               Description of the announcement.
//   FilesToSave     - Array of TransferableFileDescription
//   SavingParameters  - See FileSystemClient.FileSavingParameters
//
// Example:
//   Alert = New Message Description ("Save Printable Formfile After Receiving Files", This Object);
//   Save Parameters = Filesystem Client.Filesaving Parametersfile ();
//   Filesystem Client.Save Files(Notification, Received Files, Save Parameters);
//
Procedure SaveFiles(CompletionHandler, FilesToSave, SavingParameters = Undefined) Export
	
	If SavingParameters = Undefined Then
		SavingParameters = FilesSavingParameters();
	EndIf;
	
	ShowDownloadFiles(CompletionHandler, FilesToSave, SavingParameters);
	
EndProcedure

#EndRegion

#Region Parameters

// Initializes the parameter structure for loading a file from the file system.
// For use in the filesystem Client.Zagruzchik and Filobasidiella.Upload files
//
// Returns:
//  Structure:
//    * FormIdentifier                  - UUID -  unique ID of the form from
//                                          which the file is placed. If the parameter is not filled in,
//                                          you must call the delete time Storage global context method
//                                          after you finish working with the received binary data. The
//                                          default value is Undefined.
//    * Interactively                        - Boolean -  specifies the use of interactive mode, in which
//                                          the user is shown a file selection dialog. The
//                                          default value is True.
//    * Dialog                              - FileDialog -  see the properties in the syntax assistant.
//                                          It is used if the property Interactively takes the value True and
//                                          it was possible to connect the extension to work with 1C:Enterprise.
//    * SuggestionText                    - String -  text of the offer to install the extension. If the parameter
//                                          takes the value"", the standard text of the sentence is displayed.
//                                          The default value is "".
//    * AcrtionBeforeStartPutFiles - NotifyDescription
//                                          - Undefined - 
//                                          
//                                          
//                                          
//                                          :
//        ** Files         - FileRef
//                                   - Array - 
//                                   
//        ** RefusalToPlaceFile   - Boolean -  indicates that you don't want to move the file any further. If
//                                   this parameter is set to True in the body of the handler procedure, the file placement will be canceled.
//        ** AdditionalParameters - Arbitrary -  the value that was specified when creating the message Description object.
//
// Example:
//  Boot Parameters = Filesystem Client.Parameters of the upload file();
//  Boot parameters.Dialogue.Title = NSTR ("ru = 'Select a document'");
//  Boot parameters.Dialogue.Filter = NSTR ("ru = 'MS Word Files (*. doc;*.docx)|*.doc;*.docx|All files (*.*)|*.*'");
//  Filobasidiella.Upload A File(Notification, Upload Parameters);
//
Function FileImportParameters() Export
	
	ImportParameters = OperationContext(FileDialogMode.Open);
	ImportParameters.Insert("FormIdentifier", Undefined);
	ImportParameters.Insert("AcrtionBeforeStartPutFiles", Undefined);
	Return ImportParameters;
	
EndFunction

// Initializes the parameter structure for saving the file to the file system.
// For use in the filesystem Client.Save the file.
//
// Returns:
//  Structure:
//    * Interactively     - Boolean -  specifies the use of interactive mode, in which
//                       the user is shown a file selection dialog. The
//                       default value is True.
//    * Dialog           - FileDialog -  see the properties in the syntax assistant.
//                       It is used if the property Interactively takes the value True and
//                       it was possible to connect the extension to work with 1C:Enterprise.
//    * SuggestionText - String -  text of the offer to install the extension. If the parameter
//                       takes the value"", the standard text of the sentence is displayed.
//                       The default value is "".
//
// Example:
//  Save Parameters = Filesystem Client.Parametricheskaya();
//  Save parameters.Dialogue.Header = NSTR ("ru =' Save key operations profile to file'");
//  Save parameters.Dialogue.Filter = " key operation profile Files (*. xml)|*. xml";
//  Filobasidiella.SaveFile(Undefined, Saveprofile Keyoperationsserver (),, Save Parameters);
//
Function FileSavingParameters() Export
	
	Return OperationContext(FileDialogMode.Save);
	
EndFunction

// Initializes the parameter structure for saving the file to the file system.
// For use in the filesystem Client.Save files
//
// Returns:
//  Structure:
//    * Interactively     - Boolean -  specifies the use of interactive mode, in which
//                       the user is shown a file selection dialog. The
//                       default value is True.
//    * Dialog           - FileDialog -  see the properties in the syntax assistant.
//                       It is used if the property Interactively takes the value True and
//                       it was possible to connect the extension to work with 1C:Enterprise.
//    * SuggestionText - String -  text of the offer to install the extension. If the parameter
//                       takes the value"", the standard text of the sentence is displayed.
//                       The default value is "".
//
// Example:
//  Save Parameters = Filesystem Client.Parametrisation();
//  Save parameters.Dialogue.Title = NSTR ("ru ='Selecting a folder to save the generated document'");
//  Filobasidiella.Save Files(Notification, Received Files, Save Parameters);
//
Function FilesSavingParameters() Export
	
	Return OperationContext(FileDialogMode.ChooseDirectory);
	
EndFunction

// Initializes the parameter structure for opening the file.
// For use in the filesystem Client.OpenFile
//
// Returns:
//  Structure:
//    *Encoding         - String -  encoding of a text file. If the parameter is omitted, the text format
//                       will be determined automatically. For a list of encodings, see in the syntax assistant 
//                       , write a text document in the description of the method. The default value is "".
//    *ForEditing - Boolean -  True if the file is opened for editing, otherwise False. If
//                       the parameter is set to True, waits for the program to close, and if the parameter
//                       The file location stores the address in temporary storage, updates the file data.
//                       The default value is False.
//
Function FileOpeningParameters() Export
	
	Context = New Structure;
	Context.Insert("Encoding", "");
	Context.Insert("ForEditing", False);
	Return Context;
	
EndFunction

#EndRegion

#Region RunExternalApplications

// Opens the file for viewing or editing.
// If a file is opened from binary data in temporary storage, it first saves
// it to a temporary directory.
//
// Parameters:
//  FileLocation1    - String -  the full path to the file in the file system or the location of the file data
//                       in temporary storage.
//  CompletionHandler - NotifyDescription
//                       - Undefined - 
//                       :
//    * TheModifiedFile             - Boolean - 
//    * AdditionalParameters - Arbitrary -  the value that was specified when creating the object
//                              Description of the announcement.
//  FileName             - String -  the name of the file with the extension or the file extension without the dot. If
//                       the file Location parameter contains an address in temporary storage and the parameter
//                       Filename is not filled in, an exception will be thrown.
//  OpeningParameters    - See FileSystemClient.FileOpeningParameters.
//
Procedure OpenFile(
		FileLocation1,
		CompletionHandler = Undefined,
		FileName = "",
		OpeningParameters = Undefined) Export
		
	If OpeningParameters = Undefined Then
		OpeningParameters = FileOpeningParameters();
	EndIf;
	
	OpeningParameters.Insert("CompletionHandler", CompletionHandler);
	If IsTempStorageURL(FileLocation1) Then
		
		If IsBlankString(FileName) Then
			Raise NStr("en = 'The file name is not specified.';");
		EndIf;
		
		PathToFile = TempFileFullName(FileName);
		ShortenFullFileNameToAllowedNTFSLength(PathToFile);
		
		OpeningParameters.Insert("PathToFile", PathToFile);
		OpeningParameters.Insert("AddressOfBinaryDataToUpdate", FileLocation1);
		OpeningParameters.Insert("DeleteAfterDataUpdate", True);
		
		SavingParameters = FileSavingParameters();
		SavingParameters.Interactively = False;
		
		NotifyDescription = New NotifyDescription(
			"OpenFileAfterSaving", FileSystemInternalClient, OpeningParameters);
		
		SaveFile(NotifyDescription, FileLocation1, PathToFile, SavingParameters);
		
	Else
		FileSystemInternalClient.OpenFileAfterSaving(
			New Structure("FullName", FileLocation1), OpeningParameters);
	EndIf;
	
EndProcedure

// Opens file Explorer with the specified path.
// If a path to a file is passed, it positions the cursor in Explorer on that file.
//
// Parameters:
//  PathToDirectoryOrFile - String - 
//
// Example:
//  
//  
//  
//  
//  
//  
//
Procedure OpenExplorer(PathToDirectoryOrFile) Export
	
	FileInfo3 = New File(PathToDirectoryOrFile);
	
	Context = New Structure;
	Context.Insert("FileInfo3", FileInfo3);
	
	Notification = New NotifyDescription(
		"OpenExplorerAfterCheckFileSystemExtension", FileSystemInternalClient, Context);
		
	SuggestionText = NStr("en = 'To open the folder, install 1C:Enterprise Extension.';");
	AttachFileOperationsExtension(Notification, SuggestionText, False);
	
EndProcedure

// 
//
// 
//
// 
//  See OpenExplorer.
// 
//
// Parameters:
//  URL - String -  the link to open.
//  Notification - NotifyDescription -  notification of the opening result.
//      If an alert is not set, a warning will be displayed in case of an error.
//      The application is omitted - Boolean - True if the external application did not cause errors when opening.
//      Additional parameters - Arbitrary - the value that was specified when creating the object of the announcement description.
//
// Example:
//  Filobasidiella.Open the navigation link ("e1cib/navigationpoint/startpage"); / / home page.
//  Filobasidiella.Open the navigation link ("v8help://1cv8/QueryLanguageFullTextSearchInData");
//  Filobasidiella.Open the navigation link("https://1c.ru");
//  Filobasidiella.Open the navigation link ("mailto:help@1c.ru");
//  Filobasidiella.Open the navigation link ("skype: echo123?call");
//
Procedure OpenURL(URL, Val Notification = Undefined) Export
	
	// 
	
	Context = New Structure;
	Context.Insert("URL", URL);
	Context.Insert("Notification", Notification);
	
	ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Cannot open URL ""%1"".
		           |The URL is invalid.';"),
		URL);
	
	If Not FileSystemInternalClient.IsAllowedRef(URL) Then 
		
		FileSystemInternalClient.OpenURLNotifyOnError(ErrorDescription, Context);
		
	ElsIf FileSystemInternalClient.IsWebURL(URL)
		Or CommonInternalClient.IsURL(URL) Then 
		
		Try
		
#If ThickClientOrdinaryApplication Then
			
			// 
			Notification = New NotifyDescription(
				,, Context,
				"OpenURLOnProcessError", FileSystemInternalClient);
			BeginRunningApplication(Notification, URL);
#Else
			GotoURL(URL);
#EndIf
			
			If Notification <> Undefined Then 
				ApplicationStarted = True;
				ExecuteNotifyProcessing(Notification, ApplicationStarted);
			EndIf;
			
		Except
			FileSystemInternalClient.OpenURLNotifyOnError(ErrorDescription, Context);
		EndTry;
		
	ElsIf FileSystemInternalClient.IsHelpRef(URL) Then 
		
		OpenHelp(URL);
		
	Else 
		
		Notification = New NotifyDescription(
			"OpenURLAfterCheckFileSystemExtension", FileSystemInternalClient, Context);
		
		SuggestionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'To open link %1, install 1C:Enterprise Extension.';"),
			URL);
		AttachFileOperationsExtension(Notification, SuggestionText, False);
		
	EndIf;
	
	// 
	
EndProcedure

// Parameter constructor for the filesystem Client.Run the program.
//
// Returns:
//  Structure:
//    * CurrentDirectory - String -  sets the current folder of the application to launch.
//    * Notification - NotifyDescription -  
//          :
//          
//              -- 
//              -- 
//              -- 
//              -- 
//                             
//              -- 
//                             
//          :
//    * WaitForCompletion - Boolean -  True, wait for the running application to finish before continuing.
//    * GetOutputStream - Boolean -  False-the result sent to the stdout stream,
//         if wait for Completion is not specified, is ignored.
//    * GetErrorStream - Boolean -  False-errors sent to the stderr stream,
//         if wait for Completion is not specified - ignored.
//    * ThreadsEncoding - TextEncoding
//                       - String - 
//         
//    * ExecutionEncoding - String
//                          - Number - 
//         
//         
//         
//         
//    * ExecuteWithFullRights - Boolean - 
//          :
//          
//          
//          
//    * ExecutionEnvironment - String -  an empty string if the execution environment is not Windows. Used when 
//								   defining invalid characters in the startup string.
//
Function ApplicationStartupParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("CurrentDirectory", "");
	Parameters.Insert("Notification", Undefined);
	Parameters.Insert("WaitForCompletion", True);
	Parameters.Insert("GetOutputStream", False);
	Parameters.Insert("GetErrorStream", False);
	Parameters.Insert("ThreadsEncoding", Undefined);
	Parameters.Insert("ExecutionEncoding", Undefined);
	Parameters.Insert("ExecuteWithFullRights", False);
	
	ExecutionEnvironment = ?(CommonClient.IsWindowsClient(), "Windows", ""); 
	Parameters.Insert("ExecutionEnvironment", ExecutionEnvironment);
	
	Return Parameters;
	
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
//  StartupCommand - String -  command line for running the program.
//                 - Array - 
//      
//      
//  ApplicationStartupParameters - See FileSystemClient.ApplicationStartupParameters.
//
// Пример: 
//	// Простой запуск
//  ФайловаяСистемаКлиент.ЗапуститьПрограмму("calc");
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
Procedure StartApplication(Val StartupCommand, Val ApplicationStartupParameters = Undefined) Export
	
	If ApplicationStartupParameters = Undefined Then 
		ApplicationStartupParameters = ApplicationStartupParameters();
	EndIf;
	
	CommandString = CommonInternalClientServer.SafeCommandString(StartupCommand);
	
	OutputThreadFileName = "";
	ErrorsThreadFileName = "";
	
#If Not WebClient Then
	If ApplicationStartupParameters.WaitForCompletion Then
		
		// 
		
		If ApplicationStartupParameters.GetOutputStream Then
			OutputThreadFileName = GetTempFileName("stdout.tmp");
			CommandString = CommandString + " > """ + OutputThreadFileName + """";
		EndIf;
		
		If ApplicationStartupParameters.GetErrorStream Then 
			ErrorsThreadFileName = GetTempFileName("stderr.tmp");
			CommandString = CommandString + " 2> """ + ErrorsThreadFileName + """";
		EndIf;
		
		// 
		
	EndIf;
#EndIf
	
	Context = New Structure;
	Context.Insert("CommandString", CommandString);
	Context.Insert("CurrentDirectory", ApplicationStartupParameters.CurrentDirectory);
	Context.Insert("Notification", ApplicationStartupParameters.Notification);
	Context.Insert("WaitForCompletion", ApplicationStartupParameters.WaitForCompletion);
	Context.Insert("ThreadsEncoding", ApplicationStartupParameters.ThreadsEncoding);
	Context.Insert("ExecutionEncoding", ApplicationStartupParameters.ExecutionEncoding);
	Context.Insert("GetOutputStream", ApplicationStartupParameters.GetOutputStream);
	Context.Insert("GetErrorStream", ApplicationStartupParameters.GetErrorStream);
	Context.Insert("OutputThreadFileName", OutputThreadFileName);
	Context.Insert("ErrorsThreadFileName", ErrorsThreadFileName);
	Context.Insert("ExecuteWithFullRights", ApplicationStartupParameters.ExecuteWithFullRights);
	
	Notification = New NotifyDescription("StartApplicationAfterCheckFileSystemExtension", 
		FileSystemInternalClient, Context);
	AttachFileOperationsExtension(Notification, 
		NStr("en = 'To create a temporary folder, install 1C:Enterprise Extension.';"), False);
	
EndProcedure

// Prints the file by an external application.
//
// Parameters:
//  FileToOpenName - String
//
Procedure PrintFromApplicationByFileName(FileToOpenName) Export
	
	If Not ValueIsFilled(FileToOpenName) Then
		Return;
	EndIf;
	
#If Not MobileClient Then
	If CommonClient.IsWindowsClient() Then
		Shell = New COMObject("Shell.Application");
		Shell.ShellExecute(FileToOpenName, "", "", "print", 1);
	ElsIf CommonClient.IsLinuxClient() Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("FileToOpenName", FileToOpenName);
		NotifyDescription = New NotifyDescription("PrintFromTheApplicationByTheLinuxFileName", 
			ThisObject, AdditionalParameters);
		CheckIfTheLinuxProgramIsInstalled("Unoconv", NotifyDescription);
	Else
		ShowMessageBox(, NStr("en = 'You can print this type of files only from an application for Windows or Linux.';"));
		Return;
	EndIf;
#EndIf

EndProcedure

#EndRegion

#Region Other

// Displays the folder selection dialog.
//
// Parameters:
//   CompletionHandler - NotifyDescription - 
//                        :
//      -- 
//                        
//      -- 
//   Title - String -  title of the folder selection dialog.
//   Directory   - String -  the initial value of the folder that is suggested by default.
//
Procedure SelectDirectory(CompletionHandler, Title = "", Directory = "") Export
	
	Context = New Structure;
	Context.Insert("CompletionHandler", CompletionHandler);
	Context.Insert("Title", Title);
	Context.Insert("Directory", Directory);
	
	NotifyDescription = New NotifyDescription(
		"SelectDirectoryOnAttachFileSystemExtension", FileSystemInternalClient, Context);
	AttachFileOperationsExtension(NotifyDescription);
	
EndProcedure

// Displays the file selection dialog.
// When working in the web client, the user will be shown a dialog for installing an extension
// for working with files, if necessary.
//
// Parameters:
//   CompletionHandler - NotifyDescription - 
//           :
//          * Result - Array of String -  selected file names.
//           			- String - 
//           			- Undefined - 
//      * AdditionalParameters - Structure -  additional notification parameters.
//   Dialog - FileDialog -  see the properties in the syntax assistant.
//
Procedure ShowSelectionDialog(CompletionHandler, Dialog) Export
	
	Context = New Structure;
	Context.Insert("CompletionHandler", CompletionHandler);
	Context.Insert("Dialog", Dialog);
	
	NotifyDescription = New NotifyDescription(
		"ShowSelectionDialogOnAttachFileSystemExtension", FileSystemInternalClient, Context);
	AttachFileOperationsExtension(NotifyDescription);
	
EndProcedure

// Getting the name of the temporary folder.
//
// Parameters:
//  Notification - NotifyDescription -  notification of the receipt result with the following parameters.
//    -- 
//    -- 
//  Extension - String -  a suffix in the folder name that will help you identify the folder during analysis.
//
Procedure CreateTemporaryDirectory(Val Notification, Extension = "") Export 
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("Extension", Extension);
	
	Notification = New NotifyDescription("CreateTemporaryDirectoryAfterCheckFileSystemExtension",
		FileSystemInternalClient, Context);
	AttachFileOperationsExtension(Notification, 
		NStr("en = 'To create a temporary folder, install 1C:Enterprise Extension.';"), False);
	
EndProcedure

// Prompts the user to install an extension to work with 1C:An enterprise in the web client.
// It is intended for use at the beginning of code sections where you are working with files.
//
// Parameters:
//  OnCloseNotifyDescription - NotifyDescription - 
//          :
//    -- 
//    -- 
//  SuggestionText - String -  message text. If omitted, the default text is displayed.
//  CanContinueWithoutInstalling - Boolean -  if True, the continue button will be shown
//          . If False, the Cancel button will be shown.
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
//    
//
Procedure AttachFileOperationsExtension(
		OnCloseNotifyDescription, 
		SuggestionText = "",
		CanContinueWithoutInstalling = True) Export
	
	NotifyDescriptionCompletion = New NotifyDescription(
		"StartFileSystemExtensionAttachingWhenAnsweringToInstallationQuestion", FileSystemInternalClient,
		OnCloseNotifyDescription);
	
#If Not WebClient Then
	// 
	ExecuteNotifyProcessing(NotifyDescriptionCompletion, "AttachmentNotRequired");
	Return;
#EndIf
	
	Context = New Structure;
	Context.Insert("NotifyDescriptionCompletion", NotifyDescriptionCompletion);
	Context.Insert("SuggestionText",             SuggestionText);
	Context.Insert("CanContinueWithoutInstalling", CanContinueWithoutInstalling);
	
	Notification = New NotifyDescription(
		"StartFileSystemExtensionAttachingOnSetExtension", FileSystemInternalClient, Context);
	BeginAttachingFileSystemExtension(Notification);
	
EndProcedure

// Generates a unique file name in the specified folder, if necessary, adding an ordinal number to the file name,
// for example: "file (2). txt", "file (3). txt", etc.
//
// Parameters:
//   FileName - String -  the full name of the file with the folder, for example, " C:\Документы\файл.txt".
//
// Returns:
//   String - 
//
Function UniqueFileName(Val FileName) Export
	
	Return FileSystemInternalClientServer.UniqueFileName(FileName);

EndFunction

#EndRegion

#EndRegion

#Region Private

// Initializes the parameter structure for interacting with the file system.
//
// Parameters:
//  DialogMode - FileDialogMode -  mode of operation of the constructed file selection dialog. 
//
// Returns:
//  Structure:
//   * Dialog - FileDialog
//   * Interactively - Boolean
//   * SuggestionText - String
//
Function OperationContext(DialogMode)
	
	Context = New Structure();
	Context.Insert("Dialog", New FileDialog(DialogMode));
	Context.Insert("Interactively", True);
	Context.Insert("SuggestionText", "");
	
	Return Context;
	
EndFunction

// 
// See FileSystemClient.ImportFile_
//
Procedure ShowPutFile(CompletionHandler, PutParameters)
	
	PutParameters.Insert("CompletionHandler", CompletionHandler);
	NotifyDescription = New NotifyDescription(
		"ShowPutFileOnAttachFileSystemExtension", FileSystemInternalClient, PutParameters);
	AttachFileOperationsExtension(NotifyDescription, PutParameters.SuggestionText);
	
EndProcedure

// 
// See FileSystemClient.SaveFile
//
Procedure ShowDownloadFiles(CompletionHandler, FilesToSave, ReceivingParameters)
	
	ReceivingParameters.Insert("FilesToObtain",      FilesToSave);
	ReceivingParameters.Insert("CompletionHandler", CompletionHandler);
	
	NotifyDescription = New NotifyDescription(
		"ShowDownloadFilesOnAttachFileSystemExtension", FileSystemInternalClient, ReceivingParameters);
	AttachFileOperationsExtension(NotifyDescription, ReceivingParameters.SuggestionText);
	
EndProcedure

// Gets the path to save the file in the temporary files folder.
//
// Parameters:
//  FileName - String -  name of the file with the extension or extension without a dot.
//
// Returns:
//  String - 
//
Function TempFileFullName(Val FileName)

#If WebClient Then
	
	Return ?(StrFind(FileName, ".") = 0, 
		Format(CommonClient.SessionDate(), "DF=yyyyMMddHHmmss") + "." + FileName, FileName);
	
#Else
	
	ExtensionPosition = StrFind(FileName, ".");
	If ExtensionPosition = 0 Then
		Return GetTempFileName(FileName);
	Else
		Return TempFilesDir() + FileName;
	EndIf;
	
#EndIf

EndFunction

// Reduces the length of the file name based on the rule that the full path of the file must not exceed 260 characters.
//
// Parameters:
//  FullFileName - String -  the full name of the file with the path before it and the extension.
//
Procedure ShortenFullFileNameToAllowedNTFSLength(FullFileName)
	
	AllowedNTFSLength = 260;
	FullFileNameLength = StrLen(FullFileName);
	
	If FullFileNameLength <= AllowedNTFSLength Then
		Return;
	EndIf;
	
	File = New File(FullFileName);
	
	ExtensionLength = StrLen(File.Extension);
	PathLength       = StrLen(File.Path);
	
	// 
	If PathLength > AllowedNTFSLength - ExtensionLength - 1 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'File path is too long:
		|%1';"), FullFileName);
	EndIf;
	
	BaseName = Mid(File.BaseName, 1, AllowedNTFSLength - PathLength - ExtensionLength - 1);
	
	FullFileName = File.Path + BaseName + File.Extension;
	
EndProcedure

Procedure CheckIfTheLinuxProgramIsInstalled(ApplicationName, Notification)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Notification", Notification);
	TheLinuxProgramIsInstalledCompletion = New NotifyDescription("CheckTheLinuxProgramIsInstalledCompletion", 
		ThisObject, AdditionalParameters);
	
	ApplicationStartupParameters = ApplicationStartupParameters();
	ApplicationStartupParameters.Insert("WaitForCompletion", True);
	ApplicationStartupParameters.Insert("GetOutputStream", True);
	ApplicationStartupParameters.Insert("GetErrorStream", True);
	ApplicationStartupParameters.Insert("Notification", TheLinuxProgramIsInstalledCompletion);
	
	StartApplication(StringFunctionsClientServer.SubstituteParametersToString(
		"dpkg -s '%1'", String(ApplicationName)), ApplicationStartupParameters);
	
EndProcedure

Procedure CheckTheLinuxProgramIsInstalledCompletion(Result, Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	TheResultOfTheProcedure = StrFind(Result.OutputStream, "Status: install ok installed") <> False;
	ExecuteNotifyProcessing(Parameters.Notification, TheResultOfTheProcedure);
	
EndProcedure

Procedure PrintFromTheApplicationByTheLinuxFileName(Result, Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result = False Then
		ShowMessageBox(, StringFunctionsClient.FormattedString(
			NStr("en = 'To print out the document, install <a href=""%1"">Unoconv</a>.
			|
			|To do so, open the terminal and run:
			|%2
			|
			|Alternatively, send a request to the administrator.';"),
			"https://docs.moodle.org/404/en/Universal_Office_Converter_%28unoconv%29", 
			"sudo apt update
			|sudo apt install unoconv"));
		Return;
	EndIf;
	
	NotifyDescription = New NotifyDescription("PrintFromTheApplicationByTheLinuxFileNameRunningUnoconv", 
		ThisObject, Parameters);
	GetTheFullNameOfTheTemporaryFile(NotifyDescription);
		
EndProcedure

Procedure PrintFromTheApplicationByTheLinuxFileNameRunningUnoconv(TempFileName, Parameters) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TheFileOfTheConvertedData", TempFileName);
	
	NotifyDescription = New NotifyDescription("PrintFromTheApplicationByTheLinuxFileNameRunningLpr", 
		ThisObject, AdditionalParameters);
	
	ApplicationStartupParameters = ApplicationStartupParameters();
	ApplicationStartupParameters.Insert("WaitForCompletion", True);
	ApplicationStartupParameters.Insert("GetErrorStream", True);
	ApplicationStartupParameters.Insert("Notification", NotifyDescription);
	
	CommandString = StringFunctionsClientServer.SubstituteParametersToString("unoconv --stdout '%1' >""%2""",
		Parameters.FileToOpenName, TempFileName);
	StartApplication(CommandString, ApplicationStartupParameters);
	
EndProcedure

Procedure PrintFromTheApplicationByTheLinuxFileNameRunningLpr(Result, Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Not Result.ApplicationStarted Then
		ShowMessageBox(, Result.ErrorDescription);
		Return;
	EndIf;
		
	Parameters.Insert("ErrorDescription", Result.ErrorDescription);
		
	NotifyDescription = New NotifyDescription("PrintFromTheApplicationByTheLinuxFileNameCompletion", ThisObject, Parameters);
	ApplicationStartupParameters = ApplicationStartupParameters();
	ApplicationStartupParameters.Insert("WaitForCompletion", True);
	ApplicationStartupParameters.Insert("GetErrorStream", True);
	ApplicationStartupParameters.Insert("Notification", NotifyDescription);
	
	StartApplication(
		StringFunctionsClientServer.SubstituteParametersToString("lpr %1", Parameters.TheFileOfTheConvertedData), 
		ApplicationStartupParameters);
	
EndProcedure

Procedure PrintFromTheApplicationByTheLinuxFileNameCompletion(Result, Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	// 
	File = New File(Parameters.TheFileOfTheConvertedData);
	If File.Exists() Then
		DeleteFiles(Parameters.TheFileOfTheConvertedData);
	EndIf;
	// 
	
	If Not Result.ApplicationStarted Or ValueIsFilled(Result.ErrorDescription) 
		Or ValueIsFilled(Result.ErrorStream) Then

		ErrorDescription = TrimAll(?(ValueIsFilled(Result.ErrorDescription), 
			Result.ErrorDescription + Chars.LF, "") + Result.ErrorStream);
		
		Recommendation = ""; 
		If StrFind(Lower(ErrorDescription), "no default destination") > 0 Then
			Recommendation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Set the default printer:
					|1. In the terminal window, run ""%1"" and select a printer from the list.
					|2. In the terminal window, run: %2 ""printer name"".
					|Alternatively, send a request to the administrator.';"),
					"lpstat -p -d",
					"lpoptions -d");
		EndIf;
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t print the file. Reason:
				|%1';"),
			ErrorDescription, Result.ReturnCode);
		If Result.ReturnCode <> 0 Then
			ErrorDescription = ErrorDescription 
				+ StringFunctionsClientServer.SubstituteParametersToString(" (%1)", Result.ReturnCode);
		EndIf;
		If Not IsBlankString(Recommendation) Then
			ErrorDescription = ErrorDescription + Chars.LF + Chars.LF + Recommendation;
		EndIf;
		
		EventLogClient.AddMessageForEventLog(NStr("en = 'Standard subsystems';", 
				CommonClient.DefaultLanguageCode()),
			"Warning",,, True);
		ShowMessageBox(, ErrorDescription);
	EndIf;
	
EndProcedure

#Region GetTheFullNameOfTheTemporaryFile

// Getting the name of the temporary file.
//
// Parameters:
//  Notification - NotifyDescription -  notification of the receipt result with the following parameters.
//    -- 
//    -- 
//  Extension - String -  the extension of the temporary file.
//
Procedure GetTheFullNameOfTheTemporaryFile(Val Notification, Extension = "")
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("Extension", Extension);
	
	Notification = New NotifyDescription("GetTheNameOfATemporaryFileAfterCheckingTheFileExtension",
		ThisObject, Context);
	AttachFileOperationsExtension(Notification, 
		NStr("en = 'To get a temporary file name, install 1C:Enterprise Extension.';"), False);
	
EndProcedure

// The continuation of the procedure will receive the full timefile.
// 
// Parameters:
//  ExtensionAttached - Boolean
//  Context - Structure:
//   * Notification - NotifyDescription
//   * Extension - String
//
Procedure GetTheNameOfATemporaryFileAfterCheckingTheFileExtension(ExtensionAttached, Context) Export
	
	If ExtensionAttached Then
#If WebClient Then
		Notification = New NotifyDescription(
			"GetTheNameOfTheTemporaryFileAfterGettingTheTemporaryDirectory", ThisObject, Context,
			"GetTheNameOfATemporaryFileWhenProcessingAnError", ThisObject);
		BeginGettingTempFilesDir(Notification);
#Else
		GetTheNameOfTheTemporaryFileAfterGettingTheTemporaryDirectory("", Context);
#EndIf
	Else
		GetTheNameOfTheTemporaryFileNotifyAboutTheError(NStr("en = 'Cannot install 1C:Enterprise Extension.';"), 
			Context);
	EndIf;
	
EndProcedure

// The continuation of the procedure will receive the full timefile.
// 
// Parameters:
//  TempFilesDirName - String
//  Context - Structure:
//   * Notification - NotifyDescription
//   * Extension - String
//
Procedure GetTheNameOfTheTemporaryFileAfterGettingTheTemporaryDirectory(TempFilesDirName, Context) Export
	
	Notification = Context.Notification;
	Extension = Context.Extension;
	
#If WebClient Then
	TempFileName = TempFilesDirName + String(New UUID);
#Else
	TempFileName = GetTempFileName(Extension); // 
#EndIf
	
	If Not IsBlankString(Extension) Then 
		TempFileName = TempFileName + "." + Extension;
	EndIf;
	
	ExecuteNotifyProcessing(Notification, TempFileName);
	
EndProcedure

// The continuation of the procedure will receive the full timefile.
Procedure GetTheNameOfATemporaryFileWhenProcessingAnError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	GetTheNameOfTheTemporaryFileNotifyAboutTheError(ErrorDescription, Context);
	
EndProcedure

// The continuation of the procedure will receive the full timefile.
Procedure GetTheNameOfTheTemporaryFileNotifyAboutTheError(ErrorDescription, Context)
	
	ShowMessageBox(, ErrorDescription);
	TempFileName = "";
	ExecuteNotifyProcessing(Context.Notification, TempFileName);
	
EndProcedure

#EndRegion

#EndRegion