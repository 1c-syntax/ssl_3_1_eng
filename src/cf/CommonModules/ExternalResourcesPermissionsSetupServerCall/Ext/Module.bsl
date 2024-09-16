///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Checks the completion of the operation of applying permissions to use external resources.
// It is used to diagnose situations in which changes were made to the security profile settings
// in the server cluster, but the operation was not completed, in which it was necessary
// to change the settings for permissions to use external resources.
//
// Returns:
//   Structure:
//  The result of the check is Boolean - if False, the operation was not completed and you need to prompt
//                      the user to undo changes in
//                      the security profile settings in the server cluster,
//  Request identifiers-Array(Unique identifier) - an array of identifiers of requests
//                           for the use of external resources that must be applied to
//                           undo changes in the security profile settings in the server cluster,
//  Address of the temporary storage-A string - the address in the temporary storage at which
//                             the status of applying permission requests was placed, which should be applied
//                             to cancel changes in the security profile settings in
//                             the server cluster,
//  Address of the temporary storage of the state-A string - the address in the temporary storage at which
//                                      the internal processing state was placed.
//                                      Setting up permission to use external resources.
//
Function CheckApplyPermissionsToUseExternalResources() Export
	
	Return DataProcessors.ExternalResourcesPermissionsSetup.ExecuteApplicabilityCheckRequestsProcessing();
	
EndFunction

// Deletes requests to use external resources if the user refused to use them.
//
// Parameters:
//  RequestsIDs - Array of UUID -  array of IDs for requests to
//                           use external resources.
//
Procedure CancelApplyRequestsToUseExternalResources(Val RequestsIDs) Export
	
	InformationRegisters.RequestsForPermissionsToUseExternalResources.DeleteRequests(RequestsIDs);
	
EndProcedure

#EndRegion
