///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// Called during the internet connectivity check. A custom connectivity check URL can be specified.
//
// Parameters:
//  ServerAddresses - String - Set the server address for connection testing. 
//                           By default, "google.com".
//
Procedure OnGetChecksumServerAddress(ServerAddresses) Export
	
	
EndProcedure

// 
//
// Parameters:
//  LongDesc - Array of String - 
//  ErrorText - See GetFilesFromInternet.ConnectionDiagnostics
//
Procedure WhenGeneratingMessageAboutKnownProblem(LongDesc, ErrorText) Export
	
	If StrFind(Upper(ErrorText), Upper("Deleted node not passed checking")) > 0 Then // ACC:1297 Нелокализуемый фрагмент информации об ошибке в исключении.
	EndIf;
	
EndProcedure


#EndRegion
