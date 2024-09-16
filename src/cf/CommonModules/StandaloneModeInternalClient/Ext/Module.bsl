///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// 

// Checks the offline workplace setting and notifies you of an error.
Procedure BeforeStart(Parameters) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientParameters.Property("RestartAfterStandaloneWorkstationSetup") Then
		Parameters.Cancel = True;
		Parameters.Restart = True;
		Return;
	EndIf;
	
	If Not ClientParameters.Property("StandaloneWorkstationSetupError") Then
		Return;
	EndIf;
	
	Parameters.Cancel = True;
	Parameters.InteractiveHandler = New NotifyDescription(
		"OnCheckStandaloneWorkstationSetupInteractiveHandler", ThisObject);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// 

// Warns about an error setting up an offline workplace.
Procedure OnCheckStandaloneWorkstationSetupInteractiveHandler(Parameters, NotDefined) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	StandardSubsystemsClient.ShowMessageBoxAndContinue(
		Parameters, ClientParameters.StandaloneWorkstationSetupError);
	
EndProcedure

#EndRegion
