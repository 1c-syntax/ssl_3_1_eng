///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Not MobileStandaloneServer Then
	
#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)

	StandardProcessing = False;
	Fields.Add("Hash");
	Fields.Add("Size");

EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	Presentation = Format(StrTemplate("%1 (%2)", Data.Hash, Data.Size));
	
EndProcedure

#EndRegion

#EndIf
