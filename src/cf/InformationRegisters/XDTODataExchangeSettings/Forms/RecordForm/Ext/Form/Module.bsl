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
	
	RecordManager = InformationRegisters.XDTODataExchangeSettings.CreateRecordManager();
	FillPropertyValues(RecordManager, Record.SourceRecordKey);
	RecordManager.Read();
	
	SettingsSupportedObjects = InformationRegisters.XDTODataExchangeSettings.SettingValue(
		RecordManager.InfobaseNode, "SupportedObjects");
		
	If Not SettingsSupportedObjects = Undefined Then
		SupportedObjects.Load(SettingsSupportedObjects);
	EndIf;
	
	CorrespondentSettingsSupportedObjects = InformationRegisters.XDTODataExchangeSettings.CorrespondentSettingValue(
		RecordManager.InfobaseNode, "SupportedObjects");
	
	If Not CorrespondentSettingsSupportedObjects = Undefined Then
		SupportedCorrespondentObjects.Load(CorrespondentSettingsSupportedObjects);
	EndIf;
	
EndProcedure

#EndRegion
