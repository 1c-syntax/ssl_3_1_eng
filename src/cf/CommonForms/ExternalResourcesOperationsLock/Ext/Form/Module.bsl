///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlersForm

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	EventLogEventName = ExternalResourcesOperationsLock.EventLogEventName();
	
	LockParameters = ExternalResourcesOperationsLock.SavedLockParameters();
	CheckServerName = LockParameters.CheckServerName;
	
	If Parameters.LockDecisionMaking Then
		
		UnlockText = ScheduledJobsInternal.SettingValue("UnlockCommandPlacement");
		DataSeparationEnabled = Common.DataSeparationEnabled();
		DataSeparationChanged = LockParameters.DataSeparationEnabled <> DataSeparationEnabled;
		
		If DataSeparationEnabled Then
			Items.InfobaseMoved.Title = NStr("en = 'Transferred application';");
			Items.IsInfobaseCopy.Title = NStr("en = 'Application copy';");
			Title = NStr("en = 'The application was transferred or restored from backup';");
		EndIf;
		
		If Not DataSeparationEnabled And Not DataSeparationChanged Then
			
			ScalableClusterClarification = ?(Common.FileInfobase(), "",
				NStr("en = '• When using a scalable cluster, to prevent false starts due to change of computers acting
				           | as working servers, turn off the computer name check, click <b>More actions - Check server name.</b>';"));
			
			WarningLabel = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Scheduled online activities such as data synchronization and emailing are disabled
				           |to prevent conflicts with the main infobase.
				           |
				           |%1
				           |
				           |<a href = ""%2"">Technical information on lock reason</a>
				           |
				           | • If you use the infobase for accounting, select <b>Transferred infobase</b>.
				           | • If this is an infobase copy, select <b>Infobase copy</b>.
				           |%3
				           |
				           |%4';"),
				LockParameters.LockReason,
				"EventLog",
				ScalableClusterClarification,
				UnlockText);
		ElsIf Not DataSeparationEnabled And DataSeparationChanged Then
			WarningLabel = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Scheduled online activities such as data synchronization and emailing are disabled to prevent conflicts
				           |with the web application.
				           |
				           |<b>This infobase was transferred from a web application</b>.
				           |
				           | • If you use the infobase for accounting, select <b>Transferred infobase</b>.
				           | • If this is an infobase copy, select <b>Infobase copy</b>.
				           |
				           |%1';"),
				UnlockText);
		ElsIf DataSeparationEnabled And Not DataSeparationChanged Then
			WarningLabel = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Scheduled online activities such as data synchronization and emailing are disabled to prevent conflicts
				           |with the web application.
				           |
				           |<b>The application was transferred.</b>
				           |
				           | • If you use the application for accounting, select <b>Transferred application</b>.
				           | • If this is a copy of the application, select <b>Application copy</b>.
				           |
				           |%1';"),
				UnlockText);
		Else // 
			WarningLabel = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Scheduled online activities such as data synchronization and emailing are disabled to prevent conflicts
				           |with the desktop application.
				           |
				           |The application was transferred from a desktop.
				           |
				           | • If you use the application for accounting, select <b>Transferred application</b>.
				           | • If it is a copy of the application, select <b>Application copy</b>.
				           |
				           |%1';"),
				UnlockText);
		EndIf;
		
		Items.WarningLabel.Title = StringFunctions.FormattedString(WarningLabel);
		
		If Common.FileInfobase() Then
			Items.FormMoreGroup.Visible = False;
		Else
			Items.FormCheckServerName.Check = CheckServerName;
			Items.FormHelp.Visible = False;
		EndIf;
		
	Else
		Items.FormParametersGroup.CurrentPage = Items.LockParametersGroup;
		Items.WarningLabel.Visible = False;
		Items.WriteAndClose.DefaultButton = True;
		Title = NStr("en = 'Lock settings of external resources';");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarningLabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("EventLogEvent", EventLogEventName);
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure InfobaseMoved(Command)
	
	AllowExternalResources();
	StandardSubsystemsClient.SetAdvancedApplicationCaption();
	RefreshInterface();
	Close();
	
EndProcedure

&AtClient
Procedure IsInfobaseCopy(Command)
	
	DenyExternalResources();
	StandardSubsystemsClient.SetAdvancedApplicationCaption();
	RefreshInterface();
	Close();
	
EndProcedure

&AtClient
Procedure CheckServerName(Command)
	
	CheckServerName = Not CheckServerName;
	Items.FormCheckServerName.Check = CheckServerName;
	SetServerNameCheckInLockParameters(CheckServerName);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	SetServerNameCheckInLockParameters(CheckServerName);
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure AllowExternalResources()
	
	ExternalResourcesOperationsLock.AllowExternalResources();
	
EndProcedure

&AtServerNoContext
Procedure DenyExternalResources()
	
	ExternalResourcesOperationsLock.DenyExternalResources();
	
EndProcedure

&AtServerNoContext
Procedure SetServerNameCheckInLockParameters(CheckServerName)
	
	ExternalResourcesOperationsLock.SetServerNameCheckInLockParameters(CheckServerName);
	
EndProcedure

#EndRegion
