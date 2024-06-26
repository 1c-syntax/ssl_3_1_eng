﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.BatchEditObjects

// Returns the object attributes that are not recommended to be edited
// using a bulk attribute modification data processor.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("UsersType");
	NotAttributesToEdit.Add("User");
	NotAttributesToEdit.Add("MainSuppliedProfileAccessGroup");
	NotAttributesToEdit.Add("AccessKinds.*");
	NotAttributesToEdit.Add("AccessValues.*");
	
	Return NotAttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	IsFolder
	|	OR Profile <> VALUE(Catalog.AccessGroupProfiles.Administrator)
	|	  AND IsAuthorizedUser(EmployeeResponsible)";

EndProcedure

// End StandardSubsystems.AccessManagement

// CloudTechnology.ExportImportData

// Attached in ExportImportDataOverridable.OnRegisterDataExportHandlers.
//
// Parameters:
//   Container - DataProcessorObject.ExportImportDataContainerManager
//   ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager
//   Serializer - XDTOSerializer
//   Object - ConstantValueManager
//          - CatalogObject
//          - DocumentObject
//          - BusinessProcessObject
//          - TaskObject
//          - ChartOfAccountsObject
//          - ExchangePlanObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfCalculationTypesObject
//          - InformationRegisterRecordSet
//          - AccumulationRegisterRecordSet
//          - AccountingRegisterRecordSet
//          - CalculationRegisterRecordSet
//          - SequenceRecordSet
//          - RecalculationRecordSet
//   Artifacts - Array of XDTODataObject
//   Cancel - Boolean
//
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	AccessManagementInternal.BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel);
	
EndProcedure

// End CloudTechnology.ExportImportData

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Description");
	Fields.Add("User");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If Not ValueIsFilled(Data.User) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Presentation = AccessManagementInternalClientServer.PresentationAccessGroups(Data);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure ExcludeExpiredMembers() Export
	
	CurrentSessionDateDayStart = BegOfDay(CurrentSessionDate());
	
	Query = New Query;
	Query.SetParameter("DateEmpty", '00010101');
	Query.SetParameter("CurrentSessionDateDayStart", CurrentSessionDateDayStart);
	Query.Text =
	"SELECT DISTINCT
	|	AccessGroupsUsers_SSLy.Ref AS Ref
	|FROM
	|	Catalog.AccessGroups.Users AS AccessGroupsUsers_SSLy
	|WHERE
	|	AccessGroupsUsers_SSLy.ValidityPeriod <> &DateEmpty
	|	AND AccessGroupsUsers_SSLy.ValidityPeriod <= &CurrentSessionDateDayStart";
	
	Selection = Query.Execute().Select();
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.AccessGroups");
	
	While Selection.Next() Do
		LockItem.SetValue("Ref", Selection.Ref);
		BeginTransaction();
		Try
			Block.Lock();
			AccessGroupObject = Selection.Ref.GetObject();
			If AccessGroupObject <> Undefined Then
				HasChanges = False;
				IndexOf = AccessGroupObject.Users.Count() - 1;
				While IndexOf >= 0 Do
					TSRow = AccessGroupObject.Users[IndexOf];
					If ValueIsFilled(TSRow.ValidityPeriod)
					   And TSRow.ValidityPeriod <= CurrentSessionDateDayStart Then
						AccessGroupObject.Users.Delete(IndexOf);
						HasChanges = True;
					EndIf;
					IndexOf = IndexOf - 1;
				EndDo;
				If HasChanges Then
					AccessGroupObject.Write();
				EndIf;
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

// See AccessManagement.AdministratorsAccessGroup
Function AdministratorsAccessGroup(ProfileAdministrator = Undefined) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(ProfileAdministrator) Then
		ProfileAdministrator = AccessManagement.ProfileAdministrator();
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AccessGroups.Ref AS Ref
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|WHERE
	|	AccessGroups.Profile = &ProfileAdministrator
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccessGroups.Ref AS Ref
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|WHERE
	|	AccessGroups.PredefinedDataName = &PredefinedDataName
	|
	|ORDER BY
	|	Ref";
	Query.SetParameter("ProfileAdministrator", ProfileAdministrator);
	Query.SetParameter("PredefinedDataName", "Administrators");
	
	QueryResults = Query.ExecuteBatch();
	SelectionByProfile           = QueryResults[0].Select();
	SelectionByPredefined = QueryResults[1].Select();
	
	If SelectionByProfile.Next()
	   And SelectionByPredefined.Next()
	   And SelectionByProfile.Count() = 1
	   And SelectionByPredefined.Count() = 1
	   And SelectionByProfile.Ref = SelectionByPredefined.Ref Then
		
		Return SelectionByProfile.Ref;
	EndIf;
	
	Block = New DataLock;
	Block.Add("Catalog.AccessGroups");
	
	BeginTransaction();
	Try
		Block.Lock();
		QueryResults = Query.ExecuteBatch();
		SelectionByProfile           = QueryResults[0].Select();
		SelectionByPredefined = QueryResults[1].Select();
		If SelectionByProfile.Next() Then
			AccessGroupObject = SelectionByProfile.Ref.GetObject();
			If AccessGroupObject.PredefinedDataName <> "Administrators" Then
				AccessGroupObject.PredefinedDataName = "Administrators";
			EndIf;
		ElsIf SelectionByPredefined.Next() Then
			AccessGroupObject = SelectionByPredefined.Ref.GetObject();
			AccessGroupObject.Profile = ProfileAdministrator;
		Else
			AccessGroupByName = AccessGroupByName(
				NStr("en = 'Administrators';", Common.DefaultLanguageCode()));
			If ValueIsFilled(AccessGroupByName) Then
				AccessGroupObject = AccessGroupByName.GetObject();
			Else
				AccessGroupObject = CreateItem();
			EndIf;
			AccessGroupObject.Profile = ProfileAdministrator;
			AccessGroupObject.PredefinedDataName = "Administrators";
		EndIf;
		If AccessGroupObject.Modified() Then
			InfobaseUpdate.WriteObject(AccessGroupObject, False, False);
		EndIf;
		
		ObjectsToUnlink = New Map;
		While SelectionByProfile.Next() Do
			If SelectionByProfile.Ref <> AccessGroupObject.Ref Then
				ObjectsToUnlink.Insert(SelectionByProfile.Ref);
			EndIf;
		EndDo;
		While SelectionByPredefined.Next() Do
			If SelectionByPredefined.Ref <> AccessGroupObject.Ref Then
				ObjectsToUnlink.Insert(SelectionByPredefined.Ref);
			EndIf;
		EndDo;
		For Each KeyAndValue In ObjectsToUnlink Do
			CurrentAccessGroupObject = KeyAndValue.Key.GetObject();
			CurrentAccessGroupObject.Profile = Undefined;
			CurrentAccessGroupObject.PredefinedDataName = "";
			InfobaseUpdate.WriteObject(CurrentAccessGroupObject, False, False);
		EndDo;
		For Each KeyAndValue In ObjectsToUnlink Do
			CurrentAccessGroupObject = KeyAndValue.Key.GetObject();
			InfobaseUpdate.WriteObject(CurrentAccessGroupObject);
		EndDo;
		
		AccessGroupObject.Description = NStr("en = 'Administrators';",
			Common.DefaultLanguageCode());
		InfobaseUpdate.WriteObject(AccessGroupObject);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return AccessGroupObject.Ref;
	
EndFunction

// For the AdministratorsAccessGroup function.
Function AccessGroupByName(Description)
	
	Query = New Query;
	Query.SetParameter("Description", Description);
	Query.Text =
	"SELECT TOP 1
	|	AccessGroups.Ref AS Ref
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|WHERE
	|	AccessGroups.Description = &Description
	|
	|ORDER BY
	|	Ref";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Sets a deletion mark for access groups if the
// deletion mark is set for the access group profile. It is required, for example,
// upon deleting the predefined profiles of access groups,
// since the platform does not call object handlers
// when setting the deletion mark for former predefined
// items upon the database configuration update.
//
// Parameters:
//  HasChanges - Boolean - return value. If recorded,
//                  True is set, otherwise, it does not change.
//
Procedure MarkForDeletionSelectedProfilesAccessGroups(HasChanges = Undefined) Export
	
	Query = New Query;
	Query.SetParameter("ProfileAdministrator", AccessManagement.ProfileAdministrator());
	Query.Text =
	"SELECT
	|	AccessGroups.Ref AS Ref
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|WHERE
	|	AccessGroups.Profile <> &ProfileAdministrator
	|	AND AccessGroups.Profile.DeletionMark
	|	AND NOT AccessGroups.DeletionMark
	|	AND NOT AccessGroups.Predefined";
	
	Selection = Query.Execute().Select();
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.AccessGroups");
	
	While Selection.Next() Do
		LockItem.SetValue("Ref", Selection.Ref);
		BeginTransaction();
		Try
			Block.Lock();
			AccessGroupObject = Selection.Ref.GetObject();
			AccessGroupObject.DeletionMark = True;
			InfobaseUpdate.WriteObject(AccessGroupObject);
			InformationRegisters.AccessGroupsTables.UpdateRegisterData(Selection.Ref);
			InformationRegisters.AccessGroupsValues.UpdateRegisterData(Selection.Ref);
			// @skip-check query-in-loop - Batch-wise data processing within a transaction
			UsersForUpdate = UsersForRolesUpdate(Undefined, AccessGroupObject);
			AccessManagement.UpdateUserRoles(UsersForUpdate);
			HasChanges = True;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

// Updates access kinds of access groups for the specified profile.
//  It is possible not to remove access kinds from the access group,
// which are deleted in the access group profile,
// if access values are assigned in the access group by
// the type of access to be deleted.
// 
// Parameters:
//  Profile - CatalogRef.AccessGroupProfiles - an access group profile.
//
//  UpdatingAccessGroupsWithObsoleteSettings - Boolean - update access groups.
//
// Returns:
//  Boolean - if True, an access group is changed,
//           if False, nothing is changed.
//
Function UpdateProfileAccessGroups(Profile, UpdatingAccessGroupsWithObsoleteSettings = False) Export
	
	AccessGroupUpdated = False;
	
	ProfileAccessKinds = Common.ObjectAttributeValue(Profile, "AccessKinds").Unload();
	IndexOf = ProfileAccessKinds.Count() - 1;
	While IndexOf >= 0 Do
		String = ProfileAccessKinds[IndexOf];
		AccessKindProperties = AccessManagementInternal.AccessKindProperties(String.AccessKind);
		
		If AccessKindProperties = Undefined Then
			ProfileAccessKinds.Delete(String);
		EndIf;
		IndexOf = IndexOf - 1;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("ProfileAdministrator",        AccessManagement.ProfileAdministrator());
	Query.SetParameter("AdministratorsAccessGroup", AccessManagement.AdministratorsAccessGroup());
	Query.Text =
	"SELECT
	|	AccessGroups.Ref AS Ref
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|WHERE
	|	NOT(AccessGroups.Profile <> &Profile
	|				AND NOT(&Profile = &ProfileAdministrator
	|						AND AccessGroups.Ref = &AdministratorsAccessGroup))";
	
	Query.SetParameter("Profile", Profile);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		// Checking if an access group must or can be updated.
		AccessGroup = Selection.Ref.GetObject();
		
		If AccessGroup.Ref = AccessManagement.AdministratorsAccessGroup()
		   And AccessGroup.Profile <> AccessManagement.ProfileAdministrator() Then
			// Setting the Administrator profile if it is not set.
			AccessGroup.Profile = AccessManagement.ProfileAdministrator();
		EndIf;
		
		// Checking access kind content.
		AccessKindsContentChanged1 = False;
		HasAccessKindsToDeleteWithSpecifiedAccessValues = False;
		If AccessGroup.AccessKinds.Count() <> ProfileAccessKinds.FindRows(New Structure("Predefined", False)).Count() Then
			AccessKindsContentChanged1 = True;
		Else
			For Each AccessKindRow In AccessGroup.AccessKinds Do
				If ProfileAccessKinds.FindRows(New Structure("AccessKind, Predefined", AccessKindRow.AccessKind, False)).Count() = 0 Then
					AccessKindsContentChanged1 = True;
					If AccessGroup.AccessValues.Find(AccessKindRow.AccessKind, "AccessKind") <> Undefined Then
						HasAccessKindsToDeleteWithSpecifiedAccessValues = True;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
		If AccessKindsContentChanged1
		   And ( UpdatingAccessGroupsWithObsoleteSettings
		       Or Not HasAccessKindsToDeleteWithSpecifiedAccessValues ) Then
			// 
			// 
			CurrentRowNumber1 = AccessGroup.AccessKinds.Count()-1;
			While CurrentRowNumber1 >= 0 Do
				CurrentAccessKind = AccessGroup.AccessKinds[CurrentRowNumber1].AccessKind;
				If ProfileAccessKinds.FindRows(New Structure("AccessKind, Predefined", CurrentAccessKind, False)).Count() = 0 Then
					AccessKindValuesRows = AccessGroup.AccessValues.FindRows(New Structure("AccessKind", CurrentAccessKind));
					For Each ValueRow In AccessKindValuesRows Do
						AccessGroup.AccessValues.Delete(ValueRow);
					EndDo;
					AccessGroup.AccessKinds.Delete(CurrentRowNumber1);
				EndIf;
				CurrentRowNumber1 = CurrentRowNumber1 - 1;
			EndDo;
			// 2. Add new access kinds (if any).
			For Each AccessKindRow In ProfileAccessKinds Do
				If Not AccessKindRow.Predefined 
				   And AccessGroup.AccessKinds.Find(AccessKindRow.AccessKind, "AccessKind") = Undefined Then
					
					NewRow = AccessGroup.AccessKinds.Add();
					NewRow.AccessKind   = AccessKindRow.AccessKind;
					NewRow.AllAllowed = AccessKindRow.AllAllowed;
				EndIf;
			EndDo;
		EndIf;
		
		If AccessGroup.Modified() Then
			
			If Not InfobaseUpdate.InfobaseUpdateInProgress()
			   And Not InfobaseUpdate.IsCallFromUpdateHandler() Then
				
				LockDataForEdit(AccessGroup.Ref, AccessGroup.DataVersion);
			EndIf;
			
			If Not Catalogs.ExtensionsVersions.AllExtensionsConnected() Then
				PreviousValues1 = Common.ObjectAttributesValues(AccessGroup.Ref, "AccessKinds, AccessValues");
				Catalogs.AccessGroupProfiles.RestoreNonexistentViewsFromAccessValue(PreviousValues1, AccessGroup);
			EndIf;
			
			AccessGroup.AdditionalProperties.Insert("DoNotUpdateUsersRoles");
			InfobaseUpdate.WriteObject(AccessGroup);
			AccessGroupUpdated = True;
			
			If Not InfobaseUpdate.InfobaseUpdateInProgress()
			   And Not InfobaseUpdate.IsCallFromUpdateHandler() Then
				
				UnlockDataForEdit(AccessGroup.Ref);
			EndIf;
			
		EndIf;
	EndDo;
	
	Return AccessGroupUpdated;
	
EndFunction

// Returns a reference to a parent group of personal access groups.
//  If the parent group is not found, it will be created.
//
// Parameters:
//  DoNotCreate  - Boolean - if True, the parent is not automatically created
//                 and the function returns Undefined if the parent is not found.
//
//  ItemsGroupDescription - String
//
// Returns:
//  CatalogRef.AccessGroups - a parent group reference.
//
Function PersonalAccessGroupsParent(Val DoNotCreate = False, ItemsGroupDescription = "") Export
	
	SetPrivilegedMode(True);
	
	ItemsGroupDescription = NStr("en = 'Personal access groups';");
	
	Query = New Query(
		"SELECT
		|	AccessGroups.Ref
		|FROM
		|	Catalog.AccessGroups AS AccessGroups
		|WHERE
		|	AccessGroups.Description LIKE &ItemsGroupDescription ESCAPE ""~""
		|	AND AccessGroups.IsFolder");
	Query.SetParameter("ItemsGroupDescription", 
		Common.GenerateSearchQueryString(ItemsGroupDescription));
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Items_Group = Selection.Ref;
	ElsIf DoNotCreate Then
		Items_Group = Undefined;
	Else
		ItemsGroupObject = CreateFolder();
		ItemsGroupObject.Description = ItemsGroupDescription;
		ItemsGroupObject.Write();
		Items_Group = ItemsGroupObject.Ref;
	EndIf;
	
	Return Items_Group;
	
EndFunction

Function AccessKindsOrAccessValuesChanged(PreviousValues1, CurrentObject) Export
	
	If PreviousValues1.Ref <> CurrentObject.Ref Then
		Return True;
	EndIf;
	
	AccessKinds     = PreviousValues1.AccessKinds.Unload();
	AccessValues = PreviousValues1.AccessValues.Unload();
	
	If AccessKinds.Count()     <> CurrentObject.AccessKinds.Count()
	 Or AccessValues.Count() <> CurrentObject.AccessValues.Count() Then
		
		Return True;
	EndIf;
	
	Filter = New Structure("AccessKind, AllAllowed");
	For Each String In CurrentObject.AccessKinds Do
		FillPropertyValues(Filter, String);
		If AccessKinds.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Filter = New Structure("AccessKind, AccessValue, IncludeSubordinateAccessValues");
	For Each String In CurrentObject.AccessValues Do
		FillPropertyValues(Filter, String);
		If AccessValues.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function UsersForRolesUpdate(PreviousValues1, DataElement) Export
	
	If PreviousValues1 = Undefined Then
		PreviousValues1 = New Structure("Ref, Profile, DeletionMark")
	EndIf;
	
	// Updating roles for added, remaining, and removed users.
	Query = New Query;
	
	Query.SetParameter("NewMembers", ?(TypeOf(DataElement) <> Type("ObjectDeletion"),
		DataElement.Users.UnloadColumn("User"), New Array));
	
	Query.SetParameter("OldMembers", ?(DataElement.Ref = PreviousValues1.Ref,
		PreviousValues1.Users.Unload().UnloadColumn("User"), New Array));
	
	If TypeOf(DataElement)         =  Type("ObjectDeletion")
	 Or DataElement.Profile         <> PreviousValues1.Profile
	 Or DataElement.DeletionMark <> PreviousValues1.DeletionMark Then
		
		// Selecting all access group members.
		Query.Text =
		"SELECT DISTINCT
		|	UserGroupCompositions.User AS User
		|FROM
		|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
		|WHERE
		|	(UserGroupCompositions.UsersGroup IN (&OldMembers)
		|			OR UserGroupCompositions.UsersGroup IN (&NewMembers))";
	Else
		// Selecting changes of access group members.
		Query.Text =
		"SELECT
		|	Data.User AS User
		|FROM
		|	(SELECT DISTINCT
		|		UserGroupCompositions.User AS User,
		|		-1 AS LineChangeType
		|	FROM
		|		InformationRegister.UserGroupCompositions AS UserGroupCompositions
		|	WHERE
		|		UserGroupCompositions.UsersGroup IN(&OldMembers)
		|	
		|	UNION ALL
		|	
		|	SELECT DISTINCT
		|		UserGroupCompositions.User,
		|		1
		|	FROM
		|		InformationRegister.UserGroupCompositions AS UserGroupCompositions
		|	WHERE
		|		UserGroupCompositions.UsersGroup IN(&NewMembers)) AS Data
		|
		|GROUP BY
		|	Data.User
		|
		|HAVING
		|	SUM(Data.LineChangeType) <> 0";
	EndIf;
	
	Return Query.Execute().Unload().UnloadColumn("User");
	
EndFunction

Function UsersForRolesUpdateByProfile(Profiles) Export
	
	Query = New Query;
	Query.SetParameter("Profiles", Profiles);
	
	Query.Text =
	"SELECT DISTINCT
	|	UserGroupCompositions.User AS User
	|FROM
	|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		INNER JOIN Catalog.AccessGroups.Users AS AccessGroupsUsers_SSLy
	|		ON UserGroupCompositions.UsersGroup = AccessGroupsUsers_SSLy.User
	|			AND (AccessGroupsUsers_SSLy.Ref.Profile IN (&Profiles))";
	
	Return Query.Execute().Unload().UnloadColumn("User");
	
EndFunction

Function RolesForUpdatingRights(PreviousValues1, DataElement) Export
	
	If PreviousValues1 = Undefined Then
		PreviousValues1 = New Structure("Ref, Profile, DeletionMark")
	EndIf;
	
	// Updating roles for added, remaining, and removed users.
	Query = New Query;
	
	Query.SetParameter("NewProfile",
		?(TypeOf(DataElement) <> Type("ObjectDeletion") And Not DataElement.DeletionMark,
		DataElement.Profile, Catalogs.AccessGroupProfiles.EmptyRef()));
	
	Query.SetParameter("OldProfile",
		?(DataElement.Ref = PreviousValues1.Ref And Not PreviousValues1.DeletionMark,
		PreviousValues1.Profile, Catalogs.AccessGroupProfiles.EmptyRef()));
	
	If TypeOf(DataElement) = Type("ObjectDeletion")
	 Or DataElement.DeletionMark <> PreviousValues1.DeletionMark Then
		
		// Select all roles of the old or new access group profile.
		Query.Text =
		"SELECT DISTINCT
		|	ProfilesRoles.Role AS Role
		|FROM
		|	Catalog.AccessGroupProfiles.Roles AS ProfilesRoles
		|WHERE
		|	ProfilesRoles.Ref IN (&OldProfile, &NewProfile)";
	Else
		// Select access group role changes.
		Query.Text =
		"SELECT
		|	Data.Role AS Role
		|FROM
		|	(SELECT DISTINCT
		|		ProfilesRoles.Role AS Role,
		|		-1 AS LineChangeType
		|	FROM
		|		Catalog.AccessGroupProfiles.Roles AS ProfilesRoles
		|	WHERE
		|		ProfilesRoles.Ref = &OldProfile
		|	
		|	UNION ALL
		|	
		|	SELECT DISTINCT
		|		ProfilesRoles.Role,
		|		1
		|	FROM
		|		Catalog.AccessGroupProfiles.Roles AS ProfilesRoles
		|	WHERE
		|		ProfilesRoles.Ref = &NewProfile) AS Data
		|
		|GROUP BY
		|	Data.Role
		|
		|HAVING
		|	SUM(Data.LineChangeType) <> 0";
	EndIf;
	
	Return Query.Execute().Unload().UnloadColumn("Role");
	
EndFunction

Function ProfileAccessGroups(Profiles) Export
	
	Query = New Query;
	Query.SetParameter("Profiles", Profiles);
	Query.Text =
	"SELECT
	|	AccessGroups.Ref AS Ref
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|WHERE
	|	AccessGroups.Profile IN(&Profiles)
	|	AND NOT AccessGroups.IsFolder";
	QueryResult = Query.Execute();
	
	Return QueryResult.Unload().UnloadColumn("Ref");
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions to support data exchange in DIB.

// For internal use only.
//
// Parameters:
//  DataElement - CatalogObject.AccessGroups
//
Procedure RestoreAdministratorsAccessGroupMembers(DataElement) Export
	
	AdministratorsAccessGroup = AccessManagement.AdministratorsAccessGroup();
	If DataElement.Ref <> AdministratorsAccessGroup Then
		Return;
	EndIf;
	
	DataElement.Users.Clear();
	
	Query = New Query;
	Query.SetParameter("AdministratorsAccessGroup", AdministratorsAccessGroup);
	Query.Text =
	"SELECT DISTINCT
	|	AccessGroupsUsers_SSLy.User
	|FROM
	|	Catalog.AccessGroups.Users AS AccessGroupsUsers_SSLy
	|WHERE
	|	AccessGroupsUsers_SSLy.Ref = &AdministratorsAccessGroup";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If DataElement.Users.Find(Selection.User, "User") = Undefined Then
			DataElement.Users.Add().User = Selection.User;
		EndIf;
	EndDo;
	
EndProcedure

// For internal use only.
Procedure DeleteMembersOfAdministratorsAccessGroupWithoutIBUser() Export
	
	AdministratorsAccessGroup = AccessManagement.AdministratorsAccessGroup();
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.AccessGroups");
	LockItem.SetValue("Ref", AdministratorsAccessGroup);
	
	BeginTransaction();
	Try
		Block.Lock();
		AdministratorsAccessGroup = AdministratorsAccessGroup.GetObject();
		
		IndexOf = AdministratorsAccessGroup.Users.Count() - 1;
		While IndexOf >= 0 Do
			CurrentUser = AdministratorsAccessGroup.Users[IndexOf].User;
			If TypeOf(CurrentUser) = Type("CatalogRef.Users") Then
				IBUserID = Common.ObjectAttributeValue(CurrentUser,
					"IBUserID");
			Else
				IBUserID = Undefined;
			EndIf;
			If TypeOf(IBUserID) = Type("UUID") Then
				IBUser = InfoBaseUsers.FindByUUID(
					IBUserID);
			Else
				IBUser = Undefined;
			EndIf;
			If IBUser = Undefined Then
				AdministratorsAccessGroup.Users.Delete(IndexOf);
			EndIf;
			IndexOf = IndexOf - 1;
		EndDo;
		
		If AdministratorsAccessGroup.Modified() Then
			AdministratorsAccessGroup.Write();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure


// For internal use only.
// 
// Parameters:
//  DataElement - CatalogObject.AccessGroups
//                - ObjectDeletion
//
Procedure RegisterChangeUponDataImport(DataElement) Export
	
	PreviousValues1 = Common.ObjectAttributesValues(DataElement.Ref,
		"Ref, Profile, DeletionMark, Users, AccessKinds, AccessValues");
	
	Required2Registration = False;
	AccessGroup = DataElement.Ref;
	
	If TypeOf(DataElement) = Type("ObjectDeletion") Then
		If PreviousValues1.Ref = Undefined Then
			Return;
		EndIf;
		Required2Registration = True;
		
	ElsIf PreviousValues1.Ref <> DataElement.Ref Then
		Required2Registration = True;
		AccessGroup = UsersInternal.ObjectRef2(DataElement);
	
	ElsIf DataElement.DeletionMark <> PreviousValues1.DeletionMark
	      Or DataElement.Profile         <> PreviousValues1.Profile Then
		
		Required2Registration = True;
	Else
		HasMembers = DataElement.Users.Count() <> 0;
		HasOldMembers = Not PreviousValues1.Users.IsEmpty();
		
		If HasMembers <> HasOldMembers
		 Or AccessKindsOrAccessValuesChanged(PreviousValues1, DataElement) Then
			
			Required2Registration = True;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Required2Registration Then
		UsersInternal.RegisterRefs("AccessGroups", AccessGroup);
	EndIf;
	
	UsersInternal.RegisterRefs("AccessGroupsUsers_SSLy",
		UsersForRolesUpdate(PreviousValues1, DataElement));
	
	If AccessManagementInternal.LimitAccessAtRecordLevelUniversally() Then
		RolesToUpdate = RolesForUpdatingRights(PreviousValues1, DataElement);
		UsersInternal.RegisterRefs("AccessGroupsRoles", RolesToUpdate);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure ProcessChangeRegisteredUponDataImport() Export
	
	If Common.DataSeparationEnabled() Then
		// 
		Return;
	EndIf;
	
	RegistrationCleanup = New Array;
	ProcessRegisteredChangeInAccessGroups("AccessGroups", RegistrationCleanup);
	ProcessRegisteredChangeInRoles("AccessGroupsRoles", RegistrationCleanup);
	ProcessRegisteredChangeInMembers("AccessGroupsUsers_SSLy", RegistrationCleanup);
	
	For Each RefsKindName In RegistrationCleanup Do
		UsersInternal.RegisterRefs(RefsKindName, Null);
	EndDo;
	
EndProcedure

// 
Procedure ProcessRegisteredChangeInAccessGroups(RefsKindName, RegistrationCleanup)

	ChangedAccessGroups = UsersInternal.RegisteredRefs(RefsKindName);
	If ChangedAccessGroups.Count() = 0 Then
		Return;
	EndIf;
	
	If ChangedAccessGroups.Count() = 1
	   And ChangedAccessGroups[0] = Undefined Then
		
		ChangedAccessGroups = Undefined;
	EndIf;
	
	InformationRegisters.AccessGroupsTables.UpdateRegisterData(ChangedAccessGroups);
	InformationRegisters.AccessGroupsValues.UpdateRegisterData(ChangedAccessGroups);
	
	If AccessManagementInternal.LimitAccessAtRecordLevelUniversally() Then
		LongDesc = "UpdateAccessGroupsAuxiliaryDataChangedOnImport";
		AccessManagementInternal.ScheduleAccessGroupsSetsUpdate(LongDesc);
		
		ChangedMembersTypes = New Structure("Users, ExternalUsers", True, True);
		AccessManagementInternal.ScheduleAccessUpdateOnChangeAccessGroupMembers(
			ChangedAccessGroups, ChangedMembersTypes, True);
		
		AccessManagementInternal.UpdateAccessGroupsOfAllowedAccessKey(ChangedAccessGroups);
	EndIf;
	
	RegistrationCleanup.Add(RefsKindName);
	
EndProcedure

// 
Procedure ProcessRegisteredChangeInRoles(RefsKindName, RegistrationCleanup)
	
	If Not AccessManagementInternal.LimitAccessAtRecordLevelUniversally() Then
		Return;
	EndIf;
	
	CompositionOfRoleChanges = UsersInternal.RegisteredRefs(RefsKindName);
	If CompositionOfRoleChanges.Count() = 0 Then
		Return;
	EndIf;
	
	If CompositionOfRoleChanges.Count() = 1
	   And CompositionOfRoleChanges[0] = Undefined Then
		
		CompositionOfRoleChanges = Undefined;
	EndIf;
	
	LongDesc = "UpdateAccessGroupsAuxiliaryDataChangedOnImport";
	AccessManagementInternal.ScheduleAnAccessUpdateWhenTheAccessGroupProfileChanges(LongDesc,
		CompositionOfRoleChanges, True);
	
	RegistrationCleanup.Add(RefsKindName);
	
EndProcedure

// 
Procedure ProcessRegisteredChangeInMembers(RefsKindName, RegistrationCleanup)
	
	Content = UsersInternal.RegisteredRefs(RefsKindName);
	If Content.Count() = 0 Then
		Return;
	EndIf;
	
	If Content.Count() = 1 And Content[0] = Undefined Then
		Content = Undefined;
	EndIf;
	
	AccessManagement.UpdateUserRoles(Content);
	
	RegistrationCleanup.Add(RefsKindName);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Initial population

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = False;
	
EndProcedure

// See also InfobaseUpdateOverridable.OnInitialItemFilling
// 
// Parameters:
//   LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//   Items - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//   TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	Item = Items.Add();
	Item.PredefinedDataName = "Administrators";
	Item.Description = NStr("en = 'Administrators';", Common.DefaultLanguageCode());
	Item.Profile      = AccessManagement.ProfileAdministrator();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Infobase update.

Procedure FillAdministratorsAccessGroupProfile() Export
	
	Object = AccessManagement.AdministratorsAccessGroup().GetObject();
	If Object.Profile <> AccessManagement.ProfileAdministrator() Then
		Object.Profile = AccessManagement.ProfileAdministrator();
		InfobaseUpdate.WriteData(Object);
	EndIf;
	
EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AccessGroups.Ref AS Ref
	|FROM
	|	Catalog.AccessGroups AS AccessGroups";
	
	InfobaseUpdate.MarkForProcessing(Parameters,
		Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ProcessingCompleted = True;
	
	ParametersOfUpdate = New Structure;
	If Parameters.Property("AccessGroups") Then
		AccessGroups = Parameters.AccessGroups;
		ParametersOfUpdate.Insert("RaiseException1");
	Else
		Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.AccessGroups");
		AccessGroups = New Array;
		While Selection.Next() Do
			AccessGroups.Add(Selection.Ref);
		EndDo;
	EndIf;
	ParametersOfUpdate.Insert("AccessGroups", AccessGroups);
	
	If Catalogs.ExtensionsVersions.ExtensionsChangedDynamically()
	   And (Not Common.FileInfobase()
	      Or CurrentRunMode() <> Undefined) Then
		
		ResultAddress = PutToTempStorage(Undefined);
		ParametersOfUpdate.Insert("ResultAddress", ResultAddress);
		JobDescription =
			NStr("en = 'Updating service data of access groups';",
				Common.DefaultLanguageCode());
		BackgroundJob = ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(
			"AccessManagementInternal.UpdateAuxiliaryAccessGroupsData",
			CommonClientServer.ValueInArray(ParametersOfUpdate),,
			JobDescription);
		BackgroundJob = BackgroundJob.WaitForExecutionCompletion();
		If BackgroundJob.State <> BackgroundJobState.Completed Then
			If BackgroundJob.ErrorInfo <> Undefined Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Background job ""%1"" completed with error:
					           |%2';"),
					JobDescription,
					ErrorProcessing.DetailErrorDescription(BackgroundJob.ErrorInfo));
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Background job ""%1"" did not complete.';"), JobDescription);
			EndIf;
			Raise ErrorText;
		EndIf;
		Result = GetFromTempStorage(ResultAddress);
		If TypeOf(Result) <> Type("Structure") Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Background job ""%1"" did not return the result.';"), JobDescription);
			Raise ErrorText;
		EndIf;
	Else
		UpdateAuxiliaryAccessGroupsData(ParametersOfUpdate);
		Result = ParametersOfUpdate.Result;
	EndIf;
	For Each AccessGroup In Result.ProcessedAccessGroups Do
		InfobaseUpdate.MarkProcessingCompletion(AccessGroup);
	EndDo;
	ObjectsProcessed = Result.ProcessedAccessGroups.Count();
	ObjectsWithIssuesCount = Result.ObjectsWithIssuesCount;
	
	If Parameters.Property("AccessGroups") Then
		Return;
	EndIf;
	
	If Not InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.AccessGroups") Then
		ProcessingCompleted = False;
	EndIf;
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t process (skipped) some access groups: %1';"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Information,
			Metadata.Catalogs.AccessGroups,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Yet another batch of access groups is processed: %1';"),
				ObjectsProcessed));
	EndIf;
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

Procedure UpdateAuxiliaryAccessGroupsData(Parameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.IsInternal";
	
	Selection = Query.Execute().Select();
	UtilityUsers = New Map;
	While Selection.Next() Do
		UtilityUsers.Insert(Selection.Ref, True);
	EndDo;
	
	AccessGroupProcessingErrorTemplate =
		NStr("en = 'Couldn''t process the ""%1"" access group. Reason:
		           |%2';");
	AccessGroupsTablesUpdateErrorTemplate =
		NStr("en = 'Cannot update tables of the ""%1"" access group. Reason:
		           |%2';");
	AccessGroupsValuesUpdateErrorTemplate =
		NStr("en = 'Cannot update Access Values of the ""%1"" access group. Reason:
		           |%2';");
	
	ObjectsWithIssuesCount = 0;
	ProcessedAccessGroups = New Array;
	
	For Each AccessGroup In Parameters.AccessGroups Do
		Block = New DataLock;
		LockItem = Block.Add("Catalog.AccessGroups");
		LockItem.SetValue("Ref", AccessGroup);
		RepresentationOfTheReference = String(AccessGroup);
		BeginTransaction();
		Try
			ErrorTemplate = AccessGroupProcessingErrorTemplate;
			Block.Lock();
			
			AccessGroupObject = AccessGroup.GetObject(); // CatalogObject.AccessGroups
			IndexOf = AccessGroupObject.Users.Count();
			While IndexOf > 0 Do
				IndexOf = IndexOf - 1;
				TSRow = AccessGroupObject.Users.Get(IndexOf);
				If UtilityUsers.Get(TSRow.User) <> Undefined Then
					AccessGroupObject.Users.Delete(IndexOf);
				EndIf;
			EndDo;
			
			If AccessGroupObject.Modified() Then
				InfobaseUpdate.WriteObject(AccessGroupObject, False);
				AccessManagementInternal.ScheduleAccessGroupsSetsUpdate(
					"UpdateAuxiliaryAccessGroupsData", True, False);
			EndIf;
			
			ErrorTemplate = AccessGroupsTablesUpdateErrorTemplate;
			InformationRegisters.AccessGroupsTables.UpdateRegisterData(AccessGroup);
			
			ErrorTemplate = AccessGroupsValuesUpdateErrorTemplate;
			InformationRegisters.AccessGroupsValues.UpdateRegisterData(AccessGroup);
			
			ErrorTemplate = AccessGroupProcessingErrorTemplate;
			CommitTransaction();
		Except
			RollbackTransaction();
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			ErrorInfo = ErrorInfo();
			If Parameters.Property("RaiseException1") Then
				Raise;
			EndIf;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
				RepresentationOfTheReference,
				ErrorProcessing.DetailErrorDescription(ErrorInfo));
			
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning, , , MessageText);
			Continue;
		EndTry;
		
		ProcessedAccessGroups.Add(AccessGroup);
	EndDo;
	
	Result = New Structure;
	Result.Insert("ObjectsWithIssuesCount", ObjectsWithIssuesCount);
	Result.Insert("ProcessedAccessGroups", ProcessedAccessGroups);
	
	If Parameters.Property("ResultAddress") Then
		PutToTempStorage(Result, Parameters.ResultAddress);
	Else
		Parameters.Insert("Result", Result);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
