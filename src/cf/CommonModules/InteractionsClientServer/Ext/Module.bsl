///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns a new description of the interaction contact.
// For use in interactionclientserver is Undefined.When defining possible contacts.
//
// Returns:
//   Structure - :
//     * Type                                - Type     -  type of contact link.
//     * Name                                 - String -  name of the contact type as defined in the metadata.
//     * Presentation                       - String -  representation of the contact type to display to the user.
//     * Hierarchical                       - Boolean -  indicates whether the directory is hierarchical.
//     * HasOwner                        - Boolean -  indicates that the contact has an owner.
//     * OwnerName                        - String -  name of the contact owner, as defined in the metadata.
//     * SearchByDomain                      - Boolean -  indicates that contacts of this type will be selected
//                                                      by matching the domain, and not by the full email address.
//     * Link                               - String -  describes the possible connection of this contact with another contact,
//                                                      if the current contact is a detail of another contact.
//                                                      Described by the following line " table Name.Requestname".
//     * ContactPresentationAttributeName   - String -  name of the contact details that the contact view will be received from
//                                                      . If not specified,
//                                                      the standard name is used.
//     * InteractiveCreationPossibility   - Boolean - 
//                                                      
//     * NewContactFormName              - String -  full name of the form for creating a new contact,
//                                                      for example, " Directory.Partners.Form.Assistant Manager".
//                                                      If not filled in, the default element form opens.
//
Function NewContactDescription() Export
	
	Result = New Structure;
	Result.Insert("Type",                               "");
	Result.Insert("Name",                               "");
	Result.Insert("Presentation",                     "");
	Result.Insert("Hierarchical",                     False);
	Result.Insert("HasOwner",                      False);
	Result.Insert("OwnerName",                      "");
	Result.Insert("SearchByDomain",                    True);
	Result.Insert("Link",                             "");
	Result.Insert("ContactPresentationAttributeName", "Description");
	Result.Insert("InteractiveCreationPossibility", True);
	Result.Insert("NewContactFormName",            "");
	Return Result;
	
EndFunction	

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
//
// Parameters:
//  DetailsArray                     - Array -  the array to which will be added to the structure of the description of the contact.
//  Type                                - Type    -  type of contact link.
//  InteractiveCreationPossibility  - Boolean -  indicates whether a contact can be created interactively from
//                                                interaction documents.
//  Name                                 - String -  name of the contact type as defined in the metadata.
//  Presentation                       - String -  representation of the contact type to display to the user.
//  Hierarchical                       - Boolean -  indicates whether the directory is hierarchical.
//  HasOwner                        - Boolean -  indicates that the contact has an owner.
//  OwnerName                        - String -  name of the contact owner, as defined in the metadata.
//  SearchByDomain                      - Boolean -  indicates that the domain will be
//                                                 searched for this type of contact.
//  Link                               - String -  describes the possible connection of this contact with another contact,
//                                                 if the current contact is a detail of another contact.
//                                                 Described by the following line " table Name.Requestname".
//  ContactPresentationAttributeName   - String -  name of the contact details that the contact view will be received from.
//
Procedure AddPossibleContactsTypesDetailsArrayElement(
	DetailsArray,
	Type,
	InteractiveCreationPossibility,
	Name,
	Presentation,
	Hierarchical,
	HasOwner,
	OwnerName,
	SearchByDomain,
	Link,
	ContactPresentationAttributeName = "Description") Export
	
	DetailsStructure1 = New Structure;
	DetailsStructure1.Insert("Type",                               Type);
	DetailsStructure1.Insert("InteractiveCreationPossibility", InteractiveCreationPossibility);
	DetailsStructure1.Insert("Name",                               Name);
	DetailsStructure1.Insert("Presentation",                     Presentation);
	DetailsStructure1.Insert("Hierarchical",                     Hierarchical);
	DetailsStructure1.Insert("HasOwner",                      HasOwner);
	DetailsStructure1.Insert("OwnerName",                      OwnerName);
	DetailsStructure1.Insert("SearchByDomain",                    SearchByDomain);
	DetailsStructure1.Insert("Link",                             Link);
	DetailsStructure1.Insert("ContactPresentationAttributeName", ContactPresentationAttributeName);

	
	DetailsArray.Add(DetailsStructure1);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function PrefixTable() Export
	Return "Table_";
EndFunction
	
////////////////////////////////////////////////////////////////////////////////
// 

// Parameters:
//  ObjectRef  - AnyRef -  which needs to be checked.
//
// Returns:
//   Boolean   - 
//
Function IsInteraction(ObjectRef) Export
	
	If TypeOf(ObjectRef) = Type("Type") Then
		ObjectType = ObjectRef;
	Else
		ObjectType = TypeOf(ObjectRef);
	EndIf;
	
	Return ObjectType = Type("DocumentRef.Meeting")
		Or ObjectType = Type("DocumentRef.PlannedInteraction")
		Or ObjectType = Type("DocumentRef.PhoneCall")
		Or ObjectType = Type("DocumentRef.IncomingEmail")
		Or ObjectType = Type("DocumentRef.OutgoingEmail")
		Or ObjectType = Type("DocumentRef.SMSMessage");
	
EndFunction

// Parameters:
//  ObjectRef  - AnyRef -  which needs to be checked.
//
// Returns:
//   Boolean   - 
//
Function IsAttachedInteractionsFile(ObjectRef) Export
	
	Return TypeOf(ObjectRef) = Type("CatalogRef.MeetingAttachedFiles")
		Or TypeOf(ObjectRef) = Type("CatalogRef.PlannedInteractionAttachedFiles")
		Or TypeOf(ObjectRef) = Type("CatalogRef.PhoneCallAttachedFiles")
		Or TypeOf(ObjectRef) = Type("CatalogRef.IncomingEmailAttachedFiles")
		Or TypeOf(ObjectRef) = Type("CatalogRef.OutgoingEmailAttachedFiles")
		Or TypeOf(ObjectRef) = Type("CatalogRef.SMSMessageAttachedFiles");
	
EndFunction

// Parameters:
//  ObjectRef - AnyRef -  the link that is being checked
//                               for whether it is a link to the subject of interactions.
//
// Returns:
//   Boolean   - 
//
Function IsSubject(ObjectRef) Export
	
	InteractionsSubjects = InteractionsClientServerInternalCached.InteractionsSubjects();
	For Each SubjectOf In InteractionsSubjects Do
		If TypeOf(ObjectRef) = Type(SubjectOf) Then
			Return True;
		EndIf;
	EndDo;
	Return False;	
	
EndFunction 

////////////////////////////////////////////////////////////////////////////////
// Other

// Parameters:
//  FileName  - String -  name of the file being checked.
//
// Returns:
//   Boolean   - 
//
Function IsFileEmail(FileName) Export

	FileExtensionsArray = EmailFileExtensionsArray();
	FileExtention       = CommonClientServer.GetFileNameExtension(FileName);
	Return (FileExtensionsArray.Find(FileExtention) <> Undefined);
	
EndFunction

// Parameters:
//  SendInTransliteration  - Boolean -  indicates that the message will be automatically 
//                                   converted to Latin characters when sent.
//  MessageText  - String       -  the text of the message that the message is generated for.
//
// Returns:
//   String   - 
//
Function GenerateInfoLabelMessageCharsCount(SendInTransliteration, MessageText) Export

	CharsInMessage = ?(SendInTransliteration, 140, 50);
	CountOfCharacters = StrLen(MessageText);
	MessagesCount   = Int(CountOfCharacters / CharsInMessage) + 1;
	CharsLeft      = CharsInMessage - CountOfCharacters % CharsInMessage;
	MessageTextTemplate = NStr("en = 'Messages: %1. Symbols left: %2';");
	Return StringFunctionsClientServer.SubstituteParametersToString(MessageTextTemplate, MessagesCount, CharsLeft);

EndFunction

// Returns:
//  FixedArray of Structure - Contains:
//     * Type                                 - Type     -  type of contact link.
//     * Name                                 - String -  name of the contact type as defined in the metadata.
//     * Presentation                       - String -  representation of the contact type to display to the user.
//     * Hierarchical                       - Boolean -  indicates whether the directory is hierarchical.
//     * HasOwner                        - Boolean -  indicates that the contact has an owner.
//     * OwnerName                        - String -  name of the contact owner, as defined in the metadata.
//     * SearchByDomain                      - Boolean -  indicates that contacts of this type will be selected
//                                                      by matching the domain, and not by the full email address.
//     * Link                               - String -  describes the possible connection of this contact with another contact,
//                                                      if the current contact is a detail of another contact.
//                                                      Described by the following line " table Name.Requestname".
//     * ContactPresentationAttributeName   - String -  name of the contact details that the contact view will be received from
//                                                      . If not specified,
//                                                      the standard name is used.
//     * InteractiveCreationPossibility   - Boolean - 
//                                                      
//     * NewContactFormName              - String -  full name of the form for creating a new contact,
//                                                      for example, " Directory.Partners.Form.Assistant Manager".
//                                                      If not filled in, the default element form opens.
//
Function ContactsDetails() Export
	
	Return InteractionsClientServerInternalCached.InteractionsContacts();
	
EndFunction

// 
//
// Parameters:
//  Object - DocumentObject - 
//  Form - ClientApplicationForm -  the form of the document interactions.
//  DocumentKind - String -  string name of the interaction document.
//
Procedure CheckContactsFilling(Object,Form,DocumentKind) Export
	
	ContactsFilled = ContactsFilled(Object,DocumentKind);
	
	If ContactsFilled Then
		Form.Items.ContactsSpecifiedPages.CurrentPage = Form.Items.ContactsFilledPage;
	Else
		Form.Items.ContactsSpecifiedPages.CurrentPage = Form.Items.ContactsNotFilledPage;
	EndIf;
	
EndProcedure

// Parameters:
//  SizeInBytes - Number -  size in bytes of the attached email file.
//
// Returns:
//   String   - 
//
Function GetFileSizeStringPresentation(SizeInBytes) Export
	
	SizeMB = SizeInBytes / (1024*1024);
	If SizeMB > 1 Then
		StringSize = Format(SizeMB, "NFD=1") + " " + NStr("en = 'MB';");
	Else
		StringSize = Format(SizeInBytes /1024, "NFD=0; NZ=0") + " " + NStr("en = 'kB';");
	EndIf;
	
	Return StringSize;
	
EndFunction

// Handles changes to the quick selection of a dynamic list of interaction documents.
//
// Parameters:
//  Form - ClientApplicationForm -  the form that the action is being performed for.
//  FilterName - String -  name of the selection to change.
//  IsFilterBySubject - Boolean -  indicates that the list form is parametric and subject selection is applied to it.
//
Procedure QuickFilterListOnChange(Form, FilterName, DateForFilter = Undefined, IsFilterBySubject = True) Export
	
	Filter = DynamicListFilter(Form.List);
	
	If FilterName = "Status" Then
		
		CommonClientServer.DeleteFilterItems(Filter, "ReviewAfter");
		CommonClientServer.DeleteFilterItems(Filter, "Reviewed");
		If Not IsFilterBySubject Then
			CommonClientServer.DeleteFilterItems(Filter, "SubjectOf");
		EndIf;
		
		If Form[FilterName] = "ToReview" Then
			
			CommonClientServer.SetFilterItem(Filter, "Reviewed", False,,, True);
			CommonClientServer.SetFilterItem(
				Filter, "ReviewAfter", DateForFilter, DataCompositionComparisonType.LessOrEqual,, True);
			
		ElsIf Form[FilterName] = "Deferred3" Then
			CommonClientServer.SetFilterItem(Filter, "Reviewed", False,,, True);
			CommonClientServer.SetFilterItem(
			Filter, "ReviewAfter", , DataCompositionComparisonType.Filled,, True);
		ElsIf Form[FilterName] = "ReviewedItems" Then
			CommonClientServer.SetFilterItem(Filter, "Reviewed", True,,, True);
		EndIf;
		
	Else
		
		CommonClientServer.SetFilterItem(
			Filter,FilterName,Form[FilterName],,, ValueIsFilled(Form[FilterName]));
		
	EndIf;
	
EndProcedure

// Handles changes to the quick selection by interaction type of the dynamic list of interaction documents.
//
// Parameters:
//  Form - ClientApplicationForm -  contains a dynamic list that contains the selection that is being modified.
//  InteractionType - String -  name of the overlay selection.
//
Procedure OnChangeFilterInteractionType(Form,InteractionType) Export
	
	Filter = DynamicListFilter(Form.List);
	
	// 
	FilterGroup = CommonClientServer.CreateFilterItemGroup(
		Filter.Items, NStr("en = 'Filter by interaction category';"), DataCompositionFilterItemsGroupType.AndGroup);
	
	// 
	If InteractionType = "AllEmails" Then
		
		EmailTypesList = New ValueList;
		EmailTypesList.Add(Type("DocumentRef.IncomingEmail"));
		EmailTypesList.Add(Type("DocumentRef.OutgoingEmail"));
		CommonClientServer.SetFilterItem(
			FilterGroup, "Type", EmailTypesList, DataCompositionComparisonType.InList,, True);
		
	ElsIf InteractionType = "IncomingMessages" Then
		
		CommonClientServer.SetFilterItem(FilterGroup,
			"Type", Type("DocumentRef.IncomingEmail"), DataCompositionComparisonType.Equal,, True);
		CommonClientServer.SetFilterItem(FilterGroup,
			"DeletionMark", False, DataCompositionComparisonType.Equal, , True);
		
	ElsIf InteractionType = "MessageDrafts" Then
		
		CommonClientServer.SetFilterItem(FilterGroup,
			"Type", Type("DocumentRef.OutgoingEmail"), DataCompositionComparisonType.Equal, , True);
		CommonClientServer.SetFilterItem(
			FilterGroup, "DeletionMark", False, DataCompositionComparisonType.Equal, , True);
		CommonClientServer.SetFilterItem(FilterGroup,
			"OutgoingEmailStatus", PredefinedValue("Enum.OutgoingEmailStatuses.Draft"),
			DataCompositionComparisonType.Equal,, True);
		
	ElsIf InteractionType = "OutgoingMessages" Then
		
		CommonClientServer.SetFilterItem(FilterGroup,
		"Type", Type("DocumentRef.OutgoingEmail"),DataCompositionComparisonType.Equal,, True);
		CommonClientServer.SetFilterItem(FilterGroup,
			"DeletionMark", False,DataCompositionComparisonType.Equal,, True);
		CommonClientServer.SetFilterItem(FilterGroup,
			"OutgoingEmailStatus", PredefinedValue("Enum.OutgoingEmailStatuses.Outgoing"),DataCompositionComparisonType.Equal,, True);
		
	ElsIf InteractionType = "SentMessages" Then
		
		CommonClientServer.SetFilterItem(FilterGroup,
			"Type", Type("DocumentRef.OutgoingEmail"),DataCompositionComparisonType.Equal,, True);
		CommonClientServer.SetFilterItem(FilterGroup,
			"DeletionMark", False,DataCompositionComparisonType.Equal,, True);
		CommonClientServer.SetFilterItem(FilterGroup,
			"OutgoingEmailStatus", PredefinedValue("Enum.OutgoingEmailStatuses.Sent"),
			DataCompositionComparisonType.Equal,, True);
		
	ElsIf InteractionType = "DeletedMessages" Then
		
		EmailTypesList = New ValueList;
		EmailTypesList.Add(Type("DocumentRef.IncomingEmail"));
		EmailTypesList.Add(Type("DocumentRef.OutgoingEmail"));
		CommonClientServer.SetFilterItem(FilterGroup,
			"Type", EmailTypesList, DataCompositionComparisonType.InList,, True);
		CommonClientServer.SetFilterItem(FilterGroup,
			"DeletionMark", True,DataCompositionComparisonType.Equal,, True);
		
	ElsIf InteractionType = "Meetings" Then
		
		CommonClientServer.SetFilterItem(FilterGroup, 
			"Type", Type("DocumentRef.Meeting"),DataCompositionComparisonType.Equal,, True);
		
	ElsIf InteractionType = "PlannedInteractions" Then
		
		CommonClientServer.SetFilterItem(FilterGroup,
			"Type", Type("DocumentRef.PlannedInteraction"),DataCompositionComparisonType.Equal,, True);
		
	ElsIf InteractionType = "PhoneCalls" Then
		
		CommonClientServer.SetFilterItem(FilterGroup, 
			"Type", Type("DocumentRef.PhoneCall"),DataCompositionComparisonType.Equal,, True);
		
	ElsIf InteractionType = "OutgoingCalls" Then
		
		CommonClientServer.SetFilterItem(FilterGroup,
			"Type", Type("DocumentRef.PhoneCall"),DataCompositionComparisonType.Equal,, True);
		CommonClientServer.SetFilterItem(FilterGroup, 
			"Incoming",False,DataCompositionComparisonType.Equal,, True);
		
	ElsIf InteractionType = "IncomingCalls" Then
		
		CommonClientServer.SetFilterItem(FilterGroup, 
			"Type", Type("DocumentRef.PhoneCall"),DataCompositionComparisonType.Equal,, True);
		CommonClientServer.SetFilterItem(FilterGroup,
			"Incoming", True, DataCompositionComparisonType.Equal,, True);
			
	ElsIf InteractionType = "SMSMessages" Then
		
		CommonClientServer.SetFilterItem(FilterGroup, 
			"Type", Type("DocumentRef.SMSMessage"),DataCompositionComparisonType.Equal,, True);
	Else
			
		Filter.Items.Delete(FilterGroup);
		
	EndIf;
	
EndProcedure

// Parameters:
//  Name     - String -  destination name.
//  Address   - String -  the recipient's email address.
//  Contact - CatalogRef -  the contact that the name and email address belong to.
//
// Returns:
//   String - 
//
Function GetAddresseePresentation(Name, Address, Contact) Export
	
	Result = ?(Name = Address Or Name = "", Address, ?(IsBlankString(Address), Name, ?(StrFind(Name, Address) > 0, Name, Name + " <" + Address + ">")));
	If ValueIsFilled(Contact) And TypeOf(Contact) <> Type("String") Then
		Result = Result + " [" + GetContactPresentation(Contact) + "]";
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  AddresseesTable    - ValueTable -  table with destination data.
//  IncludeContactName - Boolean -  indicates whether to include contact data in the view.
//  Contact-reference Link - the contact who owns the name and email address.
//
// Returns:
//  String - 
//
Function GetAddressesListPresentation(AddresseesTable, IncludeContactName = True) Export

	Presentation = "";
	For Each TableRow In AddresseesTable Do
		Presentation = Presentation 
	              + GetAddresseePresentation(TableRow.Presentation,
	                                              TableRow.Address, 
	                                             ?(IncludeContactName, TableRow.Contact, "")) + "; ";
	EndDo;

	Return Presentation;

EndFunction

// Parameters:
//  InteractionObject - DocumentObject -  the interaction document that is being validated.
//  DocumentKind - String -  document name.
//
// Returns:
//  Boolean - 
//
Function ContactsFilled(InteractionObject, DocumentKind)
	
	TabularSectionsArray = New Array;
	
	If DocumentKind = "OutgoingEmail" Then
		
		TabularSectionsArray.Add("EmailRecipients");
		TabularSectionsArray.Add("CCRecipients");
		TabularSectionsArray.Add("ReplyRecipients");
		TabularSectionsArray.Add("BccRecipients");
		
	ElsIf DocumentKind = "IncomingEmail" Then
		
		If Not ValueIsFilled(InteractionObject.SenderContact) Then
			Return False;
		EndIf;
		
		TabularSectionsArray.Add("EmailRecipients");
		TabularSectionsArray.Add("CCRecipients");
		TabularSectionsArray.Add("ReplyRecipients");
		
	ElsIf DocumentKind = "Meeting" 
		Or DocumentKind = "PlannedInteraction" Then
				
		TabularSectionsArray.Add("Attendees");
		
	ElsIf DocumentKind = "SMSMessage" Then
		
		TabularSectionsArray.Add("SMSMessageRecipients");
		
	ElsIf DocumentKind = "PhoneCall" Then
		
		If Not ValueIsFilled(InteractionObject.SubscriberContact) Then
			Return False;
		EndIf;
		
	EndIf;
	
	For Each TabularSectionName In TabularSectionsArray Do
		For Each LineOfATabularSection In InteractionObject[TabularSectionName] Do
			
			If Not ValueIsFilled(LineOfATabularSection.Contact) Then
				Return False;
			EndIf;
			
		EndDo;
	EndDo;
	
	Return True;
	
