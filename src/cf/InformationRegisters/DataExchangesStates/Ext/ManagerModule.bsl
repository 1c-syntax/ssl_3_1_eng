///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// The procedure adds an entry to the register based on the passed structure values.
Procedure AddRecord(RecordStructure) Export
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		DataExchangeInternal.AddRecordToInformationRegister(RecordStructure, "DataAreaDataExchangeStates");
	Else
		DataExchangeInternal.AddRecordToInformationRegister(RecordStructure, "DataExchangesStates");
	EndIf;
	
EndProcedure

Procedure UpdateRecord(RecordStructure) Export
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "DataAreaDataExchangeStates");
	Else
		DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "DataExchangesStates");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf