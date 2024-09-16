///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var InternalData, PasswordProperties;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.Token) Then
		
		FillPropertyValues(ThisObject, Parameters.Token);
		
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
	
	If InternalData = Undefined Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion


#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RememberPasswordOnChange(Item)
	
	AdditionalParameters = AdditionalParameters();
	AdditionalParameters.Insert("OnChangeAttributeRememberPassword", True);

	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, AdditionalParameters);
	
EndProcedure

#EndRegion

#Region Private

// APK: 78-off: for secure data transfer on the client between forms, without sending them to the server.
&AtClient
Procedure ContinueOpening(Notification, CommonInternalData, ClientParameters) Export
// 
	
	AdditionalParameters = AdditionalParameters();
	
	InternalData = CommonInternalData;
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, AdditionalParameters);
	Open();
	FillInListOfCertificates();
	
EndProcedure

&AtClient
Async Procedure FillInListOfCertificates()
	
	If Not ValueIsFilled(PasswordProperties.Value) Then
		Return;
	EndIf;
	
	Token = New Structure;
	Token.Insert("Slot");
	Token.Insert("SerialNumber");
	FillPropertyValues(Token, ThisObject);
	Token.Insert("PasswordValue", PasswordProperties.Value);
	
	Items.CertificateRenewalGroup.Visible = True;
	Result = Await DigitalSignatureClientLocalization.TokenCertificates(Token, Undefined, True);
	
	ErrorText = "";
	If Result.CheckCompleted Then
		Errors = New Array;
		FillInListOfCertificatesOnServer(Result.Certificates, Errors);
		If Errors.Count() > 0 Then
			ErrorText = StrConcat(Errors, Chars.LF);
		EndIf;
		
		AdditionalParameters = AdditionalParameters();
		AdditionalParameters.Insert("OnOperationSuccess", True);
		DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
			InternalData, PasswordProperties, AdditionalParameters);
		
	Else
		ErrorText = Result.Error;
		If DigitalSignatureClientLocalization.ThisIsErrorIncorrectPinCode(Result.Error) Then
			ErrorText = NStr("en = 'Invalid token holder''s PIN.';");
		EndIf;
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		FormParameters = New Structure;
		FormParameters.Insert("WarningTitle", NStr("en = 'Couldn''t read certificates stored on the token';"));
		FormParameters.Insert("ErrorTextClient", ErrorText);
		FormParameters.Insert("ShowNeedHelp", True);
		DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(FormParameters, ThisObject);
	EndIf;
	
	Items.CertificateRenewalGroup.Visible = False;
	
EndProcedure

&AtClient
Procedure PasswordOnChange(Item)
	
	AdditionalParameters = AdditionalParameters();
	AdditionalParameters.Insert("OnChangeAttributePassword", True);
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure PasswordStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	AdditionalParameters = AdditionalParameters();
	
	DigitalSignatureInternalClient.PasswordFieldStartChoice(ThisObject,
		InternalData, PasswordProperties, StandardProcessing, AdditionalParameters);
EndProcedure

&AtClient
Procedure Refresh(Command)
	FillInListOfCertificates()
EndProcedure

&AtServer
Procedure FillInListOfCertificatesOnServer(CertificatesByString, Errors)
	
	Certificates.Clear();
	
	For Each Certificate In CertificatesByString Do
		
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
	CertificateRef = GetLinkToCertificate(Items.Certificates.CurrentData.Thumbprint);
	If Not ValueIsFilled(CertificateRef) Then
		DigitalSignatureClient.OpenCertificate(Items.Certificates.CurrentData.CertificateAddress);
	Else
		DigitalSignatureClient.OpenCertificate(CertificateRef);
	EndIf;
	
	
EndProcedure 

&AtServerNoContext
Function GetLinkToCertificate(Thumbprint)
    Return DigitalSignature.CertificateRef(Thumbprint);
EndFunction

&AtClient
Function AdditionalParameters()
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("WhenReadingTokenCertificates", True);
	AdditionalParameters.Insert("Certificate", SerialNumber);
	AdditionalParameters.Insert("EnterPasswordInDigitalSignatureApplication", False);

	Return AdditionalParameters;
EndFunction

#EndRegion