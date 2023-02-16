///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlersForm

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(ThisObject, Parameters.SignatureProperties);
	
	If Parameters.SignatureProperties.Property("Object") Then
		SignedObject = Parameters.SignatureProperties.Object;
	EndIf;
	
	If Parameters.SignatureProperties.SignatureCorrect Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "");
		Items.Instruction.Visible     = False;
		Items.ErrorDescription.Visible = False;
	Else
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "ErrorDescription");
	EndIf;
	
	If Not IsTempStorageURL(SignatureAddress) Then
		Return;
	EndIf;
	
	SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(
		SignatureAddress, True);
	
	HashAlgorithm = DigitalSignatureInternalClientServer.HashAlgorithm(
		SignatureAddress, True);
		
	UpdateFormData();
		
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InstructionClick(Item)
	
	DigitalSignatureClient.OpenInstructionOnTypicalProblemsOnWorkWithApplications();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SaveToFile(Command)
	
	DigitalSignatureClient.SaveSignature(SignatureAddress);
	
EndProcedure

&AtClient
Procedure OpenCertificate(Command)
	
	If ValueIsFilled(CertificateAddress) Then
		DigitalSignatureClient.OpenCertificate(CertificateAddress);
		
	ElsIf ValueIsFilled(Thumbprint) Then
		DigitalSignatureClient.OpenCertificate(Thumbprint);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExtendActionSignature(Command)
	
	FollowUpHandler = New NotifyDescription("AfterImprovementSignature", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("SignatureType", SignatureType);
	FormParameters.Insert("DataPresentation", 
		StrTemplate("%1, %2, %3", CertificateOwner, SignatureDate, SignatureType));
		
	If ValueIsFilled(SignedObject) Then
		Structure = New Structure;
		Structure.Insert("Signature", SignatureAddress);
		Structure.Insert("SignedObject", SignedObject);
		Structure.Insert("SequenceNumber", SequenceNumber); 
		FormParameters.Insert("Signature", Structure);
	Else
		FormParameters.Insert("Signature", SignatureAddress);
	EndIf;
	
	DigitalSignatureClient.OpenRenewalFormActionsSignatures(ThisObject, FormParameters, FollowUpHandler);
	
EndProcedure

#EndRegion

#Region Private


&AtServer
Procedure UpdateFormData()
	
	If DigitalSignature.AvailableAdvancedSignature() And DigitalSignature.AddEditDigitalSignatures() Then
		If (ValueIsFilled(DateActionLastTimestamp) And DateActionLastTimestamp <= CurrentSessionDate())
			Or SignatureType = Enums.CryptographySignatureTypes.NormalCMS Or Not SignatureCorrect Then
			Items.FormExtendActionSignature.Visible = False;
		Else
			Items.FormExtendActionSignature.Visible = True;
		EndIf;
	Else
		Items.FormExtendActionSignature.Visible = False;
	EndIf;
		
	If SignatureType = Enums.CryptographySignatureTypes.BasicCAdESBES
		Or SignatureType = Enums.CryptographySignatureTypes.NormalCMS Then
		If ValueIsFilled(DateActionLastTimestamp) Then
			Items.DateActionLastTimestamp.Title = NStr("en = 'Certificate expired';"); 
		Else
			Items.DateActionLastTimestamp.Visible = False;
		EndIf;
	Else
		Items.DateActionLastTimestamp.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterImprovementSignature(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Success Then
		
		For Each KeyAndValue In Result.PropertiesSignatures[0].SignatureProperties Do
			If KeyAndValue.Key = "Signature" Then
				SignatureAddress = PutToTempStorage(KeyAndValue.Value);
				Continue;
			EndIf;
			If KeyAndValue.Value = Undefined Then
				Continue;
			EndIf;
			If Items.Find(KeyAndValue.Key) = Undefined Then
				Continue;
			EndIf;
			
			ThisObject[KeyAndValue.Key] = KeyAndValue.Value;
		EndDo;
		
		UpdateFormData();
	EndIf;
	
EndProcedure

#EndRegion
