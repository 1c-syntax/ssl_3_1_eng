///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// 
// 
//   
//   
//   
//   
//
// 
//  
//  
//  
//
// Parameters:
//  Form              - ClientApplicationForm - 
//  RequestParameters_ - See ContactingTechnicalSupportInternalClient.RequestParameters_
//
Procedure SendQuestionToSupport(Form, RequestParameters_) Export
	
	If Not ScreenshotAppIsAvailable() Then
		ContinueSendingQuestionToSupport(Undefined, RequestParameters_);
		Return;
	EndIf;
	
	// 
	If TechnicalSupportMessagesAreAvailable() Then
		ContinueSendingQuestionToSupport(Undefined, RequestParameters_);
		Return;
	EndIf;
	
	If Form.Items.Find("AssistanceRequiredGroup") <> Undefined Then
		Form.Items.AssistanceRequiredGroup.Hide();
	EndIf;
	
	CompletionHandler = New CallbackDescription(
		"ContinueSendingQuestionToSupport",
		ThisObject,
		RequestParameters_);
	
	RequestToCreateScreenshot(CompletionHandler);
	
EndProcedure

// 
// 
//   
//   
//   
//   
//
// Parameters:
//  Form              - ClientApplicationForm - 
//  RequestParameters_ - See ContactingTechnicalSupportInternalClient.RequestParameters_
//
Procedure DownloadInformationToSendToSupport(Form, RequestParameters_) Export
	
	If Not ScreenshotAppIsAvailable() Then
		ContinueDownloadingInformationToSendToSupport(Undefined, RequestParameters_);
		Return;
	EndIf;
	
	If Form.Items.Find("AssistanceRequiredGroup") <> Undefined Then
		Form.Items.AssistanceRequiredGroup.Hide();
	EndIf;
	
	CompletionHandler = New CallbackDescription(
		"ContinueDownloadingInformationToSendToSupport",
		ThisObject,
		RequestParameters_);
	
	RequestToCreateScreenshot(CompletionHandler);
	
EndProcedure

// 
//
// Returns:
//  Structure:
//    * TechnologicalInfo - String - 
//    * EventLogFilter   - Structure - 
//                                              
//    * Recipient                - See RecipientOfSupportRequest.
//                                  
//    * RecipientAddress           - See AddressOfRecipientOfSupportRequest.
//                                  
//    * Subject                      - String - 
//    * Message                 - See TextOfMessageInSupport.
//                                  
//    * AdditionalFiles       - Array of See ContactingTechnicalSupportInternalClient.AdditionalFileData.
//
Function RequestParameters_() Export
	
	Result = New Structure;
	Result.Insert("TechnologicalInfo", StandardSubsystemsClient.SupportInformation());
	Result.Insert("EventLogFilter",   New Structure);
	Result.Insert("Recipient",                RecipientOfSupportRequest());
	Result.Insert("RecipientAddress",           AddressOfRecipientOfSupportRequest());
	Result.Insert("Subject",                      "");
	Result.Insert("Message",                 TextOfMessageInSupport());
	Result.Insert("AdditionalFiles",       New Array);
	
	Return Result;
	
EndFunction

// 
//
// Parameters:
//  FileAddress - String - 
//  FullFileName - String - 
//
// Returns:
//  Structure:
//    * FileAddress - String
//    * FullFileName - String
//
Function AdditionalFileData(FileAddress, FullFileName) Export
	
	Result = New Structure;
	Result.Insert("FileAddress", FileAddress);
	Result.Insert("FullFileName", FullFileName);
	
	Return Result;
	
EndFunction

#Region ForCallsFromOtherSubsystems

// Standard subsystems.Electronic signature

// 
// 
//
// Returns:
//  Boolean - 
//
Function TechnicalSupportMessagesAreAvailable() Export
	
	SubsystemExists = CommonClient.SubsystemExists(
		"OnlineUserSupport.MessagesToTechSupportService");
	
	WorkWithExternalResourcesIsAvailable =
		ContactingTechnicalSupportInternalServerCall.WorkWithExternalResourcesIsAvailable();
	
	Return SubsystemExists And WorkWithExternalResourcesIsAvailable;
	
EndFunction

// 
//
// Returns:
//  Boolean - 
//
Function ScreenshotAppIsAvailable() Export
	
	Return CommonClient.IsWindowsClient() And ClipboardTools.CanUse();
	
EndFunction

// 
// 
// 
//
// Parameters:
//  CompletionHandler - CallbackDescription, Undefined - 
//                                                             See ContactingTechnicalSupportInternalClient.AdditionalFileData.
//
Procedure RequestToCreateScreenshot(CompletionHandler = Undefined) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CompletionHandler", CompletionHandler);
	
	Notification = New CallbackDescription("AfterRequestToCreateScreenshot", ThisObject, AdditionalParameters);
	
	QueryText = NStr("en = 'Рекомендуется создать снимок экрана. Необходимо выделить весь экран или область с текстом возникшей проблемы.'");
	
	Buttons = New ValueList();
	Buttons.Add(DialogReturnCode.Yes, NStr("en = 'Создать снимок экрана'"));
	Buttons.Add(DialogReturnCode.Ignore, NStr("en = 'Пропустить'"));
	
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.Title = NStr("en = 'Формирование технической информации'");
	QuestionParameters.PromptDontAskAgain = False;
	QuestionParameters.DefaultButton = DialogReturnCode.Yes;
	
	StandardSubsystemsClient.ShowQuestionToUser(Notification, QueryText, Buttons, QuestionParameters);
	
EndProcedure

// End StandardSubsystems.DigitalSignature

#EndRegion

#EndRegion

#Region Private

#Region ScreenShot

Procedure AfterRequestToCreateScreenshot(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Value = DialogReturnCode.Yes Then
		LaunchScreenCaptureApp(AdditionalParameters.CompletionHandler);
		Return;
	EndIf;
	
	If AdditionalParameters.CompletionHandler <> Undefined Then
		RunCallback(AdditionalParameters.CompletionHandler, Undefined);
	EndIf
	
EndProcedure

Procedure LaunchScreenCaptureApp(CompletionHandler = Undefined)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CompletionHandler", CompletionHandler);
	
	ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
	ApplicationStartupParameters.Notification = New CallbackDescription(
		"AfterLaunchingScreenshotApplication",
		ThisObject,
		AdditionalParameters);
	
	FileSystemClient.StartApplication("explorer.exe ms-screenclip:", ApplicationStartupParameters);
	
EndProcedure

Procedure AfterLaunchingScreenshotApplication(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Not Result.ApplicationStarted Then
		ShowMessageBox(, Result.ErrorDescription);
		Return;
	EndIf;
	
	ClearClipboard();
	
	ClipboardProcessingOptions = New Structure;
	ClipboardProcessingOptions.Insert("CurrentAttempt", 0);
	ClipboardProcessingOptions.Insert("MaximumAttempt", 3);
	
	ParametersToSave1 = New Structure;
	ParametersToSave1.Insert("ClipboardProcessingOptions", ClipboardProcessingOptions);
	ParametersToSave1.Insert("CompletionHandler", AdditionalParameters.CompletionHandler);
	
	ParameterName = "StandardSubsystems.ContactingTechnicalSupport";
	ApplicationParameters.Insert(ParameterName, ParametersToSave1);
	
	AttachIdleHandler("ContinueSavingScreenshot", 1, True);
	
EndProcedure

Procedure ClearClipboard()
	
	DataToPut = New ClipboardItem(ClipboardDataStandardFormat.Text, "");
	ClipboardTools.PutDataAsync(DataToPut);
	
EndProcedure

Async Procedure SaveScreenshot() Export
	
	DataFormat = ClipboardDataStandardFormat.Picture;
	ScreenShot = Undefined;
	
	If ClipboardTools.CanUse() Then
		If Await ClipboardTools.ContainsDataAsync(DataFormat) Then
			ScreenShot = Await ClipboardTools.GetDataAsync(DataFormat);
		EndIf;
	EndIf;
	
	ParameterName = "StandardSubsystems.ContactingTechnicalSupport";
	SavedParameters1 = ApplicationParameters[ParameterName];
	
	ClipboardProcessingOptions = SavedParameters1.ClipboardProcessingOptions;
	
	If ScreenShot = Undefined Then
		
		If ClipboardProcessingOptions.CurrentAttempt < ClipboardProcessingOptions.MaximumAttempt Then
			// 
			AttachIdleHandler("ContinueSavingScreenshot", 1, True);
			ClipboardProcessingOptions.CurrentAttempt = ClipboardProcessingOptions.CurrentAttempt + 1;
		Else
			// 
			If SavedParameters1.CompletionHandler <> Undefined Then
				RunCallback(SavedParameters1.CompletionHandler);
			EndIf;
			MessageText = NStr("en = 'Не удалось сохранить снимок экрана.'");
			CommonClient.MessageToUser(MessageText);
		EndIf;
		
		Return;
		
	EndIf;
	
	FileAddress = ContactingTechnicalSupportInternalServerCall.AddressOfScreenshot(ScreenShot);
	SnapshotData = AdditionalFileData(FileAddress, NStr("en = 'Снимок экрана.png'"));
	
	If SavedParameters1.CompletionHandler <> Undefined Then
		RunCallback(SavedParameters1.CompletionHandler, SnapshotData);
	EndIf
	
EndProcedure

#EndRegion

#Region DownloadingInformation

Procedure ContinueDownloadingInformationToSendToSupport(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		AdditionalParameters.AdditionalFiles.Add(Result);
	EndIf;
	
	ArchiveAddress = ContactingTechnicalSupportInternalServerCall.TechnicalInformationArchiveAddress(
		AdditionalParameters);
	
	CompletionHandler = New CallbackDescription(
		"AfterDownloadingInformationToSendToSupport",
		ThisObject,
		New Structure("ArchiveAddress", ArchiveAddress));
	
	FileSystemClient.SaveFile(CompletionHandler, ArchiveAddress, "service_info.zip");
	
EndProcedure

Procedure AfterDownloadingInformationToSendToSupport(SavedFiles, AdditionalParameters) Export
	
	If ValueIsFilled(SavedFiles) Then
		FileSystemClient.OpenExplorer(SavedFiles[0].FullName);
	EndIf;
	
	DeleteFromTempStorage(AdditionalParameters.ArchiveAddress);
	
EndProcedure

#EndRegion

#Region SendingQuestion

Procedure ContinueSendingQuestionToSupport(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		AdditionalParameters.AdditionalFiles.Add(Result);
	EndIf;
	
	If TechnicalSupportMessagesAreAvailable() Then
		
		TheModuleOfTheMessageToTheTechnicalSupportServiceClient = CommonClient.CommonModule(
			"MessagesToTechSupportServiceClient");
		
		TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer = CommonClient.CommonModule(
			"MessagesToTechSupportServiceClientServer");
		
		MessageData = TheModuleOfTheMessageToTheTechnicalSupportServiceClientServer.MessageData();
		MessageData.Recipient = AdditionalParameters.Recipient;
		MessageData.Subject = AdditionalParameters.Subject;
		MessageData.Message = AdditionalParameters.Message;
		
		AttachedFilesForSupport = AttachedFilesInSupport(AdditionalParameters, "Data");
		
		CompletionHandler = New CallbackDescription(
			"AfterSendingQuestionToSupport",
			ThisObject,
			AdditionalParameters);
		
		TheModuleOfTheMessageToTheTechnicalSupportServiceClient.SendMessage(
			MessageData,
			AttachedFilesForSupport,
			,
			CompletionHandler);
		
		Return;
		
	EndIf;
	
	// 
	AfterSendingQuestionToSupport(Undefined, AdditionalParameters);
	
EndProcedure

Procedure AfterSendingQuestionToSupport(Result, AdditionalParameters) Export
	
	If Result <> Undefined And ValueIsFilled(Result.ErrorCode) Then
		
		EventName = NStr("en = 'Работа с почтовыми сообщениями.Отправка вопроса в поддержку'");
		
		EventComment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1 %2'"),
			Result.ErrorCode,
			Result.ErrorMessage);
		
		EventLogClient.AddMessageForEventLog(
			EventName,
			"Error",
			EventComment,
			,
			True);
		
	ElsIf Result <> Undefined Then
		Return;
	EndIf;
	
	If WorkWithMailMessagesIsAvailable() Then
		
		ModuleEmailOperationsClient = CommonClient.CommonModule(
			"EmailOperationsClient");
		
		CompletionHandler = New CallbackDescription(
			"AfterEmailAccountVerified",
			ThisObject,
			AdditionalParameters);
		
		ModuleEmailOperationsClient.CheckAccountForSendingEmailExists(CompletionHandler);
		Return;
		
	EndIf;
	
	// 
	AfterEmailAccountVerified(Undefined, AdditionalParameters);
	
EndProcedure

Procedure AfterEmailAccountVerified(Result, AdditionalParameters) Export
	
	If Result = True Then
		
		ModuleEmailOperationsClient = CommonClient.CommonModule(
			"EmailOperationsClient");
		
		EmailSendOptions = ModuleEmailOperationsClient.EmailSendOptions();
		EmailSendOptions.Recipient = AdditionalParameters.RecipientAddress;
		EmailSendOptions.Subject = AdditionalParameters.Subject;
		EmailSendOptions.Text = TemplateForTextOfMessageInSupport(AdditionalParameters.Message);
		
		Attachments = AttachedFilesInSupport(AdditionalParameters, "AddressInTempStorage");
		EmailSendOptions.Attachments = Attachments;
		
		CompletionHandler = New CallbackDescription(
			"AfterEmailMessageSentToSupport",
			ThisObject,
			EmailSendOptions);
		
		ModuleEmailOperationsClient.CreateNewEmailMessage(EmailSendOptions, CompletionHandler);
		Return;
		
	EndIf;
	
	// 
	ContinueDownloadingInformationToSendToSupport(Undefined, AdditionalParameters);
	
EndProcedure

Procedure AfterEmailMessageSentToSupport(Result, AdditionalParameters) Export
	
	For Each Attachment In AdditionalParameters.Attachments Do
		DeleteFromTempStorage(Attachment.AddressInTempStorage);
	EndDo;
	
EndProcedure

Function RecipientOfSupportRequest()
	
	Return "v8";
	
EndFunction

Function AddressOfRecipientOfSupportRequest()
	
	Return "v8@1c.ru";
	
EndFunction

Function TextOfMessageInSupport()
	
	Return NStr("en = '<Опишите возникшую проблему и приложите скриншоты ошибки.>'");
	
EndFunction

Function TemplateForTextOfMessageInSupport(RequestText_)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Здравствуйте.
			|
			|%1
			|
			|<Укажите ФИО>.'"),
		RequestText_);
	
EndFunction

#EndRegion

#Region Other

// 
//
// Returns:
//  Boolean - 
//
Function WorkWithMailMessagesIsAvailable()
	
	Return CommonClient.SubsystemExists(
		"StandardSubsystems.EmailOperations");
	
EndFunction

Function AttachedFilesInSupport(RequestParameters_, FileAddressKey)
	
	FileAddresses = ContactingTechnicalSupportInternalServerCall.TechnicalInfoFilesAddresses(
		RequestParameters_);
	
	Result = New Array;
	
	FileData = New Structure;
	FileData.Insert(FileAddressKey, FileAddresses.TechnologicalInfo);
	FileData.Insert("Presentation", NStr("en = 'Технологическая информация.txt'"));
	FileData.Insert("DataKind", "Address");
	Result.Add(FileData);
	
	FileData = New Structure;
	FileData.Insert(FileAddressKey, FileAddresses.EventLog);
	FileData.Insert("Presentation", NStr("en = 'Журнал регистрации.xml'"));
	FileData.Insert("DataKind", "Address");
	Result.Add(FileData);
	
	For Each AdditionalFile In RequestParameters_.AdditionalFiles Do
		FileData = New Structure;
		FileData.Insert(FileAddressKey, AdditionalFile.FileAddress);
		FileData.Insert("Presentation", AdditionalFile.FullFileName);
		FileData.Insert("DataKind", "Address");
		Result.Add(FileData);
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
