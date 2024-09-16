///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Generates and displays printed forms.
// 
// Parameters:
//  PrintManagerName - String -  the print Manager for printing objects;
//  TemplatesNames       - String -  print form IDs;
//  ObjectsArray     - AnyRef
//                     - Array of AnyRef - 
//  FormOwner      - ClientApplicationForm -  the form to print from;
//  PrintParameters    - Structure -  custom parameters to pass to the print Manager.
//
// Example:
//   Print managementclient.Run The Print Command ("Processing.Printable Form", "Write-Offs Of Goods", Dokumentynapechat, This Object);
//
Procedure ExecutePrintCommand(PrintManagerName, TemplatesNames, ObjectsArray, FormOwner, PrintParameters = Undefined) Export
	
	If Not CheckPassedObjectsCount(ObjectsArray) Then
		Return;
	EndIf;
	
	ParameterName = "StandardSubsystems.Print.ExecutePrintCommand";
	PassedParametersList = ApplicationParameters[ParameterName];
	
	If PassedParametersList = Undefined Then
		PassedParametersList = New Array;
		ApplicationParameters[ParameterName] = PassedParametersList;
	EndIf;
	
	OpeningParameters = PrintManagementInternalClient.ParametersForOpeningPrintForm();
	OpeningParameters.PrintManagerName = PrintManagerName;
	OpeningParameters.TemplatesNames = TemplatesNames;
	OpeningParameters.CommandParameter = ObjectsArray;
	OpeningParameters.PrintParameters = PrintParameters;
	OpeningParameters.FormOwner = FormOwner;
	
	PassedParametersList.Add(OpeningParameters);
	
	AttachIdleHandler("ResumePrintCommandWithPassedParameters", 0.1, True);
	
EndProcedure

// Generates and outputs printed forms to the printer.
//
// Parameters:
//  PrintManagerName - String -  the print Manager for printing objects;
//  TemplatesNames       - String -  print form IDs;
//  ObjectsArray     - AnyRef
//                     - Array of AnyRef - 
//  PrintParameters    - Structure -  custom parameters to pass to the print Manager.
//
// Example:
//   Print managementclient.Vypolnyayutsya("Processing.Printable Form", "Write-Offs Of Goods", Documentsnaprint);
//
Procedure ExecutePrintToPrinterCommand(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters = Undefined) Export

	// 
	If Not CheckPassedObjectsCount(ObjectsArray) Then
		Return;
	EndIf;
	
	// 
#If ThickClientOrdinaryApplication Then
	PrintForms = PrintManagementServerCall.GeneratePrintFormsForQuickPrintOrdinaryApplication(
			PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters);
	If Not PrintForms.Cancel Then
		PrintObjects = New ValueList;
		For Each PrintObject In PrintForms.PrintObjects Do
			PrintObjects.Add(PrintObject.Value, PrintObject.Key);
		EndDo;
		PrintForms.PrintObjects = PrintObjects;
	EndIf;
#Else
	PrintForms = PrintManagementServerCall.GeneratePrintFormsForQuickPrint(
			PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters);
#EndIf
	
	If PrintForms.Cancel Then
		CommonClient.MessageToUser(NStr("en = 'Insufficient rights to print out the form. Contact your administrator.';"));
		Return;
	EndIf;
	
	// 
	PrintSpreadsheetDocuments(PrintForms.SpreadsheetDocuments, PrintForms.PrintObjects);
	
	// Standard subsystems.Accounting for originalsservicedocuments
	If CommonClient.SubsystemExists("StandardSubsystems.SourceDocumentsOriginalsRecording") Then
		PrintList = New ValueList;
		For Each Template In PrintForms.SpreadsheetDocuments Do 
			PrintList.Add(TemplatesNames, Template.Presentation);
		EndDo;
	  	ModuleSourceDocumentsOriginalsAccountingClient = CommonClient.CommonModule("SourceDocumentsOriginalsRecordingClient");
		ModuleSourceDocumentsOriginalsAccountingClient.WriteOriginalsStatesAfterPrint(PrintForms.PrintObjects, PrintList);
	EndIf;
	// End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

// Display table the documents to the printer.
//
// Parameters:
//  SpreadsheetDocuments           - ValueList -  printed form.
//  PrintObjects                - ValueList -  objects match the names of areas in a table document.
//  PrintInSets          - Boolean
//                               - Undefined - 
//  SetCopies    - Number -  the number of copies of each set of documents.
//
Procedure PrintSpreadsheetDocuments(SpreadsheetDocuments, PrintObjects, Val PrintInSets = Undefined, 
	Val SetCopies = 1) Export
	
	PrintInSets = SpreadsheetDocuments.Count() > 1;
	RepresentableDocumentBatch = PrintManagementServerCall.DocumentsPackage(SpreadsheetDocuments,
		PrintObjects, PrintInSets, SetCopies);
	RepresentableDocumentBatch.Print(PrintDialogUseMode.DontUse);
	
EndProcedure

// Performs interactive drawing of documents before printing.
// If there are unverified documents, offers to carry out the survey. Asks
// the user to continue if any of the documents were not completed and there are completed documents.
//
// Parameters:
//  CompletionProcedureDetails - NotifyDescription - 
//                                                     
//                                :
//                                  DocumentsList - Array -  completed documents;
//                                  Additional parameters - the value that was specified when creating
//                                                            the alert object.
//  List of documents-an Array of links to documents that need to be held.
//  Form                       - ClientApplicationForm  -  the form from which the command was called. This parameter
//                                                    is required when the procedure
//                                                    is called from an object form in order to re-read the form.
//
Procedure CheckDocumentsPosting(CompletionProcedureDetails, DocumentsList, Form = Undefined) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CompletionProcedureDetails", CompletionProcedureDetails);
	AdditionalParameters.Insert("DocumentsList", DocumentsList);
	AdditionalParameters.Insert("Form", Form);
	
	UnpostedDocuments = CommonServerCall.CheckDocumentsPosting(DocumentsList);
	HasUnpostedDocuments = UnpostedDocuments.Count() > 0;
	If HasUnpostedDocuments Then
		AdditionalParameters.Insert("UnpostedDocuments", UnpostedDocuments);
		PrintManagementInternalClient.CheckDocumentsPostedPostingDialog(AdditionalParameters);
	Else
		ExecuteNotifyProcessing(CompletionProcedureDetails, DocumentsList);
	EndIf;
	
EndProcedure

// Opens the print Documents form for a collection of tabular documents.
//
// Parameters:
//  PrintFormsCollection - Array of See NewPrintFormsCollection
//  PrintObjects - ValueList - See PrintManagementOverridable.OnPrint
//  AdditionalParameters - See PrintParameters
//                          -  Pharmaciestestosterone - form from which you are printing;
//
Procedure PrintDocuments(PrintFormsCollection, Val PrintObjects = Undefined,
	AdditionalParameters = Undefined) Export
	
	PrintParameters = PrintParameters();
	
	FormOwner = Undefined;
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FillPropertyValues(PrintParameters, AdditionalParameters);
		FormOwner = PrintParameters.FormOwner;
		PrintParameters.Delete("FormOwner");
	ElsIf TypeOf(AdditionalParameters) = Type("ClientApplicationForm") Then 
		FormOwner = AdditionalParameters; // 
	EndIf;
	
	If PrintObjects = Undefined Then
		PrintObjects = New ValueList;
	EndIf;
	
	UniqueKey = String(New UUID);
	
	OpeningParameters = New Structure("PrintManagerName,TemplatesNames,CommandParameter,PrintParameters");
	OpeningParameters.CommandParameter = New Array;
	OpeningParameters.Insert("PrintFormsCollection", PrintFormsCollection);
	OpeningParameters.Insert("PrintObjects", PrintObjects);
	OpeningParameters.Insert("PrintParameters", PrintParameters);
	OpeningParameters.Insert("TemplatesNames", New Array);
	
	For Each PrintFormDetails In PrintFormsCollection Do
		OpeningParameters.TemplatesNames.Add(PrintFormDetails.TemplateName);
	EndDo;
	
	OpenForm("CommonForm.PrintDocuments", OpeningParameters, FormOwner, UniqueKey);
	
EndProcedure

// Parameter constructor Additional parameters of the print Documents procedure.
//
//  Returns:
//   Structure - :
//    * FormOwner - ClientApplicationForm -  the form to print from.
//    * Title     - String -  title of the print Documents form.
//
Function PrintParameters() Export
	
	Result = New Structure;
	Result.Insert("FormOwner");
	Result.Insert("FormCaption");
	
	Return Result;
	
EndFunction

// 
// See PrintDocuments
// See PrintFormDetails
//
// Parameters:
//  IDs - String -  IDs of printed forms.
//
// Returns:
//  Array - 
//           
//           
//
Function NewPrintFormsCollection(Val IDs) Export
	
	If TypeOf(IDs) = Type("String") Then
		IDs = StrSplit(IDs, ",");
	EndIf;
	
	Fields = PrintManagementClientServer.PrintFormsCollectionFieldsNames();
	AddedPrintForms = New Map;
	Result = New Array;
	
	For Each Id In IDs Do
		PrintForm = AddedPrintForms[Id];
		If PrintForm = Undefined Then
			PrintForm = New Structure(StrConcat(Fields, ","));
			PrintForm.TemplateName = Id;
			PrintForm.UpperCaseName = Upper(Id);
			PrintForm.Copies2 = 1;
			AddedPrintForms.Insert(Id, PrintForm);
			Result.Add(PrintForm);
		Else
			PrintForm.Copies2 = PrintForm.Copies2 + 1;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns a description of the printed form found in the collection.
// If the description does not exist, returns Undefined.
//
// Parameters:
//  PrintFormsCollection - Array of See NewPrintFormsCollection.
//  Id         - String -  ID of the printed form.
//
// Returns:
//  Structure - :
//   * TemplateSynonym - String -  presentation of the printed form;
//   * SpreadsheetDocument - SpreadsheetDocument -  printed form;
//   * Copies2 - Number -  number of copies to print;
//   * FullTemplatePath - String -  used to quickly switch to editing the layout of a printed form;
//   * PrintFormFileName - String -  file name;
//                           - Map of KeyAndValue - :
//                              ** Key - AnyRef -  link to the print object;
//                              ** Value - String -  file name;
//   * OfficeDocuments - Map of KeyAndValue - :
//                         ** Key - String -  address in the temporary storage of binary data of the printed form;
//                         ** Value - String -  name of the print form file.
//
Function PrintFormDetails(PrintFormsCollection, Id) Export
	For Each PrintFormDetails In PrintFormsCollection Do
		If PrintFormDetails.UpperCaseName = Upper(Id) Then
			Return PrintFormDetails;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction

// Opens the form for selecting the layout opening mode.
//
Procedure SetActionOnChoosePrintFormTemplate() Export
	
	OpenForm("InformationRegister.UserPrintTemplates.Form.SelectTemplateOpeningMode");
	
EndProcedure

// Opens a form with instructions on how to make a facsimile signature and print.
Procedure ShowInstructionOnHowToCreateFacsimileSignatureAndSeal() Export
	
	ScanAvailable = False;
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsClient = CommonClient.CommonModule("FilesOperationsClient");
		ScanAvailable = ModuleFilesOperationsClient.ScanAvailable();
	EndIf;
	GenerationParameters = New Structure ("ScanAvailable", ScanAvailable);
	ExecutePrintCommand("InformationRegister.CommonSuppliedPrintTemplates", "GuideToCreateFacsimileAndStamp", 
		PredefinedValue("Catalog.MetadataObjectIDs.EmptyRef"), Undefined, GenerationParameters);
	
EndProcedure

// It is intended for use in procedures of the print management module Clientdefinable.Printdocuments<...>.
// Returns a collection of parameters for the current print form in the "Print documents" form (General Form.Print documents).
// 
// Parameters:
//  Form - ClientApplicationForm -  print Document form passed in the General module procedure Form parameter
//                             Print managementclientdefinable.
//
// Returns:
//  FormDataCollectionItem - 
//
Function CurrentPrintFormSetup(Form) Export
	Result = Form.Items.PrintFormsSettings.CurrentData;
	If Result = Undefined And Form.PrintFormsSettings.Count() > 0 Then
		Result = Form.PrintFormsSettings[0];
	EndIf;
	Return Result;
EndFunction

// 
// 
// Returns:
//  Structure:
//   * Form - ClientApplicationForm -  the form in which the print is performed.
//   * PrintObjects - Array of AnyRef -  objects for which you need to create printed forms.
//   * Id - String - 
//                              
//                              
//
//                              
//                              :
//                              
//
//                              
//                              
//                              
//                              
//                              
//                              
//
//                              
//                              
//                              
//
//                              
//                              
//                              
//
//                   - Array - 
//
//   * PrintManager - String           -  (optional) name of the object whose Manager module contains
//                                        the Print procedure that generates table documents for this command.
//                                        The default value is the name of the object Manager module.
//                                         For Example, " Document.Invoice to the buyer".
//
//   * Handler    - String            - 
//                                        
//                                        
//                                        
//                                        
//                                        
//                                        
//                                        
//                                          
//                                        :
//                                          
//                                          //
//                                          
//                                          
//                                          
//                                          
//                                          
//                                          
//                                          
//                                          
//                                          //
//                                          
//                                          
//                                          	
//                                          
//                                        
//                                        
//                                        
//
//   * SkipPreview - Boolean           - 
//                                        
//                                        
//
//   * SaveFormat - SpreadsheetDocumentFileType -  (optional) It is used to quickly save the printed
//                                        form (without additional actions) to various formats other than mxl.
//                                        If this parameter is omitted, the normal mxl is generated.
//                                        For example, the file type of the.PDF document.
//
//                                        When you select the print command, the generated pdf
//                                        document opens immediately.
//
//   * FormCaption  - String          -  (optional) An arbitrary string that overrides the standard title
//                                         of the "Print Documents"form.
//                                         For example, "Custom Kit".
//
//   * OverrideCopiesUserSetting - Boolean -  (optional) Indicates whether to disable the
//                                        mechanism for saving/restoring
//                                        the number of copies selected by the user for printing in the print Documents form. If this parameter is omitted, the
//                                        mechanism for saving / restoring settings will work when the form is opened.
//                                        Print documents.
//
//   * AddExternalPrintFormsToSet - Boolean -  (optional) Indicates whether the set
//                                        of documents must be supplemented with all external printing forms connected to the object
//                                        (additional report Processing subsystem). If this parameter is omitted, external
//                                        printing plates are not added to the package.
//   * FixedSet - Boolean    -  (optional) Indicates whether the user should be blocked from changing
//                                        the set of documents. If this parameter is omitted, the user can
//                                        exclude individual printed forms from the set in the print Document form, as
//                                        well as change their number.
//
//   * AdditionalParameters - Structure -  (optional) custom parameters to pass to the print Manager.
//
//
Function DescriptionOfPrintParameters() Export
	
	Result = New Structure;
	Result.Insert("Form");
	Result.Insert("PrintObjects");
	Result.Insert("Id");
	Result.Insert("PrintManager");
	Result.Insert("Handler");
	Result.Insert("SkipPreview");
	Result.Insert("SaveFormat");
	Result.Insert("FormCaption");
	Result.Insert("OverrideCopiesUserSetting");
	Result.Insert("AddExternalPrintFormsToSet");
	Result.Insert("FixedSet");
	Result.Insert("AdditionalParameters");
	
	Return Result;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// 

//	
//	
//
////////////////////////////////////////////////////////////////////////////////
//	
//	
//	
//	
//						
//						
//	
//	
//							
////////////////////////////////////////////////////////////////////////////////
//	
//	
//	
//							
//							
//							
//							
//

////////////////////////////////////////////////////////////////////////////////
// 

// Deprecated.
//
// 
// 
// 
// 
//
// Parameters:
//  DocumentType            - String -  type of printed form " DOC " or " ODT";
//  TemplatePagesSettings - Map -  parameters from the structure returned by the function Initializedmaket
//                                           (the parameter is deprecated, you should skip it and use the Layout parameter);
//  Template                   - Structure -  the result of the function Initializedataset.
//
// Returns:
//  Structure - 
// 
Function InitializePrintForm(Val DocumentType, Val TemplatePagesSettings = Undefined, Template = Undefined) Export
	
	If Upper(DocumentType) = "DOC" Then
		Parameter = ?(Template = Undefined, TemplatePagesSettings, Template); // 
		PrintForm = PrintManagementMSWordClient.InitializeMSWordPrintForm(Parameter);
		PrintForm.Insert("Type", "DOC");
		PrintForm.Insert("LastOutputArea", Undefined);
		Return PrintForm;
	ElsIf Upper(DocumentType) = "ODT" Then
		PrintForm = PrintManagementOOWriterClient.InitializeOOWriterPrintForm(Template);
		PrintForm.Insert("Type", "ODT");
		PrintForm.Insert("LastOutputArea", Undefined);
		Return PrintForm;
	EndIf;
	
EndFunction

// Deprecated.
//
// 
// 
// 
// 
//
// Parameters:
//  BinaryTemplateData - BinaryData -  binary layout data;
//  TemplateType            - String -  type of printed form layout " DOC " or " ODT";
//  TemplateName            - String -  the name that will be used when creating a temporary file of the layout.
//
// Returns:
//  Structure - 
//
Function InitializeOfficeDocumentTemplate(Val BinaryTemplateData, Val TemplateType, Val TemplateName = "") Export
	
	Template = Undefined;
	TempFileName = "";
	
	#If WebClient Then
		If IsBlankString(TemplateName) Then
			TempFileName = String(New UUID) + "." + Lower(TemplateType);
		Else
			TempFileName = TemplateName + "." + Lower(TemplateType);
		EndIf;
	#EndIf
	
	If Upper(TemplateType) = "DOC" Then
		Template = PrintManagementMSWordClient.GetMSWordTemplate(BinaryTemplateData, TempFileName);
		If Template <> Undefined Then
			Template.Insert("Type", "DOC");
		EndIf;
	ElsIf Upper(TemplateType) = "ODT" Then
		Template = PrintManagementOOWriterClient.GetOOWriterTemplate(BinaryTemplateData, TempFileName);
		If Template <> Undefined Then
			Template.Insert("Type", "ODT");
			Template.Insert("TemplatePagesSettings", Undefined);
		EndIf;
	EndIf;
	
	Return Template;
	
EndFunction

// Deprecated.
//
// 
// 
//
// Parameters:
//  PrintForm     - Structure -  result of the functions initializedprinted Form and Initializedmaketofisnogodocument;
//  CloseApplication - Boolean    -  True if you want to close the app.
//                                  The connection to the layout must be closed when the application is closed.
//                                  The printable form does not need to be closed.
//
Procedure ClearRefs(PrintForm, Val CloseApplication = True) Export
	
	If PrintForm <> Undefined Then
		If PrintForm.Type = "DOC" Then
			PrintManagementMSWordClient.CloseConnection(PrintForm, CloseApplication);
		Else
			PrintManagementOOWriterClient.CloseConnection(PrintForm, CloseApplication);
		EndIf;
		PrintForm = Undefined;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Deprecated.
//
// 
//
// Parameters:
//  PrintForm - Structure -  the result of the function initialize printable Form.
//
Procedure ShowDocument(Val PrintForm) Export
	
	If PrintForm.Type = "DOC" Then
		PrintManagementMSWordClient.ShowMSWordDocument(PrintForm);
	ElsIf PrintForm.Type = "ODT" Then
		PrintManagementOOWriterClient.ShowOOWriterDocument(PrintForm);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 
// 

// Deprecated.
//
// 
//
// Parameters:
//  RefToTemplate   - Structure -  layout of the printed form.
//  AreaDetails - Structure:
//   * AreaName - String -area name;
//   * AreaTypeType - String -  area type: "header", "footer", "General", "Stringable", "List".
//   
// Returns:
//  Structure - 
//
Function TemplateArea(Val RefToTemplate, Val AreaDetails) Export
	
	Area = Undefined;
	If RefToTemplate.Type = "DOC" Then
		
		If		AreaDetails.AreaType = "Header" Then
			Area = PrintManagementMSWordClient.GetHeaderArea(RefToTemplate);
		ElsIf	AreaDetails.AreaType = "Footer" Then
			Area = PrintManagementMSWordClient.GetFooterArea(RefToTemplate);
		ElsIf	AreaDetails.AreaType = "Shared3" Then
			Area = PrintManagementMSWordClient.GetMSWordTemplateArea(RefToTemplate, AreaDetails.AreaName, 1, 0);
		ElsIf	AreaDetails.AreaType = "TableRow" Then
			Area = PrintManagementMSWordClient.GetMSWordTemplateArea(RefToTemplate, AreaDetails.AreaName);
		ElsIf	AreaDetails.AreaType = "List" Then
			Area = PrintManagementMSWordClient.GetMSWordTemplateArea(RefToTemplate, AreaDetails.AreaName, 1, 0);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Area type is not specified or invalid: %1.';"), AreaDetails.AreaType);
		EndIf;
		
		If Area <> Undefined Then
			Area.Insert("AreaDetails", AreaDetails);
		EndIf;
	ElsIf RefToTemplate.Type = "ODT" Then
		
		If		AreaDetails.AreaType = "Header" Then
			Area = PrintManagementOOWriterClient.GetHeaderArea(RefToTemplate);
		ElsIf	AreaDetails.AreaType = "Footer" Then
			Area = PrintManagementOOWriterClient.GetFooterArea(RefToTemplate);
		ElsIf	AreaDetails.AreaType = "Shared3"
				Or AreaDetails.AreaType = "TableRow"
				Or AreaDetails.AreaType = "List" Then
			Area = PrintManagementOOWriterClient.GetTemplateArea(RefToTemplate, AreaDetails.AreaName);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Area type is not specified or invalid: %1.';"), AreaDetails.AreaName);
		EndIf;
		
		If Area <> Undefined Then
			Area.Insert("AreaDetails", AreaDetails);
		EndIf;
	EndIf;
	
	Return Area;
	
EndFunction

// Deprecated.
//
// 
// 
//
// Parameters:
//  PrintForm - See InitializePrintForm.
//  TemplateArea - See TemplateArea.
//  GoToNextRow1 - Boolean -  True if you want to insert a break after the area is output.
//
Procedure AttachArea(Val PrintForm, Val TemplateArea, Val GoToNextRow1 = True) Export
	
	If TemplateArea = Undefined Then
		Return;
	EndIf;
	
	Try
		AreaDetails = TemplateArea.AreaDetails;
		
		If PrintForm.Type = "DOC" Then
			
			DerivedArea = Undefined;
			
			If		AreaDetails.AreaType = "Header" Then
				PrintManagementMSWordClient.AddHeader(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Footer" Then
				PrintManagementMSWordClient.AddFooter(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Shared3" Then
				DerivedArea = PrintManagementMSWordClient.AttachArea(PrintForm, TemplateArea, GoToNextRow1);
			ElsIf	AreaDetails.AreaType = "List" Then
				DerivedArea = PrintManagementMSWordClient.AttachArea(PrintForm, TemplateArea, GoToNextRow1);
			ElsIf	AreaDetails.AreaType = "TableRow" Then
				If PrintForm.LastOutputArea <> Undefined
				   And PrintForm.LastOutputArea.AreaType = "TableRow"
				   And Not PrintForm.LastOutputArea.GoToNextRow1 Then
					DerivedArea = PrintManagementMSWordClient.AttachArea(PrintForm, TemplateArea, GoToNextRow1, True);
				Else
					DerivedArea = PrintManagementMSWordClient.AttachArea(PrintForm, TemplateArea, GoToNextRow1);
				EndIf;
			Else
				Raise AreaTypeSpecifiedIncorrectlyText();
			EndIf;
			
			AreaDetails.Insert("Area", DerivedArea);
			AreaDetails.Insert("GoToNextRow1", GoToNextRow1);
			
			// 
			PrintForm.LastOutputArea = AreaDetails;
			
		ElsIf PrintForm.Type = "ODT" Then
			If		AreaDetails.AreaType = "Header" Then
				PrintManagementOOWriterClient.AddHeader(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Footer" Then
				PrintManagementOOWriterClient.AddFooter(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Shared3"
					Or AreaDetails.AreaType = "List" Then
				PrintManagementOOWriterClient.SetMainCursorToDocumentBody(PrintForm);
				PrintManagementOOWriterClient.AttachArea(PrintForm, TemplateArea, GoToNextRow1);
			ElsIf	AreaDetails.AreaType = "TableRow" Then
				PrintManagementOOWriterClient.SetMainCursorToDocumentBody(PrintForm);
				PrintManagementOOWriterClient.AttachArea(PrintForm, TemplateArea, GoToNextRow1, True);
			Else
				Raise AreaTypeSpecifiedIncorrectlyText();
			EndIf;
			// 
			PrintForm.LastOutputArea = AreaDetails;
		EndIf;
	Except
		ErrorMessage = TrimAll(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		ErrorMessage = ?(Right(ErrorMessage, 1) = ".", ErrorMessage, ErrorMessage + ".");
		ErrorMessage = ErrorMessage + " " + StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Error occurred during output of %1 template area.';"),
			TemplateArea.AreaDetails.AreaName);
		Raise ErrorMessage;
	EndTry;
	
EndProcedure

// Deprecated.
//
// 
//
// Parameters:
//  PrintForm - Structure -  the area of the printed form, or the printed form itself.
//  Data - Structure -  fill-in data.
//
Procedure FillParameters_(Val PrintForm, Val Data) Export
	
	AreaDetails = PrintForm.LastOutputArea; // See TemplateArea.AreaDetails
	
	If PrintForm.Type = "DOC" Then
		If		AreaDetails.AreaType = "Header" Then
			PrintManagementMSWordClient.FillHeaderParameters(PrintForm, Data);
		ElsIf	AreaDetails.AreaType = "Footer" Then
			PrintManagementMSWordClient.FillFooterParameters(PrintForm, Data);
		ElsIf	AreaDetails.AreaType = "Shared3"
				Or AreaDetails.AreaType = "TableRow"
				Or AreaDetails.AreaType = "List" Then
			PrintManagementMSWordClient.FillParameters_(AreaDetails.Area, Data);
		Else
			Raise AreaTypeSpecifiedIncorrectlyText();
		EndIf;
	ElsIf PrintForm.Type = "ODT" Then
		If		PrintForm.LastOutputArea.AreaType = "Header" Then
			PrintManagementOOWriterClient.SetMainCursorToHeader(PrintForm);
		ElsIf	PrintForm.LastOutputArea.AreaType = "Footer" Then
			PrintManagementOOWriterClient.SetMainCursorToFooter(PrintForm);
		ElsIf	AreaDetails.AreaType = "Shared3"
				Or AreaDetails.AreaType = "TableRow"
				Or AreaDetails.AreaType = "List" Then
			PrintManagementOOWriterClient.SetMainCursorToDocumentBody(PrintForm);
		EndIf;
		PrintManagementOOWriterClient.FillParameters_(PrintForm, Data);
	EndIf;
	
EndProcedure

// Deprecated.
//
// 
// 
//
// Parameters:
//  PrintForm - See InitializePrintForm.
//  TemplateArea - See TemplateArea.
//  Data - Structure -  fill-in data.
//  GoToNextRow1 - Boolean -  True if you want to insert a break after the area is output.
//
Procedure AttachAreaAndFillParameters(Val PrintForm, Val TemplateArea,
	Val Data, Val GoToNextRow1 = True) Export
	
	If TemplateArea <> Undefined Then
		AttachArea(PrintForm, TemplateArea, GoToNextRow1);
		FillParameters_(PrintForm, Data)
	EndIf;
	
EndProcedure

// Deprecated.
//
// 
// 
// 
//
// Parameters:
//  PrintForm - See InitializePrintForm.
//  TemplateArea - See TemplateArea
//  Data - Array -  a collection of elements of the Structure - object data type.
//  GoToNextRow - Boolean -  True if you want to insert a break after the area is output.
//
Procedure JoinAndFillCollection(Val PrintForm,
										Val TemplateArea,
										Val Data,
										Val GoToNextRow = True) Export
	If TemplateArea = Undefined Then
		Return;
	EndIf;
	
	AreaDetails = TemplateArea.AreaDetails;
	
	If PrintForm.Type = "DOC" Then
		If		AreaDetails.AreaType = "TableRow" Then
			PrintManagementMSWordClient.JoinAndFillTableArea(PrintForm, TemplateArea, Data, GoToNextRow);
		ElsIf	AreaDetails.AreaType = "List" Then
			PrintManagementMSWordClient.JoinAndFillSet(PrintForm, TemplateArea, Data, GoToNextRow);
		Else
			Raise AreaTypeSpecifiedIncorrectlyText();
		EndIf;
	ElsIf PrintForm.Type = "ODT" Then
		If		AreaDetails.AreaType = "TableRow" Then
			PrintManagementOOWriterClient.JoinAndFillCollection(PrintForm, TemplateArea, Data, True, GoToNextRow);
		ElsIf	AreaDetails.AreaType = "List" Then
			PrintManagementOOWriterClient.JoinAndFillCollection(PrintForm, TemplateArea, Data, False, GoToNextRow);
		Else
			Raise AreaTypeSpecifiedIncorrectlyText();
		EndIf;
	EndIf;
	
EndProcedure

// Deprecated.
//
// 
//
// Parameters:
//  PrintForm - See InitializePrintForm.
//
Procedure InsertBreakAtNewLine(Val PrintForm) Export
	
	If	  PrintForm.Type = "DOC" Then
		PrintManagementMSWordClient.InsertBreakAtNewLine(PrintForm);
	ElsIf PrintForm.Type = "ODT" Then
		PrintManagementOOWriterClient.InsertBreakAtNewLine(PrintForm);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Opens the dialog form for uploading the layout file for editing in an external program.
Procedure EditTemplateInExternalApplication(NotifyDescription, TemplateParameters1, Form) Export
	OpenForm("InformationRegister.UserPrintTemplates.Form.EditTemplate2", TemplateParameters1, Form, , , , NotifyDescription);
EndProcedure

// Constructor for the save Settings parameter of the print Management function.Print the file.
// Defines the format and other settings for writing a table document to a file.
// 
// Returns:
//  Structure - :
//   * SaveFormats - Array -  collection of document type Filetable values converted to a string;
//   * PackToArchive   - Boolean -  if set to True, a single archive file with the specified file formats will be created;
//   * TransliterateFilesNames - Boolean -  if set to True, the names of the received files will be in Latin.
//   * SignatureAndSeal    - Boolean -  if set to True and the saved table document supports the placement
//                                  of signatures and seals, then the recorded files will contain signatures and seals.
//
Function SettingsForSaving() Export
	
	Return PrintManagementClientServer.SettingsForSaving();
	
EndFunction

// Parameters:
//  Form - ClientApplicationForm
//  Command - FormCommand
//
Procedure SwitchLanguage(Form, Command) Export
	
	Parameters = New Structure;
	Parameters.Insert("Form", Form);
	ArrayOfLangWords = StrSplit(Command.Name, "_", False);
	ArrayOfLangWords.Delete(0);
	TheSelectedLanguage = StrConcat(ArrayOfLangWords, "_");
	
	Parameters.Insert("TheSelectedLanguage", TheSelectedLanguage);

	FormButton = Form.Items[Command.Name]; // FormButton
	Parameters.Insert("Title", Form.Items["Language_"+TheSelectedLanguage].Title);
	Parameters.Insert("FormButton", FormButton);
	Parameters.Insert("FormButtonAllActions", Form.Items.Find(Command.Name+"AllActions"));
	
	If Form.Modified Then
		NotifyDescription = New NotifyDescription("WhenSwitchingTheLanguage", ThisObject, Parameters);
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.OK, NStr("en = 'Continue';"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		QueryText = NStr("en = 'Current template changes are not saved. Do you want to continue?';");
		ShowQueryBox(NotifyDescription, QueryText, Buttons, , DialogReturnCode.Cancel);
	Else
		WhenSwitchingTheLanguage(DialogReturnCode.OK, Parameters);
	EndIf;
	
EndProcedure

Function AreaID(Area) Export
	
	Return PrintManagementClientServer.AreaID(Area);
	
EndFunction

// Returns:
//  Structure:
//   * FilesDetails1 - Array of Structure
//   * DirectoryName - String
//   * CompletionHandler - NotifyDescription
//   * IndexOf - Number
//   * Counter - Number
//   * FileName - String
//
Function FileNamePreparationOptions(FilesDetails1, DirectoryName, CompletionHandler) Export
	
	Result = New Structure;
	
	Result.Insert("FilesDetails1", FilesDetails1);
	Result.Insert("DirectoryName", DirectoryName);
	Result.Insert("CompletionHandler", CompletionHandler);
	Result.Insert("IndexOf", Undefined);
	Result.Insert("Counter", 1);
	Result.Insert("FileName", "");
	
	Return Result;
	
EndFunction

// Parameters:
//  PreparationParameters - See FileNamePreparationOptions
//
Procedure PrepareFileNamesToSaveToADirectory(PreparationParameters) Export
	
	FilesDetails1 = PreparationParameters.FilesDetails1;
	
	If PreparationParameters.IndexOf = Undefined Then
		For Each FileDetails In FilesDetails1 Do
			FileDetails.Presentation = PreparationParameters.DirectoryName + FileDetails.Presentation;
		EndDo;
		PreparationParameters.IndexOf = 0;
	EndIf;
	
	If PreparationParameters.IndexOf > FilesDetails1.UBound() Then
		ExecuteNotifyProcessing(PreparationParameters.CompletionHandler, FilesDetails1);
		Return;
	EndIf;
	
	FileDetails = FilesDetails1[PreparationParameters.IndexOf];
	File = New File(FileDetails.Presentation);
	If PreparationParameters.Counter > 1 Then
		File = New File(File.Path +  File.BaseName + " (" + PreparationParameters.Counter + ")" + File.Extension);
	EndIf;
	
	PreparationParameters.FileName = File.Name;
	NotifyDescription = New NotifyDescription("WhenCheckingTheExistenceOfAFile", ThisObject, PreparationParameters);
	File.BeginCheckingExistence(NotifyDescription);
	
EndProcedure

#EndRegion

#Region Private

// Before executing the print command, check whether at least one object was passed, since an
// empty array can be passed for commands with multiple use modes.
//
Function CheckPassedObjectsCount(CommandParameter)
	
	If TypeOf(CommandParameter) = Type("Array") And CommandParameter.Count() = 0 Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

Function AreaTypeSpecifiedIncorrectlyText()
	Return NStr("en = 'Area type is not specified or invalid.';");
EndFunction

Procedure WhenSwitchingTheLanguage(Response, Parameters) Export
	
	If Response <> DialogReturnCode.OK Then
		Return
	EndIf;
	
	Form = Parameters.Form; // ClientApplicationForm - 
	Items = Form.Items;
	TheSelectedLanguage = Parameters.TheSelectedLanguage;
	Title = Parameters.Title;
	ProcessMoreActionsSubmenuItems = Parameters.FormButtonAllActions <> Undefined;
	
	Items.Language.Title = Title;
	FormButton = Parameters.FormButton;
	FormButtonAllActions = Parameters.FormButtonAllActions;
	
	IsEditorForm = StrStartsWith(Form.FormName, "CommonForm.Edit");
	
	If IsEditorForm Then
		IsTemplateCreated = Form.TemplateSavedLangs.FindByValue(Form.CurrentLanguage)<>Undefined;
	EndIf;
	
	LangSwitchFrom = Form.CurrentLanguage;
	
	Form.CurrentLanguage = TheSelectedLanguage;
	MenuLang = Items.Language;
	
	For Each LangButton In MenuLang.ChildItems Do
		If TypeOf(LangButton) = Type("FormButton") Then
			LangButton.Check = False;
			If FormButton.CommandName = "Add"+LangButton.CommandName Then
				LangButton.Visible = True;
				LangButton.Check = True;
			EndIf;
		EndIf;
	EndDo;
	
	If FormButton.Parent = MenuLang Then
		FormButton.Check = True;
	Else
		FormButton.Visible = False;
	EndIf;
	
	If ProcessMoreActionsSubmenuItems Then
		Items.LanguageAllActions.Title = Title;
		MenuLanguageAllActions = Items.LanguageAllActions;
	
		For Each LangButton In MenuLanguageAllActions.ChildItems Do
			If TypeOf(LangButton) = Type("FormButton") Then
				LangButton.Check = False;
				If FormButton.CommandName = "Add"+LangButton.CommandName Then
					LangButton.Visible = True;
					LangButton.Check = True;
				EndIf;
			EndIf;
		EndDo;
		
		If FormButtonAllActions.Parent = MenuLanguageAllActions Then
			FormButtonAllActions.Check = True;
		Else
			FormButtonAllActions.Visible = False;
		EndIf;

	EndIf;

	If IsEditorForm Then
				
		If Not IsTemplateCreated Then
			
			LangsToAdd = Items.LangsToAdd;
			For Each LangButton In LangsToAdd.ChildItems Do
				If StrEndsWith(LangButton.Name, LangSwitchFrom) Then
					LangButton.Visible = True;
					Break;
				EndIf;
			EndDo;
			
			For Each LangButton In MenuLang.ChildItems Do
				If TypeOf(LangButton) = Type("FormButton") Then
					If StrEndsWith(LangButton.Name, LangSwitchFrom) Then
						LangButton.Visible = False;
						LangButton.Check = False;
						Break;
					EndIf;
				EndIf;
			EndDo;
			
			If ProcessMoreActionsSubmenuItems Then
				LangsToAddAllActions = Items.LangsToAddAllActions;
				For Each LangButton In LangsToAddAllActions.ChildItems Do
					If TypeOf(LangButton) = Type("FormButton") Then
						If StrEndsWith(LangButton.CommandName, LangSwitchFrom) Then
							LangButton.Visible = True;
							Break;
						EndIf;
					EndIf;
				EndDo;
				
				For Each LangButton In MenuLanguageAllActions.ChildItems Do
					If TypeOf(LangButton) = Type("FormButton") Then
						If StrEndsWith(LangButton.CommandName, LangSwitchFrom) Then
							LangButton.Visible = False;
							LangButton.Check = False;
							Break;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			
		EndIf;
	EndIf;
	
	Form.Modified = False;
	
	NotifyDescription = New NotifyDescription("Attachable_WhenSwitchingTheLanguage", Form);
	ExecuteNotifyProcessing(NotifyDescription, TheSelectedLanguage);
	
EndProcedure

// Parameters:
//  Exists - Boolean
//  PreparationParameters - See FileNamePreparationOptions
//
Procedure WhenCheckingTheExistenceOfAFile(Exists, PreparationParameters) Export
	
	If Exists Then
		PreparationParameters.Counter = PreparationParameters.Counter + 1;
	Else
		FileDetails = PreparationParameters.FilesDetails1[PreparationParameters.IndexOf];
		FileDetails.Presentation = PreparationParameters.FileName;
		PreparationParameters.Counter = 0;
		PreparationParameters.IndexOf = PreparationParameters.IndexOf + 1;
	EndIf;
	
	PrepareFileNamesToSaveToADirectory(PreparationParameters);
	
EndProcedure

Procedure GoToTemplate(TemplatePath) Export
	
	OpeningParameters = New Structure("TemplatePath", TemplatePath);
	OpenForm("InformationRegister.UserPrintTemplates.Form.PrintFormTemplates", OpeningParameters);
	
EndProcedure

#EndRegion
