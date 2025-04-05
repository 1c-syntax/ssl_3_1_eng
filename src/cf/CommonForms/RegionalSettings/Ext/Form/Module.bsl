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
Var PreviousLanguage;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Source = Parameters.Source;
	If Source = "SSLAdministrationPanel" Then
		Items.OK.Title = NStr("en = 'Change'");
		Items.OK.ToolTipRepresentation = ToolTipRepresentation.None;
		Items.ApplicationTimeZoneGroup.Visible = False;
		Title = NStr("en = 'Accounting languages'");
		AutoTitle = False;
	EndIf;
	 
	FillInTimeZones();
	
	If Common.SeparatedDataUsageAvailable() Then
	
		FileInfobase = Common.FileInfobase();
		
		AppTimeZone = GetInfoBaseTimeZone();
		If IsBlankString(AppTimeZone) Then
			AppTimeZone = TimeZone();
		EndIf;
		
		If Common.DataSeparationEnabled() Then
			Items.MainLanguageGroup.Visible = False;
			Items.AdditionalLanguagesGroup.Visible = False;
		EndIf;
		
	Else
		
		AppTimeZone = SessionTimeZone();
		
	EndIf;
	
	SetMainLanguage();
	
	Settings = New Structure;
	Settings.Insert("MultilanguageData",      True);
	
	AdditionalLanguagesCount = NationalLanguageSupportServer.AdditionalLanguagesCount();
	
	For LanguageSeqNumber = 1 To AdditionalLanguagesCount Do
		Settings.Insert("AdditionalLanguageCode" + Format(LanguageSeqNumber, "NG=0"), "");
	EndDo;
	
	NationalLanguageSupportOverridable.OnDefineSettings(Settings);
	
	LanguagesCount = Metadata.Languages.Count();
	If Not Settings.MultilanguageData Or LanguagesCount = 1 Then
		Items.AdditionalLanguagesGroup.Visible = False;
		Items.MainLanguageGroup.Visible        = False;
	Else
		DisplayAdditionalLanguagesSettings(Settings, AdditionalLanguagesCount);
	EndIf;
	
	DataToChangeMultilanguageAttributes = NationalLanguageSupportServer.DataToChangeMultilanguageAttributes();
	If DataToChangeMultilanguageAttributes <> Undefined Then
		If Not DataToChangeMultilanguageAttributes.MainLanguageChanged And Common.IsMainLanguage() Then
			WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		EndIf;
		ContinueChangingMultilingualDetails = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ContinueChangingMultilingualDetails Then
		RefillData();
		Return;
	EndIf;
	
	If FileInfobase
		And StrFind(LaunchParameter, "UpdateAndExit") > 0 Then
			AttachIdleHandler("WriteConstantsValuesAndClose", 0.1, True);
	EndIf;
	 
	TimeZoneOffset = CommonClient.SessionDate() - CurrentTimeOnTheClient();
	SetTime();
	
	If StrCompare(Source, "InitialFilling") = 0 Then
		FormClosingTime = CurrentTimeOnTheClient() + 180;
		AttachIdleHandler("AutoCloseInactiveForm", 1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetMainLanguage()
	
	DefaultLanguage = Constants.DefaultLanguage.Get();
	For Each Language In Metadata.Languages Do
		Items.DefaultLanguage.ChoiceList.Add(Language.LanguageCode, Language.Presentation());
	EndDo;
	
	If IsBlankString(DefaultLanguage) Then
		DefaultLanguage = CurrentLanguage().LanguageCode;
	EndIf;
	
	If IsBlankString(DefaultLanguage) Or Items.DefaultLanguage.ChoiceList.FindByValue(DefaultLanguage) = Undefined Then
		DefaultLanguage = Common.DefaultLanguageCode();
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayAdditionalLanguagesSettings(Settings, LanguagesCount)
	
	AttributesToAddArray = New Array;
	StringAttributeTypeDetails = New TypeDescription("String");
	BooleanAttributeTypeDetails = New TypeDescription("Boolean");
	
	For LanguageSeqNumber = 1 To LanguagesCount Do
		AttributesToAddArray.Add(New FormAttribute(LanguageSelectionFieldItemName(LanguageSeqNumber), StringAttributeTypeDetails));
		AttributesToAddArray.Add(New FormAttribute(LanguageEnableItemName(LanguageSeqNumber), BooleanAttributeTypeDetails));
	EndDo;
	
	ChangeAttributes(AttributesToAddArray);
	
	For LanguageSeqNumber = 1 To LanguagesCount Do
		
		AttributeName = LanguageSelectionFieldItemName(LanguageSeqNumber);
		LanguageEnableItemName = LanguageEnableItemName(LanguageSeqNumber);
		
		Var_Group = Items.Add(GroupItemName(LanguageSeqNumber), Type("FormGroup"), Items.RegionalSettings);
		Var_Group.Type = FormGroupType.UsualGroup;
		Var_Group.Title = GroupItemName(LanguageSeqNumber);
		Var_Group.ShowTitle = False;
		Var_Group.EnableContentChange = False;
		Var_Group.Representation = UsualGroupRepresentation.None;
		Var_Group.Group = ChildFormItemsGroup.AlwaysHorizontal;
		
		FieldUseAdditionalLanguage = Items.Add(LanguageEnableItemName,
			Type("FormField"), Var_Group);
		FieldUseAdditionalLanguage.Title = LanguageEnableItemName;
		FieldUseAdditionalLanguage.Type       = FormFieldType.CheckBoxField;
		FieldUseAdditionalLanguage.TitleLocation = FormItemTitleLocation.None;
		FieldUseAdditionalLanguage.DataPath = LanguageEnableItemName;
		FieldUseAdditionalLanguage.SetAction("OnChange", "Attachable_UseAdditionalLanguage_OnChange");
		
		FieldAdditionalLanguage = Items.Add(AttributeName,
			Type("FormField"), Var_Group);
		FieldAdditionalLanguage.Title = AttributeName;
		FieldAdditionalLanguage.Type = FormFieldType.InputField;
		FieldAdditionalLanguage.ListChoiceMode = True;
		FieldAdditionalLanguage.DataPath = AttributeName;
		FieldAdditionalLanguage.TitleLocation=FormItemTitleLocation.None;
		FieldAdditionalLanguage.AutoMarkIncomplete = True;
		FieldAdditionalLanguage.InputHint= NStr("en = 'Additional accounting language'");
		FieldAdditionalLanguage.SetAction("OnChange", "Attachable_AdditionalLanguage_OnChange");
		FieldAdditionalLanguage.SetAction("StartChoice", "Attachable_AdditionalLanguage_StartChoice");
		
	EndDo;
	
	AvailableLanguages = New Map;
	For Each ConfigurationLanguage In Metadata.Languages Do
		If StrCompare(DefaultLanguage, ConfigurationLanguage.LanguageCode) = 0  Then
			Continue;
		EndIf;
		AvailableLanguages.Insert(ConfigurationLanguage.LanguageCode, True);
	EndDo;
	
	For Each Language In Metadata.Languages Do

		For LanguageSeqNumber = 1 To LanguagesCount Do
				AttributeName = LanguageSelectionFieldItemName(LanguageSeqNumber);
				Items[AttributeName].ChoiceList.Add(Language.LanguageCode, Language.Presentation());
		EndDo;
		
	EndDo;
	
	For LanguageSeqNumber = 1 To LanguagesCount Do
		
		LanguageEnableItemName = LanguageEnableItemName(LanguageSeqNumber);
		AttributeName = LanguageSelectionFieldItemName(LanguageSeqNumber);

		ThisObject[LanguageEnableItemName] = NationalLanguageSupportServer.IsAdditionalLangUsed(LanguageSeqNumber);
		ThisObject[AttributeName] = NationalLanguageSupportServer.InfobaseAdditionalLanguageCode(LanguageSeqNumber);
		
		Items[AttributeName].Enabled = ThisObject[LanguageEnableItemName];
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function Separator()
	Return "_";
EndFunction

&AtClientAtServerNoContext
Function LanguageSelectionFieldItemName(LanguageSeqNumber)
	Return "AdditionalLanguage" + Separator() + Format(LanguageSeqNumber,"NG=0");
EndFunction

&AtClientAtServerNoContext
Function LanguageEnableItemName(LanguageSeqNumber)
	Return "UseAdditionalLanguage" + Separator() + Format(LanguageSeqNumber,"NG=0");
EndFunction

&AtClientAtServerNoContext
Function GroupItemName(LanguageSeqNumber)
	Return "Group" + Separator() + Format(LanguageSeqNumber,"NG=0");
EndFunction

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_UseAdditionalLanguage_OnChange(Item)
	
	Position = StrFind(Item.Name, Separator(), SearchDirection.FromEnd);
	
	If Position > 0 Then
		SequenceNumber = Mid(Item.Name, Position + 1);
		Items[LanguageSelectionFieldItemName(SequenceNumber)].Enabled = ThisObject[Item.Name];
	EndIf;
	
	DataChanged = True;
	
EndProcedure

&AtClient
Procedure Attachable_AdditionalLanguage_OnChange(Item)
	
	Position = StrFind(Item.Name, Separator(), SearchDirection.FromEnd);
	
	If Position > 0 Then
		CurrentItemSeqNumber = Mid(Item.Name, Position + 1);
	EndIf;
	
	NewValue = ThisObject[Item.Name];
	
	If StrCompare(PreviousLanguage, NewValue) <> 0 Then
		If StrCompare(NewValue, DefaultLanguage) = 0 Then
			DefaultLanguage = PreviousLanguage;
		Else
			For LanguageSeqNumber = 1 To AdditionalLanguagesCount Do
				If StrCompare(CurrentItemSeqNumber, LanguageSeqNumber) = 0 Then
					Continue;
				EndIf;
				If StrCompare(NewValue, ThisObject[LanguageSelectionFieldItemName(LanguageSeqNumber)]) = 0 Then
					ThisObject[LanguageSelectionFieldItemName(LanguageSeqNumber)] = PreviousLanguage;
				EndIf;
				
			EndDo;
		EndIf;
	EndIf;
	
	DataChanged = True;
	
EndProcedure

&AtClient
Procedure Attachable_AdditionalLanguage_StartChoice(Item, ChoiceData, StandardProcessing)
	PreviousLanguage = ThisObject[Item.Name];
EndProcedure

&AtClient
Procedure DefaultLanguageOnChange(Item)
	
	If StrCompare(PreviousLanguage, DefaultLanguage) <> 0 Then
		
		For LanguageSeqNumber = 1 To AdditionalLanguagesCount Do
			LanguageSelectionFieldItemName = LanguageSelectionFieldItemName(LanguageSeqNumber);
			
			If StrCompare(ThisObject[LanguageSelectionFieldItemName], DefaultLanguage) = 0 Then
				ThisObject[LanguageSelectionFieldItemName] = PreviousLanguage;
				Break;
			EndIf;
			
		EndDo;
		DataChanged = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DefaultLanguageStartChoice(Item, ChoiceData, StandardProcessing)
	PreviousLanguage = DefaultLanguage;
EndProcedure

&AtClient
Procedure AppTimeZoneOnChange(Item)
	TimeZoneOffset = TimeZoneOffset(AppTimeZone, CurrentTimeOnTheClient());
	DataChanged = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If DataCorrect() Then
		
		If Source = "SSLAdministrationPanel" And ConstantsValuesChanged() Then
			RefillData();
		Else
			WriteConstantsValuesAndClose();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AutoCloseInactiveForm()
	
	If DataChanged Then
		Items.OK.Title = NStr("en = 'OK'");
		Return;
	EndIf;
	
	If FormClosingTime < CurrentTimeOnTheClient() Then
		
		WriteConstantsValuesAndClose();
		Items.OK.Title = NStr("en = 'OK'");
		Return;
		
	EndIf;
	
	SecondsBeforeCloseForm = FormClosingTime - CurrentTimeOnTheClient();
	Seconds = SecondsBeforeCloseForm % 60;
	Minutes1 = (SecondsBeforeCloseForm - Seconds) / 60;
	MinutesAndSeconds = ?(Minutes1 > 1, String(Minutes1) + ":" + String(Seconds), String(Seconds));

	Items.OK.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'OK (%1)'"), MinutesAndSeconds);
		
	AttachIdleHandler("AutoCloseInactiveForm", 1, True);
	
EndProcedure

&AtClient
Procedure WriteConstantsValuesAndClose()
	
	WriteConstantsValues();
	Close(New Structure("Cancel", False));
	
EndProcedure

&AtClient
Procedure RefillData()
	
	ClearMessages();
	
	Items.Pages.CurrentPage = Items.Waiting;
	Items.OK.Enabled = False;
	
	ExecutionProgressNotification = New CallbackDescription("ExecutionProgress", ThisObject);
	
	TimeConsumingOperation = StartBackgroundRefillingAtServer(UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow           = False;
	WaitSettings.ExecutionProgressNotification = ExecutionProgressNotification;
	
	Handler = New CallbackDescription("AfterRefillInBackground", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function StartBackgroundRefillingAtServer(Val Var_UUID)
	
	If Not ContinueChangingMultilingualDetails Then
		MetadataListToProcess = PrepareListMetadataForProcessing(OldAndNewValuesOfConstants());
		WriteConstantsValues(MetadataListToProcess);
	EndIf;

	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Var_UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("en = 'Refill predefined items and classifiers.'");
	ExecutionParameters.RefinementErrors =
		NStr("en = 'Cannot refill predefined items and classifiers due to:'");
	
	Return TimeConsumingOperations.ExecuteInBackground("NationalLanguageSupportServer.ChangeLanguageinMultilingualDetailsConfig",
		New Structure, ExecutionParameters);
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.LongRunningOperationNewState
//  AdditionalParameters - Undefined
//
&AtClient
Procedure ExecutionProgress(Result, AdditionalParameters) Export
	
	If Result.Status = "Running"
	   And Result.Progress <> Undefined Then
	
		Progress = Result.Progress.Percent;
		Items.Progress.ToolTip = Result.Progress.Text;
		
	EndIf;
	
EndProcedure

&AtServer
Function PrepareListMetadataForProcessing(OldAndNewValuesOfConstants)
	
	ObjectsWithMultilingualAttributes = NationalLanguageSupportServer.ObjectNamesWithMultilingualAttributes();
	
	CurrentReferencesToObjects = New Map;
	
	For Each ObjectWithMultilingualAttributes In ObjectsWithMultilingualAttributes Do
		
		Settings = New Structure;
		Settings.Insert("ReferenceToLastProcessedObjects", Undefined);
		Settings.Insert("LanguageFields", ObjectWithMultilingualAttributes.Value);
		
		CurrentReferencesToObjects.Insert(ObjectWithMultilingualAttributes.Key, Settings);
	EndDo;
	
	ProcessingSettings = New Structure;
	ProcessingSettings.Insert("SettingsChangesLanguages", OldAndNewValuesOfConstants);
	ProcessingSettings.Insert("Objects", CurrentReferencesToObjects);
	
	Value = New ValueStorage(ProcessingSettings, New Deflation(9));
	
	Return Value;
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure AfterRefillInBackground(Result, AdditionalParameters) Export
	
	Items.Pages.CurrentPage = Items.RegionalSettings;
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;

	RefreshReusableValues();

	Items.Close.DefaultButton = True;
	Items.OK.Visible              = False;
	Items.Close.Visible         = True;
	CurrentItem                     = Items.Close;
	Items.Pages.CurrentPage = Items.CompletedSuccessfullyText;
	
EndProcedure

&AtClient
Function DataCorrect()
	
	If IsBlankString(DefaultLanguage) Then
		CommonClient.MessageToUser(NStr("en = 'Main application language not set'"),, Items.DefaultLanguage);
		Return False;
	EndIf;
	
	If IsBlankString(AppTimeZone) Then
		CommonClient.MessageToUser(NStr("en = 'Application time zone not set'"),, Items.AppTimeZone);
		Return False;
	EndIf;
	
	LanguagesThatWereSet = New Map;
	LanguagesThatWereSet.Insert(DefaultLanguage, True);
	
	For CurrentLanguageSeqNumber = 1 To AdditionalLanguagesCount Do
		
		If ThisObject[LanguageEnableItemName(CurrentLanguageSeqNumber)] Then
			CurrentItemName = LanguageSelectionFieldItemName(CurrentLanguageSeqNumber);
			
			If IsBlankString(ThisObject[CurrentItemName]) Then
				CommonClient.MessageToUser(NStr("en = 'Additional accounting language not set'"),, CurrentItemName);
				Return False;
			EndIf;
			
			For LanguageSeqNumber= 1 To AdditionalLanguagesCount Do
				TagName = LanguageSelectionFieldItemName(LanguageSeqNumber);
				
				If CurrentLanguageSeqNumber = LanguageSeqNumber Then
					If StrCompare(DefaultLanguage, ThisObject[TagName]) = 0 Then
						ShowMessageBox(Undefined, NStr("en = 'Invalid regional settings.'"));
						Return False;
					EndIf;
				ElsIf StrCompare(ThisObject[TagName], ThisObject[CurrentItemName]) = 0 Then
					ShowMessageBox(Undefined, NStr("en = 'Invalid regional settings.'"));
					Return False;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

&AtServer
Procedure WriteConstantsValues(MetadataListToProcess = Undefined)
	
	If Common.SeparatedDataUsageAvailable() Then
		
		If AppTimeZone <> GetInfoBaseTimeZone() Then
			SetPrivilegedMode(True);
			Try
				SetExclusiveMode(True);
				SetInfoBaseTimeZone(AppTimeZone);
				SetExclusiveMode(False);
			Except
				SetExclusiveMode(False);
				Raise;
			EndTry;
			SetPrivilegedMode(False);
			SetSessionTimeZone(AppTimeZone);
		EndIf;
		
	Else
		
		SetSessionTimeZone(AppTimeZone);
		
	EndIf;
	
	If Not Common.SeparatedDataUsageAvailable() Or Not Common.DataSeparationEnabled() Then
		
		LanguagesFillingData = New Map;
		
		LanguagesCodes = New Array;
		LanguagesCodes.Add(DefaultLanguage);
		
		For LanguageSeqNumber = 1 To AdditionalLanguagesCount Do
			LanguageEnableItemName  = LanguageEnableItemName(LanguageSeqNumber);
			LanguageSelectionFieldItemName = LanguageSelectionFieldItemName(LanguageSeqNumber);
			CodeCurrentLanguage           = "";
			If ThisObject[LanguageEnableItemName] Then
				CodeCurrentLanguage = ThisObject[LanguageSelectionFieldItemName];
				LanguagesCodes.Add(CodeCurrentLanguage);
			EndIf;
			LanguagesFillingData.Insert(LanguageSeqNumber, CodeCurrentLanguage);
		EndDo;
		
		BeginTransaction();
		Try
			
			SessionParameters.DefaultLanguage = DefaultLanguage;
			
			Constants.DefaultLanguage.Set(DefaultLanguage);
			
			For LanguageSeqNumber = 1 To AdditionalLanguagesCount Do
				LanguageEnableItemName = LanguageEnableItemName(LanguageSeqNumber);
				LanguageSelectionFieldItemName = LanguageSelectionFieldItemName(LanguageSeqNumber);
				LanguageConstantName = NationalLanguageSupportServer.LanguageConstantName(LanguageSeqNumber);
				FunctionalOptionName= NationalLanguageSupportServer.FunctionalOptionName(LanguageSeqNumber);
				
				Constants[LanguageConstantName].Set(ThisObject[LanguageSelectionFieldItemName]);
				Constants[FunctionalOptionName].Set(ThisObject[LanguageEnableItemName]);
			EndDo;
			
			Constants.DataToChangeMultilanguageAttributes.Set(MetadataListToProcess);
			
			If Common.SeparatedDataUsageAvailable() Then
				If Common.SubsystemExists("StandardSubsystems.Print") Then
					ModulePrintManager = Common.CommonModule("PrintManagement");
					ModulePrintManager.AddPrintFormsLanguages(LanguagesCodes);
				EndIf;
			EndIf;
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	
	EndIf;
	
	RefreshReusableValues();
	
EndProcedure

&AtServer
Function ConstantsValuesChanged()
	
	If Metadata.Languages.Count() = 1 Then
		Return False;
	EndIf;
	
	If StrCompare(Constants.DefaultLanguage.Get(), DefaultLanguage) <> 0 Then
		Return True;
	EndIf;
	
	For LanguageSeqNumber = 1 To AdditionalLanguagesCount Do
		
		FunctionalOptionName = NationalLanguageSupportServer.FunctionalOptionName(LanguageSeqNumber);
		LanguageEnableItemName = LanguageEnableItemName(LanguageSeqNumber);

		If (Constants[FunctionalOptionName].Get() = False
		   And ThisObject[LanguageEnableItemName] = True) Then
			Return True;
		EndIf;
		
		LanguageConstantName = NationalLanguageSupportServer.LanguageConstantName(LanguageSeqNumber);
		LanguageSelectionFieldItemName = LanguageSelectionFieldItemName(LanguageSeqNumber);
		
		If ThisObject[LanguageEnableItemName] 
		   And StrCompare(Constants[LanguageConstantName].Get(), ThisObject[LanguageSelectionFieldItemName]) <> 0 Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction


// Returns:
//   See NationalLanguageSupportServer.DescriptionOfOldAndNewLanguageSettings
//
&AtServer
Function OldAndNewValuesOfConstants()
	
	Result = NationalLanguageSupportServer.DescriptionOfOldAndNewLanguageSettings(AdditionalLanguagesCount);
	
	Result.DefaultLanguage.PreviousValue2= Constants.DefaultLanguage.Get();
	Result.DefaultLanguage.NewValue = DefaultLanguage;
	
	For LanguageSeqNumber = 1 To AdditionalLanguagesCount Do
		LanguageConstantName = NationalLanguageSupportServer.LanguageConstantName(LanguageSeqNumber);
		TagName       = LanguageSelectionFieldItemName(LanguageSeqNumber);
		Result[LanguageConstantName].PreviousValue2 = Constants[LanguageConstantName].Get();
		Result[LanguageConstantName].NewValue = ThisObject[TagName];
	EndDo;
	
	Return Result;
	
EndFunction

// 

&AtServer
Procedure FillInTimeZones()

	For Each DescriptionOfTheTimeZone In GetAvailableTimeZones() Do
	
			OffsetByDate = Date(1, 1, 1) + StandardTimeOffset(DescriptionOfTheTimeZone); 
			OffsetPresentation = StringFunctionsClientServer.SubstituteParametersToString("(UTC+%1)",
				Format(OffsetByDate, "DF=HH:mm; DE=00:00;"));
	
			TimeZonePresentation = OffsetPresentation + " " + DescriptionOfTheTimeZone;
			Items.AppTimeZone.ChoiceList.Add(DescriptionOfTheTimeZone, TimeZonePresentation);
			
	EndDo;
	
EndProcedure

&AtServerNoContext
Function TimeZoneOffset(AppTimeZone, TimeOnTheClient)
	
	UniversalSessionDate = ToUniversalTime(CurrentSessionDate(), SessionTimeZone());
	SessionDateNewTimeZone = UniversalSessionDate + StandardTimeOffset(AppTimeZone);

	Return SessionDateNewTimeZone - TimeOnTheClient + DaylightTimeOffset(AppTimeZone);
	
EndFunction

&AtClient
Procedure SetTime()
	
	SelectedTimeZoneTime = CurrentTimeOnTheClient() + TimeZoneOffset;
	AttachIdleHandler("SetTime", 1, True);
	
EndProcedure

&AtClient
Function CurrentTimeOnTheClient()

	// ACC:143-off To calculate the time offset for the form, CurrentDate is required.
	Return CurrentDate();
	// ACC:143-on 
	
EndFunction

#EndRegion