///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If CommandParameter = Undefined Then
		ShowMessageBox(,NStr("en = 'Tasks are not selected.'"));
		Return;
	EndIf;
		
	ClearMessages();
	Result = PeformTasks(CommandParameter);
	ShowUserNotification(Result.MessageText, Result.URL, Result.Explanation);
	Notify("Write_PerformerTask", New Structure("Executed", True), CommandParameter);
	
EndProcedure

&AtServer
Function PeformTasks(Val Var_Tasks)
	
	Result = New Structure;
	Result.Insert("MessageText", NStr("en = 'Tasks are completed'"));
	Result.Insert("URL", Undefined);
	Result.Insert("Explanation", "");
	For Each Task In Var_Tasks Do
		BusinessProcessesAndTasksServer.ExecuteTask(Task, True);
		If Result.URL = Undefined Then
			Result.MessageText = NStr("en = 'Task is completed'");
			Result.URL = GetURL(Task);
			Result.Explanation = String(Task);
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

#EndRegion