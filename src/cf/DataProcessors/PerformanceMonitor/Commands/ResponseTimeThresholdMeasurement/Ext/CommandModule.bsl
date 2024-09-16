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
	OpeningParameters = New Structure("KeyOperation", CommandParameter);
	OpenForm("DataProcessor.PerformanceMonitor.Form.CalculateKeyOperationResponseTimeThreshold", OpeningParameters);
EndProcedure

#EndRegion
