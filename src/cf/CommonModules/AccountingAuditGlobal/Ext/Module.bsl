///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Displays an alert about existing accounting problems
// in the absence of a subsystem of the current day.
//
Procedure NotifyOfAccountingIssues() Export
	
#If MobileClient Then
	If MainServerAvailable() = False Then
		Return;
	EndIf;
#EndIf
	
	AccountingAuditInternalClient.NotifyOfAccountingIssuesCases();
EndProcedure

#EndRegion
