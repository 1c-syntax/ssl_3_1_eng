///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

// Parameters:
//  CommandParameter - Structure
//                  - Undefined
//  CommandExecuteParameters - CommandExecuteParameters
// 
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PeriodClosingDatesInternalClient.OpenDataImportRestrictionDates(
		?(CommandParameter <> Undefined, CommandParameter.Source, Undefined));

EndProcedure

#EndRegion
