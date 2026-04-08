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

	CheckProcessingAvailability();
	
	RefreshPresentation();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure BinaryDataStoresSelection(Item, RowSelected, Field, StandardProcessing)
	EditStorage(Item);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddStorage(Command)

	Notification = New CallbackDescription("WhenAddingStorage", ThisObject);

	FormOpenParameters = New Structure("OpenByScenario", True);

	OpenForm(FormNameToOpen("AddStorage", FormName), FormOpenParameters, , , , , Notification, FormWindowOpeningMode.LockWholeInterface);

EndProcedure

&AtClient
Procedure EditStorage(Command)

	TheCurrentDataRow = Items.BinaryDataStores.CurrentData;
	If TheCurrentDataRow <> Undefined Then
		Notification = New CallbackDescription("WhenEditingRepository", ThisObject);
		
		FormOpenParameters = New Structure("OpenByScenario", True);
		
		If TheCurrentDataRow.StorageAddress = "" Then
			OpenForm(FormNameToOpen("BuiltInStorage", FormName), FormOpenParameters, , , , , Notification, FormWindowOpeningMode .LockWholeInterface);
		Else
			FormOpenParameters.Insert("StorageName", TheCurrentDataRow.StorageName);

			OpenForm(FormNameToOpen("ExternalStorage", FormName), FormOpenParameters, , , , , Notification, FormWindowOpeningMode .LockWholeInterface);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure DeleteStorage(Command)

	TheCurrentDataRow = Items.BinaryDataStores.CurrentData;
	If TheCurrentDataRow <> Undefined Then
		
		Notification = New CallbackDescription("DeleteBinaryDataStorage", ThisObject);
		
		QueryText = NStr("en = 'Delete binary data storage?'");
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo,,DialogReturnCode.No);
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtClient
Function FormNameToOpen(Var_FormName, FullFormName)

	Path = Left(FullFormName,StrFind(FullFormName, ".", SearchDirection.FromEnd));
	Return Path + "." + Var_FormName;

EndFunction

&AtClient
Procedure WhenAddingStorage(Result, AdditionalParameters) Export
	RefreshPresentation();
EndProcedure

&AtClient
Procedure WhenEditingRepository(Result, AdditionalParameters) Export
	RefreshPresentation();
EndProcedure

&AtServer
Procedure AddStorageToTable(StorageName, StorageAddress, HDDReadWriteMode, DefaultStorage, MinimumDataSize, DateOfStorageCleanup)

	HDDString = BinaryDataStores.Add();
	HDDString.StorageName = StorageName;	
	HDDString.StorageAddress = StorageAddress;

	If HDDReadWriteMode = BinaryDataStorageReadWriteMode.ReadOnly Then
 		HDDString.UsageMode = NStr("en = 'Read only'", Common.DefaultLanguageCode());
		HDDString.MinimumDataSize = "";
	Else 
		HDDString.UsageMode = NStr("en = 'Read and write'", Common.DefaultLanguageCode());
		HDDString.MinimumDataSize = MinimumDataSize;
	EndIf;

	HDDString.DefaultStorage = ?(DefaultStorage, 0, 1);	
	
	If HDDString.DateOfStorageCleanup <> Undefined Then
		HDDString.DateOfStorageCleanup = DateOfStorageCleanup;
	EndIf;

EndProcedure

&AtServer
Procedure RefreshPresentation()

	BinaryDataStores.Clear();
	
	// Internal storage
	HDDUsageMode = BinaryDataStorage.GetBinaryDataStorageUseMode();
	If HDDUsageMode = BinaryDataStorageUseMode.Enable Then
		StorageName = NStr("en = 'Internal storage'", Common.DefaultLanguageCode());
		StorageAddress = "";
		HDDReadWriteMode = False;
		MinimumDataSize = 2048;
		DefaultStorage = False;
		DateOfStorageCleanup = Undefined;

		Try
			HDDReadWriteMode = BinaryDataStorage.GetBinaryDataStorageReadWriteMode();
			MinimumDataSize = BinaryDataStorage.GetMinWriteDataSize();

			DefaultStorage = (HDDReadWriteMode <> BinaryDataStorageReadWriteMode.ReadOnly);
			If DefaultStorage Then
				// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
				Execute("DefaultStorage = BinaryDataStorage.GetUsingAsDefaultStorage()");
				// ACC:487-on				
			EndIf; 
			
			StorageInformation = BinaryDataStorage.GetInformation();
			If StorageInformation.LastClearingDate > Date(1, 1, 1) Then
				DateOfStorageCleanup = StorageInformation.LastClearingDate;
			EndIf;
		Except
			WriteLogEvent(NStr("en = 'Manage binary data storage'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			NStr("en = 'Error getting internal storage parameters'", Common.DefaultLanguageCode()));
		EndTry;
		
    	AddStorageToTable(StorageName, StorageAddress, HDDReadWriteMode, DefaultStorage, MinimumDataSize, DateOfStorageCleanup);

	EndIf; 
	
	// External storages
	For Each StorageManager In BinaryDataExternalStorages Do

		StorageName			= "";
		StorageAddress			= "";
		HDDReadWriteMode	= False;
		MinimumDataSize = 2048;
		DefaultStorage	= False;
		DateOfStorageCleanup	= Undefined;

		Try
			StorageName			= StorageManager.Name;
			HDDReadWriteMode	= StorageManager.ReadWriteMode;
			MinimumDataSize = StorageManager.MinWriteDataSize ;
			DefaultStorage	= (HDDReadWriteMode <> BinaryDataStorageReadWriteMode.ReadOnly) And StorageManager.DefaultStorage;

			If StorageManager.LastClearingDate > Date(1,1,1) Then
				DateOfStorageCleanup = StorageManager.LastClearingDate;
			EndIf;			

			StorageAddress	= StorageManager.ConnectionParameters.URL;

		Except
			WriteLogEvent(NStr("en = 'Manage binary data storage'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			NStr("en = 'Error getting external storage parameters'", Common.DefaultLanguageCode()));
		EndTry;
			
    	AddStorageToTable(StorageName, StorageAddress, HDDReadWriteMode, DefaultStorage, MinimumDataSize, DateOfStorageCleanup);

	EndDo;	                 

	AvailabilityOfEditingCommands = BinaryDataStores.Count() > 0;

	Items.EditStorage.Enabled = AvailabilityOfEditingCommands;
	Items.DeleteStorage.Enabled		= AvailabilityOfEditingCommands;

EndProcedure

&AtClient
Procedure DeleteBinaryDataStorage(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;	
	
	TheCurrentDataRow = Items.BinaryDataStores.CurrentData;
	
	If TheCurrentDataRow = Undefined Then
		Return;
	EndIf;
	
	DeleteStorageAtServer(TheCurrentDataRow.StorageAddress, TheCurrentDataRow.StorageName);
	
EndProcedure

&AtServer
Procedure DeleteStorageAtServer(Val StorageAddress, Val StorageName)

	If StorageAddress = "" Then 
		HDDUsageMode_ = BinaryDataStorageUseMode.Disable;
		BinaryDataStorage.SetBinaryDataStorageUseMode(HDDUsageMode_);	
	Else    
		StorageManager = BinaryDataExternalStorages[StorageName];
		BinaryDataExternalStorages.Delete(StorageManager);
	EndIf;

	RefreshPresentation();
EndProcedure

&AtServer
Procedure CheckProcessingAvailability()

	ExceptionText = "";

	If Common.FileInfobase() Then
		ExceptionText = NStr("en = 'The data processor doesn''t support file infobases.'");
	ElsIf Not WorkingWithServerFileArchive.ChangesInFileStorageMethodsAreAvailable() Then
		ExceptionText = NStr("en = 'The data processor supports 1C:Enterprise v.8.3.26 and later.'");
	ElsIf Common.DataSeparationEnabled() Then
		IBUser = InfoBaseUsers.CurrentUser();
		If IBUser.DataSeparation.Count() <> 0 Then
			ExceptionText = NStr("en = 'The data processor doesn''t support separated sessions.'");
		EndIf;
	EndIf;

	If ExceptionText <> "" Then
		Raise ExceptionText;
	EndIf;
		
EndProcedure

#EndRegion