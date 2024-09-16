///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// Returns the details of an object that is not recommended to edit
// by processing a batch update of account details.
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

// 

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

// Registers objects
// that need to be updated to the new version on the exchange plan for updating the information Database.
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

// The update handler for version 3.1.5.108:
// - fills in the details of the "Type-defined folder" in the directory "Email Folders".
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
	
	ObjectsForProcessing = Query.Execute().Select();
	
	While ObjectsForProcessing.Next() Do
		RepresentationOfTheReference = String(ObjectsForProcessing.Ref);
		BeginTransaction();
		
		Try
			
			// 
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", ObjectsForProcessing.Ref);
			
			Block.Lock();
			
			Object = ObjectsForProcessing.Ref.GetObject();
			
			If Object = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(ObjectsForProcessing.Ref);
			Else
				
				If Object.PredefinedFolder
					And Not ValueIsFilled(Object.PredefinedFolderType) Then
					Object.PredefinedFolderType = EmailManagement.TheTypeOfThePredefinedFolderByName(ObjectsForProcessing.Description);
					InfobaseUpdate.WriteData(Object);
				Else
					InfobaseUpdate.MarkProcessingCompletion(ObjectsForProcessing.Ref);
				EndIf;
				
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdate.WriteErrorToEventLog(
				ObjectsForProcessing.Ref,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
