///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	CheckBasicCalendarUse(Cancel);
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CalendarSchedules.UpdateMultipleBusinessCalendarsUsage();
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckBasicCalendarUse(Cancel)
	
	If Ref.IsEmpty() Or Not ValueIsFilled(BasicCalendar) Then
		Return;
	EndIf;
	
	// 
	If Ref = BasicCalendar Then
		MessageText = NStr("en = 'Cannot select a calendar as a source for itself.';");
		Common.MessageToUser(MessageText, , , "Object.BasicCalendar", Cancel);
		Return;
	EndIf;
	
	//  
	// 
	
	Query = New Query;
	Query.SetParameter("Calendar", Ref);
	Query.Text = 
		"SELECT TOP 1
		|	Ref
		|FROM
		|	Catalog.BusinessCalendars AS BusinessCalendars
		|WHERE
		|	BusinessCalendars.BasicCalendar = &Calendar";
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'The calendar is a source for ""%1."" It cannot depend on another calendar.';"),
		Selection.Ref);
	Common.MessageToUser(MessageText, Selection.Ref, , "Object.BasicCalendar", Cancel);
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf