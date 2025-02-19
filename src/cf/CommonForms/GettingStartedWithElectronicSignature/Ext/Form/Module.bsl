///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	NoSimultaneous = 0;
	CheckCryptoprovider = Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined;
	
	NameOfRequiredComponent = Parameters.NameOfRequiredComponent;
	If Parameters.Property("Components") Then
		FillPropertyValues(Parameters, Parameters.Components);
	EndIf;
	
	If Parameters.CryptoproviderIsInstalled And CheckCryptoprovider Then
		Items.CryptoproviderInstallationVerificationGroup.Visible = False;
		StateOfCryptoproviderInstallation = 2;
	Else
		Items.CryptoproviderInstallationVerificationGroup.Visible = True;
		StateOfCryptoproviderInstallation = 0;
	EndIf;
	If Parameters.ExpansionOfWorkOfS1CByEnterpriseIsEstablished Then
		Items.GroupCheckingInstallationOf1CExtension.Visible = False;
		StateOfInstallationOfExtensionOfWorkWith1CEnterprise = 2;
	Else
		Items.GroupCheckingInstallationOf1CExtension.Visible = True;
		StateOfInstallationOfExtensionOfWorkWith1CEnterprise = 0;
		NoSimultaneous = NoSimultaneous + 1;
	EndIf;
	If Parameters.ExtensionOfWorkWithCryptographyIsEstablished Then
		Items.GroupCheckingInstallationOfItemInstanceExtension.Visible = False;
		StateOfCryptographyExtensionInstallation = 2;
	Else
		Items.GroupCheckingInstallationOfItemInstanceExtension.Visible = True;
		StateOfCryptographyExtensionInstallation = 0;
		NoSimultaneous = NoSimultaneous + 1;
	EndIf;
	If Parameters.ExtraCryptoAPIComponentIsInstalled Then
		Items.ComponentsInstallationVerificationGroup.Visible = False;
		InstallationStateOfExtraCryptoAPIComponent = 2;
	Else
		Items.ComponentsInstallationVerificationGroup.Visible = True;
		InstallationStateOfExtraCryptoAPIComponent = 0;
		NoSimultaneous = NoSimultaneous + 1;
	EndIf;
	
	If NoSimultaneous = 1 Then
		Items.SetAll.Title = NStr("en = 'Установить';");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetValueOfDecorationsDependingOnStateOfComponentInstallation();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Installation_CryptographyApplication" Then
		
		RequireReboot = ?(Parameter = True, True, False);
		If RequireReboot Then
			Items.ContinueWork.Title = NStr("en = 'Перезагрузить';");
		EndIf;
		
		AfterInstallingCryptographyProgram();
		
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
Procedure DecorationCryptoproviderInstalledExplanationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	InstallCryptographyProgram();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetAll(Command)
	
	If StateOfInstallationOfExtensionOfWorkWith1CEnterprise = 2 Then
		ContinueInstallingComponentAfterInstallingExtensionOfWorkWith1CEnterprise(True);
	Else
		StateOfInstallationOfExtensionOfWorkWith1CEnterprise = 1;
		SetValueOfDecorationsDependingOnStateOfComponentInstallation();
		BeginInstallFileSystemExtension(New CallbackDescription(
			"AfterInstallingExtensionOfWorkWith1CEnterprise", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinueWork(Command)
	
	If NameOfRequiredComponent = "ExpansionOfWorkWith1CEnterprise" Then
		If StateOfInstallationOfExtensionOfWorkWith1CEnterprise = 2 Then
			Close(True);
		Else
			Close(False);
		EndIf;
	ElsIf NameOfRequiredComponent = "ExpandingWorkWithCryptography" Then
		If StateOfCryptographyExtensionInstallation = 2 Then
			Close(DialogReturnCode.Yes);
		Else
			Close(DialogReturnCode.No);
		EndIf;
	ElsIf NameOfRequiredComponent = "ComponentExtraCryptoAPI" Then
		ClosingParameters = New Structure("Attached, ErrorDescription");
		ClosingParameters.Attached = ?(InstallationStateOfExtraCryptoAPIComponent = 2, True, False);
		ClosingParameters.ErrorDescription = "";
		Close(ClosingParameters);
	Else
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetValueOfDecorationsDependingOnStateOfComponentInstallation()
	
	If StateOfCryptoproviderInstallation = 2 Then
		TextRebootIsRequired = ?(RequireReboot, NStr("en = ', требуется перезапустить сеанс';"), "");
		Items.DecorationCryptoproviderIsInstalled.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Установлено средство криптографической защиты информации%1';"), TextRebootIsRequired);
		Items.DecorationCryptoproviderInstalledExplanation.Visible = False;
	ElsIf StateOfCryptoproviderInstallation = 1 Then
		Items.DecorationCryptoproviderIsInstalled.Title = NStr("en = 'Выполняется установка средства криптографической защиты информации';");
		Items.DecorationCryptoproviderInstalledExplanation.Visible = False;
	Else
		Items.DecorationCryptoproviderIsInstalled.Title = NStr("en = 'Не установлено средство криптографической защиты информации';");
		Items.DecorationCryptoproviderInstalledExplanation.Visible = True;
	EndIf;
	
	If StateOfInstallationOfExtensionOfWorkWith1CEnterprise = 2 Then
		Items._1CDecorationExtensionIsInstalled.Title = NStr("en = 'Расширение для работы с 1С:Предприятием успешно установлено';");
	ElsIf StateOfInstallationOfExtensionOfWorkWith1CEnterprise = 1 Then
		Items._1CDecorationExtensionIsInstalled.Title = NStr("en = 'Выполняется установка расширения для работы с 1С:Предприятием';");
	Else
		Items._1CDecorationExtensionIsInstalled.Title = NStr("en = '1C:Enterprise Extension is not installed';");
	EndIf;
	
	If StateOfCryptographyExtensionInstallation = 2 Then
		Items.DecorationItemInstanceExtensionIsInstalled.Title = NStr("en = 'Расширение для работы с криптографией успешно установлено';");
	ElsIf StateOfCryptographyExtensionInstallation = 1 Then
		Items.DecorationItemInstanceExtensionIsInstalled.Title = NStr("en = 'Выполняется установка расширения для работы с криптографией';");
	Else
		Items.DecorationItemInstanceExtensionIsInstalled.Title = NStr("en = 'Расширение для работы с криптографией не установлено';");
	EndIf;
	
	If InstallationStateOfExtraCryptoAPIComponent = 2 Then
		Items.ComponentDecorationIsInstalled.Title = NStr("en = 'Компонента ExtraCryptoAPI успешно установлена';");
	ElsIf InstallationStateOfExtraCryptoAPIComponent = 1 Then
		Items.ComponentDecorationIsInstalled.Title = NStr("en = 'Выполняется установка компоненты ExtraCryptoAPI';");
	Else
		Items.ComponentDecorationIsInstalled.Title = NStr("en = 'Компонента ExtraCryptoAPI не установлена';");
	EndIf;
	
	If StateOfInstallationOfExtensionOfWorkWith1CEnterprise = 2
		And StateOfCryptographyExtensionInstallation = 2
		And InstallationStateOfExtraCryptoAPIComponent = 2 Then
		
		Items.GroupInstallSimultaneously.Visible = False;
		
		If StateOfCryptoproviderInstallation = 2 Then
			Items.InstallationGroupHeader.Visible = False;
			Items.GroupContinuesToWork.Visible = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InstallCryptographyProgram()
	DigitalSignatureInternalClient.OpenFormForInstallingCryptoproviderPrograms(, ThisObject);
EndProcedure

&AtClient
Procedure AfterInstallingCryptographyProgram()
	
	StateOfCryptoproviderInstallation = 2;
	SetValueOfDecorationsDependingOnStateOfComponentInstallation();
	
EndProcedure

&AtClient
Procedure AfterInstallingExtensionOfWorkWith1CEnterprise(Result) Export
	
	BeginAttachingFileSystemExtension(
		New CallbackDescription("ContinueInstallingComponentAfterInstallingExtensionOfWorkWith1CEnterprise", ThisObject));
	
EndProcedure

&AtClient
Procedure ContinueInstallingComponentAfterInstallingExtensionOfWorkWith1CEnterprise(Attached, Context = Undefined) Export
	
	If Attached = True Then
		StateOfInstallationOfExtensionOfWorkWith1CEnterprise = 2;
		AfterInstallingComponentsAndExtensions();
	Else
		AttachIdleHandler("ExpectInstallationOfExpansionOfWorkWith1CEnterprise", 3);
	EndIf;
	
	If StateOfCryptographyExtensionInstallation = 2 Then
		ContinueInstallingComponentAfterInstallingCryptographyExtension(True);
	Else
		StateOfCryptographyExtensionInstallation = 1;
		SetValueOfDecorationsDependingOnStateOfComponentInstallation();
		BeginInstallCryptoExtension(New CallbackDescription(
			"AfterInstallingCryptographyExtension", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Async Procedure ExpectInstallationOfExpansionOfWorkWith1CEnterprise()
	
	Attached = Await AttachFileSystemExtensionAsync();
	If Attached Then
		DetachIdleHandler("ExpectInstallationOfExpansionOfWorkWith1CEnterprise");
		StateOfInstallationOfExtensionOfWorkWith1CEnterprise = 2;
		AfterInstallingComponentsAndExtensions();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterInstallingCryptographyExtension(Context) Export
	
	BeginAttachingCryptoExtension(New CallbackDescription(
		"ContinueInstallingComponentAfterInstallingCryptographyExtension", ThisObject, Context));
	
EndProcedure

&AtClient
Async Procedure ContinueInstallingComponentAfterInstallingCryptographyExtension(Attached, Context = Undefined) Export
	
	If Attached = True Then
		Notify("InstallCryptoExtension");
		StateOfCryptographyExtensionInstallation = 2;
		AfterInstallingComponentsAndExtensions();
	Else
		AttachIdleHandler("ExpectToInstallExtensionToWorkWithCryptography", 3);
	EndIf;
	
	If InstallationStateOfExtraCryptoAPIComponent = 2 Then
		AfterInstallingComponentsAndExtensions();
	Else
		ConnectionParameters = CommonClient.AddInAttachmentParameters();
		ConnectionParameters.SuggestInstall = True;
		ConnectionParameters.SuggestToImport = True;
		ConnectionParameters.ShowInstallationIssue = False;
		ComponentDetails = DigitalSignatureInternalClientServer.ComponentDetails();
		
		InstallationStateOfExtraCryptoAPIComponent = 1;
		SetValueOfDecorationsDependingOnStateOfComponentInstallation();
		
		Result = Await CommonClient.AttachAddInFromTemplateAsync(
			ComponentDetails.ObjectName,
			ComponentDetails.FullTemplateName,
			ConnectionParameters);
		
		If Result.Attached Then
			InstallationStateOfExtraCryptoAPIComponent = 2;
			AfterInstallingComponentsAndExtensions();
		EndIf;
	EndIf;

EndProcedure

&AtClient
Async Procedure ExpectToInstallExtensionToWorkWithCryptography()
	
	Attached = Await AttachCryptoExtensionAsync();
	If Attached Then
		DetachIdleHandler("ExpectToInstallExtensionToWorkWithCryptography");
		StateOfCryptographyExtensionInstallation = 2;
		AfterInstallingComponentsAndExtensions();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterInstallingComponentsAndExtensions()
	
	// Если установлены еще не все необходимые компоненты для загрузки программы криптографии или токена,
	// то только актуализируем состояние установки компоненты.
	If StateOfInstallationOfExtensionOfWorkWith1CEnterprise = 2
		And StateOfCryptographyExtensionInstallation = 2
		And InstallationStateOfExtraCryptoAPIComponent = 2 Then
		
		CheckInstallationOfCryptoproviderAfterInstallingComponentsAndExtensions();
		
	Else
		SetValueOfDecorationsDependingOnStateOfComponentInstallation();
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckInstallationOfCryptoproviderAfterInstallingComponentsAndExtensions()
	
	If DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer()
		Or DigitalSignatureClient.GenerateDigitalSignaturesAtServer()
		Or DigitalSignatureInternalClient.UseCloudSignatureService()
		Or DigitalSignatureInternalClient.UseDigitalSignatureSaaS()
		Or Not CheckCryptoprovider Then
		
		SetValueOfDecorationsDependingOnStateOfComponentInstallation();
		Return;
		
	EndIf;
	
	If Not NameOfRequiredComponent = "CryptographyProgram"
		And Not Items.CryptoproviderInstallationVerificationGroup.Visible Then
		
		CheckParameters = New Structure;
		CheckParameters.Insert("ShouldPromptToInstallApp", False);
		
		StateOfCryptoproviderInstallation = 1;
		Items.CryptoproviderInstallationVerificationGroup.Visible = True;
		Items.CryptoproviderInstallationStateGroup.Visible = False;
		Items.GroupIsBeingVerified.Visible = True;
		
		DigitalSignatureInternalClient.CheckCryptographyAppsInstallation(ThisObject, CheckParameters,
			New CallbackDescription("AfterCheckingInstallationOfCryptographyPrograms", ThisObject));
			
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCheckingInstallationOfCryptographyPrograms(Result, Context) Export
	
	If Result.CheckCompleted Then
		
		CryptoproviderIsInstalled = Result.Tokens.Count() > 0;
		
		If Not CryptoproviderIsInstalled Then
			For Each Cryptoprovider In Result.Programs Do
				If ValueIsFilled(Cryptoprovider.Application) And Not CryptoproviderIsInstalled Then
					CryptoproviderIsInstalled = True;
				EndIf;
			EndDo;
		EndIf;
		
		If CryptoproviderIsInstalled Then
			StateOfCryptoproviderInstallation = 2;
		Else
			Items.CryptoproviderInstallationVerificationGroup.Visible = True;
			StateOfCryptoproviderInstallation = 0;
		EndIf;
		
		Items.CryptoproviderInstallationStateGroup.Visible = True;
		Items.GroupIsBeingVerified.Visible = False;
		
		SetValueOfDecorationsDependingOnStateOfComponentInstallation();
		
	EndIf;
	
EndProcedure

#EndRegion