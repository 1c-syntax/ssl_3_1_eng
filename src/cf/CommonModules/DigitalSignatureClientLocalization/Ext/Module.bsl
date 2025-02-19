///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// 
// 
// Parameters:
//  Recipient - String
//
Procedure OnDefineTechnicalSupportRequestRecipient(Recipient) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  Filter - String
//
Procedure OnGetFilterForSelectingSignatures(Filter) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  Form - See CommonForm.AddDigitalSignatureFromFile
//  CurrentData - See CommonForm.AddDigitalSignatureFromFile.Signatures
//  ChoiceList - ValueList
//
Procedure OnGetChoiceListWithMRLOAs(Form, CurrentData, ChoiceList) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  CompletionHandler - CallbackDescription
//  CurrentData - See CommonForm.AddDigitalSignatureFromFile.Signatures 
//
Procedure OnSelectMRLOA(CompletionHandler, CurrentData) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  MRLOAFiles - Map
//  SignaturesCollection - FormDataCollection
//
Procedure OnDefineMRLOAFiles(MRLOAFiles,
		SignaturesCollection) Export
		
	
EndProcedure

// 
// 
// Parameters:
//  ComponentObject - 
//  SuggestInstall - Boolean - 
// 
// Returns:
//  Promise - Structure
//
Async Function InstalledTokens(ComponentObject = Undefined, SuggestInstall = False) Export

	Result = New Structure;
	Result.Insert("CheckCompleted", False);
	Result.Insert("Tokens", New Array);
	Result.Insert("Error", "");
	
	
	Return Result;
	
EndFunction

// 
// 
// Parameters:
//  Context - Structure:
//    * CertificatesArray - Array
//  SuggestInstall - Boolean - 
// 
// Returns:
//    Promise - Context
//
Async Function GetCertificatesPropertiesOnTokens(Context, SuggestInstall) Export
	
	
	Return Context;
	
EndFunction

// 
// 
// Parameters:
//  SuggestInstall - Boolean - 
//  IncludingOverduePayments - Boolean - 
// 
// Returns:
//    Promise - Array
//
Async Function GetCertificatesThumbprintsOnTokens(SuggestInstall, IncludingOverduePayments = False) Export
	
	ThumbprintsArray = New Array;
	
	
	Return ThumbprintsArray;
	
EndFunction

// 
// 
// Parameters:
//  SuggestInstall - Boolean - 
//  Refresh - Boolean - 
// 
// Returns:
//  Promise - 
//  
Async Function CertificatesOnTokens(SuggestInstall, Refresh = False) Export
	
	InstalledCryptoProviders = Await DigitalSignatureInternalClient.InstalledCryptoProvidersFromCache(SuggestInstall);
	Tokens = InstalledCryptoProviders.Tokens;
	WriteTokensToCache = False;
	
	
	If WriteTokensToCache Then
		InstalledCryptoProviders.Tokens = Tokens;
		DigitalSignatureInternalClient.WriteInstalledCryptoProvidersToCache(InstalledCryptoProviders)
	EndIf;
	
	Return Tokens;
	
EndFunction

// 
// 
// Parameters:
//  Token - Structure
//  ComponentObject - 
//  SuggestInstall - Boolean - 
// 
// Returns:
//  Promise - Structure
//
Async Function TokenCertificates(Token, ComponentObject = Undefined, SuggestInstall = False) Export
	
	Result = New Structure;
	Result.Insert("CheckCompleted", False);
	Result.Insert("Certificates", New Array);
	Result.Insert("Error", "");
	
	
	Return Result;
	
EndFunction

// 
// 
// Parameters:
//  ErrorText - String - 
// 
// Returns:
//  Boolean
//
Function IsIncorrectPinCodeError(ErrorText) Export
	Return False;
EndFunction

// 
// 
// Parameters:
//  SignatureParameters - Structure:
//    * Token - Structure
//    * Certificate - CryptoCertificate
//    * Password - String
//    * SignatureType - EnumRef.CryptographySignatureTypes
//    * DetachedAddIn - Boolean
//    * SignatureType - EnumRef.CryptographySignatureTypes
//    * ComponentObject - AddInObject
//    * ShouldIncludeCertificateInSignature - Boolean
//  Data - BinaryData
// 
// Returns:
//  Promise - 
//
Async Function SignatureOnToken(SignatureParameters, Data) Export
	
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Cannot create signatures with %1 tokens.';"), SignatureParameters.SignatureType);

EndFunction

// 
// 
// Parameters:
//  Data - BinaryData, Undefined - 
//  Signature - BinaryData
//  SignAlgorithm - String - 
//  ComponentObject - AddInObject - 
// 
// Returns:
//  Promise - 
//
Async Function VerifySignature(Data, Signature, SignAlgorithm = Undefined, ComponentObject = Undefined) Export
	
	Result = Undefined;
	
	
	Return Result;

EndFunction

// 
// 
// Parameters:
//  EncryptionParameters - Structure
//  Data - BinaryData
// 
// Returns:
//  Promise - 
//
Async Function TokenBasedEncryption(EncryptionParameters, Data) Export
	
	Result = NStr("en = 'Недоступно шифрование на токене.';");
	
	
	Return Result;
EndFunction

// 
// 
// Parameters:
//  Parameters - Structure
//  Owner - ClientApplicationForm
//  Notification - CallbackDescription
//  StandardProcessing - Boolean
//
Procedure ПриОткрытииФормыУстановкиПрограммКриптопровайдеров(Parameters, Owner, Notification, StandardProcessing) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  Result - See DigitalSignatureInternalClientServer.DefaultCAVerificationResult
//  CryptoCertificate - CryptoCertificate
//  OnDate - Date
//  CheckParameters - Structure
//  CertificateProperties - See DigitalSignature.CertificateProperties
// 
// Returns:
//  Promise - See DigitalSignatureInternalClientServer.DefaultCAVerificationResult
//
Async Function OnFillCertificationAuthorityAuditResult(
	Result, CryptoCertificate, OnDate, CheckParameters, CertificateProperties) Export
	
	
	Return Result;
	
EndFunction

// 
// 
//
// Parameters:
//  Result	 - Boolean - 
//  Components	 - See DigitalSignatureInternalClient.NewComponentsOfWorkingWithCryptography.
//
Procedure WhenCheckingInstallationOfCryptographyPrograms(Result, Components) Export
	
	
EndProcedure

#EndRegion

