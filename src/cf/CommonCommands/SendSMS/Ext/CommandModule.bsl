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
	
	AdditionalParameters = New Structure("MessageSourceFormName", "");
	If TypeOf(CommandExecuteParameters.Source) = Type("ClientApplicationForm") Then
		AdditionalParameters.MessageSourceFormName = CommandExecuteParameters.Source.FormName;
	EndIf;
	
	MessageTemplatesClient.GenerateMessage(CommandParameter, "SMSMessage",,, AdditionalParameters);
	
EndProcedure

#EndRegion
