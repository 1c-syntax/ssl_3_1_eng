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
	
	UninstalledAtOnceCount = 0;
	ShouldCheckCryptoProvider = Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined;
	
	RequiredAddInName = Parameters.RequiredAddInName;
	If Parameters.Property("Components") Then
		FillPropertyValues(Parameters, Parameters.Components);
	EndIf;
	
	If Parameters.IsCryptoProviderInstalled And ShouldCheckCryptoProvider Then
		Items.GroupCheckCryptographicProviderInstalled.Visible = False;
		CryptoProviderInstallationState = 2;
	Else
		Items.GroupCheckCryptographicProviderInstalled.Visible = True;
		CryptoProviderInstallationState = 0;
	EndIf;
	If Parameters.Is1CEnterpriseExtensionInstalled Then
		Items.GroupCheck1CExtensionInstalled.Visible = False;
		InstallationStateOf1CEnterpriseExtension = 2;
	Else
		Items.GroupCheck1CExtensionInstalled.Visible = True;
		InstallationStateOf1CEnterpriseExtension = 0;
		UninstalledAtOnceCount = UninstalledAtOnceCount + 1;
	EndIf;
	If Parameters.IsCryptographicExtensionInstalled Then
		Items.GroupCheckDigitalSigningExtensionInstalled.Visible = False;
		CryptographicExtensionInstallationState = 2;
	Else
		Items.GroupCheckDigitalSigningExtensionInstalled.Visible = True;
		CryptographicExtensionInstallationState = 0;
		UninstalledAtOnceCount = UninstalledAtOnceCount + 1;
	EndIf;
	If Parameters.IsExtraCryptoAPIAddInInstalled Then
		Items.GroupCheckAddInInstalled.Visible = False;
		ExtraCryptoAPIExtensionInstallationState = 2;
	Else
		Items.GroupCheckAddInInstalled.Visible = True;
		ExtraCryptoAPIExtensionInstallationState = 0;
		UninstalledAtOnceCount = UninstalledAtOnceCount + 1;
	EndIf;
	
	If UninstalledAtOnceCount = 1 Then
		Items.SetAll.Title = NStr("en = 'Install'");
	EndIf;
	
	If Common.IsWindowsClient() Then
		Items.SetAllExtendedTooltip.Title = 
			NStr("en = 'After each of the files is downloaded, click the file and follow the installer instructions.'");
	ElsIf Common.IsLinuxClient() Or Common.IsMacOSClient() Then
		Items.SetAllExtendedTooltip.Title = StringFunctions.FormattedString(
			NStr("en = 'For the final installation of each add-in, perform the following steps:
				|1. In the window that appears, select Save file.
				|2. Click the button indicated by the arrow and select the downloaded file.
				|3. Make the file executable and run it.'"));
	Else
		Items.SetAllExtendedTooltip.Title = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetDecorationValueDependingOnAddInsInstallationState();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Installation_CryptoApp" Then
		
		RequireReload = ?(Parameter = True, True, False);
		If RequireReload Then
			Items.ContinueWork.Title = NStr("en = 'Restart'");
		EndIf;
		
		AfterCryptoAppInstalled();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	ContinueWork(Undefined);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationCryptoProviderInstalledNoteURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	InstallCryptoApp();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetAll(Command)
	
	If InstallationStateOf1CEnterpriseExtension = 2 Then
		ContinueInstallAddInsAfter1CEnterpriseExtensionInstalled(True);
	Else
		InstallationStateOf1CEnterpriseExtension = 1;
		SetDecorationValueDependingOnAddInsInstallationState();
		BeginInstallFileSystemExtension(New CallbackDescription(
			"After1CEnterpriseExtensionInstalled", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinueWork(Command)
	
	If RequiredAddInName = "ExpansionOfWorkWith1CEnterprise" Then
		If InstallationStateOf1CEnterpriseExtension = 2 Then
			Close(True);
		Else
			Close(False);
		EndIf;
	ElsIf RequiredAddInName = "CryptographicExtension" Then
		If CryptographicExtensionInstallationState = 2 Then
			Close(True);
		Else
			Close(False);
		EndIf;
	ElsIf RequiredAddInName = "ComponentExtraCryptoAPI" Then
		ClosingParameters = New Structure("Attached, ErrorDescription");
		ClosingParameters.Attached = ?(ExtraCryptoAPIExtensionInstallationState = 2, True, False);
		ClosingParameters.ErrorDescription = "";
		Close(ClosingParameters);
	Else
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetDecorationValueDependingOnAddInsInstallationState()
	
	If CryptoProviderInstallationState = 2 Then
		TextRebootIsRequired = ?(RequireReload, NStr("en = ', restart the application'"), "");
		Items.DecorationCryptoProviderInstalled.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'A cryptographic data protection tool is installed%1'"), TextRebootIsRequired);
		Items.DecorationCryptoProviderInstalledNote.Visible = False;
	ElsIf CryptoProviderInstallationState = 1 Then
		Items.DecorationCryptoProviderInstalled.Title = NStr("en = 'Installing a cryptographic data protection tool'");
		Items.DecorationCryptoProviderInstalledNote.Visible = False;
	Else
		Items.DecorationCryptoProviderInstalled.Title = NStr("en = 'No cryptographic data protection tool is installed'");
		Items.DecorationCryptoProviderInstalledNote.Visible = True;
	EndIf;
	
	If InstallationStateOf1CEnterpriseExtension = 2 Then
		Items.Decoration1CExtensionInstalled.Title = NStr("en = '1C:Enterprise Extension has been installed'");
	ElsIf InstallationStateOf1CEnterpriseExtension = 1 Then
		Items.Decoration1CExtensionInstalled.Title = NStr("en = 'Installing 1C:Enterprise Extension'");
	Else
		Items.Decoration1CExtensionInstalled.Title = NStr("en = '1C:Enterprise Extension is not installed'");
	EndIf;
	
	If CryptographicExtensionInstallationState = 2 Then
		Items.DecorationCryptographicProviderExtensionInstalled.Title = NStr("en = 'The cryptography extension  has been installed'");
	ElsIf CryptographicExtensionInstallationState = 1 Then
		Items.DecorationCryptographicProviderExtensionInstalled.Title = NStr("en = 'Installing the cryptography extension'");
	Else
		Items.DecorationCryptographicProviderExtensionInstalled.Title = NStr("en = 'The cryptography extension is not installed'");
	EndIf;
	
	If ExtraCryptoAPIExtensionInstallationState = 2 Then
		Items.DecorationAddInInstalled.Title = NStr("en = 'ExtraCryptoAPI has been installed.'");
	ElsIf ExtraCryptoAPIExtensionInstallationState = 1 Then
		Items.DecorationAddInInstalled.Title = NStr("en = 'Installing ExtraCryptoAPI'");
	Else
		Items.DecorationAddInInstalled.Title = NStr("en = 'Add-in ExtraCryptoAPI is not installed.'");
	EndIf;
	
	If InstallationStateOf1CEnterpriseExtension = 2
		And CryptographicExtensionInstallationState = 2
		And ExtraCryptoAPIExtensionInstallationState = 2 Then
		
		Items.GroupInstallAtOnce.Visible = False;
		
		If CryptoProviderInstallationState = 2 Then
			Items.GroupInstallationsHeader.Visible = False;
			Items.GroupResumeOperation.Visible = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InstallCryptoApp()
	DigitalSignatureInternalClient.OpenCryptoProviderAppsInstallationForm(, ThisObject);
EndProcedure

&AtClient
Procedure AfterCryptoAppInstalled()
	
	CryptoProviderInstallationState = 2;
	SetDecorationValueDependingOnAddInsInstallationState();
	
EndProcedure

&AtClient
Procedure After1CEnterpriseExtensionInstalled(Result) Export
	
	BeginAttachingFileSystemExtension(
		New CallbackDescription("ContinueInstallAddInsAfter1CEnterpriseExtensionInstalled", ThisObject));
	
EndProcedure

&AtClient
Procedure ContinueInstallAddInsAfter1CEnterpriseExtensionInstalled(Attached, Context = Undefined) Export
	
	If Attached = True Then
		InstallationStateOf1CEnterpriseExtension = 2;
		AfterAddInAndExtensionsInstalled();
	Else
		AttachIdleHandler("WaitFor1CEnterpriseExtensionInstallation", 3);
	EndIf;
	
	If CryptographicExtensionInstallationState = 2 Then
		ContinueInstallAddInAfterCryptographicExtensionInstalled(True);
	Else
		CryptographicExtensionInstallationState = 1;
		SetDecorationValueDependingOnAddInsInstallationState();
		BeginInstallCryptoExtension(New CallbackDescription(
			"AfterCryptographicExtensionInstalled", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Async Procedure WaitFor1CEnterpriseExtensionInstallation()
	
	Attached = Await AttachFileSystemExtensionAsync();
	If Attached Then
		DetachIdleHandler("WaitFor1CEnterpriseExtensionInstallation");
		InstallationStateOf1CEnterpriseExtension = 2;
		AfterAddInAndExtensionsInstalled();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCryptographicExtensionInstalled(Context) Export
	
	BeginAttachingCryptoExtension(New CallbackDescription(
		"ContinueInstallAddInAfterCryptographicExtensionInstalled", ThisObject, Context));
	
EndProcedure

&AtClient
Async Procedure ContinueInstallAddInAfterCryptographicExtensionInstalled(Attached, Context = Undefined) Export
	
	If Attached = True Then
		Notify("InstallCryptoExtension");
		CryptographicExtensionInstallationState = 2;
		AfterAddInAndExtensionsInstalled();
	Else
		AttachIdleHandler("WaitForCryptographyExtensionInstallation", 3);
	EndIf;
	
	If ExtraCryptoAPIExtensionInstallationState = 2 Then
		AfterAddInAndExtensionsInstalled();
	Else
		ConnectionParameters = CommonClient.AddInAttachmentParameters();
		ConnectionParameters.SuggestInstall = True;
		ConnectionParameters.SuggestToImport = True;
		ConnectionParameters.ShouldShowInstallationPrompt = False;
		ComponentDetails = DigitalSignatureInternalClientServer.ComponentDetails();
		
		ExtraCryptoAPIExtensionInstallationState = 1;
		SetDecorationValueDependingOnAddInsInstallationState();
		
		Result = Await CommonClient.AttachAddInFromTemplateAsync(
			ComponentDetails.ObjectName,
			ComponentDetails.FullTemplateName,
			ConnectionParameters);
		
		If Result.Attached Then
			ExtraCryptoAPIExtensionInstallationState = 2;
			AfterAddInAndExtensionsInstalled();
		EndIf;
	EndIf;

EndProcedure

&AtClient
Async Procedure WaitForCryptographyExtensionInstallation()
	
	Attached = Await AttachCryptoExtensionAsync();
	If Attached Then
		DetachIdleHandler("WaitForCryptographyExtensionInstallation");
		CryptographicExtensionInstallationState = 2;
		AfterAddInAndExtensionsInstalled();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAddInAndExtensionsInstalled()
	
	// If not all required add-ins for downloading the cryptography tool or token are installed,
	// only the installation status of the component will be updated.
	If InstallationStateOf1CEnterpriseExtension = 2
		And CryptographicExtensionInstallationState = 2
		And ExtraCryptoAPIExtensionInstallationState = 2 Then
		
		CheckCryptoProviderAfterAddInAndExtensionsInstalled();
		
	Else
		SetDecorationValueDependingOnAddInsInstallationState();
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckCryptoProviderAfterAddInAndExtensionsInstalled()
	
	If DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer()
		Or DigitalSignatureClient.GenerateDigitalSignaturesAtServer()
		Or DigitalSignatureInternalClient.UseCloudSignatureService()
		Or DigitalSignatureInternalClient.UseDigitalSignatureSaaS()
		Or Not ShouldCheckCryptoProvider Then
		
		SetDecorationValueDependingOnAddInsInstallationState();
		Return;
		
	EndIf;
	
	If Not RequiredAddInName = "CryptographicApp"
		And Not Items.GroupCheckCryptographicProviderInstalled.Visible Then
		
		CheckParameters = New Structure;
		CheckParameters.Insert("ShouldPromptToInstallApp", False);
		
		CryptoProviderInstallationState = 1;
		Items.GroupCheckCryptographicProviderInstalled.Visible = True;
		Items.GroupCryptographicProviderInstallationStatus.Visible = False;
		Items.GroupCheckRunning.Visible = True;
		
		DigitalSignatureInternalClient.CheckCryptographyAppsInstallation(ThisObject, CheckParameters,
			New CallbackDescription("AfterCryptoAppsInstallationChecked", ThisObject));
			
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCryptoAppsInstallationChecked(Result, Context) Export
	
	If Result.CheckCompleted Then
		
		IsCryptoProviderInstalled = Result.Tokens.Count() > 0;
		
		If Not IsCryptoProviderInstalled Then
			For Each Cryptoprovider In Result.Programs Do
				If ValueIsFilled(Cryptoprovider.Application) And Not IsCryptoProviderInstalled Then
					IsCryptoProviderInstalled = True;
				EndIf;
			EndDo;
		EndIf;
		
		If IsCryptoProviderInstalled Then
			CryptoProviderInstallationState = 2;
		Else
			Items.GroupCheckCryptographicProviderInstalled.Visible = True;
			CryptoProviderInstallationState = 0;
		EndIf;
		
		Items.GroupCryptographicProviderInstallationStatus.Visible = True;
		Items.GroupCheckRunning.Visible = False;
		
		SetDecorationValueDependingOnAddInsInstallationState();
		
	EndIf;
	
EndProcedure

#EndRegion