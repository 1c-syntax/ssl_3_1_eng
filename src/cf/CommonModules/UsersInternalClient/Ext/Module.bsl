///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Opens a form where the user can change their password.
Procedure OpenChangePasswordForm(User = Undefined, ContinuationHandler = Undefined, AdditionalParameters = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ReturnPasswordAndDoNotSet", False);
	FormParameters.Insert("PreviousPassword", Undefined);
	FormParameters.Insert("LoginName",  "");
	If AdditionalParameters <> Undefined Then
		FillPropertyValues(FormParameters, AdditionalParameters);
	EndIf;
	FormParameters.Insert("User", User);
	
	OpenForm("CommonForm.PasswordChange", FormParameters,,,,, ContinuationHandler);
	
EndProcedure

// See UsersInternalSaaSClient.RequestPasswordForAuthenticationInService.
Procedure RequestPasswordForAuthenticationInService(ContinuationHandler, OwnerForm = Undefined, ServiceUserPassword = Undefined) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.SaaSOperations.UsersSaaS") Then
		
		ModuleUsersInternalSaaSClient = CommonClient.CommonModule(
			"UsersInternalSaaSClient");
		
		ModuleUsersInternalSaaSClient.RequestPasswordForAuthenticationInService(
			ContinuationHandler, OwnerForm, ServiceUserPassword);
	EndIf;
	
EndProcedure

Procedure InstallInteractiveDataProcessorOnInsufficientRightsToSignInError(Parameters, ErrorDescription) Export
	
	Parameters.Cancel = True;
	Parameters.InteractiveHandler = New NotifyDescription(
		"InteractiveDataProcessorOnInsufficientRightsToSignInError", ThisObject, ErrorDescription);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// For internal use only.
//
// Parameters:
//  Form - ClientApplicationForm
//  Unconditionally - Boolean
//
Procedure ExpandRoleSubsystems(Form, Unconditionally = True) Export
	
	Items = Form.Items;
	
	If Not Unconditionally
	   And Not Items.RolesShowSelectedRolesOnly.Check Then
		
		Return;
	EndIf;
	
	// 
	For Each TableRow In Form.Roles.GetItems() Do
		Items.Roles.Expand(TableRow.GetID(), True);
	EndDo;
	
EndProcedure

// For internal use only.
Procedure SelectPurpose(FormData1, Title, SelectUsersAllowed = True, IsFilter = False, NotifyDescription = Undefined) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormData1", FormData1);
	AdditionalParameters.Insert("IsFilter", IsFilter);
	AdditionalParameters.Insert("NotifyDescription", NotifyDescription);
	
	OnCloseNotifyDescription = New NotifyDescription("AfterAssignmentChoice", ThisObject, AdditionalParameters);
	
	Purpose = ?(IsFilter, FormData1.UsersKind, FormData1.Object.Purpose);
	
	FormParameters = New Structure;
	FormParameters.Insert("Title", Title);
	FormParameters.Insert("Purpose", Purpose);
	FormParameters.Insert("SelectUsersAllowed", SelectUsersAllowed);
	FormParameters.Insert("IsFilter", IsFilter);
	OpenForm("CommonForm.SelectUsersTypes", FormParameters,,,,, OnCloseNotifyDescription);
	
EndProcedure

// 
//
// Parameters:
//  Notification - NotifyDescription - 
//                 
//             - Undefined - 
//
//  TypeOfWarning - See UsersInternalClientServer.TypesOfSafetyWarnings
//
//  AdditionalParameter - Arbitrary - 
//
Procedure ShowSecurityWarning(Notification, TypeOfWarning, AdditionalParameter = Undefined) Export
	
	If Not UsersInternalClientServer.TypesOfSafetyWarnings().Property(TypeOfWarning) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of parameter ""%1"" in procedure ""%2"":
			           |""%3"".';"),
			"TypeOfWarning",
			"UsersInternalClient.ShowSecurityWarning",
			TypeOfWarning);
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", TypeOfWarning);
	FormParameters.Insert("AdditionalParameter", AdditionalParameter);
	
	OpenForm("CommonForm.SecurityWarning", FormParameters,,,,, Notification);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// 

