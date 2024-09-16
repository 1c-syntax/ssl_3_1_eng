///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Procedure CheckTheLocationOfTheComponent(Id, Location) Export
	
	If StrStartsWith(Location, "e1cib/data/Catalog.AddIns.AddInStorage") Then
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.SaaSOperations.AddInsSaaS") Then
		ModuleAddInsSaaSInternalClient = CommonClient.CommonModule("AddInsSaaSInternalClient");
		If ModuleAddInsSaaSInternalClient.IsComponentFromStorage(Location) Then
			Return;
		EndIf;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Cannot attach the %1 add-in in the client application
		           |due to:
		           |Add-in
		           |%2 location is incorrect';"),
		Id, Location);

EndProcedure

// Parameters:
//  Notification - NotifyDescription
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Procedure CheckAddInAvailability(Notification, Context) Export
	
	ThePathToTheLayoutToSearchForTheLatestVersion = Undefined;
	SearchForAComponentOfTheLatestVersion = ValueIsFilled(Context.OriginalLocation) And Not Context.ASearchForANewVersionHasBeenPerformed; 
	If SearchForAComponentOfTheLatestVersion Then
		ThePathToTheLayoutToSearchForTheLatestVersion = Context.OriginalLocation;
	EndIf;
	
	Information = AddInsInternalServerCall.SavedAddInInformation(
		Context.Id, Context.Version, ThePathToTheLayoutToSearchForTheLatestVersion);
	
	Context.Location = Information.Location;
	
	// 
	// 
	// 
	// 
	// 
	
	Result = AddInAvailabilityResult();
	Result.TheComponentOfTheLatestVersion = Information.TheLatestVersionOfComponentsFromTheLayout;
	Result.Location = Information.Location;
	
	If Information.State = "DisabledByAdministrator" Then 
		
		Result.ErrorDescription = NStr("en = 'Disabled by administrator.';");
		ExecuteNotifyProcessing(Notification, Result);
		
	ElsIf Information.State = "NotFound1" Then 
		
		If Information.CanImportFromPortal 
			And Context.SuggestToImport Then 
			
			SearchContext = New Structure;
			SearchContext.Insert("Notification", Notification);
			SearchContext.Insert("Context", Context);
			
			NotificationForms = New NotifyDescription(
				"CheckAddInAvailabilityAfterSearchingAddInOnPortal",
				ThisObject, 
				SearchContext);
				
			Notification = New NotifyDescription("AddInSearchOnPortalOnGenerateResult", ThisObject, NotificationForms);
			AddInsClientLocalization.ComponentSearchOnPortal(Notification, Context);
			
		Else 
			Result.ErrorDescription = NStr("en = 'The add-in is missing from the list of allowed add-ins.';");
			ExecuteNotifyProcessing(Notification, Result);
		EndIf;
		
	Else
		
		Result.Insert("Version", Information.Attributes.Version);
		ShouldAttachAddInFromTemplate = False;
		If SearchForAComponentOfTheLatestVersion Then
			ReplaceWithCurrentComponentFromCatalog(Result, Context.Id, Information.Location, ShouldAttachAddInFromTemplate);
		EndIf;
		
		If ShouldAttachAddInFromTemplate
			Or Not Information.IsTargetPlatformsFilled
			Or CurrentClientIsSupportedByAddIn(Information.Attributes.TargetPlatforms) Then
			
			Result.Available = True;
			ExecuteNotifyProcessing(Notification, Result);
			
		Else 
			
			NotificationParameters = New Structure;
			NotificationParameters.Insert("Notification", Notification);
			NotificationParameters.Insert("Result", Result);
			
			NotificationForms = New NotifyDescription(
				"CheckAddInAvailabilityAfterDisplayingAvailableClientTypes",
				ThisObject,
				NotificationParameters);
				
			If Not Context.SuggestInstall Then
				ExecuteNotifyProcessing(NotificationForms, False);
				Return;
			EndIf;
			
			FormParameters = New Structure;
			FormParameters.Insert("ExplanationText", Context.ExplanationText);
			FormParameters.Insert("SupportedClients", Information.Attributes.TargetPlatforms);
			
			OpenForm("CommonForm.CannotInstallAddIn",
				FormParameters,,,,, NotificationForms);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Async Function AddInAvailabilityCheckResult(Context) Export
	
	ThePathToTheLayoutToSearchForTheLatestVersion = Undefined;
	SearchForAComponentOfTheLatestVersion = ValueIsFilled(Context.OriginalLocation) And Not Context.ASearchForANewVersionHasBeenPerformed; 
	If SearchForAComponentOfTheLatestVersion Then
		ThePathToTheLayoutToSearchForTheLatestVersion = Context.OriginalLocation;
	EndIf;
	
	Information = AddInsInternalServerCall.SavedAddInInformation(
		Context.Id, Context.Version, ThePathToTheLayoutToSearchForTheLatestVersion);
	
	Context.Location = Information.Location;
	
	// 
	// 
	// 
	// 
	// 
	
	Result = AddInAvailabilityResult();
	Result.TheComponentOfTheLatestVersion = Information.TheLatestVersionOfComponentsFromTheLayout;
	Result.Location = Information.Location;
	
	If Information.State = "DisabledByAdministrator" Then 
		
		Result.ErrorDescription = NStr("en = 'Disabled by administrator.';");
		Return Result;
		
	ElsIf Information.State = "NotFound1" Then 
		
		Result.ErrorDescription = NStr("en = 'The add-in is missing from the list of allowed add-ins.';");
		
		Return Result;
		
	Else
		
		Result.Insert("Version", Information.Attributes.Version);
			
		ShouldAttachAddInFromTemplate = False;
		If SearchForAComponentOfTheLatestVersion Then
			ReplaceWithCurrentComponentFromCatalog(Result, Context.Id, Information.Location, ShouldAttachAddInFromTemplate);
		EndIf;
		
		If ShouldAttachAddInFromTemplate
			Or Not Information.IsTargetPlatformsFilled
			Or CurrentClientIsSupportedByAddIn(Information.Attributes.TargetPlatforms) Then
			
			Result.Available = True;
			Return Result;
		
		Else
			
			ErrorDescription = StringFunctionsClient.FormattedString(
				NStr("en = 'Client application <b>%1</b>
					 |does not support the add-in.
					 |Contact the add-in developer.';"), PresentationOfCurrentClient());

			If Not Context.SuggestInstall Then
				Result.Available = False;
				Result.ErrorDescription = ErrorDescription;
			Else
				QuestionButtons = New ValueList;
				QuestionButtons.Add("Close", NStr("en = 'Close';"));
				QuestionButtons.Add("ResumeInstallationAttempt", NStr("en = 'Install anyway';"));

				QuestionTitle = Context.ExplanationText;
				If IsBlankString(QuestionTitle) Then
					QuestionTitle = NStr("en = 'Cannot install the add-in.';");
				EndIf;

				Response = Await DoQueryBoxAsync(ErrorDescription, QuestionButtons,, "Close", QuestionTitle);

				If Response = "ResumeInstallationAttempt" Then
					Result.Available = True;
				Else
					Result.Available = False;
					Result.ErrorDescription = ErrorDescription;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// See StandardSubsystemsClient.OnReceiptServerNotification
Procedure OnReceiptServerNotification(NameOfAlert, Result) Export
	
	If NameOfAlert <> "StandardSubsystems.AddIns" Then
		Return;
	EndIf;
	
	ApplicationParameters.Insert("StandardSubsystems.AddIns.SymbolicNames",
		New FixedMap(New Map));
	
	ApplicationParameters.Insert("StandardSubsystems.AddIns.Objects",
		New FixedMap(New Map));
	
EndProcedure

// 
// 
// Parameters:
//  Location - String - 
// 
// Returns:
//  String - 
//
Function TemplateAddInCompatibilityError(Location) Export
	
	AddInInfo = AddInsInternalServerCall.TemplateAddInInfo(Location);
		 
	If AddInInfo <> Undefined 
		And Not CurrentClientIsSupportedByAddIn(AddInInfo.Attributes.TargetPlatforms) Then
			Return AddInCompatibilityErrorDetails();
	EndIf;
	
	Return "";
	
EndFunction

// 
// 
// Parameters:
//  Notification - NotifyDescription - 
//  AddInAttachmentContext - See CommonInternalClient.AddInAttachmentContext
//
Procedure CheckTemplateAddInForCompatibility(Notification, AddInAttachmentContext) Export
	
	AddInInfo = AddInsInternalServerCall.TemplateAddInInfo(
		AddInAttachmentContext.Location);
		
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("ErrorDescription", "");
		 
	If AddInInfo <> Undefined 
		And Not CurrentClientIsSupportedByAddIn(AddInInfo.Attributes.TargetPlatforms) Then
		
		Context.ErrorDescription = AddInCompatibilityErrorDetails();
		
		If AddInAttachmentContext.SuggestInstall Then
			NotifyDescription = New NotifyDescription("AfterCompatibilityInfoDisplayed", ThisObject, Context);
			
			FormParameters = New Structure;
			FormParameters.Insert("ExplanationText", AddInAttachmentContext.ExplanationText);
			FormParameters.Insert("SupportedClients", AddInInfo.Attributes.TargetPlatforms);
			FormParameters.Insert("AfterConnectionErrorOccurred", True);
			
			OpenForm("CommonForm.CannotInstallAddIn",
				FormParameters,,,,, NotifyDescription);
			Return;
		EndIf;
	EndIf;
	
	AfterCompatibilityInfoDisplayed(Undefined, Context);
	
EndProcedure

#EndRegion

#Region Private

#Region CheckAddInAvailability

Procedure AfterCompatibilityInfoDisplayed(Result, Context) Export
	
	ExecuteNotifyProcessing(Context.Notification, Context.ErrorDescription);
	
EndProcedure

Function AddInCompatibilityErrorDetails()
	Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Client application %1 does not support the add-in. Contact the add-in developer.';"),
			CommonInternalClient.ApplicationKind());
EndFunction

Procedure CheckAddInAvailabilityAfterSearchingAddInOnPortal(Imported1, SearchContext) Export
	
	Notification = SearchContext.Notification;
	Context   = SearchContext.Context;
	
	If Imported1 Then
		Context.SuggestToImport = False;
		CheckAddInAvailability(Notification, Context);
	Else 
		ExecuteNotifyProcessing(Notification, AddInAvailabilityResult());
	EndIf;
	
EndProcedure

Procedure CheckAddInAvailabilityAfterDisplayingAvailableClientTypes(Result, Context) Export
	
	AddInAvailabilityResult = Context.Result;
	AddInAvailabilityResult.Available = Result = True;
	ExecuteNotifyProcessing(Context.Notification, AddInAvailabilityResult);
	
EndProcedure

// Returns:
//  Structure:
//   * Available - Boolean
//   * Version - String
//   * TheComponentOfTheLatestVersion - See StandardSubsystemsServer.TheComponentOfTheLatestVersion
//   * ErrorDescription - String
//   * Location - String
//
Function AddInAvailabilityResult() Export
	
	Result = New Structure;
	Result.Insert("Available", False);
	Result.Insert("Version", "");
	Result.Insert("TheComponentOfTheLatestVersion", Undefined);
	Result.Insert("ErrorDescription", "");
	Result.Insert("Location", "");
	
	Return Result;
	
EndFunction

Procedure ReplaceWithCurrentComponentFromCatalog(Result, Id, Location, ShouldAttachAddInFromTemplate)
	
	If StringFunctionsClientServer.OnlyNumbersInString(StrReplace(Result.Version, ".", "")) Then
		VersionParts = StrSplit(Result.Version, ".");
		If VersionParts.Count() = 4 And CommonClientServer.CompareVersions(Result.Version,
			Result.TheComponentOfTheLatestVersion.Version) <= 0 Then
				ShouldAttachAddInFromTemplate = True;
			Return;
		EndIf;
	EndIf;
		
	// 
	Result.TheComponentOfTheLatestVersion = New Structure("Id, Version, Location", Id,
		Result.Version, Location);
		
EndProcedure

// 
// 
// Parameters:
//  Attributes - 
// 
// Returns:
//  Boolean - 
//
Function CurrentClientIsSupportedByAddIn(Attributes)
	
	SystemInfo = New SystemInfo;
	Browser = Undefined;
#If WebClient Then
	String = SystemInfo.UserAgentInformation;
	If StrFind(String, "YaBrowser/") > 0 Then
		Browser = "YandexBrowser";
	ElsIf StrFind(String, "Chrome/") > 0 Then
		Browser = "Chrome";
	ElsIf StrFind(String, "MSIE") > 0 Then
		Browser = "MSIE";
	ElsIf StrFind(String, "Safari/") > 0 Then
		Browser = "Safari";
	ElsIf StrFind(String, "Firefox/") > 0 Then
		Browser = "Firefox";
	EndIf;
#EndIf

	NameOfThePlatformType = CommonClientServer.NameOfThePlatformType(SystemInfo.PlatformType);
	
	If NameOfThePlatformType = "Linux_x86" Then
		
		If Browser = Undefined Then
			Return Attributes.Linux_x86;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Linux_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Linux_x86_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Linux_x86_YandexBrowser;
		EndIf;
	
	ElsIf NameOfThePlatformType = "Linux_x86_64" Then
		
		If Browser = Undefined Then
			Return Attributes.Linux_x86_64;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Linux_x86_64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Linux_x86_64_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Linux_x86_64_YandexBrowser;
		EndIf;
	
	ElsIf NameOfThePlatformType = "MacOS_x86_64" Then
		
		If Browser = Undefined Then
			Return Attributes.MacOS_x86_64;
		EndIf;
		
		If Browser = "Safari" Then
			Return Attributes.MacOS_x86_64_Safari;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.MacOS_x86_64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.MacOS_x86_64_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.MacOS_x86_64_YandexBrowser;
		EndIf;
	
	ElsIf NameOfThePlatformType = "Windows_x86" Then
		
		If Browser = Undefined Then
			Return Attributes.Windows_x86;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Windows_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Windows_x86_Chrome;
		EndIf;
		
		If Browser = "MSIE" Then
			Return Attributes.Windows_x86_MSIE;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Windows_x86_YandexBrowser;
		EndIf;
		
	ElsIf NameOfThePlatformType = "Windows_x86_64" Then
		
		If Browser = Undefined Then
			Return Attributes.Windows_x86_64;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Windows_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Windows_x86_Chrome;
		EndIf;
		
		If Browser = "MSIE" Then
			Return Attributes.Windows_x86_64_MSIE;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Windows_x86_64_YandexBrowser;
		EndIf;
	
	ElsIf NameOfThePlatformType = "MacOS_x86" Then
		// 
	
		If Browser = "Firefox" Then
			Return Attributes.MacOS_x86_64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.MacOS_x86_64_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.MacOS_x86_64_YandexBrowser;
		EndIf;
		
	ElsIf NameOfThePlatformType = "Linux_E2K" Then
		
		If Browser = Undefined Then
			Return Attributes.Linux_E2K;
		EndIf;
	
		If Browser = "Firefox" Then
			Return Attributes.Linux_E2K_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Linux_E2K_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Linux_E2K_YandexBrowser;
		EndIf;
		
	ElsIf NameOfThePlatformType = "Linux_ARM64" Then
	
		If Browser = Undefined Then
			Return Attributes.Linux_ARM64;
		EndIf;
	
		If Browser = "Firefox" Then
			Return Attributes.Linux_ARM64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Linux_ARM64_Chrome;
		EndIf;
		
		If Browser = "YandexBrowser" Then
			Return Attributes.Linux_ARM64_YandexBrowser;
		EndIf;
		
	ElsIf NameOfThePlatformType = "iOS_ARM" Then
	
		Return Attributes.iOS_ARM;
	
	ElsIf NameOfThePlatformType = "iOS_ARM64" Then
	
		Return Attributes.iOS_ARM64;
	
	ElsIf NameOfThePlatformType = "Android_ARM" Then
	
		Return Attributes.Android_ARM;
	
	ElsIf NameOfThePlatformType = "Android_ARM_64" Then
	
		Return Attributes.Android_ARM64;
		
	ElsIf NameOfThePlatformType = "Android_x86" Then
	
		Return Attributes.Android_x86;
		
	ElsIf NameOfThePlatformType = "Android_x86_64" Then
	
		Return Attributes.Android_x86_64;
		
	ElsIf NameOfThePlatformType = "WinRT_ARM" Then
	
		Return Attributes.WindowsRT_ARM;
		
	ElsIf NameOfThePlatformType = "WinRT_x86" Then
	
		Return Attributes.WindowsRT_x86;
		
	ElsIf NameOfThePlatformType = "WinRT_x86_64" Then
	
		Return Attributes.WindowsRT_x86_64;
	
	EndIf;
	
	Return False;
	
EndFunction

Function TextCannotInstallAddIn(Val ExplanationText) Export

	If IsBlankString(ExplanationText) Then
		ExplanationText = NStr("en = 'Cannot install the add-in.';");
	EndIf;

	Return StringFunctionsClient.FormattedString(NStr("en = '%1
			  |
			  |The add-in is not supported 
			  |in the client application <b>%2</b>.
			  |Use <a href = about:blank>a supported client application</a> or contact the add-in developer.';"),
		ExplanationText, PresentationOfCurrentClient());
		
EndFunction

Function PresentationOfCurrentClient() 
	
	SystemInfo = New SystemInfo;
	
#If WebClient Then
	String = SystemInfo.UserAgentInformation;
	
	If StrFind(String, "YaBrowser/") > 0 Then
		Browser = NStr("en = 'Yandex Browser';");
	ElsIf StrFind(String, "Chrome/") > 0 Then
		Browser = NStr("en = 'Chrome';");
	ElsIf StrFind(String, "MSIE") > 0 Then
		Browser = NStr("en = 'Internet Explorer';");
	ElsIf StrFind(String, "Safari/") > 0 Then
		Browser = NStr("en = 'Safari';");
	ElsIf StrFind(String, "Firefox/") > 0 Then
		Browser = NStr("en = 'Firefox';");
	EndIf;
	
	Package = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'web client %1';"), Browser);
#ElsIf MobileAppClient Then
	Package = NStr("en = 'mobile application';");
#ElsIf MobileClient Then
	Package = NStr("en = 'mobile client';");
#ElsIf ThinClient Then
	Package = NStr("en = 'thin client';");
#ElsIf ThickClientOrdinaryApplication Then
	Package = NStr("en = 'thick client (standard application)';");
#ElsIf ThickClientManagedApplication Then
	Package = NStr("en = 'thick client';");
#EndIf

	NameOfThePlatformType = CommonClientServer.NameOfThePlatformType(SystemInfo.PlatformType);
	If NameOfThePlatformType = "Windows_x86" Then
		Platform = NStr("en = 'Windows x86';");
	ElsIf NameOfThePlatformType = "Windows_x86_64" Then
		Platform = NStr("en = 'Windows x86-64';");
	ElsIf NameOfThePlatformType = "Linux_x86" Then
		Platform = NStr("en = 'Linux x86';");
	ElsIf NameOfThePlatformType = "Linux_x86_64" Then
		Platform = NStr("en = 'Linux x86-64';");
	ElsIf NameOfThePlatformType = "MacOS_x86" Then
		Platform = NStr("en = 'macOS x86';");
	ElsIf NameOfThePlatformType = "MacOS_x86_64" Then
		Platform = NStr("en = 'macOS x86-64';");
	ElsIf NameOfThePlatformType = "Linux_ARM64" Then
		Platform = NStr("en = 'Linux ARM64';");
	ElsIf NameOfThePlatformType = "Linux_E2K" Then
		Platform = NStr("en = 'Linux E2K';");
	ElsIf NameOfThePlatformType = "Android_ARM" Then
		Platform = NStr("en = 'Android ARM';");
	ElsIf NameOfThePlatformType = "Android_ARM_64" Then
		Platform = NStr("en = 'Android_ARM64';");
	ElsIf NameOfThePlatformType = "Android_x86" Then
		Platform = NStr("en = 'Android x86';");
	ElsIf NameOfThePlatformType = "Android_x86_64" Then
		Platform = NStr("en = 'Android x86-64';");
	ElsIf NameOfThePlatformType = "iOS_ARM" Then
		Platform = NStr("en = 'iOS ARM';");
	ElsIf NameOfThePlatformType = "iOS_ARM_64" Then
		Platform = NStr("en = 'iOS ARM64';");
	ElsIf NameOfThePlatformType = "WinRT_ARM" Then
		Platform = NStr("en = 'WinRT ARM';");
	ElsIf NameOfThePlatformType = "WinRT_x86" Then
		Platform = NStr("en = 'WinRT x86';");
	ElsIf NameOfThePlatformType = "WinRT_x86_64" Then
		Platform = NStr("en = 'WinRT x86-64';");
	EndIf;
	
	// 
	// 
	// 
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 %2';"), Package, Platform);
	
EndFunction

#EndRegion

#Region AttachAddInSSL

// Parameters:
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Async Function AttachAddInSSLAsync(Context) Export 
	
	Result = Await AddInAvailabilityCheckResult(Context);
	
	If Result.Available Then 
		Return Await CommonInternalClient.AttachAddInSSLAsync(Context);
	Else
		If Not IsBlankString(Result.ErrorDescription) Then 
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot attach the ""%1"" add-in
				           |on the client from the add-in storage.
				           |Reason:
				           |%2';"),
				Context.Id,
				Result.ErrorDescription);
		EndIf;
		
		Return CommonInternalClient.AddInAttachmentError(ErrorText);
		
	EndIf;
	
EndFunction

Procedure AttachAddInSSL(Context) Export 
	
	Notification = New NotifyDescription(
		"AttachAddInAfterAvailabilityCheck", 
		ThisObject, 
		Context);
	
	CheckAddInAvailability(Notification, Context);
	
EndProcedure

// Parameters:
//  Result - Structure - :
//    * Attached - Boolean -  the sign connection;
//    * Attachable_Module - AddInObject -  an instance of an external component object.
//    * ErrorDescription - String -  brief description of the error. When the user cancels an empty string
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Procedure AttachAddInAfterAvailabilityCheck(Result, Context) Export
	
	If Result.Available Then 
		CommonInternalClient.AttachAddInSSL(Context);
	Else
		If Not IsBlankString(Result.ErrorDescription) Then 
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot attach the ""%1"" add-in
				           |on the client from the add-in storage.
				           |Reason:
				           |%2';"),
				Context.Id,
				Result.ErrorDescription);
		EndIf;
		
		CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
	EndIf;
	
