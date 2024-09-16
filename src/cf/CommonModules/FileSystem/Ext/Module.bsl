///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region TemporaryFiles

////////////////////////////////////////////////////////////////////////////////
// 

// Creates a temporary folder. After you finish working with the temporary directory, you must delete 
// it using the file System.Delete the temporary directory.
//
// Parameters:
//   Extension - String -  a directory extension that identifies the purpose of the temporary directory
//                         and the subsystem that created it.
//                         It is recommended to indicate in English.
//
// Returns:
//   String - 
//
Function CreateTemporaryDirectory(Val Extension = "") Export
	
	PathToDirectory = CommonClientServer.AddLastPathSeparator(GetTempFileName(Extension));
	CreateDirectory(PathToDirectory);
	Return PathToDirectory;
	
EndFunction

// Deletes the temporary directory along with its contents, if possible.
// If the temporary directory cannot be deleted (for example, it is occupied by a process),
// a corresponding warning is written to the log, and the procedure is terminated.
//
// For sharing with the file System.Create 
// a temporary directory after you finish working with the temporary directory.
//
// Parameters:
//   Path - String -  full path to the temporary directory.
//
Procedure DeleteTemporaryDirectory(Val Path) Export
	
	If Not IsTempFileName(Path) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of parameter %1 in %2:
				|The catalog is not temporary ""%3"".';"), 
			"Path", "FileSystem.DeleteTemporaryDirectory", Path);
	EndIf;
	
	DeleteTempFiles(Path);
	
EndProcedure

// Deletes the temporary file.
// 
// Throws an exception if the name of a non-temporary file is passed.
// 
// If the temporary file cannot be deleted (for example, it is occupied by some process),
// then a corresponding warning is written to the log, and the procedure is terminated.
//
// For sharing with the Get a Temporary File method, 
// after finishing working with the temporary file.
//
// Parameters:
//   Path - String -  full path to the temporary file.
//
Procedure DeleteTempFile(Val Path) Export
	
	If Not IsTempFileName(Path) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of parameter %1 in %2:
				|The file is not temporary ""%3"".';"), 
			"Path", "FileSystem.DeleteTempFile", Path);
	EndIf;
	
	DeleteTempFiles(Path);
	
EndProcedure

// Generates a unique file name in the specified folder, if necessary, adding an ordinal number to the file name,
// for example: "file (2). txt", "file (3). txt", etc.
//
// Parameters:
//   FileName - String -  the full name of the file with the folder, for example, " C:\Документы\файл.txt".
//
// Returns:
//   String - 
//
Function UniqueFileName(Val FileName) Export
	
	Return FileSystemInternalClientServer.UniqueFileName(FileName);

EndFunction

#EndRegion

#Region RunExternalApplications

////////////////////////////////////////////////////////////////////////////////
// 

// Parameter constructor for the file System.Run the program.
//
// Returns:
//  Structure:
//    * CurrentDirectory - String -  sets the current folder of the application to launch.
//    * WaitForCompletion - Boolean -  False - wait for the running application 
//         to finish before continuing.
//    * GetOutputStream - Boolean -  False-the result sent to the stdout stream,
//         if wait for Completion is not specified, is ignored.
//    * GetErrorStream - Boolean -  False-errors sent to the stderr stream,
//         if wait for Completion is not specified - ignored.
//    * ThreadsEncoding - TextEncoding
//                       - String - 
//         
//    * ExecutionEncoding - String
//                          - Number - 
//             
//         
//             
//         
//
Function ApplicationStartupParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("CurrentDirectory", "");
	Parameters.Insert("WaitForCompletion", False);
	Parameters.Insert("GetOutputStream", False);
	Parameters.Insert("GetErrorStream", False);
	Parameters.Insert("ThreadsEncoding", Undefined);
	Parameters.Insert("ExecutionEncoding", Undefined);
	
	Return Parameters;
	
EndFunction

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
//  StartupCommand - String -  command line for running the program.
//                 - Array -  
//                            
//                            
//  ApplicationStartupParameters - See FileSystem.ApplicationStartupParameters
//
// Returns:
//  Structure:
//    * ReturnCode - Number  -  the return code of the program;
//    * OutputStream - String -  the result of the program sent to the stdout stream;
//    * ErrorStream - String -  program execution errors sent to the stderr stream.
//
// Example:
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
//	
//	
//	
//
Function StartApplication(Val StartupCommand, ApplicationStartupParameters = Undefined) Export 
	
	// 
	
	CommandString = CommonInternalClientServer.SafeCommandString(StartupCommand);
	
	If ApplicationStartupParameters = Undefined Then 
		ApplicationStartupParameters = ApplicationStartupParameters();
	EndIf;
	
	CurrentDirectory = ApplicationStartupParameters.CurrentDirectory;
	WaitForCompletion = ApplicationStartupParameters.WaitForCompletion;
	GetOutputStream = ApplicationStartupParameters.GetOutputStream;
	GetErrorStream = ApplicationStartupParameters.GetErrorStream;
	ThreadsEncoding = ApplicationStartupParameters.ThreadsEncoding;
	ExecutionEncoding = ApplicationStartupParameters.ExecutionEncoding;
	
	CheckCurrentDirectory(CommandString, CurrentDirectory);
	
	If WaitForCompletion Then 
		If GetOutputStream Then 
			OutputThreadFileName = GetTempFileName("stdout.tmp");
			CommandString = CommandString + " > """ + OutputThreadFileName + """";
		EndIf;
		
		If GetErrorStream Then 
			ErrorsThreadFileName = GetTempFileName("stderr.tmp");
			CommandString = CommandString + " 2>""" + ErrorsThreadFileName + """";
		EndIf;
	EndIf;
	
	If ThreadsEncoding = Undefined Then 
		ThreadsEncoding = StandardStreamEncoding();
	EndIf;
	
	// 
	If ExecutionEncoding = Undefined And Common.IsWindowsServer() Then 
		ExecutionEncoding = "CP866";
	EndIf;
	
	ReturnCode = Undefined;
	
	If Common.IsWindowsServer() Then
		
		CommandString = CommonInternalClientServer.TheWindowsCommandStartLine(
			CommandString, CurrentDirectory, WaitForCompletion, ExecutionEncoding);
		
		If Common.FileInfobase() Then
			// 
			Shell = New COMObject("Wscript.Shell");
			ReturnCode = Shell.Run(CommandString, 0, WaitForCompletion);
			Shell = Undefined;
		Else
			RunApp(CommandString,, WaitForCompletion, ReturnCode);
		EndIf;
		
	Else
		
		If Common.IsLinuxServer() And ValueIsFilled(ExecutionEncoding) Then
			CommandString = "LANGUAGE=" + ExecutionEncoding + " " + CommandString;
		EndIf;
		
		RunApp(CommandString, CurrentDirectory, WaitForCompletion, ReturnCode);
	EndIf;
	
	OutputStream = "";
	ErrorStream = "";
	
	If WaitForCompletion Then 
		If GetOutputStream Then
			OutputStream = ReadFileIfExists(OutputThreadFileName, ThreadsEncoding);
			DeleteTempFile(OutputThreadFileName);
		EndIf;
		
		If GetErrorStream Then 
			ErrorStream = ReadFileIfExists(ErrorsThreadFileName, ThreadsEncoding);
			DeleteTempFile(ErrorsThreadFileName);
		EndIf;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ReturnCode", ReturnCode);
	Result.Insert("OutputStream", OutputStream);
	Result.Insert("ErrorStream", ErrorStream);
	
	Return Result;
	
	// 
	
EndFunction

#EndRegion

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
//  NestedDirectory - String - 
// 
// Returns:
//  String - 
//
Function SharedDirectoryOfTemporaryFiles(NestedDirectory = Undefined) Export
	
	If Common.FileInfobase() And Not Common.DebugMode() Then
		
		Return TempFilesDirName(NestedDirectory);
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	CommonPlatformType = "";
	If Common.IsWindowsServer() Then
		
		Result         = Constants.WindowsTemporaryFilesDerectory.Get();
		CommonPlatformType = "Windows";
		
	Else
		
		Result         = Constants.LinuxTemporaryFilesDerectory.Get();
		CommonPlatformType = "Linux";
		
	EndIf;
	
	SetPrivilegedMode(False);
	
	If IsBlankString(Result) Then
		
		Return TempFilesDirName(NestedDirectory);
		
	Else
		
		Result = TrimAll(Result);
		
		Directory = New File(Result);
		If Not Directory.Exists() Then
			
			ConstantPresentation = ?(CommonPlatformType = "Windows", 
				Metadata.Constants.WindowsTemporaryFilesDerectory.Presentation(),
				Metadata.Constants.LinuxTemporaryFilesDerectory.Presentation());
			
			MessageTemplate = NStr("en = 'Temporary file directory does not exist.
					|Ensure that the value is valid for the parameter:
					|""%1"".';", Common.DefaultLanguageCode());
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ConstantPresentation);
			Raise(MessageText);
			
		EndIf;
		
		If ValueIsFilled(NestedDirectory) Then
			Result = CommonClientServer.AddLastPathSeparator(Result) + NestedDirectory;
			CreateDirectory(Result);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction
	
#EndRegion

#Region Private

Procedure DeleteTempFiles(Val Path)
	
	Try
		DeleteFiles(Path);
	Except
		WriteLogEvent(
			NStr("en = 'Standard subsystems';", Common.DefaultLanguageCode()),
			EventLogLevel.Warning,,, // 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot delete temporary file %1. Reason:
					|%2';"),
				Path,
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
	EndTry;
	
EndProcedure

Function IsTempFileName(Path)
	
	// 
	// 
	Return StrStartsWith(StrReplace(Path, "/", "\"), StrReplace(TempFilesDir(), "/", "\"));
	
EndFunction

#Region StartApplication

Procedure CheckCurrentDirectory(CommandString, CurrentDirectory)
	
	If Not IsBlankString(CurrentDirectory) Then 
		
		FileInfo3 = New File(CurrentDirectory);
		
		If Not FileInfo3.Exists() Then 
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Couldn''t start %1.
				           |Reason:
				           |The catalog %2 does not exist
				           |%3';"),
				CommandString, "CurrentDirectory", CurrentDirectory);
		EndIf;
		
		If Not FileInfo3.IsDirectory() Then 
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Couldn''t start %1.
				           |Reason:
				           |%2 is not a directory:
				           |%3';"),
				CommandString, "CurrentDirectory", CurrentDirectory);
		EndIf;
		
	EndIf;
	
EndProcedure

Function TempFilesDirName(NestedDirectory)
	
	Result = CommonClientServer.AddLastPathSeparator(TempFilesDir());
	If ValueIsFilled(NestedDirectory) Then
		Result = Result + CommonClientServer.AddLastPathSeparator(NestedDirectory);
	EndIf;
	
	CreateDirectory(Result);
	
	Return Result;
	
EndFunction

Function ReadFileIfExists(Path, Encoding)
	
	Result = Undefined;
	FileInfo3 = New File(Path);
	
	If FileInfo3.Exists() Then 
		
		ErrorStreamReader = New TextReader(Path, Encoding);
		Result = ErrorStreamReader.Read();
		ErrorStreamReader.Close();
		
	EndIf;
	
	If Result = Undefined Then 
		Result = "";
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the standard output and error stream encoding used in the current OS.
//
// Returns:
//  TextEncoding
//
Function StandardStreamEncoding()
	
	If Common.IsWindowsServer() Then
		Encoding = "CP866";
	Else
		Encoding = "UTF-8";
	EndIf;
	
	Return Encoding;
	
EndFunction

#EndRegion

#EndRegion