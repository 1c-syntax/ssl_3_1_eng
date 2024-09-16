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
	
	PeriodForAccumulationRegisters = EndOfPeriod(AddMonth(CurrentSessionDate(), -1));
	PeriodForAccountingRegisters = EndOfPeriod(CurrentSessionDate());
	
	Items.PeriodForAccountingRegisters.Enabled  = Parameters.AccountingReg;
	Items.PeriodForAccumulationRegisters.Enabled = Parameters.AccumulationReg;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodForAccumulationRegistersOnChange(Item)
	
	PeriodForAccumulationRegisters = EndOfPeriod(PeriodForAccumulationRegisters);
	
EndProcedure

&AtClient
Procedure PeriodForAccountingRegistersOnChange(Item)
	
	PeriodForAccountingRegisters = EndOfPeriod(PeriodForAccountingRegisters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	SelectionResult = New Structure("PeriodForAccumulationRegisters, PeriodForAccountingRegisters");
	FillPropertyValues(SelectionResult, ThisObject);
	
	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Function EndOfPeriod(Date)
	
	Return EndOfDay(EndOfMonth(Date));
	
EndFunction

#EndRegion
