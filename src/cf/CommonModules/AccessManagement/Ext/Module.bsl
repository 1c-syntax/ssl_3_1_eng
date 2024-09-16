///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// 

// Verifies that the user has a role in one of the profiles of the access groups in which they participate,
// for example: the role of viewing the log of Registration, the role of printingneeded Documents.
//
// If an object (or sets of access values) is specified, then it is additionally checked
// that the access group grants Read access to the specified object (or the set of access values is allowed).
//
// Parameters:
//  Role           - String -  role name.
//
//  ObjectReference - AnyRef -  to the object for which sets of access values are being filled
//                   for checking Read rights.
//                 - ValueTable - :
//                     * SetNumber     - Number  -  a number that groups several rows into a separate set.
//                     * AccessKind      - String -  name of the access type specified in the module to be overridden.
//                     * AccessValue - DefinedType.AccessValue -  type of the access value
//                       specified in the module to be overridden.
//                       You can get an empty prepared table using the function
//                       Access value table for the General access control module
//                       (do not fill in the Read, Change columns).
//
//  User   - CatalogRef.Users
//                 - CatalogRef.ExternalUsers
//                 - Undefined - 
//                     
//
// Returns:
//  Boolean - 
//
Function HasRole(Val Role, Val ObjectReference = Undefined, Val User = Undefined) Export
	
	User = ?(ValueIsFilled(User), User, Users.AuthorizedUser());
	If Users.IsFullUser(User) Then
		Return True;
	EndIf;
	Role = Common.MetadataObjectID("Role." + Role);
	
	SetPrivilegedMode(True);
	
	If ObjectReference = Undefined Or Not LimitAccessAtRecordLevel() Then
		// 
		Query = New Query;
		Query.SetParameter("AuthorizedUser", User);
		Query.SetParameter("Role", Role);
		Query.Text =
		"SELECT TOP 1
		|	TRUE AS TrueValue
		|FROM
		|	Catalog.AccessGroups.Users AS AccessGroups_Users
		|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
		|		ON (UserGroupCompositions.User = &AuthorizedUser)
		|			AND (UserGroupCompositions.UsersGroup = AccessGroups_Users.User)
		|			AND (UserGroupCompositions.Used)
		|			AND (NOT AccessGroups_Users.Ref.DeletionMark)
		|		INNER JOIN Catalog.AccessGroupProfiles.Roles AS AccessGroupProfilesRoles
		|		ON AccessGroups_Users.Ref.Profile = AccessGroupProfilesRoles.Ref
		|			AND (AccessGroupProfilesRoles.Role = &Role)
		|			AND (NOT AccessGroupProfilesRoles.Ref.DeletionMark)";
		Return Not Query.Execute().IsEmpty();
	EndIf;
		
	If TypeOf(ObjectReference) = Type("ValueTable") Then
		AccessValuesSets = ObjectReference.Copy();
	Else
		AccessValuesSets = AccessValuesSetsTable();
		ObjectReference.GetObject().FillAccessValuesSets(AccessValuesSets);
		// 
		ReadSetsRows = AccessValuesSets.FindRows(New Structure("Read", True));
		SetsNumbers = New Map;
		For Each String In ReadSetsRows Do
			SetsNumbers.Insert(String.SetNumber, True);
		EndDo;
		IndexOf = AccessValuesSets.Count() - 1;
		While IndexOf >= 0 Do
			If SetsNumbers[AccessValuesSets[IndexOf].SetNumber] = Undefined Then
				AccessValuesSets.Delete(IndexOf);
			EndIf;
			IndexOf = IndexOf - 1;
		EndDo;
		AccessValuesSets.FillValues(False, "Read, Update");
	EndIf;
	
	// 
	AccessKindsNames = AccessManagementInternal.AccessKindsProperties().ByNames;
	
	For Each String In AccessValuesSets Do
		
		If String.AccessKind = "" Then
			Continue;
		EndIf;
		
		If Upper(String.AccessKind) = Upper("ReadRight1")
		 Or Upper(String.AccessKind) = Upper("EditRight") Then
			
			If TypeOf(String.AccessValue) <> Type("CatalogRef.MetadataObjectIDs") Then
				If Common.IsReference(TypeOf(String.AccessValue)) Then
					String.AccessValue = Common.MetadataObjectID(TypeOf(String.AccessValue));
				Else
					String.AccessValue = Undefined;
				EndIf;
			EndIf;
			
			If Upper(String.AccessKind) = Upper("EditRight") Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Error in function ""%1"" of module ""%2"".
					           |The access value set contains the ""%3"" access kind 
					           |for the table with ID ""%4"".
					           |The only additional right that can be included
					           |in the access restriction is Read.';"),
					"HasRole",
					"AccessManagement",
					"EditRight",
					String.AccessValue,
					"Reads");
				Raise ErrorText;
			EndIf;
		ElsIf AccessKindsNames.Get(String.AccessKind) <> Undefined
		      Or String.AccessKind = "RightsSettings" Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Error in function ""%1"" of module ""%2"".
				           |The access value set contains a known access kind ""%3.""
				           |It cannot contain this access kind.
				           |
				           |It can only contain special access kinds
				           |""%4"" and ""%5"".';"),
				"HasRole",
				"AccessManagement",
				String.AccessKind,
				"ReadRight1",
				"EditRight");
			Raise ErrorText;
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Error in function ""%1"" of module ""%2"".
				           |The access value set contains an unknown access kind ""%1"".';"),
				"HasRole",
				"AccessManagement",
				String.AccessKind);
			Raise ErrorText;
		EndIf;
		
		String.AccessKind = "";
	EndDo;
	
	// 
	AccessManagementInternal.PrepareAccessValuesSetsForWrite(Undefined, AccessValuesSets, True);
	
	// 
	// 
	
	Query = New Query;
	Query.SetParameter("AuthorizedUser", User);
	Query.SetParameter("Role", Role);
	Query.SetParameter("AccessValuesSets", AccessValuesSets);
	Query.SetParameter("RightsSettingsOwnersTypes", SessionParameters.RightsSettingsOwnersTypes);
	Query.Text =
	"SELECT DISTINCT
	|	AccessValuesSets.SetNumber,
	|	AccessValuesSets.AccessValue,
	|	AccessValuesSets.ValueWithoutGroups,
	|	AccessValuesSets.StandardValue
	|INTO AccessValuesSets
	|FROM
	|	&AccessValuesSets AS AccessValuesSets
	|
	|INDEX BY
	|	AccessValuesSets.SetNumber,
	|	AccessValuesSets.AccessValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AccessGroups_Users.Ref AS Ref
	|INTO AccessGroups
	|FROM
	|	Catalog.AccessGroups.Users AS AccessGroups_Users
	|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		ON (UserGroupCompositions.User = &AuthorizedUser)
	|			AND (UserGroupCompositions.UsersGroup = AccessGroups_Users.User)
	|			AND (UserGroupCompositions.Used)
	|			AND (NOT AccessGroups_Users.Ref.DeletionMark)
	|		INNER JOIN Catalog.AccessGroupProfiles.Roles AS AccessGroupProfilesRoles
	|		ON AccessGroups_Users.Ref.Profile = AccessGroupProfilesRoles.Ref
	|			AND (AccessGroupProfilesRoles.Role = &Role)
	|			AND (NOT AccessGroupProfilesRoles.Ref.DeletionMark)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Sets.SetNumber
	|INTO SetsNumbers
	|FROM
	|	AccessValuesSets AS Sets
	|
	|INDEX BY
	|	Sets.SetNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	AccessGroups AS AccessGroups
	|WHERE
	|	NOT(TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						SetsNumbers AS SetsNumbers
	|					WHERE
	|						TRUE IN
	|							(SELECT TOP 1
	|								TRUE
	|							FROM
	|								AccessValuesSets AS ValueSets
	|							WHERE
	|								ValueSets.SetNumber = SetsNumbers.SetNumber
	|								AND NOT TRUE IN
	|										(SELECT TOP 1
	|											TRUE
	|										FROM
	|											InformationRegister.DefaultAccessGroupsValues AS DefaultValues
	|										WHERE
	|											DefaultValues.AccessGroup = AccessGroups.Ref
	|											AND VALUETYPE(DefaultValues.AccessValuesType) = VALUETYPE(ValueSets.AccessValue)
	|											AND DefaultValues.NoSettings = TRUE)))
	|				AND NOT TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							SetsNumbers AS SetsNumbers
	|						WHERE
	|							TRUE IN
	|								(SELECT TOP 1
	|									TRUE
	|								FROM
	|									AccessValuesSets AS ValueSets
	|								WHERE
	|									ValueSets.SetNumber = SetsNumbers.SetNumber
	|									AND NOT TRUE IN
	|											(SELECT TOP 1
	|												TRUE
	|											FROM
	|												InformationRegister.DefaultAccessGroupsValues AS DefaultValues
	|											WHERE
	|												DefaultValues.AccessGroup = AccessGroups.Ref
	|												AND VALUETYPE(DefaultValues.AccessValuesType) = VALUETYPE(ValueSets.AccessValue)
	|												AND DefaultValues.NoSettings = TRUE))
	|							AND NOT FALSE IN
	|									(SELECT TOP 1
	|										FALSE
	|									FROM
	|										AccessValuesSets AS ValueSets
	|									WHERE
	|										ValueSets.SetNumber = SetsNumbers.SetNumber
	|										AND NOT CASE
	|												WHEN ValueSets.ValueWithoutGroups
	|													THEN TRUE IN
	|															(SELECT TOP 1
	|																TRUE
	|															FROM
	|																InformationRegister.DefaultAccessGroupsValues AS DefaultValues
	|																	LEFT JOIN InformationRegister.AccessGroupsValues AS Values
	|																	ON
	|																		Values.AccessGroup = AccessGroups.Ref
	|																			AND Values.AccessValue = ValueSets.AccessValue
	|															WHERE
	|																DefaultValues.AccessGroup = AccessGroups.Ref
	|																AND VALUETYPE(DefaultValues.AccessValuesType) = VALUETYPE(ValueSets.AccessValue)
	|																AND ISNULL(Values.ValueAllowed, DefaultValues.AllAllowed))
	|												WHEN ValueSets.StandardValue
	|													THEN CASE
	|															WHEN TRUE IN
	|																	(SELECT TOP 1
	|																		TRUE
	|																	FROM
	|																		InformationRegister.AccessValuesGroups AS AccessValuesGroups
	|																	WHERE
	|																		AccessValuesGroups.AccessValue = ValueSets.AccessValue
	|																		AND AccessValuesGroups.AccessValuesGroup = &AuthorizedUser)
	|																THEN TRUE
	|															ELSE TRUE IN
	|																	(SELECT TOP 1
	|																		TRUE
	|																	FROM
	|																		InformationRegister.DefaultAccessGroupsValues AS DefaultValues
	|																			INNER JOIN InformationRegister.AccessValuesGroups AS ValueGroups
	|																			ON
	|																				ValueGroups.AccessValue = ValueSets.AccessValue
	|																					AND DefaultValues.AccessGroup = AccessGroups.Ref
	|																					AND VALUETYPE(DefaultValues.AccessValuesType) = VALUETYPE(ValueSets.AccessValue)
	|																			LEFT JOIN InformationRegister.AccessGroupsValues AS Values
	|																			ON
	|																				Values.AccessGroup = AccessGroups.Ref
	|																					AND Values.AccessValue = ValueGroups.AccessValuesGroup
	|																	WHERE
	|																		ISNULL(Values.ValueAllowed, DefaultValues.AllAllowed))
	|														END
	|												WHEN ValueSets.AccessValue = VALUE(Enum.AdditionalAccessValues.AccessAllowed)
	|													THEN TRUE
	|												WHEN ValueSets.AccessValue = VALUE(Enum.AdditionalAccessValues.AccessDenied)
	|													THEN FALSE
	|												WHEN VALUETYPE(ValueSets.AccessValue) = TYPE(Catalog.MetadataObjectIDs)
	|													THEN TRUE IN
	|															(SELECT TOP 1
	|																TRUE
	|															FROM
	|																InformationRegister.AccessGroupsTables AS AccessGroupsTablesObjectRightCheck
	|															WHERE
	|																AccessGroupsTablesObjectRightCheck.AccessGroup = AccessGroups.Ref
	|																AND AccessGroupsTablesObjectRightCheck.Table = ValueSets.AccessValue)
	|												ELSE TRUE IN
	|															(SELECT TOP 1
	|																TRUE
	|															FROM
	|																InformationRegister.ObjectsRightsSettings AS RightsSettings
	|																	INNER JOIN InformationRegister.ObjectRightsSettingsInheritance AS SettingsInheritance
	|																	ON
	|																		SettingsInheritance.Object = ValueSets.AccessValue
	|																			AND RightsSettings.Object = SettingsInheritance.Parent
	|																			AND SettingsInheritance.UsageLevel < RightsSettings.ReadingPermissionLevel
	|																	INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|																	ON
	|																		UserGroupCompositions.User = &AuthorizedUser
	|																			AND UserGroupCompositions.UsersGroup = RightsSettings.User)
	|														AND NOT FALSE IN
	|																(SELECT TOP 1
	|																	FALSE
	|																FROM
	|																	InformationRegister.ObjectsRightsSettings AS RightsSettings
	|																		INNER JOIN InformationRegister.ObjectRightsSettingsInheritance AS SettingsInheritance
	|																		ON
	|																			SettingsInheritance.Object = ValueSets.AccessValue
	|																				AND RightsSettings.Object = SettingsInheritance.Parent
	|																				AND SettingsInheritance.UsageLevel < RightsSettings.ReadingProhibitionLevel
	|																		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|																		ON
	|																			UserGroupCompositions.User = &AuthorizedUser
	|																				AND UserGroupCompositions.UsersGroup = RightsSettings.User)
	|											END)))";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Verifies that the user is configured to allow permissions for the object.
//  For example, a file folder can have the rights "manage Rights", "Read", "change Folders",
// and the "Read" right is both a right for the file folder and a right for files.
//
// Parameters:
//  Right          - String -  the name of the right, as specified in the procedure for filling in the possibilty rights to configure the rights Of objects in the
//                   General access control module Undefined.
//
//  ObjectReference - CatalogRef
//                 - ChartOfCharacteristicTypesRef - 
//                   
//                   
//
//  User   - CatalogRef.Users
//                 - CatalogRef.ExternalUsers
//                 - Undefined - 
//                     
//
// Returns:
//  Boolean - 
//           
//
Function HasRight(Right, ObjectReference, Val User = Undefined) Export
	
	ForPrivilegedMode = True;
	If ValueIsFilled(User) Then
		ForPrivilegedMode = False;
	Else
		User = Users.AuthorizedUser();
	EndIf;
	If Users.IsFullUser(User,, ForPrivilegedMode) Then
		Return True;
	EndIf;
	
	If Not LimitAccessAtRecordLevel()
	 Or AccessManagementInternalCached.IsUserWithUnlimitedAccess(User) Then
		Return True;
	EndIf;
	
	SetPrivilegedMode(True);
	AvailableRights = AccessManagementInternal.RightsForObjectsRightsSettingsAvailable();
	RightsDetails = AvailableRights.ByTypes.Get(TypeOf(ObjectReference));
	
	If RightsDetails = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Details about rights valid for table ""%1"" are missing.';"),
			ObjectReference.Metadata().FullName());
		Raise ErrorText;
	EndIf;
	
	RightDetails = RightsDetails.Get(Right);
	
	If RightDetails = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Details about right ""%1"" for table ""%2"" are missing.';"),
			Right, ObjectReference.Metadata().FullName());
		Raise ErrorText;
	EndIf;
	
	If Not ValueIsFilled(ObjectReference) Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ObjectReference", ObjectReference);
	Query.SetParameter("User", User);
	Query.SetParameter("Right", Right);
	
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.ObjectsRightsSettings AS RightsSettings
	|					INNER JOIN InformationRegister.ObjectRightsSettingsInheritance AS SettingsInheritance
	|					ON
	|						SettingsInheritance.Object = &ObjectReference
	|							AND RightsSettings.Right = &Right
	|							AND SettingsInheritance.UsageLevel < RightsSettings.RightPermissionLevel
	|							AND RightsSettings.Object = SettingsInheritance.Parent
	|					INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|					ON
	|						UserGroupCompositions.User = &User
	|							AND UserGroupCompositions.UsersGroup = RightsSettings.User)
	|	AND NOT FALSE IN
	|				(SELECT TOP 1
	|					FALSE
	|				FROM
	|					InformationRegister.ObjectsRightsSettings AS RightsSettings
	|						INNER JOIN InformationRegister.ObjectRightsSettingsInheritance AS SettingsInheritance
	|						ON
	|							SettingsInheritance.Object = &ObjectReference
	|								AND RightsSettings.Right = &Right
	|								AND SettingsInheritance.UsageLevel < RightsSettings.RightProhibitionLevel
	|								AND RightsSettings.Object = SettingsInheritance.Parent
	|						INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|						ON
	|							UserGroupCompositions.User = &User
	|								AND UserGroupCompositions.UsersGroup = RightsSettings.User)";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Verifies that at the record level (and at the rights level), the specified user
// is allowed to read the object from the database.
// When a set of records is specified, all records in the database
// that match the Selection property are checked.
//
// Important: if the subsystem is running in the standard constraint mode and
// the user is specified, but not the current user,
// an exception will be raised (the Performance Option function is provided for checking).
//
// Parameters:
//  DataDetails - CatalogRef
//                 - DocumentRef
//                 - ChartOfCharacteristicTypesRef
//                 - ChartOfAccountsRef
//                 - ChartOfCalculationTypesRef
//                 - BusinessProcessRef
//                 - TaskRef
//                 - ExchangePlanRef - 
//                 - InformationRegisterRecordKey
//                 - AccumulationRegisterRecordKey
//                 - AccountingRegisterRecordKey
//                 - CalculationRegisterRecordKey - 
//                 - CatalogObject
//                 - DocumentObject
//                 - ChartOfCharacteristicTypesObject
//                 - ChartOfAccountsObject
//                 - ChartOfCalculationTypesObject
//                 - BusinessProcessObject
//                 - TaskObject
//                 - ExchangePlanObject - 
//                 - InformationRegisterRecordSet
//                 - AccumulationRegisterRecordSet
//                 - AccountingRegisterRecordSet
//                 - CalculationRegisterRecordSet - 
//                     
//
//  User   - CatalogRef.Users
//                 - CatalogRef.ExternalUsers
//                 - Undefined - 
//                   
//                   
//
// Returns:
//  Boolean
//
Function ReadingAllowed(DataDetails, User = Undefined) Export
	
	Return AccessManagementInternal.AccessAllowed(DataDetails, False,,, User);
	
EndFunction

// Verifies that at the record level (and at the rights level), the specified user
// is allowed to change an object in the database to an object in memory.
// For a new object, only the object in memory is checked.
// If a reference or record key is specified, only the object in the database is checked.
//
// Important: if the subsystem operates in the standard constraint mode,
// and not in the universal constraint mode, then the right is checked.
// Change to a table, and at the record level, only the Read right is checked.
// If a user is specified, but not the current user,
// an exception will be raised (for checking, the function productionvariant is provided).
//
// Parameters:
//  DataDetails - CatalogRef
//                 - DocumentRef
//                 - ChartOfCharacteristicTypesRef
//                 - ChartOfAccountsRef
//                 - ChartOfCalculationTypesRef
//                 - BusinessProcessRef
//                 - TaskRef
//                 - ExchangePlanRef - 
//                 - InformationRegisterRecordKey
//                 - AccumulationRegisterRecordKey
//                 - AccountingRegisterRecordKey
//                 - CalculationRegisterRecordKey - 
//                 - CatalogObject
//                 - DocumentObject
//                 - ChartOfCharacteristicTypesObject
//                 - ChartOfAccountsObject
//                 - ChartOfCalculationTypesObject
//                 - BusinessProcessObject
//                 - TaskObject
//                 - ExchangePlanObject - 
//                 - InformationRegisterRecordSet
//                 - AccumulationRegisterRecordSet
//                 - AccountingRegisterRecordSet
//                 - CalculationRegisterRecordSet - 
//                                                
//
//  User   - CatalogRef.Users
//                 - CatalogRef.ExternalUsers
//                 - Undefined - 
//                   
//                   
//
// Returns:
//  Boolean
//
Function EditionAllowed(DataDetails, User = Undefined) Export
	
	Return AccessManagementInternal.AccessAllowed(DataDetails, True,,, User);
	
EndFunction

// Does the same thing that the read function is Allowed, but if not allowed, an exception is thrown.
// 
// Parameters:
//  DataDetails - See ReadingAllowed.DataDetails
//
Procedure CheckReadAllowed(DataDetails) Export
	
	AccessManagementInternal.AccessAllowed(DataDetails, False, True);
	
EndProcedure

// Does the same thing that the change function is Allowed, but if not allowed, an exception is thrown.
// 
// Parameters:
//  DataDetails - See EditionAllowed.DataDetails
//
Procedure CheckChangeAllowed(DataDetails) Export
	
	AccessManagementInternal.AccessAllowed(DataDetails, True, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Assign access groups to a user profile by including
// them in a personal access group (only for simplified rights settings).
//
// Parameters:
//  User - CatalogRef.Users
//               - CatalogRef.ExternalUsers - 
//  Profile      - CatalogRef.AccessGroupProfiles -  the profile for which you want to find or create a personal
//                   access group and include the user in it.
//               - UUID - 
//                   
//               - String -  
//                   
//
Procedure EnableProfileForUser(User, Profile) Export
	EnableDisableUserProfile(User, Profile, True);
EndProcedure

// Canceling the assignment of access groups to the user profile by excluding
// them from the personal access group (only for simplified rights settings).
//
// Parameters:
//  User - CatalogRef.Users
//               - CatalogRef.ExternalUsers - 
//  Profile      - CatalogRef.AccessGroupProfiles -  the profile for which you want to find or create a personal
//                    access group and include the user in it.
//               - UUID - 
//                    
//               - String - 
//                    
//               - Undefined - 
//
Procedure DisableUserProfile(User, Profile = Undefined) Export
	EnableDisableUserProfile(User, Profile, False);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Checks whether a record-level access restriction is used.
//
// Returns:
//  Boolean - 
//
Function LimitAccessAtRecordLevel() Export
	
	SetPrivilegedMode(True);
	SetSafeModeDisabled(True);
	
	Result = AccessManagementInternalCached.ConstantLimitAccessAtRecordLevel();
	
	SetSafeModeDisabled(False);
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

// Returns a variant of how access restrictions work at the record level.
//
// Required for extended use of functions
// Canadatrust and Ismaningerstr in productive option.
//
// Returns:
//  Boolean - 
//
Function ProductiveOption() Export
	
	Return AccessManagementInternal.LimitAccessAtRecordLevelUniversally(False, True);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Event handler for the account form in the Server, which is embedded in the forms of reference items,
// documents, register entries, etc.to block the form if the change is prohibited.
//
// Parameters:
//  Form               - ClientApplicationForm -  form of an object element or register entry.
//
//  CurrentObject       - CatalogObject
//                      - DocumentObject
//                      - ChartOfCharacteristicTypesObject
//                      - ChartOfAccountsObject
//                      - ChartOfCalculationTypesObject
//                      - BusinessProcessObject
//                      - TaskObject
//                      - ExchangePlanObject -  the object being checked.
//                      - InformationRegisterRecordManager - 
//                      - InformationRegisterRecordSet
//                      - AccumulationRegisterRecordSet
//                      - AccountingRegisterRecordSet
//                      - CalculationRegisterRecordSet - 
//
Procedure OnReadAtServer(Form, CurrentObject) Export
	
	If AccessManagementInternal.AccessAllowed(CurrentObject, True, False, True) Then
		Return;
	EndIf;
	
	Form.ReadOnly = True;
	
EndProcedure

// Event handler for the post-write form in the Server, which is embedded in the forms
// of reference items, documents, register entries, etc.to speed
// up the launch of access updates for dependent objects when an update is scheduled.
//
// Parameters:
//  Form           - ClientApplicationForm -  form of an object element or register entry.
//
//  CurrentObject   - CatalogObject
//                  - DocumentObject
//                  - ChartOfCharacteristicTypesObject
//                  - ChartOfAccountsObject
//                  - ChartOfCalculationTypesObject
//                  - BusinessProcessObject
//                  - TaskObject
//                  - ExchangePlanObject -  the object being checked.
//                  - InformationRegisterRecordManager - 
//
//  WriteParameters - Structure -  standard parameter passed to the event handler.
//
Procedure AfterWriteAtServer(Form, CurrentObject, WriteParameters) Export
	
	AccessManagementInternal.StartAccessUpdate();
	
EndProcedure

// 

// Configures the access value form, which uses groups of access values
// to select allowed values in user access groups.
//
// It is only supported if the access value has one group of access values selected,
// rather than several.
//
// For the access Group form element associated with the access group detail, sets
// the list of access value groups in the selection parameter that grant access to change the access value.
//
// When creating a new access value, if the number of access value groups that grant access
// to change the access value is zero, an exception is thrown.
//
// If the database already has a group of access values that does not allow access to change the access value,
// or the number of access value groups that allow access to change the access value is zero,
// then the only View form property is set to True.
//
// If the record-level restriction is not used or the access type restriction is not used,
// then the form element is hidden.
//
// Parameters:
//  Form - ClientApplicationForm -  form of an access value
//            that uses groups to select allowed values.
//
//  AdditionalParameters - See ParametersOnCreateAccessValueForm
//
//  DeleteItems       - Undefined -  deprecated, additional Parameters should be used.
//  DeleteValueType    - Undefined -  deprecated, additional Parameters should be used.
//  DeleteCreateNewAccessValue - Undefined -  deprecated, additional Parameters should be used.
//
Procedure OnCreateAccessValueForm(Form, AdditionalParameters = Undefined,
			DeleteItems = Undefined, DeleteValueType = Undefined, DeleteCreateNewAccessValue = Undefined) Export
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		Attribute       = AdditionalParameters.Attribute;
		Items       = AdditionalParameters.Items;
		ValueType    = AdditionalParameters.ValueType;
		CreateNewAccessValue = AdditionalParameters.CreateNewAccessValue;
	Else
		Attribute       = AdditionalParameters;
		Items       = DeleteItems;
		ValueType    = DeleteValueType;
		CreateNewAccessValue = DeleteCreateNewAccessValue;
	EndIf;
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Error in procedure %1
		           |of common module %2.';"),
		"OnCreateAccessValueForm",
		"AccessManagement");
	
	If TypeOf(CreateNewAccessValue) <> Type("Boolean") Then
		Try
			FormObject = Form.Object; // DefinedType.AccessValue - 
			CreateNewAccessValue = Not ValueIsFilled(FormObject.Ref);
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = ErrorTitle + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Parameter ""%1"" is required. Automatic filling
				           |from form attribute ""%2"" is not available. Reason:
				           |%3';"),
				"CreateNewAccessValue",
				"Object.Ref",
				ErrorProcessing.BriefErrorDescription(ErrorInfo));
			Raise ErrorText;
		EndTry;
	EndIf;
	
	If TypeOf(ValueType) <> Type("Type") Then
		Try
			FormObject = Form.Object; // DefinedType.AccessValue - 
			AccessValueType = TypeOf(FormObject.Ref);
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = ErrorTitle + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Parameter ""%1"" is required. Automatic filling
				           |from form attribute ""%2"" is not available. Reason:
				           |%3';"),
				"ValueType",
				"Object.Ref",
				ErrorProcessing.BriefErrorDescription(ErrorInfo));
			Raise ErrorText;
		EndTry;
	Else
		AccessValueType = ValueType;
	EndIf;
	
	If Items = Undefined Then
		FormItems = New Array;
		FormItems.Add("AccessGroup");
		
	ElsIf TypeOf(Items) <> Type("Array") Then
		FormItems = New Array;
		FormItems.Add(Items);
	EndIf;
	
	GroupsProperties = AccessValueGroupsProperties(AccessValueType, ErrorTitle);
	
	If Attribute = Undefined Then
		Try
			AccessValuesGroup = Form.Object.AccessGroup;
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = ErrorTitle + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Parameter ""Attribute"" is required. Cannot populate is automatically
				           |form attribute ""%2"" due to:
				           |%3';"),
				"Attribute",
				"Object.AccessGroup",
				ErrorProcessing.BriefErrorDescription(ErrorInfo));
			Raise ErrorText;
		EndTry;
	Else
		PointPosition = StrFind(Attribute, ".");
		If PointPosition = 0 Then
			Try
				AccessValuesGroup = Form[Attribute];
			Except
				ErrorInfo = ErrorInfo();
				ErrorText = ErrorTitle + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Couldn''t get the value of form attribute ""%1""
					           |specified in parameter ""%2"". Reason:
					           |%3';"),
					Attribute,
					"Attribute",
					ErrorProcessing.BriefErrorDescription(ErrorInfo));
				Raise ErrorText;
			EndTry;
		Else
			Try
				AccessValuesGroup = Form[Left(Attribute, PointPosition - 1)][Mid(Attribute, PointPosition + 1)];
			Except
				ErrorInfo = ErrorInfo();
				ErrorText = ErrorTitle + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Couldn''t get the value of form attribute ""%1""
					           |specified in parameter ""%2"". Reason:
					           |%3';"),
					Attribute,
					"Attribute",
					ErrorProcessing.BriefErrorDescription(ErrorInfo));
				Raise ErrorText;
			EndTry;
		EndIf;
	EndIf;
	
	If TypeOf(AccessValuesGroup) <> GroupsProperties.Type Then
		ErrorText = ErrorTitle + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The ""%2"" access kind
			           |with ""%3"" value type
			           |specified in the overridable module is used for access values of ""%1"" type.
			           |This type does not match the ""%4"" type of the %5 attribute
			           |in the access value form.';"),
			String(AccessValueType),
			String(GroupsProperties.AccessKind),
			String(GroupsProperties.Type),
			String(TypeOf(AccessValuesGroup)),
			"AccessGroup");
		Raise ErrorText;
	EndIf;
	
	If Not AccessManagementInternal.AccessKindUsed(GroupsProperties.AccessKind) Then
		For Each Item In FormItems Do
			Form.Items[Item].Visible = False;
		EndDo;
		Return;
	EndIf;
	
	If Users.IsFullUser( , , False) Then
		Return;
	EndIf;
	
	If Not AccessRight("Update", Metadata.FindByType(AccessValueType)) Then
		Form.ReadOnly = True;
		Return;
	EndIf;
	
	ValuesGroupsForChange =
		AccessValuesGroupsAllowingAccessValuesChange(AccessValueType);
	
	If ValuesGroupsForChange.Count() = 0
	   And CreateNewAccessValue Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot add an item because this requires allowed ""%1"".';"),
			Metadata.FindByType(GroupsProperties.Type).Presentation());
		Raise ErrorText;
	EndIf;
	
	If ValuesGroupsForChange.Count() = 0
	 Or Not CreateNewAccessValue
	   And ValuesGroupsForChange.Find(AccessValuesGroup) = Undefined Then
		
		Form.ReadOnly = True;
		Return;
	EndIf;
	
	If CreateNewAccessValue
	   And Not ValueIsFilled(AccessValuesGroup)
	   And ValuesGroupsForChange.Count() = 1 Then
		
		If Attribute = Undefined Then
			Form.Object.AccessGroup = ValuesGroupsForChange[0];
		Else
			PointPosition = StrFind(Attribute, ".");
			If PointPosition = 0 Then
				Form[Attribute] = ValuesGroupsForChange[0];
			Else
				Form[Left(Attribute, PointPosition - 1)][Mid(Attribute, PointPosition + 1)] = ValuesGroupsForChange[0];
			EndIf;
		EndIf;
	EndIf;
	
	NewChoiceParameter = New ChoiceParameter(
		"Filter.Ref", New FixedArray(ValuesGroupsForChange));
	
	ChoiceParameters = New Array;
	ChoiceParameters.Add(NewChoiceParameter);
	
	For Each Item In FormItems Do
		Form.Items[Item].ChoiceParameters = New FixedArray(ChoiceParameters);
	EndDo;
	
EndProcedure

// 

// Description of additional parameters used in the procedure for creating the access value Form.
// 
// Returns:
//  Structure:
//    * Attribute       - Undefined -  means the name of the form's props " Object.Access group".
//                     - String - 
//
//    * Items       - Undefined -  indicates the name of the "access Group" form element.
//                     - String - 
//                     - Array - 
//
//    * ValueType    - Undefined -  means: get the type from the form's "Object.Link".
//                     - Type - 
//
//    * CreateNewAccessValue - Undefined -  means: get the value " not Value_filled(Form.An object.Link)"
//                       to determine whether a new access value is being created or not.
//                     - Boolean - 
//
Function ParametersOnCreateAccessValueForm() Export
	
	Return New Structure("Attribute, Items, ValueType, CreateNewAccessValue");
	
EndFunction

// Returns an array of groups of access values that allow changing access values.
//
// It is only supported when a single group of access values is selected, rather than multiple ones.
//
// Parameters:
//  AccessValuesType - Type -  type of access value reference.
//  ReturnAll1      - Boolean -  if True, if there are no restrictions
//                       (all are available), an array of all will be returned instead of Undefined.
//
// Returns:
//  Undefined - 
//  
//
Function AccessValuesGroupsAllowingAccessValuesChange(AccessValuesType, ReturnAll1 = False) Export
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Error in procedure %1
		           |of common module %2.';"),
		"AccessValuesGroupsAllowingAccessValuesChange",
		"AccessManagement");
	
	GroupsProperties = AccessValueGroupsProperties(AccessValuesType, ErrorTitle);
	
	If Not AccessRight("Read", Metadata.FindByType(GroupsProperties.Type)) Then
		Return New Array;
	EndIf;
	
	If Not AccessManagementInternal.AccessKindUsed(GroupsProperties.AccessKind)
	 Or Users.IsFullUser( , , False) Then
		
		If ReturnAll1 Then
			Query = New Query;
			Query.Text =
			"SELECT ALLOWED
			|	AccessValuesGroups.Ref AS Ref
			|FROM
			|	&AccessValueGroupsTable AS AccessValuesGroups";
			Query.Text = StrReplace(
				Query.Text, "&AccessValueGroupsTable", GroupsProperties.Table);
			
			Return Query.Execute().Unload().UnloadColumn("Ref");
		EndIf;
		
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("CurrentUser", Users.AuthorizedUser());
	Query.SetParameter("AccessValuesType",  GroupsProperties.ValueTypeBlankRef);
	
	Query.SetParameter("AccessValuesID",
		Common.MetadataObjectID(AccessValuesType));
	
	Query.Text =
	"SELECT
	|	AccessGroups.Ref
	|INTO UserAccessGroups
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.AccessGroupsTables AS AccessGroupsTables
	|			WHERE
	|				AccessGroupsTables.Table = &AccessValuesID
	|				AND AccessGroupsTables.AccessGroup = AccessGroups.Ref
	|				AND AccessGroupsTables.RightUpdate = TRUE)
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|					INNER JOIN Catalog.AccessGroups.Users AS AccessGroups_Users
	|					ON
	|						UserGroupCompositions.Used
	|							AND UserGroupCompositions.User = &CurrentUser
	|							AND AccessGroups_Users.User = UserGroupCompositions.UsersGroup
	|							AND AccessGroups_Users.Ref = AccessGroups.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AccessValuesGroups.Ref AS Ref
	|INTO ValueGroups
	|FROM
	|	&AccessValueGroupsTable AS AccessValuesGroups
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				UserAccessGroups AS UserAccessGroups
	|					INNER JOIN InformationRegister.DefaultAccessGroupsValues AS DefaultValues
	|					ON
	|						DefaultValues.AccessGroup = UserAccessGroups.Ref
	|							AND DefaultValues.AccessValuesType = &AccessValuesType
	|					LEFT JOIN InformationRegister.AccessGroupsValues AS Values
	|					ON
	|						Values.AccessGroup = UserAccessGroups.Ref
	|							AND Values.AccessValue = AccessValuesGroups.Ref
	|			WHERE
	|				ISNULL(Values.ValueAllowed, DefaultValues.AllAllowed))";
	Query.Text = StrReplace(Query.Text, "&AccessValueGroupsTable", GroupsProperties.Table);
	Query.TempTablesManager = New TempTablesManager;
	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
	Query.Text =
	"SELECT ALLOWED
	|	AccessValuesGroups.Ref AS Ref
	|FROM
	|	&AccessValueGroupsTable AS AccessValuesGroups
	|		INNER JOIN ValueGroups AS ValueGroups
	|		ON AccessValuesGroups.Ref = ValueGroups.Ref";
	
	Query.Text = StrReplace(
		Query.Text, "&AccessValueGroupsTable", GroupsProperties.Table);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Sets constant selections
// based on the allowed access values of the specified types within all access groups to the condition where the dynamic list is CREATED.
// This allows you to speed up the opening of a dynamic list in some cases.
// If the total number of allowed values is more than 100, the selection is not set.
//
// For the procedure to work, the dynamic list must have the main table
// installed, an arbitrary query installed, and a conversion of the form must be supported:
//   Query schemas = New Query Schemas;
//   Schema of the query.Set The Query Text(List.Query text);
//   List.Query text = Schema of the query.Get the query text();
// If this condition cannot be met, then you should add selections yourself
// using the resolved values function for dynamic search, as in this procedure.
//
// Parameters:
//  List          - DynamicList -  dynamic list in which you want to set the selection.
//  FiltersDetails - Map of KeyAndValue:
//    * Key     - String -  name of the field in the main table of the dynamic list
//                          to set the <Field> condition To (&allowed Values).
//    * Value - Type    -  type of access values to include in the
//                          "&allowed Values " parameter.
//               - Array - 
//
Procedure SetDynamicListFilters(List, FiltersDetails) Export
	
	If Not LimitAccessAtRecordLevel()
	 Or AccessManagementInternal.LimitAccessAtRecordLevelUniversally(False, True)
	 Or Users.IsFullUser(,, False) Then
		Return;
	EndIf;
	
	If TypeOf(List) <> Type("DynamicList") Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Error calling procedure ""%1"" of common module ""%2"".
			           |Value ""%4"" of parameter ""%3"" is not a dynamic list.';"),
			"SetDynamicListFilters",
			"AccessManagement",
			"List",
			String(List));
		Raise ErrorText;
	EndIf;
	
	If Not ValueIsFilled(List.MainTable) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Error calling procedure ""%1"" of common module ""%2"".
			           |The main table of the dynamic list passed to the procedure is not specified.';"),
			"SetDynamicListFilters",
			"AccessManagement");
		Raise ErrorText;
	EndIf;
	
	If Not List.CustomQuery Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Error calling procedure ""%1"" of common module ""%2"".
			           |The passed dynamic list is missing flag ""%3"".';"),
			"SetDynamicListFilters",
			"AccessManagement",
			"CustomQuery");
		Raise ErrorText;
	EndIf;
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(List.QueryText);
	Parameters = New Map;
	
	For Each FilterDetails In FiltersDetails Do
		FieldName = FilterDetails.Key;
		Values = AccessManagementInternal.AllowedDynamicListValues(
			List.MainTable, FilterDetails.Value);
		If Values = Undefined Then
			Continue;
		EndIf;
		
		Sources = QuerySchema.QueryBatch[0].Operators[0].Sources;
		Alias = "";
		For Each Source In Sources Do
			If Source.Source.TableName = List.MainTable Then
				Alias = Source.Source.Alias;
				Break;
			EndIf;
		EndDo;
		If Not ValueIsFilled(Alias) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Error calling procedure ""%1"" of common module ""%2"".
				           |Cannot find the alias of the ""%1"" main table
				           |of the dynamic list passed to the procedure.';"),
				"SetDynamicListFilters",
				"AccessManagement",
				List.MainTable);
			Raise ErrorText;
		EndIf;
		Filter = QuerySchema.QueryBatch[0].Operators[0].Filter;
		ParameterName = "AllowedFieldValues" + FieldName;
		Parameters.Insert(ParameterName, Values);
		
		Condition = Alias + "." + FieldName + " IN (&" + ParameterName + ")";
		Filter.Add(Condition);
	EndDo;
	
	List.QueryText = QuerySchema.GetQueryText();
	
	For Each KeyAndValue In Parameters Do
		UpdateDataCompositionParameterValue(List, KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
EndProcedure

// Returns an array of allowed values of the specified types within all access groups.
// Used in the configure dynamic list Selection procedure to speed up the opening of dynamic lists.
// 
// Parameters:
//  Table      - String -  the full name of the metadata object, such as " Document.Expense account".
//  ValuesType  - Type    -  type of access values to return the allowed values for.
//               - Array - 
//  User - Undefined -  returns the allowed values for the authorized user.
//               - CatalogRef.Users
//               - CatalogRef.ExternalUsers - 
//                   
//  ReturnAll   - Boolean -  if set to True, then all values will be returned - even
//                   if there are more than 100 of them.
//
// Returns:
//  Undefined - 
//                 
//  
//
Function AllowedDynamicListValues(Table, ValuesType, User = Undefined, ReturnAll = False) Export
	
	If Not LimitAccessAtRecordLevel()
	 Or Users.IsFullUser(User, , False) Then
		Return Undefined;
	EndIf;
	
	Return AccessManagementInternal.AllowedDynamicListValues(Table, ValuesType, , User, ReturnAll);
	
EndFunction

// Returns the access rights to the metadata objects of a reference type for the specified identifiers.
//
// Parameters:
//  IDs - Array -  value Spravochnike.IDs
//                            of metadown objects, reference-type objects to return permissions to.
//
// Returns:
//  Map of KeyAndValue:
//    * Key     - CatalogRef.MetadataObjectIDs - 
//    * Value - Structure:
//        ** Key     - String -  name of the access right ("Read", "Change", " Add");
//        ** Value - Boolean -  if it is True, then it is right, otherwise it is not.
//
Function RightsByIDs(IDs = Undefined) Export
	
	IDsMetadataObjects =
		Common.MetadataObjectsByIDs(IDs);
	
	RightsByIDs = New Map;
	For Each IDMetadataObject In IDsMetadataObjects Do
		MetadataObject = IDMetadataObject.Value;
		Rights = New Structure;
		Rights.Insert("Read",     AccessRight("Read",     MetadataObject));
		Rights.Insert("Update",  AccessRight("Update",  MetadataObject));
		Rights.Insert("Create", AccessRight("Insert", MetadataObject));
		RightsByIDs.Insert(IDMetadataObject.Key, Rights);
	EndDo;
	
	Return RightsByIDs;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Checks whether the metadata object has a procedure for filling in access value sets.
// 
// Parameters:
//  Ref - AnyRef -  a reference to any object.
//
// Returns:
//  Boolean - 
//
Function CanFillAccessValuesSets(Ref) Export
	
	ObjectType = Type(Common.ObjectKindByRef(Ref) + "Object." + Ref.Metadata().Name);
	
	SetsFilled = AccessManagementInternalCached.ObjectsTypesInSubscriptionsToEvents(
		"WriteAccessValuesSets
		|WriteDependentAccessValuesSets").Get(ObjectType) <> Undefined;
	
	Return SetsFilled;
	
EndFunction

// Returns an empty table that is filled in for passing to the Isrole function and
// to the populate access value Sets(table) procedures defined by the application developer.
//
// Returns:
//  ValueTable:
//    * SetNumber     - Number  -  optional if there is only one set.
//    * AccessKind      - String -  optional, except for special ones: right-Reading, right-Changing.
//    * AccessValue - DefinedType.AccessValue -  the type of access value specified for the type of access
//                        in the procedure for filling in the shared access control module Accessidentifiable.
//    * Read          - Boolean -  optional, if the set for all rights is set for a single row of the set.
//    * Update       - Boolean -  optional, if the set for all rights is set for a single row of the set.
//
Function AccessValuesSetsTable() Export
	
	SetPrivilegedMode(True);
	
	Table = New ValueTable;
	Table.Columns.Add("SetNumber",     New TypeDescription("Number", New NumberQualifiers(4, 0, AllowedSign.Nonnegative)));
	Table.Columns.Add("AccessKind",      New TypeDescription("String", , New StringQualifiers(20)));
	Table.Columns.Add("AccessValue", Metadata.DefinedTypes.AccessValue.Type);
	Table.Columns.Add("Read",          New TypeDescription("Boolean"));
	Table.Columns.Add("Update",       New TypeDescription("Boolean"));
	// 
	Table.Columns.Add("Refinement",       New TypeDescription("CatalogRef.MetadataObjectIDs"));
	
	Return Table;
	
EndFunction

// 
// 
// 
//
// 
// 
//
// 
//  
//
// 
//
//// See AccessManagement.FillAccessValuesSets.
//
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//
//
// Parameters:
//  Object  - AnyRef
//          - DefinedType.AccessValuesSetsOwnerObject - 
//            
//            
//
//  Table - See AccessValuesSetsTable
//          - Undefined-returns the prepared sets of access values in this parameter. 
//            If passed Undefined, a new table of access value sets will be created and populated.
//
//  SubordinateObjectRef - AnyRef - 
//            
//            
//
Procedure FillAccessValuesSets(Val Object, Table, Val SubordinateObjectRef = Undefined) Export
	
	SetPrivilegedMode(True);
	
	// 
	// 
	Object = ?(Object = Object.Ref, Object.GetObject(), Object);
	ObjectReference = Object.Ref;
	ValueTypeObject = TypeOf(Object);
	
	SetsFilled = AccessManagementInternalCached.ObjectsTypesInSubscriptionsToEvents(
		"WriteAccessValuesSets
		|WriteDependentAccessValuesSets").Get(ValueTypeObject) <> Undefined;
	
	If Not SetsFilled Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid parameters.
			           |Cannot find object type ""%1""
			           |in event subscriptions %2, %3.';"),
			ValueTypeObject,
			"WriteAccessValuesSets",
			"WriteDependentAccessValuesSets");
		Raise ErrorText;
	EndIf;
	
	Table = ?(TypeOf(Table) = Type("ValueTable"), Table, AccessValuesSetsTable());
	Try
		Object.FillAccessValuesSets(Table);
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1 ""%2""
			           |has not generated an access value set. Reason:
			           |%3';"),
			TypeOf(ObjectReference),
			Object,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		Raise ErrorText;
	EndTry;
	
	If Table.Count() = 0 Then
		// 
		// 
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1 ""%2""
			           |generated a blank access value set.';"),
			TypeOf(ObjectReference),
			Object);
		Raise ErrorText;
	EndIf;
	
	SpecifyAccessValuesSets(ObjectReference, Table);
	
	If SubordinateObjectRef = Undefined Then
		Return;
	EndIf;
	
	// 
	// 
	// 
	//
	// 
	// 
	
	// 
	AddAccessValuesSets(Table, AccessValuesSetsTable());
	
	// 
	ReadingSets     = AccessValuesSetsTable();
	ChangeSets  = AccessValuesSetsTable();
	For Each String In Table Do
		If String.Read Then
			NewRow = ReadingSets.Add();
			NewRow.SetNumber     = String.SetNumber + 1;
			NewRow.AccessKind      = String.AccessKind;
			NewRow.AccessValue = String.AccessValue;
			NewRow.Refinement       = String.Refinement;
		EndIf;
		If String.Update Then
			NewRow = ChangeSets.Add();
			NewRow.SetNumber     = (String.SetNumber + 1)*2;
			NewRow.AccessKind      = String.AccessKind;
			NewRow.AccessValue = String.AccessValue;
			NewRow.Refinement       = String.Refinement;
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	InformationRegister.AccessRightsDependencies AS AccessRightsDependencies
	|WHERE
	|	AccessRightsDependencies.SubordinateTable = &SubordinateTable
	|	AND AccessRightsDependencies.LeadingTableType = &LeadingTableType";
	
	Query.SetParameter("SubordinateTable", Common.MetadataObjectID(
		SubordinateObjectRef.Metadata().FullName()));
	
	TypesArray = New Array;
	TypesArray.Add(TypeOf(ObjectReference));
	TypeDescription = New TypeDescription(TypesArray);
	Query.SetParameter("LeadingTableType", TypeDescription.AdjustValue(Undefined));
	
	RightsDependencies = Query.Execute().Unload();
	Table.Clear();
	
	Id = Common.MetadataObjectID(TypeOf(ObjectReference));
	
	If RightsDependencies.Count() = 0 Then
		
		// 
		
		// 
		// 
		String = Table.Add();
		String.SetNumber     = 1;
		String.AccessKind      = "ReadRight1";
		String.AccessValue = Id;
		String.Read          = True;
		
		// 
		// 
		String = Table.Add();
		String.SetNumber     = 2;
		String.AccessKind      = "EditRight";
		String.AccessValue = Id;
		String.Update       = True;
		
		// 
		ReadingSets.FillValues(True, "Read");
		// 
		ChangeSets.FillValues(True, "Update");
		
		AddAccessValuesSets(ReadingSets, ChangeSets);
		AddAccessValuesSets(Table, ReadingSets, True);
	Else
		// 
		
		// 
		// 
		String = Table.Add();
		String.SetNumber     = 1;
		String.AccessKind      = "ReadRight1";
		String.AccessValue = Id;
		String.Read          = True;
		String.Update       = True;
		
		// 
		ReadingSets.FillValues(True, "Read");
		ReadingSets.FillValues(True, "Update");
		AddAccessValuesSets(Table, ReadingSets, True);
	EndIf;
	
EndProcedure

// Allows you to add another table of access value sets to one table
// by either logical addition or logical multiplication.
//
// The result is placed in the Receiver parameter.
//
// Parameters:
//  Receiver - ValueTable -  with columns as the table returned by the function Tablecolorizingrenderer.
//  Source - ValueTable -  with columns as the table returned by the function Tablecolorizingrenderer.
//
//  Multiplication - Boolean -  defines how the receiver and source sets are logically combined.
//  Simplify - Boolean -  determines whether sets need to be simplified after they are added.
//
Procedure AddAccessValuesSets(Receiver, Val Source, Val Multiplication = False, Val Simplify = False) Export
	
	If Source.Count() = 0 And Receiver.Count() = 0 Then
		Return;
		
	ElsIf Multiplication And ( Source.Count() = 0 Or  Receiver.Count() = 0 ) Then
		Receiver.Clear();
		Source.Clear();
		Return;
	EndIf;
	
	If Receiver.Count() = 0 Then
		Value = Receiver;
		Receiver = Source;
		Source = Value;
	EndIf;
	
	If Simplify Then
		
		// 
		// 
		//
		// 
		//  
		//     
		//     
		//  
		//     
		// 
		
		If Multiplication Then
			MultiplySetsAndSimplify(Receiver, Source);
		Else // Create
			AddSetsAndSimplify(Receiver, Source);
		EndIf;
	Else
		
		If Multiplication Then
			MultiplySets(Receiver, Source);
		Else // Create
			AddSets(Receiver, Source);
		EndIf;
	EndIf;
	
EndProcedure

// Updates the object's access value sets if they have changed.
// Sets are updated in the table part (if used) and
// in the data register of the access value Set.
//
// Parameters:
//  ReferenceOrObject - AnyRef
//                  - DefinedType.AccessValuesSetsOwnerObject - 
//                    
//  
//  IBUpdate    - Boolean -  if True, then you need to write data 
//                             without performing unnecessary, redundant actions with the data.
//                             See InfobaseUpdate.WriteData.
//
Procedure UpdateAccessValuesSets(ReferenceOrObject, IBUpdate = False) Export
	
	AccessManagementInternal.UpdateAccessValuesSets(ReferenceOrObject,, IBUpdate);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Returns a structure, for convenience of description of the supplied profiles.
//
// Returns:
//  Structure:
//   * Name           - String -  it can be used in the program interface,
//                        for example, in the procedure to enable the user profile.
//   * Parent      - String -  the name of the profile folder that the profile is included in.
//   * Id - String -  a string of the unique identifier of the supplied
//                       profile that is used for searching the database.
//                       To get the ID, you need to create a profile in 1C mode:Enter and
//                       get a unique link ID. You should not specify identifiers
//                       obtained in any arbitrary way, as this may violate the uniqueness of links.
//   * Description  - String -  name of the supplied profile.
//   * LongDesc      - String -  description of the supplied profile.
//   * Roles          - Array of String -  role names of the supplied profile.
//   * Purpose    - Array of Type -  types of user links and external
//                       user authorization objects. If empty, it means that the destination is for users.
//                       Must be within the composition of the user type being defined.
//   * AccessKinds   - ValueList:
//                     ** Value      - String - 
//                          
//                     ** Presentation - String - 
//                          
//
//   * AccessValues - ValueList:
//                     ** Value      - String -  name of the access type specified in the access View parameter.
//                     ** Presentation - String -  name of the predefined element, such
//                          as " reference.User groups.All users".
//
//   * Is_Directory - Boolean - 
//
// Example:
// 
//	
//	
//	
//	
//	
//	
//	
//		
//	
//		
//		           
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//	
//		
//	
//	
//
Function NewAccessGroupProfileDescription() Export
	
	NewDetails = New Structure;
	NewDetails.Insert("Name",             "");
	NewDetails.Insert("Parent",        "");
	NewDetails.Insert("Id",   "");
	NewDetails.Insert("Description",    "");
	NewDetails.Insert("LongDesc",        "");
	NewDetails.Insert("Roles",            New Array);
	NewDetails.Insert("Purpose",      New Array);
	NewDetails.Insert("AccessKinds",     New ValueList);
	NewDetails.Insert("AccessValues", New ValueList);
	NewDetails.Insert("Is_Directory",        False);
	
	Return NewDetails;
	
EndFunction

// Returns the structure for the convenience of describing the supplied profile folders (groups of elements).
//
// Returns:
//  Structure:
//   * Name           - String -  used in the Parent field for the profile and profile folder.
//   * Parent      - String -  the name of the other profile folder that this folder belongs to.
//   * Id - String -  the string of the unique identifier of the supplied
//                       profile folder, which is used for searching in the database.
//                       To get the ID, you need to create a profile folder in 1C mode:Enterprise and
//                       get a unique link ID. You should not specify identifiers
//                       obtained in an arbitrary way, because this may violate the uniqueness of links.
//   * Description  - String -  the name of the supplied profile folder.
//   * Is_Directory      - Boolean - 
//
// Example:
//	
//	
//	
//	
//	
//	
//	
//
Function NewDescriptionOfTheAccessGroupProfilesFolder() Export
	
	NewDetails = New Structure;
	NewDetails.Insert("Name",           "");
	NewDetails.Insert("Parent",      "");
	NewDetails.Insert("Id", "");
	NewDetails.Insert("Description",  "");
	NewDetails.Insert("Is_Directory",      True);
	
	Return NewDetails;
	
EndFunction

// Adds additional types in the procedure for filling in the
// General access control module's accessdeterminable.
//
// Parameters:
//  AccessKind             - ValueTableRow -  added to the access View parameter.
//  ValuesType            - Type -  additional type of access values.
//  ValuesGroupsType       - Type -  an additional type of access value groups can match
//                           the type of value groups specified earlier for the same type of access.
//  MultipleValuesGroups - Boolean -  True if
//                           you can specify multiple groups of values for an additional type of access values (there is a table part of access Groups).
// 
Procedure AddExtraAccessKindTypes(AccessKind, ValuesType,
		ValuesGroupsType = Undefined, MultipleValuesGroups = False) Export
	
	AdditionalTypes = AccessKind.AdditionalTypes; // See AccessManagementInternal.NewAdditionalAccessKindTypesTable
	
	If AdditionalTypes.Columns.Count() = 0 Then
		AdditionalTypes = AccessManagementInternal.NewAdditionalAccessKindTypesTable();
		AccessKind.AdditionalTypes = AdditionalTypes;
	EndIf;
	
	AdditionalTypes = AccessKind.AdditionalTypes;
	
	NewRow = AdditionalTypes.Add();
	NewRow.ValuesType            = ValuesType;
	NewRow.ValuesGroupsType       = ValuesGroupsType;
	NewRow.MultipleValuesGroups = MultipleValuesGroups;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Replaces roles in profiles, except for the supplied profiles, which are updated automatically.
// It is intended for calling from an online update handler.
//
// Parameters:
//  RolesToReplace - Map of KeyAndValue:
//    * Key     - String -  name model role, for example, "Changebaselayer". If the role was deleted,
//                          then add the prefix"? "for example "? Changebaselayer".
//
//    * Value - Array -  names of roles to replace the specified one (an empty array to delete the specified role,
//                          you can specify the role to replace, for example, when splitting into several roles).
//
Procedure ReplaceRolesInProfiles(RolesToReplace) Export
	
	RolesRefsToReplace = New Map;
	RolesToReplaceArray = New Array;
	
	For Each KeyAndValue In RolesToReplace Do
		If StrStartsWith(KeyAndValue.Key, "? ") Then
			RoleRefs = Catalogs.MetadataObjectIDs.DeletedMetadataObjectID(
				"Role." + TrimAll(Mid(KeyAndValue.Key, 3)));
		Else
			RoleRefs = New Array;
			RoleRefs.Add(Common.MetadataObjectID("Role." + KeyAndValue.Key));
		EndIf;
		For Each RoleRef1 In RoleRefs Do
			RolesToReplaceArray.Add(RoleRef1);
			NewRoles = New Array;
			RolesRefsToReplace.Insert(RoleRef1, NewRoles);
			For Each NewRole In KeyAndValue.Value Do
				NewRoles.Add(Common.MetadataObjectID("Role." + NewRole));
			EndDo;
		EndDo;
	EndDo;
	
	// 
	Query = New Query;
	Query.SetParameter("RolesToReplaceArray", RolesToReplaceArray);
	Query.SetParameter("BlankID",
		CommonClientServer.BlankUUID());
	
	Query.Text =
	"SELECT
	|	ProfilesRoles.Ref AS Profile,
	|	ProfilesRoles.Role AS Role
	|FROM
	|	Catalog.AccessGroupProfiles AS Profiles
	|		INNER JOIN Catalog.AccessGroupProfiles.Roles AS ProfilesRoles
	|		ON (ProfilesRoles.Ref = Profiles.Ref)
	|			AND (ProfilesRoles.Role IN (&RolesToReplaceArray))
	|			AND (Profiles.SuppliedDataID = &BlankID
	|				OR Profiles.SuppliedProfileChanged)
	|TOTALS BY
	|	Profile";
	
	ProfilesTree = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.AccessGroupProfiles");
	
	For Each ProfileRow In ProfilesTree.Rows Do
		LockItem.SetValue("Ref", ProfileRow.Profile);
		BeginTransaction();
		Try
			Block.Lock();
			ProfileObject = ProfileRow.Profile.GetObject();
			ProfileRoles = ProfileObject.Roles;
		
			For Each RoleRow In ProfileRow.Rows Do
				
				// 
				Filter = New Structure("Role", RoleRow.Role);
				FoundRows = ProfileRoles.FindRows(Filter);
				For Each FoundRow In FoundRows Do
					ProfileRoles.Delete(FoundRow);
				EndDo;
				
				// 
				RolesToAdd = RolesRefsToReplace.Get(RoleRow.Role);
				
				For Each RoleToAdd In RolesToAdd Do
					Filter = New Structure;
					Filter.Insert("Role", RoleToAdd);
					If ProfileRoles.FindRows(Filter).Count() = 0 Then
						NewRow = ProfileRoles.Add();
						NewRow.Role = RoleToAdd;
					EndIf;
				EndDo;
			EndDo;
			
			InfobaseUpdate.WriteData(ProfileObject);
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
	Catalogs.AccessGroupProfiles.UpdateAuxiliaryProfilesData(
		ProfilesTree.Rows.UnloadColumn("Profile"));
	
EndProcedure

// Returns a link to the supplied profile or profile folder by ID.
//
// Parameters:
//  Id - String -  the name or unique identifier of the supplied profile or profile folder,
//                  as specified in the procedure for filling in the supplied profiles of the Access group of the
//                  general Access Management module is undetectable.
//
// Returns:
//  CatalogRef.AccessGroupProfiles - 
//  
//
Function SuppliedProfileByID(Id) Export
	
	Return Catalogs.AccessGroupProfiles.SuppliedProfileByID(Id);
	
EndFunction

// Returns a link to the standard supplied Administrator profile.
//
// Returns:
//  CatalogRef.AccessGroupProfiles
//
Function ProfileAdministrator() Export
	
	Return AccessManagementInternalCached.ProfileAdministrator();
	
EndFunction

// Returns a reference to the standard supplied Administrators access group.
//
// Returns:
//  CatalogRef.AccessGroups
//
Function AdministratorsAccessGroup() Export
	
	Return AccessManagementInternalCached.AdministratorsAccessGroup();
	
EndFunction

// Returns an empty table to fill in and
// pass to the replace rightconfigure Rightobjects procedure.
//
// Returns:
//  ValueTable:
//    * OwnersType - DefinedType.RightsSettingsOwner -  an empty link of the rights owner type,
//                      such as an empty link in the Folder directory.
//    * OldName     - String -  old name of the right.
//    * NewName      - String -  new name of the right.
//
Function TableOfRightsReplacementInObjectsRightsSettings() Export
	
	Dimensions = Metadata.InformationRegisters.ObjectsRightsSettings.Dimensions;
	
	Table = New ValueTable;
	Table.Columns.Add("OwnersType", Dimensions.Object.Type);
	Table.Columns.Add("OldName",     Dimensions.Right.Type);
	Table.Columns.Add("NewName",      Dimensions.Right.Type);
	
	Return Table;
	
EndFunction

// Replaces the rights used in the object rights settings.
// After the replacement is completed, the auxiliary data
// of the object Configuration information register will be updated, so you should call
// the procedure once to avoid performance degradation.
// 
// Parameters:
//  RenamedTable - ValueTable:
//    * OwnersType - DefinedType.RightsSettingsOwner -  an empty link of the rights owner type,
//                      such as an empty link in the Folder directory.
//    * OldName     - String -  the old name of the right that belongs to the specified owner type.
//    * NewName      - String -  new name of the right that belongs to the specified owner type.
//                      If an empty string is specified, the old permission setting will be deleted.
//                      If two new names are assigned to the old name,
//                      then one old setting will be multiplied into two new ones.
//  
Procedure ReplaceRightsInObjectsRightsSettings(RenamedTable) Export
	
	// 
	// 
	Query = New Query;
	Query.Parameters.Insert("RenamedTable", RenamedTable);
	Query.Text =
	"SELECT
	|	RenamedTable.OwnersType,
	|	RenamedTable.OldName,
	|	RenamedTable.NewName
	|INTO RenamedTable
	|FROM
	|	&RenamedTable AS RenamedTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RightsSettings.Object,
	|	RightsSettings.User,
	|	RightsSettings.Right,
	|	MAX(RightsSettings.RightIsProhibited) AS RightIsProhibited,
	|	MAX(RightsSettings.InheritanceIsAllowed) AS InheritanceIsAllowed,
	|	MAX(RightsSettings.SettingsOrder) AS SettingsOrder
	|INTO OldRightsSettings
	|FROM
	|	InformationRegister.ObjectsRightsSettings AS RightsSettings
	|
	|GROUP BY
	|	RightsSettings.Object,
	|	RightsSettings.User,
	|	RightsSettings.Right
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OldRightsSettings.Object,
	|	OldRightsSettings.User,
	|	RenamedTable.OldName,
	|	RenamedTable.NewName,
	|	OldRightsSettings.RightIsProhibited,
	|	OldRightsSettings.InheritanceIsAllowed,
	|	OldRightsSettings.SettingsOrder
	|INTO RightsSettings
	|FROM
	|	OldRightsSettings AS OldRightsSettings
	|		INNER JOIN RenamedTable AS RenamedTable
	|		ON (VALUETYPE(OldRightsSettings.Object) = VALUETYPE(RenamedTable.OwnersType))
	|			AND OldRightsSettings.Right = RenamedTable.OldName
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RightsSettings.NewName
	|FROM
	|	RightsSettings AS RightsSettings
	|
	|GROUP BY
	|	RightsSettings.Object,
	|	RightsSettings.User,
	|	RightsSettings.NewName
	|
	|HAVING
	|	RightsSettings.NewName <> """" AND
	|	COUNT(RightsSettings.NewName) > 1
	|
	|UNION
	|
	|SELECT
	|	RightsSettings.NewName
	|FROM
	|	RightsSettings AS RightsSettings
	|		LEFT JOIN OldRightsSettings AS OldRightsSettings
	|		ON RightsSettings.Object = OldRightsSettings.Object
	|			AND RightsSettings.User = OldRightsSettings.User
	|			AND RightsSettings.NewName = OldRightsSettings.Right
	|WHERE
	|	NOT OldRightsSettings.Right IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RightsSettings.Object,
	|	RightsSettings.User,
	|	RightsSettings.OldName,
	|	RightsSettings.NewName,
	|	RightsSettings.RightIsProhibited,
	|	RightsSettings.InheritanceIsAllowed,
	|	RightsSettings.SettingsOrder
	|FROM
	|	RightsSettings AS RightsSettings";
	// 
	
	Block = New DataLock;
	Block.Add("InformationRegister.ObjectsRightsSettings");
	
	BeginTransaction();
	Try
		Block.Lock();
		QueryResults = Query.ExecuteBatch();
		
		RepeatedNewNames = QueryResults[QueryResults.Count()-2].Unload();
		
		If RepeatedNewNames.Count() > 0 Then
			RepeatedNewRightsNames = "";
			For Each String In RepeatedNewNames Do
				RepeatedNewRightsNames = RepeatedNewRightsNames
					+ ?(ValueIsFilled(RepeatedNewRightsNames), "," + Chars.LF, "")
					+ String.NewName;
			EndDo;
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Error in procedure ""%1""
				           |of common module ""%2""..
				           |
				           |After the update, the following new access right names will have identical settings:
				           |%1.';"),
				"ReplaceRightsInObjectsRightsSettings",
				"AccessManagement",
				RepeatedNewRightsNames);
			Raise ErrorText;
		EndIf;
		
		ReplacementTable1 = QueryResults[QueryResults.Count()-1].Unload();
		
		RecordSet = InformationRegisters.ObjectsRightsSettings.CreateRecordSet();
		
		IBUpdate = InfobaseUpdate.InfobaseUpdateInProgress()
		           Or InfobaseUpdate.IsCallFromUpdateHandler();
		
		For Each String In ReplacementTable1 Do
			RecordSet.Filter.Object.Set(String.Object);
			RecordSet.Filter.User.Set(String.User);
			RecordSet.Filter.Right.Set(String.OldName);
			RecordSet.Read();
			If RecordSet.Count() > 0 Then
				RecordSet.Clear();
				If IBUpdate Then
					InfobaseUpdate.WriteData(RecordSet);
				Else
					RecordSet.Write();
				EndIf;
			EndIf;
		EndDo;
		
		NewRecord = RecordSet.Add();
		For Each String In ReplacementTable1 Do
			If String.NewName = "" Then
				Continue;
			EndIf;
			RecordSet.Filter.Object.Set(String.Object);
			RecordSet.Filter.User.Set(String.User);
			RecordSet.Filter.Right.Set(String.NewName);
			FillPropertyValues(NewRecord, String);
			NewRecord.Right = String.NewName;
			If IBUpdate Then
				InfobaseUpdate.WriteData(RecordSet);
			Else
				RecordSet.Write();
			EndIf;
		EndDo;
		
		InformationRegisters.ObjectsRightsSettings.UpdateAuxiliaryRegisterData();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Updates the list of database user roles by their current
// access group membership. IB users with the "full Rights" role are skipped.
// 
// Parameters:
//  UsersArray - Array
//                      - Undefined
//                      - Type - 
//     
//     
//     
//     
//
//  ServiceUserPassword - String -  password for authorization in the service Manager.
//
Procedure UpdateUserRoles(Val UsersArray = Undefined, Val ServiceUserPassword = Undefined) Export
	
	AccessManagementInternal.UpdateUserRoles(UsersArray, ServiceUserPassword);
	
EndProcedure

// Updates the contents of the access group And silence access Group values registers,
// which are filled in based on the settings in access groups and the use of access types.
//
Procedure UpdateAllowedValuesOnChangeAccessKindsUsage() Export
	
	InformationRegisters.UsedAccessKinds.UpdateRegisterData();
	
EndProcedure

// Performs sequential filling in and partial updating of data required for the
// Access management subsystem to operate in record-level access restriction mode.
// 
// When the record-level access restriction mode is enabled, it fills in sets
// of access values. Filling is performed in parts at each start, until all
// sets of access values are filled in.
//
// If you disable the record-level access restriction mode, the sets of access values
// (previously filled in) are deleted when objects are overwritten, not all at once.
//
// Regardless of the record-level access restriction mode, updates secondary data -
// groups of access values and additional fields in existing sets of access values.
// After all updates and fillings are completed, disables the use of the scheduled task.
//
// Information about the operation status is recorded in the log.
// It can be called programmatically, for example, when updating an information database.
//
// Parameters:
//  DataVolume - Number -  the return value. The number of data objects 
//                             for which the filling was performed.
//
Procedure DataFillingForAccessRestriction(DataVolume = 0) Export
	
	AccessManagementInternal.DataFillingForAccessRestriction(DataVolume);
	
EndProcedure

// To speed up batch processing of data in the current session (a full user)
// disables and enables the calculation of rights when writing an object or set of records
// (updating access keys to objects and register entries, as well as the rights
//  of access groups, users, and external users to new access keys).
//
// Recommended:
// - when restoring from an XML backup;
// - bulk loading of data from a file;
// - bulk data loading during data exchange;
// - group changes to objects.
//
// Parameters:
//  Disconnect - Boolean -  True-disables updating access keys and enables the mode
//                         for collecting the composition of tables (lists) that will be scheduled
//                         for updating access keys when the access key update continues.
//                       False-plans to update access keys for tables collected in
//                         disable mode, and enables the standard access key update mode.
//
//  ScheduleUpdate1 - Boolean -  schedule updates when they are disabled and continue.
//                            When Disable = True, then determines whether to collect
//                              the list of tables that will be updated.
//                              False - required only when loading from an XML backup, when
//                              all data in the information database is loaded, including all service data.
//                            When Disable = False, then determines whether to schedule
//                              updates for the collected tables.
//                              False is required in handling an exception after a transaction is canceled
//                              if there is an external transaction, since any entry
//                              to the database in this state will result in an error.in addition,
//                              you do not need to schedule an update after the transaction is canceled.
// Example:
//
//  
//
//	
//	
//		
//		
//		
//	
//		
//		
//		
//	
//
//  
//
//	
//	
//	
//		
//		
//		
//		
//		
//		
//	
//		
//		
//		
//		
//	
//
Procedure DisableAccessKeysUpdate(Disconnect, ScheduleUpdate1 = True) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	If Disconnect And Not Users.IsFullUser() Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid call of procedure ""%1"" of common module ""%2"".
			           |Only full-access users or
			           |users that run the application in privileged mode can disable update of access keys.';"),
			"DisableAccessKeysUpdate",
			"AccessManagement");
		Raise ErrorText;
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	DisableUpdate = SessionParameters.DIsableAccessKeysUpdate; // See AccessManagementInternal.NewDisableOfAccessKeysUpdate
	Regularly = Disconnect And    ScheduleUpdate1;
	Full      = Disconnect And Not ScheduleUpdate1;
	
	If DisableUpdate.Regularly = Regularly
	   And DisableUpdate.Full      = Full Then
		Return;
	EndIf;
	
	DisableUpdate = New Structure(DisableUpdate);
	
	If Not Disconnect And ScheduleUpdate1 Then
		EditedLists = DisableUpdate.EditedLists.Get();
		If EditedLists.Count() > 0 Then
			If AccessManagementInternal.LimitAccessAtRecordLevelUniversally() Then
				Lists = New Array;
				AddedLists = New Map;
				For Each KeyAndValue In EditedLists Do
					FullName = Metadata.FindByType(KeyAndValue.Key).FullName();
					Lists.Add(FullName);
					AddedLists.Insert(FullName, True);
				EndDo;
				UnavailableLists = New Array;
				AccessManagementInternal.AddDependentLists(Lists, AddedLists, UnavailableLists);
				PlanningParameters = AccessManagementInternal.AccessUpdatePlanningParameters();
				PlanningParameters.AllowedAccessKeys = False;
				PlanningParameters.LongDesc = "DisableAccessKeysUpdateOnFinishDisabling";
				AccessManagementInternal.ScheduleAccessUpdate(Lists, PlanningParameters);
				If UnavailableLists.Count() > 0 Then
					AccessManagementInternal.ScheduleAccessUpdate(UnavailableLists, PlanningParameters);
				EndIf;
			EndIf;
			DisableUpdate.EditedLists = New ValueStorage(New Map);
			AccessManagementInternalCached.ChangedListsCacheOnDisabledAccessKeysUpdate().Clear();
		EndIf;
	EndIf;
	
	If Not Regularly And Not Full Then
		If DisableUpdate.NestedDisconnections.Count() > 0 Then
			NestedDisconnections = New Array(DisableUpdate.NestedDisconnections);
			Regularly = NestedDisconnections[0].Regularly;
			Full      = NestedDisconnections[0].Full;
			NestedDisconnections.Delete(0);
			DisableUpdate.NestedDisconnections = New FixedArray(NestedDisconnections);
		EndIf;
	ElsIf DisableUpdate.Regularly Or DisableUpdate.Full Then
		If DisableUpdate.Full Then
			Regularly = False;
			Full = True;
		EndIf;
		NestedDisconnection = New Structure;
		NestedDisconnection.Insert("Regularly", DisableUpdate.Regularly);
		NestedDisconnection.Insert("Full",      DisableUpdate.Full);
		NestedDisconnections = New Array(DisableUpdate.NestedDisconnections);
		NestedDisconnections.Add(New FixedStructure(NestedDisconnection));
		DisableUpdate.NestedDisconnections = New FixedArray(NestedDisconnections);
	EndIf;
	
	DisableUpdate.Regularly = Regularly;
	DisableUpdate.Full      = Full;
	
	SessionParameters.DIsableAccessKeysUpdate = New FixedStructure(DisableUpdate);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// 
// 
// 
//
// 
// 
// 
//
// Parameters:
//  Version      - String - 
//                  
//  Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//  IsInitialPopulationOnly - Boolean - 
//                  
//                  
//  ExclusiveOfDIB - Boolean - 
//                  
//                  
//                  
//                  
//
// Example:
//	Procedure For Adding Update Handlers(Handlers) Export
//		Access control.Add An Update Handler To Enable Universal Restrictions ("3.0.3.7", Handlers);
//	End of procedure
//
Procedure AddUpdateHandlerToEnableUniversalRestriction(Version, Handlers,
			IsInitialPopulationOnly = False, ExclusiveOfDIB = False) Export
	
	If Common.IsSubordinateDIBNode()
	 Or Common.SeparatedDataUsageAvailable()
	   And AccessManagementInternal.LimitAccessAtRecordLevelUniversally(True) Then
		Return;
	EndIf;
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "InformationRegisters.AccessRestrictionParameters.EnableUniversalRecordLevelAccessRestriction";
	Handler.ExecutionMode = "Seamless";
	
	If IsInitialPopulationOnly
	 Or Common.FileInfobase() Then
		Return;
	EndIf;
	
	DIBEnabled = False;
	If Not ExclusiveOfDIB
	   And Not Common.DataSeparationEnabled()
	   And Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		ExchangePlansNames = New Array;
		For Each ExchangePlan In Metadata.ExchangePlans Do
			If ExchangePlan.DistributedInfoBase Then
				ExchangePlansNames.Add(ExchangePlan.Name);
			EndIf;
		EndDo;
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		Table = ModuleDataExchangeServer.DataExchangeMonitorTable(ExchangePlansNames);
		Boundary = CurrentSessionDate() - ('00010701' - '00010101');
		For Each String In Table Do
			If Not ValueIsFilled(String.LastRunDate)
			 Or String.LastRunDate > Boundary Then
				DIBEnabled = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If DIBEnabled Then
		Return;
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = Version;
	Handler.Procedure = "InformationRegisters.AccessRestrictionParameters.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	Handler.Comment = NStr("en = 'Enables universal record-level access restriction.';");
	Handler.Id = New UUID("74cb1992-c9ac-4b46-90db-810544dee86c");
	Handler.UpdateDataFillingProcedure = "InformationRegisters.AccessRestrictionParameters.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead = "InformationRegister.AccessRestrictionParameters";
	Handler.ObjectsToChange = "InformationRegister.AccessRestrictionParameters";
	
EndProcedure

#Region ForCallsFromOtherSubsystems

// 

// Purpose: for the universal document log on the register (ERP).
// Used to hide a duplicate entry in the log for moving documents,
// in cases where it is known that there will be two entries at once.
//
// Checks whether the table is restricted by the specified access type.
//
// If all of the access table, at least one of the access group, providing the right to
// the specified table does not have a limit (all values allowed for all types of access),
// then there is no restriction on the specified type of access, otherwise, no restrictions
// specified type of access, unless it is not in all the access groups for the specified table.
// 
// Parameters:
//  Table        - String -  the full name of the metadata object, for example, " Document.Expense account".
//  AccessKind     - String -  name of the access type, for example, "Companies".
//  AllAccessKinds - String -  names of all access types that are used in the table constraint,
//                            for example, "Companies, partner Groups, Warehouses".
//
// Returns:
//  Boolean - 
// 
Function HasTableRestrictionByAccessKind(Table, AccessKind, AllAccessKinds) Export
	
	Return AccessManagementInternal.HasTableRestrictionByAccessKind(Table,
		AccessKind, AllAccessKinds);
	
EndFunction

// 

// 

// Purpose: to call from the constructor of a DSS restrictions.
// 
// Parameters:
//  MainTable  - String -  full name of the main table of the metadata object, for example, " Document.Customer's order".
//  RestrictionText - String -  the restriction text that is specified in
//    the metadata object Manager module to restrict users or restrict external users.
//
// Returns:
//  Structure:
//   * InternalData - Structure -  data to pass to the structure Constraint function.
//   * TablesFields       - Map of KeyAndValue:
//     ** Key     - String -  name of the collection of metadata objects, such as Directories.
//     ** Value - Map of KeyAndValue:
//       *** Key     - String -  the name of the table (object metadata) to upper case.
//       *** Value - Structure:
//         **** TableExists - Boolean -  False (to fill in True, if it exists).
//         **** Fields - Map of KeyAndValue:
//           ***** Key - String -  the name of the property in uppercase, including dots,
//                                 for example, " OWNER.ORGANIZATION", " PRODUCTS.NOMENCLATURE".
//           ***** Value - Structure:
//             ****** FieldWithError - Number -  0 (to fill in if the field contains an error,
//                       if 1, then an error in the name of the first part of the field,
//                       if 2, then an error in the name of the second part of the field, i.e. after the first dot).
//             ****** ErrorKind - String -  "Not Found", "Tabular Part Of The Field",
//                       "Tabular Part Of The Message".
//             ****** Collection - String -  empty string (to be filled in if the first part
//                       of the field exists, i.e. the part of the field up to the first point). Options: "Details",
//                      "Tablecreate", "Standartizaciisa", "Standartneftegaz",
//                      "Measurements", "Resources", "Graphs", "Priznayutsya, Prizmaticheskoj",
//                      "Requisitionists", "SPETSIALNAYA". Special fields are
//                      "Value" - tables have " Constant.* ",
//                      "Logger" and "Period" - for tables " Sequence.* ",
//                      "Object of calculation", "type of Calculation" in the tables " register of Calculation.<Name>.<Recalculation name>".
//                      Fields after the first dot can only apply to collections: "Banking Details",
//                      "Standard Requirements", "Accounting Attributes", "Forwarding Details". 
//                      You don't need to Refine the collection for these parts of the field name.
//             ****** ContainsTypes - Map of KeyAndValue:
//               ******* Key - String -  full name of the reference table in uppercase.
//               ******* Value - Structure:
//                 ******** TypeName     - String -  the name of the type whose presence we need to check.
//                 ******** ContainsType - Boolean -  False (to fill in True
//                                                         if the field of the last field has a type).
//         **** Predefined - Map of KeyAndValue:
//           ***** Key - String -  name of the predefined element.
//           ***** Value - Structure:
//             ****** NameExists - Boolean -  False (for filling in True, if there is a predefined one).
//
//         **** Extensions - Map of KeyAndValue:
//           ***** Key - String -  name of the third table name, for example, the name of the table part.
//           ***** Value - Structure:
//             ****** TableExists - Boolean -  False (to fill in True, if it exists).
//             ****** Fields - Map - 
//
Function ParsedRestriction(MainTable, RestrictionText) Export
	
	Return AccessManagementInternal.ParsedRestriction(MainTable, RestrictionText);
	
EndFunction

// Purpose: to call from the constructor of a DSS restrictions.
// Before passing the parsed Constraint parameter in the table Field property
// , the nested table properties exist, field Error, Containtype, and name Exist must be filled in.
// 
// Parameters:
//  ParsedRestriction - See ParsedRestriction
//
// Returns:
//  Structure:
//   * ErrorsDescription - Structure:
//      ** HasErrors  - Boolean -  if True, then one or more errors were found.
//      ** ErrorsText - String -  text of all errors.
//      ** Restriction - String -  numbered constraint text with"<<? >> " inserts.
//      ** Errors      - Array of Structure - :
//         *** LineNumber    - Number -    the string in the multiline text where the error was found.
//         *** PositionInRow - Number -    the number of the character from which the error was detected
//                                       may be outside the string (string length + 1).
//         *** ErrorText    - String -  the text of the error without a description of the position.
//         *** ErrorString   - String -  the string where the error was found with the insertion "<<?>>".
//      ** AddOn - String -  description of variants of the first keywords of the restriction parts.
//
//   * AdditionalTables - Array of Structure:
//      ** Table           - String -  full name of the metadata object.
//      ** Alias         - String -  name of the table alias.
//      ** ConnectionCondition - Structure -  like the constraint property, But only
//                                     nodes: "Field", "Value", "Constant", "And","=".
//   * MainTableAlias - String -  filled in if additional tables are specified.
//   * ReadRestriction    - Structure -  like the constraint property.
//   * UpdateRestriction - Structure:
//
//      ** Node - String - 
//           
//           
//           
//           
//           
//
//     
//       ** Name       - String - 
//       ** Table   - String -  the table name of this field (or an empty string for the main table).
//       ** Alias - String -  the name of the alias of the attached table in this field (or an empty string for the main table),
//                        for example, "add-in register" for the "main Company"field.
//       ** Cast  - String - :
//                       
//       ** Attachment  - Structure -  node Field containing the nested EXPRESS action (with or without IsNull).
//                    - Undefined - 
//       ** IsNull  - Structure -  a value or Constant node, for example, to describe an expression
//                        like " IsNull(Owner, Value (Reference.Files.Empty link))".
//                    - Undefined - 
//
//     
//       ** Name - String - 
//                                                 
//
//     
//       ** Value - Boolean
//                   - Number  - 
//                   - String - 
//                   - Undefined
//
//     
//       ** Arguments - Array - :
//            *** Value - Structure - 
//
//     
//       ** Argument - Structure - 
//
//     
//       ** FirstArgument - Structure -  node Field.
//       ** SecondArgument - Structure - 
//
//     
//       ** SearchFor  - Structure -  node Field.
//       ** Values - Array - :
//            *** Value - Structure - 
//
//     
//       ** Argument - Structure - 
//
//     
//       ** Name - String - 
//
//     
//       ** Argument - Structure - 
//
//     
//       ** Case - Structure -  node Field.
//                - Undefined - 
//       ** When - Array - :
//            *** Value - Structure:
//                  **** Condition  - Structure -  node Value if the Select property is specified, otherwise
//                                              nodes And, Or, Not,=,<>, In (applies to nested content).
//                  **** Value - Structure -  node other than Select.
//       ** Else - Structure - 
//
//     
//                    
//                    
//       ** Field - Structure -  node Field.
//       ** Types - Array - :
//            *** Value - String -  full name of the table
//       ** CheckTypesExceptListed - Boolean -  if True, all types of the Field property
//                                                 except those specified in the Types property.
//       ** ComparisonClarifications - Map of KeyAndValue:
//            *** Key     - String -  the specified value is "Undefined", "Null", "empty link",
//                                    <full table name>, "Number", "String", "date", "Boolean".
//            *** Value - String - 
//
//     
//       ** Argument - Structure -  any node.
//
Function RestrictionStructure(ParsedRestriction) Export
	
	Return AccessManagementInternal.RestrictionStructure(ParsedRestriction);
	
EndFunction

// 

#EndRegion

#EndRegion

#Region Private

// 

// Converts a table of value sets to the format of a table part or record set.
//  Executed before writing to the access value Set register or
// before writing an object with the table part of the access value Set.
//
// Parameters:
//  ObjectReference - AnyRef -  a reference to an object from the definable Type.Owner
//                                 of access value sets an object for which access value sets are populated.
//
//  Table - See AccessValuesSetsTable
//
Procedure SpecifyAccessValuesSets(ObjectReference, Table)
	
	AccessKindsNames = AccessManagementInternal.AccessKindsProperties().ByNames;
	
	AvailableRights = AccessManagementInternal.RightsForObjectsRightsSettingsAvailable();
	RightsSettingsOwnersTypes = AvailableRights.ByRefsTypes;
	
	For Each String In Table Do
		
		If RightsSettingsOwnersTypes.Get(TypeOf(String.AccessValue)) <> Undefined
		   And Not ValueIsFilled(String.Refinement) Then
			
			String.Refinement = Common.MetadataObjectID(TypeOf(ObjectReference));
		EndIf;
		
		If String.AccessKind = "" Then
			Continue;
		EndIf;
		
		If String.AccessKind = "ReadRight1"
		 Or String.AccessKind = "EditRight" Then
			
			If TypeOf(String.AccessValue) <> Type("CatalogRef.MetadataObjectIDs") Then
				String.AccessValue =
					Common.MetadataObjectID(TypeOf(String.AccessValue));
			EndIf;
			
			If String.AccessKind = "ReadRight1" Then
				String.Refinement = Catalogs.MetadataObjectIDs.EmptyRef();
			Else
				String.Refinement = String.AccessValue;
			EndIf;
		
		ElsIf AccessKindsNames.Get(String.AccessKind) <> Undefined
		      Or String.AccessKind = "RightsSettings" Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Object ""%1"" generated an access value set
				           |containing a known access kind ""%2."" It cannot contain this access kind.
				           |
				           |It can only contain special access kinds
				           |""%3"" and ""%4"".';"),
				TypeOf(ObjectReference),
				String.AccessKind,
				"ReadRight1",
				"EditRight");
			Raise ErrorText;
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Object ""%1"" generated an access value set
				           |containing an unknown access kind ""%2.""';"),
				TypeOf(ObjectReference),
				String.AccessKind);
			Raise ErrorText;
		EndIf;
		
		String.AccessKind = "";
	EndDo;
	
EndProcedure

// 

Function TablesSets(Table, RightsNormalization = False)
	
	TablesSets = New Map;
	
	For Each String In Table Do
		Set = TablesSets.Get(String.SetNumber);
		If Set = Undefined Then
			Set = New Structure;
			Set.Insert("Read", False);
			Set.Insert("Update", False);
			Set.Insert("Rows", New Array);
			TablesSets.Insert(String.SetNumber, Set);
		EndIf;
		If String.Read Then
			Set.Read = True;
		EndIf;
		If String.Update Then
			Set.Update = True;
		EndIf;
		Set.Rows.Add(String);
	EndDo;
	
	If RightsNormalization Then
		For Each SetDetails In TablesSets Do
			Set = SetDetails.Value;
			
			If Not Set.Read And Not Set.Update Then
				Set.Read    = True;
				Set.Update = True;
			EndIf;
		EndDo;
	EndIf;
	
	Return TablesSets;
	
EndFunction

Procedure AddSets(Receiver, Source)
	
	DestinationSets = TablesSets(Receiver);
	SourceSets = TablesSets(Source);
	
	MaxSetNumber = -1;
	
	For Each DestinationSetDetails In DestinationSets Do
		DestinationSet1 = DestinationSetDetails.Value;
		
		If Not DestinationSet1.Read And Not DestinationSet1.Update Then
			DestinationSet1.Read    = True;
			DestinationSet1.Update = True;
		EndIf;
		
		For Each String In DestinationSet1.Rows Do
			String.Read    = DestinationSet1.Read;
			String.Update = DestinationSet1.Update;
		EndDo;
		
		If DestinationSetDetails.Key > MaxSetNumber Then
			MaxSetNumber = DestinationSetDetails.Key;
		EndIf;
	EndDo;
	
	NewSetNumber = MaxSetNumber + 1;
	
	For Each SourceSetDetails In SourceSets Do
		SourceSet = SourceSetDetails.Value;
		
		If Not SourceSet.Read And Not SourceSet.Update Then
			SourceSet.Read    = True;
			SourceSet.Update = True;
		EndIf;
		
		For Each SourceRow1 In SourceSet.Rows Do
			NewRow = Receiver.Add();
			FillPropertyValues(NewRow, SourceRow1);
			NewRow.SetNumber = NewSetNumber;
			NewRow.Read      = SourceSet.Read;
			NewRow.Update   = SourceSet.Update;
		EndDo;
		
		NewSetNumber = NewSetNumber + 1;
	EndDo;
	
EndProcedure

Procedure MultiplySets(Receiver, Source)
	
	DestinationSets = TablesSets(Receiver);
	SourceSets = TablesSets(Source, True);
	Table = AccessValuesSetsTable();
	
	CurrentSetNumber = 1;
	For Each DestinationSetDetails In DestinationSets Do
			DestinationSet1 = DestinationSetDetails.Value;
		
		If Not DestinationSet1.Read And Not DestinationSet1.Update Then
			DestinationSet1.Read    = True;
			DestinationSet1.Update = True;
		EndIf;
		
		For Each SourceSetDetails In SourceSets Do
			SourceSet = SourceSetDetails.Value;
			
			ReadMultiplication    = DestinationSet1.Read    And SourceSet.Read;
			ChangeMultiplication = DestinationSet1.Update And SourceSet.Update;
			If Not ReadMultiplication And Not ChangeMultiplication Then
				Continue;
			EndIf;
			For Each DestinationRow1 In DestinationSet1.Rows Do
				String = Table.Add();
				FillPropertyValues(String, DestinationRow1);
				String.SetNumber = CurrentSetNumber;
				String.Read      = ReadMultiplication;
				String.Update   = ChangeMultiplication;
			EndDo;
			For Each SourceRow1 In SourceSet.Rows Do
				String = Table.Add();
				FillPropertyValues(String, SourceRow1);
				String.SetNumber = CurrentSetNumber;
				String.Read      = ReadMultiplication;
				String.Update   = ChangeMultiplication;
			EndDo;
			CurrentSetNumber = CurrentSetNumber + 1;
		EndDo;
	EndDo;
	
	Receiver = Table;
	
EndProcedure

Procedure AddSetsAndSimplify(Receiver, Source)
	
	DestinationSets = TablesSets(Receiver);
	SourceSets = TablesSets(Source);
	
	ResultSets   = New Map;
	TypesCodes          = New Map;
	EnumerationsCodes   = New Map;
	SetRowsTable = New ValueTable;
	
	FillTypesCodesAndSetStringsTable(TypesCodes, EnumerationsCodes, SetRowsTable);
	
	CurrentSetNumber = 1;
	
	AddSimplifiedSetsToResult(
		ResultSets, DestinationSets, CurrentSetNumber, TypesCodes, EnumerationsCodes, SetRowsTable);
	
	AddSimplifiedSetsToResult(
		ResultSets, SourceSets, CurrentSetNumber, TypesCodes, EnumerationsCodes, SetRowsTable);
	
	FillDestinationByResultSets(Receiver, ResultSets);
	
EndProcedure

Procedure MultiplySetsAndSimplify(Receiver, Source)
	
	DestinationSets = TablesSets(Receiver);
	SourceSets = TablesSets(Source, True);
	
	ResultSets   = New Map;
	TypesCodes          = New Map;
	EnumerationsCodes   = New Map;
	SetRowsTable = New ValueTable;
	
	FillTypesCodesAndSetStringsTable(TypesCodes, EnumerationsCodes, SetRowsTable);
	
	CurrentSetNumber = 1;
	
	For Each DestinationSetDetails In DestinationSets Do
		DestinationSet1 = DestinationSetDetails.Value;
		
		If Not DestinationSet1.Read And Not DestinationSet1.Update Then
			DestinationSet1.Read    = True;
			DestinationSet1.Update = True;
		EndIf;
		
		For Each SourceSetDetails In SourceSets Do
			SourceSet = SourceSetDetails.Value;
			
			ReadMultiplication    = DestinationSet1.Read    And SourceSet.Read;
			ChangeMultiplication = DestinationSet1.Update And SourceSet.Update;
			If Not ReadMultiplication And Not ChangeMultiplication Then
				Continue;
			EndIf;
			
			SetStrings = SetRowsTable.Copy();
			
			For Each DestinationRow1 In DestinationSet1.Rows Do
				String = SetStrings.Add();
				String.AccessKind      = DestinationRow1.AccessKind;
				String.AccessValue = DestinationRow1.AccessValue;
				String.Refinement       = DestinationRow1.Refinement;
				FillRowID(String, TypesCodes, EnumerationsCodes);
			EndDo;
			For Each SourceRow1 In SourceSet.Rows Do
				String = SetStrings.Add();
				String.AccessKind      = SourceRow1.AccessKind;
				String.AccessValue = SourceRow1.AccessValue;
				String.Refinement       = SourceRow1.Refinement;
				FillRowID(String, TypesCodes, EnumerationsCodes);
			EndDo;
			
			SetStrings.GroupBy("RowID, AccessKind, AccessValue, Refinement");
			SetStrings.Sort("RowID");
			
			SetID = "";
			For Each String In SetStrings Do
				SetID = SetID + String.RowID + Chars.LF;
			EndDo;
			
			ExistingSet = ResultSets.Get(SetID);
			If ExistingSet = Undefined Then
				
				SetProperties = New Structure;
				SetProperties.Insert("Read",      ReadMultiplication);
				SetProperties.Insert("Update",   ChangeMultiplication);
				SetProperties.Insert("Rows",      SetStrings);
				SetProperties.Insert("SetNumber", CurrentSetNumber);
				ResultSets.Insert(SetID, SetProperties);
				CurrentSetNumber = CurrentSetNumber + 1;
			Else
				If ReadMultiplication Then
					ExistingSet.Read = True;
				EndIf;
				If ChangeMultiplication Then
					ExistingSet.Update = True;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	FillDestinationByResultSets(Receiver, ResultSets);
	
EndProcedure

Procedure FillTypesCodesAndSetStringsTable(TypesCodes, EnumerationsCodes, SetRowsTable)
	
	EnumerationsCodes = AccessManagementInternalCached.EnumerationsCodes();
	
	TypesCodes = AccessManagementInternalCached.RefsTypesCodes("DefinedType.AccessValue");
	
	TypeCodeLength = 0;
	For Each KeyAndValue In TypesCodes Do
		TypeCodeLength = StrLen(KeyAndValue.Value);
		Break;
	EndDo;
	
	RowIDLength =
		20 // 
		+ TypeCodeLength
		+ 36 // 
		+ 36 // 
		+ 6; // 
	
	SetRowsTable = New ValueTable;
	SetRowsTable.Columns.Add("RowID", New TypeDescription("String", , New StringQualifiers(RowIDLength)));
	SetRowsTable.Columns.Add("AccessKind",          New TypeDescription("String", , New StringQualifiers(20)));
	SetRowsTable.Columns.Add("AccessValue",     Metadata.DefinedTypes.AccessValue.Type);
	SetRowsTable.Columns.Add("Refinement",           New TypeDescription("CatalogRef.MetadataObjectIDs"));
	
EndProcedure

Procedure FillRowID(String, TypesCodes, EnumerationsCodes)
	
	If String.AccessValue = Undefined Then
		AccessValueID = "";
	Else
		AccessValueID = EnumerationsCodes.Get(String.AccessValue);
		If AccessValueID = Undefined Then
			AccessValueID = String(String.AccessValue.UUID());
		EndIf;
	EndIf;
	
	String.RowID = String.AccessKind + ";"
		+ TypesCodes.Get(TypeOf(String.AccessValue)) + ";"
		+ AccessValueID + ";"
		+ String.Refinement.UUID() + ";";
	
EndProcedure

Procedure AddSimplifiedSetsToResult(ResultSets, SetsToAdd, CurrentSetNumber, TypesCodes, EnumerationsCodes, SetRowsTable)
	
	For Each SetToAddDetails In SetsToAdd Do
		SetToAdd = SetToAddDetails.Value;
		
		If Not SetToAdd.Read And Not SetToAdd.Update Then
			SetToAdd.Read    = True;
			SetToAdd.Update = True;
		EndIf;
		
		SetStrings = SetRowsTable.Copy();
		
		For Each StringOfSetToAdd In SetToAdd.Rows Do
			String = SetStrings.Add();
			String.AccessKind      = StringOfSetToAdd.AccessKind;
			String.AccessValue = StringOfSetToAdd.AccessValue;
			String.Refinement       = StringOfSetToAdd.Refinement;
			FillRowID(String, TypesCodes, EnumerationsCodes);
		EndDo;
		
		SetStrings.GroupBy("RowID, AccessKind, AccessValue, Refinement");
		SetStrings.Sort("RowID");
		
		SetID = "";
		For Each String In SetStrings Do
			SetID = SetID + String.RowID + Chars.LF;
		EndDo;
		
		ExistingSet = ResultSets.Get(SetID);
		If ExistingSet = Undefined Then
			
			SetProperties = New Structure;
			SetProperties.Insert("Read",      SetToAdd.Read);
			SetProperties.Insert("Update",   SetToAdd.Update);
			SetProperties.Insert("Rows",      SetStrings);
			SetProperties.Insert("SetNumber", CurrentSetNumber);
			ResultSets.Insert(SetID, SetProperties);
			
			CurrentSetNumber = CurrentSetNumber + 1;
		Else
			If SetToAdd.Read Then
				ExistingSet.Read = True;
			EndIf;
			If SetToAdd.Update Then
				ExistingSet.Update = True;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillDestinationByResultSets(Receiver, ResultSets)
	
	Receiver = AccessValuesSetsTable();
	
	SetsList = New ValueList;
	For Each SetDetails In ResultSets Do
		SetsList.Add(SetDetails.Value, SetDetails.Key);
	EndDo;
	SetsList.SortByPresentation();
	
	CurrentSetNumber = 1;
	For Each ListItem In SetsList Do
		SetProperties = ListItem.Value;
		For Each String In SetProperties.Rows Do
			NewRow = Receiver.Add();
			NewRow.SetNumber     = CurrentSetNumber;
			NewRow.AccessKind      = String.AccessKind;
			NewRow.AccessValue = String.AccessValue;
			NewRow.Refinement       = String.Refinement;
			NewRow.Read          = SetProperties.Read;
			NewRow.Update       = SetProperties.Update;
		EndDo;
		CurrentSetNumber = CurrentSetNumber + 1;
	EndDo;
	
EndProcedure

// For procedures for adding a form of access Value, group of access value, and resolving access value Changes.
Function AccessValueGroupsProperties(AccessValueType, ErrorTitle)
	
	SetPrivilegedMode(True);
	
	GroupsProperties = New Structure;
	
	AccessKindsProperties = AccessManagementInternal.AccessKindsProperties();
	AccessKindProperties = AccessKindsProperties.AccessValuesWithGroups.ByTypes.Get(AccessValueType); // See AccessManagementInternal.AccessKindProperties
	
	If AccessKindProperties = Undefined Then
		ErrorText = ErrorTitle + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Access value groups are not used for
			           |access values of ""%1"" type.';"),
			String(AccessValueType));
		Raise ErrorText;
	EndIf;
	
	GroupsProperties.Insert("AccessKind", AccessKindProperties.Name);
	GroupsProperties.Insert("Type",        AccessKindProperties.ValuesGroupsType);
	
	GroupsProperties.Insert("Table",    Metadata.FindByType(
		AccessKindProperties.ValuesGroupsType).FullName());
	
	GroupsProperties.Insert("ValueTypeBlankRef",
		AccessManagementInternal.MetadataObjectEmptyRef(AccessValueType));
	
	Return GroupsProperties;
	
EndFunction

// For the function set up a dynamic disk Selection.
Procedure UpdateDataCompositionParameterValue(Val ParametersOwner,
                                                    Val ParameterName,
                                                    Val ParameterValue)
	
	For Each Parameter In ParametersOwner.Parameters.Items Do
		If String(Parameter.Parameter) = ParameterName Then
			
			If Parameter.Use
			   And Parameter.Value = ParameterValue Then
				Return;
			EndIf;
			Break;
			
		EndIf;
	EndDo;
	
	ParametersOwner.Parameters.SetParameterValue(ParameterName, ParameterValue);
	
EndProcedure

// For the procedures enable user Profile and disable user Profile.
Procedure EnableDisableUserProfile(User, Profile, Enable, Source = Undefined) Export
	
	If Not AccessManagementInternal.SimplifiedAccessRightsSetupInterface() Then
		ErrorText =
			NStr("en = 'This operation is available only in the simplified
			           |access rights interface.';");
		Raise ErrorText;
	EndIf;
	
	If Enable Then
		NameOfAProcedureOrAFunction = "EnableProfileForUser";
	Else
		NameOfAProcedureOrAFunction = "DisableUserProfile";
	EndIf;
	
	// 
	If TypeOf(User) <> Type("CatalogRef.Users")
	   And TypeOf(User) <> Type("CatalogRef.ExternalUsers") Then
		
		ParameterName = "User";
		ParameterValue = User;
		Types = New Array;
		Types.Add(Type("CatalogRef.Users"));
		Types.Add(Type("CatalogRef.ExternalUsers"));
		ExpectedTypes = New TypeDescription(Types);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter in %2. 
			           |Expected value: %3, actual value: %4 (%5 type).';"),
			ParameterName,
			NameOfAProcedureOrAFunction,
			ExpectedTypes, 
			?(ParameterValue <> Undefined, ParameterValue, NStr("en = 'Undefined';")),
			TypeOf(ParameterValue));
		Raise ErrorText;
	EndIf;
	
	// 
	If TypeOf(Profile) <> Type("CatalogRef.AccessGroupProfiles")
	   And TypeOf(Profile) <> Type("String")
	   And TypeOf(Profile) <> Type("UUID")
	   And Not (Not Enable And TypeOf(Profile) = Type("Undefined")) Then
		
		ParameterName = "Profile";
		ParameterValue = Profile;
		Types = New Array;
		Types.Add(Type("CatalogRef.AccessGroupProfiles"));
		Types.Add(Type("String"));
		Types.Add(Type("UUID"));
		If Not Enable Then
			Types.Add(Type("Undefined"));
		EndIf;
		ExpectedTypes = New TypeDescription(Types);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter in %2. 
			           |Expected value: %3, actual value: %4 (%5 type).';"),
			ParameterName,
			NameOfAProcedureOrAFunction,
			ExpectedTypes, 
			?(ParameterValue <> Undefined, ParameterValue, NStr("en = 'Undefined';")),
			TypeOf(ParameterValue));
		Raise ErrorText;
	EndIf;
	
	If TypeOf(Profile) = Type("CatalogRef.AccessGroupProfiles")
	 Or TypeOf(Profile) = Type("Undefined") Then
		
		CurrentProfile = Profile;
	Else
		CurrentProfile = Catalogs.AccessGroupProfiles.SuppliedProfileByID(
			Profile, True, True);
	EndIf;
	
	If CurrentProfile <> Undefined Then
		ProfileProperties = Common.ObjectAttributesValues(CurrentProfile,
			"Description, AccessKinds");
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AccessGroups.Ref AS Ref
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|WHERE
	|	&FilterCriterion";
	Query.SetParameter("User", User);
	If CurrentProfile = ProfileAdministrator() Then
		FilterCriterion = "AccessGroups.Ref = &AdministratorsAccessGroup";
		Query.SetParameter("AdministratorsAccessGroup",
			AdministratorsAccessGroup());
	Else
		FilterCriterion = "AccessGroups.User = &User";
		If Enable Or CurrentProfile <> Undefined Then
			FilterCriterion = FilterCriterion + Chars.LF + "	AND AccessGroups.Profile = &Profile"; // @query-part-1
			Query.SetParameter("Profile", CurrentProfile);
		EndIf;
	EndIf;
	Query.Text = StrReplace(Query.Text, "&FilterCriterion", FilterCriterion);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	Block = New DataLock();
	LockItem = Block.Add("Catalog.AccessGroups");
	LockItem.DataSource = QueryResult;
	
	BeginTransaction();
	Try
		Block.Lock();
		Selection.Next();
		While True Do
			PersonalAccessGroup = Selection.Ref;
			If ValueIsFilled(PersonalAccessGroup) Then
				AccessGroupObject = PersonalAccessGroup.GetObject();
				AccessGroupObject.DeletionMark = False;
				
			ElsIf CurrentProfile <> Undefined Then
				// 
				AccessGroupObject = Catalogs.AccessGroups.CreateItem();
				AccessGroupObject.Parent     = Catalogs.AccessGroups.PersonalAccessGroupsParent();
				AccessGroupObject.Description = ProfileProperties.Description;
				AccessGroupObject.User = User;
				AccessGroupObject.Profile      = CurrentProfile;
				FillAccessKindsAndValuesOfNewAccessGroup(AccessGroupObject,
					ProfileProperties, Source);
			Else
				AccessGroupObject = Undefined;
			EndIf;
			
			If PersonalAccessGroup = AdministratorsAccessGroup() Then
				UserDetails =  AccessGroupObject.Users.Find(
					User, "User");
				
				If Enable And UserDetails = Undefined Then
					AccessGroupObject.Users.Add().User = User;
				ElsIf Not Enable And UserDetails <> Undefined Then
					AccessGroupObject.Users.Delete(UserDetails);
				EndIf;
				
				If Not Common.DataSeparationEnabled() Then
					// 
					ErrorDescription = "";
					AccessManagementInternal.CheckAdministratorsAccessGroupForIBUser(
						AccessGroupObject.Users, ErrorDescription);
					
					If ValueIsFilled(ErrorDescription) Then
						ErrorText =
							NStr("en = 'At least one user authorized to log in
							           |must have the Administrator profile.';");
						Raise ErrorText;
					EndIf;
				EndIf;
			ElsIf AccessGroupObject <> Undefined Then
				AccessGroupObject.Users.Clear();
				If Enable Then
					AccessGroupObject.Users.Add().User = User;
				EndIf;
			EndIf;
			
			If AccessGroupObject <> Undefined Then
				AccessGroupObject.Write();
			EndIf;
			
			If Not Selection.Next() Then
				Break;
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure FillAccessKindsAndValuesOfNewAccessGroup(AccessGroupObject, ProfileProperties, Source)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AccessGroups.Ref AS Ref
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|WHERE
	|	AccessGroups.Profile = &Profile
	|	AND AccessGroups.User = &User";
	Query.SetParameter("Profile", AccessGroupObject.Profile);
	Query.SetParameter("User", Source);
	
	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.Count() = 1 Then
		GroupProperties = Common.ObjectAttributesValues(Selection.Ref,
			"AccessKinds, AccessValues");
		AccessGroupObject.AccessKinds.Load(GroupProperties.AccessKinds.Unload());
		AccessGroupObject.AccessValues.Load(GroupProperties.AccessValues.Unload());
	Else
		AccessGroupObject.AccessKinds.Load(AccessKindsForNewAccessGroup(ProfileProperties));
	EndIf;
	
EndProcedure

Function AccessKindsForNewAccessGroup(ProfileProperties)
	
	AccessKinds = ProfileProperties.AccessKinds.Unload();
	
	Filter = New Structure;
	Filter.Insert("Predefined", True);
	Predefined1 = AccessKinds.FindRows(Filter);
	
	For Each Predefined In Predefined1 Do
		AccessKinds.Delete(Predefined);
	EndDo;
	
	Return AccessKinds;
	
EndFunction

#EndRegion
