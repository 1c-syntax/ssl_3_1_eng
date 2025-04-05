///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ExchangeMessagesTransport.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	SetVisibilityAvailability();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompressOutgoingMessageFileOnChange(Item)
	SetVisibilityAvailability();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	If CheckFilling() Then
		
		ClosingResult = ResultOfClosureOnServer();
		Close(ClosingResult);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TestConnection(Command)
	
	ConnectionIsSet = False;
	TestConnectionAtServer(ConnectionIsSet);
		
	WarningText = ?(ConnectionIsSet, NStr("en = 'Connection established.'"),
								NStr("en = 'Cannot establish connection.'"));
								
	ShowMessageBox(, WarningText);
	
EndProcedure


#EndRegion

#Region Private

&AtServer
Function ResultOfClosureOnServer()
	
	Return ExchangeMessagesTransport.ResultOfClosingTransportForm(ThisForm);
	
EndFunction

&AtServer
Procedure TestConnectionAtServer(ConnectionIsSet)
	
	SetPrivilegedMode(True);
	
	DataProcessorObject = FormAttributeToValue("Object");
		
	// Fill password.
	ExchangeMessagesTransport.FillInSettingsFromSecureStorageForForm(ThisForm, DataProcessorObject);
	
	// Check the connection.
	ConnectionIsSet = DataProcessorObject.ConnectionIsSet();
	If Not ConnectionIsSet Then
		
		Cancel = True;
		
		ErrorMessage = DataProcessorObject.ErrorMessage
			+ Chars.LF + NStr("en = 'See the event log for details.'");
		
		Common.MessageToUser(ErrorMessage, , , , Cancel);
		
	EndIf;
		
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailability()
	Items.ArchivePasswordExchangeMessages.Enabled = Object.CompressOutgoingMessageFile;
EndProcedure

#EndRegion

