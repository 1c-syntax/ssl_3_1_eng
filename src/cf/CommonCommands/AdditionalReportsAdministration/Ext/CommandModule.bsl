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
	
	AdditionalReportsAndDataProcessorsClient.OpenAdditionalReportAndDataProcessorCommandsForm(
		CommandParameter,
		CommandExecuteParameters,
		AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalReport(),
		"Administration");
	
EndProcedure

#EndRegion
