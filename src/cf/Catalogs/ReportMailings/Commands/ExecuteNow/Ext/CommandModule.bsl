///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(MailingArray, CommandExecuteParameters)
	If TypeOf(MailingArray) <> Type("Array") Or MailingArray.Count() = 0 Then
		Return;
	EndIf;
	
	Form = CommandExecuteParameters.Source;
	
	StartupParameters = New Structure("MailingArray, Form, IsItemForm");
	StartupParameters.MailingArray = MailingArray;
	StartupParameters.Form = Form;
	StartupParameters.IsItemForm = (Form.FormName = "Catalog.ReportMailings.Form.ItemForm");
	
	ReportMailingClient.ExecuteNow(StartupParameters);
EndProcedure

#EndRegion
