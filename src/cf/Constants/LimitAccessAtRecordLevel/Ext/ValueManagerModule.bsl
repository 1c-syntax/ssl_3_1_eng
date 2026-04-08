///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

// Intended for the "OnWrite" event handler.
Var PreviousValue2;

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	PreviousValue2 = AccessManagementInternal.ConstantLimitAccessAtRecordLevel();
	
	If Value = PreviousValue2 Then
		Return;
	EndIf;
	
	AccessManagementInternal.CheckIsAccessRestrictionDisabled();
	
	If Common.IsStandaloneWorkplace() Then
		ErrorText =
			NStr("en = 'RLS access restrictions can only be changed in the SaaS version.'");
		Raise ErrorText;
		
	ElsIf Common.IsSubordinateDIBNode() Then
		ErrorText =
			NStr("en = 'RLS access restrictions can only be changed in the master node.'");
		Raise ErrorText;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Value <> PreviousValue2 Then
		RefreshReusableValues();
		Try
			AccessManagementInternal.OnChangeAccessRestrictionAtRecordLevel(
				Not PreviousValue2 And Value);
		Except
			RefreshReusableValues();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// For internal use only.
Procedure RegisterChangeUponDataImport(DataElement) Export
	
	CurrentValue = AccessManagementInternal.ConstantLimitAccessAtRecordLevel();
	
	If DataElement.Value = CurrentValue
	 Or AccessManagementInternal.IsRecordLevelRestrictionDisabled()
	 Or Common.DataSeparationEnabled() Then
		// In the SWS, right settings are locked for editing and are not imported into the data area.
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	UsersInternal.RegisterRefs("LimitAccessAtRecordLevel", True);
	
EndProcedure

// For internal use only.
Procedure ProcessChangeRegisteredUponDataImport() Export
	
	If Common.DataSeparationEnabled() Then
		// In the SWS, right settings are locked for editing and are not imported into the data area.
		UsersInternal.RegisterRefs("LimitAccessAtRecordLevel", Null);
		Return;
	EndIf;
	
	Changes = UsersInternal.RegisteredRefs("LimitAccessAtRecordLevel");
	If Changes.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentValue = AccessManagementInternal.ConstantLimitAccessAtRecordLevel();
	If Not AccessManagementInternal.IsRecordLevelRestrictionDisabled() Then
		AccessManagementInternal.OnChangeAccessRestrictionAtRecordLevel(CurrentValue);
	EndIf;
	
	UsersInternal.RegisterRefs("LimitAccessAtRecordLevel", Null);
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.'");
#EndIf