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
//  Contact  - CatalogRef
//           - Undefined - 
//             
//
Procedure DeleteRecordFromRegister(Contact = Undefined) Export
	
	SetPrivilegedMode(True);
	
	RecordSet = CreateRecordSet();
	If Contact <> Undefined Then
		RecordSet.Filter.Contact.Set(Contact);
	EndIf;
	
	RecordSet.Write();
	
EndProcedure

// Writes information to the register for the specified item.
//
// Parameters:
//  Contact  - CatalogRef -  the contact that is being recorded.
//  NotReviewedInteractionsCount       - Number -  the number of interactions not considered for the contact.
//  LastInteractionDate  - Date  -  date of the last interaction on the contact.
//
Procedure ExecuteRecordToRegister(Contact, NotReviewedInteractionsCount = Undefined,
	LastInteractionDate = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If NotReviewedInteractionsCount = Undefined And LastInteractionDate = Undefined Then
		
		Return;
		
	ElsIf NotReviewedInteractionsCount = Undefined Or LastInteractionDate = Undefined Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	InteractionsContactStates.Contact,
		|	InteractionsContactStates.NotReviewedInteractionsCount,
		|	InteractionsContactStates.LastInteractionDate
		|FROM
		|	InformationRegister.InteractionsContactStates AS InteractionsContactStates
		|WHERE
		|	InteractionsContactStates.Contact = &Contact";
		
		Query.SetParameter("Contact", Contact);
		
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
			
		EndIf;
	EndIf;

	RecordSet = CreateRecordSet();
	RecordSet.Filter.Contact.Set(Contact);
	
	Record = RecordSet.Add();
	Record.Contact                      = Contact;
	Record.NotReviewedInteractionsCount      = NotReviewedInteractionsCount;
	Record.LastInteractionDate = LastInteractionDate;
	RecordSet.Write();

EndProcedure

// Blocks the PC state of Contactsinteractions.
// 
// Parameters:
//  Block       - DataLock -  lock to be set.
//  DataSource   - ValueTable -  the data source for the lock.
//  NameSourceField - String -  name of the source field that will be used to set the contact lock.
//
Procedure BlockInteractionContactsStates(Block, DataSource, NameSourceField) Export
	
	LockItem = Block.Add("InformationRegister.InteractionsContactStates"); 
	LockItem.DataSource = DataSource;
	LockItem.UseFromDataSource("Contact", NameSourceField);
	
EndProcedure

#EndRegion

#EndIf