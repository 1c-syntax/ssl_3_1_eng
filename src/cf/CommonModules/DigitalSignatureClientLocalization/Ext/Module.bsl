///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Technical support line code.
// 
// Parameters:
//  Recipient - String
//
Procedure OnDefineTechnicalSupportRequestRecipient(Recipient) Export
	
	
EndProcedure

// Filter for signature selection.
// 
// Parameters:
//  Filter - String
//
Procedure OnGetFilterForSelectingSignatures(Filter) Export
	
	
EndProcedure

// On getting a choice list with MR LOAs in the form for adding signatures from a file.
// 
// Parameters:
//  Form - See CommonForm.AddDigitalSignatureFromFile
//  CurrentData - FormDataCollectionItem - Signature string in form "Common.AddDigitalSignatureFromFile".
//  ChoiceList - ValueList
//
Procedure OnGetChoiceListWithMRLOAs(Form, CurrentData, ChoiceList) Export
	
	
EndProcedure

// On choosing an MR LOA on the form for exporting signatures from a file.
// 
// Parameters:
//  CompletionHandler - CallbackDescription
//  CurrentData - FormDataCollectionItem - Signature string in form "Common.AddDigitalSignatureFromFile". 
//
Procedure OnSelectMRLOA(CompletionHandler, CurrentData) Export
	
	
EndProcedure

// Adds MR LOA files to the list when saving a signature.
// 
// Parameters:
//  MRLOAFiles - Map
//  SignaturesCollection - FormDataCollection
//
Procedure OnDefineMRLOAFiles(MRLOAFiles,
		SignaturesCollection) Export
		
	
EndProcedure

// On checking for conflicts between cryptographic applications.
// 
// Parameters:
//  Form - ClientApplicationForm
//  CheckResult - Structure
//
Procedure OnCheckCryptoAppsConflict(Form, CheckResult) Export
	
	
EndProcedure

// On checking for installed cryptographic applications.
// 
// Parameters:
//  Form - ClientApplicationForm
//  CheckResult - Structure
//  HasAppsToCheck - Boolean
//
Procedure OnCheckInstalledCryptoApps(Form, CheckResult, HasAppsToCheck) Export
	
	
EndProcedure

// Detects tokens connected to the device.
// 
// Parameters:
//  ComponentObject - Undefined, AddInObject.
//  SuggestInstall - Boolean - Prompt to install the add-in (if not yet installed).
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

// Get the properties of token certificates.
// 
// Parameters:
//  Context - Structure:
//    * CertificatesArray - Array
//  SuggestInstall - Boolean - Prompt to install the add-in (if not yet installed).
// 
// Returns:
//    Promise - Context
//
Async Function GetCertificatesPropertiesOnTokens(Context, SuggestInstall) Export
	
	
	Return Context;
	
EndFunction

// Returns the thumbprints of token certificates.
// 
// Parameters:
//  SuggestInstall - Boolean - Prompt to install the add-in (if not yet installed).
//  IncludingOverduePayments - Boolean - If "False", return the thumbprints only for valid certificates.
// 
// Returns:
//    Promise - Array
//
Async Function GetCertificatesThumbprintsOnTokens(SuggestInstall, IncludingOverduePayments = False) Export
	
	ThumbprintsArray = New Array;
	
	
	Return ThumbprintsArray;
	
EndFunction

// Token certificates.
// 
// Parameters:
//  SuggestInstall - Boolean - Prompt to install.
//  Refresh - Boolean - Update the list of token certificates in the cache.
// 
// Returns:
//  Promise - Array of Structure - Tokens.
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

// Token certificates.
// 
// Parameters:
//  Token - Structure
//  ComponentObject - Undefined, AddInObject
//  SuggestInstall - Boolean - Prompt to install.
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

// Encryption-only token.
// 
// Parameters:
//  Certificate - CryptoCertificate
//  EncryptAlgorithm - String - OID or 
//  CertificateProperties - Structure
//  	* AlgorithmOfPublicKey - String - OID
// 
// Returns:
//  Promise - Structure
//
Async Function TokenForEncryption(Certificate, EncryptAlgorithm = Undefined, CertificateProperties = Undefined) Export
	Result = Undefined;
	
	Return Result;
EndFunction

// The error message indicates that an incorrect token PIN was entered.
// 
// Parameters:
//  ErrorText - String - Error text.
// 
// Returns:
//  Boolean
//
Function IsIncorrectPinCodeError(ErrorText) Export
	Return False;
EndFunction

// Token signature.
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
//  Promise - BinaryData, String
//
Async Function SignatureOnToken(SignatureParameters, Data) Export
	
	CannotCreateSignatureText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot create %1 signatures on the token.'"), SignatureParameters.SignatureType);
	
	
	Return CannotCreateSignatureText;

EndFunction

// Verifies a signature using a token.
// 
// Parameters:
//  Data - BinaryData, Undefined - If "Undefined", the signature is checked as an attachment.
//  Signature - BinaryData
//  CheckParameters - Structure:
//   * SignAlgorithm - String
//   * ComponentObject - AddInObject
//   * ShouldReturnCertificatesForVerification - Boolean
// 
// Returns:
//  Promise - Verify signature
//
Async Function VerifySignature(Data, Signature, CheckParameters) Export
	
	Result = Undefined;
	
	
	Return Result;

EndFunction

// Encryption on the token.
// 
// Parameters:
//  EncryptionParameters - Structure
//  Data - BinaryData
// 
// Returns:
//  Promise - BinaryData, String
//
Async Function EncryptionOnToken(EncryptionParameters, Data) Export
	
	Result = NStr("en = 'Encryption on the token is unavailable.'");
	
	
	Return Result;
EndFunction

// Encryption on the token.
// 
// Parameters:
//  DetailsParameters - Structure
//  Data - BinaryData
// 
// Returns:
//  Promise - BinaryData, String
//
Async Function DecryptionOnToken(DetailsParameters, Data) Export
	
	Result = NStr("en = 'Decryption on the token is unavailable.'");
	
	
	Return Result;
EndFunction

// Opens the form for installing cryptographic tools.
// 
// Parameters:
//  Parameters - Structure
//  Owner - ClientApplicationForm
//  Notification - CallbackDescription
//  StandardProcessing - Boolean
//
Procedure OnOpenCryptoProviderAppsInstallationForm(Parameters, Owner, Notification, StandardProcessing) Export
	
	
EndProcedure

// On filling the result of checking a CA.
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

// For internal use only.
// Verifies the installation of cryptographic tools as part of the add-in installation check for managing digital signatures.
//
// Parameters:
//  Result	 - Boolean - If "True", some add-ins should be installed.
//  Components	 - See DigitalSignatureInternalClient.NewCryptoManagementAddIns.
//
Procedure OnCheckCryptoAppsInstallation(Result, Components) Export
	
	
EndProcedure

// On continuing the verification of installed cryptographic tools.
// 
// Parameters:
//  Context - Structure - 
//  CheckResult - Structure - 
//  HasAppsToCheck - Boolean - 
// 
// Returns:
//  Promise - Boolean
//
Async Function OnContinueCheckInstalledCryptoApps(
		Context, CheckResult, HasAppsToCheck) Export
	
	
	Return True;
	
EndFunction

// On handling a classifier URL.
// 
// Parameters:
//  Item - FormDecoration
//  FormattedStringURL - String
//  Parameters - Structure
// 
// Returns:
//  Promise - Boolean
//
Async Function OnHandleClassifierURL(Item, FormattedStringURL, Parameters) Export
	
	Return True;
	
EndFunction


#EndRegion

