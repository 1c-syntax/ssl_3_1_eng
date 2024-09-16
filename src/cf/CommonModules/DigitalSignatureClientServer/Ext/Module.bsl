///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// 
// 
// 
// Returns:
//   Structure:
//     * Signature             - BinaryData -  the result of the signing.
//                           - String - 
//     * SignatureSetBy - CatalogRef.Users -  the user who
//                           signed the database object.
//     * Comment         - String -  comment, if it was entered when signing.
//     * SignatureFileName     - String -  if the signature was added from a file.
//     * SignatureDate         - Date -  the date when the signature was made. This makes sense if
//                           the date cannot be extracted from the signature data.
//     * SkipUponRenewal - Boolean - 
//                                
//
//     :
//     * SignatureValidationDate - Date -  date of the last signature verification.
//     * SignatureCorrect        - Boolean -  result of the last signature check.
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
//     * SignedObject   - DefinedType.SignedObject - 
//                             
//     * SequenceNumber     - Number - 
//                             
//     * IsErrorOccurredDuringAutomaticRenewal - Boolean - 
//     :
//     * SignatureID - UUID
//     * ResultOfSignatureVerificationByMRLOA - Array of Structure, Structure - 
//
//     :
//     * SignatureType          - EnumRef.CryptographySignatureTypes
//     * DateActionLastTimestamp - Date - 
//                                           
//                                           
//     * Certificate          - ValueStorage -  contains an upload of the certificate
//                             that was used for signing (contained in the signature).
//                           - BinaryData
//     * Thumbprint           - String -  the thumbprint of the certificate in Base64 string format.
//     * CertificateOwner - String -  the subject representation obtained from the certificate's binary data.
//     * CertificateDetails - Structure - 
//                             :
//        ** SerialNumber  - String -  serial number of the certificate, like the certificate Cryptography platform object.
//        ** IssuedBy       - String -  how the publisher View function returns.
//        ** IssuedTo      - String -  how the object Representation function returns.
//        ** StartDate     - String -  date of the certificate, as in the object of the platform Certatcryptography in the format "DLF=D".
//        ** EndDate  - String -  date of the certificate, as in the object of the platform Certatcryptography in the format "DLF=D".
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
	
	Structure.Insert("SkipUponRenewal");
	Structure.Insert("IsErrorOccurredDuringAutomaticRenewal", False);
	Structure.Insert("SignatureID");
	Structure.Insert("ResultOfSignatureVerificationByMRLOA");
	
	Return Structure;
	
EndFunction

// 
// 
// Returns:
//  Structure:
//   * Result - Boolean     - 
//             - String       - 
//             - Undefined - 
//   * SignatureCorrect        - Boolean, Undefined -  result of the last signature check.
//   * CertificateRevoked   - Boolean - 
//   * IsVerificationRequired   - Boolean - 
//   * IsSignatureMathematicallyValid - Boolean -  
//                                           
//   * SignatureMathValidationError - String - 
//                                                    
//   * AdditionalAttributesCheckError - String - 
//                                                      
//   * CertificateVerificationParameters - 
//
//   * SignatureType          - EnumRef.CryptographySignatureTypes - 
//   * DateActionLastTimestamp - Date - 
//    
//   * UnverifiedSignatureDate - Date - 
//                                 - Undefined - 
//                                                
//   * DateSignedFromLabels  - Date - 
//                         - Undefined - 
//   * Certificate          - BinaryData - 
//   * Thumbprint           - String -  the thumbprint of the certificate in Base64 string format.
//   * CertificateOwner - String -  the subject representation obtained from the certificate's binary data.
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
	Structure.Insert("CertificateVerificationParameters", DigitalSignatureInternalClientServer.CheckQualified());
	
	CommonClientServer.SupplementStructure(
		Structure, DigitalSignatureInternalClientServer.SignaturePropertiesUponReadAndVerify());
		
	Return Structure;
	
EndFunction

// 
// 
// Returns:
//  Structure - :
//   * SequenceNumber - 
//   * Object - 
//   * SignatureDate - 
//   * Comment - 
//   * SignatureAddress - String - 
//   * Thumbprint - 
//   * CertificateAddress - String - 
//   * SignatureCorrect - 
//   * SignatureValidationDate - 
//   * CertificateOwner - 
//   * IsVerificationRequired - 
//   * SignatureSetBy - 
//   * SignatureType - 
//   * DateActionLastTimestamp - 
//   * MachineReadableLetterOfAuthority - CatalogRef.MachineReadablePowersAttorney
//   * MachineReadableLOAValid - Boolean
//   * ResultOfSignatureVerificationByMRLOA - 
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
	SignatureProperties.Insert("SignatureFileName");
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
	ElsIf ValueIsFilled(CheckResult.AdditionalAttributesCheckError) Then
			
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
	Else
		SignatureProperties.BriefCheckResult =  StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1.';"), Status);
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