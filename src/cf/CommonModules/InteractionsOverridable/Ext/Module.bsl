///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called to get contacts (participants) for the specified interaction subject.
// Used if at least one interaction item is defined in the configuration.
//
// Parameters:
//  ContactsTableName   - String -  the name of the table object interactions in which you want to search.
//                                   For Example, " Documents.Customer's order".
//  QueryTextForSearch - String -  this parameter to specify the fragment query to search for. When executing 
//                                   a request, a link to the interaction object is inserted in the request parameter &Subject.
//
Procedure OnSearchForContacts(Val ContactsTableName, QueryTextForSearch) Export
	
	
	
EndProcedure	

// Allows you to redefine the owner of attached files for a message.
// This may be necessary, for example, for mass mailings, when it makes sense 
// to store the same attached files in one place, rather than replicating them to all mailing messages.
//
// Parameters:
//  MailMessage - DocumentRef.IncomingEmail
//         - DocumentRef.OutgoingEmail -  
//           
//  AttachedFiles - Structure - :
//    * FilesOwner                     - DefinedType.AttachedFile -  owner of the attached files.
//    * AttachedFilesCatalogName - String -  name of the attached file metadata object.
//
Procedure OnReceiveAttachedFiles(MailMessage, AttachedFiles) Export

EndProcedure

// Called to configure the logic of restricting access to interactions.
// For an example of filling in access value sets, see in the comments
// to the Access control procedure.Fill in the set of access values.
//
// Parameters:
//  Object - DocumentObject.Meeting
//         - DocumentObject.PlannedInteraction
//         - DocumentObject.SMSMessage
//         - DocumentObject.PhoneCall
//         - DocumentObject.IncomingEmail
//         - DocumentObject.OutgoingEmail -  the object for which you need to fill sets.
//  Table - See AccessManagement.AccessValuesSetsTable
//
Procedure OnFillingAccessValuesSets(Object, Table) Export
	
	
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
// 
//
// Parameters:
//  DeletePutInTempTable - Boolean -  always a Lie.
//  TableName                        - String -  the name of the table object interactions in which a search will be performed.
//  DeleteMerge                 - Boolean -  always the Truth.
//
// Returns:
//  String -  query text.
//
Function QueryTextContactsSearchBySubject(DeletePutInTempTable, TableName, DeleteMerge = False) Export
	
	Return "";
	
EndFunction

// Deprecated.
// 
//  
// 
//
// Parameters:
//  MailMessage  - DocumentRef
//          - DocumentObject - 
//
// Returns:
//  Structure, Undefined  - 
//                             :
//                              * Owner - DefinedType.AttachedFile -  owner of the attached files.
//                              * CatalogNameAttachedFiles - String -  name of the attached file metadata object.
//
Function AttachedEmailFilesMetadataObjectData(MailMessage) Export
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion
