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
	OpenForm("Task.PerformerTask.Form.TasksBySubject",
		New Structure("FilterValue", CommandParameter),
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Source.UniqueKey,
			CommandExecuteParameters.Window);	
EndProcedure

#EndRegion