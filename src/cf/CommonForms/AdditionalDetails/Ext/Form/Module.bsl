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
	
	Template = GetCommonTemplate(Parameters.TemplateName);
	
	HTMLDocumentField = Template.GetText();
	
	Parameters.Property("Title", Title);
	
EndProcedure

#EndRegion
