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
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ArrayOfExchangePlanNodes", New Array);
	OpeningParameters.Insert("SelectionByDateOfOccurrence", Date(1,1,1));
	OpeningParameters.Insert("SelectionOfExchangeNodes", New Array);
	OpeningParameters.Insert("SelectingTypesOfWarnings", New Array); 
	OpeningParameters.Insert("OnlyHiddenRecords", True);
	
	OpenForm("InformationRegister.DataExchangeResults.Form.SynchronizationWarnings", OpeningParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
