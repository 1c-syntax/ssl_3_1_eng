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
	If Not Parameters.Property("TemplateName") Then
		
		Raise NStr("en = 'This is a dependent form and opens from a different form.';", Common.DefaultLanguageCode());
		
	EndIf;
	
	HTMLDocumentField = StandaloneModeInternal.InstructionTextFromTemplate(Parameters.TemplateName);
	
	Parameters.Property("Title", Title);
	
EndProcedure

#EndRegion
