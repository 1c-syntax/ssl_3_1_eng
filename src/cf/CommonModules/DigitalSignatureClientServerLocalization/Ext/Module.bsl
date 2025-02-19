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

Procedure OnGetCertificatePresentation(Val Certificate, Val UTCOffset, Presentation) Export
	
	
EndProcedure

Procedure OnGetSubjectPresentation(Val Certificate, Presentation) Export
	
	
EndProcedure

Procedure OnGetExtendedCertificateSubjectProperties(Val Subject, Properties) Export
	
	
EndProcedure

Procedure OnGetExtendedCertificateIssuerProperties(Val Issuer, Properties) Export
	
	
EndProcedure

Procedure WhenComparingCertificates(PropertiesOfNew, PropertiesOfOld, Result) Export
	
	
EndProcedure

Procedure OnReceivingXMLEnvelope(Parameters, XMLEnvelope) Export
	
	
EndProcedure

Procedure OnGetDefaultEnvelopeVariant(XMLEnvelope) Export

	
EndProcedure

// Address of the revocation list located on a different resource.
// 
// Parameters:
//  CertificateAuthorityName - String - Issuer's name (lower case, Latin letters)
//  CertificateProperties  - BinaryData - Certificate data.
//                       - String - Certificate data address.
//                       - Structure - See DigitalSignatureInternalClientServer.CertificateProperties
//  CARevocationListDirectories - String - The names of the directories used for caching revocation lists on a local resource,
//                        taken from the accredited CA classifier settings, match the certificate issuer names.
// 
// Returns:
//  Structure:
//   * InternalAddress - String - ID for searching within the infobase
//   * ExternalAddress - String - Resource address (for downloading)
//
Function RevocationListInternalAddress(CertificateAuthorityName, CertificateProperties, CARevocationListDirectories) Export
	
	Result = New Structure("ExternalAddress, InternalAddress");
	
	CertificateAuthorityName = StrReplace(CertificateAuthorityName, " ", "_");
	CertificateAuthorityName = TrimAll(StrConcat(StrSplit(CertificateAuthorityName, "!*'();«»:@&=+$,/?%#[]\|<>", True), ""));
	
	CertificateAuthorityName = CommonClientServer.ReplaceProhibitedCharsInFileName(CertificateAuthorityName, "");
	
	If Not ValueIsFilled(CertificateAuthorityName) Then
		Return Result;
	EndIf;
	
	If TypeOf(CertificateProperties) <> Type("Structure") Then
		CertificateProperties = 
			DigitalSignatureInternalClientServer.CertificateAdditionalProperties(CertificateProperties, 0);
	EndIf;
	
	If Not ValueIsFilled(CertificateProperties.CertificateAuthorityKeyID) Then
		Return Result;
	EndIf;
	
	Result.InternalAddress = StrTemplate("%1/%2", CertificateAuthorityName, Lower(CertificateProperties.CertificateAuthorityKeyID));
	
	
	Return Result;
	
EndFunction

Function CARevocationListDirectories(AccreditedCertificationCenters) Export
	
	Return "";
	
EndFunction

// Returns:
//  Undefined, Structure - Certificate authority data:
//   * IsState - Boolean
//   * AllowedUncredited - Boolean
//   * ActionPeriods - Undefined, Array of Structure
//     **DateFrom - Date
//     **DateBy - Date, Undefined
//   * ValidityEndDate - Undefined, Date
//   * UpdateDate  - Undefined, Date
//   * FurtherSettings - Map
//
Function CertificationAuthorityData(SearchValues, AccreditedCertificationCenters) Export
	
	Result = Undefined;
	
	
	Return Result;
	
EndFunction

Procedure OnDefineRefToAppsGuide(Section, URL) Export
	
	
EndProcedure

Procedure OnDefineRefToSearchByErrorsWhenManagingDigitalSignature(URL, SearchString = "") Export
	
	
EndProcedure

// Convert the name of the passed algorithm (depending on the passed presentation).
// 
// Parameters:
//  EncryptAlgorithm  - String
// 
// Returns:
//  String
//
Function ConvertedEncryptAlgorithm(EncryptAlgorithm) Export
	
	Result = "";
	
	
	If IsBlankString(Result) Then
		Result = EncryptAlgorithm;
	EndIf;
	
	Return Result;
	
EndFunction

// Implements alternative cryptography manager parameters.
// For example, in order to comply with the regional aspects of a digital signature and encryption application.
//
// Parameters:
//  ApplicationDetails - See DigitalSignatureInternalCached.ApplicationDetails
//  Manager - CryptoManager
//  EncryptAlgorithm - String
//  Result - Boolean
//
Procedure OnSetCryptoManagerParameters(ApplicationDetails, Manager, EncryptAlgorithm, Result) Export
	
	
EndProcedure

// Adds algorithms required for creating signatures considering regional aspects.
//
// Parameters:
//  Sets	 - Array
//
Procedure OnSetAlgorithmSetsToCreateSignature(Sets) Export
	
	
EndProcedure

// Adds encryption algorithms considering regional aspects.
//
// Parameters:
//  Sets	 - Array
//
Procedure OnSetEncryptAlgorithmsSets(Sets) Export
	
	
EndProcedure

// Adds regional signature algorithms to the list of valid algorithms.
// 
// Returns:
//  Array
//
Function AppsRelevantAlgorithms() Export
	
	Result = New Array;
	
	
	Return Result;
	
EndFunction

Function CertificateCAVerificationContext() Export
	
	Structure = New Structure;
	Structure.Insert("CertificationAuthorityData");
	Structure.Insert("SearchValues");
	Structure.Insert("CertificateAuthorityDescription", "");
	Structure.Insert("UTCOffset");
	Structure.Insert("OnDate");
	Structure.Insert("ThisVerificationSignature", False);
	Structure.Insert("CertificateProperties");
	Structure.Insert("VerifyCertificate", DigitalSignatureInternalClientServer.VerifyQualified());
	
	Return Structure;
	
EndFunction

Function DataForVerificationOfCertificationCenter(Certificate) Export
	
	Result = New Structure("SearchValues, CertificateAuthorityDescription");
	
	CertificateAuthorityProperties = DigitalSignatureInternalClientServer.CertificateIssuerProperties(Certificate);
	
	Result.CertificateAuthorityDescription = CertificateAuthorityProperties.CommonName;
	
	SearchValues = New Array;
	
	If CertificateAuthorityProperties.Property("OGRN") And ValueIsFilled(CertificateAuthorityProperties.OGRN) Then
		SearchValues.Add(CertificateAuthorityProperties.OGRN);
	EndIf;
	
	If ValueIsFilled(CertificateAuthorityProperties.CommonName) Then
		SearchValues.Add(CertificateAuthorityProperties.CommonName);
	EndIf;
	
	If SearchValues.Count() > 0 Then
		Result.SearchValues = StrConcat(SearchValues, ",");
	EndIf;
	
	Return Result;

EndFunction

Function PrepareSearchValue(Val SearchValue) Export
	
	SearchValue = Upper(SearchValue);
	SearchValue = StrReplace(SearchValue, """", "");
	SearchValue = StrReplace(SearchValue, "«", "");
	SearchValue = StrReplace(SearchValue, "»", "");
	SearchValue = StrReplace(SearchValue, "“", "");
	SearchValue = StrReplace(SearchValue, "”", "");
	
	Return SearchValue;
	
EndFunction

// For internal use only.
// 
// Parameters:
//  Certificate - CryptoCertificate
//  CheckContext - See CertificateCAVerificationContext
// 
// Returns:
//   See DigitalSignatureInternalClientServer.DefaultCAVerificationResult
//
Function ResultofCertificateAuthorityVerification(Certificate, CheckContext) Export
	
	CertificationAuthorityAuditResult = DigitalSignatureInternalClientServer.DefaultCAVerificationResult();
	
	
	Return CertificationAuthorityAuditResult;
	
EndFunction

Function LinktothearticleonCAs() Export
	
	Return "https://its.1c.ru/bmk/esig_uc";
	
EndFunction

Function VipNetApplicationName() Export
	Return "ViPNet CSP";
EndFunction

Function CryptoProApplicationName() Export
	Return "CryptoPro CSP";
EndFunction

// 
// 
// Parameters:
//  ErrorText - String
//  Result - Boolean
//
Procedure OnDefineImportErrorInTokenLibraries(ErrorText, Result) Export
	
	
EndProcedure

#EndRegion
