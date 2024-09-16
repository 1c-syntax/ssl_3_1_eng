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
	
	SetFullTextSearchMode(Value);
	
EndProcedure

#EndRegion

#Region Private

Procedure SetFullTextSearchMode(UseFullTextSearch)
	
	If UseFullTextSearch Then
		FullTextSearch.SetFullTextSearchMode(FullTextSearchMode.Enable);
	Else
		FullTextSearch.SetFullTextSearchMode(FullTextSearchMode.Disable);
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf