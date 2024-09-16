///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called before opening a new email form.
// Opening the form can be canceled by changing the standard Processing parameter.
//
// Parameters:
//  SendOptions    - See EmailOperationsClient.EmailSendOptions
//  CompletionHandler - NotifyDescription -  description of the procedure that will be called after the
//                                              message is sent.
//  StandardProcessing - Boolean -  indicates whether the new email form will continue to open after exiting this
//                                  procedure. If set to False, the email form will not be opened.
//
Procedure BeforeOpenEmailSendingForm(SendOptions, CompletionHandler, StandardProcessing) Export

	// 
	//  
	//  
	//  
	//  
	SendOptions.IsInteractiveRecipientSelection = True;
	// _Demo example end
EndProcedure

#EndRegion