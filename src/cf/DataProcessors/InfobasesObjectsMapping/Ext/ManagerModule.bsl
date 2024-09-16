///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// For internal use.
//
Procedure MapObjects(Parameters, TempStorageAddress) Export
	
	PutToTempStorage(ObjectMappingResult(Parameters), TempStorageAddress);
	
EndProcedure

// For internal use.
//
Procedure ExecuteAutomaticObjectMapping(Parameters, TempStorageAddress) Export
	
	PutToTempStorage(AutomaticObjectMappingResult(Parameters), TempStorageAddress);
	
EndProcedure

#EndRegion

#Region Private
// For internal use.
//
Function ObjectMappingResult(Parameters)
	
	ObjectsMapping = Create();
	DataExchangeServer.ImportObjectContext(Parameters.ObjectContext, ObjectsMapping);
	
	Cancel = False;
	
	// 
	If Parameters.FormAttributes.ApplyOnlyUnapprovedRecordsTable Then
		
		ObjectsMapping.ApplyUnapprovedRecordsTable(Cancel);
		
		If Cancel Then
			Raise NStr("en = 'Errors occurred during object mapping.';");
		EndIf;
		
		Return Undefined;
	EndIf;
	
	// 
	If Parameters.FormAttributes.ApplyAutomaticMappingResult Then
		
		// 
		For Each TableRow In Parameters.AutomaticallyMappedObjectsTable Do
			
			FillPropertyValues(ObjectsMapping.UnapprovedMappingTable.Add(), TableRow);
			
		EndDo;
		
	EndIf;
	
	// 
	If Parameters.FormAttributes.ApplyUnapprovedRecordsTable Then
		
		ObjectsMapping.ApplyUnapprovedRecordsTable(Cancel);
		
		If Cancel Then
			Raise NStr("en = 'Errors occurred during object mapping.';");
		EndIf;
		
	EndIf;
	
	// 
	ObjectsMapping.MapObjects(Cancel);
	
	If Cancel Then
		Raise NStr("en = 'Errors occurred during object mapping.';");
	EndIf;
	
	Result = New Structure;
	Result.Insert("ObjectCountInSource",       ObjectsMapping.ObjectCountInSource());
	Result.Insert("ObjectCountInDestination",       ObjectsMapping.ObjectCountInDestination());
	Result.Insert("MappedObjectCount",   ObjectsMapping.MappedObjectCount());
	Result.Insert("UnmappedObjectsCount", ObjectsMapping.UnmappedObjectsCount());
	Result.Insert("MappedObjectPercentage",       ObjectsMapping.MappedObjectPercentage());
	Result.Insert("MappingTable",               ObjectsMapping.MappingTable());
	
	Result.Insert("ObjectContext", DataExchangeServer.GetObjectContext(ObjectsMapping));
	
	Return Result;
EndFunction

// For internal use.
//
Function AutomaticObjectMappingResult(Parameters)
	
	ObjectsMapping = Create();
	DataExchangeServer.ImportObjectContext(Parameters.ObjectContext, ObjectsMapping);
	
	// 
	ObjectsMapping.UsedFieldsList.Clear();
	CommonClientServer.SupplementTable(Parameters.FormAttributes.UsedFieldsList, ObjectsMapping.UsedFieldsList);
	
	// 
	ObjectsMapping.TableFieldsList.Clear();
	CommonClientServer.SupplementTable(Parameters.FormAttributes.TableFieldsList, ObjectsMapping.TableFieldsList);
	
	// 
	ObjectsMapping.UnapprovedMappingTable.Load(Parameters.UnapprovedMappingTable);
	
	Cancel = False;
	
	// 
	ObjectsMapping.ExecuteAutomaticObjectMapping(Cancel, Parameters.FormAttributes.MappingFieldsList);
	
	If Cancel Then
		Raise NStr("en = 'Errors occurred during automatic object mapping.';");
	EndIf;
	
	Result = New Structure;
	Result.Insert("EmptyResult", ObjectsMapping.AutomaticallyMappedObjectsTable.Count() = 0);
	Result.Insert("ObjectContext", DataExchangeServer.GetObjectContext(ObjectsMapping));
	
	Return Result;
EndFunction

#EndRegion

#EndIf
