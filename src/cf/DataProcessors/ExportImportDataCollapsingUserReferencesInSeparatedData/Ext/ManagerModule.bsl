﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// See ExportImportDataOverridable.OnFillTypesThatRequireRefAnnotationOnImport
Procedure OnFillTypesThatRequireRefAnnotationOnImport(Types) Export
	
	Types.Add(Metadata.Catalogs.Users);
	
EndProcedure

// See ExportImportDataOverridable.OnRegisterDataExportHandlers.
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	HandlerObject = Create();
	
	NewHandler = HandlersTable.Add();
	NewHandler.MetadataObject = Metadata.Catalogs.Users;
	NewHandler.Handler = HandlerObject;
	NewHandler.BeforeExportData = True;
	NewHandler.BeforeExportObject = True;
	NewHandler.AfterExportObject = True;
	NewHandler.Version = "1.0.0.1";
	
EndProcedure

// See ExportImportDataOverridable.OnRegisterDataImportHandlers.
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	HandlerObject = Create();
	
	NewHandler = HandlersTable.Add();
	NewHandler.MetadataObject = Metadata.Catalogs.Users;
	NewHandler.Handler = HandlerObject;
	NewHandler.BeforeImportData = True;
	NewHandler.BeforeMapRefs = True;
	NewHandler.BeforeImportObject = True;
	NewHandler.Version = "1.0.0.1";
	
	RegistersList = UsersInternalSaaSCached.RecordSetsWithRefsToUsersList();
	For Each ListItem In RegistersList Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = ListItem.Key;
		NewHandler.Handler = HandlerObject;
		NewHandler.BeforeImportType = True;
		NewHandler.BeforeImportObject = True;
		NewHandler.Version = "1.0.0.1";
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf