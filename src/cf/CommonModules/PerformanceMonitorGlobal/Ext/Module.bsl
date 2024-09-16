///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// The procedure finishes measuring the execution time of the key operation.
// Called from the wait handler.
//
Procedure EndTimeMeasurementAuto() Export
	
#If MobileClient Then
	If MainServerAvailable() = False Then
		Return;
	EndIf;
#EndIf
	
	PerformanceMonitorClient.StopTimeMeasurementAtClientAuto();
		
EndProcedure

// This procedure calls the function for recording measurement results on the server.
// Called from the wait handler.
//
Procedure WriteResultsAuto() Export
	
#If MobileClient Then
	If MainServerAvailable() = False Then
		Return;
	EndIf;
#EndIf
	
	PerformanceMonitorClient.WriteResultsAutoNotGlobal();
	
EndProcedure

#EndRegion
