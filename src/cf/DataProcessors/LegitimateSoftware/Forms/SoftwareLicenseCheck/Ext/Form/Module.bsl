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
	
	If Not Parameters.OpenProgrammatically Then
		Raise
			NStr("en = 'The data processor cannot be opened manually.';");
	EndIf;
	
	SkipRestart = Parameters.SkipRestart;
	
	DocumentTemplate = DataProcessors.LegitimateSoftware.GetTemplate(
		"UpdateDistributionTerms");
	
	WarningText = DocumentTemplate.GetText();
	FileInfobase = Common.FileInfobase();
	
	// 
	MonitoringCenterExists = Common.SubsystemExists("StandardSubsystems.MonitoringCenter");
	If MonitoringCenterExists Then
		ModuleMonitoringCenterInternal = Common.CommonModule("MonitoringCenterInternal");
		MonitoringCenterParameters = ModuleMonitoringCenterInternal.GetMonitoringCenterParametersExternalCall();
				
		If (Not MonitoringCenterParameters.EnableMonitoringCenter And  Not MonitoringCenterParameters.ApplicationInformationProcessingCenter) Then
			AllowSendStatistics = True;
			Items.SendStatisticsGroup.Visible = True;
		Else
			AllowSendStatistics = True;
			Items.SendStatisticsGroup.Visible = False;
		EndIf;
	Else
		Items.SendStatisticsGroup.Visible = False;
	EndIf;
	// End StandardSubsystems.MonitoringCenter
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
		Items.FormContinue.Representation = ButtonRepresentation.Picture;
	EndIf;
	
	CurrentItem = Items.AcceptTermsBoolean;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If FileInfobase
	   And StrFind(LaunchParameter, "UpdateAndExit") > 0 Then
		
		WriteLegitimateSoftwareConfirmation();
		Cancel = True;
		StandardSubsystemsClient.SetFormStorageOption(ThisObject, True);
		AttachIdleHandler("ConfirmSoftwareLicense", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ContinueFormMainActions(Command)
	
	Result = AcceptTermsBoolean;
	
	If Result <> True Then
		If Parameters.ShowRestartWarning And Not SkipRestart Then
			Terminate();
		EndIf;
	Else
		WriteLegalityAndStatisticsSendingConfirmation(AllowSendStatistics);
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	ElsIf Result <> True Then
		If Parameters.ShowRestartWarning And Not SkipRestart Then
			Terminate();
		EndIf;
	EndIf;
	
	Notify("LegitimateSoftware", Result);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ConfirmSoftwareLicense()
	
	StandardSubsystemsClient.SetFormStorageOption(ThisObject, False);
	
	ExecuteNotifyProcessing(OnCloseNotifyDescription, True);
	
EndProcedure

&AtServerNoContext
Procedure WriteLegalityAndStatisticsSendingConfirmation(AllowSendStatistics)
	
	WriteLegitimateSoftwareConfirmation();
	
	SetPrivilegedMode(True);
	
	MonitoringCenterExists = Common.SubsystemExists("StandardSubsystems.MonitoringCenter");
	If MonitoringCenterExists Then
		ModuleMonitoringCenterInternal = Common.CommonModule("MonitoringCenterInternal");
		
		SendStatisticsParameters = New Structure("EnableMonitoringCenter, ApplicationInformationProcessingCenter", Undefined, Undefined);
		SendStatisticsParameters = ModuleMonitoringCenterInternal.GetMonitoringCenterParametersExternalCall(SendStatisticsParameters);
		
		If (Not SendStatisticsParameters.EnableMonitoringCenter And SendStatisticsParameters.ApplicationInformationProcessingCenter) Then
			// 
			// 
			//
		Else
			If AllowSendStatistics Then
				ModuleMonitoringCenterInternal.SetMonitoringCenterParameterExternalCall("EnableMonitoringCenter", AllowSendStatistics);
				ModuleMonitoringCenterInternal.SetMonitoringCenterParameterExternalCall("ApplicationInformationProcessingCenter", False);
				SchedJob = ModuleMonitoringCenterInternal.GetScheduledJobExternalCall("StatisticsDataCollectionAndSending", True);
				ModuleMonitoringCenterInternal.SetDefaultScheduleExternalCall(SchedJob);
			Else
				ModuleMonitoringCenterInternal.SetMonitoringCenterParameterExternalCall("EnableMonitoringCenter", AllowSendStatistics);
				ModuleMonitoringCenterInternal.SetMonitoringCenterParameterExternalCall("ApplicationInformationProcessingCenter", False);
				ModuleMonitoringCenterInternal.DeleteScheduledJobExternalCall("StatisticsDataCollectionAndSending");
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure WriteLegitimateSoftwareConfirmation()
	SetPrivilegedMode(True);
	InfobaseUpdateInternal.WriteLegitimateSoftwareConfirmation();
EndProcedure

#EndRegion