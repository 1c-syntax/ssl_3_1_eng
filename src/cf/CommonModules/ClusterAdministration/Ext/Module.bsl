///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ProgramInterfaceParameterConstructors

// Parameters for connecting to the server cluster that is being managed.
//
// Returns:
//   Structure:
//     * AttachmentType - String - :
//                  
//                  
//                  
//     * ServerAgentAddress - String -  network address of the server agent (only for connection Type = " COM");
//     * ServerAgentPort - Number -  server agent network port (only for connection Type = "COM"),
//                  typical value is 1540;
//     * AdministrationServerAddress - String -  network address of the ras administration server (only.
//                  When connection Type = " RAS");
//     * AdministrationServerPort - Number -  network port of the ras administration server (only when.
//                  Connection type = "RAS"), typical value 1545;
//     * ClusterPort - Number -  network port of the managed cluster Manager, typical value 1541;
//     * ClusterAdministratorName - String -  name of the cluster administrator account (if
//                  the list of administrators is not specified for the cluster, an empty string is used);
//     * ClusterAdministratorPassword - String -  password of the cluster administrator account (if
//                  the list of administrators is not set for the cluster or the password is not set for the account
//                  , an empty string is used).
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

// Parameters for connecting to the cluster's managed information database.
//
// Returns: 
//  Structure:
//    * NameInCluster - String -  name of the managed database in the server cluster,
//    * InfobaseAdministratorName - String -  name of the information database user with
//                  administrator rights (if the list of information security users is not specified for the information database
//                  , an empty string is used),
//    * InfobaseAdministratorPassword - String -  password of an information database user
//                  with administrator rights (if the list
//                  of is users is not set for the information database or a password is not set for the is user, an empty string is used).
//
Function ClusterInfobaseAdministrationParameters() Export
	
	Result = New Structure();
	
	Result.Insert("NameInCluster", "");
	Result.Insert("InfobaseAdministratorName", "");
	Result.Insert("InfobaseAdministratorPassword", "");
	
	Return Result;
	
EndFunction

// Checks whether the administration parameters are correct.
//
// The Parameteradministrationib parameter can be omitted if similar fields are specified 
// in the cluster Parameteradministration parameter.
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//  CheckClusterAdministrationParameters - Boolean -  the flag you want to check the administrative settings 
//                  cluster.
//  CheckInfobaseAdministrationParameters - Boolean -  the flag you want to check the settings
//                  cluster administration.
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

// Properties of blocking sessions and scheduled tasks in the information database.
//
// Returns: 
//   Structure:
//     * SessionsLock - Boolean -  flag for setting blocking of new sessions with the information base,
//     * DateFrom1 - Date -  the moment when new sessions with the database were blocked,
//     * DateTo - Date -  time when new sessions with the information database are blocked,
//     * Message - String -  message that is displayed to the user when trying to set up a new session
//                            with the information database when new sessions are blocked,
//     * KeyCode - String -  code to bypass blocking new sessions with the information base,
//     * LockScheduledJobs - Boolean -  flag for blocking the execution of routine tasks in the information database.
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

// Returns the current state of blocking sessions and scheduled tasks for the information database.
//
// The Parameteradministrationib parameter can be omitted if similar fields are specified 
// in the cluster Parameteradministration parameter.
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//
// Returns: 
//   See ClusterAdministration.SessionAndScheduleJobLockProperties
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

// Sets a new state for blocking sessions and scheduled tasks for the information database.
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//  SessionAndJobLockProperties - See ClusterAdministration.SessionAndScheduleJobLockProperties
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

// Removes blocking of sessions and scheduled tasks for the information database.
//
// The Parameteradministrationib parameter can be omitted if similar fields are specified 
// in the cluster Parameteradministration parameter.
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
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

// Returns the current status of blocking scheduled tasks for the information database.
//
// The Parameteradministrationib parameter can be omitted if similar fields are specified 
// in the cluster Parameteradministration parameter.
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//
// Returns: 
//  Boolean - 
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

// Sets a new state for blocking routine tasks for the information database.
//
// The Parameteradministrationib parameter can be omitted if similar fields are specified 
// in the cluster Parameteradministration parameter.
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//  IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
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

// Properties of the database session.
//
// Returns: 
//   Structure:
//     * Number - Number -  session number. Unique among all sessions of the information database,
//     * UserName - String -  name of the authenticated user of the information database,
//     * ClientComputerName - String -  name or network address of the computer that established
//          the session with the database,
//     * ClientApplicationID - String -  ID of the application that established the session.
//          Possible values - see description to the function of the global context of the representation of the application(),
//     * LanguageID - String -  ID of the interface language,
//     * SessionCreationTime - Date -  when the session was set up,
//     * LatestSessionActivityTime - Date -  time when the session was last active,
//     * Block - Number -  the session number that is the reason for waiting for a managed transactional
//          lock if the session is installing managed transactional locks
//          and is waiting for the locks set by another session to be released (otherwise, the value is 0),
//     * DBMSLock - Number -  the session number that is the reason for waiting for a transactional
//          lock if the session executes a request to the DBMS and waits for a transactional
//          lock set by another session (otherwise, the value is 0),
//     * Passed - Number -  the amount of data transmitted to honey by the 1C server:Enterprises" and the client application
//          of this session from the start of the session (in bytes),
//     * PassedIn5Minutes - Number -  the amount of data transferred between the "1C" server:Enterprises" and the client
//          application of this session for the last 5 minutes (in bytes),
//     * ServerCalls - Number -  the number of calls to the server, "1C:Enterprises " from the names of this session
//          since the start of the session,
//     * ServerCallsIn5Minutes - Number -  the number of calls to the server, "1C:Enterprises " on behalf of this session
//          for the last 5 minutes,
//     * ServerCallDurations - Number -  execution time of server calls " 1C:Enterprises " on behalf
//          of this session since the session started (in seconds),
//     * CurrentServerCallDuration - Number -  the time interval in milliseconds that has elapsed since the start
//          of the request, if the session is calling the server " 1C:Enterprises" (otherwise, the value is 0),
//     * ServerCallDurationsIn5Minutes - Number -  execution time of calls to the server 1S:Businesses on behalf
//          of this session for the last 5 minutes (in milliseconds),
//     * ExchangedWithDBMS - Number -  the number of data sent and received from the DBMS on behalf of this session
//          since the session started (in bytes),
//     * ExchangedWithDBMSIn5Minutes - Number -  the number of data sent and received from the DBMS on behalf of this session
//          in the last 5 minutes (in bytes),
//     * DBMSCallDuration - Number -  execution time of DBMS queries on behalf of this session since
//          the session started (in milliseconds),
//     * CurrentDBMSCallDuration - Number -  the time interval in milliseconds that has elapsed since the start
//          of query execution if the session executes a query to the DBMS (otherwise, the value is 0),
//     * DBMSCallDurationsIn5Minutes - Number -  total execution time of DBMS requests on behalf of this session
//          for the last 5 minutes (in milliseconds).
//     * DBMSConnection - String -  DBMS connection number in DBMS terms if a
//          query to the DBMS is being made, a transaction is open, or temporary tables are defined (i.e.
//          , a connection to the DBMS is captured). If the DBMS connection is not captured , the value is equal to an empty string,
//     * DBMSConnectionTime - Number -  the connection to the DBMS from the moment of capture (in milliseconds). If the connection with
//          DBMS is not captured, the value is 0,
//     * DBMSConnectionSeizeTime - Date -  the time when the DBMS connection was last
//          captured by another session.
//     * IConnectionShort - Structure
//                          - Undefined -  
//                   See ClusterAdministration.ConnectionDetailsProperties.
//     * Sleep - Boolean -  the session is in sleep mode.
//     * TerminateIn - Number -  the time interval, in seconds, after which the sleeping session ends.
//     * SleepIn - Number -  the time interval, in seconds, after which an inactive session is put to
//                              sleep.
//     * ReadFromDisk - Number -  contains the number of bytes of data read from disk by the session since the session started.
//     * ReadFromDiskInCurrentCall - Number -  contains the number of bytes of data read from disk since the start 
//                  of the current call.
//     * ReadFromDiskIn5Minutes - Number -  contains the amount of data, in bytes, that the session has read from disk in the past
//                                         5 minutes.
//     * ILicenseInfo - Structure
//                - Undefined - 
//                   See ClusterAdministration.LicenseProperties. 
//                  
//     * OccupiedMemory - Number -  contains the amount of memory, in bytes, used during calls since the session started.
//     * OccupiedMemoryInCurrentCall - Number -  contains the amount of memory, in bytes, used since the start of the current call. 
//                  If the call is not currently running, it contains 0.
//     * OccupiedMemoryIn5Minutes - Number -  contains the amount of memory, in bytes, used during calls in the last 5 minutes.
//     * WrittenOnDisk - Number -  contains the number of bytes of data written to disk by the session since the session started.
//     * WrittenOnDiskInCurrentCall - Number -  contains the number of bytes of data written to disk since the start
//                  of the current call.
//     * WrittenOnDiskIn5Minutes - Number -  contains the number of bytes of data written to disk by the session in the last 5
//                                        minutes.
//     * IWorkingProcessInfo - Structure
//                      - Undefined -  
//                   See ClusterAdministration.WorkingProcessProperties. 
//                   
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
	Result.Insert("IConnectionShort");
	Result.Insert("Sleep");
	Result.Insert("TerminateIn");
	Result.Insert("SleepIn");
	Result.Insert("ReadFromDisk");
	Result.Insert("ReadFromDiskInCurrentCall");
	Result.Insert("ReadFromDiskIn5Minutes");
	Result.Insert("ILicenseInfo");
	Result.Insert("OccupiedMemory");
	Result.Insert("OccupiedMemoryInCurrentCall");
	Result.Insert("OccupiedMemoryIn5Minutes");
	Result.Insert("WrittenOnDisk");
	Result.Insert("WrittenOnDiskInCurrentCall");
	Result.Insert("WrittenOnDiskIn5Minutes");
	Result.Insert("IWorkingProcessInfo");
	
	Return Result;
	
EndFunction

