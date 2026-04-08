///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Overrides settings for tracking source document originals
//
// Parameters:
//  Settings - Structure:
//   * ShouldDisplayButtonsOnDocumentForm - Boolean - If "True", the external command interface for tracking 
//								source document originals is displayed on the document forms as buttons. 
//								If "False" the interface is displayed as a hyperlink. By Default, "False".
//   * ShouldDisplayHintInStatesChangeForm - Boolean - If "False", the information label is hidden from
//							    the form "Change document original state" when clarifying the print form state.
//								By default, "True".
//   * ShouldOpenDropDownMenuFromHyperlink - Boolean - If "False", clicking the hyperlink of the source document's original state
//								opens the form "Change document original state"
//								for clarifying the print form state.
//								By default, "True".
//
Procedure OnDefineSettings(Settings) Export
	
EndProcedure

// Allows you to define actions when writing the aggregated state of the original.
// 
// Parameters:
//  Document - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Reference to the document whose
//																			new aggregated state is being written.
//  OriginalState 	- CatalogRef.SourceDocumentsOriginalsStates - Reference to the state to apply.
//
Procedure OnChangeAggregatedOriginalState(Document, OriginalState) Export
			
EndProcedure

// Overrides the list of print objects and print forms before writing states after printing.
// 
//	Parameters:
//  PrintObjects - ValueList - List of references to print objects.
//  PrintList - ValueList - List with template names and print form presentations.
//
Procedure BeforeWriteOriginalStatesAfterPrint(PrintObjects, PrintList) Export 
	
EndProcedure

// Defines configuration objects whose list forms contain commands of source document tracking,
//
// Parameters:
//  ListOfObjects - Array of String - object managers with the AddPrintCommands procedure.
//
Procedure OnDefineObjectsWithOriginalsAccountingCommands(ListOfObjects) Export
	
	

EndProcedure

// Determines configuration objects that should be tracked with a breakdown by employee.
//
// Parameters:
//  ListOfObjects - Map of KeyAndValue:
//          * Key - MetadataObject
//          * Value - String - a description of the table where employees are stored.
//
Procedure WhenDeterminingMultiEmployeeDocuments(ListOfObjects) Export
	
	

EndProcedure

// Fills in the originals recording table
// If you leave the procedure body blank - states will be tracked by all print forms of attached objects.
// If you add objects attached to the originals recording subsystem and their print forms to the value table,
// states will be tracked only by them.
//  
// Parameters:
//   AccountingTableForOriginals - ValueTable - a collection of objects and templates to track originals:
//              * MetadataObject - MetadataObject
//              * Id - String - a template ID.
//
// Example:
//	 NewRow = OriginalsRecordingTable.Add();
//	 NewRow.MetadataObject = Metadata.Documents.GoodsSales;
//	 NewRow.ID = "SalesInvoice";
//
Procedure FillInTheOriginalAccountingTable(AccountingTableForOriginals) Export	
	
	

EndProcedure

#EndRegion
