///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#If Not MobileStandaloneServer Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	// 
	Catalogs.MetadataObjectIDs.BeforeWriteObject(ThisObject);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	// 
	Catalogs.MetadataObjectIDs.AtObjectWriting(ThisObject);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	// 
	Catalogs.MetadataObjectIDs.BeforeDeleteObject(ThisObject);
	
EndProcedure

#EndRegion

#EndIf

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf