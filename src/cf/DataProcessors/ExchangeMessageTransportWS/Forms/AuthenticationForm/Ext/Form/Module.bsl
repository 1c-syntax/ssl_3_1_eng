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
		
		Raise NStr("en = 'This is a dependent form and opens from a different form.';",
			Common.DefaultLanguageCode());
		
	EndIf;
	
	Peer = Parameters.Peer;
	TransportID = Parameters.TransportID;
	ExchangePlanName = Parameters.ExchangePlanName;
	TransportSettings = Parameters.TransportSettings;
	
	AuthenticationData = New Structure;
	
	If Common.IsStandaloneWorkplace() Then
		UserName = InfoBaseUsers.CurrentUser().Name;
		AccountPasswordRecoveryAddress = StandaloneModeInternal.AccountPasswordRecoveryAddress();
	EndIf;
	
	Items.ForgotPassword.Visible = Not IsBlankString(AccountPasswordRecoveryAddress);
	NoLongSynchronizationPrompt = True;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS")
		And DataExchangeServer.IsStandaloneWorkplace() Then
		
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		
		NoLongSynchronizationPrompt = Not ModuleStandaloneMode.LongSynchronizationQuestionSetupFlag();
		
	EndIf;
	
	Items.LongSyncWarningGroup.Visible = Not NoLongSynchronizationPrompt;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	SaveLongSynchronizationRequestFlag();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If ValueIsFilled(UserName) Then
		AuthenticationData.Insert("UserName", UserName); 
	EndIf;
	
	AuthenticationData.Insert("Password", Password);
	
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

&AtClient
Procedure ForgotPassword(Command)
	
	ExchangeMessagesTransportClient.OpenInstructionHowToChangeDataSynchronizationPassword(AccountPasswordRecoveryAddress);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SaveLongSynchronizationRequestFlag()
	
	Settings = Undefined;
	If SaveLongSynchronizationRequestFlagServer(Not NoLongSynchronizationPrompt, Settings) Then
		ChangedSettings = New Array;
		ChangedSettings.Add(Settings);
		Notify("UserSettingsChanged", ChangedSettings, ThisObject);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function SaveLongSynchronizationRequestFlagServer(Val Flag, Settings = Undefined)
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS")
		And DataExchangeServer.IsStandaloneWorkplace() Then
		
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		MustSave = Flag <> ModuleStandaloneMode.LongSynchronizationQuestionSetupFlag();
		
		If MustSave Then
			ModuleStandaloneMode.LongSynchronizationQuestionSetupFlag(Flag, Settings);
		EndIf;
		
	Else
		MustSave = False;
	EndIf;
	
	Return MustSave;
	
EndFunction

&AtServer
Function AuthenticationCheckStart(Val Peer, Val TransportID, Val AuthenticationData) Export
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Check connection to peer';", Common.DefaultLanguageCode());
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
			+ Chars.LF + NStr("en = 'See the event log for details.';");
			
		CommonClient.MessageToUser(ErrorMessage);

	Else
		
		Close(AuthenticationData);
		
	EndIf;
	
EndProcedure

#EndRegion