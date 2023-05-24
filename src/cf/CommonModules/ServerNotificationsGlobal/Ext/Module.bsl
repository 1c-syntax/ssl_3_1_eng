///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Procedure ServerNotificationsReceiptCheckHandler() Export
	
	DataReceiptStatus = ServerNotificationsClient.DataReceiptStatus();
	If DataReceiptStatus.Checking Then
		Return;
	EndIf;
	
	DataReceiptStatus.Checking = True;
	Try
		ServerNotificationsClient.CheckAndReceiveServerNotifications();
		DataReceiptStatus.Checking = False;
	Except
		DataReceiptStatus.Checking = False;
		Raise;
	EndTry;
	
EndProcedure

#EndRegion
