﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// 
	If Not Parameters.Property("ExchangeNode") Then
		
		Raise NStr("en = 'This is a dependent form and opens from a different form.';", Common.DefaultLanguageCode());
		
	EndIf;
	
	ExchangeNode = Parameters.ExchangeNode;
	
	CorrespondentDescription = String(ExchangeNode);
	
	Items.LabelWaitDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.LabelWaitDecoration.Title, CorrespondentDescription);
	
	Items.ErrorLabelDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.ErrorLabelDecoration.Title, CorrespondentDescription);
	
	Title = NStr("en = 'Import data exchange parameters';");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.PanelMain.CurrentPage = Items.TimeConsumingOperationPage;
	Items.FormDoneCommand.DefaultButton = False;
	Items.FormDoneCommand.Enabled = False;
	
	AttachIdleHandler("OnStartImportXDTOSettings", 1, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DoneCommand(Command)
	
	Result = New Structure;
	Result.Insert("ContinueSetup",            False);
	Result.Insert("DataReceivedForMapping", False);
	
	Close(Result);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OnStartImportXDTOSettings()
	
	ContinueWait = True;
	OnStartImportXDTOSettingsAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitIdleHandlerParameters(
			IdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForImportXDTOSettings",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteImportXDTOSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForImportXDTOSettings()
	
	ContinueWait = False;
	OnWaitImportXDTOSettingsAtServer(HandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(IdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForImportXDTOSettings",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		IdleHandlerParameters = Undefined;
		OnCompleteImportXDTOSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteImportXDTOSettings()
	
	ErrorMessage = "";
	SettingsImported = False;
	DataReceivedForMapping = False;
	OnCompleteImportXDTOSettingsAtServer(HandlerParameters, SettingsImported, DataReceivedForMapping, ErrorMessage);
	
	If SettingsImported Then
		
		Result = New Structure;
		Result.Insert("ContinueSetup",            True);
		Result.Insert("DataReceivedForMapping", DataReceivedForMapping);
		
		Close(Result);
	Else
		Items.PanelMain.CurrentPage = Items.ErrorPage;
		Items.FormDoneCommand.DefaultButton = True;
		Items.FormDoneCommand.Enabled = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartImportXDTOSettingsAtServer(ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	ImportSettings = New Structure;
	ImportSettings.Insert("ExchangeNode", ExchangeNode);
	
	ModuleSetupWizard.OnStartImportXDTOSettings(ImportSettings, HandlerParameters, ContinueWait);
	
EndProcedure
	
&AtServerNoContext
Procedure OnWaitImportXDTOSettingsAtServer(HandlerParameters, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	ContinueWait = False;
	ModuleSetupWizard.OnWaitForImportXDTOSettings(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnCompleteImportXDTOSettingsAtServer(HandlerParameters, SettingsImported, DataReceivedForMapping, ErrorMessage)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	CompletionStatus = Undefined;
	ModuleSetupWizard.OnCompleteImportXDTOSettings(HandlerParameters, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		SettingsImported = False;
		DataReceivedForMapping = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		SettingsImported = CompletionStatus.Result.SettingsImported;
			
		If Not SettingsImported Then
			DataReceivedForMapping = False;
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		Else
			DataReceivedForMapping = CompletionStatus.Result.DataReceivedForMapping;
		EndIf;
	EndIf;
	
EndProcedure 

#EndRegion
