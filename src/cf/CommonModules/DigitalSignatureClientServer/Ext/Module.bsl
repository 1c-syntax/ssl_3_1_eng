///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
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
//     * SignatureDate         - Date - a signature date. It makes sense
//                           when the date cannot be extracted from signature data.
//     * SignatureValidationDate - Date - Date when the signature was last verified.
//     * SignatureCorrect        - Boolean - Last signature check result.
//     * IsVerificationRequired   - Boolean - Verification failure flag.
//
//     Intended for updating enhanced signatures.:
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
//     * DateActionLastTimestamp - Date - атValidity period of the certificate that the last timestamp was signed with.
//                                           Empty date if there's no timestamp.
//                                           Applicable if the period was determined using CryptoManager.
//     * Certificate          - ValueStorage - contains export of the certificate
//                             that was used for signing (it is in the signature).
//                           - BinaryData
//     * Thumbprint           - String - a certificate thumbprint in the Base64 string format.
//     * CertificateOwner - String - a subject presentation received from the certificate binary data.
//     * CertificateDetails - Structure - Property required for certificates that cannot be passed to the CryptoCertificate's method.
//                             Has the following properties:
//        ** SerialNumber - String - a certificate serial number as in the CryptoCertificate platform object.
//        ** IssuedBy      - String - as the IssuerPresentation function returns.
//        ** IssuedTo     - String - as the SubjectPresentation function returns.
//        ** StartDate    - String - a certificate date as in the CryptoCertificate platform object in the DLF=D format.
//        ** EndDate - String - a certificate date as in the CryptoCertificate platform object in the DLF=D format.
//
Function NewSignatureProperties() Export
	
	Structure = New Structure;
	Structure.Insert("Signature");
	Structure.Insert("SignatureSetBy");
	Structure.Insert("Comment");
	Structure.Insert("SignatureFileName");
	Structure.Insert("SignatureDate");
	Structure.Insert("SignatureValidationDate");
	Structure.Insert("SignatureCorrect");
	Structure.Insert("SignedObject");
	Structure.Insert("SequenceNumber");
	Structure.Insert("IsVerificationRequired", False);
	
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
//   * SignatureType          - EnumRef.CryptographySignatureTypes - Not filled when checking XML envelope signatures.
//   * DateActionLastTimestamp - Date - Validity period of the certificate that the last timestamp was signed with.
//    Empty date if there's no timestamp. Applicable if the period was determined using CryptoManager.
//   * UnverifiedSignatureDate - Date - Unconfirmed signature data.
//                               - Undefined - Unconfirmed signature data is missing from the signature data
//                                                and for the XML envelope.
//   * DateSignedFromLabels  - Date - Date of the earliest timestamp.
//                       - Undefined - Timestamp is missing from the signature data during the XML envelope check.
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
	
	CommonClientServer.SupplementStructure(
		Structure, DigitalSignatureInternalClientServer.SignaturePropertiesUponReadAndVerify());
		
	Return Structure;
	
EndFunction

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