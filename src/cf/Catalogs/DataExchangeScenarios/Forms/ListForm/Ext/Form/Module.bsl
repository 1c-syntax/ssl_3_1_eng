///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableDisableScheduledJob(Command)
	
	SelectedRows = Items.List.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = Items.List.CurrentData;
	
	ScenariosCollection = New Array;
	For Each Scenario In SelectedRows Do
		
		RowData = Items.List.RowData(Scenario);
		
		If RowData.DeletionMark Then
			Continue;
		EndIf;
		
		ScenariosCollection.Add(Scenario);
		
	EndDo;
	
	EnableDisableScheduledJobAtServer(ScenariosCollection, Not CurrentData.UseScheduledJob);
	
	// 
	Items.List.Refresh();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure EnableDisableScheduledJobAtServer(ScenariosCollection, UseScheduledJob)
	
	BeginTransaction();
	Try
		Block = New DataLock;
		For Each Scenario In ScenariosCollection Do
			LockItem = Block.Add("Catalog.DataExchangeScenarios");
			LockItem.SetValue("Ref", Scenario);
		EndDo;
		Block.Lock();
		
		For Each Scenario In ScenariosCollection Do
			LockDataForEdit(Scenario);
			ScenarioObject = Scenario.GetObject(); // CatalogObject.DataExchangeScenarios
			ScenarioObject.UseScheduledJob = UseScheduledJob;
			ScenarioObject.Write();
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion
