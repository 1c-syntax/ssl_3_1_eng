﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(Variant, CommandExecuteParameters)
	ReportsOptionsClient.ShowReportSettings(Variant);
EndProcedure

#EndRegion
