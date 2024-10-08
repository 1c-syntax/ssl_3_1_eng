﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure AddRecord(RecordStructure) Export
	
	DataExchangeInternal.AddRecordToInformationRegister(RecordStructure, "DataAreasDataExchangeMessages");
	
EndProcedure

Procedure DeleteRecord(RecordStructure) Export
	
	Record = InformationRegisters.DataAreasDataExchangeMessages.CreateRecordManager();
	FillPropertyValues(Record, RecordStructure);
	Record.Delete();
	
EndProcedure

#EndRegion

#EndIf