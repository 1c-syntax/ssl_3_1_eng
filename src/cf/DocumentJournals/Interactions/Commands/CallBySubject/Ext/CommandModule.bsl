﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	InteractionsClient.CreateInteractionOrSubject(
		"Document.PhoneCall.ObjectForm",
		CommandParameter, CommandExecuteParameters.Source);
	
EndProcedure

#EndRegion