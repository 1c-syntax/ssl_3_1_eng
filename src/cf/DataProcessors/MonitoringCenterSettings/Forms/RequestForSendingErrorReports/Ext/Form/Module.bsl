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
	ParametersToGet = New Structure("DumpsInformation, DumpInstances, DumpInstancesApproved");
	MonitoringCenterParameters = MonitoringCenterInternal.GetMonitoringCenterParameters(ParametersToGet);
	DumpsInformation = MonitoringCenterParameters.DumpsInformation;
	Items.DumpsInformation.Height = StrLineCount(DumpsInformation);
	DumpsData = New Structure;
	DumpsData.Insert("DumpInstances", MonitoringCenterParameters.DumpInstances);
	DumpsData.Insert("DumpInstancesApproved", MonitoringCenterParameters.DumpInstancesApproved);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Yes(Command)
	Response = New Structure;
	Response.Insert("Approved", True);
	Response.Insert("DumpsInformation", DumpsInformation);
	Response.Insert("DoNotAskAgain", DoNotAskAgain);
	Response.Insert("DumpInstances", DumpsData.DumpInstances);
	Response.Insert("DumpInstancesApproved", DumpsData.DumpInstancesApproved);	
	SetMonitoringCenterParameters(Response);
	Close();
EndProcedure

&AtClient
Procedure None(Command)
	Response = New Structure;
	Response.Insert("Approved", False);
	Response.Insert("DoNotAskAgain", DoNotAskAgain);
	SetMonitoringCenterParameters(Response);
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure SetMonitoringCenterParameters(Response)
	
	NewParameters = New Structure;
	
	If Response.Approved Then
		
		// 
		If Response.DoNotAskAgain Then
			NewParameters.Insert("RequestConfirmationBeforeSending", False);
		EndIf;
		
		// 
		ParametersToGet = New Structure("DumpsInformation, DumpInstances");
		MonitoringCenterParameters = MonitoringCenterInternal.GetMonitoringCenterParameters(ParametersToGet);
		
		// 
		NewParameters.Insert("DumpInstancesApproved", Response.DumpInstancesApproved);
		For Each Record In Response.DumpInstances Do
			NewParameters.DumpInstancesApproved.Insert(Record.Key, Record.Value);
			MonitoringCenterParameters.DumpInstances.Delete(Record.Key);
		EndDo;
		
		NewParameters.Insert("DumpInstances", MonitoringCenterParameters.DumpInstances);
		
		// 
		If Response.DumpsInformation = MonitoringCenterParameters.DumpsInformation Then
			NewParameters.Insert("DumpsInformation", "");	
		EndIf;
		
	Else
		
		// 
		If Response.DoNotAskAgain Then
			NewParameters.Insert("SendDumpsFiles", 0);
			NewParameters.Insert("SendingResult", NStr("en = 'User refused to submit full dumps.';"));
			// 
			NewParameters.Insert("DumpsInformation", "");
			NewParameters.Insert("DumpInstances", New Map);
		EndIf;
		
	EndIf;    
	
	MonitoringCenterInternal.SetMonitoringCenterParametersExternalCall(NewParameters);
	
EndProcedure

#EndRegion
