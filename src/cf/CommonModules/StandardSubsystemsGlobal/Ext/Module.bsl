///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Continues to run in interactive mode with the user.
Procedure TheHandlerWaitsToStartInteractiveProcessingBeforeTheSystemStartsWorking() Export
	
	StandardSubsystemsClient.StartInteractiveProcessingBeforeStartingTheSystem();
	
EndProcedure

// Continues to run in interactive mode with the user.
Procedure OnStartIdleHandler() Export
	
	StandardSubsystemsClient.OnStart(, False);
	
EndProcedure

// Continues completion in the interactive mode with the user
// after the installation Failure = True.
//
Procedure BeforeExitInteractiveHandlerIdleHandler() Export
	
	StandardSubsystemsClient.StartInteractiveHandlerBeforeExit();
	
EndProcedure

// Called after starting the configuration, opens the information window.
Procedure ShowInformationAfterStart() Export
	ModuleInformationOnStartClient = CommonClient.CommonModule("InformationOnStartClient");
	ModuleInformationOnStartClient.Show();
EndProcedure

// Called after starting the configuration, opens the security warning window.
Procedure ShowSecurityWarningAfterStart() Export
	UsersInternalClient.ShowSecurityWarningAfterStartupIfNecessary();
EndProcedure

// Displays a message to the user about insufficient RAM.
Procedure ShowRAMRecommendation() Export
	StandardSubsystemsClient.NotifyLowMemory();
EndProcedure

// Displays a pop-up warning that you need to perform additional
// actions before shutting down the system.
//
Procedure ShowExitWarning() Export
	Warnings = StandardSubsystemsClient.ClientParameter("ExitWarnings");
	Explanation = NStr("en = 'and perform additional actions.';");
	If Warnings.Count() = 1 And Not IsBlankString(Warnings[0].HyperlinkText) Then
		Explanation = Warnings[0].HyperlinkText;
	EndIf;
	ShowUserNotification(NStr("en = 'Click here to exit';"), 
		"e1cib/command/CommonCommand.ExitWarnings",
		Explanation, PictureLib.ExitApplication, UserNotificationStatus.Important);
EndProcedure

Procedure RefreshInterfaceOnFunctionalOptionToggle() Export
	
	RefreshReusableValues();
	RefreshInterface();
	
EndProcedure

Procedure RestartingApplication() Export
	StandardSubsystemsClient.SkipExitConfirmation();
	Exit(True, True);
EndProcedure

Procedure NotificationFiveMinutesBeforeRestart() Export

	StandardSubsystemsClient.NotifyCurrentUserOfUpcomingRestart(300);

EndProcedure

Procedure NotificationThreeMinutesBeforeRestart() Export

	StandardSubsystemsClient.NotifyCurrentUserOfUpcomingRestart(180);

EndProcedure

Procedure NotificationOneMinuteBeforeRestart() Export

	StandardSubsystemsClient.NotifyCurrentUserOfUpcomingRestart(60);

EndProcedure

Procedure ControlRestartWhenAccessRightsReduced() Export
	UsersInternalClient.OnControlRestartWhenAccessRightsReduced();
EndProcedure

#EndRegion
