﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListExtendedTooltipURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "%1" Then
		StandardProcessing = False;
		OpenForm("DataProcessor.MarkedObjectsDeletion.Form");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False;
	OpenObject(Undefined);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenObject(Command)

	If Items.List.CurrentData = Undefined Then
		Return;
	EndIf;
	Value = Undefined;
	If Not Items.List.CurrentData.Property("Object", Value) Then
		Return;
	EndIf;
	
	ShowValue(, Value);

EndProcedure

&AtClient
Procedure Clear(Command)
	ClearUpInfoRecords();
	Items.List.Refresh();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ClearUpInfoRecords()
	RecordSet = InformationRegisters.NotDeletedObjects.CreateRecordSet();
	RecordSet.Write();
EndProcedure

#EndRegion
