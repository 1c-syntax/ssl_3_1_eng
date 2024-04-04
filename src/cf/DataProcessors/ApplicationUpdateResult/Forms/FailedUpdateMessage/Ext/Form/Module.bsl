///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Variables

&AtClient
Var ErrorReport;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// 
	// 
	If Parameters.ErrorInfo <> Undefined Then
		BriefErrorDescription   = ErrorProcessing.BriefErrorDescription(Parameters.ErrorInfo);
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(Parameters.ErrorInfo);
	EndIf;
	If ValueIsFilled(DetailErrorDescription)
	   And Common.SubsystemExists("StandardSubsystems.DataExchange")
	   And Common.IsSubordinateDIBNode() Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.EnableDataExchangeMessageImportRecurrenceBeforeStart();
	EndIf;
	
	ErrorInfo = Parameters.ErrorInfo;
	
	If ValueIsFilled(DetailErrorDescription) Then
		EventLog.AddMessageForEventLog(InfobaseUpdate.EventLogEvent(), EventLogLevel.Error,
			, , DetailErrorDescription);
	EndIf;
	
	ErrorMessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'The application was not updated to a new version due to:
		|
		|%1';"),
		BriefErrorDescription);
	
	Items.ErrorMessageText.Title = ErrorMessageText;
	
	UpdateStartTime = Parameters.UpdateStartTime;
	UpdateEndTime = CurrentSessionDate();
	
	If Not Users.IsFullUser(, True) Then
		Items.FormOpenExternalDataProcessor.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
	Else
		UseSecurityProfiles = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ModuleConfigurationUpdate = Common.CommonModule("ConfigurationUpdate");
		ScriptDirectory = ModuleConfigurationUpdate.ScriptDirectory();
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport")
		And Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate")
		And Not Common.DataSeparationEnabled()
		And Not Common.IsSubordinateDIBNode() Then
		ModuleOnlineUserSupport = Common.CommonModule("OnlineUserSupport");
		ModuleOnlineUserSupportClientServer = Common.CommonModule("OnlineUserSupportClientServer");
		ISLVersion = ModuleOnlineUserSupportClientServer.LibraryVersion();
		If CommonClientServer.CompareVersions(ISLVersion, "2.6.3.0") < 0
			Or Not Users.IsFullUser() Then
			Items.FormCheckPatches.Visible = False;
		Else
			AuthenticationData = ModuleOnlineUserSupport.OnlineSupportUserAuthenticationData();
			
			If AuthenticationData = Undefined Then
				Items.FormCheckPatches.Visible = False;
			EndIf;
		EndIf;
	Else
		Items.FormCheckPatches.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not IsBlankString(ScriptDirectory) Then
		ModuleConfigurationUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
		ModuleConfigurationUpdateClient.WriteErrorLogFileAndExit(ScriptDirectory, 
			DetailErrorDescription);
	EndIf;
	
	If ErrorInfo <> Undefined Then
		ErrorReport = New ErrorReport(ErrorInfo);
		StandardSubsystemsClient.ConfigureVisibilityAndTitleForURLSendErrorReport(Items.GenerateErrorReport, ErrorInfo, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If ErrorReport <> Undefined Then
		StandardSubsystemsClient.SendErrorReport(ErrorReport, ErrorInfo, True);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowUpdateResultInfoClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("StartDate", UpdateStartTime);
	FormParameters.Insert("EndDate", UpdateEndTime);
	FormParameters.Insert("ShouldNotRunInBackground", True);
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExitApplication(Command)
	Close(True);
EndProcedure

&AtClient
Procedure RestartApp(Command)
	Close(False);
EndProcedure

&AtClient
Procedure OpenExternalDataProcessor(Command)
	
	ContinuationHandler = New NotifyDescription("OpenExternalDataProcessorAfterConfirmSafety", ThisObject);
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.SecurityWarning",,,,,, ContinuationHandler);
	
EndProcedure

&AtClient
Procedure OpenExternalDataProcessorAfterConfirmSafety(Result, AdditionalParameters) Export
	If Result <> True Then
		Return;
	EndIf;
	
	If UseSecurityProfiles Then
		
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.OpenExternalDataProcessorOrReport(ThisObject);
		Return;
		
	EndIf;
	
	Notification = New NotifyDescription("OpenExternalDataProcessorCompletion", ThisObject);
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	ImportParameters.Dialog.Filter = NStr("en = 'External data processor';") + "(*.epf)|*.epf";
	ImportParameters.Dialog.Multiselect = False;
	ImportParameters.Dialog.Title = NStr("en = 'Select external data processor';");
	FileSystemClient.ImportFile_(Notification, ImportParameters);
EndProcedure

&AtClient
Procedure OpenExternalDataProcessorCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ExternalDataProcessorName = AttachExternalDataProcessor(Result.Location);
		OpenForm(ExternalDataProcessorName + ".Form");
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckPatches(Command)
	Result = AvailableFixesOnServer();
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Error Then
		ShowMessageBox(, Result.BriefErrorDetails);
		Return;
	EndIf;
	
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.PromptDontAskAgain = False;
	QuestionParameters.Title = NStr("en = 'Check whether patches are available';");
	QuestionParameters.Picture = PictureLib.Information;
	
	If Result.NumberOfCorrections = 0 Then
		Message = NStr("en = 'No available patch is found.';");
		StandardSubsystemsClient.ShowQuestionToUser(Undefined, Message, QuestionDialogMode.OK, QuestionParameters);
		Return;
	EndIf;
	
	Message = NStr("en = 'Found %1 patches. Do you want to install them?';");
	Message = StringFunctionsClientServer.SubstituteParametersToString(Message, Result.NumberOfCorrections);
	
	NotifyDescription = New NotifyDescription("CheckAvailableFixesContinued", ThisObject, Result);
	
	QuestionParameters.Picture = PictureLib.DialogQuestion;
	QuestionParameters.DefaultButton = DialogReturnCode.Yes;
	StandardSubsystemsClient.ShowQuestionToUser(NotifyDescription, Message, QuestionDialogMode.YesNo, QuestionParameters);
EndProcedure

&AtClient
Procedure GenerateErrorReportClick(Item)
	StandardSubsystemsClient.ShowErrorReport(ErrorReport);
EndProcedure

#EndRegion

#Region Private

&AtServer
Function AvailableFixesOnServer()
	Result = Undefined;
	If Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		ModuleGetApplicationUpdates = Common.CommonModule("GetApplicationUpdates");
		Result = ModuleGetApplicationUpdates.InfoAboutAvailablePatches();
		If Result <> Undefined Then
			Corrections = Result.Corrections.UnloadColumn("Description");
			Result.Insert("NumberOfCorrections", Result.Corrections.Count());
			Result.Insert("Corrections", Corrections);
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

&AtClient
Procedure CheckAvailableFixesContinued(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Value = DialogReturnCode.No Then
		Return;
	EndIf;
	
	TimeConsumingOperation    = StartingPatchInstallation();
	IdleParameters     = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackOnCompletion = New NotifyDescription("ProcessResult", ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtServer
Function StartingPatchInstallation()
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Installing patches';");
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "GetApplicationUpdates.DownloadAndInstallFixes");
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure ProcessResult(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.PromptDontAskAgain = False;
	QuestionParameters.Title = NStr("en = 'Installing patches';");
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	InstallResult = GetFromTempStorage(Result.ResultAddress);
	If InstallResult.Error Then
		ErrorText = InstallResult.BriefErrorDetails
			+ Chars.LF + Chars.LF + NStr("en = 'For technical error details, see the event log.';");
		
		Buttons = New ValueList;
		Buttons.Add("EventLog", NStr("en = 'Event log';"));
		Buttons.Add("Close", NStr("en = 'Close';"));
		QuestionParameters.Picture = PictureLib.DialogExclamation;
		QuestionParameters.DefaultButton = "Close";
		NotifyDescription = New NotifyDescription("HandlePatchInstallationError", ThisObject);
		StandardSubsystemsClient.ShowQuestionToUser(NotifyDescription, ErrorText, Buttons, QuestionParameters);
		
		Return;
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Corrections", AdditionalParameters.Corrections);
	OpeningParameters.Insert("OnUpdate", True);
	ModuleConfigurationUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
	ModuleConfigurationUpdateClient.ShowInstalledPatches(OpeningParameters, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure HandlePatchInstallationError(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Value = "EventLog" Then
		EventLogClient.OpenEventLog();
	EndIf;
EndProcedure

&AtServer
Function AttachExternalDataProcessor(AddressInTempStorage)
	
	If Not Users.IsFullUser(, True) Then
		Raise NStr("en = 'Insufficient access rights.';");
	EndIf;
	
	// 
	// 
	Manager = ExternalDataProcessors;
	DataProcessorName = Manager.Connect(AddressInTempStorage, , False,
		Common.ProtectionWithoutWarningsDetails());
	Return Manager.Create(DataProcessorName, False).Metadata().FullName();
	// 
	// 
	
EndFunction

#EndRegion
