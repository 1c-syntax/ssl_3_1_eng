﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// 
//
// Returns:
//  ValueTable:
//   * Id - String -  field name.
//   * Presentation - String - 
//   * ValueType   - TypeDescription - 
//   * IconName   - String - 
//   * Order       - Number - 
//
Function PrintDataFieldTable() Export
	
	Return FormulasConstructor.FieldTable();
	
EndFunction

// 
//
// Returns:
//  ValueTree:
//   * Id - String -  field name.
//   * Presentation - String - 
//   * ValueType   - TypeDescription - 
//   * IconName   - String - 
//   * Order       - Number - 
//   * Folder         - Boolean - 
//                              
//   * Table       - Boolean - 
//
Function PrintDataFieldTree() Export
	
	Return FormulasConstructor.FieldTree();
	
EndFunction

// 
//
// Parameters:
//  FieldList - See PrintDataFieldTable
//               See PrintDataFieldTree
// 
// Returns:
//  DataCompositionSchema
// 
Function SchemaCompositionDataPrint(FieldList) Export
	
	If TypeOf(FieldList) = Type("ValueTable") Then
		Return LayoutDiagramOfDataFromTheValueTable(FieldList);
	ElsIf TypeOf(FieldList) = Type("ValueTree") Then
		Return DataLayoutSchemeFromTheValueTree(FieldList);
	EndIf;

	Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
		"en = 'Invalid type ""%1"" is passed in parameter ""%2""';"),
		TypeOf(FieldList), "FieldList");
	
EndFunction

// Returns a description of the printed form found in the collection.
// If the description does not exist, returns Undefined.
// This function is intended for use only within the Print procedure.
//
// Parameters:
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  Id         - String -  ID of the print form in the print Manager.
//
// Returns:
//  ValueTableRow of See PrintManagementOverridable.OnPrint.PrintFormsCollection
//
// Example:
//  
//  
//    
//    
//    
//  
//
Function PrintFormInfo(PrintFormsCollection, Id) Export
	Return PrintFormsCollection.Find(Upper(Id), "UpperCaseName");
EndFunction

// Check whether the layout needs to be printed.
// This function is intended for use only within the Print procedure.
//
// Parameters:
//  PrintFormsCollection - ValueTable -  service parameter passed to the Print procedure;
//  TemplateName             - String          -  name of the layout to check.
//
// Returns:
//  Boolean - 
//
Function TemplatePrintRequired(PrintFormsCollection, TemplateName) Export
	
	Return PrintFormsCollection.Find(Upper(TemplateName), "UpperCaseName") <> Undefined;
	
EndFunction

// Adds a table document to the collection of printed forms.
// The procedure is intended for use only within the Print procedure.
//
// Parameters:
//  PrintFormsCollection - ValueTable -  service parameter passed to the Print procedure;
//  TemplateName             - String -  layout name;
//  TemplateSynonym         - String -  a representation of the layout;
//  SpreadsheetDocument     - SpreadsheetDocument -  printed form of the document;
//  Picture              - Picture -  pictogram of the printed form;
//  FullTemplatePath     - String -  path to the layout in the metadata tree, such
//                                   as " Document.Invoice to the buyer.Pf_mxl_account order".
//                                   If you do not specify this parameter, the user will
//                                   not be able to edit the layout in the print Documents form.
//  PrintFormFileName - String -  name used when saving the printed form to a file;
//                        - Map of KeyAndValue:
//                           * Key     - AnyRef -  link to the print object;
//                           * Value - String -  file name.
//
Procedure OutputSpreadsheetDocumentToCollection(PrintFormsCollection, TemplateName, TemplateSynonym, SpreadsheetDocument,
	Picture = Undefined, FullTemplatePath = "", PrintFormFileName = Undefined) Export
	
	PrintFormDetails = PrintFormsCollection.Find(Upper(TemplateName), "UpperCaseName");
	If PrintFormDetails <> Undefined Then
		PrintFormDetails.SpreadsheetDocument = SpreadsheetDocument;
		PrintFormDetails.TemplateSynonym = TemplateSynonym;
		PrintFormDetails.Picture = Picture;
		PrintFormDetails.FullTemplatePath = FullTemplatePath;
		PrintFormDetails.PrintFormFileName = PrintFormFileName;
	EndIf;
	
EndProcedure

// Sets the print area of an object in a table document. It must be used when displaying multiple printed forms
// in a single table document to be able to print sets of documents, as well as to be able to save
// printed forms in separate files.
// It must be called after forming each printed form in a tabular document.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument -  printed form;
//  RowNumberStart - Number -  position of the beginning of the next area in the document;
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  Ref - AnyRef -  the print object.
//
// Example:
//  
//    
//    
//    
//  
//
Procedure SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, Ref) Export
	
	If Not Common.IsReference(TypeOf(Ref)) Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Invalid value of the ""Ref"" parameter.
			|Reference type value was expected, actual value: ""%1"" (type: %2)';"), Ref, TypeOf(Ref));
		Try // 
			Raise MessageText;
		Except
			WriteLogEvent(NStr("en = 'Print';", Common.DefaultLanguageCode()), EventLogLevel.Error, , ,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		Return;
	EndIf;
	
	Item = PrintObjects.FindByValue(Ref);
	If Item = Undefined Then
		AreaName = "Document_" + Format(PrintObjects.Count() + 1, "NZ=; NG=");
		PrintObjects.Add(Ref, AreaName);
	Else
		AreaName = Item.Presentation;
	EndIf;
	
	RowNumberEnd = SpreadsheetDocument.TableHeight;
	SpreadsheetDocument.Area(RowNumberStart, , RowNumberEnd, ).Name = AreaName;
	
	If Not PrintSettings().UseSignaturesAndSeals Then
		Return;
	EndIf;
	
	For Each Drawing In SpreadsheetDocument.Drawings Do
		IsSignatureAndSeal = False;
		For Each NameOfAreaWithSignatureAndSeal In AreaNamesPrefixesWithSignatureAndSeal() Do
			If StrFind(Drawing.Name, NameOfAreaWithSignatureAndSeal) > 0 Then
				IsSignatureAndSeal = True;
				Break;
			EndIf;
		EndDo;
		If Not IsSignatureAndSeal Then
			Continue;
		EndIf;
		If Drawing.DrawingType = SpreadsheetDocumentDrawingType.Picture And StrFind(Drawing.Name, "_Document_") = 0 Then
			Drawing.Name = Drawing.Name + "_" + AreaName;
		EndIf;
	EndDo;
	
EndProcedure

// Returns a list of external print forms.
//
// Parameters:
//  FullMetadataObjectName - String -  full name of the metadata object to get a list
//                                        of printed forms for.
//
// Returns:
//  ValueList:
//   * Value      - String -  ID of the printed form;
//   * Presentation - String -  representation of the printed form.
//
Function PrintFormsListFromExternalSources(FullMetadataObjectName) Export
	
	ExternalPrintForms = New ValueList;
	If Not IsBlankString(FullMetadataObjectName) And FullMetadataObjectName <> "Catalog.MetadataObjectIDs" Then
		If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
			ModuleAdditionalReportsAndDataProcessors.OnReceiveExternalPrintFormList(ExternalPrintForms, FullMetadataObjectName);
		EndIf;
	EndIf;
	
	Return ExternalPrintForms;
	
EndFunction

// Returns a list of print commands for the specified form.
//
// Parameters:
//  Form - ClientApplicationForm
//        - String - 
//                   
//  ListOfObjects - Array -  a collection of metadata objects whose print commands should be used when creating
//                            a list of print commands for the specified form.
// Returns:
//   See CreatePrintCommandsCollection
//
Function FormPrintCommands(Form, ListOfObjects = Undefined) Export
	
	If TypeOf(Form) = Type("ClientApplicationForm") Then
		FormName = Form.FormName;
	Else
		FormName = Form;
	EndIf;
	
	MetadataObject = Metadata.FindByFullName(FormName);
	If MetadataObject <> Undefined And Not Metadata.CommonForms.Contains(MetadataObject) Then
		MetadataObject = MetadataObject.Parent();
	Else
		MetadataObject = Undefined;
	EndIf;

	If MetadataObject <> Undefined Then
		MORef = Common.MetadataObjectID(MetadataObject);
	EndIf;
	
	PrintCommands = CreatePrintCommandsCollection();
	
	StandardProcessing = True;
	SSLSubsystemsIntegration.BeforeAddPrintCommands(FormName, PrintCommands, StandardProcessing);
	PrintManagementOverridable.BeforeAddPrintCommands(FormName, PrintCommands, StandardProcessing);
	
	If StandardProcessing Then
		If ListOfObjects <> Undefined Then
			FillPrintCommandsForObjectsList(ListOfObjects, PrintCommands);
		ElsIf MetadataObject = Undefined Then
			Return PrintCommands;
		Else
			IsDocumentJournal = Common.IsDocumentJournal(MetadataObject);
			ListSettings = New Structure;
			ListSettings.Insert("PrintCommandsManager", Common.ObjectManagerByFullName(MetadataObject.FullName()));
			ListSettings.Insert("AutoFilling", IsDocumentJournal);
			If IsDocumentJournal Then
				SSLSubsystemsIntegration.OnGetPrintCommandListSettings(ListSettings);
				PrintManagementOverridable.OnGetPrintCommandListSettings(ListSettings);
			EndIf;
			
			If ListSettings.AutoFilling Then
				If IsDocumentJournal Then
					FillPrintCommandsForObjectsList(MetadataObject.RegisteredDocuments, PrintCommands);
				EndIf;
			Else
				PrintCommandsToAdd = ObjectPrintCommands(MetadataObject);
				For Each PrintCommand In PrintCommandsToAdd Do
					FillPropertyValues(PrintCommands.Add(), PrintCommand);
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	For Each PrintCommand In PrintCommands Do
		If PrintCommand.Order = 0 Then
			PrintCommand.Order = 50;
		EndIf;
		PrintCommand.AdditionalParameters.Insert("AddExternalPrintFormsToSet", PrintCommand.AddExternalPrintFormsToSet);
	EndDo;
	
	If MetadataObject <> Undefined Then
		SetPrintCommandsSettings(PrintCommands, MORef);
	EndIf;
	
	PrintCommands.Sort("Order Asc, Presentation Asc");
	
	NameParts = StrSplit(FormName, ".");
	ShortFormName = NameParts[NameParts.Count()-1];
	
	// 
	For LineNumber = -PrintCommands.Count() + 1 To 0 Do
		PrintCommand = PrintCommands[-LineNumber];
		FormsList = StrSplit(PrintCommand.FormsList, ",", False);
		If FormsList.Count() > 0 And FormsList.Find(ShortFormName) = Undefined Then
			PrintCommands.Delete(PrintCommand);
		EndIf;
	EndDo;
	
	DefinePrintCommandsVisibilityByFunctionalOptions(PrintCommands, Form);
	
	Return PrintCommands;
	
EndFunction

// Creates an empty table with a description of print commands.
// The print command table is passed to the add print Command procedures 
// located in the configuration object Manager modules that are listed in the procedure
// Print managementdefinable.When defining object print commands.
// 
// Returns:
//  ValueTable:
//
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
//                              
//                             
//                             
//
//                   - Array - 
//
//   * Presentation - String            -  view the command in the Print menu. 
//                                         For example, "Invoice for payment".
//
//   * PrintManager - String           - 
//                                        
//                                        
//                                        
//                                        
//                                        
//   * PrintObjectsTypes - Array       -  (optional) list of object types that the print command is intended for
//                                        . This parameter is used for printing commands in document logs that
//                                        require checking the passed object type before calling the print Manager.
//                                        If the list is empty, when you automatically create a list of print commands
//                                        in the document log, it is filled with the type of object that
//                                        the print command was imported from.
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
//   * Order       - Number             -  (optional) A value from 1 to 100 that indicates the order in which the command
//                                        is placed in relation to other commands. The Print menu commands are sorted
//                                        first by Order, then by view.
//                                        The default value is 50.
//
//   * Picture      - Picture          -  (optional) The image that is displayed next to the command in the Print menu.
//                                         For Example, A Library Card.PDF format.
//
//   * FormsList    - String            -  (optional) Comma-separated form names that
//                                        the command should be displayed in. If this parameter is omitted, the print command will be displayed in
//                                        all forms of the object where the Print subsystem is embedded.
//                                         For Example, "Formdocument".
//
//   * PlacingLocation - String          - 
//                                        
//                                        
//                                        
//                                        
//                                        
//   * FormCaption  - String          - 
//                                        
//
//   * FunctionalOptions - String      -  (optional) Comma-separated names of functional options that affect
//                                        the availability of the print command.
//
//   * VisibilityConditions - Array         -  (optional) Collection of command visibility conditions depending on
//                                        the context. The command visibility conditions are set using the procedure 
//                                        Dobasefinalization.
//                                        If this parameter is omitted, the command is visible regardless of the context.
//                                        
//   * CheckPostingBeforePrint    - Boolean -  (optional) Indicates whether
//                                        documents must be checked before printing. If at least one unproved document is selected
//                                        , the print dialog appears before executing the print command.
//                                        For unprocessed documents, the print command is not executed.
//                                        If this parameter is omitted, the validity check is not performed.
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
//
//   * FixedSet - Boolean    -  (optional) Indicates whether the user should be blocked from changing
//                                        the set of documents. If this parameter is omitted, the user can
//                                        exclude individual printed forms from the set in the print Document form, as
//                                        well as change their number.
//
//   * AdditionalParameters - Structure -  (optional) custom parameters to pass to the print Manager.
//
//   * DontWriteToForm - Boolean  -  (optional) Indicates whether the object's recording mechanism must be disabled
//                                        before executing the print command. Used in exceptional cases. If
//                                        this parameter is omitted, the object is recorded if the
//                                        object form has the modified attribute set.
//
//   * FileSystemExtensionIsRequired - Boolean -  
//                                        
//                                        
//
Function CreatePrintCommandsCollection() Export
	
	Result = New ValueTable;
	
	// LongDesc
	Result.Columns.Add("Id", New TypeDescription("String"));
	Result.Columns.Add("Presentation", New TypeDescription("String"));
	
	//////////
	// 
	
	// 
	Result.Columns.Add("PrintManager", Undefined);
	Result.Columns.Add("PrintObjectsTypes", New TypeDescription("Array"));
	
	// 
	Result.Columns.Add("Handler", New TypeDescription("String"));
	
	// Presentation
	Result.Columns.Add("Order", New TypeDescription("Number"));
	Result.Columns.Add("Picture", New TypeDescription("Picture"));
	// 
	Result.Columns.Add("FormsList", New TypeDescription("String"));
	Result.Columns.Add("PlacingLocation", New TypeDescription("String"));
	Result.Columns.Add("FormCaption", New TypeDescription("String"));
	// 
	Result.Columns.Add("FunctionalOptions", New TypeDescription("String"));
	
	// 
	Result.Columns.Add("VisibilityConditions", New TypeDescription("Array"));
	
	// 
	Result.Columns.Add("CheckPostingBeforePrint");
	
	// Output
	Result.Columns.Add("SkipPreview", New TypeDescription("Boolean"));
	Result.Columns.Add("SaveFormat"); // SpreadsheetDocumentFileType
	
	// 
	Result.Columns.Add("OverrideCopiesUserSetting", New TypeDescription("Boolean"));
	Result.Columns.Add("AddExternalPrintFormsToSet", New TypeDescription("Boolean"));
	Result.Columns.Add("FixedSet", New TypeDescription("Boolean")); // 
	
	// 
	Result.Columns.Add("AdditionalParameters", New TypeDescription("Structure"));
	
	// 
	// 
	Result.Columns.Add("DontWriteToForm", New TypeDescription("Boolean"));
	
	// 
	Result.Columns.Add("FileSystemExtensionIsRequired", New TypeDescription("Boolean"));
	
	// For official use.
	Result.Columns.Add("HiddenByFunctionalOptions", New TypeDescription("Boolean"));
	Result.Columns.Add("UUID", New TypeDescription("String"));
	Result.Columns.Add("isDisabled", New TypeDescription("Boolean"));
	Result.Columns.Add("FormCommandName", New TypeDescription("String"));
	Result.Columns.Add("VisibilityConditionsByObjectTypes", New TypeDescription("Map"));
	Result.Columns.Add("ShouldRunInBackgroundJob");
	
	Return Result;
	
EndFunction

// Sets the visibility conditions for the print command on the form, depending on the context.
//
// Parameters:
//  PrintCommand  - ValueTableRow - :
//   * VisibilityConditions - Array -  list of visibility conditions;
//  Attribute       - String                -  name of the item's details;
//  Value       - Arbitrary          -  value of the item's details;
//  ComparisonMethod - ComparisonType          - : 
//                                           
//                                           
//
Procedure AddCommandVisibilityCondition(PrintCommand, Attribute, Value, Val ComparisonMethod = Undefined) Export
	If ComparisonMethod = Undefined Then
		ComparisonMethod = ComparisonType.Equal;
	EndIf;
	VisibilityCondition = New Structure;
	VisibilityCondition.Insert("Attribute", Attribute);
	VisibilityCondition.Insert("ComparisonType", ComparisonMethod);
	VisibilityCondition.Insert("Value", Value);
	PrintCommand.VisibilityConditions.Add(VisibilityCondition);
EndProcedure

// Used when transferring the layout (metadata object) of a printed form to another object.
// It is intended for calling the update data filling procedure (for a "deferred" handler).
// Registers a new layout address for processing.
//
// Parameters:
//  TemplateName   - String -  new layout name in
//                         the Document format.<Document name>.<Package Name> "
//                         " Processing.<ProcessName>.<Package Name> "
//                         " General Package.<Package name>".
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterNewTemplateName(TemplateName, Parameters) Export
	TemplateNameParts = TemplateNameParts(TemplateName);
	
	RecordSet = InformationRegisters.UserPrintTemplates.CreateRecordSet();
	RecordSet.Filter.TemplateName.Set(TemplateNameParts.TemplateName);
	RecordSet.Filter.Object.Set(TemplateNameParts.ObjectName);
	
	InfobaseUpdate.MarkForProcessing(Parameters, RecordSet);
EndProcedure

// Used when transferring the layout (metadata object) of a printed form to another object.
// It is intended for calling in the" deferred " update handler.
// Transfers user data related to the layout to the new address.
//
// Parameters:
//  Templates     - Map of KeyAndValue - 
//                              
//                              
//                              :
//   * Key     - String -  a new name for the layout.
//   * Value - String -  previous name of the layout.
//
//  Parameters - Structure -  parameters passed to the "deferred" update handler.
//
Procedure TransferUserTemplates(Templates, Parameters) Export
	
	DataForProcessing = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(Parameters.Queue, "InformationRegister.UserPrintTemplates");
	While DataForProcessing.Next() Do
		NewTemplateName = DataForProcessing.Object + "." + DataForProcessing.TemplateName;
		PreviousTemplateName = Templates[NewTemplateName];
		TemplateNameParts = TemplateNameParts(PreviousTemplateName);
		
		RecordManager = InformationRegisters.UserPrintTemplates.CreateRecordManager();
		RecordManager.TemplateName = TemplateNameParts.TemplateName;
		RecordManager.Object = TemplateNameParts.ObjectName;
		RecordManager.Read();
		
		RecordSet = InformationRegisters.UserPrintTemplates.CreateRecordSet();
		RecordSet.Filter.TemplateName.Set(DataForProcessing.TemplateName);
		RecordSet.Filter.Object.Set(DataForProcessing.Object);
		
		If RecordManager.Selected() Then
			Record = RecordSet.Add();
			Record.TemplateName = DataForProcessing.TemplateName;
			Record.Object = DataForProcessing.Object;
			FillPropertyValues(Record, RecordManager, , "TemplateName,Object");
			InfobaseUpdate.WriteData(RecordSet);
			RecordManager.Delete();
		Else
			InfobaseUpdate.MarkProcessingCompletion(RecordSet);
		EndIf;
	EndDo;
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "InformationRegister.UserPrintTemplates");
	
EndProcedure

// Provides an additional access profile " Editing, sending by mail, saving to a file of printed forms (optional)".
// It is intended for use in the procedure for filling in the supplied profiles of the access Group of the access control module Undefined.
//
// Parameters:
//  ProfilesDetails - See AccessManagementOverridable.OnFillSuppliedAccessGroupProfiles.ProfilesDetails
//
Procedure FillProfileEditPrintForms(ProfilesDetails) Export
	
	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	ProfileDetails = ModuleAccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "70179f20-2315-11e6-9bff-d850e648b60c";
	ProfileDetails.Description = NStr("en = 'Edit, send by email, and save print forms to file (additionally)';",
		Common.DefaultLanguageCode());
	ProfileDetails.LongDesc = NStr("en = 'Assign to users whose duties include editing,
		|sending by email, and saving print forms to file.';");
	ProfileDetails.Roles.Add("PrintFormsEdit");
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

// Adds a new area record to the area Set parameter.
//
// Parameters:
//   OfficeDocumentTemplateAreas - Array -  a set of areas (array of structures) of the office document layout.
//   AreaName                     - String -  name of the area to add.
//   AreaType                     - String - :
//    
//    
//    
//    
//    
//
// Example:
//	Function Of The Regionmaketaofisnogodocument ()
//	
//		Area = New Structure;
//	
//		Print management.Adddescription Areas(Areas, "Header", " Header");
//		Print management.Adddescription Areas(Areas, "Footer", " Footer");
//		Print management.Adddescription Areas(Areas, "Title", " General");
//	
//		Returning An Area;
//	
//	End of function
//
Procedure AddAreaDetails(OfficeDocumentTemplateAreas, Val AreaName, Val AreaType) Export
	
	NewArea = New Structure;
	
	NewArea.Insert("AreaName", AreaName);
	NewArea.Insert("AreaType", AreaType);
	
	OfficeDocumentTemplateAreas.Insert(AreaName, NewArea);
	
EndProcedure

// Gets all the necessary information for printing in one call: object data by layout, binary
// layout data, and description of layout areas.
// To call from client modules to print forms based on office document layouts.
//
// Parameters:
//   PrintManagerName - String -  name for accessing the object Manager, such as " Document.<Document name>".
//   TemplatesNames       - String -  names of layouts that will be used for forming printed forms.
//   DocumentsComposition   - Array -  links to information database objects (must be of the same type).
//
// Returns:
//  Map of KeyAndValue - :
//   * Key - AnyRef -  link to the information base object;
//   * Value - Structure:
//       ** Key - String -  layout name;
//       ** Value - Structure -  object data.
//
Function TemplatesAndObjectsDataToPrint(Val PrintManagerName, Val TemplatesNames, Val DocumentsComposition) Export
	
	TemplatesNamesArray = StrSplit(TemplatesNames, ", ", False);
	
	ObjectManager = Common.ObjectManagerByFullName(PrintManagerName);
	TemplatesAndData = ObjectManager.GetPrintInfo(DocumentsComposition, TemplatesNamesArray);
	TemplatesAndData.Insert("LocalPrintFileFolder", Undefined); // 
	
	If Not TemplatesAndData.Templates.Property("TemplateTypes") Then
		TemplatesAndData.Templates.Insert("TemplateTypes", New Map); // 
	EndIf;
	
	Return TemplatesAndData;
	
EndFunction

// Returns the layout of the printed form by the full path to the layout.
//
// If the configuration is designed for multiple languages, it may have multiple layouts for those languages.:
// - PF_DOC_Stenopetala
// - PF_DOC_Schemaupdate
// - etc.
// In this case, the following priority is taken into account when searching for the desired layout:
// 1) in the language specified in the codelanguage parameter,
// 2) in the configuration language (general purpose.The main language code ()),
// 3) without specifying the language.
//
// Parameters:
//  TemplatePath - String - :
//                         
//                         
//                         
//  LanguageCode    - String -  the language in which you want to get the layout.
//                         It consists of the ISO 639-1 language code and, optionally, the ISO 3166-1 country code, separated
//                         by an underscore. Examples: "en", "en_US", "en_GB", "ru", "ru_RU".
//
// Returns:
//  SpreadsheetDocument, BinaryData - 
//
Function PrintFormTemplate(TemplatePath, Val LanguageCode = Undefined) Export
	
	If ValueIsFilled(LanguageCode) Then
		LanguageCode = StrSplit(LanguageCode, "_", True)[0];
	EndIf;
	
	RememberLastUsedTemplate(TemplatePath);
	
	Return FindTemplate(TemplatePath, LanguageCode);
	
EndFunction

// Checks whether the custom layout is used instead of the supplied one.
//
// Parameters:
//  TemplatePath - String - :
//                         
//                         
//                         
// Returns:
//  Boolean - 
//
Function UserTemplateUsed(TemplatePath) Export
	
	If StrStartsWith(TemplatePath, "PF_") Then // 
		Return False;
	EndIf;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Template ""%1"" does not exist. The operation is canceled.';"), TemplatePath);
	PathParts = StrSplit(TemplatePath, ".", True);
	If PathParts.Count() <> 2 And PathParts.Count() <> 3 Then
		Raise ErrorText;
	EndIf;
	
	TemplateName = PathParts[PathParts.UBound()];
	PathParts.Delete(PathParts.UBound());
	ObjectName = StrConcat(PathParts, ".");
	
	QueryText = 
	"SELECT
	|	UserPrintTemplates.TemplateName AS TemplateName
	|FROM
	|	InformationRegister.UserPrintTemplates AS UserPrintTemplates
	|WHERE
	|	UserPrintTemplates.Object = &Object
	|	AND UserPrintTemplates.TemplateName LIKE &TemplateName ESCAPE ""~""
	|	AND UserPrintTemplates.Use";
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("Object", ObjectName);
	Query.Parameters.Insert("TemplateName", Common.GenerateSearchQueryString(TemplateName) + "%");
	
	Selection = Query.Execute().Select();
	
	TemplatesList = New Map;
	If Selection.Next() Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Checks whether the supplied layout has been changed from the previous configuration version.
//
// Parameters:
//  TemplatePath - String - :
//                         
//                         
//                         
// Returns:
//  Boolean - 
//
Function SuppliedTemplateChanged(TemplatePath) Export
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Template ""%1"" does not exist. The operation is canceled.';"), TemplatePath);
	PathParts = StrSplit(TemplatePath, ".", True);
	If PathParts.Count() <> 2 And PathParts.Count() <> 3 Then
		Raise ErrorText;
	EndIf;
	
	TemplateName = PathParts[PathParts.UBound()];
	PathParts.Delete(PathParts.UBound());
	ObjectName = StrConcat(PathParts, ".");
	MetadataObject = Common.MetadataObjectID(ObjectName);
	
	QueryText = 
	"SELECT
	|	SuppliedPrintTemplates.PreviousCheckSum <> """"
	|		AND SuppliedPrintTemplates.Checksum <> SuppliedPrintTemplates.PreviousCheckSum AS Changed,
	|	SuppliedPrintTemplates.TemplateName AS TemplateName
	|FROM
	|	InformationRegister.CommonSuppliedPrintTemplates AS SuppliedPrintTemplates
	|WHERE
	|	SuppliedPrintTemplates.Object = &Object
	|	AND SuppliedPrintTemplates.TemplateName LIKE &TemplateName ESCAPE ""~""
	|	AND SuppliedPrintTemplates.TemplateVersion = &TemplateVersion
	|
	|UNION ALL
	|
	|SELECT
	|	SuppliedPrintTemplates.PreviousCheckSum <> """"
	|		AND SuppliedPrintTemplates.Checksum <> SuppliedPrintTemplates.PreviousCheckSum,
	|	SuppliedPrintTemplates.TemplateName
	|FROM
	|	InformationRegister.SuppliedPrintTemplates AS SuppliedPrintTemplates
	|WHERE
	|	SuppliedPrintTemplates.Object = &Object
	|	AND SuppliedPrintTemplates.TemplateName LIKE &TemplateName ESCAPE ""~""
	|	AND SuppliedPrintTemplates.TemplateVersion = &TemplateVersion";
	
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("Object", MetadataObject);
	Query.Parameters.Insert("TemplateName", Common.GenerateSearchQueryString(TemplateName) + "%");
	Query.Parameters.Insert("TemplateVersion", Metadata.Version);
	
	Selection = Query.Execute().Select();
	
	TemplatesList = New Map;
	While Selection.Next() Do
		TemplatesList.Insert(Selection.TemplateName, Selection.Changed);
	EndDo;
	
	SearchNames = TemplateNames(TemplateName);
	
	For Each SearchName In SearchNames Do
		Changed = TemplatesList[SearchName];
		If Changed <> Undefined Then
			Return Changed;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Switches the use of the custom layout to the layout from the configuration.
// It is used when the layout of the printed form of the configuration and / or the output algorithm are changed without backward
// compatibility with the layout of the previous version of the configuration.
// For use in update handlers.
//
// In the General case when making changes in the layouts and procedures for the formation of printing plates it is necessary to consider 
// the possibility that layouts can be changed by the user (i.e. the basis of the typical layout of the configuration
// and added static text, changed the font, color and other design cells that does not require software 
// processing by algorithms configuration).
//
// However, in some cases exact adherence to the order form filling is more important than compatibility with possible changes 
// the user in the layouts of previous versions (e.g., this is true for strictly regulated printed forms, 
// in violation of the procedure for their application by the authorities to impose fines, to refuse to carry out
// operations, tax deductions, etc. - they are invalid, reducing the number of fields on the form, reflow).
// Examples of such forms are an invoice, created on its basis UPD and UKD, cash orders (KO-1 and KO-2), 
// payment order.
// Therefore, if the user has a modified layout, it should be disabled when updating it so that these printed forms
// are formed correctly.
// 
//
// Parameters:
//  TemplatePath - String - :
//                         
//                         
//                         
//
Procedure DisableUserTemplate(TemplatePath) Export
	
	Templates = CommonClientServer.ValueInArray(TemplatePath);
	InformationRegisters.UserPrintTemplates.SetModifiedTemplatesUsage(Templates, False);
	
EndProcedure

// Returns a table document based on binary data from a table document.
//
// Parameters:
//  BinaryDocumentData - BinaryData -  binary data of a table document.
//
// Returns:
//  SpreadsheetDocument -  table document.
//
Function SpreadsheetDocumentByBinaryData(BinaryDocumentData) Export
	
	TempFileName = GetTempFileName();
	BinaryDocumentData.Write(TempFileName);
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Read(TempFileName);
	
	SafeModeSet = SafeMode();
	If TypeOf(SafeModeSet) = Type("String") Then
		SafeModeSet = True;
	EndIf;
	
	If Not SafeModeSet Then
		DeleteFiles(TempFileName);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

// Generates printed forms in the required format and writes them to files.
// Restriction: printed forms generated on the client are not supported.
//
// Parameters:
//  PrintCommands  - Structure
//                 - Array - 
//                            See PrintManagement.FormPrintCommands.
//  ListOfObjects - Array    -  links to printable objects.
//  SettingsForSaving - See PrintManagement.SettingsForSaving.
//
// Returns:
//  ValueTable:
//   * FileName - String -  file name;
//   * BinaryData - BinaryData -  print form file.
//
Function PrintToFile(PrintCommands, ListOfObjects, SettingsForSaving) Export
	
	Result = New ValueTable;
	Result.Columns.Add("FileName", New TypeDescription("String"));
	Result.Columns.Add("BinaryData", New TypeDescription("BinaryData"));
	
	ListOfCommands = PrintCommands;
	If TypeOf(PrintCommands) <> Type("Array") Then
		ListOfCommands = CommonClientServer.ValueInArray(PrintCommands);
	EndIf;
	
	For Each PrintCommand In ListOfCommands Do
		ExecutePrintToFileCommand(PrintCommand, SettingsForSaving, ListOfObjects, Result);
	EndDo;
	
	If ValueIsFilled(Result) And SettingsForSaving.PackToArchive Then
		BinaryData = PackToArchive(Result);
		Result.Clear();
		File = Result.Add();
		File.FileName = FileName(GetTempFileName("zip"));
		File.BinaryData = BinaryData;
	EndIf;
	
	Return Result;
	
EndFunction

// Constructor for the save Settings parameter of the print Management function.Print the file.
// Defines the format and other settings for writing a table document to a file.
// 
// Returns:
//  Structure - :
//   * SaveFormats - Array -  a collection of values of the type filatablecode,
//                                  or values of the type filatablecode, converted to a string.
//                                  By default, saving is done in PDF format.
//   * PackToArchive   - Boolean -  if set to True, one archive file with files of the specified formats will be created.
//   * TransliterateFilesNames - Boolean -  if set to True, the names of the received files will be in Latin.
//   * SignatureAndSeal    - Boolean -  if set to True and the saved table document supports the placement
//                                  of signatures and seals, then the recorded files will contain signatures and seals.
//
Function SettingsForSaving() Export
	
	Return PrintManagementClientServer.SettingsForSaving();
	
EndFunction

// 
// 
//
// Parameters:
//  ObjectManager - CatalogManager, DocumentManager, DataProcessorManager, InformationRegisterManager - 
//
// Returns:
//  Structure:
//   * OnSpecifyingRecipients - Boolean - 
//                                          
//                                          
//                                           
//   * OnAddPrintCommands - Boolean - 
//                                          
//                                           
//
Function ObjectPrintingSettings(ObjectManager) Export
	
	ObjectSettings = New Structure;
	ObjectSettings.Insert("OnSpecifyingRecipients", False);
	ObjectSettings.Insert("OnAddPrintCommands", False);
	
	PrintSettings = PrintManagementCached.PrintSettings(); 
	
	If PrintSettings.PrintObjects.Get(ObjectManager) <> Undefined Then
		ObjectManager.OnDefinePrintSettings(ObjectSettings);
		Return ObjectSettings;
	EndIf;
	
	// 
	
	ObjectsWithPrintCommands = PrintManagementCached.ObjectsWithPrintCommands();
	
	If ObjectsWithPrintCommands.Get(ObjectManager) <> Undefined Then
		ObjectSettings.OnAddPrintCommands = True;
	EndIf;
	
	Return ObjectSettings;
	
EndFunction


#Region OperationsWithOfficeDocumentsTemplates

////////////////////////////////////////////////////////////////////////////////
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
//							
//							
//

////////////////////////////////////////////////////////////////////////////////
// 

// APK:1382-off-You cannot define the type in the return value.
//
// Designer of a printed form in the format of an office document.
//
// Parameters:
//  DeleteDocumentType            - String -  a legacy option that is not being used;
//  DeleteTemplatePageSettings - Map -  a legacy option that is not being used;
//  Template                          - See InitializeOfficeDocumentTemplate
//
// Returns:
//  Structure - :
//   * DirectoryName        - String -  the path where the directory structure of the final document is placed for the subsequent
//                                   build of the DOCX container.
//   * DocumentStructure - See PrintManagementInternal.InitializeDocument
//   * Type - String
//   * LastSelectedArea - Structure
//
Function InitializePrintForm(Val DeleteDocumentType, Val DeleteTemplatePageSettings = Undefined, Template = Undefined) Export
	
	If Template = Undefined Then
		Raise NStr("en = 'Specify the ""Template"" parameter value';");
	EndIf;
	
	PrintForm = PrintManagementInternal.InitializePrintForm(Template);
	PrintForm.Insert("Type", "DOCX");
	PrintForm.Insert("LastOutputArea", Undefined);
	
	Return PrintForm;
	
EndFunction
// 

// Prepares the layout for use in printing form generation procedures.
//
// Parameters:
//  BinaryTemplateData - BinaryData -  binary layout data;
//  DeleteTemplateType     - String -  a legacy option that is not being used;
//  DeleteTemplateName     - String -  deprecated parameter, not used.
//
// Returns:
//  Structure:
//   * DirectoryName        - String    -  path where the template's DOCX container is unpacked for further analysis;
//   * DocumentStructure - Structure -  information about areas, sections, and headers and footers included in the template.
//
Function InitializeOfficeDocumentTemplate(BinaryTemplateData, Val DeleteTemplateType, Val DeleteTemplateName = "") Export
	
	Template = PrintManagementInternal.TemplateFromBinaryData(BinaryTemplateData);
	If Template <> Undefined Then
		Template.Insert("Type", "DOCX");
		Template.Insert("TemplatePagesSettings", New Map);
	EndIf;
	
	Return Template;
	
EndFunction


// Deletes temporary files that were created after the layout xml structure was expanded.
// It must be called every time after the layout and printed form are formed,
// or if the formation fails.
//
// Parameters:
//  PrintForm            - See PrintManagement.InitializePrintForm
//  DeleteCloseApplication - Boolean    -  deprecated parameter, not used.
//
Procedure ClearRefs(PrintForm, Val DeleteCloseApplication = True) Export
	
	If PrintForm <> Undefined Then
		PrintManagementInternal.CloseConnection(PrintForm);
		PrintForm = Undefined;
	EndIf;
	
EndProcedure

// Generates the output print form file and places it in the storage.
// It is necessary to call after placing all the necessary areas in the structure of the printed form.
//
// Parameters:
//  PrintForm - See PrintManagement.InitializePrintForm.
//
// Returns:
//  String - 
//
Function GenerateDocument(Val PrintForm) Export
	
	PrintFormStorageAddress = PrintManagementInternal.GenerateDocument(PrintForm);
	
	Return PrintFormStorageAddress;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 
// 

// Retrieves an area from the print form layout.
//
// Parameters:
//   RefToTemplate   - Structure -  layout of the printed form.
//   AreaDetails - Structure:
//    * AreaName - String - area name;
//    * AreaTypeType - String - : 
//      
//      
//      
//      
//       
//      
//
// Returns:
//  Structure - 
//
Function TemplateArea(RefToTemplate, AreaDetails) Export
	
	Area = Undefined;
	
	If AreaDetails.AreaType = "Header" Or AreaDetails.AreaType = "EvenHeader" 
		Or AreaDetails.AreaType = "FirstHeader" Then
		Area = PrintManagementInternal.GetHeaderArea(RefToTemplate, AreaDetails.AreaName);
	ElsIf AreaDetails.AreaType = "Footer"  Or AreaDetails.AreaType = "EvenFooter"  
		Or AreaDetails.AreaType = "FirstFooter" Then
		Area = PrintManagementInternal.GetFooterArea(RefToTemplate, AreaDetails.AreaName);
	ElsIf AreaDetails.AreaType = "Shared3" 
		Or AreaDetails.AreaType = "TableRow"
		Or AreaDetails.AreaType = "List" Then
		Area = PrintManagementInternal.GetTemplateArea(RefToTemplate, AreaDetails.AreaName);
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Area type is not specified or invalid: %1.';"), AreaDetails.AreaType);
	EndIf;
	
	If Area <> Undefined Then
		Area.Insert("AreaDetails", AreaDetails);
	EndIf;
	
	Return Area;
	
EndFunction

// Attaches an area to a printed form from the layout.
// Used for single output of an area.
//
// Parameters:
//  PrintForm - See PrintManagement.InitializePrintForm.
//  TemplateArea - See PrintManagement.TemplateArea.
//  GoToNextRow1 - Boolean -  True if you want to insert a break after the area is output.
//
Procedure AttachArea(PrintForm, TemplateArea, Val GoToNextRow1 = False) Export
	
	If TemplateArea = Undefined Then
		Return;
	EndIf;
	
	Try
		
		AreaDetails = TemplateArea.AreaDetails;
		DerivedArea = Undefined;
		
		If AreaDetails.AreaType = "Header" Or AreaDetails.AreaType = "EvenHeader" 
			Or AreaDetails.AreaType = "FirstHeader" Then
				DerivedArea = PrintManagementInternal.AddHeader(PrintForm, TemplateArea);
		ElsIf AreaDetails.AreaType = "Footer"  Or AreaDetails.AreaType = "EvenFooter"
			Or AreaDetails.AreaType = "FirstFooter" Then
			DerivedArea = PrintManagementInternal.AddFooter(PrintForm, TemplateArea);
		ElsIf AreaDetails.AreaType = "Shared3" Or AreaDetails.AreaType = "List" 
			Or AreaDetails.AreaType = "TableRow" Then
			DerivedArea = PrintManagementInternal.AttachArea(PrintForm, TemplateArea, GoToNextRow1);
		Else
			Raise AreaTypeSpecifiedIncorrectlyText();
		EndIf;
		
		AreaDetails.Insert("Area", DerivedArea);
		AreaDetails.Insert("GoToNextRow1", GoToNextRow1);
		
		// 
		PrintForm.LastOutputArea = AreaDetails;
		
	Except
		ErrorMessage = TrimAll(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		ErrorMessage = ?(Right(ErrorMessage, 1) = ".", ErrorMessage, ErrorMessage + ".");
		ErrorMessage = ErrorMessage + " " + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Error occurred during output of %1 template area.';"),
			TemplateArea.AreaDetails.AreaName);
		Raise ErrorMessage;
	EndTry;
	
EndProcedure

// Fills in the parameters of the print form area.
//
// Parameters:
//  PrintForm - Structure -  the area of the printed form or the printed form itself.
//  Data - Structure -  fill-in data.
//
Procedure FillParameters_(PrintForm, Data) Export
	
	AreaDetails = PrintForm.LastOutputArea; // See TemplateArea.AreaDetails
	
	If AreaDetails.AreaType = "Header" Or AreaDetails.AreaType = "EvenHeader" Or AreaDetails.AreaType = "FirstHeader" Then
		PrintManagementInternal.FillHeaderParameters(PrintForm, AreaDetails.Area, Data);
	ElsIf AreaDetails.AreaType = "Footer"  Or AreaDetails.AreaType = "EvenFooter"  Or AreaDetails.AreaType = "FirstFooter" Then
		PrintManagementInternal.FillFooterParameters(PrintForm, AreaDetails.Area, Data);
	ElsIf AreaDetails.AreaType = "Shared3"
			Or AreaDetails.AreaType = "TableRow"
			Or AreaDetails.AreaType = "List" Then
		PrintManagementInternal.FillParameters_(PrintForm, AreaDetails.Area, Data);
	Else
		Raise AreaTypeSpecifiedIncorrectlyText();
	EndIf;

EndProcedure

// Adds an area to the print form from the layout, while replacing the parameters in the area with values from the object data.
// Used for single output of an area.
//
// Parameters:
//  PrintForm - See PrintManagement.InitializePrintForm.
//  TemplateArea - See PrintManagement.TemplateArea.
//  Data - Structure -  fill-in data.
//  GoToNextRow1 - Boolean -  True if you want to insert a break after the area is output.
//
Procedure AttachAreaAndFillParameters(PrintForm, TemplateArea, Data, Val GoToNextRow1 = False) Export
	
	If TemplateArea = Undefined Then
		Return;
	EndIf;
	
	AttachArea(PrintForm, TemplateArea, GoToNextRow1);
	FillParameters_(PrintForm, Data);
	
EndProcedure

// Adds an area to the print form from the layout, while replacing
// the parameters in the area with values from the object data.
// Used for single output of an area.
//
// Parameters:
//  PrintForm - See PrintManagement.InitializePrintForm.
//  TemplateArea - See PrintManagement.TemplateArea.
//  Data - Array -  a collection of elements of the Structure - object data type.
//  GoToNextRow - Boolean -  True if you want to insert a break after the area is output.
//
Procedure JoinAndFillCollection(PrintForm, TemplateArea, Data, Val GoToNextRow = False) Export
	
	If TemplateArea = Undefined Then
		Return;
	EndIf;
	
	AreaDetails = TemplateArea.AreaDetails;
	
	If AreaDetails.AreaType = "TableRow" Or AreaDetails.AreaType = "List" Then
		PrintManagementInternal.JoinAndFillSet(PrintForm, TemplateArea, Data, GoToNextRow);
	Else
		Raise AreaTypeSpecifiedIncorrectlyText();
	EndIf;
	
EndProcedure

// Inserts a line break as a newline character.
//
// Parameters:
//  PrintForm - See PrintManagement.InitializePrintForm.
//
Procedure InsertBreakAtNewLine(PrintForm) Export
	
	PrintManagementInternal.InsertBreakAtNewLine(PrintForm);
	
EndProcedure


#EndRegion

#Region ObsoleteProceduresAndFunctions


// Deprecated. 
// 
//
// 
//
// Parameters:
//  QRString         - String -  data to be placed in the QR code.
//
//  CorrectionLevel - Number - 
//                             
//                     :
//                     
//
//  Size           - Number -  specifies the length of the side of the output image in pixels.
//                     If the minimum possible image size is larger than this parameter, the code will not be generated.
//
// Returns:
//  BinaryData  - 
// 
// Example:
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
Function QRCodeData(QRString, CorrectionLevel, Size) Export
	
	If Common.SubsystemExists("StandardSubsystems.BarcodeGeneration") Then
		BarcodeGenerationModule = Common.CommonModule("BarcodeGeneration");
		Return BarcodeGenerationModule.QRCodeData(QRString, CorrectionLevel, Size);
	EndIf;
	
	SetSafeModeDisabled(True);
	QRCodeGenerator = QRCodeGenerationComponent();
	If QRCodeGenerator = Undefined Then
		Return Undefined;
	EndIf;
	
	Try
		BinaryPictureData = QRCodeGenerator.GenerateQRCode(QRString, CorrectionLevel, Size);
	Except
		WriteLogEvent(NStr("en = 'QR code generation';", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return BinaryPictureData;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region ManagingTemplatesOfOfficeDocsWithDCS


// 
// 
// Parameters:
//  BinaryTemplateData - BinaryData - 
// 
// Returns:
//   See PrintManagementInternal.TemplateFromDCSBinaryData
//
Function InitializeTemplateOfDCSOfficeDoc(BinaryTemplateData) Export
	
	TreeOfTemplate = PrintManagementInternal.TemplateFromDCSBinaryData(BinaryTemplateData);
	DocumentStructure = TreeOfTemplate.DocumentStructure;
	
	NodeOfTextStart = PrintManagementInternal.GetNode(DocumentStructure.DocumentTree, "w:document/w:body");
	CollectStrings(NodeOfTextStart);
	PrintManagementInternal.RestoreFullText(DocumentStructure.DocumentTree, DocumentStructure.Hyperlinks);
	
	Return TreeOfTemplate;
	
EndFunction

// 
// 
// Parameters:
//  DocumentAddress - String - 
//  DigitalSignatures - See DigitalSignature.SetSignatures
//  
Procedure AddStampsToOfficeDoc(DocumentAddress, DigitalSignatures) Export
	BinaryData = GetFromTempStorage(DocumentAddress);
	TreeOfTemplate = InitializeTemplateOfDCSOfficeDoc(BinaryData);
	DocumentStructure = TreeOfTemplate.DocumentStructure;
	
	StampTemplate = GetCommonTemplate("OfficeOpenDigitalSignatureStampTemplate");
	StampTemplateText = StampTemplate.GetText();
	XMLReader = New XMLReader;
	XMLReader.IgnoreWhitespace = True;
	XMLReader.SetString(StampTemplateText);
	
	StampTemplateTree = PrintManagementInternal.ReadXMLIntoTree(XMLReader);
	DeleteInsignificantAttributes(StampTemplateTree);
	
	DocNode = StampTemplateTree.Rows[0];
	StampNode = DocNode.Rows[0];
	
	ArrayOfBookmarks = New Array;
	NodesSearchParameters = PrintManagementInternal.NodesSearchParameters();
	NodesSearchParameters.AttributeName = "w:name";
	NodesSearchParameters.ValuesOfAttribute = "V8DSStamp";
	PrintManagementInternal.FindNodesByContent(DocumentStructure.DocumentTree, "w:bookmarkStart", ArrayOfBookmarks, NodesSearchParameters);
	
	If Not ArrayOfBookmarks.Count() Then
		Return;
	EndIf;
	
	StampBookmarkNode = ArrayOfBookmarks[ArrayOfBookmarks.UBound()];
	StampNodeParent = StampBookmarkNode;
	
	PrintManagementInternal.MoveFormattingParameters(StampNode, StampBookmarkNode);
	 
	PuttingIndex = Undefined;
	PrintManagementInternal.FindStampLocationNode(StampNodeParent, PuttingIndex);
	
	
	ValuesForPopulation = New Map;
	ValuesForPopulation.Insert("[Title]", NStr("en = 'DOCUMENT IS DIGITALLY SIGNED';"));
	ValuesForPopulation.Insert("[HeaderCertificate]", "Certificate");
	ValuesForPopulation.Insert("[HeaderOwner]", "Owner");
	ValuesForPopulation.Insert("[TitleValidityPeriod]", "Valid1");
	
	For Each Signature In DigitalSignatures Do
		Certificate = Signature.Certificate;
		CryptoCertificate = New CryptoCertificate(Certificate.Get());
		
		ValuesForPopulation.Insert("[Owner]", Signature.CertificateOwner);
		ValuesForPopulation.Insert("[Certificate]", CryptoCertificate.SerialNumber);
		
		ActionPeriod = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'from %1 to %2';"),
			Format(CryptoCertificate.ValidFrom, "DLF=D"), 
			Format(CryptoCertificate.ValidTo, "DLF=D"));
			
		ValuesForPopulation.Insert("[ActionPeriod]", ActionPeriod);
		
		PuttingIndex = PuttingIndex + 1;
		StampPlacementNode = PrintManagementInternal.MakeCopyNode(StampNodeParent, PuttingIndex, StampNode);
		PrintManagementInternal.CreateLowerLevelNodes(StampPlacementNode, StampNode);
		SetParametersInTree(ValuesForPopulation, StampPlacementNode, TreeOfTemplate);
	EndDo;
	DocumentPath = PrintManagementInternal.CollectOfficeDocumentFile(TreeOfTemplate);
	BinaryData = New BinaryData(DocumentPath);
	DeleteFiles(DocumentPath);
	DeleteFiles(TreeOfTemplate.DirectoryName);
	PutToTempStorage(BinaryData, DocumentAddress);
EndProcedure

// 
// 
// Parameters:
//  Tree - See PrintManagementInternal.ReadXMLIntoTree
//
Procedure ConvertParameters(Tree) Export

	PrintManagementInternal.ConvertParameters(Tree);
	
EndProcedure


// 
// 
// Parameters:
//  Tree - See PrintManagementInternal.ReadXMLIntoTree
//
Procedure DeleteInsignificantAttributes(Tree) Export
	
	InsignificantAttributes = StrSplit("w:rsidR,w:rsidRPr,w:rsidRDefault,w:rsidP,w:rsidTr", ",");
	PrintManagementInternal.DeleteInsignificantAttributes(Tree, InsignificantAttributes);
	
EndProcedure

// 
// 
// Returns:
//  Structure - :
//   * CollectStrings - Boolean -  
//   * AreaStructure - See PrintManagementInternal.ReadXMLIntoTree
//   * PopulateHeadersAndFooters - Boolean
//   * ShouldAddLinks - Boolean - 
//
Function AreaPopulationParameters() Export
	ParametersStructure = New Structure;
	ParametersStructure.Insert("CollectStrings",  True); 
	ParametersStructure.Insert("AreaStructure", Undefined); 
	ParametersStructure.Insert("PopulateHeadersAndFooters", True); 
	ParametersStructure.Insert("ShouldAddLinks", True);
	Return ParametersStructure;
EndFunction

// 
// 
// Parameters:
//  TreeOfTemplate -  See PrintManagementInternal.ReadXMLIntoTree
//  ParameterValues - Map of KeyAndValue:
//                        ** 
//                        ** 
//  AreaPopulationParameters - See AreaPopulationParameters
//
Procedure SpecifyParameters(TreeOfTemplate, ParameterValues, AreaPopulationParameters) Export
	
	CollectStrings = AreaPopulationParameters.CollectStrings;
	AreaStructure = AreaPopulationParameters.AreaStructure;
	PopulateHeadersAndFooters = AreaPopulationParameters.PopulateHeadersAndFooters;
	ShouldAddLinks = AreaPopulationParameters.ShouldAddLinks;
	
	DocumentStructure = TreeOfTemplate.DocumentStructure;
	DocumentTree = ?(AreaStructure = Undefined, DocumentStructure.DocumentTree, AreaStructure.AreaTree);
	
	If CollectStrings Then
		PrepareConditionalAreasNodes(DocumentTree, DocumentStructure.Hyperlinks);
	EndIf;
	
	If PopulateHeadersAndFooters Then
		For Each HeaderOrFooter In DocumentStructure.HeaderFooter Do
			SetParametersInTree(ParameterValues, HeaderOrFooter.Value, TreeOfTemplate, ShouldAddLinks);
		EndDo;
	EndIf;
		
	SetParametersInTree(ParameterValues, DocumentTree, TreeOfTemplate, ShouldAddLinks);
	
EndProcedure

#EndRegion

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
Function SpreadsheetDocumentSaveFormatsSettings() Export
	
	Return StandardSubsystemsServer.SpreadsheetDocumentSaveFormatsSettings();
	
EndFunction

// Hiding the print command from the submenu "Print".
Procedure DisablePrintCommands(ListOfObjects, ListOfCommands) Export
	
	RecordSet = InformationRegisters.PrintCommandsSettings.CreateRecordSet();
	
	For Each Object In ListOfObjects Do
		ObjectPrintCommands = StandardObjectPrintCommands(Object);
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.PrintCommandsSettings");
		LockItem.SetValue("Owner", Object);
		
		BeginTransaction();
		Try
			Block.Lock();
			
			For Each IDOfCommandToReplace In ListOfCommands Do
				Filter = New Structure;
				Filter.Insert("Id", IDOfCommandToReplace);
				Filter.Insert("SaveFormat", "");
				Filter.Insert("SkipPreview", False);
				Filter.Insert("isDisabled", False);
				
				ListOfCommandsToReplace = ObjectPrintCommands.FindRows(Filter);
				For Each CommandToReplace In ListOfCommandsToReplace Do
					RecordSet.Filter.Owner.Set(Object);
					RecordSet.Filter.UUID.Set(CommandToReplace.UUID);
					RecordSet.Read();
					RecordSet.Clear();
					If RecordSet.Count() = 0 Then
						Record = RecordSet.Add();
					Else
						Record = RecordSet[0];
					EndIf;
					Record.Owner = Object;
					Record.UUID = CommandToReplace.UUID;
					Record.Visible = False;
					RecordSet.Write();
				EndDo;
			EndDo;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

// Returns a list of supplied object print commands.
//
// Parameters:
//  Object - CatalogRef.MetadataObjectIDs
// 
// Returns:
//   See CreatePrintCommandsCollection
//
Function StandardObjectPrintCommands(Object) Export
	
	ObjectPrintCommands = ObjectPrintCommands(
		Common.MetadataObjectByID(Object, False));
		
	ExternalPrintCommands = ObjectPrintCommands.FindRows(New Structure("PrintManager", "StandardSubsystems.AdditionalReportsAndDataProcessors"));
	For Each PrintCommand In ExternalPrintCommands Do
		ObjectPrintCommands.Delete(PrintCommand);
	EndDo;
	
	Return ObjectPrintCommands;
EndFunction

// Returns a list of metadata objects that have the Print subsystem embedded in them.
//
// Returns:
//  Array - 
//
Function PrintCommandsSources() Export
	
	Settings = PrintSettings();
	SSLSubsystemsIntegration.OnDefineObjectsWithPrintCommands(Settings.PrintObjects); // 
	PrintManagementOverridable.OnDefineObjectsWithPrintCommands(Settings.PrintObjects); // 
	
	Result = New Array;
	For Each ObjectManager1 In Settings.PrintObjects Do
		Result.Add(Metadata.FindByType(TypeOf(ObjectManager1)));
	EndDo;
	
	Return Result;
	
EndFunction


// 
//  See PrintManagement.ObjectPrintingSettings.
//
// Parameters:
//  
//    
//                                           
//   
//                                           
//                                           
//    
//   
//                                        
//                                        See PrintManagement.CreatePrintCommandsCollection.
//                                        
//                                        
//
Function PrintSettings() Export
	
	Settings = New Structure;
	Settings.Insert("UseSignaturesAndSeals", True);
	Settings.Insert("HideSignaturesAndSealsForEditing", False);
	Settings.Insert("PrintObjects", New Array);
	Settings.Insert("CheckPostingBeforePrint", False);
	
	SSLSubsystemsIntegration.OnDefinePrintSettings(Settings);
	PrintManagementOverridable.OnDefinePrintSettings(Settings);
	
	Return Settings;
	
EndFunction

Function ObjectPrintCommandsAvailableForAttachments(MetadataObject) Export
	
	If PrintCommandsSources().Find(MetadataObject) <> Undefined Then
		Return ObjectPrintCommands(MetadataObject);
	EndIf;
	
	Return CreatePrintCommandsCollection();
	
EndFunction

Procedure WriteTemplatesInAdditionalLangs(TemplateParameters1) Export
	
	IDOfTemplateBeingCopied  = TemplateParameters1.IDOfTemplateBeingCopied;
	CurrentLanguage						= TemplateParameters1.CurrentLanguage;
	UUID			= TemplateParameters1.UUID;
	IdentifierOfTemplate				= TemplateParameters1.IdentifierOfTemplate;
	LayoutOwner					= TemplateParameters1.LayoutOwner;
	DocumentName					= TemplateParameters1.DocumentName;
	RefTemplate					= TemplateParameters1.RefTemplate;
	TemplateType						= TemplateParameters1.TemplateType;
	
	If IDOfTemplateBeingCopied = "" Then
		Return;
	EndIf;
	
	ArrayOfIDWords = StrSplit(IDOfTemplateBeingCopied, ".", False);
	If ArrayOfIDWords.Count() > 1 Then
		IDOfTemplateBeingCopied = "";	
		NameOfTemplateToCopy = ArrayOfIDWords[ArrayOfIDWords.UBound()];
		ArrayOfIDWords.Delete(ArrayOfIDWords.UBound());
		NameOfObjectBeingCopied = StrConcat(ArrayOfIDWords, ".");
		
		QueryText = 
		"SELECT
		|	UserPrintTemplates.Template,
		|	UserPrintTemplates.TemplateName,
		|	"""" AS LanguageCode
		|FROM
		|	InformationRegister.UserPrintTemplates AS UserPrintTemplates
		|WHERE
		|	UserPrintTemplates.Object = &Object
		|	AND UserPrintTemplates.TemplateName LIKE &TemplateName
		|	AND UserPrintTemplates.Use";
		
		Query = New Query(QueryText);
		Query.Parameters.Insert("Object", NameOfObjectBeingCopied);
		Query.Parameters.Insert("TemplateName", NameOfTemplateToCopy + "_%");
	Else
		QueryText =
		"SELECT
		|	LayoutsPrintedFormsPresentation.Template,
		|	LayoutsPrintedFormsPresentation.LanguageCode
		|FROM
		|	Catalog.PrintFormTemplates.Presentations AS LayoutsPrintedFormsPresentation
		|		LEFT JOIN Catalog.PrintFormTemplates AS PrintFormTemplates
		|		ON LayoutsPrintedFormsPresentation.Ref = PrintFormTemplates.Ref
		|WHERE
		|	PrintFormTemplates.Id = &Id
		|	AND LayoutsPrintedFormsPresentation.LanguageCode <> &LanguageCode";
		
		Query = New Query(QueryText);
		UIDOfCopiedTemplate = Catalogs.PrintFormTemplates.IdentifierOfTemplate(IDOfTemplateBeingCopied);
		Query.SetParameter("Id", UIDOfCopiedTemplate);
		Query.SetParameter("LanguageCode", CurrentLanguage);
	EndIf;
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		If Selection.LanguageCode = "" Then
			ArrayOfTemplateNameWords = StrSplit(Selection.TemplateName, "_");
			TemplateLanguageCode = ArrayOfTemplateNameWords[ArrayOfTemplateNameWords.UBound()];
			If TemplateLanguageCode = CurrentLanguage Then
				Continue;
			EndIf;
		Else
			TemplateLanguageCode = Selection.LanguageCode;
		EndIf;
		
		TemplateAddressInTempStorage = PutToTempStorage(Selection.Template.Get(), UUID);
		
		TemplateDetails = TemplateDetails();
		TemplateDetails.TemplateMetadataObjectName = IdentifierOfTemplate;
		TemplateDetails.TemplateAddressInTempStorage = TemplateAddressInTempStorage;
		TemplateDetails.LanguageCode = TemplateLanguageCode;
		TemplateDetails.Owner = LayoutOwner;
		TemplateDetails.Description = DocumentName;
		TemplateDetails.Ref = RefTemplate;
		TemplateDetails.TemplateType = TemplateType;
		
		WriteTemplate(TemplateDetails);
		
	EndDo;
	
EndProcedure

Function GeneratePrintFormsInBackground(BackgroundPrintingOptions) Export
	
	TemplatesNames = BackgroundPrintingOptions.TemplatesNames;
	OutputParameters = BackgroundPrintingOptions.OutputParameters;
	CurrentLanguage = BackgroundPrintingOptions.CurrentLanguage;
	PrintObjects = BackgroundPrintingOptions.PrintObjects;
	PrintParameters = BackgroundPrintingOptions.PrintParameters;
	StoragesContents = BackgroundPrintingOptions.StoragesContents;
	StorageUUID = BackgroundPrintingOptions.StorageUUID;
	PutToStorages(PrintParameters, StoragesContents, StorageUUID);
	BackgroundPrintingOptions.Delete("StoragesContents");
	
	Result = Undefined;
	// 
	If ValueIsFilled(BackgroundPrintingOptions.DataSource) Then
		If TypeOf(OutputParameters) = Type("Structure") And OutputParameters.Property("LanguageCode") Then
			OutputParameters.LanguageCode = CurrentLanguage;
		EndIf;
		PrintByExternalSource(
			BackgroundPrintingOptions.DataSource,
			BackgroundPrintingOptions.SourceParameters,
			Result,
			PrintObjects,
			OutputParameters);
	Else
		PrintObjectsTypes = New Array;
		PrintParameters.Property("PrintObjectsTypes", PrintObjectsTypes);
		
		AdditionalParameters = Undefined;
		PrintParameters.Property("AdditionalParameters", AdditionalParameters);
		
		PrintForms = GeneratePrintForms(BackgroundPrintingOptions.PrintManagerName, TemplatesNames,
			BackgroundPrintingOptions.CommandParameter, AdditionalParameters, PrintObjectsTypes, CurrentLanguage);
		PrintObjects = PrintForms.PrintObjects;
		OutputParameters = PrintForms.OutputParameters;
		Result = PrintForms.PrintFormsCollection;
	EndIf;
	
	// 
	If TypeOf(PrintParameters) = Type("Structure") And PrintParameters.Property("SaveFormat")
		And ValueIsFilled(PrintParameters.SaveFormat) Then
		FoundFormat = SpreadsheetDocumentSaveFormatsSettings().Find(SpreadsheetDocumentFileType[PrintParameters.SaveFormat], "SpreadsheetDocumentFileType");
		If FoundFormat <> Undefined Then
			SaveFormatSettings = New Structure("SpreadsheetDocumentFileType,Presentation,Extension,Filter");
			FillPropertyValues(SaveFormatSettings, FoundFormat);
			SaveFormatSettings.Filter = SaveFormatSettings.Presentation + "|*." + SaveFormatSettings.Extension;
			SaveFormatSettings.SpreadsheetDocumentFileType = PrintParameters.SaveFormat;
		EndIf;
	EndIf;
	
	ResultOfFormation = New Structure("PrintFormsCollection,BackgroundJobParameters,OfficeDocuments,
	|PrintObjects,OutputParameters,PrintParameters,Messages");
	ResultOfFormation.OutputParameters = OutputParameters;
	ResultOfFormation.BackgroundJobParameters = BackgroundPrintingOptions;
	ResultOfFormation.PrintParameters = PrintParameters; 
	OfficeDocuments = New Map();
	
	For Each ResultString1 In Result Do
		If ValueIsFilled(ResultString1.OfficeDocuments) Then
			ResultString1.OfficeDocuments.Delete(Undefined);
			For Each OfficeDocument In ResultString1.OfficeDocuments Do
				OfficeDocuments.Insert(OfficeDocument.Key, GetFromTempStorage(OfficeDocument.Key));
			EndDo;
			If ResultString1.OfficeDocuments.Count() = 0 Then
				ResultString1.OfficeDocuments = Undefined;
			EndIf;
		EndIf;
	EndDo;
	
	ResultOfFormation.PrintFormsCollection = Common.ValueTableToArray(Result);
	
	ResultOfFormation.OfficeDocuments = OfficeDocuments;
	ResultOfFormation.PrintObjects = PrintObjects;
	ResultOfFormation.Messages = GetUserMessages();	
	
	Return ResultOfFormation;
	
EndFunction

// Generates a printed form from an external source.
//
// Parameters:
//   AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors -  external processing.
//   SourceParameters            - Structure:
//       * CommandID - String -  a comma-separated list of layouts.
//       * RelatedObjects    - Array
//   PrintFormsCollection - see the description of the Print() procedure in the documentation.
//   PrintObjects         - ValueList  - see the description of the Print() procedure in the documentation.
//   OutputParameters       - Structure       - see the description of the Print() procedure in the documentation.
//   
Procedure PrintByExternalSource(AdditionalDataProcessorRef, SourceParameters, PrintFormsCollection,
	PrintObjects, OutputParameters) Export
	
	ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
	ExternalProcessingObject = ModuleAdditionalReportsAndDataProcessors.ExternalDataProcessorObject(AdditionalDataProcessorRef);
	If ExternalProcessingObject = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'External data processor %1, type %2, is not supported.';"),
			String(AdditionalDataProcessorRef),
			String(TypeOf(AdditionalDataProcessorRef)));
	EndIf;
	
	PrintFormsCollection = PreparePrintFormsCollection(SourceParameters.CommandID);
	If Not ValueIsFilled(OutputParameters) Then
		OutputParameters = PrepareOutputParametersStructure();
	EndIf;
	OutputParameters.Insert("AdditionalDataProcessorRef", AdditionalDataProcessorRef);
	
	ExternalProcessingObject.Print(
		SourceParameters.RelatedObjects,
		PrintFormsCollection,
		PrintObjects,
		OutputParameters);
	
	// 
	For Each PrintForm In PrintFormsCollection Do
		If Not PrintForm.OfficeDocuments = Undefined Then
			PrintForm.SpreadsheetDocument = New SpreadsheetDocument;
		EndIf;
			
		If PrintForm.SpreadsheetDocument = Undefined Then
			ErrorMessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Print handler did not generate the spreadsheet document for: %1';"),
				PrintForm.TemplateName);
			Raise(ErrorMessageText);
		EndIf;
		
		PrintForm.SpreadsheetDocument.Copies = PrintForm.Copies2;
		
		If Not TemplateExists(PrintForm.FullTemplatePath) Then
			PrintForm.FullTemplatePath = "";
		EndIf;
		
		PrintForm.Protection = PrintForm.SpreadsheetDocument.Protection;
	EndDo;
	
EndProcedure

// See AttachableCommandsOverridable.OnDefineAttachableObjectsSettingsComposition
Procedure OnDefineAttachableObjectsSettingsComposition(InterfaceSettings4) Export
	Setting = InterfaceSettings4.Add();
	Setting.Key          = "AddPrintCommands";
	Setting.TypeDescription = New TypeDescription("Boolean");
EndProcedure

// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	Kind = AttachableCommandsKinds.Add();
	Kind.Name         = "Print";
	Kind.SubmenuName  = "PrintSubmenu";
	Kind.Title   = NStr("en = 'Print';");
	Kind.Order     = 40;
	Kind.Picture    = PictureLib.Print;
	Kind.Representation = ButtonRepresentation.PictureAndText;
EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	ListOfObjects = New Array;
	For Each Source In Sources.Rows Do
		ListOfObjects.Add(Source.Metadata);
	EndDo;
	If Sources.Rows.Count() = 1 And Common.IsDocumentJournal(Sources.Rows[0].Metadata) Then
		ListOfObjects = Undefined;
	EndIf;
	
	PrintCommands = FormPrintCommands(FormSettings.FormName, ListOfObjects);
	
	HandlerParametersKeys = "Handler, PrintManager, FormCaption, SkipPreview, SaveFormat,
	|OverrideCopiesUserSetting, AddExternalPrintFormsToSet,
	|FixedSet, AdditionalParameters, ShouldRunInBackgroundJob";
	For Each PrintCommand In PrintCommands Do
		If PrintCommand.isDisabled Then
			Continue;
		EndIf;
		Command = Commands.Add();
		FillPropertyValues(Command, PrintCommand, , "Handler");
		Command.Kind = "Print";
		Command.Popup = PrintCommand.PlacingLocation;
		Command.MultipleChoice = True;
		If PrintCommand.PrintObjectsTypes.Count() > 0 Then
			Command.ParameterType = New TypeDescription(PrintCommand.PrintObjectsTypes);
		EndIf;
		Command.VisibilityInForms = PrintCommand.FormsList;
		If PrintCommand.DontWriteToForm Then
			Command.WriteMode = "NotWrite";
		ElsIf PrintCommand.CheckPostingBeforePrint Then
			Command.WriteMode = "Post";
		Else
			Command.WriteMode = "Write";
		EndIf;
		Command.FilesOperationsRequired = PrintCommand.FileSystemExtensionIsRequired;
		
		Command.Handler = "PrintManagementInternalClient.HandlerCommands";
		Command.AdditionalParameters = New Structure(HandlerParametersKeys);
		FillPropertyValues(Command.AdditionalParameters, PrintCommand);
	EndDo;
	
EndProcedure

// See UsersOverridable.OnDefineRoleAssignment
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// 
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.PrintFormsEdit.Name);
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.1.1";
	Handler.Procedure = "PrintManagement.AddEditPrintFormsRoleToBasicRightsProfiles";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.60";
	Handler.Procedure = "InformationRegisters.UserPrintTemplates.ProcessUserTemplates";
	Handler.ExecutionMode = "Deferred";
	Handler.Comment = NStr("en = 'Removes custom templates that are indistinguishable from build-in templates.
		|Disables custom templates that incompatible with the configuration version.';");
	Handler.Id = New UUID("e5b0d876-c766-40a0-a0cf-ffccc83a193f");
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToLock = "InformationRegister.UserPrintTemplates";
	Handler.UpdateDataFillingProcedure = "InformationRegisters.UserPrintTemplates.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead = "InformationRegister.UserPrintTemplates";
	Handler.ObjectsToChange = "InformationRegister.UserPrintTemplates";
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "InformationRegisters.SuppliedPrintTemplates.UpdateTemplatesCheckSum";
	Handler.ExecutionMode = "Deferred";
	Handler.Comment = NStr("en = 'Determines which built-in extension print form templates were modified compared to the previous version.';");
	Handler.Id = New UUID("51f71246-67e3-40e0-80e5-ebb3192fa6c0");
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		PrintManagementModuleNationalLanguageSupport.OnAddUpdateHandlers(Handlers);
	EndIf;
	
	Catalogs.PrintFormTemplates.OnAddUpdateHandlers(Handlers);
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Permissions = New Array;
	Permissions.Add(ModuleSafeModeManager.PermissionToUseAddIn(
		"CommonTemplate.QRCodePrintingComponent", NStr("en = 'Print QR codes.';")));
	PermissionsRequests.Add(
		ModuleSafeModeManager.RequestToUseExternalResources(Permissions));
	
EndProcedure

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("Edit", Metadata.InformationRegisters.UserPrintTemplates)
		Or ModuleToDoListServer.UserTaskDisabled("PrintFormTemplates") Then
		Return;
	EndIf;
	
	// 
	Subsystem = Metadata.Subsystems.Find("Administration");
	If Subsystem = Undefined
		Or Not AccessRight("View", Subsystem)
		Or Not Common.MetadataObjectAvailableByFunctionalOptions(Subsystem) Then
		Sections = ModuleToDoListServer.SectionsForObject("InformationRegister.UserPrintTemplates");
	Else
		Sections = New Array;
		Sections.Add(Subsystem);
	EndIf;
	
	OutputToDoItem = True;
	VersionChecked = CommonSettingsStorage.Load("ToDoList", "PrintForms");
	If VersionChecked <> Undefined Then
		ArrayVersion  = StrSplit(Metadata.Version, ".");
		CurrentVersion = ArrayVersion[0] + ArrayVersion[1] + ArrayVersion[2];
		If VersionChecked = CurrentVersion Then
			OutputToDoItem = False; // 
		EndIf;
	EndIf;
	
	UserTemplatesCount = CountOfUsedUserTemplates();
	
	For Each Section In Sections Do
		SectionID = "CheckCompatibilityWithCurrentVersion" + StrReplace(Section.FullName(), ".", "");
		
		// 
		ToDoItem = ToDoList.Add();
		ToDoItem.Id = "PrintFormTemplates";
		ToDoItem.HasToDoItems      = OutputToDoItem And UserTemplatesCount > 0;
		ToDoItem.Presentation = NStr("en = 'Print form templates';");
		ToDoItem.Count    = UserTemplatesCount;
		ToDoItem.Form         = "InformationRegister.UserPrintTemplates.Form.CheckPrintForms";
		ToDoItem.Owner      = SectionID;
		
		// 
		ToDoGroup = ToDoList.Find(SectionID, "Id");
		If ToDoGroup = Undefined Then
			ToDoGroup = ToDoList.Add();
			ToDoGroup.Id = SectionID;
			ToDoGroup.HasToDoItems      = ToDoItem.HasToDoItems;
			ToDoGroup.Presentation = NStr("en = 'Check compatibility';");
			If ToDoItem.HasToDoItems Then
				ToDoGroup.Count = ToDoItem.Count;
			EndIf;
			ToDoGroup.Owner = Section;
		Else
			If Not ToDoGroup.HasToDoItems Then
				ToDoGroup.HasToDoItems = ToDoItem.HasToDoItems;
			EndIf;
			
			If ToDoItem.HasToDoItems Then
				ToDoGroup.Count = ToDoGroup.Count + ToDoItem.Count;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	
	Objects.Insert(Metadata.Catalogs.PrintFormTemplates.FullName(), "AttributesToEditInBatchProcessing");
	
EndProcedure

// Determines which configuration printable layouts that are delivered have changed from the previous version.
Procedure UpdateTemplatesCheckSum() Export
	
	InformationRegisters.CommonSuppliedPrintTemplates.UpdateTemplatesCheckSum();
	
EndProcedure

Function SuppliedTemplate(TemplatePath, LanguageCode) Export
	
	Return FindTemplate(TemplatePath, LanguageCode, True);
	
EndFunction

Function ObjectMetadataLayout(TemplatePath) Export
	
	PathParts = StrSplit(TemplatePath, ".", True);
	If PathParts.Count() <> 2 And PathParts.Count() <> 3 Then
		Return Undefined;
	EndIf;
	
	TemplateName = PathParts[PathParts.UBound()];
	PathParts.Delete(PathParts.UBound());
	ObjectName = StrConcat(PathParts, ".");
	
	IsCommonTemplate = StrSplit(ObjectName, ".").Count() = 1;
	
	TemplatesCollection = Metadata.CommonTemplates;
	If Not IsCommonTemplate Then
		MetadataObject = Common.MetadataObjectByFullName(ObjectName);
		If MetadataObject = Undefined Then
			Return Undefined;
		EndIf;
		TemplatesCollection = MetadataObject.Templates;
	EndIf;
	
	Return TemplatesCollection.Find(TemplateName);
	
EndFunction

Procedure AddPrintFormsLanguages(LanguagesCodes) Export
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		PrintManagementModuleNationalLanguageSupport.AddPrintFormsLanguages(LanguagesCodes);
	EndIf;
	
EndProcedure

#Region EditSpreadsheetDocument

Function CollectionOfDataSourcesFields(DataSources) Export
	
	Result = New ValueList;
	DetailsOfObjects = Common.MetadataObjectsByIDs(DataSources);
	
	NameOfDataSource = "CollectionOfAvailableFields";
	
	For Each ObjectDetails In DetailsOfObjects Do
		MetadataObjectName = ObjectDetails.Value.FullName();
		For Each DataCompositionSchema In FieldsSourceDataCompositionSchemes(MetadataObjectName, False) Do
			Result.Add(FormulasConstructor.FieldsCollection(DataCompositionSchema.Value), NameOfDataSource);
		EndDo;
	EndDo;

	Result.Add(CollectionOfFieldsCommonAttributes(), NameOfDataSource);
	
	Return Result;
	
EndFunction

Function CommonFieldsOfDataSources(DataSources) Export
	
	Result = Undefined;
	DetailsOfObjects = Common.MetadataObjectsByIDs(DataSources);

	For Each ObjectDetails In DetailsOfObjects Do
		MetadataObjectName = ObjectDetails.Value.FullName();
		CollectionFields = New Array;
		For Each DataCompositionSchema In FieldsSourceDataCompositionSchemes(MetadataObjectName, False) Do
			FieldsCollection = FormulasConstructor.FieldsCollection(DataCompositionSchema.Value);
			For Each Field In CollectionFields(FieldsCollection) Do
				CollectionFields.Add(Field);
			EndDo;
		EndDo;
		If Result = Undefined Then
			Result = SetIntersection(CollectionFields, CollectionFields); // 
		Else
			Result = SetIntersection(Result, CollectionFields);
		EndIf;
	EndDo;	
	
	If Result = Undefined Then
		Result = New Array;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure UpdateListOfAvailableFields(Form, FieldsCollections, NameOfTheFieldList) Export
	
	FormulasConstructor.UpdateFieldCollections(Form, FieldsCollections, NameOfTheFieldList);
	
EndProcedure

Function ListOfOperators(AdditionalFields = Undefined) Export
	
	ListOfOperators = FormulasConstructor.ListOfOperators();
	AddGroupOfFunctionOperatorsForTables(ListOfOperators);
	
	If AdditionalFields <> Undefined Then
		For Each GroupOfAdditionalField In AdditionalFields Do
			Group = ListOfOperators.Rows.Find(GroupOfAdditionalField.Key);

			If Group = Undefined Then
				Group = ListOfOperators.Rows.Add();
				FillPropertyValues(Group, GroupOfAdditionalField.Value);
				Group.Id = GroupOfAdditionalField.Key;
			EndIf;
			
			For Each AdditionalField In GroupOfAdditionalField.Value.Items Do
				Operator = Group.Rows.Add();
				FillPropertyValues(Operator, AdditionalField.Value);
				Operator.Id = AdditionalField.Key;
			EndDo;
		EndDo;
	EndIf;
	
	Group = ListOfOperators.Rows.Find("StringFunctions");
	If Group = Undefined Then
		Group = ListOfOperators.Rows.Add();
		Group.Id = "StringFunctions";
		Group.Presentation = NStr("en = 'String functions';");
		Group.Order = 5;
		Group.Picture = PictureLib.TypeFunction;
	EndIf;
	
	AddAnOperatorToAGroup(Group, PrintModuleName() + CommandSeparator() + "LatinString", NStr("en = 'Latin string';"), New TypeDescription("String"), True);
	
	Group = ListOfOperators.Rows.Find("OtherFunctions");
	If Group = Undefined Then
		Group = ListOfOperators.Rows.Add();
		Group.Id = "OtherFunctions";
		Group.Presentation = NStr("en = 'Other functions';");
		Group.Order = 7;
		Group.Picture = PictureLib.TypeFunction;
	EndIf;
	
	Return FormulasConstructor.FieldsCollection(ListOfOperators);
	
EndFunction

Function FormulasFromText(Val Text, Val Form) Export
	
	Result = New Map();
	
	If Not ValueIsFilled(Text) Then
		Return Result;
	EndIf;

	TextParameters = FindParametersInText(Text);

	For Each Parameter In TextParameters Do
		Presentation = Parameter;
		If StrOccurrenceCount(Parameter, "[") > 1 Then
			Presentation = Mid(Parameter, 2, StrLen(Parameter) - 2);
		EndIf;
		Formula = TheFormulaFromTheView(Form, Presentation);
		If Not StrStartsWith(Formula, "[") Then
			Formula = "[" + Formula + "]";
		EndIf;
		Result.Insert(Parameter, Formula);
	EndDo;
	
	Return Result;
	
EndFunction

Function TheFormulaFromTheView(Form, Presentation) Export
	
	Return FormulasConstructor.TheFormulaFromTheView(Form, Presentation);
	
EndFunction

Function RepresentationTextParameters(Val Text, Val Form) Export
	
	Result = New Map();
	
	If Not ValueIsFilled(Text) Then
		Return Result;
	EndIf;

	TextParameters = FindParametersInText(Text);
	For Each Parameter In TextParameters Do
		Formula = Mid(Parameter, 2, StrLen(Parameter) - 2);
		Presentation = FormulaPresentation(Form, Formula);
		If Not StrStartsWith(Presentation, "[") Or Not StrEndsWith(Presentation, "]")
			Or StrOccurrenceCount(Presentation, "[") > 1 Then
				Presentation = "[" + Presentation + "]";
		EndIf;
		Result.Insert(Parameter, Presentation);
	EndDo;
	
	Return Result;
	
EndFunction

Function FormulaPresentation(Val Form, Val Formula) Export
	
	Return FormulasConstructor.ViewFormulaByFormData(Form, Formula);
	
EndFunction

Function TemplateDataSource(TemplatePath) Export
	
	TemplateDataSource = Catalogs.PrintFormTemplates.TemplateDataSource(TemplatePath);
	If TemplateDataSource <> Undefined Then
		Return TemplateDataSource;
	EndIf;
	
	TemplateDataSource = New Array;
	
	PathParts = StrSplit(TemplatePath, ".", True);
	If PathParts.Count() <> 2 And PathParts.Count() <> 3 Then
		Return TemplateDataSource;
	EndIf;
	
	PathParts.Delete(PathParts.UBound());
	ObjectName = StrConcat(PathParts, ".");
	
	If ObjectName = "CommonTemplate" Then
		TemplateDataSource.Add(Catalogs.MetadataObjectIDs.EmptyRef());
		Return TemplateDataSource;
	EndIf;
	
	MetadataObject = Common.MetadataObjectByFullName(ObjectName);
	If MetadataObject = Undefined Then
		Return TemplateDataSource;
	EndIf;
	
	If Metadata.DataProcessors.Contains(MetadataObject) Then
		AttachableObjectSettings = AttachableCommands.AttachableObjectSettings(ObjectName);
		If ValueIsFilled(AttachableObjectSettings) Then
			MetadataObjectIDs = Common.MetadataObjectIDs(AttachableObjectSettings.Location, False);
			For Each Item In MetadataObjectIDs Do
				TemplateDataSource.Add(Item.Value);
			EndDo;
		EndIf;
	Else
		LayoutOwner = Common.MetadataObjectID(ObjectName, False);
		If LayoutOwner <> Undefined Then
			TemplateDataSource.Add(LayoutOwner);
		EndIf;
	EndIf;
	
	Return TemplateDataSource;
	
EndFunction

Function IsPrintForm(Val IdentifierOfTemplate, Val Owner = Undefined) Export
	
	If Not ValueIsFilled(Owner) Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(IdentifierOfTemplate) Then
		Return True;
	EndIf;
	
	RefTemplate = Catalogs.PrintFormTemplates.RefTemplate(IdentifierOfTemplate);
	If ValueIsFilled(RefTemplate) Then
		Return True;
	EndIf;
	
	MetadataObject = Common.MetadataObjectByID(Owner);

	PrintCommandsSources = PrintCommandsSources();
	If PrintCommandsSources.Find(MetadataObject) = Undefined Then
		Return False;
	EndIf;

	PathParts = StrSplit(IdentifierOfTemplate, ".", True);
	IdentifierOfTemplate = PathParts[PathParts.UBound()];
	PrintCommands = ObjectPrintCommands(MetadataObject, False);
	For Each PrintCommand In PrintCommands Do
		If PrintCommand.PrintManager = PrintModuleName() And StrFind(PrintCommand.Id, IdentifierOfTemplate) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function PrintData(Objects, Fields, LanguageCode) Export
	
	PrintData = New Map;
	PrintData["ObjectTablePartNames"] = New Array;
	PrintData["FieldFormatSettings"] = New Map;
	
	For Each Object In Objects Do
		PrintData[Object] = New Map();
	EndDo;
		
	If Not ValueIsFilled(Fields) Then
		Return PrintData;
	EndIf;
	
	ObjectName = Objects[0].Metadata().FullName();
	
	DataCompositionSchemas = FieldsSourceDataCompositionSchemes(ObjectName, True);
	ListsOfFields = DescriptionOfFieldLists(DataCompositionSchemas, , ObjectName);
	
	FieldsDetails = New ValueTable;
	FieldsDetails.Columns.Add("Field");
	FieldsDetails.Columns.Add("Owner");
	FieldsDetails.Columns.Add("DataCompositionSchema");
	FieldsDetails.Columns.Add("DataCompositionSchemaId");
	FieldsDetails.Columns.Add("DataPath");
	FieldsDetails.Columns.Add("Level", New TypeDescription("Number"));
	FieldsDetails.Columns.Add("Format");
	FieldsDetails.Columns.Add("Type");
	FieldsDetails.Columns.Add("Folder", New TypeDescription("Boolean"));
	FieldsDetails.Columns.Add("Table", New TypeDescription("Boolean"));
	
	Required_Fields = New Map;

	For Each DataPath In Fields Do
		While ValueIsFilled(DataPath) Do
			If Required_Fields[DataPath] = Undefined Then
				FieldDetails = FormulasConstructorInternal.FieldDetails(DataPath, ListsOfFields);
				FillPropertyValues(FieldsDetails.Add(), FieldDetails);
				Required_Fields.Insert(DataPath, FieldDetails);
				
				LanguageCodeWithoutRegion = StrSplit(LanguageCode, "_")[0];
				If ValueIsFilled(LanguageCodeWithoutRegion) And Not StrEndsWith(DataPath, "." + LanguageCodeWithoutRegion)
					And FieldDetails.Type <> Undefined And FieldDetails.Type.ContainsType(Type("String")) Then
					FieldDetails = FormulasConstructorInternal.FieldDetails(DataPath + "." + LanguageCodeWithoutRegion, ListsOfFields);
					If FieldDetails.DataPath <> Undefined Then
						FillPropertyValues(FieldsDetails.Add(), FieldDetails);
						Required_Fields.Insert(DataPath, FieldDetails);
					EndIf;
				EndIf;
			EndIf;
			
			PathParts = StrSplit(DataPath, ".");
			PathParts.Delete(PathParts.UBound());
			DataPath = StrConcat(PathParts, ".");
		EndDo;
	EndDo;
	
	For Each FieldDetails In FieldsDetails Do
		If Not ValueIsFilled(FieldDetails.Format) Then
			FieldDetails.Format = DefaultFormat(FieldDetails.Type);
		EndIf;
		If ValueIsFilled(FieldDetails.Owner) Then
			FieldDetails.Level = StrOccurrenceCount(FieldDetails.Field, ".") + 1;
		EndIf;
	EndDo;
	
	FieldsDetails.Sort("Level");
	FieldHierarchy = New Map;
	
	For Each FieldDetails In FieldsDetails Do
		If FieldDetails.Level = 0 Then
			Continue;
		EndIf;
		Owner = FindFieldVIerarchy(FieldDetails.Owner, FieldHierarchy);
		If Owner = Undefined Then
			FieldHierarchy.Insert(FieldDetails.Owner, New Map);
			Owner = FieldHierarchy[FieldDetails.Owner];
		EndIf;
		Owner.Insert(FieldDetails.Field, New Map);
	EndDo;                                                                                                           
	
	FillDataPrint(PrintData, FieldsDetails, FieldHierarchy, Objects, LanguageCode);	
	
	Return PrintData;
	
EndFunction

Function RefTemplate(TemplatePath) Export
	
	Return Catalogs.PrintFormTemplates.RefTemplate(TemplatePath);
	
EndFunction

Function AreaID(Area) Export
	
	Return PrintManagementClientServer.AreaID(Area);
	
EndFunction

// Saves the custom print layout in the information database.
// 
// Parameters:
//  TemplateDetails - See TemplateDetails
// 
// Returns:
//  String
// 
Function WriteTemplate(TemplateDetails) Export
	
	TemplateMetadataObjectName = TemplateDetails.TemplateMetadataObjectName;
	TemplateAddressInTempStorage = TemplateDetails.TemplateAddressInTempStorage;
	LanguageCode = TemplateDetails.LanguageCode;
	
	If Not ValueIsFilled(TemplateMetadataObjectName) Or ValueIsFilled(TemplateDetails.Ref) Then
		Return Catalogs.PrintFormTemplates.WriteTemplate(TemplateDetails);
	EndIf;
	
	ModifiedTemplate = GetFromTempStorage(TemplateAddressInTempStorage);
	
	NameParts = StrSplit(TemplateMetadataObjectName, ".");
	TemplateName = NameParts[NameParts.UBound()];
	
	OwnerName = "";
	For PartNumber = 0 To NameParts.UBound()-1 Do
		If Not IsBlankString(OwnerName) Then
			OwnerName = OwnerName + ".";
		EndIf;
		OwnerName = OwnerName + NameParts[PartNumber];
	EndDo;
	
	If NameParts.Count() = 3 Then
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		
		TemplateFromMetadata = Common.ObjectManagerByFullName(OwnerName).GetTemplate(TemplateName);
		
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
	Else
		TemplateFromMetadata = GetCommonTemplate(TemplateName);
	EndIf;
	
	If ValueIsFilled(LanguageCode) Then
		TemplateName = TemplateName + "_" + LanguageCode;
	EndIf;
	
	Record = InformationRegisters.UserPrintTemplates.CreateRecordManager();
	Record.Object = OwnerName;
	Record.TemplateName = TemplateName;
	If TemplatesDiffer(TemplateFromMetadata, ModifiedTemplate) Then
		Record.Use = True;
		Record.Template = New ValueStorage(ModifiedTemplate, New Deflation(9));
		Record.Write();
	Else
		Record.Read();
		If Record.Selected() Then
			Record.Delete();
		EndIf;
	EndIf;
	
	Return TemplateMetadataObjectName;
	
EndFunction

Function GenerateSpreadsheetDocument(Template, ObjectsArray, PrintObjects, LanguageCode) Export
	
	FieldsLayout = FieldsLayout(Template);
	
	PrintData = PrintData(ObjectsArray, FieldsLayout, LanguageCode);
	FieldFormatSettings = PrintData["FieldFormatSettings"];
	
	PathToPathPathPictures = New Map();
	For Each Drawing In Template.Drawings Do
		If Drawing.DrawingType <> SpreadsheetDocumentDrawingType.Group Then 
			PathToPathPathPictures.Insert(Drawing.Name, Drawing.DetailsParameter);
		EndIf;
	EndDo;
	
	TemplateAreas = TemplateAreas(Template, PrintData);
	SpreadsheetDocument = New SpreadsheetDocument;
	
	DrawnDrawings = SpreadsheetDocument.Drawings.Count();
	For Each Ref In ObjectsArray Do

		If SpreadsheetDocument.TableHeight > 0 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		For Each Item In TemplateAreas.AllAreas Do
			AreaName = Item.Value;
			OutputCondition = Item.Presentation;
			NumberofReps = 1;

			TableName = TemplateAreas.AreasTables[AreaName];
			If ValueIsFilled(TableName) Then
				NumberofReps = PrintData[Ref][TableName].Count();
			EndIf;
			
			For TabularSectionRowNumber = 1 To NumberofReps Do
				TemplateArea = Template.GetArea(AreaName);
			
				DataSource = New Map;
				CommonClientServer.SupplementMap(DataSource, PrintData[Ref]);
				If ValueIsFilled(TableName) Then
					DataOfTablePartRow = PrintData[Ref][TableName][TabularSectionRowNumber];
					For Each KeyAndValue In DataOfTablePartRow Do
						DataSource[TableName + "." + KeyAndValue.Key] = KeyAndValue.Value;
					EndDo;
				EndIf;
				
				If ValueIsFilled(OutputCondition) Then
					OutputRegion = EvalExpression("[" + OutputCondition + "]", DataSource, FieldFormatSettings, LanguageCode, False);
					If TypeOf(OutputRegion) <> Type("Boolean") Or Not OutputRegion Then
						Continue;
					EndIf;
				EndIf;
				
				ProcessedCells = New Map;
				For LineNumber = 1 To TemplateArea.TableHeight Do
					For ColumnNumber = 1 To TemplateArea.TableWidth Do
						TableCellArea = TemplateArea.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
						
						AreaID = AreaID(TableCellArea);
						If ProcessedCells[AreaID] <> Undefined Then
							Continue;
						EndIf;
						ProcessedCells[AreaID] = True;
						
						If Not ValueIsFilled(TableCellArea.Text) Then
							Continue;
						EndIf;
						
						TableCellArea.Text = ReplaceParametersWithValues(TableCellArea.Text, DataSource, FieldFormatSettings, LanguageCode);
					EndDo;
				EndDo;
	
				SpreadsheetDocument.Put(TemplateArea);
				For IndexOf = DrawnDrawings To SpreadsheetDocument.Drawings.Count() - 1 Do
					Drawing = SpreadsheetDocument.Drawings[IndexOf];
					If Drawing.DrawingType = SpreadsheetDocumentDrawingType.Group Then
						Continue;
					EndIf;
					Drawing.DetailsParameter = PathToPathPathPictures[Drawing.Name];
					If Not ValueIsFilled(Drawing.DetailsParameter) Then
						Continue;
					EndIf;
					ImageLink = EvalExpression(Drawing.DetailsParameter, DataSource, FieldFormatSettings, LanguageCode);
					If TypeOf(ImageLink) = Type("Picture") Then
						Drawing.Picture = ImageLink;
					Else
						Drawing.Picture = PictureFromFile(ImageLink);
					EndIf;
				EndDo;
				DrawnDrawings = SpreadsheetDocument.Drawings.Count();
			EndDo;
		EndDo;
		
		SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, Ref);
		
	EndDo;
	
	DataSource = PrintData[ObjectsArray[0]];
	
	SpreadsheetDocument.Header.LeftText = ReplaceParametersWithValues(Template.Header.LeftText, DataSource, FieldFormatSettings, LanguageCode);
	SpreadsheetDocument.Header.CenterText = ReplaceParametersWithValues(Template.Header.CenterText, DataSource, FieldFormatSettings, LanguageCode);
	SpreadsheetDocument.Header.RightText = ReplaceParametersWithValues(Template.Header.RightText, DataSource, FieldFormatSettings, LanguageCode);
	
	SpreadsheetDocument.Footer.LeftText = ReplaceParametersWithValues(Template.Footer.LeftText, DataSource, FieldFormatSettings, LanguageCode);
	SpreadsheetDocument.Footer.CenterText = ReplaceParametersWithValues(Template.Footer.CenterText, DataSource, FieldFormatSettings, LanguageCode);
	SpreadsheetDocument.Footer.RightText = ReplaceParametersWithValues(Template.Footer.RightText, DataSource, FieldFormatSettings, LanguageCode);
	
	Return SpreadsheetDocument
	
EndFunction

Procedure DeleteTemplate(TemplatePath, LanguageCode = Undefined) Export
	
	Ref = Catalogs.PrintFormTemplates.RefTemplate(TemplatePath);
	If ValueIsFilled(Ref) Then
		Catalogs.PrintFormTemplates.DeleteTemplate(Ref, LanguageCode);
		Return;
	EndIf;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Template ""%1"" does not exist. The operation is canceled.';"), TemplatePath);
	PathParts = StrSplit(TemplatePath, ".", True);
	If PathParts.Count() <> 2 And PathParts.Count() <> 3 Then
		Raise ErrorText;
	EndIf;
	
	TemplateName = PathParts[PathParts.UBound()];
	If ValueIsFilled(LanguageCode) Then
		TemplateName = TemplateName + "_" + LanguageCode;
	EndIf;
	
	PathParts.Delete(PathParts.UBound());
	ObjectName = StrConcat(PathParts, ".");
	
	QueryText = 
	"SELECT
	|	UserPrintTemplates.TemplateName AS TemplateName
	|FROM
	|	InformationRegister.UserPrintTemplates AS UserPrintTemplates
	|WHERE
	|	UserPrintTemplates.Object = &Object
	|	AND (UserPrintTemplates.TemplateName = &TemplateName
	|			OR UserPrintTemplates.TemplateName LIKE &LayoutNameTemplate ESCAPE ""~"")";
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("Object", ObjectName);
	Query.Parameters.Insert("TemplateName", TemplateName);
	Query.Parameters.Insert("LayoutNameTemplate", Common.GenerateSearchQueryString(TemplateName) + "_%");
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.UserPrintTemplates");
	LockItem.SetValue("Object", ObjectName);
	
	BeginTransaction();
	Try
		Block.Lock();
		Selection = Query.Execute().Select();
		
		RecordSet = InformationRegisters.UserPrintTemplates.CreateRecordSet();
		RecordSet.Filter.Object.Set(ObjectName);
		While Selection.Next() Do
			RecordSet.Filter.TemplateName.Set(Selection.TemplateName);
			RecordSet.Write();
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function FindParametersInText(Val Text, Parameters = Undefined, Val StartPosition = 0, OpeningParentheses = 1, ClosingParentheses = 0) Export // 
	
	If Parameters = Undefined Then
		Parameters = New Array;
	EndIf;
	
	If StartPosition = 0 Then
		StartPosition = StrFind(Text, "[");
		If StartPosition = 0 Then
			Return Parameters;
		EndIf;
	EndIf;
	
	EndPosition1 = StrFind(Text, "]", , StartPosition, OpeningParentheses);
	If EndPosition1 > 0 Then
		ClosingParentheses = ClosingParentheses + 1;
		String = Mid(Text, StartPosition, EndPosition1 - StartPosition + 1);
		OpeningParentheses = StrOccurrenceCount(String, "[");
		If OpeningParentheses > ClosingParentheses Then
			FindParametersInText(Text, Parameters, StartPosition, OpeningParentheses, ClosingParentheses);
		Else
			Parameters.Add(String);
			Text = Mid(Text, EndPosition1 + 1);
			FindParametersInText(Text, Parameters)
		EndIf;
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns:
//  Structure:
//   * Ref - CatalogRef.PrintFormTemplates
//   * TemplateAddressInTempStorage - String
//   * TemplateMetadataObjectName - String
//   * LanguageCode - String
//   * Owner - CatalogRef.MetadataObjectIDs
//              - CatalogRef.ExtensionObjectIDs
//   * Description - String
//   * TemplateType - String
//   * DataSources - String
// 
Function TemplateDetails() Export
	
	Result = New Structure;
	Result.Insert("Ref");
	Result.Insert("TemplateAddressInTempStorage");
	Result.Insert("TemplateMetadataObjectName");
	Result.Insert("LanguageCode");
	Result.Insert("Owner");
	Result.Insert("Description");
	Result.Insert("TemplateType");
	Result.Insert("DataSources");
	
	Return Result;
	
EndFunction

Procedure SetExamplesValues(FieldsCollection, PrintData, Pattern) Export

	If Not Common.SubsystemExists("StandardSubsystems.Print") Then
		Return;
	EndIf;
	
	ExampleValues = PrintData[Pattern];
	FieldFormatSettings = PrintData["FieldFormatSettings"];
	
	For Each Item In FieldsCollection.GetItems() Do
		If Not ValueIsFilled(Item.DataPath) Then
			Continue;
		EndIf;

		If Not Item.Folder And Not Item.Table Then
			Item.DefaultFormat = FieldFormatSettings[Item.DataPath];
			
			FieldDataPath = Item.DataPath;
			PathToDataOfTablePart = "";
			
			ThisTableSectionField = ThisTableSectionField(Item.DataPath, PrintData);
			If ThisTableSectionField Then
				PathToDataOfTablePart = PathToDataOfTablePart(FieldDataPath, PrintData);
				FieldDataPath = PathToFieldDataInTablePart(FieldDataPath, PrintData);
			EndIf;

			If ThisTableSectionField Then
				If ExampleValues[PathToDataOfTablePart] <> Undefined And ExampleValues[PathToDataOfTablePart].Count() > 0 Then
					Item.Value = ExampleValues[PathToDataOfTablePart][1][FieldDataPath];
				EndIf;
			Else
				Item.Value = ExampleValues[FieldDataPath]
			EndIf;
			Item.Pattern = Item.Value;
		EndIf;
		
		If ValueIsFilled(Item.Format) Then
			Item.Pattern = Format(Item.Pattern, Item.Format);
		EndIf;
	
		SetExamplesValues(Item, PrintData, Pattern);
	EndDo;
	
EndProcedure

#EndRegion

Function GenerateOfficeDoc(Template, ObjectsArray, PrintObjects, LanguageCode, PrintParameters) Export
	
	TreeOfTemplate = InitializeTemplateOfDCSOfficeDoc(Template);
	DocumentStructure = TreeOfTemplate.DocumentStructure;
	
	FieldsLayout = New Array;
	
	For Each Item In DocumentStructure.TextParameters Do
		Text = Item;
		TextParameters = FindParametersInText(Text);

		For Each Expression In TextParameters Do
			Expression = Mid(Expression, 2, StrLen(Expression) - 2);
			FormulaElements = FormulasConstructorInternal.FormulaElements(Expression);
			For Each ItemDetails In FormulaElements.OperandsAndFunctions Do
				IsFunction = ItemDetails.Value;
				If IsFunction Then
					Continue;
				EndIf;
				
				Operand = FormulaElements.AllItems[ItemDetails.Key];
				Operand = ClearSquareBrackets(Operand);
				If ValueIsFilled(Operand) Then
					FieldsLayout.Add(Operand);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	PrintData = PrintData(ObjectsArray, FieldsLayout, LanguageCode);
	
		
	ObjectTablePartNames = PrintData.Get("ObjectTablePartNames");
	PrintManagementInternal.ExcludeNestedTables(ObjectTablePartNames);
	
	PrepareConditionalAreasNodes(DocumentStructure.DocumentTree, DocumentStructure.Hyperlinks);
	PrintManagementInternal.RunIndexNodes(DocumentStructure.DocumentTree);
	PrintManagementInternal.FindAreas(DocumentStructure, ObjectTablePartNames);
	
	HeaderPopulationParameters = New Array;
	For Each Area In DocumentStructure.Areas Do
		If Not ValueIsFilled(Area.Collection) Then
			ParametersToSupplement = Area.Parameters;
		Else
			ParametersToSupplement = New Array;
			For Each Parameter In Area.Parameters Do
				FormulaElements = FormulasConstructorInternal.FormulaElements(Parameter);
				For Each FormulaElement In FormulaElements.AllItems Do
					If StrOccurrenceCount(FormulaElement, Area.Collection+".") = 0 Then
					CommonClientServer.SupplementArray(HeaderPopulationParameters, 
						     CommonClientServer.ValueInArray(FormulaElement), True);
					EndIf;
				EndDo;
			EndDo;
		EndIf;
		CommonClientServer.SupplementArray(HeaderPopulationParameters, ParametersToSupplement, True);
	EndDo;
				
	For Each HeaderOrFooter In DocumentStructure.HeaderFooter Do
		For Each FooterHeaderRow In HeaderOrFooter.Value.Rows Do
			HeaderFooterParameters = FindParametersInText(FooterHeaderRow.WholeText);
			CommonClientServer.SupplementArray(HeaderPopulationParameters, HeaderFooterParameters, True);
		EndDo;
	EndDo;
		 
	OfficeDocuments = New Map;
	For Each PrintObject In ObjectsArray Do
		TemplateTreeForPopulation = CopyOfTemplateTree(TreeOfTemplate);
		ParameterValues = GetObjectParametersValues(PrintData, PrintObject, TemplateTreeForPopulation, LanguageCode, PrintParameters, HeaderPopulationParameters);
		DocumentTree = TemplateTreeForPopulation.DocumentStructure.DocumentTree; 
		ObjectData = PrintData[PrintObject];
		FieldFormatSettings = PrintData["FieldFormatSettings"];
		FillHeadersAndFooters = True;
		
		For AreaIndex = 0 To DocumentStructure.Areas.Count()-1 Do
			CurrentArea = DocumentStructure.Areas[AreaIndex];
			If ValueIsFilled(CurrentArea.AreaCondition) Then
				SafeModeSet = SafeMode();
				SetSafeMode(True);
				OutputRegion = EvalExpression(CurrentArea.AreaCondition, ObjectData, FieldFormatSettings, LanguageCode, False);
				
				If Not SafeModeSet Then
					SetSafeMode(False);
				EndIf;
				
				If TypeOf(OutputRegion) <> Type("Boolean") Or Not OutputRegion Then
					Continue;
				EndIf;
			EndIf;
			
			AreaStructure = New Structure("AreaTree,Parameters");
			FillPropertyValues(AreaStructure, CurrentArea);
			If ValueIsFilled(CurrentArea.Collection) Then
				CollectionArray = GetAreaData(PrintData, PrintObject, CurrentArea, TemplateTreeForPopulation, LanguageCode, PrintParameters);
				For Each CollectionItem In CollectionArray Do
					RowAreaStructure = Common.CopyRecursive(AreaStructure);
					ProcessNestedAreas(RowAreaStructure, CurrentArea, CollectionItem, ObjectData, FieldFormatSettings, LanguageCode);
					AreaPopulationParameters = AreaPopulationParameters();
					AreaPopulationParameters.CollectStrings = False;
					AreaPopulationParameters.AreaStructure = RowAreaStructure;
					AreaPopulationParameters.PopulateHeadersAndFooters = False;
					SpecifyParameters(TemplateTreeForPopulation, CollectionItem, AreaPopulationParameters);
					TemplateTreeForPopulation.AreasForOutput.Add(RowAreaStructure.AreaTree);
				EndDo;  
			Else
				RowAreaStructure = Common.CopyRecursive(AreaStructure);
				AreaPopulationParameters = AreaPopulationParameters();
				AreaPopulationParameters.CollectStrings = False;
				AreaPopulationParameters.AreaStructure = RowAreaStructure;
				AreaPopulationParameters.PopulateHeadersAndFooters = FillHeadersAndFooters;
				FillHeadersAndFooters = False;
				SpecifyParameters(TemplateTreeForPopulation, ParameterValues, AreaPopulationParameters);
				TemplateTreeForPopulation.AreasForOutput.Add(RowAreaStructure.AreaTree);
			EndIf;
		EndDo;
		
		PointersInArea = New Map;
		For AreaIndex = 0 To TemplateTreeForPopulation.AreasForOutput.UBound() Do
			AreaForOutput = TemplateTreeForPopulation.AreasForOutput[AreaIndex];
			If AreaForOutput.Rows[0].IndexOf = 0 Then 
				TreeForOutput = AreaForOutput;
				PointersInArea.Insert(AreaForOutput.Rows[0].IndexOf, AreaForOutput);
			Else
				LastAddition = PointersInArea[AreaForOutput.Rows[0].IndexOf];
				If LastAddition <> Undefined Then
					ParentOfAddition = ?(LastAddition.Parent = Undefined, TreeForOutput, LastAddition.Parent);
					AdditingIndex = ParentOfAddition.Rows.IndexOf(LastAddition) + AreaForOutput.Rows.Count(); 
				Else
					AddLine = DocumentTree.Rows.Find(AreaForOutput.Rows[0].IndexOf, "IndexOf", True);
					ParentOfAddition = TreeForOutput.Rows.Find(AddLine.Parent.IndexOf, "IndexOf", True);
					If ParentOfAddition <> Undefined Then
						AdditingIndex = ParentOfAddition.Rows.Count();
					Else
						ParentOfAddition = GetSkippedParent(AddLine, TreeForOutput);
						AdditingIndex = 0;
					EndIf;
					
				EndIf;                                     
				
				For Each AdditionNode In AreaForOutput.Rows Do
					NewNode = PrintManagementInternal.MakeCopyNode(ParentOfAddition, AdditingIndex, AdditionNode);
					PointersInArea.Insert(NewNode.IndexOf, NewNode);
					PrintManagementInternal.CreateLowerLevelNodes(NewNode, AdditionNode);
					AdditingIndex = AdditingIndex + 1;
				EndDo;
			EndIf;
		EndDo; 
		
		TemplateTreeForPopulation.DocumentStructure.DocumentTree = TreeForOutput;
		
		PrintFormStorageAddress = PrintManagementInternal.GetPrintForm(TemplateTreeForPopulation);
		OfficeDocuments.Insert(PrintFormStorageAddress, PrintObject);

	EndDo;
	
	Return OfficeDocuments;
	
EndFunction

Function GetPrintForm(TreeOfTemplate, StorageAddress = Undefined) Export
	
	Return PrintManagementInternal.GetPrintForm(TreeOfTemplate, StorageAddress);
	
EndFunction

Function TagNameCondition() Export

	Return PrintManagementClientServer.TagNameCondition();

EndFunction

Function GetTextsNodes(DocNode, MapOfNodes = Undefined) Export
	
	Return PrintManagementInternal.GetTextsNodes(DocNode, MapOfNodes);
	
EndFunction

Function GetTemplateRecordKey(IdentifierOfTemplate) Export
	Return InformationRegisters.UserPrintTemplates.GetTemplateRecordKey(IdentifierOfTemplate);
EndFunction

#EndRegion

#Region Private

// Adds the PrintForm Editing role to all profiles that include the basic rights Role.
Procedure AddEditPrintFormsRoleToBasicRightsProfiles() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	
	NewRoles = New Array;
	NewRoles.Add(Metadata.Roles.BasicAccessSSL.Name);
	NewRoles.Add(Metadata.Roles.PrintFormsEdit.Name);
	
	RolesToReplace = New Map;
	RolesToReplace.Insert(Metadata.Roles.BasicAccessSSL.Name, NewRoles);
	
	ModuleAccessManagement.ReplaceRolesInProfiles(RolesToReplace);
	
EndProcedure

// Returns a reference to the source object of the external print form.
//
// Parameters:
//  Id              - String -  form ID;
//  FullMetadataObjectName - String -  full name of the metadata object to get a link
//                                        to the source of the external print form for.
//
// Returns:
//  AnyRef
//
Function AdditionalPrintFormRef(Id, FullMetadataObjectName)
	ExternalPrintFormRef = Undefined;
	
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
		ModuleAdditionalReportsAndDataProcessors.OnReceiveExternalPrintForm(Id, FullMetadataObjectName, ExternalPrintFormRef);
	EndIf;
	
	Return ExternalPrintFormRef;
EndFunction

// To form a printing plate.
Function GeneratePrintForms(Val PrintManagerName, Val TemplatesNames, Val ObjectsArray, Val PrintParameters, 
	AllowedPrintObjectsTypes = Undefined, Val LanguageCode = Undefined) Export
	
	PrintFormsCollection = PreparePrintFormsCollection(New Array);
	PrintObjects = New ValueList;
	
	OutputParameters = PrepareOutputParametersStructure();
	If ValueIsFilled(LanguageCode) Then
		OutputParameters.LanguageCode = LanguageCode;
	EndIf;
	
	If TypeOf(TemplatesNames) = Type("String") Then
		TemplatesNames = StrSplit(TemplatesNames, ",");
	Else // 
		TemplatesNames = Common.CopyRecursive(TemplatesNames);
	EndIf;
	
	GeneralPrintManager = PrintModuleName();
	ExternalPrintFormsPrefix = "ExternalPrintForm.";
	
	ExternalPrintFormsSource = PrintManagerName;
	If Common.IsReference(TypeOf(ObjectsArray)) Then
		ExternalPrintFormsSource = ObjectsArray.Metadata().FullName();
	Else
		If ObjectsArray.Count() > 0 Then
			ExternalPrintFormsSource = ObjectsArray[0].Metadata().FullName();
		EndIf;
	EndIf;
	ExternalPrintForms = PrintFormsListFromExternalSources(ExternalPrintFormsSource);
	
	// 
	AddedExternalPrintForms = New Array;
	If TypeOf(PrintParameters) = Type("Structure") 
		And PrintParameters.Property("AddExternalPrintFormsToSet") 
		And PrintParameters.AddExternalPrintFormsToSet Then 
		
		ExternalPrintFormsIDs = ExternalPrintForms.UnloadValues();
		For Each Id In ExternalPrintFormsIDs Do
			TemplatesNames.Add(ExternalPrintFormsPrefix + Id);
			AddedExternalPrintForms.Add(ExternalPrintFormsPrefix + Id);
		EndDo;
	EndIf;
	
	For Each TemplateName In TemplatesNames Do
		// 
		FoundPrintForm = PrintFormsCollection.Find(TemplateName, "TemplateName");
		If FoundPrintForm <> Undefined Then
			LastAddedPrintForm = PrintFormsCollection[PrintFormsCollection.Count() - 1];
			If LastAddedPrintForm.TemplateName = FoundPrintForm.TemplateName Then
				LastAddedPrintForm.Copies2 = LastAddedPrintForm.Copies2 + 1;
			Else
				PrintFormCopy = PrintFormsCollection.Add();
				FillPropertyValues(PrintFormCopy, FoundPrintForm);
				PrintFormCopy.Copies2 = 1;
			EndIf;
			Continue;
		EndIf;
		
		// 
		AdditionalPrintManagerName = "";
		Id = TemplateName;
		ExternalPrintForm = Undefined;
		If StrFind(Id, ExternalPrintFormsPrefix) > 0 Then // 
			Id = Mid(Id, StrLen(ExternalPrintFormsPrefix) + 1);
			ExternalPrintForm = ExternalPrintForms.FindByValue(Id);
		ElsIf StrFind(Id, ".") > 0 Then // 
			If StrStartsWith(Id, GeneralPrintManager + ".") Then
				Id = Mid(Id, StrLen(GeneralPrintManager) + 2);
				AdditionalPrintManagerName = GeneralPrintManager;
			ElsIf PrintManagerName <> GeneralPrintManager Then
				Position = StrFind(Id, ".", SearchDirection.FromEnd);
				AdditionalPrintManagerName = Left(Id, Position - 1);
				Id = Mid(Id, Position + 1);
			EndIf;
		EndIf;
		
		// 
		UsedPrintManager = AdditionalPrintManagerName;
		If IsBlankString(UsedPrintManager) Then
			UsedPrintManager = PrintManagerName;
		EndIf;
		
		// 
		ObjectsCorrespondingToPrintForm = ObjectsArray;
		If AllowedPrintObjectsTypes <> Undefined And AllowedPrintObjectsTypes.Count() > 0 Then
			If TypeOf(ObjectsArray) = Type("Array") Then
				ObjectsCorrespondingToPrintForm = New Array;
				For Each Object In ObjectsArray Do
					If AllowedPrintObjectsTypes.Find(TypeOf(Object)) = Undefined Then
						MessagePrintFormUnavailable(Object);
					Else
						ObjectsCorrespondingToPrintForm.Add(Object);
					EndIf;
				EndDo;
				If ObjectsCorrespondingToPrintForm.Count() = 0 Then
					ObjectsCorrespondingToPrintForm = Undefined;
				EndIf;
			ElsIf Common.RefTypeValue(ObjectsArray) Then // 
				If AllowedPrintObjectsTypes.Find(TypeOf(ObjectsArray)) = Undefined Then
					MessagePrintFormUnavailable(ObjectsArray);
					ObjectsCorrespondingToPrintForm = Undefined;
				EndIf;
			EndIf;
		EndIf;
		PrintManagementOverridable.BeforePrint(Id, ObjectsCorrespondingToPrintForm, PrintParameters);
		
		TempCollectionForSinglePrintForm = PreparePrintFormsCollection(Id);
		
		// 
		If ExternalPrintForm <> Undefined Then
			// 
			PrintByExternalSource(
				AdditionalPrintFormRef(ExternalPrintForm.Value, ExternalPrintFormsSource),
				New Structure("CommandID, RelatedObjects", ExternalPrintForm.Value, ObjectsCorrespondingToPrintForm),
				TempCollectionForSinglePrintForm,
				PrintObjects,
				OutputParameters);
		Else
			If Not IsBlankString(UsedPrintManager) Then
				// 
				If ObjectsCorrespondingToPrintForm <> Undefined Then
					ThisPrintableFormSKD = UsedPrintManager = PrintModuleName();
					If ThisPrintableFormSKD Then
						// 
						Print(ObjectsCorrespondingToPrintForm, PrintParameters, TempCollectionForSinglePrintForm, 
							PrintObjects, OutputParameters); 
					Else
						ClearLastUsedTemplate();
						PrintManager = Common.ObjectManagerByFullName(UsedPrintManager);
						Try
							PrintManager.Print(ObjectsCorrespondingToPrintForm, PrintParameters, TempCollectionForSinglePrintForm, 
								PrintObjects, OutputParameters);
						Except
							If TempCollectionForSinglePrintForm.Count() <> 1 Then
								Raise;
							EndIf;
							
							WriteLogEvent(NStr("en = 'Print';", Common.DefaultLanguageCode()), EventLogLevel.Error, , ,
								ErrorProcessing.DetailErrorDescription(ErrorInfo()));
							
							If Not AccessRight("Update", Metadata.InformationRegisters.UserPrintTemplates) Then
								Raise NStr("en = 'Cannot generate the print form.
									|Contact the administrator.';");
							EndIf;
							
							If Not ValueIsFilled(TempCollectionForSinglePrintForm[0].FullTemplatePath) Then
								FullTemplatePath = LastUsedTemplate();
								
								If ValueIsFilled(FullTemplatePath) And UserTemplateUsed(FullTemplatePath) Then
									TempCollectionForSinglePrintForm[0].FullTemplatePath = LastUsedTemplate();
								Else
									Raise;
								EndIf;
							EndIf;
							
							TempCollectionForSinglePrintForm[0].SpreadsheetDocument = New SpreadsheetDocument;
							TempCollectionForSinglePrintForm[0].GenerationErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
						EndTry;
					EndIf;
				Else
					TempCollectionForSinglePrintForm[0].SpreadsheetDocument = New SpreadsheetDocument;
				EndIf;
			EndIf;
		EndIf;
		
		// 
		For Each PrintFormDetails In TempCollectionForSinglePrintForm Do
			CommonClientServer.Validate(
				TypeOf(PrintFormDetails.Copies2) = Type("Number") And PrintFormDetails.Copies2 > 0,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'The number of copies is not specified for %1 print form.';"),
				?(IsBlankString(PrintFormDetails.TemplateSynonym), PrintFormDetails.TemplateName, PrintFormDetails.TemplateSynonym)));
		EndDo;
				
		// 
		Cancel = TempCollectionForSinglePrintForm.Count() = 0;
		// 
		For Each TempPrintForm In TempCollectionForSinglePrintForm Do 
			
			If Not TempPrintForm.OfficeDocuments = Undefined Then
				TempPrintForm.SpreadsheetDocument = New SpreadsheetDocument;
			EndIf;
			
			If Not TemplateExists(TempPrintForm.FullTemplatePath) Then
				TempPrintForm.FullTemplatePath = "";
			EndIf;
			
			If TempPrintForm.SpreadsheetDocument <> Undefined Then
				PrintForm = PrintFormsCollection.Add();
				FillPropertyValues(PrintForm, TempPrintForm);
				If TempCollectionForSinglePrintForm.Count() = 1 Then
					PrintForm.TemplateName = TemplateName;
					PrintForm.UpperCaseName = Upper(TemplateName);
				EndIf;
				PrintForm.Protection = TempPrintForm.SpreadsheetDocument.Protection;
			Else
				// 
				Cancel = True;
			EndIf;
			
		EndDo;
		
		// 
		If Cancel Then
			ErrorMessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"en = 'Cannot generate the ""%1"" print form. Contact the administrator.';"), TemplateName);
			Raise ErrorMessageText;
		EndIf;
		
	EndDo;
	
	SSLSubsystemsIntegration.OnPrint(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintManagementOverridable.OnPrint(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
	// 
	For Each PrintForm In PrintFormsCollection Do
		CheckSpreadsheetDocumentLayoutByPrintObjects(PrintForm.SpreadsheetDocument, 
			PrintObjects, PrintManagerName, PrintForm.TemplateName);
		If AddedExternalPrintForms.Find(PrintForm.TemplateName) <> Undefined Then
			PrintForm.Copies2 = 0; // 
		EndIf;
		If PrintForm.SpreadsheetDocument <> Undefined Then
			PrintForm.SpreadsheetDocument.Copies = PrintForm.Copies2;
			RemoveSignatureAndSeal(PrintForm.SpreadsheetDocument);
		EndIf;
	EndDo;
	
	Result = New Structure;
	Result.Insert("PrintFormsCollection", PrintFormsCollection);
	Result.Insert("PrintObjects", PrintObjects);
	Result.Insert("OutputParameters", OutputParameters);
	Return Result;
	
EndFunction

// Generate printed forms for direct output to the printer.
//
Function GeneratePrintFormsForQuickPrint(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters) Export
	
	Result = New Structure;
	Result.Insert("SpreadsheetDocuments");
	Result.Insert("PrintObjects");
	Result.Insert("OutputParameters");
	Result.Insert("Cancel", False);
		
	If Not AccessRight("Output", Metadata) Then
		Result.Cancel = True;
		Return Result;
	EndIf;
	
	PrintForms = GeneratePrintForms(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters);
		
	SpreadsheetDocuments = New ValueList;
	For Each PrintForm In PrintForms.PrintFormsCollection Do
		If (TypeOf(PrintForm.SpreadsheetDocument) = Type("SpreadsheetDocument")) And (PrintForm.SpreadsheetDocument.TableHeight <> 0) Then
			SpreadsheetDocuments.Add(PrintForm.SpreadsheetDocument, PrintForm.TemplateSynonym);
		EndIf;
	EndDo;
	
	Result.SpreadsheetDocuments = SpreadsheetDocuments;
	Result.PrintObjects      = PrintForms.PrintObjects;
	Result.OutputParameters    = PrintForms.OutputParameters;
	Return Result;
	
EndFunction

// Generate printed forms for direct output to the printer
// in server mode in a normal application.
//
Function GeneratePrintFormsForQuickPrintOrdinaryApplication(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters) Export
	
	Result = New Structure;
	Result.Insert("Address");
	Result.Insert("PrintObjects");
	Result.Insert("OutputParameters");
	Result.Insert("Cancel", False);
	
	PrintForms = GeneratePrintFormsForQuickPrint(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters);
	
	If PrintForms.Cancel Then
		Result.Cancel = PrintForms.Cancel;
		Return Result;
	EndIf;
	
	Result.PrintObjects = New Map;
	
	For Each PrintObject In PrintForms.PrintObjects Do
		Result.PrintObjects.Insert(PrintObject.Presentation, PrintObject.Value);
	EndDo;
	
	Result.Address = PutToTempStorage(PrintForms.SpreadsheetDocuments);
	Return Result;
	
EndFunction

// Filters the list of print commands according to the set functional options.
Procedure DefinePrintCommandsVisibilityByFunctionalOptions(PrintCommands, Form = Undefined)
	For Each PrintCommandDetails In PrintCommands Do
		FunctionalOptionsOfPrintCommand = StrSplit(PrintCommandDetails.FunctionalOptions, ", ", False);
		CommandVisibility = FunctionalOptionsOfPrintCommand.Count() = 0;
		For Each FunctionalOption In FunctionalOptionsOfPrintCommand Do
			If TypeOf(Form) = Type("ClientApplicationForm") Then
				CommandVisibility = CommandVisibility Or Form.GetFormFunctionalOption(FunctionalOption);
			Else
				CommandVisibility = CommandVisibility Or GetFunctionalOption(FunctionalOption);
			EndIf;
			
			If CommandVisibility Then
				Break;
			EndIf;
		EndDo;
		PrintCommandDetails.HiddenByFunctionalOptions = Not CommandVisibility;
	EndDo;
EndProcedure

Function QRCodeGenerationComponent()
	
	ErrorText = NStr("en = 'Failed to attach QR code add-in. See the Event log for details.';");
	
	Result = Common.AttachAddInFromTemplate("QRCodeExtension", "CommonTemplate.QRCodePrintingComponent");
	If Result = Undefined Then 
		Common.MessageToUser(ErrorText);
	EndIf;
	
	Return Result;
	
EndFunction

Procedure MessagePrintFormUnavailable(Object)
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Cannot print %1: the print form is unavailable.';"), Object);
	Common.MessageToUser(MessageText, Object);
EndProcedure

// Generates a package of documents to send to the printer.
Function DocumentsPackage(SpreadsheetDocuments, PrintObjects, PrintInSets, Copies = 1) Export
	
	RepresentableDocumentBatch = New RepresentableDocumentBatch;
	RepresentableDocumentBatch.Collate = True;
	PrintFormsCollection = SpreadsheetDocuments.UnloadValues();
	
	For Each PrintForm In PrintFormsCollection Do
		PrintInSets = PrintInSets Or PrintForm.DuplexPrinting <> DuplexPrintingType.None;
	EndDo;
	
	If PrintInSets And PrintObjects.Count() > 1 Then 
		For Each PrintObject In PrintObjects Do
			AreaName = PrintObject.Presentation;
			For Each PrintForm In PrintFormsCollection Do
				Area = PrintForm.Areas.Find(AreaName);
				If Area = Undefined Then
					Continue;
				EndIf;
				
				SpreadsheetDocument = PrintForm.GetArea(Area.Top, , Area.Bottom);
				FillPropertyValues(SpreadsheetDocument, PrintForm, SpreadsheetDocumentPropertiesToCopy());
				
				RepresentableDocumentBatch.Content.Add().Data = PackageWithOneSpreadsheetDocument(SpreadsheetDocument);
			EndDo;
		EndDo;
	Else
		For Each PrintForm In PrintFormsCollection Do
			SpreadsheetDocument = New SpreadsheetDocument;
			SpreadsheetDocument.Put(PrintForm);
			FillPropertyValues(SpreadsheetDocument, PrintForm, SpreadsheetDocumentPropertiesToCopy());
			RepresentableDocumentBatch.Content.Add().Data = PackageWithOneSpreadsheetDocument(SpreadsheetDocument);
		EndDo;
	EndIf;
	
	SetsPackage = New RepresentableDocumentBatch;
	SetsPackage.Collate = True;
	For Number = 1 To Copies Do
		SetsPackage.Content.Add().Data = RepresentableDocumentBatch;
	EndDo;
	
	Return SetsPackage;
	
EndFunction

// Wraps a table document in a package of displayed documents.
Function PackageWithOneSpreadsheetDocument(SpreadsheetDocument)
	SpreadsheetDocumentAddressInTempStorage = PutToTempStorage(SpreadsheetDocument);
	PackageWithOneDocument = New RepresentableDocumentBatch;
	PackageWithOneDocument.Collate = True;
	PackageWithOneDocument.Content.Add(SpreadsheetDocumentAddressInTempStorage);
	FillPropertyValues(PackageWithOneDocument, SpreadsheetDocument, "Output, DuplexPrinting, PrinterName, Copies, PrintAccuracy");
	If SpreadsheetDocument.Collate <> Undefined Then
		PackageWithOneDocument.Collate = SpreadsheetDocument.Collate;
	EndIf;
	Return PackageWithOneDocument;
EndFunction

// Collects a list of print commands from multiple objects.
Procedure FillPrintCommandsForObjectsList(ListOfObjects, PrintCommands)
	PrintCommandsSources = New Map;
	For Each PrintCommandsSource In PrintCommandsSources() Do
		PrintCommandsSources.Insert(PrintCommandsSource, True);
	EndDo;
	
	For Each MetadataObject In ListOfObjects Do
		If PrintCommandsSources[MetadataObject] = Undefined Then
			Continue;
		EndIf;
		FormPrintCommands = ObjectPrintCommands(MetadataObject); // 
		
		For Each PrintCommandToAdd In FormPrintCommands Do
			If PrintCommandToAdd.isDisabled Then
				Continue;
			EndIf;
			// 
			FoundCommands = PrintCommands.FindRows(New Structure("UUID", PrintCommandToAdd.UUID));
			
			For Each ExistingPrintCommand In FoundCommands Do
				// 
				ObjectType = Type(StrReplace(MetadataObject.FullName(), ".", "Ref."));
				If ExistingPrintCommand.PrintObjectsTypes.Find(ObjectType) = Undefined Then
					ExistingPrintCommand.PrintObjectsTypes.Add(ObjectType);
				EndIf;
				If ValueIsFilled(PrintCommandToAdd.VisibilityConditions) Then
					ExistingPrintCommand.VisibilityConditionsByObjectTypes.Insert(ObjectType, PrintCommandToAdd.VisibilityConditions);
				EndIf;
				// 
				If ExistingPrintCommand.PrintManager <> PrintCommandToAdd.PrintManager Then
					ExistingPrintCommand.PrintManager = "";
				EndIf;
			EndDo;
			If FoundCommands.Count() > 0 Then
				Continue;
			EndIf;
			
			If PrintCommandToAdd.PrintObjectsTypes.Count() = 0 Then
				PrintCommandToAdd.PrintObjectsTypes.Add(Type(StrReplace(MetadataObject.FullName(), ".", "Ref.")));
			EndIf;
			FillPropertyValues(PrintCommands.Add(), PrintCommandToAdd);
		EndDo;
	EndDo;
EndProcedure

// For internal use only.
//
Function CountOfUsedUserTemplates()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UserPrintTemplates.TemplateName
	|FROM
	|	InformationRegister.UserPrintTemplates AS UserPrintTemplates
	|WHERE
	|	UserPrintTemplates.Use = TRUE";
	
	Result = Query.Execute().Unload();
	
	Return Result.Count();
	
EndFunction

Procedure SetPrintCommandsSettings(PrintCommands, Owner)
	
	QueryText =
	"SELECT
	|	PrintCommandsSettings.UUID AS UUID
	|FROM
	|	InformationRegister.PrintCommandsSettings AS PrintCommandsSettings
	|WHERE
	|	PrintCommandsSettings.Owner = &Owner
	|	AND NOT PrintCommandsSettings.Visible";
	
	Query = New Query(QueryText);
	Query.SetParameter("Owner", Owner);
	Selection = Query.Execute().Select();
	
	ListOfDisabledItems = New Map;
	While Selection.Next() Do
		ListOfDisabledItems.Insert(Selection.UUID, True);
	EndDo;
	
	CheckPostingBeforePrint = PrintSettings().CheckPostingBeforePrint;
	
	For Each PrintCommand In PrintCommands Do
		PrintCommand.UUID = PrintCommandUUID(PrintCommand);
		If ListOfDisabledItems[PrintCommand.UUID] <> Undefined Then
			PrintCommand.isDisabled = True;
		EndIf;
		PrintCommand.SaveFormat = String(PrintCommand.SaveFormat);
		
		If PrintCommand.CheckPostingBeforePrint = Undefined Then
			PrintCommand.CheckPostingBeforePrint = CheckPostingBeforePrint;
		EndIf;

	EndDo;
	
EndProcedure

Procedure FixTagCheckingHandlingBeforePrinting(PrintCommands, MetadataObject)
	
	If Metadata.Documents.Contains(MetadataObject) Then
		If MetadataObject.Posting = Metadata.ObjectProperties.Posting.Deny Then
			PrintCommands.FillValues(False, "CheckPostingBeforePrint");
		EndIf;
	EndIf;
	
EndProcedure


Function PrintCommandUUID(PrintCommand)
	
	Parameters = New Array;
	Parameters.Add("Id");
	Parameters.Add("PrintManager");
	Parameters.Add("Handler");
	Parameters.Add("SkipPreview");
	Parameters.Add("SaveFormat");
	Parameters.Add("FixedSet");
	Parameters.Add("AdditionalParameters");
	
	ParametersStructure = New Structure(StrConcat(Parameters, ","));
	FillPropertyValues(ParametersStructure, PrintCommand);
	
	Return Common.CheckSumString(ParametersStructure);
	
EndFunction

Function ObjectPrintCommands(MetadataObject, PrintedForms = True) Export
	PrintCommands = CreatePrintCommandsCollection();
	If TypeOf(MetadataObject) <> Type("MetadataObject") Then 
		Return PrintCommands;
	EndIf;	
	
	Sources = AttachableCommands.CommandsSourcesTree();
	APISettings = AttachableCommands.AttachableObjectsInterfaceSettings();
	AttachedReportsAndDataProcessors = AttachableCommands.AttachableObjectsTable(APISettings);
	Source = AttachableCommands.RegisterSource(MetadataObject, Sources, AttachedReportsAndDataProcessors, APISettings);
	If Source.Manager = Undefined Then
		Return PrintCommands;
	EndIf;
	
	PrintCommandsToAdd = CreatePrintCommandsCollection();
	If ObjectPrintingSettings(Source.Manager).OnAddPrintCommands Then
		Source.Manager.AddPrintCommands(PrintCommandsToAdd);
	EndIf;

	If PrintedForms Then
		AddPrintCommands(PrintCommandsToAdd, MetadataObject);
	EndIf;
	
	For Each PrintCommand In PrintCommandsToAdd Do
		If PrintCommand.PrintManager = Undefined Then
			PrintCommand.PrintManager = Source.FullName;
		EndIf;
		If PrintCommand.Order = 0 Then
			PrintCommand.Order = 50;
		EndIf;
		FillPropertyValues(PrintCommands.Add(), PrintCommand);
	EndDo;
	
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
		ModuleAdditionalReportsAndDataProcessors.OnReceivePrintCommands(PrintCommands, Source.FullName);
	EndIf;
	
	PrintManagementOverridable.OnReceivePrintCommands(Source.FullName, PrintCommands);
	
	PrintCommands.Indexes.Add("PrintManager");
	FoundItems = AttachedReportsAndDataProcessors.FindRows(New Structure("AddPrintCommands", True));
	For Each AttachedObject In FoundItems Do
		AttachedObject.Manager.AddPrintCommands(PrintCommands);
		AddedCommands = PrintCommands.FindRows(New Structure("PrintManager", Undefined));
		For Each Command In AddedCommands Do
			Command.PrintManager = AttachedObject.FullName;
		EndDo;
	EndDo;
	
	ObjectType = Undefined;
	If Common.IsRefTypeObject(MetadataObject) Then
		ObjectType = Type(StrReplace(MetadataObject.FullName(), ".", "Ref."));
	EndIf;
	
	For Each PrintCommand In PrintCommands Do
		PrintCommand.AdditionalParameters.Insert("AddExternalPrintFormsToSet", PrintCommand.AddExternalPrintFormsToSet);
		If ValueIsFilled(ObjectType) And ValueIsFilled(PrintCommand.VisibilityConditions) Then
			PrintCommand.VisibilityConditionsByObjectTypes.Insert(ObjectType, PrintCommand.VisibilityConditions);
		EndIf;
		If PrintCommand.ShouldRunInBackgroundJob = Undefined Then
			PrintCommand.ShouldRunInBackgroundJob = Lower(PrintCommand.PrintManager) = Lower("PrintManagement")
				And Not Common.FileInfobase();
		EndIf;
	EndDo;
	
	PrintCommands.Sort("Order Asc, Presentation Asc");
	FixTagCheckingHandlingBeforePrinting(PrintCommands, MetadataObject);
	SetPrintCommandsSettings(PrintCommands, Source.MetadataRef);
	DefinePrintCommandsVisibilityByFunctionalOptions(PrintCommands);
	
	PrintCommands.Indexes.Add("UUID");
	Return PrintCommands;
EndFunction


// Parameters:
//   SpreadsheetDocument - SpreadsheetDocument
//   PrintObjects - ValueList
//   PrintManager - String
//   Id - String
//
Procedure CheckSpreadsheetDocumentLayoutByPrintObjects(SpreadsheetDocument, PrintObjects, Val PrintManager, Val Id)
	
	If SpreadsheetDocument.TableHeight = 0 Or PrintObjects.Count() = 0 Then
		Return;
	EndIf;
	
	HasLayoutByPrintObjects = False;
	For Each PrintObject In PrintObjects Do
		For Each Area In SpreadsheetDocument.Areas Do
			If Area.Name = PrintObject.Presentation Then
				HasLayoutByPrintObjects = True;
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	If StrFind(Id, ".") > 0 Then
		Position = StrFind(Id, ".", SearchDirection.FromEnd);
		PrintManager = Left(Id, Position - 1);
		Id = Mid(Id, Position + 1);
	EndIf;
	
	LayoutErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
		"en = 'Spreadsheet document %1 has no layout for print objects.
		|When you generate a spreadsheet document, use the
		|%2() procedure';"), 
		Id, "PrintManagement.SetDocumentPrintArea");
	
	CommonClientServer.Validate(HasLayoutByPrintObjects, LayoutErrorText, PrintManager + "." + "Print()");
	
EndProcedure

Function TemplateNameParts(FullTemplateName)
	StringParts1 = StrSplit(FullTemplateName, ".");
	LastItemIndex1 = StringParts1.UBound();
	TemplateName = StringParts1[LastItemIndex1];
	StringParts1.Delete(LastItemIndex1);
	ObjectName = StrConcat(StringParts1, ".");
	
	Result = New Structure;
	Result.Insert("TemplateName", TemplateName);
	Result.Insert("ObjectName", ObjectName);
	
	Return Result;
EndFunction

Function SpreadsheetDocumentPropertiesToCopy() Export
	Return "PrintParametersKey,FitToPage,Output,PageHeight,DuplexPrinting,Protection,PrinterName,LanguageCode,
	|Copies,PrintScale,FirstPageNumber,PageOrientation,TopMargin,LeftMargin,
	|BottomMargin,RightMargin,Collate,HeaderSize,FooterSize,PageSize,
	|PrintAccuracy,BackgroundPicture,BlackAndWhite,PageWidth,PerPage";
EndFunction

Function TemplatesDiffer(Val InitialTemplate, ModifiedTemplate) Export
	Return Common.CheckSumString(NormalizeTemplate(InitialTemplate)) <> Common.CheckSumString(NormalizeTemplate(ModifiedTemplate));
EndFunction

Function NormalizeTemplate(Val Template)
	TemplateStorage = New ValueStorage(Template);
	Return TemplateStorage.Get();
EndFunction

Function AreaTypeSpecifiedIncorrectlyText()
	Return NStr("en = 'Area type is not specified or invalid.';");
EndFunction

// Parameters:
//  PrintObjects - ValueList
//  
//
Function AreasSignaturesAndSeals(PrintObjects) Export
	
	SignaturesAndSeals = ObjectsSignaturesAndSeals(PrintObjects);
	
	AreasSignaturesAndSeals = New Map;
	For Each PrintObject In PrintObjects Do
		ObjectReference = PrintObject.Value;
		SignaturesAndSealsSet = SignaturesAndSeals[ObjectReference];
		AreasSignaturesAndSeals.Insert(PrintObject.Presentation, SignaturesAndSealsSet);
	EndDo;
	
	Return AreasSignaturesAndSeals;
	
EndFunction

Function SpreadsheetDocumentSignaturesAndSeals(PrintObjects, Template, LanguageCode) Export
	
	Fields = New Array;
	
	Texts = New Map;
	For Each Drawing In Template.Drawings Do
		If Drawing.DrawingType <> SpreadsheetDocumentDrawingType.Group Then 
			Texts.Insert(Drawing.DetailsParameter, True);
		EndIf;
	EndDo;
	
	For Each Item In Texts Do
		Text = Item.Key;
		TextParameters = FindParametersInText(Text);
		For Each Expression In TextParameters Do
			Expression = Mid(Expression, 2, StrLen(Expression) - 2);
			FormulaElements = FormulasConstructorInternal.FormulaElements(Expression);
			For Each ItemDetails In FormulaElements.OperandsAndFunctions Do
				IsFunction = ItemDetails.Value;
				If IsFunction Then
					Continue;
				EndIf;
				
				Operand = FormulaElements.AllItems[ItemDetails.Key];
				Operand = ClearSquareBrackets(Operand);
				If ValueIsFilled(Operand) Then
					Fields.Add(Operand);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	Objects = PrintObjects.UnloadValues();
	PrintData = PrintData(Objects, Fields, LanguageCode);

	Result = New Map;
	
	For Each AreaDetails In PrintObjects Do
		Object = AreaDetails.Value;
		AreaName = AreaDetails.Presentation;
	
		Images = New Map;
		For Each Field In Fields Do
			If Images[Field] <> Undefined Then
				Continue;
			EndIf;
			ImageLink = PrintData[Object][Field];
			Picture = PictureFromFile(ImageLink);
			Images.Insert("[" + Field + "]", Picture);
		EndDo;
		
		Result.Insert(AreaName, Images);
	EndDo;
	
	Return Result;
	
EndFunction

Function ObjectsSignaturesAndSeals(Val PrintObjects) Export
	
	ListOfObjects = PrintObjects.UnloadValues();
	SignaturesAndSeals = New Map;
	SSLSubsystemsIntegration.OnGetSignaturesAndSeals(ListOfObjects, SignaturesAndSeals);
	PrintManagementOverridable.OnGetSignaturesAndSeals(ListOfObjects, SignaturesAndSeals);
	
	Return SignaturesAndSeals;
	
EndFunction

Procedure AddSignatureAndSeal(SpreadsheetDocument, AreasSignaturesAndSeals) Export
	
	For Each Drawing In SpreadsheetDocument.Drawings Do
		Position = StrFind(Drawing.Name, "_Document_");
		If Position > 0 Then
			AreaNameObject_ = Mid(Drawing.Name, Position + 1);
			
			SignaturesAndSealsSet = AreasSignaturesAndSeals[AreaNameObject_];
			If SignaturesAndSealsSet = Undefined Then
				Continue;
			EndIf;
			
			If Drawing.DrawingType = SpreadsheetDocumentDrawingType.Group Then 
				Continue;
			EndIf;

			If ValueIsFilled(Drawing.DetailsParameter) Then
				IconName = Drawing.DetailsParameter;
			Else
				IconName = Left(Drawing.Name, Position - 1);
			EndIf;
			
			Picture = Undefined;
			If TypeOf(SignaturesAndSealsSet) = Type("Map")
				Or TypeOf(SignaturesAndSealsSet) = Type("Structure") And SignaturesAndSealsSet.Property(IconName) Then
				Picture = SignaturesAndSealsSet[IconName];
			EndIf;
			
			If Picture <> Undefined Then
				Drawing.Picture = Picture;
			EndIf;
			Drawing.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
		EndIf;
	EndDo;

EndProcedure

Procedure RemoveSignatureAndSeal(SpreadsheetDocument, HideSignaturesAndSeals = False) Export
	
	DrawingsToDelete = New Array;
	For Each Drawing In SpreadsheetDocument.Drawings Do
		If IsSignatureOrSeal(Drawing) Then
			Drawing.Picture = New Picture;
			Drawing.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
			If HideSignaturesAndSeals Then
				DrawingsToDelete.Add(Drawing);
			EndIf;
		EndIf;
	EndDo;
	
	For Each Drawing In DrawingsToDelete Do
		SpreadsheetDocument.Drawings.Delete(Drawing);
	EndDo;
	
EndProcedure

Function IsSignatureOrSeal(Drawing) Export
	
	Return Drawing.DrawingType = SpreadsheetDocumentDrawingType.Picture And StrFind(Drawing.Name, "_Document_") > 0;
	
EndFunction

Function AreaNamesPrefixesWithSignatureAndSeal() Export
	
	Result = New Array;
	Result.Add("Print");
	Result.Add("Signature");
	Result.Add("Facsimile");
	
	Return Result;
	
EndFunction

Function GenerateExternalPrintForm(AdditionalDataProcessorRef, Id, ListOfObjects)
	
	SourceParameters = New Structure;
	SourceParameters.Insert("CommandID", Id);
	SourceParameters.Insert("RelatedObjects", ListOfObjects);
	
	PrintFormsCollection = Undefined;
	PrintObjects = New ValueList;
	OutputParameters = PrepareOutputParametersStructure();
	
	PrintByExternalSource(AdditionalDataProcessorRef, SourceParameters, PrintFormsCollection,
	PrintObjects, OutputParameters);
	
	Result = New Structure;
	Result.Insert("PrintFormsCollection", PrintFormsCollection);
	Result.Insert("PrintObjects", PrintObjects);
	Result.Insert("OutputParameters", OutputParameters);
	
	Return Result;
	
EndFunction

Procedure InsertPicturesToHTML(HTMLFileName) Export
	
	TextDocument = New TextDocument();
	TextDocument.Read(HTMLFileName, TextEncoding.UTF8);
	HTMLText = TextDocument.GetText();
	
	HTMLFile = New File(HTMLFileName);
	
	PicturesDirectoryName = HTMLFile.BaseName + "_files";
	PicturesDirectoryPath = StrReplace(HTMLFile.FullName, HTMLFile.Name, PicturesDirectoryName);
	
	// 
	PicturesFiles = FindFiles(PicturesDirectoryPath, "*");
	
	For Each PicturesFile In PicturesFiles Do
		PictureInText = Base64String(New BinaryData(PicturesFile.FullName));
		PictureInText = "data:image/" + Mid(PicturesFile.Extension,2) + ";base64," + Chars.LF + PictureInText;
		
		HTMLText = StrReplace(HTMLText, PicturesDirectoryName + "\" + PicturesFile.Name, PictureInText);
	EndDo;
		
	TextDocument.SetText(HTMLText);
	TextDocument.Write(HTMLFileName, TextEncoding.UTF8);
	
EndProcedure

Function FileName(PathToFile)
	File = New File(PathToFile);
	Return File.Name;
EndFunction

Function PackToArchive(ListOfFiles)
	
	If ListOfFiles.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	MemoryStream = New MemoryStream;
	ZipFileWriter = New ZipFileWriter(MemoryStream);
	
	TempDirectoryName = FileSystem.CreateTemporaryDirectory();
	CreateDirectory(TempDirectoryName);
	
	For Each File In ListOfFiles Do
		FileName = TempDirectoryName + File.FileName;
		FileName = FileSystem.UniqueFileName(FileName);
		File.BinaryData.Write(FileName);
		ZipFileWriter.Add(FileName);
	EndDo;
	
	ZipFileWriter.Write();
	MemoryStream.Seek(0, PositionInStream.Begin);
	
	DataReader = New DataReader(MemoryStream);
	ReadDataResult = DataReader.Read();
	BinaryData = ReadDataResult.GetBinaryData();
	
	DataReader.Close();
	MemoryStream.Close();
	
	FileSystem.DeleteTemporaryDirectory(TempDirectoryName);
	
	Return BinaryData;
	
EndFunction

// Parameters:
//   SpreadsheetDocument - SpreadsheetDocument
//   Format - SpreadsheetDocumentFileType
// Returns:
//   BinaryData
//
Function SpreadsheetDocumentToBinaryData(SpreadsheetDocument, Format)
	
	TempFileName = GetTempFileName();
	SpreadsheetDocument.Write(TempFileName, Format);
	
	If Format = SpreadsheetDocumentFileType.HTML Then
		InsertPicturesToHTML(TempFileName);
	EndIf;
	
	BinaryData = New BinaryData(TempFileName);
	DeleteFiles(TempFileName);
	
	Return BinaryData;
	
EndFunction

Function PrintFormsByObjects(PrintForm, PrintObjects) Export
	
	If PrintObjects.Count() = 0 Then
		Return New Structure("PrintObjectsNotSpecified", PrintForm);
	EndIf;
	
	Result = New Map;
	
	For Each PrintObject In PrintObjects Do
		AreaName = PrintObject.Presentation;
		Area = PrintForm.Areas.Find(AreaName);
		If Area = Undefined Then
			Continue;
		EndIf;
		
		If PrintObjects.Count() = 1 Then
			SpreadsheetDocument = PrintForm;
		Else
			SpreadsheetDocument = PrintForm.GetArea(Area.Top, , Area.Bottom);
			LastRow = SpreadsheetDocument.Area(SpreadsheetDocument.TableHeight, , SpreadsheetDocument.TableHeight, );
			LastRow.PageBottom = False;
			FillPropertyValues(SpreadsheetDocument, PrintForm, SpreadsheetDocumentPropertiesToCopy());
		EndIf;
		
		Result.Insert(PrintObject.Value, SpreadsheetDocument);
	EndDo;
	
	Return Result;
	
EndFunction

Function ObjectPrintFormFileName(PrintObject, PrintFormFileName, PrintFormName) Export
	
	If PrintObject = Undefined Or PrintObject = "PrintObjectsNotSpecified" Then
		If ValueIsFilled(PrintFormName) Then
			Return PrintFormName;
		EndIf;
		Return NStr("en = 'Document';");
	EndIf;
	
	If TypeOf(PrintFormFileName) = Type("Map") Then
		Return String(PrintFormFileName[PrintObject]);
	ElsIf TypeOf(PrintFormFileName) = Type("String") And Not IsBlankString(PrintFormFileName) Then
		Return PrintFormFileName;
	EndIf;
	
	Return DefaultPrintFormFileName(PrintObject, PrintFormName);
	
EndFunction

Function DefaultPrintFormFileName(PrintObject, PrintFormName)
	
	IsDocument = Common.IsDocument(Metadata.FindByType(TypeOf(PrintObject)));
	
	If IsDocument Then
		
		DocumentContainsNumber = PrintObject.Metadata().NumberLength > 0;
		
		If DocumentContainsNumber Then
			AttributesList = "Date,Number";
			Template = NStr("en = '[PrintFormName] #[Number] dated [Date]';");
		Else
			AttributesList = "Date";
			Template = NStr("en = '[PrintFormName] dated [Date]';");
		EndIf;
		
		ParametersToInsert = Common.ObjectAttributesValues(PrintObject, AttributesList);
		If Common.SubsystemExists("StandardSubsystems.ObjectsPrefixes") And DocumentContainsNumber Then
			ModuleObjectsPrefixesClientServer = Common.CommonModule("ObjectsPrefixesClientServer");
			ParametersToInsert.Number = ModuleObjectsPrefixesClientServer.NumberForPrinting(ParametersToInsert.Number);
		EndIf;
		ParametersToInsert.Date = Format(ParametersToInsert.Date, "DLF=D");
		ParametersToInsert.Insert("PrintFormName", PrintFormName);
		
	Else
		
		ParametersToInsert = New Structure;
		ParametersToInsert.Insert("PrintFormName",PrintFormName);
		ParametersToInsert.Insert("ObjectPresentation", Common.SubjectString(PrintObject));
		ParametersToInsert.Insert("CurrentDate",Format(CurrentSessionDate(), "DLF=D"));
		Template = NStr("en = '[PrintFormName] - [ObjectPresentation] - [CurrentDate]';");
		
	EndIf;
	
	Result = StringFunctionsClientServer.InsertParametersIntoString(Template, ParametersToInsert);
	
	If Common.IsLinuxServer() And StrLen(Result) > 120 Then
		If IsDocument Then
			AbbreviatedField = "PrintFormName";
		Else
			AbbreviatedField = "ObjectPresentation";
		EndIf;
		ParametersToInsert[AbbreviatedField] = Left(ParametersToInsert[AbbreviatedField],
			StrLen(ParametersToInsert[AbbreviatedField]) - (StrLen(Result) - 117)) + "...";
		Result = StringFunctionsClientServer.InsertParametersIntoString(Template, ParametersToInsert);
	EndIf;
	
	Return Result;
	
EndFunction

Function OfficeDocumentFileName(Val FileName, Val Transliterate1 = False) Export
	
	FileName = CommonClientServer.ReplaceProhibitedCharsInFileName(FileName);
	
	ExtensionsToExpect = New Map;
	ExtensionsToExpect.Insert(".docx", True);
	ExtensionsToExpect.Insert(".doc", True);
	ExtensionsToExpect.Insert(".odt", True);
	ExtensionsToExpect.Insert(".html", True);
	
	File = New File(FileName);
	If ExtensionsToExpect[File.Extension] = Undefined Then
		FileName = FileName + ".docx";
	EndIf;
	
	If Transliterate1 Then
		FileName = StringFunctions.LatinString(FileName)
	EndIf;
	
	Return FileName;
	
EndFunction

// List of possible layout names:
//  1) in the session language,
//  2) in the configuration language,
//  3) without specifying the language.
//
Function TemplateNames(Val TemplateName, Val LanguageCode = Undefined)
	
	Result = New Array;
	
	If ValueIsFilled(LanguageCode) Then
		Result.Add(TemplateName + "_" + LanguageCode);
		StringParts1 = StrSplit(LanguageCode, "_", False);
		If StringParts1.Count() > 1 Then
			Result.Add(TemplateName + "_" + StringParts1[0]);
		EndIf;
	EndIf;
	
	Result.Add(TemplateName + "_" + Common.DefaultLanguageCode());
	Result.Add(TemplateName);
	
	Return Result;
	
EndFunction

// Constructor for the PrintForm Collection parameter of the Print procedure.
//
// Returns:
//  ValueTable - :
//   * TemplateName - String -  ID of the printed form;
//   * UpperCaseName - String -  ID in uppercase characters for quick search;
//   * TemplateSynonym - String -  presentation of the printed form;
//   * SpreadsheetDocument - SpreadsheetDocument -  printed form;
//   * Copies2 - Number -  number of copies to print;
//   * Picture - Picture -  (not use);
//   * FullTemplatePath - String -  used to quickly switch to editing the layout of a printed form;
//   * PrintFormFileName - String -  file name;
//                           - Map of KeyAndValue - :
//                              ** Key - AnyRef -  link to the print object;
//                              ** Value - String -  file name;
//   * OfficeDocuments - Map of KeyAndValue - :
//                         ** Key - String -  address in the temporary storage of binary data of the printed form;
//                         ** Value - String -  name of the print form file.
//
Function PreparePrintFormsCollection(Val IDs) Export
	
	Result = New ValueTable;
	For Each ColumnName In PrintManagementClientServer.PrintFormsCollectionFieldsNames() Do
		Result.Columns.Add(ColumnName);
	EndDo;
	
	If TypeOf(IDs) = Type("String") Then
		IDs = StrSplit(IDs, ",");
	EndIf;
	
	For Each Id In IDs Do
		PrintForm = Result.Find(Id, "TemplateName");
		If PrintForm = Undefined Then
			PrintForm = Result.Add();
			PrintForm.TemplateName = Id;
			PrintForm.UpperCaseName = Upper(Id);
			PrintForm.Copies2 = 1;
		Else
			PrintForm.Copies2 = PrintForm.Copies2 + 1;
		EndIf;
	EndDo;
	
	Result.Indexes.Add("UpperCaseName");
	Return Result;
	
EndFunction

// Prepare the structure of output parameters for the Manager of the object that forms printed forms.
//
// Returns:
//  Structure:
//   * SendOptions - Structure:
//     ** Recipient - 
//     ** Subject - String
//     ** Text - String
//   * LanguageCode - String
//   * PrintingBySetsIsAvailable - Boolean
//   * FormCaption - String
//
Function PrepareOutputParametersStructure() Export
	
	OutputParameters = New Structure;
	OutputParameters.Insert("FormCaption", "");
	OutputParameters.Insert("PrintingBySetsIsAvailable", False); // 
	OutputParameters.Insert("LanguageCode", Common.DefaultLanguageCode());
	
	EmailParametersStructure = New Structure("Recipient,Subject,Text", Undefined, "", "");
	OutputParameters.Insert("SendOptions", EmailParametersStructure);
	
	Return OutputParameters;
	
EndFunction

// Parameters:
//  PrintCommand - ValueTableRow of See CreatePrintCommandsCollection
//  SettingsForSaving - See PrintManagement.SettingsForSaving
//  ListOfObjects - Array
//  Result - ValueTable:
//   * FileName - String
//   * BinaryData - BinaryData
//
Procedure ExecutePrintToFileCommand(PrintCommand, SettingsForSaving, ListOfObjects, Result)
	
	If Not ValueIsFilled(SettingsForSaving.SaveFormats) Then
		SettingsForSaving.SaveFormats.Add(StandardSubsystemsServer.TableDocumentFileTypePDF());
	EndIf;
	
	PrintData = Undefined;
	If PrintCommand.PrintManager = "StandardSubsystems.AdditionalReportsAndDataProcessors" Then
		Source = PrintCommand.AdditionalParameters.Ref;
		PrintData = GenerateExternalPrintForm(Source, PrintCommand.Id, ListOfObjects);
	Else
		PrintData = GeneratePrintForms(PrintCommand.PrintManager, PrintCommand.Id,
		ListOfObjects, PrintCommand.AdditionalParameters);
	EndIf;
	
	PrintFormsCollection = PrintData.PrintFormsCollection;
	PrintObjects = PrintData.PrintObjects;
	
	AreasSignaturesAndSeals = Undefined;
	If SettingsForSaving.SignatureAndSeal Then
		AreasSignaturesAndSeals = AreasSignaturesAndSeals(PrintObjects);
	EndIf;
	
	FormatsTable = SpreadsheetDocumentSaveFormatsSettings();
	
	For Each PrintForm In PrintFormsCollection Do
		If ValueIsFilled(PrintForm.OfficeDocuments) Then
			For Each OfficeDocument In PrintForm.OfficeDocuments Do
				File = Result.Add();
				File.FileName = OfficeDocumentFileName(OfficeDocument.Value, SettingsForSaving.TransliterateFilesNames);
				File.BinaryData = GetFromTempStorage(OfficeDocument.Key);
			EndDo;
			Continue;
		EndIf;
		
		If SettingsForSaving.SignatureAndSeal Then
			AddSignatureAndSeal(PrintForm.SpreadsheetDocument, AreasSignaturesAndSeals);
		Else
			RemoveSignatureAndSeal(PrintForm.SpreadsheetDocument);
		EndIf;
		
		PrintFormsByObjects = PrintFormsByObjects(PrintForm.SpreadsheetDocument, PrintObjects);
		For Each MapBetweenObjectAndPrintForm In PrintFormsByObjects Do
			
			PrintObject = MapBetweenObjectAndPrintForm.Key;
			SpreadsheetDocument = MapBetweenObjectAndPrintForm.Value;
			
			If SpreadsheetDocument.TableHeight = 0 Then
				Continue;
			EndIf;
			
			For Each Format In SettingsForSaving.SaveFormats Do
				FileType = Format;
				If TypeOf(FileType) = Type("String") Then
					FileType = SpreadsheetDocumentFileType[FileType];
				EndIf;
				FileType = TheTypeOfTheFileTableOfTheDocument(FileType);
				
				FormatSettings = FormatsTable.FindRows(New Structure("SpreadsheetDocumentFileType", FileType))[0];
				
				FileExtention = FormatSettings.Extension;
				SpecifiedPrintFormsNames = PrintForm.PrintFormFileName;
				PrintFormName = PrintForm.TemplateSynonym;
				
				FileName = ObjectPrintFormFileName(PrintObject, SpecifiedPrintFormsNames, PrintFormName) + "." + FileExtention;
				If SettingsForSaving.TransliterateFilesNames Then
					FileName = StringFunctions.LatinString(FileName)
				EndIf;
				FileName = CommonClientServer.ReplaceProhibitedCharsInFileName(FileName);
				
				File = Result.Add();
				File.FileName = FileName;
				File.BinaryData = SpreadsheetDocumentToBinaryData(SpreadsheetDocument, FileType);
			EndDo;
		EndDo;
	EndDo;

EndProcedure

Function TheTypeOfTheFileTableOfTheDocument(FileType)
	
	If FileType = SpreadsheetDocumentFileType.PDF
		Or String(FileType) = "PDF_A_1"
		Or String(FileType) = "PDF_A_2"
		Or String(FileType) = "PDF_A_3" Then
		Return StandardSubsystemsServer.TableDocumentFileTypePDF();
	EndIf;
	
	ReplaceableTypes = New Map;
	ReplaceableTypes.Insert(SpreadsheetDocumentFileType.HTML, SpreadsheetDocumentFileType.HTML5);
	ReplaceableTypes.Insert(SpreadsheetDocumentFileType.HTML3, SpreadsheetDocumentFileType.HTML5);
	ReplaceableTypes.Insert(SpreadsheetDocumentFileType.HTML4, SpreadsheetDocumentFileType.HTML5);
	ReplaceableTypes.Insert(SpreadsheetDocumentFileType.MXL7, SpreadsheetDocumentFileType.MXL);
	ReplaceableTypes.Insert(SpreadsheetDocumentFileType.XLS95, SpreadsheetDocumentFileType.XLS);
	ReplaceableTypes.Insert(SpreadsheetDocumentFileType.XLS97, SpreadsheetDocumentFileType.XLS);
	
	Result = ReplaceableTypes[FileType];
	If Result = Undefined Then
		Result = FileType;
	EndIf;
	
	Return Result;
	
EndFunction

Function PrintFormTemplates(AreDataProcessorsAndReportsOnly = False) Export
	
	Result = New Map;
	
	MetadataObjectsCollections = New Array; // Array of MetadataObjectCollection -
	MetadataObjectsCollections.Add(Metadata.DataProcessors);
	MetadataObjectsCollections.Add(Metadata.Reports);
	If Not AreDataProcessorsAndReportsOnly Then
		MetadataObjectsCollections.Add(Metadata.Catalogs);
		MetadataObjectsCollections.Add(Metadata.Documents);
		MetadataObjectsCollections.Add(Metadata.BusinessProcesses);
		MetadataObjectsCollections.Add(Metadata.Tasks);
		MetadataObjectsCollections.Add(Metadata.DocumentJournals);
	EndIf;
	
	For Each MetadataObjectCollection In MetadataObjectsCollections Do
		For Each CollectionMetadataObject In MetadataObjectCollection Do
			MetadataObject = CollectionMetadataObject; // MetadataObjectDocument - 
			For Each Template In MetadataObject.Templates Do
				If StrFind(Template.Name, "PF_") > 0 Then
					If (MetadataObjectCollection = Metadata.DataProcessors Or MetadataObjectCollection = Metadata.Reports)
						And Not AccessRight("View", MetadataObject) Then
						Continue;
					EndIf;
					Result.Insert(Template, MetadataObject);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	For Each Template In Metadata.CommonTemplates Do
		If StrFind(Template.Name, "PF_") > 0 Then
			Result.Insert(Template, Metadata.CommonTemplates);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns:
//  SpreadsheetDocument, BinaryData - 
//
Function FindTemplate(TemplatePath, LanguageCode, SuppliedOnly = False)
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Template ""%1"" does not exist. The operation is canceled.';"), TemplatePath);
	PathParts = StrSplit(TemplatePath, ".", True);
	
	FoundTemplate = Catalogs.PrintFormTemplates.FindTemplate(TemplatePath, LanguageCode);
	If FoundTemplate <> Undefined Then
		Return FoundTemplate;
	EndIf;

	If PathParts.Count() <> 2 And PathParts.Count() <> 3 Then
		Raise ErrorText;
	EndIf;
	
	TemplateName = PathParts[PathParts.UBound()];
	PathParts.Delete(PathParts.UBound());
	ObjectName = StrConcat(PathParts, ".");
	
	TemplatesList = New Map;
	
	If Not SuppliedOnly Then
		QueryText = 
		"SELECT
		|	UserPrintTemplates.Template AS Template,
		|	UserPrintTemplates.TemplateName AS TemplateName
		|FROM
		|	InformationRegister.UserPrintTemplates AS UserPrintTemplates
		|WHERE
		|	UserPrintTemplates.Object = &Object
		|	AND UserPrintTemplates.TemplateName LIKE &TemplateName
		|	AND UserPrintTemplates.Use";
		
		Query = New Query(QueryText);
		Query.Parameters.Insert("Object", ObjectName);
		Query.Parameters.Insert("TemplateName", TemplateName + "%");
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			TemplatesList.Insert(Selection.TemplateName, Selection.Template.Get());
		EndDo;
	EndIf;
	
	SearchNames = TemplateNames(TemplateName, LanguageCode);
	
	For Each SearchName In SearchNames Do
		FoundTemplate = TemplatesList[SearchName];
		If FoundTemplate <> Undefined Then
			SetTheLayoutLanguage(FoundTemplate, LanguageCode);
			Return FoundTemplate;
		EndIf;
	EndDo;
	
	IsCommonTemplate = StrSplit(ObjectName, ".").Count() = 1;
	
	TemplatesCollection = Metadata.CommonTemplates;
	If Not IsCommonTemplate Then
		MetadataObject = Common.MetadataObjectByFullName(ObjectName);
		If MetadataObject = Undefined Then
			Raise ErrorText;
		EndIf;
		TemplatesCollection = MetadataObject.Templates;
	EndIf;
	
	For Each SearchName In SearchNames Do
		If TemplatesCollection.Find(SearchName) <> Undefined Then
			If IsCommonTemplate Then
				Template = GetCommonTemplate(SearchName);
			Else
				SetSafeModeDisabled(True);
				SetPrivilegedMode(True);
				Template = Common.ObjectManagerByFullName(ObjectName).GetTemplate(SearchName);
			EndIf;
			SetTheLayoutLanguage(Template, LanguageCode);
			Return Template;
		EndIf;
	EndDo;
	
	Raise ErrorText;
	
EndFunction

Procedure SetTheLayoutLanguage(Template, LanguageCode)
	
	If TypeOf(Template) <> Type("SpreadsheetDocument") Then
		Return;
	EndIf;
	
	ItIsAnAdditionalLanguageOfPrintedForms = False;
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		ItIsAnAdditionalLanguageOfPrintedForms = PrintManagementModuleNationalLanguageSupport.ItIsAnAdditionalLanguageOfPrintedForms(LanguageCode);
	EndIf;
	
	If ValueIsFilled(LanguageCode) And Not ItIsAnAdditionalLanguageOfPrintedForms Then
		Template.LanguageCode = LanguageCode;
	Else
		Template.LanguageCode = Common.DefaultLanguageCode();
	EndIf;
	
EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters)
	
	LanguageCode = OutputParameters.LanguageCode;
	
	ObjectManager = Common.ObjectManagerByRef(ObjectsArray[0]);	
	If ObjectPrintingSettings(ObjectManager).OnSpecifyingRecipients Then
		ObjectManager.OnSpecifyingRecipients(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	EndIf;
		
	For Each PrintForm In PrintFormsCollection Do
		PrintForm.OutputInOtherLanguagesAvailable = True;
		PrintForm.FullTemplatePath = PrintForm.TemplateName;
		PrintForm.TemplateSynonym = TemplatePresentation(PrintForm.FullTemplatePath, LanguageCode);
		//  
		// 
		Template = PrintFormTemplate(PrintForm.FullTemplatePath, LanguageCode); 
		
		If TypeOf(Template) = Type("BinaryData") Then
			PrintForm.OfficeDocuments = GenerateOfficeDoc(Template, ObjectsArray, PrintObjects, LanguageCode, PrintParameters);
		Else			
			SpreadsheetDocument = GenerateSpreadsheetDocument(Template, ObjectsArray, PrintObjects, LanguageCode); // SpreadsheetDocument
			SpreadsheetDocument.PrintParametersKey = PrintForm.FullTemplatePath + ?(ValueIsFilled(LanguageCode), "." + LanguageCode, "");
			PrintForm.SpreadsheetDocument = SpreadsheetDocument;
		EndIf;
	EndDo;
	
EndProcedure

Function ReplaceParametersWithValues(Val String, DataSource, FieldFormatSettings, LanguageCode)
	
	TextParameters = FindParametersInText(String(String));
	ParameterValues = ParameterValues(TextParameters, DataSource, FieldFormatSettings, LanguageCode);
	
	If TypeOf(String) = Type("FormattedString") Then
		Result = ReplaceInFormattedString(String, ParameterValues);
	Else
		Result = ReplaceInline(String, ParameterValues);
	EndIf;
	
	Return Result;
	
EndFunction

Function ReplaceInline(Val String, ReplacementParameters)
	
	For Each Item In ReplacementParameters Do
		SearchSubstring = Item.Key;
		ReplaceSubstring = Item.Value;
		String = StrReplace(String, SearchSubstring, ReplaceSubstring);
	EndDo;
	
	Return String;
	
EndFunction

Function ReplaceInFormattedString(String, ReplacementParameters)

	FormattedDocument = New FormattedDocument;
	FormattedDocument.SetFormattedString(String);
	
	For Each Item In ReplacementParameters Do
		SearchSubstring = Item.Key;
		ReplaceSubstring = Item.Value;

		FoundArea = FormattedDocument.FindText(SearchSubstring);
		While FoundArea <> Undefined Do
			Particles = FormattedDocument.GenerateItems(FoundArea.BeginBookmark, FoundArea.EndBookmark);
			For IndexOf = 1 To Particles.UBound() Do
				Particles[0].Text = Particles[0].Text + Particles[IndexOf].Text;
				Particles[IndexOf].Text = "";
			EndDo;
			Particles[0].Text = StrReplace(Particles[0].Text, SearchSubstring, ReplaceSubstring);
	
			FoundArea = FormattedDocument.FindText(SearchSubstring, FoundArea.EndBookmark);
		EndDo;
	EndDo;
	
	Return FormattedDocument.GetFormattedString();

EndFunction

Procedure FillDataPrint(PrintData, FieldsDetails, FieldHierarchy, Objects, LanguageCode)
	
	If PrintData["ObjectTablePartNames"] = Undefined Then
		PrintData["ObjectTablePartNames"] = New Array;
	EndIf;

	If PrintData["FieldFormatSettings"] = Undefined Then
		PrintData["FieldFormatSettings"] = New Map;
	EndIf;

	For Each FieldsCollection In FieldHierarchy Do
		SubordinateFields = FieldsCollection.Value;
		If Not ValueIsFilled(SubordinateFields) Then
			Continue;
		EndIf;
		
		FieldSource = FieldsCollection.Key;
		PathToDataOfTablePart = "";
		PathToFieldSourceData = FieldSource;
		SourceOwnerDataPath = PathToFieldOwnerSData(PathToFieldSourceData, FieldsDetails);
		
		SourceOfFieldsInTablePart = ThisTableSectionField(PathToFieldSourceData, PrintData);
		If SourceOfFieldsInTablePart Then
			PathToDataOfTablePart = PathToDataOfTablePart(PathToFieldSourceData, PrintData);
			PathToFieldSourceData = PathToFieldDataInTablePart(PathToFieldSourceData, PrintData);
		EndIf;
		
		OwnerOfSourceInTablePart = ThisTableSectionField(SourceOwnerDataPath, PrintData);
		If SourceOfFieldsInTablePart And OwnerOfSourceInTablePart Then
			SourceOwnerDataPath = PathToFieldDataInTablePart(SourceOwnerDataPath, PrintData);
		EndIf;
		
		Fields = New Map;
		DataCompositionSchemas = New Map;
		
		For Each Field In SubordinateFields Do
			FieldDetails = FieldsDetails.FindRows(New Structure("Field", Field.Key))[0];
			DataCompositionSchema = FieldDetails.DataCompositionSchema;
			DataCompositionSchemas.Insert(DataCompositionSchema, FieldDetails.DataCompositionSchemaId);
			If Fields[DataCompositionSchema] = Undefined Then
				Fields[DataCompositionSchema] = New Array;
			EndIf;
			DataCompositionSchemaFields = Fields[DataCompositionSchema]; // Array
			DataCompositionSchemaFields.Add(FieldDetails.DataPath);
			
			If ValueIsFilled(FieldDetails.Format) Then
				PrintData["FieldFormatSettings"][FieldDetails.Field] = FieldDetails.Format;
			EndIf;
		EndDo;
		
		DataSourceDescriptions = New ValueTable;
		DataSourceDescriptions.Columns.Add("Owner");
		DataSourceDescriptions.Columns.Add("Name");
		DataSourceDescriptions.Columns.Add("Value");
		
		For Each Object In Objects Do
			If SourceOfFieldsInTablePart Then
				If ThisTableSectionField(PathToDataOfTablePart, PrintData) Then
					Continue;
				EndIf;
				For LineNumber = 1 To PrintData[Object][PathToDataOfTablePart].Count() Do
					FieldSourceValue = PrintData[Object][PathToDataOfTablePart][LineNumber][PathToFieldSourceData];
					If ValueIsFilled(FieldSourceValue) Then
						SourceDetails = DataSourceDescriptions.Add();
						If OwnerOfSourceInTablePart Then
							SourceDetails.Owner = PrintData[Object][PathToDataOfTablePart][LineNumber][SourceOwnerDataPath];
						Else
							If ValueIsFilled(SourceOwnerDataPath) Then
								SourceDetails.Owner = PrintData[Object][SourceOwnerDataPath];
							ElsIf PathToFieldSourceData <> "Ref" Then
								SourceDetails.Owner = Object;
							EndIf;
						EndIf;
						SourceDetails.Name = FieldName(PathToFieldSourceData);
						SourceDetails.Value = FieldSourceValue;
					Else
						For Each Field In SubordinateFields Do
							PrintData[Object][PathToDataOfTablePart][LineNumber][PathToFieldDataInTablePart(Field.Key, PrintData)] = Undefined;
						EndDo;
					EndIf;
				EndDo;
			Else
				If FieldSource = "Ref" Then
					FieldSourceValue = Object;
				Else
					FieldSourceValue = PrintData[Object][PathToFieldSourceData];
				EndIf;
				If ValueIsFilled(FieldSourceValue) Then
					SourceDetails = DataSourceDescriptions.Add();
					If ValueIsFilled(SourceOwnerDataPath) Then
						SourceDetails.Owner = PrintData[Object][SourceOwnerDataPath];
					ElsIf PathToFieldSourceData <> "Ref" Then
						SourceDetails.Owner = Object;
					EndIf;
					SourceDetails.Name = FieldName(PathToFieldSourceData);
					SourceDetails.Value = FieldSourceValue;
				Else
					For Each Field In SubordinateFields Do
						PrintData[Object][Field.Key] = Undefined;
					EndDo;
				EndIf;
			EndIf;
		EndDo;
		
		For Each Item In Fields Do
			DataCompositionSchemaId = DataCompositionSchemas[Item.Key];
			DataCompositionSchema = GetFromTempStorage(Item.Key);
			SchemaFields = Item.Value;
			
			SourceDataGroupedByDataSourceOwner = False;
			DataSources = DataSourceDescriptions.UnloadColumn("Value");
			
			For IndexOf = 0 To DataSources.UBound() Do
				If DataSources[IndexOf] = Undefined Then
					DataSources[IndexOf] = "";
				EndIf;
			EndDo;
			
			DataSources = CommonClientServer.CollapseArray(DataSources);
			
			For Each RefsByType In RefsByTypes(DataSources) Do
				SourcesType = RefsByType.Key;
				DataSources = RefsByType.Value;
				
				IsSourceTypeCheckEnabled = False;
				StringParts1 = StrSplit(DataCompositionSchemaId, ".");
				If StringParts1.Count() > 1 Then
					MetadataObjectName = StringParts1[0] + "." +  StringParts1[1];
					MetadataObject = Common.MetadataObjectByFullName(MetadataObjectName);
					IsSourceTypeCheckEnabled = MetadataObject <> Undefined;
				EndIf;
				
				SourceTypeName = "";
				If IsSourceTypeCheckEnabled Then
					MetadataObject = Metadata.FindByType(SourcesType);
					SourceTypeName = MetadataObject.FullName();
				EndIf;
				
				If IsSourceTypeCheckEnabled And ValueIsFilled(SourceTypeName)
					And Not StrStartsWith(DataCompositionSchemaId, SourceTypeName + ".")
					And DataCompositionSchemaId <> SourceTypeName Then
					Continue;
				EndIf;
			
				Parameters = CollectionParametersGettingDataSources();
				Parameters.DataSources = DataSources;
				Parameters.SchemaFields = SchemaFields;
				Parameters.LanguageCode = LanguageCode;
				Parameters.DataCompositionSchema = DataCompositionSchema;
				Parameters.DataCompositionSchemaId = DataCompositionSchemaId;
				Parameters.DataSourceDescriptions = DataSourceDescriptions;
				Parameters.SourceDataGroupedByDataSourceOwner = SourceDataGroupedByDataSourceOwner;
				
				SourceData_ = SourceData_(Parameters);
				
				SourceDataGroupedByDataSourceOwner = Parameters.SourceDataGroupedByDataSourceOwner;
				
				If SourceData_["ObjectTablePartNames"] <> Undefined Then
					For Each TabularSectionName In SourceData_["ObjectTablePartNames"] Do
						If FieldSource = "Ref" Then
							PrintData["ObjectTablePartNames"].Add(TabularSectionName);
						Else
							PrintData["ObjectTablePartNames"].Add(FieldSource + "." + TabularSectionName);
						EndIf;
					EndDo;
				EndIf;
				
				For Each Object In Objects Do
					If SourceOfFieldsInTablePart Then
						If ThisTableSectionField(PathToDataOfTablePart, PrintData) Then
							Continue;
						EndIf;
						For LineNumber = 1 To PrintData[Object][PathToDataOfTablePart].Count() Do
							If SourceDataGroupedByDataSourceOwner Then
								If OwnerOfSourceInTablePart Then
									DataSource = PrintData[Object][PathToDataOfTablePart][LineNumber][SourceOwnerDataPath];
								Else
									If ValueIsFilled(SourceOwnerDataPath) Then
										DataSource = PrintData[Object][SourceOwnerDataPath];
									Else
										DataSource = Object;
									EndIf;
								EndIf;
							Else
								DataSource = PrintData[Object][PathToDataOfTablePart][LineNumber][PathToFieldSourceData];
							EndIf;
							If DataSource = Undefined Then
								DataSource = "";
							EndIf;
							
							If SourceData_[DataSource] <> Undefined Then
								For Each FieldData In SourceData_[DataSource] Do
									Field = FieldData.Key;
									Simple = FieldData.Value;
									PrintData[Object][PathToDataOfTablePart][LineNumber][PathToFieldSourceData + "." + Field] = Simple;
								EndDo;
							EndIf;
						EndDo;
					Else
						If SourceDataGroupedByDataSourceOwner Then
							If ValueIsFilled(SourceOwnerDataPath) Then
								DataSource = PrintData[Object][SourceOwnerDataPath];
							Else
								DataSource = Object;
							EndIf;
						ElsIf FieldSource = "Ref" Then
							DataSource = Object;
						Else
							DataSource = PrintData[Object][PathToFieldSourceData];
						EndIf;
						
						If DataSource = Undefined Then
							DataSource = "";
						EndIf;
						
						If SourceData_[DataSource] <> Undefined Then
							For Each FieldData In  SourceData_[DataSource] Do
								Field = FieldData.Key;
								Simple = FieldData.Value;
								
								If FieldSource = "Ref" Then
									FieldDataPath = Field;
								Else
									FieldDataPath = PathToFieldSourceData + "." + Field;
								EndIf;
								
								If PrintData[Object][FieldDataPath] = Undefined Then
									PrintData[Object][FieldDataPath] = Simple;
								ElsIf TypeOf(PrintData[Object][FieldDataPath]) = Type("Map") And TypeOf(Simple) = Type("Map") Then
									For Each SourceRow In Simple Do
										DestinationRow = PrintData[Object][FieldDataPath][SourceRow.Key];
										If DestinationRow = Undefined Then
											DestinationRow = New Map;
											PrintData[Object][FieldDataPath][SourceRow.Key] = DestinationRow;
										EndIf;
										For Each FieldOfRow In SourceRow.Value Do
											DestinationRow[FieldOfRow.Key] = FieldOfRow.Value;
										EndDo;
									EndDo;
								EndIf;
							EndDo;
						EndIf;
					EndIf;
				EndDo;
			
			EndDo;
		EndDo;
		FillDataPrint(PrintData, FieldsDetails, SubordinateFields, Objects, LanguageCode)
	EndDo;
	
EndProcedure

Function RefsByTypes(References)
	
	RefsByTypes = New Map;
	
	For Each Ref In References Do
		If TypeOf(Ref) = Undefined Then
			Continue;
		EndIf;
		
		Type = TypeOf(Ref);
		
		If RefsByTypes[Type] = Undefined Then
			RefsByTypes[Type] = New Array;
		EndIf;
		
		RefsByTypes[Type].Add(Ref);
	EndDo;
	
	Return RefsByTypes;
	
EndFunction

Function PathToFieldOwnerSData(FieldDataPath, FieldsDetails)
	
	PathToFieldOwnerSData = PathToParentSData(FieldDataPath);
	While ValueIsFilled(PathToFieldOwnerSData) Do
		FieldDetails = FieldsDetails.FindRows(New Structure("Field", PathToFieldOwnerSData))[0];
		If Not FieldDetails.Folder And Not FieldDetails.Table Then
			Return PathToFieldOwnerSData;
		EndIf;
		PathToFieldOwnerSData = PathToParentSData(PathToFieldOwnerSData);
	EndDo;
	
	Return PathToFieldOwnerSData;
	
EndFunction

Function PathToFieldDataInTablePart(FieldDataPath, PrintData)
	
	PathToDataOfTablePart = PathToDataOfTablePart(FieldDataPath, PrintData);
	
	If ValueIsFilled(PathToDataOfTablePart) Then
		Return Mid(FieldDataPath, StrLen(PathToDataOfTablePart) + 2);
	EndIf;
	
	Return FieldDataPath;
	
EndFunction

Function PathToDataOfTablePart(FieldDataPath, PrintData)
	
	PathToParentSData = PathToParentSData(FieldDataPath);
	
	While ValueIsFilled(PathToParentSData) Do
		If PrintData["ObjectTablePartNames"].Find(PathToParentSData) <> Undefined Then
			Return PathToParentSData;
		EndIf;
		
		PathToParentSData = PathToParentSData(PathToParentSData);
	EndDo;
	
	Return "";
	
EndFunction

Function ThisTableSectionField(FieldDataPath, PrintData)
	
	PathToParentSData = PathToParentSData(FieldDataPath);
	
	While ValueIsFilled(PathToParentSData) Do
		ThisTableSectionField = PrintData["ObjectTablePartNames"].Find(PathToParentSData) <> Undefined;
		If ThisTableSectionField Then
			Return True;
		EndIf;
		
		PathToParentSData = PathToParentSData(PathToParentSData);
	EndDo;
	
	Return False;
	
EndFunction

Function FieldName(FieldDataPath)
	
	PathParts = StrSplit(FieldDataPath, ".", True);
	Return PathParts[PathParts.UBound()];

EndFunction

Function PathToParentSData(FieldDataPath)
	
	PathParts = StrSplit(FieldDataPath, ".", True);
	PathParts.Delete(PathParts.UBound());
	
	Return StrConcat(PathParts, ".");
	
EndFunction

Function CollectionParametersGettingDataSources()

	Parameters = New Structure;
	Parameters.Insert("DataSources");
	Parameters.Insert("SchemaFields");
	Parameters.Insert("LanguageCode");
	Parameters.Insert("DataCompositionSchema");
	Parameters.Insert("DataCompositionSchemaId");
	Parameters.Insert("DataSourceDescriptions");
	Parameters.Insert("SourceDataGroupedByDataSourceOwner");
	
	Return Parameters;
	
EndFunction

Function SourceData_(Parameters)

	If Not ValueIsFilled(Parameters.DataSources) Then
		Return New Map();
	EndIf;

	LayoutResult = ComposeData(Parameters);
	
	Tables = LayoutResult.Tables;
	DetailsData = LayoutResult.DetailsData;
	
	Result = New Map;
	Result.Insert("ObjectTablePartNames", Tables);
	
	For Each Ref In Parameters.DataSources Do
		Result[Ref] = New Map();
		For Each Table In Tables Do
			Result[Ref][Table] = New Map();
		EndDo;
		For Each Field In Parameters.SchemaFields Do
			NameParts = StrSplit(Field, ".", True);
			If Tables.Find(NameParts[0]) = Undefined Then
				Result[Ref][Field] = Undefined;
			EndIf;
		EndDo;
	EndDo;
	
	PeriodicValues = New Map;
	
	For Each DetailsItem In DetailsData.Items Do
		
		If TypeOf(DetailsItem) = Type("DataCompositionGroupDetailsItem") Then
			Continue;
		EndIf;
		
		DetailsParameters = DetailsParameters(DetailsItem);
		
		If Not ValueIsFilled(DetailsParameters.DetailsFieldName1) Then
			Continue;
		EndIf;
		
		FieldName = DetailsParameters.DetailsFieldName1;
		StringParts1 = StrSplit(DetailsParameters.DetailsFieldName1, ".");
		TableName = StringParts1[0];
		If StringParts1.Count() = 2 Then
			FieldName = StringParts1[1];
		EndIf;
		
		Ref = DetailsParameters.FieldList["Ref"];
		PrintData = Result[Ref];
		If PrintData = Undefined Then
			Result.Insert(Ref, New Map);
			PrintData = Result[Ref];
		EndIf;
		
		If PeriodicValues[Ref] = Undefined Then
			PeriodicValues[Ref] = New Map;
		EndIf;
		
		If Tables.Find(TableName) <> Undefined Then
			Table = PrintData[TableName];
			If Table = Undefined Then
				PrintData.Insert(TableName, New Map);
				Table = PrintData[TableName];
			EndIf;
			
			TableRowNumber = DetailsParameters.FieldList[TableName + ".LineNumber"];
			TableRow = Table[TableRowNumber];
			If TableRow = Undefined Then
				Table.Insert(TableRowNumber, New Map);
				TableRow = Table[TableRowNumber];
			EndIf;
			
			TableRow.Insert(FieldName, DetailsParameters.FieldList[DetailsParameters.DetailsFieldName1]);
		Else
			FieldName = DetailsParameters.DetailsFieldName1;
			If DetailsParameters.FieldList["Period"] <> Undefined And FieldName <> "Ref" And FieldName <> "Period" Then
				If PeriodicValues[Ref][FieldName] = Undefined Then
					ValueTable = New ValueTable;
					ValueTable.Columns.Add("Period", New TypeDescription("Date"));
					ValueTable.Columns.Add("Value");
					PeriodicValues[Ref][FieldName] = ValueTable;
				EndIf;
				TableRow = PeriodicValues[Ref][FieldName].Add();
				TableRow.Period = DetailsParameters.FieldList["Period"];
				TableRow.Value = DetailsParameters.FieldList[FieldName];
			EndIf;
			
			If FieldName = "Number" And Common.SubsystemExists("StandardSubsystems.ObjectsPrefixes") Then
				ModuleObjectsPrefixesClientServer = Common.CommonModule("ObjectsPrefixesClientServer");
				Value = ModuleObjectsPrefixesClientServer.NumberForPrinting(DetailsParameters.FieldList[FieldName]);
				PrintData.Insert(FieldName, Value);
			Else			
				PrintData.Insert(FieldName, DetailsParameters.FieldList[FieldName]);
			EndIf;
		EndIf;
	EndDo;
	
	HasPeriodicValues = False;
	For Each Item In PeriodicValues Do
		If ValueIsFilled(Item.Value) Then
			HasPeriodicValues = True;
			Break;
		EndIf;
	EndDo;
	
	If Parameters.SourceDataGroupedByDataSourceOwner Or Not HasPeriodicValues Then
		Return Result;
	EndIf;

	OwnersOfSources = Parameters.DataSourceDescriptions.UnloadColumn("Owner");
	
	RefsTypes = New Map;
	For Each Ref In OwnersOfSources Do
		If Ref = Undefined Then
			Continue;
		EndIf;
		Type = TypeOf(Ref);
		If RefsTypes[Type] = Undefined Then
			RefsTypes[Type] = New Array;
		EndIf;
		RefsTypes[Type].Add(Ref);
	EndDo;
	
	If Not ValueIsFilled(RefsTypes) Then
		Return Result;
	EndIf;

	PeriodValues = New Map;
	For Each RefsType In RefsTypes Do
		MetadataObject = Metadata.FindByType(RefsType.Key);
		If MetadataObject <> Undefined And Common.IsDocument(MetadataObject) Then
			DateValues = Common.ObjectsAttributeValue(RefsType.Value, "Date");
			For Each Ref In RefsType.Value Do
				PeriodValues.Insert(Ref, DateValues[Ref]);
			EndDo;
		EndIf;
	EndDo;
	
	Parameters.SourceDataGroupedByDataSourceOwner = True;

	For Each DataSourceDescription In Parameters.DataSourceDescriptions Do
		Ref = DataSourceDescription.Value;
		
		PrintData = Result[Ref];
		If PrintData = Undefined Then
			Continue;
		EndIf;
		
		Owner = DataSourceDescription.Owner;
		Result[Owner] = New Map;
		For Each Field In PrintData Do
			Result[Owner][Field.Key] = Field.Value;
			Period = PeriodValues[Owner];
			If Period <> Undefined And PeriodicValues[Ref] <> Undefined And PeriodicValues[Ref][Field.Key] <> Undefined Then
				Result[Owner][Field.Key] = Undefined;
				For Each ValueDescription In PeriodicValues[Ref][Field.Key] Do
					If ValueDescription.Period <= Period Then
						Result[Owner][Field.Key] = ValueDescription.Value;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

Function FindFieldVIerarchy(Val Field, FieldHierarchy)
	
	Result= FieldHierarchy[Field];
	If Result = Undefined Then
		For Each Item In FieldHierarchy Do
			Result = FindFieldVIerarchy(Field, Item.Value);
			If Result <> Undefined Then
				Return Result;
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  Parameters - See CollectionParametersGettingDataSources
//
Function ComposeData(Parameters)
	
	Objects = Parameters.DataSources;
	FieldsLayout = Common.CopyRecursive(Parameters.SchemaFields);
	LanguageCode = Parameters.LanguageCode;
	DataCompositionSchema = Parameters.DataCompositionSchema;
	DataCompositionSchemaId = Parameters.DataCompositionSchemaId;
	DataSourceDescriptions = Parameters.DataSourceDescriptions;
	SourceDataGroupedByDataSourceOwner = Parameters.SourceDataGroupedByDataSourceOwner;
	
	ExternalDataSets = New Structure;
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DataSourceDescriptions", DataSourceDescriptions);
	AdditionalParameters.Insert("SourceDataGroupedByDataSourceOwner", SourceDataGroupedByDataSourceOwner);
	
	TitleText = DataCompositionSchemaId;
	
	RequiresPreparingExternalDataset = False;
	For Each DataSet In DataCompositionSchema.DataSets Do
		If TypeOf(DataSet) = Type("DataCompositionSchemaDataSetObject") Then
			RequiresPreparingExternalDataset = True;
			Break;
		EndIf;
	EndDo;
	
	If RequiresPreparingExternalDataset Then
		If Metadata.FindByFullName(DataCompositionSchemaId) = Undefined Then
			WhenPreparingPrintData(Objects, ExternalDataSets, DataCompositionSchemaId, LanguageCode, AdditionalParameters);
		Else
			ObjectManager = Common.ObjectManagerByFullName(DataCompositionSchemaId);
			ObjectManager.WhenPreparingPrintData(Objects, ExternalDataSets, LanguageCode, AdditionalParameters);
		EndIf;
	EndIf;
	
	DataSourceDescriptions = AdditionalParameters.DataSourceDescriptions;
	SourceDataGroupedByDataSourceOwner = AdditionalParameters.SourceDataGroupedByDataSourceOwner;
	
	If SourceDataGroupedByDataSourceOwner Then
		Objects = DataSourceDescriptions.UnloadColumn("Owner");
		Objects = CommonClientServer.CollapseArray(Objects);
	EndIf;
		
	SettingsComposer = New DataCompositionSettingsComposer;
	SchemaURL = PutToTempStorage(DataCompositionSchema);
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	ComposerSettings = SettingsComposer.Settings;
	
	WithdrawalOfBankDetails = ComposerSettings.OutputParameters.Items.Find("AttributePlacement");
	WithdrawalOfBankDetails.Value = DataCompositionAttributesPlacement.Separately;
	WithdrawalOfBankDetails.Use = True;
	
	TotalsPlacement = ComposerSettings.OutputParameters.Items.Find("TotalsPlacement");
	TotalsPlacement.Value = DataCompositionTotalPlacement.None;
	TotalsPlacement.Use = True;

	FilterOutput = ComposerSettings.OutputParameters.Items.Find("FilterOutput");
	FilterOutput.Value = DataCompositionTextOutputType.DontOutput;
	FilterOutput.Use = True;

	Title = ComposerSettings.OutputParameters.Items.Find("Title");
	Title.Value = TitleText;
	Title.Use = True;
	
	Tables = New Array;
	For Each Field In ComposerSettings.SelectionAvailableFields.Items Do
		If Field.Table Then
			TableName = String(Field.Field);
			Tables.Add(TableName);
		EndIf;
	EndDo;
	
	ComposerSettings.Structure.Clear();
	
	KeyField = Undefined;
	For Each FieldName In StrSplit("Ref", ",") Do
		KeyField = New DataCompositionField(FieldName);
		If ComposerSettings.GroupAvailableFields.FindField(KeyField) <> Undefined Then
			Break;
		Else
			KeyField = Undefined;
		EndIf;
	EndDo;
	
	If KeyField = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"en = 'The ""%1"" key field is not found in the list of fields of the data composition schema for printing ""%2"".
			|See the ""%3"" parameter details in the ""%4"" procedure.';"),
			"Ref",
			DataCompositionSchemaId,
			"PrintDataSources",
			"PrintManagementOverridable.OnDefinePrintDataSources");
	EndIf;
	
	Group = ComposerSettings.Structure.Add(Type("DataCompositionGroup"));

	Field = Group.GroupFields.Items.Add(Type("DataCompositionGroupField"));
	Field.Field = KeyField;
	Field.Use = True;
	
	Group.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	
	DataCompositionTable = Group.Structure.Add(Type("DataCompositionTable"));
	
	Header = DataCompositionTable.Rows.Add();
	Header.GroupFields.Items.Add(Type("DataCompositionAutoGroupField"));

	If FieldsLayout.Find("Period") = Undefined Then
		FieldsLayout.Add("Period");
	EndIf;
	
	For Each DataPath In FieldsLayout Do
		If Tables.Find(StrSplit(DataPath, ".", True)[0]) <> Undefined Then
			Continue;
		EndIf;
		
		AvailableField = ComposerSettings.Selection.SelectionAvailableFields.FindField(New DataCompositionField(DataPath));
		If AvailableField = Undefined Then
			Continue;
		EndIf;
		
		If AvailableField.Folder Then
			Field = Header.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
		Else
			Field = Header.Selection.Items.Add(Type("DataCompositionSelectedField"));
		EndIf;
		Field.Field = New DataCompositionField(DataPath);
		Field.Use = True;
	EndDo;
	
	For Each TabularSectionName In Tables Do
		DataCompositionTable = Group.Structure.Add(Type("DataCompositionTable"));
		
		GroupingByLineNumber = DataCompositionTable.Rows.Add();
		GroupingByLineNumber.GroupFields.Items.Add(Type("DataCompositionGroupField"));

		Field = GroupingByLineNumber.GroupFields.Items.Add(Type("DataCompositionGroupField"));
		Field.Field = New DataCompositionField(TabularSectionName + ".LineNumber");
		Field.Use = True;
		
		TabularSectionData = GroupingByLineNumber.Structure.Add();
		TabularSectionData.GroupFields.Items.Add(Type("DataCompositionAutoGroupField"));
		
		For Each DataPath In FieldsLayout Do
			If StrSplit(DataPath, ".", True)[0] <> TabularSectionName Then
				Continue;
			EndIf;
			
			AvailableField = ComposerSettings.Selection.SelectionAvailableFields.FindField(New DataCompositionField(DataPath));
			If AvailableField = Undefined Then
				Continue;
			EndIf;
			
			If AvailableField.Folder Then
				Field = TabularSectionData.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
			Else
				Field = TabularSectionData.Selection.Items.Add(Type("DataCompositionSelectedField"));
			EndIf;
			Field.Field = New DataCompositionField(DataPath);
			Field.Use = True;
		EndDo;
	EndDo;
	
	Group.Structure.Add(Type("DataCompositionTable"));
	
	FilterElement = ComposerSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = KeyField;
	FilterElement.ComparisonType = DataCompositionComparisonType.InList;
	FilterElement.RightValue = New ValueList;
	FilterElement.RightValue.LoadValues(Objects);
	
	ResultDocument = New SpreadsheetDocument;
	TemplateComposer = New DataCompositionTemplateComposer;
	DetailsData = New DataCompositionDetailsData;
	
	DataCompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ComposerSettings, DetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(DataCompositionProcessor);	
	
	Parameters.SourceDataGroupedByDataSourceOwner = SourceDataGroupedByDataSourceOwner;
	
	Result = New Structure;
	Result.Insert("DetailsData", DetailsData);
	Result.Insert("Tables", Tables);
	
	Return	Result;
	
EndFunction

Function TemplateExists(TemplatePath)
	
	PathParts = StrSplit(TemplatePath, ".", True);
	
	Id = PathParts[PathParts.UBound()];
	If StrStartsWith(Id, "PF_") Then
		Id = Mid(Id, 4);
		If StringFunctionsClientServer.IsUUID(Id) Then
			TemplateExists = Catalogs.PrintFormTemplates.TemplateExists(New UUID(Id));
			If TemplateExists Then
				Return True;
			EndIf;
		EndIf;
	EndIf;
	
	If PathParts.Count() <> 2 And PathParts.Count() <> 3 Then
		Return False;
	EndIf;
	
	TemplateName = PathParts[PathParts.UBound()];
	PathParts.Delete(PathParts.UBound());
	ObjectName = StrConcat(PathParts, ".");
	
	IsCommonTemplate = StrSplit(ObjectName, ".").Count() = 1;
	TemplatesCollection = Metadata.CommonTemplates;
	
	If Not IsCommonTemplate Then
		MetadataObject = Common.MetadataObjectByFullName(ObjectName);
		If MetadataObject = Undefined Then
			Return False;
		EndIf;
		TemplatesCollection = MetadataObject.Templates;
	EndIf;
	
	Return TemplatesCollection.Find(TemplateName) <> Undefined;
	
EndFunction

// Parameters:
//  
//  
//
// Returns:
//  Structure:
//   * DetailsFieldName1 - String
//   * FieldList - Map of KeyAndValue:
//    ** Key - String
//    ** Value - Arbitrary
//
Function DetailsParameters(DetailsItem)
	
	FieldList = New Map;
	FillFieldsList(FieldList, DetailsItem);
	
	DetailsFieldName1 = "";
	For Each Simple In DetailsItem.GetFields() Do
		DetailsFieldName1 = Simple.Field;
		Break;
	EndDo;
	
	Result = New Structure;
	Result.Insert("DetailsFieldName1", DetailsFieldName1);
	Result.Insert("FieldList", FieldList);
	
	Return Result;
	
EndFunction

// Parameters:
//   FieldList - Map of KeyAndValue:
//    ** 
//    ** 
//   DetailsItem - DataCompositionFieldDetailsItem
//                      - DataCompositionGroupDetailsItem
//
Procedure FillFieldsList(FieldList, DetailsItem)
	
	If TypeOf(DetailsItem) = Type("DataCompositionFieldDetailsItem") Then
		For Each Simple In DetailsItem.GetFields() Do
			If FieldList[Simple.Field] = Undefined Then
				FieldList.Insert(Simple.Field, Simple.Value);
			EndIf;
		EndDo;
	EndIf;
		
	For Each Parent In DetailsItem.GetParents() Do
		FillFieldsList(FieldList, Parent);
	EndDo;
	
EndProcedure

Function ParameterValues(Parameters, PrintData, FieldFormatSettings, LanguageCode)
	
	Result = New Map;

	For Each Parameter In Parameters Do
		Value = EvalExpression(Parameter, PrintData, FieldFormatSettings, LanguageCode);
		Result.Insert(Parameter, Value);
	EndDo;
	
	Return Result;
	
EndFunction

Function EvalExpression(Val OriginalExpression, PrintData, FieldFormatSettings, LanguageCode, ApplyFormatting = Undefined)
	
	Expression = OriginalExpression;
	Expression = Mid(Expression, 2, StrLen(Expression) - 2);
	
	FormulaElements = FormulasConstructorInternal.FormulaElements(Expression);
	PickTableColumnName(Expression, FormulaElements);
	
	Parameters = New Array;
	
	If ApplyFormatting = Undefined Then
		ApplyFormatting = False;
		
		If FormulaElements.OperandsAndFunctions.Count() = 1 Then
			For Each ItemDetails In FormulaElements.OperandsAndFunctions Do
				IsFunction = ItemDetails.Value;
				If IsFunction Then
					Break;
				EndIf;
				Operand = FormulaElements.AllItems[ItemDetails.Key];
				ApplyFormatting = Operand = Expression;
				Break;
			EndDo;
		EndIf;
	EndIf;
	
	For Each ItemDetails In FormulaElements.OperandsAndFunctions Do
		Operand = FormulaElements.AllItems[ItemDetails.Key];
		IsFunction = ItemDetails.Value;
		DataCollection = PrintData;
		
		If Not IsFunction Then
			If StrFind(Upper("And,OR,NOT,TRUE,FALSE"), Upper(Operand)) Then
				Continue;
			EndIf;
			
			Value = DataCollection[ClearSquareBrackets(Operand) + "." + StrSplit(LanguageCode, "_")[0]];
			If Not ValueIsFilled(Value) Then
				Value = DataCollection[ClearSquareBrackets(Operand)];
			EndIf;
			
			Format = "";
			If ApplyFormatting Then
				Format = FieldFormatSettings[Operand];
			EndIf;

			If ValueIsFilled(Format) And FormulaElements.OperandsAndFunctions.Count() = 1 Then
				If ValueIsFilled(LanguageCode) Then
					Format = StrTemplate("L=%1;", LanguageCode) + Format;
				EndIf;
				Value = Format(Value, Format);
			EndIf;
			
			Parameters.Add(Value);
			FormulaElements.AllItems[ItemDetails.Key] = "Parameters[" + Parameters.UBound() + "]";
		EndIf;
	EndDo;
	
	Expression = StrConcat(FormulaElements.AllItems);
	Expression = StrReplace(Expression, PrintModuleName() + CommandSeparator(), PrintModuleName() + ".");
	
	Try
		Result = Common.CalculateInSafeMode(Expression, Parameters);
	Except
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Expression ""%1"" contains errors:
			|%2';"), OriginalExpression, ErrorText));
		Result = "";
	EndTry;
	
	Return Result;
	
EndFunction

Procedure PickTableColumnName(Expression, FormulaElements)
	
	FunctionsWithParametersSeparation = FunctionsWithParametersSeparation();	
	
	IsFunctionFound = False;
	For Each FunctionName In FunctionsWithParametersSeparation Do
		If StrFind(Expression, FunctionName) Then
			IsFunctionFound = True;
			Break;
		EndIf;
	EndDo;
	
	If IsFunctionFound Then
		Result = New Array;
		AllItemsOfExpression = FormulaElements.AllItems;
		For IndexOf = 0 To AllItemsOfExpression.UBound() Do
			Item = AllItemsOfExpression[IndexOf];
			Result.Add(Item);
			If StrStartsWith(Item, PrintModuleName() + CommandSeparator()) Then
				Result.Add(AllItemsOfExpression[IndexOf+1]); 
				ArrayOfParameterNames = StrSplit(AllItemsOfExpression[IndexOf+2], ".", False);
				Result.Add(ArrayOfParameterNames[0]);
				Result.Add(",");
				If ArrayOfParameterNames.Count() = 2 Then
					Result.Add("""");
					ColumnName = ArrayOfParameterNames[1];
					For Position = 1 To StrLen(ColumnName) Do
						Result.Add(Mid(ColumnName, Position, 1));
					EndDo;
					Result.Add("""");
				EndIf;
				Result.Add(AllItemsOfExpression[IndexOf+3]);
				IndexOf = IndexOf + 3;
			EndIf;
		EndDo;
		FormulaElements.AllItems = Result;
	EndIf;
	
EndProcedure

Function FunctionsWithParametersSeparation()
	
	PrintModuleNameWithSeparator = PrintModuleName() + CommandSeparator();
	
	FunctionsWithParametersSeparation = New Array();	
	FunctionsWithParametersSeparation.Add(PrintModuleNameWithSeparator + "SumByColumn");
	FunctionsWithParametersSeparation.Add(PrintModuleNameWithSeparator + "RowsCount");
	FunctionsWithParametersSeparation.Add(PrintModuleNameWithSeparator + "Maximum");
	FunctionsWithParametersSeparation.Add(PrintModuleNameWithSeparator + "Minimum");
	FunctionsWithParametersSeparation.Add(PrintModuleNameWithSeparator + "Mean");
	
	Return FunctionsWithParametersSeparation;
	
EndFunction

Function PrintModuleName()
	Return Metadata.CommonModules.PrintManagement.Name;
EndFunction

Function CommandSeparator()
	Return "_";
EndFunction

Function ClearSquareBrackets(String)
	
	If StrStartsWith(String, "[") And StrEndsWith(String, "]") Then
		Return Mid(String, 2, StrLen(String) - 2);
	EndIf;
	
	Return String;
	
EndFunction

Function TemplateAreas(Template, PrintData)
	
	Tables = PrintData["ObjectTablePartNames"];
	AllAreas = New ValueList;
	AreasTables = New Map;
	
	Areaswithconditions = New Map;
	For Each Area In Template.Areas Do
		If TypeOf(Area) = Type("SpreadsheetDocumentRange") And Area.AreaType = SpreadsheetDocumentCellAreaType.Rows Then
			Areaswithconditions.Insert(Area.Top, Area);
		EndIf;
	EndDo;	
	
	AreasToProcess = New Array;
	
	AreaStart = 1;
	For LineNumber = 1 To Template.TableHeight Do
		If Areaswithconditions[LineNumber] <> Undefined Then
			If AreaStart < LineNumber Then
				Area = Template.Area(AreaStart, , LineNumber-1);
				AreasToProcess.Add(Area);
			EndIf;
			AreasToProcess.Add(Areaswithconditions[LineNumber]);
			LineNumber = Areaswithconditions[LineNumber].Bottom;
			AreaStart = LineNumber + 1;
		EndIf;
	EndDo;
	
	If Template.TableHeight >= AreaStart Then
		Area = Template.Area(AreaStart, , Template.TableHeight);
		AreasToProcess.Add(Area);
	EndIf;
	
	For Each Area In AreasToProcess Do // SpreadsheetDocumentRange
		AreasDetails = DivideInRegions(Template, Area, Tables);
		CommonClientServer.SupplementMap(AreasTables, AreasDetails.AreasTables);
		OutputCondition = "";
		If Template.Areas.Find(Area.Name) <> Undefined Then
			OutputCondition = Area.DetailsParameter;
		EndIf;
		For Each AreaID In AreasDetails.AllAreas Do
			AllAreas.Add(AreaID, OutputCondition);
		EndDo;
	EndDo;

	Result = New Structure;
	Result.Insert("AllAreas", AllAreas);
	Result.Insert("AreasTables", AreasTables);
	
	Return Result;
	
EndFunction

Function DivideInRegions(Template, Area, Tables)
	
	AllAreas = New Array;
	AreasTables = New Map;
	
	AreaStart = Area.Top;
	CurrentTable = "";
	PreviousTable = "";
	
	For LineNumber = Area.Top To Area.Bottom Do
		Top = LineNumber;
		Bottom = LineNumber;
		
		For ColumnNumber = 1 To Template.TableWidth Do
			TableCellArea = Template.Area(LineNumber, ColumnNumber);
			Bottom = Max(Bottom, TableCellArea.Bottom);
		EndDo;
		
		LineNumber = Bottom;
		RowArea = Template.Area(Top, , Bottom);
		CurrentTable = TableNameINLayoutArea(Template, RowArea, Tables);
	
		If PreviousTable <> CurrentTable And Top > AreaStart Then
			AreaID = "R" + XMLString(AreaStart) + ":R" + XMLString(Top - 1);
			AllAreas.Add(AreaID);
			
			If ValueIsFilled(PreviousTable) Then
				AreasTables.Insert(AreaID, PreviousTable);
			EndIf;
			
			AreaStart = Top;
		EndIf;

		PreviousTable = CurrentTable;
	EndDo;
	
	AreaID = "R" + XMLString(AreaStart) + ":R" + Area.Bottom;

	If ValueIsFilled(CurrentTable) Then
		AreasTables.Insert(AreaID, PreviousTable);
	EndIf;
	AllAreas.Add(AreaID);
	
	Result = New Structure;
	Result.Insert("AllAreas", AllAreas);
	Result.Insert("AreasTables", AreasTables);
	
	Return Result;
	
EndFunction

Function TableNameINLayoutArea(Template, Area, Tables)
	
	ProcessedCells = New Map;
	
	FunctionsWithParametersSeparation = FunctionsWithParametersSeparation();
	
	For LineNumber = Area.Top To Area.Bottom Do
		For ColumnNumber = 1 To Template.TableWidth Do
			TableCellArea = Template.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
			
			AreaID = AreaID(TableCellArea);
			If ProcessedCells[AreaID] <> Undefined Then
				Continue;
			EndIf;
			ProcessedCells[AreaID] = True;
			
			ParametersInText = FindParametersInText(TableCellArea.Text);
			
			For Each Parameter In ParametersInText Do
				Expression = ClearSquareBrackets(Parameter);
				FormulaElements =FormulasConstructorInternal.FormulaElements(Expression);
				
				IsTotalsFunctionFound = False;
				
				For Each Item In FormulaElements.AllItems Do
					If StrStartsWith(Item, PrintModuleName() + CommandSeparator())
						And FunctionsWithParametersSeparation.Find(Item) <> Undefined Then
						IsTotalsFunctionFound = True;
						Continue;
					EndIf;
					
					For Each Table In Tables Do
						SearchString = Table + ".";
						If StrStartsWith(Item, SearchString) Then
							If IsTotalsFunctionFound Then
								IsTotalsFunctionFound = False;
							Else
								Return Table;
							EndIf;
						EndIf;
					EndDo;
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
	Return "";
	
EndFunction

Function FieldsLayout(Template)

	Texts = New Map;
	
	ProcessedCells = New Map;
	For LineNumber = 1 To Template.TableHeight Do
		For ColumnNumber = 1 To Template.TableWidth Do
			TableCellArea = Template.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
			
			AreaID = AreaID(TableCellArea);
			If ProcessedCells[AreaID] <> Undefined Then
				Continue;
			EndIf;
			ProcessedCells[AreaID] = True;
			
			If Not ValueIsFilled(TableCellArea.Text) Then
				Continue;
			EndIf;
			
			Texts.Insert(TableCellArea.Text, True);
		EndDo;
	EndDo;
	
	Texts.Insert(String(Template.Header.LeftText), True);
	Texts.Insert(String(Template.Header.CenterText), True);
	Texts.Insert(String(Template.Header.RightText), True);

	Texts.Insert(String(Template.Footer.LeftText), True);
	Texts.Insert(String(Template.Footer.CenterText), True);
	Texts.Insert(String(Template.Footer.RightText), True);
	
	For Each Drawing In Template.Drawings Do
		If Drawing.DrawingType <> SpreadsheetDocumentDrawingType.Group Then 
			Texts.Insert(Drawing.DetailsParameter, True);
		EndIf;
	EndDo;
	
	Expressions = New Array;
	
	For Each Area In Template.Areas Do
		If TypeOf(Area) = Type("SpreadsheetDocumentRange")
			And Area.AreaType = SpreadsheetDocumentCellAreaType.Rows Then
			OutputCondition = Area.DetailsParameter;
			If ValueIsFilled(OutputCondition) Then
				Expressions.Add(Area.DetailsParameter);
			EndIf;
		EndIf;
	EndDo;
	
	For Each Item In Texts Do
		Text = Item.Key;
		TextParameters = FindParametersInText(Text);
		For Each Expression In TextParameters Do
			Expression = Mid(Expression, 2, StrLen(Expression) - 2);
			Expressions.Add(Expression);
		EndDo;
	EndDo;
	
	Result = New Array;
	
	For Each Expression In Expressions Do
		FormulaElements = FormulasConstructorInternal.FormulaElements(Expression);
		For Each ItemDetails In FormulaElements.OperandsAndFunctions Do
			IsFunction = ItemDetails.Value;
			If IsFunction Then
				Continue;
			EndIf;
			
			Operand = FormulaElements.AllItems[ItemDetails.Key];
			Operand = ClearSquareBrackets(Operand);
			If ValueIsFilled(Operand) Then
				Result.Add(Operand);
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

Function RowsCount(Table, ColumnName = Undefined) Export
	
	If TypeOf(Table) = Type("Map") Then
		Return Table.Count();
	EndIf;
	
	Raise NStr("en = 'Incorrect table';");
	
EndFunction

Function SumByColumn(Table, ColumnName = Undefined) Export // 
	
	If TypeOf(Table) = Type("Map") Then
		Value = 0;
		NumberType = New TypeDescription("Number");
		For Each MatchingOfString In Table Do
			TableRow = MatchingOfString.Value;
			Value = Value + NumberType.AdjustValue(TableRow[ColumnName]);
		EndDo;
		
		Return Value;
	EndIf;
	
	Raise NStr("en = 'The table column is incorrect';");
	
EndFunction

Function ColumnMax(Table, ColumnName = Undefined) Export // 
	
	If TypeOf(Table) = Type("Map") Then
		Value = Undefined;
		NumberType = New TypeDescription("Number");
		For Each MatchingOfString In Table Do
			TableRow = MatchingOfString.Value;
			StringValue_ = NumberType.AdjustValue(TableRow[ColumnName]);
			Value = ?(Value = Undefined, StringValue_, Value);
			Value = Max(Value, StringValue_);
		EndDo;
		
		Return Value;
	EndIf;
	
	Raise NStr("en = 'The table column is incorrect';");
	
EndFunction

Function ColumnMin(Table, ColumnName = Undefined) Export // 
	
	If TypeOf(Table) = Type("Map") Then
		Value = Undefined;
		NumberType = New TypeDescription("Number");
		For Each MatchingOfString In Table Do
			TableRow = MatchingOfString.Value;
			StringValue_ = NumberType.AdjustValue(TableRow[ColumnName]);
			Value = ?(Value = Undefined, StringValue_, Value);
			Value = Min(Value, StringValue_);
		EndDo;
		
		Return Value;
	EndIf;
	
	Raise NStr("en = 'The table column is incorrect';");
	
EndFunction

Function ColumnAverage(Table, ColumnName = Undefined) Export // 
	
	If TypeOf(Table) = Type("Map") Then
		Value = 0;
		NumberType = New TypeDescription("Number");
		For Each MatchingOfString In Table Do
			TableRow = MatchingOfString.Value;
			Value = Value + NumberType.AdjustValue(TableRow[ColumnName]);
		EndDo;
		
		Return ?(Table.Count(), Value/Table.Count(), 0);
	EndIf;
	
	Raise NStr("en = 'The table column is incorrect';");

EndFunction

// Returns:
//   See FormulasConstructorInternal.DescriptionOfFieldLists
//
Function DescriptionOfFieldLists(PrintDataSources, Operators = Undefined, DataSource = Undefined) Export
	
	DescriptionOfFieldLists = FormulasConstructorInternal.DescriptionOfFieldLists();
	
	SourcesOfAvailableFields = FormulasConstructorInternal.CollectionOfSourcesOfAvailableFields();
	For Each Item In PrintDataSources Do
		DataCompositionSchema = Item.Value;
		DataCompositionSchemaId = Item.Presentation;
		SourceOfAvailableFields = SourcesOfAvailableFields.Add(); 
		SourceOfAvailableFields.FieldsCollection = FormulasConstructorInternal.FieldsCollection(DataCompositionSchema);
		SourceOfAvailableFields.DataCompositionSchema = PutToTempStorage(DataCompositionSchema);
		SourceOfAvailableFields.DataCompositionSchemaId = DataCompositionSchemaId;
		SourceOfAvailableFields.DataSource = DataSource;
	EndDo;
	
	DescriptionOfTheFieldList = DescriptionOfFieldLists.Add();
	DescriptionOfTheFieldList.SourcesOfAvailableFields = SourcesOfAvailableFields;
	DescriptionOfTheFieldList.ViewBrackets = True;
	DescriptionOfTheFieldList.WhenDefiningAvailableFieldSources = "PrintManagement";
	
	If Operators <> Undefined Then
		SourcesOfAvailableFields = FormulasConstructorInternal.CollectionOfSourcesOfAvailableFields();
		SourceOfAvailableFields = SourcesOfAvailableFields.Add(); 
		SourceOfAvailableFields.FieldsCollection = FormulasConstructorInternal.FieldsCollection(Operators);
		
		DescriptionOfTheFieldList = DescriptionOfFieldLists.Add();
		DescriptionOfTheFieldList.SourcesOfAvailableFields = SourcesOfAvailableFields;
	EndIf;
	
	Return DescriptionOfFieldLists;
	
EndFunction

// Parameters:
//  FieldSourceName - String
//  SourcesOfAvailableFields - ValueTable
//  FormUniqueID - UUID
//
Procedure WhenDefiningAvailableFieldSources(FieldSourceName, FieldsSourceType, SourcesOfAvailableFields, FormUniqueID) Export
	
	DataCompositionSchemas = FieldsSourceDataCompositionSchemes(FieldSourceName, , FieldsSourceType);
	For Each Item In DataCompositionSchemas Do
		DataCompositionSchema = Item.Value;
		DataCompositionSchemaId = Item.Presentation;
		SourceOfAvailableFields = SourcesOfAvailableFields.Add();
		SourceOfAvailableFields.DataSource = FieldSourceName;
		SourceOfAvailableFields.DataCompositionSchema = PutToTempStorage(DataCompositionSchema, FormUniqueID);
		SourceOfAvailableFields.DataCompositionSchemaId = DataCompositionSchemaId;
		SourceOfAvailableFields.FieldsCollection = FormulasConstructor.FieldsCollection(DataCompositionSchema);
		SourceOfAvailableFields.Replace = True;
	EndDo;
	
EndProcedure

Function FieldsSourceDataCompositionSchemes(FieldSourceName, AddCommonAttributes = False, FieldsSourceType = Undefined)
	
	FieldSources = New ValueList;
	
	MetadataObject = Common.MetadataObjectByFullName(FieldSourceName);
	If MetadataObject <> Undefined Then
		If MetadataObject.Templates.Find("PrintData") <> Undefined Then
			ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
			DataCompositionSchema = ObjectManager.GetTemplate("PrintData");
			If Common.SubsystemExists("StandardSubsystems.ObjectsPrefixes") Then
				ModuleObjectsPrefixesInternal = Common.CommonModule("ObjectsPrefixesInternal");
				ModuleObjectsPrefixesInternal.AddFieldExtensionNum(DataCompositionSchema);
			EndIf;
			FieldSources.Add(DataCompositionSchema, MetadataObject.FullName());
		Else
			QueryText = QueryText(MetadataObject.FullName());
			DataCompositionSchema= DataCompositionSchema(QueryText);
			If Common.SubsystemExists("StandardSubsystems.ObjectsPrefixes") Then
				ModuleObjectsPrefixesInternal = Common.CommonModule("ObjectsPrefixesInternal");
				ModuleObjectsPrefixesInternal.AddFieldExtensionNum(DataCompositionSchema);
			EndIf;
			FieldSources.Add(DataCompositionSchema, MetadataObject.FullName());
			
			If MetadataObject.Templates.Find("AdditionalPrintingData") <> Undefined Then
				ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
				DataCompositionSchema = ObjectManager.GetTemplate("AdditionalPrintingData");
				FieldSources.Add(DataCompositionSchema, MetadataObject.FullName());
			EndIf;
		EndIf;
		
		DataCompositionSchema = DataLayoutSchemaContactInformation(MetadataObject.FullName());
		If DataCompositionSchema <> Undefined Then
			FieldSources.Add(DataCompositionSchema, MetadataObject.FullName() + ".ContactInformation");
		EndIf;
		
		DataCompositionSchema = LayoutSchemeDataAdditionalDetailsAndDetails(MetadataObject.FullName());
		If DataCompositionSchema <> Undefined Then
			FieldSources.Add(DataCompositionSchema, MetadataObject.FullName() + ".AdditionalAttributesAndInfo");
		EndIf;
		
	EndIf;
	
	If AddCommonAttributes Then
		FieldSources.Add(GetCommonTemplate("PrintDataCommonAttributes"), "CommonAttributes");	
	EndIf;

	If StrEndsWith(FieldSourceName, ".Description") Or StrEndsWith(FieldSourceName, ".NameForPrinting") Then
		FieldSources.Add(GetCommonTemplate("PrintDataCharacterCase"), "PrintDataCharacterCase");	
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.Currencies") Then
		If FieldsSourceType = Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type
			Or FieldsSourceType = Metadata.DefinedTypes.MonetaryAmountNonNegative.Type Then
				ModuleCurrencyExchangeRates = Common.CommonModule("CurrencyRateOperations");
				ModuleCurrencyExchangeRates.ConnectPrintDataSourceNumberWritten(FieldSources);
		EndIf;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		PrintManagementModuleNationalLanguageSupport.OnDefinePrintDataSources(FieldSourceName, FieldSources);
	EndIf;
	
	SSLSubsystemsIntegration.OnDefinePrintDataSources(FieldSourceName, FieldSources);
	PrintManagementOverridable.OnDefinePrintDataSources(FieldSourceName, FieldSources);
	
	Return FieldSources;
	
EndFunction

Procedure WhenPreparingPrintData(Objects, ExternalDataSets, DataCompositionSchemaId, LanguageCode, AdditionalParameters)
	
	If DataCompositionSchemaId = "CommonAttributes" Then
		ExternalDataSets.Insert("Data", GeneralDetailsofPrintedForms(Objects));
		Return;
	EndIf;

	If StrEndsWith(DataCompositionSchemaId, ".ContactInformation") Then
		ExternalDataSets.Insert("Data", ContactInformation(
			Objects, DataCompositionSchemaId, LanguageCode, AdditionalParameters));
		Return;
	EndIf;	
	
	If StrEndsWith(DataCompositionSchemaId, ".AdditionalAttributesAndInfo") Then
		ExternalDataSets.Insert("Data", AdditionalAttributesAndInfo(
			Objects, DataCompositionSchemaId,  LanguageCode));
		Return;
	EndIf;	
	
	If DataCompositionSchemaId = "PrintDataCharacterCase" Then
		ExternalDataSets.Insert("Data", PrintDataCharacterCase(Objects));
		Return;
	EndIf;
	
		
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		PrintManagementModuleNationalLanguageSupport.WhenPreparingPrintData(
			Objects, ExternalDataSets, DataCompositionSchemaId, LanguageCode, AdditionalParameters);
	EndIf;
	
	SSLSubsystemsIntegration.WhenPreparingPrintData(Objects, ExternalDataSets, DataCompositionSchemaId, LanguageCode, AdditionalParameters);
	PrintManagementOverridable.WhenPreparingPrintData(Objects, ExternalDataSets, DataCompositionSchemaId, LanguageCode, AdditionalParameters);
	
EndProcedure

Function GeneralDetailsofPrintedForms(Objects)

	CommonAttributes = New Structure;
	CommonAttributes.Insert("CurrentDate", CurrentSessionDate());
	CommonAttributes.Insert("CurrentUser", Users.CurrentUser());
	CommonAttributes.Insert("SystemTitle", ThisInfobaseName());
	CommonAttributes.Insert("InfobaseInternetAddress", Common.InfobasePublicationURL());
	CommonAttributes.Insert("InfobaseLocalAddress", Common.LocalInfobasePublishingURL());
	CommonAttributes.Insert("MainCompany", "");
	CommonAttributes.Insert("ReplyTo", "");
	CommonAttributes.Insert("DSStamp", "");
	
	Result = New ValueTable();
	Result.Columns.Add("Ref");
	For Each Attribute In CommonAttributes Do
		Result.Columns.Add(Attribute.Key);
	EndDo;
	
	For Each Object In Objects Do
		ObjectAttributes = Result.Add();
		FillPropertyValues(ObjectAttributes, CommonAttributes);
		ObjectAttributes.Ref = Object;
	EndDo;
	
	Return Result;
	
EndFunction

Function DataCompositionSchema(QueryText)
	
	DataCompositionSchema = New DataCompositionSchema;
	
	DataSource = DataCompositionSchema.DataSources.Add();
	DataSource.Name = "DataSource1";
	DataSource.DataSourceType = "local";
	
	DataSet = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.DataSource = "DataSource1";
	DataSet.AutoFillAvailableFields = True;
	DataSet.Query = QueryText;
	DataSet.Name = "DataSet1";
	
	Return DataCompositionSchema;
	
EndFunction

Function QueryText(TypesOfObjectsToChange, RestrictSelection = False)
	
	MetadataObjects = New Array;
	For Each ObjectName In StrSplit(TypesOfObjectsToChange, ",", False) Do
		MetadataObjects.Add(Common.MetadataObjectByFullName(ObjectName));
	EndDo;
	
	ObjectsStructure = CommonObjectsAttributes(TypesOfObjectsToChange);
	
	Result = "";
	TableAlias = "SpecifiedTableAlias";
	For Each MetadataObject In MetadataObjects Do
		
		If Not IsBlankString(Result) Then
			Result = Result + Chars.LF + Chars.LF + "UNION ALL" + Chars.LF + Chars.LF;
		EndIf;
		
		QueryText = "";
		
		For Each AttributeName In ObjectsStructure.Attributes Do
			If StrStartsWith(AttributeName, "Delete") Then
				Continue;
			EndIf;
			If Not IsBlankString(QueryText) Then
				QueryText = QueryText + "," + Chars.LF;
			EndIf;
			QueryText = QueryText + TableAlias + "." + AttributeName + " AS " + AttributeName;
		EndDo;
		
		For Each TabularSection In ObjectsStructure.TabularSections Do
			TabularSectionName = TabularSection.Key;
			If StrStartsWith(TabularSectionName, "Delete") Then
				Continue;
			EndIf;
			QueryText = QueryText + "," + Chars.LF + TableAlias + "." + TabularSectionName + ".(";
			
			AttributesRow = "LineNumber";
			TabularSectionAttributes = TabularSection.Value;
			For Each AttributeName In TabularSectionAttributes Do
				If Not IsBlankString(AttributesRow) Then
					AttributesRow = AttributesRow + "," + Chars.LF;
				EndIf;
				AttributesRow = AttributesRow + AttributeName;
			EndDo;
			QueryText = QueryText + AttributesRow +"
			|)";
		EndDo;
		
		QueryText = "SELECT " + ?(RestrictSelection, "TOP 1001 ", "") //@query-part
			+ QueryText + Chars.LF + "
			|FROM
			|	"+ MetadataObject.FullName() + " AS " + TableAlias;
		
		Result = Result + QueryText;
	EndDo;
		
		
	Return Result;
	
EndFunction

Function CommonObjectsAttributes(ObjectsTypes) Export
	
	MetadataObjects = New Array;
	For Each ObjectName In StrSplit(ObjectsTypes, ",", False) Do
		MetadataObjects.Add(Common.MetadataObjectByFullName(ObjectName));
	EndDo;
	
	Result = New Structure;
	Result.Insert("Attributes", New Array);
	Result.Insert("TabularSections", New Structure);
	
	If MetadataObjects.Count() = 0 Then
		Return Result;
	EndIf;
		
	CommonAttributesList = ItemsList(MetadataObjects[0].Attributes, False);
	For IndexOf = 1 To MetadataObjects.Count() - 1 Do
		CommonAttributesList = AttributesIntersection(CommonAttributesList, MetadataObjects[IndexOf].Attributes);
	EndDo;
	
	StandardAttributes = MetadataObjects[0].StandardAttributes;
	For IndexOf = 1 To MetadataObjects.Count() - 1 Do
		StandardAttributes = AttributesIntersection(StandardAttributes, MetadataObjects[IndexOf].StandardAttributes);
	EndDo;
	For Each Attribute In StandardAttributes Do // StandardAttributeDescription
		If Attribute.Name = "PredefinedDataName"
			Or Attribute.Name = "Predefined"
			Or Attribute.Name = "DeletionMark" Then
			Continue;
		EndIf;
		CommonAttributesList.Add(Attribute);
	EndDo;
	
	Result.Attributes = ItemsList(CommonAttributesList);
	
	TabularSections = ItemsList(MetadataObjects[0].TabularSections);
	For IndexOf = 1 To MetadataObjects.Count() - 1 Do
		TabularSections = SetIntersection(TabularSections, ItemsList(MetadataObjects[IndexOf].TabularSections));
	EndDo;
	
	For Each TabularSectionName In TabularSections Do
		TabularSectionAttributes = ItemsList(MetadataObjects[0].TabularSections[TabularSectionName].Attributes, False);
		For IndexOf = 1 To MetadataObjects.Count() - 1 Do
			TabularSectionAttributes = AttributesIntersection(TabularSectionAttributes, MetadataObjects[IndexOf].TabularSections[TabularSectionName].Attributes);
		EndDo;
		If TabularSectionAttributes.Count() > 0 Then
			Result.TabularSections.Insert(TabularSectionName, ItemsList(TabularSectionAttributes));
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function SetIntersection(Set1, Set2) Export
	
	IndexOf = New Map;
	For Each Item In Set1 Do
		IndexOf[Item] = False;
	EndDo;
	
	For Each Item In Set2 Do
		If IndexOf[Item] <> Undefined Then
			IndexOf[Item] = True;
		EndIf;
	EndDo;

	Result = New Array;

	For Each Item In Set1 Do
		If IndexOf[Item] = True Then
			Result.Add(Item);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function AttributesIntersection(AttributesCollection1, AttributesCollection2)
	
	Result = New Array;
	
	For Each Attribute2 In AttributesCollection2 Do
		For Each Attribute1 In AttributesCollection1 Do
			If Attribute1.Name = Attribute2.Name 
				And (Attribute1.Type = Attribute2.Type Or Attribute1.Name = "Ref") Then
				Result.Add(Attribute1);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
//   Collection - Array of MetadataObjectAttribute
//             - Array of MetadataObjectTabularSection
//   NamesOnly - Boolean
// Returns:
//   Array
//
Function ItemsList(Collection, NamesOnly = True)
	Result = New Array;
	For Each Item In Collection Do
		If NamesOnly Then
			Result.Add(Item.Name);
		Else
			Result.Add(Item);
		EndIf;
	EndDo;
	Return Result;
EndFunction

Function ThisInfobaseName()
	
	SetPrivilegedMode(True);
	Result = Constants.SystemTitle.Get();
	Return ?(IsBlankString(Result), Metadata.Synonym, Result);
	
EndFunction

Procedure AddPrintCommands(PrintCommands, MetadataObject)
	
	Owner = Common.MetadataObjectID(MetadataObject, False);
	If Owner = Undefined Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	PrintFormTemplates.Id,
	|	PrintFormTemplates.Presentation AS Presentation,
	|	PrintFormTemplates.VisibilityCondition AS VisibilityConditions
	|FROM
	|	Catalog.PrintFormTemplates.DataSources AS PrintFormTemplatesDataSources
	|		LEFT JOIN Catalog.PrintFormTemplates AS PrintFormTemplates
	|		ON PrintFormTemplatesDataSources.Ref = PrintFormTemplates.Ref
	|WHERE
	|	PrintFormTemplatesDataSources.DataSource = &Owner
	|	AND PrintFormTemplates.Used
	|	AND NOT PrintFormTemplates.DeletionMark";
	
	Query = New Query(QueryText);
	Query.SetParameter("Owner", Owner);
	Selection = Query.Execute().Select();

	While Selection.Next() Do
		PrintCommand = PrintCommands.Add();
		FillPropertyValues(PrintCommand, Selection);
		PrintCommand.Id = "PF_" + String(PrintCommand.Id);
		PrintCommand.PrintManager = PrintModuleName();
		
		VisibilityConditions = Selection.VisibilityConditions.Get();
		If ValueIsFilled(VisibilityConditions) Then
			For Each Condition In VisibilityConditions Do
				AttachableCommands.AddCommandVisibilityCondition(PrintCommand, Condition.Attribute, Condition.Value, Condition.ComparisonType); 
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

Function DefaultFormat(TypeDescription)
	
	Format = "";
	If TypeDescription = Undefined Or TypeDescription.Types().Count() <> 1 Then
		Return Format;
	EndIf;
	
	Type = TypeDescription.Types()[0];
	
	If Type = Type("Number") Then
		Format = StrTemplate("ND=%1; NFD=%2",
			TypeDescription.NumberQualifiers.Digits,
			TypeDescription.NumberQualifiers.FractionDigits);
	ElsIf Type = Type("Date") Then
		If TypeDescription.DateQualifiers.DateFractions = DateFractions.Date Then
			Format = "DLF=D";
		Else
			Format = "DLF=DT";
		EndIf;
	ElsIf Type = Type("Boolean") Then
		Format = NStr("en = 'BF=No; BT=Yes';");
	EndIf;
	
	Return Format;
	
EndFunction

Function LayoutDiagramOfDataFromTheValueTable(ValueTable)
	
	Return FormulasConstructorInternal.LayoutDiagramOfDataFromTheValueTable(ValueTable);
	
EndFunction

Function DataLayoutSchemeFromTheValueTree(ValueTree)
	
	Return FormulasConstructorInternal.DataLayoutSchemeFromTheValueTree(ValueTree);
	
EndFunction

Function PictureFromFile(File)
	
	Result = New Picture;
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
		ModuleFilesOperations = Common.CommonModule("FilesOperations");

		AttachedFilesTypes = ModuleFilesOperationsInternal.AttachedFilesTypes();
		If ValueIsFilled(File) And AttachedFilesTypes.ContainsType(TypeOf(File)) Then
			BinaryData = ModuleFilesOperations.FileBinaryData(File, False);
			If BinaryData <> Undefined Then
				Result = New Picture(BinaryData, True);
			EndIf;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns:
//  SpreadsheetDocument, BinaryData - 
//
Function TemplatePresentation(TemplatePath, LanguageCode)
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Template ""%1"" does not exist. The operation is canceled.';"), TemplatePath);
	PathParts = StrSplit(TemplatePath, ".", True);
	
	FoundTemplate = Catalogs.PrintFormTemplates.RefTemplate(TemplatePath);
	If FoundTemplate <> Undefined Then
		Return String(FoundTemplate);
	EndIf;

	If PathParts.Count() <> 2 And PathParts.Count() <> 3 Then
		Raise ErrorText;
	EndIf;
	
	TemplateName = PathParts[PathParts.UBound()];
	PathParts.Delete(PathParts.UBound());
	ObjectName = StrConcat(PathParts, ".");
	
	SearchNames = TemplateNames(TemplateName, LanguageCode);
	IsCommonTemplate = StrSplit(ObjectName, ".").Count() = 1;
	TemplatesCollection = Metadata.CommonTemplates;
	
	If Not IsCommonTemplate Then
		MetadataObject = Common.MetadataObjectByFullName(ObjectName);
		If MetadataObject = Undefined Then
			Raise ErrorText;
		EndIf;
		TemplatesCollection = MetadataObject.Templates;
	EndIf;
	
	For Each SearchName In SearchNames Do
		FoundTemplate = TemplatesCollection.Find(SearchName);
		If FoundTemplate <> Undefined Then
			Return FoundTemplate.Presentation();
		EndIf;
	EndDo;
	
	Raise ErrorText;
	
EndFunction

Function AvailableforTranslationLayouts() Export
	
	AvailableforTranslationLayouts = New Map;
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		AvailableforTranslationLayouts = PrintManagementModuleNationalLanguageSupport.AvailableforTranslationLayouts();
	EndIf;
	
	Return AvailableforTranslationLayouts;
	
EndFunction

Function AvailableTranslationLayout(TemplatePath) Export
	
	ObjectMetadataLayout = ObjectMetadataLayout(TemplatePath);
	If ObjectMetadataLayout = Undefined Then
		Return True;
	EndIf;
	
	Return AvailableforTranslationLayouts()[ObjectMetadataLayout] = True;
	
EndFunction

Function DataLayoutSchemaContactInformation(MetadataObjectName)
	
	ContactInformationKinds = Undefined;
	
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManager = Common.CommonModule("ContactsManager");

		ContactInformationKinds = ModuleContactsManager.ObjectContactInformationKinds(
			Common.ObjectManagerByFullName(MetadataObjectName).EmptyRef());
	EndIf;
	
	If Not ValueIsFilled(ContactInformationKinds) Then
		Return Undefined;
	EndIf;
		
	FieldList = PrintDataFieldTable();
	
	Field = FieldList.Add();
	Field.Id = "Ref";
	Field.Presentation = NStr("en = 'Ref';");
	Field.ValueType = New TypeDescription();	

	For Each ContactInformationKind In ContactInformationKinds Do
		If Not ValueIsFilled(ContactInformationKind.IDForFormulas) Then
			Continue;
		EndIf;

		Field = FieldList.Add();
		Field.Id = ContactInformationKind.IDForFormulas;
		Field.Presentation = ContactInformationKind.Description;
		Field.ValueType = New TypeDescription("String");
	EndDo;
	
	If FieldList.Count() = 1 Then
		Return Undefined;
	EndIf;
	
	Return SchemaCompositionDataPrint(FieldList);
	
EndFunction

Function LayoutSchemeDataAdditionalDetailsAndDetails(MetadataObjectName)
	
	FieldList = PrintDataFieldTable();
	FieldList.Columns.Add("Property");
	
	PropertiesKinds = New Array;
	PropertiesKinds.Add("AdditionalAttributes");
	PropertiesKinds.Add("AdditionalInfo");
	
	ModulePropertyManagerInternal = Common.CommonModule("PropertyManagerInternal");
	If ModulePropertyManagerInternal <> Undefined Then
		For Each PropertyKind1 In PropertiesKinds Do
			ListOfProperties = ModulePropertyManagerInternal.PropertiesListForObjectsKind(MetadataObjectName, PropertyKind1);
			If ListOfProperties <> Undefined Then
				For Each Item In ListOfProperties Do
					Field = FieldList.Add();
					Field.Property = Item.Property;
					Field.Presentation = Item.Description;
					Field.ValueType = Item.ValueType;
					Field.Format = Item.FormatProperties;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	Properties = FieldList.UnloadColumn("Property");
	
	If Properties.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	IdentifiersForFormulas = Common.ObjectsAttributeValue(Properties, "IDForFormulas");
	
	For Each TableRow In FieldList Do
		TableRow.Id = IdentifiersForFormulas[TableRow.Property];
	EndDo;
	
	Field = FieldList.Add();
	Field.Id = "Ref";
	Field.Presentation = NStr("en = 'Ref';");
	Field.ValueType = New TypeDescription();	

	Return SchemaCompositionDataPrint(FieldList);
	
EndFunction

// 
//
Function ContactInformation(DataSources, DataCompositionSchemaId, LanguageCode, AdditionalParameters)
	
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManager = Common.CommonModule("ContactsManager");
	Else
		Return Undefined;
	EndIf;
	
	If Not StrEndsWith(DataCompositionSchemaId, "ContactInformation") Then
		Return Undefined;
	EndIf;
	
	StringParts1 = StrSplit(DataCompositionSchemaId, ".", True);
	StringParts1.Delete(StringParts1.UBound());
	
	MetadataObjectName = StrConcat(StringParts1, ".");
	
	Data = New ValueTable();
	Data.Columns.Add("Ref");
	
	ObjectContactInformationKinds = ModuleContactsManager.ObjectContactInformationKinds(
		Common.ObjectManagerByFullName(MetadataObjectName).EmptyRef());
		
	IdentifiersForFormulas = New Map();
	For Each ContactInformationKind In ObjectContactInformationKinds Do
		Id = ContactInformationKind.IDForFormulas;
		If Not ValueIsFilled(Id) Then
			Continue;
		EndIf;
		IdentifiersForFormulas.Insert(ContactInformationKind.Ref, Id);
		Data.Columns.Add(Id);
	EndDo;
	
	Owners = New Array;
	For Each DataSourceDescription In AdditionalParameters.DataSourceDescriptions Do
		Owner = DataSourceDescription.Owner;
		If ValueIsFilled(Owner) And Common.IsReference(TypeOf(Owner))
			And Common.IsDocument(Owner.Metadata()) Then
			Owners.Add(Owner);
		EndIf;
	EndDo;
	
	If ValueIsFilled(Owners) Then
		AdditionalParameters.SourceDataGroupedByDataSourceOwner = True;
		DataSources = Owners;
	EndIf;
	
	DatesDetails = Common.ObjectsAttributeValue(Owners, "Date");
	
	For Each DataSourceDescription In AdditionalParameters.DataSourceDescriptions Do
		Object = DataSourceDescription.Value;
		
		TableRow = Data.Add();
		TableRow.Ref = Object;
		If AdditionalParameters.SourceDataGroupedByDataSourceOwner Then
			TableRow.Ref = DataSourceDescription.Owner;
		EndIf;
		
		DateOfLastEdit = DatesDetails[DataSourceDescription.Owner];
		If Not ValueIsFilled(DateOfLastEdit) Then
			DateOfLastEdit = CurrentSessionDate();
		EndIf;
		
		Filter = ModuleContactsManager.FilterContactInformation3();
		Filter.LanguageCode = LanguageCode;
		Filter.Date = DateOfLastEdit;

		ObjectsContactInformation = ModuleContactsManager.ContactInformation(
			CommonClientServer.ValueInArray(Object), Filter);
		
		For Each ObjectContactInformation In ObjectsContactInformation Do
			Id = IdentifiersForFormulas[ObjectContactInformation.Kind];
			If Not ValueIsFilled(Id) Then
				Continue;
			EndIf;
	
			TableRow[Id] = ObjectContactInformation.Presentation;
		EndDo;

	EndDo;
	
	Return Data;
	
EndFunction

// 
//
Function AdditionalAttributesAndInfo(Objects, DataCompositionSchemaId, LanguageCode)
	
	Data = New ValueTable();
	Data.Columns.Add("Ref");
	
	If Not Common.SubsystemExists("StandardSubsystems.Properties") Then
		Return Data;
	EndIf;
	
	If Not StrEndsWith(DataCompositionSchemaId, "AdditionalAttributesAndInfo") Then
		Return Undefined;
	EndIf;
	
	StringParts1 = StrSplit(DataCompositionSchemaId, ".", True);
	StringParts1.Delete(StringParts1.UBound());
	
	MetadataObjectName = StrConcat(StringParts1, ".");
	
	PropertiesKinds = New Array;
	PropertiesKinds.Add("AdditionalAttributes");
	PropertiesKinds.Add("AdditionalInfo");
	
	ListOfProperties = New Array;
	
	ModulePropertyManagerInternal = Common.CommonModule("PropertyManagerInternal");
	For Each PropertyKind1 In PropertiesKinds Do
		Properties = ModulePropertyManagerInternal.PropertiesListForObjectsKind(MetadataObjectName, PropertyKind1).UnloadColumn("Property");
		CommonClientServer.SupplementArray(ListOfProperties, Properties);
	EndDo;
	
	IdentifiersForFormulas = Common.ObjectsAttributeValue(ListOfProperties, "IDForFormulas");
	
	For Each Property In ListOfProperties Do
		Id = IdentifiersForFormulas[Property];
		If Not ValueIsFilled(Id) Then
			Continue;
		EndIf;
		
		Data.Columns.Add(Id);
	EndDo;
	
	For Each Object In Objects Do
		TableRow = Data.Add();
		TableRow.Ref = Object;
	EndDo;
	
	ModulePropertyManager = Common.CommonModule("PropertyManager");
	ObjectsPropertiesValues = ModulePropertyManager.PropertiesValues(Objects, , , , LanguageCode);
	
	For Each ObjectPropertiesValues In ObjectsPropertiesValues Do
		Property = ObjectPropertiesValues.Property;
		Object = ObjectPropertiesValues.PropertiesOwner;

		FoundRows = Data.FindRows(New Structure("Ref", Object));
		For Each TableRow In FoundRows Do
			TableRow[IdentifiersForFormulas[Property]] = ObjectPropertiesValues.Value;
		EndDo;
	EndDo;
	
	Return Data;

EndFunction

Function LatinString(String) Export
	
	Return StringFunctions.LatinString(String);
		
EndFunction

Function PrintDataCharacterCase(Objects)
	
	PrintData = New ValueTable();
	PrintData.Columns.Add("Ref");
	PrintData.Columns.Add("AllCaps");
	PrintData.Columns.Add("AllLiners");
	
	For Each Object In Objects Do
		NewRow = PrintData.Add();
		NewRow.Ref = Object;
		NewRow.AllCaps = Upper(Object);
		NewRow.AllLiners = Lower(Object);
	EndDo;
	
	Return PrintData;
	
EndFunction

Procedure PrepareConditionalAreasNodes(XMLTree, Hyperlinks)
	SortTable = New ValueTable();
	SortTable.Columns.Add("Key");
	SortTable.Columns.Add("Value");
	SortTable.Columns.Add("Length");
	
	WholeText = XMLTree.Rows[0].WholeText;
	NameTag = TagNameCondition();
	
	
	TextFragments = StrSplit(WholeText, "{", False);
	For Each TextFragment In TextFragments Do
		TagNamePosition = StrFind(TextFragment, NameTag);
		If TagNamePosition And TagNamePosition < 3 Then
			StringFragments = StrSplit(TextFragment, "}", False);
									
			NewRow = SortTable.Add();
			NewRow.Key 		= "{"+StringFragments[0]+"}";
			NewRow.Length 		= NewRow.Key;
			NewRow.Value 	= NewRow.Key;
		EndIf;
	EndDo;
	
	SortTable.Sort("Length Desc");
	AllConditionsNodes = New Array;
	
	ConditionsNodes = New Array;
	For Each ReplacementCompliance In SortTable Do
		ConditionsNodes.Clear(); 
		PrintManagementInternal.FindNodes(XMLTree, ReplacementCompliance.Key, ConditionsNodes);

		For Each Node In ConditionsNodes Do
			If Node.Rows.Count() Then
				CollectStrings(Node);
				PrintManagementInternal.RestoreFullText(Node, Hyperlinks);
			EndIf;
		EndDo;
		CommonClientServer.SupplementArray(AllConditionsNodes, ConditionsNodes, True);
	EndDo;
	
	NodeFragments = New Array;
	For Each ConditionNode In AllConditionsNodes Do
		NodeFragments.Clear();
		TextFragments = StrSplit(ConditionNode.Text, "{", False);
		For Each TextFragment In TextFragments Do
			TagNamePosition = StrFind(TextFragment, NameTag);
			If TagNamePosition And TagNamePosition < 3 Then
				StringFragments = StrSplit(TextFragment, "}", False);
				
				NodeFragments.Add("{"+StringFragments[0]+"}");
				For FragmentIndex = 1 To StringFragments.UBound() Do
					NodeFragments.Add(StringFragments[FragmentIndex]);
				EndDo;
			Else
				NodeFragments.Add(TextFragment);
			EndIf;
		EndDo;
		SeparateRunThrough(ConditionNode, NodeFragments, Hyperlinks);
	EndDo;
EndProcedure

Procedure SeparateRunThrough(ConditionNode, NodeFragments, Hyperlinks)
	ParentOfAddition = ConditionNode.Parent;
	AdditingIndex = ParentOfAddition.Rows.IndexOf(ConditionNode);
	For NodeFragmentIndex = 0 To NodeFragments.UBound() Do
		
		If NodeFragmentIndex = 0 Then
			NodeForProcessing = ConditionNode;
		Else
			NodeForProcessing = PrintManagementInternal.MakeCopyNode(ParentOfAddition, AdditingIndex, ConditionNode);
		EndIf;
		AdditingIndex = AdditingIndex + 1;
		
		NodeForProcessing.Text = NodeFragments[NodeFragmentIndex];
	EndDo;
	PrintManagementInternal.RestoreFullText(ParentOfAddition, Hyperlinks);
EndProcedure

Function CollectStrings(Node, AssemblyNode = Undefined, AssemblyNodes = Undefined,  OpenedCount = 0)
	
	If Node.NameTag =	"w:t" Then
	
		ArrayOfFragments = StrSplit(Node.Text, "[{", True);
		NodeText = Node.Text;		
		OpeningCount = ArrayOfFragments.UBound();
		ClosingCount = 0; 
			
		For Each StartFragment In ArrayOfFragments Do
			StartFragment = StrSplit(StartFragment, "}]", True);
			ClosingCount = ClosingCount + StartFragment.UBound();
		EndDo;
		
		If AssemblyNode = Undefined Then
			If OpeningCount > 0 Then
				AssemblyNode = Node;
				AssemblyNode.Text ="";
				If AssemblyNodes = Undefined Then
					AssemblyNodes = New Array();
				EndIf;
				AssemblyNodes.Add(Node);
			EndIf;
		Else
			Node.Text = "";
		EndIf;
						
		If AssemblyNode = Undefined Then
			Node.Text = NodeText;
		Else						
			AssemblyNode.Text = AssemblyNode.Text + NodeText;
		EndIf; 
				
		If AssemblyNode <> Undefined And OpenedCount + OpeningCount - ClosingCount = 0 Then
			AssemblyNode = Undefined;
		EndIf;
		
		OpenedCount = OpenedCount + OpeningCount - ClosingCount;
	Else
		For Each NodeRow In Node.Rows Do
			CollectStrings(NodeRow, AssemblyNode, AssemblyNodes, OpenedCount);			
		EndDo;
	EndIf;
	Return AssemblyNodes;
EndFunction

Function CopyOfTemplateTree(TreeOfTemplate)
	TemplateTreeForPopulation = Common.CopyRecursive(TreeOfTemplate);
	DirDestination = FileSystem.CreateTemporaryDirectory();
	DocumentStructure = TemplateTreeForPopulation.DocumentStructure;
	PicturesDirectory = DocumentStructure.PicturesDirectory;
	PicturesDirectory = StrReplace(PicturesDirectory, TemplateTreeForPopulation.DirectoryName, DirDestination);
	SourceDir = TemplateTreeForPopulation.DirectoryName;
	TemplateTreeForPopulation.DirectoryName = DirDestination;
	DocumentStructure.PicturesDirectory = PicturesDirectory;
	PrintManagementInternal.CopyDirectoryContent(SourceDir, DirDestination);
	TemplateTreeForPopulation.Insert("AreasForOutput", New Array);
	Return TemplateTreeForPopulation;
EndFunction

Function GetObjectParametersValues(PrintData, PrintObject, TreeOfTemplate, LanguageCode, PrintParameters, TextParameters)
	
	ObjectData = PrintData[PrintObject];
	FieldFormatSettings = PrintData["FieldFormatSettings"];
	
	MatchingOfString = New Map();
	For Each AreaParameter In TextParameters Do
		Presentation = SetPresentationPicture(LanguageCode, AreaParameter, FieldFormatSettings, ObjectData, PrintParameters);
		MatchingOfString.Insert(AreaParameter, Presentation);
	EndDo;
	Return MatchingOfString;
		
EndFunction

Function GetAreaData(PrintData, PrintObject, Area, TreeOfTemplate, LanguageCode, PrintParameters)
	
	FieldFormatSettings = PrintData["FieldFormatSettings"];
	Result = New Array();
	
	ArrayOfAreaParameters = Area.Parameters;
	
	Ref = PrintObject;
	TableName = Area.Collection;
	
	RowsMap = PrintData[Ref][TableName];
	If RowsMap <> Undefined Then
		For TabularSectionRowNumber = 1 To RowsMap.Count() Do
			DataSource = New Map;
			CommonClientServer.SupplementMap(DataSource, PrintData[Ref]);
			If ValueIsFilled(TableName) Then
				DataOfTablePartRow = PrintData[Ref][TableName][TabularSectionRowNumber];
				For Each KeyAndValue In DataOfTablePartRow Do
					DataSource[TableName + "." + KeyAndValue.Key] = KeyAndValue.Value;
				EndDo;
			EndIf;
			
			MatchingOfString = Common.CopyRecursive(DataSource);
			For Each AreaParameter In ArrayOfAreaParameters Do
				
				Presentation = SetPresentationPicture(LanguageCode, AreaParameter, FieldFormatSettings, DataSource, PrintParameters);
				MatchingOfString.Insert(AreaParameter, Presentation);
				
			EndDo;
			
			Result.Add(MatchingOfString);
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

Function SetPresentationPicture(LanguageCode, AreaParameter, FieldFormatSettings, Source, PrintParameters)
	
	TextParameters = FindParametersInText(String(AreaParameter));
	ParameterValues = ParameterValues(TextParameters, Source, FieldFormatSettings, LanguageCode);
	Presentation = AreaParameter;
	FirstParameterVal = ParameterValues[TextParameters[0]];
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
		TypeAttachment = ModuleFilesOperationsInternal.AttachedFilesTypes();
	Else
		TypeAttachment = New TypeDescription();
	EndIf;
	
	If FirstParameterVal <> Undefined And TypeAttachment.ContainsType(TypeOf(FirstParameterVal)) Then 
		If ValueIsFilled(FirstParameterVal) Then
			Presentation = New Structure("Width,Height,PictureAddress");
			
			If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
				ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
				ModuleFilesOperations = Common.CommonModule("FilesOperations");

				AttachedFilesTypes = ModuleFilesOperationsInternal.AttachedFilesTypes();
				If ValueIsFilled(FirstParameterVal) And AttachedFilesTypes.ContainsType(TypeOf(FirstParameterVal)) Then
					BinaryData = ModuleFilesOperations.FileBinaryData(FirstParameterVal, False);
					Presentation.PictureAddress = PutToTempStorage(BinaryData, New UUID());
				EndIf;
			EndIf;
			
			ShouldShowSignatureAndStamp = Undefined;
			PrintParameters.Property("SignatureAndSeal", ShouldShowSignatureAndStamp);
			
			If StrFind(TextParameters[0], "Signature") Then
				If ShouldShowSignatureAndStamp = False Then
					Presentation.PictureAddress = "";
				EndIf;
				Presentation.Width = 30;
				Presentation.Height = 10;
			ElsIf StrFind(TextParameters[0], "Print") Then
				If ShouldShowSignatureAndStamp = False Then
					Presentation.PictureAddress = "";
				EndIf;
				Presentation.Width = 40;
				Presentation.Height = 40;
			EndIf;
		Else
			Presentation = "";
		EndIf;
	ElsIf TypeOf(FirstParameterVal) = Type("Picture") Then
		If ValueIsFilled(FirstParameterVal) Then
			Presentation = New Structure("Width,Height,PictureAddress");
			BinaryData = FirstParameterVal.GetBinaryData();
			Presentation.PictureAddress = PutToTempStorage(BinaryData, New UUID());
		EndIf;
	Else
		Presentation = ReplaceInline(AreaParameter, ParameterValues);
	EndIf;
	
	Return Presentation;
	
EndFunction

Procedure AddAnOperatorToAGroup(Group, Id, Val Presentation = Undefined, Type = Undefined, IsFunction = False)
	
	If Presentation = Undefined Then
		Presentation = Id;
	EndIf;
	
	Operator = Group.Rows.Add();
	Operator.Id = Id;
	If StrSplit(Presentation, " ").Count() > 1 Then
		Operator.Presentation = StrReplace(Title(Presentation), " ", "");
	Else
		Operator.Presentation = Presentation;
	EndIf;
	Operator.ValueType = Type;
	Operator.Picture = PictureLib.IsEmpty;
	Operator.IsFunction = IsFunction;

EndProcedure

// 
// 
// Parameters:
//  ParameterValues - See SpecifyParameters.ParameterValues
//  XMLTree - See PrintManagementInternal.ReadXMLIntoTree
//  TreeOfTemplate - See InitializeTemplateOfDCSOfficeDoc
//  ShouldAddLinks - Boolean - 
//
Procedure SetParametersInTree(Val ParameterValues, XMLTree, TreeOfTemplate = Undefined, ShouldAddLinks = True)
	
	SortTable = New ValueTable();
	SortTable.Columns.Add("Key");
	SortTable.Columns.Add("Value");
	SortTable.Columns.Add("Length");
	For Each ReplacementCompliance In ParameterValues Do
		NewRow = SortTable.Add();
		NewRow.Key 		= ReplacementCompliance.Key;
		NewRow.Length 		= StrLen(ReplacementCompliance.Key);
		NewRow.Value 	= ReplacementCompliance.Value;
	EndDo;
	
	SortTable.Sort("Length Desc");
	
	For Each ReplacementCompliance In SortTable Do
		NodesArray = New Array; 
		PrintManagementInternal.FindNodes(XMLTree, ReplacementCompliance.Key, NodesArray);
		
		For Each Node In NodesArray Do
			If Node.Rows.Count() = 0 Or Node.NameTag = "w:hyperlink" Then
				PrintManagementInternal.AssignValToDoc(Node, ReplacementCompliance, TreeOfTemplate, ShouldAddLinks);
			Else
				ArrayOfCollectedNodes = CollectStrings(Node);
				If ArrayOfCollectedNodes = Undefined Then
					Continue;
				EndIf;
				
				For Each CollectedNode In ArrayOfCollectedNodes Do
					PrintManagementInternal.AssignValToDoc(CollectedNode, ReplacementCompliance, TreeOfTemplate, ShouldAddLinks);
				EndDo;
			EndIf;
		EndDo;
		
	EndDo;

EndProcedure

// Parameters:
//  FieldsCollection - See FormulasConstructor.FieldsCollection
//
Function CollectionFields(FieldsCollection)
	
	Result = New Array;
	
	For Each FieldDetails In FieldsCollection.Items Do
		Result.Add(FieldDetails.Field);
		If FieldDetails.Folder Or FieldDetails.Table Then
			CommonClientServer.SupplementArray(Result, CollectionFields(FieldDetails)); 
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function CollectionOfFieldsCommonAttributes()
	
	Return FormulasConstructor.FieldsCollection(GetCommonTemplate("PrintDataCommonAttributes"));

EndFunction

Function GetSkippedParent(AddLine, TreeForOutput)
	Parents = New Array;
	FindSkippedParents(Parents, TreeForOutput, AddLine);
	ParentOfAddition = TreeForOutput.Rows.Find(Parents[0].Parent.IndexOf, "IndexOf", True);  
	AdditingIndex = Parents[0].Parent.Rows.IndexOf(Parents[0]); 
	
	For Each Parent In Parents Do
		ParentOfAddition = PrintManagementInternal.MakeCopyNode(ParentOfAddition, AdditingIndex, Parent);
		AdditingIndex = 0;
	EndDo;
	
	Return ParentOfAddition;
EndFunction

Procedure FindSkippedParents(Parents, TreeForOutput, AddLine)
	If TreeForOutput.Rows.Find(AddLine.Parent.IndexOf, "IndexOf", True) = Undefined Then
		Parents.Insert(0, AddLine.Parent);
		FindSkippedParents(Parents, TreeForOutput, AddLine.Parent);
	EndIf;
EndProcedure

Function PutToStorages(ParametersStructure, StoragesContents, StorageUUID)
	If StoragesContents.Count() = 0 Then
		Return False;
	EndIf;
	
	ParametersType = TypeOf(ParametersStructure);
	If ParametersType = Type("String") And IsTempStorageURL(ParametersStructure) Then
		ParametersStructure = PutToTempStorage(StoragesContents[ParametersStructure], StorageUUID);
		Return True;
	ElsIf ParametersType = Type("Array") Then
		For IndexOf = 0 To ParametersStructure.UBound() Do
			Item = ParametersStructure[IndexOf];
			PutToStorages(Item, StoragesContents, StorageUUID);
			ParametersStructure[IndexOf] = Item;
		EndDo;
	ElsIf ParametersType = Type("ValueTable") Or ParametersType = Type("ValueTableRow") 
		Or ParametersType = Type("ValueTreeRow") Then
		
		For Each Item In ParametersStructure Do
			PutToStorages(Item, StoragesContents, StorageUUID);
		EndDo;
	ElsIf ParametersType = Type("Structure") Or ParametersType = Type("Map") Then
		
		NewStorageAddresses = New Map;
		For Each Item In ParametersStructure Do
			CollectionValue = Item.Value;
			If PutToStorages(CollectionValue, StoragesContents, StorageUUID) Then
				NewStorageAddresses.Insert(Item.Key, CollectionValue);
			EndIf;
		EndDo;
		
		For Each NewAddress In NewStorageAddresses Do
			ParametersStructure.Insert(NewAddress.Key, NewAddress.Value);
		EndDo;
				
	ElsIf  ParametersType = Type("ValueTree") Then
		For Each Item In ParametersStructure.Rows Do
			PutToStorages(Item, StoragesContents, StorageUUID);
		EndDo;
	EndIf;
	Return False;
EndFunction

Procedure AddGroupOfFunctionOperatorsForTables(ListOfOperators)
	Group = ListOfOperators.Rows.Add();
	Group.Id = "TableFunctions";
	Group.Presentation = NStr("en = 'Functions for tables';");
	Group.Order = 5;
	Group.Picture = PictureLib.TypeFunction;
	
	Type = New TypeDescription("Number");
	
	Prefix = PrintModuleName() + CommandSeparator();
	
	AddAnOperatorToAGroup(Group, Prefix + "SumByColumn", NStr("en = 'Column sum';"), Type, True);
	AddAnOperatorToAGroup(Group, Prefix + "RowsCount", NStr("en = 'Number of rows';"), Type, True);
	AddAnOperatorToAGroup(Group, Prefix + "ColumnMax", NStr("en = 'Column max';"), Type, True);
	AddAnOperatorToAGroup(Group, Prefix + "ColumnMin", NStr("en = 'Column min';"), Type, True);
	AddAnOperatorToAGroup(Group, Prefix + "ColumnAverage", NStr("en = 'Column average';"), Type, True);
	
EndProcedure

Procedure RememberLastUsedTemplate(TemplatePath)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Common.CommonSettingsStorageSave("Print", "LastUsedTemplate", TemplatePath);
	
EndProcedure

Function LastUsedTemplate()
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Return Common.CommonSettingsStorageLoad("Print", "LastUsedTemplate", Undefined);
	
EndFunction

Procedure ClearLastUsedTemplate()
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Common.CommonSettingsStorageDelete("Print", "LastUsedTemplate", Undefined);
	
EndProcedure

Procedure ProcessNestedAreas(RowAreaStructure, CurrentArea, CollectionItem, ObjectData, FieldFormatSettings, LanguageCode);
	If CurrentArea.NestedAreas <> Undefined Then
		ConditionsValue = New Map;
		RowsPrintData = New Map;
		For Each RowPrintData In CollectionItem Do
			RowsPrintData.Insert(ClearSquareBrackets(RowPrintData.Key), RowPrintData.Value);
		EndDo;
		
		SetSafeMode(True);
		For Each AreaCondition In CurrentArea.NestedAreas.UnloadColumn("AreaCondition") Do
			If ConditionsValue[AreaCondition] = Undefined Then
				OutputRegion = EvalExpression(AreaCondition, RowsPrintData, FieldFormatSettings, LanguageCode, False);
				ConditionsValue.Insert(AreaCondition, OutputRegion);
			EndIf;
		EndDo;
		SetSafeMode(False);
		
		NodesToDelete = New Array;
		For Each NestedArea In CurrentArea.NestedAreas Do
			If ConditionsValue[NestedArea.AreaCondition] = False Then
				AreaNode = RowAreaStructure.AreaTree.Rows.Find(NestedArea.IndexOf, "IndexOf", True);
				If AreaNode <> Undefined Then
					AreaNode.Parent.Rows.Delete(AreaNode);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

Function SingleSendButton(ChildItems)
	
	If ChildItems.Count() = 1 
		And TypeOf(ChildItems[0]) = Type("FormButton") Then
			Return ChildItems[0];
	EndIf;

	Return Undefined;
EndFunction

// Parameters:
//  Form - ClientApplicationForm
//  Cancel - Boolean
//  StandardProcessing - Boolean
//
Procedure PrintDocumentsOnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	SSLSubsystemsIntegration.PrintDocumentsOnCreateAtServer(Form, Cancel, StandardProcessing);
	PrintManagementOverridable.PrintDocumentsOnCreateAtServer(Form, Cancel, StandardProcessing);
	
	ProcessSendingCommands(Form);
	
EndProcedure

Procedure ProcessSendingCommands(Form)
			
	Items = Form.Items;
	ButtonSend = SingleSendButton(Items.SubmenuSend.ChildItems);
	If ButtonSend <> Undefined Then
		Items.Move(ButtonSend, Items.SubmenuSend.Parent, Items.SubmenuSend);
	EndIf;
	
	ButtonSend = SingleSendButton(Items.SubmenuSendAllActions.ChildItems);
	If ButtonSend <> Undefined Then
		Items.Move(ButtonSend, Items.SubmenuSendAllActions.Parent, Items.SubmenuSendAllActions);
	EndIf;
	
EndProcedure

#EndRegion
