///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.SharedUser.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Cannot display information on user %1.
		           |This is a service account reserved for SaaS administrators.';"),
		String(Parameters.Key));
	
EndProcedure

#EndRegion