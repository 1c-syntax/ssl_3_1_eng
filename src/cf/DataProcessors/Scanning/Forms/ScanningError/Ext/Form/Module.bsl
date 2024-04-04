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
	FillPropertyValues(ThisObject, Parameters, "ScannerName, ErrorText, DetailErrorDescription");
	Title = Parameters.Title;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetErrorText();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ErrorTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	If FormattedStringURL = "OpenSettings" Then
		StandardProcessing = False;
		FilesOperationsClient.OpenScanSettingForm();
	ElsIf FormattedStringURL = "TechnicalInformation" Then
		StandardProcessing = False;
		GetTechnicalInformation();
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RedoScanning(Command)
	Close("RedoScanning");
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetErrorText()
	If Not ValueIsFilled(ErrorText) Then
		If Not ShowScannerDialog And Not CommonClient.IsLinuxClient() Then
			ErrorTextOnUseAppSettings = Chars.LF + " • "
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Open <a href = ""%1"">scanner settings</> and select ""Advanced settings"".';"), "OpenSettings");
		Else
			ErrorTextOnUseAppSettings = "";
		EndIf;
		
		ErrorText = StringFunctionsClient.FormattedString(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Scanner %1 not found or not connected.
						|Try the following:
						| • Check whether the scanner is connected and try again.
						| • Specify the available scanner in the <a href = ""%2"">scanner settings</a>.%4
						| • If the issue persists, contact 1C technical support and 
						| provide <a href = ""%3"">technical information about the issue</a>.';"), 
			ScannerName, "OpenSettings", "TechnicalInformation", ErrorTextOnUseAppSettings));
  	EndIf;
  	Items.ErrorText.Title = ErrorText;
EndProcedure

&AtClient
Procedure GetTechnicalInformation()
	AfterTechnicalInfoReceived = New NotifyDescription("AfterTechnicalInfoReceived", ThisObject);
	FilesOperationsInternalClient.GetTechnicalInformation(DetailErrorDescription, AfterTechnicalInfoReceived);
EndProcedure

&AtClient
Procedure AfterTechnicalInfoReceived(Result, Context) Export
	NotifyChoice("RefreshErrorDisplay");
EndProcedure

#EndRegion
