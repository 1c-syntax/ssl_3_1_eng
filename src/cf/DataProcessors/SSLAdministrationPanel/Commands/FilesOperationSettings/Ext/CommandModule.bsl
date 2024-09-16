///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormName = "DataProcessor.SSLAdministrationPanel.Form.FilesOperationSettings";
	
	If Not CommonClient.SeparatedDataUsageAvailable() Then
		FormName = FormName + "InSaaS";
	EndIf;
	
	OpenForm(
		FormName,
		New Structure,
		CommandExecuteParameters.Source,
		FormName + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
