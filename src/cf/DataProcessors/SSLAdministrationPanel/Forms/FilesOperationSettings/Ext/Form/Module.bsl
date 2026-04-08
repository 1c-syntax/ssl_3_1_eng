///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

// If the "FileOperations" subsystem is not integrated, delete the form from the configuration.
// 

#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	BinaryDataStoresAreAvailable = WorkingWithServerFileArchive.BinaryDataStoresAreAvailable();

	FileStorageMethodCustomizeSelectionList();

	MaxFileSize = FilesOperations.MaxFileSizeCommon() / (1024*1024);
	MaxDataAreaFileSize = FilesOperations.MaxFileSize() / (1024*1024);
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	If DataSeparationEnabled Then
		Items.MaxFileSize.MaxValue = MaxFileSize;
	EndIf;
	
	DenyUploadFilesByExtension = ConstantsSet.DenyUploadFilesByExtension;
	
	ParametersOfFilesStorageInIB = FilesOperationsInVolumesInternal.FilesStorageParametersInInfobase();
	If ParametersOfFilesStorageInIB <> Undefined Then
		IBFilesExtensions = ParametersOfFilesStorageInIB.FilesExtensions;
		MaxFileSizeInIB = ParametersOfFilesStorageInIB.MaximumSize / (1024*1024);
	EndIf;
	
	FilesOperationsInternal.FillListWithFilesTypes(Items.IBFilesExtensions.ChoiceList);
	
	IsSystemAdministrator = Users.IsFullUser(, True);
	Items.FilesStorageManagement.Visible = IsSystemAdministrator;
	Items.FilesVolumesManagementGroup.Visible = IsSystemAdministrator;
	Items.FilesSizeManagementInIBGroup.Visible = IsSystemAdministrator;
	Items.CommonParametersForAllDataAreas.Visible = IsSystemAdministrator And DataSeparationEnabled;
	Items.TextFilesExtensionsListGroup.Visible = Not DataSeparationEnabled;
	Items.IBFilesExtensionsManagementGroup.Visible = IsSystemAdministrator;
	
	If IsSystemAdministrator Then
		Items.GroupDeduplication.Visible = ConstantsSet.FilesStorageMethod <> "InVolumesOnHardDrive" And Not IsDeduplicationCompleted();
		FilesStorageMethodValue = ConstantsSet.FilesStorageMethod;
		ConfigureSettingsOfStorageInVolumesAvailability();
		UseFileArchive = ConstantsSet.UseFileArchive;
	Else
		Items.GroupDeduplication.Visible = False;
	EndIf;

	UseOfFileArchiveIsAvailable = IsSystemAdministrator And WorkingWithServerFileArchive.FileArchiveIsAvailable();
	Items.FileArchiveGroup.Visible = UseOfFileArchiveIsAvailable;
	If UseOfFileArchiveIsAvailable Then
		SetAvailabilityOfFileArchiveManagementSettings();
	EndIf;

	SetAvailability();
	
	ApplicationSettingsOverridable.FilesOperationSettingsOnCreateAtServer(ThisObject);
	
	If Common.IsMobileClient() Then
		
		Items.IndentFilesSizeInIB.Visible = False;
		Items.IndentIBFilesExtensions.Visible = False;
		Items.MaxFileSizeInIB.SpinButton = False;
		Items.IBFilesExtensions.TitleLocation = FormItemTitleLocation.Top;
		Items.TextFilesExtensionsList.TitleLocation = FormItemTitleLocation.Top;
		Items.FilesExtensionsListDocumentDataAreas.TitleLocation = FormItemTitleLocation.Top;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_ConstantsSet" And Source = "AllowAccessToInternetServices" Then
		SetAvailability("AllowAccessToInternetServices");
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilesStorageMethodOnChange(Item)

	If ConstantsSet.FilesStorageMethod = FilesStorageMethodValue Then
		Return;
	EndIf;
	
	ConstantsSet.StoreFilesInVolumesOnHardDrive = ThisIsWayToStoreFilesOnDisk(ConstantsSet.FilesStorageMethod);

	NotificationProcessing = New CallbackDescription(
		"FilesStorageMethodOnChangeCompletion", ThisObject, Item);

	If ThisIsWayToStoreFilesOnDisk(FilesStorageMethodValue)
		And ConstantsSet.StoreFilesInVolumesOnHardDrive Then
		
		RunCallback(NotificationProcessing, DialogReturnCode.OK);
		Return;
	EndIf;

	Try

		RequestsForPermissionToUseExternalResources = PermissionRequestsToUseExternalResourcesOfFilesStorageVolumes(
			ConstantsSet.StoreFilesInVolumesOnHardDrive);

		If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
			ModuleSafeModeManagerClient.ApplyExternalResourceRequests(
				RequestsForPermissionToUseExternalResources, ThisObject, NotificationProcessing);
		Else
			RunCallback(NotificationProcessing, DialogReturnCode.OK);
		EndIf;

	Except

		ConstantsSet.FilesStorageMethod = FilesStorageMethodValue;
		ConstantsSet.StoreFilesInVolumesOnHardDrive = ThisIsWayToStoreFilesOnDisk(FilesStorageMethodValue);
		Raise;

	EndTry;		
	
