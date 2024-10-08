﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

#Region FilesImportFromFileSystem

// Continuation of the filesystem Client procedure.ShowMessage of the file.
Procedure ShowPutFileOnAttachFileSystemExtension(ExtensionAttached, Context) Export
	
	Interactively         = Context.Interactively;
	
	If Not ExtensionAttached
		And Not Interactively Then
		Raise NStr("en = 'Cannot upload the file because 1C:Enterprise Extension is not installed.';");
	EndIf;
		
	Try
		StartProcessingPuttingFiles(Context);
	Except
		Dialog               = Context.Dialog; // FileDialog - 
		Interactively         = Context.Interactively;
		CompletionHandler = Context.CompletionHandler;
	
		ProcessingResultsParameters = New Structure;
		ProcessingResultsParameters.Insert("MultipleChoice",   Dialog.Multiselect);
		ProcessingResultsParameters.Insert("CompletionHandler", CompletionHandler);
		
		NotifyDescription = New NotifyDescription(
			"AfterWarnedAboutFileUnavailability", ThisObject, ProcessingResultsParameters);
		ErrorInfo = ErrorInfo();
		ErrorDescription = ErrorInfo.Cause.Description;
		If StrFind(ErrorDescription, "32(0x00000020)") Then 
			ShowMessageBox(NotifyDescription, NStr("en = 'Complete the operation with the file in another application.';"), , NStr("en = 'The file is opened in another application';"));
		Else
			Raise ErrorDescription;
		EndIf;
		
	EndTry;

EndProcedure

// 
// 
// Parameters:
//  ProcessingResultsParameters - Structure:
//   * MultipleChoice - Boolean
//   * CompletionHandler - NotifyDescription
//
Procedure AfterWarnedAboutFileUnavailability(ProcessingResultsParameters) Export

		If ProcessingResultsParameters.MultipleChoice Then
			ProcessPutFilesResult(Undefined, ProcessingResultsParameters);
		Else
			ProcessPutFileResult(False, Undefined, Undefined,	ProcessingResultsParameters);
		EndIf;
	
EndProcedure
	
Procedure StartProcessingPuttingFiles(Context)
	
	Dialog               = Context.Dialog; // FileDialog - 
	Interactively         = Context.Interactively;
	FilesToUpload     = Context.FilesToUpload;
	FormIdentifier   = Context.FormIdentifier;
	CompletionHandler = Context.CompletionHandler;
	
	ProcessingResultsParameters = New Structure;
	ProcessingResultsParameters.Insert("MultipleChoice",   Dialog.Multiselect);
	ProcessingResultsParameters.Insert("CompletionHandler", CompletionHandler);
			
	If Dialog.Multiselect Then
		
		Files = ?(Interactively, Dialog, FilesToUpload);
		NotifyDescription = New NotifyDescription(
			"ProcessPutFilesResult", ThisObject, ProcessingResultsParameters);
		
		If ValueIsFilled(FormIdentifier) Then
			BeginPuttingFiles(NotifyDescription, Files, Interactively,
				FormIdentifier, Context.AcrtionBeforeStartPutFiles);
		Else
			BeginPuttingFiles(NotifyDescription, Files, Interactively, ,
				Context.AcrtionBeforeStartPutFiles);
		EndIf;
		
	Else
		
		File = ?(Interactively, Dialog, FilesToUpload.Name);
		NotifyDescription = New NotifyDescription(
			"ProcessPutFileResult", ThisObject, ProcessingResultsParameters);
		
		If ValueIsFilled(FormIdentifier) Then
			BeginPutFile(NotifyDescription, FilesToUpload.Location, File,
				Interactively, FormIdentifier, Context.AcrtionBeforeStartPutFiles);
		Else
			BeginPutFile(NotifyDescription, FilesToUpload.Location, File,
				Interactively, , Context.AcrtionBeforeStartPutFiles);
		EndIf;
		
	EndIf;
EndProcedure

// End of file placement.
Procedure ProcessPutFilesResult(PlacedFiles, ProcessingResultsParameters) Export
	
	ProcessPutFileResult(PlacedFiles <> Undefined, PlacedFiles, Undefined,
		ProcessingResultsParameters);
	
EndProcedure

// The end of the file has been placed.
Procedure ProcessPutFileResult(SelectionDone, AddressOrSelectionResult, SelectedFileName,
		ProcessingResultsParameters) Export
	
	If SelectionDone = True Then
		
		If TypeOf(AddressOrSelectionResult) = Type("Array") Then
			
			PutFilesToServe = New Array;
			For Each File In AddressOrSelectionResult Do
				
				FileProperties = New Structure("Name, FullName, Location");
				FillPropertyValues(FileProperties, File);
				
				FileProperties.Insert("FileName", File.Name);
				If Not IsBlankString(File.FullName) Then
					FileProperties.Name = File.FullName;
				EndIf;
				
				PutFilesToServe.Add(FileProperties);
				
			EndDo;
			
		Else
			
			PutFilesToServe = New Structure;
			PutFilesToServe.Insert("Location", AddressOrSelectionResult);
			PutFilesToServe.Insert("Name",      SelectedFileName);
			
		EndIf;
		
	Else
		PutFilesToServe = Undefined;
	EndIf;
	
	ExecuteNotifyProcessing(ProcessingResultsParameters.CompletionHandler, PutFilesToServe);
	
EndProcedure

#EndRegion

#Region ModifiesStoredDataToFileSystem

// Continuation of the filesystem Client procedure.Showfiles received.
Procedure ShowDownloadFilesOnAttachFileSystemExtension(ExtensionAttached, Context) Export
	
	If ExtensionAttached Then
		
		If Context.Interactively Then
			ShowDownloadFilesToDirectory(Context);
		ElsIf Not IsBlankString(Context.Dialog.Directory)Then
			Context.Dialog = Context.Dialog.Directory;
			ShowDownloadFilesToDirectory(Context);
		Else
			
			DirectoryReceiptNotification = New NotifyDescription(
				"ShowDownloadFilesAfterGetTempFilesDirectory", ThisObject, Context);
			BeginGettingTempFilesDir(DirectoryReceiptNotification);
				
		EndIf;
		
	Else
		
		For Each FileToReceive In Context.FilesToObtain Do
			GetFile(FileToReceive.Location, FileToReceive.Name, True);
		EndDo;
		
		If Context.CompletionHandler <> Undefined Then
			ExecuteNotifyProcessing(Context.CompletionHandler, Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

// Continuation of the filesystem Client procedure.Showfiles received.
Procedure ShowDownloadFilesAfterGetTempFilesDirectory(TempFilesDirName, Context) Export
	
	Context.Dialog = TempFilesDirName;
	ShowDownloadFilesToDirectory(Context);
	
EndProcedure

// Continuation of the filesystem Client procedure.Showfiles received.
Procedure ShowDownloadFilesToDirectory(Context)
	
	CallbackOnCompletion = New NotifyDescription("NotifyGetFilesCompletion", ThisObject, Context);
	BeginGettingFiles(CallbackOnCompletion, Context.FilesToObtain,
		Context.Dialog, Context.Interactively);
	
EndProcedure

// Continuation of the filesystem Client procedure.Showfiles received.
Procedure NotifyGetFilesCompletion(ObtainedFiles, AdditionalParameters) Export
	
	If AdditionalParameters.CompletionHandler <> Undefined Then
		ExecuteNotifyProcessing(AdditionalParameters.CompletionHandler, ObtainedFiles);
	EndIf;
	
EndProcedure

#EndRegion

#Region OpeningFiles

// Continuation of the filesystem Client procedure.Open the file.
Procedure OpenFileAfterSaving(SavedFiles, OpeningParameters) Export
	
	If SavedFiles = Undefined Then
		ExecuteNotifyProcessing(OpeningParameters.CompletionHandler, False);
	Else
		
		FileDetails = 
			?(TypeOf(SavedFiles) = Type("Array"), 
				SavedFiles[0], 
				SavedFiles);
		
		OpeningParameters.Insert("PathToFile", FileDetails.FullName);
		CompletionHandler = New NotifyDescription(
			"OpenFileAfterEditingCompletion", ThisObject, OpeningParameters);
		
		OpenFileInViewer(FileDetails.FullName, CompletionHandler, OpeningParameters.ForEditing);
		
	EndIf;
	
EndProcedure

// 
// 
// 
//
// Parameters:
//  PathToFile        - String - 
//  Notification        - NotifyDescription - 
//                    :
//   * ApplicationStarted      - Boolean -  True if the external application did not cause errors when opening.
//   * AdditionalParameters - Arbitrary -  the value that was specified when creating the message Description object.
//  ForEditing - Boolean -  True if the file is opened for editing, otherwise False.
//
Procedure OpenFileInViewer(PathToFile, Val Notification = Undefined,
		Val ForEditing = False)
	
	FileInfo3 = New File(PathToFile);
	
	Context = New Structure;
	Context.Insert("FileInfo3",          FileInfo3);
	Context.Insert("Notification",        Notification);
	Context.Insert("ForEditing", ForEditing);
	
	Notification = New NotifyDescription(
		"OpenFileInViewerAfterCheckFileSystemExtension", ThisObject, Context);
	
	SuggestionText = NStr("en = 'To open the file, install 1C:Enterprise Extension.';");
	FileSystemClient.AttachFileOperationsExtension(Notification, SuggestionText, False);
	
EndProcedure

// Continuation of the filesystem Client procedure.Open the file.
Procedure OpenFileInViewerAfterCheckFileSystemExtension(ExtensionAttached, Context) Export
	
	FileInfo3 = Context.FileInfo3;
	If ExtensionAttached Then
		
		Notification = New NotifyDescription(
			"OpenFileInViewerAfterCheckIfExists", ThisObject, Context,
			"OpenFileInViewerOnProcessError", ThisObject);
		FileInfo3.BeginCheckingExistence(Notification);
		
	Else
		
		ErrorDescription = NStr("en = 'Cannot open the file because 1C:Enterprise Extension is not installed.';");
		OpenFileInViewerNotifyOnError(ErrorDescription, Context);
		
	EndIf;
	
EndProcedure

// Continuation of the filesystem Client procedure.Open the file.
Procedure OpenFileInViewerAfterCheckIfExists(Exists, Context) Export
	
	FileInfo3 = Context.FileInfo3;
	If Exists Then
		 
		Notification = New NotifyDescription(
			"OpenFileInViewerAfterCheckIsFIle", ThisObject, Context,
			"OpenFileInViewerOnProcessError", ThisObject);
		FileInfo3.BeginCheckingIsFile(Notification);
		
	Else 
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The file to open does not exist:
			           |%1';"),
			FileInfo3.FullName);
		OpenFileInViewerNotifyOnError(ErrorDescription, Context);
		
	EndIf;
	
