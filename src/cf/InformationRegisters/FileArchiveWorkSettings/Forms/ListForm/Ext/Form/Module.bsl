///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Not Parameters.AllowedToOpenForm Then
		ErrorText = NStr("en = 'Cannot open this form directly.'");
		Raise ErrorText;
	EndIf;
	
	FillObjectTypesInValueTree();

	ManualStartOfFileTransferIsAvailable = Not Common.DataSeparationEnabled() And Common.SubsystemExists("StandardSubsystems.ScheduledJobs");
	
	Items.GroupStateOfFileTransfer.Visible = ManualStartOfFileTransferIsAvailable;
	Items.MoveFiles.Visible = ManualStartOfFileTransferIsAvailable;

	If ManualStartOfFileTransferIsAvailable Then

		Items.LabelCurrentState.Title = GetPresentationOfCurrentStateOfOperationsOfFileTransfer();

	EndIf;

EndProcedure
#EndRegion

#Region FormTableItemsEventHandlersMetadataObjectsTree

&AtClient
Procedure MetadataObjectsTreeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)

	Cancel = True;
	If Not Copy Then
		AttachIdleHandler("AddSettingForWorkingWithFileArchive", 0.1, True);
	EndIf;	

EndProcedure

&AtClient
Procedure MetadataObjectsTreeOnActivateField(Item)

	Item.CurrentItem.ReadOnly = Not FormTableGetItemAvailabilityForEditing(Item);

EndProcedure

&AtClient
Procedure MetadataObjectsTreeActionOnChange(Item)

	WriteCurrentSettings();

EndProcedure

&AtClient
Procedure MetadataObjectsTreeTransferToFileArchiveInDaysOnChange(Item)

	If Not SettingIsFilledInCorrectly() Then
		Return;		
	EndIf;
	
	WriteCurrentSettings();

EndProcedure

&AtClient
Procedure MetadataObjectsTreeActionClearing(Item, StandardProcessing)

	StandardProcessing = False;	
	SetActionForSelectedObjects(PredefinedValue("Enum.ActionsInFileArchiveWorkSettings.NotTransferToArchive"));

EndProcedure

&AtClient
Procedure MetadataObjectsTreeBeforeRowChange(Item, Cancel)

	Cancel = Not FormTableGetItemAvailabilityForEditing(Item); // ACC:144 - The function returns a Boolean value.

EndProcedure

&AtClient
Procedure MetadataObjectsTreeChoiceProcessing(Item, ValueSelected, StandardProcessing)

	StandardProcessing = False;
	AddSettingsByOwner(ValueSelected);

EndProcedure

&AtClient
Procedure MetadataObjectsTreeBeforeDeleteRow(Item, Cancel)

	Cancel = True;

	SettingToDelete = MetadataObjectsTree.FindByID(Items.MetadataObjectsTree.CurrentRow);
	If SettingToDelete <> Undefined Then

		SettingToDeleteParent = SettingToDelete.GetParent();

		If SettingToDeleteParent <> Undefined And SettingToDeleteParent.DetailedInfoAvailable Then

			QueryText = NStr("en = 'If you delete the setting, you will not be able
				|to use the rules defined in it. Continue?'");
			CallbackDescription = New CallbackDescription("DeleteSettingItemCompletion", ThisObject);
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No, NStr("en = 'Warning'"));
			Return;

		EndIf;

	EndIf;

	MessageText = NStr("en = 'Advanced file archive settings are unavailable for this object.'");
	ShowMessageBox(, MessageText);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveFiles(Command)
	CancelBackgroundJob1();
	RunScheduledJob();

	AttachIdleHandler("CheckBackgroundJobExecution", 2, True);

EndProcedure

#EndRegion

