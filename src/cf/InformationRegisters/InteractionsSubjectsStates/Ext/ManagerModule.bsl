///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Deletes either one or all entries from the register.
//
// Parameters:
//  SubjectOf  - DocumentRef
//           - CatalogRef
//           - Undefined - 
//                            
//                            
//
Procedure DeleteRecordFromRegister(SubjectOf = Undefined) Export
	
	SetPrivilegedMode(True);
	
	RecordSet = CreateRecordSet();
	If SubjectOf <> Undefined Then
		RecordSet.Filter.SubjectOf.Set(SubjectOf);
	EndIf;
	
	RecordSet.Write();
	
EndProcedure

// Writes information to the register for the specified item.
//
// Parameters:
//  SubjectOf                       - DocumentRef
//                                - CatalogRef - 
//  NotReviewedInteractionsCount       - Number -  the number of interactions not considered for the item.
//  LastInteractionDate  - Date -  date of the last interaction on the subject.
//  Running                       - Boolean -  indicates that the item is active.
//
Procedure ExecuteRecordToRegister(SubjectOf,
	                              NotReviewedInteractionsCount = Undefined,
	                              LastInteractionDate = Undefined,
	                              Running = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If NotReviewedInteractionsCount = Undefined And LastInteractionDate = Undefined And Running = Undefined Then
		
		Return;
		
	ElsIf NotReviewedInteractionsCount = Undefined Or LastInteractionDate = Undefined Or Running = Undefined Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	InteractionsSubjectsStates.SubjectOf,
		|	InteractionsSubjectsStates.NotReviewedInteractionsCount,
		|	InteractionsSubjectsStates.LastInteractionDate,
		|	InteractionsSubjectsStates.Running
		|FROM
		|	InformationRegister.InteractionsSubjectsStates AS InteractionsSubjectsStates
		|WHERE
		|	InteractionsSubjectsStates.SubjectOf = &SubjectOf";
		
		Query.SetParameter("SubjectOf",SubjectOf);
		
		Result = Query.Execute();
		If Not Result.IsEmpty() Then
			
			Selection = Result.Select();
			Selection.Next();
			
			If NotReviewedInteractionsCount = Undefined Then
				NotReviewedInteractionsCount = Selection.NotReviewedInteractionsCount;
			EndIf;
			
			If LastInteractionDate = Undefined Then
				LastInteractionDate = LastInteractionDate.SubjectOf;
			EndIf;
			
			If Running = Undefined Then
				Running = Selection.Running;
			EndIf;
			
		EndIf;
	EndIf;

	RecordSet = CreateRecordSet();
	RecordSet.Filter.SubjectOf.Set(SubjectOf);
	
	Record = RecordSet.Add();
	Record.SubjectOf                      = SubjectOf;
	Record.NotReviewedInteractionsCount      = NotReviewedInteractionsCount;
	Record.LastInteractionDate = LastInteractionDate;
	Record.Running                      = Running;
	RecordSet.Write();

EndProcedure

// Blocks the RS state of objects and Interactions.
// 
// Parameters:
//  Block       - DataLock -  lock to be set.
//  DataSource   - ValueTable -  the data source for the lock.
//  NameSourceField - String -  name of the source field that will be used to set the item lock.
//
Procedure BlockInteractionObjectsStatus(Block, DataSource, NameSourceField) Export
	
	LockItem = Block.Add("InformationRegister.InteractionsSubjectsStates"); 
	LockItem.DataSource = DataSource;
	LockItem.UseFromDataSource("SubjectOf", NameSourceField);
	
EndProcedure

#EndRegion

#EndIf