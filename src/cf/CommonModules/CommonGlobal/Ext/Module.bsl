///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Asks whether the action that causes changes to be lost will continue.
//
Procedure ConfirmFormClosingNow() Export
	
	CommonInternalClient.ConfirmFormClosing();
	
EndProcedure

// Asks whether the action that leads to closing the form should continue.
//
Procedure ConfirmArbitraryFormClosingNow() Export
	
	CommonInternalClient.ConfirmArbitraryFormClosing();
	
EndProcedure

#EndRegion
