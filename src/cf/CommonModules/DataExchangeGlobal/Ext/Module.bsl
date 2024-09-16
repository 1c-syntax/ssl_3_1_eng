///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Checks whether the database configuration needs to be updated on the subordinate node.
//
Procedure CheckSubordinateNodeConfigurationUpdateRequired() Export
	
	UpdateRequired = StandardSubsystemsClient.ClientRunParameters().DIBNodeConfigurationUpdateRequired;
	CheckUpdateRequired(UpdateRequired);
	
EndProcedure

// Checks whether the database configuration in the slave node needs to be updated at startup.
//
Procedure CheckSubordinateNodeConfigurationUpdateRequiredOnStart() Export
	
	UpdateRequired = StandardSubsystemsClient.ClientParametersOnStart().DIBNodeConfigurationUpdateRequired;
	CheckUpdateRequired(UpdateRequired);
	
EndProcedure

Procedure CheckUpdateRequired(DIBNodeConfigurationUpdateRequired)
	
	If DIBNodeConfigurationUpdateRequired Then
		Explanation = NStr("en = 'The application update is received from ""%1"".
			|Install the update to continue the synchronization.';");
		Explanation = StringFunctionsClientServer.SubstituteParametersToString(Explanation, StandardSubsystemsClient.ClientRunParameters().MasterNode);
		ShowUserNotification(NStr("en = 'Install update';"), "e1cib/app/DataProcessor.DataExchangeExecution",
			Explanation, PictureLib.Warning32);
		Notify("DataExchangeCompleted");
	EndIf;
	
	AttachIdleHandler("CheckSubordinateNodeConfigurationUpdateRequired", 60 * 60, True); // 
	
EndProcedure

#EndRegion
