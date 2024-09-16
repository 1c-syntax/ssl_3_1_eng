///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Applies requests to use external resources that were previously saved in the information database.
//
// Parameters:
//  IDs - Array -  the IDs of the queries that you want to apply,
//  OwnerForm - ClientApplicationForm -  a form that should be blocked until permissions are applied,
//  ClosingNotification1 - NotifyDescription -  which will be called when permissions are granted successfully.
//
Procedure ApplyExternalResourceRequests(Val IDs, OwnerForm, ClosingNotification1) Export
	
	StandardProcessing = True;
	SSLSubsystemsIntegrationClient.OnConfirmRequestsToUseExternalResources(IDs, OwnerForm, ClosingNotification1, StandardProcessing);
	If Not StandardProcessing Then
		Return;
	EndIf;
		
	SafeModeManagerClientOverridable.OnConfirmRequestsToUseExternalResources(
		IDs, OwnerForm, ClosingNotification1, StandardProcessing);
	ExternalResourcesPermissionsSetupClient.StartInitializingRequestForPermissionsToUseExternalResources(
		IDs, OwnerForm, ClosingNotification1);
	
EndProcedure

// Opens the dialog for configuring the mode of using security profiles for
// the current database.
//
Procedure OpenSecurityProfileSetupDialog() Export
	
	OpenForm(
		"DataProcessor.ExternalResourcesPermissionsSetup.Form.SecurityProfileSetup",
		,
		,
		"DataProcessor.ExternalResourcesPermissionsSetup.Form.SecurityProfileSetup",
		,
		,
		,
		FormWindowOpeningMode.Independent);
	
EndProcedure

// Allows the administrator to open an external processing or report with a safe mode selection.
//
// Parameters:
//   Owner - ClientApplicationForm -  form-owner of the external processing form or report. 
//
Procedure OpenExternalDataProcessorOrReport(Owner) Export
	
	OpenForm("DataProcessor.ExternalResourcesPermissionsSetup.Form.OpenExternalDataProcessorOrReportWithSafeModeSelection",,
		Owner);
	
EndProcedure

#EndRegion

#Region Private

// Checks whether you need to display the assistant for configuring permissions to use
// external (relative to the 1C server cluster:Enterprises) resources.
//
// Returns:
//   Boolean
//
Function DisplayPermissionSetupAssistant() Export
	
	Return StandardSubsystemsClient.ClientParameter("DisplayPermissionSetupAssistant");
	
EndFunction

#EndRegion
