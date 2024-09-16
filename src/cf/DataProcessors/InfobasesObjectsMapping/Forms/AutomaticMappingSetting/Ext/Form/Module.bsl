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
	
	// 
	If Not Parameters.Property("MappingFieldsList") Then
		
		Raise NStr("en = 'This is a dependent form and opens from a different form.';", Common.DefaultLanguageCode());
		
	EndIf;
	
	MappingFieldsList = Parameters.MappingFieldsList;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateCommentLabelText();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MappingFieldsListOnChange(Item)
	
	UpdateCommentLabelText();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RunMapping(Command)
	
	NotifyChoice(MappingFieldsList.Copy());
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	NotifyChoice(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateCommentLabelText()
	
	MarkedListItemArray = CommonClientServer.MarkedItems(MappingFieldsList);
	
	If MarkedListItemArray.Count() = 0 Then
		
		NoteLabel = NStr("en = 'Mapping will be performed by internal object UUIDs only.';");
		
	Else
		
		NoteLabel = NStr("en = 'Mapping will be performed by internal object UUIDs and the selected fields.';");
		
	EndIf;
	
EndProcedure

#EndRegion
