﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Key.IsEmpty() Then
		Cancel = True;
	Else
		ReadOnly = True;
	EndIf;
	
EndProcedure

#EndRegion
