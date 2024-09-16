///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		
		Return;
		
	EndIf;
	
	AdditionalProperties.Insert("CurrentValue", Constants.IsStandaloneWorkplace.Get());
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		
		Return;
		
	EndIf;
	
	StandardProcessing = True;
	PreviousValue = AdditionalProperties.CurrentValue;
	NewCurrent = Value;
	
	DataExchangeOverridable.WhenChangingOfflineModeOption(PreviousValue, NewCurrent, StandardProcessing);
	
	If StandardProcessing = False Then
		
		Return;
		
	EndIf;
	
	If AdditionalProperties.CurrentValue <> Value Then
		
		RefreshReusableValues();
		
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf