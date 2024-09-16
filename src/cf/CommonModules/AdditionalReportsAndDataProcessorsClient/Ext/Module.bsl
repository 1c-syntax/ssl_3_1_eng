///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens a form with available commands.
//
// Parameters:
//   CommandParameter - Arbitrary -  passed "as is" from the command handler parameters.
//   CommandExecuteParameters - CommandExecuteParameters -  passed "as is" from the command handler parameters.
//   Kind - String - :
//       
//   SectionName - String -  name of the section of the command interface from which the command is called.
//
Procedure OpenAdditionalReportAndDataProcessorCommandsForm(CommandParameter, CommandExecuteParameters, Kind, SectionName = "") Export
	
	RelatedObjects = New ValueList;
	If TypeOf(CommandParameter) = Type("Array") Then // 
		RelatedObjects.LoadValues(CommandParameter);
	ElsIf CommandParameter <> Undefined Then
		RelatedObjects.Add(CommandParameter);
	EndIf;
	
	Parameters = New Structure("RelatedObjects, Kind, SectionName, WindowOpeningMode");
	Parameters.RelatedObjects = RelatedObjects;
	Parameters.Kind = Kind;
	Parameters.SectionName = SectionName;
	
	If TypeOf(CommandExecuteParameters.Source) = Type("ClientApplicationForm") Then // 
		Parameters.Insert("FormName", CommandExecuteParameters.Source.FormName);
	EndIf;
	
	If TypeOf(CommandExecuteParameters) = Type("CommandExecuteParameters") Then
		RefForm = CommandExecuteParameters.URL;
	Else
		RefForm = Undefined;
	EndIf;
	
	OpenForm("CommonForm.AdditionalReportsAndDataProcessors", Parameters,
		CommandExecuteParameters.Source,,, RefForm);
	
EndProcedure

// Opens an additional report form with the specified option.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors -  link to the additional report.
//   VariantKey - String -  name of the additional report option.
//
Procedure OpenAdditionalReportOption(Ref, VariantKey) Export
	
	If TypeOf(Ref) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	ReportName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(Ref);
	OpeningParameters = New Structure("VariantKey", VariantKey);
	Uniqueness = "ExternalReport." + ReportName + "/VariantKey." + VariantKey;
	OpenForm("ExternalReport." + ReportName + ".Form", OpeningParameters, Undefined, Uniqueness);
	
EndProcedure

// Returns an empty structure of command execution parameters in the background.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors -  link to the additional processing or report that is being performed.
//
// Returns:
//   Structure - :
//      * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors -  passed "as is" from
//                                                                                          the form parameters.
//      * AccompanyingText1 - String -  text of a long operation.
//      * RelatedObjects - Array -  references of objects for which the command is executed.
//          Used for assigned additional treatments.
//      * CreatedObjects - Array -  references to objects created during the command execution.
//          Used for assigned additional processing of the "creating related objects" type.
//      * OwnerForm - ClientApplicationForm -  the form of the object or list that the command was called from.
//
Function CommandExecuteParametersInBackground(Ref) Export
	
	Result = New Structure("AdditionalDataProcessorRef", Ref);
	Result.Insert("AccompanyingText1");
	Result.Insert("RelatedObjects");
	Result.Insert("CreatedObjects");
	Result.Insert("OwnerForm");
	Return Result;
	
EndFunction

// Executes the command ID In the background using the long-running operation mechanism.
// For use in external reporting and processing forms.
//
// Parameters:
//   CommandID - String -  the name of the command, as specified in the function informationexternal Processing of the object module.
//   CommandParameters - Structure - 
//       
//       :
//         * CommandID - String -  name of the command to run. Matches the command ID parameter.
//       In addition to standard parameters, it can contain custom parameters for use in the command handler.
//       When adding custom parameters, we recommend that you use a prefix in their names
//       to avoid conflicts with standard parameters, such as"Context...".
//   Handler - See TimeConsumingOperationsClient.WaitCompletion.CallbackOnCompletion
//
// Example:
//	&Naciente
//	Command Handler Procedure (Command)
//		Command Parameterscommand = Additional Reportsprocessclient.Parameterinfocollection(Parameters.Additional processing link);
//		Command parameters.Accompanying text = NSTR ("ru = 'Running the command...'");
//		Handler = New Description Of The Announcement("<Export Procedure Name>", This Object);
//		Additional reports and processing of the client.Violetcompany(Command.Name, Command Parametersand Handler);
//	End of procedure
//
Procedure ExecuteCommandInBackground(Val CommandID, Val CommandParameters, Val Handler) Export
	
	ProcedureName = "AdditionalReportsAndDataProcessorsClient.ExecuteCommandInBackground";
	CommonClientServer.CheckParameter(
		ProcedureName,
		"CommandID",
		CommandID,
		Type("String"));
	CommonClientServer.CheckParameter(
		ProcedureName,
		"CommandParameters",
		CommandParameters,
		Type("Structure"));
	CommonClientServer.CheckParameter(
		ProcedureName,
		"CommandParameters.AdditionalDataProcessorRef",
		CommonClientServer.StructureProperty(CommandParameters, "AdditionalDataProcessorRef"),
		Type("CatalogRef.AdditionalReportsAndDataProcessors"));
	CommonClientServer.CheckParameter(
		ProcedureName,
		"Handler",
		Handler,
		New TypeDescription("NotifyDescription, ClientApplicationForm"));
	
	CommandParameters.Insert("CommandID", CommandID);
	MustReceiveResult = CommonClientServer.StructureProperty(CommandParameters, "MustReceiveResult", False);
	
	Form = Undefined;
	If CommandParameters.Property("OwnerForm", Form) Then
		CommandParameters.OwnerForm = Undefined;
	EndIf;
	If TypeOf(Handler) = Type("NotifyDescription") Then
		CommonClientServer.CheckParameter(ProcedureName, "Handler.Module",
			Handler.Module,
			Type("ClientApplicationForm"));
		Form = ?(Form <> Undefined, Form, Handler.Module);
	Else
		Form = Handler;
		Handler = Undefined;
		MustReceiveResult = True; // 
	EndIf;
	
	Job = AdditionalReportsAndDataProcessorsServerCall.StartTimeConsumingOperation(Form.UUID, CommandParameters);
	
	AccompanyingText1 = CommonClientServer.StructureProperty(CommandParameters, "AccompanyingText1", "");
	Title = CommonClientServer.StructureProperty(CommandParameters, "Title");
	If ValueIsFilled(Title) Then
		AccompanyingText1 = TrimAll(Title + Chars.LF + AccompanyingText1);
	EndIf;
	If Not ValueIsFilled(AccompanyingText1) Then
		AccompanyingText1 = NStr("en = 'Command running.';");
	EndIf;
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(Form);
	WaitSettings.MessageText       = AccompanyingText1;
	WaitSettings.OutputIdleWindow = True;
	WaitSettings.MustReceiveResult    = MustReceiveResult; // 
	WaitSettings.OutputMessages    = True;
	WaitSettings.OutputProgressBar = True;
	
	TimeConsumingOperationsClient.WaitCompletion(Job, Handler, WaitSettings);
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
// 
// 
//
// 
//
// Returns:
//   String - See ExecuteCommandInBackground.
//
Function TimeConsumingOperationFormName() Export
	
	Return "CommonForm.TimeConsumingOperation";
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Opens the form for selecting additional reports.
// Place of use:
//   Guide.Mailing lists of reports.Form.Form of the element.Add an additional report.
//
// Parameters:
//   FormItem - Arbitrary -  the form element that you are selecting elements for.
//
Procedure ReportDistributionPickAddlReport(FormItem) Export
	
	AdditionalReport = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.AdditionalReport");
	Report               = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.Report");
	
	FilterByType = New ValueList;
	FilterByType.Add(AdditionalReport, AdditionalReport);
	FilterByType.Add(Report, Report);
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("WindowOpeningMode",  FormWindowOpeningMode.Independent);
	ChoiceFormParameters.Insert("ChoiceMode",        True);
	ChoiceFormParameters.Insert("CloseOnChoice", False);
	ChoiceFormParameters.Insert("MultipleChoice", True);
	ChoiceFormParameters.Insert("Filter",              New Structure("Kind", FilterByType));
	
	OpenForm("Catalog.AdditionalReportsAndDataProcessors.ChoiceForm", ChoiceFormParameters, FormItem);
	
EndProcedure

// Handler for an external print command.
//
// Parameters:
//  CommandToExecute - Structure        -  the structure from the command table row, see
//                                        Additional processing reports.The receipt of the print command.
//  Form            - ClientApplicationForm -  the form in which the print command is executed.
//
Procedure ExecuteAssignablePrintCommand(CommandToExecute, Form) Export
	
	// 
	For Each KeyAndValue In CommandToExecute.AdditionalParameters Do
		CommandToExecute.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	// 
	CommandToExecute.Insert("IsReport", False);
	CommandToExecute.Insert("Kind", PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.PrintForm"));
	
	// 
	StartupOption = CommandToExecute.StartupOption;
	If StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm") Then
		OpenDataProcessorForm(CommandToExecute, Form, CommandToExecute.PrintObjects);
	ElsIf StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall") Then
		ExecuteDataProcessorClientMethod(CommandToExecute, Form, CommandToExecute.PrintObjects);
	Else
		ExecutePrintFormOpening(CommandToExecute, Form, CommandToExecute.PrintObjects);
	EndIf;
	
EndProcedure

// Opens a list of additional report and processing commands.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef -  links to the selected objects that the command is running on.
//   ExecutionParameters - Structure:
//       * CommandDetails - Structure:
//          ** Id - String -  command ID.
//          ** Presentation - String -  representation of the team in the form.
//          ** Name - String -  name of the team in the form.
//          ** AdditionalParameters - See AdditionalReportsAndDataProcessors.AdditionalCommandParameters
//       * Form - ClientApplicationForm -  the form from which the command was called.
//       * Source - FormDataStructure
//                  - FormTable - 
//
Procedure OpenCommandList(Val ReferencesArrray, Val ExecutionParameters) Export
	Context = New Structure;
	Context.Insert("Source", ExecutionParameters.Form);
	Kind = ExecutionParameters.CommandDetails.AdditionalParameters.Kind;
	OpenAdditionalReportAndDataProcessorCommandsForm(ReferencesArrray, Context, Kind);
EndProcedure

// See AdditionalReportsAndDataProcessors.HandlerFillingCommands
Procedure HandlerFillingCommands(Val ReferencesArrray, Val ExecutionParameters) Export
	Form              = ExecutionParameters.Form;
	Object             = ExecutionParameters.Source;
	CommandToExecute = ExecutionParameters.CommandDetails.AdditionalParameters; // See AdditionalReportsAndDataProcessors.AdditionalFillingCommandParameters
	

	ServerCallParameters = New Structure;
	ServerCallParameters.Insert("CommandID",          CommandToExecute.Id);
	ServerCallParameters.Insert("AdditionalDataProcessorRef", CommandToExecute.Ref);
	ServerCallParameters.Insert("RelatedObjects",             New Array);
	ServerCallParameters.Insert("FormName",                      Form.FormName);
	ServerCallParameters.RelatedObjects.Add(Object.Ref);
	
	ShowNotificationOnCommandExecution(CommandToExecute);
	
	// 
	// 
	If CommandToExecute.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm") Then
		
		ExternalObjectName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(CommandToExecute.Ref);
		If CommandToExecute.IsReport Then
			OpenForm("ExternalReport."+ ExternalObjectName +".Form", ServerCallParameters, Form);
		Else
			OpenForm("ExternalDataProcessor."+ ExternalObjectName +".Form", ServerCallParameters, Form);
		EndIf;
		
	ElsIf CommandToExecute.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall") Then
		
		ExternalObjectName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(CommandToExecute.Ref);
		If CommandToExecute.IsReport Then
			ExternalObjectForm = GetForm("ExternalReport."+ ExternalObjectName +".Form", ServerCallParameters, Form);
		Else
			ExternalObjectForm = GetForm("ExternalDataProcessor."+ ExternalObjectName +".Form", ServerCallParameters, Form);
		EndIf;
		ExternalObjectForm.ExecuteCommand(ServerCallParameters.CommandID, ServerCallParameters.RelatedObjects);
		
	ElsIf CommandToExecute.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ServerMethodCall")
		Or CommandToExecute.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.SafeModeScenario") Then
		
		ServerCallParameters.Insert("ExecutionResult", New Structure);
		AdditionalReportsAndDataProcessorsServerCall.ExecuteCommand(ServerCallParameters, Undefined);
		
		ApplicationParameters.Insert(ApplicationParameterNameFormCommandExecutionOwner(), Form);
		AttachIdleHandler("OnCompleteFillCommandExecution", 0.1, True);
	EndIf;
	
EndProcedure

Procedure OpenAdditionalReportsAndDataProcessorsList() Export
	
	OpenForm("Catalog.AdditionalReportsAndDataProcessors.ListForm");
	
EndProcedure

#EndRegion

#Region Private

// Displays an alert before running the command.
Procedure ShowNotificationOnCommandExecution(CommandToExecute)
	If CommandToExecute.ShouldShowUserNotification Then
		ShowUserNotification(NStr("en = 'Command running…';"), , CommandToExecute.Presentation);
	EndIf;
EndProcedure

// Opens the processing form.
Procedure OpenDataProcessorForm(CommandToExecute, Form, RelatedObjects) Export
	ProcessingParameters = New Structure("CommandID, AdditionalDataProcessorRef, FormName, SessionKey1");
	ProcessingParameters.CommandID          = CommandToExecute.Id;
	ProcessingParameters.AdditionalDataProcessorRef = CommandToExecute.Ref;
	ProcessingParameters.FormName                      = ?(Form = Undefined, Undefined, Form.FormName);
	ProcessingParameters.SessionKey1 = CommandToExecute.Ref.UUID();
	
	If TypeOf(RelatedObjects) = Type("Array") Then
		ProcessingParameters.Insert("RelatedObjects", RelatedObjects);
	EndIf;
	
	#If ThickClientOrdinaryApplication Then
		ExternalDataProcessor = AdditionalReportsAndDataProcessorsServerCall.ExternalDataProcessorObject(CommandToExecute.Ref);
		DataProcessorForm = ExternalDataProcessor.GetForm(, Form);
		If DataProcessorForm = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = '%1 report or data processor is missing the main form,
				|or the main form does not support standard applications.
				|Command %2 failed.';"),
				String(CommandToExecute.Ref),
				CommandToExecute.Presentation);
		EndIf;
		DataProcessorForm.Open();
		DataProcessorForm = Undefined;
	#Else
		DataProcessorName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(CommandToExecute.Ref);
		If CommandToExecute.IsReport Then
			OpenForm("ExternalReport." + DataProcessorName + ".Form", ProcessingParameters, Form);
		Else
			OpenForm("ExternalDataProcessor." + DataProcessorName + ".Form", ProcessingParameters, Form);
		EndIf;
	#EndIf
EndProcedure

// Executes the client processing method.
Procedure ExecuteDataProcessorClientMethod(CommandToExecute, Form, RelatedObjects) Export
	
	ShowNotificationOnCommandExecution(CommandToExecute);
	
	ProcessingParameters = New Structure("CommandID, AdditionalDataProcessorRef, FormName");
	ProcessingParameters.CommandID          = CommandToExecute.Id;
	ProcessingParameters.AdditionalDataProcessorRef = CommandToExecute.Ref;
	ProcessingParameters.FormName                      = ?(Form = Undefined, Undefined, Form.FormName);
	
	If TypeOf(RelatedObjects) = Type("Array") Then
		ProcessingParameters.Insert("RelatedObjects", RelatedObjects);
	EndIf;
	
	#If ThickClientOrdinaryApplication Then
		ExternalDataProcessor = AdditionalReportsAndDataProcessorsServerCall.ExternalDataProcessorObject(CommandToExecute.Ref);
		DataProcessorForm = ExternalDataProcessor.GetForm(, Form);
		If DataProcessorForm = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = '%1 report or data processor is missing the main form,
				|or the main form does not support standard applications.
				|Command %2 failed.';"),
				String(CommandToExecute.Ref),
				CommandToExecute.Presentation);
		EndIf;
	#Else
		DataProcessorName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(CommandToExecute.Ref);
		If CommandToExecute.IsReport Then
			DataProcessorForm = GetForm("ExternalReport."+ DataProcessorName +".Form", ProcessingParameters, Form);
		Else
			DataProcessorForm = GetForm("ExternalDataProcessor."+ DataProcessorName +".Form", ProcessingParameters, Form);
		EndIf;
	#EndIf
	
	If CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor")
		Or CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.AdditionalReport") Then
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.Id);
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.RelatedObjectsCreation") Then
		
		CreatedObjects = New Array;
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.Id, RelatedObjects, CreatedObjects);
		
		CreatedObjectTypes = New Array;
		
		For Each CreatedObject In CreatedObjects Do
			Type = TypeOf(CreatedObject);
			If CreatedObjectTypes.Find(Type) = Undefined Then
				CreatedObjectTypes.Add(Type);
			EndIf;
		EndDo;
		
		For Each Type In CreatedObjectTypes Do
			NotifyChanged(Type);
		EndDo;
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.PrintForm") Then
		
		DataProcessorForm.Print(CommandToExecute.Id, RelatedObjects);
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.ObjectFilling") Then
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.Id, RelatedObjects);
		
		ModifiedObjectTypes = New Array;
		
		For Each ModifiedObject In RelatedObjects Do
			Type = TypeOf(ModifiedObject);
			If ModifiedObjectTypes.Find(Type) = Undefined Then
				ModifiedObjectTypes.Add(Type);
			EndIf;
		EndDo;
		
		For Each Type In ModifiedObjectTypes Do
			NotifyChanged(Type);
		EndDo;
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.Report") Then
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.Id, RelatedObjects);
		
	EndIf;
	
	DataProcessorForm = Undefined;
	
EndProcedure

// Generates a tabular document in the form of the "Print" subsystem.
Procedure ExecutePrintFormOpening(CommandToExecute, Form, RelatedObjects) Export
	
	StandardProcessing = True;
	// 
	AdditionalReportsAndDataProcessorsClientOverridable.BeforeExecuteExternalPrintFormPrintCommand(
		RelatedObjects, StandardProcessing);
	// 
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManagerInternalClient = CommonClient.CommonModule("PrintManagementInternalClient");
		ModulePrintManagerInternalClient.ExecutePrintFormOpening(
			CommandToExecute.Ref,
			CommandToExecute.Id,
			RelatedObjects,
			Form,
			StandardProcessing);
	EndIf;
	
EndProcedure

// Displays the extension installation dialog, then uploads additional report or processing data.
//
// Parameters:
//   ExportingParameters - Structure:
//   * Ref - AnyRef
//
Procedure ExportToFile(ExportingParameters) Export
	Var Address;
	
	ExportingParameters.Property("DataProcessorDataAddress", Address);
	If Not ValueIsFilled(Address) Then
		Address = AdditionalReportsAndDataProcessorsServerCall.PutInStorage(ExportingParameters.Ref, Undefined);
	EndIf;
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.SuggestionText = NStr("en = 'It is recommended that you install 1C:Enterprise Extension before you save the external report or data processor to a file.';");
	SavingParameters.Dialog.Filter = AdditionalReportsAndDataProcessorsClientServer.SelectingAndSavingDialogFilter();
	SavingParameters.Dialog.Title = NStr("en = 'Select file';");
	SavingParameters.Dialog.FilterIndex = ?(ExportingParameters.IsReport, 1, 2);
	SavingParameters.Dialog.FullFileName = ExportingParameters.FileName;
	
	FileSystemClient.SaveFile(Undefined, Address, ExportingParameters.FileName, SavingParameters);
	
EndProcedure

// 
Procedure UpdateDataInForm() Export
	
	ParameterName = ApplicationParameterNameFormCommandExecutionOwner();
	If ApplicationParameters[ParameterName] = Undefined Then
		Return;
	EndIf;
	
	Form = ApplicationParameters[ParameterName];
	Form.Read();
	
	ApplicationParameters[ParameterName] = Undefined;
	
EndProcedure

Function ApplicationParameterNameFormCommandExecutionOwner()
	
	Return "StandardSubsystems.AdditionalReportsAndDataProcessors.FormCommandExecutionOwner";
	
EndFunction

#EndRegion
