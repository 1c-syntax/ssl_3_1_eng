﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Variables

Var VerificationRequired;
Var DataToWrite;
Var PreparedData1;

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	// 
	// 
	// 
	//
	// 
	// 
	
	If PreparedData1 Then
		Load(DataToWrite);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// 
	// 
	// 
	//
	// 
	// 
	
	If VerificationRequired Then
		
		For Each Record In ThisObject Do
			
			VerificationRows = DataToWrite.FindRows(
				New Structure("Id, DataType", Record.Id, Record.DataType));
			
			If VerificationRows.Count() <> 1 Then
				ThrowControlException();
			EndIf;
				
			VerificationRow = VerificationRows.Get(0);
			
			CurrentData = Common.ValueToXMLString(Record.Data.Get());
			VerificationData = Common.ValueToXMLString(VerificationRow.Data.Get());
			
			If CurrentData <> VerificationData Then
				ThrowControlException();
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure PrepareDataToRecord() Export
	
	ReceivingParameters = Undefined;
	If Not AdditionalProperties.Property("ReceivingParameters", ReceivingParameters) Then
		Raise NStr("en = 'The data getting parameters are not defined.';");
	EndIf;
	
	DataToWrite = Unload();
	
	For Each String In DataToWrite Do
		
		Data = InformationRegisters.ProgramInterfaceCache.PrepareVersionCacheData(String.DataType, ReceivingParameters);
		String.Data = New ValueStorage(Data);
		
	EndDo;
	
	PreparedData1 = True;
	
EndProcedure

Procedure ThrowControlException()
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'The %1 resource of the %2 information register record cannot be changed
			|inside the record transaction from the session with separation enabled.';"),
		"Data", "ProgramInterfaceCache");
	
EndProcedure

#EndRegion

#Region Initialize

DataToWrite = New ValueTable();
VerificationRequired = Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable();
PreparedData1 = False;

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf