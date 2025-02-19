///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RestrictionOfSaveFormats = StrSplit(Parameters.RestrictionOfSaveFormats, ",", False);
	For Each SaveFormat In PrintManagement.SpreadsheetDocumentSaveFormatsSettings() Do
		If Not RestrictionOfSaveFormats.Count()
			Or RestrictionOfSaveFormats.Find(SaveFormat.Extension) <> Undefined Then
				
			SelectedSaveFormats.Add(String(SaveFormat.SpreadsheetDocumentFileType), SaveFormat.Presentation, False, SaveFormat.Picture);
		EndIf;
	EndDo;
	SelectedSaveFormats[0].Check = True; // By default, only the first format from the list is selected.
	
	If SelectedSaveFormats.Count() = 1 Then
		Items.FormatsSelectionGroup.Visible = False;
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "WithoutChoosingFormat");
	ElsIf SelectedSaveFormats.Count() > 1 Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "");
	EndIf;

	AttachmentObjects = ObjectsToAttach(Parameters.PrintObjects);
	
	CanBeSaved = Parameters.PrintObjects.Count() > 0;
	If Parameters.PrintObjects.Count() = 1 Then
		HasOpportunityToAttach = AttachmentObjects[0].Check;
	ElsIf CanBeSaved Then
		HasOpportunityToAttach = False;
		For Each ObjectForAttaching In AttachmentObjects Do
			HasOpportunityToAttach = HasOpportunityToAttach Or ObjectForAttaching.Check;			
		EndDo;
	Else
		HasOpportunityToAttach = False;
	EndIf;
	
	AttachableItem = Items.SavingOption.ChoiceList.FindByValue("Join");
	If Not HasOpportunityToAttach Then
		Items.SavingOption.ChoiceList.Delete(AttachableItem);
		AttachableItem = Undefined;
		SavingOption = "SaveToFolder";
		Items.SavingOption.ReadOnly = True;
	EndIf;
	
	Items.SelectFileSaveLocation.Visible = Parameters.FileOperationsExtensionAttached 
		Or CanBeSaved;
	If Parameters.PrintObjects.Count() > 1 And AttachableItem <> Undefined Then
		AttachableItem.Presentation = NStr("en = 'Attach to documents';")
				+ " (" + Format(Parameters.PrintObjects.Count(), "NFD=0;") + ")";
	EndIf;

	If Parameters.Purpose = "AttachedFiles" Then
		SavingOption = "Join";
		Items.SavingOption.Visible = False;
		Items.FilesSaveDirectory.Visible = False;
		Title = AttachableItem.Presentation;
		AutoTitle = False;
		Items.SaveButton.Title =  NStr("en = 'Attach';");
	ElsIf Parameters.Purpose = "Computer" Then
		SavingOption = "SaveToFolder";
		Items.SavingOption.Visible = False;
		Items.FilesSaveDirectory.TitleLocation = FormItemTitleLocation.Top;
		Items.FilesSaveDirectory.Visible = Parameters.FileOperationsExtensionAttached;
	Else	
		SavingOption = "SaveToFolder";
		Items.SavingOption.Visible = CanBeSaved;
		If Not CanBeSaved Then
			Items.FilesSaveDirectory.TitleLocation = FormItemTitleLocation.Top;
		EndIf;
		Items.FilesSaveDirectory.Visible = Parameters.FileOperationsExtensionAttached;
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		Items.SaveButton.Representation = ButtonRepresentation.Picture;
		Items.Sign.Visible = False;
		Item = Items.SavingOption.ChoiceList.FindByValue("SaveToFolder");
		Item.Presentation = NStr("en = 'Save to device';");
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If SelectedSaveFormats.Count() <> 1 Then
		SaveFormatsFromSettings = Settings["SelectedSaveFormats"];
		If SaveFormatsFromSettings <> Undefined Then
			For Each SelectedFormat In SelectedSaveFormats Do 
				FormatFromSettings = SaveFormatsFromSettings.FindByValue(SelectedFormat.Value);
				If FormatFromSettings <> Undefined Then
					SelectedFormat.Check = FormatFromSettings.Check;
				EndIf;
			EndDo;
			Settings.Delete("SelectedSaveFormats");
		EndIf;
	Else
		Settings.Delete("SelectedSaveFormats");
	EndIf;
	
	If Items.SavingOption.ReadOnly Then
		Settings["SavingOption"] = "SaveToFolder"; 
	EndIf;
	
	If Common.IsMobileClient() Then
		Settings["Sign"] = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	If SelectedSaveFormats.Count() = 1 Then
		Settings.Delete("SelectedSaveFormats");
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetSaveLocationPage();
	If Parameters.Purpose = "Computer" Then
		FileSystemClient.SelectDirectory(
			New CallbackDescription("FolderToSaveFilesSelectionCompletion", ThisObject));
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SavingOptionOnChange(Item)
	SetSaveLocationPage();
	ClearMessages();
EndProcedure

&AtClient
Procedure FolderToSaveFilesStartChoice(Item, ChoiceData, StandardProcessing)

	SelectedFolder = Item.EditText;
	FileSystemClient.SelectDirectory(
		New CallbackDescription("FolderToSaveFilesSelectionCompletion", ThisObject), , SelectedFolder);
	
EndProcedure

// Completion handler that handles selection of the destination directory.
//  See "FileDialog.Show" in Syntax Assistant.
//
&AtClient
Procedure FolderToSaveFilesSelectionCompletion(Folder, AdditionalParameters) Export 
	If Not IsBlankString(Folder) Then 
		SelectedFolder = Folder;
		ClearMessages();
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	If Items.FilesSaveDirectory.Visible Then
		If SavingOption = "SaveToFolder" And IsBlankString(SelectedFolder) Then
			CommonClient.MessageToUser(NStr("en = 'Choose a directory.';"),, "SelectedFolder");
			Return;
		EndIf;
	EndIf;
		
	SaveFormats = New Array;
	For Each SelectedFormat In SelectedSaveFormats Do
		If SelectedFormat.Check Then
			SaveFormats.Add(SelectedFormat.Value);
		EndIf;
	EndDo;
	
	If SaveFormats.Count() = 0 Then
		ShowMessageBox(,NStr("en = 'Choose one of the suggested formats.';"));
		Return;
	EndIf;
	
	SelectionResult = New Structure;
	SelectionResult.Insert("PackToArchive", PackToArchive);
	SelectionResult.Insert("SaveFormats", SaveFormats);
	SelectionResult.Insert("SavingOption", SavingOption);
	SelectionResult.Insert("FolderForSaving", SelectedFolder);
	SelectionResult.Insert("TransliterateFilesNames", TransliterateFilesNames);
	SelectionResult.Insert("Sign", Sign);
	
	If SavingOption = "SaveToFolder" Then
		NotifyChoice(SelectionResult);
		Return;
	EndIf;	
	
	ErrorString = "";
	ObjectsToAttach = New Map; 
	For Each ObjectOfAttachment In AttachmentObjects Do
		If Not ObjectOfAttachment.Check Then
			ErrorString = ErrorString + ObjectOfAttachment.Value;
		Else
			ObjectsToAttach.Insert(ObjectOfAttachment.Value, True);
		EndIf;
	EndDo;
	
	SelectionResult.Insert("ObjectsToAttach", ObjectsToAttach);
	
	If IsBlankString(ErrorString) Then
		NotifyChoice(SelectionResult);
		Return;
	EndIf;

	QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'The file will not be attached to the documents:
		|%1';"), ErrorString);
	
	Buttons = New ValueList;
	Buttons.Add("Cancel", NStr("en = 'Cancel';"));
	Buttons.Add("Continue", NStr("en = 'Continue';"));
	
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.Title = NStr("en = 'Insufficient rights to attach the file';");
	QuestionParameters.LockWholeInterface = True;
	QuestionParameters.PromptDontAskAgain = False;
	
	NotifyDescription = New CallbackDescription("SaveAfterConfirm", ThisObject, SelectionResult);
	StandardSubsystemsClient.ShowQuestionToUser(NotifyDescription, QueryText, Buttons, QuestionParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetSaveLocationPage()
	
	If Items.FilesSaveDirectory.Visible Then
		Items.FilesSaveDirectory.Enabled = SavingOption <> "Join";
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveAfterConfirm(QuestionResult, SelectionResult) Export
	If QuestionResult.Value = "Cancel" Then
		Close();
		Return;
	EndIf;
	NotifyChoice(SelectionResult);
EndProcedure

&AtServerNoContext
Function ObjectsToAttach(PrintObjects)
	Result = New ValueList;
	ModuleAccessManagement = Undefined;
	ModuleFilesOperations = Undefined;
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
	EndIf;
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperations = Common.CommonModule("FilesOperations");
	EndIf;
	
	For Each PrintObject In PrintObjects Do
		Check = False;
		If ModuleAccessManagement <> Undefined Then
			Check = Check Or ModuleAccessManagement.EditionAllowed(PrintObject.Value);
		EndIf;
		If ModuleFilesOperations <> Undefined Then
			Check = Check And ModuleFilesOperations.CanAttachFilesToObject(PrintObject.Value);
		EndIf;
		Result.Add(PrintObject.Value,,Check); 
	EndDo;
	
	Return Result;
EndFunction

#EndRegion
