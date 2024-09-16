///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(BulkEmail, Parameters)
	EventLogParameters = EventLogParameters(BulkEmail);
	If EventLogParameters = Undefined Then
		ShowMessageBox(, NStr("en = 'Report distribution has not been started yet.';"));
		Return;
	EndIf;
	OpenForm("DataProcessor.EventLog.Form", EventLogParameters, ThisObject);
EndProcedure

#EndRegion

#Region Private

&AtServer
Function EventLogParameters(BulkEmail)
	Return ReportMailing.EventLogParameters(BulkEmail);
EndFunction

#EndRegion
