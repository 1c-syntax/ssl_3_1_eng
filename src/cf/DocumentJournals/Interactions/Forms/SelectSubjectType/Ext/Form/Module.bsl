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
	
	FillSubjectsTypesTable();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetTableFilter(ThisObject);
	
	CurrentSubjectType = Settings.Get("CurrentSubjectType");
	If ValueIsFilled(CurrentSubjectType) Then
		
		FoundRows =  SubjectsTypesTable.FindRows(New Structure("SubjectType", CurrentSubjectType));
		
		If FoundRows.Count() > 0 Then
			Items.SubjectsTypesTable.CurrentRow = FoundRows[0].GetID();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region SubjectTypesFormsTablesItemsEventsHandlers

&AtClient
Procedure SubjectsTypesTableValueChoice(Item, Value, StandardProcessing)
	
	SelectAndClose();
	
EndProcedure

&AtClient
Procedure SubjectsTypesTableOnActivateRow(Item)
	
	CurrentData = Items.SubjectsTypesTable.CurrentData;
	
	If CurrentData <> Undefined Then
		CurrentSubjectType = CurrentData.SubjectType;
	EndIf;
	
EndProcedure

&AtClient
Procedure DontDisplayInteractionsOnChange(Item)
	
	SetTableFilter(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	SelectAndClose();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillSubjectsTypesTable()

	ListOfAvailableSubjectsTypes = Interactions.ListOfAvailableSubjectsTypes();
	ListOfAvailableSubjectsTypes.SortByPresentation();
	
	For Each ListItem In ListOfAvailableSubjectsTypes Do 
		
		NewRow = SubjectsTypesTable.Add();
		NewRow.TypePresentation       = ListItem.Presentation;
		NewRow.SubjectType             = ListItem.Value;
		NewRow.IsInteraction = ListItem.Check;
		
	EndDo;

EndProcedure

&AtClient
Procedure SelectAndClose()
	
	CurrentData = Items.SubjectsTypesTable.CurrentData;
	
	If CurrentData = Undefined Then
		Close();
	EndIf;
	
	NotifyChoice(CurrentData.SubjectType);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetTableFilter(Form)

	If Form.DontDisplayInteractions Then
		RowFilter = New Structure("IsInteraction", False);
		Form.Items.SubjectsTypesTable.RowFilter = New FixedStructure(RowFilter);
	Else
		Form.Items.SubjectsTypesTable.RowFilter = Undefined;
	EndIf;

EndProcedure

#EndRegion
