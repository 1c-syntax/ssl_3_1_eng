///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Called when processing a message http://www.1c.ru/SaaS/RemoteAdministration/App/a.b.c.d}SetFullControl.
//
// Parameters:
//  DataAreaUser - CatalogRef.Users -  a user 
//   whose membership in the Administrators group needs to be changed.
//  AccessAllowed - Boolean -  True include user in group,
//   False-exclude the user from the group.
//
Procedure SetUserBelongingToAdministratorGroup(Val DataAreaUser, Val AccessAllowed) Export
	
	AdministratorsGroup = AccessManagement.AdministratorsAccessGroup();
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.AccessGroups");
	LockItem.SetValue("Ref", AdministratorsGroup);
	Block.Lock();
	
	GroupObject = AdministratorsGroup.GetObject();
	
	UserString = GroupObject.Users.Find(DataAreaUser, "User");
	
	If AccessAllowed And UserString = Undefined Then
		
		UserString = GroupObject.Users.Add();
		UserString.User = DataAreaUser;
		GroupObject.Write();
		
	ElsIf Not AccessAllowed And UserString <> Undefined Then
		
		GroupObject.Users.Delete(UserString);
		GroupObject.Write();
	Else
		AccessManagement.UpdateUserRoles(DataAreaUser);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See JobsQueueOverridable.OnGetTemplateList.
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.DataFillingForAccessRestriction.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.AccessUpdateOnRecordsLevel.Name);
	
EndProcedure

// See ExportImportDataOverridable.AfterImportData.
Procedure AfterImportData(Container) Export
	
	// 
	// 
	// 
	If Not Common.DataSeparationEnabled() Then
		Catalogs.AccessGroupProfiles.UpdateSuppliedProfiles();
		Catalogs.AccessGroupProfiles.UpdateUnshippedProfiles();
	EndIf;
	
	AccessManagementInternal.ScheduleAccessRestrictionParametersUpdate(
		"AfterUploadingDataToTheDataArea");
	
EndProcedure

// Called when updating the database user roles.
//
// Parameters:
//  Useridid-Unique Identifier,
//  Cancel - Boolean -  if the parameter value is set to False inside the event handler
//    , the role update for this database user will be skipped.
//
Procedure OnUpdateIBUserRoles(Val UserIdentificator, Cancel) Export
	
	If Common.DataSeparationEnabled()
		And UsersInternalSaaS.UserRegisteredAsShared(UserIdentificator) Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion
