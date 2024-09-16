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

// Returns the current user or the current external user,
// depending on who logged in to the session.
//  We recommend using it in code that supports both cases.
//
// Returns:
//  CatalogRef.Users, CatalogRef.ExternalUsers - 
//    
//
Function AuthorizedUser() Export
	
	Return UsersInternal.AuthorizedUser();
	
EndFunction

// Returns the current user.
//  We recommend using it in code that doesn't support working with external users.
//
//  If an external user logs in to the session, an exception is thrown.
//
// Returns:
//  CatalogRef.Users -  user.
//
Function CurrentUser() Export
	
	Return UsersInternalClientServer.CurrentUser(AuthorizedUser());
	
EndFunction

// Returns True if an external user logged in to the session.
//
// Returns:
//  Boolean - 
//
Function IsExternalUserSession() Export
	
	Return UsersInternalCached.IsExternalUserSession();
	
EndFunction

// Checks whether the current or specified user is a full user.
// 
// A full-fledged user is considered to be a user who:
// a) if the list of users in the information database is not empty
//    , has the role of full-right And the role for system administration (if you check the system administration Rights = Truth);
// b) if the list of users in the information database is empty
//    , the main role of the configuration is not set or full Rights.
//
// Parameters:
//  User - Undefined -  the current is user is checked.
//               - CatalogRef.Users
//               - CatalogRef.ExternalUsers - 
//                    
//                    
//               - InfoBaseUser - 
//
//  CheckSystemAdministrationRights - Boolean -  if set to True, then
//                 the system administration role is checked.
//
//  ForPrivilegedMode - Boolean -  if set to True,
//                 the function returns True for the current user when privileged mode is set.
//
// Returns:
//  Boolean - 
//
Function IsFullUser(User = Undefined,
                                    CheckSystemAdministrationRights = False,
                                    ForPrivilegedMode = True) Export
	
	PrivilegedModeSet = PrivilegedMode();
	
	SetPrivilegedMode(True);
	IBUserProperies = CheckedIBUserProperties(User);
	
	If IBUserProperies = Undefined Then
		Return False;
	EndIf;
	
	CheckFullAccessRole = Not CheckSystemAdministrationRights;
	CheckSystemAdministratorRole = CheckSystemAdministrationRights;
	
	If Not IBUserProperies.IsCurrentIBUser Then
		Roles = IBUserProperies.IBUser.Roles;
		
		// 
		If CheckFullAccessRole
		   And Not Roles.Contains(Metadata.Roles.FullAccess) Then
			Return False;
		EndIf;
		
		If CheckSystemAdministratorRole
		   And Not Roles.Contains(Metadata.Roles.SystemAdministrator) Then
			Return False;
		EndIf;
		
		Return True;
	EndIf;
	
	If ForPrivilegedMode And PrivilegedModeSet Then
		Return True;
	EndIf;
	
	If StandardSubsystemsCached.PrivilegedModeSetOnStart() Then
		// 
		// 
		Return True;
	EndIf;
	
	If Not ValueIsFilled(IBUserProperies.Name) And Metadata.DefaultRoles.Count() = 0 Then
		// 
		// 
		Return True;
	EndIf;
	
	If Not ValueIsFilled(IBUserProperies.Name)
	   And PrivilegedModeSet
	   And IBUserProperies.AdministrationRight Then
		// 
		// 
		// 
		Return True;
	EndIf;
	
	// 
	// 
	If CheckFullAccessRole
	   And Not IBUserProperies.RoleAvailableFullAccess Then
		Return False;
	EndIf;
	
	If CheckSystemAdministratorRole
	   And Not IBUserProperies.SystemAdministratorRoleAvailable Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Returns the availability of at least one of the specified roles or
// the user's full rights (current or specified).
//
// Parameters:
//  RolesNames   - String -  comma-separated role names that are checked for availability.
//
//  User - Undefined -  the current is user is checked.
//               - CatalogRef.Users
//               - CatalogRef.ExternalUsers - 
//                    
//                    
//               - InfoBaseUser - 
//
//  ForPrivilegedMode - Boolean -  if set to True,
//                 the function returns True for the current user when privileged mode is set.
//
// Returns:
//  Boolean - 
//           
//
Function RolesAvailable(RolesNames,
                     User = Undefined,
                     ForPrivilegedMode = True) Export
	
	SystemAdministratorRole1 = IsFullUser(User, True, ForPrivilegedMode);
	FullAccessRole          = IsFullUser(User, False,   ForPrivilegedMode);
	
	If SystemAdministratorRole1 And FullAccessRole Then
		Return True;
	EndIf;
	
	RolesNamesArray = StrSplit(RolesNames, ",", False);
	
	SystemAdministratorRoleRequired = False;
	RolesAssignment = UsersInternalCached.RolesAssignment();
	
	For Each NameOfRole In RolesNamesArray Do
		If RolesAssignment.ForSystemAdministratorsOnly.Get(NameOfRole) <> Undefined Then
			SystemAdministratorRoleRequired = True;
			Break;
		EndIf;
	EndDo;
	
	If SystemAdministratorRole1 And    SystemAdministratorRoleRequired
	 Or FullAccessRole          And Not SystemAdministratorRoleRequired Then
		Return True;
	EndIf;
	
	SetPrivilegedMode(True);
	IBUserProperies = CheckedIBUserProperties(User);
	
	If IBUserProperies = Undefined Then
		Return False;
	EndIf;
	
	If IBUserProperies.IsCurrentIBUser Then
		For Each NameOfRole In RolesNamesArray Do
			// 
			If IsInRole(TrimAll(NameOfRole)) Then
				Return True;
			EndIf;
			// 
		EndDo;
	Else
		Roles = IBUserProperies.IBUser.Roles;
		For Each NameOfRole In RolesNamesArray Do
			If Roles.Contains(Metadata.Roles.Find(TrimAll(NameOfRole))) Then
				Return True;
			EndIf;
		EndDo;
	EndIf;
	
	Return False;
	
EndFunction

// 
// 
// 
//
// Parameters:
//  IBUserDetails - UUID -  ID of the IB user.
//                         - Structure - :
//                             * StandardAuthentication    - Boolean -  1C authentication:Companies.
//                             * OSAuthentication             - Boolean -  authentication of the operating system.
//                             * OpenIDAuthentication         - Boolean -  OpenID authentication.
//                             * OpenIDConnectAuthentication  - Boolean - 
//                             * AccessTokenAuthentication - Boolean - 
//                         - InfoBaseUser       - 
//                         - CatalogRef.Users        -  user.
//                         - CatalogRef.ExternalUsers -  external user.
//
// Returns:
//  Boolean - 
//
Function CanSignIn(IBUserDetails) Export
	
	SetPrivilegedMode(True);
	
	UUID = Undefined;
	
	If TypeOf(IBUserDetails) = Type("CatalogRef.Users")
	 Or TypeOf(IBUserDetails) = Type("CatalogRef.ExternalUsers") Then
		
		UUID = Common.ObjectAttributeValue(
			IBUserDetails, "IBUserID");
		
		If TypeOf(UUID) <> Type("UUID") Then
			Return False;
		EndIf;
		
	ElsIf TypeOf(IBUserDetails) = Type("UUID") Then
		UUID = IBUserDetails;
	EndIf;
	
	If UUID <> Undefined Then
		IBUser = InfoBaseUsers.FindByUUID(UUID);
		
		If IBUser = Undefined Then
			Return False;
		EndIf;
	Else
		IBUser = IBUserDetails;
	EndIf;
	
	Return IBUser.StandardAuthentication
		Or IBUser.OpenIDAuthentication
		Or IBUser.OpenIDConnectAuthentication
		Or IBUser.AccessTokenAuthentication
		Or IBUser.OSAuthentication;
	
EndFunction

// 
// 
//
// Parameters:
//  IBUser      - InfoBaseUser
//  Interactively        - Boolean - 
//                          
//  AreStartupRightsOnly - Boolean - 
//                          
//
// Returns:
//  Boolean
//
Function HasRightsToLogIn(IBUser, Interactively = True, AreStartupRightsOnly = True) Export
	
	Result =
		    AccessRight("ThinClient",    Metadata, IBUser)
		Or AccessRight("WebClient",       Metadata, IBUser)
		Or AccessRight("MobileClient", Metadata, IBUser)
		Or AccessRight("ThickClient",   Metadata, IBUser);
	
	If Not Interactively Then
		Result = Result
			Or AccessRight("Automation",        Metadata, IBUser)
			Or AccessRight("ExternalConnection", Metadata, IBUser);
	EndIf;
	
	If Not AreStartupRightsOnly Then
		// 
		Result = Result And RolesAvailable("BasicAccessSSL,
			|BasicAccessExternalUserSSL", IBUser, False);
		// 
	EndIf;
	
	Return Result;
	
EndFunction

// You should call http services, web services, and com connections at the beginning of procedures,
// if they are used for remote connection of regular users,
// to ensure control of login restrictions (by date, by activity, etc.),
// update the date of the last login, and immediately fill in the session parameters
// Authorized user, Current User, Current External user.
//
// The procedure is called automatically only on interactive input,
// that is, when the current startup mode () < > is undefined.
//
// Parameters:
//  RaiseException1 - Boolean -  raise an exception in case of an authorization error,
//                                otherwise return the error text.
// Returns:
//  Structure:
//   * AuthorizationError      - String -  error text, if filled in.
//   * PasswordChangeRequired - Boolean -  if True, then this is a password deprecation error.
//
Function AuthorizeTheCurrentUserWhenLoggingIn(RaiseException1 = True) Export
	
	Result = UsersInternal.AuthorizeTheCurrentUserWhenLoggingIn(True);
	
	If RaiseException1 And ValueIsFilled(Result.AuthorizationError) Then
		Raise Result.AuthorizationError;
	EndIf;
	
	Return Result;
	
EndFunction

// 
// 
// 
// 
//
// Returns:
//  Boolean
//
Function IndividualUsed() Export
	
	Return UsersInternalCached.Settings().IndividualUsed;
	
EndFunction

// 
// 
// 
// 
//
// Returns:
//  Boolean
//
Function IsDepartmentUsed() Export
	
	Return UsersInternalCached.Settings().IsDepartmentUsed;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Returns a list of users, user groups, external users,
// and external user groups.
// For use in event handlers for end-of-text And auto-selection.
//
// Parameters:
//  Text         - String -  characters entered by the user.
//
//  IncludeGroups - Boolean -  if True, include user groups and external users.
//                  If the use user Group option is disabled, the parameter is ignored.
//
//  IncludeExternalUsers - Undefined
//                              - Boolean - 
//                  
//
//  NoUsers - Boolean -  if True, the user directory elements
//                  are excluded from the result.
//
// Returns:
//  ValueList
//
Function GenerateUserSelectionData(Val Text,
                                             Val IncludeGroups = True,
                                             Val IncludeExternalUsers = Undefined,
                                             Val NoUsers = False) Export
	
	IncludeGroups = IncludeGroups And GetFunctionalOption("UseUserGroups");
	
	Query = New Query(
		"SELECT
		|	VALUE(Catalog.Users.EmptyRef) AS Ref,
		|	"""" AS Description,
		|	-1 AS PictureNumber
		|WHERE
		|	FALSE");
	
	If Not NoUsers
	   And AccessRight("Read", Metadata.Catalogs.Users)Then
		
		QueryText =
		"SELECT
		|	Users.Ref AS Ref,
		|	Users.Description AS Description,
		|	ISNULL(UsersInfo.NumberOfStatePicture, 0) - 1 AS PictureNumber
		|FROM
		|	Catalog.Users AS Users
		|		LEFT JOIN InformationRegister.UsersInfo AS UsersInfo
		|		ON UsersInfo.User = Users.Ref
		|WHERE
		|	Users.Description LIKE &Text ESCAPE ""~""
		|	AND Users.Invalid = FALSE
		|	AND Users.IsInternal = FALSE
		|
		|UNION ALL
		|
		|SELECT
		|	UserGroups.Ref,
		|	UserGroups.Description,
		|	CASE
		|		WHEN UserGroups.DeletionMark
		|			THEN 2
		|		ELSE 3
		|	END
		|FROM
		|	Catalog.UserGroups AS UserGroups
		|WHERE
		|	&IncludeGroups
		|	AND UserGroups.Description LIKE &Text ESCAPE ""~""";
		
		Query.Text = Query.Text + " UNION ALL " + QueryText;
	EndIf;
	
	Query.SetParameter("Text", Common.GenerateSearchQueryString(Text) + "%");
	Query.SetParameter("IncludeGroups", IncludeGroups);

	If TypeOf(IncludeExternalUsers) <> Type("Boolean") Then
		IncludeExternalUsers = ExternalUsers.UseExternalUsers();
	EndIf;
	IncludeExternalUsers = IncludeExternalUsers
		And AccessRight("Read", Metadata.Catalogs.ExternalUsers);
	
	If IncludeExternalUsers Then
		QueryText =
		"SELECT
		|	ExternalUsers.Ref AS Ref,
		|	ExternalUsers.Description AS Description,
		|	ISNULL(UsersInfo.NumberOfStatePicture, 0) - 1 AS PictureNumber
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|		LEFT JOIN InformationRegister.UsersInfo AS UsersInfo
		|		ON UsersInfo.User = ExternalUsers.Ref
		|WHERE
		|	ExternalUsers.Description LIKE &Text ESCAPE ""~""
		|	AND ExternalUsers.Invalid = FALSE
		|
		|UNION ALL
		|
		|SELECT
		|	ExternalUsersGroups.Ref,
		|	ExternalUsersGroups.Description,
		|	CASE
		|		WHEN ExternalUsersGroups.DeletionMark
		|			THEN 8
		|		ELSE 9
		|	END
		|FROM
		|	Catalog.ExternalUsersGroups AS ExternalUsersGroups
		|WHERE
		|	&IncludeGroups
		|	AND ExternalUsersGroups.Description LIKE &Text ESCAPE ""~""";
		
		Query.Text = Query.Text + " UNION ALL " + QueryText;
	EndIf;
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	ChoiceData = New ValueList;
	
	While Selection.Next() Do
		ChoiceData.Add(Selection.Ref, Selection.Description, ,
			PictureLib["UserState" + Format(Selection.PictureNumber + 1, "ND=2; NLZ=; NG=")]);
	EndDo;
	
	Return ChoiceData;
	
EndFunction

// Fills in the image numbers of users, user groups, external users, and external user groups
// in all rows or the specified row (see the Row IDENTIFIER parameter) of the Table or Tree collection.
// 
// Parameters:
//  TableOrTree      - FormDataCollection
//                        - FormDataTree - 
//  UserFieldName   - String -  name of the column in the table collection or Tree that contains a reference to a user, 
//                                   user group, external user, or group of external users.
//                                   Its value is used to calculate the image number.
//  PictureNumberFieldName - String -  the name of the column in the table collection, or the Tree with the image number 
//                                   to fill in.
//  RowID  - Undefined
//                       - Number -  
//                                 
//                                 
//  ProcessSecondAndThirdLevelHierarchy - Boolean -  if True and the table or Tree parameter specifies 
//                                 a collection of the data form Tree type, then 
//                                 the fields will be filled up to and including the fourth level of the tree,
//                                 otherwise only the fields at the first and second levels of the tree will be filled in.
//
Procedure FillUserPictureNumbers(Val TableOrTree,
                                               Val UserFieldName,
                                               Val PictureNumberFieldName,
                                               Val RowID = Undefined,
                                               Val ProcessSecondAndThirdLevelHierarchy = False) Export
	
	SetPrivilegedMode(True);
	
	If RowID = Undefined Then
		TableRows = Undefined;
		
	ElsIf TypeOf(RowID) = Type("Array") Then
		TableRows = New Array;
		For Each Id In RowID Do
			TableRows.Add(TableOrTree.FindByID(Id));
		EndDo;
	Else
		TableRows = New Array;
		TableRows.Add(TableOrTree.FindByID(RowID));
	EndIf;
	
	If TypeOf(TableOrTree) = Type("FormDataTree") Then
		If TableRows = Undefined Then
			TableRows = TableOrTree.GetItems();
		EndIf;
		UsersTable = New ValueTable;
		UsersTable.Columns.Add(UserFieldName,
			Metadata.InformationRegisters.UserGroupCompositions.Dimensions.UsersGroup.Type);
		For Each TableRow In TableRows Do
			UsersTable.Add()[UserFieldName] = TableRow[UserFieldName];
			If ProcessSecondAndThirdLevelHierarchy Then
				For Each String2 In TableRow.GetItems() Do
					UsersTable.Add()[UserFieldName] = String2[UserFieldName];
					For Each String3 In String2.GetItems() Do
						UsersTable.Add()[UserFieldName] = String3[UserFieldName];
					EndDo;
				EndDo;
			EndIf;
		EndDo;
	ElsIf TypeOf(TableOrTree) = Type("FormDataCollection") Then
		If TableRows = Undefined Then
			TableRows = TableOrTree;
		EndIf;
		UsersTable = New ValueTable;
		UsersTable.Columns.Add(UserFieldName,
			Metadata.InformationRegisters.UserGroupCompositions.Dimensions.UsersGroup.Type);
		For Each TableRow In TableRows Do
			UsersTable.Add()[UserFieldName] = TableRow[UserFieldName];
		EndDo;
	ElsIf TypeOf(TableOrTree) = Type("Array") Then
		TableRows = TableOrTree;
		UsersTable = New ValueTable;
		UsersTable.Columns.Add(UserFieldName,
			Metadata.InformationRegisters.UserGroupCompositions.Dimensions.UsersGroup.Type);
		For Each TableRow In TableOrTree Do
			UsersTable.Add()[UserFieldName] = TableRow[UserFieldName];
		EndDo;
	Else
		If TableRows = Undefined Then
			TableRows = TableOrTree;
		EndIf;
		UsersTable = TableOrTree.Unload(TableRows, UserFieldName);
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	Users.UserFieldName AS User
	|INTO Users
	|FROM
	|	&Users AS Users
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Users.User AS User,
	|	CASE
	|		WHEN Users.User = UNDEFINED
	|			THEN -1
	|		WHEN VALUETYPE(Users.User) = TYPE(Catalog.Users)
	|			THEN ISNULL(UsersInfo.NumberOfStatePicture, 0) - 1
	|		WHEN VALUETYPE(Users.User) = TYPE(Catalog.UserGroups)
	|			THEN CASE
	|					WHEN CAST(Users.User AS Catalog.UserGroups).DeletionMark
	|						THEN 2
	|					ELSE 3
	|				END
	|		WHEN VALUETYPE(Users.User) = TYPE(Catalog.ExternalUsers)
	|			THEN ISNULL(UsersInfo.NumberOfStatePicture, 0) - 1
	|		WHEN VALUETYPE(Users.User) = TYPE(Catalog.ExternalUsersGroups)
	|			THEN CASE
	|					WHEN CAST(Users.User AS Catalog.ExternalUsersGroups).DeletionMark
	|						THEN 8
	|					ELSE 9
	|				END
	|		ELSE -2
	|	END AS PictureNumber
	|FROM
	|	Users AS Users
	|		LEFT JOIN InformationRegister.UsersInfo AS UsersInfo
	|		ON UsersInfo.User = Users.User";
	
	Query.Text = StrReplace(Query.Text, "UserFieldName", UserFieldName);
	Query.SetParameter("Users", UsersTable);
	PicturesNumbers = Query.Execute().Unload();
	
	For Each TableRow In TableRows Do
		FoundRow = PicturesNumbers.Find(TableRow[UserFieldName], "User");
		TableRow[PictureNumberFieldName] = ?(FoundRow = Undefined, -2, FoundRow.PictureNumber);
		If ProcessSecondAndThirdLevelHierarchy Then
			For Each String2 In TableRow.GetItems() Do
				FoundRow = PicturesNumbers.Find(String2[UserFieldName], "User");
				String2[PictureNumberFieldName] = ?(FoundRow = Undefined, -2, FoundRow.PictureNumber);
				For Each String3 In String2.GetItems() Do
					FoundRow = PicturesNumbers.Find(String3[UserFieldName], "User");
					String3[PictureNumberFieldName] = ?(FoundRow = Undefined, -2, FoundRow.PictureNumber);
				EndDo;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Used for updating and initial filling in the information base.
// 1) Creates the first administrator and maps it to a new or existing
//    user in the Users directory.
// 2) Maps the administrator specified in the user parameter To a new or
//    existing user in the Users directory.
//
// Parameters:
//  IBUser - Undefined -  create the first administrator if it doesn't exist.
//                 - InfoBaseUser - 
//                   
//                   
//
// Returns:
//  Undefined                  - 
//  
//                                  
//
Function CreateAdministrator(IBUser = Undefined) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		ErrorText = NStr("en = 'The ""Users"" catalog is unavailable in shared mode.';");
		Raise ErrorText;
	EndIf;
	
	SetPrivilegedMode(True);
	
	// 
	If IBUser = Undefined Then
		IBUsers = InfoBaseUsers.GetUsers();
		
		If IBUsers.Count() = 0 Then
			If Common.DataSeparationEnabled() Then
				ErrorText =
					NStr("en = 'Cannot automatically create the first administrator of the data area.';");
				Raise ErrorText;
			EndIf;
			IBUser = InfoBaseUsers.CreateUser();
			IBUser.Name       = "Administrator";
			IBUser.FullName = IBUser.Name;
			IBUser.Roles.Clear();
			IBUser.Roles.Add(Metadata.Roles.FullAccess);
			SystemAdministratorRole = Metadata.Roles.SystemAdministrator;
			If Not IBUser.Roles.Contains(SystemAdministratorRole) Then
				IBUser.Roles.Add(SystemAdministratorRole);
			EndIf;
			IBUser.Write();
		Else
			// 
			// 
			For Each CurrentIBUser In IBUsers Do
				If UsersInternal.AdministratorRolesAvailable(CurrentIBUser) Then
					Return Undefined; // 
				EndIf;
			EndDo;
			// 
			ErrorText =
				NStr("en = 'The list of infobase users is not blank. No users
				           |with ""Full access"" and ""System administrator"" roles are found.
				           |
				           |The users might have been created in Designer.
				           |Assign ""Full access"" and ""System administrator"" roles to at least one user.';");
			Raise ErrorText;
		EndIf;
	Else
		If Not UsersInternal.AdministratorRolesAvailable(IBUser) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot create a user in the catalog
				           |mapped to the infobase user""%1""
				           |because it does not have ""Full access"" and ""System administrator"" roles.
				           |
				           |The user was probably created in Designer.
				           |To have a user created in the catalog automatically,
				           |grant the infobase user both ""Full access"" and ""System administrator"" roles.';"),
				String(IBUser));
			Raise ErrorText;
		EndIf;
		
		FindAmbiguousIBUsers(Undefined, IBUser.UUID);
	EndIf;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("Catalog.Users");
		LockItem.SetValue("IBUserID", IBUser.UUID);
		LockItem = Block.Add("Catalog.ExternalUsers");
		LockItem.SetValue("IBUserID", IBUser.UUID);
		LockItem = Block.Add("Catalog.Users");
		LockItem.SetValue("Description", IBUser.FullName);
		Block.Lock();
		
		User = Undefined;
		UsersInternal.UserByIDExists(IBUser.UUID,, User);
		If TypeOf(User) = Type("CatalogRef.ExternalUsers") Then
			ExternalUserObject = User.GetObject();
			ExternalUserObject.IBUserID = Undefined;
			InfobaseUpdate.WriteData(ExternalUserObject);
			User = Undefined;
		EndIf;

		If Not ValueIsFilled(User) Then
			User = Catalogs.Users.FindByDescription(IBUser.FullName);
			
			If ValueIsFilled(User)
			   And ValueIsFilled(User.IBUserID)
			   And User.IBUserID <> IBUser.UUID
			   And InfoBaseUsers.FindByUUID(
			         User.IBUserID) <> Undefined Then
				
				User = Undefined;
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(User) Then
			User = Catalogs.Users.CreateItem();
			UserCreated = True;
		Else
			User = User.GetObject();
			UserCreated = False;
		EndIf;
		
		User.Description = IBUser.FullName;
		
		IBUserDetails = New Structure;
		IBUserDetails.Insert("Action", "Write");
		IBUserDetails.Insert("UUID", IBUser.UUID);
		User.AdditionalProperties.Insert(
			"IBUserDetails", IBUserDetails);
		User.AdditionalProperties.Insert("CreateAdministrator",
			?(IBUser = Undefined,
			  NStr("en = 'The first administrator is created.';"),
			  ?(UserCreated,
			    NStr("en = 'The administrator is mapped to a new catalog user.';"),
			    NStr("en = 'The administrator is mapped to an existing catalog user.';")) ) );
			
		User.Write();
	
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	Return User.Ref;
	
EndFunction

// Sets the use user Group constant to True
// if there is at least one user group in the directory.
//
// Used when updating the information base.
//
Procedure IfUserGroupsExistSetUsage() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.UserGroups AS UserGroups
	|WHERE
	|	UserGroups.Ref <> VALUE(Catalog.UserGroups.AllUsers)
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE
	|FROM
	|	Catalog.ExternalUsersGroups AS ExternalUsersGroups
	|WHERE
	|	ExternalUsersGroups.Ref <> VALUE(Catalog.ExternalUsersGroups.AllExternalUsers)");
	
	If Not Query.Execute().IsEmpty() Then
		Constants.UseUserGroups.Set(True);
	EndIf;
	
EndProcedure

// 
//
// Returns:
//  CatalogRef.UserGroups
//
Function AllUsersGroup() Export
	
	Return UsersInternalCached.StandardUsersGroup("AllUsers");
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// 
// 
//
// Returns:
//   String
//
Function UnspecifiedUserFullName() Export
	
	Return "<" + NStr("en = 'Not specified';") + ">";
	
EndFunction

// 
// 
//
// Parameters:
//  CreateIfDoesNotExists - Boolean -  if True, the user "<not specified> " will be created.
//
// Returns:
//  CatalogRef.Users
//  Undefined - if an unspecified user does not exist in the directory.
//
Function UnspecifiedUserRef(CreateIfDoesNotExists = False) Export
	
	Ref = UsersInternal.UnspecifiedUserProperties().Ref;
	
	If Ref = Undefined And CreateIfDoesNotExists Then
		Ref = UsersInternal.CreateUnspecifiedUser();
	EndIf;
	
	Return Ref;
	
EndFunction

// Checks whether the is user is associated with the users directory element or
// with the external Users directory element.
// 
// Parameters:
//  IBUser - String -  name of the IB user.
//                 - UUID - 
//                 - InfoBaseUser
//
//  Account  - InfoBaseUser -  the return value.
//
// Returns:
//  Boolean - 
//   
//
Function IBUserOccupied(IBUser, Account = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(IBUser) = Type("String") Then
		Account = InfoBaseUsers.FindByName(IBUser);
		
	ElsIf TypeOf(IBUser) = Type("UUID") Then
		Account = InfoBaseUsers.FindByUUID(IBUser);
	Else
		Account = IBUser;
	EndIf;
	
	If Account = Undefined Then
		Return False;
	EndIf;
	
	Return UsersInternal.UserByIDExists(
		Account.UUID);
	
EndFunction

// Returns an empty structure for the is user description.
// The assignment of structure properties corresponds to the properties of the user information Database object.
//
// Parameters:
//  IsIntendedForSetting - Boolean - 
//    
//    
//    
//
// Returns:
//  Structure:
//   * UUID   - UUID - 
//                                 
//   * Name                       - String -  name of the database user. For Example, "Ivanov".
//                               - Undefined - 
//   * FullName                 - String -  
//                                   
//                               - Undefined - 
//   * Email     - String - 
//                               - Undefined - 
//
//   * StandardAuthentication      - Boolean -  whether standard authentication (by user and password) is allowed.
//                                    - Undefined - 
//   * ShowInList        - Boolean -  whether to show the user's full name in the list for selection at startup.
//   * Password                         - String - 
//                                    - Undefined - 
//                                        
//   * StoredPasswordValue      - String - 
//                                    - Undefined - 
//   * PasswordIsSet               - Boolean - 
//                                      
//                                    - Undefined - 
//   * CannotChangePassword        - Boolean -  determines whether the user can change their password.
//                                    - Undefined - 
//   * CannotRecoveryPassword - Boolean - 
//                                    - Undefined - 
//
//   * OpenIDAuthentication         - Boolean - 
//                                  - Undefined - 
//   * OpenIDConnectAuthentication  - Boolean - 
//                                  - Undefined - 
//   * AccessTokenAuthentication - Boolean - 
//                                  - Undefined - 
//
//   * OSAuthentication          - Boolean -  whether authentication is enabled by the operating system.
//                               - Undefined - 
//   * OSUser            - String -  name of the corresponding operating system user account 
//                                          (not included in the training version of the platform).
//                               - Undefined - 
//
//   * DefaultInterface         - String - 
//                                         
//                               - Undefined - 
//   * RunMode              - String - 
//                               - Undefined - 
//   * Language                      - String - 
//                               - Undefined - 
//   * Roles                      - Array of String - 
//                               - Undefined - 
//
//   * UnsafeActionProtection   - Boolean - 
//                                   
//                               - Undefined - 
//
Function NewIBUserDetails(IsIntendedForSetting = True) Export
	
	// 
	Properties = New Structure;
	
	Properties.Insert("Name",                            "");
	Properties.Insert("FullName",                      "");
	Properties.Insert("Email",          "");
	Properties.Insert("StandardAuthentication",      False);
	Properties.Insert("ShowInList",        False);
	Properties.Insert("PreviousPassword",                   Undefined);
	Properties.Insert("Password",                         Undefined);
	Properties.Insert("StoredPasswordValue",      Undefined);
	Properties.Insert("PasswordIsSet",               False);
	Properties.Insert("CannotChangePassword",        False);
	Properties.Insert("CannotRecoveryPassword", True);
	Properties.Insert("OpenIDAuthentication",           False);
	Properties.Insert("OpenIDConnectAuthentication",    False);
	Properties.Insert("AccessTokenAuthentication",   False);
	Properties.Insert("OSAuthentication",               False);
	Properties.Insert("OSUser",                 "");
	
	Properties.Insert("DefaultInterface",
		?(Metadata.DefaultInterface = Undefined, "", Metadata.DefaultInterface.Name));
	
	Properties.Insert("RunMode", "Auto");
	
	Properties.Insert("Language",
		?(Metadata.DefaultLanguage = Undefined, "", Metadata.DefaultLanguage.Name));
	
	Properties.Insert("Roles", New Array);
	
	Properties.Insert("UnsafeActionProtection", True);
	
	If IsIntendedForSetting Then
		For Each KeyAndValue In Properties Do
			Properties[KeyAndValue.Key] = Undefined;
		EndDo;
	EndIf;
	
	Properties.Insert("UUID", CommonClientServer.BlankUUID());
	
	Return Properties;
	
EndFunction

// Returns the user properties of the information database as a structure.
// If the user with the specified ID or name does not exist, it is returned Undefined.
//
// Parameters:
//  NameOrID  - String
//                       - UUID - 
//
// Returns:
//  Structure - See Users.NewIBUserDetails
//  
//
Function IBUserProperies(Val NameOrID) Export
	
	CommonClientServer.CheckParameter("Users.IBUserProperies", "NameOrID",
		NameOrID, New TypeDescription("String, UUID"));
	
	Properties = NewIBUserDetails(False);
	
	If TypeOf(NameOrID) = Type("UUID") Then
		IBUser = UsersInternal.InfobaseUserByID(NameOrID);
		
	ElsIf TypeOf(NameOrID) = Type("String") Then
		IBUser = InfoBaseUsers.FindByName(NameOrID);
	Else
		IBUser = Undefined;
	EndIf;
	
	If IBUser = Undefined Then
		Return Undefined;
	EndIf;
	
	CopyIBUserProperties(Properties, IBUser);
	Properties.Insert("IBUser", IBUser);
	Return Properties;
	
EndFunction

// 
// 
//
// Parameters:
//  NameOrID - String
//                      - UUID -  
//                                                  
//  PropertiesToUpdate - See Users.NewIBUserDetails
//
//  CreateNewOne - Boolean -  specify True to create a new IB user named Name_identifier.
//
//  IsExternalUser - Boolean -  specify True if the is user corresponds to an external user
//                                    (an element of the external Users directory).
//
Procedure SetIBUserProperies(Val NameOrID, Val PropertiesToUpdate,
	Val CreateNewOne = False, Val IsExternalUser = False) Export
	
	ProcedureName = "Users.SetIBUserProperies";
	
	CommonClientServer.CheckParameter(ProcedureName, "NameOrID",
		NameOrID, New TypeDescription("String, UUID"));
	
	CommonClientServer.CheckParameter(ProcedureName, "PropertiesToUpdate",
		PropertiesToUpdate, Type("Structure"));
	
	CommonClientServer.CheckParameter(ProcedureName, "CreateNewOne",
		CreateNewOne, Type("Boolean"));
	
	CommonClientServer.CheckParameter(ProcedureName, "IsExternalUser",
		IsExternalUser, Type("Boolean"));
	
	PreviousProperties = IBUserProperies(NameOrID);
	UserExists = PreviousProperties <> Undefined;
	If UserExists Then
		IBUser = PreviousProperties.IBUser;
		OldInfobaseUserString = ValueToStringInternal(IBUser);
	Else
		IBUser = Undefined;
		OldInfobaseUserString = Undefined;
		PreviousProperties = NewIBUserDetails(False);
	EndIf;
		
	If Not UserExists Then
		If Not CreateNewOne Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Infobase user ""%1"" does not exist.';"),
				NameOrID);
			Raise ErrorText;
		EndIf;
		IBUser = InfoBaseUsers.CreateUser();
	Else
		If CreateNewOne Then
			ErrorText = ErrorDescriptionOnWriteIBUser(
				NStr("en = 'Cannot create infobase user ""%1"". The user already exists.';"),
				PreviousProperties.Name,
				PreviousProperties.UUID);
			Raise ErrorText;
		EndIf;
		
		If PropertiesToUpdate.Property("PreviousPassword")
		   And TypeOf(PropertiesToUpdate.PreviousPassword) = Type("String") Then
			
			PreviousPasswordMatches = UsersInternal.PreviousPasswordMatchSaved(
				PropertiesToUpdate.PreviousPassword, PreviousProperties.UUID);
			
			If Not PreviousPasswordMatches Then
				ErrorText = ErrorDescriptionOnWriteIBUser(
					NStr("en = 'Couldn''t save infobase user ""%1"". The previous password is incorrect.';"),
					PreviousProperties.Name,
					PreviousProperties.UUID);
				Raise ErrorText;
			EndIf;
		EndIf;
	EndIf;
	
	// 
	SetPassword = False;
	NewProperties = Common.CopyRecursive(PreviousProperties);
	For Each KeyAndValue In NewProperties Do
		If Not PropertiesToUpdate.Property(KeyAndValue.Key)
		 Or PropertiesToUpdate[KeyAndValue.Key] = Undefined Then
			Continue;
		EndIf;
		If KeyAndValue.Key <> "Password" Then
			NewProperties[KeyAndValue.Key] = PropertiesToUpdate[KeyAndValue.Key];
			Continue;
		EndIf;
		If PropertiesToUpdate.Property("StoredPasswordValue")
		   And PropertiesToUpdate.StoredPasswordValue <> Undefined
		 Or StandardSubsystemsServer.IsTrainingPlatform() Then
			Continue;
		EndIf;
		SetPassword = True;
	EndDo;
	
	CopyIBUserProperties(IBUser, NewProperties);
	
	UsersInternal.SetPasswordPolicy(IBUser, IsExternalUser);
	
	If SetPassword Then
		PasswordErrorText = UsersInternal.PasswordComplianceError(
			PropertiesToUpdate.Password, IBUser);
		
		If ValueIsFilled(PasswordErrorText) Then
			ErrorText = ErrorDescriptionOnWriteIBUser(
				NStr("en = 'Couldn''t save properties of infobase user ""%1"". Reason:
				           |%2.';"),
				IBUser.Name,
				?(UserExists, PreviousProperties.UUID, Undefined),
				PasswordErrorText);
			Raise ErrorText;
		EndIf;
		If UsersInternal.IsSettings8_3_26Available() Then
			// 
			IBUser.StoredPasswordValue =
				Eval("EvaluateStoredUserPasswordValue(PropertiesToUpdate.Password)");
			// 
		Else
			IBUser.StoredPasswordValue =
				UsersInternal.PasswordHashString(PropertiesToUpdate.Password, True);
		EndIf;
	EndIf;
	
	ShowInList = UsersInternalCached.ShowInList();
	If ShowInList <> Undefined Then
		IBUser.ShowInList = ShowInList;
	EndIf;
	
	If OldInfobaseUserString <> ValueToStringInternal(IBUser)
	 Or PropertiesToUpdate.Property("PasswordSetDateToWrite")
	   And PropertiesToUpdate.PasswordSetDateToWrite <> Undefined  Then
		
		// 
		Try
			UsersInternal.WriteInfobaseUser(IBUser, IsExternalUser);
		Except
			ErrorText = ErrorDescriptionOnWriteIBUser(
				NStr("en = 'Couldn''t save properties of infobase user ""%1"". Reason:
				           |%2.';"),
				IBUser.Name,
				?(UserExists, PreviousProperties.UUID, Undefined),
				ErrorInfo());
			Raise ErrorText;
		EndTry;
		
		If ValueIsFilled(PreviousProperties.Name) And PreviousProperties.Name <> NewProperties.Name Then
			// 
			UsersInternal.CopyUserSettings(PreviousProperties.Name, NewProperties.Name, True);
		EndIf;
		
		If CreateNewOne Then
			UsersInternal.SetInitialSettings(IBUser.Name, IsExternalUser);
		EndIf;
		
		UsersOverridable.OnWriteInfobaseUser(PreviousProperties, NewProperties);
	EndIf;
	
	PropertiesToUpdate.Insert("UUID", IBUser.UUID);
	PropertiesToUpdate.Insert("IBUser", IBUser);
	
EndProcedure

// Deletes the specified database user.
//
// Parameters:
//  NameOrID  - String
//                       - UUID - 
//
Procedure DeleteIBUser(Val NameOrID) Export
	
	CommonClientServer.CheckParameter("Users.DeleteIBUser", "NameOrID",
		NameOrID, New TypeDescription("String, UUID"));
		
	DeletedIBUserProperties = IBUserProperies(NameOrID);
	If DeletedIBUserProperties = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Infobase user ""%1"" does not exist.';"),
			NameOrID);
		Raise ErrorText;
	EndIf;
	IBUser = DeletedIBUserProperties.IBUser;
		
	Try
		
		SSLSubsystemsIntegration.BeforeDeleteIBUser(IBUser);
		IBUser.Delete();
		
	Except
		ErrorText = ErrorDescriptionOnWriteIBUser(
			NStr("en = 'Cannot delete infobase user ""%1"". Reason:
			           |%2.';"),
			IBUser.Name,
			IBUser.UUID,
			ErrorInfo());
		Raise ErrorText;
	EndTry;
	UsersOverridable.AfterDeleteInfobaseUser(DeletedIBUserProperties);
	
EndProcedure

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
//  Receiver     - Structure
//               - InfoBaseUser
//               - ClientApplicationForm - 
//                 
//
//  Source     - Structure
//               - InfoBaseUser
//               - ClientApplicationForm - 
//                 
//                 
// 
//  PropertiesToCopy  - String -  a comma-separated list of properties to copy (without the prefix).
//  PropertiesToExclude - String -  a comma-separated list of properties that do not need to be copied (without a prefix).
//  PropertyPrefix      - String -  the initial name for the Source or Receiver type is NOT a Structure.
//                      - Map:
//                         * Key - 
//                         * Value - 
//
Procedure CopyIBUserProperties(Receiver,
                                            Source,
                                            PropertiesToCopy = "",
                                            PropertiesToExclude = "",
                                            PropertyPrefix = "") Export
	
	If TypeOf(Receiver) = Type("InfoBaseUser")
	   And TypeOf(Source) = Type("InfoBaseUser")
	   
	 Or TypeOf(Receiver) = Type("InfoBaseUser")
	   And TypeOf(Source) <> Type("Structure")
	   And TypeOf(Source) <> Type("ClientApplicationForm")
	   
	 Or TypeOf(Source) = Type("InfoBaseUser")
	   And TypeOf(Receiver) <> Type("Structure")
	   And TypeOf(Receiver) <> Type("ClientApplicationForm") Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of parameter %1 or %2.
			           |Common module: %4. Procedure: %3.';"),
			"Receiver",
			"Source",
			"CopyIBUserProperties",
			"Users");
		Raise ErrorText;
	EndIf;
	
	AllProperties = NewIBUserDetails();
	
	If ValueIsFilled(PropertiesToCopy) Then
		CopiedPropertiesStructure = New Structure(PropertiesToCopy);
	Else
		CopiedPropertiesStructure = AllProperties;
	EndIf;
	
	If ValueIsFilled(PropertiesToExclude) Then
		ExcludedPropertiesStructure = New Structure(PropertiesToExclude);
	Else
		ExcludedPropertiesStructure = New Structure;
	EndIf;
	
	If StandardSubsystemsServer.IsTrainingPlatform() Then
		ExcludedPropertiesStructure.Insert("OSAuthentication");
		ExcludedPropertiesStructure.Insert("OSUser");
	EndIf;
	
	PasswordIsSet = False;
	
	For Each KeyAndValue In AllProperties Do
		Property = KeyAndValue.Key;
		
		If Not CopiedPropertiesStructure.Property(Property)
		 Or ExcludedPropertiesStructure.Property(Property) Then
		
			Continue;
		EndIf;
		
		If TypeOf(Source) = Type("InfoBaseUser")
		   And (    TypeOf(Receiver) = Type("Structure")
		      Or TypeOf(Receiver) = Type("ClientApplicationForm") ) Then
			
			If Property = "Password"
			 Or Property = "PreviousPassword" Then
				
				PropertyValue = Undefined;
				
			ElsIf Property = "DefaultInterface" Then
				PropertyValue = ?(Source.DefaultInterface = Undefined,
					"", Source.DefaultInterface.Name);
			
			ElsIf Property = "RunMode" Then
				ValueFullName = GetPredefinedValueFullName(Source.RunMode);
				PropertyValue = Mid(ValueFullName, StrFind(ValueFullName, ".") + 1);
				
			ElsIf Property = "Language" Then
				PropertyValue = ?(Source.Language = Undefined,
					"", Source.Language.Name);
				
			ElsIf Property = "UnsafeActionProtection" Then
				PropertyValue =
					Source.UnsafeOperationProtection.UnsafeOperationWarnings;
				
			ElsIf Property = "Roles" Then
				
				TempStructure = New Structure("Roles", New ValueTable);
				FillPropertyValues(TempStructure, Receiver);
				If TypeOf(TempStructure.Roles) = Type("ValueTable") Then
					Continue;
				ElsIf TempStructure.Roles = Undefined
				      Or TypeOf(TempStructure.Roles) = Type("Array") Then
					Receiver.Roles = New Array;
				Else
					Receiver.Roles.Clear();
				EndIf;
				
				For Each Role In Source.Roles Do
					Receiver.Roles.Add(Role.Name);
				EndDo;
				
				Continue;
			Else
				PropertyValue = Source[Property];
			EndIf;
			
			If TypeOf(PropertyPrefix) = Type("Map") Then
				PropertyFullName = PropertyPrefix.Get(Property);
				If Not ValueIsFilled(PropertyFullName) Then
					Continue;
				EndIf;
			Else
				PropertyFullName = PropertyPrefix + Property;
			EndIf;
			TempStructure = New Structure(PropertyFullName, PropertyValue);
			FillPropertyValues(Receiver, TempStructure);
		Else
			If TypeOf(Source) = Type("Structure") Then
				If Source.Property(Property) Then
					PropertyValue = Source[Property];
				Else
					Continue;
				EndIf;
			Else
				If TypeOf(PropertyPrefix) = Type("Map") Then
					PropertyFullName = PropertyPrefix.Get(Property);
					If Not ValueIsFilled(PropertyFullName) Then
						Continue;
					EndIf;
				Else
					PropertyFullName = PropertyPrefix + Property;
				EndIf;
				TempStructure = New Structure(PropertyFullName, New ValueTable);
				FillPropertyValues(TempStructure, Source);
				PropertyValue = TempStructure[PropertyFullName];
				If TypeOf(PropertyValue) = Type("ValueTable") Then
					Continue;
				EndIf;
			EndIf;
			If PropertyValue = Undefined Then
				Continue;
			EndIf;
			
			If TypeOf(Receiver) = Type("InfoBaseUser") Then
			
				If Property = "UUID"
				 Or Property = "PreviousPassword"
				 Or Property = "PasswordIsSet" Then
					
					Continue;
					
				ElsIf Property = "StandardAuthentication"
				      Or Property = "OpenIDAuthentication"
				      Or Property = "OpenIDConnectAuthentication"
				      Or Property = "AccessTokenAuthentication"
				      Or Property = "OSAuthentication"
				      Or Property = "OSUser" Then
					
					If Receiver[Property] <> PropertyValue Then
						Receiver[Property] = PropertyValue;
					EndIf;
					
				ElsIf Property = "Password" Then
					Receiver.Password = PropertyValue;
					PasswordIsSet = True;
					
				ElsIf Property = "StoredPasswordValue" Then
					If Not PasswordIsSet
					   And Receiver.StoredPasswordValue <> PropertyValue Then
						Receiver.StoredPasswordValue = PropertyValue;
					EndIf;
					
				ElsIf Property = "DefaultInterface" Then
					If TypeOf(PropertyValue) = Type("String") Then
						Receiver.DefaultInterface = Metadata.Interfaces.Find(PropertyValue);
					Else
						Receiver.DefaultInterface = Undefined;
					EndIf;
				
				ElsIf Property = "RunMode" Then
					If PropertyValue = "Auto"
					 Or PropertyValue = "OrdinaryApplication"
					 Or PropertyValue = "ManagedApplication" Then
						
						Receiver.RunMode = ClientRunMode[PropertyValue];
					Else
						Receiver.RunMode = ClientRunMode.Auto;
					EndIf;
					
				ElsIf Property = "UnsafeActionProtection" Then
					Receiver.UnsafeOperationProtection.UnsafeOperationWarnings =
						PropertyValue;
					
				ElsIf Property = "Language" Then
					If TypeOf(PropertyValue) = Type("String") Then
						Receiver.Language = Metadata.Languages.Find(PropertyValue);
					Else
						Receiver.Language = Undefined;
					EndIf;
					
				ElsIf Property = "Roles" Then
					Receiver.Roles.Clear();
					For Each NameOfRole In PropertyValue Do
						Role = Metadata.Roles.Find(NameOfRole);
						If Role <> Undefined Then
							Receiver.Roles.Add(Role);
						EndIf;
					EndDo;
				Else
					If Property = "Name"
					   And Receiver[Property] <> PropertyValue Then
					
						If StrLen(PropertyValue) > 64 Then
							ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("en = 'Couldn''t save the infobase user.
								           |The username ""%1""
								           |exceeds the limit of 64 characters.';"),
								PropertyValue);
							Raise ErrorText;
							
						ElsIf StrFind(PropertyValue, ":") > 0 Then
							ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("en = 'Couldn''t save the infobase user.
								           |The username ""%1""
								           |contains an illegal character (colon).';"),
								PropertyValue);
							Raise ErrorText;
						EndIf;
					EndIf;
					Receiver[Property] = Source[Property];
				EndIf;
			Else
				If Property = "Roles" Then
					TempStructure = New Structure("Roles", New ValueTable);
					FillPropertyValues(TempStructure, Receiver);
					If TypeOf(TempStructure.Roles) = Type("ValueTable") Then
						Continue;
					ElsIf TempStructure.Roles = Undefined
					      Or TypeOf(TempStructure.Roles) = Type("Array") Then
						Receiver.Roles = New Array;
					Else
						Receiver.Roles.Clear();
					EndIf;
					
					If Source.Roles <> Undefined Then
						For Each Role In Source.Roles Do
							Receiver.Roles.Add(Role.Name);
						EndDo;
					EndIf;
					Continue;
					
				ElsIf TypeOf(Source) = Type("Structure") Then
					If TypeOf(PropertyPrefix) = Type("Map") Then
						PropertyFullName = PropertyPrefix.Get(Property);
						If Not ValueIsFilled(PropertyFullName) Then
							Continue;
						EndIf;
					Else
						PropertyFullName = PropertyPrefix + Property;
					EndIf;
				Else
					PropertyFullName = Property;
				EndIf;
				TempStructure = New Structure(PropertyFullName, PropertyValue);
				FillPropertyValues(Receiver, TempStructure);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// 
// 
// 
// Parameters:
//  LoginName - String -  name of the database user used for logging in.
//
// Returns:
//  CatalogRef.Users           - 
//  
//  
//  
//
Function FindByName(Val LoginName) Export
	
	SetPrivilegedMode(True);
	
	IBUser = InfoBaseUsers.FindByName(LoginName);
	If IBUser = Undefined Then
		Return Undefined;
	EndIf;
	
	User = FindByID(IBUser.UUID);
	If User = Undefined Then
		User = PredefinedValue("Catalog.Users.EmptyRef");
	EndIf;
	
	SetPrivilegedMode(False);
	
	Return User;
	
EndFunction

// 
// 
// 
// 
// Parameters:
//  IBUserID - UUID - 
//
// Returns:
//  CatalogRef.Users           - 
//  
//  
//
Function FindByID(Val IBUserID) Export
	
	If TypeOf(IBUserID) <> Type("UUID") Then
		Return Undefined;
	EndIf;
	
	User = Undefined;
	
	SetPrivilegedMode(True);
	UsersInternal.UserByIDExists(
		IBUserID,, User);
	SetPrivilegedMode(False);
	
	Return User;
	
EndFunction

// 
//  
// 
// 
// Parameters:
//  User - CatalogRef.Users
//               - CatalogRef.ExternalUsers
//
// Returns:
//  InfoBaseUser - 
//  
//
Function FindByReference(User) Export
	
	SetPrivilegedMode(True);
	IBUserID = Common.ObjectAttributeValue(User,
		"IBUserID");
	SetPrivilegedMode(False);
	
	If TypeOf(IBUserID) <> Type("UUID") Then
		Return Undefined;
	EndIf;
	
	Return InfoBaseUsers.FindByUUID(IBUserID);
	
EndFunction

// Searches for IDs of is users that are used more than once, and
// either throws an exception or returns the found is users for further
// processing.
//
// Parameters:
//  User - Undefined -  verification for all users and external users.
//               - CatalogRef.Users
//               - CatalogRef.ExternalUsers - 
//                 
//
//  UUID - Undefined -  checking all specified IDS of is users.
//                          - UUID - 
//
//  FoundIDs - Undefined - 
//                            
//                            
//                          - Map of KeyAndValue:
//                              * Key     - UUID - 
//                              * Value - Array of CatalogRef.Users, CatalogRef.ExternalUsers
//
//  ServiceUserID - Boolean -  if False, then check the userid,
//                                              And if True, then check the userid of the Service.
//
Procedure FindAmbiguousIBUsers(Val User,
                                            Val UUID = Undefined,
                                            Val FoundIDs = Undefined,
                                            Val ServiceUserID = False) Export
	
	SetPrivilegedMode(True);
	BlankUUID = CommonClientServer.BlankUUID();
	
	If TypeOf(UUID) <> Type("UUID")
	 Or UUID = BlankUUID Then
		
		UUID = Undefined;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("BlankUUID", BlankUUID);
	
	If User = Undefined And UUID = Undefined Then
		Query.Text =
		"SELECT
		|	Users.IBUserID AS AmbiguousID
		|FROM
		|	Catalog.Users AS Users
		|
		|GROUP BY
		|	Users.IBUserID
		|
		|HAVING
		|	Users.IBUserID <> &BlankUUID AND
		|	COUNT(Users.Ref) > 1
		|
		|UNION ALL
		|
		|SELECT
		|	ExternalUsers.IBUserID
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|
		|GROUP BY
		|	ExternalUsers.IBUserID
		|
		|HAVING
		|	ExternalUsers.IBUserID <> &BlankUUID AND
		|	COUNT(ExternalUsers.Ref) > 1
		|
		|UNION ALL
		|
		|SELECT
		|	Users.IBUserID
		|FROM
		|	Catalog.Users AS Users
		|		INNER JOIN Catalog.ExternalUsers AS ExternalUsers
		|		ON (ExternalUsers.IBUserID = Users.IBUserID)
		|			AND (Users.IBUserID <> &BlankUUID)";
		
	ElsIf UUID <> Undefined Then
		
		Query.SetParameter("UUID", UUID);
		Query.Text =
		"SELECT
		|	Users.IBUserID AS AmbiguousID
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	Users.IBUserID = &UUID
		|
		|UNION ALL
		|
		|SELECT
		|	ExternalUsers.IBUserID
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|WHERE
		|	ExternalUsers.IBUserID = &UUID";
	Else
		Query.SetParameter("User", User);
		Query.Text =
		"SELECT
		|	Users.IBUserID AS AmbiguousID
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	Users.IBUserID IN
		|			(SELECT
		|				CatalogUsers.IBUserID
		|			FROM
		|				Catalog.Users AS CatalogUsers
		|			WHERE
		|				CatalogUsers.Ref = &User
		|				AND CatalogUsers.IBUserID <> &BlankUUID)
		|
		|UNION ALL
		|
		|SELECT
		|	ExternalUsers.IBUserID
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|WHERE
		|	ExternalUsers.IBUserID IN
		|			(SELECT
		|				CatalogUsers.IBUserID
		|			FROM
		|				Catalog.Users AS CatalogUsers
		|			WHERE
		|				CatalogUsers.Ref = &User
		|				AND CatalogUsers.IBUserID <> &BlankUUID)";
		
		If TypeOf(User) = Type("CatalogRef.ExternalUsers") Then
			Query.Text = StrReplace(Query.Text,
				"Catalog.Users AS CatalogUsers",
				"Catalog.ExternalUsers AS CatalogUsers");
		EndIf;
	EndIf;
	
	If ServiceUserID Then
		Query.Text = StrReplace(Query.Text,
			"IBUserID",
			"ServiceUserID");
	EndIf;
	
	Upload0 = Query.Execute().Unload();
	
	If User = Undefined And UUID = Undefined Then
		If Upload0.Count() = 0 Then
			Return;
		EndIf;
	Else
		If Upload0.Count() < 2 Then
			Return;
		EndIf;
	EndIf;
	
	AmbiguousIDs = Upload0.UnloadColumn("AmbiguousID");
	
	Query = New Query;
	Query.SetParameter("AmbiguousIDs", AmbiguousIDs);
	Query.Text =
	"SELECT
	|	AmbiguousIDs.AmbiguousID AS AmbiguousID,
	|	AmbiguousIDs.User AS User
	|FROM
	|	(SELECT
	|		Users.IBUserID AS AmbiguousID,
	|		Users.Ref AS User
	|	FROM
	|		Catalog.Users AS Users
	|	WHERE
	|		Users.IBUserID IN(&AmbiguousIDs)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ExternalUsers.IBUserID,
	|		ExternalUsers.Ref
	|	FROM
	|		Catalog.ExternalUsers AS ExternalUsers
	|	WHERE
	|		ExternalUsers.IBUserID IN(&AmbiguousIDs)) AS AmbiguousIDs
	|
	|ORDER BY
	|	AmbiguousIDs.AmbiguousID,
	|	AmbiguousIDs.User";
	
	Result = Query.Execute().Unload();
	
	ErrorDescription = "";
	CurrentAmbiguousID = Undefined;
	
	For Each TableRow In Result Do
		If TableRow.AmbiguousID <> CurrentAmbiguousID Then
			CurrentAmbiguousID = TableRow.AmbiguousID;
			If TypeOf(FoundIDs) = Type("Map") Then
				CurrentUsers = New Array;
				FoundIDs.Insert(CurrentAmbiguousID, CurrentUsers);
			Else
				CurrentIBUser = InfoBaseUsers.CurrentUser();
				
				If CurrentIBUser.UUID <> CurrentAmbiguousID Then
					CurrentIBUser =
						InfoBaseUsers.FindByUUID(
							CurrentAmbiguousID);
				EndIf;
				
				If CurrentIBUser = Undefined Then
					LoginName = "<" + NStr("en = 'not found';") + ">";
				Else
					LoginName = CurrentIBUser.Name;
				EndIf;
				
				If ServiceUserID Then
					ErrorDescription = ErrorDescription + StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'The service user with ID ""%1""
						           |is mapped to multiple catalog items:';"),
						CurrentAmbiguousID);
				Else
					ErrorDescription = ErrorDescription + StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'Infobase user ""%1"" with ID ""%2""
						           |is mapped to multiple catalog items:';"),
						LoginName,
						CurrentAmbiguousID);
				EndIf;
				ErrorDescription = ErrorDescription + Chars.LF;
			EndIf;
		EndIf;
		
		If TypeOf(FoundIDs) = Type("Map") Then
			CurrentUsers.Add(TableRow.User);
		Else
			ErrorDescription = ErrorDescription + "- "
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = '""%1"" %2';"),
					TableRow.User,
					GetURL(TableRow.User)) + Chars.LF;
		EndIf;
	EndDo;
	
	If TypeOf(FoundIDs) <> Type("Map") Then
		Raise ErrorDescription;
	EndIf;
	
EndProcedure

// 
// 
// 
// 
// 
// 
//
// Parameters:
//  Password - String -  the password to get the value to save.
//
// Returns:
//  String - 
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
Function PasswordHashString(Val Password) Export
	
	Return UsersInternal.PasswordHashString(Password);
	
EndFunction

// Creates a new password that matches the specified complexity check rules.
// To make it easier to remember, the password is formed from syllables (consonant-vowel).
//
// Parameters:
//  PasswordProperties - See PasswordProperties
//                 
//  DeleteIsComplex         - Boolean - 
//  DeleteConsiderSettings - String - 
//
// Returns:
//  String - 
//
Function CreatePassword(Val PasswordProperties = 7, DeleteIsComplex = False, DeleteConsiderSettings = "ForUsers") Export
	
	If TypeOf(PasswordProperties) = Type("Number") Then
		MinLength = PasswordProperties; 
		PasswordProperties = PasswordProperties();
		PasswordProperties.MinLength = MinLength;
		PasswordProperties.Complicated = DeleteIsComplex;
		PasswordProperties.ConsiderSettings = DeleteConsiderSettings;
	EndIf;
	
	If PasswordProperties.ConsiderSettings = "ForExternalUsers"
	 Or PasswordProperties.ConsiderSettings = "ForUsers" Then
		
		PasswordPolicyName = UsersInternal.PasswordPolicyName(
			PasswordProperties.ConsiderSettings = "ForExternalUsers");
		
		SetPrivilegedMode(True);
		PasswordPolicy = UserPasswordPolicies.FindByName(PasswordPolicyName);
		If PasswordPolicy = Undefined Then
			MinPasswordLength = GetUserPasswordMinLength();
			ComplexPassword          = GetUserPasswordStrengthCheck();
		Else
			MinPasswordLength = PasswordPolicy.PasswordMinLength;
			ComplexPassword          = PasswordPolicy.PasswordStrengthCheck;

		EndIf;
		SetPrivilegedMode(False);
		If MinPasswordLength < PasswordProperties.MinLength Then
			MinPasswordLength = PasswordProperties.MinLength;
		EndIf;
		If Not ComplexPassword And PasswordProperties.Complicated Then
			ComplexPassword = True;
		EndIf;
	Else
		MinPasswordLength = PasswordProperties.MinLength;
		ComplexPassword = PasswordProperties.Complicated;
	EndIf;
	
	PasswordParameters = UsersInternal.PasswordParameters(MinPasswordLength, ComplexPassword);
	
	Return UsersInternal.CreatePassword(PasswordParameters, PasswordProperties.RNG);
	
EndFunction

// 
// 
// Returns:
//   Structure:
//     * MinLength - Number -  the smallest password length.
//     * Complicated - Boolean -  consider password complexity requirements.
//     * ConsiderSettings - String -
//             "Don't account for settings" - ignore administrator settings,
//             "for Users" - consider settings for users (default),
//             "for external Users" - consider settings for external users.
//             If the administrator settings are taken into account, then the specified
//             password length and complexity parameters will be increased to the values specified in the settings.
//     * RNG - RandomNumberGenerator -  if you are already using.
//           - Undefined - 
//
Function PasswordProperties() Export
	
	Result = New Structure;
	Result.Insert("MinLength", 7);
	Result.Insert("Complicated", False);
	Result.Insert("ConsiderSettings", "ForUsers");
	
	Milliseconds = CurrentUniversalDateInMilliseconds();
	BeginningNumber = Milliseconds - Int(Milliseconds / 40) * 40;
	RNG = New RandomNumberGenerator(BeginningNumber);
	
	Result.Insert("RNG", RNG);
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// 
// 
// 
//
// Returns:
//  Boolean - 
//
Function CommonAuthorizationSettingsUsed() Export
	
	Return UsersInternalCached.Settings().CommonAuthorizationSettings;
	
EndFunction

// Returns the role assignment specified by library and application developers.
// Scope: only for automated configuration verification.
//
// Returns:
//  Structure - 
//              
//
Function RolesAssignment() Export
	
	RolesAssignment = New Structure;
	RolesAssignment.Insert("ForSystemAdministratorsOnly",                New Array);
	RolesAssignment.Insert("ForSystemUsersOnly",                  New Array);
	RolesAssignment.Insert("ForExternalUsersOnly",                  New Array);
	RolesAssignment.Insert("BothForUsersAndExternalUsers", New Array);
	
	UsersOverridable.OnDefineRoleAssignment(RolesAssignment);
	SSLSubsystemsIntegration.OnDefineRoleAssignment(RolesAssignment);
	
	For Each Role In Metadata.Roles Do
		Extension = Role.ConfigurationExtension();
		If Extension = Undefined Then
			Continue;
		EndIf;
		NameOfRole = Role.Name;
		
		If StrEndsWith(Upper(NameOfRole), Upper("CommonRights")) Then
			RolesAssignment.BothForUsersAndExternalUsers.Add(NameOfRole);
			
		ElsIf StrEndsWith(Upper(NameOfRole), Upper("BasicAccessExternalUsers")) Then
			RolesAssignment.ForExternalUsersOnly.Add(NameOfRole);
			
		ElsIf StrEndsWith(Upper(NameOfRole), Upper("SystemAdministrator")) Then
			RolesAssignment.ForSystemAdministratorsOnly.Add(NameOfRole);
		EndIf;
	EndDo;
	
	Return RolesAssignment;
	
EndFunction

// Checks whether the role rights match the role assignment specified 
// in the procedure for defining the role assignation Of the shared user module Undefined.
//
// It is used in the following cases:
//  - checking the security of configurations before automatically updating to a new version;
//  - checking the configuration before building;
//  - checking the configuration during development.
//
// Parameters:
//  CheckEverything - Boolean -  if False, then the role assignment check
//                          for service technology requirements is skipped (which is faster), otherwise
//                          the check is performed if separation is enabled.
//
//  ErrorList - Undefined   -  if errors are found, the error text is generated and an exception is thrown.
//               - ValueList - :
//                   * Value      - String -  role name.
//                                   - Undefined - 
//                   * Presentation - String -  error text.
//
Procedure CheckRoleAssignment(CheckEverything = False, ErrorList = Undefined) Export
	
	RolesAssignment = UsersInternalCached.RolesAssignment();
	
	UsersInternal.CheckRoleAssignment(RolesAssignment, CheckEverything, ErrorList);
	
EndProcedure

// Adds all system administrators to the access group
// associated with the predefined openingexternal accounts and Processing profile.
// Hides security warnings that pop up when you first open an administrator session.
// Not for the service model.
//
// Parameters:
//   OpenAllowed - Boolean -  if True, set the opening permission.
//
Procedure SetExternalReportsAndDataProcessorsOpenRight(OpenAllowed) Export
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	AdministrationParameters = StandardSubsystemsServer.AdministrationParameters();
	AdministrationParameters.Insert("OpenExternalReportsAndDataProcessorsDecisionMade", True);
	StandardSubsystemsServer.SetAdministrationParameters(AdministrationParameters);
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.SetExternalReportsAndDataProcessorsOpenRight(OpenAllowed);
		Return;
	EndIf;
	
	SystemAdministratorRole1 = Metadata.Roles.SystemAdministrator;
	InteractiveOpeningRole = Metadata.Roles.InteractiveOpenExtReportsAndDataProcessors;
	
	IBUsers = InfoBaseUsers.GetUsers();
	For Each IBUser In IBUsers Do
		
		If Not IBUser.Roles.Contains(SystemAdministratorRole1) Then
			Continue;
		EndIf;
		
		UserChanged = False;
		HasInteractiveOpeningRole = IBUser.Roles.Contains(InteractiveOpeningRole);
		If OpenAllowed Then 
			If Not HasInteractiveOpeningRole Then 
				IBUser.Roles.Add(InteractiveOpeningRole);
				UserChanged = True;
			EndIf;
		Else 
			If HasInteractiveOpeningRole Then
				IBUser.Roles.Delete(InteractiveOpeningRole);
				UserChanged = True;
			EndIf;
		EndIf;
		If UserChanged Then 
			IBUser.Write();
		EndIf;
		
		SettingsDescription = New SettingsDescription;
		SettingsDescription.Presentation = NStr("en = 'Security warning';");
		Common.CommonSettingsStorageSave(
			"SecurityWarning", 
			"UserAccepts", 
			True, 
			SettingsDescription, 
			IBUser.Name);
		
	EndDo;
	
EndProcedure

// 
// 
// 
// Parameters:
//  CommonSettingsToSave - See Users.CommonAuthorizationSettingsNewDetails
//
Procedure SetCommonAuthorizationSettings(CommonSettingsToSave) Export
	
	Block = New DataLock();
	Block.Add("Constant.UserAuthorizationSettings");
	
	BeginTransaction();
	Try
		Block.Lock();
		
		LogonSettings = UsersInternal.LogonSettings();
		Settings = LogonSettings.Overall;
		
		For Each SettingToSave In CommonSettingsToSave Do
			If Not Settings.Property(SettingToSave.Key)
			 Or TypeOf(Settings[SettingToSave.Key]) <> TypeOf(SettingToSave.Value) Then
				Continue;
			EndIf;
			Settings[SettingToSave.Key] = SettingToSave.Value;
		EndDo;
		
		Constants.UserAuthorizationSettings.Set(New ValueStorage(LogonSettings));
		
		If Not CommonSettingsToSave.Property("UpdateOnlyConstant") Then
			UsersInternal.UpdateCommonPasswordPolicy(Settings);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
		
EndProcedure

// 
// 
// Returns:
//  Structure:
//   * AreSeparateSettingsForExternalUsers - Boolean - 
//       
//   * NotificationLeadTimeBeforeAccessExpire - Number - 
//       
//   * NotificationLeadTimeBeforeTerminateInactiveSession - Number - 
//   * InactivityTimeoutBeforeTerminateSession - Number - 
//   * PasswordAttemptsCountBeforeLockout - Number - 
//       
//   * PasswordLockoutDuration - Number - 
//   * PasswordSaveOptionUponLogin - String - 
//       
//       
//       
//   * PasswordRemembranceDuration - Number - 
//   * ShowInList - String - 
//       
//       
//   * ShouldUseStandardBannedPasswordList - Boolean
//   * ShouldUseAdditionalBannedPasswordList - Boolean
//   * ShouldUseBannedPasswordService - Boolean
//   * BannedPasswordServiceAddress - String - 
//   * BannedPasswordServiceMaxTimeout - Number - 
//   * ShouldSkipValidationIfBannedPasswordServiceOffline - Boolean - 
//       
//       
//
Function CommonAuthorizationSettingsNewDetails() Export
	
	Settings = New Structure;
	Settings.Insert("AreSeparateSettingsForExternalUsers", False);
	
	Settings.Insert("NotificationLeadTimeBeforeAccessExpire", 7);
	Settings.Insert("NotificationLeadTimeBeforeTerminateInactiveSession", 0);
	Settings.Insert("InactivityTimeoutBeforeTerminateSession", 0);
	Settings.Insert("PasswordAttemptsCountBeforeLockout", 3);
	Settings.Insert("PasswordLockoutDuration", 5);
	Settings.Insert("PasswordSaveOptionUponLogin", "AllowedAndDisabled");
	Settings.Insert("PasswordRemembranceDuration", 600);
	Settings.Insert("ShowInList",
		?(Common.DataSeparationEnabled()
		  Or ExternalUsers.UseExternalUsers(),
			"HiddenAndDisabledForAllUsers", "EnabledForNewUsers"));
	
	Settings.Insert("ShouldUseStandardBannedPasswordList", True);
	Settings.Insert("ShouldUseAdditionalBannedPasswordList", False);
	Settings.Insert("ShouldUseBannedPasswordService", False);
	Settings.Insert("BannedPasswordServiceAddress", "");
	Settings.Insert("BannedPasswordServiceMaxTimeout", 1);
	Settings.Insert("ShouldSkipValidationIfBannedPasswordServiceOffline", True);
	
	Return Settings;
	
EndFunction

// 
// 
// 
// Parameters:
//  SavingSettings - See Users.NewDescriptionOfLoginSettings
//  ForExternalUsers - Boolean - 
//
Procedure SetLoginSettings(SavingSettings, ForExternalUsers = False) Export
	
	Block = New DataLock();
	Block.Add("Constant.UserAuthorizationSettings");
	
	BeginTransaction();
	Try
		Block.Lock();
		LogonSettings = UsersInternal.LogonSettings();
		
		If ForExternalUsers Then
			Settings = LogonSettings.ExternalUsers;
		Else
			Settings = LogonSettings.Users;
		EndIf;
		
		For Each SettingToSave In SavingSettings Do
			
			If Not Settings.Property(SettingToSave.Key)
			 Or TypeOf(Settings[SettingToSave.Key]) <> TypeOf(SettingToSave.Value)
			 Or Upper(SettingToSave.Key) = Upper("InactivityPeriodActivationDate")
			   And Not ValueIsFilled(Settings[SettingToSave.Key]) Then
				Continue;
			EndIf;
			Settings[SettingToSave.Key] = SettingToSave.Value;
		EndDo;
		
		If Not ValueIsFilled(Settings.InactivityPeriodBeforeDenyingAuthorization) Then
			Settings.InactivityPeriodActivationDate = Date(1, 1, 1);
		ElsIf Not ValueIsFilled(Settings.InactivityPeriodActivationDate) Then
			Settings.InactivityPeriodActivationDate = BegOfDay(CurrentSessionDate());
		EndIf;
		
		Constants.UserAuthorizationSettings.Set(New ValueStorage(LogonSettings));
		
		If Not SavingSettings.Property("UpdateOnlyConstant") Then
			If ForExternalUsers Then
				If LogonSettings.Overall.AreSeparateSettingsForExternalUsers
				   And CommonAuthorizationSettingsUsed() Then
				
					UsersInternal.UpdateExternalUsersPasswordPolicy(Settings);
				Else
					UsersInternal.UpdateExternalUsersPasswordPolicy(Undefined);
				EndIf;
			Else
				UsersInternal.UpdateUsersPasswordPolicy(Settings);
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// 
// 
// Returns:
//  Structure:
//   * PasswordMustMeetComplexityRequirements - Boolean - 
//        
//          
//          
//            
//          
//   * MinPasswordLength - Number - 
//   * ShouldBeExcludedFromBannedPasswordList - Boolean - 
//        
//        
//   * ActionUponLoginIfRequirementNotMet - String - 
//        
//        
//        
//        
//   * MaxPasswordLifetime - Number - 
//   * MinPasswordLifetime - Number - 
//   * DenyReusingRecentPasswords - Number - 
//        
//   * WarnAboutPasswordExpiration - Number - 
//        
//   * InactivityPeriodBeforeDenyingAuthorization - Number - 
//        
//   * InactivityPeriodActivationDate - Date - 
//        
//
Function NewDescriptionOfLoginSettings() Export
	
	Settings = New Structure();
	// 
	Settings.Insert("PasswordMustMeetComplexityRequirements", False);
	Settings.Insert("MinPasswordLength", 0);
	Settings.Insert("ShouldBeExcludedFromBannedPasswordList", False);
	Settings.Insert("ActionUponLoginIfRequirementNotMet", "");
	// 
	Settings.Insert("MaxPasswordLifetime", 0);
	Settings.Insert("MinPasswordLifetime", 0);
	Settings.Insert("DenyReusingRecentPasswords", 0);
	Settings.Insert("WarnAboutPasswordExpiration", 0);
	// 
	Settings.Insert("InactivityPeriodBeforeDenyingAuthorization", 0);
	Settings.Insert("InactivityPeriodActivationDate", '00010101');
	
	Return Settings;
	
EndFunction

// 
// 
//
Procedure UpdateRegistrationSettingsForDataAccessEvents() Export
	
	Settings = RegistrationSettingsForDataAccessEvents();
	UsersInternal.CollapseSettingsForIdenticalTables(Settings);
	
	NewUse = New EventLogEventUse;
	NewUse.Use = ValueIsFilled(Settings);
	NewUse.UseDescription = Settings;
	
	OldUsage = GetEventLogEventUse("_$Access$_.Access");
	NewHashString = ValueToStringInternal(NewUse);
	OldCacheString = ValueToStringInternal(OldUsage);
	
	If NewHashString = OldCacheString Then
		Return;
	EndIf;
	
	Try
		SetEventLogEventUse("_$Access$_.Access", NewUse);
	Except
		UnfoundFields = New Array;
		UsersInternal.DeleteNonExistentFieldsFromAccessAccessEventSetting(
			NewUse.UseDescription, UnfoundFields);
		If Not ValueIsFilled(UnfoundFields) Then
			Raise;
		EndIf;
		Try
			SetEventLogEventUse("_$Access$_.Access", NewUse);
			IsTruncatedUsageDetailsEnabled = True;
		Except
			IsTruncatedUsageDetailsEnabled = False;
		EndTry;
		If IsTruncatedUsageDetailsEnabled Then
			EventName = NStr("en = 'Users.Error setting up Access.Access event';",
				Common.DefaultLanguageCode());
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The following non-existent fields or tables with fields
				           |were removed from the ""Access.Access"" event usage:
				           |%1';"),
				StrConcat(UnfoundFields, Chars.LF));
			If Common.SubsystemExists("StandardSubsystems.UserMonitoring") Then
				ModuleUserMonitoringInternal = Common.CommonModule("UserMonitoringInternal");
				ModuleUserMonitoringInternal.OnWriteErrorUpdatingRegistrationSettingsForDataAccessEvents(ErrorText);
			EndIf;
			WriteLogEvent(EventName, EventLogLevel.Error,,, ErrorText);
		Else
			Raise;
		EndIf;
	EndTry;
	
EndProcedure

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
// Returns:
//  Array of EventLogAccessEventUseDescription
//
Function RegistrationSettingsForDataAccessEvents() Export
	
	Settings = New Array;
	UsersOverridable.OnDefineRegistrationSettingsForDataAccessEvents(Settings);
	SSLSubsystemsIntegration.OnDefineRegistrationSettingsForDataAccessEvents(Settings);
	
	Return Settings;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// 
// 
// 
// Parameters:
//  User - CatalogRef.Users
//               - CatalogRef.ExternalUsers
//  StoredPasswordValue - String
//
Procedure AddUsedPassword(User, StoredPasswordValue) Export
	Return;
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Generates a short description of the error that the user will see,
// and can also record a detailed description of the error in the log.
//
// Parameters:
//  ErrorTemplate       - String - 
//                       
//
//  LoginName        - String -  name of the database user used for logging in.
//
//  IBUserID - Undefined
//                              - UUID
//
//  ErrorInfo - ErrorInfo
//
//  WriteToLog    - Boolean -  if True, a detailed description of the error is recorded
//                       in the log.
//
// Returns:
//  String - 
//
Function ErrorDescriptionOnWriteIBUser(ErrorTemplate,
                                              LoginName,
                                              IBUserID,
                                              ErrorInfo = Undefined,
                                              WriteToLog = True)
	
	If WriteToLog Then
		WriteLogEvent(
			NStr("en = 'Users.Error saving infobase user';",
			     Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			,
			,
			StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
				"""" + LoginName + """ (" + ?(ValueIsFilled(IBUserID),
					NStr("en = 'New';"), String(IBUserID)) + ")",
				?(TypeOf(ErrorInfo) = Type("ErrorInfo"),
					ErrorProcessing.DetailErrorDescription(ErrorInfo), String(ErrorInfo))));
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, """" + LoginName + """",
		?(TypeOf(ErrorInfo) = Type("ErrorInfo"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo), String(ErrorInfo)));
	
