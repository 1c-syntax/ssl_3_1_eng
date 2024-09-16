///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Sets the title of the main application window using the constant value
// App title and default app title.
//
// Parameters:
//   OnStart - Boolean -  True if called when the program starts.
//
Procedure SetAdvancedApplicationCaption(OnStart = False) Export
	
	ClientParameters = ?(OnStart, ClientParametersOnStart(),
		ClientRunParameters());
		
	If CommonClient.SeparatedDataUsageAvailable() Then
		CaptionPresentation = ClientParameters.ApplicationCaption;
		ConfigurationPresentation = ClientParameters.DetailedInformation;
		
		If IsBlankString(TrimAll(CaptionPresentation)) Then
			If ClientParameters.Property("DataAreaPresentation") Then
				TitleTemplate1 = "%1 / %2";
				ApplicationCaption = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, ClientParameters.DataAreaPresentation,
					ConfigurationPresentation);
			Else
				TitleTemplate1 = "%1";
				ApplicationCaption = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, ConfigurationPresentation);
			EndIf;
		Else
			TitleTemplate1 = "%1 / %2";
			ApplicationCaption = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1,
				TrimAll(CaptionPresentation), ConfigurationPresentation);
		EndIf;
	Else
		TitleTemplate1 = "%1 / %2";
		ApplicationCaption = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, NStr("en = 'Separators are not set';"), ClientParameters.DetailedInformation);
	EndIf;
	
	If Not CommonClient.DataSeparationEnabled()
	   And ClientParameters.Property("OperationsWithExternalResourcesLocked") Then
		ApplicationCaption = "[" + NStr("en = 'COPY';") + "]" + " " + ApplicationCaption;
	EndIf;
	
	CommonClientOverridable.ClientApplicationCaptionOnSet(ApplicationCaption, OnStart);
	
	ClientApplication.SetCaption(ApplicationCaption);
	
EndProcedure

// To show the form of a question.
//
// Parameters:
//   NotifyDescriptionOnCompletion - NotifyDescription - 
//                                                        :
//                                                          
//                                                            
//                                                                       
//                                                                       
//                                                                       
//                                                                       
//                                                            
//                                                                                                  
//                                                                                                  
//                                                          AdditionalParameters - Structure 
//    
//   
//                                 - ValueList     - :
//                                        
//                                                  
//                                                  
//                                                  
//                                       
//
//    See StandardSubsystemsClient.QuestionToUserParameters.
//
Procedure ShowQuestionToUser(NotifyDescriptionOnCompletion, QueryText, Buttons, AdditionalParameters = Undefined) Export
	
	Parameters = QuestionToUserParameters();
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FillPropertyValues(Parameters, AdditionalParameters);
	EndIf;
	
	DialogReturnCodes = New Map;
	DialogReturnCodes.Insert(DialogReturnCode.Yes, "DialogReturnCode.Yes");
	DialogReturnCodes.Insert(DialogReturnCode.No, "DialogReturnCode.None");
	DialogReturnCodes.Insert(DialogReturnCode.OK, "DialogReturnCode.OK");
	DialogReturnCodes.Insert(DialogReturnCode.Cancel, "DialogReturnCode.Cancel");
	DialogReturnCodes.Insert(DialogReturnCode.Retry, "DialogReturnCode.Retry");
	DialogReturnCodes.Insert(DialogReturnCode.Abort, "DialogReturnCode.Abort");
	DialogReturnCodes.Insert(DialogReturnCode.Ignore, "DialogReturnCode.Ignore");
	DialogReturnCodes.Insert(DialogReturnCode.Timeout, "DialogReturnCode.Timeout");
	
	ButtonsPresentations = New Map;
	ButtonsPresentations.Insert(DialogReturnCode.Yes, NStr("en = 'Yes';"));
	ButtonsPresentations.Insert(DialogReturnCode.No, NStr("en = 'No';"));
	ButtonsPresentations.Insert(DialogReturnCode.OK, NStr("en = 'OK';"));
	ButtonsPresentations.Insert(DialogReturnCode.Cancel, NStr("en = 'Cancel';"));
	ButtonsPresentations.Insert(DialogReturnCode.Retry, NStr("en = 'Repeat';"));
	ButtonsPresentations.Insert(DialogReturnCode.Abort, NStr("en = 'Abort';"));
	ButtonsPresentations.Insert(DialogReturnCode.Ignore, NStr("en = 'Ignore';"));
	ButtonsPresentations.Insert(DialogReturnCode.Timeout, NStr("en = 'Timeout';"));
	
	QuestionDialogModes = New Map;
	QuestionDialogModes.Insert(QuestionDialogMode.YesNo, "QuestionDialogMode.YesNo");
	QuestionDialogModes.Insert(QuestionDialogMode.YesNoCancel, "QuestionDialogMode.YesNoCancel");
	QuestionDialogModes.Insert(QuestionDialogMode.OK, "QuestionDialogMode.OK");
	QuestionDialogModes.Insert(QuestionDialogMode.OKCancel, "QuestionDialogMode.OKCancel");
	QuestionDialogModes.Insert(QuestionDialogMode.RetryCancel, "QuestionDialogMode.RetryCancel");
	QuestionDialogModes.Insert(QuestionDialogMode.AbortRetryIgnore, "QuestionDialogMode.AbortRetryIgnore");
	
	DialogButtons = Buttons;
	
	If TypeOf(Buttons) = Type("ValueList") Then
		DialogButtons = CommonClient.CopyRecursive(Buttons);
		For Each Button In DialogButtons Do
			If Button.Presentation = "" Then
				Button.Presentation = ButtonsPresentations[Button.Value];
			EndIf;
			If TypeOf(Button.Value) = Type("DialogReturnCode") Then
				Button.Value = DialogReturnCodes[Button.Value];
			EndIf;
		EndDo;
	EndIf;
	
	If TypeOf(Buttons) = Type("QuestionDialogMode") Then
		DialogButtons = QuestionDialogModes[Buttons];
	EndIf;
	
	If TypeOf(Parameters.DefaultButton) = Type("DialogReturnCode") Then
		Parameters.DefaultButton = DialogReturnCodes[Parameters.DefaultButton];
	EndIf;
	
	If TypeOf(Parameters.TimeoutButton) = Type("DialogReturnCode") Then
		Parameters.TimeoutButton = DialogReturnCodes[Parameters.TimeoutButton];
	EndIf;
	
	Parameters.Insert("Buttons", DialogButtons);
	Parameters.Insert("MessageText", QueryText);
	
	OpenForm("CommonForm.DoQueryBox", Parameters, , , , , NotifyDescriptionOnCompletion);
	
EndProcedure

// Returns a new structure of additional parameters for the show to User procedure.
//
// Returns:
//  Structure:
//    * DefaultButton             - Arbitrary -  defines the default button by the button type or
//                                                     by its associated value.
//    * Timeout                       - Number        -  the time interval in seconds to automatically close the dialog box
//                                                     question.
//    * TimeoutButton                - Arbitrary -  a button (by button type or by its associated value) 
//                                                     that displays the number of seconds remaining before
//                                                     the timeout expires.
//    * Title                     - String       -  the question title. 
//    * PromptDontAskAgain - Boolean -  if True, the same flag will be available in the question window.
//    * NeverAskAgain    - Boolean       -  takes the value selected by the user in the corresponding
//                                                     checkbox.
//    * LockWholeInterface      - Boolean       -  if True, the question form opens, blocking all
//                                                     other open Windows, including the main window.
//    * Picture                      - Picture     -  image displayed in the question window.
//    * CheckBoxText                   - String       - 
//
Function QuestionToUserParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("DefaultButton", Undefined);
	Parameters.Insert("Timeout", 0);
	Parameters.Insert("TimeoutButton", Undefined);
	Parameters.Insert("Title", ClientApplication.GetCaption());
	Parameters.Insert("PromptDontAskAgain", True);
	Parameters.Insert("NeverAskAgain", False);
	Parameters.Insert("LockWholeInterface", False);
	Parameters.Insert("Picture", PictureLib.DialogQuestion);
	Parameters.Insert("CheckBoxText", "");
	
	Return Parameters;
	
EndFunction	

// Called when you need to open a form for the list of active users
// who are currently working with the system.
//
// Parameters:
//    FormParameters - Structure        - see the description of the parameter Parameters of the Open Form method in the syntax assistant.
//    FormOwner  - ClientApplicationForm - see the description of the Owner parameter of the Open Form method in the syntax Assistant.
//
Procedure OpenActiveUserList(FormParameters = Undefined, FormOwner = Undefined) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.UsersSessions") Then
		
		FormName = "";
		ModuleIBConnectionsClient = CommonClient.CommonModule("IBConnectionsClient");
		ModuleIBConnectionsClient.OnDefineActiveUserForm(FormName);
		OpenForm(FormName, FormParameters, FormOwner);
		
	Else
		
		ShowMessageBox(,
			NStr("en = 'To open the list of active users, on the main menu, click
				       |Functions for technician—Standard—Active users.';"));
		
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.IsBaseConfigurationVersion
Function IsBaseConfigurationVersion() Export
	
	Return ClientParameter("IsBaseConfigurationVersion");
	
EndFunction

// See StandardSubsystemsServer.IsTrainingPlatform
Function IsTrainingPlatform() Export
	
	Return ClientParameter("IsTrainingPlatform");
	
EndFunction

#Region ErrorProcessing

// 
// 
//  
//
// Parameters:
//  ErrorInfo - ErrorInfo
//
// Example:
//	
//	 See TimeConsumingOperationsClient.NewResultLongOperation
//	
//	//
//	
//	
//		
//			
//		
//		
//			
//			
//		
//		
//	
//
Procedure OutputErrorInfo(ErrorInfo) Export
	
	ErrorProcessing.ShowErrorInfo(ErrorInfo);
	
EndProcedure

// 
// 
// 
// 
// 
// 
// 
//
// Parameters:
//  Item - FormField, FormButton - 
//  ErrorInfo  - ErrorInfo - 
//  IsErrorRequiresRestart - Boolean - 
//    
//
// Example:
//	
//	
//	
//	
//	
//	
//	
//		
//			
//			
//			
//				
//		
//	
//	
//	
//		
//			
//		
//	
//	
//	
//	
//	
//		
//	
//	
//
Procedure ConfigureVisibilityAndTitleForURLSendErrorReport(Item, ErrorInfo, IsErrorRequiresRestart = False) Export
	
	Settings = ClientParameter("ErrorInfoSendingSettings");
	CategoryForUser = ErrorProcessing.ErrorCategoryForUser(ErrorInfo);
	
	Item.Visible =
		    Not IsErrorRequiresRestart And CategoryForUser = ErrorCategory.OtherError
		Or Not IsErrorRequiresRestart And CategoryForUser = ErrorCategory.ConfigurationError
		Or    IsErrorRequiresRestart And CategoryForUser <> ErrorCategory.SessionError;
	
	If Settings.SendOutMode = ErrorReportingMode.Send Then
		Item.Title = NStr("en = 'The error report will be sent out automatically.
			|Configure the report…';");
	Else
		Item.Title = NStr("en = 'Generate error report';");
	EndIf;
	
EndProcedure

// 
// 
// 
// 
//
// Parameters:
//  ReportToSend - ErrorReport
//
// Example:
//	
//	
//	
//	
//	
//	
//	
//		
//			
//			
//			
//				
//		
//	
//	
//	
//		
//			
//		
//	
//	
//	
//	
//	
//		
//	
//	
//
Procedure ShowErrorReport(ReportToSend) Export
	
	Settings = ClientParameter("ErrorInfoSendingSettings");
	
	If ValueIsFilled(Settings.SendOutAddress)
	   And Settings.SendOutMode <> ErrorReportingMode.DontSend Then
		
		ReportToSend.Send(True);
	Else
		ReportToSend.Write(, True);
	EndIf;
	
EndProcedure

// 
// 
// 
// 
//
// Parameters:
//  ReportToSend - ErrorReport
//  ErrorInfo  - ErrorInfo - 
//  IsErrorRequiresRestart - Boolean - 
//    
//    
//
// Example:
//	
//	
//	
//	
//	
//	
//	
//		
//			
//			
//			
//				
//		
//	
//	
//	
//		
//			
//		
//	
//	
//	
//	
//	
//		
//	
//	
//
Procedure SendErrorReport(ReportToSend, ErrorInfo, IsErrorRequiresRestart = False) Export
	
	Settings = ClientParameter("ErrorInfoSendingSettings");
	
	If Not ValueIsFilled(Settings.SendOutAddress)
	 Or Settings.SendOutMode <> ErrorReportingMode.Send Then
		Return;
	EndIf;
	
	CategoryForUser = ErrorProcessing.ErrorCategoryForUser(ErrorInfo);
	
	If IsErrorRequiresRestart And CategoryForUser <> ErrorCategory.SessionError
	 Or Not IsErrorRequiresRestart
	   And (    CategoryForUser = ErrorCategory.OtherError
	      Or CategoryForUser = ErrorCategory.ConfigurationError) Then
		
		ReportToSend.Send(False);
	EndIf;
	
EndProcedure

#EndRegion

#Region ApplicationEventsProcessing

// Disables issuing a warning to the user when the program is shut down.
//
Procedure SkipExitConfirmation() Export
	
	ApplicationParameters.Insert("StandardSubsystems.SkipExitConfirmation", True);
	
EndProcedure

// Perform standard actions before the user starts working
// with the data area, or in local mode.
//
// It is intended for calling modules of a managed and normal application from the handler before starting work.
//
// Parameters:
//  CompletionNotification - NotifyDescription -  
//                         
//                         :
//                         
//                         
//                         
//                         
//
Procedure BeforeStart(Val CompletionNotification = Undefined) Export
	
	BeginTime = CurrentUniversalDateInMilliseconds();
	
	If ApplicationParameters = Undefined Then
		ApplicationParameters = New Map;
	EndIf;
	
	ApplicationParameters.Insert("StandardSubsystems.PerformanceMonitor.StartTime1", BeginTime);
	
	If CompletionNotification <> Undefined Then
		CommonClientServer.CheckParameter("StandardSubsystemsClient.BeforeStart", 
			"CompletionNotification", CompletionNotification, Type("NotifyDescription"));
	EndIf;
	
	SignInToDataArea();
	
	ActionsBeforeStart(CompletionNotification);
	
	If Not ApplicationStartupLogicDisabled()
	   And Not CommonClient.SubsystemExists("OnlineUserSupport.CoreISL") Then
		Return;
	EndIf;
	
	Try
		ModuleOnlineUserSupportClientServer =
			CommonClient.CommonModule("OnlineUserSupportClientServer");
	Except
		If ApplicationStartupLogicDisabled() Then
			Return;
		EndIf;
		Raise;
	EndTry;
	
	ISLVersion = ModuleOnlineUserSupportClientServer.LibraryVersion();
	// 
	// 
	If CommonClientServer.CompareVersions(ISLVersion, "2.7.1.0") > 0 Then
		ModuleLicensingClientClient = CommonClient.CommonModule("LicensingClientClient");
		ModuleLicensingClientClient.AttachLicensingClientSettingsRequest();
	EndIf;
	
EndProcedure

// To perform a standard action at the beginning of the user experience
// with a data region or in a local mode.
//
// It is intended for calling modules of a managed and normal application from the handler at the beginning of the Worksystem.
//
// Parameters:
//  CompletionNotification - NotifyDescription -  
//                         
//                         :
//                         
//                         
//                         
//                         
//
//  ContinuousExecution - Boolean -  for internal use only.
//                          To switch from the handler before starting the system Operation
//                          performed in interactive processing mode.
//
Procedure OnStart(Val CompletionNotification = Undefined, ContinuousExecution = True) Export
	
	If InteractiveHandlerBeforeStartInProgress() Then
		Return;
	EndIf;
	
	If ApplicationStartupLogicDisabled() Then
		Return;
	EndIf;
	
	If CompletionNotification <> Undefined Then
		CommonClientServer.CheckParameter("StandardSubsystemsClient.OnStart", 
			"CompletionNotification", CompletionNotification, Type("NotifyDescription"));
	EndIf;
	CommonClientServer.CheckParameter("StandardSubsystemsClient.OnStart", 
		"ContinuousExecution", ContinuousExecution, Type("Boolean"));
	
	ActionsOnStart(CompletionNotification, ContinuousExecution);
	
EndProcedure

// Perform standard actions before the user finishes working
// with the data area, or in local mode.
//
// It is intended for calling modules of a managed and normal application from the handler before completing the work Of the system.
//
// Parameters:
//  Cancel                - Boolean -  returned value. Indicates 
//                         that the event handler for the system's pre-Completion event failed, either programmatically failed,
//                         or that interactive processing was required. If the user interaction is successful
//                         , the shutdown will continue.
//  WarningText  - String - See BeforeExit
//                                  
//
Procedure BeforeExit(Cancel = False, WarningText = "") Export
	
	If Not DisplayWarningsBeforeShuttingDownTheSystem(Cancel) Then
		Return;
	EndIf;
	
	Warnings = WarningsBeforeSystemShutdown(Cancel);
	If Warnings.Count() = 0 Then
		If Not ClientParameter("AskConfirmationOnExit") Then
			Return;
		EndIf;
		WarningText = NStr("en = 'Exit the app?';");
		Cancel = True;
	Else
		Cancel = True;
		WarningArray = New Array;
		For Each Warning In Warnings Do
			WarningArray.Add(Warning.WarningText);
		EndDo;
		If Not IsBlankString(WarningText) Then
			WarningText = WarningText + Chars.LF;
		EndIf;
		WarningArray.Add(Chars.LF);
		WarningArray.Add(NStr("en = 'To do so, select ""Continue"" and click the pop-up notification.';"));
		WarningText = WarningText + StrConcat(WarningArray, Chars.LF);
		
		AttachIdleHandler("ShowExitWarning", 0.1, True);
	EndIf;
	SetClientParameter("ExitWarnings", Warnings);
	
EndProcedure

// 
//
// Parameters:
//  ChoicePurpose - CollaborationSystemUsersChoicePurpose
//  Form - ClientApplicationForm
//  ConversationID - CollaborationSystemConversationID
//  Parameters - Structure
//  SelectedForm - String
//  StandardProcessing - Boolean
//
Procedure CollaborationSystemUsersChoiceFormGetProcessing(ChoicePurpose,
			Form, ConversationID, Parameters, SelectedForm, StandardProcessing) Export
	
	// 
	If CommonClient.SubsystemExists("StandardSubsystems.Conversations") Then
		ModuleConversationsInternalClient = CommonClient.CommonModule("ConversationsInternalClient");
		ModuleConversationsInternalClient.OnGetCollaborationSystemUsersChoiceForm(ChoicePurpose,
			Form, ConversationID, Parameters, SelectedForm, StandardProcessing);
	EndIf;
	// End StandardSubsystems.Conversations
		
EndProcedure

// Returns a new parameter structure for displaying a warning before the program terminates.
// For General use, the client is Undefined.Before completing the system operation.
//
// Returns:
//  Structure:
//    
//                                    
//                                    
//                                    
//     
//                                    
//    
//                                    
//    
//                                    
//    
//                                     
//                                    
//    
//    
//                                         
//    
//      * Form          - String    - 
//                                     
//      * FormParameters - Structure -  
//    :
//      * Form          - String    -  path to the form that should be opened by clicking on the hyperlink.
//                                     For Example, " Processing.Files.Editable files".
//      * FormParameters - Structure -  custom structure of parameters for the form to open.
//      * ApplicationWarningForm - String -  the path to the form that should open immediately
//                                        instead of the universal form if 
//                                        only one given warning appears in the list of warnings.
//                                        For Example, " Processing.Files.Editable files".
//      * ApplicationWarningFormParameters - Structure -  custom
//                                                 parameter structure for the form described above.
//      * WindowOpeningMode - FormWindowOpeningMode -  mode for opening forms Form or Applicationformreferences.
// 
Function WarningOnExit() Export
	
	ActionIfFlagSet = New Structure;
	ActionIfFlagSet.Insert("Form", "");
	ActionIfFlagSet.Insert("FormParameters", Undefined);
	
	ActionOnClickHyperlink = New Structure;
	ActionOnClickHyperlink.Insert("Form", "");
	ActionOnClickHyperlink.Insert("FormParameters", Undefined);
	ActionOnClickHyperlink.Insert("ApplicationWarningForm", "");
	ActionOnClickHyperlink.Insert("ApplicationWarningFormParameters", Undefined);
	ActionOnClickHyperlink.Insert("WindowOpeningMode", Undefined);
	
	WarningParameters = New Structure;
	WarningParameters.Insert("CheckBoxText", "");
	WarningParameters.Insert("NoteText", "");
	WarningParameters.Insert("WarningText", "");
	WarningParameters.Insert("ExtendedTooltip", "");
	WarningParameters.Insert("HyperlinkText", "");
	WarningParameters.Insert("ActionIfFlagSet", ActionIfFlagSet);
	WarningParameters.Insert("ActionOnClickHyperlink", ActionOnClickHyperlink);
	WarningParameters.Insert("Priority", 0);
	WarningParameters.Insert("OutputSingleWarning", False);
	
	Return WarningParameters;
	
EndFunction

// Returns the values of parameters required for the client code
// to work when running the configuration in a single server call (to minimize client-server interaction
// and reduce startup time). 
// You can use this function to access parameters in client code that are called from event handlers:
// - Before the system operation starts,
// - At the beginning of the system's work.
//
// In these handlers, you can't use commands to reset the cache
// of reusable modules at startup, otherwise running them can lead
// to unpredictable errors and unnecessary server calls.
// 
// Returns:
//   FixedStructure -  
//                            
//
//
Function ClientParametersOnStart() Export
	
	Return StandardSubsystemsClientCached.ClientParametersOnStart();
	
EndFunction

// Returns the values of parameters required for the client configuration code
// to work without additional server calls.
// 
// Returns:
//   FixedStructure - 
//                            
//
Function ClientRunParameters() Export
	
	Return StandardSubsystemsClientCached.ClientRunParameters();
	
EndFunction

#EndRegion

#Region ForCallsFromOtherSubsystems

// 
// 
// 
// 
// Parameters:
//  NameOfAlert - See ServerNotifications.SendServerNotification.NameOfAlert
//  Result     - See ServerNotifications.SendServerNotification.Result
//
// Example:
//	
//		
//	
//	
//		
//	
//		
//	
//
Procedure OnReceiptServerNotification(NameOfAlert, Result) Export
	
	If NameOfAlert = "StandardSubsystems.Core.FunctionalOptionsModified" Then
		DetachIdleHandler("RefreshInterfaceOnFunctionalOptionToggle");
		AttachIdleHandler("RefreshInterfaceOnFunctionalOptionToggle", 5*60, True);
		
	ElsIf NameOfAlert = "StandardSubsystems.Core.CachedValuesOutdated" Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Function ApplicationStartCompleted() Export
	
	ParameterName = "StandardSubsystems.ApplicationStartCompleted";
	If ApplicationParameters[ParameterName] = True Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function ClientParameter(ParameterName = Undefined) Export
	
	GlobalParameterName = "StandardSubsystems.ClientParameters";
	ClientParameters = ApplicationParameters[GlobalParameterName];
	
	If ClientParameters = Undefined Then
		// 
		StandardSubsystemsClientCached.ClientParametersOnStart();
		ClientParameters = ApplicationParameters[GlobalParameterName];
	EndIf;
	
	If ParameterName = Undefined Then
		Return ClientParameters;
	Else
		Return ClientParameters[ParameterName];
	EndIf;
	
EndFunction

Procedure SetClientParameter(ParameterName, Value) Export
	GlobalParameterName = "StandardSubsystems.ClientParameters";
	ApplicationParameters[GlobalParameterName].Insert(ParameterName, Value);
EndProcedure

Procedure FillClientParameters(ClientParameters) Export
	
	ParameterName = "StandardSubsystems.ClientParameters";
	If TypeOf(ApplicationParameters[ParameterName]) <> Type("Structure") Then
		ApplicationParameters[ParameterName] = New Structure;
		ApplicationParameters[ParameterName].Insert("DataSeparationEnabled");
		ApplicationParameters[ParameterName].Insert("FileInfobase");
		ApplicationParameters[ParameterName].Insert("IsBaseConfigurationVersion");
		ApplicationParameters[ParameterName].Insert("IsTrainingPlatform");
		ApplicationParameters[ParameterName].Insert("IsExternalUserSession");
		ApplicationParameters[ParameterName].Insert("IsFullUser");
		ApplicationParameters[ParameterName].Insert("IsSystemAdministrator");
		ApplicationParameters[ParameterName].Insert("AuthorizedUser");
		ApplicationParameters[ParameterName].Insert("AskConfirmationOnExit");
		ApplicationParameters[ParameterName].Insert("SeparatedDataUsageAvailable");
		ApplicationParameters[ParameterName].Insert("StandaloneModeParameters");
		ApplicationParameters[ParameterName].Insert("PersonalFilesOperationsSettings");
		ApplicationParameters[ParameterName].Insert("LockedFilesCount");
		ApplicationParameters[ParameterName].Insert("IBBackupOnExit");
		ApplicationParameters[ParameterName].Insert("DisplayPermissionSetupAssistant");
		ApplicationParameters[ParameterName].Insert("SessionTimeOffset");
		ApplicationParameters[ParameterName].Insert("UniversalTimeCorrection");
		ApplicationParameters[ParameterName].Insert("StandardTimeOffset");
		ApplicationParameters[ParameterName].Insert("ClientDateOffset");
		ApplicationParameters[ParameterName].Insert("DefaultLanguageCode");
		ApplicationParameters[ParameterName].Insert("ErrorInfoSendingSettings");
	EndIf;
	If Not ApplicationParameters[ParameterName].Property("PerformanceMonitor")
	   And ClientParameters.Property("PerformanceMonitor") Then
		ApplicationParameters[ParameterName].Insert("PerformanceMonitor");
	EndIf;
	
	FillPropertyValues(ApplicationParameters[ParameterName], ClientParameters);
	
EndProcedure

// After the warning, calls the procedure with the parameters Result, additional Parameters.
//
// Parameters:
//  Parameters           - Structure - :
//                          
//                          
//                            
//
//  WarningDetails - Undefined - 
//  
//  :
//       * WarningText - String -  the alert text that you want to show.
//       * Buttons              - ValueList -  for the procedure show to the User.
//       * QuestionParameters    - Structure -  contains a subset of properties
//                                 to be redefined from the number
//                                 returned by the function to the user parameter.
//
Procedure ShowMessageBoxAndContinue(Parameters, WarningDetails) Export
	
	NotificationWithResult = Parameters.ContinuationHandler;
	
	If WarningDetails = Undefined Then
		ExecuteNotifyProcessing(NotificationWithResult);
		Return;
	EndIf;
	
	Buttons = New ValueList;
	QuestionParameters = QuestionToUserParameters();
	QuestionParameters.PromptDontAskAgain = False;
	QuestionParameters.LockWholeInterface = True;
	QuestionParameters.Picture = PictureLib.DialogExclamation;
	
	If Parameters.Cancel Then
		Buttons.Add("ExitApp", NStr("en = 'End session';"));
		QuestionParameters.DefaultButton = "ExitApp";
	Else
		Buttons.Add("Continue", NStr("en = 'Continue';"));
		Buttons.Add("ExitApp",  NStr("en = 'End session';"));
		QuestionParameters.DefaultButton = "Continue";
	EndIf;
	
	If TypeOf(WarningDetails) = Type("Structure") Then
		WarningText = WarningDetails.WarningText;
		Buttons = WarningDetails.Buttons;
		FillPropertyValues(QuestionParameters, WarningDetails.QuestionParameters);
	Else
		WarningText = WarningDetails;
	EndIf;
	
	ClosingNotification1 = New NotifyDescription("ShowMessageBoxAndContinueCompletion", ThisObject, Parameters);
	ShowQuestionToUser(ClosingNotification1, WarningText, Buttons, QuestionParameters);
	
EndProcedure

// Returns the name of the executable file depending on the client type.
//
// Returns:
//  String
//
Function ApplicationExecutableFileName(GetDesignerFileName = False) Export
	
	FileNameTemplate = "1cv8[TrainingPlatform].exe";
	
#If ThinClient Then
	If Not GetDesignerFileName Then
		FileNameTemplate = "1cv8c[TrainingPlatform].exe";
	EndIf;	
#EndIf
	
	Return StrReplace(FileNameTemplate, "[TrainingPlatform]", ?(IsTrainingPlatform(), "t", ""));
	
EndFunction

// Sets / disables storing a reference to a managed form in a global variable.
// Required for cases when the form reference is passed through additional
// Parameters in the message Description object, which does not block the release of a closed form.
//
Procedure SetFormStorageOption(Form, Location) Export
	
	Store = ApplicationParameters["StandardSubsystems.TemporaryManagedFormsRefStorage"];
	If Store = Undefined Then
		Store = New Map;
		ApplicationParameters.Insert("StandardSubsystems.TemporaryManagedFormsRefStorage", Store);
	EndIf;
	
	If Location Then
		Store.Insert(Form, New Structure("Form", Form));
	ElsIf Store.Get(Form) <> Undefined Then
		Store.Delete(Form);
	EndIf;
	
EndProcedure

// Checks that the current data is defined and is not a grouping.
// It is intended for table handlers of the dynamic list form.
//
// Parameters:
//  TableOrCurrentData - FormTable -  table of the dynamic list form for checking current data.
//                          - Undefined
//                          - FormDataStructure
//                          - Structure - 
//
// Returns:
//  Boolean
//
Function IsDynamicListItem(TableOrCurrentData) Export
	
	If TypeOf(TableOrCurrentData) = Type("FormTable") Then
		CurrentData = TableOrCurrentData.CurrentData;
	Else
		CurrentData = TableOrCurrentData;
	EndIf;
	
	If TypeOf(CurrentData) <> Type("FormDataStructure")
	   And TypeOf(CurrentData) <> Type("Structure") Then
		Return False;
	EndIf;
	
	If CurrentData.Property("RowGroup") Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Checks whether startup procedures have been dangerously disabled for automatic testing purposes.
//
// Returns:
//  Boolean
//
Function ApplicationStartupLogicDisabled() Export
	Return StrFind(LaunchParameter, "DisableSystemStartupLogic") > 0;
EndFunction

// 
//
// Returns:
//  Structure:
//   * Key - String - 
//   * Value - MetadataObjectStyleItem
//
Function StyleItems() Export
	
	StyleItems = New Structure;
	
	ClientRunParameters = ClientRunParameters();
	For Each StyleItem In ClientRunParameters.StyleItems Do
#If ThickClientOrdinaryApplication Then
		StyleItems.Insert(StyleItem.Key, StyleItem.Value.Get());
#Else
		StyleItems.Insert(StyleItem.Key, StyleItem.Value);
#EndIf
	EndDo;
	
	Return StyleItems;
	
EndFunction

// Redirects an alert with no result to an alert with a result.
//
// Returns:
//  NotifyDescription
//
Function NotificationWithoutResult(NotificationWithResult) Export
	
	Return New NotifyDescription("NotifyWithEmptyResult", ThisObject, NotificationWithResult);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// See SSLSubsystemsIntegrationClient.BeforeRecurringClientDataSendToServer
Procedure BeforeRecurringClientDataSendToServer(Parameters) Export
	
	ParameterName = "StandardSubsystems.Core.DynamicUpdateControl";
	If Not ServerNotificationsClient.TimeoutExpired(ParameterName) Then
		Return;
	EndIf;
	
	// ConfigurationOrExtensionsWasModified
	Parameters.Insert(ParameterName, True);
	
EndProcedure

// See CommonClientOverridable.AfterRecurringReceiptOfClientDataOnServer
Procedure AfterRecurringReceiptOfClientDataOnServer(Results) Export
	
	ParameterName = "StandardSubsystems.Core.DynamicUpdateControl";
	Result = Results.Get(ParameterName);
	If Result = Undefined Then
		Return;
	EndIf;
	
	// ConfigurationOrExtensionsWasModified
	PictureDialogInformation = PictureLib.DialogInformation;
	ShowUserNotification(
		NStr("en = 'Application update installed';"),
		"e1cib/app/CommonForm.DynamicUpdateControl",
		Result, PictureDialogInformation,
		UserNotificationStatus.Important,
		"TheProgramUpdateIsInstalled");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Expands the nodes of the specified tree on the form.
//
// Parameters:
//   Form                     - ClientApplicationForm -  the form where the control with the value tree is placed.
//   FormItemName          - String           -  name of the element with the form table (value tree) and associated
//                                                  form details (must match).
//   TreeRowID - Arbitrary     -  the row ID of the tree that you want to deploy.
//                                                  If " * " is specified, all top-level nodes will be expanded.
//                                                  If Undefined is specified, then the rows of the tree will not be deployed.
//                                                  The default value is "*".
//   ExpandWithSubordinates   - Boolean           -  if True, then all subordinate nodes should also be disclosed.
//                                                  False by default.
//
Procedure ExpandTreeNodes(Form, FormItemName, TreeRowID = "*", ExpandWithSubordinates = False) Export
	
	TableItem = Form.Items[FormItemName];
	If TreeRowID = "*" Then
		Nodes = Form[FormItemName].GetItems();
		For Each Node In Nodes Do
			TableItem.Expand(Node.GetID(), ExpandWithSubordinates);
		EndDo;
	Else
		TableItem.Expand(TreeRowID, ExpandWithSubordinates);
	EndIf;
	
EndProcedure

// Notifies open forms and dynamic lists of mass changes to objects of various types
// using the Notify and notify Change global context methods.
//
// Parameters:
//  ModifiedObjectTypes - See StandardSubsystemsServer.PrepareFormChangeNotification
//  FormNotificationParameter - Arbitrary -  message parameter for the Notify method.
//
Procedure NotifyFormsAboutChange(ModifiedObjectTypes, FormNotificationParameter = Undefined) Export
	
	For Each ObjectType In ModifiedObjectTypes Do
		Notify(ObjectType.Value.EventName, 
			?(FormNotificationParameter <> Undefined, FormNotificationParameter, New Structure), 
			ObjectType.Value.EmptyRef);
		NotifyChanged(ObjectType.Key);
	EndDo;
	
EndProcedure

// Opens the object list form with positioning on the object.
//
// Parameters:
//   Ref - AnyRef -  the object that you want to show in the list.
//   ListFormName - String -  name of the list form.
//       If the value is Undefined, it will be determined automatically (you will need to call the server).
//   FormParameters - Structure -  additional parameters for opening the list form.
//
Procedure ShowInList(Ref, ListFormName, FormParameters = Undefined) Export
	If Ref = Undefined Then
		Return;
	EndIf;
	
	If ListFormName = Undefined Then
		FullName = StandardSubsystemsServerCall.FullMetadataObjectName(TypeOf(Ref));
		If FullName = Undefined Then
			Return;
		EndIf;
		ListFormName = FullName + ".ListForm";
	EndIf;
	
	If FormParameters = Undefined Then
		FormParameters = New Structure;
	EndIf;
	
	FormParameters.Insert("CurrentRow", Ref);
	
	Form = GetForm(ListFormName, FormParameters, , True);
	Form.Open();
	Form.ExecuteNavigation(Ref);
EndProcedure

// Displays text that the user can copy.
//
// Parameters:
//   Handler - NotifyDescription -  description of the procedure that will be called after the display is completed.
//       The return value is similar to show to the User().
//   Text     - String -  text of information.
//   Title - String -  the title of the window. By default, "Learn more".
//
Procedure ShowDetailedInfo(Handler, Text, Title = Undefined) Export
	DialogSettings = New Structure;
	DialogSettings.Insert("PromptDontAskAgain", False);
	DialogSettings.Insert("Picture", Undefined);
	DialogSettings.Insert("ShowPicture", False);
	DialogSettings.Insert("CanCopy", True);
	DialogSettings.Insert("DefaultButton", 0);
	DialogSettings.Insert("HighlightDefaultButton", False);
	DialogSettings.Insert("Title", Title);
	
	If Not ValueIsFilled(DialogSettings.Title) Then
		DialogSettings.Title = NStr("en = 'Details';");
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add(0, NStr("en = 'Close';"));
	
	ShowQuestionToUser(Handler, Text, Buttons, DialogSettings);
EndProcedure

// Header of the file for technical support.
//
// Returns:
//  String
//
Function SupportInformation() Export
	
	Text = NStr("en = '[ApplicationName1], [ApplicationVersion]
	                   |1C:Enterprise: [PlatformVersion] [PlatformBitness]
	                   |Standard Subsystem Library: [SSLVersion]
	                   |App: [Viewer]
	                   |OS: [OperatingSystem]
	                   |RAM: [RAM]
	                   |COM connector: [COMConnectorName]
	                   |Basic configuration: [IsBaseConfigurationVersion]
	                   |Full-access user: [IsFullUser]
	                   |Sandbox: [IsTrainingPlatform]
	                   |Configuration modified: [ConfigurationChanged]';") + Chars.LF;
	
	Parameters = ?(ApplicationStartCompleted(), ClientRunParameters(), ClientParametersOnStart());
	SystemInfo = New SystemInfo;
	TextUnavailable = NStr("en = 'unavailable';");
	
	Text = StrReplace(Text, "[ApplicationName1]", 
		?(Parameters.Property("DetailedInformation"), Parameters.DetailedInformation, TextUnavailable));
	Text = StrReplace(Text, "[ApplicationVersion]", 
		?(Parameters.Property("ConfigurationVersion"), Parameters.ConfigurationVersion, TextUnavailable));
	Text = StrReplace(Text, "[PlatformVersion]", SystemInfo.AppVersion);
	Text = StrReplace(Text, "[PlatformBitness]", SystemInfo.PlatformType);
	Text = StrReplace(Text, "[SSLVersion]", StandardSubsystemsServerCall.LibraryVersion());
	Text = StrReplace(Text, "[Viewer]", SystemInfo.UserAgentInformation);
	Text = StrReplace(Text, "[OperatingSystem]", SystemInfo.OSVersion);
	Text = StrReplace(Text, "[RAM]", SystemInfo.RAM);
	Text = StrReplace(Text, "[COMConnectorName]", CommonClientServer.COMConnectorName());
	Text = StrReplace(Text, "[IsBaseConfigurationVersion]", IsBaseConfigurationVersion());
	Text = StrReplace(Text, "[IsFullUser]", UsersClient.IsFullUser());
	Text = StrReplace(Text, "[IsTrainingPlatform]", IsTrainingPlatform());
	Text = StrReplace(Text, "[ConfigurationChanged]", 
		?(Parameters.Property("SettingsOfUpdate"), Parameters.SettingsOfUpdate.ConfigurationChanged, TextUnavailable));
	
	Return Text;
	
EndFunction

#If Not WebClient And Not MobileClient Then

// Directory of system applications, for example, "C:\Windows\System32".
// Used only in Windows OS.
//
// Returns:
//  String
//
Function SystemApplicationsDirectory() Export
	
	ShellObject = New COMObject("Shell.Application");
	
	SystemInfo = New SystemInfo;
	If SystemInfo.PlatformType = PlatformType.Windows_x86 Then 
		// 
		// 
		FolderObject = ShellObject.Namespace(41);
	ElsIf SystemInfo.PlatformType = PlatformType.Windows_x86_64 Then 
		// 
		FolderObject = ShellObject.Namespace(37);
	EndIf;
	
	Return FolderObject.Self.Path + "\";
	
EndFunction

#EndIf

// 
// 
// 
// 
// 
// Parameters:
//  NotifyDescription - NotifyDescription - 
//  Result  - Arbitrary - 
//               
//
Procedure StartNotificationProcessing(NotifyDescription, Result = Undefined) Export
	
	Context = New Structure;
	Context.Insert("Notification", NotifyDescription);
	Context.Insert("Result", Result);
	
	Stream = New MemoryStream;
	Stream.BeginGetSize(New NotifyDescription(
		"StartNotificationProcessingCompletion", ThisObject, Context));
	
EndProcedure

// 
// 
// Parameters:
//  FormParameters - See StandardSubsystemsClientServer.MetadataObjectsSelectionParameters
//  OnCloseNotifyDescription - NotifyDescription - : 
//			
//				 
//			 
//		 
//		
//			
//			
//			
//
Procedure ChooseMetadataObjects(FormParameters, OnCloseNotifyDescription = Undefined) Export
	OpenForm("CommonForm.SelectMetadataObjects", FormParameters,,,,, OnCloseNotifyDescription);
EndProcedure

// 
//  
// 
//	
//	
//	  
//	  
//	
// 
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - 
//  FormParameters - See StandardSubsystemsClient.SpreadsheetEditorParameters
//
Procedure ShowSpreadsheetEditor(Val SpreadsheetDocument, Val FormParameters = Undefined, 
	Val OnCloseNotifyDescription = Undefined, Owner = Undefined) Export
	
	If FormParameters = Undefined Then
		FormParameters = SpreadsheetEditorParameters();
	EndIf;
	FormParameters.SpreadsheetDocument = SpreadsheetDocument;
	
	OpenForm("CommonForm.EditSpreadsheetDocument", FormParameters, Owner);
	
EndProcedure

// 
// 
// Returns:
//  Structure:
//   * DocumentName - String -  
//   * SpreadsheetDocument - SpreadsheetDocument, String - 
//                         
//   * PathToFile - String - 
//   * Edit - Boolean - 
//
Function SpreadsheetEditorParameters() Export
	
	Result = New Structure;
	Result.Insert("DocumentName", "");
	Result.Insert("SpreadsheetDocument", Undefined);
	Result.Insert("PathToFile", "");
	Result.Insert("Edit", False);
	Return Result;
	
EndFunction

// 
// 
// Parameters:
//  SpreadsheetDocumentLeft - SpreadsheetDocument - 
//  SpreadsheetDocumentRight - SpreadsheetDocument - 
//  Parameters - See SpreadsheetComparisonParameters
//
Procedure ShowSpreadsheetComparison(SpreadsheetDocumentLeft, SpreadsheetDocumentRight, Parameters) Export
	
	If SpreadsheetDocumentLeft <> Undefined Then
		FormParameters = SpreadsheetComparisonParameters();
		CommonClientServer.SupplementStructure(FormParameters, Parameters, True);
		ComparableDocuments = New Structure("Left_1, Right", SpreadsheetDocumentLeft, SpreadsheetDocumentRight);
		FormParameters.SpreadsheetDocumentsAddress = PutToTempStorage(ComparableDocuments, Undefined);
	Else
		FormParameters = Parameters;
	EndIf;
	OpenForm("CommonForm.CompareSpreadsheetDocuments", FormParameters);
	
EndProcedure

// 
// 
// Returns:
//  Structure:
//    * SpreadsheetDocumentsAddress - String - 
//    * Title - String - 
//    * TitleLeft - String - 
//    * TitleRight - String - 
//
Function SpreadsheetComparisonParameters() Export
	
	Result = New Structure;
	Result.Insert("SpreadsheetDocumentsAddress", "");
	Result.Insert("Title", "");
	Result.Insert("TitleLeft", "");
	Result.Insert("TitleRight", "");
	Return Result;
	
EndFunction

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// BeforeStart

// 
Procedure ActionsBeforeStart(CompletionNotification)
	
	Parameters = ProcessingParametersBeforeStartSystem();
	
	// 
	Parameters.Insert("Cancel", False);
	Parameters.Insert("Restart", False);
	Parameters.Insert("AdditionalParametersOfCommandLine", "");
	
	// 
	Parameters.Insert("InteractiveHandler", Undefined); // NotifyDescription
	Parameters.Insert("ContinuationHandler",   Undefined); // NotifyDescription
	Parameters.Insert("ContinuousExecution", True);
	Parameters.Insert("RetrievedClientParameters", New Structure);
	Parameters.Insert("ModuleOfLastProcedure", "");
	Parameters.Insert("NameOfLastProcedure", "");
	InstallLatestProcedure(Parameters, "StandardSubsystemsClient", "BeforeStart");
	
	// 
	Parameters.Insert("CompletionNotification", CompletionNotification);
	Parameters.Insert("CompletionProcessing", New NotifyDescription(
		"ActionsBeforeStartCompletionHandler", ThisObject));
	
	UpdateClientParameters(Parameters, True, CompletionNotification <> Undefined);
	
	// 
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsBeforeStartInIntegrationProcedure", ThisObject));
	
	If ApplicationStartupLogicDisabled() Then
		Try
			// 
			ClientProperties = New Structure;
			FillInTheClientParametersOnTheServer(ClientProperties);
			StandardSubsystemsServerCall.CheckDisableStartupLogicRight(ClientProperties);
			If ClientProperties.Property("ErrorThereIsNoRightToDisableTheSystemStartupLogic") Then
				UsersInternalClient.InstallInteractiveDataProcessorOnInsufficientRightsToSignInError(
					Parameters, ClientProperties.ErrorThereIsNoRightToDisableTheSystemStartupLogic);
			EndIf;
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			StandardSubsystemsServerCall.WriteErrorToEventLogOnStartOrExit(
				False, "Run", ErrorText);
			UsersInternalClient.InstallInteractiveDataProcessorOnInsufficientRightsToSignInError(
				Parameters, ErrorText);
		EndTry;
		If BeforeStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
		HideDesktopOnStart(True, True);
		Return;
	EndIf;
	
	// 
	// 
	Try
		CommonClient.SubsystemExists("StandardSubsystems.Core");
	Except
		HandleErrorBeforeStart(Parameters, ErrorInfo(), True);
	EndTry;
	If BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continue the procedure before starting the system.
Procedure ActionsBeforeStartInIntegrationProcedure(NotDefined, Context) Export
	
	Parameters = ProcessingParametersBeforeStartSystem();
	InstallLatestProcedure(Parameters, "StandardSubsystemsClient",
		"ActionsBeforeStartInIntegrationProcedure");
	
	If Not ContinueActionsBeforeStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsBeforeStartInIntegrationProcedureModules", ThisObject));
	
	Parameters.Insert("CurrentModuleIndex", 0);
	Parameters.Insert("AddedModules", New Array);
	Try
		Parameters.Insert("Modules", New Array);
		SSLSubsystemsIntegrationClient.BeforeStart(Parameters);
		Parameters.Insert("AddedModules", Parameters.Modules);
		Parameters.Delete("Modules");
	Except
		HandleErrorBeforeStart(Parameters, ErrorInfo(), True);
	EndTry;
	If BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continue the procedure before starting the system.
Procedure ActionsBeforeStartInIntegrationProcedureModules(NotDefined, Context) Export
	
	While True Do
		
		Parameters = ProcessingParametersBeforeStartSystem();
		InstallLatestProcedure(Parameters, "StandardSubsystemsClient",
			"ActionsBeforeStartInIntegrationProcedureModules");
		
		If Not ContinueActionsBeforeStart(Parameters) Then
			Return;
		EndIf;
		
		If Parameters.CurrentModuleIndex >= Parameters.AddedModules.Count() Then
			ActionsBeforeStartInOverridableProcedure(Undefined, Undefined);
			Return;
		EndIf;
	
		ModuleDetails = Parameters.AddedModules[Parameters.CurrentModuleIndex];
		Parameters.CurrentModuleIndex = Parameters.CurrentModuleIndex + 1;
		
		Try
			If TypeOf(ModuleDetails) <> Type("Structure") Then
				CurrentModule = ModuleDetails;
				CurrentModule.BeforeStart(Parameters);
			Else
				CurrentModule = ModuleDetails.Module;
				If ModuleDetails.Number = 2 Then
					CurrentModule.BeforeStart2(Parameters);
				ElsIf ModuleDetails.Number = 3 Then
					CurrentModule.BeforeStart3(Parameters);
				ElsIf ModuleDetails.Number = 4 Then
					CurrentModule.BeforeStart4(Parameters);
				ElsIf ModuleDetails.Number = 5 Then
					CurrentModule.BeforeStart5(Parameters);
				EndIf;
			EndIf;
		Except
			HandleErrorBeforeStart(Parameters, ErrorInfo(), True);
		EndTry;
		If BeforeStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use only. Continue the procedure before starting the system.
Procedure ActionsBeforeStartInOverridableProcedure(NotDefined, Context)
	
	Parameters = ProcessingParametersBeforeStartSystem();
	InstallLatestProcedure(Parameters, "StandardSubsystemsClient",
		"ActionsBeforeStartInOverridableProcedure");
	
	If Not ContinueActionsBeforeStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsBeforeStartInOverridableProcedureModules", ThisObject));
	
	Parameters.InteractiveHandler = Undefined;
	
	Parameters.Insert("CurrentModuleIndex", 0);
	Parameters.Insert("AddedModules", New Array);
	
	If CommonClient.SeparatedDataUsageAvailable() Then
		Try
			Parameters.Insert("Modules", New Array);
			CommonClientOverridable.BeforeStart(Parameters);
			Parameters.Insert("AddedModules", Parameters.Modules);
			Parameters.Delete("Modules");
		Except
			HandleErrorBeforeStart(Parameters, ErrorInfo());
		EndTry;
		If BeforeStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continue the procedure before starting the system.
Procedure ActionsBeforeStartInOverridableProcedureModules(NotDefined, Context) Export
	
	While True Do
		
		Parameters = ProcessingParametersBeforeStartSystem();
		InstallLatestProcedure(Parameters, "StandardSubsystemsClient",
			"ActionsBeforeStartInOverridableProcedureModules");
		
		If Not ContinueActionsBeforeStart(Parameters) Then
			Return;
		EndIf;
		
		If Parameters.CurrentModuleIndex >= Parameters.AddedModules.Count() Then
			ActionsBeforeStartAfterAllProcedures(Undefined, Undefined);
			Return;
		EndIf;
		
		CurrentModule = Parameters.AddedModules[Parameters.CurrentModuleIndex];
		Parameters.CurrentModuleIndex = Parameters.CurrentModuleIndex + 1;
		
		Try
			CurrentModule.BeforeStart(Parameters);
		Except
			HandleErrorBeforeStart(Parameters, ErrorInfo());
		EndTry;
		If BeforeStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use only. Continue the procedure before starting the system.
Procedure ActionsBeforeStartAfterAllProcedures(NotDefined, Context)
	
	Parameters = ProcessingParametersBeforeStartSystem();
	InstallLatestProcedure(Parameters, "StandardSubsystemsClient",
		"ActionsBeforeStartAfterAllProcedures");
	
	If Not ContinueActionsBeforeStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", Parameters.CompletionProcessing);
	
	Try
		SetInterfaceFunctionalOptionParametersOnStart();
	Except
		HandleErrorBeforeStart(Parameters, ErrorInfo(), True);
	EndTry;
	If BeforeStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Completing the procedure before starting the system.
Procedure ActionsBeforeStartCompletionHandler(NotDefined, Context) Export
	
	Parameters = ProcessingParametersBeforeStartSystem(True);
	
	Parameters.ContinuationHandler = Undefined;
	Parameters.CompletionProcessing  = Undefined;
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	ApplicationStartParameters.Delete("RetrievedClientParameters");
	ApplicationParameters["StandardSubsystems.ApplicationStartCompleted"] = True;
	
	If Parameters.CompletionNotification <> Undefined Then
		Result = New Structure;
		Result.Insert("Cancel", Parameters.Cancel);
		Result.Insert("Restart", Parameters.Restart);
		Result.Insert("AdditionalParametersOfCommandLine", Parameters.AdditionalParametersOfCommandLine);
		ExecuteNotifyProcessing(Parameters.CompletionNotification, Result);
		Return;
	EndIf;
	
	If Parameters.Cancel Then
		If Parameters.Restart <> True Then
			Terminate();
		ElsIf ValueIsFilled(Parameters.AdditionalParametersOfCommandLine) Then
			Terminate(Parameters.Restart, Parameters.AdditionalParametersOfCommandLine);
		Else
			Terminate(Parameters.Restart);
		EndIf;
		
	ElsIf Not Parameters.ContinuousExecution Then
		If ApplicationStartParameters.Property("ProcessingParameters") Then
			ApplicationStartParameters.Delete("ProcessingParameters");
		EndIf;
		AttachIdleHandler("OnStartIdleHandler", 0.1, True);
	EndIf;
	
EndProcedure

// For internal use only.
Function ProcessingParametersBeforeStartSystem(Delete = False)
	
	ParameterName = "StandardSubsystems.ApplicationStartParameters";
	Properties = ApplicationParameters[ParameterName];
	If Properties = Undefined Then
		Properties = New Structure;
		ApplicationParameters.Insert(ParameterName, Properties);
	EndIf;
	
	PropertyName = "ProcessingParametersBeforeStartSystem";
	If Properties.Property(PropertyName) Then
		Parameters = Properties[PropertyName];
	Else
		Parameters = New Structure;
		Properties.Insert(PropertyName, Parameters);
	EndIf;
	
	If Delete Then
		Properties.Delete(PropertyName);
	EndIf;
	
	Return Parameters;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// OnStart

// 
Procedure ActionsOnStart(CompletionNotification, ContinuousExecution)
	
	Parameters = ProcessingParametersOnStartSystem();
	
	// 
	Parameters.Insert("Cancel", False);
	Parameters.Insert("Restart", False);
	Parameters.Insert("AdditionalParametersOfCommandLine", "");
	
	// 
	Parameters.Insert("InteractiveHandler", Undefined); // NotifyDescription
	Parameters.Insert("ContinuationHandler",   Undefined); // NotifyDescription
	Parameters.Insert("ContinuousExecution", ContinuousExecution);
	
	// 
	Parameters.Insert("CompletionNotification", CompletionNotification);
	Parameters.Insert("CompletionProcessing", New NotifyDescription(
		"ActionsOnStartCompletionHandler", ThisObject));
	
	// 
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsOnStartInIntegrationProcedure", ThisObject));
	
	If Not ApplicationStartCompleted() Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'An unexpected error occurred during the application startup.
			           |
			           |Technical details:
			           |Invalid call %1 during the application startup. First, you need to complete the %2 procedure.
			           |One of the event handlers might have not called the notification to continue.
			           |The last called procedure is %3.';"),
			"StandardSubsystemsClient.OnStart",
			"StandardSubsystemsClient.BeforeStart",
			FullNameOfLastProcedureBeforeStartingSystem());
		Try
			Raise ErrorText;
		Except
			HandleErrorOnStart(Parameters, ErrorInfo(), True);
		EndTry;
		If OnStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
	EndIf;
	
	Try
		SetAdvancedApplicationCaption(True); // 
		
		If Not ProcessStartParameters() Then
			Parameters.Cancel = True;
			ExecuteNotifyProcessing(Parameters.CompletionProcessing);
			Return;
		EndIf;
	Except
		HandleErrorOnStart(Parameters, ErrorInfo(), True);
	EndTry;
	If OnStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continuation of the procedure at the beginning of the system's Work.
Procedure ActionsOnStartInIntegrationProcedure(NotDefined, Context) Export
	
	Parameters = ProcessingParametersOnStartSystem();
	
	If Not ContinueActionsOnStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsOnStartInIntegrationProcedureModules", ThisObject));
	
	Parameters.Insert("CurrentModuleIndex", 0);
	Parameters.Insert("AddedModules", New Array);
	Try
		Parameters.Insert("Modules", New Array);
		SSLSubsystemsIntegrationClient.OnStart(Parameters);
		Parameters.Insert("AddedModules", Parameters.Modules);
		Parameters.Delete("Modules");
	Except
		HandleErrorOnStart(Parameters, ErrorInfo());
	EndTry;
	If OnStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continuation of the procedure at the beginning of the system's Work.
Procedure ActionsOnStartInIntegrationProcedureModules(NotDefined, Context) Export
	
	While True Do
		Parameters = ProcessingParametersOnStartSystem();
		
		If Not ContinueActionsOnStart(Parameters) Then
			Return;
		EndIf;
		
		If Parameters.CurrentModuleIndex >= Parameters.AddedModules.Count() Then
			ActionsOnStartInOverridableProcedure(Undefined, Undefined);
			Return;
		EndIf;
		
		ModuleDetails = Parameters.AddedModules[Parameters.CurrentModuleIndex];
		Parameters.CurrentModuleIndex = Parameters.CurrentModuleIndex + 1;
		
		Try
			If TypeOf(ModuleDetails) <> Type("Structure") Then
				CurrentModule = ModuleDetails;
				CurrentModule.OnStart(Parameters);
			Else
				CurrentModule = ModuleDetails.Module;
				If ModuleDetails.Number = 2 Then
					CurrentModule.OnStart2(Parameters);
				ElsIf ModuleDetails.Number = 3 Then
					CurrentModule.OnStart3(Parameters);
				ElsIf ModuleDetails.Number = 4 Then
					CurrentModule.OnStart4(Parameters);
				EndIf;
			EndIf;
		Except
			HandleErrorOnStart(Parameters, ErrorInfo());
		EndTry;
		If OnStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use only. Continuation of the procedure at the beginning of the system's Work.
Procedure ActionsOnStartInOverridableProcedure(NotDefined, Context)
	
	Parameters = ProcessingParametersOnStartSystem();
	
	If Not ContinueActionsOnStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", New NotifyDescription(
		"ActionsOnStartInOverridableProcedureModules", ThisObject));
	
	Parameters.Insert("CurrentModuleIndex", 0);
	Parameters.Insert("AddedModules", New Array);
	Try
		Parameters.Insert("Modules", New Array);
		CommonClientOverridable.OnStart(Parameters);
		Parameters.Insert("AddedModules", Parameters.Modules);
		Parameters.Delete("Modules");
	Except
		HandleErrorOnStart(Parameters, ErrorInfo());
	EndTry;
	If OnStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continuation of the procedure at the beginning of the system's Work.
Procedure ActionsOnStartInOverridableProcedureModules(NotDefined, Context) Export
	
	While True Do
		
		Parameters = ProcessingParametersOnStartSystem();
		
		If Not ContinueActionsOnStart(Parameters) Then
			Return;
		EndIf;
		
		If Parameters.CurrentModuleIndex >= Parameters.AddedModules.Count() Then
			ActionsOnStartAfterAllProcedures(Undefined, Undefined);
			Return;
		EndIf;
		
		CurrentModule = Parameters.AddedModules[Parameters.CurrentModuleIndex];
		Parameters.CurrentModuleIndex = Parameters.CurrentModuleIndex + 1;
		
		Try
			CurrentModule.OnStart(Parameters);
		Except
			HandleErrorOnStart(Parameters, ErrorInfo());
		EndTry;
		If OnStartInteractiveHandler(Parameters) Then
			Return;
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use only. Continuation of the procedure at the beginning of the system's Work.
Procedure ActionsOnStartAfterAllProcedures(NotDefined, Context)
	
	Parameters = ProcessingParametersOnStartSystem();
	
	If Not ContinueActionsOnStart(Parameters) Then
		Return;
	EndIf;
	
	Parameters.Insert("ContinuationHandler", Parameters.CompletionProcessing);
	
	Try
		SSLSubsystemsIntegrationClient.AfterStart();
		CommonClientOverridable.AfterStart();
	Except
		HandleErrorOnStart(Parameters, ErrorInfo());
	EndTry;
	If OnStartInteractiveHandler(Parameters) Then
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Completion of the procedure at the beginning of the system Work.
Procedure ActionsOnStartCompletionHandler(NotDefined, Context) Export
	
	Parameters = ProcessingParametersOnStartSystem(True);
	
	Parameters.ContinuationHandler = Undefined;
	Parameters.CompletionProcessing  = Undefined;
	
	If Not Parameters.Cancel Then
		ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
		If ApplicationStartParameters.Property("SkipClearingDesktopHiding") Then
			ApplicationStartParameters.Delete("SkipClearingDesktopHiding");
		EndIf;
		HideDesktopOnStart(False);
	EndIf;
	
	If Parameters.CompletionNotification <> Undefined Then
		
		Result = New Structure;
		Result.Insert("Cancel", Parameters.Cancel);
		Result.Insert("Restart", Parameters.Restart);
		Result.Insert("AdditionalParametersOfCommandLine", Parameters.AdditionalParametersOfCommandLine);
		ExecuteNotifyProcessing(Parameters.CompletionNotification, Result);
		Return;
		
	Else
		If Parameters.Cancel Then
			If Parameters.Restart <> True Then
				Terminate();
				
			ElsIf ValueIsFilled(Parameters.AdditionalParametersOfCommandLine) Then
				Terminate(Parameters.Restart, Parameters.AdditionalParametersOfCommandLine);
			Else
				Terminate(Parameters.Restart);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// For internal use only.
Function ProcessingParametersOnStartSystem(Delete = False)
	
	ParameterName = "StandardSubsystems.ApplicationStartParameters";
	Properties = ApplicationParameters[ParameterName];
	If Properties = Undefined Then
		Properties = New Structure;
		ApplicationParameters.Insert(ParameterName, Properties);
	EndIf;
	
	PropertyName = "ProcessingParametersOnStartSystem";
	If Properties.Property(PropertyName) Then
		Parameters = Properties[PropertyName];
	Else
		Parameters = New Structure;
		Properties.Insert(PropertyName, Parameters);
	EndIf;
	
	If Delete Then
		Properties.Delete(PropertyName);
	EndIf;
	
	Return Parameters;
	
EndFunction

// To handle the startup parameters for the program.
//
// Returns:
//   Boolean   - 
//
Function ProcessStartParameters()

	If IsBlankString(LaunchParameter) Then
		Return True;
	EndIf;
	
	// 
	StartupParameters = StrSplit(LaunchParameter, ";", False);
	
	Cancel = False;
	SSLSubsystemsIntegrationClient.LaunchParametersOnProcess(StartupParameters, Cancel);
	CommonClientOverridable.LaunchParametersOnProcess(StartupParameters, Cancel);
	
	Return Not Cancel;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// BeforeExit

// For internal use only. 
// 
// Parameters:
//  ReCreate - Boolean
//
// Returns:
//   Structure:
//     
//      See StandardSubsystemsClient.WarningOnExit.
//     
//     
//     
//     
//
Function ParametersOfActionsBeforeShuttingDownTheSystem(ReCreate = False) Export
	
	ParameterName = "StandardSubsystems.ParametersOfActionsBeforeShuttingDownTheSystem";
	If ReCreate Or ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Structure);
	EndIf;
	Parameters = ApplicationParameters[ParameterName];
	
	If Not ReCreate Then
		Return Parameters;
	EndIf;
	
	// 
	Parameters.Insert("Cancel", False);
	Parameters.Insert("Warnings", ClientParameter("ExitWarnings"));
	
	// 
	Parameters.Insert("InteractiveHandler", Undefined); // NotifyDescription
	Parameters.Insert("ContinuationHandler",   Undefined); // NotifyDescription
	Parameters.Insert("ContinuousExecution", True);
	
	// 
	Parameters.Insert("CompletionProcessing", New NotifyDescription(
		"ActionsBeforeExitCompletionHandler", StandardSubsystemsClient));
	Return Parameters;
	
EndFunction	
	
// For internal use only. Continue the procedure before completing the system Operation.
//
// Parameters:
//   Parameters - See StandardSubsystemsClient.ParametersOfActionsBeforeShuttingDownTheSystem
//
Procedure ActionsBeforeExit(Parameters) Export
	
	Parameters.Insert("ContinuationHandler", Parameters.CompletionProcessing);
	
	If CommonClient.SeparatedDataUsageAvailable() Then
		Try
			OpenMessageFormOnExit(Parameters);
		Except
			HandleErrorOnStartOrExit(Parameters, ErrorInfo(), "End");
		EndTry;
		If InteractiveHandlerBeforeExit(Parameters) Then
			Return;
		EndIf;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Completing the procedure before completing the system Operation.
//
// Parameters:
//   NotDefined - Undefined
//   Parameters - See StandardSubsystemsClient.ParametersOfActionsBeforeShuttingDownTheSystem
//
Procedure ActionsBeforeExitCompletionHandler(NotDefined, Parameters) Export
	
	Parameters = ParametersOfActionsBeforeShuttingDownTheSystem();
	Parameters.ContinuationHandler = Undefined;
	Parameters.CompletionProcessing  = Undefined;
	ParameterName = "StandardSubsystems.SkipQuitSystemAfterWarningsHandled";
	
	If Not Parameters.Cancel
	   And Not Parameters.ContinuousExecution
	   And ApplicationParameters.Get(ParameterName) = Undefined Then
		
		ParameterName = "StandardSubsystems.SkipExitConfirmation";
		ApplicationParameters.Insert(ParameterName, True);
		Exit();
	EndIf;
	
EndProcedure

// For internal use only. Completing the procedure before completing the system Operation.
// 
// Parameters:
//  NotDefined - Undefined
//  ContinuationHandler - NotifyDescription
//
Procedure ActionsBeforeExitAfterErrorProcessing(NotDefined, ContinuationHandler) Export
	
	Parameters = ParametersOfActionsBeforeShuttingDownTheSystem();
	Parameters.ContinuationHandler = ContinuationHandler;
	
	If Parameters.Cancel Then
		Parameters.Cancel = False;
		ExecuteNotifyProcessing(Parameters.CompletionProcessing);
	Else
		ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart2(Parameters) Export
	
	// 
	// 
	// 
	// 
	
	ClientParameters = ClientParametersOnStart();
	
	If ClientParameters.Property("ShowDeprecatedPlatformVersion") Then
		Parameters.InteractiveHandler = New NotifyDescription(
			"Check1CEnterpriseVersionOnStartup", ThisObject);
	ElsIf ClientParameters.Property("InvalidPlatformVersionUsed") Then
		Parameters.InteractiveHandler = New NotifyDescription(
			"WarnAboutInvalidPlatformVersion", ThisObject);
	EndIf;
	
EndProcedure

// 
Procedure Check1CEnterpriseVersionOnStartup(Parameters, Context) Export
	
	ClientParameters = ClientParametersOnStart();
	
	SystemInfo = New SystemInfo;
	Current             = SystemInfo.AppVersion;
	Min         = ClientParameters.MinPlatformVersion;
	If StrFind(LaunchParameter, "UpdateAndExit") > 0
		And CommonClientServer.CompareVersions(Current, Min) < 0
		And CommonClient.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		MessageText = NStr("en = 'Cannot update the application.
			|
			|The current 1C:Enterprise version %1 is not supported.
			|Update 1C:Enterprise to version %2 or later';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, Current, Min);
		ModuleConfigurationUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
		ModuleConfigurationUpdateClient.WriteDownTheErrorOfTheNeedToUpdateThePlatform(MessageText);
	EndIf;
	
	ClosingNotification1 = New NotifyDescription("AfterClosingDeprecatedPlatformVersionForm", ThisObject, Parameters);
	If CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		StandardProcessing = True;
		ModuleGetApplicationUpdatesClient = CommonClient.CommonModule("GetApplicationUpdatesClient");
		ModuleGetApplicationUpdatesClient.WhenCheckingPlatformVersionAtStartup(ClosingNotification1, StandardProcessing);
		If Not StandardProcessing Then
			Return;
		EndIf;
	EndIf;
	
	If CommonClientServer.CompareVersions(Current, Min) < 0 Then
		If UsersClient.IsFullUser(True) Then
			MessageText =
				NStr("en = 'Cannot start the application.
				           |1C:Enterprise platform update is required.';");
		Else
			MessageText =
				NStr("en = 'Cannot start the application.
				           |1C:Enterprise platform update is required. Contact the administrator.';");
		EndIf;
	Else
		If UsersClient.IsFullUser(True) Then
			MessageText =
				NStr("en = 'It is recommended that you close the application and update the 1C:Enterprise platform version.
				         |The new 1C:Enterprise platform version includes bug fixes that improve the application stability.
				         |You can also continue using the current version.
				         |The minimum required platform version is %1.';");
		Else
			MessageText = 
				NStr("en = 'It is recommended that you close the application and contact the administrator to update the 1C:Enterprise platform version.
				         |The new platform version includes bug fixes that improve the application stability.
				         |You can also continue using the current version.
				         |The minimum required platform version is %1.';");
		EndIf;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("MessageText", MessageText);
	FormParameters.Insert("RecommendedPlatformVersion", ClientParameters.RecommendedPlatformVersion);
	FormParameters.Insert("MinPlatformVersion", ClientParameters.MinPlatformVersion);
	FormParameters.Insert("OpenByScenario", True);
	FormParameters.Insert("SkipExit", True);
	
	Form = OpenForm("DataProcessor.PlatformUpdateRecommended.Form.PlatformUpdateRecommended", FormParameters,
		, , , , ClosingNotification1);	
	If Form = Undefined Then
		AfterClosingDeprecatedPlatformVersionForm("Continue", Parameters);
	EndIf;
	
EndProcedure

// For internal use only. Continue the procedure to check the version of the platform on Startup.
Procedure AfterClosingDeprecatedPlatformVersionForm(Result, Parameters) Export
	
	If Result <> "Continue" Then
		Parameters.Cancel = True;
	Else
		Parameters.RetrievedClientParameters.Insert("ShowDeprecatedPlatformVersion");
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// 
Procedure WarnAboutInvalidPlatformVersion(Parameters, Context) Export

	ClosingNotification1 = New NotifyDescription("AfterCloseInvalidPlatformVersionForm", ThisObject, Parameters);
	
	Form = OpenForm("DataProcessor.PlatformUpdateRecommended.Form.PlatformUpdateIsRequired", ,
		, , , , ClosingNotification1); 
	
	If Form = Undefined Then
		AfterCloseInvalidPlatformVersionForm("Continue", Parameters);
	EndIf;
	
EndProcedure

// For internal use only. Continue the procedure to check the version of the platform on Startup.
Procedure AfterCloseInvalidPlatformVersionForm(Result, Parameters) Export
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart3(Parameters) Export
	
	// 
	// 
	
	ClientParameters = ClientParametersOnStart();
	
	If Not ClientParameters.Property("ReconnectMasterNode") Then
		Return;
	EndIf;
	
	Parameters.InteractiveHandler = New NotifyDescription(
		"MasterNodeReconnectionInteractiveHandler", ThisObject);
	
EndProcedure

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart4(Parameters) Export
	
	// 
	// 
	
	ClientParameters = ClientParametersOnStart();
	
	If Not ClientParameters.Property("SelectInitialRegionalIBSettings") Then
		Return;
	EndIf;
	
	Parameters.InteractiveHandler = New NotifyDescription(
		"InteractiveInitialRegionalInfobaseSettingsProcessing", ThisObject, Parameters);
	
EndProcedure

// For internal use only. Continue the procedure to check the need to restore the connection to the main Node.
Procedure MasterNodeReconnectionInteractiveHandler(Parameters, Context) Export
	
	ClientParameters = ClientParametersOnStart();
	
	If ClientParameters.ReconnectMasterNode = False Then
		Parameters.Cancel = True;
		ShowMessageBox(
			NotificationWithoutResult(Parameters.ContinuationHandler),
			NStr("en = 'Cannot log in because the connection to the master node is lost.
			           |Please contact the administrator.';"),
			15);
		Return;
	EndIf;
	
	Form = OpenForm("CommonForm.ReconnectToMasterNode",,,,,,
		New NotifyDescription("ReconnectToMasterNodeAfterCloseForm", ThisObject, Parameters));
	
	If Form = Undefined Then
		ReconnectToMasterNodeAfterCloseForm(New Structure("Cancel", True), Parameters);
	EndIf;
	
EndProcedure

// For internal use only. Continue the procedure before starting the System4.
Procedure InteractiveInitialRegionalInfobaseSettingsProcessing(Parameters, Context) Export
	
	ClientParameters = ClientParametersOnStart();
	
	If ClientParameters.SelectInitialRegionalIBSettings = False Then
		Parameters.Cancel = True;
		ShowMessageBox(
			NotificationWithoutResult(Parameters.ContinuationHandler),
			NStr("en = 'Cannot start the application. Regional settings need to be configured.
			           |Contact the administrator.';"),
			15);
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportClient = CommonClient.CommonModule("NationalLanguageSupportClient");
		
		NotifyDescription = New NotifyDescription("AfterCloseInitialRegionalInfobaseSettingsChoiceForm", ThisObject, Parameters);
		OpeningParameters  = New Structure("Source", "InitialFilling");
		ModuleNationalLanguageSupportClient.OpenTheRegionalSettingsForm(NotifyDescription, OpeningParameters);
		
	Else
		AfterCloseInitialRegionalInfobaseSettingsChoiceForm(New Structure("Cancel", True), Parameters);
	EndIf;
	
EndProcedure

// For internal use only. Continue the procedure to check the need to restore the connection to the main Node.
Procedure ReconnectToMasterNodeAfterCloseForm(Result, Parameters) Export
	
	If TypeOf(Result) <> Type("Structure") Or Result.Cancel Then
		Parameters.Cancel = True;
	Else
		Parameters.RetrievedClientParameters.Insert("ReconnectMasterNode");
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continue the procedure before starting the System4.
Procedure AfterCloseInitialRegionalInfobaseSettingsChoiceForm(Result, Parameters) Export
	
	If TypeOf(Result) <> Type("Structure") Or Result.Cancel Then
		Parameters.Cancel = True;
	Else
		Parameters.RetrievedClientParameters.Insert("SelectInitialRegionalIBSettings");
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// Sets the hide desktop flag when starting the system,
// which blocks the creation of forms on the desktop.
// Removes the hide flag and updates the desktop when it becomes possible,
// if the hide was performed.
//
// Parameters:
//  Hide - Boolean -  if the message is False, then if the desktop is hidden
//           , it will be shown again.
//
//  AlreadyDoneAtServer - Boolean -  if the pass is True, then the method has already been called
//           in the standardsystem module of the server Call, and it does not need
//           to be called, but only needs to be set on the client that the desktop
//           was hidden and needs to be shown later.
//
Procedure HideDesktopOnStart(Hide = True, AlreadyDoneAtServer = False) Export
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	
	If Hide Then
		If Not ApplicationStartParameters.Property("HideDesktopOnStart") Then
			ApplicationStartParameters.Insert("HideDesktopOnStart");
			If Not AlreadyDoneAtServer Then
				StandardSubsystemsServerCall.HideDesktopOnStart();
			EndIf;
			RefreshInterface();
		EndIf;
	Else
		If ApplicationStartParameters.Property("HideDesktopOnStart") Then
			ApplicationStartParameters.Delete("HideDesktopOnStart");
			If Not AlreadyDoneAtServer Then
				StandardSubsystemsServerCall.HideDesktopOnStart(False);
			EndIf;
			CommonClient.RefreshApplicationInterface();
		EndIf;
	EndIf;
	
EndProcedure

// For internal use only.
Procedure NotifyWithEmptyResult(NotificationWithResult) Export
	
	ExecuteNotifyProcessing(NotificationWithResult);
	
EndProcedure

// For internal use only.
Procedure StartInteractiveHandlerBeforeExit() Export
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	If Not ApplicationStartParameters.Property("ExitProcessingParameters") Then
		Return;
	EndIf;
	
	Parameters = ApplicationStartParameters.ExitProcessingParameters;
	ApplicationStartParameters.Delete("ExitProcessingParameters");
	
	InteractiveHandler = Parameters.InteractiveHandler;
	Parameters.InteractiveHandler = Undefined;
	ExecuteNotifyProcessing(InteractiveHandler, Parameters);
	
EndProcedure

// For internal use only.
//
// Parameters:
//  Result - DialogReturnCode 
//            - Undefined
//  AdditionalParameters - Structure
//
Procedure AfterClosingWarningFormOnExit(Result, AdditionalParameters) Export
	
	Parameters = ParametersOfActionsBeforeShuttingDownTheSystem();
	
	If AdditionalParameters.FormOption = "DoQueryBox" Then
		
		If Result = Undefined Or Result.Value <> DialogReturnCode.Yes Then
			Parameters.Cancel = True;
		EndIf;
		
	ElsIf AdditionalParameters.FormOption = "StandardForm" Then
	
		If Result = True Or Result = Undefined Then
			Parameters.Cancel = True;
		EndIf;
		
	Else // AppliedForm
		If Result = True Or Result = Undefined Or Result = DialogReturnCode.No Then
			Parameters.Cancel = True;
		EndIf;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	If MustShowRAMSizeRecommendations() Then
		AttachIdleHandler("ShowRAMRecommendation", 10, True);
	EndIf;
	
	If DisplayWarningsBeforeShuttingDownTheSystem(False) Then
		// 
		// 
		WarningsBeforeSystemShutdown(False); 
	EndIf;
	
EndProcedure

Function DisplayWarningsBeforeShuttingDownTheSystem(Cancel)
	
	If ApplicationStartupLogicDisabled() Then
		Return False;
	EndIf;
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	
	If ApplicationStartParameters.Property("HideDesktopOnStart") Then
		// 
		// 
		// 
		// 
		// 
		// 
		// 
		// 
#If Not WebClient Then
		Cancel = True;
#EndIf
		Return False;
	EndIf;
	
	// 
#If ThickClientOrdinaryApplication Then
	Return False;
#EndIf
	
	If ApplicationParameters["StandardSubsystems.SkipExitConfirmation"] = True Then
		Return False;
	EndIf;
	
	If Not CommonClient.SeparatedDataUsageAvailable() Then
		Return False;
	EndIf;
	Return True;
	
EndFunction
	
Function WarningsBeforeSystemShutdown(Cancel)
	
	Warnings = New Array;
	SSLSubsystemsIntegrationClient.BeforeExit(Cancel, Warnings);
	CommonClientOverridable.BeforeExit(Cancel, Warnings);
	Return Warnings;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// For internal use only.
Procedure MetadataObjectIDsListFormListValueChoice(Form, Item, Value, StandardProcessing) Export
	
	If Not Form.SelectMetadataObjectsGroups
	   And Item.CurrentData <> Undefined
	   And Not Item.CurrentData.DeletionMark
	   And Not ValueIsFilled(Item.CurrentData.Parent) Then
		
		StandardProcessing = False;
		
		If Item.Representation = TableRepresentation.Tree Then
			If Item.Expanded(Item.CurrentRow) Then
				Item.GroupBy(Item.CurrentRow);
			Else
				Item.Expand(Item.CurrentRow);
			EndIf;
			
		ElsIf Item.Representation = TableRepresentation.HierarchicalList Then
			
			If Item.CurrentParent <> Item.CurrentRow Then
				Item.CurrentParent = Item.CurrentRow;
			Else
				CurrentRow = Item.CurrentRow;
				Item.CurrentParent = Undefined;
				Item.CurrentRow = CurrentRow;
			EndIf;
		Else
			ShowMessageBox(,
				NStr("en = 'Cannot select a group of metadata objects.
				           |Please select a metadata object.';"));
		EndIf;
	EndIf;
	
EndProcedure

#Region TheParametersOfTheClientToTheServer

Procedure FillInTheClientParametersOnTheServer(Parameters) Export
	
	Parameters.Insert("LaunchParameter", LaunchParameter);
	Parameters.Insert("InfoBaseConnectionString", InfoBaseConnectionString());
	Parameters.Insert("IsWebClient", IsWebClient());
	Parameters.Insert("IsLinuxClient", CommonClient.IsLinuxClient());
	Parameters.Insert("IsMacOSClient", CommonClient.IsMacOSClient());
	Parameters.Insert("IsWindowsClient", CommonClient.IsWindowsClient());
	Parameters.Insert("IsMobileClient", IsMobileClient());
	Parameters.Insert("ClientUsed", ClientUsed());
	Parameters.Insert("BinDir", CurrentAppllicationDirectory());
	Parameters.Insert("ClientID", ClientID());
	Parameters.Insert("HideDesktopOnStart", False);
	Parameters.Insert("RAM", CommonClient.RAMAvailableForClientApplication());
	Parameters.Insert("MainDisplayResolotion", MainDisplayResolotion());
	Parameters.Insert("SystemInfo", ClientSystemInfo());
	
	// 
	Parameters.Insert("CurrentDateOnClient", CurrentDate()); // 
	Parameters.Insert("CurrentUniversalDateInMillisecondsOnClient", CurrentUniversalDateInMilliseconds());
	
EndProcedure

// Returns:
//   See Common.ClientUsed
//
Function ClientUsed()
	
	ClientUsed = "";
	#If ThinClient Then
		ClientUsed = "ThinClient";
	#ElsIf ThickClientManagedApplication Then
		ClientUsed = "ThickClientManagedApplication";
	#ElsIf ThickClientOrdinaryApplication Then
		ClientUsed = "ThickClientOrdinaryApplication";
	#ElsIf WebClient Then
		BrowserDetails = CurrentBrowser();
		If IsBlankString(BrowserDetails.Version) Then
			ClientUsed = StringFunctionsClientServer.SubstituteParametersToString("WebClient.%1", BrowserDetails.Name1);
		Else
			ClientUsed = StringFunctionsClientServer.SubstituteParametersToString("WebClient.%1.%2", BrowserDetails.Name1, StrSplit(BrowserDetails.Version, ".")[0]);
		EndIf;
	#EndIf
	
	Return ClientUsed;
	
EndFunction

Function CurrentBrowser()
	
	Result = New Structure("Name1,Version", "Other", "");
	
	SystemInfo = New SystemInfo;
	String = SystemInfo.UserAgentInformation;
	String = StrReplace(String, ",", ";");

	// Opera
	Id = "Opera";
	Position = StrFind(String, Id, SearchDirection.FromEnd);
	If Position > 0 Then
		String = Mid(String, Position + StrLen(Id));
		Result.Name1 = "Opera";
		Id = "Version/";
		Position = StrFind(String, Id);
		If Position > 0 Then
			String = Mid(String, Position + StrLen(Id));
			Result.Version = TrimAll(String);
		Else
			String = TrimAll(String);
			If StrStartsWith(String, "/") Then
				String = Mid(String, 2);
			EndIf;
			Result.Version = TrimL(String);
		EndIf;
		Return Result;
	EndIf;

	// IE
	Id = "MSIE"; // v11-
	Position = StrFind(String, Id);
	If Position > 0 Then
		Result.Name1 = "IE";
		String = Mid(String, Position + StrLen(Id));
		Position = StrFind(String, ";");
		If Position > 0 Then
			String = TrimL(Left(String, Position - 1));
			Result.Version = String;
		EndIf;
		Return Result;
	EndIf;

	Id = "Trident"; // v11+
	Position = StrFind(String, Id);
	If Position > 0 Then
		Result.Name1 = "IE";
		String = Mid(String, Position + StrLen(Id));
		
		Id = "rv:";
		Position = StrFind(String, Id);
		If Position > 0 Then
			String = Mid(String, Position + StrLen(Id));
			Position = StrFind(String, ")");
			If Position > 0 Then
				String = TrimL(Left(String, Position - 1));
				Result.Version = String;
			EndIf;
		EndIf;
		Return Result;
	EndIf;

	// Chrome
	Id = "Chrome/";
	Position = StrFind(String, Id);
	If Position > 0 Then
		Result.Name1 = "Chrome";
		String = Mid(String, Position + StrLen(Id));
		Position = StrFind(String, " ");
		If Position > 0 Then
			String = TrimL(Left(String, Position - 1));
			Result.Version = String;
		EndIf;
		Return Result;
	EndIf;

	// Safari
	Id = "Safari/";
	If StrFind(String, Id) > 0 Then
		Result.Name1 = "Safari";
		Id = "Version/";
		Position = StrFind(String, Id);
		If Position > 0 Then
			String = Mid(String, Position + StrLen(Id));
			Position = StrFind(String, " ");
			If Position > 0 Then
				Result.Version = TrimAll(Left(String, Position - 1));
			EndIf;
		EndIf;
		Return Result;
	EndIf;

	// Firefox
	Id = "Firefox/";
	Position = StrFind(String, Id);
	If Position > 0 Then
		Result.Name1 = "Firefox";
		String = Mid(String, Position + StrLen(Id));
		If Not IsBlankString(String) Then
			Result.Version = TrimAll(String);
		EndIf;
		Return Result;
	EndIf;
	
	Return Result;
	
EndFunction

Function CurrentAppllicationDirectory()
	
#If WebClient Or MobileClient Then
	BinDir = "";
#Else
	BinDir = BinDir();
#EndIf
	
	Return BinDir;
	
EndFunction

Function MainDisplayResolotion()
	
	ClientDisplaysInformation = GetClientDisplaysInformation();
	If ClientDisplaysInformation.Count() > 0 Then
		DPI = ClientDisplaysInformation[0].DPI; // 
		MainDisplayResolotion = ?(DPI = 0, 72, DPI);
	Else
		MainDisplayResolotion = 72;
	EndIf;
	
	Return MainDisplayResolotion;
	
EndFunction

Function ClientID()
	
	SystemInfo = New SystemInfo;
	Return SystemInfo.ClientID;
	
EndFunction

Function IsWebClient()
	
#If WebClient Then
	Return True;
#Else
	Return False;
#EndIf
	
EndFunction

Function IsMobileClient()
	
#If MobileClient Then
	Return True;
#Else
	Return False;
#EndIf
	
EndFunction

// Returns:
//   See Common.ClientSystemInfo
//
Function ClientSystemInfo()
	
	Result = New Structure(
		"OSVersion,
		|AppVersion,
		|ClientID,
		|UserAgentInformation,
		|RAM,
		|Processor,
		|PlatformType");
	
	SystemInfo = New SystemInfo;
	FillPropertyValues(Result, SystemInfo);
	Result.PlatformType = CommonClientServer.NameOfThePlatformType(SystemInfo.PlatformType);
	
	Return New FixedStructure(Result);
	
EndFunction

#EndRegion

// 
//
// Parameters:
//  Size - Number
//  Context - Structure:
//   * Notification - NotifyDescription
//   * Result  - Arbitrary
//
Procedure StartNotificationProcessingCompletion(Size, Context) Export
	
	ExecuteNotifyProcessing(Context.Notification, Context.Result);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

Procedure SignInToDataArea()
	
	If IsBlankString(LaunchParameter) Then
		Return;
	EndIf;
	
	StartupParameters = StrSplit(LaunchParameter, ";", False);
	
	If StartupParameters.Count() = 0 Then
		Return;
	EndIf;
	
	StartParameterValue = Upper(StartupParameters[0]);
	
	If StartParameterValue <> Upper("SignInToDataArea") Then
		Return;
	EndIf;
	
	If StartupParameters.Count() < 2 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Specify a separator value (a number) in startup parameter %1.';"),
			"SignInToDataArea");
	EndIf;
	
	Try
		SeparatorValue = Number(StartupParameters[1]);
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'A separator value in parameter %1 must be a number.';"),
			"SignInToDataArea");
	EndTry;
	
	StandardSubsystemsServerCall.SignInToDataArea(SeparatorValue);
	
EndProcedure

// Updates the settings of the client after the next interactive processing when you run.
Procedure UpdateClientParameters(Parameters, InitialCall = False, RefreshReusableValues = True)
	
	If InitialCall Then
		ParameterName = "StandardSubsystems.ApplicationStartParameters";
		If ApplicationParameters[ParameterName] = Undefined Then
			ApplicationParameters.Insert(ParameterName, New Structure);
		EndIf;
		ParameterName = "StandardSubsystems.ApplicationStartCompleted";
		If ApplicationParameters[ParameterName] = Undefined Then
			ApplicationParameters.Insert(ParameterName, False);
		EndIf;
	ElsIf Parameters.CountOfReceivedClientParameters = Parameters.RetrievedClientParameters.Count() Then
		Return;
	EndIf;
	
	Parameters.Insert("CountOfReceivedClientParameters", Parameters.RetrievedClientParameters.Count());
	
	ApplicationParameters["StandardSubsystems.ApplicationStartParameters"].Insert(
		"RetrievedClientParameters", Parameters.RetrievedClientParameters);
	
	If RefreshReusableValues Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Check the result of the interactive process, if a Failure, then causes the processing is completed.
// If a new received client parameter is added, updates the client's operation parameters.
//
// Parameters:
//   Parameters - See CommonClientOverridable.BeforeStart.Parameters.
//
// Returns:
//   Boolean - 
//            
//
Function ContinueActionsBeforeStart(Parameters)
	
	If Parameters.Cancel Then
		ExecuteNotifyProcessing(Parameters.CompletionProcessing);
		Return False;
	EndIf;
	
	UpdateClientParameters(Parameters);
	
	Return True;
	
EndFunction

// Handles an error found when calling the event handler at the beginning of the system's Work.
//
// Parameters:
//   Parameters          - See CommonClientOverridable.OnStart.Parameters.
//   ErrorInfo - ErrorInfo -  information about the error.
//   Shutdown   - Boolean -  if set to True, you will not be able to continue working if a startup error occurs.
//
Procedure HandleErrorBeforeStart(Parameters, ErrorInfo, Shutdown = False)
	
	HandleErrorOnStartOrExit(Parameters, ErrorInfo, "Run", Shutdown);
	
EndProcedure

// Checks the result of the event handler before starting the system And executes the alert handler.
//
// Parameters:
//   Parameters - See CommonClientOverridable.BeforeStart.Parameters.
//
// Returns:
//   Boolean - 
//            
//            
//
Function BeforeStartInteractiveHandler(Parameters)
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	
	If Parameters.InteractiveHandler = Undefined Then
		If Parameters.Cancel Then
			ExecuteNotifyProcessing(Parameters.CompletionProcessing);
			Return True;
		EndIf;
		Return False;
	EndIf;
	
	UpdateClientParameters(Parameters);
	
	If Not Parameters.ContinuousExecution Then
		InteractiveHandler = Parameters.InteractiveHandler;
		Parameters.InteractiveHandler = Undefined;
		InstallLatestProcedure(Parameters,,, InteractiveHandler);
		ExecuteNotifyProcessing(InteractiveHandler, Parameters);
		
	Else
		// 
		// 
		// 
		// 
		ApplicationStartParameters.Insert("ProcessingParameters", Parameters);
		HideDesktopOnStart();
		ApplicationStartParameters.Insert("SkipClearingDesktopHiding");
		
		If Parameters.CompletionNotification = Undefined Then
			// 
			// 
			If Not ApplicationStartupLogicDisabled() Then
				SetInterfaceFunctionalOptionParametersOnStart();
			EndIf;
		Else
			// 
			// 
			AttachIdleHandler("OnStartIdleHandler", 0.1, True);
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

Procedure InstallLatestProcedure(Parameters, ModuleName = "", ProcedureName = "", NotifyDescription = Undefined)
	
	If NotifyDescription = Undefined Then
		Parameters.ModuleOfLastProcedure = ModuleName;
		Parameters.NameOfLastProcedure = ProcedureName;
	Else
		Parameters.ModuleOfLastProcedure = NotifyDescription.Module;
		Parameters.NameOfLastProcedure = NotifyDescription.ProcedureName;
	EndIf;
	
EndProcedure

Function FullNameOfLastProcedureBeforeStartingSystem() Export
	
	Properties = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	If Properties = Undefined
	 Or Not Properties.Property("ProcessingParametersBeforeStartSystem") Then
		Return "";
	EndIf;
	Parameters = Properties.ProcessingParametersBeforeStartSystem;
	
	If TypeOf(Parameters.ModuleOfLastProcedure) = Type("CommonModule") Then
		NamesOfClientModules = StandardSubsystemsServerCall.NamesOfClientModules();
		For Each NameOfClientModule In NamesOfClientModules Do
			Try
				CurrentModule = CommonClient.CommonModule(NameOfClientModule);
			Except
				CurrentModule = Undefined;
			EndTry;
			If CurrentModule = Parameters.ModuleOfLastProcedure Then
				ModuleName = NameOfClientModule;
				Break;
			EndIf;
		EndDo;
	ElsIf TypeOf(Parameters.ModuleOfLastProcedure) = Type("ClientApplicationForm") Then
		ModuleName = Parameters.ModuleOfLastProcedure.FormName;
	Else
		ModuleName = String(Parameters.ModuleOfLastProcedure);
	EndIf;
	
	Return String(ModuleName) + "." + Parameters.NameOfLastProcedure;
	
EndFunction

// Check the result of the interactive process, if a Failure, then causes the processing is completed.
//
// Parameters:
//   Parameters - See CommonClientOverridable.OnStart.Parameters.
//
// Returns:
//   Boolean - 
//            
//
Function ContinueActionsOnStart(Parameters)
	
	If Parameters.Cancel Then
		ExecuteNotifyProcessing(Parameters.CompletionProcessing);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Handles an error found when calling the event handler at the beginning of the system's Work.
//
// Parameters:
//   Parameters          - See CommonClientOverridable.OnStart.Parameters.
//   ErrorInfo - ErrorInfo -  information about the error.
//   Shutdown   - Boolean -  if set to True, you will not be able to continue working if a startup error occurs.
//
Procedure HandleErrorOnStart(Parameters, ErrorInfo, Shutdown = False)
	
	HandleErrorOnStartOrExit(Parameters, ErrorInfo, "Run", Shutdown);
	
EndProcedure

// Checks the result of the event handler at the beginning of the system And executes the notification handler.
//
// Parameters:
//   Parameters - See CommonClientOverridable.OnStart.Parameters.
//
// Returns:
//   Boolean - 
//            
//
Function OnStartInteractiveHandler(Parameters)
	
	If Parameters.InteractiveHandler = Undefined Then
		If Parameters.Cancel Then
			ExecuteNotifyProcessing(Parameters.CompletionProcessing);
			Return True;
		EndIf;
		Return False;
	EndIf;
	
	InteractiveHandler = Parameters.InteractiveHandler;
	
	Parameters.ContinuousExecution = False;
	Parameters.InteractiveHandler = Undefined;
	
	ExecuteNotifyProcessing(InteractiveHandler, Parameters);
	
	Return True;
	
EndFunction

Function InteractiveHandlerBeforeStartInProgress()
	
	If ApplicationParameters = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'An unexpected error occurred during the application startup.
			           |
			           |Technical details:
			           |Invalid call %1 during the application startup. First, you need to complete the %2 procedure.';"),
			"StandardSubsystemsClient.OnStart",
			"StandardSubsystemsClient.BeforeStart");
		Raise ErrorText;
	EndIf;	

	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"]; // Structure
	If Not ApplicationStartParameters.Property("ProcessingParameters") Then
		Return False;
	EndIf;
	
	Parameters = ApplicationStartParameters.ProcessingParameters;
	InstallLatestProcedure(Parameters, "StandardSubsystemsClient",
		"InteractiveHandlerBeforeStartInProgress");
	If Parameters.InteractiveHandler = Undefined Then
		Return False;
	EndIf;
	
	AttachIdleHandler("TheHandlerWaitsToStartInteractiveProcessingBeforeTheSystemStartsWorking", 0.1, True);
	Parameters.ContinuousExecution = False;
	
	Return True;
	
EndFunction

Procedure StartInteractiveProcessingBeforeStartingTheSystem() Export
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"]; // Structure
	
	Parameters = ApplicationStartParameters.ProcessingParameters;
	InteractiveHandler = Parameters.InteractiveHandler;
	Parameters.InteractiveHandler = Undefined;
	InstallLatestProcedure(Parameters,,, InteractiveHandler);
	
	ExecuteNotifyProcessing(InteractiveHandler, Parameters);
	
	ApplicationStartParameters.Delete("ProcessingParameters");
	
EndProcedure

Function InteractiveHandlerBeforeExit(Parameters)
	
	If Parameters.InteractiveHandler = Undefined Then
		If Parameters.Cancel Then
			ExecuteNotifyProcessing(Parameters.CompletionProcessing);
			Return True;
		EndIf;
		Return False;
	EndIf;
	
	If Not Parameters.ContinuousExecution Then
		InteractiveHandler = Parameters.InteractiveHandler;
		Parameters.InteractiveHandler = Undefined;
		ExecuteNotifyProcessing(InteractiveHandler, Parameters);
		
	Else
		// 
		// 
		ApplicationParameters["StandardSubsystems.ApplicationStartParameters"].Insert("ExitProcessingParameters", Parameters);
		Parameters.ContinuousExecution = False;
		AttachIdleHandler(
			"BeforeExitInteractiveHandlerIdleHandler", 0.1, True);
	EndIf;
	
	Return True;
	
EndFunction

// Displays a form of messages to the user when the program is closed, or displays a message.
Procedure OpenMessageFormOnExit(Parameters)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormOption", "DoQueryBox");
	
	ResponseHandler = New NotifyDescription("AfterClosingWarningFormOnExit",
		ThisObject, AdditionalParameters);
		
	Warnings = Parameters.Warnings;
	Parameters.Delete("Warnings");
	
	FormParameters = New Structure;
	FormParameters.Insert("Warnings", Warnings);
	
	FormName = "CommonForm.ExitWarnings";
	
	If Warnings.Count() = 1 And IsBlankString(Warnings[0].CheckBoxText) Then
		AdditionalParameters.Insert("FormOption", "AppliedForm");
		OpenApplicationWarningForm(Parameters, ResponseHandler, Warnings[0], FormName, FormParameters);
	Else	
		AdditionalParameters.Insert("FormOption", "StandardForm");
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("FormName", FormName);
		FormOpenParameters.Insert("FormParameters", FormParameters);
		FormOpenParameters.Insert("ResponseHandler", ResponseHandler);
		FormOpenParameters.Insert("WindowOpeningMode", Undefined);
		Parameters.InteractiveHandler = New NotifyDescription(
			"WarningInteractiveHandlerOnExit", ThisObject, FormOpenParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure openformatedpredictionsperformance of work.
Procedure WarningInteractiveHandlerOnExit(Parameters, FormOpenParameters) Export
	
	OpenForm(
		FormOpenParameters.FormName,
		FormOpenParameters.FormParameters, , , , ,
		FormOpenParameters.ResponseHandler,
		FormOpenParameters.WindowOpeningMode);
	
EndProcedure

// Continuation of the procedure showprediction and Continue.
Procedure ShowMessageBoxAndContinueCompletion(Result, Parameters) Export
	
	If Result <> Undefined Then
		If Result.Value = "ExitApp" Then
			Parameters.Cancel = True;
		ElsIf Result.Value = "Restart" Or Result.Value = DialogReturnCode.Timeout Then
			Parameters.Cancel = True;
			Parameters.Restart = True;
		EndIf;
	EndIf;
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// Generates a single question display.
//
//	If the warning to the User has the "Text_perlinks" property, then the "individual opening Form" opens from
//	The structure of the question.
//	If the warning to the User has the "Textflag" property, the "General Form
//	" form opens.Questionsperforming the system".
//
// Parameters:
//  Parameters - See StandardSubsystemsClient.ParametersOfActionsBeforeShuttingDownTheSystem.
//  ResponseHandler - NotifyDescription -  to continue after receiving the user's response.
//  UserWarning - See StandardSubsystemsClient.WarningOnExit.
//  FormName - String -  name of the General form with questions.
//  FormParameters - Structure -  parameters for the form with questions.
//
Procedure OpenApplicationWarningForm(Parameters, ResponseHandler, UserWarning, FormName, FormParameters)
	
	HyperlinkText = "";
	If Not UserWarning.Property("HyperlinkText", HyperlinkText) Then
		Return;
	EndIf;
	If IsBlankString(HyperlinkText) Then
		Return;
	EndIf;
	
	ActionOnClickHyperlink = Undefined;
	If Not UserWarning.Property("ActionOnClickHyperlink", ActionOnClickHyperlink) Then
		Return;
	EndIf;
	
	ActionHyperlink = UserWarning.ActionOnClickHyperlink;
	Form = Undefined;
	
	If ActionHyperlink.Property("ApplicationWarningForm", Form) Then
		FormParameters = Undefined;
		If ActionHyperlink.Property("ApplicationWarningFormParameters", FormParameters) Then
			If TypeOf(FormParameters) = Type("Structure") Then 
				FormParameters.Insert("ApplicationShutdown", True);
			ElsIf FormParameters = Undefined Then 
				FormParameters = New Structure;
				FormParameters.Insert("ApplicationShutdown", True);
			EndIf;
			
			FormParameters.Insert("YesButtonTitle",  NStr("en = 'Exit';"));
			FormParameters.Insert("NoButtonTitle", NStr("en = 'Cancel';"));
			
		EndIf;
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("FormName", Form);
		FormOpenParameters.Insert("FormParameters", FormParameters);
		FormOpenParameters.Insert("ResponseHandler", ResponseHandler);
		FormOpenParameters.Insert("WindowOpeningMode", ActionHyperlink.WindowOpeningMode);
		Parameters.InteractiveHandler = New NotifyDescription(
			"WarningInteractiveHandlerOnExit", ThisObject, FormOpenParameters);
		
	ElsIf ActionHyperlink.Property("Form", Form) Then 
		FormParameters = Undefined;
		If ActionHyperlink.Property("FormParameters", FormParameters) Then
			If TypeOf(FormParameters) = Type("Structure") Then 
				FormParameters.Insert("ApplicationShutdown", True);
			ElsIf FormParameters = Undefined Then 
				FormParameters = New Structure;
				FormParameters.Insert("ApplicationShutdown", True);
			EndIf;
		EndIf;
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("FormName", Form);
		FormOpenParameters.Insert("FormParameters", FormParameters);
		FormOpenParameters.Insert("ResponseHandler", ResponseHandler);
		FormOpenParameters.Insert("WindowOpeningMode", ActionHyperlink.WindowOpeningMode);
		Parameters.InteractiveHandler = New NotifyDescription(
			"WarningInteractiveHandlerOnExit", ThisObject, FormOpenParameters);
		
	EndIf;
	
EndProcedure

// If stop Working = True is specified, then abort further execution of the client code and stop working.
//
Procedure HandleErrorOnStartOrExit(Parameters, ErrorInfo, Event, Shutdown = False)
	
	If Event = "Run" Then
		If Shutdown Then
			Parameters.Cancel = True;
			Parameters.ContinuationHandler = Parameters.CompletionProcessing;
		EndIf;
	Else
		Parameters.ContinuationHandler = New NotifyDescription(
			"ActionsBeforeExitAfterErrorProcessing", ThisObject, Parameters.ContinuationHandler);
	EndIf;
	
	StandardSubsystemsServerCall.WriteErrorToEventLogOnStartOrExit(
		Shutdown, Event, ErrorProcessing.DetailErrorDescription(ErrorInfo));	
		
	WarningText = ErrorProcessing.BriefErrorDescription(ErrorInfo) + Chars.LF + Chars.LF
		+ NStr("en = 'Technical information has been saved to the event log.';");
		
	If Event = "Run" And Shutdown Then
		WarningText = NStr("en = 'Cannot start the application:';")
			+ Chars.LF + Chars.LF + WarningText;
	EndIf;
	
	InteractiveHandler = New NotifyDescription("ShowMessageBoxAndContinue", ThisObject, WarningText);
	Parameters.InteractiveHandler = InteractiveHandler;
	
EndProcedure

Procedure SetInterfaceFunctionalOptionParametersOnStart()
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	
	If TypeOf(ApplicationStartParameters) <> Type("Structure")
	 Or Not ApplicationStartParameters.Property("InterfaceOptions") Then
		// 
		Return;
	EndIf;
	
	If ApplicationStartParameters.Property("InterfaceOptionsSet") Then
		Return;
	EndIf;
	
	InterfaceOptions = New Structure(ApplicationStartParameters.InterfaceOptions);
	
	// 
	If InterfaceOptions.Count() > 0 Then
		SetInterfaceFunctionalOptionParameters(InterfaceOptions);
	EndIf;
	
	ApplicationStartParameters.Insert("InterfaceOptionsSet");
	
EndProcedure

Function MustShowRAMSizeRecommendations()
	ClientParameters = ClientParametersOnStart();
	Return ClientParameters.MustShowRAMSizeRecommendations;
EndFunction

Procedure NotifyLowMemory() Export
	RecommendedSize = ClientParametersOnStart().RecommendedRAM;
	
	Title = NStr("en = 'Application performance degraded';");
	Text = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Consider increasing RAM size to %1 GB.';"), RecommendedSize);
	
	ShowUserNotification(Title, 
		"e1cib/app/DataProcessor.SpeedupRecommendation",
		Text, PictureLib.DialogExclamation, UserNotificationStatus.Important);
EndProcedure

Procedure NotifyCurrentUserOfUpcomingRestart(SecondsBeforeRestart) Export

	RestartTime = StandardSubsystemsServerCall.AppRestartTimeForApplyPatches();
	RestartTime = ?(RestartTime <> Undefined, Format(RestartTime,"DF=HH:mm"),
		Format(CommonClient.SessionDate() + SecondsBeforeRestart, "DF=HH:mm"));
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Application restart at %1';"), RestartTime);
	MessageText = NStr("en = 'You have scheduled the application restart to apply the patches. Click here to postpone.';");
	ShowUserNotification(
		TitleText,
		"e1cib/app/CommonForm.DynamicUpdateControl",
		MessageText, PictureLib.DialogExclamation,
		UserNotificationStatus.Important,
		"AppRestartToday");

EndProcedure
	
Procedure AttachHandlersOfRestartAndNotificationsWait(SecondsBeforeRestart) Export
	AttachIdleHandler("NotificationFiveMinutesBeforeRestart", SecondsBeforeRestart - 300, True);
	AttachIdleHandler("NotificationThreeMinutesBeforeRestart", SecondsBeforeRestart - 180, True);
	AttachIdleHandler("NotificationOneMinuteBeforeRestart", SecondsBeforeRestart - 60, True);
	AttachIdleHandler("RestartingApplication", SecondsBeforeRestart, True);
EndProcedure 

Procedure DisableScheduledRestart() Export
	DetachIdleHandler("NotificationFiveMinutesBeforeRestart");
	DetachIdleHandler("NotificationThreeMinutesBeforeRestart");
	DetachIdleHandler("NotificationOneMinuteBeforeRestart");
	DetachIdleHandler("RestartingApplication");
EndProcedure

#EndRegion
