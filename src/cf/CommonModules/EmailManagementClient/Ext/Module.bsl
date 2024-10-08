﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Parameters:
//  Ref  - CatalogRef.IncomingEmailAttachedFiles,
//            Spravochnike.E-mailinputconnected files - link to the file to
//                                                                            open.
//
Procedure OpenAttachment(Ref, Form, ForEditing = False) Export

	FileData = FilesOperationsClient.FileData(Ref, Form.UUID);
	
	If Form.RestrictedExtensions.FindByValue(FileData.Extension) <> Undefined Then
		
		AdditionalParameters = New Structure("FileData", FileData);
		AdditionalParameters.Insert("ForEditing", ForEditing);
		
		Notification = New NotifyDescription("OpenFileAfterConfirm", ThisObject, AdditionalParameters);
		UsersInternalClient.ShowSecurityWarning(Notification,
			UsersInternalClientServer.TypesOfSafetyWarnings().BeforeOpenFile,
			FileData.FileName);
		Return;
		
	EndIf;
	
	FilesOperationsClient.OpenFile(FileData, ForEditing);
	
EndProcedure

Procedure OpenFileAfterConfirm(Result, AdditionalParameters) Export
	
	If Result <> Undefined And Result = "Continue" Then
		FilesOperationsClient.OpenFile(AdditionalParameters.FileData, AdditionalParameters.ForEditing);
	EndIf;

EndProcedure

// Parameters:
//  TableOfContacts - FormDataCollection -  contains descriptions and links to contacts of the interaction
//                                            or participants of the interaction subject.
//
// Returns:
//  Array of Structure:
//    * Address - String
//    * Presentation - String
//    * Contact - Arbitrary 
//
Function ContactsTableToArray(TableOfContacts) Export
	
	Result = New Array;
	For Each TableRow In TableOfContacts Do
		Contact = ?(TypeOf(TableRow.Contact) = Type("String"), Undefined, TableRow.Contact);
		Record = New Structure(
		"Address, Presentation, Contact", TableRow.Address, TableRow.Presentation, Contact);
		Result.Add(Record);
	EndDo;
	
	Return Result;
	
EndFunction

// Receive mail for all available accounts.
// 
// Parameters:
//  ItemList - FormField -  a form element that needs to be updated after receiving emails.
//
Procedure SendReceiveUserEmail(UUID, Form, ItemList = Undefined, DisplayProgress = True) Export

	TimeConsumingOperation =  InteractionsServerCall.SendReceiveUserEmailInBackground(UUID);
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	Form.SendReceiveEmailInProgress = True;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemList",       ItemList);
	AdditionalParameters.Insert("URL", Undefined);
	AdditionalParameters.Insert("Form",               Form);
	AdditionalParameters.Insert("DisplayProgress",    DisplayProgress);
	If Form.Window <> Undefined Then
		AdditionalParameters.URL = Form.Window.GetURL();
	EndIf;	
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	If DisplayProgress Then
		IdleParameters.OutputProgressBar = True;
	Else
		IdleParameters.OutputIdleWindow = False;
	EndIf;
	CallbackOnCompletion = New NotifyDescription("SendReceiveUserEmailCompletion", ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

// Processing the user's mail upload completion
// 
// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Structure:
//   * ItemList - FormTable -  an element containing a dynamic list.
//
Procedure SendReceiveUserEmailCompletion(Result, AdditionalParameters) Export
	
	AdditionalParameters.Form.SendReceiveEmailInProgress = False;
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		
		If AdditionalParameters.ItemList <> Undefined 
		     And AdditionalParameters.ItemList.Visible
		     And AdditionalParameters.ItemList.CurrentData <> Undefined Then
			AdditionalParameters.ItemList.Refresh();
		EndIf;
		
		AdditionalParameters.Form.DateOfPreviousEmailReceiptSending = CommonClient.SessionDate();
		
		If AdditionalParameters.DisplayProgress Then
		
			Title = NStr("en = 'Mail Sync';");
			ExecutionResult = GetFromTempStorage(Result.ResultAddress);
			If ExecutionResult.HasErrors Then
				ShowUserNotification(Title, "e1cib/app/DataProcessor.EventLog", 
					NStr("en = 'Not all the mail has been synced. See the event log for details.';"), 
					PictureLib.Warning, UserNotificationStatus.Important);
			Else	
				ShowUserNotification(Title, AdditionalParameters.URL,
					EmailsSendingReceivingResult(ExecutionResult));
			EndIf;
			
		EndIf;
		
		Notify("SendAndReceiveEmailDone");
	EndIf;
	
EndProcedure

Function EmailsSendingReceivingResult(ExecutionResult)
	
	If ExecutionResult.EmailsReceived1 > 0 And ExecutionResult.SentEmails1 > 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Received: %1; Sent: %2';"), 
			ExecutionResult.EmailsReceived1, ExecutionResult.SentEmails1);
	ElsIf ExecutionResult.EmailsReceived1 > 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Received: %1';"), 
			ExecutionResult.EmailsReceived1);
	ElsIf ExecutionResult.SentEmails1 > 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Sent: %1';"), 
			ExecutionResult.SentEmails1);
	Else
		MessageText = NStr("en = 'No new messages.';");
	EndIf;	
	If ExecutionResult.UserAccountsAvailable > 1 Then
		MessageText = MessageText + Chars.LF  
			+ StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Accounts synced: %1';"),
				ExecutionResult.UserAccountsAvailable);
	EndIf;
	
	Return MessageText;
	
EndFunction

#EndRegion
