///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure AddRecord(RecordStructure) Export
	
	DataExchangeInternal.AddRecordToInformationRegister(RecordStructure, "DataExchangeMessages");
	
EndProcedure

Procedure DeleteRecord(RecordStructure) Export
	
	DataExchangeInternal.DeleteRecordSetFromInformationRegister(RecordStructure, "DataExchangeMessages");
	
EndProcedure

#EndRegion

#EndIf