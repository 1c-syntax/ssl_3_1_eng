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
	
		FormParameters = New Structure("MailMessage",CommandParameter);
		OpenForm("DocumentJournal.Interactions.Form.PrintEmail", FormParameters, CommandExecuteParameters.Source);
	
EndProcedure

#EndRegion