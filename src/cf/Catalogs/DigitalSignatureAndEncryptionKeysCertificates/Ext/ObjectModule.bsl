///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	CopiedObject = Catalogs.DigitalSignatureAndEncryptionKeysCertificates.CreateItem();
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If FillingData = Undefined Then
		Application = Catalogs.DigitalSignatureAndEncryptionApplications.EmptyRef();
	EndIf;	
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Application = Undefined Then
		Application = Catalogs.DigitalSignatureAndEncryptionApplications.EmptyRef();
	EndIf;
	
	If ValueIsFilled(Application) And TypeOf(Application) = Type(
		"CatalogRef.DigitalSignatureAndEncryptionApplications") And ValueIsFilled(Thumbprint) Then

		ApplicationDetails = Common.ObjectAttributesValues(Application,
			"IsBuiltInCryptoProvider, SignAlgorithm, HashAlgorithm");

		If Not ApplicationDetails.IsBuiltInCryptoProvider Then
			BinaryData = CertificateData.Get();
			If TypeOf(BinaryData) = Type("BinaryData") Then

				CertificateAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(
					BinaryData, False, True);

				Result = DigitalSignatureInternalClientServer.SignAlgorithmCorrespondsToCertificate(
					Description, CertificateAlgorithm, ApplicationDetails.SignAlgorithm,
					ApplicationDetails.HashAlgorithm);

				If Result <> True Then

					Raise Result;

				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf