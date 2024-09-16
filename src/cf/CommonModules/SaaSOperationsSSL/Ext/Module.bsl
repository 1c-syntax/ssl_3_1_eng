///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Handler for subscribing to the event of controldistributed record Objects.
//
// Parameters:
//   Source - AnyRef -  event source.
//   Cancel    - Boolean -  indicates that the recording was rejected.
//
Procedure CheckSharedObjectsOnWrite(Source, Cancel) Export
	
	// 
	// 
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleSaaSOperations.CheckSharedObjectsOnWrite(Source, Cancel);
	
EndProcedure

// Handler for subscribing to the event controlselected Recordsetsrecords.
//
// Parameters:
//   Source  - InformationRegisterRecordSet -  event source.
//   Cancel     - Boolean -  indicates that the set is not being written to the database.
//   Replacing - Boolean -  recording mode is set. True-the record is performed by replacing
//             the existing set records in the database. False-recording is performed with
//             "appending" the current set of records.
//
Procedure CheckSharedRecordsSetsOnWrite(Source, Cancel, Replacing) Export
	
	// 
	// 
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleSaaSOperations.CheckSharedRecordsSetsOnWrite(Source, Cancel, Replacing);
	
EndProcedure

#EndRegion

#Region Internal

// 
// 
//
// Returns:
//  Boolean
//
Function StandardSeparatorsOnly() Export
	
	Result = True;
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute = Metadata.CommonAttributes.DataAreaMainData
		 Or CommonAttribute = Metadata.CommonAttributes.DataAreaAuxiliaryData
		 Or CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.DontUse Then
			Continue;
		EndIf;
		Result = False;
		Break;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion
