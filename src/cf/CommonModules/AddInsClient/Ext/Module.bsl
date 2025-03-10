﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// Parameters for the call of the AddInClient.AttachAddInSSL procedure.
//
// Returns:
//  Structure:
//      * Cached - Boolean - Client add-in cache usage flag. By default, True.
//      * SuggestInstall - Boolean - (default value is True) prompt to install the add-in.
//      * SuggestToImport - Boolean - (default value is True) prompt to import the add-in from the ITS website.
//      * ExplanationText - String - a text that describes the add-in purpose and which functionality requires the add-in.
//      * ObjectsCreationIDs - Array - string array of object module instance.
//                Use it only for add-ins with several object creation IDs.
//                On specify, the ID parameter is used only to determine add-in.
//      * Isolated - Boolean, Undefined - If True, the add-in is attached isolatedly (it is uploaded to a separate OS process).
//                If False, the add-in is executed in the same OS process that runs the 1C:Enterprise code.
//                If Undefined, the add-in is executed according to the default 1C:Enterprise settings
//                Isolatedly if the add-in supports only isolated execution; otherwise, non-isolatedly.:
//                By default, Undefined.
//                See https://its.1c.eu/db/v83doc
//                                              #bookmark:dev:TI000001866
//      * AutoUpdate - Boolean - Flag indicating whether to set the UpdateFrom1CITSPortal flag for the uploaded add-in.
//                By default, True.
//
// Example:
//
//  AttachmentParameters = AddInClient.AttachmentParameters();
//  AttachmentParameters.NoteText = 
//      AttachmentParameters.NoteText = NStr("en = 'To use a barcode scanner, install
//                 |the 1C:Barcode scanners (NativeApi) add-in.'");
//
Function ConnectionParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Cached", True);
	Parameters.Insert("SuggestInstall", True);
	Parameters.Insert("SuggestToImport", True);
	Parameters.Insert("ExplanationText", "");
	Parameters.Insert("ObjectsCreationIDs", New Array);
	Parameters.Insert("Isolated", Undefined);
	Parameters.Insert("AutoUpdate", True);
	
	Return Parameters;
	
EndFunction

// Attaches the add-in based on Native API or COM technologies on the client computer.
// Web client can display the dialog box with installation tips.
// Checking whether the add-in can be executed on the current user client.
//
// Parameters:
//  Notification - NotifyDescription - connection notification details with the following parameters:
//      * Result - Structure - add-in attachment result:
//          ** Attached - Boolean - attachment flag;
//          ** Attachable_Module - AddInObject - an instance of the add-in;
//                                - FixedMap of KeyAndValue - Add-in object instances stored in
//                                      AttachmentParameters.ObjectsCreationIDs:
//                                    *** Key - String - the add-in ID;
//                                    *** Value - AddInObject - an instance of the add-in.
//          ** ErrorDescription - String - brief error message. Empty string on cancel by user.
//      * AdditionalParameters - Structure - a value that was specified on creating the NotifyDescription object.
//  Id - String - the add-in identification code.
//  Version        - String - an add-in version.
//  ConnectionParameters - See AddInsClient.ConnectionParameters.
//
// Example:
//
//  Notification = New NotifyDescription("AttachAddInSSLCompletion", ThisObject);
//
//  AttachmentParameters = AddInClient.AttachmentParameters();
//  AttachmentParameters.NoteText = 
//      NStr("en = 'To use a barcode scanner, install
//                 |the 1C:Barcode scanners (NativeApi) add-in.'");
//
//  AddInClient.AttachAddInSSL(Notification,"InputDevice",, AttachmentParameters);
//
//  &AtClient
//  Procedure AttachAddInSSLCompletion(Result, AdditionalParameters) Export
//
//      AttachableModule = Undefined;
//
//      If Result.Attached Then 
//          AttachableModule = Result.AttachableModule;
//      Else
//          If Not IsBlankString(Result.ErrorDetails) Then
//              ShowMessageBox (, Result.ErrorDetails);
//          EndIf;
//      EndIf;
//
//      If AttachableModule <> Undefined Then 
//          // AttachableModule contains the instance of the attached add-in.
//      EndIf;
//
//      AttachableModule = Undefined;
//
//  EndProcedure
//
Procedure AttachAddInSSL(Notification, Id, Version = Undefined,
	ConnectionParameters = Undefined) Export
	
	If ConnectionParameters = Undefined Then
		ConnectionParameters = ConnectionParameters();
	EndIf;
	
	Context = CommonInternalClient.AddInAttachmentContext();
	FillPropertyValues(Context, ConnectionParameters);
	Context.Notification = Notification;
	Context.Id = Id;
	Context.Version = Version;
	
	AddInsInternalClient.AttachAddInSSL(Context);
	
EndProcedure

// Attaches the add-in based on COM technology from Windows registry in asynchronous mode.
// (not recommended for backward compatibility with 1C:Enterprise 7.7 add-ins). 
//
// Parameters:
//  Notification - NotifyDescription - connection notification details with the following parameters:
//      * Result - Structure - add-in attachment result:
//          ** Attached - Boolean - attachment flag.
//          ** Attachable_Module - AddInObject  - an instance of the add-in.
//          ** ErrorDescription - String - brief error message.
//      * AdditionalParameters - Structure - a value that was specified on creating the NotifyDescription object.
//  Id - String - the add-in identification code.
//  ObjectCreationID - String - object creation ID of object module instance
//          (only for add-ins with object creation ID different from ProgID).
//
// Example:
//
//  Notification = New NotifyDescription("PrintDocumentCompletion", ThisObject);
//  AddInClient.AttachAddInFromWindowsRegistry(Notification, "SBRFCOMObject", "SBRFCOMExtension");
//
//  &AtClient
//  Procedure AttachAddInSSLCompletion(Result, AdditionalParameters) Export
//
//      AttachableModule = Undefined;
//
//      If Result.Attached Then 
//          AttachableModule = Result.AttachableModule;
//      Else 
//          ShowMessageBox (, Result.ErrorDetails);
//      EndIf;
//
//      If AttachableModule <> Undefined Then 
//          // AttachableModule contains the instance of the attached add-in.
//      EndIf;
//
//      AttachableModule = Undefined;
//
//  EndProcedure
//
Procedure AttachAddInFromWindowsRegistry(Notification, Id,
	ObjectCreationID = Undefined) Export 
	
	Context = AddInsInternalClient.ConnectionContextComponentsFromTheWindowsRegistry();
	Context.Notification = Notification;
	Context.Id = Id;
	Context.ObjectCreationID = ObjectCreationID;
	
	AddInsInternalClient.AttachAddInFromWindowsRegistry(Context);
	
EndProcedure

// Structure of parameters for the AddInClient.InstallAddInSSL procedure.
//
// Returns:
//  Structure:
//      * ExplanationText - String - a text that describes the add-in purpose and which functionality requires the add-in.
//      * SuggestToImport - Boolean - prompt to import the add-in from the ITS website
//      * SuggestInstall - Boolean - (default value is False) prompt to install the add-in.
//
// Example:
//
//  InstallationParameters = AddInClient.InstallationParameters();
//  InstallationParameters.NoteText = 
//      NStr("en = 'To use a barcode scanner, install
//                 |the 1C:Barcode scanners (NativeApi) add-in.'");
//
Function InstallationParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("ExplanationText", "");
	Parameters.Insert("SuggestToImport", True);
	Parameters.Insert("SuggestInstall", False);
	
	Return Parameters;
	
EndFunction

// Connects an add-in based on Native API and COM technology in an asynchronous mode.
// Checking whether the add-in can be executed on the current user client.
//
// Parameters:
//  Notification - NotifyDescription - notification details of add-in installation:
//      * Result - Structure - Add-in installation result:
//          ** IsSet - Boolean - installation flag.
//          ** ErrorDescription - String - brief error message. Empty string on cancel by user.
//      * AdditionalParameters - Structure - a value that was specified on creating the NotifyDescription object.
//  Id - String - the add-in identification code.
//  Version - String - an add-in version.
//  InstallationParameters - See InstallationParameters.
//
// Example:
//
//  Notification = New NotifyDescription("SetCompletionComponent", ThisObject);
//
//  InstallationParameters = AddInClient.InstallationParameters();
//  InstallationParameters.ExplanationText = 
//      NStr("en = 'To use a barcode scanner, install
//                 |the 1C:Barcode scanners (NativeApi) add-in.'");
//
//  AddInClient.InstallAddIn(Notification,"InputDevice",, InstallationParameters);
//
//  &AtClient
//  Procedure InstallAddInEnd(Result, AdditionalParameters) Export
//
//      If Not Result.Installed and Not EmptyString(Result.ErrorDetails) Then 
//          ShowMessageBox (, Result.ErrorDetails);
//      EndIf;
//
//  EndProcedure
//
Procedure InstallAddInSSL(Notification, Id, Version = Undefined, 
	InstallationParameters = Undefined) Export
	
	If InstallationParameters = Undefined Then
		InstallationParameters = InstallationParameters();
	EndIf;
	
	Context = CommonInternalClient.AddInAttachmentContext();
	Context.Notification = Notification;
	Context.Id = Id;
	Context.Version = Version;
	Context.ExplanationText = InstallationParameters.ExplanationText;
	Context.SuggestToImport = InstallationParameters.SuggestToImport;
	Context.SuggestInstall = InstallationParameters.SuggestInstall;
		
	AddInsInternalClient.InstallAddInSSL(Context);
	
EndProcedure


// Returns a parameter structure to describe search rules of additional information within an add-in.
// See the ImportAddInFromFile procedure.
//
// Returns:
//  Structure:
//      * XMLFileName - String - (optional) file name within an add-in from which information is extracted.
//      * XPathExpression - String - (optional) XPath path to information in the file.
//
// Example:
//
//  ImportParameters = AddInClient.AdditionalInformationSearchParameters();
//  ImportParameters.XMLFileName = "INFO.XML";
//  ImportParameters.XPathExpression = "//drivers/component/@type";
//
Function AdditionalInformationSearchParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("XMLFileName", "");
	Parameters.Insert("XPathExpression", "");
	
	Return Parameters;
	
EndFunction

// Structure of parameters for the AddInClient.ImportAddInFromFile procedure.
//
// Returns:
//  Structure:
//      * Id - String -(optional) add-in object ID.
//      * Version - String - (Optional) Add-in version.
//      * AdditionalInformationSearchParameters - Map of KeyAndValue - (optional) parameters:
//          ** Key - String - requested additional information ID.
//          ** Value - See AdditionalInformationSearchParameters.
// Example:
//
//  ImportParameters = AddInClient.ImportParameters();
//  ImportParameters.ID = "InputDevice";
//  ImportParameters.Version = "8.1.7.10";
//
Function ImportParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Id", Undefined);
	Parameters.Insert("Version", Undefined);
	Parameters.Insert("AdditionalInformationSearchParameters", New Map);
	
	Return Parameters;
	
EndFunction

// Imports add-in file to the add-ins catalog in asynchronous mode. 
//
// Parameters:
//  Notification - NotifyDescription - notification details of add-in installation:
//      * Result - Structure - import add-in result:
//          ** Imported1 - Boolean - imported flag.
//          ** Id  - String - the add-in identification code.
//          ** Version - String - version of the imported add-in.
//          ** Description - String - version of the imported add-in.
//          ** AdditionalInformation - Map of KeyAndValue - additional information on an add-in;
//                     if not requested – blank map:
//               *** Key - See AdditionalInformationSearchParameters.
//               *** Value - See AdditionalInformationSearchParameters.
//      * AdditionalParameters - Structure - a value that was specified on creating the NotifyDescription object.
//  ImportParameters - See ImportParameters.
//
// Example:
//
//  ImportParameters = AddInClient.ImportParameters();
//  ImportParameters.ID = "InputDevice";
//  ImportParameters.Version = "8.1.7.10";
//
//  Notification = New NotifyDescription("LoadAddInFromFileAfterAddInImport", ThisObject);
//
//  AddInClient.ImportAddInFromFile(Notification, ImportParameters);
//
//  &AtClient
//  Procedure LoadAddInFromFileAfterAddInImport(Result, AdditionalParameters) Export
//
//      If Result.Imported Then 
//          ID = Result.ID;
//          Version = Result.Version;
//      EndIf;
//
//  EndProcedure
//
Procedure ImportAddInFromFile(Notification, ImportParameters = Undefined) Export
	
	If ImportParameters = Undefined Then 
		ImportParameters = ImportParameters();
	EndIf;
	
	Context = AddInsInternalClient.ContextForLoadingComponentsFromAFile();
	Context.Notification = Notification;
	Context.Id = ImportParameters.Id;
	Context.Version = ImportParameters.Version;
	Context.AdditionalInformationSearchParameters = ImportParameters.AdditionalInformationSearchParameters;
	
	AddInsInternalClient.ImportAddInFromFile(Context);
	
EndProcedure

#Region ForCallsFromOtherSubsystems

// EquipmentSupport
// 
// Attaches an add-in powered by Native API and COM technology on the client machine.
// Checks whether the add-in can be executed on the current client.
//
// Parameters:
//  Id - String - the add-in identification code.
//  Version        - String - an add-in version.
//  ConnectionParameters - See AddInsClient.ConnectionParameters.
//
//  Returns:  
//  	Structure - Add-in attachment result:
//          * Attached - Boolean - attachment flag.
//          * Attachable_Module - AddInObject - an instance of the add-in;
//                                - FixedMap of KeyAndValue - Add-in object instances stored in
//                                      AttachmentParameters.ObjectsCreationIDs:
//                                    *** Key - String - Add-in ID.
//                                    *** Key - String - Add-in ID.
//          * ErrorDescription - String - brief error message. Empty string on cancel by user.
//
Async Function AttachAddInSSLAsync(Id, Version = Undefined,
	ConnectionParameters = Undefined) Export
	
	If ConnectionParameters = Undefined Then
		ConnectionParameters = ConnectionParameters();
	EndIf;
	
	Context = CommonInternalClient.AddInAttachmentContext();
	FillPropertyValues(Context, ConnectionParameters);
	Context.Id = Id;
	Context.Version = Version;
	
	Return Await AddInsInternalClient.AttachAddInSSLAsync(Context);
	
EndFunction

// Connects an add-in based on Native API and COM technology in an asynchronous mode.
// Checking whether the add-in can be executed on the current user client.
//
// Parameters:
//  Id - String - the add-in identification code.
//  Version - String - an add-in version.
//  InstallationParameters - See InstallationParameters.
//
//  Returns:
//    Structure - Add-in installation result:
//          * IsSet - Boolean - Installation flag.
//          * ErrorDescription - String - brief error message. Empty string on cancel by user.
//
Async Function InstallAddInSSLAsync(Id, Version = Undefined, 
	InstallationParameters = Undefined) Export
	
	If InstallationParameters = Undefined Then
		InstallationParameters = InstallationParameters();
	EndIf;
	
	Context = CommonInternalClient.AddInAttachmentContext();
	Context.Id = Id;
	Context.Version = Version;
	Context.ExplanationText = InstallationParameters.ExplanationText;
	Context.SuggestToImport = InstallationParameters.SuggestToImport;
	Context.SuggestInstall = InstallationParameters.SuggestInstall;
		
	Return Await AddInsInternalClient.InstallAddInSSLAsync(Context);
	
EndFunction

// Attaches the add-in based on COM technology from Windows registry in asynchronous mode.
// (not recommended for backward compatibility with 1C:Enterprise 7.7 add-ins). 
//
// Parameters:
//  Id - String - the add-in identification code.
//  ObjectCreationID - String - object creation ID of object module instance
//          (only for add-ins with object creation ID different from ProgID).
//
//  Returns:
//  	Structure - Add-in attachment result:
//          * Attached - Boolean - attachment flag.
//          * Attachable_Module - AddInObject - an instance of the add-in;
//                                - FixedMap of KeyAndValue - Add-in object instances stored in
//                                      AttachmentParameters.ObjectsCreationIDs:
//                                    *** Value - ??? - Instance of the add-in object.
//                                    *** Value - ??? - Instance of the add-in object.
//          * ErrorDescription - String - brief error message. Empty string on cancel by user.
//
Async Function AttachAddInFromWindowsRegistryAsync(Id,
	ObjectCreationID = Undefined) Export 
	
	Context = AddInsInternalClient.ConnectionContextComponentsFromTheWindowsRegistry();
	Context.Id = Id;
	Context.ObjectCreationID = ObjectCreationID;
	
	Return Await AddInsInternalClient.AttachAddInFromWindowsRegistryAsync(Context);
	
EndFunction

// End EquipmentSupport

#EndRegion

#EndRegion

#Region Internal

Procedure ShowAddIns() Export
	
	OpenForm("Catalog.AddIns.ListForm");
	
EndProcedure

#EndRegion