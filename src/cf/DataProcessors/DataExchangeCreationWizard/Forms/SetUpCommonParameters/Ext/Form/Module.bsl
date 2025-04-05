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
	
	CheckCanUseForm(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	InitializeFormAttributes();
	
	SetInitialFormItemsView();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Set the current navigation table.
	FillNavigationTable();
	
	// Select the first wizard step.
	SetNavigationNumber(1);

EndProcedure

&AtClient
Procedure NameOfFolderWhereSettingsAreSavedStartChoice(Item, ChoiceData, StandardProcessing)
	
	DialogTitle = NStr("en = 'Choose a directory to save the connection settings'");
	Notification = New CallbackDescription("NameOfFolderWhereSettingsAreSavedStartChoiceCompletion", ThisObject);

	FileSystemClient.SelectDirectory(Notification, DialogTitle, NameOfFolderWhereSettingsAreSaved);

EndProcedure

&AtClient
Procedure NameOfFolderWhereSettingsAreSavedStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	NameOfFolderWhereSettingsAreSaved = Result;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	WarningText = NStr("en = 'Do you want to discard the connection parameters for data synchronization?'");
	CommonClient.ShowArbitraryFormClosingConfirmation(
		ThisObject, Cancel, Exit, WarningText, "ForceCloseForm");

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)

	If Not SaveConnectionParametersToFile Then
		CommonClientServer.DeleteValueFromArray(CheckedAttributes, "NameOfFolderWhereSettingsAreSaved");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FixDuplicateSynchronizationSettingsOnChange(Item)
	
	If FixDuplicateSynchronizationSettings 
		And (ThisNodeExistsInPeerInfobase Or ThisInfobaseHasPeerInfobaseNode) Then
		
		ClosingNotification1 = New CallbackDescription("AfterPermissionDeletion", ThisObject, Object.InfobaseNode);
		If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			Queries = DataExchangeServerCall.RequestToClearPermissionsToUseExternalResources(Object.InfobaseNode);
			ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
			ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, Undefined, ClosingNotification1);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterPermissionDeletion(Result, InfobaseNode) Export
	
	If Not Result = DialogReturnCode.OK Then
		FixDuplicateSynchronizationSettings = False;
	EndIf;
	
	Items.Next.Enabled = FixDuplicateSynchronizationSettings
		And (ThisNodeExistsInPeerInfobase Or ThisInfobaseHasPeerInfobaseNode);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	ForceCloseForm = True;
	
	Result = New Structure;
	Result.Insert("ExchangeNode", Object.InfobaseNode);
	Result.Insert("HasDataToMap", HasDataToMap);
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Next(Command)
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region FormInitializationOnCreate

&AtServer
Procedure CheckCanUseForm(Cancel = False)
	
	// Parameters of the data exchange creation wizard must be passed.
	If Not Parameters.Property("ConnectionSettings") Then
				
		MessageText = NStr("en = 'The form cannot be opened manually.'");
		Common.MessageToUser(MessageText, , , , Cancel);
		
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeFormAttributes()
	
	FillPropertyValues(Object, Parameters.ConnectionSettings);
	
	ContinueSetupInSubordinateDIBNode = Parameters.Property("ContinueSetupInSubordinateDIBNode");

	SaaSModel = Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable();
		
	DIBSetup  = DataExchangeCached.IsDistributedInfobaseExchangePlan(Object.ExchangePlanName);
	XDTOSetup = DataExchangeServer.IsXDTOExchangePlan(Object.ExchangePlanName);
		
	DescriptionChangeAvailable = False;
	PrefixChangeAvailable     = False;
	
	CorrespondentDescriptionChangeAvailable = True;
	CorrespondentPrefixChangeAvailable     = True;
	
	If ContinueSetupInSubordinateDIBNode Then

		DescriptionChangeAvailable = False;
		PrefixChangeAvailable = False;
		
		CorrespondentDescriptionChangeAvailable = False;
		CorrespondentPrefixChangeAvailable = False;
		
	EndIf;
		
	If ValueIsFilled(Object.TransportID) Then
	
		ConnectionSettings = ExchangeMessagesTransportClientServer.ConnectionSettingsForProcessing(Object);
		NameOfFolderWhereSettingsAreSaved = ExchangeMessagesTransport.NameOfFolderWhereSettingsAreSaved(ConnectionSettings);
			
		TransportParameters = ExchangeMessagesTransport.TransportParameters(Object.TransportID);
		
		SaveConnectionParametersToFile =
			TransportParameters.SaveConnectionParametersToFile
			And Not Object.WizardRunOption = "ContinueDataExchangeSetup"
			And Not DIBSetup;
			
		SettingsFileNameForDestination = DataExchangeServer.ExchangePlanSettingValue(
			Object.ExchangePlanName, "SettingsFileNameForDestination", Object.SettingID);
	
	EndIf;
	
	If Not ValueIsFilled(SettingsFileNameForDestination) Then
		SettingsFileNameForDestination = "ConnectionSettings";
	EndIf;
		
	TitleTemplate1 = 
		NStr("en = 'This directory will contains the settings files ""%1.*"".
              |Use one of them to resume the setup in the peer infobase.'");
	
	Items.NameOfFolderWhereSettingsAreSaved.ToolTip = StrTemplate(TitleTemplate1, SettingsFileNameForDestination);
	
EndProcedure

&AtServer
Procedure SetInitialFormItemsView()
	
	CommonClientServer.SetFormItemProperty(Items,
		"GroupSavingConnectionSettingsForCorrespondent", "Visible", SaveConnectionParametersToFile);
	
	CommonClientServer.SetFormItemProperty(Items,
		"Description", "ReadOnly", Not DescriptionChangeAvailable);
	
	CommonClientServer.SetFormItemProperty(Items,
		"Prefix", "ReadOnly", Not PrefixChangeAvailable);
	
	CommonClientServer.SetFormItemProperty(Items,
		"PeerInfobaseName", "ReadOnly", Not CorrespondentDescriptionChangeAvailable);
	
	CommonClientServer.SetFormItemProperty(Items,
		"CorrespondentPrefix", "ReadOnly", Not CorrespondentPrefixChangeAvailable);
	
EndProcedure

#EndRegion

#Region SuppliedPartOfAssistant

&AtClient
Procedure ChangeNavigationNumber(Iterator_SSLy)
	
	ClearMessages();
	
	SetNavigationNumber(NavigationNumber + Iterator_SSLy);
	
EndProcedure

&AtClient
Procedure SetNavigationNumber(Val Value)
	
	IsMoveNext = (Value > NavigationNumber);
	
	NavigationNumber = Value;
	
	If NavigationNumber < 0 Then
		
		NavigationNumber = 0;
		
	EndIf;
	
	NavigationNumberOnChange(IsMoveNext);
	
EndProcedure

&AtClient
Procedure NavigationNumberOnChange(Val IsMoveNext)
	
	// Run navigation event handlers.
	ExecuteNavigationEventHandlers(IsMoveNext);
	
	// Set up page view.
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("en = 'The page to display is not specified.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	Items.PanelMain.CurrentPage  = Items[NavigationRowCurrent.MainPageName];
	Items.NavigationPanel.CurrentPage = Items[NavigationRowCurrent.NavigationPageName];
	
	If Not IsBlankString(NavigationRowCurrent.DecorationPageName) Then
		
		Items.DecorationPanel.CurrentPage = Items[NavigationRowCurrent.DecorationPageName];
		
	EndIf;
	
	// Set the default button.
	NextButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "NextCommand");
	
	If NextButton <> Undefined Then
		
		NextButton.DefaultButton = True;
		
	Else
		
		ConfirmButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "DoneCommand");
		
		If ConfirmButton <> Undefined Then
			
			ConfirmButton.DefaultButton = True;
			
		EndIf;
		
	EndIf;
	
	If IsMoveNext And NavigationRowCurrent.TimeConsumingOperation Then
		
		AttachIdleHandler("ExecuteTimeConsumingOperationHandler", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteNavigationEventHandlers(Val IsMoveNext)
	
	// Navigation event handlers.
	If IsMoveNext Then
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber - 1));
		
		If NavigationRows.Count() > 0 Then
			
			NavigationRow = NavigationRows[0];
			
			// OnNavigationToNextPage handler.
			If Not IsBlankString(NavigationRow.OnNavigationToNextPageHandlerName)
				And Not NavigationRow.TimeConsumingOperation Then
				
				ProcedureName = "[HandlerName](Cancel)";
				ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnNavigationToNextPageHandlerName);
				
				Cancel = False;
				
				Result = Eval(ProcedureName);
				
				If Cancel Then
					
					NavigationNumber = NavigationNumber - 1;
					Return;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	Else
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber + 1));
		
		If NavigationRows.Count() > 0 Then
			
			NavigationRow = NavigationRows[0];
			
			// OnNavigationToPreviousPage handler.
			If Not IsBlankString(NavigationRow.OnSwitchToPreviousPageHandlerName)
				And Not NavigationRow.TimeConsumingOperation Then
				
				ProcedureName = "[HandlerName](Cancel)";
				ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnSwitchToPreviousPageHandlerName);
				
				Cancel = False;
				
				Result = Eval(ProcedureName);
				
				If Cancel Then
					
					NavigationNumber = NavigationNumber + 1;
					Return;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("en = 'The page to display is not specified.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	If NavigationRowCurrent.TimeConsumingOperation And Not IsMoveNext Then
		SetNavigationNumber(NavigationNumber - 1);
		Return;
	EndIf;
	
	// OnOpen handler.
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then
		
		ProcedureName = "[HandlerName](Cancel, SkipPage, IsMoveNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.OnOpenHandlerName);
		
		Cancel = False;
		SkipPage = False;
		
		Result = Eval(ProcedureName);
		
		If Cancel Then
			
			NavigationNumber = NavigationNumber - 1;
			Return;
			
		ElsIf SkipPage Then
			
			If IsMoveNext Then
				
				SetNavigationNumber(NavigationNumber + 1);
				Return;
				
			Else
				
				SetNavigationNumber(NavigationNumber - 1);
				Return;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTimeConsumingOperationHandler()
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("en = 'The page to display is not specified.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// TimeConsumingOperationProcessing handler.
	If Not IsBlankString(NavigationRowCurrent.TimeConsumingOperationHandlerName) Then
		
		ProcedureName = "[HandlerName](Cancel, GoToNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.TimeConsumingOperationHandlerName);
		
		Cancel = False;
		GoToNext = True;
		
		Result = Eval(ProcedureName);
		
		If Cancel Then
			
			NavigationNumber = NavigationNumber - 1;
			Return;
			
		ElsIf GoToNext Then
			
			SetNavigationNumber(NavigationNumber + 1);
			Return;
			
		EndIf;
		
	Else
		
		SetNavigationNumber(NavigationNumber + 1);
		Return;
		
	EndIf;
	
EndProcedure

&AtClient
Function GetFormButtonByCommandName(FormItem, CommandName)
	
	For Each Item In FormItem.ChildItems Do
		
		If TypeOf(Item) = Type("FormGroup") Then
			
			FormItemByCommandName = GetFormButtonByCommandName(Item, CommandName);
			
			If FormItemByCommandName <> Undefined Then
				
				Return FormItemByCommandName;
				
			EndIf;
			
		ElsIf TypeOf(Item) = Type("FormButton")
			And StrFind(Item.CommandName, CommandName) > 0 Then
			
			Return Item;
			
		Else
			
			Continue;
			
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region NavigationEventHandlers

// 

&AtClient
Function Attachable_GettingCorresponding_ParametersWhenOpening(Cancel, SkipPage, Val IsMoveNext) Export

	BackgroundJob = GettingParametersOfCorrespondentBeginning();
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
		
	Handler = New CallbackDescription("GettingCorrespondentParametersCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);

	Return Undefined;
		
EndFunction

&AtServer
Function GettingParametersOfCorrespondentBeginning()
	
	ConnectionSettings = ExchangeMessagesTransportClientServer.StructureOfConnectionSettings();
	FillPropertyValues(ConnectionSettings, Object);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Get peer parameters'", Common.DefaultLanguageCode());
	ExecutionParameters.WaitCompletion = 0;
		
	Return TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"DataProcessors.DataExchangeCreationWizard.GettingCorrespondentParameters",
		ConnectionSettings);
	
EndFunction

&AtClient
Procedure GettingCorrespondentParametersCompletion(BackgroundJob, AdditionalParameters) Export 
	
	If BackgroundJob.Status = "Error" Then 
		ErrorMessage = BackgroundJob.DetailErrorDescription;
	EndIf;
	
	GettingCorrespondentParametersEndOnServer(BackgroundJob.ResultAddress);
	
	SetInitialFormItemsView();
	
	If ConnectionIsSet And ConnectionAllowed
		And (ThisNodeExistsInPeerInfobase Or ThisInfobaseHasPeerInfobaseNode) Then
		
		ConfigureDuplicateSyncSettingsGroup();
		ChangeNavigationNumber(+1);
		
	ElsIf ConnectionIsSet And ConnectionAllowed Then
		
		ConfigureSettingsRecoveryGroup();
		ChangeNavigationNumber(+1);
		
	Else
		
		ChangeNavigationNumber(+4);
		
	EndIf;

EndProcedure

&AtServer
Procedure GettingCorrespondentParametersEndOnServer(Val ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);
	
	If Result = Undefined Then
		Return;
	EndIf;
			
	ListOfProperties = "ConnectionIsSet,
					|ConnectionAllowed,
					|ErrorMessage,
					|ThisNodeExistsInPeerInfobase,
					|ThisInfobaseHasPeerInfobaseNode,
					|NodeToDelete";
	
	FillPropertyValues(ThisObject, Result, ListOfProperties);
	
	If ConnectionIsSet And ValueIsFilled(Result.CorrespondentParameters) Then
		FillCorrespondentParameters(Result.CorrespondentParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureDuplicateSyncSettingsGroup() 
	
	If ThisInfobaseHasPeerInfobaseNode Or ThisNodeExistsInPeerInfobase Then
	
		Items.DuplicateSynchronizationSettingsGroup.Visible = True;
		Items.ThereIsGroupOfThisSubAssetInCorrespondent.Visible = ThisNodeExistsInPeerInfobase;
		Items.ThereIsCorrespondentSGroupOfSubAssetInThisDatabase.Visible = ThisInfobaseHasPeerInfobaseNode;
		Items.InscriptionCorrespondentSSubAssetIsInThisDatabase.Title =
			StrTemplate(Items.InscriptionCorrespondentSSubAssetIsInThisDatabase.Title, NodeToDelete);
			
		Items.Next.Enabled = False;
		
	Else
		
		Items.DuplicateSynchronizationSettingsGroup.Visible = False;
		
	EndIf;
	
EndProcedure

&AtClient 
Procedure ConfigureSettingsRecoveryGroup()
	
	Items.GroupRestoreExchangeSettings.Visible = 
		Object.RestoreExchangeSettings = "RestoreWithWarning";
	
EndProcedure

&AtServer
Procedure FillCorrespondentParameters(CorrespondentParameters, CorrespondentInSaaS = False)
	
	If ValueIsFilled(CorrespondentParameters.InfobasePrefix) Then
		Object.DestinationInfobasePrefix = CorrespondentParameters.InfobasePrefix;
		CorrespondentPrefixChangeAvailable = False;
	Else
		Object.DestinationInfobasePrefix = CorrespondentParameters.DefaultInfobasePrefix;
		CorrespondentPrefixChangeAvailable = True;
	EndIf;
	
	If Not CorrespondentInSaaS Then
		If ValueIsFilled(CorrespondentParameters.InfobaseDescription) Then
			Object.SecondInfobaseDescription = CorrespondentParameters.InfobaseDescription;
		Else
			Object.SecondInfobaseDescription = CorrespondentParameters.DefaultInfobaseDescription;
		EndIf;
	EndIf;
	
	Object.DestinationInfobaseID = CorrespondentParameters.ThisNodeCode;
	Object.CorrespondentExchangePlanName = CorrespondentParameters.ExchangePlanName;
	
	If XDTOSetup Then
		
		Object.UsePrefixesForCorrespondentExchangeSettings = CorrespondentParameters.UsePrefixesForExchangeSettings;
		
		Object.ExchangeFormatVersion = DataExchangeXDTOServer.MaxCommonFormatVersion(
			Object.ExchangePlanName, CorrespondentParameters.ExchangeFormatVersions);
		
		Object.SupportedPeerInfobaseFormatObjects = New ValueStorage(
			CorrespondentParameters.SupportedObjectsInFormat, New Deflation(9));
	
	ElsIf StrLen(Object.DestinationInfobaseID) = 9 Then
		Object.UsePrefixesForExchangeSettings               = False;
		Object.UsePrefixesForCorrespondentExchangeSettings = False;
		If IsBlankString(Object.SourceInfobaseID) Then
			Object.SourceInfobaseID = Object.SourceInfobasePrefix;
		EndIf;
	EndIf;
	
EndProcedure

// 

&AtClient
Function Attachable_GeneralSynchronizationSettingsPageOnGoNext(Cancel) Export
	
	If Not CheckFilling() Then
		
		Cancel = True;
		
	EndIf;
	
EndFunction

// 

&AtClient
Function Attachable_SavingConnectionSettings_WhenOpening(Cancel, SkipPage, Val IsMoveNext) Export

	BackgroundJob = SavingConnectionSettingsStart();
		
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
		
	Handler = New CallbackDescription("SaveConnectionSettingsCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);

	Return Undefined;
		
EndFunction

&AtClient 
Function Attachable_ErrorPage_WhenOpening(Cancel, SkipPage, Val IsMoveNext) Export
	
	If ErrorMessage = "" Then
		
		ErrorMessage = NStr(
			"en = 'Error setting up common parameters.
			|See the event log for details.'",
			CommonClient.DefaultLanguageCode());
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServer
Function SavingConnectionSettingsStart()
	
	ProcedureParameters = ExchangeMessagesTransportClientServer.ConnectionSettingsForProcessing(Object);
	
	ProcedureParameters.FixDuplicateSynchronizationSettings = FixDuplicateSynchronizationSettings;
	ProcedureParameters.ThisInfobaseHasPeerInfobaseNode = ThisInfobaseHasPeerInfobaseNode;
	ProcedureParameters.ThisNodeExistsInPeerInfobase = ThisNodeExistsInPeerInfobase;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Get peer parameters'", Common.DefaultLanguageCode());
	ExecutionParameters.WaitCompletion = 0;
	
	BackgroundJobKey = DataExchangeServer.BackgroundJobKey(Object.ExchangePlanName,
		NStr("en = 'Save connection settings'"));
		
	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Saving connection settings for ""%1"" is already in progress.'"), Object.ExchangePlanName);
	EndIf; 
		
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
		
	Return TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"DataProcessors.DataExchangeCreationWizard.SaveConnectionSettings1",
		ProcedureParameters);
	
EndFunction

&AtClient
Procedure SaveConnectionSettingsCompletion(BackgroundJob, AdditionalParameters) Export 
	
	If BackgroundJob = Undefined Then
		Return;
	EndIf;
	
	If BackgroundJob.Status = "Error" Then 
		
		ErrorMessage = BackgroundJob.DetailErrorDescription;
		ChangeNavigationNumber(+2);
		
	EndIf;
	
	SavingConnectionSettingsEndingOnServer(BackgroundJob.ResultAddress);
	
	If ConnectionSettingsSaved Then
		
		SaveConnectionSettingsFiles();
		
	Else
		
		ChangeNavigationNumber(+2);
		
	EndIf;

EndProcedure

&AtServer
Procedure SavingConnectionSettingsEndingOnServer(Val ResultAddress)
		
	Result = GetFromTempStorage(ResultAddress);
	
	ListOfProperties = "ConnectionSettingsSaved,ErrorMessage";
	FillPropertyValues(ThisObject, Result, ListOfProperties);
		
	If Result.ConnectionSettingsSaved Then
		
		Object.InfobaseNode = Result.ExchangeNode;
		
		AddressOfXMLConnectionSettings = "";
		
		If ValueIsFilled(Result.XMLConnectionSettingsString) Then
			
			TempFileName = GetTempFileName();
			
			Record = New TextWriter;
			Record.Open(TempFileName, "UTF-8");
			Record.Write(Result.XMLConnectionSettingsString);
			Record.Close();
			
			AddressOfXMLConnectionSettings = PutToTempStorage(
				New BinaryData(TempFileName), UUID);
				
			DeleteFiles(TempFileName);
			
		EndIf;
		
		AddressOfJSONConnectionSettings = "";
		
		If ValueIsFilled(Result.JSONConnectionSettingsString) Then
			
			TempFileName = GetTempFileName();
			
			Record = New TextWriter;
			Record.Open(TempFileName, "UTF-8");
			Record.Write(Result.JSONConnectionSettingsString);
			Record.Close();
			
			AddressOfJSONConnectionSettings = PutToTempStorage(
				New BinaryData(TempFileName), UUID);
				
			DeleteFiles(TempFileName);
			
		EndIf;
		
		If Not SaaSModel Then
			HasDataToMap = Result.HasDataToMap;
		EndIf;
			
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveConnectionSettingsFiles()
	
	If Not ValueIsFilled(NameOfFolderWhereSettingsAreSaved) Then
		
		ChangeNavigationNumber(+1);
		Return;
		
	EndIf;
	
	FilesToObtain = New Array;
	
	If ValueIsFilled(AddressOfXMLConnectionSettings) Then
		
		FileName = CommonClientServer.GetFullFileName(
			NameOfFolderWhereSettingsAreSaved,
			SettingsFileNameForDestination + ".xml");

		FilesToObtain.Add(New TransferableFileDescription(FileName, AddressOfXMLConnectionSettings));
		
	EndIf;
	
	If ValueIsFilled(AddressOfJSONConnectionSettings) Then
		
		FileName = CommonClientServer.GetFullFileName(
			NameOfFolderWhereSettingsAreSaved,
			SettingsFileNameForDestination + ".json");
		
		FilesToObtain.Add(New TransferableFileDescription(FileName, AddressOfJSONConnectionSettings));
		
	EndIf;
	
	If FilesToObtain.Count() > 0 Then
		
		Notification = New CallbackDescription("SaveConnectionSettingsFilesCompletion", ThisObject);
		
		SavingParameters = FileSystemClient.FilesSavingParameters();
		SavingParameters.Interactively = False;
			
		FileSystemClient.SaveFiles(Notification, FilesToObtain, SavingParameters);
		
	Else
		
		ChangeNavigationNumber(+1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveConnectionSettingsFilesCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	ChangeNavigationNumber(+1);
	
EndProcedure

#EndRegion

&AtClient
Procedure FillNavigationTable()
	
	NavigationTable.Clear();
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 1;
	Transition.MainPageName     = "GettingParametersPageIsCorresponding";
	Transition.NavigationPageName    = "NavigationWaitPage";
	Transition.OnOpenHandlerName = "Attachable_GettingCorresponding_ParametersWhenOpening";
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 2;
	Transition.MainPageName     = "CommonSynchronizationSettingsPage";
	Transition.NavigationPageName    = "NextNavigationPage";
	Transition.OnNavigationToNextPageHandlerName = "Attachable_GeneralSynchronizationSettingsPageOnGoNext";
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 3;
	Transition.MainPageName     = "SaveConnectionSettingsPage";
	Transition.NavigationPageName    = "NavigationWaitPage";
	Transition.OnOpenHandlerName = "Attachable_SavingConnectionSettings_WhenOpening";
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 4;
	Transition.MainPageName     = "EndPage";
	Transition.NavigationPageName    = "DoneNavigationPage";
	
	Transition = NavigationTable.Add();
	Transition.NavigationNumber = 5;
	Transition.MainPageName     = "ErrorPage";
	Transition.NavigationPageName    = "NavigationWaitPage";
	Transition.OnOpenHandlerName = "Attachable_ErrorPage_WhenOpening";
	
EndProcedure

#EndRegion



