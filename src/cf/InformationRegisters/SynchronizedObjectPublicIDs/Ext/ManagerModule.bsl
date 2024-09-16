///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// The procedure adds an entry to the register based on the passed structure values.
Procedure AddRecord(RecordStructure, Load = False) Export
	
	DataExchangeInternal.AddRecordToInformationRegister(RecordStructure, "SynchronizedObjectPublicIDs", Load);
	
EndProcedure

// Returns whether there is an entry in the register for the passed selection.
//
// Parameters:
//   RecordStructure - Structure:
//     * InfobaseNode - ExchangePlanRef -  the site plan of exchange.
//     * Ref - DocumentRef
//              - ChartOfCharacteristicTypesRef
//              - CatalogRef -  object reference.
//
// Returns:
//   Boolean - 
//
Function RecordIsInRegister(RecordStructure) Export
	
	Query = New Query(
	"SELECT TOP 1
	|	TRUE AS IsRecord
	|FROM
	|	InformationRegister.SynchronizedObjectPublicIDs AS PIR
	|WHERE
	|	PIR.InfobaseNode = &InfobaseNode
	|	AND PIR.Ref = &Ref");
	Query.SetParameter("InfobaseNode", RecordStructure.InfobaseNode);
	Query.SetParameter("Ref",                 RecordStructure.Ref);
	
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

// The procedure deletes a set of entries in the register based on the passed structure values.
Procedure DeleteRecord(RecordStructure, Load = False) Export
	
	DataExchangeInternal.DeleteRecordSetFromInformationRegister(RecordStructure, "SynchronizedObjectPublicIDs", Load);
	
EndProcedure

// Converts a reference to the current database object to a string representation of the UID.
// If there is such a reference in the register of public identifiers of synchronized Objects, the UID from the register is returned.
// Otherwise, the UID of the passed link is returned.
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef - 
//  ObjectReference - AnyRef - 
//                   
//
// Returns:
//  String - 
//
Function PublicIDByObjectRef(InfobaseNode, ObjectReference) Export
	
	// 
	// 
	//  
	If TypeOf(ObjectReference) = Type("UUID") Then
		
		Return TrimAll(ObjectReference);
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	// 
	Query = New Query(
	"SELECT
	|	PIR.Id AS Id
	|FROM
	|	InformationRegister.SynchronizedObjectPublicIDs AS PIR
	|WHERE
	|	PIR.InfobaseNode = &InfobaseNode
	|	AND PIR.Ref = &Ref");
	Query.SetParameter("InfobaseNode", InfobaseNode);
	Query.SetParameter("Ref",                 ObjectReference);
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 Then
		Selection.Next();
		Return TrimAll(Selection.Id);
	ElsIf Selection.Count() > 1 Then
		RecordStructure = New Structure();
		RecordStructure.Insert("InfobaseNode", InfobaseNode);
		RecordStructure.Insert("Ref",                 ObjectReference);
		DeleteRecord(RecordStructure, True);
	EndIf;
	
	Return TrimAll(ObjectReference.UUID());

EndFunction

#EndRegion

#EndIf