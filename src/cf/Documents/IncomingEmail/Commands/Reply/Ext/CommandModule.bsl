///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Basis = New Structure("Basis,Command", CommandParameter, "Reply");
	OpeningParameters = New Structure("Basis", Basis);
	OpenForm("Document.OutgoingEmail.ObjectForm", OpeningParameters);
	CommandExecuteParameters.Source.Close();
	
EndProcedure

#EndRegion