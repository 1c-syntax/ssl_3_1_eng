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

Procedure PrepareChangesForLogging(Object, Replacing, OldRecords)
	
	If Object.AdditionalProperties.Property("IsStandardRegisterUpdate") Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.UserGroupCompositions.CreateRecordSet();
	
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

Procedure DoLogChanges(Object, Replacing, OldRecords)
	
	If Object.AdditionalProperties.Property("IsStandardRegisterUpdate") Then
		Return;
	EndIf;
	
	Table = Unload();
	Table.Columns.Add("ChangeType", New TypeDescription("String"));
	Table.FillValues("Added2", "ChangeType");
	RowFilter = New Structure("UsersGroup, User");
	
	If ValueIsFilled(OldRecords) Then
		IndexOf = Table.Count();
		While IndexOf > 0 Do
			IndexOf = IndexOf - 1;
			NewRecord = Table.Get(IndexOf);
			FillPropertyValues(RowFilter, NewRecord);
			FoundRows = OldRecords.FindRows(RowFilter);
			OldRecord = ?(FoundRows.Count() = 0, Undefined, FoundRows[0]);
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
	
	UsersInternal.RegisterGroupsCompositionChanges(Table);
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf