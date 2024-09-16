﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Record.Id <> IDAsString Then
		Record.Id = IDAsString;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	IDAsString = Record.Id;
	
EndProcedure

#EndRegion