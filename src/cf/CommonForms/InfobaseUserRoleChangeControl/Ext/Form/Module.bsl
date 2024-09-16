﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	InformParameters = UsersInternalClient.RestartNotificationParameters();
	If Not ValueIsFilled(InformParameters.RestartDate) Then
		Return;
	EndIf;
	
	Items.FormRemindMeTomorrow.Visible = False;
	Items.Picture.Picture = PictureLib.DialogExclamation;
	
	MinutesLeftPresentation = UsersInternalClient.MinutesBeforeRestartPresentation(
		UsersInternalClient.MinutesBeforeRestart(InformParameters.RestartDate));
		
	Items.Label.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'The administrator changed access rights.
		           |To apply the changes, the app will restart in %1.';"),
		MinutesLeftPresentation);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Restart(Command)
	
	StandardSubsystemsClient.SkipExitConfirmation();
	Exit(True, True);
	
EndProcedure

&AtClient
Procedure RemindMeTomorrow(Command)
	
	RemindTomorrowOnServer();
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure RemindTomorrowOnServer()
	
	Common.SystemSettingsStorageSave("InfobaseUserRoleChangeControl",
		"DateRemindTomorrow", BegOfDay(CurrentSessionDate()) + 60*60*24);
	
EndProcedure

#EndRegion
