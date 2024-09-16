///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If DeletionMark Then
		
		UseScheduledJob = False;
		
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
	
		ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
		
		DataSeparationEnabled = Common.DataSeparationEnabled();
		
		If DataSeparationEnabled 
			And UseScheduledJob 
			And IsAutoDisabled Then
			
			IsAutoDisabled = False;
			
			ModuleDataExchangeInternalPublication.DeleteTasksAccordingToScriptWithError(Ref);
			
		EndIf;
	
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// 
	If DeletionMark Then
		
		DeleteScheduledJob(Cancel);
		
	EndIf;
	
	// 
	// 
	RefreshReusableValues();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	GUIDScheduledJob = "";
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DeleteScheduledJob(Cancel);
	
EndProcedure

#EndRegion

#Region Private

// Deletes a scheduled task.
//
// Parameters:
//  Cancel                     - Boolean -  flag of failure. If errors were detected during the procedure
//                                       , the failure flag is set to True.
//  Scheduled taskobject - the object of the scheduled task that needs to be deleted.
// 
Procedure DeleteScheduledJob(Cancel)
	
	SetPrivilegedMode(True);
			
	// 
	ScheduledJobObject = Catalogs.DataExchangeScenarios.ScheduledJobByID(GUIDScheduledJob);
	
	If ScheduledJobObject <> Undefined Then
		
		Try
			If Common.DataSeparationEnabled() Then
				ScheduledJobsServer.DeleteJob(ScheduledJobObject);
			Else
				ScheduledJobObject.Delete();
			EndIf;	
		Except
			MessageString = NStr("en = 'Cannot delete the scheduled job: %1';");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, 
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			DataExchangeServer.ReportError(MessageString, Cancel);
		EndTry;
	
	EndIf;
		
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf