///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// Returns object details that can be edited
// by processing group changes to details.
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("RateSource");
	Result.Add("Markup");
	Result.Add("MainCurrency");
	Result.Add("RateCalculationFormula");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

#EndRegion

#EndRegion

#Region Private

Function CurrencyCodes() Export
	
	QueryText =
	"SELECT
	|	Currencies.Ref AS Ref,
	|	Currencies.Description AS AlphabeticCode,
	|	Currencies.DescriptionFull AS Presentation
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.RateSource <> VALUE(Enum.RateSources.MarkupForOtherCurrencyRate)
	|	AND Currencies.RateSource <> VALUE(Enum.RateSources.CalculationByFormula)";
	
	Query = New Query(QueryText);
	Return Common.ValueTableToArray(Query.Execute().Unload());
	
EndFunction

#EndRegion

#EndIf