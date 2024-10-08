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
	
	Value = Common.CommonSettingsStorageLoad(
		"TemplateOpeningSettings", 
		"PromptForTemplateOpeningMode");
	
	If Value = Undefined Then
		DontAskAgain = False;
	Else
		DontAskAgain = Not Value;
	EndIf;
	
	Value = Common.CommonSettingsStorageLoad(
		"TemplateOpeningSettings", 
		"TemplateOpeningModeView");
	
	If Value = Undefined Then
		HowToOpen = 0;
	Else
		If Value Then
			HowToOpen = 0;
		Else
			HowToOpen = 1;
		EndIf;
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.HowToOpen.ChoiceList.Clear();
		Items.HowToOpen.ChoiceList.Add(0, NStr("en = 'View only';"));
		Items.HowToOpen.ChoiceList.Add(1, NStr("en = 'Edit';"));
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	PromptForTemplateOpeningMode = Not DontAskAgain;
	TemplateOpeningModeView = ?(HowToOpen = 0, True, False);
	
	SaveTemplateOpeningModeSettings(PromptForTemplateOpeningMode, TemplateOpeningModeView);
	
	NotifyChoice(New Structure("DontAskAgain, OpeningModeView",
							DontAskAgain,
							TemplateOpeningModeView) );
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure SaveTemplateOpeningModeSettings(PromptForTemplateOpeningMode, TemplateOpeningModeView)
	
	Common.CommonSettingsStorageSave(
		"TemplateOpeningSettings", 
		"PromptForTemplateOpeningMode", 
		PromptForTemplateOpeningMode);
	
	Common.CommonSettingsStorageSave(
		"TemplateOpeningSettings", 
		"TemplateOpeningModeView", 
		TemplateOpeningModeView);
	
EndProcedure

#EndRegion
