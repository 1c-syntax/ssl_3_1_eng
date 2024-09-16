///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns the flag for whether user change actions are available.
//
// Returns:
//   Boolean - 
//
Function CanChangeUsers() Export
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		Return ModuleSaaSOperations.CanChangeUsers();
	EndIf;
	Return False;
	
EndFunction

// Returns actions available to the current user with the specified
// service user.
//
// Parameters:
//  User - CatalogRef.Users - 
//   
//   
//
//  MinimalActions - Undefined - 
//   
//   
//  
// Returns:
//   See NewActionsWithSaaSUser
//
Function GetActionsWithSaaSUser(Val User = Undefined,
			MinimalActions = Undefined) Export
	
	MinimalActions = NewActionsWithSaaSUser();
	
	If User = Undefined Then
		User = Users.CurrentUser();
	EndIf;
	
	If Not CanChangeUsers() Then
		Return ActionsWithSaaSUserWhenUserSetupUnavailable();
	EndIf;
		
	If InfoBaseUsers.CurrentUser().DataSeparation.Count() = 0 Then
		If Users.IsFullUser(, True) Then
			Return ActionsWithNewSaaSUser();
		Else
			Return ActionsWithSaaSUserWhenUserSetupUnavailable();
		EndIf;
		
	ElsIf IsExistingUserCurrentDataArea(User) Then
		Return ActionsWithExsistingSaaSUser(User);
	Else
		If HasRightToAddUsers() Then
			Return ActionsWithNewSaaSUser();
		Else
			ErrorText = NStr("en = 'Insufficient rights to add users';");
			Raise(ErrorText, ErrorCategory.AccessViolation);
		EndIf;
	EndIf;
	
EndFunction

// Generates a request to change the service user's email address
// .
//
// Parameters:
//  NewEmailAddress - String -  the user's new email address.
//  User - CatalogRef.Users -  the user who
//   needs to change the email address.
//  ServiceUserPassword - String -  password of the current user
//   to access the service Manager.
//
Procedure CreateEmailAddressChangeRequest(Val NewEmailAddress, Val User, Val ServiceUserPassword) Export
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		Return;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	Proxy = ModuleSaaSOperations.GetProxyServiceManager(ServiceUserPassword);
	SetPrivilegedMode(False);
	
	ErrorInfo = Undefined;
	Proxy.RequestEmailChange(
		Common.ObjectAttributeValue(User, "ServiceUserID"), 
		NewEmailAddress, 
		ErrorInfo);
	HandleWebServiceErrorInfo(ErrorInfo, "RequestEmailChange"); 
	
EndProcedure

// Creates / updates a record of the service user.
// 
// Parameters:
//  User - CatalogRef.Users
//               - CatalogObject.Users
//
//  CreateServiceUser - Boolean
//     The truth is to create a new user of the service,
//     False - update an existing one.
//
//  ServiceUserPassword - String -  password of the current user
//   to access the service Manager.
//
Procedure WriteSaaSUser(Val User, Val CreateServiceUser, Val ServiceUserPassword) Export
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		Return;
	EndIf;
	
	If TypeOf(User) = Type("CatalogRef.Users") Then
		UserObject = User.GetObject();
	Else
		UserObject = User;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	Proxy = ModuleSaaSOperations.GetProxyServiceManager(ServiceUserPassword);
	SetPrivilegedMode(False);
	
	If ValueIsFilled(UserObject.IBUserID) Then
		IBUser = InfoBaseUsers.FindByUUID(UserObject.IBUserID);
		AccessAllowed = CanStartApp(IBUser);
	Else
		AccessAllowed = False;
	EndIf;
	
	SaaSUser = Proxy.XDTOFactory.Create(
		Proxy.XDTOFactory.Type("http://www.1c.ru/SaaS/ApplicationUsers", "User"));
	SaaSUser.Zone = ModuleSaaSOperations.SessionSeparatorValue();
	SaaSUser.UserServiceID = UserObject.ServiceUserID;
	SaaSUser.FullName = UserObject.Description;
	SaaSUser.Name = IBUser.Name;
	SaaSUser.StoredPasswordValue = IBUser.StoredPasswordValue;
	SaaSUser.Language = GetLanguageCode(IBUser.Language);
	SaaSUser.Access = AccessAllowed;
	SaaSUser.AdmininstrativeAccess = AccessAllowed And IBUser.Roles.Contains(Metadata.Roles.FullAccess);
	
	ContactInformation = Proxy.XDTOFactory.Create(
		Proxy.XDTOFactory.Type("http://www.1c.ru/SaaS/ApplicationUsers", "ContactsList"));
		
	CIWriterType = Proxy.XDTOFactory.Type("http://www.1c.ru/SaaS/ApplicationUsers", "ContactsItem");
	
	CIKindsMap = ModuleSaaSOperations.MatchingUserSAITypesToXDTO();
	For Each CIRow In UserObject.ContactInformation Do
		CIKindXDTO = CIKindsMap.Get(CIRow.Kind);
		If CIKindXDTO = Undefined Then
			Continue;
		EndIf;
		
		CIWriter = Proxy.XDTOFactory.Create(CIWriterType);
		CIWriter.ContactType = CIKindXDTO;
		CIWriter.Value = CIRow.Presentation;
		CIWriter.Parts = CIRow.FieldValues;
		
		KIRecords = ContactInformation.Item; // XDTOList
		KIRecords.Add(CIWriter);
	EndDo;
	
	SaaSUser.Contacts = ContactInformation;
	
	ErrorInfo = Undefined;
	If CreateServiceUser Then
		Proxy.CreateUser(SaaSUser, ErrorInfo);
		HandleWebServiceErrorInfo(ErrorInfo, "CreateUser"); 
	Else
		Proxy.UpdateUser(SaaSUser, ErrorInfo);
		HandleWebServiceErrorInfo(ErrorInfo, "UpdateUser"); 
	EndIf;
	
EndProcedure

// 
// 
// 
// Parameters:
//  User - CatalogRef.Users
//  IBUser - InfoBaseUser
//  InfobaseOldUser - Undefined - 
//                       - InfoBaseUser - 
//
Procedure NotifyAppStartupModified(User, IBUser, InfobaseOldUser = Undefined) Export
	
	If Not Common.SubsystemExists("CloudTechnology.Core")
	 Or Not Common.SubsystemExists("CloudTechnology.MessagesExchange") Then
		Return;
	EndIf;
	
	IsStartupPossible = CanStartApp(IBUser);
	If InfobaseOldUser <> Undefined
	   And IsStartupPossible = CanStartApp(InfobaseOldUser)
	 Or Not MessagesSupportedHasRightsToLogIn() Then
		Return;
	EndIf;
	
	Attributes = Common.ObjectAttributesValues(User,
		"IBUserID, ServiceUserID");
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesExchange = Common.CommonModule("MessagesExchange");
	
	User_Info = New Structure;
	User_Info.Insert("DataArea", ModuleSaaSOperations.SessionSeparatorValue());
	User_Info.Insert("IBUserID", Attributes.IBUserID);
	User_Info.Insert("ServiceUserID", Attributes.ServiceUserID);
	User_Info.Insert("HasRights", IsStartupPossible);
	User_Info.Insert("DateUTC", CurrentUniversalDate());
	
	BeginTransaction();
	Try
		ModuleMessagesExchange.SendMessage("UserHandler/LaunchSwitch", Common.ValueToXMLString(
			User_Info), ModuleSaaSOperations.ServiceManagerEndpoint());
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#Region SharedInfobaseUsersOperations

// Called before starting the program before calling all other handlers.
Procedure BeforeStartApplication() Export
	
	If IsSharedIBUser() Then
		RecordSharedUserInRegister();
	EndIf;
	
EndProcedure

// Checks whether the is user with the specified ID
// is included in the list of undivided users.
//
// Parameters:
//   IBUserID - UUID -  the ID
//        of the IB user for whom it is necessary to check
//        whether they belong to undivided users.
//
// Returns:
//  Boolean
//
Function UserRegisteredAsShared(Val IBUserID) Export
	
	If Not ValueIsFilled(IBUserID) Then
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SharedUserIDs.IBUserID
	|FROM
	|	InformationRegister.SharedUsers AS SharedUserIDs
	|WHERE
	|	SharedUserIDs.IBUserID = &IBUserID";
	Query.SetParameter("IBUserID", IBUserID);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.SharedUsers");
	LockItem.SetValue("IBUserID", IBUserID);
	LockItem.Mode = DataLockMode.Shared;
	
	BeginTransaction();
	Try
		Block.Lock();
		Result = Query.Execute();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Not Result.IsEmpty();
	
EndFunction

#EndRegion

#Region ConfigurationSubsystemsEventHandlers

// See SSLSubsystemsIntegration.OnNoCurrentUserInCatalog
Procedure OnNoCurrentUserInCatalog(CreateUser) Export
	
	If IsSharedIBUser() Then
		// 
		// 
		CreateUser = True;
	EndIf;
	
EndProcedure

// See SSLSubsystemsIntegration.OnAutoCreateCurrentUserInCatalog
Procedure OnAutoCreateCurrentUserInCatalog(NewUser) Export
	
	If IsSharedIBUser() Then
		NewUser.IsInternal = True;
		NewUser.Description = InternalUserFullName(
			InfoBaseUsers.CurrentUser().UUID);
	EndIf;
	
EndProcedure

// See SSLSubsystemsIntegration.OnAuthorizeNewIBUser
Procedure OnAuthorizeNewIBUser(Val CurrentIBUser, StandardProcessing) Export
	
	If Not Common.DataSeparationEnabled()
		Or Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	If Not IsSharedIBUser() Then
		Return;
	EndIf;
			
	StandardProcessing = False;
	
	BeginTransaction();
	Try
		
		Block = New DataLock();
		Block.Add("Catalog.Users");
		Block.Lock();
		
		If Not UsersInternal.UserByIDExists(CurrentIBUser.UUID) Then
			
			// 
			UserObject = Catalogs.Users.CreateItem();
			UserObject.Description = InternalUserFullName(CurrentIBUser.UUID);
			UserObject.IsInternal = True;
			UserObject.Write();
			
			UserObject.IBUserID = CurrentIBUser.UUID;
			UserObject.DataExchange.Load = True;
			UserObject.Write();
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
		
EndProcedure

// See SSLSubsystemsIntegration.OnStartIBUserProcessing
Procedure OnStartIBUserProcessing(ProcessingParameters, IBUserDetails) Export
	
	If ValueIsFilled(ProcessingParameters.OldUser.IBUserID)
	   And Common.DataSeparationEnabled()
	   And UserRegisteredAsShared(
	         ProcessingParameters.OldUser.IBUserID) Then
		
		Raise SharedUserCannotBeWrittenExceptionText();
		
	ElsIf IBUserDetails.Property("UUID")
	        And ValueIsFilled(IBUserDetails.UUID)
	        And Common.DataSeparationEnabled()
	        And UserRegisteredAsShared(
	              IBUserDetails.UUID) Then
		
		// 
		// 
		ProcessingParameters.Delete("Action");
		
		If IBUserDetails.Count() > 2
		 Or IBUserDetails.Action = "Delete" Then
			
			Raise SharedUserCannotBeWrittenExceptionText();
		EndIf;
	EndIf;
	
EndProcedure

// See SSLSubsystemsIntegration.BeforeWriteIBUser
Procedure BeforeWriteIBUser(IBUser) Export
	
	If Common.DataSeparationEnabled() Then
		If UserRegisteredAsShared(IBUser.UUID) Then
			Raise SharedUserCannotBeWrittenExceptionText();
		EndIf;
	EndIf;
	
EndProcedure

// Processing of an information security user during the recording of an element of the directory Users and external users.
// Called from the Start User Processing procedure to support the service model.
// 
// Parameters:
//  UserObject - CatalogObject.Users
//                     - CatalogObject.ExternalUsers
//  ProcessingParameters - Structure
//
Procedure BeforeStartIBUserProcessing(Val UserObject, ProcessingParameters) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	AdditionalProperties = UserObject.AdditionalProperties;
	OldUser     = ProcessingParameters.OldUser;
	AutoAttributes          = ProcessingParameters.AutoAttributes;
	
	If TypeOf(UserObject) = Type("CatalogObject.ExternalUsers") Then
		ErrorText = NStr("en = 'SaaS applications don''t support external users.';");
		Raise ErrorText;
	EndIf;
	
	AutoAttributes.Insert("ServiceUserID", OldUser.ServiceUserID);
	
	If AdditionalProperties.Property("RemoteAdministrationChannelMessageProcessing") Then
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		If Not ModuleSaaSOperations.SessionWithoutSeparators() Then
			ErrorText =
				NStr("en = 'Only shared users can edit
				           |user information via remote administration.';");
			Raise ErrorText;
		EndIf;
		
		ProcessingParameters.Insert("RemoteAdministrationChannelMessageProcessing");
		AutoAttributes.ServiceUserID = UserObject.ServiceUserID;
		
	ElsIf Not UserObject.IsInternal Then
		UpdateDetailsSaasManagerWebService();
	EndIf;
	
	If ValueIsFilled(AutoAttributes.ServiceUserID)
	   And AutoAttributes.ServiceUserID <> OldUser.ServiceUserID Then
		
		If ValueIsFilled(OldUser.ServiceUserID) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot change the service user ID for ""%1"".';"),
				UserObject.Description);
			Raise ErrorText;
		EndIf;
		
		FoundUser = Undefined;
		
		If UsersInternal.UserByIDExists(
				AutoAttributes.ServiceUserID,
				UserObject.Ref,
				FoundUser,
				True) Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot set the ""%1"" service user ID for ""%2""
				           |as it is already specified in another ""%3"".';"),
				AutoAttributes.ServiceUserID,
				UserObject.Description,
				FoundUser);
			Raise ErrorText;
		EndIf;
	EndIf;
	
EndProcedure

// Called from the start user processing procedure To support the service model.
//
// Parameters:
//  UserObject - CatalogObject.Users
//                     - CatalogObject.ExternalUsers
//  ProcessingParameters - Structure
//
Procedure AfterStartIBUserProcessing(UserObject, ProcessingParameters) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	AutoAttributes = ProcessingParameters.AutoAttributes;
	
	ProcessingParameters.Insert("CreateServiceUser", False);
	
	If ProcessingParameters.NewIBUserExists
		And Common.DataSeparationEnabled() Then
		
		If Not ValueIsFilled(AutoAttributes.ServiceUserID) Then
			
			ProcessingParameters.Insert("CreateServiceUser", True);
			UserObject.ServiceUserID = New UUID;
			
			// 
			AutoAttributes.ServiceUserID = UserObject.ServiceUserID;
		EndIf;
	EndIf;
	
EndProcedure

// Called from the end user processing procedure To support the service model.
//
// Parameters:
//  UserObject - CatalogObject.Users
//                     - CatalogObject.ExternalUsers
//  ProcessingParameters - Structure
//
Procedure BeforeEndIBUserProcessing(UserObject, ProcessingParameters) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	AutoAttributes = ProcessingParameters.AutoAttributes;	
	If AutoAttributes.ServiceUserID <> UserObject.ServiceUserID Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot change the %1 attribute for ""%2"".
			           |The attribute value will be updated automatically.';"),
			"ServiceUserID", UserObject.Ref);
		Raise ErrorText;
	EndIf;
	
EndProcedure

// Called from the end user processing procedure To support the service model.
// 
// Parameters:
//  UserObject - CatalogObject.Users
//                     - CatalogObject.ExternalUsers
//  ProcessingParameters - Structure
//  UpdateRoles      - Boolean -  the return value.
//
Procedure OnEndIBUserProcessing(UserObject, ProcessingParameters, UpdateRoles) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If ProcessingParameters.Property("RemoteAdministrationChannelMessageProcessing") Then
		UpdateRoles = False;
		Return;
	EndIf;
	
	IBUserDetails = UserObject.AdditionalProperties.IBUserDetails;
	
	If TypeOf(UserObject) = Type("CatalogObject.Users")
	   And IBUserDetails.Property("ActionResult")
	   And Not UserObject.IsInternal Then
		
		If IBUserDetails.ActionResult = "IBUserDeleted" Then
			
			SetPrivilegedMode(True);
			CancelSaaSUserAccess(UserObject);
			SetPrivilegedMode(False);
			
		Else // 
			
			SetPrivilegedMode(True);
			If UserObject.AdditionalProperties.Property("SynchronizeWithService")
			   And UserObject.AdditionalProperties.SynchronizeWithService Then
				
				WriteSaaSUser(UserObject,
					ProcessingParameters.CreateServiceUser,
					UserObject.AdditionalProperties.ServiceUserPassword);
			Else
				NotifyAppStartupModified(UserObject.Ref,
					ProcessingParameters.InfobaseNewUser,
					ProcessingParameters.InfobaseOldUser);
			EndIf;
			SetPrivilegedMode(False);
			
			If ProcessingParameters.CreateServiceUser Then
				SSLSubsystemsIntegration.OnEndIBUserProcessing(UserObject.Ref);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See SSLSubsystemsIntegration.OnDefineUserAlias
Procedure OnDefineUserAlias(UserIdentificator, Alias) Export
	
	If UserRegisteredAsShared(UserIdentificator) Then
		Alias = InternalUserFullName(UserIdentificator);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 
// 

// See ExportImportDataOverridable.OnFillTypesThatRequireRefAnnotationOnImport.
Procedure OnFillTypesThatRequireRefAnnotationOnImport(Types) Export
	
	DataProcessors.ExportImportDataCollapsingUserReferencesInSeparatedData.OnFillTypesThatRequireRefAnnotationOnImport(
		Types);
	
EndProcedure

// See ExportImportDataOverridable.OnRegisterDataExportHandlers.
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	DataProcessors.ExportImportDataCollapsingUserReferencesInSeparatedData.OnRegisterDataExportHandlers(
		HandlersTable);
	
EndProcedure

// See ExportImportDataOverridable.OnRegisterDataImportHandlers.
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	DataProcessors.ExportImportDataCollapsingUserReferencesInSeparatedData.OnRegisterDataImportHandlers(
		HandlersTable);
	
EndProcedure

// See ExportImportDataOverridable.OnImportInfobaseUser.
Procedure OnImportInfobaseUser(Container, Serialization, IBUser, Cancel) Export
	
	If Not Common.DataSeparationEnabled() Then
		
		IBUser.ShowInList = True;
		// 
		If IBUser.Roles.Contains(Metadata.Roles.FullAccess) Then
			IBUser.Roles.Add(Metadata.Roles.SystemAdministrator);
		EndIf;
		
		InfobaseUpdateInternal.SetShowDetailsToNewUserFlag(IBUser.Name);
		
	EndIf;
	
EndProcedure

// See ExportImportDataOverridable.AfterImportInfobaseUser.
Procedure AfterImportInfobaseUser(Container, Serialization, IBUser) Export
	
	If Not Container.AdditionalProperties.Property("UserMap") Then
		Container.AdditionalProperties.Insert("UserMap", New Map());
	EndIf;
	
	Container.AdditionalProperties.UserMap.Insert(Serialization.UUID, IBUser.UUID);
	
EndProcedure

// See ExportImportDataOverridable.AfterImportInfobaseUsers.
Procedure AfterImportInfobaseUsers(Container) Export
	
	If Container.AdditionalProperties.Property("UserMap") Then
		UpdateIBUsersIDs(Container.AdditionalProperties.UserMap);
	Else
		UpdateIBUsersIDs(New Map);
	EndIf;
	
	Container.AdditionalProperties.Insert("UserMap", Undefined);
	
EndProcedure

#EndRegion

#Region EventsSubscriptionsHandlers

Procedure GetUserFormProcessing(Source, FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If FormType = "ObjectForm"
		And Parameters.Property("Key") And Not Parameters.Key.IsEmpty() Then
		
		SetPrivilegedMode(True);
		
		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	1
		|FROM
		|	InformationRegister.SharedUsers AS SharedUsers
		|		INNER JOIN Catalog.Users AS Users
		|		ON SharedUsers.IBUserID = Users.IBUserID
		|			AND (Users.Ref = &Ref)";
		Query.SetParameter("Ref", Parameters.Key);
		If Not Query.Execute().IsEmpty() Then
			StandardProcessing = False;
			SelectedForm = Metadata.CommonForms.SharedUserInfo;
			Return;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// For internal use only.
//
// Returns:
//   See NewActionsWithSaaSUser
//
Function ActionsWithSaaSUserWhenUserSetupUnavailable()
	
	ActionsWithSaaSUser = NewActionsWithSaaSUser();
	ActionsWithSaaSUser.EditPassword = False;
	ActionsWithSaaSUser.ChangeName = False;
	ActionsWithSaaSUser.ChangeFullName = False;
	ActionsWithSaaSUser.ChangeAccess = False;
	ActionsWithSaaSUser.ChangeAdministrativeAccess = False;
	
	ActionsWithContactInformation = ActionsWithSaaSUser.ContactInformation;
	If Common.SubsystemExists("CloudTechnology.Core") Then
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		For Each KeyAndValue In ModuleSaaSOperations.MatchingUserSAITypesToXDTO() Do
			ActionsWithContactInformation[KeyAndValue.Key].Update = False;
		EndDo;
		
	EndIf;
	
	Return ActionsWithSaaSUser;
	
EndFunction

// For internal use only.
//
// Parameters:
//   User - CatalogRef.Users -  user.
//
// Returns:
//   See NewActionsWithSaaSUser
//
Function ActionsWithExsistingSaaSUser(Val User)
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		ErrorText = NStr("en = 'SaaS mode is not supported.';");
		Raise ErrorText;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	Proxy = ModuleSaaSOperations.GetProxyServiceManager();
	SetPrivilegedMode(False);
	
	AccessObjects = PrepareUserAccessObjects(Proxy.XDTOFactory, User);
	
	ErrorInfo = Undefined;
	ObjectsAccessRightsXDTO = Proxy.GetObjectsAccessRights(AccessObjects, 
		CurrentUserServiceID(), ErrorInfo);
	HandleWebServiceErrorInfo(ErrorInfo, "GetObjectsAccessRights"); 
	
	Return ObjectsAccessRightsXDTOInActionsWithSaaSUser(Proxy.XDTOFactory, ObjectsAccessRightsXDTO);
	
EndFunction

// For internal use only.
//
// Returns:
//   See NewActionsWithSaaSUser
//
Function ActionsWithNewSaaSUser()
	
	ActionsWithSaaSUser = NewActionsWithSaaSUser();
	ActionsWithSaaSUser.EditPassword = True;
	ActionsWithSaaSUser.ChangeName = True;
	ActionsWithSaaSUser.ChangeFullName = True;
	ActionsWithSaaSUser.ChangeAccess = True;
	ActionsWithSaaSUser.ChangeAdministrativeAccess = True;
	
	ActionsWithCI = ActionsWithSaaSUser.ContactInformation;
	If Common.SubsystemExists("CloudTechnology.Core") Then
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		For Each KeyAndValue In ModuleSaaSOperations.MatchingUserSAITypesToXDTO() Do
			ActionsWithCI[KeyAndValue.Key].Update = True;
		EndDo;
		
	EndIf;
	
	Return ActionsWithSaaSUser;
	
EndFunction

// For internal use only.
//
// Returns:
//   Boolean - 
//
Function HasRightToAddUsers()
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		ErrorText = NStr("en = 'SaaS mode is not supported.';");
		Raise ErrorText;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	Proxy = ModuleSaaSOperations.GetProxyServiceManager();
	SetPrivilegedMode(False);
	
	DataArea = Proxy.XDTOFactory.Create(
		Proxy.XDTOFactory.Type("http://www.1c.ru/SaaS/ApplicationAccess", "Zone"));
	DataArea.Zone = ModuleSaaSOperations.SessionSeparatorValue();
	
	ErrorInfo = Undefined;
	AccessRightsXDTO = Proxy.GetAccessRights(DataArea, 
		CurrentUserServiceID(), ErrorInfo);
	HandleWebServiceErrorInfo(ErrorInfo, "GetAccessRights"); 
	
	For Each RightsListItem In AccessRightsXDTO.Item Do
		If RightsListItem.AccessRight = "CreateUser" Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// For internal use only.
Procedure UpdateDetailsSaasManagerWebService()
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	// 
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleSaaSOperations.GetProxyServiceManager();
	SetPrivilegedMode(False);
	
EndProcedure

// Parameters:
//  IBUser - 
//
// Returns:
//  Boolean
//
Function CanStartApp(IBUser)
	
	Return IBUser <> Undefined
		And Users.CanSignIn(IBUser)
		And Users.HasRightsToLogIn(IBUser,, False);
	
EndFunction

// For internal use only.
//
// Parameters:
//  ServiceUserPassword - String
//                            - Undefined - 
//
// Returns:
//  ValueTable:
//   * Id - UUID
//   * Name - String
//   * FullName - String
//   * Access - Boolean
//
Function GetSaaSUsers(ServiceUserPassword) Export
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		ErrorText = NStr("en = 'SaaS mode is not supported.';");
		Raise ErrorText;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	Proxy = ModuleSaaSOperations.GetProxyServiceManager(ServiceUserPassword);
	SetPrivilegedMode(False);
	
	ErrorInfo = Undefined;
	Try
		UsersList = Proxy.GetUsersList(ModuleSaaSOperations.SessionSeparatorValue(), );
	Except
		ServiceUserPassword = Undefined;
		Raise;
	EndTry;
	
	HandleWebServiceErrorInfo(ErrorInfo, "GetUsersList"); 
	
	Result = New ValueTable;
	Result.Columns.Add("Id", New TypeDescription("UUID"));
	Result.Columns.Add("Name", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	Result.Columns.Add("FullName", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	Result.Columns.Add("Access", New TypeDescription("Boolean"));
	
	For Each UserInformation In UsersList.Item Do
		UserRow1 = Result.Add();
		UserRow1.Id = UserInformation.UserServiceID;
		UserRow1.Name = UserInformation.Name;
		UserRow1.FullName = UserInformation.FullName;
		UserRow1.Access = UserInformation.Access;
	EndDo;
	
	Return Result;
	
EndFunction

// For internal use only.
Procedure GrantSaaSUserAccess(Val ServiceUserID, Val ServiceUserPassword) Export
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		ErrorText = NStr("en = 'SaaS mode is not supported.';");
		Raise ErrorText;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	Proxy = ModuleSaaSOperations.GetProxyServiceManager(ServiceUserPassword);
	SetPrivilegedMode(False);
	
	ErrorInfo = Undefined;
	Proxy.GrantUserAccess(
		ModuleSaaSOperations.SessionSeparatorValue(),
		ServiceUserID, 
		ErrorInfo);
	HandleWebServiceErrorInfo(ErrorInfo, "GrantUserAccess"); 
	
EndProcedure

// For the user's pre-completion procedure.
Procedure CancelSaaSUserAccess(UserObject)
	
	If Not Common.SubsystemExists("CloudTechnology.Core")
		Or Not Common.SubsystemExists("CloudTechnology.MessagesExchange")
		Or Not ValueIsFilled(UserObject.ServiceUserID) Then
		Return;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	BeginTransaction();
	Try
		ApplicationManagementMessageModuleInterface = Common.CommonModule("ApplicationManagementMessagesInterface");
		Message = ModuleMessagesSaaS.NewMessage(
			ApplicationManagementMessageModuleInterface.RevokeUserAccessMessage());
		
		Message.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		Message.Body.UserServiceID = UserObject.ServiceUserID;
		
		ModuleMessagesSaaS.SendMessage(
			Message,
			ModuleSaaSOperations.ServiceManagerEndpoint());
			
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Checks that the passed user corresponds to an existing user of the information
// database in the current data area.
//
// Parameters:
//  User - CatalogRef.Users
//
// Returns:
//   Boolean
//
Function IsExistingUserCurrentDataArea(Val User)
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(User) Then
		Return False;
	EndIf;
		
	If Not ValueIsFilled(User.IBUserID) Then
		Return False;
	EndIf;
		
	Return InfoBaseUsers.FindByUUID(User.IBUserID) <> Undefined;		
	
EndFunction

#Region AuxiliaryProceduresAndFunctions

Function CurrentUserServiceID()
	
	Return Common.ObjectAttributeValue(Users.CurrentUser(), "ServiceUserID");
	
EndFunction

// Returns:
//  Structure:
//   * EditPassword - Boolean
//   * ChangeName - Boolean
//   * ChangeFullName - Boolean
//   * ChangeAccess - Boolean
//   * ChangeAdministrativeAccess - Boolean
//   * ContactInformation - Map of KeyAndValue:
//      ** Key - CatalogRef.ContactInformationKinds
//      ** Value - Structure:
//          *** Update - Boolean
//
Function NewActionsWithSaaSUser()
	
	ActionsWithSaaSUser = New Structure;
	ActionsWithSaaSUser.Insert("EditPassword", False);
	ActionsWithSaaSUser.Insert("ChangeName", False);
	ActionsWithSaaSUser.Insert("ChangeFullName", False);
	ActionsWithSaaSUser.Insert("ChangeAccess", False);
	ActionsWithSaaSUser.Insert("ChangeAdministrativeAccess", False);
	
	ActionsWithContactInformation = New Map;
	If Common.SubsystemExists("CloudTechnology.Core") Then
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		For Each KeyAndValue In ModuleSaaSOperations.MatchingUserSAITypesToXDTO() Do
			ActionsWithContactInformation.Insert(KeyAndValue.Key, New Structure("Update", False));
		EndDo;
		
	EndIf;
	
	ActionsWithSaaSUser.Insert("ContactInformation", ActionsWithContactInformation);
	Return ActionsWithSaaSUser;
	
EndFunction

Function PrepareUserAccessObjects(Factory, User)
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		ErrorText = NStr("en = 'SaaS mode is not supported.';");
		Raise ErrorText;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	UserInformation1 = Factory.Create(
		Factory.Type("http://www.1c.ru/SaaS/ApplicationAccess", "User"));
	UserInformation1.Zone = ModuleSaaSOperations.SessionSeparatorValue();
	UserInformation1.UserServiceID = Common.ObjectAttributeValue(User, "ServiceUserID");
	
	ListOfObjects = Factory.Create(
		Factory.Type("http://www.1c.ru/SaaS/ApplicationAccess", "ObjectsList"));
		
	CIKinds = ListOfObjects.Item; // XDTOList
	CIKinds.Add(UserInformation1);
	
	UserCIType = Factory.Type("http://www.1c.ru/SaaS/ApplicationAccess", "UserContact");
	
	For Each KeyAndValue In ModuleSaaSOperations.MatchingUserSAITypesToXDTO() Do
		CIKind = Factory.Create(UserCIType);
		CIKind.UserServiceID = Common.ObjectAttributeValue(User, "ServiceUserID");
		CIKind.ContactType = KeyAndValue.Value;
		CIKinds.Add(CIKind);
	EndDo;
	
	Return ListOfObjects;
	
EndFunction

Function ObjectsAccessRightsXDTOInActionsWithSaaSUser(Factory, ObjectsAccessRightsXDTO)
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		ErrorText = NStr("en = 'SaaS mode is not supported.';");
		Raise ErrorText;
	EndIf;
	
	UserInformationType = Factory.Type("http://www.1c.ru/SaaS/ApplicationAccess", "User");
	ContactInformationType = Factory.Type("http://www.1c.ru/SaaS/ApplicationAccess", "UserContact");
	
	ActionsWithSaaSUser = NewActionsWithSaaSUser();
	ActionsWithContactInformation = ActionsWithSaaSUser.ContactInformation;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	RightsMap = ModuleSaaSOperations.ComplianceOfXDTORightsWithActionsWithServiceUser();
	CIKindsMap = ModuleSaaSOperations.ComplianceOfKixdtoTypesWithUserKiTypes();
	
	For Each ObjectAccessRightsXDTO In ObjectsAccessRightsXDTO.Item Do
		
		If ObjectAccessRightsXDTO.Object.Type() = UserInformationType Then
			
			For Each RightsListItem In ObjectAccessRightsXDTO.AccessRights.Item Do
				ActionWithUser = RightsMap.Get(RightsListItem.AccessRight);
				ActionsWithSaaSUser[ActionWithUser] = True;
			EndDo;
			
		ElsIf ObjectAccessRightsXDTO.Object.Type() = ContactInformationType Then
			ContactInformationKind = CIKindsMap.Get(ObjectAccessRightsXDTO.Object.ContactType);
			If ContactInformationKind = Undefined Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Unknown contact information kind: %1';"),
					ObjectAccessRightsXDTO.Object.ContactType);
				Raise ErrorText;
			EndIf;
			
			ActionsWithContactInformationKind = ActionsWithContactInformation[ContactInformationKind];
			For Each RightsListItem In ObjectAccessRightsXDTO.AccessRights.Item Do
				If RightsListItem.AccessRight = "Change" Then
					ActionsWithContactInformationKind.Update = True;
				EndIf;
			EndDo;
		Else
			XDTOType = ObjectAccessRightsXDTO.Object.Type();
			TypePresentation = XDTOSerializer.XMLString(New XMLExpandedName(XDTOType.NamespaceURI, XDTOType.Name));
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Unknown access object type: %1';"), TypePresentation);
			Raise ErrorText;
		EndIf;
		
	EndDo;
	
	Return ActionsWithSaaSUser;
	
EndFunction

Function GetLanguageCode(Val Language)
	
	If Language = Undefined Then
		Return "";
	Else
		Return Language.LanguageCode;
	EndIf;
	
EndFunction

// Processes error information received from the web service.
// If non-empty error information is passed, writes
// a detailed representation of the error to the log and raises
// an exception with the text of the error summary.
//
Procedure HandleWebServiceErrorInfo(Val ErrorInfo, Val OperationName)
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		
		Subsystem = Metadata.Subsystems.StandardSubsystems.Subsystems.SaaSOperations.Subsystems.UsersSaaS; // MetadataObjectSubsystem
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleSaaSOperations.HandleWebServiceErrorInfo(
			ErrorInfo,
			Subsystem.Name,
			"ManageApplication", // 
			OperationName);
		
	EndIf;
	
EndProcedure

// 
Function MessagesSupportedHasRightsToLogIn()
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesExchangeTransportSettings = Common.CommonModule(
		"InformationRegisters.MessageExchangeTransportSettings");
	
	SettingsStructure_ = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(
		ModuleSaaSOperations.ServiceManagerEndpoint());
	
	ConnectionParametersToSM = New Structure;
	ConnectionParametersToSM.Insert("URL", SettingsStructure_.WSWebServiceURL);
	ConnectionParametersToSM.Insert("UserName", SettingsStructure_.WSUserName);
	ConnectionParametersToSM.Insert("Password", SettingsStructure_.WSPassword);
	
	SupportedVersions = Common.GetInterfaceVersions(ConnectionParametersToSM, "UserHandler");
	If Not ValueIsFilled(SupportedVersions) Then
		Return False;
	EndIf;
	CurrentVersion = SupportedVersions[SupportedVersions.UBound()];
	
	Return CommonClientServer.CompareVersions(CurrentVersion, "1.0.0.2") >= 0
	
EndFunction

#EndRegion

#Region SharedIBUsersOperations

// Returns the full name of the service user to display in interfaces.
//
// Parameters:
//  Id - UUID
//                - CatalogRef.Users
//
// Returns:
//  String
//
Function InternalUserFullName(Val Id = Undefined) Export
	
	Result = "<" + NStr("en = 'Utility user ""%1""';") + ">";
	
	If ValueIsFilled(Id) Then
		
		If TypeOf(Id) = Type("CatalogRef.Users") Then
			Id = Common.ObjectAttributeValue(Id, "IBUserID");
		EndIf;
		
		SequenceNumber = Format(InformationRegisters.SharedUsers.IBUserSequenceNumber(Id), "NFD=0; NG=0");
		Result = StringFunctionsClientServer.SubstituteParametersToString(Result, SequenceNumber);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Checks whether the current is user is undivided.
//
// Returns:
//   Boolean
//
Function IsSharedIBUser()
	
	If IsBlankString(InfoBaseUsers.CurrentUser().Name) Then
		Return False;
	EndIf;
	
	If Not Common.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	If InfoBaseUsers.CurrentUser().DataSeparation.Count() > 0 Then
		Return False;
	EndIf;
		
	If Common.SeparatedDataUsageAvailable() Then
		UserIdentificator = InfoBaseUsers.CurrentUser().UUID;
		If Not UserRegisteredAsShared(UserIdentificator) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'User with ID %1 is not a shared user.';"),
				String(UserIdentificator));
			Raise ErrorText;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

// When working in the service model, it adds the current user to the list of undivided users,
// if they do not have the use of separators set.
//
Procedure RecordSharedUserInRegister()
	
	IBUserID = InfoBaseUsers.CurrentUser().UUID;
	
	RecordManager = InformationRegisters.SharedUsers.CreateRecordManager();
	RecordManager.IBUserID = IBUserID;
	RecordManager.Read();
	If Not RecordManager.Selected() Then
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.SharedUsers");
			Block.Lock();
			
			RecordManager.IBUserID = InfoBaseUsers.CurrentUser().UUID;
			RecordManager.SequenceNumber = InformationRegisters.SharedUsers.MaxSequenceNumber() + 1;
			RecordManager.UserName = InfoBaseUsers.CurrentUser().Name;
			RecordManager.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	ElsIf RecordManager.UserName <> InfoBaseUsers.CurrentUser().Name Then
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.SharedUsers");
			LockItem.SetValue("IBUserID", IBUserID);
			Block.Lock();
			
			RecordManager.UserName = InfoBaseUsers.CurrentUser().Name;
			RecordManager.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

Function SharedUserCannotBeWrittenExceptionText()
	
	Return NStr("en = 'It is prohibited to save shared users when the separator use is enabled.';");
	
EndFunction

#EndRegion

// Updates the IDS of is users in the user directory and clears the service user ID field.
//
// Parameters:
//  IDsMap - Map of KeyAndValue:
//    * Key - UUID - 
//    * Value - UUID - 
//
Procedure UpdateIBUsersIDs(Val IDsMap)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref,
	|	Users.IBUserID AS IBUserID,
	|	Users.IBUserID AS ServiceUserID
	|FROM
	|	Catalog.Users AS Users";
	BlankID = New UUID("00000000-0000-0000-0000-000000000000");
	Block = New DataLock;
	Block.Add("Catalog.Users");
	
	BeginTransaction();
	Try
		Block.Lock();
		Result = Query.Execute();
		Selection = Result.Select();
		While Selection.Next() Do
			NewInformationSecurityUserId = IDsMap[Selection.IBUserID];
			IDsMap.Delete(Selection.IBUserID);
			If Selection.IBUserID = BlankID
			   And Selection.ServiceUserID = BlankID
			   And Not ValueIsFilled(NewInformationSecurityUserId) Then
				Continue;
			EndIf;
			UserObject = Selection.Ref.GetObject();
			UserObject.ServiceUserID = Undefined;
			UserObject.IBUserID = NewInformationSecurityUserId;
			If UserObject.IsInternal Then
				IBUser = InfoBaseUsers.FindByUUID(
					UserObject.IBUserID);
				If IBUser <> Undefined
				   And IBUser.ShowInList Then
					IBUser.ShowInList = False;
					IBUser.Write();
				EndIf;
			EndIf;
			InfobaseUpdate.WriteData(UserObject);	
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion
