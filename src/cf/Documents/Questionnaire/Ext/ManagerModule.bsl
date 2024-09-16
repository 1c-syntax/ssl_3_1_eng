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

// Returns object details that can be edited
// by processing group changes to details.
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("Respondent");
	Result.Add("EditDate");
	Result.Add("Comment");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// 

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	IsAuthorizedUser(Respondent)
	|	OR IsAuthorizedUser(Interviewer)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS Questionnaire
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersRespondent
	|	ON ExternalUsersRespondent.AuthorizationObject = Questionnaire.Respondent
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersInterviewer
	|	ON ExternalUsersInterviewer.AuthorizationObject = Questionnaire.Interviewer
	|;
	|AllowReadUpdate
	|WHERE
	|	IsAuthorizedUser(ExternalUsersRespondent.Ref)
	|	OR IsAuthorizedUser(ExternalUsersInterviewer.Ref)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// 

// Registers objects
// that need to be updated to the new version on the exchange plan for updating the information Database.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	Questionnaire.Ref
		|FROM
		|	Document.Questionnaire AS Questionnaire
		|WHERE
		|	Questionnaire.SurveyMode = &EmptyRef
		|
		|ORDER BY
		|	Questionnaire.Date DESC";
	Query.Parameters.Insert("EmptyRef", Enums.SurveyModes.EmptyRef());
	
	Result = Query.Execute().Unload();
	ReferencesArrray = Result.UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, ReferencesArrray);
	
EndProcedure

// Fill in the value of the New questionnaire details in the Questionnaire document.
// 
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Document.Questionnaire");
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	While Selection.Next() Do
		RepresentationOfTheReference = String(Selection.Ref);
		Try
			
			FillSurveyModeAttribute(Selection);
			ObjectsProcessed = ObjectsProcessed + 1;
			
		Except
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				Selection.Ref,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Document.Questionnaire");
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t process (skipped) some questionnaires: %1';"), ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Documents.Questionnaire,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Yet another batch of questionnaires is processed: %1';"), ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Fills in the value of the new Questionnaire details for the transmitted document.
//
Procedure FillSurveyModeAttribute(Selection)
	
	BeginTransaction();
	Try
	
		Block = New DataLock;
		LockItem = Block.Add("Document.Questionnaire");
		LockItem.SetValue("Ref", Selection.Ref);
		Block.Lock();
		
		DocumentObject = Selection.Ref.GetObject();
		
		If DocumentObject.SurveyMode <> Enums.SurveyModes.EmptyRef() Then
			InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			CommitTransaction();
			Return;
		EndIf;
		
		DocumentObject.SurveyMode = Enums.SurveyModes.Questionnaire;
		
		InfobaseUpdate.WriteData(DocumentObject);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf