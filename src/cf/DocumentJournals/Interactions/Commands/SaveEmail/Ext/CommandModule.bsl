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
	
	InteractionsClient.SaveEmailToHardDrive(CommandParameter, CommandExecuteParameters.Source.UUID);
	
EndProcedure

#EndRegion
