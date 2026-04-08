///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// See StandardSubsystemsClient.OnReceiptServerNotification
Procedure OnReceiptServerNotification(NameOfAlert, Result) Export
	
	If NameOfAlert <> EmailOperationsInternalClientServer.ServerNotificationName() Then
		Return;
	EndIf;
	
	If Result.EventName = "OpenAuthorizationOfMailService" Then
		Notify("OpenAuthorizationOfMailService", Result.Context);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function SupportRequestTopic(Val TechnicalInformation) Export
	
	MainReason = StrReplace(TechnicalInformation, Chars.LF, " ");
	
	LengthLimitation = 500;
	MainReason = Left(MainReason, LengthLimitation);
	
	Template = NStr("en = 'Configure email: %1'");
	Result = StringFunctionsClientServer.SubstituteParametersToString(Template, MainReason);
	
	Return Result;
	
EndFunction

Function SupportRequestText(Val Email, Val TechnicalInformation) Export
	
	MainReason = StrReplace(TechnicalInformation, Chars.LF, " ");
	
	Template = NStr("en = 'Issue when configuring email %1: %2.
		|
		|<Describe the issue and attach screenshots>'");
	
	Result = StringFunctionsClientServer.SubstituteParametersToString(
		Template,
		Email,
		MainReason);
	
	Return Result;
	
EndFunction

#EndRegion