EndProcedure

// Continuation of the filesystem Client procedure.Open the file.
Procedure OpenFileInViewerAfterCheckIsFIle(IsFile, Context) Export
	
	// 
	
	FileInfo3 = Context.FileInfo3;
	If IsFile Then
		
		If IsBlankString(FileInfo3.Extension) Then 
			
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The file name is missing extension:
				           |%1.';"),
				FileInfo3.FullName);
			
			OpenFileInViewerNotifyOnError(ErrorDescription, Context);
			Return;
			
		EndIf;
		
		If IsExecutableFileExtension(FileInfo3.Extension) Then 
			
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Opening executable files is disabled:
				           |%1.';"),
				FileInfo3.FullName);
			
			OpenFileInViewerNotifyOnError(ErrorDescription, Context);
			Return;
			
		EndIf;
		
		Notification          = Context.Notification;
		WaitForCompletion = Context.ForEditing;
		
		Notification = New NotifyDescription(
			"OpenFileInViewerAfterStartApplication", ThisObject, Context,
			"OpenFileInViewerOnProcessError", ThisObject);
		BeginRunningApplication(Notification, FileInfo3.FullName,, WaitForCompletion);
		
	Else 
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The file to open does not exist:
			           |%1';"),
			FileInfo3.FullName);
			
		OpenFileInViewerNotifyOnError(ErrorDescription, Context);
		
	EndIf;
	
	// 
	
EndProcedure

// Continuation of the filesystem Client procedure.Open the file.
Procedure OpenFileInViewerAfterStartApplication(ReturnCode, Context) Export 
	
	Notification = Context.Notification;
	
	If Notification <> Undefined Then 
		ApplicationStarted = (ReturnCode = 0);
		ExecuteNotifyProcessing(Notification, ApplicationStarted);
	EndIf;
	
EndProcedure

// Continuation of the filesystem Client procedure.Open the file.
Procedure OpenFileInViewerOnProcessError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	OpenFileInViewerNotifyOnError("", Context);
	
EndProcedure

// Continuation of the filesystem Client procedure.Open the file.
Procedure OpenFileAfterEditingCompletion(ApplicationStarted, OpeningParameters) Export
	
	If ApplicationStarted
		And OpeningParameters.Property("AddressOfBinaryDataToUpdate") Then
		
		Notification = New NotifyDescription(
			"OpenFileAfterDataUpdateInStorage", ThisObject, OpeningParameters);
			
		BeginPutFile(Notification, OpeningParameters.AddressOfBinaryDataToUpdate,
			OpeningParameters.PathToFile, False);
		
	Else
		ExecuteNotifyProcessing(OpeningParameters.CompletionHandler, ApplicationStarted);
	EndIf;
	
EndProcedure

// Continuation of the filesystem Client procedure.Open the file.
Procedure OpenFileAfterDataUpdateInStorage(IsDataUpdated, DataAddress, FileName,
		OpeningParameters) Export
	
	If OpeningParameters.Property("DeleteAfterDataUpdate") Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("IsDataUpdated", IsDataUpdated);
		AdditionalParameters.Insert("OpeningParameters", OpeningParameters);
		
		NotifyDescription = New NotifyDescription(
			"OpenFileAfterTempFileDeletion", ThisObject, AdditionalParameters);
			
		BeginDeletingFiles(NotifyDescription, FileName);
		
	Else
		ExecuteNotifyProcessing(OpeningParameters.CompletionHandler, IsDataUpdated);
	EndIf;
	
EndProcedure

// Continuation of the filesystem Client procedure.Open the file.
Procedure OpenFileAfterTempFileDeletion(AdditionalParameters) Export
	
	ExecuteNotifyProcessing(AdditionalParameters.OpeningParameters.CompletionHandler,
		AdditionalParameters.IsDataUpdated);
	
EndProcedure

// Continuation of the filesystem Client procedure.Open the file.
Procedure OpenFileInViewerNotifyOnError(ErrorDescription, Context)
	
	If Not IsBlankString(ErrorDescription) Then 
		ShowMessageBox(, ErrorDescription);
	EndIf;
	
	ApplicationStarted = False;
	ExecuteNotifyProcessing(Context.Notification, ApplicationStarted);
	
EndProcedure

// Parameters:
//  Extension - String -  property is an extension of the object File.
//
Function IsExecutableFileExtension(Val Extension)
	
	Extension = Upper(Extension);
	
	// Windows
	Return Extension = ".BAT" // Batch File
		Or Extension = ".BIN" // Binary Executable
		Or Extension = ".CMD" // Command Script
		Or Extension = ".COM" // 
		Or Extension = ".CPL" // Control Panel Extension
		Or Extension = ".EXE" // 
		Or Extension = ".GADGET" // Binary Executable
		Or Extension = ".HTA" // HTML Application
		Or Extension = ".INF1" // Setup Information File
		Or Extension = ".INS" // Internet Communication Settings
		Or Extension = ".INX" // InstallShield Compiled Script
		Or Extension = ".ISU" // InstallShield Uninstaller Script
		Or Extension = ".JOB" // Windows Task Scheduler Job File
		Or Extension = ".LNK" // File Shortcut
		Or Extension = ".MSC" // Microsoft Common Console Document
		Or Extension = ".MSI" // Windows Installer Package
		Or Extension = ".MSP" // Windows Installer Patch
		Or Extension = ".MST" // Windows Installer Setup Transform File
		Or Extension = ".OTM" // 
		Or Extension = ".PAF" // Portable Application Installer File
		Or Extension = ".PIF" // Program Information File
		Or Extension = ".PS1" // Windows PowerShell Cmdlet
		Or Extension = ".REG" // Registry Data File
		Or Extension = ".RGS" // Registry Script
		Or Extension = ".SCT" // Windows Scriptlet
		Or Extension = ".SHB" // Windows Document Shortcut
		Or Extension = ".SHS" // Shell Scrap Object
		Or Extension = ".U3P" // U3 Smart Application
		Or Extension = ".VB"  // VBScript File
		Or Extension = ".VBE" // VBScript Encoded Script
		Or Extension = ".VBS" // VBScript File
		Or Extension = ".VBSCRIPT" // Visual Basic Script
		Or Extension = ".WS"  // Windows Script
		Or Extension = ".WSF" // Windows Script
	// Linux
		Or Extension = ".CSH" // C Shell Script
		Or Extension = ".KSH" // Unix Korn Shell Script
		Or Extension = ".OUT" // 
		Or Extension = ".RUN" // 
		Or Extension = ".SH"  // Shell Script
	// macOS
		Or Extension = ".ACTION" // Automator Action
		Or Extension = ".APP" // 
		Or Extension = ".COMMAND" // Terminal Command
		Or Extension = ".OSX" // 
		Or Extension = ".WORKFLOW" // 
	// 
		Or Extension = ".AIR" // 
		Or Extension = ".COFFIE" // 
		Or Extension = ".JAR" // 
		Or Extension = ".JS"  // JScript File
		Or Extension = ".JSE" // JScript Encoded File
		Or Extension = ".PLX" // 
		Or Extension = ".PYC" // 
		Or Extension = ".PYO"; // 
	
EndFunction

#EndRegion

#Region OpenExplorer

// Continuation of the Filesystem Client procedure.Open the conductor.
Procedure OpenExplorerAfterCheckFileSystemExtension(ExtensionAttached, Context) Export
	
	FileInfo3 = Context.FileInfo3;
	
	If ExtensionAttached Then
		Notification = New NotifyDescription(
			"OpenExplorerAfterCheckIfExists", ThisObject, Context, 
			"OpenExplorerOnProcessError", ThisObject);
		FileInfo3.BeginCheckingExistence(Notification);
	Else
		ErrorDescription = NStr("en = 'To open the folder, install 1C:Enterprise Extension.';");
		OpenExplorerNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continuation of the Filesystem Client procedure.Open the conductor.
Procedure OpenExplorerAfterCheckIfExists(Exists, Context) Export 
	
	FileInfo3 = Context.FileInfo3;
	
	If Exists Then 
		Notification = New NotifyDescription(
			"OpenExplorerAfterCheckIsFIle", ThisObject, Context, 
			"OpenExplorerOnProcessError", ThisObject);
		FileInfo3.BeginCheckingIsFile(Notification);
	Else 
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The directory to be opened in the Explorer, does not exist:
			           |""%1""';"),
			FileInfo3.FullName);
		OpenExplorerNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continuation of the Filesystem Client procedure.Open the conductor.
Procedure OpenExplorerAfterCheckIsFIle(IsFile, Context) Export 
	
	// 
	
	FileInfo3 = Context.FileInfo3;
	
	Notification = New NotifyDescription(,,, "OpenExplorerOnProcessError", ThisObject);
	If IsFile Then
		If CommonClient.IsWindowsClient() Then
			BeginRunningApplication(Notification, "explorer.exe /select, """ + FileInfo3.FullName + """");
		Else // 
			BeginRunningApplication(Notification, "file:///" + FileInfo3.Path);
		EndIf;
	Else // 
		BeginRunningApplication(Notification, "file:///" + FileInfo3.FullName);
	EndIf;
	
	// 
	
EndProcedure

// Continuation of the Filesystem Client procedure.Open the conductor.
Procedure OpenExplorerOnProcessError(ErrorInfo, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	OpenExplorerNotifyOnError("", Context);
	
EndProcedure

// Continuation of the Filesystem Client procedure.Open the conductor.
Procedure OpenExplorerNotifyOnError(ErrorDescription, Context)
	
	If Not IsBlankString(ErrorDescription) Then 
		ShowMessageBox(, ErrorDescription);
	EndIf;
	
EndProcedure

#EndRegion

#Region OpenURL

// Continuation of the Filesystem Client procedure.Open the Navigation link.
Procedure OpenURLAfterCheckFileSystemExtension(ExtensionAttached, Context) Export
	
	// 
	
	URL = Context.URL;
	
	If ExtensionAttached Then
		
		Notification          = Context.Notification;
		WaitForCompletion = (Notification <> Undefined);
		
		Notification = New NotifyDescription(
			"OpenURLAfterStartApplication", ThisObject, Context,
			"OpenURLOnProcessError", ThisObject);
		BeginRunningApplication(Notification, URL,, WaitForCompletion);
		
	Else
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot follow link ""%1"" because 1C:Enterprise Extension is not installed.';"),
			URL);
		OpenURLNotifyOnError(ErrorDescription, Context);
	EndIf;
	
	// 
	
EndProcedure

// Continuation of the Filesystem Client procedure.Open the Navigation link.
Procedure OpenURLAfterStartApplication(ReturnCode, Context) Export 
	
	Notification = Context.Notification;
	
	If Notification <> Undefined Then 
		ApplicationStarted = (ReturnCode = 0 Or ReturnCode = Undefined);
		ExecuteNotifyProcessing(Notification, ApplicationStarted);
	EndIf;
	
EndProcedure

// Continuation of the Filesystem Client procedure.Open the Navigation link.
Procedure OpenURLOnProcessError(ErrorInfo, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	OpenURLNotifyOnError("", Context);
	
EndProcedure

// Continuation of the Filesystem Client procedure.Open the Navigation link.
Procedure OpenURLNotifyOnError(ErrorDescription, Context) Export
	
	Notification = Context.Notification;
	
	If Notification = Undefined Then
		If Not IsBlankString(ErrorDescription) Then 
			ShowMessageBox(, ErrorDescription);
		EndIf;
	Else 
		ApplicationStarted = False;
		ExecuteNotifyProcessing(Notification, ApplicationStarted);
	EndIf;
	
EndProcedure

// Checks whether the passed string is a web link.
// 
// Parameters:
//  String - String -  passed link.
// 
// Returns:
//  Boolean
// 
Function IsWebURL(String) Export
	
	Return StrStartsWith(String, "http://")  // 
		Or StrStartsWith(String, "https://");// 
	
EndFunction

// Checks whether the passed string is a reference to the built-in help.
// 
// Parameters:
//  String - String -  passed link.
// 
// Returns:
//  Boolean
//
Function IsHelpRef(String) Export
	
	Return StrStartsWith(String, "v8help://");
	
EndFunction

// Checks whether the passed string is a valid link in the Protocol whitelist.
// 
// Parameters:
//  String - String -  passed link.
// 
// Returns:
//  Boolean
//
Function IsAllowedRef(String) Export
	
	Return StrStartsWith(String, "e1c:")
		Or StrStartsWith(String, "e1cib/")
		Or StrStartsWith(String, "e1ccs/")
		Or StrStartsWith(String, "v8help:")
		Or StrStartsWith(String, "http:")
		Or StrStartsWith(String, "https:")
		Or StrStartsWith(String, "mailto:")
		Or StrStartsWith(String, "tel:")
		Or StrStartsWith(String, "skype:")
		Or StrStartsWith(String, "market:")
		Or StrStartsWith(String, "itms-apps:");
	
EndFunction

#EndRegion

#Region StartApplication

// Continuation of the Filesystem Client procedure.Run the program.
Procedure StartApplicationAfterCheckFileSystemExtension(ExtensionAttached, Context) Export
	
	If ExtensionAttached Then
		
		CurrentDirectory = Context.CurrentDirectory;
		
		If IsBlankString(CurrentDirectory) Then
			StartApplicationBeginRunning(Context);
		Else 
			FileInfo3 = New File(CurrentDirectory);
			Notification = New NotifyDescription(
				"StartApplicationAfterCheckIfExists", ThisObject, Context,
				"StartApplicationOnProcessError", ThisObject);
			FileInfo3.BeginCheckingExistence(Notification);
		EndIf;
		
	Else
		ErrorDescription = NStr("en = 'Cannot start the app because 1C:Enterprise Extension is not installed.';");
		StartApplicationNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continuation of the Filesystem Client procedure.Run the program.
Procedure StartApplicationAfterCheckIfExists(Exists, Context) Export
	
	CurrentDirectory = Context.CurrentDirectory;
	FileInfo3 = New File(CurrentDirectory);
	
	If Exists Then 
		Notification = New NotifyDescription(
			"StartApplicationAfterCheckIsDirectory", ThisObject, Context,
			"StartApplicationOnProcessError", ThisObject);
		FileInfo3.BeginCheckingIsDirectory(Notification);
	Else 
		CommandString = Context.CommandString;
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t start %1
			           | as the folder does not exist:
			           |%2';"),
			CommandString, CurrentDirectory);
		StartApplicationNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// 
//
Procedure StartApplicationAfterCheckIsDirectory(IsDirectory, Context) Export
	
	If IsDirectory Then
		StartApplicationBeginRunning(Context);
	Else
		CommandString = Context.CommandString;
		CurrentDirectory = Context.CurrentDirectory;
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t start %1
			           | as the specified object is not a folder:
			           |%2';"),
			CommandString, CurrentDirectory);
		StartApplicationNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continuation of the Filesystem Client procedure.Run the program.
Procedure StartApplicationBeginRunning(Context)
	
	// 
	
	If Context.ThreadsEncoding = Undefined Then 
		Context.ThreadsEncoding = StandardStreamEncoding();
	EndIf;
	
	// 
	If Context.ExecutionEncoding = Undefined And CommonClient.IsWindowsClient() Then 
		Context.ExecutionEncoding = "CP866";
	EndIf;

	If Context.ExecuteWithFullRights Then 
		StartApplicationWithFullRights(Context);
		Return;
	EndIf;
		
	ExecuteUsingPlatformMethod = True;
		
	#If Not WebClient And Not MobileClient Then
		If CommonClient.IsWindowsClient() Then
			ExecuteUsingPlatformMethod = False; 
			CommandString = Context.CommandString;
			CurrentDirectory = Context.CurrentDirectory;
			ExecutionEncoding = Context.ExecutionEncoding;
			WaitForCompletion = Context.WaitForCompletion;
			
			CommandString = CommonInternalClientServer.TheWindowsCommandStartLine(CommandString, CurrentDirectory, WaitForCompletion, ExecutionEncoding);
			
			Try
				Shell = New COMObject("Wscript.Shell");
				ReturnCode = Shell.Run(CommandString, 0, WaitForCompletion);
				Shell = Undefined;
			Except
				Shell = Undefined;
				ErrorInfo = ErrorInfo();
				StandardProcessing = True;
				StartApplicationOnProcessError(ErrorInfo, StandardProcessing, Context);
				Return;
			EndTry;
			
			If ReturnCode = Undefined Then 
				ReturnCode = 0;
			EndIf;
			
			StartApplicationAfterStartApplication(ReturnCode, Context);
		EndIf;
	#EndIf
	
	If ExecuteUsingPlatformMethod Then 
		CommandString = Context.CommandString;
		CurrentDirectory = Context.CurrentDirectory;
		WaitForCompletion = Context.WaitForCompletion;
		ExecutionEncoding = Context.ExecutionEncoding;
		
		If CommonClient.IsLinuxClient() And ValueIsFilled(ExecutionEncoding) Then
			CommandString = "LANGUAGE=" + ExecutionEncoding + " " + CommandString;
		EndIf;
		
		Notification = New NotifyDescription(
			"StartApplicationAfterStartApplication", ThisObject, Context,
			"StartApplicationOnProcessError", ThisObject);
		BeginRunningApplication(Notification, CommandString, CurrentDirectory, WaitForCompletion);
	EndIf;
	// 
	
EndProcedure

// 
//
// Returns:
//  TextEncoding
//
Function StandardStreamEncoding()
	
	Return ?(CommonClient.IsWindowsClient(), "CP866", "UTF-8");
	
EndFunction

// Continuation of the Filesystem Client procedure.Run the program.
Procedure StartApplicationAfterStartApplication(ReturnCode, Context) Export 
	
	Notification = Context.Notification;
	If Notification = Undefined Then
		Return;
	EndIf;
		
	Result = ApplicationStartResult();
	If Context.WaitForCompletion And ReturnCode = Undefined Then
		Result.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'An unexpected error occurred upon the startup of
				|%1';"),
			Context.CommandString);
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'An unexpected error occurred upon the startup:
				|Command line: %1
				|Directory: %2
				|Return code: %3
				|Wait for completion: %4';"),
			Context.CommandString,
			Context.CurrentDirectory,
			Context.ReturnCode,
			Context.WaitForCompletion);
		EventLogClient.AddMessageForEventLog(
			NStr("en = 'Standard subsystems';", CommonClient.DefaultLanguageCode()),
			"Error", ErrorDescription);
	Else
		Result.ApplicationStarted = True;
	EndIf;
	
	Result.ReturnCode = ?(ReturnCode <> Undefined, ReturnCode, -1);
	If Context.WaitForCompletion Then
		FillThreadResult(Result, Context);
	EndIf;
	ExecuteNotifyProcessing(Notification, Result);
	
EndProcedure

// Continuation of the Filesystem Client procedure.Run the program.
Procedure StartApplicationOnProcessError(ErrorInfo, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	StartApplicationNotifyOnError(ErrorDescription, Context);
	
EndProcedure

// Continuation of the Filesystem Client procedure.Run the program.
Procedure StartApplicationNotifyOnError(ErrorDescription, Context)
	
	Notification = Context.Notification;
	If Notification = Undefined Then
		If Not IsBlankString(ErrorDescription) Then
			ShowMessageBox(, ErrorDescription);
		EndIf;
		Return;
	EndIf;
		
	Result = ApplicationStartResult();
	Result.ErrorDescription = ErrorDescription;
	If Context.WaitForCompletion Then
		FillThreadResult(Result, Context);
	EndIf;
	ExecuteNotifyProcessing(Notification, Result);
	
EndProcedure

// Continuation of the Filesystem Client procedure.Run the program.
Function ApplicationStartResult()
	
	Result = New Structure;
	Result.Insert("ApplicationStarted", False);
	Result.Insert("ErrorDescription", "");
	Result.Insert("ReturnCode", -13);
	Result.Insert("OutputStream", "");
	Result.Insert("ErrorStream", "");
	
	Return Result;
	
EndFunction

// Continuation of the Filesystem Client procedure.Run the program.
Procedure StartApplicationWithFullRights(Context)
	
#If WebClient Then
	ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Cannot start %1.
		           |Reason:
		           |The web client does not support starting apps with elevated privileges.';"),
		Context.CommandString);
	StartApplicationNotifyOnError(ErrorDescription, Context);
#ElsIf MobileClient Then
	ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Couldn''t start %1.
		           |Reason:
		           |The web client does not support starting apps with elevated privileges.';"),
		Context.CommandString);
	StartApplicationNotifyOnError(ErrorDescription, Context);
#Else
	
	If CommonClient.IsWindowsClient() Then 
		StartApplicationWithFullWindowsRights(Context);
	ElsIf CommonClient.IsLinuxClient() Then 
		StartApplicationWithFullLinuxRights(Context);
	Else
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t start %1.
			           |Reason:
			           |Starting apps with elevated privileges is supported for Windows and Linux only.';"),
			Context.CommandString);
		StartApplicationNotifyOnError(ErrorDescription, Context);
	EndIf;
	
#EndIf
	
EndProcedure

// 
//
Procedure FillThreadResult(Result, Context)
	
#If Not WebClient Then
		
	If Context.GetOutputStream
		And Not IsBlankString(Context.OutputThreadFileName) Then
		Result.OutputStream = ReadThreadFile(Context.OutputThreadFileName, Context.ThreadsEncoding);
	EndIf;
	
	If Context.GetErrorStream
		And Not IsBlankString(Context.ErrorsThreadFileName) Then
		Result.ErrorStream = ReadThreadFile(Context.ErrorsThreadFileName, Context.ThreadsEncoding);
	EndIf;
		
#EndIf

EndProcedure

// 
//
Function ReadThreadFile(PathToFile, ThreadsEncoding)
	
	// 
	
#If WebClient Then
	Return "";
#Else
	ThreadFile = New File(PathToFile);
	If Not ThreadFile.Exists() Then
		Return "";
	EndIf;
	
	ReadThreadFile1 = New TextReader(PathToFile, ThreadsEncoding);
	Result = ReadThreadFile1.Read();
	ReadThreadFile1.Close();
	
	DeleteFiles(PathToFile);
	
	Return ?(Result = Undefined, "", Result);
#EndIf
	
	// 
	
EndFunction

#If Not WebClient And Not MobileClient Then

// 
//
Procedure StartApplicationWithFullWindowsRights(Context)
	
	// 
	
	CommandString = Context.CommandString;
	CurrentDirectory = Context.CurrentDirectory;
	ExecutionEncoding = Context.ExecutionEncoding;
	
	WaitForCompletion = False;
	
	CommandString = CommonInternalClientServer.TheWindowsCommandStartLine(CommandString, CurrentDirectory, WaitForCompletion, ExecutionEncoding);
	
	Try
		Shell = New COMObject("Shell.Application");
		// 
		ReturnCode = Shell.ShellExecute("cmd", "/c """ + CommandString + """",, "runas", 0);
		Shell = Undefined;
	Except
		Shell = Undefined;
		ErrorInfo = ErrorInfo();
		StandardProcessing = True;
		StartApplicationOnProcessError(ErrorInfo, StandardProcessing, Context);
		Return;
	EndTry;
	
	If ReturnCode = Undefined Then 
		ReturnCode = 0;
	EndIf;
	
	StartApplicationAfterStartApplication(ReturnCode, Context);
	
	// 
	
EndProcedure

// 
//
Procedure StartApplicationWithFullLinuxRights(Context)
	
	// 
	
	CurrentDirectory = Context.CurrentDirectory;
	CommandString = Context.CommandString;
	
	CommandWithPrivilegeEscalation = "pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY " + CommandString;
	WaitForCompletion = True;
	
	Notification = New NotifyDescription(
		"StartApplicationAfterStartApplication", ThisObject, Context,
		"StartApplicationOnProcessError", ThisObject);
	BeginRunningApplication(Notification, CommandWithPrivilegeEscalation, CurrentDirectory, WaitForCompletion);
	
	// 
	
EndProcedure

#EndIf

#EndRegion

#Region ChooseDirectory

// Continuation of the filesystem Client procedure.Select the catalog.
Procedure SelectDirectoryOnAttachFileSystemExtension(ExtensionAttached, Context) Export
	
	If Not ExtensionAttached Then
		ExecuteNotifyProcessing(Context.CompletionHandler, "");
		Return;
	EndIf;
	
	NotifyDescription = New NotifyDescription(
		"SelectDirectoryAtSelectionEnd", ThisObject, Context.CompletionHandler);
	
	Dialog = New FileDialog(FileDialogMode.ChooseDirectory);
	Dialog.Multiselect = False;
	If Not IsBlankString(Context.Title) Then
		Dialog.Title = Context.Title;
	EndIf;
	If Not IsBlankString(Context.Directory) Then
		Dialog.Directory = Context.Directory;
	EndIf;
	
	Dialog.Show(NotifyDescription);
	
EndProcedure

// Continuation of the filesystem Client procedure.Select the catalog.
Procedure SelectDirectoryAtSelectionEnd(DirectoriesArray, CompletionHandler) Export
	
	PathToDirectory = 
		?(DirectoriesArray = Undefined Or DirectoriesArray.Count() = 0,
			"", 
			DirectoriesArray[0]);
	
	ExecuteNotifyProcessing(CompletionHandler, PathToDirectory);
	
EndProcedure

#EndRegion

#Region ShowSelectionDialog

// 
//
Procedure ShowSelectionDialogOnAttachFileSystemExtension(ExtensionAttached, Context) Export
	
	If Not ExtensionAttached Then
		ExecuteNotifyProcessing(Context.CompletionHandler, "");
		Return;
	EndIf;
	
	Context.Dialog.Show(Context.CompletionHandler);
	
EndProcedure

#EndRegion

#Region FileSystemExtension

Procedure StartFileSystemExtensionAttachingOnSetExtension(Attached, Context) Export
	
	// 
	If Attached Then
		ExecuteNotifyProcessing(Context.NotifyDescriptionCompletion, "AttachmentNotRequired");
		Return;
	EndIf;
	
	// 
	If CommonClient.IsMacOSClient() 
			And Not AnExtensionForWorkingWithFilesIsAvailable() Then
		ExecuteNotifyProcessing(Context.NotifyDescriptionCompletion);
		Return;
	EndIf;
	
	ParameterName = "StandardSubsystems.SuggestFileSystemExtensionInstallation";
	FirstCallDuringSession = ApplicationParameters[ParameterName] = Undefined;
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, SuggestFileSystemExtensionInstallation());
	EndIf;
	
	SuggestFileSystemExtensionInstallation = ApplicationParameters[ParameterName] Or FirstCallDuringSession;
	If Context.CanContinueWithoutInstalling And Not SuggestFileSystemExtensionInstallation Then
		
		ExecuteNotifyProcessing(Context.NotifyDescriptionCompletion);
		
	Else 
		
		FormParameters = New Structure;
		FormParameters.Insert("SuggestionText", Context.SuggestionText);
		FormParameters.Insert("CanContinueWithoutInstalling", Context.CanContinueWithoutInstalling);
		OpenForm(
			"CommonForm.FileSystemExtensionInstallationQuestion", 
			FormParameters,,,,, 
			Context.NotifyDescriptionCompletion);
		
	EndIf;
	
EndProcedure

Procedure StartFileSystemExtensionAttachingWhenAnsweringToInstallationQuestion(Action, ClosingNotification1) Export
	
	ExtensionAttached = (Action = "ExtensionAttached" Or Action = "AttachmentNotRequired");
	
#If WebClient Then
	If Action = "DoNotPrompt"
		Or Action = "ExtensionAttached" Then
		
		SystemInfo = New SystemInfo();
		ClientID = SystemInfo.ClientID;
		ApplicationParameters["StandardSubsystems.SuggestFileSystemExtensionInstallation"] = False;
		CommonServerCall.CommonSettingsStorageSave(
			"ApplicationSettings/SuggestFileSystemExtensionInstallation", ClientID, False);
		
	EndIf;
#EndIf
	
	ExecuteNotifyProcessing(ClosingNotification1, ExtensionAttached);
	
EndProcedure

Function SuggestFileSystemExtensionInstallation()
	
	SystemInfo = New SystemInfo();
	ClientID = SystemInfo.ClientID;
	Return CommonServerCall.CommonSettingsStorageLoad(
		"ApplicationSettings/SuggestFileSystemExtensionInstallation", ClientID, True);
	
EndFunction

Function AnExtensionForWorkingWithFilesIsAvailable()

	SystemInfo = New SystemInfo;
	Return StrFind(SystemInfo.UserAgentInformation, "Chrome") > 0;

EndFunction

#EndRegion

#Region TemporaryFiles

#Region CreateTemporaryDirectory

// Continuation of the filesystem Client procedure.Create a temporary directory.
// 
// Parameters:
//  ExtensionAttached - Boolean
//  Context - Structure:
//   * Notification - NotifyDescription
//   * Extension - String
//
Procedure CreateTemporaryDirectoryAfterCheckFileSystemExtension(ExtensionAttached, Context) Export
	
	If ExtensionAttached Then
		Notification = New NotifyDescription(
			"CreateTemporaryDirectoryAfterGetTemporaryDirectory", ThisObject, Context,
			"CreateTemporaryDirectoryOnProcessError", ThisObject);
		BeginGettingTempFilesDir(Notification);
	Else
		CreateTemporaryDirectoryNotifyOnError(NStr("en = 'Cannot install 1C:Enterprise Extension.';"), Context);
	EndIf;
	
EndProcedure

// Continuation of the filesystem Client procedure.Create a temporary directory.
// 
// Parameters:
//  TempFilesDirName - String
//  Context - Structure:
//   * Notification - NotifyDescription
//   * Extension - String
//
Procedure CreateTemporaryDirectoryAfterGetTemporaryDirectory(TempFilesDirName, Context) Export 
	
	Notification = Context.Notification;
	Extension = Context.Extension;
	
	DirectoryName = "v8_" + String(New UUID);
	
	If Not IsBlankString(Extension) Then 
		DirectoryName = DirectoryName + "." + Extension;
	EndIf;
	
	BeginCreatingDirectory(Notification, TempFilesDirName + DirectoryName);
	
EndProcedure

// Continuation of the filesystem Client procedure.Create a temporary directory.
Procedure CreateTemporaryDirectoryOnProcessError(ErrorInfo, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	CreateTemporaryDirectoryNotifyOnError(ErrorDescription, Context);
	
EndProcedure

// Continuation of the filesystem Client procedure.Create a temporary directory.
Procedure CreateTemporaryDirectoryNotifyOnError(ErrorDescription, Context)
	
	ShowMessageBox(, ErrorDescription);
	DirectoryName = "";
	ExecuteNotifyProcessing(Context.Notification, DirectoryName);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion