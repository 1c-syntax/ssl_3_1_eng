///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Writes the object version (other than documents) to the information database.
//
// Parameters:
//  Source - CatalogObject -  write the object IB;
//  Cancel    - Boolean -  indicates that the object was not recorded.
//
Procedure WriteObjectVersion(Source, Cancel) Export
	
	// 
	// 
	If Source.DataExchange.Load And Source.DataExchange.Sender = Undefined Then
		Return;
	EndIf;
	
	ObjectsVersioning.WriteObjectVersion(Source, False);
	
EndProcedure

// Writes the document version to the information database.
//
// Parameters:
//  Source        - DocumentObject -  recordable IB document;
//  Cancel           - Boolean -  indicates that the document was not recorded.
//  WriteMode     - DocumentWriteMode -  allows you to determine whether recording, holding, or canceling is in progress.
//                                           Changing the parameter value allows you to change the recording mode.
//  PostingMode - DocumentPostingMode -  allows you to determine whether or not an operational survey is being performed.
//                                               Changing the parameter value allows you to change the holding mode.
//
Procedure WriteDocumentVersion(Source, Cancel, WriteMode, PostingMode) Export
	
	// 
	// 
	If Source.DataExchange.Load And Source.DataExchange.Sender = Undefined Then
		Return;
	EndIf;

	ObjectsVersioning.WriteObjectVersion(Source, WriteMode);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 

// For internal use only.
//
Procedure DeleteVersionAuthorInfo(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	InformationRegisters.ObjectsVersions.DeleteVersionAuthorInfo(Source.Ref);
	
EndProcedure

#EndRegion
