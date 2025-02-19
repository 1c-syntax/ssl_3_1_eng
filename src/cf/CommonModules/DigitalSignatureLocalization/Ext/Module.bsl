///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// On create at server.
// 
// Parameters:
//  Form - ClientApplicationForm
//
Procedure OnCreateAtServer(Form) Export
	
	
EndProcedure

// Overrides the signature type display in the settings form of the administration panel and the tooltip text in the signing form.
// 
// Parameters:
//  SignatureType - EnumRef.CryptographySignatureTypes
//  SignaturePresentation - String
//
Procedure OnPopulateSignatureTypePresentation(SignatureType, SignaturePresentation) Export
	
	
EndProcedure


// 
// 
// Parameters:
//  Form - See CommonForm.AddDigitalSignatureFromFile
//
Procedure OnImportMRLOAs(Form) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  Form - See CommonForm.AddDigitalSignatureFromFile
//  SignedObject - DefinedType.SignedObject
//
Procedure OnFillMRLOAs(Form, SignedObject = Undefined) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  Form - See CommonForm.AddDigitalSignatureFromFile
//  SignedObject - DefinedType.SignedObject
//  
//
Procedure OnFillMRLOAInRow(Form, RowID, SignedObject) Export

	
EndProcedure

// See ClassifiersOperationsOverridable.OnAddClassifiers.
Procedure OnAddClassifiers(Classifiers) Export
		
	
EndProcedure

// See ClassifiersOperationsOverridable.OnImportClassifier.
Procedure OnImportClassifier(Id, Version, Address, Processed, AdditionalParameters) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  Form - See CommonForm.AddDigitalSignatureFromFile
//  PlacedFiles - Array 
//  OtherFiles - Map 
//  ErrorOnLOAsImport - String 
//  UUID - UUID
// 
Procedure OnAddRowsAtServer(Form, PlacedFiles, OtherFiles, ErrorOnLOAsImport, UUID) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  Signatures - Array
//  SignedObject - DefinedType.SignedObject
//  ChecksResults - Array
//
Procedure OnVerifySignaturesOnMRLOA(Signatures, SignedObject, ChecksResults) Export


EndProcedure

// 
// 
// Parameters:
//  AvailabilityOfCreatingAnApplication - See DigitalSignature.AvailabilityOfCreatingAnApplication
//
Procedure OnDetermineAvailabilityOfApplicationCreation(AvailabilityOfCreatingAnApplication) Export
	
	
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
Procedure OnFillCertificationAuthorityAuditResult(
	Result, CryptoCertificate, OnDate, CheckParameters, CertificateProperties) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  AccreditedCertificationCenters - Structure
//
Procedure OnGetAccreditedCAs(AccreditedCertificationCenters) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  ClassifierData - 
//
Procedure OnGetCryptoErrorsClassifier(ClassifierData) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  IsCheckAvailable - Boolean
//
Procedure OnDetermineAvailabilityOfCheckByCAList(IsCheckAvailable) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  Parameters - Structure
//  Id - String
//  Result - See TimeConsumingOperations.ExecuteFunction 
//
Procedure OnGetDistribution(Parameters, Id, Result) Export
	
	
EndProcedure

// 
// 
// Parameters:
//  TimeConsumingOperation - Structure:
//   * ResultAddress - String - 
//  FormIdentifier - UUID
//  Result - Structure
//
Procedure OnProcessDistributionGetResult(TimeConsumingOperation, FormIdentifier, Result) Export
	
	
EndProcedure

#EndRegion
