﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
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
	
	Title = ?(ValueIsFilled(Parameters.Title), Parameters.Title, Title);
	Items.ErrorMessageText.Title = ?(ValueIsFilled(Parameters.ErrorMessageText),
		Parameters.ErrorMessageText, Items.ErrorMessageText.Title);
	
	CheckExclusiveModeAtServer();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ExclusiveModeAvailable Then
		Cancel = True;
		ExecuteNotifyProcessing(OnCloseNotifyDescription, False);
		Return;
	EndIf;
	
	If Parameters.ShouldCloseAllSessionsButCurrent Then
		IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(True);
	EndIf;
	AttachIdleHandler("CheckExclusiveMode", 30);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Parameters.ShouldCloseAllSessionsButCurrent Then
		IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(False);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ActiveUsersClick(Item)
	
	CheckExclusiveModeAtServer();
	NotifyDescription = New NotifyDescription("OpenActiveUserListCompletion", ThisObject);
	OpenForm("DataProcessor.ActiveUsers.Form.ActiveUsers", , , , , ,
		NotifyDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ActiveUsers2Click(Item)
	
	CheckExclusiveModeAtServer();
	NotifyDescription = New NotifyDescription("OpenActiveUserListCompletion", ThisObject);
	OpenForm("DataProcessor.ActiveUsers.Form.ActiveUsers" , , , , , ,
		NotifyDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EndSessionsAndRepeat(Command)
	
	Items.GroupPages.CurrentPage = Items.Waiting;
	Items.FormRetryApplicationStart.Visible = False;
	Items.TerminateSessionsAndRestartApplicationForm.Visible = False;
	
	// Setting the infobase lock parameters.
	CheckExclusiveMode();
	LockFileInfobase();
	IBConnectionsClient.SetTheUserShutdownMode(True);
	AttachIdleHandler("WaitForUserSessionTermination", 60);
	
EndProcedure

&AtClient
Procedure AbortApplicationStart(Command)
	
	CancelFileInfobaseLock();
	
	Close(True);
	
EndProcedure

&AtClient
Procedure RetryApplicationStart(Command)
	
	Close(False);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenActiveUserListCompletion(Result, AdditionalParameters) Export
	CheckExclusiveMode();
EndProcedure

&AtClient
Procedure CheckExclusiveMode()
	
	CheckExclusiveModeAtServer();
	If ExclusiveModeAvailable Then
		Close(False);
		Return;
	EndIf;
		
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateActiveSessionCount(Form)
	
	If Form.ActiveSessionCount > 0 Then
		HyperlinkText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Active users (%1)';"), 
			Form.ActiveSessionCount);
	Else
		HyperlinkText = NStr("en = 'Active users';");
	EndIf;	
	
	Form.Items.ActiveUsers.Title = HyperlinkText;
	Form.Items.ActiveUsersWait.Title = HyperlinkText;
	Form.Items.ActiveUsers.ExtendedTooltip.Title = Form.ExclusiveModeSettingError;
	Form.Items.ActiveUsersWait.ExtendedTooltip.Title = Form.ExclusiveModeSettingError;
	
	If Form.ActiveSessionCount = 0 And IsBlankString(Form.ExclusiveModeSettingError) Then
		Form.Items.ErrorMessageText.Title = NStr("en = 'Other users have already signed out:';");
		Form.Items.FixErrorText.Title = NStr("en = 'To continue, click Retry.';");
	Else	
		If ValueIsFilled(Form.Parameters.ErrorTextExitFailed) Then
			ErrorMessageText = Form.Parameters.ErrorTextExitFailed;
		Else	
			ErrorMessageText = NStr("en = 'Cannot update the app because the following users are still logged in:';");
		EndIf;
		Form.Items.ErrorMessageText.Title = ErrorMessageText;
		Form.Items.FixErrorText.Title = NStr("en = 'To continue, close their sessions.';");
	EndIf;	
	
EndProcedure

&AtServer
Procedure CheckExclusiveModeAtServer()
	
	InfobaseSessions = GetInfoBaseSessions();
	CurrentUserSessionNumber = InfoBaseSessionNumber();
	ActiveSessionCount = 0;
	For Each IBSession In InfobaseSessions Do
		If IBSession.ApplicationName = "Designer" And Not Parameters.ShouldCloseDesignerSession
			Or IBSession.SessionNumber = CurrentUserSessionNumber Then
			Continue;
		EndIf;
		ActiveSessionCount = ActiveSessionCount + 1;
	EndDo;
	
	ExclusiveModeAvailable = False;
	ExclusiveModeSettingError = "";
	If ActiveSessionCount = 0 Then
		Try
			SetExclusiveMode(True);
		Except
			ExclusiveModeSettingError = NStr("en = 'Details:';") + " " 
				+ ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		If ExclusiveMode() Then
			SetExclusiveMode(False);
		EndIf;
		ExclusiveModeAvailable = True;
	EndIf;	
	UpdateActiveSessionCount(ThisObject);
	
EndProcedure

&AtClient
Procedure WaitForUserSessionTermination()
	
	UserSessionsTerminationDuration = UserSessionsTerminationDuration + 1;
	If UserSessionsTerminationDuration < 8 Then
		Return;
	EndIf;
	
	CancelFileInfobaseLock();
	Items.GroupPages.CurrentPage = Items.Information;
	UpdateActiveSessionCount(ThisObject);
	Items.FormRetryApplicationStart.Visible = True;
	Items.TerminateSessionsAndRestartApplicationForm.Visible = True;
	DetachIdleHandler("WaitForUserSessionTermination");
	UserSessionsTerminationDuration = 0;
	
EndProcedure

&AtServer
Procedure LockFileInfobase()
	
	Object.DisableUserAuthorisation = True;
	
	Object.LockEffectiveFrom = CurrentSessionDate() + 2*60;
	BlockingPeriod = ?(ValueIsFilled(Parameters.BlockingPeriod), Parameters.BlockingPeriod, 5*60);
	Object.LockEffectiveTo = Object.LockEffectiveFrom + BlockingPeriod;
	Object.MessageForUsers = ?(ValueIsFilled(Parameters.LoginMessage), Parameters.LoginMessage, NStr("en = 'The app is unavailable while updating';"));
	
	Try
		FormAttributeToValue("Object").PerformInstallation();
	Except
		WriteLogEvent(IBConnections.EventLogEvent(),
			EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Common.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

&AtServer
Procedure CancelFileInfobaseLock()
	
	FormAttributeToValue("Object").CancelLock();
	
EndProcedure

#EndRegion
