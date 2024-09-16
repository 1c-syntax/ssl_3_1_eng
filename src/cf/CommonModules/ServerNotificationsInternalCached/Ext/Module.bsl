///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns:
//  Boolean
//
Function IsSessionSendServerNotificationsToClients() Export
	
	If CurrentRunMode() <> Undefined Then
		Return False;
	EndIf;
	
	CurrentBackgroundJob = GetCurrentInfoBaseSession().GetBackgroundJob();
	If CurrentBackgroundJob = Undefined
	 Or CurrentBackgroundJob.MethodName
	     <> Metadata.ScheduledJobs.SendServerNotificationsToClients.MethodName Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// 
//
// Returns:
//  Structure:
//   * Date - Date
//   * Connected - Boolean
//
Function LastCheckOfInteractionSystemConnection() Export
	
	Result = New Structure;
	Result.Insert("Date", '00010101');
	Result.Insert("Connected", False);
	
	Return Result;
	
EndFunction

#EndRegion