// 
Procedure ShowSecurityWarningAfterStartupIfNecessary() Export
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	Var_Key = CommonClientServer.StructureProperty(ClientRunParameters, "SecurityWarningKey");
	If ValueIsFilled(Var_Key) Then
		ShowSecurityWarning(Undefined, Var_Key);
	EndIf;
	
EndProcedure

Procedure OnControlRestartWhenAccessRightsReduced() Export
	NotifyAboutAppRestart();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart(Parameters) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientParameters.Property("ErrorInsufficientRightsForAuthorization") Then
		Parameters.RetrievedClientParameters.Insert("ErrorInsufficientRightsForAuthorization");
		InstallInteractiveDataProcessorOnInsufficientRightsToSignInError(Parameters,
			ClientParameters.ErrorInsufficientRightsForAuthorization);
	EndIf;
	
EndProcedure

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart2(Parameters) Export
	
	// 
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientParameters.Property("AuthorizationError") Then
		Parameters.Cancel = True;
		Parameters.InteractiveHandler = New NotifyDescription("ShowMessageBoxAndContinue",
			StandardSubsystemsClient, ClientParameters.AuthorizationError);
		Return;
	EndIf;
	
EndProcedure

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart3(Parameters) Export
	
	// 
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientParameters.Property("PasswordChangeRequired") Then
		Parameters.InteractiveHandler = New NotifyDescription(
			"InteractiveHandlerOnChangePasswordOnStart", ThisObject);
		Return;
	EndIf;
	
EndProcedure

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	Var_Key = CommonClientServer.StructureProperty(ClientRunParameters, "SecurityWarningKey");
	If ValueIsFilled(Var_Key) Then
		// 
		AttachIdleHandler("ShowSecurityWarningAfterStart", 0.3, True);
	EndIf;
	
	If ClientRunParameters.Property("AskAboutDisablingOpenIDConnect") Then
		ClickNotification = New NotifyDescription("AskAboutDisablingOpenIDConnect", ThisObject);
		MessageTitle = NStr("en = 'Security warning';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Disable %1 authentication if it is not used.';"), "OpenID-Connect");
		ShowUserNotification(MessageTitle, ClickNotification,
			MessageText, PictureLib.DialogExclamation, UserNotificationStatus.Important);
	EndIf;
	
EndProcedure

// See StandardSubsystemsClient.OnReceiptServerNotification.
Procedure OnReceiptServerNotification(NameOfAlert, Result) Export
	
	If Result = "AuthorizationDenied" Then
		StopAppRestart();
		OpenForm("CommonForm.AuthorizationDenied");
		
	ElsIf Result = "RolesReduced" Then
		InitiateAppRestart();
		
	ElsIf Result = "RolesIncreased" Then
		StopAppRestart();
		ShowUserNotification(
			NStr("en = 'Access rights updated';"),
			"e1cib/app/CommonForm.InfobaseUserRoleChangeControl",
			NStr("en = 'Restart the application so that they come into force.';"),
			PictureLib.DialogExclamation,
			UserNotificationStatus.Important,
			"InfobaseUserRoleChangeControl");
		
	ElsIf TypeOf(Result) = Type("Number") Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Your access will expire in %1.
			           |To extend access, contact your administrator.';"),
			Format(Result, "NG=") + " "
				+ UsersInternalClientServer.IntegerSubject(Result,
					"", NStr("en = 'day,days,,,0';")));
		
		ShowUserNotification(
			NStr("en = 'Access about to expire';"),,
			MessageText,
			PictureLib.DialogExclamation,
			UserNotificationStatus.Important,
			"UserExpirationInApp");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

///////////////////////////////////////////////////////////////////////////////
// 

// Warns the user about the error of insufficient rights to log in to the program.
Procedure InteractiveDataProcessorOnInsufficientRightsToSignInError(Parameters, ErrorDescription) Export
	
	ShowMessageBox(
		New NotifyDescription("InteractiveDataProcessorOnInsufficientRightsToSignInErrorAfterWarning",
			ThisObject, Parameters),
		ErrorDescription);
	
EndProcedure

// Shuts down after warning the user about the error of insufficient rights to log in to the program.
Procedure InteractiveDataProcessorOnInsufficientRightsToSignInErrorAfterWarning(Parameters) Export
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// Prompts the user to change their password or exit.
Procedure InteractiveHandlerOnChangePasswordOnStart(Parameters, Context) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("OnAuthorization", True);
	
	OpenForm("CommonForm.PasswordChange", FormParameters,,,,, New NotifyDescription(
		"InteractiveHandlerOnChangePasswordOnStartCompletion", ThisObject, Parameters));
	
EndProcedure

// Continue the interactionprocessing procedure when changing the password on Startup.
Procedure InteractiveHandlerOnChangePasswordOnStartCompletion(Result, Parameters) Export
	
	If Not ValueIsFilled(Result) Then
		Parameters.Cancel = True;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// 
Procedure AskAboutDisablingOpenIDConnect(Context) Export
	
	CompletionProcessing = New NotifyDescription(
		"AskAboutDisablingOpenIDConnectCompletion", ThisObject);
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = '%1 authentication is enabled for users.
		           |If you do not use this authentication kind, disable it.';"),
		"OpenID-Connect");
	
	Buttons = New ValueList;
	Buttons.Add("DisabledForAllUsers", NStr("en = 'Disable for all users';"));
	Buttons.Add("DoNotDisable",                 NStr("en = 'Do not disable';"));
	Buttons.Add("RemindLater",              NStr("en = 'Remind me later';"));
	
	AdditionalParameters = StandardSubsystemsClient.QuestionToUserParameters();
	AdditionalParameters.Title = NStr("en = 'Security warning';");
	AdditionalParameters.PromptDontAskAgain = False;
	
	StandardSubsystemsClient.ShowQuestionToUser(CompletionProcessing,
		QueryText, Buttons, AdditionalParameters);
	
EndProcedure

// 
Procedure AskAboutDisablingOpenIDConnectCompletion(Result, Parameters) Export
	
	Response = ?(Result <> Undefined, Result.Value, "RemindLater");
	
	If Response = "DisabledForAllUsers" Then
		StandardSubsystemsServerCall.ProcessAnswerOnDisconnectingOpenIDConnect(True);
	ElsIf Response = "DoNotDisable" Then
		StandardSubsystemsServerCall.ProcessAnswerOnDisconnectingOpenIDConnect(False);
	EndIf;
	
EndProcedure

// Writes the result of selecting a destination to the form.
//
// Parameters:
//  ClosingResult - Undefined
//                    - ValueList
//  AdditionalParameters - Structure:
//    * FormData1 - ClientApplicationForm
//                  - ManagedFormExtensionForObjects:
//        ** Object - FormDataStructure
//        ** Items - FormAllItems:
//              *** SelectPurpose - FormButton
//    * IsFilter - Boolean
//    * NotifyDescription - NotifyDescription
//
Procedure AfterAssignmentChoice(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	If Not AdditionalParameters.IsFilter Then
		Purpose = AdditionalParameters.FormData1.Object.Purpose;
		Purpose.Clear();
	EndIf;
	
	SynonymArray = New Array;
	TypesArray = New Array;
	
	For Each Item In ClosingResult Do
		
		If Item.Check Then
			SynonymArray.Add(Item.Presentation);
			TypesArray.Add(Item.Value);
			If Not AdditionalParameters.IsFilter Then
				NewRow = Purpose.Add();
				NewRow.UsersType = Item.Value;
			EndIf;
		EndIf;
		
	EndDo;
	
	ItemTitle = StrConcat(SynonymArray, ", ");
	
	If AdditionalParameters.IsFilter Then
		AdditionalParameters.FormData1.UsersKind = ItemTitle;
	Else
		AdditionalParameters.FormData1.Items.SelectPurpose.Title = ItemTitle;
	EndIf;
	
	If AdditionalParameters.NotifyDescription <> Undefined Then
		ExecuteNotifyProcessing(AdditionalParameters.NotifyDescription, TypesArray);
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// 

// Used to open the submitted report or form.
//
// Parameters:
//  CurrentItem               - FormTable -  selected row in the value tree.
//  User                 - String -  name of the database user,
//  CurrentUser          - String -  the name of the user of the information database to open the form
//                                 must match the value of the "User" parameter.
//  PersonalSettingsFormName - String -  path to open the personal settings form.
//                                 Type " General Form.Form name".
//
Procedure OpenReportOrForm(CurrentItem, User, CurrentUser, PersonalSettingsFormName) Export
	
	ValueTreeItem = CurrentItem;
	If ValueTreeItem.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If User <> CurrentUser Then
		WarningText =
			NStr("en = 'To view settings of another user,
			           |restart the application on behalf of that user and open the setting.';");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	If ValueTreeItem.Name = "ReportSettingsTree" Then
		
		ObjectKey = ValueTreeItem.CurrentData.Keys[0].Value;
		ObjectKeyRowArray = StrSplit(ObjectKey, "/", False);
		VariantKey = ObjectKeyRowArray[1];
		ReportParameters = New Structure("VariantKey, UserSettingsKey", VariantKey, "");
		
		If ValueTreeItem.CurrentData.Type = "ReportSettings1" Then
			UserSettingsKey = ValueTreeItem.CurrentData.Keys[0].Presentation;
			ReportParameters.Insert("UserSettingsKey", UserSettingsKey);
		EndIf;
		
		OpenForm(ObjectKeyRowArray[0] + ".Form", ReportParameters);
		Return;
		
	ElsIf ValueTreeItem.Name = "Interface" Then
		
		For Each ObjectKey In ValueTreeItem.CurrentData.Keys Do
			
			If ObjectKey.Check = True Then
				
				FormName = StrSplit(ObjectKey.Value, "/")[0];
				FormNameParts = StrSplit(FormName, ".");
				While FormNameParts.Count() > 4 Do
					FormNameParts.Delete(4);
				EndDo;
				FormName = StrConcat(FormNameParts, ".");
				OpenForm(FormName);
				Return;
			Else
				ItemParent = ValueTreeItem.CurrentData.GetParent();
				
				If ValueTreeItem.CurrentData.RowType = "DesktopSettings" Then
					ShowMessageBox(,
						NStr("en = 'Navigate to ""Home page"" to view its settings.';"));
					Return;
				EndIf;
				
				If ValueTreeItem.CurrentData.RowType = "CommandInterfaceSettings" Then
					ShowMessageBox(,
						NStr("en = 'To view the command interface settings,
						           |select a section in the application command interface.';"));
					Return;
				EndIf;
				
				If ItemParent <> Undefined Then
					WarningText =
						NStr("en = 'To view this setting, open ""%1""
						           |and go to the ""%2"" form.';");
					WarningText = StringFunctionsClientServer.SubstituteParametersToString(WarningText,
						ItemParent.Setting, ValueTreeItem.CurrentData.Setting);
					ShowMessageBox(,WarningText);
					Return;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		ShowMessageBox(,NStr("en = 'Cannot view this setting.';"));
		Return;
		
	ElsIf ValueTreeItem.Name = "OtherSettings" Then
		
		If ValueTreeItem.CurrentData.Type = "PersonalSettings"
			And PersonalSettingsFormName <> "" Then
			OpenForm(PersonalSettingsFormName);
			Return;
		EndIf;
		
		ShowMessageBox(,NStr("en = 'Cannot view this setting.';"));
		Return;
		
	EndIf;
	
	ShowMessageBox(,NStr("en = 'Select a setting to view.';"));
	
EndProcedure

// It is used to generate an explanation string when copying settings.
//
// Parameters:
//  SettingPresentation            - String -  name of the setting. Used if a single setting is copied.
//  SettingsCount                - Number  -  number of settings. Used if two or more settings are copied.
//  SettingsCopiedToNote - String -  who the settings are copied to.
//
// Returns:
//  String - 
//
Function GenerateNoteOnCopy(SettingPresentation, SettingsCount, SettingsCopiedToNote) Export
	
	If SettingsCount = 1 Then
		
		If StrLen(SettingPresentation) > 24 Then
			SettingPresentation = Left(SettingPresentation, 24) + "...";
		EndIf;
		
		NotificationComment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '""%1"" copied to %2.';"),
			SettingPresentation,
			SettingsCopiedToNote);
	Else
		SubjectInWords = Format(SettingsCount, "NFD=0") + " "
			+ UsersInternalClientServer.IntegerSubject(SettingsCount,
				"", NStr("en = 'setting,settings,,,0';"));
		
		NotificationComment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1 copied to %2.';"),
			SubjectInWords,
			SettingsCopiedToNote);
	EndIf;
	
	Return NotificationComment;
	
EndFunction

// Generates the configuration recipient string.
//
// Parameters:
//  UsersCount - Number  -  used if the value is greater than one.
//  User            - String -  user name. Used if the number of users
//                            is equal to one.
//
// Returns:
//  String - 
//
Function UsersNote(UsersCount, User) Export
	
	If UsersCount = 1 Then
		SettingsCopiedToNote = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'user ""%1""';"), User);
	Else
		SettingsCopiedToNote = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1 users.';"), UsersCount);
	EndIf;
	
	Return SettingsCopiedToNote;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// 

Procedure InitiateAppRestart()
	
	Parameters = RestartNotificationParameters();
	If ValueIsFilled(Parameters.RestartDate) Then
		Return;
	EndIf;
	
	Parameters.RestartDate = CommonClient.SessionDate() + 15*60; // 
	
	AttachIdleHandler("ControlRestartWhenAccessRightsReduced", 60);
	NotifyAboutAppRestart();
	
EndProcedure

Procedure StopAppRestart()
	
	DetachIdleHandler("ControlRestartWhenAccessRightsReduced");
	ClearRestartAlert();
	RestartNotificationParameters().RestartDate = '00010101';
	
EndProcedure

Procedure NotifyAboutAppRestart()
	
	Parameters = RestartNotificationParameters();
	If Not ValueIsFilled(Parameters.RestartDate) Then
		Return;
	EndIf;
	
	If Not StandardSubsystemsServerCall.AreCurrentUserRolesReduced() Then
		StopAppRestart();
		Return;
	EndIf;
	
	WaitTimeout = 10; // 
	ExitWithConfirmationTimeout = 5; // 
	CurrentMoment = CommonClient.SessionDate();
	
	If Parameters.RestartDate - CurrentMoment < 5 Then
		RestartNow();
		Return;
	EndIf;
	
	MinutesLeft = MinutesBeforeRestart(Parameters.RestartDate, CurrentMoment);
	MinutesLeftPresentation = MinutesBeforeRestartPresentation(MinutesLeft);
	
	ShowRestartAlert(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'App will restart in %1. Save the changes.';"),
		MinutesLeftPresentation));
	
	If MinutesLeft <= ExitWithConfirmationTimeout Then
		AskOnTermination(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'App will restart in %1. Save the changes.
			           |Restart now?';"),
			MinutesLeftPresentation));
		
	ElsIf MinutesLeft <= WaitTimeout Then
		ShowWarningOnExit(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'App will restart in %1. Save the changes.';"),
			MinutesLeftPresentation));
	EndIf;
	
