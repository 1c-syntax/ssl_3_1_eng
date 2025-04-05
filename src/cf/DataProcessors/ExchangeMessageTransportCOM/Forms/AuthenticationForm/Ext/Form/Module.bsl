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
	
	If Not Parameters.Property("Peer") 
		And Not Parameters.Property("TransportID") 
		And Not Parameters.Property("ExchangePlanName")
		And Not Parameters.Property("TransportSettings") Then
	
		Raise NStr("en = 'This is a dependent form and opens from a different form.'",
			Common.DefaultLanguageCode());
	
	EndIf;
		
	Peer = Parameters.Peer;
	TransportID = Parameters.TransportID;
	ExchangePlanName = Parameters.ExchangePlanName;
	TransportSettings = Parameters.TransportSettings;
	
	If Not ValueIsFilled(TransportSettings) 
		And ValueIsFilled(Peer) Then
		
		TransportSettings = ExchangeMessagesTransport.TransportSettings(
			Peer, TransportID);
			
		UserName = TransportSettings.UserName;
		
	EndIf;
	
	FillPropertyValues(Object, TransportSettings);
	
	AuthenticationData = New Structure;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	OperatingSystemAuthentication();

EndProcedure

#EndRegion


#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OperatingSystemAuthenticationOnChange(Item)
	
	OperatingSystemAuthentication();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	AuthenticationData.Insert("UserName", Object.UserName);
	AuthenticationData.Insert("UserPassword", Object.UserPassword);
	AuthenticationData.Insert("OperatingSystemAuthentication", Object.OperatingSystemAuthentication);
	
	Items.PerformingConnectionVerification.CurrentPage = Items.WaitingForConnectionVerification;
	
	BackgroundJob = AuthenticationCheckStart(
		?(ValueIsFilled(Peer), Peer, ExchangePlanName),
		TransportID,
		AuthenticationData);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	
	Handler = New CallbackDescription("AuthenticationCheckCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
	
EndProcedure
	
&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OperatingSystemAuthentication()
	
	Items.UserName.Enabled = Not Object.OperatingSystemAuthentication;
	Items.UserPassword.Enabled = Not Object.OperatingSystemAuthentication;
	
EndProcedure

&AtServer
Function AuthenticationCheckStart(Peer, TransportID, AuthenticationData) Export
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Check connection to peer'", Common.DefaultLanguageCode());
	ExecutionParameters.WaitCompletion = 0;
		
	Return TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"ExchangeMessagesTransport.VerifyAuthentication",
		Peer, TransportID, TransportSettings, AuthenticationData);
	
EndFunction
	
&AtClient
Procedure AuthenticationCheckCompletion(BackgroundJob, AdditionalParameters) Export 
	
	If BackgroundJob = Undefined Then
		
		Return;
	
	ElsIf BackgroundJob.Status = "Error" Then 
		
		Items.PerformingConnectionVerification.CurrentPage = Items.UserPasswordRequest;
		ErrorMessage = BackgroundJob.BriefErrorDescription
			+ Chars.LF + NStr("en = 'See the event log for details.'");
			
		CommonClient.MessageToUser(ErrorMessage);

	Else
		
		If ValueIsFilled(Peer) Then
			SaveTransportSettings();
		EndIf;
		
		Close(AuthenticationData);
		
	EndIf;
	
EndProcedure

&AtServer 
Procedure SaveTransportSettings()
	
	PasswordId = String(New UUID);
	Common.WriteDataToSecureStorage(PasswordId, Object.UserPassword);

	TransportSettings.Insert("UserName", Object.UserName);
	TransportSettings.Insert("OperatingSystemAuthentication", Object.OperatingSystemAuthentication);
	TransportSettings.Insert("UserPassword", PasswordId);
	TransportSettings.Insert("ContinueSettings", False);
		
	ExchangeMessagesTransport.SaveTransportSettings(
		Peer, TransportID, TransportSettings, True);

EndProcedure

#EndRegion

