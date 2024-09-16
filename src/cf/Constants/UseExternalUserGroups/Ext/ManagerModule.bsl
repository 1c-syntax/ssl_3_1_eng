///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure Refresh() Export
	
	CurrentValue = Constants.UseExternalUserGroups.Get();
	ComputedValue = ComputedValue();
	
	If CurrentValue <> ComputedValue Then
		Constants.UseExternalUserGroups.Set(ComputedValue);
	EndIf;
	
EndProcedure

Function ComputedValue() Export
	
	Return Constants.UseExternalUsers.Get()
	      And Constants.UseUserGroups.Get();
	
EndFunction

#EndRegion

#EndIf