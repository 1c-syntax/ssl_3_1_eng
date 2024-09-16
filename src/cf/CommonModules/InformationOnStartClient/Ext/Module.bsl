///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Called from the wait handler, opens the information window.
Procedure Show() Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
		ModulePerformanceMonitorClient.TimeMeasurement("DataOpeningTimeOnStart");
	EndIf;
	
	If CommonClient.SubsystemExists("OnlineUserSupport.Ads") Then
		ModuleAdvertisingManagerClient = CommonClient.CommonModule("WorkingWithAdsClient");
		ModuleAdvertisingManagerClient.Show();
	Else
		OpenForm("DataProcessor.InformationOnStart.Form");
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParameters.Property("InformationOnStart") And ClientParameters.InformationOnStart.Show Then
		AttachIdleHandler("ShowInformationAfterStart", 0.2, True);
	EndIf;
	
EndProcedure

#EndRegion
