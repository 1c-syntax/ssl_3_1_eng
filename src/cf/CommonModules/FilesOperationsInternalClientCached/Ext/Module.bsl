///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns the session parameter pathname of the user's Workdirectory.
Function UserWorkingDirectory() Export
	
	ParameterName = "StandardSubsystems.WorkingDirectoryAccessCheckExecuted";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, False);
	EndIf;
	
	DirectoryName =
		StandardSubsystemsClient.ClientRunParameters().PersonalFilesOperationsSettings.PathToLocalFileCache;
	
	// 
	If DirectoryName <> Undefined
		And Not IsBlankString(DirectoryName)
		And ApplicationParameters["StandardSubsystems.WorkingDirectoryAccessCheckExecuted"] Then
		
		Return DirectoryName;
	EndIf;
	
	If DirectoryName = Undefined Then
		DirectoryName = FilesOperationsInternalClient.SelectPathToUserDataDirectory();
		If Not IsBlankString(DirectoryName) Then
			FilesOperationsInternalClient.SetUserWorkingDirectory(DirectoryName);
		Else
			ApplicationParameters["StandardSubsystems.WorkingDirectoryAccessCheckExecuted"] = True;
			Return ""; // 
		EndIf;
	EndIf;
	
#If Not WebClient Then
	
	// 
	Try
		// 
		// 
		InformationAboutTheCatalog = New File(DirectoryName);
		If Not InformationAboutTheCatalog.Exists() Then
			Raise NStr("en = 'Directory does not exist.';");
		EndIf;

		CreateDirectory(DirectoryName);
		TestDirectoryName = DirectoryName + "CheckAccess\";
		CreateDirectory(TestDirectoryName);
		DeleteFiles(TestDirectoryName);
	Except
		// 
		// 
		EventLogMessage = NStr("en = 'Working directory %1 is not found or there is no save permission. Default settings are restored.';");
		EventLogMessage = StringFunctionsClientServer.SubstituteParametersToString(EventLogMessage, DirectoryName);
		DirectoryName = FilesOperationsInternalClient.SelectPathToUserDataDirectory();
		FilesOperationsInternalClient.SetUserWorkingDirectory(DirectoryName);
		
		EventLogClient.AddMessageForEventLog(
			NStr("en = 'File management';", CommonClient.DefaultLanguageCode()),
			"Warning",
			EventLogMessage,
			CommonClient.SessionDate(),
			True);

	EndTry;
	
#EndIf
	
	ApplicationParameters["StandardSubsystems.WorkingDirectoryAccessCheckExecuted"] = True;
	
	Return DirectoryName;
	
EndFunction

Function IsDirectoryFiles(FilesOwner) Export
	
	Return FilesOperationsInternalServerCall.IsDirectoryFiles(FilesOwner);
	
EndFunction

Function CurrentSessionStart() Export
	Return FilesOperationsInternalServerCall.CurrentSessionStart();
EndFunction

#EndRegion
