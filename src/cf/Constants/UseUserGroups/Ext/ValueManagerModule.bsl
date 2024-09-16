﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	PreviousValue2 = Constants.UseUserGroups.Get();
	
	If Value = PreviousValue2 Then
		Return;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		ErrorText =
			NStr("en = 'To change the usage of user groups, go to the app in the service.';");
		Raise ErrorText;
		
	ElsIf Common.IsSubordinateDIBNode() Then
		ErrorText =
			NStr("en = 'To change the usage of user groups, go to the infobase''s master node.';");
		Raise ErrorText;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Constants.UseExternalUserGroups.Refresh();
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf