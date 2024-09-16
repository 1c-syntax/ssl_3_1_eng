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
		
	FormParameters = New Structure("InfobaseNode", CommandParameter);
	OpenForm("InformationRegister.ObjectsUnregisteredDuringLoop.ListForm", 
		FormParameters, CommandExecuteParameters.Source);
	
EndProcedure

#EndRegion