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
	Result.Add("SenderContact");
	Result.Add("SenderPresentation");
	Result.Add("EmailRecipients.Presentation");
	Result.Add("EmailRecipients.Contact");
	Result.Add("CCRecipients.Presentation");
	Result.Add("CCRecipients.Contact");
	Result.Add("ReplyRecipients.Presentation");
	Result.Add("ReplyRecipients.Contact");
	Result.Add("ReadReceiptAddresses.Presentation");
	Result.Add("ReadReceiptAddresses.Contact");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// 

// Retrieves the sender and recipients of the email.
//
// Parameters:
//  Ref  - DocumentRef.IncomingEmail -  the document to get the subscriber for.
//
// Returns:
//   ValueTable   - 
//
Function GetContacts(Ref) Export

	QueryText = 
		"SELECT
		|	IncomingEmail.Account.Email AS AccountEmailAddress
		|INTO OurAddress
		|FROM
		|	Document.IncomingEmail AS IncomingEmail
		|WHERE
		|	IncomingEmail.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	IncomingEmail.SenderAddress AS Address,
		|	SUBSTRING(IncomingEmail.SenderPresentation, 1, 1000) AS Presentation,
		|	IncomingEmail.SenderContact AS Contact
		|INTO AllContacts
		|FROM
		|	Document.IncomingEmail AS IncomingEmail
		|WHERE
		|	IncomingEmail.Ref = &Ref
		|
		|UNION
		|
		|SELECT
		|	EmailIncomingEmailRecipients.Address,
		|	EmailIncomingEmailRecipients.Presentation,
		|	EmailIncomingEmailRecipients.Contact
		|FROM
		|	Document.IncomingEmail.EmailRecipients AS EmailIncomingEmailRecipients
		|WHERE
		|	EmailIncomingEmailRecipients.Ref = &Ref
		|
		|UNION
		|
		|SELECT
		|	EmailIncomingCopyRecipients.Address,
		|	EmailIncomingCopyRecipients.Presentation,
		|	EmailIncomingCopyRecipients.Contact
		|FROM
		|	Document.IncomingEmail.CCRecipients AS EmailIncomingCopyRecipients
		|WHERE
		|	EmailIncomingCopyRecipients.Ref = &Ref
		|
		|UNION
		|
		|SELECT
		|	EmailIncomingReplyRecipients.Address,
		|	EmailIncomingReplyRecipients.Presentation,
		|	EmailIncomingReplyRecipients.Contact
		|FROM
		|	Document.IncomingEmail.ReplyRecipients AS EmailIncomingReplyRecipients
		|WHERE
		|	EmailIncomingReplyRecipients.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllContacts.Address AS Address,
		|	MAX(AllContacts.Presentation) AS Presentation,
		|	MAX(AllContacts.Contact) AS Contact
		|FROM
		|	AllContacts AS AllContacts
		|		LEFT JOIN OurAddress AS OurAddress
		|		ON AllContacts.Address = OurAddress.AccountEmailAddress
		|WHERE
		|	OurAddress.AccountEmailAddress IS NULL
		|
		|GROUP BY
		|	AllContacts.Address";

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
	
	Command = GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.IncomingEmail);
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
	
	InteractionsEvents.ChoiceDataGetProcessing(Metadata.Documents.IncomingEmail.Name,
		ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#EndIf



