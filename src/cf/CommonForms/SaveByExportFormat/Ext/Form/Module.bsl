///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Common.SubsystemExists("StandardSubsystems.Print") Then
		
		Cancel = True;
		Return;
		
	EndIf;
	
	// Место сохранения по умолчанию.
	ExportOption = "SaveToFolder";
	
	If TypeOf(Parameters.ExecutionCommandDetails) = Type("Structure") Then
		
		ExecutionCommandDetails = Parameters.ExecutionCommandDetails; // Structure
		PrintObjects = ExecutionCommandDetails.PrintObjects; // Array of DocumentRef
		
		ConfigureActionOptionsAvailability(PrintObjects, Parameters);
		
		If Common.IsMobileClient() Then
			
			CommandBarLocation = FormCommandBarLabelLocation.Auto;
			Items.FormExecuteSelectedOption.Representation = ButtonRepresentation.Picture;
			
		EndIf;
		
	Else
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetSaveLocationPage();
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If ExportOption = "SaveToFolder" Then
		Settings["ExportOption"] = "SaveToFolder";
	Else
		Settings["ExportOption"] = "Join";
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExportOptionOnChange(Item)
	
	SetSaveLocationPage();
	ClearMessages();
	
EndProcedure

&AtClient
Procedure FileSavingDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectedDirectory = Item.EditText;
	Notification = New CallbackDescription("FileSavingDirectorySelectionCompletion", ThisObject);
	FileSystemClient.SelectDirectory(Notification,, SelectedDirectory);
	
EndProcedure

// Completion handler that handles selection of the destination directory.
//  See "FileDialog.Show()" in Syntax Assistant.
// 
// Parameters:
//  Directory - String
//  AdditionalParameters - Structure
//
&AtClient
Procedure FileSavingDirectorySelectionCompletion(Directory, AdditionalParameters) Export
	
	If Not IsBlankString(Directory) Then
		
		SelectedDirectory = Directory;
		ClearMessages();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteSelectedOption(Command)
	
	If ExportOption = "SaveToFolder"
	   And IsBlankString(SelectedDirectory) Then
		
		MessageText = NStr("en = 'Select folder';");
		CommonClient.MessageToUser(MessageText,, "SelectedDirectory");
		Return;
		
	EndIf;
	
	ErrorString = "";
	ErrorCounter = 0;
	MoreErrorsCounter = 0;
	DisplayedAttachmentErrorsCount = 10;
	
	If ExportOption = "Join" Then
		
		SelectionResult = New Structure;
		
		ObjectsToAttach = New Array;
		For Each ObjectOfAttachment In AttachmentObjects Do
			
			If Not ObjectOfAttachment.Check Then
				
				ErrorCounter = ErrorCounter + 1;
				
				If ErrorCounter < DisplayedAttachmentErrorsCount Then
					ErrorString = ErrorString + ?(ErrorCounter = 1, " ", ", ") + ObjectOfAttachment.Value;
				Else
					MoreErrorsCounter = MoreErrorsCounter + 1;
				EndIf;
				
			Else
				ObjectsToAttach.Add(ObjectOfAttachment.Value);
			EndIf;
			
		EndDo;
		
		SelectionResult.Insert("ObjectsToAttach", ObjectsToAttach);
		
	EndIf;
	
	If ErrorString <> "" Then
		
		CallbackDescriptionContinueExporting = New CallbackDescription(
			"ContinueExporting",
			ThisObject, 
			SelectionResult);
		
		If MoreErrorsCounter > 0 Then
			
			TemplateQuestionText = NStr("en = 'The following objects cannot be attached:
										|%1… and %2 more';");
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				TemplateQuestionText,
				ErrorString,
				MoreErrorsCounter);
			
		Else
			
			TemplateQuestionText = NStr("en = 'The following objects cannot be attached:
										|%1';");
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(TemplateQuestionText, ErrorString);
			
		EndIf;
		
		Buttons = New ValueList;
		Buttons.Add("Cancel", NStr("en = 'Cancel';"));
		Buttons.Add("Continue", NStr("en = 'Continue';"));
		
		QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionParameters.Title = NStr("en = 'Insufficient rights to attach objects';");
		QuestionParameters.LockWholeInterface = True;
		QuestionParameters.PromptDontAskAgain = False;
		
		StandardSubsystemsClient.ShowQuestionToUser(
			CallbackDescriptionContinueExporting,
			QueryText,
			Buttons,
			QuestionParameters);
		
	Else
		
		CommandDetails = ExecutionCommandDetails.CommandDetails;
		CommandDetails.Insert("ExportOption", ExportOption);
		
		ExecuteCommandExportToFile(
			CommandDetails.PrintManager,
			CommandDetails.Id,
			ExecutionCommandDetails.PrintObjects,
			FormOwner,
			CommandDetails);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ConfigureActionOptionsAvailability(PrintObjects, Var_Parameters)
	
	// настройка видимости
	CanBeSaved = (PrintObjects.Count() > 0);
	
	AttachmentObjects = ObjectsToAttach(PrintObjects);
	If PrintObjects.Count() = 1 Then
		
		HasOpportunityToAttach = AttachmentObjects[0].Check;
		
	ElsIf CanBeSaved Then
		
		HasOpportunityToAttach = False;
		For Each ObjectForAttaching In AttachmentObjects Do
			HasOpportunityToAttach = HasOpportunityToAttach Or ObjectForAttaching.Check;
		EndDo;
		
	Else
		
		HasOpportunityToAttach = False;
		
	EndIf;
	
	AttachableItem = Items.ExportOption.ChoiceList.FindByValue("Join");
	
	If Not HasOpportunityToAttach Then
		
		Items.ExportOption.ChoiceList.Delete(AttachableItem);
		AttachableItem = Undefined;
		ExportOption = "SaveToFolder";
		Items.ExportOption.ReadOnly = True;
		
	EndIf;
	
	FileOperationsExtensionAttached = Var_Parameters.FileOperationsExtensionAttached;
	Items.SelectExportOption.Visible = (FileOperationsExtensionAttached
												Or CanBeSaved);
	Items.ExportOption.Visible = CanBeSaved;
	If Not CanBeSaved Then
		
		Items.FileSavingDirectory.TitleLocation = FormItemTitleLocation.Top;
		
	ElsIf Not FileOperationsExtensionAttached Then
		
		ExportOption = "Join";
		Items.ExportOption.Enabled = False;
		
	EndIf;
	Items.FileSavingDirectory.Visible = FileOperationsExtensionAttached;
	
	If PrintObjects.Count() > 1
	   And AttachableItem <> Undefined Then
		
		Template = NStr("en = 'Attach to documents (%1)';");
		QuantityByString = Format(PrintObjects.Count(), "NFD=0;");
		AttachableItem.Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			QuantityByString);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinueExporting(QuestionResult, SelectionResult) Export
	
	If QuestionResult.Value = "Cancel" Then
		Close();
	Else
		
		CommandDetails = ExecutionCommandDetails.CommandDetails;
		CommandDetails.Insert("ExportOption", ExportOption);
		
		ExecuteCommandExportToFile(
			CommandDetails.PrintManager,
			CommandDetails.Id,
			SelectionResult.ObjectsToAttach,
			FormOwner,
			CommandDetails);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ObjectsToAttach(PrintObjects)
	
	Result = New ValueList;
	ModuleAccessManagement = Undefined;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
	EndIf;
	
	For Each PrintObject In PrintObjects Do
		
		EditionAllowed = True;
		If ModuleAccessManagement <> Undefined Then
			EditionAllowed = ModuleAccessManagement.EditionAllowed(PrintObject);
		EndIf;
		Result.Add(PrintObject,, EditionAllowed);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
//  PrintManagerName - String - 
//  TemplatesNames       - String - Print form IDs.
//  ObjectsArray     - AnyRef
//                     - Array of AnyRef - Print objects.
//  Var_FormOwner      - ClientApplicationForm - 
//  CommandDetails    - Structure - Arbitrary parameters to pass to the print manager.
//
&AtClient
Procedure ExecuteCommandExportToFile(PrintManagerName, TemplatesNames, ObjectsArray, Var_FormOwner, CommandDetails)
	
	If Not CheckPassedObjectsCount(ObjectsArray) Then
		Return;
	EndIf;
	
	OpeningParameters = PrintManagementInternalClient.ParametersForOpeningPrintForm();
	OpeningParameters.PrintManagerName = PrintManagerName;
	OpeningParameters.TemplatesNames = TemplatesNames;
	OpeningParameters.CommandParameter = ObjectsArray;
	OpeningParameters.PrintParameters = CommandDetails;
	
	If Var_FormOwner = Undefined Then
		OpeningParameters.StorageUUID = New UUID;
	Else
		OpeningParameters.StorageUUID = Var_FormOwner.UUID;
	EndIf;
	
	ResultAddress = ExecuteExportingToFileCommand(OpeningParameters);
	ExecuteExportingToFileCommandCompletion(ResultAddress, CommandDetails);
	
EndProcedure

&AtServer
Function ExecuteExportingToFileCommand(Val OpeningParameters)
	
	PrintObjects = OpeningParameters.CommandParameter;
	ExportCommands = OpeningParameters.PrintParameters;
	StorageUUID = OpeningParameters.StorageUUID;
	SettingsForSaving = PrintManagement.SettingsForSaving();
	SettingsForSaving.TransliterateFilesNames = TransliterateFilesNames;
	
	TableOfFiles = ExportObjectsToFiles.SaveByFormatToFile(ExportCommands, PrintObjects, SettingsForSaving);
	ResultAddress = PutToTempStorage(TableOfFiles, StorageUUID);
	Return ResultAddress;
	
EndFunction

&AtClient
Function CheckPassedObjectsCount(CommandParameter)
	
	AreObjectsPassed = True;
	
	If TypeOf(CommandParameter) = Type("Array")
	   And CommandParameter.Count() = 0 Then
		AreObjectsPassed =  False;
	EndIf;
	
	Return AreObjectsPassed;
	
EndFunction

&AtClient
Procedure ExecuteExportingToFileCommandCompletion(ResultAddress, PrintParameters)
	
	FilesInTempStorage = ProcessMessagesAndPutResultInTemporaryStorage(
		ResultAddress,
		PrintParameters);
	
	If FilesInTempStorage.Count() > 0 Then
		
		If ExportOption = "SaveToFolder" Then
			
			SavePrintFormsToDirectory(FilesInTempStorage, SelectedDirectory);
			
		Else
			
			WrittenObjects = AttachPrintFormsToObject(FilesInTempStorage);
			
			If WrittenObjects.Count() > 0 Then
				NotifyChanged(TypeOf(WrittenObjects[0]));
			EndIf;
			If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
				ModuleFilesOperationsInternalClient = CommonClient.CommonModule("FilesOperationsInternalClient");
				ModuleFilesOperationsInternalClient.NotifyOfFilesModification(WrittenObjects);
			EndIf;
			
			ShowUserNotification(,, NStr("en = 'Saved';"), PictureLib.Information32);
			
		EndIf;
		
	EndIf;
	
	Close();
	
EndProcedure

