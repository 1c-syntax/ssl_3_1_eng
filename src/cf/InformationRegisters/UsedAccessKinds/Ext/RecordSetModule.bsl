///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var OldRecords; // 

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	// 
	If UsersInternalCached.ShouldRegisterChangesInAccessRights() Then
		PrepareChangesForLogging(ThisObject, Replacing, OldRecords);
	EndIf;
	// 
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// 
	If UsersInternalCached.ShouldRegisterChangesInAccessRights() Then
		DoLogChanges(ThisObject, Replacing, OldRecords);
	EndIf;
	// 
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure PrepareChangesForLogging(Var_ThisObject, Replacing, OldRecords)
	
	RecordSet = InformationRegisters.UsedAccessKinds.CreateRecordSet();
	
	If Replacing Then
		For Each FilterElement In Filter Do
			If FilterElement.Use Then
				RecordSet.Filter[FilterElement.Name].Set(FilterElement.Value);
			EndIf;
		EndDo;
		RecordSet.Read();
	EndIf;
	
	OldRecords = RecordSet.Unload();
	
EndProcedure

Procedure DoLogChanges(RecordSet, Replacing, OldRecords)
	
	Table = Unload();
	Table.Columns.Add("ChangeType", New TypeDescription("String"));
	Table.FillValues("Added2", "ChangeType");
	
	If ValueIsFilled(OldRecords) Then
		IndexOf = Table.Count();
		While IndexOf > 0 Do
			IndexOf = IndexOf - 1;
			NewRecord = Table.Get(IndexOf);
			OldRecord = OldRecords.Find(NewRecord.AccessValuesType, "AccessValuesType");
			If OldRecord = Undefined Then
				Continue;
			EndIf;
			If NewRecord.Used = OldRecord.Used Then
				Table.Delete(NewRecord);
			Else
				NewRecord.ChangeType = "IsChanged";
			EndIf;
			OldRecords.Delete(OldRecord);
		EndDo;
		For Each OldRecord In OldRecords Do
			NewRow = Table.Add();
			FillPropertyValues(NewRow, OldRecord);
			NewRow.ChangeType = "Deleted";
		EndDo;
	EndIf;
	
	If Table.Count() = 0 Then
		Return;
	EndIf;
	
	Table.Columns.AccessValuesType.Name = "AccessKind";
	ObjectDetails = New Structure("AccessKindsChange", Table);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Catalogs.AccessGroups.RegisterChangeInAllowedValues(ObjectDetails, Undefined);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf