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
	
	If Not IsBlankString(Parameters.QuestionTitle) Then
		Title = Parameters.QuestionTitle;
	EndIf;
	
	If Not IsBlankString(Parameters.QueryText) Then
		Items.Explanation.Title = Parameters.QueryText;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure InstallAndContinue(Command)
	
	Close(DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion
