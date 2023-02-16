///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Opens the service user password input form.
//
// Parameters:
//  ContinuationHandler      - NotifyDescription - to be processed after the password is entered.
//  OwnerForm1             - ClientApplicationForm - that requests the password.
//  ServiceUserPassword - String - a current SaaS user password.
//
Procedure RequestPasswordForAuthenticationInService(ContinuationHandler, OwnerForm1, ServiceUserPassword) Export
	
	If ServiceUserPassword = Undefined Then
		OpenForm("CommonForm.AuthenticationInService", , OwnerForm1, , , , ContinuationHandler);
	Else
		ExecuteNotifyProcessing(ContinuationHandler, ServiceUserPassword);
	EndIf;
	
EndProcedure

#EndRegion
