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
	
	If Not ValueIsFilled(CommandParameter) Then
		Return;
	EndIf;
	
	OpenForm("CommonForm.RelatedDocuments",
		New Structure("FilterObject", CommandParameter),
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Source.UniqueKey,
			CommandExecuteParameters.Window);

EndProcedure

#EndRegion
