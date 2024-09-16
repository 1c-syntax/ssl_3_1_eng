///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// Returns the details of an object that is not recommended to edit
// by processing a batch update of account details.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("SuppliedDataID");
	NotAttributesToEdit.Add("SuppliedProfileChanged");
	NotAttributesToEdit.Add("AccessKinds.*");
	NotAttributesToEdit.Add("AccessValues.*");
	
	Return NotAttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// 

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS AccessGroupProfiles
	|
	|LEFT JOIN Catalog.AccessGroups AS AccessGroups
	|	ON AccessGroups.Profile = AccessGroupProfiles.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	IsFolder
	|	OR Ref <> VALUE(Catalog.AccessGroupProfiles.Administrator)
	|	  AND IsAuthorizedUser(AccessGroups.EmployeeResponsible)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

// 

// It is connected to the offload of the unloaded data, which is undetectable.When registering the data handlers, the data loads.
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

#Region Internal

// This procedure Updates the description of the supplied profiles in
// the access restriction settings when the configuration changes.
//
// Parameters:
//  HasChanges - Boolean -  the return value. If a record was made,
//                  the Truth is set, otherwise it does not change.
//
Procedure UpdateSuppliedProfilesDescription(HasChanges = Undefined) Export
	
	SetPrivilegedMode(True);
	
	SessionProperties = AccessManagementInternalCached.DescriptionPropertiesAccessTypesSession().SessionProperties;
	NewValue = "";
	VerifiedSuppliedSessionProfiles(SessionProperties, NewValue);
	
	BeginTransaction();
	Try
		HasCurrentChanges = False;
		
		StandardSubsystemsServer.UpdateApplicationParameter(
			"StandardSubsystems.AccessManagement.SuppliedProfilesDescription",
			NewValue, HasCurrentChanges);
		
		StandardSubsystemsServer.AddApplicationParameterChanges(
			"StandardSubsystems.AccessManagement.SuppliedProfilesDescription",
			?(HasCurrentChanges,
			  New FixedStructure("HasChanges", True),
			  New FixedStructure()) );
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If HasCurrentChanges Then
		HasChanges = True;
	EndIf;
	
EndProcedure

// This procedure Updates the predefined profiles in
// the access restriction settings when the configuration changes.
//
// Parameters:
//  HasChanges - Boolean -  the return value. If a record was made,
//                  the Truth is set, otherwise it does not change.
//
Procedure UpdatePredefinedProfileComposition(HasChanges = Undefined) Export
	
	SetPrivilegedMode(True);
	
	PredefinedProfiles = Metadata.Catalogs.AccessGroupProfiles.GetPredefinedNames();
	
	BeginTransaction();
	Try
		Trash = New Array;
		HasCurrentChanges = False;
		PreviousValue2 = Undefined;
		
		StandardSubsystemsServer.UpdateApplicationParameter(
			"StandardSubsystems.AccessManagement.AccessGroupPredefinedProfiles",
			PredefinedProfiles, , PreviousValue2);
		
		If Not PredefinedProfilesMatch(PredefinedProfiles, PreviousValue2, Trash) Then
			HasCurrentChanges = True;
		EndIf;
		
		StandardSubsystemsServer.AddApplicationParameterChanges(
			"StandardSubsystems.AccessManagement.AccessGroupPredefinedProfiles",
			?(ValueIsFilled(Trash),
			  New FixedStructure("Trash", New FixedArray(Trash)),
			  New FixedStructure()) );
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If HasCurrentChanges Then
		HasChanges = True;
	EndIf;
	
EndProcedure

// 
// 
//
Procedure UpdateSuppliedProfilesByConfigurationChanges() Export
	
	Cache = AccessManagementInternalCached.DescriptionSuppliedSessionProfiles();
	NewValue = Cache.HashSum;
	
	IsAlreadyModified = False;
	ParameterName = "StandardSubsystems.AccessManagement.UpdatedSuppliedProfiles";
	PreviousValue2 = StandardSubsystemsServer.ExtensionParameter(ParameterName, True, IsAlreadyModified);
	
	If PreviousValue2 = NewValue Then
		Return;
	EndIf;
	
	Trash = New Array;
	
	If InfobaseUpdate.InfobaseUpdateInProgress() Then
		LastChanges = StandardSubsystemsServer.ApplicationParameterChanges(
			"StandardSubsystems.AccessManagement.AccessGroupPredefinedProfiles");
		
		If LastChanges <> Undefined Then
			For Each ChangesPart In LastChanges Do
				If TypeOf(ChangesPart) <> Type("FixedStructure") Then
					Continue;
				EndIf;
				ChangesCurrentPart = New Structure("Trash");
				FillPropertyValues(ChangesCurrentPart, ChangesPart);
				If TypeOf(ChangesCurrentPart.Trash) = Type("FixedArray") Then
					For Each Deleted In ChangesCurrentPart.Trash Do
						Trash.Add(Deleted);
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If IsAlreadyModified Then
		AccessManagementInternal.CheckWhetherTheMetadataIsUpToDate();
	EndIf;
	
	UpdateSuppliedProfiles(, Trash);
	StandardSubsystemsServer.SetExtensionParameter(ParameterName, NewValue, True);
	
EndProcedure

// 
// 
//
Procedure UpdateNonSuppliedProfilesOnConfigurationChanges() Export
	
	Cache = AccessManagementInternalCached.DescriptionSuppliedSessionProfiles();
	NewValue = Cache.HashSum;
	
	IsAlreadyModified = False;
	ParameterName = "StandardSubsystems.AccessManagement.UpdatedUnshippedProfiles";
	PreviousValue2 = StandardSubsystemsServer.ExtensionParameter(ParameterName, True, IsAlreadyModified);
	
	If PreviousValue2 = NewValue Then
		Return;
	EndIf;
	
	If IsAlreadyModified Then
		AccessManagementInternal.CheckWhetherTheMetadataIsUpToDate();
	EndIf;
	
	UpdateUnshippedProfiles();
	StandardSubsystemsServer.SetExtensionParameter(ParameterName, NewValue, True);
	
EndProcedure

// 
// 
// 
//
// 
// 
//
// Parameters:
//  HasChanges - Boolean -  the return value. If a record was made,
//                  the Truth is set, otherwise it does not change.
//  Trash     - Array - 
//                  
//                - Undefined
//
Procedure UpdateSuppliedProfiles(HasChanges = Undefined, Trash = Undefined) Export
	
	// 
	// 
	AllRoles = New Array;
	For Each Role In Metadata.Roles Do
		AllRoles.Add(Role);
	EndDo;
	Common.MetadataObjectIDs(AllRoles);
	
	SuppliedProfiles = AccessManagementInternal.SuppliedProfiles();
	
	CurrentProfileFolders = CurrentProfileFolders();
	UpdateTheSuppliedProfileFolders("", CurrentProfileFolders, SuppliedProfiles, Trash, HasChanges);
	MarkForDeletionObsoleteSuppliedData(CurrentProfileFolders, HasChanges);
	
	CurrentProfiles = CurrentProfiles();
	UpdatedProfiles  = New Array;
	UpdateTheSuppliedProfilesWithoutFolders(UpdatedProfiles,
		CurrentProfiles, CurrentProfileFolders, SuppliedProfiles, Trash, HasChanges);
	MarkForDeletionObsoleteSuppliedData(CurrentProfiles, HasChanges, UpdatedProfiles);
	UpdateAuxiliaryProfilesData(UpdatedProfiles, HasChanges);
	
EndProcedure

// 
//
// Parameters:
//  HasChanges - Boolean -  the return value. If a record was made,
//                  the Truth is set, otherwise it does not change.
//
Procedure UpdateUnshippedProfiles(HasChanges = Undefined) Export
	
	BasicNonSuppliedProfiles = BasicNonSuppliedProfiles();
	UpdatedProfiles = New Array;
	
	For Each ProfileReference In BasicNonSuppliedProfiles Do
		ProfileObject = ProfileReference.GetObject();
		
		FillStandardExtensionRoles(ProfileObject.Roles);
		If Not ProfileObject.Modified() Then
			Continue;
		EndIf;
		
		If Not InfobaseUpdate.InfobaseUpdateInProgress()
		   And Not InfobaseUpdate.IsCallFromUpdateHandler() Then
			
			LockDataForEdit(ProfileObject.Ref, ProfileObject.DataVersion);
		EndIf;
		
		ProfileObject.AdditionalProperties.Insert("DoNotUpdateUsersRoles");
		InfobaseUpdate.WriteObject(ProfileObject);
		
		HasChanges = True;
		UpdatedProfiles.Add(ProfileReference);
		
		If Not InfobaseUpdate.InfobaseUpdateInProgress()
		   And Not InfobaseUpdate.IsCallFromUpdateHandler() Then
			
			UnlockDataForEdit(ProfileObject.Ref);
		EndIf;
	EndDo;
	
	UpdateAuxiliaryProfilesData(UpdatedProfiles, HasChanges);
	
EndProcedure

Procedure UpdateAuxiliaryProfilesData(Profiles = Undefined, HasChanges = False) Export
	
	If Profiles = Undefined Then
		InformationRegisters.AccessGroupsTables.UpdateRegisterData( , , HasChanges);
		InformationRegisters.AccessGroupsValues.UpdateRegisterData( , HasChanges);
		AccessManagementInternal.UpdateUserRoles( , , HasChanges);
		
	ElsIf Profiles.Count() > 0 Then
		ProfilesAccessGroups = Catalogs.AccessGroups.ProfileAccessGroups(Profiles);
		InformationRegisters.AccessGroupsTables.UpdateRegisterData(ProfilesAccessGroups, , HasChanges);
		InformationRegisters.AccessGroupsValues.UpdateRegisterData(ProfilesAccessGroups, HasChanges);
		
		// 
		UsersForUpdate =
			Catalogs.AccessGroups.UsersForRolesUpdateByProfile(Profiles);
		
		AccessManagementInternal.UpdateUserRoles(UsersForUpdate, , HasChanges);
	EndIf;
	
EndProcedure

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not Users.IsFullUser()
		Or ModuleToDoListServer.UserTaskDisabled("AccessGroupProfiles") Then
		Return;
	EndIf;
	
	// 
	// 
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.Catalogs.AccessGroupProfiles.FullName());
	IncompatibleAccessGroupsProfilesCount = IncompatibleAccessGroupsProfiles().Count();
	
	For Each Section In Sections Do
		
		ProfileID = "IncompatibleWithCurrentVersion" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.Id = ProfileID;
		ToDoItem.HasToDoItems      = IncompatibleAccessGroupsProfilesCount > 0;
		ToDoItem.Presentation = NStr("en = 'Profiles incompatible with the current version';");
		ToDoItem.Count    = IncompatibleAccessGroupsProfilesCount;
		ToDoItem.Owner      = Section;
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id = "AccessGroupProfiles";
		ToDoItem.HasToDoItems      = IncompatibleAccessGroupsProfilesCount > 0;
		ToDoItem.Important        = True;
		ToDoItem.Presentation = NStr("en = 'Access group profiles';");
		ToDoItem.Count    = IncompatibleAccessGroupsProfilesCount;
		ToDoItem.Form         = "Catalog.AccessGroupProfiles.ListForm";
		ToDoItem.FormParameters= New Structure("ProfilesWithRolesMarkedForDeletion", True);
		ToDoItem.Owner      = ProfileID;
		
	EndDo;
	
EndProcedure

// Parameters:
//  ProfileRoles - Array of String - 
//              - TabularSection:
//                 * Role - CatalogRef.MetadataObjectIDs
//                        - CatalogRef.ExtensionObjectIDs
//              - FormDataCollection:
//                 * Role - String -  role name.
//
Procedure FillStandardExtensionRoles(ProfileRoles, StandardExtensionRoles = Undefined) Export
	
	If StandardExtensionRoles = Undefined Then
		StandardExtensionRoles = AccessManagementInternal.StandardExtensionRoles();
	EndIf;
	StandardProfileRoles = StandardProfileRoles(ProfileRoles);
	
	// 
	SetRolesInProfile(ProfileRoles,
		StandardExtensionRoles.SystemAdministrator,
		StandardProfileRoles.SystemAdministrator);
	
	// 
	SetRolesInProfile(ProfileRoles,
		StandardExtensionRoles.FullAccess,
		StandardProfileRoles.FullAccess);
	
	// 
	SetRolesInProfile(ProfileRoles,
		StandardExtensionRoles.BasicAccess,
		StandardProfileRoles.BasicAccessSSL);
	
	// 
	SetRolesInProfile(ProfileRoles,
		StandardExtensionRoles.BasicAccessExternalUsers,
		StandardProfileRoles.BasicAccessExternalUserSSL);
	
	// 
	SetRolesInProfile(ProfileRoles,
		StandardExtensionRoles.CommonRights,
		StandardProfileRoles.FullAccess
			Or StandardProfileRoles.BasicAccessSSL
			Or StandardProfileRoles.BasicAccessExternalUserSSL);
	
	// 
	ClearRemovedStandardExtensionRoles(ProfileRoles);
	
EndProcedure

#EndRegion

#Region Private

// Returns a string of the unique ID
// of the supplied and predefined Administrator profile.
//
// Returns:
//  String - 
//
Function AdministratorProfileID() Export
	
	Return "6c4b0307-43a4-4141-9c35-3dd7e9586d41";
	
EndFunction

// See AccessManagement.ProfileAdministrator
Function ProfileAdministrator() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AccessGroupProfiles.Ref AS Ref
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|WHERE
	|	AccessGroupProfiles.SuppliedDataID = &SuppliedDataID
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccessGroupProfiles.Ref AS Ref
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|WHERE
	|	AccessGroupProfiles.PredefinedDataName = &PredefinedDataName
	|
	|ORDER BY
	|	Ref";
	
	Id = New UUID(AdministratorProfileID());
	Query.SetParameter("SuppliedDataID", Id);
	Query.SetParameter("PredefinedDataName", "Administrator");
	
	QueryResults = Query.ExecuteBatch();
	SelectionByID    = QueryResults[0].Select();
	SelectionByPredefined = QueryResults[1].Select();
	
	If SelectionByID.Next()
	   And SelectionByPredefined.Next()
	   And SelectionByID.Count() = 1
	   And SelectionByPredefined.Count() = 1
	   And SelectionByID.Ref = SelectionByPredefined.Ref Then
		
		Return SelectionByID.Ref;
	EndIf;
	
	Block = New DataLock;
	Block.Add("Catalog.AccessGroupProfiles");
	Block.Add("Catalog.AccessGroups");
	
	SuppliedProfiles = AccessManagementInternal.SuppliedProfiles();
	AdministratorProfileProperties = SuppliedProfiles.ProfilesDetails.Get(
		AdministratorProfileID());
	
	BeginTransaction();
	Try
		Block.Lock();
		QueryResults = Query.ExecuteBatch();
		SelectionByID    = QueryResults[0].Select();
		SelectionByPredefined = QueryResults[1].Select();
		If SelectionByID.Next() Then
			ProfileObject = SelectionByID.Ref.GetObject();
			If ProfileObject.PredefinedDataName <> "Administrator" Then
				ProfileObject.PredefinedDataName = "Administrator";
			EndIf;
		ElsIf SelectionByPredefined.Next() Then
			ProfileObject = SelectionByPredefined.Ref.GetObject();
			ProfileObject.SuppliedDataID = Id;
		Else
			ProfileByName = ProfileByName(
				NStr("en = 'Administrator';", Common.DefaultLanguageCode()));
			If ValueIsFilled(ProfileByName) Then
				ProfileObject = ProfileByName.GetObject();
			Else
				ProfileObject = CreateItem();
			EndIf;
			ProfileObject.SuppliedDataID = Id;
			ProfileObject.PredefinedDataName = "Administrator";
		EndIf;
		If ProfileObject.Modified() Then
			InfobaseUpdate.WriteObject(ProfileObject, False, False);
		EndIf;
		
		ObjectsToUnlink = New Map;
		While SelectionByID.Next() Do
			If SelectionByID.Ref <> ProfileObject.Ref Then
				ObjectsToUnlink.Insert(SelectionByID.Ref);
			EndIf;
		EndDo;
		While SelectionByPredefined.Next() Do
			If SelectionByPredefined.Ref <> ProfileObject.Ref Then
				ObjectsToUnlink.Insert(SelectionByPredefined.Ref);
			EndIf;
		EndDo;
		For Each KeyAndValue In ObjectsToUnlink Do
			CurrentProfileObject = KeyAndValue.Key.GetObject();
			CurrentProfileObject.SuppliedDataID = Undefined;
			CurrentProfileObject.PredefinedDataName = "";
			InfobaseUpdate.WriteObject(CurrentProfileObject, False, False);
		EndDo;
		For Each KeyAndValue In ObjectsToUnlink Do
			CurrentProfileObject = KeyAndValue.Key.GetObject();
			InfobaseUpdate.WriteObject(CurrentProfileObject);
		EndDo;
		
		UpdateTheProfileOrProfileFolder(AdministratorProfileProperties);
		Catalogs.AccessGroups.AdministratorsAccessGroup(ProfileObject.Ref);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return ProfileObject.Ref;
	
EndFunction

// For the Profiladministrator function.
Function ProfileByName(Description)
	
	Query = New Query;
	Query.SetParameter("Description", Description);
	Query.Text =
	"SELECT TOP 1
	|	AccessGroupProfiles.Ref AS Ref
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|WHERE
	|	AccessGroupProfiles.Description = &Description
	|
	|ORDER BY
	|	Ref";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns a link to the supplied profile or profile folder by ID.
//
// Parameters:
//  Id - String -  the name or unique identifier of the supplied profile or profile folder,
//                  as specified in the procedure for filling in the supplied profiles of the Access group of the
//                  general Access Management module is undetectable.
//
//  RaiseExceptionIfMissingInDatabase - Boolean
//  WithoutFolders      - Boolean
//
// Returns:
//  CatalogRef.AccessGroupProfiles - 
//  
//
Function SuppliedProfileByID(Id, RaiseExceptionIfMissingInDatabase = False, WithoutFolders = False) Export
	
	SetPrivilegedMode(True);
	
	SuppliedProfiles = AccessManagementInternal.SuppliedProfiles();
	ProfileProperties = SuppliedProfiles.ProfilesDetails.Get(String(Id)); // See SuppliedProfileProperties
	
	If ProfileProperties = Undefined Or ProfileProperties.IsFolder And WithoutFolders Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot find profile with ID:
			           |%1.';"),
			String(Id));
		Raise ErrorText;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("SuppliedDataID",
		New UUID(ProfileProperties.Id));
	
	Query.Text =
	"SELECT
	|	AccessGroupProfiles.Ref AS Ref
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|WHERE
	|	AccessGroupProfiles.SuppliedDataID = &SuppliedDataID
	|
	|ORDER BY
	|	Ref";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	
	If RaiseExceptionIfMissingInDatabase Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Built-in profile with this id does not exist:
			           |%1';"),
			String(Id));
		Raise ErrorText;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns a string of the unique
// data ID of the supplied profile.
//
// Returns:
//  String
//  Undefined
//
Function SuppliedProfileID(Profile) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("Ref", Profile);
	
	Query.SetParameter("BlankUUID",
		CommonClientServer.BlankUUID());
	
	Query.Text =
	"SELECT
	|	AccessGroupProfiles.SuppliedDataID
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|WHERE
	|	AccessGroupProfiles.Ref = &Ref
	|	AND AccessGroupProfiles.SuppliedDataID <> &BlankUUID";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return String(Selection.SuppliedDataID);
	EndIf;
	
	Return Undefined;
	
EndFunction

// Checks whether the supplied profile or profile folder has been changed compared to the description from the procedure
// Control access is undetectable.When filling in the supplied profiles of the Access group().
//
// Parameters:
//  Profile      - CatalogRef.AccessGroupProfiles
//                     (returns the details of the deliverableprofile Changed),
//               - CatalogObject.AccessGroupProfiles
//                     (returns the result of comparing the object's fill
//                      with the description in the shared module being redefined).
//
// Returns:
//  Boolean
//
Function SuppliedProfileChanged(Profile) Export
	
	If TypeOf(Profile) = Type("CatalogRef.AccessGroupProfiles") Then
		Return Common.ObjectAttributeValue(Profile,
			"SuppliedProfileChanged") = True;
	EndIf;
	
	If Not ValueIsFilled(Profile.SuppliedDataID) Then
		Return False;
	EndIf;
	
	ProfilesDetails = AccessManagementInternal.SuppliedProfiles().ProfilesDetails;
	ProfileProperties = ProfilesDetails.Get(String(Profile.SuppliedDataID)); // See SuppliedProfileProperties
	
	If ProfileProperties = Undefined Then
		Return False;
	EndIf;
	
	If Upper(Profile.Description) <> Upper(ProfileProperties.Description) Then
		Return True;
	EndIf;
	
	If ValueIsFilled(ProfileProperties.Parent) Then
		Parent = SuppliedProfileByID(ProfileProperties.Parent);
		If ValueIsFilled(Parent) And Profile.Parent <> Parent Then
			Return True;
		EndIf;
	EndIf;
	
	If ProfileProperties.IsFolder Then
		Return False;
	EndIf;
	
	ProfileRolesDetails = ProfileRolesDetails(ProfileProperties);
	
	If Profile.Roles.Count()            <> ProfileRolesDetails.Count()
	 Or Profile.AccessKinds.Count()     <> ProfileProperties.AccessKinds.Count()
	 Or Profile.AccessValues.Count() <> ProfileProperties.AccessValues.Count()
	 Or Profile.Purpose.Count()      <> ProfileProperties.Purpose.Count() Then
		Return True;
	EndIf;
	
	For Each Role In ProfileRolesDetails Do
		RoleMetadata = Metadata.Roles.Find(Role);
		If RoleMetadata = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Role ""%2"" specified in built-in profile
				           |""%1"" does not exist.';"),
				ProfileProperties.Description,
				Role);
			Raise ErrorText;
		EndIf;
		RoleID = Common.MetadataObjectID(RoleMetadata);
		If Profile.Roles.FindRows(New Structure("Role", RoleID)).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	For Each AccessKindDetails In ProfileProperties.AccessKinds Do
		AccessKindProperties = AccessManagementInternal.AccessKindProperties(AccessKindDetails.Key);
		Filter = New Structure;
		Filter.Insert("AccessKind",        AccessKindProperties.Ref);
		Filter.Insert("Predefined", AccessKindDetails.Value = "Predefined");
		Filter.Insert("AllAllowed",      AccessKindDetails.Value = "AllAllowedByDefault");
		If Profile.AccessKinds.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	For Each AccessValueDetails In ProfileProperties.AccessValues Do
		Filter = New Structure;
		Filter.Insert("AccessValue", PredefinedValue(AccessValueDetails.AccessValue));
		If Profile.AccessValues.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	For Each UsersType In ProfileProperties.Purpose Do
		Filter = New Structure;
		Filter.Insert("UsersType", UsersType);
		If Profile.Purpose.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// 
//
// Parameters:
//  
//
//  PreviousValues1 - Structure:
//    * Description    - String
//    * Parent        - CatalogRef.AccessGroupProfiles
//    * Roles            - QueryResult
//    * Purpose      - QueryResult
//    * AccessKinds     - QueryResult
//    * AccessValues - QueryResult
//
Function Are1CSuppliedProfileAreasModified(NewProfile, PreviousValues1) Export
	
	If Upper(NewProfile.Description) <> Upper(PreviousValues1.Description) Then
		Return True;
	EndIf;
	
	If NewProfile.Parent <> PreviousValues1.Parent Then
		ProfilesDetails = AccessManagementInternal.SuppliedProfiles().ProfilesDetails;
		ProfileProperties = ProfilesDetails.Get(String(NewProfile.SuppliedDataID)); // See SuppliedProfileProperties
		If ProfileProperties <> Undefined
		   And ValueIsFilled(ProfileProperties.Parent)
		   And ValueIsFilled(SuppliedProfileByID(ProfileProperties.Parent)) Then
			Return True;
		EndIf;
	EndIf;
	
	If NewProfile.IsFolder Then
		Return False;
	EndIf;
	
	OldProfile = New Structure;
	OldProfile.Insert("Roles",            PreviousValues1.Roles.Unload());
	OldProfile.Insert("Purpose",      PreviousValues1.Purpose.Unload());
	OldProfile.Insert("AccessKinds",     PreviousValues1.AccessKinds.Unload());
	OldProfile.Insert("AccessValues", PreviousValues1.AccessValues.Unload());
	
	If NewProfile.Roles.Count()            <> OldProfile.Roles.Count()
	 Or NewProfile.AccessKinds.Count()     <> OldProfile.AccessKinds.Count()
	 Or NewProfile.AccessValues.Count() <> OldProfile.AccessValues.Count()
	 Or NewProfile.Purpose.Count()      <> OldProfile.Purpose.Count() Then
		Return True;
	EndIf;
	
	For Each String In NewProfile.Roles Do
		If OldProfile.Roles.Find(String.Role, "Role") = Undefined Then
			Return True;
		EndIf;
	EndDo;
	
	For Each String In NewProfile.AccessKinds Do
		Filter = New Structure("AccessKind, Predefined, AllAllowed",
			String.AccessKind, String.Predefined, String.AllAllowed);
		If OldProfile.AccessKinds.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	For Each String In NewProfile.AccessKinds Do
		Filter = New Structure("AccessKind, Predefined, AllAllowed",
			String.AccessKind, String.Predefined, String.AllAllowed);
		If OldProfile.AccessKinds.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	For Each String In NewProfile.AccessValues Do
		Filter = New Structure("AccessKind, AccessValue, IncludeSubordinateAccessValues",
			String.AccessKind, String.AccessValue, String.IncludeSubordinateAccessValues);
		If OldProfile.AccessValues.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	For Each String In NewProfile.Purpose Do
		If OldProfile.Purpose.Find(String.UsersType, "UsersType") = Undefined Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Determines whether there is an initial padding for the access group profile in the module being overridden.
//
// Parameters:
//  Profile      - CatalogRef.AccessGroupProfiles
//
// Returns:
//  Boolean
//
Function HasInitialProfileFilling(Val Profile) Export
	
	SuppliedDataID = Common.ObjectAttributeValue(
		Profile, "SuppliedDataID");
	
	If Not ValueIsFilled(SuppliedDataID) Then
		Return False;
	EndIf;
	
	SuppliedProfiles = AccessManagementInternal.SuppliedProfiles();
	ProfileProperties = SuppliedProfiles.ProfilesDetails.Get(String(SuppliedDataID));
	
	Return ProfileProperties <> Undefined;
	
EndFunction

// Specifies whether changes to the supplied profile are prohibited.
// A profile that is not delivered cannot have a change ban.
//
// Parameters:
//  Profile      - CatalogObject.AccessGroupProfiles
//               - FormDataStructure - 
//
// ParentViewOnly - Boolean -  the return value is set to True
//                 if the parent is filled in at the supplied profile and
//                 changing the supplied profile is prohibited.
//
// Returns:
//  Boolean
//
Function ProfileChangeProhibition(Val Profile, ParentViewOnly = False) Export
	
	If Not ValueIsFilled(Profile.SuppliedDataID) Then
		Return False;
	EndIf;
	
	If Profile.SuppliedDataID =
			New UUID(AdministratorProfileID()) Then
		// 
		Return True;
	EndIf;
	
	SuppliedProfiles = AccessManagementInternal.SuppliedProfiles();
	
	ProfileProperties = SuppliedProfiles.ProfilesDetails.Get(
		String(Profile.SuppliedDataID));
	
	ForbiddingChanges = ProfileProperties <> Undefined
	      And (SuppliedProfiles.ParametersOfUpdate.DenyProfilesChange
	         Or ProfileProperties.IsFolder);
	
	If ForbiddingChanges And ValueIsFilled(ProfileProperties.Parent) Then
		ParentViewOnly = True;
	EndIf;
	
	Return ForbiddingChanges;
	
EndFunction

// Returns a description of the purpose of the supplied profile.
//
// Parameters:
//  Profile - CatalogRef.AccessGroupProfiles
//
// Returns:
//  String
//
Function SuppliedProfileNote(Profile) Export
	
	SuppliedDataID = String(Common.ObjectAttributeValue(
		Profile, "SuppliedDataID"));
	
	SuppliedProfilesNote = AccessManagementInternalCached.SuppliedProfilesNote();
	
	Return String(SuppliedProfilesNote.Get(SuppliedDataID));
	
EndFunction

// Creates a supplied profile in the access Profilegroup reference that is specific
// to the application solution and allows you to re-fill the previously created supplied profile
// with its supplied description.
//  The initial fill is searched by the unique profile ID string.
//
// Parameters:
//  Profile      - CatalogRef.AccessGroupProfiles
//                 If the initial fill description is found for the specified profile
//                 , the profile content is completely replaced.
//
//  UpdateAccessGroups - Boolean -  if True, the access types of the profile's access groups will be updated.
//
Procedure FillSuppliedProfile(Val Profile, Val UpdateAccessGroups) Export
	
	SuppliedDataID = String(Common.ObjectAttributeValue(
		Profile, "SuppliedDataID"));
	
	SuppliedProfiles = AccessManagementInternal.SuppliedProfiles();
	ProfileProperties = SuppliedProfiles.ProfilesDetails.Get(SuppliedDataID);
	
	If ProfileProperties <> Undefined Then
		
		UpdateTheProfileOrProfileFolder(ProfileProperties);
		
		If UpdateAccessGroups And Not ProfileProperties.IsFolder Then
			Catalogs.AccessGroups.UpdateProfileAccessGroups(Profile, True);
		EndIf;
	EndIf;
	
EndProcedure

// Returns a list of links to profiles containing unavailable roles or roles marked for deletion.
//
// Returns:
//  Array - 
//
Function IncompatibleAccessGroupsProfiles() Export
	
	Upload0 = ProfilesAssignmentAndRolesAccessGroup();
	
	IncompatibleProfiles = New Array;
	UnavailableRolesByAssignment = New Map;
	
	For Each ProfileDetails In Upload0 Do
		ProfileAssignment = AccessManagementInternalClientServer.ProfileAssignment(ProfileDetails);
		UnavailableRoles = UnavailableRolesByAssignment.Get(ProfileAssignment);
		If UnavailableRoles = Undefined Then
			UnavailableRoles = UsersInternalCached.UnavailableRoles(ProfileAssignment);
			UnavailableRolesByAssignment.Insert(ProfileAssignment, UnavailableRoles);
		EndIf;
		
		If ProfileDetails.Roles.Find(Undefined, "Role") <> Undefined Then
			IncompatibleProfiles.Add(ProfileDetails.Ref);
			Continue;
		EndIf;
		
		RolesDetails = Common.MetadataObjectsByIDs(
			ProfileDetails.Roles.UnloadColumn("Role"), False);
		
		For Each RoleDetails In RolesDetails Do
			MetadataObject = RoleDetails.Value; // MetadataObject
			If MetadataObject = Undefined Then
				// 
				Continue;
			EndIf;
			
			If MetadataObject = Null
			 Or UnavailableRoles.Get(MetadataObject.Name) <> Undefined
			 Or Upper(Left(MetadataObject.Name, StrLen("Delete"))) = Upper("Delete") Then
				
				IncompatibleProfiles.Add(ProfileDetails.Ref);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	Return IncompatibleProfiles;
	
EndFunction

// 
// 
// 
// Returns:
//   See AccessManagementInternal.SuppliedProfiles
//
Function SuppliedProfiles() Export
	
	Cache = AccessManagementInternalCached.DescriptionSuppliedSessionProfiles();
	
	CurrentSessionDate = CurrentSessionDate();
	If Cache.Validation.Date + 3 > CurrentSessionDate Then
		Return Cache.SuppliedSessionProfiles;
	EndIf;
	
	NewValue = Cache.HashSum;
	
	ParameterName = "StandardSubsystems.AccessManagement.SuppliedProfilesDescription";
	PreviousValue2 = StandardSubsystemsServer.ExtensionParameter(ParameterName, True);
	
	If PreviousValue2 <> NewValue Then
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ExtensionVersionParameters");
		LockItem.SetValue("ExtensionsVersion", Catalogs.ExtensionsVersions.EmptyRef());
		LockItem.SetValue("ParameterName", ParameterName);
		BeginTransaction();
		Try
			Block.Lock();
			IsAlreadyModified = False;
			PreviousValue2 = StandardSubsystemsServer.ExtensionParameter(ParameterName, True, IsAlreadyModified);
			If PreviousValue2 <> NewValue Then
				If IsAlreadyModified Then
					AccessManagementInternal.CheckWhetherTheMetadataIsUpToDate();
				EndIf;
				SetSafeModeDisabled(True);
				SetPrivilegedMode(True);
				StandardSubsystemsServer.SetExtensionParameter(ParameterName, NewValue, True);
				SetPrivilegedMode(False);
				SetSafeModeDisabled(False);
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
	Cache.Validation.Date = CurrentSessionDate;
	
	Return Cache.SuppliedSessionProfiles;
	
EndFunction

Function AccessKindsOrValuesOrAssignmentChanged(PreviousValues1, CurrentObject) Export
	
	If PreviousValues1.Ref <> CurrentObject.Ref Then
		Return True;
	EndIf;
	
	AccessKinds     = PreviousValues1.AccessKinds.Unload();
	AccessValues = PreviousValues1.AccessValues.Unload();
	Purpose      = PreviousValues1.Purpose.Unload();
	
	If AccessKinds.Count()     <> CurrentObject.AccessKinds.Count()
	 Or AccessValues.Count() <> CurrentObject.AccessValues.Count()
	 Or Purpose.Count()      <> CurrentObject.Purpose.Count() Then
		
		Return True;
	EndIf;
	
	Filter = New Structure("AccessKind, Predefined, AllAllowed");
	For Each String In CurrentObject.AccessKinds Do
		FillPropertyValues(Filter, String);
		If AccessKinds.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Filter = New Structure("AccessKind, AccessValue");
	For Each String In CurrentObject.AccessValues Do
		FillPropertyValues(Filter, String);
		If AccessValues.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Filter = New Structure("UsersType");
	For Each String In CurrentObject.Purpose Do
		FillPropertyValues(Filter, String);
		If Purpose.FindRows(Filter).Count() = 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Parameters:
//  ChangingLanguages - See NationalLanguageSupportServer.DescriptionOfOldAndNewLanguageSettings
//
Procedure WhenChangingTheLanguageOfTheInformationBase(ChangingLanguages) Export
	
	AccessManagementInternal.SuppliedProfiles(); // 
	ProfilesDetails = FilledSuppliedProfiles().ProfilesDetails;
	
	NewProfileNames = New ValueTable;
	NewProfileNames.Columns.Add("SuppliedDataID",
		New TypeDescription("UUID"));
	NewProfileNames.Columns.Add("Description", New TypeDescription("String",,,,
		New StringQualifiers(Metadata.Catalogs.AccessGroupProfiles.DescriptionLength)));
	
	For Each ProfileDetails In ProfilesDetails Do
		Description = ProfileDetails.Description;
		If Not ValueIsFilled(Description)
		 Or Not StringFunctionsClientServer.IsUUID(ProfileDetails.Id) Then
			Continue;
		EndIf;
		NewRow = NewProfileNames.Add();
		NewRow.SuppliedDataID =
			New UUID(ProfileDetails.Id);
		NewRow.Description = Description;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("NewProfileNames", NewProfileNames);
	Query.Text =
	"SELECT
	|	NewProfileNames.SuppliedDataID AS SuppliedDataID,
	|	NewProfileNames.Description AS Description
	|INTO NewProfileNames
	|FROM
	|	&NewProfileNames AS NewProfileNames
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Profiles.Ref AS Ref,
	|	NewProfileNames.Description AS Description
	|FROM
	|	Catalog.AccessGroupProfiles AS Profiles
	|		INNER JOIN NewProfileNames AS NewProfileNames
	|		ON Profiles.SuppliedDataID = NewProfileNames.SuppliedDataID
	|			AND Profiles.Description <> NewProfileNames.Description";
	
	Selection = Query.Execute().Select();
	Block = New DataLock;
	LockItem = Block.Add("Catalog.AccessGroupProfiles");
	
	While Selection.Next() Do
		LockItem.SetValue("Ref", Selection.Ref);
		BeginTransaction();
		Try
			Block.Lock();
			CurrentObject = Selection.Ref.GetObject(); // CatalogObject.AccessGroupProfiles
			If CurrentObject.Description <> Selection.Description Then
				CurrentObject.Description = Selection.Description;
				InfobaseUpdate.WriteObject(CurrentObject);
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

Procedure RestoreNonexistentViewsFromAccessValue(PreviousValues1, NewValues) Export
	
	If TypeOf(PreviousValues1.AccessKinds) <> Type("QueryResult") Then
		Return;
	EndIf;
	
	AccessKindsProperties = AccessManagementInternal.AccessKindsProperties();
	
	ByRefs             = AccessKindsProperties.ByRefs;
	ByGroupsAndValuesTypes = AccessKindsProperties.ByGroupsAndValuesTypes;
	
	OldAccessTypes     = PreviousValues1.AccessKinds.Unload();
	OldAccessValues = PreviousValues1.AccessValues.Unload();
	
	HaveRefurbished = False;
	
	For Each String In OldAccessTypes Do
		If String.AccessKind = Undefined
		 Or ByRefs.Get(String.AccessKind) <> Undefined
		 Or NewValues.AccessKinds.Find(String.AccessKind, "AccessKind") <> Undefined Then
			Continue;
		EndIf;
		NewRow = NewValues.AccessKinds.Add();
		FillPropertyValues(NewRow, String);
		HaveRefurbished = True;
	EndDo;
	
	For Each String In OldAccessValues Do
		If String.AccessKind = Undefined
		 Or String.AccessValue = Undefined
		 Or NewValues.AccessKinds.Find(String.AccessKind, "AccessKind") = Undefined Then
			Continue;
		EndIf;
		AccessKindProperties = ByGroupsAndValuesTypes.Get(TypeOf(String.AccessValue)); // See AccessManagementInternal.AccessKindsProperties
		If AccessKindProperties <> Undefined
		   And AccessKindProperties.Ref = String.AccessKind Then
			Continue;
		EndIf;
		Filter = New Structure("AccessKind, AccessValue",
			String.AccessKind, String.AccessValue);
		If NewValues.AccessValues.FindRows(Filter).Count() > 0 Then
			Continue;
		EndIf;
		NewRow = NewValues.AccessValues.Add();
		FillPropertyValues(NewRow, String);
		HaveRefurbished = True;
	EndDo;
	
	If HaveRefurbished Then
		// 
		// 
		NewValues.AccessKinds.Add();
	EndIf;
	
EndProcedure

// 
Function StandardProfileRoles(ProfileRoles)
	
	Result = New Structure;
	Result.Insert("SystemAdministrator",
		HasRoleInProfile(ProfileRoles, Metadata.Roles.SystemAdministrator));
	
	Result.Insert("FullAccess",
		HasRoleInProfile(ProfileRoles, Metadata.Roles.FullAccess));
	
	Result.Insert("BasicAccessSSL",
		HasRoleInProfile(ProfileRoles, Metadata.Roles.BasicAccessSSL));
	
	Result.Insert("BasicAccessExternalUserSSL",
		HasRoleInProfile(ProfileRoles, Metadata.Roles.BasicAccessExternalUserSSL));
	
	Return Result;
	
EndFunction

// 
Function HasRoleInProfile(ProfileRoles, Role)
	
	Result = False;
	
	If TypeOf(ProfileRoles) = Type("Array") Then
		If ProfileRoles.Find(Role.Name) <> Undefined Then
			Result = True;
		EndIf;
	ElsIf TypeOf(ProfileRoles) = Type("FormDataCollection") Then
		Filter = New Structure("Role", Role.Name);
		If ProfileRoles.FindRows(Filter).Count() > 0 Then
			Result = True;
		EndIf;
	Else
		RoleID = Common.MetadataObjectID(Role.FullName());
		
		If ProfileRoles.Find(RoleID, "Role") <> Undefined Then
			Result = True;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// 
Procedure SetRolesInProfile(ProfileRoles, RolesNames, Set)
	
	If Not ValueIsFilled(RolesNames) Then
		Return;
	EndIf;
	
	If TypeOf(ProfileRoles) = Type("Array") Then
		For Each NameOfRole In RolesNames Do
			RoleIndex = ProfileRoles.Find(NameOfRole);
			Use = RoleIndex <> Undefined;
			If Set And Not Use Then
				ProfileRoles.Add(NameOfRole);
			ElsIf Not Set And Use Then
				ProfileRoles.Delete(RoleIndex);
			EndIf;
		EndDo;
	ElsIf TypeOf(ProfileRoles) = Type("FormDataCollection") Then
		For Each NameOfRole In RolesNames Do
			Filter = New Structure("Role", NameOfRole);
			FoundRows = ProfileRoles.FindRows(Filter);
			Use = FoundRows.Count() > 0;
			If Set And Not Use Then
				ProfileRoles.Add().Role = NameOfRole;
			ElsIf Not Set And Use Then
				FoundRow = FoundRows[0]; // FormDataCollectionItem
				ProfileRoles.Delete(FoundRow);
			EndIf;
		EndDo;
	Else
		StringFullRoleNames = "Role." + StrConcat(RolesNames, Chars.LF + "Role.");
		FullRoleNames = StrSplit(StringFullRoleNames, Chars.LF);
		RoleIDs = Common.MetadataObjectIDs(FullRoleNames);
		
		For Each FullNameOfTheRole In FullRoleNames Do
			RoleID = RoleIDs.Get(FullNameOfTheRole);
			TSRow = ProfileRoles.Find(RoleID, "Role");
			Use = TSRow <> Undefined;
			If Set And Not Use Then
				ProfileRoles.Add().Role = RoleID;
			ElsIf Not Set And Use Then
				ProfileRoles.Delete(TSRow);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure ClearRemovedStandardExtensionRoles(ProfileRoles)
	
	If TypeOf(ProfileRoles) = Type("Array")
	 Or TypeOf(ProfileRoles) = Type("FormDataCollection") Then
		Return;
	EndIf;
	
	RoleIDs = New Array;
	For Each String In ProfileRoles Do
		If TypeOf(String.Role) = Type("CatalogRef.ExtensionObjectIDs") Then
			RoleIDs.Add(String.Role);
		EndIf;
	EndDo;
	
	RolesByIds = Common.MetadataObjectsByIDs(RoleIDs, False);
	IDsofRemovedAndDisabledRoles = New Array;
	For Each RoleDetails In RolesByIds Do
		If TypeOf(RoleDetails.Value) = Type("MetadataObject") Then
			Continue;
		EndIf;
		IDsofRemovedAndDisabledRoles.Add(RoleDetails.Key);
	EndDo;
	
	FullNamesofRemovedDisabledRoles =
		Catalogs.MetadataObjectIDs.FullNamesofMetadataObjectsIncludingRemote(
			IDsofRemovedAndDisabledRoles);
	
	For Each RoleDetails In FullNamesofRemovedDisabledRoles Do
		NameParts = StrSplit(RoleDetails.Value, ".");
		If NameParts.Count() <> 2
		 Or Upper(NameParts[0]) <> Upper("Role") Then
			Continue;
		EndIf;
		NameOfRole = NameParts[1];
		If Not StrEndsWith(Upper(NameOfRole), Upper("CommonRights"))
		   And Not StrEndsWith(Upper(NameOfRole), Upper("FullAccess"))
		   And Not StrEndsWith(Upper(NameOfRole), Upper("BasicAccess"))
		   And Not StrEndsWith(Upper(NameOfRole), Upper("BasicAccessExternalUsers"))
		   And Not StrEndsWith(Upper(NameOfRole), Upper("SystemAdministrator")) Then
			Continue;
		EndIf;
		Filter = New Structure("Role", RoleDetails.Key);
		Rows = ProfileRoles.FindRows(Filter);
		For Each String In Rows Do
			ProfileRoles.Delete(String);
		EndDo;
	EndDo;
	
EndProcedure

// 
// 
// Returns:
//   See AccessManagementInternal.StandardExtensionRoles
//
Function StandardExtensionRoles() Export
	
	Cache = AccessManagementInternalCached.DescriptionStandardRolesSessionExtensions();
	
	CurrentSessionDate = CurrentSessionDate();
	If Cache.Validation.Date + 3 > CurrentSessionDate Then
		Return Cache.SessionRoles;
	EndIf;
	
	NewValue = Cache.HashSum;
	
	ParameterName = "StandardSubsystems.AccessManagement.DescriptionStandardRolesExtensions";
	PreviousValue2 = StandardSubsystemsServer.ExtensionParameter(ParameterName, True);
	
	If PreviousValue2 <> NewValue Then
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ExtensionVersionParameters");
		LockItem.SetValue("ExtensionsVersion", Catalogs.ExtensionsVersions.EmptyRef());
		LockItem.SetValue("ParameterName", ParameterName);
		BeginTransaction();
		Try
			Block.Lock();
			IsAlreadyModified = False;
			PreviousValue2 = StandardSubsystemsServer.ExtensionParameter(ParameterName, True, IsAlreadyModified);
			If PreviousValue2 <> NewValue Then
				If IsAlreadyModified Then
					AccessManagementInternal.CheckWhetherTheMetadataIsUpToDate();
				EndIf;
				SetSafeModeDisabled(True);
				SetPrivilegedMode(True);
				StandardSubsystemsServer.SetExtensionParameter(ParameterName, NewValue, True);
				SetPrivilegedMode(False);
				SetSafeModeDisabled(False);
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
	Cache.Validation.Date = CurrentSessionDate;
	
	Return Cache.SessionRoles;
	
EndFunction

// 
// 
// Parameters:
//  HashSum - String -  the return value.
//
// Returns:
//   See AccessManagementInternal.StandardExtensionRoles
//
Function PreparedStandardRolesSessionExtensions(HashSum) Export
	
	CommonRights                       = New ValueList;
	BasicAccess                     = New ValueList;
	BasicAccessExternalUsers = New ValueList;
	SystemAdministrator             = New ValueList;
	FullAccess                      = New ValueList;
	AdditionalAdministratorRoles = New ValueList;
	AllRoles                          = New Map;
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	For Each Role In Metadata.Roles Do
		Extension = Role.ConfigurationExtension();
		If Extension = Undefined Then
			Continue;
		EndIf;
		NameOfRole = Role.Name;
		
		If StrEndsWith(Upper(NameOfRole), Upper("CommonRights")) Then
			CommonRights.Add(NameOfRole);
			AdditionalAdministratorRoles.Add(NameOfRole);
			AllRoles.Insert(NameOfRole, "CommonRights");
			
		ElsIf StrEndsWith(Upper(NameOfRole), Upper("FullAccess")) Then
			FullAccess.Add(NameOfRole);
			AdditionalAdministratorRoles.Add(NameOfRole);
			AllRoles.Insert(NameOfRole, "FullAccess");
			
		ElsIf StrEndsWith(Upper(NameOfRole), Upper("BasicAccess")) Then
			BasicAccess.Add(NameOfRole);
			AllRoles.Insert(NameOfRole, "BasicAccess");
			
		ElsIf StrEndsWith(Upper(NameOfRole), Upper("BasicAccessExternalUsers")) Then
			BasicAccessExternalUsers.Add(NameOfRole);
			AllRoles.Insert(NameOfRole, "BasicAccessExternalUsers");
			
		ElsIf StrEndsWith(Upper(NameOfRole), Upper("SystemAdministrator")) Then
			SystemAdministrator.Add(NameOfRole);
			AllRoles.Insert(NameOfRole, "SystemAdministrator");
			If Not DataSeparationEnabled Then
				AdditionalAdministratorRoles.Add(NameOfRole);
			EndIf;
		EndIf;
	EndDo;
	
	CommonRights.SortByValue();
	BasicAccess.SortByValue();
	BasicAccessExternalUsers.SortByValue();
	SystemAdministrator.SortByValue();
	FullAccess.SortByValue();
	AdditionalAdministratorRoles.SortByValue();
	
	CommonRights = CommonRights.UnloadValues();
	BasicAccess = BasicAccess.UnloadValues();
	BasicAccessExternalUsers = BasicAccessExternalUsers.UnloadValues();
	SystemAdministrator = SystemAdministrator.UnloadValues();
	FullAccess = FullAccess.UnloadValues();
	AdditionalAdministratorRoles = AdditionalAdministratorRoles.UnloadValues();
	
	AdditionalRoles = New Map;
	For Each NameOfRole In AdditionalAdministratorRoles Do
		AdditionalRoles.Insert(NameOfRole, True);
	EndDo;
	
	Properties = New Structure;
	Properties.Insert("CommonRights",
		New FixedArray(CommonRights));
	
	Properties.Insert("BasicAccess",
		New FixedArray(BasicAccess));
	
	Properties.Insert("BasicAccessExternalUsers",
		New FixedArray(BasicAccessExternalUsers));
	
	Properties.Insert("SystemAdministrator",
		New FixedArray(SystemAdministrator));
	
	Properties.Insert("FullAccess",
		New FixedArray(FullAccess));
	
	Properties.Insert("All",
		New FixedMap(AllRoles));
	
	Properties.Insert("AdditionalAdministratorRoles",
		New FixedMap(AdditionalRoles));
	
	VersionDetails = New Structure("VersionProperties", New Array);
	AddVersionItem(VersionDetails, "Version", "1");
	AddVersionItem(VersionDetails, "CommonRights", CommonRights);
	AddVersionItem(VersionDetails, "BasicAccess", BasicAccess);
	AddVersionItem(VersionDetails, "BasicAccessExternalUsers", BasicAccessExternalUsers);
	AddVersionItem(VersionDetails, "SystemAdministrator", SystemAdministrator);
	AddVersionItem(VersionDetails, "FullAccess", FullAccess);
	AddVersionItem(VersionDetails, "AdditionalAdministratorRoles", AdditionalAdministratorRoles);
	
	Result = New FixedStructure(Properties);
	
	VersionString = StrConcat(VersionDetails.VersionProperties, Chars.LF);
	HashSum = AccessManagementInternal.HashAmountsData(VersionString);
	
	Return Result;
	
EndFunction

// See AccessManagementInternal.AddVersionItem
Procedure AddVersionItem(Context, FieldName, Value)
	AccessManagementInternal.AddVersionItem(Context, FieldName, Value);
EndProcedure

// See AccessManagementInternal.AddVersionProperties
Procedure AddVersionProperties(Context, Structure, FieldsNames)
	AccessManagementInternal.AddVersionProperties(Context, Structure, FieldsNames);
EndProcedure

// For internal use only.
//
// Parameters:
//  Object - CatalogObject.AccessGroupProfiles
//         - CatalogObject.MetadataObjectIDs
//         - CatalogObject.ExtensionObjectIDs
//  PreviousValues1 - Structure
//
Procedure RegisterChangeInProfilesRoles(Object, PreviousValues1) Export
	
	Data = New Structure;
	Data.Insert("DataStructureVersion", 1);
	Data.Insert("ChangeOfRoles", New Array);
	Data.Insert("RolesPresentation", New Array);
	Data.Insert("ProfilesPresentation", New Array);
	
	If TypeOf(Object) = Type("CatalogObject.AccessGroupProfiles") Then
		WasProfileActivityChanged = Object.DeletionMark <> PreviousValues1.DeletionMark;
		
		ChangeOfRoles = Object.Roles.Unload();
		ChangeOfRoles.GroupBy("Role");
		ChangeOfRoles.Columns.Add("ChangeType", New TypeDescription("String"));
		ChangeOfRoles.FillValues("Added2", "ChangeType");
		
		If TypeOf(PreviousValues1.Roles) = Type("QueryResult")
		   And Not PreviousValues1.Roles.IsEmpty() Then
			
			OldRoles = PreviousValues1.Roles.Unload();
			OldRoles.Indexes.Add("Role");
			IndexOf = ChangeOfRoles.Count();
			While IndexOf > 0 Do
				IndexOf = IndexOf - 1;
				NewRole = ChangeOfRoles.Get(IndexOf);
				OldRole = OldRoles.Find(NewRole.Role, "Role");
				If OldRole = Undefined Then
					Continue;
				EndIf;
				If WasProfileActivityChanged Then
					NewRole.ChangeType = "IsChanged";
				Else
					ChangeOfRoles.Delete(NewRole);
				EndIf;
				OldRoles.Delete(OldRole);
			EndDo;
			For Each OldRole In OldRoles Do
				NewRow = ChangeOfRoles.Add();
				FillPropertyValues(NewRow, OldRole);
				NewRow.ChangeType = "Deleted";
			EndDo;
		EndIf;
		
		If Not WasProfileActivityChanged
		   And Not ValueIsFilled(ChangeOfRoles) Then
			Return;
		EndIf;
		
		ProfileSerializedRef = SerializedRef(Object.Ref);
		RoleIDs = ChangeOfRoles.UnloadColumn("Role");
		RolesProperties = Common.ObjectsAttributesValues(RoleIDs,
			"DeletionMark, Name, Synonym");
		
		RolesMetadata = Common.MetadataObjectsByIDs(RoleIDs, False);
		
		For Each String In ChangeOfRoles Do
			If Not ValueIsFilled(String.Role) Then
				Continue;
			EndIf;
			RoleSerializedRef = SerializedRef(String.Role);
			
			Properties = New Structure;
			Properties.Insert("Profile", ProfileSerializedRef);
			Properties.Insert("Role", RoleSerializedRef);
			Properties.Insert("ChangeType", String.ChangeType);
			Data.ChangeOfRoles.Add(Properties);
			
			RoleMetadata = RolesMetadata.Get(String.Role);
			RoleProperties = RolesProperties.Get(String.Role);
			NameOfRole     = Undefined;
			RoleSynonym = Undefined;
			
			If TypeOf(RoleMetadata) = Type("MetadataObject") Then
				NameOfRole     = RoleMetadata.Name;
				RoleSynonym = RoleMetadata.Synonym;
			ElsIf RoleProperties <> Undefined Then
				NameOfRole     = RoleProperties.Name;
				RoleSynonym = RoleProperties.Synonym;
			EndIf;
			RoleDeletionMark = ?(RoleProperties = Undefined,
				Undefined, RoleProperties.DeletionMark);
			
			Properties = New Structure;
			Properties.Insert("Role", RoleSerializedRef);
			Properties.Insert("DeletionMark", RoleDeletionMark);
			Properties.Insert("IsPresentInMetadata", TypeOf(RoleMetadata) = Type("MetadataObject"));
			Properties.Insert("Name", NameOfRole);
			Properties.Insert("Synonym", RoleSynonym);
			Properties.Insert("OldPropertyValues", New Structure);
			Data.RolesPresentation.Add(Properties);
		EndDo;
		
		Properties = New Structure;
		Properties.Insert("Profile", SerializedRef(Object.Ref));
		Properties.Insert("Presentation", RepresentationOfTheReference(Object.Ref));
		Properties.Insert("DeletionMark", Object.DeletionMark);
		Properties.Insert("OldPropertyValues", New Structure);
		
		If Object.DeletionMark <> PreviousValues1.DeletionMark Then
			Properties.OldPropertyValues.Insert("DeletionMark", PreviousValues1.DeletionMark);
		EndIf;
		Data.ProfilesPresentation.Add(Properties);
	Else
		If Object.DeletionMark = PreviousValues1.DeletionMark Then
			Return;
		EndIf;
		
		Query = New Query;
		Query.SetParameter("Role", Object.Ref);
		Query.Text =
		"SELECT
		|	AccessGroupProfiles.Ref AS Ref,
		|	AccessGroupProfiles.DeletionMark AS DeletionMark,
		|	AccessGroupProfiles.Presentation AS Presentation
		|FROM
		|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
		|WHERE
		|	AccessGroupProfiles.Ref IN
		|			(SELECT
		|				ProfilesRoles.Ref
		|			FROM
		|				Catalog.AccessGroupProfiles.Roles AS ProfilesRoles
		|			WHERE
		|				ProfilesRoles.Role = &Role)";
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			Return;
		EndIf;
		
		RoleSerializedRef = SerializedRef(Object.Ref);
		RoleMetadata = Common.MetadataObjectByID(Object.Ref, False);
		NameOfRole = ?(TypeOf(RoleMetadata) = Type("MetadataObject"), RoleMetadata.Name, Object.Name);
		RoleSynonym = ?(TypeOf(RoleMetadata) = Type("MetadataObject"), RoleMetadata.Synonym, Object.Synonym);
		
		Properties = New Structure;
		Properties.Insert("Role", RoleSerializedRef);
		Properties.Insert("DeletionMark", Object.DeletionMark);
		Properties.Insert("IsPresentInMetadata", TypeOf(RoleMetadata) = Type("MetadataObject"));
		Properties.Insert("Name", NameOfRole);
		Properties.Insert("Synonym", RoleSynonym);
		Properties.Insert("OldPropertyValues", New Structure);
		
		If Object.DeletionMark <> PreviousValues1.DeletionMark Then
			Properties.OldPropertyValues.Insert("DeletionMark", PreviousValues1.DeletionMark);
		EndIf;
		If Object.Name <> PreviousValues1.Name Then
			Properties.OldPropertyValues.Insert("Name",
				?(TypeOf(PreviousValues1.Name) = Type("String"), PreviousValues1.Name, ""));
		EndIf;
		If Object.Synonym <> PreviousValues1.Synonym Then
			Properties.OldPropertyValues.Insert("Synonym",
				?(TypeOf(PreviousValues1.Synonym) = Type("String"), PreviousValues1.Synonym, ""));
		EndIf;
		
		Data.RolesPresentation.Add(Properties);
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			ProfileSerializedRef = SerializedRef(Selection.Ref);
			
			Properties = New Structure;
			Properties.Insert("Profile", ProfileSerializedRef);
			Properties.Insert("Role", RoleSerializedRef);
			Properties.Insert("ChangeType", "IsChanged");
			Data.ChangeOfRoles.Add(Properties);
			
			Properties = New Structure;
			Properties.Insert("Profile", ProfileSerializedRef);
			Properties.Insert("Presentation", Selection.Presentation);
			Properties.Insert("DeletionMark", Selection.DeletionMark);
			Properties.Insert("OldPropertyValues", New Structure);
			Data.ProfilesPresentation.Add(Properties);
		EndDo;
	EndIf;
	
	EventName = AccessManagementInternal.NameOfLogEventProfilesRolesChanged();
	
	WriteLogEvent(EventName,
		EventLogLevel.Information,
		Object.Metadata(),
		Common.ValueToXMLString(Data),
		,
		EventLogEntryTransactionMode.Transactional);
	
EndProcedure

// See UsersInternal.SerializedRef
Function SerializedRef(Ref)
	Return UsersInternal.SerializedRef(Ref);
EndFunction

// See UsersInternal.RepresentationOfTheReference
Function RepresentationOfTheReference(Ref)
	Return UsersInternal.RepresentationOfTheReference(Ref);
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// For internal use only.
//
// Parameters:
//  DataElement - CatalogObject.AccessGroupProfiles
//
Procedure RestoreExtensionsRolesComponents(DataElement) Export
	
	DeleteExtensionsRoles(DataElement);
	
	Query = New Query;
	Query.SetParameter("Profile", DataElement.Ref);
	Query.Text =
	"SELECT DISTINCT
	|	ProfilesRoles.Role AS Role
	|FROM
	|	Catalog.AccessGroupProfiles.Roles AS ProfilesRoles
	|WHERE
	|	ProfilesRoles.Ref = &Profile
	|	AND VALUETYPE(ProfilesRoles.Role) = TYPE(Catalog.ExtensionObjectIDs)";
	
	// 
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		DataElement.Roles.Add().Role = Selection.Role;
	EndDo;
	
EndProcedure

// For internal use only.
Procedure DeleteExtensionsRoles(DataElement) Export
	
	IndexOf = DataElement.Roles.Count() - 1;
	While IndexOf >= 0 Do
		If TypeOf(DataElement.Roles[IndexOf].Role) <> Type("CatalogRef.MetadataObjectIDs") Then
			DataElement.Roles.Delete(IndexOf);
		EndIf;
		IndexOf = IndexOf - 1;
	EndDo;
	
EndProcedure

// For internal use only.
Procedure DeleteExtensionsRolesInAllAccessGroupsProfiles() Export
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	ProfilesRoles.Ref AS Ref
	|FROM
	|	Catalog.AccessGroupProfiles.Roles AS ProfilesRoles
	|WHERE
	|	VALUETYPE(ProfilesRoles.Role) <> TYPE(Catalog.MetadataObjectIDs)";
	
	HasChanges = False;
	
	//  
	// 
	// 
	Selection = Query.Execute().Select();
	// 
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.AccessGroupProfiles");
	
	While Selection.Next() Do
		LockItem.SetValue("Ref", Selection.Ref);
		BeginTransaction();
		Try
			Block.Lock();
			ProfileObject = Selection.Ref.GetObject();
			If ProfileObject <> Undefined Then
				DeleteExtensionsRoles(ProfileObject);
				If ProfileObject.Modified() Then
					InfobaseUpdate.WriteObject(ProfileObject, False);
					HasChanges = True;
				EndIf;
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
	If HasChanges Then
		InformationRegisters.AccessGroupsTables.UpdateRegisterData();
	EndIf;
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  DataElement - CatalogObject.AccessGroupProfiles
//                - ObjectDeletion
//
Procedure RegisterChangeUponDataImport(DataElement) Export
	
	If TypeOf(DataElement) = Type("CatalogObject.AccessGroupProfiles") Then
		FillStandardExtensionRoles(DataElement.Roles);
	EndIf;
	
	// 
	// 
	
	PreviousValues1 = Common.ObjectAttributesValues(DataElement.Ref,
		"Ref, DeletionMark, Roles, Purpose, AccessKinds, AccessValues");
	
	Required2Registration = False;
	Profile = DataElement.Ref;
	ModifiedRoles = Undefined;
	
	If TypeOf(DataElement) = Type("ObjectDeletion") Then
		If PreviousValues1.Ref = Undefined Then
			Return;
		EndIf;
		Required2Registration = True;
		ModifiedRoles = ?(PreviousValues1.DeletionMark, New Array,
			PreviousValues1.Roles.Unload().UnloadColumn("Role"));
		
	ElsIf PreviousValues1.Ref <> DataElement.Ref Then
		Required2Registration = True;
		Profile = UsersInternal.ObjectRef2(DataElement);
		ModifiedRoles = ?(DataElement.DeletionMark, New Array,
			DataElement.Roles.UnloadColumn("Role"));
		
	ElsIf PreviousValues1.DeletionMark <> DataElement.DeletionMark Then
		Required2Registration = True;
		ModifiedRoles = ?(DataElement.DeletionMark,
			PreviousValues1.Roles.Unload().UnloadColumn("Role"),
			DataElement.Roles.UnloadColumn("Role"));
		
	ElsIf AccessKindsOrValuesOrAssignmentChanged(PreviousValues1, DataElement) Then
		Required2Registration = True;
	EndIf;
	
	If ModifiedRoles = Undefined Then
		OldRoles = PreviousValues1.Roles.Unload(); // ValueTable
		OldRoles.Indexes.Add("Role");
		NewRoles = DataElement.Roles.Unload();
		NewRoles.Indexes.Add("Role");
		ModifiedRoles = New Array;
		For Each String In NewRoles Do
			If OldRoles.Find(String.Role, "Role") = Undefined Then
				ModifiedRoles.Add(String.Role);
			EndIf;
		EndDo;
		For Each String In OldRoles Do
			If NewRoles.Find(String.Role, "Role") = Undefined Then
				ModifiedRoles.Add(String.Role);
			EndIf;
		EndDo;
		If ModifiedRoles.Count() > 0 Then
			Required2Registration = True;
		EndIf;
	EndIf;
	
	If Not Required2Registration Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	UsersInternal.RegisterRefs("AccessGroupProfiles", Profile);
	
	If AccessManagementInternal.LimitAccessAtRecordLevelUniversally() Then
		UsersInternal.RegisterRefs("AccessGroupProfilesRoles", ModifiedRoles);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure ProcessChangeRegisteredUponDataImport() Export
	
	If Common.DataSeparationEnabled() Then
		// 
		Return;
	EndIf;
	
	ChangedProfiles = UsersInternal.RegisteredRefs("AccessGroupProfiles");
	
	If ChangedProfiles.Count() = 0 Then
		Return;
	EndIf;
	
	If ChangedProfiles.Count() = 1
	   And ChangedProfiles[0] = Undefined Then
		
		UpdateAuxiliaryProfilesData();
	Else
		UpdateAuxiliaryProfilesData(ChangedProfiles);
	EndIf;
	
	UsersInternal.RegisterRefs("AccessGroupProfiles", Null);
	
	If Not AccessManagementInternal.LimitAccessAtRecordLevelUniversally() Then
		Return;
	EndIf;
	
	ModifiedRoles = UsersInternal.RegisteredRefs("AccessGroupProfilesRoles");
	If ModifiedRoles.Count() = 0 Then
		Return;
	EndIf;
	
	If ModifiedRoles.Count() = 1
	   And ModifiedRoles[0] = Undefined Then
		
		ModifiedRoles = Undefined;
	EndIf;
	
	AccessManagementInternal.ScheduleAccessUpdatesWhenProfileRolesChange(
		"UpdateAuxiliaryProfilesDataChangedOnImport", ModifiedRoles);
	
	UsersInternal.RegisterRefs("AccessGroupProfilesRoles", Null);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See also updating the information base undefined.customizingmachine infillingelements
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = False;
	
EndProcedure

// See also updating the information base undefined.At firstfillingelements
// 
// Parameters:
//   LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//   Items - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//   TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	Item = Items.Add();
	Item.PredefinedDataName = "Administrator";
	Item.Description = NStr("en = 'Administrator';", Common.DefaultLanguageCode());
	Item.SuppliedDataID =
		New UUID(AdministratorProfileID());
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

Function FilledSuppliedProfiles()
	
	ParametersOfUpdate = New Structure;
	// 
	ParametersOfUpdate.Insert("UpdateModifiedProfiles", True);
	ParametersOfUpdate.Insert("DenyProfilesChange", True);
	// 
	ParametersOfUpdate.Insert("UpdatingAccessGroups", True);
	ParametersOfUpdate.Insert("UpdatingAccessGroupsWithObsoleteSettings", False);
	
	ProfilesDetails = New Array;
	
	// 
	AdministratorProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	FillAdministratorProfile(AdministratorProfileDetails);
	ProfilesDetails.Add(AdministratorProfileDetails);
	
	DescriptionOfTheProfileFolder = AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder();
	FillInTheProfilesFolderAdditionalProfiles(DescriptionOfTheProfileFolder);
	ProfilesDetails.Add(DescriptionOfTheProfileFolder);
	
	SSLSubsystemsIntegration.OnFillSuppliedAccessGroupProfiles(
		ProfilesDetails, ParametersOfUpdate);
	
	AccessManagementOverridable.OnFillSuppliedAccessGroupProfiles(
		ProfilesDetails, ParametersOfUpdate);
	
	If ProfilesDetails.Find(AdministratorProfileDetails) = Undefined Then
		ProfilesDetails.Add(AdministratorProfileDetails);
	EndIf;
	
	FillAdministratorProfile(AdministratorProfileDetails, True);
	
	If Not Common.DataSeparationEnabled() Then
		ProfilesDetails.Add(
			AccessManagementInternal.OpenExternalReportsAndDataProcessorsProfileDetails());
	EndIf;
	
	Return New Structure("ProfilesDetails, ParametersOfUpdate", ProfilesDetails, ParametersOfUpdate);
	
EndFunction

// For the function, filled-in Deliverableprofiles.
//
// Parameters:
//    AdministratorProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
//
Procedure FillAdministratorProfile(AdministratorProfileDetails, ExcludeDetails = False)
	
	If ExcludeDetails Then
		LongDesc = AdministratorProfileDetails.LongDesc;
	Else
		LongDesc =
			NStr("en = 'The profile is intended to:
			           |- Configure and manage information system parameters.
			           |- Assign user access rights.
			           |- Delete objects marked for deletion.
			           |- Edit the configuration (in rare cases).
			           |
			           |It is recommended that you do not use it for regular operations in the information system.';");
	EndIf;
	
	FillPropertyValues(AdministratorProfileDetails,
		AccessManagement.NewAccessGroupProfileDescription());
	
	AdministratorProfileDetails.Name           = "Administrator";
	AdministratorProfileDetails.Id = AdministratorProfileID();
	AdministratorProfileDetails.Description  = NStr("en = 'Administrator';", Common.DefaultLanguageCode());
	AdministratorProfileDetails.Roles.Add("SystemAdministrator");
	AdministratorProfileDetails.Roles.Add("FullAccess");
	AdministratorProfileDetails.LongDesc = LongDesc;
	
EndProcedure

// For the function, filled-in Deliverableprofiles.
//
// Parameters:
//    Descriptionprofile Administrator -  See AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder
//
Procedure FillInTheProfilesFolderAdditionalProfiles(FolderDescription_)
	
	FolderDescription_ = AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder();
	FolderDescription_.Name           = "AdditionalProfiles";
	FolderDescription_.Id = "69a066e7-ce81-11eb-881c-b06ebfbf08c7";
	FolderDescription_.Description  = NStr("en = 'Additional profiles';", Common.DefaultLanguageCode());
	
EndProcedure

// 
// 
//
// Parameters:
//  AccessKindsProperties - See AccessManagementInternal.AccessKindsProperties
//                       - Undefined
//  HashSum - String -  the return value.
//
// Returns:
//   See AccessManagementInternal.SuppliedProfiles
//
Function VerifiedSuppliedSessionProfiles(AccessKindsProperties = Undefined, HashSum = "") Export
	
	FilledSuppliedProfiles = FilledSuppliedProfiles();
	ParametersOfUpdate = FilledSuppliedProfiles.ParametersOfUpdate;
	ProfilesDetails    = FilledSuppliedProfiles.ProfilesDetails; // Array of See AccessManagement.NewAccessGroupProfileDescription
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'In common module ""%2"",
		           |procedure ""%1"" contains invalid values.';"),
		"OnFillSuppliedAccessGroupProfiles",
		"AccessManagementOverridable")
		+ Chars.LF
		+ Chars.LF;
	
	If ParametersOfUpdate.DenyProfilesChange
	   And Not ParametersOfUpdate.UpdateModifiedProfiles Then
		
		ErrorText = ErrorTitle +  StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'In parameter ""%1"", 
			           |property ""%2"" is set to ""False"".
			           |Property ""%3""
			           |must be ""False"", too.';"),
			"ParametersOfUpdate",
			"UpdateModifiedProfiles",
			"DenyProfilesChange");
		Raise ErrorText;
	EndIf;
	
	AllRoles = UsersInternal.AllRoles().Map;
	If AccessKindsProperties = Undefined Then
		AccessKindsProperties = AccessManagementInternal.AccessKindsProperties();
	EndIf;
	
	// 
	// 
	AllNames           = New Map;
	AllIDs  = New Map;
	ProfileFolderNames = New Map;
	ProfileList     = New ValueList;
	
	For Each ProfileDetails In ProfilesDetails Do
		ProfileDetails.Delete("LongDesc");
		IsFolder = ProfileDetails.Is_Directory;
		
		If Not ValueIsFilled(ProfileDetails.Id) Then
			ErrorTemplate = ?(IsFolder,
				NStr("en = 'Property ""%2"" is not specified for profile folder ""%1"".';"),
				NStr("en = 'Property ""%2"" is not specified for profile ""%1"".';"));
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
				?(ValueIsFilled(ProfileDetails.Name), ProfileDetails.Name, ProfileDetails.Description),
				"Id");
			Raise ErrorText;
		ElsIf Not StringFunctionsClientServer.IsUUID(ProfileDetails.Id) Then
			ErrorTemplate = ?(IsFolder,
				NStr("en = 'Profile folder ""%1"" contains invalid ID: ""%2"".';"),
				NStr("en = 'Profile ""%1"" contains invalid ID: ""%2"".';"));
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
				?(ValueIsFilled(ProfileDetails.Name), ProfileDetails.Name, ProfileDetails.Description),
				ProfileDetails.Id);
			Raise ErrorText;
		EndIf;
		
		ProfileProperties = New Structure;
		ProfileProperties.Insert("Name",           "");
		ProfileProperties.Insert("Parent",      "");
		ProfileProperties.Insert("Id", "");
		ProfileProperties.Insert("Description",  "");
		FillPropertyValues(ProfileProperties, ProfileDetails);
		ProfileProperties.Insert("IsFolder", IsFolder);
		
		If AllIDs.Get(Upper(ProfileProperties.Id)) <> Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'In another profile or profile folder, property ""%2"" already contains value ""%1"".';"),
				ProfileProperties.Id, "Id");
			Raise ErrorText;
		EndIf;
		AllIDs.Insert(Upper(ProfileProperties.Id), True);
		ProfileList.Add(ProfileProperties, Lower(ProfileProperties.Id));
		
		If IsFolder And Not ValueIsFilled(ProfileProperties.Name) Then
			ErrorText =  ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Property ""%2"" is not specified for profile folder ""%1"".';"),
				?(ValueIsFilled(ProfileDetails.Description), ProfileDetails.Description, ProfileDetails.Id),
				"Name");
			Raise ErrorText;
		ElsIf ValueIsFilled(ProfileProperties.Name) Then
			If TrimAll(ProfileProperties.Name) <> ProfileProperties.Name Then
				ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'In a profile or profile folder, property ""%2"" has value ""%1"" with non-printable characters.';"),
					ProfileProperties.Name, "Name");
				Raise ErrorText;
			EndIf;
			If AllNames.Get(Upper(ProfileProperties.Name)) <> Undefined Then
				ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'In another profile or profile folder, property ""%2"" already contains value ""%1"".';"),
					ProfileProperties.Name, "Name");
				Raise ErrorText;
			EndIf;
			AllNames.Insert(Upper(ProfileProperties.Name), True);
		EndIf;
		
		If IsFolder Then
			ProfileFolderNames.Insert(Upper(ProfileProperties.Name), ProfileProperties.Parent);
			Continue;
		EndIf;
		
		PrepareThePurposeOfTheSuppliedProfile(ProfileProperties, ProfileDetails, ErrorTitle);
		
		ProfileAssignment = AccessManagementInternalClientServer.ProfileAssignment(ProfileProperties);
		PrepareTheRolesOfTheSuppliedProfile(ProfileProperties, ProfileDetails, ProfileAssignment, AllRoles, ErrorTitle);
		
		PrepareTheTypesOfAccessForTheSuppliedProfile(ProfileProperties, ProfileDetails, ProfileAssignment, AccessKindsProperties, ErrorTitle);
		PrepareTheAccessValuesOfTheSuppliedProfile(ProfileProperties, ProfileDetails, AccessKindsProperties, ErrorTitle);
	EndDo;
	
	For Each ProfileDetails In ProfilesDetails Do
		If Not ValueIsFilled(ProfileDetails.Parent) Then
			Continue;
		EndIf;
		If ProfileFolderNames.Get(Upper(ProfileDetails.Parent)) <> Undefined Then
			Continue;
		EndIf;
		ErrorTemplate = ?(ProfileDetails.Is_Directory,
			NStr("en = 'In the details of profile folder ""%1"",
			           |property ""%2"" contains a non-existent name ""%3"".';"),
			NStr("en = 'In the details of profile ""%1"",
			           |property ""%2"" contains a non-existent name ""%3"".';"));
		ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
			?(ValueIsFilled(ProfileDetails.Name), ProfileDetails.Name, ProfileDetails.Description),
			"Parent", ProfileDetails.Parent);
		Raise ErrorText;
	EndDo;
	
	FoldersByParents = New Map;
	For Each ProfileDetails In ProfilesDetails Do
		If Not ProfileDetails.Is_Directory Then
			Continue;
		EndIf;
		ParentFolders = FoldersByParents.Get(ProfileDetails.Parent);
		If ParentFolders = Undefined Then
			ParentFolders = New Map;
			FoldersByParents.Insert(ProfileDetails.Parent, ParentFolders);
		EndIf;
		ParentFolders.Insert(ProfileDetails.Name, True);
		If Not ValueIsFilled(ProfileDetails.Parent) Then
			Continue;
		EndIf;
		FolderParents = New Array;
		Parent = ProfileDetails.Parent;
		While True Do
			FolderParents.Add(Parent);
			Parent = ProfileFolderNames.Get(Upper(Parent));
			If Not ValueIsFilled(Parent) Then
				Break;
			EndIf;
			If FolderParents.Find(Parent) = Undefined Then
				Continue;
			EndIf;
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'In the details of profile folder ""%1"", property ""%2""
				           |contains profile folder name ""%3""
				           |that causes a circular dependency: ""%4"".';"),
				?(ValueIsFilled(ProfileDetails.Name), ProfileDetails.Name, ProfileDetails.Description),
				"Parent",
				ProfileDetails.Parent,
				StrConcat(FolderParents, " -> "));
			Raise ErrorText;
		EndDo;
	EndDo;
	
	VersionDetails = New Structure("VersionProperties", New Array);
	AddVersionItem(VersionDetails, "Version", "1");
	AddVersionItem(VersionDetails, "PredefinedItemsNames",
		Metadata.Catalogs.AccessGroupProfiles.GetPredefinedNames());
	
	AddVersionProperties(VersionDetails, ParametersOfUpdate,
		"UpdateModifiedProfiles,
		|DenyProfilesChange,
		|UpdatingAccessGroups,
		|UpdatingAccessGroupsWithObsoleteSettings");
	
	ProfileList.SortByPresentation();
	ProfilesProperties = New Map;
	ProfilesDetailsArray = New Array;
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	For Each ProfileDetails In ProfileList Do
		ProfileProperties = New FixedStructure(ProfileDetails.Value);
		ProfilesDetailsArray.Add(ProfileProperties);
		ProfilesProperties.Insert(ProfileProperties.Id, ProfileProperties);
		If ValueIsFilled(ProfileProperties.Name) Then
			ProfilesProperties.Insert(ProfileProperties.Name, ProfileProperties);
		EndIf;
		VersionDetails.VersionProperties.Add("");
		AddVersionProperties(VersionDetails, ProfileProperties,
			"Name, Parent, Id, Description");
		If ProfileProperties.IsFolder Then
			Continue;
		EndIf;
		AddVersionProperties(VersionDetails, ProfileProperties, "Purpose, Roles");
		If DataSeparationEnabled Then
			RolesUnavailableInService = New ValueList;
			For Each RoleDetails In ProfileProperties.RolesUnavailableInService Do
				RolesUnavailableInService.Add(RoleDetails.Key);
			EndDo;
			RolesUnavailableInService.SortByValue();
			AddVersionItem(VersionDetails,
				"RolesUnavailableInService", RolesUnavailableInService.UnloadValues());
		EndIf;
		AccessKinds = New ValueList;
		For Each KeyAndValue In ProfileProperties.AccessKinds Do
			AccessValues = New ValueList;
			AccessKinds.Add(AccessValues, KeyAndValue.Key + " (" + KeyAndValue.Value + ")");
			For Each ValueDescription In ProfileProperties.AccessValues Do
				If ValueDescription.AccessKind = KeyAndValue.Key Then
					AccessValues.Add(ValueDescription.AccessValue);
				EndIf;
			EndDo;
			AccessValues.SortByValue();
		EndDo;
		AccessKinds.SortByPresentation();
		For Each ListItem In AccessKinds Do
			If ValueIsFilled(ListItem.Value) Then
				AddVersionItem(VersionDetails,
					ListItem.Presentation, ListItem.Value.UnloadValues());
			Else
				VersionDetails.VersionProperties.Add(ListItem.Presentation);
			EndIf;
		EndDo;
	EndDo;
	
	VersionString = StrConcat(VersionDetails.VersionProperties, Chars.LF);
	HashSum = AccessManagementInternal.HashAmountsData(VersionString);
	
	Result = New Structure;
	Result.Insert("ParametersOfUpdate",
		New FixedStructure(ParametersOfUpdate));
	
	Result.Insert("ProfilesDetails",
		New FixedMap(ProfilesProperties));
	
	Result.Insert("ProfilesDetailsArray",
		New FixedArray(ProfilesDetailsArray));
	
	Result.Insert("FoldersByParents",
		Common.FixedData(FoldersByParents));
	
	Return New FixedStructure(Result);
	
EndFunction

// For the function supplied profiles.
Procedure PrepareThePurposeOfTheSuppliedProfile(ProfileProperties, ProfileDetails, ErrorTitle)
	
	If ProfileDetails.Purpose.Count() = 0 Then
		ProfileDetails.Purpose.Add(Type("CatalogRef.Users"));
	EndIf;
	PurposeList = New ValueList;
	For Each Type In ProfileDetails.Purpose Do
		If TypeOf(Type) = Type("TypeDescription") Then
			Types = Type.Types();
		Else
			Types = CommonClientServer.ValueInArray(Type);
		EndIf;
		For Each Type In Types Do
			If TypeOf(Type) <> Type("Type")
			 Or Not Common.IsReference(Type)
			 Or Not Metadata.DefinedTypes.User.Type.ContainsType(Type)
			 Or Type <> Type("CatalogRef.Users")
			   And Not Metadata.DefinedTypes.ExternalUser.Type.ContainsType(Type) Then
				ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'An invalid assignment ""%2 (%3)""
					           |is specified in the details of profile ""%1"".
					           |An assignment with the following properties is expected:
					           |- The type is ""%4"".
					           |- It is based on a value specified in the %5 type collection.
					           |- It is based on a value from the %6 type collection, except for the %7 type.';"),
					?(ValueIsFilled(ProfileDetails.Name),
						ProfileDetails.Name, ProfileDetails.Id),
					String(Type),
					String(TypeOf(Type)),
					"Type",
					"User",
					"ExternalUser",
					"CatalogRef.Users");
				Raise ErrorText;
			EndIf;
			RefTypeDetails = New TypeDescription(CommonClientServer.ValueInArray(Type));
			Value = RefTypeDetails.AdjustValue(Undefined);
			PurposeList.Add(Value);
		EndDo;
	EndDo;
	
	PurposeList.SortByValue();
	ProfileProperties.Insert("Purpose",
		New FixedArray(PurposeList.UnloadValues()));
	
EndProcedure

// For the function supplied profiles.
Procedure PrepareTheRolesOfTheSuppliedProfile(ProfileProperties, ProfileDetails,
			ProfileAssignment, AllRoles, ErrorTitle)
	
	UnavailableRoles = UsersInternalCached.UnavailableRoles(ProfileAssignment, False);
	CheckedRoles = New Map;
	RoleIndex = ProfileDetails.Roles.Count();
	While RoleIndex > 0 Do
		RoleIndex = RoleIndex - 1;
		Role = ProfileDetails.Roles[RoleIndex];
		// 
		If AllRoles.Get(Role) = Undefined Then
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Role ""%3"" provided in profile
				           |""%1 (%2)"" does not exist.';"),
				ProfileDetails.Name,
				ProfileDetails.Id,
				Role);
			Raise ErrorText;
		EndIf;
		// 
		If CheckedRoles.Get(Upper(Role)) <> Undefined Then
			ProfileDetails.Roles.Delete(RoleIndex);
			Continue;
		EndIf;
		CheckedRoles.Insert(Upper(Role), True);
		// 
		If UnavailableRoles.Get(Role) <> Undefined Then
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Role ""%3"" provided in profile
				           |""%1 (%2)""
				           |does not match profile assignment
				           |""%4"".';"),
				ProfileDetails.Name,
				ProfileDetails.Id,
				Role,
				ProfileAssignmentPresentation(ProfileAssignment));
			Raise ErrorText;
		EndIf;
	EndDo;
	
	FillStandardExtensionRoles(ProfileDetails.Roles,
		AccessManagementInternalCached.DescriptionStandardRolesSessionExtensions().SessionRoles);
	
	RolesList = New ValueList;
	RolesList.LoadValues(ProfileDetails.Roles);
	RolesList.SortByValue();
	ProfileProperties.Insert("Roles",
		New FixedArray(RolesList.UnloadValues()));
	
	If Common.DataSeparationEnabled() Then
		// 
		// 
		ProfileProperties.Insert("RolesUnavailableInService",
			ProfileRolesUnavailableInService(ProfileDetails, ProfileAssignment));
	EndIf;
	
EndProcedure

// For the function supplied profiles.
Procedure PrepareTheTypesOfAccessForTheSuppliedProfile(ProfileProperties, ProfileDetails,
			ProfileAssignment, AccessKindsProperties, ErrorTitle)
	
	AccessKinds = New Map;
	For Each ListItem In ProfileDetails.AccessKinds Do
		AccessKindName       = ListItem.Value;
		AccessKindClarification = ListItem.Presentation;
		If AccessKindsProperties.ByNames.Get(AccessKindName) = Undefined Then
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Access kind ""%2"" specified in profile
				           |""%1"" does not exist.';"),
				?(ValueIsFilled(ProfileDetails.Name),
				  ProfileDetails.Name,
				  ProfileDetails.Id),
				AccessKindName);
			Raise ErrorText;
		EndIf;
		
		AccessKindMatchesProfileAssignment =
			AccessManagementInternalClientServer.AccessKindMatchesProfileAssignment(
				AccessKindName, ProfileAssignment);
		
		If Not AccessKindMatchesProfileAssignment Then
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Access kind ""%2"" specified in profile
				           |""%1""
				           |does not match profile assignment
				           |""%3"".';"),
				?(ValueIsFilled(ProfileDetails.Name),
				  ProfileDetails.Name,
				  ProfileDetails.Id),
				AccessKindName,
				ProfileAssignmentPresentation(ProfileAssignment));
			Raise ErrorText;
		EndIf;
		If AccessKindClarification <> ""
		   And AccessKindClarification <> "AllDeniedByDefault"
		   And AccessKindClarification <> "Predefined"
		   And AccessKindClarification <> "AllAllowedByDefault" Then
			
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'An invalid refinement ""%3""
				           |is specified in the details of profile ""%1"" for access kind ""%2.""
				           |
				           |The valid values are:
				           |- %4
				           |- %5
				           |- %6';"),
				?(ValueIsFilled(ProfileDetails.Name),
					ProfileDetails.Name,
					ProfileDetails.Id),
				AccessKindName,
				AccessKindClarification,
				"AllDeniedByDefault",
				"AllAllowedByDefault",
				"Predefined");
			Raise ErrorText;
		EndIf;
		AccessKinds.Insert(AccessKindName, AccessKindClarification);
	EndDo;
	ProfileProperties.Insert("AccessKinds", New FixedMap(AccessKinds));
	
EndProcedure

// For the function supplied profiles.
Procedure PrepareTheAccessValuesOfTheSuppliedProfile(ProfileProperties, ProfileDetails, AccessKindsProperties, ErrorTitle);
	
	// 
	AccessValues = New Array;
	AccessValuesTable = New ValueTable;
	AccessValuesTable.Columns.Add("AccessKind",      Metadata.DefinedTypes.AccessValue.Type);
	AccessValuesTable.Columns.Add("AccessValue", Metadata.DefinedTypes.AccessValue.Type);
	
	For Each ListItem In ProfileDetails.AccessValues Do
		Filter = New Structure;
		Filter.Insert("AccessKind",      ListItem.Value);
		Filter.Insert("AccessValue", ListItem.Presentation);
		AccessKind      = Filter.AccessKind;
		AccessValue = Filter.AccessValue;
		
		AccessKindProperties = AccessKindsProperties.ByNames.Get(AccessKind);
		If AccessKindProperties = Undefined Then
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Access Value ""%3""
				           |of profile ""%1""
				           |has invalid access kind:
				           |""%2"".';"),
				?(ValueIsFilled(ProfileDetails.Name),
				  ProfileDetails.Name,
				  ProfileDetails.Id),
				AccessKind,
				AccessValue);
			Raise ErrorText;
		EndIf;
		
		MetadataObject = Undefined;
		PointPosition = StrFind(AccessValue, ".");
		If PointPosition > 0 Then
			MetadataObjectKind = Left(AccessValue, PointPosition - 1);
			RowBalance = Mid(AccessValue, PointPosition + 1);
			PointPosition = StrFind(RowBalance, ".");
			If PointPosition > 0 Then
				MetadataObjectName = Left(RowBalance, PointPosition - 1);
				FullMetadataObjectName = MetadataObjectKind + "." + MetadataObjectName;
				MetadataObject = Common.MetadataObjectByFullName(FullMetadataObjectName);
			EndIf;
		EndIf;
		
		If MetadataObject = Undefined Then
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'An Access Value ""%3""
				           |specified for access kind ""%2""
				           |has the type that is not listed in the details
				           |of the ""%1"" profile.';"),
				?(ValueIsFilled(ProfileDetails.Name),
				  ProfileDetails.Name,
				  ProfileDetails.Id),
				AccessKind,
				AccessValue);
			Raise ErrorText;
		EndIf;
		
		Try
			AccessValuesBlankRef = Common.ObjectManagerByFullName(
				FullMetadataObjectName).EmptyRef();
		Except
			AccessValuesBlankRef = Undefined;
		EndTry;
		
		If AccessValuesBlankRef = Undefined Then
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The type of Access Value ""%3""
				           |specified in the details of the ""%1"" profile
				           |for access kind ""%2""
				           |is not a reference type.';"),
				?(ValueIsFilled(ProfileDetails.Name),
				  ProfileDetails.Name,
				  ProfileDetails.Id),
				AccessKind,
				AccessValue);
			Raise ErrorText;
		EndIf;
		AccessValueType = TypeOf(AccessValuesBlankRef);
		
		AccessKindPropertiesByType = AccessKindsProperties.ByValuesTypes.Get(AccessValueType); // See AccessManagementInternal.AccessKindProperties
		If AccessKindPropertiesByType = Undefined
		 Or AccessKindPropertiesByType.Name <> AccessKind Then
			
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The type of Access Value ""%3""
				           |specified in the details of the ""%1"" profile
				           |is not found in the properties of access kind ""%2"".';"),
				?(ValueIsFilled(ProfileDetails.Name),
				  ProfileDetails.Name,
				  ProfileDetails.Id),
				AccessKind,
				AccessValue);
			Raise ErrorText;
		EndIf;
		
		If AccessValuesTable.FindRows(Filter).Count() > 0 Then
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Duplicate Access Value ""%3""
				           |for access kind 
				           |""%2""
				           |in the details of the ""%1"" profile.';"),
				?(ValueIsFilled(ProfileDetails.Name),
				  ProfileDetails.Name,
				  ProfileDetails.Id),
				AccessKind,
				AccessValue);
			Raise ErrorText;
		EndIf;
		AccessValues.Add(New FixedStructure(Filter));
	EndDo;
	ProfileProperties.Insert("AccessValues", New FixedArray(AccessValues));

EndProcedure

// Returns the profile properties specified in the module being overridden,
// converted to a fixed save format in the database.
// For a detailed description of the properties, see the functions of the New description of the Access Group Profile and the new description of the Access Group Profile folder of
// the general Access Control module.
// 
// Parameters:
//   Id - String -  name or ID of the supplied profile.
// 
// Returns:
//   FixedStructure:
//     * Name - String
//     * Id - String
//     * IsFolder     - Boolean
//     * Description  - String
//     * Roles          - FixedArray of String
//     * Purpose    - FixedArray of DefinedType.User
//     * AccessKinds   - FixedMap of KeyAndValue:
//          * Key - String
//          * Value - String
//     * AccessValues - FixedArray of FixedStructure:
//          * AccessKind - String
//          * AccessValue - String
//   
//   Undefined - the profile does not exist.
//
Function SuppliedProfileProperties(Id) Export
	
	SuppliedProfiles = AccessManagementInternal.SuppliedProfiles();
	
	Return SuppliedProfiles.ProfilesDetails.Get(Id);
	
EndFunction

// Returns:
//   FixedMap of KeyAndValue:
//     * Key - String -  string ID of the supplied profile
//     * Value - String -  description of the supplied profile
//
Function SuppliedProfilesNote() Export
	
	ProfilesDetails = FilledSuppliedProfiles().ProfilesDetails; // Array of See AccessManagement.NewAccessGroupProfileDescription
	
	AccessKindsPresentation = New Map;
	
	For Each ProfileDetails In ProfilesDetails Do
		If ProfileDetails.Is_Directory Then
			AccessKindsPresentation.Insert(ProfileDetails.Id, "");
		Else
			AccessKindsPresentation.Insert(ProfileDetails.Id, ProfileDetails.LongDesc);
		EndIf;
	EndDo;
	
	Return New FixedMap(AccessKindsPresentation);
	
EndFunction

// We supply Profiles for the procedure.
Function ProfileAssignmentPresentation(ProfileAssignment)
	
	If ProfileAssignment = "BothForUsersAndExternalUsers" Then
		Return NStr("en = 'For users and external users';");
		
	ElsIf ProfileAssignment = "ForExternalUsers" Then
		Return NStr("en = 'For external users';");
	EndIf;
	
	Return NStr("en = 'For users';");
	
EndFunction

// For the procedure, update the composition of the defined profiles.
Function PredefinedProfilesMatch(NewProfiles, OldProfiles, Trash)
	
	If TypeOf(NewProfiles) <> TypeOf(OldProfiles) Then
		Return False;
	EndIf;
	
	PredefinedProfilesMatch =
		NewProfiles.Count() = OldProfiles.Count();
	
	For Each Profile In OldProfiles Do
		If NewProfiles.Find(Profile) = Undefined Then
			PredefinedProfilesMatch = False;
			Trash.Add(Profile);
		EndIf;
	EndDo;
	
	Return PredefinedProfilesMatch;
	
EndFunction

// For the procedure, update the supplied profiles.
Procedure UpdateTheSuppliedProfileFolders(Parent, CurrentProfileFolders, SuppliedProfiles, Trash, HasChanges)
	
	ParentFolders = SuppliedProfiles.FoldersByParents.Get(Parent);
	If Not ValueIsFilled(ParentFolders) Then
		Return;
	EndIf;
	
	For Each KeyAndValue In ParentFolders Do
		ProfileProperties = SuppliedProfiles.ProfilesDetails.Get(KeyAndValue.Key); // See Catalogs.AccessGroupProfiles.SuppliedProfileProperties
		
		Id = New UUID(ProfileProperties.Id);
		LineOfTheCurrentFolder = CurrentProfileFolders.Find(Id, "SuppliedDataID");
		If LineOfTheCurrentFolder <> Undefined Then
			LineOfTheCurrentFolder.Found = True;
		EndIf;
		// 
		If UpdateTheProfileOrProfileFolder(ProfileProperties, Trash, True) Then
			HasChanges = True;
		EndIf;
		// 
		UpdateTheSuppliedProfileFolders(KeyAndValue.Key,
			CurrentProfileFolders, SuppliedProfiles, Trash, HasChanges);
	EndDo;
	
EndProcedure

// For the procedure, update the supplied profiles.
Procedure MarkForDeletionObsoleteSuppliedData(FoldersOrProfiles, HasChanges, UpdatedProfiles = Undefined)
	
	If Not Catalogs.ExtensionsVersions.AllExtensionsConnected() Then
		Return;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.AccessGroupProfiles");
	
	For Each CurrentProfileRow In FoldersOrProfiles Do
		If CurrentProfileRow.Found Then
			Continue;
		EndIf;
		If Not CurrentProfileRow.IsFolder
		   And CurrentProfileRow.SuppliedProfileChanged Then
			Continue;
		EndIf;
		LockItem.SetValue("Ref", CurrentProfileRow.Ref);
		BeginTransaction();
		Try
			Block.Lock();
			ProfileObject = CurrentProfileRow.Ref.GetObject();
			If Not ProfileObject.DeletionMark Then
				ProfileObject.DeletionMark = True;
				InfobaseUpdate.WriteObject(ProfileObject);
				If UpdatedProfiles <> Undefined Then
					UpdatedProfiles.Add(ProfileObject.Ref);
				EndIf;
				HasChanges = True;
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

// For the procedure, update the supplied profiles.
Procedure UpdateTheSuppliedProfilesWithoutFolders(UpdatedProfiles, CurrentProfiles,
			CurrentProfileFolders, SuppliedProfiles, Trash, HasChanges)
	
	ProfilesDetails    = SuppliedProfiles.ProfilesDetailsArray;
	ParametersOfUpdate = SuppliedProfiles.ParametersOfUpdate;
	
	For Each ProfileProperties In ProfilesDetails Do
		ProfileProperties = ProfileProperties; // See Catalogs.AccessGroupProfiles.SuppliedProfileProperties
		If ProfileProperties.IsFolder Then
			Continue;
		EndIf;
		
		Id = New UUID(ProfileProperties.Id);
		CurrentProfileRow = CurrentProfiles.Find(Id, "SuppliedDataID");
		
		ProfileUpdated = False;
		
		If CurrentProfileRow = Undefined Then
			// 
			// 
			If UpdateTheProfileOrProfileFolder(ProfileProperties, Trash, True) Then
				HasChanges = True;
			EndIf;
			// 
			Profile = SuppliedProfileByID(ProfileProperties.Id);
			
		Else
			CurrentProfileRow.Found = True;
			
			Profile = CurrentProfileRow.Ref;
			If Not CurrentProfileRow.SuppliedProfileChanged
			 Or ParametersOfUpdate.UpdateModifiedProfiles Then
				// 
				// 
				ProfileUpdated = UpdateTheProfileOrProfileFolder(ProfileProperties, Trash, True);
			EndIf;
		EndIf;
		
		If ParametersOfUpdate.UpdatingAccessGroups Then
			ProfileAccessGroupsUpdated = Catalogs.AccessGroups.UpdateProfileAccessGroups(
				Profile, ParametersOfUpdate.UpdatingAccessGroupsWithObsoleteSettings);
			
			ProfileUpdated = ProfileUpdated Or ProfileAccessGroupsUpdated;
		EndIf;
		
		If ProfileUpdated Then
			HasChanges = True;
			UpdatedProfiles.Add(Profile);
		EndIf;
	EndDo;
	
EndProcedure

// For procedures, update the supplied file folders, update the supplied file folders, and
// Fill in the supplied profile.
//
// Replaces the existing or creates a new supplied access group profile according to its description.
//
// Parameters:
//  ProfileProperties - See SuppliedProfileProperties
//  Trash - Array
//            - Undefined
//  DoNotUpdateUsersRoles - Boolean
//
// Returns:
//  Boolean -  
//
Function UpdateTheProfileOrProfileFolder(ProfileProperties, Trash = Undefined, DoNotUpdateUsersRoles = False)
	
	ProfileChanged = False;
	PredefinedFolderOrProfileItemHasBeenDeleted = TypeOf(Trash) = Type("Array")
		And Trash.Find(ProfileProperties.Name) <> Undefined;
	
	ProfileReference = SuppliedProfileByID(ProfileProperties.Id);
	If ProfileReference = Undefined Then
		
		If ValueIsFilled(ProfileProperties.Name) Then
			Query = New Query;
			Query.Text =
			"SELECT
			|	AccessGroupProfiles.Ref AS Ref,
			|	AccessGroupProfiles.PredefinedDataName AS PredefinedDataName
			|FROM
			|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
			|WHERE
			|	AccessGroupProfiles.Predefined = TRUE
			|	AND AccessGroupProfiles.IsFolder = &IsFolder";
			Query.SetParameter("IsFolder", ProfileProperties.IsFolder);
			Selection = Query.Execute().Select();
			
			While Selection.Next() Do
				PredefinedItemName = Selection.PredefinedDataName;
				If Upper(ProfileProperties.Name) = Upper(PredefinedItemName) Then
					ProfileReference = Selection.Ref;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If ProfileReference = Undefined Then
			Query = New Query;
			Query.Text =
			"SELECT
			|	AccessGroupProfiles.Ref AS Ref
			|FROM
			|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
			|WHERE
			|	AccessGroupProfiles.Predefined = FALSE
			|	AND AccessGroupProfiles.IsFolder = &IsFolder
			|	AND AccessGroupProfiles.Ref = &Ref";
			Query.SetParameter("IsFolder", ProfileProperties.IsFolder);
			Query.SetParameter("Ref",
				GetRef(New UUID(ProfileProperties.Id)));
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				ProfileReference = Selection.Ref;
			EndIf;
		EndIf;
		
		If ProfileReference = Undefined
		   And ProfileProperties.IsFolder
		   And ValueIsFilled(ProfileProperties.Description) Then
			
			Query = New Query;
			Query.Text =
			"SELECT
			|	AccessGroupProfiles.Ref AS Ref
			|FROM
			|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
			|WHERE
			|	AccessGroupProfiles.Predefined = FALSE
			|	AND AccessGroupProfiles.IsFolder
			|	AND AccessGroupProfiles.Description = &Description";
			Query.SetParameter("Description", ProfileProperties.Description);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				ProfileReference = Selection.Ref;
			EndIf;
		EndIf;
		
		If ProfileReference = Undefined Then
			// 
			ProfileObject = ?(ProfileProperties.IsFolder, CreateFolder(), CreateItem());
		Else
			// 
			ProfileObject = ProfileReference.GetObject();
		EndIf;
		
		ProfileObject.SuppliedDataID =
			New UUID(ProfileProperties.Id);
		
		ProfileChanged = True;
	Else
		ProfileObject = ProfileReference.GetObject();
		ProfileChanged = SuppliedProfileChanged(ProfileObject)
			Or PredefinedFolderOrProfileItemHasBeenDeleted;
	EndIf;
	
	If ProfileChanged Then
		
		If Not InfobaseUpdate.InfobaseUpdateInProgress()
		   And Not InfobaseUpdate.IsCallFromUpdateHandler() Then
			
			LockDataForEdit(ProfileObject.Ref, ProfileObject.DataVersion);
		EndIf;
		
		If PredefinedFolderOrProfileItemHasBeenDeleted Then
			ProfileObject.DeletionMark = False;
		EndIf;
		
		ProfileObject.Description = ProfileProperties.Description;
		
		If ValueIsFilled(ProfileProperties.Parent) Then
			Parent = SuppliedProfileByID(ProfileProperties.Parent);
			If ValueIsFilled(Parent) Then
				ProfileObject.Parent = Parent;
			EndIf;
		EndIf;
		
		If Not ProfileProperties.IsFolder Then
			ProfileObject.Roles.Clear();
			For Each Role In ProfileRolesDetails(ProfileProperties) Do
				RoleMetadata = Metadata.Roles.Find(Role);
				If RoleMetadata = Undefined Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'When updating built-in profile ""%1"",
						           |a non-existent role ""%2"" has been found';"),
						ProfileProperties.Description,
						Role);
					Raise ErrorText;
				EndIf;
				ProfileObject.Roles.Add().Role =
					Common.MetadataObjectID(RoleMetadata);
			EndDo;
			
			ProfileObject.AccessKinds.Clear();
			For Each AccessKindDetails In ProfileProperties.AccessKinds Do
				AccessKindProperties = AccessManagementInternal.AccessKindProperties(AccessKindDetails.Key);
				String = ProfileObject.AccessKinds.Add();
				String.AccessKind        = AccessKindProperties.Ref;
				String.Predefined = AccessKindDetails.Value = "Predefined";
				String.AllAllowed      = AccessKindDetails.Value = "AllAllowedByDefault";
			EndDo;
			
			ProfileObject.AccessValues.Clear();
			For Each AccessValueDetails In ProfileProperties.AccessValues Do
				AccessKindProperties = AccessManagementInternal.AccessKindProperties(AccessValueDetails.AccessKind);
				ValueRow = ProfileObject.AccessValues.Add();
				ValueRow.AccessKind = AccessKindProperties.Ref;
				ValueRow.AccessValue = PredefinedValue(AccessValueDetails.AccessValue);
			EndDo;
			
			ProfileObject.Purpose.Clear();
			For Each AssignmentType In ProfileProperties.Purpose Do
				AssignmentRow1 = ProfileObject.Purpose.Add();
				AssignmentRow1.UsersType = AssignmentType;
			EndDo;
			
			If DoNotUpdateUsersRoles Then
				ProfileObject.AdditionalProperties.Insert("DoNotUpdateUsersRoles");
			EndIf;
		EndIf;
		
		If Not Catalogs.ExtensionsVersions.AllExtensionsConnected() Then
			PreviousValues1 = Common.ObjectAttributesValues(ProfileObject.Ref, "AccessKinds, AccessValues");
			RestoreNonexistentViewsFromAccessValue(PreviousValues1, ProfileObject);
		EndIf;
		
		InfobaseUpdate.WriteObject(ProfileObject);
		
		If Not InfobaseUpdate.InfobaseUpdateInProgress()
		   And Not InfobaseUpdate.IsCallFromUpdateHandler() Then
			
			UnlockDataForEdit(ProfileObject.Ref);
		EndIf;
		
	EndIf;
	
	Return ProfileChanged;
	
EndFunction

// For the functions supplied, the profile is changed and the Access profile group is updated.
Function ProfileRolesDetails(ProfileDetails)
	
	ProfileAssignment = AccessManagementInternalClientServer.ProfileAssignment(ProfileDetails);
	UnavailableRoles = UsersInternalCached.UnavailableRoles(ProfileAssignment);
	
	ProfileRolesDetails = New Array;
	
	For Each Role In ProfileDetails.Roles Do
		If UnavailableRoles.Get(Role) = Undefined Then
			ProfileRolesDetails.Add(Role);
		EndIf;
	EndDo;
	
	FillStandardExtensionRoles(ProfileRolesDetails);
	
	Return New FixedArray(ProfileRolesDetails);
	
EndFunction

// For the procedure, prepare the supplied profile.
Function ProfileRolesUnavailableInService(ProfileDetails, ProfileAssignment)
	
	UnavailableRoles = UsersInternalCached.UnavailableRoles(ProfileAssignment, True);
	UnavailableProfileRoles = New Map;
	
	For Each Role In ProfileDetails.Roles Do
		If UnavailableRoles.Get(Role) <> Undefined Then
			UnavailableProfileRoles.Insert(Role, True);
		EndIf;
	EndDo;
	
	Return New FixedMap(UnavailableProfileRoles);
	
EndFunction

// For the procedure, update the supplied profiles.
//
// Returns:
//  ValueTable:
//     * SuppliedDataID - UUID
//     * Ref - CatalogRef.AccessGroupProfiles
//     * IsFolder - Boolean
//
Function CurrentProfileFolders()
	
	Query = New Query;
	Query.SetParameter("BlankUUID",
		CommonClientServer.BlankUUID());
	Query.Text =
	"SELECT
	|	AccessGroupProfiles.SuppliedDataID AS SuppliedDataID,
	|	AccessGroupProfiles.Ref AS Ref,
	|	AccessGroupProfiles.IsFolder AS IsFolder,
	|	FALSE AS Found
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|WHERE
	|	AccessGroupProfiles.IsFolder
	|	AND AccessGroupProfiles.SuppliedDataID <> &BlankUUID";
	CurrentProfiles = Query.Execute().Unload();
	
	Return CurrentProfiles;
	
EndFunction

// For the procedure, update the supplied profiles.
//
// Returns:
//  ValueTable:
//     * SuppliedProfileChanged - Boolean
//     * SuppliedDataID - UUID
//     * Ref - CatalogRef.AccessGroupProfiles
//     * IsFolder - Boolean
//
Function CurrentProfiles()
	
	Query = New Query;
	Query.SetParameter("BlankUUID",
		CommonClientServer.BlankUUID());
	Query.Text =
	"SELECT
	|	AccessGroupProfiles.SuppliedProfileChanged AS SuppliedProfileChanged,
	|	AccessGroupProfiles.SuppliedDataID AS SuppliedDataID,
	|	AccessGroupProfiles.IsFolder AS IsFolder,
	|	AccessGroupProfiles.Ref AS Ref,
	|	FALSE AS Found
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|WHERE
	|	NOT AccessGroupProfiles.IsFolder
	|	AND AccessGroupProfiles.SuppliedDataID <> &BlankUUID";
	CurrentProfiles = Query.Execute().Unload();
	
	Return CurrentProfiles;
	
EndFunction

Function BasicNonSuppliedProfiles()
	
	SuppliedProfiles = AccessManagementInternal.SuppliedProfiles();
	SuppliedProfileIDs = New Array;
	
	For Each ProfileDetails In SuppliedProfiles.ProfilesDetailsArray Do
		If ProfileDetails.IsFolder Then
			Continue;
		EndIf;
		SuppliedProfileIDs.Add(
			New UUID(ProfileDetails.Id));
	EndDo;
	
	MainProfileRoles = New Array;
	MainProfileRoles.Add(Common.MetadataObjectID(
		Metadata.Roles.FullAccess.FullName()));
	MainProfileRoles.Add(Common.MetadataObjectID(
		Metadata.Roles.BasicAccessSSL.FullName()));
	MainProfileRoles.Add(Common.MetadataObjectID(
		Metadata.Roles.BasicAccessExternalUserSSL.FullName()));
	MainProfileRoles.Add(Common.MetadataObjectID(
		Metadata.Roles.SystemAdministrator.FullName()));
	
	Query = New Query;
	Query.SetParameter("SuppliedProfileIDs", SuppliedProfileIDs);
	Query.SetParameter("MainProfileRoles", MainProfileRoles);
	Query.Text =
	"SELECT DISTINCT
	|	AccessGroupProfiles.Ref AS Ref
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|WHERE
	|	NOT AccessGroupProfiles.IsFolder
	|	AND NOT AccessGroupProfiles.SuppliedDataID IN (&SuppliedProfileIDs)
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Catalog.AccessGroupProfiles.Roles AS ProfilesRoles
	|			WHERE
	|				ProfilesRoles.Ref = AccessGroupProfiles.Ref
	|				AND ProfilesRoles.Role IN (&MainProfileRoles))";
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// The Access group profile is incompatible for the function.
//
// Returns:
//  ValueTable:
//    * Ref - CatalogRef.AccessGroupProfiles
//    * Purpose - ValueTable:
//        ** UsersType - DefinedType.User
//    * Roles - ValueTable:
//        ** Role - CatalogRef.ExtensionObjectIDs
//                - CatalogRef.MetadataObjectIDs
//
Function ProfilesAssignmentAndRolesAccessGroup()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Profiles.Ref AS Ref,
	|	Profiles.Purpose.(
	|		UsersType AS UsersType
	|	) AS Purpose,
	|	Profiles.Roles.(
	|		Role AS Role
	|	) AS Roles
	|FROM
	|	Catalog.AccessGroupProfiles AS Profiles";
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#EndIf
