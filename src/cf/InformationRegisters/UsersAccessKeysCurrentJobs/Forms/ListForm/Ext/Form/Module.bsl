﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ReadOnly = True;
	
	Items.FormCancelBackgroundJob.ExtendedTooltip.Title =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cancel the background job of the access update thread immediately.
			           |Background jobs that do not respond for %1 seconds are canceled automatically.
			           |The missing background job will be started automatically.';"),
			AccessManagementInternal.MaxWaitSecondsCountOfWaitingForOneJobInThreadToBeProcessed());
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

&AtClient
Procedure CancelBackgroundJob(Command)
	
	If Items.List.CurrentData = Undefined Then
		ShowMessageBox(, NStr("en = 'Please select a background job.';"));
		Return;
	EndIf;
	
	ResultingText = "";
	CancelBackgroundJobAtServer(Items.List.CurrentData.ThreadID, ResultingText);
	
	ShowMessageBox(, ResultingText);
	
EndProcedure

&AtClient
Procedure AccessUpdateOnRecordsLevel(Command)
	
	AccessManagementInternalClient.OpenUpdateAccessFormAtRecordLevel(, True);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure CancelBackgroundJobAtServer(JobID, ResultingText)
	
	BackgroundJob = BackgroundJobs.FindByUUID(JobID);
	
	If BackgroundJob = Undefined Then
		ResultingText = NStr("en = 'Cannot find a background job by ID.';");
		Return;
	EndIf;
	
	Try
		BackgroundJob.Cancel();
		ResultingText = NStr("en = 'The background job is canceled.';");
	Except
		ErrorInfo = ErrorInfo();
		ResultingText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot cancel the background job. Reason:
			           |%1';"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;
	
EndProcedure

#EndRegion


