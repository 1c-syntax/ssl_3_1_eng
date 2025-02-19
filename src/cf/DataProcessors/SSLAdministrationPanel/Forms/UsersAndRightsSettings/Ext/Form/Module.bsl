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
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Users.CommonAuthorizationSettingsUsed() Then
		Items.UsersAuthorizationSettingsGroup.Visible = False;
		Items.GroupExternalUsers.Group
			= ChildFormItemsGroup.AlwaysHorizontal;
	EndIf;
	
	If Common.DataSeparationEnabled()
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion()
	 Or Common.IsStandaloneWorkplace()
	 Or Not UsersInternal.ExternalUsersEmbedded() Then
	
		Items.GroupExternalUsers.Visible = False;
		Items.SectionDetails.Title =
			NStr("en = 'Manage users, configure access groups, grant access to external users, and manage user settings.';");
	EndIf;
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion()
	 Or Common.IsSubordinateDIBNode() Then
		
		Items.UseUserGroups.Enabled = False;
		Items.UseExternalUsers.Enabled = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		SimplifiedInterface = ModuleAccessManagementInternal.SimplifiedAccessRightsSetupInterface();
		Items.OpenAccessGroups.Visible            = Not SimplifiedInterface;
		Items.UseUserGroups.Visible = Not SimplifiedInterface;
		Items.LimitAccessAtRecordLevelUniversally.Visible
			= ModuleAccessManagementInternal.ScriptVariantRussian()
				And Users.IsFullUser();
		Items.AccessUpdateOnRecordsLevel.Visible =
			ModuleAccessManagementInternal.LimitAccessAtRecordLevelUniversally(True);
		
		If Common.IsSubordinateDIBNode() Then
			Items.LimitAccessAtRecordLevel.Enabled = False;
			Items.LimitAccessAtRecordLevelUniversally.Enabled = False;
		EndIf;
		UpdateVisibilityOfStandardOptionObsoleteWarning(ThisObject);
		IsAccessRightsChangeLoggingSupported =
			ModuleAccessManagementInternal.IsAccessRightsChangeLoggingSupported();
	Else
		Items.AccessGroupsGroup.Visible = False;
		IsAccessRightsChangeLoggingSupported = False;
	EndIf;
	
	If Not IsAccessRightsChangeLoggingSupported
	   And Items.Find("ShouldRegisterChangesInAccessRights") <> Undefined Then
		
		Items.ShouldRegisterChangesInAccessRights.Title =
			NStr("en = 'Log changes in user group membership';");
		Items.ShouldRegisterChangesInAccessRights.ExtendedTooltip.Title =
			NStr("en = 'Logging events of changes in user group membership.';");
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		Items.PeriodClosingDatesGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PersonalDataProtection") Then
		Items.GroupPersonalDataAccessEventRegistrationSettings.Visible =
			  Not Common.DataSeparationEnabled()
			And Users.IsFullUser(, True);
	Else
		Items.PersonalDataProtectionGroup.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions")
	 Or Metadata.Subsystems.Find("Administration") = Undefined Then
		Items.UserMonitoring.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.UserMonitoring") Then
		Items.GroupDataAccessAudit.Visible = False;
		If Items.Find("ShouldRegisterChangesInAccessRights") <> Undefined Then
			Items.ShouldRegisterChangesInAccessRights.Visible = False;
		EndIf;
		Items.GroupUserMonitoringLeftColumnVerticalIndent.Visible = True;
		
	ElsIf Common.DataSeparationEnabled()
	      Or Not Users.IsFullUser(, True) Then
		
		Items.GroupDataAccessManagementSettings.Visible = False;
	Else
		ModuleUserMonitoring = Common.CommonModule("UserMonitoring");
		ShouldRegisterDataAccess = ModuleUserMonitoring.ShouldRegisterDataAccess();
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Items.PasswordsRecovery.Visible = False;
	EndIf;
	
	// Update items states.
	SetAvailability();
	
	ApplicationSettingsOverridable.UsersAndRightsSettingsOnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	RefreshApplicationInterface();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName <> "Write_ConstantsSet" Then
		Return;
	EndIf;
	
	If Source = "UseSurvey" 
		And CommonClient.SubsystemExists("StandardSubsystems.Surveys") Then
		
		Read();
		SetAvailability();
		
	ElsIf Source = "UseHidePersonalDataOfSubjects" Then
		Read();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseUserGroupsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ShouldRegisterChangesInAccessRightsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseExternalUsersOnChange(Item)
	
	If ConstantsSet.UseExternalUsers Then
		
		QueryText =
			NStr("en = 'Do you want to allow external user access?
			           |
			           |This will clear the user list in the startup dialog.
			           |The ""Show in choice list"" checkbox will be cleared and hidden in all user cards).
			           |';");
		
		ShowQueryBox(
			New CallbackDescription(
				"UseExternalUsersOnChangeCompletion",
				ThisObject,
				Item),
			QueryText,
			QuestionDialogMode.YesNo);
	Else
		QueryText =
			NStr("en = 'Do you want to deny external user access?
			           |
			           |The ""Login allowed"" checkbox will be cleared in all external user cards.
			           |';");
		
		ShowQueryBox(
			New CallbackDescription(
				"UseExternalUsersOnChangeCompletion",
				ThisObject,
				Item),
			QueryText,
			QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure LimitAccessAtRecordLevelUniversallyOnChange(Item)
	
	If ConstantsSet.LimitAccessAtRecordLevelUniversally Then
		QueryText =
			NStr("en = 'Do you want to enable the high-performance access restriction mode?
			           |
			           |The update of the right settings will take some time.
			           |To monitor the progress, click ""RLS access update progress"".';");
	Else
		QueryText =
			NStr("en = 'Are you sure you want to enable the standard access restriction mode, which is obsolete?
			           |
			           |The update of the right settings will take some time.
			           |To monitor the progress, click ""RLS access update progress"".';");
	EndIf;
	
	If ValueIsFilled(QueryText) Then
		ShowQueryBox(
			New CallbackDescription(
				"LimitAccessAtRecordLevelUniversallyOnChangeCompletion",
				ThisObject, Item),
			QueryText, QuestionDialogMode.YesNo);
	Else
		LimitAccessAtRecordLevelUniversallyOnChangeCompletion(DialogReturnCode.Yes, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure LimitAccessAtRecordLevelOnChange(Item)
	
	If ConstantsSet.LimitAccessAtRecordLevelUniversally Then
		QueryText =
			NStr("en = 'Access group settings will take effect in a while.
			           |To monitor the progress, click ""RLS access update progress"".
			           |
			           |This might slow down the app and take
			           |from seconds to a few hours, depending on the data volume.';");
		If ConstantsSet.LimitAccessAtRecordLevel Then
			QueryText = NStr("en = 'Do you want to enable record-level access restrictions?';")
				+ Chars.LF + Chars.LF + QueryText;
		Else
			QueryText = NStr("en = 'Do you want to disable record-level access restrictions?';")
				+ Chars.LF + Chars.LF + QueryText;
		EndIf;
		
	ElsIf ConstantsSet.LimitAccessAtRecordLevel Then
		QueryText =
			NStr("en = 'Do you want to enable RLS restriction?
			           |
			           |This might slow down the app and take
			           |from seconds to a few hours, depending on the data volume.
			           |To monitor the progress, see ""Populate data for access restriction"" in the event log.';");
	Else
		QueryText = "";
	EndIf;
	
	If ValueIsFilled(QueryText) Then
		ShowQueryBox(
			New CallbackDescription(
				"LimitAccessAtRecordLevelOnChangeCompletion",
				ThisObject, Item),
			QueryText, QuestionDialogMode.YesNo);
	Else
		LimitAccessAtRecordLevelOnChangeCompletion(DialogReturnCode.Yes, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShouldRegisterDataAccessOnChange(Item)
	RegisterDataAccessOnChangeAtServer(ShouldRegisterDataAccess);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CatalogExternalUsers(Command)
	OpenForm("Catalog.ExternalUsers.ListForm", , ThisObject);
EndProcedure

&AtClient
Procedure UserMonitoring(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsOptionsClient = CommonClient.CommonModule("ReportsOptionsClient");
		ModuleReportsOptionsClient.ShowReportBar("Administration", Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure AccessUpdateOnRecordsLevel(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternalClient = CommonClient.CommonModule("AccessManagementInternalClient");
		ModuleAccessManagementInternalClient.OpenAccessUpdateOnRecordsLevelForm(True, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigurePeriodClosingDates(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		ModulePeriodClosingDatesInternalClient = CommonClient.CommonModule("PeriodClosingDatesInternalClient");
		ModulePeriodClosingDatesInternalClient.OpenPeriodEndClosingDates(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure UpdateVisibilityOfStandardOptionObsoleteWarning(Form)
	
	Items = Form.Items;
	Items.StandardOptionObsolete.Visible =
		Items.LimitAccessAtRecordLevelUniversally.Visible
		And Items.LimitAccessAtRecordLevelUniversally.Enabled
		And Not Items.AccessUpdateOnRecordsLevel.Visible;
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True)
	
	ConstantsNames = OnChangeAttributeServer(Item.Name);
	RefreshReusableValues();
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
	For Each ConstantName In ConstantsNames Do
		If ConstantName <> "" Then
			Notify("Write_ConstantsSet", New Structure, ConstantName);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_PDDestructionSettingsOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.PersonalDataProtection") Then
		ModulePersonalDataProtectionClient = CommonClient.CommonModule("PersonalDataProtectionClient");
		ModulePersonalDataProtectionClient.SettingsForDestructionOfPersonalDataWhenChanging(ThisObject);
	EndIf;

	RefreshInterface = True;
	AttachIdleHandler("RefreshApplicationInterface", 2, True);

EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Procedure LimitAccessAtRecordLevelUniversallyOnChangeCompletion(Response, Item) Export
	
	If Response = DialogReturnCode.No Then
		ConstantsSet.LimitAccessAtRecordLevelUniversally
			= Not ConstantsSet.LimitAccessAtRecordLevelUniversally;
		Return;
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
	
	Items.AccessUpdateOnRecordsLevel.Visible =
		ConstantsSet.LimitAccessAtRecordLevelUniversally;
	
	UpdateVisibilityOfStandardOptionObsoleteWarning(ThisObject);
	
EndProcedure

&AtClient
Procedure LimitAccessAtRecordLevelOnChangeCompletion(Response, Item) Export
	
	If Response = DialogReturnCode.No Then
		ConstantsSet.LimitAccessAtRecordLevel = Not ConstantsSet.LimitAccessAtRecordLevel;
		Return;
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
	
	If Not ConstantsSet.LimitAccessAtRecordLevel Then
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UseExternalUsersOnChangeCompletion(Response, Item) Export
	
	If Response = DialogReturnCode.No Then
		ConstantsSet.UseExternalUsers = Not ConstantsSet.UseExternalUsers;
	Else
		Attachable_OnChangeAttribute(Item);
	EndIf;
	
EndProcedure

&AtServer
Function OnChangeAttributeServer(TagName)
	
	ConstantsNames = New Array;
	DataPathAttribute = Items[TagName].DataPath;
	
	BeginTransaction();
	Try
		
		ConstantName = SaveAttributeValue(DataPathAttribute);
		ConstantsNames.Add(ConstantName);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SetAvailability(DataPathAttribute);
	RefreshReusableValues();
	Return ConstantsNames;
	
EndFunction

&AtServerNoContext
Procedure RegisterDataAccessOnChangeAtServer(Val ShouldRegisterDataAccess)
	
	If Not Common.SubsystemExists("StandardSubsystems.UserMonitoring") Then
		Return;
	EndIf;
	
	ModuleUserMonitoring = Common.CommonModule("UserMonitoring");
	ModuleUserMonitoring.SetDataAccessRegistration(ShouldRegisterDataAccess);
	
EndProcedure

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	CurrentValue  = ConstantManager.Get();
	If CurrentValue <> ConstantValue Then
		Try
			ConstantManager.Set(ConstantValue);
		Except
			ConstantsSet[ConstantName] = CurrentValue;
			Raise;
		EndTry;
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If DataPathAttribute = "ConstantsSet.UseExternalUsers"
	 Or DataPathAttribute = "" Then
		
		Items.OpenExternalUsers.Enabled = ConstantsSet.UseExternalUsers;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PeriodClosingDates")
		And (DataPathAttribute = "ConstantsSet.UsePeriodClosingDates"
		Or DataPathAttribute = "") Then
		
		Items.ConfigurePeriodClosingDates.Enabled = ConstantsSet.UsePeriodClosingDates;
	EndIf;
	
	
	
EndProcedure

#EndRegion