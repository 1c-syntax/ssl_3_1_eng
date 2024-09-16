///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// Parameters:
//   Table - See AccessManagement.AccessValuesSetsTable
//
Procedure FillAccessValuesSets(Table) Export
	
	InteractionsEvents.FillAccessValuesSets(ThisObject, Table);
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	PrevDeletionMark = False;
	If Not IsNew() Then
		PrevDeletionMark = Common.ObjectAttributeValue(Ref, "DeletionMark");
	EndIf;
	AdditionalProperties.Insert("DeletionMark", PrevDeletionMark);
	
	If DeletionMark <> PrevDeletionMark Then
		HasAttachments = ?(DeletionMark, False, FilesOperationsInternalServerCall.AttachedFilesCount(Ref) > 0);
	EndIf;

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Interactions.OnWriteDocument(ThisObject);
	Interactions.ProcessDeletionMarkChangeFlagOnWriteEmail(ThisObject);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	EmailManagement.DeleteEmailAttachments(Ref);
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf