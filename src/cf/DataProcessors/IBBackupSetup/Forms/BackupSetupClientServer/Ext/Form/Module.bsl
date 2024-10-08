﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Common.IsWebClient() Then
		Raise NStr("en = 'Web client does not support data backup.';");
	EndIf;
	
	If Not Common.IsWindowsClient() Then
		Raise NStr("en = 'Set up data backup and restore using operating system tools or other third-party tools.';");
	EndIf;
	
	Settings = IBBackupServer.BackupParameters();
	DisableNotifications = Settings.BackupConfigured;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Settings = ApplicationParameters["StandardSubsystems.IBBackupParameters"];
	Settings.NotificationParameter1 = ?(DisableNotifications, "DontNotify", "NotConfiguredYet");
	
	If DisableNotifications Then
		IBBackupClient.DisableBackupIdleHandler();
	Else
		IBBackupClient.AttachIdleBackupHandler();
	EndIf;
	
	SetBackupSettings();
	Notify("BackupSettingsFormClosed");
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetBackupSettings()
	
	Settings = IBBackupServer.BackupParameters();
	Settings.BackupConfigured = DisableNotifications;
	Settings.CreateBackupAutomatically = False;
	IBBackupServer.SetBackupSettings(Settings);
	
EndProcedure

#EndRegion
