///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Procedure ShowExchangeRatesImport(FormParameters = Undefined) Export
	
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParameters.Property("Currencies") And ClientParameters.Currencies.ExchangeRatesUpdateRequired Then
		AttachIdleHandler("CurrencyRateOperationsOutputObsoleteDataNotification", 180, True);
	EndIf;
	
EndProcedure

// See StandardSubsystemsClient.OnReceiptServerNotification.
Procedure OnReceiptServerNotification(NameOfAlert, Result) Export
	
	If NameOfAlert <> "StandardSubsystems.Currencies.ExchangeRatesUpdateRequired" Then
		Return;
	EndIf;
	
	NotifyRatesObsolete();
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Update currency rates.

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

Procedure NotifyRatesObsolete(Val CheckRelevance = False) Export
	
	If CheckRelevance And CurrenciesExchangeRatesServerCall.RatesUpToDate() Then
		Return;
	EndIf;
	
	DateStartOfDay = BegOfDay(CommonClient.SessionDate());
	Settings = SettingsOnClient();
	
	If Settings.LastNotificationDayStart >= DateStartOfDay Then
		Return;
	EndIf;
	Settings.LastNotificationDayStart = DateStartOfDay;
	
	ShowUserNotification(
		NStr("en = 'Outdated exchange rates';"),
		DataProcessorURL(),
		NStr("en = 'Update exchange rates';"),
		PictureLib.Warning32,
		UserNotificationStatus.Important,
		"ExchangeRatesAreOutdated");
	
EndProcedure

// Displays the update notification.
//
Procedure NotifyRatesAreUpdated() Export
	
	ShowUserNotification(
		NStr("en = 'Exchange rates updated';"),
		,
		NStr("en = 'The exchange rates are updated.';"),
		PictureLib.Information32);
	
EndProcedure

// Displays the update notification.
//
Procedure NotifyRatesUpToDate() Export
	
	ShowMessageBox(,NStr("en = 'Актуальные курсы валют успешно загружены.';"));
	
EndProcedure

// Returns a notification URL.
//
Function DataProcessorURL()
	Return "e1cib/app/DataProcessor.CurrenciesRatesImport";
EndFunction

#EndRegion
