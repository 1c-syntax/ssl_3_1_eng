﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// The procedure generates rows in the list of participants.
//
// Parameters:
//  Contacts  - Array -  an array containing interaction participants.
//
Procedure FillContacts(Contacts) Export
	
	Interactions.FillContactsForMeeting(Contacts, Attendees);
	
EndProcedure

// End StandardSubsystems.Interactions

// 

// Parameters:
//   Table - See AccessManagement.AccessValuesSetsTable
//
Procedure FillAccessValuesSets(Table) Export
	
	InteractionsEvents.FillAccessValuesSets(ThisObject, Table);
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)

	SetDefaultDates();
	Interactions.FillDefaultAttributes(ThisObject, FillingData);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Interactions.GenerateParticipantsList(ThisObject);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	SetDefaultDates();
	EmployeeResponsible    = Users.CurrentUser();
	Author            = Users.CurrentUser();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	If EndDate < StartDate Then

		Common.MessageToUser(
			NStr("en = 'End date cannot be earlier than Start date.';"),
			,
			"EndDate",
			,
			Cancel);

	EndIf;

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Interactions.OnWriteDocument(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

Procedure SetDefaultDates()

	StartDate = CurrentSessionDate();
	StartDate = BegOfHour(StartDate) + ?(Minute(StartDate) < 30, 1800, 3600);
	EndDate = StartDate + 1800;

EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf