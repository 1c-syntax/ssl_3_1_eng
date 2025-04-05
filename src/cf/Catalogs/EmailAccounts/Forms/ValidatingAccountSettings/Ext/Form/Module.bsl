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
	
	ErrorsMessages = Parameters.ErrorText;
	
	If ValueIsFilled(ErrorsMessages) Then
		Title = Parameters.Title;
		AutoTitle = False;
		FillinExplanations();
		SetKeyToSaveWindowPosition();
	Else
		Items.FormClose.Title = NStr("en = 'Cancel'");
		Items.FormGoToSettings.Visible = False;
	EndIf;
	
	Items.Pages.CurrentPage = Items.SettingsCheckInProgress;
	
	Items.FormBack.Visible = False;
	Items.AssistanceRequiredGroup.Visible = False;
	
	// 
	If Common.SubsystemExists("StandardSubsystems.ContactingTechnicalSupport") Then
		
		ModuleForContactingTechnicalSupportService = Common.CommonModule(
			"ContactingTechnicalSupportInternal");
		
		ModuleForContactingTechnicalSupportService.OnCreateAtServer(ThisObject);
		
	Else
		Items.AssistanceRequiredGroup.Visible = False;
	EndIf;
	// End StandardSubsystems.ContactingTechnicalSupport
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("ExecuteSettingsCheck", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RecommendationsPossibleReasonsForProcessingNavigationLink(Item, Var_URL, StandardProcessing)
	
	If CommonClientServer.URIStructure(Var_URL).Schema = "" Then
		StandardProcessing = False;
		PatchID = Var_URL;
		GotoMailSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationTechnicalDetailsClick(Item)
	
	Items.Pages.CurrentPage = Items.TechnicalDetails;
	Items.FormBack.Visible = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToSettings(Command)
	
	GotoMailSettings();
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	Items.Pages.CurrentPage = Items.ErrorsFoundOnCheck;
	Items.FormBack.Visible = False;
	
EndProcedure

&AtClient
Procedure QuestionInSupport(Command)
	
	// 
	If CommonClient.SubsystemExists("StandardSubsystems.ContactingTechnicalSupport") Then
		
		ModuleForContactingTechnicalSupportServiceClient = CommonClient.CommonModule(
			"ContactingTechnicalSupportInternalClient");
		
		RequestParameters_ = ModuleForContactingTechnicalSupportServiceClient.RequestParameters_();
		RequestParameters_.TechnologicalInfo = SupportInformation;
		RequestParameters_.EventLogFilter.Insert("StartDate", ErrorRegistrationTime);
		
		RequestParameters_.Subject = EmailOperationsInternalClient.SubjectOfSupportRequest(
			ErrorsMessages);
		
		RequestParameters_.Message = EmailOperationsInternalClient.TextOfSupportRequest(
			Parameters.Account,
			ErrorsMessages);
		
		ModuleForContactingTechnicalSupportServiceClient.SendQuestionToSupport(
			ThisObject,
			RequestParameters_);
		
	EndIf;
	// End StandardSubsystems.ContactingTechnicalSupport
	
EndProcedure

&AtClient
Procedure InformationToSendToSupport(Command)
	
	// 
	If CommonClient.SubsystemExists("StandardSubsystems.ContactingTechnicalSupport") Then
		
		ModuleForContactingTechnicalSupportServiceClient = CommonClient.CommonModule(
			"ContactingTechnicalSupportInternalClient");
		
		RequestParameters_ = ModuleForContactingTechnicalSupportServiceClient.RequestParameters_();
		RequestParameters_.TechnologicalInfo = SupportInformation;
		RequestParameters_.EventLogFilter.Insert("StartDate", ErrorRegistrationTime);
		
		ModuleForContactingTechnicalSupportServiceClient.DownloadInformationToSendToSupport(
			ThisObject,
			RequestParameters_);
		
	EndIf;
	// End StandardSubsystems.ContactingTechnicalSupport
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ExecuteSettingsCheck()
	TimeConsumingOperation = StartExecutionAtServer();
	CallbackOnCompletion = New CallbackDescription("ProcessResult", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
EndProcedure

&AtServer
Function StartExecutionAtServer()
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "Catalogs.EmailAccounts.ValidateAccountSettings",
		Parameters.Account);
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure ProcessResult(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Items.FormClose.Title = NStr("en = 'Close'");
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	CheckResult = GetFromTempStorage(Result.ResultAddress);
	
	SupportInformation = CheckResult.ConnectionErrors;
	ExecutedChecks = CheckResult.ExecutedChecks;
	
	If ValueIsFilled(SupportInformation) Then
		
		If Not ValueIsFilled(ErrorsMessages) Then
			ErrorsMessages = StrConcat(CheckResult.ErrorsTexts, Chars.LF);
			FillinExplanations();
		EndIf;
		
		Items.Pages.CurrentPage = Items.ErrorsFoundOnCheck;
		
		ErrorRegistrationTime = CommonClient.SessionDate();
		ShowHelpNeededSection();
		
	Else
		Items.Pages.CurrentPage = Items.CheckCompletedSuccessfully;
	EndIf;
	
EndProcedure

&AtServer
Procedure ShowHelpNeededSection()
	
	// 
	If Common.SubsystemExists("StandardSubsystems.ContactingTechnicalSupport") Then
		
		ModuleForContactingTechnicalSupportService = Common.CommonModule(
			"ContactingTechnicalSupportInternal");
		
		ModuleForContactingTechnicalSupportService.ShowHelpNeededSection(Items);
		
	EndIf;
	// End StandardSubsystems.ContactingTechnicalSupport
	
EndProcedure

&AtServer
Procedure FillinExplanations()
	
	ExplanationOnError = EmailOperationsInternal.ExplanationOnError(ErrorsMessages);
	
	PossibleReasons = EmailOperationsInternal.FormattedList(ExplanationOnError.PossibleReasons);
	MethodsToFixError = EmailOperationsInternal.FormattedList(ExplanationOnError.MethodsToFixError);
	
	Items.DecorationRecommendations.Title = MethodsToFixError;
	Items.DecorationPossibleReasons.Title = PossibleReasons;
	
EndProcedure

&AtServer
Procedure SetKeyToSaveWindowPosition()
	
	WindowOptionsKey = Common.CheckSumString(String(PossibleReasons) + String(MethodsToFixError));
	
EndProcedure

&AtClient
Procedure GotoMailSettings()
	
	If FormOwner <> Undefined And FormOwner.FormName = "Catalog.EmailAccounts.Form.ItemForm" Then
		Close(PatchID);
	Else
		OpeningParameters = New Structure;
		OpeningParameters.Insert("Key", Parameters.Account);
		OpeningParameters.Insert("PatchID", PatchID);
		
		OpenForm("Catalog.EmailAccounts.ObjectForm", OpeningParameters, ThisObject);
	EndIf;
	
EndProcedure

#EndRegion
