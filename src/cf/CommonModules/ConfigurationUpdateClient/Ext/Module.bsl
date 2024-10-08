﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns whether installation of configuration updates is supported on this computer.
// Install the update:
// - available only in Windows OS;
// - not available when connecting via a web server (because the update is performed via a batch launch of the Configurator,
//   which performs a direct connection to the information database);
// - possible if the Configurator is installed (full distribution of the 1C technology platform:Enterprise for Windows);
// - available if you have administrative rights.
// - not available in the service model (performed centrally via the service Manager).
//
// Returns:
//    Structure:
//     * Supported - Boolean -  True if the installation of the configuration updates are supported.
//     * ErrorDescription - String -  description of the error if not supported.
//
Function UpdatesInstallationSupported() Export
	
	Result = New Structure;
	Result.Insert("Supported", False);
	Result.Insert("InstallationOfPatchesIsSupported", False);
	Result.Insert("ErrorDescription", "");
	
	If CommonClient.DataSeparationEnabled() Then
		Result.ErrorDescription = 
			NStr("en = 'Cloud applications support only centralized updates initiated from the service manager.';");
		Return Result;
	EndIf;
	
	If Not UsersClient.IsFullUser(True) Then
		Result.ErrorDescription = NStr("en = 'You need the administrator rights to install the update.';");
		Return Result;
	EndIf;
	
#If WebClient Then
	
	Result.InstallationOfPatchesIsSupported = True;
	Result.ErrorDescription =
		NStr("en = 'Only patch installation is available in the web client.
			|To install the update, install
			|the distribution package of 1C:Enterprise for Windows.';");
	
#ElsIf MobileClient Then
	Result.ErrorDescription = NStr("en = 'The update is available only on Windows.';");
#Else
	
	If Not CommonClient.IsWindowsClient() Then 
		Result.ErrorDescription = NStr("en = 'The update is available only on Windows.';");
	EndIf;
	
	If CommonClient.ClientConnectedOverWebServer() Then 
		If Not IsBlankString(Result.ErrorDescription) Then
			Result.ErrorDescription = Result.ErrorDescription + Chars.LF + Chars.LF; 
		EndIf;
		
		Result.InstallationOfPatchesIsSupported = True;
		Result.ErrorDescription = Result.ErrorDescription
			+ NStr("en = 'Only patch installation is available from the web server.
				|To install the update, install
				|the distribution package of 1C:Enterprise for Windows.';");
	EndIf;
	
	If Not DesignerBatchModeSupported() Then 
		If Not IsBlankString(Result.ErrorDescription) Then
			Result.ErrorDescription = Result.ErrorDescription + Chars.LF + Chars.LF; 
		EndIf;
		
		Result.ErrorDescription = Result.ErrorDescription
			+ NStr("en = 'Designer is required to install the update.
				|Install the distribution package for 1C:Enterprise for Windows.';");
	EndIf;
	
#EndIf
	
	Result.Supported = IsBlankString(Result.ErrorDescription);
	
	If Result.Supported Then 
		Result.InstallationOfPatchesIsSupported = True;
	EndIf;
	
	Return Result;
	
EndFunction

// Opens the update installation form with the specified parameters.
//
// Parameters:
//    UpdateIntallationParameters - Structure - :
//     * ShouldExitApp - Boolean -  True if the program terminates after installing the update. 
//                                          False by default.
//     * IsConfigurationUpdateReceived - Boolean -  True if the update being installed is received from an application 
//                                          on the Internet. By default, False is the normal update installation mode.
//     * RunUpdate     - Boolean -  True if you need to skip selecting the update file and go straight
//                                          to installing the update. By default, False-offer a choice.
//
Procedure ShowUpdateSearchAndInstallation(UpdateIntallationParameters = Undefined) Export
	
	Result = UpdatesInstallationSupported();
	If Result.Supported
		Or Result.InstallationOfPatchesIsSupported Then
		
		OpenForm("DataProcessor.InstallUpdates.Form", UpdateIntallationParameters);
	Else 
		ShowMessageBox(, Result.ErrorDescription);
	EndIf;
	
EndProcedure

// Displays the backup settings form.
//
// Parameters:
//    BackupParameters - Structure - :
//      * CreateDataBackup - Number -  0, Do not create an IB backup;
//                                          1, Create a temporary backup of the IB;
//                                          2, Create a backup copy of the IB.
//      * IBBackupDirectoryName - String -  the folder where the backup is saved.
//      * RestoreInfobase - Boolean -  perform a rollback in case of an emergency.
//    NotifyDescription - NotifyDescription -  description of the alert the form is closed.
//
Procedure ShowBackup(BackupParameters, NotifyDescription) Export
	
	OpenForm("DataProcessor.InstallUpdates.Form.BackupCreationSetup", BackupParameters,,,,, NotifyDescription);
	
EndProcedure

#Region ForCallsFromOtherSubsystems

// 

// Returns the title text of the backup settings to display on the form.
//
// Parameters:
//    Parameters - Structure -  backup settings.
//
// Returns:
//    String - 
//
Function BackupCreationTitle(Parameters) Export
	
	If Parameters.CreateDataBackup = 0 Then
		Return NStr("en = 'Do not back up the infobase';");
	ElsIf Parameters.CreateDataBackup = 1 Then
		If Parameters.RestoreInfobase Then 
			Return NStr("en = 'Create a temporary infobase backup and roll back if any issues occur';");
		Else 
			Return NStr("en = 'Create a temporary infobase backup and do not roll back if any issues occur';");
		EndIf;
	ElsIf Parameters.CreateDataBackup = 2 Then
		If Parameters.RestoreInfobase Then 
			Return NStr("en = 'Create an infobase backup and roll back if any issues occur';");
		Else 
			Return NStr("en = 'Create an infobase backup and do not roll back if any issues occur';");
		EndIf;
	Else
		Return "";
	EndIf;
	
EndFunction

// Checks whether the update can be installed. If possible, it runs
// the update script or schedules the update for the specified time.
//
// Parameters:
//    Form - ClientApplicationForm -  the form from which the update is installed and which should be closed at the end. 
//    Parameters - Structure - :
//        * UpdateMode - Number - :
//                                    
//        * UpdateDateTime - Date -  date of the planned update.
//        * EmailReport - Boolean -  indicates whether the report should be sent to the email address.
//        * Email - String -  e-mail address to send the report about the result updates.
//        * SchedulerTaskCode - Number -  code of the scheduled update task.
//        * UpdateFileName - String -  name of the update file to install.
//        * CreateDataBackup - Number -  indicates whether to create a backup.
//        * IBBackupDirectoryName - String -  the folder where the backup is saved.
//        * RestoreInfobase - Boolean -  indicates whether the database needs to be restored.
//        * ShouldExitApp - Boolean -  indicates that the update is being installed at shutdown.
//        * FilesOfUpdate - Array of Structure:
//           ** UpdateFileFullName - String
//           ** RunUpdateHandlers - Boolean - 
//        * Corrections - Structure:
//           ** Set - Array -  paths to patch files in temporary storage
//                                    that you want to install.
//           ** Delete    - Array -  unique IDs (string) of the fixes that you want to delete.
//        * PlatformDirectory - String -  path to the platform on which the update should be run, if not specified
//                                    runs on the platform of the current session.
//    AdministrationParameters - See StandardSubsystemsServer.AdministrationParameters.
//
Procedure InstallUpdate(Form, Parameters, AdministrationParameters) Export
	
#If Not WebClient And Not MobileClient Then
	
	If Not UpdateInstallationPossible(Parameters, AdministrationParameters) Then
		Return;
	EndIf;
	
	ConfigurationUpdateServerCall.SaveConfigurationUpdateSettings(Parameters);
	
	If Form <> Undefined Then
		If Parameters.UpdateMode = 0 Then
			ParameterName = "StandardSubsystems.SkipQuitSystemAfterWarningsHandled";
			ApplicationParameters.Insert(ParameterName, True);
			Try
				Form.Close();
			Except
				ApplicationParameters.Delete(ParameterName);
				Raise;
			EndTry;
			ApplicationParameters.Delete(ParameterName);
		Else
			Form.Close();
		EndIf;
	EndIf;
	
	If Parameters.UpdateMode = 0 Then // 
		RunUpdateScript(Parameters, AdministrationParameters);
	ElsIf Parameters.UpdateMode = 1 Then // 
		ParameterName = "StandardSubsystems.SuggestInfobaseUpdateOnExitSession";
		ApplicationParameters.Insert(ParameterName, True);
		ApplicationParameters.Insert("StandardSubsystems.UpdateFilesNames", UpdateFilesNames(Parameters, Undefined));
	ElsIf Parameters.UpdateMode = 2 Then // 
		ScheduleConfigurationUpdate(Parameters, AdministrationParameters);
	EndIf;
	
#EndIf
	
EndProcedure

// End OnlineUserSupport.GetApplicationUpdates

#EndRegion

#EndRegion

#Region Internal

Procedure ProcessUpdateResult(UpdateResult, ScriptDirectory) Export
	
	If IsBlankString(ScriptDirectory) Then
		EventLogClient.AddMessageForEventLog(EventLogEvent(),
			"Warning", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'See the update log in the temporary file folder: %1.(digits).';"), "%temp%\1Cv8Update"),, True);
		UpdateResult = True; // 
	Else 
		EventLogClient.AddMessageForEventLog(EventLogEvent(),
			"Information", 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Update log folder: %1';"), ScriptDirectory),, True);
		
#If Not WebClient And Not MobileClient Then
		ReadDataToEventLog(UpdateResult, ScriptDirectory);
#EndIf
		
	EndIf;
	
EndProcedure

Procedure WriteDownTheErrorOfTheNeedToUpdateThePlatform(ErrorText) Export
	
	ScriptDirectory = ConfigurationUpdateServerCall.ScriptDirectory();
	WriteErrorLogFileAndExit(ScriptDirectory, ErrorText);
	
EndProcedure

// Updates the database configuration.
//
// Parameters:
//  Standard processing-Boolean - if this parameter is set to False in the procedure, the manual
//                                  update instruction will not be shown.
//
Procedure InstallConfigurationUpdate(ShouldExitApp = False) Export
	
	FormParameters = New Structure("ShouldExitApp, IsConfigurationUpdateReceived",
		ShouldExitApp, ShouldExitApp);
	ShowUpdateSearchAndInstallation(FormParameters);
	
EndProcedure

// Writes an error marker file to the script directory.
//
Procedure WriteErrorLogFileAndExit(Val DirectoryName, Val DetailErrorDescription) Export
	
#If Not WebClient Then
	
	If StrFind(LaunchParameter, "UpdateAndExit") > 0 Then
		
		Directory = New File(DirectoryName);
		If Directory.Exists() And Directory.IsDirectory() Then // 
			
			ErrorRegistrationFile = New TextWriter(DirectoryName + "error.txt");
			ErrorRegistrationFile.Close();
			
			LogFile1 = New TextWriter(DirectoryName + "templog.txt", TextEncoding.System);
			LogFile1.Write(DetailErrorDescription);
			LogFile1.Close();
			
			Terminate();
			
		EndIf;
	EndIf;
	
#EndIf
	
EndProcedure

// Opens a form with a list of installed fixes.
//
Procedure ShowInstalledPatches(Parameters = Undefined, OpeningMode = Undefined) Export
	
	If Parameters = Undefined Then
		Parameters = New Structure;
	EndIf;
	
	OpenForm("CommonForm.InstalledPatches", Parameters,,,,,, OpeningMode);
	
EndProcedure

// Determines whether the extension with the passed name is a patch.
// Parameters:
//  PatchName - String -  name of the extension being checked.
//
Function IsPatch(PatchName) Export
	Return StrStartsWith(PatchName, "EF_");
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonClientOverridable.OnStart.
Procedure OnStart(Parameters) Export
	
	CheckForConfigurationUpdate();
	
EndProcedure

// Parameters:
//  Cancel - See CommonClientOverridable.BeforeExit.Cancel
//  Warnings - See CommonClientOverridable.BeforeExit.Warnings
//
Procedure BeforeExit(Cancel, Warnings) Export
	
	// 
	// 
	If ApplicationParameters["StandardSubsystems.SuggestInfobaseUpdateOnExitSession"] = True Then
		WarningParameters = StandardSubsystemsClient.WarningOnExit();
		WarningParameters.CheckBoxText  = NStr("en = 'Install configuration update';");
		WarningParameters.WarningText  = NStr("en = 'Update installation is scheduled.';");
		WarningParameters.Priority = 50;
		WarningParameters.OutputSingleWarning = True;
		
		ActionIfFlagSet = WarningParameters.ActionIfFlagSet;
		ActionIfFlagSet.Form = "DataProcessor.InstallUpdates.Form";
		ActionIfFlagSet.FormParameters = New Structure("ShouldExitApp, RunUpdate", 
			True, True);
		
		Warnings.Add(WarningParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function VersionsRequiringSuccessfulUpdate(TransferredUpdateFiles)
	FilesOfUpdate = New Array;
	For Each UpdateFile In TransferredUpdateFiles Do
		InformationRecords = New Structure;
		InformationRecords.Insert("BinaryData", New BinaryData(UpdateFile.UpdateFileFullName));
		InformationRecords.Insert("Required", UpdateFile.RunUpdateHandlers);
		FilesOfUpdate.Add(InformationRecords);
	EndDo;
	
	Return ConfigurationUpdateServerCall.VersionsRequiringSuccessfulUpdate(FilesOfUpdate);
EndFunction

Function UpdateInstallationPossible(Parameters, AdministrationParameters)
	
	Result = UpdatesInstallationSupported();
	If Not Result.Supported Then 
		ShowMessageBox(, Result.ErrorDescription);
		Return False;
	EndIf;
	
	IsFileInfobase = CommonClient.FileInfobase();
	
	If IsFileInfobase And Parameters.CreateDataBackup = 2 Then
		File = New File(Parameters.IBBackupDirectoryName);
		If Not File.Exists() Or Not File.IsDirectory() Then // 
			ShowMessageBox(,
				NStr("en = 'Please specify an existing folder for storing the infobase backup.';"));
			Return False;
		EndIf;
	EndIf;
	
	If Parameters.UpdateMode = 0 Then // 
		ParameterName = "StandardSubsystems.MessagesForEventLog";
		If IsFileInfobase
			And ConfigurationUpdateServerCall.HasActiveConnections(ApplicationParameters[ParameterName]) Then
			
			ShowMessageBox(,
				NStr("en = 'Cannot proceed with configuration update
				           |as some infobase connections were not closed.';"));
			Return False;
		EndIf;
	ElsIf Parameters.UpdateMode = 2 Then
		If Not UpdateDateCorrect(Parameters) Then
			Return False;
		EndIf;
		
		InvalidEmailSpecified = Parameters.EmailReport
			And Not CommonClientServer.EmailAddressMeetsRequirements(Parameters.Email);
		
		If InvalidEmailSpecified Then
			ShowMessageBox(,
				NStr("en = 'Please specify a valid email address.';"));
			Return False;
		EndIf;
		
		If Not JobSchedulerSupported() Then
			ShowMessageBox(,
				NStr("en = 'Job scheduler supports Windows Vista 6.0 or later.';"));
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

Function UpdateDateCorrect(Parameters)
	
	CurrentDate = CommonClient.SessionDate();
	If Parameters.UpdateDateTime < CurrentDate Then
		MessageText = NStr("en = 'A configuration update can be scheduled only for a future date and time.';");
	ElsIf Parameters.UpdateDateTime > AddMonth(CurrentDate, 1) Then
		MessageText = NStr("en = 'A configuration update cannot be scheduled to a date later than one month from the current date.';");
	EndIf;
	
	DateCorrect = IsBlankString(MessageText);
	If Not DateCorrect Then
		ShowMessageBox(, MessageText);
	EndIf;
	
	Return DateCorrect;
	
EndFunction

Procedure InsertScriptParameter(Val ParameterName, Val ParameterValue, DoFormat, ParametersArea)
	
	If DoFormat Then
		ParameterValue = DoFormat(ParameterValue);
	ElsIf TypeOf(ParameterValue) = Type("Boolean") Then
		ParameterValue = ?(ParameterValue, "true", "false");
	EndIf;
	ParametersArea = StrReplace(ParametersArea, "[" + ParameterName + "]", ParameterValue);
	
EndProcedure

Function UpdateFilesNames(Parameters, FirstFileOnly = False)
	
	ParameterName = "StandardSubsystems.UpdateFilesNames";
	If ApplicationParameters.Get(ParameterName) <> Undefined Then
		If FirstFileOnly = True Then
			Return ApplicationParameters[ParameterName].NameOfFirstFile;
		ElsIf FirstFileOnly = False Then
			If ApplicationParameters[ParameterName].Property("FilesOfUpdate") Then
				Parameters.Insert("FilesOfUpdate", ApplicationParameters[ParameterName].FilesOfUpdate);
			EndIf;
			Return ApplicationParameters[ParameterName].FilesNames;
		EndIf;
		Return ApplicationParameters[ParameterName];
	EndIf;
	
	If Parameters.Property("UpdateFileRequired") And Not Parameters.UpdateFileRequired Then
		NameOfFirstFile = "";
		UpdateFilesNames = "";
	Else
		NameOfFirstFile = Null;
		If IsBlankString(Parameters.UpdateFileName) Then
			FilesNames = New Array;
			For Each UpdateFile In Parameters.FilesOfUpdate Do
				If NameOfFirstFile = Null Then
					NameOfFirstFile = UpdateFile.UpdateFileFullName;
				EndIf;
				UpdateFilePrefix = ?(UpdateFile.RunUpdateHandlers, "+", "");
				FilesNames.Add(DoFormat(UpdateFilePrefix + UpdateFile.UpdateFileFullName));
			EndDo;
			UpdateFilesNames = StrConcat(FilesNames, ",");
		Else
			UpdateFilesNames = DoFormat(Parameters.UpdateFileName);
			NameOfFirstFile = Parameters.UpdateFileName;
		EndIf;
	EndIf;
	
	NameOfFirstFile = ?(NameOfFirstFile = Null, "", NameOfFirstFile);
	UpdateFilesNames = "[" + UpdateFilesNames + "]";
	
	If FirstFileOnly = True Then
		Return NameOfFirstFile;
	ElsIf FirstFileOnly = False Then
		Return UpdateFilesNames;
	EndIf;
	
	Result = New Structure;
	Result.Insert("NameOfFirstFile", NameOfFirstFile);
	Result.Insert("FilesNames", UpdateFilesNames);
	If Parameters.Property("FilesOfUpdate") Then
		Result.Insert("FilesOfUpdate", Parameters.FilesOfUpdate);
	EndIf;
	
	Return Result;
	
EndFunction

Function DoFormat(Val Text)
	Text = StrReplace(Text, "\", "\\");
	Text = StrReplace(Text, """", "\""");
	Text = StrReplace(Text, "'", "\'");
	Return "'" + Text + "'";
EndFunction

Function EncodingOfTheLogFile(Val BinDir)
	
	EncodingOfTheLogFile = "UTF-8";
	PartsOfTheProgramCatalog = StrSplit(BinDir, GetPathSeparator(), False);
	For Each ProgramVersionNumber In PartsOfTheProgramCatalog Do
		PartsOfTheProgramVersionNumber = StrSplit(ProgramVersionNumber, ".", False);
		If PartsOfTheProgramVersionNumber.Count() <> 4 Then
			Continue;	
		EndIf;
		ThisIsTheVersionNumber = True;
		For Each PartOfTheProgramVersionNumber In PartsOfTheProgramVersionNumber Do
			If Not IsNumber(PartOfTheProgramVersionNumber) Then
				ThisIsTheVersionNumber = False;
				Break;	
			EndIf;
		EndDo;
		If Not ThisIsTheVersionNumber Then
			Continue;	
		EndIf;
	EndDo;
	Return EncodingOfTheLogFile;

EndFunction

Function IsNumber(Val ValueToCheck)
	
	If ValueToCheck = "0" Then
		Return True;
	EndIf;
	
	NumberDetails = New TypeDescription("Number");
	Return NumberDetails.AdjustValue(ValueToCheck) <> 0;
	
EndFunction

Function GetUpdateAdministratorAuthenticationParameters(AdministrationParameters)
	
	Result = New Structure("StringForConnection, InfoBaseConnectionString");
	
	ClusterPort = AdministrationParameters.ClusterPort;
	CurrentConnections = IBConnectionsServerCall.ConnectionsInformation(True,
		ApplicationParameters["StandardSubsystems.MessagesForEventLog"], ClusterPort);
	
	ConnectionString = CurrentConnections.InfoBaseConnectionString;
	PathToTheDatabase = "";
	If StrFind(ConnectionString, "'") > 0 Then
		FileInfobase1 = CommonClient.FileInfobase(ConnectionString);
		If FileInfobase1 Then
			PathToTheDatabase = StrReplace(StrReplace(ConnectionString, "File=", ""), ";", "");
			ErrorText = NStr("en = 'Cannot update the application as the infobase
				|directory contains an incorrect single quote character "" '' "":
				|%1%2';");
			Postfix = NStr("en = 'Move the infobase to another directory and retry the update.';");
		Else
			PathToTheDatabase = ConnectionString;
			ErrorText = NStr("en = 'Cannot update the application as the server address
				|or the infobase name contains an incorrect single quote character "" '' "":
				|%1%2';");
			Postfix = NStr("en = 'Move the infobase to another server or rename it and then retry the update.';");
		EndIf;
		ErrorText = StrConcat(StrSplit(ErrorText, Chars.LF), " ");
		
		ErrorText = ErrorText + Chars.LF + Chars.LF + Postfix;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Chars.LF, PathToTheDatabase);
		
		Raise ErrorText;
	EndIf;
	
	Result.InfoBaseConnectionString = CurrentConnections.InfoBaseConnectionString;
	Result.StringForConnection = "Usr=""{0}"";Pwd=""{1}""";
	
	Return Result;
	
EndFunction

Function ScheduleServiceTaskName(Val TaskCode)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Update configuration (%1)';"), Format(TaskCode, "NG=0"));
	
EndFunction

Function StringUnicode(String)
	
	Result = "";
	
	For CharacterNumber = 1 To StrLen(String) Do
		
		Char = Format(CharCode(Mid(String, CharacterNumber, 1)), "NG=0");
		Char = StringFunctionsClientServer.SupplementString(Char, 4);
		Result = Result + Char;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the event name for the log entry.
Function EventLogEvent() Export
	Return NStr("en = 'Configuration update';", CommonClient.DefaultLanguageCode());
EndFunction

// Checks for configuration updates when the program starts.
//
Procedure CheckForConfigurationUpdate()
	
	If Not CommonClient.IsWindowsClient() Then
		Return;
	EndIf;
	
#If Not WebClient And Not MobileClient Then
	If CommonClient.DataSeparationEnabled()
	 Or Not CommonClient.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientRunParameters.Property("ShowInvalidHandlersMessage") Then
		Return; // 
	EndIf;
	
	SettingsOfUpdate = ClientRunParameters.SettingsOfUpdate;
	UpdateAvailability = SettingsOfUpdate.CheckPreviousInfobaseUpdates;
	
	If UpdateAvailability Then
		// 
		OpenForm("DataProcessor.ApplicationUpdateResult.Form.ApplicationUpdateResult");
		Return;
	EndIf;
	
	If SettingsOfUpdate.ConfigurationChanged Then
		ShowUserNotification(NStr("en = 'Configuration update';"),
			"e1cib/app/DataProcessor.InstallUpdates",
			NStr("en = 'The configuration is different from the main infobase configuration.';"), 
			PictureLib.DialogInformation);
	EndIf;
	
#EndIf

EndProcedure

Function JobSchedulerSupported()
	
	// 
	
	SystemInfo = New SystemInfo();
	
	PointPosition = StrFind(SystemInfo.OSVersion, ".");
	If PointPosition < 2 Then 
		Return False;
	EndIf;
	
	VersionNumber = Mid(SystemInfo.OSVersion, PointPosition - 2, 2);
	
	TypeDescriptionNumber = New TypeDescription("Number");
	VersionLaterThanVista = TypeDescriptionNumber.AdjustValue(VersionNumber) >= 6;
	
	Return VersionLaterThanVista;
	
EndFunction

#If Not WebClient And Not MobileClient Then

Procedure ReadDataToEventLog(UpdateResult, ScriptDirectory)
	
	UpdateResult = Undefined;
	ErrorOccurredDuringUpdate = False;
	
	FilesArray = FindFiles(ScriptDirectory, "log*.txt");
	
	If FilesArray.Count() = 0 Then
		Return;
	EndIf;
	
	LogFile = FilesArray[0];
	
	TextDocument = New TextDocument;
	TextDocument.Read(LogFile.FullName);
	
	For LineNumber = 1 To TextDocument.LineCount() Do
		
		CurrentRow = TextDocument.GetLine(LineNumber);
		If IsBlankString(CurrentRow) Then
			Continue;
		EndIf;
		
		LevelPresentation = "Information";
		If Mid(CurrentRow, 3, 1) = "." And Mid(CurrentRow, 6, 1) = "." Then // 
			RowArray = StrSplit(CurrentRow, " ", False);
			DateArray = StrSplit(RowArray[0], ".");
			TimeArray = StrSplit(RowArray[1], ":");
			EventDate = Date(DateArray[2], DateArray[1], DateArray[0], TimeArray[0], TimeArray[1], TimeArray[2]);
			If RowArray[2] = "{ERR}" Then
				LevelPresentation = "Error";
				ErrorOccurredDuringUpdate = True;
			EndIf;
			
			Comment = TrimAll(Mid(CurrentRow, StrFind(CurrentRow, "}") + 2));
			If StrStartsWith(Comment, "UpdateSuccessful") 
				Or Comment = "RefreshEnabled completed2" Then // 
				UpdateResult = True;
				Continue;
			ElsIf StrStartsWith(Comment, "UpdateNotExecuted")  
				Or Comment = "RefreshEnabled not completed2" Then // 
				UpdateResult = False;
				Continue;
			EndIf;
			
			For NextLineNumber = LineNumber + 1 To TextDocument.LineCount() Do
				CurrentRow = TextDocument.GetLine(NextLineNumber);
				If Mid(CurrentRow, 3, 1) = "." And Mid(CurrentRow, 6, 1) = "." Then
					// 
					LineNumber = NextLineNumber - 1;
					Break;
				EndIf;
				
				Comment = Comment + Chars.LF + CurrentRow;
			EndDo;
			
			EventLogClient.AddMessageForEventLog(EventLogEvent(), 
				LevelPresentation, Comment, EventDate);
			
		EndIf;
		
	EndDo;
	
	// 
	// 
	// 
	// 
	If UpdateResult = Undefined Then 
		UpdateResult = Not ErrorOccurredDuringUpdate;
	EndIf;
	
	EventLogClient.WriteEventsToEventLog();

EndProcedure

Function UpdateProgramFilesEncoding()
	
	// 
	Return TextEncoding.UTF16;
	
EndFunction

Function PatchesFilesNames(Parameters, TempFilesDir)
	
	ParameterName = "StandardSubsystems.PatchesFilesNames";
	If ApplicationParameters.Get(ParameterName) <> Undefined Then
		Return ApplicationParameters[ParameterName];
	EndIf;
	
	FilesNames = New Array;
	For Each PatchFileName In Parameters.PatchesFiles Do
		If StrEndsWith(PatchFileName, ".cfe") Then
			ArchiveName = TempFilesDir + StrReplace(String(New UUID),"-", "") + ".zip";
			WriteArchive = New ZipFileWriter(ArchiveName);
			WriteArchive.Add(PatchFileName);
			WriteArchive.Write();
			
			FilesNames.Add(DoFormat(ArchiveName));
		Else
			FilesNames.Add(DoFormat(PatchFileName));
		EndIf;
	EndDo;
	PatchesFilesNames = StrConcat(FilesNames, ",");
	
	Return "[" + PatchesFilesNames + "]";
	
EndFunction

Function PatchesInformation(Parameters, TempFilesDir)
	
	ParameterName = "StandardSubsystems.PatchesInformation";
	If ApplicationParameters.Get(ParameterName) <> Undefined Then
		Return ApplicationParameters[ParameterName];
	EndIf;
	
	PatchesToInstall1 = "['']";
	PatchesToDelete = "['']";
	If Parameters.Property("PatchesFiles") Then
		PatchesToInstall1 = PatchesFilesNames(Parameters, TempFilesDir);
	ElsIf Parameters.Property("Corrections") Then
		If Parameters.Corrections.Property("Set")
			And Parameters.Corrections.Set.Count() > 0 Then
			FilesNames = New Array;
			For Each NewPatch In Parameters.Corrections.Set Do
				ArchiveName = TempFilesDir + StrReplace(String(New UUID),"-", "") + ".zip";
				Data = GetFromTempStorage(NewPatch); // BinaryData
				Data.Write(ArchiveName);
				FilesNames.Add(DoFormat(ArchiveName));
			EndDo;
			PatchesToInstall1 = StrConcat(FilesNames, ",");
			PatchesToInstall1 = "[" + PatchesToInstall1 + "]";
		EndIf;
		
		If Parameters.Corrections.Property("Delete")
			And Parameters.Corrections.Delete.Count() > 0 Then
			PatchesToDelete = "'" + StrConcat(Parameters.Corrections.Delete, "','") + "'";
			PatchesToDelete = "[" + PatchesToDelete + "]";
		EndIf;
	EndIf;
	
	PatchesInformation = New Structure;
	PatchesInformation.Insert("Set", PatchesToInstall1);
	PatchesInformation.Insert("Delete", PatchesToDelete);
	
	Return PatchesInformation;
	
EndFunction

Function GenerateUpdateScriptFiles(Val InteractiveMode, Parameters, AdministrationParameters)
	
	IsFileInfobase = CommonClient.FileInfobase();
	
	PlatformDirectory = Undefined;
	Parameters.Property("PlatformDirectory", PlatformDirectory);
	BinDir = ?(ValueIsFilled(PlatformDirectory), PlatformDirectory, BinDir());
	
	DesignerExecutableFileName = BinDir + StandardSubsystemsClient.ApplicationExecutableFileName(True);
	ClientExecutableFileName = BinDir + StandardSubsystemsClient.ApplicationExecutableFileName();
	COMConnectorPath = BinDir() + "comcntr.dll";
	COMConnectorName = CommonClientServer.COMConnectorName();
	EncodingOfTheLogFile = EncodingOfTheLogFile(BinDir);
	UseCOMConnector = Not (StandardSubsystemsClient.IsBaseConfigurationVersion()
		Or StandardSubsystemsClient.IsTrainingPlatform());
	
	ScriptParameters = GetUpdateAdministratorAuthenticationParameters(AdministrationParameters);
	InfoBaseConnectionString = ScriptParameters.InfoBaseConnectionString + ScriptParameters.StringForConnection;
	If StrEndsWith(InfoBaseConnectionString, ";") Then
		InfoBaseConnectionString = Left(InfoBaseConnectionString, StrLen(InfoBaseConnectionString) - 1);
	EndIf;
	
	// 
	InfobasePath = IBConnectionsClientServer.InfobasePath(, AdministrationParameters.ClusterPort);
	InfobasePathParameter = ?(IsFileInfobase, "/F", "/S") + InfobasePath;
	InfobasePathString = ?(IsFileInfobase, InfobasePath, "");
	InfobasePathString = CommonClientServer.AddLastPathSeparator(StrReplace(InfobasePathString, """", "")) + "1Cv8.1CD";
	
	Email = ?(Parameters.UpdateMode = 2 And Parameters.EmailReport, Parameters.Email, "");
	
	//  
	// 
	// 
	TempFilesDirForUpdate = TempFilesDir() + "1Cv8Update." + Format(CommonClient.SessionDate(), "DF=yyMMddHHmmss") + "\";
	
	If Parameters.CreateDataBackup = 1 Then 
		BackupDirectory = TempFilesDirForUpdate;
	ElsIf Parameters.CreateDataBackup = 2 Then 
		BackupDirectory = CommonClientServer.AddLastPathSeparator(Parameters.IBBackupDirectoryName);
	Else 
		BackupDirectory = "";
	EndIf;
	
	UserNotificationInterval = 0;
	If Parameters.Property("UserNotificationInterval") Then
		UserNotificationInterval = Parameters.UserNotificationInterval;
	EndIf;
	
	CreateDataBackup = IsFileInfobase And (Parameters.CreateDataBackup = 1 Or Parameters.CreateDataBackup = 2);
	
	ExecuteDeferredHandlers = False;
	IsDeferredUpdate = (Parameters.UpdateMode = 2);
	TemplatesTexts = ConfigurationUpdateServerCall.TemplatesTexts(ApplicationParameters["StandardSubsystems.MessagesForEventLog"], 
		InteractiveMode, ExecuteDeferredHandlers, IsDeferredUpdate);
	UserName = AdministrationParameters.InfobaseAdministratorName;
	
	If IsDeferredUpdate Then 
		RandomNumberGenerator = New RandomNumberGenerator;
		TaskCode = Format(RandomNumberGenerator.RandomNumber(1000, 9999), "NG=0");
		TaskName = ScheduleServiceTaskName(TaskCode);
	EndIf;
	
	OneCEnterpriseStartupParameters = CommonInternalClient.EnterpriseStartupParametersFromScript();
	
	PerformAConfigurationUpdate = Parameters.Property("ConfigurationChanged") And Parameters.ConfigurationChanged;
	DownloadExtensions = Parameters.Property("LoadExtensions") And Parameters.LoadExtensions;
	
	ParametersArea = TemplatesTexts.ParametersArea;
	InsertScriptParameter("DesignerExecutableFileName" , DesignerExecutableFileName          , True, ParametersArea);
	InsertScriptParameter("ClientExecutableFileName"       , ClientExecutableFileName                , True, ParametersArea);
	InsertScriptParameter("COMConnectorPath"               , COMConnectorPath                        , True, ParametersArea);
	InsertScriptParameter("EncodingOfTheLogFile"                 , EncodingOfTheLogFile                          , False, ParametersArea);
	InsertScriptParameter("InfobasePathParameter"   , InfobasePathParameter            , True, ParametersArea);
	InsertScriptParameter("InfobaseFilePathString", InfobasePathString              , True, ParametersArea);
	InsertScriptParameter("InfoBaseConnectionString", InfoBaseConnectionString         , True, ParametersArea);
	InsertScriptParameter("EventLogEvent"         , EventLogEvent()                , True, ParametersArea);
	InsertScriptParameter("Email"             , Email                      , True, ParametersArea);
	InsertScriptParameter("UpdateAdministratorName"       , UserName                            , True, ParametersArea);
	InsertScriptParameter("COMConnectorName"                 , COMConnectorName                          , True, ParametersArea);
	InsertScriptParameter("BackupDirectory"             , BackupDirectory                      , True, ParametersArea);
	InsertScriptParameter("CreateDataBackup"           , CreateDataBackup                    , False  , ParametersArea);
	InsertScriptParameter("RestoreInfobase" , Parameters.RestoreInfobase, False  , ParametersArea);
	InsertScriptParameter("BlockIBConnections"           , Not IsFileInfobase                         , False  , ParametersArea);
	InsertScriptParameter("UseCOMConnector"        , UseCOMConnector                 , False  , ParametersArea);
	InsertScriptParameter("StartSessionAfterUpdate"       , Not Parameters.ShouldExitApp       , False  , ParametersArea);
	InsertScriptParameter("CompressIBTables"           , IsFileInfobase                            , False  , ParametersArea);
	InsertScriptParameter("ExecuteDeferredHandlers"    , ExecuteDeferredHandlers             , False  , ParametersArea);
	InsertScriptParameter("TaskSchedulerTaskName"        , TaskName                                  , True, ParametersArea);
	InsertScriptParameter("OneCEnterpriseStartupParameters"       , OneCEnterpriseStartupParameters                , True, ParametersArea);
	InsertScriptParameter("UnlockCode1"                  , "IBConfigurationBatchUpdate"         , False,   ParametersArea);
	InsertScriptParameter("UserNotificationInterval"  , UserNotificationInterval           , False,   ParametersArea);
	InsertScriptParameter("PerformAConfigurationUpdate"   , PerformAConfigurationUpdate            , False,   ParametersArea);
	InsertScriptParameter("DownloadExtensions"       , DownloadExtensions                , False,   ParametersArea);
	
	CreateDirectory(TempFilesDirForUpdate);
	PatchesInformation = PatchesInformation(Parameters, TempFilesDirForUpdate);
	ParametersArea = StrReplace(ParametersArea, "[UpdateFilesNames]", UpdateFilesNames(Parameters));
	ParametersArea = StrReplace(ParametersArea, "[PatchesFilesNames]", PatchesInformation.Set);
	ParametersArea = StrReplace(ParametersArea, "[DeletedChangesNames]", PatchesInformation.Delete);
	
	If Parameters.Property("FilesOfUpdate") Then
		Parameters.Insert("VersionsRequiringSuccessfulUpdate", VersionsRequiringSuccessfulUpdate(Parameters.FilesOfUpdate));
	Else
		Parameters.Insert("VersionsRequiringSuccessfulUpdate", New Array);
	EndIf;
	
	TemplatesTexts.ConfigurationUpdateFileTemplate = ParametersArea + TemplatesTexts.ConfigurationUpdateFileTemplate;
	TemplatesTexts.Delete("ParametersArea");
	
	//
	WriteTextToFile(TempFilesDirForUpdate + "main.js", TemplatesTexts.ConfigurationUpdateFileTemplate);
	
	// 
	WriteTextToFile(TempFilesDirForUpdate + "helpers.js", TemplatesTexts.AdditionalConfigurationUpdateFile);
	
	If InteractiveMode Then
		PictureLib.ExternalOperationSplash.Write(TempFilesDirForUpdate + "splash.png");
		PictureLib.ExternalOperationSplashIcon.Write(TempFilesDirForUpdate + "splash.ico");
		PictureLib.TimeConsumingOperation48.Write(TempFilesDirForUpdate + "progress.gif");

		MainScriptFileName = TempFilesDirForUpdate + "splash.hta";
		WriteTextToFile(MainScriptFileName, TemplatesTexts.ConfigurationUpdateSplash);
	Else
		MainScriptFileName = TempFilesDirForUpdate + "updater.js";
		WriteTextToFile(MainScriptFileName, TemplatesTexts.NonInteractiveConfigurationUpdate);
	EndIf;
	
	If IsDeferredUpdate Then 
		
		StartDate2 = Format(Parameters.UpdateDateTime, "DF=yyyy-MM-ddTHH:mm:ss");
		
		ScriptPath = StandardSubsystemsClient.SystemApplicationsDirectory() + "wscript.exe";
		ScriptParameters = StringFunctionsClientServer.SubstituteParametersToString("//nologo ""%1"" /p1:""%2"" /p2:""%3""",
			MainScriptFileName,
			StringUnicode(AdministrationParameters.InfobaseAdministratorPassword),
			StringUnicode(AdministrationParameters.ClusterAdministratorPassword));
		
		TaskDetails1 = NStr("en = 'Update 1C:Enterprise configuration';");
		
		TaskSchedulerTaskCreationScript = TemplatesTexts.TaskSchedulerTaskCreationScript;
		
		InsertScriptParameter("StartDate2" , StartDate2, True, TaskSchedulerTaskCreationScript);
		InsertScriptParameter("ScriptPath" , ScriptPath, True, TaskSchedulerTaskCreationScript);
		InsertScriptParameter("ScriptParameters" , ScriptParameters, True, TaskSchedulerTaskCreationScript);
		InsertScriptParameter("TaskName" , TaskName, True, TaskSchedulerTaskCreationScript);
		InsertScriptParameter("TaskDetails1" , TaskDetails1, True, TaskSchedulerTaskCreationScript);
		
		TaskSchedulerTaskCreationScriptName = TempFilesDirForUpdate + "addsheduletask.js";
		WriteTextToFile(TaskSchedulerTaskCreationScriptName, TaskSchedulerTaskCreationScript);
		
		Parameters.SchedulerTaskCode = TaskCode;
		
		Parameters.Insert("TaskSchedulerTaskCreationScriptName", TaskSchedulerTaskCreationScriptName);
		
	EndIf;
	
	WriteTextToFile(TempFilesDirForUpdate + "templog.txt",
		StandardSubsystemsClient.SupportInformation(), TextEncoding.System);
	
	WriteTextToFile(TempFilesDirForUpdate + "add-delete-patches.js",
		TemplatesTexts.PatchesDeletionScript);
	
	Return MainScriptFileName;
	
EndFunction

Procedure WriteTextToFile(FullFileName, Text, Encoding = Undefined)
	
	If Encoding = Undefined Then
		Encoding = UpdateProgramFilesEncoding();
	EndIf;
	
	ScriptFile = New TextWriter(FullFileName, Encoding);
	ScriptFile.Write(Text);
	ScriptFile.Close();
	
EndProcedure

// Parameters:
//  Parameters - See InstallUpdate.Parameters
//  AdministrationParameters - See StandardSubsystemsServer.AdministrationParameters.
//
Procedure RunUpdateScript(Parameters, AdministrationParameters)
	
	Context = New Structure;
	Context.Insert("Parameters", Parameters);
	Context.Insert("AdministrationParameters", AdministrationParameters);
	
	FormParameters = New Structure("NameOfFirstUpdateFile",
		UpdateFilesNames(Parameters, True));
	
	Notification = New NotifyDescription("RunUpdateScriptAfterUpdateFileChecked",
		ThisObject, Context);
	
	Form = OpenForm("CommonForm.CheckUpdateFile", FormParameters,,,,,
		Notification, FormWindowOpeningMode.LockWholeInterface);
	
	If Form = Undefined Then
		RunUpdateScriptOnDataCleanUp(Context);
	ElsIf Not Form.IsOpen() Then
		RunUpdateScriptAfterUpdateFileChecked(Form.Result, Context);
	EndIf;
	
EndProcedure

// Parameters:
//  Context - Structure:
//   * Parameters - See InstallUpdate.Parameters
//   * AdministrationParameters - See StandardSubsystemsServer.AdministrationParameters.
//  
//
Procedure RunUpdateScriptAfterUpdateFileChecked(Result, Context) Export
	
	If Result = True Then
		RunUpdateScriptAfterObsoleteDataPurge(True, Context);
	Else
		RunUpdateScriptOnDataCleanUp(Context);
	EndIf;
	
EndProcedure

// Parameters:
//  Context - See RunUpdateScriptAfterUpdateFileChecked.Context
//
Procedure RunUpdateScriptOnDataCleanUp(Context)
	
	FullFormName = "DataProcessor.ApplicationUpdateResult.Form.ClearObsoleteData";
	
	Windows = GetWindows();
	For Each Window In Windows Do
		For Each Form In Window.Content Do
			If Form.FormName = FullFormName And Form.IsOpen() Then
				Form.Close();
			EndIf;
		EndDo;
	EndDo;
	
	Notification = New NotifyDescription("RunUpdateScriptAfterObsoleteDataPurge",
		ThisObject, Context);
	
	FormParameters = New Structure;
	FormParameters.Insert("ClearAndClose", True);
	
	OpenForm(FullFormName, FormParameters,,,,,
		Notification, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

// Parameters:
//  Result - 
//  Context - See RunUpdateScriptAfterUpdateFileChecked.Context
//
Procedure RunUpdateScriptAfterObsoleteDataPurge(Result, Context) Export
	
	If Result <> True Then
		If Result <> False Then
			ShowMessageBox(, NStr("en = 'Configuration update is canceled.';"));
		EndIf;
		Return;
	EndIf;
	
	RunUpdateScriptCompletion(Context.Parameters, Context.AdministrationParameters);
	
EndProcedure

// Parameters:
//  Parameters - See InstallUpdate.Parameters
//  AdministrationParameters - See StandardSubsystemsServer.AdministrationParameters.
//
Procedure RunUpdateScriptCompletion(Parameters, AdministrationParameters)
	
	MainScriptFileName = GenerateUpdateScriptFiles(True, Parameters, AdministrationParameters);
	EventLogClient.AddMessageForEventLog(EventLogEvent(), "Information",
		NStr("en = 'Updating the configuration:';") + " " + MainScriptFileName);
	
	VersionsRequiringSuccessfulUpdate = New Array;
	If Parameters.Property("VersionsRequiringSuccessfulUpdate") Then
		VersionsRequiringSuccessfulUpdate = Parameters.VersionsRequiringSuccessfulUpdate;
	EndIf;
	
	ParametersOfUpdate = ConfigurationUpdateServerCall.ParametersOfUpdate();
	ParametersOfUpdate.UpdateAdministratorName = UserName();
	ParametersOfUpdate.UpdateScheduled = True;
	ParametersOfUpdate.UpdateComplete = False;
	ParametersOfUpdate.ConfigurationUpdateResult = False;
	ParametersOfUpdate.MainScriptFileName = MainScriptFileName;
	ParametersOfUpdate.VersionsRequiringSuccessfulUpdate = VersionsRequiringSuccessfulUpdate;
	ConfigurationUpdateServerCall.WriteUpdateStatus(ParametersOfUpdate,
		ApplicationParameters["StandardSubsystems.MessagesForEventLog"]);
	
	DontStopScenariosExecution();
	
	PathToLauncher = StandardSubsystemsClient.SystemApplicationsDirectory() + "mshta.exe";
	
	CommandLine1 = """%1"" ""%2"" [p1]%3[/p1][p2]%4[/p2]";
	CommandLine1 = StringFunctionsClientServer.SubstituteParametersToString(CommandLine1,
		PathToLauncher, MainScriptFileName,
		StringUnicode(AdministrationParameters.InfobaseAdministratorPassword),
		StringUnicode(AdministrationParameters.ClusterAdministratorPassword));
	
	If StandardSubsystemsClient.IsBaseConfigurationVersion() Then
		ConfigurationUpdateServerCall.DeletePatchesFromScript();
	EndIf;
	ReturnCode = Undefined;
	RunApp(CommandLine1,,, ReturnCode); // 
	ApplicationParameters.Insert("StandardSubsystems.SkipExitConfirmation", True);
	Exit(False);
	
EndProcedure

Procedure DontStopScenariosExecution()
	
	Shell = New COMObject("Wscript.Shell");
	Shell.RegWrite("HKCU\Software\Microsoft\Internet Explorer\Styles\MaxScriptStatements", 1107296255, "REG_DWORD");

EndProcedure

Procedure ScheduleConfigurationUpdate(Parameters, AdministrationParameters)
	
	GenerateUpdateScriptFiles(False, Parameters, AdministrationParameters);
	
	ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
	ApplicationStartupParameters.ExecuteWithFullRights = True;
	
	StartupCommand = New Array;
	StartupCommand.Add("wscript.exe");
	StartupCommand.Add("//nologo");
	StartupCommand.Add(Parameters.TaskSchedulerTaskCreationScriptName);
	
	FileSystemClient.StartApplication(StartupCommand, ApplicationStartupParameters);
	
	ParametersOfUpdate = ConfigurationUpdateServerCall.ParametersOfUpdate();
	ParametersOfUpdate.UpdateAdministratorName = UserName();
	ParametersOfUpdate.UpdateScheduled = True;
	ParametersOfUpdate.UpdateComplete = False;
	ParametersOfUpdate.ConfigurationUpdateResult = False;
	ConfigurationUpdateServerCall.WriteUpdateStatus(ParametersOfUpdate);
	
EndProcedure

#EndIf

// Returns True if the Configurator is available.
//
// See Common.DebugMode
//
// Returns:
//  Boolean - 
//
Function DesignerBatchModeSupported()
	
#If WebClient Or MobileClient Then
	Return False;
#Else
	Designer1 = BinDir() + StandardSubsystemsClient.ApplicationExecutableFileName(True);
	DesignerFile = New File(Designer1);
	Return DesignerFile.Exists(); // 
#EndIf
	
EndFunction

#EndRegion