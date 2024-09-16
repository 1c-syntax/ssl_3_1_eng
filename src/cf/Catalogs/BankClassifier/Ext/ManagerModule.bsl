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
	Result.Add("*");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// 

// Returns the directory details that form the natural key
// for the directory elements.
//
// Returns:
//  Array - 
//
Function NaturalKeyFields() Export
	
	Result = New Array();
	
	Result.Add("Code");
	Result.Add("CorrAccount");
	
	Return Result;
	
EndFunction

// End CloudTechnology.ExportImportData

#EndRegion

#EndRegion

#EndIf
