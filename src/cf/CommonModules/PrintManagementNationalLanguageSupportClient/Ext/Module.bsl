///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Procedure AdditionalInformationURLProcessing(Item, FormattedStringURL, StandardProcessing) Export
	
	If FormattedStringURL = "GoToTheLanguagesOfPrintedForms" Then
		StandardProcessing = False;
		OpenForm("Catalog.PrintFormsLanguages.ListForm");
	EndIf;
	
EndProcedure

#EndRegion