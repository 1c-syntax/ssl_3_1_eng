///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Displays a notification about the need to update the Bank classifier.
//
Procedure BankManagerOutputObsoleteDataNotification() Export
	BankManagerClient.NotifyClassifierObsolete();
EndProcedure

Procedure BankManagerOpenClassifierImportForm() Export
	BankManagerClient.GoToClassifierImport();
EndProcedure

#EndRegion
