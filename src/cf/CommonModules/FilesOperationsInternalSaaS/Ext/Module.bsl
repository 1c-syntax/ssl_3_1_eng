﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

#Region TextExtraction

// Adds and deletes entries to the text extraction Queue information register when
// the text extraction status of file versions changes.
//
// Parameters:
//  TextSource - DefinedType.AttachedFile -  the file that has changed the text extraction state.
//  TextExtractionState - EnumRef.FileTextExtractionStatuses -  new status.
//
Procedure UpdateTextExtractionQueueState(TextSource, TextExtractionState) Export
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		Return;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.TextExtractionQueue.CreateRecordSet();
	RecordSet.Filter.DataAreaAuxiliaryData.Set(ModuleSaaSOperations.SessionSeparatorValue());
	RecordSet.Filter.TextSource.Set(TextSource);
	
	If TextExtractionState = Enums.FileTextExtractionStatuses.NotExtracted
			Or TextExtractionState = Enums.FileTextExtractionStatuses.EmptyRef() Then
			
		Record = RecordSet.Add();
		Record.DataAreaAuxiliaryData = ModuleSaaSOperations.SessionSeparatorValue();
		Record.TextSource = TextSource;
			
	EndIf;
		
	RecordSet.Write();
	
EndProcedure

#EndRegion

#Region ConfigurationSubsystemsEventHandlers

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert("FilesOperationsInternal.ExtractTextFromFiles");
	NamesAndAliasesMap.Insert("FilesOperationsInternal.ClearExcessiveFiles");
	NamesAndAliasesMap.Insert("FilesOperationsInternal.ScheduledFileSynchronizationWebdav");
	NamesAndAliasesMap.Insert("InformationRegisters.FileRepository.TransferData_");
	
EndProcedure

// See JobsQueueOverridable.OnDefineScheduledJobsUsage.
Procedure OnDefineScheduledJobsUsage(UsageTable) Export
	
	NewRow = UsageTable.Add();
	NewRow.ScheduledJob = "TextExtractionPlanningSaaS";
	
	If Common.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		ModuleFullTextSearchServer = Common.CommonModule("FullTextSearchServer");
		NewRow.Use = ModuleFullTextSearchServer.UseFullTextSearch();
	Else
		NewRow.Use = False;
	EndIf;
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplateList.
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.CleanUpUnusedFiles.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.FilesSynchronization.Name);
	
EndProcedure

// See ODataInterfaceOverridable.OnPopulateDependantTablesForODataImportExport
Procedure OnPopulateDependantTablesForODataImportExport(Tables) Export
	
	DependentTables = FilesCatalogsAndStorageOptionObjects().StorageObjects;
	For Each DependentTable In DependentTables Do
		Tables.Add(DependentTable.Key);
	EndDo;
	
EndProcedure

// 

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	ModuleExportImportData = Common.CommonModule("ExportImportData");
	
	Types.Add(Metadata.InformationRegisters.TextExtractionQueue);
	Types.Add(Metadata.InformationRegisters.DeleteFilesBinaryData);
	Types.Add(Metadata.Constants.VolumePathIgnoreRegionalSettings);
	
	TypesToExclude = FilesCatalogsAndStorageOptionObjects().StorageObjects;
	For Each IsExcludableType In TypesToExclude Do
		ModuleExportImportData.AddTypeExcludedFromUploadingUploads(
			Types,
			Common.MetadataObjectByFullName(IsExcludableType.Key),
			ModuleExportImportData.ActionWithLinksDoNotChange());	
	EndDo;
	
EndProcedure

// See ExportImportDataOverridable.OnRegisterDataExportHandlers.
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	FilesCatalogs = FilesCatalogsAndStorageOptionObjects().FilesCatalogs;
	For Each FilesCatalog In FilesCatalogs Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Common.MetadataObjectByFullName(FilesCatalog.Key);
		NewHandler.Handler = FilesOperationsInternalSaaS;
		NewHandler.BeforeExportObject = True;
		NewHandler.Version = "1.0.0.1";
		
	EndDo;
	
	If HandlersTable.Find(Metadata.Catalogs.Files, "MetadataObject") = Undefined Then
	
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Metadata.Catalogs.Files;
		NewHandler.Handler = FilesOperationsInternalSaaS;
		NewHandler.BeforeExportObject = True;
		NewHandler.Version = "1.0.0.1";
	
	EndIf;
	
EndProcedure

// See ExportImportDataOverridable.OnRegisterDataImportHandlers.
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	FilesCatalogs = FilesCatalogsAndStorageOptionObjects().FilesCatalogs;
	For Each FilesCatalog In FilesCatalogs Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Common.MetadataObjectByFullName(FilesCatalog.Key);
		NewHandler.Handler = FilesOperationsInternalSaaS;
		NewHandler.BeforeImportObject = True;
		NewHandler.Version = "1.0.0.1";
		
	EndDo;
	
EndProcedure

// It is connected to the offload of the unloaded data, which is undetectable.When registering the data handlers, the data loads.
//
// Parameters:
//   Container - DataProcessorObject.ExportImportDataContainerManager
//   ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager
//   Serializer - XDTOSerializer
//   Object - ConstantValueManager
//          - CatalogObject
//          - DocumentObject
//          - BusinessProcessObject
//          - TaskObject
//          - ChartOfAccountsObject
//          - ExchangePlanObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfCalculationTypesObject
//          - InformationRegisterRecordSet
//          - AccumulationRegisterRecordSet
//          - AccountingRegisterRecordSet
//          - CalculationRegisterRecordSet
//          - SequenceRecordSet
//          - RecalculationRecordSet
//   Artifacts - Array of XDTODataObject
//   Cancel - Boolean
//
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	If TypeOf(Object) = Type("CatalogObject.Files") Then
		ClearRefToFilesStorageVolume(Object);
		If Object.StoreVersions Then
			Return;
		EndIf;
	EndIf;
	
	If Object.IsFolder Then
		Return;
	EndIf;
	
	FilesCatalogs = FilesCatalogsAndStorageOptionObjects().FilesCatalogs;
	
	Handler = FilesCatalogs.Get(Object.Metadata().FullName());
	
	If Handler = Undefined Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Handler %2 cannot handle
				|metadata object %1.';",
				Common.DefaultLanguageCode()),
			Object.Metadata().FullName(), "FilesOperationsInternalSaaS.BeforeExportObject()");
		
	EndIf;
	
	HandlerModule = Common.CommonModule(Handler);
	FileExtention = HandlerModule.FileExtention(Object);
	FileName = Container.CreateCustomFile(FileExtention);
	
	Try
		
		HandlerModule.ExportFile(Object, FileName);
		
		Artifact = XDTOFactory.Create(FileArtifactType());
		Artifact.RelativeFilePath = Container.GetRelativeFileName(FileName);
		Artifacts.Add(Artifact);
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		If Common.SubsystemExists("CloudTechnology.Core") Then
		
			ModuleSaaSTechnology = Common.CommonModule("CloudTechnology");
			If CommonClientServer.CompareVersions(ModuleSaaSTechnology.LibraryVersion(), "2.0.2.15") >= 0 Then
				Warning = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Export of file %1 (type %2) is skipped due to 
					|%3';"),
					Object,
					Object.Metadata().FullName(),
					ErrorProcessing.BriefErrorDescription(ErrorInfo));
				
				Container.AddWarning(Warning);
			EndIf;
			
		EndIf;
		
		WriteLogEvent(
			NStr("en = 'Files.Export data for cloud migration';", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Object.Metadata(),
			Object.Ref,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
			
		Container.ExcludeFile(FileName);
		
	EndTry;
	
	ClearRefToFilesStorageVolume(Object);
	
EndProcedure

// It is connected to the offload of the unloaded data, which is undetectable.When registering the processing of the data upload.
//
// Parameters:
//   Container - DataProcessorObject.ExportImportDataContainerManager
//   Object - ConstantValueManager
//          - CatalogObject
//          - DocumentObject
//          - BusinessProcessObject
//          - TaskObject
//          - ChartOfAccountsObject
//          - ExchangePlanObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfCalculationTypesObject
//          - InformationRegisterRecordSet
//          - AccumulationRegisterRecordSet
//          - AccountingRegisterRecordSet
//          - CalculationRegisterRecordSet
//          - SequenceRecordSet
//          - RecalculationRecordSet
//   Artifacts - Array of XDTODataObject
//   Cancel - Boolean
//
Procedure BeforeImportObject(Container, Object, Artifacts, Cancel) Export
	
	FilesCatalogs = FilesCatalogsAndStorageOptionObjects().FilesCatalogs;
	
	Handler = FilesCatalogs.Get(Object.Metadata().FullName());
	
	If Handler = Undefined Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Handler %2 cannot handle
				|metadata object %1.';", Common.DefaultLanguageCode()),
			Object.Metadata().FullName(), "FilesOperationsInternalSaaS.BeforeExportObject()");
		
	EndIf;
	
	HandlerModule = Common.CommonModule(Handler);
	
	For Each Artifact In Artifacts Do
		
		If Artifact.Type() = FileArtifactType() Then
			
			HandlerModule.ImportFile_(Object, Container.GetFullFileName(Artifact.RelativeFilePath));
			
		EndIf;
		
	EndDo;
	
EndProcedure

// End CloudTechnology.ExportImportData

// 
// 
//
Procedure StartDeduplication() Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		
		Return;
		
	EndIf;
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	
	Query = New Query( 
	"SELECT
	|	DataAreas.DataAreaAuxiliaryData AS DataArea
	|FROM
	|	InformationRegister.DataAreas AS DataAreas
	|WHERE
	|	DataAreas.Status = VALUE(Enum.DataAreaStatuses.Used)");
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		JobParameters = New Structure;
		JobParameters.Insert("DataArea", Selection.DataArea);
		JobParameters.Insert("MethodName", "InformationRegisters.FileRepository.TransferData_");
		
		If ModuleJobsQueue.GetJobs(JobParameters).Count() = 0 Then
			
			JobParameters.Insert("Use", True);
			JobParameters.Insert("RestartCountOnFailure", 3);
			ModuleJobsQueue.AddJob(JobParameters);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// 

#Region InfobaseUpdate

// Fills the text extraction queue for the current data area. Used for initial filling when
// updating.
//
Procedure FillTextExtractionQueue() Export
	
	IsSeparatedConfiguration = False;
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		IsSeparatedConfiguration = ModuleSaaSOperations.IsSeparatedConfiguration();
	EndIf;
	
	If Not IsSeparatedConfiguration Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = FilesOperationsInternal.QueryTextToExtractText(True);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		UpdateTextExtractionQueueState(Selection.Ref,
			Enums.FileTextExtractionStatuses.NotExtracted);
	EndDo;
	
EndProcedure

#EndRegion

// 

#Region TextExtraction

// Defines a list of data areas where text extraction is required and schedules
// it for them using the task queue.
//
Procedure HandleTextExtractionQueue() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.TextExtractionPlanningSaaS);
	
	If Not Common.DataSeparationEnabled()
		Or Not Common.IsWindowsServer() Then
		Return;
	EndIf;
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	
	SeparatedMethodName = "FilesOperationsInternal.ExtractTextFromFiles";
	
	QueryText = 
	"SELECT DISTINCT
	|	TextExtractionQueue.DataAreaAuxiliaryData AS DataArea,
	|	CASE
	|		WHEN TimeZones.Value = """"
	|			THEN UNDEFINED
	|		ELSE ISNULL(TimeZones.Value, UNDEFINED)
	|	END AS TimeZone
	|FROM
	|	InformationRegister.TextExtractionQueue AS TextExtractionQueue
	|		LEFT JOIN Constant.DataAreaTimeZone AS TimeZones
	|		ON TextExtractionQueue.DataAreaAuxiliaryData = TimeZones.DataAreaAuxiliaryData
	|		LEFT JOIN InformationRegister.DataAreas AS DataAreas
	|		ON TextExtractionQueue.DataAreaAuxiliaryData = DataAreas.DataAreaAuxiliaryData
	|WHERE
	|	NOT TextExtractionQueue.DataAreaAuxiliaryData IN (&DataAreasToProcess)
	|	AND DataAreas.Status = VALUE(Enum.DataAreaStatuses.Used)";
	Query = New Query(QueryText);
	Query.SetParameter("DataAreasToProcess", ModuleJobsQueue.GetJobs(
		New Structure("MethodName", SeparatedMethodName)));
		
	If TransactionActive() Then
		Raise(NStr("en = 'The transaction is active. Cannot execute a query in the transaction.';"));
	EndIf;
	
	AttemptsNumber = 0;
	
	Result = Undefined;
	While True Do
		Try
			Result = Query.Execute(); // 
			                                // 
			                                // 
			Break;
		Except
			AttemptsNumber = AttemptsNumber + 1;
			If AttemptsNumber = 5 Then
				Raise;
			EndIf;
		EndTry;
	EndDo;
		
	Selection = Result.Select();
	While Selection.Next() Do
		// 
		If ModuleSaaSOperations.DataAreaLocked(Selection.DataArea) Then
			// 
			Continue;
		EndIf;
		
		NewJob = New Structure();
		NewJob.Insert("DataArea", Selection.DataArea);
		NewJob.Insert("ScheduledStartTime", ToLocalTime(CurrentUniversalDate(), Selection.TimeZone));
		NewJob.Insert("MethodName", SeparatedMethodName);
		ModuleJobsQueue.AddJob(NewJob);
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Function FileArtifactType()
	
	Return XDTOFactory.Type(Package(), "FileArtefact");
	
EndFunction

Function Package()
	
	Return "http://www.1c.ru/1cFresh/Data/Artefacts/Files/1.0.0.1";
	
EndFunction

Function FilesCatalogsAndStorageOptionObjects()
	
	Return FilesOperationsInternalSaaSCached.FilesCatalogsAndStorageOptionObjects();
	
EndFunction

Procedure ClearRefToFilesStorageVolume(Object)
	
	For Each ObjectAttribute In Object.Metadata().Attributes Do
		If ObjectAttribute.Type.ContainsType(Type("CatalogRef.FileStorageVolumes")) 
			And ValueIsFilled(Object[ObjectAttribute.Name]) Then
			Object[ObjectAttribute.Name] = Undefined;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
