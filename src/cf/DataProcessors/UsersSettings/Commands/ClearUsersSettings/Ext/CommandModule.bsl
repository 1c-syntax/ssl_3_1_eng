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
	
	OpenForm("DataProcessor.UsersSettings.Form.ClearUsersSettings", , CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion