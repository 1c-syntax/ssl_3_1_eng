﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

///////////////////////////////////////////////////////////////////////////////
// 

// Called when sign-in.
//
// Parameters:
//  RegisterInLog - Boolean -  if True, then write the error to the log.
//
// Returns:
//  Structure:
//   * AuthorizationError      - String -  error text, if filled in.
//   * PasswordChangeRequired - Boolean -  if True, then the text of the error password has expired.
//   
Function AuthorizeTheCurrentUserWhenLoggingIn(RegisterInLog) Export
	
	Result = New Structure;
	Result.Insert("AuthorizationError", "");
	Result.Insert("PasswordChangeRequired", False);
	
	Try
		AuthorizationError = AuthenticateCurrentUser(True, RegisterInLog);
		
		If Not ValueIsFilled(AuthorizationError) Then
			DisableInactiveAndOverdueUsers(True, AuthorizationError, RegisterInLog);
		EndIf;
		
		If Not ValueIsFilled(AuthorizationError) Then
			CheckCanSignIn(AuthorizationError);
		EndIf;
		
		If Not ValueIsFilled(AuthorizationError) Then
			Result.PasswordChangeRequired = PasswordChangeRequired(AuthorizationError,
				True, RegisterInLog);
		EndIf;
	Except
		ErrorInfo = ErrorInfo();
		AuthorizationError = AuthorizationErrorBriefPresentationAfterRegisterInLog(
			ErrorInfo,, RegisterInLog);
		If RegisterInLog Then
			AuthorizationError = AuthorizationNotCompletedMessageTextWithLineBreak()
				+ ?(Users.IsFullUser(,, False),
					NStr("en = 'For more information, see the event log.';"),
					NStr("en = 'Please contact the administrator.';"));
		EndIf;
	EndTry;
	
	Result.AuthorizationError = AuthorizationError;
	
	Return Result;
	
EndFunction

// Called at the start of the system to check whether authorization can be performed and
// to cause the values of the current User and current external User session parameters to be filled in.
// Also called when entering the data area.
//
// Returns:
//  String - 
//           
//                             
//                             
//
Function AuthenticateCurrentUser(OnStart = False, RegisterInLog = False) Export
	
	StateBeforeCallAuthenticateCurrentUser(, True);
	
	If Not OnStart Then
		RefreshReusableValues();
	EndIf;
	
	SetPrivilegedMode(True);
	
	CurrentIBUser = InfoBaseUsers.CurrentUser();
	IsExternalUser = ValueIsFilled(Catalogs.ExternalUsers.FindByAttribute(
		"IBUserID", CurrentIBUser.UUID));
	
	ErrorText = CheckUserRights(CurrentIBUser,
		"OnStart", IsExternalUser, Not OnStart, RegisterInLog);
	If ValueIsFilled(ErrorText) Then
		Return ErrorText;
	EndIf;
	
	If IsBlankString(CurrentIBUser.Name) Then
		// 
		Try
			Values = CurrentUserSessionParameterValues();
		Except
			ErrorInfo = ErrorInfo();
			ErrorTemplate = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Couldn''t set session parameter for user ""%1"". Reason:
				           |%2
				           |
				           |Please contact the administrator.';"),
				"CurrentUser", "%1");
			Return AuthorizationErrorBriefPresentationAfterRegisterInLog(ErrorInfo,
				ErrorTemplate, RegisterInLog);
		EndTry;
		If TypeOf(Values) = Type("String") Then
			Return AuthorizationErrorBriefPresentationAfterRegisterInLog(Values, , RegisterInLog);
		EndIf;
		Return SessionParametersSettingResult(RegisterInLog);
	EndIf;
	
	FoundUser = Undefined;
	UserByIDExists(CurrentIBUser.UUID,, FoundUser);
	
	If Not ValueIsFilled(FoundUser) Then
		StandardProcessing = True;
		SSLSubsystemsIntegration.OnAuthorizeNewIBUser(CurrentIBUser, StandardProcessing);
		
		If Not StandardProcessing Then
			Return "";
		EndIf;
		UserByIDExists(CurrentIBUser.UUID,, FoundUser);
	EndIf;
	
	If ValueIsFilled(FoundUser) Then
		// 
		If OnStart And AdministratorRolesAvailable() Then
			SSLSubsystemsIntegration.OnCreateAdministrator(FoundUser,
				NStr("en = 'Administrator roles were detected during the user authorization.';"));
		EndIf;
		Return SessionParametersSettingResult(RegisterInLog);
	EndIf;
	
	// 
	IBUsers = InfoBaseUsers.GetUsers();
	
	If IBUsers.Count() > 1
	   And Not AdministratorRolesAvailable()
	   And Not AccessRight("Administration", Metadata, CurrentIBUser) Then
		
		// 
		Return AuthorizationErrorBriefPresentationAfterRegisterInLog(
			UserNotFoundInCatalogMessageText(CurrentIBUser.Name),
			, RegisterInLog);
	EndIf;
	
	// 
	If Not AdministratorRolesAvailable() Then
		Return AuthorizationErrorBriefPresentationAfterRegisterInLog(
			NStr("en = 'Cannot start a session on behalf of the user with ""Administration"" right
			           |because this user is not in the user list.
			           |
			           |To manage users and their rights, use the Users list
			           |and do not use Designer.';"),
			, RegisterInLog);
	EndIf;
	
	Try
		User = Users.CreateAdministrator(CurrentIBUser);
	Except
		ErrorInfo = ErrorInfo();
		Return AuthorizationErrorBriefPresentationAfterRegisterInLog(ErrorInfo,
			NStr("en = 'Cannot automatically register the administrator in the list. Reason:
			           |""%1"".
			           |
			           |Please use the Users list and do not use Designer
			           |to manage users and their rights.';"),
			RegisterInLog);
	EndTry;
	
	Comment =
		NStr("en = 'Session started on behalf of the user with ""Full access"" role
		           |that was not in the user list.
		           |The user is added to the list.
		           |
		           |To manage users and their rights, use the Users list
		           |and do not use Designer.';");
	
	SSLSubsystemsIntegration.AfterWriteAdministratorOnAuthorization(Comment);
	
	If Common.ObjectAttributeValue(User, "IsInternal") = True Then
		Comment =
			NStr("en = 'Session started on behalf of the user with ""Full access"" role
			           |that was not in the user list.
			           |The user is added to the list.';");
	EndIf;
	
	WriteLogEvent(
		NStr("en = 'Users.Administrator registered in Users catalog';",
		     Common.DefaultLanguageCode()),
		EventLogLevel.Warning,
		Metadata.Catalogs.Users,
		User,
		Comment);
	
	Return SessionParametersSettingResult(RegisterInLog);
	
EndFunction

// Parameters:
//  ShouldCheckAdministratorRolesAvailable - Boolean - 
//    
//  Disconnect - Boolean - 
// 
// Returns:
//  Boolean
//
Function StateBeforeCallAuthenticateCurrentUser(ShouldCheckAdministratorRolesAvailable = False,
			Disconnect = False) Export
	
	ParameterName = "StateBeforeCallAuthenticateCurrentUser";
	
	SetPrivilegedMode(True);
	
	If SessionParameters.ClientParametersAtServer.Get(ParameterName) <> True Then
		Return False;
	EndIf;
	
	If Not Disconnect Then
		Return Not ShouldCheckAdministratorRolesAvailable
			Or AdministratorRolesAvailable();
	EndIf;
	
	CurrentParameters = New Map(SessionParameters.ClientParametersAtServer);
	CurrentParameters.Delete("StateBeforeCallAuthenticateCurrentUser");
	SessionParameters.ClientParametersAtServer = New FixedMap(CurrentParameters);
	
	Return False;
	
EndFunction

// Determines that a non-standard method of installing roles for is users is used.
//
// Returns:
//  Boolean
//
Function CannotEditRoles() Export
	
	Return UsersInternalCached.Settings().EditRoles <> True;
	
EndFunction

// Checks that the external User type being defined
// contains references to authorization objects, not the String type.
//
// Returns:
//  Boolean
//
Function ExternalUsersEmbedded() Export
	
	Return UsersInternalCached.BlankRefsOfAuthorizationObjectTypes().Count() > 0;
	
EndFunction

// Sets the initial settings for the database user.
//
// Parameters:
//  UserName - String -  name of the database user to save settings for.
//  IsExternalUser - Boolean -  specify True if the is user corresponds to an external user
//                                    (an element of the external Users directory).
//
Procedure SetInitialSettings(Val UserName, IsExternalUser = False) Export
	
	ClientSettings = New ClientSettings;
	ClientSettings.ShowNavigationAndActionsPanels = False;
	ClientSettings.ShowSectionsPanel = True;
	ClientSettings.ApplicationFormsOpenningMode = ApplicationFormsOpenningMode.Tabs;
	ClientSettings.ClientApplicationInterfaceVariant = ClientApplicationInterfaceVariant.Taxi;
	
	InterfaceSettings = New CommandInterfaceSettings;
	InterfaceSettings.SectionsPanelRepresentation = SectionsPanelRepresentation.PictureAndText;
	
	TaxiSettings = New ClientApplicationInterfaceSettings;
	CompositionSettings1 = New ClientApplicationInterfaceContentSettings;
	LeftGroup2 = New ClientApplicationInterfaceContentSettingsGroup;
	
	LeftGroup2.Add(New ClientApplicationInterfaceContentSettingsItem("SectionsPanel"));
	CompositionSettings1.Left.Add(LeftGroup2);
	TaxiSettings.SetContent(CompositionSettings1);

	InitialSettings1 = New Structure;
	InitialSettings1.Insert("ClientSettings",    ClientSettings);
	InitialSettings1.Insert("InterfaceSettings", InterfaceSettings);
	InitialSettings1.Insert("TaxiSettings",      TaxiSettings);
	InitialSettings1.Insert("IsExternalUser", IsExternalUser);
	
	UsersOverridable.OnSetInitialSettings(InitialSettings1);
	
	If InitialSettings1.ClientSettings <> Undefined Then
		SystemSettingsStorage.Save("Common/ClientSettings", "",
			InitialSettings1.ClientSettings, , UserName);
	EndIf;
	
	If InitialSettings1.InterfaceSettings <> Undefined Then
		SystemSettingsStorage.Save("Common/SectionsPanel/CommandInterfaceSettings", "",
			InitialSettings1.InterfaceSettings, , UserName);
	EndIf;
		
	If InitialSettings1.TaxiSettings <> Undefined Then
		SystemSettingsStorage.Save("Common/ClientApplicationInterfaceSettings", "",
			InitialSettings1.TaxiSettings, , UserName);
	EndIf;
	
EndProcedure

// Returns the error text if the current user does not have either the basic rights role or the administrator roles.
// Logs an error in the log.
//
// Parameters:
//  RegisterInLog - Boolean
//
// Returns:
//  String
//
Function ErrorInsufficientRightsForAuthorization(RegisterInLog = True) Export
	
	// 
	If IsInRole(Metadata.Roles.FullAccess) Then
		Return "";
	EndIf;
	// 
	
	If Users.IsExternalUserSession() Then
		BasicAccessRoleName = Metadata.Roles.BasicAccessExternalUserSSL.Name;
	Else
		BasicAccessRoleName = Metadata.Roles.BasicAccessSSL.Name;
	EndIf;
	
	// 
	If IsInRole(BasicAccessRoleName) Then
		Return "";
	EndIf;
	// 
	
	Return AuthorizationErrorBriefPresentationAfterRegisterInLog(
		NStr("en = 'Insufficient rights to log in.
		           |
		           |Please contact the administrator.';"),
		, RegisterInLog);
	
EndFunction

// Only for calling from the procedure check
// Rightconnectlogicunachalarabotesystem of the common module standardsystem of the server Call.
//
// Returns:
//  String -  error text.
//
Function ErrorCheckingTheRightsOfTheCurrentUserWhenLoggingIn() Export
	
	Return CheckUserRights(InfoBaseUsers.CurrentUser(),
		"OnStart", Users.IsExternalUserSession(), False);
	
EndFunction

// Creates a user <not specified>.
//
// Returns:
//  CatalogRef.Users - 
// 
Function CreateUnspecifiedUser() Export
	
	UnspecifiedUserProperties = UnspecifiedUserProperties();
	
	If Common.RefExists(UnspecifiedUserProperties.StandardRef) Then
		
		Return UnspecifiedUserProperties.StandardRef;
		
	Else
		
		NewUser = Catalogs.Users.CreateItem();
		NewUser.IsInternal = True;
		NewUser.Description = UnspecifiedUserProperties.FullName;
		NewUser.SetNewObjectRef(UnspecifiedUserProperties.StandardRef);
		NewUser.DataExchange.Load = True;
		NewUser.Write();
		
		Return NewUser.Ref;
		
	EndIf;
	
EndFunction

// 
//
// Returns:
//  Structure:
//   * SelectedUsers - Array of CatalogRef.Users - 
//                               
//   * PickFormHeader - String - 
//   * PickingCompletionButtonTitle - String - 
//
Function NewParametersOfExtendedPickForm() Export
	
	Result = New Structure;
	Result.Insert("PickFormHeader", "");
	Result.Insert("SelectedUsers", New Array);
	Result.Insert("PickingCompletionButtonTitle", "");
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// For internal use only.
//
// Parameters:
//  Action - String -  Set up the interfacerleyprichtenyin the server,
//                      Set
//                      up Interfacerroleyform Creation, Set up interfacerroleyprizagruzkenfigurations,
//                      Fill in the roles,
//                      Update the tree of Kings,
//                      Update
//                      the list of roles, only the selected roles,
//                      Ostrovityanova,
//                      Grouping by subsystems.
//
//  Parameters - Structure:
//    * MainParameter - Undefined
//                       - Boolean
//                       - String
//                       - Array
//                       - Map
//
//    * Form - ClientApplicationForm:
//       ** ShowRoleSubsystems - Boolean
//       ** Roles - FormDataTree:
//            *** IsRole - Boolean
//            *** Name     - String
//            *** Synonym - String
//            *** IsUnavailableRole    - Boolean
//            *** IsNonExistingRole - Boolean
//            *** Check               - Boolean
//            *** PictureNumber         - Number
//       ** Items - FormAllItems:
//            *** RolesSelectAll            - FormButton
//            *** RolesClearAll                 - FormButton
//            *** RolesShowSelectedRolesOnly - FormButton
//            *** RolesShowRolesSubsystems     - FormButton
//
//    * RolesCollection - ValueTable:
//        ** Role - String
//    * RolesAssignment - String
//    * HideFullAccessRole - Boolean
//    * AdministrativeAccessChangeProhibition - Boolean
//
Procedure ProcessRolesInterface(Action, Parameters) Export
	
	If Action = "SetRolesReadOnly" Then
		SetRolesReadOnly(Parameters);
		
	ElsIf Action = "SetUpRoleInterfaceOnLoadSettings" Then
		SetUpRoleInterfaceOnLoadSettings(Parameters);
		
	ElsIf Action = "SetUpRoleInterfaceOnFormCreate" Then
		SetUpRoleInterfaceOnFormCreate(Parameters);
		
	ElsIf Action = "SetUpRoleInterfaceOnReadAtServer" Then
		SetUpRoleInterfaceOnReadAtServer(Parameters);
		
	ElsIf Action = "SelectedRolesOnly" Then
		SelectedRolesOnly(Parameters);
		
	ElsIf Action = "GroupBySubsystems" Then
		GroupBySubsystems(Parameters);
		
	ElsIf Action = "RefreshRolesTree" Then
		RefreshRolesTree(Parameters);
		
	ElsIf Action = "UpdateRoleComposition" Then
		UpdateRoleComposition(Parameters);
		
	ElsIf Action = "FillRoles" Then
		FillRoles(Parameters);
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Error in procedure %1.
			           |Invalid value of parameter ""Action"": ""%2"".';"),
			"UsersInternal.ProcessRolesInterface",
			Action);
		Raise ErrorText;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Returns the names and synonyms of the roles.
//
// Returns:
//  Structure:
//   * Array - FixedArray of String - 
//   * Map - FixedMap of KeyAndValue:
//      ** Key     - String -  role name.
//      ** Value - String - 
//   * Table - ValueStorage of ValueTable:
//      ** Name - String -  role name.
//
Function AllRoles() Export
	
	Return UsersInternalCached.AllRoles();
	
EndFunction

// Returns unavailable roles for separated users or external users
// based on the current user's rights and operating mode (local or service model).
//
// Parameters:
//  ForExternalUsers - Boolean -  if true, it means for external users.
//
// Returns:
//  Map of KeyAndValue:
//   * Key     - String -  role name.
//   * Value - Boolean -  Truth.
//
Function UnavailableRolesByUserType(ForExternalUsers) Export
	
	If ForExternalUsers Then
		UserRolesAssignment = "ForExternalUsers";
		
	ElsIf Not Common.DataSeparationEnabled()
	        And Users.IsFullUser(, True) Then
		
		// 
		// 
		UserRolesAssignment = "ForAdministrators";
	Else
		UserRolesAssignment = "ForUsers";
	EndIf;
	
	Return UsersInternalCached.UnavailableRoles(UserRolesAssignment);
	
EndFunction

// Returns user properties for an IB user with an empty name.
//
// Returns:
//  Structure:
//    * Ref - CatalogRef.Users - 
//                 
//             - Undefined - 
//
//    * StandardRef - CatalogRef.Users - 
//                 
//
//    * FullName - String - 
//                    
//
//    * FullNameForSearch - String - 
//                  
//                  
//
Function UnspecifiedUserProperties() Export
	
	SetPrivilegedMode(True);
	
	Properties = New Structure;
	Properties.Insert("Ref", Undefined);
	
	Properties.Insert("StandardRef", Catalogs.Users.GetRef(
		New UUID("aa00559e-ad84-4494-88fd-f0826edc46f0")));
	
	Properties.Insert("FullName", Users.UnspecifiedUserFullName());
	
	Properties.Insert("FullNameForSearch", "<" + NStr("en = 'Not specified';") + ">");
	
	// 
	Query = New Query;
	Query.SetParameter("Ref", Properties.StandardRef);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Ref = &Ref";
	
	BeginTransaction();
	Try
		If Query.Execute().IsEmpty() Then
			Query.SetParameter("FullName", Properties.FullNameForSearch);
			Query.Text =
			"SELECT TOP 1
			|	Users.Ref
			|FROM
			|	Catalog.Users AS Users
			|WHERE
			|	Users.Description = &FullName";
			Result = Query.Execute();
			
			If Not Result.IsEmpty() Then
				Selection = Result.Select();
				Selection.Next();
				Properties.Ref = Selection.Ref;
			EndIf;
		Else
			Properties.Ref = Properties.StandardRef;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Properties;
	
EndFunction

// Determines whether an element exists in the Users directory
// or the external Users directory by the unique user ID
// of the user.
//  This function is used to check whether a user is associated with only
// one element of the users and External users directories.
//
// Parameters:
//  UUID - UUID -  ID of the IB user.
//
//  RefToCurrent - CatalogRef.Users
//                   - CatalogRef.ExternalUsers - 
//                       
//                     
//
//  FoundUser - Undefined -  the user does not exist.
//                        - CatalogRef.Users
//                        - CatalogRef.ExternalUsers - 
//
//  ServiceUserID - Boolean
//                     False-check the user ID of AIB.
//                     True - check the service user ID.
//
// Returns:
//  Boolean
//
Function UserByIDExists(UUID,
                                               RefToCurrent = Undefined,
                                               FoundUser = Undefined,
                                               ServiceUserID = False) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("RefToCurrent", RefToCurrent);
	Query.SetParameter("UUID", UUID);
	Query.Text = 
	"SELECT
	|	Users.Ref AS User
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.IBUserID = &UUID
	|	AND Users.Ref <> &RefToCurrent
	|
	|UNION ALL
	|
	|SELECT
	|	ExternalUsers.Ref
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.IBUserID = &UUID
	|	AND ExternalUsers.Ref <> &RefToCurrent";
	
	Result = False;
	FoundUser = Undefined;
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		FoundUser = Selection.User;
		Result = True;
		Users.FindAmbiguousIBUsers(Undefined, UUID);
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  IBUserID - UUID
//
Function InfobaseUserByID(IBUserID) Export
	
	If TypeOf(IBUserID) <> Type("UUID") Then
		Return Undefined;
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionWithoutSeparators = ModuleSaaSOperations.SessionWithoutSeparators();
	Else
		SessionWithoutSeparators = True;
	EndIf;
	
	If Common.DataSeparationEnabled()
	   And SessionWithoutSeparators
	   And Common.SeparatedDataUsageAvailable()
	   And IBUserID = InfoBaseUsers.CurrentUser().UUID Then
		
		IBUser = InfoBaseUsers.CurrentUser();
	Else
		IBUser = InfoBaseUsers.FindByUUID(IBUserID);
	EndIf;
	
	Return IBUser;
	
EndFunction

// For internal use only.
//
// Parameters:
//  Form - ClientApplicationForm
//  AddUsers - Boolean
//  ExternalUsersOnly - Boolean
//
Procedure UpdateAssignmentOnCreateAtServer(Form, AddUsers = True, ExternalUsersOnly = False) Export
	
	Purpose = Form.Object.Purpose;
	
	If Not ExternalUsers.UseExternalUsers() Then
		Purpose.Clear();
		NewRow = Purpose.Add();
		Form.Items.SelectPurpose.Parent.Visible = False;
		NewRow.UsersType = Catalogs.Users.EmptyRef();
	EndIf;
	
	If AddUsers And Purpose.Count() = 0 Then
		If ExternalUsersOnly Then
			BlankRefs = UsersInternalCached.BlankRefsOfAuthorizationObjectTypes();
			For Each EmptyRef In BlankRefs Do
				NewRow = Purpose.Add();
				NewRow.UsersType = EmptyRef;
			EndDo;
		Else
			NewRow = Purpose.Add();
			NewRow.UsersType = Catalogs.Users.EmptyRef();
		EndIf;
	EndIf;
	
	If Purpose.Count() <> 0 Then
		PresentationsArray = New Array;
		IndexOf = Purpose.Count() - 1;
		While IndexOf >= 0 Do
			UsersType = Purpose.Get(IndexOf).UsersType;
			If UsersType = Undefined Then
				Purpose.Delete(IndexOf);
			Else
				PresentationsArray.Add(UsersType.Metadata().Synonym);
			EndIf;
			IndexOf = IndexOf - 1;
		EndDo;
		Form.Items.SelectPurpose.Title = StrConcat(PresentationsArray, ", ");
	EndIf;
	
EndProcedure

// Calls the event before writing the IB User, checks the rights based
// on the data separation mode, and writes the specified IB user.
//
// Parameters:
//  IBUser  - InfoBaseUser -  the object that you want to record.
//  IsExternalUser - Boolean -  specify True if the is user corresponds to an external user
//                                    (an element of the external Users directory).
//  User - Undefined - 
//               - CatalogRef.Users
//               - CatalogRef.ExternalUsers
//
//  ShouldNotifyServiceManager - Boolean
//
Procedure WriteInfobaseUser(IBUser, IsExternalUser = False,
			User = Undefined, Val ShouldNotifyServiceManager = True) Export
	
	SSLSubsystemsIntegration.BeforeWriteIBUser(IBUser);
	
	ShouldNotifyServiceManager = ShouldNotifyServiceManager
		And Common.DataSeparationEnabled()
		And Common.SubsystemExists("StandardSubsystems.SaaSOperations.UsersSaaS");
	
	IsUsersCatalogsUpdate = IBUser.UUID
		= SessionParameters.UsersCatalogsUpdate.Get("IBUserID");
	
	If ShouldNotifyServiceManager And Not IsUsersCatalogsUpdate Then
		InfobaseOldUser = InfoBaseUsers.FindByUUID(
			IBUser.UUID);
	EndIf;
	
	CheckUserRights(IBUser, "BeforeWrite", IsExternalUser);
	InfobaseUpdateInternal.SetShowDetailsToNewUserFlag(IBUser.Name);
	IBUser.Write();
	
	If Not IsUsersCatalogsUpdate Then
		
		UpdatedInfobaseUser = InfoBaseUsers.FindByUUID(
			IBUser.UUID);
		If UpdatedInfobaseUser <> Undefined Then
			IBUser = UpdatedInfobaseUser;
		EndIf;
		
		If User = Undefined Then
			User = Users.FindByID(IBUser.UUID);
		EndIf;
		If User <> Undefined Then
			InformationRegisters.UsersInfo.UpdateUserInfoRecords(User,
				Undefined, IBUser);
			If ShouldNotifyServiceManager Then
				ModuleUsersInternalSaaS = Common.CommonModule("UsersInternalSaaS");
				ModuleUsersInternalSaaS.NotifyAppStartupModified(User,
					IBUser, InfobaseOldUser);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Checks whether the role assignment is filled in correctly, as well as whether the rights in the assigned roles are correct.
//
// Parameters:
//  RolesAssignment - Undefined
//  CheckEverything - Boolean
//  ErrorList - Undefined
//               - ValueList - :
//                   * Value      - String -  role name.
//                                   - Undefined - 
//                   * Presentation - String -  error text.
//
Procedure CheckRoleAssignment(RolesAssignment = Undefined, CheckEverything = False, ErrorList = Undefined) Export
	
	If RolesAssignment = Undefined Then
		RolesAssignment = UsersInternalCached.RolesAssignment();
	EndIf;
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Error in procedure %1 of common module %2.';"),
		"OnDefineRoleAssignment",
		"UsersOverridable");
	
	ErrorText = "";
	
	Purpose = RolesAssignment();
	For Each RolesAssignmentDetails In RolesAssignment Do
		Roles = New Map;
		For Each KeyAndValue In RolesAssignmentDetails.Value Do
			Role = Metadata.Roles.Find(KeyAndValue.Key);
			If Role = Undefined Then
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'Role ""%1""
						           | specified in assignment %2 does not exist in metadata.';"),
						KeyAndValue.Key, RolesAssignmentDetails.Key);
				If ErrorList = Undefined Then
					ErrorText = ErrorText + Chars.LF + Chars.LF + ErrorDescription;
				Else
					ErrorList.Add(Undefined, ErrorDescription);
				EndIf;
				Continue;
			EndIf;
			Roles.Insert(Role, True);
			For Each AssignmentDetails In Purpose Do
				CurrentRoles = AssignmentDetails.Value; // Map
				If CurrentRoles.Get(Role) = Undefined Then
					Continue;
				EndIf;
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Role ""%1"" is specified in multiple assignments:
					           |%2 and %3.';"),
					Role.Name, RolesAssignmentDetails.Key, AssignmentDetails.Key);
				If ErrorList = Undefined Then
					ErrorText = ErrorText + Chars.LF + Chars.LF + ErrorDescription;
				Else
					ErrorList.Add(Role, ErrorDescription);
				EndIf;
			EndDo;
		EndDo;
		Purpose.Insert(RolesAssignmentDetails.Key, Roles);
	EndDo;
	
	// 
	UnavailableRights = New Array;
	UnavailableRights.Add("Administration");
	UnavailableRights.Add("ConfigurationExtensionsAdministration");
	UnavailableRights.Add("UpdateDataBaseConfiguration");
	UnavailableRights.Add("DataAdministration");
	
	CheckRoleRightsList(UnavailableRights, Purpose.ForExternalUsersOnly, ErrorText,
		NStr("en = 'Errors were found while checking external user roles:';"), ErrorList);
	
	CheckRoleRightsList(UnavailableRights, Purpose.BothForUsersAndExternalUsers, ErrorText,
		NStr("en = 'Errors were found while checking both user and external user roles:';"), ErrorList);
	
	// 
	If Common.DataSeparationEnabled() Or CheckEverything Then
		Roles = New Map;
		For Each Role In Metadata.Roles Do
			If Purpose.ForSystemAdministratorsOnly.Get(Role) <> Undefined
			 Or Purpose.ForSystemUsersOnly.Get(Role) <> Undefined Then
				Continue;
			EndIf;
			Roles.Insert(Role, True);
		EndDo;
		UnavailableRights = New Array;
		UnavailableRights.Add("Administration");
		UnavailableRights.Add("ConfigurationExtensionsAdministration");
		UnavailableRights.Add("UpdateDataBaseConfiguration");
		UnavailableRights.Add("ThickClient");
		UnavailableRights.Add("ExternalConnection");
		UnavailableRights.Add("Automation");
		UnavailableRights.Add("InteractiveOpenExtDataProcessors");
		UnavailableRights.Add("InteractiveOpenExtReports");
		UnavailableRights.Add("AllFunctionsMode");
		
		Shared_Data = Shared_Data();
		CheckRoleRightsList(UnavailableRights, Roles, ErrorText,
			NStr("en = 'Errors were found while checking application user roles:';"), ErrorList, Shared_Data);
	EndIf;
	If Not Common.DataSeparationEnabled() Or CheckEverything Then
		Roles = New Map;
		For Each Role In Metadata.Roles Do
			If Purpose.ForSystemAdministratorsOnly.Get(Role) <> Undefined
			 Or Purpose.ForExternalUsersOnly.Get(Role) <> Undefined Then
				Continue;
			EndIf;
			Roles.Insert(Role, True);
		EndDo;
		UnavailableRights = New Array;
		UnavailableRights.Add("Administration");
		UnavailableRights.Add("ConfigurationExtensionsAdministration");
		UnavailableRights.Add("UpdateDataBaseConfiguration");
		
		CheckRoleRightsList(UnavailableRights, Roles, ErrorText,
			NStr("en = 'Errors were found while checking user roles:';"), ErrorList);
		
		CheckRoleRightsList(UnavailableRights, Purpose.BothForUsersAndExternalUsers, ErrorText,
			NStr("en = 'Errors were found while checking both user and external user roles:';"), ErrorList);
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		Raise ErrorTitle + ErrorText;
	EndIf;
	
EndProcedure

// Includes the receiver user in the source user's user groups.
// Called from the form handler when writing to the Server.
//
Procedure CopyUserGroups(Source, Receiver) Export
	
	ExternalUser = (TypeOf(Source) = Type("CatalogRef.ExternalUsers"));
	
	Query = New Query;
	Block = New DataLock;
	
	If ExternalUser Then
		LockItem = Block.Add("Catalog.ExternalUsersGroups");
		Query.Text = 
			"SELECT
			|	UserGroupsComposition.Ref AS UsersGroup
			|FROM
			|	Catalog.ExternalUsersGroups.Content AS UserGroupsComposition
			|WHERE
			|	UserGroupsComposition.ExternalUser = &User";
	Else
		LockItem = Block.Add("Catalog.UserGroups");
		Query.Text = 
			"SELECT
			|	UserGroupsComposition.Ref AS UsersGroup
			|FROM
			|	Catalog.UserGroups.Content AS UserGroupsComposition
			|WHERE
			|	UserGroupsComposition.User = &User";
	EndIf;
	Query.SetParameter("User", Source);
	Query.SetParameter("Receiver", Receiver);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	LockItem.DataSource = QueryResult;
	LockItem.UseFromDataSource("Ref", "UsersGroup");
	
	BeginTransaction();
	Try
		Block.Lock();
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			UsersGroupObject = Selection.UsersGroup.GetObject(); // CatalogObject.UserGroups, CatalogObject.ExternalUsersGroups
			Filter = New Structure;
			Filter.Insert(?(ExternalUser, "ExternalUser", "User"), Receiver);
			FoundRows = UsersGroupObject.Content.FindRows(Filter);
			If FoundRows.Count() <> 0 Then
				Continue;
			EndIf;
			
			String = UsersGroupObject.Content.Add();
			If ExternalUser Then
				String.ExternalUser = Receiver;
			Else
				String.User = Receiver;
			EndIf;
			
			UsersGroupObject.Write();
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns a description of the user's contact information.
// For example, your email address and phone number.
//
// Parameters:
//   User - CatalogRef.Users
//
// Returns:
//   Structure:
//   * Description - String
//   * IBUserID - String
//   * Photo - BinaryData
// 	             - Undefined
//   * Invalid - String
//   * DeletionMark - String
//   * Phone - String
//   * Email - String
//   * Department - Undefined
// 	                - DefinedType.Department
//
Function UserDetails(User) Export

	Result = New Structure;
	Result.Insert("Description", "");
	Result.Insert("IBUserID", "");
	Result.Insert("Photo");
	Result.Insert("Department");
	Result.Insert("Invalid", True);
	Result.Insert("DeletionMark", True);
	Result.Insert("Phone", "");
	Result.Insert("Email", "");
	
	UserProperties = ?(TypeOf(User) = Type("CatalogObject.Users"),
		User,
		Common.ObjectAttributesValues(User,
			" Description,
			| IBUserID,
			| Photo,
			| DeletionMark,
			| Invalid,
			| Department"));
	FillPropertyValues(Result, UserProperties);
	Result.Photo = ?(UserProperties.Photo = Undefined, Undefined, UserProperties.Photo.Get());
	
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManager = Common.CommonModule("ContactsManager");
		ContactInformationValue = ModuleContactsManager.ObjectContactInformation(User,,,False);
		
		PhoneKind = ModuleContactsManager.ContactInformationKindByName("UserPhone");
		MailAddrKind = ModuleContactsManager.ContactInformationKindByName("UserEmail");
		For Each Contact In ContactInformationValue Do
			
			If Contact.Kind = PhoneKind And Not ValueIsFilled(Result.Phone) Then
				
				Result.Phone = Contact.Presentation;
			ElsIf Contact.Kind = MailAddrKind And Not ValueIsFilled(Result.Email) Then
				
				Result.Email = Contact.Presentation;
			EndIf;
			
		EndDo;
	EndIf;
	
	If Not ValueIsFilled(Result.IBUserID) Then
		If TypeOf(User) = Type("CatalogObject.Users") Then
			UserRef = User.Ref;
		EndIf;
		If UserRef = Users.UnspecifiedUserRef() Then
			Result.IBUserID = InfoBaseUsers.FindByName("").UUID;
		EndIf;
	EndIf;
	
	Return Result;

EndFunction

// Returns:
//  Boolean
//
Function AreCurrentUserRolesReduced() Export
	
	SetPrivilegedMode(True);
	
	InfobaseOldUser = InfoBaseUsers.CurrentUser();
	InfobaseNewUser = InfoBaseUsers.FindByUUID(
		InfobaseOldUser.UUID);
	
	If InfobaseNewUser = Undefined Then
		Return True;
	EndIf;
	
	Return RolesReduced(InfobaseOldUser, InfobaseNewUser);
	
EndFunction

// Parameters:
//  List - DynamicList
//
Procedure SetUpFieldDynamicListPicNum(List) Export
	
	RestrictUsageOfDynamicListFieldToFill(List, "PictureNumber");
	
EndProcedure

// Parameters:
//  TagName - String
//  Settings - DataCompositionSettings
//  Rows - DynamicListRows
//
Procedure DynamicListOnGetDataAtServer(TagName, Settings, Rows) Export
	
	If Rows.Count() = 0 Then
		Return;
	EndIf;
	
	For Each KeyAndValue In Rows Do
		If Not KeyAndValue.Value.Data.Property("PictureNumber")
		 Or TypeOf(KeyAndValue.Key) <> Type("CatalogRef.Users")
		   And TypeOf(KeyAndValue.Key) <> Type("CatalogRef.ExternalUsers") Then
			Return;
		EndIf;
		Break;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("Users", Rows.GetKeys());
	Query.Text =
	"SELECT
	|	UsersInfo.User AS User,
	|	UsersInfo.NumberOfStatePicture - 1 AS PictureNumber
	|FROM
	|	InformationRegister.UsersInfo AS UsersInfo
	|WHERE
	|	UsersInfo.User IN (&Users)";
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		String = Rows.Get(Selection.User);
		String.Data.PictureNumber = Selection.PictureNumber;
	EndDo;
	
EndProcedure

// Parameters:
//  Settings - Array of EventLogAccessEventUseDescription
//
Procedure CollapseSettingsForIdenticalTables(Settings) Export
	
	AddedSettings = New Map;
	Result = New Array;
	
	For Each Setting In Settings Do
		LongDesc = AddedSettings.Get(Upper(Setting.Object));
		If LongDesc = Undefined Then
			LongDesc = New Structure("Setting, ForSearch", Setting);
			AddedSettings.Insert(Upper(Setting.Object), LongDesc);
			Result.Add(Setting);
			Continue;
		EndIf;
		If LongDesc.ForSearch = Undefined Then
			DetailsForSearch = New Structure;
			DetailsForSearch.Insert("AccessFields", New Map);
			DetailsForSearch.Insert("RegistrationFields", New Map);
			For Each AccessField In LongDesc.Setting.AccessFields Do
				DetailsForSearch.AccessFields.Insert(Upper(AccessField), True);
			EndDo;
			For Each RegistrationField In LongDesc.Setting.RegistrationFields Do
				DetailsForSearch.RegistrationFields.Insert(Upper(RegistrationField), True);
			EndDo;
			LongDesc.ForSearch = DetailsForSearch;
		Else
			DetailsForSearch = LongDesc.ForSearch;
		EndIf;
		For Each AccessField In Setting.AccessFields Do
			If DetailsForSearch.AccessFields.Get(Upper(AccessField)) <> Undefined Then
				Continue;
			EndIf;
			DetailsForSearch.AccessFields.Insert(Upper(AccessField), True);
			LongDesc.Setting.AccessFields.Add(AccessField);
		EndDo;
		For Each RegistrationField In Setting.RegistrationFields Do
			If DetailsForSearch.RegistrationFields.Get(Upper(RegistrationField)) <> Undefined Then
				Continue;
			EndIf;
			DetailsForSearch.RegistrationFields.Insert(Upper(RegistrationField), True);
			LongDesc.Setting.RegistrationFields.Add(RegistrationField);
		EndDo;
	EndDo;
	
	Settings = Result;
	
EndProcedure

// Parameters:
//  Settings - Array of EventLogAccessEventUseDescription
//  UnfoundFields - Array - 
//
Procedure DeleteNonExistentFieldsFromAccessAccessEventSetting(Settings, UnfoundFields) Export
	
	Result = New Array;
	UnfoundFields = New Array;
	AddedFields = New Map;
	
	For Each Setting In Settings Do
		TableFields = UsersInternalCached.TableFields(Setting.Object);
		AvailableFields = ?(TableFields = Undefined, Undefined, TableFields.AllFields);
		
		AccessFields = New Array;
		For Each Field In Setting.AccessFields Do
			If TypeOf(Field) = Type("Array") Then
				NestedFields = New Array;
				For Each NestedField In Field Do
					AddFieldWithCheck(NestedFields,
						NestedField, AvailableFields, UnfoundFields, AddedFields, Setting.Object);
				EndDo;
				If ValueIsFilled(NestedFields) Then
					AccessFields.Add(NestedFields);
				EndIf;
			Else
				AddFieldWithCheck(AccessFields,
					Field, AvailableFields, UnfoundFields, AddedFields, Setting.Object);
			EndIf;
		EndDo;
		
		RegistrationFields = New Array;
		For Each Field In Setting.RegistrationFields Do
			AddFieldWithCheck(RegistrationFields,
				Field, AvailableFields, UnfoundFields, AddedFields, Setting.Object);
		EndDo;
		
		If ValueIsFilled(AccessFields)
		 Or ValueIsFilled(RegistrationFields) Then
			
			NewSetting = New EventLogAccessEventUseDescription;
			NewSetting.Object = Setting.Object;
			NewSetting.AccessFields = AccessFields;
			NewSetting.RegistrationFields = RegistrationFields;
			Result.Add(NewSetting);
		EndIf;
	EndDo;
	
	Settings = Result;
	
EndProcedure

// 
// 
// 
// 
// 
// 
// Parameters:
//  EventSetting - EventLogAccessEventUseDescription
//
// Returns:
//   See TableFields
//
Function TableFieldsConsideringAccessEventSettings(EventSetting) Export
	
	TableFields = UsersInternalCached.TableFields(EventSetting.Object);
	
	UnfoundFields = New Array;
	DeleteNonExistentFieldsFromAccessAccessEventSetting(
		CommonClientServer.ValueInArray(EventSetting), UnfoundFields);
	
	If Not ValueIsFilled(UnfoundFields) Then
		Return TableFields;
	EndIf;
	
	If TableFields = Undefined Then
		TableFields = New Structure;
		TableFields.Insert("Collections", New Array);
		TableFields.Insert("AllFields", New Map);
	Else
		TableFields = TableFields(EventSetting.Object);
	EndIf;
	
	Tables = New Map;
	
	IndexOfFirstTableCollection = 0;
	For Each Collection In TableFields.Collections Do
		If Collection.Tables = Undefined Then
			Continue;
		EndIf;
		For Each TableDetails In Collection.Tables Do
			If Not ValueIsFilled(Tables) Then
				IndexOfFirstTableCollection = TableFields.Collections.Find(Collection);
			EndIf;
			Tables.Insert(Lower(TableDetails.Name),
				New Structure("TableDetails, FieldIndex", TableDetails, 0));
		EndDo;
	EndDo;
	
	FieldsCollection = New Structure;
	FieldsCollection.Insert("Name", "");
	FieldsCollection.Insert("Fields", New Array);
	FieldsCollection.Insert("Tables");
	
	TablesCollection = New Structure;
	TablesCollection.Insert("Name", "");
	TablesCollection.Insert("Fields");
	TablesCollection.Insert("Tables", New Array);
	
	BeginningOfFieldName = StrLen(EventSetting.Object) + 1;
	For Each UnfoundField In UnfoundFields Do
		UnfoundField = StrReplace(UnfoundField, "<<?>>", "");
		UnfoundField = Mid(UnfoundField, BeginningOfFieldName);
		NameParts = StrSplit(UnfoundField, ".", False);
		If NameParts.Count() > 1 Then
			TableName = NameParts[0];
			FieldName = NameParts[1];
			TableProperties = Tables.Get(Lower(TableName));
			If TableProperties = Undefined Then
				TableDetails = TableNewDetails();
				TableDetails.Name = TableName;
				TableDetails.Presentation = TableName;
				TablesCollection.Tables.Add(TableDetails);
				TableProperties = New Structure("TableDetails, FieldIndex", TableDetails, 0);
				Tables.Insert(Lower(TableName), TableProperties);
			EndIf;
			Fields = TableProperties.TableDetails.Fields;
			FieldIndex = TableProperties.FieldIndex;
		Else
			FieldName = NameParts[0];
			Fields = FieldsCollection.Fields;
			FieldIndex = Fields.Count();
		EndIf;
		FieldDetails = NewFieldDescription();
		FieldDetails.Name = FieldName;
		FieldDetails.Presentation = FieldName;
		Fields.Insert(FieldIndex, FieldDetails);
	EndDo;
	
	If ValueIsFilled(TablesCollection.Tables) Then
		TableFields.Collections.Insert(IndexOfFirstTableCollection, TablesCollection);
	EndIf;
	
	If ValueIsFilled(FieldsCollection.Fields) Then
		TableFields.Collections.Insert(0, FieldsCollection);
	EndIf;
	
	Return TableFields;
	
EndFunction

// Returns:
//  String
//
Function EventNameChangeAdditionalForLogging() Export
	
	Return NStr("en = 'Users.Change (additional)';",
		Common.DefaultLanguageCode());
	
EndFunction

// Returns:
//  String
//
Function NameOfLogEventUserGroupsMembersChanged() Export
	
	Return NStr("en = 'Users.Change user group membership';",
		Common.DefaultLanguageCode());
	
EndFunction

// Returns:
//  String
//
Function NameOfLogEventExternalUserGroupsMembersChanged() Export
	
	Return NStr("en = 'Users.Change external user group membership';",
		Common.DefaultLanguageCode());
	
EndFunction

// 
//
// Parameters:
//  Ref - Null - 
//         - Undefined - 
//         - AnyRef - 
//
// Returns:
//  
//
Function SerializedRef(Ref) Export
	
	If Ref = Null Or Ref = Undefined Then
		Return Ref;
	EndIf;
	
	Return ValueToStringInternal(Ref);
	
EndFunction

// 
//
// Parameters:
//  Ref - Null - 
//         - Undefined - 
//         - AnyRef - 
//
// Returns:
//  String
//
Function RepresentationOfTheReference(Ref) Export
	
	If Ref = Null Or Ref = Undefined Then
		Return "";
	EndIf;
	
	Result = String(Ref);
	
	If Not ValueIsFilled(Result) Then
		Result = "<" + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Empty reference: ""%1""';", Common.DefaultLanguageCode()), TypeOf(Ref)) + ">";
	EndIf;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Returns the reference of the old object or the reference of the new object.
//
// Parameters:
//  Object   - CatalogObject.Users
//           - CatalogObject.ExternalUsers
//
//  IsNew - Boolean -  the return value.
//
// Returns:
//  CatalogRef.Users
//  
//
Function ObjectRef2(Val Object, IsNew = Undefined) Export
	
	Ref = Object.Ref;
	IsNew = Not ValueIsFilled(Ref);
	
	If IsNew Then
		Ref = Object.GetNewObjectRef();
		
		If Not ValueIsFilled(Ref) Then
			
			Manager = Common.ObjectManagerByRef(Object.Ref);
			Ref = Manager.GetRef();
			Object.SetNewObjectRef(Ref);
		EndIf;
	EndIf;
	
	Return Ref;
	
EndFunction

// Returns:
//  Boolean
//
Function IsSettings8_3_26Available() Export
	
	Properties = New Structure("PasswordHashAlgorithmType", Null);
	FillPropertyValues(Properties, InfoBaseUsers.CurrentUser());
	
	Return Properties.PasswordHashAlgorithmType <> Null;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// 
// 
// 
//
// Parameters:
//  ParameterName - String
//  Value - 
//  DCSettings - DataCompositionSettings
//  UserSettings - DataCompositionUserSettings
//
Procedure SetFilterOnParameter(ParameterName, Value, DCSettings, UserSettings) Export
	
	DataParameter = DCSettings.DataParameters.Items.Find(ParameterName);
	If DataParameter = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(DataParameter.UserSettingID) Then
		For Each CurrentItem In UserSettings.Items Do
			If CurrentItem.UserSettingID
					= DataParameter.UserSettingID Then
				DataParameter = CurrentItem;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	NewValue = Value;
	
	If TypeOf(Value) = Type("ValueList")
	   And Value.Count() = 1 Then
		
		NewValue = Value[0].Value;
	EndIf;
	
	DataParameter.Value = NewValue;
	DataParameter.Use = True;
	
EndProcedure

// 
// 
//
// Parameters:
//  FieldName - String
//  Value - 
//  DCSettings - DataCompositionSettings
//  UserSettings - DataCompositionUserSettings
//  InHierarchy - Boolean - 
//                
//
Procedure SetFilterOnField(FieldName, Value, DCSettings, UserSettings, InHierarchy = False) Export
	
	Field = New DataCompositionField(FieldName);
	SettingID = Undefined;
	
	For Each FilterElement In DCSettings.Filter.Items Do
		If FilterElement.LeftValue = Field Then
			SettingID = FilterElement.UserSettingID;
			Break;
		EndIf;
	EndDo;
	
	If SettingID = Undefined Then
		Return;
	EndIf;
	
	Item = Undefined;
	For Each CurrentItem In UserSettings.Items Do
		If CurrentItem.UserSettingID = SettingID Then
			Item = CurrentItem;
			Break;
		EndIf;
	EndDo;
	
	If Item = Undefined Then
		Return;
	EndIf;
	
	NewValue = Value;
	NewComparisonType = ?(InHierarchy,
		DataCompositionComparisonType.InHierarchy,
		DataCompositionComparisonType.Equal);
	
	If TypeOf(Value) = Type("ValueList") Then
		If Value.Count() = 1 Then
			NewValue = Value[0].Value;
		Else
			NewComparisonType = ?(InHierarchy,
				DataCompositionComparisonType.InListByHierarchy,
				DataCompositionComparisonType.InList);
		EndIf;
	EndIf;
	
	Item.ComparisonType = NewComparisonType;
	Item.RightValue = NewValue;
	Item.Use = True;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
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
//  RefsKind - String - 
//               
// 
//  RefsToAdd - Arbitrary - 
//                    - Array of Arbitrary
//                    - Null - 
//
Procedure RegisterRefs(RefsKind, Val RefsToAdd) Export
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	RefsKindProperties = UsersInternalCached.RefKindsProperties().Get(RefsKind);
	If RefsKindProperties = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'In procedure ""%3"", parameter ""%2"" has invalid value: %1.';"),
			RefsKind, "RefsKind", "RegisterRefs");
		Raise ErrorText;
	EndIf;
	
	References = StandardSubsystemsServer.ExtensionParameter(
		RefsKindProperties.ParameterNameExtensionsOperation, True);
	
	If TypeOf(References) <> Type("Array") Then
		References = New Array;
	EndIf;
	
	HasChanges = False;
	If RefsToAdd = Null Then
		If References.Count() > 0 Then
			References = New Array;
			HasChanges = True;
		EndIf;
		
	ElsIf References.Count() = 1
	        And References[0] = Undefined Then
		
		Return; // 
	Else
		If TypeOf(RefsToAdd) <> Type("Array") Then
			RefsToAdd = CommonClientServer.ValueInArray(RefsToAdd);
		EndIf;
		For Each RefToAdd In RefsToAdd Do
			If References.Find(RefToAdd) <> Undefined Then
				Continue;
			EndIf;
			References.Add(RefToAdd);
			HasChanges = True;
		EndDo;
		If References.Count() > 300 Then
			References = New Array;
			References.Add(Undefined);
			HasChanges = True;
		EndIf;
	EndIf;
	
	If Not HasChanges Then
		Return;
	EndIf;
	
	StandardSubsystemsServer.SetExtensionParameter(
		RefsKindProperties.ParameterNameExtensionsOperation, References, True);
	
EndProcedure

// 
// 
//
// 
//
// Parameters:
//  RefsKind - String - 
//               
//
// Returns:
//  Array of Arbitrary - 
//                           
//                           
//
Function RegisteredRefs(RefsKind) Export
	
	If Common.DataSeparationEnabled() Then
		Return New Array;
	EndIf;
	
	RefsKindProperties = UsersInternalCached.RefKindsProperties().Get(RefsKind);
	If RefsKindProperties = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'In function ""%3"", parameter ""%2"" has invalid value: %1.';"),
			RefsKind, "RefsKind", "RegisteredRefs");
		Raise ErrorText;
	EndIf;
	
	References = StandardSubsystemsServer.ExtensionParameter(
		RefsKindProperties.ParameterNameExtensionsOperation, True);
	
	If TypeOf(References) <> Type("Array") Then
		References = New Array;
	EndIf;
	
	If References.Count() = 1
	   And References[0] = Undefined Then
		
		Return References;
	EndIf;
	
	CheckedRefs = New Array;
	For Each Ref In References Do
		If RefsKindProperties.AllowedTypes.ContainsType(TypeOf(Ref)) Then
			CheckedRefs.Add(Ref);
		EndIf;
	EndDo;
	
	Return CheckedRefs;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters, Cancel, IsCallBeforeStart) Export
	
	If Not IsCallBeforeStart Then
		SecurityWarningKey = SecurityWarningKeyOnStart();
		If ValueIsFilled(SecurityWarningKey) Then
			Parameters.Insert("SecurityWarningKey", SecurityWarningKey);
		EndIf;
		Return;
	EndIf;
	
	If Parameters.RetrievedClientParameters.Property("AuthenticationDone") Then
		AuthorizationResult = Parameters.RetrievedClientParameters.AuthenticationDone;
	Else
		AuthorizationResult = New Structure;
		
		Result = AuthorizeTheCurrentUserWhenLoggingIn(True);
		
		If ValueIsFilled(Result.AuthorizationError) Then
			AuthorizationResult.Insert("AuthorizationError", Result.AuthorizationError);
			
		Else
			If Result.PasswordChangeRequired Then
				AuthorizationResult.Insert("PasswordChangeRequired");
				StandardSubsystemsServerCall.HideDesktopOnStart();
			EndIf;
			
			If Not Common.DataSeparationEnabled()
			   And Users.IsFullUser(, True, False)
			   And InformationRegisters.UsersInfo.AskAboutDisablingOpenIDConnect() Then
			
				AuthorizationResult.Insert("AskAboutDisablingOpenIDConnect");
			EndIf;
			
			If Common.SeparatedDataUsageAvailable() Then
				IBUser = InfoBaseUsers.CurrentUser();
				IBUserID = IBUser.UUID;
				BegOfDay = BegOfDay(CurrentSessionDate());
				IBUsersIDs = CommonClientServer.ValueInArray(IBUserID);
				SetPrivilegedMode(True);
				Balance = UsersRemainingValidityPeriods(IBUsersIDs, BegOfDay);
				RemainingValidityPeriod = Balance.Get(IBUserID);
				If ValueIsFilled(RemainingValidityPeriod)
				   And IsNotificationRequired(IBUser.Name, RemainingValidityPeriod, BegOfDay) Then
				
					SMSMessageRecipients = New Map;
					SMSMessageRecipients.Insert(IBUserID, CommonClientServer.ValueInArray("*"));
					ServerNotifications.SendServerNotification(ServerNotificationName(),
						RemainingValidityPeriod, SMSMessageRecipients);
				EndIf;
				SetPrivilegedMode(False);
			EndIf;
		EndIf;
		
		Parameters.RetrievedClientParameters.Insert("AuthenticationDone",
			?(ValueIsFilled(AuthorizationResult), AuthorizationResult, Undefined));
	EndIf;
	
	If ValueIsFilled(AuthorizationResult) Then
		For Each KeyAndValue In AuthorizationResult Do
			Parameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
	EndIf;
	
	If Parameters.Property("AuthorizationError") Then
		Cancel = True;
	EndIf;
	
EndProcedure

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.ExternalUsers.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ExternalUsersGroups.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.Users.FullName(), "AttributesToSkipInBatchProcessing");
EndProcedure

// See CommonOverridable.OnAddSessionParameterSettingHandlers.
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	Handlers.Insert("CurrentUser",        "UsersInternal.SessionParametersSetting");
	Handlers.Insert("CurrentExternalUser", "UsersInternal.SessionParametersSetting");
	Handlers.Insert("AuthorizedUser", "UsersInternal.SessionParametersSetting");
	Handlers.Insert("UsersCatalogsUpdate", "UsersInternal.SessionParametersSetting");
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessKinds
Procedure OnFillAccessKinds(AccessKinds) Export
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name                    = "Users";
	AccessKind.Presentation          = NStr("en = 'Users';");
	AccessKind.ValuesType            = Type("CatalogRef.Users");
	AccessKind.ValuesGroupsType       = Type("CatalogRef.UserGroups");
	AccessKind.MultipleValuesGroups = True; // 
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name                    = "ExternalUsers";
	AccessKind.Presentation          = NStr("en = 'External users';");
	AccessKind.ValuesType            = Type("CatalogRef.ExternalUsers");
	AccessKind.ValuesGroupsType       = Type("CatalogRef.ExternalUsersGroups");
	AccessKind.MultipleValuesGroups = True; // 
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Catalogs.ExternalUsers, True);
	Lists.Insert(Metadata.Catalogs.ExternalUsersGroups, True);
	Lists.Insert(Metadata.Catalogs.Users, True);
	
EndProcedure

// See CommonOverridable.OnAddServerNotifications
Procedure OnAddServerNotifications(Notifications) Export
	
	If Common.DataSeparationEnabled()
	   And Common.SubsystemExists("CloudTechnology.Core") Then
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		If ModuleSaaSOperations.SessionWithoutSeparators() Then
			Return;
		EndIf;
	EndIf;
	
	Notification = ServerNotifications.NewServerNotification(ServerNotificationName());
	
	Notification.NotificationSendModuleName  = "UsersInternal";
	Notification.NotificationReceiptModuleName = "UsersInternalClient";
	If Common.FileInfobase() Then
		Notification.Parameters = InfobaseUserRoleKeys(
			InfoBaseUsers.CurrentUser());
	EndIf;
	
	Notifications.Insert(Notification.Name, Notification);
	
EndProcedure

// 
//
// Parameters:
//  NameOfAlert - See StandardSubsystemsServer.OnSendServerNotification.NameOfAlert
//  ProcedureParameters - Structure:
//   * ParametersVariants - See StandardSubsystemsServer.OnSendServerNotification.ParametersVariants
//   * ActiveSessionsByKeys - Map of KeyAndValue:
//      ** Key - See ServerNotifications.SessionKey
//      ** Value - InfoBaseSession
//
Procedure OnSendServerNotification(NameOfAlert, ProcedureParameters) Export
	
	ParametersVariants     = ProcedureParameters.ParametersVariants;
	ActiveSessionsByKeys = ProcedureParameters.ActiveSessionsByKeys;
	
	FileInfobase = Common.FileInfobase();
	BegOfDay = BegOfDay(CurrentSessionDate());
	IBUsersIDs = New Array;
	UpdateLastUserActivityDate(ParametersVariants, IBUsersIDs);
	DisableInactiveAndOverdueUsers();
	RemainingValidityPeriods = UsersRemainingValidityPeriods(IBUsersIDs, BegOfDay);
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		AccessGroupModule = Common.CommonModule("Catalogs.AccessGroups");
		AccessGroupModule.ExcludeExpiredMembers();
	EndIf;
	
	LockAddressees = New Map;
	ValidityPeriodRecipients = New Map;
	RolesIncreaseRecipients = New Map;
	RolesReductionRecipients = New Map;
	
	For Each ParametersVariant In ParametersVariants Do
		For Each Addressee In ParametersVariant.SMSMessageRecipients Do
			IBUser = InfoBaseUsers.FindByUUID(Addressee.Key);
			If IBUser = Undefined
			 Or IBUser.StandardAuthentication    = False
			   And IBUser.OpenIDAuthentication         = False
			   And IBUser.OpenIDConnectAuthentication  = False
			   And IBUser.AccessTokenAuthentication = False
			   And IBUser.OSAuthentication             = False Then
			
				AddRecipientSessions(LockAddressees, Addressee);
				Continue;
			EndIf;
			
			RemainingValidityPeriod = RemainingValidityPeriods.Get(IBUser.UUID);
			If ValueIsFilled(RemainingValidityPeriod)
			   And IsNotificationRequired(IBUser.Name, RemainingValidityPeriod, BegOfDay) Then
				
				CurrentPeriodRecipients = ValidityPeriodRecipients.Get(RemainingValidityPeriod);
				If CurrentPeriodRecipients = Undefined Then
					CurrentPeriodRecipients = New Map;
					ValidityPeriodRecipients.Insert(RemainingValidityPeriod, CurrentPeriodRecipients);
				EndIf;
				AddRecipientSessions(CurrentPeriodRecipients, Addressee);
			EndIf;
			
			IsFullUser = Users.IsFullUser(IBUser);
			DateRemindTomorrow = Common.SystemSettingsStorageLoad(
				"InfobaseUserRoleChangeControl", "DateRemindTomorrow",,, IBUser.Name);
			RemindMeTomorrow = TypeOf(DateRemindTomorrow) = Type("Date")
				And CurrentSessionDate() < DateRemindTomorrow;
			
			If FileInfobase Then
				NewRoleKeys = InfobaseUserRoleKeys(IBUser);
				If ParametersVariant.Parameters <> NewRoleKeys Then
					If Not IsFullUser
					   And AreRoleKeysReduced(ParametersVariant.Parameters, NewRoleKeys) Then
						AddRecipientSessions(RolesReductionRecipients, Addressee);
					ElsIf Not RemindMeTomorrow Then
						AddRecipientSessions(RolesIncreaseRecipients, Addressee);
					EndIf;
				EndIf;
				Continue;
			EndIf;
			
			RolesAsString = ValueToStringInternal(IBUser.Roles);
			For Each SessionKey In Addressee.Value Do
				CurrentSession = ActiveSessionsByKeys.Get(SessionKey);
				If CurrentSession = Undefined Then
					Continue;
				EndIf;
				InfobaseOldUser = CurrentSession.User;
				If InfobaseOldUser = Undefined Then
					Continue;
				EndIf;
				If RolesAsString = ValueToStringInternal(InfobaseOldUser.Roles) Then
					Continue;
				EndIf;
				If Not IsFullUser
				   And RolesReduced(InfobaseOldUser, IBUser) Then
					AddRecipientSessions(RolesReductionRecipients, Addressee, SessionKey);
				ElsIf Not RemindMeTomorrow Then
					AddRecipientSessions(RolesIncreaseRecipients, Addressee, SessionKey);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	If ValueIsFilled(LockAddressees) Then
		ServerNotifications.SendServerNotification(NameOfAlert, "AuthorizationDenied", LockAddressees);
	EndIf;
	If ValueIsFilled(ValidityPeriodRecipients) Then
		For Each LongDesc In ValidityPeriodRecipients Do
			ServerNotifications.SendServerNotification(NameOfAlert, LongDesc.Key, LongDesc.Value);
		EndDo;
	EndIf;
	If ValueIsFilled(RolesReductionRecipients) Then
		ServerNotifications.SendServerNotification(NameOfAlert, "RolesReduced", RolesReductionRecipients);
	EndIf;
	If ValueIsFilled(RolesIncreaseRecipients) Then
		ServerNotifications.SendServerNotification(NameOfAlert, "RolesIncreased", RolesIncreaseRecipients);
	EndIf;
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// 
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.ExternalUsers.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
	// 
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.Users.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;

	
EndProcedure

// See MonitoringCenterOverridable.OnCollectConfigurationStatisticsParameters.
Procedure OnCollectConfigurationStatisticsParameters() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		Return;
	EndIf;
	
	ModuleMonitoringCenter = Common.CommonModule("MonitoringCenter");
	
	StandardAuthentication = 0;
	OpenIDAuthentication = 0;
	OpenIDConnectAuthentication = 0;
	AccessTokenAuthentication = 0;
	OSAuthentication = 0;
	CanSignIn = 0;
	For Each UserDetails In InfoBaseUsers.GetUsers() Do
		StandardAuthentication = StandardAuthentication
			+ ?(UserDetails.StandardAuthentication, 1, 0);
		OpenIDAuthentication = OpenIDAuthentication
			+ ?(UserDetails.OpenIDAuthentication, 1, 0);
		OpenIDConnectAuthentication = OpenIDConnectAuthentication
			+ ?(UserDetails.OpenIDConnectAuthentication, 1, 0);
		AccessTokenAuthentication = AccessTokenAuthentication
			+ ?(UserDetails.AccessTokenAuthentication, 1, 0);
		OSAuthentication = OSAuthentication
			+ ?(UserDetails.OSAuthentication, 1, 0);
		CanSignIn = CanSignIn
			+ ?(UserDetails.StandardAuthentication
				Or UserDetails.OpenIDAuthentication
				Or UserDetails.OpenIDConnectAuthentication
				Or UserDetails.AccessTokenAuthentication
				Or UserDetails.OSAuthentication, 1, 0);
	EndDo;
	
	ModuleMonitoringCenter.WriteConfigurationObjectStatistics(
		"Catalog.Users.StandardAuthentication", StandardAuthentication);
	
	ModuleMonitoringCenter.WriteConfigurationObjectStatistics(
		"Catalog.Users.OpenIDAuthentication", OpenIDAuthentication);
	
	ModuleMonitoringCenter.WriteConfigurationObjectStatistics(
		"Catalog.Users.OpenIDConnectAuthentication", OpenIDConnectAuthentication);
	
	ModuleMonitoringCenter.WriteConfigurationObjectStatistics(
		"Catalog.Users.AccessTokenAuthentication", AccessTokenAuthentication);
	
	ModuleMonitoringCenter.WriteConfigurationObjectStatistics(
		"Catalog.Users.OSAuthentication", OSAuthentication);
	
	ModuleMonitoringCenter.WriteConfigurationObjectStatistics(
		"Catalog.Users.CanSignIn", CanSignIn);

	QueryText = 
	"SELECT
	|	COUNT(1) AS Count
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Invalid";
	
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	ModuleMonitoringCenter.WriteConfigurationObjectStatistics(
		"Catalog.Users.Invalid", Selection.Count);
	
	Settings = LogonSettings().Users;
	ExtendedAuthorizationSettingsUsage = Settings.PasswordMustMeetComplexityRequirements
		Or ValueIsFilled(Settings.MinPasswordLength)
		Or ValueIsFilled(Settings.MaxPasswordLifetime)
		Or ValueIsFilled(Settings.MinPasswordLifetime)
		Or ValueIsFilled(Settings.DenyReusingRecentPasswords)
		Or ValueIsFilled(Settings.WarnAboutPasswordExpiration)
		Or ValueIsFilled(Settings.InactivityPeriodBeforeDenyingAuthorization);
	
	ModuleMonitoringCenter.WriteConfigurationObjectStatistics(
		"Catalog.Users.ExtendedAuthorizationSettingsUsage",
		ExtendedAuthorizationSettingsUsage);
	
	QueryText = 
	"SELECT
	|	COUNT(1) AS Count
	|FROM
	|	InformationRegister.UsersInfo AS UsersInfo
	|WHERE
	|	UsersInfo.LastActivityDate >= &SliceDate";
	
	Query = New Query(QueryText);
	Query.SetParameter("SliceDate", BegOfDay(CurrentSessionDate() - 30 *60*60*24)); // 
	Selection = Query.Execute().Select();
	Selection.Next();
	
	ModuleMonitoringCenter.WriteConfigurationObjectStatistics(
		"Catalog.Users.Active", Selection.Count);
	
	QueryText = 
	"SELECT
	|	UsersInfo.LastUsedClient AS ClientUsed,
	|	COUNT(1) AS Count
	|FROM
	|	InformationRegister.UsersInfo AS UsersInfo
	|
	|GROUP BY
	|	UsersInfo.LastUsedClient";
	
	MetadataNamesMap = New Map;
	MetadataNamesMap.Insert("Catalog.Users", QueryText);
	ModuleMonitoringCenter.WriteConfigurationStatistics(MetadataNamesMap);
	
EndProcedure

// See ExportImportDataOverridable.AfterImportData.
Procedure AfterImportData(Container) Export
	
	// 
	If Not Common.DataSeparationEnabled() Then
		AdministrationParameters = StandardSubsystemsServer.AdministrationParameters();
		
		If TypeOf(AdministrationParameters.OpenExternalReportsAndDataProcessorsDecisionMade) <> Type("Boolean")
		 Or AdministrationParameters.OpenExternalReportsAndDataProcessorsDecisionMade Then
			
			AdministrationParameters.OpenExternalReportsAndDataProcessorsDecisionMade = False;
			StandardSubsystemsServer.SetAdministrationParameters(AdministrationParameters);
		EndIf;
	EndIf;
	
	AuthenticateCurrentUser();
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.3.16"; 
	Handler.Procedure = "UsersInternal.UpdatePredefinedUserContactInformationKinds";
	
	If Common.DataSeparationEnabled() Then
		Handler = Handlers.Add();
		Handler.Version = "2.4.1.1";
		Handler.SharedData = True;
		Handler.ExecutionMode = "Seamless";
		Handler.Procedure = "UsersInternal.AddOpenExternalReportsAndDataProcessorsRightForAdministrators";
	Else
		Handler = Handlers.Add();
		Handler.Version = "2.4.1.1";
		Handler.ExecutionMode = "Seamless";
		Handler.Procedure = "UsersInternal.RenameExternalReportAndDataProcessorOpeningDecisionStorageKey";
		Handler.ExecuteInMandatoryGroup = True;
		Handler.Priority = 1;
	EndIf;
	
	If Not Common.DataSeparationEnabled() Then
		
		// Users
		Handler = Handlers.Add();
		Handler.Procedure = "Catalogs.Users.ProcessDataForMigrationToNewVersion";
		Handler.Version = "3.1.4.25";
		Handler.ExecutionMode = "Deferred";
		Handler.Id = New UUID("d553f38f-196b-4fb7-ac8e-34ffb7025ab5");
		Handler.UpdateDataFillingProcedure = "Catalogs.Users.RegisterDataToProcessForMigrationToNewVersion";
		Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
		Handler.Comment = NStr("en = 'Fill in email to recover passwords from user contact information.';");
		Handler.ObjectsToRead    = "Catalog.Users";
		Handler.ObjectsToChange  = "Catalog.Users";
		Handler.ObjectsToLock = "Catalog.Users";
		
		If Common.SubsystemExists("StandardSubsystems.Conversations") Then
			Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
			
			ExecutionPriorities = Handler.ExecutionPriorities; // ValueTable
			NewRow = ExecutionPriorities.Add();
			NewRow.Procedure = "ConversationsInternal.LockInvalidUsersInCollaborationSystem"; // 
			NewRow.Order = "After";
		EndIf;
		
		// External user
		TypesOfExternalUsers = Metadata.DefinedTypes.ExternalUser.Type.Types();
		If TypesOfExternalUsers[0] <> Type("String")
			 And TypesOfExternalUsers[0] <> Type("CatalogRef.MetadataObjectIDs")Then
			
			Handler = Handlers.Add();
			Handler.Procedure = "Catalogs.ExternalUsers.ProcessDataForMigrationToNewVersion";
			Handler.Version = "3.1.4.25";
			Handler.ExecutionMode = "Deferred";
			Handler.Id = New UUID("002f8ac6-dfe6-4d9f-be48-ce3c331aea82");
			Handler.UpdateDataFillingProcedure = "Catalogs.ExternalUsers.RegisterDataToProcessForMigrationToNewVersion";
			Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
			Handler.Comment = NStr("en = 'Fill in email to recover passwords from contact information of external users.';");
			
			ItemsToRead = New Array;
			For Each ExternalUserType In TypesOfExternalUsers Do
				
				If ExternalUserType = Type("CatalogRef.MetadataObjectIDs") Then
					Continue;
				EndIf;
				
				ItemsToRead.Add(Metadata.FindByType(ExternalUserType).FullName());
			EndDo;
			Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
			
			Handler.ObjectsToChange  = "Catalog.ExternalUsers";
			Handler.ObjectsToLock = "Catalog.ExternalUsers";
			
			If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
				Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
				NewRow = Handler.ExecutionPriorities.Add();
				NewRow.Procedure = "NationalLanguageSupportServer.ProcessDataForMigrationToNewVersion";
				NewRow.Order = "Before";
			EndIf;
		EndIf;
		
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.6.8";
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "Constants.UseExternalUserGroups.Refresh";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.8.289";
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "InformationRegisters.UsersInfo.UpdateUsersInfoAndDisableAuthentication";
	Handler.Comment = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = '- Move obsolete ""(not used) Infobase user properties"" attribute values from the ""Users"" and ""External users"" catalogs to the ""User details"" information register.
		           |- Update the ""State picture number"" attribute value in the ""User details"" information register.
		           |- Delete records with non-existing users and external users from the ""User details"" information register.
		           |- Reset unnecessary %1authentication and inactive user authentication.';"),
		"OpenID-Connect");
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.8.198";
	Handler.SharedData = Common.DataSeparationEnabled();
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "UsersInternal.MoveDesignerPasswordLengthAndComplexitySettings";
	Handler.Comment = NStr("en = 'Specify and transfer user authorization settings';");
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.10.65";
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "UsersInternal.FillUserGroupsHierarchy";
	Handler.Comment = NStr("en = 'Filling ""User group hierarchy"" information register';");
	
EndProcedure

// See also updating the information base undefined.When defining settings
//
// Parameters:
//  Objects - Array of MetadataObject
//
Procedure OnDefineObjectsWithInitialFilling(Objects) Export
	
	Objects.Add(Metadata.Catalogs.ExternalUsersGroups);
	Objects.Add(Metadata.Catalogs.UserGroups);
	
EndProcedure

// See InfobaseUpdateSSL.AfterUpdateInfobase.
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
			Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	UpdateAuxiliaryDataOfItemsModifiedUponDataImport();
	
EndProcedure

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	
	// 
	Parameters.Insert("IsFullUser", Users.IsFullUser());
	Parameters.Insert("IsSystemAdministrator", Users.IsFullUser(, True));
	
EndProcedure

// See CommonOverridable.OnAddReferenceSearchExceptions.
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	RefSearchExclusions.Add(Metadata.InformationRegisters.UserGroupCompositions.FullName());
	RefSearchExclusions.Add(Metadata.Catalogs.ExternalUsers.Attributes.AuthorizationObject.FullName());
	
EndProcedure

// 
Procedure OnSendDataToMaster(DataElement, ItemSend, Recipient) Export
	
	OnSendData(DataElement, ItemSend, False, False);
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToSlave.
Procedure OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Recipient) Export
	
	OnSendData(DataElement, ItemSend, True, InitialImageCreating);
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromMaster.
Procedure OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Sender) Export
	
	OnDataGet(DataElement, ItemReceive, SendBack, False);
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromSlave.
Procedure OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender) Export
	
	OnDataGet(DataElement, ItemReceive, SendBack, True);
	
EndProcedure

// See StandardSubsystemsServer.AfterGetData.
Procedure AfterGetData(Sender, Cancel, GetFromMasterNode) Export
	
	If InfobaseUpdate.InfobaseUpdateInProgress() Then
		Return;
	EndIf;
	
	UpdateAuxiliaryDataOfItemsModifiedUponDataImport();
	
EndProcedure

// See the description in the procedure
// to fill in the Extension Work Parameters of the Information Register Manager module Extension Work Parameters.
//
Procedure OnFillAllExtensionParameters() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	// 
	UpdateAuxiliaryDataOfItemsModifiedUponDataImport();
	
EndProcedure


// See SSLSubsystemsIntegration.OnFillToDoList.
Procedure OnFillToDoList(ToDoList) Export
	
	// 
	// 
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	
	AddCaseInvalidUsersInfo = Not Common.DataSeparationEnabled()
		And Users.IsFullUser(, True)
		And Not ModuleToDoListServer.UserTaskDisabled("InvalidUsersInfo");
	OfInvalidUsers = 0;
	If AddCaseInvalidUsersInfo Then
		OfInvalidUsers = UsersAddedInDesigner();
	EndIf;
	
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.Catalogs.Users.FullName());
	
	For Each Section In Sections Do
		
		If AddCaseInvalidUsersInfo Then
			IDUsers = "InvalidUsersInfo" + StrReplace(Section.FullName(), ".", "");
			ToDoItem = ToDoList.Add();
			ToDoItem.Id  = IDUsers;
			ToDoItem.HasToDoItems       = OfInvalidUsers > 0;
			ToDoItem.Count     = OfInvalidUsers;
			ToDoItem.Presentation  = NStr("en = 'Invalid users data';");
			ToDoItem.Form          = "Catalog.Users.Form.InfoBaseUsers";
			ToDoItem.Owner       = Section;
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  KindsOfObjectsToChange - Array of String - 
//  ExternalAttributes - Array of See NewExternalAttribute
//
Procedure OnFillExternalAttributes(KindsOfObjectsToChange, ExternalAttributes) Export
	
	If KindsOfObjectsToChange.Count() > 2
	 Or KindsOfObjectsToChange.Count() = 1
	   And KindsOfObjectsToChange[0] <> "Catalog.Users"
	   And KindsOfObjectsToChange[0] <> "Catalog.ExternalUsers"
	 Or KindsOfObjectsToChange.Count() = 2
	   And (KindsOfObjectsToChange.Find("Catalog.Users") = Undefined
	      Or KindsOfObjectsToChange.Find("Catalog.ExternalUsers") = Undefined)
	 Or Not Users.IsFullUser() Then
		Return;
	EndIf;
	
	Prefix = ExternalAttributePrefix();
	BooleanType = New TypeDescription("Boolean");
	RegisterMetadata = Metadata.InformationRegisters.UsersInfo;
	
	ExternalAttributes.Add(NewExternalAttribute(Prefix + "CanSignIn",
		RegisterMetadata.Attributes.CanSignIn.Presentation(), BooleanType));
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	ExternalAttributes.Add(NewExternalAttribute(Prefix + "StandardAuthentication",
		NStr("en = '1C:Enterprise authentication';"), BooleanType));
	
	ExternalAttributes.Add(NewExternalAttribute(Prefix + "OpenIDAuthentication",
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1 authentication';"), "OpenID"), BooleanType));
	
	ExternalAttributes.Add(NewExternalAttribute(Prefix + "OpenIDConnectAuthentication",
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1 authentication';"), "OpenID-Connect"), BooleanType));
	
	ExternalAttributes.Add(NewExternalAttribute(Prefix + "AccessTokenAuthentication",
		RegisterMetadata.Attributes.AccessTokenAuthentication.Presentation(), BooleanType));
	
	If KindsOfObjectsToChange.Count() = 1
	   And KindsOfObjectsToChange[0] = "Catalog.Users" Then
		
		ExternalAttributes.Add(NewExternalAttribute(Prefix + "OSAuthentication",
			RegisterMetadata.Attributes.OSAuthentication.Presentation(), BooleanType));
		
		ExternalAttributes.Add(NewExternalAttribute(Prefix + "OSUser",
			RegisterMetadata.Attributes.OSUser.Presentation(),
			RegisterMetadata.Attributes.OSUser.Type, True));
	EndIf;
	
	ExternalAttributes.Add(NewExternalAttribute(Prefix + "ShowInList",
		RegisterMetadata.Attributes.ShowInList.Presentation(), BooleanType));
	
	ExternalAttributes.Add(NewExternalAttribute(Prefix + "CannotChangePassword",
		RegisterMetadata.Attributes.CannotChangePassword.Presentation(), BooleanType));
	
	ExternalAttributes.Add(NewExternalAttribute(Prefix + "CannotRecoveryPassword",
		RegisterMetadata.Attributes.CannotRecoveryPassword.Presentation(), BooleanType));
	
	ExternalAttributes.Add(NewExternalAttribute(Prefix + "Email",
		RegisterMetadata.Attributes.Email.Presentation(),
		RegisterMetadata.Attributes.Email.Type, True));
	
	ExternalAttributes.Add(NewExternalAttribute(Prefix + "UserMustChangePasswordOnAuthorization",
		RegisterMetadata.Resources.UserMustChangePasswordOnAuthorization.Presentation(), BooleanType));
	
	ExternalAttributes.Add(NewExternalAttribute(Prefix + "UnlimitedValidityPeriod",
		NStr("en = 'Non-expiring access';"), BooleanType));
	
	ExternalAttributes.Add(NewExternalAttribute(Prefix + "ValidityPeriod",
		NStr("en = 'Access will expire';"),
		RegisterMetadata.Resources.ValidityPeriod.Type));
	
	ExternalAttributes.Add(NewExternalAttribute(Prefix + "InactivityPeriodBeforeDenyingAuthorization",
		NStr("en = 'Deny login after inactivity (days)';"),
		RegisterMetadata.Resources.InactivityPeriodBeforeDenyingAuthorization.Type));
	
EndProcedure

// Parameters:
//  ObjectToChange - CatalogObject.Users
//                   - CatalogObject.ExternalUsers
//
//  ExternalAttributesToChange - Map of KeyAndValue:
//   * Key - See NewExternalAttribute.Name
//   * Value - Arbitrary
//
Procedure OnChangeExternalAttributes(ObjectToChange, ExternalAttributesToChange) Export
	
	IBUserDetails = New Structure;
	Extensions    = New Structure;
	
	AllExtendedProperties = New Structure(
		"UserMustChangePasswordOnAuthorization,
		|UnlimitedValidityPeriod,
		|ValidityPeriod,
		|InactivityPeriodBeforeDenyingAuthorization");
	
	Prefix = ExternalAttributePrefix();
	PositionAfterPrefix = StrLen(Prefix) + 1;
	
	For Each ExternalAttributeToChange In ExternalAttributesToChange Do
		If Not StrStartsWith(ExternalAttributeToChange.Key, Prefix) Then
			Continue;
		EndIf;
		PropertyName = Mid(ExternalAttributeToChange.Key, PositionAfterPrefix);
		If AllExtendedProperties.Property(PropertyName) Then
			Extensions.Insert(PropertyName, ExternalAttributeToChange.Value);
		Else
			IBUserDetails.Insert(PropertyName, ExternalAttributeToChange.Value);
		EndIf;
	EndDo;
	
	Write = False;
	If ValueIsFilled(IBUserDetails) Then
		IBUserDetails.Insert("Action", "Write");
		IBUserDetails.Insert("UpdateInfobaseUserOnly");
		If Not IBUserDetails.Property("CanSignIn") Then
			// 
			IBUserDetails.Insert("CanSignIn");
		EndIf;
		ObjectToChange.AdditionalProperties.Insert("IBUserDetails", IBUserDetails);
		Write = True;
	EndIf;
	
	If ValueIsFilled(Extensions) Then
		ObjectToChange.AdditionalProperties.Insert("InfobaseUserExtendedProperties", Extensions);
		Write = True;
	EndIf;
	
	If Write Then
		ObjectToChange.Description = ObjectToChange.Description; // 
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionKinds.
Procedure OnFillMetadataObjectsAccessRestrictionKinds(LongDesc) Export
	
	AdditionToDetails =
	"
	|Catalog.ExternalUsers.Read.ExternalUsers
	|";
	
	LongDesc = LongDesc + AdditionToDetails;
	
EndProcedure

// See PropertyManagerOverridable.OnGetPredefinedPropertiesSets
Procedure OnGetPredefinedPropertiesSets(Sets) Export
	Set = Sets.Rows.Add();
	Set.Name = "Catalog_ExternalUsers";
	Set.Id = New UUID("d9c30d48-a72a-498a-9faa-c078bf652776");
	Set.Used  = GetFunctionalOption("UseExternalUsers");
	
	Set = Sets.Rows.Add();
	Set.Name = "Catalog_Users";
	Set.Id = New UUID("2bf06771-775a-406a-a5dc-45a10e98914f");
EndProcedure

// See CommonOverridable.OnDefineSupportedInterfaceVersions.
// 
// Parameters:
//   SupportedVersionsStructure - See CommonOverridable.OnDefineSupportedInterfaceVersions.SupportedVersions
// 
Procedure OnDefineSupportedInterfaceVersions(SupportedVersionsStructure) Export
	
	VersionsArray = New Array;
	VersionsArray.Add("1.0.0.1");
	
	SupportedVersionsStructure.Insert(
		"LoginSettingsSaaS",
		VersionsArray);
	
EndProcedure

// 

// See DataExchangeOverridable.OnSetUpSubordinateDIBNode.
Procedure OnSetUpSubordinateDIBNode() Export
	
	ClearNonExistingIBUsersIDs();
	
	InformationRegisters.UsersInfo.UpdateRegisterData();
	
EndProcedure

// 

// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.UsersInfo);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.UserGroupsMembers);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.UsersByDepartments);
	
EndProcedure

// See ReportsOptionsOverridable.BeforeAddReportCommands.
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	Reports.UserGroupsMembers.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
	Reports.UsersByDepartments.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
	
EndProcedure

// 

// See GenerateFromOverridable.OnDefineObjectsWithCreationBasedOnCommands.
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export
	
	Objects.Add(Metadata.Catalogs.Users);
	
EndProcedure

// 

// See UsersOverridable.ChangeActionsOnForm
Procedure OnDefineActionsInForm(Ref, ActionsOnForm) Export
	
	SSLSubsystemsIntegration.OnDefineActionsInForm(Ref, ActionsOnForm);
	UsersOverridable.ChangeActionsOnForm(Ref, ActionsOnForm);
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(Val ParameterName, SpecifiedParameters) Export
	
	If ParameterName <> "CurrentUser"
	   And ParameterName <> "CurrentExternalUser"
	   And ParameterName <> "AuthorizedUser"
	   And ParameterName <> "UsersCatalogsUpdate" Then
		
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	SessionParameters.UsersCatalogsUpdate = New FixedMap(New Map);
	If ParameterName = "UsersCatalogsUpdate" Then
		Return;
	EndIf;
	
	Try
		Values = CurrentUserSessionParameterValues();
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t set session parameter for user ""%1"". Reason:
			           |%2
			           |
			           |Please contact the administrator.';"),
			"CurrentUser",
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		Raise ErrorText;
	EndTry;
	
	If TypeOf(Values) = Type("String") Then
		Raise Values;
	EndIf;
	
	SessionParameters.CurrentUser        = Values.CurrentUser;
	SessionParameters.CurrentExternalUser = Values.CurrentExternalUser;
	
	If ValueIsFilled(Values.CurrentUser) Then
		SessionParameters.AuthorizedUser = Values.CurrentUser;
	Else
		SessionParameters.AuthorizedUser = Values.CurrentExternalUser;
	EndIf;
	
	SpecifiedParameters.Add("CurrentUser");
	SpecifiedParameters.Add("CurrentExternalUser");
	SpecifiedParameters.Add("AuthorizedUser");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Causes the external user's view to be updated when
// the view of their authorization object changes, and also marks it as invalid
// if the authorization object is marked for deletion.
//
Procedure UpdateExternalUserWhenWriting(Val Object, Cancel) Export
	
	If Object.DataExchange.Load Then
		Return;
	EndIf;
	
	If StandardSubsystemsServer.IsMetadataObjectID(Object) Then
		Return;
	EndIf;
	
	UpdateExternalUser(Object.Ref, Object.DeletionMark);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Returns:
//  Structure:
//   * Overall               - See Users.CommonAuthorizationSettingsNewDetails
//   * Users        - See Users.NewDescriptionOfLoginSettings
//   * ExternalUsers - See Users.NewDescriptionOfLoginSettings
//
Function LogonSettings() Export
	
	Settings = New Structure;
	Settings.Insert("Overall",               Users.CommonAuthorizationSettingsNewDetails());
	Settings.Insert("Users",        Users.NewDescriptionOfLoginSettings());
	Settings.Insert("ExternalUsers", Users.NewDescriptionOfLoginSettings());
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	CommonAuthorizationSettingsUsed = Users.CommonAuthorizationSettingsUsed();
	RoundPasswordPolicy = Not DataSeparationEnabled And CommonAuthorizationSettingsUsed;
	
	SetPrivilegedMode(True);
	
	SavedSettings = Constants.UserAuthorizationSettings.Get().Get();
	
	If TypeOf(SavedSettings) = Type("Structure") Then
		
		For Each Setting In Settings Do
			
			If Not SavedSettings.Property(Setting.Key)
			 Or TypeOf(SavedSettings[Setting.Key]) <> Type("Structure") Then
				Continue;
			EndIf;
			
			InitialSettings1 = Setting.Value;
			CurrentSettings = SavedSettings[Setting.Key];
			
			For Each InitialSetting In InitialSettings1 Do
				
				If Not CurrentSettings.Property(InitialSetting.Key)
				 Or TypeOf(CurrentSettings[InitialSetting.Key]) <> TypeOf(InitialSetting.Value) Then
					Continue;
				EndIf;
				InitialSettings1[InitialSetting.Key] = CurrentSettings[InitialSetting.Key];
			EndDo;
		EndDo;
		
	EndIf;
	
	If DataSeparationEnabled
	 Or ExternalUsers.UseExternalUsers() Then
		
		Settings.Overall.ShowInList = "HiddenAndDisabledForAllUsers";
		
	ElsIf Settings.Overall.ShowInList <> "EnabledForNewUsers"
	        And Settings.Overall.ShowInList <> "DisabledForNewUsers"
	        And Settings.Overall.ShowInList <> "HiddenAndEnabledForAllUsers"
	        And Settings.Overall.ShowInList <> "HiddenAndDisabledForAllUsers" Then
		
		Settings.Overall.ShowInList =
			Users.CommonAuthorizationSettingsNewDetails().ShowInList;
	EndIf;
	
	If Settings.Overall.NotificationLeadTimeBeforeTerminateInactiveSession
	   > Settings.Overall.InactivityTimeoutBeforeTerminateSession Then
		
		Settings.Overall.NotificationLeadTimeBeforeTerminateInactiveSession =
			Settings.Overall.InactivityTimeoutBeforeTerminateSession;
	EndIf;
	
	If Settings.Overall.PasswordLockoutDuration <= 0 Then
		Settings.Overall.PasswordLockoutDuration = 1;
	ElsIf Settings.Overall.PasswordLockoutDuration > 16666666 Then
		Settings.Overall.PasswordLockoutDuration = 16666666;
	EndIf;
	
	If Settings.Overall.PasswordRemembranceDuration <= 0 Then
		Settings.Overall.PasswordRemembranceDuration = 1;
	ElsIf Settings.Overall.PasswordRemembranceDuration > 16666666 Then
		Settings.Overall.PasswordRemembranceDuration = 16666666;
	EndIf;
	
	If Settings.Overall.ShouldUseBannedPasswordService
	   And Not ValueIsFilled(Settings.Overall.BannedPasswordServiceAddress) Then
		Settings.Overall.ShouldUseBannedPasswordService = False;
	EndIf;
	
	// 
	FillCommonSettingsFromCommonPasswordPolicy(Settings.Overall);
	If RoundPasswordPolicy Then
		UpdateCommonPasswordPolicy(Settings.Overall);
	EndIf;
	
	// 
	FillSettingsFromUsersPasswordPolicy(Settings.Users);
	If RoundPasswordPolicy Then
		UpdateUsersPasswordPolicy(Settings.Users);
	EndIf;
	
	// 
	If Settings.Overall.AreSeparateSettingsForExternalUsers Then
		FillSettingsFromExternalUsersPasswordPolicy(Settings.ExternalUsers);
	EndIf;
	
	If Not DataSeparationEnabled Then
		If Settings.Overall.AreSeparateSettingsForExternalUsers
		   And CommonAuthorizationSettingsUsed Then
			UpdateExternalUsersPasswordPolicy(Settings.ExternalUsers);
		Else
			UpdateExternalUsersPasswordPolicy(Undefined);
		EndIf;
	EndIf;
	
	SetPrivilegedMode(False);
	
	Return Settings;
	
EndFunction

// Parameters:
//  Settings - See Users.CommonAuthorizationSettingsNewDetails
//
Procedure FillCommonSettingsFromCommonPasswordPolicy(Settings)
	
	LockSettings = AuthenticationLock.GetSettings();
	
	Settings.PasswordLockoutDuration =
		Round(LockSettings.LockDuration / 60);
	
	Settings.PasswordAttemptsCountBeforeLockout =
		LockSettings.MaxUnsuccessfulAttemptsCount;
	
	If Not IsSettings8_3_26Available() Then
		Return;
	EndIf;
	
	// 
	Settings.InactivityTimeoutBeforeTerminateSession =
		Round(Eval("GetInactivityTimeForTerminateSession()") / 60);
	
	Settings.NotificationLeadTimeBeforeTerminateInactiveSession =
		Round(Eval("GetInactivityTimeForTerminateSessionNotification()") / 60);
	
	SettingsForSaving =
		Eval("AdditionalAuthenticationSettings.GetCredentialsAutoSaveSettings()");
	
	Settings.PasswordSaveOptionUponLogin = CurrentPasswordSaveOptionUponLogin(SettingsForSaving);
	Settings.PasswordRemembranceDuration =
		Round(SettingsForSaving.SavedCredentialsLifetime / 60);
	
	ValidationSettings =
		Eval("AdditionalAuthenticationSettings.GetCompromisedPasswordsCheckSettings()");
	// 
	
	Settings.ShouldUseStandardBannedPasswordList =
		ValidationSettings.UseStandardPasswordCompromiseCheckList;
	
	Settings.ShouldUseAdditionalBannedPasswordList =
		ValidationSettings.UseSetPasswordCompromiseCheckList;
	
	Settings.ShouldUseBannedPasswordService =
		ValidationSettings.UsePasswordCompromiseCheckService;
	
	Settings.BannedPasswordServiceAddress =
		ValidationSettings.PasswordCompromiseCheckServiceURL;
	
	Settings.BannedPasswordServiceMaxTimeout =
		ValidationSettings.PasswordCompromiseCheckServiceRequestTimeout;
	
	Settings.ShouldSkipValidationIfBannedPasswordServiceOffline =
		ValidationSettings.IgnorePasswordCompromiseCheckServiceErrors;
	
EndProcedure

// Parameters:
//  Settings - See Users.CommonAuthorizationSettingsNewDetails
//
Procedure UpdateCommonPasswordPolicy(Settings) Export
	
	LockSettings = AuthenticationLock.GetSettings();
	Write = False;
	
	If LockSettings.LockDuration
	  <> Settings.PasswordLockoutDuration * 60 Then
		
		Write = True;
		LockSettings.LockDuration =
			Settings.PasswordLockoutDuration * 60;
	EndIf;
	
	If LockSettings.MaxUnsuccessfulAttemptsCount
	  <> Settings.PasswordAttemptsCountBeforeLockout Then
	
		Write = True;
		LockSettings.MaxUnsuccessfulAttemptsCount =
			Settings.PasswordAttemptsCountBeforeLockout;
	EndIf;
	
	If Write Then
		AuthenticationLock.SetSettings(LockSettings);
	EndIf;
	
	If Not IsSettings8_3_26Available() Then
		Return;
	EndIf;
	
	// 
	// 
	If Eval("GetInactivityTimeForTerminateSession()")
	  <> Settings.InactivityTimeoutBeforeTerminateSession * 60
	   And Eval("GetInactivityTimeForTerminateSessionNotification()")
	  <> Settings.NotificationLeadTimeBeforeTerminateInactiveSession * 60 Then
		
		Execute("SetInactivityTimeForTerminateSessionNotification(0)");
	EndIf;
	
	If Eval("GetInactivityTimeForTerminateSession()")
	  <> Settings.InactivityTimeoutBeforeTerminateSession * 60 Then
		
		Execute("SetInactivityTimeForTerminateSession(
			|Settings.InactivityTimeoutBeforeTerminateSession * 60)");
	EndIf;
	
	If Eval("GetInactivityTimeForTerminateSessionNotification()")
	  <> Settings.NotificationLeadTimeBeforeTerminateInactiveSession * 60 Then
		
		Execute("SetInactivityTimeForTerminateSessionNotification(
			|Settings.NotificationLeadTimeBeforeTerminateInactiveSession * 60)");
	EndIf;
	
	Write = False;
	SettingsForSaving =
		Eval("AdditionalAuthenticationSettings.GetCredentialsAutoSaveSettings()");

	If CurrentPasswordSaveOptionUponLogin(SettingsForSaving)
	  <> Settings.PasswordSaveOptionUponLogin Then
		
		Write = True;
		SettingsForSaving.AllowSave =
			    Settings.PasswordSaveOptionUponLogin = "AllowedAndDisabled"
			Or Settings.PasswordSaveOptionUponLogin = "AllowedAndEnabled";
		SettingsForSaving.SaveByDefault =
			Settings.PasswordSaveOptionUponLogin = "AllowedAndEnabled";
	EndIf;
	
	If SettingsForSaving.SavedCredentialsLifetime
	  <> Settings.PasswordRemembranceDuration * 60 Then
		
		Write = True;
		SettingsForSaving.SavedCredentialsLifetime =
			Settings.PasswordRemembranceDuration * 60;
	EndIf;
	
	If Write Then
		Execute("AdditionalAuthenticationSettings.SetAuthenticationAutoSaveSettings(
			|SettingsForSaving)");
	EndIf;
	
	Write = False;
	ValidationSettings =
		Eval("AdditionalAuthenticationSettings.GetCompromisedPasswordsCheckSettings()");
	
	If ValidationSettings.UseStandardPasswordCompromiseCheckList
	  <> Settings.ShouldUseStandardBannedPasswordList Then
		
		Write = True;
		ValidationSettings.UseStandardPasswordCompromiseCheckList =
			Settings.ShouldUseStandardBannedPasswordList;
	EndIf;
	
	If ValidationSettings.UseSetPasswordCompromiseCheckList
	  <> Settings.ShouldUseAdditionalBannedPasswordList Then
		
		Write = True;
		ValidationSettings.UseSetPasswordCompromiseCheckList =
			Settings.ShouldUseAdditionalBannedPasswordList;
	EndIf;
	
	If ValidationSettings.UsePasswordCompromiseCheckService
	  <> Settings.ShouldUseBannedPasswordService Then
		
		Write = True;
		ValidationSettings.UsePasswordCompromiseCheckService =
			Settings.ShouldUseBannedPasswordService;
	EndIf;
	
	If ValidationSettings.PasswordCompromiseCheckServiceURL
	  <> Settings.BannedPasswordServiceAddress Then
		
		Write = True;
		ValidationSettings.PasswordCompromiseCheckServiceURL =
			Settings.BannedPasswordServiceAddress;
	EndIf;
	
	If ValidationSettings.PasswordCompromiseCheckServiceRequestTimeout
	  <> Settings.BannedPasswordServiceMaxTimeout Then
		
		Write = True;
		ValidationSettings.PasswordCompromiseCheckServiceRequestTimeout =
			Settings.BannedPasswordServiceMaxTimeout;
	EndIf;
	
	If ValidationSettings.IgnorePasswordCompromiseCheckServiceErrors
	  <> Settings.ShouldSkipValidationIfBannedPasswordServiceOffline Then
		
		Write = True;
		ValidationSettings.IgnorePasswordCompromiseCheckServiceErrors =
			Settings.ShouldSkipValidationIfBannedPasswordServiceOffline;
	EndIf;
	
	If Write Then
		Execute("AdditionalAuthenticationSettings.SetPasswordCompromiseCheckSettings(
			|ValidationSettings)");
	EndIf;
	// 
	// 
	
EndProcedure

// Parameters:
//  Settings - See Users.NewDescriptionOfLoginSettings
//
Procedure FillSettingsFromUsersPasswordPolicy(Settings)
	
	SecondsPerDay = 24*60*60;
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	Settings.PasswordMustMeetComplexityRequirements =
		GetUserPasswordStrengthCheck();
	
	Settings.MinPasswordLength =
		GetUserPasswordMinLength();
	
	// 
	If IsSettings8_3_26Available() Then
		Settings.ShouldBeExcludedFromBannedPasswordList
			= Eval("GetUserPasswordCompromiseCheck()");
			
		Settings.ActionUponLoginIfRequirementNotMet =
			CurrentActionUponLoginIfRequirementNotMet();
	EndIf;
	// 
	
	If Not DataSeparationEnabled Then
		Settings.MaxPasswordLifetime =
			Round(GetUserPasswordMaxEffectivePeriod() / SecondsPerDay);
	EndIf;
	
	Settings.MinPasswordLifetime =
		Round(GetUserPasswordMinEffectivePeriod() / SecondsPerDay);
	
	Settings.DenyReusingRecentPasswords =
		GetUserPasswordReuseLimit();
	
	If Not DataSeparationEnabled Then
		Settings.WarnAboutPasswordExpiration =
			Round(GetUserPasswordExpirationNotificationPeriod() / SecondsPerDay);
	EndIf;
	
EndProcedure

// Parameters:
//  Settings - See Users.NewDescriptionOfLoginSettings
//
Procedure UpdateUsersPasswordPolicy(Settings) Export
	
	SecondsPerDay = 24*60*60;
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	If GetUserPasswordStrengthCheck()
	  <> Settings.PasswordMustMeetComplexityRequirements Then
		
		SetUserPasswordStrengthCheck(
			Settings.PasswordMustMeetComplexityRequirements);
	 EndIf;
	
	If GetUserPasswordMinLength()
	  <> Settings.MinPasswordLength Then
	
		SetUserPasswordMinLength(
			Settings.MinPasswordLength);
	EndIf;
	
	// 
	// 
	If IsSettings8_3_26Available() Then
		If Eval("GetUserPasswordCompromiseCheck()")
		  <> Settings.ShouldBeExcludedFromBannedPasswordList Then
			
			Execute("SetUserPasswordCompromiseCheck(
				|Settings.ShouldBeExcludedFromBannedPasswordList)");
		EndIf;
		
		NewAction = ValueOfActionUponLoginIfRequirementNotMet(
			Settings.ActionUponLoginIfRequirementNotMet);
		
		If Eval("GetActionOnUserPasswordRequirementsViolationOnAuthentication()")
		  <> NewAction Then
			
			Execute("SetActionOnUserPasswordRequirementsViolationOnAuthentication(NewAction)");
		EndIf;
	EndIf;
	// 
	// 
	
	MaxPasswordLifetime = ?(DataSeparationEnabled,
		0, Settings.MaxPasswordLifetime);
	
	If GetUserPasswordMaxEffectivePeriod()
	  <> MaxPasswordLifetime * SecondsPerDay Then
	
		SetUserPasswordMaxEffectivePeriod(
			MaxPasswordLifetime * SecondsPerDay);
	EndIf;
	
	If GetUserPasswordMinEffectivePeriod()
	  <> Settings.MinPasswordLifetime * SecondsPerDay Then
	
		SetUserPasswordMinEffectivePeriod(
			Settings.MinPasswordLifetime * SecondsPerDay);
	EndIf;
	
	If GetUserPasswordReuseLimit()
	  <> Settings.DenyReusingRecentPasswords Then
	
		SetUserPasswordReuseLimit(
			Settings.DenyReusingRecentPasswords);
	EndIf;
	
	WarnAboutPasswordExpiration = ?(DataSeparationEnabled,
		0, Settings.WarnAboutPasswordExpiration);
	
	If GetUserPasswordExpirationNotificationPeriod()
	  <> WarnAboutPasswordExpiration * SecondsPerDay Then
	
		SetUserPasswordExpirationNotificationPeriod(
			WarnAboutPasswordExpiration * SecondsPerDay);
	EndIf;
	
EndProcedure

// Parameters:
//  Settings - See Users.NewDescriptionOfLoginSettings
//
Procedure FillSettingsFromExternalUsersPasswordPolicy(Settings)
	
	PasswordPolicy = UserPasswordPolicies.FindByName(
		ExternalUsersPasswordPolicyName());
		
	If PasswordPolicy = Undefined Then
		Return;
	EndIf;
	
	SecondsPerDay = 24*60*60;
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	Settings.PasswordMustMeetComplexityRequirements =
		PasswordPolicy.PasswordStrengthCheck;
	
	Settings.MinPasswordLength =
		PasswordPolicy.PasswordMinLength;
	
	If IsSettings8_3_26Available() Then
		Settings.ShouldBeExcludedFromBannedPasswordList
			= PasswordPolicy.PasswordCompromiseCheck;
			
		Settings.ActionUponLoginIfRequirementNotMet =
			CurrentActionUponLoginIfRequirementNotMet(PasswordPolicy);
	EndIf;
	
	If Not DataSeparationEnabled Then
		Settings.MaxPasswordLifetime =
			Round(PasswordPolicy.PasswordMaxEffectivePeriod / SecondsPerDay);
	EndIf;
	
	Settings.MinPasswordLifetime =
		Round(PasswordPolicy.PasswordMinEffectivePeriod / SecondsPerDay);
	
	Settings.DenyReusingRecentPasswords =
		PasswordPolicy.PasswordReuseLimit;
	
	If Not DataSeparationEnabled Then
		Settings.WarnAboutPasswordExpiration =
			Round(PasswordPolicy.PasswordExpirationNotificationPeriod / SecondsPerDay);
	EndIf;
	
EndProcedure

// Parameters:
//  Settings - See Users.NewDescriptionOfLoginSettings
//
Procedure UpdateExternalUsersPasswordPolicy(Settings) Export
	
	PolicyName = ExternalUsersPasswordPolicyName();
	
	PasswordPolicy = UserPasswordPolicies.FindByName(PolicyName);
	If Settings = Undefined Then
		If PasswordPolicy <> Undefined Then
			PasswordPolicy.Delete();
		EndIf;
		Return;
	EndIf;
	
	Write = False;
	If PasswordPolicy = Undefined Then
		PasswordPolicy = UserPasswordPolicies.CreatePolicy();
		PasswordPolicy.Name = PolicyName;
		Write = True;
	EndIf;
	
	SecondsPerDay = 24*60*60;
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	UpdatePolicyProperty(PasswordPolicy.PasswordStrengthCheck,
		Settings.PasswordMustMeetComplexityRequirements, Write);
	
	UpdatePolicyProperty(PasswordPolicy.PasswordMinLength,
		Settings.MinPasswordLength, Write);
	
	If IsSettings8_3_26Available() Then
		UpdatePolicyProperty(PasswordPolicy.PasswordCompromiseCheck,
			Settings.ShouldBeExcludedFromBannedPasswordList, Write);
	
		NewAction = ValueOfActionUponLoginIfRequirementNotMet(
			Settings.ActionUponLoginIfRequirementNotMet);
		
		UpdatePolicyProperty(PasswordPolicy.ActionUponAuthenticationIfPasswordsNonCompliant,
			NewAction, Write);
	EndIf;
	
	UpdatePolicyProperty(PasswordPolicy.PasswordMaxEffectivePeriod,
		?(DataSeparationEnabled, 0, Settings.MaxPasswordLifetime * SecondsPerDay), Write);
	
	UpdatePolicyProperty(PasswordPolicy.PasswordMinEffectivePeriod,
		Settings.MinPasswordLifetime * SecondsPerDay, Write);
	
	UpdatePolicyProperty(PasswordPolicy.PasswordReuseLimit,
		Settings.DenyReusingRecentPasswords, Write);
	
	UpdatePolicyProperty(PasswordPolicy.PasswordExpirationNotificationPeriod,
		?(DataSeparationEnabled, 0, Settings.WarnAboutPasswordExpiration * SecondsPerDay), Write);
	
	If Write Then
		PasswordPolicy.Write();
	EndIf;
	
EndProcedure

Procedure UpdatePolicyProperty(PolicyValue, SettingValue, Write)
	
	If PolicyValue = SettingValue Then
		Return;
	EndIf;
	
	PolicyValue = SettingValue;
	Write = True;
	
EndProcedure

// Parameters:
//  IBUser - InfoBaseUser
//  IsExternalUser - Boolean
//
Procedure SetPasswordPolicy(IBUser, IsExternalUser) Export
	
	PasswordPolicyName = PasswordPolicyName(IsExternalUser);
	If IBUser.PasswordPolicyName <> PasswordPolicyName Then
		IBUser.PasswordPolicyName = PasswordPolicyName;
	EndIf;
	
EndProcedure

// Parameters:
//  IsExternalUser - Boolean
//
Function PasswordPolicyName(IsExternalUser) Export
	
	If IsExternalUser Then
		Return ExternalUsersPasswordPolicyName();
	EndIf;
	
	Return "";
	
EndFunction

Function ExternalUsersPasswordPolicyName()
	
	Return "ExternalUsers";
	
EndFunction

Function CurrentPasswordSaveOptionUponLogin(SettingsForSaving)
	
	If Not SettingsForSaving.AllowSave Then
		Return "";
	EndIf;
	
	If SettingsForSaving.SaveByDefault Then
		Return "AllowedAndEnabled";
	EndIf;
	
	Return "AllowedAndDisabled";
	
EndFunction

Function CurrentActionUponLoginIfRequirementNotMet(PasswordPolicy = Undefined)
	
	// 
	CurrentAction1 = ?(PasswordPolicy = Undefined,
		Eval("GetActionOnUserPasswordRequirementsViolationOnAuthentication()"),
		PasswordPolicy.ActionUponAuthenticationIfPasswordsNonCompliant);
	
	If CurrentAction1 = Eval("ActionOnPasswordRequirementsViolationOnAuthentication.RequirePasswordChange") Then
		Return "RequirePasswordChange";
		
	ElsIf CurrentAction1 = Eval("ActionOnPasswordRequirementsViolationOnAuthentication.SuggestPasswordChange") Then
		Return "SuggestPasswordChange";
		
	EndIf;
	// 
	
	Return "";
	
EndFunction

Function ValueOfActionUponLoginIfRequirementNotMet(ActionName)
	
	// 
	If ActionName = "RequirePasswordChange" Then
		Return Eval("ActionOnPasswordRequirementsViolationOnAuthentication.RequirePasswordChange");
		
	ElsIf ActionName = "SuggestPasswordChange" Then
		Return Eval("ActionOnPasswordRequirementsViolationOnAuthentication.SuggestPasswordChange");
	EndIf;
	
	Return Eval("ActionOnPasswordRequirementsViolationOnAuthentication.None");
	// 
	
EndFunction

// 
// Parameters:
//  Show - Boolean
//
Procedure SetShowInListAttributeForAllInfobaseUsers(Show) Export
	
	Hidden1 = New Map;
	
	If Show Then
		Query = New Query;
		Query.SetParameter("BlankUUID",
			CommonClientServer.BlankUUID());
		Query.Text =
		"SELECT
		|	Users.IBUserID AS IBUserID
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	Users.IBUserID <> &BlankUUID
		|	AND (Users.IsInternal
		|			OR Users.Invalid)";
		Selection = Query.Execute().Select();
		Hidden1.Insert(Selection.IBUserID, True);
	EndIf;
	
	IBUsers = InfoBaseUsers.GetUsers();
	For Each IBUser In IBUsers Do
		If Not Show
		 Or Hidden1.Get(IBUser.UUID) <> Undefined Then
			ShowInList = False;
		Else
			ShowInList = IBUser.StandardAuthentication;
		EndIf;
		If IBUser.ShowInList <> ShowInList Then
			IBUser.ShowInList = ShowInList;
			IBUser.Write();
		EndIf;
	EndDo;
	
	InformationRegisters.UsersInfo.UpdateRegisterData();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Creates a new password that matches the specified complexity check rules.
// To make it easier to remember, the password is formed from syllables (consonant-vowel).
//
// Parameters:
//  PasswordParameters - Structure -  returns all the parameters of the Password.
//  RNG             - RandomNumberGenerator -  if you are already using.
//                  - Undefined - 
//
// Returns:
//  String - 
//
Function CreatePassword(PasswordParameters, RNG = Undefined) Export
	
	NewPassword = "";
	
	LowercaseConsonants1               = PasswordParameters.LowercaseConsonants;
	UppercaseConsonants1              = PasswordParameters.UppercaseConsonants;
	LowercaseConsonantsCount     = StrLen(LowercaseConsonants1);
	UppercaseConsonantsCount    = StrLen(UppercaseConsonants1);
	UseConsonants           = (LowercaseConsonantsCount > 0)
	                                  Or (UppercaseConsonantsCount > 0);
	
	LowercaseVowels1                 = PasswordParameters.LowercaseVowels;
	UppercaseVowels1                = PasswordParameters.UppercaseVowels;
	LowercaseVowelsCount       = StrLen(LowercaseVowels1);
	UppercaseVowelsCount      = StrLen(UppercaseVowels1);
	UseVowels             = (LowercaseVowelsCount > 0) 
	                                  Or (UppercaseVowelsCount > 0);
	
	Digits                   = PasswordParameters.Digits;
	DigitCount          = StrLen(Digits);
	UseNumbers       = (DigitCount > 0);
	
	SpecialChars             = PasswordParameters.SpecialChars;
	SpecialCharCount  = StrLen(SpecialChars);
	UseSpecialChars = (SpecialCharCount > 0);
	
	// 
	If RNG = Undefined Then
		RNG = Users.PasswordProperties().RNG;
	EndIf;
	
	Counter = 0;
	
	MaxLength           = PasswordParameters.MaxLength;
	MinimumLength            = PasswordParameters.MinimumLength;
	
	// 
	If PasswordParameters.CheckComplexityConditions Then
		SetLowercase      = PasswordParameters.CheckLowercaseLettersExist;
		SetUppercase     = PasswordParameters.CheckUppercaseLettersExist;
		SetDigit         = PasswordParameters.CheckDigitsExist;
		SetSpecialChar    = PasswordParameters.CheckSpecialCharsExist;
	Else
		SetLowercase      = (LowercaseVowelsCount > 0) 
		                          Or (LowercaseConsonantsCount > 0);
		SetUppercase     = (UppercaseVowelsCount > 0) 
		                          Or (UppercaseConsonantsCount > 0);
		SetDigit         = UseNumbers;
		SetSpecialChar    = UseSpecialChars;
	EndIf;
	
	While Counter < MaxLength Do
		
		// 
		If UseConsonants Then
			If SetUppercase And SetLowercase Then
				SearchString = LowercaseConsonants1 + UppercaseConsonants1;
				UpperBound = LowercaseConsonantsCount + UppercaseConsonantsCount;
			ElsIf SetUppercase Then
				SearchString = UppercaseConsonants1;
				UpperBound = UppercaseConsonantsCount;
			Else
				SearchString = LowercaseConsonants1;
				UpperBound = LowercaseConsonantsCount;
			EndIf;
			If IsBlankString(SearchString) Then
				SearchString = LowercaseConsonants1 + UppercaseConsonants1;
				UpperBound = LowercaseConsonantsCount + UppercaseConsonantsCount;
			EndIf;
			Char = Mid(SearchString, RNG.RandomNumber(1, UpperBound), 1);
			If Char = Upper(Char) Then
				If SetUppercase Then
					SetUppercase = (RNG.RandomNumber(0, 1) = 1);
				EndIf;
			Else
				SetLowercase = False;
			EndIf;
			NewPassword = NewPassword + Char;
			Counter     = Counter + 1;
			If Counter >= MinimumLength Then
				Break;
			EndIf;
		EndIf;
		
		// 
		If UseVowels Then
			If SetUppercase And SetLowercase Then
				SearchString = LowercaseVowels1 + UppercaseVowels1;
				UpperBound = LowercaseVowelsCount + UppercaseVowelsCount;
			ElsIf SetUppercase Then
				SearchString = UppercaseVowels1;
				UpperBound = UppercaseVowelsCount;
			Else
				SearchString = LowercaseVowels1;
				UpperBound = LowercaseVowelsCount;
			EndIf;
			If IsBlankString(SearchString) Then
				SearchString = LowercaseVowels1 + UppercaseVowels1;
				UpperBound = LowercaseVowelsCount + UppercaseVowelsCount;
			EndIf;
			Char = Mid(SearchString, RNG.RandomNumber(1, UpperBound), 1);
			If Char = Upper(Char) Then
				SetUppercase = False;
			Else
				SetLowercase = False;
			EndIf;
			NewPassword = NewPassword + Char;
			Counter     = Counter + 1;
			If Counter >= MinimumLength Then
				Break;
			EndIf;
		EndIf;
	
		// 
		If UseNumbers And SetDigit Then
			SetDigit = (RNG.RandomNumber(0, 1) = 1);
			Char          = Mid(Digits, RNG.RandomNumber(1, DigitCount), 1);
			NewPassword     = NewPassword + Char;
			Counter         = Counter + 1;
			If Counter >= MinimumLength Then
				Break;
			EndIf;
		EndIf;
		
		// 
		If UseSpecialChars And SetSpecialChar Then
			SetSpecialChar = (RNG.RandomNumber(0, 1) = 1);
			Char      = Mid(SpecialChars, RNG.RandomNumber(1, SpecialCharCount), 1);
			NewPassword = NewPassword + Char;
			Counter     = Counter + 1;
			If Counter >= MinimumLength Then
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	Return NewPassword;
	
EndFunction

// Returns standard parameters based on length and complexity.
//
// Parameters:
//  MinLength - Number -  the smallest password length (7 by default).
//  Complicated         - Boolean -  consider the requirements for checking password complexity.
//
// Returns:
//  Structure - 
//
Function PasswordParameters(MinLength = 7, Complicated = False) Export
	
	PasswordParameters = New Structure();
	PasswordParameters.Insert("MinimumLength",                MinLength);
	PasswordParameters.Insert("MaxLength",               99);
	PasswordParameters.Insert("LowercaseVowels",            "aeiouy"); 
	PasswordParameters.Insert("UppercaseVowels",           "AEIOUY");
	PasswordParameters.Insert("LowercaseConsonants",          "bcdfghjklmnpqrstvwxz");
	PasswordParameters.Insert("UppercaseConsonants",         "BCDFGHJKLMNPQRSTVWXZ");
	PasswordParameters.Insert("Digits",                           "0123456789");
	PasswordParameters.Insert("SpecialChars",                     " _.,!?");
	PasswordParameters.Insert("CheckComplexityConditions",       Complicated);
	PasswordParameters.Insert("CheckUppercaseLettersExist",  True);
	PasswordParameters.Insert("CheckLowercaseLettersExist",   True);
	PasswordParameters.Insert("CheckDigitsExist",           True);
	PasswordParameters.Insert("CheckSpecialCharsExist",     False);
	
	Return PasswordParameters;
	
EndFunction

// Checks whether you have an account and the rights required to change your password.
//
// Parameters:
//  User - CatalogRef.Users
//               - CatalogRef.ExternalUsers - 
//
//  AdditionalParameters - Structure - :
//   * ErrorText                 - String -  description of the error if there is no possibility to change the password.
//   * IBUserID - UUID -  ID of the IB user.
//   * IsCurrentIBUser    - Boolean -  True if the user is the current user.
//
// Returns:
//  Boolean - 
//
Function CanChangePassword(User, AdditionalParameters = Undefined) Export
	
	If TypeOf(AdditionalParameters) <> Type("Structure") Then
		AdditionalParameters = New Structure;
	EndIf;
	
	If Not AdditionalParameters.Property("IsInternalUser")
	   And Common.DataSeparationEnabled()
	   And Common.SubsystemExists("StandardSubsystems.SaaSOperations.UsersSaaS")
	   And User <> Users.AuthorizedUser() Then
		
		ModuleUsersInternalSaaS = Common.CommonModule("UsersInternalSaaS");
		ActionsWithSaaSUser = ModuleUsersInternalSaaS.GetActionsWithSaaSUser(
			User);
		
		If Not ActionsWithSaaSUser.EditPassword Then
			AdditionalParameters.Insert("ErrorText", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Service: Insufficient rights to change password for user ""%1.""';"), User));
			Return False;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	UserAttributes = Common.ObjectAttributesValues(
		User, "Ref, Invalid, IBUserID, Prepared");
	
	If UserAttributes.Ref <> User Then
		UserAttributes.Ref = Common.ObjectManagerByRef(User).EmptyRef();
		UserAttributes.Invalid = False;
		UserAttributes.Prepared = False;
		UserAttributes.IBUserID = CommonClientServer.BlankUUID();
	EndIf;
	
	If AdditionalParameters.Property("CheckUserValidity")
	   And UserAttributes.Invalid <> False Then
		
		AdditionalParameters.Insert("ErrorText", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'User ""%1"" is inactive.';"), User));
		Return False;
	EndIf;
	
	IBUserID = UserAttributes.IBUserID;
	IBUser = InfoBaseUsers.FindByUUID(IBUserID);
	
	SetPrivilegedMode(False);
	
	If AdditionalParameters.Property("CheckIBUserExists")
	   And IBUser = Undefined Then
		
		AdditionalParameters.Insert("ErrorText", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'There is no account for user ""%1.""';"), User));
		Return False;
	EndIf;
	
	AdditionalParameters.Insert("IBUserID", IBUserID);
	AdditionalParameters.Insert("LoginName", ?(IBUser = Undefined, "", IBUser.Name));
	
	CurrentIBUserID = InfoBaseUsers.CurrentUser().UUID;
	AdditionalParameters.Insert("IsCurrentIBUser", IBUserID = CurrentIBUserID);
	
	AccessLevel = UserPropertiesAccessLevel(UserAttributes);
	
	If Not AdditionalParameters.IsCurrentIBUser
	   And Not AccessLevel.AuthorizationSettings2 Then
		
		AdditionalParameters.Insert("ErrorText", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Insufficient rights to change password for user ""%1"".';"), User));
		Return False;
	EndIf;
	
	AdditionalParameters.Insert("PasswordIsSet",
		IBUser <> Undefined And IBUser.PasswordIsSet);
	
	If IBUser <> Undefined And IBUser.CannotChangePassword Then
		If AccessLevel.AuthorizationSettings2 Then
			If AdditionalParameters.Property("IncludeCannotChangePasswordProperty") Then
				AdditionalParameters.Insert("ErrorText", StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'User ""%1"" cannot change password.';"), User));
				Return False;
			EndIf;
		Else
			AdditionalParameters.Insert("ErrorText", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'User ""%1"" cannot change password.
				           |Please contact the administrator.';"), User));
			Return False;
		EndIf;
	EndIf;
	
	If AdditionalParameters.Property("IncludeStandardAuthenticationProperty")
	   And IBUser <> Undefined
	   And Not IBUser.StandardAuthentication Then
		Return False;
	EndIf;
	
	// 
	If IBUser = Undefined
	 Or Not Common.DataSeparationEnabled()
	   And AccessLevel.AuthorizationSettings2 Then
		
		Return True;
	EndIf;
	
	PasswordPolicyName = PasswordPolicyName(
		TypeOf(User) = Type("CatalogRef.ExternalUsers"));
	
	SetPrivilegedMode(True);
	PasswordPolicy = UserPasswordPolicies.FindByName(PasswordPolicyName);
	If PasswordPolicy = Undefined Then
		PasswordMinEffectivePeriod = GetUserPasswordMinEffectivePeriod();
	Else
		PasswordMinEffectivePeriod = PasswordPolicy.PasswordMinEffectivePeriod;
	EndIf;
	SetPrivilegedMode(False);
	
	If Not ValueIsFilled(PasswordMinEffectivePeriod) Then
		Return True;
	EndIf;
	
	RemainingMinPasswordLifetime = PasswordMinEffectivePeriod
		- (CurrentUniversalDate() - IBUser.PasswordSettingDate);
	
	If RemainingMinPasswordLifetime <= 0 Then
		Return True;
	EndIf;
	
	DaysCount = Round(RemainingMinPasswordLifetime / (24*60*60));
	If DaysCount = 0 Then
		DaysCount = 1;
	EndIf;
	
	NumberAndSubject = Format(DaysCount, "NG=") + " "
		+ UsersInternalClientServer.IntegerSubject(DaysCount,
			"", NStr("en = 'day,days,,,0';"));
	
	AdditionalParameters.Insert("ErrorText", StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'You can change the password in %1.';"), NumberAndSubject));
	
	Return False;
	
EndFunction

// 
// 
// 
// 
// Parameters:
//  Parameters - Structure:
//   * User - CatalogRef.Users
//                  - CatalogRef.ExternalUsers - 
//                  - CatalogObject.Users
//                  - CatalogObject.ExternalUsers - 
//
//   * NewPassword  - String -  the password that you plan to set for the is user.
//   * PreviousPassword - String -  password that is set for the is user (for verification).
//
//   * OnAuthorization    - Boolean -  it may be True when calling from the change Password form.
//   * CheckOnly       - Boolean -  it may be True when calling from the change Password form.
//   * PreviousPasswordMatches - Boolean -  the return value. If it's a lie, it means it doesn't match.
//
//   * ServiceUserPassword - String -  the password of the current user when called
//                                          from the change Password form is reset if an error occurs.
//
// Returns:
//  String - 
//
Function ProcessNewPassword(Parameters) Export
	
	NewPassword  = Parameters.NewPassword;
	PreviousPassword = Parameters.PreviousPassword;
	
	AdditionalParameters = New Structure;
	
	If TypeOf(Parameters.User) = Type("CatalogObject.Users")
	 Or TypeOf(Parameters.User) = Type("CatalogObject.ExternalUsers") Then
		
		ObjectRef2 = Parameters.User.Ref;
		User  = ObjectRef2(Parameters.User);
		CallFromChangePasswordForm = False;
		
		If TypeOf(Parameters.User) = Type("CatalogObject.Users")
		   And Parameters.User.IsInternal Then
			
			AdditionalParameters.Insert("IsInternalUser");
		EndIf;
	Else
		ObjectRef2 = Parameters.User;
		User  = Parameters.User;
		CallFromChangePasswordForm = True;
	EndIf;
	
	Parameters.Insert("PreviousPasswordMatches", False);
	
	If Not CanChangePassword(ObjectRef2, AdditionalParameters) Then
		Return AdditionalParameters.ErrorText;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If AdditionalParameters.IsCurrentIBUser
	   And AdditionalParameters.PasswordIsSet
	   And (PreviousPassword <> Undefined) Then
		
		Parameters.PreviousPasswordMatches = PreviousPasswordMatchSaved(
			PreviousPassword, AdditionalParameters.IBUserID);
		
		If Not Parameters.PreviousPasswordMatches Then
			Return NStr("en = 'The previous password is incorrect.';");
		EndIf;
	EndIf;
	
	IBUser = InfoBaseUsers.FindByUUID(
		AdditionalParameters.IBUserID);
	If TypeOf(IBUser) <> Type("InfoBaseUser") Then
		IBUser = InfoBaseUsers.CreateUser();
	EndIf;
	SetPasswordPolicy(IBUser,
		TypeOf(User) = Type("CatalogRef.ExternalUsers"));
	PasswordErrorText = PasswordComplianceError(NewPassword, IBUser);
	
	SetPrivilegedMode(False);
	
	If ValueIsFilled(PasswordErrorText) Then
		Return PasswordErrorText;
	EndIf;
	
	If CallFromChangePasswordForm And Parameters.CheckOnly Then
		Return "";
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add(Metadata.FindByType(TypeOf(User)).FullName());
	LockItem.SetValue("Ref", User);
	LockItem = Block.Add("InformationRegister.UsersInfo");
	LockItem.SetValue("User", User);
	BeginTransaction();
	Try
		Block.Lock();
		
		If CallFromChangePasswordForm Then
			IBUserDetails = New Structure;
			IBUserDetails.Insert("Action", "Write");
			IBUserDetails.Insert("Password", NewPassword);
			
			CurrentObject = User.GetObject();
			CurrentObject.AdditionalProperties.Insert("IBUserDetails",
				IBUserDetails);
			
			If Parameters.OnAuthorization Then
				CurrentObject.AdditionalProperties.Insert("ChangePasswordOnAuthorization");
			EndIf;
			If Common.DataSeparationEnabled() Then
				If AdditionalParameters.IsCurrentIBUser Then
					CurrentObject.AdditionalProperties.Insert("ServiceUserPassword",
						PreviousPassword);
				Else
					CurrentObject.AdditionalProperties.Insert("ServiceUserPassword",
						Parameters.ServiceUserPassword);
				EndIf;
				CurrentObject.AdditionalProperties.Insert("SynchronizeWithService", True);
			EndIf;
			Try
				CurrentObject.Write();
			Except
				Parameters.ServiceUserPassword = Undefined;
				Raise;
			EndTry;
		Else
			RecordSet = InformationRegisters.UsersInfo.CreateRecordSet();
			RecordSet.Filter.User.Set(User);
			RecordSet.Read();
			Write = False;
			If RecordSet.Count() = 0 Then
				UserInfo = RecordSet.Add();
				UserInfo.User = User;
				Write = True;
			Else
				UserInfo = RecordSet[0];
			EndIf;
			If Parameters.User.AdditionalProperties.Property("ChangePasswordOnAuthorization") Then
				UserInfo.UserMustChangePasswordOnAuthorization = False;
				Write = True;
			EndIf;
			If Common.DataSeparationEnabled() Then
				NewStartDate = BegOfDay(CurrentSessionDate());
				If UserInfo.DeletePasswordUsageStartDate <> NewStartDate Then
					UserInfo.DeletePasswordUsageStartDate = NewStartDate;
					Write = True;
				EndIf;
			EndIf;
			If Write Then
				RecordSet.Write();
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorInfo = ErrorInfo();
		If CallFromChangePasswordForm Then
			WriteLogEvent(
				NStr("en = 'Users.Password change error';",
				     Common.DefaultLanguageCode()),
				EventLogLevel.Error,
				Metadata.FindByType(TypeOf(User)),
				User,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Cannot change password for user ""%1"". Reason:
					           |%2';"),
					User, ErrorProcessing.DetailErrorDescription(ErrorInfo)));
			Parameters.Insert("ErrorSavedToEventLog");
		EndIf;
		Raise;
	EndTry;
	
	Return "";
	
EndFunction

// For the change Password form and function, the new password can be Set.
//
// Returns:
//  String
//
Function NewPasswordHint() Export
	
	Return
		NStr("en = 'A secure password:
		           |- Has at least 7 characters.
		           |- Contains at least 3 out of 4 character types: uppercase
		           |and lowercase letters, numbers, and special characters.
		           |- Is not identical to the username.';");
	
EndFunction

// For forms of directory elements, Users and external Users.

// 
//
// Parameters:
//  ForExternalUsers - Boolean
//
// Returns:
//  FormattedString
//
Function HintUserMustChangePasswordOnAuthorization(ForExternalUsers) Export
	
	IsFullUser = Users.IsFullUser(, False);
	
	If Not IsFullUser Then
		ToolTip =
			NStr("en = 'You can apply password length and complexity requirements.
			           |For details, contact the administrator.';");
		Return New FormattedString(ToolTip);
	EndIf;
	
	If Not Users.CommonAuthorizationSettingsUsed() Then
		ToolTip =
			NStr("en = 'You can apply password length and complexity requirements.
			           |See ""Administration"" – ""Infobase parameters"" in Designer.';");
		Return New FormattedString(ToolTip);
	EndIf;
	
	HasAdministrationSection = Metadata.Subsystems.Find("Administration") <> Undefined;
	
	If ForExternalUsers Then
		If HasAdministrationSection Then
			ToolTip =
				NStr("en = 'You can set password length and complexity requirements.
				           |To do this, go to <b>Administration</b> > <b>Users and rights settings</b>.
				           |Click <a href = ""%1"">Login settings</a> and select <b>For external users</b>.';");
		Else
			ToolTip =
				NStr("en = 'You can set password length and complexity requirements.
				           |To do this, go to <a href = ""%1"">Login settings</a> and select <b>For external users</b>.';");
		EndIf;
	Else
		If HasAdministrationSection Then
			ToolTip =
				NStr("en = 'You can set password length and complexity requirements.
				           |To do this, go to <b>Administration</b> > <b>Users and rights settings</b>.
				           |Click <a href = ""%1"">Login settings</a> and select <b>For users</b>.';");
		Else
			ToolTip =
				NStr("en = 'You can set password length and complexity requirements.
				           |To do this, go to <a href = ""%1"">Login settings</a> and select <b>For users</b>.';");
		EndIf;
	EndIf;
	
	Return StringFunctions.FormattedString(ToolTip,
		"UserAuthorizationSettings");
	
EndFunction

// 
// 
//
// Returns:
//  Map
//   
//   
//
Function PrefixedNamesForInfobaseUserProperties() Export
	
	Result = New Map;
	Result.Insert("Email",          "IBUserEmailAddress");
	Result.Insert("OpenIDAuthentication",           "IBUserOpenIDAuthentication");
	Result.Insert("OpenIDConnectAuthentication",    "InfobaseUserAuthWithOpenIDConnect");
	Result.Insert("OSAuthentication",               "IBUserOSAuthentication");
	Result.Insert("StandardAuthentication",      "IBUserStandardAuthentication");
	Result.Insert("AccessTokenAuthentication",   "InfobaseUserAuthWithAccessToken");
	Result.Insert("CannotRecoveryPassword", "IBUserCannotRecoveryPassword");
	Result.Insert("CannotChangePassword",        "IBUserCannotChangePassword");
	Result.Insert("UnsafeActionProtection",        "InfobaseUserUnsafeActionProtection");
	Result.Insert("Name",                            "IBUserName");
	Result.Insert("DefaultInterface",              "IBUserDefaultInterface");
	Result.Insert("Password",                         "IBUserPassword");
	Result.Insert("ShowInList",        "IBUserShowInList");
	Result.Insert("FullName",                      "IBUserFullName");
	Result.Insert("OSUser",                 "IBUserOSUser");
	Result.Insert("RunMode",                   "IBUserRunMode");
	Result.Insert("Roles",                           "IBUserRoles");
	Result.Insert("PreviousPassword",                   "IBUserPreviousPassword");
	Result.Insert("Language",                           "IBUserLanguage");
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// For internal use only.
//
// Returns:
//  CatalogRef.Users
//  
//
Function AuthorizedUser() Export
	
	SetPrivilegedMode(True);
	
	If Not Common.SeparatedDataUsageAvailable() Then
		ErrorText = CurrentUserUnavailableInSessionWithoutSeparatorsMessageText();
		Raise ErrorText;
	EndIf;
	
	Return ?(ValueIsFilled(SessionParameters.CurrentUser),
		SessionParameters.CurrentUser,
		SessionParameters.CurrentExternalUser);
	
EndFunction

// 
//
// Parameters:
//  Password    - String -  the password you need to get the value to be stored.
//  ToWrite - Boolean -  if True, then an empty password will have a non-empty result.
//
// Returns:
//  String - 
//           
//
Function PasswordHashString(Password, ToWrite = False) Export
	
	If Password = "" And Not ToWrite Then
		StoredPasswordValue = "";
	Else
		DataHashing = New DataHashing(HashFunction.SHA1);
		DataHashing.Append(Password);
		
		StoredPasswordValue = Base64String(DataHashing.HashSum);
		
		DataHashing = New DataHashing(HashFunction.SHA1);
		DataHashing.Append(Upper(Password));
		
		StoredPasswordValue = StoredPasswordValue + ","
			+ Base64String(DataHashing.HashSum);
	EndIf;
	
	Return StoredPasswordValue;
	
EndFunction

// Compares the old password with the previously saved password
// for the is user without taking into account password complexity control.
//
// Parameters:
//  Password                      - String -  the old password that you want to compare.
//
//  IBUserID - UUID -  the user of IB for which
//                                you need to check the old password.
//
// Returns:
//  Boolean - 
//
Function PreviousPasswordMatchSaved(Password, IBUserID) Export
	
	If TypeOf(IBUserID) <> Type("UUID") Then
		Return False;
	EndIf;
	
	IBUser = InfoBaseUsers.FindByUUID(
		IBUserID);
	
	If TypeOf(IBUser) <> Type("InfoBaseUser") Then
		Return False;
	EndIf;
	
	If IsSettings8_3_26Available() Then
		// 
		Result = Eval("CheckUserPasswordComplianceWithStoredValue(Password, IBUser)");
		// 
	Else
		Result = PasswordHashSumMatches(PasswordHashString(Password),
			IBUser.StoredPasswordValue);
	EndIf;
	
	Return Result;
	
EndFunction

// Checks that the first and second passwords have the same first or second hash amounts.
//
// Parameters:
//  FirstPasswordHash - String -  contains the hash sum of the saved password in the format
//                                       of the same name property of the user information Database type.
//
//  SecondPasswordHash - String -  the same as the stored value of the second password.
//
//
Function PasswordHashSumMatches(FirstPasswordHash, SecondPasswordHash)
	
	If FirstPasswordHash = SecondPasswordHash Then
		Return True;
	EndIf;
	
	FirstPasswordHashSums = StrSplit(FirstPasswordHash, ",", False);
	If FirstPasswordHashSums.Count() <> 2 Then
		Return False;
	EndIf;
	
	SecondPasswordHashSums = StrSplit(SecondPasswordHash, ",", False);
	If SecondPasswordHashSums.Count() <> 2 Then
		Return False;
	EndIf;
	
	Return FirstPasswordHashSums[0] = SecondPasswordHashSums[0]
		Or FirstPasswordHashSums[1] = SecondPasswordHashSums[1];
	
EndFunction

// Returns the current level of access to change the properties of the is user.
// 
// Parameters:
//  ObjectDetails - CatalogObject.Users
//                  - CatalogObject.ExternalUsers
//                  - FormDataStructure - 
//
//  ProcessingParameters - Undefined -  get data from the object description,
//                       otherwise take ready-made data from the processing parameters.
//
// Returns:
//  Structure:
//   * SystemAdministrator       - Boolean -  any actions with any user and their information security user.
//   * FullAccess                - Boolean -  the same applies to system Administrators, excluding system administrators.
//   * ListManagement          - Boolean - :
//                                  
//                                     
//                                  
//                                     
//                                     
//   * ChangeAuthorizationPermission  - Boolean - 
//   * DisableAuthorizationApproval - Boolean - 
//   * AuthorizationSettings2          - Boolean - 
//                                    
//                                    
//                                    
//   * ChangeCurrent          - Boolean -  changing the properties of the current user Password and Language.
//   * NoAccess                 - Boolean -  there are none of the above access levels.
//
Function UserPropertiesAccessLevel(ObjectDetails, ProcessingParameters = Undefined) Export
	
	AccessLevel = New Structure;
	
	// 
	AccessLevel.Insert("SystemAdministrator", Users.IsFullUser(, True));
	
	// 
	AccessLevel.Insert("FullAccess", Users.IsFullUser());
	
	If TypeOf(ObjectDetails.Ref) = Type("CatalogRef.Users") Then
		// 
		AccessLevel.Insert("ListManagement",
			AccessRight("Insert", Metadata.Catalogs.Users)
			And (AccessLevel.FullAccess
			   Or Not Users.IsFullUser(ObjectDetails.Ref)));
		// 
		AccessLevel.Insert("ChangeCurrent",
			AccessLevel.FullAccess
			Or AccessRight("Update", Metadata.Catalogs.Users)
			  And ObjectDetails.Ref = Users.AuthorizedUser());
		
	ElsIf TypeOf(ObjectDetails.Ref) = Type("CatalogRef.ExternalUsers") Then
		// 
		AccessLevel.Insert("ListManagement",
			AccessRight("Insert", Metadata.Catalogs.ExternalUsers)
			And (AccessLevel.FullAccess
			   Or Not Users.IsFullUser(ObjectDetails.Ref)));
		// 
		AccessLevel.Insert("ChangeCurrent",
			AccessLevel.FullAccess
			Or AccessRight("Update", Metadata.Catalogs.ExternalUsers)
			  And ObjectDetails.Ref = Users.AuthorizedUser());
	EndIf;
	
	If ProcessingParameters = Undefined Then
		SetPrivilegedMode(True);
		If ValueIsFilled(ObjectDetails.IBUserID) Then
			IBUser = InfoBaseUsers.FindByUUID(
				ObjectDetails.IBUserID);
		Else
			IBUser = Undefined;
		EndIf;
		UserWithoutAuthorizationSettingsOrPrepared =
			    IBUser = Undefined
			Or ObjectDetails.Prepared
			    And Not Users.CanSignIn(IBUser);
		SetPrivilegedMode(False);
	Else
		UserWithoutAuthorizationSettingsOrPrepared =
			    Not ProcessingParameters.OldIBUserExists
			Or ProcessingParameters.OldUser.Prepared
			    And Not Users.CanSignIn(ProcessingParameters.PreviousIBUserDetails);
	EndIf;
	
	AccessLevel.Insert("ChangeAuthorizationPermission",
		    AccessLevel.SystemAdministrator
		Or AccessLevel.FullAccess
		  And Not Users.IsFullUser(ObjectDetails.Ref, True));
	
	AccessLevel.Insert("DisableAuthorizationApproval",
		    AccessLevel.SystemAdministrator
		Or AccessLevel.FullAccess
		  And Not Users.IsFullUser(ObjectDetails.Ref, True)
		Or AccessLevel.ListManagement);
	
	AccessLevel.Insert("AuthorizationSettings2",
		    AccessLevel.SystemAdministrator
		Or AccessLevel.FullAccess
		  And Not Users.IsFullUser(ObjectDetails.Ref, True)
		Or AccessLevel.ListManagement
		  And UserWithoutAuthorizationSettingsOrPrepared);
	
	AccessLevel.Insert("NoAccess",
		  Not AccessLevel.SystemAdministrator
		And Not AccessLevel.FullAccess
		And Not AccessLevel.ListManagement
		And Not AccessLevel.ChangeCurrent
		And Not AccessLevel.AuthorizationSettings2);
	
	Return AccessLevel;
	
EndFunction

// Checks that the specified user has a higher access level than the current user.
// 
// Parameters:
//  UserDetails - CatalogRef.Users
//                       - CatalogRef.ExternalUsers
// 
// CurrentAccessLevel - See UserPropertiesAccessLevel
// 
// Returns:
//  Boolean
//
Function UserAccessLevelAbove(UserDetails, CurrentAccessLevel) Export
	
	If TypeOf(UserDetails) = Type("CatalogRef.Users")
	 Or TypeOf(UserDetails) = Type("CatalogRef.ExternalUsers") Then
		
		Return Users.IsFullUser(UserDetails, True, False)
		      And Not CurrentAccessLevel.SystemAdministrator
		    Or Users.IsFullUser(UserDetails, False, False)
		      And Not CurrentAccessLevel.FullAccess;
	Else
		Return UserDetails.Roles.Find("SystemAdministrator") <> Undefined
		      And Not CurrentAccessLevel.SystemAdministrator
		    Or UserDetails.Roles.Find("FullAccess") <> Undefined
		      And Not CurrentAccessLevel.FullAccess;
	EndIf;
	
EndFunction

// 
// 
// 
//
// Parameters:
//  ThisIsBandRecord - Boolean
//
Procedure LockRegistersBeforeWritingToFileInformationSystem(ThisIsBandRecord) Export
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.LockRegistersBeforeWritingAccessConfigurationObjectToFileInformationSystem();
	EndIf;
	
	Block = New DataLock;
	Block.Add("InformationRegister.UserGroupsHierarchy");
	Block.Add("InformationRegister.UserGroupCompositions");
	If Not ThisIsBandRecord Then
		Block.Add("InformationRegister.UsersInfo");
	EndIf;
	Block.Lock();
	
EndProcedure

// 
// 
//
// Parameters:
//  Object - CatalogObject.Users
//         - CatalogObject.ExternalUsers
//  ProcessingParameters - Structure -  the return value.
//
Procedure UserObjectBeforeWrite(Object, ProcessingParameters) Export
	
	IsExternalUser = TypeOf(Object.Ref) = Type("CatalogRef.ExternalUsers");
	Properties = Common.ObjectAttributesValues(Object.Ref,
		"DeletionMark, Invalid, IBUserID"
		+ ?(IsExternalUser, "", ", Department, Individual"));
	
	ShouldLogChanges = Properties.DeletionMark <> Object.DeletionMark
		Or Properties.Invalid <> Object.Invalid
		Or Properties.IBUserID <> Object.IBUserID
		Or Not IsExternalUser
		  And (    Properties.Department <> Object.Department
		     Or Properties.Individual <> Object.Individual);
	
	If Not Object.DataExchange.Load
	 Or Object.AdditionalProperties.Property("WriteDuringDataExchange")
	 Or Object.AdditionalProperties.Property("IBUserDetails") Then
		
		StartIBUserProcessing(Object, ProcessingParameters);
	EndIf;
	
	If Not Object.DataExchange.Load
	 Or Object.AdditionalProperties.Property("WriteDuringDataExchange")
	 Or Object.AdditionalProperties.Property("IBUserDetails")
	 Or Object.AdditionalProperties.Property("InfobaseUserExtendedProperties")
	 Or ShouldLogChanges Then
		
		SetPrivilegedMode(True);
		InformationRegisters.UsersInfo.UpdateUserInfoRecords(
			ObjectRef2(Object), Object,, ShouldLogChanges);
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

// 
// 
//
// Parameters:
//  Object - CatalogObject.Users
//         - CatalogObject.ExternalUsers
//
Procedure UserObjectBeforeDelete(Object, IsDeletionDuringExchange = False) Export
	
	If Not Object.DataExchange.Load
	 Or IsDeletionDuringExchange
	 Or Object.AdditionalProperties.Property("IBUserDetails") Then
	
		// 
		// 
		
		IBUserDetails = New Structure;
		IBUserDetails.Insert("Action", "Delete");
		Object.AdditionalProperties.Insert("IBUserDetails", IBUserDetails);
		
		IBUserProcessingParameters = Undefined;
		StartIBUserProcessing(Object, IBUserProcessingParameters, True);
		EndIBUserProcessing(Object, IBUserProcessingParameters);
	EndIf;
	
	InformationRegisters.UsersInfo.DeleteUserInfo(Object.Ref);
	
EndProcedure

// Called before recording a user or an external user.
//
// Parameters:
//  UserObject - CatalogObject.Users
//                     - CatalogObject.ExternalUsers
//  ProcessingParameters - Structure
//  DeleteUserFromCatalog - Boolean
//
Procedure StartIBUserProcessing(UserObject,
                                        ProcessingParameters,
                                        DeleteUserFromCatalog = False) Export
	
	ProcessingParameters = New Structure;
	AdditionalProperties = UserObject.AdditionalProperties;
	
	ProcessingParameters.Insert("DeleteUserFromCatalog", DeleteUserFromCatalog);
	ProcessingParameters.Insert("InsufficientRightsMessageText",
		NStr("en = 'Insufficient rights to change infobase user.';"));
	
	If AdditionalProperties.Property("CopyingValue")
	   And ValueIsFilled(AdditionalProperties.CopyingValue)
	   And TypeOf(AdditionalProperties.CopyingValue) = TypeOf(UserObject.Ref) Then
		
		ProcessingParameters.Insert("CopyingValue", AdditionalProperties.CopyingValue);
	EndIf;
	
	// 
	AutoAttributes = New Structure;
	AutoAttributes.Insert("IBUserID");
	AutoAttributes.Insert("DeleteInfobaseUserProperties");
	ProcessingParameters.Insert("AutoAttributes", AutoAttributes);
	
	// 
	AttributesToLock = New Structure;
	AttributesToLock.Insert("IsInternal", False); // 
	AttributesToLock.Insert("DeletionMark");
	AttributesToLock.Insert("Invalid");
	AttributesToLock.Insert("Prepared");
	ProcessingParameters.Insert("AttributesToLock", AttributesToLock);
	
	RememberUserProperties(UserObject, ProcessingParameters);
	
	AccessLevel = UserPropertiesAccessLevel(UserObject, ProcessingParameters);
	ProcessingParameters.Insert("AccessLevel", AccessLevel);
	
	// 
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.UsersSaaS") Then
		ModuleUsersInternalSaaS = Common.CommonModule("UsersInternalSaaS");
		ModuleUsersInternalSaaS.BeforeStartIBUserProcessing(UserObject, ProcessingParameters);
	EndIf;
	
	If ProcessingParameters.OldUser.Prepared <> UserObject.Prepared
	   And Not AccessLevel.ChangeAuthorizationPermission Then
		
		Raise ProcessingParameters.InsufficientRightsMessageText;
	EndIf;
	
	// 
	If ProcessingParameters.OldIBUserExists
	   And Users.CanSignIn(ProcessingParameters.PreviousIBUserDetails)
	   And Not AdditionalProperties.Property("IBUserDetails")
	   And (  ProcessingParameters.OldUser.DeletionMark = False
	      And UserObject.DeletionMark = True
	    Or ProcessingParameters.OldUser.Invalid = False
	      And UserObject.Invalid  = True) Then
		
		AdditionalProperties.Insert("IBUserDetails", New Structure);
		AdditionalProperties.IBUserDetails.Insert("Action", "Write");
		AdditionalProperties.IBUserDetails.Insert("CanSignIn", False);
	EndIf;
	
	// 
	If ProcessingParameters.OldIBUserExists
	   And Not AdditionalProperties.Property("IBUserDetails")
	   And ProcessingParameters.PreviousIBUserDetails.FullName
	     <> UserObject.Description Then
		
		AdditionalProperties.Insert("IBUserDetails", New Structure);
		AdditionalProperties.IBUserDetails.Insert("Action", "Write");
	EndIf;
	
	If Not AdditionalProperties.Property("IBUserDetails") Then
		If AccessLevel.ListManagement
		   And Not ProcessingParameters.OldIBUserExists
		   And ValueIsFilled(UserObject.IBUserID) Then
			// 
			UserObject.IBUserID = Undefined;
			ProcessingParameters.AutoAttributes.IBUserID =
				UserObject.IBUserID;
		EndIf;
		Return;
	EndIf;
	IBUserDetails = AdditionalProperties.IBUserDetails;
	
	If Not IBUserDetails.Property("Action") Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t save user ""%1"".
			           |Parameter %2 is missing property %3.';"),
			UserObject.Ref, "IBUserDetails", "Action");
		Raise ErrorText;
	EndIf;
	
	If IBUserDetails.Action <> "Write"
	   And IBUserDetails.Action <> "Delete" Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t save user ""%1"".
			           |Parameter %2 has invalid value in property %4:
			           |""%3"".';"),
			UserObject.Ref,
			"IBUserDetails",
			IBUserDetails.Action,
			"Action");
		Raise ErrorText;
	EndIf;
	ProcessingParameters.Insert("Action", IBUserDetails.Action);
	
	SSLSubsystemsIntegration.OnStartIBUserProcessing(ProcessingParameters, IBUserDetails);
	
	SetPrivilegedMode(True);
	
	If IBUserDetails.Action = "Write"
	   And IBUserDetails.Property("UUID")
	   And ValueIsFilled(IBUserDetails.UUID)
	   And IBUserDetails.UUID
	     <> ProcessingParameters.OldUser.IBUserID Then
		
		ProcessingParameters.Insert("IBUserSetting");
		
		If ProcessingParameters.OldIBUserExists Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Couldn''t save user ""%1"".
				           |The user in the catalog is already mapped
				           |with an infobase user.';"),
				UserObject.Description);
			Raise ErrorText;
		EndIf;
		
		FoundUser = Undefined;
		
		If UserByIDExists(
			IBUserDetails.UUID,
			UserObject.Ref,
			FoundUser) Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Couldn''t save user ""%1"".
				           |The infobase user is already mapped
				           |with a user in catalog
				           |""%2"".';"),
				FoundUser,
				UserObject.Description);
			Raise ErrorText;
		EndIf;
		
		If Not AccessLevel.FullAccess Then
			Raise ProcessingParameters.InsufficientRightsMessageText;
		EndIf;
		
		If Not ProcessingParameters.Property("Action") Then
			UserObject.IBUserID = IBUserDetails.UUID;
			// 
			ProcessingParameters.AutoAttributes.IBUserID =
				UserObject.IBUserID;
		EndIf;
	EndIf;
	
	If Not ProcessingParameters.Property("Action") Then
		Return;
	EndIf;
	
	If AccessLevel.NoAccess Then
		Raise ProcessingParameters.InsufficientRightsMessageText;
	EndIf;
	
	If IBUserDetails.Action = "Delete" Then
		
		If Not AccessLevel.ChangeAuthorizationPermission Then
			Raise ProcessingParameters.InsufficientRightsMessageText;
		EndIf;
		
	ElsIf Not AccessLevel.ListManagement Then // 
		
		If Not AccessLevel.ChangeCurrent
		 Or Not ProcessingParameters.OldIBUserCurrent Then
			
			Raise ProcessingParameters.InsufficientRightsMessageText;
		EndIf;
	EndIf;
	
	If IBUserDetails.Action = "Write" Then
		
		// 
		If ProcessingParameters.OldIBUserExists
		   And UserAccessLevelAbove(ProcessingParameters.PreviousIBUserDetails, AccessLevel) Then
			
			Raise ProcessingParameters.InsufficientRightsMessageText;
		EndIf;
		
		// 
		If Not AccessLevel.FullAccess Then
			ValidProperties = New Structure;
			ValidProperties.Insert("UUID"); // 
			
			If AccessLevel.ChangeCurrent Then
				ValidProperties.Insert("Email");
				ValidProperties.Insert("Password");
				ValidProperties.Insert("Language");
			EndIf;
			
			If AccessLevel.ListManagement Then
				ValidProperties.Insert("FullName");
				ValidProperties.Insert("Email");
				ValidProperties.Insert("ShowInList");
				ValidProperties.Insert("CannotChangePassword");
				ValidProperties.Insert("CannotRecoveryPassword");
				ValidProperties.Insert("Language");
				ValidProperties.Insert("RunMode");
			EndIf;
			
			If AccessLevel.AuthorizationSettings2 Then
				ValidProperties.Insert("Name");
				ValidProperties.Insert("StandardAuthentication");
				ValidProperties.Insert("Password");
				ValidProperties.Insert("OpenIDAuthentication");
				ValidProperties.Insert("OpenIDConnectAuthentication");
				ValidProperties.Insert("AccessTokenAuthentication");
				ValidProperties.Insert("OSAuthentication");
				ValidProperties.Insert("OSUser");
				ValidProperties.Insert("Roles");
			EndIf;
			
			AllProperties = Users.NewIBUserDetails();
			
			For Each KeyAndValue In IBUserDetails Do
				
				If AllProperties.Property(KeyAndValue.Key)
				   And KeyAndValue.Value <> Undefined
				   And Not ValidProperties.Property(KeyAndValue.Key) Then
					
					Raise ProcessingParameters.InsufficientRightsMessageText;
				EndIf;
			EndDo;
		EndIf;
		
		WriteIBUser(UserObject, ProcessingParameters);
	Else
		DeleteIBUser(UserObject, ProcessingParameters);
	EndIf;
	
	// 
	ProcessingParameters.AutoAttributes.IBUserID =
		UserObject.IBUserID;
	
	NewIBUserDetails1 = Users.IBUserProperies(UserObject.IBUserID);
	ProcessingParameters.Insert("NewIBUserExists", NewIBUserDetails1 <> Undefined);
	ProcessingParameters.Insert("InfobaseNewUser",
		InfobaseUserByID(UserObject.IBUserID));
	
	If NewIBUserDetails1 <> Undefined Then
		ProcessingParameters.Insert("NewIBUserDetails1", NewIBUserDetails1);
		
		// 
		If ProcessingParameters.OldIBUserExists
		   And UserAccessLevelAbove(ProcessingParameters.NewIBUserDetails1, AccessLevel) Then
			
			Raise ProcessingParameters.InsufficientRightsMessageText;
		EndIf;
	EndIf;
	
	// 
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.UsersSaaS") Then
		ModuleUsersInternalSaaS = Common.CommonModule("UsersInternalSaaS");
		ModuleUsersInternalSaaS.AfterStartIBUserProcessing(UserObject, ProcessingParameters);
	EndIf;
	
	If ProcessingParameters.Property("CreateAdministrator")
	   And ProcessingParameters.NewIBUserExists Then
		
		SetPrivilegedMode(True);
		SSLSubsystemsIntegration.OnCreateAdministrator(ObjectRef2(UserObject),
			ProcessingParameters.CreateAdministrator);
		SetPrivilegedMode(False);
	EndIf;
	
	If IBUserDetails.Property("Email")
	   And IBUserDetails.Email <> Undefined
	   And Not AdditionalProperties.Property("IsRecoveryEmailSetOnForm")
	   And Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		
		OldEmailAddress = ?(ProcessingParameters.OldIBUserExists,
			ProcessingParameters.PreviousIBUserDetails.Email, Undefined);
		
		If IBUserDetails.Email <> OldEmailAddress Then
			ChangePasswordRecoveryEmail(UserObject,
				IBUserDetails.Email, OldEmailAddress);
		EndIf;
	EndIf;
	
EndProcedure

// Called when a User or External user is Recorded.
//
// Parameters:
//  UserObject - CatalogObject.Users
//                     - CatalogObject.ExternalUsers
//  ProcessingParameters - Structure
//
Procedure EndIBUserProcessing(UserObject, ProcessingParameters) Export
	
	CheckUserAttributeChanges(UserObject, ProcessingParameters);
	
	// 
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.UsersSaaS") Then
		ModuleUsersInternalSaaS = Common.CommonModule("UsersInternalSaaS");
		ModuleUsersInternalSaaS.BeforeEndIBUserProcessing(UserObject, ProcessingParameters);
	EndIf;
	
	If Not ProcessingParameters.Property("Action") Then
		ProcessingParameters = Undefined;
		Return;
	EndIf;
	
	UpdateRoles = True;
	
	// 
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.UsersSaaS") Then
		ModuleUsersInternalSaaS = Common.CommonModule("UsersInternalSaaS");
		ModuleUsersInternalSaaS.OnEndIBUserProcessing(
			UserObject, ProcessingParameters, UpdateRoles);
	EndIf;
	
	If ProcessingParameters.Property("IBUserSetting") And UpdateRoles Then
		ServiceUserPassword = Undefined;
		If UserObject.AdditionalProperties.Property("ServiceUserPassword") Then
			ServiceUserPassword = UserObject.AdditionalProperties.ServiceUserPassword;
		EndIf;
		
		SSLSubsystemsIntegration.AfterSetIBUser(UserObject.Ref,
			ServiceUserPassword);
	EndIf;
	
	If ProcessingParameters.NewIBUserExists
	   And Users.CanSignIn(ProcessingParameters.NewIBUserDetails1) Then
		
		SetPrivilegedMode(True);
		UpdateInfoOnUserAllowedToSignIn(UserObject.Ref,
			Not ProcessingParameters.OldIBUserExists
			Or Not Users.CanSignIn(ProcessingParameters.PreviousIBUserDetails));
		SetPrivilegedMode(False);
	EndIf;
	
	CopyIBUserSettings(UserObject, ProcessingParameters);
	ProcessingParameters = Undefined;
	
EndProcedure

// Called when processing the userproperty property of the user In the directory.
//
// Parameters:
//  UserDetails   - CatalogRef.Users
//                         - CatalogRef.ExternalUsers
//                         - ValueTableRow
//                         - Structure
//
//  CanSignIn - Boolean -  if False is specified and True is saved, then
//                           the authentication properties are definitely False, since they were removed in the Configurator.
//
// Returns:
//  Structure
//
Function StoredIBUserProperties(UserDetails, CanSignIn = False) Export
	
	Properties = New Structure;
	Properties.Insert("CanSignIn",       False);
	Properties.Insert("StandardAuthentication",    False);
	Properties.Insert("OpenIDAuthentication",         False);
	Properties.Insert("OpenIDConnectAuthentication",  False);
	Properties.Insert("AccessTokenAuthentication", False);
	Properties.Insert("OSAuthentication",             False);
	
	If TypeOf(UserDetails) = Type("CatalogRef.Users")
	 Or TypeOf(UserDetails) = Type("CatalogRef.ExternalUsers") Then
		
		Query = New Query;
		Query.SetParameter("User", UserDetails);
		Query.Text =
		"SELECT
		|	UsersInfo.CanSignIn AS CanSignIn,
		|	UsersInfo.StandardAuthentication AS StandardAuthentication,
		|	UsersInfo.OpenIDAuthentication AS OpenIDAuthentication,
		|	UsersInfo.OpenIDConnectAuthentication AS OpenIDConnectAuthentication,
		|	UsersInfo.AccessTokenAuthentication AS AccessTokenAuthentication,
		|	UsersInfo.OSAuthentication AS OSAuthentication
		|FROM
		|	InformationRegister.UsersInfo AS UsersInfo
		|WHERE
		|	UsersInfo.User = &User";
		Selection = Query.Execute().Select();
		If Not Selection.Next() Then
			Return Properties;
		EndIf;
	Else
		Selection = UserDetails;
	EndIf;
	
	SavedProperties = New Structure(New FixedStructure(Properties));
	FillPropertyValues(SavedProperties, Selection);
	
	For Each KeyAndValue In Properties Do
		If TypeOf(SavedProperties[KeyAndValue.Key]) = Type("Boolean") Then
			Properties[KeyAndValue.Key] = SavedProperties[KeyAndValue.Key];
		EndIf;
	EndDo;
	
	If Properties.CanSignIn And Not CanSignIn Then
		Properties.StandardAuthentication    = False;
		Properties.OpenIDAuthentication         = False;
		Properties.OpenIDConnectAuthentication  = False;
		Properties.AccessTokenAuthentication = False;
		Properties.OSAuthentication             = False;
	EndIf;
	
	Return Properties;
	
EndFunction

Procedure SetStoredPropertiesOfInfobaseUser(UserObject, StoredProperties)
	
	UserObject.AdditionalProperties.Insert("StoredIBUserProperties", StoredProperties);
	
EndProcedure

// You can't call from background tasks with an empty user.
//
// Parameters:
//  IBUserDetails - Structure:
//                            * Roles - Array of String
//                         - InfoBaseUser
//  Text - String - 
//  
// Returns:
//  Boolean
//
Function CreateFirstAdministratorRequired(Val IBUserDetails,
                                              Text = Undefined) Export
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	CurrentIBUser = InfoBaseUsers.CurrentUser();
	
	If Not ValueIsFilled(CurrentIBUser.Name)
	   And InfoBaseUsers.GetUsers().Count() = 0 Then
		
		If TypeOf(IBUserDetails) = Type("Structure") Then
			// 
			
			If IBUserDetails.Property("Roles") Then
				Roles = IBUserDetails.Roles;
			Else
				Roles = New Array;
			EndIf;
			
			If CannotEditRoles()
				Or Roles.Find("FullAccess") = Undefined
				Or Roles.Find("SystemAdministrator") = Undefined Then
				
				// 
				Text =
					NStr("en = 'You are adding the first user to the list of application users.
					           |Therefore, the user will be automatically granted ""Full access"" and ""System administrator"" roles.
					           |Do you want to continue?';");
				
				If Not CannotEditRoles() Then
					Return True;
				EndIf;
				
				SSLSubsystemsIntegration.OnDefineQuestionTextBeforeWriteFirstAdministrator(Text);
				
				Return True;
			EndIf;
		Else
			// 
			Text =
				NStr("en = 'The first infobase user must be a full access user.
				           |External users cannot have full access.
				           |Before creating an external user, create an administrator in the Users catalog.';");
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// Checks for administrator roles based on the service model.
// 
// Parameters:
//  IBUser - InfoBaseUser - 
//                 - Undefined - 
//  
// Returns:
//  Boolean
//
Function AdministratorRolesAvailable(IBUser = Undefined) Export
	
	If IBUser = Undefined
	 Or IBUser = InfoBaseUsers.CurrentUser() Then
	
		// 
		Return IsInRole(Metadata.Roles.FullAccess)
		     //@skip-check using-isinrole
		     And (IsInRole(Metadata.Roles.SystemAdministrator)
		        Or Common.DataSeparationEnabled() );
		// 
	EndIf;
	
	Return IBUser.Roles.Contains(Metadata.Roles.FullAccess)
	     And (IBUser.Roles.Contains(Metadata.Roles.SystemAdministrator)
	        Or Common.DataSeparationEnabled() );
	
EndFunction

// Checks whether the structure of the information security user description is filled in correctly.
// If errors are found, sets the Failure parameter to True and
// sends error messages.
//
// Parameters:
//  IBUserDetails - Structure -  description
//                 of the information security user to check.
//
//  Cancel        - Boolean -  flag for refusing to perform the operation.
//                 It is set in case of an error.
//
//  IsExternalUser - Boolean -  True if the description
//                 of the is user for an external user is checked.
//
// Returns:
//  Boolean - 
//
Function CheckIBUserDetails(Val IBUserDetails, Cancel, IsExternalUser) Export
	
	If IBUserDetails.Property("Name") Then
		Name = IBUserDetails.Name;
		
		If IsBlankString(Name) Then
			// 
			Common.MessageToUser(
				NStr("en = 'The username is required.';"),, "Name",,Cancel);
			
		ElsIf StrLen(Name) > 64 Then
			// 
			// 
			Common.MessageToUser(
				NStr("en = 'The username exceeds 64 characters.';"),,"Name",,Cancel);
			
		ElsIf StrFind(Name, ":") > 0 Then
			Common.MessageToUser(
				NStr("en = 'The username contains an illegal character "":"".';"),,"Name",,Cancel);
		Else
			SetPrivilegedMode(True);
			IBUser = InfoBaseUsers.FindByName(Name);
			SetPrivilegedMode(False);
			
			If IBUser <> Undefined
			   And IBUser.UUID
			     <> IBUserDetails.IBUserID Then
				
				FoundUser = Undefined;
				UserByIDExists(
					IBUser.UUID, , FoundUser);
				
				If FoundUser = Undefined
				 Or Not Users.IsFullUser() Then
					
					ErrorText = NStr("en = 'The username is not unique.';");
				Else
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'The username is not unique. It belongs to user ""%1"".';"),
						String(FoundUser));
				EndIf;
				
				Common.MessageToUser(
					ErrorText, , "Name", , Cancel);
			EndIf;
		EndIf;
	EndIf;
	If Cancel Then
		Return False;
	EndIf;
	
	If Not IBUserDetails.Property("Password")
	 Or Not ValueIsFilled(IBUserDetails.Password) Then
		
		PasswordPolicyName = PasswordPolicyName(IsExternalUser);
		SetPrivilegedMode(True);
		PasswordPolicy = UserPasswordPolicies.FindByName(PasswordPolicyName);
		If PasswordPolicy = Undefined Then
			PasswordMinLength = GetUserPasswordMinLength();
		Else
			PasswordMinLength = PasswordPolicy.PasswordMinLength;
		EndIf;
		SetPrivilegedMode(False);
		If ValueIsFilled(PasswordMinLength) Then
			If ValueIsFilled(IBUserDetails.IBUserID) Then
				SetPrivilegedMode(True);
				IBUser = InfoBaseUsers.FindByUUID(
					IBUserDetails.IBUserID);
				SetPrivilegedMode(False);
			Else
				IBUser = Undefined;
			EndIf;
			
			IsPasswordSet = IBUserDetails.Property("Password")
				And IBUserDetails.Password <> Undefined;
			
			AuthenticationStandardOld = IBUser <> Undefined
				And IBUser.StandardAuthentication;
			
			If IBUserDetails.Property("StandardAuthentication") Then
				AuthenticationStandardNew = IBUserDetails.StandardAuthentication;
			Else
				AuthenticationStandardNew = AuthenticationStandardOld;
			EndIf;
			CheckBlankPassword =
				Not AuthenticationStandardOld
				And AuthenticationStandardNew
				And (    IBUser = Undefined
				     And Not IsPasswordSet
				   Or IBUser <> Undefined
				     And Not IBUser.PasswordIsSet);
			
			If IsPasswordSet Or CheckBlankPassword Then
				Common.MessageToUser(
					NStr("en = 'Set a password.';"),, "ChangePassword",, Cancel);
			EndIf;
		EndIf;
	EndIf;
	
	If IBUserDetails.Property("OSUser") Then
		
		If Not IsBlankString(IBUserDetails.OSUser)
		   And Not StandardSubsystemsServer.IsTrainingPlatform() Then
			
			SetPrivilegedMode(True);
			Try
				IBUser = InfoBaseUsers.CreateUser();
				IBUser.OSUser = IBUserDetails.OSUser;
			Except
				Common.MessageToUser(
					NStr("en = 'The operating system username must have the following format:
					           |""\\Domain Name\Username"".';"),,"OSUser",,Cancel);
			EndTry;
			SetPrivilegedMode(False);
		EndIf;
		
	EndIf;
	
	If IBUserDetails.Property("Email")
		And IBUserDetails.Property("CannotRecoveryPassword") Then
		
		If Not IBUserDetails.CannotRecoveryPassword
		   And IsBlankString(IBUserDetails.Email) Then
				
				Common.MessageToUser(
					NStr("en = 'Email to recover the password is not filled in.';"),,
					"ContactInformation",,Cancel);
		EndIf;
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

// Returns:
//  Structure:
//   
//                         * Key - CatalogRef.Users
//                                - CatalogRef.ExternalUsers -  fills in the match
//                                  with users for whom there are changes.
//                         * Value - Undefined
//
//   :
//                         * Key - CatalogRef.UserGroups
//                                - CatalogRef.ExternalUsersGroups -  fills in the correspondence
//                                  with the user groups for which there are changes.
//                         * Value - Undefined
//
//    See NewChangeInRegistrableGroupMembership
//                  - Undefined - 
//
Function GroupsCompositionNewChanges() Export
	
	Result = New Structure;
	Result.Insert("ItemsToChange", New Map);
	Result.Insert("ModifiedGroups", New Map);
	Result.Insert("ForRegistration", Undefined);
	
	If UsersInternalCached.ShouldRegisterChangesInAccessRights() Then
		Result.ForRegistration = NewChangeInRegistrableGroupMembership();
	EndIf;
	
	Return Result;
	
EndFunction

// Returns:
//  ValueTable:
//   * UsersGroup - CatalogRef.UserGroups
//                         - CatalogRef.ExternalUsersGroups
//   * User        - CatalogRef.Users
//                         - CatalogRef.ExternalUsers
//   * Used        - Boolean
//   * ChangeType        - String - 
//
Function NewChangeInRegistrableGroupMembership() Export
	
	Dimensions = Metadata.InformationRegisters.UserGroupCompositions.Dimensions;
	
	Result = New ValueTable;
	Result.Columns.Add("UsersGroup", Dimensions.UsersGroup.Type);
	Result.Columns.Add("User",        Dimensions.User.Type);
	Result.Columns.Add("Used",        New TypeDescription("Boolean"));
	Result.Columns.Add("ChangeType",        New TypeDescription("String"));
	
	Result.Indexes.Add("User, UsersGroup");
	
	Return Result;
	
EndFunction

// 
// 
// 
//
// Parameters:
//  Group - CatalogRef.UserGroups
//         - CatalogRef.ExternalUsersGroups - 
//             
//
//  ChangesInComposition - See GroupsCompositionNewChanges
//
//  Check - Boolean - 
//
Procedure UpdateGroupsHierarchy(Group, ChangesInComposition, Check = True) Export
	
	// 
	// 
	// 
	//    
	// 
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("Group", Group);
	Query.Text =
	"SELECT
	|	CurrentTable.Ref AS Ref
	|FROM
	|	Catalog.UserGroups AS CurrentTable
	|WHERE
	|	CurrentTable.Ref IN HIERARCHY(&Group)
	|TOTALS BY
	|	Ref HIERARCHY";
	
	If TypeOf(Group) = Type("CatalogRef.ExternalUsersGroups") Then
		Query.Text = StrReplace(Query.Text,
			"Catalog.UserGroups", "Catalog.ExternalUsersGroups");
	EndIf;
	
	If ValueIsFilled(Group) Then
		Parent = Common.ObjectAttributeValue(Group, "Parent");
	Else
		Parent = Group;
	EndIf;
	
	Block = New DataLock;
	// 
	LockItem = Block.Add("InformationRegister.UserGroupsHierarchy");
	LockItem.DataSource = Query.Execute();
	LockItem.UseFromDataSource("UsersGroup", "Ref");
	
	Updated3 = False;
	BeginTransaction();
	Try
		Block.Lock();
		
		RecordSet = InformationRegisters.UserGroupsHierarchy.CreateRecordSet();
		If ValueIsFilled(Parent) Then
			RecordSet.Filter.UsersGroup.Set(Parent);
			RecordSet.Read();
		EndIf;
		NewParents = RecordSet.Unload();
		NewParents.Sort("LevelOfParent Asc");
		NewParents.Indexes.Add("UsersGroup, Parent, LevelOfParent, GroupLevel");
		If NewParents.Count() > 0 Or Not ValueIsFilled(Parent) Then
			LevelOfParent = ?(ValueIsFilled(Parent),
				NewParents.Get(NewParents.Count() - 1).LevelOfParent, 0);
			Tree = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
			
			TreeRows = Tree.Rows;
			If ValueIsFilled(Group) Then
				While True Do
					If TreeRows.Count() <> 1 Then
						TreeRows = Undefined;
						Break;
					ElsIf TreeRows[0].Ref = Group Then
						Break;
					Else
						TreeRows = TreeRows[0].Rows;
					EndIf;
				EndDo;
			EndIf;
			
			If TreeRows <> Undefined Then
				WriteNewGroupParents(TreeRows,
					NewParents, LevelOfParent, ChangesInComposition, Check);
				Updated3 = True;
			EndIf;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Not Updated3 Then
		EmptyGroup1 = ?(TypeOf(Group) = Type("CatalogRef.ExternalUsersGroups"),
			Catalogs.UserGroups.EmptyRef(),
			Catalogs.ExternalUsersGroups.EmptyRef());
		UpdateGroupsHierarchy(EmptyGroup1, ChangesInComposition);
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	UserGroupsHierarchy.UsersGroup AS UsersGroup
	|FROM
	|	InformationRegister.UserGroupsHierarchy AS UserGroupsHierarchy
	|WHERE
	|	UserGroupsHierarchy.UsersGroup = UNDEFINED
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	UserGroupsHierarchy.UsersGroup
	|FROM
	|	InformationRegister.UserGroupsHierarchy AS UserGroupsHierarchy
	|WHERE
	|	UserGroupsHierarchy.UsersGroup = VALUE(Catalog.UserGroups.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	UserGroupsHierarchy.UsersGroup
	|FROM
	|	InformationRegister.UserGroupsHierarchy AS UserGroupsHierarchy
	|WHERE
	|	UserGroupsHierarchy.UsersGroup = VALUE(Catalog.ExternalUsersGroups.EmptyRef)";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RecordSet = InformationRegisters.UserGroupsHierarchy.CreateRecordSet();
		RecordSet.Filter.UsersGroup.Set(Selection.UsersGroup);
		RecordSet.Write(); // 
		ChangesInComposition.ModifiedGroups.Insert(Selection.UsersGroup);
	EndDo;
	
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
//   See GroupsCompositionNewChanges
//
Procedure UpdateAllUsersGroupComposition(User, ChangesInComposition) Export
	
	If TypeOf(User) = Type("Array")
	   And Not ValueIsFilled(User) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&AllUsersGroup AS UsersGroup,
	|	Users.Ref AS User,
	|	NOT Users.DeletionMark
	|		AND NOT Users.Invalid AS Used,
	|	UserGroupCompositions.Used AS UsedFlagPreviousState
	|FROM
	|	Catalog.Users AS Users
	|		LEFT JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		ON (UserGroupCompositions.UsersGroup = &AllUsersGroup)
	|			AND (UserGroupCompositions.User = Users.Ref)
	|WHERE
	|	&FilterUser
	|	AND (UserGroupCompositions.User IS NULL
	|			OR ISNULL(UserGroupCompositions.Used, FALSE) <> (NOT Users.DeletionMark
	|				AND NOT Users.Invalid))
	|
	|UNION ALL
	|
	|SELECT
	|	Users.Ref,
	|	Users.Ref,
	|	NOT Users.DeletionMark
	|		AND NOT Users.Invalid,
	|	UserGroupCompositions.Used
	|FROM
	|	Catalog.Users AS Users
	|		LEFT JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		ON (UserGroupCompositions.UsersGroup = Users.Ref)
	|			AND (UserGroupCompositions.User = Users.Ref)
	|WHERE
	|	&FilterUser
	|	AND (UserGroupCompositions.User IS NULL
	|			OR ISNULL(UserGroupCompositions.Used, FALSE) <> (NOT Users.DeletionMark
	|				AND NOT Users.Invalid))
	|
	|UNION ALL
	|
	|SELECT
	|	UserGroupCompositions.UsersGroup,
	|	UserGroupCompositions.User,
	|	NULL,
	|	UserGroupCompositions.Used
	|FROM
	|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|WHERE
	|	UserGroupCompositions.UsersGroup = UNDEFINED
	|
	|UNION ALL
	|
	|SELECT
	|	UserGroupCompositions.UsersGroup,
	|	UserGroupCompositions.User,
	|	NULL,
	|	UserGroupCompositions.Used
	|FROM
	|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|WHERE
	|	UserGroupCompositions.User = UNDEFINED
	|
	|UNION ALL
	|
	|SELECT
	|	UserGroupCompositions.UsersGroup,
	|	UserGroupCompositions.User,
	|	NULL,
	|	UserGroupCompositions.Used
	|FROM
	|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|WHERE
	|	UserGroupCompositions.UsersGroup = VALUE(Catalog.UserGroups.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	UserGroupCompositions.UsersGroup,
	|	UserGroupCompositions.User,
	|	NULL,
	|	UserGroupCompositions.Used
	|FROM
	|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|WHERE
	|	UserGroupCompositions.User = VALUE(Catalog.Users.EmptyRef)";
	
	ForExternalUsers = Type("CatalogRef.ExternalUsers")
		= TypeOf(?(TypeOf(User) = Type("Array"), User[0], User));
	
	If ForExternalUsers Then
		Query.Text = StrReplace(Query.Text,
			"Catalog.Users", "Catalog.ExternalUsers");
		Query.Text = StrReplace(Query.Text,
			"Catalog.UserGroups", "Catalog.ExternalUsersGroups");
		AllUsersGroup = ExternalUsers.AllExternalUsersGroup();
	Else
		AllUsersGroup = Users.AllUsersGroup();
	EndIf;
	
	Query.SetParameter("AllUsersGroup", AllUsersGroup);
	
	If Not ValueIsFilled(User) Then
		Query.Text = StrReplace(Query.Text, "&FilterUser", "TRUE");
	Else
		Query.SetParameter("User", User);
		Query.Text = StrReplace(Query.Text,
			"&FilterUser", "Users.Ref IN (&User)");
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.UserGroupCompositions");
	LockItem.DataSource = QueryResult;
	LockItem.UseFromDataSource("UsersGroup", "UsersGroup");
	LockItem.UseFromDataSource("User", "User");
	
	ItemsToChange = ChangesInComposition.ItemsToChange;
	ModifiedGroups   = ChangesInComposition.ModifiedGroups;
	ForRegistration     = ChangesInComposition.ForRegistration;
	
	BeginTransaction();
	Try
		Block.Lock();
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			RecordSet = InformationRegisters.UserGroupCompositions.CreateRecordSet();
			RecordSet.AdditionalProperties.Insert("IsStandardRegisterUpdate");
			Record = RecordSet.Add();
			Selection = QueryResult.Select();
			
			While Selection.Next() Do
				If Selection.Used = Null Then
					RecordSetIsEmpty = InformationRegisters.UserGroupCompositions.CreateRecordSet();
					RecordSetIsEmpty.Filter.UsersGroup.Set(Selection.UsersGroup);
					RecordSetIsEmpty.Filter.User.Set(Selection.User);
					RecordSetIsEmpty.Write(); // 
				Else
					RecordSet.Filter.UsersGroup.Set(Selection.UsersGroup);
					RecordSet.Filter.User.Set(Selection.User);
					FillPropertyValues(Record, Selection);
					RecordSet.Write(); // 
				EndIf;
				
				ModifiedGroups.Insert(Selection.UsersGroup);
				ItemsToChange.Insert(Selection.User);
				If ForRegistration <> Undefined Then
					AddCompositionChange(ForRegistration, Selection);
				EndIf;
			EndDo;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// 
// 
// 
// 
// 
//
// Parameters:
//  UsersGroup - CatalogRef.UserGroups
//                      - CatalogRef.ExternalUsersGroups - 
//                          
//                      - Array of CatalogRef.UserGroups
//                      - Array of CatalogRef.ExternalUsersGroups
//
//  ChangesInComposition - See GroupsCompositionNewChanges
//  IsGroupDeletion    - Boolean - 
//
Procedure UpdateHierarchicalUserGroupCompositions(UsersGroup, ChangesInComposition,
			IsGroupDeletion = False) Export
	
	If TypeOf(UsersGroup) = Type("Array")
	   And Not ValueIsFilled(UsersGroup) Then
		Return;
	EndIf;
	
	If IsGroupDeletion Then
		QueryText =
		"SELECT DISTINCT
		|	UserGroupCompositions.UsersGroup AS UsersGroup,
		|	UserGroupCompositions.User AS User
		|FROM
		|	InformationRegister.UserGroupsHierarchy AS GroupsToUpdate1
		|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
		|		ON (UserGroupCompositions.UsersGroup = GroupsToUpdate1.Parent)
		|			AND (GroupsToUpdate1.UsersGroup = &UsersGroup)
		|		LEFT JOIN InformationRegister.UserGroupsHierarchy AS GroupsToUpdate2
		|			INNER JOIN InformationRegister.UserGroupsHierarchy AS LowerLevelGroups
		|			ON (LowerLevelGroups.Parent = GroupsToUpdate2.Parent)
		|				AND (GroupsToUpdate2.UsersGroup = &UsersGroup)
		|			INNER JOIN Catalog.UserGroups.Content AS UserGroupsComposition
		|			ON (UserGroupsComposition.Ref = LowerLevelGroups.UsersGroup)
		|				AND (UserGroupsComposition.User <> VALUE(Catalog.Users.EmptyRef))
		|				AND (NOT UserGroupsComposition.Ref IN
		|						(SELECT
		|							CAST(LowerLevelGroups.UsersGroup AS Catalog.UserGroups) AS UsersGroup
		|						FROM
		|							InformationRegister.UserGroupsHierarchy AS LowerLevelGroups
		|						WHERE
		|							LowerLevelGroups.Parent = &UsersGroup))
		|		ON (GroupsToUpdate2.Parent = UserGroupCompositions.UsersGroup)
		|			AND (UserGroupsComposition.User = UserGroupCompositions.User)
		|WHERE
		|	UserGroupsComposition.User IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	UNDEFINED AS UsersGroup,
		|	UNDEFINED AS User,
		|	FALSE AS Used
		|WHERE
		|	FALSE";
		
	ElsIf ValueIsFilled(UsersGroup) Then
		QueryText =
		"SELECT DISTINCT
		|	UserGroupCompositions.UsersGroup AS UsersGroup,
		|	UserGroupCompositions.User AS User
		|FROM
		|	InformationRegister.UserGroupsHierarchy AS GroupsToUpdate1
		|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
		|		ON (UserGroupCompositions.UsersGroup = GroupsToUpdate1.Parent)
		|			AND (GroupsToUpdate1.UsersGroup IN (&UsersGroup))
		|		LEFT JOIN InformationRegister.UserGroupsHierarchy AS GroupsToUpdate2
		|			INNER JOIN InformationRegister.UserGroupsHierarchy AS LowerLevelGroups
		|			ON (LowerLevelGroups.Parent = GroupsToUpdate2.Parent)
		|				AND (GroupsToUpdate2.UsersGroup IN (&UsersGroup))
		|			INNER JOIN Catalog.UserGroups.Content AS UserGroupsComposition
		|			ON (UserGroupsComposition.Ref = LowerLevelGroups.UsersGroup)
		|				AND (UserGroupsComposition.User <> VALUE(Catalog.Users.EmptyRef))
		|		ON (GroupsToUpdate2.Parent = UserGroupCompositions.UsersGroup)
		|			AND (UserGroupsComposition.User = UserGroupCompositions.User)
		|WHERE
		|	UserGroupsComposition.User IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GroupsToUpdate.Parent AS UsersGroup,
		|	UserGroupsComposition.User AS User,
		|	NOT GroupsToUpdate.Parent.DeletionMark
		|		AND NOT UserGroupsComposition.User.DeletionMark
		|		AND NOT UserGroupsComposition.User.Invalid AS Used,
		|	UserGroupCompositions.Used AS UsedFlagPreviousState
		|FROM
		|	InformationRegister.UserGroupsHierarchy AS GroupsToUpdate
		|		INNER JOIN InformationRegister.UserGroupsHierarchy AS LowerLevelGroups
		|		ON (LowerLevelGroups.Parent = GroupsToUpdate.Parent)
		|			AND (GroupsToUpdate.UsersGroup IN (&UsersGroup))
		|		INNER JOIN Catalog.UserGroups.Content AS UserGroupsComposition
		|		ON (UserGroupsComposition.Ref = LowerLevelGroups.UsersGroup)
		|			AND (UserGroupsComposition.User <> VALUE(Catalog.Users.EmptyRef))
		|		LEFT JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
		|		ON (UserGroupCompositions.UsersGroup = GroupsToUpdate.Parent)
		|			AND (UserGroupCompositions.User = UserGroupsComposition.User)
		|WHERE
		|	(UserGroupCompositions.User IS NULL
		|			OR ISNULL(UserGroupCompositions.Used, FALSE) <> (NOT GroupsToUpdate.Parent.DeletionMark
		|				AND NOT UserGroupsComposition.User.DeletionMark
		|				AND NOT UserGroupsComposition.User.Invalid))";
	Else
		QueryText =
		"SELECT DISTINCT
		|	UserGroupCompositions.UsersGroup AS UsersGroup,
		|	UserGroupCompositions.User AS User
		|FROM
		|	Catalog.UserGroups AS GroupsToUpdate1
		|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
		|		ON (UserGroupCompositions.UsersGroup = GroupsToUpdate1.Ref)
		|			AND (GroupsToUpdate1.Ref <> &AllUsersGroup)
		|			AND (&FilterForExternalUserGroups1)
		|		LEFT JOIN Catalog.UserGroups AS GroupsToUpdate2
		|			INNER JOIN InformationRegister.UserGroupsHierarchy AS LowerLevelGroups
		|			ON (LowerLevelGroups.Parent = GroupsToUpdate2.Ref)
		|				AND (GroupsToUpdate2.Ref <> &AllUsersGroup)
		|				AND (&FilterForExternalUserGroups2)
		|			INNER JOIN Catalog.UserGroups.Content AS UserGroupsComposition
		|			ON (UserGroupsComposition.Ref = LowerLevelGroups.UsersGroup)
		|				AND (UserGroupsComposition.User <> VALUE(Catalog.Users.EmptyRef))
		|		ON (GroupsToUpdate2.Ref = UserGroupCompositions.UsersGroup)
		|			AND (UserGroupsComposition.User = UserGroupCompositions.User)
		|WHERE
		|	UserGroupsComposition.User IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GroupsToUpdate.Ref AS UsersGroup,
		|	UserGroupsComposition.User AS User,
		|	NOT GroupsToUpdate.DeletionMark
		|		AND NOT UserGroupsComposition.User.DeletionMark
		|		AND NOT UserGroupsComposition.User.Invalid AS Used,
		|	UserGroupCompositions.Used AS UsedFlagPreviousState
		|FROM
		|	Catalog.UserGroups AS GroupsToUpdate
		|		INNER JOIN InformationRegister.UserGroupsHierarchy AS LowerLevelGroups
		|		ON (LowerLevelGroups.Parent = GroupsToUpdate.Ref)
		|			AND (GroupsToUpdate.Ref <> &AllUsersGroup)
		|			AND (&FilterForExternalUserGroups0)
		|		INNER JOIN Catalog.UserGroups.Content AS UserGroupsComposition
		|		ON (UserGroupsComposition.Ref = LowerLevelGroups.UsersGroup)
		|			AND (UserGroupsComposition.User <> VALUE(Catalog.Users.EmptyRef))
		|		LEFT JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
		|		ON (UserGroupCompositions.UsersGroup = GroupsToUpdate.Ref)
		|			AND (UserGroupCompositions.User = UserGroupsComposition.User)
		|WHERE
		|	(UserGroupCompositions.User IS NULL
		|			OR ISNULL(UserGroupCompositions.Used, FALSE) <> (NOT GroupsToUpdate.DeletionMark
		|				AND NOT UserGroupsComposition.User.DeletionMark
		|				AND NOT UserGroupsComposition.User.Invalid))";
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("UsersGroup", UsersGroup);
	
	ForExternalUsers = Type("CatalogRef.ExternalUsersGroups")
		= TypeOf(?(TypeOf(UsersGroup) = Type("Array"), UsersGroup[0], UsersGroup));
	
	If ForExternalUsers Then
		Query.SetParameter("AllUsersGroup", ExternalUsers.AllExternalUsersGroup());
		Query.Text = StrReplace(Query.Text, "Catalog.UserGroups",
			"Catalog.ExternalUsersGroups");
		Query.Text = StrReplace(Query.Text, "Catalog.Users",
			"Catalog.ExternalUsers");
		Query.Text = StrReplace(Query.Text, "UserGroupsComposition.User",
			"UserGroupsComposition.ExternalUser");
	EndIf;
	
	If Not ValueIsFilled(UsersGroup) Then
		If ForExternalUsers Then
			Query.SetParameter("AllUsersGroup", ExternalUsers.AllExternalUsersGroup());
			Query.Text = StrReplace(Query.Text, "&FilterForExternalUserGroups0",
				"NOT GroupsToUpdate.AllAuthorizationObjects");
			Query.Text = StrReplace(Query.Text, "&FilterForExternalUserGroups1",
				"NOT GroupsToUpdate1.AllAuthorizationObjects");
			Query.Text = StrReplace(Query.Text, "&FilterForExternalUserGroups2",
				"NOT GroupsToUpdate2.AllAuthorizationObjects");
		Else
			Query.SetParameter("AllUsersGroup", Users.AllUsersGroup());
			Query.Text = StrReplace(Query.Text, "&FilterForExternalUserGroups0", "TRUE");
			Query.Text = StrReplace(Query.Text, "&FilterForExternalUserGroups1", "TRUE");
			Query.Text = StrReplace(Query.Text, "&FilterForExternalUserGroups2", "TRUE");
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryResults = Query.ExecuteBatch();
	If QueryResults[0].IsEmpty() And QueryResults[1].IsEmpty() Then
		Return;
	EndIf;
	
	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.UserGroupCompositions");
	LockItem.DataSource = QueryResults[0];
	LockItem.UseFromDataSource("UsersGroup", "UsersGroup");
	LockItem.UseFromDataSource("User", "User");
	
	LockItem = Block.Add("InformationRegister.UserGroupCompositions");
	LockItem.DataSource = QueryResults[1];
	LockItem.UseFromDataSource("UsersGroup", "UsersGroup");
	LockItem.UseFromDataSource("User", "User");
	
	ItemsToChange = ChangesInComposition.ItemsToChange;
	ModifiedGroups   = ChangesInComposition.ModifiedGroups;
	ForRegistration     = ChangesInComposition.ForRegistration;
	
	BeginTransaction();
	Try
		Block.Lock();
		QueryResults = Query.ExecuteBatch();
		
		If Not QueryResults[0].IsEmpty() Then
			RecordSet = InformationRegisters.UserGroupCompositions.CreateRecordSet();
			RecordSet.AdditionalProperties.Insert("IsStandardRegisterUpdate");
			Selection = QueryResults[0].Select();
			
			While Selection.Next() Do
				RecordSet.Filter.UsersGroup.Set(Selection.UsersGroup);
				RecordSet.Filter.User.Set(Selection.User);
				RecordSet.Write(); // 
				
				ItemsToChange.Insert(Selection.User);
				ModifiedGroups.Insert(Selection.UsersGroup);
				If ForRegistration <> Undefined Then
					AddCompositionChange(ForRegistration, Selection, True);
				EndIf;
			EndDo;
		EndIf;
		
		If Not QueryResults[1].IsEmpty() Then
			RecordSet = InformationRegisters.UserGroupCompositions.CreateRecordSet();
			RecordSet.AdditionalProperties.Insert("IsStandardRegisterUpdate");
			Record = RecordSet.Add();
			Selection = QueryResults[1].Select();
			
			While Selection.Next() Do
				RecordSet.Filter.UsersGroup.Set(Selection.UsersGroup);
				RecordSet.Filter.User.Set(Selection.User);
				FillPropertyValues(Record, Selection);
				RecordSet.Write(); // 
				
				ItemsToChange.Insert(Selection.User);
				ModifiedGroups.Insert(Selection.UsersGroup);
				If ForRegistration <> Undefined Then
					AddCompositionChange(ForRegistration, Selection);
				EndIf;
			EndDo;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// 
// 
//
// Parameters:
//  User - CatalogRef.Users
//               - CatalogRef.ExternalUsers - 
//                   
//               - Array of CatalogRef.Users
//               - Array of CatalogRef.ExternalUsers
//
//  ChangesInComposition - See GroupsCompositionNewChanges
//
Procedure UpdateUserGroupCompositionUsage(User, ChangesInComposition) Export
	
	If TypeOf(User) = Type("Array")
	   And Not ValueIsFilled(User) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("User", User);
	Query.Text =
	"SELECT
	|	UserGroupCompositions.UsersGroup AS UsersGroup,
	|	UserGroupCompositions.User AS User,
	|	NOT ISNULL(UserGroups.DeletionMark, TRUE)
	|		AND NOT ISNULL(Users.DeletionMark, TRUE)
	|		AND NOT ISNULL(Users.Invalid, TRUE) AS Used,
	|	UserGroupCompositions.Used AS UsedFlagPreviousState
	|FROM
	|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		LEFT JOIN Catalog.Users AS Users
	|		ON (Users.Ref = UserGroupCompositions.User)
	|		LEFT JOIN Catalog.UserGroups AS UserGroups
	|		ON (UserGroups.Ref = UserGroupCompositions.UsersGroup)
	|WHERE
	|	VALUETYPE(UserGroupCompositions.User) = TYPE(Catalog.Users)
	|	AND VALUETYPE(UserGroupCompositions.UsersGroup) = TYPE(Catalog.UserGroups)
	|	AND UserGroupCompositions.Used <> (NOT ISNULL(UserGroups.DeletionMark, TRUE)
	|			AND NOT ISNULL(Users.DeletionMark, TRUE)
	|			AND NOT ISNULL(Users.Invalid, TRUE))
	|	AND &FilterUser
	|
	|UNION ALL
	|
	|SELECT
	|	UserGroupCompositions.UsersGroup,
	|	UserGroupCompositions.User,
	|	NOT ISNULL(Users.DeletionMark, TRUE)
	|		AND NOT ISNULL(Users.Invalid, TRUE),
	|	UserGroupCompositions.Used
	|FROM
	|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		LEFT JOIN Catalog.Users AS Users
	|		ON (Users.Ref = UserGroupCompositions.User)
	|WHERE
	|	VALUETYPE(UserGroupCompositions.User) = TYPE(Catalog.Users)
	|	AND UserGroupCompositions.UsersGroup = UserGroupCompositions.User
	|	AND UserGroupCompositions.Used <> (NOT ISNULL(Users.DeletionMark, TRUE)
	|			AND NOT ISNULL(Users.Invalid, TRUE))
	|	AND &FilterUser";
	
	If Not ValueIsFilled(User) Then
		Query.Text = StrReplace(Query.Text, "&FilterUser", "TRUE");
	Else
		Query.SetParameter("User", User);
		Query.Text = StrReplace(Query.Text, "&FilterUser",
			"CAST(UserGroupCompositions.User AS Catalog.Users) IN (&User)");
	EndIf;
	
	ForExternalUsers = Type("CatalogRef.ExternalUsers")
		= TypeOf(?(TypeOf(User) = Type("Array"), User[0], User));
	
	If ForExternalUsers Then
		Query.Text = StrReplace(Query.Text,
			"Catalog.Users", "Catalog.ExternalUsers");
		Query.Text = StrReplace(Query.Text,
			"Catalog.UserGroups", "Catalog.ExternalUsersGroups");
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.UserGroupCompositions");
	LockItem.DataSource = QueryResult;
	LockItem.UseFromDataSource("UsersGroup", "UsersGroup");
	LockItem.UseFromDataSource("User", "User");
	
	SetOfOneRecord = InformationRegisters.UserGroupCompositions.CreateRecordSet();
	SetOfOneRecord.AdditionalProperties.Insert("IsStandardRegisterUpdate");
	Record = SetOfOneRecord.Add();
	
	ItemsToChange = ChangesInComposition.ItemsToChange;
	ModifiedGroups   = ChangesInComposition.ModifiedGroups;
	ForRegistration     = ChangesInComposition.ForRegistration;
	
	BeginTransaction();
	Try
		Block.Lock();
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			If Not ValueIsFilled(Selection.UsersGroup)
			 Or Not ValueIsFilled(Selection.User) Then
				Continue;
			EndIf;
			
			SetOfOneRecord.Filter.UsersGroup.Set(Selection.UsersGroup);
			SetOfOneRecord.Filter.User.Set(Selection.User);
			
			Record.UsersGroup = Selection.UsersGroup;
			Record.User        = Selection.User;
			Record.Used        = Selection.Used;
			
			SetOfOneRecord.Write();
			
			ModifiedGroups.Insert(Selection.UsersGroup);
			ItemsToChange.Insert(Selection.User);
			If ForRegistration <> Undefined Then
				AddCompositionChange(ForRegistration, Selection);
			EndIf;
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Parameters:
//  Ref - CatalogRef.Users
//         - CatalogRef.ExternalUsers
//         - CatalogRef.UserGroups
//         - CatalogRef.ExternalUsersGroups
//
Procedure UpdateGroupsCompositionBeforeDeleteUserOrGroup(Ref) Export
	
	ChangesInComposition = GroupsCompositionNewChanges();
	
	If TypeOf(Ref) = Type("CatalogRef.Users")
	 Or TypeOf(Ref) = Type("CatalogRef.ExternalUsers")
	 Or Ref = Users.AllUsersGroup()
	 Or Ref = ExternalUsers.AllExternalUsersGroup()
	 Or TypeOf(Ref) = Type("CatalogRef.ExternalUsersGroups")
	   And Common.ObjectAttributeValue(Ref, "AllAuthorizationObjects") = True Then
		
		UpdateCompositionBeforeDeleteGroupWithoutHierarchyOrUser(Ref, ChangesInComposition);
	Else
		UpdateHierarchicalUserGroupCompositions(Ref, ChangesInComposition, True);
	EndIf;
	
	AfterUserGroupsUpdate(ChangesInComposition);
	
EndProcedure

// Parameters:
//  ChangesInComposition - See GroupsCompositionNewChanges
//  HasChanges - Boolean -  returned value
//
Procedure AfterUserGroupsUpdate(ChangesInComposition, HasChanges = False) Export
	
	If ChangesInComposition.ItemsToChange.Count() = 0
	   And ChangesInComposition.ModifiedGroups.Count() = 0 Then
		Return;
	EndIf;
	
	HasChanges = True;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	RegisterGroupsCompositionChanges(ChangesInComposition.ForRegistration);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	ItemsToChange = New Array;
	For Each KeyAndValue In ChangesInComposition.ItemsToChange Do
		If ValueIsFilled(KeyAndValue.Key) Then
			ItemsToChange.Add(KeyAndValue.Key);
		EndIf;
	EndDo;
	
	ModifiedGroups = New Array;
	For Each KeyAndValue In ChangesInComposition.ModifiedGroups Do
		If ValueIsFilled(KeyAndValue.Key) Then
			ModifiedGroups.Add(KeyAndValue.Key);
		EndIf;
	EndDo;
	
	If ValueIsFilled(ItemsToChange)
	   And TypeOf(ItemsToChange[0]) = Type("CatalogRef.ExternalUsers")
	 Or ValueIsFilled(ModifiedGroups)
	   And TypeOf(ModifiedGroups[0]) = Type("CatalogRef.ExternalUsersGroups") Then
		
		UpdateExternalUsersRoles(ItemsToChange);
	EndIf;
	
	SSLSubsystemsIntegration.AfterUserGroupsUpdate(ItemsToChange,
		ModifiedGroups);
	
EndProcedure

Procedure AddCompositionChange(ForRegistration, Selection, Removed = False)
	
	If Not ValueIsFilled(Selection.UsersGroup)
	 Or Not ValueIsFilled(Selection.User)
	 Or Selection.UsersGroup = Selection.User Then
		Return;
	EndIf;
	
	Filter = New Structure("UsersGroup, User",
		Selection.UsersGroup, Selection.User);
	
	FoundRows = ForRegistration.FindRows(Filter);
	If ValueIsFilled(FoundRows) Then
		String = FoundRows[0];
	Else
		String = ForRegistration.Add();
		FillPropertyValues(String, Filter);
	EndIf;
	
	If Removed Then
		String.ChangeType = "Deleted";
		String.Used = False;
		
	ElsIf Selection.UsedFlagPreviousState = Null Then
		String.ChangeType = "Added2";
		String.Used = Selection.Used;
	Else
		String.ChangeType = "IsChanged";
		String.Used = Selection.Used;
	EndIf;
	
EndProcedure

// Parameters:
//   See NewChangeInRegistrableGroupMembership
//
Procedure RegisterGroupsCompositionChanges(DataForRegistration) Export
	
	If Not ValueIsFilled(DataForRegistration) Then
		Return;
	EndIf;
	ThisisExternalUsers = TypeOf(DataForRegistration[0].User)
		= Type("CatalogRef.ExternalUsers");
	
	Query = New Query;
	Query.SetParameter("ChangesInComposition", DataForRegistration);
	Query.Text =
	"SELECT
	|	ChangesInComposition.UsersGroup AS UsersGroup,
	|	ChangesInComposition.User AS User
	|INTO ChangesInComposition
	|FROM
	|	&ChangesInComposition AS ChangesInComposition
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChangesInComposition.UsersGroup AS UsersGroup,
	|	ChangesInComposition.User AS User
	|FROM
	|	ChangesInComposition AS ChangesInComposition
	|		LEFT JOIN Catalog.UserGroups.Content AS UserGroupsComposition
	|		ON (UserGroupsComposition.Ref = ChangesInComposition.UsersGroup)
	|			AND (UserGroupsComposition.User = ChangesInComposition.User)
	|		LEFT JOIN Catalog.ExternalUsersGroups.Content AS ExternalUserGroupsComposition
	|		ON (ExternalUserGroupsComposition.Ref = ChangesInComposition.UsersGroup)
	|			AND (ExternalUserGroupsComposition.ExternalUser = ChangesInComposition.User)
	|WHERE
	|	(NOT UserGroupsComposition.User IS NULL
	|			OR NOT ExternalUserGroupsComposition.ExternalUser IS NULL)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ISNULL(FolderHierarchy.Parent.Parent, UNDEFINED) AS Parent,
	|	ISNULL(FolderHierarchy.Parent, ChangesInComposition.UsersGroup) AS UsersGroup,
	|	ISNULL(FolderHierarchy.Parent.Description, PRESENTATION(ChangesInComposition.UsersGroup)) AS GroupPresentation
	|FROM
	|	ChangesInComposition AS ChangesInComposition
	|		LEFT JOIN InformationRegister.UserGroupsHierarchy AS FolderHierarchy
	|		ON ChangesInComposition.UsersGroup = FolderHierarchy.UsersGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ChangesInComposition.User AS User,
	|	ISNULL(Users.Description, ISNULL(ExternalUsers.Description, PRESENTATION(ChangesInComposition.User))) AS UserPresentation2
	|FROM
	|	ChangesInComposition AS ChangesInComposition
	|		LEFT JOIN Catalog.Users AS Users
	|		ON (Users.Ref = ChangesInComposition.User)
	|		LEFT JOIN Catalog.ExternalUsers AS ExternalUsers
	|		ON (ExternalUsers.Ref = ChangesInComposition.User)";
	
	IsAccessManagementSubsystemIntegrated = Common.SubsystemExists(
		"StandardSubsystems.AccessManagement");
	
	If IsAccessManagementSubsystemIntegrated Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		Query.SetParameter("AllUsersGroup", ?(ThisisExternalUsers,
			ExternalUsers.AllExternalUsersGroup(), Users.AllUsersGroup()));
		Query.Text = Query.Text
			+ Common.QueryBatchSeparator()
			+ ModuleAccessManagementInternal.QueryTextForAccessGroupsOnUserGroupsMembersChange();
	EndIf;
	
	QueryResults = Query.ExecuteBatch();
	
	Data = New Structure;
	Data.Insert("DataStructureVersion", 2);
	Data.Insert("ChangesInComposition", New Array);
	Data.Insert("GroupsPresentation", New Array);
	Data.Insert("PresentationUsers", New Array);
	
	UsersInGroups = QueryResults[1].Unload();
	UsersInGroups.Indexes.Add("User, UsersGroup");
	Filter = New Structure("User, UsersGroup");
	
	For Each Item In DataForRegistration Do
		FillPropertyValues(Filter, Item);
		UserInGroup = ValueIsFilled(UsersInGroups.FindRows(Filter));
		Properties = New Structure;
		Properties.Insert("GroupID",
			Lower(Item.UsersGroup.UUID()));
		Properties.Insert("UserIdentificator",
			Lower(Item.User.UUID()));
		Properties.Insert("IsBelongToLowerLevelGroup", Not UserInGroup);
		Properties.Insert("Used", Item.Used);
		Properties.Insert("ChangeType", Item.ChangeType);
		Data.ChangesInComposition.Add(Properties);
	EndDo;
	
	Selection = QueryResults[2].Select();
	While Selection.Next() Do
		Properties = New Structure;
		Properties.Insert("ParentID", ?(ValueIsFilled(Selection.Parent),
			Lower(Selection.Parent.UUID()), ""));
		Properties.Insert("GroupID",
			Lower(Selection.UsersGroup.UUID()));
		Properties.Insert("GroupPresentation", Selection.GroupPresentation);
		Properties.Insert("GroupReference", SerializedRef(Selection.UsersGroup));
		Data.GroupsPresentation.Add(Properties);
	EndDo;
	
	Selection = QueryResults[3].Select();
	While Selection.Next() Do
		Properties = New Structure;
		Properties.Insert("UserIdentificator",
			Lower(Selection.User.UUID()));
		Properties.Insert("UserPresentation2", Selection.UserPresentation2);
		Properties.Insert("RefToUser", SerializedRef(Selection.User));
		Data.PresentationUsers.Add(Properties);
	EndDo;
	
	If IsAccessManagementSubsystemIntegrated Then
		Data.Insert("AccessGroupsMembers", New Array);
		Data.Insert("AccessGroupsPresentation", New Array);
		
		Selection = QueryResults[5].Select();
		While Selection.Next() Do
			Properties = New Structure;
			Properties.Insert("AccessGroup", SerializedRef(Selection.AccessGroup));
			Properties.Insert("Member", SerializedRef(Selection.Member));
			Properties.Insert("ValidityPeriod", Selection.ValidityPeriod);
			Data.AccessGroupsMembers.Add(Properties);
		EndDo;
		
		Selection = QueryResults[6].Select();
		While Selection.Next() Do
			Properties = New Structure;
			Properties.Insert("AccessGroup", SerializedRef(Selection.AccessGroup));
			Properties.Insert("Presentation", Selection.Presentation);
			Properties.Insert("DeletionMark", Selection.DeletionMark);
			Properties.Insert("Profile", SerializedRef(Selection.Profile));
			Properties.Insert("ProfilePresentation", Selection.ProfilePresentation);
			Properties.Insert("ProfileDeletionMark", Selection.ProfileDeletionMark);
			Data.AccessGroupsPresentation.Add(Properties);
		EndDo;
	EndIf;
	
	If ThisisExternalUsers Then
		EventName = NameOfLogEventExternalUserGroupsMembersChanged();
	Else
		EventName = NameOfLogEventUserGroupsMembersChanged();
	EndIf;
	
	WriteLogEvent(EventName,
		EventLogLevel.Information,
		Metadata.InformationRegisters.UserGroupCompositions,
		Common.ValueToXMLString(Data),
		,
		EventLogEntryTransactionMode.Transactional);
	
	
	If Not Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	AccessGroupModule = Common.CommonModule("Catalogs.AccessGroups");
	
	ObjectDetails = New Structure("ChangeInUserGroupsMembership", DataForRegistration);
	AccessGroupModule.RegisterChangeInAllowedValues(ObjectDetails, Undefined);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
//
// Parameters:
//  ExternalUsersGroup - CatalogRef.ExternalUsersGroups
//                             - Array of CatalogRef.ExternalUsersGroups
//                             - Undefined - 
//
//  ExternalUser - CatalogRef.ExternalUsers
//                      - Array of CatalogRef.ExternalUsers
//                      - Undefined - 
//
//  ChangesInComposition - See GroupsCompositionNewChanges
//
Procedure UpdateGroupCompositionsByAuthorizationObjectType(ExternalUsersGroup,
			ExternalUser, ChangesInComposition) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UserGroupCompositions.UsersGroup AS UsersGroup,
	|	UserGroupCompositions.User AS User
	|FROM
	|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		LEFT JOIN Catalog.ExternalUsers AS ExternalUsers
	|			INNER JOIN Catalog.ExternalUsersGroups AS ExternalUsersGroups
	|			ON (ExternalUsersGroups.AllAuthorizationObjects = TRUE)
	|				AND (&FilterExternalUsersGroups1)
	|				AND (TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						Catalog.ExternalUsersGroups.Purpose AS UsersTypes
	|					WHERE
	|						UsersTypes.Ref = ExternalUsersGroups.Ref
	|						AND VALUETYPE(UsersTypes.UsersType) = VALUETYPE(ExternalUsers.AuthorizationObject)))
	|				AND (&ExternalUserFilter1)
	|		ON (ExternalUsersGroups.Ref = UserGroupCompositions.UsersGroup)
	|			AND (ExternalUsers.Ref = UserGroupCompositions.User)
	|WHERE
	|	VALUETYPE(UserGroupCompositions.UsersGroup) = TYPE(Catalog.ExternalUsersGroups)
	|	AND ISNULL(CAST(UserGroupCompositions.UsersGroup AS Catalog.ExternalUsersGroups).AllAuthorizationObjects, FALSE) = TRUE
	|	AND &FilterExternalUsersGroups2
	|	AND &ExternalUserFilter2
	|	AND ExternalUsersGroups.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExternalUsersGroups.Ref AS UsersGroup,
	|	ExternalUsers.Ref AS User,
	|	NOT ExternalUsersGroups.DeletionMark
	|		AND NOT ExternalUsers.DeletionMark
	|		AND NOT ExternalUsers.Invalid AS Used,
	|	UserGroupCompositions.Used AS UsedFlagPreviousState
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|		INNER JOIN Catalog.ExternalUsersGroups AS ExternalUsersGroups
	|		ON (ExternalUsersGroups.AllAuthorizationObjects = TRUE)
	|			AND (&FilterExternalUsersGroups1)
	|			AND (TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.ExternalUsersGroups.Purpose AS UsersTypes
	|				WHERE
	|					UsersTypes.Ref = ExternalUsersGroups.Ref
	|					AND VALUETYPE(UsersTypes.UsersType) = VALUETYPE(ExternalUsers.AuthorizationObject)))
	|			AND (&ExternalUserFilter1)
	|		LEFT JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		ON (UserGroupCompositions.UsersGroup = ExternalUsersGroups.Ref)
	|			AND (UserGroupCompositions.User = ExternalUsers.Ref)
	|WHERE
	|	(UserGroupCompositions.User IS NULL
	|			OR ISNULL(UserGroupCompositions.Used, FALSE) = (NOT ExternalUsersGroups.DeletionMark
	|				AND NOT ExternalUsers.DeletionMark
	|				AND NOT ExternalUsers.Invalid))";
	
	If ExternalUsersGroup = Undefined Then
		Query.Text = StrReplace(Query.Text, "&FilterExternalUsersGroups1", "TRUE");
		Query.Text = StrReplace(Query.Text, "&FilterExternalUsersGroups2", "TRUE");
	Else
		Query.SetParameter("ExternalUsersGroup", ExternalUsersGroup);
		Query.Text = StrReplace(
			Query.Text,
			"&FilterExternalUsersGroups1",
			"ExternalUsersGroups.Ref IN (&ExternalUsersGroup)");
		Query.Text = StrReplace(
			Query.Text,
			"&FilterExternalUsersGroups2",
			"UserGroupCompositions.UsersGroup IN (&ExternalUsersGroup)");
	EndIf;
	
	If ExternalUser = Undefined Then
		Query.Text = StrReplace(Query.Text, "&ExternalUserFilter1", "TRUE");
		Query.Text = StrReplace(Query.Text, "&ExternalUserFilter2", "TRUE");
	Else
		Query.SetParameter("ExternalUser", ExternalUser);
		Query.Text = StrReplace(Query.Text,
			"&ExternalUserFilter1",
			"ExternalUsers.Ref IN (&ExternalUser)");
		Query.Text = StrReplace(Query.Text,
			"&ExternalUserFilter2",
			"UserGroupCompositions.User IN (&ExternalUser)");
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryResults = Query.ExecuteBatch();
	If QueryResults[0].IsEmpty() And QueryResults[1].IsEmpty() Then
		Return;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.UserGroupCompositions");
	LockItem.DataSource = QueryResults[0];
	LockItem.UseFromDataSource("UsersGroup", "UsersGroup");
	LockItem.UseFromDataSource("User", "User");
	
	LockItem = Block.Add("InformationRegister.UserGroupCompositions");
	LockItem.DataSource = QueryResults[1];
	LockItem.UseFromDataSource("UsersGroup", "UsersGroup");
	LockItem.UseFromDataSource("User", "User");
	
	ItemsToChange = ChangesInComposition.ItemsToChange;
	ModifiedGroups   = ChangesInComposition.ModifiedGroups;
	ForRegistration     = ChangesInComposition.ForRegistration;
	
	BeginTransaction();
	Try
		Block.Lock();
		QueriesResults = Query.ExecuteBatch();
		
		If Not QueriesResults[0].IsEmpty() Then
			RecordSet = InformationRegisters.UserGroupCompositions.CreateRecordSet();
			RecordSet.AdditionalProperties.Insert("IsStandardRegisterUpdate");
			Selection = QueriesResults[0].Select();
			
			While Selection.Next() Do
				RecordSet.Filter.UsersGroup.Set(Selection.UsersGroup);
				RecordSet.Filter.User.Set(Selection.User);
				RecordSet.Write(); // 
				
				ItemsToChange.Insert(Selection.User);
				ModifiedGroups.Insert(Selection.UsersGroup);
				If ForRegistration <> Undefined Then
					AddCompositionChange(ForRegistration, Selection, True);
				EndIf;
			EndDo;
		EndIf;
		
		If Not QueriesResults[1].IsEmpty() Then
			RecordSet = InformationRegisters.UserGroupCompositions.CreateRecordSet();
			RecordSet.AdditionalProperties.Insert("IsStandardRegisterUpdate");
			Record = RecordSet.Add();
			Selection = QueriesResults[1].Select();
			
			While Selection.Next() Do
				RecordSet.Filter.UsersGroup.Set(Selection.UsersGroup);
				RecordSet.Filter.User.Set(Selection.User);
				FillPropertyValues(Record, Selection);
				RecordSet.Write(); // 
				
				ItemsToChange.Insert(Selection.User);
				ModifiedGroups.Insert(Selection.UsersGroup);
				If ForRegistration <> Undefined Then
					AddCompositionChange(ForRegistration, Selection);
				EndIf;
			EndDo;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Updates the list of database user roles that correspond
// to external users. The role composition is calculated based on the membership of external
// users in groups of external users, except for those external users
// for whom the roles are set directly.
//  Required only when you edit permissions to roles, for example, if
// integrated subsystem of access Control, this procedure is not required.
// 
// Parameters:
//  ExternalUsersArray - Undefined - 
//                             - CatalogRef.ExternalUsersGroups
//                             - Array of CatalogRef.ExternalUsers
//
Procedure UpdateExternalUsersRoles(Val ExternalUsersArray = Undefined) Export
	
	If CannotEditRoles() Then
		// 
		Return;
	EndIf;
	
	If TypeOf(ExternalUsersArray) = Type("Array")
	   And ExternalUsersArray.Count() = 0 Then
		
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		If TypeOf(ExternalUsersArray) <> Type("Array") Then
			
			If ExternalUsersArray = Undefined Then
				ExternalUsersGroup = ExternalUsers.AllExternalUsersGroup();
			Else
				ExternalUsersGroup = ExternalUsersArray;
			EndIf;
			
			Query = New Query;
			Query.SetParameter("ExternalUsersGroup", ExternalUsersGroup);
			Query.Text =
			"SELECT
			|	UserGroupCompositions.User
			|FROM
			|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
			|WHERE
			|	UserGroupCompositions.UsersGroup = &ExternalUsersGroup";
			
			ExternalUsersArray = Query.Execute().Unload().UnloadColumn("User");
		EndIf;
		
		Users.FindAmbiguousIBUsers(Undefined);
		
		IBUsersIDs = New Map;
		
		Query = New Query;
		Query.SetParameter("ExternalUsers", ExternalUsersArray);
		Query.Text =
		"SELECT
		|	ExternalUsers.Ref AS ExternalUser,
		|	ExternalUsers.IBUserID
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|WHERE
		|	ExternalUsers.Ref IN(&ExternalUsers)
		|	AND (NOT ExternalUsers.SetRolesDirectly)";
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			IBUsersIDs.Insert(
				Selection.ExternalUser, Selection.IBUserID);
		EndDo;
		
		// 
		OldExternalUserRoles = New ValueTable;
		
		OldExternalUserRoles.Columns.Add(
			"ExternalUser", New TypeDescription("CatalogRef.ExternalUsers"));
		
		OldExternalUserRoles.Columns.Add(
			"Role", New TypeDescription("String", , New StringQualifiers(200)));
		
		CurrentNumber = ExternalUsersArray.Count() - 1;
		While CurrentNumber >= 0 Do
			
			// 
			IBUser = Undefined;
			IBUserID = IBUsersIDs[ExternalUsersArray[CurrentNumber]];
			If IBUserID <> Undefined Then
				
				IBUser = InfoBaseUsers.FindByUUID(
					IBUserID);
			EndIf;
			
			If IBUser = Undefined
			 Or IsBlankString(IBUser.Name) Then
				
				ExternalUsersArray.Delete(CurrentNumber);
			Else
				For Each Role In IBUser.Roles Do
					PreviousExternalUserRole = OldExternalUserRoles.Add();
					PreviousExternalUserRole.ExternalUser = ExternalUsersArray[CurrentNumber];
					PreviousExternalUserRole.Role = Role.Name;
				EndDo;
			EndIf;
			CurrentNumber = CurrentNumber - 1;
		EndDo;
		
		// 
		Query = New Query;
		Query.TempTablesManager = New TempTablesManager;
		Query.SetParameter("ExternalUsers", ExternalUsersArray);
		Query.SetParameter("AllRoles", AllRoles().Table.Get());
		Query.SetParameter("OldExternalUserRoles", OldExternalUserRoles);
		Query.SetParameter("UseExternalUsers",
			GetFunctionalOption("UseExternalUsers"));
		// 
		// 
		Query.Text =
		"SELECT
		|	OldExternalUserRoles.ExternalUser,
		|	OldExternalUserRoles.Role
		|INTO OldExternalUserRoles
		|FROM
		|	&OldExternalUserRoles AS OldExternalUserRoles
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllRoles.Name
		|INTO AllRoles
		|FROM
		|	&AllRoles AS AllRoles
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	UserGroupCompositions.UsersGroup AS ExternalUsersGroup,
		|	UserGroupCompositions.User AS ExternalUser,
		|	Roles.Role.Name AS Role
		|INTO AllNewExternalUserRoles
		|FROM
		|	Catalog.ExternalUsersGroups.Roles AS Roles
		|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
		|		ON (UserGroupCompositions.User IN (&ExternalUsers))
		|			AND (UserGroupCompositions.UsersGroup = Roles.Ref)
		|			AND (&UseExternalUsers = TRUE)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	AllNewExternalUserRoles.ExternalUser,
		|	AllNewExternalUserRoles.Role
		|INTO NewExternalUserRoles
		|FROM
		|	AllNewExternalUserRoles AS AllNewExternalUserRoles
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OldExternalUserRoles.ExternalUser
		|INTO ModifiedExternalUsers
		|FROM
		|	OldExternalUserRoles AS OldExternalUserRoles
		|		LEFT JOIN NewExternalUserRoles AS NewExternalUserRoles
		|		ON (NewExternalUserRoles.ExternalUser = OldExternalUserRoles.ExternalUser)
		|			AND (NewExternalUserRoles.Role = OldExternalUserRoles.Role)
		|WHERE
		|	NewExternalUserRoles.Role IS NULL 
		|
		|UNION
		|
		|SELECT
		|	NewExternalUserRoles.ExternalUser
		|FROM
		|	NewExternalUserRoles AS NewExternalUserRoles
		|		LEFT JOIN OldExternalUserRoles AS OldExternalUserRoles
		|		ON NewExternalUserRoles.ExternalUser = OldExternalUserRoles.ExternalUser
		|			AND NewExternalUserRoles.Role = OldExternalUserRoles.Role
		|WHERE
		|	OldExternalUserRoles.Role IS NULL 
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllNewExternalUserRoles.ExternalUsersGroup,
		|	AllNewExternalUserRoles.ExternalUser,
		|	AllNewExternalUserRoles.Role
		|FROM
		|	AllNewExternalUserRoles AS AllNewExternalUserRoles
		|WHERE
		|	NOT TRUE IN
		|				(SELECT TOP 1
		|					TRUE AS TrueValue
		|				FROM
		|					AllRoles AS AllRoles
		|				WHERE
		|					AllRoles.Name = AllNewExternalUserRoles.Role)";
		// 
		
		// 
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ExternalUser = Selection.ExternalUser; // CatalogRef.ExternalUsers
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Role ""%2"" of external user group ""%3""
				          |was not found in metadata while updating roles
				          |of external user ""%1"".
				          |';"),
				TrimAll(ExternalUser),
				Selection.Role,
				String(Selection.ExternalUsersGroup));
			
			WriteLogEvent(
				NStr("en = 'Users.Role is not found in the metadata.';",
				     Common.DefaultLanguageCode()),
				EventLogLevel.Error,
				,
				,
				MessageText,
				EventLogEntryTransactionMode.Transactional);
		EndDo;
		
		// 
		Query.Text =
		"SELECT
		|	ModifiedExternalUsersAndRoles.ExternalUser,
		|	ModifiedExternalUsersAndRoles.Role
		|FROM
		|	(SELECT
		|		NewExternalUserRoles.ExternalUser AS ExternalUser,
		|		NewExternalUserRoles.Role AS Role
		|	FROM
		|		NewExternalUserRoles AS NewExternalUserRoles
		|	WHERE
		|		NewExternalUserRoles.ExternalUser IN
		|				(SELECT
		|					ModifiedExternalUsers.ExternalUser
		|				FROM
		|					ModifiedExternalUsers AS ModifiedExternalUsers)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ExternalUsers.Ref,
		|		""""
		|	FROM
		|		Catalog.ExternalUsers AS ExternalUsers
		|	WHERE
		|		ExternalUsers.Ref IN
		|				(SELECT
		|					ModifiedExternalUsers.ExternalUser
		|				FROM
		|					ModifiedExternalUsers AS ModifiedExternalUsers)) AS ModifiedExternalUsersAndRoles
		|
		|ORDER BY
		|	ModifiedExternalUsersAndRoles.ExternalUser,
		|	ModifiedExternalUsersAndRoles.Role";
		Selection = Query.Execute().Select();
		
		IBUser = Undefined;
		While Selection.Next() Do
			If ValueIsFilled(Selection.Role) Then
				IBUser.Roles.Add(Metadata.Roles[Selection.Role]);
				Continue;
			EndIf;
			If IBUser <> Undefined Then
				IBUser.Write();
			EndIf;
			
			IBUser = InfoBaseUsers.FindByUUID(
				IBUsersIDs[Selection.ExternalUser]);
			
			IBUser.Roles.Clear();
		EndDo;
		If IBUser <> Undefined Then
			IBUser.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Checks that the information database object is used as an authorization object
// for an external user other than the specified external user (if specified).
//
// Parameters:
//  AuthorizationObjectRef - DefinedType.ExternalUser
//  CurrentExternalUserRef - CatalogRef.ExternalUsers
//  FoundExternalUser - Undefined
//                               - CatalogRef.ExternalUsers
//  CanAddExternalUser - Boolean
//  ErrorText - String
//
// Returns:
//  Boolean
//
Function AuthorizationObjectIsInUse(Val AuthorizationObjectRef,
                                      Val CurrentExternalUserRef,
                                      FoundExternalUser = Undefined,
                                      CanAddExternalUser = False,
                                      ErrorText = "") Export
	
	CanAddExternalUser = AccessRight(
		"Insert", Metadata.Catalogs.ExternalUsers);
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		AuthorizationObjectProperties = AuthorizationObjectProperties(AuthorizationObjectRef,
			CurrentExternalUserRef);
		
		If AuthorizationObjectProperties.Used Then
			FoundExternalUser = AuthorizationObjectProperties.Ref;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If AuthorizationObjectProperties.Used Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'An external user mapped to object ""%1"" already exists.';"),
			AuthorizationObjectRef);
	EndIf;
	
	Return AuthorizationObjectProperties.Used;
	
EndFunction

// Returns a link to an external user.
//
// Parameters:
//  AuthorizationObjectRef - DefinedType.ExternalUser
//  CurrentExternalUserRef - CatalogRef.ExternalUsers
//
// Returns:
//  Structure:
//    * Used - Boolean
//    * Ref - CatalogRef.ExternalUsers
//
Function AuthorizationObjectProperties(AuthorizationObjectRef, CurrentExternalUserRef)
	
	Query = New Query(
	"SELECT TOP 1
	|	ExternalUsers.Ref
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.AuthorizationObject = &AuthorizationObjectRef
	|	AND ExternalUsers.Ref <> &CurrentExternalUserRef");
	
	Query.SetParameter("CurrentExternalUserRef", CurrentExternalUserRef);
	Query.SetParameter("AuthorizationObjectRef", AuthorizationObjectRef);
	
	Selection = Query.Execute().Select();
	
	AuthorizationObjectProperties = New Structure;
	AuthorizationObjectProperties.Insert("Used", Selection.Next());
	AuthorizationObjectProperties.Insert("Ref", Selection.Ref);
	
	Return AuthorizationObjectProperties;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Copies settings from the source user to the receiver user. If
// the Transfer = True parameter is set, the source user's settings are deleted.
//
// Parameters:
//   UserNameSource - String -  name of the IB user from which the settings will be copied.
//
// UserNameDestination - String -  Name of the user to whom the settings will be recorded.
//
// Wrap              - Boolean -  If True, the settings are transferred from one user to another,
//                           if False, they are copied to the new one.
//
Procedure CopyUserSettings(UserNameSource, UserNameDestination, Wrap = False) Export
	
	// 
	CopySettings(ReportsUserSettingsStorage, UserNameSource, UserNameDestination, Wrap);
	// 
	CopySettings(SystemSettingsStorage,UserNameSource, UserNameDestination, Wrap);
	// 
	CopySettings(CommonSettingsStorage, UserNameSource, UserNameDestination, Wrap);
	// 
	CopySettings(FormDataSettingsStorage, UserNameSource, UserNameDestination, Wrap);
	// 
	If Not Wrap Then
		CopyOtherUserSettings(UserNameSource, UserNameDestination);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
// 
//
// Parameters:
//  RefsKinds - ValueTable:
//   * Name - String - 
//
//   * ParameterNameExtensionsOperation - String - 
//       
//
//   * AllowedTypes - TypeDescription - 
//
Procedure OnFillRegisteredRefKinds(RefsKinds) Export
	
	RefsKind = RefsKinds.Add();
	RefsKind.Name = "UseExternalUsers";
	RefsKind.AllowedTypes = New TypeDescription("Boolean");
	RefsKind.ParameterNameExtensionsOperation =
		"StandardSubsystems.Users.UseExternalUsersModifiedUponImport";
	
	RefsKind = RefsKinds.Add();
	RefsKind.Name = "Users";
	RefsKind.AllowedTypes = New TypeDescription(
		"CatalogRef.Users");
	RefsKind.ParameterNameExtensionsOperation =
		"StandardSubsystems.Users.UsersChangedOnImport";
	
	RefsKind = RefsKinds.Add();
	RefsKind.Name = "UserGroups";
	RefsKind.AllowedTypes = New TypeDescription(
		"CatalogRef.UserGroups");
	RefsKind.ParameterNameExtensionsOperation =
		"StandardSubsystems.Users.UserGroupsModifiedOnImport";
	
	RefsKind = RefsKinds.Add();
	RefsKind.Name = "UsersGroupsHierarchy";
	RefsKind.AllowedTypes = New TypeDescription(
		"CatalogRef.UserGroups");
	RefsKind.ParameterNameExtensionsOperation =
		"StandardSubsystems.Users.UsersGroupsHierarchyModifiedUponImport";
	
	RefsKind = RefsKinds.Add();
	RefsKind.Name = "ExternalUsers";
	RefsKind.AllowedTypes = New TypeDescription(
		"CatalogRef.ExternalUsers");
	RefsKind.ParameterNameExtensionsOperation =
		"StandardSubsystems.Users.ExternalUsersModifiedUponImport";
	
	RefsKind = RefsKinds.Add();
	RefsKind.Name = "ExternalUsersAuthorizationObjects";
	RefsKind.AllowedTypes = Metadata.DefinedTypes.ExternalUser.Type;
	RefsKind.ParameterNameExtensionsOperation =
		"StandardSubsystems.Users.ExternalUsersAuthorizationObjectsModifiedUponImport";
	
	RefsKind = RefsKinds.Add();
	RefsKind.Name = "ExternalUsersGroups";
	RefsKind.AllowedTypes = New TypeDescription(
		"CatalogRef.ExternalUsersGroups");
	RefsKind.ParameterNameExtensionsOperation =
		"StandardSubsystems.Users.ExternalUsersGroupsModifiedUponImport";
	
	RefsKind = RefsKinds.Add();
	RefsKind.Name = "ExternalUsersGroupsHierarchy";
	RefsKind.AllowedTypes = New TypeDescription(
		"CatalogRef.ExternalUsersGroups");
	RefsKind.ParameterNameExtensionsOperation =
		"StandardSubsystems.Users.ExternalUsersGroupsHierarchyModifiedUponImport";
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.OnFillRegisteredRefKinds(RefsKinds);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.BusinessProcessesAndTasks") Then
		ModuleBusinessProcessesAndTasksServer = Common.CommonModule("BusinessProcessesAndTasksServer");
		ModuleBusinessProcessesAndTasksServer.OnFillRegisteredRefKinds(RefsKinds);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Moves a user from one group to another.
//
// Parameters:
//  UsersArray - Array -  users to move to a new group.
//  SourceGroup      - CatalogRef.UserGroups -  the group from which
//                        users are migrated.
//  DestinationGroup1      - CatalogRef.UserGroups -  the group that
//                        users are being moved to.
//  Move         - Boolean -  if True, the user is removed from the old group.
//
// Returns:
//  String - 
//
Function MoveUserToNewGroup(UsersArray, SourceGroup,
												DestinationGroup1, Move) Export
	
	If DestinationGroup1 = Undefined
		Or DestinationGroup1 = SourceGroup Then
		Return Undefined;
	EndIf;
	MovedUsersArray = New Array;
	UnmovedUsersArray = New Array;
	
	For Each UserRef In UsersArray Do
		
		If TypeOf(UserRef) <> Type("CatalogRef.Users")
			And TypeOf(UserRef) <> Type("CatalogRef.ExternalUsers") Then
			Continue;
		EndIf;
		
		If Not CanMoveUser(DestinationGroup1, UserRef) Then
			UnmovedUsersArray.Add(UserRef);
			Continue;
		EndIf;
		
		If TypeOf(UserRef) = Type("CatalogRef.Users") Then
			CompositionColumnName = "User";
		Else
			CompositionColumnName = "ExternalUser";
		EndIf;
		
		// 
		If DestinationGroup1 = Users.AllUsersGroup()
			Or DestinationGroup1 = ExternalUsers.AllExternalUsersGroup() Then
			
			If Move Then
				Removed = False;
				DeleteUserFromGroup(SourceGroup, UserRef, CompositionColumnName, Removed);
			Else
				Removed = True;
			EndIf;
			If Removed Then
				MovedUsersArray.Add(UserRef);
			EndIf;
		Else
			Added = False;
			AddUserToGroup(DestinationGroup1, UserRef, CompositionColumnName, Added);
			If Added Then
				// 
				If Move Then
					DeleteUserFromGroup(SourceGroup, UserRef, CompositionColumnName);
				EndIf;
				MovedUsersArray.Add(UserRef);
			EndIf;
		EndIf;
		
	EndDo;
	
	UserMessage = CreateUserMessage(
		MovedUsersArray, DestinationGroup1, Move, UnmovedUsersArray, SourceGroup);
	
	If MovedUsersArray.Count() = 0 And UnmovedUsersArray.Count() = 0 Then
		If UsersArray.Count() = 1 Then
			MessageText = NStr("en = 'User ""%1"" is already included in group ""%2.""';");
			UserToMoveName = String(UsersArray[0]);
		Else
			MessageText = NStr("en = 'All selected users are already included in group ""%2.""';");
			UserToMoveName = "";
		EndIf;
		GroupDescription = String(DestinationGroup1);
		UserMessage.Message = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
			UserToMoveName, GroupDescription);
		UserMessage.HasErrors = True;
		Return UserMessage;
	EndIf;
	
	Return UserMessage;
	
EndFunction

// Checks whether an external user can be included in the group.
//
// Parameters:
//  DestinationGroup1     - CatalogRef.UserGroups
//                     - CatalogRef.ExternalUsersGroups - 
//                          
//
//  UserRef - CatalogRef.Users
//                     - CatalogRef.ExternalUsers - 
//                         
//
// Returns:
//  Boolean - 
//
Function CanMoveUser(DestinationGroup1, UserRef) Export
	
	If TypeOf(UserRef) = Type("CatalogRef.ExternalUsers") Then
		
		DestinationGroupProperties = Common.ObjectAttributesValues(
			DestinationGroup1, "Purpose, AllAuthorizationObjects");
		
		If DestinationGroupProperties.AllAuthorizationObjects Then
			Return False;
		EndIf;
		
		DestinationGroupPurpose = DestinationGroupProperties.Purpose.Unload();
		
		ExternalUserType = TypeOf(Common.ObjectAttributeValue(
			UserRef, "AuthorizationObject"));
		RefTypeDetails = New TypeDescription(CommonClientServer.ValueInArray(ExternalUserType));
		Value = RefTypeDetails.AdjustValue(Undefined);
		
		Filter = New Structure("UsersType", Value);
		If DestinationGroupPurpose.FindRows(Filter).Count() <> 1 Then
			Return False;
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

Procedure AddUserToGroup(OwnerGroup, UserRef, CompositionColumnName, Added) Export
	
	If OwnerGroup = Users.AllUsersGroup()
	 Or OwnerGroup = ExternalUsers.AllExternalUsersGroup() Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		If CompositionColumnName = "ExternalUser" Then
			TableName = "Catalog.ExternalUsersGroups";
		Else
			TableName = "Catalog.UserGroups";
		EndIf;
		LockItem = Block.Add(TableName);
		LockItem.SetValue("Ref", OwnerGroup);
		Block.Lock();
		
		OwnerGroupObject = OwnerGroup.GetObject(); // CatalogObject.UserGroups, CatalogObject.ExternalUsersGroups
		Properties = New Structure("AllAuthorizationObjects", False);
		FillPropertyValues(Properties, OwnerGroupObject);
		
		CompositionRow = OwnerGroupObject.Content.Find(UserRef, CompositionColumnName);
		
		If CompositionRow = Undefined And Not Properties.AllAuthorizationObjects Then
			CompositionRow = OwnerGroupObject.Content.Add();
			If CompositionColumnName = "ExternalUser" Then
				CompositionRow.ExternalUser = UserRef;
			Else
				CompositionRow.User = UserRef;
			EndIf;
			OwnerGroupObject.Write();
			Added = True;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure DeleteUserFromGroup(OwnerGroup, UserRef, CompositionColumnName, Removed = False) Export
	
	If OwnerGroup = Users.AllUsersGroup()
	 Or OwnerGroup = ExternalUsers.AllExternalUsersGroup() Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		If CompositionColumnName = "ExternalUser" Then
			TableName = "Catalog.ExternalUsersGroups";
		Else
			TableName = "Catalog.UserGroups";
		EndIf;
		LockItem = Block.Add(TableName);
		LockItem.SetValue("Ref", OwnerGroup);
		Block.Lock();
		
		OwnerGroupObject = OwnerGroup.GetObject();
		
		CompositionRow = OwnerGroupObject.Content.Find(UserRef, CompositionColumnName);
		If CompositionRow <> Undefined Then
			OwnerGroupObject.Content.Delete(CompositionRow);
			OwnerGroupObject.Write();
			Removed = True;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Generates a message about the results of the user's migration.
//
// Parameters:
//  UsersArray - Array -  users to move to a new group.
//  DestinationGroup1      - CatalogRef.UserGroups -  the group that
//                        users are being moved to.
//  Move         - Boolean -  if True, the user is removed from the old group.
//  UnmovedUsersArray - Array -  users who could not be moved to the group.
//  SourceGroup      - CatalogRef.UserGroups -  the group from which
//                        users are migrated.
//
// Returns:
//  String -  user message.
//
Function CreateUserMessage(UsersArray, DestinationGroup1,
	                                      Move, UnmovedUsersArray, SourceGroup = Undefined) Export
	
	UsersCount = UsersArray.Count();
	GroupDescription = String(DestinationGroup1);
	UserMessage = Undefined;
	NotMovedUsersCount = UnmovedUsersArray.Count();
	
	NotifyUser1 = New Structure;
	NotifyUser1.Insert("Message");
	NotifyUser1.Insert("HasErrors");
	NotifyUser1.Insert("Users");
	
	If NotMovedUsersCount > 0 Then
		
		DestinationGroupProperties = Common.ObjectAttributesValues(
			DestinationGroup1, "Purpose, Description");
		
		GroupDescription = DestinationGroupProperties.Description;
		ExternalUserGroupPurpose = DestinationGroupProperties.Purpose.Unload();
		
		PresentationsArray = New Array;
		For Each AssignmentRow1 In ExternalUserGroupPurpose Do
			
			PresentationsArray.Add(Lower(Metadata.FindByType(
				TypeOf(AssignmentRow1.UsersType)).Synonym));
			
		EndDo;
		
		AuthorizationObjectTypePresentation = StrConcat(PresentationsArray, ", ");
		
		If NotMovedUsersCount = 1 Then
			
			NotMovedUserProperties = Common.ObjectAttributesValues(
				UnmovedUsersArray[0], "Description, AuthorizationObject");
			
			SubjectOf = NotMovedUserProperties.Description;
			
			ExternalUserType = TypeOf(NotMovedUserProperties.AuthorizationObject);
			RefTypeDetails = New TypeDescription(CommonClientServer.ValueInArray(ExternalUserType));
			Value = RefTypeDetails.AdjustValue(Undefined);
		
			Filter = New Structure("UsersType", Value);
			UserTypeMatchesGroup = (ExternalUserGroupPurpose.FindRows(Filter).Count() = 1);
			
			NotifyUser1.Users = Undefined;
			
			If UserTypeMatchesGroup Then
				UserMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Cannot add user ""%1"" to group ""%2""
					           |because the group has ""All users of the specified types"" option selected.';"),
					SubjectOf, GroupDescription) + Chars.LF;
			Else
				UserMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Cannot add user ""%1"" to group ""%2""
					           |because the group contains only %3.';"),
					SubjectOf, GroupDescription, AuthorizationObjectTypePresentation) + Chars.LF;
			EndIf;
		Else
			NotifyUser1.Users = StrConcat(UnmovedUsersArray, Chars.LF);
			
			UserMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot add some users to group ""%1""
				           |because the group contains only %2
				           |or it has ""All users of the specified types"" option selected.';"),
				GroupDescription,
				AuthorizationObjectTypePresentation);
		EndIf;
		
		NotifyUser1.Message = UserMessage;
		NotifyUser1.HasErrors = True;
		
		Return NotifyUser1;
	EndIf;
	
	If UsersCount = 1 Then
		
		StringObject = String(UsersArray[0]);
		
		If DestinationGroup1 = Users.AllUsersGroup()
		 Or DestinationGroup1 = ExternalUsers.AllExternalUsersGroup() Then
			
			UserMessage = NStr("en = '""%1"" is excluded from group ""%2.""';");
			GroupDescription = String(SourceGroup);
			
		ElsIf Move Then
			UserMessage = NStr("en = '""%1"" is moved to group ""%2.""';");
		Else
			UserMessage = NStr("en = '""%1"" is added to group ""%2.""';");
		EndIf;
		
	ElsIf UsersCount > 1 Then
		
		StringObject = Format(UsersCount, "NFD=0") + " "
			+ UsersInternalClientServer.IntegerSubject(UsersCount,
				"", NStr("en = 'user, users,,,0';"));
		
		If DestinationGroup1 = Users.AllUsersGroup() Then
			UserMessage = NStr("en = '%1 are excluded from group ""%2.""';");
			GroupDescription = String(SourceGroup);
			
		ElsIf Move Then
			UserMessage = NStr("en = '%1 are moved to group ""%2.""';");
		Else
			UserMessage = NStr("en = '%1 are added to group ""%2.""';");
		EndIf;
		
	EndIf;
	
	If UserMessage <> Undefined Then
		UserMessage = StringFunctionsClientServer.SubstituteParametersToString(UserMessage,
			StringObject, GroupDescription);
	EndIf;
	
	NotifyUser1.Message = UserMessage;
	NotifyUser1.HasErrors = False;
	
	Return NotifyUser1;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Procedure FillInTheEmailForPasswordRecoveryFromUsersInTheBackground(AdditionalParameters, AddressInTempStorage) Export
	
	UsersList = UsersToEnablePasswordRecovery();
	For Each UserRef In UsersList Do
		UpdateEmailForPasswordRecovery(UserRef);
	EndDo;
	
	UsersList = ExternalUsersToEnablePasswordRecovery();
	For Each ExternalUserLink In UsersList Do
		
		AuthorizationObject = Common.ObjectAttributeValue(ExternalUserLink, "AuthorizationObject");
		UpdateEmailForPasswordRecovery(ExternalUserLink, AuthorizationObject);
		
	EndDo;
	
EndProcedure

Function PasswordRecoverySettingsAreAvailable(AccessLevel) Export
	
	If Common.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	If Not AccessLevel.ChangeCurrent
		 And Not AccessLevel.ListManagement Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Parameters:
//  AccessLevel - Structure
//  Object - CatalogObject.Users
//         - CatalogObject.ExternalUsers
// 
// Returns:
//  Boolean
//
Function InteractivelyPromptForAPassword(AccessLevel, Object) Export
	
	If Users.IsFullUser()
		Or AccessLevel.ListManagement
		Or Not ValueIsFilled(Object.Ref) Then
			Return False;
	ElsIf ValueIsFilled(Object.IBUserID) 
		And AccessLevel.ChangeCurrent Then
		
			SetPrivilegedMode(True);
			IBUser = InfoBaseUsers.FindByUUID(Object.IBUserID);
			SetPrivilegedMode(False);
			
			If IBUser <> Undefined Then
				Return IBUser.PasswordIsSet;
			EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

// Parameters:
//  AccessLevel - Structure
//  Object - CatalogObject.Users
//         - CatalogObject.ExternalUsers
// 
// Returns:
//  Boolean
//
Function YouCanEditYourEmailToRestoreYourPassword(AccessLevel, Object) Export
	
	If Users.IsFullUser()
		Or AccessLevel.ChangeCurrent
		Or Not ValueIsFilled(Object.Ref)
		Or (AccessLevel.ListManagement And Object.Prepared) Then
			Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function UsersToEnablePasswordRecovery() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		Return New Array;
	EndIf;
	
	IBSUsersByMail = UsersWithRecoveryEmail();
	
	If ExternalUsers.UseExternalUsers() Then
		Return UsersToEnablePasswordRecoveryBasedOnExternalUsers(IBSUsersByMail);
	EndIf;
	
	ModuleContactsManager = Common.CommonModule("ContactsManager");
	
	Query = New Query;
	Query.Text = "SELECT DISTINCT
	|	MAX(UsersContactInformation.Ref) AS Ref,
	|	UsersContactInformation.Presentation AS Presentation,
	|	Users.IBUserID AS IBUserID
	|FROM
	|	Catalog.Users.ContactInformation AS UsersContactInformation
	|		LEFT JOIN Catalog.Users AS Users
	|		ON UsersContactInformation.Ref = Users.Ref
	|WHERE
	|	UsersContactInformation.Kind = &ContactInformationKind
	|	AND Users.Invalid = FALSE
	|	AND Users.IsInternal = FALSE
	|
	|GROUP BY
	|	UsersContactInformation.Presentation,
	|	Users.IBUserID";
	
	Query.SetParameter("ContactInformationKind",
	ModuleContactsManager.ContactInformationKindByName("UserEmail"));
	
	QueryResult = Query.Execute().Unload();
	
	Return ListOfUsersToUpdate(IBSUsersByMail, QueryResult);
	
EndFunction

Function UsersToEnablePasswordRecoveryBasedOnExternalUsers(IBSUsersByMail)
	
	TypesOfExternalUsers = Metadata.DefinedTypes.ExternalUser.Type.Types();
	
	If TypesOfExternalUsers.Count() = 0 Then
		Return New Array;
	EndIf;
	
	ModuleContactsManager = Common.CommonModule("ContactsManager");
	
	QueryTemplate = "SELECT
		|	ExternalUserContactInformation.Presentation AS Mail
		|INTO TempTable
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|		LEFT JOIN #ContactInformation AS ExternalUserContactInformation
		|		ON (ExternalUsers.AuthorizationObject = ExternalUserContactInformation.Ref)
		|WHERE
		|	ExternalUsers.Invalid = FALSE
		|	AND ExternalUserContactInformation.Type = &ContactInformationType";
	
	QueriesSet = New Array;
	
	For Each ExternalUserType In TypesOfExternalUsers Do
		
		If Not ModuleContactsManager.ContainsContactInformation(ExternalUserType) Then
			Continue;
		EndIf;
		
		TableName = Metadata.FindByType(ExternalUserType).FullName() + ".ContactInformation";
		QueriesSet.Add(StrReplace(QueryTemplate, "#ContactInformation", TableName));
		
		QueryTemplate = StrReplace(QueryTemplate, "INTO TempTable", "");
	EndDo;
	
	If QueriesSet.Count() = 0 Then
		Return New Array;
	EndIf;
	
	QueryText = StrConcat(QueriesSet, Chars.LF + " UNION ALL " + Chars.LF);
	
	QueryText = QueryText + Common.QueryBatchSeparator() + "
	|SELECT DISTINCT
	|	MAX(Users.Ref) AS Ref,
	|	UsersContactInformation.Presentation AS Presentation,
	|	Users.IBUserID AS IBUserID
	|FROM
	|	Catalog.Users.ContactInformation AS UsersContactInformation
	|		LEFT JOIN Catalog.Users AS Users
	|		ON (UsersContactInformation.Ref = Users.Ref)
	|		LEFT JOIN TempTable AS TempTable
	|		ON (UsersContactInformation.Presentation = TempTable.Mail)
	|
	|WHERE
	|	UsersContactInformation.Kind = &ContactInformationKind
	|	AND Users.Invalid = FALSE
	|	AND Users.IsInternal = FALSE
	|	AND TempTable.Mail IS NULL
	|
	|GROUP BY
	|	UsersContactInformation.Presentation, Users.IBUserID
	|
	|HAVING
	|	COUNT(UsersContactInformation.Ref) = 1";
	
	Query = New Query(QueryText);
	
	Query.Parameters.Insert("ContactInformationType",
		ModuleContactsManager.ContactInformationTypeByDescription("Email"));
	Query.SetParameter("ContactInformationKind",
			ModuleContactsManager.ContactInformationKindByName("UserEmail"));
	
	QueryResult = Query.Execute().Unload();
	
	Return ListOfUsersToUpdate(IBSUsersByMail, QueryResult);
	
EndFunction

Function ListOfUsersToUpdate(IBSUsersByMail, QueryResult)

	If IBSUsersByMail.Count() = 0 Then
		Return QueryResult.UnloadColumn("Ref");
	EndIf;
	
	UsersList = New Array;
	
	For Each UserToUpdate In QueryResult Do
		UserInfo = IBSUsersByMail[UserToUpdate.Presentation];
		
		If UserInfo = Undefined Then
			UsersList.Add(UserToUpdate.Ref);
			Continue;
		EndIf;
		
		If StrCompare(UserToUpdate.IBUserID, UserInfo.UUID) = 0 Then
			Continue;
		EndIf;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot assign recovery email ""%2"" for user %1.
			           |It is already assigned to user
			           |%3 (%4)';"),
			String(UserToUpdate.Ref),
			UserInfo.Email,
			UserInfo.Name,
			UserInfo.FullName);
			
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Warning,
			Metadata.Catalogs.Users,
			UserToUpdate.Ref,
			MessageText);
	EndDo;
	
	Return UsersList;
	
EndFunction

Function ExternalUsersToEnablePasswordRecovery() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		Return New Array;
	EndIf;
	
	TypesOfExternalUsers = Metadata.DefinedTypes.ExternalUser.Type.Types();
	
	If TypesOfExternalUsers.Count() = 0 Then
		Return New Array;
	EndIf;
	
	ModuleContactsManager = Common.CommonModule("ContactsManager");
	QueriesSet = New Array;
	
	QueryText = "SELECT
	|	UsersContactInformation.Ref AS Ref,
	|	UsersContactInformation.Presentation AS Presentation,
	|	Users.IBUserID AS IBUserID
	|INTO TempTable
	|FROM
	|	Catalog.Users.ContactInformation AS UsersContactInformation
	|		LEFT JOIN Catalog.Users AS Users
	|		ON (UsersContactInformation.Ref = Users.Ref)
	|WHERE
	|	UsersContactInformation.Kind = &ContactInformationKind
	|	AND Users.Invalid = FALSE
	|	AND Users.IsInternal = FALSE";
	
	QueriesSet.Add(QueryText);
	
	QueryTemplate = "SELECT
	|	ExternalUsers.Ref AS Ref,
	|	ExternalUserContactInformation.Presentation, 
	|	ExternalUsers.IBUserID AS IBUserID
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|		LEFT JOIN #ContactInformation AS ExternalUserContactInformation
	|		ON (ExternalUsers.AuthorizationObject = ExternalUserContactInformation.Ref)
	|WHERE
	|	ExternalUsers.Invalid = FALSE
	|	AND ExternalUserContactInformation.Type = &ContactInformationType";

	For Each ExternalUserType In TypesOfExternalUsers Do
		
		If Not ModuleContactsManager.ContainsContactInformation(ExternalUserType) Then
			Continue;
		EndIf;
		
		TableName = Metadata.FindByType(ExternalUserType).FullName() + ".ContactInformation";
		QueriesSet.Add(StrReplace(QueryTemplate, "#ContactInformation", TableName));
		
	EndDo;
	
	If QueriesSet.Count() < 2 Then
		Return New Array;
	EndIf;
	
	QueryText = StrConcat(QueriesSet, Chars.LF + " UNION ALL " + Chars.LF);
	
	QueryText = QueryText + Common.QueryBatchSeparator() + "
	|SELECT
	|	MAX(TempTable.Ref) AS Ref,
	|	TempTable.Presentation AS Presentation,
	|	TempTable.IBUserID AS IBUserID
	|FROM
	|	TempTable AS TempTable
	|	
	|GROUP BY
	|	TempTable.Presentation, TempTable.IBUserID
	|
	|HAVING
	|	COUNT(TempTable.Ref) = 1 
	|	AND VALUETYPE(MAX(TempTable.Ref)) <> TYPE(Catalog.Users)";
	
	Query = New Query(QueryText);
	
	Query.Parameters.Insert("ContactInformationType",
		ModuleContactsManager.ContactInformationTypeByDescription("Email"));
	Query.SetParameter("ContactInformationKind",
			ModuleContactsManager.ContactInformationKindByName("UserEmail"));
	
	QueryResult = Query.Execute().Unload();
	
	IBSUsersByMail = UsersWithRecoveryEmail();
	
	Return ListOfUsersToUpdate(IBSUsersByMail, QueryResult);
	
EndFunction

Function UpdateEmailForPasswordRecovery(UserRef, AuthorizationObject = Undefined) Export
	
	Result =  New Structure;
	Result.Insert("Status",      "NoUpdateRequired");
	Result.Insert("ErrorText", "");
	
	ModuleContactsManager = Common.CommonModule("ContactsManager");
	IBUserID = Common.ObjectAttributeValue(UserRef, "IBUserID");
	
	IBUser = Users.IBUserProperies(IBUserID);
	If IBUser = Undefined Or ValueIsFilled(IBUser.Email) Then
		Return Result;
	EndIf;
	
	If AuthorizationObject = Undefined Then
		
		OwnerOfTheKey                 = UserRef;
		TypeOrTypeOfEmail  = ModuleContactsManager.ContactInformationKindByName("UserEmail");
		FullMetadataObjectName = Metadata.Catalogs.Users.FullName();
		
	Else
		
		If Not ModuleContactsManager.ContainsContactInformation(AuthorizationObject) Then
			Return Result;
		EndIf;
		OwnerOfTheKey                 = AuthorizationObject;
		TypeOrTypeOfEmail  = ModuleContactsManager.ContactInformationTypeByDescription("Email");
		FullMetadataObjectName = AuthorizationObject.Metadata().FullName();
		
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add(FullMetadataObjectName);
	LockItem.SetValue("Ref", OwnerOfTheKey);
	LockItem.Mode = DataLockMode.Shared;
	
	EmailForPasswordRecovery = "";
	RepresentationOfTheReference = String(UserRef);
	BeginTransaction();
	Try
		
		Block.Lock();
		
		UserContactInformation = ModuleContactsManager.ObjectContactInformation(OwnerOfTheKey,
			TypeOrTypeOfEmail, CurrentSessionDate(), False);
		
		If UserContactInformation.Count() > 0 Then
			
			LineWithMail = UserContactInformation[0];
			
			If ValueIsFilled(LineWithMail.Value) Then
				EmailForPasswordRecovery = ModuleContactsManager.Email(LineWithMail.Value);
				If Not CommonClientServer.EmailAddressMeetsRequirements(EmailForPasswordRecovery) Then
					EmailForPasswordRecovery = "";
				EndIf;
			EndIf;
			
			If IsBlankString(EmailForPasswordRecovery) And ValueIsFilled(LineWithMail.FieldValues) Then
				EmailForPasswordRecovery = ModuleContactsManager.Email(LineWithMail.FieldValues);
				If Not CommonClientServer.EmailAddressMeetsRequirements(EmailForPasswordRecovery) Then
					EmailForPasswordRecovery = "";
				EndIf;
			EndIf;
			
			If IsBlankString(EmailForPasswordRecovery) And ValueIsFilled(LineWithMail.Presentation) Then
				EmailForPasswordRecovery = LineWithMail.Presentation;
			EndIf;
			
			If CommonClientServer.EmailAddressMeetsRequirements(EmailForPasswordRecovery) Then
				
				IBUser.Email          = EmailForPasswordRecovery;
				IBUser.CannotRecoveryPassword = False;
				Users.SetIBUserProperies(IBUserID, IBUser);
				
			EndIf;
			
		EndIf;
		
		Result.Status = "Updated";
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		// 
		ErrorInfo = ErrorInfo();
		
		Result.Status = "Error";
		Result.ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		InfobaseUpdate.WriteErrorToEventLog(
			UserRef,
			RepresentationOfTheReference,
			ErrorInfo());
		
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		If ValueIsFilled(EmailForPasswordRecovery)
			 And StrFind(ErrorText, EmailForPasswordRecovery) > 0 Then
				Refinement = NStr("en = 'Email address %1 is already occupied by another user and cannot be used to restore the password.';");
				Refinement = StringFunctionsClientServer.SubstituteParametersToString(Refinement, EmailForPasswordRecovery);
				InfobaseUpdate.FileIssueWithData(UserRef, Refinement);
		EndIf;
		
	EndTry;
	
	Return Result;
	
EndFunction

Function UsersWithRecoveryEmail()
	
	IBSUsersByMail = New Map;
	
	IBUsers = InfoBaseUsers.GetUsers();
	For Each IBUser In IBUsers Do
		
		UserInfo = UserInformationForUpdatingMailForRecovery();
		FillPropertyValues(UserInfo, IBUser);
		
		If ValueIsFilled(UserInfo.Email) Then
			IBSUsersByMail.Insert(UserInfo.Email, UserInfo);
		EndIf;
		
	EndDo;
	
	Return IBSUsersByMail;
	
EndFunction

// Returns:
//  Structure:
//   * Email - String
//   * UUID - String
//   * Name - String
//   * FullName - String
//
Function UserInformationForUpdatingMailForRecovery()
	
	Result = New Structure;
	Result.Insert("Email", "");
	Result.Insert("UUID", "");
	Result.Insert("Name", "");
	Result.Insert("FullName", "");
	
	Return Result;
	
EndFunction

// 
// 
// 
// 
// 
// 
//
// Parameters:
//  UserObject - CatalogObject.Users - 
//                     - CatalogObject.ExternalUsers
//  NewAddress  - String
//  OldAddress - String
//              - Undefined - 
//
Procedure ChangePasswordRecoveryEmail(UserObject, NewAddress, OldAddress)
	
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManager = Common.CommonModule("ContactsManager");
		ModuleContactsManager.ChangePasswordRecoveryEmail(UserObject, NewAddress, OldAddress);
	EndIf;
	
EndProcedure

// 
Procedure AddRecipientSessions(RecipientsSessions, Addressee, SessionKey = Undefined);
	
	SessionsKeys = RecipientsSessions.Get(Addressee.Key);
	If SessionsKeys = Undefined Then
		SessionsKeys = New Array;
		RecipientsSessions.Insert(Addressee.Key, SessionsKeys);
	EndIf;
	
	If SessionKey <> Undefined Then
		SessionsKeys.Add(SessionKey);
		Return;
	EndIf;
	
	For Each SessionKey In Addressee.Value Do
		SessionsKeys.Add(SessionKey);
	EndDo;
	
EndProcedure

// 
Function AreRoleKeysReduced(OldRoleKeysAsString, NewRoleKeysAsString)
	
	OldKeys = StrSplit(OldRoleKeysAsString, ",", False);
	NewKeys = StrSplit(NewRoleKeysAsString, ",", False);
	
	For Each KeyRole In OldKeys Do
		If Not StrEndsWith(KeyRole, "/1") // 
		   And NewKeys.Find(KeyRole) = Undefined Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// 
Function RolesReduced(InfobaseOldUser, InfobaseNewUser)
	
	For Each Role In InfobaseOldUser.Roles Do
		If Not InfobaseNewUser.Roles.Contains(Role)
		   And Role.ConfigurationExtension() = Undefined Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// 
//
// Parameters:
//  IBUser - InfoBaseUser
//
// Returns:
//  String
//
Function InfobaseUserRoleKeys(IBUser)
	
	For Each Role In IBUser.Roles Do
		Break;
	EndDo;
	If Role = Undefined Then
		Return "";
	EndIf;
	
	ExtensionsRoles = UsersInternalCached.ExtensionsRoles();
	List = New ValueList;
	
	For Each Role In IBUser.Roles Do
		KeyRole = Catalogs.MetadataObjectIDs.RoleMetadataObjectKey(Role);
		If KeyRole = Undefined Then
			KeyRole = "Undefined";
		EndIf;
		If ExtensionsRoles.Get(Role.Name) <> Undefined Then
			KeyRole = KeyRole + "/1";
		EndIf;
		List.Add(KeyRole);
	EndDo;
	
	List.SortByValue();
	
	Return StrConcat(List.UnloadValues(), ",");
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Returns the distinct values in the column of the tables of values.
//
// Parameters:
//  ColumnName - String -  name of the column to compare.
//  Table1   - ValueTable
//  Table2   - ValueTable
//
// Returns:
//  Array - 
// 
Function ColumnValueDifferences(ColumnName, Table1, Table2) Export
	
	If TypeOf(Table1) <> Type("ValueTable")
	   And TypeOf(Table2) <> Type("ValueTable") Then
		
		Return New Array;
	EndIf;
	
	If TypeOf(Table1) <> Type("ValueTable") Then
		Return Table2.UnloadColumn(ColumnName);
	EndIf;
	
	If TypeOf(Table2) <> Type("ValueTable") Then
		Return Table1.UnloadColumn(ColumnName);
	EndIf;
	
	Table11 = Table1.Copy(, ColumnName);
	Table11.GroupBy(ColumnName);
	
	Table22 = Table2.Copy(, ColumnName);
	Table22.GroupBy(ColumnName);
	
	For Each TableRow In Table22 Do
		NewRow = Table11.Add();
		NewRow[ColumnName] = TableRow[ColumnName];
	EndDo;
	
	Table11.Columns.Add("Flag");
	Table11.FillValues(1, "Flag");
	
	Table11.GroupBy(ColumnName, "Flag");
	
	Filter = New Structure("Flag", 1);
	Table = Table11.Copy(Table11.FindRows(Filter));
	
	Return Table.UnloadColumn(ColumnName);
	
EndFunction

Procedure SelectGroupUsers(SelectedItems, StoredParameters, ListBox) Export 
	
	If SelectedItems.Count() = 0 Then 
		Return;
	EndIf;
	
	SelectedElement = SelectedItems[0].SelectedElement;
	SelectedItemType = TypeOf(SelectedElement);
	
	If SelectedItemType = Type("CatalogRef.UserGroups")
			And StoredParameters.UsersGroupsSelection
		Or SelectedItemType = Type("CatalogRef.ExternalUsersGroups")
			And StoredParameters.SelectExternalUsersGroups
		Or SelectedItemType <> Type("CatalogRef.UserGroups")
			And SelectedItemType <> Type("CatalogRef.ExternalUsersGroups") Then 
		
		Return;
	EndIf;
	
	GroupUsers = GroupUsers(ListBox);
	
	SelectedItems.Clear();
	
	For Each GroupUser1 In GroupUsers Do 
		
		Item = New Structure;
		Item.Insert("SelectedElement", GroupUser1.Ref);
		Item.Insert("PictureNumber", GroupUser1.PictureNumber);
		
		SelectedItems.Add(Item);
		
	EndDo;
	
EndProcedure

Function GroupUsers(ListBox)
	
	Schema = ListBox.GetPerformingDataCompositionScheme();
	Settings = ListBox.GetPerformingDataCompositionSettings();
	
	AddGroupUsersFields(Settings);
	
	TemplateComposer = New DataCompositionTemplateComposer();
	CompositionTemplate = TemplateComposer.Execute(
		Schema, Settings,,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	
	Return OutputProcessor.Output(CompositionProcessor);
	
EndFunction

Procedure AddGroupUsersFields(Settings)
	
	FieldsToAdd = StrSplit("Ref, PictureNumber", ", ", False);
	SettingsStructure = Settings.Structure[0]; // DataCompositionGroup
	SelectedFields = SettingsStructure.Selection;
	
	For Each FieldToAdd In FieldsToAdd Do 
		
		AvailableField = SelectedFields.SelectionAvailableFields.FindField(New DataCompositionField(FieldToAdd));
		
		If AvailableField = Undefined Then 
			Continue;
		EndIf;
		
		FieldFound = False;
		
		For Each Item In SelectedFields.Items Do 
			
			If Item.Field = AvailableField.Field Then 
				FieldFound = True;
				Break;
			EndIf;
			
		EndDo;
		
		If FieldFound Then 
			Continue;
		EndIf;
		
		SelectedField = SelectedFields.Items.Add(Type("DataCompositionSelectedField"));
		FillPropertyValues(SelectedField, AvailableField);
		
	EndDo;
	
EndProcedure

// Parameters:
//  List - DynamicList
//  FieldName - String
//
Procedure RestrictUsageOfDynamicListFieldToFill(List, FieldName) Export
	
	Fields = List.GetRestrictionsForUseInGroup();
	If Fields.Find(FieldName) = Undefined Then
		Fields.Add(FieldName);
		List.SetRestrictionsForUseInGroup(Fields);
	EndIf;
	
	Fields = List.GetRestrictionsForUseInFilter();
	If Fields.Find(FieldName) = Undefined Then
		Fields.Add(FieldName);
		List.SetRestrictionsForUseInFilter(Fields);
	EndIf;
	
	Fields = List.GetRestrictionsForUseInOrder();
	If Fields.Find(FieldName) = Undefined Then
		Fields.Add(FieldName);
		List.SetRestrictionsForUseInOrder(Fields);
	EndIf;
	
EndProcedure

// 
Procedure AddFieldWithCheck(Fields, Field, AvailableFields, UnfoundFields, AddedFields, ObjectName)

	If AvailableFields <> Undefined
	   And AvailableFields.Get(Lower(Field)) <> Undefined Then
		Fields.Add(Field);
	Else
		FullFieldName1 = ?(AvailableFields = Undefined, "<<?>>", "") + ObjectName + "."
			+ ?(AvailableFields = Undefined, "", "<<?>>") + Field;
		If AddedFields.Get(Lower(FullFieldName1)) = Undefined Then
			UnfoundFields.Add(FullFieldName1);
			AddedFields.Insert(Lower(FullFieldName1), True);
		EndIf;
	EndIf;
	
EndProcedure

// 
//
// Parameters:
//  FullTableName - String
//
// Returns:
//  Structure:
//   * Collections - Array of Structure:
//      ** Name - String  - 
//                         
//      ** Fields          - Array of See NewFieldDescription
//                       - Undefined - 
//      ** Tables       - Array of See TableNewDetails
//                       - Undefined - 
//   * AllFields - Map of KeyAndValue:
//      ** Key - String - 
//      ** Value - String - 
//
//  
//
Function TableFields(Val FullTableName) Export
	
	ObjectMetadata = Common.MetadataObjectByFullName(FullTableName);
	If ObjectMetadata = Undefined Then
		Return Undefined;
	EndIf;
	
	NameParts = StrSplit(ObjectMetadata.FullName(), ".", False);
	ObjectKind = NameParts[0];
	
	If NameParts.Count() = 4 And ObjectKind = "ExternalDataSource" Then
		ObjectKind = "ExternalDataSourceTable";
	EndIf;
	
	ObjectCollections = ObjectCollectionsByKind(ObjectKind);
	If ObjectCollections = Undefined Then
		Return Undefined;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Collections", New Array);
	Result.Insert("AllFields", New Map);
	
	For Each ObjectCollection In ObjectCollections Do
		CollectionDescription_ = New Structure;
		CollectionDescription_.Insert("Name", ObjectCollection.Name);
		CollectionDescription_.Insert("Fields");
		CollectionDescription_.Insert("Tables");
		Result.Collections.Add(CollectionDescription_);
		
		If ValueIsFilled(ObjectCollection.Fields) Then
			CollectionDescription_.Fields = ObjectCollection.Fields;
			CompleteAllFields(Result.AllFields, CollectionDescription_.Fields);
			Continue;
		EndIf;
		
		CollectionItems = ObjectMetadata[ObjectCollection.Name];
		If ValueIsFilled(ObjectCollection.FieldsCollectionName) Then
			CollectionDescription_.Tables = New Array;
			For Each CollectionItem In CollectionItems Do
				TableDetails = TableNewDetails();
				TableDetails.Name = CollectionItem.Name;
				TableDetails.Presentation = CollectionItem.Presentation();
				CollectionDescription_.Tables.Add(TableDetails);
				AddFields(TableDetails.Fields, CollectionItem[ObjectCollection.FieldsCollectionName]);
				CompleteAllFields(Result.AllFields, TableDetails.Fields, TableDetails.Name + ".");
			EndDo;
		Else
			CollectionDescription_.Fields = New Array;
			AddFields(CollectionDescription_.Fields, CollectionItems);
			CompleteAllFields(Result.AllFields, CollectionDescription_.Fields);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// 
Procedure AddFields(TableFields, TableFieldsMetadata)
	
	For Each FieldMetadata In TableFieldsMetadata Do
		FieldDetails = NewFieldDescription();
		FieldDetails.Name = FieldMetadata.Name;
		FieldDetails.Presentation = FieldMetadata.Presentation();
		TableFields.Add(FieldDetails);
	EndDo;
	
EndProcedure

// 
Procedure CompleteAllFields(AllFields, Fields, TableName = "")
	
	For Each Field In Fields Do
		FullFieldName1 = TableName + Field.Name;
		AllFields.Insert(Lower(FullFieldName1), FullFieldName1);
	EndDo;
	
EndProcedure

// Returns:
//  Array of Structure:
//   * Name - String - 
//   * FieldsCollectionName - String - 
//   * Fields - Undefined - 
//          - Array of
//
//  
//
Function ObjectCollectionsByKind(ObjectKind)
	
	Result = New Array;
	
	If ObjectKind = "ExchangePlan"
	 Or ObjectKind = "Catalog"
	 Or ObjectKind = "Document"
	 Or ObjectKind = "ChartOfCharacteristicTypes"
	 Or ObjectKind = "ChartOfCharacteristicTypes"
	 Or ObjectKind = "BusinessProcess" Then
		
		AddCollection(Result, "StandardAttributes");
		AddCollection(Result, "Attributes");
		AddCollection(Result, "TabularSections", "Attributes");
		
	ElsIf ObjectKind = "Constant" Then
		Fields = New Array;
		Fields.Add(NewFieldDescription("Value", NStr("en = 'Value';")));
		AddCollection(Result, "StandardAttributes",, Fields);
		
	ElsIf ObjectKind = "Sequence" Then
		Fields = New Array;
		Fields.Add(NewFieldDescription("Recorder",   NStr("en = 'Recorder';")));
		Fields.Add(NewFieldDescription("Period",        NStr("en = 'Period';")));
		Fields.Add(NewFieldDescription("PointInTime", NStr("en = 'Point in time';")));
		AddCollection(Result, "StandardAttributes",, Fields);
		AddCollection(Result, "Dimensions");
		
	ElsIf ObjectKind = "DocumentJournal" Then
		AddCollection(Result, "StandardAttributes");
		AddCollection(Result, "Columns");
		
	ElsIf ObjectKind = "ChartOfAccounts"
	      Or ObjectKind = "ChartOfCalculationTypes" Then
		
		AddCollection(Result, "StandardAttributes");
		AddCollection(Result, "Attributes");
		AddCollection(Result, "StandardTabularSections", "StandardAttributes");
		AddCollection(Result, "TabularSections", "Attributes");
		
	ElsIf ObjectKind = "InformationRegister"
	      Or ObjectKind = "AccumulationRegister"
	      Or ObjectKind = "AccountingRegister"
	      Or ObjectKind = "CalculationRegister" Then
		
		AddCollection(Result, "StandardAttributes");
		AddCollection(Result, "Dimensions");
		AddCollection(Result, "Resources");
		AddCollection(Result, "Attributes");
		
	ElsIf ObjectKind = "Task" Then
		AddCollection(Result, "AddressingAttributes");
		AddCollection(Result, "Attributes");
		AddCollection(Result, "TabularSections", "Attributes");
		
	ElsIf ObjectKind = "ExternalDataSource" Then
		AddCollection(Result, "Tables", "Fields");
		
	ElsIf ObjectKind = "ExternalDataSourceTable" Then
		AddCollection(Result, "Fields");
	Else
		Result = Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

// 
Procedure AddCollection(Collections, Name, FieldsCollectionName = "", Fields = Undefined)
	
	Collection = New Structure;
	Collection.Insert("Name", Name);
	Collection.Insert("FieldsCollectionName", FieldsCollectionName);
	Collection.Insert("Fields", Fields);
	
	Collections.Add(Collection);
	
EndProcedure

// Returns:
//  Structure:
//   * Name - String
//   * Presentation - String
//
Function NewFieldDescription(Name = "", Presentation = "")
	
	Result = New Structure;
	Result.Insert("Name", Name);
	Result.Insert("Presentation", Presentation);
	
	Return Result;
	
EndFunction

// Returns:
//  Structure:
//   * Name - String
//   * Presentation - String
//   * Fields - Array of See NewFieldDescription
//
Function TableNewDetails()
	
	Result = New Structure;
	Result.Insert("Name", "");
	Result.Insert("Presentation", "");
	Result.Insert("Fields", New Array);
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Called when switching to the configuration version 2.1.3.16.
Procedure UpdatePredefinedUserContactInformationKinds() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		Return;
	EndIf;
	
	ModuleContactsManager = Common.CommonModule("ContactsManager");
	
	KindParameters = ModuleContactsManager.ContactInformationKindParameters("Email");
	KindParameters.Kind = "UserEmail";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.AllowMultipleValueInput = True;
	KindParameters.Order = 1;
	ModuleContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ModuleContactsManager.ContactInformationKindParameters("Phone");
	KindParameters.Kind = "UserPhone";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.AllowMultipleValueInput = True;
	KindParameters.Order = 2;
	ModuleContactsManager.SetContactInformationKindProperties(KindParameters);
	
EndProcedure

Procedure MoveDesignerPasswordLengthAndComplexitySettings() Export
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	Block = New DataLock;
	Block.Add("Constant.UserAuthorizationSettings");
	If Not DataSeparationEnabled Then
		Block.Add("Constant.DeleteUserAuthorizationSettings");
	EndIf;
	
	BeginTransaction();
	Try
		Block.Lock();
		PreviousSettings1 = Undefined;
		If Not DataSeparationEnabled Then
			PreviousSettings1 = Constants.DeleteUserAuthorizationSettings.Get().Get();
			Constants.DeleteUserAuthorizationSettings.Set(New ValueStorage(Undefined));
		EndIf;
		If PreviousSettings1 = Undefined Then
			PreviousSettings1 = Constants.UserAuthorizationSettings.Get().Get();
		EndIf;
		
		NewSettings1 = LogonSettings();
		
		If Not Users.CommonAuthorizationSettingsUsed() Then
			NewSettings1.Overall.Insert("UpdateOnlyConstant");
			NewSettings1.Users.Insert("UpdateOnlyConstant");
			NewSettings1.ExternalUsers.Insert("UpdateOnlyConstant");
		EndIf;
		
		If TypeOf(PreviousSettings1) <> Type("Structure")
		 Or Not PreviousSettings1.Property("Users") Then
			CommonSettingsDetails = Users.CommonAuthorizationSettingsNewDetails();
			NewSettings1.Overall.PasswordAttemptsCountBeforeLockout =
				CommonSettingsDetails.PasswordAttemptsCountBeforeLockout;
			NewSettings1.Overall.PasswordLockoutDuration =
				CommonSettingsDetails.PasswordLockoutDuration;
		EndIf;
		
		If TypeOf(PreviousSettings1) = Type("Structure") Then
			If PreviousSettings1.Property("Users")
			   And TypeOf(PreviousSettings1.Users) = Type("Structure") Then
				FillPropertyValues(NewSettings1.Users, PreviousSettings1.Users);
				Users.SetLoginSettings(NewSettings1.Users);
			EndIf;
			If PreviousSettings1.Property("ExternalUsers")
			   And TypeOf(PreviousSettings1.ExternalUsers) = Type("Structure") Then
				FillPropertyValues(NewSettings1.ExternalUsers, PreviousSettings1.ExternalUsers);
				Users.SetLoginSettings(NewSettings1.ExternalUsers, True);
			EndIf;
			Match = True;
			For Each KeyAndValue In NewSettings1.Users Do
				If KeyAndValue.Value <> NewSettings1.ExternalUsers[KeyAndValue.Key] Then
					Match = False;
					Break;
				EndIf;
			EndDo;
			If Not Match Then
				NewSettings1.Overall.AreSeparateSettingsForExternalUsers = True;
			EndIf;
		EndIf;
		
		Users.SetCommonAuthorizationSettings(NewSettings1.Overall);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Called when switching to a new version of the 2.4.1.1 configuration.
Procedure AddOpenExternalReportsAndDataProcessorsRightForAdministrators() Export
	
	RoleToAdd = Metadata.Roles.InteractiveOpenExtReportsAndDataProcessors;
	AdministratorRole = Metadata.Roles.SystemAdministrator;
	IBUsers = InfoBaseUsers.GetUsers();
	
	For Each IBUser In IBUsers Do
		
		If IBUser.Roles.Contains(AdministratorRole)
		   And Not IBUser.Roles.Contains(RoleToAdd) Then
			
			IBUser.Roles.Add(RoleToAdd);
			IBUser.Write();
		EndIf;
		
	EndDo;
	
EndProcedure

// Called when switching to a new version of the 2.4.1.1 configuration.
Procedure RenameExternalReportAndDataProcessorOpeningDecisionStorageKey() Export
	
	Block = New DataLock;
	Block.Add("Constant.IBAdministrationParameters");
	
	BeginTransaction();
	Try
		Block.Lock();
		
		IBAdministrationParameters = Constants.IBAdministrationParameters.Get().Get();
		
		If TypeOf(IBAdministrationParameters) = Type("Structure")
		   And IBAdministrationParameters.Property("OpenExternalReportsAndDataProcessorsAllowed") Then
			
			If Not IBAdministrationParameters.Property("OpenExternalReportsAndDataProcessorsDecisionMade")
			   And TypeOf(IBAdministrationParameters.OpenExternalReportsAndDataProcessorsAllowed) = Type("Boolean")
			   And IBAdministrationParameters.OpenExternalReportsAndDataProcessorsAllowed Then
				
				IBAdministrationParameters.Insert("OpenExternalReportsAndDataProcessorsDecisionMade", True);
			EndIf;
			IBAdministrationParameters.Delete("OpenExternalReportsAndDataProcessorsAllowed");
			Constants.IBAdministrationParameters.Set(New ValueStorage(IBAdministrationParameters));
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure FillUserGroupsHierarchy() Export
	InformationRegisters.UserGroupsHierarchy.UpdateRegisterData();
	InformationRegisters.UserGroupCompositions.UpdateRegisterData();
	InformationRegisters.UsersInfo.UpdateRegisterData();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Called from user Settings processing and generates
// a list of user settings.
//
Procedure FillSettingsLists(Parameters, StorageAddress) Export
	
	If Parameters.InfoBaseUser <> UserName()
	   And Not AccessRight("DataAdministration", Metadata) Then
		
		ErrorText = NStr("en = 'Insufficient rights to view user settings.';");
		Raise(ErrorText, ErrorCategory.AccessViolation);
	EndIf;
	
	DataProcessors.UsersSettings.FillSettingsLists(Parameters);
	
	Result = New Structure;
	Result.Insert("InterfaceSettings2");
	Result.Insert("ReportSettingsTree");
	Result.Insert("OtherSettingsTree");
	Result.Insert("UserReportOptions");
	
	FillPropertyValues(Result, Parameters);
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See UsersOverridable.OnGetOtherSettings
Procedure OnGetOtherUserSettings(UserInfo, Settings) Export
	
	SSLSubsystemsIntegration.OnGetOtherSettings(UserInfo, Settings);
	UsersOverridable.OnGetOtherSettings(UserInfo, Settings);
	
EndProcedure

Procedure OnSaveOtherUserSettings(UserInfo, Settings) Export
	
	SSLSubsystemsIntegration.OnSaveOtherSetings(UserInfo, Settings);
	UsersOverridable.OnSaveOtherSetings(UserInfo, Settings);
	
EndProcedure

Procedure OnDeleteOtherUserSettings(UserInfo, Settings) Export
	
	SSLSubsystemsIntegration.OnDeleteOtherSettings(UserInfo, Settings);
	UsersOverridable.OnDeleteOtherSettings(UserInfo, Settings);
	
EndProcedure

// Returns:
//  ValueTable:
//   * Object - String
//   * Id - String
//
Function ANewDescriptionOfSettings() Export
	
	Return New Structure;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// When the slave node is first started, it clears
// the is user IDs that were copied when the initial image was created.
//
Procedure ClearNonExistingIBUsersIDs()
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	BlankUUID = CommonClientServer.BlankUUID();
	
	Query = New Query;
	Query.SetParameter("BlankUUID", BlankUUID);
	
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref,
	|	Users.IBUserID
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.IBUserID <> &BlankUUID
	|
	|UNION ALL
	|
	|SELECT
	|	ExternalUsers.Ref,
	|	ExternalUsers.IBUserID
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.IBUserID <> &BlankUUID";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		IBUser = InfoBaseUsers.FindByUUID(
			Selection.IBUserID);
		
		If IBUser <> Undefined Then
			Continue;
		EndIf;
		
		Block = New DataLock;
		LockItem = Block.Add(Selection.Ref.Metadata().FullName());
		LockItem.SetValue("Ref", Selection.Ref);
		
		BeginTransaction();
		Try
			Block.Lock();
			CurrentObject = Selection.Ref.GetObject();
			CurrentObject.IBUserID = BlankUUID;
			InfobaseUpdate.WriteData(CurrentObject);
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

// Updates the external user's view when the view of their authorization object changes,
// and marks it as invalid if the authorization object is marked for deletion.
//
Procedure UpdateExternalUser(AuthorizationObjectRef, AuthorizationObjectDeletionMark)
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT TOP 1
	|	ExternalUsers.Ref AS Ref,
	|	ExternalUsers.Description AS Description,
	|	ExternalUsers.Invalid AS Invalid,
	|	ExternalUsers.IBUserID AS IBUserID
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.AuthorizationObject = &AuthorizationObjectRef
	|	AND (ExternalUsers.Invalid = FALSE
	|			OR &AuthorizationObjectDeletionMark)");
	
	Query.SetParameter("AuthorizationObjectRef",            AuthorizationObjectRef);
	Query.SetParameter("AuthorizationObjectDeletionMark",    AuthorizationObjectDeletionMark);
	
	BeginTransaction();
	Try
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			Selection = QueryResult.Select();
			Selection.Next();
			
			If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
				
				If ValueIsFilled(Selection.IBUserID) Then
					
					InformationSecurityUser = Users.IBUserProperies(Selection.IBUserID);
					If InformationSecurityUser <> Undefined Then
						
						ModuleContactsManager = Common.CommonModule("ContactsManager");
						
						Email = ModuleContactsManager.NewEmailAddressForPasswordRecovery(
							AuthorizationObjectRef, InformationSecurityUser.Email);
						If Email <> Undefined Then
							InformationSecurityUser.Email = Email;
							Users.SetIBUserProperies(Selection.IBUserID, InformationSecurityUser);
						EndIf;
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If String(AuthorizationObjectRef) <> Selection.Description Then
			
				Block = New DataLock;
				LockItem = Block.Add("Catalog.ExternalUsers");
				LockItem.SetValue("Ref", Selection.Ref);
				Block.Lock();
				
				ExternalUserObject = Selection.Ref.GetObject();
				ExternalUserObject.Description = String(AuthorizationObjectRef);
				If AuthorizationObjectDeletionMark And ExternalUserObject.Invalid = False Then
					ExternalUserObject.Invalid = True;
					If Users.CanSignIn(ExternalUserObject.IBUserID) Then
						ExternalUserObject.AdditionalProperties.Insert("IBUserDetails",
							New Structure("Action, CanSignIn", "Write", False));
					EndIf;
				EndIf;
				ExternalUserObject.Write();
			EndIf;
		
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function CurrentUserInfoRecordErrorTextTemplate()
	
	Return
		NStr("en = 'Couldn''t save the current user details. Reason:
		           |%1
		           |
		           |Please contact the administrator.';");
	
EndFunction

Function AuthorizationNotCompletedMessageTextWithLineBreak()
	
	Return NStr("en = 'The authorization was not completed. The application will be closed.';")
		+ Chars.LF + Chars.LF;
	
EndFunction

Function CurrentUserSessionParameterValues()
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return CurrentUserUnavailableInSessionWithoutSeparatorsMessageText();
	EndIf;
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Couldn''t set session parameter for user ""%1"".';"),
		"CurrentUser") + Chars.LF;
	
	BeginTransaction();
	Try
		UserInfo = FindCurrentUserInCatalog();
		
		If UserInfo.CreateUser Then
			CreateCurrentUserInCatalog(UserInfo);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Not UserInfo.CreateUser
	   And Not UserInfo.UserFound Then
		
		Return ErrorTitle + UserNotFoundInCatalogMessageText(
			UserInfo.UserName);
	EndIf;
	
	If UserInfo.CurrentUser        = Undefined
	 Or UserInfo.CurrentExternalUser = Undefined Then
		
		Return ErrorTitle + UserNotFoundInCatalogMessageText(
				UserInfo.UserName) + Chars.LF
			+ NStr("en = 'Internal user search error.';");
	EndIf;
	
	Values = New Structure;
	Values.Insert("CurrentUser",        UserInfo.CurrentUser);
	Values.Insert("CurrentExternalUser", UserInfo.CurrentExternalUser);
	
	Return Values;
	
EndFunction

Function CurrentUserUnavailableInSessionWithoutSeparatorsMessageText()
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Couldn''t get session parameter for user ""%1"".
		           |Not all session delimiters are specified.';"),
		"CurrentUser");
	
EndFunction

Function FindCurrentUserInCatalog()
	
	Result = New Structure;
	Result.Insert("UserName",             Undefined);
	Result.Insert("UserFullName",       Undefined);
	Result.Insert("IBUserID", Undefined);
	Result.Insert("UserFound",          False);
	Result.Insert("CreateUser",         False);
	Result.Insert("RefToNew",                Undefined);
	Result.Insert("IsInternal",                   False);
	Result.Insert("CurrentUser",         Undefined);
	Result.Insert("CurrentExternalUser",  Catalogs.ExternalUsers.EmptyRef());
	
	CurrentIBUser = InfoBaseUsers.CurrentUser();
	
	If IsBlankString(CurrentIBUser.Name) Then
		UnspecifiedUserProperties = UnspecifiedUserProperties();
		
		Result.UserName       = UnspecifiedUserProperties.FullName;
		Result.UserFullName = UnspecifiedUserProperties.FullName;
		Result.RefToNew          = UnspecifiedUserProperties.StandardRef;
		
		If UnspecifiedUserProperties.Ref = Undefined Then
			Result.CreateUser = True;
			Result.IsInternal = True;
			Result.IBUserID = "";
		Else
			Result.UserFound = True;
			Result.CurrentUser = UnspecifiedUserProperties.Ref;
		EndIf;
		
		Return Result;
	EndIf;

	Result.UserName             = CurrentIBUser.Name;
	Result.IBUserID = CurrentIBUser.UUID;
	
	Users.FindAmbiguousIBUsers(Undefined, Result.IBUserID);
	
	Query = New Query;
	Query.Parameters.Insert("IBUserID", Result.IBUserID);
	
	Query.Text =
	"SELECT TOP 1
	|	ExternalUsers.Ref AS Ref
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.IBUserID = &IBUserID";
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		If Not ExternalUsers.UseExternalUsers() Then
			Raise NStr("en = 'External users are disabled.';");
		EndIf;
		
		Result.CurrentUser        = Catalogs.Users.EmptyRef();
		Result.CurrentExternalUser = Selection.Ref;
		
		Result.UserFound = True;
		Return Result;
	EndIf;

	Query.Text =
	"SELECT TOP 1
	|	Users.Ref AS Ref
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.IBUserID = &IBUserID";
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Result.CurrentUser = Selection.Ref;
		Result.UserFound = True;
		Return Result;
	EndIf;
	
	SSLSubsystemsIntegration.OnNoCurrentUserInCatalog(
		Result.CreateUser);
	
	If Not Result.CreateUser
	   And Not AdministratorRolesAvailable() Then
		
		Return Result;
	EndIf;
	
	Result.IBUserID = CurrentIBUser.UUID;
	Result.UserFullName       = CurrentIBUser.FullName;
	
	If Result.CreateUser Then
		Return Result;
	EndIf;
	
	UserByDescription = UserRefByFullDescription(
		Result.UserFullName);
	
	If UserByDescription <> Undefined Then
		Result.UserFound  = True;
		Result.CurrentUser = UserByDescription;
	Else
		Result.CreateUser = True;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure CreateCurrentUserInCatalog(UserInfo)
	
	BeginTransaction();
	Try
		If UserInfo.RefToNew = Undefined Then
			UserInfo.RefToNew = Catalogs.Users.GetRef();
		EndIf;
		
		UserInfo.CurrentUser = UserInfo.RefToNew;
		
		SessionParameters.CurrentUser        = UserInfo.CurrentUser;
		SessionParameters.CurrentExternalUser = UserInfo.CurrentExternalUser;
		SessionParameters.AuthorizedUser = UserInfo.CurrentUser;
		
		NewUser = Catalogs.Users.CreateItem();
		NewUser.IsInternal    = UserInfo.IsInternal;
		NewUser.Description = UserInfo.UserFullName;
		NewUser.SetNewObjectRef(UserInfo.RefToNew);
		
		If ValueIsFilled(UserInfo.IBUserID) Then
			
			IBUserDetails = New Structure;
			IBUserDetails.Insert("Action", "Write");
			IBUserDetails.Insert("UUID",
				UserInfo.IBUserID);
			
			NewUser.AdditionalProperties.Insert(
				"IBUserDetails", IBUserDetails);
		EndIf;
		
		SSLSubsystemsIntegration.OnAutoCreateCurrentUserInCatalog(
			NewUser);
		
		NewUser.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		ParametersToClear = New Array;
		ParametersToClear.Add("CurrentUser");
		ParametersToClear.Add("CurrentExternalUser");
		ParametersToClear.Add("AuthorizedUser");
		SessionParameters.Clear(ParametersToClear);
		Raise;
	EndTry;
	
EndProcedure

Function UserNotFoundInCatalogMessageText(UserName)
	
	If ExternalUsers.UseExternalUsers() Then
		ErrorMessageTemplate =
			NStr("en = 'User ""%1"" does not exist in the
			           |""Users"" and ""External users"" catalogs.
			           |
			           |Contact your administrator.';");
	Else
		ErrorMessageTemplate =
			NStr("en = 'User ""%1"" does not exist in the ""Users"" catalog.
			           |
			           |Contact your administrator.';");
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageTemplate, UserName);
	
EndFunction

Function UserRefByFullDescription(FullName)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref,
	|	Users.IBUserID
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Description = &FullName";
	
	Query.SetParameter("FullName", FullName);
	
	Result = Undefined;
	
	BeginTransaction();
	Try
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			
			Selection = QueryResult.Select();
			Selection.Next();
			
			If Not Users.IBUserOccupied(Selection.IBUserID) Then
				Result = Selection.Ref;
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Result;
	
EndFunction

Function SessionParametersSettingResult(RegisterInLog)
	
	Try
		Users.AuthorizedUser();
	Except
		ErrorInfo = ErrorInfo();
		Return AuthorizationErrorBriefPresentationAfterRegisterInLog(ErrorInfo,
			, RegisterInLog);
	EndTry;
	
	Return "";
	
EndFunction

Function AuthorizationErrorBriefPresentationAfterRegisterInLog(ErrorInfo, ErrorTemplate = "", RegisterInLog = True)
	
	If TypeOf(ErrorInfo) = Type("ErrorInfo") Then
		BriefPresentation   = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		DetailedPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo);
	Else
		BriefPresentation   = ErrorInfo;
		DetailedPresentation = ErrorInfo;
	EndIf;
	
	If ValueIsFilled(ErrorTemplate) Then
		BriefPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate, ErrorProcessing.BriefErrorDescription(ErrorInfo));
		
		DetailedPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate, ErrorProcessing.DetailErrorDescription(ErrorInfo));
	EndIf;
	
	BriefPresentation   = AuthorizationNotCompletedMessageTextWithLineBreak() + BriefPresentation;
	DetailedPresentation = AuthorizationNotCompletedMessageTextWithLineBreak() + DetailedPresentation;
	
	If RegisterInLog Then
		WriteLogEvent(
			EventNameLoginErrorForTheLogLog(),
			EventLogLevel.Error, , , DetailedPresentation);
	EndIf;
	
	Return BriefPresentation;
	
EndFunction

Function EventNameLoginErrorForTheLogLog()
	
	Return NStr("en = 'Users.Authorization error';", Common.DefaultLanguageCode());
	
EndFunction

// 
Procedure WriteNewGroupParents(TreeRows, NewParents, Val LevelOfParent,
			ChangesInComposition, Check, HigherLevelGroup = Undefined)
	
	LevelOfParent = LevelOfParent + 1;
	NewRow = NewParents.Add();
	
	// 
	For Each TreeRow In TreeRows Do
		If TreeRow.Ref = HigherLevelGroup Then
			Continue;
		EndIf;
		NewRow.Parent = TreeRow.Ref;
		NewRow.LevelOfParent = LevelOfParent;
		NewParents.FillValues(TreeRow.Ref, "UsersGroup");
		NewParents.FillValues(LevelOfParent, "GroupLevel");
		
		HasChanges = Not Check;
		If Check Then
			RecordSet = InformationRegisters.UserGroupsHierarchy.CreateRecordSet();
			RecordSet.Filter.UsersGroup.Set(TreeRow.Ref);
			RecordSet.Read();
			If RecordSet.Count() = NewParents.Count() Then
				Filter = New Structure("UsersGroup, Parent, LevelOfParent, GroupLevel");
				For Each Record In RecordSet Do
					FillPropertyValues(Filter, Record);
					If NewParents.FindRows(Filter).Count() <> 1 Then
						HasChanges = True;
						Break;
					EndIf;
				EndDo;
			Else
				HasChanges = True;
			EndIf;
		EndIf;
		If HasChanges Then
			RecordSet = InformationRegisters.UserGroupsHierarchy.CreateRecordSet();
			RecordSet.Filter.UsersGroup.Set(TreeRow.Ref);
			RecordSet.Load(NewParents);
			RecordSet.Write();
			ChangesInComposition.ModifiedGroups.Insert(TreeRow.Ref);
		EndIf;
		WriteNewGroupParents(TreeRow.Rows,
			NewParents, LevelOfParent, ChangesInComposition, Check, TreeRow.Ref);
	EndDo;
	// 
	
	NewParents.Delete(NewRow);
	
EndProcedure

// Parameters:
//  UserOrGroup - CatalogRef.UserGroups
//                        - CatalogRef.ExternalUsersGroups
//                        - CatalogRef.Users
//                        - CatalogRef.ExternalUsers
//
//  ChangesInComposition - See GroupsCompositionNewChanges
//
Procedure UpdateCompositionBeforeDeleteGroupWithoutHierarchyOrUser(UserOrGroup, ChangesInComposition)
	
	SetPrivilegedMode(True);
	
	If TypeOf(UserOrGroup) = Type("CatalogRef.Users")
	 Or TypeOf(UserOrGroup) = Type("CatalogRef.ExternalUsers") Then
		
		FieldName = "User";
	Else
		FieldName = "UsersGroup";
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.UserGroupCompositions");
	LockItem.SetValue(FieldName, UserOrGroup);
	
	ItemsToChange = ChangesInComposition.ItemsToChange;
	ModifiedGroups   = ChangesInComposition.ModifiedGroups;
	ForRegistration     = ChangesInComposition.ForRegistration;
	
	BeginTransaction();
	Try
		Block.Lock();
		RecordSet = InformationRegisters.UserGroupCompositions.CreateRecordSet();
		RecordSet.AdditionalProperties.Insert("IsStandardRegisterUpdate");
		RecordSet.Filter[FieldName].Set(UserOrGroup);
		RecordSet.Read();
		IndexOf = RecordSet.Count();
		HasChanges = IndexOf > 0;
		While IndexOf > 0 Do
			IndexOf = IndexOf - 1;
			Record = RecordSet.Get(IndexOf);
			ItemsToChange.Insert(Record.User);
			ModifiedGroups.Insert(Record.UsersGroup);
			If ForRegistration <> Undefined Then
				AddCompositionChange(ForRegistration, Record, True);
			EndIf;
			RecordSet.Delete(Record);
		EndDo;
		If HasChanges Then
			RecordSet.Write();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Checks the rights of the specified information security user.
//
// Parameters:
//  IBUser         - InfoBaseUser -  the user being checked.
//  CheckMode          - String -  When recording or Restarting.
//  IsExternalUser - Boolean -  check permissions for an external user.
//  RaiseException1     - Boolean -  raise an exception instead of returning the error text.
//  RegisterInLog - Boolean -  write an error to the log
//                                    when calling an exception specified False.
//
// Returns:
//  String - 
//
Function CheckUserRights(IBUser, CheckMode, IsExternalUser,
			RaiseException1 = True, RegisterInLog = True)
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	If DataSeparationEnabled And IBUser.DataSeparation.Count() = 0 Then
		Return ""; // 
	EndIf;
	
	If Not DataSeparationEnabled And CheckMode = "OnStart" And Not IsExternalUser Then
		Return ""; // 
	EndIf;
	
	// 
	// 
	If IsExternalUser And CheckMode = "OnStart" Then
		Return "";
	EndIf;
	// _Demo example end
	UnavailableRoles = UnavailableRolesByUserType(IsExternalUser);
	
	RolesToCheck = New ValueTable;
	RolesToCheck.Columns.Add("Role", New TypeDescription("MetadataObject"));
	For Each Role In IBUser.Roles Do
		RolesToCheck.Add().Role = Role;
	EndDo;
	RolesToCheck.Indexes.Add("Role");
	
	If Not DataSeparationEnabled And CheckMode = "BeforeWrite" Then
		
		PreviousIBUser = InfoBaseUsers.FindByUUID(
			IBUser.UUID);
		
		If PreviousIBUser <> Undefined Then
			For Each Role In PreviousIBUser.Roles Do
				String = RolesToCheck.Find(Role, "Role");
				If String <> Undefined Then
					RolesToCheck.Delete(String);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	UnavailableRolesToAdd = "";
	RolesAssignment = Undefined;
	
	For Each RoleDetails In RolesToCheck Do
		Role = RoleDetails.Role;
		NameOfRole = Role.Name;
		
		If UnavailableRoles.Get(NameOfRole) = Undefined Then
			Continue;
		EndIf;
		
		If RolesAssignment = Undefined Then
			RolesAssignment = UsersInternalCached.RolesAssignment();
		EndIf;
		
		If RolesAssignment.ForSystemAdministratorsOnly.Get(NameOfRole) <> Undefined Then
			TemplateText = NStr("en = '""%1"" (for system administrators only)';");
		
		ElsIf DataSeparationEnabled
		        And RolesAssignment.ForSystemUsersOnly.Get(NameOfRole) <> Undefined Then
			
			TemplateText = NStr("en = '""%1"" (for system users only)';");
			
		ElsIf RolesAssignment.ForExternalUsersOnly.Get(NameOfRole) <> Undefined Then
			TemplateText = NStr("en = '""%1"" (for external users only)';");
			
		Else // 
			TemplateText = NStr("en = '""%1"" (for users only)';");
		EndIf;
		
		UnavailableRolesToAdd = UnavailableRolesToAdd
			+ StringFunctionsClientServer.SubstituteParametersToString(TemplateText, Role.Presentation()) + Chars.LF;
	EndDo;
	
	UnavailableRolesToAdd = TrimAll(UnavailableRolesToAdd);
	
	If Not ValueIsFilled(UnavailableRolesToAdd) Then
		Return "";
	EndIf;
	
	If CheckMode = "OnStart" Then
		If RaiseException1 Or RegisterInLog Then
			If StrLineCount(UnavailableRolesToAdd) = 1 Then
				AuthorizationRegistrationText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Authorization denied for user ""%1"". The user has an unavailable role:
					           |%2';"),
				IBUser.FullName, UnavailableRolesToAdd);
			Else
				AuthorizationRegistrationText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Authorization denied for user ""%1"". The user has unavailable roles:
					           |%2';"),
				IBUser.FullName, UnavailableRolesToAdd);
			EndIf;
			WriteLogEvent(EventNameLoginErrorForTheLogLog(),
				EventLogLevel.Error, , IBUser, AuthorizationRegistrationText);
		EndIf;
		
		AuthorizationMessageText =
			NStr("en = 'Authorization denied due to unavailable roles.
			           |Please contact the administrator.';");
		
		If RaiseException1 Then
			Raise AuthorizationMessageText;
		Else
			Return AuthorizationMessageText;
		EndIf;
	EndIf;
	
	If RaiseException1 Or RegisterInLog Then
		If StrLineCount(UnavailableRolesToAdd) = 1 And ValueIsFilled(UnavailableRolesToAdd) Then
			AddingRegistrationText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot assign the following unavailable role to user ""%1"":
				           |%2.';"),
				IBUser.FullName, UnavailableRolesToAdd);
				
		ElsIf StrLineCount(UnavailableRolesToAdd) > 1 Then
			AddingRegistrationText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot assign the following unavailable roles to user ""%1"":
				           |%2.';"),
				IBUser.FullName, UnavailableRolesToAdd);
		Else
			AddingRegistrationText = "";
		EndIf;
		EventName = NStr("en = 'Users.Error setting roles for infobase user';",
			Common.DefaultLanguageCode());
		
		WriteLogEvent(EventName, EventLogLevel.Error, , IBUser,
			AddingRegistrationText);
	EndIf;
	
	If StrLineCount(UnavailableRolesToAdd) = 1 And ValueIsFilled(UnavailableRolesToAdd) Then
		AddingMessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot assign the following unavailable role to user ""%1"":
			           |%2.';"),
			IBUser.FullName, UnavailableRolesToAdd);
		
	ElsIf StrLineCount(UnavailableRolesToAdd) > 1 Then
		AddingMessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot assign the following unavailable roles to user ""%1"":
			           |%2.';"),
			IBUser.FullName, UnavailableRolesToAdd);
	Else
		AddingMessageText = "";
	EndIf;
	
	If RaiseException1 Then
		Raise AddingMessageText;
	Else
		Return AddingMessageText;
	EndIf;
	
EndFunction

Function SettingsList(IBUserName, SettingsManager)
	
	SettingsTable = New ValueTable;
	SettingsTable.Columns.Add("ObjectKey");
	SettingsTable.Columns.Add("SettingsKey");
	
	Filter = New Structure;
	Filter.Insert("User", IBUserName);
	
	SettingsSelection = SettingsManager.Select(Filter);
	Ignore = False;
	While NextSettingsItem(SettingsSelection, Ignore) Do
		
		If Ignore Then
			Continue;
		EndIf;
		
		NewRow = SettingsTable.Add();
		NewRow.ObjectKey = SettingsSelection.ObjectKey;
		NewRow.SettingsKey = SettingsSelection.SettingsKey;
	EndDo;
	
	Return SettingsTable;
	
EndFunction

Function NextSettingsItem(SettingsSelection, Ignore) 
	
	Try 
		Ignore = False;
		Return SettingsSelection.Next();
	Except
		Ignore = True;
		Return True;
	EndTry;
	
EndFunction

Procedure CopySettings(SettingsManager, UserNameSource, UserNameDestination, Wrap)
	
	SettingsTable = SettingsList(UserNameSource, SettingsManager);
	
	For Each Setting In SettingsTable Do
		ObjectKey = Setting.ObjectKey;
		SettingsKey = Setting.SettingsKey;
		Try
			Value = SettingsManager.Load(ObjectKey, SettingsKey, , UserNameSource);
		Except
			ErrorInfo = ErrorInfo();
			Comment = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot import the setting value when copying the setting from user ""%1""
				           |to user ""%2""
				           |with the ""%3"" object key and
				           |the ""%4"" setting key.
				           |Reason:
				           |%5';"),
				UserNameSource,
				UserNameDestination,
				ObjectKey,
				SettingsKey,
				ErrorProcessing.DetailErrorDescription(ErrorInfo));
			WriteLogEvent(
				NStr("en = 'Users.Copy settings';",
				     Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				Comment);
			CanProceed = True;
			Try
				Catalogs.Users.FindByDescription(String(New UUID()), True);
			Except
				CanProceed = False;
			EndTry;
			If CanProceed Then
				Continue;
			EndIf;
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot copy the setting to the user due to:
				           |%1
				           |
				           |For more information, see the event log.';"),
				ErrorProcessing.BriefErrorDescription(ErrorInfo));
			Raise ErrorText;
		EndTry;
		SettingsDescription = SettingsManager.GetDescription(ObjectKey, SettingsKey, UserNameSource);
		SettingsManager.Save(ObjectKey, SettingsKey, Value,
			SettingsDescription, UserNameDestination);
		If Wrap Then
			SettingsManager.Delete(ObjectKey, SettingsKey, UserNameSource);
		EndIf;
	EndDo;
	
EndProcedure

Procedure CopyOtherUserSettings(UserNameSource, UserNameDestination)
	
	UserSourceRef = Users.FindByName(UserNameSource);
	UserDestinationRef = Users.FindByName(UserNameDestination);
	SourceUserInfo = New Structure;
	SourceUserInfo.Insert("UserRef", UserSourceRef);
	SourceUserInfo.Insert("InfobaseUserName", UserNameSource);
	
	DestinationUserInfo = New Structure;
	DestinationUserInfo.Insert("UserRef", UserDestinationRef);
	DestinationUserInfo.Insert("InfobaseUserName", UserNameDestination);
	
	// 
	OtherUserSettings = New Structure; // See OnGetOtherUserSettings.Settings
	OnGetOtherUserSettings(SourceUserInfo, OtherUserSettings);
	Keys = New ValueList;
	
	If OtherUserSettings.Count() <> 0 Then
		
		For Each OtherSetting In OtherUserSettings Do
			OtherSettingsStructure = New Structure;
			If OtherSetting.Key = "QuickAccessSetting" Then
				SettingsList = OtherSetting.Value.SettingsList; // See ANewDescriptionOfSettings
				For Each Item In SettingsList Do
					Keys.Add(Item.Object, Item.Id);
				EndDo;
				OtherSettingsStructure.Insert("SettingID", "QuickAccessSetting");
				OtherSettingsStructure.Insert("SettingValue", Keys);
			Else
				OtherSettingsStructure.Insert("SettingID", OtherSetting.Key);
				OtherSettingsStructure.Insert("SettingValue", OtherSetting.Value.SettingsList);
			EndIf;
			OnSaveOtherUserSettings(DestinationUserInfo, OtherSettingsStructure);
		EndDo;
		
	EndIf;
	
EndProcedure

// Copies the user's settings.
//
// Parameters:
//  UserObject - CatalogObject.Users
//                     - CatalogObject.ExternalUsers
//  ProcessingParameters - Structure:
//    * NewIBUserDetails1 - See Users.NewIBUserDetails
//
Procedure CopyIBUserSettings(UserObject, ProcessingParameters)
	
	If Not ProcessingParameters.Property("CopyingValue")
	 Or Not ProcessingParameters.NewIBUserExists Then
		
		Return;
	EndIf;
	
	NameOfTheNewIBUser = ProcessingParameters.NewIBUserDetails1.Name;
	
	SourceIBUserID = Common.ObjectAttributeValue(
		ProcessingParameters.CopyingValue, "IBUserID");
	
	If Not ValueIsFilled(SourceIBUserID) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	SourceIBUserDetails = Users.IBUserProperies(SourceIBUserID);
	If SourceIBUserDetails = Undefined Then
		Return;
	EndIf;
	SetPrivilegedMode(False);
	
	SourceIBUserName = SourceIBUserDetails.Name;
	
	// 
	CopyUserSettings(SourceIBUserName, NameOfTheNewIBUser, False);
	
EndProcedure

Procedure CheckRoleRightsList(UnavailableRights, RolesDetails, GeneralErrorText, ErrorTitle, ErrorList, Shared_Data = Undefined)
	
	ErrorText = "";
	
	For Each RoleDetails In RolesDetails Do
		Role = RoleDetails.Key;
		For Each UnavailableRight In UnavailableRights Do
			If AccessRight(UnavailableRight, Metadata, Role) Then
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Role ""%1"" contains unavailable right %2.';"),
					Role, UnavailableRight);
				If ErrorList = Undefined Then
					ErrorText = ErrorText + Chars.LF + ErrorDescription;
				Else
					ErrorList.Add(Role, ErrorTitle + Chars.LF + ErrorDescription);
				EndIf;
			EndIf;
		EndDo;
		If Shared_Data = Undefined Then
			Continue;
		EndIf;
		For Each DataProperties In Shared_Data Do
			MetadataObject = DataProperties.Value;
			If Not AccessRight("Read", MetadataObject, Role) Then
				Continue;
			EndIf;
			If AccessRight("Update", MetadataObject, Role) Then
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Role ""%1"" contains the ""Update"" right for shared object %2.';"),
					Role, MetadataObject.FullName());
				If ErrorList = Undefined Then
					ErrorText = ErrorText + Chars.LF + ErrorDescription;
				Else
					ErrorList.Add(MetadataObject, ErrorTitle + Chars.LF + ErrorDescription);
				EndIf;
			EndIf;
			If DataProperties.Presentation = "" Then
				Continue; // 
			EndIf;
			If AccessRight("Insert", MetadataObject, Role) Then
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Role ""%1"" contains the ""Insert"" right for shared object %2.';"),
					Role, MetadataObject.FullName());
				If ErrorList = Undefined Then
					ErrorText = ErrorText + Chars.LF + ErrorDescription;
				Else
					ErrorList.Add(MetadataObject, ErrorTitle + Chars.LF + ErrorDescription);
				EndIf;
			EndIf;
			If AccessRight("Delete", MetadataObject, Role) Then
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Role ""%1"" contains the ""Delete"" right for shared object %2.';"),
					Role, MetadataObject.FullName());
				If ErrorList = Undefined Then
					ErrorText = ErrorText + Chars.LF + ErrorDescription;
				Else
					ErrorList.Add(MetadataObject, ErrorTitle + Chars.LF + ErrorDescription);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	If ValueIsFilled(ErrorText) Then
		GeneralErrorText = GeneralErrorText + Chars.LF + Chars.LF
			+ ErrorTitle + ErrorText;
	EndIf;
	
EndProcedure

Function Shared_Data()
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		Return Undefined;
	EndIf;
	
	List = New ValueList;
	
	MetadataKinds = New Array;
	MetadataKinds.Add(New Structure("Kind, Referential" , Metadata.ExchangePlans,             True));
	MetadataKinds.Add(New Structure("Kind, Referential" , Metadata.Constants,               False));
	MetadataKinds.Add(New Structure("Kind, Referential" , Metadata.Catalogs,             True));
	MetadataKinds.Add(New Structure("Kind, Referential" , Metadata.Sequences,      False));
	MetadataKinds.Add(New Structure("Kind, Referential" , Metadata.Documents,               True));
	MetadataKinds.Add(New Structure("Kind, Referential" , Metadata.ChartsOfCharacteristicTypes, True));
	MetadataKinds.Add(New Structure("Kind, Referential" , Metadata.ChartsOfAccounts,             True));
	MetadataKinds.Add(New Structure("Kind, Referential" , Metadata.ChartsOfCalculationTypes,       True));
	MetadataKinds.Add(New Structure("Kind, Referential" , Metadata.BusinessProcesses,          True));
	MetadataKinds.Add(New Structure("Kind, Referential" , Metadata.Tasks,                  True));
	MetadataKinds.Add(New Structure("Kind, Referential" , Metadata.InformationRegisters,        False));
	MetadataKinds.Add(New Structure("Kind, Referential" , Metadata.AccumulationRegisters,      False));
	MetadataKinds.Add(New Structure("Kind, Referential" , Metadata.AccountingRegisters,     False));
	MetadataKinds.Add(New Structure("Kind, Referential" , Metadata.CalculationRegisters,         False));
	
	SetPrivilegedMode(True);
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	DataModel = ModuleSaaSOperations.GetAreaDataModel();
	
	SeparatedMetadataObjects = New Map;
	For Each DataModelItem In DataModel Do
		MetadataObject = Common.MetadataObjectByFullName(DataModelItem.Key);
		SeparatedMetadataObjects.Insert(MetadataObject, True);
	EndDo;
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	SeparatedDataUsageAvailable = Common.SeparatedDataUsageAvailable();
	
	For Each KindDetails In MetadataKinds Do // 
		For Each MetadataObject In KindDetails.Kind Do // 
			If SeparatedMetadataObjects.Get(MetadataObject) <> Undefined Then
				Continue;
			EndIf;
			If SeparatedDataUsageAvailable Then
				ConfigurationExtension = MetadataObject.ConfigurationExtension();
				If ConfigurationExtension <> Undefined
				   And (Not DataSeparationEnabled
				      Or ConfigurationExtension.Scope = ConfigurationExtensionScope.DataSeparation) Then
					Continue;
				EndIf;
			EndIf;
			List.Add(MetadataObject, ?(KindDetails.Referential, "Referential", ""));
		EndDo;
	EndDo;
	
	Return List;
	
EndFunction

Function SecurityWarningKeyOnStart()
	
	If IsBlankString(InfoBaseUsers.CurrentUser().Name) Then
		Return Undefined; // 
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Return Undefined; // 
	EndIf;
	
	If PrivilegedMode() Then
		Return Undefined; // 
	EndIf;
	
	If Common.IsSubordinateDIBNode()
		And Not Common.IsStandaloneWorkplace() Then
		Return Undefined; // 
	EndIf;
	
	SetPrivilegedMode(True);
	If Not PrivilegedMode() Then
		Return Undefined; // 
	EndIf;
	
	AdministrationParameters = StandardSubsystemsServer.AdministrationParameters();
	DecisionMade = AdministrationParameters.OpenExternalReportsAndDataProcessorsDecisionMade;
	If TypeOf(DecisionMade) <> Type("Boolean") Then
		DecisionMade = False;
	EndIf;
	SetPrivilegedMode(False);
	
	IsSystemAdministrator = Users.IsFullUser(, True, False);
	If IsSystemAdministrator And Not DecisionMade Then
		Return UsersInternalClientServer.TypesOfSafetyWarnings().AfterUpdate;
	EndIf;
	
	If DecisionMade Then
		If AccessRight("InteractiveOpenExtDataProcessors", Metadata)
		 Or AccessRight("InteractiveOpenExtReports", Metadata) Then
			
			UserAccepts = Common.CommonSettingsStorageLoad(
				"SecurityWarning", "UserAccepts", False);
			
			If Not UserAccepts Then
				Return UsersInternalClientServer.TypesOfSafetyWarnings().AfterObtainRight;
			EndIf;
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns:
//  Structure:
//   * ForSystemAdministratorsOnly - Map of KeyAndValue:
//      ** Key     - MetadataObject -  role.
//      ** Value - Boolean -  Truth.
//   * ForSystemUsersOnly - Map of KeyAndValue:
//      ** Key     - MetadataObject -  role.
//      ** Value - Boolean -  Truth.
//   * ForExternalUsersOnly - Map of KeyAndValue:
//      ** Key     - MetadataObject -  role.
//      ** Value - Boolean -  Truth.
//   * BothForUsersAndExternalUsers - Map of KeyAndValue:
//      ** Key     - MetadataObject -  role.
//      ** Value - Boolean -  Truth.
//
Function RolesAssignment()
	Return New Structure;
EndFunction

// Parameters:
//   
//   
//   
//   
//
// Returns:
//  Structure:
//   * Name - String - 
//   * Presentation - String - 
//   * ValueType - TypeDescription
//   * IsInternal - Boolean
//
Function NewExternalAttribute(Name, Presentation, ValueType, IsInternal = False)
	
	Result = New Structure;
	Result.Insert("Name", Name);
	Result.Insert("Presentation", Presentation);
	Result.Insert("ValueType", ValueType);
	Result.Insert("IsInternal", IsInternal);
	
	Return Result;
	
EndFunction

Function ExternalAttributePrefix()
	Return "Users" + "_";
EndFunction

Function EventNameChangeLoginSettingsAdditionalForLogging() Export
	
	Return NStr("en = 'Users.Change login settings (additional)';",
		Common.DefaultLanguageCode());
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// For procedures that are sent to the Main, sent to the Subordinate,
// Prepolycondensation, Prepolycondensation.
//
Function UsersSubsystemObjectForCreatingInitialImageOnly(DataElement)
	
	Return TypeOf(DataElement) = Type("InformationRegisterRecordSet.UserGroupsHierarchy")
	    Or TypeOf(DataElement) = Type("InformationRegisterRecordSet.UserGroupCompositions");
	
EndFunction

// Overrides the standard behavior when uploading data.
// The useridentifierib details are not transferred.
//
Procedure OnSendData(DataElement, ItemSend, Subordinate1, InitialImageCreating)
	
	If InitialImageCreating Then
		// 
		// 
		Return;
	EndIf;
	
	// 
	If ItemSend = DataItemSend.Delete
	 Or ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	If UsersSubsystemObjectForCreatingInitialImageOnly(DataElement) Then
		ItemSend = DataItemSend.Ignore;
		Return;
	EndIf;
	
	ElementType = TypeOf(DataElement);
	
	If ElementType = Type("CatalogObject.Users")
	 Or ElementType = Type("CatalogObject.ExternalUsers") Then
		
		DataElement.IBUserID = CommonClientServer.BlankUUID();
		
		DataElement.Prepared = False;
		DataElement.DeleteInfobaseUserProperties = New ValueStorage(Undefined);
	EndIf;
	
EndProcedure

// Overrides the standard behavior when loading data.
// The user ID ID is not transferred, because it always
// refers to the user of the current information database or is not filled in.
//
Procedure OnDataGet(DataElement, ItemReceive, SendBack, FromSubordinate)
	
	// 
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	If UsersSubsystemObjectForCreatingInitialImageOnly(DataElement) Then
		ItemReceive = DataItemReceive.Ignore;
		Return;
	EndIf;
	
	ElementType = TypeOf(DataElement);
	
	If FromSubordinate And Common.DataSeparationEnabled() Then
		If ElementType = Type("ConstantValueManager.UseExternalUsers")
		 Or ElementType = Type("ConstantValueManager.UseUserGroups")
		 Or ElementType = Type("ConstantValueManager.UseExternalUserGroups")
		 Or ElementType = Type("CatalogObject.Users")
		 Or ElementType = Type("CatalogObject.UserGroups")
		 Or ElementType = Type("CatalogObject.ExternalUsers")
		 Or ElementType = Type("CatalogObject.ExternalUsersGroups") Then
			// 
			// 
			SendBack = True;
			ItemReceive = DataItemReceive.Ignore;
			Return;
		EndIf;
		
	ElsIf FromSubordinate Then
		If ElementType = Type("ConstantValueManager.UseExternalUsers")
		 Or ElementType = Type("ConstantValueManager.UseUserGroups")
		 Or ElementType = Type("ConstantValueManager.UseExternalUserGroups") Then
			// 
			// 
			SendBack = True;
			ItemReceive = DataItemReceive.Ignore;
			Return;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If ElementType = Type("ConstantValueManager.UseExternalUsers") Then
		Constants.UseExternalUsers.CreateValueManager().RegisterChangeUponDataImport(DataElement);
		
	ElsIf ElementType = Type("CatalogObject.UserGroups")
	      Or ElementType = Type("CatalogObject.ExternalUsersGroups") Then
		
		RegisterGroupsChangeUponDataImport(DataElement);
		
	ElsIf ElementType = Type("CatalogObject.Users")
	      Or ElementType = Type("CatalogObject.ExternalUsers") Then
		
		RegisterUsersChangeUponDataImport(DataElement);
	EndIf;
	
	If ElementType <> Type("ObjectDeletion") Then
		Return;
	EndIf;
	
	DataElement = DataElement; // ObjectDeletion
	RefType = TypeOf(DataElement.Ref);
	
	If RefType = Type("CatalogRef.UserGroups")
	 Or RefType = Type("CatalogRef.ExternalUsersGroups") Then
		
		RegisterGroupsChangeUponDataImport(DataElement);
		
	ElsIf RefType = Type("CatalogRef.Users")
	      Or RefType = Type("CatalogRef.ExternalUsers") Then
		
		RegisterUsersChangeUponDataImport(DataElement);
	EndIf;
	
EndProcedure

// 
Procedure RegisterGroupsChangeUponDataImport(DataElement)
	
	PreviousValues1 = Common.ObjectAttributesValues(DataElement.Ref,
		"Ref, Parent");
	
	If TypeOf(DataElement) = Type("ObjectDeletion") Then
		If PreviousValues1.Ref <> Undefined Then
			UpdateGroupsCompositionBeforeDeleteUserOrGroup(DataElement.Ref);
		EndIf;
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	ObjectRef2 = ObjectRef2(DataElement);
	Values = New Array;
	Values.Add(ObjectRef2);
	
	If PreviousValues1.Parent <> DataElement.Parent Then
		If ValueIsFilled(PreviousValues1.Parent) Then
			Values.Add(PreviousValues1.Parent);
		EndIf;
		If TypeOf(ObjectRef2) = Type("CatalogRef.ExternalUsersGroups") Then
			RegisterRefs("ExternalUsersGroupsHierarchy", ObjectRef2);
		Else
			RegisterRefs("UsersGroupsHierarchy", ObjectRef2);
		EndIf;
	EndIf;
	
	If TypeOf(ObjectRef2) = Type("CatalogRef.ExternalUsersGroups") Then
		RegisterRefs("ExternalUsersGroups", Values);
	Else
		RegisterRefs("UserGroups", Values);
	EndIf;
	
EndProcedure

// 
Procedure RegisterUsersChangeUponDataImport(DataElement)
	
	IsExternalUser = TypeOf(DataElement.Ref) = Type("CatalogRef.ExternalUsers");
	ListOfPropertiesToRecover = "IBUserID, Prepared, DeleteInfobaseUserProperties";
	
	PreviousValues1 = Common.ObjectAttributesValues(DataElement.Ref,
		"Ref, DeletionMark, Invalid, " + ListOfPropertiesToRecover
		+ ?(IsExternalUser, ", " + "AuthorizationObject", ""));
	
	If TypeOf(DataElement) = Type("ObjectDeletion") Then
		Try
			Object = DataElement.Ref.GetObject();
		Except
			Object = True;
		EndTry;
		If Object <> Undefined Then
			UserObjectBeforeDelete(Object, True);
		Else
			SetPrivilegedMode(True);
			InformationRegisters.UsersInfo.DeleteUserInfo(DataElement.Ref);
			SetPrivilegedMode(False);
		EndIf;
		If PreviousValues1.Ref <> Undefined Then
			UpdateGroupsCompositionBeforeDeleteUserOrGroup(DataElement.Ref);
		EndIf;
		Return;
	EndIf;
	
	FillPropertyValues(DataElement, PreviousValues1, ListOfPropertiesToRecover);
	DataElement.AdditionalProperties.Insert("WriteDuringDataExchange");
	
	SetPrivilegedMode(True);
	
	If IsExternalUser
	   And PreviousValues1.AuthorizationObject <> DataElement.AuthorizationObject Then
		
		Values = New Array;
		If ValueIsFilled(PreviousValues1.AuthorizationObject) Then
			Values.Add(PreviousValues1.AuthorizationObject);
		EndIf;
		Values.Add(DataElement.AuthorizationObject);
		RegisterRefs("ExternalUsersAuthorizationObjects", Values);
	EndIf;
	
	If PreviousValues1.Ref          = DataElement.Ref
	   And PreviousValues1.Invalid  = DataElement.Invalid
	   And PreviousValues1.DeletionMark = DataElement.DeletionMark Then
		
		Return;
	EndIf;
	
	If TypeOf(DataElement.Ref) = Type("CatalogRef.ExternalUsers") Then
		RegisterRefs("ExternalUsersGroups",
			ExternalUsers.AllExternalUsersGroup());
		RegisterRefs("ExternalUsers",
			ObjectRef2(DataElement));
	Else
		RegisterRefs("UserGroups",
			Users.AllUsersGroup());
		RegisterRefs("Users",
			ObjectRef2(DataElement));
	EndIf;
	
EndProcedure

// 
Procedure UpdateAuxiliaryDataOfItemsModifiedUponDataImport()
	
	If Common.DataSeparationEnabled() Then
		// 
		Return;
	EndIf;
	
	Constants.UseExternalUsers.CreateValueManager().ProcessChangeRegisteredUponDataImport();
	
	RegistrationCleanup = New Array;
	
	// 
	ChangesInComposition = GroupsCompositionNewChanges();
	
	BeginTransaction();
	Try
		SetPrivilegedMode(True);
		ProcessRegisteredChangeInHierarchy("UsersGroupsHierarchy",
			Catalogs.UserGroups.EmptyRef(), ChangesInComposition, RegistrationCleanup);
		
		ProcessRegisteredChangeInGroups("UserGroups",
			Catalogs.UserGroups.EmptyRef(), ChangesInComposition, RegistrationCleanup);
		
		ProcessRegisteredChangeInUsers("Users",
			Catalogs.Users.EmptyRef(), ChangesInComposition, RegistrationCleanup);
		SetPrivilegedMode(False);
		
		AfterUserGroupsUpdate(ChangesInComposition);
		
		SetPrivilegedMode(True);
		For Each RefsKindName In RegistrationCleanup Do
			RegisterRefs(RefsKindName, Null);
		EndDo;
		SetPrivilegedMode(False);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	// 
	ChangesInComposition = GroupsCompositionNewChanges();
	
	BeginTransaction();
	Try
		SetPrivilegedMode(True);
		ProcessRegisteredChangeInHierarchy("ExternalUsersGroupsHierarchy",
			Catalogs.ExternalUsersGroups.EmptyRef(), ChangesInComposition, RegistrationCleanup);
		
		ProcessRegisteredChangeInGroups("ExternalUsersGroups",
			Catalogs.ExternalUsersGroups.EmptyRef(), ChangesInComposition, RegistrationCleanup);
		
		ProcessRegisteredChangeInUsers("ExternalUsers",
			Catalogs.ExternalUsers.EmptyRef(), ChangesInComposition, RegistrationCleanup);
		SetPrivilegedMode(False);
		
		AfterUserGroupsUpdate(ChangesInComposition);
		
		SetPrivilegedMode(True);
		ProcessRegisteredChangeInAuthorizationObjects("ExternalUsersAuthorizationObjects",
			RegistrationCleanup);
		For Each RefsKindName In RegistrationCleanup Do
			RegisterRefs(RefsKindName, Null);
		EndDo;
		SetPrivilegedMode(False);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// 
Procedure ProcessRegisteredChangeInHierarchy(RefsKindName, RefAllGroups,
			ChangesInComposition, RegistrationCleanup)
	
	HierarchyGroups = RegisteredRefs(RefsKindName);
	
	If HierarchyGroups.Count() = 0 Then
		Return;
	EndIf;
	
	If HierarchyGroups.Count() = 1 And HierarchyGroups[0] = Undefined
	 Or HierarchyGroups.Count() > 30 Then
		
		UpdateGroupsHierarchy(RefAllGroups, ChangesInComposition);
	Else
		For Each Group In HierarchyGroups Do
			// 
			UpdateGroupsHierarchy(Group, ChangesInComposition);
		EndDo;
	EndIf;
	
	RegistrationCleanup.Add(RefsKindName);
	
EndProcedure

// 
Procedure ProcessRegisteredChangeInGroups(RefsKindName, RefAllGroups,
			ChangesInComposition, RegistrationCleanup)
	
	Groups = RegisteredRefs(RefsKindName);
	
	If Groups.Count() = 0 Then
		Return;
	EndIf;
	
	If TypeOf(RefAllGroups) = Type("CatalogRef.ExternalUsersGroups") Then
		RefAllUsers = Catalogs.ExternalUsers.EmptyRef();
		AllUsersGroup = ExternalUsers.AllExternalUsersGroup();
	Else
		RefAllUsers = Catalogs.Users.EmptyRef();
		AllUsersGroup = Users.AllUsersGroup();
	EndIf;
	
	If Groups.Count() = 1 And Groups[0] = Undefined Then
		UpdateAllUsersGroupComposition(RefAllUsers, ChangesInComposition);
		
		If TypeOf(RefAllGroups) = Type("CatalogRef.ExternalUsersGroups") Then
			UpdateGroupCompositionsByAuthorizationObjectType(Undefined,
				Undefined, ChangesInComposition);
		EndIf;
		
		UpdateHierarchicalUserGroupCompositions(RefAllGroups, ChangesInComposition);
	Else
		IndexOf = Groups.Find(AllUsersGroup);
		If IndexOf <> Undefined Then
			Groups.Delete(IndexOf);
			UpdateAllUsersGroupComposition(RefAllUsers, ChangesInComposition);
		EndIf;
		If TypeOf(RefAllUsers) = Type("CatalogRef.ExternalUsersGroups") Then
			DescriptionOfGroups = Common.ObjectsAttributeValue(Groups, "AllAuthorizationObjects");
			AutoGroups = New Array;
			For Each GroupDetails In DescriptionOfGroups Do
				If GroupDetails.Value = True Then
					IndexOf = Groups.Find(GroupDetails.Key);
					If IndexOf <> Undefined Then
						Groups.Delete(IndexOf);
						AutoGroups.Add(GroupDetails.Key);
					EndIf;
				EndIf;
			EndDo;
			If ValueIsFilled(AutoGroups) Then
				UpdateGroupCompositionsByAuthorizationObjectType(AutoGroups,
					Undefined, ChangesInComposition);
			EndIf;
		EndIf;
		UpdateHierarchicalUserGroupCompositions(Groups, ChangesInComposition);
	EndIf;
	
	RegistrationCleanup.Add(RefsKindName);
	
EndProcedure

// 
Procedure ProcessRegisteredChangeInUsers(RefsKindName, RefAllUsers,
			ChangesInComposition, RegistrationCleanup)
	
	References = RegisteredRefs(RefsKindName);
	If References.Count() = 0 Then
		Return;
	EndIf;
	
	If References.Count() = 1 And References[0] = Undefined Then
		UpdateAllUsersGroupComposition(RefAllUsers, ChangesInComposition);
		
		If TypeOf(RefAllUsers) = Type("CatalogRef.ExternalUsers") Then
			UpdateGroupCompositionsByAuthorizationObjectType(Undefined, Undefined, ChangesInComposition);
		EndIf;
		
		UpdateUserGroupCompositionUsage(RefAllUsers, ChangesInComposition);
	Else
		UpdateAllUsersGroupComposition(References, ChangesInComposition);
		
		If TypeOf(RefAllUsers) = Type("CatalogRef.ExternalUsers") Then
			UpdateGroupCompositionsByAuthorizationObjectType(Undefined, References, ChangesInComposition);
		EndIf;
		
		UpdateUserGroupCompositionUsage(References, ChangesInComposition);
	EndIf;
	
	RegistrationCleanup.Add(RefsKindName);
	
EndProcedure

// 
Procedure ProcessRegisteredChangeInAuthorizationObjects(RefsKindName, RegistrationCleanup)
	
	AuthorizationObjects = RegisteredRefs(RefsKindName);
	If AuthorizationObjects.Count() = 0 Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		If AuthorizationObjects.Count() = 1 And AuthorizationObjects[0] = Undefined Then
			AuthorizationObjects = Undefined;
		EndIf;
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.AfterChangeExternalUserAuthorizationObject(AuthorizationObjects);
	EndIf;
	
	RegistrationCleanup.Add(RefsKindName);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
// 
//
Function PasswordChangeRequired(ErrorDescription = "", OnStart = False, RegisterInLog = True)
	
	IBUser = InfoBaseUsers.CurrentUser();
	If Not ValueIsFilled(IBUser.Name) Then
		Return False;
	EndIf;
	
	// 
	SetPrivilegedMode(True);
	CurrentUser = Users.AuthorizedUser();
	
	Query = New Query;
	Query.SetParameter("CurrentUser", CurrentUser);
	
	Query.Text =
	"SELECT TOP 1
	|	UsersInfo.User AS User,
	|	UsersInfo.LastActivityDate AS LastActivityDate,
	|	UsersInfo.LastUsedClient AS LastUsedClient,
	|	UsersInfo.DeletePasswordUsageStartDate AS DeletePasswordUsageStartDate,
	|	UsersInfo.AutomaticAuthorizationProhibitionDate AS AutomaticAuthorizationProhibitionDate,
	|	UsersInfo.UserMustChangePasswordOnAuthorization AS UserMustChangePasswordOnAuthorization
	|FROM
	|	InformationRegister.UsersInfo AS UsersInfo
	|WHERE
	|	UsersInfo.User = &CurrentUser";
	
	Upload0 = Query.Execute().Unload();
	
	CurrentSessionDateDayStart = BegOfDay(CurrentSessionDate());
	ClientUsed = Common.ClientUsed();
	
	If Upload0.Count() = 1 Then
		HasChanges = False;
		IsOnlyLastActivityDateNoLongerRelevant = True;
		UserInfo = Upload0[0];
		UpdateUserInfoRecords(UserInfo, CurrentSessionDateDayStart,
			ClientUsed, HasChanges, IsOnlyLastActivityDateNoLongerRelevant, True);
	Else
		HasChanges = True;
		IsOnlyLastActivityDateNoLongerRelevant = False;
	EndIf;
	
	If HasChanges Then
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.UsersInfo");
		LockItem.SetValue("User", CurrentUser);
		BeginTransaction();
		Try
			IsLockEnabled = True;
			Block.Lock();
			IsLockEnabled = False;
			RecordSet = InformationRegisters.UsersInfo.CreateRecordSet();
			RecordSet.Filter.User.Set(CurrentUser);
			RecordSet.Read();
			If RecordSet.Count() = 0 Then
				UserInfo = RecordSet.Add();
				UserInfo.User = CurrentUser;
			Else
				UserInfo = RecordSet[0];
			EndIf;
			
			Write = False;
			UpdateUserInfoRecords(UserInfo,
				CurrentSessionDateDayStart, ClientUsed, Write);
			
			If Write Then
				RecordSet.Write();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			ContinueStart = IsLockEnabled And IsOnlyLastActivityDateNoLongerRelevant;
			ErrorInfo = ErrorInfo();
			ErrorTextTemplate = CurrentUserInfoRecordErrorTextTemplate();
			If OnStart And Not ContinueStart Then
				ErrorDescription = AuthorizationNotCompletedMessageTextWithLineBreak()
					+ StringFunctionsClientServer.SubstituteParametersToString(ErrorTextTemplate,
						ErrorProcessing.BriefErrorDescription(ErrorInfo));
				
				If RegisterInLog Then
					WriteLogEvent(
						NStr("en = 'Users.Authorization error';",
						     Common.DefaultLanguageCode()),
						EventLogLevel.Error,
						Metadata.FindByType(TypeOf(CurrentUser)),
						CurrentUser,
						StringFunctionsClientServer.SubstituteParametersToString(ErrorTextTemplate,
							ErrorProcessing.DetailErrorDescription(ErrorInfo)));
				EndIf;
			Else
				If RegisterInLog Then
					WriteLogEvent(
						NStr("en = 'Users.Last activity date update error';",
						     Common.DefaultLanguageCode()),
						EventLogLevel.Error,
						Metadata.FindByType(TypeOf(CurrentUser)),
						CurrentUser,
						StringFunctionsClientServer.SubstituteParametersToString(ErrorTextTemplate,
							ErrorProcessing.DetailErrorDescription(ErrorInfo)));
				EndIf;
			EndIf;
			If Not OnStart Or Not ContinueStart Then
				Return False;
			EndIf;
		EndTry;
	EndIf;
	SetPrivilegedMode(False);
	
	If StandardSubsystemsServer.ThisIsSplitSessionModeWithNoDelimiters() Then
		Return False;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("IncludeCannotChangePasswordProperty");
	AdditionalParameters.Insert("IncludeStandardAuthenticationProperty");
	If Not CanChangePassword(CurrentUser, AdditionalParameters) Then
		Return False;
	EndIf;
	
	If UserInfo.UserMustChangePasswordOnAuthorization Then
		Return True;
	EndIf;
	
	If Not Common.DataSeparationEnabled()
	 Or Not Users.CommonAuthorizationSettingsUsed() Then
		Return False;
	EndIf;
	
	If TypeOf(CurrentUser) = Type("CatalogRef.ExternalUsers") Then
		LogonSettings = LogonSettings().ExternalUsers;
	Else
		LogonSettings = LogonSettings().Users;
	EndIf;
	
	If Not ValueIsFilled(LogonSettings.MaxPasswordLifetime) Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(UserInfo.DeletePasswordUsageStartDate) Then
		Return False;
	EndIf;
	
	RemainingMaxPasswordLifetime = LogonSettings.MaxPasswordLifetime
		- (CurrentSessionDateDayStart - UserInfo.DeletePasswordUsageStartDate) / (24*60*60);
	
	Return RemainingMaxPasswordLifetime <= 0;
	
EndFunction

// 
Procedure UpdateUserInfoRecords(UserInfo, CurrentSessionDateDayStart,
			ClientUsed, HasChanges, IsOnlyLastActivityDateNoLongerRelevant = True, ThisIsTest = False)
	
	If UserInfo.LastActivityDate <> CurrentSessionDateDayStart Then
		
		UserInfo.LastActivityDate = CurrentSessionDateDayStart;
		HasChanges = True;
		
		If Not ThisIsTest
		   And Common.DataSeparationEnabled()
		   And Common.SubsystemExists("CloudTechnology.ServiceUsers") Then
			
			ServiceUsersModule = Common.CommonModule("ServiceUsers");
			ServiceUsersModule.UpdateActivityOfServiceUser(
				UserInfo.User,
				CurrentSessionDateDayStart);
		EndIf;
	EndIf;
	
	If ClientUsed <> Undefined
	   And UserInfo.LastUsedClient <> ClientUsed Then
		
		UserInfo.LastUsedClient = ClientUsed;
		HasChanges = True;
		IsOnlyLastActivityDateNoLongerRelevant = False;
	EndIf;
	
	If Not Common.DataSeparationEnabled() Then
		If ValueIsFilled(UserInfo.DeletePasswordUsageStartDate) Then
			UserInfo.DeletePasswordUsageStartDate = Undefined;
			HasChanges = True;
		EndIf;
		
	ElsIf Not ValueIsFilled(UserInfo.DeletePasswordUsageStartDate)
	      Or UserInfo.DeletePasswordUsageStartDate > CurrentSessionDateDayStart Then
		
		UserInfo.DeletePasswordUsageStartDate = CurrentSessionDateDayStart;
		HasChanges = True;
		IsOnlyLastActivityDateNoLongerRelevant = False;
	EndIf;
	
	If ValueIsFilled(UserInfo.AutomaticAuthorizationProhibitionDate) Then
		UserInfo.AutomaticAuthorizationProhibitionDate = Undefined;
		HasChanges = True;
		IsOnlyLastActivityDateNoLongerRelevant = False;
	EndIf;
	
EndProcedure

Function ServerNotificationName()
	Return "StandardSubsystems.Users.UserRolesChangeOrLockOrValidityPeriod";
EndFunction

// 
Procedure UpdateLastUserActivityDate(Parameters, IBUsersIDs)
	
	IBUsersIDs = New Array;
	For Each CheckParameter1 In Parameters Do
		For Each Addressee In CheckParameter1.SMSMessageRecipients Do
			IBUsersIDs.Add(Addressee.Key);
		EndDo;
	EndDo;
	
	CurrentSessionDateDayStart = BegOfDay(CurrentSessionDate());
	
	Query = New Query;
	Query.SetParameter("CurrentSessionDateDayStart",    CurrentSessionDateDayStart);
	Query.SetParameter("IBUsersIDs", IBUsersIDs);
	Query.Text =
	"SELECT
	|	UsersInfo.User AS User
	|FROM
	|	InformationRegister.UsersInfo AS UsersInfo
	|WHERE
	|	UsersInfo.LastActivityDate < &CurrentSessionDateDayStart
	|	AND UsersInfo.User.IBUserID IN(&IBUsersIDs)";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		CurrentUser = Selection.User;
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.UsersInfo");
		LockItem.SetValue("User", CurrentUser);
		BeginTransaction();
		Try
			Block.Lock();
			RecordSet = InformationRegisters.UsersInfo.CreateRecordSet();
			RecordSet.Filter.User.Set(CurrentUser);
			RecordSet.Read();
			If RecordSet.Count() = 1 Then
				UserInfo = RecordSet[0];
				If UserInfo.LastActivityDate < CurrentSessionDateDayStart Then
					UserInfo.LastActivityDate = CurrentSessionDateDayStart;
					
					If Common.DataSeparationEnabled()
						And Common.SubsystemExists("CloudTechnology.ServiceUsers") Then
						
						ServiceUsersModule = Common.CommonModule("ServiceUsers");
						ServiceUsersModule.UpdateActivityOfServiceUser(
							CurrentUser,
							CurrentSessionDateDayStart);
					EndIf;
					
					RecordSet.Write();
				EndIf;
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			ErrorInfo = ErrorInfo();
			ErrorTextTemplate = CurrentUserInfoRecordErrorTextTemplate();
			WriteLogEvent(
				NStr("en = 'Users.Last activity date update error';",
				     Common.DefaultLanguageCode()),
				EventLogLevel.Error,
				Metadata.FindByType(TypeOf(CurrentUser)),
				CurrentUser,
				StringFunctionsClientServer.SubstituteParametersToString(ErrorTextTemplate,
					ErrorProcessing.DetailErrorDescription(ErrorInfo)));
		EndTry;
	EndDo;
	
EndProcedure

// 
Function UsersRemainingValidityPeriods(IBUsersIDs, BegOfDay)
	
	Result = New Map;
	
	DaysCount = LogonSettings().Overall.NotificationLeadTimeBeforeAccessExpire;
	If Not ValueIsFilled(DaysCount) Then
		Return Result;
	EndIf;
	
	Days1 = 24*60*60;
	
	Query = New Query;
	Query.SetParameter("DateEmpty", '00010101');
	Query.SetParameter("CurrentSessionDateDayStart", BegOfDay);
	Query.SetParameter("WarningDayStart", BegOfDay + DaysCount * Days1);
	Query.SetParameter("IBUsersIDs", IBUsersIDs);
	
	Query.Text =
	"SELECT
	|	Users.IBUserID AS IBUserID,
	|	UsersInfo.ValidityPeriod AS ValidityPeriod
	|FROM
	|	Catalog.Users AS Users
	|		INNER JOIN InformationRegister.UsersInfo AS UsersInfo
	|		ON (UsersInfo.User = Users.Ref)
	|WHERE
	|	Users.IBUserID IN(&IBUsersIDs)
	|	AND UsersInfo.UnlimitedValidityPeriod = FALSE
	|	AND UsersInfo.ValidityPeriod > &CurrentSessionDateDayStart
	|	AND UsersInfo.ValidityPeriod <= &WarningDayStart
	|
	|UNION ALL
	|
	|SELECT
	|	ExternalUsers.IBUserID,
	|	UsersInfo.ValidityPeriod
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|		INNER JOIN InformationRegister.UsersInfo AS UsersInfo
	|		ON (UsersInfo.User = ExternalUsers.Ref)
	|WHERE
	|	ExternalUsers.IBUserID IN(&IBUsersIDs)
	|	AND UsersInfo.UnlimitedValidityPeriod = FALSE
	|	AND UsersInfo.ValidityPeriod > &CurrentSessionDateDayStart
	|	AND UsersInfo.ValidityPeriod <= &WarningDayStart";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Result.Insert(Selection.IBUserID, (Selection.ValidityPeriod - BegOfDay) / Days1);
	EndDo;
	
	Return Result;
	
EndFunction

// 
Function IsNotificationRequired(IBUserName, RemainingValidityPeriod, BegOfDay)
	
	LastReminder = New Structure("DaysLeft, Date", 0, '00010101');
	
	LoadedValue = Common.SystemSettingsStorageLoad(
		"LastNotificationAboutExpiration",,,, IBUserName);
	
	If TypeOf(LoadedValue) = Type("Structure") Then
		For Each KeyAndValue In LastReminder Do
			If LoadedValue.Property(KeyAndValue.Key)
			   And TypeOf(LoadedValue[KeyAndValue.Key]) = TypeOf(KeyAndValue.Value) Then
				
				LastReminder[KeyAndValue.Key] = LoadedValue[KeyAndValue.Key];
			EndIf;
		EndDo;
	EndIf;
	
	If LastReminder.DaysLeft = RemainingValidityPeriod
	   And LastReminder.Date = BegOfDay Then
		Return False;
	EndIf;
	
	LastReminder.DaysLeft = RemainingValidityPeriod;
	LastReminder.Date = BegOfDay;
	
	Common.SystemSettingsStorageSave(
		"LastNotificationAboutExpiration",, LastReminder,, IBUserName);
	
	Return True;
	
EndFunction

// 
// 
//
// Parameters:
//  Password - String
//  IBUser - InfoBaseUser
//
// Returns:
//  String
//
Function PasswordComplianceError(Password, IBUser) Export
	
	PasswordPolicy = UserPasswordPolicies.FindByName(IBUser.PasswordPolicyName);
	
	Errors = UserPasswordPolicies.CheckPasswordComplianceWithPolicy(Password,
		PasswordPolicy, IBUser);
	
	If Errors.Find(PasswordPolicyComplianceCheckResult.DoesNotSatisfyMinLengthRequirements) <> Undefined Then
		If PasswordPolicy = Undefined Then
			MinPasswordLength = GetUserPasswordMinLength();
		Else
			MinPasswordLength = PasswordPolicy.PasswordMinLength;
		EndIf;
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The new password must contain at least %1 characters.';"),
			Format(MinPasswordLength, "NG="));
	EndIf;
	
	If Errors.Find(PasswordPolicyComplianceCheckResult.DoesNotSatisfyComplexityRequirements) <> Undefined Then
		Return NStr("en = 'The password does not meet the password complexity requirements.';")
			+ Chars.LF + Chars.LF
			+ NewPasswordHint();
	EndIf;
	
	If Errors.Find(PasswordPolicyComplianceCheckResult.DoesNotSatisfyReuseLimitRequirements) <> Undefined Then
		Return NStr("en = 'The new password has been used before.';");
	EndIf;
	
	Return "";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Procedure RememberUserProperties(UserObject, ProcessingParameters)
	
	Fields =
	"Ref,
	|IBUserID,
	|ServiceUserID,
	|DeleteInfobaseUserProperties,
	|Prepared,
	|DeletionMark,
	|Invalid";
	
	If TypeOf(UserObject) = Type("CatalogObject.Users") Then
		Fields = Fields + ",
		|IsInternal";
	EndIf;
	
	OldUser = Common.ObjectAttributesValues(UserObject.Ref, Fields);
	
	If TypeOf(UserObject) <> Type("CatalogObject.Users") Then
		OldUser.Insert("IsInternal", False);
	EndIf;
	
	If UserObject.IsNew() Or UserObject.Ref <> OldUser.Ref Then
		OldUser.IBUserID = CommonClientServer.BlankUUID();
		OldUser.ServiceUserID = CommonClientServer.BlankUUID();
		OldUser.DeleteInfobaseUserProperties    = New ValueStorage(Undefined);
		OldUser.Prepared               = False;
		OldUser.DeletionMark           = False;
		OldUser.Invalid            = False;
	EndIf;
	ProcessingParameters.Insert("OldUser", OldUser);
	
	// 
	SetPrivilegedMode(True);
	
	PreviousIBUserDetails = Users.IBUserProperies(OldUser.IBUserID);
	ProcessingParameters.Insert("OldIBUserExists", PreviousIBUserDetails <> Undefined);
	ProcessingParameters.Insert("OldIBUserCurrent", False);
	ProcessingParameters.Insert("InfobaseOldUser",
		InfobaseUserByID(OldUser.IBUserID));
	
	If ProcessingParameters.OldIBUserExists Then
		ProcessingParameters.Insert("PreviousIBUserDetails", PreviousIBUserDetails);
		
		If PreviousIBUserDetails.UUID =
				InfoBaseUsers.CurrentUser().UUID Then
		
			ProcessingParameters.Insert("OldIBUserCurrent", True);
		EndIf;
	EndIf;
	SetPrivilegedMode(False);
	
	// 
	FillPropertyValues(ProcessingParameters.AutoAttributes, OldUser);
	
	// 
	FillPropertyValues(ProcessingParameters.AttributesToLock, UserObject);
	
EndProcedure

Procedure WriteIBUser(UserObject, ProcessingParameters)
	
	AdditionalProperties = UserObject.AdditionalProperties;
	IBUserDetails = AdditionalProperties.IBUserDetails;
	OldUser     = ProcessingParameters.OldUser;
	
	If IBUserDetails.Count() = 0 Then
		Return;
	EndIf;
	
	If IBUserDetails.Property("UserMustChangePasswordOnAuthorization") Then
		WritePropertyUserMustChangePasswordOnAuthorization(ObjectRef2(UserObject),
			IBUserDetails.UserMustChangePasswordOnAuthorization);
		
		If IBUserDetails.Count() = 2 Then
			Return;
		EndIf;
	EndIf;
	
	CreateNewIBUser = False;
	
	If IBUserDetails.Property("UUID")
	   And ValueIsFilled(IBUserDetails.UUID)
	   And IBUserDetails.UUID
	     <> ProcessingParameters.OldUser.IBUserID Then
		
		IBUserID = IBUserDetails.UUID;
		
	ElsIf ValueIsFilled(OldUser.IBUserID) Then
		IBUserID = OldUser.IBUserID;
		CreateNewIBUser = Not ProcessingParameters.OldIBUserExists;
	Else
		IBUserID = CommonClientServer.BlankUUID();
		CreateNewIBUser = True;
	EndIf;
	
	// 
	IBUserDetails.Insert("FullName", UserObject.Description);
	
	StoredProperties = StoredIBUserProperties(ObjectRef2(UserObject));
	If ProcessingParameters.OldIBUserExists Then
		PreviousAuthentication = ProcessingParameters.PreviousIBUserDetails;
		If Users.CanSignIn(PreviousAuthentication) Then
			StoredProperties.StandardAuthentication    = PreviousAuthentication.StandardAuthentication;
			StoredProperties.OpenIDAuthentication         = PreviousAuthentication.OpenIDAuthentication;
			StoredProperties.OpenIDConnectAuthentication  = PreviousAuthentication.OpenIDConnectAuthentication;
			StoredProperties.AccessTokenAuthentication = PreviousAuthentication.AccessTokenAuthentication;
			StoredProperties.OSAuthentication             = PreviousAuthentication.OSAuthentication;
			SetStoredPropertiesOfInfobaseUser(UserObject, StoredProperties);
		EndIf;
	Else
		PreviousAuthentication = New Structure;
		PreviousAuthentication.Insert("StandardAuthentication",    False);
		PreviousAuthentication.Insert("OpenIDAuthentication",         False);
		PreviousAuthentication.Insert("OpenIDConnectAuthentication",  False);
		PreviousAuthentication.Insert("AccessTokenAuthentication", False);
		PreviousAuthentication.Insert("OSAuthentication",             False);
		StoredProperties.StandardAuthentication    = False;
		StoredProperties.OpenIDAuthentication         = False;
		StoredProperties.OpenIDConnectAuthentication  = False;
		StoredProperties.AccessTokenAuthentication = False;
		StoredProperties.OSAuthentication             = False;
		SetStoredPropertiesOfInfobaseUser(UserObject, StoredProperties);
	EndIf;
	
	If IBUserDetails.Property("StandardAuthentication") Then
		StoredProperties.StandardAuthentication = IBUserDetails.StandardAuthentication;
		SetStoredPropertiesOfInfobaseUser(UserObject, StoredProperties);
	EndIf;
	
	If IBUserDetails.Property("OpenIDAuthentication") Then
		StoredProperties.OpenIDAuthentication = IBUserDetails.OpenIDAuthentication;
		SetStoredPropertiesOfInfobaseUser(UserObject, StoredProperties);
	EndIf;
	
	If IBUserDetails.Property("OpenIDConnectAuthentication") Then
		StoredProperties.OpenIDConnectAuthentication = IBUserDetails.OpenIDConnectAuthentication;
		SetStoredPropertiesOfInfobaseUser(UserObject, StoredProperties);
	EndIf;
	
	If IBUserDetails.Property("AccessTokenAuthentication") Then
		StoredProperties.AccessTokenAuthentication = IBUserDetails.AccessTokenAuthentication;
		SetStoredPropertiesOfInfobaseUser(UserObject, StoredProperties);
	EndIf;
	
	If IBUserDetails.Property("OSAuthentication") Then
		StoredProperties.OSAuthentication = IBUserDetails.OSAuthentication;
		SetStoredPropertiesOfInfobaseUser(UserObject, StoredProperties);
	EndIf;
	
	If CreateNewIBUser
	   And IBUserDetails.Property("UpdateInfobaseUserOnly") Then
		
		If StoredProperties.CanSignIn <> False Then
			StoredProperties.CanSignIn = False;
			SetStoredPropertiesOfInfobaseUser(UserObject, StoredProperties);
		EndIf;
		
		IBUserDetails.Insert("ActionResult", "InfobaseUserSkipped");
		IBUserDetails.Insert("UUID",
			UserObject.IBUserID);
		
		Return;
		
	EndIf;
	
	SetStoredAuthentication = Undefined;
	If IBUserDetails.Property("CanSignIn") Then
		SetStoredAuthentication = IBUserDetails.CanSignIn = True
			Or IBUserDetails.CanSignIn <> False
			  And Users.CanSignIn(PreviousAuthentication);
	
	ElsIf IBUserDetails.Property("StandardAuthentication")
	        And IBUserDetails.StandardAuthentication = True
	      Or IBUserDetails.Property("OpenIDAuthentication")
	        And IBUserDetails.OpenIDAuthentication = True
	      Or IBUserDetails.Property("OpenIDConnectAuthentication")
	        And IBUserDetails.OpenIDConnectAuthentication = True
	      Or IBUserDetails.Property("AccessTokenAuthentication")
	        And IBUserDetails.AccessTokenAuthentication = True
	      Or IBUserDetails.Property("OSAuthentication")
	        And IBUserDetails.OSAuthentication = True Then
		
		SetStoredAuthentication = True;
	EndIf;
	
	If SetStoredAuthentication = Undefined Then
		NewAuthentication = PreviousAuthentication;
	Else
		If SetStoredAuthentication Then
			IBUserDetails.Insert("StandardAuthentication",    StoredProperties.StandardAuthentication);
			IBUserDetails.Insert("OpenIDAuthentication",         StoredProperties.OpenIDAuthentication);
			IBUserDetails.Insert("OpenIDConnectAuthentication",  StoredProperties.OpenIDConnectAuthentication);
			IBUserDetails.Insert("AccessTokenAuthentication", StoredProperties.AccessTokenAuthentication);
			IBUserDetails.Insert("OSAuthentication",             StoredProperties.OSAuthentication);
		Else
			IBUserDetails.Insert("StandardAuthentication",    False);
			IBUserDetails.Insert("OpenIDAuthentication",         False);
			IBUserDetails.Insert("OpenIDConnectAuthentication",  False);
			IBUserDetails.Insert("AccessTokenAuthentication", False);
			IBUserDetails.Insert("OSAuthentication",             False);
		EndIf;
		NewAuthentication = IBUserDetails;
	EndIf;
	
	If StoredProperties.CanSignIn <> Users.CanSignIn(NewAuthentication) Then
		StoredProperties.CanSignIn = Users.CanSignIn(NewAuthentication);
		SetStoredPropertiesOfInfobaseUser(UserObject, StoredProperties);
	EndIf;
	
	// 
	If Users.CanSignIn(NewAuthentication)
	  <> Users.CanSignIn(PreviousAuthentication) Then
	
		If Users.CanSignIn(NewAuthentication)
		   And Not ProcessingParameters.AccessLevel.ChangeAuthorizationPermission
		 Or Not Users.CanSignIn(NewAuthentication)
		   And Not ProcessingParameters.AccessLevel.DisableAuthorizationApproval Then
			
			Raise ProcessingParameters.InsufficientRightsMessageText;
		EndIf;
	EndIf;
	
	IsPasswordSet = IBUserDetails.Property("Password")
		And IBUserDetails.Password <> Undefined;
	
	PasswordHashSpecified = IBUserDetails.Property("StoredPasswordValue")
		And IBUserDetails.StoredPasswordValue <> Undefined;
	
	CheckBlankPassword =
		Not PreviousAuthentication.StandardAuthentication
		And StoredProperties.StandardAuthentication
		And (    CreateNewIBUser
		     And Not IsPasswordSet
		   Or ProcessingParameters.OldIBUserExists
		     And Not ProcessingParameters.PreviousIBUserDetails.PasswordIsSet);
	
	If IsPasswordSet Or Not PasswordHashSpecified And CheckBlankPassword Then
		LoginName = ?(IBUserDetails.Property("Name"),
			IBUserDetails.Name, ?(ProcessingParameters.OldIBUserExists,
				ProcessingParameters.PreviousIBUserDetails.Name, ""));
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("User", UserObject);
		ExecutionParameters.Insert("LoginName",  LoginName);
		ExecutionParameters.Insert("NewPassword", ?(IsPasswordSet, IBUserDetails.Password, ""));
		ExecutionParameters.Insert("PreviousPassword", Undefined);
		
		IBUserDetails.Property("PreviousPassword", ExecutionParameters.PreviousPassword);
		
		ErrorText = ProcessNewPassword(ExecutionParameters);
		If ValueIsFilled(ErrorText) Then
			Raise ErrorText;
		EndIf;
	EndIf;
	
	// 
	ParametersOfUpdate = New Map(SessionParameters.UsersCatalogsUpdate);
	ParametersOfUpdate.Insert("IBUserID", IBUserID);
	SessionParameters.UsersCatalogsUpdate = New FixedMap(ParametersOfUpdate);
	ParametersOfUpdate.Delete("IBUserID");
	Try
		Users.SetIBUserProperies(IBUserID, IBUserDetails, 
			CreateNewIBUser, TypeOf(UserObject) = Type("CatalogObject.ExternalUsers"));
		IBUser = IBUserDetails.IBUser;
	Except
		SessionParameters.UsersCatalogsUpdate = New FixedMap(ParametersOfUpdate);
		Raise;
	EndTry;
	SessionParameters.UsersCatalogsUpdate = New FixedMap(ParametersOfUpdate);
	
	If UserObject.AdditionalProperties.Property("CreateAdministrator")
	   And ValueIsFilled(UserObject.AdditionalProperties.CreateAdministrator)
	   And Not UserObject.DataExchange.Load
	   And AdministratorRolesAvailable(IBUser) Then
		
		ProcessingParameters.Insert("CreateAdministrator",
			UserObject.AdditionalProperties.CreateAdministrator);
	EndIf;
	
	If CreateNewIBUser Then
		IBUserDetails.Insert("ActionResult", "IBUserAdded");
		IBUserID = IBUserDetails.UUID;
		ProcessingParameters.Insert("IBUserSetting");
		
		If Not ProcessingParameters.AccessLevel.ChangeAuthorizationPermission
		   And ProcessingParameters.AccessLevel.ListManagement
		   And Not Users.CanSignIn(IBUser) Then
			
			UserObject.Prepared = True;
			ProcessingParameters.AttributesToLock.Prepared = True;
		EndIf;
	Else
		IBUserDetails.Insert("ActionResult", "IBUserChanged");
		
		If Users.CanSignIn(IBUser) Then
			UserObject.Prepared = False;
			ProcessingParameters.AttributesToLock.Prepared = False;
		EndIf;
	EndIf;
	
	UserObject.IBUserID = IBUserID;
	
	IBUserDetails.Insert("UUID", IBUserID);
	
EndProcedure

Procedure DeleteIBUser(UserObject, ProcessingParameters)
	
	IBUserDetails = UserObject.AdditionalProperties.IBUserDetails;
	OldUser     = ProcessingParameters.OldUser;
	
	// 
	UserObject.IBUserID = Undefined;
	
	If ProcessingParameters.OldIBUserExists Then
		
		SetPrivilegedMode(True);
		Users.DeleteIBUser(OldUser.IBUserID);
			
		// 
		IBUserDetails.Insert("UUID", OldUser.IBUserID);
		IBUserDetails.Insert("ActionResult", "IBUserDeleted");
		
	ElsIf ValueIsFilled(OldUser.IBUserID) Then
		IBUserDetails.Insert("ActionResult", "MappingToNonExistingIBUserCleared");
	Else
		IBUserDetails.Insert("ActionResult", "IBUserDeletionNotRequired");
	EndIf;
	
EndProcedure

Procedure WritePropertyUserMustChangePasswordOnAuthorization(User, Value)
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.UsersInfo");
	LockItem.SetValue("User", User);
	BeginTransaction();
	Try
		Block.Lock();
		RecordSet = InformationRegisters.UsersInfo.CreateRecordSet();
		RecordSet.Filter.User.Set(User);
		RecordSet.Read();
		If RecordSet.Count() = 0 Then
			UserInfo = RecordSet.Add();
			UserInfo.User = User;
		Else
			UserInfo = RecordSet[0];
		EndIf;
		UserInfo.UserMustChangePasswordOnAuthorization = Value;
		RecordSet.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

Procedure CheckUserAttributeChanges(UserObject, ProcessingParameters)
	
	OldUser   = ProcessingParameters.OldUser;
	AutoAttributes        = ProcessingParameters.AutoAttributes;
	AttributesToLock = ProcessingParameters.AttributesToLock;
	
	If TypeOf(UserObject) = Type("CatalogObject.Users")
	   And AttributesToLock.IsInternal <> UserObject.IsInternal Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t save user ""%1"".
			           |Cannot modify attribute ""IsInternal"" in event subscriptions.';"),
			UserObject.Ref);
		Raise ErrorText;
	EndIf;
	
	If AttributesToLock.Prepared <> UserObject.Prepared Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t save user ""%1"".
			           |Cannot modify attribute ""Prepared"" in event subscriptions.';"),
			UserObject.Ref);
		Raise ErrorText;
	EndIf;
	
	If AutoAttributes.IBUserID <> UserObject.IBUserID Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t save user ""%1"".
			           |Cannot modify attribute ""%2"" in event subscriptions.
			           |The attribute updates automatically.';"),
			UserObject.Ref,
			"IBUserID");
		Raise ErrorText;
	EndIf;
	
	If Not Common.DataMatch(AutoAttributes.DeleteInfobaseUserProperties,
				UserObject.DeleteInfobaseUserProperties) Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t save user ""%1"".
			           |Cannot modify attribute ""%2"" in event subscriptions.
			           |The attribute updates automatically.';"),
			UserObject.Ref,
			"DeleteInfobaseUserProperties");
		Raise ErrorText;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If OldUser.DeletionMark = False
	   And UserObject.DeletionMark = True
	   And Users.CanSignIn(UserObject.IBUserID) Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t save user ""%1"".
			           |Cannot mark for deletion users who are allowed to log in.';"),
			UserObject.Ref);
		Raise ErrorText;
	EndIf;
	
	If OldUser.Invalid = False
	   And UserObject.Invalid = True
	   And Users.CanSignIn(UserObject.IBUserID) Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t save user ""%1"".
			           |Cannot mark users who are allowed to log in as ""Inactive"".';"),
			UserObject.Ref);
		Raise ErrorText;
	EndIf;
	
	If OldUser.Prepared = False
	   And UserObject.Prepared = True
	   And Users.CanSignIn(UserObject.IBUserID) Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t save user ""%1"".
			           |Cannot mark users who are allowed to log in as ""Requires approval"".';"),
			UserObject.Ref);
		Raise ErrorText;
	EndIf;
	
EndProcedure

Procedure UpdateInfoOnUserAllowedToSignIn(User, EnableSignIn)
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.UsersInfo");
	LockItem.SetValue("User", User);
	
	RecordSet = InformationRegisters.UsersInfo.CreateRecordSet();
	RecordSet.Filter.User.Set(User);
	
	BeginTransaction();
	Try
		Block.Lock();
		RecordSet.Read();
		If RecordSet.Count() = 0 Then
			RecordSet.Add();
			RecordSet[0].User = User;
		EndIf;
		Write = False;
		If ValueIsFilled(RecordSet[0].AutomaticAuthorizationProhibitionDate) Then
			Write = True;
			RecordSet[0].AutomaticAuthorizationProhibitionDate = Undefined;
		EndIf;
		If EnableSignIn
		   And RecordSet[0].AuthorizationAllowedDate <> BegOfDay(CurrentSessionDate()) Then
			Write = True;
			RecordSet[0].AuthorizationAllowedDate = BegOfDay(CurrentSessionDate());
		EndIf;
		If Write Then
			RecordSet.Write();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure DisableInactiveAndOverdueUsers(ForAuthorizedUsersOnly = False,
			ErrorDescription = "", RegisterInLog = True)
	
	If Common.DataSeparationEnabled()
	 Or Not Users.CommonAuthorizationSettingsUsed() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Settings = LogonSettings();
	
	Query = New Query;
	Query.SetParameter("DateEmpty",                                 '00010101');
	Query.SetParameter("CurrentSessionDateDayStart",                 BegOfDay(CurrentSessionDate()));
	Query.SetParameter("UserOverdueActivationDate",        Settings.Users.InactivityPeriodActivationDate);
	Query.SetParameter("UserInactivityPeriod",               Settings.Users.InactivityPeriodBeforeDenyingAuthorization);
	Query.SetParameter("ExternalUserOverdueActivationDate", Settings.ExternalUsers.InactivityPeriodActivationDate);
	Query.SetParameter("ExternalUserInactivityPeriod",        Settings.ExternalUsers.InactivityPeriodBeforeDenyingAuthorization);
	
	Query.Text =
	"SELECT
	|	Users.Ref AS User,
	|	CASE
	|		WHEN ISNULL(UsersInfo.ValidityPeriod, &DateEmpty) <> &DateEmpty
	|			THEN ISNULL(UsersInfo.ValidityPeriod, &DateEmpty) <= &CurrentSessionDateDayStart
	|		ELSE FALSE
	|	END AS ValidityPeriodExpired
	|FROM
	|	Catalog.Users AS Users
	|		LEFT JOIN InformationRegister.UsersInfo AS UsersInfo
	|		ON (UsersInfo.User = Users.Ref)
	|WHERE
	|	&FilterUsers
	|	AND ISNULL(UsersInfo.UnlimitedValidityPeriod, FALSE) = FALSE
	|	AND ISNULL(UsersInfo.AutomaticAuthorizationProhibitionDate, &DateEmpty) = &DateEmpty
	|	AND CASE
	|			WHEN ISNULL(UsersInfo.ValidityPeriod, &DateEmpty) <> &DateEmpty
	|				THEN ISNULL(UsersInfo.ValidityPeriod, &DateEmpty) <= &CurrentSessionDateDayStart
	|			WHEN ISNULL(UsersInfo.InactivityPeriodBeforeDenyingAuthorization, 0) <> 0
	|				THEN CASE
	|						WHEN ISNULL(UsersInfo.LastActivityDate, &DateEmpty) <= ISNULL(UsersInfo.AuthorizationAllowedDate, &DateEmpty)
	|							THEN CASE
	|									WHEN ISNULL(UsersInfo.AuthorizationAllowedDate, &DateEmpty) = &DateEmpty
	|										THEN &CurrentSessionDateDayStart > DATEADD(&UserOverdueActivationDate, DAY, UsersInfo.InactivityPeriodBeforeDenyingAuthorization)
	|									ELSE &CurrentSessionDateDayStart > DATEADD(UsersInfo.AuthorizationAllowedDate, DAY, UsersInfo.InactivityPeriodBeforeDenyingAuthorization)
	|								END
	|						WHEN &CurrentSessionDateDayStart > DATEADD(ISNULL(UsersInfo.LastActivityDate, &DateEmpty), DAY, UsersInfo.InactivityPeriodBeforeDenyingAuthorization)
	|							THEN TRUE
	|						ELSE FALSE
	|					END
	|			ELSE CASE
	|					WHEN &UserInactivityPeriod = 0
	|						THEN FALSE
	|					WHEN ISNULL(UsersInfo.LastActivityDate, &DateEmpty) <= ISNULL(UsersInfo.AuthorizationAllowedDate, &DateEmpty)
	|						THEN CASE
	|								WHEN ISNULL(UsersInfo.AuthorizationAllowedDate, &DateEmpty) = &DateEmpty
	|									THEN &CurrentSessionDateDayStart > DATEADD(&UserOverdueActivationDate, DAY, &UserInactivityPeriod)
	|								ELSE &CurrentSessionDateDayStart > DATEADD(UsersInfo.AuthorizationAllowedDate, DAY, &UserInactivityPeriod)
	|							END
	|					WHEN &CurrentSessionDateDayStart > DATEADD(ISNULL(UsersInfo.LastActivityDate, &DateEmpty), DAY, &UserInactivityPeriod)
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	ExternalUsers.Ref,
	|	CASE
	|		WHEN ISNULL(UsersInfo.ValidityPeriod, &DateEmpty) <> &DateEmpty
	|			THEN ISNULL(UsersInfo.ValidityPeriod, &DateEmpty) <= &CurrentSessionDateDayStart
	|		ELSE FALSE
	|	END
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|		LEFT JOIN InformationRegister.UsersInfo AS UsersInfo
	|		ON (UsersInfo.User = ExternalUsers.Ref)
	|WHERE
	|	&FilterExternalUsers
	|	AND ISNULL(UsersInfo.UnlimitedValidityPeriod, FALSE) = FALSE
	|	AND ISNULL(UsersInfo.AutomaticAuthorizationProhibitionDate, &DateEmpty) = &DateEmpty
	|	AND CASE
	|			WHEN ISNULL(UsersInfo.ValidityPeriod, &DateEmpty) <> &DateEmpty
	|				THEN ISNULL(UsersInfo.ValidityPeriod, &DateEmpty) <= &CurrentSessionDateDayStart
	|			WHEN ISNULL(UsersInfo.InactivityPeriodBeforeDenyingAuthorization, 0) <> 0
	|				THEN CASE
	|						WHEN ISNULL(UsersInfo.LastActivityDate, &DateEmpty) <= ISNULL(UsersInfo.AuthorizationAllowedDate, &DateEmpty)
	|							THEN CASE
	|									WHEN ISNULL(UsersInfo.AuthorizationAllowedDate, &DateEmpty) = &DateEmpty
	|										THEN &CurrentSessionDateDayStart > DATEADD(&ExternalUserOverdueActivationDate, DAY, UsersInfo.InactivityPeriodBeforeDenyingAuthorization)
	|									ELSE &CurrentSessionDateDayStart > DATEADD(UsersInfo.AuthorizationAllowedDate, DAY, UsersInfo.InactivityPeriodBeforeDenyingAuthorization)
	|								END
	|						WHEN &CurrentSessionDateDayStart > DATEADD(ISNULL(UsersInfo.LastActivityDate, &DateEmpty), DAY, UsersInfo.InactivityPeriodBeforeDenyingAuthorization)
	|							THEN TRUE
	|						ELSE FALSE
	|					END
	|			ELSE CASE
	|					WHEN &ExternalUserInactivityPeriod = 0
	|						THEN FALSE
	|					WHEN ISNULL(UsersInfo.LastActivityDate, &DateEmpty) <= ISNULL(UsersInfo.AuthorizationAllowedDate, &DateEmpty)
	|						THEN CASE
	|								WHEN ISNULL(UsersInfo.AuthorizationAllowedDate, &DateEmpty) = &DateEmpty
	|									THEN &CurrentSessionDateDayStart > DATEADD(&ExternalUserOverdueActivationDate, DAY, &ExternalUserInactivityPeriod)
	|								ELSE &CurrentSessionDateDayStart > DATEADD(UsersInfo.AuthorizationAllowedDate, DAY, &ExternalUserInactivityPeriod)
	|							END
	|					WHEN &CurrentSessionDateDayStart > DATEADD(ISNULL(UsersInfo.LastActivityDate, &DateEmpty), DAY, &ExternalUserInactivityPeriod)
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		END";
	If ForAuthorizedUsersOnly Then
		Query.SetParameter("User", Users.AuthorizedUser());
		FilterUsers        = "Users.Ref = &User";
		FilterExternalUsers = "ExternalUsers.Ref = &User";
	Else
		FilterUsers        = "TRUE";
		FilterExternalUsers = "TRUE";
	EndIf;
	Query.Text = StrReplace(Query.Text, "&FilterUsers",        FilterUsers);
	Query.Text = StrReplace(Query.Text, "&FilterExternalUsers", FilterExternalUsers);
	
	Selection = Query.Execute().Select();
	
	ErrorInfo = Undefined;
	While Selection.Next() Do
		User = Selection.User;
		If Not Selection.ValidityPeriodExpired
		   And Users.IsFullUser(User,, False) Then
			Continue;
		EndIf;
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.UsersInfo");
		LockItem.SetValue("User", User);
		BeginTransaction();
		Try
			Block.Lock();
			IBUserID = Common.ObjectAttributeValue(User,
				"IBUserID");
			IBUser = Undefined;
			If TypeOf(IBUserID) = Type("UUID") Then
				IBUser = InfoBaseUsers.FindByUUID(
					IBUserID);
			EndIf;
			If IBUser <> Undefined
			   And (    IBUser.StandardAuthentication
			      Or IBUser.OpenIDAuthentication
			      Or IBUser.OpenIDConnectAuthentication
			      Or IBUser.AccessTokenAuthentication
			      Or IBUser.OSAuthentication) Then
				
				PropertiesToUpdate = New Structure;
				PropertiesToUpdate.Insert("StandardAuthentication",    False);
				PropertiesToUpdate.Insert("OpenIDAuthentication",         False);
				PropertiesToUpdate.Insert("OpenIDConnectAuthentication",  False);
				PropertiesToUpdate.Insert("AccessTokenAuthentication", False);
				PropertiesToUpdate.Insert("OSAuthentication",             False);
				
				Users.SetIBUserProperies(IBUser.UUID,
					PropertiesToUpdate, False, TypeOf(User) = Type("CatalogRef.ExternalUsers"));
			EndIf;
			RecordSet = InformationRegisters.UsersInfo.CreateRecordSet();
			RecordSet.Filter.User.Set(User);
			RecordSet.Read();
			If RecordSet.Count() = 0 Then
				UserInfo = RecordSet.Add();
				UserInfo.User = User;
			Else
				UserInfo = RecordSet[0];
			EndIf;
			UserInfo.AutomaticAuthorizationProhibitionDate = BegOfDay(CurrentSessionDate());
			RecordSet.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			ErrorInfo = ErrorInfo();
			
			ErrorTextTemplate = CurrentUserInfoRecordErrorTextTemplate();
			ErrorDescription = AuthorizationNotCompletedMessageTextWithLineBreak()
				+ StringFunctionsClientServer.SubstituteParametersToString(ErrorTextTemplate,
					ErrorProcessing.BriefErrorDescription(ErrorInfo));
			
			If RegisterInLog Then
				If Selection.ValidityPeriodExpired Then
					CommentTemplate =
						NStr("en = 'Cannot clear the ""Login allowed"" flag
						           |for user ""%1"" with expired access. Reason:
						           |%2';");
				Else
					CommentTemplate =
						NStr("en = 'Cannot clear the ""Login allowed"" flag
						           |for user ""%1"" with inactivity timeout reached.
						           |Reason:
						           |%2';");
				EndIf;
				WriteLogEvent(
					NStr("en = 'Users.Automatic authorization denial error';",
					     Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					Metadata.FindByType(TypeOf(User)),
					User,
					StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate,
						User, ErrorProcessing.DetailErrorDescription(ErrorInfo)));
			EndIf;
		EndTry;
	EndDo;
	
EndProcedure

Procedure CheckCanSignIn(AuthorizationError)
	
	SetPrivilegedMode(True);
	
	Id = InfoBaseUsers.CurrentUser().UUID;
	IBUser = InfoBaseUsers.FindByUUID(Id);
	AuthorizedUser = Users.AuthorizedUser();
	Invalid = Common.ObjectAttributeValue(AuthorizedUser, "Invalid");
	
	If IBUser = Undefined
	 Or Not ValueIsFilled(IBUser.Name)
	 Or Users.CanSignIn(IBUser)
	   And (AdministratorRolesAvailable(IBUser)
	      Or Invalid <> True) Then
			Return;
	EndIf;
	
	AuthorizationError = AuthorizationNotCompletedMessageTextWithLineBreak()
		+ NStr("en = 'Your account is disabled. Please contact the administrator.';");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Fills a collection of roles.
//
// Parameters:
//  Parameters - See ProcessRolesInterface.Parameters
//
Procedure FillRoles(Parameters)
	
	ReadRoles = Parameters.MainParameter;
	RolesCollection  = Parameters.RolesCollection;
	
	RolesCollection.Clear();
	AddedRoles = New Map;
	
	If TypeOf(ReadRoles) = Type("Array") Then
		For Each Role In ReadRoles Do
			If AddedRoles.Get(Role) <> Undefined Then
				Continue;
			EndIf;
			AddedRoles.Insert(Role, True);
			RolesCollection.Add().Role = Role;
		EndDo;
	Else
		RoleIDs = New Array;
		For Each RoleDetails In ReadRoles Do
			If TypeOf(RoleDetails.Role) = Type("CatalogRef.MetadataObjectIDs")
			 Or TypeOf(RoleDetails.Role) = Type("CatalogRef.ExtensionObjectIDs") Then
				RoleIDs.Add(RoleDetails.Role);
			EndIf;
		EndDo;
		ReadRoles = Common.MetadataObjectsByIDs(RoleIDs, False);
		
		For Each RoleDetails In ReadRoles Do
			If TypeOf(RoleDetails.Value) <> Type("MetadataObject") Then
				Role = RoleDetails.Key;
				NameOfRole = Common.ObjectAttributeValue(Role, "Name");
				NameOfRole = ?(NameOfRole = Undefined, "(" + Role.UUID() + ")", NameOfRole);
				NameOfRole = ?(Left(NameOfRole, 1) = "?", NameOfRole, "? " + TrimL(NameOfRole));
				RolesCollection.Add().Role = TrimAll(NameOfRole);
			Else
				RolesCollection.Add().Role = RoleDetails.Value.Name;
			EndIf;
		EndDo;
	EndIf;
	
	RefreshRolesTree(Parameters);
	
EndProcedure

// Parameters:
//  Parameters - See ProcessRolesInterface.Parameters
//
Procedure SetUpRoleInterfaceOnFormCreate(Parameters)
	
	Form = Parameters.Form;
	
	// 
	ConditionalAppearanceItem = Form.ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.ErrorNoteText.Value;
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Roles.IsUnavailableRole");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("Roles");
	AppearanceFieldItem.Use = True;
	
	// 
	ConditionalAppearanceItem = Form.ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Roles.IsNonExistingRole");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("Roles");
	AppearanceFieldItem.Use = True;
	
	SetUpRoleInterfaceOnReadAtServer(Parameters);
	
EndProcedure

// Parameters:
//  Parameters - See ProcessRolesInterface.Parameters
//
Procedure SetUpRoleInterfaceOnReadAtServer(Parameters)
	
	Form    = Parameters.Form;
	Items = Form.Items;
	
	// 
	// 
	Form.ShowRoleSubsystems = False;
	Items.RolesShowRolesSubsystems.Check = False;
	
	// 
	If Items.Find("RolesShowSelectedRolesOnly") <> Undefined Then
		Items.RolesShowSelectedRolesOnly.Check = Parameters.MainParameter;
	EndIf;
	
	RefreshRolesTree(Parameters);
	
EndProcedure

// Parameters:
//  Parameters - See ProcessRolesInterface.Parameters
//
Procedure SetUpRoleInterfaceOnLoadSettings(Parameters)
	
	Settings = Parameters.MainParameter;
	Form     = Parameters.Form;
	Items  = Form.Items;
	
	ShowRoleSubsystems = Form.ShowRoleSubsystems;
	
	If Settings["ShowRoleSubsystems"] = False Then
		Form.ShowRoleSubsystems = False;
		Items.RolesShowRolesSubsystems.Check = False;
	Else
		Form.ShowRoleSubsystems = True;
		Items.RolesShowRolesSubsystems.Check = True;
	EndIf;
	
	If ShowRoleSubsystems <> Form.ShowRoleSubsystems Then
		RefreshRolesTree(Parameters);
	EndIf;
	
EndProcedure

// Parameters:
//  Parameters - See ProcessRolesInterface.Parameters
//
Procedure SetRolesReadOnly(Parameters)
	
	Form = Parameters.Form;
	Items               = Form.Items;
	RolesReadOnly    = Parameters.MainParameter;
	
	If RolesReadOnly <> Undefined Then
		
		Items.Roles.ReadOnly = RolesReadOnly;
		
		FoundItem = Items.Find("RolesSelectAll"); // FormButton
		If FoundItem <> Undefined Then
			FoundItem.Enabled = Not RolesReadOnly;
		EndIf;
		
		FoundItem = Items.Find("RolesClearAll"); // FormButton
		If FoundItem <> Undefined Then
			FoundItem.Enabled = Not RolesReadOnly;
		EndIf;
	EndIf;
	
EndProcedure

// Parameters:
//  Parameters - See ProcessRolesInterface.Parameters
//
Procedure SelectedRolesOnly(Parameters)
	
	Form = Parameters.Form;
	
	Form.Items.RolesShowSelectedRolesOnly.Check =
		Not Form.Items.RolesShowSelectedRolesOnly.Check;
	
	RefreshRolesTree(Parameters);
	
EndProcedure

// Parameters:
//  Parameters - See ProcessRolesInterface.Parameters
//
Procedure GroupBySubsystems(Parameters)
	
	Form = Parameters.Form;
	
	Form.ShowRoleSubsystems = Not Parameters.Form.ShowRoleSubsystems;
	Form.Items.RolesShowRolesSubsystems.Check = Parameters.Form.ShowRoleSubsystems;
	
	RefreshRolesTree(Parameters);
	
EndProcedure

// Parameters:
//  Parameters - See ProcessRolesInterface.Parameters
//
Procedure RefreshRolesTree(Parameters)
	
	Form           = Parameters.Form;
	Items        = Form.Items;
	Roles            = Form.Roles;
	RolesAssignment = Parameters.RolesAssignment;
	
	HideFullAccessRole = Parameters.Property("HideFullAccessRole")
	                      And Parameters.HideFullAccessRole = True;
	
	If Items.Find("RolesShowSelectedRolesOnly") <> Undefined Then
		If Not Items.RolesShowSelectedRolesOnly.Enabled Then
			Items.RolesShowSelectedRolesOnly.Check = True;
		EndIf;
		ShowSelectedRolesOnly = Items.RolesShowSelectedRolesOnly.Check;
	Else
		ShowSelectedRolesOnly = True;
	EndIf;
	
	ShowRoleSubsystems = Parameters.Form.ShowRoleSubsystems;
	
	// 
	CurrentSubsystem = "";
	CurrentRole       = "";
	
	If Items.Roles.CurrentRow <> Undefined Then
		CurrentData = Roles.FindByID(Items.Roles.CurrentRow);
		
		If CurrentData = Undefined Then
			Items.Roles.CurrentRow = Undefined;
			
		ElsIf CurrentData.IsRole Then
			CurrentRole       = CurrentData.Name;
			CurrentSubsystem = ?(CurrentData.GetParent() = Undefined, "",
				CurrentData.GetParent().Name);
		Else
			CurrentRole       = "";
			CurrentSubsystem = CurrentData.Name;
		EndIf;
	EndIf;
	
	RolesTreeStorage = UsersInternalCached.RolesTree(ShowRoleSubsystems, RolesAssignment);
	RolesTree = RolesTreeStorage.Get(); // See UsersInternalCached.RolesTree
	
	RolesTree.Columns.Add("IsUnavailableRole",    New TypeDescription("Boolean"));
	RolesTree.Columns.Add("IsNonExistingRole", New TypeDescription("Boolean"));
	AddNonexistentAndUnavailableRoleNames(Parameters, RolesTree);
	
	RolesTree.Columns.Add("Check",       New TypeDescription("Boolean"));
	RolesTree.Columns.Add("PictureNumber", New TypeDescription("Number"));
	PrepareRolesTree(RolesTree.Rows, HideFullAccessRole, ShowSelectedRolesOnly,
		Parameters.RolesCollection, ?(Parameters.Property("StandardExtensionRoles"),
			Parameters.StandardExtensionRoles, Undefined));
	
	Parameters.Form.ValueToFormAttribute(RolesTree, "Roles");
	
	Items.Roles.Representation = ?(RolesTree.Rows.Find(False, "IsRole") = Undefined,
		TableRepresentation.List, TableRepresentation.Tree);
	
	// 
	Filter = New Structure("IsRole, Name", False, CurrentSubsystem);
	FoundRows = RolesTree.Rows.FindRows(Filter, True);
	If FoundRows.Count() <> 0 Then
		SubsystemDetails = FoundRows[0];
		
		SubsystemIndex = ?(SubsystemDetails.Parent = Undefined,
			RolesTree.Rows, SubsystemDetails.Parent.Rows).IndexOf(SubsystemDetails);
		
		SubsystemRow = FormDataTreeItemCollection(Roles,
			SubsystemDetails).Get(SubsystemIndex);
		
		If ValueIsFilled(CurrentRole) Then
			Filter = New Structure("IsRole, Name", True, CurrentRole);
			FoundRows = SubsystemDetails.Rows.FindRows(Filter);
			If FoundRows.Count() <> 0 Then
				RoleDetails = FoundRows[0];
				Items.Roles.CurrentRow = SubsystemRow.GetItems().Get(
					SubsystemDetails.Rows.IndexOf(RoleDetails)).GetID();
			Else
				Items.Roles.CurrentRow = SubsystemRow.GetID();
			EndIf;
		Else
			Items.Roles.CurrentRow = SubsystemRow.GetID();
		EndIf;
	Else
		Filter = New Structure("IsRole, Name", True, CurrentRole);
		FoundRows = RolesTree.Rows.FindRows(Filter, True);
		If FoundRows.Count() <> 0 Then
			RoleDetails = FoundRows[0];
			
			RoleIndex = ?(RoleDetails.Parent = Undefined,
				RolesTree.Rows, RoleDetails.Parent.Rows).IndexOf(RoleDetails);
			
			RoleRow = FormDataTreeItemCollection(Roles, RoleDetails).Get(RoleIndex);
			Items.Roles.CurrentRow = RoleRow.GetID();
		EndIf;
	EndIf;
	
EndProcedure

// Parameters:
//  Parameters - See ProcessRolesInterface.Parameters
//  RolesTree - ValueTree:
//    * IsRole - Boolean
//    * Name     - String -  the name of the role or subsystem.
//    * Synonym - String -  synonym for a role or subsystem.
//    * IsUnavailableRole    - Boolean
//    * IsNonExistingRole - Boolean
//    * Check               - Boolean
//    * PictureNumber         - Number
//
Procedure AddNonexistentAndUnavailableRoleNames(Parameters, RolesTree)
	
	RolesCollection  = Parameters.RolesCollection;
	AllRoles = AllRoles().Map;
	
	UnavailableRoles    = New ValueList;
	NonexistentRoles = New ValueList;
	
	// 
	For Each RoleDetails In RolesCollection Do
		Filter = New Structure("IsRole, Name", True, RoleDetails.Role);
		If RolesTree.Rows.FindRows(Filter, True).Count() > 0 Then
			Continue;
		EndIf;
		Synonym = AllRoles.Get(RoleDetails.Role);
		If Synonym = Undefined Then
			NonexistentRoles.Add(RoleDetails.Role,
				?(Left(RoleDetails.Role, 1) = "?", RoleDetails.Role, "? " + RoleDetails.Role));
		Else
			UnavailableRoles.Add(RoleDetails.Role, Synonym);
		EndIf;
	EndDo;
	
	UnavailableRoles.SortByPresentation();
	For Each RoleDetails In UnavailableRoles Do
		IndexOf = UnavailableRoles.IndexOf(RoleDetails);
		TreeRow = RolesTree.Rows.Insert(IndexOf);
		TreeRow.Name     = RoleDetails.Value;
		TreeRow.Synonym = RoleDetails.Presentation;
		TreeRow.IsRole = True;
		TreeRow.IsUnavailableRole = True;
	EndDo;
	
	NonexistentRoles.SortByPresentation();
	For Each RoleDetails In NonexistentRoles Do
		IndexOf = NonexistentRoles.IndexOf(RoleDetails);
		TreeRow = RolesTree.Rows.Insert(IndexOf);
		TreeRow.Name     = RoleDetails.Value;
		TreeRow.Synonym = RoleDetails.Presentation;
		TreeRow.IsRole = True;
		TreeRow.IsNonExistingRole = True;
	EndDo;
	
EndProcedure

Procedure PrepareRolesTree(Val Collection, Val HideFullAccessRole, Val ShowSelectedRolesOnly,
			RolesCollection, StandardExtensionRoles)
	
	IndexOf = Collection.Count()-1;
	
	While IndexOf >= 0 Do
		String = Collection[IndexOf];
		
		PrepareRolesTree(String.Rows, HideFullAccessRole, ShowSelectedRolesOnly,
			RolesCollection, StandardExtensionRoles);
		
		If String.IsRole Then
			If HideFullAccessRole
			   And (    Upper(String.Name) = Upper("FullAccess")
			      Or Upper(String.Name) = Upper("SystemAdministrator")
			      Or StandardExtensionRoles <> Undefined
			        And (    StandardExtensionRoles.FullAccess.Find(String.Name) <> Undefined
			           Or StandardExtensionRoles.SystemAdministrator.Find(String.Name) <> Undefined)) Then
				Collection.Delete(IndexOf);
			Else
				String.PictureNumber = 7;
				String.Check = RolesCollection.FindRows(
					New Structure("Role", String.Name)).Count() > 0;
				
				If ShowSelectedRolesOnly And Not String.Check Then
					Collection.Delete(IndexOf);
				EndIf;
			EndIf;
		Else
			If String.Rows.Count() = 0 Then
				Collection.Delete(IndexOf);
			Else
				String.PictureNumber = 6;
				String.Check = String.Rows.FindRows(
					New Structure("Check", False)).Count() = 0;
			EndIf;
		EndIf;
		
		IndexOf = IndexOf-1;
	EndDo;
	
EndProcedure

// Returns a hierarchical collection.
// 
// Parameters:
//  FormDataTree - FormDataTree
//  ValueTreeRow - ValueTreeRow
//
// Returns:
//  FormDataTreeItemCollection
// 
Function FormDataTreeItemCollection(Val FormDataTree, Val ValueTreeRow)
	
	If ValueTreeRow.Parent = Undefined Then
		FormDataTreeItemCollection = FormDataTree.GetItems();
	Else
		ParentIndex = ?(ValueTreeRow.Parent.Parent = Undefined,
			ValueTreeRow.Owner().Rows, ValueTreeRow.Parent.Parent.Rows).IndexOf(
				ValueTreeRow.Parent);
			
		FormDataTreeItemCollection = FormDataTreeItemCollection(FormDataTree,
			ValueTreeRow.Parent).Get(ParentIndex).GetItems();
	EndIf;
	
	Return FormDataTreeItemCollection;
	
EndFunction

// Parameters:
//  Parameters - See ProcessRolesInterface.Parameters
//
Procedure UpdateRoleComposition(Parameters)
	
	Form = Parameters.Form;
	
	RoleTable                = Form.Items.Roles;
	Roles                        = Form.Roles;
	ShowSelectedRolesOnly = Form.Items.RolesShowSelectedRolesOnly.Check;
	RolesAssignment             = Parameters.RolesAssignment;
	
	AllRoles         = AllRoles().Array;
	UnavailableRoles = UsersInternalCached.UnavailableRoles(RolesAssignment);
	
	If Parameters.MainParameter = "EnableAll" Then
		Add = True;
		RowsIDs = Undefined;
		
	ElsIf Parameters.MainParameter = "DisableAll" Then
		Add = False;
		RowsIDs = Undefined;
		
	ElsIf Parameters.MainParameter = "EnableHighlighted" Then
		Add = True;
		RowsIDs = RoleTable.SelectedRows;
		
	ElsIf Parameters.MainParameter = "ClearMarked" Then
		Add = False;
		RowsIDs = RoleTable.SelectedRows;
	Else
		RowsIDs = CommonClientServer.ValueInArray(
			Form.Items.Roles.CurrentRow);
	EndIf;
	
	If RowsIDs = Undefined Then
		
		AdministrativeAccessEnabled = Parameters.RolesCollection.FindRows(
			New Structure("Role", "FullAccess")).Count() > 0;
		
		// 
		RolesCollection = Parameters.RolesCollection;
		RolesCollection.Clear();
		If Add Then
			For Each NameOfRole In AllRoles Do
				
				If NameOfRole = "FullAccess"
				 Or NameOfRole = "SystemAdministrator"
				 Or UnavailableRoles.Get(NameOfRole) <> Undefined
				 Or Upper(Left(NameOfRole, StrLen("Delete"))) = Upper("Delete") Then
					
					Continue;
				EndIf;
				RolesCollection.Add().Role = NameOfRole;
			EndDo;
		EndIf;
		
		If Parameters.Property("AdministrativeAccessChangeProhibition")
			And Parameters.AdministrativeAccessChangeProhibition Then
			
			AdministrativeAccessWasEnabled = Parameters.RolesCollection.FindRows(
				New Structure("Role", "FullAccess")).Count() > 0;
			
			If AdministrativeAccessWasEnabled And Not AdministrativeAccessEnabled Then
				Filter = New Structure("Role", "FullAccess");
				Parameters.RolesCollection.FindRows(Filter).Delete(0);
				
			ElsIf AdministrativeAccessEnabled And Not AdministrativeAccessWasEnabled Then
				RolesCollection.Add().Role = "FullAccess";
			EndIf;
		EndIf;
		FillStandardExtensionRoles(Parameters);
		
		If ShowSelectedRolesOnly Then
			If RolesCollection.Count() > 0 Then
				RefreshRolesTree(Parameters);
			Else
				Roles.GetItems().Clear();
			EndIf;
			
			Return;
		EndIf;
	Else
		For Each RowID In RowsIDs Do
			CurrentData = Roles.FindByID(RowID);
			Add = ?(Add = Undefined, CurrentData.Check, Add);
			If CurrentData.IsRole Then
				AddDeleteRole(Parameters, CurrentData.Name, Add);
			Else
				AddDeleteSubsystemRoles(Parameters, CurrentData.GetItems(), Add);
			EndIf;
		EndDo;
		FillStandardExtensionRoles(Parameters);
	EndIf;
	
	UpdateSelectedRoleMarks(Parameters, Roles.GetItems());
	
EndProcedure

Procedure FillStandardExtensionRoles(Parameters)
	
	If Not Parameters.Property("StandardExtensionRoles") Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessGroupsProfiles = Common.CommonModule("Catalogs.AccessGroupProfiles");
		ModuleAccessGroupsProfiles.FillStandardExtensionRoles(Parameters.RolesCollection,
			Parameters.StandardExtensionRoles);
	EndIf;
	
EndProcedure

// Parameters:
//  Parameters - See ProcessRolesInterface.Parameters
//  Role      - String
//  Add  - Boolean
//
Procedure AddDeleteRole(Parameters, Val Role, Val Add)
	
	FoundRoles = Parameters.RolesCollection.FindRows(New Structure("Role", Role));
	
	If Add Then
		If FoundRoles.Count() = 0 Then
			Parameters.RolesCollection.Add().Role = Role;
		EndIf;
	Else
		If FoundRoles.Count() > 0 Then
			Parameters.RolesCollection.Delete(FoundRoles[0]);
		EndIf;
	EndIf;
	
EndProcedure

// Changes the composition of roles.
//
// Parameters:
//  Parameters - See ProcessRolesInterface.Parameters
//  Collection - 
//  Add  - Boolean
//
Procedure AddDeleteSubsystemRoles(Parameters, Val Collection, Val Add)
	
	For Each RoleDetails In Collection Do
		If RoleDetails.IsRole Then
			AddDeleteRole(Parameters, RoleDetails.Name, Add);
		Else
			AddDeleteSubsystemRoles(Parameters, RoleDetails.GetItems(), Add);
		EndIf;
	EndDo;
	
EndProcedure

// Parameters:
//  Parameters - See ProcessRolesInterface.Parameters
//  Collection - 
//
Procedure UpdateSelectedRoleMarks(Parameters, Val Collection)
	
	Form = Parameters.Form;
	
	ShowSelectedRolesOnly = Form.Items.RolesShowSelectedRolesOnly.Check;
	
	IndexOf = Collection.Count()-1;
	
	While IndexOf >= 0 Do
		String = Collection[IndexOf];
		
		If String.IsRole Then
			Filter = New Structure("Role", String.Name);
			String.Check = Parameters.RolesCollection.FindRows(Filter).Count() > 0;
			If ShowSelectedRolesOnly And Not String.Check Then
				Collection.Delete(IndexOf);
			EndIf;
		Else
			UpdateSelectedRoleMarks(Parameters, String.GetItems());
			If String.GetItems().Count() = 0 Then
				Collection.Delete(IndexOf);
			Else
				String.Check = True;
				For Each Item In String.GetItems() Do
					If Not Item.Check Then
						String.Check = False;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		IndexOf = IndexOf-1;
	EndDo;
	
EndProcedure

Function UsersAddedInDesigner()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref,
	|	Users.Description AS FullName,
	|	Users.IBUserID,
	|	FALSE AS IsExternalUser
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.IBUserID <> &BlankUUID
	|
	|UNION ALL
	|
	|SELECT
	|	ExternalUsers.Ref,
	|	ExternalUsers.Description,
	|	ExternalUsers.IBUserID,
	|	TRUE
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.IBUserID <> &BlankUUID";
	
	Query.SetParameter("BlankUUID", 
		CommonClientServer.BlankUUID());
	
	Upload0 = Query.Execute().Unload();
	Upload0.Indexes.Add("IBUserID");
	
	IBUsers = InfoBaseUsers.GetUsers();
	UsersAddedInDesignerCount = 0;
	
	For Each IBUser In IBUsers Do
		
		String = Upload0.Find(IBUser.UUID, "IBUserID");
		If String = Undefined Then
			UsersAddedInDesignerCount = UsersAddedInDesignerCount + 1;
		EndIf;
		
	EndDo;
	
	Return UsersAddedInDesignerCount;
	
EndFunction

#EndRegion