// The license properties.
//
// Returns: 
//   Structure:
//     * FileName - String -  contains the full name of the software license file used. 
//     * FullPresentation - String -  contains a localized string representation of the license, as in
//                  the "License" property of the session properties dialog or the cluster console workflow properties
//     * BriefPresentation - String -  contains a localized string representation of the license, as in
//                  the "License" column of the list of sessions or workflows.
//     * IssuedByServer - Boolean -  True-the license was obtained by the 1C server:Enterprise" and issued to the client application.
//                  False-the license was obtained by the client application.
//     * LisenceType - Number - : 
//                   
//                  
//     * MaxUsersForSet - Number -  contains the maximum number of users 
//                  allowed for this bundle if the platform software license is used. Otherwise, it matches
//                  the value of the MaxUsersCur property.
//     * MaxUsersInKey - Number -  contains the maximum number of users in 
//                  the program security key used or in the software license file used.
//     * LicenseIsReceivedViaAladdinLicenseManager - Boolean -  True if the program security key is used for the hardware license
//                  is a network license obtained through the Aladdin License Manager; False
//                  otherwise.
//     * ProcessAddress - String -  contains the address of the server where the licensed process is running.
//     * ProcessID - String -  contains the ID of the licensed process assigned to it
//                  by the operating system.
//     * ProcessPort - Number -  contains the IP port number of the server process that received the license.
//     * KeySeries - String -  contains the program security key series for the hardware license or the registration number
//                  of the kit for the platform software license.
//
Function LicenseProperties() Export
	
	Result = New Structure();
	
	Result.Insert("FileName");
	Result.Insert("FullPresentation");
	Result.Insert("BriefPresentation");
	Result.Insert("IssuedByServer");
	Result.Insert("LisenceType");
	Result.Insert("MaxUsersForSet");
	Result.Insert("MaxUsersInKey");
	Result.Insert("LicenseIsReceivedViaAladdinLicenseManager");
	Result.Insert("ProcessAddress");
	Result.Insert("ProcessID");
	Result.Insert("ProcessPort");
	Result.Insert("KeySeries");
	
	Return Result;
	
EndFunction

// Properties of the connection description.
//
// Returns: 
//   Structure:
//     * ApplicationName - String -  contains the name of the application that established a connection to the 1C server farm:Companies".
//     * Block - Number -  contains the ID of the connection that is blocking this connection (in 
//                  the transactional blocking Service).
//     * ConnectionEstablishingTime - Date -  contains the time when the connection was established.
//     * Number - Number -  contains the connection ID. Allows you to distinguish between different connections established by
//                  the same application from the same client computer
//     * ClientComputerName - String -  contains the name of the user computer that the connection is made from.
//     * SessionNumber - Number -  contains the session number if the connection is assigned a session, otherwise it is 0.
//     * IWorkingProcessInfo - Structure -  contains the interface of an object with a description of the server process to which
//                  this connection is established.
//
Function ConnectionDetailsProperties() Export
	
	Result = New Structure();
	
	Result.Insert("ApplicationName");
	Result.Insert("Block");
	Result.Insert("ConnectionEstablishingTime");
	Result.Insert("Number");
	Result.Insert("ClientComputerName");
	Result.Insert("SessionNumber");
	Result.Insert("IWorkingProcessInfo");
	
	Return Result;
	
EndFunction

// Properties of the workflow.
//
// Returns:
//   Structure:
//     * AvailablePerformance - Number -  average available performance over the last 5 minutes. It is determined
//                  by the response time of the workflow to the reference request. In accordance with the available 
//                  the performance of the server cluster, decides on the allocation of customers between workers
//                  processes.
//     * SpentByTheClient - Number -  shows the average time spent by the workflow on
//                  client application method callbacks during a single client call
//     * ServerReaction - Number -  shows the average service time for a single client request by the workflow.
//                  It consists of: property values with Saracenorum, Tetracenes, Strictmanagement,
//                  Expended by the client.
//     * SpentByDBMS - Number -  shows the average time that a worker process spends accessing the database server
//                  during a single client request.
//     * SpentByTheLockManager - Number -  shows the average time to access the lock Manager.
//     * SpentByTheServer - Number -  shows the average time that the workflow itself takes to complete
//                  a single client request.
//     * ClientStreams - Number -  shows the average number of client threads executed by the cluster workflow.
//     * Capacity - Number -  relative performance of the process. It can be in 
//                  the range from 1 to 1000. Used when selecting the workflow that
//                  the next client will be connected to. Clients are distributed among workflows in proportion
//                  to the performance of the workflows.
//     * Connections - Number -  the number of workflow connections to user applications.
//     * ComputerName - String -  contains the name or IP address of the computer on which the workflow should be running.
//     * Enabled - Boolean -  it is set by the cluster when it is necessary to start or stop the workflow.
//                  True-the process must be started and will be started if possible. 
//                  False - the process must be stopped and will be stopped after all users are disconnected or
//                  after the time set by the cluster settings has elapsed.
//     * Port - Number -  contains the number of the main IP port of the workflow. This port is allocated dynamically at the start
//                  of the workflow from the port ranges defined for the corresponding production server.
//     * ExceedingTheCriticalValue - Number -  contains the time that the amount of virtual memory
//                  in the workflow exceeds the critical value set for the cluster, in seconds.
//     * OccupiedMemory - Number -  contains the amount of virtual memory used by the workflow, in kilobytes.
//     * Id - String -  ID of the active workflow in terms of the operating system.
//     * Started2 - Number -  status of the workflow.
//                  0 - the process is inactive (either not loaded in memory, or cannot execute client requests); 
//                  1 - the process is active (running). 
//     * CallsCountByWhichTheStatisticsIsCalculated - Number -  the number of calls for which statistics are calculated.
//     * StartedAt - Date -  contains the time when the workflow started. If the process is not running, then an empty date.
//     * Use - Number -  
//                  : 
//                      
//                      
//                     
//                         
//     * ILicenseInfo - Structure
//                - Undefined -  
//                  
//
Function WorkingProcessProperties() Export
	
	Result = New Structure();
	
	Result.Insert("AvailablePerformance");
	Result.Insert("SpentByTheClient");
	Result.Insert("ServerReaction");
	Result.Insert("SpentByDBMS");
	Result.Insert("SpentByTheLockManager");
	Result.Insert("SpentByTheServer");
	Result.Insert("ClientStreams");
	Result.Insert("Capacity");
	Result.Insert("Connections");
	Result.Insert("ComputerName");
	Result.Insert("Enabled");
	Result.Insert("Port");
	Result.Insert("ExceedingTheCriticalValue");
	Result.Insert("OccupiedMemory");
	Result.Insert("Id");
	Result.Insert("Started2");
	Result.Insert("CallsCountByWhichTheStatisticsIsCalculated");
	Result.Insert("StartedAt");
	Result.Insert("Use");
	Result.Insert("ILicenseInfo");
	
	Return Result;
	
EndFunction

// 
//
//  
// 
//  (See ClusterAdministration.SessionsFilter) 
// 
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//   Filter - Array of See ClusterAdministration.SessionsFilter
//          - See ClusterAdministration.SessionsFilter
//
// Returns: 
//   Array of See ClusterAdministration.SessionProperties
//
Function InfobaseSessions(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, 
	Val Filter = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobaseSessions(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Filter);
	
EndFunction

// 
//
//  
// 
//  (See ClusterAdministration.SessionsFilter) 
// 
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//   Filter - Array of See ClusterAdministration.SessionsFilter
//          - See ClusterAdministration.SessionsFilter
//
Procedure DeleteInfobaseSessions(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, 
	Val Filter = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.DeleteInfobaseSessions(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Filter);
	
EndProcedure

// The properties of the filter.
// For use in the functions of the session Informationbase, delete session Informationbase, and similar. 
//
// Returns:
//   Structure:
//     * Property - String -  the name of the property by which filtering is performed. 
//                  Acceptable values - see the return value of the Cluster Administration function.The properties of the session.
//     * ComparisonType - ComparisonType -  
//                  :
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
//     * Value - Number
//                - String
//                - Date
//                - Boolean
//                - ValueList
//                - Array
//                - Structure - 
//               
//               
//               
//               
//               
//               
//
Function SessionsFilter() Export
	
	Result = New Structure();
	
	Result.Insert("Property");
	Result.Insert("ComparisonType", ComparisonType.Equal);
	Result.Insert("Value");
	
	Return Result;
	
EndFunction

#EndRegion

#Region InfobaseConnections

// Properties of the connection to the information base.
//
// Returns: 
//   Structure:
//     * Number - Number -  number of the connection to the information base.
//     * UserName - String -  user name 1C:An enterprise connected to the information database.
//     * ClientComputerName - String -  name of the computer that the connection is made from.
//     * ClientApplicationID - String -  ID of the application that established the connection.
//                  Possible values - see description to the function of the global context of the representation of the application(),
//     * ConnectionEstablishingTime - Date -  the moment when the connection was established.
//     * InfobaseConnectionMode - Number -  data base connection mode (0 -
//                  shared, 1-exclusive),
//     * DataBaseConnectionMode - Number -  database connection mode (0 - no connection established,
//                  1 - shared, 2-exclusive).
//     * DBMSLock - Number -  ID of the connection that is blocking this connection in the DBMS.
//     * Passed - Number -  the amount of data received and sent by the connection.
//     * PassedIn5Minutes - Number -  the amount of data received and sent by the connection in the last 5 minutes.
//     * ServerCalls - Number -  number of server calls.
//     * ServerCallsIn5Minutes - Number -  the number of server calls to the connection in the last 5 minutes.
//     * ExchangedWithDBMS - Number -  amount of data transferred between the 1C server:Enterprise and database server,
//                  from the moment this connection is established,
//     * ExchangedWithDBMSIn5Minutes - Number -  amount of data transferred between the 1C server:Enterprise and database server
//                  in the last 5 minutes,
//     * DBMSConnection - String -  ID of the DBMS connection process (if
//                  this connection was accessing the DBMS server at the time of getting the list of connections, otherwise the value is equal
//                  to an empty string). The ID is returned in terms of the DBMS server.
//     * DBMSTime - Number -  the time, in seconds, during which the DBMS server is accessed (if this connection was accessing the DBMS server at the time of
//                  receiving the list of connections, otherwise
//                  the value is 0).
//     * DBMSConnectionSeizeTime - Date -  the moment when the connection to the DBMS server was last captured.
//     * ServerCallDurations - Number -  duration of all server calls to the connection.
//     * DBMSCallDuration - Number -  time of DBMS calls initiated by the connection.
//     * CurrentServerCallDuration - Number -  duration of the current server call.
//     * CurrentDBMSCallDuration - Number -  the duration of the current call to the DBMS server.
//     * ServerCallDurationsIn5Minutes - Number -  duration of server connection calls in the last 5 minutes.
//     * DBMSCallDurationsIn5Minutes - Number -  duration of DBMS connection calls in the last 5 minutes.
//     * ReadFromDisk - Number -  contains the number of bytes of data read from disk by the session since the session started.
//     * ReadFromDiskInCurrentCall - Number -  contains the number of bytes of data read from disk since the start
//                  of the current call.
//     * ReadFromDiskIn5Minutes - Number -  contains the number of bytes of data read from disk by the session in the 
//                  last 5 minutes.
//     * OccupiedMemory - Number -  contains the amount of memory, in bytes, used during calls since the session started.
//     * OccupiedMemoryInCurrentCall - Number -  contains the amount of memory, in bytes, used since the start of the current
//                  call. If the call is not currently running, it contains 0.
//     * OccupiedMemoryIn5Minutes - Number -  contains the amount of memory, in bytes, used during calls in the last 5 minutes.
//     * WrittenOnDisk - Number -  contains the number of bytes of data written to disk by the session since the session started.
//     * WrittenOnDiskInCurrentCall - Number -  contains the number of bytes of data written to disk since the start
//                  of the current call.
//     * WrittenOnDiskIn5Minutes - Number -  contains the number of bytes of data written to disk by the session in the
//                  last 5 minutes.
//     * ControlIsOnServer - Number -  indicates whether management is located on the server (0 - not located, 1-located).
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
	Result.Insert("ReadFromDisk");
	Result.Insert("ReadFromDiskInCurrentCall");
	Result.Insert("ReadFromDiskIn5Minutes");
	Result.Insert("OccupiedMemory");
	Result.Insert("OccupiedMemoryInCurrentCall");
	Result.Insert("OccupiedMemoryIn5Minutes");
	Result.Insert("WrittenOnDisk");
	Result.Insert("WrittenOnDiskInCurrentCall");
	Result.Insert("WrittenOnDiskIn5Minutes");
	Result.Insert("ControlIsOnServer");
	
	Return Result;
	
EndFunction

// 
//
//  
// 
//  (See ClusterAdministration.SessionsFilter) 
// 
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//   Filter - See ClusterAdministration.JoinsFilters 
//           See ClusterAdministration.JoinsFilters
//
// Returns: 
//   Array of See ClusterAdministration.ConnectionProperties
//
Function InfobaseConnections(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, 
	Val Filter = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfobaseConnections(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Filter);
	
EndFunction

// 
//
//  
// 
//  (See ClusterAdministration.JoinsFilters) 
// 
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//   Filter - Array of See ClusterAdministration.JoinsFilters
//          - See ClusterAdministration.JoinsFilters
//
Procedure TerminateInfobaseConnections(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, 
	Val Filter = Undefined) Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.TerminateInfobaseConnections(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		Filter);
	
EndProcedure

// Properties of the connection filter.
// For use in the functions joininformation Base, breakinformation base Connections, and similar. 
//
// Returns:
//   Structure:
//     * Property - String -  the name of the property by which filtering is performed. 
//                  Acceptable values - see the return value of the Cluster Administration function.Connection properties.
//     * ComparisonType - ComparisonType -  
//                  :
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
//     * Value - Number
//                - String
//                - Date
//                - Boolean
//                - ValueList
//                - Array
//                - Structure - 
//               
//               
//               
//               
//               
//               
//
Function JoinsFilters() Export
	
	Result = New Structure();
	
	Result.Insert("Property");
	Result.Insert("ComparisonType", ComparisonType.Equal);
	Result.Insert("Value");
	
	Return Result;
	
EndFunction

#EndRegion

#Region SecurityProfiles

// Returns the name of the security profile assigned to the information database.
//
// The Parameteradministrationib parameter can be omitted if similar fields are specified 
// in the cluster Parameteradministration parameter.
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//
// Returns: 
//   String - 
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

// Returns the name of the security profile assigned to the information database as
// the safe mode security profile.
//
// The Parameteradministrationib parameter can be omitted if similar fields are specified 
// in the cluster Parameteradministration parameter.
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//
// Returns: 
//   String - 
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

// Assigns the use of a security profile for the information database.
//
// The Parameteradministrationib parameter can be omitted if similar fields are specified 
// in the cluster Parameteradministration parameter.
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//   ProfileName - String -  name of the security profile. If an empty string is passed 
//                         , the use of the security profile will be disabled for the information database.
//
Procedure SetInfobaseSecurityProfile(Val ClusterAdministrationParameters, Val IBAdministrationParameters = Undefined, 
	Val ProfileName = "") Export
	
	If IBAdministrationParameters = Undefined Then
		IBAdministrationParameters = ClusterAdministrationParameters;
	EndIf;
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetInfobaseSecurityProfile(
		ClusterAdministrationParameters,
		IBAdministrationParameters,
		ProfileName);
	
EndProcedure

// Assigns the information base to use the safe mode security profile.
//
// The Parameteradministrationib parameter can be omitted if similar fields are specified 
// in the cluster Parameteradministration parameter.
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   IBAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//   ProfileName - String -  name of the security profile. If an empty string is passed 
//                         , the use of the safe mode security profile will be disabled for the information database.
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

// Checks whether a security profile exists in the server cluster.
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters.
//   ProfileName - String -  name of the security profile that is being checked for existence.
//
// Returns:
//   Boolean
//
Function SecurityProfileExists(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.SecurityProfileExists(
		ClusterAdministrationParameters,
		ProfileName);
	
EndFunction

// The properties of the security profile.
//
// Returns: 
//   Structure:
//     * Name - String -  the name of the security profile,
//     * LongDesc - String -  description of the security profile,
//     * SafeModeProfile - Boolean -  defines whether the security profile can be used
//                  as a safe mode security profile (both when specifying the
//                  safe mode profile for the information base and when calling.
//                  Set the secure mode (<profile Name>) from the configuration code.
//     * FullAccessToPrivilegedMode - Boolean -  determines
//                  whether privileged mode can be set from the safe mode of this security profile.
//     * FullAccessToCryptoFunctions - Boolean -  defines permission to use cryptographic
//                  functionality (signature, signature verification, encryption, decryption, working with the certificate store
//                  , certificate verification, extracting certificates from the signature) when working on the server.
//                  Cryptography functions are not blocked on the client. 
//                  True-execution is allowed. False-execution is prohibited.
//     * FullAccessToAllModulesExtension - Boolean - 
//                  :
//                     
//                     
//     * ModulesAvailableForExtension - String -  used when the extension of all modules is not allowed.
//                  Contains a list of full names of configuration objects or modules whose extension is allowed, 
//                  separated by";". Specifying the full name of the configuration object allows the extension of all modules
//                  of the object. Specifying the full module name allows the extension of a specific module.
//     * ModulesNotAvailableForExtension - String -  used when the extension of all modules is allowed.
//                  Contains a list of full names of configuration objects or modules whose extension is not allowed,
//                  separated by";". Specifying the full name of the configuration object prohibits the extension of all modules
//                  of the object.
//     * FullAccessToAccessRightsExtension - Boolean - 
//                  : 
//                      
//                      
//                  
//                  
//     * AccessRightsExtensionLimitingRoles - String -  contains a list of role names that affect changes
//                  to access rights from the extension. When you change the list of roles, changes in the role composition are only considered after
//                  restarting the current sessions and for new sessions.
//     * FileSystemFullAccess - Boolean -  determines whether there are restrictions on access to the file
//                  system. If set to False, access will only be granted to the file
//                  system directories listed in the virtual Directories property.
//     * COMObjectFullAccess - Boolean -  determines whether there are restrictions on access to use.
//                  com object. If the value is set to False, access will only be granted to the COM classes
//                  listed in the COM classes property.
//     * AddInFullAccess - Boolean -  determines whether there are restrictions on access to the use
//                  of external components. If the value is set to False, access will only be granted to the external
//                  components listed in the external Components property.
//     * ExternalModuleFullAccess - Boolean -  determines whether there are restrictions on access to using external 
//                  modules (external reports and processing, Execute() and Compute () calls) in unsafe mode.
//                  If the value is set to False,
//                  only the external modules listed in the external Modules property can be used in unsafe mode.
//     * FullOperatingSystemApplicationAccess - Boolean -  determines whether there are restrictions on access to
//                  the use of operating system applications. If the value is set to False, you will be
//                  given the option to use only the operating system applications listed in
//                  the application property of the OS.
//     * InternetResourcesFullAccess - Boolean -  determines whether there are restrictions on access to the use
//                  of Internet resources. If the value is set to False, you will be given the option to use
//                  only the Internet resources listed in the Internet resources property.
//     * VirtualDirectories - Array of See ClusterAdministration.VirtualDirectoryProperties
//     * COMClasses - Array of See ClusterAdministration.COMClassProperties
//     * AddIns - Array of See ClusterAdministration.AddInProperties
//     * ExternalModules - Array of See ClusterAdministration.ExternalModuleProperties
//     * OSApplications - Array of See ClusterAdministration.OSApplicationProperties
//     * InternetResources - Array of See ClusterAdministration.InternetResourceProperties
//
Function SecurityProfileProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name", "");
	Result.Insert("LongDesc", "");
	Result.Insert("SafeModeProfile", False);
	Result.Insert("FullAccessToPrivilegedMode", False);
	Result.Insert("FullAccessToCryptoFunctions", False);
	
	Result.Insert("FullAccessToAllModulesExtension", False);
	Result.Insert("ModulesAvailableForExtension", "");
	Result.Insert("ModulesNotAvailableForExtension", "");
	
	Result.Insert("FullAccessToAccessRightsExtension", False);
	Result.Insert("AccessRightsExtensionLimitingRoles", "");
		
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

// Properties of the virtual folder that you are granting access to.
//
// Returns: 
//    Structure:
//     * LogicalURL - String -  logical url of the folder.
//     * PhysicalURL - String -  the physical URL of the directory on the server for hosting virtual directory data.
//     * LongDesc - String -  description of the virtual folder.
//     * DataReader - Boolean -  flag to allow reading data from the virtual directory.
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

// Properties of the COM class to which access is granted.
//
// Returns: 
//    Structure:
//     * Name - String -  name of the COM class, used as a key when searching.
//     * LongDesc - String -  description of the COM class.
//     * FileMoniker - String -  name of the file used to create the object using the global context method 
//                  Get a ComObject () with an empty value for the second parameter.
//     * CLSID - String -  representation of the COM class identifier in the MS Windows registry format
//                  without curly brackets, by which it can be created by the operating system.
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

// Properties of the external component to which access is granted.
//
// Returns: 
//    Structure:
//     * Name - String -  name of the external component, used as the search key.
//     * LongDesc - String -  description of the external component.
//     * HashSum - String -  the checksum of the allowed external component, calculated by the SHA-1 algorithm and
//                  converted to a base64 string.
//
Function AddInProperties() Export
	
	Result = New Structure();
	Result.Insert("Name");
	Result.Insert("LongDesc");
	Result.Insert("HashSum");
	Result.Insert("HashSum"); // 
	Return Result;
	
EndFunction

// Properties of the external module to which access is granted.
//
// Returns: 
//    Structure:
//     * Name - String -  the name of the external module is used as a key to search for.
//     * LongDesc - String -  description of the external module.
//     * HashSum - String -  the checksum of the allowed external module, calculated by the SHA-1 algorithm and
//                  converted to a base64 string.
//
Function ExternalModuleProperties() Export
	
	Result = New Structure();
	Result.Insert("Name");
	Result.Insert("LongDesc");
	Result.Insert("HashSum");
	Result.Insert("HashSum"); // 
	Return Result;
	
EndFunction

// Properties of the operating system application that you are granting access to.
//
// Returns: 
//    Structure:
//     * Name - String -  the name of the operating system application that is used as the search key.
//     * LongDesc - String -  description of the operating system application.
//     * CommandLinePattern - String -  application launch string template (consists of a sequence of template words
//                  separated by spaces).
//
Function OSApplicationProperties() Export
	
	Result = New Structure();
	
	Result.Insert("Name");
	Result.Insert("LongDesc");
	
	Result.Insert("CommandLinePattern");
	
	Return Result;
	
EndFunction

// Properties of the Internet resource to which access is granted.
//
// Returns: 
//    Structure:
//     * Name - String -  the name of the Internet resource used as the search key.
//     * LongDesc - String -  description of the Internet resource.
//     * Protocol - String - :
//          
//          
//          
//          
//          
//          
//          
//     * Address - String -  network address of the Internet resource without specifying the Protocol and port.
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

// Returns the properties of the security profile.
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   ProfileName - String -  name of the security profile.
//
// Returns: 
//   See ClusterAdministration.SecurityProfileProperties
//
Function SecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.SecurityProfile(
		ClusterAdministrationParameters,
		ProfileName);
	
EndFunction

// Creates a security profile based on the passed description.
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   SecurityProfileProperties - See ClusterAdministration.SecurityProfileProperties
//
Procedure CreateSecurityProfile(Val ClusterAdministrationParameters, Val SecurityProfileProperties) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.CreateSecurityProfile(
		ClusterAdministrationParameters,
		SecurityProfileProperties);
	
EndProcedure

// Sets properties for an existing security profile based on the passed description.
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   SecurityProfileProperties - See ClusterAdministration.SecurityProfileProperties
//
Procedure SetSecurityProfileProperties(Val ClusterAdministrationParameters, Val SecurityProfileProperties)  Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.SetSecurityProfileProperties(
		ClusterAdministrationParameters,
		SecurityProfileProperties);
	
EndProcedure

// Deletes the security profile.
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   ProfileName - String -  name of the security profile.
//
Procedure DeleteSecurityProfile(Val ClusterAdministrationParameters, Val ProfileName) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	AdministrationManager.DeleteSecurityProfile(
		ClusterAdministrationParameters,
		ProfileName);
	
EndProcedure

#EndRegion

#Region Infobases

// Returns the internal ID of the information database.
//
// Parameters:
//   ClusterID - String - internal ID of the server cluster.
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   InfobaseAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//
// Returns: 
//   String
//
Function InfoBaseID(Val ClusterID, Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.InfoBaseID(
		ClusterID,
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters);
	
EndFunction

// Returns descriptions of information databases.
//
// Parameters:
//   ClusterID - String - internal ID of the server cluster.
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   Filter - Structure -  the parameters of the filtering databases.
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

// Returns the internal ID of the server cluster.
//
// Parameters:
//  ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters.
//
// Returns:
//   String
//
Function ClusterID(Val ClusterAdministrationParameters) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.ClusterID(ClusterAdministrationParameters);
	
EndFunction

// Returns the description of server clusters.
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   Filter - Structure -  parameters for filtering server clusters.
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

// Returns the description of workflows.
//
// Parameters:
//   ClusterID - String - internal ID of the server cluster.
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   Filter - Structure -  the filtering options work processes.
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

// Returns the description of the production servers.
//
// Parameters:
//   ClusterID - String - internal ID of the server cluster.
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   Filter - Structure -  parameters for filtering production servers.
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

// 
//
//  (See ClusterAdministration.SessionsFilter) 
// 
//
// Parameters:
//   ClusterID - String - internal ID of the server cluster.
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   InfoBaseID - String -  internal ID of the information database.
//   Filter - See ClusterAdministration.SessionsFilter
//           See ClusterAdministration.SessionsFilter
//   UseDictionary - Boolean -  if True, the returned result will be filled in using the dictionary.
//
// Returns: 
//   - Array of See ClusterAdministration.SessionProperties
//   - Array of Map - 
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

// Returns descriptions of connections to the information base.
//
// Parameters:
//   ClusterID - String - internal ID of the server cluster.
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//   InfoBaseID - String -  internal ID of the information database.
//   InfobaseAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//   Filter - See ClusterAdministration.JoinsFilters
//           See ClusterAdministration.JoinsFilters
//   UseDictionary - Boolean -  if True, the returned result will be filled in using the dictionary.
//
// Returns: 
//   - Array of See ClusterAdministration.ConnectionProperties
//   - Array of Map - 
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

// Returns the path to the console client of the administration server.
//
// Parameters:
//   ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//
// Returns:
//   String
//
Function PathToAdministrationServerClient(Val ClusterAdministrationParameters) Export
	
	AdministrationManager = AdministrationManager(ClusterAdministrationParameters);
	
	Return AdministrationManager.PathToAdministrationServerClient();
	
EndFunction

#EndRegion

#Region Private

Procedure AddFilterCondition(Filter, Val Property, Val ValueComparisonType, Val Value) Export
	
	If Filter = Undefined Then
		
		If ValueComparisonType = ComparisonType.Equal Then
			
			Filter = New Structure;
			Filter.Insert(Property, Value);
			
		Else
			
			NewFilerItem = New Structure("Property, ComparisonType, Value", Property, ValueComparisonType, Value);
			
			Filter = New Array;
			Filter.Add(NewFilerItem);
			
		EndIf;
		
	ElsIf TypeOf(Filter) = Type("Structure") Then
		
		ExistingFilterItem = New Structure("Property, ComparisonType, Value", Filter.Key, ComparisonType.Equal, Filter.Value);
		NewFilerItem = New Structure("Property, ComparisonType, Value", Property, ValueComparisonType, Value);
		
		Filter = New Array;
		Filter.Add(ExistingFilterItem);
		Filter.Add(NewFilerItem);
		
	ElsIf TypeOf(Filter) = Type("Array") Then
		
		Filter.Add(New Structure("Property, ComparisonType, Value", Property, ValueComparisonType, Value));
		
	Else
		
		Raise NStr("en = 'Unexpected type of the Filter parameter. Expected type is <Structure> or <Array>.';");
		
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
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Invalid value type of parameter %1, expected %2 or %3.';"),
					"Filter", "Structure", "KeyAndValue");
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
		
		Return ClusterAdministrationCOM;
		
	ElsIf AdministrationParameters.AttachmentType = "RAS" Then
		
		Return ClusterAdministrationRAS;
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Unknown type of parameter %1: %2. Expected values: ""%3"" or ""%4"".';"),
			"AdministrationParameters", AdministrationParameters.AttachmentType, "COM", "RAS");
		
	EndIf;
	
EndFunction

Function DateEmpty() Export
	
	Return Date(1, 1, 1, 0, 0, 0);
	
EndFunction

Procedure SessionDataFromLock(SessionData, Val LockText, Val SessionKey, Val InfobaseName) Export
	
	TextLower = Lower(LockText);
	
	TextLower = StrReplace(TextLower, "db(",			"db(");
	TextLower = StrReplace(TextLower, "(session,",		"(session,");
	TextLower = StrReplace(TextLower, ",shared",		",separable");
	TextLower = StrReplace(TextLower, ",exceptional",	",exceptional_");
	TextLower = StrReplace(TextLower, ",exclusive",	",exceptional_");
	
	If Left(TextLower, 9) = "db(session," Then
		LockValuesAsString = Mid(TextLower, StrFind(TextLower, "(") + 1, StrFind(TextLower, ")") - StrFind(TextLower, "(") - 1);
		LockValues = StringFunctionsClientServer.SplitStringIntoSubstringsArray(LockValuesAsString, ",");
		If LockValues.Count() >= 3
			And LockValues[0] = "session"
			And LockValues[1] = Lower(InfobaseName) Then
			
			If StrFind(LockValuesAsString, "'") > 0 Then
				SeparatorValue = Mid(LockValuesAsString, StrFind(LockValuesAsString, "'") + 1);
				SeparatorValue = Left(SeparatorValue, StrFind(SeparatorValue, "'") - 1);
			Else
				SeparatorValue = "";
			EndIf;
			
			SessionData[SessionKey] = New Structure("DBLockMode, Separator", LockValues[2], SeparatorValue);
			
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion
