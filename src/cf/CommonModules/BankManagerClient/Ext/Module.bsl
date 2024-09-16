///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens the BIC Directory selection form with selection based on the passed BIC.
// If there is only one entry in the selection list, then the selection in the form is made automatically.
//
// Parameters:
//  BIC - String -  bank identification code.
//  Form - ClientApplicationForm -  the form from which the selection form opens.
//  HandlerNotifications - NotifyDescription - 
//                                              
//    :
//     * BIC - CatalogRef.BankClassifier -  the selected item.
//     * AdditionalParameters - Arbitrary -  the parameter passed in the constructor of the description of the alert.
// 
Procedure SelectFromTheBICDirectory(BIC, Form, HandlerNotifications = Undefined) Export
	
	Parameters = New Structure;
	Parameters.Insert("BIC", BIC);
	OpenForm("Catalog.BankClassifier.ChoiceForm", Parameters, Form, , , , HandlerNotifications);
	
EndProcedure

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParameters.Property("Banks") And ClientParameters.Banks.OutputMessageOnInvalidity Then
		AttachIdleHandler("BankManagerOutputObsoleteDataNotification", 180, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 

// Displays the corresponding notification.
//
Procedure NotifyClassifierObsolete() Export
	
	If BankManagerServerCall.ClassifierUpToDate() Then
		Return;
	EndIf;
	
	ShowUserNotification(
		NStr("en = 'The bank classifier is outdated';"),
		NotificationURLImportForm(),
		NStr("en = 'Update the bank classifier';"),
		PictureLib.DialogExclamation,
		UserNotificationStatus.Important,
		"BankClassifierIsOutdated");
	
EndProcedure

// Returns the navigation link for notifications.
//
Function NotificationURLImportForm()
	Return "e1cib/command/DataProcessor.ImportBankClassifier.Command.ImportBankClassifier";
EndFunction

Procedure OpenClassifierImportForm() Export
	AttachIdleHandler("BankManagerOpenClassifierImportForm", 0.1, True);
EndProcedure

Procedure GoToClassifierImport() Export
	FileSystemClient.OpenURL(NotificationURLImportForm());
EndProcedure

Procedure SuggestToImportClassifier() Export
	
	NotifyDescription = New NotifyDescription("OnGetAnswerToQuestionAboutClassifierImport", ThisObject);
	QuestionTitle = NStr("en = 'Import bank classifier';");
	QueryText = NStr("en = 'Bank classifier has not been imported yet. Import now?';");
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes, NStr("en = 'Import';"));
	Buttons.Add(DialogReturnCode.Cancel);
	ShowQueryBox(NotifyDescription, QueryText, Buttons, , Buttons[0].Value, QuestionTitle);

EndProcedure

Procedure OnGetAnswerToQuestionAboutClassifierImport(Response, AdditionalParameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	OpenClassifierImportForm();
	
EndProcedure

#EndRegion
