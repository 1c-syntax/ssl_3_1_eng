///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Set or remove the information database lock
// based on the values of the processing details.
//
Procedure PerformInstallation() Export
	
	ExecuteSetLock(DisableUserAuthorisation);
	
EndProcedure

// Cancel a previously set session lock.
//
Procedure CancelLock() Export
	
	ExecuteSetLock(False);
	
EndProcedure

// Read the parameters of blocking the information base 
// in the processing details.
//
Procedure GetLockParameters() Export
	
	If Users.IsFullUser(, True) Then
		CurrentMode = GetSessionsLock();
		UnlockCode = CurrentMode.KeyCode;
	Else
		CurrentMode = IBConnections.GetDataAreaSessionLock();
	EndIf;
	
	DisableUserAuthorisation = CurrentMode.Use 
		And (Not ValueIsFilled(CurrentMode.End) Or CurrentSessionDate() < CurrentMode.End);
	MessageForUsers = IBConnectionsClientServer.ExtractLockMessage(CurrentMode.Message);
	
	If DisableUserAuthorisation Then
		LockEffectiveFrom    = CurrentMode.Begin;
		LockEffectiveTo = CurrentMode.End;
	Else
		// 
		// 
		// 
		LockEffectiveFrom     = BegOfMinute(CurrentSessionDate() + 15 * 60);
	EndIf;
	
EndProcedure

Procedure ExecuteSetLock(Value)
	
	If Users.IsFullUser(, True) Then
		Block = New SessionsLock;
		Block.KeyCode    = UnlockCode;
		Block.Parameter = ServerNotifications.SessionKey();
	Else
		Block = IBConnections.NewConnectionLockParameters();
	EndIf;
	
	Block.Begin           = LockEffectiveFrom;
	Block.End            = LockEffectiveTo;
	Block.Message        = IBConnections.GenerateLockMessage(MessageForUsers, 
		UnlockCode); 
	Block.Use      = Value;
	
	If Users.IsFullUser(, True) Then
		SetSessionsLock(Block);
		
		SetPrivilegedMode(True);
		IBConnections.SendServerNotificationAboutLockSet();
		SetPrivilegedMode(False);
	Else
		IBConnections.SetDataAreaSessionLock(Block);
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf