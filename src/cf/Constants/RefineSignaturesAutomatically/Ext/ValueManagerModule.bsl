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
	
	If Value < 0 Or Value > 2 Then
		ErrorText = NStr("en = 'Incorrect constant value: %1. Possible values:
			|0 - do not enhance signatures automatically and do not display commands for manual processing in the interface.
			|1 - enhance signatures using a scheduled job.
			|2 - enhance signatures manually (display commands in the administrator interface and in the to-do list)';");
		Raise StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Value);
	EndIf;
	
	DigitalSignatureInternal.ChangeRegulatoryTaskExtensionCredibilitySignatures(Value);

EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf