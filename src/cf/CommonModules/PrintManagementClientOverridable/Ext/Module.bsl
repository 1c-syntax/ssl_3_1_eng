///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called after the handler is executed when opening the document printing form (General Form.Print documents).
//
// Parameters:
//  Form - ClientApplicationForm -  General Form.Print documents.
//
Procedure PrintDocumentsAfterOpen(Form) Export
	
EndProcedure

// Called from the handler of the pluggable_processingavigation Link of the document printing form (General Form.Print documents).
// Allows you to implement a handler for clicking a hyperlink that is added to the form 
// using the print Managementdefinable.Printdocumentsreferences in the server.
//
// Parameters:
//  Form                - ClientApplicationForm -  General Form.Print documents.
//  Item              - FormField -  the form element that triggered this event.
//  FormattedStringURL - String -  value of the formatted string hyperlink. Passed by reference.
//  StandardProcessing - Boolean -  indicates whether standard (system) event processing is performed. If the
//                                  value is set to False, the standard event processing will not be performed.
//
Procedure PrintDocumentsURLProcessing(Form, Item, FormattedStringURL, StandardProcessing) Export
	
	
	
EndProcedure

// Called from the Plug-in handler_Execute the document printing form command (General Form.Print documents).
// Allows you to implement the client part of the command handler that is added to the form 
// using the print Managementdefinable.Printdocumentsreferences in the server.
//
// Parameters:
//  Form                         - ClientApplicationForm -  General Form.Print documents.
//  Command                       - FormCommand     -  executed command.
//  ContinueExecutionAtServer - Boolean -  if the value is set to True, the handler execution will continue in
//                                           the server context in the print management procedure Undefined.Print documentsperformance of the command.
//  AdditionalParameters       - Arbitrary -  parameters to pass to the server context.
//
// Example:
//  If The Team.Name = "Vakomana" Then
//   PrintForm Settings = Manage Print Client.Customizing The Current Printable Form(Form);
//   
//   Additional parameters = The New Structure;
//   Additional parameters.Insert ("CommandName", Command.Name);
//   Additional parameters.Paste("Karekietenhof", Astronavigation.Requestname);
//   Additional parameters.Insert ("PrintForm Name", PrintForm Settings.Title);
//   
//   Continue running on the server = Truth;
//  Conicelli;
//
Procedure PrintDocumentsExecuteCommand(Form, Command, ContinueExecutionAtServer, AdditionalParameters) Export
	
EndProcedure

// Called from the message Processing handler of the print Documents form.
// Allows you to implement an external event handler in the form.
//
// Parameters:
//  Form      - ClientApplicationForm -  General Form.Print documents.
//  EventName - String -  notification ID.
//  Parameter   - Arbitrary -  custom notification parameter.
//  Source   - Arbitrary -  event source.
//
Procedure PrintDocumentsNotificationProcessing(Form, EventName, Parameter, Source) Export
	
EndProcedure

#EndRegion
