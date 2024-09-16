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
	Block.Add("InformationRegister.UserGroupCompositions");
	
	LockItem = Block.Add("Catalog.Users");
	LockItem.Mode = DataLockMode.Shared;
	LockItem = Block.Add("Catalog.UserGroups");
	LockItem.Mode = DataLockMode.Shared;
	
	LockItem = Block.Add("Catalog.ExternalUsers");
	LockItem.Mode = DataLockMode.Shared;
	LockItem = Block.Add("Catalog.ExternalUsersGroups");
	LockItem.Mode = DataLockMode.Shared;
	
	BeginTransaction();
	Try
		Block.Lock();
		
		// 
		ChangesInComposition = UsersInternal.GroupsCompositionNewChanges();
		
		UsersInternal.UpdateAllUsersGroupComposition(
			Catalogs.Users.EmptyRef(), ChangesInComposition);
		
		UsersInternal.UpdateHierarchicalUserGroupCompositions(
			Catalogs.UserGroups.EmptyRef(), ChangesInComposition);
		
		UsersInternal.AfterUserGroupsUpdate(ChangesInComposition, HasChanges);
		
		// 
		ChangesInComposition = UsersInternal.GroupsCompositionNewChanges();
		
		UsersInternal.UpdateAllUsersGroupComposition(
			Catalogs.ExternalUsers.EmptyRef(), ChangesInComposition);
		
		UsersInternal.UpdateGroupCompositionsByAuthorizationObjectType(Undefined,
			Undefined, ChangesInComposition);
		
		UsersInternal.UpdateHierarchicalUserGroupCompositions(
			Catalogs.ExternalUsersGroups.EmptyRef(), ChangesInComposition);
		
		UsersInternal.AfterUserGroupsUpdate(ChangesInComposition, HasChanges);
		
		UsersInternal.UpdateExternalUsersRoles();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region Private

// 
//
// Parameters:
//  HasHierarchyChanges - Boolean -  (return value) - if a record was made,
//                            it is set to True, otherwise it is not changed.
//  HasChangesInComposition - Boolean -  (return value) - if a record was made,
//                            it is set to True, otherwise it is not changed.
//
Procedure UpdateHierarchyAndComposition(HasHierarchyChanges = Undefined, HasChangesInComposition = Undefined) Export

	Block = New DataLock;
	Block.Add("InformationRegister.UserGroupsHierarchy");
	Block.Add("InformationRegister.UserGroupCompositions");
	
	LockItem = Block.Add("Catalog.Users");
	LockItem.Mode = DataLockMode.Shared;
	LockItem = Block.Add("Catalog.UserGroups");
	LockItem.Mode = DataLockMode.Shared;
	
	LockItem = Block.Add("Catalog.ExternalUsers");
	LockItem.Mode = DataLockMode.Shared;
	LockItem = Block.Add("Catalog.ExternalUsersGroups");
	LockItem.Mode = DataLockMode.Shared;
	
	BeginTransaction();
	Try
		Block.Lock();
		
		InformationRegisters.UserGroupsHierarchy.UpdateRegisterData(HasHierarchyChanges);
		UpdateRegisterData(HasChangesInComposition);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf