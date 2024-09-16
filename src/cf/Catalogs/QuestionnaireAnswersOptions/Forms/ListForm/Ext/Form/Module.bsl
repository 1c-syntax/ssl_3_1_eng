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
	
	If Not Users.IsExternalUserSession() Then
		Common.MessageToUser(
			NStr("en = 'Questionnaire response options are used only by external users.';"),,,,Cancel);
	EndIf;
	
EndProcedure

#EndRegion
