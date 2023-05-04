///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlersForm

&AtClient
Procedure OnOpen(Cancel)
	
	If FormOwner = Undefined Then
		WindowOpeningMode = FormWindowOpeningMode.LockWholeInterface;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	NotifyChoice(ServiceUserPassword);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	ErrorText = "";
	
	If TypeOf(ThisObject.OnCloseNotifyDescription) = Type("NotifyDescription") Then
		ServiceUserPassword = Password;
		Try
			ExecuteNotifyProcessing(ThisObject.OnCloseNotifyDescription, ServiceUserPassword);
		Except
			ErrorInfo = ErrorInfo();
			WriteTheErrorToTheLog(ErrorProcessing.DetailErrorDescription(ErrorInfo));
			ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo) + Chars.LF
				+ NStr("en = 'Password may be incorrect. Retype the password.';");
		EndTry;
		ThisObject.OnCloseNotifyDescription = Undefined;
	EndIf;
	
	Close();
	
	If ValueIsFilled(ErrorText) Then
		ShowMessageBox(, ErrorText);
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure WriteTheErrorToTheLog(ErrorText)
	
	WriteLogEvent(
		NStr("en = 'Runtime error';", Common.DefaultLanguageCode()),
		EventLogLevel.Error,,, ErrorText);
	
EndProcedure

#EndRegion
