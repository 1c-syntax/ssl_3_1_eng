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
	
	If CommonClient.SubsystemExists("OnlineUserSupport.ApplicationSettings") Then
		
		AppSetupModuleOSLClient = CommonClient.CommonModule("AppSettingsOSLClient");
		AppSetupModuleOSLClient.OpenSettingsOnlineSupportAndServices(CommandExecuteParameters);
		
	Else
		
		OpenForm(
			"DataProcessor.SSLAdministrationPanel.Form.InternetSupportAndServices",
			New Structure,
			CommandExecuteParameters.Source,
			"DataProcessor.SSLAdministrationPanel.Form.InternetSupportAndServices"
				+ ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
			CommandExecuteParameters.Window);
			
	EndIf;
	
EndProcedure

#EndRegion
