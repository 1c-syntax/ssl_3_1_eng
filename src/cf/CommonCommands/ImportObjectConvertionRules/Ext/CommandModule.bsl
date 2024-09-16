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
	
	// 
	ExchangePlanName = ExchangePlanName(CommandParameter);
	
	// 
	RulesKind = PredefinedValue("Enum.DataExchangeRulesTypes.ObjectsConversionRules");
	
	Filter              = New Structure("ExchangePlanName, RulesKind", ExchangePlanName, RulesKind);
	FillingValues = New Structure("ExchangePlanName, RulesKind", ExchangePlanName, RulesKind);
	
	DataExchangeClient.OpenInformationRegisterWriteFormByFilter(Filter, FillingValues, "DataExchangeRules", CommandExecuteParameters.Source, "ObjectsConversionRules");
	
EndProcedure

&AtServer
Function ExchangePlanName(Val InfobaseNode)
	
	Return DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
EndFunction

#EndRegion
