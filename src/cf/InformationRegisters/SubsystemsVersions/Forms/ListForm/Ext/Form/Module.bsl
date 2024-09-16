///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ReadOnly = True;
	Items.FormRelaunchDeferredUpdate.Visible = Not Common.IsSubordinateDIBNode();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	Items.FormEnableEditing.Enabled = False;
	
EndProcedure

&AtClient
Procedure RelaunchDeferredUpdate(Command)
	OpenForm("InformationRegister.UpdateHandlers.Form.RestartDeferredUpdate");
EndProcedure

#EndRegion
