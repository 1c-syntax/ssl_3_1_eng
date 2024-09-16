///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Adds a flag for changing the deletion mark of the document.
// The composition of the procedure parameters corresponds to the subscription to the event before recording the Document object.
// For a description, see in the syntax assistant.
//
// Parameters:
//  Source  - DocumentObject -  source of the subscription event.
//  Cancel     - Boolean         -  indicates that the recording was rejected. If set to True, the record will not be executed 
//                               and an exception will be thrown.
//  WriteMode     - DocumentWriteMode     -  the current recording mode of the source document.
//  PostingMode - DocumentPostingMode -  current mode of holding the source document.
//
Procedure SetDocumentDeletionMarkChangeStatus(Source, Cancel, WriteMode, PostingMode) Export
	UserNotesInternal.SetDeletionMarkChangeStatus(Source);
EndProcedure

// Adds a flag for changing the object deletion tag.
// The composition of the procedure parameters corresponds to subscribing to the event before recording any objects, except documents.
// For a description, see in the syntax assistant.
//
// Parameters:
//  Source - CatalogObject -  source of the subscription event.
//  Cancel    - Boolean -  indicates that the recording was rejected. If set to True, the record will not be executed
//                      and an exception will be thrown.
//
Procedure SetObjectDeletionMarkChangeStatus(Source, Cancel) Export
	UserNotesInternal.SetDeletionMarkChangeStatus(Source);
EndProcedure

#EndRegion
