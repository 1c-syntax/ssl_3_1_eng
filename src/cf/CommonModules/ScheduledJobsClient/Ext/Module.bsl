///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// See CommonClientOverridable.OnStart.
Procedure OnStart(Parameters) Export
	
	ClientParametersOnStart = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParametersOnStart.ShowExternalResourceLockForm Then
		Parameters.InteractiveHandler = New NotifyDescription("ShowExternalResourceLockForm", ThisObject);
	EndIf;
	
EndProcedure
	
// For internal use only.
Procedure ShowExternalResourceLockForm(Parameters, AdditionalParameters) Export
	
	FormParameters = New Structure("LockDecisionMaking", True);
	Notification = New NotifyDescription("AfterOpenOperationsWithExternalResourcesLockWindow", ThisObject, Parameters);
	OpenForm("CommonForm.ExternalResourcesOperationsLock", FormParameters,,,,, Notification);
	
EndProcedure

// For internal use only.
Procedure AfterOpenOperationsWithExternalResourcesLockWindow(Result, Parameters) Export
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

Procedure GoToScheduledJobsSetup() Export
	FileSystemClient.OpenURL("e1cib/app/DataProcessor.ScheduledAndBackgroundJobs");
EndProcedure

#EndRegion