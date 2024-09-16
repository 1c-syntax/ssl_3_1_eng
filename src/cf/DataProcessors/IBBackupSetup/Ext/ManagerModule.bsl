///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	StandardProcessing = False;
	SelectedForm = "DataProcessor.IBBackupSetup.Form.BackupSetupClientServer";
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		
		If Common.FileInfobase() Then
			SelectedForm = "DataProcessor.IBBackupSetup.Form.BackupSetup";
		EndIf;
		
	#EndIf
	
EndProcedure

#EndRegion

#EndIf