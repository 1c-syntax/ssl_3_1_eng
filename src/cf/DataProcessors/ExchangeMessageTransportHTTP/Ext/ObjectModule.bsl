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

#EndRegion

#Region Public

// See DataProcessorObject.ExchangeMessageTransportFILE.SendData
Function SendData(MessageForDataMapping = False) Export
	
	Try
		Result = SendExchangeMessage(MessageForDataMapping);
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Result = False;
		
	EndTry;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.GetData
Function GetData() Export

	Try
		Result = GetExchangeMessage();
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Result = False;
		
	EndTry;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.CorrespondentParameters
Function CorrespondentParameters(ConnectionSettings) Export
	
	Result = ExchangeMessagesTransport.StructureOfResultOfObtainingParametersOfCorrespondent();
	Result.Insert("CorrespondentExchangePlanName", CorrespondentExchangePlanName);
	
	HTTPConnection = HTTPConnection();
	
	Parameters = New Structure;
	Parameters.Insert("ExchangePlanName", CorrespondentExchangePlanName);
	Parameters.Insert("NodeCode", ExchangePlans[ExchangePlanName].ThisNode().Code);
	Parameters.Insert("IsXDTOExchangePlan", DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName));
	Parameters.Insert("SettingID", ConnectionSettings.SettingID);
	
	Response = ExecuteHTTPRequest(HTTPConnection, "GET", "GetIBParameters", Parameters);
	
	If AnswerIsMistake(Response) Then
		
		Result.ConnectionIsSet = False;
		Result.ErrorMessage = ErrorMessage;
		
		Return Result;

	EndIf;
	
	Body = Response.GetBodyAsString();
	QueryResult = ExchangeMessagesTransport.JSONValue(Body);
		
	CorrespondentParameters = New Structure;
	
	CorrespondentParameters.Insert("ExchangePlanExists", QueryResult["ExchangePlanExists"]);
	CorrespondentParameters.Insert("InfobasePrefix", QueryResult["InfobasePrefix"]);
	CorrespondentParameters.Insert("DefaultInfobasePrefix", QueryResult["DefaultInfobasePrefix"]);
	CorrespondentParameters.Insert("InfobaseDescription", QueryResult["InfobaseDescription"]);
	CorrespondentParameters.Insert("DefaultInfobaseDescription", QueryResult["DefaultInfobaseDescription"]);
	CorrespondentParameters.Insert("AccountingParametersSettingsAreSpecified", QueryResult["AccountingParametersSettingsAreSpecified"]);
	CorrespondentParameters.Insert("ThisNodeCode", QueryResult["ThisNodeCode"]); 
	CorrespondentParameters.Insert("ConfigurationVersion", QueryResult["ConfigurationVersion"]);
	CorrespondentParameters.Insert("NodeExists", QueryResult["NodeExists"]);
	CorrespondentParameters.Insert("DataExchangeSettingsFormatVersion", QueryResult["DataExchangeSettingsFormatVersion"]);
	CorrespondentParameters.Insert("UsePrefixesForExchangeSettings", QueryResult["UsePrefixesForExchangeSettings"]);
	CorrespondentParameters.Insert("ExchangeFormat", QueryResult["ExchangeFormat"]);
	CorrespondentParameters.Insert("ExchangePlanName", QueryResult["ExchangePlanName"]);
	CorrespondentParameters.Insert("ExchangeFormatVersions", QueryResult["ExchangeFormatVersions"]);
	CorrespondentParameters.Insert("DataSynchronizationSetupCompleted", QueryResult["DataSynchronizationSetupCompleted"]);
	CorrespondentParameters.Insert("MessageReceivedForDataMapping", QueryResult["MessageReceivedForDataMapping"]);
	CorrespondentParameters.Insert("DataMappingSupported", QueryResult["DataMappingSupported"]);
	
	If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
		
		FormatObjects = ExchangeMessagesTransport.TableFromArray_SupportedObjectsInFormat(
			QueryResult["SupportedObjectsInFormat"],
			QueryResult["ExchangeFormatVersions"]);
	
		CorrespondentParameters.Insert("SupportedObjectsInFormat", FormatObjects);
		
	EndIf;

	Result.ConnectionIsSet = False;
	
 	If Not CorrespondentParameters.ExchangePlanExists Then
		
		Text = NStr("en = 'Exchange plan ""%1"" is not found in the peer application.
			|Ensure that the following data is correct:
			|- The application type selected in the exchange settings.
			|- The web application address.';");
		
		ErrorMessage = StrTemplate(Text, ExchangePlanName);
		
		Result.ConnectionIsSet = False;
		Result.ErrorMessage = ErrorMessage;
		
		Return Result;
		
	EndIf;
	
	Result.CorrespondentParametersReceived = True;
	Result.CorrespondentParameters = CorrespondentParameters;
	Result.CorrespondentExchangePlanName = CorrespondentParameters.ExchangePlanName;
	Result.ConnectionIsSet = True;
	
	Cancel = False;
	ErrorMessage = "";
	
	ConfigurationVersion = Result.CorrespondentParameters.ConfigurationVersion;
	
	ExchangeMessagesTransport.OnConnectToCorrespondent(Cancel, ExchangePlanName, ConfigurationVersion, ErrorMessage);
		
	If Cancel Then
		
		Result.ConnectionAllowed = False;
		Result.ErrorMessage = ErrorMessage;
		
		Return Result;
		
	EndIf;
	
	ExchangeMessagesTransport.CheckForDuplicateSyncs(ExchangePlanName, CorrespondentParameters, Result);
	
	Result.ConnectionAllowed = True;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.BeforeExportData
Function BeforeExportData(MessageForDataMapping = False) Export
	
	Return ConnectionIsSet();
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.SaveSettingsInCorrespondent
Function SaveSettingsInCorrespondent(ConnectionSettings) Export
	
	HTTPConnection = HTTPConnection();
	
	ConnectionSettingsINJSON = ExchangeMessagesTransport.ConnectionSettingsINJSON(ConnectionSettings);
	
	Response = ExecuteHTTPRequest(HTTPConnection, "POST", "CreateExchangeNode", , ConnectionSettingsINJSON);
	
	If AnswerIsMistake(Response) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.AuthenticationRequired
Function AuthenticationRequired() Export
	
	Return Not RememberPassword;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.DeleteSynchronizationSettingInCorrespondent
Function DeleteSynchronizationSettingInCorrespondent() Export
	
	HTTPConnection = HTTPConnection();
	
	Parameters = New Structure;
	Parameters.Insert("ExchangePlanName", CorrespondentExchangePlanName);
	Parameters.Insert("NodeCode", ExchangePlans[ExchangePlanName].ThisNode().Code);
	
	Response = ExecuteHTTPRequest(HTTPConnection, "DELETE", "RemoveExchangeNode", Parameters);
	
	If AnswerIsMistake(Response) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionIsSet() Export
	
	HTTPConnection = HTTPConnection();
	
	URIStructure = CommonClientServer.URIStructure(WebServiceAddress);
	ResourceAddress = URIStructure.PathAtServer + "/hs/exchange_dsl_1_0_0_1/version";
		
	Headers = New Map();
	Query = New HTTPRequest(ResourceAddress, Headers);
	
	Response = HTTPConnection.Get(Query);
	
	If Response.StatusCode = 200 Then
		
		Return True;
		
	Else
		
		ErrorMessage = NStr("en = 'User authentication failed.';");
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject,,Response.GetBodyAsString());
		
		Return False;
		
	EndIf;
	
EndFunction

Function SendExchangeMessage(MessageForDataMapping)
		
	HTTPConnection = HTTPConnection(180);
	
	If Not ValueIsFilled(Peer) Then
		UIDFileID = PutFileInStorageInService(HTTPConnection, ExchangeMessage, 1024);
		Return True;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("ExchangePlanName", CorrespondentExchangePlanName);
	Parameters.Insert("NodeCode", ExchangePlans[ExchangePlanName].ThisNode().Code);
	Parameters.Insert("IsXDTOExchangePlan", DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName));
	
	Response = ExecuteHTTPRequest(HTTPConnection, "GET", "GetIBParameters", Parameters);
	
	If AnswerIsMistake(Response, "DataExport") Then
		Return False;
	EndIf;
	
	Body = Response.GetBodyAsString();
	SetupStatus = ExchangeMessagesTransport.JSONValue(Body);
	UIDFileID = PutFileInStorageInService(HTTPConnection, ExchangeMessage, 1024);
	
	FileIDAsString = String(UIDFileID);
	
	If MessageForDataMapping
		And (SetupStatus["DataMappingSupported"]
		Or Not SetupStatus["DataSynchronizationSetupCompleted"]) Then
			
		Parameters = New Structure;
		Parameters.Insert("ExchangePlanName", CorrespondentExchangePlanName);
		Parameters.Insert("NodeCode", ExchangePlans[ExchangePlanName].ThisNode().Code);
		Parameters.Insert("FileID", FileIDAsString);
		
		Response = ExecuteHTTPRequest(HTTPConnection, "POST", "PutMessageForDataMatching", Parameters);
		
		If AnswerIsMistake(Response, "DataExport") Then
			Return False;
		EndIf;
		
	Else
		
		Parameters = New Structure;
		Parameters.Insert("ExchangePlanName", CorrespondentExchangePlanName);
		Parameters.Insert("NodeCode", ExchangePlans[ExchangePlanName].ThisNode().Code);
		Parameters.Insert("FileID", FileIDAsString);
		Parameters.Insert("TimeConsumingOperationAllowed", True);
		
		Response = ExecuteHTTPRequest(HTTPConnection, "POST", "DownloadData", Parameters);
		
		Body = Response.GetBodyAsString();
		
		If AnswerIsMistake(Response, "DataExport") Then
			Return False;
		EndIf;
		
		Result = ExchangeMessagesTransport.JSONValue(Body);
		
		ExchangeParameters = DataExchangeServer.ExchangeParameters();
		ExchangeParameters.TheTimeoutOnTheServer = 15;
		ExchangeParameters.TimeConsumingOperation = Result["TimeConsumingOperation"];
		ExchangeParameters.OperationID = Result["OperationID"];
		
		If ExchangeParameters.TimeConsumingOperation Then
			
			WaitingForTheOperationToComplete(HTTPConnection, ExchangeParameters, Enums.ActionsOnExchange.DataExport);
			
		EndIf;
		
	EndIf;
		
	Return True;
	
EndFunction

Function PutFileInStorageInService(HTTPConnection, Val FileName, 
	Val PartSizeKB = 1024, FileID = Undefined) Export
	
	If HTTPConnection = Undefined Then
		
		Raise NStr("en = 'The WS proxy of transferring the export file to the destination infobase is not defined. 
			|Contact the administrator.';", Common.DefaultLanguageCode());
		
	EndIf;
	
	FilesDirectory = GetTempFileName();
	CreateDirectory(FilesDirectory);
	
	// Archive the file.
	SharedFileName = CommonClientServer.GetFullFileName(FilesDirectory, "data.zip");
	Archiver = New ZipFileWriter(SharedFileName,,,, ZIPCompressionLevel.Maximum);
	Archiver.Add(FileName);
	Archiver.Write();
	
	// Splitting a file into parts.
	SessionID = New UUID;
	
	TheSizeOfThePartInBytes = PartSizeKB * 1024;
	FilesNames = SplitFile(SharedFileName, TheSizeOfThePartInBytes);
		
	PartCount = FilesNames.Count();
	For PartNumber = 1 To PartCount Do
		
		PartFileName = FilesNames[PartNumber - 1];
		FileData = New BinaryData(PartFileName);

		Parameters = New Structure;
		Parameters.Insert("SessionID", SessionID);
		Parameters.Insert("PartNumber", PartNumber);
		
		Response = ExecuteHTTPRequest(HTTPConnection, "POST", "PutFilePart", Parameters, FileData);
		
		If AnswerIsMistake(Response, "DataExport") Then
			Return False;
		EndIf;
		
	EndDo;
	
	Try
		DeleteFiles(FilesDirectory);
	Except
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
		
	Parameters = New Structure;
	Parameters.Insert("SessionID", SessionID);
	Parameters.Insert("PartCount", PartCount);
	
	Response = ExecuteHTTPRequest(HTTPConnection, "POST", "SaveFileFromParts", Parameters);
	
	If AnswerIsMistake(Response, "DataExport") Then
		Return False;
	EndIf;
	
	Body = Response.GetBodyAsString();
	Result = ExchangeMessagesTransport.JSONValue(Body);
	
	Return Result["FileID"]; 
	
EndFunction

Procedure WaitingForTheOperationToComplete(HTTPConnection, ExchangeParameters, ActionWhenExchangingInThisInformationSystem = Undefined) Export
	
	If ExchangeParameters.TheTimeoutOnTheServer = 0 Then
		
		If ActionWhenExchangingInThisInformationSystem <> Undefined Then
			
			// For this infobase, "Import". Therefore, for the peer infobase, "Export".
			If ActionWhenExchangingInThisInformationSystem = Enums.ActionsOnExchange.DataImport Then
				
				ActionInTheCorrespondentLine = NStr("en = 'export';", Common.DefaultLanguageCode());
				
			Else
				
				ActionInTheCorrespondentLine = NStr("en = 'import';", Common.DefaultLanguageCode());
				
			EndIf;
			
			MessageTemplate = NStr("en = 'Waiting for the operation to be executed (%1 of the data in the peer infobase)…';", Common.DefaultLanguageCode());
			Message = StrTemplate(MessageTemplate, ActionInTheCorrespondentLine);
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject,, Message, False);
			
		EndIf;
		
		Return;
		
	EndIf;
	
	While ExchangeParameters.TimeConsumingOperation Do // Replace recursion.
		
		DataExchangeServer.Pause(ExchangeParameters.TheTimeoutOnTheServer);
		
		ErrorMessageString = "";
			
		Parameters = New Structure;
		Parameters.Insert("OperationID",  ExchangeParameters.OperationID);
		
		Response = ExecuteHTTPRequest(HTTPConnection, "GET", "GetContinuousOperationStatus", Parameters);
		
		If AnswerIsMistake(Response) Then
			ActionState = "";
		Else
			Body = Response.GetBodyAsString();
			Result = ExchangeMessagesTransport.JSONValue(Body);
			ActionState = Result["ActionState"];
		EndIf;
			
		If ActionState = "Active" Then
			
			ExchangeParameters.TheTimeoutOnTheServer = Min(ExchangeParameters.TheTimeoutOnTheServer + 30, 180);
			
		ElsIf ActionState = "Completed" Then
			
			ExchangeParameters.TheTimeoutOnTheServer = 15;
			ExchangeParameters.TimeConsumingOperation = False; 
			ExchangeParameters.OperationID = Undefined;
			
		Else
			
			Raise StrTemplate(NStr("en = 'Peer infobase error: %1 %2';"), Chars.LF, ErrorMessageString);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function GetExchangeMessage()
	
	HTTPConnection = HTTPConnection(180);
	
	If Not ValueIsFilled(Peer) Then
		ExchangeMessage = GetFileFromStorageInService(HTTPConnection, NameTemplatesForReceivingMessage[0], 1024);
		Return True;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("ExchangePlanName", CorrespondentExchangePlanName);
	Parameters.Insert("NodeCode", ExchangePlans[ExchangePlanName].ThisNode().Code);
	Parameters.Insert("TimeConsumingOperationAllowed", True);
	
	Response = ExecuteHTTPRequest(HTTPConnection, "POST", "UploadData", Parameters);
	
	If AnswerIsMistake(Response, "DataImport") Then
		Return False;
	EndIf;
	
	Body = Response.GetBodyAsString();
	
	Result = ExchangeMessagesTransport.JSONValue(Body);
		
	ExchangeParameters = DataExchangeServer.ExchangeParameters();
	ExchangeParameters.TimeConsumingOperationAllowed = True;
	ExchangeParameters.TheTimeoutOnTheServer = 15;
	ExchangeParameters.FileID = Result["FileID"];
	ExchangeParameters.TimeConsumingOperation = Result["TimeConsumingOperation"];
	ExchangeParameters.OperationID = Result["OperationID"];
	
	If ExchangeParameters.TimeConsumingOperation Then
		
		WaitingForTheOperationToComplete(HTTPConnection, ExchangeParameters, Enums.ActionsOnExchange.DataImport);
		
	EndIf;
	
	UIDOfTheMessageFile = New UUID(ExchangeParameters.FileID);
	
	ExchangeMessage = GetFileFromStorageInService(HTTPConnection, UIDOfTheMessageFile, 1024);
		
	If AnswerIsMistake(Response, "DataImport") Then
		Return False;
	EndIf;
		
	Return True;
	
