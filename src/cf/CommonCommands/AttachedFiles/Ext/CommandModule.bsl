///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient = Undefined;
	UseEDIToStoreObjectFiles =
		FilesOperationsInternalClient._1CDocumentManagementIsUsedToStoreObjectFiles(
			CommandParameter,
			ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient,
			CommandExecuteParameters.Source,
			ThisObject);
	
	If UseEDIToStoreObjectFiles Then
		
		// IntegrationWith1CDocumentManagementSubsystem
		ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient.OpenAttachedFiles(
			CommandParameter,,
			CommandExecuteParameters.Source.ReadOnly,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window);
		// End IntegrationWith1CDocumentManagementSubsystem
		
	Else
		FormParameters = New Structure;
		FormParameters.Insert("FileOwner",  CommandParameter);
		FormParameters.Insert("ReadOnly", CommandExecuteParameters.Source.ReadOnly);
		
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles",
			FormParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window);
	EndIf;
	
EndProcedure

#EndRegion
