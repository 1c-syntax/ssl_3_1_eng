///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// See UsersInternal.AllRoles
Function AllRoles() Export
	
	Array = New Array;
	Map = New Map;
	
	Table = New ValueTable;
	Table.Columns.Add("Name", New TypeDescription("String", , New StringQualifiers(256)));
	
	For Each Role In Metadata.Roles Do
		NameOfRole = Role.Name;
		
		Array.Add(NameOfRole);
		Map.Insert(NameOfRole, Role.Synonym);
		Table.Add().Name = NameOfRole;
	EndDo;
	
	AllRoles = New Structure;
	AllRoles.Insert("Array",       New FixedArray(Array));
	AllRoles.Insert("Map", New FixedMap(Map));
	AllRoles.Insert("Table",      New ValueStorage(Table));
	
	Return Common.FixedData(AllRoles, False);
	
EndFunction

// Returns roles that are not available for the specified assignment (with or without the service model).
//
// Parameters:
//  Purpose - String -  "For Admins", "For Users", "For External Users",
//                        "For Joint Usersexternal Users".
//     
//  Service     - Undefined -  detect the current mode automatically.
//             - Boolean       - 
//                              
//
// Returns:
//  Map of KeyAndValue:
//   * Key     - String -  role name.
//   * Value - Boolean -  Truth.
//
Function UnavailableRoles(Purpose = "ForUsers", Service = Undefined) Export
	
	CheckAssignment(Purpose, StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Error in function ""%1"" of common module ""%2"".';"),
		"UnavailableRoles", "UsersInternalCached"));
	
	If Service = Undefined Then
		Service = Common.DataSeparationEnabled();
	EndIf;
	
	RolesAssignment = UsersInternalCached.RolesAssignment();
	UnavailableRoles = New Map;
	
	For Each Role In Metadata.Roles Do
		If (Purpose <> "ForAdministrators" Or Service)
		   And RolesAssignment.ForSystemAdministratorsOnly.Get(Role.Name) <> Undefined
		 // 
		 Or Purpose = "ForExternalUsers"
		   And RolesAssignment.ForExternalUsersOnly.Get(Role.Name) = Undefined
		   And RolesAssignment.BothForUsersAndExternalUsers.Get(Role.Name) = Undefined
		 // 
		 Or (Purpose = "ForUsers" Or Purpose = "ForAdministrators")
		   And RolesAssignment.ForExternalUsersOnly.Get(Role.Name) <> Undefined
		 // 
		 Or Purpose = "BothForUsersAndExternalUsers"
		   And Not RolesAssignment.BothForUsersAndExternalUsers.Get(Role.Name) <> Undefined
		 // 
		 Or Service
		   And RolesAssignment.ForSystemUsersOnly.Get(Role.Name) <> Undefined Then
			
			UnavailableRoles.Insert(Role.Name, True);
		EndIf;
	EndDo;
	
	Return New FixedMap(UnavailableRoles);
	
EndFunction

// 
// 
//
// Returns:
//  FixedStructure:
//   * ForSystemAdministratorsOnly - FixedMap of KeyAndValue:
//      ** Key     - String -  role name.
//      ** Value - Boolean -  Truth.
//   * ForSystemUsersOnly - FixedMap of KeyAndValue:
//      ** Key     - String -  role name.
//      ** Value - Boolean -  Truth.
//   * ForExternalUsersOnly - FixedMap of KeyAndValue:
//      ** Key     - String -  role name.
//      ** Value - Boolean -  Truth.
//   * BothForUsersAndExternalUsers - FixedMap of KeyAndValue:
//      ** Key     - String -  role name.
//      ** Value - Boolean -  Truth.
//
Function RolesAssignment() Export
	
	RolesAssignment = Users.RolesAssignment();
	
	Purpose = New Structure;
	For Each RolesAssignmentDetails In RolesAssignment Do
		Names = New Map;
		For Each Name In RolesAssignmentDetails.Value Do
			Role = Metadata.Roles.Find(Name);
			If Role = Undefined Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Procedure ""%2""''
					           |of common module ""%3""''
					           |contains a non-existent role ""%1"".';"),
					Name,
					"OnDefineRoleAssignment",
					"UsersOverridable");
				Raise ErrorText;
			EndIf;
			Names.Insert(Role.Name, True);
		EndDo;
		Purpose.Insert(RolesAssignmentDetails.Key, New FixedMap(Names));
	EndDo;
	
	Return New FixedStructure(Purpose);
	
EndFunction

// See UsersInternal.TableFields
Function TableFields(Val FullTableName) Export
	
	TableFields = UsersInternal.TableFields(FullTableName);
	If TableFields = Undefined Then
		Return Undefined;
	EndIf;
	
	Return Common.FixedData(TableFields);
	
EndFunction

// Returns:
//  Boolean
//
Function ShouldRegisterChangesInAccessRights() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.UserMonitoring") Then
		Return False;
	EndIf;
	
	ModuleUserMonitoringInternal = Common.CommonModule("UserMonitoringInternal");
	
	Return ModuleUserMonitoringInternal.ShouldRegisterChangesInAccessRights();
	
EndFunction

#EndRegion

#Region Private

// See Users.IsExternalUserSession.
Function IsExternalUserSession() Export
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionWithoutSeparators = ModuleSaaSOperations.SessionWithoutSeparators();
	Else
		SessionWithoutSeparators = True;
	EndIf;
	
	If Common.DataSeparationEnabled()
	   And SessionWithoutSeparators Then
		// 
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	
	IBUser = InfoBaseUsers.CurrentUser();
	IBUserID = IBUser.UUID;
	
	Users.FindAmbiguousIBUsers(Undefined, IBUserID);
	
	Query = New Query;
	Query.SetParameter("IBUserID", IBUserID);
	
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.IBUserID = &IBUserID";
	
	// 
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// 
// 
//
// Returns:
//  Structure:
//   * CommonAuthorizationSettings - Boolean -  if it is False,
//          then in the administration panel "rights and user Settings" the ability
//          to open the login settings form will be hidden, as well as the Expiration date field in
//          the user and external user cards.
//
//   * EditRoles - Boolean -  if False, then
//          the interface for changing roles in the user, external user, and
//          external user group cards will be hidden (including for the administrator).
//
//   * IndividualUsed - Boolean - 
//                                             
//
//   * IsDepartmentUsed  - Boolean - 
//                                             
//
Function Settings() Export
	
	Settings = New Structure;
	Settings.Insert("CommonAuthorizationSettings", True);
	Settings.Insert("EditRoles", True);
	Settings.Insert("IndividualUsed", True);
	Settings.Insert("IsDepartmentUsed", True);
	
	SSLSubsystemsIntegration.OnDefineSettings(Settings);
	UsersOverridable.OnDefineSettings(Settings);
	
	If Metadata.DefinedTypes.Department.Type.Types().Count() = 1
	   And Metadata.DefinedTypes.Department.Type.Types()[0] = Type("String") Then
		
		Settings.IsDepartmentUsed = False;
	EndIf;
	
	If Metadata.DefinedTypes.Individual.Type.Types().Count() = 1
	   And Metadata.DefinedTypes.Individual.Type.Types()[0] = Type("String") Then
		
		Settings.IndividualUsed = False;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		
		If Common.SubsystemExists("CloudTechnology.ServiceUsers") Then
			
			ServiceUsersModule = Common.CommonModule("ServiceUsers");
			
			Settings.Insert("CommonAuthorizationSettings",
				ServiceUsersModule.UseCommonSettingsOfServiceUserAuthorization());
			
		Else
			Settings.Insert("CommonAuthorizationSettings", False);
		EndIf;
	
	ElsIf StandardSubsystemsServer.IsBaseConfigurationVersion()
	      Or Common.IsStandaloneWorkplace() Then
		
		Settings.Insert("CommonAuthorizationSettings", False);
		
	EndIf;
	
	AllSettings = New Structure;
	AllSettings.Insert("CommonAuthorizationSettings",        Settings.CommonAuthorizationSettings);
	AllSettings.Insert("EditRoles",        Settings.EditRoles);
	AllSettings.Insert("IndividualUsed", Settings.IndividualUsed);
	AllSettings.Insert("IsDepartmentUsed",  Settings.IsDepartmentUsed);
	
	Return Common.FixedData(AllSettings);
	
EndFunction


// Returns:
//  Boolean - 
//  
//
Function ShowInList() Export
	
	If Common.DataSeparationEnabled()
	 Or ExternalUsers.UseExternalUsers() Then
		Return False;
	EndIf;
	
	If Not Users.CommonAuthorizationSettingsUsed() Then
		Return Undefined;
	EndIf;
	
	CommonSettingShowInList =
		UsersInternal.LogonSettings().Overall.ShowInList;
	
	If CommonSettingShowInList = "HiddenAndEnabledForAllUsers" Then
		Return True;
	EndIf;
	
	If CommonSettingShowInList = "HiddenAndDisabledForAllUsers" Then
		Return False;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns a tree of roles with or without subsystems.
// If the role does not belong to any subsystem, it is added "to the root".
// 
// Parameters:
//  BySubsystems - Boolean -  if False, all roles are added to the "root".
//  Purpose    - String -  "For Admins", "For Users", "For External Users",
//                           "For Joint Usersexternal Users".
// 
// Returns:
//  ValueTree:
//    * IsRole - Boolean
//    * Name     - String -  name of the role or subsystem.
//    * Synonym - String -  synonym for a role or subsystem.
//
Function RolesTree(BySubsystems = True, Purpose = "ForUsers") Export
	
	CheckAssignment(Purpose, StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Error in function ""%1"" of common module ""%2"".';"),
		"RolesTree", "UsersInternalCached"));
	
	UnavailableRoles = UsersInternalCached.UnavailableRoles(Purpose);
	
	Tree = New ValueTree;
	Tree.Columns.Add("IsRole", New TypeDescription("Boolean"));
	Tree.Columns.Add("Name",     New TypeDescription("String"));
	Tree.Columns.Add("Synonym", New TypeDescription("String", , New StringQualifiers(1000)));
	
	If BySubsystems Then
		FillSubsystemsAndRoles(Tree.Rows, Undefined, UnavailableRoles);
	EndIf;
	
	// 
	For Each Role In Metadata.Roles Do
		
		If UnavailableRoles.Get(Role.Name) <> Undefined
		 Or Upper(Left(Role.Name, StrLen("Delete"))) = Upper("Delete") Then
			
			Continue;
		EndIf;
		
		Filter = New Structure("IsRole, Name", True, Role.Name);
		If Tree.Rows.FindRows(Filter, True).Count() = 0 Then
			TreeRow = Tree.Rows.Add();
			TreeRow.IsRole       = True;
			TreeRow.Name           = Role.Name;
			TreeRow.Synonym       = ?(ValueIsFilled(Role.Synonym), Role.Synonym, Role.Name);
		EndIf;
	EndDo;
	
	Tree.Rows.Sort("IsRole Desc, Synonym Asc", True);
	
	Return New ValueStorage(Tree);
	
EndFunction

// See Users.CheckedIBUserProperties
Function CurrentIBUserProperties1() Export
	
	IBUser = InfoBaseUsers.CurrentUser();
	
	Properties = New Structure;
	Properties.Insert("IsCurrentIBUser", True);
	Properties.Insert("UUID", IBUser.UUID);
	Properties.Insert("Name",                     IBUser.Name);
	
	Properties.Insert("AdministrationRight", ?(PrivilegedMode(),
		AccessRight("Administration", Metadata, IBUser),
		AccessRight("Administration", Metadata)));
	
	// 
	
	//@skip-check using-isinrole
	Properties.Insert("SystemAdministratorRoleAvailable",
		IsInRole(Metadata.Roles.SystemAdministrator));
	
	//@skip-check using-isinrole
	Properties.Insert("RoleAvailableFullAccess",
		IsInRole(Metadata.Roles.FullAccess));
	
	// 
	
	Return New FixedStructure(Properties);
	
EndFunction

// Returns empty references to the types of authorization objects
// specified in the external User type being defined.
//
// If the defined type specifies a String type or
// other non-reference type, it is skipped.
//
// Returns:
//  FixedArray - :
//   * Value - AnyRef -  an empty link of the authorization object type.
//
Function BlankRefsOfAuthorizationObjectTypes() Export
	
	BlankRefs = New Array;
	
	For Each Type In Metadata.DefinedTypes.ExternalUser.Type.Types() Do
		If Not Common.IsReference(Type) Then
			Continue;
		EndIf;
		RefTypeDetails = New TypeDescription(CommonClientServer.ValueInArray(Type));
		BlankRefs.Add(RefTypeDetails.AdjustValue(Undefined));
	EndDo;
	
	Return New FixedArray(BlankRefs);
	
EndFunction

// See Catalogs.UserGroups.StandardUsersGroup
Function StandardUsersGroup(GroupName) Export
	
	Return Catalogs.UserGroups.StandardUsersGroup(GroupName);
	
EndFunction

// 
// 
//
// 
// 
//
// Returns:
//  FixedMap of KeyAndValue:
//   * Key - String - 
//   * Value -  FixedStructure:
//      ** AllowedTypes - TypeDescription
//      ** ParameterNameExtensionsOperation - String
// 
Function RefKindsProperties() Export
	
	RefsKinds = New ValueTable;
	RefsKinds.Columns.Add("Name", New TypeDescription("String"));
	RefsKinds.Columns.Add("ParameterNameExtensionsOperation", New TypeDescription("String"));
	RefsKinds.Columns.Add("AllowedTypes", New TypeDescription("TypeDescription"));
	
	UsersInternal.OnFillRegisteredRefKinds(RefsKinds);
	
	AllParametersNames = New Map;
	
	Result = New Map;
	For Each RefsKind In RefsKinds Do
		If Result.Get(RefsKind.Name) <> Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The reference kind name ""%1"" is already defined.';"), RefsKind.Name);
			Raise ErrorText;
		EndIf;
		If AllParametersNames.Get(RefsKind.ParameterNameExtensionsOperation) <> Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Extension parameter name in reference kind ""%1"" is already taken:
				           |""%2"".';"), RefsKind.Name, RefsKind.ParameterNameExtensionsOperation);
			Raise ErrorText;
		EndIf;
		Properties = New Structure;
		Properties.Insert("ParameterNameExtensionsOperation", RefsKind.ParameterNameExtensionsOperation);
		Properties.Insert("AllowedTypes",               RefsKind.AllowedTypes);
		Result.Insert(RefsKind.Name, New FixedStructure(Properties));
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

// Returns:
//  FixedMap of KeyAndValue:
//   * Key - String -  role name.
//   * Value - Boolean -  Truth.
//
Function ExtensionsRoles() Export
	
	Result = New Map;
	
	For Each Role In Metadata.Roles Do
		If Role.ConfigurationExtension() = Undefined Then
			Continue;
		EndIf;
		Result.Insert(Role.Name, True);
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Procedure FillSubsystemsAndRoles(TreeRowsCollection, Subsystems, UnavailableRoles, AllRoles = Undefined)
	
	If Subsystems = Undefined Then
		Subsystems = Metadata.Subsystems;
	EndIf;
	
	If AllRoles = Undefined Then
		AllRoles = New Map;
		For Each Role In Metadata.Roles Do
			
			If UnavailableRoles.Get(Role.Name) <> Undefined
			 Or Upper(Left(Role.Name, StrLen("Delete"))) = Upper("Delete") Then
			
				Continue;
			EndIf;
			AllRoles.Insert(Role, True);
		EndDo;
	EndIf;
	
	For Each Subsystem In Subsystems Do
		
		SubsystemDetails = TreeRowsCollection.Add();
		SubsystemDetails.Name     = Subsystem.Name;
		SubsystemDetails.Synonym = ?(ValueIsFilled(Subsystem.Synonym), Subsystem.Synonym, Subsystem.Name);
		
		FillSubsystemsAndRoles(SubsystemDetails.Rows, Subsystem.Subsystems, UnavailableRoles, AllRoles);
		
		For Each MetadataObject In Subsystem.Content Do
			If AllRoles[MetadataObject] = Undefined Then
				Continue;
			EndIf;
			Role = MetadataObject;
			RoleDetails = SubsystemDetails.Rows.Add();
			RoleDetails.IsRole = True;
			RoleDetails.Name     = Role.Name;
			RoleDetails.Synonym = ?(ValueIsFilled(Role.Synonym), Role.Synonym, Role.Name);
		EndDo;
		
		Filter = New Structure("IsRole", True);
		If SubsystemDetails.Rows.FindRows(Filter, True).Count() = 0 Then
			TreeRowsCollection.Delete(SubsystemDetails);
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckAssignment(Purpose, ErrorTitle)
	
	If Purpose <> "ForAdministrators"
	   And Purpose <> "ForUsers"
	   And Purpose <> "ForExternalUsers"
	   And Purpose <> "BothForUsersAndExternalUsers" Then
		
		ErrorText = ErrorTitle + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Parameter %1 ""%2"" has invalid value.
			           |
			           |Valid values are:
			           | - %3
			           | - %4
			           | - %5
			           | - %6';"),
			"Purpose",
			Purpose,
			"ForAdministrators",
			"ForUsers",
			"ForExternalUsers",
			"BothForUsersAndExternalUsers");
		Raise ErrorText;
	EndIf;
	
EndProcedure

#EndRegion
