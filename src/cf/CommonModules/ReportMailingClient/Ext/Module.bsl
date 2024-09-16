///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Handler for the report form command.
//
// Parameters:
//   Form     - ClientApplicationForm -  report form.
//   Command   - FormCommand     - 
//
// :
//   
//
Procedure CreateNewBulkEmailFromReport(Form, Command) Export
	OpenReportMailingFromReportForm(Form);
EndProcedure

// Handler for the report form command.
//
// Parameters:
//   Form     - ClientApplicationForm -  report form.
//   Command   - FormCommand     - 
//
// :
//   
//
Procedure AttachReportToExistingBulkEmail(Form, Command) Export
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
	FormParameters.Insert("MultipleChoice", False);
	
	OpenForm("Catalog.ReportMailings.ChoiceForm", FormParameters, Form);
EndProcedure

// Handler for the report form command.
//
// Parameters:
//   Form     - ClientApplicationForm -  report form.
//   Command   - FormCommand     - 
//
// :
//   
//
Procedure OpenBulkEmailsWithReport(Form, Command) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Report", Form.ReportSettings.OptionRef);
	OpenForm("Catalog.ReportMailings.ListForm", FormParameters, Form);
	
EndProcedure

// Handler for selecting the report form.
//
// Parameters:
//   Form             - ClientApplicationForm -  report form.
//   ValueSelected - Arbitrary     -  the result of the selection in the subordinate form.
//   ChoiceSource    - ClientApplicationForm -  the form where the selection was made.
//   Result         - Boolean           - 
//
// :
//   
//
Procedure ChoiceProcessingReportForm(Form, ValueSelected, ChoiceSource, Result) Export
	
	If Result = True Then
		Return;
	EndIf;
	
	If TypeOf(ValueSelected) = Type("CatalogRef.ReportMailings") Then
		
		OpenReportMailingFromReportForm(Form, ValueSelected);
		
		Result = True;
		
	EndIf;
	
EndProcedure

Procedure ClearReportDistributionHistory(Form) Export

	If Form.ConstantsSet.RetainReportDistributionHistory Then
		QueryText = StringFunctionsClient.FormattedString(NStr(
		"en = 'Do you want to clear an obsolete report distribution history?';"));
	Else
		QueryText = StringFunctionsClient.FormattedString(NStr(
		"en = 'Do you want to clear the report distribution history?';"));
	EndIf;

	Parameters = New Structure("Form", Form);

	ShowQueryBox(New NotifyDescription("ResponseClearUpReportDistributionHistory", ThisObject, Parameters), QueryText,
		QuestionDialogMode.YesNo, , DialogReturnCode.Yes);

EndProcedure

#EndRegion

#Region Private

// Generates a list of mailing list recipients, prompts the user to select
//   a specific recipient or all mailing list recipients, and returns
//   the result of the user's selection.
// Called from the element form.
//
Procedure SelectRecipient(ResultHandler, Object, MultipleChoice, ReturnsMap) Export
	
	If Object.Personal = True Then
		ParametersSet = "Ref, RecipientsEmailAddressKind, Personal, Author";
	Else
		ParametersSet = "Ref, RecipientsEmailAddressKind, Personal, MailingRecipientType, Recipients";
	EndIf;
	
	RecipientsParameters = New Structure(ParametersSet);
	FillPropertyValues(RecipientsParameters, Object);
	ExecutionResult = ReportMailingServerCall.GenerateMailingRecipientsList(RecipientsParameters);
	
	If ExecutionResult.HadCriticalErrors Then
		QuestionToUserParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionToUserParameters.PromptDontAskAgain = False;
		QuestionToUserParameters.Picture = PictureLib.DialogExclamation;
		StandardSubsystemsClient.ShowQuestionToUser(Undefined, ExecutionResult.Text, 
			QuestionDialogMode.OK, QuestionToUserParameters);
		Return;
	EndIf;
	
	Recipients = ExecutionResult.Recipients;
	If Recipients.Count() = 1 Then
		Result = Recipients;
		If Not ReturnsMap Then
			For Each KeyAndValue In Recipients Do
				Result = New Structure("Recipient, MailAddress", KeyAndValue.Key, KeyAndValue.Value);
			EndDo;
		EndIf;
		ExecuteNotifyProcessing(ResultHandler, Result);
		Return;
	EndIf;
	
	PossibleRecipients = New ValueList;
	For Each KeyAndValue In Recipients Do
		PossibleRecipients.Add(KeyAndValue.Key, String(KeyAndValue.Key) +" <"+ KeyAndValue.Value +">");
	EndDo;
	If MultipleChoice Then
		PossibleRecipients.Insert(0, Undefined, NStr("en = 'To all recipients';"));
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ResultHandler", ResultHandler);
	AdditionalParameters.Insert("Recipients", Recipients);
	AdditionalParameters.Insert("ReturnsMap", ReturnsMap);
	
	Handler = New NotifyDescription("SelectRecipientCompletion", ThisObject, AdditionalParameters);
	PossibleRecipients.ShowChooseItem(Handler, NStr("en = 'Select recipient';"));
	
EndProcedure

// Handler for the result of the select Recipient procedure.
// 
// Parameters:
//   SelectedElement - ValueListItem
//   AdditionalParameters - Structure:
//     * ResultHandler - NotifyDescription
//     * Recipients - Map of KeyAndValue:
//       ** Key - Arbitrary
//       ** Value - String 
//     * ReturnsMap - Boolean
//
Procedure SelectRecipientCompletion(SelectedElement, AdditionalParameters) Export
	If SelectedElement = Undefined Then
		Result = Undefined;
	Else
		If AdditionalParameters.ReturnsMap Then
			If SelectedElement.Value = Undefined Then
				Result = AdditionalParameters.Recipients;
			Else
				Result = New Map;
				Result.Insert(SelectedElement.Value, AdditionalParameters.Recipients[SelectedElement.Value]);
			EndIf;
		Else
			Result = New Structure("Recipient, MailAddress", SelectedElement.Value, AdditionalParameters.Recipients[SelectedElement.Value]);
		EndIf;
	EndIf;
	
	ExecuteNotifyProcessing(AdditionalParameters.ResultHandler, Result);
EndProcedure

// Performs mailings in the background.
Procedure ExecuteNow(Parameters) Export
	Handler = New NotifyDescription("ExecuteNowInBackground", ThisObject, Parameters);
	If Parameters.IsItemForm Then
		Object = Parameters.Form.Object;
		If Not Object.IsPrepared Then
			ShowMessageBox(, NStr("en = 'The report distribution is not prepared.';"));
			Return;
		EndIf;
		If Object.UseEmail Then
			SelectRecipient(Handler, Parameters.Form.Object, True, True);
			Return;
		EndIf;
	EndIf;
	ExecuteNotifyProcessing(Handler, Undefined);
EndProcedure

// Starts a background task, called when all parameters are ready.
Procedure ExecuteNowInBackground(Recipients, Parameters) Export
	PreliminarySettings = Undefined;
	If Parameters.IsItemForm Then
		If Parameters.Form.Object.UseEmail Then
			If Recipients = Undefined Then
				Return;
			EndIf;
			PreliminarySettings = New Structure("Recipients", Recipients);
		EndIf;
		StateText = NStr("en = 'Distributing reports.';");
	Else
		StateText = NStr("en = 'Distributing reports.';");
	EndIf;
	
	MethodParameters = New Structure;
	MethodParameters.Insert("MailingArray", Parameters.MailingArray);
	MethodParameters.Insert("PreliminarySettings", PreliminarySettings);
	
	Job = ReportMailingServerCall.RunBackgroundJob1(MethodParameters, Parameters.Form.UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(Parameters.Form);
	WaitSettings.OutputIdleWindow = True;
	WaitSettings.MessageText = StateText;
	WaitSettings.OutputProgressBar = True;
	
	Handler = New NotifyDescription("ExecuteNowInBackgroundCompletion", ThisObject, Parameters);
	TimeConsumingOperationsClient.WaitCompletion(Job, Handler, WaitSettings);
	
EndProcedure

// Accepts the result of a background task.
//
// Parameters:
//  Job - See TimeConsumingOperationsClient.NewResultLongOperation
//  Parameters - Arbitrary
//
Procedure ExecuteNowInBackgroundCompletion(Job, Parameters) Export
	
	If Job = Undefined Then
		Return; // 
	EndIf;
	
	If Job.Status = "Completed2" Then
		Result = GetFromTempStorage(Job.ResultAddress);
		MailingNumber = Result.BulkEmails.Count();
		If MailingNumber > 0 Then
			NotifyChanged(?(MailingNumber > 1, Type("CatalogRef.ReportMailings"), Result.BulkEmails[0]));
		EndIf;
		ShowUserNotification(,, Result.Text, PictureLib.ReportMailing, UserNotificationStatus.Information);
		
	Else
		StandardSubsystemsClient.OutputErrorInfo(
			Job.ErrorInfo);
	EndIf;
	
EndProcedure

// Opens the distribution of reports from the report form.
//
// Parameters:
//   Form  - ClientApplicationForm -  report form.
//   Ref - CatalogRef.ReportMailings -  the report distribution link.
//
Procedure OpenReportMailingFromReportForm(Form, Ref = Undefined)
	ReportSettings = Form.ReportSettings;
	ReportOptionMode = (TypeOf(Form.CurrentVariantKey) = Type("String") And Not IsBlankString(Form.CurrentVariantKey));
	
	ReportsParametersRow = New Structure("ReportFullName, VariantKey, OptionRef, Settings");
	ReportsParametersRow.ReportFullName = ReportSettings.FullName;
	ReportsParametersRow.VariantKey   = Form.CurrentVariantKey;
	ReportsParametersRow.OptionRef  = ReportSettings.OptionRef;
	If ReportOptionMode Then
		ReportsParametersRow.Settings = Form.Report.SettingsComposer.UserSettings;
	EndIf;
	
	ReportsToAttach = New Array;
	ReportsToAttach.Add(ReportsParametersRow);
	
	FormParameters = New Structure;
	FormParameters.Insert("ReportsToAttach", ReportsToAttach);
	If Ref <> Undefined Then
		FormParameters.Insert("Key", Ref);
	EndIf;
	
	OpenForm("Catalog.ReportMailings.ObjectForm", FormParameters, , String(Form.UUID) + ".OpenReportsMailing");
	
EndProcedure

// Returns a set of templates for filling in scheduled tasks.
Function ScheduleFillingOptionsList() Export
	
	VariantList = New ValueList;
	VariantList.Add(1, NStr("en = 'Every day';"));
	VariantList.Add(2, NStr("en = 'Every second day';"));
	VariantList.Add(3, NStr("en = 'Every fourth day';"));
	VariantList.Add(4, NStr("en = 'On weekdays';"));
	VariantList.Add(5, NStr("en = 'On weekends';"));
	VariantList.Add(6, NStr("en = 'On Mondays';"));
	VariantList.Add(7, NStr("en = 'On Fridays';"));
	VariantList.Add(8, NStr("en = 'On Sundays';"));
	VariantList.Add(9, NStr("en = 'On the first day of the month';"));
	VariantList.Add(10, NStr("en = 'On the last day of the month';"));
	VariantList.Add(11, NStr("en = 'On the 10th day of every quarter';"));
	If Not CommonClient.DataSeparationEnabled() Then
		VariantList.Add(12, NStr("en = 'Other…';"));
	EndIf;
	
	Return VariantList;
EndFunction

// Parses the FTP address string into Login, Password, Server, Port and Directory.
//   For more information, see RFC 1738 (http://tools.ietf.org/html/rfc1738#section-3.1 ). 
//   Template: "ftp://<user>:<password>@<host>:<port>/<url-path>".
//   Fragments "<user>:<password>@", ":<password>", ":<port>" and "/<url-path>" may be missing.
//
// Parameters:
//   Ftpaddress String - the full path to the ftp resource.
//
// Returns:
//   Structure - :
//       * Login - String -  the name of the ftp user.
//       * Password - String -  the password of the ftp user.
//       * Server - String -  server name.
//       * Port - Number -  server port. By default, 21.
//       * Directory - String -  path to the folder on the server. The first character is always "/".
//
Function ParseFTPAddress(FullFTPAddress) Export
	
	Result = New Structure;
	Result.Insert("Login", "");
	Result.Insert("Password", "");
	Result.Insert("Server", "");
	Result.Insert("Port", 21);
	Result.Insert("Directory", "/");
	
	FTPAddress = FullFTPAddress;
	
	// 
	Pos = StrFind(FTPAddress, "://");
	If Pos > 0 Then
		FTPAddress = Mid(FTPAddress, Pos + 3);
	EndIf;
	
	// 
	Pos = StrFind(FTPAddress, "/");
	If Pos > 0 Then
		Result.Directory = Mid(FTPAddress, Pos);
		FTPAddress = Left(FTPAddress, Pos - 1);
	EndIf;
	
	// 
	Pos = StrFind(FTPAddress, "@");
	If Pos > 0 Then
		UsernamePassword = Left(FTPAddress, Pos - 1);
		FTPAddress = Mid(FTPAddress, Pos + 1);
		
		Pos = StrFind(UsernamePassword, ":");
		If Pos > 0 Then
			Result.Login = Left(UsernamePassword, Pos - 1);
			Result.Password = Mid(UsernamePassword, Pos + 1);
		Else
			Result.Login = UsernamePassword;
		EndIf;
	EndIf;
	
	// 
	Pos = StrFind(FTPAddress, ":");
	If Pos > 0 Then
		
		Result.Server = Left(FTPAddress, Pos - 1);
		
		NumberType = New TypeDescription("Number");
		Port     = NumberType.AdjustValue(Mid(FTPAddress, Pos + 1));
		Result.Port = ?(Port > 0, Port, Result.Port);
		
	Else
		
		Result.Server = FTPAddress;
		
	EndIf;
	
	Return Result;
	
EndFunction

// 
Procedure SendBulkSMSMessages(Parameters) Export
	Handler = New NotifyDescription("SendBulkSMSMessagesInBackground", ThisObject, Parameters);
	ExecuteNotifyProcessing(Handler, Undefined);
EndProcedure

// Starts a background task, called when all parameters are ready.
Procedure SendBulkSMSMessagesInBackground(Recipients, Parameters) Export

	MethodParameters = New Structure;
	MethodParameters.Insert("PreparedSMSMessages", Parameters.PreparedSMSMessages);
	MethodParameters.Insert("UnsentCount", Parameters.UnsentCount);
	
	Job = ReportMailingServerCall.RunBackgroundJobToSendSMSWithPasswords(MethodParameters,
		Parameters.Form.UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(Parameters.Form);
	WaitSettings.OutputIdleWindow = True;
	WaitSettings.MessageText = NStr("en = 'Sending text messages with passwords for the report distribution.';");
	
	Handler = New NotifyDescription("SendBulkSMSMessagesInBackgroundCompletion", ThisObject, Parameters);
	TimeConsumingOperationsClient.WaitCompletion(Job, Handler, WaitSettings);

EndProcedure

// Accepts the result of a background task.
//
// Parameters:
//   Job - See TimeConsumingOperationsClient.NewResultLongOperation
//   Parameters - Structure:
//     * UnsentCount - Number
//     * PreparedSMSMessages - Array of Structure:
//         ** PhoneNumbers - Array of String - 
//         ** SMSMessageText - String
//         ** Recipient - DefinedType.BulkEmailRecipient	
//     * Form - ClientApplicationForm:
//         ** Items - FormAllItems
//         ** SMSDistributionResult - FormDataCollection
//         ** SMSDistributionResultNoFilters - FormDataCollection
//
Procedure SendBulkSMSMessagesInBackgroundCompletion(Job, Parameters) Export
	
	If Job = Undefined Then
		Return; // 
	EndIf;
		
	Form = Parameters.Form;     
	
	If Not Form.Items.Close.Visible Then
		Form.Items.Close.Visible = True;      
	EndIf;
	
	If Job.Status = "Completed2" Then
		Result = GetFromTempStorage(Job.ResultAddress);
		ShowUserNotification(,, Result.Text, PictureLib.ReportMailing, UserNotificationStatus.Information);	
		For Each RecipientResult In Result.ResultByRecipients Do
			ResultString1 = Form.SMSDistributionResult.Add();
			FillPropertyValues(ResultString1, RecipientResult);
			StringResultNoFilters = Form.SMSDistributionResultNoFilters.Add();
			FillPropertyValues(StringResultNoFilters, ResultString1);
		EndDo;      
		Form.SentCount = Result.SentCount;
		Form.UnsentCount = Result.UnsentCount;
		Form.AutoTitle = False;
		Form.Title = NStr("en = 'The result of sending text messages with archive passwords';");
		Form.Items.Pages.CurrentPage = Form.Items.InformationPage;
	Else
		Form.Items.Pages.CurrentPage = Form.Items.InformationPage;
		StandardSubsystemsClient.OutputErrorInfo(
			Job.ErrorInfo);
	EndIf;
	
EndProcedure

Procedure ResponseClearUpReportDistributionHistory(Result, Parameters) Export  
	
	If Result = DialogReturnCode.Yes Then
		Handler = New NotifyDescription("ClearUpReportDistributionHistoryInBackground", ThisObject, Parameters);
		ExecuteNotifyProcessing(Handler, Undefined);
	EndIf;
	
EndProcedure

// Starts a background task, called when all parameters are ready.
Procedure ClearUpReportDistributionHistoryInBackground(Parameters, AdditionalParameters) Export

	MethodParameters = New Structure;
	
	Job = ReportMailingServerCall.RunBackgroundJobToClearUpReportDistributionHistory(MethodParameters,
		AdditionalParameters.Form.UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(AdditionalParameters.Form);
	WaitSettings.OutputIdleWindow = True;
	WaitSettings.MessageText = NStr("en = 'Clearing the report distribution history.';");
	
	Handler = New NotifyDescription("ClearUpReportDistributionHistoryCompletion", ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(Job, Handler, WaitSettings);

EndProcedure

// Parameters:
//  Job - See TimeConsumingOperationsClient.NewResultLongOperation
//  Parameters - Arbitrary
//
Procedure ClearUpReportDistributionHistoryCompletion(Job, Parameters) Export
	
	If Job = Undefined Then
		Return; // 
	EndIf;
	
	If Job.Status = "Completed2" Then
		Result = GetFromTempStorage(Job.ResultAddress);
		ShowUserNotification(,, Result.Text, , UserNotificationStatus.Information);	
	Else
		StandardSubsystemsClient.OutputErrorInfo(
			Job.ErrorInfo);
	EndIf;	
	
EndProcedure

#EndRegion
