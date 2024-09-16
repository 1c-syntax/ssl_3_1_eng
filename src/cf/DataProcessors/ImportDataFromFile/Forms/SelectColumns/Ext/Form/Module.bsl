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
	
	ColumnsList = Parameters.ColumnsList;
	ColumnsList.SortByPresentation();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ColumnsListSelection(Item, RowSelected, Field, StandardProcessing)
	ColumnsList.FindByID(RowSelected).Check = Not ColumnsList.FindByID(RowSelected).Check;
EndProcedure

&AtClient
Procedure ColumnsListOnStartEdit(Item, NewRow, Copy)
	String = ColumnsList.FindByID(Items.ColumnsList.CurrentRow);
	If StrStartsWith(String.Value, "ContactInformation_") Then
		For Each ColumnInformation In ColumnsList Do
			If StrStartsWith(ColumnInformation.Value, "AdditionalAttribute_") Then
				ColumnInformation.Check = False;
			EndIf;
		EndDo;
	ElsIf StrStartsWith(String.Value, "AdditionalAttribute_") Then
		For Each ColumnInformation In ColumnsList Do
			If StrStartsWith(ColumnInformation.Value, "ContactInformation_") Then
				ColumnInformation.Check = False;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Case(Command)
	Close(ColumnsList);
EndProcedure

#EndRegion
