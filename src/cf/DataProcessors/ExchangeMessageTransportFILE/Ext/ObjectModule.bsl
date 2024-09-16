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
Var ObjectName; // 

Var TempExchangeMessageFile; // 
Var TempExchangeMessagesDirectory; // 
Var DataExchangeDirectory; // 

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
	
	Result = True;
	
	InitMessages();
	
	Try
		
		If UseTempDirectoryToSendAndReceiveMessages Then
			
			Result = SendExchangeMessage();
			
		EndIf;
		
	Except
		Result = False;
	EndTry;
	
	Return Result;
	
EndFunction

// Retrieves the exchange message from the specified resource to the temporary directory of the exchange message.
//
// Parameters:
//   ExistenceCheck - Boolean
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
	
	If UseTempDirectoryToSendAndReceiveMessages Then
		
		DeleteTempExchangeMessagesDirectory();
		
	EndIf;
	
	Return True;
EndFunction

// Initializes processing properties with initial values and constants.
//
// Parameters:
//  No.
// 
Procedure Initialize() Export
	
	DataExchangeDirectory = New File(FILEDataExchangeDirectory);
	
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
	
	InitMessages();
	
	If IsBlankString(FILEDataExchangeDirectory) Then
		
		GetErrorMessage(1);
		Return False;
		
	ElsIf Not DataExchangeDirectory.Exists() Then
		
		GetErrorMessage(2);
		Return False;
	EndIf;
	
	CheckFileName = DataExchangeServer.TempConnectionTestFileName();
	
	If Not CreateCheckFile(CheckFileName) Then
		
		GetErrorMessage(8);
		Return False;
		
	ElsIf Not DeleteCheckFile(CheckFileName) Then
		
		GetErrorMessage(9);
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// 

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

// Function-property: full name of the information exchange directory (network or local resource).
//
// Returns:
//  String - 
//
Function DataExchangeDirectoryName() Export
	
	Name = "";
	
	If TypeOf(DataExchangeDirectory) = Type("File") Then
		
		Name = DataExchangeDirectory.FullName;
		
	EndIf;
	
	Return Name;
	
EndFunction

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

///////////////////////////////////////////////////////////////////////////////
// 

Function CreateTempExchangeMessagesDirectory()
	
	If UseTempDirectoryToSendAndReceiveMessages Then
		
		// 
		Try
			TempDirectoryName = DataExchangeServer.CreateTempExchangeMessagesDirectory(DirectoryID);
		Except
			GetErrorMessage(6);
			SupplementErrorMessage(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Return False;
		EndTry;
		
		TempExchangeMessagesDirectory = New File(TempDirectoryName);
		
	Else
		
		TempExchangeMessagesDirectory = New File(DataExchangeDirectoryName());
		
	EndIf;
	
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
	
	Extension = ?(CompressOutgoingMessageFile(), "zip", "xml");
	
	OutgoingMessageFileName = CommonClientServer.GetFullFileName(DataExchangeDirectoryName(), MessageFileNameTemplate + "." + Extension);
	
	If CompressOutgoingMessageFile() Then
		
		// 
		ArchiveTempFileName = CommonClientServer.GetFullFileName(ExchangeMessageDirectoryName(), MessageFileNameTemplate + ".zip");
		
		Try
			
			Archiver = New ZipFileWriter(ArchiveTempFileName, ArchivePasswordExchangeMessages, NStr("en = 'Exchange message file';"));
			Archiver.Add(ExchangeMessageFileName());
			Archiver.Write();
			
		Except
			Result = False;
			GetErrorMessage(5);
			SupplementErrorMessage(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;
		
		Archiver = Undefined;
		
		If Result Then
			
			// 
			If Not ExecuteFileCopying(ArchiveTempFileName, OutgoingMessageFileName) Then
				Result = False;
			EndIf;
			
		EndIf;
		
	Else
		
		// 
		If Not ExecuteFileCopying(ExchangeMessageFileName(), OutgoingMessageFileName) Then
			Result = False;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function GetExchangeMessage(ExistenceCheck)
	
	ExchangeMessagesFilesTable = New ValueTable;
	ExchangeMessagesFilesTable.Columns.Add("File", New TypeDescription("File"));
	ExchangeMessagesFilesTable.Columns.Add("Modified");
	MessageFileNameTemplateForSearch = StrReplace(MessageFileNameTemplate, "Message", "Message*");
	
	FoundFileArray = FindFiles(DataExchangeDirectoryName(), MessageFileNameTemplateForSearch + ".*", False);
	
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
			GetErrorMessage(3);
		
			MessageString = NStr("en = 'Data exchange directory is %1';");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, DataExchangeDirectoryName());
			SupplementErrorMessage(MessageString);
			
			MessageString = NStr("en = 'Exchange message file name is %1 or %2';");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, MessageFileNameTemplateForSearch + ".xml", MessageFileNameTemplateForSearch + ".zip");
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
		If Not StrStartsWith(IncomingMessageFile.Name, MessageFileNameTemplate) Then
			// 
			FileNameStructure = CommonClientServer.ParseFullFileName(IncomingMessageFile.Name,False);
			MessageFileNameTemplate = FileNameStructure.BaseName;
		EndIf;
		
		InformationRegisters.ArchiveOfExchangeMessages.PackMessageToArchive(InfobaseNode, IncomingMessageFile.FullName); 
		
		If FilePacked Then
			
			// 
			ArchiveTempFileName = CommonClientServer.GetFullFileName(ExchangeMessageDirectoryName(), MessageFileNameTemplate + ".zip");
			
			// 
			If Not ExecuteFileCopying(IncomingMessageFile.FullName, ArchiveTempFileName) Then
				Return False;
			EndIf;
			
			// 
			SuccessfullyUnpacked = DataExchangeServer.UnpackZipFile(ArchiveTempFileName, ExchangeMessageDirectoryName(), ArchivePasswordExchangeMessages);
			
			If Not SuccessfullyUnpacked Then
				GetErrorMessage(4);
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
			
			// 
			If UseTempDirectoryToSendAndReceiveMessages And Not ExecuteFileCopying(IncomingMessageFile.FullName, ExchangeMessageFileName()) Then
				
				Return False;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return True;
EndFunction

Function CreateCheckFile(CheckFileName)
	
	TextDocument = New TextDocument;
	TextDocument.AddLine(NStr("en = 'Temporary file for checking';"));
	
	Try
		
		TextDocument.Write(CommonClientServer.GetFullFileName(DataExchangeDirectoryName(), CheckFileName));
		
	Except
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(), EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	Return True;
EndFunction

Function DeleteCheckFile(CheckFileName)
	
	Try
		
		DeleteFiles(DataExchangeDirectoryName(), CheckFileName);
		
	Except
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(), EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	Return True;
EndFunction

Function ExecuteFileCopying(Val SourceFileName, Val ReceiverFileName)
	
	Try
		
		DeleteFiles(ReceiverFileName);
		FileCopy(SourceFileName, ReceiverFileName);
		
	Except
		
		MessageString = NStr("en = 'An error occurred while copying a file from %1 to %2. Error details: %3';");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
							SourceFileName,
							ReceiverFileName,
							ErrorProcessing.BriefErrorDescription(ErrorInfo()));
							
		SetErrorMessageString(MessageString);
		
		Return False
		
	EndTry;
	
	Return True;
	
EndFunction

Procedure GetErrorMessage(MessageNo)
	
	SetErrorMessageString(ErrorsMessages[MessageNo])
	
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

///////////////////////////////////////////////////////////////////////////////
// 

Function CompressOutgoingMessageFile()
	
	Return FILECompressOutgoingMessageFile;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Initialize

Procedure InitMessages()
	
	ErrorMessageString   = "";
	ErrorMessageStringEL = "";
	
EndProcedure

Procedure ErrorMessageInitialization()
	
	ErrorsMessages = New Map;
	ErrorsMessages.Insert(1, NStr("en = 'Connection error: The data exchange directory is not specified.';"));
	ErrorsMessages.Insert(2, NStr("en = 'Connection error: The data exchange directory does not exist.';"));
	
	ErrorsMessages.Insert(3, NStr("en = 'No message file with data was found in the exchange directory.';"));
	ErrorsMessages.Insert(4, NStr("en = 'Error extracting message file.';"));
	ErrorsMessages.Insert(5, NStr("en = 'Error packing the exchange message file.';"));
	ErrorsMessages.Insert(6, NStr("en = 'An error occurred when creating a temporary directory';"));
	ErrorsMessages.Insert(7, NStr("en = 'The archive does not contain the exchange message file';"));
	
	ErrorsMessages.Insert(8, NStr("en = 'An error occurred when saving the file to the data exchange directory. Check if the user is authorized to access the directory.';"));
	ErrorsMessages.Insert(9, NStr("en = 'An error occurred when removing the file from the data exchange directory. Check if the user is authorized to access the directory.';"));
	
EndProcedure

#EndRegion

#Region Initialize

InitMessages();
ErrorMessageInitialization();

TempExchangeMessagesDirectory = Undefined;
TempExchangeMessageFile    = Undefined;

ObjectName = NStr("en = 'Data processor: %1';");
ObjectName = StringFunctionsClientServer.SubstituteParametersToString(ObjectName, Metadata().Name);

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf