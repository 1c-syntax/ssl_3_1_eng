///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// See Users.AuthorizedUser.
// See UsersClient.AuthorizedUser.
//
Function AuthorizedUser() Export
	
// 
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return Users.AuthorizedUser();
#Else
	Return UsersClient.AuthorizedUser();
#EndIf
// 
	
EndFunction

// Deprecated.
// See Users.CurrentUser.
// See UsersClient.CurrentUser.
//
Function CurrentUser() Export
	
// 
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return Users.CurrentUser();
#Else
	Return UsersClient.CurrentUser();
#EndIf
// 
	
EndFunction

// Deprecated.
// See ExternalUsers.CurrentExternalUser.
// See ExternalUsersClient.CurrentExternalUser.
//
Function CurrentExternalUser() Export
	
// 
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return ExternalUsers.CurrentExternalUser();
#Else
	Return ExternalUsersClient.CurrentExternalUser();
#EndIf
// 
	
EndFunction

// Deprecated.
// See Users.IsExternalUserSession.
// See UsersClient.IsExternalUserSession.
//
Function IsExternalUserSession() Export
	
// 
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return Users.IsExternalUserSession();
#Else
	Return UsersClient.IsExternalUserSession();
#EndIf
// 
	
EndFunction

#EndRegion

#EndRegion
