///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Creates a message based on the subject based on the message template.
//
// Parameters:
//  Template                   - CatalogRef.MessageTemplates -  link to the message template.
//  SubjectOf                  - Arbitrary -  the object is the base for the message template. the object types are listed in
//                                            the subject type of the message Template that is being defined.
//  UUID  - UUID -  form ID required for placing attachments in
//                                            temporary storage during a client-server call. If the call
//                                            occurs only on the server, you can use any ID.
//  AdditionalParameters  - Structure - 
//                                         :
//      * DCSParametersValues - Structure - 
//                                            
//      * ConvertHTMLForFormattedDocument - Boolean -  optional, False by default, determines
//                      whether it is necessary to convert the HTML text of the message containing images to the text of the message due to the
//                      peculiarities of displaying images in a formatted document.
// 
// Returns:
//  Structure - :
//    * Subject - String -  message subject
//    * Text - String -  the text of the letter
//    * Recipient - ValueList - 
//                                    
//                 - Array of See NewEmailRecipients -  
//                   
//    * AdditionalParameters - Structure -  parameters of the message template.
//    * Attachments - ValueTable:
//       ** Presentation - String -  name of the attachment file.
//       ** AddressInTempStorage - String -  address of the attachment's binary data in temporary storage.
//       ** Encoding - String -  encoding of the attachment (used if it differs from the encoding of the message).
//       ** Id - String -  optional, attachment ID, used for storing 
//                                   images displayed in the message body.
//
Function GenerateMessage(Template, SubjectOf, UUID, AdditionalParameters = Undefined) Export

	SendOptions = GenerateSendOptions(Template, SubjectOf, UUID, AdditionalParameters);
	Return MessageTemplatesInternal.GenerateMessage(SendOptions);

EndFunction

// Sends an email or SMS message based on the subject using the message template.
//
// Parameters:
//  Template                   - CatalogRef.MessageTemplates -  link to the message template.
//  SubjectOf                  - Arbitrary -  the object is the base for the message template. the object types are listed in
//                                            the subject type of the message Template that is being defined.
//  UUID  - UUID -  ID of the form that is required for placing attachments in
//                                                       temporary storage.
//  AdditionalParameters  - See ParametersForSendingAMessageUsingATemplate
// 
// Returns:
//   See MessageTemplatesInternal.EmailSendingResult
//
Function GenerateMessageAndSend(Template, SubjectOf, UUID,
	AdditionalParameters = Undefined) Export

	SendOptions = GenerateSendOptions(Template, SubjectOf, UUID, AdditionalParameters);
	Return MessageTemplatesInternal.GenerateMessageAndSend(SendOptions);

EndFunction

// Returns a list of required additional parameters for the Generate Message and Send procedure.
// The list of parameters can be expanded, for end-to-end transmission as part of the Message parameter of the message
// formation procedures and subsequent use of their values when creating a message.
// 
// Returns:
//  Structure:
//   * ConvertHTMLForFormattedDocument - Boolean -  optional, False by default, determines
//                      whether the HTML text of a message containing images in the message text needs to be converted due to the
//                      way images are output in a formatted document.
//   * Account - Undefined
//                 - CatalogRef.EmailAccounts - 
//                       
//   * SendImmediately - Boolean -  if False, the email will be placed in the Outgoing folder 
//                                  and sent during the general sending of emails. Only when sending via Interaction.
//                                  The default value is False.
//   * DCSParametersValues - Structure - 
//                                         
//
Function ParametersForSendingAMessageUsingATemplate() Export

	AdditionalParameters  = New Structure;

	AdditionalParameters.Insert("ConvertHTMLForFormattedDocument", False);
	AdditionalParameters.Insert("Account", Undefined);
	AdditionalParameters.Insert("SendImmediately", False);
	AdditionalParameters.Insert("DCSParametersValues", New Structure);

	Return AdditionalParameters;

EndFunction

// 
//
// 	Parameters:
//    Attributes  - ValueTree -  a list of Bank details to fill in.
//    Template      - DataCompositionSchema -  the layout of the CDS.
//
Procedure GenerateAttributesListByDCS(Attributes, Template) Export
	
	MessageTemplatesInternal.AttributesByDCS(Attributes, Template);
	
EndProcedure

// Fills in the list of message template details based on the SKD layout.
//
// Parameters:
//  Attributes        - Map -  list of Bank details.
//  SubjectOf          - Arbitrary -  reference to the base object for the message template.
//  TemplateParameters - See TemplateParameters.
//
Procedure FillAttributesByDCS(Attributes, SubjectOf, TemplateParameters) Export
	MessageTemplatesInternal.FillAttributesByDCS(Attributes, SubjectOf, TemplateParameters);
EndProcedure

// Create a message template.
//
// Parameters:
//  Description     - String -  name of the template.
//  TemplateParameters - See MessageTemplates.TemplateParametersDetails
//
// Returns:
//  CatalogRef.MessageTemplates - 
//
Function CreateTemplate(Description, TemplateParameters) Export

	TemplateParameters.Insert("Description", Description);

	EventLogEventName = NStr("en = 'Create a message template';", Common.DefaultLanguageCode());

	BeginTransaction();
	Try

		Template = Catalogs.MessageTemplates.CreateItem();
		Template.Fill(TemplateParameters);

		If InfobaseUpdate.IsCallFromUpdateHandler() Then
			InfobaseUpdate.WriteData(Template, True);
		Else
			Template.Write();
		EndIf;

		If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then

			ModuleFilesOperations = Common.CommonModule("FilesOperations");

			If TemplateParameters.Attachments <> Undefined Then
				For Each Attachment In TemplateParameters.Attachments Do

					FileName = New File(Attachment.Key);

					AdditionalParameters = New Structure;
					AdditionalParameters.Insert("Description", FileName.BaseName);
					If StrFind(TemplateParameters.Text, FileName.BaseName) > 0 Then
						AdditionalParameters.Insert("EmailFileID", FileName.BaseName);
					EndIf;

					FileAddingOptions = ModuleFilesOperations.FileAddingOptions(AdditionalParameters);
					FileAddingOptions.BaseName = FileName.BaseName;
					If StrLen(FileName.Extension) > 1 Then
						FileAddingOptions.ExtensionWithoutPoint = Mid(FileName.Extension, 2);
					EndIf;
					FileAddingOptions.Author = Users.AuthorizedUser();
					FileAddingOptions.FilesOwner = Template.Ref;

					Try
						ModuleFilesOperations.AppendFile(FileAddingOptions, Attachment.Value);
					Except
						// 
						// 
						ErrorInfo = ErrorInfo();
						WriteLogEvent(EventLogEventName, EventLogLevel.Error,,,
							ErrorProcessing.DetailErrorDescription(ErrorInfo));
					EndTry;
				EndDo;
			EndIf;

		EndIf;

		CommitTransaction();
	Except
		RollbackTransaction();

		ErrorInfo = ErrorInfo();
		WriteLogEvent(EventLogEventName, EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));

		Raise;
	EndTry;

	Return Template.Ref;

EndFunction

// Returns a description of the template parameters.
// 
// Returns:
//  Structure:
//   * Description - String -  name of the message template.
//   * Text        - String -  text of the message template or SMS message.
//   * Subject         - String -  text of the email subject. Only for email templates.
//   * TemplateType   - String -  template type. Options: "Email", "SMS".
//   * Purpose   - String -  view the subject of the message template. For example, a customer's Order.
//   * FullAssignmentTypeName - String -  subject of the message template. If the full path to the metadata object
//                                        is specified, all its details will be available in the template as parameters. For Example, A Document.Customer's order.
//   * EmailFormat1    - EnumRef.EmailEditingMethods-  the email format is HTML or plain text.
//                                         Only for email templates.
//   * PackToArchive - Boolean -  if True, then print the form and attachments will be Packed into the archive when sending.
//                                Only for email templates.
//   * TransliterateFileNames - Boolean -  printed forms and files attached to the email will have names that contain 
//                                             only Latin letters and numbers, so that you can transfer them between
//                                             different operating systems. For example, the file " Invoice for payment.pdf" will
//                                             be saved with the name "Schet na oplaty. pdf". Only for email templates.
//   * AttachmentsFormats - ValueList -  list of attachment formats. Only for email templates.
//   * Attachments - Map of KeyAndValue:
//      ** Key - String - 
//                         
//      ** Value - String - 
//   * PrintCommands - Array of String - 
//   * TemplateOwner - DefinedType.MessageTemplateOwner -  the owner of the context template.
//   * TemplateByExternalDataProcessor - Boolean -  if True, the template is generated by external processing.
//   * ExternalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors -  external processing that contains the template.
//   * SignatureAndSeal   - Boolean -  adds a facsimile signature and stamp to the printed form. Only for
//                                 email templates.
//   * AddAttachedFiles - Boolean -  
//                                              
//
Function TemplateParametersDetails() Export

	TemplateParameters = MessageTemplatesClientServer.TemplateParametersDetails();
	TemplateParameters.Delete("ExpandRefAttributes");

	Return TemplateParameters;

EndFunction

// Creates subordinate details for reference details in the value tree
//
// Parameters:
//  Name					 - String -  name of the reference detail to add subordinate details to in the value tree.
//  Node				 - ValueTreeRowCollection -  a node in the tree values which you want to create child elements.
//  AttributesList	 - String -  list of added details, separated by commas, if specified, will be added to them.
//  ExcludingAttributes	 - String -  comma-separated list of excluded Bank details.
//
Procedure ExpandAttribute(Name, Node, AttributesList = "", ExcludingAttributes = "") Export
	MessageTemplatesInternal.ExpandAttribute(Name, Node, AttributesList, ExcludingAttributes);
EndProcedure

// Adds current email addresses or phone numbers from the object's contact information to the list of recipients.
// Only up-to-date information is included in the selection of email addresses or phone numbers, 
// because there is no point in sending emails or SMS messages to archived data. 
//
// Parameters:
//  EmailRecipients        - ValueTable -  list of recipients of an email or SMS message
//  MessageSubject        - Arbitrary -  a parent object that has banking details containing contact information.
//  AttributeName            - String -  name of the detail in the parent object to get email addresses or
//                                     phone numbers from.
//  ContactInformationType - EnumRef.ContactInformationTypes -  if the type is Address, then
//                                                                          email addresses will be added, if Phone, then phone numbers.
//  SendingOption - String - 
//
Procedure FillRecipients(EmailRecipients, MessageSubject, AttributeName,
	ContactInformationType = Undefined, SendingOption = "Whom") Export

	If TypeOf(MessageSubject) = Type("Structure") Then
		SubjectOf = MessageSubject.SubjectOf;
	Else
		SubjectOf = MessageSubject;
	EndIf;
	ObjectMetadata = SubjectOf.Metadata();

	If ObjectMetadata.Attributes.Find(AttributeName) = Undefined Then
		If Not MessageTemplatesInternal.IsStandardAttribute(ObjectMetadata, AttributeName) Then
			Return;
		EndIf;
	EndIf;

	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManager = Common.CommonModule("ContactsManager");

		If SubjectOf[AttributeName] = Undefined Then
			Return;
		EndIf;

		If ContactInformationType = Undefined Then
			ContactInformationType = ModuleContactsManager.ContactInformationTypeByDescription(
				"Email");
		EndIf;

		ObjectsOfContactInformation = New Array;
		ObjectsOfContactInformation.Add(SubjectOf[AttributeName]);

		ContactInformation4 = ModuleContactsManager.ObjectsContactInformation(
			ObjectsOfContactInformation, ContactInformationType,, CurrentSessionDate());
		For Each ContactInformationItem In ContactInformation4 Do
			Recipient = EmailRecipients.Add();
			If ContactInformationType = ModuleContactsManager.ContactInformationTypeByDescription(
				"Phone") Then
				Recipient.PhoneNumber = ContactInformationItem.Presentation;
				Recipient.Presentation = String(ContactInformationItem.Object);
				Recipient.Contact       = ObjectsOfContactInformation[0];
			Else
				Recipient.Address           = ContactInformationItem.Presentation;
				Recipient.Presentation   = String(ContactInformationItem.Object);
				Recipient.Contact         = ObjectsOfContactInformation[0];
				Recipient.SendingOption = SendingOption;
			EndIf;

		EndDo;
	EndIf;

EndProcedure

// 
//
// Parameters:
//   Value - Boolean - 
//
Procedure SetUsageOfMessagesTemplates(Value) Export

	Constants.UseMessageTemplates.Set(Value);

EndProcedure

// 
//
// Returns:
//   Boolean - 
//
Function MessageTemplatesUsed() Export

	Return GetFunctionalOption("UseMessageTemplates");

EndFunction

// 

// Creates a description of the message template parameter table.
//
// Returns:
//   ValueTable   - 
//
Function ParametersTable() Export

	TemplateParameters = New ValueTable;

	TemplateParameters.Columns.Add("ParameterName", New TypeDescription("String", , New StringQualifiers(50,
		AllowedLength.Variable)));
	TemplateParameters.Columns.Add("TypeDetails", New TypeDescription("TypeDescription"));
	TemplateParameters.Columns.Add("IsPredefinedParameter", New TypeDescription("Boolean"));
	TemplateParameters.Columns.Add("ParameterPresentation", New TypeDescription("String", ,
		New StringQualifiers(150, AllowedLength.Variable)));

	Return TemplateParameters;

EndFunction

// Add a template parameter for external processing.
//
// Parameters:
//  ParametersTable - ValueTable -  table with a list of parameters.
//  ParameterName - String -  name of the parameter to add.
//  TypeDetails - TypeDescription -  parameter type.
//  IsPredefinedParameter - Boolean -  if True, the parameter is predefined.
//  ParameterPresentation - String -  representation of the argument.
//
Procedure AddTemplateParameter(ParametersTable, ParameterName, TypeDetails, IsPredefinedParameter,
	ParameterPresentation = "") Export

	NewRow                             = ParametersTable.Add();
	NewRow.ParameterName                = ParameterName;
	NewRow.TypeDetails                = TypeDetails;
	NewRow.IsPredefinedParameter = IsPredefinedParameter;
	NewRow.ParameterPresentation      = ?(IsBlankString(ParameterPresentation), ParameterName,
		ParameterPresentation);

EndProcedure

// Initializes the Recipients structure to populate possible message recipients.
//
// Returns:
//   Structure  - 
//
Function InitializeRecipientsStructure() Export

	Return MessageTemplatesClientServer.InitializeRecipientsStructure();

EndFunction

// Initializes the template message structure to be returned by external processing.
//
// Returns:
//   Structure  - 
//
Function InitializeMessageStructure() Export

	Return MessageTemplatesClientServer.InitializeMessageStructure();

EndFunction

// Returns a description of the message template parameters based on form data, a reference to the message template reference element
// , or by defining a context template by its owner. If the template is not found, the
// structure will be returned with empty fields of the message template, which can be used to create a new message template.
//
// Parameters:
//  Template - FormDataStructure
//         - CatalogRef.MessageTemplates
//         - AnyRef - 
//
// Returns:
//   See MessageTemplatesClientServer.TemplateParametersDetails.
//
Function TemplateParameters(Val Template) Export

	SearchByOwner = False;
	If TypeOf(Template) <> Type("FormDataStructure") And TypeOf(Template) <> Type("CatalogRef.MessageTemplates") Then

		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	MessageTemplates.Ref AS Ref
		|FROM
		|	Catalog.MessageTemplates AS MessageTemplates
		|WHERE
		|	MessageTemplates.TemplateOwner = &TemplateOwner";
		Query.SetParameter("TemplateOwner", Template);

		QueryResult = Query.Execute().Select();
		If QueryResult.Next() Then
			Template = QueryResult.Ref;
		Else
			SearchByOwner = True;
		EndIf;
	EndIf;

	Result = MessageTemplatesInternal.TemplateParameters(Template);
	If SearchByOwner Then
		Result.TemplateOwner = Template;
	EndIf;
	Return Result;
EndFunction

// 

// Inserts the values of message parameters into the template and generates the message text.
//
// Parameters:
//  StringPattern        - String -  the template that values will be inserted into, according to the parameter table.
//  ValuesToInsert - Map -  a match containing parameter keys and parameter values.
//  Prefix             - String -  the prefix parameter.
//
// Returns:
//   String - 
//
Function InsertParametersInRowAccordingToParametersTable(Val StringPattern, ValuesToInsert, Val Prefix = "") Export
	Return MessageTemplatesInternal.InsertParametersInRowAccordingToParametersTable(StringPattern,
		ValuesToInsert, Prefix);
EndFunction

// Returns whether the template message text parameters match.
//
// Parameters:
//  TemplateParameters - Structure -  information about the template.
//
// Returns:
//  Map - 
//
Function ParametersFromMessageText(TemplateParameters) Export
	Return MessageTemplatesInternal.ParametersFromMessageText(TemplateParameters);
EndFunction

// Fills in the General details with values from the program.
// After performing the procedure, the match will contain the following values:
//  current Date, system Header, address Baseinternet, address baseinlocal Network
//  Current user
//
// Parameters:
//  CommonAttributes - Map of KeyAndValue:
//   * Key - String -  name of the shared property
//   * Value - String -  the value of the completed banking details.
//
Procedure FillCommonAttributes(CommonAttributes) Export
	MessageTemplatesInternal.FillCommonAttributes(CommonAttributes);
EndProcedure

// Returns the name of the shared details node.
// 
// Returns:
//  String - 
//
Function CommonAttributesNodeName() Export
	Return "CommonAttributes";
EndFunction

#EndRegion

#Region Internal

// Determines whether the passed link is an element of the message templates directory.
//
// Parameters:
//  TemplateRef1 - CatalogRef.MessageTemplates -  the reference to the element of the dictionary templates.
// 
// Returns:
//  Boolean - 
//
Function IsTemplate1(TemplateRef1) Export
	Return TypeOf(TemplateRef1) = Type("CatalogRef.MessageTemplates");
EndFunction

// See GenerateFromOverridable.OnDefineObjectsWithCreationBasedOnCommands.
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export

	Objects.Add(Metadata.Catalogs.MessageTemplates);

EndProcedure

// See GenerateFromOverridable.OnAddGenerationCommands.
Procedure OnAddGenerationCommands(Object, GenerationCommands, Parameters, StandardProcessing) Export

	If Common.SubsystemExists("StandardSubsystems.Interactions") Then
		If Object = Metadata.Documents["OutgoingEmail"] Then
			Catalogs.MessageTemplates.AddGenerateCommand(GenerationCommands);
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region Private

// Sending parameters
// 
// Parameters:
//  Template - CatalogRef.MessageTemplates
//  SubjectOf - DefinedType.MessageTemplateSubject
//  UUID - UUID
//  AdditionalParameters - Undefined
//                          - Structure
//
// Returns:
//  Structure:
//    * AdditionalParameters - Structure
//    * UUID - UUID
//    * SubjectOf - DefinedType.MessageTemplateSubject
//    * Template - CatalogRef.MessageTemplates
//
Function GenerateSendOptions(Template, SubjectOf, UUID, AdditionalParameters = Undefined) Export
	
	SendOptions = MessageTemplatesClientServer.SendOptionsConstructor(Template, SubjectOf,
		UUID);

	If TypeOf(SendOptions.SubjectOf) = Type("String") And Common.MetadataObjectByFullName(
		SendOptions.SubjectOf) <> Undefined Then

		SendOptions.SubjectOf = Common.ObjectManagerByFullName(
			SendOptions.SubjectOf).EmptyRef();

	EndIf;

	If TypeOf(AdditionalParameters) = Type("Structure") Then
		SendOptions.AdditionalParameters.MessageParameters = AdditionalParameters;
		
		// 
		For Each Item In AdditionalParameters Do
			If SendOptions.AdditionalParameters.Property(Item.Key) Then
				SendOptions.AdditionalParameters.Insert(Item.Key, Item.Value);
			EndIf;
		EndDo;

	EndIf;

	Return SendOptions;

EndFunction

// Returns:
//  Structure:
//    * Address - String - 
//    * Presentation - String - 
//    * ContactInformationSource - DefinedType.MessageTemplateSubject -  owner of the contact information.
//                                   - Undefined
//
Function NewEmailRecipients() Export

	Result = New Structure;
	Result.Insert("Address", "");
	Result.Insert("Presentation", "");
	Result.Insert("ContactInformationSource", Undefined);

	Return Result;

EndFunction

// Parameters:
//  Attachments-Value Tables
// Returns:
//   ValueTableRow:
//   * Ref - CatalogRef.MessageTemplatesAttachedFiles
//   * Id - String
//   * Presentation - String
//   * SelectedItemsCount - Boolean
//   * PictureIndex - Number
//   * FileType - String
//   * PrintManager
//   * PrintParameters
//   * Status
//   * Name
//   * Attribute
//   * ParameterName - String
//
Function AttachmentsRow(Attachment) Export
	Return Attachment;
EndFunction

#EndRegion