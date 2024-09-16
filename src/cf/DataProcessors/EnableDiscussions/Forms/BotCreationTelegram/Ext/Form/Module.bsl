///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Id <> Undefined Then
		IntegrationDetails = CollaborationSystem.GetIntegration(Parameters.Id);
		
		If IntegrationDetails <> Undefined Then
			Description = IntegrationDetails.Presentation;
			Token = IntegrationDetails.ExternalSystemParameters.Get("token");
			
			Attendees.Clear();
			For Each IBUser In Conversations.InfoBaseUsers(IntegrationDetails.Members) Do
				Attendees.Add().User = IBUser.Value;
			EndDo;
		EndIf;
		
		If IntegrationDetails.Use Then
			Items.Close.Title = NStr("en = 'Save and close';");
			Items.Disconnect.Visible = True;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	ConversationsInternalClient.StartPickingConversationParticipants(Items.Attendees);
EndProcedure

&AtClient
Procedure ActivateBot(Command)
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Try
		ActivateServer();
		Close(True);
	Except
		ShowMessageBox(, NStr("en = 'Cannot enable the chat bot due to:';")
			+ Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
EndProcedure

&AtServer
Procedure ActivateServer()
	
	IntegrationParameters = ConversationsInternal.IntegrationParameters();
	IntegrationParameters.Id = Parameters.Id;
	IntegrationParameters.Key = Description; 
	IntegrationParameters.Type = ConversationsInternalClientServer.ExternalSystemsTypes().Telegram;
	IntegrationParameters.Attendees = Attendees.Unload(,"User").UnloadColumn("User");
	IntegrationParameters.token = Token;
	
	Try
		ConversationsInternal.CreateChangeIntegration(IntegrationParameters);
	Except
		WriteLogEvent(ConversationsInternal.EventLogEvent(),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;

EndProcedure

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

&AtClient
Procedure Disconnect(Command)
	Try
		DisconnectServer();
	    Close(True);
	Except
		ShowMessageBox(, NStr("en = 'Cannot disable the chat bot due to:';")
			+ Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
EndProcedure

&AtServer
Procedure DisconnectServer()
	ConversationsInternal.DisableIntegration(Parameters.Id);
EndProcedure

#EndRegion

