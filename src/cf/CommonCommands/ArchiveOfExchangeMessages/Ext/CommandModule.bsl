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
	
	InfobaseNode = CommandParameter;
	
	Filter              = New Structure("InfobaseNode", InfobaseNode);
	FillingValues = New Structure("InfobaseNode", InfobaseNode);
		
	DataExchangeClient.OpenInformationRegisterWriteFormByFilter(Filter,
		FillingValues, "ExchangeMessageArchiveSettings", CommandExecuteParameters.Source);
	
EndProcedure
	
#EndRegion
