///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var FormClosing;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Id <> Undefined Then
		
		IntegrationDetails = CollaborationSystem.GetIntegration(Parameters.Id);
		If IntegrationDetails <> Undefined Then
			Description = IntegrationDetails.Presentation;
			Token = IntegrationDetails.ExternalSystemParameters.Get("token");
			Canal = IntegrationDetails.ExternalSystemParameters.Get("channel");
			EndpointURL = IntegrationDetails.EndpointURL;
			
			Attendees.Clear();
			For Each IBUser In Conversations.InfoBaseUsers(IntegrationDetails.Members) Do
				Attendees.Add().User = IBUser.Value;
			EndDo;	
		EndIf;
		
		IsIntegrationUsed = IntegrationDetails.Use;
		If IsIntegrationUsed Then
			Items.Close.Title = NStr("en = 'Save and close'");
			Items.Disconnect.Visible = True;
		EndIf;
		
	EndIf;
	
	ConversationsLocalization.OnFillInstructionOnIntegrationConnect(Items.Instruction.Title, 
		ConversationsInternalClientServer.ExternalSystemsTypes().WhatsApp);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	If FormClosing = True And Not Exit Then
		Close(True);
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttendees

&AtClient
Procedure AttendeesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	For Each PickedUser In ValueSelected Do
		If Attendees.FindRows(New Structure("User", PickedUser)).Count() = 0 Then
			Attendees.Add().User = PickedUser;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	ConversationsInternalClient.StartPickingConversationParticipants(Items.Attendees);
EndProcedure

&AtClient
Procedure ActivateBot(Command)

	If FormClosing = True Then
		Close(True);
		Return;
	EndIf;
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Try
		ActivateServer();
	Except
		ErrorInfo = ErrorInfo();
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
			NStr("en = 'Cannot enable the chat bot due to:'"), True);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;

	If IsIntegrationUsed Then
		Close(True);
		Return;		
	EndIf;
	
	Items.Close.Title = NStr("en = 'Close'");
	FormClosing = True;

EndProcedure

&AtClient
Procedure Disconnect(Command)
	
	Try
		DisconnectServer();
	Except
		ErrorInfo = ErrorInfo();
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
			NStr("en = 'Cannot disable the chat bot due to:'"), True);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	Close(True);
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ActivateServer()
	
	IntegrationParameters = ConversationsInternal.IntegrationParameters();
	IntegrationParameters.Id = Parameters.Id;
	IntegrationParameters.Key = Description; 
	IntegrationParameters.Type = ConversationsInternalClientServer.ExternalSystemsTypes().WhatsApp;
	IntegrationParameters.Attendees = Attendees.Unload(, "User").UnloadColumn("User");
	IntegrationParameters.token = Token;
	IntegrationParameters.channel = Canal;
	
	Try
		IntegrationDetails = ConversationsInternal.CreateChangeIntegration(IntegrationParameters);
		// Collaboration System requires a secondary call.
		Integration = CollaborationSystem.GetIntegration(IntegrationDetails.ID);
	Except
		WriteLogEvent(ConversationsInternal.EventLogEvent(),
			EventLogLevel.Error, , ,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	If Integration <> Undefined Then
		EndpointURL = Integration.EndpointURL;
	EndIf;
	
EndProcedure

&AtServer
Procedure DisconnectServer()
	ConversationsInternal.DisableIntegration(Parameters.Id);
EndProcedure

#EndRegion
