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
	
	ExchangePlanInfo = ExchangePlanInfo(CommandParameter);
	
	If ExchangePlanInfo.SeparatedMode Then
		CommonClient.MessageToUser(
			NStr("en = 'Cannot load data exchange rules in separated mode.';"));
		Return;
	EndIf;
	
	If ExchangePlanInfo.ConversionRulesAreUsed Then
		DataExchangeClient.ImportDataSyncRules(ExchangePlanInfo.ExchangePlanName);
	Else
		Filter              = New Structure("ExchangePlanName, RulesKind", ExchangePlanInfo.ExchangePlanName, ExchangePlanInfo.ORRRulesKind);
		FillingValues = New Structure("ExchangePlanName, RulesKind", ExchangePlanInfo.ExchangePlanName, ExchangePlanInfo.ORRRulesKind);
		
		DataExchangeClient.OpenInformationRegisterWriteFormByFilter(Filter, FillingValues, "DataExchangeRules", 
			CommandParameter, "ObjectsRegistrationRules");
	EndIf;
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ExchangePlanInfo(Val InfobaseNode)
	
	Result = New Structure("SeparatedMode",
		Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable());
		
	If Not Result.SeparatedMode Then
		Result.Insert("ExchangePlanName",
			DataExchangeCached.GetExchangePlanName(InfobaseNode));
			
		Result.Insert("ConversionRulesAreUsed",
			DataExchangeCached.HasExchangePlanTemplate(Result.ExchangePlanName, "ExchangeRules"));
			
		Result.Insert("ORRRulesKind", Enums.DataExchangeRulesTypes.ObjectsRegistrationRules);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion