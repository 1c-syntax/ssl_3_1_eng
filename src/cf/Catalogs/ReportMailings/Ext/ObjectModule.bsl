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
	ElsIf IsFolder Then 
		Personal = ReportMailing.IsMemberOfPersonalReportGroup(Parent);
		Return;
	EndIf;
	
	// 
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
	
	// 
	If DeletionMark And IsPrepared Then
		IsPrepared = False;
	EndIf;
	
	// 
	// 
	// 
	GroupIncludedIntoPersonalDistributionHierarchy = ReportMailing.IsMemberOfPersonalReportGroup(Parent);
	If Personal <> GroupIncludedIntoPersonalDistributionHierarchy Then
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
	// 
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
		
		// 
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

Procedure FillCheckProcessing(Cancel, CheckedAttributes) 
	
	If IsFolder Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Author) Then 
		Cancel = True;
		Common.MessageToUser(
			NStr("en = 'The ""Person responsible"" field is required.';"), ThisObject, "Author",, Cancel);
	EndIf;
		
	GroupIncludedIntoPersonalDistributionHierarchy = ReportMailing.IsMemberOfPersonalReportGroup(Parent);
		
	If Not Personal And Not Personalized And GroupIncludedIntoPersonalDistributionHierarchy Then
		Cancel = True;
		Common.MessageToUser(
			NStr("en = 'You cannot specify a group included in ""Personal distributions"" for the ""Reports to specified recipients"" distributions.';"), ThisObject, "Parent",, Cancel);
	ElsIf Not Personal And Personalized And GroupIncludedIntoPersonalDistributionHierarchy Then
		Cancel = True;
		Common.MessageToUser(
			NStr("en = 'You cannot specify a group included in ""Personal distributions"" for the ""Individual report for each recipient"" distributions.';"), ThisObject, "Parent",, Cancel);
	ElsIf Personal And Not GroupIncludedIntoPersonalDistributionHierarchy  Then
		Cancel = True;
		Common.MessageToUser(
			NStr("en = 'Specify a ""Personal distributions"" group or its subgroup for personal report distributions.';"), ThisObject, "Parent",, Cancel);
	EndIf;

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