///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	TimestampServersAddresses = DigitalSignatureInternal.TimestampServersAddresses(Value);
	ErrorText = NStr("en = 'Invalid timestamp server address: %1.'");
	
	For Each Address In TimestampServersAddresses Do
		URLStructure1 = CommonClientServer.URIStructure(Address);
		If Not Common.DomainNameCorrect(URLStructure1.Host) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Address);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.'");
#EndIf