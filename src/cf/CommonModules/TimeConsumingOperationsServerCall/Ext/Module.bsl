///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Function IsBackgroundJobCompleted(JobID) Export
	
	BackgroundJob = BackgroundJobs.FindByUUID(JobID);
	If BackgroundJob = Undefined Then
		Return True;
	EndIf;
	
	If BackgroundJob.State <> BackgroundJobState.Active Then
		Return True;
	EndIf;
	
	BackgroundJob = BackgroundJob.WaitForExecutionCompletion(3);
	
	Return BackgroundJob.State <> BackgroundJobState.Active;
	
EndFunction

#EndRegion
