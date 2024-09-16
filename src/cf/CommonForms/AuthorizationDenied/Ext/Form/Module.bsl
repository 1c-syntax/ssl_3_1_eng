///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("IdleHandlerExitApplication", 5 * 60, True);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	Terminate();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExitApplication(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure IdleHandlerExitApplication()
	
	Close();
	
EndProcedure

#EndRegion
