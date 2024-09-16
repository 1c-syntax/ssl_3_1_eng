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
	
	If Not Users.IsFullUser(Undefined, True, False) Then
		Raise NStr("en = 'Insufficient rights to administer data exchange.';");
	EndIf;
	
	SetPrivilegedMode(True);
	
	RefreshNodesStatesList();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToDataExportEventLog(Command)
	
	CurrentData = Items.NodesStateList.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.InfobaseNode = Undefined Then
		Return;
	EndIf;
	
	DataExchangeClient.GoToDataEventLogModally(CurrentData.InfobaseNode, ThisObject, "DataExport");
	
EndProcedure

&AtClient
Procedure GoToDataImportEventLog(Command)
	
	CurrentData = Items.NodesStateList.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.InfobaseNode = Undefined Then
		Return;
	EndIf;
	
	DataExchangeClient.GoToDataEventLogModally(CurrentData.InfobaseNode, ThisObject, "DataImport");
	
EndProcedure

&AtClient
Procedure RefreshScreen(Command)
	
	RefreshMonitorData();
	
EndProcedure

&AtClient
Procedure More(Command)
	
	DetailsAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure RefreshNodesStatesList()
	
	NodesStateList.Clear();
	
	NodesStateList.Load(
		DataExchangeSaaS.DataExchangeMonitorTable(DataExchangeCached.SeparatedSSLExchangePlans()));
		
EndProcedure

&AtClient
Procedure RefreshMonitorData()
	
	NodesStatesListRowIndex = GetCurrentRowIndex();
	
	// 
	RefreshNodesStatesList();
	
	// 
	ExecuteCursorPositioning(NodesStatesListRowIndex);
	
EndProcedure

&AtClient
Function GetCurrentRowIndex()
	
	// 
	RowIndex = Undefined;
	
	// 
	CurrentData = Items.NodesStateList.CurrentData;
	
	If CurrentData <> Undefined Then
		
		RowIndex = NodesStateList.IndexOf(CurrentData);
		
	EndIf;
	
	Return RowIndex;
EndFunction

&AtClient
Procedure ExecuteCursorPositioning(RowIndex)
	
	If RowIndex <> Undefined Then
		
		// 
		If NodesStateList.Count() <> 0 Then
			
			If RowIndex > NodesStateList.Count() - 1 Then
				
				RowIndex = NodesStateList.Count() - 1;
				
			EndIf;
			
			// 
			Items.NodesStateList.CurrentRow = NodesStateList[RowIndex].GetID();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DetailsAtServer()
	
	Items.NodesStateListMore.Check = Not Items.NodesStateListMore.Check;
	
	Items.NodesStatesListLastSuccessfulExportDate.Visible = Items.NodesStateListMore.Check;
	Items.NodesStatesListLastSuccessfulImportDate.Visible = Items.NodesStateListMore.Check;
	Items.NodesStateListExchangePlanName.Visible = Items.NodesStateListMore.Check;
	
EndProcedure

#EndRegion