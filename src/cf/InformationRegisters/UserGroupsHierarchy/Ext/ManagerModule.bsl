///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// The procedure updates all the data of the register.
//
// Parameters:
//  HasChanges - Boolean -  (return value) - if a record was made,
//                  it is set to True, otherwise it is not changed.
//
Procedure UpdateRegisterData(HasChanges = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Block = New DataLock;
	Block.Add("InformationRegister.UserGroupsHierarchy");
	
	LockItem = Block.Add("Catalog.UserGroups");
	LockItem.Mode = DataLockMode.Shared;
	
	LockItem = Block.Add("Catalog.ExternalUsersGroups");
	LockItem.Mode = DataLockMode.Shared;
	
	BeginTransaction();
	Try
		Block.Lock();
		ChangesInComposition = UsersInternal.GroupsCompositionNewChanges();
		
		UsersInternal.UpdateGroupsHierarchy(
			Catalogs.UserGroups.EmptyRef(), ChangesInComposition);
		
		UsersInternal.UpdateGroupsHierarchy(
			Catalogs.ExternalUsersGroups.EmptyRef(), ChangesInComposition);
		
		If ValueIsFilled(ChangesInComposition.ModifiedGroups) Then
			HasChanges = True;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf