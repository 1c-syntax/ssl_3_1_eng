///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var AllowClose;

&AtClient
Var WaitingCompleted;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Duration = Parameters.Duration;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AllowClose = False;
	
	If Duration > 0 Then
		WaitingCompleted = False;
		AttachIdleHandler("AfterWaitForSettingsApplyingInCluster", Duration, True);
	Else
		WaitingCompleted = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not AllowClose Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterWaitForSettingsApplyingInCluster()
	
	AllowClose = True;
	Close(DialogReturnCode.OK);
	
EndProcedure

#EndRegion