///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Performs a shift of the boundary results.
Procedure ExecuteCommand(CommandParameters, StorageAddress) Export
	SetPrivilegedMode(True);
	TotalsAndAggregatesManagementInternal.CalculateTotals();
EndProcedure

#EndRegion

#EndIf
