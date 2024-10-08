﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.InfoLoopDetected.Title = StringFunctions.FormattedString(
		Items.InfoLoopDetected.Title, 
		DataExchangeLoopControl.AllLoopedNodesPresentation());
		
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Settings.InfobaseNode AS InfobaseNode,
		|	Settings.ExchangeDataRegistrationOnLoop AS ExchangeDataRegistrationOnLoop
		|FROM
		|	InformationRegister.CommonInfobasesNodesSettings AS Settings
		|WHERE
		|	Settings.IsLoopDetected";
	
	Table = Query.Execute().Unload();
	NodeTable_.Load(Table);
	
	If NodeTable_.Count() > 0 Then
		
		Items.GroupThisInfobase.Visible = True;
		Items.GroupAnotherInfobase.Visible = False;
		
	Else
		
		Items.GroupThisInfobase.Visible = False;
		Items.GroupAnotherInfobase.Visible = True;
		
		Items.InformationAnotherInfobase.Title = StringFunctions.FormattedString(
			Items.InformationAnotherInfobase.Title,
			DataExchangeLoopControl.InfobaseWithSuspendedRegistrationPresentation());
		
	EndIf;
		
	SetConditionalAppearance();
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersNodeTable_

&AtClient
Procedure NodeTable_Selection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "NodeTable_ExchangeDataRegistrationOnLoop" Then
		
		String = NodeTable_.FindByID(RowSelected);
		String.ExchangeDataRegistrationOnLoop = Not String.ExchangeDataRegistrationOnLoop;
		
		PauseResumeRegistration(String.InfobaseNode, String.ExchangeDataRegistrationOnLoop);
		
	ElsIf Field.Name = "NodeTable_UnregistreredData" Then
		
		String = NodeTable_.FindByID(RowSelected);
		FormParameters = New Structure("InfobaseNode", String.InfobaseNode);
		
		OpenForm("InformationRegister.ObjectsUnregisteredDuringLoop.ListForm", FormParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PauseResumeRegistration(InfobaseNode, ExchangeDataRegistrationOnLoop)
	
	SetPrivilegedMode(True);
	
	Try 
		
		InformationRegisters.CommonInfobasesNodesSettings.SetLoop(
			InfobaseNode,, 
			ExchangeDataRegistrationOnLoop);
		
	Except
		
		WriteLogEvent(, EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseForm(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// 
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("NodeTable_ExchangeDataRegistrationOnLoop");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NodeTable_.ExchangeDataRegistrationOnLoop");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Text = NStr("en = 'Resume registration';");
	Item.Appearance.SetParameterValue("Text", Text);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", WebColors.Blue);
	
	// 
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("NodeTable_ExchangeDataRegistrationOnLoop");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NodeTable_.ExchangeDataRegistrationOnLoop");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Text = NStr("en = 'Terminate registration';");
	Item.Appearance.SetParameterValue("Text", Text);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", WebColors.Blue);

	// GoTo
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("NodeTable_UnregistreredData");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NodeTable_.InfobaseNode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Text = NStr("en = 'Navigate';");
	Item.Appearance.SetParameterValue("Text", Text);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", WebColors.Blue);
	
EndProcedure

#EndRegion
