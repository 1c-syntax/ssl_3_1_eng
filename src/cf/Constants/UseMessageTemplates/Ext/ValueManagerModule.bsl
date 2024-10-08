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
	
	If Value Then
		CanSendSMSMessage = Common.SubsystemExists("StandardSubsystems.SendSMSMessage") 
			And Not Common.SubsystemExists("StandardSubsystems.AttachableCommands");
		EmailOperationsAvailable = Common.SubsystemExists("StandardSubsystems.EmailOperations")
			And Not Common.SubsystemExists("StandardSubsystems.AttachableCommands");
	Else
		CanSendSMSMessage = False;
		EmailOperationsAvailable = False;
	EndIf;
	
	Constants.UseSMSMessagesSendingInMessageTemplates.Set(CanSendSMSMessage);
	Constants.UseEmailInMessageTemplates.Set(EmailOperationsAvailable);
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf