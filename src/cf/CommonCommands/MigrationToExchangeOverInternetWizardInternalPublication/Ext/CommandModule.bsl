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
	
	FormParameters = New Structure("ExchangeNode", CommandParameter);
	OpenForm("DataProcessor.DataExchangeCreationWizard.Form.MigrationToExchangeOverInternet", 
		FormParameters, CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

#EndRegion