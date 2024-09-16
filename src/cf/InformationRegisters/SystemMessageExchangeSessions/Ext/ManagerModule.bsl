///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Creates a new messaging session and returns its ID
//
Function NewSession() Export
	
	Session = New UUID;
	
	RecordStructure = New Structure("Session, StartDate", Session, CurrentUniversalDate());
	
	AddRecord(RecordStructure);
	
	Return Session;
EndFunction

// Gets the session status: Running, Successful, Error.
//
Function SessionStatus(Val Session) Export
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN SystemMessageExchangeSessions.OperationFailed
	|			THEN ""Error""
	|		WHEN SystemMessageExchangeSessions.OperationSuccessful
	|			THEN ""Success""
	|		ELSE ""Running""
	|	END AS Result
	|FROM
	|	InformationRegister.SystemMessageExchangeSessions AS SystemMessageExchangeSessions
	|WHERE
	|	SystemMessageExchangeSessions.Session = &Session";
	Record = RecordMessagesExchangeSession(QueryText, Session);
	
	Return Record.Result;
	
EndFunction

// Marks the successful completion of the session
//
Procedure CommitSuccessfulSession(Val Session) Export
	
	RecordStructure = New Structure;
	RecordStructure.Insert("Session", Session);
	RecordStructure.Insert("OperationSuccessful", True);
	RecordStructure.Insert("OperationFailed", False);
	
	UpdateRecord(RecordStructure);
	
EndProcedure

// Notes the failure of the session
//
Procedure CommitUnsuccessfulSession(Val Session, Val ErrorDescription = "") Export
	
	RecordStructure = New Structure;
	RecordStructure.Insert("Session", Session);
	RecordStructure.Insert("OperationSuccessful", False);
	RecordStructure.Insert("OperationFailed", True);
	RecordStructure.Insert("ErrorDescription", ErrorDescription);
	
	UpdateRecord(RecordStructure);
	
EndProcedure

// Saves session data and marks the successful completion of the session
//
Procedure SaveSessionData(Val Session, Data) Export
	
	RecordStructure = New Structure;
	RecordStructure.Insert("Session", Session);
	RecordStructure.Insert("Data", Data);
	RecordStructure.Insert("OperationSuccessful", True);
	RecordStructure.Insert("OperationFailed", False);
	UpdateRecord(RecordStructure);
	
EndProcedure

// Retrieves session data and deletes the session from the database
//
Function GetSessionData(Val Session) Export
	
	QueryText =
	"SELECT
	|	SystemMessageExchangeSessions.Data AS Data
	|FROM
	|	InformationRegister.SystemMessageExchangeSessions AS SystemMessageExchangeSessions
	|WHERE
	|	SystemMessageExchangeSessions.Session = &Session";
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.SystemMessageExchangeSessions");
		LockItem.SetValue("Session", Session);
		Block.Lock();
		
		Record = RecordMessagesExchangeSession(QueryText, Session);
		
		Result = Record.Data;
		
		DeleteRecord(Session);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Result;
	
EndFunction

// 
//
Function SessionErrorDetails(Val Session) Export
	
	QueryText =
		"SELECT
		|	SystemMessageExchangeSessions.ErrorDescription AS ErrorDescription
		|FROM
		|	InformationRegister.SystemMessageExchangeSessions AS SystemMessageExchangeSessions
		|WHERE
		|	SystemMessageExchangeSessions.Session = &Session";
	
	Record = RecordMessagesExchangeSession(QueryText, Session);
	
	Return Record.ErrorDescription;
	
EndFunction

// 

Function RecordMessagesExchangeSession(QueryText, Session)
	
	Query = New Query(QueryText);
	Query.SetParameter("Session", Session);
	
	Selection = Query.Execute().Select();
	
	If Not Selection.Next() Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'System message exchange session with ID %1 not found.';"),
			String(Session));
	EndIf;
	
	Return Selection;
	
EndFunction

Procedure AddRecord(RecordStructure)
	
	DataExchangeInternal.AddRecordToInformationRegister(RecordStructure, "SystemMessageExchangeSessions");
	
EndProcedure

Procedure UpdateRecord(RecordStructure)
	
	DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "SystemMessageExchangeSessions");
	
EndProcedure

Procedure DeleteRecord(Val Session)
	
	DataExchangeInternal.DeleteRecordSetFromInformationRegister(New Structure("Session", Session), "SystemMessageExchangeSessions");
	
EndProcedure

#EndRegion

#EndIf