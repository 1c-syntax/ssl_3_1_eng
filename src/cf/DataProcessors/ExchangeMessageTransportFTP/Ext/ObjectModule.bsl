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

// For FTP
Var SendGetDataTimeout; // Timeout for exchanging data with a FTP server.
Var ConnectionCheckTimeout; // FTP connection check timeout.
Var FTPServerName; // FTP server name or IP address.
Var DirectoryAtFTPServer; // Directory on server for storing and receiving exchange messages.

#EndRegion

#Region Public

// See DataProcessorObject.ExchangeMessageTransportFILE.SendData
Function SendData(MessageForDataMapping = False) Export
	
	Try
		Result = SendMessage();
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

// See DataProcessorObject.ExchangeMessageTransportFILE.CorrespondentParameters
Function CorrespondentParameters(ConnectionSettings) Export
	
	Result = ExchangeMessagesTransport.StructureOfResultOfObtainingParametersOfCorrespondent();
	Result.ConnectionIsSet = True;
	Result.ConnectionAllowed = True;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.BeforeExportData
Function BeforeExportData(MessageForDataMapping = False) Export
	
	Return True;
	
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

Function ConnectionIsSet() Export
	
	// Function return value.
	Result = True;
	
	If Common.DataSeparationEnabled() Then
		Return Result;
	EndIf;
	
	If IsBlankString(Path) Then
		ErrorMessage = NStr("en = 'Path on the server is not specified.'");
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		Return False;
	EndIf;
	
	// Creating a file in the temporary directory.
	TempConnectionTestFileName = GetTempFileName("tmp");
	FileNameForDestination = DataExchangeServer.TempConnectionTestFileName();
	
	TextWriter = New TextWriter(TempConnectionTestFileName);
	TextWriter.WriteLine(FileNameForDestination);
	TextWriter.Close();
	
	// Copying a file to the external resource from the temporary directory.
	Result = CopyFileToFTPServer(TempConnectionTestFileName, FileNameForDestination, ConnectionCheckTimeout);
	
	// Deleting a file from the external resource.
	If Result Then
		Result = DeleteFileAtFTPServer(FileNameForDestination, True);
	EndIf;
	
	// Deleting a file from the temporary directory.
	DeleteFiles(TempConnectionTestFileName);
	
	Return Result;
	
EndFunction

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
		
		// Copying the archive file to the FTP server in the data exchange directory.
		If Not CopyFileToFTPServer(ExchangeMessage, ReceiverFileName, SendGetDataTimeout) Then
			Result = False;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function GetMessage(MessageNameTemplate)
	
	ExchangeMessagesFilesTable = New ValueTable;
	ExchangeMessagesFilesTable.Columns.Add("File");
	ExchangeMessagesFilesTable.Columns.Add("Modified");
	
	Try
		FTPConnection = GetFTPConnection(SendGetDataTimeout);
	Except
		
		ErrorMessage = NStr("en = 'An occurred when initializing connection to the FTP server.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndTry;
	
	Try
		FoundFileArray = FTPConnection.FindFiles(DirectoryAtFTPServer, MessageNameTemplate, False);
	Except
		
		ErrorMessage = NStr("en = 'An occurred when initializing connection to the FTP server.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndTry;
	
	For Each CurrentFile In FoundFileArray Do
		
		If Not CurrentFile.IsFile() Then
			
			Continue;
			
		// Checking that the file size is greater than 0.
		ElsIf (CurrentFile.Size() = 0) Then
			
			Continue;
			
		EndIf;
		
		// The file is a required exchange message. Adding the file to the table.
		TableRow = ExchangeMessagesFilesTable.Add();
		TableRow.File           = CurrentFile;
		TableRow.Modified = CurrentFile.GetModificationTime();
		
	EndDo;
	
	If ExchangeMessagesFilesTable.Count() = 0 Then
		
		ErrorMessage = NStr("en = 'An information exchange directory is missing a message file.
                                  |Server directory: %1
                                  |File: %2'");
		
		ErrorMessage = StrTemplate(ErrorMessage, DirectoryAtFTPServer, MessageNameTemplate);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	Else
		
		ExchangeMessagesFilesTable.Sort("Modified Desc");
		
		// Obtaining the newest exchange message file from the table.
		File = ExchangeMessagesFilesTable[0].File;
		FilePacked = (Upper(File.Extension) = ".ZIP");
			
		If FilePacked Then
			
			ArchiveTempFileName = CommonClientServer.GetFullFileName(
				TempDirectory, String(New UUID) + ".zip");
				
			Try
				FTPConnection.Get(File.FullName, ArchiveTempFileName);
			Except

				ErrorMessage = NStr("en = 'Error receiving the file from the FTP server.'");
				ErrorMessageEventLog = ErrorMessage;
					
				ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
				ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
				
				Return False;
				
			EndTry;
		
			If Not ExchangeMessagesTransport.UnzipExchangeMessageFromZipFile(
				ThisObject, ArchiveTempFileName, ArchivePasswordExchangeMessages) Then
				
				Return False;
				
			EndIf;
			
		Else
	
			Try
				
				FTPConnection.Get(File.FullName, ExchangeMessage);
				
			Except
				
				ErrorMessage = NStr("en = 'Error receiving the file from the FTP server.'");
				ErrorMessageEventLog = ErrorMessage;
		
				ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
				ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport"); 
				
				Return False;
				
			EndTry;
			
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// FTP management.

Function GetFTPConnection(Timeout)
	
	ServerNameAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(Path));
	FTPServerName = ServerNameAndDirectoryAtServer.ServerName;
	DirectoryAtFTPServer = ServerNameAndDirectoryAtServer.DirectoryName;
	
	FTPSettings = ExchangeMessagesTransport.FTPConnectionSetup(Timeout);
	FTPSettings.Server               = FTPServerName;
	FTPSettings.Port                 = Port;
	FTPSettings.UserName      = User;
	FTPSettings.UserPassword   = Password;
	FTPSettings.PassiveConnection  = PassiveConnection;
	FTPSettings.SecureConnection = DataExchangeServer.SecureConnection(Path);
	
	Return ExchangeMessagesTransport.FTPConnection(FTPSettings);
	
EndFunction

Function CopyFileToFTPServer(Val SourceFileName, ReceiverFileName, Val Timeout)
	
	Var DirectoryAtServer;
	
	ServerAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(Path));
	DirectoryAtServer = ServerAndDirectoryAtServer.DirectoryName;
	
	Try
		FTPConnection = GetFTPConnection(Timeout);
	Except
		
		ErrorMessage = NStr("en = 'An occurred when initializing connection to the FTP server.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Return False;
		
	EndTry;
	
	If Timeout = ConnectionCheckTimeout 
		And FTPConnection.PassiveMode 
		And Not PassiveConnection Then
		
		ErrorMessage = NStr("en = 'An error occurred during the attempt to establish an active connection to the FTP server. Try establishing a passive connection.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Return False;
		
	EndIf;
	
	CreateDirectoryIfNecessary(FTPConnection, DirectoryAtServer);
	
	Try
		FTPConnection.Put(SourceFileName, DirectoryAtServer + ReceiverFileName);
	Except
		
		ErrorMessage = NStr("en = 'An error occurred when establishing connection to the FTP server. Check whether the path is specified correctly and access rights are sufficient.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");

		Return False;
	EndTry;
	
	If Common.DataSeparationEnabled() Then
		Return True;
	EndIf;
	
	Try
		FilesArray = FTPConnection.FindFiles(DirectoryAtServer, ReceiverFileName, False);
	Except
		
		ErrorMessage = NStr("en = 'Error searching for files on the FTP server.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Return False;
		
	EndTry;
	
	Return FilesArray.Count() > 0;
	
EndFunction

Procedure CreateDirectoryIfNecessary(FTPConnection, DirectoryAtServer)
	
	If DirectoryAtServer = "/" Then
		Return;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		
		// In SaaS mode, checking if a directory exists is a resource-intensive operation.
		// Instead, run "CreateDirectory", and if it already exists, throw an exception and exit. 
		// 
		Try
			FTPConnection.CreateDirectory(DirectoryAtServer);
		Except
			// No action required
		EndTry;
		
	Else	
		
		NamesArray = StrSplit(DirectoryAtServer, "/", False);
		DirectoryName = "";
		
		For Each Name In NamesArray Do
		
			DirectoryName = DirectoryName + "/" + Name;
		
			If FTPConnection.FindFiles(DirectoryName).Count() = 0 Then
				FTPConnection.CreateDirectory(DirectoryName);
			EndIf;
		
		EndDo;
	
	EndIf;
	
EndProcedure

Function DeleteFileAtFTPServer(Val FileName, ConnectionCheckUp = False)
	
	Var DirectoryAtServer;
	
	ServerAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(Path));
	DirectoryAtServer = ServerAndDirectoryAtServer.DirectoryName;
	
	Try
		FTPConnection = GetFTPConnection(ConnectionCheckTimeout);
	Except
		
		ErrorMessage = NStr("en = 'An occurred when initializing connection to the FTP server.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True); 
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	EndTry;
	
	Try
		FTPConnection.Delete(DirectoryAtServer + FileName);
	Except
		
		ErrorMessage = NStr("en = 'Error deleting the file from the FTP server. Check whether resource access rights are sufficient.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		If ConnectionCheckUp Then
			
			ErrorMessage = NStr("en = 'Cannot check connection using test file ""%1"".
				|Maybe, the specified directory does not exist or is unavailable.
				|Check FTP server documentation to configure support of Cyrillic file names.'");
			ErrorMessage = StrTemplate(ErrorMessage, FileName);
			ErrorMessageEventLog = ErrorMessage;
			
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
			
		EndIf;
		
		Return False;
		
	EndTry;
	
	Return True;
	
EndFunction

Function SplitFTPResourceToServerAndDirectory(Val FullPath)
	
	Result = New Structure("ServerName, DirectoryName");
	
	FTPParameters = ExchangeMessagesTransport.FTPServerNameAndPath(FullPath);
	
	Result.ServerName  = FTPParameters.Server;
	Result.DirectoryName = FTPParameters.Path;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Initialize

TempDirectory = Undefined;
ExchangeMessage = Undefined;

FTPServerName = Undefined;
DirectoryAtFTPServer = Undefined;

SendGetDataTimeout = 12*60*60;
ConnectionCheckTimeout = 10;

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.'");
#EndIf