///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Handler for launching the client application session.
// If a session is started for an offline workplace, it notifies the user
// to synchronize data with the application on the Internet
// (if the corresponding flag is set).
//
Procedure OnStart(Parameters) Export
	
	If CommonClient.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientRunParameters.IsStandaloneWorkplace Then
		ParameterName = "StandardSubsystems.SuggestDataSynchronizationWithWebApplicationOnExit";
		If ApplicationParameters[ParameterName] = Undefined Then
			ApplicationParameters.Insert(ParameterName, Undefined);
		EndIf;
		
		ApplicationParameters["StandardSubsystems.SuggestDataSynchronizationWithWebApplicationOnExit"] =
			ClientRunParameters.SynchronizeDataWithWebApplicationOnExit;
		
		If ClientRunParameters.SynchronizeDataWithWebApplicationOnStart Then
			
			ShowUserNotification(NStr("en = 'Standalone mode';"), "e1cib/app/DataProcessor.DataExchangeExecution",
				NStr("en = 'It is recommended that you synchronize the workstation data with the web application.';"), PictureLib.Information32);
			
		EndIf;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Determines the list of warnings to the user before the system shutdown.
//
// Parameters:
//  Cancel - Boolean -  indicates that the user refused to exit the program. If
//                   this parameter is set to True in the body of the handler procedure, the program will not be finished.
//  Warnings - Array -  You can add elements of the Structure type to the array,
//                            the properties of which can be found in the Standardsystem Client.Before completing the work of the system.
//
Procedure BeforeExit(Cancel, Warnings) Export
	
	StandaloneModeParameters = StandardSubsystemsClient.ClientParameter("StandaloneModeParameters");
	
	If ApplicationParameters["StandardSubsystems.SuggestDataSynchronizationWithWebApplicationOnExit"] = True
		And StandaloneModeParameters.SynchronizationWithServiceNotExecutedLongTime Then
		
		WarningParameters = StandardSubsystemsClient.WarningOnExit();
		WarningParameters.ExtendedTooltip = NStr("en = 'Data synchronization may take a while if:
	        | • The connection is slow
	        | • The amount of data to sync is big
	        | • An application update is available online';");

		WarningParameters.WarningText = NStr("en = 'Data is not synchronized with the web application.';");
		WarningParameters.CheckBoxText = NStr("en = 'Synchronize data with web application';");
		WarningParameters.Priority = 80;
		
		ActionIfFlagSet = WarningParameters.ActionIfFlagSet;
		ActionIfFlagSet.Form = "DataProcessor.DataExchangeExecution.Form.Form";
		
		FormParameters = StandaloneModeParameters.DataExchangeExecutionFormParameters;
		FormParameters = CommonClient.CopyRecursive(FormParameters, False);
		FormParameters.Insert("ShouldExitApp", True);
		ActionIfFlagSet.FormParameters = FormParameters;
		
		Warnings.Add(WarningParameters);
	EndIf;
	
EndProcedure

#EndRegion
