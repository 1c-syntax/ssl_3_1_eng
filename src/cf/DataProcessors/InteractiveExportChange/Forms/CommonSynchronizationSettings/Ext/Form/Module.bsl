///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers
//

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CloseOnOwnerClose = True;
	
	If ValueIsFilled(Parameters.InfobaseNode) Then
		CommonSyncSettingsAsString = DataExchangeServer.DataSynchronizationRulesDetails(Parameters.InfobaseNode);
		NodeDescription = String(Parameters.InfobaseNode);
	Else
		NodeDescription = "";
	EndIf;
	
	Title = StrReplace(Title, "%1", NodeDescription);
	
EndProcedure

#EndRegion
