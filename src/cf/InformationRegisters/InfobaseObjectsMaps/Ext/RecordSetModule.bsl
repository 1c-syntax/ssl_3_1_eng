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
	
	// 
	AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	
	// 
	DataExchange.Recipients.Clear();
	
	// 
	If Count() > 0 Then
		
		If ThisObject[0].ObjectExportedByRef = True 
			Or Not ValueIsFilled(ThisObject[0]["SourceUUID"]) Then
			Return;
		EndIf;
		
		ThisObject[0]["SourceUUIDString"] = String(ThisObject[0]["SourceUUID"].UUID());
		
	EndIf;
	
	If DataExchange.Load
		Or Not ValueIsFilled(Filter.InfobaseNode.Value)
		Or Not ValueIsFilled(Filter.DestinationUUID.Value)
		Or Not Common.RefExists(Filter.InfobaseNode.Value) Then
		Return;
	EndIf;
	
	// 
	DataExchange.Recipients.Add(Filter.InfobaseNode.Value);
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf