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
	
	RunParameters = StandardSubsystemsClient.ClientRunParameters();
	BackupParameters = RunParameters.IBBackup;
	
	FormParameters = New Structure();
	
	If BackupParameters.Property("CopyingResult") Then
		FormParameters.Insert("WorkMode", ?(BackupParameters.CopyingResult = True, "CompletedSuccessfully1", "NotCompleted2"));
		FormParameters.Insert("BackupFileName", BackupParameters.BackupFileName);
	EndIf;
	
	OpenForm("DataProcessor.IBBackup.Form.DataBackup", FormParameters);
	
EndProcedure

#EndRegion
