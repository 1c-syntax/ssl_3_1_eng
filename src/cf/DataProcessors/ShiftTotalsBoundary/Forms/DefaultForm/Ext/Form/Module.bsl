///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Not TotalsAndAggregatesManagementInternal.MustMoveTotalsBorder() Then
		Cancel = True; // 
		Return;
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	TimeConsumingOperation = LongRunningOperationStartServer(UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	
	Handler = New NotifyDescription("TimeConsumingOperationCompletionClient", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, Handler, WaitSettings);
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function LongRunningOperationStartServer(UUID)
	MethodName = "DataProcessors.ShiftTotalsBoundary.ExecuteCommand";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("en = 'Totals and aggregates: Accelerated document posting and report generation';");
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteInBackground(MethodName, Undefined, StartSettings1);
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure TimeConsumingOperationCompletionClient(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		TimeConsumingOperationAfterOutputResult(False);
		Return;
	EndIf;
	If Result.Status = "Completed2" Then
		ShowUserNotification(NStr("en = 'Optimization completed successfully';"),,, PictureLib.Success32);
		TimeConsumingOperationAfterOutputResult(True);
	Else
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
	EndIf;
	
EndProcedure

&AtClient
Procedure TimeConsumingOperationAfterOutputResult(Result)
	If OnCloseNotifyDescription <> Undefined Then
		ExecuteNotifyProcessing(OnCloseNotifyDescription, Result); // 
	EndIf;
	If IsOpen() Then
		Close(Result);
	EndIf;
EndProcedure

#EndRegion