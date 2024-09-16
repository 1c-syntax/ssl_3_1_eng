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
	
	Cancel = False;
	
	TempStorageAddress = "";
	
	GetSecondInfobaseDataExchangeSettingsAtServer(Cancel, TempStorageAddress, CommandParameter);
	
	If Cancel Then
		
		ShowMessageBox(, NStr("en = 'Cannot get data exchange settings.';"));
		
	Else
		
		SavingParameters = FileSystemClient.FileSavingParameters();
		SavingParameters.Dialog.Filter = "Files XML (*.xml)|*.xml";

		FileSystemClient.SaveFile(
			Undefined,
			TempStorageAddress,
			NStr("en = 'Synchronization settings.xml';"),
			SavingParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GetSecondInfobaseDataExchangeSettingsAtServer(Cancel, TempStorageAddress, InfobaseNode)
	
	DataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard().Create();
	DataExchangeCreationWizard.Initialize(InfobaseNode);
	DataExchangeCreationWizard.ExportWizardParametersToTempStorage(Cancel, TempStorageAddress);
	
EndProcedure

#EndRegion
