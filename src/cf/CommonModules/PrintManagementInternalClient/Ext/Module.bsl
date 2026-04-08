///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Attachable command clarifying handler.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - references to the selected objects for which a command is being executed.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure BeforeExecutingCommand(ReferencesArrray, ExecutionParameters) Export
	
	If ExecutionParameters.CommandDetails.Handler <> "PrintManagementInternalClient.HandlerCommands"
	 Or ExecutionParameters.CommandDetails.AdditionalParameters.PrintManager <> "StandardSubsystems.AdditionalReportsAndDataProcessors"
	 Or TypeOf(ReferencesArrray) <> Type("Array")
	 Or Not CommonClient.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	ModuleAdditionalReportsAndDataProcessorsClient = CommonClient.CommonModule("AdditionalReportsAndDataProcessorsClient");
	ModuleAdditionalReportsAndDataProcessorsClient.BeforeExecutingPrintCommands(ReferencesArrray, ExecutionParameters);
	
EndProcedure

// The attached command handler.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef - references to the selected objects for which a command is being executed.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure HandlerCommands(Val ReferencesArrray, Val ExecutionParameters) Export
	ExecutionParameters.Insert("PrintObjects", ReferencesArrray);
	CommandDetails = ExecutionParameters.CommandDetails;
	CommonClientServer.SupplementStructure(CommandDetails, CommandDetails.AdditionalParameters, True);
	
	If CommandDetails.DefaultCommand Then
		DefaultPrintOptions = PrintManagementServerCall.DefaultPrintExecutionParameters(ReferencesArrray);
		If DefaultPrintOptions.HasExecutionParameters Then
			For Each NewParameters In DefaultPrintOptions.NewExecutionParameters Do
				FillPropertyValues(ExecutionParameters, NewParameters);
				RunConnectedPrintCommandCompletion(True, ExecutionParameters);
			EndDo;
		Else
			NewExecutionParameters = DefaultPrintOptions.NewExecutionParameters;
			If NewExecutionParameters.Count() = 0 Then
				ShowMessageBox( , NStr("en = 'The object does not support this type of operations.'"));
				Return;
			EndIf;
			
			NewParameters = NewExecutionParameters[0];
			ListOfCommands = NewParameters.CommandsForSelection;
			
			NotificationParameters = New Structure;
			NotificationParameters.Insert("TeamDescriptions", NewParameters.TeamDescriptions);
			NotificationParameters.Insert("ExecutionParameters", ExecutionParameters);
			
			Notification = New CallbackDescription("AfterSelectDefaultCommand", ThisObject, NotificationParameters);
			If ListOfCommands.Count() = 1 Then
				RunCallback(Notification, ListOfCommands[0]);
			ElsIf ListOfCommands.Count() = 0 Then
				ShowMessageBox( , NStr("en = 'The object does not support this type of operation.'"));
			Else
				ListOfCommands.ShowChooseItem(Notification, NStr("en = 'Select print form'"));
			EndIf;
		EndIf;
	Else
		Notification = New CallbackDescription("ContinueExecutionCommandHandler", ThisObject, ExecutionParameters);
		PrintManagementClient.BeforeStartExecutePrintCommand(ReferencesArrray, ExecutionParameters.CommandDetails, Notification);
	EndIf;
EndProcedure

// Generates a spreadsheet document in the Print subsystem form.
Procedure ExecutePrintFormOpening(DataSource, CommandID, RelatedObjects, Form, StandardProcessing) Export
	
	Parameters = New Structure;
	Parameters.Insert("Form",                Form);
	Parameters.Insert("DataSource",       DataSource);
	Parameters.Insert("CommandID", CommandID);
	
	If StandardProcessing Then
		CallbackDescription = New CallbackDescription("ExecutePrintFormOpeningCompletion", ThisObject, Parameters);
		PrintManagementClient.CheckDocumentsPosting(CallbackDescription, RelatedObjects, Form);
	Else
		ExecutePrintFormOpeningCompletion(RelatedObjects, Parameters);
	EndIf;
	
EndProcedure

// Opens a form for command visibility setting in the Print submenu.
Procedure OpenPrintSubmenuSettingsForm(Filter) Export
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Filter", Filter);
	OpenForm("CommonForm.PrintCommandsSetup", OpeningParameters, , , , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// Opening a form to select attachment format options.
//
// Parameters:
//  FormatSettings - Structure:
//       * PackToArchive   - Boolean - shows whether it is necessary to archive attachments.
//       * SaveFormats - Array - a list of the selected save formats.
//  Notification       - CallbackDescription - a notification called after closing the form for processing
//                                          the selection result.
//
Procedure OpenAttachmentsFormatSelectionForm(FormatSettings, Notification) Export
	FormParameters = New Structure("FormatSettings", FormatSettings);
	CommonClient.ShowAttachmentsFormatSelection(Notification, FormatSettings);
EndProcedure

// Opens the email message composition form.
// 
// Parameters:
//  OwnerForm  - ClientApplicationForm 
//  FormParameters - Structure:
//    * Recipient - String - list of addresses in the following format:
//                           [RecipientPresentation1] <Address1>; [[RecipientPresentation2] <Address2>;…]
//                 - ValueList:
//                     ** Presentation - String - Recipient's presentation.
//                     ** Value      - String - Email address.
//                 - Array - Array of structures with the recipient details:
//                     ** Address                        - String - Recipient's address.
//                     ** Presentation                - String - Recipient's presentation.
//                     ** ContactInformationSource - CatalogRef - Contact information owner. 
//  CallbackDescriptionOnCompletion - CallbackDescription
//
Procedure OpenNewMailPreparationForm(OwnerForm, FormParameters, CallbackDescriptionOnCompletion) Export
	OpenForm("CommonForm.ComposeNewMessage", FormParameters, OwnerForm,,,, CallbackDescriptionOnCompletion);
EndProcedure

Function ParametersForOpeningPrintForm() Export
	OpeningParameters = New Structure("PrintManagerName,TemplatesNames,CommandParameter,PrintParameters,StorageUUID,
	|DataSource,PrintFormsCollection,SourceParameters,CurrentLanguage,FormOwner,OutputParameters");
	OpeningParameters.Insert("PrintObjects", New ValueList);
	Return OpeningParameters;
EndFunction  

#EndRegion

#Region Private

Procedure RunConnectedPrintCommandCompletion(FileSystemExtensionAttached1, AdditionalParameters)
	
	If Not FileSystemExtensionAttached1 Then
		Return;
	EndIf;
	
	CommandDetails = AdditionalParameters.CommandDetails;
	Form = AdditionalParameters.Form;
	PrintObjects = AdditionalParameters.PrintObjects;
	
	CommandDetails = CommonClient.CopyRecursive(CommandDetails);
	CommandDetails.Insert("PrintObjects", PrintObjects);
	
	If CommonClient.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
		
		IndicatorName = NStr("en = 'Print'") + StringFunctionsClientServer.SubstituteParametersToString("/%1/%2/%3/%4/%5/%6/%7",
			CommandDetails.Id,
			CommandDetails.PrintManager,
			CommandDetails.Handler,
			Format(CommandDetails.PrintObjects.Count(), "NG=0"),
			?(CommandDetails.SkipPreview, "Printer", ""),
			CommandDetails.SaveFormat,
			?(CommandDetails.FixedSet, "Fixed", ""));
		
		ModulePerformanceMonitorClient.StartTechologicalTimeMeasurement(True, Lower(IndicatorName));
	EndIf;
	
	If CommandDetails.PrintManager = "StandardSubsystems.AdditionalReportsAndDataProcessors" 
		And CommonClient.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			ModuleAdditionalReportsAndDataProcessorsClient = CommonClient.CommonModule("AdditionalReportsAndDataProcessorsClient");
			ModuleAdditionalReportsAndDataProcessorsClient.ExecuteAssignablePrintCommand(CommandDetails, Form);
			Return;
	EndIf;
	
	If Not IsBlankString(CommandDetails.Handler) Then
		CommandDetails.Insert("Form", Form);
		HandlerName = CommandDetails.Handler;
		If StrOccurrenceCount(HandlerName, ".") = 0 And IsReportOrDataProcessor(CommandDetails.PrintManager) Then
			DefaultForm = GetForm(CommandDetails.PrintManager + ".Form", , Form, True);// ACC:65 - Form is created to call a method.
			HandlerName = "DefaultForm." + HandlerName;
		EndIf;
		PrintParameters = PrintManagementClient.DescriptionOfPrintParameters();
		FillPropertyValues(PrintParameters, CommandDetails);
		Handler = HandlerName + "(PrintParameters)";
		Result = Eval(Handler);
		
		CommandDetails.Delete("Form");
		UpdateCommands(Form, CommandDetails);
		
		Return;
	EndIf;
	
	If CommandDetails.SkipPreview Then
		ToPrinterCommandDetails = New Structure("Id,DefaultPrintForm,PrintFormDescription,
			|ReplaceDefaultPrintForm,IDFromSet");
		FillPropertyValues(ToPrinterCommandDetails, CommandDetails);
		CommandDetails.AdditionalParameters.Insert("CommandDetails", ToPrinterCommandDetails);
		PrintManagementClient.ExecutePrintToPrinterCommand(CommandDetails.PrintManager, CommandDetails.Id,
			PrintObjects, CommandDetails.AdditionalParameters);
	Else
		PrintManagementClient.ExecutePrintCommand(CommandDetails.PrintManager, CommandDetails.Id,
			PrintObjects, Form, CommandDetails);
	EndIf;
	
EndProcedure

Procedure CheckDocumentsPostedPostingDialog(Parameters) Export
	
	If Not Parameters.HasPostingRight Then
		If Parameters.UnpostedDocuments.Count() = 1 Then
			WarningText = NStr("en = 'To print the document, you must first post it. However, you do not have the required posting permissions. Printing is not possible.'");
		Else
			WarningText = NStr("en = 'To print the documents, you must first post them. However, you do not have the required posting permissions. Printing is not possible.'");
		EndIf;
		Raise(WarningText, ErrorCategory.AccessViolation);
	EndIf;

	If Parameters.UnpostedDocuments.Count() = 1 Then
		QueryText = NStr("en = 'To print the document, you must first post it. Do you want to post the document and continue?'");
	Else
		QueryText = NStr("en = 'To print the documents, you must first post them. Do you want to post the documents and continue?'");
	EndIf;
	CallbackDescription = New CallbackDescription("CheckDocumentsPostedDocumentsPosting", 
		ThisObject, Parameters);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

Procedure CheckDocumentsPostedDocumentsPosting(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ClearMessages();
	UnpostedDocumentsData = CommonClient.PostDocuments(AdditionalParameters.UnpostedDocuments);
	
	MessageTemplate = NStr("en = 'Document %1 is not posted: %2'");
	UnpostedDocuments = New Array;
	For Each DocumentInformation In UnpostedDocumentsData Do
		CommonClient.MessageToUser(
			StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, 
			String(DocumentInformation.Ref), DocumentInformation.ErrorDescription),
			DocumentInformation.Ref);
		UnpostedDocuments.Add(DocumentInformation.Ref);
	EndDo;
	PostedDocuments = CommonClientServer.ArraysDifference(AdditionalParameters.DocumentsList, 
		UnpostedDocuments);
	ModifiedDocuments = CommonClientServer.ArraysDifference(AdditionalParameters.UnpostedDocuments, 
		UnpostedDocuments);
	
	AdditionalParameters.Insert("UnpostedDocuments", UnpostedDocuments);
	AdditionalParameters.Insert("PostedDocuments", PostedDocuments);
	
	CommonClient.NotifyObjectsChanged(ModifiedDocuments);
	
	// If the command is called from a form, read the up-to-date (posted) copy from the infobase.
	If TypeOf(AdditionalParameters.Form) = Type("ClientApplicationForm") Then
		Try
			AdditionalParameters.Form.Read();
		Except
			// If the Read method is unavailable, printing was executed from a location other than the object form.
		EndTry;
	EndIf;
		
	If UnpostedDocuments.Count() > 0 Then
		// Asking a user whether they want to continue printing if there are unposted documents.
		DialogText = NStr("en = 'Failed to post one or several documents.'");
		
		DialogButtons = New ValueList;
		If PostedDocuments.Count() > 0 Then
			DialogText = DialogText + " " + NStr("en = 'Continue?'");
			DialogButtons.Add(DialogReturnCode.Ignore, NStr("en = 'Continue'"));
			DialogButtons.Add(DialogReturnCode.Cancel);
		Else
			DialogButtons.Add(DialogReturnCode.OK);
		EndIf;
		
		CallbackDescription = New CallbackDescription("CheckDocumentsPostingCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, DialogText, DialogButtons);
		Return;
	EndIf;
	
	CheckDocumentsPostingCompletion(Undefined, AdditionalParameters);
	
EndProcedure

Procedure CheckDocumentsPostingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> Undefined And QuestionResult <> DialogReturnCode.Ignore Then
		Return;
	EndIf;
	
	RunCallback(AdditionalParameters.CompletionProcedureDetails, AdditionalParameters.PostedDocuments);
	
EndProcedure

Function IsReportOrDataProcessor(PrintManager)
	If Not ValueIsFilled(PrintManager) Then
		Return False;
	EndIf;
	SubstringsArray = StrSplit(PrintManager, ".");
	If SubstringsArray.Count() = 0 Then
		Return False;
	EndIf;
	Kind = Upper(TrimAll(SubstringsArray[0]));
	Return Kind = "REPORT" Or Kind = "DATAPROCESSOR";
EndFunction

Procedure ExecutePrintFormOpeningCompletion(RelatedObjects, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	
	SourceParameters = New Structure;
	SourceParameters.Insert("CommandID", AdditionalParameters.CommandID);
	SourceParameters.Insert("RelatedObjects",    RelatedObjects);
	
	OpeningParameters = ParametersForOpeningPrintForm();
	OpeningParameters.Insert("DataSource",     AdditionalParameters.DataSource);
	OpeningParameters.Insert("SourceParameters", SourceParameters);
	OpeningParameters.Insert("CommandParameter", RelatedObjects);
	
	If Form = Undefined Then
		OpeningParameters.StorageUUID = New UUID;
	Else
		OpeningParameters.StorageUUID = Form.UUID;
	EndIf;

	ParameterName = "StandardSubsystems.Print.ExecutePrintCommand";
	PassedParametersList = ApplicationParameters[ParameterName];
	
	If PassedParametersList = Undefined Then
		PassedParametersList = New Array;
		ApplicationParameters[ParameterName] = PassedParametersList;
	EndIf;
	
	PassedParametersList.Add(OpeningParameters);
	
	AttachIdleHandler("ResumePrintCommandWithPassedParameters", 0.1, True);
	
EndProcedure

Procedure ResumePrintCommand() Export
	
	ParameterName = "StandardSubsystems.Print.ExecutePrintCommand";
	PassedParametersList = ApplicationParameters[ParameterName];
	
	If PassedParametersList = Undefined Then
		PassedParametersList = New Array;
		ApplicationParameters[ParameterName] = PassedParametersList;
		Return;
	EndIf;
	
	If PassedParametersList.Count() = 0 Then
		Return;
	EndIf;
	
	OpeningParameters = PassedParametersList[0];
	PrintParameters = OpeningParameters.PrintParameters;
	FormOwner = OpeningParameters.FormOwner;
	OpeningParameters.FormOwner = Undefined;
	PassedParametersList.Delete(0);
	AttachIdleHandler("ResumePrintCommandWithPassedParameters", 0.1, True);
	
	If TypeOf(PrintParameters) = Type("Structure")
		And PrintParameters.Property("ShouldRunInBackgroundJob")
		And PrintParameters.ShouldRunInBackgroundJob = True Then
		
		RunPrintCommandInBackground(FormOwner, OpeningParameters);
	Else
		OpenForm("CommonForm.PrintDocuments", OpeningParameters, FormOwner, String(New UUID));
		UpdateCommands(FormOwner, PrintParameters);
	EndIf;
	
EndProcedure

Procedure RunPrintCommandInBackground(FormOwner, OpeningParameters)
	
	If FormOwner = Undefined Then
		OpeningParameters.StorageUUID = New UUID;
	Else
		OpeningParameters.StorageUUID = FormOwner.UUID;
	EndIf;
	
	TimeConsumingOperation = PrintManagementServerCall.StartGeneratingPrintForms(OpeningParameters);
	OpeningParameters.FormOwner = FormOwner;
	
	CallbackOnCompletion = New CallbackDescription("OpenPrintDocumentsForm", ThisObject, OpeningParameters);
	IdleParameters = IdleParameters(FormOwner);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  OpeningParameters - Structure
//
Procedure OpenPrintDocumentsForm(Result, OpeningParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	ResultStructure1 = GetFromTempStorage(Result.ResultAddress);
	
	For Each PrintForm In ResultStructure1.PrintFormsCollection Do
		If TypeOf(PrintForm.SpreadsheetDocument) = Type("SpreadsheetDocument") Then
			PrintForm.SpreadsheetDocument.Protection = PrintForm.Protection;
		EndIf;
	EndDo;
	
	OpeningParameters.Insert("PrintObjects", ResultStructure1.PrintObjects);
	OpeningParameters.Insert("OutputParameters", ResultStructure1.OutputParameters);
	OpeningParameters.Insert("PrintParameters", ResultStructure1.PrintParameters); 
	
	PrintFormsCollection	 = ResultStructure1.PrintFormsCollection;
	OfficeDocuments		 = ResultStructure1.OfficeDocuments;
	For Each PrintForm In PrintFormsCollection Do
		OfficeDocsNewAddresses = New Map();
		If ValueIsFilled(PrintForm.OfficeDocuments) Then
			For Each OfficeDocument In PrintForm.OfficeDocuments Do
				OfficeDocsNewAddresses.Insert(PutToTempStorage(OfficeDocuments[OfficeDocument.Key], OpeningParameters.StorageUUID), OfficeDocument.Value);
			EndDo;
			PrintForm.OfficeDocuments = OfficeDocsNewAddresses;
		EndIf;
	EndDo;
	
	OpeningParameters.Insert("PrintFormsCollection", PrintFormsCollection);

	If Result.Messages.Count() <> 0 Then
		OpeningParameters.Insert("Messages", Result.Messages);
	Else
		OpeningParameters.Insert("Messages", ResultStructure1.Messages);
	EndIf;
	
	FormOwner = OpeningParameters.FormOwner;
	OpeningParameters.Delete("FormOwner");
	
	OpenForm("CommonForm.PrintDocuments",
		OpeningParameters, FormOwner, String(New UUID));
	
	UpdateCommands(FormOwner, ResultStructure1.PrintParameters);
	
EndProcedure

Function IdleParameters(FormOwner) Export
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(FormOwner);
	IdleParameters.MessageText = NStr("en = 'Preparing print forms.'");
	IdleParameters.UserNotification.Show = False;
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputMessages = False;
	Return IdleParameters;

EndFunction

// A synchronous alternative of CommonClient.CreateTempDirectory for backward compatibility.
//
Function CreateTemporaryDirectory(Val Extension = "") Export 
	
	DirectoryName = TempFilesDir() + "v8_" + String(New UUID);// ACC:495 - Intended for backward compatibility.
	If Not IsBlankString(Extension) Then 
		DirectoryName = DirectoryName + "." + Extension;
	EndIf;
	CreateDirectory(DirectoryName);
	Return DirectoryName;
	
EndFunction

Procedure AfterSelectDefaultCommand(Result, ExecutionParameters) Export
	
	If Result <> Undefined Then
		CommandParameters = New Structure("CommandDetails", ExecutionParameters.TeamDescriptions[Result.Value]);
		ExecutionParameters = ExecutionParameters.ExecutionParameters;
		
		FillPropertyValues(ExecutionParameters, CommandParameters);
		RunConnectedPrintCommandCompletion(True, ExecutionParameters);
	EndIf;
	
EndProcedure

Procedure ContinueExecutionCommandHandler(Result, ExecutionParameters) Export
	ExecutionParameters.CommandDetails = Result;
	RunConnectedPrintCommandCompletion(True, ExecutionParameters);
EndProcedure

Procedure UpdateCommands(Form, CommandDetails)
	
	If TypeOf(CommandDetails) = Type("Structure") Then
		UpdateRequired = CommonClientServer.StructureProperty(CommandDetails, "ReplaceDefaultPrintForm", False)
			Or CommonClientServer.StructureProperty(CommandDetails, "DefaultCommand", False);
			
		If UpdateRequired Then
			Form.DetachIdleHandler("Attachable_UpdateCommands");
			Form.AttachIdleHandler("Attachable_UpdateCommands", 0.2, True);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion
