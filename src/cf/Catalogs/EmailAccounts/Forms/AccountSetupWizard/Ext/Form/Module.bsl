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
	
	Title = NStr("en = 'Account setup'");
	AuthenticationOption = "OAuth";
	
	Items.GoToSettingsButton.Visible = False;
	Items.BackButton.Visible = False;
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
	Else
		UseSecurityProfiles = False;
	EndIf;
	
	If UseSecurityProfiles Then
		SetupMethod = ManualSetting();
	Else
		SetupMethod = AutomaticSetting();
	EndIf;
	
	CanReceiveEmails = EmailOperationsInternal.SubsystemSettings().CanReceiveEmails;
	ShouldUsePOP3Protocol = EmailOperationsInternal.SubsystemSettings().ShouldUsePOP3Protocol;
	
	If Not ShouldUsePOP3Protocol Then
		Protocol = "IMAP";
	EndIf;
	
	ContextMode = Parameters.ContextMode;
	Reconfigure = Parameters.Reconfigure;
	
	UseForReceiving = Not ContextMode And CanReceiveEmails;
	UseForSending = True;
	AuthorizationRequiredOnSendMail = True;
	
	Items.EmailSenderName.Visible = Not ContextMode;
	Items.UseForReceiving.Visible = Not ContextMode And CanReceiveEmails;
	Items.Pages.CurrentPage = Items.EnteringEmailMailAddress;
	
	WindowOptionsKey = ?(ContextMode, "ContextMode", "NoContextMode");
	
	If ValueIsFilled(Parameters.Key) Then
		AccountRef = Parameters.Key;
		AuthenticationOption = "Password";
		PopulateUserAccountProperties();
	Else
		NewAccountRef = Catalogs.EmailAccounts.GetRef();
		
		If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
			
			ModuleContactsManager = Common.CommonModule("ContactsManager");
			TypeEmail = ModuleContactsManager.TypeEmail();
			ObjectContactInformation = ModuleContactsManager.ObjectContactInformation(
				Users.CurrentUser(), TypeEmail, , False);
			
			For Each Contact In ObjectContactInformation Do
				Address = Contact.Presentation;
				If Catalogs.EmailAccounts.FindByAttribute("Email", Address).IsEmpty() Then
					Email = Address;
					EmailSenderName = String(Users.CurrentUser());
					Break;
				EndIf;
			EndDo;
			
		EndIf;
	EndIf;
	
	IsFullUser = Users.IsFullUser();
	Items.UserAccountKind.Visible = IsFullUser And Not ContextMode;
	UserAccountKind = ?(IsFullUser, "Shared3", "Personal1");
	
	If Common.IsMobileClient() Then
		Items.Password.HorizontalStretch = True;
		Items.Password.TitleLocation = FormItemTitleLocation.Auto;
	EndIf;
	
	Items.AssistanceRequiredGroup.Visible = False;
	
	// StandardSubsystems.SupportRequests
	If Common.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternal = Common.CommonModule(
			"SupportRequestsInternal");
		
		ModuleSupportRequestsInternal.OnCreateAtServer(ThisObject);
		
	Else
		Items.AssistanceRequiredGroup.Visible = False;
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("AdjustCurrentPageElementsOnOpening", 0.1, True);
	AttachIdleHandler("CheckAvailabilityOfOpenAuthorizationService", 0.1, True);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not FormClosingConfirmationRequired Then
		Return;
	EndIf;
	
	Cancel = True;
	
	If Exit Then
		Return;
	EndIf;
	
	AttachIdleHandler("ShowQueryBoxBeforeCloseForm", 0.1, True);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName <> "OpenAuthorizationOfMailService" Then
		Return;
	EndIf;
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	KeyReceiptAddress = AuthorizationSettings.KeyReceiptAddress;
	
	If QueryID <> String(Parameter.QueryID) Then
		ErrorsMessages = NStr("en = 'Cannot authorize on the mail server. Incorrect response ID.'");
		ValidationCompletedWithErrors = True;
	ElsIf Not GetAccessKeysToMailServer(Parameter.AuthorizationCode, KeyReceiptAddress) Then
		ValidationCompletedWithErrors = True;
	EndIf;
	
	If ValidationCompletedWithErrors Then
		FillinExplanations();
	EndIf;
	
	GotoNextPage();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PasswordOnChange(Item)
	
	PasswordForSendingEmails = PasswordForReceivingEmails;
	
EndProcedure

&AtClient
Procedure PasswordStartChoice(Item, ChoiceData, StandardProcessing)
	
	EmailOperationsClient.PasswordFieldStartChoice(Item, PasswordForReceivingEmails, StandardProcessing);
	
EndProcedure

&AtClient
Procedure EmailOnChange(Item)
	
	SettingsFilled = False;
	FormClosingConfirmationRequired = True;
	
EndProcedure

&AtClient
Procedure EmailSenderNameOnChange(Item)
	
	FormClosingConfirmationRequired = True;
	
EndProcedure

&AtClient
Procedure DecorationTechnicalDetailsClick(Item)
	
	Items.Pages.CurrentPage = Items.TechnicalDetails;
	Items.BackButton.Visible = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	GotoNextPage(Command);
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	CurrentPage = Items.Pages.CurrentPage;
	
	PreviousPage = Undefined;
	
	If CurrentPage = Items.AccountSettings1 Then
		PreviousPage = Items.EnteringEmailMailAddress;
	ElsIf CurrentPage = Items.Authorization Or CurrentPage = Items.EnteringAccountPassword Then
		
		If Not ContextMode Then
			PreviousPage = Items.AccountSettings1;
		Else
			PreviousPage = Items.EnteringEmailMailAddress;
		EndIf;
		
	ElsIf CurrentPage = Items.ErrorsFoundOnCheck Then
		
		If ValueIsFilled(AppID) Then
			PreviousPage = Items.AccountSettings1;
		Else
			PreviousPage = Items.EnteringAccountPassword;
			ValidationCompletedWithErrors = False;
		EndIf;
		
	ElsIf CurrentPage = Items.TechnicalDetails Then
		PreviousPage = Items.ErrorsFoundOnCheck;
	EndIf;
	
	If PreviousPage <> Undefined Then
		Items.Pages.CurrentPage = PreviousPage;
	Else
		Items.Pages.CurrentPage = Items.EnteringEmailMailAddress;
	EndIf;
	
	SetCurrentPageItems();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	CancelJobExecution(JobID);
	Close(False);
	
EndProcedure

&AtClient
Procedure GoToSettings(Command)
	
	CurrentPage = Items.Pages.CurrentPage;
	
	If Not ContextMode And CurrentPage = Items.AccountConfigured Then
		ShowValue(,AccountRef);
		Close(True);
	Else
		OpenManualSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure SupportTicket(Command)
	
	// StandardSubsystems.SupportRequests
	If CommonClient.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternalClient = CommonClient.CommonModule(
			"SupportRequestsInternalClient");
		
		If ValueIsFilled(BriefErrorDetails) Then
			DetailsForRequestTopic = BriefErrorDetails;
		Else
			DetailsForRequestTopic = ErrorsMessages;
		EndIf;
		
		RequestParameters_ = ModuleSupportRequestsInternalClient.RequestParameters_();
		RequestParameters_.TechnologicalInfo = ErrorsMessages;
		RequestParameters_.EventLogFilter.Insert("StartDate", ErrorRegistrationTime);
		
		RequestParameters_.Subject = EmailOperationsInternalClient.SupportRequestTopic(
			DetailsForRequestTopic);
		
		RequestParameters_.Message = EmailOperationsInternalClient.SupportRequestText(
			Email,
			DetailsForRequestTopic);
		
		ModuleSupportRequestsInternalClient.SubmitSupportTicket(
			ThisObject,
			RequestParameters_);
		
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

&AtClient
Procedure InfoForSupport(Command)
	
	// StandardSubsystems.SupportRequests
	If CommonClient.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternalClient = CommonClient.CommonModule(
			"SupportRequestsInternalClient");
		
		RequestParameters_ = ModuleSupportRequestsInternalClient.RequestParameters_();
		RequestParameters_.TechnologicalInfo = ErrorsMessages;
		RequestParameters_.EventLogFilter.Insert("StartDate", ErrorRegistrationTime);
		
		ModuleSupportRequestsInternalClient.DownloadInfoForSupport(
			ThisObject,
			RequestParameters_);
		
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenManualSettings()
	
	AccountParameters1 = AccountParameters1();
	CompletionHandler = New CallbackDescription("AfterManuallySettingUpAccount", ThisObject);
	
	OpenForm("Catalog.EmailAccounts.Form.ItemForm", AccountParameters1, , , , ,
		CompletionHandler, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure PopulateUserAccountProperties()
	
	QueryText =
	"SELECT
	|	EmailAccounts.Email AS Email,
	|	EmailAccounts.UserName AS EmailSenderName,
	|	EmailAccounts.Description AS AccountName,
	|	EmailAccounts.EmailServiceAuthorization
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.Ref = &Ref";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", AccountRef);
	
	Selection = Query.Execute().Select();
	
	If Not Selection.Next() Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, Selection);
	OnlyAuthorization = Parameters.OnlyAuthorization;
	
	If Selection.EmailServiceAuthorization Or OnlyAuthorization Then
		
		AuthenticationOption = "OAuth";
		
		If OnlyAuthorization Then
			
			SettingsAuthorizationOnMailServer = SettingsAuthorizationOnMailServer();
			AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
			
			If ValueIsFilled(AuthorizationSettings) And ValueIsFilled(AuthorizationSettings.AppID) Then
				
				AppID = AuthorizationSettings.AppID;
				RedirectAddress = AuthorizationSettings.RedirectAddress;
				
				If IsWebClient() And Not OpenAuthorizationOfMailServiceHasBeenPublished Then
					RedirectAddress = AuthorizationSettings.RedirectionAddressWebClient;
				EndIf;
				
				ApplicationPassword = AuthorizationSettings.ApplicationPassword;
				Items.Pages.CurrentPage = Items.Authorization;
				
				If IsWebClient() And Not OpenAuthorizationOfMailServiceHasBeenPublished Then
					Items.AuthorizationOptions.CurrentPage = Items.OperatingSystemBrowser;
					CurrentItem = Items.WebPage;
				Else
					Items.AuthorizationOptions.CurrentPage = Items.EmbeddedBrowser;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowQueryBoxBeforeCloseForm()
	
	QueryText = NStr("en = 'Changes are not saved. Close the form?'");
	CallbackDescription = New CallbackDescription("CloseFormConfirmed", ThisObject);
	Buttons = New ValueList;
	Buttons.Add("Close", NStr("en = 'Close'"));
	Buttons.Add(DialogReturnCode.Cancel, NStr("en = 'Do not close'"));
	ShowQueryBox(CallbackDescription, QueryText, Buttons, , DialogReturnCode.Cancel, NStr("en = 'Account setup'"));
	
EndProcedure

&AtClient
Procedure CloseFormConfirmed(QuestionResult, AdditionalParameters = Undefined) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	FormClosingConfirmationRequired = False;
	Close(False);
	
EndProcedure

&AtClient
Procedure GotoNextPage(Command = Undefined)
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	CurrentPage = Items.Pages.CurrentPage;
	NextPage = Undefined;
	Cancel = False;
	
	If CurrentPage = Items.EnteringEmailMailAddress Then
		
		ValidationCompletedWithErrors = False;
		CheckCompletionOfMailAddress(Cancel);
		
		If Not Cancel And Not SettingsFilled Then
			FillAccountSettings();
		EndIf;
		
		If Not Cancel Then
			
			SettingsAuthorizationOnMailServer = SettingsAuthorizationOnMailServer();
			AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
			
			FillInTitleOfAssistant();
			
			If Not ContextMode Then
				NextPage = Items.AccountSettings1;
			Else
				DefineAuthenticationOption(NextPage, AuthorizationSettings);
			EndIf;
			
		EndIf;
		
	ElsIf CurrentPage = Items.AccountSettings1 Then
		
		DefineAuthenticationOption(NextPage, AuthorizationSettings);
		
	ElsIf CurrentPage = Items.Authorization Then
		
		If IsWebClient() And Not OpenAuthorizationOfMailServiceHasBeenPublished
			And Not ValueIsFilled(AuthorizationSettings.DeviceRegistrationAddress) Then
			
			If Not GetAccessKeysToMailServer(ConfirmationCode, AuthorizationSettings.KeyReceiptAddress, ClientApplication.GetShortCaption()) Then
				ValidationCompletedWithErrors = True;
			EndIf;
			
		EndIf;
		
		If OnlyAuthorization Then
			FormClosingConfirmationRequired = False;
			If Not ValidationCompletedWithErrors Then
				Close(WriteAuthorizationSettings());
				Return;
			EndIf;
		EndIf;
		
		If ValidationCompletedWithErrors Then
			NextPage = Items.ErrorsFoundOnCheck;
		Else
			NextPage = Items.ValidatingAccountSettings;
		EndIf;
		
	ElsIf CurrentPage = Items.EnteringAccountPassword Then
		
		If IsBlankString(PasswordForReceivingEmails) Then
			CommonClient.MessageToUser(NStr("en = 'Enter the account password'"), , "Password");
			Return;
		EndIf;
		
		NextPage = Items.ValidatingAccountSettings;
		
	ElsIf CurrentPage = Items.ValidatingAccountSettings Then
		
		If Command = Undefined Then
			If ValidationCompletedWithErrors Then
				NextPage = Items.ErrorsFoundOnCheck;
				FillinExplanations();
			ElsIf CheckMissed And SetupMethod = AutomaticSetting() Then
				OpenManualSettings();
				Return;
			Else
				NextPage = Items.AccountConfigured;
			EndIf;
			CheckMissed = False;
		Else
			CancelJobExecution(JobID);
			JobID = "";
			CheckMissed = True;
			GotoNextPage();
			Return;
		EndIf;
		
	ElsIf CurrentPage = Items.ErrorsFoundOnCheck Then
		NextPage = Items.ValidatingAccountSettings;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	If NextPage = Undefined Then
		Close(True);
	Else
		Items.Pages.CurrentPage = NextPage;
		SetCurrentPageItems();
	EndIf;
	
	If Items.Pages.CurrentPage = Items.ValidatingAccountSettings Then
		If SetupMethod = AutomaticSetting() Then
			AttachIdleHandler("SetUpConnectionParametersAutomatically", 0.1, True);
		Else
			AttachIdleHandler("ExecuteSettingsCheck", 0.1, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DefineAuthenticationOption(NextPage, AuthorizationSettings)
	
	AppID = AuthorizationSettings.AppID;
	ApplicationPassword = AuthorizationSettings.ApplicationPassword;
	
	If AuthenticationOption = "OAuth" And ValueIsFilled(AppID) Then
		
		If IsWebClient() And Not OpenAuthorizationOfMailServiceHasBeenPublished And Not AvailableAuthorizationByCode() Then
			AuthenticationOption = "Password";
			NextPage = Items.EnteringAccountPassword;
			FillInPasswordPrompt();
		Else
			
			NextPage = Items.Authorization;
			RedirectAddress = AuthorizationSettings.RedirectAddress;
			
			If IsWebClient() And Not OpenAuthorizationOfMailServiceHasBeenPublished Then
				RedirectAddress = AuthorizationSettings.RedirectionAddressWebClient;
			EndIf;
			
			If Not ValueIsFilled(RedirectAddress) Then
				RedirectAddress = AuthorizationSettings.RedirectAddressDefault;
			EndIf;
			
			AttachIdleHandler("LoginAtMailServer", 0.1, True);
			
		EndIf
	Else
		AuthenticationOption = "Password";
		NextPage = Items.EnteringAccountPassword;
		FillInPasswordPrompt();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPasswordPrompt();
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	If Not ValueIsFilled(AuthorizationSettings) Then
		Return;
	EndIf;
	
	If ValueIsFilled(AuthorizationSettings.PasswordInputHint) Then
		Items.Password.ExtendedTooltip.Title = AuthorizationSettings.PasswordInputHint;
	EndIf
	
EndProcedure

&AtClient
Procedure ExecuteSettingsCheck()
	
	ClosingNotification1 = New CallbackDescription("CheckSettingsPermissionRequestExecuted", ThisObject);
	
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		
		Query = CreateRequestToUseExternalResources();
		
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(
			CommonClientServer.ValueInArray(Query), ThisObject, ClosingNotification1);
		
	Else
		RunCallback(ClosingNotification1, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckSettingsPermissionRequestExecuted(QueryResult, AdditionalParameters) Export
	
	If Not QueryResult = DialogReturnCode.OK Then
		Return;
	EndIf;
	
	ValidateAccountSettings();
	
	If ValueIsFilled(AccountRef) Then 
		CommonClient.NotifyObjectChanged(AccountRef);
	EndIf;
	
	GotoNextPage();
	
EndProcedure

&AtServer
Function CreateRequestToUseExternalResources()
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Return ModuleSafeModeManager.RequestToUseExternalResources(
		Permissions(), NewAccountRef);
	
EndFunction

&AtServer
Function Permissions()
	
	Result = New Array;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	If UseForSending Then
		Result.Add(
			ModuleSafeModeManager.PermissionToUseInternetResource(
				"SMTP",
				OutgoingMailServer,
				OutgoingMailServerPort,
				NStr("en = 'Email.'")));
	EndIf;
	
	If UseForReceiving Then
		Result.Add(
			ModuleSafeModeManager.PermissionToUseInternetResource(
				Protocol,
				IncomingMailServer,
				IncomingMailServerPort,
				NStr("en = 'Email.'")));
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure CheckCompletionOfMailAddress(Cancel)
	
	ClearMessages();
	
	If IsBlankString(Email) Then
		CommonClient.MessageToUser(NStr("en = 'Email address required'"), , "Email", , Cancel);
	ElsIf Not CommonClientServer.EmailAddressMeetsRequirements(Email, True) Then
		CommonClient.MessageToUser(NStr("en = 'Invalid email address'"), , "Email", , Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetCurrentPageItems()
	
	CurrentPage = Items.Pages.CurrentPage;
	
	If CurrentPage = Items.AccountConfigured Then
		If ContextMode Then
			ButtonNextTitle = NStr("en = 'Next >'");
		Else
			ButtonNextTitle = NStr("en = 'Close'");
		EndIf;
	Else
		If CurrentPage = Items.ValidatingAccountSettings Then
			ButtonNextTitle = NStr("en = 'Skip test'");
		Else
			ButtonNextTitle = NStr("en = 'Next >'");
		EndIf;
	EndIf;
	
	If Not ContextMode And CurrentPage = Items.AccountConfigured Then
		Items.GoToSettingsButton.Title = NStr("en = 'Settings'");
	Else
		Items.GoToSettingsButton.Title = NStr("en = 'Manual setup'");
	EndIf;
	
	Items.NextButton.Title = ButtonNextTitle;
	Items.NextButton.DefaultButton = CurrentPage <> Items.ValidatingAccountSettings;
	Items.NextButton.Enabled = Not (CurrentPage = Items.ValidatingAccountSettings And CheckMissed);
	Items.NextButton.Visible = Not (CurrentPage = Items.ValidatingAccountSettings And SetupMethod = ManualSetting())
		And Not (CurrentPage = Items.Authorization And Not IsWebClient())
		And Not CurrentPage = Items.ErrorsFoundOnCheck;
	
	Items.BackButton.Visible = CurrentPage <> Items.EnteringEmailMailAddress
		And CurrentPage <> Items.AccountConfigured
		And CurrentPage <> Items.ValidatingAccountSettings
		And Not OnlyAuthorization;
	
	Items.CancelButton.Visible = CurrentPage <> Items.AccountConfigured;
	Items.GoToSettingsButton.Visible = Not UseSecurityProfiles
		And (CurrentPage = Items.ErrorsFoundOnCheck And ValidationCompletedWithErrors
			Or Not ContextMode And Not Reconfigure And CurrentPage = Items.AccountConfigured)
		And Not OnlyAuthorization;
	
	If CurrentPage = Items.AccountConfigured Then
		Items.AccountConfiguredLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Email account
				|%1 is set up successfully.'"), Email);
	EndIf;
	
	If CurrentPage = Items.Authorization And Items.AuthorizationOptions.CurrentPage = Items.EmbeddedBrowser Then
		Activate();
		AttachIdleHandler("CheckAuthenticationResult", 5, True );
	EndIf;
	
	If CurrentPage <> Items.ErrorsFoundOnCheck Then
		HideNeedHelpSection();
	EndIf;
	
EndProcedure

&AtServer
Procedure HideNeedHelpSection()
	
	// StandardSubsystems.SupportRequests
	If Common.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternal = Common.CommonModule(
		"SupportRequestsInternal");
		
		ModuleSupportRequestsInternal.HideNeedHelpSection(Items);
		
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

&AtClient
Procedure FillAccountSettings()
	
	DefaultSettings = DefaultSettings(Email, PasswordForReceivingEmails);
	FillPropertyValues(ThisObject, DefaultSettings);
	
	If IsBlankString(AccountName) Then
		AccountName = Email;
	EndIf;
	
	SettingsFilled = True;
	
	EncryptOnSendMail = ?(UseSecureConnectionForOutgoingMail, "SSL", "Auto");
	EncryptOnReceiveMail = ?(UseSecureConnectionForIncomingMail, "SSL", "Auto");
	
	FillInDescriptionOfDefaultSettings(DefaultSettings);
	
EndProcedure

&AtServerNoContext
Function DefaultSettings(Email, Password)
	
	Position = StrFind(Email, "@");
	ServerNameInAccount = Mid(Email, Position + 1);
	
	Settings = New Structure;
	
	Settings.Insert("UsernameForReceivingEmails", Email);
	Settings.Insert("UsernameToSendMail", Email);
	
	Settings.Insert("PasswordForSendingEmails", Password);
	Settings.Insert("PasswordForReceivingEmails", Password);
	
	Settings.Insert("Protocol", "IMAP");
	Settings.Insert("IncomingMailServer", "imap." + ServerNameInAccount);
	Settings.Insert("IncomingMailServerPort", 993);
	Settings.Insert("UseSecureConnectionForIncomingMail", True);
	
	Settings.Insert("OutgoingMailServer", "smtp." + ServerNameInAccount);
	Settings.Insert("OutgoingMailServerPort", 587);
	Settings.Insert("UseSecureConnectionForOutgoingMail", False);
	
	Settings.Insert("ServerTimeout", 10);
	Settings.Insert("KeepEmailCopiesOnServer", True);
	Settings.Insert("KeepMailAtServerPeriod", 10);
	
	IMAPDefaultSettings = Catalogs.EmailAccounts.IMAPServerConnectionSettingsOptions(Email)[0];
	SMTPDefaultSettings = Catalogs.EmailAccounts.SMTPServerConnectionSettingsOptions(Email)[0];
	
	FillPropertyValues(Settings, IMAPDefaultSettings);
	FillPropertyValues(Settings, SMTPDefaultSettings);
	
	Return Settings;
	
EndFunction

&AtClient
Procedure FillInDescriptionOfDefaultSettings(DefaultSettings)
	
	DefaultSettingsDescriptionTemplate = NStr("en = 'Default settings are used.
		|Protocol: %1
		|
		|Incoming mail server: %2
		|Port of the incoming mail server: %3
		|Use SSL-connection for incoming mail: %4
		|
		|Outgoing mail server: %5
		|Port of outgoing mail server: %6
		|Use SSL-connection for outgoing mail: %7'");
	
	DescriptionOfDefaultSettings = StringFunctionsClientServer.SubstituteParametersToString(
		DefaultSettingsDescriptionTemplate,
		DefaultSettings.Protocol,
		DefaultSettings.IncomingMailServer,
		DefaultSettings.IncomingMailServerPort,
		DefaultSettings.UseSecureConnectionForIncomingMail,
		DefaultSettings.OutgoingMailServer,
		DefaultSettings.OutgoingMailServerPort,
		DefaultSettings.UseSecureConnectionForOutgoingMail);
	
	Items.DescriptionOfDefaultSettings.Title = DescriptionOfDefaultSettings;
	
EndProcedure

&AtServer
Procedure ValidateAccountSettings()
	
	OutgoingMailProfile = Undefined;
	If UseForSending Then
		OutgoingMailProfile = InternetMailProfile(False);
	EndIf;
	
	IncomingMailProfile = Undefined;
	If UseForReceiving Then
		IncomingMailProfile = InternetMailProfile(True);
	EndIf;
	
	CheckResult = Catalogs.EmailAccounts.CheckProfilesSettings(
		OutgoingMailProfile, IncomingMailProfile, Email);
	
	ErrorsMessages = CheckResult.ConnectionErrors;
	ValidationCompletedWithErrors = ValueIsFilled(ErrorsMessages);
	
	If Not ValidationCompletedWithErrors And Not CheckMissed Then
		Try
			NewAccount1();
		Except
			ValidationCompletedWithErrors = True;
			ErrorsMessages = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
	EndIf;
	
	If ValidationCompletedWithErrors Then
		
		ErrorRegistrationTime = CurrentSessionDate();
		FillinExplanations();
		
		// StandardSubsystems.SupportRequests
		If Common.SubsystemExists("StandardSubsystems.SupportRequests") Then
			
			ModuleSupportRequestsInternal = Common.CommonModule(
				"SupportRequestsInternal");
			
			ModuleSupportRequestsInternal.ShowNeedHelpSection(Items);
			
		EndIf;
		// End StandardSubsystems.SupportRequests
		
	EndIf;
	
EndProcedure

&AtServer
Procedure NewAccount1()
	
	ConvertSettingsFromPunycode();
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	SystemAccount = Catalogs.EmailAccounts.SystemEmailAccount;
	SetUpSystemAccount = ContextMode And UserAccountKind = "Shared3"
		And Not EmailOperations.AccountSetUp(SystemAccount)
		And Catalogs.EmailAccounts.EditionAllowed(SystemAccount);
	
	If SetUpSystemAccount Then
		AccountRef = SystemAccount;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.EmailAccounts");
	If Not AccountRef.IsEmpty() Then
		LockItem.SetValue("Ref", AccountRef);
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Block.Lock();
		
		If AccountRef.IsEmpty() Then
			Account = Catalogs.EmailAccounts.CreateItem();
			Account.SetNewObjectRef(NewAccountRef);
		Else
			Account = AccountRef.GetObject();
		EndIf;
		
		FillPropertyValues(Account, ThisObject);
		Account.UserName = EmailSenderName;
		Account.User = UsernameForReceivingEmails;
		Account.SMTPUser = UsernameToSendMail;
		Account.Timeout = ServerTimeout;
		Account.KeepMessageCopiesAtServer = KeepEmailCopiesOnServer;
		Account.KeepMailAtServerPeriod = ?(KeepEmailCopiesOnServer And DeleteMailFromServer And Protocol = "POP", KeepMailAtServerPeriod, 0);
		Account.ProtocolForIncomingMail = Protocol;
		Account.Description = AccountName;
		Account.AuthorizationRequiredOnSendEmails = ValueIsFilled(Account.SMTPUser);
		
		If UserAccountKind = "Personal1" Then
			Account.AccountOwner = Users.CurrentUser();
		Else
			Account.AccountOwner = Catalogs.Users.EmptyRef();
		EndIf;
		
		If AuthenticationOption = "OAuth" Then
			Account.EmailServiceAuthorization = True;
			Account.EmailServiceName = AuthorizationSettings.InternetServiceName;
		EndIf;
		
		Account.AdditionalProperties.Insert("DoNotCheckSettingsForChanges");
		Account.Write();
		
		AccountRef = Account.Ref;
		FormClosingConfirmationRequired = False;
		
		SetPrivilegedMode(True);
		
		Common.DeleteDataFromSecureStorage(AccountRef);
		
		If AuthenticationOption = "OAuth" Then
			WriteAuthorizationSettings();
		Else
			Common.WriteDataToSecureStorage(AccountRef, PasswordForReceivingEmails);
			Common.WriteDataToSecureStorage(AccountRef, PasswordForSendingEmails, "SMTPPassword");
		EndIf;
		
		SetPrivilegedMode(False);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		WriteLogEvent(NStr("en = 'Email management'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , AccountRef, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
		
	EndTry;
	
EndProcedure

&AtServer
Function WriteAuthorizationSettings()
	
	SetPrivilegedMode(True);
	
	Common.WriteDataToSecureStorage(AccountRef, AccessToken, "AccessToken");
	Common.WriteDataToSecureStorage(AccountRef, AccessTokenValidity, "AccessTokenValidity");
	Common.WriteDataToSecureStorage(AccountRef, UpdateToken, "UpdateToken");
	
	SetPrivilegedMode(False);
	
	Return Common.CheckSumString(AccessToken + UpdateToken);
	
EndFunction

&AtServer
Function InternetMailProfile(ForReceiving = False)
	
	Profile = New InternetMailProfile;
	
	If ForReceiving Or SignInBeforeSendingRequired Then
		If Protocol = "IMAP" Then
			Profile.IMAPServerAddress = IncomingMailServer;
			Profile.IMAPUseSSL = UseSecureConnectionForIncomingMail;
			Profile.IMAPPassword = PasswordForReceivingEmails;
			Profile.IMAPUser = UsernameForReceivingEmails;
			Profile.IMAPPort = IncomingMailServerPort;
		Else
			Profile.POP3ServerAddress = IncomingMailServer;
			Profile.POP3UseSSL = UseSecureConnectionForIncomingMail;
			Profile.Password = PasswordForReceivingEmails;
			Profile.User = UsernameForReceivingEmails;
			Profile.POP3Port = IncomingMailServerPort;
		EndIf;
	EndIf;
	
	If Not ForReceiving Then
		Profile.POP3BeforeSMTP = SignInBeforeSendingRequired;
		Profile.SMTPServerAddress = OutgoingMailServer;
		Profile.SMTPUseSSL = UseSecureConnectionForOutgoingMail;
		Profile.SMTPPassword = PasswordForSendingEmails;
		Profile.SMTPUser = UsernameToSendMail;
		Profile.SMTPPort = OutgoingMailServerPort;
	EndIf;
	
	Profile.Timeout = ServerTimeout;
	
	If AuthenticationOption = "OAuth" Then
		Profile.TokenAuthentication = UseInternetMailTokenAuthentication.Use;
		Profile.AccessToken = AccessToken;
	EndIf;
	
	Return Profile;
	
EndFunction

&AtClient
Procedure SetUpConnectionParametersAutomatically()
	
	ErrorsMessages = NStr("en = 'Couldn''t configure email server settings.
		|Please provide settings manually.'");
	
	ValidationCompletedWithErrors = False;
	
	TimeConsumingOperation = StartSearchAccountSettings();
	JobID = TimeConsumingOperation.JobID;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	CallbackDescription = New CallbackDescription("OnCompleteSettingsSearch", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

&AtServer
Function StartSearchAccountSettings()
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Look up mail server settings'");
	
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "Catalogs.EmailAccounts.DefineAccountSettings",
		Email, PasswordForReceivingEmails, UseForSending, UseForReceiving);
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure OnCompleteSettingsSearch(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		If Not CheckMissed And IsOpen() Then
			GotoNextPage();
		EndIf;
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		ValidationCompletedWithErrors = True;
		GotoNextPage();
		
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		
		Return;
	EndIf;
	
	FoundSettings = GetFromTempStorage(Result.ResultAddress);
	
	ValidationCompletedWithErrors = UseForSending And Not FoundSettings.ForSending 
		Or UseForReceiving And Not FoundSettings.ForReceiving;
		
	FillPropertyValues(ThisObject, FoundSettings);
	EncryptOnSendMail = ?(UseSecureConnectionForOutgoingMail, "SSL", "Auto");
	EncryptOnReceiveMail = ?(UseSecureConnectionForIncomingMail, "SSL", "Auto");
	
	If Not FoundSettings.SettingsCheckCompleted Then
		AttachIdleHandler("ExecuteSettingsCheck", 0.1, True);
		Return;
	EndIf;
	
	If Not ValidationCompletedWithErrors And Not CheckMissed Then
		Try
			NewAccount1();
		Except
			ValidationCompletedWithErrors = True;
			ErrorsMessages = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		If Not ValidationCompletedWithErrors Then
			CommonClient.NotifyObjectChanged(NewAccountRef);	
		EndIf;
	EndIf;
	
	GotoNextPage();
	
EndProcedure

&AtServerNoContext
Procedure CancelJobExecution(JobID)
	
	If ValueIsFilled(JobID) Then 
		TimeConsumingOperations.CancelJobExecution(JobID);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteNavigationByAddress(Val JumpAddr)
	
	AddressStructure1 = CommonClientServer.URIStructure(JumpAddr);
	
	If Not ValueIsFilled(AddressStructure1.Schema) Then
		JumpAddr = "http://" + JumpAddr;
	EndIf;
	
	If IsWebClient() Then
		FileSystemClient.OpenURL(JumpAddr);
		Return;
	EndIf;
	
	WebPage = 
	"<!DOCTYPE html>
	|<html>
	|	<body>
	|		<script language = 'javascript'>
	|			document.location.href='" + JumpAddr + "';
	|		</script>
	|		<p>Load...</p>
	|	</body>
	|</html>";
	
EndProcedure

&AtClient
Procedure LoginAtMailServer()
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	QueryAuthorizationString = QueryAuthorizationString();
	
	If IsWebClient() And Not OpenAuthorizationOfMailServiceHasBeenPublished Then
		
		If ValueIsFilled(AuthorizationSettings.DeviceRegistrationAddress) Then
			If GetAuthorizationParametersInWebClient(AuthorizationSettings.DeviceRegistrationAddress) Then
				QueryAuthorizationString = UserAuthorizationAddress;
				If Not ValueIsFilled(QueryExecutionInterval) Then
					QueryExecutionInterval = 5;
				EndIf;
				AttachIdleHandler("GetAccessKeysWebClient", QueryExecutionInterval, True);
			Else
				FillinExplanations();
				GotoNextPage();
				Return;
			EndIf;
		EndIf;
		
		Items.ExplanationByConfirmationCode.Title = StringFunctionsClient.FormattedString(NStr(
			"en = 'Authorize on the <a href=""%1"">email service page</a> and enter the received code in the field below:'"),
			QueryAuthorizationString);
		
		Items.AuthorizationOptions.CurrentPage = Items.OperatingSystemBrowser;
		
	Else
		Items.AuthorizationOptions.CurrentPage = Items.EmbeddedBrowser;
		ExecuteNavigationByAddress(QueryAuthorizationString);
	EndIf;
	
EndProcedure

&AtServer
Function QueryAuthorizationString()
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	URIStructure = CommonClientServer.URIStructure(AuthorizationSettings.AuthorizationAddress);
	ServerAddress = URIStructure.Host;
	ResourceAddress = "/" + URIStructure.PathAtServer;
	
	QueryID = String(New UUID());
	VerificationCode = EmailOperationsInternal.GenerateVerificationCode();
	
	If IsWebClient() Then
		If Not ValueIsFilled(AuthorizationSettings.DeviceRegistrationAddress) Then
			DeviceID = String(New UUID());
		EndIf;
	EndIf;
	
	QueryOptions = ParametersAuthorizationRequest();
	HTTPRequest = EmailOperationsInternal.PrepareHTTPRequest(ResourceAddress, QueryOptions, False);
	
	QueryString = "https://" + ServerAddress + HTTPRequest.ResourceAddress;
	Return QueryString; 
	
EndFunction

&AtServer
Function ParametersAuthorizationRequest()
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	QueryOptions = New Structure;
	QueryOptions.Insert("client_id", AppID);
	QueryOptions.Insert("response_type", "code");
	QueryOptions.Insert("redirect_uri", RedirectAddress);
	
	If ValueIsFilled(AuthorizationSettings["PermissionsToRequest"]) Then
		QueryOptions.Insert("scope", AuthorizationSettings["PermissionsToRequest"]);
	EndIf;
	
	If OpenAuthorizationOfMailServiceHasBeenPublished Then
		QueryOptions.Insert("state", NestedRedirectionAddress());
	Else
		QueryOptions.Insert("state", QueryID);
	EndIf;
	
	QueryOptions.Insert("login_hint", Email);
	
	If AuthorizationSettings.UsePKCEAuthenticationKey Then
		QueryOptions.Insert("code_challenge", EmailOperationsInternal.EncodeStringMethodS256(VerificationCode));
		QueryOptions.Insert("code_challenge_method", "S256");
	EndIf;
	
	If ValueIsFilled(AuthorizationSettings["AdditionalAuthorizationParameters"]) Then
		For Each Item In StrSplit(AuthorizationSettings["AdditionalAuthorizationParameters"], " ", False) Do
			ParameterDetails = StrSplit(Item, "=", True);
			ParameterName = ParameterDetails[0];
			ParameterValue = "";
			If ParameterDetails.Count() = 2 Then
				ParameterValue = ParameterDetails[1];
			EndIf;
			QueryOptions.Insert(ParameterName, ParameterValue);
		EndDo;
	EndIf;
	
	If IsWebClient() Then
		If Not ValueIsFilled(AuthorizationSettings.DeviceRegistrationAddress) Then
			QueryOptions.Insert("device_name", NStr("en = '1C:Enterprise'"));
		EndIf;
		QueryOptions.Insert("device_id", DeviceID);
	EndIf;
	
	Return QueryOptions;
	
EndFunction

&AtServer
Function NestedRedirectionAddress()
	
	TemplateForNestedRedirectAddress = "%1/hs/oauth2_mail/callback/?zone=%2&session=%3&request_id=%4&user_id=%5";
	NestedRedirectionAddress = StringFunctionsClientServer.SubstituteParametersToString(
		TemplateForNestedRedirectAddress,
		Common.InfobasePublicationURL(),
		XMLString(SessionSeparatorValue()),
		XMLString(InfoBaseSessionNumber()),
		QueryID,
		String(InfoBaseUsers.CurrentUser().UUID));
	
	Return NestedRedirectionAddress;
	
EndFunction

&AtServerNoContext
Function SessionSeparatorValue()
	
	SessionSeparatorValue = 0;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionSeparatorValue = ModuleSaaSOperations.SessionSeparatorValue();
	EndIf;
	
	Return SessionSeparatorValue;
	
EndFunction

&AtClient
Procedure WebPageDocumentComplete(Item)
	
	CheckAuthenticationResult();
	
EndProcedure

&AtClient
Procedure CheckAuthenticationResult()
	
	If OpenAuthorizationOfMailServiceHasBeenPublished Then
		ServerNotificationsClient.AttachServerNotificationReceiptCheckHandler(1, True);
		Return;
	EndIf;
	
#If Not WebClient Then
	DetachIdleHandler("CheckAuthenticationResult");
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	KeyReceiptAddress = AuthorizationSettings.KeyReceiptAddress;
	
	ServerResponse1 = "";
	If StrStartsWith(Lower(Items.WebPage.Document.URL), Lower(RedirectAddress)) Then
		ServerResponse1 = Items.WebPage.Document.URL;
	ElsIf StrStartsWith(WebPage, "{") And StrEndsWith(WebPage, "}") Then
		ServerResponse1 = WebPage;
	ElsIf Items.WebPage.Document.contentType = "application/json"
		And Items.WebPage.Document.body <> Undefined Then
		ServerResponse1 = Items.WebPage.Document.body.innerText;
	ElsIf Items.WebPage.Document.body <> Undefined 
		And StrFind(Items.WebPage.Document.body.innerText, RedirectAddress) Then
		StringParts1 = StrSplit(Items.WebPage.Document.body.innerText, " ", False);
		For Each RowPart In StringParts1 Do
			If StrStartsWith(RowPart, RedirectAddress) Then
				ServerResponse1 = RowPart;
				Break;
			EndIf;
		EndDo;
	Else
		If Items.Pages.CurrentPage = Items.Authorization Then
			AttachIdleHandler("CheckAuthenticationResult", 5, True);
		EndIf;
		Return;
	EndIf;
	
	OnReceiveMailServerResponse(ServerResponse1, KeyReceiptAddress);
	GotoNextPage();
#EndIf
	
EndProcedure

&AtServer
Procedure OnReceiveMailServerResponse(ParametersString1, KeyReceiptAddress)
	
	If StrStartsWith(ParametersString1, "{") Then
		Response = Common.JSONValue(ParametersString1);
	Else
		Response = ParametersFromStringURI(ParametersString1);
	EndIf;
	
	AuthorizationCode = Response["code"];
	ErrorCode = Response["error"];
	ErrorText = Response["error_description"];
	
	If ValueIsFilled(ErrorText) Then
		ErrorText = DecodeString(ErrorText, StringEncodingMethod.URLEncoding);
	EndIf;
	
	If ValueIsFilled(ErrorCode) Then
		ErrorsMessages = DescriptionErrorsMailServerAuthorization(ErrorCode, ErrorText);
		ValidationCompletedWithErrors = True;
	ElsIf QueryID <> Response["state"] Then
		ErrorsMessages = NStr("en = 'Cannot authorize on the mail server. Incorrect response ID.'");
		ValidationCompletedWithErrors = True;
	ElsIf Not GetAccessKeysToMailServer(AuthorizationCode, KeyReceiptAddress) Then
		ValidationCompletedWithErrors = True;
	EndIf;
	
	If ValidationCompletedWithErrors Then
		
		ErrorRegistrationTime = CurrentSessionDate();
		FillinExplanations();
		
		// StandardSubsystems.SupportRequests
		If Common.SubsystemExists("StandardSubsystems.SupportRequests") Then
			
			ModuleSupportRequestsInternal = Common.CommonModule(
				"SupportRequestsInternal");
			
			ModuleSupportRequestsInternal.ShowNeedHelpSection(Items);
			
		EndIf;
		// End StandardSubsystems.SupportRequests
		
	EndIf;
	
EndProcedure

&AtServer
Function GetAccessKeysToMailServer(AuthorizationCode, KeyReceiptAddress, ApplicationCaption = "")
	
	URIStructure = CommonClientServer.URIStructure(KeyReceiptAddress);
	ServerAddress = URIStructure.Host;
	ResourceAddress = "/" + URIStructure.PathAtServer;
	
	QueryOptions = New Structure;
	QueryOptions.Insert("client_id", AppID);
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	If ValueIsFilled(AuthorizationSettings["PermissionsToRequest"]) Then
		QueryOptions.Insert("scope", AuthorizationSettings["PermissionsToRequest"]);
	EndIf;
	
	QueryOptions.Insert("code", AuthorizationCode);
	QueryOptions.Insert("redirect_uri", RedirectAddress);
	QueryOptions.Insert("grant_type", "authorization_code");
	
	If AuthorizationSettings.UsePKCEAuthenticationKey Then
		QueryOptions.Insert("code_verifier", VerificationCode);
	EndIf;
	
	If ValueIsFilled(ApplicationPassword) Then
		QueryOptions.Insert("client_secret", ApplicationPassword);
	EndIf;
	
	If IsWebClient() Then
		QueryOptions.Insert("device_id", DeviceID);
		QueryOptions.Insert("device_name", ApplicationCaption);
	EndIf;
	
	RequestTime = CurrentSessionDate();
	QueryResult = EmailOperationsInternal.ExecuteQuery(ServerAddress, ResourceAddress, QueryOptions);
	
	Try
		AnswerParameters = Common.JSONValue(QueryResult.ServerResponse1);
	Except
		AnswerParameters = New Map;
	EndTry;
	
	AccessToken = AnswerParameters["access_token"];
	AccessTokenValidity = AnswerParameters["expires_in"];
	UpdateToken = AnswerParameters["refresh_token"];
	ErrorCode = AnswerParameters["error"];
	ErrorText = AnswerParameters["error_description"];
	
	If ValueIsFilled(ErrorCode) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot get access keys to the %1 email account due to:
			|%2'"), Email, ErrorText);
			
		TechnicalDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Server response:
			|%1'"), QueryResult.ServerResponse1);
			
		WriteLogEvent(EmailOperationsInternal.EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , ErrorText + Chars.LF + TechnicalDetails);
		ErrorsMessages = ErrorText;
		Return False;
	ElsIf Not QueryResult.QueryCompleted Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot get access keys to the %1 email account due to:
			|Request failed.'"), Email);
			
		TechnicalDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Server response:
			|%1'"), QueryResult.ServerResponse1);
			
		WriteLogEvent(EmailOperationsInternal.EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , ErrorText + Chars.LF + TechnicalDetails);
		ErrorsMessages = ErrorText;
		Return False;
	EndIf;
	
	If ValueIsFilled(AccessTokenValidity) Then
		AccessTokenValidity = RequestTime + AccessTokenValidity;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Function ParametersFromStringURI(URIString1)
	
	ParameterValues = New Map;
	URIStructure = CommonClientServer.URIStructure(URIString1);
	
	For Each RowPart In StrSplit(URIStructure.PathAtServer, "?&") Do
		ParameterFValue = StrSplit(RowPart, "=", True);
		ParameterName = ParameterFValue[0];
		If ParameterFValue.Count() > 1 Then
			ParameterValue = DecodeString(ParameterFValue[1], StringEncodingMethod.URLEncoding);
			ParameterValues.Insert(ParameterName, ParameterValue);
		EndIf;
	EndDo;
	
	Return ParameterValues;
	
EndFunction

&AtServerNoContext
Function DescriptionErrorsMailServerAuthorization(Val ErrorCode, Val ErrorText)
	
	Result = String(ErrorText) + Chars.LF + ErrorCode;
	Result = TrimAll(Result);
	
	Result = StringFunctionsClientServer.SubstituteParametersToString(NStr(
		"en = 'Authorization on the email server failed:
		|%1'"), Result);
	
	Return Result;
	
EndFunction

// Returns:
//   See Catalogs.EmailAccounts.ConnectionSettingsByEmailAddress
//
&AtServer
Function ConnectionSettingsByEmailAddress()
	
	SetPrivilegedMode(True);
	Return Catalogs.EmailAccounts.ConnectionSettingsByEmailAddress(Email, PasswordForReceivingEmails);
	
EndFunction

// Returns:
//   See Catalogs.InternetServicesAuthorizationSettings.SettingsAuthorizationInternetService
//
&AtServer
Function SettingsAuthorizationOnMailServer()
	
	Return ConnectionSettingsByEmailAddress().AuthorizationSettings;
	
EndFunction

&AtClientAtServerNoContext
Function IsWebClient()
	
#If WebClient Then
	Return True;
#EndIf
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return Common.IsWebClient();
#EndIf
	
	Return False;
	
EndFunction

&AtServer
Function GetAuthorizationParametersInWebClient(KeyReceiptAddress)
	
	URIStructure = CommonClientServer.URIStructure(KeyReceiptAddress);
	ServerAddress = URIStructure.Host;
	ResourceAddress = "/" + URIStructure.PathAtServer;
	
	QueryOptions = New Structure;
	QueryOptions.Insert("client_id", AppID);
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	If ValueIsFilled(AuthorizationSettings["PermissionsToRequest"]) Then
		QueryOptions.Insert("scope", AuthorizationSettings["PermissionsToRequest"]);
	EndIf;
	
	RequestTime = CurrentSessionDate();
	QueryResult = EmailOperationsInternal.ExecuteQuery(ServerAddress, ResourceAddress, QueryOptions);
	
	Try
		AnswerParameters = Common.JSONValue(QueryResult.ServerResponse1);
	Except
		AnswerParameters = New Map;
	EndTry;
	
	DeviceID = AnswerParameters["device_code"];
	DeviceIdValidityTime = AnswerParameters["expires_in"];
	QueryExecutionInterval = AnswerParameters["interval"];
	ConfirmationCode = AnswerParameters["user_code"];
	
	UserAuthorizationAddress = AnswerParameters["verification_url"];
	If Not ValueIsFilled(UserAuthorizationAddress) Then
		UserAuthorizationAddress = AnswerParameters["verification_uri"];
	EndIf;
	
	ErrorCode = AnswerParameters["error"];
	ErrorText = AnswerParameters["error_description"];
	ErrorText = DescriptionErrorsMailServerAuthorization(ErrorCode, ErrorText);
	
	If ValueIsFilled(ErrorCode) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot get access keys to the %1 email account due to:
			|%2'"), Email, ErrorText);
			
		TechnicalDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Server response:
			|%1'"), QueryResult.ServerResponse1);
			
		WriteLogEvent(EmailOperationsInternal.EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , ErrorText + Chars.LF + TechnicalDetails);
		ErrorsMessages = ErrorText;
		ValidationCompletedWithErrors = True;
		Return False;
	ElsIf Not QueryResult.QueryCompleted Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot get access keys to the %1 email account due to:
			|Request failed.'"), Email);
			
		TechnicalDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Server response:
			|%1'"), QueryResult.ServerResponse1);
			
		WriteLogEvent(EmailOperationsInternal.EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , ErrorText + Chars.LF + TechnicalDetails);
		ErrorsMessages = ErrorText;
		ValidationCompletedWithErrors = True;
		Return False;
	EndIf;
	
	If ValueIsFilled(DeviceIdValidityTime) Then
		DeviceIdValidityTime = RequestTime + DeviceIdValidityTime;
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure GetAccessKeysWebClient()
	
	If GetDeviceAccessKey() = Undefined Then
		AttachIdleHandler("GetAccessKeysWebClient", QueryExecutionInterval, True);
		Return;
	EndIf;
	
	GotoNextPage();
	
EndProcedure

&AtServer
Function GetDeviceAccessKey()
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	URIStructure = CommonClientServer.URIStructure(AuthorizationSettings.KeyReceiptAddress);
	ServerAddress = URIStructure.Host;
	ResourceAddress = "/" + URIStructure.PathAtServer;
	
	QueryOptions = New Structure;
	QueryOptions.Insert("client_id", AppID);
	QueryOptions.Insert("client_secret", ApplicationPassword);
	QueryOptions.Insert("device_code", DeviceID);
	QueryOptions.Insert("grant_type", "urn:ietf:params:oauth:grant-type:device_code");
	
	RequestTime = CurrentSessionDate();
	QueryResult = EmailOperationsInternal.ExecuteQuery(ServerAddress, ResourceAddress, QueryOptions);
	
	Try
		AnswerParameters = Common.JSONValue(QueryResult.ServerResponse1);
	Except
		AnswerParameters = New Map;
	EndTry;
	
	AccessToken = AnswerParameters["access_token"];
	AccessTokenValidity = AnswerParameters["expires_in"];
	UpdateToken = AnswerParameters["refresh_token"];
	ErrorCode = AnswerParameters["error"];
	ErrorText = AnswerParameters["error_description"];
	
	If ErrorCode = "authorization_pending" Then
		Return Undefined;
	EndIf;
	
	If ValueIsFilled(ErrorCode) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot get access keys to the %1 email account due to:
			|%2'"), Email, ErrorText);
			
		TechnicalDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Server response:
			|%1'"), QueryResult.ServerResponse1);
			
		WriteLogEvent(EmailOperationsInternal.EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , ErrorText + Chars.LF + TechnicalDetails);
		ErrorsMessages = ErrorText;
		Return False;
	ElsIf Not QueryResult.QueryCompleted Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot get access keys to the %1 email account due to:
			|Request failed.'"), Email);
			
		TechnicalDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Server response:
			|%1'"), QueryResult.ServerResponse1);
			
		WriteLogEvent(EmailOperationsInternal.EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , ErrorText + Chars.LF + TechnicalDetails);
		ErrorsMessages = ErrorText;
		Return False;
	EndIf;
	
	If ValueIsFilled(AccessTokenValidity) Then
		AccessTokenValidity = RequestTime + AccessTokenValidity;
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Function AvailableAuthorizationByCode()
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	Return ValueIsFilled(AuthorizationSettings)
		And (ValueIsFilled(AuthorizationSettings.DeviceRegistrationAddress) 
		Or ValueIsFilled(AuthorizationSettings.RedirectionAddressWebClient));
	
EndFunction

&AtClient
Procedure AdjustCurrentPageElementsOnOpening()
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	If OnlyAuthorization Then
		
		If Not ValueIsFilled(AuthorizationSettings) Then
			Close(NStr("en = 'Cannot find authorization settings for the specified email address.
				|Use username and password authorization.'"));
			Return;
		EndIf;
		
		If Items.Pages.CurrentPage = Items.Authorization Then
			LoginAtMailServer();
		EndIf;
		
	EndIf;
	
	SetCurrentPageItems();
	
EndProcedure

&AtServer
Procedure FillinExplanations()
	
	ExplanationOnError = ExplanationOnError();
	
	PossibleReasons = EmailOperationsInternal.FormattedList(ExplanationOnError.PossibleReasons);
	MethodsToFixError = EmailOperationsInternal.FormattedList(ExplanationOnError.MethodsToFixError);
	
	Items.DecorationRecommendations.Title = String(MethodsToFixError);
	Items.DecorationPossibleReasons.Title = String(PossibleReasons);
	
	FillInBriefDescriptionOfError();
	
EndProcedure

&AtServer
Function ExplanationOnError()
	
	ExplanationParameters = EmailOperationsInternal.ExplanationParameters();
	ExplanationParameters.ErrorText = ErrorsMessages;
	ExplanationParameters.Context = SetupMethod;
	ExplanationParameters.ServerNames = EmailOperationsInternal.ServerNamesForClarification(IncomingMailServer, OutgoingMailServer);
	
	Return EmailOperationsInternal.ExplanationOnError(ExplanationParameters);
	
EndFunction

&AtServer
Procedure FillInBriefDescriptionOfError()
	
	LengthLimitation = 150;
	
	If StrLen(ErrorsMessages) = LengthLimitation Then
		ErrorDescriptionBeginning = StrFind(ErrorsMessages, Chars.LF);
		BriefErrorDetails = Left(ErrorsMessages, ErrorDescriptionBeginning);
	Else
		BriefErrorDetails = ErrorsMessages;
	EndIf;
	
	If Not ValueIsFilled(BriefErrorDetails) Then
		BriefErrorDetails = NStr("en = 'Authorization in the email server failed.'");
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTitleOfAssistant()
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 setting'"), Email);
	
EndProcedure

&AtServerNoContext
Function AutomaticSetting()
	
	Return EmailOperationsInternal.ContextForClarification().AutomaticSetting;
	
EndFunction

&AtServerNoContext
Function ManualSetting()
	
	Return EmailOperationsInternal.ContextForClarification().ManualSetting;
	
EndFunction

&AtServer
Procedure ConvertSettingsFromPunycode()
	
	IncomingMailServer = EmailOperationsInternal.PunycodeIntoString(IncomingMailServer);
	OutgoingMailServer = EmailOperationsInternal.PunycodeIntoString(OutgoingMailServer);
	UsernameToSendMail = EmailOperationsInternal.PunycodeIntoString(UsernameToSendMail);
	UsernameForReceivingEmails = EmailOperationsInternal.PunycodeIntoString(UsernameForReceivingEmails);
	
EndProcedure

&AtClient
Procedure AfterManuallySettingUpAccount(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, Result);
	FillInTitleOfAssistant();
	
	PasswordForReceivingEmails = Result.Password;
	PasswordForSendingEmails = PasswordForReceivingEmails;
	
	CheckMissed = False;
	SetupMethod = ManualSetting();
	
	Items.Pages.CurrentPage = Items.EnteringAccountPassword;
	GotoNextPage();
	
EndProcedure

&AtClient
Procedure CheckAvailabilityOfOpenAuthorizationService()
	
	OpenAuthorizationOfMailServiceHasBeenPublished = OpenAuthorizationOfMailServiceHasBeenPublished();
	
EndProcedure

&AtServerNoContext
Function OpenAuthorizationOfMailServiceHasBeenPublished()
	
	Return EmailOperationsInternal.OpenAuthorizationOfMailServiceHasBeenPublished();
	
EndFunction

&AtServer
Function AccountParameters1()
	
	AccountParameters1 = Catalogs.EmailAccounts.AccountParameters1();
	FillPropertyValues(AccountParameters1, ThisObject);
	
	AccountParameters1.Description = AccountName;
	AccountParameters1.Timeout =  ServerTimeout;
	AccountParameters1.UserName = EmailSenderName;
	AccountParameters1.KeepMessageCopiesAtServer = KeepEmailCopiesOnServer;
	
	StoragePeriod = ?(KeepEmailCopiesOnServer And DeleteMailFromServer And Protocol = "POP", KeepMailAtServerPeriod, 0);
	AccountParameters1.KeepMailAtServerPeriod = StoragePeriod;
	
	AccountParameters1.User = UsernameForReceivingEmails;
	AccountParameters1.SMTPUser = UsernameToSendMail;
	AccountParameters1.ProtocolForIncomingMail = Protocol;
	AccountParameters1.AuthorizationRequiredOnSendEmails = ValueIsFilled(UsernameToSendMail);
	
	If UserAccountKind = "Personal1" Then
		AccountParameters1.AccountOwner = Users.CurrentUser();
	Else
		AccountParameters1.AccountOwner = Catalogs.Users.EmptyRef();
	EndIf;
	
	If AuthenticationOption = "OAuth" Then
		AccountParameters1.EmailServiceAuthorization = True;
		AccountParameters1.EmailServiceName = SettingsAuthorizationOnMailServer.InternetServiceName;
	Else
		AccountParameters1.Password = PasswordForReceivingEmails;
	EndIf;
	
	AccountParameters1.AuthenticationOption = AuthenticationOption;
	AccountParameters1.CreatingAccountThroughAssistant = True;
	
	Return AccountParameters1;
	
EndFunction

#EndRegion
