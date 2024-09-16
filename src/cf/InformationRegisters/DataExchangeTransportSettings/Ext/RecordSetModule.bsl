///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	For Each SetRow In ThisObject Do
		
		// 
		TrimAllFieldValue(SetRow, "COM1CEnterpriseServerSideInfobaseName");
		TrimAllFieldValue(SetRow, "COMUserName");
		TrimAllFieldValue(SetRow, "COM1CEnterpriseServerName");
		TrimAllFieldValue(SetRow, "COMInfobaseDirectory");
		TrimAllFieldValue(SetRow, "FILEDataExchangeDirectory");
		TrimAllFieldValue(SetRow, "FTPConnectionUser");
		TrimAllFieldValue(SetRow, "FTPConnectionPath");
		TrimAllFieldValue(SetRow, "WSWebServiceURL");
		TrimAllFieldValue(SetRow, "WSUserName");
		
	EndDo;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// 
	// 
	RefreshReusableValues();
	
EndProcedure

#EndRegion

#Region Private

Procedure TrimAllFieldValue(Record, Val Field)
	
	Record[Field] = TrimAll(Record[Field]);
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf