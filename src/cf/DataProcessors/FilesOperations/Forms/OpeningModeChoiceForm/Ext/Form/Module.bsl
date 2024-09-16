///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DontAskAgain = False;
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
	FileOpeningOption = FilesOperations.FilesOperationSettings().FileOpeningOption;
	If FileOpeningOption = "Edit" Then
		HowToOpen = 1;
	EndIf;
	HowToOpenSavedOption = HowToOpen;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenFile(Command)
	
	If HowToOpenSavedOption <> HowToOpen Then
		OpeningMode = ?(HowToOpen = 1, "Edit", "Open");
		CommonServerCall.CommonSettingsStorageSave(
			"OpenFileSettings", "FileOpeningOption", OpeningMode,,, True);
	EndIf;
	
	If DontAskAgain = True Then
		CommonServerCall.CommonSettingsStorageSave(
			"OpenFileSettings", "PromptForEditModeOnOpenFile", False,,, True);
		
		RefreshReusableValues();
	EndIf;
	
	SelectionResult = New Structure;
	SelectionResult.Insert("DontAskAgain", DontAskAgain);
	SelectionResult.Insert("HowToOpen", HowToOpen);
	NotifyChoice(SelectionResult);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	NotifyChoice(DialogReturnCode.Cancel);
EndProcedure

#EndRegion
