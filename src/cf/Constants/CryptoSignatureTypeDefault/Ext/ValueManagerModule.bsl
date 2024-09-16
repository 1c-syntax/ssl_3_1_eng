///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	If Value = Enums.CryptographySignatureTypes.NormalCMS
		Or Value = Enums.CryptographySignatureTypes.BasicCAdESBES
		Or Not ValueIsFilled(Value) Then
		If Constants.RefineSignaturesAutomatically.Get() <> 0 Then
			Constants.RefineSignaturesAutomatically.Set(0);
		EndIf;
	EndIf;
	
	DigitalSignatureInternal.ChangeRegulatoryTaskExtensionCredibilitySignatures(,,Value);

EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf