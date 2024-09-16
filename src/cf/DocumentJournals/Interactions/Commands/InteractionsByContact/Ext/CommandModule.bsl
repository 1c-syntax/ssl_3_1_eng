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
	
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Contact", CommandParameter);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("InteractionType", "Contact");
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterStructure1);
	FormParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	
	OpenForm(
		"DocumentJournal.Interactions.Form.ParametricListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Source.UniqueKey,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
