///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns the full path to the information database (connection string).
//
// Parameters:
//  FileModeFlag  - Boolean -  output parameter. Take the values.
//                                     True if the current IB is a file system;
//                                     False - if client-server.
//  ServerClusterPort    - Number  -  input parameter. Set if
//                                     the server cluster uses a non-standard port number.
//                                     The default value is 0, which means that 
//                                     the server cluster occupies the default port number.
//
// Returns:
//   String   -  the connection string is.
//
Function InfobasePath(FileModeFlag = Undefined, Val ServerClusterPort = 0) Export
	
	ConnectionString = InfoBaseConnectionString();
	
	SearchPosition = StrFind(Upper(ConnectionString), "FILE=");
	
	If SearchPosition = 1 Then // 
		
		IBPath = Mid(ConnectionString, 6, StrLen(ConnectionString) - 6);
		FileModeFlag = True;
		
	Else
		FileModeFlag = False;
		
		SearchPosition = StrFind(Upper(ConnectionString), "SRVR=");
		
		If Not (SearchPosition = 1) Then
			Return Undefined;
		EndIf;
		
		SemicolonPosition = StrFind(ConnectionString, ";");
		StartPositionForCopying = 6 + 1;
		EndPositionForCopying = SemicolonPosition - 2;
		
		ServerName = Mid(ConnectionString, StartPositionForCopying, EndPositionForCopying - StartPositionForCopying + 1);
		
		ConnectionString = Mid(ConnectionString, SemicolonPosition + 1);
		
		// 
		SearchPosition = StrFind(Upper(ConnectionString), "REF=");
		
		If Not (SearchPosition = 1) Then
			Return Undefined;
		EndIf;
		
		StartPositionForCopying = 6;
		SemicolonPosition = StrFind(ConnectionString, ";");
		EndPositionForCopying = SemicolonPosition - 2;
		
		IBNameAtServer = Mid(ConnectionString, StartPositionForCopying, EndPositionForCopying - StartPositionForCopying + 1);
		
		IBPath = """" + ServerName + "\" + IBNameAtServer + """";
	EndIf;
	
	Return IBPath;
	
EndFunction

#EndRegion

#Region Private

// Deletes all sessions of the information database except the current one.
//
Procedure DeleteAllSessionsExceptCurrent(AdministrationParameters) Export
	
	IBConnectionsServerCall.DeleteAllSessionsExceptCurrent(AdministrationParameters);
	
EndProcedure

// Returns the text constant for the formation of messages.
// Used for localization purposes.
//
// Returns:
//  String - 
//
Function TextForAdministrator() Export
	
	Return NStr("en = 'Message for administrator:';");
	
EndFunction

// Returns the custom text of the session lock message.
//
// Parameters:
//   Message - String -  complete message.
// 
// Returns:
//  String - 
//
Function ExtractLockMessage(Val Message) Export
	
	MarkerIndex = StrFind(Message, TextForAdministrator());
	If MarkerIndex = 0  Then
		Return Message;
	ElsIf MarkerIndex >= 3 Then
		Return Mid(Message, 1, MarkerIndex - 3);
	Else
		Return "";
	EndIf;
		
EndFunction

#EndRegion
