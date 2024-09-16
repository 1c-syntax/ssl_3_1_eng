///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Value Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		Block.Add("InformationRegister.EmailAccountSettings");
		Block.Lock();
		
		// 
		AccountsSettings = InformationRegisters.EmailAccountSettings.CreateRecordSet();
		AccountsSettings.Read();
		For Each Setting In AccountsSettings Do
			Setting.NewMessageSignatureFormat = Enums.EmailEditingMethods.NormalText;
			Setting.ReplyForwardSignatureFormat = Enums.EmailEditingMethods.NormalText;
		EndDo;
		If AccountsSettings.Modified() Then
			AccountsSettings.Write();
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf