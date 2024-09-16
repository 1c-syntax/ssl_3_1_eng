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
	RulesKind = PredefinedValue("Enum.DataExchangeRulesTypes.ObjectsRegistrationRules");
	
	Filter              = New Structure("ExchangePlanName, RulesKind", ExchangePlanName, RulesKind);
	FillingValues = New Structure("ExchangePlanName, RulesKind", ExchangePlanName, RulesKind);
	
	DataExchangeClient.OpenInformationRegisterWriteFormByFilter(Filter, FillingValues, "DataExchangeRules", CommandExecuteParameters.Source, "ObjectsRegistrationRules");
	
EndProcedure

&AtServer
Function ExchangePlanName(Val InfobaseNode)
	
	Return DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
EndFunction

#EndRegion
