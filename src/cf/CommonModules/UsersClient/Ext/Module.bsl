///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// See Users.AuthorizedUser.
Function AuthorizedUser() Export
	
	Return StandardSubsystemsClient.ClientParameter("AuthorizedUser");
	
EndFunction

// See Users.CurrentUser.
Function CurrentUser() Export
	
	Return UsersInternalClientServer.CurrentUser(AuthorizedUser());
	
EndFunction

// See Users.IsExternalUserSession.
Function IsExternalUserSession() Export
	
	Return StandardSubsystemsClient.ClientParameter("IsExternalUserSession");
	
EndFunction

// 
// 
// Parameters:
//  CheckSystemAdministrationRights - See Users.IsFullUser.CheckSystemAdministrationRights
//
// Returns:
//  Boolean - 
//
Function IsFullUser(CheckSystemAdministrationRights = False) Export
	
	If CheckSystemAdministrationRights Then
		Return StandardSubsystemsClient.ClientParameter("IsSystemAdministrator");
	Else
		Return StandardSubsystemsClient.ClientParameter("IsFullUser");
	EndIf;
	
EndFunction

#EndRegion
