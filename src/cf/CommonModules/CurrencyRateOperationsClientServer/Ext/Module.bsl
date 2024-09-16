///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Converts the amount from the current currency to the new currency based on their exchange rate parameters. 
// Options currencies it is possible to function Remotecharset.Getcurrencies.
//
// Parameters:
//   Sum                  - Number     -  the amount should be recalculated.
//
//   SourceRateParameters - Structure - :
//    * Currency    - CatalogRef.Currencies -  link to the currency being converted.
//    * Rate      - Number -  the exchange rate of the currency being converted.
//    * Repetition - Number -  multiplicity of the currency being recalculated.
//
//   NewRateParameters   - Structure - :
//    * Currency    - CatalogRef.Currencies -  link to the currency that is being converted to.
//    * Rate      - Number -  the exchange rate of the currency that is being converted.
//    * Repetition - Number -  the multiple of the currency that is being converted.
//
// Returns: 
//   Number - 
//
Function ConvertAtRate(Sum, SourceRateParameters, NewRateParameters) Export
	If SourceRateParameters.Currency = NewRateParameters.Currency
		Or (SourceRateParameters.Rate = NewRateParameters.Rate 
			And SourceRateParameters.Repetition = NewRateParameters.Repetition) Then
		
		Return Sum;
	EndIf;
	
	If SourceRateParameters.Rate = 0
		Or SourceRateParameters.Repetition = 0
		Or NewRateParameters.Rate = 0
		Or NewRateParameters.Repetition = 0 Then
		
		Return 0;
	EndIf;
	
	Return Round((Sum * SourceRateParameters.Rate * NewRateParameters.Repetition) 
		/ (NewRateParameters.Rate * SourceRateParameters.Repetition), 2);
EndFunction

#EndRegion
