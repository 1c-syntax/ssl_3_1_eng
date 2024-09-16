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
	If AdditionalProperties.Property("PredefinedObjectsFilling") Then
		CheckPredefinedReportOptionFilling(Cancel);
	EndIf;
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not AdditionalProperties.Property("PredefinedObjectsFilling") Then
		Raise NStr("en = 'Predefined report options catalog is modified only during automatic population.';");
	EndIf;
EndProcedure

// Basic data validation checks for predefined report variants.
Procedure CheckPredefinedReportOptionFilling(Cancel)
	If DeletionMark Then
		Return;
	EndIf;
	If Not ValueIsFilled(Report) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Field %1 is required.';"), "Report");
	EndIf;
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf