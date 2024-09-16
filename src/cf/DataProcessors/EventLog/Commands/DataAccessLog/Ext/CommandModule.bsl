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
	
	FormParameters = New Structure;
	FormParameters.Insert("DataAccessLog", True);
	
	OpenForm("DataProcessor.EventLog.Form", FormParameters,
		CommandExecuteParameters.Source);
	
EndProcedure

#EndRegion
