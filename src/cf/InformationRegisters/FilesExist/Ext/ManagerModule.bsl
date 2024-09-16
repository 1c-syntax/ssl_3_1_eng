///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// 

// Registers objects
// that need to be updated in the register on the exchange plan for updating the information Database.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.FullRegisterName = "InformationRegister.FilesExist";
	
	FirstQueryText =
		"SELECT DISTINCT
		|	AttachedFiles.FileOwner AS FileOwner
		|INTO OwnersOfFilesForAnalysis
		|FROM
		|	&CatalogName AS AttachedFiles
		|WHERE
		|	AttachedFiles.IsInternal = TRUE
		|	AND AttachedFiles.DeletionMark = FALSE
		|
		|INDEX BY
		|	FileOwner";
	
	TextOfSecondRequest = 
		"SELECT TOP 1000
		|	OwnersOfFilesForAnalysis.FileOwner AS ObjectWithFiles
		|FROM
		|	OwnersOfFilesForAnalysis AS OwnersOfFilesForAnalysis
		|		INNER JOIN InformationRegister.FilesExist AS FilesExist
		|		ON OwnersOfFilesForAnalysis.FileOwner = FilesExist.ObjectWithFiles
		|WHERE
		|	NOT TRUE IN
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					&CatalogName AS AttachedFiles
		|				WHERE
		|					OwnersOfFilesForAnalysis.FileOwner = AttachedFiles.FileOwner
		|					AND AttachedFiles.IsInternal = FALSE
		|					AND AttachedFiles.DeletionMark = FALSE)
		|	AND FilesExist.HasFiles = TRUE
		|	AND OwnersOfFilesForAnalysis.FileOwner > &FileOwnerLink
		|
		|ORDER BY
		|	FileOwner";
	
	ObjectsWithFiles = Metadata.InformationRegisters.FilesExist.Dimensions.ObjectWithFiles.Type.Types();
	ProcessedObjectsWithFiles = New Map;
	
	For Each ObjectWithFiles In ObjectsWithFiles Do
		CatalogNames = FilesOperationsInternal.FileStorageCatalogNames(ObjectWithFiles, True);
				
		For Each KeyAndValue In CatalogNames Do
			
			If ProcessedObjectsWithFiles[KeyAndValue.Key] = True Then
				Continue;
			EndIf;
			If Common.HasObjectAttribute("IsInternal", Metadata.Catalogs[KeyAndValue.Key]) = False Then
				Continue;
			EndIf;
						
			Query = New Query;
			Query.TempTablesManager = New TempTablesManager;
			Query.Text =  StrReplace(FirstQueryText,"&CatalogName","Catalog." + KeyAndValue.Key);
			// 
			Query.Execute();
			
			Query.Text = StrReplace(TextOfSecondRequest,"&CatalogName","Catalog." + KeyAndValue.Key);
			AllFilesOwnersProcessed = False;
			FileOwnerLink = "";
			
			While Not AllFilesOwnersProcessed Do
				
				Query.SetParameter("FileOwnerLink", FileOwnerLink);
				
				// 
				ValueTable = Query.Execute().Unload(); 
			
				InfobaseUpdate.MarkForProcessing(Parameters, ValueTable, AdditionalParameters);
				
				RefsCount = ValueTable.Count();
				If RefsCount < 1000 Then
					AllFilesOwnersProcessed = True;
				EndIf;
				
				If RefsCount > 0 Then
					FileOwnerLink = ValueTable[RefsCount-1].ObjectWithFiles;
				EndIf;
		
			EndDo;
			
			ProcessedObjectsWithFiles.Insert(KeyAndValue.Key,True);
		EndDo;	
	EndDo;
	
EndProcedure

// Update the register entries.
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	FullRegisterName = "InformationRegister.FilesExist";
	
	TempTablesManager = New TempTablesManager();
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
			
	RegisterSelection = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(
		Parameters.Queue,
		FullRegisterName,
		AdditionalParameters);
	
	If RegisterSelection.Count() = 0 Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	DataTable = New ValueTable;
	DataTable.Columns.Add("ObjectWithFiles");
	
	AddlParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AddlParameters.IsIndependentInformationRegister = True;
	AddlParameters.FullRegisterName = FullRegisterName;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	While RegisterSelection.Next() Do
		
		RepresentationOfTheReference = String(RegisterSelection.ObjectWithFiles);
		BeginTransaction();
		Try
			
			Block = New DataLock;
			LockItem = Block.Add(FullRegisterName);
			LockItem.SetValue("ObjectWithFiles", RegisterSelection.ObjectWithFiles);
			LockItem.Mode = DataLockMode.Shared;
			Block.Lock();
			
			If FilesOperationsInternal.OwnerHasFiles(RegisterSelection.ObjectWithFiles) = True Then
				// 
				DataTable.Clear();		
				
				FillPropertyValues(DataTable.Add(),RegisterSelection);
				InfobaseUpdate.MarkProcessingCompletion(DataTable,AddlParameters,Parameters.Queue);
		
			Else	
			
				RecordSetFilesExist = CreateRecordSet();
				RecordSetFilesExist.Filter.ObjectWithFiles.Set(RegisterSelection.ObjectWithFiles);
				RecordSetFilesExist.Read();
				
				If RecordSetFilesExist.Count() = 1 Then
					// 
					FilesExistSetRecord                      = RecordSetFilesExist[0];
					FilesExistSetRecord.HasFiles            = False;
					InfobaseUpdate.WriteRecordSet(RecordSetFilesExist, True);
				Else
					// 
					DataTable.Clear();		
				
					FillPropertyValues(DataTable.Add(),RegisterSelection);
					InfobaseUpdate.MarkProcessingCompletion(DataTable,AddlParameters,Parameters.Queue);	
				EndIf;
			EndIf;		
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
		Except
			RollbackTransaction();
			// 
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Не удалось обновить сведения о наличие файлов %1 по причине:
					|%2';"), 
				RepresentationOfTheReference, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				RegisterSelection.ObjectWithFiles.Metadata(), RegisterSelection.ObjectWithFiles, MessageText);
		EndTry;
			
	EndDo;
	
	
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t process (skipped) information records about availability of files: %1';"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), 
			EventLogLevel.Information, , ,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Yet another batch of information records about availability of files is processed: %1';"),
				ObjectsProcessed));
	EndIf;
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(Parameters.Queue,
		FullRegisterName);
			
EndProcedure

#EndRegion

#EndIf

