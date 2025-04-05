///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Internal

Function AuthenticationParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Peer");
	Parameters.Insert("ExchangePlanName");
	Parameters.Insert("TransportID");
	Parameters.Insert("TransportSettings");
	
	Return Parameters;
	
EndFunction

Procedure StartOfAuthentication(AuthenticationParameters, AuthenticationRequired, ClosingNotification1 = Undefined) Export
	
	NameOfAuthenticationForm = "";
	AuthenticationRequired = ExchangeMessageTransportServerCall.AuthenticationRequired(
		AuthenticationParameters, NameOfAuthenticationForm);
		
	If AuthenticationRequired Then
		
		OpenForm(NameOfAuthenticationForm, AuthenticationParameters,,,,,ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

Procedure OpenProxyServerParametersForm() Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownloadClient = CommonClient.CommonModule("GetFilesFromInternetClient");
		
		FormParameters = Undefined;
		If CommonClient.FileInfobase() Then
			FormParameters = New Structure("ProxySettingAtClient", True);
		EndIf;
		
		ModuleNetworkDownloadClient.OpenProxyServerParametersForm(FormParameters);
	EndIf;
	
EndProcedure

// Opens the instruction for restoring or changing the password for data synchronization
// with a standalone workstation.
//
Procedure OpenInstructionHowToChangeDataSynchronizationPassword(Val AccountPasswordRecoveryAddress) Export
	
	If IsBlankString(AccountPasswordRecoveryAddress) Then
		
		ShowMessageBox(, NStr("en = 'The address of the password recovery instruction is not specified.'"));
		
	Else
		
		FileSystemClient.OpenURL(AccountPasswordRecoveryAddress);
		
	EndIf;
	
EndProcedure

#EndRegion