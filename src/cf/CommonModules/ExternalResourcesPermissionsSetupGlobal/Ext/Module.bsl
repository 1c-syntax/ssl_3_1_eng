///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Performs asynchronous processing of notifications about closing forms of the wizard for configuring permissions to
// use external resources when called through the connection of the wait handler.
// As a result, the value of the directory return Code is passed to the handler.OK.
//
// The procedure is not intended to be called directly.
//
Procedure FinishExternalResourcePermissionSetup() Export
	
	ExternalResourcesPermissionsSetupClient.CompleteSetUpPermissionsToUseExternalResourcesSynchronously(DialogReturnCode.OK);
	
EndProcedure

// Performs asynchronous processing of notifications about closing forms of the wizard for configuring permissions to
// use external resources when called through the connection of the wait handler.
// As a result, the value of the directory return Code is passed to the handler.Cancel.
//
// The procedure is not intended to be called directly.
//
Procedure CancelExternalResourcePermissionSetup() Export
	
	ExternalResourcesPermissionsSetupClient.CompleteSetUpPermissionsToUseExternalResourcesSynchronously(DialogReturnCode.Cancel);
	
EndProcedure

#EndRegion