EndProcedure

&AtClient
Procedure CreateSubdirectoriesWithOwnersNamesOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure IBFilesExtensionsOnChange(Item)
	
	OnChangeSettingsOfFilesStorageInIB();
	
EndProcedure

&AtClient
Procedure IBFilesExtensionsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	IBFilesExtensions = FilesOperationsInternalClient.ExtensionsByFileType(ValueSelected);
	OnChangeSettingsOfFilesStorageInIB();
	
EndProcedure

&AtClient
Procedure MaxFileSizeInIBOnChange(Item)
	
	OnChangeSettingsOfFilesStorageInIB();
	
EndProcedure

&AtClient
Procedure DenyUploadFilesByExtensionOnChange(Item)
	
	If Not DenyUploadFilesByExtension Then
		
		Notification = New CallbackDescription(
			"ProhibitFilesImportByExtensionAfterConfirm", ThisObject, New Structure("Item", Item));
		UsersInternalClient.ShowSecurityWarning(Notification,
			UsersInternalClientServer.SecurityWarningKinds().OnChangeDeniedExtensionsList);
		Return;
		
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure SynchronizeFilesOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure DeniedDataAreaExtensionsListOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure MaxDataAreaFileSizeOnChange(Item)
	
	If MaxDataAreaFileSize = 0 Then
		
		MessageText = NStr("en = 'File size limit is required.'");
		CommonClient.MessageToUser(MessageText, ,"MaxDataAreaFileSize");
		Return;
		
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure FilesExtensionsListDocumentDataAreasOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure TextFilesExtensionsListOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

#Region CommonParametersForAllDataAreas

&AtClient
Procedure MaxFileSizeOnChange(Item)
	
	If MaxFileSize = 0 Then
		
		MessageText = NStr("en = 'File size limit is required.'");
		CommonClient.MessageToUser(MessageText, ,"MaxFileSize");
		Return;
		
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure DeniedExtensionsListOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure FilesExtensionsListOpenDocumentOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

#EndRegion

#Region FileArchiveWorkParameters

&AtClient
Procedure UseFileArchiveOnChange(Item)

	Attachable_OnChangeAttribute(Item);

EndProcedure

&AtClient
Procedure TextInformingUserAboutUnavailabilityOfFileInArchiveOnChange(Item)

	Attachable_OnChangeAttribute(Item);

EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CatalogFiles(Command)
	
	OpenForm("Catalog.Files.ListForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure CatalogFileStorageVolumes(Command)

	TypeOfFileStorageVolume = CommonClient.PredefinedItem("Enum.TypesOfFileStorage.OperationalStorage");
	OpenFileStorageVolumeCatalogListFormWithSelectionByTypeOfFileStorageVolume(ThisObject, TypeOfFileStorageVolume);

EndProcedure

&AtClient
Procedure FilesSynchronizationSetup(Command)
	
	OpenForm("InformationRegister.FileSynchronizationSettings.ListForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure FileTransfer(Command)
	
	FilesOperationsInternalClient.MoveFiles();
	
EndProcedure

&AtClient
Async Procedure StartDeduplication(Command)
	
	QuestionTitle = NStr("en = 'File deduplication'");
	QuestionTemplate = NStr("en = 'With file deduplication, you can save up to 30% of infobase space by removing duplicate files stored in the application (the ""Infobase"" storage option). The process takes from minutes to hours, depending on the number of files, and can be paused and resumed at any time. All newly added files are automatically stored as a single instance.
	 |
	 |During deduplication, the infobase size may increase significantly. Therefore, before initiating the process, ensure that the device hosting the infobase has at least %1 MB of free space and back up the infobase. After completion, compress the infobase for the deduplication to take effect.
	 |
	 |Do you want to start file deduplication?'");
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(QuestionTemplate, FilesSizeInInfobase());
	Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No, QuestionTitle);
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	TimeConsumingOperation = StartDeduplicationAtServer();
	CallbackOnCompletion = New CallbackDescription("FinishDeduplication", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.Title = NStr("en = 'Deduplicating files'");
	IdleParameters.OutputProgressBar = True;
	IdleParameters.CancelButtonTitle = NStr("en = 'Cancel'");
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
EndProcedure

&AtClient
Procedure CatalogOfFileStorageVolumesArchived(Command)

	TypeOfFileStorageVolume = CommonClient.PredefinedItem("Enum.TypesOfFileStorage.ArchivalStorage");
	OpenFileStorageVolumeCatalogListFormWithSelectionByTypeOfFileStorageVolume(ThisObject, TypeOfFileStorageVolume);

EndProcedure

&AtClient
Procedure SettingUpWorkWithFileArchive(Command)

	FormParameters = New Structure;
	FormParameters.Insert("AllowedToOpenForm", True);
	
	OpenForm("InformationRegister.FileArchiveWorkSettings.ListForm", FormParameters, ThisObject);

EndProcedure
#EndRegion

#Region Private

&AtClient
Procedure FilesStorageMethodOnChangeCompletion(Response, Item) Export

	If Response <> DialogReturnCode.OK Then
		ConstantsSet.FilesStorageMethod = FilesStorageMethodValue;
		ConstantsSet.StoreFilesInVolumesOnHardDrive = ThisIsWayToStoreFilesOnDisk(FilesStorageMethodValue);
		Return;
	EndIf;

	ChangeCompositionOfStoredData_ = False;
	
	If Not BinaryDataStoresAreAvailable Then
		If FilesStorageMethodValue = "InInfobase"
			And ConstantsSet.StoreFilesInVolumesOnHardDrive
			And Not HasFileStorageVolumes("InVolumesOnHardDrive") Then
			
			ShowMessageBox(, NStr("en = 'Storing files to the file server is enabled but the volumes are not configured.
				|Files will be saved to the infobase until at least one file storage volume is configured.'"));
		EndIf;
	Else

		ChangeCompositionOfStoredData_ = True;

		If WorkingWithClientServerFileArchive.StorageMethodUsesVolumes(ConstantsSet.FilesStorageMethod) Then
			If Not HasFileStorageVolumes(ConstantsSet.FilesStorageMethod) Then
				WarningText = GetWarningTextByFileStorageMethod(ConstantsSet.FilesStorageMethod);
				ShowMessageBox(, NStr("ru = '" + WarningText + "'"));
			EndIf;
		EndIf;				
	EndIf;
		
	OnChangeFilesStorageMethodAtServer(ChangeCompositionOfStoredData_);
	RefreshReusableValues();
	AfterChangeAttribute("FilesStorageMethod", False);
	AfterChangeAttribute("StoreFilesInVolumesOnHardDrive");
	
EndProcedure

// Parameters:
//  Result - Undefined
//            - String
//  AdditionalParameters - Structure:
//    * Item - FormField
//              - FormFieldExtensionForACheckBoxField
//
&AtClient
Procedure ProhibitFilesImportByExtensionAfterConfirm(Result, AdditionalParameters) Export
	
	If Result <> Undefined
		And Result = "Continue" Then
		
		Attachable_OnChangeAttribute(AdditionalParameters.Item);
	Else
		DenyUploadFilesByExtension = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeSettingsOfFilesStorageInIB()
	
	SetParametersOfFilesStorageInIB(
		New Structure("FilesExtensions, MaximumSize",
		IBFilesExtensions, MaxFileSizeInIB*1024*1024));
	
	RefreshReusableValues();
	AfterChangeAttribute("ParametersOfFilesStorageInIB", False);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	RefreshReusableValues();
	AfterChangeAttribute(ConstantName, ShouldRefreshInterface);
	
EndProcedure

&AtClient
Procedure AfterChangeAttribute(ConstantName, ShouldRefreshInterface = True)
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	ConstantName = SaveAttributeValue(DataPathAttribute);
	
	SetAvailability(DataPathAttribute);
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure OnChangeFilesStorageMethodAtServer(Val ChangeCompositionOfStoredData_ = False)

	BeginTransaction();
	Try
		Constants.FilesStorageMethod.Set(ConstantsSet.FilesStorageMethod);
		Constants.StoreFilesInVolumesOnHardDrive.Set(ConstantsSet.StoreFilesInVolumesOnHardDrive);
		
		If ChangeCompositionOfStoredData_ Then
			ChangeCompositionOfStoredData(ConstantsSet.FilesStorageMethod);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		ConstantsSet.FilesStorageMethod		= FilesStorageMethodValue;
		ConstantsSet.StoreFilesInVolumesOnHardDrive = FilesOperationsClientServer.ShouldStoreFilesInVolumes(FilesStorageMethodValue);

		Raise;		
	EndTry;
	
	FilesStorageMethodValue = ConstantsSet.FilesStorageMethod;
	SetAvailability("ConstantsSet.FilesStorageMethod");
	RefreshReusableValues();
	
EndProcedure

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If DataPathAttribute = "ConstantsSet.FilesStorageMethod" Then
		ConfigureSettingsOfStorageInVolumesAvailability();
	EndIf;
	
	If DataPathAttribute = "DenyUploadFilesByExtension"
		Or DataPathAttribute = "" Then
		
		Items.DeniedDataAreaExtensionsList.Enabled = DenyUploadFilesByExtension;
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.SynchronizeFiles"
		Or DataPathAttribute = "AllowAccessToInternetServices" 
		Or DataPathAttribute = ""  Then
		
		AllowAccessToInternetServices = Common.AccessToInternetServicesAllowed();
		Items.FileSynchronizationSettings.Enabled = ConstantsSet.SynchronizeFiles
			And AllowAccessToInternetServices;
		Items.SynchronizeFiles1.Visible = Not AllowAccessToInternetServices;
		Items.SynchronizeFiles.Visible = AllowAccessToInternetServices;
		Items.GroupCommentAllowInternetDownloadsInSync.Visible = Not AllowAccessToInternetServices;
		 
	EndIf;

	If DataPathAttribute = "UseFileArchive" Then
		SetAvailabilityOfFileArchiveManagementSettings();
	EndIf;	

EndProcedure

&AtServer
Procedure ConfigureSettingsOfStorageInVolumesAvailability()

	StorageMethodUsesVolumes = WorkingWithClientServerFileArchive.StorageMethodUsesVolumes(ConstantsSet.FilesStorageMethod);

	Items.FilesVolumesManagementGroup.Enabled = StorageMethodUsesVolumes;
	Items.CatalogFileStorageVolumes.Enabled = StorageMethodUsesVolumes;

	Items.CreateSubdirectoriesWithOwnersNames.Enabled = ConstantsSet.StoreFilesInVolumesOnHardDrive;
	Items.FilesSizeManagementInIBGroup.Enabled =
		ConstantsSet.FilesStorageMethod = "InInfobaseAndVolumesOnHardDrive";
	Items.IBFilesExtensionsManagementGroup.Enabled =
		ConstantsSet.FilesStorageMethod = "InInfobaseAndVolumesOnHardDrive";
	Items.GroupDeduplication.Visible = ConstantsSet.FilesStorageMethod <> "InVolumesOnHardDrive" And Not IsDeduplicationCompleted();
	
EndProcedure

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		
		If DataPathAttribute = "MaxFileSize" Then
			ConstantsSet.MaxFileSize = MaxFileSize * (1024*1024);
			ConstantName = "MaxFileSize";
		ElsIf DataPathAttribute = "MaxDataAreaFileSize" Then
			
			If Not Common.DataSeparationEnabled() Then
				ConstantsSet.MaxFileSize = MaxDataAreaFileSize * (1024*1024);
				ConstantName = "MaxFileSize";
			Else
				ConstantsSet.MaxDataAreaFileSize = MaxDataAreaFileSize * (1024*1024);
				ConstantName = "MaxDataAreaFileSize";
			EndIf;
			
		ElsIf DataPathAttribute = "DenyUploadFilesByExtension" Then
			ConstantsSet.DenyUploadFilesByExtension = DenyUploadFilesByExtension;
			ConstantName = "DenyUploadFilesByExtension";
		ElsIf DataPathAttribute = "UseFileArchive" Then
			ConstantsSet.UseFileArchive = UseFileArchive;
			ConstantName = "UseFileArchive";

			OnChangingUseOfFileArchive(UseFileArchive);
		EndIf;
		
	Else
		ConstantName = NameParts[1];
	EndIf;
	
	If IsBlankString(ConstantName) Then
		Return "";
	EndIf;
	
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() <> ConstantValue Then
		ConstantManager.Set(ConstantValue);
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServerNoContext
Procedure SetParametersOfFilesStorageInIB(StorageParameters)
	
	FilesOperationsInVolumesInternal.SetFilesStorageParametersInInfobase(StorageParameters);
	
EndProcedure

&AtServerNoContext
Function PermissionRequestsToUseExternalResourcesOfFilesStorageVolumes(Include)
	
	PermissionRequestsToUse = New Array;
	CatalogName = "FileStorageVolumes";
	
	If Include Then
		Catalogs[CatalogName].AddRequestsToUseExternalResourcesForAllVolumes(PermissionRequestsToUse);
	Else
		Catalogs[CatalogName].AddRequestsToStopUsingExternalResourcesForAllVolumes(PermissionRequestsToUse);
	EndIf;
	
	Return PermissionRequestsToUse;
	
EndFunction

&AtServerNoContext
Function HasFileStorageVolumes(Val ProcessedFileStorageMethod = Undefined)

	If ProcessedFileStorageMethod = Undefined Then
		
		TypeOfFileStorageVolume = Undefined;
		FilesStorageMethod = Undefined;
	Else

		TypeOfFileStorageVolume = Enums.TypesOfFileStorage.OperationalStorage;

		FilesStorageMethod = WorkingWithServerFileArchive.StorageMethodForSelectingStorageVolumes(ProcessedFileStorageMethod);

	EndIf;

	Return FilesOperationsInVolumesInternal.HasFileStorageVolumes(TypeOfFileStorageVolume, FilesStorageMethod);

EndFunction

&AtServer
Function StartDeduplicationAtServer()
	
	DeduplicationResultAddress = PutToTempStorage(Undefined, UUID);
	Return TimeConsumingOperations.ExecuteProcedure(, "InformationRegisters.FileRepository.TransferData_", True, DeduplicationResultAddress);
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure FinishDeduplication(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		ShowMessageBox(, NStr("en = 'Deduplication has been paused and can be resumed later.'"));
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	DeduplicationErrors = GetFromTempStorage(DeduplicationResultAddress);
	If IsDeduplicationCompleted() And DeduplicationErrors = Undefined Then
		Items.GroupDeduplication.Visible = False;
		ShowMessageBox(, NStr("en = 'File deduplication is completed.'"));
	ElsIf DeduplicationErrors = Undefined Then
		ShowMessageBox(, NStr("en = 'Some files have not been processed. Start again.'"));
	Else
		FormParameters = New Structure;
		FormParameters.Insert("Deduplication", True);
		FormParameters.Insert("Explanation", NStr("en = 'Some of the files failed to be processed. To resume, fix the following issues:'"));
		FormParameters.Insert("FilesWithErrors", DeduplicationErrors);
		OpenForm("DataProcessor.FileTransfer.Form.ReportForm", FormParameters);
	EndIf;
EndProcedure 

&AtServerNoContext
Function IsDeduplicationCompleted()
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	TRUE AS Validation
	|FROM
	|	InformationRegister.DeleteFilesBinaryData AS DeleteFilesBinaryData";
	
	Return Query.Execute().IsEmpty();
	
EndFunction

&AtServerNoContext
Function FilesSizeInInfobase()
	
	IncludeObjects = New Array();
	IncludeObjects.Add(Metadata.InformationRegisters.DeleteFilesBinaryData);
	FilesSizeMB = GetDatabaseDataSize(, IncludeObjects) / 1024 / 1024;
	If FilesSizeMB > 100 Then
		FilesSizeMB = Round(FilesSizeMB, 0);
	Else
		FilesSizeMB = Round(FilesSizeMB, 2);
	EndIf;
	
	Return FilesSizeMB;
	
EndFunction

&AtClient
Procedure OpenFileStorageVolumeCatalogListFormWithSelectionByTypeOfFileStorageVolume(OwnerForm, ValueForFilter)

	FormParameters = New Structure("Filter, ValueOfSelectionByTypeOfFileStorageVolume", New Structure("TypeOfFileStorageVolume", ValueForFilter), ValueForFilter);
	OpenForm("Catalog.FileStorageVolumes.ListForm", FormParameters, OwnerForm, True);

EndProcedure

&AtServer
Procedure FileStorageMethodCustomizeSelectionList()

	If Not WorkingWithServerFileArchive.ChangesInFileStorageMethodsAreAvailable() Then
		Return;
	EndIf;
	
	If Items.Find("FilesStorageMethod") = Undefined Then
		Return;
	EndIf;

	ChangeableStorageMethods = New Structure;
	ChangeableStorageMethods.Insert("InVolumesOnHardDrive"						, NStr("en = 'Volumes (network directories)'"));
	ChangeableStorageMethods.Insert("InInfobase"				, NStr("en = 'Database'"));
	ChangeableStorageMethods.Insert("InInfobaseAndVolumesOnHardDrive"	, NStr("en = 'Volumes or database'"));
	
	SelectionListFileStorageMethod = Items.FilesStorageMethod.ChoiceList;
	
	For Each ChangeableStorageMethod In ChangeableStorageMethods Do
		SearchResult = SelectionListFileStorageMethod.FindByValue(ChangeableStorageMethod.Key);
		If SearchResult <> Undefined Then
			SearchResult.Presentation = ChangeableStorageMethod.Value;
		EndIf;		
	EndDo;
	
	If Not BinaryDataStoresAreAvailable Then
		Return;
	EndIf;

	SelectionListFileStorageMethod.Add("InBuiltInBinaryDataStorage"	, NStr("en = 'Internal binary data storage (CORP)'"));
	SelectionListFileStorageMethod.Add("InExternalBinaryDataStorage"	, NStr("en = 'External binary data storage (CORP)'"));

EndProcedure

&AtClient
Function ThisIsWayToStoreFilesOnDisk(VerifiableWayToStoreFiles)

	Return FilesOperationsClientServer.ShouldStoreFilesInVolumes(VerifiableWayToStoreFiles);

EndFunction

&AtClient
Function GetWarningTextByFileStorageMethod(ProcessedFileStorageMethod)

	Result = "";

	If ProcessedFileStorageMethod = "InVolumesOnHardDrive" Then

		Result = NStr("en = 'File storage on the file server is enabled, but archive volumes are not configured yet.'");

	ElsIf ProcessedFileStorageMethod = "InInfobaseAndVolumesOnHardDrive" Then

		Result = NStr("en = 'File storage in the database and external storage is enabled, but storage volumes are not configured yet.'");

	ElsIf ProcessedFileStorageMethod = "InBuiltInBinaryDataStorage" Then

		Result = NStr("en = 'File storage in the internal binary data repository is enabled, but storage volumes are not configured yet.'");

	ElsIf ProcessedFileStorageMethod = "InExternalBinaryDataStorage" Then
		
		Result = NStr("en = 'File storage in the external binary data repository is enabled, but storage volumes are not configured yet.'");

	EndIf;

	If Not IsBlankString(Result) Then

		MessageTemplate = NStr("en = '%1
		|Files will be stored in the infobase until a file storage volume is configured.'");

		Result = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, Result);

	EndIf;

	Return Result;

EndFunction

&AtServerNoContext
Procedure ChangeCompositionOfStoredData(FilesStorageMethod)

	AttributesForConfiguringCompositionOfStoredData = WorkingWithServerFileArchive.FileStorageAttributesNamesByStorageMethod(FilesStorageMethod);

	If YouNeedToChangeCompositionOfStoredData(FilesStorageMethod, AttributesForConfiguringCompositionOfStoredData) Then
		WorkingWithBinaryDataStoresServer.ConfigureCompositionOfStoredDataForAttributes_(AttributesForConfiguringCompositionOfStoredData);
	EndIf;

EndProcedure

&AtServerNoContext
Function YouNeedToChangeCompositionOfStoredData(FilesStorageMethod, AttributesForFileStorage)

	If WorkingWithBinaryDataStoresServer.ThereAreNoBinaryDataStores() Then
		Return False;
	EndIf;

	For Each NameOfFileStorageAttribute In AttributesForFileStorage Do

		If WorkingWithBinaryDataStoresServer.YouNeedToConfigureCompositionOfStoredDataForAttributes(NameOfFileStorageAttribute, FilesStorageMethod) Then
			Return True;
		EndIf;

	EndDo;

	Return False;

EndFunction

&AtServer
Procedure SetAvailabilityOfFileArchiveManagementSettings()

	Items.SettingUpWorkWithFileArchive							.Enabled = UseFileArchive;
	Items.CatalogOfFileStorageVolumesArchived						.Enabled = UseFileArchive;
	Items.TextInformingUserAboutUnavailabilityOfFileInArchive	.Enabled = UseFileArchive;

EndProcedure

&AtServerNoContext
Procedure OnChangingUseOfFileArchive(UseFileArchive)

	JobParameters = New Structure;
	JobParameters.Insert("Metadata", Metadata.ScheduledJobs.TransferringFilesBetweenOperationalStorageAndFileArchive);
	If Not Common.DataSeparationEnabled() Then
		JobParameters.Insert("MethodName", Metadata.ScheduledJobs.TransferringFilesBetweenOperationalStorageAndFileArchive.MethodName);
	EndIf;
	
	SetPrivilegedMode(True);
	
	JobsList = ScheduledJobsServer.FindJobs(JobParameters);
	ParameterName = "Use";
	If JobsList.Count() = 0 Then
		JobParameters.Insert(ParameterName, UseFileArchive);
		ScheduledJobsServer.AddJob(JobParameters);
	Else
		JobParameters = New Structure(ParameterName, UseFileArchive);
		For Each Job In JobsList Do
			ScheduledJobsServer.ChangeJob(Job, JobParameters);
		EndDo;
	EndIf;
EndProcedure

#EndRegion