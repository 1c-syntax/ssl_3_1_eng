///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Operations with office document templates.

// Gets all data required for printing within a single call: object template data, binary
// template data, and template area description.
// Used for calling print forms based on office document templates from client modules.
//
// Parameters:
//   PrintManagerName - String - a name for accessing the object manager, for example, "Document.<Document name>".
//   TemplatesNames       - String - names of templates used for print form generation.
//   DocumentsComposition   - Array - references to infobase objects (all references must be of the same type).
//
// Returns:
//  Map of KeyAndValue - 
//   * Key - AnyRef - reference to an infobase object;
//   * Value - Structure:
//       ** Key - String - template name;
//       ** Value - Structure - object data.
//
Function TemplatesAndObjectsDataToPrint(Val PrintManagerName, Val TemplatesNames, Val DocumentsComposition) Export
	
	Return PrintManagement.TemplatesAndObjectsDataToPrint(PrintManagerName, TemplatesNames, DocumentsComposition);
	
EndFunction

#EndRegion

#Region Private

// Generates print forms for direct output to a printer.
//
// Detailed - for details, see PrintManagement.GeneratePrintFormsForQuickPrint(). 
//
Function GeneratePrintFormsForQuickPrint(PrintManagerName, TemplatesNames, ObjectsArray,	PrintParameters) Export
	
	Return PrintManagement.GeneratePrintFormsForQuickPrint(PrintManagerName, TemplatesNames,
		ObjectsArray,	PrintParameters);
	
EndFunction

// Generates print forms for direct output to a printer in an ordinary application.
//
// Detailed - for details, see PrintManagement.GeneratePrintFormsForQuickPrintOrdinaryApplication(). 
//
Function GeneratePrintFormsForQuickPrintOrdinaryApplication(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters) Export
	
	Return PrintManagement.GeneratePrintFormsForQuickPrintOrdinaryApplication(PrintManagerName, TemplatesNames,
		ObjectsArray,	PrintParameters);
	
EndFunction

// Returns True if the user is authorized to post at least one document.
Function HasRightToPost(DocumentsList) Export
	Return StandardSubsystemsServer.HasRightToPost(DocumentsList);
EndFunction

// See PrintManagement.DocumentsPackage.
Function DocumentsPackage(SpreadsheetDocuments, PrintObjects, PrintInSets, Copies = 1) Export
	
	Return PrintManagement.DocumentsPackage(SpreadsheetDocuments, PrintObjects,
		PrintInSets, Copies);
	
EndFunction

#EndRegion
