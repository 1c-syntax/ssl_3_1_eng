///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Internal

// The function downloads the file from the file transfer service by the passed ID.
//
// Parameters:
//  FileID       - UUID - an ID of the file being received.
//  InfobaseNode   - ExchangePlanRef - The exchange plan node that should receive the file.
//  PartSize              - Number - Chunk size in kilobytes. If the passed value is 0,
//                             the file is not split into chunks.
//  AuthenticationParameters - Structure: ServiceAddress, UserName, UserPassword.
//
// Returns:
//  String - The path to the received file.
//
Function GetFileFromStorageInService(Proxy, Val FileID, Val InfobaseNode = Undefined,
	Val PartSize = 1024, Val DataArea = 0) Export
	
	// Function return value.
	ResultFileName = "";
	
	SessionID = Undefined;
	PartCount    = Undefined;
	
	PrepareFileForReceipt(Proxy, FileID, PartSize, SessionID, PartCount, DataArea);
	
	FilesNames = New Array;
	
	BuildDirectory = GetTempFileName();
	CreateDirectory(BuildDirectory);
	
	FileNameTemplate = "data.zip.[n]";
	
	// Log exchange events.
	If ValueIsFilled(InfobaseNode) Then
		
		ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
			InfobaseNode, Enums.ActionsOnExchange.DataExport);

		ExchangeSettingsStructure.EventLogMessageKey = DataExchangeServer.EventLogMessageKey(
			InfobaseNode, Enums.ActionsOnExchange.DataImport);
		
		Comment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Start receiving an exchange message from the Internet. The message is split into %1 parts.'"),
			Format(PartCount, "NZ=0; NG=0"));
			
		DataExchangeServer.WriteEventLogDataExchange(Comment, ExchangeSettingsStructure);
		
	EndIf;
	
	For PartNumber = 1 To PartCount Do
		
		PartData = Undefined; // BinaryData
		
		Try
			GetFileChunk(Proxy, SessionID, PartNumber, PartData, DataArea);
		Except
			Proxy.ReleaseFile(SessionID);
			Raise;
		EndTry;
		
		FileName = StrReplace(FileNameTemplate, "[n]", Format(PartNumber, "NG=0"));
		PartFileName = CommonClientServer.GetFullFileName(BuildDirectory, FileName);
		
		PartData.Write(PartFileName);
		FilesNames.Add(PartFileName);
		
	EndDo;
	
	PartData = Undefined;
	
	Proxy.ReleaseFile(SessionID);
	
	ArchiveName = CommonClientServer.GetFullFileName(BuildDirectory, "data.zip");
	
	MergeFiles(FilesNames, ArchiveName);
		
	Dearchiver = New ZipFileReader(ArchiveName);
	If Dearchiver.Items.Count() = 0 Then
		Try
			DeleteFiles(BuildDirectory);
		Except
			WriteLogEvent(TempFileDeletionEventLogEvent(),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		Raise(NStr("en = 'The archive file is empty.'"));
	EndIf;
	
	// Log exchange events.
	ArchiveFile1 = New File(ArchiveName);
	
	If ValueIsFilled(InfobaseNode) Then
	
		Comment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Complete receiving an exchange message from the Internet. Compressed message size: %1 MB.'"),
			Format(Round(ArchiveFile1.Size() / 1024 / 1024, 3), "NZ=0; NG=0"));
			
		DataExchangeServer.WriteEventLogDataExchange(Comment, ExchangeSettingsStructure);
	
	EndIf;
	
	ArchiveItem = Dearchiver.Items.Get(0);
	FileName = CommonClientServer.GetFullFileName(BuildDirectory, ArchiveItem.Name);
	
	Dearchiver.Extract(ArchiveItem, BuildDirectory);
	Dearchiver.Close();
	
	File = New File(FileName);
	
	TempDirectory = GetTempFileName(); //ACC:441 - The directory is deleted when the peer infobase receives the exchange data
	CreateDirectory(TempDirectory);
	
	ResultFileName = CommonClientServer.GetFullFileName(TempDirectory, File.Name);
	
	MoveFile(FileName, ResultFileName);
	
	Try
		DeleteFiles(BuildDirectory);
	Except
		WriteLogEvent(TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
		
	Return ResultFileName;
	
EndFunction

// Passes the specified file to the file transfer service.
//
// Parameters:
//  Proxy
//  ExchangeSettingsStructure - Structure - a structure with all necessary data and objects to execute the exchange.
//  FileName                 - String - Path to the transferred file.
//  InfobaseNode - ExchangePlanRef - The recipient exchange node. 
//  PartSizeKB            - Number - part size in kilobytes. If the passed value is 0,
//                             the file is not split into parts.
//  FileID       - UUID - The id of the file being uploaded to the service.
//
// Returns:
//  UUID  - The id of the file in the file transfer service.
//
Function PutFileInStorageInService(Proxy, Val FileName, 
	Val PartSizeKB = 1024, FileID = Undefined, DataArea = 0) Export
	
	If Proxy = Undefined Then
		
		Raise NStr("en = 'The WS proxy of transferring the export file to the destination infobase is not defined. 
			|Contact the administrator.'", Common.DefaultLanguageCode());
		
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
		PutFileChunk(Proxy, SessionID, PartNumber, FileData, DataArea);
		
	EndDo;
	
	Try
		DeleteFiles(FilesDirectory);
	Except
		WriteLogEvent(TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	AssembleFileFromParts(Proxy, SessionID, PartCount, FileID, DataArea);
	
	Return FileID;
	
EndFunction

Function GetWSProxyByConnectionParameters(
					SettingsStructure_,
					ErrorMessageString = "",
					UserMessage = "",
					ProbingCallRequired = False) Export
	
	Try
		CheckWSProxyAddressFormatCorrectness(SettingsStructure_.WSWebServiceURL);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessageString);
		Return Undefined;
	EndTry;

	Try
		CheckProhibitedCharsInWSProxyUsername(SettingsStructure_.WSUserName);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessageString);
		Return Undefined;
	EndTry;
	
	WSDLLocation = "[WebServiceURL]/ws/[ServiceName]?wsdl";
	WSDLLocation = StrReplace(WSDLLocation, "[WebServiceURL]", SettingsStructure_.WSWebServiceURL);
	WSDLLocation = StrReplace(WSDLLocation, "[ServiceName]",    SettingsStructure_.WSServiceName);
	
	ConnectionParameters = Common.WSProxyConnectionParameters();
	ConnectionParameters.WSDLAddress = WSDLLocation;
	ConnectionParameters.NamespaceURI = SettingsStructure_.WSServiceNamespaceURL;
	ConnectionParameters.ServiceName = SettingsStructure_.WSServiceName;
	ConnectionParameters.UserName = SettingsStructure_.WSUserName; 
	ConnectionParameters.Password = SettingsStructure_.WSPassword;
	ConnectionParameters.Timeout = SettingsStructure_.WSTimeout;
	ConnectionParameters.ProbingCallRequired = ProbingCallRequired;
	
	Try
		WSProxy = Common.CreateWSProxy(ConnectionParameters);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessageString);
		Return Undefined;
	EndTry;
	
	Return WSProxy;
EndFunction

Function WSProxy(ConnectionParameters, ErrorMessage = "", UserMessage = "") Export
	
	Try
		CheckWSProxyAddressFormatCorrectness(ConnectionParameters.WebServiceAddress);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessage);
		Return Undefined;
	EndTry;

	Try
		CheckProhibitedCharsInWSProxyUsername(ConnectionParameters.UserName);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessage);
		Return Undefined;
	EndTry;

	Try
		SettingsStructure_ = New Structure;
		SettingsStructure_.Insert("WSWebServiceURL", ConnectionParameters.WebServiceAddress);
		SettingsStructure_.Insert("WSUserName", ConnectionParameters.UserName);
		SettingsStructure_.Insert("WSPassword", ConnectionParameters.Password);
		CorrespondentVersions = DataExchangeCached.CorrespondentVersions(SettingsStructure_);
	Except
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		Return Undefined;
	EndTry;
		
	InterfaceVersion = MaximumGeneralVersionOfExchangeInterface(CorrespondentVersions);
	
	If InterfaceVersion = "0.0.0.0" Then
		VersionForAddress = "";
	Else
		VersionForAddress = "_" + StrReplace(InterfaceVersion, ".", "_");
	EndIf;
	
	DataExchangeServer.DeleteInsignificantCharactersInConnectionSettings(ConnectionParameters);
	
	ConnectionParameters.Insert("NamespaceURI", "http://www.1c.ru/SSL/Exchange" + VersionForAddress);
	ConnectionParameters.Insert("ServiceName", "Exchange" + VersionForAddress);
	
	If Not ConnectionParameters.Property("Timeout") Then
		ConnectionParameters.Insert("Timeout", 600);
	EndIf;
	
	If Not ConnectionParameters.Property("ProbingCallRequired") Then
		ConnectionParameters.Insert("ProbingCallRequired", True);
	EndIf;
		
	WSDLLocation = "[WebServiceURL]/ws/[ServiceName]?wsdl";
	WSDLLocation = StrReplace(WSDLLocation, "[WebServiceURL]", ConnectionParameters.WebServiceAddress);
	WSDLLocation = StrReplace(WSDLLocation, "[ServiceName]",    ConnectionParameters.ServiceName);
	
	ConnectionParameters.Insert("WSDLAddress", WSDLLocation);
	
	ConnectionParameters.Insert("EndpointName");
	ConnectionParameters.Insert("UseOSAuthentication", False);
	ConnectionParameters.Insert("Location");
	ConnectionParameters.Insert("SecureConnection");
	
	Try
		WSProxy = Common.CreateWSProxy(ConnectionParameters);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessage);
		Return Undefined;
	EndTry;
	
	Return WSProxy;
	
EndFunction

Function SetupStatus(Proxy, SettingsStructure_, DataArea = 0, Cancel = False, ErrorMessageString = "") Export
	
	If DataExchangeServer.IsXDTOExchangePlan(SettingsStructure_.ExchangePlanName) Then
		
		NodeAlias = DataExchangeServer.PredefinedNodeAlias(SettingsStructure_.InfobaseNode);
		If ValueIsFilled(NodeAlias) Then
			// Checking a setting with an old ID (prefix).
			SettingsStructureOfPredefined = Common.CopyRecursive(SettingsStructure_, False); // Structure
			SettingsStructureOfPredefined.Insert("CurrentExchangePlanNodeCode1", NodeAlias);
			SetupStatus = SynchronizationSetupStatusInCorrespondent(Proxy, SettingsStructureOfPredefined);
				
			If Not SetupStatus.SettingExists Then
				If ObsoleteExchangeSettingsOptionInCorrespondent(
						Proxy, SetupStatus, SettingsStructure_, NodeAlias, Cancel, ErrorMessageString)
					Or Cancel Then
					Return SetupStatus;
				EndIf;
			Else
				SettingsStructure_.CurrentExchangePlanNodeCode1 = NodeAlias;
				Return SetupStatus;
			EndIf;
		EndIf;
		
		SetupStatus = SynchronizationSetupStatusInCorrespondent(Proxy, SettingsStructure_, DataArea);
			
		If Not SetupStatus.SettingExists Then
			If ObsoleteExchangeSettingsOptionInCorrespondent(
					Proxy, SetupStatus, SettingsStructure_, SettingsStructure_.CurrentExchangePlanNodeCode1, Cancel, ErrorMessageString)
				Or Cancel Then
				Return SetupStatus;
			EndIf;
		EndIf;
		
	Else
		
		SetupStatus = SynchronizationSetupStatusInCorrespondent(Proxy, SettingsStructure_, DataArea);
			
	EndIf;
	
	If Not SetupStatus.SettingExists Then
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Data synchronization setting with ID ""%2"" is not found. Exchange plan: %1.'"),
			SettingsStructure_.ExchangePlanName,
			SettingsStructure_.CurrentExchangePlanNodeCode1);
		Cancel = True;
	EndIf;
	
	Return SetupStatus;
	
EndFunction

Procedure ExportToFileTransferServiceForInfobaseNode(ProcedureParameters, StorageAddress) Export
	
	ExchangePlanName            = ProcedureParameters["ExchangePlanName"];
	InfobaseNodeCode = ProcedureParameters["InfobaseNodeCode"];
	FileID        = ProcedureParameters["FileID"];
	
	UseCompression = ProcedureParameters.Property("UseCompression") And ProcedureParameters["UseCompression"];
	
	SetPrivilegedMode(True);
	
	MessageFileName = CommonClientServer.GetFullFileName(
		DataExchangeServer.TempFilesStorageDirectory(),
		DataExchangeServer.UniqueExchangeMessageFileName());
	
	DataExchangeParameters = DataExchangeServer.DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.FullNameOfExchangeMessageFile = MessageFileName;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataExport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	
	DataExchangeServer.ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	
	NameOfFileToPutInStorage = MessageFileName;
	If UseCompression Then
		NameOfFileToPutInStorage = CommonClientServer.GetFullFileName(
			DataExchangeServer.TempFilesStorageDirectory(),
			DataExchangeServer.UniqueExchangeMessageFileName("zip"));
		
		Archiver = New ZipFileWriter(NameOfFileToPutInStorage, , , , ZIPCompressionLevel.Maximum);
		Archiver.Add(MessageFileName);
		Archiver.Write();
		
		DeleteFiles(MessageFileName);
	EndIf;
	
	DataExchangeServer.PutFileInStorage(NameOfFileToPutInStorage, FileID);
	
EndProcedure

Procedure ImportFromFileTransferServiceForInfobaseNode(ProcedureParameters, StorageAddress) Export
	
	ExchangePlanName            = ProcedureParameters["ExchangePlanName"];
	InfobaseNodeCode = ProcedureParameters["InfobaseNodeCode"];
	FileID        = ProcedureParameters["FileID"];
	
	SetPrivilegedMode(True);
	
	TempFileName = DataExchangeServer.GetFileFromStorage(FileID);
	
	DataExchangeParameters = DataExchangeServer.DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.FullNameOfExchangeMessageFile = TempFileName;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataImport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	
	Try
		DataExchangeServer.ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		DeleteFiles(TempFileName);
		Raise ErrorPresentation;
	EndTry;
	
	DeleteFiles(TempFileName);
EndProcedure

// An analog of the "UploadData" operation
Procedure RunDataExport(Proxy, ExchangeSettingsStructure, ExchangeParameters, DataArea = 0) Export
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.UploadData(
			ExchangeSettingsStructure.CorrespondentExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			ExchangeParameters.FileID,
			ExchangeParameters.TimeConsumingOperation,
			ExchangeParameters.OperationID,
			ExchangeParameters.TimeConsumingOperationAllowed,
			DataArea);

	Else
					
		Proxy.UploadData(
			ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			ExchangeParameters.FileID,
			ExchangeParameters.TimeConsumingOperation,
			ExchangeParameters.OperationID,
			ExchangeParameters.TimeConsumingOperationAllowed);
			
	EndIf;

EndProcedure

// An analog of the "DownloadData" operation
Procedure RunDataImport(Proxy, ExchangeSettingsStructure, ExchangeParameters, FileIDAsString, DataArea = 0) Export
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.DownloadData(
			ExchangeSettingsStructure.CorrespondentExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			FileIDAsString,
			ExchangeParameters.TimeConsumingOperation,
			ExchangeParameters.OperationID,
			ExchangeParameters.TimeConsumingOperationAllowed,
			DataArea);
		
	Else
		
		Proxy.DownloadData(
			ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			FileIDAsString,
			ExchangeParameters.TimeConsumingOperation,
			ExchangeParameters.OperationID,
			ExchangeParameters.TimeConsumingOperationAllowed);
			
	EndIf;

EndProcedure

// Matches the GetIBParameters web service operation.

Function GetParametersOfInfobase(Proxy, ExchangePlanName, NodeCode, ErrorMessage, DataArea = 0, AdditionalParameters = Undefined) Export
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_2(ProxyVersion) Then
		
		If AdditionalParameters = Undefined Then
			AdditionalParameters = New Structure;
		EndIf;
		
		AdditionalXDTOParameters = XDTOSerializer.WriteXDTO(AdditionalParameters);
		
		Return Proxy.GetIBParameters(ExchangePlanName, NodeCode, ErrorMessage, DataArea, AdditionalXDTOParameters);
		
	ElsIf Version3_0_2_1(ProxyVersion) Then
		
		Return Proxy.GetIBParameters(ExchangePlanName, NodeCode, ErrorMessage, DataArea);
			
	Else
		
		Return Proxy.GetIBParameters(ExchangePlanName, NodeCode, ErrorMessage);
		
	EndIf;
	
EndFunction 

// An analog of the "PutMessageForDataMatching" operation
Procedure PutMessageForDataMapping(Proxy, ExchangeSettingsStructure, FileIDAsString, DataArea = 0) Export
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.PutMessageForDataMatching(ExchangeSettingsStructure.CorrespondentExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			FileIDAsString,
			DataArea);
		
	Else
		
		Proxy.PutMessageForDataMatching(ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			FileIDAsString);
	
	EndIf;
	
EndProcedure

// An analog of the "RemoveExchangeNode" operation
Procedure DeleteExchangeNode(Proxy, ExchangeSettingsStructure, DataArea = 0) Export
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.RemoveExchangeNode(ExchangeSettingsStructure.CorrespondentExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			DataArea);
			
	Else
	
		Proxy.RemoveExchangeNode(ExchangeSettingsStructure.ExchangePlanName, ExchangeSettingsStructure.CurrentExchangePlanNodeCode1);
		
	EndIf;
	
EndProcedure

// An analog of the "CreateExchangeNode" operation
Procedure CreateExchangeNode(Proxy, ConnectionParameters, DataArea = 0) Export
	
	ProxyVersion = ProxyVersion(Proxy);
	
	Serializer = New XDTOSerializer(Proxy.XDTOFactory);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.CreateExchangeNode(Serializer.WriteXDTO(ConnectionParameters), DataArea);
		
	Else
		
		Proxy.CreateExchangeNode(Serializer.WriteXDTO(ConnectionParameters));
		
	EndIf;
	
EndProcedure

// Returns:
//   String
//
Function TempFileDeletionEventLogEvent() Export
	
	Return NStr("en = 'Data exchange.Delete temporary file'", Common.DefaultLanguageCode());
	
EndFunction

// Returns:
//   String
//
Function EventLogEventTransportChangedOnWS() Export
	
	Return NStr("en = 'Data exchange.Change transport to WS'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#Region Private

// Returns:
//   String
//
Function EstablishWebServiceConnectionEventLogEvent()
	
	Return NStr("en = 'Data exchange.Establish web service connection'", Common.DefaultLanguageCode());
	
EndFunction

Procedure WaitingForTheOperationToComplete(ExchangeSettingsStructure, ExchangeParameters, Proxy, ActionWhenExchangingInThisInformationSystem = Undefined) Export
	
	If ExchangeParameters.TheTimeoutOnTheServer = 0 Then
		
		If ActionWhenExchangingInThisInformationSystem <> Undefined Then
			
			// For this infobase, "Import". Therefore, for the peer infobase, "Export".
			If ActionWhenExchangingInThisInformationSystem = Enums.ActionsOnExchange.DataImport Then
				
				ActionInTheCorrespondentLine = NStr("en = 'export'", Common.DefaultLanguageCode());
				
			Else
				
				ActionInTheCorrespondentLine = NStr("en = 'import'", Common.DefaultLanguageCode());
				
			EndIf;
			
			MessageTemplate = NStr("en = 'Waiting for the operation to be executed (%1 of the data in the peer infobase)…'", Common.DefaultLanguageCode());
			DataExchangeServer.WriteEventLogDataExchange(StrTemplate(MessageTemplate, ActionInTheCorrespondentLine), ExchangeSettingsStructure);
			
		EndIf;
		
		Return;
		
	EndIf;
	
	While ExchangeParameters.TimeConsumingOperation Do // Replace recursion.
		
		DataExchangeServer.Pause(ExchangeParameters.TheTimeoutOnTheServer);
		
		ErrorMessageString = "";
	
		ActionState = GetLongRunningOperationStatus(Proxy, ExchangeParameters, ErrorMessageString);
			
		If ActionState = "Active" Then
			
			ExchangeParameters.TheTimeoutOnTheServer = Min(ExchangeParameters.TheTimeoutOnTheServer + 30, 180);
			
		ElsIf ActionState = "Completed" Then
			
			ExchangeParameters.TheTimeoutOnTheServer = 15;
			ExchangeParameters.TimeConsumingOperation = False; 
			ExchangeParameters.OperationID = Undefined;
			
		Else
			
			Raise StrTemplate(NStr("en = 'Peer infobase error: %1 %2'"), Chars.LF, ErrorMessageString);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function Version3_0_2_1(ProxyVersion)
	
	Return CommonClientServer.CompareVersions(ProxyVersion, "3.0.2.1") >= 0;
		
EndFunction

Function Version3_0_2_2(ProxyVersion)
	
	Return CommonClientServer.CompareVersions(ProxyVersion, "3.0.2.2") >= 0;
		
EndFunction

Function ProxyVersion(Proxy)

	Name = Proxy.Endpoint.Name;
	Version = StrReplace(Name, "Exchange_", "");
	Version = StrReplace(Version, "Soap", "");
	Version = StrReplace(Version, "_", ".");
	
	Return Version;
	
EndFunction

// An analog of the "GetContinuousOperationStatus" operation
Function GetLongRunningOperationStatus(Proxy, ExchangeParameters, ErrorMessageString, DataArea = 0)

	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Return Proxy.GetContinuousOperationStatus(ExchangeParameters.OperationID,
			ErrorMessageString, 
			DataArea);
		
	Else
	
		Return Proxy.GetContinuousOperationStatus(ExchangeParameters.OperationID, ErrorMessageString);
		
	EndIf;
	
EndFunction

// An analog of the "PrepareGetFile" operation
Function PrepareFileForReceipt(Proxy, FileID, PartSize, SessionID, PartCount, DataArea = 0)
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Return Proxy.PrepareGetFile(FileID,
			PartSize,
			SessionID,
			PartCount, 
			DataArea);
		
	Else
	
		Return Proxy.PrepareGetFile(FileID, PartSize, SessionID, PartCount);
	
	EndIf;
	
EndFunction

// An analog of the "GetFilePart" operation
Procedure GetFileChunk(Proxy, SessionID, PartNumber, PartData, DataArea = 0)
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.GetFilePart(SessionID,
			PartNumber, PartData,
			DataArea);
			
	Else
	
		Proxy.GetFilePart(SessionID, PartNumber, PartData);
		
	EndIf;
	
EndProcedure

// An analog of the "PutFilePart" operation
Procedure PutFileChunk(Proxy, SessionID, PartNumber, FileData, DataArea = 0)
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.PutFilePart(SessionID, PartNumber, FileData,
			DataArea);
		
	Else
	
		Proxy.PutFilePart(SessionID, PartNumber, FileData);
		
	EndIf;
	
EndProcedure

// An analog of the "SaveFileFromParts" operation
Procedure AssembleFileFromParts(Proxy, SessionID, PartCount, FileID, DataArea = 0)
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.SaveFileFromParts(SessionID, PartCount, FileID, DataArea);
		
	Else
		
		Proxy.SaveFileFromParts(SessionID, PartCount, FileID);
		
	EndIf; 
	
EndProcedure

// An analog of the "TestConnection" operation
Function ConnectionTesting(Proxy, ExchangeSettingsStructure, ErrorMessage, DataArea = 0)

	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Return Proxy.TestConnection(
			ExchangeSettingsStructure.CorrespondentExchangePlanName, 
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1, 
			ErrorMessage, 
			DataArea); 
			
	Else
		
		Return Proxy.TestConnection(ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			ErrorMessage);
		
	EndIf;
	
EndFunction

Procedure CheckProhibitedCharsInWSProxyUsername(Val UserName)
	
	InvalidChars = ProhibitedCharsInWSProxyUsername();
	
	If StringContainsCharacter(UserName, InvalidChars) Then
		
		MessageString = NStr("en = 'Username ""%1"" contains illegal characters:
			|%2'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, UserName, InvalidChars);
		
		Raise MessageString;
		
	EndIf;
	
EndProcedure

Function StringContainsCharacter(Val String, Val CharacterString)
	
	For IndexOf = 1 To StrLen(CharacterString) Do
		Char = Mid(CharacterString, IndexOf, 1);
		
		If StrFind(String, Char) <> 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function ProhibitedCharsInWSProxyUsername()
	
	Return ":";
	
EndFunction

Procedure CheckWSProxyAddressFormatCorrectness(Val WSProxyAddress)
	
	IsInternetAddress           = False;
	AllowedWSProxyPrefixes = AllowedWSProxyPrefixes();
	
	For Each Prefix In AllowedWSProxyPrefixes Do
		If Left(Lower(WSProxyAddress), StrLen(Prefix)) = Lower(Prefix) Then
			IsInternetAddress = True;
			Break;
		EndIf;
	EndDo;
	
	If Not IsInternetAddress Then
		PrefixesString = "";
		For Each Prefix In AllowedWSProxyPrefixes Do
			PrefixesString = PrefixesString + ?(IsBlankString(PrefixesString), """", " or """) + Prefix + """";
		EndDo;
		
		MessageString = NStr("en = 'Invalid address format: ""%1"".
			|An address must start with an Internet protocol prefix: %2. For example, ""http://myserver.com/service"".'");
			
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, WSProxyAddress, PrefixesString);
		
		Raise MessageString;
	EndIf;
	
EndProcedure

Function AllowedWSProxyPrefixes()
	
	Result = New Array();
	
	Result.Add("http");
	Result.Add("https");
	
	Return Result;
	
EndFunction

Function SynchronizationSetupStatusInCorrespondent(Proxy, SettingsStructure_, DataArea = 0)
	
	Result = New Structure;
	Result.Insert("SettingExists",                     False);
	
	Result.Insert("DataSynchronizationSetupCompleted",   True);
	Result.Insert("MessageReceivedForDataMapping", False);
	Result.Insert("DataMappingSupported",       True);
		
	ErrorMessageString = "";
	ProxyVersion = ProxyVersion(Proxy);
	
	If CommonClientServer.CompareVersions(ProxyVersion, "2.0.1.6") >= 0 Then
		
		SettingExists = ConnectionTesting(Proxy, SettingsStructure_, ErrorMessageString, DataArea);
		
		If SettingExists
			And CommonClientServer.CompareVersions(ProxyVersion, "3.0.1.1") >= 0 Then
			
			ProxyDestinationParameters = GetParametersOfInfobase(Proxy,
				SettingsStructure_.CorrespondentExchangePlanName,
				SettingsStructure_.CurrentExchangePlanNodeCode1,
				ErrorMessageString,
				DataArea);
			
			DestinationParameters = XDTOSerializer.ReadXDTO(ProxyDestinationParameters);
			
			FillPropertyValues(Result, DestinationParameters);
		EndIf;
		
		Result.SettingExists = SettingExists;
	Else
		
		ProxyDestinationParameters = GetParametersOfInfobase(Proxy,
				SettingsStructure_.ExchangePlanName,
				SettingsStructure_.CurrentExchangePlanNodeCode1,
				ErrorMessageString,
				DataArea);
			
		DestinationParameters = ValueFromStringInternal(ProxyDestinationParameters);
		
		If DestinationParameters.Property("NodeExists") Then
			Result.SettingExists = DestinationParameters.NodeExists;
		Else
			Result.SettingExists = True;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

Function ObsoleteExchangeSettingsOptionInCorrespondent(Proxy, SetupStatus, SettingsStructure_, NodeCode, Cancel, ErrorMessageString = "")
	
	StateOfOptionSetup = New Structure();
	StateOfOptionSetup.Insert("TransportSettings", SettingsStructure_.TransportSettings);
	
	// Checking if migration is possible.
	For Each SettingsMode In ObsoleteExchangeSettingsOptions(SettingsStructure_.InfobaseNode) Do
		
		StateOfOptionSetup.Insert("ExchangePlanName", SettingsMode.ExchangePlanName);
		StateOfOptionSetup.Insert("CurrentExchangePlanNodeCode1", NodeCode);
				
		SetupStatus = SynchronizationSetupStatusInCorrespondent(
			Proxy, StateOfOptionSetup);
		
		If SetupStatus.SettingExists Then
			If SettingsStructure_.ActionOnExchange = Enums.ActionsOnExchange.DataExport Then
				SettingsStructure_.ExchangePlanName = SettingsMode.ExchangePlanName;
				If NodeCode <> SettingsStructure_.CurrentExchangePlanNodeCode1 Then
					SettingsStructure_.CurrentExchangePlanNodeCode1 = NodeCode;
				EndIf;
			Else
				// This infobase has switched to another exchange plan, and its peer hasn't.
				// Data import is aborted.
				ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Synchronization settings are being updated in ""%1"" application.
					|The data import is canceled. Restart the data synchronization later.'"),
					String(SettingsStructure_.InfobaseNode));
				Cancel = True;
			EndIf;
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function ObsoleteExchangeSettingsOptions(ExchangeNode)
	
	Result = New Array;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeNode);
	
	SettingsMode = "";
	If Common.HasObjectAttribute("SettingsMode", ExchangeNode.Metadata()) Then
		SettingsMode = Common.ObjectAttributeValue(ExchangeNode, "SettingsMode");
	EndIf;
	
	If ValueIsFilled(SettingsMode) Then
		For Each PreviousExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
			If PreviousExchangePlanName = ExchangePlanName Then
				Continue;
			EndIf;
			If DataExchangeCached.IsDistributedInfobaseExchangePlan(PreviousExchangePlanName) Then
				Continue;
			EndIf;
			
			PreviousExchangePlanSettings = DataExchangeServer.ExchangePlanSettingValue(PreviousExchangePlanName,
				"ExchangePlanNameToMigrateToNewExchange,ExchangeSettingsOptions");
			
			If PreviousExchangePlanSettings.ExchangePlanNameToMigrateToNewExchange = ExchangePlanName Then
				SettingsOption = PreviousExchangePlanSettings.ExchangeSettingsOptions.Find(SettingsMode, "SettingID");
				If Not SettingsOption = Undefined Then
					Result.Add(New Structure("ExchangePlanName, SettingID", 
						PreviousExchangePlanName, SettingsOption.SettingID));
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

Function MaximumGeneralVersionOfExchangeInterface(WeightOfCorrespondentExchangeInterface) Export
	
	SupportedVersionsStructure = New Structure;
	DataExchangeServer.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);
	VersionsOfExchangeInterface = SupportedVersionsStructure.DataExchange;
	
	MaxVersion = "0.0.0.0";
	
	For Each Version In WeightOfCorrespondentExchangeInterface Do
		
		If VersionsOfExchangeInterface.Find(Version) = Undefined Then
			Continue;
		EndIf;
		
		If CommonClientServer.CompareVersions(Version, MaxVersion) > 0 Then
			MaxVersion = Version;
		EndIf;
		
	EndDo;
	
	// Exception
	If MaxVersion = "2.1.1.7" Then
		MaxVersion = "2.0.1.6";
	EndIf;
	
	Return MaxVersion;
	
EndFunction

#EndRegion

