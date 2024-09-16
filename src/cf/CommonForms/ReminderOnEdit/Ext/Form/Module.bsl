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
	
	DontShowAgain = False;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SystemInfo = New SystemInfo;
	
	If StrFind(SystemInfo.UserAgentInformation, "Firefox") <> 0 Then
		Items.Additions.CurrentPage = Items.MozillaFireFox;
	Else
		Items.Additions.CurrentPage = Items.IsEmpty;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ContinueExecute(Command)
	
	If DontShowAgain = True Then
		CommonServerCall.CommonSettingsStorageSave(
			"ApplicationSettings", "ShowTooltipsOnEditFiles", False,,, True);
	EndIf;
	
	Close(True);
	
EndProcedure

#EndRegion
