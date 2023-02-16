///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlersForm

&AtClient
Procedure OnOpen(Cancel)
	ItemCount = 0;
	If FilesOperationsInternalClient.InitAddIn() Then
		DeviceArray = FilesOperationsInternalClient.EnumDevices();
		For Each String In DeviceArray Do
			ItemCount = ItemCount + 1;
			Items.DeviceName.ChoiceList.Add(String);
		EndDo;
	EndIf;
	If ItemCount = 0 Then
		Cancel = True;
		ShowMessageBox(, NStr("en = 'There are no scanners installed. Please contact the application administrator.';"));
	Else
		Items.DeviceName.ListChoiceMode = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ChooseScanner(Command)
	
	If IsBlankString(DeviceName) Then
		MessageText = NStr("en = 'Please select a scanner.';");
		CommonClient.MessageToUser(MessageText, , "DeviceName");
		Return;
	EndIf;
	
	SystemInfo = New SystemInfo();
	CommonServerCall.CommonSettingsStorageSave(
		"ScanningSettings1/DeviceName",
		SystemInfo.ClientID,
		DeviceName,
		,
		,
		True);
	Close(DeviceName);
EndProcedure

#EndRegion