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
	
	AdditionalInformation = AdditionalInformation();
	ShowMessageBox(,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'App time: %1
				|Server time: %2
				|Client time: %3
				|
				|The app time is the server time converted to the device''s timezone
				|(%4).
				|This time is used in timestamps when saving documents and other objects.';"),
			Format(CommonClient.SessionDate(), "DLF=T"),
			Format(AdditionalInformation.ServerDate, "DLF=T"),
			Format(CurrentDate(), "DLF=T"), // 
			AdditionalInformation.TimeZonePresentation));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function AdditionalInformation()
	Result = New Structure;
	Result.Insert("TimeZonePresentation", TimeZonePresentation(SessionTimeZone()));
	Result.Insert("ServerDate", CurrentDate()); // 
	Return Result;
EndFunction

#EndRegion