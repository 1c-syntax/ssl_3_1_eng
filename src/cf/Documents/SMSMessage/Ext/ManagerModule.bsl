﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.Interactions

// Gets an array of structures and the SMS Message document addressees.
//
// Parameters:
//  Ref  - DocumentRef.SMSMessage - a document, for which an array of contacts is being received.
//
// Returns:
//   Array of Structure:
//    * Address - String
//    * Presentation - String
//    * Contact - AnyRef
//
Function GetContacts(Ref) Export
	
	Return Interactions.GetParticipantsByTable(Ref);
	
EndFunction

// End StandardSubsystems.Interactions

// StandardSubsystems.BatchEditObjects

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("Author");
	Result.Add("Importance");
	Result.Add("EmployeeResponsible");
	Result.Add("InteractionBasis");
	Result.Add("Comment");
	Result.Add("SMSMessageRecipients.Contact");
	Result.Add("SMSMessageRecipients.ContactPresentation");
	Result.Add("SMSMessageRecipients.HowToContact");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(EmployeeResponsible, Disabled AS FALSE)
	|	OR ValueAllowed(Author, Disabled AS FALSE)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.AttachableCommands

// Defines the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.Meeting.AddGenerateCommand(GenerationCommands);
	Documents.PlannedInteraction.AddGenerateCommand(GenerationCommands);
	AddGenerateCommand(GenerationCommands);
	Documents.PhoneCall.AddGenerateCommand(GenerationCommands);
	Documents.OutgoingEmail.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Intended for use by the AddGenerationCommands procedure in other object manager modules.
// Adds this object to the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - Details of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Command = GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.SMSMessage);
	If Command <> Undefined Then
		Command.FunctionalOptions = "UseOtherInteractions";
		Command.Importance = "SeeAlso";
	EndIf;
	
	Return Command;
	
EndFunction

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	InteractionsEvents.ChoiceDataGetProcessing(Metadata.Documents.SMSMessage.Name,
		ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#EndIf