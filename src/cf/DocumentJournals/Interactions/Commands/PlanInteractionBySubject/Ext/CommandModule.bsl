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
		"Document.PlannedInteraction.ObjectForm",
		CommandParameter, CommandExecuteParameters.Source);
	
EndProcedure

#EndRegion