EndFunction

Function GetFileFromStorageInService(HTTPConnection, Val FileID, Val PartSize = 1024) Export
	
	// Function return value.
	ResultFileName = "";
	
	Parameters = New Structure;
	Parameters.Insert("FileID", FileID);
	Parameters.Insert("BlockSize", Format(PartSize, "NG="));
	
	Response = ExecuteHTTPRequest(HTTPConnection, "POST", "PrepareGetFile", Parameters);
	
	If AnswerIsMistake(Response, "DataImport") Then
		Return False;
	EndIf;
	
	Body = Response.GetBodyAsString();
	
	Result = ExchangeMessagesTransport.JSONValue(Body);
	
	SessionID = Result["SessionID"];
	PartCount = Result["PartCount"];
	
	FilesNames = New Array;
	
	BuildDirectory = GetTempFileName();
	CreateDirectory(BuildDirectory);
	
	FileNameTemplate = "data.zip.[n]";
	
	MessageTemplate = NStr("en = 'Start receiving an exchange message from the Internet. The message is split into %1 parts.';");
	Message = StrTemplate(MessageTemplate, Format(PartCount, "NZ=0; NG=0"));
	ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport", Message, False);
		
	For PartNumber = 1 To PartCount Do
		PartData = Undefined; // BinaryData
		
		Parameters = New Structure;
		Parameters.Insert("SessionID", SessionID);
		Parameters.Insert("PartNumber", PartNumber);
		
		Response = ExecuteHTTPRequest(HTTPConnection, "GET", "GetFilePart", Parameters);
		
		If AnswerIsMistake(Response, "DataImport") Then
			
			Parameters = New Structure;
			Parameters.Insert("SessionID", SessionID);
			
			ExecuteHTTPRequest(HTTPConnection, "DELETE", "ReleaseFile", Parameters);
			
			Return False;
			
		Else
			
			PartData = Response.GetBodyAsBinaryData();
			
		EndIf;
		
		FileName = StrReplace(FileNameTemplate, "[n]", Format(PartNumber, "NG=0"));
		PartFileName = CommonClientServer.GetFullFileName(BuildDirectory, FileName);
		
		PartData.Write(PartFileName);
		FilesNames.Add(PartFileName);
		
	EndDo;
	
	PartData = Undefined;
		
	Parameters = New Structure;
	Parameters.Insert("SessionID", SessionID);
			
	Response = ExecuteHTTPRequest(HTTPConnection, "DELETE", "ReleaseFile", Parameters);
			
	If AnswerIsMistake(Response, "DataImport") Then
		Return False;
	EndIf;
	
	ArchiveName = CommonClientServer.GetFullFileName(BuildDirectory, "data.zip");
	
	MergeFiles(FilesNames, ArchiveName);
		
	Dearchiver = New ZipFileReader(ArchiveName);
	If Dearchiver.Items.Count() = 0 Then
		Try
			DeleteFiles(BuildDirectory);
		Except
			ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		EndTry;
		Raise(NStr("en = 'The archive file is empty.';"));
	EndIf;
	
	// Log exchange events.
	ArchiveFile1 = New File(ArchiveName);
	
	MessageTemplate = NStr("en = 'Complete receiving an exchange message from the Internet. Compressed message size: %1 MB.';");
	Message = StrTemplate(MessageTemplate, Format(Round(ArchiveFile1.Size() / 1024 / 1024, 3), "NZ=0; NG=0"));
	ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport", Message, False);
	
	ArchiveItem = Dearchiver.Items.Get(0);
	FileName = CommonClientServer.GetFullFileName(BuildDirectory, ArchiveItem.Name);
	
	Dearchiver.Extract(ArchiveItem, BuildDirectory);
	Dearchiver.Close();
	
	File = New File(FileName);
	
	TempDirectory = GetTempFileName(); //ACC:441 удаление каталога происходит при получении данных обмена в другой ИБ
	CreateDirectory(TempDirectory);
	
	ResultFileName = CommonClientServer.GetFullFileName(TempDirectory, File.Name);
	
	MoveFile(FileName, ResultFileName);
	
	Try
		DeleteFiles(BuildDirectory);
	Except
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
	EndTry;
		
	Return ResultFileName;
	
EndFunction

Function HTTPConnection(Timeout = 20)
	
	URIStructure = CommonClientServer.URIStructure(WebServiceAddress);
	
	If Lower(URIStructure.Schema) = Lower("https") Then
		SecureConnection = CommonClientServer.NewSecureConnection();
	Else
		SecureConnection = Undefined;
	EndIf;
	
	Proxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		Proxy = ModuleNetworkDownload.GetProxy(URIStructure.Schema);
	EndIf;
	
	Return New HTTPConnection(URIStructure.ServerName,,UserName, Password, Proxy, Timeout, SecureConnection);
	
EndFunction

Function ExecuteHTTPRequest(HTTPConnection, RequestType, Method, Parameters = Undefined, Body = Undefined)
	
	URIStructure = CommonClientServer.URIStructure(WebServiceAddress);
		
	ResourceAddressTemplate = "/%1/hs/exchange_dsl_1_0_0_1/v1/%2?%3";
	ParametersByString = "";
	
	If ValueIsFilled(Parameters) Then
		
		For Each KeyAndValue In Parameters Do
		
			If ParametersByString <> "" Then
				ParametersByString = ParametersByString + "&"
			EndIf;
			
			ParametersByString = ParametersByString + KeyAndValue.Key + "=" + KeyAndValue.Value
		
		EndDo;
		
	EndIf;
	
	ResourceAddress = StrTemplate(ResourceAddressTemplate, URIStructure.PathAtServer, Method, ParametersByString); 
	
	Headers = New Map();
	Query = New HTTPRequest(ResourceAddress, Headers);
	
	If TypeOf(Body) = Type("String") Then
		Query.SetBodyFromString(Body);
	ElsIf TypeOf(Body) = Type("BinaryData") Then
		Query.SetBodyFromBinaryData(Body);
	EndIf;
	
	If Lower(RequestType) = "post" Then 
		Response = HTTPConnection.Post(Query);
	ElsIf Lower(RequestType) = "get" Then 
		Response = HTTPConnection.Get(Query);
	ElsIf Lower(RequestType) = "delete" Then
		Response = HTTPConnection.Delete(Query);
	EndIf;
	
	Return Response;
	
EndFunction

Function AnswerIsMistake(Response, ActionOnExchange = Undefined)
	
	If Response.StatusCode <> 200 Then
		
		Body = Response.GetBodyAsString();
		
		Try
			ErrorMessage = ExchangeMessagesTransport.JSONValue(Body)["message"];
		Except
			ErrorMessage = Body;
		EndTry;
		
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, ActionOnExchange);
		
		Return True;
		
	Else
		
		Return False;
	
	EndIf;
	
EndFunction

#EndRegion

#Region Initialize

TempDirectory = Undefined;
MessagesOfExchange = Undefined;

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf