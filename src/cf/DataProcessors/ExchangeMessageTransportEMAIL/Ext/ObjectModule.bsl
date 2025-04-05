///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ExchangeMessage Export; // For import, it is the name of the file stored in "TempDirectory". For export, the name of the file to be sent out
Var TempDirectory Export; // A temporary exchange directory.
Var DirectoryID Export;
Var Peer Export;
Var ExchangePlanName Export;
Var CorrespondentExchangePlanName Export;
Var ErrorMessage Export;
Var ErrorMessageEventLog Export;

Var NameTemplatesForReceivingMessage Export;
Var NameOfMessageToSend Export;

Var EmailOperationsCommonModule;

#EndRegion

#Region Public

// See DataProcessorObject.ExchangeMessageTransportFILE.SendData
Function SendData(MessageForDataMapping = False) Export
	
	Try
		Result = SendMessage();
	Except
		Result = False;
	EndTry;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.GetData
Function GetData() Export
	
	Try
		
		For Each Template In NameTemplatesForReceivingMessage Do
			
			Result = GetMessage(Template);
			
			If Result Then
				Break;
			EndIf;
			
		EndDo;
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Result = False;
		
	EndTry;
	
	Return Result;

EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.BeforeExportData
Function BeforeExportData(MessageForDataMapping = False) Export
	
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.CorrespondentParameters
Function CorrespondentParameters(ConnectionSettings) Export
	
	Result = ExchangeMessagesTransport.StructureOfResultOfObtainingParametersOfCorrespondent();
	Result.ConnectionIsSet = True;
	Result.ConnectionAllowed = True;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.SaveSettingsInCorrespondent
Function SaveSettingsInCorrespondent(ConnectionSettings) Export
		
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.AuthenticationRequired
Function AuthenticationRequired() Export
	
	Return False;
	
EndFunction

#EndRegion

#Region Private

Function SendMessage()
		
	Result = True;
	
	If CompressOutgoingMessageFile Then
		
		If Not ExchangeMessagesTransport.PackExchangeMessageIntoZipFile(ThisObject, ArchivePasswordExchangeMessages) Then
			Result = False;
		EndIf;
		
		File = New File(ExchangeMessage);
		ReceiverFileName = File.Name;
		
	Else
		
		ReceiverFileName = NameOfMessageToSend;
		
	EndIf;
	
	If Result Then
		
		// Checking that the exchange message size does not exceed the maximum allowed size.
		If DataExchangeServer.ExchangeMessageSizeExceedsAllowed(ExchangeMessage, MaxMessageSize) Then
			ErrorMessage = NStr("en = 'The maximum allowed exchange message size is exceeded.'");
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
			Result = False;
		EndIf;
		
	EndIf;
	
	If Result Then
		
		SimpleBody = NStr("en = 'Data exchange message'");
		
		Result = SendMessagebyEmail(
			SimpleBody,
			ReceiverFileName,
			ExchangeMessage);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function GetMessage(MessageNameTemplate)
	
	ExchangeMessagesTable = ExchangeMessagesTable();
	
	ColumnsArray1 = New Array;
	
	ImportParameters = New Structure;
	ImportParameters.Insert("GetHeaders", True);
	ImportParameters.Insert("CastMessagesToType", False);
	
	Try
		MessageSet = EmailOperationsCommonModule.DownloadEmailMessages(Account, ImportParameters);
	Except
		
		ErrorMessage = NStr("en = 'Error receiving message headers from the email server.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndTry;
		
	For Each MailMessage In MessageSet Do
		
		Subject = TrimAll(MailMessage.Subject);
		Subject = StrReplace(Subject, Chars.Tab, "");
		
		NewRow = ExchangeMessagesTable.Add();
		NewRow.Subject = Subject;
		NewRow.PostingDate = MailMessage.PostingDate;
		NewRow.RowID = String(New UUID);
		NewRow.Id.Add(MailMessage);
		
	EndDo;

	Query = New Query;
	Query.Text = 
		"SELECT
		|	T.RowID AS RowID,
		|	T.PostingDate AS PostingDate,
		|	T.Subject AS Subject
		|INTO TT
		|FROM
		|	&ExchangeMessagesTable AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT.RowID AS RowID
		|FROM
		|	TT AS TT
		|WHERE
		|	TT.Subject LIKE &Template
		|
		|ORDER BY
		|	TT.PostingDate DESC";
	
	// Search ignoring the extension
	Position = StrFind(MessageNameTemplate, ".", SearchDirection.FromEnd);
	MessageNameTemplateForSearching = Left(MessageNameTemplate,  Position - 1);
	MessageNameTemplateForSearching = "%" + StrReplace(MessageNameTemplateForSearching, "*", "%") + "%";
	
	Query.SetParameter("ExchangeMessagesTable", ExchangeMessagesTable);
	Query.SetParameter("Template", MessageNameTemplateForSearching);
	
	EmailSearchResults = Query.Execute().Unload(); 
	
	If EmailSearchResults.Count() = 0 Then
		
		ErrorMessage = NStr("en = 'The messages with ""%1"" header are not found.'");
		ErrorMessage = StrTemplate(ErrorMessage, MessageNameTemplate);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndIf;
	
	ColumnsArray1 = New Array;
	ColumnsArray1.Add("Attachments");
	
	Id = ExchangeMessagesTable.Find(EmailSearchResults[0].RowID).Id;
	
	ImportParameters = New Structure;
	ImportParameters.Insert("Columns", ColumnsArray1);
	ImportParameters.Insert("HeadersIDs", Id);
		
	Try
		MessageSet = EmailOperationsCommonModule.DownloadEmailMessages(Account, ImportParameters);
	Except
		
		ErrorMessage = NStr("en = 'Error receiving the message from the email server.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndTry;

	BinaryData = Undefined;
	For Each KeyAndValue In MessageSet[0].Attachments Do
		FilePacked = Upper(Right(KeyAndValue.Key, 3)) = "ZIP";
		BinaryData = KeyAndValue.Value;
	EndDo;
	
	If BinaryData = Undefined Then
		
		ErrorMessage = NStr("en = 'Error: no exchange message file is found in the email message.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndIf;
		
	If FilePacked Then
		
		// Getting the temporary archive file name.
		ArchiveTempFileName = CommonClientServer.GetFullFileName(
			ExchangeMessage, String(New UUID) + ".zip");
		
		BinaryData.Write(ArchiveTempFileName);
		
		If Not ExchangeMessagesTransport.UnzipExchangeMessageFromZipFile(
			ThisObject, ArchiveTempFileName, ArchivePasswordExchangeMessages) Then
			
			Return False;
			
		EndIf;
	
	Else
		
		Try
			BinaryData.Write(ExchangeMessage);
		Except
			
			ErrorMessage = NStr("en = 'Error saving the exchange message file to the hard drive.'");
			ErrorMessageEventLog = ErrorMessage;
		
			ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
			
			Return False;
			
		EndTry;
		
	EndIf;
	
	Return True;
	
EndFunction

Function ConnectionIsSet() Export
	
	If Not ValueIsFilled(Account) Then
		ErrorMessage = NStr("en = 'Initialization error: the exchange message transport email account is not specified.'");
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function ExchangeMessagesTable()
	
	ExchangeMessagesTable = New ValueTable;
	ExchangeMessagesTable.Columns.Add("RowID", New TypeDescription("String",,,, New StringQualifiers(36)));
	ExchangeMessagesTable.Columns.Add("Id",   New TypeDescription("Array"));
	ExchangeMessagesTable.Columns.Add("PostingDate", New TypeDescription("Date"));
	ExchangeMessagesTable.Columns.Add("Subject", New TypeDescription("String",,,, New StringQualifiers(200)));
	
	Return ExchangeMessagesTable;
	
EndFunction

Function SendMessagebyEmail(Body, OutgoingMessageFileName, PathToFile)
	
	AttachmentDetails = New Structure;
	AttachmentDetails.Insert("Presentation", OutgoingMessageFileName);
	AttachmentDetails.Insert("AddressInTempStorage", PutToTempStorage(New BinaryData(PathToFile)));
	
	Email = Common.ObjectAttributeValue(Account, "Email");
	
	MessageSubject1 = "Exchange message (%1)"; // Non-localizable string.
	MessageSubject1 = StrTemplate(MessageSubject1, OutgoingMessageFileName);
	
	MessageParameters = New Structure;
	MessageParameters.Insert("Whom",     Email);
	MessageParameters.Insert("Subject",     MessageSubject1);
	MessageParameters.Insert("Body",     Body);
	MessageParameters.Insert("Attachments", New Array);
	
	MessageParameters.Attachments.Add(AttachmentDetails);
	
	Try
		NewEmail = EmailOperationsCommonModule.PrepareEmail(Account, MessageParameters);
		EmailOperationsCommonModule.SendMail(Account, NewEmail);
	Except
		
		ErrorMessage = NStr("en = 'Error sending the email message.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Return False;
		
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#Region Initialize

TempDirectory = Undefined;
MessagesOfExchange  = Undefined;

If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
	EmailOperationsCommonModule = Common.CommonModule("EmailOperations");
EndIf;

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.'");
#EndIf