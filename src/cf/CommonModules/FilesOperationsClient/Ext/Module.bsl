///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// 

// Opens the file for viewing or editing.
// If the file is opened for viewing, it gets the file to the user's working directory
// , searches for the file in the working directory, and offers to open an existing one or get the file from the server.
// If the file is opened for editing, it opens the file in the working directory (if available) or
// retrieves it from the server.
//
// Parameters:
//  FileData       - See FilesOperations.FileData.
//  ForEditing - Boolean -  True if the file is opened for editing, otherwise False.
//
Procedure OpenFile(Val FileData, Val ForEditing = False) Export
	
	If ForEditing Then
		FilesOperationsInternalClient.EditFile(Undefined, FileData);
	Else
		FilesOperationsInternalClient.OpenFileWithNotification(Undefined, FileData, , ForEditing); 
	EndIf;
	
EndProcedure

// Opens the folder on the computer where the specified file is located in the standard viewer (file Explorer)
// .
//
// Parameters:
//  FileData - See FilesOperations.FileData.
//
Procedure OpenFileDirectory(FileData) Export
	
	FilesOperationsInternalClient.FileDirectory(Undefined, FileData);
	
EndProcedure

// Opens the file selection dialog for placing one or more files in the program.
// This is done by checking the necessary conditions:
// - the file size does not exceed the maximum allowed,
// - the file has a valid extension,
// - there is free space in the volume (when storing files in volumes),
// - other conditions.
//
// Parameters:
//  FileOwner      - DefinedType.AttachedFilesOwner -  the file folder or object
//                       to attach the file to.
//  FormIdentifier - UUID -  unique ID of the form
//                       that the file will be placed in temporary storage.
//  Filter             - String -  filter the selected file, for example, images for the item.
//  FilesGroup       - DefinedType.AttachedFile -  the directory group with files to 
//                       add the new file to.
//  ResultHandler - NotifyDescription - 
//                         :
//        
//        
//
Procedure AddFiles(Val FileOwner, Val FormIdentifier, Val Filter = "", FilesGroup = Undefined,
	ResultHandler = Undefined) Export
	
	If Not ValueIsFilled(FileOwner) Then
		Template = NStr("en = 'The %1 parameter value is not set in %2.';");
		Raise StringFunctionsClientServer.SubstituteParametersToString(Template, "FileOwner", 
			"FilesOperationsClient.AddFiles");
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("FileOwner",        FileOwner);
	Parameters.Insert("FormIdentifier",   FormIdentifier);
	Parameters.Insert("Filter",               Filter);
	Parameters.Insert("FilesGroup",         FilesGroup);
	Parameters.Insert("ResultHandler", ResultHandler);
	
	NotifyDescription = New NotifyDescription("AddFilesAddInSuggested", FilesOperationsInternalClient, Parameters);
	FilesOperationsInternalClient.ShowFileSystemExtensionInstallationQuestion(NotifyDescription);
	
EndProcedure

// Opens the file selection dialog for placing a single selected file in the program.
//
// Parameters:
//   ResultHandler - NotifyDescription - 
//                        :
//                    * Result - Structure:
//                       ** FileRef - DefinedType.AttachedFile -  link to the directory element with the file,
//                                     if it was added, otherwise Undefined.
//                       ** FileAdded - Boolean -  True if the file was added.
//                       ** ErrorText  - String -  error text if the file was not added.
//                    * AdditionalParameters - Arbitrary -  the value specified when creating the notification object.
//
//   FileOwner - DefinedType.AttachedFilesOwner -  the file folder or object
//                 to attach the file to.
//   OwnerForm - ClientApplicationForm -  the form that the file creation was called from.
//   CreateMode - Undefined
//                 - Number - :
//                 - Undefined - 
//                 - Number - :
//                           
//                           
//                           
//
//   AddingOptions - Structure - :
//     * MaximumSize  - Number -  limit on the size of the file (in megabytes) that can be downloaded from the file system.
//                           If it takes the value 0, the size check is not performed. This property is ignored
//                           if it takes a value greater than specified in the maximum file Size constant.
//     * SelectionDialogFilter - String -  the filter that is set in the selection dialog when adding a file.
//                           For the format, see the Filter property of the Dialog File Selection object in the Syntax Assistant.
//     * NotOpenCard - Boolean -  action after creation. If the value is True, the file card
//                           will not be opened after creation, otherwise the file card will be opened.
//
Procedure AppendFile(ResultHandler, FileOwner, OwnerForm, CreateMode = Undefined, 
	AddingOptions = Undefined) Export
	
	If Not ValueIsFilled(FileOwner) Then
		Template = NStr("en = 'The %1 parameter value is not set in %2.';");
		Raise StringFunctionsClientServer.SubstituteParametersToString(Template, "FileOwner",
			"FilesOperationsClient.AppendFile");
	EndIf;
	
	ExecutionParameters = New Structure;
	If AddingOptions = Undefined
		Or TypeOf(AddingOptions) = Type("Boolean") Then
		
		ExecutionParameters.Insert("MaximumSize" , 0);
		ExecutionParameters.Insert("NotOpenCard", ?(AddingOptions = Undefined, False, AddingOptions));
		ExecutionParameters.Insert("SelectionDialogFilter",  
			StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'All files (%1)|%1';"), GetAllFilesMask()));
		
	Else
		ExecutionParameters.Insert("MaximumSize" , AddingOptions.MaximumSize);
		ExecutionParameters.Insert("NotOpenCard", AddingOptions.NotOpenCard);
		ExecutionParameters.Insert("SelectionDialogFilter", AddingOptions.SelectionDialogFilter);
	EndIf;
	
	If CreateMode = Undefined Then
		FilesOperationsInternalClient.AppendFile(ResultHandler, FileOwner, OwnerForm, , ExecutionParameters);
	Else
		ExecutionParameters.Insert("ResultHandler", ResultHandler);
		ExecutionParameters.Insert("FileOwner", FileOwner);
		ExecutionParameters.Insert("OwnerForm", OwnerForm);
		ExecutionParameters.Insert("OneFileOnly", True);
		FilesOperationsInternalClient.AddAfterCreationModeChoice(CreateMode, ExecutionParameters);
	EndIf;
	
EndProcedure

// Opens a form to configure settings for the working directory of your personal user settings of the program.
// Working directory - a folder on the user's personal computer that temporarily stores files
// received from the program for viewing or editing.
//
Procedure OpenWorkingDirectorySettingsForm() Export
	
	OpenForm("CommonForm.WorkingDirectorySettings");
	
EndProcedure

// Show a warning before closing the object form
// if the user still has captured files attached to this object.
// Called from the event Before closing forms with files.
//
// If the captured files remain, the Refuse parameter is set to True,
// and the user is asked a question. If the user answered Yes, the form is closed.
//
// Parameters:
//   Form            - ClientApplicationForm -  the form in which the file is edited.
//   Cancel            - Boolean -  parameter of the pre-Closing event.
//   Exit - Boolean -  indicates that the form is being closed while the application is shutting down.
//   FilesOwner   - DefinedType.AttachedFilesOwner -  the file folder or object that
//                      the files are attached to.
//   AttributeName     - String -  name of the Boolean attribute that stores
//                      the indication that the question has already been output.
//
// Example:
//
//	&Naciente
//	Procedure Prezcription(Denial, Superseniority, Textpageprivate, Standartnaya)
//		Remotevalidation.Show Confirmation Of Closing Formsfiles(This Is An Object, Failure, Completion Of Work, Object.Link);
//	End of procedure
//
Procedure ShowConfirmationForClosingFormWithFiles(Form, Cancel, Exit, FilesOwner,
	AttributeName = "CanCloseFormWithFiles") Export
	
	ProcedureName = "FilesOperationsClient.ShowConfirmationForClosingFormWithFiles";
	CommonClientServer.CheckParameter(ProcedureName, "Form", Form, Type("ClientApplicationForm"));
	CommonClientServer.CheckParameter(ProcedureName, "Cancel", Cancel, Type("Boolean"));
	CommonClientServer.CheckParameter(ProcedureName, "Exit", Exit, Type("Boolean"));
	CommonClientServer.CheckParameter(ProcedureName, "AttributeName", AttributeName, Type("String"));
		
	If Form[AttributeName] Then
		Return;
	EndIf;
	
	If Exit Then
		Return;
	EndIf;
	
	Count = FilesOperationsInternalServerCall.FilesLockedByCurrentUserCount(FilesOwner);
	If Count = 0 Then
		Return;
	EndIf;
	
	Cancel = True;
	
	QueryText = NStr("en = 'One or several files are locked for editing.
	                          |
	                          |Do you want to continue?';");
	CommonClient.ShowArbitraryFormClosingConfirmation(Form, Cancel, Exit, QueryText, AttributeName);
	
EndProcedure

// Opens a new file form with a copy of the specified file.
//
// Parameters:
//  FileOwner - DefinedType.AttachedFilesOwner -  the file folder or object that the file is attached to.
//  BasisFile - DefinedType.AttachedFile -  copy files.
//  AdditionalParameters - Structure - :
//    * FilesStorageCatalogName - String -  defines a directory for storing a copy of the file.
//  OnCloseNotifyDescription - NotifyDescription - 
//                                :
//                                
//                                
//                                
//                                
//
Procedure CopyAttachedFile(FileOwner, BasisFile, AdditionalParameters = Undefined,
	OnCloseNotifyDescription = Undefined) Export
	
	If Not ValueIsFilled(FileOwner) Then
		Template = NStr("en = 'The %1 parameter value is not set in %2.';");
		Raise StringFunctionsClientServer.SubstituteParametersToString(Template, "FileOwner",
			"FilesOperationsClient.CopyAttachedFile");
	EndIf;
	
	AreFiles = TypeOf(BasisFile) = Type("CatalogRef.Files");
	
	FormParameters = New Structure;
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FormParameters = CommonClient.CopyRecursive(AdditionalParameters);
		FilesStorageCatalogName = Undefined;
		If AdditionalParameters.Property("FilesStorageCatalogName", FilesStorageCatalogName) Then
			AreFiles = (FilesStorageCatalogName = "Files");
		EndIf;
	EndIf;
	
	FormParameters.Insert("CopyingValue", BasisFile);
	FormParameters.Insert("FileOwner", FileOwner);
	
	If AreFiles Then
		OpenForm("Catalog.Files.ObjectForm", FormParameters,,,,, OnCloseNotifyDescription);
	Else
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFile", FormParameters,,,,, OnCloseNotifyDescription);
	EndIf;
	
EndProcedure

// 
// 
// 
//
// 
//
// Parameters:
//  AttachedFile - DefinedType.AttachedFile -  link to the directory element with the file.
//  FormIdentifier - UUID  -  unique form ID that is used to block the file.
//
Procedure SaveWithDigitalSignature(Val AttachedFile, Val FormIdentifier) Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToSave(AttachedFile);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("AttachedFile", AttachedFile);
	ExecutionParameters.Insert("FileData",        FileData);
	ExecutionParameters.Insert("FormIdentifier", FormIdentifier);
	
	DataDetails = New Structure;
	DataDetails.Insert("DataTitle",     NStr("en = 'File';"));
	DataDetails.Insert("ShowComment", True);
	DataDetails.Insert("Presentation",       ExecutionParameters.FileData.Ref);
	DataDetails.Insert("Object",              AttachedFile);
	
	DataDetails.Insert("Data",
		New NotifyDescription("OnSaveFileData", FilesOperationsInternalClient, ExecutionParameters));
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.SaveDataWithSignature(DataDetails);
	
EndProcedure

// Opens the save file dialog, where the user can specify the path and name to save the file.
//
// Parameters:
//   FileData           - See FilesOperations.FileData.
//   CompletionHandler  - NotifyDescription
//                         - Undefined - 
//                           :
//      
//      
//
Procedure SaveFileAs(Val FileData, CompletionHandler = Undefined) Export
	
	Notification = New NotifyDescription("SaveFileAsAfterSave",
		FilesOperationsInternalClient, CompletionHandler);
	
	FilesOperationsInternalClient.SaveAs(Notification, FileData, Undefined);
	
EndProcedure

// Opens the file selection form.
// Used in the selection handler to override the standard behavior.
//
// Parameters:
//  FilesOwner - DefinedType.AttachedFilesOwner -  the file folder or object
//                   that the selected files are attached to.
//  FormItem   - FormTable
//                 - FormField - 
//                   
//  StandardProcessing - Boolean -  the return value. Always set to False.
//  ChoiceNotificationDetails - NotifyDescription -  
//                                                   :
//    
//                   - Undefined -  
//                     
//    
//
Procedure OpenFileChoiceForm(Val FilesOwner, Val FormItem, StandardProcessing = False,
	ChoiceNotificationDetails = Undefined) Export
	
	StandardProcessing = False;

	If FilesOwner.IsEmpty() Then
		OnCloseNotifyHandler = New NotifyDescription("PromptForWriteRequiredAfterCompletion", ThisObject);
		ShowQueryBox(OnCloseNotifyHandler,
			NStr("en = 'You have unsaved data.
				|You can open ""Attachments"" after saving the data.';"),
				QuestionDialogMode.OK);
	Else
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceMode", True);
		FormParameters.Insert("FileOwner", FilesOwner);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles", FormParameters, FormItem,,,,
						?(ChoiceNotificationDetails <> Undefined, ChoiceNotificationDetails, Undefined));
	EndIf;
	
EndProcedure

// 
//
// Parameters:
//  FilesOwner - DefinedType.AttachedFilesOwner -  the file folder or object
//                   that the selected files are attached to.
//
Procedure OpenFileListForm(Val FilesOwner) Export
	
	If FilesOperationsInternalClient.Is1CDocumentManagementUsedForFileStorage(FilesOwner) Then
		
		// IntegrationWith1CDocumentManagementSubsystem
		FilesOperationsInternalClient.OpenFormAttachedFiles1CDocumentManagement(FilesOwner);
		// End IntegrationWith1CDocumentManagementSubsystem
		
	Else
		
		FormParameters = New Structure();
		FormParameters.Insert("FileOwner", FilesOwner);
		FormParameters.Insert("ShouldHideOwner", False);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles", FormParameters);
		
	EndIf;
	
EndProcedure

// Opens the file form.
// It can be used as a handler for opening a file.
//
// Parameters:
//  AttachedFile      - DefinedType.AttachedFile -  link to the directory element with the file.
//  StandardProcessing    - Boolean -  the return value. Always set to False.
//  AdditionalParameters - Structure -  parameters for opening the form.
//  OnCloseNotifyDescription - NotifyDescription - 
//                                :
//                                
//                                 
//                                 
//                                
//
Procedure OpenFileForm(Val AttachedFile, StandardProcessing = False, AdditionalParameters = Undefined, 
	OnCloseNotifyDescription = Undefined) Export
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(AttachedFile) Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FormParameters = CommonClient.CopyRecursive(AdditionalParameters);
	EndIf;	
	If TypeOf(AttachedFile) = Type("CatalogRef.Files") Then
		FormParameters.Insert("Key", AttachedFile);
		OpenForm("Catalog.Files.ObjectForm", FormParameters,,,,, OnCloseNotifyDescription);
	Else	
		FormParameters.Insert("AttachedFile", AttachedFile);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFile", FormParameters,, AttachedFile,,, OnCloseNotifyDescription);
	EndIf;
	
EndProcedure

// Prints files to the printer.
//
// Parameters:
//  Files              - DefinedType.AttachedFile
//                     - Array of DefinedType.AttachedFile
//  FormIdentifier - UUID -  unique ID of the form
//                       that the file will be placed in temporary storage.
//
Procedure PrintFiles(Val Files, FormIdentifier = Undefined) Export
	
	If TypeOf(Files) <> Type("Array") Then
		Files = CommonClientServer.ValueInArray(Files);
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("FileNumber",   0);
	ExecutionParameters.Insert("FilesData", Files);
	ExecutionParameters.Insert("FileData",  Files);
	ExecutionParameters.Insert("UUID", FormIdentifier);
	PrintFilesExecution(Undefined, ExecutionParameters);
	
EndProcedure

// 
// 
// 
//
// Parameters:
//  AttachedFile      - DefinedType.AttachedFile -  link to the directory element with the file.
//                          - Array of DefinedType.AttachedFile
//  FormIdentifier      - UUID -  unique ID of the form
//                            that is used to block the file.
//  AdditionalParameters - Undefined - 
//                          - Structure:
//       * FileData            - See FilesOperations.FileData
//                                - Array of See FilesOperations.FileData
//       
//                                  
//                                  
//  SignatureParameters         - See DigitalSignatureClient.NewSignatureType
//
Procedure SignFile(AttachedFile, FormIdentifier, AdditionalParameters = Undefined,
	SignatureParameters = Undefined) Export
	
	If Not ValueIsFilled(AttachedFile) Then
		ShowMessageBox(, NStr("en = 'Please select a file to sign.';"));
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ShowMessageBox(, NStr("en = 'This app version doesn''t support adding digital signatures.';"));
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	
	If Not ModuleDigitalSignatureClient.UseDigitalSignature() Then
		ShowMessageBox(,
			NStr("en = 'Digital signatures cannot be added due to the app settings.';"));
		Return;
	EndIf;
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	If Not AdditionalParameters.Property("FileData") Then
		AdditionalParameters.Insert("FileData", FilesOperationsInternalServerCall.FileDataForSigning(
			AttachedFile, FormIdentifier));
	EndIf;
	
	ResultProcessing = Undefined;
	AdditionalParameters.Property("ResultProcessing", ResultProcessing);
	
	FilesOperationsInternalClient.SignFile(AttachedFile,
		AdditionalParameters.FileData, FormIdentifier, ResultProcessing, Undefined, SignatureParameters);
	
EndProcedure

// Returns structured information about the file. It is used in various file management commands
// and as the value of the Data file parameter of other procedures and functions.
//
// Parameters:
//   FileRef - DefinedType.AttachedFile -  link to the directory element with the file.
//   FormIdentifier             - UUID -  unique ID of the form
//                                     to put the file in temporary storage and return the address in the link property of the Binary data file.
//   GetBinaryDataRef - Boolean -  if False, the binary data reference in the binary data file
//                                     reference will not be received, which will significantly speed up execution for large binary data.
//   ForEditing              - Boolean -  if set to True, the file will be captured for editing.
//
// Returns:
//   See FilesOperations.FileData
//
Function FileData(Val FileRef,
                    Val FormIdentifier = Undefined,
                    Val GetBinaryDataRef = True,
                    Val ForEditing = False) Export
	
	Return FilesOperationsInternalServerCall.GetFileData(
		FileRef,
		FormIdentifier,
		GetBinaryDataRef,
		ForEditing);

EndFunction

// Retrieves a file from the file store to the user's working directory.
// Analogous to the interactive action View or Edit without opening the received file.
// The only View property of the received file will be set depending on whether
// the file is captured for editing or not. If not captured, only view is set.
// If a file already exists in the working directory, then it will be deleted and replaced with a file
// obtained from the file storage.
//
// Parameters:
//  Notification - NotifyDescription - 
//   :
//     
//     
//
//  AttachedFile - DefinedType.AttachedFile -  link to the directory element with the file.
//  FormIdentifier - UUID -  unique ID of the form
//                       that the file will be placed in temporary storage.
//
//  AdditionalParameters - Undefined -  to use the default values.
//                          - Structure - :
//         * ForEditing - Boolean    -  the initial value is False. If True,
//                                           then the file will be captured for editing.
//         * FileData       - Structure -  file properties that can be passed for acceleration
//                                           if they were previously received to the client from the server.
//
Procedure GetAttachedFile(Notification, AttachedFile, FormIdentifier, AdditionalParameters = Undefined) Export
	
	FilesOperationsInternalClient.GetAttachedFile(Notification, AttachedFile, FormIdentifier, AdditionalParameters);
	
EndProcedure

// Places a file from the user's working directory in the file storage.
// Analogous to the interactive action Finish editing.
//
// Parameters:
//  Notification - NotifyDescription - 
//   :
//     
//
//  AttachedFile - DefinedType.AttachedFile -  link to the directory element with the file.
//  FormIdentifier - UUID -  unique ID of the form
//          to put data in temporary storage and return a new address to.
//
//  AdditionalParameters - Undefined -  to use the default values.
//                          - Structure - :
//         * FullFileName - String -  if filled in, the specified file will be placed in
//                                     the user's working directory, and then in the file storage.
//         * FileData    - Structure -  file properties that can be passed for acceleration
//                                        if they were previously received to the client from the server.
//
Procedure PutAttachedFile(Notification, AttachedFile, FormIdentifier, AdditionalParameters = Undefined) Export
	
	FilesOperationsInternalClient.PutAttachedFile(Notification, AttachedFile, FormIdentifier, AdditionalParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Opens the scan settings form from the user settings.
//
Procedure OpenScanSettingForm() Export
	
	If Not FilesOperationsInternalClient.ScanAvailable() Then
		MessageText = NStr("en = 'Scanning is supported for MS Windows and Linux OS.';");
		ShowMessageBox(, MessageText);
		Return;
	EndIf;
	
	Handler = New NotifyDescription("OpenScanSettingFormCompletion", ThisObject);
	
	FilesOperationsInternalClient.InitAddIn(Handler, True);
		
EndProcedure

// 
// 
// Returns:
//  Structure:
//   * ResultType - See ConversionResultTypeFileName
//                   - See ConversionResultTypeBinaryData
//                   - See ConversionResultTypeAttachedFile
//   
//    See ConversionResultTypeFileName
//   
//
Function GraphicDocumentConversionParameters() Export
	
	ConversionParameters_SSLy = New Structure;
	ConversionParameters_SSLy.Insert("ResultType", ConversionResultTypeFileName());
	ConversionParameters_SSLy.Insert("ResultFormat", "pdf");
	ConversionParameters_SSLy.Insert("ResultFileName", "");
	
	UserScanSettings = GetUserScanSettings();
	
	ConversionParameters_SSLy.Insert("UseImageMagick", 
		UserScanSettings.UseImageMagickToConvertToPDF);
		
	Return ConversionParameters_SSLy;
	
EndFunction

// 
// 
// Returns:
//  String
//
Function ConversionResultTypeFileName() Export
	
	Return "File";
	
EndFunction

// 
// 
// Returns:
//  String
//
Function ConversionResultTypeBinaryData() Export
	
	Return "BinaryData";
	
EndFunction

// 
// 
// Returns:
//  String
//
Function ConversionResultTypeAttachedFile() Export
	
	Return "AttachedFile";
	
EndFunction


// 
// 
// Parameters:
//  NotificationOfReturn - NotifyDescription - 
//  ObjectsForMerging - Array of BinaryData, DefinedType.AttachedFile, String - 
//                          
//                          
//  GraphicDocumentConversionParameters - See FilesOperationsClient.GraphicDocumentConversionParameters.
// 
Procedure CombineToMultipageFile(NotificationOfReturn, ObjectsForMerging, GraphicDocumentConversionParameters) Export
	
	Result = ResultOfMergeIntoMultipageDocument();
	UserScanSettings = GetUserScanSettings();
	
	UseImageMagick = GraphicDocumentConversionParameters.UseImageMagick; 
	PathToConverterApplication = UserScanSettings.PathToConverterApplication;
	
		Context = New Structure;
	Context.Insert("NotificationOfReturn", NotificationOfReturn);
	Context.Insert("ObjectsForMerging", ObjectsForMerging);
	Context.Insert("GraphicDocumentConversionParameters", GraphicDocumentConversionParameters);
	Context.Insert("UserScanSettings", UserScanSettings);
	
	If ObjectsForMerging.Count() = 0 Then
		Result.ErrorDescription = NStr("en = 'Images for merging are not specified.';");
		ExecuteNotifyProcessing(NotificationOfReturn, Result);
		Return;
	ElsIf UseImageMagick And Not ValueIsFilled(PathToConverterApplication) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Path to the %1 application is not specified.
		|Multipage documents are merged using 1C:Enterprise tools.';"), "ImageMagick");
		
		EventLogClient.AddMessageForEventLog(EventLogEvent(),
			"Warning", ErrorText,, True);
		Context.GraphicDocumentConversionParameters.UseImageMagick = False;
		MergeIntoMultipageFileFollowUp(Context);
		Return;
	EndIf;
	
#If Not WebClient And Not MobileClient Then
		
	If UseImageMagick Then
		NotificationOfResult = New NotifyDescription("AfterCheckIfConversionAppInstalled", ThisObject, Context);
		StartCheckConversionAppPresence(PathToConverterApplication, NotificationOfResult);
		Return;
	EndIf;
	
	MergeIntoMultipageFileFollowUp(Context);
	
#EndIf
EndProcedure

// 
// 
// Parameters:
//  Fill - Boolean - 
// 
// Returns:
//  Structure:
//   * ShowDialogBox - Boolean - 
//                                 
//   * SelectedDevice - String -  name of the scanner.
//   * PictureFormat - String - 
//   * Resolution - Number - 
//   * Chromaticity - Number - 
//   * Rotation - Number -  
//                       
//   * PaperSize - Number - 
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
//   * JPGQuality - Number - 
//                           
//   * TIFFDeflation - Number - :
//     
//     
//     
//     
//     
//   * DuplexScanning - Boolean - 
//   * DocumentAutoFeeder - Boolean - 
//   * ShouldSaveAsPDF - Boolean
//   * UseImageMagickToConvertToPDF - Boolean
//
Function ScanningParameters(Fill = False) Export
	ScanningParameters = FilesOperationsInternalClientServer.ScanningParameters();
	ClientID = FilesOperationsInternalClient.ClientID();
	
	If Fill And ClientID <> Undefined Then
		FilesOperationsInternalServerCall.FillScanSettings(ScanningParameters, ClientID);
	EndIf;
	Return ScanningParameters;
EndFunction

// 
// 
// Returns:
//  Structure:
//    * ResultHandler - Undefined, NotifyDescription - 
//    * FileOwner - Undefined, DefinedType.FilesOwner - 
//                                                                     
//    * OwnerForm - Undefined, Form - 
//    * NotOpenCardAfterCreateFromFile - Boolean - 
//    * IsFile - Boolean
//    * ResultType - See ConversionResultTypeFileName 
//                    - See ConversionResultTypeBinaryData
//                    - See ConversionResultTypeAttachedFile
//    
//
Function AddingFromScannerParameters() Export
	AddingOptions = New Structure;
	AddingOptions.Insert("ResultHandler", Undefined);
	AddingOptions.Insert("FileOwner", Undefined);
	AddingOptions.Insert("OwnerForm", Undefined);
	AddingOptions.Insert("NotOpenCardAfterCreateFromFile", True);
	AddingOptions.Insert("IsFile", True);
	AddingOptions.Insert("ResultType", ConversionResultTypeAttachedFile());
	AddingOptions.Insert("OneFileOnly", False);
	Return AddingOptions;
EndFunction

//  
// 
// 
// Parameters:
//  AddingOptions - See AddingFromScannerParameters
//  ScanningParameters - See ScanningParameters
//
Procedure AddFromScanner(AddingOptions, ScanningParameters = Undefined) Export
	
	FilesOperationsInternalClient.AddFromScanner(AddingOptions, ScanningParameters);
	
EndProcedure

// 
// 
// Returns:
//   See FilesOperationsInternalClient.ScanAvailable
//
Function ScanAvailable() Export
	Return FilesOperationsInternalClient.ScanAvailable();
EndFunction

//  
// 
// 
// Parameters:
//  NotificationOfResult - NotifyDescription - :
//   * Result - Boolean - 
//   * AdditionalParameters - Arbitrary - 
//
Procedure ScanCommandAvailable(NotificationOfResult) Export
	
	If ScanAvailable() Then
		NotifyDescription = New NotifyDescription("ScanCommandAvailableCompletion", ThisObject, NotificationOfResult);
		FilesOperationsInternalClient.InitAddIn(NotifyDescription);
	Else
		ExecuteNotifyProcessing(NotificationOfResult, False);
	EndIf;
	
EndProcedure

// 
// 
// Parameters:
//  ClientID - UUID - 
// 
// Returns:
//   See FilesOperationsClientServer.UserScanSettings
//
Function GetUserScanSettings(ClientID = Undefined) Export
	
	If ClientID = Undefined Then
		ClientID = FilesOperationsInternalClient.ClientID();
	EndIf;
	
	Return FilesOperationsInternalServerCall.GetUserScanSettings(ClientID);
	
EndFunction

// 
// 
// Parameters:
//  UserScanSettings - See FilesOperationsClientServer.UserScanSettings
//  ClientID - UUID - 
//
Procedure SaveUserScanSettings(UserScanSettings, ClientID = Undefined) Export
	
	If ClientID = Undefined Then
		ClientID = FilesOperationsInternalClient.ClientID();
	EndIf;
	
	FilesOperationsInternalServerCall.SaveUserScanSettings(UserScanSettings, ClientID);
	
EndProcedure

#Region AttachedFilesManagement

// Event handler for opening the managed form of the file owner.
//
// Parameters:
//  Form - ClientApplicationForm -  form of the file owner.
//  Cancel - Boolean -  standard parameter for the managed form's Open event.
//
Procedure OnOpen(Form, Cancel) Export
	ScannerExistence = FilesOperationsInternalClient.ScanAvailable();
	If Not ScannerExistence Then
		ChangeAdditionalCommandsVisibility(Form);
	EndIf;
EndProcedure

// Event handler for handling the Announcement of the managed form of the file owner.
//
// Parameters:
//  Form      - ClientApplicationForm -  form of the file owner.
//  EventName - String -  standard parameter for the managed form's message Processing event.
//
Procedure NotificationProcessing(Form, EventName) Export
	
	If EventName <> "Write_File" Then
		Return;
	EndIf;
		
	For ItemNumber = 0 To Form.FilesOperationsParameters.FormElementsDetails.UBound() Do
		
		DisplayCount = Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].DisplayCount;
		If Not DisplayCount Then
			Continue;
		EndIf;
		
		AttachedFilesOwner = AttachedFileParameterValue(Form, ItemNumber, "PathToOwnerData");
		AttachedFilesCount = FilesOperationsInternalServerCall.AttachedFilesCount(AttachedFilesOwner);
		AttachedFilesCountAsString = Format(AttachedFilesCount, "NG=");
		
		Hyperlink = Form.Items.Find(FilesOperationsClientServer.CommandsPrefix() + FilesOperationsClientServer.OpenListCommandName() + ItemNumber);
		If Hyperlink = Undefined Then
			Continue;
		EndIf;
			
		CountPositionInTitle = StrFind(Hyperlink.Title, "(");
		If CountPositionInTitle = 0 Then
			Hyperlink.Title = Hyperlink.Title 
						+ ?(AttachedFilesCount = 0, "",
						" (" + AttachedFilesCountAsString + ")");
		Else
			Hyperlink.Title = Left(Hyperlink.Title, CountPositionInTitle - 1)
						+ ?(AttachedFilesCount = 0, "",
						"(" + AttachedFilesCountAsString + ")");
		EndIf;
		
	EndDo;
	
EndProcedure

// Handler for executing additional commands for managing attached files.
//
// Parameters:
//  Form   - ClientApplicationForm -  form of the file owner.
//  Command - FormCommand -  executed command.
//
Procedure AttachmentsControlCommand(Form, Command) Export
	
	Position = StrFind(Command.Name, "_",SearchDirection.FromEnd);
	If Position = 0 Then
		Return;
	EndIf;
	
	NumAsString = Mid(Command.Name, Position + 1);
	
	ItemNumber = Number(StrReplace(NumAsString, FilesOperationsClientServer.OneFileOnlyText(), ""));
	AttachedFilesOwner = AttachedFileParameterValue(Form, ItemNumber, "PathToOwnerData");
	If Not ValueIsFilled(AttachedFilesOwner) Then
		
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Action", "CommandExecution");
		HandlerParameters.Insert("Form", Form);
		HandlerParameters.Insert("Command", Command);
		HandlerParameters.Insert("ItemNumber", ItemNumber);
		
		AskQuestionAboutOwnerRecord(HandlerParameters);
		
	Else
		AttachmentsControlCommandCompletion(Form, Command, AttachedFilesOwner);
	EndIf;
	
EndProcedure

// Handler for clicking on the preview field.
//
// Parameters:
//  Form                - ClientApplicationForm -  form of the file owner.
//  Item              - FormField -  preview field.
//  StandardProcessing - Boolean -  standard event parameter for form fields.
//  View             - Boolean - 
//                       
//                       
//
Procedure PreviewFieldClick(Form, Item, StandardProcessing, View = False) Export
	
	StandardProcessing = False;
	If Form.ReadOnly Or Item.ReadOnly Then
		Return;
	EndIf;
	
	ItemNumber = Number(StrReplace(Item.Name, "AttachedFilePictureField", ""));
	OneFileOnly = Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].OneFileOnly;
	AttachedFilesOwner = AttachedFileParameterValue(Form, Number(ItemNumber), "PathToOwnerData");
	
	If Not ValueIsFilled(AttachedFilesOwner) Then
		
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Action", "PreviewClick");
		HandlerParameters.Insert("Form", Form);
		HandlerParameters.Insert("Item", Item);
		HandlerParameters.Insert("View", View);
		HandlerParameters.Insert("ItemNumber", ItemNumber);
		HandlerParameters.Insert("OneFileOnly", OneFileOnly);
		
		AskQuestionAboutOwnerRecord(HandlerParameters);
		
	Else
		PreviewFieldClickCompletion(Form, AttachedFilesOwner, Item, StandardProcessing,
			View, OneFileOnly);
	EndIf;
	
EndProcedure

// Drag handler for the preview field.
//
// Parameters:
//  Form                   - ClientApplicationForm -  form of the file owner.
//  Item                 - FormField -  preview field.
//  DragParameters - DragParameters -  the standard parameter for the Drag 
//                          form field event.
//  StandardProcessing    - Boolean -  the standard parameter for the Drag form field event.
//
Procedure PreviewFieldDrag(Form, Item, DragParameters, StandardProcessing) Export
	
	StandardProcessing = False;
	If Form.ReadOnly Or Item.ReadOnly Then
		Return;
	EndIf;
	
	ItemNumber = Number(StrReplace(Item.Name, "AttachedFilePictureField", ""));
	OneFileOnly = Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].OneFileOnly;
	AttachedFilesOwner = AttachedFileParameterValue(Form, Number(ItemNumber), "PathToOwnerData");
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("Action", "Drag");
	HandlerParameters.Insert("Form", Form);
	HandlerParameters.Insert("Item", Item);
	HandlerParameters.Insert("ItemNumber", ItemNumber);
	HandlerParameters.Insert("OneFileOnly", OneFileOnly);
	HandlerParameters.Insert("DragParameters", DragParameters);
	HandlerParameters.Insert("AttachedFilesOwner", AttachedFilesOwner);
	
	If Not ValueIsFilled(AttachedFilesOwner) Then
		AskQuestionAboutOwnerRecord(HandlerParameters);
	Else
		InstallationNotification = New NotifyDescription("PreviewFieldDragCompletion", ThisObject, HandlerParameters);
		FileSystemClient.AttachFileOperationsExtension(InstallationNotification, , False);
	EndIf;
	
EndProcedure

// Handler for checking drag and drop on the preview field.
//
// Parameters:
//  Form                   - ClientApplicationForm -  form of the file owner.
//  Item                 - FormField -  preview field.
//  DragParameters - DragParameters -  standard event parameter Check
//                          drag-and-drop form fields.
//  StandardProcessing    - Boolean -  the standard parameter of the event Checking form field dragging.
//
Procedure PreviewFieldCheckDragging(Form, Item, DragParameters, StandardProcessing) Export
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
// 
// Parameters:
//  Form     - ClientApplicationForm -  form for the directory of attached files.
//
Procedure GoToFileForm(Val Form) Export
	
	AttachedFile = Form.Key;
	
	Form.Close();
	
	For Each ApplicationWindow In GetWindows() Do
		
		Content = ApplicationWindow.GetContent();
		
		If Content = Undefined Then
			Continue;
		EndIf;
		
		If Content.FormName = "DataProcessor.FilesOperations.Form.AttachedFile" Then
			If Content.Parameters.Property("AttachedFile")
				And Content.Parameters.AttachedFile = AttachedFile Then
				ApplicationWindow.Activate();
				Return;
			EndIf;
		EndIf;
		
	EndDo;
	
	OpenFileForm(AttachedFile);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// The procedure is designed to print the file by the appropriate application
//
// Parameters:
//  FileData          - See FilesOperations.FileData.
//  FileToOpenName - String
//
Procedure PrintFileByApplication(FileData, FileToOpenName)
	
#If MobileClient Then
	ShowMessageBox(, NStr("en = 'You can print this type of files only from an application for Windows or Linux.';"));
	Return;
#Else
	ExtensionsExceptions = 
		" m3u, m4a, mid, midi, mp2, mp3, mpa, rmi, wav, wma, 
		| 3g2, 3gp, 3gp2, 3gpp, asf, asx, avi, m1v, m2t, m2ts, m2v, m4v, mkv, mov, mp2v, mp4, mp4v, mpe, mpeg, mts, vob, wm, wmv, wmx, wvx,
		| 7z, zip, rar, arc, arh, arj, ark, p7m, pak, package, 
		| app, com, exe, jar, dll, res, iso, isz, mdf, mds,
		| cf, dt, epf, erf";
	
	Extension = Lower(FileData.Extension);
	
	If StrFind(ExtensionsExceptions, " " + Extension + ",") > 0 Then
		ShowMessageBox(, NStr("en = 'Cannot print this type of files.';"));
		Return;
	ElsIf Extension = "grs" Then
		Schema = New GraphicalSchema;
		Schema.Read(FileToOpenName);
		Schema.Print();
		Return;
	EndIf;

	If CommonClient.IsWindowsClient() Then
		FileToOpenName = StrReplace(FileToOpenName, "/", "\");
	EndIf;

	Try
		PrintFromApplicationByFileName(FileToOpenName);
	Except
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot print the file. Reason:
				|%1';"), ErrorProcessing.BriefErrorDescription(ErrorInfo()))); 
	EndTry;
#EndIf

EndProcedure

// The procedure to print the File
//
// Parameters:
//  ResultHandler - NotifyDescription
//  ExecutionParameters  - Structure:
//        * FileNumber               - Number -  the number of the current file.
//        * FileData              - Structure
//        * UUID  - UUID
//
Procedure PrintFilesExecution(ResultHandler, ExecutionParameters) Export
	
	UserInterruptProcessing();
	
	If ExecutionParameters.FileNumber >= ExecutionParameters.FilesData.Count() Then
		Return;
	EndIf;
	ExecutionParameters.FileData = FilesOperationsInternalServerCall.FileDataToPrint(
		ExecutionParameters.FilesData[ExecutionParameters.FileNumber],
		ExecutionParameters.UUID);
		
#If WebClient Then
	If ExecutionParameters.FileData.Extension <> "mxl" Then
		Text = NStr("en = 'Save the file to your computer and then print it from an application that can open this file.';");
		ShowMessageBox(, Text);
		Return;
	EndIf;
#EndIf
	
	If ExecutionParameters.FileData.Property("SpreadsheetDocument") Then
		ExecutionParameters.FileData.SpreadsheetDocument.Print();
		// 
		ExecutionParameters.FileNumber = ExecutionParameters.FileNumber + 1;
		Handler = New NotifyDescription("PrintFilesExecution", ThisObject, ExecutionParameters);
		ExecuteNotifyProcessing(Handler);
		Return
	EndIf;
	
	If FilesOperationsInternalClient.FileSystemExtensionAttached1() Then
		Handler = New NotifyDescription("PrintFileAfterReceiveVersionInWorkingDirectory", ThisObject, 
			ExecutionParameters);
		FilesOperationsInternalClient.GetVersionFileToWorkingDirectory(Handler, ExecutionParameters.FileData,
			"", ExecutionParameters.UUID);
	Else
		ExecutionParameters.FileData = FilesOperationsInternalServerCall.FileDataToOpen(
			ExecutionParameters.FilesData[ExecutionParameters.FileNumber], Undefined);
		OpenFile(ExecutionParameters.FileData, False);
	EndIf;
EndProcedure

// 
//
// Parameters:
//  Result - Structure:
//    * FileReceived - Boolean
//    * FullFileName - String
//  ExecutionParameters  - Structure:
//    * FileNumber               - Number -  the number of the current file.
//    * FileData              - Structure
//    * UUID  - UUID
//
Procedure PrintFileAfterReceiveVersionInWorkingDirectory(Result, ExecutionParameters) Export

	If Result.FileReceived Then
		
		If ExecutionParameters.FileNumber >= ExecutionParameters.FilesData.Count() Then
			Return;
		EndIf;
	
		PrintFileByApplication(ExecutionParameters.FileData, Result.FullFileName);
		
	EndIf;

	// 
	ExecutionParameters.FileNumber = ExecutionParameters.FileNumber + 1;
	Handler = New NotifyDescription("PrintFilesExecution", ThisObject, ExecutionParameters);
	ExecuteNotifyProcessing(Handler);
	
EndProcedure

// Prints the file by an external application.
//
// Parameters:
//  FileToOpenName - String
//
Procedure PrintFromApplicationByFileName(FileToOpenName)
	
	FileSystemClient.PrintFromApplicationByFileName(FileToOpenName);

EndProcedure

Procedure OpenScanSettingFormCompletion(InitializationCheckResult, ExecutionParameters) Export
	
	AddInInstalled = InitializationCheckResult.Attached;
	
	If Not AddInInstalled Then
		If ValueIsFilled(InitializationCheckResult.ErrorDescription) Then
			ShowMessageBox(, InitializationCheckResult.ErrorDescription);
		EndIf;
		Return;
	EndIf;
	
	ContinueNotification = New NotifyDescription("OpenScanSetupFormAfterLogEnabled", 
		ThisObject, AddInInstalled);
	
	FilesOperationsInternalClient.EnableScanLog(InitializationCheckResult.Attachable_Module, 
		ContinueNotification);
EndProcedure

Procedure OpenScanSetupFormAfterLogEnabled(Result, AddInInstalled) Export
	ClientID = FilesOperationsInternalClient.ClientID();
	
	FormParameters = New Structure;
	FormParameters.Insert("AddInInstalled", AddInInstalled);
	FormParameters.Insert("ClientID",  ClientID);
	
	OpenForm("DataProcessor.Scanning.Form.ScanningSettings", FormParameters);
	
EndProcedure

Procedure PromptForWriteRequiredAfterCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		Return;
	EndIf;
	
EndProcedure

Function ImagesForMerging(ObjectsForMerging, UseImageMagick = False)
	
	ImagesForMerging = New Array;
	
	If UseImageMagick Then
		For Each ObjectForMerging In ObjectsForMerging Do
			FileName = Undefined;
			#If Not WebClient And Not MobileClient Then
				// 
				TempFileName = GetTempFileName();
				// 
			#Else
				TempFileName = Undefined;			
			#EndIf
			
			If ObjectForMerging = Undefined Then
				Continue;
			ElsIf TypeOf(ObjectForMerging) = Type("BinaryData") Then
				FileName = TempFileName;
				ObjectForMerging.Write(FileName);
			ElsIf TypeOf(ObjectForMerging) = Type("String") Then
				If IsTempStorageURL(ObjectForMerging) Then
					AddressContent = GetFromTempStorage(ObjectForMerging);
					If TypeOf(AddressContent) = Type("BinaryData") Then
						FileName = TempFileName;
						AddressContent.Write(FileName);
					ElsIf TypeOf(AddressContent) = Type("Picture") Then
						PictureData = AddressContent.GetBinaryData();
						FileName = TempFileName;
						PictureData.Write(FileName);
					EndIf;
				Else
					FileName = ObjectForMerging;
				EndIf;
			ElsIf FilesOperationsInternalServerCall.IsFilesOperationsItem(ObjectForMerging) Then
				FileData = FilesOperationsInternalServerCall.FileData(ObjectForMerging);
				AddressContent = GetFromTempStorage(FileData.RefToBinaryFileData);
				FileName = TempFileName;
				AddressContent.Write(FileName);
			EndIf;
			
			If FileName <> Undefined Then
				ImagesForMerging.Add(FileName);
			EndIf;
			
		EndDo;
	Else
		For Each ObjectForMerging In ObjectsForMerging Do
			Image = Undefined;
			If ObjectForMerging = Undefined Then
				Continue;
			ElsIf TypeOf(ObjectForMerging) = Type("BinaryData") Then
				Image = New Picture(ObjectForMerging);
			ElsIf TypeOf(ObjectForMerging) = Type("String") Then
				If IsTempStorageURL(ObjectForMerging) Then
					AddressContent = GetFromTempStorage(ObjectForMerging);
					If TypeOf(AddressContent) = Type("BinaryData") Then
						Image = New Picture(AddressContent);
					ElsIf TypeOf(AddressContent) = Type("Picture") Then
						Image = AddressContent;
					EndIf;
				Else
					Image = New Picture(ObjectForMerging);
				EndIf;
			ElsIf FilesOperationsInternalServerCall.IsFilesOperationsItem(ObjectForMerging) Then
				FileData = FilesOperationsInternalServerCall.FileData(ObjectForMerging);
				AddressContent = GetFromTempStorage(FileData.RefToBinaryFileData);
				Image = New Picture(AddressContent);
			EndIf;
			
			If Image <> Undefined Then
				ImagesForMerging.Add(Image);
			EndIf;
			
		EndDo;
	EndIf;
	
	Return ImagesForMerging;
EndFunction

Function ResultOfMergeIntoMultipageDocument()
	Result = New Structure;
	Result.Insert("ResultFileName", "");
	Result.Insert("BinaryData");
	Result.Insert("ErrorDescription", "");
	Result.Insert("Success", False);	
	Return Result;
EndFunction

Procedure MergeIntoMultipageFileAfterCommandExecuted(ImageMagickResult, Context) Export

	ImageFiles = Context.ImageFiles;
	ResultType = Context.ResultType;
	ResultFileName = Context.ResultFileName;
	NotificationOfReturn = Context.NotificationOfReturn;
	
	Result = ResultOfMergeIntoMultipageDocument();

	If ImageMagickResult.ReturnCode <> 0 Then
		Result.ErrorDescription = ImageMagickResult.ErrorDescription;
		ExecuteNotifyProcessing(NotificationOfReturn, Result);
		Return;
	EndIf;
	
	For Each ImageFile In ImageFiles Do
		DeleteFiles(ImageFile);
	EndDo;
	
	If ResultType = ConversionResultTypeFileName() Then
		Result.ResultFileName = ResultFileName;
	ElsIf ResultType = ConversionResultTypeBinaryData() Then
		PDFData = New BinaryData(ResultFileName);
		DeleteFiles(ResultFileName);
		Result.BinaryData =  PDFData;
	EndIf;
	Result.Success = True;
	
	ExecuteNotifyProcessing(NotificationOfReturn, Result);
		
EndProcedure

Procedure ScanCommandAvailableCompletion(InitializationCheckResult, NotificationOfResult) Export

	InitializationCheckResult.Insert("NotificationOfResult", NotificationOfResult);
	
	CompletionNotification = New NotifyDescription("ScanCommandAvailableAfterLogEnabled", ThisObject, 
		InitializationCheckResult);
	If InitializationCheckResult.Attached Then
		FilesOperationsInternalClient.EnableScanLog(InitializationCheckResult.Attachable_Module, 
			CompletionNotification);
	Else
		ExecuteNotifyProcessing(CompletionNotification);
	EndIf;
	
EndProcedure

Procedure ScanCommandAvailableAfterLogEnabled(Result, Context) Export
	
	ScanCommandAvailable = Context.Attached 
		And FilesOperationsInternalClient.IsDevicePresent(Undefined, Context.Attachable_Module, False);

	ExecuteNotifyProcessing(Context.NotificationOfResult, ScanCommandAvailable);
	
EndProcedure

Procedure AfterCheckIfConversionAppInstalled(RunResult, Context) Export
	If StrFind(RunResult.OutputStream, "ImageMagick") = 0  Then
		UserScanSettings = Context.UserScanSettings;
		PathToConverterApplication = UserScanSettings.PathToConverterApplication;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Specified path to the %1 application is incorrect.
		|Multipage documents are merged using 1C:Enterprise tools.
		|Specified path: %2';"), "ImageMagick", PathToConverterApplication); 
		EventLogClient.AddMessageForEventLog(EventLogEvent(),
			"Warning", ErrorText,, True);
		Context.GraphicDocumentConversionParameters.UseImageMagick = False;
	EndIf;
	MergeIntoMultipageFileFollowUp(Context);
EndProcedure
	
Procedure MergeIntoMultipageFileFollowUp(Context)
	NotificationOfReturn = Context.NotificationOfReturn;
	ObjectsForMerging = Context.ObjectsForMerging;
	GraphicDocumentConversionParameters = Context.GraphicDocumentConversionParameters;
	UserScanSettings = Context.UserScanSettings;
	
	UseImageMagick = GraphicDocumentConversionParameters.UseImageMagick; 
	PathToConverterApplication = UserScanSettings.PathToConverterApplication;
	
	Result = ResultOfMergeIntoMultipageDocument();
	
	#If Not WebClient And Not MobileClient Then
	ResultFileName = GraphicDocumentConversionParameters.ResultFileName;
	
	If Not ValueIsFilled(ResultFileName) Then
		// 
		ResultFileName = GetTempFileName(GraphicDocumentConversionParameters.ResultFormat);
		// 
	EndIf;
	
	If Not UseImageMagick Then
		ImagesForMerging = ImagesForMerging(ObjectsForMerging);
		If GraphicDocumentConversionParameters.ResultFormat = "pdf" Then
			SpreadsheetDocument = FilesOperationsInternalServerCall.NewSpreadsheetAtServer(ImagesForMerging.Count());
			Stream = New MemoryStream();
			SpreadsheetDocument.Write(Stream, SpreadsheetDocumentFileType.PDF);
			
			PDFDocument = New PDFDocument();
			PDFDocument.Read(Stream);
			For ObjectIndex = 0 To ImagesForMerging.UBound() Do
				LongDesc = New PDFRepresentationObjectDescription;
				LongDesc.Name           = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Image #%1';"), ObjectIndex);
				Image = ImagesForMerging[ObjectIndex];
				Width = Image.Width();
				Height = Image.Height();
				RatioA4 = 210/297;
				
				If RatioA4*Height > Width Then
					LongDesc.Height        = 269; //297
					LongDesc.Width        = LongDesc.Height * Width/Height; //210
				Else
					LongDesc.Width        = 190; //210
					LongDesc.Height        = LongDesc.Width * Height/Width; //297 
				EndIf;
				LongDesc.Left          = 0;
				LongDesc.Top          = 0;
				LongDesc.PageNumber = ObjectIndex+1;
				LongDesc.Object        = Image;
				PDFDocument.AddRepresentationObject(LongDesc);
			EndDo;
			PDFDocument.Write(Stream);
			ResultData = Stream.CloseAndGetBinaryData();
		ElsIf GraphicDocumentConversionParameters.ResultFormat = "tif" Then
			TIFImage = FilesOperationsInternalServerCall.MergeImagesIntoTIFFile(ImagesForMerging);
			ResultData = TIFImage.GetBinaryData();
		EndIf;
		
		If GraphicDocumentConversionParameters.ResultType = ConversionResultTypeFileName() Then
			ResultData.Write(ResultFileName);
			Result.ResultFileName = ResultFileName;
			Result.Success = True;
		ElsIf GraphicDocumentConversionParameters.ResultType = ConversionResultTypeBinaryData() Then
			Result.BinaryData = ResultData;
			Result.Success = True;
		EndIf;
		
		ExecuteNotifyProcessing(NotificationOfReturn, Result);
	Else
		ImageFiles = ImagesForMerging(ObjectsForMerging, True);
		
		ImageFilesAsString = """" + StrConcat(ImageFiles, """" + " " + """") + """";
		SystemCommands = """" + PathToConverterApplication + """" +" "+ ImageFilesAsString + " " +""""+ ResultFileName+"""";
		
		Context = New Structure;
		Context.Insert("ImageFiles", ImageFiles);
		Context.Insert("ResultType", GraphicDocumentConversionParameters.ResultType);
		Context.Insert("ResultFileName", ResultFileName);
		Context.Insert("NotificationOfReturn", NotificationOfReturn);
		
		ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
		ApplicationStartupParameters.WaitForCompletion = True;
		ApplicationStartupParameters.Notification = New NotifyDescription("MergeIntoMultipageFileAfterCommandExecuted", 
			ThisObject, Context);
		FileSystemClient.StartApplication(SystemCommands, ApplicationStartupParameters);
				
	EndIf;
	
	#EndIf
EndProcedure

#Region AttachedFilesManagement

Function ManagementCommandParameters(Form)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("Form",              Form);
	ExecutionParameters.Insert("Action",           "ImportFile_");
	ExecutionParameters.Insert("ItemNumber",      "");
	ExecutionParameters.Insert("FormIdentifier", Form.UUID);
	Return ExecutionParameters;
	
EndFunction

Function AttachedFileParameterValue(Form, Val ItemNumber, ParameterName)
	
	If TypeOf(ItemNumber) = Type("String") Then
		ItemNumber = Number(ItemNumber);
	EndIf;
	
	DataPath = Form.FilesOperationsParameters.FormElementsDetails[ItemNumber][ParameterName];
	DataPathParts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DataPath, ".", True, True);
	If DataPathParts.Count() > 0 Then
		
		ParameterValue = Form[DataPathParts[0]];
		For IndexOf = 1 To DataPathParts.UBound() Do
			ParameterValue = ParameterValue[DataPathParts[IndexOf]];
		EndDo;
		
		Return ParameterValue;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure AskQuestionAboutOwnerRecord(CompletionHandlerParameters)
	
	QueryText = NStr("en = 'You have unsaved data.
		|You can open the attachments after saving the data.
		|Do you want to save the data?';");
	HandlerNotifications = New NotifyDescription("ShowNewOwnerRecordQuestion", ThisObject, CompletionHandlerParameters);
	
	ShowQueryBox(HandlerNotifications, QueryText, QuestionDialogMode.OKCancel);
	
EndProcedure

// Parameters:
//   Response - DialogReturnCode
//         - Undefined
//   AdditionalParameters - Structure
//
Procedure ShowNewOwnerRecordQuestion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.OK Then
		
		Form = AdditionalParameters.Form; // ManagedFormExtensionForCatalogs
		If Not Form.Write() Then
			Return;
		EndIf;
		
		StandardProcessing = False;
		AttachedFilesOwner = AttachedFileParameterValue(Form, 
			AdditionalParameters.ItemNumber, "PathToOwnerData");
		
		If Not ValueIsFilled(AttachedFilesOwner) Then
			Return;
		EndIf;
		
		If AdditionalParameters.Action = "CommandExecution" Then
			AttachmentsControlCommandCompletion(Form, AdditionalParameters.Command, AttachedFilesOwner);
		ElsIf AdditionalParameters.Action = "PreviewClick" Then
			PreviewFieldClickCompletion(Form, AttachedFilesOwner,
				AdditionalParameters.Item, StandardProcessing,
				AdditionalParameters.View, AdditionalParameters.OneFileOnly);
		ElsIf AdditionalParameters.Action = "Drag" Then
			InstallationNotification = New NotifyDescription("PreviewFieldDragCompletion", ThisObject, AdditionalParameters);
			FileSystemClient.AttachFileOperationsExtension(InstallationNotification, , False);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure AttachmentsControlCommandCompletion(Form, Command, AttachedFilesOwner)
	
	CommandName = StrReplace(Command.Name, FilesOperationsClientServer.CommandsPrefix(), "");
	ItemNumber = "";

	Position = StrFind(CommandName, "_", SearchDirection.FromEnd);
	If Position > 0 Then 
		ItemNumber = StrReplace(Mid(CommandName, Position + 1), FilesOperationsClientServer.OneFileOnlyText(), "");
		CommandName    = Left(CommandName, Position - 1);
	EndIf;
	
	ExecutionParameters = ManagementCommandParameters(Form);
	ExecutionParameters.ItemNumber = ItemNumber;
	
	CompletionHandler = New NotifyDescription("CommandWithNotificationExecutionCompletion",
		ThisObject, ExecutionParameters);
		
	NumberType = New TypeDescription("Number");
	ItemNumber = NumberType.AdjustValue(ExecutionParameters.ItemNumber);
	FileAddingOptions = New Structure;
	FileAddingOptions.Insert("MaximumSize",
		Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].MaximumSize);
	FileAddingOptions.Insert("SelectionDialogFilter",
		Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].SelectionDialogFilter);
	FileAddingOptions.Insert("NotOpenCard", True);
	
	ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient = Undefined;
	UseEDIToStoreObjectFiles =
		FilesOperationsInternalClient.Is1CDocumentManagementUsedForFileStorage(
			AttachedFilesOwner,
			Form,
			Command,
			ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient);
	
	If StrStartsWith(CommandName, "OpenList") Then
		
		If UseEDIToStoreObjectFiles Then
			
			// IntegrationWith1CDocumentManagementSubsystem
			FilesOperationsInternalClient.OpenFormAttachedFiles1CDocumentManagement(
				AttachedFilesOwner,
				Form);
			// End IntegrationWith1CDocumentManagementSubsystem
			
		Else
			
			FormParameters = New Structure();
			FormParameters.Insert("FileOwner", AttachedFilesOwner);
			FormParameters.Insert("ShouldHideOwner", True);
			FormParameters.Insert("CurrentRow", Form.UUID);
			OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles", FormParameters);
			
		EndIf;
		
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.ImportFileCommandName()) Then
		
		If UseEDIToStoreObjectFiles Then
			
			// IntegrationWith1CDocumentManagementSubsystem
			ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient.AddFileFromDiskoISObject(
				AttachedFilesOwner,
				Form.UUID);
			// End IntegrationWith1CDocumentManagementSubsystem
			
		Else
			
			CommandName = StrReplace(CommandName, FilesOperationsClientServer.ImportFileCommandName(), "");
			OwnerFiles = FilesOperationsInternalServerCall.AttachedFilesCount(AttachedFilesOwner, True);
			If StrStartsWith(CommandName, "OneFileOnly")
				And OwnerFiles.Count > 0 Then
				
				FileData = OwnerFiles.FileData; // See FilesOperations.FileData
				
				ExecutionParameters.Action = "ReplaceFile";
				ExecutionParameters.Insert("PicturesFile", FileData.Ref);
				
				FilesOperationsInternalClient.UpdateFromFileOnHardDriveWithNotification(CompletionHandler,
					FileData, Form.UUID, FileAddingOptions);
				
			Else
				AppendFile(CompletionHandler, AttachedFilesOwner, Form, 2, FileAddingOptions);
			EndIf;
			
		EndIf;
		
	ElsIf StrStartsWith(CommandName, "AttachedFileTitle") Then
		
		Location = AttachedFileParameterValue(Form, ExecutionParameters.ItemNumber, "PathToPlacementAttribute");
		If Not ValueIsFilled(Location) Then
			AppendFile(CompletionHandler, AttachedFilesOwner, Form, 2, FileAddingOptions);
		Else
			ExecutionParameters.Action = "ViewFile1";
			ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
		EndIf;
		
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.CreateFromTemplateCommandName()) Then
		AppendFile(CompletionHandler, AttachedFilesOwner, Form, 1, FileAddingOptions);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.ScanCommandName()) Then
		AppendFile(CompletionHandler, AttachedFilesOwner, Form, 3, FileAddingOptions);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.SelectFileCommandName()) Then
		ExecutionParameters.Action = "SelectFile";
		OpenFileChoiceForm(AttachedFilesOwner, Undefined, False, CompletionHandler);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.ViewFileCommandName()) Then
		ExecutionParameters.Action = "ViewFile1";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.ClearCommandName()) Then
		UpdateAttachedFileStorageAttribute(Form, ExecutionParameters.ItemNumber, Undefined);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.OpenFormCommandName()) Then
		ExecutionParameters.Action = "OpenForm";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.EditFileCommandName()) Then
		ExecutionParameters.Action = "EditFile";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.PutFileCommandName()) Then
		ExecutionParameters.Action = "PutFile";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.CancelEditCommandName()) Then
		ExecutionParameters.Action = "CancelEdit";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	EndIf;
	
EndProcedure

Procedure PreviewFieldClickCompletion(Form, AttachedFilesOwner, Item, StandardProcessing,
	View = False, OneFileOnly = False)
	
	StandardProcessing = False;
	ItemNumber = StrReplace(Item.Name, "AttachedFilePictureField", "");
	ExecutionParameters = ManagementCommandParameters(Form);
	ExecutionParameters.ItemNumber = ItemNumber;
	
	NumberType = New TypeDescription("Number");
	ItemNumber = NumberType.AdjustValue(ExecutionParameters.ItemNumber);
	FileOperationsParameters = Form.FilesOperationsParameters.FormElementsDetails[ItemNumber];
	FileAddingOptions = New Structure;
	FileAddingOptions.Insert("MaximumSize", FileOperationsParameters.MaximumSize);
	FileAddingOptions.Insert("SelectionDialogFilter", FileOperationsParameters.SelectionDialogFilter);


	FileAddingOptions.Insert("NotOpenCard", True);
	PlacementAttribute = Undefined;
	If FileOperationsParameters.Property("PathToPictureData") And ValueIsFilled(FileOperationsParameters.PathToPlacementAttribute) Then
		PathToPlacementAttribute = FileOperationsParameters.PathToPlacementAttribute;
		PathElements = StrSplit(PathToPlacementAttribute, ".", False);
		PlacementAttribute = PathElements[PathElements.UBound()];
	EndIf;
	
	ImageAddingOptions = FilesOperationsInternalServerCall.ImageAddingOptions(AttachedFilesOwner, PlacementAttribute);
	If View
		Or (Not ImageAddingOptions.InsertRight1 And Not ImageAddingOptions.EditRight) Then
		
		ExecutionParameters.Action = "ViewFile1";
		ExecuteActionWithFile(ExecutionParameters, Undefined);

	Else
		
		CompletionHandler = New NotifyDescription("CommandWithNotificationExecutionCompletion",
			ThisObject, ExecutionParameters);
		
		If OneFileOnly Then
			
			OwnerFiles = ImageAddingOptions.OwnerFiles;
			If OwnerFiles.FilesCount > 0 Then
				
				FileData = OwnerFiles.FileData; // See FilesOperations.FileData
				ExecutionParameters.Action = "ReplaceFile";
				ExecutionParameters.Insert("PicturesFile", FileData.Ref);
				
				FilesOperationsInternalClient.UpdateFromFileOnHardDriveWithNotification(CompletionHandler, FileData,
					Form.UUID, FileAddingOptions);
				
			Else
				AppendFile(CompletionHandler, AttachedFilesOwner, Form, 2, FileAddingOptions);
			EndIf;
			
		Else
			AppendFile(CompletionHandler, AttachedFilesOwner, Form, 2, FileAddingOptions);
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//   ExtensionInstalled - Boolean
//   AdditionalParameters - Structure:
//     * Item - FormField
//
Procedure PreviewFieldDragCompletion(ExtensionInstalled, AdditionalParameters) Export
	
	If Not ExtensionInstalled Then
		Return;
	EndIf;
	
	Form = AdditionalParameters.Form;
	Item = AdditionalParameters.Item;
	DragParameters = AdditionalParameters.DragParameters;
	AttachedFilesOwner = AdditionalParameters.AttachedFilesOwner;
	
	ExecutionParameters = ManagementCommandParameters(Form);
	ExecutionParameters.ItemNumber = StrReplace(Item.Name, "AttachedFilePictureField", "");
	
	NumberType = New TypeDescription("Number");
	ItemNumber = NumberType.AdjustValue(ExecutionParameters.ItemNumber);
	If TypeOf(DragParameters.Value) = Type("FileRef")
		And FilesOperationsInternalServerCall.HasAccessRight("Create", AttachedFilesOwner) Then //@Access-right-2
		
		File = DragParameters.Value.File;
		If File = Undefined Then
			Return;
		EndIf;
		
		ExecutionParameters.Action = "CompleteDragging";
		CompletionHandler = New NotifyDescription("CommandWithNotificationExecutionCompletion",
			ThisObject, ExecutionParameters);
		
		AddingOptions = New Structure;
		AddingOptions.Insert("ResultHandler", CompletionHandler);
		AddingOptions.Insert("FullFileName", File.FullName);
		AddingOptions.Insert("FileOwner", AttachedFilesOwner);
		AddingOptions.Insert("OwnerForm", Form);
		AddingOptions.Insert("NotOpenCardAfterCreateFromFile", True);
		AddingOptions.Insert("NameOfFileToCreate", File.BaseName);
		AddingOptions.Insert("MaximumSize",
			Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].MaximumSize);
		AddingOptions.Insert("SelectionDialogFilter",
			Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].SelectionDialogFilter);
			
		FilesOperationsInternalClient.AddFormFileSystemWithExtension(AddingOptions);
		
	EndIf;
	
EndProcedure

Procedure UpdateAttachedFileStorageAttribute(Form, Val ItemNumber, File)
	
	If TypeOf(ItemNumber) = Type("String") Then
		ItemNumber = Number(ItemNumber);
	EndIf;
	
	DataPath = Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].PathToPlacementAttribute;
	DataPathParts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DataPath, ".", True, True);
	
	If DataPathParts.Count() > 0 Then
		
		AttributeLocationLevel = DataPathParts.Count();
		If AttributeLocationLevel = 1 Then
			Form[DataPathParts[0]] = File;
		ElsIf AttributeLocationLevel = 2 Then
			Form[DataPathParts[0]][DataPathParts[1]] = File;
		Else
			Return;
		EndIf;
		
		UpdatePreviewArea(Form, ItemNumber, File);
		
		Form.Modified = True;
		
	EndIf;
	
EndProcedure

Procedure UpdatePreviewArea(Form, ItemNumber, File)
	
	If TypeOf(ItemNumber) = Type("String") Then
		ItemNumAsNumber = Number(ItemNumber);
		ItemNumAsString = ItemNumber;
	Else
		ItemNumAsNumber = ItemNumber;
		ItemNumAsString = Format(ItemNumber, "NG=;");
	EndIf;
	
	AttributeName = Form.FilesOperationsParameters.FormElementsDetails[ItemNumAsNumber].PathToPictureData;
	PictureItem = Form.Items.Find("AttachedFilePictureField" + ItemNumAsString);
	TitleItem = Form.Items.Find("AttachedFileTitle" + ItemNumAsString);
	
	DataParameters = FilesOperationsClientServer.FileDataParameters();
	DataParameters.RaiseException1 = False;
	DataParameters.FormIdentifier = Form.UUID;
	
	UpdateData = FilesOperationsInternalServerCall.ImageFieldUpdateData(
		File, DataParameters);
		
	FileData = UpdateData.FileData;
	If PictureItem <> Undefined Then
		
		NonselectedPictureText = Form.FilesOperationsParameters.FormElementsDetails[ItemNumAsNumber].NonselectedPictureText;
		If FileData = Undefined Then
			Form[AttributeName] = Undefined;
			PictureItem.NonselectedPictureText = NonselectedPictureText;
		ElsIf UpdateData.FileCorrupted Then
			Form[AttributeName] = Undefined;
			PictureItem.NonselectedPictureText = NStr("en = 'No image';");
		Else
			Form[AttributeName] = FileData.RefToBinaryFileData;
			PictureItem.NonselectedPictureText = NonselectedPictureText;
		EndIf;
		
		PictureItem.TextColor = UpdateData.TextColor;
		
	EndIf;
	
	If TitleItem <> Undefined Then
		
		If FileData = Undefined Then
			TitleItem.Title = NStr("en = 'upload';");
			TitleItem.ToolTipRepresentation = ToolTipRepresentation.None;
		Else
			TitleItem.Title = FileData.FileName;
			TitleItem.ToolTipRepresentation = ToolTipRepresentation.Auto;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ExecuteActionWithFile(ExecutionParameters, CompletionHandler)
	
	Form = ExecutionParameters.Form;
	Location = AttachedFileParameterValue(Form, Number(ExecutionParameters.ItemNumber), "PathToPlacementAttribute");
	If ValueIsFilled(Location) Then
		
		If ExecutionParameters.Action = "ViewFile1" Then
			FileData = FilesOperationsInternalServerCall.FileDataToOpen(Location, Undefined, Form.UUID);
			OpenFile(FileData);
		ElsIf ExecutionParameters.Action = "OpenForm" Then
			OpenFileForm(Location);
		ElsIf ExecutionParameters.Action = "EditFile" Then
			FilesOperationsInternalClient.EditWithNotification(CompletionHandler, Location);
		ElsIf ExecutionParameters.Action = "PutFile" Then
			
			FileUpdateParameters = FilesOperationsInternalClient.FileUpdateParameters(CompletionHandler,
				Location, Form.UUID);
			FileUpdateParameters.Insert("CreateNewVersion", False);
			FilesOperationsInternalClient.EndEditAndNotify(FileUpdateParameters);
			
		ElsIf ExecutionParameters.Action = "CancelEdit" Then
			
			FilesArray = New Array;
			FilesArray.Add(Location);
			
			FilesOperationsInternalServerCall.UnlockFiles(FilesArray);
			CommandWithNotificationExecutionCompletion(Undefined, ExecutionParameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CommandWithNotificationExecutionCompletion(Result, AdditionalParameters) Export
	
	If AdditionalParameters.Action = "ReplaceFile" Then
		
		UpdatePreviewArea(AdditionalParameters.Form, AdditionalParameters.ItemNumber,
			AdditionalParameters.PicturesFile);
		
	ElsIf (AdditionalParameters.Action = "ImportFile_"
		Or AdditionalParameters.Action = "CompleteDragging")
		And Result <> Undefined
		And Result.FileAdded Then
		
		UpdateAttachedFileStorageAttribute(AdditionalParameters.Form, AdditionalParameters.ItemNumber,
			Result.FileRef);
		
	ElsIf AdditionalParameters.Action = "SelectFile"
		And Result <> Undefined Then
		
		UpdateAttachedFileStorageAttribute(AdditionalParameters.Form, AdditionalParameters.ItemNumber,
			Result);
		
	ElsIf AdditionalParameters.Action = "EditFile" Then
		ChangeButtonsAvailability(AdditionalParameters.Form, AdditionalParameters.ItemNumber, True);
	ElsIf AdditionalParameters.Action = "PutFile"
		Or AdditionalParameters.Action = "CancelEdit" Then
		ChangeButtonsAvailability(AdditionalParameters.Form, AdditionalParameters.ItemNumber, False);
	EndIf;
	
EndProcedure

// Parameters:
//
// Form - ClientApplicationForm
//
Procedure ChangeButtonsAvailability(Form, ItemNumber, EditStart)
	
	CommandPrefix                   = FilesOperationsClientServer.CommandsPrefix();
	PutFileCommandName          = FilesOperationsClientServer.PutFileCommandName();
	CancelEditCommandName = FilesOperationsClientServer.CancelEditCommandName();
	EditFileCommandName      = FilesOperationsClientServer.EditFileCommandName();
	
	Buttons = New ValueList;
	Buttons.Add(CommandPrefix + PutFileCommandName + ItemNumber,, EditStart);
	Buttons.Add(CommandPrefix + CancelEditCommandName + ItemNumber,, EditStart);
	Buttons.Add(CommandPrefix + EditFileCommandName + ItemNumber,, Not EditStart);
	Buttons.Add(PutFileCommandName + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,, EditStart);
	Buttons.Add(CancelEditCommandName + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,, EditStart);
	Buttons.Add(EditFileCommandName + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,, Not EditStart);
	
	Items = Form.Items;
	For Each Button In Buttons Do
		
		FormButton = Items.Find(Button.Value);
		If FormButton <> Undefined Then
			FormButton.Enabled = Button.Check;
		EndIf;
		
	EndDo;
		
EndProcedure

Procedure ChangeAdditionalCommandsVisibility(Form)
	
	Try
		HasFileManagementParameters = TypeOf(Form["FilesOperationsParameters"]) = Type("FixedStructure");
	Except
		// 
		HasFileManagementParameters = False;
	EndTry;
	
	If Not HasFileManagementParameters Then
		Return;
	EndIf;
	
	CommandPrefix = FilesOperationsClientServer.CommandsPrefix();
	
	For ElementIndex = 0 To Form.FilesOperationsParameters.FormElementsDetails.UBound() Do
		
		CommandsSubmenu                 = Form.Items.Find("AddingFileSubmenu" + ElementIndex);
		CommandSelectButton          = Form.Items.Find(CommandPrefix + FilesOperationsClientServer.SelectFileCommandName() + ElementIndex);
		CommandSelectButton          = Form.Items.Find(CommandPrefix + FilesOperationsClientServer.SelectFileCommandName() + ElementIndex);
		CommandLoadButton        = Form.Items.Find(CommandPrefix + FilesOperationsClientServer.ImportFileCommandName() + ElementIndex);
		CommandScanButton      = Form.Items.Find(CommandPrefix + FilesOperationsClientServer.ScanCommandName() + ElementIndex);
		CommandCreateFromTemplateButton = Form.Items.Find(CommandPrefix + FilesOperationsClientServer.CreateFromTemplateCommandName() + ElementIndex);
		
		If CommandScanButton <> Undefined Then
			CommandScanButton.Visible = False;
			CommandScanFromContextMenuButton = Form.Items.Find(FilesOperationsClientServer.CommandsPrefix()
				+ FilesOperationsClientServer.ScanCommandName() + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ElementIndex);
			If CommandScanFromContextMenuButton <> Undefined Then
				CommandScanFromContextMenuButton.Visible = False;
			EndIf;
		EndIf;
		
		If CommandCreateFromTemplateButton <> Undefined Then
			CommandCreateFromTemplateButton.Visible = False;
			CommandCreateFromTemplateFromContextMenuButton = Form.Items.Find(FilesOperationsClientServer.CommandsPrefix() 
				+ FilesOperationsClientServer.ScanCommandName() + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ElementIndex);
			If CommandCreateFromTemplateFromContextMenuButton <> Undefined Then
				CommandCreateFromTemplateFromContextMenuButton.Visible = False;
			EndIf;
		EndIf;
		
		SubmenuVisibility = False;
		If CommandsSubmenu <> Undefined Then
			SubmenuVisibility = CommandSelectButton <> Undefined;
			CommandsSubmenu.Visible = SubmenuVisibility;
		EndIf;
		
		If CommandLoadButton <> Undefined Then
			CommandLoadButton.Visible = Not SubmenuVisibility;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure StartCheckConversionAppPresence(PathToConverterApplication, NotificationOfResult) Export
	
	SystemCommands = """" + PathToConverterApplication + """ -version";
	
	ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	ApplicationStartupParameters.GetErrorStream = True;
	ApplicationStartupParameters.GetOutputStream = True;
	
	ApplicationStartupParameters.Notification = NotificationOfResult;
	FileSystemClient.StartApplication(SystemCommands, ApplicationStartupParameters);
EndProcedure

Function EventLogEvent()
	
	Return NStr("en = 'Files';", CommonClient.DefaultLanguageCode());
	
EndFunction

#EndRegion

#EndRegion
