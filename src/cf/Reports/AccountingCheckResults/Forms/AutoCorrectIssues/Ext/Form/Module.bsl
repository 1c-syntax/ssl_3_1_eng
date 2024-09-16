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
	
	CheckID = Parameters.CheckID;
	
	If CheckID = "StandardSubsystems.CheckCircularRefs1" Then
		QueryText = NStr("en = 'Fixing the circular references can take a long time. Do you want to fix these?';");
	ElsIf CheckID = "StandardSubsystems.CheckNoPredefinedItems" Then
		QueryText = NStr("en = 'Create the missing predefined items?';");
	EndIf;
	
	Items.QuestionLabel.Title = QueryText;
	SetCurrentPage(ThisObject, "DoQueryBox");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ResolveIssue(Command)
	
	If CheckID = "StandardSubsystems.CheckCircularRefs1" Then
		TimeConsumingOperation = ResolveIssueInBackground(CheckID);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CallbackOnCompletion = New NotifyDescription("ResolveIssueInBackgroundCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	ElsIf CheckID = "StandardSubsystems.CheckNoPredefinedItems" Then
		SetCurrentPage(ThisObject, "TroubleshootingInProgress");
		RestoreMissingPredefinedItems(CheckID);
		SetCurrentPage(ThisObject, "FixedSuccessfully");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetCurrentPage(Form, PageName)
	
	FormItems = Form.Items;
	If PageName = "TroubleshootingInProgress" Then
		FormItems.TroubleshootingIndicatorGroup.Visible         = True;
		FormItems.TroubleshootingStartIndicatorGroup.Visible   = False;
		FormItems.TroubleshootingSuccessIndicatorGroup.Visible = False;
	ElsIf PageName = "FixedSuccessfully" Then
		FormItems.TroubleshootingIndicatorGroup.Visible         = False;
		FormItems.TroubleshootingStartIndicatorGroup.Visible   = False;
		FormItems.TroubleshootingSuccessIndicatorGroup.Visible = True;
	Else // 
		FormItems.TroubleshootingIndicatorGroup.Visible         = False;
		FormItems.TroubleshootingStartIndicatorGroup.Visible   = True;
		FormItems.TroubleshootingSuccessIndicatorGroup.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Function ResolveIssueInBackground(CheckID)
	
	If TimeConsumingOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
	SetCurrentPage(ThisObject, "TroubleshootingInProgress");
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Fixing circular references';");
	
	Return TimeConsumingOperations.ExecuteInBackground("AccountingAuditInternal.FixInfiniteLoopInBackgroundJob",
		New Structure("CheckID", CheckID), ExecutionParameters);
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure ResolveIssueInBackgroundCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;

	If Result = Undefined Then
		SetCurrentPage(ThisObject, "TroubleshootingInProgress");
	
	ElsIf Result.Status = "Error" Then
		SetCurrentPage(ThisObject, "DoQueryBox");
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
	
	ElsIf Result.Status = "Completed2" Then
		SetCurrentPage(ThisObject, "FixedSuccessfully");
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure RestoreMissingPredefinedItems(CheckID) 
	
	// 
	Result = CheckByIDRule(CheckID);
	CheckRule = Result.Ref;
	
	Query = New Query;
	Query.SetParameter("CheckRule", CheckRule);
	Query.Text =
		"SELECT DISTINCT
		|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue
		|FROM
		|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
		|WHERE
		|	AccountingCheckResults.CheckRule = &CheckRule";
	Result = Query.Execute().Unload();
	
	Query = New Query;
	For Each String In Result Do
		Id    = String.ObjectWithIssue;
		MetadataObject = Common.MetadataObjectByID(Id, False);
		NoHierarchy = Common.IsChartOfAccounts(MetadataObject)
			           Or Common.IsChartOfCalculationTypes(MetadataObject)
			           Or Not MetadataObject.Hierarchical;
		
		QueryText =
			"SELECT
			|	SpecifiedTableAlias.Ref AS Ref,
			|	ISNULL(SpecifiedTableAlias.Parent.PredefinedDataName, """") AS ParentName,
			|	SpecifiedTableAlias.PredefinedDataName AS Name
			|FROM
			|	&CurrentTable AS SpecifiedTableAlias
			|WHERE
			|	SpecifiedTableAlias.Predefined";
		FullName = MetadataObject.FullName();
		Query.Text = StrReplace(QueryText, "&CurrentTable", FullName);
		
		If NoHierarchy Then
			Query.Text = StrReplace(Query.Text,
				"ISNULL(SpecifiedTableAlias.Parent.PredefinedDataName, """")", """""");
		EndIf;
		NameTable = Query.Execute().Unload(); // 
		
		If NameTable.Count() = 0 Then
			Continue; // 
		EndIf;
		PredefinedItemsInData     = NameTable.UnloadColumn("Name");
		PredefinedItemsInMetadata = New Array(MetadataObject.GetPredefinedNames());
		
		ItemsIdentical = Common.IdenticalCollections(PredefinedItemsInData, PredefinedItemsInMetadata);
		
		If ItemsIdentical Then
			Continue; // 
		EndIf;
		
		For Each TagName In PredefinedItemsInData Do
			IndexOf = PredefinedItemsInMetadata.Find(TagName);
			If IndexOf = Undefined Then
				Continue;
			EndIf;
			PredefinedItemsInMetadata.Delete(IndexOf);
		EndDo;
		
		Query = New Query;
		Query.Text =
			"SELECT
			|	SpecifiedTableAlias.Ref AS Ref,
			|	SpecifiedTableAlias.Parent AS Parent,
			|	SpecifiedTableAlias.Description AS Description
			|FROM
			|	&CurrentTable AS SpecifiedTableAlias
			|WHERE
			|	NOT SpecifiedTableAlias.Predefined";
		Query.Text = StrReplace(Query.Text, "&CurrentTable", FullName);
		AllNonPredefinedItems = Query.Execute().Unload(); // 
		AllNonPredefinedItems.Indexes.Add("Description, Parent");
		
		If PredefinedItemsInMetadata.Count() > 0 Then
			Properties = MissingPredefinedItemsProperties(MetadataObject, NameTable, PredefinedItemsInMetadata);
			For Each Property In Properties Do

				SearchParameters = New Structure;
				SearchParameters.Insert("Description", Property.Description);
				SearchParameters.Insert("Parent", Property.Parent);
				FoundItems1 = AllNonPredefinedItems.FindRows(SearchParameters);
				If FoundItems1.Count() = 0 Then
					Continue;
				EndIf;
				Ref = FoundItems1[0].Ref;
				
				Block = New DataLock;
				LockItem = Block.Add(Ref.Metadata().FullName());
				LockItem.SetValue("Ref", Ref);
				
				BeginTransaction();
				Try
					Block.Lock();
					
					Object = Ref.GetObject();
					Object.PredefinedDataName = Property.PredefinedDataName;
					InfobaseUpdate.WriteData(Object);
					
					CommitTransaction();
				Except
					RollbackTransaction();
					Raise;
				EndTry;

			EndDo;
		EndIf;
	EndDo;
	
	// 
	StandardSubsystemsServer.RestorePredefinedItems();
	
EndProcedure

// Returns:
//   Structure:
//   * Ref - CatalogRef.AccountingCheckRules
//
&AtServerNoContext
Function CheckByIDRule( CheckID)
	Query = New Query;
	Query.SetParameter("Id", CheckID);
	Query.Text =
		"SELECT
		|	AccountingCheckRules.Ref AS Ref
		|FROM
		|	Catalog.AccountingCheckRules AS AccountingCheckRules
		|WHERE
		|	AccountingCheckRules.Id = &Id";
	Result = Query.Execute().Select();
	Result.Next();
	Return New Structure("Ref", Result.Ref);
EndFunction

// Parameters:
//   MetadataObject - MetadataObject
//   PredefinedItemsInData - ValueTable:
//   * Ref - AnyRef
//   Absent - Array of AnyRef
// Returns:
//   Array
//
&AtServerNoContext
Function MissingPredefinedItemsProperties(MetadataObject, PredefinedItemsInData, Absent)
	Properties = New Array;
	// 
	BeginTransaction();
	Try
		For Each String In PredefinedItemsInData Do
			Object = String.Ref.GetObject();
			Object.PredefinedDataName = "";
			// 
			InfobaseUpdate.WriteData(Object); // 
		EndDo;
		Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		Manager.SetPredefinedDataInitialization(False);
		
		For Each PredefinedItemName In Absent Do
			NewPredefinedItem = Manager[PredefinedItemName];
			Properties.Add(Common.ObjectAttributesValues(NewPredefinedItem, "Description, Parent, PredefinedDataName"));
		EndDo;
		RollbackTransaction();
	Except
		RollbackTransaction();
	EndTry;
	// 
	
	Return Properties;
EndFunction

#EndRegion