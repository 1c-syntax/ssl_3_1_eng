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
//  Folder  - CatalogRef.EmailMessageFolders  -  the folder for which the record is being deleted.
//         - Undefined - 
//
Procedure DeleteRecordFromRegister(Folder = Undefined) Export
	
	SetPrivilegedMode(True);
	
	RecordSet = CreateRecordSet();
	If Folder <> Undefined Then
		RecordSet.Filter.Folder.Set(Folder);
	EndIf;
	
	RecordSet.Write();
	
EndProcedure

// Writes information to the register for the specified folder.
//
// Parameters:
//  Folder  - CatalogRef.EmailMessageFolders -  the folder that you are recording is in progress.
//  Count  - Number -  the number of interactions not considered for this folder.
//
Procedure ExecuteRecordToRegister(Folder, Count) Export

	SetPrivilegedMode(True);
	
	Record = CreateRecordManager();
	Record.Folder = Folder;
	Record.NotReviewedInteractionsCount = Count;
	Record.Write(True);

EndProcedure

// Blocks the PC state of the folder List.
// 
// Parameters:
//  Block       - DataLock -  lock to be set.
//  DataSource   - ValueTable -  the data source for the lock.
//  NameSourceField - String -  name of the source field that will be used to set the folder lock.
//
Procedure BlockEmailsFoldersStatus(Block, DataSource, NameSourceField) Export
	
	LockItem = Block.Add("InformationRegister.EmailFolderStates"); 
	LockItem.DataSource = DataSource;
	LockItem.UseFromDataSource("Folder", NameSourceField);
	
EndProcedure

#EndRegion

#EndIf