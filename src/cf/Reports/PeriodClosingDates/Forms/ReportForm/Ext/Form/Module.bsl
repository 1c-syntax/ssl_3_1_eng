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
	
	SetOptionAtServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FirstOption(Command)
	
	SetOptionAtServer(1);
	
EndProcedure

&AtClient
Procedure SecondOption(Command)
	
	SetOptionAtServer(2);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetOptionAtServer(Variant = 0)
	
	Reports.PeriodClosingDates.SetOption(ThisObject, Variant);
	
EndProcedure

#EndRegion
