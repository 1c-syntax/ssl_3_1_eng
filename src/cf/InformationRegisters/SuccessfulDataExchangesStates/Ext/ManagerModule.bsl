///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// The procedure adds an entry to the register based on the passed structure values.
Procedure AddRecord(RecordStructure) Export
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		DataExchangeInternal.AddRecordToInformationRegister(RecordStructure, "DataAreasSuccessfulDataExchangeStates");
	Else
		DataExchangeInternal.AddRecordToInformationRegister(RecordStructure, "SuccessfulDataExchangesStates");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf