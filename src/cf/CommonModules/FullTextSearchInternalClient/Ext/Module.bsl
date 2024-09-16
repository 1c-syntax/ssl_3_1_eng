///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Procedure ShowExclusiveChangeModeWarning() Export
	
	QueryText = 
		NStr("en = 'To change the full-text search mode, close all sessions,
		           |except for the current user session.';");
	
	Buttons = New ValueList;
	Buttons.Add("ActiveUsers", NStr("en = 'Active users';"));
	Buttons.Add(DialogReturnCode.Cancel);
	
	Handler = New NotifyDescription("AfterDisplayWarning", ThisObject);
	ShowQueryBox(Handler, QueryText, Buttons,, "ActiveUsers");
	
EndProcedure

Procedure AfterDisplayWarning(Response, ExecutionParameters) Export
	
	If Response = "ActiveUsers" Then
		StandardSubsystemsClient.OpenActiveUserList();
	EndIf
	
EndProcedure

#EndRegion