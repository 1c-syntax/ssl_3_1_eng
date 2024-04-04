///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// 
// 
// 
//
// Parameters:
//  Notification             - NotifyDescription -  contains a handler that is called after
//                                    confirming that the update was received legally.
//  TerminateApplication - Boolean -  shut down the system if the user
//                                    indicated that the update was not received legally.
//
Procedure ShowLegitimateSoftwareCheck(Notification, TerminateApplication = False) Export
	
	If StandardSubsystemsClient.IsBaseConfigurationVersion() Then
		ExecuteNotifyProcessing(Notification, True);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowRestartWarning", TerminateApplication);
	FormParameters.Insert("OpenProgrammatically", True);
	
	OpenForm("DataProcessor.LegitimateSoftware.Form", FormParameters,,,,, Notification);
	
EndProcedure

#EndRegion

#Region Internal

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart(Parameters) Export
	
	// 
	// 
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If Not ClientParameters.Property("CheckLegitimateSoftware") Then
		Return;
	EndIf;
	
	Parameters.InteractiveHandler = New NotifyDescription(
		"LegitimateSoftwareCheckInteractiveHandler", ThisObject);
	
EndProcedure

// For internal use only. Continue with the procedure to check the legality of receiving an update on Startup.
Procedure LegitimateSoftwareCheckInteractiveHandler(Parameters, Context) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("OpenProgrammatically", True);
	FormParameters.Insert("ShowRestartWarning", True);
	FormParameters.Insert("SkipRestart", True);
	
	OpenForm("DataProcessor.LegitimateSoftware.Form", FormParameters, , , , ,
		New NotifyDescription("AfterCloseLegitimateSoftwareCheckFormOnStart",
			ThisObject, Parameters));
	
EndProcedure

#EndRegion

#Region Private

// For internal use only. Continue with the procedure to check the legality of receiving an update on Startup.
Procedure AfterCloseLegitimateSoftwareCheckFormOnStart(Result, Parameters) Export
	
	If Result <> True Then
		Parameters.Cancel = True;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

#EndRegion
