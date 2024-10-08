﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ActionSelected;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InitialValue = Parameters.InitialValue;
	
	If Not ValueIsFilled(InitialValue) Then
		InitialValue = CurrentSessionDate();
	EndIf;
	
	Items.Calendar.BeginOfRepresentationPeriod = Parameters.BeginOfRepresentationPeriod;
	Items.Calendar.EndOfRepresentationPeriod = Parameters.EndOfRepresentationPeriod;
	
	Calendar = InitialValue;

	Title = Parameters.Title;
	Items.NoteText.Title = Parameters.NoteText;
	Items.NoteText.Visible = ValueIsFilled(Parameters.NoteText);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	If ActionSelected <> True Then
		NotifyChoice(Undefined);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CalendarSelection(Item, SelectedDate)
	
	ActionSelected = True;
	NotifyChoice(SelectedDate);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	SelectedDates = Items.Calendar.SelectedDates;
	
	If SelectedDates.Count() = 0 Then
		ShowMessageBox(,NStr("en = 'Please select a date.';"));
		Return;
	EndIf;
	
	ActionSelected = True;
	NotifyChoice(SelectedDates[0]);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	ActionSelected = True;
	NotifyChoice(Undefined);
	
EndProcedure

#EndRegion

