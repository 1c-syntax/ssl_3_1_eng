///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Check whether the undivided data in the information database needs to be updated
// when changing the configuration version.
//
Function SharedInfobaseDataUpdateRequired() Export
	
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled() Then
		
		MetadataVersion = Metadata.Version;
		If IsBlankString(MetadataVersion) Then
			MetadataVersion = "0.0.0.0";
		EndIf;
		
		SharedDataVersion = IBVersion(Metadata.Name, True);
		
		If UpdateRequired(MetadataVersion, SharedDataVersion) Then
			Return True;
		EndIf;
		
		If Not Common.SeparatedDataUsageAvailable()
		   And IsStartInfobaseUpdateSet() Then
			
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// 
// 
// 
//
// Parameters:
//  UpdateProgress - Structure - 
//                         
//
// Returns:
//  Boolean
//
Function DeferredUpdateCompleted(UpdateProgress = Undefined) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		UpdateProgress = InfobaseUpdate.DataAreasUpdateProgress("Deferred2");
		Return UpdateProgress = Undefined Or UpdateProgress.Running = 0
			And UpdateProgress.Waiting1 = 0 And UpdateProgress.Issues = 0;
	EndIf;
	
	Return GetFunctionalOption("DeferredUpdateCompletedSuccessfully");
	
EndFunction

// Perform a non-interactive update of information security data.
//
// Parameters:
// 
//  ParametersOfUpdate - Structure:
//    * ExceptionOnCannotLockIB - Boolean -  if False, then
//                 an exception is not raised when an attempt to install exclusive mode
//                 fails, but the string "error installing exclusive Mode"is returned.
// 
//    * OnClientStart - Boolean -  the initial value is False. If you specify True,
//                 then the program parameters will not be updated, because when the client
//                 starts, they are updated at the very beginning (before users are authorized and the information security is updated).
//                 This parameter is required to optimize the client startup mode so that you don't have to
//                 update the program parameters twice.
//                 When an external call is made, for example, in an external connection session, the
//                 program parameters must be updated before continuing to update the information security.
//    * Restart             - Boolean    - 
//                                  
//                                  
//                                  
//                                  
//    * IBLockSet - See IBLock
//    * InBackground                     - Boolean    -  if the database update is performed
//                 in the background, it should be passed True, otherwise False.
//    * ExecuteDeferredHandlers1 - Boolean -  if True, the deferred update will be performed
//                 in the main update cycle. Only for client-server mode.
// 
// Returns:
//  String -  :
//           
//
Function UpdateInfobase(ParametersOfUpdate) Export
	
	AdditionalParameters = ActionsBeforeUpdateInfobase(ParametersOfUpdate);
	If ValueIsFilled(AdditionalParameters.Return) Then
		Return AdditionalParameters.Return;
	EndIf;
	
	ClientLaunchParameter       = StandardSubsystemsServer.ClientParametersAtServer().Get("LaunchParameter");
	DeferredUpdateDebug = StrFind(Lower(ClientLaunchParameter), Lower("DeferredUpdateDebug")) > 0;
	DeferredUpdateMode = DeferredUpdateMode(ParametersOfUpdate);
	ExecuteDeferredUpdateNow  = Not DeferredUpdateDebug And DeferredUpdateMode = "Exclusively";
	
	AdditionalParameters.Insert("ExecuteDeferredUpdateNow", ExecuteDeferredUpdateNow);
	AdditionalParameters.Insert("DeferredUpdateMode", DeferredUpdateMode);
	
	ExecuteActionsOnUpdateInfobase(ParametersOfUpdate, AdditionalParameters);
	ExecuteActionsAfterUpdateInfobase(ParametersOfUpdate, AdditionalParameters);
	
	Return "Success";
	
EndFunction

// Get the version of the configuration or parent configuration (library)
// that is stored in the information database.
//
// Parameters:
//  LibraryID   - String -  the configuration name or ID of the library.
//                            - Undefined - 
//  GetSharedDataVersion - Boolean -  if set to True, 
//                                       the version in the shared data will be returned when working in the service model.
//
// Returns:
//   String   - 
//   :
//      * Key - String - 
//      * Value - String - 
//
// :
//   
//
Function IBVersion(Val LibraryID, Val GetSharedDataVersion = False) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	StandardProcessing = True;
	Result = "";
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.OnDetermineIBVersion(LibraryID, GetSharedDataVersion,
			StandardProcessing, Result);
		
	EndIf;
	
	AllVersionsOfSubsystems = (LibraryID = Undefined);
	If AllVersionsOfSubsystems And Not StandardProcessing Then
		Return Result;
	EndIf;
	
	If StandardProcessing Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	SubsystemsVersions.Version,
		|	SubsystemsVersions.SubsystemName
		|FROM
		|	InformationRegister.SubsystemsVersions AS SubsystemsVersions
		|WHERE
		|	&Condition";
		
		If AllVersionsOfSubsystems Then
			Query.Text = StrReplace(Query.Text, "&Condition", "TRUE");
		Else
			Query.Text = StrReplace(Query.Text, "&Condition", "SubsystemsVersions.SubsystemName = &SubsystemName");
			Query.SetParameter("SubsystemName", LibraryID);
		EndIf;
		ValueTable = Query.Execute().Unload();
		Result = "";
		If ValueTable.Count() > 0 Then
			If Not AllVersionsOfSubsystems Then
				Result = TrimAll(ValueTable[0].Version);
			Else
				SubsystemsVersions = New Map;
				For Each VersionRow In ValueTable Do
					SubsystemsVersions.Insert(VersionRow.SubsystemName, TrimAll(VersionRow.Version));
				EndDo;
				
				Return SubsystemsVersions;
			EndIf;
		EndIf;
		
	EndIf;
	
	If AllVersionsOfSubsystems Then
		Return Undefined;
	Else
		Return ?(IsBlankString(Result), "0.0.0.0", Result);
	EndIf;
	
EndFunction

// Writes the version of the configuration or parent configuration (library) to the information database.
//
// Parameters:
//  LibraryID - String -  name of the configuration or parent configuration (library),
//  VersionNumber             - String -  version number.
//  IsMainConfiguration - Boolean -  indicates that the library ID matches the configuration name.
//  ExecutedRegistration    - Boolean - 
//
Procedure SetIBVersion(Val LibraryID, Val VersionNumber, Val IsMainConfiguration, ExecutedRegistration = Undefined) Export
	
	StandardProcessing = True;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.OnSetIBVersion(LibraryID, VersionNumber, StandardProcessing, IsMainConfiguration);
		
	EndIf;
	
	If Not StandardProcessing Then
		Return;
	EndIf;
		
	RecordSet = InformationRegisters.SubsystemsVersions.CreateRecordSet();
	RecordSet.Filter.SubsystemName.Set(LibraryID);
	
	NewRecord = RecordSet.Add();
	NewRecord.SubsystemName = LibraryID;
	NewRecord.Version = VersionNumber;
	NewRecord.IsMainConfiguration = IsMainConfiguration;
	If ExecutedRegistration <> Undefined Then
		NewRecord.DeferredHandlersRegistrationCompleted = ExecutedRegistration;
	EndIf;
	
	RecordSet.Write();
	
EndProcedure

// Records information about the result of registering deferred handlers on the exchange plan.
//
Procedure CanlcelDeferredUpdateHandlersRegistration(SubsystemName = Undefined, Value = True) Export
	
	StandardProcessing = True;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.OnMarkDeferredUpdateHandlersRegistration(SubsystemName, Value, StandardProcessing);
	EndIf;
	
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.SubsystemsVersions.CreateRecordSet();
	If SubsystemName <> Undefined Then
		RecordSet.Filter.SubsystemName.Set(SubsystemName);
	EndIf;
	RecordSet.Read();
	
	If RecordSet.Count() = 0 Then
		Return;
	EndIf;
	
	For Each RegisterRecord In RecordSet Do
		RegisterRecord.DeferredHandlersRegistrationCompleted = Value;
	EndDo;
	RecordSet.Write();
	
EndProcedure

// Returns the mode for updating information database data.
// It is allowed to call only before the start of updating the information base (otherwise it returns "update Versions").
// 
// Returns:
//   String   - 
//              
//               
//              
//
Function DataUpdateMode() Export
	
	SetPrivilegedMode(True);
	
	StandardProcessing = True;
	DataUpdateMode = "";
	
	BaseConfigurationName = Metadata.Name;
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	For Each SubsystemName In SubsystemsDetails.Order Do
		SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName); // See StandardSubsystemsCached.NewSubsystemDescription
		If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		
		If SubsystemDetails.Name <> BaseConfigurationName Then
			Continue;
		EndIf;
		
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		Module.OnDefineDataUpdateMode(DataUpdateMode, StandardProcessing);
	EndDo;
	
	If Not StandardProcessing Then
		CommonClientServer.CheckParameter("OnDefineDataUpdateMode", "DataUpdateMode",
			DataUpdateMode, Type("String"));
		Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Invalid value of parameter %1 in %2.
			|Expected value: %3, %4, or %5. Passed value: %6 (type %7).';"),
			"DataUpdateMode", "OnDefineDataUpdateMode",
			"InitialFilling", "VersionUpdate", "MigrationFromAnotherApplication",
			DataUpdateMode, TypeOf(DataUpdateMode));
		CommonClientServer.Validate(DataUpdateMode = "InitialFilling" 
			Or DataUpdateMode = "VersionUpdate" Or DataUpdateMode = "MigrationFromAnotherApplication", Message);
		Return DataUpdateMode;
	EndIf;

	Result = Undefined;
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.WhenDeterminingUpdateModeDataRegion(StandardProcessing, Result);
	EndIf;
	
	If Not StandardProcessing Then
		Return Result;
	EndIf;
	
	Return DataUpdateModeInLocalMode();
	
EndFunction

// For internal use.
Function HandlerFIlteringParameters() Export
	
	Result = New Structure;
	Result.Insert("GetSeparated", False);
	Result.Insert("UpdateMode", "Exclusively");
	Result.Insert("IncludeFirstExchangeInDIB", False);
	Result.Insert("FirstExchangeInDIB", False);
	Return Result;
	
EndFunction

Function UpdateInIntervalHandlers(Val InitialHandlerTable, Val VersionFrom, Val VersionTo,
		Val HandlerFIlteringParameters = Undefined) Export
	
	FilterParameters = HandlerFIlteringParameters;
	If FilterParameters = Undefined Then
		FilterParameters = HandlerFIlteringParameters();
	EndIf;
	// 
	AllHandlers = InitialHandlerTable.Copy();
	
	AllHandlers.Columns.Add("SerialNumber", New TypeDescription("Number", New NumberQualifiers(10, 0)));
	For IndexOf = 0 To AllHandlers.Count() - 1 Do
		HandlerRow = AllHandlers[IndexOf];
		HandlerRow.SerialNumber = IndexOf + 1;
	EndDo;
	
	SelectNewSubsystemHandlers(AllHandlers);
	
	// 
	SelectSeparatedHandlers = True;
	SelectSharedHandlers = True;
	
	If Common.DataSeparationEnabled() Then
		If FilterParameters.GetSeparated Then
			SelectSharedHandlers = False;
		Else
			If Common.SeparatedDataUsageAvailable() Then
				SelectSharedHandlers = False;
			Else
				SelectSeparatedHandlers = False;
			EndIf;
		EndIf;
	EndIf;
	
	// 
	Schema = GetCommonTemplate("GetUpdateHandlersTree");
	Schema.Parameters.Find("SelectSeparatedHandlers").Value = SelectSeparatedHandlers;
	Schema.Parameters.Find("SelectSharedHandlers").Value = SelectSharedHandlers;
	Schema.Parameters.Find("VersionFrom").Value = VersionFrom;
	Schema.Parameters.Find("VersionTo").Value = VersionTo;
	Schema.Parameters.Find("VersionWeightFrom").Value = VersionWeight(Schema.Parameters.Find("VersionFrom").Value);
	Schema.Parameters.Find("VersionWeightTo").Value = VersionWeight(Schema.Parameters.Find("VersionTo").Value);
	Schema.Parameters.Find("SeamlessUpdate").Value = (FilterParameters.UpdateMode = "Seamless");
	Schema.Parameters.Find("DeferredUpdate").Value = (FilterParameters.UpdateMode = "Deferred");
	If FilterParameters.IncludeFirstExchangeInDIB Then
		Schema.Parameters.Find("FirstExchangeInDIB").Value = FilterParameters.FirstExchangeInDIB;
		Schema.Parameters.Find("IsDIBWithFilter").Value = StandardSubsystemsCached.DIBUsed("WithFilter");
	EndIf;
	Schema.Parameters.Find("IdOfHandlerForClearingOutdatedData").Value =
		IdOfHandlerForClearingOutdatedData();
	
	Composer = New DataCompositionTemplateComposer;
	Template = Composer.Execute(Schema, Schema.DefaultSettings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Template, New Structure("Handlers", AllHandlers), , True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(New ValueTree);
	
	HandlersToExecute = OutputProcessor.Output(CompositionProcessor);
	
	VersionColumn = HandlersToExecute.Columns.Version; // ValueTableColumnCollection
	VersionColumn.Name = "RegistrationVersion";
	VersionGroupColumn = HandlersToExecute.Columns.VersionGroup;  // ValueTableColumnCollection
	VersionGroupColumn.Name = "Version";
	
	// 
	For Each Version In HandlersToExecute.Rows Do
		Version.Rows.Sort("SharedData Desc", True);
	EndDo;
	
	Return HandlersToExecute;
	
EndFunction

// For internal use.
//
Function UpdateRequired(Val MetadataVersion, Val DataVersion) Export
	Return Not IsBlankString(MetadataVersion) And DataVersion <> MetadataVersion;
EndFunction

// For internal use.
//
Function DeferredUpdateHandlersRegistered() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled()
		And Not Common.SeparatedDataUsageAvailable() Then
		Return True; // 
	EndIf;
	
	StandardProcessing = True;
	Result = "";
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.OnCheckDeferredUpdateHandlersRegistration(Result, StandardProcessing);
	EndIf;
	
	If Not StandardProcessing Then
		Return Result;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	SubsystemsVersions.SubsystemName
		|FROM
		|	InformationRegister.SubsystemsVersions AS SubsystemsVersions
		|WHERE
		|	SubsystemsVersions.DeferredHandlersRegistrationCompleted = FALSE";
	
	Result = Query.Execute().Unload();
	Return Result.Count() = 0;
	
EndFunction

// Returns True if the user has not disabled showing the description
// of system changes after the update and there are unproven changes.
//
Function ShowChangeHistory1() Export
	
	UpdateInfo = InfobaseUpdateInfo();
	If UpdateInfo.OutputUpdatesDetails = False Then
		Return False;
	EndIf;
	
	If Not AccessRight("SaveUserData", Metadata) Then
		// 
		Return False;
	EndIf;
	
	If Not AccessRight("View", Metadata.CommonForms.ApplicationReleaseNotes) Then
		Return False;
	EndIf;
	
	If Common.DataSeparationEnabled()
		And Users.IsFullUser(, True) Then
		Return False;
	EndIf;
	
	OutputUpdateDetailsForAdministrator = Common.CommonSettingsStorageLoad("IBUpdate", "OutputUpdateDetailsForAdministrator",,, UserName());
	If OutputUpdateDetailsForAdministrator = True Then
		Return True;
	EndIf;
	
	LatestVersion1 = SystemChangesDisplayLastVersion();
	If LatestVersion1 = Undefined Then
		Return True;
	EndIf;
	
	Sections = UpdateDetailsSections();
	
	If Sections = Undefined Then
		Return False;
	EndIf;
	
	Return GetLaterVersions(Sections, LatestVersion1).Count() > 0;
	
EndFunction

// Checks the status of deferred update handlers.
//
Function UncompletedHandlersStatus(OnUpdate = False) Export
	
	UpdateInfo = InfobaseUpdateInfo();
	
	If OnUpdate Then
		DataVersion = IBVersion(Metadata.Name);
		DataVersionWithoutBuildNumber = CommonClientServer.ConfigurationVersionWithoutBuildNumber(DataVersion);
		MetadataVersionWithoutBuildNumber = CommonClientServer.ConfigurationVersionWithoutBuildNumber(Metadata.Version);
		IdenticalSubrevisions = (DataVersionWithoutBuildNumber = MetadataVersionWithoutBuildNumber);
		
		If DataVersion = "0.0.0.0" Or IdenticalSubrevisions Then
			// 
			// 
			Return "";
		EndIf;
		
		HandlerTreeVersion = UpdateInfo.HandlerTreeVersion;
		If HandlerTreeVersion <> "" And CommonClientServer.CompareVersions(HandlerTreeVersion, DataVersion) > 0 Then
			// 
			// 
			// 
			Return "";
		EndIf;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.Text =
		"SELECT
		|	UpdateHandlers.Status AS Status
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode
		|
		|GROUP BY
		|	UpdateHandlers.Status";
	HandlersStatuses = Query.Execute().Unload();
	
	If HandlersStatuses.Find(Enums.UpdateHandlersStatuses.NotPerformed) <> Undefined
		Or HandlersStatuses.Find(Enums.UpdateHandlersStatuses.Running) <> Undefined Then
		Return "UncompletedStatus";
	ElsIf HandlersStatuses.Find(Enums.UpdateHandlersStatuses.Error) <> Undefined Then
		Return "StatusError";
	ElsIf HandlersStatuses.Find(Enums.UpdateHandlersStatuses.Paused) <> Undefined Then
		Return "SuspendedStatus";
	Else
		Return "";
	EndIf;
	
EndFunction

// Performs all deferred update procedures in a loop in a single call.
//
Procedure ExecuteDeferredUpdateNow(ParametersOfUpdate = Undefined) Export
	
	UpdateInfo = InfobaseUpdateInfo();
	
	// 
	// 
	// 
	StartupParameters = StandardSubsystemsServer.ClientParametersAtServer().Get("LaunchParameter");
	SyncedUpdate = ParametersOfUpdate <> Undefined
		And (Not ParametersOfUpdate.OnClientStart
			Or StrFind(StartupParameters, "UpdateAndExit") > 0);
	IsScriptedUpdate = StrFind(StartupParameters, "UpdateAndExit") > 0;
	
	If UpdateInfo.DeferredUpdatesEndTime <> Undefined Then
		RunActionAfterDeferredInfobaseUpdate(SyncedUpdate);
		Return;
	EndIf;

	If UpdateInfo.DeferredUpdateStartTime = Undefined Then
		UpdateInfo.DeferredUpdateStartTime = CurrentSessionDate();
	EndIf;
	
	If TypeOf(UpdateInfo.SessionNumber) <> Type("ValueList") Then
		UpdateInfo.SessionNumber = New ValueList;
	EndIf;
	UpdateInfo.SessionNumber.Add(InfoBaseSessionNumber());
	WriteInfobaseUpdateInfo(UpdateInfo);
	
	HandlersExecutedEarlier = True;
	ProcessedItems = New Array;
	While HandlersExecutedEarlier Do
		HandlersExecutedEarlier = ExecuteDeferredUpdateHandler(ParametersOfUpdate); // 
		
		QueuesToClear = QueuesToClear(ProcessedItems); // 
		ClearProcessedQueues(QueuesToClear, ProcessedItems, UpdateInfo);
		
		If HandlersExecutedEarlier Then
			UpdateInfo = InfobaseUpdateInfo();
			If UpdateInfo.DeferredUpdateCompletedSuccessfully <> Undefined Then
				ClearHandlersLaunchTransactions();
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	RunActionAfterDeferredInfobaseUpdate(SyncedUpdate, IsScriptedUpdate);
	
EndProcedure

// For internal use.
Function AddClientParametersOnStart(Parameters) Export
	
	Parameters.Insert("MainConfigurationDataVersion", IBVersion(Metadata.Name));
	If SharedInfobaseDataUpdateRequired() Then
		Parameters.Insert("UndividedDataNeedsToBeUpdated");
	EndIf;
	
	// 
	IsCallBeforeStart = Parameters.RetrievedClientParameters <> Undefined;
	SimplifiedInfobaseUpdateForm = False;
	ErrorDescription = InfobaseLockedForUpdate(,
		IsCallBeforeStart, SimplifiedInfobaseUpdateForm);
	If ValueIsFilled(ErrorDescription) Then
		Parameters.Insert("InfobaseLockedForUpdate", ErrorDescription);
		// 
		Return False;
	EndIf;
	
	If SimplifiedInfobaseUpdateForm Then
		Parameters.Insert("SimplifiedInfobaseUpdateForm");
	EndIf;
	
	If MustCheckLegitimateSoftware() Then
		Parameters.Insert("CheckLegitimateSoftware");
	EndIf;
	
	Return True;
	
EndFunction

// APK: 581-off is Used for testing.
Function MustCheckLegitimateSoftware() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.SoftwareLicenseCheck") Then
		Return False;
	EndIf;
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return False;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	If Common.IsSubordinateDIBNode() Then
		Return False;
	EndIf;
	
	LegitimateVersion = "";
	
	If DataUpdateModeInLocalMode() = "InitialFilling" Then
		LegitimateVersion = Metadata.Version;
	Else
		UpdateInfo = InfobaseUpdateInfo();
		LegitimateVersion = UpdateInfo.LegitimateVersion;
	EndIf;
	
	Return LegitimateVersion <> Metadata.Version;
	
EndFunction
// 

// Returns the text of the reason for blocking if the information security update is required and the current user
// does not have enough rights for this, otherwise it returns an empty string.
//
// Parameters:
//  ForPrivilegedMode - Boolean -  if you specify False,
//                                    the presence of privileged mode will not be taken into account when checking the rights of the current user.
//  OnStart - Boolean
//  SimplifiedInfobaseUpdateForm - Boolean -  the return value.
//  
// Returns:
//  String - 
// 
Function InfobaseLockedForUpdate(ForPrivilegedMode = True,
			OnStart = Undefined, SimplifiedInfobaseUpdateForm = False) Export
	
	Message = "";
	
	CurrentIBUser = InfoBaseUsers.CurrentUser();
	
	// 
	If ForPrivilegedMode Then
		HasAdministrationRight = AccessRight("Administration", Metadata);
	Else
		HasAdministrationRight = AccessRight("Administration", Metadata, CurrentIBUser);
	EndIf;
	
	MessageForSystemAdministrator =
		NStr("en = 'The application is temporarily unavailable due to version update.
		           |To complete the version update, administrative rights are required
		           |(""System administrator"" and ""Full access"" roles).';");
	
	SetPrivilegedMode(True);
	DataSeparationEnabled = Common.DataSeparationEnabled();
	SeparatedDataUsageAvailable = Common.SeparatedDataUsageAvailable();
	SetPrivilegedMode(False);
	
	If SharedInfobaseDataUpdateRequired() Then
		
		MessageForDataAreaAdministrator =
			NStr("en = 'The application is temporarily unavailable due to version update.
			           |For details, contact the service administrator.';");
		
		If SeparatedDataUsageAvailable Then
			Message = MessageForDataAreaAdministrator;
			
		ElsIf Not CanUpdateInfobase(ForPrivilegedMode, False) Then
			
			If HasAdministrationRight Then
				Message = MessageForSystemAdministrator;
			Else
				Message = MessageForDataAreaAdministrator;
			EndIf;
		EndIf;
		
		Return Message;
	EndIf;
	
	// 
	If DataSeparationEnabled And Not SeparatedDataUsageAvailable Then
		Return "";
	EndIf;
		
	If CanUpdateInfobase(ForPrivilegedMode,
			True, SimplifiedInfobaseUpdateForm) Then
		
		If InfobaseUpdate.InfobaseUpdateRequired()
			And OnStart = True Then
			SetPrivilegedMode(True);
			Result = UpdateStartMark();
			SetPrivilegedMode(False);
			If Not Result.CanUpdate Then
				Message = NStr("en = 'The application is temporarily unavailable due to version update.
					|Now updating:
					|  computer: %1
					|  user: %2
					|  session: %3
					|  start time: %4
					|  application: %5';");
				
				Message = StringFunctionsClientServer.SubstituteParametersToString(Message,
					Result.UpdateSession.ComputerName,
					Result.UpdateSession.User,
					Result.UpdateSession.SessionNumber,
					Result.UpdateSession.SessionStarted,
					Result.UpdateSession.ApplicationName);
				Return Message;
			EndIf;
		EndIf;
		Return "";
	EndIf;
	
	RepeatedDataExchangeMessageImportRequiredBeforeStart = False;
	If Common.IsSubordinateDIBNode()
	   And Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeInternal = Common.CommonModule("DataExchangeInternal");
		RepeatedDataExchangeMessageImportRequiredBeforeStart = 
			ModuleDataExchangeInternal.RetryDataExchangeMessageImportBeforeStart();
	EndIf;
	
	// 
	If Not InfobaseUpdate.InfobaseUpdateRequired()
	   And Not MustCheckLegitimateSoftware()
	   And Not RepeatedDataExchangeMessageImportRequiredBeforeStart Then
		Return "";
	EndIf;
	
	// 
	If HasAdministrationRight Then
		Return MessageForSystemAdministrator;
	EndIf;

	If DataSeparationEnabled Then
		// 
		Message =
			NStr("en = 'The application is temporarily unavailable due to version update.
			           |For details, contact the service administrator.';");
	Else
		// 
		Message =
			NStr("en = 'The application is temporarily unavailable due to version update.
			           |For details, contact the service administrator.';");
	EndIf;
	
	Return Message;
	
EndFunction

// Returns:
//  Boolean
//
Function IsStartInfobaseUpdateSet() Export
	
	IsSet = StandardSubsystemsServer.ClientParametersAtServer(False).Get("StartInfobaseUpdate");
	Return IsSet <> Undefined;
	
EndFunction

// Sets the status of the information update start.
// Privileged mode is required.
//
// Parameters:
//  Run - Boolean -  if set to True, the state will be set,
//           if set to False, the state will be cleared.
//
Procedure SetInfobaseUpdateStartup(Val Run) Export
	
	If Not CanUpdateInfobase(False) Then
		Run = False;
	EndIf;
	
	SetPrivilegedMode(True);
	CurrentParameters = New Map(SessionParameters.ClientParametersAtServer);
	
	If Run = True Then
		CurrentParameters.Insert("StartInfobaseUpdate", True);
		
	ElsIf CurrentParameters.Get("StartInfobaseUpdate") <> Undefined Then
		CurrentParameters.Delete("StartInfobaseUpdate");
	EndIf;
	
	SessionParameters.ClientParametersAtServer = New FixedMap(CurrentParameters);
	
EndProcedure

// Gets information about the update of the information base
// of constants "Swedenization".
// 
// Returns:
//  Structure:
//     * UpdateStartTime - String
//     * UpdateEndTime - String
//     * UpdateDuration - String
//     * DeferredUpdateStartTime - String
//     * DeferredUpdatesEndTime - String
//     * SessionNumber - ValueList
//     * UpdateHandlerParameters - Structure
//     * DeferredUpdateCompletedSuccessfully - String
//     * HandlersTree - ValueTree
//     * HandlerTreeVersion - String
//     * OutputUpdatesDetails - Boolean
//     * LegitimateVersion - String
//     * NewSubsystems - Array
//     * DeferredUpdateManagement - Structure
//     * DataToProcess - Map
//     * CurrentUpdateIteration - Number
//     * DeferredUpdatePlan - Array
//     * UpdateSession - Structure
//     * ThreadsDetails - see the new description of the streams of the registration of the proposed updates
//     * VersionPatchesDeletion - String
//     * VersionOfPatchCheck - String
//     * DurationOfUpdateSteps - Structure:
//         ** CriticalOnes - Structure:
//              *** Begin - Date
//              *** End  - Date
//         ** Regular - Structure:
//              *** Begin - Date
//              *** End  - Date
//         ** NonCriticalOnes - Structure:
//              *** Begin - Date
//              *** End  - Date
//
Function InfobaseUpdateInfo() Export
	
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled()
	   And Not Common.SeparatedDataUsageAvailable() Then
		
		Return NewUpdateInfo();
	EndIf;
	
	IBUpdateInfo = Constants.IBUpdateInfo.Get().Get();
	If TypeOf(IBUpdateInfo) <> Type("Structure") Then
		Return NewUpdateInfo();
	EndIf;
	If IBUpdateInfo.Count() = 1 Then
		Return NewUpdateInfo();
	EndIf;
		
	IBUpdateInfo = NewUpdateInfo(IBUpdateInfo);
	Return IBUpdateInfo;
	
EndFunction

// Writes the data to update in a constant "Swedenization".
//
Procedure WriteInfobaseUpdateInfo(Val UpdateInfo) Export
	
	If UpdateInfo = Undefined Then
		NewValue = NewUpdateInfo();
	Else
		NewValue = UpdateInfo;
	EndIf;
	
	ManagerOfConstant = Constants.IBUpdateInfo.CreateValueManager();
	ManagerOfConstant.Value = New ValueStorage(NewValue);
	InfobaseUpdate.WriteData(ManagerOfConstant);
	
EndProcedure

// Writes the duration of the main update cycle to a constant.
//
Procedure WriteUpdateExecutionTime(UpdateStartTime, UpdateEndTime) Export
	
	If Common.DataSeparationEnabled() And Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	UpdateInfo = InfobaseUpdateInfo();
	UpdateInfo.UpdateStartTime = UpdateStartTime;
	UpdateInfo.UpdateEndTime = UpdateEndTime;
	
	TimeInSeconds = UpdateEndTime - UpdateStartTime;
	
	Hours1 = Int(TimeInSeconds/3600);
	Minutes1 = Int((TimeInSeconds - Hours1 * 3600) / 60);
	Seconds = TimeInSeconds - Hours1 * 3600 - Minutes1 * 60;
	
	DurationHours = ?(Hours1 = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 h';"), Hours1));
	DurationMinutes = ?(Minutes1 = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 min';"), Minutes1));
	DurationSeconds = ?(Seconds = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 sec';"), Seconds));
	UpdateDuration = DurationHours + " " + DurationMinutes + " " + DurationSeconds;
	UpdateInfo.UpdateDuration = TrimAll(UpdateDuration);
	
	WriteInfobaseUpdateInfo(UpdateInfo);
	
EndProcedure

// For internal use only.
Procedure WriteLegitimateSoftwareConfirmation() Export
	
	If Common.DataSeparationEnabled()
	   And Not Common.SeparatedDataUsageAvailable()
	   Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		
		Return;
	EndIf;
	
	UpdateInfo = InfobaseUpdateInfo();
	UpdateInfo.LegitimateVersion = Metadata.Version;
	WriteInfobaseUpdateInfo(UpdateInfo);
	
EndProcedure

// Sets the flag for displaying descriptions of changes in software versions for
// the current version, inclusive, if the flag was not set for the user 
// earlier.
//
// Parameters:
//  UserName - String -  the name of the user for which
//   you need to set the flag.
//
Procedure SetShowDetailsToNewUserFlag(Val UserName) Export
	
	If SystemChangesDisplayLastVersion(UserName) = Undefined Then
		SetShowDetailsToCurrentVersionFlag(UserName);
	EndIf;
	
EndProcedure

// Re-registers updated data on the exchange plan
// Updating the information database is required when loading data
// from the service to the box and back.
//
Procedure ReregisterDataForDeferredUpdate() Export
	
	ParametersInitialized = False;
	
	Handlers = HandlersForDeferredDataRegistration();
	UpdateInfo = InfobaseUpdateInfo();
	SubsystemVersionsAtStartUpdates = UpdateInfo.SubsystemVersionsAtStartUpdates;
	
	For Each Handler In Handlers Do
		SubsystemVersionAtStartUpdates = SubsystemVersionsAtStartUpdates[Handler.LibraryName];
		
		If Not ParametersInitialized Then
			HandlerParametersStructure = InfobaseUpdate.MainProcessingMarkParameters();
			HandlerParametersStructure.ReRegistration = True;
			ParametersInitialized = True;
		EndIf;
		
		HandlerParametersStructure.Queue = Handler.DeferredProcessingQueue;
		HandlerParametersStructure.HandlerName = Handler.HandlerName;
		HandlerParametersStructure.Insert("HandlerData", New Map);
		HandlerParametersStructure.Insert("UpToDateData", InfobaseUpdate.UpToDateDataSelectionParameters());
		HandlerParametersStructure.Insert("RegisteredRecordersTables", New Map);
		HandlerParametersStructure.Insert("SubsystemVersionAtStartUpdates", SubsystemVersionAtStartUpdates);
		
		If Handler.Multithreaded Then
			HandlerParametersStructure.SelectionParameters =
				InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters();
		Else
			HandlerParametersStructure.SelectionParameters = Undefined;
		EndIf;
		
		HandlerParameters = New Array;
		HandlerParameters.Add(HandlerParametersStructure);
		Try
			Message = NStr("en = 'Executing data population procedure
				                   |%1
				                   |of deferred update handler
				                   |%2.';");
			Message = StringFunctionsClientServer.SubstituteParametersToString(Message,
				Handler.UpdateDataFillingProcedure,
				Handler.HandlerName);
			WriteInformation(Message);
			
			Common.ExecuteConfigurationMethod(Handler.UpdateDataFillingProcedure, HandlerParameters);
			If Handler.Multithreaded Then
				CorrectFullNamesInTheSelectionParameters(HandlerParametersStructure.SelectionParameters);
			EndIf;
		Except
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'An error occurred while calling data population procedure
						   |""%1""
						   |of deferred update handler
						   |""%2"":
						   |%3.
						   |';"),
				Handler.UpdateDataFillingProcedure,
				Handler.HandlerName,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WriteError(ErrorText);
			
			Properties = New Structure;
			Properties.Insert("Status", Enums.UpdateHandlersStatuses.Error);
			Properties.Insert("ErrorInfo", ErrorText);
			SetHandlerProperties(Handler.HandlerName, Properties);

			Raise;
		EndTry;
		
		DataToProcessDetails = NewDataToProcessDetails(Handler.Multithreaded);
		DataToProcessDetails.HandlerData = HandlerParametersStructure.HandlerData;
		DataToProcessDetails.HandlerName    = Handler.HandlerName;
		DataToProcessDetails.UpToDateData  = HandlerParametersStructure.UpToDateData;
		If ValueIsFilled(HandlerParametersStructure.RegisteredRecordersTables) Then
			RegisteredTables = New Array;
			For Each KeyAndValue In HandlerParametersStructure.RegisteredRecordersTables Do
				RegisteredTables.Add(KeyAndValue.Value);
			EndDo;
		EndIf;
		DataToProcessDetails.RegisteredRecordersTables = RegisteredTables;
		
		If Handler.Multithreaded Then
			DataToProcessDetails.SelectionParameters = HandlerParametersStructure.SelectionParameters;
		EndIf;
		
		DataToProcessDetails = New ValueStorage(DataToProcessDetails, New Deflation(9));
		HandlerProperty(Handler.HandlerName, "DataToProcess", DataToProcessDetails);
		
	EndDo;
	
EndProcedure

// Returns parameters of the deferred update handler.
// Checks whether the update handler has saved parameters
// and returns them.
// 
// Parameters:
//  Id - String
//                - UUID - 
//                  
//
// Returns:
//  Structure - 
//
Function DeferredUpdateHandlerParameters(Id) Export
	HandlerUpdates = HandlerUpdates(Id);
	
	If HandlerUpdates = Undefined Then
		Return Undefined;
	EndIf;
	
	ExecutionStatistics = HandlerUpdates.ExecutionStatistics.Get();
	Parameters = ExecutionStatistics["HandlerParameters"];
	If Parameters = Undefined Then
		Parameters = New Structure;
	EndIf;
	
	Return Parameters;
EndFunction

// Writes the settings of the deferred processor upgrade
// 
// Parameters:
//  Id - String
//                - UUID - 
//                  
//  Parameters     - Structure -  the parameters that must be maintained.
//
Procedure WriteDeferredUpdateHandlerParameters(Id, Parameters) Export
	HandlerUpdates = HandlerUpdates(Id);
	
	If HandlerUpdates = Undefined Then
		Return;
	EndIf;
	
	ExecutionStatistics = HandlerUpdates.ExecutionStatistics.Get();
	ExecutionStatistics.Insert("HandlerParameters", Parameters);
	
	HandlerProperty(Id,
		"ExecutionStatistics",
		New ValueStorage(ExecutionStatistics));
EndProcedure

// 
//
// 
// 
//  See DefaultInfobaseUpdateThreadsCount.
//
// Returns:
//  Number - 
//
Function InfobaseUpdateThreadCount() Export
	
	If MultithreadUpdateAllowed() Then
		Count = 0;
		ParameterName = "UpdateThreadsCount1=";
		Parameters = StandardSubsystemsServer.ClientParametersAtServer().Get("LaunchParameter");
		ParameterPosition = StrFind(Parameters, ParameterName);
		
		If ParameterPosition > 0 Then
			SeparatorPosition = StrFind(Parameters, ";",, ParameterPosition + StrLen(ParameterName));
			Length = ?(SeparatorPosition > 0, SeparatorPosition, StrLen(Parameters) + 1) - ParameterPosition;
			UpdateThreads = StrSplit(Mid(Parameters, ParameterPosition, Length), "=");
			
			Try
				Count = Number(UpdateThreads[1]);
			Except
				ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Specify application startup parameter ""%1"" in format
						|""%1=X"", where X is the maximum number of update threads.';"),
					"UpdateThreadsCount1");
				Raise ExceptionText;
			EndTry;
		EndIf;
		
		If Count = 0 Then
			Count = Constants.InfobaseUpdateThreadCount.Get();
			
			If Count = 0 Then
				Count = DefaultInfobaseUpdateThreadsCount();
			EndIf;
		EndIf;
		
		Return Count;
	Else
		Return 1;
	EndIf;
	
EndFunction

// Returns the iterations of the update.
//
// Returns:
//  Array of See UpdateIteration
//
Function UpdateIterations() Export
	
	BaseConfigurationName = Metadata.Name;
	MainSubsystemUpdateIteration = Undefined;
	
	UpdateIterations = New Array;
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	SubsystemsVersions    = IBVersion(Undefined);
	For Each SubsystemName In SubsystemsDetails.Order Do
		SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName);
		If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		
		UpdateIteration = UpdateIteration(SubsystemDetails.Name, SubsystemDetails.Version, 
			InfobaseUpdate.NewUpdateHandlerTable(), SubsystemDetails.Name = BaseConfigurationName);
		UpdateIteration.MainServerModuleName = SubsystemDetails.MainServerModule;
		UpdateIteration.MainServerModule = Module;
		If Not ValueIsFilled(SubsystemsVersions) Then
			UpdateIteration.PreviousVersion = "0.0.0.0";
		Else
			PreviousVersion = SubsystemsVersions[SubsystemDetails.Name];
			If PreviousVersion = Undefined Then
				UpdateIteration.PreviousVersion = "0.0.0.0";
			Else
				UpdateIteration.PreviousVersion = SubsystemsVersions[SubsystemDetails.Name];
			EndIf;
		EndIf;
		UpdateIterations.Add(UpdateIteration);
		
		Module.OnAddUpdateHandlers(UpdateIteration.Handlers);
		
		If SubsystemDetails.Name = BaseConfigurationName Then
			MainSubsystemUpdateIteration = UpdateIteration;
		EndIf;
		
		ValidateHandlerProperties(UpdateIteration);
	EndDo;
	
	If MainSubsystemUpdateIteration = Undefined And BaseConfigurationName = "StandardSubsystemsLibrary" Then
		MessageText = NStr("en = 'The 1C:Standard Subsystems Library distribution file is not intended for template-based infobase creation.
			|Before you start using it,  read the <link https://kb.1ci.com/1C_Standard_Subsystems_Library/Guides/>SSL documentation</>.';");
		Raise MessageText;
	EndIf;
	
	Return UpdateIterations;
	
EndFunction

// 

// Updates the list of executed update handlers in the information registers
// Update handlers and general data update handlers.
//
Procedure UpdateListOfUpdateHandlersToExecute(UpdateIterations, FirstExchangeInDIB = False, HandlerTypes = Undefined) Export
	
	OnlyDeferred  = (HandlerTypes = "Deferred3");
	OnlyExclusive = (HandlerTypes = "Monopoly");
	
	If Not OnlyExclusive Then
		UpdateInfo = InfobaseUpdateInfo();
		IncompleteDeferredHandlers = IncompleteDeferredHandlers(UpdateInfo);
	EndIf;
	BeginTransaction();
	Try
		
		If Not OnlyExclusive Then
			SubsystemVersionsAtStartUpdates = New Map;
			DeferredUpdateCompletedSuccessfully = Undefined;
			FillinSubsystemVersions = False;
			If Common.SeparatedDataUsageAvailable() Then
				DeferredUpdateCompletedSuccessfully = Constants.DeferredUpdateCompletedSuccessfully.Get();
				SubsystemVersionsAtStartUpdates    = UpdateInfo.SubsystemVersionsAtStartUpdates;
				FillinSubsystemVersions = True;
			EndIf;
			
			If DeferredUpdateCompletedSuccessfully = True Then
				SubsystemVersionsAtStartUpdates.Clear();
			EndIf;
			
			ClearUpdateInformation(UpdateInfo);
			
			CheckDeferredHandlerIDUniqueness(UpdateIterations);
		EndIf;
		
		// 
		If Common.SeparatedDataUsageAvailable() Then
			SeparatedHandlersSet = InformationRegisters.UpdateHandlers.CreateRecordSet();
			If OnlyExclusive Then
				// 
				SeparatedHandlersSet.Read();
				HandlersTable = SeparatedHandlersSet.Unload();
				
				FilterParameters = New Structure;
				FilterParameters.Insert("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
				HandlersTable = HandlersTable.Copy(FilterParameters);
				
				SeparatedHandlersSet.Load(HandlersTable);
			ElsIf OnlyDeferred Then
				// 
				SeparatedHandlersSet.Read();
				HandlersTable = SeparatedHandlersSet.Unload();
				
				FilterParameters = New Structure;
				FilterParameters.Insert("ExecutionMode", Enums.HandlersExecutionModes.Exclusively);
				ExclusiveHandlers = HandlersTable.Copy(FilterParameters);
				
				FilterParameters.Insert("ExecutionMode", Enums.HandlersExecutionModes.Seamless);
				OperationalHandlers = HandlersTable.Copy(FilterParameters);
				
				CommonClientServer.SupplementTable(ExclusiveHandlers, OperationalHandlers);
				
				SeparatedHandlersSet.Load(OperationalHandlers);
			EndIf;
			SeparatedHandlersSet.Write();
		EndIf;
		If Not OnlyDeferred And Not Common.DataSeparationEnabled() Or Not Common.SeparatedDataUsageAvailable() Then
			SharedHandlersSet = InformationRegisters.SharedDataUpdateHandlers.CreateRecordSet();
			SharedHandlersSet.Write();
		EndIf;
		// 
		
		LibraryDetailsList = StandardSubsystemsCached.SubsystemsDetails().ByNames;
		UpdateGroup = 1;
		CurrentExecutionMode = "";
		ErrorsText = "";
		AddedHandlers = New Array;
		For Each UpdateIteration In UpdateIterations Do
			
			If Not OnlyExclusive And FillinSubsystemVersions Then
				SavedVersion = SubsystemVersionsAtStartUpdates[UpdateIteration.Subsystem];
				If SavedVersion = Undefined Then
					SubsystemVersionsAtStartUpdates.Insert(UpdateIteration.Subsystem, UpdateIteration.PreviousVersion);
				Else
					If CommonClientServer.CompareVersions(SavedVersion, UpdateIteration.PreviousVersion) > 0 Then
						SubsystemVersionsAtStartUpdates.Insert(UpdateIteration.Subsystem, UpdateIteration.PreviousVersion);
					EndIf;
				EndIf;
			EndIf;
			
			// 
			LibraryName = UpdateIteration.Subsystem;
			If Not OnlyDeferred Then
				If Not FirstExchangeInDIB Then
					PreviousVersion = UpdateIteration.PreviousVersion;
					MetadataVersion = UpdateIteration.Version;
					If IsBlankString(MetadataVersion) Then
						MetadataVersion = "0.0.0.0";
					EndIf;
					
					HandlersByVersion = Undefined;
					If PreviousVersion <> "0.0.0.0"
						And Common.DataSeparationEnabled()
						And Common.SeparatedDataUsageAvailable() Then
						HandlersByVersion = GetUpdatePlan(UpdateIteration.Subsystem, PreviousVersion, MetadataVersion);
					EndIf;
					
					If HandlersByVersion = Undefined Then
						HandlersByVersion = UpdateInIntervalHandlers(UpdateIteration.Handlers,
							PreviousVersion, UpdateIteration.Version);
					EndIf;
					
					If HandlersByVersion.Rows.Count() <> 0 Then
						HandlersByVersion.Columns.Procedure.Name = "HandlerName";
						AddHandlers(LibraryName, HandlersByVersion.Rows, AddedHandlers);
					EndIf;
				EndIf;
			EndIf;
			
			If OnlyExclusive Then
				Continue;
			EndIf;
			
			// 
			If Common.SeparatedDataUsageAvailable() Then
				// 
				PreviousVersion = ?(FirstExchangeInDIB, "1.0.0.0", UpdateIteration.PreviousVersion);
				DeferredHandlersExecutionMode = LibraryDetailsList[LibraryName].DeferredHandlersExecutionMode;
				ParallelSinceVersion = LibraryDetailsList[LibraryName].ParallelDeferredUpdateFromVersion;
				If FirstExchangeInDIB And DeferredHandlersExecutionMode = "Sequentially" Then
					Continue;
				EndIf;
				
				FilterParameters = HandlerFIlteringParameters();
				FilterParameters.GetSeparated = True;
				FilterParameters.UpdateMode = "Deferred";
				FilterParameters.IncludeFirstExchangeInDIB = (DeferredHandlersExecutionMode = "Parallel");
				FilterParameters.FirstExchangeInDIB = FirstExchangeInDIB;
				
				HandlersByVersion = UpdateInIntervalHandlers(UpdateIteration.Handlers,
					PreviousVersion, UpdateIteration.Version, FilterParameters);
				HandlersByVersion.Columns.Procedure.Name = "HandlerName";
				AddIncompleteDeferredHandlers(
					UpdateIteration,
					LibraryName,
					IncompleteDeferredHandlers,
					HandlersByVersion.Rows);
				
				If FirstExchangeInDIB Then
					LinesToDelete = New Array;
					For Each VersionRow In HandlersByVersion.Rows Do
						If VersionRow.Version = "*"
							Or (ValueIsFilled(ParallelSinceVersion)
								And CommonClientServer.CompareVersions(VersionRow.Version, ParallelSinceVersion) < 0) Then
							LinesToDelete.Add(VersionRow);
						EndIf;
					EndDo;
					
					For Each RowToDelete In LinesToDelete Do
						HandlersByVersion.Rows.Delete(RowToDelete);
					EndDo;
				EndIf;
				
				If HandlersByVersion.Rows.Count() = 0 Then
					Continue;
				EndIf;
				
				OrderHandlersVersions(HandlersByVersion);
				
				AddDeferredHandlers(LibraryName, HandlersByVersion.Rows, UpdateGroup, ErrorsText, CurrentExecutionMode);
			EndIf;
			
		EndDo;
		
		If ValueIsFilled(ErrorsText) Then
			Raise(ErrorsText, ErrorCategory.ConfigurationError);
		EndIf;
		
		If (HandlerTypes = Undefined Or OnlyDeferred)
			And (Not Common.DataSeparationEnabled() Or Not Common.SeparatedDataUsageAvailable()) Then
			Constants.OrderOfDataToProcess.Set(Enums.OrderOfUpdateHandlers.Crucial);
		EndIf;
		
		If Not OnlyExclusive And FillinSubsystemVersions Then
			UpdateInfo = InfobaseUpdateInfo();
			UpdateInfo.SubsystemVersionsAtStartUpdates = SubsystemVersionsAtStartUpdates;
			WriteInfobaseUpdateInfo(UpdateInfo);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// 

// Called to enable and disable deferred updates.
//
// Parameters:
//   Use - Boolean -  True if the task needs to be enabled, otherwise False.
//
Procedure OnEnableDeferredUpdate(Use) Export
	
	JobsFilter = New Structure;
	JobsFilter.Insert("Metadata", Metadata.ScheduledJobs.DeferredIBUpdate);
	Jobs = ScheduledJobsServer.FindJobs(JobsFilter);
	
	For Each Job In Jobs Do
		If Job.Use = Use Then
			Continue;
		EndIf;
		
		JobParameters = New Structure("Use", Use);
		
		YouNeedToSetTheScheduledStartTime = False;
		If Common.SubsystemExists("CloudTechnology.Core") Then
			ModuleSaaSTechnology = Common.CommonModule("CloudTechnology");
			CTLLibraryVersion = ModuleSaaSTechnology.LibraryVersion();
			YouNeedToSetTheScheduledStartTime = CommonClientServer.CompareVersions(CTLLibraryVersion, "2.0.1.0") > 0;
		EndIf;
		
		If Common.DataSeparationEnabled()
			And Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS")
			And Use
			And YouNeedToSetTheScheduledStartTime Then
			ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
			ScheduledStartTime = ModuleInfobaseUpdateInternalSaaS.ScheduledTimeWhenTheAreaUpdateStarts();
			JobParameters.Insert("ScheduledStartTime", ScheduledStartTime);
		EndIf;
		
		ScheduledJobsServer.ChangeJob(Job.UUID, JobParameters);
	EndDo;
	
EndProcedure

// Executes live and exclusive update handlers
// on the passed update iteration.
//
Function ExecuteUpdateIteration(Val UpdateIteration, Val Parameters) Export
	
	LibraryID = UpdateIteration.Subsystem;
	IBMetadataVersion      = UpdateIteration.Version;
	UpdateHandlers   = UpdateIteration.Handlers;
	
	CurrentIBVersion = UpdateIteration.PreviousVersion;
	
	NewIBVersion = CurrentIBVersion;
	MetadataVersion = IBMetadataVersion;
	If IsBlankString(MetadataVersion) Then
		MetadataVersion = "0.0.0.0";
	EndIf;
	
	If CurrentIBVersion <> "0.0.0.0"
		And Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		// 
		HandlersToExecute = GetUpdatePlan(LibraryID, CurrentIBVersion, MetadataVersion);
		If HandlersToExecute = Undefined Then
			If UpdateIteration.IsMainConfiguration Then 
				MessageTemplate = NStr("en = 'The update plan for configuration %1 (version %2 to %3) does not exist.';");
			Else
				MessageTemplate = NStr("en = 'The update plan for library %1 (version %2 to %3) does not exist.';");
			EndIf;
			Message = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, LibraryID, CurrentIBVersion, MetadataVersion);
			WriteInformation(Message);
			
			HandlersToExecute = UpdateInIntervalHandlers(UpdateHandlers, CurrentIBVersion, MetadataVersion);
		EndIf;
	Else
		HandlersToExecute = UpdateInIntervalHandlers(UpdateHandlers, CurrentIBVersion, MetadataVersion);
	EndIf;
	
	MandatorySeparatedHandlers = InfobaseUpdate.NewUpdateHandlerTable();
	SourceIBVersion = CurrentIBVersion;
	WriteToLog1 = Constants.WriteIBUpdateDetailsToEventLog.Get();
	
	For Each Version In HandlersToExecute.Rows Do
		
		If Version.Version = "*" Then
			Message = NStr("en = 'Mandatory updates in progress.';");
		Else
			NewIBVersion = Version.Version;
			If CurrentIBVersion = "0.0.0.0" Then
				Message = NStr("en = 'Initializing the application.';");
			ElsIf UpdateIteration.IsMainConfiguration Then 
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Updating infobase version %1 to version %2.';"), 
					CurrentIBVersion, NewIBVersion);
			Else
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Updating %3 library version %1 to version %2.';"), 
					CurrentIBVersion, NewIBVersion, LibraryID);
			EndIf;
		EndIf;
		WriteInformation(Message);
		
		For Each Handler In Version.Rows Do
			
			HandlerParameters = Undefined;
			If Handler.RegistrationVersion = "*" Then
				
				If Handler.HandlerManagement Then
					HandlerParameters = New Structure;
					HandlerParameters.Insert("SeparatedHandlers", MandatorySeparatedHandlers);
				EndIf;
				
				If Handler.ExclusiveMode = True Or Handler.ExecutionMode = "Exclusively" Then
					If Parameters.SeamlessUpdate Then
						// 
						// 
						Continue;
					EndIf;
					
					If HandlerParameters = Undefined Then
						HandlerParameters = New Structure;
					EndIf;
					HandlerParameters.Insert("ExclusiveMode", True);
				EndIf;
			EndIf;
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("WriteToLog1", WriteToLog1);
			AdditionalParameters.Insert("LibraryID", LibraryID);
			AdditionalParameters.Insert("HandlerExecutionProgress", Parameters.HandlerExecutionProgress);
			AdditionalParameters.Insert("InBackground", Parameters.InBackground);
			
			ExecuteUpdateHandler(Handler, HandlerParameters, AdditionalParameters);
		EndDo;
		
		If Version.Version = "*" Then
			Message = NStr("en = 'Mandatory updates finished.';");
		ElsIf StrStartsWith(Version.Version, "DebuggingTheHandler") Then
			Message = NStr("en = 'Debugged updates finished.';");
		Else
			If UpdateIteration.IsMainConfiguration Then 
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Infobase update from version %1 to version %2 is completed.';"), 
					CurrentIBVersion, NewIBVersion);
			Else
				Message = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'The update of %3 library from version %1 to version %2 is completed.';"), 
					CurrentIBVersion, NewIBVersion, LibraryID);
			EndIf;
		EndIf;
		WriteInformation(Message);
		
		If Version.Version <> "*" And Not StrStartsWith(Version.Version, "DebuggingTheHandler") Then
			// 
			SetIBVersion(LibraryID, NewIBVersion, UpdateIteration.IsMainConfiguration);
			CurrentIBVersion = NewIBVersion;
		EndIf;
		
	EndDo;
	
	// 
	MarkRegisterData = Undefined;
	If Parameters.Property("MarkRegisterData") Then
		MarkRegisterData = Parameters.MarkRegisterData;
	EndIf;
	If IBVersion(LibraryID) <> IBMetadataVersion Then
		SetIBVersion(LibraryID, IBMetadataVersion, UpdateIteration.IsMainConfiguration, MarkRegisterData);
	EndIf;
	
	If CurrentIBVersion <> "0.0.0.0" Then
		
		If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
			
			ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
			ModuleInfobaseUpdateInternalSaaS.GenerateDataAreaUpdatePlan(LibraryID, UpdateHandlers,
				MandatorySeparatedHandlers, SourceIBVersion, IBMetadataVersion);
			
		EndIf;
		
	EndIf;
	
	Return HandlersToExecute;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonOverridable.OnAddSessionParameterSettingHandlers.
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	Handlers.Insert("IBUpdateInProgress", "InfobaseUpdateInternal.SessionParametersSetting");
	Handlers.Insert("UpdateHandlerParameters", "InfobaseUpdateInternal.SessionParametersSetting");
	Handlers.Insert("TimeConsumingOperations", "TimeConsumingOperations.SessionParametersSetting");
	
EndProcedure

// See CommonOverridable.OnAddReferenceSearchExceptions.
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	RefSearchExclusions.Add(Metadata.InformationRegisters.DataProcessedInMasterDIBNode.FullName());

EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ClearObsoleteData;
	Setting.IsParameterized = True;
	
EndProcedure

// See MonitoringCenterOverridable.OnCollectConfigurationStatisticsParameters.
Procedure OnCollectConfigurationStatisticsParameters() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		Return;
	EndIf;
	
	ModuleMonitoringCenter = Common.CommonModule("MonitoringCenter");
	
	UpdateInfo = InfobaseUpdateInfo();
	If UpdateInfo.DeferredUpdateCompletedSuccessfully <> True Then
		Return; // 
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.Text =
		"SELECT
		|	UpdateHandlers.HandlerName AS HandlerName,
		|	UpdateHandlers.ProcessingDuration AS ProcessingDuration
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode";
	Handlers = Query.Execute().Unload();
	
	For Each Handler In Handlers Do
		ModuleMonitoringCenter.WriteConfigurationObjectStatistics("DeferredHandlerRunTime." + Handler.HandlerName, Handler.ProcessingDuration / 1000);
	EndDo;
	
	BeginTime = UpdateInfo.UpdateStartTime;
	EndTime = UpdateInfo.UpdateEndTime;
	
	If ValueIsFilled(BeginTime) And ValueIsFilled(EndTime) Then
		ModuleMonitoringCenter.WriteConfigurationObjectStatistics("HandlersRunTime",
			EndTime - BeginTime);
	EndIf;
	
	BeginTime = UpdateInfo.DeferredUpdateStartTime;
	EndTime = UpdateInfo.DeferredUpdatesEndTime;
	
	If ValueIsFilled(BeginTime) And ValueIsFilled(EndTime) Then
		ModuleMonitoringCenter.WriteConfigurationObjectStatistics("DeferredHandlersRunTime",
			EndTime - BeginTime);
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToSlave.
Procedure OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Recipient) Export
	
	OnSendSubsystemVersions(DataElement, ItemSend, InitialImageCreating);
	
EndProcedure

// 
Procedure OnSendDataToMaster(DataElement, ItemSend, Recipient) Export
	
	OnSendSubsystemVersions(DataElement, ItemSend);
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	Parameters.Insert("DataPopulation", DataUpdateMode() = "InitialFilling");
	Parameters.Insert("ShowChangeHistory1", ShowChangeHistory1());
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If Users.IsFullUser(, True)
		And Not InfobaseUpdate.InfobaseUpdateRequired()
		And Not Common.DataSeparationEnabled()
		And Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		InformationRecords = InfobaseUpdateInfo();
		VersionOfPatchCheck = InformationRecords.VersionOfPatchCheck;
		If VersionOfPatchCheck = Undefined
			Or CommonClientServer.CompareVersions(Metadata.Version, VersionOfPatchCheck) > 0 Then
			ModuleConfigurationUpdate = Common.CommonModule("ConfigurationUpdate");
			Result = ModuleConfigurationUpdate.PatchesChanged();
			InformationRecords.VersionOfPatchCheck = Metadata.Version;
			If Result.HasChanges Then
				InformationRecords.VersionPatchesDeletion = Metadata.Version;
			EndIf;
			WriteInfobaseUpdateInfo(InformationRecords);
		EndIf;
	EndIf;
	
	HandlersStatus = UncompletedHandlersStatus();
	If HandlersStatus = "" Then
		Return;
	EndIf;
	If HandlersStatus = "StatusError"
		And Users.IsFullUser(, True) Then
		Parameters.Insert("ShowInvalidHandlersMessage");
	Else
		Parameters.Insert("ShowUncompletedHandlersNotification");
	EndIf;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	If Common.SubsystemExists("StandardSubsystems.SoftwareLicenseCheck") Then
		Handler = Handlers.Add();
		Handler.InitialFilling = True;
		Handler.Procedure = "InfobaseUpdateInternal.WriteLegitimateSoftwareConfirmation";
	EndIf;
	
	If Not Common.DataSeparationEnabled() Then
		Handler = Handlers.Add();
		Handler.Version = "3.0.2.160";
		Handler.Procedure = "InfobaseUpdateInternal.InstallScheduledJobKey";
		Handler.ExecutionMode = "Seamless";
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = StandardSubsystemsServer.LibraryVersion(); // 
	Handler.Procedure = "InfobaseUpdateInternal.ClearOutdatedDataCompletely";
	Handler.ExecutionMode = "Deferred";
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	Handler.Id = IdOfHandlerForClearingOutdatedData();
	Handler.UpdateDataFillingProcedure = "InfobaseUpdateInternal.EmptyRegistrationProcedure";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.ObjectsToRead = "InformationRegister.UpdateHandlers";
	Handler.ObjectsToChange = "InformationRegister.UpdateHandlers";
	Handler.Comment =
		NStr("en = 'Clears obsolete data to avoid the ""Register records are no longer unique"" error during a date restructuring when updating.';");
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplateList.
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.DeferredIBUpdate.Name);
	
EndProcedure

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not Users.IsFullUser(, True)
		Or ModuleToDoListServer.UserTaskDisabled("DeferredUpdate") Then
		Return;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	// 
	// 
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.DataProcessors.ApplicationUpdateResult.FullName());
	
	HandlersStatus           = UncompletedHandlersStatus();
	HasHandlersWithErrors      = (HandlersStatus = "StatusError");
	HasUncompletedHandlers = (HandlersStatus = "UncompletedStatus");
	HasPausedHandlers = (HandlersStatus = "SuspendedStatus");
	
	For Each Section In Sections Do
		Id = "DeferredUpdate" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.Id = Id;
		ToDoItem.HasToDoItems      = (HasHandlersWithErrors Or HasUncompletedHandlers Or HasPausedHandlers);
		ToDoItem.Important        = HasHandlersWithErrors;
		ToDoItem.Presentation = NStr("en = 'Application update is not completed';");
		ToDoItem.Form         = "DataProcessor.ApplicationUpdateResult.Form.ApplicationUpdateResult";
		ToDoItem.Owner      = Section;
	EndDo;
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.DeferredUpdateProgress);
EndProcedure

// Restarts deferred handlers that run only on the master node
// when the first exchange message is received.
//
Procedure OnGetFirstDIBExchangeMessageAfterUpdate() Export
	
	SetPrivilegedMode(True);
	
	FileInfobase = Common.FileInfobase();
	UpdateInfo       = InfobaseUpdateInfo();
	If UpdateInfo.DeferredUpdateCompletedSuccessfully = Undefined
		And Not FileInfobase Then
		CancelDeferredUpdate();
		FilterParameters = New Structure;
		FilterParameters.Insert("MethodName", "InfobaseUpdateInternal.ExecuteDeferredUpdate");
		FilterParameters.Insert("State", BackgroundJobState.Active);
		BackgroundJobArray = BackgroundJobs.GetBackgroundJobs(FilterParameters);
		If BackgroundJobArray.Count() = 1 Then
			BackgroundJob = BackgroundJobArray[0];
			BackgroundJob.Cancel();
		EndIf;
	EndIf;
	
	UpdateIterations = UpdateIterations();
	FillInHandlerQueueNumber(UpdateIterations);
	UpdateListOfUpdateHandlersToExecute(UpdateIterations, True);
	ReregisterDataForDeferredUpdate();
	If FileInfobase Then
		ExecuteDeferredUpdateNow();
	Else
		ScheduleDeferredUpdate();
	EndIf;
	
EndProcedure

// Called when the update script is executed from the configuration update procedure.Complete the update.
Procedure AfterUpdateCompletion() Export
	
	WriteLegitimateSoftwareConfirmation();
	
EndProcedure

// See ExportImportDataOverridable.AfterImportData.
Procedure AfterImportData(Container) Export
	UpdateInfo = InfobaseUpdateInfo();
	
	If UpdateInfo.DeferredUpdateCompletedSuccessfully <> True Then
		ScheduleDeferredUpdate();
	EndIf;
EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	Command = Commands.Add();
	Command.Kind = "IBVersionUpdate";
	Command.Presentation = NStr("en = 'Unlock object for editing';");
	Command.WriteMode = "NotWrite";
	Command.Purpose = "ForObject";
	Command.OnlyInAllActions = True;
	Command.Handler = "InfobaseUpdateClient.UnlockObjectToEdit";
	
	ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
	ModuleAttachableCommands.AddCommandVisibilityCondition(Command, "IBVersionUpdate_ObjectLocked");
	
EndProcedure

// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	
	Kind = AttachableCommandsKinds.Add();
	Kind.Name = "IBVersionUpdate";
	Kind.Title   = NStr("en = 'Object unlock';");
	Kind.Representation = ButtonRepresentation.PictureAndText;
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert("InfobaseUpdate.RelaunchDeferredUpdate");
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.ClearObsoleteData.MethodName);
	
EndProcedure

// See AccountingAuditOverridable.OnDefineChecks.
Procedure OnDefineChecks(ChecksGroups, Checks) Export
	
	Validation = Checks.Add();
	Validation.GroupID          = "SystemChecks";
	Validation.Description                 = NStr("en = 'Issue when updating the application';");
	Validation.Reasons                      = NStr("en = 'Invalid data synchronization with external applications or data import,
		|errors in third-party tools (such as external data processors or extensions), or equipment malfunction.';");
	Validation.Recommendation                 = NStr("en = 'If mandatory attributes are missing, enter them manually.
		|Restore missing data in the backup copy.';");
	Validation.Id                = "InfoBaseUpdateProblemWithData";
	Validation.HandlerChecks           = "InfobaseUpdateInternal.HandlerAccountingChecks";
	Validation.ImportanceChangeDenied   = False;
	Validation.AccountingChecksContext = "IBVersionUpdate";
	Validation.isDisabled                    = True;
	
EndProcedure

Function SubsystemSettings() Export
	
	UncompletedDeferredHandlersMessageParameters = New Structure;
	UncompletedDeferredHandlersMessageParameters.Insert("MessageText", "");
	UncompletedDeferredHandlersMessageParameters.Insert("MessagePicture", Undefined);
	UncompletedDeferredHandlersMessageParameters.Insert("ProhibitContinuation", False);
	
	
	Settings = New Structure;
	Settings.Insert("UpdateResultNotes", "");
	Settings.Insert("ApplicationChangeHistoryLocation", "");
	Settings.Insert("UncompletedDeferredHandlersMessageParameters", UncompletedDeferredHandlersMessageParameters);
	Settings.Insert("MultiThreadUpdate", False);
	Settings.Insert("DefaultInfobaseUpdateThreadsCount", 1);
	
	Settings.Insert("ObjectsWithInitialFilling", New Array);
	SSLSubsystemsIntegration.OnDefineObjectsWithInitialFilling(Settings.ObjectsWithInitialFilling);
	
	InfobaseUpdateOverridable.OnDefineSettings(Settings);
	
	Return Settings;
	
EndFunction

// 

// Returns:
//  FixedMap of KeyAndValue:
//   * Key - MetadataObject
//   * Value - String -  full name of the metadata object
//
Function ObjectsWithInitialFilling() Export
	
	Return InfobaseUpdateInternalCached.ObjectsWithInitialFilling();
	
EndFunction

Function PredefinedItemsSettings(ObjectManager, PredefinedData) Export
	
	CustomSettingsFillItems = CustomSettingsFillItems();
	CustomSettingsFillItems.AdditionalParameters.Insert("PredefinedData", PredefinedData);
	
	FullObjectName = ObjectManager.EmptyRef().Metadata().FullName();
	
	ObjectManager.OnSetUpInitialItemsFilling(CustomSettingsFillItems);
	InfobaseUpdateOverridable.OnSetUpInitialItemsFilling(FullObjectName,
		CustomSettingsFillItems);
		
	ItemsFillingSettings = ItemsFillingSettings();
	FillPropertyValues(ItemsFillingSettings.OverriddenSettings, CustomSettingsFillItems);
	
	ItemsFillingSettings.IsColumnNamePredefinedData = 
		 PredefinedData.Columns.Find("PredefinedDataName") <> Undefined;
		 
	ItemsFillingSettings.OverriddenSettings.KeyAttributeName =
		?(ValueIsFilled(ItemsFillingSettings.OverriddenSettings.KeyAttributeName),
				ItemsFillingSettings.OverriddenSettings.KeyAttributeName, "PredefinedDataName");
	
	Return ItemsFillingSettings;
	
EndFunction

// 
// 
// Returns:
//  Structure:
//    * OverriddenSettings - See CustomSettingsFillItems
//    * IsColumnNamePredefinedData - Boolean
//
Function ItemsFillingSettings() Export
	
	ItemsFillingSettings = New Structure;
	ItemsFillingSettings.Insert("OverriddenSettings", CustomSettingsFillItems());
	ItemsFillingSettings.Insert("IsColumnNamePredefinedData", False);
	
	Return ItemsFillingSettings;
	
EndFunction

Function PredefinedObjectData(Val ObjectMetadata, ObjectManager, ObjectAttributesToLocalize) Export
	
	Languages = StandardSubsystemsServer.ConfigurationLanguages();
	
	// 
	PredefinedData = New ValueTable;
	TabularSections         = New Structure;
	
	For Each Attribute In ObjectMetadata.StandardAttributes Do
		AddPredefinedDataTableColumn(PredefinedData, Attribute, ObjectAttributesToLocalize, Languages);
	EndDo;
	
	For Each Attribute In ObjectMetadata.Attributes Do
		AddPredefinedDataTableColumn(PredefinedData, Attribute, ObjectAttributesToLocalize, Languages);
	EndDo;
	
	For Each TabularSection In ObjectMetadata.TabularSections Do
		
		PredefinedData.Columns.Add(TabularSection.Name, New TypeDescription("ValueTable"));
		Table = New ValueTable;
		For Each Attribute In TabularSection.StandardAttributes Do
			AddPredefinedDataTableColumn(Table, Attribute, ObjectAttributesToLocalize, Languages);
		EndDo;
		
		For Each Attribute In TabularSection.Attributes Do
			AddPredefinedDataTableColumn(Table, Attribute, ObjectAttributesToLocalize, Languages);
		EndDo;
		TabularSections.Insert(TabularSection.Name, Table);
		
	EndDo;
	
	If Common.IsChartOfAccounts(ObjectMetadata)
		 Or Common.IsChartOfCalculationTypes(ObjectMetadata) Then
			For Each TabularSection In ObjectMetadata.StandardTabularSections Do
				
				PredefinedData.Columns.Add(TabularSection.Name, New TypeDescription("ValueTable"));
				Table = New ValueTable;
				For Each Attribute In TabularSection.StandardAttributes Do
					AddPredefinedDataTableColumn(Table, Attribute, ObjectAttributesToLocalize, Languages);
				EndDo;
				
				TabularSections.Insert(TabularSection.Name, Table);
				
			EndDo;
	EndIf;
	
	If PredefinedData.Columns.Find("PredefinedDataName") <> Undefined Then
		PredefinedData.Indexes.Add("PredefinedDataName");
	EndIf;
	
	ObjectManager.OnInitialItemsFilling(Languages, PredefinedData, TabularSections);
	InfobaseUpdateOverridable.OnInitialItemsFilling(ObjectMetadata.FullName(), Languages, PredefinedData, TabularSections);
	
	If PredefinedData.Columns.Find("Ref") <> Undefined Then
		For Each StringPredefinedData In PredefinedData Do
			
			If Common.SeparatedDataUsageAvailable() Then
				
				If TypeOf(StringPredefinedData.Ref) = Type("UUID") Then
					StringPredefinedData.Ref = ObjectManager.GetRef(StringPredefinedData.Ref);
				ElsIf TypeOf(StringPredefinedData.Ref) = Type("String") Then
					StringPredefinedData.Ref = ObjectManager.GetRef(New UUID(StringPredefinedData.Ref));
				EndIf; 
				
			EndIf;
			
		EndDo;
	EndIf;
	
	Return PredefinedData;
	
EndFunction

// Parameters:
//  UpdateMultilanguageStrings - Boolean -  if True, then only multilingual details will be filled in.
//  AdditionalParameters - See NationalLanguageSupportServer.DescriptionOfOldAndNewLanguageSettings
// 
Procedure InitialFillingOfPredefinedData(UpdateMultilanguageStrings = False,
	AdditionalParameters = Undefined) Export

	FillParameters = New Structure;
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.WhenGettingParametersForFillingInPredefinedData(FillParameters);
	EndIf;
	
	CheckRequiredExecution = AdditionalParameters <> Undefined And TypeOf(AdditionalParameters) = Type(
		"Structure") And AdditionalParameters.Property("NewObjects");

	ObjectsWithInitialFilling = ObjectsWithInitialFilling();
	
	ParametersOfUpdate = InfobaseUpdate.PredefinedItemsUpdateParameters();
	ParametersOfUpdate.UpdateMultilingualStringsOnly = UpdateMultilanguageStrings;
	
	For Each ObjectWithInitialPopulation In ObjectsWithInitialFilling Do

		ObjectMetadata          = ObjectWithInitialPopulation.Key;
		FullMetadataObjectName = ObjectWithInitialPopulation.Value;
		
		If CheckRequiredExecution 
		   And AdditionalParameters.NewObjects.Find(FullMetadataObjectName) = Undefined Then
			Continue;
		EndIf;
		
		// 
		UpdateObjectPredefinedItems(ObjectMetadata,ParametersOfUpdate);

	EndDo;

	If UpdateMultilanguageStrings Then
		If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
			ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
			ModuleAccessManagementInternal.WhenChangingTheLanguageOfTheInformationBase(AdditionalParameters);
		EndIf;
	EndIf;

EndProcedure


Procedure UpdateObjectPredefinedItems(ObjectMetadata, ParametersOfUpdate) Export
	
	Context = ParameterSetForFillingObject(ObjectMetadata);
	
	ObjectManager                   = Context.ObjectManager;
	PredefinedData            = Context.PredefinedData;
	PopulationSettings               = Context.PredefinedItemsSettings;
	FullMetadataObjectName        = ObjectMetadata.FullName();
	UpdateMultilingualStringsOnly = ParametersOfUpdate.UpdateMultilingualStringsOnly;
	Items                          = ParametersOfUpdate.Items;
	AreOnlyDefinedItems        = Items.Count() > 0;
	
	DetailsToFillIn               = New Map;
	For Each DetailsToFillIn_ In StrSplit(ParametersOfUpdate.Attributes, ",", False) Do
		DetailsToFillIn.Insert(TrimAll(DetailsToFillIn_), True);
	EndDo;
	
	KeyAttributeName = PopulationSettings.OverriddenSettings.KeyAttributeName;
	
	ExistingItems = ExistingSuppliedItems(PredefinedData, PopulationSettings,
	ObjectManager, ObjectMetadata);
	
	TabularSections = New Array;
	MetadataObjectTabularSections = ObjectMetadata.TabularSections; // MetadataObjectCollection of MetadataObjectTabularSection
	For Each TabularSection In MetadataObjectTabularSections Do
		If PredefinedData.Columns.Find(TabularSection.Name) <> Undefined Then
			TabularSections.Add(TabularSection.Name);
		EndIf;
	EndDo;
	
	ExceptionAttributes = New Map;
	If StrStartsWith(FullMetadataObjectName, "ChartOfCharacteristicTypes") Then
		ExceptionAttributes.Insert("ValueType", True);
	EndIf;
	
	HierarchySupported =  PredefinedData.Columns.Find("IsFolder") <> Undefined;
	ExceptionAttributes.Insert("Parent", True); // 
	
	DetailsOfTheExceptionWithTheElements = New Map;
	If HierarchySupported Then
		CommonClientServer.SupplementMap(DetailsOfTheExceptionWithTheElements, ExceptionAttributes);
		ForItem = Metadata.ObjectProperties.AttributeUse.ForItem;
		For Each Attribute In ObjectMetadata.Attributes Do
			If Attribute.Use = ForItem Then
				DetailsOfTheExceptionWithTheElements.Insert(Attribute.Name, True);
			EndIf;
		EndDo;
	EndIf;
	
	HaveColumnLink = PredefinedData.Columns.Find("Ref") <> Undefined;
	
	BeginTransaction();
	Try
		
		For Each TableRow In PredefinedData Do
			
			ObjectReference = Undefined;
			
			If PopulationSettings.IsColumnNamePredefinedData Then
				ObjectReference = ExistingItems[TableRow.PredefinedDataName];
			EndIf;
			
			If ObjectReference = Undefined And ValueIsFilled(TableRow[KeyAttributeName]) Then
				ObjectReference = ExistingItems[TableRow[KeyAttributeName]];
			EndIf;
			
			If ObjectReference <> Undefined Then
				
				If AreOnlyDefinedItems And Items.Find(ObjectReference) = Undefined Then
					Continue;
				EndIf;
				
				DataLock = New DataLock;
				DataLockItem = DataLock.Add(FullMetadataObjectName);
				DataLockItem.SetValue("Ref", ObjectReference);
				DataLock.Lock();
				
				ItemToFill = ObjectReference.GetObject();
				
			Else
				
				If HierarchySupported And TableRow.IsFolder = True Then
					ItemToFill = ObjectManager.CreateFolder();
				Else
					ItemToFill = ObjectManager.CreateItem();
				EndIf;
				
				If HaveColumnLink And ValueIsFilled(TableRow.Ref) Then
					
					ItemToFill.SetNewObjectRef(TableRow.Ref);
					
					If ValueIsFilled(TableRow[KeyAttributeName]) Then
						ExistingItems.Insert(TableRow[KeyAttributeName], TableRow.Ref);
					EndIf;
					
				Else
					
					NewRef = ObjectManager.GetRef();
					ItemToFill.SetNewObjectRef(NewRef);
					
					If ValueIsFilled(TableRow[KeyAttributeName]) Then
						ExistingItems.Insert(TableRow[KeyAttributeName], NewRef);
					EndIf;
					
				EndIf;
				
			EndIf;
			
			EditedAttributes = EditedAttributes(ItemToFill, FullMetadataObjectName);
			
			If Not UpdateMultilingualStringsOnly Then
				
				If HierarchySupported And ValueIsFilled(TableRow.Parent) Then
					
					If KeyAttributeName = "Ref" Then
						If TypeOf(TableRow.Parent) = Type("String") Then
							ItemToFill.Parent = ObjectManager.GetRef(
							New UUID(TableRow.Parent));
						ElsIf TypeOf(TableRow.Parent) = Type("UUID") Then
							ItemToFill.Parent = ObjectManager.GetRef(TableRow.Parent);
						Else
							ItemToFill.Parent = TableRow.Parent;
						EndIf;
					ElsIf TypeOf(TableRow.Parent) = Type("String") Then
						ItemToFill.Parent = ExistingItems[TableRow.Parent];
					Else
						ItemToFill.Parent = TableRow.Parent;
					EndIf;
					
				EndIf;
				
				CurrentExceptionFields =?(HierarchySupported And ItemToFill.IsFolder,
				DetailsOfTheExceptionWithTheElements, ExceptionAttributes);
				ObjectExceptionFields = New Map(New FixedMap(CurrentExceptionFields));
				For Each EditedAttribute In EditedAttributes Do
					ObjectExceptionFields.Insert(EditedAttribute, True);
				EndDo;
				
				If ObjectReference <> Undefined Then
					FillingData = DefineTheFillingData(PredefinedData, TableRow, ObjectExceptionFields, DetailsToFillIn);
				Else
					FillingData = DefineTheFillingData(PredefinedData, TableRow, ObjectExceptionFields);
				EndIf;
				
				FillPropertyValues(ItemToFill, FillingData);
				
				If Not (HierarchySupported And ItemToFill.IsFolder) Then
					For Each TabularSectionName In TabularSections Do
						If TableRow[TabularSectionName].Count() > 0 Then
							ItemToFill[TabularSectionName].Load(TableRow[TabularSectionName]);
						EndIf;
					EndDo;
				EndIf;
				
			EndIf;
			
			If Context.ObjectAttributesToLocalize.Count() > 0
				And Context.ObjectAttributesToLocalize["Description"] <> Undefined Then
				If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
					ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
					ModuleNationalLanguageSupportServer.InitialFillingInOfPredefinedDataLocalizedBankingDetails(
					ItemToFill, TableRow, ObjectExceptionFields, Context);
				ElsIf Context.ObjectContainsPMRepresentations Then
					InitialFillingPMViews(ItemToFill, TableRow, Context);
				EndIf;
			ElsIf UpdateMultilingualStringsOnly And PredefinedData.Columns.Find("Description") <> Undefined
				And ValueIsFilled(TableRow["Description"]) Then
				ItemToFill["Description"] = TableRow["Description"];
			EndIf;
			
			If Not UpdateMultilingualStringsOnly
				And PopulationSettings.OverriddenSettings.OnInitialItemFilling Then
				
				ObjectManager.OnInitialItemFilling(ItemToFill, TableRow,
				PopulationSettings.OverriddenSettings.AdditionalParameters);
				InfobaseUpdateOverridable.OnInitialItemFilling(
				FullMetadataObjectName, ItemToFill, TableRow,
				PopulationSettings.OverriddenSettings.AdditionalParameters);
				
			EndIf;
			
			InfobaseUpdate.WriteObject(ItemToFill);
			
			TableRow.Ref = ItemToFill.Ref;
			
		EndDo;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure InitialFillingPMViews(ItemToFill, FillingData, FillParameters) Export
	
	Languages = StandardSubsystemsServer.ConfigurationLanguages();
	ObjectAttributesToLocalize = FillParameters.ObjectAttributesToLocalize;
	
	For Each LanguageCode In Languages Do
		If StrCompare(LanguageCode, Common.DefaultLanguageCode()) = 0 Then
			Continue;
		EndIf;
		
		ObjectViews = ItemToFill.Presentations; // TabularSection 
		TableRow = ObjectViews.Find(LanguageCode, "LanguageCode");
		If TableRow  = Undefined Then
			TableRow          = ObjectViews.Add();
			TableRow.LanguageCode = LanguageCode;
		EndIf;
		
		For Each NameOfAttributeToLocalize In ObjectAttributesToLocalize Do
			Value = FillingData[NameOfAttributeToLocalize.Key + "_" + LanguageCode];
			TableRow[NameOfAttributeToLocalize.Key] = ?(ValueIsFilled(Value), Value, FillingData[NameOfAttributeToLocalize.Key]);
		EndDo;
	
	EndDo;
	
EndProcedure

Function ParameterSetForFillingObject(ObjectMetadata) Export
	
	Result = New Structure;
	
	ObjectsWithInitialFilling = ObjectsWithInitialFilling();
	HavePredefinedData   =  ObjectsWithInitialFilling.Get(ObjectMetadata) <> Undefined;
	
	ObjectAttributesToLocalize = New Map;
	MultilanguageStringsInAttributes = False;
	ObjectContainsPMRepresentations  = False;
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ObjectAttributesToLocalize = ModuleNationalLanguageSupportServer.MultilingualObjectAttributes(ObjectMetadata);
		MultilanguageStringsInAttributes = ModuleNationalLanguageSupportServer.MultilanguageStringsInAttributes(ObjectMetadata);
		ObjectContainsPMRepresentations = ModuleNationalLanguageSupportServer.ObjectContainsPMRepresentations(ObjectMetadata.FullName());
	EndIf;
	
	ObjectManager = Common.ObjectManagerByFullName(ObjectMetadata.FullName());
	
	If HavePredefinedData Then
		PredefinedData = PredefinedObjectData(ObjectMetadata, ObjectManager, ObjectAttributesToLocalize);
		PredefinedItemsSettings = PredefinedItemsSettings(ObjectManager, PredefinedData);
	Else
		PredefinedData = New ValueTable();
		PredefinedItemsSettings = New Structure;
	EndIf;
	
	TabularSections = New Array;
	MetadataObjectTabularSections = ObjectMetadata.TabularSections; // MetadataObjectCollection of MetadataObjectTabularSection
	For Each TabularSection In MetadataObjectTabularSections Do
		If PredefinedData.Columns.Find(TabularSection.Name) <> Undefined Then
			TabularSections.Add(TabularSection.Name);
		EndIf;
	EndDo;
	
	ExceptionAttributes    = ?(StrStartsWith(ObjectMetadata.FullName(), "ChartOfCharacteristicTypes"), "ValueType", "");
	HierarchySupported =  PredefinedData.Columns.Find("IsFolder") <> Undefined;
	
	PMViewUsedForGroups = False; 
	If ObjectContainsPMRepresentations And HierarchySupported Then
		 
		If ObjectMetadata.TabularSections.Presentations.Use = Metadata.ObjectProperties.AttributeUse.ForFolderAndItem
			Or ObjectMetadata.TabularSections.Presentations.Use = Metadata.ObjectProperties.AttributeUse.ForFolder Then
			PMViewUsedForGroups = True;
		EndIf;
		
	EndIf;
	
	AttributesWithItems = New Array;
	If HierarchySupported Then
		ForItem = Metadata.ObjectProperties.AttributeUse.ForItem;
		For Each Attribute In ObjectMetadata.Attributes Do
			If Attribute.Use = ForItem Then
				AttributesWithItems.Add(Attribute.Name);
			EndIf;
		EndDo;
	EndIf;
	
	Result.Insert("PredefinedItemsSettings", PredefinedItemsSettings);
	Result.Insert("PredefinedData", PredefinedData);
	Result.Insert("ExceptionAttributes", ExceptionAttributes);
	Result.Insert("HierarchySupported", HierarchySupported);
	Result.Insert("TabularSections", TabularSections);
	Result.Insert("ObjectAttributesToLocalize", ObjectAttributesToLocalize);
	Result.Insert("MultilanguageStringsInAttributes", MultilanguageStringsInAttributes);
	Result.Insert("ObjectContainsPMRepresentations", ObjectContainsPMRepresentations);
	Result.Insert("PMViewUsedForGroups", PMViewUsedForGroups);
	Result.Insert("ObjectManager", ObjectManager);
	Result.Insert("AttributesWithItems", AttributesWithItems);
	
	Return Result;
	
EndFunction

// Parameters:
//  Object  - CatalogObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfAccountsObject
//          - ChartOfCalculationTypesObject
// 
Procedure DetermineModifiedAttributesInPredefinedItems(Object) Export

	ObjectsWithInitialFilling = ObjectsWithInitialFilling();
	
	MetadataObject = Object.Ref.Metadata();
	FullMetadataObjectName = ObjectsWithInitialFilling.Get(MetadataObject);

	If Not ValueIsFilled(FullMetadataObjectName) Then
		Return;
	EndIf;
	
	IsIncludesEditedPredefinedAttributes = IsIncludesEditedPredefinedAttributes(FullMetadataObjectName);
	If Not IsIncludesEditedPredefinedAttributes Then
		Return;
	EndIf;

	DatasetToFill = ParameterSetForFillingObject(
		MetadataObject);
		
	If DatasetToFill.PredefinedItemsSettings.IsColumnNamePredefinedData Then
		ValueOfKeyProps = Object["PredefinedDataName"];
	EndIf;
	
	If IsBlankString(ValueOfKeyProps) Then
		KeyAttributeName = KeyAttributeName(
			DatasetToFill.PredefinedItemsSettings);
		ValueOfKeyProps = Object[KeyAttributeName];
	Else
		KeyAttributeName = "PredefinedDataName";
	EndIf;
	
	If IsBlankString(ValueOfKeyProps) Then
		Return;
	EndIf;
	
	TableRow = DatasetToFill.PredefinedData.Find(ValueOfKeyProps,
		KeyAttributeName);
		
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	ObjectAttributes = EditableObjectAttributes(MetadataObject, KeyAttributeName);
	EditedPredefinedAttributes = StrSplit(Object.EditedPredefinedAttributes, ",",
		False);
	
	For Each TableColumn2 In DatasetToFill.PredefinedData.Columns Do
		AttributeName = TableColumn2.Name;

		If ObjectAttributes[AttributeName] = Undefined Then
			Continue;
		EndIf;

		ObjectManager = Common.ObjectManagerByFullName(FullMetadataObjectName);

		If DatasetToFill.ObjectAttributesToLocalize[AttributeName] <> Undefined Then
			
			If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
				ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
				ModuleNationalLanguageSupportServer.DetermineModifiedMultilingualItems(Object,
					TableRow, AttributeName, EditedPredefinedAttributes, DatasetToFill);
			EndIf;
			
		Else
			If AttributeName = "Parent" Then

				If KeyAttributeName = "Ref" Then
					If TypeOf(TableRow.Parent) = Type("String") Then
						AttributeValue = ObjectManager.GetRef(New UUID(TableRow.Parent));
					ElsIf TypeOf(TableRow.Parent) = Type("UUID") Then
						AttributeValue = ObjectManager.GetRef(TableRow.Parent);
					Else
						AttributeValue = TableRow.Parent;
					EndIf;
				ElsIf TypeOf(TableRow.Parent) = Type("String") Then
					
					If KeyAttributeName = "PredefinedDataName" Then
						AttributeValue = ObjectManager[TableRow.Parent];
					Else
						AttributeValue = ObjectManager.FindByAttribute(KeyAttributeName, TableRow.Parent);
					EndIf;
					
				Else
					AttributeValue = TableRow.Parent;
				EndIf;

			Else
				AttributeValue = TableRow[AttributeName];
			EndIf;
				
			If Object[AttributeName] <> AttributeValue Then
				If EditedPredefinedAttributes.Find(TableColumn2.Name) = Undefined Then
					EditedPredefinedAttributes.Add(TableColumn2.Name);
				EndIf;
			EndIf;
		
		EndIf;
		
	EndDo;
	Object.EditedPredefinedAttributes = StrConcat(EditedPredefinedAttributes, ",");
	
EndProcedure

Function IsIncludesEditedPredefinedAttributes(FullName) Export
	
	Result = False;
	If Metadata.CommonAttributes.Find("EditedPredefinedAttributes") = Undefined Then
		Return Result;
	EndIf;
	
	MetadataObject    = Metadata.FindByFullName(FullName);
	AttributeInfo = Metadata.CommonAttributes.EditedPredefinedAttributes.Content.Find(MetadataObject);

	If AttributeInfo <> Undefined Then
		If AttributeInfo.Use = Metadata.ObjectProperties.CommonAttributeUse.Use Then
			Result = True;
		ElsIf AttributeInfo.Use = Metadata.ObjectProperties.CommonAttributeUse.Auto
			And Metadata.CommonAttributes.EditedPredefinedAttributes.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use Then
			Result = True;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function CanCheckForPatchesManually() Export
	
	If Common.SubsystemExists("OnlineUserSupport")
		And Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate")
		And Not Common.DataSeparationEnabled()
		And Not Common.IsSubordinateDIBNode() Then
		ModuleOnlineUserSupport = Common.CommonModule("OnlineUserSupport");
		ModuleOnlineUserSupportClientServer = Common.CommonModule("OnlineUserSupportClientServer");
		ISLVersion = ModuleOnlineUserSupportClientServer.LibraryVersion();
		If CommonClientServer.CompareVersions(ISLVersion, "2.6.3.0") < 0
			Or Not Users.IsFullUser() Then
			Return False;
		Else
			AuthenticationData = ModuleOnlineUserSupport.OnlineSupportUserAuthenticationData();
			If AuthenticationData = Undefined Then
				Return False;
			Else
				Return True;
			EndIf;
		EndIf;
	Else
		Return False
	EndIf;
	
EndFunction

Function PatchesAvailableForInstall() Export
	Result = Undefined;
	If Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		ModuleGetApplicationUpdates = Common.CommonModule("GetApplicationUpdates");
		Result = ModuleGetApplicationUpdates.InfoAboutAvailablePatches();
		If Result <> Undefined Then
			Corrections = Result.Corrections.UnloadColumn("Description");
			Result.Insert("NumberOfCorrections", Result.Corrections.Count());
			Result.Insert("Corrections", Corrections);
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

Function DefineTheFillingData(Val PredefinedData, Val TableRow, Val ExceptionFields, Val DetailsToFillIn = Undefined)

	AreOnlyAttributesToFill = ?(TypeOf(DetailsToFillIn) = Type("Map"), DetailsToFillIn.Count() > 0, False);
	
	FillingData = New Structure;
	For Each Column In PredefinedData.Columns Do
		
		FieldName = Column.Name;
		
		If AreOnlyAttributesToFill And DetailsToFillIn[FieldName]= Undefined Then
			Continue;
		EndIf;
			
		If ExceptionFields[FieldName] = True Then
			Continue;
		EndIf;
		
		Value       = TableRow[FieldName]; 
		IsUpdateBoolean = False;
		If Column.ValueType.Types().Count() > 1 Then
			Filled = Value <> Undefined;
		ElsIf TypeOf(Value) = Type("Boolean") Then
			Filled = Value;
			IsUpdateBoolean = True;
		Else
			Filled = ValueIsFilled(Value);
		EndIf;
		
		If Filled Or IsUpdateBoolean Then
			FillingData.Insert(FieldName, Value);
		EndIf;
	EndDo;
	
	Return FillingData;
	
EndFunction

Function ActionsBeforeUpdateInfobase(ParametersOfUpdate)
	
	If Not ParametersOfUpdate.OnClientStart Then
		If Not Common.DataSeparationEnabled()
			And Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
			ModuleConfigurationUpdate = Common.CommonModule("ConfigurationUpdate");
			ModuleConfigurationUpdate.CheckObsoletePatchesExist();
		EndIf;
		
		Try
			InformationRegisters.ApplicationRuntimeParameters.ImportUpdateApplicationParameters();
		Except
			WriteError(ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Raise;
		EndTry;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Return", "");
	
	// 
	
	DataUpdateMode = DataUpdateMode();
	MetadataVersion = Metadata.Version;
	If IsBlankString(MetadataVersion) Then
		MetadataVersion = "0.0.0.0";
	EndIf;
	DataVersion = IBVersion(Metadata.Name);
	
	// 
	//
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.BeforeUpdateInfobase();
		
		// 
		// 
		If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
			SetPrivilegedMode(True);
		EndIf;
		
	EndIf;
	
	SetUpObsoleteDataPurgeJob(False);
	
	// 
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.BeforeUpdateInfobase(ParametersOfUpdate.OnClientStart, ParametersOfUpdate.Restart);
	EndIf;
	
	If Not InfobaseUpdate.InfobaseUpdateRequired() Then
		Result.Return = "NotRequired2";
		Return Result;
	EndIf;
	
	If ParametersOfUpdate.InBackground Then
		TimeConsumingOperations.ReportProgress(1);
	EndIf;
	
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	For Each SubsystemName In SubsystemsDetails.Order Do
		SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName);
		If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		Module.BeforeUpdateInfobase();
	EndDo;
	InfobaseUpdateOverridable.BeforeUpdateInfobase();
	
	// 
	If Not CanUpdateInfobase() Then
		Message = NStr("en = 'Insufficient rights to update the app.';");
		WriteError(Message);
		Raise(Message, ErrorCategory.AccessViolation);
	EndIf;
	
	If DataUpdateMode = "MigrationFromAnotherApplication" Then
		Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The configuration name changed to ""%1"".
			|Migration from another application will be performed.';"),
			Metadata.Name);
	ElsIf DataUpdateMode = "VersionUpdate" Then
		Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Configuration version was updated from ""%1"" to ""%2"".
			|Your app will be updated.';"),
			DataVersion, MetadataVersion);
	Else
		Message = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Initializing the data to version %1.';"),
		MetadataVersion);
	EndIf;
	WriteInformation(Message);
	
	// 
	LockAlreadySet = ParametersOfUpdate.IBLockSet <> Undefined 
		And ParametersOfUpdate.IBLockSet.Use;
	If LockAlreadySet Then
		UpdateIterations = UpdateIterations();
		IBLock = ParametersOfUpdate.IBLockSet;
	Else
		IBLock = Undefined;
		UpdateIterations = LockIB(IBLock, ParametersOfUpdate.ExceptionOnCannotLockIB);
		If IBLock.Error <> Undefined Then
			Result.Return = IBLock.Error;
			Return Result;
		EndIf;
	EndIf;
	
	Result.Insert("DataUpdateMode", DataUpdateMode);
	Result.Insert("UpdateIterations", UpdateIterations);
	Result.Insert("IBLock", IBLock);
	Result.Insert("LockAlreadySet", LockAlreadySet);
	Result.Insert("DataVersion", DataVersion);
	Result.Insert("MetadataVersion", MetadataVersion);
	
	Return Result;
	
EndFunction

Procedure ExecuteActionsOnUpdateInfobase(ParametersOfUpdate, AdditionalParameters)
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		// 
		// 
		If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
			SetPrivilegedMode(True);
		EndIf;
	EndIf;
	
	DataUpdateMode = AdditionalParameters.DataUpdateMode;
	UpdateIterations    = AdditionalParameters.UpdateIterations;
	IBLock          = AdditionalParameters.IBLock;
	LockAlreadySet = AdditionalParameters.LockAlreadySet;
	DeferredUpdateMode = AdditionalParameters.DeferredUpdateMode;
	ExecuteDeferredUpdateNow  = AdditionalParameters.ExecuteDeferredUpdateNow;
	
	SeamlessUpdate = IBLock.SeamlessUpdate;
	
	Try
		
		If DataUpdateMode = "MigrationFromAnotherApplication" Then
			MigrateFromAnotherApplication(UpdateIterations);
			UpdateIterations = UpdateIterations();
			
			DataUpdateMode = DataUpdateMode();
			SeamlessUpdate = False;
		EndIf;
		
	Except
		If Not LockAlreadySet Then
			UnlockIB(IBLock);
		EndIf;
		Raise;
	EndTry;
	
	InfobaseUpdateOverridable.BeforeGenerateDeferredHandlersList(UpdateIterations);
	FillInHandlerQueueNumber(UpdateIterations);
	UpdateListOfUpdateHandlersToExecute(UpdateIterations);
	ResetProgressProgressHandlers();
	ClearRegisteredProblemsWithData();
	
	If ParametersOfUpdate.InBackground Then
		TimeConsumingOperations.ReportProgress(10);
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("HandlerExecutionProgress", HandlerCountForCurrentVersion(UpdateIterations, DeferredUpdateMode));
	Parameters.Insert("SeamlessUpdate", SeamlessUpdate);
	Parameters.Insert("InBackground", ParametersOfUpdate.InBackground);
	Parameters.Insert("OnClientStart", ParametersOfUpdate.OnClientStart);
	Parameters.Insert("DeferredUpdateMode", DeferredUpdateMode);
	
	Message = NStr("en = 'The following handlers will be executed during the application update: %1';");
	Message = StringFunctionsClientServer.SubstituteParametersToString(Message, Parameters.HandlerExecutionProgress.TotalHandlerCount);
	WriteInformation(Message);
	
	Try
		
		// 
		For Each UpdateIteration In UpdateIterations Do
			UpdateIteration.CompletedHandlers = ExecuteUpdateIteration(UpdateIteration, Parameters); // 
		EndDo;
		
		// 
		UpdateInfo = InfobaseUpdateInfo();
		UpdateInfo.NewSubsystems = New Array;
		UpdateInfo.AllNewSubsystems = New Array;
		FillDataForParallelDeferredUpdate1(Parameters);
		WriteInfobaseUpdateInfo(UpdateInfo);
		
		// 
		// 
		If ExecuteDeferredUpdateNow Then
			ExecuteDeferredUpdateNow(Parameters);
		EndIf;
		
	Except
		If Not LockAlreadySet Then
			UnlockIB(IBLock);
		EndIf;
		Raise;
	EndTry;

EndProcedure

Procedure ExecuteActionsAfterUpdateInfobase(ParametersOfUpdate, AdditionalParameters)
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		// 
		// 
		If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
			SetPrivilegedMode(True);
		EndIf;
	EndIf;
	
	DataUpdateMode = AdditionalParameters.DataUpdateMode;
	UpdateIterations    = AdditionalParameters.UpdateIterations;
	IBLock          = AdditionalParameters.IBLock;
	SeamlessUpdate = AdditionalParameters.IBLock.SeamlessUpdate;
	DataVersion          = AdditionalParameters.DataVersion;
	MetadataVersion      = AdditionalParameters.MetadataVersion;
	LockAlreadySet           = AdditionalParameters.LockAlreadySet;
	DeferredUpdateMode = AdditionalParameters.DeferredUpdateMode;
	ExecuteDeferredUpdateNow  = AdditionalParameters.ExecuteDeferredUpdateNow;
	
	// 
	If Not LockAlreadySet Then
		UnlockIB(IBLock);
	EndIf;
	
	Message = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'The infobase was updated to version %1.';"), MetadataVersion);
		WriteInformation(Message);
	
	OutputUpdatesDetails = (DataUpdateMode <> "InitialFilling");
	
	RefreshReusableValues();
	
	// 
	//
	ExecuteHandlersAfterInfobaseUpdate(
		UpdateIterations,
		Constants.WriteIBUpdateDetailsToEventLog.Get(),
		OutputUpdatesDetails,
		SeamlessUpdate);
	
	InfobaseUpdateOverridable.AfterUpdateInfobase(
		DataVersion,
		MetadataVersion,
		UpdateIterations,
		OutputUpdatesDetails,
		Not SeamlessUpdate);
	
	// 
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.AfterUpdateInfobase();
	EndIf;
	
	// 
	If DeferredUpdateMode <> Undefined
		And DeferredUpdateMode = "Deferred" Then
		ScheduleDeferredUpdate();
	EndIf;
	
	If Common.DataSeparationEnabled() And Not Common.SeparatedDataUsageAvailable() Then
		ScheduledJobsServer.SetScheduledJobUsage(Metadata.ScheduledJobs.SetDeferredUpdateProcedureInSaaS, True);
	EndIf;
	
	DefineUpdateDetailsDisplay(OutputUpdatesDetails);
	
	// 
	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ModuleConfigurationUpdate = Common.CommonModule("ConfigurationUpdate");
		ModuleConfigurationUpdate.AfterUpdateInfobase();
	EndIf;
	
	RefreshReusableValues();
	
	If IsStartInfobaseUpdateSet() Then
		SetPrivilegedMode(True);
		StandardSubsystemsServer.RegisterPriorityDataChangeForSubordinateDIBNodes();
		SetPrivilegedMode(False);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.UpdateAccessAfterInfobaseUpdate(
		ExecuteDeferredUpdateNow);
	EndIf;
	
	If Not ParametersOfUpdate.OnClientStart Then
		SetInfobaseUpdateStartup(False);
		SessionParameters.IBUpdateInProgress = False;
	EndIf;
	
	If Not Common.SeparatedDataUsageAvailable() Then
		SetUpObsoleteDataPurgeJob(True);
	EndIf;
	
EndProcedure

Procedure RunActionAfterDeferredInfobaseUpdate(SyncedUpdate = False, IsScriptedUpdate = False)
	
	If Not DeferredUpdateCompleted() Then
		If IsScriptedUpdate And Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
			ModuleConfigurationUpdate = Common.CommonModule("ConfigurationUpdate");
			ShouldAbortUpdate = ModuleConfigurationUpdate.IsCurrentVersionRequiresSuccessfulHandlersCompletion();
			If ShouldAbortUpdate Then
				Raise NStr("en = 'The deferred update is completed with errors. See the event log for details.';");
			EndIf;
		EndIf;
		Return;
	EndIf;
	
EndProcedure

Procedure FillInHandlerQueueNumber(UpdateIterations)
	
	DataProcessors.UpdateHandlersDetails.FillQueueNumber(UpdateIterations);
	
	OutOfDateDataCleanupHandler = Undefined;
	MaxQueue = 0;
	For Each UpdateIteration In UpdateIterations Do
		CurCurrentQueues = UpdateIteration.Handlers.Copy(, "DeferredProcessingQueue");
		CurCurrentQueues.Sort("DeferredProcessingQueue DESC");
		If ValueIsFilled(CurCurrentQueues) Then
			CurrentQueue = CurCurrentQueues[0].DeferredProcessingQueue;
			MaxQueue = ?(MaxQueue < CurrentQueue,
				CurrentQueue, MaxQueue);
		EndIf;
		If UpdateIteration.Subsystem <> "StandardSubsystems" Then
			Continue;
		EndIf;
		OutOfDateDataCleanupHandler = UpdateIteration.Handlers.Find(
			IdOfHandlerForClearingOutdatedData(), "Id");
	EndDo;
	
	If OutOfDateDataCleanupHandler <> Undefined Then
		OutOfDateDataCleanupHandler.DeferredProcessingQueue = MaxQueue + 1;
	EndIf;
	
EndProcedure

// Returns whether to enable the use of multi-threaded updates.
// Multithreaded updating can be enabled in the update of the information base Undefined.When defining add-ons().
//
// Returns:
//  Boolean - 
//
Function MultithreadUpdateAllowed() Export
	
	Parameters = SubsystemSettings();
	Return Parameters.MultiThreadUpdate;
	
EndFunction

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(Val ParameterName, SpecifiedParameters) Export
	
	If ParameterName = "IBUpdateInProgress" Then
		SessionParameters.IBUpdateInProgress = InfobaseUpdate.InfobaseUpdateRequired();
		SpecifiedParameters.Add("IBUpdateInProgress");
	ElsIf ParameterName = "UpdateHandlerParameters" Then
		SessionParameters.UpdateHandlerParameters = New FixedStructure(NewUpdateHandlerParameters());
		SpecifiedParameters.Add("UpdateHandlerParameters");
	EndIf;
	
EndProcedure

// Returns a numeric weight version to compare versions between them.
//
// Parameters:
//  Version - String -  version in string format.
//
// Returns:
//  Number - 
//
Function VersionWeight(Val Version) Export
	
	If Version = "" Then
		Return 0;
	EndIf;
	
	If StrStartsWith(Version, "DebuggingTheHandler") Then
		Return 99000000000;
	EndIf;
	
	Return VersionWeightFromStringArray(StrSplit(Version, "."));
	
EndFunction

Function IdOfHandlerForClearingOutdatedData()
	Return New UUID("724850c1-7de4-4d18-8d99-33d0c6b46afa");
EndFunction

Function ThisIsOutOfDateDataCleanupHandler(Handler) Export
	Return Handler.Id = IdOfHandlerForClearingOutdatedData();
EndFunction

// For internal use.
//
// Parameters:
//  ConfigurationOrLibraryName - String
//  Version - String
//  Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//  IsMainConfiguration - Boolean
//                          - Undefined
// Returns:
//  Structure:
//     * PreviousVersion - String
//     * MainServerModule - String
//     * MainServerModuleName - String
//     * CompletedHandlers - Undefined
//     * Handlers - ValueTable:
//       ** InitialFilling - Boolean
//       ** Version - String
//       ** Procedure - String
//       ** ExecutionMode - String
//       ** SharedData - Boolean
//       ** HandlerManagement - Boolean
//       ** Comment - String
//       ** Id - UUID
//       ** ObjectsToLock - String
//       ** CheckProcedure - String
//       ** UpdateDataFillingProcedure - String
//       ** ExecuteInMasterNodeOnly - Boolean
//       ** RunAlsoInSubordinateDIBNodeWithFilters - Boolean
//       ** ObjectsToRead - String
//       ** ObjectsToChange - String
//       ** ExecutionPriorities - ValueTable
//       ** ExecuteInMandatoryGroup - Boolean
//       ** Priority - Number
//       ** ExclusiveMode - Undefined
//                           - Boolean
//     * IsMainConfiguration - Boolean
//                               - Undefined
//
Function UpdateIteration(ConfigurationOrLibraryName, Version, Handlers, IsMainConfiguration = Undefined) Export
	
	UpdateIteration = New Structure;
	UpdateIteration.Insert("Subsystem",  ConfigurationOrLibraryName);
	UpdateIteration.Insert("Version",      Version);
	UpdateIteration.Insert("IsMainConfiguration", 
		?(IsMainConfiguration <> Undefined, IsMainConfiguration, ConfigurationOrLibraryName = Metadata.Name));
	UpdateIteration.Insert("Handlers", Handlers);
	UpdateIteration.Insert("CompletedHandlers", Undefined);
	UpdateIteration.Insert("MainServerModuleName", "");
	UpdateIteration.Insert("MainServerModule", "");
	UpdateIteration.Insert("PreviousVersion", "");
	Return UpdateIteration;
	
EndFunction

// Check the current user's rights to perform database updates.
Function CanUpdateInfobase(ForPrivilegedMode = True,
			SeparatedData = Undefined, SimplifiedInfobaseUpdateForm = False)
	
	CheckSystemAdministrationRights = True;
	
	If SeparatedData = Undefined Then
		SeparatedData = Not Common.DataSeparationEnabled()
			Or Common.SeparatedDataUsageAvailable();
	EndIf;
	
	If Common.DataSeparationEnabled()
	   And SeparatedData Then
		
		If Not Common.SeparatedDataUsageAvailable() Then
			Return False;
		EndIf;
		CheckSystemAdministrationRights = False;
	EndIf;
	
	HasRights = Users.IsFullUser(
		, CheckSystemAdministrationRights, ForPrivilegedMode);
	
	If HasRights Then
		Return True;
	EndIf;
	
	If Not CheckSystemAdministrationRights Then
		SimplifiedInfobaseUpdateForm = True;
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// For internal use.
//
Function UpdateInfobaseInBackground(FormUniqueID, IBLock) Export
	
	// 
	IBUpdateParameters = New Structure;
	IBUpdateParameters.Insert("ExceptionOnCannotLockIB", False);
	IBUpdateParameters.Insert("IBLock", IBLock);
	IBUpdateParameters.Insert("ClientParametersAtServer", StandardSubsystemsServer.ClientParametersAtServer());
	
	// 
	Try
		LockIB(IBUpdateParameters.IBLock, False);
	Except
		ErrorInfo = ErrorInfo();
		
		Result = New Structure;
		Result.Insert("Status",    "Error");
		Result.Insert("IBLock", IBUpdateParameters.IBLock);
		Result.Insert("BriefErrorDescription", ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Result.Insert("DetailErrorDescription", ErrorProcessing.DetailErrorDescription(ErrorInfo));
		Result.Insert("ErrorInfo", ErrorInfo);
		
		Return Result;
	EndTry;
	
	IBUpdateParameters.Insert("InBackground", Not IBUpdateParameters.IBLock.DebugMode);
	
	If Not IBUpdateParameters.InBackground Then
		IBUpdateParameters.Delete("ClientParametersAtServer");
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormUniqueID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Update infobase in background';");
	// 
	// 
	// 
	ExecutionParameters.RunInBackground = True;
	
	Result = TimeConsumingOperations.ExecuteInBackground("InfobaseUpdateInternal.RunInfobaseUpdateInBackground",
		IBUpdateParameters, ExecutionParameters);
	
	Result.Insert("IBLock", IBUpdateParameters.IBLock);
	
	// 
	If Result.Status <> "Running" Then
		UnlockIB(IBUpdateParameters.IBLock);
	EndIf;
	
	Return Result;
	
EndFunction

// Starts updating the information base in a long operation.
Procedure RunInfobaseUpdateInBackground(IBUpdateParameters, StorageAddress) Export
	
	ErrorInfo = Undefined;
	Try
		ParametersOfUpdate = ParametersOfUpdate();
		ParametersOfUpdate.ExceptionOnCannotLockIB = IBUpdateParameters.ExceptionOnCannotLockIB;
		ParametersOfUpdate.OnClientStart = True;
		ParametersOfUpdate.Restart = False;
		ParametersOfUpdate.IBLockSet = IBUpdateParameters.IBLock;
		ParametersOfUpdate.InBackground = IBUpdateParameters.InBackground;
		
		Result = UpdateInfobase(ParametersOfUpdate);
	Except
		ErrorInfo = ErrorInfo();
		// 
		// 
		If Common.SubsystemExists("StandardSubsystems.DataExchange")
		   And Common.IsSubordinateDIBNode() Then
			ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
			ModuleDataExchangeServer.EnableDataExchangeMessageImportRecurrenceBeforeStart();
		EndIf;
	EndTry;
	
	If ErrorInfo <> Undefined Then
		UpdateResult = New Structure;
		UpdateResult.Insert("ErrorInfo", ErrorInfo);
	ElsIf Not IBUpdateParameters.InBackground Then
		UpdateResult = Result;
	Else
		UpdateResult = New Structure;
		UpdateResult.Insert("Result", Result);
	EndIf;
	PutToTempStorage(UpdateResult, StorageAddress);
	
EndProcedure

Function UpdateUnderRestrictedRights(IBLock) Export
	If Not Common.DataSeparationEnabled()
		Or Not Common.SeparatedDataUsageAvailable() Then
		Return False;
	EndIf;
	
	ParametersOfUpdate = ParametersOfUpdate();
	ParametersOfUpdate.ExceptionOnCannotLockIB = False;
	ParametersOfUpdate.IBLockSet = IBLock;
	
	Result = "";
	// 
	Try
		SetPrivilegedMode(True);
		Result = UpdateInfobase(ParametersOfUpdate);
		SetPrivilegedMode(False);
	Except
		// 
	EndTry;
	// 
	
	Return (Result = "Success" Or Result = "NotRequired2");
EndFunction

// For internal use.
//
Function LockIB(IBLock, ExceptionOnCannotLockIB) Export
	
	UpdateIterations = Undefined;
	If IBLock = Undefined Then
		IBLock = IBLock();
	EndIf;
	
	IBLock.Use = True;
	If Common.DataSeparationEnabled() Then
		IBLock.DebugMode = False;
	Else
		IBLock.DebugMode = Common.DebugMode();
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		IBLock.RecordKey = ModuleInfobaseUpdateInternalSaaS.LockDataAreaVersions();
	EndIf;
	
	UpdateIterations = UpdateIterations();
	IBLock.SeamlessUpdate = False;
	
	If IBLock.DebugMode Then
		Return UpdateIterations;
	EndIf;
	
	// 
	ErrorInfo = Undefined;
	Try
		If Not ExclusiveMode() Then
			SetExclusiveMode(True);
		EndIf;
		Return UpdateIterations;
	Except
		If CanExecuteSeamlessUpdate(UpdateIterations) Then
			IBLock.SeamlessUpdate = True;
			Return UpdateIterations;
		EndIf;
		ErrorInfo = ErrorInfo();
	EndTry;
	
	// 
	Message = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Cannot update the infobase:
			|- Cannot switch to exclusive mode.
			|- The configuration version does not support update in nonexclusive mode.
			|
			|Error details:
			|%1';"),
		ErrorProcessing.BriefErrorDescription(ErrorInfo));
	
	WriteError(Message);
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.UnlockDataAreaVersions(IBLock.RecordKey);
	EndIf;
	
	If Not ExceptionOnCannotLockIB
	   And Common.FileInfobase()
	   And Common.SubsystemExists("StandardSubsystems.UsersSessions") Then
		
		ClientLaunchParameter = StandardSubsystemsServer.ClientParametersAtServer().Get("LaunchParameter");
		If StrFind(ClientLaunchParameter, "ScheduledJobsDisabled2") = 0 Then
			IBLock.Error = "LockScheduledJobsExecution";
		Else
			IBLock.Error = "ExclusiveModeSettingError";
		EndIf;
	EndIf;
	
	Raise Message;
	
EndFunction

// For internal use.
//
Procedure UnlockIB(IBLock) Export
	
	If IBLock.DebugMode Then
		Return;
	EndIf;
		
	If ExclusiveMode() Then
		While TransactionActive() Do
			RollbackTransaction(); // 
		EndDo;
		
		SetExclusiveMode(False);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.UnlockDataAreaVersions(IBLock.RecordKey);
	EndIf;
	
EndProcedure

// For internal use.
//
Function IBLock()
	
	Result = New Structure;
	Result.Insert("Use", False);
	Result.Insert("Error", Undefined);
	Result.Insert("SeamlessUpdate", Undefined);
	Result.Insert("RecordKey", Undefined);
	Result.Insert("DebugMode", Undefined);
	Return Result;
	
EndFunction

// For internal use.
//
Function ParametersOfUpdate() Export
	
	Result = New Structure;
	Result.Insert("ExceptionOnCannotLockIB", True);
	Result.Insert("OnClientStart", False);
	Result.Insert("Restart", False);
	Result.Insert("IBLockSet", Undefined);
	Result.Insert("InBackground", False);
	Result.Insert("ExecuteDeferredHandlers1", False);
	Return Result;
	
EndFunction

// For internal use.
//
Function NewApplicationMigrationHandlerTable()
	
	Handlers = New ValueTable;
	Handlers.Columns.Add("PreviousConfigurationName", New TypeDescription("String", New StringQualifiers(0)));
	Handlers.Columns.Add("Procedure",                 New TypeDescription("String", New StringQualifiers(0)));
	Handlers.Columns.Add("SharedData",               New TypeDescription("Boolean"));
	Return Handlers;
	
EndFunction

// For internal use.
//
Function ApplicationMigrationHandlers(PreviousConfigurationName, UpdateIterations) 
	
	MigrationHandlers = NewApplicationMigrationHandlerTable();
	BaseConfigurationName = Metadata.Name;
	
	// 
	MigrationHandlers = NewApplicationMigrationHandlerTable();
	BaseConfigurationName = Metadata.Name;
	
	SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails();
	ConfigurationSubsystems = SubsystemsDetails.ByNames;
	AllNewSubsystems = InfobaseUpdateInfo().AllNewSubsystems;
	
	// 
	TransitionHandler = MigrationHandlers.Add();
	TransitionHandler.PreviousConfigurationName = "*";
	TransitionHandler.SharedData = False;
	TransitionHandler.Procedure   = InitialFillHandlerPredefined();
	
	NewMetadataObjects = New Array;
	For Each Subsystem In AllNewSubsystems Do
		MetadataObject = Common.MetadataObjectByFullName(Subsystem);
		If MetadataObject = Undefined Then
			Continue;
		EndIf;
		
		If MetadataObject.IncludeInCommandInterface Then
			Continue;
		EndIf;
		
		For Each SubsystemObject In MetadataObject.Content Do
			NewMetadataObjects.Add(SubsystemObject.FullName());
		EndDo;
	EndDo;
	
	For Each UpdateIteration In UpdateIterations Do
		
		SubsystemDetails = ConfigurationSubsystems.Get(UpdateIteration.Subsystem);
		If Not SubsystemDetails.FillDataNewSubsystemsWhenSwitchingFromAnotherProgram Then
			Continue;
		EndIf;
		
		Filter = New Structure;
		Filter.Insert("InitialFilling", True);
		
		InitialFillHandlers = UpdateIteration.Handlers.FindRows(Filter);
		For Each Handler In InitialFillHandlers Do
			If Handler.ExecutionMode = "Deferred"
				Or Handler.DoNotExecuteWhenSwitchingFromAnotherProgram Then
				Continue;
			EndIf;
			
			Position      = StrFind(Handler.Procedure, ".", SearchDirection.FromEnd);
			ManagerName = Left(Handler.Procedure, Position - 1);
			FullObjectName = MetadataObjectNameByManagerName(ManagerName);
			
			If NewMetadataObjects.Find(FullObjectName) <> Undefined Then
				TransitionHandler = MigrationHandlers.Add();
				TransitionHandler.PreviousConfigurationName = "*";
				TransitionHandler.SharedData = Handler.SharedData;
				TransitionHandler.Procedure   = Handler.Procedure;
			EndIf;
		EndDo;
	EndDo;
	
	// 
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	For Each SubsystemName In SubsystemsDetails.Order Do
		SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName); // See StandardSubsystemsCached.NewSubsystemDescription
		If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		
		If SubsystemDetails.Name <> BaseConfigurationName Then
			Continue;
		EndIf;
		
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		Module.OnAddApplicationMigrationHandlers(MigrationHandlers);
	EndDo;
	// 
	InfobaseUpdateSSL.OnAddApplicationMigrationHandlers(MigrationHandlers);
	
	Filter = New Structure("PreviousConfigurationName", "*");
	If Common.DataSeparationEnabled() Then
		Filter.Insert("SharedData", Not Common.SeparatedDataUsageAvailable());
	EndIf;
	SelectedHandlers = MigrationHandlers.FindRows(Filter);
	
	Filter.PreviousConfigurationName = PreviousConfigurationName;
	CommonClientServer.SupplementArray(SelectedHandlers, MigrationHandlers.FindRows(Filter), True);
	
	Result = New Structure;
	Result.Insert("Handlers", SelectedHandlers);
	Result.Insert("NewObjects", NewMetadataObjects);
	
	Return Result;
	
EndFunction

Procedure MigrateFromAnotherApplication(UpdateIterations)
	
	IsUnsharedSession = Not Common.DataSeparationEnabled()
		Or Not Common.SeparatedDataUsageAvailable();
	
	ModuleInfobaseUpdateInternalSaaS = Undefined;
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
	EndIf;
	
	// 
	If IsUnsharedSession Then
		Query = New Query;
		Query.Text = 
		"SELECT TOP 1
		|	SubsystemsVersions.SubsystemName AS SubsystemName,
		|	SubsystemsVersions.Version AS Version
		|FROM
		|	InformationRegister.SubsystemsVersions AS SubsystemsVersions
		|WHERE
		|	SubsystemsVersions.IsMainConfiguration = TRUE";
		// 
		// 
		QueryResult = Query.Execute();
		// 
	ElsIf ModuleInfobaseUpdateInternalSaaS = Undefined Then
		// 
		Return;
	Else
		QueryResult = ModuleInfobaseUpdateInternalSaaS.MainConfigurationInDataArea();
	EndIf;
	// 
	If QueryResult.IsEmpty() Then 
		Return;
	EndIf;
	
	QueryResult = QueryResult.Unload()[0];
	PreviousConfigurationName = QueryResult.SubsystemName;
	PreviousConfigurationVersion = QueryResult.Version;
	
	// 
	If Not Common.SeparatedDataUsageAvailable() Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.FillTagThisMainConfig(PreviousConfigurationName);
	Else
		SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails();
		DescriptionPreviousSubsystem = SubsystemsDetails.ByNames.Get(PreviousConfigurationName);
		If DescriptionPreviousSubsystem = Undefined Then
			// 
			Query = New Query;
			Query.SetParameter("LibraryName", PreviousConfigurationName);
			Query.SetParameter("Status", Enums.UpdateHandlersStatuses.Completed);
			Query.Text =
				"SELECT
				|	UpdateHandlers.HandlerName AS HandlerName
				|FROM
				|	InformationRegister.UpdateHandlers AS UpdateHandlers
				|WHERE
				|	UpdateHandlers.LibraryName = &LibraryName
				|	AND UpdateHandlers.Status <> &Status";
			Result = Query.Execute().Unload();
			For Each TableRow In Result Do
				RecordSet = InformationRegisters.UpdateHandlers.CreateRecordSet();
				RecordSet.Filter.HandlerName.Set(TableRow.HandlerName);
				RecordSet.Read();
				
				RecordSet[0].LibraryName = Metadata.Name;
				
				RecordSet.Write(); // 
			EndDo;
		EndIf;
	EndIf;
	
	HandlersNewObjects = ApplicationMigrationHandlers(PreviousConfigurationName, UpdateIterations);
	Handlers  = HandlersNewObjects.Handlers;
	NewObjects = HandlersNewObjects.NewObjects;
	
	SubsystemExists = Common.SubsystemExists("StandardSubsystems.AccessManagement");
	// 
	For Each Handler In Handlers Do
		
		TransactionActiveAtExecutionStartTime = TransactionActive();
		DisableAccessKeysUpdate(True, SubsystemExists);
		Try
			// 
			If Handler.Procedure = InitialFillHandlerPredefined() Then
				HandlerParameters = New Array;
				HandlerParameters.Add(False);
				HandlerParameters.Add(New Structure("NewObjects", NewObjects));
				Common.ExecuteConfigurationMethod(Handler.Procedure, HandlerParameters);
			Else
				// 
				Common.ExecuteConfigurationMethod(Handler.Procedure);
			EndIf;
			DisableAccessKeysUpdate(False, SubsystemExists);
		Except
			
			DisableAccessKeysUpdate(False, SubsystemExists);
			HandlerName = Handler.Procedure;
			WriteError(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Error while calling the handler of migration from another application
				           |%1:
				           |%2
				           |';"),
				HandlerName,
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
			
			Raise;
		EndTry;
		ValidateNestedTransaction(TransactionActiveAtExecutionStartTime, Handler.Procedure);
		
	EndDo;
	
	Parameters = New Structure();
	Parameters.Insert("ExecuteUpdateFromVersion", True);
	Parameters.Insert("ConfigurationVersion", Metadata.Version);
	Parameters.Insert("ClearPreviousConfigurationInfo", True);
	OnCompleteApplicationMigration(PreviousConfigurationName, PreviousConfigurationVersion, Parameters);
	
	// 
	BeginTransaction();
	Try
		If Parameters.ClearPreviousConfigurationInfo Then
			If IsUnsharedSession Then
				RecordSet = InformationRegisters.SubsystemsVersions.CreateRecordSet();
			Else
				RecordSet = ModuleInfobaseUpdateInternalSaaS.WriteSubsystemVersionsDataRegions();
			EndIf;
			RecordSet.Filter.SubsystemName.Set(PreviousConfigurationName);
			RecordSet.Write();
		EndIf;
		
		If IsUnsharedSession Then
			RecordSet = InformationRegisters.SubsystemsVersions.CreateRecordSet();
		Else
			RecordSet = ModuleInfobaseUpdateInternalSaaS.WriteSubsystemVersionsDataRegions();
		EndIf;
		RecordSet.Filter.SubsystemName.Set(Metadata.Name);
		
		ConfigurationVersion = Metadata.Version; 
		If Parameters.ExecuteUpdateFromVersion Then
			ConfigurationVersion = Parameters.ConfigurationVersion;
		EndIf;
		NewRecord = RecordSet.Add();
		NewRecord.SubsystemName = Metadata.Name;
		NewRecord.Version = ConfigurationVersion;
		If IsUnsharedSession Then
			NewRecord.UpdatePlan = Undefined;
		EndIf;
		NewRecord.IsMainConfiguration = True;
		
		RecordSet.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	RefreshReusableValues();
	
EndProcedure

Function InitialFillHandlerPredefined()
	
	Return "InfobaseUpdateInternal.InitialFillingOfPredefinedData";
	
EndFunction

Procedure OnCompleteApplicationMigration(PreviousConfigurationName, PreviousConfigurationVersion, Parameters)
	
	ConfigurationName = Metadata.Name;
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	For Each SubsystemName In SubsystemsDetails.Order Do
		SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName); // See StandardSubsystemsCached.NewSubsystemDescription
		If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		
		If SubsystemDetails.Name <> ConfigurationName Then
			Continue;
		EndIf;
		
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		Module.OnCompleteApplicationMigration(PreviousConfigurationName, PreviousConfigurationVersion, Parameters);
	EndDo;
	
EndProcedure

Procedure IBVersionUpdateBeforeDeleteRefObject(Source, Cancel) Export
	// 
	// 
	
	If GetFunctionalOption("DeferredUpdateCompletedSuccessfully")
		Or Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	If Metadata.ExchangePlans.InfobaseUpdate.Content.Find(Source.Metadata()) = Undefined Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	InfobaseUpdate.Ref AS Ref
		|FROM
		|	ExchangePlan.InfobaseUpdate AS InfobaseUpdate
		|WHERE
		|	InfobaseUpdate.ThisNode = FALSE";
	
	SetPrivilegedMode(True);
	Nodes = Query.Execute().Unload().UnloadColumn("Ref");
	ExchangePlans.DeleteChangeRecords(Nodes, Source);
EndProcedure

Procedure OrderHandlersVersions(HandlersByVersion)
	HandlersByVersion.Columns.Add("VersionOrder", New TypeDescription("Number"));
	For Each VersionRow In HandlersByVersion.Rows Do
		Version = VersionRow.Version;
		If Version = "*" Or Not ValueIsFilled(Version) Then
			VersionRow.VersionOrder = 0;
		ElsIf StrStartsWith(Version, "DebuggingTheHandler") Then
			VersionRow.VersionOrder = 99000000000;
		Else
			VersionRow.VersionOrder = VersionWeightFromStringArray(StrSplit(Version, "."));
		EndIf;
	EndDo;
	
	HandlersByVersion.Rows.Sort("VersionOrder Asc");
EndProcedure

Procedure AddHandlers(LibraryName, HandlersByVersion, AddedHandlers)
	
	If Common.SeparatedDataUsageAvailable() Then
		SeparatedHandlersSet   = InformationRegisters.UpdateHandlers.CreateRecordSet();
		SeparatedHandlersSet.Read();
	EndIf;
	If Not Common.DataSeparationEnabled() Or Not Common.SeparatedDataUsageAvailable() Then
		SharedHandlersSet = InformationRegisters.SharedDataUpdateHandlers.CreateRecordSet();
		SharedHandlersSet.Read();
	EndIf;
	
	For Each Version In HandlersByVersion Do
		For Each Handler In Version.Rows Do
			If AddedHandlers.Find(Handler.HandlerName) <> Undefined Then
				Continue;
			EndIf;
			
			If Handler.SharedData = True Then
				Record = SharedHandlersSet.Add();
			Else
				Record = SeparatedHandlersSet.Add();
			EndIf;
			
			FillPropertyValues(Record, Handler, , "ExecutionMode");
			
			If Not ValueIsFilled(Handler.ExecutionMode)
				And (Handler.ExclusiveMode = True Or Handler.ExclusiveMode = Undefined) Then
				ExecutionMode = Enums.HandlersExecutionModes.Exclusively;
			ElsIf Not ValueIsFilled(Handler.ExecutionMode) And Handler.ExclusiveMode = False Then
				ExecutionMode = Enums.HandlersExecutionModes.Seamless;
			Else
				ExecutionMode = Enums.HandlersExecutionModes[Handler.ExecutionMode];
			EndIf;
			
			Record.ExecutionMode = ExecutionMode;
			Record.Status = Enums.UpdateHandlersStatuses.NotPerformed;
			Record.LibraryName = LibraryName;
			
			AddedHandlers.Add(Handler.HandlerName);
		EndDo;
	EndDo;
	
	// 
	If Common.SeparatedDataUsageAvailable() Then
		SeparatedHandlersSet.Write();
	EndIf;
	If Not Common.DataSeparationEnabled() Or Not Common.SeparatedDataUsageAvailable() Then
		SharedHandlersSet.Write();
	EndIf;
	// 
	
EndProcedure

Procedure SetHandlerStatus(HandlerName, Status, ErrorText = "")
	
	RecordSet = Undefined;
	If Common.SeparatedDataUsageAvailable() Then
		RecordSet = InformationRegisters.UpdateHandlers.CreateRecordSet();
		RecordSet.Filter.HandlerName.Set(HandlerName);
		RecordSet.Read();
	EndIf;
	
	CanReadSharedData = Not Common.DataSeparationEnabled()
		Or Not Common.SeparatedDataUsageAvailable();
	
	If CanReadSharedData And (RecordSet = Undefined Or RecordSet.Count() = 0) Then
		RecordSet = InformationRegisters.SharedDataUpdateHandlers.CreateRecordSet();
		RecordSet.Filter.HandlerName.Set(HandlerName);
		RecordSet.Read();
	EndIf;
	
	If RecordSet.Count() = 0 Then
		Return;
	EndIf;
	
	Record = RecordSet[0];
	Record.Status = Enums.UpdateHandlersStatuses[Status];
	Record.ErrorInfo = ErrorText;
	
	RecordSet.Write();
	
EndProcedure

Procedure HandlerProperty(HandlerName, Property, Value) Export
	
	Properties = New Structure;
	Properties.Insert(Property, Value);
	SetHandlerProperties(HandlerName, Properties);
	
EndProcedure

Procedure SetHandlerProperties(HandlerName, Properties)
	
	If Properties.Count() = 0 Then
		Return;
	EndIf;
	
	RecordSet = Undefined;
	If Common.SeparatedDataUsageAvailable() Then
		RecordSet = InformationRegisters.UpdateHandlers.CreateRecordSet();
		RecordSet.Filter.HandlerName.Set(HandlerName);
		RecordSet.Read();
	EndIf;
	
	CanReadSharedData = Not Common.DataSeparationEnabled()
		Or Not Common.SeparatedDataUsageAvailable();
	
	If CanReadSharedData And (RecordSet = Undefined Or RecordSet.Count() = 0) Then
		RecordSet = InformationRegisters.SharedDataUpdateHandlers.CreateRecordSet();
		RecordSet.Filter.HandlerName.Set(HandlerName);
		RecordSet.Read();
	EndIf;
	
	If RecordSet.Count() = 0 Then
		Return;
	EndIf;
	
	Record = RecordSet[0];
	For Each Property In Properties Do
		Record[Property.Key] = Property.Value;
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Returns a string constant for generating log messages.
//
// Returns:
//   String
//
Function EventLogEvent() Export
	
	Return NStr("en = 'Infobase update';", Common.DefaultLanguageCode());
	
EndFunction

// Returns a string constant for generating log messages
// for logging the progress of update handlers.
//
// Returns:
//   String
//
Function EventLogEventProtocol() Export
	
	Return EventLogEvent() + "." + NStr("en = 'Execution log';", Common.DefaultLanguageCode());
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Generates a tabular document with a description of changes in versions
// that correspond to the passed list of versions of the Sections.
//
Function DocumentUpdatesDetails(Val Sections) Export
	
	DocumentUpdatesDetails = New SpreadsheetDocument();
	If Sections.Count() = 0 Then
		Return DocumentUpdatesDetails;
	EndIf;
	
	UpdateDetailsTemplate = Metadata.CommonTemplates.Find("SystemReleaseNotes");
	If UpdateDetailsTemplate <> Undefined Then
		UpdateDetailsTemplate = GetCommonTemplate(UpdateDetailsTemplate);
	Else
		Return New SpreadsheetDocument();
	EndIf;
	
	For Each Version In Sections Do
		
		OutputUpdateDetails(Version, DocumentUpdatesDetails, UpdateDetailsTemplate);
		
	EndDo;
	
	Return DocumentUpdatesDetails;
	
EndFunction

// Returns an array of versions larger than the last displayed version
// that have descriptions of system changes.
//
// Returns:
//  Array - 
//
Function NotShownUpdateDetailSections() Export
	
	Sections = UpdateDetailsSections();
	
	LatestVersion1 = SystemChangesDisplayLastVersion();
	
	If LatestVersion1 = Undefined Then
		Return New Array;
	EndIf;
	
	Return GetLaterVersions(Sections, LatestVersion1);
	
EndFunction

// Sets the flag for displaying descriptions of version changes to the
// current version inclusive.
//
// Parameters:
//  UserName - String -  the name of the user for which
//   you need to set the flag.
//
Procedure SetShowDetailsToCurrentVersionFlag(Val UserName = Undefined) Export
	
	Common.CommonSettingsStorageSave("IBUpdate",
		"SystemChangesDisplayLastVersion", Metadata.Version, , UserName);
		
	If UserName = Undefined And Users.IsFullUser() Then
		
		Common.CommonSettingsStorageDelete("IBUpdate", "OutputUpdateDetailsForAdministrator", UserName());
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Schedules a deferred update in the client-server database.
//
Procedure ScheduleDeferredUpdate()
	
	// 
	// 
	If Not Common.FileInfobase() Then
		OnEnableDeferredUpdate(True);
	EndIf;
	
EndProcedure

// Manages the execution of deferred update handlers.
// 
Procedure ExecuteDeferredUpdate() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DeferredIBUpdate);
	
	If InfobaseUpdateInternalCached.InfobaseUpdateRequired() Then
		Return;
	EndIf;
	
	UpdateInfo = InfobaseUpdateInfo();
	
	If UpdateInfo.DeferredUpdatesEndTime <> Undefined Then
		CancelDeferredUpdate();
		RunActionAfterDeferredInfobaseUpdate();
		Return;
	EndIf;
	
	If UpdateInfo.DeferredUpdateStartTime = Undefined Then
		UpdateInfo.DeferredUpdateStartTime = CurrentSessionDate();
	EndIf;
	If TypeOf(UpdateInfo.SessionNumber) <> Type("ValueList") Then
		UpdateInfo.SessionNumber = New ValueList;
	EndIf;
	UpdateInfo.SessionNumber.Add(InfoBaseSessionNumber());
	UpdateInfo.UpdateSessionStartDate = CurrentSessionDate();
	WriteInfobaseUpdateInfo(UpdateInfo);
	
	// 
	If Common.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		ModulePeriodClosingDates = Common.CommonModule("PeriodClosingDates");
		ModulePeriodClosingDates.DisablePeriodEndClosingDatesCheck(True);
	EndIf;
	
	HandlersExecutedEarlier = True;
	ProcessedItems = New Array;
	
	LastCheckDate = Undefined;
	Try
		If ForceUpdate(UpdateInfo) Then
			Groups = NewDetailsOfDeferredUpdateHandlersThreadsGroups();
			CancelAllThreadsExecution(Groups);
			
			While HandlersExecutedEarlier Do
				Stream = AddDeferredUpdateHandlerThread(UpdateInfo); // 
				
				QueuesToClear = QueuesToClear(ProcessedItems); // 
				ClearProcessedQueues(QueuesToClear, ProcessedItems, UpdateInfo);
				
				If TypeOf(Stream) = Type("ValueTableRow") Then
					ExecuteThread(Groups, Stream);
					WaitForAvailableThread(Groups); // 
				ElsIf Stream = True Then
					WaitForAnyThreadCompletion(Groups); // 
				ElsIf Stream = False Then
					HandlersExecutedEarlier = False;
					WaitForAllThreadsCompletion(Groups); // 
					Break;
				ElsIf Stream = "AbortExecution" Then
					WaitForAllThreadsCompletion(Groups); // 
					Break;
				EndIf;
				
				If LastCheckDate = Undefined
					Or CurrentSessionDate() - LastCheckDate > 600 Then
					LastCheckDate = CurrentSessionDate();
					ClearProcessingProgressForPreviousDayIntervals(); // 
				EndIf;
				
				Job = ScheduledJobsServer.Job(Metadata.ScheduledJobs.DeferredIBUpdate);
				ExecutionRequired = Job.Schedule.ExecutionRequired(CurrentSessionDate());
				
				If Not ExecutionRequired Or Not ForceUpdate(UpdateInfo) Then
					WaitForAllThreadsCompletion(Groups); // 
					DeleteAllUpdateThreads();
					Break;
				EndIf;
				
			EndDo;
		Else
			ClearProcessingProgressForPreviousDayIntervals();
			HandlersExecutedEarlier = ExecuteDeferredUpdateHandler();
		EndIf;
	Except
		WriteError(ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		CancelAllThreadsExecution(Groups);
		DeleteAllUpdateThreads();
	EndTry;
	
	UpdateInfo = InfobaseUpdateInfo();
	If Not HandlersExecutedEarlier Or AllDeferredHandlersCompleted(UpdateInfo) Then
		DeleteAllUpdateThreads();
		CancelDeferredUpdate();
		ClearHandlersLaunchTransactions();
		RunActionAfterDeferredInfobaseUpdate();
	EndIf;
	
EndProcedure

Procedure ClearHandlersLaunchTransactions()
	
	RecordSet = InformationRegisters.CommitDataProcessedByHandlers.CreateRecordSet();
	RecordSet.Write();
	
EndProcedure

Procedure ClearProcessingProgressForPreviousDayIntervals()
	
	Query = New Query;
	Query.SetParameter("IntervalHour", BegOfDay(CurrentSessionDate()));
	Query.Text = 
		"SELECT
		|	UpdateProgress.HandlerName AS HandlerName,
		|	UpdateProgress.IntervalHour AS IntervalHour,
		|	UpdateProgress.RecordKey AS RecordKey
		|FROM
		|	InformationRegister.UpdateProgress AS UpdateProgress
		|WHERE
		|	UpdateProgress.IntervalHour < &IntervalHour";
	Result = Query.Execute().Unload();
	
	For Each TableRow In Result Do
		RecordManager = InformationRegisters.UpdateProgress.CreateRecordManager();
		RecordManager.HandlerName = TableRow.HandlerName;
		RecordManager.IntervalHour = TableRow.IntervalHour;
		RecordManager.RecordKey = TableRow.RecordKey;
		RecordManager.Delete();
	EndDo;
	
EndProcedure

Function HandlersForDeferredDataRegistration(NoFilter1 = False, UpdateRestart = False, RegisteredHandlers = Undefined) Export
	
	If RegisteredHandlers = Undefined Then
		RegisteredHandlers = New Array;
	EndIf;
	
	IsSubordinateDIBNodeWithFilter = Common.IsSubordinateDIBNodeWithFilter();
	
	Query = New Query;
	Query.SetParameter("HandlerExecutionMode", Enums.DeferredHandlersExecutionModes.Parallel);
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.SetParameter("NoFilter1", NoFilter1);
	Query.SetParameter("IsSubordinateDIBNodeWithFilter", IsSubordinateDIBNodeWithFilter);
	// 
	Query.SetParameter("ProcessorStatus", Enums.UpdateHandlersStatuses.Completed);
	Query.SetParameter("RegisteredHandlers", RegisteredHandlers);
	Query.SetParameter("ClearFilter", (Not UpdateRestart Or RegisteredHandlers.Count() = 0));
	Query.Text =
		"SELECT
		|	UpdateHandlers.HandlerName AS HandlerName,
		|	UpdateHandlers.LibraryName AS LibraryName,
		|	UpdateHandlers.Version AS Version,
		|	UpdateHandlers.UpdateDataFillingProcedure AS UpdateDataFillingProcedure,
		|	UpdateHandlers.DeferredProcessingQueue AS DeferredProcessingQueue,
		|	UpdateHandlers.Multithreaded AS Multithreaded,
		|	UpdateHandlers.DataToProcess AS DataToProcess,
		|	UpdateHandlers.Status AS Status
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode
		|	AND (UpdateHandlers.DeferredHandlerExecutionMode = &HandlerExecutionMode
		|			OR &NoFilter1)
		|	AND (UpdateHandlers.Status <> &ProcessorStatus
		|			OR UpdateHandlers.HandlerName IN(&RegisteredHandlers)
		|			OR &ClearFilter)
		|	AND (&IsSubordinateDIBNodeWithFilter
		|		AND UpdateHandlers.RunAlsoInSubordinateDIBNodeWithFilters
		|		OR NOT &IsSubordinateDIBNodeWithFilter)
		|
		|ORDER BY
		|	UpdateHandlers.DeferredProcessingQueue";
	Handlers = Query.Execute().Unload();
	
	Return Handlers;
	
EndFunction

Function FindUpdateHandler(HandlerContext, ParametersOfUpdate = Undefined)
	
	UpdateInfo = InfobaseUpdateInfo();
	CurrOrder       = CurrentUpdatingProcedure();
	DurationOfUpdateSteps = UpdateInfo.DurationOfUpdateSteps;
	WriteDurationOfSteps = False;
	If Not ValueIsFilled(DurationOfUpdateSteps.CriticalOnes.Begin) Then
		DurationOfUpdateSteps.CriticalOnes.Begin = CurrentSessionDate();
		WriteDurationOfSteps = True;
	ElsIf Common.DataSeparationEnabled() Then
		If CurrOrder = Enums.OrderOfUpdateHandlers.Normal
			And Not ValueIsFilled(DurationOfUpdateSteps.Regular.Begin) Then
			DurationOfUpdateSteps.Regular.Begin = CurrentSessionDate();
			WriteDurationOfSteps = True;
		ElsIf CurrOrder = Enums.OrderOfUpdateHandlers.Noncritical
			And Not ValueIsFilled(DurationOfUpdateSteps.NonCriticalOnes.Begin) Then
			DurationOfUpdateSteps.NonCriticalOnes.Begin = CurrentSessionDate();
			WriteDurationOfSteps = True;
		EndIf;
	EndIf;
	
	If WriteDurationOfSteps Then
		WriteInfobaseUpdateInfo(UpdateInfo);
	EndIf;
	
	// 
	Query = New Query;
	Query.SetParameter("Status", Enums.UpdateHandlersStatuses.Completed);
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.Text =
		"SELECT DISTINCT
		|	UpdateHandlers.UpdateGroup AS UpdateGroup
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.Status <> &Status
		|	AND UpdateHandlers.ExecutionMode = &ExecutionMode";
	HandlersGroupsAndDependency = Query.Execute().Unload();
	
	// 
	Query = New Query;
	Query.SetParameter("Status", Enums.UpdateHandlersStatuses.Completed);
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.Text = 
		"SELECT
		|	UpdateHandlers.HandlerName AS HandlerName,
		|	UpdateHandlers.Status AS Status,
		|	UpdateHandlers.Version AS Version,
		|	UpdateHandlers.LibraryName AS LibraryName,
		|	UpdateHandlers.ProcessingDuration AS ProcessingDuration,
		|	UpdateHandlers.ExecutionMode AS ExecutionMode,
		|	UpdateHandlers.RegistrationVersion AS RegistrationVersion,
		|	UpdateHandlers.VersionOrder AS VersionOrder,
		|	UpdateHandlers.Id AS Id,
		|	UpdateHandlers.AttemptCount AS AttemptCount,
		|	UpdateHandlers.ErrorInfo AS ErrorInfo,
		|	UpdateHandlers.Comment AS Comment,
		|	UpdateHandlers.Priority AS Priority,
		|	UpdateHandlers.CheckProcedure AS CheckProcedure,
		|	UpdateHandlers.UpdateDataFillingProcedure AS UpdateDataFillingProcedure,
		|	UpdateHandlers.DeferredProcessingQueue AS DeferredProcessingQueue,
		|	UpdateHandlers.ExecuteInMasterNodeOnly AS ExecuteInMasterNodeOnly,
		|	UpdateHandlers.RunAlsoInSubordinateDIBNodeWithFilters AS RunAlsoInSubordinateDIBNodeWithFilters,
		|	UpdateHandlers.Multithreaded AS Multithreaded,
		|	UpdateHandlers.BatchProcessingCompleted AS BatchProcessingCompleted,
		|	UpdateHandlers.UpdateGroup AS UpdateGroup,
		|	UpdateHandlers.StartIteration AS StartIteration,
		|	UpdateHandlers.DataToProcess AS DataToProcess,
		|	UpdateHandlers.ExecutionStatistics AS ExecutionStatistics,
		|	UpdateHandlers.DeferredHandlerExecutionMode AS DeferredHandlerExecutionMode,
		|	UpdateHandlers.ObjectsToChange AS ObjectsToChange,
		|	UpdateHandlers.Order,
		|	UpdateHandlers.IsSeveritySeparationUsed,
		|	UpdateHandlers.IsUpToDateDataProcessed
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode
		|	AND UpdateHandlers.Status <> &Status
		|
		|ORDER BY
		|	UpdateGroup,
		|	DeferredProcessingQueue";
	Handlers = Query.Execute().Unload();
	
	While True Do
		Result = HandlerForExecution(Handlers, HandlersGroupsAndDependency, UpdateInfo);
		
		If Result.Property("MoveToNextUpdateProcedure") Then
			
			If CurrOrder = Enums.OrderOfUpdateHandlers.Crucial Then
				CurrOrder = Enums.OrderOfUpdateHandlers.Normal;
			ElsIf CurrOrder = Enums.OrderOfUpdateHandlers.Normal Then
				CurrOrder = Enums.OrderOfUpdateHandlers.Noncritical;
			EndIf;
			
			DataSeparationEnabled = Common.DataSeparationEnabled();
			
			If CurrOrder = Enums.OrderOfUpdateHandlers.Normal Then
				DurationOfUpdateSteps.CriticalOnes.End = CurrentSessionDate();
				If Not DataSeparationEnabled Then
					DurationOfUpdateSteps.Regular.Begin  = CurrentSessionDate();
				EndIf;
			Else
				DurationOfUpdateSteps.Regular.End = CurrentSessionDate();
				If Not DataSeparationEnabled Then
					DurationOfUpdateSteps.NonCriticalOnes.Begin = CurrentSessionDate();
				EndIf;
			EndIf;
			WriteInfobaseUpdateInfo(UpdateInfo);
			
			If DataSeparationEnabled Then
				Return "AbortExecution";
			Else
				Constants.OrderOfDataToProcess.Set(CurrOrder);
			EndIf;
			
			Continue;
		EndIf;
		
		If Result.HandlerForExecution = Undefined
			And Result.HasUncompleted Then
			UpdateInfo.CurrentUpdateIteration = UpdateInfo.CurrentUpdateIteration + 1;
			WriteInfobaseUpdateInfo(UpdateInfo);
		Else
			Break;
		EndIf;
	EndDo;
	
	HandlerForExecution = Result.HandlerForExecution;
	If HandlerForExecution = Undefined Then
		If Result.HasRunning Then
			Return True;
		Else
			UpdateInfo.DeferredUpdatesEndTime = CurrentSessionDate();
			UpdateInfo.DeferredUpdateCompletedSuccessfully = Result.CompletedSuccessfully;
			DurationOfUpdateSteps.NonCriticalOnes.End = CurrentSessionDate();
			WriteInfobaseUpdateInfo(UpdateInfo);
			Constants.DeferredUpdateCompletedSuccessfully.Set(Result.CompletedSuccessfully);
			If Not Common.IsSubordinateDIBNode() Then
				Constants.DeferredMasterNodeUpdateCompleted.Set(Result.CompletedSuccessfully);
			EndIf;
			
			Return False;
		EndIf;
	EndIf;
	
	ParallelMode = (HandlerForExecution.DeferredHandlerExecutionMode = Enums.DeferredHandlersExecutionModes.Parallel);
	ParametersOfUpdate = ?(ParametersOfUpdate = Undefined, New Structure, ParametersOfUpdate);
	ParametersOfUpdate.Insert("ParallelMode", ParallelMode);
	If ParallelMode Then
		ParametersOfUpdate.Insert("HandlersQueue", UpdateGroupHandlersQueue(HandlerForExecution.UpdateGroup));
		ParametersOfUpdate.Insert("HasMasterNodeHandlers", HasMasterNodeHandlersOnly());
	EndIf;
	
	SetUpdateHandlerParameters(HandlerForExecution, True, ParallelMode);
	BeforeStartDataProcessingProcedure(HandlerContext,
		HandlerForExecution,
		ParametersOfUpdate,
		UpdateInfo);
	
	HandlerContext.HandlerID = HandlerForExecution.Id;
	HandlerContext.HandlerName = HandlerForExecution.HandlerName;
	HandlerContext.ParallelMode = ParallelMode;
	HandlerContext.ParametersOfUpdate = ParametersOfUpdate;
	HandlerContext.UpdateHandlerParameters = SessionParameters.UpdateHandlerParameters;
	HandlerContext.CurrentUpdateIteration = UpdateInfo.CurrentUpdateIteration;
	
	SetUpdateHandlerParameters(Undefined);
	
	Return HandlerForExecution;
	
EndFunction

Procedure ClearUpdateInformation(UpdateInfo)
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	NewUpdateInfo = NewUpdateInfo();
	
	Constants.DeferredUpdateCompletedSuccessfully.Set(False);
	
	UpdateInfo.Insert("UpdateStartTime");
	UpdateInfo.Insert("UpdateEndTime");
	UpdateInfo.Insert("UpdateDuration");
	UpdateInfo.Insert("DeferredUpdateStartTime");
	UpdateInfo.Insert("DeferredUpdatesEndTime");
	UpdateInfo.Insert("SessionNumber", New ValueList());
	UpdateInfo.Insert("DeferredUpdateCompletedSuccessfully");
	UpdateInfo.Insert("OutputUpdatesDetails", False);
	UpdateInfo.Insert("PausedUpdateProcedures", New Array);
	UpdateInfo.Insert("StartedUpdateProcedures", New Array);
	If UpdateInfo.DeferredUpdateManagement.Property("ForceUpdate") Then
		UpdateInfo.Insert("DeferredUpdateManagement", New Structure("ForceUpdate"));
	Else
		UpdateInfo.Insert("DeferredUpdateManagement", New Structure);
	EndIf;
	UpdateInfo.Insert("CurrentUpdateIteration", 1);
	UpdateInfo.Insert("HandlersGroupsDependence", New Map);
	UpdateInfo.Insert("TablesToReadAndChange", New Map);
	UpdateInfo.HandlerTreeVersion = Metadata.Version;
	
	UpdateInfo.Insert("DurationOfUpdateSteps", NewUpdateInfo.DurationOfUpdateSteps);
	
	WriteInfobaseUpdateInfo(UpdateInfo);
	
	WriteLockedObjectsInfo(NewLockedObjectsInfo());
EndProcedure

Procedure CheckDeferredHandlerProperties(Val Handler, Val DeferredHandlersExecutionMode, Val LibraryName, ErrorsText)
	
	If DeferredHandlersExecutionMode = "Parallel"
		And Not ValueIsFilled(Handler.UpdateDataFillingProcedure) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'No data population procedure is specified
					   |for deferred update handler
					   |%1.';"),
			Handler.HandlerName);
		
		WriteError(ErrorText);
		ErrorsText = ErrorsText + ErrorText + Chars.LF;
	EndIf;

	If Handler.ExclusiveMode = True Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Deferred handler ""%1""
			|cannot have flag ""%2"" set.';"), 
			Handler.HandlerName,
			"ExclusiveMode");
		WriteError(ErrorText);
		ErrorsText = ErrorsText + ErrorText + Chars.LF;
	EndIf;

	If DeferredHandlersExecutionMode = "Parallel" And Handler.ExecuteInMasterNodeOnly
		And Handler.RunAlsoInSubordinateDIBNodeWithFilters Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'In deferred handler ""%1""
			|, the following properties have invalid values:
			| - ""%2""
			| - ""%3"".
			|
			|The property values cannot be True at the same time.';"), 
			Handler.HandlerName,
			"ExecuteInMasterNodeOnly",
			"RunAlsoInSubordinateDIBNodeWithFilters");
		WriteError(ErrorText);
		ErrorsText = ErrorsText + ErrorText + Chars.LF;
	EndIf;
	
	If DeferredHandlersExecutionMode = "Sequentially"
		And Handler.Multithreaded Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The deferred handler ""%1"" has the ""Multithreaded"" property set, which is prohibited.
			|The handler belongs to the ""%2"" subsystem, which supports only sequential deferred handlers.';"),
			Handler.HandlerName,
			LibraryName);
		WriteError(ErrorText);
		ErrorsText = ErrorsText + ErrorText + Chars.LF;
	EndIf;
	
	If Handler.SharedData = True Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'In deferred handler ""%1""
			|, the value of property ""%2"" is invalid.
			|
			|This property cannot be True in deferred handlers.';"), 
			Handler.HandlerName, "SharedData");
		WriteError(ErrorText);
		ErrorsText = ErrorsText + ErrorText + Chars.LF;
	EndIf;
	
EndProcedure

Procedure CheckDeferredHandlerIDUniqueness(UpdateIterations)
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	UniquenessCheckTable = New ValueTable;
	UniquenessCheckTable.Columns.Add("Id");
	UniquenessCheckTable.Columns.Add("IndexOf");
	
	For Each UpdateIteration In UpdateIterations Do
		
		FilterParameters = New Structure;
		FilterParameters.Insert("ExecutionMode", "Deferred");
		HandlersTable = UpdateIteration.Handlers;
		
		Handlers = HandlersTable.FindRows(FilterParameters);
		For Each Handler In Handlers Do
			If Not ValueIsFilled(Handler.Id) Then
				Continue;
			EndIf;
			TableRow = UniquenessCheckTable.Add();
			TableRow.Id = String(Handler.Id);
			TableRow.IndexOf        = 1;
		EndDo;
		
	EndDo;
	
	InitialRowCount = UniquenessCheckTable.Count();
	UniquenessCheckTable.GroupBy("Id", "IndexOf");
	FinalRowCount = UniquenessCheckTable.Count();
	
	If InitialRowCount = FinalRowCount Then
		Return; // 
	EndIf;
	
	UniquenessCheckTable.Sort("IndexOf Desc");
	MessageText = NStr("en = 'Some of the deferred update handlers have matching UUIDs:';");
	For Each IDRow In UniquenessCheckTable Do
		If IDRow.IndexOf = 1 Then
			Break;
		EndIf;
		MessageText = MessageText + Chars.LF + IDRow.Id;
	EndDo;
	
	Raise(MessageText, ErrorCategory.ConfigurationError);
	
EndProcedure

Procedure AddDeferredHandlers(LibraryName, HandlersByVersion, UpdateGroup, ErrorsText, CurrentExecutionMode = "")
	
	IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
	IsSubordinateDIBNodeWithFilter = Common.IsSubordinateDIBNodeWithFilter();
	SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails();
	
	SubsystemDetails = SubsystemsDetails.ByNames[LibraryName];
	ParallelSinceVersion = SubsystemDetails.ParallelDeferredUpdateFromVersion;
	DeferredHandlersExecutionMode = SubsystemDetails.DeferredHandlersExecutionMode;
	
	SeparatedHandlersSet   = InformationRegisters.UpdateHandlers.CreateRecordSet();
	SeparatedHandlersSet.Read();
	
	UpdateInfo = InfobaseUpdateInfo();
	HandlersGroupsDependence = UpdateInfo.HandlersGroupsDependence;
	TablesToReadAndChange   = UpdateInfo.TablesToReadAndChange;
	
	SkipCheck     = False;
	CreateNewIteration = True;
	Iteration = 1;
	HasMasterNodeHandlersOnly = False;
	LockedObjectsInfo = LockedObjectsInfo();
	
	FilterCriticalOnes = New Structure("Order", Enums.OrderOfUpdateHandlers.Crucial);
	HasCriticalHandlers = (HandlersByVersion.FindRows(FilterCriticalOnes, True).Count() > 0);
	
	For Each VersionRow In HandlersByVersion Do
		FillLockedItems(VersionRow, LockedObjectsInfo);
		
		If DeferredHandlersExecutionMode = "Sequentially" Then
			If CurrentExecutionMode = "Parallel" Then
				// 
				// 
				UpdateGroup = UpdateGroup + 1;
			EndIf;
			HandlersGroupsDependence.Insert(UpdateGroup, Iteration <> 1);
			CurrentExecutionMode = "Sequentially";
		ElsIf DeferredHandlersExecutionMode = "Parallel" And Not ValueIsFilled(ParallelSinceVersion) Then
			HandlersGroupsDependence.Insert(UpdateGroup, False);
			CurrentExecutionMode = "Parallel";
			CreateNewIteration = False;
		ElsIf DeferredHandlersExecutionMode = "Parallel" And ValueIsFilled(ParallelSinceVersion) And Not SkipCheck Then
			VersionNumber = VersionRow.Version;
			If VersionNumber = "*" Then
				Result = -1;
			ElsIf StrStartsWith(VersionNumber, "DebuggingTheHandler") Then
				Result = 1;
			Else
				Result = CommonClientServer.CompareVersions(VersionNumber, ParallelSinceVersion);
			EndIf;
			
			If Result < 0 Then
				If CurrentExecutionMode = "Parallel" Then
					// 
					// 
					UpdateGroup = UpdateGroup + 1;
				EndIf;
				HandlersGroupsDependence.Insert(UpdateGroup, Iteration <> 1);
				CurrentExecutionMode = "Sequentially";
			Else
				HandlersGroupsDependence.Insert(UpdateGroup, Iteration <> 1);
				SkipCheck = True;
				CurrentExecutionMode = "Parallel";
				CreateNewIteration = False;
			EndIf;
		EndIf;
		
		For Each Handler In VersionRow.Rows Do
			CheckDeferredHandlerProperties(Handler, CurrentExecutionMode, LibraryName, ErrorsText);
			If CurrentExecutionMode = "Parallel" Then
				PopulateDataToReadAndChange(Handler, TablesToReadAndChange);
			EndIf;
			
			Record = SeparatedHandlersSet.Add();
			
			FillPropertyValues(Record, Handler, , "ExecutionMode,VersionOrder");
			ExecutionMode = Enums.HandlersExecutionModes[Handler.ExecutionMode];
			
			If Not ValueIsFilled(Record.Order) Then
				Record.Order = Enums.OrderOfUpdateHandlers.Normal;
			EndIf;
			Record.VersionOrder = VersionRow.VersionOrder;
			Record.ExecutionMode = ExecutionMode;
			Record.Status = Enums.UpdateHandlersStatuses.NotPerformed;
			Record.LibraryName = LibraryName;
			Record.UpdateGroup = UpdateGroup;
			Record.ExecutionStatistics = New ValueStorage(New Map);
			If CurrentExecutionMode = "Parallel" Then
				Record.DeferredHandlerExecutionMode = Enums.DeferredHandlersExecutionModes.Parallel;
			Else
				Record.DeferredHandlerExecutionMode = Enums.DeferredHandlersExecutionModes.Sequentially;
				If ValueIsFilled(ParallelSinceVersion) And HasCriticalHandlers Then
					Record.Order = Enums.OrderOfUpdateHandlers.Crucial;
				EndIf;
			EndIf;
			
			// 
			If CurrentExecutionMode = "Parallel" And Not IsSubordinateDIBNode
				And Handler.ExecuteInMasterNodeOnly = True Then
				HasMasterNodeHandlersOnly = True;
			EndIf;
			If CurrentExecutionMode = "Parallel" And IsSubordinateDIBNodeWithFilter
				And Not Handler.RunAlsoInSubordinateDIBNodeWithFilters Then
				HasMasterNodeHandlersOnly = True;
				// 
				Record.Status = Enums.UpdateHandlersStatuses.Completed;
			EndIf;
			
		EndDo;
		
		If CreateNewIteration Then
			UpdateGroup = UpdateGroup + 1;
		EndIf;
		Iteration = Iteration + 1;
	EndDo;
	
	WriteLockedObjectsInfo(LockedObjectsInfo);
	CurrentValue = Constants.DeferredMasterNodeUpdateCompleted.Get();
	Constants.DeferredMasterNodeUpdateCompleted.Set(CurrentValue And Not HasMasterNodeHandlersOnly);
	
	// 
	SeparatedHandlersSet.Write();
	// 
	WriteInfobaseUpdateInfo(UpdateInfo);
	
EndProcedure

Function IncompleteDeferredHandlers(UpdateInfo)
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.SetParameter("Status", Enums.UpdateHandlersStatuses.Completed);
	Query.Text = 
		"SELECT
		|	UpdateHandlers.HandlerName AS HandlerName,
		|	UpdateHandlers.Status AS Status,
		|	UpdateHandlers.Version AS Version,
		|	UpdateHandlers.LibraryName AS LibraryName,
		|	UpdateHandlers.ProcessingDuration AS ProcessingDuration,
		|	UpdateHandlers.ExecutionMode AS ExecutionMode,
		|	UpdateHandlers.RegistrationVersion AS RegistrationVersion,
		|	UpdateHandlers.Id AS Id,
		|	UpdateHandlers.AttemptCount AS AttemptCount,
		|	UpdateHandlers.ExecutionStatistics AS ExecutionStatistics,
		|	UpdateHandlers.ErrorInfo AS ErrorInfo,
		|	UpdateHandlers.Comment AS Comment,
		|	UpdateHandlers.Priority AS Priority,
		|	UpdateHandlers.CheckProcedure AS CheckProcedure,
		|	UpdateHandlers.UpdateDataFillingProcedure AS UpdateDataFillingProcedure,
		|	UpdateHandlers.DeferredProcessingQueue AS DeferredProcessingQueue,
		|	UpdateHandlers.ExecuteInMasterNodeOnly AS ExecuteInMasterNodeOnly,
		|	UpdateHandlers.RunAlsoInSubordinateDIBNodeWithFilters AS RunAlsoInSubordinateDIBNodeWithFilters,
		|	UpdateHandlers.Multithreaded AS Multithreaded,
		|	UpdateHandlers.BatchProcessingCompleted AS BatchProcessingCompleted,
		|	UpdateHandlers.UpdateGroup AS UpdateGroup,
		|	UpdateHandlers.StartIteration AS StartIteration,
		|	UpdateHandlers.DataToProcess AS DataToProcess
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode
		|	AND UpdateHandlers.Status <> &Status";
	Handlers = Query.Execute().Unload();
	
	HandlersTree = UpdateInfo.HandlersTree.Rows;
	If HandlersTree.Count() > 0 Then
		UpdateInfo.HandlersTree.Columns.VersionNumber.Name = "Version";
		Filter = New Structure;
		Filter.Insert("Status", "Running");
		IsRunning = HandlersTree.FindRows(Filter, True);
		MoveHandlersFromConstant(Handlers, IsRunning);
		
		Filter.Status = "NotCompleted2";
		NotExecuted = HandlersTree.FindRows(Filter, True);
		MoveHandlersFromConstant(Handlers, NotExecuted);
		
		Filter.Status = "Error";
		CompletedWithError1 = HandlersTree.FindRows(Filter, True);
		MoveHandlersFromConstant(Handlers, CompletedWithError1);
		
		UpdateInfo.HandlersTree = New ValueTree;
	EndIf;
	
	Return Handlers
	
EndFunction

Procedure AddIncompleteDeferredHandlers(UpdateIteration, LibraryName,
		IncompleteDeferredHandlers, Handlers)
	
	Filter = New Structure;
	Filter.Insert("LibraryName", LibraryName);
	IncompleteLibraryHandlers = IncompleteDeferredHandlers.FindRows(Filter);
	For Each Handler In IncompleteLibraryHandlers Do
		FoundHandler = Handlers.Find(Handler.HandlerName, "HandlerName", True);
		If FoundHandler <> Undefined Then
			Continue;
		EndIf;
		
		If ValueIsFilled(Handler.Id) Then
			FoundHandler = Handlers.Find(Handler.Id, "Id", True);
			If FoundHandler <> Undefined Then
				Continue;
			EndIf;
		EndIf;
		
		//  
		AdditionalSelection = New Structure;
		AdditionalSelection.Insert("ExecutionMode", "Deferred");
		AdditionalSelection.Insert("Procedure", Handler.HandlerName);
		FoundHandler = UpdateIteration.Handlers.FindRows(AdditionalSelection);
		If FoundHandler.Count() = 0 Then
			Continue;
		Else
			FoundHandler = FoundHandler[0];
		EndIf;
		
		// 
		VersionRow = Handlers.Find(FoundHandler.Version, "Version");
		If VersionRow = Undefined Then
			VersionRow = Handlers.Add();
			VersionRow.Version = FoundHandler.Version;
		EndIf;
		
		NewHandler = VersionRow.Rows.Add();
		FillPropertyValues(NewHandler, FoundHandler, , "ExecutionMode");
		NewHandler.HandlerName = FoundHandler.Procedure;
		NewHandler.ExecutionMode = "Deferred";
	EndDo;
	
EndProcedure

Procedure MoveHandlersFromConstant(Receiver, Source)
	
	For Each Handler In Source Do
		NewHandler = Receiver.Add();
		FillPropertyValues(NewHandler, Handler);
		NewHandler.ExecutionMode = Enums.HandlersExecutionModes.Deferred;
	EndDo;
	
EndProcedure

Function UpdateGroupHandlersQueue(UpdateGroup)
	
	Query = New Query;
	Query.SetParameter("UpdateGroup", UpdateGroup);
	Query.Text = 
		"SELECT
		|	UpdateHandlers.DeferredProcessingQueue AS Queue,
		|	UpdateHandlers.Id AS Id,
		|	UpdateHandlers.HandlerName AS Handler
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.UpdateGroup = &UpdateGroup";
	Return Query.Execute().Unload();
	
EndFunction

Function HasMasterNodeHandlersOnly()
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecuteInMasterNodeOnly = TRUE";
	Return Query.Execute().Unload().Count() > 0;
	
EndFunction

// Returns:
//  Structure:
//     * HandlerForExecution - Undefined
//                               - ValueTableRow:
//          ** HandlerName - String
//          ** Id - UUID
//     * CompletedSuccessfully - Boolean
//     * HasRunning - Boolean
//     * HasUncompleted - Boolean
//
Function HandlerForExecution(Handlers, HandlersGroupsAndDependency, UpdateInfo)
	
	HandlersGroupsDependence = UpdateInfo.HandlersGroupsDependence;
	CurrentIteration              = UpdateInfo.CurrentUpdateIteration;
	CurrOrder               = CurrentUpdatingProcedure();
	
	RunningOnes = New Map;
	RunningOnes.Insert(Enums.OrderOfUpdateHandlers.Crucial, True);
	If CurrOrder = Enums.OrderOfUpdateHandlers.Normal Then
		RunningOnes.Insert(Enums.OrderOfUpdateHandlers.Normal, True);
	ElsIf CurrOrder = Enums.OrderOfUpdateHandlers.Noncritical Then
		RunningOnes.Insert(Enums.OrderOfUpdateHandlers.Normal, True);
		RunningOnes.Insert(Enums.OrderOfUpdateHandlers.Noncritical, True);
	EndIf;
	
	CurrentUpdateGroup = Undefined;
	HandlerForExecution = Undefined;
	GroupsToSkip      = New Array;
	HasRunning       = False;
	HasErrors              = False;
	HasUncompleted       = False;
	RunningMultithreadHandler = Undefined;
	For Each Handler In Handlers Do
		If Handler.AttemptCount >= MaxUpdateAttempts(Handler) Then
			HasErrors = True;
			Continue;
		EndIf;
		
		// 
		If RunningOnes[Handler.Order] = Undefined Then
			Continue;
		ElsIf CurrOrder <> Enums.OrderOfUpdateHandlers.Noncritical
			And Handler.IsSeveritySeparationUsed
			And Handler.IsUpToDateDataProcessed Then
			Continue;
		EndIf;
		
		If ThisIsOutOfDateDataCleanupHandler(Handler)
		   And Handlers.Count() > 1 Then
			Continue;
		EndIf;
		
		If Handler.StartIteration = CurrentIteration Then
			// 
			HasUncompleted = True;
			Continue;
		EndIf;
		
		If GroupsToSkip.Find(Handler.UpdateGroup) <> Undefined Then
			Continue;
		EndIf;
		
		If Handler.UpdateGroup <> 1
			And HandlersGroupsDependence[Handler.UpdateGroup] = True Then
			FoundRow = HandlersGroupsAndDependency.Find(Handler.UpdateGroup - 1, "UpdateGroup");
			If FoundRow <> Undefined Then
				GroupsToSkip.Add(Handler.UpdateGroup);
				Continue;
			EndIf;
		EndIf;
		
		If CurrentUpdateGroup = Undefined Then
			CurrentUpdateGroup = Handler.UpdateGroup;
		ElsIf CurrentUpdateGroup <> Handler.UpdateGroup Then
			// 
			// 
			If RunningMultithreadHandler <> Undefined Then
				HandlerForExecution = RunningMultithreadHandler;
				Break;
			EndIf;
			CurrentUpdateGroup = Handler.UpdateGroup;
		EndIf;
		
		If Handler.Status = Enums.UpdateHandlersStatuses.Running
			And Not Handler.BatchProcessingCompleted Then
			If Handler.Multithreaded Then
				If HasBatchesForUpdate(Handler) Then
					// 
					// 
					RunningMultithreadHandler = Handler;
				EndIf;
			ElsIf UpdateThreads().Count() = 0 Then // 
				HandlerForExecution = Handler;
			EndIf;
			HasRunning = True;
			Continue;
		EndIf;
		
		If Handler.Status = Enums.UpdateHandlersStatuses.Paused Then
			Continue;
		EndIf;
		
		HandlerForExecution = Handler;
		Break;
	EndDo;
	
	If HandlerForExecution = Undefined And RunningMultithreadHandler <> Undefined Then
		HandlerForExecution = RunningMultithreadHandler;
	EndIf;
	
	Result = New Structure;
	Result.Insert("HandlerForExecution", HandlerForExecution);
	Result.Insert("CompletedSuccessfully", Not HasErrors);
	Result.Insert("HasRunning", HasRunning);
	Result.Insert("HasUncompleted", HasUncompleted);
	
	If HandlerForExecution = Undefined
		And Not HasRunning
		And Not HasUncompleted
		And CurrOrder <> Enums.OrderOfUpdateHandlers.Noncritical Then
		Result.Insert("MoveToNextUpdateProcedure");
	EndIf;
	
	Return Result;
	
EndFunction

Function HandlerUpdates(HandlerName)
	
	Query = New Query;
	Query.SetParameter("HandlerName", HandlerName);
	Query.Text =
		"SELECT
		|	UpdateHandlers.HandlerName AS HandlerName,
		|	UpdateHandlers.Status AS Status,
		|	UpdateHandlers.Version AS Version,
		|	UpdateHandlers.LibraryName AS LibraryName,
		|	UpdateHandlers.ProcessingDuration AS ProcessingDuration,
		|	UpdateHandlers.ExecutionMode AS ExecutionMode,
		|	UpdateHandlers.RegistrationVersion AS RegistrationVersion,
		|	UpdateHandlers.VersionOrder AS VersionOrder,
		|	UpdateHandlers.Id AS Id,
		|	UpdateHandlers.AttemptCount AS AttemptCount,
		|	UpdateHandlers.ExecutionStatistics AS ExecutionStatistics,
		|	UpdateHandlers.ErrorInfo AS ErrorInfo,
		|	UpdateHandlers.Comment AS Comment,
		|	UpdateHandlers.Priority AS Priority,
		|	UpdateHandlers.CheckProcedure AS CheckProcedure,
		|	UpdateHandlers.UpdateDataFillingProcedure AS UpdateDataFillingProcedure,
		|	UpdateHandlers.DeferredProcessingQueue AS DeferredProcessingQueue,
		|	UpdateHandlers.ExecuteInMasterNodeOnly AS ExecuteInMasterNodeOnly,
		|	UpdateHandlers.RunAlsoInSubordinateDIBNodeWithFilters AS RunAlsoInSubordinateDIBNodeWithFilters,
		|	UpdateHandlers.Multithreaded AS Multithreaded,
		|	UpdateHandlers.BatchProcessingCompleted AS BatchProcessingCompleted,
		|	UpdateHandlers.UpdateGroup AS UpdateGroup,
		|	UpdateHandlers.StartIteration AS StartIteration,
		|	UpdateHandlers.DataToProcess AS DataToProcess,
		|	UpdateHandlers.DeferredHandlerExecutionMode AS DeferredHandlerExecutionMode
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.HandlerName = &HandlerName";
	Result = Query.Execute().Unload();
	If Result.Count() = 0 Then
		Return Undefined;
	Else
		Return Result[0];
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Name of the data logging thread group for the deferred update.
//
// Returns:
//  String -  group name.
//
Function DeferredUpdateDataRegistrationThreadsGroup()
	
	Return "Registration";
	
EndFunction

// The name of the group of threads pending updates.
//
// Returns:
//  String -  group name.
//
Function DeferredUpdateThreadsGroup()
	
	Return "RefreshEnabled";
	
EndFunction

// The name of the groups of streams of search data portions for multi-threaded execution of update handlers.
//
// Returns:
//  String -  group name.
//
Function BatchesSearchThreadsGroup()
	
	Return "Search";
	
EndFunction

// Create a new description of deferred update data logging flows.
//
// Returns:
//   See NewThreadsDetails
//
Function NewDetailsOfDeferredUpdateDataRegistrationThreadsGroups() Export
	
	RegistrationGroup = NewThreadsGroupDetails();
	RegistrationGroup.Procedure =
		"InfobaseUpdateInternal.FillDeferredHandlerData";
	RegistrationGroup.CompletionProcedure =
		"InfobaseUpdateInternal.CompleteDeferredUpdateDataRegistration";
	
	Groups = New Map;
	Groups[DeferredUpdateDataRegistrationThreadsGroup()] = RegistrationGroup;
	
	Return Groups;
	
EndFunction

// Add a deferred update data logging flow.
//
// Parameters:
//  DataToProcessDetails - See NewDataToProcessDetails
//
// Returns:
//  ValueTableRow of See NewThreadsDetails
//
Function AddDeferredUpdateDataRegistrationThread(DataToProcessDetails)
	
	DescriptionTemplate = NStr("en = 'Register data of %1 update handler';");
	DataToProcessDetails.Status = "Running";
	
	Stream = NewThread();
	Stream.ProcedureParameters = DataToProcessDetails;
	Stream.CompletionProcedureParameters = DataToProcessDetails;
	Stream.Group = DeferredUpdateDataRegistrationThreadsGroup();
	Stream.Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate,
		DataToProcessDetails.HandlerName);
	
	SaveUpdateThread(Stream);
	
	Return Stream;
	
EndFunction

// Complete registration of deferred update data.
// Called automatically in the main thread, after completion of execution, fill in the data of the laid-out Handler().
//
// Parameters:
//  DataToProcessDetails - See NewDataToProcessDetails
//  ResultAddress - String -  address of the temporary storage with the result from fill in the data from the laid-out Handler().
//
Procedure CompleteDeferredUpdateDataRegistration(DataToProcessDetails,
                                                          ResultAddress) Export
	
	Result = GetFromTempStorage(ResultAddress);
	
	FillPropertyValues(DataToProcessDetails, Result,, "RegisteredRecordersTables");
	DataToProcessDetails.Status = "Completed2";
	
	If ValueIsFilled(Result.RegisteredRecordersTables) Then
		RegisteredTables = New Array;
		For Each KeyAndValue In Result.RegisteredRecordersTables Do
			RegisteredTables.Add(KeyAndValue.Value);
		EndDo;
	EndIf;
	DataToProcessDetails.RegisteredRecordersTables = RegisteredTables;
	
	DataRegistrationDuration = 0;
	Result.Property("DataRegistrationDuration", DataRegistrationDuration);
	
	If IsMultithreadHandlerDataDetails(DataToProcessDetails) Then
		CorrectFullNamesInTheSelectionParameters(DataToProcessDetails.SelectionParameters);
	EndIf;
	
	IsUpToDateFilterSet = IsUpToDateFilterSet(DataToProcessDetails.UpToDateData);
	DataToProcess = New ValueStorage(DataToProcessDetails, New Deflation(9));
	
	PropertiesToSet = New Structure;
	PropertiesToSet.Insert("DataRegistrationDuration", DataRegistrationDuration);
	PropertiesToSet.Insert("DataToProcess", DataToProcess);
	If IsUpToDateFilterSet Then
		PropertiesToSet.Insert("IsSeveritySeparationUsed", True);
	EndIf;
	SetHandlerProperties(DataToProcessDetails.HandlerName, PropertiesToSet);
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		If Result.UpdateData <> Undefined Then
			ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
			ModuleDataExchangeServer.SaveUpdateData(Result.UpdateData, Result.NameOfChangedFile);
		EndIf;
	EndIf;
	
EndProcedure

// Create a new description of deferred update handler threads.
//
// Returns:
//   See NewThreadsDetails
//
Function NewDetailsOfDeferredUpdateHandlersThreadsGroups() Export
	
	UpdateGroup = NewThreadsGroupDetails();
	UpdateGroup.Procedure =
		"InfobaseUpdateInternal.ExecuteDeferredHandler";
	UpdateGroup.CompletionProcedure =
		"InfobaseUpdateInternal.CompleteDeferredHandlerExecution";
	UpdateGroup.OnAbnormalTermination =
		"InfobaseUpdateInternal.OnDeferredHandlerThreadAbnormalTermination";
	UpdateGroup.OnCancelThread =
		"InfobaseUpdateInternal.OnCancelDeferredHandlerThread";
	
	SearchGroup1 = NewThreadsGroupDetails();
	SearchGroup1.Procedure =
		"InfobaseUpdateInternal.FindBatchToUpdate";
	SearchGroup1.CompletionProcedure =
		"InfobaseUpdateInternal.EndSearchForBatchToUpdate";
	SearchGroup1.OnAbnormalTermination =
		"InfobaseUpdateInternal.OnBatchToImportSearchThreadAbnormalTermination";
	SearchGroup1.OnCancelThread =
		"InfobaseUpdateInternal.OnCancelSearchBatchToUpdate";
	
	Groups = New Map;
	Groups[DeferredUpdateThreadsGroup()] = UpdateGroup;
	Groups[BatchesSearchThreadsGroup()] = SearchGroup1;
	
	Return Groups;
	
EndFunction

Function NewThread()
	
	Threads = NewThreadsDetails();
	Stream = Threads.Add();
	Stream.ThreadID = New UUID;
	
	Return Stream;
	
EndFunction

// Add a deferred update handler thread.
//
// Parameters:
//  Description of streams - see New Description of the processing flowsreferences
//  UpdateInfo - See InfobaseUpdateInfo
//
// Returns:
//   ValueTableRow of See NewThreadsDetails
//
Function AddDeferredUpdateHandlerThread(UpdateInfo)
	
	Stream = Undefined;
	
	While Stream = Undefined Do
		HandlerContext = NewHandlerContext();
		HandlerUpdates = FindUpdateHandler(HandlerContext); // 
		
		If TypeOf(HandlerUpdates) = Type("ValueTableRow") Then
			If HandlerContext.ExecuteHandler Then
				Stream = NewThread();
				
				If HandlerUpdates.Multithreaded Then
					SupplementMultithreadHandlerContext(HandlerContext);
					Added = AddDatasearchThreadForUpdate(Stream,
						HandlerUpdates,
						HandlerContext,
						UpdateInfo);
					
					If Not Added Then
						Stream = True;
					EndIf;
				Else
					AddUpdateHandlerThread(Stream, HandlerContext);
				EndIf;
			Else
				CompleteDeferredHandlerExecution(HandlerContext, Undefined); // 
				Stream = Undefined;
			EndIf;
		Else
			Stream = HandlerUpdates;
		EndIf;
	EndDo;
	
	Return Stream;
	
EndFunction

// Add a stream of data search for the handler of the pending updates.
//
// Parameters:
//  Stream - See NewThreadsDetails
//  Handler - ValueTreeRow -  update handler as a string in the handler tree.
//  HandlerContext - See NewHandlerContext
//  UpdateInfo - See InfobaseUpdateInfo
//
// Returns:
//  Boolean - 
//
Function AddDatasearchThreadForUpdate(Stream, Handler, HandlerContext, UpdateInfo)
	
	HandlerName = Handler.HandlerName;
	LongDesc = Handler.DataToProcess.Get();
	
	If Not LongDesc.BatchSearchInProgress Then
		BatchesToUpdate = LongDesc.BatchesToUpdate;
		
		If LongDesc.SearchCompleted And (BatchesToUpdate = Undefined Or BatchesToUpdate.Count() = 0) Then
			BatchesToUpdate = Undefined;
			LongDesc.LastSelectedRecord = Undefined;
			LongDesc.SearchCompleted = False;
		EndIf;
		
		DescriptionTemplate = NStr("en = 'Searching data for the %1 update handler';");
		Stream.Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, HandlerName);
		Stream.Group = BatchesSearchThreadsGroup();
		Stream.CompletionPriority = 1;
		
		SearchParameters = NewBatchSearchParameters();
		SearchParameters.HandlerName = HandlerName;
		SearchParameters.HandlerContext = HandlerContext;
		SearchParameters.SelectionParameters = LongDesc.SelectionParameters;
		SearchParameters.Queue = HandlerContext.Parameters.Queue;
		SearchParameters.ForceUpdate = ForceUpdate(UpdateInfo);
		
		UnprocessedBatch = FirstUnprocessedBatch(BatchesToUpdate);
		
		If UnprocessedBatch <> Undefined Then
			SearchParameters.BatchID = UnprocessedBatch.Id;
			SearchParameters.FirstRecord = UnprocessedBatch.FirstRecord;
			SearchParameters.LatestRecord = UnprocessedBatch.LatestRecord;
		ElsIf LongDesc.LastSelectedRecord <> Undefined Then
			SearchParameters.LastSelectedRecord = LongDesc.LastSelectedRecord;
		EndIf;
		
		Stream.ProcedureParameters = SearchParameters;
		Stream.CompletionProcedureParameters = SearchParameters;
		LongDesc.BatchSearchInProgress = True;
		
		BeginTransaction();
		Try
			HandlerProperty(HandlerName,
				"DataToProcess",
				New ValueStorage(LongDesc));
			SaveUpdateThread(Stream);
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Add a deferred update handler thread.
//
// Parameters:
//  Stream - See NewThreadsDetails
//  HandlerContext - See NewHandlerContext
//
Procedure AddUpdateHandlerThread(Stream, HandlerContext)
	
	HandlerName = HandlerContext.HandlerName;
	DescriptionTemplate = NStr("en = 'Run the %1 update handler';");
	Stream.Description = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate, HandlerName);
	Stream.Group = DeferredUpdateThreadsGroup();
	Stream.ProcedureParameters = HandlerContext;
	Stream.CompletionProcedureParameters = HandlerContext;
	
	SaveUpdateThread(Stream);
	
EndProcedure

// Execute a deferred handler in the background task.
// Executed only if the handler Context.Execute handler = True (i.e. not in a subordinate rib node).
//
// Parameters:
//  HandlerContext - See NewHandlerContext
//  ResultAddress - String -  address of the temporary storage for saving the result of the procedure.
//
Procedure ExecuteDeferredHandler(HandlerContext, ResultAddress) Export
	
	SessionParameters.UpdateHandlerParameters = HandlerContext.UpdateHandlerParameters;
	
	SubsystemExists = Common.SubsystemExists("StandardSubsystems.AccessManagement");
	DisableAccessKeysUpdate(True, SubsystemExists);
	Try
		CallParameters = New Array;
		CallParameters.Add(HandlerContext.Parameters);
		Result = NewDeferredHandlerResult();
		
		If HandlerContext.Parameters.Property("DataToUpdate") Then
			TotalData = 0;
			For Each RowObjectToUpdate In HandlerContext.Parameters.DataToUpdate.DataSet Do
				TotalData = TotalData + RowObjectToUpdate.Data.Count();
			EndDo;
			Result.TotalObjectsPassedForProcessing = TotalData;
		EndIf;
		Result.HandlerProcedureStart = CurrentUniversalDateInMilliseconds();
		Common.ExecuteConfigurationMethod(HandlerContext.HandlerName, CallParameters);
		Result.HandlerProcedureCompletion = CurrentUniversalDateInMilliseconds();
		
		Result.Parameters = HandlerContext.Parameters;
		Result.UpdateHandlerParameters = SessionParameters.UpdateHandlerParameters;
		
		CheckNestedTransactionWhenExecutingDeferredHandler(HandlerContext, Result);
		
		PutToTempStorage(Result, ResultAddress);
		DisableAccessKeysUpdate(False, SubsystemExists);
		SessionParameters.UpdateHandlerParameters = New FixedStructure(NewUpdateHandlerParameters());
	Except
		CheckNestedTransactionWhenExecutingDeferredHandler(HandlerContext, Result);
		
		DisableAccessKeysUpdate(False, SubsystemExists);
		SessionParameters.UpdateHandlerParameters = New FixedStructure(NewUpdateHandlerParameters());
		Raise;
	EndTry;
	
EndProcedure

// Finish executing the deferred handler.
// Called automatically in the main thread, after execution is complete, run the laid Handler().
//
// Parameters:
//  HandlerContext - See NewHandlerContext
//  ResultAddress - String -  the address of the temporary storage with the result from runcomposed Handler().
//  Swedenlithuania -  See InfobaseUpdateInfo
//
Procedure CompleteDeferredHandlerExecution(HandlerContext, ResultAddress) Export
	
	HandlerContext.Insert("SkipCancelingTransactions");
	
	BeginTransaction();
	Try
		HandlerUpdates = HandlerUpdates(HandlerContext.HandlerName);
		HandlerProperty(HandlerUpdates.HandlerName, "BatchProcessingCompleted", True);
		
		ImportHandlerExecutionResult(HandlerContext, ResultAddress);
		CalculateHandlerProcedureEecutionTime(HandlerContext, HandlerContext.HandlerName);
		SessionParameters.UpdateHandlerParameters = HandlerContext.UpdateHandlerParameters;
		
		If HandlerContext.StartedWithoutErrors Then
			AfterStartDataProcessingProcedure(HandlerContext, HandlerContext.HandlerName);
		EndIf;
		
		EndDataProcessingProcedure(HandlerContext, HandlerContext.HandlerName);
		SessionParameters.UpdateHandlerParameters = New FixedStructure(NewUpdateHandlerParameters());
		
		If HandlerUpdates.Multithreaded Then
			CompleteMultithreadHandlerExecution(HandlerContext, HandlerContext.HandlerName);
		EndIf;
		
		EndDeferredUpdateHandlerExecution(HandlerContext);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	HandlerContext.Delete("SkipCancelingTransactions");
	
	If HandlerContext.Property("ErrorWhenCompletingHandler") Then
		Raise HandlerContext.ErrorWhenCompletingHandler;
	EndIf;
	
EndProcedure

// Calculate the execution time of the data processing procedure (not the entire handler).
//
// Parameters:
//  HandlerContext - See NewHandlerContext
//  HandlerName - String
//
Procedure CalculateHandlerProcedureEecutionTime(HandlerContext, HandlerName)
	
	HandlerUpdates = HandlerUpdates(HandlerName);
	
	HandlerProcedureStart = ?(HandlerContext.HandlerProcedureStart = Undefined, 0,
		HandlerContext.HandlerProcedureStart);
	HandlerProcedureCompletion = ?(HandlerContext.HandlerProcedureCompletion = Undefined, 0,
		HandlerContext.HandlerProcedureCompletion);
	TotalObjectsPassedForProcessing = ?(HandlerContext.TotalObjectsPassedForProcessing = Undefined, 0,
		HandlerContext.TotalObjectsPassedForProcessing);
	HandlerProcedureDuration = HandlerProcedureCompletion - HandlerProcedureStart;
	ExecutionStarted = '00010101' + HandlerProcedureStart / 1000;
	ExecutionCompletion = '00010101' + HandlerProcedureCompletion / 1000;
	ExecutionStatistics = HandlerUpdates.ExecutionStatistics.Get();
	StatisticsStart = ExecutionStatistics["HandlerProcedureStart"];
	StatisticsCompletion = ExecutionStatistics["HandlerProcedureCompletion"];
	DataStatisticsToProcess = ExecutionStatistics["TotalObjectsPassedForProcessing"];
	StatisticsDuration = ExecutionStatistics["HandlerProcedureDuration"];
	
	If StatisticsStart = Undefined Then
		StatisticsStart = New Array;
		ExecutionStatistics["HandlerProcedureStart"] = StatisticsStart;
	EndIf;
	
	If StatisticsCompletion = Undefined Then
		StatisticsCompletion = New Array;
		ExecutionStatistics["HandlerProcedureCompletion"] = StatisticsCompletion;
	EndIf;
	
	If DataStatisticsToProcess = Undefined Then
		DataStatisticsToProcess = New Array;
		ExecutionStatistics["TotalObjectsPassedForProcessing"] = DataStatisticsToProcess;
	EndIf;
	
	If StatisticsDuration = Undefined Then
		StatisticsDuration = New Array;
		ExecutionStatistics["HandlerProcedureDuration"] = StatisticsDuration;
	EndIf;
	
	StatisticsStart.Add(ExecutionStarted);
	StatisticsCompletion.Add(ExecutionCompletion);
	DataStatisticsToProcess.Add(TotalObjectsPassedForProcessing);
	StatisticsDuration.Add(HandlerProcedureDuration);
	
	HandlerProperty(HandlerUpdates.HandlerName,
		"ExecutionStatistics",
		New ValueStorage(ExecutionStatistics));
	
EndProcedure

// Handler for the delayed update thread crash.
//
// Parameters:
//  Stream - See NewThreadsDetails
//  ErrorInfo - ErrorInfo -  description of the error that occurred.
//
Procedure OnDeferredHandlerThreadAbnormalTermination(Stream, ErrorInfo) Export
	
	HandlerUpdates = HandlerUpdates(Stream.ProcedureParameters.HandlerName);
	HandlerProperty(HandlerUpdates.HandlerName, "BatchProcessingCompleted", True);
	ProcessHandlerException(Stream.ProcedureParameters, HandlerUpdates, ErrorInfo);
	
	If HandlerUpdates.Multithreaded Then
		CancelUpdatingDataOfMultithreadHandler(Stream, HandlerUpdates);
	EndIf;
	
	HandlerContext = Stream.CompletionProcedureParameters;
	EndDeferredUpdateHandlerExecution(HandlerContext);
	
EndProcedure

// Handler to cancel execution of the thread.
//
// Parameters:
//  Stream - See NewThreadsDetails
//
Procedure OnCancelDeferredHandlerThread(Stream) Export
	
	HandlerUpdates = HandlerUpdates(Stream.ProcedureParameters.HandlerName);
	HandlerProperty(HandlerUpdates.HandlerName, "BatchProcessingCompleted", True);
	
	If HandlerUpdates.Status = Enums.UpdateHandlersStatuses.Running Then
		SetHandlerStatus(HandlerUpdates.HandlerName, "NotPerformed");
	EndIf;
	
	If HandlerUpdates.Multithreaded Then
		CancelUpdatingDataOfMultithreadHandler(Stream, HandlerUpdates);
	EndIf;
	
EndProcedure

// Load the result of the handler execution from temporary storage to the context of the update handler.
//
// Parameters:
//  HandlerContext - See NewHandlerContext
//  ResultAddress - String -  address of the result in temporary storage.
//
Procedure ImportHandlerExecutionResult(HandlerContext, ResultAddress)
	
	If ResultAddress <> Undefined Then
		Result = GetFromTempStorage(ResultAddress); // See NewDeferredHandlerResult
	Else
		Result = Undefined;
	EndIf;
	
	If Result <> Undefined Then
		If HandlerContext.WriteToLog1 Then
			HandlerContext.HandlerFullDetails.Parameters = Result.Parameters;
		EndIf;
		
		HandlerContext.HasOpenTransactions = Result.HasOpenTransactions;
		HandlerContext.HandlerProcedureCompletion = Result.HandlerProcedureCompletion;
		HandlerContext.ErrorInfo = Result.ErrorInfo;
		HandlerContext.HandlerProcedureStart = Result.HandlerProcedureStart;
		HandlerContext.TotalObjectsPassedForProcessing = Result.TotalObjectsPassedForProcessing;
		HandlerContext.Parameters = Result.Parameters;
		HandlerContext.UpdateHandlerParameters = Result.UpdateHandlerParameters;
	EndIf;
	
EndProcedure

Procedure DeleteAllUpdateThreads()
	
	RecordSet = InformationRegisters.UpdateThreads.CreateRecordSet();
	RecordSet.Write();
	
EndProcedure

// Context for executing the update handler.
//
// Returns:
//  Structure - :
//   * ExecuteHandler - Boolean -  if True, the handler is ready for execution.
//   * HandlerFullDetails - See PrepareUpdateProgressDetails
//   * HandlerProcedureCompletion - Number -  completion of the data processing procedure.
//   * WriteToLog1 - Boolean - see Constants.Itemize the update of the Registration log.
//   * StartedWithoutErrors - Boolean -  if True, no exceptions occurred when the handler was started.
//   * HandlerID - UUID -  ID of the update handler.
//   * HandlerName - String -  name of the update handler.
//   * UpdateCycleDetailsIndex - Number -  index of the update plan element.
//   * CurrentUpdateCycleIndex - Number -  index of the current update plan element.
//   * DataProcessingStart - Date -  start time of the update handler execution.
//   * HandlerProcedureStart - Number -  start of the data processing procedure.
//   * TotalObjectsPassedForProcessing - Number -  the number of objects passed for processing.
//   * ParallelMode - Boolean -  indicates whether the update handler is running in parallel mode.
//   * Parameters - Structure - :
//      ** DataToUpdate - See NewBatchForUpdate
//   * ParametersOfUpdate - Structure -  description of update parameters.
//   * UpdateHandlerParameters - see the session parameters.Parameters of the Update Handler
//   * SkipProcessedDataCheck - Boolean -  skip checking in the rib slave node.
//   * CurrentUpdateIteration - Number -  number of the current update iteration.
//   * TransactionActiveAtExecutionStartTime - Boolean -  state of transaction activity before executing the handler.
//   * SubsystemVersionAtStartUpdates - String - 
//                                                   
//
Function NewHandlerContext()
	
	HandlerContext = New Structure;
	
	HandlerContext.Insert("ExecuteHandler", False);
	HandlerContext.Insert("HandlerFullDetails");
	HandlerContext.Insert("HasOpenTransactions", False);
	HandlerContext.Insert("HandlerProcedureCompletion");
	HandlerContext.Insert("WriteToLog1");
	HandlerContext.Insert("StartedWithoutErrors", False);
	HandlerContext.Insert("HandlerID");
	HandlerContext.Insert("HandlerName");
	HandlerContext.Insert("UpdateCycleDetailsIndex");
	HandlerContext.Insert("CurrentUpdateCycleIndex");
	HandlerContext.Insert("ErrorInfo");
	HandlerContext.Insert("DataProcessingStart");
	HandlerContext.Insert("HandlerProcedureStart");
	HandlerContext.Insert("TotalObjectsPassedForProcessing");
	HandlerContext.Insert("ParallelMode");
	HandlerContext.Insert("Parameters");
	HandlerContext.Insert("ParametersOfUpdate");
	HandlerContext.Insert("UpdateHandlerParameters");
	HandlerContext.Insert("SkipProcessedDataCheck", False);
	HandlerContext.Insert("CurrentUpdateIteration");
	HandlerContext.Insert("TransactionActiveAtExecutionStartTime");
	HandlerContext.Insert("SubsystemVersionAtStartUpdates");
	
	Return HandlerContext;
	
EndFunction

// Add fields for the multithreaded handler to the handler context.
//
// Parameters:
//  HandlerContext - See NewHandlerContext
//
Procedure SupplementMultithreadHandlerContext(HandlerContext)
	
	HandlerContext.Parameters.Insert("DataToUpdate");
	
EndProcedure

// The result of executing a deferred update handler to pass to the completion procedure
// in the control thread.
//
// Returns:
//  Structure:
//   * HasOpenTransactions - Boolean -  indicates whether there are non-closed transactions in the handler itself.
//   * HandlerProcedureCompletion - Number -  time when the update handler procedure completed.
//   * ErrorInfo - String -  description of the error (if any).
//   * HandlerProcedureStart - Number -  start time of the update handler procedure.
//   * TotalObjectsPassedForProcessing - Number -  the number of objects passed for processing.
//   * Parameters - Structure -  parameters passed to the update handler.
//   * UpdateHandlerParameters - FixedStructure -  the value of the session option
//                                      Parameters of the update handler.
//
Function NewDeferredHandlerResult()
	
	Result = New Structure;
	Result.Insert("HasOpenTransactions", False);
	Result.Insert("HandlerProcedureCompletion");
	Result.Insert("ErrorInfo");
	Result.Insert("HandlerProcedureStart");
	Result.Insert("TotalObjectsPassedForProcessing");
	Result.Insert("Parameters");
	Result.Insert("UpdateHandlerParameters");
	
	Return Result;
	
EndFunction

// The default number of update threads.
//
// Returns:
//  Number - 
//          
//
Function DefaultInfobaseUpdateThreadsCount()
	
	Parameters = SubsystemSettings();
	Return Parameters.DefaultInfobaseUpdateThreadsCount;
	
EndFunction

// To determine the priority of the updates.
//
// Parameters:
//  UpdateInfo - See InfobaseUpdateInfo
//
// Returns:
//  Boolean - 
//
Function ForceUpdate(UpdateInfo)
	
	If Not Common.DataSeparationEnabled() Then
		ClientLaunchParameter = StandardSubsystemsServer.ClientParametersAtServer().Get("LaunchParameter");
		If StrFind(Lower(ClientLaunchParameter), Lower("ForceDeferredUpdate")) > 0 Then
			Return True;
		Else
			Return UpdateInfo.DeferredUpdateManagement.Property("ForceUpdate");
		EndIf;
	Else
		Priority = Undefined;
		SSLSubsystemsIntegration.OnGetUpdatePriority(Priority);
		
		If Priority = "UserWork" Then
			Return False;
		ElsIf Priority = "DataProcessing" Then
			Return True;
		Else
			Return UpdateInfo.DeferredUpdateManagement.Property("ForceUpdate");
		EndIf;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Procedure SaveUpdateThread(Stream)
	
	RecordSet = InformationRegisters.UpdateThreads.CreateRecordSet();
	Id = Stream.ThreadID;
	If Not ValueIsFilled(Id) Then
		Id = New UUID;
	EndIf;
	RecordSet.Filter.ThreadID.Set(Id);
	RecordSet.Read();
	
	If RecordSet.Count() = 0 Then
		Record = RecordSet.Add();
	Else
		Record = RecordSet[0];
	EndIf;
	
	FillPropertyValues(Record, Stream, , "ThreadID,ProcedureParameters,CompletionProcedureParameters");
	Record.ThreadID = Id;
	Record.ProcedureParameters = New ValueStorage(Stream.ProcedureParameters);
	Record.CompletionProcedureParameters = New ValueStorage(Stream.CompletionProcedureParameters);
	
	RecordSet.Write();
	
EndProcedure

Procedure DeleteUpdateThread(ThreadID)
	
	RecordSet = InformationRegisters.UpdateThreads.CreateRecordSet();
	RecordSet.Filter.ThreadID.Set(ThreadID);
	RecordSet.Write();
	
EndProcedure

Function UpdateThreads()
	
	ThreadsTable = NewThreadsDetails();
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	UpdateThreads.ResultAddress AS ResultAddress,
		|	UpdateThreads.Group AS Group,
		|	UpdateThreads.Description AS Description,
		|	UpdateThreads.ProcedureParameters AS ProcedureParameters,
		|	UpdateThreads.CompletionProcedureParameters AS CompletionProcedureParameters,
		|	UpdateThreads.CompletionPriority AS CompletionPriority,
		|	UpdateThreads.JobID AS JobID,
		|	UpdateThreads.ThreadID AS ThreadID
		|FROM
		|	InformationRegister.UpdateThreads AS UpdateThreads";
	Result = Query.Execute().Unload();
	For Each Stream In Result Do
		String = ThreadsTable.Add();
		FillPropertyValues(String, Stream, , "ProcedureParameters,CompletionProcedureParameters");
		If Not ValueIsFilled(String.ResultAddress) Then
			String.ResultAddress = Undefined;
		EndIf;
		String.CompletionProcedureParameters = Stream.CompletionProcedureParameters.Get();
		String.ProcedureParameters = Stream.ProcedureParameters.Get();
	EndDo;
	Return ThreadsTable;
	
EndFunction

// Execute the specified thread.
//
// Parameters:
//  Groups - Map
//  Stream - ValueTableRow of See NewThreadsDetails
//  FormIdentifier - UUID -  ID of the form, if any.
//
Procedure ExecuteThread(Groups, Stream, FormIdentifier = Undefined)
	
	ThreadDetails = Groups[Stream.Group];
	
	If Not IsBlankString(ThreadDetails.Procedure) And Stream.ProcedureParameters <> Undefined Then
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormIdentifier);
		ExecutionParameters.BackgroundJobDescription = Stream.Description;
		ExecutionParameters.WaitCompletion = 0;
		
		If FormIdentifier = Undefined Then
			ExecutionParameters.ResultAddress = PutToTempStorage(Undefined, New UUID);
		EndIf;
		
		RunResult = TimeConsumingOperations.ExecuteInBackground(ThreadDetails.Procedure,
			Stream.ProcedureParameters,
			ExecutionParameters);
		
		Stream.ResultAddress = RunResult.ResultAddress;
		Status = RunResult.Status;
		
		If Status = "Running" Then
			Stream.JobID = RunResult.JobID;
		ElsIf Status <> "Running" And Status <> "Completed2" Then
			Refinement = CommonClientServer.ExceptionClarification(RunResult.ErrorInfo);
			Raise(Refinement.Text, Refinement.Category,,, RunResult.ErrorInfo);
		EndIf;
	EndIf;
	
	SaveUpdateThread(Stream);
	
EndProcedure

// Terminates threads that have completed their background tasks.
//
// Parameters:
//  Threads - See NewThreadsDetails
//  Groups - Map
//
// Returns:
//  Boolean - 
//
Function StopThreadsWithCompletedBackgroundJobs(Threads, Groups)
	
	HasCompletedThreads = False;
	Threads.Sort("CompletionPriority Desc");
	IndexOf = Threads.Count() - 1;
	
	While IndexOf >= 0 Do
		Stream = Threads[IndexOf];
		ThreadDetails = Groups[Stream.Group];
		JobID = Stream.JobID;
		
		If ValueIsFilled(JobID) Then
			Try
				JobCompleted = TimeConsumingOperations.JobCompleted(JobID);
			Except
				ErrorInfo = ErrorInfo();
				JobCompleted = Undefined;
				
				If IsBlankString(ThreadDetails.OnAbnormalTermination) Then
					Raise;
				EndIf;

				CallParameters = New Array;
				CallParameters.Add(Stream);
				CallParameters.Add(ErrorInfo);
				Common.ExecuteConfigurationMethod(ThreadDetails.OnAbnormalTermination, CallParameters);
			EndTry;
		EndIf;
		
		If Not ValueIsFilled(JobID) Or JobCompleted <> False Then
			ExecuteJob = Not IsBlankString(ThreadDetails.CompletionProcedure)
			          And Stream.CompletionProcedureParameters <> Undefined
			          And (Not ValueIsFilled(JobID) Or JobCompleted = True)
			          And Stream.ResultAddress <> Undefined;
			
			If ExecuteJob Then
				CallParameters = New Array;
				CallParameters.Add(Stream.CompletionProcedureParameters);
				CallParameters.Add(Stream.ResultAddress);
				
				Common.ExecuteConfigurationMethod(ThreadDetails.CompletionProcedure, CallParameters);
			EndIf;
			
			If Stream.ResultAddress <> Undefined Then
				DeleteFromTempStorage(Stream.ResultAddress);
			EndIf;
			DeleteUpdateThread(Stream.ThreadID);
			Threads.Delete(Stream);
			HasCompletedThreads = True;
		EndIf;
		
		IndexOf = IndexOf - 1;
	EndDo;
	
	Return HasCompletedThreads;
	
EndFunction

// Wait for all threads to complete.
//
// Parameters:
//  Groups - Map
//
Procedure WaitForAllThreadsCompletion(Groups)
	
	Threads = UpdateThreads();
	
	While Threads.Count() > 0 Do
		If Not StopThreadsWithCompletedBackgroundJobs(Threads, Groups) Then
			WaitForThreadCompletion(Threads[0]);
		EndIf;
	EndDo;
	
EndProcedure

// Wait for any thread to finish.
//
// Parameters:
//  Groups - Map
//
Procedure WaitForAnyThreadCompletion(Groups)
	
	Threads = UpdateThreads();
	ThreadsCount = Threads.Count();
	
	While ThreadsCount > 0 And Threads.Count() >= ThreadsCount Do
		If Not StopThreadsWithCompletedBackgroundJobs(Threads, Groups) Then
			WaitForThreadCompletion(Threads[0]);
		EndIf;
	EndDo;
	
EndProcedure

// Wait until the number of running threads is less than the maximum.
//
// Parameters:
//  Groups - Map
//
Procedure WaitForAvailableThread(Groups)
	
	MaxThreads = InfobaseUpdateThreadCount();
	
	Threads = UpdateThreads();
	
	While Threads.Count() >= MaxThreads Do
		If StopThreadsWithCompletedBackgroundJobs(Threads, Groups) Then
			Continue;
		EndIf;
		
		WaitForThreadCompletion(Threads[0]);
		MaxThreads = InfobaseUpdateThreadCount();
	EndDo;
	
EndProcedure

// Cancel execution of threads if they are active.
//
// Parameters:
//  Groups - Map
//
Procedure CancelAllThreadsExecution(Groups) Export
	
	Threads = UpdateThreads();
	For Each Stream In Threads Do
		ThreadDetails = Groups[Stream.Group];
		
		If ValueIsFilled(Stream.JobID) Then
			TimeConsumingOperations.CancelJobExecution(Stream.JobID);
		EndIf;
		
		If ThreadDetails.OnCancelThread <> Undefined Then
			CallParameters = New Array;
			CallParameters.Add(Stream);
			Common.ExecuteConfigurationMethod(ThreadDetails.OnCancelThread, CallParameters);
		EndIf;
		
		DeleteUpdateThread(Stream.ThreadID);
	EndDo;
	
EndProcedure

// Description of the thread group.
//
// Returns:
//  Structure - :
//   * Procedure - String - :
//                 
//                   
//                   
//   * CompletionProcedure - String - :
//                           
//                             
//                             
//                             
//   * OnAbnormalTermination - String - :
//                              
//                                 See NewThreadsDetails
//                                
//                                
//   * OnCancelThread - String - :
//                       
//                          See NewThreadsDetails
//                         
//
Function NewThreadsGroupDetails()
	
	LongDesc = New Structure;
	LongDesc.Insert("Procedure");
	LongDesc.Insert("CompletionProcedure");
	LongDesc.Insert("OnAbnormalTermination");
	LongDesc.Insert("OnCancelThread");
	
	Return LongDesc;
	
EndFunction

// Description of the thread group.
//
// Returns:
//  ValueTable:
//     * Groups - Map of KeyAndValue - :
//       ** Key - String -  group name.
//       ** Value - See NewThreadsGroupDetails
//     * Threads - ValueTable - :
//       ** Description - String -  custom thread name (used in the name of the background task).
//       ** Group - String -  name of the group with a description of the stream.
//       ** JobID - UUID -  unique ID of the background task.
//       ** ProcedureParameters - Arbitrary -  parameters for the Procedure.
//       ** CompletionProcedureParameters - Arbitrary -  parameters for the completion Procedure.
//       ** ResultAddress - String -  address of the temporary storage to save the result of the background task.
//
Function NewThreadsDetails()
	
	Threads = New ValueTable;
	Columns = Threads.Columns;
	Columns.Add("Description");
	Columns.Add("Group");
	Columns.Add("CompletionPriority", New TypeDescription("Number"));
	Columns.Add("JobID");
	Columns.Add("ThreadID");
	Columns.Add("ProcedureParameters");
	Columns.Add("CompletionProcedureParameters");
	Columns.Add("ResultAddress");
	
	Return Threads;
	
EndFunction

// Wait for the thread to finish within the specified duration.
//
// Parameters:
//   Stream - ValueTableRow of See NewThreadsDetails
//   Duration - Number -  maximum waiting time, in seconds.
//
// Returns:
//  Boolean - 
//
Function WaitForThreadCompletion(Stream, Duration = 1)
	
	If ValueIsFilled(Stream.JobID) Then
		Job = BackgroundJobs.FindByUUID(Stream.JobID);
		
		If Job <> Undefined Then
			Job = Job.WaitForExecutionCompletion(Duration);
			IsJobCompleted = (Job.State <> BackgroundJobState.Active);
			Return IsJobCompleted;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Find a portion of the data for the handler thread updates.
//
// Parameters:
//  SearchParameters - See NewBatchSearchParameters
//  ResultAddress - String -  address of the result of the procedure. Returns a table of values.
//
Procedure FindBatchToUpdate(SearchParameters, ResultAddress) Export
	
	SelectionParameters = SearchParameters.SelectionParameters;
	CheckSelectionParameters(SelectionParameters);
	SelectionParameters.MaxSelection = InfobaseUpdate.MaxRecordsCountInSelection();
	OrderFields = OrderingFieldsOnSearchBatches(SearchParameters);
	SelectionParameters.OrderFields = OrderFields;
	SelectionParameters.OptimizeSelectionByPages = Not HasOrderingByExternalTables(OrderFields);
	Maximum = InfobaseUpdate.MaxRecordsCountInSelection();
	IterationParameters = DataIterationParametersForUpdate(SearchParameters);
	
	If Not SearchFromBegin(SearchParameters) And Not IsBatchProcessing(SearchParameters) Then
		NextIterationParameters(IterationParameters, False);
	EndIf;

	Iterator = CurrentIterationParameters(IterationParameters);
	SearchResult = NewBatchSearchResult();
	DataSet = NewDataSetForUpdate();
	SearchResult.DataSet = DataSet;
	SelectionParameters = SearchParameters.SelectionParameters;
	AdditionalDataSources = SelectionParameters.AdditionalDataSources;
	Queue = SearchParameters.Queue;
	
	While Iterator <> Undefined Do
		RefObject1 = Iterator.RefObject1;
		TabularObject = Iterator.TabularObject;
		SetSelectionStartBorder(SearchParameters, Iterator.RefIndex, Iterator.TabularIndex);
		SetSelectionEndBorder(SearchParameters, RefObject1, TabularObject);
		MaxSelection = SelectionParameters.MaxSelection;
		SelectionParameters.AdditionalDataSources = InfobaseUpdate.DataSources(
			AdditionalDataSources,
			RefObject1,
			TabularObject);
		
		// 
		// 
		If Not SelectionParameters.Property("UpdateHandlerParameters") Then
			SelectionParameters.Insert("UpdateHandlerParameters", SearchParameters.HandlerContext.UpdateHandlerParameters);
		EndIf;
		Data = SelectBatchData(SelectionParameters, Queue, RefObject1, TabularObject);
		
		If SelectionParameters.UpdateHandlerParameters.IsUpToDateDataProcessed = True Then
			SearchResult.IsUpToDateDataProcessed = True;
		ElsIf SelectionParameters.UpdateHandlerParameters.ProcessedRecordersTables <> Undefined Then
			SearchResult.ProcessedRecordersTables = SelectionParameters.UpdateHandlerParameters.ProcessedRecordersTables;
		EndIf;
		
		Count = Data.Count();
		SearchResult.Count = SearchResult.Count + Count;
		SelectionParameters.MaxSelection = SelectionParameters.MaxSelection - Count;
		
		If Count > 0 Then
			SetRecord = DataSet.Add();
			SetRecord.RefObject1 = RefObject1;
			SetRecord.TabularObject = TabularObject;
			SetRecord.Data = Data;
		EndIf;
		
		If SearchResult.Count < Maximum Then
			NextIterationParameters(IterationParameters, Count = MaxSelection);
			Iterator = CurrentIterationParameters(IterationParameters);
		Else
			Break;
		EndIf;
	EndDo;
	
	SelectionParameters.AdditionalDataSources = AdditionalDataSources;
	SearchResult.SearchCompleted = (Iterator = Undefined);
	PutToTempStorage(SearchResult, ResultAddress);
	
EndProcedure

// Check whether the update handler data selection parameters are filled in correctly.
//
// Parameters:
//   SelectionParameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters
//
Procedure CheckSelectionParameters(SelectionParameters)
	
	SelectionMethod = SelectionParameters.SelectionMethod;
	KnownMethod = (SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements())
	              Or (SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod())
	              Or (SelectionMethod = InfobaseUpdate.RefsSelectionMethod());
	If Not KnownMethod Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"en = 'Specify a selection method in the update data registration procedure
			|in ""%1"".
			|The current selection method is invalid: ""%2"".';"),
			SelectionMethod, "Parameters.SelectionParameters.SelectionMethod");
		Raise(MessageText, ErrorCategory.ConfigurationError);
	EndIf;
	
	TablesSpecified = Not IsBlankString(SelectionParameters.FullNamesOfObjects)
	             Or Not IsBlankString(SelectionParameters.FullRegistersNames);
	If Not TablesSpecified Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"en = 'Specify tables to be processed in the update data registration procedure
			|in ""%1"" and/or
			|""%2"".';"),
			"Parameters.SelectionParameters.FullNamesOfObjects", "Parameters.SelectionParameters.FullRegistersNames");
		Raise(MessageText, ErrorCategory.ConfigurationError);
	EndIf;
	
EndProcedure

// Set the border for the beginning of the portion selection.
//
// Parameters:
//  SearchParameters - See NewBatchSearchParameters
//  RefIndex - Number -  iteration number for reference objects.
//  TabularIndex - Number -  the number of the iteration objects on the table.
//
Procedure SetSelectionStartBorder(SearchParameters, RefIndex, TabularIndex)
	
	SelectionParameters = SearchParameters.SelectionParameters;
	LastSelectedRecord = SearchParameters.LastSelectedRecord;
	FirstRecord = SearchParameters.FirstRecord;
	
	If RefIndex = 0 And TabularIndex = 0 Then // 
		SelectionParameters.LastSelectedRecord = LastSelectedRecord;
		SelectionParameters.FirstRecord = FirstRecord;
	Else // 
		SelectionParameters.LastSelectedRecord = Undefined;
		SelectionParameters.FirstRecord = Undefined;
	EndIf;
	
EndProcedure

// Set the limit for the end of the portion selection.
//
// Parameters:
//  SearchParameters - See NewBatchSearchParameters
//  RefObject1 - String -  full name of the metadata reference object.
//  TabularObject - String -  full name of the metadata table object.
//
Procedure SetSelectionEndBorder(SearchParameters, RefObject1, TabularObject)
	
	SelectionParameters = SearchParameters.SelectionParameters;
	LatestRecord = SearchParameters.LatestRecord;
	IsLastObject = LatestRecord <> Undefined
	                   And RefObject1 = LatestRecord[0].Value
	                   And TabularObject = LatestRecord[1].Value;
	
	If IsLastObject Then // 
		SelectionParameters.LatestRecord = LatestRecord;
	Else // 
		SelectionParameters.LatestRecord = Undefined;
	EndIf;
	
EndProcedure

// Select these portions using the specified method.
//
// Parameters:
//  SelectionParameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters
//  Queue - Number -  queue number.
//  RefObject1 - String -  full name of the metadata reference object.
//  TabularObject - String -  full name of the metadata table object.
//
// Returns:
//  ValueTable -  the data portions.
//
Function SelectBatchData(SelectionParameters, Queue, RefObject1, TabularObject)
	
	SelectionMethod = SelectionParameters.SelectionMethod;
	
	If SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements() Then
		Data = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(
			Queue,
			TabularObject,
			SelectionParameters);
	ElsIf SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod() Then
		Data = InfobaseUpdate.SelectRegisterRecordersToProcess(
			Queue,
			?(IsBlankString(RefObject1), Undefined, RefObject1),
			TabularObject,
			SelectionParameters);
	ElsIf SelectionMethod = InfobaseUpdate.RefsSelectionMethod() Then
		Data = InfobaseUpdate.SelectRefsToProcess(
			Queue,
			RefObject1,
			SelectionParameters);
	EndIf;
	
	Return Data;
	
EndFunction

// 
//
// Parameters:
//  SearchParameters - See NewBatchSearchParameters
//
// Returns:
//  Boolean - 
//
Function IsBatchProcessing(SearchParameters)
	
	Return SearchParameters.LastSelectedRecord = Undefined
	      And SearchParameters.FirstRecord <> Undefined
	      And SearchParameters.LatestRecord <> Undefined;
	
EndFunction

// To prepare the bypass settings data to update.
// In fact, find the border of the beginning of the selection (the place where you stopped last time).
//
// Parameters:
//  SearchParameters - See NewBatchSearchParameters
//
// Returns:
//  Structure - :
//   
//   
//   
//
Function DataIterationParametersForUpdate(SearchParameters)
	
	LastSelectedRecord = SearchParameters.LastSelectedRecord;
	FirstRecord = SearchParameters.FirstRecord;
	SelectionParameters = SearchParameters.SelectionParameters;
	FullNamesOfObjects = SelectionParameters.FullNamesOfObjects;
	FullRegistersNames = SelectionParameters.FullRegistersNames;
	FullRegistersNamesStart = FullRegistersNames;
	
	If LastSelectedRecord <> Undefined Then // 
		FirstReferenced = LastSelectedRecord[0].Value;
		FirstTabular = LastSelectedRecord[1].Value;
	ElsIf FirstRecord <> Undefined Then // 
		FirstReferenced = FirstRecord[0].Value;
		FirstTabular = FirstRecord[1].Value;
	Else // 
		FirstReferenced = Undefined;
		FirstTabular = Undefined;
	EndIf;
	
	If Not IsBlankString(FullNamesOfObjects) And Not IsBlankString(FirstReferenced) Then // 
		// 
		FullObjectNamesArray = TheRemainderOfTheArray(FullNamesOfObjects, FirstReferenced);
	Else
		FullObjectNamesArray = StrSplitTrimAll(FullNamesOfObjects, ",");
	EndIf;
	
	If Not IsBlankString(FullRegistersNamesStart) And Not IsBlankString(FirstTabular) Then // 
		// 
		FullRegisterNamesStartArray = TheRemainderOfTheArray(FullRegistersNamesStart, FirstTabular);
	Else
		FullRegisterNamesStartArray = StrSplitTrimAll(FullRegistersNamesStart, ",");
	EndIf;
	
	Result = New Structure;
	Result.Insert("RefObjects", FullObjectNamesArray);
	Result.Insert("TabularObjectsAll", StrSplitTrimAll(FullRegistersNames, ","));
	Result.Insert("TabularObjectsBeginning", FullRegisterNamesStartArray);
	Result.Insert("RefIndex", 0);
	Result.Insert("TabularIndex", 0);
	
	Return Result;
	
EndFunction

// 
//
// Parameters:
//  SearchParameters - See NewBatchSearchParameters
//
// Returns:
//  Boolean - 
//           
//
Function SearchFromBegin(SearchParameters)
	
	Return SearchParameters.LastSelectedRecord = Undefined
	      And SearchParameters.FirstRecord = Undefined
	      And SearchParameters.LatestRecord = Undefined;
	
EndFunction

// Get the next batch of data crawl parameters to update.
//
// Parameters:
//  IterationParameters - See DataIterationParametersForUpdate
//
// Returns:
//   Structure - :
//    * RefObject1 - String -  the name of the reference object.
//    * TabularObject - String -  the name of the tabular object.
//   Undefined - if the crawl is finished.
//
Function CurrentIterationParameters(IterationParameters)
	
	If IterationParameters.RefIndex < IterationParameters.RefObjects.Count() Then
		If IterationParameters.RefIndex = 0 Then
			TabularObjects = IterationParameters.TabularObjectsBeginning;
		Else
			TabularObjects = IterationParameters.TabularObjectsAll;
		EndIf;
		
		If IterationParameters.TabularIndex < TabularObjects.Count() Then
			RefObject1 = IterationParameters.RefObjects[IterationParameters.RefIndex];
			TabularObject = TabularObjects[IterationParameters.TabularIndex];
			
			Result = New Structure;
			Result.Insert("RefObject1", RefObject1);
			Result.Insert("TabularObject", TabularObject);
			Result.Insert("RefIndex", IterationParameters.RefIndex);
			Result.Insert("TabularIndex", IterationParameters.TabularIndex);
			
			Return Result;
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Go to the next selection parameters if no records with the current parameters were selected.
//
// Parameters:
//  IterationParameters - See DataIterationParametersForUpdate
//  FullSelection - Boolean -  True if the maximum number of records is selected.
//  
Procedure NextIterationParameters(IterationParameters, FullSelection)
	
	If Not FullSelection Then
		If IterationParameters.RefIndex = 0 Then
			TabularObjects = IterationParameters.TabularObjectsBeginning;
		Else
			TabularObjects = IterationParameters.TabularObjectsAll;
		EndIf;
		
		If IterationParameters.TabularIndex = TabularObjects.UBound() Then
			IterationParameters.TabularIndex = 0;
			IterationParameters.RefIndex = IterationParameters.RefIndex + 1;
		Else
			IterationParameters.TabularIndex = IterationParameters.TabularIndex + 1;
		EndIf;
	EndIf;
	
EndProcedure

// Get ordering fields for the specified portion search parameters.
//
// Parameters:
//  SearchParameters - See NewBatchSearchParameters
//
// Returns:
//  String - 
//
Function OrderingFieldsOnSearchBatches(SearchParameters)
	
	SelectionParameters = SearchParameters.SelectionParameters;
	Return ?(SearchParameters.ForceUpdate,
		SelectionParameters.OrderingFieldsOnProcessData,
		SelectionParameters.OrderingFieldsOnUserOperations);
	
EndFunction

// Determine whether there is an ordering by fields of the attached tables.
//
// Parameters:
//  OrderFields - Array -  ordering fields.
//
// Returns:
//  Boolean - 
//
Function HasOrderingByExternalTables(OrderFields)
	
	For Each OrderField In OrderFields Do
		If StrFind(OrderField, ".") > 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Get the search result, split it into chunks, and start updating streams.
//
// Parameters:
//  SearchParameters - See NewBatchSearchParameters
//  ResultAddress - String -  address of the result of naytiportionfor Updating
//  Swedenlithuania -  See InfobaseUpdateInfo
//
Procedure EndSearchForBatchToUpdate(SearchParameters, ResultAddress) Export
	
	SearchResult = GetFromTempStorage(ResultAddress);
	Groups = NewDetailsOfDeferredUpdateHandlersThreadsGroups();
	HandlerContext = SearchParameters.HandlerContext;
	
	HandlerUpdates = HandlerUpdates(HandlerContext.HandlerName);
	FillingProcedureDetails = HandlerUpdates.DataToProcess.Get();
	BatchesToUpdate = FillingProcedureDetails.BatchesToUpdate; // See NewBatchesTableForUpdate
	BatchID = SearchParameters.BatchID;
	HasID = BatchID <> Undefined;
	OldBatch = ?(HasID, BatchesToUpdate.Find(BatchID, "Id"), Undefined);
	IsFirstSearch = SearchParameters.LastSelectedRecord = Undefined
	               And SearchParameters.FirstRecord = Undefined
	               And SearchParameters.LatestRecord = Undefined;
	IsDuplicateSearch = SearchParameters.FirstRecord <> Undefined
	                  And SearchParameters.LatestRecord <> Undefined;
	
	If IsFirstSearch Then
		SaveFirstSearchResult(SearchResult, FillingProcedureDetails);
		BatchesToUpdate = FillingProcedureDetails.BatchesToUpdate;
	ElsIf IsDuplicateSearch Then
		SaveRepeatedSearchResult(SearchResult, FillingProcedureDetails, BatchID);
	Else
		SaveSearchResult(SearchResult, FillingProcedureDetails);
	EndIf;
	
	If SearchResult.Count > 0 Then
		MaxThreads = InfobaseUpdateThreadCount();
		UpdateThreads = UpdateThreads();
		AvailableThreads = MaxThreads - UpdateThreads.Count() + 1;
		If AvailableThreads = 0 Then
			AvailableThreads = 1;
		EndIf;
		Particles = SplitSearchResultIntoParticles(SearchResult, AvailableThreads);
		ParticlesCount = Particles.Count();
		
		For ParticleNumber = 0 To ParticlesCount - 1 Do
			Particle = Particles[ParticleNumber];
			HasOldBatch = (ParticleNumber = 0 And OldBatch <> Undefined);
			
			If HasOldBatch Then
				Batch = OldBatch;
				Particle.Id = Batch.Id;
			Else
				Batch = BatchesToUpdate.Add();
				Batch.Id = Particle.Id;
			EndIf;
			
			Batch.FirstRecord = Particle.FirstRecord;
			Batch.LatestRecord = Particle.LatestRecord;
			Batch.InProcessing = True;
			
			// 
			UpdateHandlerParameters = New Structure(HandlerContext.UpdateHandlerParameters);
			UpdateHandlerParameters.KeyRecordProgressUpdates = New UUID;
			If SearchResult.Property("IsUpToDateDataProcessed")
				And SearchResult.IsUpToDateDataProcessed = True Then
				UpdateHandlerParameters.IsUpToDateDataProcessed = True;
			EndIf;
			If SearchResult.Property("ProcessedRecordersTables")
				And SearchResult.ProcessedRecordersTables <> Undefined Then
				UpdateHandlerParameters.ProcessedRecordersTables = SearchResult.ProcessedRecordersTables;
			EndIf;
			HandlerContext.UpdateHandlerParameters = New FixedStructure(UpdateHandlerParameters);
			ProcessDataFragmentInThread(Particle, Groups, HandlerContext);
		EndDo;
	Else
		Particle = NewBatchForUpdate();
		Particle.DataSet = NewDataSetForUpdate();
		UpdateHandlerParameters = New Structure(HandlerContext.UpdateHandlerParameters);
		If SearchResult.Property("IsUpToDateDataProcessed")
			And SearchResult.IsUpToDateDataProcessed = True Then
			UpdateHandlerParameters.IsUpToDateDataProcessed = True;
		EndIf;
		
		If SearchResult.Property("ProcessedRecordersTables")
			And SearchResult.ProcessedRecordersTables <> Undefined Then
			UpdateHandlerParameters.ProcessedRecordersTables = SearchResult.ProcessedRecordersTables;
		EndIf;
		HandlerContext.UpdateHandlerParameters = New FixedStructure(UpdateHandlerParameters);
		
		ProcessDataFragmentInThread(Particle, Groups, HandlerContext);
	EndIf;
	
	FillingProcedureDetails.BatchSearchInProgress = False;
	HandlerProperty(HandlerUpdates.HandlerName,
		"DataToProcess",
		New ValueStorage(FillingProcedureDetails));
	
EndProcedure

// Handler for crash execution of the search thread for a portion to update.
//
// Parameters:
//  Stream - See NewThreadsDetails
//  ErrorInfo - ErrorInfo -  description of the error that occurred.
//  Swedenlithuania -  See InfobaseUpdateInfo.
//
Procedure OnBatchToImportSearchThreadAbnormalTermination(Stream, ErrorInfo) Export
	
	HandlerUpdates = HandlerUpdates(Stream.ProcedureParameters.HandlerName);
	LongDesc = HandlerUpdates.DataToProcess.Get();
	LongDesc.BatchSearchInProgress = False;
	HandlerProperty(Stream.ProcedureParameters.HandlerName,
		"DataToProcess",
		New ValueStorage(LongDesc));
	
EndProcedure

// Handler for canceling the execution of the search thread for a portion to update.
//
// Parameters:
//  Stream - See NewThreadsDetails
//  Swedenlithuania -  See InfobaseUpdateInfo
//
Procedure OnCancelSearchBatchToUpdate(Stream) Export
	
	HandlerUpdates = HandlerUpdates(Stream.ProcedureParameters.HandlerName);
	LongDesc = HandlerUpdates.DataToProcess.Get();
	LongDesc.BatchSearchInProgress = False;
	HandlerProperty(Stream.ProcedureParameters.HandlerName,
		"DataToProcess",
		New ValueStorage(LongDesc));
	
EndProcedure

// To complete the data processing, multithreaded processor upgrade.
// Delete the processed portion of data.
//
// Parameters:
//  HandlerContext - See NewHandlerContext
//  Swedenlithuania -  See InfobaseUpdateInfo
//
Procedure CompleteMultithreadHandlerExecution(HandlerContext, HandlerName)
	
	HandlerUpdates = HandlerUpdates(HandlerName);
	
	FillingProcedureDetails = HandlerUpdates.DataToProcess.Get();
	BatchesToUpdate = FillingProcedureDetails.BatchesToUpdate;
	
	If BatchesToUpdate <> Undefined
		And HandlerContext.Parameters.Property("DataToUpdate") Then
		DataToUpdate = HandlerContext.Parameters.DataToUpdate;
		
		If DataToUpdate <> Undefined Then
			Batch = BatchesToUpdate.Find(DataToUpdate.Id, "Id");
			
			If Batch <> Undefined Then
				BatchesToUpdate.Delete(Batch);
			EndIf;
		EndIf;
	EndIf;
	
	HandlerProperty(HandlerUpdates.HandlerName,
		"DataToProcess",
		New ValueStorage(FillingProcedureDetails));
	
EndProcedure

// Cancel data processing for the multithreaded update handler.
// Note that the found portion of data will need to be processed again.
//
// Parameters:
//  Stream - ValueTableRow:
//     * Description - String -  custom thread name (used in the name of the background task).
//     * Group - String -  name of the group with a description of the stream.
//     * JobID - UUID -  unique ID of the background task.
//     * ProcedureParameters - See NewHandlerContext
//     * CompletionProcedureParameters - Arbitrary -  parameters for the completion Procedure.
//     * ResultAddress - String -  address of the temporary storage to save the result of the background task.
//  HandlerUpdates - ValueTreeRow -  update handler as a string in the handler tree.
//  Swedenlithuania -  See InfobaseUpdateInfo
//  
Procedure CancelUpdatingDataOfMultithreadHandler(Stream, HandlerUpdates)
	
	FillingProcedureDetails = HandlerUpdates.DataToProcess.Get();
	BatchesToUpdate = FillingProcedureDetails.BatchesToUpdate;
	
	If BatchesToUpdate <> Undefined Then
		DataToUpdate = Stream.ProcedureParameters.Parameters.DataToUpdate;
		
		If DataToUpdate <> Undefined Then
			Batch = BatchesToUpdate.Find(DataToUpdate.Id, "Id");
			
			If Batch <> Undefined Then
				Batch.InProcessing = False;
			EndIf;
		EndIf;
	EndIf;
	
	HandlerProperty(HandlerUpdates.HandlerName,
		"DataToProcess",
		New ValueStorage(FillingProcedureDetails));
	
EndProcedure

// Save the result of the first data search for a multithreaded handler.
//
// Parameters:
//  SearchResult - See NewBatchSearchResult
//  FillingProcedureDetails - See NewDataToProcessDetails
//
Procedure SaveFirstSearchResult(SearchResult, FillingProcedureDetails)
	
	If SearchResult.Count > 0 Then
		LastSelectedRecord = LastDataSetRowRecordKey(SearchResult.DataSet);
		FillingProcedureDetails.LastSelectedRecord = LastSelectedRecord;
		
		If FillingProcedureDetails.BatchesToUpdate = Undefined Then
			FillingProcedureDetails.BatchesToUpdate = NewBatchesTableForUpdate();
		EndIf;
	Else
		FillingProcedureDetails.LastSelectedRecord = Undefined;
	EndIf;
	
	FillingProcedureDetails.SearchCompleted = SearchResult.SearchCompleted;
	
EndProcedure

// Save the result of repeated (after an error) data search for a multithreaded handler.
//
// Parameters:
//  SearchResult - See NewBatchSearchResult
//  FillingProcedureDetails - See NewDataToProcessDetails
//  BatchID - UUID -  ID of the portion for which data was searched.
//
Procedure SaveRepeatedSearchResult(SearchResult, FillingProcedureDetails, BatchID)
	
	If SearchResult.Count = 0 Then
		BatchesToUpdate = FillingProcedureDetails.BatchesToUpdate;
		Batch = BatchesToUpdate.Find(BatchID, "Id");
		BatchesToUpdate.Delete(Batch);
	EndIf;
	
	FillingProcedureDetails.SearchCompleted = SearchResult.SearchCompleted;
	
	If FillingProcedureDetails.Property("HandlerName") Then
		HandlerProperty(FillingProcedureDetails.HandlerName,
			"DataToProcess",
			New ValueStorage(FillingProcedureDetails));
	EndIf;
	
EndProcedure

// Save the result of a data search for a multithreaded handler.
//
// Parameters:
//  SearchResult - See NewBatchSearchResult
//  FillingProcedureDetails - See NewDataToProcessDetails
//
Procedure SaveSearchResult(SearchResult, FillingProcedureDetails)
	
	If SearchResult.Count > 0 Then
		LastSelectedRecord = LastDataSetRowRecordKey(SearchResult.DataSet);
		FillingProcedureDetails.LastSelectedRecord = LastSelectedRecord;
	EndIf;
	
	FillingProcedureDetails.SearchCompleted = SearchResult.SearchCompleted;
	
EndProcedure

// Split the found data into the specified number of portions.
//
// Parameters:
//  SearchResult - See NewBatchSearchResult
//  ParticlesCount - Number -  the number of fragments to split the data into.
//
// Returns:
//   See NewBatchesSetForUpdate
//
Function SplitSearchResultIntoParticles(SearchResult, Val ParticlesCount)
	
	Particles = NewBatchesSetForUpdate();
	FoundDataSet = SearchResult.DataSet;
	FoundItemsCount = SearchResult.Count;
	ParticlesCount = ?(FoundItemsCount < ParticlesCount, 1, ParticlesCount);
	MaxBatchSize = Int(FoundItemsCount / ParticlesCount);
	ProcessedItemsCount = 0;
	
	For ParticleNumber = 1 To ParticlesCount Do // 
		Particle = NewBatchForUpdate();
		Particle.Id = New UUID;
		Particle.DataSet = NewDataSetForUpdate();
		Particle.LatestRecord = LastDataSetRowRecordKey(FoundDataSet);
		Particles.Insert(0, Particle);
		DataSetIndex = FoundDataSet.Count() - 1;
		FreeJobsCount = ?(ParticleNumber = ParticlesCount,
			FoundItemsCount - ProcessedItemsCount,
			MaxBatchSize);
		
		While DataSetIndex >= 0 Do
			CurrentDataRow = FoundDataSet[DataSetIndex];
			CurrentData = CurrentDataRow.Data;
			CurrentCount = CurrentData.Count();
			ParticleData = Particle.DataSet.Add();
			
			If CurrentCount <= FreeJobsCount Then
				FillPropertyValues(ParticleData, CurrentDataRow);
				FoundDataSet.Delete(DataSetIndex);
				FreeJobsCount = FreeJobsCount - CurrentCount;
				ProcessedItemsCount = ProcessedItemsCount + CurrentCount;
			Else
				FillPropertyValues(ParticleData, CurrentDataRow, "RefObject1, TabularObject");
				StartCutting = CurrentCount - FreeJobsCount;
				ParticleData.Data = CutRowsFromValueTable(CurrentData, StartCutting, FreeJobsCount);
				ProcessedItemsCount = ProcessedItemsCount + FreeJobsCount;
				FreeJobsCount = 0;
			EndIf;
			
			If FreeJobsCount = 0 Then
				Break;
			Else
				DataSetIndex = DataSetIndex - 1;
			EndIf;
		EndDo;
		
		Particle.FirstRecord = LastDataSetRowRecordKey(Particle.DataSet);
	EndDo;
	
	Return Particles;
	
EndFunction

// 
//
// Parameters:
//  Table - ValueTable -  the table from which rows are cut.
//  Begin - Number -  index of the first line to be cut.
//  Count - Number -  the number of rows to cut.
//
// Returns:
//  ValueTable - 
//
Function CutRowsFromValueTable(Table, Begin, Count)
	
	NewTable = Table.CopyColumns();
	IndexOf = Begin + Count - 1;
	
	While IndexOf >= Begin Do
		NewRow = NewTable.Add();
		OldRow = Table[IndexOf];
		FillPropertyValues(NewRow, OldRow);
		Table.Delete(OldRow);
		IndexOf = IndexOf - 1;
	EndDo;
	
	Return NewTable;
	
EndFunction

// Determines whether the handler has portions that can be updated in a new thread.
//
// Parameters:
//  HandlerUpdates - ValueTableRow -  update handler as a string in the handler tree.
//
Function HasBatchesForUpdate(HandlerUpdates)
	
	LongDesc = HandlerUpdates.DataToProcess.Get();
	
	If LongDesc.BatchSearchInProgress Then
		Return False;
	Else
		If LongDesc.BatchesToUpdate <> Undefined And LongDesc.BatchesToUpdate.Count() > 0 Then
			For Each Batch In LongDesc.BatchesToUpdate Do
				If Not Batch.InProcessing Then
					Return True;
				EndIf;
			EndDo;
			
			Return False;
		Else
			Return True;
		EndIf;
	EndIf;
	
EndFunction

// Get the record key of the first row of the data set.
//
// Parameters:
//  DataSet - See NewDataSetForUpdate
//
// Returns:
//  ValueList - 
//
Function FirstDataSetRowRecordKey(DataSet)
	
	FirstDataRow = DataSet[0];
	Return NewRecordKeyFromDataTable(FirstDataRow.RefObject1,
		FirstDataRow.TabularObject,
		FirstDataRow.Data,
		0);
	
EndFunction

// Get the record key for the last row of the data set.
//
// Parameters:
//  DataSet - See NewDataSetForUpdate
//
// Returns:
//  ValueList - 
//
Function LastDataSetRowRecordKey(DataSet)
	
	LastDataRow = DataSet[DataSet.Count() - 1];
	Return NewRecordKeyFromDataTable(LastDataRow.RefObject1,
		LastDataRow.TabularObject,
		LastDataRow.Data,
		LastDataRow.Data.Count() - 1);
	
EndFunction

// A table describing the portions of updated data.
//
// Returns:
//  ValueTable:
//   * Id - UUID -  the ID portion.
//   * FirstRecord - ValueList - :
//     ** Presentation - String -  field name.
//     ** Value - Arbitrary -  value of the key field.
//   * LatestRecord - ValueList - :
//     ** Presentation - String -  field name.
//     ** Value - Arbitrary -  value of the key field.
//   * InProcessing - Boolean -  True if the data update thread is running.
//
Function NewBatchesTableForUpdate()
	
	Table = New ValueTable;
	Columns = Table.Columns;
	Columns.Add("Id", New TypeDescription("UUID"));
	Columns.Add("FirstRecord", New TypeDescription("ValueList"));
	Columns.Add("LatestRecord", New TypeDescription("ValueList"));
	Columns.Add("InProcessing", New TypeDescription("Boolean"));
	Table.Indexes.Add("Id");
	
	Return Table;
	
EndFunction

// Description of the data processed by the update handler (for information about the Update.Processed data).
//
// Parameters:
//  Multithread - Boolean -  The truth is, if used for a multithreaded processor upgrade.
//  Background - Boolean -  True if used to fill in the data of the deferred Handler().
//
// Returns:
//  Structure - :
//   * HandlerData - Map -  data registered and processed by the update handler.
//   * BatchSearchInProgress - Boolean -  indicates whether there is a thread searching for a portion of data to update.
//   * SelectionParameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters
//   * BatchesToUpdate - See NewBatchesTableForUpdate
//   * LastSelectedRecord - ValueList - :
//     ** Presentation - String -  field name.
//     ** Value - Arbitrary -  field value.
//   * SearchCompleted - Boolean -  True, the search will no longer be performed (completed).
//   * ProcessingCompleted - Boolean -  indicates whether processing is complete, which is filled in by the update handler.
//   * HandlerName - String -  name of the update handler.
//   * Queue - Number -  number of the update handler queue.
//   * FillingProcedure - String -  name of the procedure for filling in data for updating.
//   * Status - String -  status of data processing.
//
Function NewDataToProcessDetails(Multithread = False, Background = False) Export
	
	LongDesc = New Structure;
	LongDesc.Insert("HandlerData");
	LongDesc.Insert("HandlerName");
	LongDesc.Insert("UpToDateData");
	LongDesc.Insert("RegisteredRecordersTables");
	LongDesc.Insert("ProcessedRecordersTables");
	LongDesc.Insert("SubsystemVersionAtStartUpdates");
	
	If Multithread Then
		LongDesc.Insert("BatchSearchInProgress", False);
		LongDesc.Insert("SelectionParameters");
		LongDesc.Insert("BatchesToUpdate");
		LongDesc.Insert("LastSelectedRecord");
		LongDesc.Insert("SearchCompleted", False);
	EndIf;
	
	If Background Then
		LongDesc.Insert("Queue");
		LongDesc.Insert("FillingProcedure");
		LongDesc.Insert("Status");
	EndIf;
	
	Return LongDesc;
	
EndFunction

// Selection procedure Nationsinternational().
// If the last selected Record is filled in, the first 10,000 records after it are searched.
// Otherwise, it searches for records between the first Record and the last Record.
//
// Returns:
//  Structure - :
//   * BatchID - UUID -  ID of the portion for which data is being searched.
//   * HandlerContext - See NewHandlerContext
//   * LastSelectedRecord - ValueList - :
//     ** Presentation - String -  field name.
//     ** Value - Arbitrary -  field value.
//   * FirstRecord - ValueList - :
//     ** Presentation - String -  field name.
//     ** Value - Arbitrary -  value of the key field.
//   * LatestRecord - ValueList - :
//     ** Presentation - String -  field name.
//     ** Value - Arbitrary -  value of the key field.
//   * SelectionParameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters
//   * Queue - Number -  number of the handler queue.
//
Function NewBatchSearchParameters()
	
	SearchParameters = New Structure;
	SearchParameters.Insert("BatchID");
	SearchParameters.Insert("HandlerName");
	SearchParameters.Insert("HandlerContext");
	SearchParameters.Insert("LastSelectedRecord");
	SearchParameters.Insert("FirstRecord");
	SearchParameters.Insert("LatestRecord");
	SearchParameters.Insert("SelectionParameters");
	SearchParameters.Insert("Queue");
	SearchParameters.Insert("ForceUpdate", False);
	
	Return SearchParameters;
	
EndFunction

// Key for recording a portion of data.
//
// Parameters:
//  RefObject1 - String -  full name of the reference type metadata object.
//  TabularObject - String -  full name of the table-type metadata object.
//
// Returns:
//  ValueList of String
//
Function NewRecordKey(RefObject1, TabularObject)
	
	RecordKey = New ValueList;
	RecordKey.Add(RefObject1);
	RecordKey.Add(TabularObject);
	
	Return RecordKey;
	
EndFunction

// Key for recording portions from the data table.
//
// Parameters:
//  RefObject1 - String -  full name of the reference type metadata object.
//  TabularObject - String -  full name of the table-type metadata object.
//  Data - ValueTable -  the data portions.
//  IndexOf - Number -  index of the data string to generate the key.
//
// Returns:
//  ValueList - 
//
Function NewRecordKeyFromDataTable(RefObject1, TabularObject, Data, IndexOf)
	
	RecordKey = NewRecordKey(RefObject1, TabularObject);
	String = Data[IndexOf];
	
	For Each Column In Data.Columns Do
		ColumnName = Column.Name;
		RecordKey.Add(String[ColumnName], ColumnName);
	EndDo;
	
	Return RecordKey;
	
EndFunction

// A table of values describing the data to update.
// Is the result of searching for data to update.
//
// Returns:
//  ValueTable - :
//   * RefObject1 - String -  name of the metadata reference object (may be Undefined).
//   * TabularObject - String -  name of the metadata table object (can be Undefined).
//   * Data - ValueTable -  selection from the DBMS as a table of values.
//
Function NewDataSetForUpdate()
	
	DataSet = New ValueTable;
	Columns = DataSet.Columns;
	Columns.Add("RefObject1", New TypeDescription("String"));
	Columns.Add("TabularObject", New TypeDescription("String"));
	Columns.Add("Data", New TypeDescription("ValueTable"));
	
	Return DataSet;
	
EndFunction

// Array of descriptions of data portions to update.
// This is the result of splitting the found data into fragments.
//
// Returns:
//   Array of See NewBatchForUpdate
//
Function NewBatchesSetForUpdate()
	
	Return New Array;
	
EndFunction

// Description of the data portion to update.
//
// Returns:
//  Structure - :
//   * Id - UUID -  the ID portion.
//   * FirstRecord - ValueList - 
//   * LatestRecord - ValueList - 
//   * DataSet - See NewDataSetForUpdate
//
Function NewBatchForUpdate()
	
	Batch = New Structure;
	Batch.Insert("Id");
	Batch.Insert("FirstRecord");
	Batch.Insert("LatestRecord");
	Batch.Insert("DataSet");
	
	Return Batch;
	
EndFunction

// The result of the portion search.
//
// Returns:
//  Structure - :
//   
//    See NewDataSetForUpdate
//   
//
Function NewBatchSearchResult()
	
	SearchResult = New Structure;
	SearchResult.Insert("Count", 0);
	SearchResult.Insert("DataSet");
	SearchResult.Insert("SearchCompleted", False);
	SearchResult.Insert("IsUpToDateDataProcessed", False);
	SearchResult.Insert("ProcessedRecordersTables", Undefined);
	
	Return SearchResult;
	
EndFunction

// To find the first processed portion (the processing of which ended in disaster).
//
// Parameters:
//  BatchesToUpdate - See NewBatchesTableForUpdate
//
// Returns:
//  ValueTableRow of See NewBatchesTableForUpdate
//  
//
Function FirstUnprocessedBatch(BatchesToUpdate)
	
	If BatchesToUpdate <> Undefined Then
		For Each Batch In BatchesToUpdate Do
			If Not Batch.InProcessing Then
				Return Batch;
			EndIf;
		EndDo;
	EndIf;
	
	Return Undefined;
	
EndFunction

// An analog of page Split, supplemented by the fact that the fragments are shortened to the left and right.
//
// Parameters:
//  String - String -  split string.
//  Separator - String -  line element separator.
//  IncludeBlank - Boolean -  The truth is, if you are getting an empty string.
//
// Returns:
//  Array - 
//
Function StrSplitTrimAll(String, Separator, IncludeBlank = True)
	
	Array = StrSplit(String, Separator, IncludeBlank);
	
	For IndexOf = 0 To Array.UBound() Do
		Array[IndexOf] = TrimAll(Array[IndexOf]);
	EndDo;
	
	Return Array;
	
EndFunction

// Determines whether the description of the multithreaded processor.
//
// Returns:
//  Boolean - 
//
Function IsMultithreadHandlerDataDetails(LongDesc)
	
	Return LongDesc.Property("BatchesToUpdate");
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Register predefined elements for updating in the update handler.
//
Procedure RegisterPredefinedItemsToUpdate(Parameters, MetadataObject = Undefined, AdditionalParameters = Undefined) Export
	
	RegistrationParameters = PredefinedItemsRegistrationParameters();
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FillPropertyValues(RegistrationParameters, AdditionalParameters);
	EndIf;
	
	If MetadataObject <> Undefined Then
		ObjectsWithPredefinedItems = New Map();
		ObjectsWithPredefinedItems.Insert(MetadataObject, MetadataObject.FullName());
	Else
		ObjectsWithPredefinedItems = ObjectsWithInitialFilling();
	EndIf;
	
	ObjectsToBeProcessed = New Array;
	
	QueryTemplate = "SELECT
		|	&Fields
		|FROM
		|	#Table AS Table
		|WHERE
		|	Table.Predefined = TRUE";
	
	For Each ObjectWithPredefinedElements In ObjectsWithPredefinedItems Do
		
		MetadataObjectWithItems = ObjectWithPredefinedElements.Key;
		FullMetadataObjectName  = ObjectWithPredefinedElements.Value;
		
		ObjectManager = Common.ObjectManagerByFullName(FullMetadataObjectName);
		ObjectAttributesToLocalize = New Map;
		If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
			ObjectAttributesToLocalize = ModuleNationalLanguageSupportServer.MultilingualObjectAttributes(MetadataObjectWithItems);
		EndIf;
		
		PredefinedData       = PredefinedObjectData(MetadataObjectWithItems, ObjectManager, ObjectAttributesToLocalize);
		
		// 
		
		ObjectAttributesNames = New Array;
		If RegistrationParameters.UpdateMode = "NewAndChanged" Then
			
			For Each Column In PredefinedData.Columns Do
				If IsBlankString(Column.Title) Then
					ObjectAttributesNames.Add(Column.Name);
				EndIf;
			EndDo;
			
		EndIf;
		
		If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
			ModuleNationalLanguageSupportServer.GenerateNamesOfMultilingualAttributes(ObjectAttributesNames, ObjectAttributesToLocalize);
		EndIf;
		
		If ObjectAttributesNames.Find("PredefinedDataName") = Undefined Then
			ObjectAttributesNames.Add("PredefinedDataName");
		EndIf;
		If ObjectAttributesNames.Find("Ref") = Undefined Then
			ObjectAttributesNames.Add("Ref");
		EndIf;
		
		QueryText = StrReplace(QueryTemplate, "&Fields", StrConcat(ObjectAttributesNames, ", " + Chars.LF));
		QueryText = StrReplace(QueryText, "#Table", FullMetadataObjectName);
		Query = New Query(QueryText);
		
		// 
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			Continue;
		EndIf;
		
		QueryData = QueryResult.Select();
		While QueryData.Next() Do
			
			SuppliedInformationRecords = PredefinedData.Find(QueryData.PredefinedDataName, "PredefinedDataName");
			
			If SuppliedInformationRecords <> Undefined Then
				
				If RegistrationParameters.UpdateMode = "All" Then
					ObjectsToBeProcessed.Add(QueryData.Ref);
				ElsIf RegistrationParameters.UpdateMode = "NewAndChanged" Then
					
					If DataContainsDifferences(QueryData, ObjectAttributesNames, SuppliedInformationRecords, ObjectAttributesToLocalize, RegistrationParameters) Then
						ObjectsToBeProcessed.Add(QueryData.Ref);
					EndIf;
					
				ElsIf RegistrationParameters.UpdateMode = "MultilingualStrings" Then
					
					If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
						ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
						If ModuleNationalLanguageSupportServer.MultilingualAttributesStringsChanged(
							SuppliedInformationRecords, QueryData, ObjectAttributesToLocalize, RegistrationParameters) Then
							ObjectsToBeProcessed.Add(QueryData.Ref);
						EndIf;
					EndIf;
					
				EndIf;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	If ObjectsToBeProcessed.Count() > 0 Then
		InfobaseUpdate.MarkForProcessing(Parameters, ObjectsToBeProcessed);
	EndIf;
	
EndProcedure

// 
// 
// Parameters:
//  ObjectToFillIn - CatalogObject
//                    - ChartOfCharacteristicTypesObject
//                    - FormDataStructure:
//                       * Ref - CatalogRef
//  PopulationSettings - See InfobaseUpdate.PopulationSettings
// 
Procedure FillObjectInitialData(ObjectToFillIn, PopulationSettings) Export
	
	If TypeOf(ObjectToFillIn) = Type("FormDataStructure") Then
		If ObjectToFillIn.Property("SourceRecordKey") Then
			ObjectType = TypeOf(ObjectToFillIn.SourceRecordKey);
		Else
			ObjectType = TypeOf(ObjectToFillIn.Ref);
		EndIf;
	Else
		ObjectType = TypeOf(ObjectToFillIn);
	EndIf;
	
	ObjectMetadata = Metadata.FindByType(ObjectType);
	
	SetFillSettings = ParameterSetForFillingObject(ObjectMetadata);
	
	FillRequisitesInitialData(ObjectToFillIn, SetFillSettings, PopulationSettings);
	
EndProcedure

Procedure FillItemsWithInitialData(Parameters, MetadataObject, PopulationSettings) Export
	
	ObjectsRefs = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, MetadataObject.FullName());
	
	If PopulationSettings.UpdateMultilingualStringsOnly Then
		If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
			Result = ModuleNationalLanguageSupportServer.UpdateMultilanguageStringsOfPredefinedItems(ObjectsRefs, MetadataObject);
		EndIf;
	Else
		Result = UpdateItemsOfPredefinedItems(ObjectsRefs, MetadataObject, PopulationSettings);
	EndIf;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, MetadataObject.FullName());
	
	If Result.ObjectsProcessed = 0 And Result.ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t populate (skipped) some items with initial data: %1';"),
			Result.ObjectsWithIssuesCount);
		Raise MessageText;
	EndIf;
	WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
		MetadataObject,, StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Yet another batch of items is processed: %1';"),
	Result.ObjectsProcessed));
	
EndProcedure

Function PredefinedItemsRegistrationParameters()
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("UpdateMode",         "NewAndChanged");
	AdditionalParameters.Insert("SkipEmpty",         True);
	AdditionalParameters.Insert("CompareTabularSections", False);
	
	Return AdditionalParameters;
	
EndFunction

Function DataContainsDifferences(QueryData, NameObjectAttribute, SuppliedInformationRecords, ObjectAttributesToLocalize, RegistrationParameters)
	
	For Each ObjectAttributeName In NameObjectAttribute Do
		
		If StrCompare(ObjectAttributeName, "Predefined") = 0
			Or StrCompare(ObjectAttributeName, "Ref") = 0 Then
				Continue;
		EndIf;
		
		AttributeNameWithoutSuffixLanguage= ObjectAttributeName;
		If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
			AttributeNameWithoutSuffixLanguage = ModuleNationalLanguageSupportServer.AttributeNameWithoutSuffixLanguage(ObjectAttributeName);
		EndIf;

		If ObjectAttributesToLocalize[AttributeNameWithoutSuffixLanguage] = Undefined Then
		
			If TypeOf(SuppliedInformationRecords[ObjectAttributeName]) = Type("ValueTable")
				And TypeOf(QueryData[ObjectAttributeName]) = Type("QueryResult") Then
				
				If RegistrationParameters.CompareTabularSections Then
					DataTable = QueryData[ObjectAttributeName].Unload();
					If Not Common.IdenticalCollections(SuppliedInformationRecords[ObjectAttributeName], DataTable) Then
						Return True;
					EndIf;
				EndIf;
				
			Else
				If RegistrationParameters.SkipEmpty And IsBlankString(SuppliedInformationRecords[ObjectAttributeName]) Then
					Continue;
				EndIf;
				If SuppliedInformationRecords[ObjectAttributeName] <> QueryData[ObjectAttributeName] Then
					Return True;
				EndIf;
			EndIf;
		
		Else
			
			If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
				ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
				If ModuleNationalLanguageSupportServer.MultilingualAttributeStringsChanged(SuppliedInformationRecords, QueryData,
						AttributeNameWithoutSuffixLanguage, RegistrationParameters) Then
					Return True;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

// 


// 
// 
// Returns:
//  Structure:
//    * OnInitialItemFilling - Boolean
//    * KeyAttributeName - String
//    * AdditionalParameters - Structure
//
Function CustomSettingsFillItems()
	
	ItemsFillingSettings = New Structure;
	ItemsFillingSettings.Insert("OnInitialItemFilling", False);
	ItemsFillingSettings.Insert("KeyAttributeName",          "PredefinedDataName");
	ItemsFillingSettings.Insert("AdditionalParameters", New Structure);

	Return ItemsFillingSettings;
	
EndFunction

Procedure FillRequisitesInitialData(ItemToFill, Context, PopulationSettings)
	
	KeyAttributeName = KeyAttributeName(Context.PredefinedItemsSettings);
	
	ObjectKeyValue = ItemToFill[KeyAttributeName];
	
	If Not ValueIsFilled(ObjectKeyValue) Then
		
		If Not Context.PredefinedItemsSettings.IsColumnNamePredefinedData Then 
			Return;
		EndIf;
		
		KeyAttributeName = "PredefinedDataName";
		ObjectKeyValue = ItemToFill[KeyAttributeName];
		If Not ValueIsFilled(ObjectKeyValue) Then
			Return;
		EndIf;
		
	EndIf;
	
	ObjectManager = Context.ObjectManager;
	
	TableRow = Context.PredefinedData.Find(ObjectKeyValue, KeyAttributeName);
	If TableRow = Undefined Then
		Return;
	EndIf;
		
	ButAttributes = Context.ExceptionAttributes;
	
	If Context.HierarchySupported And ItemToFill.IsFolder Then
		
		ButAttributes = Context.ExceptionAttributes + ?(IsBlankString(
			Context.ExceptionAttributes), "", ",") + StrConcat(
			Context.AttributesWithItems, ",");
	EndIf;
	
	If Not PopulationSettings.UpdateMultilingualStringsOnly Then
		
		If ValueIsFilled(PopulationSettings.Attributes) Then
			FillPropertyValues(ItemToFill, TableRow, PopulationSettings.Attributes);
		Else
			FillPropertyValues(ItemToFill, TableRow,, ButAttributes);
		EndIf;      
		
		If Context.HierarchySupported And ValueIsFilled(TableRow.Parent) Then
			
			If KeyAttributeName = "Ref" Then
				If TypeOf(TableRow.Parent) = Type("String") Then
					ItemToFill.Parent = ObjectManager.GetRef(New UUID(TableRow.Parent));
				ElsIf TypeOf(TableRow.Parent) = Type("UUID") Then
					ItemToFill.Parent = ObjectManager.GetRef(TableRow.Parent);
				Else
					ItemToFill.Parent = TableRow.Parent;
				EndIf;
			ElsIf TypeOf(TableRow.Parent) = Type("String") Then 
				
				ObjectMetadata = Metadata.FindByType(TypeOf(ItemToFill));
				ExistingItems = ExistingSuppliedItems(Context.PredefinedData,
					Context.PredefinedItemsSettings, ObjectManager, ObjectMetadata);
				ItemToFill.Parent = ExistingItems[TableRow.Parent];
				
			Else
				ItemToFill.Parent = TableRow.Parent;
			EndIf;
			
		EndIf; 
		
		If Not (Context.HierarchySupported And ItemToFill.IsFolder) Then
			For Each TabularSectionName In Context.TabularSections Do
				ItemToFill[TabularSectionName].Load(TableRow[TabularSectionName]);
			EndDo;
		EndIf;
		
	EndIf;
		
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");

		ExceptionFields = StrSplitTrimAll(ButAttributes, ",", False);
		ModuleNationalLanguageSupportServer.FillItemsWithMultilingualInitialData(ItemToFill, 
			TableRow, Context, ExceptionFields);
	EndIf;
	
	If Context.PredefinedItemsSettings.OverriddenSettings.OnInitialItemFilling Then
		ObjectManager.OnInitialItemFilling(ItemToFill, TableRow, Context.PredefinedItemsSettings.OverriddenSettings.AdditionalParameters);
	EndIf;
	
EndProcedure

// 
// 
// Parameters:
//  ObjectsRefs - QueryResultSelection - :
//    * Ref - AnyRef
//  ObjectMetadata - MetadataObject
//  PopulationSettings - See InfobaseUpdate.PopulationSettings
// 
// Returns:
//  Structure - :
//   * ObjectsWithIssuesCount - Number
//   * ObjectsProcessed - Number
//
Function UpdateItemsOfPredefinedItems(ObjectsRefs, ObjectMetadata, PopulationSettings)
	
	Result = New Structure();
	Result.Insert("ObjectsWithIssuesCount", 0);
	Result.Insert("ObjectsProcessed", 0);
	
	ParametersForFillingObject = ParameterSetForFillingObject(ObjectMetadata);
	FullName                     = ObjectMetadata.FullName();
	
	IsIncludesEditedPredefinedAttributes = IsIncludesEditedPredefinedAttributes(FullName);
	
	KeyAttributeName = KeyAttributeName(ParametersForFillingObject.PredefinedItemsSettings);
	
	HierarchySupported = ParametersForFillingObject.HierarchySupported;
	ExceptionAttributes = ParametersForFillingObject.ExceptionAttributes;
	ObjectManager = ParametersForFillingObject.ObjectManager;  
	
	While ObjectsRefs.Next() Do
		
		ObjectReference = ObjectsRefs.Ref;
		
		ValueOfKeyProps = Common.ObjectAttributeValue(ObjectReference, KeyAttributeName);
		If Not ValueIsFilled(ValueOfKeyProps) Then
			Result.ObjectsProcessed = Result.ObjectsProcessed + 1;
			InfobaseUpdate.MarkProcessingCompletion(ObjectsRefs.Ref);
			Continue;
		EndIf;
		
		TableRow = ParametersForFillingObject.PredefinedData.Find(ValueOfKeyProps, KeyAttributeName);
		If TableRow = Undefined Then
			Result.ObjectsProcessed = Result.ObjectsProcessed + 1;
			InfobaseUpdate.MarkProcessingCompletion(ObjectsRefs.Ref);
			Continue;
		EndIf;
		
		RepresentationOfTheReference = String(ObjectsRefs.Ref);
		
		BeginTransaction();
		
		Try
			
			DataLock = New DataLock;
			DataLockItem = DataLock.Add(FullName);
			DataLockItem.SetValue("Ref", ObjectsRefs.Ref);
			DataLock.Lock();
			
			ItemToFill = ObjectsRefs.Ref.GetObject();
			
			ButAttributes = ExceptionAttributes;
			If HierarchySupported And ItemToFill.IsFolder Then
				ButAttributes = ExceptionAttributes + ?(IsBlankString(ExceptionAttributes), "", ",") + StrConcat(ParametersForFillingObject.AttributesWithItems, ",");
			EndIf;
			
			If ValueIsFilled(PopulationSettings.Attributes) Then
				FillPropertyValues(ItemToFill, TableRow, PopulationSettings.Attributes);
			Else
				
				If IsIncludesEditedPredefinedAttributes Then
					EditedAttributes = EditedAttributes(ItemToFill, FullName);
					
					If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
						ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
						ModuleNationalLanguageSupportServer.DeleteMultilingualAttributes(EditedAttributes);
					EndIf;
					
					EditedAttributesAsString = StrConcat(EditedAttributes, ",");
				
					If ValueIsFilled(EditedAttributesAsString) Then
						ButAttributes = ?(ValueIsFilled(ButAttributes), "," , "") + EditedAttributesAsString;
					EndIf;
				EndIf;
				
				FillPropertyValues(ItemToFill, TableRow,, ButAttributes);
			EndIf;
			
			If Not (HierarchySupported And ItemToFill.IsFolder) Then
				For Each TabularSectionName In ParametersForFillingObject.TabularSections Do
					ItemToFill[TabularSectionName].Load(TableRow[TabularSectionName]);
				EndDo;
			EndIf;
			
			If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
				ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
				ModuleNationalLanguageSupportServer.FillItemsWithMultilingualInitialData(ItemToFill,
					TableRow, ParametersForFillingObject, EditedAttributes(ItemToFill, FullName));
			EndIf;
			
			If ParametersForFillingObject.PredefinedItemsSettings.OverriddenSettings.OnInitialItemFilling Then
				ObjectManager.OnInitialItemFilling(ItemToFill, TableRow, 
					ParametersForFillingObject.PredefinedItemsSettings.OverriddenSettings.AdditionalParameters);
			EndIf;
			
			InfobaseUpdate.WriteObject(ItemToFill);
			CommitTransaction();
			
		Except
			RollbackTransaction();
			// 
			Result.ObjectsWithIssuesCount = Result.ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot fill in item %1 due to: %2';"),
			RepresentationOfTheReference, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
			ObjectMetadata, ObjectsRefs.Ref, MessageText);
		EndTry;
		
		Result.ObjectsProcessed = Result.ObjectsProcessed + 1;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function ExistingSuppliedItems(PredefinedData, PredefinedItemsSettings, Val ObjectManager, ObjectMetadata)
	
	Result = New Map();
	
	KeyAttributeName = PredefinedItemsSettings.OverriddenSettings.KeyAttributeName;
	IsColumnNamePredefinedData = PredefinedItemsSettings.IsColumnNamePredefinedData;
	
	PredefinedItemsNames = ObjectMetadata.GetPredefinedNames();
	
	SetOfKeys = New ValueTable();
	If KeyAttributeName <> "Ref" Then
		SetOfKeys.Columns.Add("Key", Common.StringTypeDetails(150));
	Else
		
		Array = New Array;
		Array.Add(TypeOf(ObjectManager.EmptyRef()));
		SetOfKeys.Columns.Add("Key",  New TypeDescription(Array));
	
	EndIf;
	
	Result = New Map();
	
	If StrCompare(KeyAttributeName, "PredefinedDataName") <> 0 Then
		
		For Each PredefinedItem In PredefinedData Do
			
			If IsColumnNamePredefinedData And ValueIsFilled(
				PredefinedItem.PredefinedDataName) And PredefinedItemsNames.Find(
				PredefinedItem.PredefinedDataName) <> Undefined Then
				Result.Insert(PredefinedItem.PredefinedDataName,
					ObjectManager[PredefinedItem.PredefinedDataName]);
					Continue;
			EndIf;
			
			If ValueIsFilled(PredefinedItem[KeyAttributeName]) Then
				
				NewRow = SetOfKeys.Add();
				NewRow.Key =  PredefinedItem[KeyAttributeName];
			EndIf;
			
		EndDo;
		
		If SetOfKeys.Count() > 0 Then
			
			Query = New Query;
			QueryText = "SELECT
				|	SetOfKeys.Key AS KeyAttributeName
				|INTO SetOfKeys
				|FROM
				|	&SetOfKeys AS SetOfKeys
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ISNULL(DataTable.Ref, UNDEFINED) AS Ref,
				|	SetOfKeys.KeyAttributeName AS KeyAttributeName
				|FROM
				|	SetOfKeys AS SetOfKeys
				|		LEFT JOIN #Table AS DataTable
				|		ON SetOfKeys.KeyAttributeName = &FieldName";
			
			QueryText = StrReplace(QueryText, "&FieldName", "DataTable." + KeyAttributeName);
			Query.Text = StrReplace(QueryText, "#Table", ObjectMetadata.FullName());
			Query.SetParameter("SetOfKeys", SetOfKeys);
			
			QueryResult = Query.Execute();
			
			SelectionDetailRecords = QueryResult.Select();
			
			While SelectionDetailRecords.Next() Do
				Result.Insert(SelectionDetailRecords.KeyAttributeName, SelectionDetailRecords.Ref);
			EndDo;
		
		EndIf;
		
	ElsIf IsColumnNamePredefinedData Then
		
		For Each SuppliedItem In PredefinedData Do
			
			If ValueIsFilled(SuppliedItem["PredefinedDataName"]) Then
					Result.Insert(SuppliedItem["PredefinedDataName"], ObjectManager[SuppliedItem[KeyAttributeName]]);
					Continue;
			EndIf;
		EndDo;
		
	EndIf;
	
	Return Result;

EndFunction

Procedure AddPredefinedDataTableColumn(PredefinedData, Attribute, AttributesToLocalize, Languages)
	
	If StrCompare(Attribute.Name, "Parent") = 0 Then
		TypesArray = New Array;
		For Each AttributeType In Attribute.Type.Types() Do
			TypesArray.Add(AttributeType);
		EndDo;
		TypesArray.Add(Type("String"));

		RowParameters = New StringQualifiers(150);
		AttributeType = New TypeDescription(TypesArray,, RowParameters);
	ElsIf StrCompare(Attribute.Name, "Ref") = 0 Then
		TypesArray = New Array;
		For Each AttributeType In Attribute.Type.Types() Do
			TypesArray.Add(AttributeType);
		EndDo;
		TypesArray.Add(Type("String"));
		TypesArray.Add(Type("UUID"));

		RowParameters = New StringQualifiers(150);
		AttributeType = New TypeDescription(TypesArray,, RowParameters);
	Else
		AttributeType = Attribute.Type;
	EndIf;

	PredefinedData.Columns.Add(Attribute.Name, AttributeType);
	If AttributesToLocalize[Attribute.Name] = Undefined Then
		Return;
	EndIf;

	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		AttributeToLocalizeFlag = ModuleNationalLanguageSupportServer.AttributeToLocalizeFlag();
	Else
		AttributeToLocalizeFlag = Undefined;
	EndIf;
	
	For Each Language In Languages Do
		PredefinedData.Columns.Add(Attribute.Name + "_" + Language, Attribute.Type, AttributeToLocalizeFlag);
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Sets the key maintenance tasks Allogeneically.
//
Procedure InstallScheduledJobKey() Export
	
	Filter = New Structure;
	Filter.Insert("Metadata", Metadata.ScheduledJobs.DeferredIBUpdate);
	Filter.Insert("Predefined", True);
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	For Each Job In Jobs Do
		If ValueIsFilled(Job.Key) Then
			Continue;
		EndIf;
		Job.Key = Metadata.ScheduledJobs.DeferredIBUpdate.Key;
		Job.Write(); // 
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 
// 

// 
Procedure ClearObsoleteData() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.ClearObsoleteData);
	
	If TransactionActive() Then
		ErrorText = NStr("en = 'You cannot clear obsolete data in an external transaction.';");
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	JobMetadata = Metadata.ScheduledJobs.ClearObsoleteData;
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'You can run the %1 procedure only in a background job.';"),
		JobMetadata.MethodName);
	
	CurrentSession = GetCurrentInfoBaseSession();
	If CurrentSession.ApplicationName <> "BackgroundJob" Then
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	CurrentBackgroundJob = CurrentSession.GetBackgroundJob();
	If CurrentBackgroundJob = Undefined Then
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	If Not Common.SeparatedDataUsageAvailable() Then
		UpdateProgress = Undefined; // See InfobaseUpdate.DataAreasUpdateProgress
		If Not DeferredUpdateCompleted(UpdateProgress) Then
			Comment = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Obsolete shared data cleanup is deferred as some
				           |data areas have not completed the deferred infobase update yet.
				           |Areas with update in progress: %1
				           |Areas pending update: %2
				           |Areas with update issues: %3';"),
				Format(UpdateProgress.Running, "NZ=0; NG="),
				Format(UpdateProgress.Waiting1, "NZ=0; NG="),
				Format(UpdateProgress.Issues, "NZ=0; NG="));
			WriteLogEvent(
				NStr("en = 'Clear obsolete data.Wait for the update to complete';",
					Common.DefaultLanguageCode()),
				EventLogLevel.Information,,, Comment);
			Return;
		EndIf;
	Else
		SetUpObsoleteDataPurgeJobNoAttempt(False);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The last deferred update handler clears obsolete data.
			           |View the results: %1
			           |
			           |The scheduled job is used only in SaaS to
			           |clear up obsolete shared data.';"),
			"e1cib/app/DataProcessor.ApplicationUpdateResult");
		Raise ErrorText;
	EndIf;
	
	JobID = CurrentBackgroundJob.UUID;
	FoundJob = Undefined;
	If IsJobAlreadyRunning(JobMetadata.MethodName, JobID,, FoundJob)
	 Or IsJobAlreadyRunning("",, ObsoleteDataPurgeJobKey(), FoundJob) Then
		SetUpObsoleteDataPurgeJobNoAttempt(True);
		Comment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Obsolete data cleanup is already in progress
			           |in the ""%1"" background job dated %2';"),
			FoundJob.Description,
			Format(FoundJob.Begin, "DLF=DT"));
		WriteLogEvent(
			NStr("en = 'Clear obsolete data.Startup denied';",
				Common.DefaultLanguageCode()),
			EventLogLevel.Information,,, Comment);
		Return;
	EndIf;
	
	RuntimeBorder = CurrentSessionDate() + ObsoleteDataContinuousPurgeTimerMinutes() * 60;
	IsAllBatchesProcessed = True;
	HasSuccesses = False;
	Errors = New Array;
	
	Context = New Structure("CleanUpDeleteable, IsScheduledJob", True);
	While True Do
		NewBatches = New Map;
		ObsoleteDataOnRequestChunksInBackground(NewBatches, Context);
		If Not ValueIsFilled(NewBatches) Then
			Break;
		EndIf;
		For Each KeyAndValue In NewBatches Do
			If RuntimeBorder < CurrentSessionDate() Then
				IsAllBatchesProcessed = False;
				Break;
			EndIf;
			Batch = KeyAndValue.Value[0];
			Batch.Insert("RuntimeBorder", RuntimeBorder);
			Batch.Insert("IsAllBatchesProcessed", True);
			Try
				ObsoleteDataOnCleaningBatchInBackground(Batch);
				HasSuccesses = True;
			Except
				ErrorInfo = ErrorInfo();
				Errors.Add(ErrorProcessing.DetailErrorDescription(ErrorInfo));
			EndTry;
			If Not Batch.IsAllBatchesProcessed Then
				IsAllBatchesProcessed = False;
				Break;
			EndIf;
		EndDo;
		If Not IsAllBatchesProcessed Then
			Break;
		EndIf;
	EndDo;
	
	If Not IsAllBatchesProcessed
	 Or ValueIsFilled(Errors) And HasSuccesses Then
		SetUpObsoleteDataPurgeJobNoAttempt(True);
		Return;
	EndIf;
	
	If ValueIsFilled(Errors) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot clear some data due to errors:
			           |
			           |%1';"),
			StrConcat(Errors, "
			|--------------------------------------------------------------------------------
			|
			|"));
		WriteLogEvent(
			NStr("en = 'Clear obsolete data.Deletion errors';",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorText);
	EndIf;
	
	SetUpObsoleteDataPurgeJobNoAttempt(False);
	
EndProcedure

// 
Function ObsoleteDataContinuousPurgeTimerMinutes()
	Return 15;
EndFunction

// 
Function IsJobAlreadyRunning(MethodName, IDOfJobToExclude = Undefined,
			Var_Key = Undefined, FoundJob = Undefined)
	
	Filter = New Structure("State", BackgroundJobState.Active);
	If ValueIsFilled(MethodName) Then
		Filter.Insert("MethodName", MethodName);
	Else
		Filter.Insert("Key", Var_Key);
	EndIf;
	
	FoundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	For Each FoundJob In FoundJobs Do
		If FoundJob.UUID <> IDOfJobToExclude Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// 
Procedure SetUpObsoleteDataPurgeJob(Enable)
	
	Try
		SetUpObsoleteDataPurgeJobNoAttempt(Enable);
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot set up scheduled job
			           |""%1"" due to:
			           |%2';"),
			Metadata.ScheduledJobs.ClearObsoleteData.Name,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		WriteLogEvent(
			NStr("en = 'Clear obsolete data.Scheduled job setup error';",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorText);
	EndTry;
	
EndProcedure

// 
Procedure SetUpObsoleteDataPurgeJobNoAttempt(Enable)
	
	JobMetadata = Metadata.ScheduledJobs.ClearObsoleteData;
	
	If Common.DataSeparationEnabled() Then
		Filter = New Structure("MethodName", JobMetadata.MethodName);
	Else
		Filter = New Structure("Metadata", JobMetadata);
	EndIf;
	FoundJobs = ScheduledJobsServer.FindJobs(Filter);
	
	Count = ?(Common.SeparatedDataUsageAvailable(), 0, 1);
	If FoundJobs.Count() > Count Then
		For Each FoundJob In FoundJobs Do
			If FoundJob = FoundJobs[0] And Count > 0 Then
				Continue;
			EndIf;
			ScheduledJobsServer.DeleteJob(FoundJob);
		EndDo;
	EndIf;
	
	If Count = 0 Then
		Return;
	EndIf;
	
	If FoundJobs.Count() = 0 Then
		BeginTransaction();
		Try
			ScheduledJobsServer.BlockARoutineTask(JobMetadata);
			FoundJobs = ScheduledJobsServer.FindJobs(Filter);
			If FoundJobs.Count() = 0 Then
				// 
				NewJob = ScheduledJobs.CreateScheduledJob(JobMetadata);
				// 
				ParametersOfNewJob = New Structure("Key, RestartIntervalOnFailure,
				|RestartCountOnFailure, Schedule, Metadata");
				FillPropertyValues(ParametersOfNewJob, NewJob);
				ParametersOfNewJob.Insert("Use", Enable);
				ScheduledJobsServer.AddJob(ParametersOfNewJob);
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry
	EndIf;
	
	If FoundJobs.Count() = 0 Then
		Return;
	EndIf;
	
	Job = FoundJobs[0];
	If Job.Use = Enable Then
		Return;
	EndIf;
	
	JobParameters = New Structure("Use", Enable);
	
	BeginTransaction();
	Try
		ScheduledJobsServer.BlockARoutineTask(Job.UUID);
		FoundJobs = ScheduledJobsServer.FindJobs(Filter);
		If FoundJobs.Count() = 0
		 Or FoundJobs[0].UUID <> Job.UUID Then
			SetUpObsoleteDataPurgeJobNoAttempt(Enable);
		ElsIf FoundJobs[0].Use <> Enable Then
			ScheduledJobsServer.ChangeJob(FoundJobs[0].UUID, JobParameters);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry
	
EndProcedure

// 
Function ObsoleteDataPurgeJobKey() Export
	Return New UUID("f5104cf5-6251-438c-8557-e8bde0faec3e");
EndFunction

// 
Procedure CancelObsoleteDataPurgeJob(CancelManagerJob = False) Export
	
	Filter = New Structure("State, MethodName", BackgroundJobState.Active,
		Metadata.ScheduledJobs.ClearObsoleteData.MethodName);
	
	FoundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	For Each FoundJob In FoundJobs Do
		FoundJob.Cancel();
		FoundJob.WaitForExecutionCompletion(7);
	EndDo;
	
	If Not CancelManagerJob Then
		Return;
	EndIf;
	
	Filter = New Structure("State, Key", BackgroundJobState.Active,
		ObsoleteDataPurgeJobKey());
	
	FoundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	For Each FoundJob In FoundJobs Do
		FoundJob.Cancel();
		FoundJob.WaitForExecutionCompletion(7);
	EndDo;
	
EndProcedure

Procedure EmptyRegistrationProcedure(Parameters) Export
	Return;
EndProcedure

Procedure ClearOutdatedDataCompletely(Parameters) Export
	
	ErrorTitle = NStr("en = 'Couldn''t clear obsolete data.';")
		+ Chars.LF + Chars.LF;
	
	If Not Common.SeparatedDataUsageAvailable() Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot call the ""%1"" procedure in shared mode.';"),
			"ClearCompletelyAfterDeferredUpdateSucceeded");
		Raise(ErrorTitle + ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	CancelObsoleteDataPurgeJob(True);
	
	AddressOfCleaningResult = PutToTempStorage(Undefined, New UUID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters();
	ExecutionParameters.WaitCompletion = Undefined;
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Clear obsolete data (deferred)';");
	ExecutionParameters.ResultAddress = AddressOfCleaningResult;
	ExecutionParameters.BackgroundJobKey = ObsoleteDataPurgeJobKey();
	ExecutionParameters.RunNotInBackground1 = ExclusiveMode();
	
	ProcedureSettings = New Structure;
	ProcedureSettings.Insert("Context",
		New Structure("CleanUpDeleteable, DeferredUpdate", False, True));
	ProcedureSettings.Insert("NameOfBatchAcquisitionMethod",
		"InfobaseUpdateInternal.ObsoleteDataOnRequestChunksInBackground");
	
	Try
		Result = TimeConsumingOperations.ExecuteProcedureinMultipleThreads(
			"InfobaseUpdateInternal.ObsoleteDataOnCleaningBatchInBackground",
			ExecutionParameters, ProcedureSettings);
		
		If Result.Status = "Error" Then
			ErrorText = Result.DetailErrorDescription;
		ElsIf Result.Status = "Canceled" Then
			ErrorText = NStr("en = 'Job is canceled';");
		ElsIf Result.Status = "Running" Then
			ErrorText = NStr("en = 'The app did not wait for the job to be completed';");
		EndIf;
		If Result.Status <> "Completed2" Then
			Raise ErrorTitle + ErrorText;
		EndIf;
		
		Results = GetFromTempStorage(AddressOfCleaningResult);
		ErrorText = ObsoleteDataPurgeJobErrorText(Results);
		If ErrorText <> Undefined Then
			Raise(ErrorTitle + ErrorText, ErrorCategory.ConfigurationError);
		EndIf;
		
	Except
		DeleteFromTempStorage(AddressOfCleaningResult);
		Raise;
	EndTry;
	
	DeleteFromTempStorage(AddressOfCleaningResult);
	
	Parameters.ProcessingCompleted = True;
	
EndProcedure

// 
Function ObsoleteDataPurgeJobErrorText(Results) Export
	
	If TypeOf(Results) <> Type("Map") Then
		If Common.DataSeparationEnabled() Then
			Return NStr("en = 'The background job did not return a result';");
		Else
			Return NStr("en = 'The managing background job did not return a result';");
		EndIf;
	EndIf;
	
	HasError = False;
	ErrorsTexts = New Array;
	
	For Each KeyAndValue In Results Do
		CurrentResult = KeyAndValue.Value;
		If CurrentResult.Status = "Error" Then
			ErrorsTexts.Add(CurrentResult.BriefErrorDescription);
		ElsIf CurrentResult.Status <> "Completed2" Then
			HasError = True;
		EndIf;
	EndDo;
	
	ErrorText = Undefined;
	
	If HasError And Not ValueIsFilled(ErrorsTexts) Then
		ErrorText = NStr("en = 'Some jobs are not completed. Repeat the operation.';");
	ElsIf ValueIsFilled(ErrorsTexts) Then
		ErrorText = StrConcat(ErrorsTexts, "
		|--------------------------------------------------------------------------------
		|
		|");
	EndIf;
	
	Return ErrorText;
	
EndFunction

// 
// 
//
// Parameters:
//  NewBatches - Map of KeyAndValue:
//   * Key - UUID - 
//   * Value - Arbitrary - 
//
//  Context - Structure - 
//                
//                
//
Procedure ObsoleteDataOnRequestChunksInBackground(NewBatches, Context) Export
	
	If Not Context.Property("TablesToClearUp") Then
		If Not Context.Property("IsScheduledJob")
		   And Not Common.SeparatedDataUsageAvailable() Then
			IsObsoleteDataPurgeJobRunning(True);
		EndIf;
		Context.Insert("IndexOfCurrentTable", -1);
		Context.Insert("TablesToClearUp", TablesToClearUp(Not Context.CleanUpDeleteable));
		SetTablesCleaningOrder(Context.TablesToClearUp);
		WriteCleanUpPlanToLog(Context);
		Context.Insert("PortionSize", 10000);
		Context.Insert("MaxNumberOfBatches",
			?(Context.Property("Percent") And Not Common.FileInfobase(), 5, 1));
		Properties = New Array;
		For Each Column In Context.TablesToClearUp.Columns Do
			Properties.Add(Column.Name);
		EndDo;
		Context.Insert("PropertiesOfTableToClear", StrConcat(Properties, ","));
		If Context.MaxNumberOfBatches = 1 Then
			Context.TablesToClearUp.FillValues(Null, "LastRef");
		EndIf;
	EndIf;
	
	While True Do
		Context.IndexOfCurrentTable = Context.IndexOfCurrentTable + 1;
		If Context.IndexOfCurrentTable >= Context.TablesToClearUp.Count() Then
			Break;
		EndIf;
		TableToCleanUp = Context.TablesToClearUp.Get(Context.IndexOfCurrentTable);
		If TypeOf(TableToCleanUp.Nodes) <> Type("Array") Then
			TableToCleanUp.Nodes = TableNodes(TableToCleanUp);
		EndIf;
		If TableToCleanUp.IsRegister
		   And (TableToCleanUp.ClearAll
		      Or TableToCleanUp.Independent) Then
			If Not ContinueAddingCleanUpBatches(Context, NewBatches, TableToCleanUp) Then
				Break;
			EndIf;
			Continue;
		EndIf;
		InterruptExternalLoop = False;
		While True Do
			Query = DataRequest(TableToCleanUp, False, False, Context.PortionSize);
			QueryResult = Query.Execute();
			If QueryResult.IsEmpty() Then
				Break;
			EndIf;
			BatchOfRefs = QueryResult.Unload().UnloadColumn("Ref");
			If Not ContinueAddingCleanUpBatches(Context, NewBatches, TableToCleanUp, BatchOfRefs) Then
				InterruptExternalLoop = True;
				If BatchOfRefs.Count() = Context.PortionSize Then
					Context.IndexOfCurrentTable = Context.IndexOfCurrentTable - 1;
				EndIf;
				Break;
			EndIf;
		EndDo;
		If InterruptExternalLoop Then
			Break;
		EndIf;
	EndDo;
	
	If Context.Property("Percent")
	   And Not Context.Property("DeferredUpdate") Then
		Context.Percent = ?(Context.TablesToClearUp.Count() = 0, 100,
			Round((Context.IndexOfCurrentTable + 1) * 100 / Context.TablesToClearUp.Count()));
	EndIf;
	
EndProcedure

// 
Function IsObsoleteDataPurgeJobRunning(RaiseException1 = False)
	
	JobMetadata = Metadata.ScheduledJobs.ClearObsoleteData;
	If Not IsJobAlreadyRunning(JobMetadata.MethodName) Then
		Return False;
	EndIf;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Cannot start as the ""%1"" scheduled job is running.';"),
		JobMetadata.Presentation());
	
	If RaiseException1 Then
		Raise ErrorText;
	EndIf;
	
	Return True;
	
EndFunction

// 
Procedure SetTablesCleaningOrder(TablesToClearUp)
	
	TablesToClearUp.Sort("IsRegister Desc, ClearAll Desc, IsExchangePlan Asc");
	
EndProcedure

// 
Function TableNodes(TableToCleanUp)
	
	If Not TableToCleanUp.InExchangePlan Then
		Return New Array;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	CurrentTable.Node AS Node
	|FROM
	|	&CurrentTable AS CurrentTable";
	
	Query.Text = StrReplace(Query.Text,
		"&CurrentTable", TableToCleanUp.FullName + ".Changes");
	
	Return Query.Execute().Unload().UnloadColumn("Node");
	
EndFunction

// 
Function ContinueAddingCleanUpBatches(Context, NewBatches, TableToCleanUp, BatchOfRefs = Undefined)
	
	If TableToCleanUp.LastRef <> Null
	   And ValueIsFilled(BatchOfRefs) Then
		TableToCleanUp.LastRef = BatchOfRefs[BatchOfRefs.UBound()];
	EndIf;
	
	Properties = New Structure(Context.PropertiesOfTableToClear);
	FillPropertyValues(Properties, TableToCleanUp);
	
	NewBatch = New Structure;
	NewBatch.Insert("TableToCleanUp", Properties);
	NewBatch.Insert("PortionSize", Context.PortionSize);
	NewBatch.Insert("BatchOfRefs", BatchOfRefs);
	
	NewBatches.Insert(New UUID,
		CommonClientServer.ValueInArray(NewBatch));
	
	Return NewBatches.Count() < Context.MaxNumberOfBatches;
	
EndFunction


// 
Procedure ObsoleteDataOnCleaningBatchInBackground(Parameters) Export
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(True, False);
		Try
			ObsoleteDataOnBatchPurge(Parameters);
		Except
			ModuleAccessManagement.DisableAccessKeysUpdate(False, False);
			Raise;
		EndTry;
		ModuleAccessManagement.DisableAccessKeysUpdate(False, False);
	Else
		ObsoleteDataOnBatchPurge(Parameters);
	EndIf;
	
EndProcedure

// 
Procedure ObsoleteDataOnBatchPurge(Parameters)
	
	TableToCleanUp = Parameters.TableToCleanUp;
	BatchOfRefs     = Parameters.BatchOfRefs;
	PortionSize     = Parameters.PortionSize;
	
	If TableToCleanUp.IsRegister Then
		RegisterManager = Common.ObjectManagerByFullName(TableToCleanUp.FullName);
		RecordSet = RegisterManager.CreateRecordSet();
		Common.DisableRecordingControl(RecordSet);
	EndIf;
	
	TableNodes = TableToCleanUp.Nodes;
	
	If TableToCleanUp.ClearAll
	   And TableToCleanUp.IsRegister Then
		WriteWithAttempt(,, TableNodes,
			Common.MetadataObjectByFullName(TableToCleanUp.FullName));
		WriteWithAttempt(RecordSet);
		Return;
	EndIf;
	
	If TableToCleanUp.Independent Then
		Query = DataRequest(TableToCleanUp, False, False, PortionSize);
		For Each QueryDetails In Query Do
			RequestForDimensionValues = QueryDetails.Value;
			DimensionName = QueryDetails.Presentation;
			While True Do
				QueryResult = RequestForDimensionValues.Execute();
				If QueryResult.IsEmpty() Then
					Break;
				EndIf;
				Selection = QueryResult.Select();
				RecordSet = RegisterManager.CreateRecordSet();
				Common.DisableRecordingControl(RecordSet);
				While Selection.Next() Do
					FilterElement = RecordSet.Filter[DimensionName]; // FilterItem
					FilterElement.Set(Selection[DimensionName]);
					WriteWithAttempt(RecordSet);
				EndDo;
				If Parameters.Property("RuntimeBorder")
				   And Parameters.RuntimeBorder < CurrentSessionDate() Then
					Parameters.IsAllBatchesProcessed = False;
					Return;
				EndIf;
			EndDo;
		EndDo;
		
		Return;
	EndIf;
	
	If TableToCleanUp.IsExchangePlan Then
		MetadataTables = Common.MetadataObjectByFullName(TableToCleanUp.FullName);
	EndIf;
	
	For Each Ref In BatchOfRefs Do
		If TableToCleanUp.IsRegister Then
			FilterElement = RecordSet.Filter.Recorder; // FilterItem
			FilterElement.Set(Ref);
			WriteWithAttempt(,, TableNodes, RecordSet);
			WriteWithAttempt(RecordSet);
		Else
			If Not TableToCleanUp.IsExchangePlan Then
				WriteWithAttempt(,, TableNodes, Ref);
			ElsIf Ref.ThisNode <> True Then
				For Each CompositionItem In MetadataTables.Content Do
					WriteWithAttempt(,, Ref, CompositionItem.Metadata);
				EndDo;
			EndIf;
			WriteWithAttempt(Ref, True,, TableToCleanUp.IsExchangePlan);
		EndIf;
	EndDo;
	
EndProcedure

// 
Procedure WriteWithAttempt(Data, Delete = False, TableNodes = "", NodesData = Undefined)
	
	AttemptNumber = 1;
	While True Do
		Try
			If TableNodes <> "" Then
				TableNodes = TableNodes; // Array
				ExchangePlans.DeleteChangeRecords(TableNodes, NodesData);
			ElsIf Delete Then
				Data = Data; // CatalogRef
				CurrentObject = Data.GetObject();
				If CurrentObject <> Undefined Then
					Common.DisableRecordingControl(CurrentObject, NodesData);
					// 
					CurrentObject.Delete();
					// 
				EndIf;
			Else
				Data = Data; // CatalogObject
				Data.Write();
			EndIf;
		Except
			AttemptNumber = AttemptNumber + 1;
			BackgroundJob = GetCurrentInfoBaseSession().GetBackgroundJob();
			If BackgroundJob = Undefined
			 Or AttemptNumber > 10 Then
				Raise;
			EndIf;
			BackgroundJob.WaitForExecutionCompletion(AttemptNumber * 3);
			Continue;
		EndTry;
		Break;
	EndDo;
	
EndProcedure

// 
Procedure WriteCleanUpPlanToLog(Context)
	
	CleanUpPlan = ObsoleteDataPurgePlan(Context.CleanUpDeleteable, Context.TablesToClearUp);
	
	WriteLogEvent(
		NStr("en = 'Clear obsolete data.Cleanup plan';",
			Common.DefaultLanguageCode()),
		EventLogLevel.Information,,, CleanUpPlan);
	
EndProcedure

// 
Function ObsoleteDataPurgePlan(CleanUpDeleteable, TablesToClearUp = Undefined, ShouldConsiderDataSeparation = True) Export
	
	Rows = New Array;
	SeparatedDataUsageAvailable = Common.SeparatedDataUsageAvailable();
	
	If ShouldConsiderDataSeparation Or SeparatedDataUsageAvailable Then
		If TablesToClearUp = Undefined Then
			TablesToClearUp = TablesToClearUp(Not CleanUpDeleteable);
			SetTablesCleaningOrder(TablesToClearUp);
		EndIf;
		If Not Common.DataSeparationEnabled() Then
			Rows.Add(NStr("en = 'The following tables will be processed';"));
		ElsIf Not SeparatedDataUsageAvailable Then
			Rows.Add(NStr("en = 'The following shared tables will be processed (shared data)';"));
		Else
			Rows.Add(NStr("en = 'The following separated tables will be processed';"));
		EndIf;
		AddTablesDetailsToCleanUpPlan(Rows, TablesToClearUp);
	Else
		AllTables = TablesToClearUp(Not CleanUpDeleteable, False);
		
		Filter = New Structure("Shared2", True);
		SharedTables = AllTables.Copy(AllTables.FindRows(Filter));
		SetTablesCleaningOrder(SharedTables);
		Rows.Add(NStr("en = '1. The following shared tables will be processed (shared data).';"));
		AddTablesDetailsToCleanUpPlan(Rows, SharedTables);
		
		Rows.Add("");
		
		Filter = New Structure("Shared2", True);
		SeparatedTables = AllTables.Copy(AllTables.FindRows(Filter));
		SetTablesCleaningOrder(SeparatedTables);
		Rows.Add(NStr("en = '2. The following separated tables will be processed in data areas
		                           |   (the full cleanup plan is available only when you log in to a data area).';"));
		AddTablesDetailsToCleanUpPlan(Rows, SeparatedTables);
	EndIf;
	
	Return StrConcat(Rows, Chars.LF);
	
EndFunction

// 
Procedure AddTablesDetailsToCleanUpPlan(Rows, TablesToClearUp)
	
	For Each TableToCleanUp In TablesToClearUp Do
		Rows.Add("");
		Rows.Add(TableToCleanUp.Presentation + " (" + TableToCleanUp.FullName + ")");
		If TableToCleanUp.ClearAll Then
			Rows.Add("	" + NStr("en = 'Full cleanup';"));
			Continue;
		ElsIf TableToCleanUp.Independent Then
			Rows.Add("	" + NStr("en = 'Delete records by values in dimensions:';"));
			AddFieldsDetailsToCleanUpPlan(Rows, TableToCleanUp.RegisterFields);
			Continue;
		EndIf;
		If ValueIsFilled(TableToCleanUp.RegisterFields) Then
			Rows.Add("	" + NStr("en = 'Delete records by recorders if the main table dimensions contain values:';"));
			AddFieldsDetailsToCleanUpPlan(Rows, TableToCleanUp.RegisterFields);
		EndIf;
		If ValueIsFilled(TableToCleanUp.ExtdimensionFields) Then
			Rows.Add("	" + NStr("en = 'Delete records by recorders if dimensions of the extra dimension table contain values:';"));
			AddFieldsDetailsToCleanUpPlan(Rows, TableToCleanUp.ExtdimensionFields);
		EndIf;
	EndDo;
	
EndProcedure

// 
Procedure AddFieldsDetailsToCleanUpPlan(Rows, FieldsDetails)
	
	For Each FieldDetails In FieldsDetails Do
		Rows.Add("		" + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The ""%1"" dimension contains values of the following types:';"), FieldDetails.Key));
		For Each TypeDetails In FieldDetails.Value Do
			If TypeOf(TypeDetails.Value) = Type("Array") Then
				Rows.Add("			" + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'For the ""%1"" type, only the following values are checked:';"), String(TypeDetails.Key)) + "
					|				" + StrConcat(TypeDetails.Value, "
					|				"));
			Else
				Rows.Add("			""" + String(TypeDetails.Key) + """ (" + TypeDetails.Value + ")");
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure


// 
Procedure PurgeObsoleteDataInBackground(Parameters, ResultAddress) Export
	
	LastSendOut = CurrentSessionDate();
	LastPercent = 0;
	
	ModuleSaaSOperations = Undefined;
	Parameters.ShouldProcessDataAreas = Parameters.ShouldProcessDataAreas
		And Not Common.SeparatedDataUsageAvailable();
	
	Try
		PurgeObsoleteDataInBackgroundNoAttempt(Parameters);
		If Parameters.ShouldProcessDataAreas Then
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			DataAreas = ModuleSaaSOperations.DataAreasUsed().Unload().UnloadColumn(
				"DataArea");
			For Each DataArea In DataAreas Do
				ModuleSaaSOperations.SignInToDataArea(DataArea);
				PurgeObsoleteDataInBackgroundNoAttempt(Parameters); // 
				ModuleSaaSOperations.SignOutOfDataArea();
				If LastSendOut + 5 < CurrentSessionDate() Then
					NewPercentage = Int(DataAreas.Find(DataArea) / DataAreas.Count() * 100);
					If NewPercentage > LastPercent Then
						TimeConsumingOperations.ReportProgress(NewPercentage);
						LastPercent = NewPercentage;
					EndIf;
					LastSendOut = CurrentSessionDate();
				EndIf;
			EndDo;
		EndIf;
		Result = New Map;
	Except
		Result = ErrorInfo();
		If Parameters.ShouldProcessDataAreas
		   And ModuleSaaSOperations <> Undefined Then
			ModuleSaaSOperations.SignOutOfDataArea();
		EndIf;
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

// 
Procedure PurgeObsoleteDataInBackgroundNoAttempt(Parameters)

	ShouldProcessDataAreas = Parameters.ShouldProcessDataAreas;
	
	LastSendOut = CurrentSessionDate();
	LastPercent = 0;
	
	Context = New Structure("CleanUpDeleteable", Parameters.CleanUpDeleteable);
	While True Do
		NewBatches = New Map;
		ObsoleteDataOnRequestChunksInBackground(NewBatches, Context);
		If Not ValueIsFilled(NewBatches) Then
			Break;
		EndIf;
		For Each KeyAndValue In NewBatches Do
			ObsoleteDataOnCleaningBatchInBackground(KeyAndValue.Value[0]);
		EndDo;
		If Not ShouldProcessDataAreas
		   And LastSendOut + 5 < CurrentSessionDate() Then
			NewPercentage = Int(Context.IndexOfCurrentTable / Context.TablesToClearUp.Count() * 100);
			If NewPercentage > LastPercent Then
				TimeConsumingOperations.ReportProgress(NewPercentage);
				LastPercent = NewPercentage;
			EndIf;
			LastSendOut = CurrentSessionDate();
		EndIf;
	EndDo;
	
EndProcedure


// 
Procedure GenerateObsoleteDataListInBackground(Parameters, ResultAddress) Export
	
	ObsoleteData = New ValueTable;
	ObsoleteData.Columns.Add("FullTableName",     New TypeDescription("String"));
	ObsoleteData.Columns.Add("TablePresentation", New TypeDescription("String"));
	ObsoleteData.Columns.Add("Count",           New TypeDescription("Number"));
	ObsoleteData.Columns.Add("DataArea",        New TypeDescription("Number"));
	
	ModuleSaaSOperations = Undefined;
	Parameters.ShouldProcessDataAreas = Parameters.ShouldProcessDataAreas
		And Not Common.SeparatedDataUsageAvailable();
	
	LastSendOut = CurrentSessionDate();
	LastPercent = 0;
	
	Try
		GenerateListOfObsoleteDataInBackgroundNoAttempt(ObsoleteData, Parameters);
		If Parameters.ShouldProcessDataAreas Then
			ObsoleteData.FillValues(-1, "DataArea");
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			DataAreas = ModuleSaaSOperations.DataAreasUsed().Unload().UnloadColumn(
				"DataArea");
			For Each DataArea In DataAreas Do
				AreaObsoleteData = ObsoleteData.Copy(New Array);
				ModuleSaaSOperations.SignInToDataArea(DataArea);
				GenerateListOfObsoleteDataInBackgroundNoAttempt(AreaObsoleteData, Parameters); // 
				ModuleSaaSOperations.SignOutOfDataArea();
				If ValueIsFilled(AreaObsoleteData) Then
					NewRow = ObsoleteData.Add();
					FillPropertyValues(NewRow, AreaObsoleteData[0]);
					NewRow.DataArea = DataArea;
				EndIf;
				If LastSendOut + 5 < CurrentSessionDate() Then
					NewPercentage = Int(DataAreas.Find(DataArea) / DataAreas.Count() * 100);
					If NewPercentage > LastPercent Then
						TimeConsumingOperations.ReportProgress(NewPercentage);
						LastPercent = NewPercentage;
					EndIf;
					LastSendOut = CurrentSessionDate();
				EndIf;
			EndDo;
		EndIf;
		Result = ObsoleteData;
	Except
		Result = ErrorInfo();
		If Parameters.ShouldProcessDataAreas
		   And ModuleSaaSOperations <> Undefined Then
			ModuleSaaSOperations.SignOutOfDataArea();
		EndIf;
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

// 
Procedure GenerateListOfObsoleteDataInBackgroundNoAttempt(ObsoleteData, Parameters)
	
	TablesToClearUp = TablesToClearUp(Not Parameters.CleanUpDeleteable);
	CommonCount = 0;
	DisplayQuantity = Parameters.DisplayQuantity;
	ShouldProcessDataAreas = Parameters.ShouldProcessDataAreas;
	
	LastSendOut = CurrentSessionDate();
	LastPercent = 0;
	
	For Each TableToCleanUp In TablesToClearUp Do
		Query = DataRequest(TableToCleanUp, True, DisplayQuantity);
		QueryResult = Query.Execute(); // 
		Count = 0;
		If DisplayQuantity Then
			Selection = QueryResult.Select();
			If Selection.Next()
			   And TypeOf(Selection.Count) = Type("Number") Then
				Count = Selection.Count;
			EndIf;
		ElsIf Not QueryResult.IsEmpty() Then
			Count = 1;
		EndIf;
		If Not ShouldProcessDataAreas
		   And LastSendOut + 5 < CurrentSessionDate() Then
			NewPercentage = Int(TablesToClearUp.IndexOf(TableToCleanUp) / TablesToClearUp.Count() * 100);
			If NewPercentage > LastPercent Then
				TimeConsumingOperations.ReportProgress(NewPercentage);
				LastPercent = NewPercentage;
			EndIf;
			LastSendOut = CurrentSessionDate();
		EndIf;
		If Not ValueIsFilled(Count) Then
			Continue;
		EndIf;
		CommonCount = CommonCount + Count;
		If Not ShouldProcessDataAreas Then
			NewRow = ObsoleteData.Add();
			NewRow.FullTableName     = TableToCleanUp.FullName;
			NewRow.TablePresentation = TableToCleanUp.Presentation;
			NewRow.Count = Count;
		ElsIf Not DisplayQuantity Then
			Break;
		EndIf;
	EndDo;
	
	If ShouldProcessDataAreas
	   And CommonCount > 0
	 Or DisplayQuantity
	   And ObsoleteData.Count() > 1 Then
		
		If Not ShouldProcessDataAreas Then
			Presentation = NStr("en = 'Total number for all tables';");
		ElsIf DisplayQuantity Then
			Presentation = NStr("en = 'Total number for all area tables';");
		Else
			Presentation = NStr("en = 'There are tables to clear';");
		EndIf;
		
		NewRow = ObsoleteData.Insert(0);
		NewRow.TablePresentation = "<" + Presentation + ">";
		NewRow.Count = CommonCount;
	EndIf;
	
EndProcedure


// 
// 
//
// Parameters:
//  TableToCleanUp - ValueTableRow of See TablesToClearUp
//
// Returns:
//  Query - 
//  :
//    
//    
//
Function DataRequest(TableToCleanUp, PresentOnly = True, Count = False, PortionSize = 10000)
	
	QueryText =
	"SELECT DISTINCT TOP 10000
	|	&Field
	|FROM
	|	&CurrentTable AS CurrentTable
	|WHERE
	|	&Filter";
	
	Query = New Query;
	ParameterNamePrefix = StrReplace(TableToCleanUp.FullName, ".", "_") + "_";
	Field = "";
	HasRecorder = TableToCleanUp.IsRegister And Not TableToCleanUp.Independent;
	If PresentOnly And Count Then
		QueryText = StrReplace(QueryText, "TOP 10000", "");
		If HasRecorder Then
			Field = "COUNT(DISTINCT CurrentTable.Recorder) AS Count";
		Else
			Field = "COUNT(*) AS Count";
		EndIf;
	ElsIf PresentOnly Then
		QueryText = StrReplace(QueryText, "10000", "1");
		Field = "TRUE";
	ElsIf TableToCleanUp.Independent Then
		Field = "";
	Else
		FieldName = ?(TableToCleanUp.IsRegister, "Recorder", "Ref");
		Field = StrReplace("CurrentTable.FieldName AS Ref", "FieldName", FieldName);
		If TableToCleanUp.LastRef <> Null Then
			QueryText = QueryText + StrReplace("
			|
			|ORDER BY
			|	CurrentTable.FieldName", "FieldName", FieldName);
			If ValueIsFilled(TableToCleanUp.LastRef) Then
				ParameterName = ParameterNamePrefix + "LastRef";
				QueryText = StrReplace(QueryText, "&Filter", StrReplace(
				"CurrentTable.FieldName > &" + ParameterName + "
				|	AND (&Filter)", "FieldName", FieldName));
				Query.SetParameter(ParameterName, TableToCleanUp.LastRef);
			EndIf;
		EndIf;
	EndIf;
	
	QueryText = StrReplace(QueryText, "10000", Format(PortionSize, "NG="));
	
	If Not PresentOnly
	   And TableToCleanUp.Independent
	   And TableToCleanUp.RegisterFields.Count() > 0 Then
		
		QueryText = StrReplace(QueryText,
			"&CurrentTable", TableToCleanUp.FullName);
		
		Queries = New ValueList;
		For Each FieldDetails In TableToCleanUp.RegisterFields Do
			RegisterFields = New Map;
			RegisterFields.Insert(FieldDetails.Key, FieldDetails.Value);
			Query = New Query;
			Query.Text = StrReplace(QueryText, "&Field",
				"CurrentTable." + FieldDetails.Key + " AS " + FieldDetails.Key);
			ApplyFilterToQueryText(RegisterFields, Query.Text, Query, ParameterNamePrefix);
			Queries.Add(Query, FieldDetails.Key);
		EndDo;
		
		Return Queries;
	EndIf;
	
	If TableToCleanUp.IsRegister
	   And ValueIsFilled(TableToCleanUp.RegisterFields)
	   And ValueIsFilled(TableToCleanUp.ExtdimensionFields) Then
	
		QueryText = StrReplace(QueryText, "&Field",
			"CurrentTable.Recorder AS Recorder");
		If PresentOnly And Not Count Then
			QueryText = StrReplace(QueryText, "DISTINCT", "");
		EndIf;
		QueryText1 = StrReplace(QueryText,
			"&CurrentTable", TableToCleanUp.FullName);
		QueryText2 = StrReplace(QueryText,
			"&CurrentTable", TableToCleanUp.FullName + ".ExtDimension");
		ApplyFilterToQueryText(TableToCleanUp.RegisterFields,
			QueryText1, Query, ParameterNamePrefix);
		ApplyFilterToQueryText(TableToCleanUp.ExtdimensionFields,
			QueryText2, Query, ParameterNamePrefix + "2_");
		QueryText =
		"SELECT DISTINCT TOP 10000
		|	&Field
		|FROM
		|	(SELECT &CurrentTable1
		|	
		|	UNION ALL
		|	
		|	SELECT &CurrentTable2) AS CurrentTable";
		If PresentOnly And Count Then
			QueryText = StrReplace(QueryText, "DISTINCT TOP 10000", "");
		ElsIf PresentOnly Then
			QueryText = StrReplace(QueryText, "DISTINCT TOP 10000", "TOP 1");
		EndIf;
		If PresentOnly Or TableToCleanUp.LastRef = Null Then
			QueryText = StrReplace(QueryText, "&Field", Field);
			QueryText = StrReplace(QueryText, "SELECT &CurrentTable1",
				StrReplace(QueryText1, Chars.LF, Chars.LF + Chars.Tab));
			QueryText = StrReplace(QueryText, "SELECT &CurrentTable2",
				StrReplace(QueryText2, Chars.LF, Chars.LF + Chars.Tab));
		Else
			QueryText =
			"SELECT DISTINCT TOP 10000
			|	CurrentTable.Recorder AS Ref
			|FROM
			|	(SELECT
			|		CurrentTable1.Recorder AS Recorder
			|	FROM
			|		CurrentTable1 AS CurrentTable1
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CurrentTable2.Recorder
			|	FROM
			|		CurrentTable2 AS CurrentTable2) AS CurrentTable
			|
			|ORDER BY
			|	CurrentTable.Recorder";
			QueryText = StrReplace(QueryText1,
				"CurrentTable.Recorder AS Recorder",
				"CurrentTable.Recorder AS Recorder
				|INTO CurrentTable1")
				+ Common.QueryBatchSeparator()
				+ StrReplace(QueryText2,
				"CurrentTable.Recorder AS Recorder",
				"CurrentTable.Recorder AS Recorder
				|INTO CurrentTable2")
				+ Common.QueryBatchSeparator()
				+ QueryText;
		EndIf;
		QueryText = StrReplace(QueryText, "10000", Format(PortionSize, "NG="));
	Else
		If Not HasRecorder Or PresentOnly Then
			QueryText = StrReplace(QueryText, "DISTINCT", "");
		EndIf;
		QueryText = StrReplace(QueryText,
			"&CurrentTable", TableToCleanUp.FullName
			+ ?(ValueIsFilled(TableToCleanUp.ExtdimensionFields), ".ExtDimension", ""));
		QueryText = StrReplace(QueryText, "&Field", Field);
		If TableToCleanUp.IsRegister Then
			ApplyFilterToQueryText(?(ValueIsFilled(TableToCleanUp.ExtdimensionFields),
				TableToCleanUp.ExtdimensionFields, TableToCleanUp.RegisterFields),
				QueryText, Query, ParameterNamePrefix);
		Else
			QueryText = StrReplace(QueryText, "&Filter", "TRUE");
		EndIf;
	EndIf;
	
	Query.Text = Query.Text + QueryText;
	
	Return Query;
	
EndFunction

// 
Procedure ApplyFilterToQueryText(FieldsDetails, QueryText, Query, ParameterNamePrefix)
	
	Filter = "";
	FilterConnections = "";
	
	For Each FieldDetails In FieldsDetails Do
		TypesToClear = New Map;
		ValuesToClear = New Map;
		For Each TypeDetails In FieldDetails.Value Do
			If TypeOf(TypeDetails.Value) = Type("Array") Then
				ValuesToClear.Insert(TypeDetails.Key, TypeDetails.Value);
			Else
				TypesToClear.Insert(TypeDetails.Key, TypeDetails.Value);
			EndIf;
		EndDo;
		
		If FieldDetails.Value.Count() > 100
		   And ValueIsFilled(TypesToClear) Then
			
			ParameterName = ParameterNamePrefix + FieldDetails.Key;
			TemporaryTableQueryText =
			"SELECT
			|	CurrentTable.EmptyRef AS EmptyRef
			|INTO TempTable
			|FROM
			|	&TempTable AS CurrentTable
			|
			|INDEX BY
			|	EmptyRef";
			TemporaryTableQueryText = StrReplace(TemporaryTableQueryText,
				"TempTable", ParameterName);
			Query.Text = TemporaryTableQueryText
				+ Common.QueryBatchSeparator() + Query.Text;
			FilterConnections = FilterConnections + ?(FilterConnections = "", "", Chars.LF);
			FilterConnections = FilterConnections + StringFunctionsClientServer.SubstituteParametersToString(
			"		LEFT JOIN %1 AS %1
			|		ON (VALUETYPE(%1.EmptyRef) = VALUETYPE(CurrentTable.%2))
			|", ParameterName, FieldDetails.Key);
			Filter = Filter + ?(Filter = "", "", "
			|	OR ");
			Filter = Filter + StringFunctionsClientServer.SubstituteParametersToString(
				"NOT %1.EmptyRef IS NULL", ParameterName);
			BlankRefs = New Array;
			RefsTypes = New Array;
			ParameterValue = New ValueTable;
			For Each TypeDetails In TypesToClear Do
				BlankRefs.Add(PredefinedValue(TypeDetails.Value + ".EmptyRef"));
				RefsTypes.Add(TypeDetails.Key);
				ParameterValue.Add();
			EndDo;
			ParameterValue.Columns.Add("EmptyRef", New TypeDescription(RefsTypes));
			ParameterValue.LoadColumn(BlankRefs, "EmptyRef");
			Query.SetParameter(ParameterName, ParameterValue);
		Else
			For Each TypeDetails In TypesToClear Do
				Filter = Filter + ?(Filter = "", "", "
				|	OR ");
				If StrFind(TypeDetails.Value, ".") > 0 Then
					Filter = Filter + StringFunctionsClientServer.SubstituteParametersToString(
						"VALUETYPE(CurrentTable.%1) = TYPE(%2)",
						FieldDetails.Key, TypeDetails.Value);
				Else
					ParameterName = "Type" + TypeDetails.Value;
					Query.SetParameter(ParameterName, Type(TypeDetails.Value));
					Filter = Filter + StringFunctionsClientServer.SubstituteParametersToString(
						"VALUETYPE(CurrentTable.%1) = &%2",
						FieldDetails.Key, ParameterName);
				EndIf;
			EndDo;
		EndIf;
		For Each TypeDetails In ValuesToClear Do
			Filter = Filter + ?(Filter = "", "", "
			|	OR ");
			Filter = Filter + StringFunctionsClientServer.SubstituteParametersToString(
				"CurrentTable.%1 IN (%2)",
				FieldDetails.Key,
				"VALUE(" + StrConcat(TypeDetails.Value, "), VALUE(") + ")");
		EndDo;
	EndDo;
	
	QueryText = StrReplace(QueryText, "&Filter", Filter);
	QueryText = StrReplace(QueryText, "WHERE", FilterConnections + "WHERE");
	
EndProcedure

// 
// 
// 
//
// Parameters:
//  RegistersOnly - Boolean
//  ShouldConsiderDataSeparation - Boolean
//
// Returns:
//  ValueTable:
//   * Order       - Number
//   * FullName     - String
//   * Presentation - String
//   * ClearAll   - Boolean
//   * IsRegister    - Boolean
//   * Independent   - Boolean - 
//   * RegisterFields  - See RegisterNewFields
//   * ExtdimensionFields  - See RegisterNewFields
//   * IsExchangePlan - Boolean
//   * InExchangePlan  - Boolean - 
//   * Shared2 - Boolean
//
Function TablesToClearUp(RegistersOnly, ShouldConsiderDataSeparation = True)
	
	Objects = New Map;
	SSLSubsystemsIntegration.OnPopulateObjectsPlannedForDeletion(Objects);
	InfobaseUpdateOverridable.OnPopulateObjectsPlannedForDeletion(Objects);
	
	Result = New ValueTable;
	Result.Columns.Add("Order",       New TypeDescription("Number"));
	Result.Columns.Add("FullName",     New TypeDescription("String"));
	Result.Columns.Add("Presentation", New TypeDescription("String"));
	Result.Columns.Add("ClearAll",   New TypeDescription("Boolean"));
	Result.Columns.Add("IsRegister",    New TypeDescription("Boolean"));
	Result.Columns.Add("Independent",   New TypeDescription("Boolean"));
	Result.Columns.Add("RegisterFields",  New TypeDescription("Map"));
	Result.Columns.Add("ExtdimensionFields",  New TypeDescription("Map"));
	Result.Columns.Add("IsExchangePlan", New TypeDescription("Boolean"));
	Result.Columns.Add("InExchangePlan",  New TypeDescription("Boolean"));
	Result.Columns.Add("Shared2", New TypeDescription("Boolean"));
	Result.Columns.Add("Nodes");
	Result.Columns.Add("LastRef");
	
	ObjectsKindsOrder = ObjectsKindsOrder();
	ChangeRecords = ChangeRecords();
	TablesToEmpty  = New Map;
	DeletedTypes        = New Map;
	FieldsTypeToDelete   = New Map;
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Error in procedure %1 of common module %2.';"),
			"OnPopulateObjectsPlannedForDeletion",
			"InfobaseUpdateOverridable")
		+ Chars.LF + Chars.LF;
	
	For Each ObjectDetails In Objects Do
		NameParts = StrSplit(ObjectDetails.Key, ".");
		If NameParts.Count() = 2 Then
			FullName = ObjectDetails.Key;
			FieldName = Undefined;
		Else
			FieldName = NameParts[2];
			FullName = NameParts[0] + "." + NameParts[1];
			NameParts.Delete(0);
			NameParts.Delete(0);
			FieldName = StrConcat(NameParts, ".");
		EndIf;
		MetadataObject = Common.MetadataObjectByFullName(FullName);
		If MetadataObject = Undefined Then
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The ""%1"" metadata object does not exist.';"), FullName);
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		ElsIf FieldName = Undefined And Not StrStartsWith(MetadataObject.Name, "Delete") Then
			ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The ""%1"" metadata object name must begin with ""%2"".';"), FullName, "Delete");
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndIf;
		FullName = MetadataObject.FullName();
		IsEnum = Common.IsEnum(MetadataObject);
		IsBusinessProcess = Common.IsBusinessProcess(MetadataObject);
		If FieldName = Undefined Or IsEnum Or IsBusinessProcess Then
			If Common.IsRefTypeObject(MetadataObject) Or IsEnum Then
				RefType = Type(StrReplace(FullName, ".", "Ref."));
				If FieldName = Undefined Then
					DeletedTypes.Insert(RefType, FullName);
					If IsBusinessProcess Then
						RouteDotsType = TypeOf(PredefinedValue(FullName + ".RoutePoint.EmptyRef"));
						DeletedTypes.Insert(RouteDotsType, FullName + ".Points");
					EndIf;
				ElsIf IsEnum Then
					ValueMetadata = MetadataObject.EnumValues.Find(FieldName); // MetadataObject
					If ValueMetadata = Undefined Then
						ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
							NStr("en = 'The ""%1"" value does not exist.';"), ObjectDetails.Key);
						Raise(ErrorText, ErrorCategory.ConfigurationError);
					ElsIf Not StrStartsWith(ValueMetadata.Name, "Delete") Then
						ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
							NStr("en = 'The ""%1"" value name must begin with ""%2"".';"), ObjectDetails.Key, "Delete");
						Raise(ErrorText, ErrorCategory.ConfigurationError);
					EndIf;
					EnumValues = DeletedTypes.Get(RefType);
					If EnumValues = Undefined Then
						EnumValues = New Map;
						DeletedTypes.Insert(RefType, EnumValues);
					EndIf;
					If TypeOf(EnumValues) = Type("Map") Then
						EnumValues.Insert(FullName + "." + ValueMetadata.Name, True);
					EndIf;
					Continue;
				ElsIf Upper(FieldName) = Upper("Points") Then
					RouteDotsType = TypeOf(PredefinedValue(FullName + ".RoutePoint.EmptyRef"));
					DeletedTypes.Insert(RouteDotsType, FullName + ".Points");
				Else // 
					FieldParts = StrSplit(FieldName, ".", True);
					RoutePoint = Undefined;
					If FieldParts.Count() = 2 Then
						BusinessProcessManager = Common.ObjectManagerByFullName(FullName);
						SoughtName = Upper(FieldParts[1]);
						For Each RouteCurrentPoint In BusinessProcessManager.RoutePoints Do
							If Upper(RouteCurrentPoint.Name) = SoughtName Then
								RoutePoint = RouteCurrentPoint;
								Break;
							EndIf;
						EndDo;
					EndIf;
					If RoutePoint = Undefined
					 Or Upper(FieldParts[0]) <> Upper("RoutePoint") Then
						ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
							NStr("en = 'The ""%1"" value is not an existing route point.';"), ObjectDetails.Key);
						Raise(ErrorText, ErrorCategory.ConfigurationError);
					ElsIf Not StrStartsWith(RoutePoint.Name, "Delete") Then
						ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
							NStr("en = 'The ""%1"" route point name must begin with ""%2"".';"), ObjectDetails.Key, "Delete");
						Raise(ErrorText, ErrorCategory.ConfigurationError);
					EndIf;
					RouteDotsType = TypeOf(PredefinedValue(FullName + ".RoutePoint.EmptyRef"));
					RouteDotsValues = DeletedTypes.Get(RouteDotsType);
					If RouteDotsValues = Undefined Then
						RouteDotsValues = New Map;
						DeletedTypes.Insert(RouteDotsType, RouteDotsValues);
					EndIf;
					If TypeOf(RouteDotsValues) = Type("Map") Then
						RouteDotsValues.Insert(FullName + ".RoutePoint." + RoutePoint.Name, True);
					EndIf;
					Continue;
				EndIf;
			EndIf;
			If ObjectDetails.Value = True And Not IsEnum Then
				IsRegister = Common.IsRegister(MetadataObject);
				If Not RegistersOnly Or IsRegister Then
					TablesToEmpty.Insert(FullName, True);
					NewRow = Result.Add();
					NewRow.Order       = ObjectsKindsOrder.Get(StrSplit(FullName, ".")[0]);
					NewRow.FullName     = FullName;
					NewRow.Presentation = MetadataObject.Presentation();
					NewRow.ClearAll   = True;
					NewRow.IsRegister    = IsRegister;
					NewRow.Independent   = IsRegister
						And Common.IsInformationRegister(MetadataObject)
						And MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent;
					NewRow.IsExchangePlan = Common.IsExchangePlan(MetadataObject);
					NewRow.InExchangePlan  = ChangeRecords.Get(MetadataObject) <> Undefined;
					NewRow.Shared2 = IsSharedObject(MetadataObject);
				EndIf;
			EndIf;
		Else
			FieldsTypeToDelete.Insert(FullName + "." + FieldName, ObjectDetails.Value);
		EndIf;
	EndDo;
	
	RegistersTypesToClear = RegistersTypesToClear();
	RefineRegisterTypesToBeCleaned(RegistersTypesToClear);
	
	Context = New Structure;
	Context.Insert("TablesToClearUp",        Result);
	Context.Insert("ErrorTitle",         ErrorTitle);
	Context.Insert("DeletedTypes",           DeletedTypes);
	Context.Insert("FieldsTypeToDelete",      FieldsTypeToDelete);
	Context.Insert("TablesNamesByType",      TablesNamesByType());
	Context.Insert("TablesToEmpty",     TablesToEmpty);
	Context.Insert("ObjectsKindsOrder",    ObjectsKindsOrder);
	Context.Insert("ChangeRecords",    ChangeRecords);
	Context.Insert("RegistersTypesToClear", RegistersTypesToClear);
	Context.Insert("PrimitiveTypesNames",       TablesFieldsPrimitiveTypesNames());
	
	AddRegisterFieldTypesToDelete(Context, "InformationRegisters");
	AddRegisterFieldTypesToDelete(Context, "AccumulationRegisters");
	AddRegisterFieldTypesToDelete(Context, "AccountingRegisters");
	AddRegisterFieldTypesToDelete(Context, "CalculationRegisters");
	
	RedundantFieldsTypes = New Array;
	For Each FieldDeletableTypes In FieldsTypeToDelete Do
		FieldTypesNames = New Array;
		For Each KeyAndValue In FieldDeletableTypes.Value Do
			FieldTypesNames.Add(Common.TypePresentationString(KeyAndValue.Key));
		EndDo;
		RedundantFieldsTypes.Add(FieldDeletableTypes.Key + " (" + StrConcat(FieldTypesNames, ", ") + ")");
	EndDo;
	If ValueIsFilled(RedundantFieldsTypes) Then
		ErrorText = ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'You cannot use the following field types to clear obsolete data:
			           |%1';"),
			"- " + StrConcat(RedundantFieldsTypes, ";" + Chars.LF + "- ") + ".");
		Raise(ErrorText. ErrorCategory.ConfigurationError);
	EndIf;
	
	If ShouldConsiderDataSeparation And Common.DataSeparationEnabled() Then
		Filter = New Structure("Shared2", Not Common.SeparatedDataUsageAvailable());
		Result = Result.Copy(Result.FindRows(Filter));
	EndIf;
	
	Result.Sort("Order, FullName");
	
	Return Result;
	
EndFunction

// 
Function ChangeRecords()
	
	Result = New Map;
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		For Each CompositionItem In ExchangePlan.Content Do
			Result.Insert(CompositionItem.Metadata, True);
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

// 
Function ObjectsKindsOrder()
	
	Result = New Map;
	Result.Insert("ExchangePlan", 1);
	Result.Insert("Catalog", 2);
	Result.Insert("Document", 3);
	Result.Insert("Enum", 4);
	Result.Insert("ChartOfCharacteristicTypes", 5);
	Result.Insert("ChartOfAccounts", 6);
	Result.Insert("ChartOfCalculationTypes", 7);
	Result.Insert("InformationRegister", 8);
	Result.Insert("AccumulationRegister", 9);
	Result.Insert("AccountingRegister", 10);
	Result.Insert("CalculationRegister", 11);
	Result.Insert("BusinessProcess", 12);
	Result.Insert("Task", 13);
	
	Return Result;
	
EndFunction

// 
// 
//
// 
// 
// 
//
// Returns:
//  Structure:
//   * InformationRegisters - Boolean
//   * AccumulationRegisters - Boolean
//   * AccountingRegisters - Boolean
//   * AccountingRegistersExtDimensions - Boolean
//   * CalculationRegisters - Boolean
//
Function RegistersTypesToClear()
	
	Result = New Structure;
	Result.Insert("InformationRegisters", True);
	Result.Insert("AccumulationRegisters", False);
	Result.Insert("AccountingRegisters", False);
	Result.Insert("AccountingRegistersExtDimensions", False);
	Result.Insert("CalculationRegisters", False);
	
	Return Result;
	
EndFunction

Function TablesNamesByType()
	
	Result = New Map;
	For Each BusinessProcessMetadata In Metadata.BusinessProcesses Do
		FullName = BusinessProcessMetadata.FullName();
		RouteDotsType = TypeOf(PredefinedValue(FullName + ".RoutePoint.EmptyRef"));
		Result.Insert(RouteDotsType, FullName + ".Points");
	EndDo;
	
	Return Result;
	
EndFunction

Function TablesFieldsPrimitiveTypesNames();
	
	Names = New Map;
	Names.Insert(Type("Number"), "Number");
	Names.Insert(Type("String"), "String");
	Names.Insert(Type("Date"), "Date");
	Names.Insert(Type("Boolean"), "Boolean");
	Names.Insert(Type("ValueStorage"), "ValueStorage");
	Names.Insert(Type("UUID"), "UUID");
	
	Return Names;
	
EndFunction

// 
//
// Parameters:
//  TypesOfCleaning - See RegistersTypesToClear
//
Procedure RefineRegisterTypesToBeCleaned(TypesOfCleaning)
	Return;
EndProcedure

// 
Function IsSharedObject(MetadataObject)
	
	If Not Common.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	Separated1 = False;
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		Separated1 = ModuleSaaSOperations.IsSeparatedMetadataObject(MetadataObject);
	EndIf;
	
	Return Not Separated1;
	
EndFunction

// 
Procedure AddRegisterFieldTypesToDelete(Context, RegistersKind)
	
	Registers = Metadata[RegistersKind]; // MetadataObjectCollection
	
	For Each Register In Registers Do
		FullName = Register.FullName();
		RegisterFields = RegisterNewFields();
		ExtdimensionFields = RegisterNewFields();
		If Registers <> Metadata.InformationRegisters
		 Or Register.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
			For Each StandardAttribute In Register.StandardAttributes Do
				StandardAttribute = StandardAttribute; // StandardAttributeDescription
				If StandardAttribute.Name = "Recorder" Then
					AddDeleteableFieldTypes(RegisterFields, StandardAttribute, FullName, Context, RegistersKind);
				EndIf;
			EndDo;
			Independent = False;
		Else
			Independent = True;
		EndIf;
		For Each Dimension In Register.Dimensions Do
			If Registers = Metadata.AccountingRegisters
			   And Not Dimension.Balance
			   And Register.ChartOfAccounts <> Undefined
			   And Register.Correspondence Then
				Field = New Structure("Name, Type",, Dimension.Type);
				Field.Name = Dimension.Name + "Dr";
				AddDeleteableFieldTypes(RegisterFields, Field, FullName, Context, RegistersKind);
				Field.Name = Dimension.Name + "Cr";
				AddDeleteableFieldTypes(RegisterFields, Field, FullName, Context, RegistersKind);
				Continue;
			EndIf;
			AddDeleteableFieldTypes(RegisterFields, Dimension, FullName, Context, RegistersKind);
		EndDo;
		If Registers = Metadata.AccountingRegisters
		   And Register.ChartOfAccounts <> Undefined Then
			CoARefTypeName = StrReplace(Register.ChartOfAccounts.FullName(), ".", "Ref.");
			Field = New Structure("Name, Type", "Account", New TypeDescription(CoARefTypeName));
			If Register.Correspondence Then
				Field.Name = "AccountDr";
				AddDeleteableFieldTypes(RegisterFields, Field, FullName, Context, RegistersKind);
				Field.Name = "AccountCr";
				AddDeleteableFieldTypes(RegisterFields, Field, FullName, Context, RegistersKind);
			Else
				AddDeleteableFieldTypes(RegisterFields, Field, FullName, Context, RegistersKind);
			EndIf;
			If Register.ChartOfAccounts.MaxExtDimensionCount > 0
			   And Register.ChartOfAccounts.ExtDimensionTypes <> Undefined Then
				ExtDimensionTypeRefTypeName = StrReplace(Register.ChartOfAccounts.ExtDimensionTypes.FullName(), ".", "Ref.");
				Field = New Structure("Name, Type", "Kind", New TypeDescription(ExtDimensionTypeRefTypeName));
				AddDeleteableFieldTypes(ExtdimensionFields, Field, FullName, Context, "AccountingRegistersExtDimensions");
				Field = New Structure("Name, Type", "Value", Register.ChartOfAccounts.ExtDimensionTypes.Type);
				AddDeleteableFieldTypes(ExtdimensionFields, Field, FullName, Context, "AccountingRegistersExtDimensions");
			EndIf;
		EndIf;
		If Context.TablesToEmpty.Get(FullName) = Undefined
		   And (ValueIsFilled(RegisterFields)
		      Or ValueIsFilled(ExtdimensionFields)) Then
			NewRow = Context.TablesToClearUp.Add();
			NewRow.Order       = Context.ObjectsKindsOrder.Get(StrSplit(FullName, ".")[0]);
			NewRow.FullName     = FullName;
			NewRow.Presentation = Register.Presentation();
			NewRow.IsRegister    = True;
			NewRow.Independent   = Independent;
			NewRow.RegisterFields  = RegisterFields;
			NewRow.ExtdimensionFields  = ExtdimensionFields;
			NewRow.InExchangePlan  = Context.ChangeRecords.Get(Register) <> Undefined;
			NewRow.Shared2 = IsSharedObject(Register);
		EndIf;
	EndDo;
	
EndProcedure

// 
//
// Returns:
//  Map of KeyAndValue:
//   * Key     - field name.
//   * Value - Map of KeyAndValue:
//      ** Key     - Type -  link type.
//      ** Value - String - 
//                  - Array of String - 
//
Function RegisterNewFields()
	
	Return New Map;
	
EndFunction

// 
Procedure AddDeleteableFieldTypes(Fields, Field, FullRegisterName, Context, RegistersKind)
	
	AllDeleteableFieldTypes = Fields.Get(Field.Name);
	If AllDeleteableFieldTypes = Undefined Then
		AllDeleteableFieldTypes = New Map;
	EndIf;
	FieldTypes = Field.Type;
	
	If Context.RegistersTypesToClear[RegistersKind] Then
		DeletedTypes = Context.DeletedTypes;
		For Each Type In FieldTypes.Types() Do
			TableName = DeletedTypes.Get(Type);
			If TableName = Undefined Then
				Continue;
			EndIf;
			If TypeOf(TableName) = Type("String") Then
				AllDeleteableFieldTypes.Insert(Type, TableName);
			Else
				AddEnumValues(AllDeleteableFieldTypes, Type, TableName);
			EndIf;
		EndDo;
	EndIf;
	
	FullFieldName1 = FullRegisterName + "." + Field.Name;
	FieldDeletableTypes = Context.FieldsTypeToDelete.Get(FullFieldName1);
	If FieldDeletableTypes <> Undefined Then
		TablesNamesByType = Context.TablesNamesByType;
		For Each KeyAndValue In FieldDeletableTypes Do
			TypeOrValue = KeyAndValue.Key;
			If TypeOf(TypeOrValue) = Type("Type") Then
				Type = TypeOrValue;
			Else
				Type = TypeOf(TypeOrValue);
			EndIf;
			If Not FieldTypes.ContainsType(Type) Then
				ErrorText = Context.ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'The ""%1"" field does not contain the ""%2"" type.';"),
					FullFieldName1, Common.TypePresentationString(Type));
				Raise(ErrorText, ErrorCategory.ConfigurationError);
			Else
				TableName = TablesNamesByType.Get(Type);
				If TableName = Undefined Then
					TableName = Context.PrimitiveTypesNames.Get(Type);
					If TableName = Undefined Then
						MetadataTables = Metadata.FindByType(Type);
						If MetadataTables = Undefined Then
							ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("en = 'Cannot find a metadata object by the %1 type being deleted in the %2 field.';"),
								String(Type), FullFieldName1);
							WriteLogEvent(
								NStr("en = 'Clear obsolete data.Error preparing the list of tables to clear';",
									Common.DefaultLanguageCode()),
								EventLogLevel.Error,,, ErrorText);
							Continue;
						EndIf;
						TableName = MetadataTables.FullName();
					EndIf;
					TablesNamesByType.Insert(Type, TableName);
				EndIf;
				If Type = TypeOrValue Then
					AllDeleteableFieldTypes.Insert(Type, TableName);
				Else
					IsEnumValue = Enums.AllRefsType().ContainsType(Type);
					If Not IsEnumValue
					   And Not BusinessProcesses.RoutePointsAllRefsType().ContainsType(Type) Then
						ErrorText = Context.ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
							NStr("en = 'The ""%1""field
							           |contains a value of the ""%2"" type,
							           |which is not an enumeration value or a business process route point.';"),
							FullFieldName1,
							Common.TypePresentationString(Type));
						Raise(ErrorText, ErrorCategory.ConfigurationError);
					EndIf;
					ValuesToDelete = New Map;
					If IsEnumValue Then
						ValuesToDelete.Insert(TableName + "." + XMLString(TypeOrValue), True);
					Else
						RoutePoint = TypeOrValue; // BusinessProcessRoutePointRefBusinessProcessName
						NameParts = StrSplit(TableName, ".");
						NameParts[2] = "RoutePoint";
						ValuesToDelete.Insert(StrConcat(NameParts, ".") + "." + RoutePoint.Name, True);
					EndIf;
					AddEnumValues(AllDeleteableFieldTypes, Type, ValuesToDelete);
				EndIf;
			EndIf;
		EndDo;
		Context.FieldsTypeToDelete.Delete(FullFieldName1);
	EndIf;
	
	If ValueIsFilled(AllDeleteableFieldTypes) Then
		Fields.Insert(Field.Name, AllDeleteableFieldTypes);
	EndIf;
	
EndProcedure

// 
Procedure AddEnumValues(AllDeleteableFieldTypes, Type, ValuesToDelete)
	
	AllValues = AllDeleteableFieldTypes.Get(Type);
	If TypeOf(AllValues) = Type("String") Then
		Return;
	EndIf;
	
	If AllValues = Undefined Then
		AllValues = New Array;
		AllDeleteableFieldTypes.Insert(Type, AllValues);
	EndIf;
	
	For Each KeyAndValue In ValuesToDelete Do
		If AllValues.Find(KeyAndValue.Key) = Undefined Then
			AllValues.Add(KeyAndValue.Key);
		EndIf;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

////////////////////////////////////////////////////////////////////////////////
// 

Procedure SetProcedureForDeferredUpdate() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.SetDeferredUpdateProcedureInSaaS);
	
	If Not Common.DataSeparationEnabled()
		Or Common.SeparatedDataUsageAvailable() Then
		// 
		Jobs = ScheduledJobsServer.FindJobs(New Structure("Metadata", Metadata.ScheduledJobs.SetDeferredUpdateProcedureInSaaS));
		For Each Job In Jobs Do
			ScheduledJobsServer.ChangeJob(Job.UUID,
				New Structure("Use", False));
		EndDo;
		Return;
	EndIf;
	
	UpdateProgress = InfobaseUpdate.DataAreasUpdateProgress("Deferred2");
	AreasToCheck = UpdateProgress.AreasRunning;
	CommonClientServer.SupplementArray(AreasToCheck, UpdateProgress.AreasWithIssues, True);
	CommonClientServer.SupplementArray(AreasToCheck, UpdateProgress.AreasWaitingFor, True);
	
	OrderOfDataToProcess = Constants.OrderOfDataToProcess.Get();
	
	Statuses = New Array;
	Statuses.Add(Enums.UpdateHandlersStatuses.NotPerformed);
	Statuses.Add(Enums.UpdateHandlersStatuses.Running);
	
	Query = New Query;
	Query.SetParameter("AreasToCheck", AreasToCheck);
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.SetParameter("Order", Enums.OrderOfUpdateHandlers.Crucial);
	Query.SetParameter("Statuses", Statuses);
	Query.Text = 
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode
		|	AND UpdateHandlers.DataAreaAuxiliaryData IN(&AreasToCheck)
		|	AND UpdateHandlers.Order = &Order
		|	AND UpdateHandlers.Status IN(&Statuses)
		|	AND &CommonHandlersCondition";
	
	CommonHandlersCondition = "TRUE";
	If OrderOfDataToProcess = Enums.OrderOfUpdateHandlers.Normal Then
		// 
		CommonHandlersCondition = "(Not UpdateHandlers.IsSeveritySeparationUsed
			|	Or Not UpdateHandlers.IsUpToDateDataProcessed)";
		// 
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&CommonHandlersCondition", CommonHandlersCondition);
	
	DisableJob = False;
	If Query.Execute().IsEmpty() Then
		If OrderOfDataToProcess = Enums.OrderOfUpdateHandlers.Crucial Then
			Constants.OrderOfDataToProcess.Set(Enums.OrderOfUpdateHandlers.Normal);
		Else
			Constants.OrderOfDataToProcess.Set(Enums.OrderOfUpdateHandlers.Noncritical);
			DisableJob = True;
		EndIf;
	EndIf;
	
	If DisableJob Then
		ScheduledJobsServer.SetScheduledJobUsage(Metadata.ScheduledJobs.SetDeferredUpdateProcedureInSaaS, False);
	EndIf;
	
EndProcedure

Procedure DisableAccessKeysUpdate(Value, SubsystemExists)
	If SubsystemExists Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(Value);
	EndIf;
EndProcedure

Function DataUpdateModeInLocalMode()
	
	SetPrivilegedMode(True);
	Query = New Query;
	Query.Text = 
		"SELECT
		|	1 AS HasSubsystemVersions
		|FROM
		|	InformationRegister.SubsystemsVersions AS SubsystemsVersions";
	
	BatchExecutionResult = Query.ExecuteBatch();
	If BatchExecutionResult[0].IsEmpty() Then
		Return "InitialFilling";
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	1 AS HasSubsystemVersions
		|FROM
		|	InformationRegister.SubsystemsVersions AS SubsystemsVersions
		|WHERE
		|	SubsystemsVersions.IsMainConfiguration = TRUE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS HasSubsystemVersions
		|FROM
		|	InformationRegister.SubsystemsVersions AS SubsystemsVersions
		|WHERE
		|	SubsystemsVersions.SubsystemName = &BaseConfigurationName
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS HasSubsystemVersions
		|FROM
		|	InformationRegister.SubsystemsVersions AS SubsystemsVersions
		|WHERE
		|	SubsystemsVersions.IsMainConfiguration = TRUE
		|	AND SubsystemsVersions.SubsystemName = &BaseConfigurationName";
	Query.SetParameter("BaseConfigurationName", Metadata.Name);
	BatchExecutionResult = Query.ExecuteBatch();
	If BatchExecutionResult[0].IsEmpty() And Not BatchExecutionResult[1].IsEmpty() Then
		Return "VersionUpdate"; // 
	EndIf;
	
	// 
	Return ?(BatchExecutionResult[2].IsEmpty(), "MigrationFromAnotherApplication", "VersionUpdate");
	
EndFunction	

// APK:581-off is used for testing.
Function CanExecuteSeamlessUpdate(UpdateIterationsToCheck = Undefined) Export
	
	If UpdateIterationsToCheck = Undefined Then
		// 
		// 
		UpdateIterations = UpdateIterations();
	Else
		UpdateIterations = UpdateIterationsToCheck;
	EndIf;
	
	HandlerSeparationFilters = New Array;
	If Not Common.SeparatedDataUsageAvailable() Then
		HandlerSeparationFilters.Add(False);
	EndIf;
	HandlerSeparationFilters.Add(True);
	
	// 
	MandatorySeparatedHandlers = InfobaseUpdate.NewUpdateHandlerTable();
	
	WriteToLog1 = Constants.WriteIBUpdateDetailsToEventLog.Get();
	HandlerProcedures = New Array;
	
	// 
	For Each UpdateIteration In UpdateIterations Do
		
		FilterParameters = HandlerFIlteringParameters();
		FilterParameters.UpdateMode = "Seamless";
		
		For Each SeparationFlag In HandlerSeparationFilters Do
		
			FilterParameters.GetSeparated = SeparationFlag;
			
			HandlersTree = UpdateInIntervalHandlers(UpdateIteration.Handlers, UpdateIteration.PreviousVersion,
				UpdateIteration.Version, FilterParameters);
			If HandlersTree.Rows.Count() = 0 Then
				Continue;
			EndIf;
				
			If HandlersTree.Rows.Count() > 1 
				Or HandlersTree.Rows[0].Version <> "*" Then
				For Each VersionRow In HandlersTree.Rows Do
					If VersionRow.Version = "*" Then
						Continue;
					EndIf;
					For Each Handler In VersionRow.Rows Do
						HandlerProcedures.Add(Handler.Procedure);
					EndDo;
				EndDo;
			EndIf;
			
			If SeparationFlag 
				And Common.DataSeparationEnabled() 
				And Not Common.SeparatedDataUsageAvailable() Then
				
				// 
				// 
				Continue;
			EndIf;
			
			FoundHandlers = HandlersTree.Rows[0].Rows.FindRows(New Structure("ExclusiveMode", Undefined));
			For Each Handler In FoundHandlers Do
				HandlerProcedures.Add(Handler.Procedure);
			EndDo;
			
			// 
			For Each Handler In HandlersTree.Rows[0].Rows Do
				If Handler.RegistrationVersion <> "*" Then
					HandlerProcedures.Add(Handler.Procedure);
					Continue;
				EndIf;
				
				HandlerParameters = New Structure;
				If Handler.HandlerManagement Then
					HandlerParameters.Insert("SeparatedHandlers", MandatorySeparatedHandlers);
				EndIf;
				HandlerParameters.Insert("ExclusiveMode", False);
				
				AdditionalParameters = New Structure;
				AdditionalParameters.Insert("WriteToLog1", WriteToLog1);
				AdditionalParameters.Insert("LibraryID", UpdateIteration.Subsystem);
				AdditionalParameters.Insert("HandlerExecutionProgress", Undefined);
				AdditionalParameters.Insert("InBackground", False);
				
				ExecuteUpdateHandler(Handler, HandlerParameters, AdditionalParameters);
				
				If HandlerParameters.ExclusiveMode = True Then
					HandlerProcedures.Add(Handler.Procedure);
				EndIf;
			EndDo;
			
		EndDo;
	EndDo;
	
	If UpdateIterationsToCheck = Undefined Then
		UpdateIterationsToCheck = HandlerProcedures;
		Return HandlerProcedures.Count() = 0;
	EndIf;
	
	If HandlerProcedures.Count() <> 0 Then
		MessageText = NStr("en = 'The following handlers support update in exclusive mode only:';");
		MessageText = MessageText + Chars.LF;
		For Each HandlerProcedure1 In HandlerProcedures Do
			MessageText = MessageText + Chars.LF + HandlerProcedure1;
		EndDo;
		WriteError(MessageText);
	EndIf;
	
	Return HandlerProcedures.Count() = 0;
	
EndFunction
// 

Procedure CopyRowsToTree(Val DestinationRows, Val SourceRows, Val ColumnStructure1)
	
	For Each SourceRow1 In SourceRows Do
		FillPropertyValues(ColumnStructure1, SourceRow1);
		FoundRows = DestinationRows.FindRows(ColumnStructure1);
		If FoundRows.Count() = 0 Then
			DestinationRow1 = DestinationRows.Add();
			FillPropertyValues(DestinationRow1, SourceRow1);
		Else
			DestinationRow1 = FoundRows[0];
		EndIf;
		
		CopyRowsToTree(DestinationRow1.Rows, SourceRow1.Rows, ColumnStructure1);
	EndDo;
	
EndProcedure

Function GetUpdatePlan(Val LibraryID, Val VersionFrom1, Val VersionTo1)
	
	RecordManager = InformationRegisters.SubsystemsVersions.CreateRecordManager();
	RecordManager.SubsystemName = LibraryID;
	RecordManager.Read();
	If Not RecordManager.Selected() Then
		Return Undefined;
	EndIf;
	
	PlanDetails = RecordManager.UpdatePlan.Get();
	If PlanDetails = Undefined Then
		
		Return Undefined;
		
	Else
		
		If PlanDetails.VersionFrom1 <> VersionFrom1
			Or PlanDetails.VersionTo1 <> VersionTo1 Then
			
			// 
			Return Undefined;
		EndIf;
		
		Return PlanDetails.Plan;
		
	EndIf;
	
EndFunction

Procedure ExecuteUpdateHandler(Handler, Parameters, AdditionalParameters)
	
	WriteUpdateProgressInformation(Handler, AdditionalParameters.HandlerExecutionProgress, AdditionalParameters.InBackground);
	HandlerDetails = 
		PrepareUpdateProgressDetails(Handler, Parameters, AdditionalParameters.LibraryID);
	
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		MeasurementStart = ModulePerformanceMonitor.StartTimeMeasurement();
	EndIf;
	
	If Parameters <> Undefined Then
		HandlerParameters = New Array;
		HandlerParameters.Add(Parameters);
	Else
		HandlerParameters = Undefined;
	EndIf;
	
	TransactionActiveAtExecutionStartTime = TransactionActive();
	
	SubsystemExists = Common.SubsystemExists("StandardSubsystems.AccessManagement");
	DisableAccessKeysUpdate(True, SubsystemExists);
	Try
		SetUpdateHandlerParameters(Handler);
		SetHandlerStatus(Handler.Procedure, "Running");
		
		ProcessingStart = CurrentUniversalDateInMilliseconds();
		Common.ExecuteConfigurationMethod(Handler.Procedure, HandlerParameters);
		ProcessingEnd = CurrentUniversalDateInMilliseconds();
		
		SetUpdateHandlerParameters(Undefined);
		
		ValidateNestedTransaction(TransactionActiveAtExecutionStartTime, Handler.Procedure);
		
		PropertiesToSet = New Structure;
		PropertiesToSet.Insert("Status", Enums.UpdateHandlersStatuses.Completed);
		PropertiesToSet.Insert("ProcessingDuration", ProcessingEnd - ProcessingStart);
		SetHandlerProperties(Handler.Procedure, PropertiesToSet);
		
		DisableAccessKeysUpdate(False, SubsystemExists);
	Except
		ValidateNestedTransaction(TransactionActiveAtExecutionStartTime, Handler.Procedure);
		
		DisableAccessKeysUpdate(False, SubsystemExists);
		If AdditionalParameters.WriteToLog1 Then
			WriteUpdateProgressDetails(HandlerDetails);
		EndIf;
		
		HandlerName = Handler.Procedure + "(" + ?(HandlerParameters = Undefined, "", "Parameters") + ")";
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'An error occurred while calling update handler
					   |%1:
					   |%2.
					   |';"),
			HandlerName,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteError(ErrorText);
		SetHandlerStatus(Handler.Procedure, "Error", ErrorText);
		Raise;
	EndTry;
	
	If AdditionalParameters.WriteToLog1 Then
		WriteUpdateProgressDetails(HandlerDetails);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		ModulePerformanceMonitor.EndTechnologicalTimeMeasurement("UpdateHandlerRunTime." + HandlerDetails.Procedure, MeasurementStart);
	EndIf;
	
EndProcedure

Procedure ExecuteHandlersAfterInfobaseUpdate(Val UpdateIterations, Val WriteToLog1, OutputUpdatesDetails, Val SeamlessUpdate)
	
	For Each UpdateIteration In UpdateIterations Do
		
		If WriteToLog1 Then
			Handler = New Structure();
			Handler.Insert("Version", "*");
			Handler.Insert("RegistrationVersion", "*");
			Handler.Insert("ExecutionMode", "Seamless");
			Handler.Insert("Procedure", UpdateIteration.MainServerModuleName + ".AfterUpdateInfobase");
			HandlerDetails =  PrepareUpdateProgressDetails(Handler, Undefined, UpdateIteration.Subsystem);
		EndIf;
		
		Try
			
			UpdateIteration.MainServerModule.AfterUpdateInfobase(
				UpdateIteration.PreviousVersion,
				UpdateIteration.Version,
				UpdateIteration.CompletedHandlers,
				OutputUpdatesDetails,
				Not SeamlessUpdate);
				
		Except
			
			If WriteToLog1 Then
				WriteUpdateProgressDetails(HandlerDetails);
			EndIf;
			
			Raise;
			
		EndTry;
		
		If WriteToLog1 Then
			WriteUpdateProgressDetails(HandlerDetails);
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  Handler - Undefined
//             - ValueTreeRow
//             - Structure:
//    * ExecutionMode - String
//    * RegistrationVersion - String
//    * Version - String
//  Parameters - Undefined  
//            - Structure:
//    * Queue - Arbitrary
//    * ExecutionProgress - Structure:
//        ** ProcessedObjectsCount1 - Number
//        ** TotalObjectCount - Number
//    * ProcessingCompleted - Boolean
//  LibraryID - Arbitrary
//  HandlerDeferred - Boolean
// Returns:
//  Structure:
//   * ValueAtStart - Number
//   * DataAreaUsage - Boolean
//   * DataAreaValue - Number
//   * ExecutionMode - String
//   * Parameters - Undefined
// 
Function PrepareUpdateProgressDetails(Handler, Parameters, LibraryID, HandlerDeferred = False)
	
	HandlerDetails = New Structure;
	HandlerDetails.Insert("Library", LibraryID);
	If HandlerDeferred Then
		HandlerDetails.Insert("Version", Handler.Version);
		HandlerDetails.Insert("Procedure", Handler.HandlerName);
	Else
		HandlerDetails.Insert("Version", Handler.Version);
		HandlerDetails.Insert("Procedure", Handler.Procedure);
	EndIf;
	HandlerDetails.Insert("RegistrationVersion", Handler.RegistrationVersion);
	HandlerDetails.Insert("Parameters", Parameters);
	
	If HandlerDeferred Then
		HandlerDetails.Insert("ExecutionMode", "Deferred");
	ElsIf ValueIsFilled(Handler.ExecutionMode) Then
		HandlerDetails.Insert("ExecutionMode", Handler.ExecutionMode);
	Else
		HandlerDetails.Insert("ExecutionMode", "Exclusively");
	EndIf;
	
	If Common.DataSeparationEnabled()
	   And Common.SeparatedDataUsageAvailable() Then
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		
		HandlerDetails.Insert("DataAreaValue",
			ModuleSaaSOperations.SessionSeparatorValue());
		HandlerDetails.Insert("DataAreaUsage", True);
		
	Else
		
		HandlerDetails.Insert("DataAreaValue", -1);
		HandlerDetails.Insert("DataAreaUsage", False);
		
	EndIf;
	
	HandlerDetails.Insert("ValueAtStart", CurrentUniversalDateInMilliseconds());
	
	Return HandlerDetails;
	
EndFunction

Procedure WriteUpdateProgressDetails(HandlerDetails)
	
	Duration = CurrentUniversalDateInMilliseconds() - HandlerDetails.ValueAtStart;
	
	HandlerDetails.Insert("Completed", False);
	HandlerDetails.Insert("Duration", Duration / 1000); // 
	
	ACopyOfTheDescription = Common.CopyRecursive(HandlerDetails);
	If ACopyOfTheDescription.Property("Parameters") Then
		ACopyOfTheDescription.Delete("Parameters");
	EndIf;
	
	WriteLogEvent(
		EventLogEventProtocol(),
		EventLogLevel.Information,
		,
		,
		Common.ValueToXMLString(ACopyOfTheDescription));
		
EndProcedure

Procedure CheckNestedTransactionWhenExecutingDeferredHandler(HandlerContext, Result)
	
	Try
		ValidateNestedTransaction(HandlerContext.TransactionActiveAtExecutionStartTime,
			HandlerContext.HandlerName);
	Except
		Result.ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		Result.HasOpenTransactions = True;
		
		While TransactionActive() Do
			RollbackTransaction(); // 
		EndDo;
	EndTry;
	
EndProcedure

Procedure ValidateNestedTransaction(TransactionActiveAtExecutionStartTime, HandlerName1)
	
	EventName = EventLogEvent() + "." + NStr("en = 'Execute handlers';", Common.DefaultLanguageCode());
	If TransactionActiveAtExecutionStartTime Then
		
		If TransactionActive() Then
			// 
			Try
				Constants.UseSeparationByDataAreas.Get();
			Except
				CommentTemplate = NStr("en = 'Error while executing update handler %1:
				|The update handler intercepted an exception while an external transaction was active.
				|If active transactions are open at higher stack levels, the exceptions also must be passed to higher stack levels.';");
				Comment = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, HandlerName1);
				
				WriteLogEvent(EventName, EventLogLevel.Error,,, Comment);
				Raise(Comment, ErrorCategory.ConfigurationError);
			EndTry;
		Else
			CommentTemplate = NStr("en = 'Error while executing update handler %1:
			|The update handler closed an excessive transaction that was opened earlier (at a higher stack level).';");
			Comment = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, HandlerName1);
			
			WriteLogEvent(EventName, EventLogLevel.Error,,, Comment);
			Raise(Comment, ErrorCategory.ConfigurationError);
		EndIf;
	Else
		If TransactionActive() Then
			CommentTemplate = NStr("en = 'Error while executing update handler %1:
			|A transaction that was opened in the update handler is still active (as it was not committed or rolled back).';");
			Comment = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, HandlerName1);
			
			WriteLogEvent(EventName, EventLogLevel.Error,,, Comment);
			Raise(Comment, ErrorCategory.ConfigurationError);
		EndIf;
	EndIf;
	
EndProcedure

Procedure ValidateHandlerProperties(UpdateIteration)
	
	For Each Handler In UpdateIteration.Handlers Do
		ErrorDescription = "";
		
		// 
		If Handler.ExecutionMode = "Exclusive" Then
			Handler.ExecutionMode = "Exclusively";
		EndIf;
		
		If IsBlankString(Handler.Version) Then
			
			If Handler.InitialFilling <> True Then
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'One of the following handler properties is blank: %1 or %2.';"),
					"Version", "InitialFilling");
			EndIf;
			
		ElsIf Handler.Version <> "*"
			And Not StrStartsWith(Handler.Version, "DebuggingTheHandler") Then
			
			Try
				ZeroVersion = CommonClientServer.CompareVersions(Handler.Version, "0.0.0.0") = 0;
			Except
				ZeroVersion = False;
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'In the handler, property %1 has invalid value: ""%2"".
					           |Valid format: ""2.1.3.70"".';"),
					"Version", Handler.Version);
			EndTry;
			
			If ZeroVersion Then
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'In the handler, property %1 has invalid value: ""%2"".
					           |Zero versions are not allowed.';"),
					"Version", Handler.Version);
			EndIf;
			
			If Not ValueIsFilled(ErrorDescription)
			   And Handler.ExecuteInMandatoryGroup <> True
			   And Handler.Priority <> 0 Then
				
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'One of the following handler properties has invalid value: %1 or
				               |%2.';"),
					"Priority", "ExecuteInMandatoryGroup");
			EndIf;
		EndIf;
		
		If Handler.ExecutionMode <> ""
			And Handler.ExecutionMode <> "Exclusively"
			And Handler.ExecutionMode <> "Seamless"
			And Handler.ExecutionMode <> "Deferred" Then
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'In handler ""%1"", property %2 has invalid value.
				           |Valid value: ""%3"", ""%4"", or ""%5"".';"),
				Handler.Procedure, "ExecutionMode", "Exclusively", "Deferred", "Seamless");
		EndIf;
		
		If Not ValueIsFilled(ErrorDescription)
		   And Handler.Optional = True
		   And Handler.InitialFilling = True Then
			
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'One of the following handler properties has invalid value: %1 or
			               |%2.';"),
				"Optional", "InitialFilling");
		EndIf;
			
		If Not ValueIsFilled(ErrorDescription) Then
			Continue;
		EndIf;
		
		If UpdateIteration.IsMainConfiguration Then
			ErrorTitle = NStr("en = 'Configuration update handler property error';");
		Else
			ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Error in a property of library %1 (version %2) update handler';"),
				UpdateIteration.Subsystem,
				UpdateIteration.Version);
		EndIf;
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTitle + Chars.LF
			+ NStr("en = '(%1).';") + Chars.LF
			+ Chars.LF
			+ ErrorDescription,
			Handler.Procedure);
		
		WriteError(ErrorDescription);
		Raise(ErrorDescription, ErrorCategory.ConfigurationError);

	EndDo;
	
EndProcedure

Function HandlerCountForCurrentVersion(UpdateIterations, DeferredUpdateMode)
	
	Query = New Query;
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.SetParameter("DeferredHandlerExecutionMode", Enums.DeferredHandlersExecutionModes.Parallel);
	
	Query.Text =
		"SELECT
		|	UpdateHandlers.HandlerName AS HandlerName
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode <> &ExecutionMode";
	NumberOfSeparatedHandlers = Query.Execute().Unload().Count();
	
	Query.Text =
		"SELECT
		|	SharedDataUpdateHandlers.HandlerName AS HandlerName
		|FROM
		|	InformationRegister.SharedDataUpdateHandlers AS SharedDataUpdateHandlers";
	NumberOfUndividedHandlers = Query.Execute().Unload().Count();
	
	Query.Text =
		"SELECT
		|	UpdateHandlers.HandlerName AS HandlerName
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode";
	NumberOfDeferredHandlers = Query.Execute().Unload().Count();
	
	Query.Text =
		"SELECT
		|	UpdateHandlers.HandlerName AS HandlerName
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.DeferredHandlerExecutionMode = &DeferredHandlerExecutionMode";
	NumberOfRegistrationProcedures = Query.Execute().Unload().Count();
	
	HandlerCount = NumberOfSeparatedHandlers + NumberOfUndividedHandlers + NumberOfRegistrationProcedures;
	If DeferredUpdateMode = "Exclusively" Then
		HandlerCount = HandlerCount + NumberOfDeferredHandlers;
	EndIf;
	
	Return New Structure("TotalHandlerCount, CompletedHandlersCount", HandlerCount, 0);
	
EndFunction

Function MetadataObjectNameByManagerName(ManagerName)
	
	Position = StrFind(ManagerName, ".");
	If Position = 0 Then
		Return "CommonModule." + ManagerName;
	EndIf;
	ManagerType = Left(ManagerName, Position - 1);
	
	TypesNames = New Map;
	TypesNames.Insert("Catalogs", "Catalog");
	TypesNames.Insert("Documents", "Document");
	TypesNames.Insert("DataProcessors", "DataProcessor");
	TypesNames.Insert("ChartsOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	TypesNames.Insert("AccountingRegisters", "AccountingRegister");
	TypesNames.Insert("AccumulationRegisters", "AccumulationRegister");
	TypesNames.Insert("CalculationRegisters", "CalculationRegister");
	TypesNames.Insert("InformationRegisters", "InformationRegister");
	TypesNames.Insert("BusinessProcesses", "BusinessProcess");
	TypesNames.Insert("DocumentJournals", "DocumentJournal");
	TypesNames.Insert("Tasks", "Task");
	TypesNames.Insert("Reports", "Report");
	TypesNames.Insert("Constants", "Constant");
	TypesNames.Insert("Enums", "Enum");
	TypesNames.Insert("ChartsOfCalculationTypes", "ChartOfCalculationTypes");
	TypesNames.Insert("ExchangePlans", "ExchangePlan");
	TypesNames.Insert("ChartsOfAccounts", "ChartOfAccounts");
	
	TypeName = TypesNames[ManagerType];
	If TypeName = Undefined Then
		Return ManagerName;
	EndIf;
	
	Return TypeName + Mid(ManagerName, Position);
EndFunction

Procedure SelectNewSubsystemHandlers(AllHandlers)
	
	// 
	NewSubsystemObjects = New Array;
	For Each SubsystemName In InfobaseUpdateInfo().NewSubsystems Do
		Subsystem = Common.MetadataObjectByFullName(SubsystemName);
		If Subsystem = Undefined Then
			Continue;
		EndIf;
		For Each MetadataObject In Subsystem.Content Do
			NewSubsystemObjects.Add(MetadataObject.FullName());
		EndDo;
	EndDo;
	
	// 
	AllHandlers.Columns.Add("IsNewSubsystem", New TypeDescription("Boolean"));
	For Each HandlerDetails In AllHandlers Do
		Position = StrFind(HandlerDetails.Procedure, ".", SearchDirection.FromEnd);
		ManagerName = Left(HandlerDetails.Procedure, Position - 1);
		If NewSubsystemObjects.Find(MetadataObjectNameByManagerName(ManagerName)) <> Undefined Then
			HandlerDetails.IsNewSubsystem = True;
		EndIf;
	EndDo;
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToSlave.
Procedure OnSendSubsystemVersions(DataElement, ItemSend, Val InitialImageCreating = False)
	
	StandardProcessing = True;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		ModuleInfobaseUpdateInternalSaaS.OnSendSubsystemVersions(DataElement, ItemSend, 
			InitialImageCreating, StandardProcessing);
	EndIf;
	
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	If ItemSend = DataItemSend.Delete
		Or ItemSend = DataItemSend.Ignore Then
		
		// 
		
	ElsIf TypeOf(DataElement) = Type("InformationRegisterRecordSet.SubsystemsVersions") Then
		
		If Not InitialImageCreating Then
			
			// 
			ItemSend = DataItemSend.Ignore;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function UpdateStartMark()
	
	SessionDetails = New Structure;
	SessionDetails.Insert("ComputerName");
	SessionDetails.Insert("ApplicationName");
	SessionDetails.Insert("SessionStarted");
	SessionDetails.Insert("SessionNumber");
	SessionDetails.Insert("ConnectionNumber");
	SessionDetails.Insert("User");
	FillPropertyValues(SessionDetails, GetCurrentInfoBaseSession());
	User  = SessionDetails.User; // InfoBaseUser
	SessionDetails.User = User.Name;
	ParameterName = "StandardSubsystems.IBVersionUpdate.InfobaseUpdateSession";
	
	CanUpdate = True;
	
	Block = New DataLock;
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		LockItem = Block.Add("Constant.IBUpdateInfo");
	Else
		LockItem = Block.Add("InformationRegister.ApplicationRuntimeParameters");
		LockItem.SetValue("ParameterName", ParameterName);
	EndIf;
	
	BeginTransaction();
	Try
		Block.Lock();
		SavedParameters1 = UpdateSessionInfo(ParameterName);
		
		If SavedParameters1 = Undefined Then
			SessionsMatch = False;
		Else
			SessionsMatch = DataMatch(SessionDetails, SavedParameters1);
		EndIf;
		
		If Not SessionsMatch Then
			UpdateSessionActive = SessionActive(SavedParameters1);
			If UpdateSessionActive Then
				UpdateSession = SavedParameters1;
				CanUpdate = False;
			Else
				WriteUpdateSessionInfo(ParameterName, SessionDetails);
				UpdateSession = SessionDetails;
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Result = New Structure;
	Result.Insert("CanUpdate", CanUpdate);
	Result.Insert("UpdateSession", UpdateSession);
	
	Return Result;
	
EndFunction

Function UpdateSessionInfo(ParameterName)
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		InformationRecords = InfobaseUpdateInfo();
		UpdateSession = InformationRecords.UpdateSession;
	Else
		UpdateSession = StandardSubsystemsServer.ApplicationParameter(ParameterName);
	EndIf;
	
	Return UpdateSession;
EndFunction

Procedure WriteUpdateSessionInfo(ParameterName, SessionDetails)
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		InformationRecords = InfobaseUpdateInfo();
		InformationRecords.UpdateSession = SessionDetails;
		WriteInfobaseUpdateInfo(InformationRecords);
	Else
		StandardSubsystemsServer.SetApplicationParameter(ParameterName, SessionDetails);
	EndIf;
EndProcedure

Function SessionActive(SessionDetails)
	If SessionDetails = Undefined Then
		Return False;
	EndIf;
	
	InfobaseSessions = GetInfoBaseSessions();
	
	For Each Session In InfobaseSessions Do
		Match = DataMatch(SessionDetails, Session);
		If Match Then
			Break;
		EndIf;
	EndDo;
	
	Return Match;
EndFunction

Function DataMatch(Data1, Data2)
	
	Match = True;
	For Each KeyAndValue In Data1 Do
		If KeyAndValue.Key = "User"
		 Or KeyAndValue.Key = "ConnectionNumber" Then
			Continue;
		EndIf;
		
		If Data2[KeyAndValue.Key] <> KeyAndValue.Value Then
			Match = False;
			Break;
		EndIf;
	EndDo;
	
	Return Match;
	
EndFunction

Function NewTableOfInformationAboutHandlers() Export

	InfoHandlers = New ValueTable;
	InfoHandlers.Columns.Add("HandlerName", New TypeDescription("String"));
	InfoHandlers.Columns.Add("ExecutionMode", New TypeDescription("String"));
	InfoHandlers.Columns.Add("LibraryName", New TypeDescription("String"));
	InfoHandlers.Columns.Add("Version", New TypeDescription("String"));
	InfoHandlers.Columns.Add("Status", New TypeDescription("String"));
	InfoHandlers.Columns.Add("ProcessingDuration", New TypeDescription("Number"));
	InfoHandlers.Columns.Add("ErrorInfo", New TypeDescription("String"));
	InfoHandlers.Columns.Add("DataArea", New TypeDescription("Number"));

	Return InfoHandlers;

EndFunction

Function NewProgressInUpdatingDataAreas() Export

	Progress = New Structure;
	Progress.Insert("Updated3", 0);
	Progress.Insert("Running", 0);
	Progress.Insert("Waiting1", 0);
	Progress.Insert("Issues", 0);

	Progress.Insert("AreasUpdated", New Array);
	Progress.Insert("AreasRunning", New Array);
	Progress.Insert("AreasWaitingFor", New Array);
	Progress.Insert("AreasWithIssues", New Array);

	Return Progress;

EndFunction

Function NamesByEnumerationValues(EnumerationMetadata) Export

	EnumManager = Enums[EnumerationMetadata.Name];
	Result = New Map;
	For Each CollectionItem In EnumerationMetadata.EnumValues Do // MetadataObject
		Result.Insert(EnumManager[CollectionItem.Name], CollectionItem.Name);
	EndDo;

	Return Result;

EndFunction

Function TheValueOfTheEnumerationByName(EnumValueName, EnumerationMetadata) Export

	EnumManager = Enums[EnumerationMetadata.Name];
	If Not ValueIsFilled(EnumValueName) Then
		Return EnumManager.EmptyRef();
	EndIf;

	Result = Undefined;
	AvailableValues = New Array;
	
	NameOfTheValueToCompare = Upper(EnumValueName);
	For Each CollectionItem In EnumerationMetadata.EnumValues Do // MetadataObject
		If Upper(CollectionItem.Name) = NameOfTheValueToCompare Then
			Result = EnumManager[CollectionItem.Name];
			Break;
		EndIf;
		AvailableValues.Add("""" + CollectionItem.Name + """");
	EndDo;

	If Result = Undefined Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid name ""%1"" of the ""%2"" enumeration value.
				 |Available values: %3';"), 
			EnumValueName, EnumerationMetadata, StrConcat(AvailableValues, ", "));
		Raise(MessageText, ErrorCategory.ConfigurationError); 
	EndIf;

	Return Result;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Procedure WriteInformation(Val Text) Export
	
	EventLog.AddMessageForEventLog(EventLogEvent(), EventLogLevel.Information,,, Text);
	
EndProcedure

Procedure WriteError(Val Text) Export
	
	EventLog.AddMessageForEventLog(EventLogEvent(), EventLogLevel.Error,,, Text);
	
EndProcedure

Procedure WriteWarning(Val Text) Export
	
	EventLog.AddMessageForEventLog(EventLogEvent(), EventLogLevel.Warning,,, Text);
	
EndProcedure

Procedure WriteUpdateProgressInformation(Handler, HandlerExecutionProgress, InBackground)
	
	If HandlerExecutionProgress = Undefined Then
		Return;
	EndIf;
	
	HandlerExecutionProgress.CompletedHandlersCount = HandlerExecutionProgress.CompletedHandlersCount + 1;
	
	If Not Common.DataSeparationEnabled() Then
		Message = NStr("en = 'Executing update handler %1 (%2 out of %3).';");
		Message = StringFunctionsClientServer.SubstituteParametersToString(
			Message, Handler.Procedure,
			HandlerExecutionProgress.CompletedHandlersCount, HandlerExecutionProgress.TotalHandlerCount);
		WriteInformation(Message);
	EndIf;
	
	If InBackground Then
		Progress = 10 + HandlerExecutionProgress.CompletedHandlersCount / HandlerExecutionProgress.TotalHandlerCount * 90;
		TimeConsumingOperations.ReportProgress(Progress);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Display descriptions of changes in the specified version.
//
// Parameters:
//  VersionNumber  - String -  the version number for which the description is output from the layout
//                          of the table document mockupdescription of Updates to the table document.
//                          
//
Procedure OutputUpdateDetails(Val VersionNumber, DocumentUpdatesDetails, UpdateDetailsTemplate)
	
	Number = StrReplace(VersionNumber, ".", "_");
	
	If UpdateDetailsTemplate.Areas.Find("Header" + Number) = Undefined Then
		Return;
	EndIf;
	
	DocumentUpdatesDetails.Put(UpdateDetailsTemplate.GetArea("Header" + Number));
	DocumentUpdatesDetails.StartRowGroup("Version" + Number);
	DocumentUpdatesDetails.Put(UpdateDetailsTemplate.GetArea("Version" + Number));
	DocumentUpdatesDetails.EndRowGroup();
	DocumentUpdatesDetails.Put(UpdateDetailsTemplate.GetArea("Indent"));
	
EndProcedure

Function SystemChangesDisplayLastVersion(Val UserName = Undefined) Export
	
	If UserName = Undefined Then
		UserName = UserName();
	EndIf;
	
	LatestVersion1 = Common.CommonSettingsStorageLoad("IBUpdate",
		"SystemChangesDisplayLastVersion", , , UserName);
	
	Return LatestVersion1;
	
EndFunction

Procedure DefineUpdateDetailsDisplay(OutputUpdatesDetails)
	
	If OutputUpdatesDetails And Not Common.DataSeparationEnabled() Then
		Common.CommonSettingsStorageSave("IBUpdate", "OutputUpdateDetailsForAdministrator", True, , UserName());
	EndIf;
	
	If Common.SeparatedDataUsageAvailable() Then
		IBUpdateInfo = InfobaseUpdateInfo();
		IBUpdateInfo.OutputUpdatesDetails = OutputUpdatesDetails;
		
		WriteInfobaseUpdateInfo(IBUpdateInfo);
	EndIf;
	
EndProcedure

// Returns a list of sections describing system changes.
//
// Returns:
//  ValueList:
//    * Value - Number -  version weight.
//    * Presentation - String -  versions.
//
Function UpdateDetailsSections() Export
	
	Sections = New ValueList;
	MetadataVersionWeight = VersionWeight(Metadata.Version);
	
	UpdateDetailsTemplate = Metadata.CommonTemplates.Find("SystemReleaseNotes");
	If UpdateDetailsTemplate <> Undefined Then
		VersionPredicate = "Version";
		HeaderPredicate = "Header";
		Template = GetCommonTemplate(UpdateDetailsTemplate);
		
		For Each Area In Template.Areas Do
			If StrFind(Area.Name, VersionPredicate) = 0 Then
				Continue;
			EndIf;
			
			VersionInDescriptionFormat = Mid(Area.Name, StrLen(VersionPredicate) + 1);
			
			If Template.Areas.Find(HeaderPredicate + VersionInDescriptionFormat) = Undefined Then
				Continue;
			EndIf;
			
			VersionDigitsAsStrings = StrSplit(VersionInDescriptionFormat, "_");
			If VersionDigitsAsStrings.Count() <> 4 Then
				Continue;
			EndIf;
			
			VersionWeight = VersionWeightFromStringArray(VersionDigitsAsStrings);
			
			Version = ""
				+ Number(VersionDigitsAsStrings[0]) + "."
				+ Number(VersionDigitsAsStrings[1]) + "."
				+ Number(VersionDigitsAsStrings[2]) + "."
				+ Number(VersionDigitsAsStrings[3]);
			
			If VersionWeight > MetadataVersionWeight Then
				ExceptionText = NStr("en = 'The version specified in a section of common template %1
					|is greater than the version specified in the metadata (%2 instead of correct version %3)';");
				ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionText,
					"SystemReleaseNotes", Version, Metadata.Version);
				Raise(ExceptionText, ErrorCategory.ConfigurationError);
			EndIf;
			
			Sections.Add(VersionWeight, Version);
		EndDo;
		
		Sections.SortByValue(SortDirection.Desc);
	EndIf;
	
	
	Return Sections;
	
EndFunction

Function VersionWeightFromStringArray(VersionDigitsAsStrings)
	
	Return 0
		+ Number(VersionDigitsAsStrings[0]) * 1000000000
		+ Number(VersionDigitsAsStrings[1]) * 1000000
		+ Number(VersionDigitsAsStrings[2]) * 1000
		+ Number(VersionDigitsAsStrings[3]);
	
EndFunction

Function GetLaterVersions(Sections, Version)
	
	Result = New Array;
	
	If Sections = Undefined Then
		Sections = UpdateDetailsSections();
	EndIf;
	
	VersionWeight = VersionWeight(Version);
	For Each ListItem In Sections Do
		If ListItem.Value <= VersionWeight Then
			Continue;
		EndIf;
		
		Result.Add(ListItem.Presentation);
	EndDo;
	
	Return Result;
	
EndFunction

Procedure CancelDeferredUpdate()
	
	OnEnableDeferredUpdate(False);
	
EndProcedure

Function AllDeferredHandlersCompleted(UpdateInfo)
	
	Query = New Query;
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.SetParameter("Status", Enums.UpdateHandlersStatuses.Completed);
	Query.Text =
		"SELECT
		|	UpdateHandlers.HandlerName AS HandlerName,
		|	UpdateHandlers.Status AS Status
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode
		|	AND UpdateHandlers.Status <> &Status";
	UncompletedHandlers = Query.Execute().Unload();
	
	If UncompletedHandlers.Count() = 0 Then
		UpdateInfo.DeferredUpdatesEndTime = CurrentSessionDate();
		UpdateInfo.DeferredUpdateCompletedSuccessfully = True;
		UpdateInfo.DurationOfUpdateSteps.NonCriticalOnes.End = CurrentSessionDate();
		WriteInfobaseUpdateInfo(UpdateInfo);
		Constants.DeferredUpdateCompletedSuccessfully.Set(True);
		If Not Common.IsSubordinateDIBNode() Then
			Constants.DeferredMasterNodeUpdateCompleted.Set(True);
		EndIf;
		
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Procedure HandlerAccountingChecks(Validation, CheckParameters) Export
	
	// 
	// 
	Return;
	
EndProcedure

Function ShouldShowDataIssues() Export
	
	If Common.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		ModuleAccountingAudit = Common.CommonModule("AccountingAudit");
		Return ModuleAccountingAudit.SubsystemAvailable();
	Else
		Return False;
	EndIf;
	
EndFunction

Function NumberofProblemswithData() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.AccountingAudit")
		Or Not Common.SeparatedDataUsageAvailable() Then
		Return 0;
	EndIf;
	
	ModuleAccountingAudit = Common.CommonModule("AccountingAudit");
	Validation          = ModuleAccountingAudit.CheckByID("InfoBaseUpdateProblemWithData");
	IssuesCount = ModuleAccountingAudit.IssuesCountByCheckRule(Validation);
	
	Return IssuesCount;
	
EndFunction

Procedure ClearRegisteredProblemsWithData()
	
	If Not Common.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		Return;
	EndIf;
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ModuleAccountingAudit = Common.CommonModule("AccountingAudit");
	
	Validation = ModuleAccountingAudit.CheckByID("InfoBaseUpdateProblemWithData");
	ModuleAccountingAudit.ClearResultOnCheck(Validation);
	
EndProcedure

// For internal use only.
//
Function ExecuteDeferredUpdateHandler(ParametersOfUpdate = Undefined)
	
	HandlerContext = NewHandlerContext();
	HandlerUpdates = FindUpdateHandler(HandlerContext, ParametersOfUpdate);
	
	If HandlerUpdates = "AbortExecution" Then
		Return True;
	EndIf;
	
	If TypeOf(HandlerUpdates) = Type("ValueTableRow") Then
		ResultAddress = PutToTempStorage(Undefined);
		
		Try
			TheHandlerWasExecutedWithoutErrors = False;
			If HandlerUpdates.Multithreaded Then
				SupplementMultithreadHandlerContext(HandlerContext);
				DataToProcess = HandlerUpdates.DataToProcess.Get();
				DataToProcess.LastSelectedRecord = Undefined;
				DataToProcess.SearchCompleted = False;
				SelectionParameters = DataToProcess.SelectionParameters;
				CheckSelectionParameters(SelectionParameters);
				SelectionParameters.MaxSelection = InfobaseUpdate.MaxRecordsCountInSelection();
				SearchParameters = NewBatchSearchParameters();
				SearchParameters.SelectionParameters = SelectionParameters;
				SearchParameters.LastSelectedRecord = DataToProcess.LastSelectedRecord;
				IterationParameters = DataIterationParametersForUpdate(SearchParameters);
				Queue = HandlerContext.Parameters.Queue;
				Iterator = CurrentIterationParameters(IterationParameters);
				AdditionalDataSources = SelectionParameters.AdditionalDataSources;
				
				HandlerInitialParameters = HandlerContext.UpdateHandlerParameters;
				
				While Iterator <> Undefined Do
					TheHandlerWasExecutedWithoutErrors = False;
					RefObject1 = Iterator.RefObject1;
					TabularObject = Iterator.TabularObject;
					DataSet     = NewDataSetForUpdate();
					DataWriter    = DataSet.Add();
					SelectionParameters.AdditionalDataSources = InfobaseUpdate.DataSources(
						AdditionalDataSources,
						RefObject1,
						TabularObject);
					// 
					// 
					SelectionParameters.Insert("UpdateHandlerParameters", HandlerContext.UpdateHandlerParameters);
					
					DataWriter.Data = SelectBatchData(SelectionParameters, Queue, RefObject1, TabularObject);
					
					HandlerContext.UpdateHandlerParameters = SelectionParameters.UpdateHandlerParameters;
					
					DataWriter.RefObject1 = RefObject1;
					DataWriter.TabularObject = TabularObject;
					DataToUpdate = NewBatchForUpdate();
					DataToUpdate.DataSet = DataSet;
					
					If DataWriter.Data.Count() > 0 Then
						DataToUpdate.FirstRecord = FirstDataSetRowRecordKey(DataSet);
						DataToUpdate.LatestRecord = LastDataSetRowRecordKey(DataSet);
					EndIf;
					
					HandlerContext.Parameters.DataToUpdate = DataToUpdate;
					Count = DataWriter.Data.Count();
					If HandlerContext.ExecuteHandler Then
						ExecuteDeferredHandler(HandlerContext, ResultAddress);
					EndIf;
					TheHandlerWasExecutedWithoutErrors = True;
					CompleteDeferredHandlerExecution(HandlerContext, ResultAddress); // 
					
					// 
					HandlerUpdates = HandlerUpdates(HandlerContext.HandlerName); // 
					MaxAttempts = MaxUpdateAttempts(HandlerUpdates);
					If HandlerUpdates.AttemptCount >= MaxAttempts Then
						Break;
					EndIf;
					
					// 
					HandlerContext.UpdateHandlerParameters = HandlerInitialParameters;
					
					If Count > 0 Then
						DataToProcess.LastSelectedRecord = LastDataSetRowRecordKey(DataSet);
					Else
						DataToProcess.LastSelectedRecord = Undefined;
					EndIf;
					
					NextIterationParameters(IterationParameters, Count = SelectionParameters.MaxSelection);
					Iterator = CurrentIterationParameters(IterationParameters);
				EndDo;
				
				SelectionParameters.AdditionalDataSources = AdditionalDataSources;
			Else
				If HandlerContext.ExecuteHandler Then
					ExecuteDeferredHandler(HandlerContext, ResultAddress);
				EndIf;
				TheHandlerWasExecutedWithoutErrors = True;
				CompleteDeferredHandlerExecution(HandlerContext, ResultAddress);
			EndIf;
		Except
			ProcessHandlerException(HandlerContext, HandlerUpdates, ErrorInfo());
			// 
			If Not TheHandlerWasExecutedWithoutErrors Then
				HandlerContext.Insert("HandlingAHandlerException");
				CompleteDeferredHandlerExecution(HandlerContext, ResultAddress);
			EndIf;
		EndTry;
	ElsIf HandlerUpdates = False Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Finish executing the deferred handler in the main thread after the background task is finished.
//
// Parameters:
//  HandlerContext - See NewHandlerContext
//
Procedure EndDeferredUpdateHandlerExecution(HandlerContext)
	
	ParallelMode = HandlerContext.ParallelMode;
	CurrentUpdateIteration = HandlerContext.CurrentUpdateIteration;
	
	HandlerUpdates = HandlerUpdates(HandlerContext.HandlerName);
	PropertiesToSet = New Structure;
	
	If HandlerUpdates.Status = Enums.UpdateHandlersStatuses.Completed Then
		
		LockedObjectsInfo = LockedObjectsInfo();
		HandlerInfo = LockedObjectsInfo.Handlers[HandlerUpdates.HandlerName];
		If HandlerInfo <> Undefined Then
			HandlerInfo.Completed = True;
			WriteLockedObjectsInfo(LockedObjectsInfo);
		EndIf;
		PropertiesToSet.Insert("ErrorInfo", "");
		
	ElsIf HandlerUpdates.Status = Enums.UpdateHandlersStatuses.Running Then
		
		// 
		// 
		StartsWithPriority = Undefined;
		If HandlerUpdates.Priority = "HighPriority" Then
			ExecutionStatistics = HandlerUpdates.ExecutionStatistics.Get();
			StartsWithPriority = ExecutionStatistics["StartsWithPriority"];
			StartsWithPriority = ?(StartsWithPriority = Undefined, 1, ?(StartsWithPriority = 4, 0, StartsWithPriority + 1));
			ExecutionStatistics.Insert("StartsWithPriority", StartsWithPriority);
			PropertiesToSet.Insert("ExecutionStatistics", New ValueStorage(ExecutionStatistics));
		EndIf;
		
		If StartsWithPriority = Undefined Or StartsWithPriority = 0 Then
			PropertiesToSet.Insert("StartIteration", CurrentUpdateIteration);
		EndIf;
		
	Else
		PropertiesToSet.Insert("StartIteration", CurrentUpdateIteration);
	EndIf;
	
	SetHandlerProperties(HandlerUpdates.HandlerName, PropertiesToSet);
	
	// 
	// 
	If ParallelMode
		And HandlerUpdates.Status = Enums.UpdateHandlersStatuses.Error
		And HandlerUpdates.AttemptCount >= MaxUpdateAttempts(HandlerUpdates)
		And AreHandlersToRunMissing() Then
		UpdateInfo = InfobaseUpdateInfo();
		UpdateInfo.DeferredUpdatesEndTime = CurrentSessionDate();
		UpdateInfo.DeferredUpdateCompletedSuccessfully = False;
		WriteInfobaseUpdateInfo(UpdateInfo);
		Constants.DeferredUpdateCompletedSuccessfully.Set(False);
		If Not Common.IsSubordinateDIBNode() Then
			Constants.DeferredMasterNodeUpdateCompleted.Set(False);
		EndIf;
		
		ErrorTemplate = NStr("en = 'Cannot execute update handler %1. See the Event log for details.';");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
			HandlerContext.HandlerName);
		HandlerContext.Insert("ErrorWhenCompletingHandler", ErrorText);
	EndIf;
	
EndProcedure

Function AreHandlersToRunMissing()
	
	Statuses = New Array;
	Statuses.Add(Enums.UpdateHandlersStatuses.NotPerformed);
	Statuses.Add(Enums.UpdateHandlersStatuses.Running);
	
	// 
	Query = New Query;
	Query.SetParameter("Statuses", Statuses);
	Query.Text =
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.Status IN(&Statuses)";
	
	If Not Query.Execute().IsEmpty() Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.SetParameter("Status", Enums.UpdateHandlersStatuses.Error);
	Query.Text =
		"SELECT
		|	UpdateHandlers.HandlerName AS HandlerName,
		|	UpdateHandlers.Status AS Status,
		|	UpdateHandlers.AttemptCount AS AttemptCount,
		|	UpdateHandlers.Multithreaded,
		|	UpdateHandlers.DataToProcess
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode
		|	AND UpdateHandlers.Status = &Status";
	Handlers = Query.Execute().Unload();
	For Each Handler In Handlers Do
		If Handler.AttemptCount < MaxUpdateAttempts(Handler) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function PassedUpdateHandlerParameters(Parameters)
	PassedParameters = New Structure;
	For Each Parameter In Parameters Do
		If Parameter.Key <> "ProcessingCompleted"
			And Parameter.Key <> "ExecutionProgress"
			And Parameter.Key <> "Queue"
			And Parameter.Key <> "DataToUpdate" Then
			PassedParameters.Insert(Parameter.Key, Parameter.Value);
		EndIf;
	EndDo;
	
	Return PassedParameters;
EndFunction

Function NewUpdateInfo(PreviousInfo = Undefined)
	
	UpdateInfo = New Structure;
	UpdateInfo.Insert("UpdateStartTime");
	UpdateInfo.Insert("UpdateEndTime");
	UpdateInfo.Insert("UpdateDuration");
	UpdateInfo.Insert("DeferredUpdateStartTime");
	UpdateInfo.Insert("DeferredUpdatesEndTime");
	UpdateInfo.Insert("SessionNumber", New ValueList());
	UpdateInfo.Insert("DeferredUpdateCompletedSuccessfully");
	UpdateInfo.Insert("HandlersTree", New ValueTree());
	UpdateInfo.Insert("HandlerTreeVersion", "");
	UpdateInfo.Insert("OutputUpdatesDetails", False);
	UpdateInfo.Insert("LegitimateVersion", "");
	UpdateInfo.Insert("NewSubsystems", New Array);
	UpdateInfo.Insert("AllNewSubsystems", New Array);
	UpdateInfo.Insert("DeferredUpdateManagement", New Structure);
	UpdateInfo.Insert("CurrentUpdateIteration", 1);
	UpdateInfo.Insert("UpdateSession");
	UpdateInfo.Insert("VersionPatchesDeletion");
	UpdateInfo.Insert("VersionOfPatchCheck");
	UpdateInfo.Insert("HandlersGroupsDependence", New Map);
	UpdateInfo.Insert("SubsystemVersionsAtStartUpdates", New Map);
	UpdateInfo.Insert("UpdateSessionStartDate", Undefined);
	UpdateInfo.Insert("DurationOfUpdateSteps", New Structure);
	UpdateInfo.Insert("TablesToReadAndChange", New Map);
	
	UpdateInfo.DurationOfUpdateSteps.Insert("CriticalOnes", New Structure("Begin, End"));
	UpdateInfo.DurationOfUpdateSteps.Insert("Regular", New Structure("Begin, End"));
	UpdateInfo.DurationOfUpdateSteps.Insert("NonCriticalOnes", New Structure("Begin, End"));
	
	If TypeOf(PreviousInfo) = Type("Structure") Then
		FillPropertyValues(UpdateInfo, PreviousInfo);
	EndIf;
	
	Return UpdateInfo;
	
EndFunction

Function DeferredUpdateMode(ParametersOfUpdate)
	
	FileInfobase             = Common.FileInfobase();
	DataSeparationEnabled                     = Common.DataSeparationEnabled();
	SeparatedDataUsageAvailable = Common.SeparatedDataUsageAvailable();
	ExecuteDeferredHandlers1         = ParametersOfUpdate.ExecuteDeferredHandlers1;
	ClientLaunchParameter                 = StandardSubsystemsServer.ClientParametersAtServer().Get("LaunchParameter");
	
	If Not DataSeparationEnabled Or SeparatedDataUsageAvailable Then
		If FileInfobase
			Or StrFind(Lower(ClientLaunchParameter), Lower("ExecuteDeferredUpdateNow")) > 0
			Or ExecuteDeferredHandlers1 Then
			Return "Exclusively";
		Else
			Return "Deferred";
		EndIf;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Obtains information about updating the information base from the constant "Information Updates".
//
Function LockedObjectsInfo() Export
	
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled()
	   And Not Common.SeparatedDataUsageAvailable() Then
		
		Return NewLockedObjectsInfo();
	EndIf;
	
	LockedObjectsInfo = Constants.LockedObjectsInfo.Get().Get();
	If TypeOf(LockedObjectsInfo) <> Type("Structure") Then
		Return NewLockedObjectsInfo();
	EndIf;
	
	LockedObjectsInfo = NewLockedObjectsInfo(LockedObjectsInfo);
	Return LockedObjectsInfo;
	
EndFunction

// Preparing to launch the update handler in the main thread.
//
// Parameters:
//  HandlerContext - See NewHandlerContext
//  HandlerUpdates - ValueTreeRow -  update handler as a string in the handler tree.
//  ParametersOfUpdate - See UpdateInfobase
//  UpdateInfo - See InfobaseUpdateInfo
//
Procedure BeforeStartDataProcessingProcedure(HandlerContext,
                                                HandlerUpdates,
                                                ParametersOfUpdate,
                                                UpdateInfo)
	
	HandlerContext.WriteToLog1 = Constants.WriteIBUpdateDetailsToEventLog.Get();
	HandlerContext.TransactionActiveAtExecutionStartTime = TransactionActive();
	
	Try
		HandlerName = HandlerUpdates.HandlerName;
		SubsystemVersionsAtStartUpdates = UpdateInfo.SubsystemVersionsAtStartUpdates;
		SubsystemVersionAtStartUpdates = SubsystemVersionsAtStartUpdates[HandlerUpdates.LibraryName];
		
		HandlerContext.StartedWithoutErrors = True;
		HandlerExecutionMessage = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Executing update procedure %1.';"), HandlerName);
		EventLog.AddMessageForEventLog(EventLogEvent(),
				EventLogLevel.Information,,, HandlerExecutionMessage);
		
		// 
		ExecutionProgress = New Structure;
		ExecutionProgress.Insert("TotalObjectCount", 0);
		ExecutionProgress.Insert("ProcessedObjectsCount1", 0);
		ExecutionStatistics = HandlerUpdates.ExecutionStatistics.Get();
		If ExecutionStatistics["ExecutionProgress"] <> Undefined
			And TypeOf(ExecutionStatistics["ExecutionProgress"]) = Type("Structure") Then
			FillPropertyValues(ExecutionProgress, ExecutionStatistics["ExecutionProgress"]);
		EndIf;
		
		// 
		Parameters = ExecutionStatistics["HandlerParameters"];
		If Parameters = Undefined Then
			Parameters = New Structure;
		EndIf;
		
		HandlerContext.Parameters = Parameters;
		
		If ParametersOfUpdate.ParallelMode Then
			Parameters.Insert("ProcessingCompleted", Undefined);
		Else
			Parameters.Insert("ProcessingCompleted", True);
		EndIf;
		
		Parameters.Insert("HandlerName", HandlerName);
		Parameters.Insert("ExecutionProgress", ExecutionProgress);
		Parameters.Insert("SubsystemVersionAtStartUpdates", SubsystemVersionAtStartUpdates);
		
		Parameters.Insert("Queue", HandlerUpdates.DeferredProcessingQueue);
		
		If HandlerContext.WriteToLog1 Then
			HandlerContext.HandlerFullDetails = PrepareUpdateProgressDetails(HandlerUpdates,
				Parameters,
				HandlerUpdates.LibraryName,
				True);
		EndIf;
		
		UpdateProcedureStartCount = UpdateProcedureStartCount(ExecutionStatistics);
		UpdateThreadsCount1                = InfobaseUpdateThreadCount();
		MaximumNumberOfLaunches        = UpdateThreadsCount1 * 10000;
		
		If UpdateProcedureStartCount > MaximumNumberOfLaunches Then // 
			If ParametersOfUpdate.ParallelMode
				And Common.IsSubordinateDIBNode()
				And ParametersOfUpdate.HasMasterNodeHandlers Then
				ErrorText = NStr("en = 'The maximum number of update handler execution attempts is exceeded.
					|Ensure that all additional update handlers in the main node
					|are completed, synchronize the data,
					|and execute the update handlers in this node again.';");
			Else
				ErrorText = NStr("en = 'The maximum number of update attempts is exceeded.
					|The update is canceled to prevent an endless loop.';");
			EndIf;
			
			MinQueue = MinDeferredDataProcessorQueue();
			
			If Not ParametersOfUpdate.ParallelMode
				Or HandlerUpdates.DeferredProcessingQueue <= MinQueue Then
				AttemptCount = MaxUpdateAttempts(HandlerUpdates);
				HandlerProperty(HandlerUpdates.HandlerName, "AttemptCount", AttemptCount);
				Raise ErrorText;
			EndIf;
		EndIf;
		
		// 
		If ExecutionStatistics["DataProcessingStart"] = Undefined Then
			ExecutionStatistics.Insert("DataProcessingStart", CurrentSessionDate());
		EndIf;
		
		Properties = New Structure;
		Properties.Insert("Status", Enums.UpdateHandlersStatuses.Running);
		Properties.Insert("BatchProcessingCompleted", False);
		Properties.Insert("ExecutionStatistics", New ValueStorage(ExecutionStatistics));
		SetHandlerProperties(HandlerUpdates.HandlerName, Properties);
		
		DataToProcess = HandlerUpdates.DataToProcess.Get();
		If HandlerUpdates.Multithreaded Then
			CheckSelectionParameters(DataToProcess.SelectionParameters);
		EndIf;
		
		HandlerContext.DataProcessingStart = CurrentUniversalDateInMilliseconds();
		If ParametersOfUpdate.ParallelMode
			And Common.IsSubordinateDIBNode()
			And HandlerUpdates.ExecuteInMasterNodeOnly Then
			// 
			// 
			HandlerContext.SkipProcessedDataCheck = True;
			DataToProcessDetails = HandlerUpdates.DataToProcess.Get();
			HandlerData = DataToProcessDetails.HandlerData;
			
			If HandlerData.Count() = 0 Then
				Parameters.ProcessingCompleted = True;
			Else
				For Each ObjectToProcess In HandlerData Do
					Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(
						HandlerUpdates.DeferredProcessingQueue,
						ObjectToProcess.Key);
					If Not Parameters.ProcessingCompleted Then
						Break;
					EndIf;
				EndDo;
			EndIf;
		Else
			HandlerContext.ExecuteHandler = True;
			Return;
		EndIf;
	Except
		ProcessHandlerException(HandlerContext, HandlerUpdates, ErrorInfo());
		HandlerContext.StartedWithoutErrors = False;
	EndTry;
	
	EndDataProcessingProcedure(HandlerContext, HandlerUpdates.HandlerName);
	
EndProcedure

// Completion of the data processing procedure in the main thread.
//
// Parameters:
//  HandlerContext - See NewHandlerContext
//  HandlerName - String
//
Procedure AfterStartDataProcessingProcedure(HandlerContext, HandlerName)
	
	HandlerUpdates = HandlerUpdates(HandlerName);
	Parameters = HandlerContext.Parameters;
	ParametersOfUpdate = HandlerContext.ParametersOfUpdate;
	PropertiesToSet = New Structure;
	
	Try
		DataProcessingCompletion = CurrentUniversalDateInMilliseconds();
		FillingProcedureDetails = HandlerUpdates.DataToProcess.Get();
		
		If HandlerContext.Property("HandlingAHandlerException") Then
			Parameters.ProcessingCompleted = False;
		EndIf;
		
		If Parameters.ProcessingCompleted = Undefined Then
			ErrorText = NStr("en = 'The update handler cannot initialize parameter %1.
				|The execution is canceled due to an error in the handler code.';");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, "ProcessingCompleted");
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndIf;
		
		ExecutionStatistics = HandlerUpdates.ExecutionStatistics.Get();
		AddNumberOfLaunches = True;
		If Parameters.ProcessingCompleted Then
			ExecutionStatistics.Insert("DataProcessingCompletion", CurrentSessionDate());
			
			NetExecutionDuration = NetHandlerExecutionDuration(HandlerUpdates, ExecutionStatistics);
			
			PropertiesToSet.Insert("Status", Enums.UpdateHandlersStatuses.Completed);
			PropertiesToSet.Insert("Priority","OnSchedule");
			
			// 
			If ParametersOfUpdate.Property("InBackground")
				And ParametersOfUpdate.InBackground Then
				HandlerExecutionProgress = ParametersOfUpdate.HandlerExecutionProgress;
				HandlerExecutionProgress.CompletedHandlersCount = HandlerExecutionProgress.CompletedHandlersCount + 1;
				Progress = 10 + HandlerExecutionProgress.CompletedHandlersCount / HandlerExecutionProgress.TotalHandlerCount * 90;
				TimeConsumingOperations.ReportProgress(Progress);
			EndIf;
		ElsIf ParametersOfUpdate.ParallelMode And Not HandlerContext.SkipProcessedDataCheck Then
			HasProcessedObjects = SessionParameters.UpdateHandlerParameters.HasProcessedObjects;
			HandlerQueue = HandlerUpdates.DeferredProcessingQueue;
			
			MinQueue = 0;
			If HasProcessedObjects Then
				// 
				TransactionID = SessionParameters.UpdateHandlerParameters.TransactionID;
				RecordManager = InformationRegisters.CommitDataProcessedByHandlers.CreateRecordManager();
				RecordManager.TransactionID = TransactionID;
				RecordManager.Read();
				HasProcessedObjects = RecordManager.Selected();
				If HasProcessedObjects Then
					RecordManager.Delete();
				EndIf;
			EndIf;
			
			// 
			// 
			ProcessedRecordersTables = SessionParameters.UpdateHandlerParameters.ProcessedRecordersTables;
			If ValueIsFilled(ProcessedRecordersTables) Then
				If FillingProcedureDetails.ProcessedRecordersTables = Undefined Then
					FillingProcedureDetails.ProcessedRecordersTables = New Array;
				EndIf;
				CommonClientServer.SupplementArray(FillingProcedureDetails.ProcessedRecordersTables, ProcessedRecordersTables, True);
				PropertiesToSet.Insert("DataToProcess", New ValueStorage(FillingProcedureDetails));
				
				If Common.IdenticalCollections(FillingProcedureDetails.ProcessedRecordersTables, FillingProcedureDetails.RegisteredRecordersTables) Then
					PropertiesToSet.Insert("IsUpToDateDataProcessed", True);
				EndIf;
			EndIf;
			
			// 
			If Not HasProcessedObjects Then
				IsAllUpToDateDataProcessed = SessionParameters.UpdateHandlerParameters.IsUpToDateDataProcessed;
				If IsAllUpToDateDataProcessed = True Then
					PropertiesToSet.Insert("IsUpToDateDataProcessed", True);
				Else
					MinQueue = MinDeferredDataProcessorQueue();
				EndIf;
			EndIf;
			
			AddNumberOfLaunches = (HasProcessedObjects Or HandlerQueue <= MinQueue);
			
			If Not HasProcessedObjects
				And HandlerQueue <= MinQueue Then
				AttemptCount = HandlerUpdates.AttemptCount;
				MaxAttempts = MaxUpdateAttempts(HandlerUpdates) - 1;
				If AttemptCount >= MaxAttempts Then
					ExceptionText = NStr("en = 'The data processing procedure went into an endless loop and was canceled.';");
					Raise(ExceptionText, ErrorCategory.ConfigurationError);
				Else
					AttemptsCountToAdd = AttemptsCountToAdd(HandlerUpdates, HandlerContext);
					PropertiesToSet.Insert("AttemptCount", AttemptCount + AttemptsCountToAdd);
				EndIf;
			Else
				PropertiesToSet.Insert("AttemptCount", 0);
			EndIf;
		EndIf;
		
		// 
		If HandlerUpdates.Multithreaded Then
			ExecutionProgress = ExecutionStatistics["ExecutionProgress"];
			If ExecutionProgress = Undefined Then
				ExecutionStatistics.Insert("ExecutionProgress", Parameters.ExecutionProgress);
			Else
				ProcessedObjectsCount1 = Parameters.ExecutionProgress.ProcessedObjectsCount1;
				ExecutionProgress.ProcessedObjectsCount1 = ExecutionProgress.ProcessedObjectsCount1 + ProcessedObjectsCount1;
			EndIf;
		Else
			ExecutionStatistics.Insert("ExecutionProgress", Parameters.ExecutionProgress);
		EndIf;
		
		If AddNumberOfLaunches Then
			UpdateProcedureStartCount = UpdateProcedureStartCount(ExecutionStatistics) + 1;
		Else
			UpdateProcedureStartCount = UpdateProcedureStartCount(ExecutionStatistics);
		EndIf;
		
		If ValueIsFilled(NetExecutionDuration) Then
			ExecutionDuration = NetExecutionDuration;
		Else
			ExecutionDuration = DataProcessingCompletion - HandlerContext.DataProcessingStart;
			If ExecutionStatistics["ExecutionDuration"] <> Undefined Then
				ExecutionDuration = ExecutionDuration + ExecutionStatistics["ExecutionDuration"];
			EndIf;
		EndIf;
		ExecutionStatistics.Insert("ExecutionDuration", ExecutionDuration);
		ExecutionStatistics.Insert("StartsCount", UpdateProcedureStartCount);
		
		PropertiesToSet.Insert("ExecutionStatistics", New ValueStorage(ExecutionStatistics));
		PropertiesToSet.Insert("ProcessingDuration", ExecutionDuration);
		SetHandlerProperties(HandlerUpdates.HandlerName, PropertiesToSet);
	Except
		ProcessHandlerException(HandlerContext, HandlerUpdates, ErrorInfo());
	EndTry;
	
EndProcedure

// Completion of the data processing procedure.
//
// Parameters:
//  HandlerContext - See NewHandlerContext
//  HandlerName - String
//
Procedure EndDataProcessingProcedure(HandlerContext, HandlerName)
	
	HandlerUpdates = HandlerUpdates(HandlerName);
	
	Parameters = HandlerContext.Parameters;
	
	WriteProgressProgressHandler(HandlerContext.UpdateHandlerParameters);
	
	// 
	PassedParameters = PassedUpdateHandlerParameters(Parameters);
	ExecutionStatistics = HandlerUpdates.ExecutionStatistics.Get();
	ExecutionStatistics.Insert("HandlerParameters", PassedParameters);
	HandlerProperty(HandlerUpdates.HandlerName,
		"ExecutionStatistics",
		New ValueStorage(ExecutionStatistics));
	
	If HandlerContext.HasOpenTransactions Then
		// 
		HandlerUpdates.Status = Enums.UpdateHandlersStatuses.Error;
		HandlerUpdates.ErrorInfo = String(HandlerUpdates.ErrorInfo)
			+ Chars.LF + HandlerContext.ErrorInfo;
		
		HandlerUpdates.AttemptCount = MaxUpdateAttempts(HandlerUpdates);
		
		Properties = New Structure;
		Properties.Insert("AttemptCount", HandlerUpdates.AttemptCount);
		Properties.Insert("Status", HandlerUpdates.Status);
		Properties.Insert("ErrorInfo", HandlerUpdates.ErrorInfo);
		SetHandlerProperties(HandlerUpdates.HandlerName, Properties);
	EndIf;
	
	If HandlerContext.WriteToLog1 Then
		WriteUpdateProgressDetails(HandlerContext.HandlerFullDetails);
	EndIf;
	
EndProcedure

Procedure FillLockedItems(VersionRow, LockedObjectsInfo)
	
	For Each Handler In VersionRow.Rows Do
		CheckProcedure  = Handler.CheckProcedure;
		ObjectsToLock = Handler.ObjectsToLock;
		If ValueIsFilled(CheckProcedure) And ValueIsFilled(ObjectsToLock) Then
			HandlerProperties = New Structure;
			HandlerProperties.Insert("Completed", False);
			HandlerProperties.Insert("CheckProcedure", CheckProcedure);
			
			LockedObjectsInfo.Handlers.Insert(Handler.HandlerName, HandlerProperties);
			LockedObjectArray = StrSplit(ObjectsToLock, ",");
			For Each LockedObject In LockedObjectArray Do
				LockedObject = StrReplace(TrimAll(LockedObject), ".", "");
				ObjectInformation = LockedObjectsInfo.ObjectsToLock[LockedObject];
				If ObjectInformation = Undefined Then
					HandlersArray = New Array;
					HandlersArray.Add(Handler.HandlerName);
					LockedObjectsInfo.ObjectsToLock.Insert(LockedObject, HandlersArray);
				Else
					LockedObjectInfo = LockedObjectsInfo.ObjectsToLock[LockedObject]; // Array
					LockedObjectInfo.Add(Handler.HandlerName);
				EndIf;
			EndDo;
		ElsIf ValueIsFilled(ObjectsToLock) And Not ValueIsFilled(CheckProcedure) Then
			ExceptionText =  StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'In deferred update handler ""%1"",
					|the list of locked objects is filled in but property ""%2"" is not specified.';"),
					Handler.HandlerName, "CheckProcedure");
			Raise(ExceptionText, ErrorCategory.ConfigurationError);
		EndIf;
	EndDo;
	
EndProcedure

Function NewLockedObjectsInfo(PreviousInfo = Undefined)
	
	LockedObjectsInfo = New Structure;
	LockedObjectsInfo.Insert("ObjectsToLock", New Map);
	LockedObjectsInfo.Insert("Handlers", New Map);
	LockedObjectsInfo.Insert("UnlockedObjects", New Map);
	
	If TypeOf(PreviousInfo) = Type("Structure") Then
		FillPropertyValues(LockedObjectsInfo, PreviousInfo);
	EndIf;
	
	Return LockedObjectsInfo;
	
EndFunction

Procedure WriteLockedObjectsInfo(InformationRecords) Export
	
	If InformationRecords = Undefined Then
		NewValue = NewLockedObjectsInfo();
	Else
		NewValue = InformationRecords;
	EndIf;
	
	ManagerOfConstant = Constants.LockedObjectsInfo.CreateValueManager();
	ManagerOfConstant.Value = New ValueStorage(NewValue);
	InfobaseUpdate.WriteData(ManagerOfConstant);
	
EndProcedure

Procedure FillDataForParallelDeferredUpdate1(Parameters) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		CanlcelDeferredUpdateHandlersRegistration();
		Return;
	EndIf;
	
	If Parameters.OnClientStart
		And Parameters.DeferredUpdateMode = "Deferred" Then
		ClientServer  = Not Common.FileInfobase();
		Box       = Not Common.DataSeparationEnabled();
		
		If ClientServer And Box Then
			// 
			Return;
		EndIf;
	EndIf;
	
	UpdateRestart      = Parameters.Property("UpdateRestart");
	RegisteredHandlers = New Array;
	If Parameters.Property("RegisteredHandlers") Then
		RegisteredHandlers = Parameters.RegisteredHandlers;
	EndIf;
	
	DeleteAllUpdateThreads();
	
	If Not (StandardSubsystemsCached.DIBUsed("WithFilter") And Common.IsSubordinateDIBNode()) And Not UpdateRestart Then
		Query = New Query;
		Query.Text =
		"SELECT
		|	InfobaseUpdate.Ref AS Node
		|FROM
		|	ExchangePlan.InfobaseUpdate AS InfobaseUpdate
		|WHERE
		|	NOT InfobaseUpdate.ThisNode";
		
		Upload0 = Query.Execute().Unload();
		ExchangeNodes = Upload0.UnloadColumn("Node");
		
		For Each CompositionItem In Metadata.ExchangePlans.InfobaseUpdate.Content Do
			ExchangePlans.DeleteChangeRecords(ExchangeNodes, CompositionItem.Metadata);
		EndDo;
	EndIf;
	
	UpdateInfo = InfobaseUpdateInfo();
	SubsystemVersionsAtStartUpdates = UpdateInfo.SubsystemVersionsAtStartUpdates;
	
	If Not Common.IsSubordinateDIBNode()
		And Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.ResetConstantValueWithChangesForSubordinateDIBNodeWithFilters();
	EndIf;
	
	ParametersInitialized = False;
	
	Handlers = HandlersForDeferredDataRegistration(False, UpdateRestart, RegisteredHandlers);
	
	For Each Handler In Handlers Do
		
		SubsystemVersionAtStartUpdates = SubsystemVersionsAtStartUpdates[Handler.LibraryName];
		
		If Not ParametersInitialized Then
			
			HandlerParametersStructure = InfobaseUpdate.MainProcessingMarkParameters();
			ParametersInitialized = True;
			
			If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
				ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
				ModuleDataExchangeServer.InitializeUpdateDataFile(HandlerParametersStructure);
			EndIf;
			
		EndIf;
		
		HandlerParametersStructure.Queue = Handler.DeferredProcessingQueue;
		HandlerParametersStructure.HandlerName = Handler.HandlerName;
		HandlerParametersStructure.Insert("HandlerData", New Map);
		HandlerParametersStructure.Insert("UpdateRestart", UpdateRestart);
		HandlerParametersStructure.Insert("UpToDateData", InfobaseUpdate.UpToDateDataSelectionParameters());
		HandlerParametersStructure.Insert("RegisteredRecordersTables", New Map); 
		HandlerParametersStructure.Insert("SubsystemVersionAtStartUpdates", SubsystemVersionAtStartUpdates);
		
		If Handler.Multithreaded Then
			HandlerParametersStructure.SelectionParameters =
				InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters();
		Else
			HandlerParametersStructure.SelectionParameters = Undefined;
		EndIf;
		
		HandlerParameters = New Array;
		HandlerParameters.Add(HandlerParametersStructure);
		Try
			Message = NStr("en = 'Executing data population procedure
				                   |%1
				                   |of deferred update handler
				                   |%2.';");
			Message = StringFunctionsClientServer.SubstituteParametersToString(Message,
				Handler.UpdateDataFillingProcedure,
				Handler.HandlerName);
			WriteInformation(Message);
			
			RegistrationStart = CurrentUniversalDateInMilliseconds();
			Common.ExecuteConfigurationMethod(Handler.UpdateDataFillingProcedure, HandlerParameters);
			RegistrationEnd  = CurrentUniversalDateInMilliseconds();
			
			RegistrationDuration = (RegistrationEnd - RegistrationStart) / 1000; 
			
			If Handler.Multithreaded Then
				CorrectFullNamesInTheSelectionParameters(HandlerParametersStructure.SelectionParameters);
			EndIf;
			
			// 
			If Not UpdateRestart And Parameters.InBackground Then
				HandlerExecutionProgress = Parameters.HandlerExecutionProgress;
				HandlerExecutionProgress.CompletedHandlersCount = HandlerExecutionProgress.CompletedHandlersCount + 1;
				Progress = 10 + HandlerExecutionProgress.CompletedHandlersCount / HandlerExecutionProgress.TotalHandlerCount * 90;
				TimeConsumingOperations.ReportProgress(Progress);
			EndIf;
		Except
			If Not UpdateRestart Then
				CanlcelDeferredUpdateHandlersRegistration(Handler.LibraryName, False);
			EndIf;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'An error occurred while calling data population procedure
						   |""%1""
						   |of deferred update handler
						   |""%2"":
						   |%3.
						   |';"),
				Handler.UpdateDataFillingProcedure,
				Handler.HandlerName,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteError(ErrorText);

			Properties = New Structure;
			Properties.Insert("Status", Enums.UpdateHandlersStatuses.Error);
			Properties.Insert("ErrorInfo", ErrorText);
			SetHandlerProperties(Handler.HandlerName, Properties);

			Raise;
		EndTry;
		
		DataToProcessDetails = NewDataToProcessDetails(Handler.Multithreaded);
		DataToProcessDetails.HandlerData = HandlerParametersStructure.HandlerData;
		DataToProcessDetails.HandlerName    = Handler.HandlerName;
		DataToProcessDetails.UpToDateData  = HandlerParametersStructure.UpToDateData;
		If ValueIsFilled(HandlerParametersStructure.RegisteredRecordersTables) Then
			RegisteredTables = New Array;
			For Each KeyAndValue In HandlerParametersStructure.RegisteredRecordersTables Do
				RegisteredTables.Add(KeyAndValue.Value);
			EndDo;
		EndIf;
		DataToProcessDetails.RegisteredRecordersTables = RegisteredTables;
		
		If Handler.Multithreaded Then
			DataToProcessDetails.SelectionParameters = HandlerParametersStructure.SelectionParameters;
		EndIf;
		
		DataToProcessDetails = New ValueStorage(DataToProcessDetails, New Deflation(9));
		
		PropertiesToSet = New Structure;
		PropertiesToSet.Insert("DataToProcess", DataToProcessDetails);
		PropertiesToSet.Insert("DataRegistrationDuration", RegistrationDuration);
		If IsUpToDateFilterSet(HandlerParametersStructure.UpToDateData) Then
			PropertiesToSet.Insert("IsSeveritySeparationUsed", True);
		EndIf;
		
		SetHandlerProperties(Handler.HandlerName, PropertiesToSet);
	EndDo;
	
	If Not UpdateRestart Then
		CanlcelDeferredUpdateHandlersRegistration();
	EndIf;
	
	If ParametersInitialized And Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.CompleteWriteUpdateDataFile(HandlerParametersStructure);
	EndIf;
	
EndProcedure

// Fill in data for parallel deferred updates in the background using multiple threads.
//
// Parameters:
//  FormIdentifier - UUID -  ID of the form that displays the update process.
//  ResultAddress - String -  address of the temporary storage with the result of the procedure.
//
Procedure StartDeferredHandlerDataRegistration(FormIdentifier, ResultAddress) Export
	
	Groups = NewDetailsOfDeferredUpdateDataRegistrationThreadsGroups();
	
	Handlers = HandlersForDeferredDataRegistration();
	DeleteAllUpdateThreads();
	
	Try
		CurrentQueue = ?(Handlers.Count() > 0, Handlers[0].DeferredProcessingQueue, 0);
		For Each Handler In Handlers Do
			If Handler.DeferredProcessingQueue > CurrentQueue Then
				WaitForAllThreadsCompletion(Groups); // 
				CurrentQueue = Handler.DeferredProcessingQueue;
			EndIf;
			
			DataToProcessDetails = Handler.DataToProcess.Get();
			
			Stream = AddDeferredUpdateDataRegistrationThread(DataToProcessDetails);
			ExecuteThread(Groups, Stream, FormIdentifier);
			WaitForAvailableThread(Groups); // 
		EndDo;
		
		WaitForAllThreadsCompletion(Groups);
		DeleteAllUpdateThreads();
	Except
		CancelAllThreadsExecution(Groups);
		DeleteAllUpdateThreads();
		Raise;
	EndTry;
	
EndProcedure

// Filling in the data of a deferred handler in the background task.
//
// Parameters:
//  DataToProcessDetails - See NewDataToProcessDetails
//  ResultAddress - String -  address of the temporary storage for saving the result of the procedure.
//
Procedure FillDeferredHandlerData(DataToProcessDetails, ResultAddress) Export
	
	ProcessingMarkParameters = InfobaseUpdate.MainProcessingMarkParameters();
	DataExchangeSubsystemExists = Common.SubsystemExists("StandardSubsystems.DataExchange");
	
	If DataExchangeSubsystemExists Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.InitializeUpdateDataFile(ProcessingMarkParameters);
	EndIf;
	
	ProcessingMarkParameters.Queue = DataToProcessDetails.Queue;
	ProcessingMarkParameters.HandlerName = DataToProcessDetails.HandlerName;
	ProcessingMarkParameters.SubsystemVersionAtStartUpdates = DataToProcessDetails.SubsystemVersionAtStartUpdates;
	ProcessingMarkParameters.Insert("HandlerData", New Map);
	MultithreadMode = IsMultithreadHandlerDataDetails(DataToProcessDetails);
	
	If MultithreadMode Then
		ProcessingMarkParameters.SelectionParameters =
			InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters();
	Else
		ProcessingMarkParameters.SelectionParameters = Undefined;
	EndIf;
	
	HandlerParameters = New Array;
	HandlerParameters.Add(ProcessingMarkParameters);
	
	MessageTemplate = NStr(
		"en = 'Executing data population procedure
		|%1
		|of deferred update handler
		|%2.';");
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
		DataToProcessDetails.FillingProcedure,
		DataToProcessDetails.HandlerName);
	WriteInformation(MessageText);
	
	Try
		RegistrationStart = CurrentUniversalDateInMilliseconds();
		Common.ExecuteConfigurationMethod(DataToProcessDetails.FillingProcedure, HandlerParameters);
		RegistrationEnd  = CurrentUniversalDateInMilliseconds();
	Except
		ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorTemplate = NStr(
			"en = 'An error occurred while calling data population procedure
			|""%1""
			|of deferred update handler
			|""%2"":
			|%3.
			|';");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
			DataToProcessDetails.FillingProcedure,
			DataToProcessDetails.HandlerName,
			ErrorInfo);
		WriteError(ErrorText);

		Properties = New Structure;
		Properties.Insert("Status", Enums.UpdateHandlersStatuses.Error);
		Properties.Insert("ErrorInfo", ErrorText);
		SetHandlerProperties(DataToProcessDetails.HandlerName, Properties);

		Raise;
	EndTry;
	
	DataRegistrationDuration = (RegistrationEnd - RegistrationStart) / 1000;
	
	Result = New Structure;
	Result.Insert("HandlerData", ProcessingMarkParameters.HandlerData);
	Result.Insert("DataRegistrationDuration", DataRegistrationDuration);
	Result.Insert("UpToDateData", ProcessingMarkParameters.UpToDateData);
	Result.Insert("RegisteredRecordersTables", ProcessingMarkParameters.RegisteredRecordersTables);
	
	If MultithreadMode Then
		Result.Insert("SelectionParameters", ProcessingMarkParameters.SelectionParameters);
	EndIf;
	
	If DataExchangeSubsystemExists Then
		UpdateData = ModuleDataExchangeServer.CompleteWriteFileAndGetUpdateData(ProcessingMarkParameters);
		Result.Insert("UpdateData", UpdateData);
		Result.Insert("NameOfChangedFile", ProcessingMarkParameters.NameOfChangedFile);
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure SetUpdateHandlerParameters(HandlerUpdates, Deferred = False, Parallel = False)
	
	If HandlerUpdates = Undefined Then
		SessionParameters.UpdateHandlerParameters = New FixedStructure(NewUpdateHandlerParameters());
		Return;
	EndIf;
	
	If Deferred Then
		ExecutionMode = "Deferred";
		HandlerName = HandlerUpdates.HandlerName;
	Else
		ExecutionMode = "Exclusively";
		HandlerName = HandlerUpdates.Procedure;
	EndIf;
	
	If Parallel Then
		DeferredHandlersExecutionMode = "Parallel";
	Else
		DeferredHandlersExecutionMode = "Sequentially";
	EndIf;
	
	Get_Properties = New Structure;
	Get_Properties.Insert("ObjectsToChange", "");
	FillPropertyValues(Get_Properties, HandlerUpdates);
	
	UpdateHandlerParameters = NewUpdateHandlerParameters();
	UpdateHandlerParameters.ExecuteInMasterNodeOnly = HandlerUpdates.ExecuteInMasterNodeOnly;
	UpdateHandlerParameters.RunAlsoInSubordinateDIBNodeWithFilters = HandlerUpdates.RunAlsoInSubordinateDIBNodeWithFilters;
	UpdateHandlerParameters.DeferredProcessingQueue = HandlerUpdates.DeferredProcessingQueue;
	UpdateHandlerParameters.ExecutionMode = ExecutionMode;
	UpdateHandlerParameters.DeferredHandlersExecutionMode = DeferredHandlersExecutionMode;
	UpdateHandlerParameters.KeyRecordProgressUpdates = New UUID;
	UpdateHandlerParameters.HasProcessedObjects = False;
	UpdateHandlerParameters.HandlerName = HandlerName;
	UpdateHandlerParameters.ObjectsToChange = UniqueValuesSeparatedByCommas(Get_Properties.ObjectsToChange);
	If Parallel Then
		DataToProcess = HandlerUpdates.DataToProcess.Get();
		If TypeOf(DataToProcess) = Type("Structure")
			And DataToProcess.Property("UpToDateData")
			And TypeOf(DataToProcess.UpToDateData) = Type("Structure") Then
			DataToProcess.UpToDateData.ComparisonType = ComparisonKindAsString(DataToProcess.UpToDateData.ComparisonType, HandlerName);
			UpdateHandlerParameters.UpToDateData = New FixedStructure(DataToProcess.UpToDateData);
		EndIf;
	EndIf;
	
	SessionParameters.UpdateHandlerParameters = New FixedStructure(UpdateHandlerParameters);
	
EndProcedure

Function NewUpdateHandlerParameters() Export
	UpdateHandlerParameters = New Structure;
	UpdateHandlerParameters.Insert("ExecuteInMasterNodeOnly", False);
	UpdateHandlerParameters.Insert("RunAlsoInSubordinateDIBNodeWithFilters", False);
	UpdateHandlerParameters.Insert("DeferredProcessingQueue", 0);
	UpdateHandlerParameters.Insert("ExecutionMode", "");
	UpdateHandlerParameters.Insert("DeferredHandlersExecutionMode", "");
	UpdateHandlerParameters.Insert("HasProcessedObjects", False);
	UpdateHandlerParameters.Insert("KeyRecordProgressUpdates", Undefined);
	UpdateHandlerParameters.Insert("HandlerName", "");
	UpdateHandlerParameters.Insert("ObjectsToChange", "");
	UpdateHandlerParameters.Insert("TransactionID", "");
	UpdateHandlerParameters.Insert("UpToDateData", Undefined);
	UpdateHandlerParameters.Insert("IsUpToDateDataProcessed", Undefined);
	UpdateHandlerParameters.Insert("ProcessedRecordersTables", Undefined);
	UpdateHandlerParameters.Insert("ProgressLastRecordDate", Undefined);
	UpdateHandlerParameters.Insert("ProcessedObjectsCount1", 0);
	
	Return UpdateHandlerParameters;
EndFunction

Function ComparisonKindAsString(Val ComparisonCondition, HandlerName)
	
	If Not ValueIsFilled(ComparisonCondition) Then
		Return "";
	ElsIf ComparisonCondition = ComparisonType.Greater Then
		ComparisonCondition = ">";
	ElsIf ComparisonCondition = ComparisonType.GreaterOrEqual Then
		ComparisonCondition = ">=";
	ElsIf ComparisonCondition = ComparisonType.Less Then
		ComparisonCondition = "<";
	ElsIf ComparisonCondition = ComparisonType.LessOrEqual Then
		ComparisonCondition = "<=";
	ElsIf ComparisonCondition = ComparisonType.Equal Then
		ComparisonCondition = "=";
	ElsIf ComparisonCondition = ComparisonType.NotEqual Then
		ComparisonCondition = "<>";
	Else
		ErrorText = NStr("en = 'Invalid comparison type ""%1"" is specified for the relevant data filter
			|in the data registration procedure of the ""%2"" handler.
			|For valid types, see the function ""%3""';");
		AvailableCompareTypes = "InfobaseUpdate.UpToDateDataSelectionParameters";
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
			ComparisonCondition, HandlerName, AvailableCompareTypes);
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	Return ComparisonCondition;
	
EndFunction

Function FilterOfUpToDateData(HandlerParameters, TableAlias) Export
	
	Result = New Structure;
	Result.Insert("Condition", "TRUE");
	Result.Insert("Value", Undefined);
	Result.Insert("HasSelectionFilter", False);
	
	If HandlerParameters = Undefined Then
		Parameters = SessionParameters.UpdateHandlerParameters;
		FilterUpToDateData = Parameters.UpToDateData;
	Else
		FilterUpToDateData = HandlerParameters.UpToDateData;
	EndIf;
	
	
	If FilterUpToDateData = Undefined Then
		Return Result;
	EndIf;
	
	If Not IsUpToDateFilterSet(FilterUpToDateData) Then
		Return Result;
	EndIf;
	
	OrderOfDataToProcess = CurrentUpdatingProcedure();
	If OrderOfDataToProcess = Enums.OrderOfUpdateHandlers.Noncritical Then
		Return Result;
	EndIf;
	
	ComparisonCondition = FilterUpToDateData.ComparisonType;
	ConditionTemplate = "%1.%2 %3 &UpToDateDataFilterVal";
	
	Condition = StringFunctionsClientServer.SubstituteParametersToString(
		ConditionTemplate,
		TableAlias,
		FilterUpToDateData.FilterField,
		ComparisonCondition);
	
	Result.Condition  = Condition;
	Result.Value = FilterUpToDateData.Value;
	Result.HasSelectionFilter = True;
	
	Return Result;
	
EndFunction

Function IsUpToDateFilterSet(FilterUpToDateData)
	
	If (TypeOf(FilterUpToDateData) = Type("Structure") Or TypeOf(FilterUpToDateData) = Type("FixedStructure"))
		And ValueIsFilled(FilterUpToDateData.FilterField)
		And ValueIsFilled(FilterUpToDateData.ComparisonType) Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Handle an exception that occurred when preparing or completing the handler execution in the main thread.
//
// Parameters:
//  HandlerContext - See NewHandlerContext
//  HandlerUpdates - ValueTreeRow -  update handler as a string in the handler tree.
//
Procedure ProcessHandlerException(HandlerContext, HandlerUpdates, ErrorInfo)
	
	If HandlerContext.WriteToLog1 Then
		WriteUpdateProgressDetails(HandlerContext.HandlerFullDetails);
	EndIf;
	
	// 
	If Not HandlerContext.Property("SkipCancelingTransactions") Then
		While TransactionActive() Do
			RollbackTransaction();
		EndDo;
	EndIf;
	// 
	
	AttemptsCountToAdd = AttemptsCountToAdd(HandlerUpdates, HandlerContext, True);
	AttemptCount = HandlerUpdates.AttemptCount + AttemptsCountToAdd;
	DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
	
	MaxUpdateAttempts = MaxUpdateAttempts(HandlerUpdates);
	
	If AttemptCount < MaxUpdateAttempts Then
		WriteWarning(DetailErrorDescription);
	Else
		InfobaseUpdate.WriteEventToRegistrationLog(DetailErrorDescription, , HandlerContext.Parameters);
	EndIf;
	
	Properties = New Structure;
	Properties.Insert("AttemptCount", AttemptCount);
	Properties.Insert("Status", Enums.UpdateHandlersStatuses.Error);
	Properties.Insert("ErrorInfo", DetailErrorDescription);
	SetHandlerProperties(HandlerUpdates.HandlerName, Properties);
	
EndProcedure

// 
// 
//
// Parameters:
//   See NewBatchesSetForUpdate
//   See NewThreadsDetails
//  HandlerContext - See NewHandlerContext
//
Procedure ProcessDataFragmentInThread(Particle, Groups, HandlerContext)
	
	HandlerContextForThread = Common.CopyRecursive(HandlerContext); // See NewHandlerContext
	HandlerContextForThread.Parameters.DataToUpdate = Particle;
	Stream = NewThread();
	AddUpdateHandlerThread(Stream, HandlerContextForThread);
	ExecuteThread(Groups, Stream);
	HandlerContextForThread.Parameters.DataToUpdate.DataSet = Undefined;
	
EndProcedure

// Get the number of runs of the update procedure.
//
// Parameters:
//  Update handler-assignment String-update handler as a string in the handler tree.
//
// Returns:
//  Number - 
//
Function UpdateProcedureStartCount(ExecutionStatistics)
	
	UpdateProcedureStartCount = ExecutionStatistics["StartsCount"];
	
	If UpdateProcedureStartCount = Undefined Then
		UpdateProcedureStartCount = 0;
	EndIf;
	
	Return UpdateProcedureStartCount;
	
EndFunction

// Returns the maximum number of update attempts for the specified update handler.
//
// Parameters:
//  HandlerUpdates - ValueTableRow -  update handler as a string in the handler tree.
//
// Returns:
//  Number - 
//
Function MaxUpdateAttempts(HandlerUpdates)
	
	If HandlerUpdates.Multithreaded Then
		DataToProcess = HandlerUpdates.DataToProcess.Get();
		SelectionParameters = DataToProcess.SelectionParameters;
		FullNamesOfObjects = SelectionParameters.FullNamesOfObjects;
		FullRegistersNames = SelectionParameters.FullRegistersNames;
		ObjectsComposition = StrSplit(FullNamesOfObjects, ",");
		RegistersComposition = StrSplit(FullRegistersNames, ",");
		ThreadsCount = InfobaseUpdateThreadCount();
		Multiplier = ObjectsComposition.Count() * RegistersComposition.Count() + ThreadsCount;
	Else
		Multiplier = 1;
	EndIf;
	
	Return 3 * Multiplier;
	
EndFunction

// The number of added attempts to counter Cyclopoida.
//
// Parameters:
//  HandlerUpdates - ValueTreeRow -  update handler as a string in the handler tree.
//  HandlerContext - See NewHandlerContext
//  Error - Boolean -  True if an error occurred in the update handler.
//
// Returns:
//  Number - 
//
Function AttemptsCountToAdd(HandlerUpdates, HandlerContext, Error = False)
	
	If HandlerUpdates.Multithreaded Then
		If HandlerContext.Parameters.Property("DataToUpdate") Then
			DataToUpdate = HandlerContext.Parameters.DataToUpdate;
		Else
			DataToUpdate = Undefined;
		EndIf;
		
		// 
		// 
		// 
		If DataToUpdate <> Undefined Then
			HasData = DataToUpdate.FirstRecord <> Undefined Or DataToUpdate.LatestRecord <> Undefined;
			If Not HasData And Not Error Then
				Return 0;
			EndIf;
		EndIf;
	EndIf;
	
	Return 1;
	
EndFunction

Function MinDeferredDataProcessorQueue()
	
	Query = New Query;
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.SetParameter("Status", Enums.UpdateHandlersStatuses.Completed);
	Query.SetParameter("DeferredHandlerExecutionMode", Enums.DeferredHandlersExecutionModes.Parallel);
	Query.Text =
		"SELECT
		|	UpdateHandlers.DeferredProcessingQueue AS Queue,
		|	UpdateHandlers.Multithreaded AS Multithreaded,
		|	UpdateHandlers.DataToProcess AS DataToProcess,
		|	UpdateHandlers.Status AS Status,
		|	UpdateHandlers.AttemptCount AS AttemptCount
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode
		|	AND UpdateHandlers.DeferredHandlerExecutionMode = &DeferredHandlerExecutionMode
		|	AND UpdateHandlers.Status <> &Status
		|
		|ORDER BY
		|	Queue";
	Result = Query.Execute().Unload();
	If Result.Count() = 0 Then
		Return 0;
	EndIf;
	For Each HandlerUpdates In Result Do
		If HandlerUpdates.Status <> Enums.UpdateHandlersStatuses.Error Then
			Break;
		EndIf;
		MaxAttempts = MaxUpdateAttempts(HandlerUpdates) - 1;
		If HandlerUpdates.AttemptCount >= MaxAttempts Then
			Continue;
		Else
			Break;
		EndIf;
	EndDo;
	
	Return HandlerUpdates.Queue;
	
EndFunction

Function TheRemainderOfTheArray(Array, StartValue)
	
	TheRemainderOfTheArray = New Array;
	ExactStartValue = TrimAll(StartValue);
	ValueFound2 = False;
	
	For Each Item In StrSplitTrimAll(Array, ",") Do
		If ExactStartValue = Item Then
			ValueFound2 = True;
		EndIf;
		
		If ValueFound2 Then
			TheRemainderOfTheArray.Add(Item);
		EndIf;
	EndDo;
	
	Return TheRemainderOfTheArray;
	
EndFunction

// Correct the comma-separated full names of objects and registers
// using a unique comma-separated value so that the cursor selection of data does not go astray.
//
// Parameters:
//  SelectionParameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters
//
Procedure CorrectFullNamesInTheSelectionParameters(SelectionParameters)
	
	SelectionParameters.FullNamesOfObjects = UniqueValuesSeparatedByCommas(SelectionParameters.FullNamesOfObjects);
	SelectionParameters.FullRegistersNames = UniqueValuesSeparatedByCommas(SelectionParameters.FullRegistersNames);
	
EndProcedure

// Leave only the unique values listed separated by commas and arrange them.
//
// Parameters:
//  String - String -  comma-separated values.
//
// Returns:
//  String - 
//
Function UniqueValuesSeparatedByCommas(String)
	
	If String = Undefined Then
		Return Undefined;
	EndIf;
	
	Values = StrSplit(String, ",");
	Table = New ValueTable;
	Table.Columns.Add("Value");
	
	For Each Value In Values Do
		ExactValue = TrimAll(Value);
		
		If Not IsBlankString(ExactValue) Then
			TableRow = Table.Add();
			TableRow.Value = ExactValue;
		EndIf;
	EndDo;
	
	Table.GroupBy("Value");
	Table.Sort("Value");
	Values = Table.UnloadColumn("Value");
	
	Return StrConcat(Values, ",");
	
EndFunction

Function DetailsCell(Status, HasErrors, ProblemInData) Export
	Array = New Array;
	Array.Add(Status);
	Array.Add(HasErrors);
	Array.Add(ProblemInData);
	Return Array;
EndFunction

Procedure ResetProgressProgressHandlers()
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	Set = InformationRegisters.UpdateProgress.CreateRecordSet();
	Set.Write();
	
EndProcedure

Procedure AddErrorInformationInHandler(HandlerName) Export
	
	If Not ValueIsFilled(HandlerName) Then
		ErrorText = NStr("en = 'Couldn''t save error details in the handler.
			|Reason:
			|Seems like the call wasn''t made from the update handler.';");
		WriteError(ErrorText);
		Return;
	EndIf;
	
	DataLock = New DataLock;
	DataLockItem = DataLock.Add("InformationRegister.UpdateHandlers");
	DataLockItem.SetValue("HandlerName", HandlerName);
	BeginTransaction();
	Try
		DataLock.Lock();
		
		RecordManager = InformationRegisters.UpdateHandlers.CreateRecordManager();
		RecordManager.HandlerName = HandlerName;
		RecordManager.Read();
		
		ExecutionStatistics = RecordManager.ExecutionStatistics;
		ExecutionStatistics = ExecutionStatistics.Get();
		ExecutionStatistics.Insert("HasErrors", True);
		RecordManager.ExecutionStatistics = New ValueStorage(ExecutionStatistics);
		RecordManager.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorInfo = ErrorInfo();
		ErrorText = NStr("en = 'Couldn''t save error details in handler ""%1"".
			|Reason:
			|%2';");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
			HandlerName, ErrorProcessing.DetailErrorDescription(ErrorInfo));
		WriteError(ErrorText);
	EndTry
	
EndProcedure

Procedure Pause(Seconds) Export
	
	CurrentInfobaseSession1 = GetCurrentInfoBaseSession();
	BackgroundJob = CurrentInfobaseSession1.GetBackgroundJob();
	
	If BackgroundJob = Undefined Then
		Parameters = New Array;
		Parameters.Add(Seconds);
		BackgroundJob = BackgroundJobs.Execute("InfobaseUpdateInternal.Pause", Parameters);
	EndIf;
	
	BackgroundJob.WaitForExecutionCompletion(Seconds);
	
EndProcedure

Function StepDurationAsString(Val Duration) Export
	
	If Duration < 1 Then
		Return "< " + NStr("en = '1 sec';");
	ElsIf Duration < 60 Then
		Template = NStr("en = '%1 sec';");
		Return StringFunctionsClientServer.SubstituteParametersToString(Template, Int(Duration));
	ElsIf Duration < 3600 Then
		Template = NStr("en = '%1 min %2 sec';");
		Duration = Duration / 60; // 
		Minutes1 = Int(Duration);
		Seconds = Int((Duration - Minutes1) * 60);
		Return StringFunctionsClientServer.SubstituteParametersToString(Template, Minutes1, Seconds);
	Else
		Template = NStr("en = '%1 h %2 min';");
		Duration = Duration / 60 / 60; // 
		Hours1 = Int(Duration);
		Minutes1 = Int((Duration - Hours1) * 60);
		Return StringFunctionsClientServer.SubstituteParametersToString(Template, Hours1, Minutes1);
	EndIf;
	
EndFunction

Function CurrentUpdatingProcedure()
	
	OrderOfUpdate = Undefined;
	If Common.DataSeparationEnabled() Then
		FileIB = Common.FileInfobase();
		ClientLaunchParameter  = StandardSubsystemsServer.ClientParametersAtServer().Get("LaunchParameter");
		ForcingDeferredOne = StrFind(Lower(ClientLaunchParameter), Lower("ExecuteDeferredUpdateNow")) > 0;
		If ForcingDeferredOne Or FileIB Then
			Return Enums.OrderOfUpdateHandlers.Noncritical;
		Else
			OrderOfUpdate = Constants.OrderOfDataToProcess.Get();
		EndIf;
	Else
		OrderOfUpdate = Constants.OrderOfDataToProcess.Get();
	EndIf;
	
	If Not ValueIsFilled(OrderOfUpdate) Then
		Return Enums.OrderOfUpdateHandlers.Crucial;
	Else
		Return OrderOfUpdate;
	EndIf;
	
EndFunction

Function QueuesToClear(ProcessedItems)
	
	Query = New Query;
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.SetParameter("Status", Enums.UpdateHandlersStatuses.Completed);
	Query.SetParameter("DeferredHandlerExecutionMode", Enums.DeferredHandlersExecutionModes.Parallel);
	Query.SetParameter("ProcessedItems", ProcessedItems);
	Query.Text =
		"SELECT DISTINCT
		|	UpdateHandlers.DeferredProcessingQueue AS Queue
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode
		|	AND UpdateHandlers.DeferredHandlerExecutionMode = &DeferredHandlerExecutionMode
		|	AND UpdateHandlers.Status = &Status
		|	AND NOT UpdateHandlers.DeferredProcessingQueue IN (&ProcessedItems)
		|	AND NOT TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				InformationRegister.UpdateHandlers AS UpdateHandlersCheck
		|			WHERE
		|				UpdateHandlersCheck.DeferredProcessingQueue = UpdateHandlers.DeferredProcessingQueue
		|				AND UpdateHandlersCheck.Status <> &Status)";
	
	Result = Query.Execute().Unload().UnloadColumn("Queue");
	Return Result;
	
EndFunction

Procedure PopulateDataToReadAndChange(Handler, TablesToReadAndChange)
	HandlerQueue = Handler.DeferredProcessingQueue;
	TablesInQueue = TablesToReadAndChange[HandlerQueue];
	If TablesInQueue = Undefined Then
		TablesInQueue = New Array;
	EndIf;
	
	TablesToRead   = StrSplit(Handler.ObjectsToRead, ",", False);
	TablesToChange = StrSplit(Handler.ObjectsToChange, ",", False); 
	
	HandlerNameByParts = StrSplit(Handler.HandlerName, ".");
	If HandlerNameByParts.Count() > 2 Then
		Position      = StrFind(Handler.HandlerName, ".", SearchDirection.FromEnd);
		ManagerName = Left(Handler.HandlerName, Position - 1);
		FullObjectName = MetadataObjectNameByManagerName(ManagerName); 
		If TablesInQueue.Find(FullObjectName) = Undefined Then
			TablesInQueue.Add(FullObjectName);
		EndIf;
	EndIf;
	
	CommonClientServer.SupplementArray(TablesInQueue, TablesToRead, True);
	CommonClientServer.SupplementArray(TablesInQueue, TablesToChange, True);
	
	TablesToReadAndChange.Insert(HandlerQueue, TablesInQueue);
EndProcedure

Procedure ClearProcessedQueues(QueuesToClear, ProcessedItems, UpdateInfo)
	
	If QueuesToClear.Count() = 0 Then
		Return;
	EndIf;
	
	TablesToReadAndChange = UpdateInfo.TablesToReadAndChange;
	AllReadAndModifiedTables = New Array;
	For Each KeyAndValue In TablesToReadAndChange Do
		CommonClientServer.SupplementArray(AllReadAndModifiedTables, KeyAndValue.Value, True);
	EndDo;
	
	For Each QueueToClear In QueuesToClear Do
		QueueObjects = TablesToReadAndChange[QueueToClear];
		Node = ExchangePlans.InfobaseUpdate.NodeInQueue(QueueToClear);
		For Each FullTableName In AllReadAndModifiedTables Do
			If QueueObjects.Find(FullTableName) <> Undefined Then
				// 
				Continue;
			EndIf;
			
			Object = Common.MetadataObjectByFullName(FullTableName);
			If Object = Undefined Then
				Continue;
			EndIf;
			
			ExchangePlanContent = Metadata.ExchangePlans.InfobaseUpdate.Content;
			If Not ExchangePlanContent.Contains(Object) Then
				Continue;
			EndIf;
			
			ExchangePlans.DeleteChangeRecords(Node, Object);
		EndDo;
		
		ProcessedItems.Add(QueueToClear);
	EndDo;
	
EndProcedure

Function NetHandlerExecutionDuration(HandlerUpdates, ExecutionStatistics)
	
	NetDuration = 0;
	If HandlerUpdates.Multithreaded
		And ExecutionStatistics <> Undefined
		And ExecutionStatistics["HandlerProcedureStart"] <> Undefined
		And TypeOf(ExecutionStatistics["HandlerProcedureStart"]) = Type("Array")
		And ExecutionStatistics["HandlerProcedureCompletion"] <> Undefined
		And TypeOf(ExecutionStatistics["HandlerProcedureCompletion"]) = Type("Array")
		And ExecutionStatistics["HandlerProcedureStart"].Count() = ExecutionStatistics["HandlerProcedureCompletion"].Count() Then
		StartsNumber = ExecutionStatistics["HandlerProcedureStart"].Count();
		DurationsTable = New ValueTable;
		DurationsTable.Columns.Add("Begin");
		DurationsTable.Columns.Add("End");
		
		For Iterator_SSLy = 1 To StartsNumber Do
			DurationsTable.Add();
		EndDo;
		
		DurationsTable.LoadColumn(ExecutionStatistics["HandlerProcedureStart"], "Begin");
		DurationsTable.LoadColumn(ExecutionStatistics["HandlerProcedureCompletion"], "End");
		DurationsTable.Sort("Begin Asc");
		
		CurrentIntervalStart = Undefined;
		CurrentIntervalEnd  = Undefined;
		For Each TableRow In DurationsTable Do
			If Not ValueIsFilled(TableRow.Begin)
				Or Not ValueIsFilled(TableRow.End) Then
				Continue;
			EndIf;
			If CurrentIntervalStart = Undefined Then
				CurrentIntervalStart = TableRow.Begin;
				CurrentIntervalEnd = TableRow.End;
				Continue;
			EndIf;
			
			If TableRow.End < CurrentIntervalEnd Then
				Continue;
			EndIf;
			
			If TableRow.Begin < CurrentIntervalEnd Then
				If TableRow.End > CurrentIntervalEnd Then
					CurrentIntervalEnd = TableRow.End;
				EndIf;
				Continue;
			EndIf;
			
			If TableRow.Begin > CurrentIntervalEnd Then
				NetDuration = NetDuration + (CurrentIntervalEnd - CurrentIntervalStart);
				CurrentIntervalStart = TableRow.Begin;
				CurrentIntervalEnd = TableRow.End;
			EndIf;
		EndDo;
	EndIf;
	
	Return NetDuration * 1000;
	
EndFunction

Procedure WriteProgressProgressHandler(HandlerParameters) Export
	
	If HandlerParameters = Undefined
		Or HandlerParameters.ProcessedObjectsCount1 = 0 Then
		Return;
	EndIf;
	
	CurrentDate = CurrentSessionDate();
	IntervalHour = BegOfHour(CurrentDate);
	
	DataLock = New DataLock;
	DataLockItem = DataLock.Add("InformationRegister.UpdateProgress");
	DataLockItem.SetValue("HandlerName", HandlerParameters.HandlerName);
	DataLockItem.SetValue("RecordKey", HandlerParameters.KeyRecordProgressUpdates);
	DataLockItem.SetValue("IntervalHour", IntervalHour);
	BeginTransaction();
	Try
		DataLock.Lock();
		
		RecordSet = InformationRegisters.UpdateProgress.CreateRecordSet();
		RecordSet.Filter.HandlerName.Set(HandlerParameters.HandlerName);
		RecordSet.Filter.RecordKey.Set(HandlerParameters.KeyRecordProgressUpdates);
		RecordSet.Filter.IntervalHour.Set(IntervalHour);
		RecordSet.Read();
		If RecordSet.Count() = 0 Then
			Record = RecordSet.Add();
			Record.HandlerName = HandlerParameters.HandlerName;
			Record.RecordKey = HandlerParameters.KeyRecordProgressUpdates;
			Record.IntervalHour = IntervalHour;
			Record.ObjectsProcessed = HandlerParameters.ProcessedObjectsCount1;
		Else
			Record = RecordSet[0];
			Record.ObjectsProcessed = Record.ObjectsProcessed + HandlerParameters.ProcessedObjectsCount1;
		EndIf;
		RecordSet.DataExchange.Load = True;
		RecordSet.DataExchange.Recipients.AutoFill = False;
		RecordSet.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// 

Function EditedAttributes(ItemToFill, FullMetadataObjectName)
	
	EditedAttributes = New Array;
	
	If IsIncludesEditedPredefinedAttributes(FullMetadataObjectName) Then
		EditedAttributes = StrSplit(ItemToFill.EditedPredefinedAttributes, ",", False);
	EndIf;
	
	Return EditedAttributes;
	
EndFunction

Function EditableObjectAttributes(MetadataObject, KeyAttributeName)

	ObjectAttributes = New Map;

	AttributesException = New Map;
	AttributesException.Insert("Ref", True);
	AttributesException.Insert("DeletionMark", True);
	AttributesException.Insert("IsFolder", True);
	AttributesException.Insert("Predefined", True);
	AttributesException.Insert("PredefinedDataName", True);
	AttributesException.Insert("KeyAttributeName", True);

	For Each Attribute In MetadataObject.Attributes Do
		ObjectAttributes.Insert(Attribute.Name, True);
	EndDo;

	For Each Attribute In MetadataObject.StandardAttributes Do
		If AttributesException[Attribute.Name] = Undefined Then
			ObjectAttributes.Insert(Attribute.Name, True);
		EndIf;
	EndDo;

	Return ObjectAttributes;

EndFunction

Function KeyAttributeName(DatasetToFill)
	
	KeyAttributeName = DatasetToFill.OverriddenSettings.KeyAttributeName;
	If Not ValueIsFilled(KeyAttributeName) Then
		KeyAttributeName = "PredefinedDataName";
	EndIf;
	
	Return KeyAttributeName;
	
EndFunction

#EndRegion