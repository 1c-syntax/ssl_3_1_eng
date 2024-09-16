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
	Result.Add("IsRequired");
	Result.Add("Notes");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

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
		|	QuestionnaireTemplateQuestions.Ref
		|FROM
		|	Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
		|WHERE
		|	QuestionnaireTemplateQuestions.HintPlacement = &EmptyRef";
	Query.Parameters.Insert("EmptyRef", Enums.TooltipDisplayMethods.EmptyRef());
	
	Result = Query.Execute().Unload();
	ReferencesArrray = Result.UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, ReferencesArrray);
	
EndProcedure

// Fill in the value of the new detail of the method of displaying a Statement in the reference list of questionsanquettes.
// 
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.QuestionnaireTemplateQuestions");
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	While Selection.Next() Do
		RepresentationOfTheReference = String(Selection.Ref);
		Try
			
			FillTooltipDisplayMethodAttribute(Selection);
			ObjectsProcessed = ObjectsProcessed + 1;
			
		Except
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				Selection.Ref,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.QuestionnaireTemplateQuestions");
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t process (skipped) some questionnaire template questions: %1';"), 
				ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Catalogs.QuestionnaireTemplateQuestions,,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Yet another batch of questionnaire template questions is processed: %1';"),
					ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Fills in the value of the new detail of the display method for the passed object.
//
Procedure FillTooltipDisplayMethodAttribute(Selection)
	
	BeginTransaction();
	Try
	
		Block = New DataLock;
		LockItem = Block.Add("Catalog.QuestionnaireTemplateQuestions");
		LockItem.SetValue("Ref", Selection.Ref);
		Block.Lock();
		
		CatalogObject = Selection.Ref.GetObject();
		
		If CatalogObject.HintPlacement <> Enums.TooltipDisplayMethods.EmptyRef() Then
			RollbackTransaction();
			InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			Return;
		EndIf;
		
		CatalogObject.HintPlacement = Enums.TooltipDisplayMethods.AsTooltip;
		
		InfobaseUpdate.WriteData(CatalogObject);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf
