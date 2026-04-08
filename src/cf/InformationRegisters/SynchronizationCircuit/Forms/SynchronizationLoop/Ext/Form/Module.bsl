///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

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
	|	Settings.ExchangeDataRegistrationOnLoop AS ExchangeDataRegistrationOnLoop,
	|	Settings.DisableSynchronizationCircuitMonitoring AS DisableSynchronizationCircuitMonitoring
	|FROM
	|	InformationRegister.CommonInfobasesNodesSettings AS Settings
	|WHERE
	|	Settings.IsLoopDetected
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	Settings.InfobaseNode AS InfobaseNode
	|FROM
	|	InformationRegister.CommonInfobasesNodesSettings AS Settings
	|WHERE
	|	Settings.DisableSynchronizationCircuitMonitoring";
	
	QueryResult = Query.ExecuteBatch();
	
	NodeTable_.Load(QueryResult[0].Unload());
	If NodeTable_.Count() > 0 Then
		
		Items.GroupThisInfobase.Visible = True;
		Items.FormSwitchControl.Visible = False;
		Items.GroupAnotherInfobase.Visible = False;
		
	Else
		
		Items.GroupThisInfobase.Visible = False;
		Items.FormSwitchControl.Visible = True;
		Items.GroupAnotherInfobase.Visible = True;
		
		Items.InformationAnotherInfobase.Title = StringFunctions.FormattedString(
			Items.InformationAnotherInfobase.Title,
			DataExchangeLoopControl.InfobaseWithSuspendedRegistrationPresentation());
		
	EndIf;
	
	SynchronizationLoopMonitoringIsEnabled = QueryResult[1].IsEmpty();
	LoopingWarningIsHidden = DataExchangeLoopControl.LoopingWarningIsHiddenFromUser();
	
	SetConditionalAppearance();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FormElementHeaders();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersNodeTable_

&AtClient
Procedure NodeTable_DisableSynchronizationCircuitMonitoringOnChange(Item)
	
	CurrentRowData = Items.NodeTable_.CurrentData;
	If CurrentRowData = Undefined Then
		
		Return;
		
	EndIf;
	
	LoopControlManagement(CurrentRowData.InfobaseNode, CurrentRowData.DisableSynchronizationCircuitMonitoring);
	
EndProcedure

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

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseForm(Command)
	
	Notify("ChangingVisibilityOfLoopingWarnings");
	Close();
	
EndProcedure

&AtClient
Procedure SynchronizationCircuit(Command)
	
	OpenForm("InformationRegister.SynchronizationCircuit.ListForm");
	
EndProcedure

&AtClient
Procedure SwitchControl(Command)
	
	SwitchControlAtServer();
	FormElementHeaders();
	
EndProcedure

&AtClient
Procedure DisplayLoopingWarning(Command)
	
	LoopingWarningIsHidden = Not LoopingWarningIsHidden;
	DataExchangeServerCall.HideShowLoopingWarningFromUser(LoopingWarningIsHidden);
	FormElementHeaders();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FormElementHeaders()
	
	If SynchronizationLoopMonitoringIsEnabled = True Then
		
		LineHeader = NStr("en = 'Disable control'", CommonClient.DefaultLanguageCode());
		
	Else
		
		LineHeader = NStr("en = 'Enable control'", CommonClient.DefaultLanguageCode());
		
	EndIf;
	
	Items.FormSwitchControl.Title = LineHeader;
	
	
	If LoopingWarningIsHidden = True Then
		
		LineHeader = NStr("en = 'Show synchronization loop warning'", CommonClient.DefaultLanguageCode());
		
	Else
		
		LineHeader = NStr("en = 'Hide synchronization loop warning'", CommonClient.DefaultLanguageCode());
		
	EndIf;
	
	Items.FormDisplayLoopingWarning.Title = LineHeader;
	
EndProcedure

&AtServer
Function SubAssetsWithDetectedLooping()
	
	Query = New Query(
	"SELECT DISTINCT
	|	SynchronizationCircuit.InfobaseNode AS ExchangePlanNode
	|FROM
	|	InformationRegister.SynchronizationCircuit AS SynchronizationCircuit
	|		INNER JOIN InformationRegister.CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings
	|		ON SynchronizationCircuit.InfobaseNode = CommonInfobasesNodesSettings.InfobaseNode
	|WHERE
	|	NOT SynchronizationCircuit.InfobaseNode IS NULL");
	
	Return Query.Execute().Unload().UnloadColumn("ExchangePlanNode");
	
EndFunction

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

&AtServer
Procedure SwitchControlAtServer()
	
	SubAssetsWithDetectedLooping = SubAssetsWithDetectedLooping();
	For Each ExchangePlanNode In SubAssetsWithDetectedLooping Do
		
		InformationRegisters.CommonInfobasesNodesSettings.SetLoop(ExchangePlanNode, , , SynchronizationLoopMonitoringIsEnabled);
		
	EndDo;
	
	SynchronizationLoopMonitoringIsEnabled = Not SynchronizationLoopMonitoringIsEnabled;
	If Not SynchronizationLoopMonitoringIsEnabled Then
		
		DataExchangeServerCall.HideShowLoopingWarningFromUser(True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Resume registration
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("NodeTable_ExchangeDataRegistrationOnLoop");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NodeTable_.ExchangeDataRegistrationOnLoop");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Text = NStr("en = 'Resume registration'");
	Item.Appearance.SetParameterValue("Text", Text);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", WebColors.Blue);
	
	// Terminate registration
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("NodeTable_ExchangeDataRegistrationOnLoop");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NodeTable_.ExchangeDataRegistrationOnLoop");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Text = NStr("en = 'Terminate registration'");
	Item.Appearance.SetParameterValue("Text", Text);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", WebColors.Blue);

	// Navigate
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("NodeTable_UnregistreredData");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NodeTable_.InfobaseNode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Text = NStr("en = 'Navigate'");
	Item.Appearance.SetParameterValue("Text", Text);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", WebColors.Blue);
	
EndProcedure

&AtServer
Procedure LoopControlManagement(Val InfobaseNode, Val DisableSynchronizationCircuitMonitoring)
	
	SetPrivilegedMode(True);
	
	Try 
		
		InformationRegisters.CommonInfobasesNodesSettings.SetLoop(
			InfobaseNode,,, DisableSynchronizationCircuitMonitoring);
		
	Except
		
		WriteLogEvent(, EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	
EndProcedure

#EndRegion
