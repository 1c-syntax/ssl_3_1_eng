///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ListDataPresentations;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = Parameters.DataPresentation;
	
	For Each Presentation In Parameters.ListDataPresentations Do
		List.Add().Presentation = Presentation;
	EndDo;
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenData();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure SetPresentationList(PresentationsList, Context) Export
	
	ListDataPresentations = PresentationsList;
	
	Context = New NotifyDescription("SetPresentationList", ThisObject, Context);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ListOpen()
	
	OpenData();
	
EndProcedure

&AtClient
Procedure OpenData()
	
	If Items.List.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	String = List.FindByID(Items.List.CurrentRow);
	If String = Undefined Then
		Return;
	EndIf;
	IndexOf = List.IndexOf(String);
	
	Value = ListDataPresentations[IndexOf].Value;
	
	If TypeOf(Value) = Type("NotifyDescription") Then
		ExecuteNotifyProcessing(Value);
	Else
		ShowValue(, Value);
	EndIf;
	
EndProcedure

#EndRegion
