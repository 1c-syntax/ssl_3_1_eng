﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Function FilesCatalogsAndStorageOptionObjects() Export
	
	FilesCatalogs = New Map();
	InfobaseStorageOptionObjects = New Map();
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		
		Handler = "FilesOperationsInternal";
		CommonModule = Common.CommonModule(Handler);
		If CommonModule <> Undefined Then
			
			HandlerFilesCatalogs = CommonModule.FilesCatalogs();
			For Each HandlerFilesCatalog In HandlerFilesCatalogs Do
				FilesCatalogs.Insert(HandlerFilesCatalog.FullName(), Handler);
			EndDo;
			
			HandlerStorageOptionObjects = CommonModule.InfobaseFileStoredObjects();
			For Each HandlerStorageObject In HandlerStorageOptionObjects Do
				InfobaseStorageOptionObjects.Insert(HandlerStorageObject.FullName(), Handler);
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Cache = New Structure("FilesCatalogs, StorageObjects", FilesCatalogs, InfobaseStorageOptionObjects);
	
	Return Cache;
	
EndFunction

#EndRegion