///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables
Var ErrorMessageString Export;
Var ErrorMessageStringEL Export;

Var ErrorsMessages; // 
Var ObjectName;		// 
Var FTPServerName;		// 
Var DirectoryAtFTPServer;// 

Var TempExchangeMessageFile; // 
Var TempExchangeMessagesDirectory; // 

Var SendGetDataTimeout; // 
Var ConnectionCheckTimeout; // 

Var DirectoryID;
#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 

// Creates a temporary directory in the temporary files directory of the operating system user.
//
// Parameters:
//  No.
// 
//  Returns:
//    Boolean - 
// 
Function ExecuteActionsBeforeProcessMessage() Export
	
	InitMessages();
	
	DirectoryID = Undefined;
	
	Return CreateTempExchangeMessagesDirectory();
	
EndFunction

// Sends an exchange message to the specified resource from the temporary directory of the exchange message.
//
// Parameters:
//  No.
// 
//  Returns:
//    Boolean - 
// 
Function SendMessage() Export
	
	InitMessages();
	
	Try
		Result = SendExchangeMessage();
	Except
		Result = False;
	EndTry;
	
	Return Result;
	
EndFunction

// Retrieves the exchange message from the specified resource to the temporary directory of the exchange message.
//
// Parameters:
//  ExistenceCheck - Boolean -  True if you only need to check for exchange messages, without downloading them.
// 
//  Returns:
//    Boolean - 
// 
Function GetMessage(ExistenceCheck = False) Export
	
	InitMessages();
	
	Try
		Result = GetExchangeMessage(ExistenceCheck);
	Except
		Result = False;
	EndTry;
	
	Return Result;
	
EndFunction

// Removes the temporary directory the message exchange after performing the upload or download of data.
//
// Parameters:
//  No.
// 
//  Returns:
//    Boolean - True
//
Function ExecuteActionsAfterProcessMessage() Export
	
	InitMessages();
	
	DeleteTempExchangeMessagesDirectory();
	
	Return True;
	
EndFunction

// Initializes processing properties with initial values and constants.
//
// Parameters:
//  No.
// 
Procedure Initialize() Export
	
	InitMessages();
	
	ServerNameAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(FTPConnectionPath));
	FTPServerName			= ServerNameAndDirectoryAtServer.ServerName;
	DirectoryAtFTPServer	= ServerNameAndDirectoryAtServer.DirectoryName;
	
EndProcedure

// Checks whether a connection can be established to the specified resource.
//
// Parameters:
//  No.
// 
//  Returns:
//    Boolean - 
//
Function ConnectionIsSet() Export
	
	// 
	Result = True;
	
	If Common.DataSeparationEnabled() Then
		Return Result;
	EndIf;
	
	InitMessages();
	
	If IsBlankString(FTPConnectionPath) Then
		
		GetErrorMessage(101);
		Return False;
		
	EndIf;
	
	// 
	TempConnectionTestFileName = GetTempFileName("tmp");
	FileNameForDestination = DataExchangeServer.TempConnectionTestFileName();
	
	TextWriter = New TextWriter(TempConnectionTestFileName);
	TextWriter.WriteLine(FileNameForDestination);
	TextWriter.Close();
	
	// 
	Result = CopyFileToFTPServer(TempConnectionTestFileName, FileNameForDestination, ConnectionCheckTimeout);
	
	// 
	If Result Then
		
		Result = DeleteFileAtFTPServer(FileNameForDestination, True);
		
	EndIf;
	
	// 
	DeleteFiles(TempConnectionTestFileName);
	
	Return Result;
EndFunction

///////////////////////////////////////////////////////////////////////////////
// 

// Function-property: time when the exchange message file was changed.
//
// Returns:
//  Date - 
//
Function ExchangeMessageFileDate() Export
	
	Result = Undefined;
	
	If TypeOf(TempExchangeMessageFile) = Type("File") Then
		
		If TempExchangeMessageFile.Exists() Then
			
			Result = TempExchangeMessageFile.GetModificationTime();
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Function property: the fully qualified file name of the message exchange.
//
// Returns:
//  String - 
//
Function ExchangeMessageFileName() Export
	
	Name = "";
	
	If TypeOf(TempExchangeMessageFile) = Type("File") Then
		
		Name = TempExchangeMessageFile.FullName;
		
	EndIf;
	
	Return Name;
	
EndFunction

// Function-property: full name of the exchange message folder.
//
// Returns:
//  String - 
//
Function ExchangeMessageDirectoryName() Export
	
	Name = "";
	
	If TypeOf(TempExchangeMessagesDirectory) = Type("File") Then
		
		Name = TempExchangeMessagesDirectory.FullName;
		
	EndIf;
	
	Return Name;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// 

Function CreateTempExchangeMessagesDirectory()
	
	// 
	Try
		TempDirectoryName = DataExchangeServer.CreateTempExchangeMessagesDirectory(DirectoryID);
	Except
		GetErrorMessage(4);
		SupplementErrorMessage(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	TempExchangeMessagesDirectory = New File(TempDirectoryName);
	
	MessageFileName = CommonClientServer.GetFullFileName(ExchangeMessageDirectoryName(), MessageFileNameTemplate + ".xml");
	
	TempExchangeMessageFile = New File(MessageFileName);
	
	Return True;
EndFunction

Function DeleteTempExchangeMessagesDirectory()
	
	Try
		If Not IsBlankString(ExchangeMessageDirectoryName()) Then
			DeleteFiles(ExchangeMessageDirectoryName());
			TempExchangeMessagesDirectory = Undefined;
		EndIf;
		
		If Not DirectoryID = Undefined Then
			DataExchangeServer.GetFileFromStorage(DirectoryID);
			DirectoryID = Undefined;
		EndIf;
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function SendExchangeMessage()
	
	Result = True;
	
	Extension = ?(CompressOutgoingMessageFile(), ".zip", ".xml");
	
	OutgoingMessageFileName = MessageFileNameTemplate + Extension;
	
	If CompressOutgoingMessageFile() Then
		
		// 
		ArchiveTempFileName = CommonClientServer.GetFullFileName(ExchangeMessageDirectoryName(), MessageFileNameTemplate + ".zip");
		
		Try
			
			Archiver = New ZipFileWriter(ArchiveTempFileName, ArchivePasswordExchangeMessages, NStr("en = 'Exchange message file';"));
			Archiver.Add(ExchangeMessageFileName());
			Archiver.Write();
			
		Except
			
			Result = False;
			GetErrorMessage(3);
			SupplementErrorMessage(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
		EndTry;
		
		Archiver = Undefined;
		
		If Result Then
			
			// 
			If DataExchangeServer.ExchangeMessageSizeExceedsAllowed(ArchiveTempFileName, MaxMessageSize()) Then
				GetErrorMessage(108);
				Result = False;
			EndIf;
			
		EndIf;
		
		If Result Then
			
			// 
			If Not CopyFileToFTPServer(ArchiveTempFileName, OutgoingMessageFileName, SendGetDataTimeout) Then
				Result = False;
			EndIf;
			
		EndIf;
		
	Else
		
		If Result Then
			
			// 
			If DataExchangeServer.ExchangeMessageSizeExceedsAllowed(ExchangeMessageFileName(), MaxMessageSize()) Then
				GetErrorMessage(108);
				Result = False;
			EndIf;
			
		EndIf;
		
		If Result Then
			
			// 
			If Not CopyFileToFTPServer(ExchangeMessageFileName(), OutgoingMessageFileName, SendGetDataTimeout) Then
				Result = False;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function GetExchangeMessage(ExistenceCheck)
	
	ExchangeMessagesFilesTable = New ValueTable;
	ExchangeMessagesFilesTable.Columns.Add("File");
	ExchangeMessagesFilesTable.Columns.Add("Modified");
	
	Try
		FTPConnection = GetFTPConnection(SendGetDataTimeout);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetErrorMessage(102);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	MessageFileNameTemplateForSearch = StrReplace(MessageFileNameTemplate, "Message", "Message*");

	Try
		FoundFileArray = FTPConnection.FindFiles(DirectoryAtFTPServer, MessageFileNameTemplateForSearch + ".*", False);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetErrorMessage(104);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	For Each CurrentFile In FoundFileArray Do
		
		// 
		If ((Upper(CurrentFile.Extension) <> ".ZIP")
			And (Upper(CurrentFile.Extension) <> ".XML")) Then
			
			Continue;
			
		// 
		ElsIf Not CurrentFile.IsFile() Then
			
			Continue;
			
		// 
		ElsIf (CurrentFile.Size() = 0) Then
			
			Continue;
			
		EndIf;
		
		// 
		TableRow = ExchangeMessagesFilesTable.Add();
		TableRow.File           = CurrentFile;
		TableRow.Modified = CurrentFile.GetModificationTime();
		
	EndDo;
	
	If ExchangeMessagesFilesTable.Count() = 0 Then
		
		If Not ExistenceCheck Then
			GetErrorMessage(1);
		
			MessageString = NStr("en = 'The data exchange directory on the server is %1.';");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, DirectoryAtFTPServer);
			SupplementErrorMessage(MessageString);
			
			MessageString = NStr("en = 'Exchange message file name is %1 or %2';");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, MessageFileNameTemplate + ".xml", MessageFileNameTemplate + ".zip");
			SupplementErrorMessage(MessageString);
		EndIf;
		
		Return False;
		
	Else
		
		If ExistenceCheck Then
			Return True;
		EndIf;
		
		ExchangeMessagesFilesTable.Sort("Modified Desc");
		
		// 
		IncomingMessageFile = ExchangeMessagesFilesTable[0].File;
		
		FilePacked = (Upper(IncomingMessageFile.Extension) = ".ZIP");
		
		InformationRegisters.ArchiveOfExchangeMessages.PackMessageToArchive(InfobaseNode, IncomingMessageFile.FullName);
		
		If FilePacked Then
			
			// 
			ArchiveTempFileName = CommonClientServer.GetFullFileName(ExchangeMessageDirectoryName(), MessageFileNameTemplate + ".zip");
			
			Try
				FTPConnection.Get(IncomingMessageFile.FullName, ArchiveTempFileName);
			Except
				ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				GetErrorMessage(105);
				SupplementErrorMessage(ErrorText);
				Return False;
			EndTry;
			
			// 
			SuccessfullyUnpacked = DataExchangeServer.UnpackZipFile(ArchiveTempFileName, ExchangeMessageDirectoryName(), ArchivePasswordExchangeMessages);
			
			If Not SuccessfullyUnpacked Then
				GetErrorMessage(2);
				Return False;
			EndIf;
			
			// 
			File = New File(ExchangeMessageFileName());
			
			If Not File.Exists() Then
				// 
				ArchiveFileNameStructure = CommonClientServer.ParseFullFileName(IncomingMessageFile.Name,False);
				MessageFileNameStructure = CommonClientServer.ParseFullFileName(ExchangeMessageFileName(),False);
				
				If ArchiveFileNameStructure.BaseName <> MessageFileNameStructure.BaseName Then
					UnpackedFilesArray = FindFiles(ExchangeMessageDirectoryName(), "*.xml", False);
					If UnpackedFilesArray.Count() > 0 Then
						UnpackedFile = UnpackedFilesArray[0];
						MoveFile(UnpackedFile.FullName,ExchangeMessageFileName());
					Else
						GetErrorMessage(7);
						Return False;
					EndIf;
				Else
					GetErrorMessage(7);
					Return False;
				EndIf;
				
			EndIf;
			
		Else
			Try
				FTPConnection.Get(IncomingMessageFile.FullName, ExchangeMessageFileName());
			Except
				ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				GetErrorMessage(105);
				SupplementErrorMessage(ErrorText);
				Return False;
			EndTry;
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

Procedure GetErrorMessage(MessageNo)
	
	SetErrorMessageString(ErrorsMessages[MessageNo]);
	
EndProcedure

Procedure SetErrorMessageString(Val Message)
	
	If Message = Undefined Then
		Message = NStr("en = 'Internal error';");
	EndIf;
	
	ErrorMessageString   = Message;
	ErrorMessageStringEL = ObjectName + ": " + Message;
	
EndProcedure

Procedure SupplementErrorMessage(Message)
	
	ErrorMessageStringEL = ErrorMessageStringEL + Chars.LF + Message;
	
EndProcedure

// An overridable function that returns the maximum allowed size
// of a message that can be sent.
// 
Function MaxMessageSize()
	
	Return FTPConnectionMaxMessageSize;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// 

Function CompressOutgoingMessageFile()
	
	Return FTPCompressOutgoingMessageFile;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Initialize

Procedure InitMessages()
	
	ErrorMessageString   = "";
	ErrorMessageStringEL = "";
	
EndProcedure

Procedure ErrorMessageInitialization()
	
	ErrorsMessages = New Map;
	
	// 
	ErrorsMessages.Insert(001, NStr("en = 'No message file with data was found in the exchange directory.';"));
	ErrorsMessages.Insert(002, NStr("en = 'Error extracting message file.';"));
	ErrorsMessages.Insert(003, NStr("en = 'Error packing the exchange message file.';"));
	ErrorsMessages.Insert(004, NStr("en = 'An error occurred when creating a temporary directory.';"));
	ErrorsMessages.Insert(005, NStr("en = 'The archive does not contain the exchange message file.';"));
	
	// 
	ErrorsMessages.Insert(101, NStr("en = 'Path on the server is not specified.';"));
	ErrorsMessages.Insert(102, NStr("en = 'An error occurred when initializing connection to the FTP server.';"));
	ErrorsMessages.Insert(103, NStr("en = 'An error occurred when establishing connection to the FTP server. Check whether the path is specified correctly and access rights are sufficient.';"));
	ErrorsMessages.Insert(104, NStr("en = 'Error searching for files on the FTP server.';"));
	ErrorsMessages.Insert(105, NStr("en = 'Error receiving the file from the FTP server.';"));
	ErrorsMessages.Insert(106, NStr("en = 'Error deleting the file from the FTP server. Check whether resource access rights are sufficient.';"));
	
	ErrorsMessages.Insert(108, NStr("en = 'The maximum allowed exchange message size is exceeded.';"));
	
	ErrorsMessages.Insert(109, NStr("en = 'An error occurred during the attempt to establish an active connection to the FTP server. Try establishing a passive connection.';"));
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// 

Function GetFTPConnection(Timeout)
	
	FTPSettings = DataExchangeServer.FTPConnectionSetup(Timeout);
	FTPSettings.Server               = FTPServerName;
	FTPSettings.Port                 = FTPConnectionPort;
	FTPSettings.UserName      = FTPConnectionUser;
	FTPSettings.UserPassword   = FTPConnectionPassword;
	FTPSettings.PassiveConnection  = FTPConnectionPassiveConnection;
	FTPSettings.SecureConnection = DataExchangeServer.SecureConnection(FTPConnectionPath);
	
	Return DataExchangeServer.FTPConnection(FTPSettings);
	
EndFunction

Function CopyFileToFTPServer(Val SourceFileName, ReceiverFileName, Val Timeout)
	
	Var DirectoryAtServer;
	
	ServerAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(FTPConnectionPath));
	DirectoryAtServer = ServerAndDirectoryAtServer.DirectoryName;
	
	Try
		FTPConnection = GetFTPConnection(Timeout);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetErrorMessage(102);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	If Timeout = ConnectionCheckTimeout 
		And FTPConnection.PassiveMode 
		And Not FTPConnectionPassiveConnection Then	
		ErrorText = "";
		GetErrorMessage(109);
		SupplementErrorMessage(ErrorText);		
		Return False;
	EndIf;
	
	CreateDirectoryIfNecessary(FTPConnection, DirectoryAtServer);
	
	Try
		FTPConnection.Put(SourceFileName, DirectoryAtServer + ReceiverFileName);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetErrorMessage(103);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	If Common.DataSeparationEnabled() Then
		Return True;
	EndIf;
	
	Try
		FilesArray = FTPConnection.FindFiles(DirectoryAtServer, ReceiverFileName, False);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetErrorMessage(104);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	Return FilesArray.Count() > 0;
	
EndFunction

Procedure CreateDirectoryIfNecessary(FTPConnection, DirectoryAtServer)
	
	If DirectoryAtServer = "/" Then
		Return;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		
		// 
		//  
		// 
		Try
			FTPConnection.CreateDirectory(DirectoryAtServer);
		Except
			// 
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
	
	ServerAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(FTPConnectionPath));
	DirectoryAtServer = ServerAndDirectoryAtServer.DirectoryName;
	
	Try
		FTPConnection = GetFTPConnection(ConnectionCheckTimeout);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetErrorMessage(102);
		SupplementErrorMessage(ErrorText);
		Return False;
	EndTry;
	
	Try
		FTPConnection.Delete(DirectoryAtServer + FileName);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		GetErrorMessage(106);
		SupplementErrorMessage(ErrorText);
		
		If ConnectionCheckUp Then
			
			ErrorMessage = NStr("en = 'Cannot check connection using test file ""%1"".
			|Maybe, the specified directory does not exist or is unavailable.
			|Check FTP server documentation to configure support of Cyrillic file names.';");
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, FileName);
			SupplementErrorMessage(ErrorMessage);
			
		EndIf;
		
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function SplitFTPResourceToServerAndDirectory(Val FullPath)
	
	Result = New Structure("ServerName, DirectoryName");
	
	FTPParameters = DataExchangeServer.FTPServerNameAndPath(FullPath);
	
	Result.ServerName  = FTPParameters.Server;
	Result.DirectoryName = FTPParameters.Path;
	
	Return Result;
EndFunction

#EndRegion

#Region Initialize

InitMessages();
ErrorMessageInitialization();

TempExchangeMessagesDirectory = Undefined;
TempExchangeMessageFile    = Undefined;

FTPServerName       = Undefined;
DirectoryAtFTPServer = Undefined;

ObjectName = NStr("en = 'Data processor: %1';");
ObjectName = StringFunctionsClientServer.SubstituteParametersToString(ObjectName, Metadata().Name);

SendGetDataTimeout = 12*60*60;
ConnectionCheckTimeout = 10;

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf