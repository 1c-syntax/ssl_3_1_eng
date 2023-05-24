///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure BeforeWrite(Cancel)
	If DataExchange.Load Or IsFolder Then
		Return;
	EndIf;
	
	// Create a scheduled dummy job (to store its ID in the data).
	SetPrivilegedMode(True);
	
	ScheduledJobsServer.BlockARoutineTask(ScheduledJob);

	Job = ScheduledJobsServer.Job(ScheduledJob);
	If Job = Undefined Then
		
		JobParameters = New Structure();
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ReportMailing);
		JobParameters.Insert("MethodName", Metadata.ScheduledJobs.ReportMailing.MethodName);
		JobParameters.Insert("UserName", ReportMailing.IBUserName(Author));
		JobParameters.Insert("Use", False);
		JobParameters.Insert("Description", JobByMailingPresentation(Description));
 		Job = ScheduledJobsServer.AddJob(JobParameters);
		
		ScheduledJob = ScheduledJobsServer.UUID(Job);
		ScheduledJobsServer.BlockARoutineTask(ScheduledJob);
	EndIf;

	SetPrivilegedMode(False);
	
	// Mapping of the mailing and job readiness flag to the mailing deletion mark.
	If DeletionMark And IsPrepared Then
		IsPrepared = False;
	EndIf;
	
	// 
	// 
	// 
	PersonalMailingsGroupSelected = (Parent = Catalogs.ReportMailings.PersonalMailings);
	If Personal <> PersonalMailingsGroupSelected Then
		Parent = ?(Personal, Catalogs.ReportMailings.PersonalMailings, Catalogs.ReportMailings.EmptyRef());
	EndIf;
EndProcedure

Procedure BeforeDelete(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	If ValueIsFilled(ScheduledJob) Then
		SetPrivilegedMode(True);
		ScheduledJobsServer.DeleteJob(ScheduledJob);
		SetPrivilegedMode(False);
	EndIf;
	
	Common.DeleteDataFromSecureStorage(Ref);
EndProcedure

Procedure OnCopy(CopiedObject)
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	ScheduledJob = Undefined;
EndProcedure

Procedure OnWrite(Cancel)
	// Called right after writing the object to the database.
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	Job = ScheduledJobsServer.Job(ScheduledJob);	
	If Job <> Undefined Then
		Changes = New Structure;
		
		EnableJob = ExecuteOnSchedule And IsPrepared;
		If Job.Use <> EnableJob Then
			Changes.Insert("Use", EnableJob);
		EndIf;
		
		// Schedule is set in the item form.
		If AdditionalProperties.Property("Schedule") 
			And TypeOf(AdditionalProperties.Schedule) = Type("JobSchedule")
			And String(AdditionalProperties.Schedule) <> String(Job.Schedule) Then
			Changes.Insert("Schedule", AdditionalProperties.Schedule);
		EndIf;
		
		UserName = ReportMailing.IBUserName(Author);
		If Job.UserName <> UserName Then
			Changes.Insert("UserName", UserName);
		EndIf;
		
		If TypeOf(Job) = Type("ScheduledJob") Then
			JobDescription = JobByMailingPresentation(Description);
			If Job.Description <> JobDescription Then
				Changes.Insert("Description", JobDescription);
			EndIf;
		EndIf;
		
		If Job.Parameters.Count() <> 1 Or Job.Parameters[0] <> Ref Then
			JobParameters = New Array;
			JobParameters.Add(Ref);
			Changes.Insert("Parameters", JobParameters);
		EndIf;
			
		If Changes.Count() > 0 Then
			ScheduledJobsServer.ChangeJob(ScheduledJob, Changes);
		EndIf;
	EndIf;
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region Private

Function JobByMailingPresentation(MailingDescription)
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Report distribution: %1';"), TrimAll(MailingDescription));
EndFunction

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf