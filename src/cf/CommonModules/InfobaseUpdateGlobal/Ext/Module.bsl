///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Checks the status of the deferred update. If the update failed
// with errors, it informs the user and administrator about it.
//
Procedure CheckDeferredUpdateStatus() Export
	
#If MobileClient Then
	If MainServerAvailable() = False Then
		Return;
	EndIf;
#EndIf
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientParameters.Property("ShowInvalidHandlersMessage") Then
		OpenForm("DataProcessor.ApplicationUpdateResult.Form.ApplicationUpdateResult");
	Else
		InfobaseUpdateClient.NotifyDeferredHandlersNotExecuted();
	EndIf;
	
EndProcedure

#EndRegion
