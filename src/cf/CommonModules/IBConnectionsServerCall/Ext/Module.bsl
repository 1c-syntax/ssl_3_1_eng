///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// See IBConnections.ConnectionsInformation.
Function ConnectionsInformation(GetConnectionString = False, MessagesForEventLog = Undefined, ClusterPort = 0) Export
	
	Return IBConnections.ConnectionsInformation(GetConnectionString, MessagesForEventLog, ClusterPort);
	
EndFunction

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
Function SetConnectionLock(MessageText = "", KeyCode = "KeyCode", // 
	WaitingForTheStartOfBlocking = 0, LockDuration = 0) Export 
	
	Return IBConnections.SetConnectionLock(
		MessageText, KeyCode, WaitingForTheStartOfBlocking, LockDuration);
	
EndFunction

// Remove the information database lock.
//
// Returns:
//   Boolean   - 
//              
//
Function AllowUserAuthorization() Export
	
	Return IBConnections.AllowUserAuthorization();
	
EndFunction

#EndRegion

#Region Private

// Get parameters for blocking is connections for use on the client side.
//
// Parameters:
//  GetSessionCount - Boolean -  if True,
//                                       the number of Sessions field is filled in in the returned structure.
//
// Returns:
//   Structure:
//     Set-Boolean-True if the lock is set, False-Otherwise. 
//     Start-date - the start date of the block. 
//     End-date - the end date of the block. 
//     Message-String-message to the user. 
//     Waiting interval for user work completion-Number - the interval in seconds.
//     Number of sessions - 0 if the parameter getcounty of Sessions = False.
//     Current session date - the current date of the session.
//
Function SessionLockParameters(GetSessionCount = False) Export
	
	Return IBConnections.SessionLockParameters(GetSessionCount);
	
EndFunction

// To set the blocking sessions pane data.
// 
// Parameters:
//   Parameters         - 
//   LocalTime - Boolean -  the lock start and end times are specified in the local session time.
//                                If False, then in universal time.
//
Procedure SetDataAreaSessionLock(Parameters, LocalTime = True) Export
	
	IBConnections.SetDataAreaSessionLock(Parameters, LocalTime);
	
EndProcedure

Function AdministrationParameters() Export
	Return StandardSubsystemsServer.AdministrationParameters();
EndFunction

Procedure DeleteAllSessionsExceptCurrent(AdministrationParameters) Export
	
	AllExceptCurrent = New Structure;
	AllExceptCurrent.Insert("Property", "Number");
	AllExceptCurrent.Insert("ComparisonType", ComparisonType.NotEqual);
	AllExceptCurrent.Insert("Value", InfoBaseSessionNumber());
	
	Filter = New Array;
	Filter.Add(AllExceptCurrent);
	
	ClusterAdministration.DeleteInfobaseSessions(AdministrationParameters,, Filter);
	
EndProcedure

#EndRegion