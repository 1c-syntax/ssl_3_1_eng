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
	
	FormParameters = New Structure(
		"Respondent, 
		|SurveyMode");
	FormParameters.Respondent = CommandParameter;
	FormParameters.SurveyMode = PredefinedValue("Enum.SurveyModes.Interview");
	
	OpenForm(
		"DataProcessor.AvailableQuestionnaires.Form", 
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, , , 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion
