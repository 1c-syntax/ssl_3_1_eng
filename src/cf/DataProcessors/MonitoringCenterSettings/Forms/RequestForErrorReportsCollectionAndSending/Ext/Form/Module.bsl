///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToSettingsClick(Item)
	Close();
	OpenForm("DataProcessor.MonitoringCenterSettings.Form.MonitoringCenterSettings");
EndProcedure

&AtClient
Procedure Yes(Command)
	NewParameters = New Structure("SendDumpsFiles", 1);
	SetMonitoringCenterParameters(NewParameters);
	Close();
EndProcedure

&AtClient
Procedure None(Command)
	NewParameters = New Structure("SendDumpsFiles", 0);
	NewParameters.Insert("SendingResult", NStr("en = 'User refused to submit full dumps.';"));
	SetMonitoringCenterParameters(NewParameters);
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure SetMonitoringCenterParameters(NewParameters)
	MonitoringCenterInternal.SetMonitoringCenterParametersExternalCall(NewParameters);
EndProcedure

#EndRegion