EndProcedure

#EndRegion

#Region AttachAddInFromWindowsRegistry

// Returns:
//  Structure:
//   * Notification - NotifyDescription
//   * Id - String
//   * ObjectCreationID - String
//
Function ConnectionContextComponentsFromTheWindowsRegistry() Export
	
	Context = New Structure;
	Context.Insert("Notification", Undefined);
	Context.Insert("Id", "");
	Context.Insert("ObjectCreationID", "");
	Return Context;
		
EndFunction

// 
// 
// Parameters:
//  Context - See ConnectionContextComponentsFromTheWindowsRegistry.
//
Async Function AttachAddInFromWindowsRegistryAsync(Context) Export
	
	If AttachAddInFromWindowsRegistryAttachmentAvailable() Then
		
		Try
			
			Attached = Await AttachAddInAsync("AddIn." + Context.Id);
			
		Except
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot attach the ""%1"" add-in on the client
					 |from Windows registry.
					 |Reason:
					 |%2';"), Context.Id, ErrorProcessing.BriefErrorDescription(ErrorInfo()));

			Return CommonInternalClient.AddInAttachmentError(ErrorText);
		EndTry;
		
		If Attached Then

			ObjectCreationID = Context.ObjectCreationID;

			If ObjectCreationID = Undefined Then
				ObjectCreationID = Context.Id;
			EndIf;

			Try
				Attachable_Module = New ("AddIn." + ObjectCreationID);
				If Attachable_Module = Undefined Then
					Raise NStr("en = 'The New operator returned Undefined.';");
				EndIf;
			Except
				Attachable_Module = Undefined;
				ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			EndTry;

			If Attachable_Module = Undefined Then

				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot create object of the ""%1"" add-in attached on the client
					 |from Windows registry.
					 |Reason:
					 |%2';"), Context.Id, ErrorText);

				Return CommonInternalClient.AddInAttachmentError(ErrorText);

			Else
				
				Result = CommonInternalClient.AddInAttachmentResult();
				Result.Attached = True;
				Result.Attachable_Module = Attachable_Module;
				Return Result;
				
			EndIf;

		Else

			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t attach add-in ""%1"" on the client
				 |from Windows registry.
				 |Reason:
				 |Method ""%2"" returned ""%3"".';"), Context.Id, "AttachAddInAsync", "False");

			Return CommonInternalClient.AddInAttachmentError(ErrorText);

		EndIf;
		
	Else 
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot attach the ""%1"" add-in
			           |on the client from Windows registry.
			           |Reason:
			           |Attaching add-ins from Windows is allowed only in the thin and thick clients.';"),
			Context.Id);
		
		Return CommonInternalClient.AddInAttachmentError(ErrorText);
		
	EndIf;
	
EndFunction

//  See AddInsClient.AttachAddInFromWindowsRegistry.
// 
// Parameters:
//  Context - See ConnectionContextComponentsFromTheWindowsRegistry.
//
Procedure AttachAddInFromWindowsRegistry(Context) Export
	
	If AttachAddInFromWindowsRegistryAttachmentAvailable() Then
		
		Notification = New NotifyDescription(
		"AttachAddInFromWindowsRegistryAfterAttachmentAttempt", ThisObject, Context,
		"AttachAddInFromWIndowsRegisterOnProcessError", ThisObject);
		
		BeginAttachingAddIn(Notification, "AddIn." + Context.Id);
		
	Else 
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot attach the ""%1"" add-in
			           |on the client from Windows registry.
			           |Reason:
			           |Attaching add-ins from Windows is allowed only in the thin and thick clients.';"),
		Context.Id);
		
		CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
		
	EndIf;
	
EndProcedure

// Continue with the connect component of the Windows Registry.
//
// Parameters:
//  Attached - Boolean
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Procedure AttachAddInFromWindowsRegistryAfterAttachmentAttempt(Attached, Context) Export
	
	If Attached Then 
		
		ObjectCreationID = Context.ObjectCreationID;
			
		If ObjectCreationID = Undefined Then 
			ObjectCreationID = Context.Id;
		EndIf;
		
		Try
			Attachable_Module = New("AddIn." + ObjectCreationID);
			If Attachable_Module = Undefined Then 
				Raise NStr("en = 'The New operator returned Undefined';");
			EndIf;
		Except
			Attachable_Module = Undefined;
			ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		
		If Attachable_Module = Undefined Then 
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot create object of the ""%1"" add-in attached on the client
				           |from Windows registry.
				           |Reason:
				           |%2';"),
				Context.Id,
				ErrorText);
				
			CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
			
		Else 
			CommonInternalClient.AttachAddInSSLNotifyOnAttachment(Attachable_Module, Context);
		EndIf;
		
	Else 
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t attach add-in ""%1"" on the client
			           |from Windows registry.
			           |Reason:
			           |Method ""%2"" returned ""%3"".';"),
			Context.Id, "BeginAttachingAddIn", "False");
			
		CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
		
	EndIf;
	
