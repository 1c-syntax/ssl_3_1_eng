﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
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
	
	For Each Record In ThisObject Do
		Record.DataSize = ObjectsVersioning.DataSize(Record.ObjectVersion);
		
		VersionData = Record.ObjectVersion.Get();
		Record.HasVersionData = VersionData <> Undefined;
		
		If IsBlankString(Record.Checksum) And Record.HasVersionData Then
			Record.Checksum = ObjectsVersioning.Checksum(VersionData);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf