///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

Function AreClientNotificationsAvailable() Export
	
	If IsForTestingOnly() Then
		Return False;
	EndIf;
	
	SystemInfo = New SystemInfo;
	Version = SystemInfo.AppVersion;
	
	Return CommonClientServer.CompareVersions(Version, "8.3.26.1498") >= 0
	      And CommonClientServer.CompareVersions(Version, "8.3.27.0") < 0
	    Or CommonClientServer.CompareVersions(Version, "8.3.27.1288") >= 0;
	
EndFunction

Function IsForTestingOnly()
	
	Return True;
	
EndFunction

Function ServerNotificationsNotificationsKey() Export
	
	Return "StandardSubsystems.Core.ServerNotifications";
	
EndFunction

#EndRegion