EndProcedure

// Continue with the connect component of the Windows Registry.
//
// Parameters:
//  ErrorInfo - ErrorInfo
//  StandardProcessing - Boolean
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Procedure AttachAddInFromWIndowsRegisterOnProcessError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Cannot attach the ""%1"" add-in on the client
		           |from Windows registry.
		           |Reason:
		           |%2';"),
		Context.Id,
		ErrorProcessing.BriefErrorDescription(ErrorInfo));
		
	CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
	
EndProcedure

// Continue with the connect component of the Windows Registry.
Function AttachAddInFromWindowsRegistryAttachmentAvailable()
	
#If WebClient Then
	Return False;
#Else
	Return CommonClient.IsWindowsClient();
#EndIf
	
EndFunction

#EndRegion

#Region InstallAddInSSL

// Parameters:
//  Context - See CommonInternalClient.AddInAttachmentContext
//
Async Function InstallAddInSSLAsync(Context) Export
	
	CheckResult = Await AddInAvailabilityCheckResult(Context);
	
	If CheckResult.Available Then 
		Return Await CommonInternalClient.InstallAddInSSLAsync(Context);
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot attach the ""%1"" add-in
			           |on the client from the add-in storage.
			           |Reason:
			           |%2';"),
			Context.Id,
			CheckResult.ErrorDescription);
			
		Return CommonInternalClient.AddInInstallationError(ErrorText);
	EndIf;
	
EndFunction

Procedure InstallAddInSSL(Context) Export
	
	Notification = New NotifyDescription(
		"InstallAddInAfterAvailabilityCheck", 
		ThisObject, 
		Context);
	
	CheckAddInAvailability(Notification, Context);
	
EndProcedure

// Parameters:
//  Result - Structure - :
//    * Attached - Boolean -  the sign connection;
//    * Attachable_Module - AddInObject -  an instance of an external component object.
//    * ErrorDescription - String -  brief description of the error. When canceled by the user, an empty string.
//  Context - See CommonInternalClient.AddInAttachmentContext 
//
Procedure InstallAddInAfterAvailabilityCheck(Result, Context) Export
	
	If Result.Available Then 
		CommonInternalClient.InstallAddInSSL(Context);
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot attach the ""%1"" add-in
			           |on the client from the add-in storage.
			           |Reason:
			           |%2';"),
			Context.Id,
			Result.ErrorDescription);
			
		CommonInternalClient.InstallAddInSSLNotifyOnError(ErrorText, Context);
	EndIf;
	
EndProcedure

#EndRegion

#Region ImportAddInFromFile

// Returns:
//  Structure:
//   * Notification - NotifyDescription
//   * Id - String
//   * Version - String
//   * AdditionalInformationSearchParameters - Map
//
Function ContextForLoadingComponentsFromAFile() Export
	
	Context = New Structure;
	Context.Insert("Notification", Undefined);
	Context.Insert("Id", "");
	Context.Insert("Version", "");
	Context.Insert("AdditionalInformationSearchParameters", New Map);
	Return Context;
	
EndFunction
	
// To call from an external component client.Upload the component of the file.
// 
// Parameters:
//  Context - See ContextForLoadingComponentsFromAFile.
//
Procedure ImportAddInFromFile(Context) Export 
	
	Information = AddInsInternalServerCall.SavedAddInInformation(Context.Id, Context.Version);
	
	If Information.ImportFromFileIsAvailable Then
		
		AdditionalInformationSearchParameters = Context.AdditionalInformationSearchParameters;
		
		FormParameters = New Structure;
		FormParameters.Insert("ShowImportFromFileDialogOnOpen", True);
		FormParameters.Insert("ReturnImportResultFromFile", True);
		FormParameters.Insert("AdditionalInformationSearchParameters", AdditionalInformationSearchParameters);
		
		If Information.State = "FoundInStorage"
			Or Information.State = "DisabledByAdministrator" Then
			
			FormParameters.Insert("ShowImportFromFileDialogOnOpen", False);
			FormParameters.Insert("Key", Information.Ref);
		EndIf;
		
		Notification = New NotifyDescription("ImportAddInFromFileAfterImport", ThisObject, Context);
		OpenForm("Catalog.AddIns.ObjectForm", FormParameters,,,,, Notification);
		
	Else 
		
		Notification = New NotifyDescription("ImportAddInFromFileAfterAvailabilityWarnings", ThisObject, Context);
		ShowMessageBox(Notification, 
			NStr("en = 'Add-in import is canceled
			           |due to:
			           |You must have administrative rights';"));
		
	EndIf;
	
EndProcedure

// Continue with the upload component of the File procedure.
Procedure ImportAddInFromFileAfterAvailabilityWarnings(Context) Export
	
	Result = AddInImportResult();
	Result.Imported1 = False;
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Continue with the upload component of the File procedure.
Procedure ImportAddInFromFileAfterImport(Result, Context) Export
	
	//  
	// 
	//  
	
	UserClosedDialogBox = (Result = Undefined);
	
	Notification = Context.Notification;
	
	If UserClosedDialogBox Then 
		Result = AddInImportResult();
		Result.Imported1 = False;
	EndIf;
	
	ExecuteNotifyProcessing(Notification, Result);
	
EndProcedure

// Continue with the upload component of the File procedure.
Function AddInImportResult() Export
	
	Result = New Structure;
	Result.Insert("Imported1", False);
	Result.Insert("Id", "");
	Result.Insert("Version", "");
	Result.Insert("Description", "");
	Result.Insert("AdditionalInformation", New Map);
	
	Return Result;
	
EndFunction

#EndRegion

#Region ComponentSearchOnPortal

Procedure AddInSearchOnPortalOnGenerateResult(Result, Notification) Export
	
	Imported1 = (Result = True); // 
	ExecuteNotifyProcessing(Notification, Imported1);
	
EndProcedure

#EndRegion

#Region UpdateAddInsFromPortal

// Parameters:
//  Notification - NotifyDescription
//  AddInsToUpdate - Array of CatalogRef.AddIns
//
Procedure UpdateAddInsFromPortal(Notification, AddInsToUpdate) Export
	
	NotificationForms = New NotifyDescription("UpdateAddInFromPortalOnGenerateResult", ThisObject, Notification);
	AddInsClientLocalization.UpdateAddInsFromPortal(NotificationForms, AddInsToUpdate);
	
EndProcedure

Procedure UpdateAddInFromPortalOnGenerateResult(Result, Notification) Export
	
	ExecuteNotifyProcessing(Notification, Undefined);
	
EndProcedure

#EndRegion

#Region SaveAddInToFile

// Parameters:
//  AddInRef - CatalogRef.AddIns
//                          - Array of CatalogRef.AddIns
//
Procedure SaveAddInToFile(AddInRef) Export
	
	If TypeOf(AddInRef) = Type("Array") Then
		References = AddInRef;
	Else
		References = CommonClientServer.ValueInArray(AddInRef);
	EndIf;
	FilesDetails = AddInsInternalServerCall.AddInsFilesDetails(References);

	If References.Count() = 1 Then
		
		SavingParameters = FileSystemClient.FileSavingParameters();
		SavingParameters.Dialog.Title = NStr("en = 'Select a file to save the add-in to';");
		SavingParameters.Dialog.Filter    = NStr("en = 'Add-in files (*.zip)|*.zip';")+"|"
			+ StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'All files (%1)|%1';"), GetAllFilesMask());
		
		Notification = New NotifyDescription("SaveAddInToFileAfterReceivingFiles", ThisObject);
		FileSystemClient.SaveFile(Notification, FilesDetails[0].Location, FilesDetails[0].Name, SavingParameters);
		
		Return;
	EndIf;
	
	Notification = New NotifyDescription("SaveAddInsToFileAfterDirectorySelected", ThisObject, FilesDetails);
	FileSystemClient.SelectDirectory(Notification, NStr("en = 'Select a directory to save the add-ins';"));
	
EndProcedure

// Continue with the save component File procedure.
Procedure SaveAddInsToFileAfterDirectorySelected(Directory, FilesDetails) Export
	
	If IsBlankString(Directory) Then
		Return;
	EndIf;
	
	FilesToSave = New Array;
	For Each FileDetails In FilesDetails Do
		FilesToSave.Add(New TransferableFileDescription(FileDetails.Name, FileDetails.Location));
	EndDo;
	
	SavingParameters = FileSystemClient.FilesSavingParameters();
	SavingParameters.Interactively = False;
	SavingParameters.Dialog.Directory = Directory;
	FileSystemClient.SaveFiles(New NotifyDescription(
		"SaveAddInToFileAfterReceivingFiles", ThisObject), 
		FilesToSave, SavingParameters);

EndProcedure

// Continue with the save component File procedure.
Procedure SaveAddInToFileAfterReceivingFiles(ObtainedFiles, Context) Export
	
	If ObtainedFiles <> Undefined 
		And ObtainedFiles.Count() > 0 Then
		
		MessageText = ?(ObtainedFiles.Count() = 1, 
			NStr("en = 'The add-in is saved to the file.';"),
			NStr("en = 'The add-ins are saved to the files.';"));
		
		ShowUserNotification(NStr("en = 'Save to file';"),,
			MessageText, PictureLib.Success32);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

