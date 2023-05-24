///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// SignatureProperties constructor that adds and updates signature data.
// 
// Returns:
//   Structure - 
//     * Signature             - BinaryData - Signing result.
//     * SignatureSetBy - CatalogRef.Users - a user who
//                           signed the infobase object.
//     * Comment         - String - a comment if it was entered upon signing.
//     * SignatureFileName     - String - if a signature is added from a file.
//     * SignatureDate         - Date - a signature date. It makes sense
//                           when the date cannot be extracted from signature data.
//     * SignatureValidationDate - Date - a last signature check date.
//     * SignatureCorrect        - Boolean - Last signature validation result.
//     
//     Intended for updating upgraded signatures:
//     * SignedObject   - DefinedType.SignedObject - Object the signature associated with.
//                             Ignored in methods there this object is a parameter.
//     * SequenceNumber     - Number - Signature ID that used for list sorting.
//                             Empty if the signature is not associated with an object.
//     * IsErrorOccurredDuringAutomaticRenewal - Boolean - Service attribute. Assigned by a scheduled job.
//
//     Derived properties:
//     * Certificate          - ValueStorage - contains an upload of the certificate
//                             that was used for signing (contained in the signature).
//                           - BinaryData
//     * Thumbprint           - String - a certificate thumbprint in the Base64 string format.
//     * CertificateOwner - String - a subject presentation received from the certificate binary data.
//     * SignatureType          - ПеречислениеСсылка.ТипыЭлектроннойПодписи
//     * DateActionLastTimestamp - Date - Validity period of the certificate  that the last timestamp was signed with.
//                                   Empty date if there's no timestamp.
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
	
	Structure.Insert("Certificate");
	Structure.Insert("Thumbprint");
	Structure.Insert("CertificateOwner");
	Structure.Insert("SignatureType");
	Structure.Insert("DateActionLastTimestamp");
	Structure.Insert("DateSignedFromLabels");
	Structure.Insert("UnverifiedSignatureDate");
	
	Structure.Insert("CertificateDetails");
	
	Structure.Insert("IsErrorOccurredDuringAutomaticRenewal", False);
	
	Return Structure;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated.Dated.
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

// Deprecated.Dated.
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

// Deprecated.Dated.
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

// Deprecated.Dated.
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

// Deprecated.Dated.
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

// Deprecated.Dated.
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

// Deprecated.Dated.
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