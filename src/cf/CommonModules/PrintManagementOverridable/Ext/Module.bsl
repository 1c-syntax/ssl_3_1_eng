///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Overrides the subsystem settings.
//
// Parameters:
//  Settings - Structure:
//   * UseSignaturesAndSeals - Boolean -  setting the value to False disables the ability to set signatures 
//                                           and seals in printed forms.
//   * HideSignaturesAndSealsForEditing - Boolean -  delete drawings of signatures and seals of tabular documents when
//                                           you uncheck the "Signatures and seals" box in the "Print documents" form,
//                                           so that they do not interfere with editing the text below them.
//   * CheckPostingBeforePrint    - Boolean - 
//                                        
//                                        See PrintManagement.CreatePrintCommandsCollection.
//                                        
//                                        
//   * PrintObjects - Array - 
//
Procedure OnDefinePrintSettings(Settings) Export
	
	
	
EndProcedure

// Allows you to redefine the list of print commands in any form.
// It can be used for General forms that do not have a Manager module for placing the add command Print procedure in it,
// for cases when the standard tools for adding commands to such forms are not enough. 
// For example, if General forms require specific print commands.
// Called from the print Management function.Comodification.
// 
// Parameters:
//  FormName             - String -  full name of the form to add print commands to;
//  PrintCommands        - See PrintManagement.CreatePrintCommandsCollection
//  StandardProcessing - Boolean -  if set to False, the print Command collection will not be automatically populated.
//
// Example:
//  If Formname = " General Form.Journaldugeek" Then
//    If Users.Roles Are Available ("Printschetanaoplatunaprinter") Then
//      Command Print = Command Print.Add();
//      Print command.ID = " Invoice";
//      Print command.Submission = NSTR ("ru = 'Invoice for payment (to the printer)'");
//      Print command.Picture = Of Bibliotecarios.Print now;
//      Print command.Printoutcheck = True;
//      Print command.Casuarina = True;
//    Conicelli;
//  Conicelli;
//
Procedure BeforeAddPrintCommands(FormName, PrintCommands, StandardProcessing) Export
	
EndProcedure

// Allows you to set additional settings for print commands in document logs.
//
// Parameters:
//  ListSettings - Structure - :
//   * PrintCommandsManager     - CommonModule -  Manager of the object where the list of print commands is generated;
//   * AutoFilling - Boolean -  fill in print commands from objects that are part of the log.
//                                         If set to False, the list of log print commands will be
//                                         filled in by calling the add print Command method from the log Manager module.
//                                         The default value is True - the add print Command method will be called from
//                                         the document Manager modules that are part of the log.
//
// Example:
//   If The Settings Are Subscription.Managercommunity = "Journaldugeek.Warehouse Documents " Then
//     Astronomiska.Auto-Fill = False;
//   Conicelli;
//
Procedure OnGetPrintCommandListSettings(ListSettings) Export
	
EndProcedure

// Allows you to perform post-processing of printed forms during their formation.
// For example, you can insert the date of formation into the printed form.
// Called after the completion of the Print procedure of the object's print manager, it has the same parameters.
// Not called when the Print Client control is called.Print documents.
//
// Parameters:
//  ObjectsArray - Array of AnyRef -  list of objects for which the print command was executed;
//  PrintParameters - Structure -  custom parameters passed when calling the print command;
//  PrintFormsCollection - ValueTable - :
//   * TemplateName - String -  ID of the printed form;
//   * TemplateSynonym - String -  name of the printed form;
//
//   * SpreadsheetDocument - SpreadsheetDocument - 
//                         
//                         
//                         
//                         
//
//   * OfficeDocuments - Map of KeyAndValue - :
//                         ** Key - String -  address in the temporary storage of binary data of the printed form;
//                         ** Value - String -  name of the print form file.
//
//   * PrintFormFileName - String -  name of the print form file when saving to a file or sending as
//                                      an email attachment. It is not used for printed forms in the format of office documents.
//                                      By default, the file name is set in the format
//                                      " [PrintForm Name]  No. [number] from [date] "for documents,
//                                      " [PrintForm Name] - [Object view] - [current Date]" for objects.
//                           - Map of KeyAndValue - :
//                              ** Key - AnyRef -  reference to a print object from the array Object collection;
//                              ** Value - String -  file name;
//
//   * Copies2 - Number -  number of copies to print;
//   * FullTemplatePath - String -  used to quickly switch to editing the layout of the printed form
//                                  in the General form of Printdocuments;
//   * OutputInOtherLanguagesAvailable - Boolean -  it is necessary to set the value to True if the printed form is adapted
//                                            for output in an arbitrary language.
//  
//  PrintObjects - ValueList - 
//                                   
//                                   :
//   * Value - AnyRef -  link from the array Object collection,
//   * Presentation - String -  name of the area with the object in table documents;
//
//  OutputParameters - Structure - :
//   * SendOptions - Structure -  
//                                     :
//     ** Recipient - 
//     ** Subject       - 
//     ** Text      - 
//   * LanguageCode - String -  the language in which you want to create the printed form.
//                         It consists of the ISO 639-1 language code and, optionally, the ISO 3166-1 country code, separated
//                         by an underscore. Examples: "en", "en_US", "en_GB", "ru", "ru_RU".
//
//   * FormCaption - String -  overrides the title of the document printing form (Printdocuments).
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
//    
//  
//
Procedure OnPrint(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	
	
EndProcedure

// 
//
// Parameters:
//  PrintFormID - String -  ID of the printed form;
//  PrintObjects      - Array    -  collection of links to print objects;
//  PrintParameters - Structure -  custom parameters passed when calling the print command;
//
Procedure BeforePrint(Val PrintFormID, PrintObjects, PrintParameters) Export 
	
	
	
EndProcedure

// Overrides the parameters for sending printed forms when preparing a message.
// It can be used, for example, to prepare the text of a message.
//
// Parameters:
//  SendOptions - Structure:
//   * Recipient - Array -  collection of recipient names;
//   * Subject - String -  message subject;
//   * Text - String -  the text of the letter;
//   * Attachments - Structure:
//    ** AddressInTempStorage - String -  address of the attachment in temporary storage;
//    ** Presentation - String -  name of the attachment file.
//  PrintObjects - Array -  a collection of objects that are used for forming printed forms.
//  Output parameter-Structure-parameter of the output Parameter in the Print procedure call.
//  PrintForms - ValueTable - :
//   * Name1 - String -  name of the printed form;
//   * SpreadsheetDocument - SpreadsheetDocument - 
//
Procedure BeforeSendingByEmail(SendOptions, OutputParameters, PrintObjects, PrintForms) Export
	
	
	
EndProcedure

// Defines a set of signatures and seals for documents.
//
// Parameters:
//  Var_Documents      - Array    -  collection of links to print objects;
//  SignaturesAndSeals - Map of KeyAndValue - :
//   * Key     - AnyRef -  link to the print object;
//   * Value - Structure   - :
//     ** Key     - String -  ID of the signature or seal in the layout of the printed form, 
//                            must start with " Signature...", "Seal..." or " Facsimile...",
//                            for example, "signature of the Head", " seal of the Company";
//     ** Value - Picture -  image of the signature or seal.
//
Procedure OnGetSignaturesAndSeals(Var_Documents, SignaturesAndSeals) Export
	
	
	
EndProcedure

// Called from the handler for the append To the server of the document printing form (General Form.Print documents).
// Allows you to change the appearance and behavior of the form, for example, to place additional elements on it:
// information labels, buttons, hyperlinks, various settings, etc.
//
// When adding commands (buttons), specify the name "plug-In" as the handler._Execute the command",
// and place its implementation in the print Managementdefinable.Print documentsperforming the command (backend),
// or in the print Managementclientdefinable.Print documentsfill the command (client side).
//
// To add your team to the form, you need to do the following:
// 1. Create a command and a button in the print Managementdefinable.Printdocumentsreferences in the server.
// 2. Implement a client-side command handler in print Managementclientdefinable.Print documentsfill the command.
// 3. (Optional) Implement a server-side command handler in print Managementdefinable.Print documentsperformance of the command.
//
// When adding hyperlinks, the click handler should be named "Pluggable_processingavigation_link",
// and its implementation should be placed in the print Managementclientdefinable.Printdocumentsprocessingavigation links.
//
// When placing elements whose values should be remembered between opening the print form,
// use the Printdocumentsprizagruzedannyhiznadjustmentsserver and
// Printdocumentsreservationsreferences in the server.
//
// Parameters:
//  Form                - ClientApplicationForm -  General Form.Print documents.
//  Cancel                - Boolean -  indicates that the form was not created. If you set
//                                  this parameter to True, the form will not be created.
//  StandardProcessing - Boolean -  this parameter is passed to indicate that standard (system)
//                                  event processing is performed. If this parameter is set to False, 
//                                  standard event processing will not be performed.
// 
// Example:
//  Commandform = Form.Teams.Add("Vakomana");
//  Commandform.Action = " Plug-In_Execute the command";
//  Commandform.Title = NSTR ("ru = ' My team'");
//  
//  Button Forms = Form.Elements.Add (Command Forms.Name, Type ("Form Button"), Form.Elements.Amandaplease);
//  Form button.View = Widgettitle.Command panel buttons;
//  Form button.Named CommandName = Commandform.Name;
//
Procedure PrintDocumentsOnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	
	
EndProcedure

// Called from the preload handler for the Customizedconfigurationserver of the document printing form (General Form.Print documents).
// In conjunction with Printdocumentsreservingdannyconfigurationserver allows you to load and save 
// the settings of controls placed using Printdocumentscreationserver.
//
// Parameters:
//  Form     - ClientApplicationForm -  General Form.Print documents.
//  Settings - Map     -  the values of the details form.
//
Procedure PrintDocumentsOnImportDataFromSettingsAtServer(Form, Settings) Export
	
EndProcedure

// Called from the handler for saving the data in settings On the server of the document printing form (General Form.Print documents).
// Together with Printdocumentsprizagruzkedannyhiznadjustmentsserver allows you to load and save 
// the settings of controls placed using Printdocumentscreationsserver.
//
// Parameters:
//  Form     - ClientApplicationForm -  General Form.Print documents.
//  Settings - Map     -  the values of the details form.
//
Procedure PrintDocumentsOnSaveDataInSettingsAtServer(Form, Settings) Export

EndProcedure

// Called from the Plug-in handler_Execute the document printing form command (General Form.Print documents).
// Allows you to implement the server part of the command handler, which is added to the form 
// using Printdocumentscreationserver.
//
// Parameters:
//  Form                   - ClientApplicationForm -  General Form.Print documents.
//  AdditionalParameters - Arbitrary     -  parameters passed from the print Managementclientdefinable.Print documentsfill the command.
//
// Example:
//  If The Type Is LF(Additional Parameters) = Type ("Structure") And Additional Parameters.Named CommandName = "Vakomana" Then
//   Tablecellelement = New Tablecellelement;
//   Tabular document.Area ("R1C1").Text = NSTR ("ru =' Example of using a server handler for a connected command.'");
//  
//   Printable Form = Form[Additional parameters.Karekietenhof];
//   Printable form.Insert A Region (Tabular Document.Area ("R1"), Printable Form.Area ("R1"), 
//    Type of placementtabledocument.Polarizatio)
//  Conicelli;
//
Procedure PrintDocumentsOnExecuteCommand(Form, AdditionalParameters) Export
	
EndProcedure

// 
// 
// 
// 
//
// Parameters:
//  Object - String - 
//                      
//  PrintDataSources - ValueList:
//    * Value - DataCompositionSchema - 
//                                         
//                                         
//                                         
//                                         
//                                         
//      
//    * Presentation - String - 
//    * Check -Boolean - 
//
Procedure OnDefinePrintDataSources(Object, PrintDataSources) Export
	
	
	
EndProcedure

// 
//
// Parameters:
//  DataSources - Array - 
//  ExternalDataSets - Structure - 
//  DataCompositionSchemaId - String - 
//  LanguageCode - String - 
//  AdditionalParameters - Structure:
//   * DataSourceDescriptions - ValueTable - 
//   * SourceDataGroupedByDataSourceOwner - Boolean - 
//                           
//  
Procedure WhenPreparingPrintData(DataSources, ExternalDataSets, DataCompositionSchemaId, LanguageCode,
	AdditionalParameters) Export
	
	
	
EndProcedure

// 
//
// Parameters:
//   FullMetadataObjectName   - MetadataObject - 
//   PrintCommands 		- See PrintManagement.CreatePrintCommandsCollection
//
Procedure OnReceivePrintCommands(Val FullMetadataObjectName, PrintCommands) Export
	
	
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
// 
// 
//
// Parameters:
//  ListOfObjects - Array -  object managers with the add print Command procedure.
//
Procedure OnDefineObjectsWithPrintCommands(ListOfObjects) Export
		
EndProcedure

#EndRegion

#EndRegion

