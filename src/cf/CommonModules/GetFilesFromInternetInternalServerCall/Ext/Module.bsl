///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

#Region DownloadFileAtClient

Function DownloadFile(URL, ReceivingParameters, WriteError1) Export
	
	SavingSetting = New Map;
	SavingSetting.Insert("StorageLocation", "TemporaryStorage");
	
	Return GetFilesFromInternetInternal.DownloadFile(
		URL, ReceivingParameters, SavingSetting, WriteError1);
	
EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

Function ProxySettingsState() Export
	
	Return GetFilesFromInternetInternal.ProxySettingsState();
	
EndFunction

#EndRegion

#EndRegion