&AtServer
Function ProcessMessagesAndPutResultInTemporaryStorage(Val ResultAddress, Val PrintParameters)
	
	Presentation = PrintParameters.Presentation;
	
	FilesInTempStorage = New Array;
	Result = GetFromTempStorage(ResultAddress);
	
	If TypeOf(Result) = Type("Structure") Then
		
		ResultTable2 = Result.TableOfFiles;
		ErrorsArray = Result.ErrorsArray;
		
		For Each MessageText In ErrorsArray Do
			
			Common.MessageToUser(MessageText);
			
		EndDo;
		
	Else
		
		ResultTable2 = Result;
		
	EndIf;
		
	DeleteFromTempStorage(ResultAddress);
	
	For Each CurrentFileData In ResultTable2 Do
		
		PathInTempStorage = PutToTempStorage(
			CurrentFileData.BinaryData,
			New UUID());
		FileDetails = New Structure;
		FileDetails.Insert("AddressInTempStorage", PathInTempStorage);
		FileDetails.Insert("Presentation", CurrentFileData.FileName);
		FileDetails.Insert("UploadObject", CurrentFileData.UploadObject);
		FilesInTempStorage.Add(FileDetails);
		
	EndDo;
	
	If PackToArchive Then
		
		FilesInTempStorage = PutFilesToArchive(FilesInTempStorage, Presentation);
		
	EndIf;
	
	Return FilesInTempStorage;
	
EndFunction

&AtClient
Procedure SavePrintFormsToDirectory(FilesListInTempStorage, Val DirectoryName = "")
	
	If FileOperationsExtensionAttached And ValueIsFilled(DirectoryName) Then
		DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
	Else
		
		WhenPreparingFileNames(FilesListInTempStorage, "");
		Return;
		
	EndIf;
	
	NotifyDescription = New CallbackDescription("WhenPreparingFileNames", ThisObject, DirectoryName);
	PreparationParameters = PrintManagementClient.FileNamePreparationOptions(
		FilesListInTempStorage,
		DirectoryName,
		NotifyDescription);
	PrepareFileNamesToSaveToADirectory(PreparationParameters);
	
EndProcedure

// 
// 
// Parameters:
//  FilesListInTempStorage - Array of Structure:
//   * Presentation - String
//   * AddressInTempStorage - String
//  DirectoryName - String
//
&AtClient
Procedure WhenPreparingFileNames(FilesListInTempStorage, DirectoryName) Export
	
	FilesToSave = New Array;
	
	For Each FileToWrite In FilesListInTempStorage Do
		
		FileName = FileToWrite.Presentation;
		FilesToSave.Add(New TransferableFileDescription(FileName, FileToWrite.AddressInTempStorage));
		
	EndDo;
	
	SavingParameters = FileSystemClient.FilesSavingParameters();
	SavingParameters.Dialog.Directory = DirectoryName;
	SavingParameters.Interactively = Not ValueIsFilled(DirectoryName);
	FileSystemClient.SaveFiles(Undefined, FilesToSave, SavingParameters);
	
#If Not WebClient Then
	
	If ValueIsFilled(DirectoryName) Then
		
		NotifyDescription = New CallbackDescription("OpenFolderSaveTo", ThisObject, DirectoryName);
		Template = NStr("en = 'into %1';");
		SavingPath = StringFunctionsClientServer.SubstituteParametersToString(Template, DirectoryName);
		Text = NStr("en = 'Saved';");
		ShowUserNotification(
			Text,
			NotifyDescription,
			SavingPath,
			PictureLib.DialogInformation);
		
	EndIf;
	
#EndIf

EndProcedure

// 
// 
// Parameters:
//  DirectoryName - String
//
&AtClient
Procedure OpenFolderSaveTo(DirectoryName) Export
	
	FileSystemClient.OpenExplorer(DirectoryName);
	
EndProcedure

// Parameters:
//  PreparationParameters - See PrintManagementClient.FileNamePreparationOptions
//
&AtClient
Procedure PrepareFileNamesToSaveToADirectory(PreparationParameters)
	
	PrintManagementClient.PrepareFileNamesToSaveToADirectory(PreparationParameters);
	
EndProcedure

// 
// 
// Parameters:
//  DocsPrintForms - Array of Structure
//  PresentationToArchive - String
// 
// Returns:
//  Array of Structure:
// * Presentation - String
// * PrintObject - String
// * AddressInTempStorage - String
// 
&AtServer
Function PutFilesToArchive(DocsPrintForms, PresentationToArchive)
	
	Var ZipFileWriter; // ZipFileWriter
	ArchiveName = "";
	
	Result = New Array; // Array of Structure
	
	SetPrintObject = ExportOption = "Join";
	TempDirectoryName = FileSystem.CreateTemporaryDirectory();
	MapForArchives = New Map;
	
	For Each FileStructure In DocsPrintForms Do
		
		FileData = GetFromTempStorage(FileStructure.AddressInTempStorage);
		DeleteFromTempStorage(FileStructure.AddressInTempStorage);
		FullFileName = TempDirectoryName + FileStructure.Presentation;
		FullFileName = FileSystem.UniqueFileName(FullFileName);
		FileData.Write(FullFileName);
		
		If SetPrintObject Then
			
			UploadObject = FileStructure.UploadObject;
			
		Else
			
			UploadObject = Undefined;
			
		EndIf;
		
		If MapForArchives[UploadObject] = Undefined Then
			
			ArchiveName = GetTempFileName("zip");
			ZipFileWriter = New ZipFileWriter(ArchiveName);
			WriteParameters = New Structure("ZipFileWriter, ArchiveName", ZipFileWriter, ArchiveName);
			MapForArchives.Insert(UploadObject, WriteParameters);
			
		EndIf;
		
		MapForArchives[UploadObject].ZipFileWriter.Add(FullFileName);
		
	EndDo;
	
	For Each ObjectArchive In MapForArchives Do
		
		ZipFileWriter = ObjectArchive.Value.ZipFileWriter;
		ArchiveName = ObjectArchive.Value.ArchiveName;
		ZipFileWriter.Write();
		BinaryData = New BinaryData(ArchiveName);
		StorageUUID = New UUID;
		PathInTempStorage = PutToTempStorage(BinaryData, StorageUUID);
		FileNameToArchive = FileNameForArchive(TransliterateFilesNames, PresentationToArchive);
		FileDetails = New Structure;
		FileDetails.Insert("Presentation", FileNameToArchive);
		FileDetails.Insert("UploadObject", ObjectArchive.Key);
		FileDetails.Insert("AddressInTempStorage", PathInTempStorage);
		Result.Add(FileDetails);
		FileSystem.DeleteTempFile(ArchiveName);
		
	EndDo;
	
	FileSystem.DeleteTemporaryDirectory(TempDirectoryName);
	
	Return Result;
	
EndFunction

// 
// 
// Parameters:
//  TransliterateFilesNames - Boolean
//  PresentationToArchive - String
// 
// Returns:
//  String - 
// 
&AtServer
Function FileNameForArchive(TransliterateFilesNames, PresentationToArchive)
	
	Result = "";
	If PresentationToArchive <> "" Then
		Result = PresentationToArchive;
	Else
		Result = NStr("en = 'Documents';");
	EndIf;
	
	If TransliterateFilesNames Then
		Result = StringFunctions.LatinString(Result);
	EndIf;
	
	Return Result + ".zip";
	
EndFunction

&AtServer
Function AttachPrintFormsToObject(Val FilesInTempStorage)
	
	Result = New Array;
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		
		ModuleFilesOperations = Common.CommonModule("FilesOperations");
		For Each File In FilesInTempStorage Do
			
			If ModuleFilesOperations.CanAttachFilesToObject(File.UploadObject) Then
				
				FileParameters = ModuleFilesOperations.FileAddingOptions();
				FileParameters.FilesOwner = File.UploadObject;
				FileParameters.BaseName = File.Presentation;
				AttachedFile = ModuleFilesOperations.AppendFile(
					FileParameters, File.AddressInTempStorage, , NStr("en = 'Export';"));
				Result.Add(AttachedFile);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure SetSaveLocationPage()
	
	If Items.FileSavingDirectory.Visible Then
		Items.FileSavingDirectory.Enabled = (ExportOption <> "Join");
	EndIf;
	
EndProcedure

#EndRegion