﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.BackgroundJobProperties = Undefined Then
		
		BackgroundJobProperties = ScheduledJobsInternal
			.GetBackgroundJobProperties(Parameters.Id);
		
		If BackgroundJobProperties = Undefined Then
			Raise(NStr("en = 'The background job was not found.';"));
		EndIf;
		
		MessagesToUserAndErrorDescription = ScheduledJobsInternal
			.BackgroundJobMessagesAndErrorDescriptions(Parameters.Id);
			
		If ValueIsFilled(BackgroundJobProperties.ScheduledJobID) Then
			
			ScheduledJobID
				= BackgroundJobProperties.ScheduledJobID;
			
			ScheduledJobDescription
				= ScheduledJobsInternal.ScheduledJobPresentation(
					BackgroundJobProperties.ScheduledJobID);
		Else
			ScheduledJobDescription  = ScheduledJobsInternal.TextUndefined();
			ScheduledJobID = ScheduledJobsInternal.TextUndefined();
		EndIf;
	Else
		BackgroundJobProperties = Parameters.BackgroundJobProperties;
		FillPropertyValues(
			ThisObject,
			BackgroundJobProperties,
			"MessagesToUserAndErrorDescription,
			|ScheduledJobID,
			|ScheduledJobDescription");
	EndIf;
	
	FillPropertyValues(
		ThisObject,
		BackgroundJobProperties,
		"Id,
		|Key,
		|Description,
		|Begin,
		|End,
		|Placement,
		|State,
		|MethodName");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EventLogEvents(Command)
	EventFilter = New Structure;
	EventFilter.Insert("StartDate", Begin);
	EventFilter.Insert("EndDate", End);
	EventLogClient.OpenEventLog(EventFilter, ThisObject);
EndProcedure

#EndRegion
