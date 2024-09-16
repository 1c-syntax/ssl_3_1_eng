///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// 
	If Not Parameters.Property("ExchangePlanName") Then
		
		Raise NStr("en = 'This is a dependent form and opens from a different form.';", Common.DefaultLanguageCode());
		
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		
		Items.FormSetNewCode.Enabled = False;
		Items.GroupPanel.CurrentPage = Items.ServiceWorkPage;
		
	EndIf;
	
	ExchangePlanName = Parameters.ExchangePlanName;
	InfobaseNode = ExchangePlans[ExchangePlanName].ThisNode();	
	
EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetNewCode(Command)
	
	If InstallANewCodeOnTheServer() Then
		Close();	
	EndIf;
	
EndProcedure

&AtServer
Function InstallANewCodeOnTheServer()
	
	BeginTransaction();
	Try
		
		DataLock = New DataLock;
		
		DataLockItem = DataLock.Add("ExchangePlan." + ExchangePlanName);
		DataLockItem.SetValue("Ref", InfobaseNode);
				
		DataLock.Lock();

		ExchangeNodeObject = InfobaseNode.GetObject();
		ExchangeNodeObject.Code = String(New UUID);
		ExchangeNodeObject.DataExchange.Load = True;
		ExchangeNodeObject.Write();
						
		CommitTransaction();
		
		Return True;
		
	Except
				
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	Return False;
	
EndFunction

&AtClient
Procedure CloseForm(Command)
	
	Close()
	
EndProcedure

#EndRegion
