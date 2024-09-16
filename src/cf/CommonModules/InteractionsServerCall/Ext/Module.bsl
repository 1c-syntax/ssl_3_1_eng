///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

////////////////////////////////////////////////////////////////////////////////
//  

// Parameters:
//  Contact                 - DefinedType.InteractionContact -  contact for which information is obtained.
//  Presentation           - String -  the resulting view will be placed in this parameter.
//  CIRow                - String -  this parameter will contain the received contact information.
//  ContactInformationType - EnumRef.ContactInformationTypes -  the ability to set the selection by the type 
//                                                                          of contact information received.
//
Procedure PresentationAndAllContactInformationOfContact(Contact, Presentation, CIRow,ContactInformationType = Undefined) Export
	
	Presentation = "";
	CIRow = "";
	If Not ValueIsFilled(Contact) 
		Or TypeOf(Contact) = Type("CatalogRef.StringContactInteractions") Then
		Contact = Undefined;
		Return;
	EndIf;
	
	TableName = Contact.Metadata().Name;
	FieldNameForOwnerDescription = Interactions.FieldNameForOwnerDescription(TableName);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CatalogContact.Description   AS Description,
	|	&NameOfTheOwnerSName AS OwnerDescription1
	|FROM
	|	&TableName AS CatalogContact
	|WHERE
	|	CatalogContact.Ref = &Contact
	|";
	
	Query.Text = StrReplace(Query.Text, "&TableName", "Catalog." + TableName);
	Query.Text = StrReplace(Query.Text, "&NameOfTheOwnerSName", FieldNameForOwnerDescription);
	
	Query.SetParameter("Contact", Contact);
	Query.SetParameter("ContactInformationType", ContactInformationType);
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Return;
	EndIf;
	
	Presentation = Selection.Description;
	
	If Not IsBlankString(Selection.OwnerDescription1) Then
		Presentation = Presentation + " (" + Selection.OwnerDescription1 + ")";
	EndIf;
	
	ContactsArray = CommonClientServer.ValueInArray(Contact);
	CITable = ContactsManager.ObjectsContactInformation(ContactsArray, ContactInformationType, Undefined, CurrentSessionDate());
	
	For Each TableRow In CITable Do
		If TableRow.Type <> Enums.ContactInformationTypes.Other Then
			CIRow = CIRow + ?(IsBlankString(CIRow), "", "; ") + TableRow.Presentation;
		EndIf;
	EndDo;
	
EndProcedure

// Parameters:
//  Contact - AnyRef -  the contact for which data is being received.
//
// Returns:
//  Structure - 
//
Function ContactDescriptionAndEmailAddresses(Contact) Export
	
	If Not ValueIsFilled(Contact) 
		Or TypeOf(Contact) = Type("CatalogRef.StringContactInteractions") Then
		Return Undefined;
	EndIf;
	
	ContactMetadata = Contact.Metadata();
	
	If ContactMetadata.Hierarchical
		And ContactMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
		If Common.ObjectAttributeValue(Contact, "IsFolder") = True Then
			Return Undefined;
		EndIf;
	EndIf;
	
	ContactsTypesDetailsArray = InteractionsClientServer.ContactsDetails();
	DetailsArrayElement = Undefined;
	For Each ArrayElement In ContactsTypesDetailsArray Do
		
		If ArrayElement.Name = ContactMetadata.Name Then
			DetailsArrayElement = ArrayElement;
			Break;
		EndIf;
		
	EndDo;
	
	If DetailsArrayElement = Undefined Then
		Return Undefined;
	EndIf;
	
	TableName = ContactMetadata.FullName();
	
	QueryText =
	"SELECT ALLOWED DISTINCT
	|	ISNULL(ContactInformationTable.EMAddress,"""") AS EMAddress,
	|	CatalogContact." + DetailsArrayElement.ContactPresentationAttributeName + " AS Description
	|FROM
	|	" + TableName + " AS CatalogContact
	|		LEFT JOIN " + TableName + ".ContactInformation AS ContactInformationTable
	|		On (ContactInformationTable.Ref = CatalogContact.Ref)
	|			AND (ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.Email))
	|WHERE
	|	CatalogContact.Ref = &Contact
	|TOTALS BY
	|	Description";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Contact", Contact);
	Selection = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	If Not Selection.Next() Then
		Return Undefined;
	EndIf;
	
	Addresses = New Structure("Description,Addresses", Selection.Description, New ValueList);
	AddressesSelection = Selection.Select();
	While AddressesSelection.Next() Do
		Addresses.Addresses.Add(AddressesSelection.EMAddress);
	EndDo;
	
	Return Addresses;
	
EndFunction

// Parameters:
//  Contact - DefinedType.InteractionContact -  the contact for which data is being received.
//
// Returns:
//  Array of Structure - 
//
Function GetContactEmailAddresses(Contact, IncludeBlankKinds = False) Export
	
	If Not ValueIsFilled(Contact) Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	ContactMetadataName = Contact.Metadata().Name;
	
	If IncludeBlankKinds Then
		
		Query.Text =
		"SELECT
		|	ContactInformationKinds.Ref AS Kind,
		|	ContactInformationKinds.Description AS DescriptionKind,
		|	Contacts.Ref AS Contact
		|INTO ContactCIKinds
		|FROM
		|	Catalog.ContactInformationKinds AS ContactInformationKinds,
		|	&NameOfTheReferenceTable AS Contacts
		|WHERE
		|	ContactInformationKinds.Parent = &ContactInformationKindGroup
		|	AND Contacts.Ref = &Contact
		|	AND ContactInformationKinds.Type = VALUE(Enum.ContactInformationTypes.Email)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PRESENTATION(ContactCIKinds.Contact) AS Presentation,
		|	ISNULL(ContactInformation.EMAddress, """") AS EMAddress,
		|	ContactCIKinds.Kind,
		|	ContactCIKinds.DescriptionKind
		|FROM
		|	ContactCIKinds AS ContactCIKinds
		|		LEFT JOIN Catalog.Users.ContactInformation AS ContactInformation
		|		ON (ContactInformation.Ref = ContactCIKinds.Contact)
		|			AND (ContactInformation.Kind = ContactCIKinds.Kind)";
		
		Query.Text = StrReplace(Query.Text, "&NameOfTheReferenceTable", "Catalog." + ContactMetadataName);
		Query.Text = StrReplace(Query.Text, "Catalog.Users.ContactInformation", "Catalog." + ContactMetadataName + ".ContactInformation");
		
		ContactInformationKindGroup = ContactsManager.ContactInformationKindByName("Catalog" + ContactMetadataName);
		Query.SetParameter("ContactInformationKindGroup", ContactInformationKindGroup);
		
	Else
		
		Query.Text =
		"SELECT
		|	Tables.EMAddress,
		|	Tables.Kind,
		|	Tables.Presentation,
		|	Tables.Kind.Description AS DescriptionKind
		|FROM
		|	&NameOfTheContactInformationTable AS Tables
		|WHERE
		|	Tables.Ref = &Contact
		|	AND Tables.Type = VALUE(Enum.ContactInformationTypes.Email)";
		
		Query.Text = StrReplace(Query.Text, "&NameOfTheContactInformationTable", "Catalog." + ContactMetadataName + ".ContactInformation");
		
	EndIf;

	Query.SetParameter("Contact", Contact);
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 0 Then
		Return New Array;
	EndIf;
	
	Result = New Array;
	While Selection.Next() Do
		Address = New Structure;
		Address.Insert("EMAddress",         Selection.EMAddress);
		Address.Insert("Kind",             Selection.Kind);
		Address.Insert("Presentation",   Selection.Presentation);
		Address.Insert("DescriptionKind", Selection.DescriptionKind);
		Result.Add(Address);
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
//  UUID - UUID -  ID of the background task.
//
// Returns:
//   See TimeConsumingOperations.ExecuteInBackground
//
Function SendReceiveUserEmailInBackground(UUID) Export
	
	If Interactions.BackgroundJobReceivingSendingMailInProgress() Then
		Common.MessageToUser(NStr("en = 'Mail synchronization in progress. Please wait…';"));
		Return Undefined;
	EndIf;
	
	ProcedureParameters = New Structure;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Mail Sync';");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground("EmailManagement.SendReceiveUserEmail",
		ProcedureParameters,	ExecutionParameters);
	Return TimeConsumingOperation;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
//  Other

// Parameters:
//  InteractionsArray - Array -  array of interactions for which the item will be set.
//  SubjectOf  - AnyRef -  the item that will be replaced.
//  CheckIfThereAreOtherChains - Boolean -  if True, the item will also be replaced for interactions
//                                           that are part of the chain of interactions, the first interaction of which
//                                           is the interaction included in the array.
//
Procedure SetSubjectForInteractionsArray(InteractionsArray, SubjectOf, CheckIfThereAreOtherChains = False) Export

	If CheckIfThereAreOtherChains Then
		
		Query = New Query;
		Query.Text = "SELECT DISTINCT
		|	InteractionsSubjects.Interaction AS Ref
		|FROM
		|	InformationRegister.InteractionsFolderSubjects AS InteractionsSubjects
		|WHERE
		|	NOT (NOT InteractionsSubjects.SubjectOf IN (&InteractionsArray)
		|			AND NOT InteractionsSubjects.Interaction IN (&InteractionsArray))";
		
		Query.SetParameter("InteractionsArray", InteractionsArray);
		InteractionsArray = Query.Execute().Unload().UnloadColumn("Ref");
		
	EndIf;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		InformationRegisters.InteractionsFolderSubjects.BlockInteractionFoldersSubjects(Block, InteractionsArray);
		Block.Lock();
		
		If TypeOf(SubjectOf) = Type("InformationRegisterRecordKey.InteractionsSubjectsStates") Then
			SubjectOf = SubjectOf.SubjectOf;
		EndIf;
		
		Query = New Query;
		Query.Text = "SELECT DISTINCT
		|	InteractionsFolderSubjects.SubjectOf
		|FROM
		|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|WHERE
		|	InteractionsFolderSubjects.Interaction IN(&InteractionsArray)
		|
		|UNION ALL
		|
		|SELECT
		|	&SubjectOf";
		
		Query.SetParameter("SubjectOf", SubjectOf);
		Query.SetParameter("InteractionsArray", InteractionsArray);
		
		SubjectsSelection = Query.Execute().Select();
		
		For Each Interaction In InteractionsArray Do
			Interactions.SetSubject(Interaction, SubjectOf, False);
		EndDo;
		
		Interactions.CalculateReviewedBySubjects(Interactions.TableOfDataForReviewedCalculation(SubjectsSelection, "SubjectOf"));
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;	
EndProcedure

// 
//
// Parameters:
//  MailMessage                  - DocumentRef.IncomingEmail
//                          - DocumentRef.OutgoingEmail - 
//  UUID - UUID -  unique ID of the form that the save command was called from.
//
// Returns:
//   See FileDataStructure
//
Function EmailDataToSaveAsFile(MailMessage, UUID) Export

	FileData = FileDataStructure();
	
	EmailData = Interactions.InternetEmailMessageFromEmail(MailMessage);
	If EmailData <> Undefined Then
		
		BinaryData = EmailData.InternetMailMessage.GetSourceData(); // BinaryData
		FileData.RefToBinaryFileData = PutToTempStorage(BinaryData, UUID);

		FileData.Description = Interactions.EmailPresentation(EmailData.InternetMailMessage.Subject,
			EmailData.EmailDate);
		
		FileData.Extension  = "eml";
		FileData.FileName    = FileData.Description + "." + FileData.Extension;
		FileData.Size      = BinaryData.Size();
		FolderForSaveAs = Common.CommonSettingsStorageLoad("ApplicationSettings", "FolderForSaveAs");
		FileData.Insert("FolderForSaveAs", FolderForSaveAs);
		FileData.UniversalModificationDate = CurrentSessionDate();
		FileData.FullVersionDescription = FileData.FileName;
		
	EndIf;
	
	Return FileData;

EndFunction

// Returns:
//  Structure:
//   * RefToBinaryFileData - String
//   * RelativePath - String
//   * UniversalModificationDate - Date
//   * FileName - String
//   * Description - String
//   * Extension - String
//   * Size - String
//   * BeingEditedBy - Undefined
//   * SignedWithDS - Boolean
//   * Encrypted - Boolean
//   * FileBeingEdited - Boolean
//   * CurrentUserEditsFile - Boolean
//   * FullVersionDescription - String
//
Function FileDataStructure()

	FileDataStructure = New Structure;
	FileDataStructure.Insert("RefToBinaryFileData",        "");
	FileDataStructure.Insert("RelativePath",                  "");
	FileDataStructure.Insert("UniversalModificationDate",       Date(1, 1, 1));
	FileDataStructure.Insert("FileName",                           "");
	FileDataStructure.Insert("Description",                       "");
	FileDataStructure.Insert("Extension",                         "");
	FileDataStructure.Insert("Size",                             "");
	FileDataStructure.Insert("BeingEditedBy",                        Undefined);
	FileDataStructure.Insert("SignedWithDS",                         False);
	FileDataStructure.Insert("Encrypted",                         False);
	FileDataStructure.Insert("FileBeingEdited",                  False);
	FileDataStructure.Insert("CurrentUserEditsFile", False);
	FileDataStructure.Insert("FullVersionDescription",           "");
	
	Return FileDataStructure;

EndFunction 

Procedure EnableSendingAndReceivingEmails() Export
	
	Interactions.EnableSendingAndReceivingEmails();
	
EndProcedure

#EndRegion
