///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.BatchEditObjects

// Returns the object attributes that are not recommended to be edited
// using a bulk attribute modification data processor.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("Code");
	Result.Add("Description");
	Result.Add("PredefinedFolder");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Owner)
	|	OR ValueAllowed(Owner.AccountOwner, EmptyRef AS FALSE)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region UpdateHandlers

// Registers the objects to be updated in the InfobaseUpdate exchange plan.
// 
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	QueryText ="
	|SELECT
	|	EmailMessageFolders.Ref AS Ref
	|FROM
	|	Catalog.EmailMessageFolders AS EmailMessageFolders
	|WHERE
	|	EmailMessageFolders.PredefinedFolder
	|	AND EmailMessageFolders.PredefinedFolderType = VALUE(Enum.PredefinedEmailsFoldersTypes.EmptyRef)
	|";
	
	Query = New Query(QueryText);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// A handler of the update to version 3.1.5.108:
// - — fills in the "PredefinedFolderType" attribute in the "Mailbox folder" catalog.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Catalog.EmailMessageFolders";
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ReferencesToProcess.Ref       AS Ref,
	|	CatalogTable.Description AS Description
	|FROM
	|	&TTDocumentsToProcess AS ReferencesToProcess
	|		LEFT JOIN Catalog.EmailMessageFolders AS CatalogTable
	|		ON CatalogTable.Ref = ReferencesToProcess.Ref";
	
	TempTablesManager = New TempTablesManager;
	Result = InfobaseUpdate.CreateTemporaryTableOfRefsToProcess(Parameters.Queue, FullObjectName, TempTablesManager);
	If Not Result.HasDataToProcess Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	If Not Result.HasRecordsInTemporaryTable Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf; 
	
	Query.Text = StrReplace(Query.Text, "&TTDocumentsToProcess", Result.TempTableName);
	Query.TempTablesManager = TempTablesManager;
	
	ObjectsToProcess1 = Query.Execute().Select();
	
	While ObjectsToProcess1.Next() Do
		
		BeginTransaction();
		
		Try
			
			// Setting a managed lock to post object responsible reading.
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", ObjectsToProcess1.Ref);
			
			Block.Lock();
			
			Object = ObjectsToProcess1.Ref.GetObject();
			
			If Object = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(ObjectsToProcess1.Ref);
			Else
				
				If Object.PredefinedFolder
					And Not ValueIsFilled(Object.PredefinedFolderType) Then
					Object.PredefinedFolderType = EmailManagement.TheTypeOfThePredefinedFolderByName(ObjectsToProcess1.Description);
					InfobaseUpdate.WriteData(Object);
				Else
					InfobaseUpdate.MarkProcessingCompletion(ObjectsToProcess1.Ref);
				EndIf;
				
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectMetadata = Common.MetadataObjectByFullName(FullObjectName);
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Failed to process %1 %2 due to:
					|%3';"), 
				FullObjectName, ObjectsToProcess1.Ref, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				ObjectMetadata,
				ObjectsToProcess1.Ref,
				MessageText);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
