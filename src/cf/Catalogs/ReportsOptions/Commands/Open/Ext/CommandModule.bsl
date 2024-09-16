///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(OptionRef1, CommandExecuteParameters)
	Variant = OptionRef1;
	Form = CommandExecuteParameters.Source;
	If TypeOf(Form) = Type("ClientApplicationForm") Then
		If Form.FormName = "Catalog.ReportsOptions.Form.ListForm" Then
			Variant = Form.Items.List.CurrentData;
		ElsIf Form.FormName = "Catalog.ReportsOptions.Form.ItemForm" Then
			Variant = Form.Object;
		EndIf;
	Else
		Form = Undefined;
	EndIf;
	
	ReportsOptionsClient.OpenReportForm(Form, Variant);
EndProcedure

#EndRegion
