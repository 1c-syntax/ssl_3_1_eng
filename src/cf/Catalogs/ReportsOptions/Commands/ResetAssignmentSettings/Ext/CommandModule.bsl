///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(Variants, CommandExecuteParameters)
	If TypeOf(Variants) <> Type("Array") Or Variants.Count() = 0 Then
		ShowMessageBox(, NStr("en = 'Select report options to reset location settings.';"));
		Return;
	EndIf;
	
	OpenForm("Catalog.ReportsOptions.Form.ResetAssignmentToSections",
		New Structure("Variants", Variants), CommandExecuteParameters.Source);
EndProcedure

#EndRegion
