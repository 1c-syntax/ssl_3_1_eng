///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called when confirming requests to use external resources.
// 
// Parameters:
//  RequestsIDs - Array -  the IDs of the queries that you want to apply,
//  OwnerForm - ClientApplicationForm -  a form that should be blocked until permissions are applied,
//  ClosingNotification1 - NotifyDescription -  which will be called when permissions are granted successfully.
//  StandardProcessing - Boolean -  flag for performing standard processing for applying permissions to use
//    external resources (connecting to the server agent via a COM connection or the administration server
//    requesting cluster connection parameters from the current user). Can be set to False
//    inside the event handler, in this case, standard treatment is complete, the session will not be executed.
//
Procedure OnConfirmRequestsToUseExternalResources(Val RequestsIDs, OwnerForm, ClosingNotification1, StandardProcessing) Export
	
	
	
EndProcedure

#EndRegion