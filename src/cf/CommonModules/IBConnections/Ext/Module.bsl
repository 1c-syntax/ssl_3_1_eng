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

// Sets blocking of is connections.
// If called from a session with set delimiter values,
// it sets the data area session lock.
//
// Parameters:
//  MessageText           - String -  text that will be part of the error message
//                                      when trying to establish a connection to a blocked
//                                      database.
// 
//  KeyCode            - String -  a string that must be added to
//                                      the command line parameter "/uc" or to
//                                      the connection string parameter "uc" in order to establish a connection to
//                                      the information base despite the lock.
//                                      Not applicable for blocking data area sessions.
//  WaitingForTheStartOfBlocking - Number -    the time to delay the start of blocking in minutes.
//  LockDuration   - Number -    the duration of the block in minutes.
//
// Returns:
//   Boolean   - 
//              
//
Function SetConnectionLock(Val MessageText = "", Val KeyCode = "KeyCode", // 
	Val WaitingForTheStartOfBlocking = 0, Val LockDuration = 0) Export
	
	If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
		
		If Not Users.IsFullUser() Then
			Return False;
		EndIf;
		
		Block = NewConnectionLockParameters();
		Block.Use = True;
		Block.Begin = CurrentSessionDate() + WaitingForTheStartOfBlocking * 60;
		Block.Message = GenerateLockMessage(MessageText, KeyCode);
		Block.Exclusive = Users.IsFullUser(, True);
		
		If LockDuration > 0 Then 
			Block.End = Block.Begin + LockDuration * 60;
		EndIf;
		
		SetDataAreaSessionLock(Block);
		
		Return True;
	Else
		If Not Users.IsFullUser(, True) Then
			Return False;
		EndIf;
		
		Block = New SessionsLock;
		Block.Use = True;
		Block.Begin = CurrentSessionDate() + WaitingForTheStartOfBlocking * 60;
		Block.KeyCode = KeyCode;
		Block.Parameter = ServerNotifications.SessionKey();
		Block.Message = GenerateLockMessage(MessageText, KeyCode);
		
		If LockDuration > 0 Then 
			Block.End = Block.Begin + LockDuration * 60;
		EndIf;
		
		SetSessionsLock(Block);
	
		SetPrivilegedMode(True);
		SendServerNotificationAboutLockSet();
		SetPrivilegedMode(False);
		
		Return True;
	EndIf;
	
EndFunction

// Determine whether connection blocking is set during a batch 
// update of the database configuration.
//
// Returns:
//    Boolean - 
//
Function ConnectionsLocked() Export
	
	LockParameters = CurrentConnectionLockParameters();
	Return LockParameters.ConnectionsLocked;
	
EndFunction

// Get parameters for blocking is connections for use on the client side.
//
// Parameters:
//    GetSessionCount - Boolean -  if True,
//                                         the number of Sessions field is filled in in the returned structure.
//
// Returns:
//   Structure:
//     * Use       - Boolean -  True if the lock is set, False otherwise. 
//     * Begin            - Date   -  date when the block started. 
//     * End             - Date   -  the end date of the block. 
//     * Message         - String -  user message. 
//     * SessionTerminationTimeout - Number -  the interval, in seconds.
//     * SessionCount - Number  -  0, if the parameter getcounter of Sessions = False.
//     * CurrentSessionDate - Date   -  the current date of the session.
//
Function SessionLockParameters(Val GetSessionCount = False) Export
	
	LockParameters = CurrentConnectionLockParameters();
	Return AdvancedSessionLockParameters(GetSessionCount, LockParameters);
	
EndFunction

// Remove the information database lock.
//
// Returns:
//   Boolean   - 
//              
//
Function AllowUserAuthorization() Export
	
	If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
		
		If Not Users.IsFullUser() Then
			Return False;
		EndIf;
		
		LockParameters = GetDataAreaSessionLock();
		If LockParameters.Use Then
			LockParameters.Use = False;
			SetDataAreaSessionLock(LockParameters);
		EndIf;
		Return True;
		
	EndIf;
	
	If Not Users.IsFullUser(, True) Then
		Return False;
	EndIf;
	
	LockParameters = GetSessionsLock();
	If LockParameters.Use Then
		LockParameters.Use = False;
		
		SetSessionsLock(LockParameters);
		
		SetPrivilegedMode(True);
		SendServerNotificationAboutLockSet();
		SetPrivilegedMode(False);
	EndIf;
	
	Return True;
	
EndFunction

// Returns information about current connections to the database.
// If necessary, writes the message to the log.
//
// Parameters:
//    GetConnectionString - Boolean -  indicates whether to add a connection string to the return value.
//    MessagesForEventLog - ValueList -  if the parameter is not empty, events
//                                                      from the list will be recorded in the log.
//    ClusterPort - Number -  a non-standard port of a server cluster.
//
// Returns:
//    Structure:
//        * HasActiveConnections - Boolean -  indicates whether there are active connections.
//        * HasCOMConnections - Boolean -  indicates whether com connections are available.
//        * HasDesignerConnection - Boolean -  indicates whether the Configurator is connected.
//        * HasActiveUsers - Boolean -  indicates whether there are active users.
//        * InfoBaseConnectionString - String -  information database connection string. The property will
//                                                            only be used if the get connection String parameter was
//                                                            set to True.
//
Function ConnectionsInformation(GetConnectionString = False,
	MessagesForEventLog = Undefined, ClusterPort = 0) Export
	
	SetPrivilegedMode(True);
	
	Result = New Structure();
	Result.Insert("HasActiveConnections", False);
	Result.Insert("HasCOMConnections", False);
	Result.Insert("HasDesignerConnection", False);
	Result.Insert("HasActiveUsers", False);
	
	If InfoBaseUsers.GetUsers().Count() > 0 Then
		Result.HasActiveUsers = True;
	EndIf;
	
	If GetConnectionString Then
		Result.Insert("InfoBaseConnectionString", InfoBaseConnectionString());
	EndIf;
		
	EventLog.WriteEventsToEventLog(MessagesForEventLog);
	
	SessionsArray = GetInfoBaseSessions();
	If SessionsArray.Count() = 1 Then
		Return Result;
	EndIf;
	
	Result.HasActiveConnections = True;
	
	For Each Session In SessionsArray Do
		If Upper(Session.ApplicationName) = Upper("COMConnection") Then // 
			Result.HasCOMConnections = True;
		ElsIf Upper(Session.ApplicationName) = Upper("Designer") Then // Designer1
			Result.HasDesignerConnection = True;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Get an empty structure with data area session blocking parameters.
// 
// Returns:
//   Structure:
//     * Begin         - Date   -  the start time of the lock.
//     * End          - Date   -  the time when the lock action was completed.
//     * Message      - String -  messages for users logging in to a locked data area.
//     * Use    - Boolean -  indicates that the lock is set.
//     * Exclusive   - Boolean -  the lock cannot be changed by the application administrator.
//
Function NewConnectionLockParameters() Export
	
	Result = New Structure;
	Result.Insert("End", Date(1,1,1));
	Result.Insert("Begin", Date(1,1,1));
	Result.Insert("Message", "");
	Result.Insert("Use", False);
	Result.Insert("Exclusive", False);
	
	Return Result;
	
EndFunction

