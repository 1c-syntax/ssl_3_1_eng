///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	UseEDIToStoreObjectFiles =
		FilesOperationsInternalClient.Is1CDocumentManagementUsedForFileStorage(
			CommandParameter,
			CommandExecuteParameters.Source,
			ThisObject);
	
	If UseEDIToStoreObjectFiles Then
		
		// IntegrationWith1CDocumentManagementSubsystem
		FilesOperationsInternalClient.OpenFormAttachedFiles1CDocumentManagement(
			CommandParameter,
			CommandExecuteParameters.Source,
			CommandExecuteParameters);
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
