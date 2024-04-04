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

// Constructor of the SignatureProperties parameter. Intended for adding and updating signature data.
// Contains the signature's extended details.
// 
// Returns:
//   Structure:
//     * Signature             - BinaryData - Signing result.
//                           - String - Signed XMLEnvelope (if it was passed in the data).
//     * SignatureSetBy - CatalogRef.Users - a user who
//                           signed the infobase object.
//     * Comment         - String - a comment if it was entered upon signing.
//     * SignatureFileName     - String - if a signature is added from a file.
//     * SignatureDate         - Date - 
//                           
//
//     :
//     * SignatureValidationDate - Date - Date when the signature was last verified.
//     * SignatureCorrect        - Boolean - Last signature check result.
//     * IsVerificationRequired   - Boolean - 
//     * IsSignatureMathematicallyValid - Boolean - 
//     * SignatureMathValidationError - String - 
//                                                      
//     * AdditionalAttributesCheckError - String - 
//                                                        
//     * IsAdditionalAttributesCheckedManually - Boolean - 
//         
//     * AdditionalAttributesManualCheckAuthor - CatalogRef.Users
//     * AdditionalAttributesManualCheckJustification - String - 
//                                                                   
//
//     :
//     * SignedObject   - DefinedType.SignedObject - Object the signature associated with.
//                             Ignored in methods there this object is a parameter.
//     * SequenceNumber     - Number - Signature ID that used for list sorting.
//                             Empty if the signature is not associated with an object.
//     * IsErrorOccurredDuringAutomaticRenewal - Boolean - Do no use. This is an internal parameter, which is filled by the scheduled job.
//     Intended for linking with the machine-readable letter of authority.:
//     * SignatureID - UUID
//     * ResultOfSignatureVerificationByMRLOA - Array of Structure, Structure - MachineReadableLettersOfAuthorityFTS.ResultOfSignatureVerificationByMRLOA
//
//     Derived signature properties:
//     * SignatureType          - EnumRef.CryptographySignatureTypes
//     * DateActionLastTimestamp - Date - 
//                                           
//                                           
//     * Certificate          - ValueStorage - contains export of the certificate
//                             that was used for signing (it is in the signature).
//                           - BinaryData
//     * Thumbprint           - String - a certificate thumbprint in the Base64 string format.
//     * CertificateOwner - String - a subject presentation received from the certificate binary data.
//     * CertificateDetails - Structure - Property required for certificates that cannot be passed to the CryptoCertificate's method.
//                             Has the following properties:
//        ** SerialNumber  - String - a certificate serial number as in the CryptoCertificate platform object.
//        ** IssuedBy       - String - as the IssuerPresentation function returns.
//        ** IssuedTo      - String - as the SubjectPresentation function returns.
//        ** StartDate     - String - a certificate date as in the CryptoCertificate platform object in the DLF=D format.
//        ** EndDate  - String - a certificate date as in the CryptoCertificate platform object in the DLF=D format.
//        ** ValidBefore - String - 
//                                     
//
Function NewSignatureProperties() Export
	
	Structure = New Structure;
	Structure.Insert("Signature");
	Structure.Insert("SignatureSetBy");
	Structure.Insert("Comment");
	Structure.Insert("SignatureFileName");
	Structure.Insert("SignatureDate");
	
	Structure.Insert("SignedObject");
	Structure.Insert("SequenceNumber");
	
	Structure.Insert("SignatureValidationDate");
	Structure.Insert("SignatureCorrect");
	Structure.Insert("IsVerificationRequired", False);
	
	Structure.Insert("IsSignatureMathematicallyValid");
	Structure.Insert("SignatureMathValidationError");
	Structure.Insert("AdditionalAttributesCheckError");
	Structure.Insert("IsAdditionalAttributesCheckedManually");
	Structure.Insert("AdditionalAttributesManualCheckAuthor");
	Structure.Insert("AdditionalAttributesManualCheckJustification");
	
	Structure.Insert("Certificate");
	Structure.Insert("Thumbprint");
	Structure.Insert("CertificateOwner");
	Structure.Insert("SignatureType");
	Structure.Insert("DateActionLastTimestamp");
	
	Structure.Insert("CertificateDetails");
	
	Structure.Insert("IsErrorOccurredDuringAutomaticRenewal", False);
	Structure.Insert("SignatureID");
	Structure.Insert("ResultOfSignatureVerificationByMRLOA");
	
	Return Structure;
	
EndFunction

// Signature verification result.
// 
// Returns:
//  Structure:
//   * Result - Boolean     - True if the check is passed.
//             - String       - Check error details.
//             - Undefined - Failed to get the cryptographic manager (when it is not specified).
//   * SignatureCorrect        - Boolean, Undefined - Last signature check result.
//   * CertificateRevoked   - Boolean - Flag indicating whether the error occurred because the certificate was revoked.
//   * IsVerificationRequired   - Boolean - Signature verification failure flag.
//   * IsSignatureMathematicallyValid - Boolean -  
//                                           
//   * SignatureMathValidationError - String - 
//                                                    
//   * AdditionalAttributesCheckError - String - 
//                                                      
//
//   * SignatureType          - EnumRef.CryptographySignatureTypes - Not filled when checking XML envelope signatures.
//   * DateActionLastTimestamp - Date - 
//    
//   * UnverifiedSignatureDate - Date - Unconfirmed signature data.
//                                 - Undefined - Unconfirmed signature data is missing from the signature data
//                                                and for the XML envelope.
//   * DateSignedFromLabels  - Date - Date of the earliest timestamp.
//                         - Undefined - Timestamp is missing from the signature data during the XML envelope check.
//   * Certificate          - BinaryData - Signatory's certificate
//   * Thumbprint           - String - a certificate thumbprint in the Base64 string format.
//   * CertificateOwner - String - a subject presentation received from the certificate binary data.
//
Function SignatureVerificationResult() Export
	
	Structure = New Structure;
	Structure.Insert("Result");
	Structure.Insert("SignatureCorrect");
	Structure.Insert("CertificateRevoked", False);
	Structure.Insert("IsVerificationRequired");
	
	Structure.Insert("IsSignatureMathematicallyValid");
	Structure.Insert("SignatureMathValidationError");
	Structure.Insert("AdditionalAttributesCheckError");
	
	CommonClientServer.SupplementStructure(
		Structure, DigitalSignatureInternalClientServer.SignaturePropertiesUponReadAndVerify());
		
	Return Structure;
	
EndFunction

// 
// 
// Returns:
//  Structure - :
//   * SignatureAddress - String - Signature address in temporary storage.
//   * CertificateAddress - String - Certificate address in a temporary storage.
//   * MachineReadableLOAValid - Boolean
//   * CheckResult - Structure - :
//     ** IsSignatureMathematicallyValid - Boolean
//     ** SignatureMathValidationError - String -  error text.
//     ** AdditionalAttributesCheckError - String -  error text.
//     ** IsAdditionalAttributesCheckedManually - Boolean - 
//     ** AdditionalAttributesManualCheckAuthor - CatalogRef.Users
//     ** AdditionalAttributesManualCheckJustification - String
//   * BriefCheckResult - String - 
//
Function ResultOfSignatureValidationOnForm() Export
	
	SignatureProperties = New Structure;
	
	SignatureProperties.Insert("SequenceNumber");
	SignatureProperties.Insert("Object");
	SignatureProperties.Insert("SignatureDate");
	SignatureProperties.Insert("Comment");
	SignatureProperties.Insert("SignatureAddress");
	SignatureProperties.Insert("Thumbprint");
	SignatureProperties.Insert("CertificateAddress");
	SignatureProperties.Insert("SignatureCorrect");
	SignatureProperties.Insert("SignatureValidationDate");
	SignatureProperties.Insert("CertificateOwner");
	SignatureProperties.Insert("IsVerificationRequired");
	SignatureProperties.Insert("SignatureSetBy");
	SignatureProperties.Insert("SignatureType");
	SignatureProperties.Insert("DateActionLastTimestamp");
	
	// 
	SignatureProperties.Insert("ErrorDescription"); 
	SignatureProperties.Insert("Status");
	// 
	
	SignatureProperties.Insert("MachineReadableLetterOfAuthority");
	SignatureProperties.Insert("MachineReadableLOAValid");
	SignatureProperties.Insert("ResultOfSignatureVerificationByMRLOA");

	CheckResult = New Structure;
	CheckResult.Insert("IsSignatureMathematicallyValid");
	CheckResult.Insert("SignatureMathValidationError");
	CheckResult.Insert("AdditionalAttributesCheckError");
	CheckResult.Insert("IsAdditionalAttributesCheckedManually");
	CheckResult.Insert("AdditionalAttributesManualCheckAuthor");
	CheckResult.Insert("AdditionalAttributesManualCheckJustification");
	
	SignatureProperties.Insert("CheckResult", CheckResult);
	SignatureProperties.Insert("BriefCheckResult");
	
	Return SignatureProperties;
	
EndFunction

//  
//
// Parameters:
//  SignatureProperties - See ResultOfSignatureValidationOnForm
//  SessionDate - Date
//
Procedure FillSignatureStatus(SignatureProperties, SessionDate) Export
	
	If Not ValueIsFilled(SignatureProperties.SignatureValidationDate) Then
		Status = "";
		SignatureProperties.BriefCheckResult = NStr("en = 'Not verified';");
		Return;
	EndIf;
		
	CheckResult = SignatureProperties.CheckResult;
	
	If ValueIsFilled(CheckResult) And CheckResult.IsAdditionalAttributesCheckedManually Then
		Status = NStr("en = 'Verified manually';");
	ElsIf SignatureProperties.SignatureCorrect
		And ValueIsFilled(SignatureProperties.DateActionLastTimestamp)
		And SignatureProperties.DateActionLastTimestamp < SessionDate Then
		Status = NStr("en = 'Was valid as of signing date';");
	ElsIf SignatureProperties.SignatureCorrect Then
		Status = NStr("en = 'Valid';");
	ElsIf SignatureProperties.IsVerificationRequired Then
		Status = NStr("en = 'Verification required';");
	Else
		Status = NStr("en = 'Invalid';");
	EndIf;
	
	If Not ValueIsFilled(CheckResult) Then
		SignatureProperties.BriefCheckResult = Status;
		Return;
	EndIf;

	If SignatureProperties.SignatureCorrect Then
		If ValueIsFilled(CheckResult.AdditionalAttributesManualCheckJustification) Then
			
			If StrLen(CheckResult.AdditionalAttributesManualCheckJustification) > 100 Then
				AdditionalAttributesManualCheckJustification =
					Left(CheckResult.AdditionalAttributesManualCheckJustification, 100) + "...";
			Else
				AdditionalAttributesManualCheckJustification = CheckResult.AdditionalAttributesManualCheckJustification;
			EndIf;
			
			SignatureProperties.BriefCheckResult = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = '%1. %2 (%3)';"), Status,
				AdditionalAttributesManualCheckJustification, CheckResult.AdditionalAttributesManualCheckAuthor);
		Else
			
			If SignatureProperties.SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES")
				Or SignatureProperties.SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.NormalCMS")
				Or Not ValueIsFilled(SignatureProperties.SignatureType) Then
					
				If ValueIsFilled(SignatureProperties.DateActionLastTimestamp)
					And SignatureProperties.DateActionLastTimestamp < SessionDate Then
					SignatureProperties.BriefCheckResult = 
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("en = '%1. The document wasn''t modified, and the certificate was valid at the signing date.';"), Status);
				Else
					SignatureProperties.BriefCheckResult =  
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("en = '%1. The document wasn''t modified, and the certificate was valid at the verification date.';"), Status);
				EndIf;
			Else
				SignatureProperties.BriefCheckResult = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = '%1. The document wasn''t modified, and the certificate was valid at the timestamp date.';"), Status);
			EndIf;
			
		EndIf;
		Return;
	EndIf;

	If ValueIsFilled(CheckResult.SignatureMathValidationError) And ValueIsFilled(
		CheckResult.AdditionalAttributesCheckError) Then

		SignatureProperties.BriefCheckResult =  StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1. The document was modified, and the certificate validation failed. %2 %3';"), Status,
			CheckResult.SignatureMathValidationError, CheckResult.AdditionalAttributesCheckError);
	ElsIf ValueIsFilled(CheckResult.SignatureMathValidationError) Then

		SignatureProperties.BriefCheckResult =  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = '%1. The document was modified. %2';"), Status, CheckResult.SignatureMathValidationError);
	Else
			
		If SignatureProperties.SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.NormalCMS")
			Or SignatureProperties.SignatureType = PredefinedValue(
			"Enum.CryptographySignatureTypes.BasicCAdESBES") Then

			SignatureProperties.BriefCheckResult =  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = '%1. The document was not modified, but the certificate validation failed. %2';"), Status, 
				CheckResult.AdditionalAttributesCheckError);
		Else
			SignatureProperties.BriefCheckResult =  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = '%1. The document was not modified, but one of the certificates failed validation. %2';"), Status,
				CheckResult.AdditionalAttributesCheckError);
		EndIf;

	EndIf;
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// See DigitalSignatureClient.CertificatePresentation.
// See DigitalSignature.CertificatePresentation.
//
Function CertificatePresentation(Certificate, MiddleName = False, ValidityPeriod = True) Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	If ValidityPeriod Then
		Return DigitalSignature.CertificatePresentation(Certificate);
	Else	
		Return DigitalSignature.SubjectPresentation(Certificate);
	EndIf;	
#Else
	If ValidityPeriod Then
		Return DigitalSignatureClient.CertificatePresentation(Certificate);
	Else
		Return DigitalSignatureClient.SubjectPresentation(Certificate);
	EndIf;
#EndIf
	
EndFunction

// Deprecated.
// See DigitalSignatureClient.SubjectPresentation.
// See DigitalSignature.SubjectPresentation.
//
Function SubjectPresentation(Certificate, MiddleName = True) Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return DigitalSignature.SubjectPresentation(Certificate);
#Else
	Return DigitalSignatureClient.SubjectPresentation(Certificate);
#EndIf
	
EndFunction

// Deprecated.
// See DigitalSignatureClient.IssuerPresentation.
// See DigitalSignature.IssuerPresentation.
//
Function IssuerPresentation(Certificate) Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return DigitalSignature.IssuerPresentation(Certificate);
#Else
	Return DigitalSignatureClient.IssuerPresentation(Certificate);
#EndIf
	
EndFunction

// Deprecated.
// See DigitalSignatureClient.CertificateProperties.
// See DigitalSignature.CertificateProperties.
//
Function FillCertificateStructure(Certificate) Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return DigitalSignature.CertificateProperties(Certificate);
#Else
	Return DigitalSignatureClient.CertificateProperties(Certificate);
#EndIf
	
EndFunction

// Deprecated.
// See DigitalSignatureClient.CertificateSubjectProperties.
// See DigitalSignature.CertificateSubjectProperties.
//
Function CertificateSubjectProperties(Certificate) Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return DigitalSignature.CertificateSubjectProperties(Certificate);
#Else
	Return DigitalSignatureClient.CertificateSubjectProperties(Certificate);
#EndIf
	
EndFunction

// Deprecated.
// See DigitalSignatureClient.CertificateIssuerProperties.
// See DigitalSignature.CertificateIssuerProperties.
//
Function CertificateIssuerProperties(Certificate) Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return DigitalSignature.CertificateIssuerProperties(Certificate);
#Else
	Return DigitalSignatureClient.CertificateIssuerProperties(Certificate);
#EndIf
	
EndFunction

// Deprecated.
// See DigitalSignatureClient.XMLDSigParameters.
// See DigitalSignature.XMLDSigParameters.
//
Function XMLDSigParameters() Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return DigitalSignature.XMLDSigParameters();
#Else
	Return DigitalSignatureClient.XMLDSigParameters();
#EndIf
	
EndFunction

#EndRegion

#EndRegion