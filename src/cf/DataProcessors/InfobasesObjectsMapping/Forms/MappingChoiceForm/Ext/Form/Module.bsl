///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

// 
//
// 
// 
// 
//
// 
//      
//     
//     
//
// 
//
// 
//
// 
//     
//     
//     
//     
//     
//
// 
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// 
	If Not Parameters.Property("ObjectToMap") Then
		
		Raise NStr("en = 'This is a dependent form and opens from a different form.';", Common.DefaultLanguageCode());
		
	EndIf;
	
	ObjectToMap = Parameters.ObjectToMap;
	
	Items.ObjectToMap.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Object in ""%1""';"), Parameters.Application1);
		
	Items.Header.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Object in ""%1""';"), Parameters.Application2);
	
	// 
	GenerateChoiceTable(Parameters.MaxUserFields, Parameters.UsedFieldsList, 
		Parameters.TempStorageAddress);
		
	SetChoiceTableCursor(Parameters.StartRowSerialNumber);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersChoiceTable

&AtClient
Procedure ChoiceTableSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	MakeChoice(RowSelected);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	MakeChoice(Items.ChoiceTable.CurrentRow);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure MakeChoice(Val SelectionRowID)
	If SelectionRowID=Undefined Then
		Return;
	EndIf;
		
	ChoiceData = ChoiceTable.FindByID(SelectionRowID);
	If ChoiceData<>Undefined Then
		NotifyChoice(ChoiceData.SerialNumber);
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateChoiceTable(Val FieldsTotal, Val UsedFields, Val DataAddress)
	
	// 
	ItemsToAdd = New Array;
	StringType   = New TypeDescription("String");
	For FieldNumber=1 To FieldsTotal Do
		ItemsToAdd.Add(New FormAttribute("SortField" + Format(FieldNumber, "NZ=; NG="), StringType, "ChoiceTable"));
	EndDo;
	ChangeAttributes(ItemsToAdd);
	
	// 
	ColumnGroup = Items.FieldsGrouping;
	ElementType   = Type("FormField");
	ListSize  = UsedFields.Count() - 1;
	
	For FieldNumber=0 To FieldsTotal-1 Do
		Attribute = ItemsToAdd[FieldNumber];
		
		NewColumn = Items.Add("ChoiceTable" + Attribute.Name, ElementType, ColumnGroup);
		NewColumn.DataPath = Attribute.Path + "." + Attribute.Name;
		If FieldNumber<=ListSize Then
			Field = UsedFields[FieldNumber];
			NewColumn.Visible = Field.Check;
			NewColumn.Title = Field.Presentation;
		Else
			NewColumn.Visible = False;
		EndIf;
	EndDo;
	
	// 
	If Not IsBlankString(DataAddress) Then
		ChoiceTable.Load( GetFromTempStorage(DataAddress) );
		DeleteFromTempStorage(DataAddress);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetChoiceTableCursor(Val StartRowSerialNumber)
	
	For Each String In ChoiceTable Do
		If String.SerialNumber=StartRowSerialNumber Then
			Items.ChoiceTable.CurrentRow = String.GetID();
			Break;
			
		ElsIf String.SerialNumber>StartRowSerialNumber Then
			PreviousRowIndex = ChoiceTable.IndexOf(String) - 1;
			If PreviousRowIndex>0 Then
				Items.ChoiceTable.CurrentRow = ChoiceTable[PreviousRowIndex].GetID();
			EndIf;
			Break;
			
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion
