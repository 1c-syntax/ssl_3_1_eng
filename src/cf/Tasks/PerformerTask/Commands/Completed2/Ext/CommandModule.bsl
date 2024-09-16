///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If CommandParameter = Undefined Then
		ShowMessageBox(,NStr("en = 'Tasks are not selected.';"));
		Return;
	EndIf;
		
	ClearMessages();
	For Each Task In CommandParameter Do
		BusinessProcessesAndTasksServerCall.ExecuteTask(Task, True);
		ShowUserNotification(
			NStr("en = 'The task is completed';"),
			GetURL(Task),
			String(Task));
	EndDo;
	Notify("Write_PerformerTask", New Structure("Executed", True), CommandParameter);
	
EndProcedure

#EndRegion