// To set the blocking sessions pane data.
// 
// Parameters:
//   Parameters         - See NewConnectionLockParameters
//   LocalTime - Boolean -  the lock start and end times are specified in the local session time.
//                                If False, then in universal time.
//   DataArea - Number -  the number of the data area for which the lock is placed.
//     When calling from a session where delimiter values are set, only the value
//       that matches the value of the delimiter in the session can be passed (or omitted).
//     When called from a session in which you do not set values for delimiters, the value of the parameter cannot be omitted.
//
Procedure SetDataAreaSessionLock(Val Parameters, Val LocalTime = True, Val DataArea = -1) Export
	
	If Not Users.IsFullUser() Then
		Raise(NStr("en = 'Insufficient rights to perform the operation.';"), ErrorCategory.AccessViolation);
	EndIf;
	
	// 
	ConnectionsLockParameters = NewConnectionLockParameters();
	FillPropertyValues(ConnectionsLockParameters, Parameters); 
	Parameters = ConnectionsLockParameters;
	 
	If Parameters.Exclusive And Not Users.IsFullUser(, True) Then
		Raise(NStr("en = 'Not enough rights to perform the operation.';"), ErrorCategory.AccessViolation);
	EndIf;
	
	If Common.SeparatedDataUsageAvailable() Then
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionSeparatorValue = ModuleSaaSOperations.SessionSeparatorValue();
		
		If DataArea = -1 Then
			DataArea = SessionSeparatorValue;
		ElsIf DataArea <> SessionSeparatorValue Then
			Raise NStr("en = 'Cannot set a session lock for a data area that is different from the session data area because the session uses separator values.';");
		EndIf;
		
	ElsIf DataArea = -1 Then
		Raise NStr("en = 'Cannot lock data area sessions because the data area is not specified.';");
	EndIf;
	
	SetPrivilegedMode(True);
	BeginTransaction();
	Try
		
		DataLock = New DataLock;
		LockItem = DataLock.Add("InformationRegister.DataAreaSessionLocks");
		LockItem.SetValue("DataAreaAuxiliaryData", DataArea);
		DataLock.Lock();
		
		LockSet1 = InformationRegisters.DataAreaSessionLocks.CreateRecordSet();
		LockSet1.Filter.DataAreaAuxiliaryData.Set(DataArea);
		LockSet1.Read();
		LockSet1.Clear();
		If Parameters.Use Then 
			Block = LockSet1.Add();
			Block.DataAreaAuxiliaryData = DataArea;
			Block.LockStart = ?(LocalTime And ValueIsFilled(Parameters.Begin), 
				ToUniversalTime(Parameters.Begin), Parameters.Begin);
			Block.LockEnd = ?(LocalTime And ValueIsFilled(Parameters.End), 
				ToUniversalTime(Parameters.End), Parameters.End);
			Block.LockMessage = Parameters.Message;
			Block.Exclusive = Parameters.Exclusive;
		EndIf;
		LockSet1.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SendServerNotificationAboutLockSet();
	
EndProcedure

// Get information about blocking sessions in the data area.
// 
// Parameters:
//   LocalTime - Boolean -  the start and end time of the lock must be returned 
//                                in the local session time. If False, 
//                                it is returned in universal time.
//
// Returns:
//   See NewConnectionLockParameters.
//
Function GetDataAreaSessionLock(Val LocalTime = True) Export
	
	Result = NewConnectionLockParameters();
	If Not Common.DataSeparationEnabled() Or Not Common.SeparatedDataUsageAvailable() Then
		Return Result;
	EndIf;
	
	If Not Users.IsFullUser() Then
		Raise(NStr("en = 'Not enough rights to perform the operation.';"), ErrorCategory.AccessViolation);
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	LockSet1 = InformationRegisters.DataAreaSessionLocks.CreateRecordSet();
	LockSet1.Filter.DataAreaAuxiliaryData.Set(
		ModuleSaaSOperations.SessionSeparatorValue());
	LockSet1.Read();
	If LockSet1.Count() = 0 Then
		Return Result;
	EndIf;
	Block = LockSet1[0];
	Result.Begin = ?(LocalTime And ValueIsFilled(Block.LockStart), 
		ToLocalTime(Block.LockStart), Block.LockStart);
	Result.End = ?(LocalTime And ValueIsFilled(Block.LockEnd), 
		ToLocalTime(Block.LockEnd), Block.LockEnd);
	Result.Message = Block.LockMessage;
	Result.Exclusive = Block.Exclusive;
	Result.Use = True;
	If ValueIsFilled(Block.LockEnd) And CurrentSessionDate() > Block.LockEnd Then
		Result.Use = False;
	EndIf;
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

Function IsSubsystemUsed() Export
	
	//  
	Return Not Common.DataSeparationEnabled();
	
EndFunction

// Returns a text string with a list of active is connections.
// Connection names are separated by a line break.
//
// Parameters:
//  Message-String - the string to be passed.
//
// Returns:
//   String - 
//
Function ActiveSessionsMessage() Export
	
	Message = NStr("en = 'Cannot close sessions:';");
	CurrentSessionNumber = InfoBaseSessionNumber();
	For Each Session In GetInfoBaseSessions() Do
		If Session.SessionNumber <> CurrentSessionNumber Then
			Message = Message + Chars.LF + "• " + Session;
		EndIf;
	EndDo;
	
	Return Message;
	
EndFunction

// Get the number of active is sessions.
//
// Parameters:
//   IncludeConsole - Boolean -  if False, then exclude the console session of a server cluster.
//                               Server cluster console sessions do not prevent you from performing 
//                               administrative operations (setting exclusive mode, etc.).
//
// Returns:
//   Number - 
//
Function InfobaseSessionsCount(IncludeConsole = True, IncludeBackgroundJobs = True) Export
	
	IBSessions = GetInfoBaseSessions();
	If IncludeConsole And IncludeBackgroundJobs Then
		Return IBSessions.Count();
	EndIf;
	
	Result = 0;
	
	For Each IBSession In IBSessions Do
		
		If Not IncludeConsole And IBSession.ApplicationName = "SrvrConsole"
			Or Not IncludeBackgroundJobs And IBSession.ApplicationName = "BackgroundJob" Then
			Continue;
		EndIf;
		
		Result = Result + 1;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Determines the number of sessions in the database and whether there are sessions
// that cannot be forcibly disabled. Generates
// the error message text.
//
Function BlockingSessionsInformation(MessageText = "") Export
	
	BlockingSessionsInformation = New Structure;
	
	CurrentSessionNumber = InfoBaseSessionNumber();
	InfobaseSessions = GetInfoBaseSessions();
	
	HasBlockingSessions = False;
	If Common.FileInfobase() Then
		ActiveSessionNames = "";
		For Each Session In InfobaseSessions Do
			If Session.SessionNumber <> CurrentSessionNumber
				And Session.ApplicationName <> "1CV8"
				And Session.ApplicationName <> "1CV8C"
				And Session.ApplicationName <> "WebClient" Then
				ActiveSessionNames = ActiveSessionNames + Chars.LF + "• " + Session;
				HasBlockingSessions = True;
			EndIf;
		EndDo;
	EndIf;
	
	BlockingSessionsInformation.Insert("HasBlockingSessions", HasBlockingSessions);
	BlockingSessionsInformation.Insert("SessionCount", InfobaseSessions.Count());
	
	If HasBlockingSessions Then
		Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'There are active sessions that cannot be closed:
			|%1
			|%2';"),
			ActiveSessionNames, MessageText);
		BlockingSessionsInformation.Insert("MessageText", Message);
		
	EndIf;
	
	Return BlockingSessionsInformation;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// See SaaSOperationsOverridable.OnFillIIBParametersTable.
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleSaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "LockMessageOnConfigurationUpdate");
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	LockParameters = CurrentConnectionLockParameters();
	Parameters.Insert("SessionLockParameters", New FixedStructure(AdvancedSessionLockParameters(False, LockParameters)));
	
	If Not LockParameters.ConnectionsLocked
		Or Not Common.DataSeparationEnabled()
		Or Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	// 
	If InfobaseUpdate.InfobaseUpdateInProgress() 
		And Users.IsFullUser() Then
		// 
		// 
		Return; 
	EndIf;
	
	CurrentMode = LockParameters.CurrentDataAreaMode;
	
	If ValueIsFilled(CurrentMode.End) Then
		If ValueIsFilled(CurrentMode.Message) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The application administrator locked the application for the period from %1 to %2. Reason:
					|%3.';"), CurrentMode.Begin, CurrentMode.End, CurrentMode.Message);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The application administrator locked the application for the period from %1 to %2 for scheduled maintenance.';"), 
				CurrentMode.Begin, CurrentMode.End);
		EndIf;		
	Else
		If ValueIsFilled(CurrentMode.Message) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The application administrator locked the application at %1. Reason:
					|%2.';"), CurrentMode.Begin, CurrentMode.Message);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The application administrator locked the application at %1 due for scheduled maintenance.';"), 
				CurrentMode.Begin);
		EndIf;		
	EndIf;
	Parameters.Insert("DataAreaSessionsLocked", MessageText + Chars.LF + Chars.LF + NStr("en = 'The application is temporarily unavailable.';"));
	LogonMessageText = "";
	If Users.IsFullUser() Then
		LogonMessageText = MessageText + Chars.LF + Chars.LF + NStr("en = 'Do you want to log in to the locked application?';");
	EndIf;
	Parameters.Insert("PromptToAuthorize", LogonMessageText);
	If (Users.IsFullUser() And Not CurrentMode.Exclusive) 
		Or Users.IsFullUser(, True) Then
		
		Parameters.Insert("CanUnlock", True);
	Else
		Parameters.Insert("CanUnlock", False);
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	Parameters.Insert("SessionLockParameters", New FixedStructure(SessionLockParameters()));
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.DataAreaSessionLocks);
	
EndProcedure

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("DataAdministration", Metadata)
		Or ModuleToDoListServer.UserTaskDisabled("SessionsLock") Then
		Return;
	EndIf;
	
	// 
	// 
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.DataProcessors.ApplicationLock.FullName());
	
	LockParameters = SessionLockParameters(False);
	CurrentSessionDate = CurrentSessionDate();
	
	If LockParameters.Use Then
		If CurrentSessionDate < LockParameters.Begin Then
			If LockParameters.End <> Date(1, 1, 1) Then
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Scheduled from %1 to %2';"),
					Format(LockParameters.Begin, "DLF=DT"), Format(LockParameters.End, "DLF=DT"));
			Else
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Scheduled from %1';"), Format(LockParameters.Begin, "DLF=DT"));
			EndIf;
			Importance = False;
		ElsIf LockParameters.End <> Date(1, 1, 1) And CurrentSessionDate > LockParameters.End And LockParameters.Begin <> Date(1, 1, 1) Then
			Importance = False;
			Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Inactive (expired on %1)';"), Format(LockParameters.End, "DLF=DT"));
		Else
			If LockParameters.End <> Date(1, 1, 1) Then
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'from %1 to %2';"),
					Format(LockParameters.Begin, "DLF=DT"), Format(LockParameters.End, "DLF=DT"));
			Else
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'from %1';"), 
					Format(LockParameters.Begin, "DLF=DT"));
			EndIf;
			Importance = True;
		EndIf;
	Else
		Message = NStr("en = 'Inactive';");
		Importance = False;
	EndIf;

	
	For Each Section In Sections Do
		
		ToDoItemID = "SessionsLock" + StrReplace(Section.FullName(), ".", "");
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = ToDoItemID;
		ToDoItem.HasToDoItems       = LockParameters.Use;
		ToDoItem.Presentation  = NStr("en = 'Deny user access';");
		ToDoItem.Form          = "DataProcessor.ApplicationLock.Form";
		ToDoItem.Important         = Importance;
		ToDoItem.Owner       = Section;
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "SessionLockDetails";
		ToDoItem.HasToDoItems       = LockParameters.Use;
		ToDoItem.Presentation  = Message;
		ToDoItem.Owner       = ToDoItemID; 
		
	EndDo;
	
EndProcedure

// See CommonOverridable.OnAddServerNotifications
Procedure OnAddServerNotifications(Notifications) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	Notification = ServerNotifications.NewServerNotification(
		"StandardSubsystems.UsersSessions.SessionsLock");
	Notification.NotificationSendModuleName  = "IBConnections";
	Notification.NotificationReceiptModuleName = "IBConnectionsClient";
	Notification.VerificationPeriod = 300;
	
	Notifications.Insert(Notification.Name, Notification);
	
EndProcedure

// See StandardSubsystemsServer.OnSendServerNotification
Procedure OnSendServerNotification(NameOfAlert, ParametersVariants) Export
	
	SendServerNotificationAboutLockSet(True);
	
EndProcedure

// See CommonOverridable.OnReceiptRecurringClientDataOnServer
Procedure OnReceiptRecurringClientDataOnServer(Parameters, Results) Export
	
	If Not IsSubsystemUsed() Then
		Return;
	EndIf;
	
	ParameterName = "StandardSubsystems.UsersSessions.SessionsLock";
	SessionLockParameters = SessionsLockSettingsWhenSet();
	
	If SessionLockParameters <> Undefined
	   And SessionLockParameters.Use Then
		
		Results.Insert(ParameterName, SessionLockParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SendServerNotificationAboutLockSet(OnSendServerNotification = False) Export
	
	Try
		SessionLockParameters = SessionsLockSettingsWhenSet();
		If SessionLockParameters = Undefined Then
			SessionLockParameters = New Structure("Use", False);
		EndIf;
		
		If SessionLockParameters.Use
		 Or Not OnSendServerNotification Then
			
			ServerNotifications.SendServerNotification(
				"StandardSubsystems.UsersSessions.SessionsLock",
				SessionLockParameters, Undefined, Not OnSendServerNotification);
		EndIf;
	Except
		If OnSendServerNotification Then
			Raise;
		EndIf;
		WriteLogEvent(EventLogEvent(),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Returns the text of the session lock message.
//
// Parameters:
//  Message - String -  message to block.
//  KeyCode - String -  permission code for entering the information database.
//
// Returns:
//   String - 
//
Function GenerateLockMessage(Val Message, Val KeyCode) Export
	
	AdministrationParameters = StandardSubsystemsServer.AdministrationParameters();
	FileModeFlag = False;
	IBPath = IBConnectionsClientServer.InfobasePath(FileModeFlag, AdministrationParameters.ClusterPort);
	InfobasePathString = ?(FileModeFlag = True, "/F", "/S") + IBPath;
	MessageText = "";
	If Not IsBlankString(Message) Then
		MessageText = Message + Chars.LF + Chars.LF;
	EndIf;
	
	ParameterName = "AllowUserAuthorization";
	If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
		MessageText = MessageText + NStr("en = '%1
			|To allow user access, you can open the application with parameter %2. For example:
			|http://<server web address>/?C=%2';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, 
			IBConnectionsClientServer.TextForAdministrator(), ParameterName);
	Else
		MessageText = MessageText + NStr("en = '%1
			|To allow user access, use the server cluster console or run 1C:Enterprise with the following parameters:
			|ENTERPRISE %2 /C%3 /UC%4';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, IBConnectionsClientServer.TextForAdministrator(),
			InfobasePathString, ParameterName, NStr("en = '<access code>';"));
	EndIf;
	
	Return MessageText;
	
EndFunction

// Returns whether connection blocking is set for a specific date.
//
// Parameters:
//  CurrentMode - SessionsLock -  blocking sessions.
//  CurrentDate - Date -  the date on which you want to test.
//
// Returns:
//  Boolean - 
//
Function ConnectionsLockedForDate(CurrentMode, CurrentDate)
	
	Return (CurrentMode.Use And CurrentMode.Begin <= CurrentDate 
		And (Not ValueIsFilled(CurrentMode.End) Or CurrentDate <= CurrentMode.End));
	
EndFunction

// See the description in the function parameterblocking Sessions.
//
// Parameters:
//    GetSessionCount - Boolean
//    LockParameters - See CurrentConnectionLockParameters
//
Function AdvancedSessionLockParameters(Val GetSessionCount, LockParameters)
	
	If LockParameters.IBConnectionLockSetForDate Then
		CurrentMode = LockParameters.CurrentIBMode;
	ElsIf LockParameters.DataAreaConnectionLockSetForDate Then
		CurrentMode = LockParameters.CurrentDataAreaMode;
	ElsIf LockParameters.CurrentIBMode.Use Then
		CurrentMode = LockParameters.CurrentIBMode;
	Else
		CurrentMode = LockParameters.CurrentDataAreaMode;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Result = New Structure;
	Result.Insert("Use", CurrentMode.Use);
	Result.Insert("Begin", CurrentMode.Begin);
	Result.Insert("End", CurrentMode.End);
	Result.Insert("Message", CurrentMode.Message);
	Result.Insert("SessionTerminationTimeout", 15 * 60);
	Result.Insert("SessionCount", ?(GetSessionCount, InfobaseSessionsCount(), 0));
	Result.Insert("CurrentSessionDate", LockParameters.CurrentDate);
	Result.Insert("RestartOnCompletion", True);
	
	IBConnectionsOverridable.OnDetermineSessionLockParameters(Result);
	
	Return Result;
	
EndFunction

// Parameters:
//   ShouldReturnUndefinedIfUnspecified - Boolean
// 
// Returns:
//   Structure:
//   * IBConnectionLockSetForDate - Boolean
//   * CurrentDataAreaMode - See NewConnectionLockParameters
//   * CurrentIBMode - SessionsLock
//   * CurrentDate - Date
//
Function CurrentConnectionLockParameters(ShouldReturnUndefinedIfUnspecified = False)
	
	CurrentDate = CurrentDate(); // 
	
	SetPrivilegedMode(True);
	CurrentIBMode = GetSessionsLock();
	If ShouldReturnUndefinedIfUnspecified
	   And Not CurrentIBMode.Use
	   And Not Common.DataSeparationEnabled() Then
		Return Undefined;
	EndIf;
	CurrentDataAreaMode = GetDataAreaSessionLock();
	SetPrivilegedMode(False);
	
	IBLockedForDate = ConnectionsLockedForDate(CurrentIBMode, CurrentDate);
	AreaLockedAtDate = ConnectionsLockedForDate(CurrentDataAreaMode, CurrentDate);
	ConnectionsLocked = IBLockedForDate Or AreaLockedAtDate;
	
	Parameters = New Structure;
	Parameters.Insert("CurrentDate", CurrentDate);
	Parameters.Insert("CurrentIBMode", CurrentIBMode);
	Parameters.Insert("CurrentDataAreaMode", CurrentDataAreaMode);
	Parameters.Insert("IBConnectionLockSetForDate", IBLockedForDate);
	Parameters.Insert("DataAreaConnectionLockSetForDate", AreaLockedAtDate);
	Parameters.Insert("ConnectionsLocked", ConnectionsLocked);
	
	Return Parameters;
	
EndFunction

// Returns:
//   See SessionLockParameters
//
Function SessionsLockSettingsWhenSet()
	
	LockParameters = CurrentConnectionLockParameters(True);
	If LockParameters = Undefined Then
		Return Undefined;
	EndIf;
	
	Result = AdvancedSessionLockParameters(False, LockParameters);
	If LockParameters.IBConnectionLockSetForDate Then
		Result.Insert("Parameter", LockParameters.CurrentIBMode.Parameter);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a string constant for generating log messages.
//
// Returns:
//   String - 
//
Function EventLogEvent() Export
	
	Return NStr("en = 'User sessions';", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion
