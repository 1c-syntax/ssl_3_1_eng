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

	If Not IsBlankString(Parameters.ExplanationText) Then
		Items.DecorationNote.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1
			           |Do you want to install it?';"),
			Parameters.ExplanationText);
	EndIf;
	
EndProcedure

#EndRegion