EndFunction

// 

// LongDesc
//
// Parameters:
//  User - Undefined
//               - InfoBaseUser
//               - CatalogRef.ExternalUsers
//               - CatalogRef.Users
// 
// Returns:
//  - Undefined
//  - FixedStructure
//  - Structure:
//    * IsCurrentIBUser - Boolean
//    * IBUser - Undefined
//                     - InfoBaseUser
//
Function CheckedIBUserProperties(User) Export
	
	CurrentIBUserProperties = UsersInternalCached.CurrentIBUserProperties1();
	IBUser = Undefined;
	
	If TypeOf(User) = Type("InfoBaseUser") Then
		IBUser = User;
		
	ElsIf User = Undefined Or User = AuthorizedUser() Then
		Return CurrentIBUserProperties;
	Else
		// 
		If ValueIsFilled(User) Then
			IBUserID = Common.ObjectAttributeValue(User, "IBUserID");
			If CurrentIBUserProperties.UUID = IBUserID Then
				Return CurrentIBUserProperties;
			EndIf;
			IBUser = InfoBaseUsers.FindByUUID(IBUserID);
		EndIf;
	EndIf;
	
	If IBUser = Undefined Then
		Return Undefined;
	EndIf;
	
	If CurrentIBUserProperties.UUID = IBUser.UUID Then
		Return CurrentIBUserProperties;
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("IsCurrentIBUser", False);
	Properties.Insert("IBUser", IBUser);
	
	Return Properties;
	
EndFunction

#EndRegion
