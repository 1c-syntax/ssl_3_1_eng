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
	
	FillingValues = New Structure("EmailAccount", CommandParameter);
	OpenForm("InformationRegister.EmailAccountSettings.RecordForm",
		New Structure("Key,FillingValues", RecordKey(CommandParameter), FillingValues),
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function RecordKey(EmailAccount)
	
	Query = New Query("
		|SELECT
		|	EmailAccountSettings.EmailAccount
		|FROM
		|	InformationRegister.EmailAccountSettings AS EmailAccountSettings
		|WHERE
		|	EmailAccountSettings.EmailAccount = &EmailAccount
		|");
	
	Query.SetParameter("EmailAccount", EmailAccount);
	If Query.Execute().IsEmpty() Then
		Return Undefined;
	EndIf;
	
	RecordKeyData = New Structure("EmailAccount", EmailAccount);
	Return InformationRegisters.EmailAccountSettings.CreateRecordKey(RecordKeyData);
	
EndFunction

#EndRegion
