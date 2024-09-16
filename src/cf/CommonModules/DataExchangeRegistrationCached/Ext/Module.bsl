///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

#Region SelectiveDataRegistration

// 
// 
//
// Parameters:
//   ExchangePlanName - String -  name of the exchange plan.
//
// Returns:
//   ПараметрыВыборочнойРегистрации - Structure
//                                  - Undefined - 
//   
//
Function SelectiveRegistrationParametersByExchangeNodeName(ExchangePlanName) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("ExchangePlanName", ExchangePlanName);
	
	Query.Text = 
	"SELECT
	|	DataExchangeRules.SelectiveRegistrationParameters AS SelectiveRegistrationParameters
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	DataExchangeRules.RulesKind = VALUE(Enum.DataExchangeRulesTypes.ObjectsRegistrationRules)
	|	AND DataExchangeRules.ExchangePlanName = &ExchangePlanName";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then // 
		
		SelectiveRegistrationParameters = Selection.SelectiveRegistrationParameters.Get();
		
		// 
		// 
		// 
		
		Return SelectiveRegistrationParameters;
		
	EndIf;
	
	Return DataExchangeRegistrationServer.NewParametersOfExchangePlanDataSelectiveRegistration(ExchangePlanName);
	
EndFunction

// 
// 
// 
//
// Returns:
//   String - 
//
// :
//
//   
//                         
//   
//                         
//   
//                         
//
Function ExchangePlanDataSelectiveRegistrationMode(ExchangePlanName) Export
	
	SettingValue = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "SelectiveRegistrationMode");
	If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName)
		And SettingValue = DataExchangeRegistrationServer.SelectiveRegistrationModeByXMLRules() Then
		
		// 
		// 
		SettingValue = DataExchangeRegistrationServer.SelectiveRegistrationModeModification();
		
	ElsIf SettingValue = Undefined Then
		
		// 
		SettingValue = DataExchangeRegistrationServer.SelectiveRegistrationModeModification();
		
	EndIf;
	
	Return SettingValue;
	
EndFunction

#EndRegion

#EndRegion