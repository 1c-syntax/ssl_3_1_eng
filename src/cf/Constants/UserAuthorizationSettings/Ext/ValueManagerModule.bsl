///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var PreviousSettings1; // 

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	// 
	PrepareChangesForLogging(PreviousSettings1);
	// 
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// 
	DoLogChanges(PreviousSettings1);
	// 
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Returns:
//  Structure:
//   * AreSeparateSettingsForExternalUsers - Boolean
//   * InactivityPeriodBeforeDenyingAuthorization - Number
//   * InactivityPeriodBeforeDenyingAuthorizationForExternalUsers - Number
//   * ShowInList - String
//   * NotificationLeadTimeBeforeAccessExpire - Number
//
Function SettingsToRegister(LogonSettings)
	
	Result = New Structure;
	Result.Insert("DataStructureVersion", 1);
	
	Result.Insert("AreSeparateSettingsForExternalUsers",
		LogonSettings.Overall.AreSeparateSettingsForExternalUsers);
	
	Result.Insert("InactivityPeriodBeforeDenyingAuthorization",
		LogonSettings.Users.InactivityPeriodBeforeDenyingAuthorization);
	
	Result.Insert("InactivityPeriodBeforeDenyingAuthorizationForExternalUsers",
		LogonSettings.ExternalUsers.InactivityPeriodBeforeDenyingAuthorization);
	
	Result.Insert("ShowInList",
		LogonSettings.Overall.ShowInList);
	
	Result.Insert("NotificationLeadTimeBeforeAccessExpire",
		LogonSettings.Overall.NotificationLeadTimeBeforeAccessExpire);
	
	Return Result;
	
EndFunction

Procedure PrepareChangesForLogging(PreviousSettings1)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	PreviousSettings1 = SettingsToRegister(UsersInternal.LogonSettings());
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

Procedure DoLogChanges(PreviousSettings1)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	NewSettings1 = SettingsToRegister(UsersInternal.LogonSettings());
	
	HasChanges = False;
	For Each KeyAndValue In NewSettings1 Do
		If PreviousSettings1[KeyAndValue.Key] <> KeyAndValue.Value Then
			HasChanges = True;
			Break;
		EndIf;
	EndDo;
	
	If Not HasChanges Then
		Return;
	EndIf;
	
	WriteLogEvent(
		UsersInternal.EventNameChangeLoginSettingsAdditionalForLogging(),
		EventLogLevel.Information,
		Metadata.InformationRegisters.UsersInfo,
		Common.ValueToXMLString(NewSettings1),
		,
		EventLogEntryTransactionMode.Transactional);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf