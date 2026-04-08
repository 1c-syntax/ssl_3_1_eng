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

	StorageName = Parameters.StorageName;

	ExternalHDD = BinaryDataExternalStorages.Find(StorageName);
	If ExternalHDD = Undefined Then
		Cancel = True;
		Return;
	EndIf;

	FillFormAttributes(ExternalHDD);

	Items.MinimumSizeOfRecordedData.Enabled = AllowRecording;	

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AllowRecordingOnChange(Item)
	
	Items.MinimumSizeOfRecordedData.Enabled = AllowRecording;	

	If AllowRecording Then     
		MinimumSizeOfRecordedData = RecordedDataIsMinimumSize(StorageName);
	Else                    
		MinimumSizeOfRecordedData = 0;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Clear(Command)

	ClearAtServer();

EndProcedure

&AtClient
Procedure OK(Command)

	RecordChangesToRepository();
	Close(True);

EndProcedure

&AtClient
Procedure Cancel(Command)

	Close(False);

EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function RecordedDataIsMinimumSize(Val StorageName)

	ExternalHDD = BinaryDataExternalStorages[StorageName];
	Return ExternalHDD.MinWriteDataSize;

EndFunction

&AtServer
Procedure FillFormAttributes(ExternalHDD)

	Name						= ExternalHDD.Name;
	AccessID	= ExternalHDD.AccessParameters.AccessID;
	SecretKey			= ExternalHDD.AccessParameters.SecretKey; 
	State					= ExternalHDD.AccessParameters.Region;

	AllowRecording = ExternalHDD.ReadWriteMode = BinaryDataStorageReadWriteMode.ReadAndWrite;

	If AllowRecording Then

		MinimumSizeOfRecordedData = ExternalHDD.MinWriteDataSize ;

	Else

		MinimumSizeOfRecordedData = 0;

	EndIf;

	If ExternalHDD.LastClearingDate > Date(1, 1, 1) Then
		LastClearingDate = ExternalHDD.LastClearingDate;
	Else
		LastClearingDate = Undefined;
	EndIf;	
	
EndProcedure

&AtServer
Procedure ClearAtServer()

	ExternalHDD = BinaryDataExternalStorages[StorageName];
	ExternalHDD.ClearUnusedSpaceByUniversalDate(ToUniversalTime(ClearDate));
	If ExternalHDD.LastClearingDate > Date(1, 1, 1) Then
		LastClearingDate = ExternalHDD.LastClearingDate;
	Else
		LastClearingDate = Undefined;
	EndIf;

EndProcedure

&AtServer
Procedure RecordChangesToRepository()

	AccessParametersOfVXDD = Undefined;

	// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
	Execute("AccessParametersOfVXDD = New BinaryDataExternalStorageAccessParameters()");
	// ACC:487-on

	AccessParametersOfVXDD.AccessID	= AccessID;
	AccessParametersOfVXDD.SecretKey			= SecretKey;
	AccessParametersOfVXDD.State					= State;
	
	ExternalHDD = BinaryDataExternalStorages[StorageName];	
	ExternalHDD.AccessParameters		= AccessParametersOfVXDD;
	ExternalHDD.Name					= Name;

	If AllowRecording Then
		ExternalHDD.ReadWriteMode = BinaryDataStorageReadWriteMode.ReadAndWrite;
		ExternalHDD.MinWriteDataSize = MinimumSizeOfRecordedData;
	Else
		ExternalHDD.ReadWriteMode = BinaryDataStorageReadWriteMode.ReadOnly;
	EndIf;
	
	ExternalHDD.Write();

EndProcedure

#EndRegion