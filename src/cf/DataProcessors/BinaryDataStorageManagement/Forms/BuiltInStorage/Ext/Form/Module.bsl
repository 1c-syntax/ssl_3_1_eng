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

	If Not Parameters.OpenByScenario Then
		Raise NStr("en = 'The form cannot be opened manually.'");
	EndIf;
	
	UpdateSettings2();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)

	If CurrentPage.Name = "SettingsPage" Then
		UpdateSettings2();
	ElsIf CurrentPage.Name = "StorageInformationPage" Then
		UpdateInformationATServer();
	EndIf;

EndProcedure

&AtClient
Procedure AllowRecordingOnChange(Item)

	Items.MinimumSizeOfRecordedData.Enabled = AllowRecording;	

	If AllowRecording Then

		MinimumSizeOfRecordedData = MinimumSizeOfRecordedDataATServer();

		AvailabilityOfOKButton();
	Else

		MinimumSizeOfRecordedData = 0;
	EndIf;

EndProcedure

&AtClient
Procedure MinimumSizeOfRecordedDataOnChange(Item)

	AvailabilityOfOKButton();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateInformation2(Command)

    UpdateInformationATServer();

EndProcedure

&AtClient
Procedure ClearVault(Command)

	If ClearDate = Date(1, 1, 1) Then
		Raise NStr("en = 'Cleanup date is required'");	
	EndIf;

	Status(NStr("en = 'Wait please'"), , StringFunctionsClientServer.SubstituteParametersToString(
											NStr("en = 'Cleaning up data through %1…'"), ClearDate));

	ClearStorageByDateCleared(ClearDate); 

	Status("", , NStr("en = 'Сleanup completed'"));

EndProcedure

&AtClient
Procedure OK(Command)

	Try

		ChangeStorageSettingsAtServer();

	Except
		UpdateSettings2();
		Raise;
	EndTry;

	Close(True);

EndProcedure

&AtClient
Procedure Cancel(Command)

	Close(False);

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AvailabilityOfOKButton()

	OKButtonIsAvailable = MinimumSizeOfRecordedData >= 2048;

	Items.OKButton.Enabled = OKButtonIsAvailable;

EndProcedure

&AtServer                 
Procedure UpdateSettings2()

	MinimumSizeOfRecordedData	= BinaryDataStorage.GetMinWriteDataSize();
	
	ReadWriteMode = BinaryDataStorage.GetBinaryDataStorageReadWriteMode();
	ReadAndWriteAreAvailable = ReadWriteMode = BinaryDataStorageReadWriteMode.ReadAndWrite;

	If ReadAndWriteAreAvailable Then 

		AllowRecording = True;

	Else
		AllowRecording			= False;		
	EndIf;

	Items.MinimumSizeOfRecordedData.Enabled = ReadAndWriteAreAvailable;	

EndProcedure

&AtServer
Procedure UpdateInformationATServer()

	StorageInformation = BinaryDataStorage.GetInformation();

	StoredDataSize						= StorageInformation.StoredDataSize;
	DeletedDataSize					= StorageInformation.DeletedDataSize;
    StoredItemsCount				= StorageInformation.StoredItemsCount;
	DeletedItemsCount			= StorageInformation.DeletedItemsCount;
	StoredDataSizeOnDisk				= StorageInformation.StoredDataSizeOnDisk;
	DeduplicatedItemsCount	= StorageInformation.DeduplicatedItemsCount;
	LastClearingDate					= ToLocalTime(StorageInformation.LastClearingDate);
	
EndProcedure

&AtServerNoContext
Procedure ClearStorageByDateCleared(Val ClearDate)

	BinaryDataStorage.ClearUnusedSpaceByUniversalDate(ToUniversalTime(ClearDate));

EndProcedure

&AtServerNoContext
Function MinimumSizeOfRecordedDataATServer()

	Return BinaryDataStorage.GetMinWriteDataSize();

EndFunction

&AtServer
Procedure ChangeStorageSettingsAtServer()

	If AllowRecording Then
		BinaryDataStorage.SetBinaryDataStorageReadWriteMode(BinaryDataStorageReadWriteMode.ReadAndWrite);
	Else 
		BinaryDataStorage.SetBinaryDataStorageReadWriteMode(BinaryDataStorageReadWriteMode.ReadOnly);
	EndIf;

	BinaryDataStorage.SetMinWriteDataSize(MinimumSizeOfRecordedData);

EndProcedure

#EndRegion