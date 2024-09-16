///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// The procedure updates the register data when the use of access types changes.
//
// Parameters:
//  HasChanges - Boolean -  (return value) - if a record was made,
//                  it is set to True, otherwise it is not changed.
//
//  WithoutUpdatingDependentData - Boolean -  if True, then
//                  do not call the procedure for changing the use of the Access view and
//                  do not plan to update the access restriction parameters.
//
Procedure UpdateRegisterData(HasChanges = Undefined, WithoutUpdatingDependentData = False) Export
	
	InformationRegisters.ExtensionVersionParameters.LockForChangeInFileIB();
	AccessKindsProperties = AccessManagementInternal.AccessKindsProperties();
	
	RecordSet = CreateRecordSet();
	
	For Each AccessKindProperties In AccessKindsProperties.Array Do
		
		If AccessKindProperties.Name = "ExternalUsers"
		 Or AccessKindProperties.Name = "Users" Then
			// 
			Used = True;
		Else
			Used = True;
			SSLSubsystemsIntegration.OnFillAccessKindUsage(AccessKindProperties.Name, Used);
			AccessManagementOverridable.OnFillAccessKindUsage(AccessKindProperties.Name, Used);
		EndIf;
		
		NewRecord = RecordSet.Add();
		NewRecord.AccessValuesType = AccessKindProperties.Ref;
		NewRecord.Used = Used;
		
		If NewRecord.AccessValuesType <> AccessKindProperties.Ref Then
			RecordSet.Delete(NewRecord);
		EndIf;
	EndDo;
	
	If Not HasChangesInAccessKindsUsage(RecordSet) Then
		Return;
	EndIf;
	
	Block = New DataLock;
	Block.Add("InformationRegister.UsedAccessKinds");
	
	BeginTransaction();
	Try
		Block.Lock();
		
		If HasChangesInAccessKindsUsage(RecordSet) Then
			RecordSet.Write();
			HasChanges = True;
			If Not WithoutUpdatingDependentData Then
				WhenChangingTheUseOfAccessTypes(True);
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Parameters:
//  RecordSet - InformationRegisterRecordSet.UsedAccessKinds
//
// Returns:
//  Boolean
//
Function HasChangesInAccessKindsUsage(RecordSet)
	
	PreviousValues1 = CreateRecordSet();
	If RecordSet.Filter.AccessValuesType.Use Then
		PreviousValues1.Filter.AccessValuesType.Set(RecordSet.Filter.AccessValuesType.Value);
	EndIf;
	
	PreviousValues1.Read();
	
	Table = PreviousValues1.Unload();
	Table.Columns.Add("LineChangeType", New TypeDescription("Number"));
	Table.FillValues(-1, "LineChangeType");
	
	For Each Record In RecordSet Do
		NewRow = Table.Add();
		NewRow.LineChangeType = 1;
		NewRow.AccessValuesType = Record.AccessValuesType;
		NewRow.Used       = Record.Used;
	EndDo;
	Table.GroupBy("AccessValuesType,Used", "LineChangeType");
	
	HasChanges = False;
	For Each String In Table Do
		If String.LineChangeType = 0 Then
			Continue;
		EndIf;
		HasChanges = True;
		Break;
	EndDo;
	
	Return HasChanges;
	
EndFunction

// Parameters:
//  DataElement - InformationRegisterRecordSet.UsedAccessKinds
//
Procedure RegisterChangeUponDataImport(DataElement) Export
	
	If Not HasChangesInAccessKindsUsage(DataElement) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	UsersInternal.RegisterRefs("UsedAccessKinds", Undefined);
	
EndProcedure

// For internal use only.
Procedure ProcessChangeRegisteredUponDataImport() Export
	
	If Common.DataSeparationEnabled() Then
		// 
		Return;
	EndIf;
	
	Changes = UsersInternal.RegisteredRefs("UsedAccessKinds");
	If Changes.Count() = 0 Then
		Return;
	EndIf;
	
	WhenChangingTheUseOfAccessTypes(Changes.Count() = 1 And Changes[0] <> Undefined);
	
	UsersInternal.RegisterRefs("UsedAccessKinds", Null);
	
EndProcedure

Procedure ScheduleUpdateOnChangeAccessKindsUsage() Export
	UsersInternal.RegisterRefs("UsedAccessKinds", Undefined);
EndProcedure

// For procedures, update the register data, process the change of the registered reload.
Procedure WhenChangingTheUseOfAccessTypes(PlanToUpdateAccessRestrictionSettings = False) Export
	
	InformationRegisters.AccessGroupsValues.UpdateRegisterData();
	InformationRegisters.UsedAccessKindsByTables.UpdateRegisterData();
	
	If PlanToUpdateAccessRestrictionSettings Then
		AccessManagementInternal.ScheduleAccessRestrictionParametersUpdate(
			"WhenChangingTheUseOfAccessTypes");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
