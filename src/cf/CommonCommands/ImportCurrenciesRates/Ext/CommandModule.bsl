﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	NotifyDescription = New NotifyDescription("ImportCurrencyRatesClient", ThisObject);
	ShowQueryBox(NotifyDescription, 
		NStr("en = 'You are about to import a file with full exchange rates data for all the periods from the service manager.
              |The exchange rates that are marked to be imported from the Internet in specific data areas will be replaced in a background job. Do you want to continue?';"), 
		QuestionDialogMode.YesNo);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ImportCurrencyRatesClient(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ImportCurrencyRates();
	
	ShowUserNotification(
		NStr("en = 'The import is scheduled.';"), ,
		NStr("en = 'The exchange rates will soon be imported in background mode.';"),
		PictureLib.DialogInformation);
	
EndProcedure

&AtServer
Procedure ImportCurrencyRates()
	
	CurrencyRateOperationsInternal.ImportCurrencyRates();
	
EndProcedure

#EndRegion
