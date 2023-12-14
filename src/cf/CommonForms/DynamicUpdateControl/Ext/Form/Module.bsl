///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CheckParameters = Catalogs.ExtensionsVersions.DynamicallyChangedExtensions();
	CheckParameters.Insert("DataBaseConfigurationChangedDynamically", DataBaseConfigurationChangedDynamically());
	
	NumberOfNewPatches = 0;
	If CheckParameters.Corrections <> Undefined And CheckParameters.Corrections.NewItemsList.Count() > 0 Then
		StorageAddress = PutToTempStorage(Undefined, UUID);
		MethodParameters = New Array;
		MethodParameters.Add(StorageAddress);
		MethodParameters.Add(CheckParameters.Corrections.NewItemsList);
		BackgroundJob = ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(
			"ConfigurationUpdate.NewPatchesDetails1",
			MethodParameters);
		BackgroundJob.WaitForExecutionCompletion(Undefined);
		
		NewPatchesDetails = GetFromTempStorage(StorageAddress);
		NumberOfNewPatches = CheckParameters.Corrections.NewItemsList.Count();
	EndIf;
	
	SetMainText(CheckParameters, NumberOfNewPatches);
	SetVisibilityAvailability(ThisObject);
	
	WithASchedule = True;
	If CheckParameters.Corrections = Undefined
		Or CheckParameters.Corrections.Added2 = 0 Then
		Items.ScheduleGroup.Visible = False;
		WithASchedule = False;
	Else
		FillInTheFormDisplaySchedule();
	EndIf;
	
	Var_Key = "";
	If CheckParameters.DataBaseConfigurationChangedDynamically Then
		Var_Key = "Configuration";
	EndIf;
	If CheckParameters.Corrections <> Undefined Then
		Var_Key = Var_Key + "Corrections";
	EndIf;
	If CheckParameters.Extensions <> Undefined Then
		Var_Key = Var_Key + "Extensions";
	EndIf;
	If WithASchedule Then
		Var_Key = Var_Key + "Schedule";
	EndIf;
	
	StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, Var_Key);
	
	RestartTime = Common.CommonSettingsStorageLoad(
		"UserCommonSettings", 
		"TimeToRestartApplicationToApplyFixes",,,
		UserName());
	
	If Not ValueIsFilled(RestartTime) Then
		RestartTime = Date(1, 1, 1, 23, 00, 00);
	EndIf;

	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	If Not Exit Then
		SaveSchedule();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	Document = New TextDocument;
	Document.SetText(NewPatchesDetails);
	Document.Show(NStr("en = 'New patches';"));
EndProcedure

&AtClient
Procedure RestartOptionOnChange(Item)
	SetVisibilityAvailability(ThisObject);
EndProcedure

&AtClient
Procedure PlanOptionOnChange(Item)
	SetVisibilityAvailability(ThisObject);
EndProcedure

&AtClient
Procedure OptionToRemindTomorrowOnChange(Item)
	SetVisibilityAvailability(ThisObject);
EndProcedure

&AtClient
Procedure ScheduleClick(Item, StandardProcessing)
	StandardProcessing = False;
	CompletionHandler = New NotifyDescription("ScheduleClickCompletion", ThisObject);
	List = New ValueList;
	List.Add("Once", NStr("en = 'once a day';"));
	List.Add("Twice", NStr("en = 'twice a day';"));
	List.Add("OtherInterval", NStr("en = 'another interval…';"));
	
	ShowChooseFromMenu(CompletionHandler, List, Items.Schedule);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteAction(Command)
	If PossibleAction = 0 Then
		SaveSchedule();
		StandardSubsystemsClient.SkipExitConfirmation();
		Exit(True, True);
	ElsIf PossibleAction = 1 Then
		ScheduleRestart();
	ElsIf PossibleAction = 2 Then
		StandardSubsystemsClient.DisableScheduledRestart();
		RemindMeTomorrow();
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure DontRemindAgain(Command)
	DontRemindAgainAtServer();
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DontRemindAgainAtServer()
	Common.CommonSettingsStorageSave("UserCommonSettings",
		"ShowInstalledApplicationUpdatesWarning",
		False);
EndProcedure

&AtClient
Procedure RemindMeTomorrow()
	RemindTomorrowOnServer();
EndProcedure

&AtServerNoContext
Procedure RemindTomorrowOnServer()
	
	Common.SystemSettingsStorageSave("DynamicUpdateControl",
		"DateRemindTomorrow", BegOfDay(CurrentSessionDate()) + 60*60*24);
	
EndProcedure

&AtClient
Procedure ScheduleClickCompletion(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Value = "Once" Or Result.Value = "Twice" Then
		SchedulePresentation = Result;
		ScheduleChanged = True;
		CurrentSchedule.Id = Result.Value;
		CurrentSchedule.Presentation = Result.Presentation;
		CurrentSchedule.Schedule = StandardSchedule[Result.Value];
		Return;
	EndIf;
	
	CompletionsHandler = New NotifyDescription("ScheduleClickAfterSelectingAnArbitrarySchedule", ThisObject);
	ScheduleDialog1 = New ScheduledJobDialog(New JobSchedule);
	ScheduleDialog1.Show(CompletionsHandler);
EndProcedure

&AtClient
Procedure ScheduleClickAfterSelectingAnArbitrarySchedule(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	ScheduleChanged = True;
	SchedulePresentation = Result;
	CurrentSchedule.Id = "OtherInterval";
	CurrentSchedule.Presentation = String(Result);
	CurrentSchedule.Schedule = Result;
	
EndProcedure

&AtServer
Procedure SaveSchedule()
	If Not ScheduleChanged Then
		Return;
	EndIf;
	
	Common.SystemSettingsStorageSave("DynamicUpdateControl", "PatchCheckSchedule", CurrentSchedule);
EndProcedure

&AtServer
Procedure FillInTheFormDisplaySchedule()
	
	CurrentSchedule = Common.SystemSettingsStorageLoad("DynamicUpdateControl", "PatchCheckSchedule");
	If CurrentSchedule = Undefined Then
		CurrentSchedule = New Structure;
		CurrentSchedule.Insert("Id");
		CurrentSchedule.Insert("Presentation");
		CurrentSchedule.Insert("Schedule");
		CurrentSchedule.Insert("LastAlert");
		SchedulePresentation = NStr("en = 'once a day';");
	Else
		SchedulePresentation = CurrentSchedule.Presentation;
	EndIf;
	
	OnceADay = New JobSchedule;
	OnceADay.DaysRepeatPeriod = 1;
	TwiceADay = New JobSchedule;
	TwiceADay.DaysRepeatPeriod = 1;
	
	FirstRun = New JobSchedule;
	FirstRun.BeginTime = Date(01,01,01,09,00,00);
	TwiceADay.DetailedDailySchedules.Add(FirstRun);
	
	SecondLaunch = New JobSchedule;
	SecondLaunch.BeginTime = Date(01,01,01,15,00,00);
	TwiceADay.DetailedDailySchedules.Add(SecondLaunch);
	
	StandardSchedule = New Structure;
	StandardSchedule.Insert("Once", OnceADay);
	StandardSchedule.Insert("Twice", TwiceADay);
	
EndProcedure

&AtServer
Procedure SetMainText(CheckParameters, NumberOfNewPatches)
	
	OutputDetails = False;

	If NumberOfNewPatches > 5 Then
		NumberOfPatchesToOutput = 5;
	Else
		NumberOfPatchesToOutput = NumberOfNewPatches;
		OutputDetails = True;
	EndIf;
	
	DescriptionOfPatches = NewPatchesDetails;
	BriefDescriptionsOfPatches = New Array;
	For PatchNumber = 1 To NumberOfPatchesToOutput Do
		CountOfCharacters = StrFind(DescriptionOfPatches, Chars.LF);
		CountOfCharacters = ?(CountOfCharacters = 0, StrLen(DescriptionOfPatches), CountOfCharacters);
		ShortDescription = TrimAll(Left(DescriptionOfPatches, CountOfCharacters));
		DescriptionOfPatches = TrimAll(Mid(DescriptionOfPatches, CountOfCharacters));
		DescriptionShortened = False;
		If StrLen(ShortDescription) > 150 Then
			ShortDescription = Left(ShortDescription, 151);
			CountOfCharacters = StrFind(ShortDescription, " ", SearchDirection.FromEnd);
			ShortDescription = Left(ShortDescription, CountOfCharacters);
			ShortDescription = ShortDescription + "...";
			DescriptionShortened = True;
			OutputDetails = True;
		EndIf;
		
		StartOfNextPatch = StrFind(DescriptionOfPatches, "EF_");
		
		If StartOfNextPatch <> 0 Then 
			DescriptionOfPatches = Mid(DescriptionOfPatches, StartOfNextPatch);
			If Not DescriptionShortened And StartOfNextPatch > 1 Then
				ShortDescription = ShortDescription + "...";
				OutputDetails = True;
			EndIf;
		Else
			MultiLineDescription = ?(StrFind(DescriptionOfPatches, Chars.LF) = 0, False, True);
			If Not DescriptionShortened And MultiLineDescription Then
				ShortDescription = ShortDescription + "...";
				OutputDetails = True;
			EndIf;
		EndIf;
		BriefDescriptionsOfPatches.Add(TrimAll(ShortDescription));
	EndDo;
	
	BriefDescriptionOfPatches = StrConcat(BriefDescriptionsOfPatches, Chars.LF);
		
	PartsOfMessage = New Array;
	PartsOfMessage.Add(StandardSubsystemsServer.MessageTextOnDynamicUpdate(CheckParameters)); 
	If ValueIsFilled(NewPatchesDetails) Then
		PartsOfMessage.Add("");
		PartsOfMessage.Add(BriefDescriptionOfPatches);
		If OutputDetails Then
			PartsOfMessage.Add("...");
			PartsOfMessage.Add("");
			PartsOfMessage.Add(NStr("en = '<a href = ""%1"">Detailed</a>';"));
		EndIf; 
	EndIf;
	Message = StrConcat(PartsOfMessage, Chars.LF);
	
	Items.Text.Title = StringFunctions.FormattedString(Message, "LinkAction");
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityAvailability(Form)
	
	If Form.PossibleAction = 0 Then
		TitleOfPerformActionButton = NStr("en = 'Restart';");
		Form.Items.RestartTime.Enabled = False;
	ElsIf Form.PossibleAction = 1 Then
		TitleOfPerformActionButton = NStr("en = 'Schedule';");
		Form.Items.RestartTime.Enabled = True;
	ElsIf Form.PossibleAction = 2 Then
		TitleOfPerformActionButton = NStr("en = 'Remind me tomorrow';");
		Form.Items.RestartTime.Enabled = False;
	EndIf;
	
	Form.Items.FormExecuteAction.Title = TitleOfPerformActionButton;
	
EndProcedure

&AtClient
Procedure ScheduleRestart()
	StandardSubsystemsClient.DisableScheduledRestart();
	SessionDate = CommonClient.SessionDate();
	SessionTime =  Date('00010101') + (SessionDate-BegOfDay(SessionDate));
	SecondsBeforeRestart = RestartTime - SessionTime;
	If SecondsBeforeRestart < 560 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Minimum restart time: %1';"), Format(SessionTime + 600, "DF=HH:mm"));
		CommonClient.MessageToUser(MessageText,,"RestartTime");
		Return;
	EndIf;
	StandardSubsystemsClient.EnablingHandlersForWaitingForNotificationsToBeDisplayedAndRestarting(SecondsBeforeRestart);
	SaveApplicationRestartTimeSettingToApplyFixes(RestartTime);
	RemindTomorrowOnServer();
	Close();
EndProcedure 

&AtServerNoContext
Procedure SaveApplicationRestartTimeSettingToApplyFixes(RestartTime)
	Common.CommonSettingsStorageSave("UserCommonSettings",
		"TimeToRestartApplicationToApplyFixes",
		RestartTime);
EndProcedure



#EndRegion