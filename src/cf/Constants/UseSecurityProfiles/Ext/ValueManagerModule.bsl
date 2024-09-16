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
	
	// 
	// 
	SafeModeManagerInternal.OnSaveInternalData(ThisObject);
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Value Then
		SSLSubsystemsIntegration.OnEnableSecurityProfiles();
		SafeModeManagerOverridable.OnEnableSecurityProfiles();
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf