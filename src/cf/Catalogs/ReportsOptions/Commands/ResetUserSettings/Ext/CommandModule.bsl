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
		ShowMessageBox(, NStr("en = 'Select report options to reset custom settings.';"));
		Return;
	EndIf;
	
	OpenForm("Catalog.ReportsOptions.Form.UserSettingsReset",
		New Structure("Variants", Variants), CommandExecuteParameters.Source);
EndProcedure

#EndRegion
