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
	
	If Not AvailabilityOfBuiltInBinaryDataStorage() Then
		Items.StoreType.ChoiceList.Add(0, NStr("en = 'Internal storage'", Common.DefaultLanguageCode()));
		StoreType = 0;
	Else
		StoreType = 1;
	EndIf;
	Items.StoreType.ChoiceList.Add(1, NStr("en = 'S3 external storage'", Common.DefaultLanguageCode()));
	Items.StoreType.ChoiceList.Add(2, NStr("en = 'S3 external storage (virtual host)'", Common.DefaultLanguageCode()));

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	UpdateForm();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StoreTypeOnChange(Item)
    UpdateForm();
EndProcedure

&AtClient
Procedure StorageNameOnChange(Item)
	UpdateForm();
EndProcedure

&AtClient
Procedure ConnectionAddressOnChange(Item)
	UpdateForm();
EndProcedure

&AtClient
Procedure AccessIDOnChange(Item)
	UpdateForm();
EndProcedure

&AtClient
Procedure SecretKeyOnChange(Item)
	UpdateForm();
EndProcedure

&AtClient
Procedure StateOnChange(Item)
	UpdateForm();
EndProcedure

&AtClient
Procedure AllowRecordingOnChange(Item)

	Items.MinimumSizeOfRecordedData.Enabled = AllowRecording;	

	If AllowRecording Then
		MinimumSizeOfRecordedData = 2048;
	Else                    
		MinimumSizeOfRecordedData = 0;
	EndIf;	
	
EndProcedure

&AtClient
Procedure MinimumSizeOfRecordedDataOnChange(Item)
	UpdateForm();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)

    AddStorage();
	Close(True);

EndProcedure

&AtClient
Procedure Cancel(Command)

	Close(False);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddStorage()

	// Internal storage
	If StoreType = 0 Then

		BinaryDataStorage.SetBinaryDataStorageUseMode(BinaryDataStorageUseMode.Enable);

		If AllowRecording Then
			BinaryDataStorage.SetBinaryDataStorageReadWriteMode(BinaryDataStorageReadWriteMode.ReadAndWrite);
		Else 
			BinaryDataStorage.SetBinaryDataStorageReadWriteMode(BinaryDataStorageReadWriteMode.ReadOnly);
		EndIf;		

		Return;
	EndIf;

	// External storage
	// Connection parameters
	ConnectionParameters = New BinaryDataExternalStorageConnectionParameters();
	ConnectionParameters.URL = ConnectionAddress;
	
	// ACC:216-off - Enumeration member contains Latin and Cyrillic letters.
	If StoreType = 1 Then                                      
		ConnectionParameters.URLType = BinaryDataExternalStorageURLType.S3HostWithBucketInPath ;
	ElsIf StoreType = 2 Then
		ConnectionParameters.URLType = BinaryDataExternalStorageURLType.S3VirtualHost;
	EndIf;
	// ACC:216-on

	// Access parameters
	AccessParametersOfVXDD = Undefined;

	// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
	Execute("AccessParametersOfVXDD = New BinaryDataExternalStorageAccessParameters()");
	// ACC:487-on	

	AccessParametersOfVXDD.AccessID	= AccessID;
	AccessParametersOfVXDD.SecretKey			= SecretKey;
	AccessParametersOfVXDD.State					= State;

	ExternalHDD = BinaryDataExternalStorages.Add(StorageName, ConnectionParameters, AccessParametersOfVXDD);
	
	If AllowRecording Then
		ExternalHDD.ReadWriteMode = BinaryDataStorageReadWriteMode.ReadAndWrite;
		ExternalHDD.MinWriteDataSize = MinimumSizeOfRecordedData;
		
		ExternalHDD.Write();
	EndIf;

EndProcedure

&AtServer
Function AvailabilityOfBuiltInBinaryDataStorage()

	HDDUsageMode = BinaryDataStorage.GetBinaryDataStorageUseMode();
	Result = HDDUsageMode = BinaryDataStorageUseMode.Enable;

	Return Result;

EndFunction

&AtClient
Procedure UpdateForm()

	ThisIsExternalHDD = StoreType <> 0;

	Items.StorageName			.Enabled = ThisIsExternalHDD;
	Items.ConnectionAddress		.Enabled = ThisIsExternalHDD;
	Items.AccessID	.Enabled = ThisIsExternalHDD;
	Items.SecretKey			.Enabled = ThisIsExternalHDD;
	Items.State					.Enabled = ThisIsExternalHDD;	

	OKAccessibilityButton = True;

	If ThisIsExternalHDD Then
		If StorageName = "" Or ConnectionAddress = "" Or AccessID = "" Or SecretKey = "" Or State = "" Then
			OKAccessibilityButton = False;
		EndIf;	
	EndIf;

	If AllowRecording And OKAccessibilityButton Then
		OKAccessibilityButton = MinimumSizeOfRecordedData >= 2048;
	EndIf;

	Items.OKButton.Enabled = OKAccessibilityButton;

EndProcedure

#EndRegion