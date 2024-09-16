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
	
	Record.FileOwner = Parameters.FileOwner;
	Record.FileOwnerType = Parameters.FileOwnerType;
	Record.IsFile = Parameters.IsFile;
	
	If ValueIsFilled(Record.Account) Then
		Items.Account.ReadOnly = True;
	EndIf;
	
	OwnerPresentation = Common.SubjectString(Record.FileOwner);
	
	Title = NStr("en = 'File synchronization setting:';")
		+ " " + OwnerPresentation;
	
EndProcedure

#EndRegion