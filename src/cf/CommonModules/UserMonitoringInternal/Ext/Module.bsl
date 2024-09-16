///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonOverridable.OnAddMetadataObjectsRenaming.
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Library = "StandardSubsystems";
	
	Common.AddRenaming(Total,
		"2.1.0.1",
		"Subsystem.StandardSubsystems.Subsystem.EventLogMonitor",
		"Subsystem.StandardSubsystems.Subsystem.EventLogAnalysis",
		Library);
	
	Common.AddRenaming(Total,
		"3.1.10.32",
		"Subsystem.StandardSubsystems.Subsystem.EventLogAnalysis",
		"Subsystem.StandardSubsystems.Subsystem.UserMonitoring",
		Library);
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.EventLogAnalysis);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.UserAccountsChanges);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.MembersChangeInUsersGroups);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.EditAccessGroupMembers);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.AccessGroupsAllowedValuesChange);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.ProfilesRolesChanges);
	
EndProcedure

// See ReportsOptionsOverridable.BeforeAddReportCommands.
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	Reports.EventLogAnalysis.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
	Reports.UserAccountsChanges.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
	Reports.MembersChangeInUsersGroups.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
	Reports.EditAccessGroupMembers.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
	Reports.AccessGroupsAllowedValuesChange.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
	Reports.ProfilesRolesChanges.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
	
EndProcedure

// See UsersOverridable.OnDefineRegistrationSettingsForDataAccessEvents
Procedure OnDefineRegistrationSettingsForDataAccessEvents(Settings) Export
	
	StoredSettings = StoredRegistrationSettings();
	If Not StoredSettings.Use Then
		Return;
	EndIf;
	
	For Each Setting In StoredSettings.Content Do
		Settings.Add(Setting);
	EndDo;
	
EndProcedure

// See SSLSubsystemsIntegration.OnFillToDoList.
Procedure OnFillToDoList(ToDoList) Export
	
	If Common.DataSeparationEnabled()
	 Or Not Users.IsFullUser(, True) Then
		Return;
	EndIf;
	
	AdministrationSection = Metadata.Subsystems.Find("Administration");
	If AdministrationSection = Undefined Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	StoredSettings = StoredRegistrationSettings();
	
	UnfoundFields = New Array;
	UsersInternal.DeleteNonExistentFieldsFromAccessAccessEventSetting(
		StoredSettings.Content, UnfoundFields);
	
	If Not ValueIsFilled(UnfoundFields) Then
		Return;
	EndIf;
	
	// 
	// 
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "KeepRegistrationSettingsForDataAccessEventsUpToDate";
	ToDoItem.HasToDoItems       = True;
	ToDoItem.Important         = True;
	ToDoItem.Count     = UnfoundFields.Count();
	ToDoItem.Presentation  = NStr("en = 'Update data access logging settings';");
	ToDoItem.ToolTip      = NStr("en = 'Access control is disabled for outdated settings.';");
	ToDoItem.Form          = "CommonForm.RegistrationSettingsForDataAccessEvents";
	ToDoItem.Owner       = AdministrationSection;
	
EndProcedure

// Parameters:
//  ErrorText - String - 
//
Procedure OnWriteErrorUpdatingRegistrationSettingsForDataAccessEvents(ErrorText) Export
	
	SetPrivilegedMode(True);
	StoredSettings = StoredRegistrationSettings();
	
	If Not StoredSettings.Use Then
		Return;
	EndIf;
	
	UnfoundFields = New Array;
	UsersInternal.DeleteNonExistentFieldsFromAccessAccessEventSetting(
		StoredSettings.Content, UnfoundFields);
	
	If Not ValueIsFilled(UnfoundFields) Then
		Return;
	EndIf;
	
	ErrorText = ErrorText + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'You are recommended to adjust the form settings by the link:
		           |%1';", Common.DefaultLanguageCode()),
		"e1cib/app/CommonForm.RegistrationSettingsForDataAccessEvents");
	
EndProcedure

// Returns:
//  Boolean
//
Function ShouldRegisterDataAccess() Export
	
	SetPrivilegedMode(True);
	
	Return StoredRegistrationSettings().Use;
	
EndFunction

// Parameters:
//  ShouldRegisterDataAccess - Boolean
//
Procedure SetDataAccessRegistration(ShouldRegisterDataAccess) Export
	
	Block = New DataLock;
	Block.Add("Constant.RegistrationSettingsForDataAccessEvents");
	
	BeginTransaction();
	Try
		Block.Lock();
		CurrentSettings = StoredRegistrationSettings();
		CurrentSettings.Use = ShouldRegisterDataAccess;
		Store = New ValueStorage(CurrentSettings);
		Constants.RegistrationSettingsForDataAccessEvents.Set(Store);
		Users.UpdateRegistrationSettingsForDataAccessEvents();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns:
//  Boolean
//
Function ShouldRegisterChangesInAccessRights() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Result = Constants.ShouldRegisterChangesInAccessRights.Get();
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// See UserMonitoring.RegistrationSettingsForDataAccessEvents
Function RegistrationSettingsForDataAccessEvents() Export
	
	Result = New Structure;
	Result.Insert("Content", New Array);
	Result.Insert("Comments", New Map);
	Result.Insert("GeneralComment", "");
	
	FillPropertyValues(Result, StoredRegistrationSettings());
	
	Return Result;
	
EndFunction

// See UserMonitoring.SetRegistrationSettingsForDataAccessEvents
Procedure SetRegistrationSettingsForDataAccessEvents(Settings) Export
	
	Block = New DataLock;
	Block.Add("Constant.RegistrationSettingsForDataAccessEvents");
	
	BeginTransaction();
	Try
		Block.Lock();
		CurrentSettings = StoredRegistrationSettings();
		CurrentSettings.Content           = Settings.Content;
		CurrentSettings.Comments      = Settings.Comments;
		CurrentSettings.GeneralComment = Settings.GeneralComment;
		Store = New ValueStorage(CurrentSettings);
		Constants.RegistrationSettingsForDataAccessEvents.Set(Store);
		Users.UpdateRegistrationSettingsForDataAccessEvents();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function EventNameDataAccessAuditingEventRegistrationSettingsChange() Export
	
	Return NStr("en = 'Data access audit.Change event logging settings';",
		Common.DefaultLanguageCode());
	
EndFunction

// Parameters:
//  Store - Undefined - 
//            - ValueStorage - 
//
// Returns:
//  Structure:
//    * Use - Boolean
//    * Content - Array of EventLogAccessEventUseDescription
//    * Comments - Map of KeyAndValue:
//        * Key     - String - 
//        * Value - String - 
//    * GeneralComment - String - 
//
Function StoredRegistrationSettings(Store = Undefined) Export
	
	Result = New Structure;
	Result.Insert("Use", False);
	Result.Insert("Content", New Array);
	Result.Insert("Comments", New Map);
	Result.Insert("GeneralComment", "");
	
	If Store = Undefined Then
		Store = Constants.RegistrationSettingsForDataAccessEvents.Get();
	EndIf;
	If TypeOf(Store) <> Type("ValueStorage") Then
		Return Result;
	EndIf;
	
	Value = Store.Get();
	If TypeOf(Value) <> Type("Structure") Then
		Return Result;
	EndIf;
	
	For Each KeyAndValue In Result Do
		If Not Value.Property(KeyAndValue.Key)
		 Or TypeOf(Value[KeyAndValue.Key]) <> TypeOf(KeyAndValue.Value) Then
			Continue;
		EndIf;
		If KeyAndValue.Key = "Content" Then
			For Each Setting In Value.Content Do
				If TypeOf(Setting) = Type("EventLogAccessEventUseDescription") Then
					Result.Content.Add(Setting);
				EndIf;
			EndDo;
		Else
			Result[KeyAndValue.Key] = Value[KeyAndValue.Key];
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// 
//
Function ConnectionColumnName() Export
	Return "Connection";
EndFunction

#EndRegion
