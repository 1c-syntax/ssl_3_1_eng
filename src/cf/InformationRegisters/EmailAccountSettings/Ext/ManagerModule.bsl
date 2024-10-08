﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(EmailAccount)
	|	OR ValueAllowed(EmailAccount.AccountOwner, EmptyRef AS FALSE)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Internal

// 
//
// Parameters:
//  Account     - CatalogRef.EmailAccounts - 
//  DateOfUse - Date - 
//
Procedure UpdateTheAccountUsageDate(Account, DateOfUse = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.EmailAccountSettings");
	LockItem.SetValue("EmailAccount", Account);
	
	RecordSet = InformationRegisters.EmailAccountSettings.CreateRecordSet();
	RecordSet.Filter.EmailAccount.Set(Account);
	
	If DateOfUse = Undefined Then
		DateOfUse = BegOfDay(CurrentSessionDate());
	EndIf;
	
	WritingRequired = False;
	
	BeginTransaction();
	Try
		
		Block.Lock();
		
		RecordSet.Read();
		
		If RecordSet.Count() > 0 Then
			
			If RecordSet[0].DateOfLastUse <> DateOfUse Then
				
				RecordSet[0].DateOfLastUse = DateOfUse;
				WritingRequired = True;
				
			EndIf;
			
		Else
			
			SetRecord = RecordSet.Add();
			SetRecord.DateOfLastUse   = DateOfUse;
			SetRecord.EmailAccount = Account;
			
			WritingRequired = True;
		
		EndIf;
		
		If WritingRequired Then
			RecordSet.Write();
		EndIf;
		
		CommitTransaction();
	
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf
