///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Function AccreditedCertificationCenters() Export
	
	Return DigitalSignatureInternalServerCall.AccreditedCertificationCenters();
	
EndFunction

Function CertificationAuthorityData(SearchValues) Export
	
	AccreditedCertificationCenters = DigitalSignatureInternalClientCached.AccreditedCertificationCenters();
	If AccreditedCertificationCenters = Undefined Then
		Return Undefined;
	EndIf;
	
	ModuleDigitalSignatureClientServerLocalization = CommonClient.CommonModule("DigitalSignatureClientServerLocalization");
	Return ModuleDigitalSignatureClientServerLocalization.CertificationAuthorityData(SearchValues, AccreditedCertificationCenters);
	
EndFunction

Function ClassifierError(ErrorText) Export
	
	Return DigitalSignatureInternalServerCall.ClassifierError(ErrorText);
	
EndFunction

#EndRegion