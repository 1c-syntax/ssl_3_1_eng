///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// 
//
// Parameters:
//  Form - ClientApplicationForm -  the form from which the procedure is called.
// 
Procedure NodesSetupFormCloseFormCommand(Form) Export
	
	If Not Form.CheckFilling() Then
		Return;
	EndIf;
	
	Form.Modified = False;
	FillStructureData(Form);
	Form.Close(Form.Context);
	
EndProcedure

// Procedure-handler for closing the exchange plan node configuration form.
//
// Parameters:
//  Form - ClientApplicationForm -  the form from which the procedure is called.
// 
Procedure NodeSettingsFormCloseFormCommand(Form) Export
	
	OnCloseExchangePlanNodeSettingsForm(Form, "NodeFiltersSetting");
	
EndProcedure

// Procedure-handler for closing the exchange plan node default settings form.
//
// Parameters:
//  Form - ClientApplicationForm -  the form from which the procedure is called.
// 
Procedure DefaultValueSetupFormCloseFormCommand(Form) Export
	
	OnCloseExchangePlanNodeSettingsForm(Form, "DefaultNodeValues");
	
EndProcedure

// Procedure-handler for closing the exchange plan node configuration form.
//
// Parameters:
//  Cancel            - Boolean           -  indicates whether the form is not closed.
//  Form            - ClientApplicationForm -  the form from which the procedure is called.
//  Exit - Boolean           -  indicates that the form is being closed while the application is shutting down.
// 
// Example:
//
//	&Naciente
//	Procedure Prezcription(Denial, Superseniority, Textpageprivate, Standartnaya)
//		Abendanimation.Formanastruction Before Closing(Failure, This Object, Completion Of Work);
//	End of procedure
//
Procedure SetupFormBeforeClose(Cancel, Form, Exit) Export
	
	ProcedureName = "DataExchangeClient.SetupFormBeforeClose";
	CommonClientServer.CheckParameter(ProcedureName, "Cancel", Cancel, Type("Boolean"));
	CommonClientServer.CheckParameter(ProcedureName, "Form", Form, Type("ClientApplicationForm"));
	CommonClientServer.CheckParameter(ProcedureName, "Exit", Exit, Type("Boolean"));
	
	If Not Form.Modified Then
		Return;
	EndIf;
		
	Cancel = True;
	
	If Exit Then
		Return;
	EndIf;
	
	QueryText = NStr("en = 'Close the form without saving the changes?';");
	NotifyDescription = New NotifyDescription("SetupFormBeforeCloseCompletion", ThisObject, Form);
	ShowQueryBox(NotifyDescription, QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.No);
	
EndProcedure

// Opens the form assistant to set up communication for a given exchange.
//
// Parameters:
//  ExchangePlanName         - String -  name of the exchange plan as the metadata object
//                                    to open the assistant for.
//  SettingID - String -  ID of the data exchange configuration option.
// 
Procedure OpenDataExchangeSetupWizard(Val ExchangePlanName, Val SettingID) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ExchangePlanName", ExchangePlanName);
	FormParameters.Insert("SettingID", SettingID);
	
	FormKey = ExchangePlanName + "_" + SettingID;
	
	OpenForm("DataProcessor.DataExchangeCreationWizard.Form.ConnectionSetup", FormParameters, ,
		FormKey, , , , FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Handler for starting the selection of an element for the form for setting up the correspondent database node settings when setting up an exchange via
// an external connection.
//
// Parameters:
//  AttributeName - String -  name of the form's details.
//  TableName - String -  full name of the metadata object.
//  Owner - ClientApplicationForm -  form for selecting elements of the corresponding database.
//  StandardProcessing - Boolean -  indicates whether standard (system) event processing is performed.
//  ExternalConnectionParameters - Structure
//  ChoiceParameters - Structure -  structure of selection parameters.
//
Procedure CorrespondentInfobaseItemSelectionHandlerStartChoice(Val AttributeName, Val TableName, Val Owner,
	Val StandardProcessing, Val ExternalConnectionParameters, Val ChoiceParameters=Undefined) Export
	
	IDAttributeName = AttributeName + "_Key";
	
	ChoiceInitialValue = Undefined;
	ChoiceFoldersAndItems    = Undefined;
	
	OwnerType = TypeOf(Owner);
	If OwnerType=Type("FormTable") Then
		CurrentData = Owner.CurrentData;
		If CurrentData<>Undefined Then
			ChoiceInitialValue = CurrentData[IDAttributeName];
		EndIf;
		
	ElsIf OwnerType=Type("ClientApplicationForm") Then
		ChoiceInitialValue = Owner[IDAttributeName];
		
	EndIf;
	
	If ChoiceParameters<>Undefined Then
		If ChoiceParameters.Property("ChoiceFoldersAndItems") Then
			ChoiceFoldersAndItems = ChoiceParameters.ChoiceFoldersAndItems;
		EndIf;
	EndIf;
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("ExternalConnectionParameters",        ExternalConnectionParameters);
	FormParameters.Insert("CorrespondentInfobaseTableFullName", TableName);
	FormParameters.Insert("ChoiceInitialValue",            ChoiceInitialValue);
	FormParameters.Insert("AttributeName",                       AttributeName);
	FormParameters.Insert("ChoiceFoldersAndItems",               ChoiceFoldersAndItems);
	
	OpenForm("CommonForm.SelectCorrespondentInfobaseObjects", FormParameters, Owner);
	
EndProcedure

// Handler for selecting elements for the form for setting up the corresponding database node settings when setting up exchange via an external
// connection.
//
// Parameters:
//  AttributeName - String -  name of the form's details.
//  TableName - String -  full name of the metadata object.
//  Owner - ClientApplicationForm -  form for selecting elements of the corresponding database.
//  ExternalConnectionParameters - Structure
//  ChoiceParameters - Structure -  structure of selection parameters.
//
Procedure CorrespondentInfobaseItemSelectionHandlerPick(Val AttributeName, Val TableName, Val Owner,
	Val ExternalConnectionParameters, Val ChoiceParameters=Undefined) Export
	
	IDAttributeName = AttributeName + "_Key";
	
	ChoiceInitialValue = Undefined;
	ChoiceFoldersAndItems    = Undefined;
	
	CurrentData = Owner.CurrentData;
	If CurrentData <> Undefined Then
		ChoiceInitialValue = CurrentData[IDAttributeName];
	EndIf;
	
	If ChoiceParameters <> Undefined Then
		If ChoiceParameters.Property("ChoiceFoldersAndItems") Then
			ChoiceFoldersAndItems = ChoiceParameters.ChoiceFoldersAndItems;
		EndIf;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ExternalConnectionParameters",        ExternalConnectionParameters);
	FormParameters.Insert("CorrespondentInfobaseTableFullName", TableName);
	FormParameters.Insert("ChoiceInitialValue",            ChoiceInitialValue);
	FormParameters.Insert("CloseOnChoice",                 False);
	FormParameters.Insert("AttributeName",                       AttributeName);
	FormParameters.Insert("ChoiceFoldersAndItems",               ChoiceFoldersAndItems);
	
	OpenForm("CommonForm.SelectCorrespondentInfobaseObjects", FormParameters, Owner);
EndProcedure

// Handler for processing the element selection for the form for setting up the correspondent database node settings when setting up an exchange via
// an external connection.
//
// Parameters:
//  Item - ClientApplicationForm
//          - FormTable - 
//  ValueSelected - Arbitrary - see the description of the parameter Selected Value of the Selection Processing event.
//  FormDataCollection - FormDataCollection -  for the selection mode from the list.
//
Procedure CorrespondentInfobaseItemsSelectionHandlerChoiceProcessing(Val Item, Val ValueSelected, Val FormDataCollection=Undefined) Export
	
	If TypeOf(ValueSelected)<>Type("Structure") Then
		Return;
	EndIf;
	
	IDAttributeName = ValueSelected.AttributeName + "_Key";
	PresentationAttributeName  = ValueSelected.AttributeName;
	
	ElementType = TypeOf(Item);
	If ElementType=Type("FormTable") Then
		
		If ValueSelected.PickMode Then
			If FormDataCollection<>Undefined Then
				Filter = New Structure(IDAttributeName, ValueSelected.Id);
				ExistingRows = FormDataCollection.FindRows(Filter);
				If ExistingRows.Count() > 0 Then
					Return;
				EndIf;
			EndIf;
			
			Item.AddRow();
		EndIf;
		
		CurrentData = Item.CurrentData;
		If CurrentData<>Undefined Then
			CurrentData[IDAttributeName] = ValueSelected.Id;
			CurrentData[PresentationAttributeName]  = ValueSelected.Presentation;
		EndIf;
		
	ElsIf ElementType=Type("ClientApplicationForm") Then
		Item[IDAttributeName] = ValueSelected.Id;
		Item[PresentationAttributeName]  = ValueSelected.Presentation;
		
	EndIf;
	
EndProcedure

// Checks whether the "Use" flag is set for all rows in the table.
//
// Parameters:
//  Table - ValueTable -  the table being checked.
//
// Returns:
//  Boolean - 
//
Function AllRowsMarkedInTable(Table) Export
	
	For Each Item In Table Do
		
		If Item.Use = False Then
			
			Return False;
			
		EndIf;
		
	EndDo;
	
	Return True;
EndFunction

// Deletes the data synchronization setting.
//
// Parameters:
//   InfobaseNode - ExchangePlanRef -  the exchange plan node that corresponds to the exchange that is being disabled.
//
Procedure DeleteSynchronizationSetting(Val InfobaseNode) Export
	
	If DataExchangeServerCall.IsMasterNode(InfobaseNode) Then
		WarningText = NStr("en = 'To detach the infobase from the main node,
			|start Designer with parameter /ResetMasterNode.';");
		ShowMessageBox(, WarningText);
	Else
		WizardParameters = New Structure;
		WizardParameters.Insert("ExchangeNode", InfobaseNode);
		
		OpenForm("DataProcessor.DataExchangeCreationWizard.Form.DeleteSyncSetting", WizardParameters);
	EndIf;
	
EndProcedure

// The procedure is the handler of the exchange plan node entry. If necessary, performs node recording using a long operation
//
// Parameters:
//  Form - ClientApplicationForm -  the site plan of exchange.
//  Cancel - Boolean -  a sign of refusal to record the exchange plan node.
//  WriteParameters - Structure -  arbitrary recording parameters. See the description of the post-recording event in the syntax Assistant.
//
Procedure BeforeWrite(Form, Cancel, WriteParameters) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	CheckResult = DataExchangeServerCall.CheckTheNeedForADeferredNodeEntry(Form.Object);
	
	If CheckResult.ThereIsAnActiveBackgroundTask Then 
					
		WarningText = NStr("en = 'Deferred node saving operation is already in progress.
										|Try again later';");
		
		ShowMessageBox(, WarningText);

		Cancel = True;	
		
	ElsIf CheckResult.ALongTermOperationIsRequired Then
		
		Object = Form.Object; //ExchangePlanObject
		
		ProcessingParameters = New Structure;
		ProcessingParameters.Insert("Node", 				Object.Ref);
		ProcessingParameters.Insert("NodeStructureAddress", 	CheckResult.NodeStructureAddress);
		
		Form.Modified = False;
		Form.Close();
		
		OpenForm("DataProcessor.DeferredNodeWriting.Form.Form", ProcessingParameters,,,,,,FormWindowOpeningMode.LockOwnerWindow);

		Cancel = True;
		
	EndIf;
	
EndProcedure

// 
// 
//
// Parameters:
//  Form - ClientApplicationForm -  the site plan of exchange.
//  Item - FormItems
//  URL -  String - 
//  StandardProcessing - Boolean
//
Procedure HandleURLInNodeForm(Form, Item, URL, StandardProcessing) Export
	
	StandardProcessing = False;
	
	If CommonClient.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		ModuleDataExchangeInternalPublicationClient = CommonClient.CommonModule("DataExchangeInternalPublicationClient");
		ModuleDataExchangeInternalPublicationClient.HandleURLInNodeForm(
			Form, URL, StandardProcessing);
	EndIf;
	
EndProcedure

// 
//
// Parameters:
//  CommandParameter - Structure
//                  - Undefined
//  CommandExecuteParameters - CommandExecuteParameters
//
Procedure OpenDataSynchronizationPanel(CommandParameter, CommandExecuteParameters) Export
	
	DataProcessorName      = "";
	DataProcessorFormName = "";
	
	If StandardSubsystemsClient.ClientRunParameters().SeparatedDataUsageAvailable Then
		If CommonClient.SubsystemExists("ОбменДаннымиНастройкиПрограммы") Then
			DataProcessorName      = "DSLAdministrationPanel";
			DataProcessorFormName = "DataSynchronization";
		ElsIf CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
			DataProcessorName      = "SSLAdministrationPanel";
			DataProcessorFormName = "DataSynchronization";
		EndIf;	
	Else
		If Not CommonClient.SubsystemExists("CloudTechnology") Then
			Return;
		EndIf;
		
		DataProcessorName      = "SSLAdministrationPanelSaaS";
		DataProcessorFormName = "DataSynchronizationForServiceAdministrator";
	EndIf;
	
	If DataProcessorName = "" Then
		Return;
	EndIf;
	
	NameOfFormToOpen_ = "DataProcessor.[DataProcessorName].Form.[DataProcessorFormName]";
	NameOfFormToOpen_ = StrReplace(NameOfFormToOpen_, "[DataProcessorName]", DataProcessorName);
	NameOfFormToOpen_ = StrReplace(NameOfFormToOpen_, "[DataProcessorFormName]", DataProcessorFormName);
	
	OpenForm(
		NameOfFormToOpen_,
		New Structure,
		CommandExecuteParameters.Source,
		NameOfFormToOpen_ + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion

#Region Internal

// Opens the log modally with selection based on data upload or download events for the specified
// exchange plan node.
//
Procedure GoToDataEventLogModally(InfobaseNode, Owner, ActionOnExchange) Export
	
	// 
	FormParameters = DataExchangeServerCall.EventLogFilterData(InfobaseNode, ActionOnExchange);
	
	OpenForm("DataProcessor.EventLog.Form", FormParameters, Owner);
	
EndProcedure

// Returns the name of the failed update message form for an error in the PRO when updating the information database.
// 
// Returns:
//  String - 
//
Function FailedUpdateMessageFormName() Export
	
	Return "InformationRegister.DataExchangeRules.Form.FailedUpdateMessage";
	
EndFunction

// Updates the database configuration.
//
Procedure InstallConfigurationUpdate(ShouldExitApp = False) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ModuleConfigurationUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
		ModuleConfigurationUpdateClient.InstallConfigurationUpdate(ShouldExitApp);
	Else
		OpenForm("CommonForm.AdditionalDetails", New Structure("Title,TemplateName",
		NStr("en = 'Install update';"), "ManualUpdateInstruction"));
	EndIf;
	
EndProcedure

// Opens the form for the monitor of registered data to be sent.
//
Procedure OpenCompositionOfDataToSend(Val InfobaseNode) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ExchangeNode", InfobaseNode);
	FormParameters.Insert("SelectExchangeNodeProhibited", True);
	
	// 
	FormParameters.Insert("NamesOfMetadataToHide", New ValueList);
	FormParameters.NamesOfMetadataToHide.Add("InformationRegister.InfobaseObjectsMaps");
	
	NotExportByRules = DataExchangeServerCall.NotExportedNodeObjectsMetadataNames(InfobaseNode);
	For Each NameOfMetadataObjects In NotExportByRules Do
		FormParameters.NamesOfMetadataToHide.Add(NameOfMetadataObjects);
	EndDo;
	
	OpenForm("DataProcessor.RegisterChangesForDataExchange.Form", FormParameters,, InfobaseNode);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart(Parameters) Export
	
	If StrFind(LaunchParameter, "DownloadExtensionsAndShutDown") > 0 Then
				
		DataExchangeServerCall.DownloadExtensions();
		Terminate();
				
	EndIf;
	
	// 
	// 
	// 
	// 
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If Not ClientParameters.Property("RetryDataExchangeMessageImportBeforeStart") Then
		Return;
	EndIf;
	
	Parameters.InteractiveHandler = New NotifyDescription(
		"RetryDataExchangeMessageImportBeforeStartInteractiveHandler", ThisObject);
	
EndProcedure

// See CommonClientOverridable.OnStart.
Procedure OnStart(Parameters) Export
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientRunParameters.Property("OpenDataExchangeCreationWizardForSubordinateNodeSetup") Then
		
		For Each Window In GetWindows() Do
			If Window.IsMain Then
				Window.Activate();
				Break;
			EndIf;
		EndDo;
		
		WizardParameters = New Structure;
		WizardParameters.Insert("ExchangePlanName",         ClientRunParameters.DIBExchangePlanName);
		WizardParameters.Insert("SettingID", ClientRunParameters.DIBNodeSettingID);
		WizardParameters.Insert("NewSYnchronizationSetting");
		WizardParameters.Insert("ContinueSetupInSubordinateDIBNode");
		
		OpenForm("DataProcessor.DataExchangeCreationWizard.Form.SyncSetup", WizardParameters);
	EndIf;
	
EndProcedure

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If Not ClientRunParameters.SeparatedDataUsageAvailable Or ClientRunParameters.DataSeparationEnabled Then
		Return;
	EndIf;
		
	If Not ClientRunParameters.IsMasterNode1
		And Not ClientRunParameters.Property("OpenDataExchangeCreationWizardForSubordinateNodeSetup")
		And ClientRunParameters.Property("CheckSubordinateNodeConfigurationUpdateRequired") Then
		
		AttachIdleHandler("CheckSubordinateNodeConfigurationUpdateRequiredOnStart", 1, True);
		
	EndIf;
	
EndProcedure

// Opens the data register entry form for the specified selection.
Procedure OpenInformationRegisterWriteFormByFilter(
		Filter,
		FillingValues,
		Val RegisterName,
		OwnerForm,
		Val FormName = "",
		FormParameters = Undefined,
		ClosingNotification1 = Undefined) Export
	
	Var RecordKey;
	
	EmptyRecordSet = DataExchangeServerCall.RegisterRecordSetIsEmpty(Filter, RegisterName);
	
	If Not EmptyRecordSet Then
		// 
		
		ValueType = Type("InformationRegisterRecordKey." + RegisterName);
		Parameters = New Array(1);
		Parameters[0] = Filter;
		
		RecordKey = New(ValueType, Parameters);
	EndIf;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("Key",               RecordKey);
	WriteParameters.Insert("FillingValues", FillingValues);
	
	If FormParameters <> Undefined Then
		
		For Each Item In FormParameters Do
			
			WriteParameters.Insert(Item.Key, Item.Value);
			
		EndDo;
		
	EndIf;
	
	If IsBlankString(FormName) Then
		
		FullFormName = "InformationRegister.[RegisterName].RecordForm";
		FullFormName = StrReplace(FullFormName, "[RegisterName]", RegisterName);
		
	Else
		
		FullFormName = "InformationRegister.[RegisterName].Form.[FormName]";
		FullFormName = StrReplace(FullFormName, "[RegisterName]", RegisterName);
		FullFormName = StrReplace(FullFormName, "[FormName]", FormName);
		
	EndIf;
	
	// 
	If ClosingNotification1 <> Undefined Then
		OpenForm(FullFormName, WriteParameters, OwnerForm, , , , ClosingNotification1);
	Else
		OpenForm(FullFormName, WriteParameters, OwnerForm);
	EndIf;
	
EndProcedure

Procedure InitIdleHandlerParameters(IdleHandlerParameters) Export
	
	IdleHandlerParameters = New Structure;
	IdleHandlerParameters.Insert("MinInterval", 1);
	IdleHandlerParameters.Insert("MaxInterval", 15);
	IdleHandlerParameters.Insert("CurrentInterval", 1);
	IdleHandlerParameters.Insert("IntervalIncreaseCoefficient", 1.4);
	
EndProcedure

Procedure UpdateIdleHandlerParameters(IdleHandlerParameters) Export
	
	IdleHandlerParameters.CurrentInterval = Min(IdleHandlerParameters.MaxInterval,
		Round(IdleHandlerParameters.CurrentInterval * IdleHandlerParameters.IntervalIncreaseCoefficient, 1));
		
EndProcedure

// Opens the data exchange execution form for the specified exchange plan node.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef -  exchange plan node to open the form for;
//  Owner               - Form-owner for the form to open;
// 
Procedure ExecuteDataExchangeCommandProcessing(InfobaseNode, Owner,
		AccountPasswordRecoveryAddress = "", Val AutoSynchronization = Undefined, AdditionalParameters = Undefined) Export
	
	If AutoSynchronization = Undefined Then
		AutoSynchronization = (DataExchangeServerCall.DataExchangeOption(InfobaseNode) = "Synchronization");
	EndIf;
	
	WizardFormName = "";
	
	FormParameters = New Structure;
	FormParameters.Insert("InfobaseNode", InfobaseNode);
	
	If AutoSynchronization Then
		WizardFormName = "DataProcessor.DataExchangeExecution.Form";
		FormParameters.Insert("AccountPasswordRecoveryAddress", AccountPasswordRecoveryAddress);
	Else
		WizardFormName = "DataProcessor.InteractiveDataExchangeWizard.Form";
		FormParameters.Insert("AdvancedExportAdditionMode", True);
	EndIf;

	ClosingNotification1 = Undefined;
	
	If Not AdditionalParameters = Undefined Then
		
		If AdditionalParameters.Property("WizardParameters") Then
			For Each CurrentParameter In AdditionalParameters.WizardParameters Do
				FormParameters.Insert(CurrentParameter.Key, CurrentParameter.Value);
			EndDo;
		EndIf;
		
		AdditionalParameters.Property("ClosingNotification1", ClosingNotification1);
		
	EndIf;
	
	OpenForm(WizardFormName,
		FormParameters, Owner, InfobaseNode.UUID(), , , ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Starts getting a file from the server interactively, without an extension for working with files.
//
// Parameters:
//     FileToReceive   - Structure -  description of the file to get. Contains the Name and Storage properties.
//     DialogParameters - Structure -  optional additional parameters of the file selection dialog.
//
Procedure SelectAndSaveFileAtClient(Val FileToReceive, Val DialogParameters = Undefined) Export
	
	DefaultDialogOptions = New Structure;
	DefaultDialogOptions.Insert("Title",               NStr("en = 'Select file to download';"));
	DefaultDialogOptions.Insert("MultipleChoice",      False);
	DefaultDialogOptions.Insert("Preview", False);
	
	SetDefaultStructureValues(DialogParameters, DefaultDialogOptions);
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	FillPropertyValues(SavingParameters.Dialog, DialogParameters);
	
	FileSystemClient.SaveFile(Undefined, FileToReceive.Location, FileToReceive.Name, SavingParameters);
	
EndProcedure

Procedure OpenDataSynchronizationSettings() Export
	
	OpenForm("CommonForm.DataSyncSettings");
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 

// Returns the maximum allowed number of fields
// that are displayed in the information security object mapping assistant.
//
// Returns:
//     Number - 
//
Function MaxObjectsMappingFieldsCount() Export
	
	Return 5;
	
EndFunction

// Returns the structure of data loading progress statuses.
//
Function DataImportStatusPages() Export
	
	Structure = New Structure;
	Structure.Insert("Undefined", "ImportStatusUndefined");
	Structure.Insert("Error",       "ImportStatusError");
	Structure.Insert("Success",        "ImportStateSuccess");
	Structure.Insert("Perform",   "ImportStatusExecution");
	
	Structure.Insert("Warning_ExchangeMessageAlreadyAccepted", "ImportStatusWarning");
	Structure.Insert("CompletedWithWarnings",                     "ImportStatusWarning");
	Structure.Insert("ErrorMessageTransport",                      "ImportStatusError");
	
	Return Structure;
EndFunction

// Returns the structure status of implementation of discharge data.
//
Function DataExportStatusPages() Export
	
	Structure = New Structure;
	Structure.Insert("Undefined", "ExportStatusUndefined");
	Structure.Insert("Error",       "ExportStatusError");
	Structure.Insert("Success",        "ExportStatusSuccess");
	Structure.Insert("Perform",   "ExportStatusExecution");
	
	Structure.Insert("Warning_ExchangeMessageAlreadyAccepted", "ExportStatusWarning");
	Structure.Insert("CompletedWithWarnings",                     "ExportStatusWarning");
	Structure.Insert("ErrorMessageTransport",                      "ExportStatusError");
	
	Return Structure;
EndFunction

// Returns a structure with the hyperlink name of the data loading field.
//
Function DataImportHyperlinksHeaders() Export
	
	Structure = New Structure;
	Structure.Insert("Undefined",               NStr("en = 'Data was not received';"));
	Structure.Insert("Error",                     NStr("en = 'Could not receive data';"));
	Structure.Insert("CompletedWithWarnings", NStr("en = 'Data was received with warnings';"));
	Structure.Insert("Success",                      NStr("en = 'Data was received';"));
	Structure.Insert("Perform",                 NStr("en = 'Receiving data…';"));
	
	Structure.Insert("Warning_ExchangeMessageAlreadyAccepted", NStr("en = 'No new data to receive';"));
	Structure.Insert("ErrorMessageTransport",                      NStr("en = 'Could not receive data';"));
	
	Return Structure;
EndFunction

// Returns a structure with the hyperlink name of the data upload field.
//
Function DataExportHyperlinksHeaders() Export
	
	Structure = New Structure;
	Structure.Insert("Undefined", NStr("en = 'Data was not sent';"));
	Structure.Insert("Error",       NStr("en = 'Could not send data';"));
	Structure.Insert("Success",        NStr("en = 'Data was sent';"));
	Structure.Insert("Perform",   NStr("en = 'Sending data…';"));
	
	Structure.Insert("Warning_ExchangeMessageAlreadyAccepted", NStr("en = 'Data was sent with warnings';"));
	Structure.Insert("CompletedWithWarnings",                     NStr("en = 'Data was sent with warnings';"));
	Structure.Insert("ErrorMessageTransport",                      NStr("en = 'Could not send data';"));
	
	Return Structure;
EndFunction

// Opens a form or hyperlink with a detailed description of data synchronization.
//
Procedure OpenSynchronizationDetails(RefToDetails) Export
	
	If Upper(Left(RefToDetails, 4)) = "HTTP" Then
		
		FileSystemClient.OpenURL(RefToDetails);
		
	Else
		
		OpenForm(RefToDetails);
		
	EndIf;
	
EndProcedure

// Opens a form to enter the parameters of the proxy server.
//
Procedure OpenProxyServerParametersForm() Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownloadClient = CommonClient.CommonModule("GetFilesFromInternetClient");
		
		FormParameters = Undefined;
		If CommonClient.FileInfobase() Then
			FormParameters = New Structure("ProxySettingAtClient", True);
		EndIf;
		
		ModuleNetworkDownloadClient.OpenProxyServerParametersForm(FormParameters);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// For internal use only.
//
Procedure RetryDataExchangeMessageImportBeforeStartInteractiveHandler(Parameters, Context) Export
	
	Form = OpenForm(
		"InformationRegister.DataExchangeTransportSettings.Form.DataReSyncBeforeStart", , , , , ,
		New NotifyDescription(
			"AfterCloseFormDataResynchronizationBeforeStart", ThisObject, Parameters));
	
	If Form = Undefined Then
		AfterCloseFormDataResynchronizationBeforeStart("Continue", Parameters);
	EndIf;
	
EndProcedure

// For internal use only. Continuation of the procedure.
// Interactive processing re-booting the message exchange before starting.
//
Procedure AfterCloseFormDataResynchronizationBeforeStart(Result, Parameters) Export
	
	If Result <> "Continue" Then
		Parameters.Cancel = True;
	Else
		Parameters.RetrievedClientParameters.Insert(
			"RetryDataExchangeMessageImportBeforeStart");
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continuation of the procedure.
// Permanentrepresentative.
//
Procedure SetupFormBeforeCloseCompletion(Response, Form) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Form.Modified = False;
	Form.Close();
	
	// 
	RefreshReusableValues();
EndProcedure

// Opens a file in the associated operating system application.
//
// Parameters:
//     Object               - Arbitrary -  object from which the name of the property will be used to get the name of the file to open.
//     PropertyName          - String       -  name of the object property from which the file name to open will be obtained.
//     StandardProcessing - Boolean       -  the standard processing flag is set to False.
//
Procedure FileOrDirectoryOpenHandler(Object, PropertyName, StandardProcessing = False) Export
	StandardProcessing = False;
	
	FullFileName = Object[PropertyName];
	If IsBlankString(FullFileName) Then
		Return;
	EndIf;
	
	FileSystemClient.OpenExplorer(FullFileName);
	
EndProcedure

// Opens a dialog for selecting a file directory, requesting the installation of an extension for working with files.
//
// Parameters:
//     Object                - Arbitrary       -  the object where the selected property will be set.
//     PropertyName           - String             -  name of the property with the name of the file to set in the object. Source
//                                                  of the initial value.
//     StandardProcessing  - Boolean             -  the standard processing flag is set to False.
//     DialogParameters      - Structure          -  optional additional parameters of the folder selection dialog.
//     CompletionNotification  - NotifyDescription - 
//                                                  :
//                                 
//                                                                    
//                                 
//
Procedure FileDirectoryChoiceHandler(Object, Val PropertyName, StandardProcessing = False, Val DialogParameters = Undefined, CompletionNotification = Undefined) Export
	StandardProcessing = False;
	
	DefaultDialogOptions = New Structure;
	DefaultDialogOptions.Insert("Title", NStr("en = 'Select directory';") );
	
	SetDefaultStructureValues(DialogParameters, DefaultDialogOptions);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object",               Object);
	AdditionalParameters.Insert("PropertyName",          PropertyName);
	AdditionalParameters.Insert("DialogParameters",     DialogParameters);
	AdditionalParameters.Insert("CompletionNotification", CompletionNotification);
	
	Notification = New NotifyDescription("FileDirectoryChoiceHandlerCompletionAfterChoiceInDialog", ThisObject, AdditionalParameters);
	
	FileSystemClient.SelectDirectory(Notification, DialogParameters.Title);
	
EndProcedure

// 
// 
Procedure FileDirectoryChoiceHandlerCompletionAfterChoiceInDialog(PathToDirectory, AdditionalParameters) Export
	
	If Not ValueIsFilled(PathToDirectory) Then
		Return;
	EndIf;
	
	Object = AdditionalParameters.Object;
	Object[AdditionalParameters.PropertyName] = PathToDirectory;
	
	If AdditionalParameters.CompletionNotification <> Undefined Then
		ExecuteNotifyProcessing(AdditionalParameters.CompletionNotification, PathToDirectory);
	EndIf;
	
EndProcedure

// Opens a dialog for selecting a file, requesting the installation of an extension for working with files.
//
// Parameters:
//     Object                - Arbitrary       -  the object where the selected property will be set.
//     PropertyName           - String             -  name of the property with the name of the file to set in the object. Source
//                                                  of the initial value.
//     StandardProcessing  - Boolean             -  the standard processing flag is set to False.
//     DialogParameters      - Structure          - 
//     CompletionNotification  - NotifyDescription - 
//                                                  :
//                                 
//                                                         - Undefined - 
//                                                                          
//                                                                          
//                                 
//
//
Procedure FileSelectionHandler(Object, Val PropertyName, StandardProcessing = False, Val DialogParameters = Undefined, CompletionNotification = Undefined) Export
	
	StandardProcessing = False;
	
	DefaultDialogOptions = New Structure;
	DefaultDialogOptions.Insert("Mode",                       FileDialogMode.Open);
	DefaultDialogOptions.Insert("CheckFileExist", True);
	DefaultDialogOptions.Insert("Title",                   NStr("en = 'Select file';"));
	DefaultDialogOptions.Insert("MultipleChoice",          False);
	DefaultDialogOptions.Insert("Preview",     False);
	DefaultDialogOptions.Insert("FullFileName",              Object[PropertyName]);
	
	SetDefaultStructureValues(DialogParameters, DefaultDialogOptions);
	
	Dialog = New FileDialog(DialogParameters.Mode);
	FillPropertyValues(Dialog, DialogParameters);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object",               Object);
	AdditionalParameters.Insert("PropertyName",          PropertyName);
	AdditionalParameters.Insert("CompletionNotification", CompletionNotification);
	
	Notification = New NotifyDescription("FileSelectionHandlerCompletion", ThisObject, AdditionalParameters);
	
	FileSystemClient.ShowSelectionDialog(Notification, Dialog);
	
EndProcedure

// Handler for the asynchronous file selection dialog (completion).
//
Procedure FileSelectionHandlerCompletion(SelectedFiles, AdditionalParameters) Export
	
	If Not ValueIsFilled(SelectedFiles) Then
		Return;
	EndIf;
	
	Object      = AdditionalParameters.Object;
	PropertyName = AdditionalParameters.PropertyName;
	
	Result = Undefined;
	
	If SelectedFiles.Count() > 1 Then
		Result = SelectedFiles;
	Else
		Result = SelectedFiles[0];
		
		Object[PropertyName] = Result;
	EndIf;
	
	If Not AdditionalParameters.CompletionNotification = Undefined Then
		ExecuteNotifyProcessing(AdditionalParameters.CompletionNotification, Result);
	EndIf;
	
EndProcedure

// Sends the file to the server interactively, without an extension for working with files.
//
// Parameters:
//     CompletionNotification - NotifyDescription - 
//                                                 :
//                                
//                                
//
//     DialogParameters     - Structure                       -  optional additional parameters
//                                                              of the file selection dialog.
//     FormIdentifier   - String
//                          - UUID - 
//
Procedure SelectAndSendFileToServer(CompletionNotification, Val DialogParameters = Undefined, Val FormIdentifier = Undefined) Export
	
	DefaultDialogOptions = New Structure;
	DefaultDialogOptions.Insert("CheckFileExist", True);
	DefaultDialogOptions.Insert("Title",                   NStr("en = 'Select file';"));
	DefaultDialogOptions.Insert("MultipleChoice",          False);
	DefaultDialogOptions.Insert("Preview",     False);
	
	SetDefaultStructureValues(DialogParameters, DefaultDialogOptions);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CompletionNotification", CompletionNotification);
	
	Notification = New NotifyDescription("SelectAndSendFileToServerAfterChoiceInDialogCompletion", ThisObject, AdditionalParameters);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = FormIdentifier;
	FillPropertyValues(ImportParameters.Dialog, DialogParameters);
	
	FileSystemClient.ImportFile_(Notification, ImportParameters);

EndProcedure

// Handler for non-modal completion of file selection and transfer to the server.
//
Procedure SelectAndSendFileToServerAfterChoiceInDialogCompletion(FileThatWasPut, AdditionalParameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	Result  = New Structure("Name, Location, ErrorDescription");
	Result.Name      = FileThatWasPut.Name;
	Result.Location = FileThatWasPut.Location;
	
	// 
	ExecuteNotifyProcessing(AdditionalParameters.CompletionNotification, Result);
	
EndProcedure

// Adds fields to the target structure if they are not there.
//
// Parameters:
//     Result           - Structure -  target structure.
//     DefaultValues - Structure
//
Procedure SetDefaultStructureValues(Result, Val DefaultValues)
	
	If Result = Undefined Then
		Result = New Structure;
	EndIf;
	
	For Each KeyValue In DefaultValues Do
		PropertyName = KeyValue.Key;
		If Not Result.Property(PropertyName) Then
			Result.Insert(PropertyName, KeyValue.Value);
		EndIf;
	EndDo;
	
EndProcedure

// Opens the form for uploading conversion and registration rules as a single file.
//
Procedure ImportDataSyncRules(Val ExchangePlanName) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ExchangePlanName", ExchangePlanName);
	
	OpenForm("InformationRegister.DataExchangeRules.Form.ImportDataSyncRules", FormParameters,, ExchangePlanName);
	
EndProcedure

// Opens the log with selection based on data upload or download events for the specified exchange plan node.
// 
Procedure GoToDataEventLog(InfobaseNode, CommandExecuteParameters, ActionOnStringExchange) Export
	
	EventLogEvent = DataExchangeServerCall.EventLogMessageKeyByActionString(InfobaseNode, ActionOnStringExchange);
	
	FormParameters = New Structure;
	FormParameters.Insert("EventLogEvent", EventLogEvent);
	
	OpenForm("DataProcessor.EventLog.Form", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure

Function DataExchangeEventLogEvent() Export
	
	Return NStr("en = 'Data exchange';", CommonClient.DefaultLanguageCode());
	
EndFunction

// Opens the interactive data exchange execution form for the specified exchange plan node.
//
// Parameters:
//  InfobaseNode  - ExchangePlanRef -  exchange plan node to open the form for;
//  Owner                - Form-owner for the form to open;
//  AdditionalParameters - Structure - :
//    * WizardParameters  - Structure -  custom structure that will be passed to the helper form that opens;
//    * ClosingNotification1 - NotifyDescription -  description of the alert that will be triggered when the assistant form is closed.
//
Procedure OpenObjectsMappingWizardCommandProcessing(InfobaseNode,
		Owner, AdditionalParameters = Undefined) Export
	
	// 
	// 
	FormParameters = New Structure("InfobaseNode", InfobaseNode);
	FormParameters.Insert("AdvancedExportAdditionMode", True);
	
	ClosingNotification1 = Undefined;
	
	If Not AdditionalParameters = Undefined Then
		
		If AdditionalParameters.Property("WizardParameters") Then
			For Each CurrentParameter In AdditionalParameters.WizardParameters Do
				FormParameters.Insert(CurrentParameter.Key, CurrentParameter.Value);
			EndDo;
		EndIf;
		
		AdditionalParameters.Property("ClosingNotification1", ClosingNotification1);
		
	EndIf;
	
	OpenForm("DataProcessor.InteractiveDataExchangeWizard.Form",
		FormParameters, Owner, InfobaseNode.UUID(), , , ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Opens the new data synchronization settings form.
//
Procedure OpenNewDataSynchronizationSettingForm(NewDataSynchronizationForm = "", AdditionalParameters = Undefined) Export
	
	If IsBlankString(NewDataSynchronizationForm) Then
		NewDataSynchronizationForm = "DataProcessor.DataExchangeCreationWizard.Form.NewDataSynchronization";
	EndIf;
	
	OpenForm(NewDataSynchronizationForm, AdditionalParameters);
	
EndProcedure

// Opens the list of data exchange scenarios form for the specified exchange plan node.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef -  exchange plan node to open the form for;
//  Owner               - Form-owner for the form to open;
//
Procedure SetExchangeExecutionScheduleCommandProcessing(InfobaseNode, Owner) Export
	
	FormParameters = New Structure("InfobaseNode", InfobaseNode);
	
	OpenForm("Catalog.DataExchangeScenarios.Form.DataExchangesScheduleSetup", FormParameters, Owner);
	
EndProcedure

// Notifies all open dynamic lists to update the displayed data.
//
Procedure RefreshAllOpenDynamicLists() Export
	
	Types = DataExchangeServerCall.AllConfigurationReferenceTypes();
	
	For Each Type In Types Do
		
		NotifyChanged(Type);
		
	EndDo;
	
EndProcedure

// Registers a handler for opening a new form immediately after closing the current one.
// 
Procedure OpenFormAfterCloseCurrentOne(CurrentForm, Val FormName, Val Parameters = Undefined, Val OpeningParameters = Undefined) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormName",          FormName);
	AdditionalParameters.Insert("Parameters",         Parameters);
	AdditionalParameters.Insert("OpeningParameters", OpeningParameters);
	
	AdditionalParameters.Insert("PreviousClosingNotification",  CurrentForm.OnCloseNotifyDescription);
	
	CurrentForm.OnCloseNotifyDescription = New NotifyDescription("FormOpeningHandlerAfterCloseCurrentOne", ThisObject, AdditionalParameters);
EndProcedure

// Delayed opening
Procedure FormOpeningHandlerAfterCloseCurrentOne(Val ClosingResult, Val AdditionalParameters) Export
	
	OpeningParameters = New Structure("Owner, Uniqueness, Window, URL, OnCloseNotifyDescription, WindowOpeningMode");
	FillPropertyValues(OpeningParameters, AdditionalParameters.OpeningParameters);
	OpenForm(AdditionalParameters.FormName, AdditionalParameters.Parameters,
		OpeningParameters.Owner, OpeningParameters.Uniqueness, OpeningParameters.Window, 
		OpeningParameters.URL, OpeningParameters.OnCloseNotifyDescription, OpeningParameters.WindowOpeningMode);
	
	If AdditionalParameters.PreviousClosingNotification <> Undefined Then
		ExecuteNotifyProcessing(AdditionalParameters.PreviousClosingNotification, ClosingResult);
	EndIf;
	
EndProcedure

// Opens instructions for restoring / changing the password for syncing data
// with an offline workplace.
//
Procedure OpenInstructionHowToChangeDataSynchronizationPassword(Val AccountPasswordRecoveryAddress) Export
	
	If IsBlankString(AccountPasswordRecoveryAddress) Then
		
		ShowMessageBox(, NStr("en = 'The address of the password recovery instruction is not specified.';"));
		
	Else
		
		FileSystemClient.OpenURL(AccountPasswordRecoveryAddress);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

Procedure OnCloseExchangePlanNodeSettingsForm(Form, FormAttributeName)
	
	If Not Form.CheckFilling() Then
		Return;
	EndIf;
	
	For Each FilterSettings In Form[FormAttributeName] Do
		
		If TypeOf(Form[FilterSettings.Key]) = Type("FormDataCollection") Then
			
			TabularSectionStructure = Form[FormAttributeName][FilterSettings.Key];
			
			For Each Item In TabularSectionStructure Do
				
				TabularSectionStructure[Item.Key].Clear();
				
				For Each CollectionRow In Form[FilterSettings.Key] Do
					
					TabularSectionStructure[Item.Key].Add(CollectionRow[Item.Key]);
					
				EndDo;
				
			EndDo;
			
		Else
			
			Form[FormAttributeName][FilterSettings.Key] = Form[FilterSettings.Key];
			
		EndIf;
		
	EndDo;
	
	Form.Modified = False;
	Form.Close(Form[FormAttributeName]);
	
EndProcedure

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
// 
//

// Processing interactive extension dialogs.
//
// Parameters:
//     ExportAddition           - Structure
//                                  - FormDataStructure - 
//     Owner, Uniqueness, Window-parameters for opening the form window.
//
// Returns:
//     Open form
//
Function OpenExportAdditionFormNodeScenario(Val ExportAddition, Val Owner=Undefined, Val Uniqueness=Undefined, Val Window=Undefined) Export
	
	FormParameters = New Structure("ChoiceMode, CloseOnChoice", True, True);
	FormParameters.Insert("InfobaseNode", ExportAddition.InfobaseNode);
	FormParameters.Insert("FilterPeriod1",           ExportAddition.NodeScenarioFilterPeriod);
	FormParameters.Insert("Filter",                  ExportAddition.AdditionalNodeScenarioRegistration);

	Return OpenForm(ExportAddition.AdditionScenarioParameters.AdditionalOption.FilterFormName,
		FormParameters, Owner, Uniqueness, Window);
EndFunction

// Processing interactive extension dialogs.
//
// Parameters:
//     ExportAddition           - Structure
//                                  - FormDataStructure - 
//     Owner, Uniqueness, Window-parameters for opening the form window.
//
// Returns:
//     Open form
//
Function OpenExportAdditionFormAllDocuments(Val ExportAddition, Val Owner=Undefined, Val Uniqueness=Undefined, Val Window=Undefined) Export
	FormParameters = New Structure;
	
	FormParameters.Insert("Title", NStr("en = 'Add documents to send';") );
	FormParameters.Insert("ChoiceAction", 1);
	
	FormParameters.Insert("PeriodSelection", True);
	FormParameters.Insert("DataPeriod", ExportAddition.AllDocumentsFilterPeriod);
	
	FormParameters.Insert("SettingsComposerAddress", ExportAddition.AllDocumentsComposerAddress);
	
	FormParameters.Insert("FormStorageAddress", ExportAddition.FormStorageAddress);
	
	Return OpenForm("DataProcessor.InteractiveExportChange.Form.PeriodAndFilterEdit", 
		FormParameters, Owner, Uniqueness, Window);
EndFunction

// Processing interactive extension dialogs.
//
// Parameters:
//     ExportAddition           - Structure
//                                  - FormDataStructure - 
//     Owner, Uniqueness, Window-parameters for opening the form window.
//
// Returns:
//     Open form
//
Function OpenExportAdditionFormDetailedFilter(Val ExportAddition, Val Owner=Undefined, Val Uniqueness=Undefined, Val Window=Undefined) Export
	FormParameters = New Structure;
	
	FormParameters.Insert("ChoiceAction", 2);
	FormParameters.Insert("ObjectSettings", ExportAddition);
	
	FormParameters.Insert("OpenByScenario", True);
	Return OpenForm("DataProcessor.InteractiveExportChange.Form", 
		FormParameters, Owner, Uniqueness, Window);
EndFunction

// Processing interactive extension dialogs.
//
// Parameters:
//     ExportAddition           - Structure
//                                  - FormDataStructure - 
//     Owner, Uniqueness, Window-parameters for opening the form window.
//
// Returns:
//     Open form
//
Function OpenExportAdditionFormDataComposition(Val ExportAddition, Val Owner=Undefined, Val Uniqueness=Undefined, Val Window=Undefined) Export
	FormParameters = New Structure;
	
	FormParameters.Insert("ObjectSettings", ExportAddition);
	If ExportAddition.ExportOption=3 Then
		FormParameters.Insert("SimplifiedMode", True);
	EndIf;
	
	Return OpenForm("DataProcessor.InteractiveExportChange.Form.ExportComposition",
		FormParameters, Owner, Uniqueness, Window);
EndFunction

// Processing interactive extension dialogs.
//
// Parameters:
//     ExportAddition           - Structure
//                                  - FormDataStructure - 
//     Owner, Uniqueness, Window-parameters for opening the form window.
//
// Returns:
//     Open form
//
Function OpenExportAdditionFormSaveSettings(Val ExportAddition, Val Owner=Undefined, Val Uniqueness=Undefined, Val Window=Undefined) Export
	FormParameters = New Structure("CloseOnChoice, ChoiceAction", True, 3);
	
	// 
	ExportAddition.AllDocumentsFilterComposer = Undefined;
	
	FormParameters.Insert("CurrentSettingsItemPresentation", ExportAddition.CurrentSettingsItemPresentation);
	FormParameters.Insert("Object", ExportAddition);
	
	Return OpenForm("DataProcessor.InteractiveExportChange.Form.SettingsCompositionEdit",
		FormParameters, Owner, Uniqueness, Window);
EndFunction

// Selection handler for the upload extension helpers form.
// The function analyzes the source for a call from the upload add-on and operates with the data of the upload Add-on.
//
// Parameters:
//     ValueSelected  - Arbitrary                    -  election result.
//     ChoiceSource     - ClientApplicationForm                -  the form that made the selection.
//     ExportAddition - Structure
//                        - FormDataCollection - 
//
// Returns:
//     Boolean - 
//
Function ExportAdditionChoiceProcessing(Val ValueSelected, Val ChoiceSource, ExportAddition) Export
	
	If ChoiceSource.FormName="DataProcessor.InteractiveExportChange.Form.PeriodAndFilterEdit" Then
		// 
		Return ExportAdditionStandardOptionChoiceProcessing(ValueSelected, ExportAddition);
		
	ElsIf ChoiceSource.FormName="DataProcessor.InteractiveExportChange.Form.Form" Then
		// 
		Return ExportAdditionStandardOptionChoiceProcessing(ValueSelected, ExportAddition);
		
	ElsIf ChoiceSource.FormName="DataProcessor.InteractiveExportChange.Form.SettingsCompositionEdit" Then
		// 
		Return ExportAdditionStandardOptionChoiceProcessing(ValueSelected, ExportAddition);
		
	ElsIf ChoiceSource.FormName=ExportAddition.AdditionScenarioParameters.AdditionalOption.FilterFormName Then
		// 
		Return ExportAdditionNodeScenarioChoiceProcessing(ValueSelected, ExportAddition);
		
	EndIf;
	
	Return False;
EndFunction

Procedure FillStructureData(Form)
	
	// 
	SettingsStructure_ = Form.Context.NodeFiltersSetting;
	MatchingAttributes = Form.AttributesNames;
	
	For Each SettingItem In SettingsStructure_ Do
		
		If MatchingAttributes.Property(SettingItem.Key) Then
			
			AttributeName = MatchingAttributes[SettingItem.Key];
			
		Else
			
			AttributeName = SettingItem.Key;
			
		EndIf;
		
		FormAttribute = Form[AttributeName];
		
		If TypeOf(FormAttribute) = Type("FormDataCollection") Then
			
			TableName = SettingItem.Key;
			
			Table = New Array;
			
			For Each Item In Form[AttributeName] Do
				
				TableRow = New Structure("Use, Presentation, RefUUID");
				
				FillPropertyValues(TableRow, Item);
				
				Table.Add(TableRow);
				
			EndDo;
			
			SettingsStructure_.Insert(TableName, Table);
			
		Else
			
			SettingsStructure_.Insert(SettingItem.Key, Form[AttributeName]);
			
		EndIf;
		
	EndDo;
	
	Form.Context.NodeFiltersSetting = SettingsStructure_;
	
	// 
	SettingsStructure_ = Form.Context.CorrespondentInfobaseNodeFilterSetup;
	MatchingAttributes = Form.NamesOfCorrespondentsDatabaseDetails;
	
	For Each SettingItem In SettingsStructure_ Do
		
		If MatchingAttributes.Property(SettingItem.Key) Then
			
			AttributeName = MatchingAttributes[SettingItem.Key];
			
		Else
			
			AttributeName = SettingItem.Key;
			
		EndIf;
		
		FormAttribute = Form[AttributeName];
		
		If TypeOf(FormAttribute) = Type("FormDataCollection") Then
			
			TableName = SettingItem.Key;
			
			Table = New Array;
			
			For Each Item In Form[AttributeName] Do
				
				TableRow = New Structure("Use, Presentation, RefUUID");
				
				FillPropertyValues(TableRow, Item);
				
				Table.Add(TableRow);
				
			EndDo;
			
			SettingsStructure_.Insert(TableName, Table);
			
		Else
			
			SettingsStructure_.Insert(SettingItem.Key, Form[AttributeName]);
			
		EndIf;
		
	EndDo;
	
	Form.Context.CorrespondentInfobaseNodeFilterSetup = SettingsStructure_;
	
	Form.Context.Insert("ContextDetails", Form.ContextDetails);
	
EndProcedure

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
// 
//

Function ExportAdditionStandardOptionChoiceProcessing(Val ValueSelected, ExportAddition)
	
	Result = False;
	If TypeOf(ValueSelected)=Type("Structure") Then 
		
		If ValueSelected.ChoiceAction=1 Then
			// 
			ExportAddition.AllDocumentsFilterComposer = Undefined;
			ExportAddition.AllDocumentsComposerAddress = ValueSelected.SettingsComposerAddress;
			ExportAddition.AllDocumentsFilterPeriod      = ValueSelected.DataPeriod;
			Result = True;
			
		ElsIf ValueSelected.ChoiceAction=2 Then
			// 
			SelectionObject = GetFromTempStorage(ValueSelected.ObjectAddress);
			FillPropertyValues(ExportAddition, SelectionObject, , "AdditionalRegistration");
			ExportAddition.AdditionalRegistration.Clear();
			For Each String In SelectionObject.AdditionalRegistration Do
				FillPropertyValues(ExportAddition.AdditionalRegistration.Add(), String);
			EndDo;
			Result = True;
			
		ElsIf ValueSelected.ChoiceAction=3 Then
			// 
			ExportAddition.CurrentSettingsItemPresentation = ValueSelected.SettingPresentation;
			Result = True;
			
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

Function ExportAdditionNodeScenarioChoiceProcessing(Val ValueSelected, ExportAddition)
	If TypeOf(ValueSelected)<>Type("Structure") Then 
		Return False;
	EndIf;
	
	ExportAddition.NodeScenarioFilterPeriod        = ValueSelected.FilterPeriod1;
	ExportAddition.NodeScenarioFilterPresentation = ValueSelected.FilterPresentation;
	
	ExportAddition.AdditionalNodeScenarioRegistration.Clear();
	For Each RegistrationLine In ValueSelected.Filter Do
		FillPropertyValues(ExportAddition.AdditionalNodeScenarioRegistration.Add(), RegistrationLine);
	EndDo;
	
	Return True;
EndFunction

Function CheckAndRegisterCOMConnector(Val SettingsStructure_, Notification = Undefined) Export
	
	If Not CommonClient.FileInfobase() Then
		Return True;
	EndIf;
	
	If Not DataExchangeServerCall.CheckAndRegisterCOMConnector(SettingsStructure_) Then
		CommonClient.RegisterCOMConnector(False, Notification);
	EndIf;
	
EndFunction

#EndRegion