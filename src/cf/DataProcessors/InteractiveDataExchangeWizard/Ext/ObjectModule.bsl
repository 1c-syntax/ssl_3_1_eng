///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 

// Retrieves statistics of matching objects to table rows Informatizaciyi.
//
// Parameters:
//      Cancel        - Boolean -  failure flag; raised if errors occur during the procedure.
//      RowIndexes - Array -  indexes of rows in the Informationstatistics table
//                              for which you need to get information about mapping statistics.
//                              If omitted, the operation will be performed for all rows in the table.
// 
Procedure GetObjectMappingByRowStats(Cancel, RowIndexes = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If RowIndexes = Undefined Then
		
		RowIndexes = New Array;
		
		For Each TableRow In StatisticsInformation Do
			
			RowIndexes.Add(StatisticsInformation.IndexOf(TableRow));
			
		EndDo;
		
	EndIf;
	
	// 
	ExecuteDataImportFromExchangeMessagesIntoCache(Cancel, RowIndexes);
	
	If Cancel Then
		Return;
	EndIf;
	
	InfobasesObjectsMapping = DataProcessors.InfobasesObjectsMapping.Create();
	
	// 
	For Each RowIndex In RowIndexes Do
		
		TableRow = StatisticsInformation[RowIndex];
		
		If Not TableRow.SynchronizeByID Then
			Continue;
		EndIf;
		
		// 
		InfobasesObjectsMapping.DestinationTableName            = TableRow.DestinationTableName;
		InfobasesObjectsMapping.SourceTableObjectTypeName = TableRow.ObjectTypeString;
		InfobasesObjectsMapping.InfobaseNode         = InfobaseNode;
		InfobasesObjectsMapping.ExchangeMessageFileName        = ExchangeMessageFileName;
		
		InfobasesObjectsMapping.SourceTypeString = TableRow.SourceTypeString;
		InfobasesObjectsMapping.DestinationTypeString = TableRow.DestinationTypeString;
		
		// Designer
		InfobasesObjectsMapping.Designer();
		
		// 
		InfobasesObjectsMapping.GetObjectMappingDigestInfo(Cancel);
		
		// 
		TableRow.ObjectCountInSource       = InfobasesObjectsMapping.ObjectCountInSource();
		TableRow.ObjectCountInDestination       = InfobasesObjectsMapping.ObjectCountInDestination();
		TableRow.MappedObjectCount   = InfobasesObjectsMapping.MappedObjectCount();
		TableRow.UnmappedObjectsCount = InfobasesObjectsMapping.UnmappedObjectsCount();
		TableRow.MappedObjectPercentage       = InfobasesObjectsMapping.MappedObjectPercentage();
		TableRow.PictureIndex                     = DataExchangeServer.StatisticsTablePictureIndex(TableRow.UnmappedObjectsCount, TableRow.DataImportedSuccessfully);
		TableRow.IsMasterData                             = IsMasterDataTypeName(TableRow.DestinationTypeString);

	EndDo;
	
EndProcedure

// Performs automatic mapping of information database objects
//  to the default values and gets statistics for object mapping
//  after automatic mapping.
//
// Parameters:
//      Cancel        - Boolean -  failure flag; raised if errors occur during the procedure.
//      RowIndexes - Array -  indexes of rows in the statistics Informationstatistics table
//                              for which you need to perform automatic matching and get
//                              statistics information.
//                              If omitted, the operation will be performed for all rows in the table.
// 
Procedure ExecuteDefaultAutomaticMappingAndGetMappingStatistics(Cancel, RowIndexes = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If RowIndexes = Undefined Then
		
		RowIndexes = New Array;
		
		For Each TableRow In StatisticsInformation Do
			
			RowIndexes.Add(StatisticsInformation.IndexOf(TableRow));
			
		EndDo;
		
	EndIf;
	
	// 
	ExecuteDataImportFromExchangeMessagesIntoCache(Cancel, RowIndexes);
	
	If Cancel Then
		Return;
	EndIf;
	
	InfobasesObjectsMapping = DataProcessors.InfobasesObjectsMapping.Create();
	
	// 
	// 
	For Each RowIndex In RowIndexes Do
		
		TableRow = StatisticsInformation[RowIndex];
		
		If Not TableRow.SynchronizeByID Then
			Continue;
		EndIf;
		
		// 
		InfobasesObjectsMapping.DestinationTableName            = TableRow.DestinationTableName;
		InfobasesObjectsMapping.SourceTableObjectTypeName = TableRow.ObjectTypeString;
		InfobasesObjectsMapping.DestinationTableFields           = TableRow.TableFields;
		InfobasesObjectsMapping.DestinationTableSearchFields     = TableRow.SearchFields;
		InfobasesObjectsMapping.InfobaseNode         = InfobaseNode;
		InfobasesObjectsMapping.ExchangeMessageFileName        = ExchangeMessageFileName;
		
		InfobasesObjectsMapping.SourceTypeString = TableRow.SourceTypeString;
		InfobasesObjectsMapping.DestinationTypeString = TableRow.DestinationTypeString;
		
		// Designer
		InfobasesObjectsMapping.Designer();
		
		// 
		InfobasesObjectsMapping.ExecuteDefaultAutomaticMapping(Cancel);
		
		// 
		InfobasesObjectsMapping.GetObjectMappingDigestInfo(Cancel);
		
		// 
		TableRow.ObjectCountInSource       = InfobasesObjectsMapping.ObjectCountInSource();
		TableRow.ObjectCountInDestination       = InfobasesObjectsMapping.ObjectCountInDestination();
		TableRow.MappedObjectCount   = InfobasesObjectsMapping.MappedObjectCount();
		TableRow.UnmappedObjectsCount = InfobasesObjectsMapping.UnmappedObjectsCount();
		TableRow.MappedObjectPercentage       = InfobasesObjectsMapping.MappedObjectPercentage();
		TableRow.PictureIndex                     = DataExchangeServer.StatisticsTablePictureIndex(TableRow.UnmappedObjectsCount, TableRow.DataImportedSuccessfully);
		TableRow.IsMasterData                             = IsMasterDataTypeName(TableRow.DestinationTypeString);
	EndDo;
	
EndProcedure

// Loads data to the information database for rows in the statistics Informationtable.
//  If all the data of the exchange message is loaded
//  , the number of the incoming message will be written to the exchange node.
//  This means that these messages are fully loaded into the information database.
//  Reloading this message will be canceled.
//
// Parameters:
//       Cancel        - Boolean -  failure flag; raised if errors occur during the procedure.
//       RowIndexes - Array -  indexes of rows in the Informationstatistics table
//                               for which you need to load data.
//                               If omitted, the operation will be performed for all rows in the table.
// 
Procedure RunDataImport(Cancel, RowIndexes = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If RowIndexes = Undefined Then
		
		RowIndexes = New Array;
		
		For Each TableRow In StatisticsInformation Do
			
			RowIndexes.Add(StatisticsInformation.IndexOf(TableRow));
			
		EndDo;
		
	EndIf;
	
	TablesToImport = New Array;
	
	For Each RowIndex In RowIndexes Do
		
		TableRow = StatisticsInformation[RowIndex];
		
		DataTableKey = DataExchangeServer.DataTableKey(TableRow.SourceTypeString, TableRow.DestinationTypeString, TableRow.IsObjectDeletion);
		
		TablesToImport.Add(DataTableKey);
		
	EndDo;
	
	// 
	InfobasesObjectsMapping = DataProcessors.InfobasesObjectsMapping.Create();
	InfobasesObjectsMapping.ExchangeMessageFileName = ExchangeMessageFileName;
	InfobasesObjectsMapping.InfobaseNode  = InfobaseNode;
	
	// 
	InfobasesObjectsMapping.ExecuteDataImportForInfobase(Cancel, TablesToImport);
	
	DataImportedSuccessfully = Not Cancel;
	
	For Each RowIndex In RowIndexes Do
		
		TableRow = StatisticsInformation[RowIndex];
		
		TableRow.DataImportedSuccessfully = DataImportedSuccessfully;
		TableRow.PictureIndex = DataExchangeServer.StatisticsTablePictureIndex(TableRow.UnmappedObjectsCount, TableRow.DataImportedSuccessfully);
	
	EndDo;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// 

// Loads data (tables) from the exchange message to the cache.
// Only tables that have not been loaded before are loaded.
// The variable data Processing contains (caches) previously loaded tables.
//
// Parameters:
//       Cancel        - Boolean -  failure flag; raised if errors occur during the procedure.
//       RowIndexes - Array -  indexes of rows in the Informationstatistics table
//                               for which you need to load data.
//                               If omitted, the operation will be performed for all rows in the table.
// 
Procedure ExecuteDataImportFromExchangeMessagesIntoCache(Cancel, RowIndexes)
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsStructureForInteractiveImportSession(InfobaseNode, ExchangeMessageFileName);
	
	If ExchangeSettingsStructure.Cancel Then
		Return;
	EndIf;
	ExchangeSettingsStructure.StartDate = CurrentSessionDate();
	DataExchangeDataProcessor = ExchangeSettingsStructure.DataExchangeDataProcessor;
	
	// 
	TablesToImport = New Array;
	
	For Each RowIndex In RowIndexes Do
		
		TableRow = StatisticsInformation[RowIndex];
		
		If Not TableRow.SynchronizeByID Then
			Continue;
		EndIf;
		
		DataTableKey = DataExchangeServer.DataTableKey(TableRow.SourceTypeString, TableRow.DestinationTypeString, TableRow.IsObjectDeletion);
		
		// 
		DataTable = DataExchangeDataProcessor.DataTablesExchangeMessages().Get(DataTableKey);
		
		If DataTable = Undefined Then
			
			TablesToImport.Add(DataTableKey);
			
		EndIf;
		
	EndDo;
	
	// 
	If TablesToImport.Count() > 0 Then
		
		DataExchangeDataProcessor.ExecuteDataImportIntoValueTable(TablesToImport);
		
		If DataExchangeDataProcessor.FlagErrors() Then
			Cancel = True;
			NString = NStr("en = 'Errors occurred while importing the exchange message: %1';");
			NString = StringFunctionsClientServer.SubstituteParametersToString(NString, DataExchangeDataProcessor.ErrorMessageString());
			DataExchangeServer.WriteExchangeFinishWithError(ExchangeSettingsStructure.InfobaseNode,
												ExchangeSettingsStructure.ActionOnExchange, 
												ExchangeSettingsStructure.StartDate,
												NString);
			Return;
		EndIf;
		
	EndIf;
	
EndProcedure

Function IsMasterDataTypeName(DestinationTypeString)
	If Documents.AllRefsType().ContainsType(Type(DestinationTypeString)) Then
		Return False;
	EndIf;
	Return True;
EndFunction
////////////////////////////////////////////////////////////////////////////////
// 

// Data table part Informatizaciyi.
//
// Returns:
//  ValueTable - 
//
Function StatisticsTable() Export
	
	Return StatisticsInformation.Unload();
	
EndFunction

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf