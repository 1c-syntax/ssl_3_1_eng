///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Procedure ShowExchangeRatesImport(FormParameters = Undefined) Export
	
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParameters.Property("Currencies") And ClientParameters.Currencies.ExchangeRatesUpdateRequired Then
		AttachIdleHandler("CurrencyRateOperationsOutputObsoleteDataNotification", 180, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 

Function SettingsOnClient()
	
	ParameterName = "StandardSubsystems.Currencies";
	Settings = ApplicationParameters[ParameterName];
	
	If Settings = Undefined Then
		Settings = New Structure;
		Settings.Insert("LastNotificationDayStart", '00010101');
		ApplicationParameters[ParameterName] = Settings;
	EndIf;
	
	Return Settings;
	
EndFunction

Procedure NotifyRatesObsolete(Val ShouldCheckValidity = False) Export
	
	If ShouldCheckValidity And CurrenciesExchangeRatesServerCall.RatesUpToDate() Then
		Return;
	EndIf;
	
	DateStartOfDay = BegOfDay(CommonClient.SessionDate());
	Settings = SettingsOnClient();
	
	If Settings.LastNotificationDayStart >= DateStartOfDay Then
		Return;
	EndIf;
	Settings.LastNotificationDayStart = DateStartOfDay;
	
	ShowNotification(
		NStr("en = 'Outdated exchange rates';"),
		DataProcessorURL(),
		NStr("en = 'Update exchange rates';"),
		PictureLib.DialogExclamation,
		UserNotificationStatus.Important,
		"ExchangeRatesAreOutdated");
	
EndProcedure

// Displays the corresponding notification.
//
Procedure NotifyRatesAreUpdated() Export
	
	ShowUserNotification(
		NStr("en = 'Exchange rates updated';"),
		,
		NStr("en = 'The exchange rates are updated.';"),
		PictureLib.DialogInformation);
	
EndProcedure

// Displays the corresponding notification.
//
Procedure NotifyRatesUpToDate() Export
	
	ShowMessageBox(,NStr("en = 'Up-to-date exchange rates are imported.';"));
	
EndProcedure

// Returns the navigation link for notifications.
//
Function DataProcessorURL()
	Return "e1cib/app/DataProcessor.CurrenciesRatesImport";
EndFunction

Procedure ShowNotification(Text, ActionOnClick, Explanation, Picture, Var_UserNotificationStatus, UniqueKey)
	
	ShowUserNotification(
		Text,
		ActionOnClick,
		Explanation,
		Picture,
		Var_UserNotificationStatus,
		UniqueKey);
		
EndProcedure

#EndRegion
