///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Outputs a request to send dumps.
//
Procedure MonitoringCenterDumpSendingRequest() Export
	MonitoringCenterClientInternal.NotifyRequestForSendingDumps();
EndProcedure

// Outputs a request to collect and send dumps (once).
//
Procedure MonitoringCenterDumpCollectionAndSendingRequest() Export
	MonitoringCenterClientInternal.NotifyRequestForReceivingDumps();
EndProcedure

// Displays a request for administrator contact information.
//
Procedure MonitoringCenterContactInformationRequest() Export
	MonitoringCenterClientInternal.NotifyContactInformationRequest();
EndProcedure

#EndRegion