#Region Private
&AtServer
Procedure FillObjectTypesInValueTree()

	FileArchiveWorkSettings = InformationRegisters.FileArchiveWorkSettings.CurrentSettingsForWorkingWithFileArchive();

	MOTree = FormAttributeToValue("MetadataObjectsTree");
	MOTree.Rows.Clear();

	MetadataCatalogs = Metadata.Catalogs;

	TypesTable = New ValueTable;
	TypesTable.Columns.Add("FileOwner");
	TypesTable.Columns.Add("FileOwnerType");
	TypesTable.Columns.Add("FileOwnerName");
	TypesTable.Columns.Add("IsFile", New TypeDescription("Boolean"));
	TypesTable.Columns.Add("DetailedInfoAvailable"  , New TypeDescription("Boolean"));

	For Each Catalog In MetadataCatalogs Do

		If Catalog.Attributes.Find("FileOwner") = Undefined Then
			Continue;
		EndIf;

		FilesOwnersTypes = Catalog.Attributes.FileOwner.Type.Types();
		For Each OwnerType In FilesOwnersTypes Do
			
			OwnerMetadata = Metadata.FindByType(OwnerType);
			
			NewRow = TypesTable.Add();
			NewRow.FileOwner = OwnerType;
			NewRow.FileOwnerType = Catalog;
			NewRow.FileOwnerName = OwnerMetadata.FullName();
			NewRow.DetailedInfoAvailable = True;
			
			If Not StrEndsWith(Catalog.Name, FilesOperationsInternal.CatalogSuffixAttachedFiles()) Then
				NewRow.IsFile = True;
			EndIf;
			
		EndDo;
		
	EndDo;

	AllCatalogs = Catalogs.AllRefsType();

	AllDocuments = Documents.AllRefsType();
	CatalogsNode = Undefined;
	DocumentsNode = Undefined;
	BusinessProcessesNode = Undefined;

	CommonSettingsNode = MOTree.Rows.Add();
	CommonSettingsNode.ObjectDescriptionSynonym	= NStr("en = 'General settings'");	

	CommonSettings = FileArchiveWorkSettings.FindRows(New Structure("FileOwner, FileOwnerType", Undefined, Undefined));
	If CommonSettings.Count() > 0 Then

		CommonSettingsNode.TransferToFileArchiveInDays	= CommonSettings[0].TransferToFileArchiveInDays;

	EndIf;

	FilesOwners = New Array;
	For Each Type In TypesTable Do
		
		FileOwnerType = Type.FileOwnerType; // MetadataObjectCatalog
		If StrStartsWith(FileOwnerType.Name, "Delete")
			Or FilesOwners.Find(Type.FileOwnerName) <> Undefined Then
			Continue;
		EndIf;

		FilesOwners.Add(Type.FileOwnerName);

		If AllCatalogs.ContainsType(Type.FileOwner) Then
			If CatalogsNode = Undefined Then
				CatalogsNode = MOTree.Rows.Add();
				CatalogsNode.ObjectDescriptionSynonym = NStr("en = 'Catalogs'");
			EndIf;
			NewTableRow = CatalogsNode.Rows.Add();
		ElsIf AllDocuments.ContainsType(Type.FileOwner) Then
			If DocumentsNode = Undefined Then
				DocumentsNode = MOTree.Rows.Add();
				DocumentsNode.ObjectDescriptionSynonym = NStr("en = 'Documents'");
			EndIf;
			NewTableRow = DocumentsNode.Rows.Add();
		ElsIf BusinessProcesses.AllRefsType().ContainsType(Type.FileOwner) Then
			If BusinessProcessesNode = Undefined Then
				BusinessProcessesNode = MOTree.Rows.Add();
				BusinessProcessesNode.ObjectDescriptionSynonym = NStr("en = 'Business processes'");
			EndIf;
			NewTableRow = BusinessProcessesNode.Rows.Add();
		EndIf;
		ObjectMetadata = Metadata.FindByType(Type.FileOwner);
		NewTableRow.FileOwner = Common.MetadataObjectID(Type.FileOwner);
		NewTableRow.FileOwnerType = Common.MetadataObjectID(Type.FileOwnerType);
		NewTableRow.ObjectDescriptionSynonym = ObjectMetadata.Synonym;
		NewTableRow.IsFile = Type.IsFile;
		NewTableRow.DetailedInfoAvailable = Type.DetailedInfoAvailable;
		
		ObjectID		= Common.MetadataObjectID(Type.FileOwner);
		DetailedSettings	= FileArchiveWorkSettings.FindRows(New Structure(
										"OwnerID, IsFile", ObjectID, Type.IsFile));

		If DetailedSettings.Count() > 0 Then
			For Each Setting In DetailedSettings Do
				DetalizedSetting = NewTableRow.Rows.Add();
				DetalizedSetting.FileOwner						= Setting.FileOwner;
				DetalizedSetting.FileOwnerType					= Setting.FileOwnerType;
				DetalizedSetting.ObjectDescriptionSynonym		= Setting.FileOwner;
				DetalizedSetting.Action							= Setting.Action;
				DetalizedSetting.TransferToFileArchiveInDays	= Setting.TransferToFileArchiveInDays;
				DetalizedSetting.IsFile							= Setting.IsFile;
			EndDo;
		EndIf;		
		
		FoundSettings = FileArchiveWorkSettings.FindRows(New Structure("FileOwner, IsFile", NewTableRow.FileOwner, Type.IsFile));

		If FoundSettings.Count() > 0 Then
			NewTableRow.Action							= FoundSettings[0].Action;
			NewTableRow.TransferToFileArchiveInDays	= FoundSettings[0].TransferToFileArchiveInDays;
		Else
			NewTableRow.Action							= Enums.ActionsInFileArchiveWorkSettings.NotTransferToArchive;
			NewTableRow.TransferToFileArchiveInDays	= 0;
		EndIf;
	EndDo;
	
	For Each TopLevelNode In MOTree.Rows Do
		TopLevelNode.Rows.Sort("ObjectDescriptionSynonym");
	EndDo;
	ValueToFormAttribute(MOTree, "MetadataObjectsTree");
	
EndProcedure

&AtClient
Function FormTableGetItemAvailabilityForEditing(Item)

	Result = True;

	If Item.CurrentItem.Name = "MetadataObjectsTreeObjectDescriptionSynonym" Then
		Result = False;
	ElsIf Item.CurrentData.FileOwnerType = Undefined Then
		Result = Item.CurrentItem.Name = "MetadataObjectsTreeTransferToFileArchiveInDays";
	EndIf;

	Return Result;

EndFunction

&AtClient
Procedure AddFileOwner(SelectedOwners, ObjectTreeRow)
	If TypeOf(ObjectTreeRow.FileOwner) = Type("CatalogRef.MetadataObjectIDs")
	   Or TypeOf(ObjectTreeRow.FileOwner) = Type("CatalogRef.ExtensionObjectIDs")
	   Or ObjectTreeRow.FileOwner = Undefined Then
		SubordinateRows = ObjectTreeRow.GetItems();
		For Each TreeRow In SubordinateRows Do
			AddFileOwner(SelectedOwners, TreeRow);
		EndDo;
	Else
		If SelectedOwners.Find(ObjectTreeRow.FileOwner) = Undefined Then
			SelectedOwners.Add(ObjectTreeRow.FileOwner);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure DeleteSettingItemCompletion(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		ClearSettingData();
	EndIf;

EndProcedure

&AtClient
Procedure AddSettingForWorkingWithFileArchive()

	TreeRow = Items.MetadataObjectsTree.CurrentData;

	If Not TreeRow.DetailedInfoAvailable Then
		MessageText = NStr("en = 'Advanced file archive settings are unavailable for this object.'");
		ShowMessageBox(, MessageText);
		Return;
	EndIf;

	ChoiceFormParameters = New Structure;

	ChoiceFormParameters.Insert("ChoiceFoldersAndItems"			, FoldersAndItemsUse.FoldersAndItems);
	ChoiceFormParameters.Insert("CloseOnChoice"				, True);
	ChoiceFormParameters.Insert("CloseOnOwnerClose"	, True);
	ChoiceFormParameters.Insert("MultipleChoice"				, True);
	ChoiceFormParameters.Insert("ChoiceMode"						, True);

	ChoiceFormParameters.Insert("WindowOpeningMode"		, FormWindowOpeningMode.LockOwnerWindow);
	ChoiceFormParameters.Insert("SelectGroups"				, True);
	ChoiceFormParameters.Insert("UsersGroupsSelection"	, True);

	ChoiceFormParameters.Insert("AdvancedPick"		, True);
	ChoiceFormParameters.Insert("PickFormHeader"	, NStr("en = 'Select settings items'"));

	// Excluding already existing settings from the selection list.
	ExistingSettings1 = TreeRow.GetItems();
	FixedSettings = New DataCompositionSettings;
	SettingItem = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	SettingItem.LeftValue = New DataCompositionField("Ref");
	SettingItem.ComparisonType = DataCompositionComparisonType.NotInList;
	ExistingSettingsList = New Array;
	For Each Setting In ExistingSettings1 Do
		ExistingSettingsList.Add(Setting.FileOwner);
	EndDo;
	SettingItem.RightValue = ExistingSettingsList;
	SettingItem.Use = True;
	SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	ChoiceFormParameters.Insert("FixedSettings", FixedSettings);

	OpenForm(ChoiceFormPath(TreeRow.FileOwner), ChoiceFormParameters, Items.MetadataObjectsTree);

EndProcedure

&AtServer
Function ChoiceFormPath(Val FileOwner)

	MetadataObject = Common.MetadataObjectByID(FileOwner);
	Return MetadataObject.FullName() + ".ChoiceForm";

EndFunction

&AtServer
Procedure AddSettingsByOwner(Val ValueSelected)

	RowOwner = MetadataObjectsTree.FindByID(Items.MetadataObjectsTree.CurrentRow);


	RegisterEntryStructure = InformationRegisters.FileArchiveWorkSettings.StructureOfRecord();
	FillPropertyValues(RegisterEntryStructure, RowOwner);
	InformationRegisters.FileArchiveWorkSettings.AddRecord(RegisterEntryStructure);

	OwnerElement = RowOwner.GetItems();
	For Each Setting In ValueSelected Do

		RegisterEntryStructure = InformationRegisters.FileArchiveWorkSettings.StructureOfRecord();
		RegisterEntryStructure.FileOwner						= Setting;
		RegisterEntryStructure.FileOwnerType					= RowOwner.FileOwnerType;
		RegisterEntryStructure.Action							= Enums.ActionsInFileArchiveWorkSettings.NotTransferToArchive;
		RegisterEntryStructure.TransferToFileArchiveInDays	= RowOwner.TransferToFileArchiveInDays;
		RegisterEntryStructure.IsFile								= RowOwner.IsFile;

		InformationRegisters.FileArchiveWorkSettings.AddRecord(RegisterEntryStructure);

		DetalizedSetting = OwnerElement.Add();
		FillPropertyValues(DetalizedSetting, RegisterEntryStructure);
		DetalizedSetting.ObjectDescriptionSynonym = Setting;
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearSettingData()

	SettingToDelete = MetadataObjectsTree.FindByID(Items.MetadataObjectsTree.CurrentRow);

	InformationRegisters.FileArchiveWorkSettings.DeleteRecord(SettingToDelete.FileOwner, SettingToDelete.FileOwnerType);

	SettingsItemParent = SettingToDelete.GetParent();
	If SettingsItemParent <> Undefined Then
		SettingsItemParent.GetItems().Delete(SettingToDelete);
	Else
		MetadataObjectsTree.GetItems().Delete(SettingToDelete);
	EndIf;

EndProcedure

&AtServer
Procedure SetActionForSelectedObjects(Val Action)

	For Each RowID In Items.MetadataObjectsTree.SelectedRows Do
		TreeItem = MetadataObjectsTree.FindByID(RowID);
		If TreeItem.GetParent() = Undefined Then
			For Each TreeChildItem In TreeItem.GetItems() Do
				SetActionOfSelectedObjectWithRecursion(TreeChildItem, Action);
			EndDo;
		Else
			SetActionOfSelectedObjectWithRecursion(TreeItem, Action);
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure SetActionOfSelectedObjectWithRecursion(SelectedObject, Val Action)

	SetSelectedObjectAction(SelectedObject, Action);
	For Each ChildObject In SelectedObject.GetItems() Do
		SetSelectedObjectAction(ChildObject, Action);
	EndDo;

EndProcedure

&AtServer
Procedure SetSelectedObjectAction(SelectedObject, Val Action)

	SelectedObject.Action = Action;
	SaveCurrentObjectSettings(
		SelectedObject.FileOwner,
		SelectedObject.FileOwnerType,
		Action,
		SelectedObject.TransferToFileArchiveInDays,
		SelectedObject.IsFile);

EndProcedure

&AtClient
Procedure WriteCurrentSettings()

	CurrentData = Items.MetadataObjectsTree.CurrentData;
	SaveCurrentObjectSettings(
		CurrentData.FileOwner,
		CurrentData.FileOwnerType,
		CurrentData.Action,
		CurrentData.TransferToFileArchiveInDays,
		CurrentData.IsFile);

EndProcedure

&AtServer
Procedure SaveCurrentObjectSettings(Val FileOwner, Val FileOwnerType, Val Action, Val TransferToFileArchiveInDays, Val IsFile)

	RegisterEntryStructure = InformationRegisters.FileArchiveWorkSettings.StructureOfRecord();
	RegisterEntryStructure.FileOwner						= FileOwner;
	RegisterEntryStructure.FileOwnerType					= FileOwnerType;
	RegisterEntryStructure.Action							= Action;
	RegisterEntryStructure.TransferToFileArchiveInDays	= TransferToFileArchiveInDays;
	RegisterEntryStructure.IsFile								= IsFile;
	
	InformationRegisters.FileArchiveWorkSettings.AddRecord(RegisterEntryStructure);

EndProcedure

&AtServer
Procedure RunScheduledJob()

	If Not Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		Return;
	EndIf;
	
	ModuleScheduledJobsInternal = Common.CommonModule("ScheduledJobsInternal");
	
	RaiseIfNoAdministrationRights(ModuleScheduledJobsInternal);

	ScheduledJobMetadata1 = Metadata.ScheduledJobs.TransferringFilesBetweenOperationalStorageAndFileArchive;

	Filter = New Structure;
	MethodName = ScheduledJobMetadata1.MethodName;
	Filter.Insert("MethodName", MethodName);
	Filter.Insert("State", BackgroundJobState.Active);
	BackgroundFileTransferTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	If BackgroundFileTransferTasks.Count() > 0 Then
		BackgroundJobIdentifier = BackgroundFileTransferTasks[0].UUID;
	Else

		ScheduledJob = ScheduledJobs.FindPredefined(ScheduledJobMetadata1); // ACC:453 - Used only in shared mode.

		ExecutionParameters = ModuleScheduledJobsInternal.ExecuteScheduledJobManually(ScheduledJob.UUID);		

		BackgroundJobIdentifier = New UUID(ExecutionParameters.BackgroundJobIdentifier);

		Items.LabelCurrentState.Title = GetPresentationOfCurrentStateOfOperationsOfFileTransfer(BackgroundJobIdentifier)

	EndIf;
EndProcedure

&AtClient
Procedure CancelBackgroundJob1()
	CancelJobExecution(BackgroundJobIdentifier);
	BackgroundJobIdentifier = "";
EndProcedure

&AtServerNoContext
Procedure CancelJobExecution(Val BackgroundJobIdentifier)

	If ValueIsFilled(BackgroundJobIdentifier) And Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then

		RaiseIfNoAdministrationRights();

		TimeConsumingOperations.CancelJobExecution(BackgroundJobIdentifier);
	EndIf;
EndProcedure

&AtClient
Function SettingIsFilledInCorrectly()

	Result = True;

	CurrentData = Items.MetadataObjectsTree.CurrentData;

	If CurrentData.FileOwner = Undefined And CurrentData.FileOwnerType = Undefined Then
		If CurrentData.TransferToFileArchiveInDays = 0 Then

			Result = False;

			CurrentData.TransferToFileArchiveInDays = GetCurrentDefaultSettingValue();

			MessageText = NStr("en = 'General file storage settings cannot be empty.
									|The previous value has been restored.'");
			ShowMessageBox(,MessageText);

		EndIf;
	EndIf;

	Return Result;	

EndFunction

&AtServerNoContext
Function GetCurrentDefaultSettingValue()

	Return InformationRegisters.FileArchiveWorkSettings.GetNumberOfDaysOfStorageFromDefaultSetting();

EndFunction

&AtServerNoContext
Function GetPresentationOfCurrentStateOfOperationsOfFileTransfer(Val BackgroundJobIdentifier = Undefined)
	
	If Not Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		Return "";
	EndIf;

	RaiseIfNoAdministrationRights();

	InformationForFormingView = New Structure;
	InformationForFormingView.Insert("State"	, Undefined);
	InformationForFormingView.Insert("Begin"		, Date(1,1,1));
	InformationForFormingView.Insert("End"		, Date(1,1,1));	

	If BackgroundJobIdentifier = Undefined Then

		ScheduledJobMetadata1 = Metadata.ScheduledJobs.TransferringFilesBetweenOperationalStorageAndFileArchive;

		Filter = New Structure;
		Filter.Insert("MethodName", ScheduledJobMetadata1.MethodName);
		Filter.Insert("State", BackgroundJobState.Active);
		BackgroundFileTransferTasks = BackgroundJobs.GetBackgroundJobs(Filter);
		
		If BackgroundFileTransferTasks.Count() > 0 Then
			FillPropertyValues(InformationForFormingView, BackgroundFileTransferTasks[0]);
		Else

			Filter.Delete("State");

			BackgroundFileTransferTasks = BackgroundJobs.GetBackgroundJobs(Filter);

			If BackgroundFileTransferTasks.Count() > 0 Then
				LastBackgroundJob = BackgroundFileTransferTasks[0];
				For Each BackgroundJob In BackgroundFileTransferTasks Do
					If LastBackgroundJob.End < BackgroundJob.End Then
						LastBackgroundJob = BackgroundJob;
					EndIf;
				EndDo;

				FillPropertyValues(InformationForFormingView, LastBackgroundJob);
			EndIf;	
		EndIf;
	Else

		FoundBackgroundJob = BackgroundJobs.FindByUUID(BackgroundJobIdentifier);

		If FoundBackgroundJob <> Undefined Then

			FillPropertyValues(InformationForFormingView, FoundBackgroundJob);
		EndIf;
	EndIf;

	Return GetPresentationOfStateOfBackgroundJobExecution(InformationForFormingView);

EndFunction

&AtServerNoContext
Function GetPresentationOfStateOfBackgroundJobExecution(BackgroundJobStateInformation)

	Result = "";

	If BackgroundJobStateInformation.State = Undefined Then

		Result = NStr("en = 'No info'");

	ElsIf BackgroundJobStateInformation.State = BackgroundJobState.Active Then

		Result = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'In progress. Started at %1'"), 
																			Format(BackgroundJobStateInformation.Begin, "DLF=DT"));

	Else

		Result = StringFunctionsClientServer.SubstituteParametersToString("%1 %2", 
																			BackgroundJobStateInformation.State, 
																			Format(BackgroundJobStateInformation.End, "DLF=DT"));

	EndIf;

	Return Result;

EndFunction

&AtClient
Procedure CheckBackgroundJobExecution()
	If ValueIsFilled(BackgroundJobIdentifier) And Not IsJobCompleted(BackgroundJobIdentifier) Then
		AttachIdleHandler("CheckBackgroundJobExecution", 5, True);
	Else
		Items.LabelCurrentState.Title = GetPresentationOfCurrentStateOfOperationsOfFileTransfer(BackgroundJobIdentifier);
		BackgroundJobIdentifier = "";
	EndIf;
EndProcedure

&AtServerNoContext
Function IsJobCompleted(Val BackgroundJobIdentifier)

	Result = True;
	
	JobCompletingResult = TimeConsumingOperations.JobCompleted(BackgroundJobIdentifier, True);
	
	If JobCompletingResult.Status = "Running" Then
		Result = False;
	EndIf;

	Return Result;
EndFunction

&AtServerNoContext
Procedure RaiseIfNoAdministrationRights(Val ModuleScheduledJobsInternal = Undefined)
	
	If ModuleScheduledJobsInternal = Undefined Then
		ModuleScheduledJobsInternal = Common.CommonModule("ScheduledJobsInternal");
	EndIf;
	
	ModuleScheduledJobsInternal.RaiseIfNoAdministrationRights();
	
EndProcedure

#EndRegion