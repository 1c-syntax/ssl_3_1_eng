///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers
//

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	MultipleChoice = False;
	ReadExchangeNodeTree();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	CurParameters = SetFormParameters();
	ExpandNodes(CurParameters.Marked_SSLyf);
	Items.ExchangeNodesTree.CurrentRow = CurParameters.CurrentRow;
EndProcedure

&AtClient
Procedure OnReopen()
	CurParameters = SetFormParameters();
	ExpandNodes(CurParameters.Marked_SSLyf);
	Items.ExchangeNodesTree.CurrentRow = CurParameters.CurrentRow;
EndProcedure

#EndRegion

#Region NodeTreeFormTableItemEventHandlers
//

&AtClient
Procedure ExchangeNodesTreeSelection(Item, RowSelected, Field, StandardProcessing)
	PerformNodeChoice(False);
EndProcedure

&AtClient
Procedure ExchangeNodesTreeCheckOnChange(Item)
	ChangeMark(Items.ExchangeNodesTree.CurrentRow);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers
//

// Opens the object form that is specified in the configuration for the exchange plan where the node belongs.
&AtClient
Procedure SelectNode(Command)
	PerformNodeChoice(MultipleChoice);
EndProcedure

// Opens node form that specified as an object form.
&AtClient
Procedure ChangeNode(Command)
	KeyRef = Items.ExchangeNodesTree.CurrentData.Ref;
	If KeyRef <> Undefined Then
		OpenForm(GetFormName(KeyRef) + "ObjectForm", New Structure("Key", KeyRef));
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExchangeNodesTreeCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExchangeNodesTree.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);

EndProcedure
//

&AtClient
Procedure ExpandNodes(Marked_SSLyf) 
	If Marked_SSLyf <> Undefined Then
		For Each CurID In Marked_SSLyf Do
			CurRow = ExchangeNodesTree.FindByID(CurID);
			CurParent = CurRow.GetParent();
			If CurParent <> Undefined Then
				Items.ExchangeNodesTree.Expand(CurParent.GetID());
			EndIf;
		EndDo;
	EndIf;
EndProcedure	

&AtClient
Procedure PerformNodeChoice(IsMultiselect)
	
	If IsMultiselect Then
		Data = SelectedNodes();
		If Data.Count() > 0 Then
			NotifyChoice(Data);
		EndIf;
		Return;
	EndIf;
	
	Data = Items.ExchangeNodesTree.CurrentData;
	If Data <> Undefined And Data.Ref <> Undefined Then
		NotifyChoice(Data.Ref);
	EndIf;
	
EndProcedure

&AtServer
Function SelectedNodes(NewData = Undefined)
	
	If NewData <> Undefined Then
		// Install.
		Marked_SSLyf = New Array;
		InternalMarkSelectedNodes(ThisObject(), ExchangeNodesTree, NewData, Marked_SSLyf);
		Return Marked_SSLyf;
	EndIf;
	
	// Receive.
	Result = New Array;
	For Each CurPlan In ExchangeNodesTree.GetItems() Do
		For Each CurRow In CurPlan.GetItems() Do
			If CurRow.Check And CurRow.Ref <> Undefined Then
				Result.Add(CurRow.Ref);
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
EndFunction

&AtServer
Procedure InternalMarkSelectedNodes(CurrentObject, Data, NewData, Marked_SSLyf)
	For Each CurRow In Data.GetItems() Do
		If NewData.Find(CurRow.Ref) <> Undefined Then
			CurRow.Check = True;
			CurrentObject.SetMarksUp(CurRow);
			Marked_SSLyf.Add(CurRow.GetID());
		EndIf;
		InternalMarkSelectedNodes(CurrentObject, CurRow, NewData, Marked_SSLyf);
	EndDo;
EndProcedure

&AtServer
Function ThisObject(CurrentObject = Undefined) 
	If CurrentObject = Undefined Then
		Return FormAttributeToValue("Object");
	EndIf;
	ValueToFormAttribute(CurrentObject, "Object");
	Return Undefined;
EndFunction

&AtServer
Function GetFormName(CurrentObject = Undefined)
	Return ThisObject().GetFormName(CurrentObject);
EndFunction	

&AtServer
Procedure ReadExchangeNodeTree()
	Tree = ThisObject().GenerateNodeTree();
	ValueToFormAttribute(Tree,  "ExchangeNodesTree");
EndProcedure

&AtServer
Procedure ChangeMark(DataString1)
	DataElement = ExchangeNodesTree.FindByID(DataString1);
	ThisObject().ChangeMark(DataElement);
EndProcedure

&AtServer
Function SetFormParameters()
	
	Result = New Structure("CurrentRow, Marked_SSLyf");
	
	// Multiple item selection.
	Items.ExchangeNodesTreeCheck.Visible = Parameters.MultipleChoice;
	// Clearing marks if selection type is changed.
	If Parameters.MultipleChoice <> MultipleChoice Then
		CurrentObject = ThisObject();
		For Each CurRow In ExchangeNodesTree.GetItems() Do
			CurRow.Check = False;
			CurrentObject.SetMarksDown(CurRow);
		EndDo;
	EndIf;
	MultipleChoice = Parameters.MultipleChoice;
	
	// Positioning.
	If MultipleChoice And TypeOf(Parameters.ChoiceInitialValue) = Type("Array") Then 
		Marked_SSLyf = SelectedNodes(Parameters.ChoiceInitialValue);
		Result.Marked_SSLyf = Marked_SSLyf;
		If Marked_SSLyf.Count() > 0 Then
			Result.CurrentRow = Marked_SSLyf[0];
		EndIf;
			
	ElsIf Parameters.ChoiceInitialValue <> Undefined Then
		// Single item selection.
		Result.CurrentRow = RowIDByNode(ExchangeNodesTree, Parameters.ChoiceInitialValue);
		
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Function RowIDByNode(Data, Ref)
	For Each CurRow In Data.GetItems() Do
		If CurRow.Ref = Ref Then
			Return CurRow.GetID();
		EndIf;
		Result = RowIDByNode(CurRow, Ref);
		If Result <> Undefined Then 
			Return Result;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction

#EndRegion