EndFunction

Procedure SetGroupItemsProperty(Items_Group, PropertyName, PropertyValue) Export
	
	For Each SubordinateItem In Items_Group.ChildItems Do
		
		If TypeOf(SubordinateItem) = Type("FormGroup") Then
			
			SetGroupItemsProperty(SubordinateItem, PropertyName, PropertyValue);
			
		Else
			
			SubordinateItem[PropertyName] = PropertyValue;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function GetContactPresentation(Contact)

	Return String(Contact);

EndFunction

// Parameters:
//  List  - DynamicList -  the list for which it is necessary to determine the selection.
//
// Returns:
//   Filter   - 
//
Function DynamicListFilter(List) Export

	Return List.SettingsComposer.FixedSettings.Filter;

EndFunction

// Parameters:
//  ObjectManager     - DocumentObject.PhoneCall
//                      - DocumentObject.PlannedInteraction
//                      - DocumentObject.SMSMessage
//                      - DocumentObject.Meeting
//                      - DocumentObject.IncomingEmail
//                      - DocumentObject.OutgoingEmail - 
//  Data              - Structure:
//                        * StartDate - Date -  start of the planned interaction.
//  Presentation        - String -  generated view.
//  StandardProcessing - Boolean - 
//
Procedure PresentationGetProcessing(ObjectManager, Data, Presentation, StandardProcessing) Export
	
	Subject = InteractionSubject1(Data.Subject);
	Date = Format(Data.Date, "DLF=D");
	DocumentType = "";
	If TypeOf(ObjectManager) = Type("DocumentManager.Meeting") Then
		DocumentType = NStr("en = 'Appointment';");
		Date = Format(Data.StartDate, "DLF=D");
	ElsIf TypeOf(ObjectManager) = Type("DocumentManager.PlannedInteraction") Then
		DocumentType = NStr("en = 'Scheduled interaction';");
	ElsIf TypeOf(ObjectManager) = Type("DocumentManager.SMSMessage") Then
		DocumentType = NStr("en = 'SMS';");
	ElsIf TypeOf(ObjectManager) = Type("DocumentManager.PhoneCall") Then
		DocumentType = NStr("en = 'Phone call';");
	ElsIf TypeOf(ObjectManager) = Type("DocumentManager.IncomingEmail") Then
		DocumentType = NStr("en = 'Incoming mail';");
	ElsIf TypeOf(ObjectManager) = Type("DocumentManager.OutgoingEmail") Then
		DocumentType = NStr("en = 'Outgoing mail';");
	EndIf;
	
	TemplateOfPresentation = NStr("en = '%1, %2 (%3)';");
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(TemplateOfPresentation, Subject, Date, DocumentType);
	
	StandardProcessing = False;
	 
EndProcedure

// Gets the fields required to form the view for interactions.
// 
// Parameters:
//  ObjectManager - DocumentObject.PhoneCall
//                  - DocumentObject.PlannedInteraction
//                  - DocumentObject.SMSMessage
//                  - DocumentObject.Meeting
//                  - DocumentObject.IncomingEmail
//                  - DocumentObject.OutgoingEmail - 
//  Fields                  - Array -  names of fields that are needed to form a representation of an object or link.
//  StandardProcessing  - Boolean -  indicates whether standard processing is required.
//
Procedure PresentationFieldsGetProcessing(ObjectManager, Fields, StandardProcessing) Export
	
	Fields.Add("Subject");
	Fields.Add("Date");
	If TypeOf(ObjectManager) = Type("DocumentManager.Meeting") Then
		Fields.Add("StartDate");
	EndIf;
	StandardProcessing = False;
	
EndProcedure

Function EmailFileExtensionsArray()
	
	FileExtensionsArray = New Array;
	FileExtensionsArray.Add("msg");
	FileExtensionsArray.Add("eml");
	
	Return FileExtensionsArray;
	
EndFunction

Function InteractionSubject1(Subject) Export

	Return ?(IsBlankString(Subject), NStr("en = '<No Subject>';"), Subject);

EndFunction 

#EndRegion
