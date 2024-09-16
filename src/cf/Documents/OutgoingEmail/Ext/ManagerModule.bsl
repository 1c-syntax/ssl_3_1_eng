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
	Result.Add("Importance");
	Result.Add("EmployeeResponsible");
	Result.Add("InteractionBasis");
	Result.Add("Comment");
	Result.Add("EmailRecipients.Presentation");
	Result.Add("EmailRecipients.Contact");
	Result.Add("CCRecipients.Presentation");
	Result.Add("CCRecipients.Contact");
	Result.Add("ReplyRecipients.Presentation");
	Result.Add("ReplyRecipients.Contact");
	Result.Add("BccRecipients.Presentation");
	Result.Add("BccRecipients.Contact");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// 

// Gets the recipients the email.
//
// Parameters:
//  Ref  - DocumentRef.OutgoingEmail -  the document to get the subscriber for.
//
// Returns:
//   ValueTable   - 
//
Function GetContacts(Ref) Export
	
	QueryText = 
	"SELECT
	|	EmailOutgoingEmailRecipients.Address,
	|	EmailOutgoingEmailRecipients.Presentation,
	|	EmailOutgoingEmailRecipients.Contact
	|FROM
	|	Document.OutgoingEmail.EmailRecipients AS EmailOutgoingEmailRecipients
	|WHERE
	|	EmailOutgoingEmailRecipients.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	EMailOutgoingCopyRecipients.Address,
	|	EMailOutgoingCopyRecipients.Presentation,
	|	EMailOutgoingCopyRecipients.Contact
	|FROM
	|	Document.OutgoingEmail.CCRecipients AS EMailOutgoingCopyRecipients
	|WHERE
	|	EMailOutgoingCopyRecipients.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	EmailOutgoingReplyRecipients.Address,
	|	EmailOutgoingReplyRecipients.Presentation,
	|	EmailOutgoingReplyRecipients.Contact
	|FROM
	|	Document.OutgoingEmail.ReplyRecipients AS EmailOutgoingReplyRecipients
	|WHERE
	|	EmailOutgoingReplyRecipients.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	EmailOutgoingRecipientsOfHiddenCopies.Address,
	|	EmailOutgoingRecipientsOfHiddenCopies.Presentation,
	|	EmailOutgoingRecipientsOfHiddenCopies.Contact
	|FROM
	|	Document.OutgoingEmail.BccRecipients AS EmailOutgoingRecipientsOfHiddenCopies
	|WHERE
	|	EmailOutgoingRecipientsOfHiddenCopies.Ref = &Ref";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", Ref);
	TableOfContacts = Query.Execute().Unload();
	
	Return Interactions.ConvertContactsTableToArray(TableOfContacts);
	
EndFunction

// End StandardSubsystems.Interactions

// 

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(EmployeeResponsible, Disabled AS FALSE)
	|	OR ValueAllowed(Author, Disabled AS FALSE)
	|	OR ValueAllowed(Account, Disabled AS FALSE)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

// Standard subsystems.Pluggable commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.Meeting.AddGenerateCommand(GenerationCommands);
	Documents.PlannedInteraction.AddGenerateCommand(GenerationCommands);
	Documents.SMSMessage.AddGenerateCommand(GenerationCommands);
	Documents.PhoneCall.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// To use in the procedure add a create command Based on other object Manager modules.
// Adds this object to the list of base creation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - 
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Command = GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.OutgoingEmail);
	If Command <> Undefined Then
		Command.Importance = "SeeAlso";
	EndIf;
	
	Return Command;
	
EndFunction

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	InteractionsEvents.ChoiceDataGetProcessing(Metadata.Documents.OutgoingEmail.Name,
		ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#Region Private

#Region UpdateHandlers

// Registers objects
// that need to be updated to the new version on the exchange plan for updating the information Database.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	QueryText ="
	|SELECT
	|	OutgoingEmail.Ref AS Ref
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail
	|WHERE
	|	OutgoingEmail.TextType = VALUE(Enum.EmailTextTypes.HTML)
	|	AND CASE
	|			WHEN (CAST(OutgoingEmail.Text AS STRING(1))) = """"
	|				THEN TRUE
	|			ELSE FALSE
	|		END
	|	AND CASE
	|			WHEN (CAST(OutgoingEmail.HTMLText AS STRING(1))) <> """"
	|				THEN TRUE
	|			ELSE FALSE
	|		END";
	
	Query = New Query(QueryText);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The handler of the update to version 3.1.5.147:
// - fills in the details of the Text, for letters in HTML format, for which it was not previously filled in.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.OutgoingEmail";
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DocumentTable.Ref     AS Ref
	|FROM
	|	&TTDocumentsToProcess AS ReferencesToProcess
	|		LEFT JOIN Document.OutgoingEmail AS DocumentTable
	|		ON (DocumentTable.Ref = ReferencesToProcess.Ref)";
	
	TempTablesManager = New TempTablesManager;
	Result = InfobaseUpdate.CreateTemporaryTableOfRefsToProcess(Parameters.Queue, FullObjectName, TempTablesManager);
	If Not Result.HasDataToProcess Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	If Not Result.HasRecordsInTemporaryTable Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf; 
	
	Query.Text = StrReplace(Query.Text, "&TTDocumentsToProcess", Result.TempTableName);
	Query.TempTablesManager = TempTablesManager;
	
	ObjectsForProcessing = Query.Execute().Select();
	
	While ObjectsForProcessing.Next() Do
		RepresentationOfTheReference = String(ObjectsForProcessing.Ref);
		BeginTransaction();
		
		Try
			
			// 
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", ObjectsForProcessing.Ref);
			
			Block.Lock();
			
			Object = ObjectsForProcessing.Ref.GetObject();
			
			If Object = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(ObjectsForProcessing.Ref);
			Else
				
				If Object.TextType = Enums.EmailTextTypes.HTML
					And Not IsBlankString(Object.HTMLText)
					And IsBlankString(Object.Text) Then
					
					Object.Text = Interactions.GetPlainTextFromHTML(Object.HTMLText);
					
				EndIf;
			
				InfobaseUpdate.WriteData(Object);
				
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				ObjectsForProcessing.Ref,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;
		
	EndDo;
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t update (skipped) outgoing email data: %1';"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Information,
			Metadata.Documents.OutgoingEmail,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Another batch of outgoing emails is processed: %1';"),
				ObjectsProcessed));
	EndIf;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
