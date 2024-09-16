///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Procedure OnGetCertificatePresentation(Val Certificate, Val UTCOffset, Presentation) Export
	
	
EndProcedure

Procedure OnGetSubjectPresentation(Val Certificate, Presentation) Export
	
	
EndProcedure

Procedure OnGetExtendedCertificateSubjectProperties(Val Subject, Properties) Export
	
	
EndProcedure

Procedure OnGetExtendedCertificateIssuerProperties(Val Issuer, Properties) Export
	
	
EndProcedure

Procedure OnReceivingXMLEnvelope(Parameters, XMLEnvelope) Export
	
	
EndProcedure

Procedure OnGetDefaultEnvelopeVariant(XMLEnvelope) Export

	
EndProcedure

// 
// 
// Parameters:
//  CertificateAuthorityName - String - 
//  Certificate  - BinaryData
//              - String
// 
// Returns:
//  Structure:
//   * InternalAddress - String - 
//   * ExternalAddress - String - 
//
Function RevocationListInternalAddress(CertificateAuthorityName, Certificate) Export
	
	Result = New Structure("ExternalAddress, InternalAddress");
	
	CertificateAuthorityName = StrReplace(CertificateAuthorityName, " ", "_");
	CertificateAuthorityName = TrimAll(StrConcat(StrSplit(CertificateAuthorityName, "!*'();:@&=+$,/?%#[]\|<>", True), ""));
	
	CertificateAuthorityName = CommonClientServer.ReplaceProhibitedCharsInFileName(CertificateAuthorityName, "");
	
	If Not ValueIsFilled(CertificateAuthorityName) Then
		Return Result;
	EndIf;
	
	CertificateAdditionalProperties = 
		DigitalSignatureInternalClientServer.CertificateAdditionalProperties(Certificate, 0);
	
	If Not ValueIsFilled(CertificateAdditionalProperties.CertificateAuthorityKeyID) Then
		Return Result;
	EndIf;
	
	Result.InternalAddress = StrTemplate("%1/%2", CertificateAuthorityName, Lower(CertificateAdditionalProperties.CertificateAuthorityKeyID));
	
	
	Return Result;
	
EndFunction

// Returns:
//  Undefined, Structure - :
//   * IsState - Boolean
//   * AllowedUncredited - Boolean
//   * ActionPeriods - 
//     **DateFrom - Date
//     **DateBy - 
//   * ValidityEndDate - 
//   * UpdateDate  - 
//   * FurtherSettings - Map
//
Function CertificationAuthorityData(SearchValues, AccreditedCertificationCenters) Export
	
	Result = Undefined;
	
	
	Return Result;
	
EndFunction

Procedure OnDefineRefToAppsGuide(Section, URL) Export
	
	
EndProcedure

Procedure OnDefiningRefToAppsTroubleshootingGuide(URL, SectionName = "") Export
	
	
EndProcedure

Procedure OnDefineRefToSearchByErrorsWhenManagingDigitalSignature(URL, SearchString = "") Export
	
	
EndProcedure



#EndRegion