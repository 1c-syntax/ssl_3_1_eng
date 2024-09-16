///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ObsoleteProceduresAndFunctions

#Region ProgramInterfaceParameterConstructors

// Deprecated.
// 
// 
//
// Returns:
//  Structure:
//    * AttachmentType - String - :
//        
//        
//                
//    * ServerAgentAddress - String -  network address of the server agent (only for connection Type = " COM"),
//    * ServerAgentPort - Number -  network port of the server agent (only for connection Type = "COM"),
//      typical value-1540,
//    * AdministrationServerAddress - String -  network address of the ras administration server (only
//      for connection Type = " RAS"),
//    * AdministrationServerPort - Number -  network port of the ras administration server (only when
//      Connection type = "RAS"), typical value-1545,
//    * ClusterPort - Number -  network port of the managed cluster Manager, typical value -1541,
//    * ClusterAdministratorName - String -  name of the cluster administrator account (if
//      the list of administrators is not specified for the cluster, an empty string is used),
//    * ClusterAdministratorPassword - String -  password of the cluster administrator account (if
//      the list of administrators is not set for the cluster or the password is not set for the account
//      , an empty string is used).
//
Function ClusterAdministrationParameters() Export
	
	Result = New Structure();
	
	Result.Insert("AttachmentType", "COM"); // 
	
	// 
	Result.Insert("ServerAgentAddress", "");
	Result.Insert("ServerAgentPort", 1540);
	
	// 
	Result.Insert("AdministrationServerAddress", "");
	Result.Insert("AdministrationServerPort", 1545);
	
	Result.Insert("ClusterPort", 1541);
	Result.Insert("ClusterAdministratorName", "");
	Result.Insert("ClusterAdministratorPassword", "");
	
	Return Result;
	
EndFunction

// Deprecated.
// 
//  
//
// Returns: 
//  Structure:
//    * NameInCluster - String -  name of the managed database in the server cluster,
//    * InfobaseAdministratorName - String -  name of the information database user with
//      administrator rights (if the list of information security users is not specified for the information database
//      , an empty string is used),
//    * InfobaseAdministratorPassword - String -  password of an information database user
//      with administrator rights (if the list
//      of is users is not set for the information database or a password is not set for the is user, an empty string is used).
//
Function ClusterInfobaseAdministrationParameters() Export
	
	Result = New Structure();
	
	Result.Insert("NameInCluster", "");
	Result.Insert("InfobaseAdministratorName", "");
	Result.Insert("InfobaseAdministratorPassword", "");
	
	Return Result;
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//  CheckClusterAdministrationParameters - Boolean -  the flag you want to check the administrative settings of the cluster,
//  CheckInfobaseAdministrationParameters - Boolean -  the flag you want to check the settings
//                                                                   cluster administration.
//
Procedure CheckAdministrationParameters(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined,
	CheckClusterAdministrationParameters = True,
	CheckInfobaseAdministrationParameters = True) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	AdministrationManager.CheckAdministrationParameters(ClusterAdministrationParameters, IBAdministrationParameters, CheckInfobaseAdministrationParameters, CheckClusterAdministrationParameters);
	
EndProcedure

#EndRegion

#Region SessionAndScheduledJobLock

// Deprecated.
// 
//  
//
// Returns:
//  Structure:
//    * SessionsLock - Boolean -  flag for setting blocking of new sessions with the information base,
//    * DateFrom1 - Date - 
//    * DateTo - Date -  (Date and time) when new sessions with the database were blocked,
//    * Message - String -  message that is displayed to the user when trying to set up a new session
//      with the information database when new sessions are blocked,
//    * KeyCode - String -  code to bypass blocking new sessions with the information base,
//    * LockScheduledJobs - Boolean -  flag for blocking the execution of routine tasks
//      in the information database.
//
Function SessionAndScheduleJobLockProperties() Export
	
	Result = New Structure();
	
	Result.Insert("SessionsLock");
	Result.Insert("DateFrom1");
	Result.Insert("DateTo");
	Result.Insert("Message");
	Result.Insert("KeyCode");
	Result.Insert("LockParameter");
	Result.Insert("LockScheduledJobs");
	
	Return Result;
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//
// Returns: 
//    See ClusterAdministrationClientServer.SessionAndScheduleJobLockProperties.
//
Function InfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Result = AdministrationManager.InfobaseSessionAndJobLock(
		ClusterAdministrationParameters,
		IBAdministrationParameters);
	
	Return Result;
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//  SessionAndJobLockProperties - See ClusterAdministrationClientServer.SessionAndScheduleJobLockProperties.
//
Procedure SetInfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val SessionAndJobLockProperties) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetInfobaseSessionAndJobLock(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		SessionAndJobLockProperties);
	
EndProcedure

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//
Procedure RemoveInfobaseSessionAndJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	LockProperties = SessionAndScheduleJobLockProperties();
	LockProperties.SessionsLock = False;
	LockProperties.DateFrom1 = Undefined;
	LockProperties.DateTo = Undefined;
	LockProperties.Message = "";
	LockProperties.KeyCode = "";
	LockProperties.LockScheduledJobs = False;
	
	SetInfobaseSessionAndJobLock(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		LockProperties);
	
EndProcedure

#EndRegion

#Region LockScheduledJobs

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//
// Returns:
//    Boolean - 
//
Function InfobaseScheduledJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Result = AdministrationManager.InfobaseScheduledJobLock(
		ClusterAdministrationParameters,
		IBAdministrationParameters);
	
	Return Result;
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters
//  LockScheduledJobs - Boolean -  flag for setting blocking of scheduled tasks in the information database.
//
Procedure SetInfobaseScheduledJobLock(Val ClusterAdministrationParameters, Val IBAdministrationParameters, Val LockScheduledJobs) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetInfobaseScheduledJobLock(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		LockScheduledJobs);
	
EndProcedure

#EndRegion

#Region InfobaseSessions

// Deprecated.
// 
//
// Returns: 
//  Structure:
//   * Number - Number -  session number. Unique among all sessions of the information database,
//   * UserName - String -  name of the authenticated user of the information database,
//   * ClientComputerName - String -  name or network address of the computer that established
//     the session with the database,
//   * ClientApplicationID - String - 
//     
//   * LanguageID - String -  ID of the interface language,
//   * SessionCreationTime - Date -  (Date and time) when the session was set up,
//   * LatestSessionActivityTime - Date -  (Date and time) when the session was last active,
//   * Block - Number -  the session number that is the reason for waiting for a managed transactional
//     lock, if the session is installing managed transactional locks
//     and is waiting for the locks set by another session to be released (otherwise, the value is 0),
//   * DBMSLock - Number -  the session number that is the reason for waiting for a transactional
//     lock, if the session executes a request to the DBMS and waits for a transactional
//     lock set by another session (otherwise, the value is 0),
//   * Passed - Number -  the amount of data transmitted to honey by the 1C server:The enterprise and client application
//     of this session since the start of the session (in bytes),
//   * PassedIn5Minutes - Number -  amount of data transferred between the 1C server:Enterprise and client
//     application of this session for the last 5 minutes (in bytes),
//   * ServerCalls - Number -  number of calls to the 1C server:Businesses from the start of this session to
//     the start of the session,
//   * ServerCallsIn5Minutes - Number -  number of calls to the 1C server:Businesses on behalf of this session
//     in the last 5 minutes,
//   * ServerCallDurations - Number -  execution time of calls to the server 1S:Businesses on behalf
//     of this session since the session started (in seconds),
//   * CurrentServerCallDuration - Number -  the time interval in milliseconds that has elapsed since the start
//     of the request, if the session is calling the 1C server:Businesses (otherwise, the value is 0),
//   * ServerCallDurationsIn5Minutes - Number -  execution time of calls to the server 1S:Businesses on behalf
//     of this session for the last 5 minutes (in milliseconds),
//   * ExchangedWithDBMS - Number -  the number of data sent and received from the DBMS on behalf of this session
//     since the session started (in bytes),
//   * ExchangedWithDBMSIn5Minutes - Number -  the number of data sent and received from the DBMS on behalf of this session
//     in the last 5 minutes (in bytes),
//   * DBMSCallDuration - Number -  execution time of DBMS queries on behalf of this session since
//     the session started (in milliseconds),
//   * CurrentDBMSCallDuration - Number -  the time interval in milliseconds that has elapsed since the start
//     of query execution if the session executes a query to the DBMS (otherwise, the value is 0),
//   * DBMSCallDurationsIn5Minutes - Number -  total execution time of DBMS queries on behalf of this session
//     for the last 5 minutes (in milliseconds),
//   * DBMSConnection - String -  DBMS connection number in DBMS terms if a
//     query to the DBMS is being made, a transaction is open, or temporary tables are defined (i.e.
//     , a connection to the DBMS is captured). If the DBMS connection is not captured , the value is equal to an empty string,
//   * DBMSConnectionTime - Number -  the connection to the DBMS from the moment of capture (in milliseconds). If the connection with
//     DBMS is not captured, the value is 0,
//   * DBMSConnectionSeizeTime - Date -  (Date and time) the time when the DBMS connection was last
//     captured by another session.
//
Function SessionProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Number");
	Result.Insert("UserName");
	Result.Insert("ClientComputerName");
	Result.Insert("ClientApplicationID");
	Result.Insert("LanguageID");
	Result.Insert("SessionCreationTime");
	Result.Insert("LatestSessionActivityTime");
	Result.Insert("Block");
	Result.Insert("DBMSLock");
	Result.Insert("Passed");
	Result.Insert("PassedIn5Minutes");
	Result.Insert("ServerCalls");
	Result.Insert("ServerCallsIn5Minutes");
	Result.Insert("ServerCallDurations");
	Result.Insert("CurrentServerCallDuration");
	Result.Insert("ServerCallDurationsIn5Minutes");
	Result.Insert("ExchangedWithDBMS");
	Result.Insert("ExchangedWithDBMSIn5Minutes");
	Result.Insert("DBMSCallDuration");
	Result.Insert("CurrentDBMSCallDuration");
	Result.Insert("DBMSCallDurationsIn5Minutes");
	Result.Insert("DBMSConnection");
	Result.Insert("DBMSConnectionTime");
	Result.Insert("DBMSConnectionSeizeTime");
	
	Return Result;
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//  Filter - Array of Structure:
//             * Property - See ClusterAdministrationClientServer.SessionProperties
//             * ComparisonType - ComparisonType -  value of the system enumeration of the comparison View,
//             * Value - Number
//                        - String
//                        - Date
//                        - Boolean
//                        - ValueList
//                        - Array
//                        - Structure - 
//               
//         - Structure - 
//           
//           
//
// Returns:
//   Array of See ClusterAdministrationClientServer.SessionProperties
//
Function InfobaseSessions(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, Val Filter = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobaseSessions(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Filter);
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//  Filter - Array of Structure:
//             * Property - See ClusterAdministrationClientServer.SessionProperties
//             * ComparisonType - ComparisonType -  value of the system enumeration of the comparison View,
//             * Value - Number
//                        - String
//                        - Date
//                        - Boolean
//                        - ValueList
//                        - Array
//                        - Structure - 
//               
//         - Structure - 
//           
//
Procedure DeleteInfobaseSessions(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, Val Filter = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.DeleteInfobaseSessions(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Filter);
	
EndProcedure

#EndRegion

#Region InfobaseConnections

// Deprecated.
// 
//
// Returns:
//  Structure:
//    * Number - Number -  number of connection to the information base,
//    * UserName - String -  user name 1C:Enterprise connected to the information base,
//    * ClientComputerName - String -  name of the computer from which the connection is established,
//    * ClientApplicationID - String -  ID of the application that established the connection (see the description of the
//                                                    function of the global context of the application view),
//    * ConnectionEstablishingTime - Date -  (Date and time) when the connection was established,
//    * InfobaseConnectionMode - Number -  data base connection mode (0 -
//      shared, 1-exclusive),
//    * DataBaseConnectionMode - Number -  database connection mode (0 - no connection established,
//      1 - shared, 2-exclusive),
//    * DBMSLock - Number -  ID of the connection that is blocking this connection in the DBMS,
//    * Passed - Number -  amount of data received and sent by the connection,
//    * PassedIn5Minutes - Number -  amount of data received and sent by the connection in the last 5 minutes,
//    * ServerCalls - Number -  number of server calls,
//    * ServerCallsIn5Minutes - Number -  number of server connection calls in the last 5 minutes,
//    * ExchangedWithDBMS - Number -  amount of data transferred between the 1C server:Enterprise and database server,
//      from the moment this connection is established,
//    * ExchangedWithDBMSIn5Minutes - Number -  amount of data transferred between the 1C server:Enterprise and database server
//        in the last 5 minutes,
//    * DBMSConnection - String -  ID of the DBMS connection process (if
//      this connection was accessing the DBMS server at the time of getting the list of connections, otherwise the value is equal to an empty
//      string). The ID is returned in terms of the DBMS server,
//    * DBMSTime - Number -  the time, in seconds, during which the DBMS server is accessed (if this connection was accessing the DBMS server at the time of
//      receiving the list of connections, otherwise the value
//      is 0),
//    * DBMSConnectionSeizeTime - Date -  (Date and time) when the connection to the DBMS server was last captured,
//    * ServerCallDurations - Number -  duration of all server connection calls,
//    * DBMSCallDuration - Number -  time of DBMS calls initiated by the connection,
//    * CurrentServerCallDuration - Number -  duration of the current server call,
//    * CurrentDBMSCallDuration - Number -  the duration of the current call to the DBMS server,
//    * ServerCallDurationsIn5Minutes - Number -  duration of server connection calls in the last 5 minutes,
//    * DBMSCallDurationsIn5Minutes - Number -  duration of DBMS connection calls in the last 5 minutes.
//
Function ConnectionProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Number");
	Result.Insert("UserName");
	Result.Insert("ClientComputerName");
	Result.Insert("ClientApplicationID");
	Result.Insert("ConnectionEstablishingTime");
	Result.Insert("InfobaseConnectionMode");
	Result.Insert("DataBaseConnectionMode");
	Result.Insert("DBMSLock");
	Result.Insert("Passed");
	Result.Insert("PassedIn5Minutes");
	Result.Insert("ServerCalls");
	Result.Insert("ServerCallsIn5Minutes");
	Result.Insert("ExchangedWithDBMS");
	Result.Insert("ExchangedWithDBMSIn5Minutes");
	Result.Insert("DBMSConnection");
	Result.Insert("DBMSTime");
	Result.Insert("DBMSConnectionSeizeTime");
	Result.Insert("ServerCallDurations");
	Result.Insert("DBMSCallDuration");
	Result.Insert("CurrentServerCallDuration");
	Result.Insert("CurrentDBMSCallDuration");
	Result.Insert("ServerCallDurationsIn5Minutes");
	Result.Insert("DBMSCallDurationsIn5Minutes");
	
	Return Result;
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//  Filter - Array of Structure:
//             * Property - See ClusterAdministrationClientServer.ConnectionProperties
//             * ComparisonType - ComparisonType -  value of the system enumeration type of Comparison
//               , the type of comparison of connection values with the one specified in the filter condition,
//             * Value - Number
//                        - String
//                        - Date
//                        - Boolean
//                        - ValueList
//                        - Array
//                        - Structure - 
//               
//         - Structure - 
//           
//
// Returns: 
//   Array of See ClusterAdministrationClientServer.ConnectionProperties.
//
Function InfobaseConnections(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, Val Filter = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobaseConnections(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Filter);
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//  Filter - Array of Structure:
//              * Property - See ClusterAdministrationClientServer.ConnectionProperties
//              * ComparisonType - ComparisonType -  value of the system enumeration type of Comparison
//                , the type of comparison of connection values with the one specified in the filter condition,
//              * Value - Number
//                         - String
//                         - Date
//                         - Boolean
//                         - ValueList
//                         - Array
//                         - Structure - 
//                
//         - Structure - 
//           
//
Procedure TerminateInfobaseConnections(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, Val Filter = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.TerminateInfobaseConnections(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Filter);
	
EndProcedure

#EndRegion

#Region SecurityProfiles

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//
// Returns:
//  String - 
//  
//
Function InfobaseSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobaseSecurityProfile(
		ClusterAdministrationParameters,
		IBAdministrationParameters);
	
EndFunction

// Deprecated.
// 
//  
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//
// Returns:
//  String - 
//  
//  
//
Function InfobaseSafeModeSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobaseSafeModeSecurityProfile(
		ClusterAdministrationParameters,
		IBAdministrationParameters);
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//  ProfileName - String -  name of the security profile. If an empty string is passed
//    , the use of the security profile will be disabled for the information database.
//
Procedure SetInfobaseSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, Val ProfileName = "") Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetInfobaseSecurityProfile(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		ProfileName);
	
EndProcedure

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//  ProfileName - String -  name of the security profile. If an empty string is passed
//    , the use of the safe mode security profile will be disabled for the information database.
//
Procedure SetInfobaseSafeModeSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, Val ProfileName = "") Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetInfobaseSafeModeSecurityProfile(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		ProfileName);
	
EndProcedure

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  ProfileName - String -  name of the security profile that is being checked for existence.
//
// Returns:
//   Boolean - 
//
Function SecurityProfileExists(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.SecurityProfileExists(
		ClusterAdministrationParameters,
		ProfileName);
	
EndFunction

// Deprecated.
// 
//
// Returns: 
//   Structure:
//     * Name - String -  the name of the security profile,
//     * LongDesc - String -  description of the security profile,
//     * SafeModeProfile - Boolean -  defines whether the security profile can
//       be used as a safe mode security profile (both when specifying the
//       safe mode profile for the information base, and when calling set safe Mode (<profile Name>) from the configuration code,
//     * FullAccessToPrivilegedMode - Boolean -  determines
//       whether privileged mode can be set from the safe mode of this security profile,
//     * FileSystemFullAccess - Boolean -  determines whether there are restrictions on access to the file
//       system. If the value is set to False, access will only be granted to the file
//       system directories listed in the virtual Directories property,
//     * COMObjectFullAccess - Boolean -  determines whether there are restrictions on access to use
//       Somobjects. If the value is set to False, access will only be granted to the COM classes
//       listed in the Comclasses property,
//     * AddInFullAccess - Boolean -  determines whether there are restrictions on access to the use
//       of external components. If the value is set to False, access will only be granted to the external
//       components listed in the external Components property,
//     * ExternalModuleFullAccess - Boolean -  determines whether there are restrictions on access to using
//       external modules (external reports and processing, Execute() and Compute () calls) in unsafe mode.
//       If the value is set to False, you will be given the option to use
//       only the external modules listed in the external Modules property in unsafe mode,
//     * FullOperatingSystemApplicationAccess - Boolean -  determines whether there are restrictions on access to
//       the use of operating system applications. If the value is set to False, you will be given
//       the option to use only the operating system applications listed in the Applicationsoc property,
//     * InternetResourcesFullAccess - Boolean -  determines whether there are restrictions on access to use
//       Internet resources. If the value is set to False, you will be given the option to use
//       only the Internet resources listed in the Internet Resources property,
//     * VirtualDirectories - Array of See ClusterAdministrationClientServer.VirtualDirectoryProperties
//     * COMClasses - Array of See ClusterAdministrationClientServer.COMClassProperties
//     * AddIns - Array of See ClusterAdministrationClientServer.AddInProperties
//     * ExternalModules - Array of See ClusterAdministrationClientServer.ExternalModuleProperties
//     * OSApplications - Array of See ClusterAdministrationClientServer.OSApplicationProperties
//     * InternetResources - Array of See ClusterAdministrationClientServer.InternetResourceProperties
//
Function SecurityProfileProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name", "");
	Result.Insert("LongDesc", "");
	Result.Insert("SafeModeProfile", False);
	Result.Insert("FullAccessToPrivilegedMode", False);
	
	Result.Insert("FileSystemFullAccess", False);
	Result.Insert("COMObjectFullAccess", False);
	Result.Insert("AddInFullAccess", False);
	Result.Insert("ExternalModuleFullAccess", False);
	Result.Insert("FullOperatingSystemApplicationAccess", False);
	Result.Insert("InternetResourcesFullAccess", False);
	
	Result.Insert("VirtualDirectories", New Array());
	Result.Insert("COMClasses", New Array());
	Result.Insert("AddIns", New Array());
	Result.Insert("ExternalModules", New Array());
	Result.Insert("OSApplications", New Array());
	Result.Insert("InternetResources", New Array());
	
	Return Result;
	
EndFunction

// Deprecated.
// 
//
// Returns: 
//   Structure:
//     * LogicalURL - String -  logical url of the folder,
//     * PhysicalURL - String -  physical URL of the directory on the server for hosting
//       virtual directory data,
//     * LongDesc - String -  description of the virtual folder,
//     * DataReader - Boolean -  flag to allow reading data from the virtual directory,
//     * DataWriter - Boolean -  flag for allowing data to be written to the virtual directory.
//
Function VirtualDirectoryProperties() Export
	
	Result = New Structure();
	
	Result.Insert("LogicalURL");
	Result.Insert("PhysicalURL");
	
	Result.Insert("LongDesc");
	
	Result.Insert("DataReader");
	Result.Insert("DataWriter");
	
	Return Result;
	
EndFunction

// Deprecated.
// 
//
// Returns:
//   Structure:
//     * Name - String -  name of the COM class, used as the search key,
//     * LongDesc - String -  description of the COM class,
//     * FileMoniker - String -  name of the file used to create the object using the global 
//       context method Getcomobject() with an empty value for the second parameter,
//     * CLSID - String -  representation of the COM class identifier in the MS Windows registry format 
//       without curly brackets, by which it can be created by the operating system,
//     * Computer - String -  name of the computer on which the COM object can be created.
//
Function COMClassProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name");
	Result.Insert("LongDesc");
	
	Result.Insert("FileMoniker");
	Result.Insert("CLSID");
	Result.Insert("Computer");
	
	Return Result;
	
EndFunction

// Deprecated.
// 
//
// Returns:
//   Structure:
//     * Name - String -  the name of the external components, is used as a key to search for,
//     * LongDesc - String -  description of external components,
//     * HashSum - String -  checksum of the allowed external component calculated by the algorithm
//       SHA-1 and converted to a base64 string.
//
Function AddInProperties() Export
	
	Result = New Structure();
	Result.Insert("Name");
	Result.Insert("LongDesc");
	Result.Insert("HashSum"); // 
	Return Result;
	
EndFunction

// Deprecated.
// 
//
// Returns:
//   Structure:
//     * Name - String -  the name of the external module is used as a key to search for,
//     * LongDesc - String -  external module description,
//     * HashSum - String -  checksum of the allowed external module calculated by the algorithm
//       SHA-1 and converted to a base64 string.
//
Function ExternalModuleProperties() Export
	
	Result = New Structure();
	Result.Insert("Name");
	Result.Insert("LongDesc");
	Result.Insert("HashSum"); // 
	Return Result;
	
EndFunction

// Deprecated.
// 
//
// Returns:
//   Structure:
//     * Name - String -  name of the operating system application, used as the search key,
//     * LongDesc - String -  description of the operating system application,
//     * CommandLinePattern - String -  application launch string template (consists of a sequence
//       of template words separated by spaces).
//
Function OSApplicationProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name");
	Result.Insert("LongDesc");
	
	Result.Insert("CommandLinePattern");
	
	Return Result;
	
EndFunction

// Deprecated.
// 
//
// Returns:
//   Structure:
//     * Name - String -  name of the Internet resource used as the search key,
//     * LongDesc - String -  description of the Internet resource,
//     * Protocol - String - :
//         
//         
//         
//         
//         
//         
//         
//     * Address - String -  network address of an Internet resource without specifying the Protocol and port,
//     * Port - Number -  network port of the Internet resource.
//
Function InternetResourceProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name");
	Result.Insert("LongDesc");
	
	Result.Insert("Protocol");
	Result.Insert("Address");
	Result.Insert("Port");
	
	Return Result;
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  ProfileName - String -  name of the security profile.
//
// Returns:
//   See ClusterAdministrationClientServer.SecurityProfileProperties.
//
Function SecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.SecurityProfile(
		ClusterAdministrationParameters,
		ProfileName);
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  SecurityProfileProperties - See ClusterAdministrationClientServer.SecurityProfileProperties.
//
Procedure CreateSecurityProfile(Val ClusterAdministrationParameters, Val SecurityProfileProperties) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.CreateSecurityProfile(
		ClusterAdministrationParameters,
		SecurityProfileProperties);
	
EndProcedure

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  SecurityProfileProperties - See ClusterAdministrationClientServer.SecurityProfileProperties.
//
Procedure SetSecurityProfileProperties(Val ClusterAdministrationParameters, Val SecurityProfileProperties)  Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetSecurityProfileProperties(
		ClusterAdministrationParameters,
		SecurityProfileProperties);
	
EndProcedure

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  ProfileName - String -  name of the security profile.
//
Procedure DeleteSecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.DeleteSecurityProfile(
		ClusterAdministrationParameters,
		ProfileName);
	
EndProcedure

#EndRegion

#Region Infobases

// Deprecated.
// 
//
// Parameters:
//  ClusterID - String -  internal ID of the server cluster,
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  InfobaseAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//
// Returns:
//   String -  internal ID of the information database.
//
Function InfoBaseID(Val ClusterID, Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfoBaseID(
		ClusterID,
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters);
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterID - String -  internal ID of the server cluster,
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  Filter - Structure -  the parameters of the filtering databases.
//
// Returns:
//  Array of Structure
//
Function InfobasesProperties(Val ClusterID, Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobasesProperties(
		ClusterID,
		ClusterAdministrationParameters,
		Filter);
	
EndFunction

#EndRegion

#Region Cluster

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters.
//
// Returns:
//   String - internal ID of the server cluster.
//
Function ClusterID(Val ClusterAdministrationParameters) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.ClusterID(ClusterAdministrationParameters);
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  Filter - Structure -  parameters for filtering server clusters.
//
// Returns:
//   Array of Structure
//
Function ClusterProperties(Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.ClusterProperties(ClusterAdministrationParameters, Filter);
	
EndFunction

#EndRegion

#Region WorkingProcessesServers

// Deprecated.
// 
//
// Parameters:
//  ClusterID - String -  internal ID of the server cluster,
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  Filter - Structure -  the filtering options work processes.
//
// Returns:
//   Array of Structure 
//
Function WorkingProcessesProperties(Val ClusterID, Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.WorkingProcessesProperties(
		ClusterID,
		ClusterAdministrationParameters,
		Filter);
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterID - String -  internal ID of the server cluster,
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  Filter - Structure -  parameters for filtering production servers.
//
// Returns:
//   Array of Structure
//
Function WorkingServerProperties(Val ClusterID, Val ClusterAdministrationParameters, Val Filter = Undefined) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.WorkingServerProperties(
		ClusterID,
		ClusterAdministrationParameters,
		Filter);
	
EndFunction

#EndRegion

// Deprecated.
// 
//
// Parameters:
//  ClusterID - String -  internal ID of the server cluster,
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  InfoBaseID - String -  internal ID of the information base,
//  Filter - Array of Structure:
//             * Property - See ClusterAdministrationClientServer.SessionProperties
//             * ComparisonType - ComparisonType -  value of the system enumeration of the comparison View,
//             * Value - Number
//                        - String
//                        - Date
//                        - Boolean
//                        - ValueList
//                        - Array
//                        - Structure - 
//               
//         - Structure - 
//           
//           
//  UseDictionary - Boolean -  if True, the returned result will be filled in using the dictionary, otherwise - without
//    using it.
//
// Returns:
//   - Array of See ClusterAdministrationClientServer.SessionProperties
//   - Array of Map
//
Function SessionsProperties(Val ClusterID, Val ClusterAdministrationParameters, Val InfoBaseID, Val Filter = Undefined, Val UseDictionary = True) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.SessionsProperties(
		ClusterID,
		ClusterAdministrationParameters,
		InfoBaseID,
		Filter,
		UseDictionary);
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterID - String -  internal ID of the server cluster,
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters
//  InfoBaseID - String -  internal ID of the information base,
//  InfobaseAdministrationParameters - See ClusterAdministrationClientServer.ClusterInfobaseAdministrationParameters.
//  Filter - Array of Structure:
//             * Property - See ClusterAdministrationClientServer.ConnectionsProperties
//             * ComparisonType - ComparisonType -  value of the system enumeration of the comparison View,
//             * Value - Number
//                        - String
//                        - Date
//                        - Boolean
//                        - ValueList
//                        - Array
//                        - Structure - 
//               
//         - Structure - 
//           
//           
//  UseDictionary - Boolean -  if True, the returned result will be filled in using the dictionary.
//
// Returns:
//   - Array of See ClusterAdministrationClientServer.ConnectionsProperties
//   - Array of Map
//
Function ConnectionsProperties(Val ClusterID, Val ClusterAdministrationParameters, Val InfoBaseID, Val InfobaseAdministrationParameters, Val Filter = Undefined, Val UseDictionary = False) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.ConnectionsProperties(
		ClusterID,
		ClusterAdministrationParameters,
		InfoBaseID,
		InfobaseAdministrationParameters,
		Filter,
		UseDictionary);
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministrationClientServer.ClusterAdministrationParameters.
//
// Returns:
//  String
//
Function PathToAdministrationServerClient(Val ClusterAdministrationParameters) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.PathToAdministrationServerClient();
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Procedure AddFilterCondition(Filter, Val Property, Val ValueComparisonType, Val Value) Export
	
	If Filter = Undefined Then
		
		If ValueComparisonType = ComparisonType.Equal Then
			
			Filter = New Structure;
			Filter.Insert(Property, Value);
			
		Else
			
			Filter = New Array;
			AddFilterCondition(Filter, Property, ValueComparisonType, Value);
			
		EndIf;
		
	ElsIf TypeOf(Filter) = Type("Structure") Then
		
		NewFilter1 = New Array;
		
		For Each KeyAndValue In Filter Do
			
			AddFilterCondition(NewFilter1, KeyAndValue.Key, ComparisonType.Equal, KeyAndValue.Value);
			
		EndDo;
		
		AddFilterCondition(NewFilter1, Property, ValueComparisonType, Value);
		
		Filter = NewFilter1;
		
	ElsIf TypeOf(Filter) = Type("Array") Then
		
		Filter.Add(New Structure("Property, ComparisonType, Value", Property, ValueComparisonType, Value));
		
	Else
		
		Raise NStr("en = 'Invalid filter description.';");
		
	EndIf;
	
EndProcedure

Function CheckFilterConditions(Val ObjectToCheck, Val Filter = Undefined) Export
	
	If Filter = Undefined Or Filter.Count() = 0 Then
		Return True;
	EndIf;
	
	ConditionsMet = 0;
	
	For Each Condition In Filter Do
		
		If TypeOf(Condition) = Type("Structure") Then
			
			Field = Condition.Property;
			RequiredValue = Condition.Value;
			ValueComparisonType = Condition.ComparisonType;
			
		ElsIf TypeOf(Condition) = Type("KeyAndValue") Then
			
			Field = Condition.Key;
			RequiredValue = Condition.Value;
			ValueComparisonType = ComparisonType.Equal;
			
		Else
			
			Raise NStr("en = 'Invalid filter.';");
			
		EndIf;
		
		ValueToCheck = ObjectToCheck[Field];
		ConditionMet = CheckFilterCondition(ValueToCheck, ValueComparisonType, RequiredValue);
		
		If ConditionMet Then
			ConditionsMet = ConditionsMet + 1;
		Else
			Break;
		EndIf;
		
	EndDo;
	
	Return ConditionsMet = Filter.Count();
	
EndFunction

Function CheckFilterCondition(Val ValueToCheck, Val ValueComparisonType, Val Value)
	
	If ValueComparisonType = ComparisonType.Equal Then
		
		Return ValueToCheck = Value;
		
	ElsIf ValueComparisonType = ComparisonType.NotEqual Then
		
		Return ValueToCheck <> Value;
		
	ElsIf ValueComparisonType = ComparisonType.Greater Then
		
		Return ValueToCheck > Value;
		
	ElsIf ValueComparisonType = ComparisonType.GreaterOrEqual Then
		
		Return ValueToCheck >= Value;
		
	ElsIf ValueComparisonType = ComparisonType.Less Then
		
		Return ValueToCheck < Value;
		
	ElsIf ValueComparisonType = ComparisonType.LessOrEqual Then
		
		Return ValueToCheck <= Value;
		
	ElsIf ValueComparisonType = ComparisonType.InList Then
		
		If TypeOf(Value) = Type("ValueList") Then
			
			Return Value.FindByValue(ValueToCheck) <> Undefined;
			
		ElsIf TypeOf(Value) = Type("Array") Then
			
			Return Value.Find(ValueToCheck) <> Undefined;
			
		EndIf;
		
	ElsIf ValueComparisonType = ComparisonType.NotInList Then
		
		If TypeOf(Value) = Type("ValueList") Then
			
			Return Value.FindByValue(ValueToCheck) = Undefined;
			
		ElsIf TypeOf(Value) = Type("Array") Then
			
			Return Value.Find(ValueToCheck) = Undefined;
			
		EndIf;
		
	ElsIf ValueComparisonType = ComparisonType.Interval Then
		
		Return ValueToCheck > Value.From1 And ValueToCheck < Value.On;
		
	ElsIf ValueComparisonType = ComparisonType.IntervalIncludingBounds Then
		
		Return ValueToCheck >= Value.From1 And ValueToCheck <= Value.On;
		
	ElsIf ValueComparisonType = ComparisonType.IntervalIncludingLowerBound Then
		
		Return ValueToCheck >= Value.From1 And ValueToCheck < Value.On;
		
	ElsIf ValueComparisonType = ComparisonType.IntervalIncludingUpperBound Then
		
		Return ValueToCheck > Value.From1 And ValueToCheck <= Value.On;
		
	EndIf;
	
EndFunction

Function AdministrationManager(Val AdministrationParameters)
	
	If AdministrationParameters.AttachmentType = "COM" Then
		
		Return ClusterAdministrationCOMClientServer;
		
	ElsIf AdministrationParameters.AttachmentType = "RAS" Then
		
		Return ClusterAdministrationRASClientServer;
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Unknown connection type: %1.';"), AdministrationParameters.AttachmentType);
		
	EndIf;
	
EndFunction

Function DateEmpty() Export
	
	Return Date(1, 1, 1, 0, 0, 0);
	
EndFunction

#EndRegion


