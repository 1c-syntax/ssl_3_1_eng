///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.Token) Then
		
		FillPropertyValues(ThisObject, Parameters.Token,,"Certificates");
		
		If IsServer Then
			TitleTemplate1 = NStr("en = '%1 on server';");
		Else
			TitleTemplate1 = NStr("en = '%1 on computer';");
		EndIf;
		
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			TitleTemplate1, Parameters.Token.Presentation);
		
	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	AttachIdleHandler("FillInListOfCertificates", 0.1, True);
EndProcedure

#EndRegion

#Region Private

&AtClient
Async Procedure FillInListOfCertificates()
	
	Token = New Structure;
	Token.Insert("Slot");
	Token.Insert("SerialNumber");
	FillPropertyValues(Token, ThisObject);
	
	Items.GroupRefreshCertificates.Visible = True;
	Result = Await DigitalSignatureClientLocalization.TokenCertificates(Token, Undefined, True);
	
	ErrorText = "";
	If Result.CheckCompleted Then
		Errors = New Array;
		PopulateCertificateListOnServer(Result.Certificates, Errors);
		If Errors.Count() > 0 Then
			ErrorText = StrConcat(Errors, Chars.LF);
		EndIf;
	Else
		ErrorText = Result.Error;
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		FormParameters = New Structure;
		FormParameters.Insert("WarningTitle", NStr("en = 'Couldn''t read certificates stored on the token';"));
		FormParameters.Insert("ErrorTextClient", ErrorText);
		FormParameters.Insert("ShowNeedHelp", True);
		DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(FormParameters, ThisObject);
	EndIf;
	
	Items.GroupRefreshCertificates.Visible = False;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	FillInListOfCertificates()
EndProcedure

&AtServer
Procedure PopulateCertificateListOnServer(CertificatesAsString, Errors)
	
	Certificates.Clear();
	
	For Each Certificate In CertificatesAsString Do
		
		Certificate = StrReplace(Certificate, "-----BEGIN CERTIFICATE-----", "");
		Certificate = StrReplace(Certificate, "-----END CERTIFICATE-----", "");
		Certificate = StrReplace(Certificate, Chars.LF, "");
		
		Try
			CertificateData = Base64Value(Certificate);
		Except
			Errors.Add(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Continue;
		EndTry;

		If TypeOf(CertificateData) <> Type("BinaryData") Then
			Continue;
		EndIf;

		Try
			CryptoCertificate = New CryptoCertificate(CertificateData);
		Except
			Errors.Add(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Continue;
		EndTry;
		
		CertificateProperties = DigitalSignatureInternalClientServer.CertificateProperties(
			CryptoCertificate, DigitalSignatureInternal.UTCOffset(), CertificateData);
		
		NewRow = Certificates.Add();
		NewRow.ValidUntil = CertificateProperties.ValidBefore;
		NewRow.Thumbprint = CertificateProperties.Thumbprint;
		NewRow.Presentation = CertificateProperties.Presentation;
		NewRow.IssuedBy = CertificateProperties.IssuedBy;
		NewRow.CertificateAddress = PutToTempStorage(CryptoCertificate.Unload(), UUID);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CertificatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CertificateRef = CertificateRef(Items.Certificates.CurrentData.Thumbprint);
	If Not ValueIsFilled(CertificateRef) Then
		DigitalSignatureClient.OpenCertificate(Items.Certificates.CurrentData.CertificateAddress);
	Else
		DigitalSignatureClient.OpenCertificate(CertificateRef);
	EndIf;
	
	
EndProcedure 

&AtServerNoContext
Function CertificateRef(Thumbprint)
    Return DigitalSignature.CertificateRef(Thumbprint);
EndFunction

#EndRegion