﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ReportsToSend; // Array of ErrorReport 

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetConditionalAppearance();
	
	FuzzySearchAddIn = Common.AttachAddInFromTemplate("FuzzyStringMatchExtension", "CommonTemplate.StringSearchAddIn");
	If FuzzySearchAddIn <> Undefined Then 
		FuzzySearch1 = True;
	EndIf;
	
	DefaultFormSettings = DuplicatesDeletionSearchSettings();
	FormSettings = Common.CommonSettingsStorageLoad(FormName, "", DefaultFormSettings);
	FillPropertyValues(DefaultFormSettings, FormSettings);
	FormSettings = DefaultFormSettings;
	FillPropertyValues(FormSettings, Parameters);
	
	OnCreateAtServerDataInitialization(FormSettings);
	InitializeFilterComposerAndRules(FormSettings);
	
	//  
	
	// 
	StatePresentation = Items.NoSearchPerformed.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.Text = NStr("en = 'You did not run duplicate search yet.
	                                  |Set filter criteria and select Find duplicates.';");
	
	StatePresentation = Items.Searching.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.Picture = Items.TimeConsumingOperation48.Picture;
	
	StatePresentation = Items.Deletion.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.Picture = Items.TimeConsumingOperation48.Picture;
	
	StatePresentation = Items.DuplicatesNotFound.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.Text = NStr("en = 'No duplicates found by the specified criteria.
	                                        |Edit the filter criteria and select Find duplicates.';");
	
	// 
	SavedInSettingsDataModified = True;
	
	// 
	InitializeStepByStepWizardSettings();
	
	// 
	SearchStep = AddWizardStep(Items.NoSearchPerformedStep);
	SearchStep.BackButton.Visible = False;
	SearchStep.NextButton.Title = NStr("en = 'Find duplicates >';");
	SearchStep.NextButton.ToolTip = NStr("en = 'Find duplicates by the specified criteria.';");
	SearchStep.CancelButton.Title = NStr("en = 'Close';");
	SearchStep.CancelButton.ToolTip = NStr("en = 'Close the form without duplicate search.';");
	
	// 
	Step = AddWizardStep(Items.PerformSearchStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Visible = False;
	Step.CancelButton.Title = NStr("en = 'Cancel';");
	Step.CancelButton.ToolTip = NStr("en = 'Cancel duplicate search.';");
	
	// 
	Step = AddWizardStep(Items.MainItemSelectionStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Title = NStr("en = 'Delete duplicates >';");
	Step.NextButton.ToolTip = NStr("en = 'Delete duplicates';");
	Step.WhenYouClickNext = "StepSelectTheMainElementWhenYouClickNext";
	Step.CancelButton.Title = NStr("en = 'Close';");
	Step.CancelButton.ToolTip = NStr("en = 'Close the form without duplicate search.';");
	
	// 
	Step = AddWizardStep(Items.DeletionStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Visible = False;
	Step.CancelButton.Title = NStr("en = 'Cancel';");
	Step.CancelButton.ToolTip = NStr("en = 'Cancel duplicate deletion.';");
	
	// 
	Step = AddWizardStep(Items.SuccessfulDeletionStep);
	Step.BackButton.Title = NStr("en = 'Search again';");
	Step.BackButton.ToolTip = NStr("en = 'Start a new duplicate search.';");
	Step.NextButton.Visible = False;
	Step.CancelButton.DefaultButton = True;
	Step.CancelButton.Title = NStr("en = 'Close';");
	
	// 
	Step = AddWizardStep(Items.UnsuccessfulReplacementsStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Title = NStr("en = 'Delete again >';");
	Step.NextButton.ToolTip = NStr("en = 'Delete duplicates';");
	Step.CancelButton.Title = NStr("en = 'Close';");
	
	// 
	Step = AddWizardStep(Items.DuplicatesNotFoundStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Title = NStr("en = 'Find duplicates >';");
	Step.NextButton.ToolTip = NStr("en = 'Find duplicates by the specified criteria.';");
	Step.CancelButton.Title = NStr("en = 'Close';");
	
	// 
	Step = AddWizardStep(Items.ErrorOccurredStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Visible = False;
	Step.CancelButton.Title = NStr("en = 'Close';");
	
	// 
	WizardSettings.CurrentStep = SearchStep;
	SetVisibilityAvailability(ThisObject);
	
	Items.DetailsGroup1.Visible = False;
	DisplayedRelationship = 2;
	SetPossibleDuplicatesFilter(ThisObject);
	
	If Common.IsMobileClient() Then
		Items.Header.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.CommandBar.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	OnActivateWizardStep();
	ReportsToSend = New Map;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	If Not WizardSettings.ShowDialogBeforeClose Then
		Return;
	EndIf;
	If Exit Then
		Return;
	EndIf;
	
	Cancel = True;
	CurrentPage = Items.WizardSteps.CurrentPage;
	If CurrentPage = Items.PerformSearchStep Then
		QueryText = NStr("en = 'Do you want to stop search and close the form?';");
	ElsIf CurrentPage = Items.DeletionStep Then
		QueryText = NStr("en = 'Do you want to stop deletion and close the form?';");
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Abort, NStr("en = 'Cancel operation';"));
	Buttons.Add(DialogReturnCode.No,      NStr("en = 'Continue operation';"));
	
	Handler = New NotifyDescription("AfterConfirmCancelJob", ThisObject);
	ShowQueryBox(Handler, QueryText, Buttons, , DialogReturnCode.No);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DuplicatesSearchAreaOpening(Item, StandardProcessing)
	StandardProcessing = False;
	OpenForm(DuplicatesSearchArea + ".ListForm");
EndProcedure

&AtClient
Procedure DuplicatesSearchAreaStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	Name = FullFormName("DuplicatesSearchArea");
	
	FormParameters = New Structure;
	FormParameters.Insert("SettingsAddress", SettingsAddress);
	FormParameters.Insert("DuplicatesSearchArea", DuplicatesSearchArea);
	
	Handler = New NotifyDescription("DuplicatesSearchAreaSelectionCompletion", ThisObject);
	
	OpenForm(Name, FormParameters, ThisObject, , , , Handler);
EndProcedure

&AtClient
Procedure DuplicatesSearchAreaSelectionCompletion(Result, ExecutionParameters) Export
	If TypeOf(Result) <> Type("String") Then
		Return;
	EndIf;
	
	DuplicatesSearchArea = Result;
	InitializeFilterComposerAndRules(Undefined);
	GoToWizardStep1(Items.NoSearchPerformedStep);
EndProcedure

&AtClient
Procedure DuplicatesSearchAreaOnChange(Item)
	InitializeFilterComposerAndRules(Undefined);	
	GoToWizardStep1(Items.NoSearchPerformedStep);
EndProcedure

&AtClient
Procedure DuplicatesSearchAreaClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure AllUnprocessedItemsUsageInstancesClick(Item)
	
	ShowUsageInstances(UnprocessedDuplicates);
	
EndProcedure

&AtClient
Procedure AllUsageInstancesClick(Item)
	
	ShowUsageInstances(FoundDuplicates);
	
EndProcedure

&AtClient
Procedure FilterRulesPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	AttachIdleHandler("OnStartSelectFilterRules", 0.1, True);
EndProcedure

&AtClient
Procedure OnStartSelectFilterRules()
	
	Name = FullFormName("FilterRules");
	
	ListItem = Items.DuplicatesSearchArea.ChoiceList.FindByValue(DuplicatesSearchArea);
	If ListItem = Undefined Then
		SearchForDuplicatesAreaPresentation = Undefined;
	Else
		SearchForDuplicatesAreaPresentation = ListItem.Presentation;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CompositionSchemaAddress",            CompositionSchemaAddress);
	FormParameters.Insert("FilterComposerSettingsAddress", FilterComposerSettingsAddress());
	FormParameters.Insert("MasterFormID",      UUID);
	FormParameters.Insert("FilterAreaPresentation",      SearchForDuplicatesAreaPresentation);
	
	Handler = New NotifyDescription("FilterRulesSelectionCompletion", ThisObject);
	
	OpenForm(Name, FormParameters, ThisObject, , , , Handler);
	
EndProcedure

&AtClient
Procedure FilterRulesSelectionCompletion(ResultAddress, ExecutionParameters) Export
	If TypeOf(ResultAddress) <> Type("String") Or Not IsTempStorageURL(ResultAddress) Then
		Return;
	EndIf;
	UpdateFilterComposer(ResultAddress);
	GoToWizardStep1(Items.NoSearchPerformedStep);
EndProcedure

&AtClient
Procedure FilterRulesPresentationClearing(Item, StandardProcessing)
	StandardProcessing = False;
	PrefilterComposer.Settings.Filter.Items.Clear();
	GoToWizardStep1(Items.NoSearchPerformedStep);
	SaveUserSettingsSSL();
EndProcedure

&AtClient
Procedure SearchRulesPresentationClick(Item, StandardProcessing)
	StandardProcessing = False;
	
	Name = FullFormName("SearchRules");
	
	ListItem = Items.DuplicatesSearchArea.ChoiceList.FindByValue(DuplicatesSearchArea);
	If ListItem = Undefined Then
		SearchForDuplicatesAreaPresentation = Undefined;
	Else
		SearchForDuplicatesAreaPresentation = ListItem.Presentation;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("DuplicatesSearchArea",        DuplicatesSearchArea);
	FormParameters.Insert("AppliedRuleDetails",   AppliedRuleDetails);
	FormParameters.Insert("SettingsAddress",              SearchRulesSettingsAddress());
	FormParameters.Insert("FilterAreaPresentation", SearchForDuplicatesAreaPresentation);
	
	Handler = New NotifyDescription("SearchRulesSelectionCompletion", ThisObject);
	OpenForm(Name, FormParameters, ThisObject, , , , Handler);
EndProcedure

&AtClient
Procedure SearchRulesSelectionCompletion(ResultAddress, ExecutionParameters) Export
	If TypeOf(ResultAddress) <> Type("String") Or Not IsTempStorageURL(ResultAddress) Then
		Return;
	EndIf;
	UpdateSearchRules(ResultAddress);
	GoToWizardStep1(Items.NoSearchPerformedStep);
EndProcedure

&AtClient
Procedure FoundDuplicatesStateDetailsURLProcessing(Item, Ref, StandardProcessing)
	
	StandardProcessing = False;
	If Ref = "DeletionMethod" Then
		DeletionMethod = ?(DeletionMethod = "Directly", "Check", "Directly");
		UpdateFoundDuplicatesStateDetails();
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailsRefClick(Item)
	StandardSubsystemsClient.ShowDetailedInfo(Undefined, Item.ToolTip);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFoundDuplicates

&AtClient
Procedure FoundDuplicatesOnActivateRow(Item)
	
	AttachIdleHandler("DuplicatesRowActivationDeferredHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure DuplicatesRowActivationDeferredHandler()
	RowID = Items.FoundDuplicates.CurrentRow;
	If RowID = Undefined Or RowID = CurrentRowID Then
		Return;
	EndIf;
	CurrentRowID = RowID;
	
	UpdateCandidateUsageInstances(RowID);
EndProcedure

&AtServer
Procedure UpdateCandidateUsageInstances(Val RowID)
	CurrentRow = FoundDuplicates.FindByID(RowID);
	
	If CurrentRow.GetParent() = Undefined Then
		// 
		ProbableDuplicateUsageInstances.Clear();
		
		OriginalDescription = Undefined;
		MarkedForDeletionAndNotUsed = True;
		For Each Candidate In CurrentRow.GetItems() Do
			If Candidate.Main Then
				OriginalDescription = Candidate.Description;
			ElsIf Candidate.PictureNumber <> 4 Or Candidate.Count > 0 Then
				MarkedForDeletionAndNotUsed = False;
			EndIf;
		EndDo;
		
		LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Found %2 duplicates for %1.';"),
			OriginalDescription, CurrentRow.Count);
		If MarkedForDeletionAndNotUsed Then
			LongDesc = LongDesc + Chars.LF
				+ NStr("en = 'All duplicates are marked for deletion and there are no references to them, so deleting duplicates is no longer required.';");
		EndIf;
				
		Items.DetailsGroup1.Title = NStr("en = 'Information records:';");
		Items.CurrentDuplicatesGroupDetails.Title = LongDesc;
		Items.UsageInstancesPages.CurrentPage = Items.GroupDetails;
		Return;
	EndIf;
	
	// 
	UsageTable = GetFromTempStorage(UsageInstancesAddress);
	Filter = New Structure("Ref", CurrentRow.Ref);
	
	ProbableDuplicateUsageInstances.Load(UsageTable.Copy(UsageTable.FindRows(Filter)));
	
	If CurrentRow.Count = 0 Then
		Items.CurrentDuplicatesGroupDetails.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1 has no occurrences';"), 
			CurrentRow.Description);
		Items.DetailsGroup1.Title = NStr("en = 'Information records:';");
		Items.UsageInstancesPages.CurrentPage = Items.GroupDetails;
	Else
		Items.DetailsGroup1.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Occurrences of ""%1"" (%2):';"), 
			CurrentRow.Description,
			CurrentRow.Count);
		
		Items.UsageInstancesPages.CurrentPage = Items.UsageInstances;
	EndIf;
	
EndProcedure

&AtClient
Procedure FoundDuplicatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	OpenDuplicateForm(Item.CurrentData);
	
EndProcedure

&AtClient
Procedure FoundDuplicatesCheckOnChange(Item)
	
	RowData = Items.FoundDuplicates.CurrentData;
	RowData.Check = RowData.Check % 2;
	EditCandidatesNotes(RowData);
	
	DuplicatesSearchErrorDescription = "";
	TotalFoundDuplicates = 0;
	For Each Duplicate1 In FoundDuplicates.GetItems() Do
		For Each Child In Duplicate1.GetItems() Do
			If Not Child.Main And Child.Check Then
				TotalFoundDuplicates = TotalFoundDuplicates + 1;
			EndIf;
		EndDo;
	EndDo;
	
	UpdateFoundDuplicatesStateDetails();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUnprocessedDuplicates

&AtClient
Procedure UnprocessedDuplicatesOnActivateRow(Item)
	
	AttachIdleHandler("UnprocessedDuplicatesRowActivationDeferredHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure UnprocessedDuplicatesRowActivationDeferredHandler()
	
	RowData = Items.UnprocessedDuplicates.CurrentData;
	If RowData = Undefined Then
		Return;
	EndIf;
	
	UpdateUnprocessedItemsUsageInstancesDuplicates( RowData.GetID() );
EndProcedure

&AtServer
Procedure UpdateUnprocessedItemsUsageInstancesDuplicates(Val DataString1)
	RowData = UnprocessedDuplicates.FindByID(DataString1);
	
	If RowData.GetParent() = Undefined Or RowData.Main Then
		UnprocessedItemsUsageInstances.Clear();
		Items.CurrentDuplicatesGroupDetails1.Title = NStr("en = 'To view details, select the duplicate that caused the issue.';");
		Items.UnprocessedItemsUsageInstancesPages.CurrentPage = Items.UnprocessedItemsGroupDetails;
		Return;
	EndIf;
	
	If RowData.Count = 0 Then
		UnprocessedItemsUsageInstances.Clear();
		Items.CurrentDuplicatesGroupDetails1.Title = 
			NStr("en = 'Cannot replace the selected duplicate as it is impossible to replace other duplicates.';");
		Items.UnprocessedItemsUsageInstancesPages.CurrentPage = Items.UnprocessedItemsGroupDetails;
	Else
		ErrorsTable = GetFromTempStorage(ReplacementResultAddress); // See Common.ReplaceReferences
		Filter = New Structure("Ref", RowData.Ref);
		
		Data = ErrorsTable.Copy( ErrorsTable.FindRows(Filter) );
		Data.Columns.Add("Pictogram");
		Data.FillValues(True, "Pictogram");
		UnprocessedItemsUsageInstances.Load(Data);
		
		Items.ProbableDuplicateUsageInstances.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot replace some of the duplicates (%1).';"), 
			RowData.Count);
		Items.UnprocessedItemsUsageInstancesPages.CurrentPage = Items.UnprocessedItemsUsageInstanceDetails;
	EndIf;
	
EndProcedure

&AtClient
Procedure UnprocessedDuplicatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	OpenDuplicateForm(Items.UnprocessedDuplicates.CurrentData);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUnprocessedItemsUsageInstances

&AtClient
Procedure UnprocessedItemsUsageInstancesOnActivateRow(Item)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		UnprocessedItemsErrorDescription = "";	
		Items.DecorationSendErrorReport.Visible = False;
		Return;
	EndIf;
		
	UnprocessedItemsErrorDescription = ?(CurrentData.ErrorInfo <> Undefined,
			ErrorProcessing.ErrorMessageForUser(CurrentData.ErrorInfo),
			CurrentData.ErrorText);

	If CurrentData.ErrorInfo = Undefined Then
		Items.DecorationSendErrorReport.Visible = False;
	Else
		StandardSubsystemsClient.ConfigureVisibilityAndTitleForURLSendErrorReport(
			Items.DecorationSendErrorReport, CurrentData.ErrorInfo);
	EndIf;
	
EndProcedure

&AtClient
Procedure UnprocessedItemsUsageInstancesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = UnprocessedItemsUsageInstances.FindByID(RowSelected);
	ShowValue(, CurrentData.ErrorObject);
	
EndProcedure

&AtClient
Procedure DecorationSendErrorReportClick(Item)

	CurrentData = Items.UnprocessedItemsUsageInstances.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	ReportToSend = ReportsToSend[CurrentData.ErrorInfo];
	If ReportToSend = Undefined Then
		ReportToSend = New ErrorReport(CurrentData.ErrorInfo);
		ReportsToSend[CurrentData.ErrorInfo] = ReportToSend;
	EndIf;
	StandardSubsystemsClient.ShowErrorReport(ReportToSend);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProbableDuplicateUsageInstances

&AtClient
Procedure ProbableDuplicateUsageInstancesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = ProbableDuplicateUsageInstances.FindByID(RowSelected);
	ShowValue(, CurrentData.Data);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPossibleDuplicates

&AtClient
Procedure DisplayedRelationshipOnChange(Item)
	
	SetPossibleDuplicatesFilter(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetPossibleDuplicatesFilter(Form)
	
	If Form.DisplayedRelationship = 1 Then
		Form.Items.PossibleDuplicates.RowFilter = Undefined;	
	Else
		Form.Items.PossibleDuplicates.RowFilter = New FixedStructure("RelationDegree", 2);
	EndIf;

EndProcedure

&AtClient
Procedure PossibleDuplicatesSelectedOnChange(Item)
	
	CurrentData = Items.PossibleDuplicates.CurrentData;
	
	RowsSelected = PossibleDuplicates.FindRows(New Structure("Selected", True));
	For Each DuplicateRow In RowsSelected Do
		
		If DuplicateRow.GetID() = CurrentData.GetID() Then
			Continue;
		EndIf;
		
		DuplicateRow.Selected = False;
		
	EndDo;
	
	PossibleDuplicateSelected = CurrentData.Selected;
	PossibleDuplicateSelectedType = CurrentData.MetadataObjectType;
	
	OnActivateWizardStep();

EndProcedure

&AtClient
Procedure RefreshPossibleDuplicatesStatus()

	GroupTitle = NStr("en = 'The replacement of duplicates might have generated duplicates in other lists (%1)';");
	UnprocessedItemsCount = PossibleDuplicates.FindRows(New Structure("Processed", False)).Count();
	Items.GroupPossibleDuplicates.Title = StringFunctionsClientServer.SubstituteParametersToString(GroupTitle, UnprocessedItemsCount);
	Items.GroupPossibleDuplicates.Visible = UnprocessedItemsCount > 0;	

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WizardButtonHandler(Command)
	
	If Command.Name = WizardSettings.NextButton Then
		
		WizardStepNext();
		
	ElsIf Command.Name = WizardSettings.BackButton Then
		
		WizardStepBack();
		
	ElsIf Command.Name = WizardSettings.CancelButton Then
		
		WizardStepCancel();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MarkAsOriginal(Command)
	
	RowData = Items.FoundDuplicates.CurrentData;
	If RowData = Undefined Or RowData.Main Then
		Return; // 
	EndIf;
		
	Parent = RowData.GetParent();
	If Parent = Undefined Then
		Return;
	EndIf;
	
	MarkItemAsOriginal(RowData, Parent);
EndProcedure

&AtClient
Procedure OpenProbableDuplicate(Command)
	
	OpenDuplicateForm(Items.FoundDuplicates.CurrentData);
	
EndProcedure

&AtClient
Procedure OpenUnprocessedDuplicate(Command)
	
	OpenDuplicateForm(Items.UnprocessedDuplicates.CurrentData);
	
EndProcedure

&AtClient
Procedure ExpandDuplicatesGroups(Command)
	
	ExpandDuplicatesGroup();
	
EndProcedure

&AtClient
Procedure CollapseDuplicatesGroups(Command)
	
	CollapseDuplicatesGroup();
	
EndProcedure

&AtClient
Procedure RetrySearch(Command)
	
	GoToWizardStep1(Items.PerformSearchStep);
	
EndProcedure

&AtClient
Procedure SelectAllCheckBoxes(Command)
	
	ListItems = FoundDuplicates.GetItems();
	For Each Item In ListItems Do
		SetMarksInTree(Item, True, True);
		Parent = Item.GetParent();
		If Parent = Undefined Then
			CheckParentMark(Item)
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearAllCheckBoxes(Command)
	
	ListItems = FoundDuplicates.GetItems();
	For Each Item In ListItems Do
		SetMarksInTree(Item, False, True);
		Parent = Item.GetParent();
		If Parent = Undefined Then
			CheckParentMark(Item)
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure More(Command)
	Items.DetailsGroup1.Visible = Not Items.DetailsGroup1.Visible;
	Items.MoreDetails.Title = ?(Items.DetailsGroup1.Visible, NStr("en = '<< Hide';"), NStr("en = 'Details >>';"));
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 

&AtServer
Procedure InitializeStepByStepWizardSettings()
	WizardSettings = New Structure;
	WizardSettings.Insert("Steps", New Array);
	WizardSettings.Insert("CurrentStep", Undefined);
	
	// 
	WizardSettings.Insert("PagesGroup", Items.WizardSteps.Name);
	WizardSettings.Insert("NextButton",   Items.WizardStepNext.Name);
	WizardSettings.Insert("BackButton",   Items.WizardStepBack.Name);
	WizardSettings.Insert("CancelButton",  Items.WizardStepCancel.Name);
	
	// 
	WizardSettings.Insert("ShowDialogBeforeClose", False);
	
	// 
	Items.WizardStepNext.Visible  = False;
	Items.WizardStepBack.Visible  = False;
	Items.WizardStepCancel.Visible = False;
EndProcedure

// Parameters:
//  Page - FormGroup
//
// Returns:
//  Structure:
//    * IndexOf - Number
//    * PageName - String
//    * BackButton - See WizardButton
//    * NextButton - See WizardButton
//    * CancelButton - See WizardButton
// 
&AtServer
Function AddWizardStep(Val Page)
	StepDescription = New Structure;
	StepDescription.Insert("IndexOf", 0);
	StepDescription.Insert("PageName", "");
	StepDescription.Insert("BackButton", WizardButton());
	StepDescription.Insert("NextButton", WizardButton());
	StepDescription.Insert("WhenYouClickNext", "");
	StepDescription.Insert("CancelButton", WizardButton());
	StepDescription.PageName = Page.Name;
	
	StepDescription.BackButton = WizardButton();
	StepDescription.BackButton.Title = NStr("en = '< Back';");
	
	StepDescription.NextButton = WizardButton();
	StepDescription.NextButton.DefaultButton = True;
	StepDescription.NextButton.Title = NStr("en = 'Next >';");
	
	StepDescription.CancelButton = WizardButton();
	StepDescription.CancelButton.Title = NStr("en = 'Cancel';");
	
	WizardSettings.Steps.Add(StepDescription);
	
	StepDescription.IndexOf = WizardSettings.Steps.UBound();
	Return StepDescription;
EndFunction

&AtClientAtServerNoContext
Procedure SetVisibilityAvailability(Form)
	
	Items = Form.Items;
	WizardSettings = Form.WizardSettings;
	CurrentStep = WizardSettings.CurrentStep;
	
	// 
	Items[WizardSettings.PagesGroup].CurrentPage = Items[CurrentStep.PageName];
	
	// 
	UpdateWizardButtonProperties(Items[WizardSettings.NextButton],  CurrentStep.NextButton);
	UpdateWizardButtonProperties(Items[WizardSettings.BackButton],  CurrentStep.BackButton);
	UpdateWizardButtonProperties(Items[WizardSettings.CancelButton], CurrentStep.CancelButton);
	
EndProcedure

&AtClient
Procedure GoToWizardStep1(Val StepOrIndexOrFormGroup)
	
	// 
	Type = TypeOf(StepOrIndexOrFormGroup);
	If Type = Type("Structure") Then
		StepDescription = StepOrIndexOrFormGroup;
	ElsIf Type = Type("Number") Then
		StepIndex = StepOrIndexOrFormGroup;
		If StepIndex < 0 Then
			Raise NStr("en = 'Attempt to go back from the first step.';");
		ElsIf StepIndex > WizardSettings.Steps.UBound() Then
			Raise NStr("en = 'Attempt to go next from the last step.';");
		EndIf;
		StepDescription = WizardSettings.Steps[StepIndex];
	Else
		StepFound = False;
		RequiredPageName = StepOrIndexOrFormGroup.Name;
		For Each StepDescription In WizardSettings.Steps Do
			If StepDescription.PageName = RequiredPageName Then
				StepFound = True;
				Break;
			EndIf;
		EndDo;
		If Not StepFound Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Step %1 is not found.';"),
				RequiredPageName);
		EndIf;
	EndIf; 
	
	// 
	WizardSettings.CurrentStep = StepDescription;
	
	// 
	SetVisibilityAvailability(ThisObject);
	OnActivateWizardStep();
	
EndProcedure

#Region WizardEvents

&AtClient
Procedure OnActivateWizardStep()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.NoSearchPerformedStep Then
		
		Items.Header.Enabled = True;
		
		// 
		FilterRulesPresentation = String(PrefilterComposer.Settings.Filter);
		If IsBlankString(FilterRulesPresentation) Then
			FilterRulesPresentation = NStr("en = 'All items';");
		EndIf;
		
		// 
		Conjunction = " " + NStr("en = 'AND';") + " ";
		RulesText = "";
		For Each Rule In SearchRules Do
			If Rule.Rule = "Equal" Then
				Comparison = Rule.AttributeRepresentation + " " + NStr("en = 'attributes are identical';");
			ElsIf Rule.Rule = "Like" Then
				Comparison = Rule.AttributeRepresentation + " " + NStr("en = 'attributes are similar';");
			Else
				Continue;
			EndIf;
			RulesText = ?(RulesText = "", "", RulesText + Conjunction) + Comparison;
		EndDo;
		If TakeAppliedRulesIntoAccount Then
			For Position = 1 To StrLineCount(AppliedRuleDetails) Do
				RuleRow = TrimAll(StrGetLine(AppliedRuleDetails, Position));
				If Not IsBlankString(RuleRow) Then
					RulesText = ?(RulesText = "", "", RulesText + Conjunction) + RuleRow;
				EndIf;
			EndDo;
		EndIf;
		If IsBlankString(RulesText) Then
			RulesText = NStr("en = 'No rules set';");
		EndIf;
		
		If HideInsignificantDuplicates Then
			RulesRow = NStr("en = 'hide duplicates that are marked for deletion and never referred';");
			RulesText = ?(RulesText = "", "", RulesText + Conjunction) + RulesRow;
		EndIf;
		
		SearchRulesPresentation = RulesText;
		
		// 
		Items.FilterRulesPresentation.Enabled = Not IsBlankString(DuplicatesSearchArea);
		Items.SearchRulesPresentation.Enabled = Not IsBlankString(DuplicatesSearchArea);
		
	ElsIf CurrentPage = Items.PerformSearchStep Then
		
		If Not IsTempStorageURL(CompositionSchemaAddress) Then
			Return; // 
		EndIf;
		Items.Header.Enabled = False;
		WizardSettings.ShowDialogBeforeClose = True;
		FindAndDeleteDuplicatesClient();
		
	ElsIf CurrentPage = Items.MainItemSelectionStep Then
		
		Items.Header.Enabled = True;
		Items.RetrySearch.Visible = True;
		ExpandDuplicatesGroup();
		
	ElsIf CurrentPage = Items.DeletionStep Then
		
		Items.Header.Enabled = False;
		WizardSettings.ShowDialogBeforeClose = True;
		FindAndDeleteDuplicatesClient();
		
	ElsIf CurrentPage = Items.SuccessfulDeletionStep Then
		
		Items.Header.Enabled = False;
		
		If PossibleDuplicateSelected Then
			Items.WizardStepBack.Title = NStr("en = 'New search';");
			Items.WizardStepBack.DefaultButton = True;
		Else
			Items.WizardStepBack.Title = NStr("en = 'Search again';");
			Items.WizardStepBack.DefaultButton = False;
		EndIf;
		
	ElsIf CurrentPage = Items.UnsuccessfulReplacementsStep Then
		
		Items.Header.Enabled = False;
		
	ElsIf CurrentPage = Items.DuplicatesNotFoundStep Then
		
		Items.Header.Enabled = True;
		If IsBlankString(DuplicatesSearchErrorDescription) Then
			Message = NStr("en = 'No duplicates found by the specified parameters.';");
		Else	
			Message = DuplicatesSearchErrorDescription;
		EndIf;	
		Items.DuplicatesNotFound.StatePresentation.Text = Message + Chars.LF 
			+ NStr("en = 'Edit the criteria and select Find duplicates.';");
		
	ElsIf CurrentPage = Items.ErrorOccurredStep Then
		
		Items.Header.Enabled = True;
		Items.DetailsRef.Visible = ValueIsFilled(Items.DetailsRef.ToolTip);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepNext()
	
	ClearMessages();
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	Step = WizardSettings.CurrentStep;// See AddWizardStep
	HandlerNextCompletion = New NotifyDescription("WizardStepNextCompletion", ThisObject);
	If CurrentPage = Items.NoSearchPerformedStep Then
		
		If IsBlankString(DuplicatesSearchArea) Then
			ShowMessageBox(, NStr("en = 'Select a search location';"));
			Return;
		EndIf;
		
		ExecuteNotifyProcessing(HandlerNextCompletion, Step.IndexOf + 1);
		
	ElsIf CurrentPage = Items.MainItemSelectionStep Then
		
		Items.RetrySearch.Visible = False;
		If ValueIsFilled(Step.WhenYouClickNext) Then
		
			Handler = New NotifyDescription(Step.WhenYouClickNext, ThisObject, 
							New Structure("CompletionHandler", HandlerNextCompletion));
			ExecuteNotifyProcessing(Handler, Step.IndexOf + 1);
		Else
			
			ExecuteNotifyProcessing(HandlerNextCompletion, Step.IndexOf + 1);
		EndIf;
		
		
	ElsIf CurrentPage = Items.UnsuccessfulReplacementsStep Then
		
		ExecuteNotifyProcessing(HandlerNextCompletion, Items.DeletionStep);
		
	ElsIf CurrentPage = Items.DuplicatesNotFoundStep Then
		
		ExecuteNotifyProcessing(HandlerNextCompletion, Items.PerformSearchStep);
		
	Else
		
		ExecuteNotifyProcessing(HandlerNextCompletion, Step.IndexOf + 1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepNextCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	GoToWizardStep1(Result);

EndProcedure

&AtClient
Procedure WizardStepBack()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.SuccessfulDeletionStep Then
		
		If PossibleDuplicateSelected Then
			PickSelectedUsageInstances(PossibleDuplicateSelectedType);
			DuplicatesSearchAreaSelectionCompletion(PossibleDuplicateSelectedType, Undefined);
			WizardStepNext();
		Else
			GoToWizardStep1(Items.NoSearchPerformedStep);
		EndIf;
		
	Else
		
		Step = WizardSettings.CurrentStep;// See AddWizardStep
		GoToWizardStep1(Step.IndexOf - 1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepCancel()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.PerformSearchStep
		Or CurrentPage = Items.DeletionStep Then
		WizardSettings.ShowDialogBeforeClose = False;
	EndIf;
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region EventsOfTheMainElementSelectionStep

&AtClient
Procedure StepSelectTheMainElementWhenYouClickNext(DescriptionOfTheNextStep, AdditionalParameters) Export

	HandlerParameters = New Structure("DescriptionOfTheNextStep, CompletionHandler", 
		DescriptionOfTheNextStep, AdditionalParameters.CompletionHandler);
	If ReturnedLessThanFound Then
		
		ResponseHandler1 = New NotifyDescription("StepSelectTheMainElementWhenYouClickNextCompletion", ThisObject, HandlerParameters);
		ShowQueryBox(
			ResponseHandler1, 
			NStr("en = 'Not all duplicates found are displayed. All duplicates found will be processed.
			|Start processing the duplicates?';"), QuestionDialogMode.YesNo);
	Else
			
		ExecuteNotifyProcessing(AdditionalParameters.CompletionHandler, DescriptionOfTheNextStep);
	EndIf;

EndProcedure

&AtClient         
Procedure StepSelectTheMainElementWhenYouClickNextCompletion(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
	
		ExecuteNotifyProcessing(
			AdditionalParameters.CompletionHandler, 
			AdditionalParameters.DescriptionOfTheNextStep);
	
	EndIf;

EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// 

&AtServer
Function DuplicatesDeletionSearchSettings()
	
	Result = New Structure;
	Result.Insert("TakeAppliedRulesIntoAccount", True);
	Result.Insert("DuplicatesSearchArea",        "");
	Result.Insert("DCSettings",                Undefined);
	Result.Insert("SearchRules",              Undefined);
	Result.Insert("DeletionMethod",             "Check");
	Result.Insert("HideInsignificantDuplicates", 	 True);
	Return Result;

EndFunction

&AtClient
Function FullFormName(ShortFormName)
	Names = StrSplit(FormName, ".");
	Return Names[0] + "." + Names[1] + ".Form." + ShortFormName;
EndFunction

&AtClient
Procedure OpenDuplicateForm(Val CurrentData)
	If CurrentData = Undefined Or Not ValueIsFilled(CurrentData.Ref) Then
		Return;
	EndIf;
	
	ShowValue(,CurrentData.Ref);
EndProcedure

&AtClient
Procedure ShowUsageInstances(SourceTree)
	ReferencesArrray = New Array;
	For Each DuplicatesGroup In SourceTree.GetItems() Do
		For Each TreeRow In DuplicatesGroup.GetItems() Do
			ReferencesArrray.Add(TreeRow.Ref);
		EndDo;
	EndDo;
	
	ReportParameters = New Structure;
	ReportParameters.Insert("Filter", New Structure("RefSet", ReferencesArrray));
	WindowMode = FormWindowOpeningMode.LockOwnerWindow;
	OpenForm("Report.SearchForReferences.Form", ReportParameters, ThisObject, , , , , WindowMode);
EndProcedure

&AtClient
Procedure ExpandDuplicatesGroup(Val DataString1 = Undefined)
	If DataString1 <> Undefined Then
		Items.FoundDuplicates.Expand(DataString1, True);
	EndIf;
	
	// 
	AllRows = Items.FoundDuplicates;
	For Each RowData In FoundDuplicates.GetItems() Do 
		AllRows.Expand(RowData.GetID(), True);
	EndDo;
EndProcedure

&AtClient
Procedure CollapseDuplicatesGroup(Val DataString1 = Undefined)
	If DataString1 <> Undefined Then
		Items.FoundDuplicates.Collapse(DataString1);
		Return;
	EndIf;
	
	// 
	AllRows = Items.FoundDuplicates;
	For Each RowData In FoundDuplicates.GetItems() Do 
		AllRows.Collapse(RowData.GetID());
	EndDo;
EndProcedure

&AtClient
Procedure SetMarksInTree(Tree, Check, CheckParent)
	
	RowItems = Tree.GetItems();
	For Each Item In RowItems Do
		Item.Check = Check;
		SetMarksInTree(Item, Check, False);
	EndDo;
	
	Parent = Tree.GetParent();
	If CheckParent And Parent <> Undefined Then 
		CheckParentMark(Parent);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckParentMark(Parent)
	
	ParentMark = True;
	RowItems = Parent.GetItems();
	For Each Item In RowItems Do
		If Not Item.Check Then
			ParentMark = False;
			Break;
		EndIf;
	EndDo;
	Parent.Check = ParentMark;
	
EndProcedure

&AtClient
Procedure EditCandidatesNotes(Val RowData)
	SetMarksDown(RowData);
	SetMarksUp(RowData);
EndProcedure

&AtClient
Procedure SetMarksDown(Val RowData)
	Value = RowData.Check;
	For Each Child In RowData.GetItems() Do
		Child.Check = Value;
		SetMarksDown(Child);
	EndDo;
EndProcedure

&AtClient
Procedure SetMarksUp(Val RowData)
	RowParent = RowData.GetParent();
	
	If RowParent <> Undefined Then
		AllTrue = True;
		NotAllFalse = False;
		
		For Each Child In RowParent.GetItems() Do
			AllTrue = AllTrue And (Child.Check = 1);
			NotAllFalse = NotAllFalse Or (Child.Check > 0);
		EndDo;
		
		If AllTrue Then
			RowParent.Check = 1;
		ElsIf NotAllFalse Then
			RowParent.Check = 2;
		Else
			RowParent.Check = 0;
		EndIf;
		
		SetMarksUp(RowParent);
	EndIf;
	
EndProcedure

&AtClient
Procedure MarkItemAsOriginal(Val RowData, Val Parent)
	For Each Child In Parent.GetItems() Do
		Child.Main = False;
	EndDo;
	RowData.Main = True;
	
	// 
	RowData.Check = 1;
	EditCandidatesNotes(RowData);
	
	// 
	Parent.Description = RowData.Description + " (" + Parent.Count + ")";
EndProcedure

&AtClient
Procedure UpdateFoundDuplicatesStateDetails()
	
	HasMarkedObjectsDeletionSubsystem = CommonClient.SubsystemExists(
		"StandardSubsystems.MarkedObjectsDeletion");
	
	If IsBlankString(DuplicatesSearchErrorDescription) Then
		LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Selected duplicates: %1 out of %2.';"),
			TotalFoundDuplicates, TotalItems);
	Else	
		LongDesc = DuplicatesSearchErrorDescription;
	EndIf;
	
	If HasMarkedObjectsDeletionSubsystem Then
	
		If DeletionMethod = "Check" Then
			ToolTipText = NStr("en = 'The selected items will be <a href = ""[Action]"">marked for deletion</a> and replaced with the original items (the original items are marked with an arrow icon).';");
			RowParameters = New Structure("Action", "DeletionMethod");
			ToolTipText = StringFunctionsClientServer.InsertParametersIntoString(ToolTipText, RowParameters);
		Else
			ToolTipText = NStr("en = 'The selected items will be <a href = ""[Action]"">deleted permanently</a> and replaced with the original items (the original items are marked with an arrow icon).';");
			RowParameters = New Structure("Action", "DeletionMethod");
			ToolTipText = StringFunctionsClientServer.InsertParametersIntoString(ToolTipText, RowParameters);
		EndIf;
		
	Else
		
		ToolTipText = NStr("en = 'The selected items will be marked for deletion and replaced with the original items, which are marked with an arrow.';");
		
	EndIf;
	FoundDuplicatesStateDetails = StringFunctionsClient.FormattedString(LongDesc + Chars.LF + ToolTipText);
		
EndProcedure

&AtServer
Function FilterComposerSettingsAddress()
	Return PutToTempStorage(PrefilterComposer.Settings, UUID);
EndFunction

&AtServer
Function SearchRulesSettingsAddress()
	Settings = New Structure;
	Settings.Insert("TakeAppliedRulesIntoAccount", TakeAppliedRulesIntoAccount);
	Settings.Insert("AllComparisonOptions", AllComparisonOptions);
	Settings.Insert("SearchRules", FormAttributeToValue("SearchRules"));
	Settings.Insert("HideInsignificantDuplicates", HideInsignificantDuplicates);

	Return PutToTempStorage(Settings);
EndFunction

&AtServer
Procedure UpdateFilterComposer(Val ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);
	DeleteFromTempStorage(ResultAddress);
	PrefilterComposer.LoadSettings(Result);
	PrefilterComposer.Refresh(DataCompositionSettingsRefreshMethod.Full);
	SaveUserSettingsSSL();
	
EndProcedure

&AtServer
Procedure UpdateSearchRules(Val ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);
	DeleteFromTempStorage(ResultAddress);
	TakeAppliedRulesIntoAccount = Result.TakeAppliedRulesIntoAccount;
	HideInsignificantDuplicates = Result.HideInsignificantDuplicates;
	ValueToFormAttribute(Result.SearchRules, "SearchRules");
	SaveUserSettingsSSL();
	
EndProcedure

&AtServer
Procedure InitializeFilterComposerAndRules(Val FormSettings)
	// 
	FilterRulesPresentation = "";
	SearchRulesPresentation = "";
	
	SettingsTable = GetFromTempStorage(SettingsAddress);
	SettingsTableRow = SettingsTable.Find(DuplicatesSearchArea, "FullName");
	If SettingsTableRow = Undefined Then
		DuplicatesSearchArea = "";
		Return;
	EndIf;
	
	MetadataObject = Common.MetadataObjectByFullName(DuplicatesSearchArea);
	
	// 
	CompositionSchema = New DataCompositionSchema;
	DataSource = CompositionSchema.DataSources.Add();
	DataSource.DataSourceType = "Local";
	
	DataSet = CompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Query = "SELECT " + AvailableFilterAttributes(MetadataObject) + " FROM " + DuplicatesSearchArea; // @query-part-1 @query-part-2
	DataSet.AutoFillAvailableFields = True;
	
	CompositionSchemaAddress = PutToTempStorage(CompositionSchema, UUID);
	
	PrefilterComposer.Initialize(New DataCompositionAvailableSettingsSource(CompositionSchema));
	
	// 
	RulesTable = FormAttributeToValue("SearchRules");
	RulesTable.Clear();
	
	AttributesToExclude = New Structure("DeletionMark, Ref, Predefined, PredefinedDataName, IsFolder");
	AddAttributesRules(RulesTable, AttributesToExclude, AllComparisonOptions, MetadataObject.StandardAttributes, FuzzySearch1);
	AddAttributesRules(RulesTable, AttributesToExclude, AllComparisonOptions, MetadataObject.Attributes, FuzzySearch1);
	
	// 
	FiltersImported = False;
	DCSettings = CommonClientServer.StructureProperty(FormSettings, "DCSettings");
	If TypeOf(DCSettings) = Type("DataCompositionSettings") Then
		
		For Cnt = -(DCSettings.Filter.Items.Count()-1) To 0 Do
			Filter = DCSettings.Filter.Items[-Cnt];
			If StrFind(Filter.Presentation, RepresentationOfTheSelectedPlaceOfUse()) > 0 Then
				CommonClientServer.DeleteFilterItems(DCSettings.Filter,, Filter.Presentation);
			EndIf;	
		EndDo;
		
		PrefilterComposer.LoadSettings(DCSettings);
		FiltersImported = True;
	EndIf;
	
	RulesAreImported = False;
	SavedRules = CommonClientServer.StructureProperty(FormSettings, "SearchRules");
	If TypeOf(SavedRules) = Type("ValueTable") Then
		RulesAreImported = True;
		For Each SavedRule In SavedRules Do
			Rule = RulesTable.Find(SavedRule.Attribute, "Attribute");
			If Rule <> Undefined
				And Rule.ComparisonOptions.FindByValue(SavedRule.Rule) <> Undefined Then
				Rule.Rule = SavedRule.Rule;
			EndIf;
		EndDo;
	EndIf;
	
	// 
	// 
	If Not FiltersImported Then
		CommonClientServer.SetFilterItem(	PrefilterComposer.Settings.Filter,
			"DeletionMark", False, DataCompositionComparisonType.Equal,, False);
	EndIf;
		
	// 	
	If IsTempStorageURL(SelectedUsageInstancesAddress) Then
		
		SelectedUsageInstances = GetFromTempStorage(SelectedUsageInstancesAddress);
		FilterGroup = Undefined;
		If SelectedUsageInstances.FilterValue.Count() > 0 Then
		
			FilterGroup = CommonClientServer.CreateFilterItemGroup(
				PrefilterComposer.Settings.Filter.Items,	
				SelectedUsageInstances.FilterPresentation,
				DataCompositionFilterItemsGroupType.OrGroup);
		
		EndIf;
			
		For Each FilterValueAttribute In SelectedUsageInstances.FilterValue Do
			CommonClientServer.SetFilterItem(FilterGroup,
				FilterValueAttribute.Key, FilterValueAttribute.Value,
				DataCompositionComparisonType.InList, "", True);	
		EndDo;
		
		DeleteFromTempStorage(SelectedUsageInstancesAddress);
		SelectedUsageInstancesAddress = "";
	
	EndIf;
		
	// 
	If Not RulesAreImported Then
		Rule = RulesTable.Find("Description", "Attribute");
		If Rule <> Undefined Then
			ValueToCompare = ?(FuzzySearch1, "Like", "Equal");
			If Rule.ComparisonOptions.FindByValue(ValueToCompare) <> Undefined Then
				Rule.Rule = ValueToCompare;
			EndIf;
		EndIf;
	EndIf;
	
	// 
	AppliedRuleDetails = Undefined;
	If SettingsTableRow.EventDuplicateSearchParameters Then
		AppliedParameters = DuplicateObjectsDetection.DuplicatesSearchParameters(RulesTable, PrefilterComposer);
		MetadataObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		MetadataObjectManager.DuplicatesSearchParameters(AppliedParameters);
		
		// 
		AppliedRuleDetails = "";
		For Each LongDesc In AppliedParameters.ComparisonRestrictions Do
			AppliedRuleDetails = AppliedRuleDetails + Chars.LF + LongDesc.Presentation;
		EndDo;
		AppliedRuleDetails = TrimAll(AppliedRuleDetails);
	EndIf;
	
	PrefilterComposer.Refresh(DataCompositionSettingsRefreshMethod.Full);
	
	RulesTable.Sort("AttributeRepresentation");
	ValueToFormAttribute(RulesTable, "SearchRules");
	
	DuplicatesSearchAreaID = Catalogs.MetadataObjectIDs
		.FindByAttribute("FullName", DuplicatesSearchArea);
	DuplicatesSearchAreaType = TypeOf(Common.ObjectAttributeValue(DuplicatesSearchAreaID, "EmptyRefValue"));
	ProcessedObjectsTypes = New TypeDescription(
		CommonClientServer.ValueInArray(DuplicatesSearchAreaType));
	
	If FormSettings = Undefined Then
		SaveUserSettingsSSL();
	EndIf;
EndProcedure

&AtServer
Procedure OnCreateAtServerDataInitialization(FormSettings)
	TakeAppliedRulesIntoAccount = FormSettings.TakeAppliedRulesIntoAccount;
	DuplicatesSearchArea = FormSettings.DuplicatesSearchArea;
	DeletionMethod = FormSettings.DeletionMethod;
	HideInsignificantDuplicates = FormSettings.HideInsignificantDuplicates;
	
	SettingsTable = DuplicateObjectsDetection.MetadataObjectsSettings();
	SettingsAddress = PutToTempStorage(SettingsTable, UUID);
	
	ChoiceList = Items.DuplicatesSearchArea.ChoiceList;
	ImageCache = New Map;
	For Each TableRow In SettingsTable Do
		PictureOfTheView = ImageOfTheMetadataType(ImageCache, TableRow.Kind);
		ChoiceList.Add(TableRow.FullName, TableRow.ListPresentation, , PictureOfTheView);
	EndDo;
	
	AllComparisonOptions.Add("Equal",   NStr("en = 'Match';"));
	AllComparisonOptions.Add("Like", NStr("en = 'Fuzzy match';"));
EndProcedure

&AtServer
Procedure SaveUserSettingsSSL()
	FormSettings = New Structure;
	FormSettings.Insert("TakeAppliedRulesIntoAccount", TakeAppliedRulesIntoAccount);
	FormSettings.Insert("DuplicatesSearchArea", DuplicatesSearchArea);
	FormSettings.Insert("DCSettings", PrefilterComposer.Settings);
	FormSettings.Insert("SearchRules", SearchRules.Unload());
	FormSettings.Insert("HideInsignificantDuplicates", HideInsignificantDuplicates);
	Common.CommonSettingsStorageSave(FormName, "", FormSettings);
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	InformationTextColor       = Metadata.StyleItems.NoteText.Value;
	ErrorInformationTextColor = Metadata.StyleItems.ErrorNoteText.Value;
	UnavailableDataColor     = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	
	ConditionalAppearanceItems = ConditionalAppearance.Items;
	ConditionalAppearanceItems.Clear();
	
	// 
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Ref");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	AppearanceFilter.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("Text", "");
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesCount");
	
	// 
		
	// 
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Main");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", False);
	AppearanceItem.Appearance.SetParameterValue("Show", False);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesCheck");
			
	// 
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Ref");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Filled;
	AppearanceFilter.RightValue = True;
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Count");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = 0;
	
	AppearanceItem.Appearance.SetParameterValue("Text", NStr("en = '-';"));
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicatesCount");
	
	// 
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("FoundDuplicates.Check");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = 0;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", UnavailableDataColor);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("FoundDuplicates");
	
	// 
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("PossibleDuplicates.Processed");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("PossibleDuplicatesMetadataObjectName");
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("PossibleDuplicatesSources");

EndProcedure

&AtServer
Function DuplicatesPurgeParameters()
	
	DeletionParameters = New Map;
	BatchIndex = 0;
	DuplicatesTree = FormAttributeToValue("FoundDuplicates");
	SearchFilter = New Structure("Main", True);
	
	For Each DuplicatesGroups In DuplicatesTree.Rows Do
		ReplacementPairs = New Map;
		Original = DuplicatesGroups.Rows.FindRows(SearchFilter)[0].Ref;
		For Each Duplicate1 In DuplicatesGroups.Rows Do
			If Duplicate1.Check = 1 And Duplicate1.Ref <> Original Then
				ReplacementPairs[Duplicate1.Ref] = Original;
			EndIf;
		EndDo;
		ReplacementsCount = ReplacementPairs.Count();
		If ReplacementsCount = 0 Then
			Continue;
		EndIf;
		
		SelectedCountTotal = SelectedCountTotal + ReplacementsCount;
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("TakeAppliedRulesIntoAccount", TakeAppliedRulesIntoAccount);
		ProcedureParameters.Insert("DeletionMethod", DeletionMethod);
		ProcedureParameters.Insert("ReplacementPairs", ReplacementPairs);
		ServerCallParameters = New Array;
		ServerCallParameters.Add(ProcedureParameters);
		DeletionParameters.Insert(BatchIndex, ServerCallParameters);
		BatchIndex = BatchIndex + 1;
	EndDo;
	
	Return DeletionParameters;
	
EndFunction

&AtServerNoContext
Function AvailableFilterAttributes(MetadataObject)
	AttributesArray = New Array;
	For Each AttributeMetadata1 In MetadataObject.StandardAttributes Do
		If Not AttributeMetadata1.Type.ContainsType(Type("ValueStorage")) Then
			AttributesArray.Add(AttributeMetadata1.Name);
		EndIf
	EndDo;
	For Each AttributeMetadata1 In MetadataObject.Attributes Do
		If Not AttributeMetadata1.Type.ContainsType(Type("ValueStorage")) Then
			AttributesArray.Add(AttributeMetadata1.Name);
		EndIf
	EndDo;
	Return StrConcat(AttributesArray, ",");
EndFunction

&AtServerNoContext
Procedure AddAttributesRules(RulesTable, Val AttributesToExclude, Val AllComparisonOptions, Val AttributesCollection, Val FuzzySearchAvailable)
	
	For Each AttributeMetadata In AttributesCollection Do
		
		If AttributesToExclude.Property(AttributeMetadata.Name) Then
			Continue;
		EndIf;
		
		ComparisonOptions = ComparisonOptionsForType(AttributeMetadata.Type, AllComparisonOptions, FuzzySearchAvailable);
		If ComparisonOptions = Undefined Then
			Continue;
		EndIf;
		
		RulesRow = RulesTable.Add();
		RulesRow.Attribute          = AttributeMetadata.Name;
		RulesRow.ComparisonOptions = ComparisonOptions;
		RulesRow.AttributeRepresentation = AttributeMetadata.Presentation();
	EndDo;
	
EndProcedure

&AtServerNoContext
Function ComparisonOptionsForType(Val AvailableTypes, Val AllComparisonOptions, Val FuzzySearchAvailable) 
	
	IsStorage = AvailableTypes.ContainsType(Type("ValueStorage"));
	If IsStorage Then 
		// 
		Return Undefined;
	EndIf;
	
	IsString = AvailableTypes.ContainsType(Type("String"));
	IsFixedString = IsString And AvailableTypes.StringQualifiers <> Undefined 
		And AvailableTypes.StringQualifiers.Length <> 0;
		
	If IsString And Not IsFixedString Then
		// 
		Return Undefined;
	EndIf;
	
	Result = New ValueList;
	FillPropertyValues(Result.Add(), AllComparisonOptions[0]);		// Matches
	
	If FuzzySearchAvailable And IsString Then
		FillPropertyValues(Result.Add(), AllComparisonOptions[1]);	// 
	EndIf;
		
	Return Result;
EndFunction

&AtServerNoContext
Function ImageOfTheMetadataType(ImageCache, Kind)

	Picture = ImageCache[Kind];
	If Picture = Undefined Then
	
		Picture = PictureLib[Kind];
		ImageCache.Insert(Kind, Picture);
	
	EndIf;

	Return Picture;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

&AtClient
Procedure FindAndDeleteDuplicatesClient()
	
	ReportsToSend = New Map;
	
	TimeConsumingOperation = FindAndDeleteDuplicates();
	If TimeConsumingOperation = Undefined Then
		WizardSettings.ShowDialogBeforeClose = False;
		GoToWizardStep1(Items.MainItemSelectionStep);
		Return;
	EndIf;	
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	WaitSettings.OutputProgressBar = True;
	WaitSettings.ExecutionProgressNotification = New NotifyDescription("FindAndRemoveDuplicatesProgress", ThisObject);
	Handler = New NotifyDescription("FindAndDeleteDuplicatesCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function FindAndDeleteDuplicates()
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("TakeAppliedRulesIntoAccount", TakeAppliedRulesIntoAccount);
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	If CurrentPage = Items.PerformSearchStep Then
		
		Items.Searching.StatePresentation.Text = NStr("en = 'Searching for duplicates…';");

		ProcedureName = FormAttributeToValue("Object").Metadata().FullName() + ".ObjectModule.BackgroundSearchForDuplicates";
		MethodDescription = NStr("en = 'Duplicate cleaner: Find duplicates';");
		ProcedureParameters.Insert("DuplicatesSearchArea",     DuplicatesSearchArea);
		ProcedureParameters.Insert("MaxDuplicates", 1500);
		SearchRulesArray = New Array;
		For Each Rule In SearchRules Do
			SearchRulesArray.Add(New Structure("Attribute, Rule", Rule.Attribute, Rule.Rule));
		EndDo;
		ProcedureParameters.Insert("SearchRules", SearchRulesArray);
		ProcedureParameters.Insert("CompositionSchema", GetFromTempStorage(CompositionSchemaAddress));
		ProcedureParameters.Insert("PrefilterComposerSettings", PrefilterComposer.Settings);
		ProcedureParameters.Insert("HideInsignificantDuplicates", HideInsignificantDuplicates);
		
		StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		StartSettings1.BackgroundJobDescription = MethodDescription;
		
		Return TimeConsumingOperations.ExecuteInBackground(ProcedureName, ProcedureParameters, StartSettings1);
		
	ElsIf CurrentPage = Items.DeletionStep Then
		
		DeletionParameters = DuplicatesPurgeParameters();
		If DeletionParameters.Count() = 0 Then
			Common.MessageToUser(NStr("en = 'Select at least one duplicate group.';"),, "FoundDuplicates");
			Return Undefined;
		EndIf;
		
		Items.Deletion.StatePresentation.Text = NStr("en = 'Processing duplicates…';");
		
		ProcedureName = FormAttributeToValue("Object").Metadata().FullName() + ".ObjectModule.BackgroundDuplicateDeletion";
		MethodDescription = NStr("en = 'Duplicate cleaner: Delete duplicates';");
		
		StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		StartSettings1.BackgroundJobDescription = MethodDescription;
		
		BatchesCount = DeletionParameters.Count();
		Return TimeConsumingOperations.ExecuteFunctionInMultipleThreads(ProcedureName, StartSettings1, DeletionParameters);
		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Incorrect operation: %1.';"), String(CurrentPage));
	EndIf;
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.LongRunningOperationNewState
//  AdditionalParameters - Undefined
//
&AtClient
Procedure FindAndRemoveDuplicatesProgress(Result, AdditionalParameters) Export
	
	If Result.Status <> "Running"
	 Or Result.Progress = Undefined Then
		Return;
	EndIf;
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	If CurrentPage = Items.PerformSearchStep Then
		
		Message = NStr("en = 'Searching for duplicates…';");
		If Result.Progress.Text = "CalculateUsageInstances" Then 
			Message = NStr("en = 'Searching for duplicate occurrences…';");
		ElsIf Result.Progress.Percent > 0 Then
			Message = Message + " " 
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = '(%1 locations found)';"), Result.Progress.Percent);
		EndIf;
		Items.Searching.StatePresentation.Text = Message;
		
	ElsIf CurrentPage = Items.DeletionStep Then
		
		ProgressParameters = Undefined;
		If Result.Progress.Property("AdditionalParameters", ProgressParameters)
			And ProgressParameters = "ProgressofMultithreadedProcess" Then
			Return;
		EndIf;
		
		If Not IsBlankString(Result.Progress.Text) Then
			If ProgressParameters = Undefined Then
				Message = Result.Progress.Text;
			Else
				Message = ProgressText(ProgressParameters, Result.Progress.Text);
			EndIf;
		Else	
			Message = NStr("en = 'Processing duplicates…';");
		EndIf;
		
		Items.Deletion.StatePresentation.Text = Message;
		
	EndIf;
	
EndProcedure

&AtServer
Function ProgressText(Val ProgressParameters, Val SourceProgressText)
	
	ThisIsReplacement = StrStartsWith(SourceProgressText, NStr("en = 'Replacing duplicates';"));
	ProgressAttributeName = ?(ThisIsReplacement, "ProcessedItemsCount", "DeletedItemsCount");
	Filter = New Structure;
	Filter.Insert("SessionNumber", ProgressParameters.SessionNumber);
	TableRows = DeletionProgress.FindRows(Filter);
	If TableRows.Count() = 0 Then
		TableRow = DeletionProgress.Add();
		TableRow.SessionNumber = ProgressParameters.SessionNumber;
		PreviousProcessedCount = 0;
	Else
		TableRow = TableRows[0];
		PreviousProcessedCount = TableRow[ProgressAttributeName];
	EndIf;
	TableRow[ProgressAttributeName] = ProgressParameters.ProcessedItemsCount;
	ProgressToAdd = (ProgressParameters.ProcessedItemsCount - PreviousProcessedCount);
	If ThisIsReplacement Then
		ProcessedTotalCount = ProcessedTotalCount + ProgressToAdd;
	Else
		DeletedTotalCount = DeletedTotalCount + ProgressToAdd;
	EndIf;
	
	ProgressText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Replacing duplicates… Processed (%1 out of %2)';"),
		ProcessedTotalCount,
		SelectedCountTotal);
	If DeletionMethod = "Directly" Then
		ProgressText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1
			|Deleting duplicates... Processed (%2 out of %3)';"),
			ProgressText,
			DeletedTotalCount,
			SelectedCountTotal);
	EndIf;
	
	Return ProgressText;
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure FindAndDeleteDuplicatesCompletion(Result, AdditionalParameters) Export
	WizardSettings.ShowDialogBeforeClose = False;
	Activate();
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If Result = Undefined Then 
		Return;
	EndIf;
	
	If Result.Status <> "Completed2" Then
		// 
		If CurrentPage = Items.PerformSearchStep Then
			Brief1 = NStr("en = 'Cannot find duplicates. Reason:';");
		ElsIf CurrentPage = Items.DeletionStep Then
			Brief1 = NStr("en = 'Cannot delete the duplicates. Reason:';");
		EndIf;
		Brief1 = Brief1 + Chars.LF + Result.BriefErrorDescription;
		More = Brief1 + Chars.LF + Chars.LF + Result.DetailErrorDescription;
		Items.ErrorTextLabel.Title = Brief1;
		Items.DetailsRef.ToolTip    = More;
		GoToWizardStep1(Items.ErrorOccurredStep);
		Return;
	EndIf;
	
	Step = WizardSettings.CurrentStep;// See AddWizardStep
	If CurrentPage = Items.PerformSearchStep Then
		TotalFoundDuplicates = FillDuplicatesSearchResults(Result.ResultAddress);
		TotalItems = TotalFoundDuplicates;
		If TotalFoundDuplicates > 0 Then
			UpdateFoundDuplicatesStateDetails();
			GoToWizardStep1(Step.IndexOf + 1);
		Else
			GoToWizardStep1(Items.DuplicatesNotFoundStep);
		EndIf;
	ElsIf CurrentPage = Items.DeletionStep Then
		Success = FillDuplicatesDeletionResults(Result.ResultAddress);
		CommonClient.NotifyObjectsChanged(ProcessedObjectsTypes);
		If Success = True Then
			// 
			RefreshPossibleDuplicatesStatus();
			GoToWizardStep1(Step.IndexOf + 1);
		Else
			// 
			GoToWizardStep1(Items.UnsuccessfulReplacementsStep);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function FillDuplicatesSearchResults(Val ResultAddress)
	
	// 
	Data = GetFromTempStorage(ResultAddress); // See DataProcessorObject.DuplicateObjectsDetection.DuplicatesGroups
	DuplicatesSearchErrorDescription = Data.ErrorDescription;
	
	FoundDuplicatesTree = FormAttributeToValue("FoundDuplicates");
	TreeItems = FoundDuplicatesTree.Rows;
	TreeItems.Clear();
	
	UsageInstances = Data.UsageInstances;
	DuplicatesTable      = Data.DuplicatesTable;
	ReturnedLessThanFound = Data.ReturnedLessThanFound;
	
	RowsFilter = New Structure("Parent");
	InstancesFilter  = New Structure("Ref");
	
	TotalFoundDuplicates = 0;
	
	DuplicatesGroups = DuplicatesTable.FindRows(RowsFilter);
	For Each DuplicateGroup In DuplicatesGroups Do
		RowsFilter.Parent = DuplicateGroup.Ref;
		GroupItems1 = DuplicatesTable.FindRows(RowsFilter);
		
		TreeGroup = TreeItems.Add();
		TreeGroup.Count = GroupItems1.Count();
		TreeGroup.Check = 1;
		TreeGroup.PictureNumber = -1;
		
		OriginalItem = Undefined; // 
		MaxUsageInstances = -1;
		
		For Each Item In GroupItems1 Do
			TreeRow = TreeGroup.Rows.Add();
			FillPropertyValues(TreeRow, Item, "Ref, Code, Description");
			
			InstancesFilter.Ref = Item.Ref;
			UsageInstancesCount = UsageInstances.FindRows(InstancesFilter).Count();
			
			TreeRow.Count = UsageInstancesCount;
			TreeRow.Check = ?(Item.DeletionMark And UsageInstancesCount = 0, 0, 1);
			TreeRow.PictureNumber = ?(Item.DeletionMark, 4, 3);
			
			If MaxUsageInstances < UsageInstancesCount Then
				If OriginalItem <> Undefined Then
					OriginalItem.Main = False;
				EndIf;
				OriginalItem = TreeRow;
				MaxUsageInstances   = UsageInstancesCount;
				OriginalItem.Main = True;
			EndIf;
			
			TotalFoundDuplicates = TotalFoundDuplicates + 1;
		EndDo;
		
		
		// 
		GroupMark = False;
		For Each TreeRow In TreeGroup.Rows Do
			If Not TreeRow.Main And TreeRow.Check Then
				GroupMark = True;
				Break;
			EndIf;
		EndDo;
		
		TreeGroup.Check = GroupMark;
		TreeGroup.Description = OriginalItem.Description + " (" + TreeGroup.Count + ")";
		TreeGroup.Rows.Sort("Description");
	EndDo;
	
	ValueToFormAttribute(FoundDuplicatesTree, "FoundDuplicates");
	
	ProbableDuplicateUsageInstances.Clear();
	Items.CurrentDuplicatesGroupDetails.Title = NStr("en = 'No duplicates found';");
	
	If IsTempStorageURL(UsageInstancesAddress) Then
		DeleteFromTempStorage(UsageInstancesAddress);
	EndIf;
	UsageInstancesAddress = PutToTempStorage(UsageInstances, UUID);
	Return TotalFoundDuplicates;
	
EndFunction

&AtServer
Function FillDuplicatesDeletionResults(Val ResultAddress)
	// 
	BackgroundExecutionResult = GetFromTempStorage(ResultAddress); // See Common.ReplaceReferences
	ErrorsTable = GetFromTempStorage(BackgroundExecutionResult[0].ResultAddress);
	For BatchIndex = 1 To BatchesCount - 1 Do
		BatchResultAddress = BackgroundExecutionResult[BatchIndex].ResultAddress;
		TableOfBatchErrors = GetFromTempStorage(BatchResultAddress);
		
		CommonClientServer.SupplementTable(TableOfBatchErrors, ErrorsTable);
	EndDo;
	ProcessedTotalCount = 0;
	DeletedTotalCount = 0;
	SelectedCountTotal = 0;
	BatchesCount = 0;
	DeletionProgress.Clear();
	
	If IsTempStorageURL(ReplacementResultAddress) Then
		DeleteFromTempStorage(ReplacementResultAddress);
	EndIf;
	
	CompletedWithoutErrors = ErrorsTable.Count() = 0;
	LastCandidate  = Undefined;
	
	If CompletedWithoutErrors Then
		ProcessedItemsTotal = 0; 
		MainItemsTotal   = 0;
		For Each DuplicatesGroup In FoundDuplicates.GetItems() Do
			If DuplicatesGroup.Check Then
				For Each Candidate In DuplicatesGroup.GetItems() Do
					If Candidate.Main Then
						LastCandidate = Candidate.Ref;
						ProcessedItemsTotal   = ProcessedItemsTotal + 1;
						MainItemsTotal     = MainItemsTotal + 1;
					ElsIf Candidate.Check Then 
						ProcessedItemsTotal = ProcessedItemsTotal + 1;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		
		If MainItemsTotal = 1 Then
			// 
			If LastCandidate = Undefined Then
				FoundDuplicatesStateDetails = New FormattedString(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'All %1 duplicates have been merged.';"),
						ProcessedItemsTotal));
			Else
				LastCandidateAsString = Common.SubjectString(LastCandidate);
				FoundDuplicatesStateDetails = New FormattedString(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'All %1 duplicates have been merged
							|into %2.';"),
						ProcessedItemsTotal, LastCandidateAsString));
			EndIf;
		Else
			// 
			FoundDuplicatesStateDetails = New FormattedString(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'All %1 duplicates have been merged.
						|Number of resulted items: %2.';"),
					ProcessedItemsTotal,
					MainItemsTotal));
		EndIf;
	EndIf;
	
	UnprocessedDuplicates.GetItems().Clear();
	UnprocessedItemsUsageInstances.Clear();
	ProbableDuplicateUsageInstances.Clear();
	
	If CompletedWithoutErrors Then
		FillPossibleDuplicates();
		FoundDuplicates.GetItems().Clear();
		HasImportantPossibleDuplicates = PossibleDuplicates.FindRows(New Structure("RelationDegree",2)).Count() > 0; 
		DisplayedRelationship = ?(HasImportantPossibleDuplicates, 2, 1);		
		SetPossibleDuplicatesFilter(ThisObject);
		Return True;
	EndIf;
	
	// 
	ReplacementResultAddress = PutToTempStorage(ErrorsTable, UUID);
	
	// 
	ValueToFormAttribute(FormAttributeToValue("FoundDuplicates"), "UnprocessedDuplicates");
	
	// 
	Filter = New Structure("Ref");
	Parents = UnprocessedDuplicates.GetItems();
	ParentPosition = Parents.Count() - 1;
	While ParentPosition >= 0 Do
		Parent = Parents[ParentPosition];
		
		Children = Parent.GetItems();
		ChildPosition = Children.Count() - 1;
		MainChild = Children[0];	// 
		
		While ChildPosition >= 0 Do
			Child = Children[ChildPosition];
			
			If Child.Main Then
				MainChild = Child;
				Filter.Ref = Child.Ref;
				Child.Count = ErrorsTable.FindRows(Filter).Count();
				
			ElsIf ErrorsTable.Find(Child.Ref, "Ref") = Undefined Then
				// 
				Children.Delete(Child);
				
			Else
				Filter.Ref = Child.Ref;
				Child.Count = ErrorsTable.FindRows(Filter).Count();
				
			EndIf;
			
			ChildPosition = ChildPosition - 1;
		EndDo;
		
		ChildrenCount1 = Children.Count();
		If ChildrenCount1 = 1 And Children[0].Main Then
			Parents.Delete(Parent);
		Else
			Parent.Count = ChildrenCount1 - 1;
			Parent.Description = MainChild.Description + " (" + ChildrenCount1 + ")";
		EndIf;
		
		ParentPosition = ParentPosition - 1;
	EndDo;
	
	Return False;
EndFunction

&AtServer
Procedure FillPossibleDuplicates()
	
	ObjectToProcessID = DuplicatesSearchAreaID;
	MetadataObjectToProcess = Common.MetadataObjectByID(ObjectToProcessID);
	
	ProcessedPossibleDuplicate = PossibleDuplicates.FindRows(
		New Structure("MetadataObjectType", MetadataObjectToProcess.FullName()));
	If ProcessedPossibleDuplicate.Count() > 0 Then
		ProcessedPossibleDuplicate[0].Processed = True;	
	EndIf;
		
	UsageInstances = GetFromTempStorage(UsageInstancesAddress);
	ExpectedPossibleDuplicates = GeneratePossibleDuplicates(UsageInstances);
	
	PossibleDuplicatesSearchFilter = GeneratePossibleDuplicatesFilter(FormAttributeToValue("FoundDuplicates"));
	TypeOfObjectToProcess = TypeOf(Common.ObjectAttributeValue(ObjectToProcessID, 
		"EmptyRefValue"));
	
	For Each UsageInstance1 In ExpectedPossibleDuplicates Do
		
		If MetadataObjectToProcess = UsageInstance1 
			Or UsageInstance1 = Undefined Then
			
			Continue;
		EndIf;
		
		KeysLinks = KeysMetadataLinks(TypeOfObjectToProcess, UsageInstance1);
		If KeysLinks.Count() > 0 Then
			AddPossibleDuplicate(MetadataObjectToProcess, UsageInstance1, KeysLinks, PossibleDuplicatesSearchFilter); 	
		EndIf;
		
	EndDo;
	
	SelectedProcessedRows = PossibleDuplicates.FindRows(New Structure("Processed, Selected", True, True));
	For Each RowPossibleDuplicates In SelectedProcessedRows Do
		RowPossibleDuplicates.Selected = False;
	EndDo;

EndProcedure

&AtServerNoContext
Function GeneratePossibleDuplicatesFilter(DuplicatesTree)

	Filter = New Array;
	For Each DuplicatesGroup In DuplicatesTree.Rows Do
	
		For Each DuplicateRow In DuplicatesGroup.Rows Do
		
			Filter.Add(DuplicateRow.Ref);
		
		EndDo;
	
	EndDo;
	Return Filter;

EndFunction


&AtServerNoContext
Function GeneratePossibleDuplicates(UsageInstances)

	TypesToExclude = DuplicateObjectsDetection.TypesToExcludeFromPossibleDuplicates();
	
	ExpectedUsageInstances = New Array;
	For Each UsageInstance1 In UsageInstances Do
		
		UsageInstanceType = TypeOf(UsageInstance1.Data);
		If UsageInstance1.AuxiliaryData 
			Or UsageInstance1.IsInternalData
			Or Not Common.IsReference(UsageInstanceType)
			Or TypesToExclude.Find(UsageInstanceType) <> Undefined Then
			
			Continue;	
		EndIf;
		
		MetadataDetails = ?(UsageInstance1.Metadata <> Undefined, UsageInstance1.Metadata, UsageInstance1.Data.Metadata());
		
		MetadataCompatible = Common.IsCatalog(MetadataDetails)
			Or Common.IsChartOfCharacteristicTypes(MetadataDetails);

		If Not MetadataCompatible Then
			Continue;
		EndIf;
		
		If ExpectedUsageInstances.Find(MetadataDetails) = Undefined Then
			ExpectedUsageInstances.Add(MetadataDetails);
		EndIf;
	
	EndDo;
	
	Return ExpectedUsageInstances;

EndFunction

&AtServer
Procedure AddPossibleDuplicate(MetadataObjectToProcess, UsageInstance1, KeysLinks, Filter = Undefined)
	
	UsageInstancePresentation = UsageInstance1.Presentation();
	FullUsageInstanceName = UsageInstance1.FullName();
	
	CurrentSequenceNumber = ?(PossibleDuplicates.Count(),PossibleDuplicates[PossibleDuplicates.Count() - 1].Order + 1, 0);
	DuplicatesFilter = New Structure("MetadataObjectType", FullUsageInstanceName);
	AddedDuplicates = PossibleDuplicates.FindRows(DuplicatesFilter);
	
	If AddedDuplicates.Count() > 0 Then
		
		PossibleDuplicate = AddedDuplicates[0];
		If PossibleDuplicate.Sources.FindByValue(FullUsageInstanceName) <> Undefined Then
			PossibleDuplicate.Sources.Add(MetadataObjectToProcess.Presentation());	
		EndIf;
		
		PossibleDuplicatesFilterInformation = GetFromTempStorage(PossibleDuplicate.FilterAddress);
				
	Else	
		
		PossibleDuplicate = PossibleDuplicates.Add();	
		PossibleDuplicate.MetadataObjectName = UsageInstancePresentation;
		PossibleDuplicate.MetadataObjectType = FullUsageInstanceName;
		PossibleDuplicate.Order = CurrentSequenceNumber;
		PossibleDuplicate.Processed = False;
		
		Sources = New ValueList;
		Sources.Add(MetadataObjectToProcess.Presentation());
		PossibleDuplicate.Sources = Sources;
		
		PossibleDuplicatesFilterInformation = New Map;
		
	EndIf;	
	
	PossibleDuplicate.RelationDegree = ?(KeysLinks.Find(2, "RelationDegree") <> Undefined, 2, 1);
	PossibleDuplicate.SourcesPresentation = StrConcat(PossibleDuplicate.Sources.UnloadValues(), ", ");
	
	// 
	// 		
	For Each KeysLinks In KeysLinks Do
	
		PossibleDuplicatesFilter = PossibleDuplicatesFilterInformation[KeysLinks.Name];
		If PossibleDuplicatesFilter = Undefined Then
			PossibleDuplicatesFilterInformation.Insert(KeysLinks.Name, Filter);
		Else
			CommonClientServer.SupplementArray(PossibleDuplicatesFilter, Filter);
			PossibleDuplicatesFilterInformation.Insert(KeysLinks.Name, PossibleDuplicatesFilter);
		EndIf;
	
	EndDo;	
	
	PossibleDuplicate.FilterAddress = PutToTempStorage(PossibleDuplicatesFilterInformation, UUID);

EndProcedure

// 
// 
// Returns:
//   - Number - 
//    
//    
//    
//
&AtServerNoContext
Function KeysMetadataLinks(Val TypeOfObjectToProcess, Val UsageInstance1)
	
	Result = New ValueTable;
	Result.Columns.Add("Name");
	Result.Columns.Add("RelationDegree");
			
	For Each UsageInstanceAttribute In UsageInstance1.Attributes Do
		
		If UsageInstanceAttribute.Type.Types().Find(TypeOfObjectToProcess) <> Undefined Then
			MetadataLink = Result.Add();
			MetadataLink.Name = UsageInstanceAttribute.Name;
			MetadataLink.RelationDegree = 1;
		EndIf;
		
	EndDo;
	
	For Each UsageInstanceAttribute In UsageInstance1.StandardAttributes Do
		
		If UsageInstanceAttribute.Type.Types().Find(TypeOfObjectToProcess) <> Undefined Then
			MetadataLink = Result.Add();
			MetadataLink.Name = UsageInstanceAttribute.Name;
			MetadataLink.RelationDegree = 2;
		EndIf;
		
	EndDo;
		
	Return Result;

EndFunction

&AtClient
Procedure AfterConfirmCancelJob(Response, ExecutionParameters) Export
	If Response = DialogReturnCode.Abort Then
		WizardSettings.ShowDialogBeforeClose = False;
		Close();
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Description of the settings button in the wizard.
//
// Returns:
//  Structure - :
//    * Title         - String -  the title of the button.
//    * ToolTip         - String -  hint for the button.
//    * Visible         - Boolean - 
//    * Enabled       - Boolean - 
//    * DefaultButton - Boolean -  when True, the button will be the main button of the form. The default value is False.
//    * ExtendedTooltip - Structure:
//    ** Title - String
//
&AtClientAtServerNoContext
Function WizardButton()
	Result = New Structure;
	Result.Insert("Title", "");
	Result.Insert("ToolTip", "");
	
	Result.Insert("Enabled", True);
	Result.Insert("Visible", True);
	Result.Insert("DefaultButton", False);
	
	Return Result;
EndFunction

// Parameters:
//  WizardButton - See WizardButton
//  LongDesc - String
//
&AtClientAtServerNoContext
Procedure UpdateWizardButtonProperties(WizardButton, LongDesc)
	
	FillPropertyValues(WizardButton, LongDesc);
	WizardButton.ExtendedTooltip.Title = LongDesc.ToolTip;
	
EndProcedure

&AtServer
Procedure PickSelectedUsageInstances(Val SelectedType)

	Var FilterAddress;
	SelectedUsageInstances = New Structure("FilterPresentation, FilterValue","", New Structure);
	SelectedDuplicate = PossibleDuplicates.FindRows(New Structure("MetadataObjectType", SelectedType));
		
	SelectedUsageInstances.FilterPresentation = RepresentationOfTheSelectedPlaceOfUse();
	
	If SelectedDuplicate.Count() > 0 Then
	
		SelectedDuplicate = SelectedDuplicate[0];
		FilterAddress = SelectedDuplicate.FilterAddress;
		
	EndIf;
	
	If IsTempStorageURL(FilterAddress) Then
	
		Filter = GetFromTempStorage(FilterAddress);	
		For Each FilterValueAttribute In Filter Do
			
			FilterValue = New ValueList;
			FilterValue.LoadValues(FilterValueAttribute.Value);
			SelectedUsageInstances.FilterValue.Insert(FilterValueAttribute.Key, FilterValue);	
		
		EndDo;
	
	EndIf;
	
	SelectedUsageInstancesAddress = PutToTempStorage(SelectedUsageInstances, UUID);
	
EndProcedure

// Used as a selection identifier.
&AtServer
Function RepresentationOfTheSelectedPlaceOfUse()
	Return NStr("en = 'Items that can include duplicates';");
EndFunction

#EndRegion