///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var OldRecords; // Filled "BeforeWrite" to use "OnWrite".

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	// ACC:75-off - "DataExchange.Import" check must follow the change records in the Event log.
	PrepareChangesForLogging(ThisObject, Replacing, OldRecords);
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// ACC:75-off - "DataExchange.Import" check must follow the change records in the Event log.
	DoLogChanges(ThisObject, Replacing, OldRecords);
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure PrepareChangesForLogging(Var_ThisObject, Replacing, OldRecords)
	
	RecordSet = InformationRegisters.UsersInfo.CreateRecordSet();
	
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
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	FieldList = "User,
		|UserMustChangePasswordOnAuthorization,
		|UnlimitedValidityPeriod,
		|ValidityPeriod,
		|InactivityPeriodBeforeDenyingAuthorization";
	
	NewRecords = Unload();
	Table = NewRecords.Copy(, FieldList);
	Table.Columns.Add("LineChangeType", New TypeDescription("Number"));
	Table.FillValues(1, "LineChangeType");
	
	For Each NewRecord In Table Do
		If OldRecords.Find(NewRecord.User, "User") = Undefined Then
			OldRecords.Add().User = NewRecord.User;
		EndIf;
	EndDo;
	
	For Each OldRecord In OldRecords Do
		NewRow = Table.Add();
		FillPropertyValues(NewRow, OldRecord);
		NewRow.LineChangeType = -1;
	EndDo;
	
	If RecordSet.AdditionalProperties.Property("UserProperties")
	   And TypeOf(RecordSet.AdditionalProperties.UserProperties) = Type("Structure") Then
		
		UserProperties = RecordSet.AdditionalProperties.UserProperties;
	Else
		UserProperties = New Structure;
	EndIf;
	
	Table.GroupBy(FieldList, "LineChangeType");
	UnchangedRows = Table.FindRows(New Structure("LineChangeType", 0));
	If Table.Count() = UnchangedRows.Count()
	   And Not UserProperties.Property("ShouldLogChanges") Then
		Return;
	EndIf;
	
	If UserProperties.Property("IBUserID")
	   And TypeOf(UserProperties.IBUserID) = Type("UUID")
	   And RecordSet.Count() = 1 Then
		
		UsersProperties = New ValueTable;
		UsersProperties.Columns.Add("User");
		UsersProperties.Columns.Add("IBUserID");
		UsersProperties.Columns.Add("DeletionMark");
		UsersProperties.Columns.Add("Invalid");
		NewRow = UsersProperties.Add();
		FillPropertyValues(NewRow, RecordSet.AdditionalProperties.UserProperties);
		NewRow.User = RecordSet[0].User;
	Else
		Query = New Query;
		Query.SetParameter("UsersList", Table.UnloadColumn("User"));
		Query.Text =
		"SELECT
		|	Users.Ref AS User,
		|	Users.IBUserID AS IBUserID,
		|	Users.DeletionMark AS DeletionMark,
		|	Users.Invalid AS Invalid
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	Users.Ref IN(&UsersList)
		|
		|UNION ALL
		|
		|SELECT
		|	ExternalUsers.Ref,
		|	ExternalUsers.IBUserID,
		|	ExternalUsers.DeletionMark,
		|	ExternalUsers.Invalid
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|WHERE
		|	ExternalUsers.Ref IN(&UsersList)";
		
		UsersProperties = Query.Execute().Unload();
		UsersProperties.Indexes.Add("User");
	EndIf;
	
	ProcessedUsers = New Map;
	
	For Each String In Table Do
		If Not ValueIsFilled(String.User)
		 Or ProcessedUsers.Get(String.User) <> Undefined Then
			Continue;
		EndIf;
		ProcessedUsers.Insert(String.User, True);
		
		Data = New Structure;
		Data.Insert("DataStructureVersion", 1);
		Data.Insert("Ref", ValueToStringInternal(String.User));
		Data.Insert("RefType", String.User.Metadata().FullName());
		Data.Insert("LinkID", Lower(String.User.UUID()));
		Data.Insert("IBUserID");
		Data.Insert("Name");
		Data.Insert("UserMustChangePasswordOnAuthorization", False);
		Data.Insert("UnlimitedValidityPeriod", False);
		Data.Insert("ValidityPeriod", '00010101');
		Data.Insert("InactivityPeriodBeforeDenyingAuthorization", 0);
		Data.Insert("DeletionMark");
		Data.Insert("Invalid");
		
		NewRecord = NewRecords.Find(String.User, "User");
		UserProperties = UsersProperties.Find(String.User, "User");
		If UserProperties <> Undefined Then
			Data.IBUserID = Lower(UserProperties.IBUserID);
			Data.DeletionMark = UserProperties.DeletionMark;
			Data.Invalid  = UserProperties.Invalid;
			IBUser = InfoBaseUsers.FindByUUID(
				UserProperties.IBUserID);
			If IBUser <> Undefined Then
				Data.Name = IBUser.Name;
			EndIf;
		EndIf;
		
		If String.LineChangeType = 1 Then
			FillPropertyValues(Data, NewRecord,
				"UserMustChangePasswordOnAuthorization,
				|UnlimitedValidityPeriod,
				|ValidityPeriod,
				|InactivityPeriodBeforeDenyingAuthorization");
		EndIf;
		
		WriteLogEvent(
			UsersInternal.EventNameChangeAdditionalForLogging(),
			EventLogLevel.Information,
			Metadata.InformationRegisters.UsersInfo,
			Common.ValueToXMLString(Data),
			,
			EventLogEntryTransactionMode.Transactional);
	EndDo;
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf