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

// Applies requests to use external resources saved to the infobase.
//
// Parameters:
//  IDs - Array - Request IDs.
//  OwnerForm - ClientApplicationForm - Form that must be locked before permissions are applied.
//  ClosingNotification1 - NotifyDescription - Notification triggered when permissions are granted.
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

// Opens the security profile setup dialog for
// the current infobase.
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

// Allows the administrator to open an external data processor or report in safe mode.
//
// Parameters:
//   Owner - ClientApplicationForm - a form that owns the external report or data processor form. 
//
Procedure OpenExternalDataProcessorOrReport(Owner) Export
	
	OpenForm("DataProcessor.ExternalResourcesPermissionsSetup.Form.OpenExternalDataProcessorOrReportWithSafeModeSelection",,
		Owner);
	
EndProcedure

#EndRegion

#Region Private

// Checks whether
// external (relative to 1C:Enterprise server cluster) resource permissions setup wizard must be shown.
//
// Returns:
//   Boolean
//
Function DisplayPermissionSetupAssistant() Export
	
	Return StandardSubsystemsClient.ClientParameter("DisplayPermissionSetupAssistant");
	
EndFunction

#EndRegion