EndProcedure

Function MinutesBeforeRestart(RestartDate, CurrentMoment = Undefined) Export
	
	If CurrentMoment = Undefined Then
		CurrentMoment = CommonClient.SessionDate();
	EndIf;
	
	MinutesLeft = Int((RestartDate - CurrentMoment) / 60);
	
	Return ?(MinutesLeft > 0, MinutesLeft, 1);
	
EndFunction

Function MinutesBeforeRestartPresentation(MinutesLeft) Export
	
	Return StringFunctionsClientServer.StringWithNumberForAnyLanguage(
		NStr("en = ';%1 minute;;;;%1 minutes';"),
		MinutesLeft);
	
EndFunction

// Parameters:
//  ShouldUpdateLastWarningOrQuestionDate - Boolean
//
// Returns:
//  Structure:
//   * IsNotificationDisplayed - Boolean
//   * ShowWarningOrQuestion - Boolean
//   * LastQuestionOrWarningDate - Date
//   * RestartDate - Date
//
Function RestartNotificationParameters(ShouldUpdateLastWarningOrQuestionDate = False) Export
	
	ParameterName = "StandardSubsystems.Users.RestartNotificationParameters";
	Properties = ApplicationParameters[ParameterName];
	If Properties = Undefined Or Not ValueIsFilled(Properties.RestartDate) Then
		Properties = New Structure;
		Properties.Insert("IsNotificationDisplayed", False);
		Properties.Insert("ShowWarningOrQuestion", False);
		Properties.Insert("LastQuestionOrWarningDate", '00010101');
		Properties.Insert("RestartDate", '00010101');
		ApplicationParameters.Insert(ParameterName, Properties);
	EndIf;
	
	If ShouldUpdateLastWarningOrQuestionDate Then
		SessionDate = CommonClient.SessionDate();
		If Properties.LastQuestionOrWarningDate + 50 < SessionDate Then
			Properties.LastQuestionOrWarningDate = SessionDate;
			Properties.ShowWarningOrQuestion = True;
		Else
			Properties.ShowWarningOrQuestion = False;
		EndIf;
	EndIf;
	
	Return Properties;
	
EndFunction

Procedure ShowRestartAlert(MessageText)
	
	Parameters = RestartNotificationParameters();
	If Parameters.IsNotificationDisplayed Then
		Return;
	EndIf;
	
	ShowUserNotification(
		NStr("en = 'App will restart';"),
		"e1cib/app/CommonForm.InfobaseUserRoleChangeControl",
		MessageText,
		PictureLib.DialogExclamation,
		UserNotificationStatus.Important,
		"ControlRestartWhenAccessRightsReduced");
	
	Parameters.IsNotificationDisplayed = True;
	
EndProcedure

Procedure ClearRestartAlert()
	
	Parameters = RestartNotificationParameters();
	If Not Parameters.IsNotificationDisplayed Then
		Return;
	EndIf;
	Parameters.IsNotificationDisplayed = False;
	
	ShowUserNotification(NStr("en = 'Restart canceled';"),,,,
		UserNotificationStatus.Important, "ControlRestartWhenAccessRightsReduced");
	
EndProcedure

Procedure ShowWarningOnExit(WarningText)
	
	Parameters = RestartNotificationParameters(True);
	If Not Parameters.ShowWarningOrQuestion Then
		Return;
	EndIf;
	
	ShowMessageBox(, WarningText, 30);
	
EndProcedure

Procedure AskOnTermination(QueryText)
	
	Parameters = RestartNotificationParameters(True);
	If Not Parameters.ShowWarningOrQuestion Then
		Return;
	EndIf;
	
	NotifyDescription = New NotifyDescription("AskOnTerminationCompletion", ThisObject);
	ShowQueryBox(NotifyDescription, QueryText, QuestionDialogMode.YesNo, 30, DialogReturnCode.Yes);
	
EndProcedure

Procedure AskOnTerminationCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		RestartNow();
	EndIf;
	
EndProcedure

Procedure RestartNow()
	
	StandardSubsystemsClient.SkipExitConfirmation();
	Exit(True, True);
	
EndProcedure

#EndRegion
