///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var SettingEnabled; // 
                         // 

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SettingEnabled = Value And Not Constants.UseImportForbidDates.Get();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	// 
	// 
	If Not AdditionalProperties.Property("SkipPeriodClosingDatesVersionUpdate") Then
		PeriodClosingDatesInternal.UpdatePeriodClosingDatesVersion();
	EndIf;
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If SettingEnabled Then
		SectionsProperties = PeriodClosingDatesInternal.SectionsProperties();
		If Not SectionsProperties.ImportRestrictionDatesImplemented Then
			Raise PeriodClosingDatesInternal.ErrorTextImportRestrictionDatesNotImplemented();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf