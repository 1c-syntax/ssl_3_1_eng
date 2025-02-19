///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Internal

Function Connected2() Export
	
	Return ConversationsInternalServerCall.Connected2();
	
EndFunction

Procedure ShowConnection(CompletionDetails = Undefined) Export
	
	OpenForm("DataProcessor.EnableDiscussions.Form",,,,,, CompletionDetails);
	
EndProcedure

Procedure ShowDisconnection() Export
	
	If Not ConversationsInternalServerCall.Connected2() Then 
		ShowMessageBox(, NStr("en = 'Conversations are already disabled.';"));
		Return;
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add("Disconnect", NStr("en = 'Disable';"));
	Buttons.Add(DialogReturnCode.No);
	
	Notification = New CallbackDescription("AfterResponseToDisablePrompt", ThisObject);
	
	ShowQueryBox(Notification, NStr("en = 'Do you want to disable conversations?';"),
		Buttons,, DialogReturnCode.No);
	
EndProcedure

Procedure AfterWriteUser(Form, CompletionDetails) Export
	
	If Not Form.SuggestDiscussions Then
		RunCallback(CompletionDetails);
		Return;
	EndIf;
	
	Form.SuggestDiscussions = False;
		
	CallbackOnCompletion = New CallbackDescription("SuggestDiscussionsCompletion", ThisObject, CompletionDetails);
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.PromptDontAskAgain = True;
	QuestionParameters.Title = NStr("en = 'Conversations (collaboration system)';");
	StandardSubsystemsClient.ShowQuestionToUser(CallbackOnCompletion, Form.SuggestConversationsText,
		QuestionDialogMode.YesNo, QuestionParameters);
	
EndProcedure

Procedure OnGetCollaborationSystemUsersChoiceForm(ChoicePurpose, Form, ConversationID, Parameters, SelectedForm, StandardProcessing) Export

	Parameters.Insert("SelectConversationParticipants", True);
	Parameters.Insert("ChoiceMode", True);
	Parameters.Insert("CloseOnChoice", False);
	Parameters.Insert("MultipleChoice", True);
	Parameters.Insert("AdvancedPick", True);
	Parameters.Insert("SelectedUsers", New Array);
	Parameters.Insert("PickFormHeader", NStr("en = 'Conversation members';"));
	
	StandardProcessing = False;
	
	SelectedForm = "Catalog.Users.ChoiceForm";

EndProcedure

Procedure ShowSettingOfIntegrationWithExternalSystems() Export
	OpenForm("DataProcessor.EnableDiscussions.Form.SettingsOfMessagesFromOtherApps",,ThisObject);
EndProcedure

Procedure OnStart(Parameters) Export
	
	CommandsGenerationHandler = New CallbackDescription("WhenFormingCommandsOfInteractionSystem", ThisObject);
	CollaborationSystem.AttachGenerateCommandsHandler(CommandsGenerationHandler);
	
EndProcedure

#EndRegion

#Region Private

Procedure StartPickingConversationParticipants(Item) Export
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CloseOnChoice", False);
	FormParameters.Insert("MultipleChoice", True);
	FormParameters.Insert("AdvancedPick", True);
	FormParameters.Insert("SelectedUsers", New Array);
	FormParameters.Insert("PickFormHeader", NStr("en = 'Conversation members';"));
	
	OpenForm("Catalog.Users.ChoiceForm", FormParameters,Item,,,,,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

Procedure ShowIntegrationInformation(Form, IntegrationDetails, IntegrationChangeNotification) Export

	Notification = New CallbackDescription("IntegrationCreationCompletion", ThisObject,
		New Structure("Notification", IntegrationChangeNotification));
		
	IntegrationTypes = ConversationsInternalClientServer.ExternalSystemsTypes();
	FormName = "DataProcessor.EnableDiscussions.Form";
	If IntegrationDetails.Type = IntegrationTypes.Telegram Then
		FormName = FormName + ".TelegramBotCreation";
	ElsIf IntegrationDetails.Type = IntegrationTypes.VKontakte Then	
		FormName = FormName + ".BotCreationVKontakte";
	ElsIf IntegrationDetails.Type = IntegrationTypes.WhatsApp Then	
		FormName = FormName + ".WhatsAppBotCreation";
	ElsIf IntegrationDetails.Type = IntegrationTypes.WebChat Then	
		FormName = FormName + ".WebChatBotCreation";
	ElsIf IntegrationDetails.Type = IntegrationTypes.Webhook Then	
		FormName = FormName + ".WebhookBotCreation";
	EndIf;
		
	OpenForm(FormName, IntegrationDetails, Form,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

Procedure IntegrationCreationCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	RunCallback(AdditionalParameters.Notification, True);

EndProcedure

Procedure AfterResponseToDisablePrompt(ReturnCode, Context) Export
	
	If ReturnCode = "Disconnect" Then 
		OnDisconnect();
	EndIf;
	
EndProcedure

Procedure OnDisconnect()
	
	Notification = New CallbackDescription("AfterDisconnectSuccessfully", ThisObject,,
		"OnProcessDisableDiscussionError", ThisObject);
	
	Try
		CollaborationSystem.BeginInfoBaseUnregistration(Notification);
	Except
		OnProcessDisableDiscussionError(ErrorInfo(), False, Undefined);
	EndTry;
	
EndProcedure

Procedure AfterDisconnectSuccessfully(Context) Export
	
	Notify("ConversationsEnabled", False);
	
EndProcedure

Procedure OnProcessDisableDiscussionError(ErrorInfo, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	
	EventLogClient.AddMessageForEventLog(
		NStr("en = 'Conversations.An error occurred when unregistering infobase';",
			CommonClient.DefaultLanguageCode()),
		"Error",
		ErrorProcessing.DetailErrorDescription(ErrorInfo),, True);
	
	StandardSubsystemsClient.OutputErrorInfo(ErrorInfo);
	
EndProcedure

Procedure SuggestDiscussionsCompletion(Result, CompletionDetails) Export
	
	If Result = Undefined Then
		RunCallback(CompletionDetails);
		Return;
	EndIf;
	
	If Result.NeverAskAgain Then
		CommonServerCall.CommonSettingsStorageSave("ApplicationSettings", "SuggestDiscussions", False);
	EndIf;
	
	If Result.Value = DialogReturnCode.Yes Then
		ShowConnection();
		Return;
	EndIf;
	RunCallback(CompletionDetails);
	
EndProcedure

Procedure WhenFormingCommandsOfInteractionSystem(CommandsParameters, Commands, DefaultCommand, AdditionalParameters) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.UserReminders") Then
		ModuleUserReminderInternalClient = CommonClient.CommonModule("UserRemindersInternalClient");
		ModuleUserReminderInternalClient.AddConversationsCommands(CommandsParameters, Commands, DefaultCommand);
	EndIf;
	
	CheckActionBeingPerformed(CommandsParameters, Commands, DefaultCommand);
	
EndProcedure

Procedure CheckActionBeingPerformed(CommandsParameters, Commands, DefaultCommand)
	
	If Not ShowSecurityAlert(CommandsParameters) Then
		Return;
	EndIf;
	
	CommandsToRemove = New Array;
	
	For IndexOf = -Commands.UBound() To 0 Do
		If Commands[-IndexOf].Command = CollaborationSystemStandardCommand.OpenAttachment Then
			Commands.Delete(IndexOf);
		EndIf;
	EndDo;
	
	If Not ConversationsInternalServerCall.ItIsPossibleToOpenExternalReportsAndTreatments() Then
		DefaultCommand = New CollaborationSystemCommandDescription(
			CollaborationSystemStandardCommand.SaveAttachment);
		Return;
	EndIf;
	
	NotifyDescription = New CallbackDescription("ShowSecurityWarning", ThisObject, CommandsParameters);
	DefaultCommand = New CollaborationSystemCommandDescription(NotifyDescription);
	
EndProcedure

Function ShowSecurityAlert(CommandsParameters)
	
	IsItExternalReportOrProcessing = False;
	
	If CommandsParameters.Attachment <> Undefined Then
		File = New File (CommandsParameters.Attachment.Description);
		IsItExternalReportOrProcessing = Lower(File.Extension) = ".erf" Or Lower(File.Extension) = ".epf";
	EndIf;
	
	Return IsItExternalReportOrProcessing
		And AllowedAttachments()[AttachmentID(CommandsParameters)] <> True
		
EndFunction

Procedure ShowSecurityWarning(CommandsParameters) Export
	
	NotifyDescription = New CallbackDescription("ContinueOpeningAttachment", ThisObject, CommandsParameters);
	UsersInternalClient.ShowSecurityWarning(NotifyDescription,
		UsersInternalClientServer.SecurityWarningKinds().BeforeAddExternalReportOrDataProcessor);
	
EndProcedure

Procedure ContinueOpeningAttachment(Result, CommandsParameters) Export

	If Result <> "Continue" Then
		Return;
	EndIf;
	
	AllowedAttachments()[AttachmentID(CommandsParameters)] = True;
	
	NotifyDescription = New CallbackDescription("WhenOpeningThreadToReadAttachment",
		ThisObject, CommandsParameters.Attachment);
	
	CommandsParameters.Attachment.BeginOpenStreamForRead(NotifyDescription);
	
EndProcedure

Procedure WhenOpeningThreadToReadAttachment(Stream, Attachment) Export

	If Stream = Undefined Then
		Return;
	EndIf;
	
	BinaryDataBuffer = New BinaryDataBuffer(Attachment.Size);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("BinaryDataBuffer", BinaryDataBuffer);
	AdditionalParameters.Insert("Attachment", Attachment);

	NotifyDescription = New CallbackDescription("AtEndOfReadingThread", ThisObject, AdditionalParameters);
	
	Stream.BeginReading(NotifyDescription, BinaryDataBuffer, 0, Attachment.Size);

EndProcedure

Procedure AtEndOfReadingThread(Count, AdditionalParameters) Export
	
	BinaryDataBuffer = AdditionalParameters.BinaryDataBuffer;
	Attachment = AdditionalParameters.Attachment;
	BinaryData = GetBinaryDataFromBinaryDataBuffer(BinaryDataBuffer);
	AddressInTempStorage = PutToTempStorage(BinaryData);
	
	File = New File(Attachment.Description);
	
	If Lower(File.Extension) = ".epf" Then
		DataProcessorName = ConversationsInternalServerCall.AttachExternalDataProcessor(AddressInTempStorage);
		OpenForm("ExternalDataProcessor."+ DataProcessorName +".Form");
	ElsIf File.Extension = ".erf" Then
		ReportName = ConversationsInternalServerCall.ConnectExternalReport(AddressInTempStorage);
		OpenForm("ExternalReport."+ ReportName +".Form");
	EndIf;	
	
EndProcedure

Function AttachmentID(CommandsParameters)
	
	If CommandsParameters.Attachment = Undefined Then
		Return Undefined;
	EndIf;

	Return StrTemplate("%1_%2_%3",
		CommandsParameters.Message.Id,
		CommandsParameters.Attachment.Description,
		CommandsParameters.Attachment.Size);
		
EndFunction
	
Function AllowedAttachments()

	ParameterName = "StandardSubsystems.Conversations.AllowedAttachments";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Map);
	EndIf;
	
	Return ApplicationParameters[ParameterName];

EndFunction

#EndRegion