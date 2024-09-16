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
	FormParameters.Insert("AuthorizationObject", CommandParameter);
	
	Try
		OpenForm(
			"Catalog.ExternalUsers.ObjectForm",
			FormParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window);
	Except
		ErrorInfo = ErrorInfo();
		If StrFind(ErrorProcessing.DetailErrorDescription(ErrorInfo),
		         "CauseTheException" + " " + "ErrorAsWarningDetails") > 0 Then
			
			ShowMessageBox(, ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Else
			Raise;
		EndIf;
	EndTry;
	
EndProcedure

#EndRegion
