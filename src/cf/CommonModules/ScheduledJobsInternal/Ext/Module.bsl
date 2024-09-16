///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Checks whether the scheduled task is enabled for functional options.
//
// Parameters:
//  Job - MetadataObjectScheduledJob -  routine task.
//  JobDependencies - ValueTable -  table of dependencies of routine
//    tasks, obtained by the method of routine Tasksservice.Regulationsadjustmentsreferencesfunctionsoptions.
//    If not specified, it is obtained automatically.
//
// Returns:
//  Boolean - 
//
Function ScheduledJobAvailableByFunctionalOptions(Job, JobDependencies = Undefined) Export
	
	If JobDependencies = Undefined Then
		JobDependencies = ScheduledJobsDependentOnFunctionalOptions();
	EndIf;
	
	DisableInSubordinateDIBNode = False;
	DisableInStandaloneWorkplace = False;
	Use                = Undefined;
	IsSubordinateDIBNode        = Common.IsSubordinateDIBNode();
	IsSeparatedMode          = Common.DataSeparationEnabled();
	IsStandaloneWorkplace = Common.IsStandaloneWorkplace();
	
	FoundRows = JobDependencies.FindRows(New Structure("ScheduledJob", Job));
	
	For Each DependencyString In FoundRows Do
		If IsSeparatedMode And DependencyString.AvailableSaaS = False Then
			Return False;
		EndIf;
		
		DisableInSubordinateDIBNode = (DependencyString.AvailableInSubordinateDIBNode = False) And IsSubordinateDIBNode;
		DisableInStandaloneWorkplace = (DependencyString.AvailableAtStandaloneWorkstation = False) And IsStandaloneWorkplace;
		
		If DisableInSubordinateDIBNode Or DisableInStandaloneWorkplace Then
			Return False;
		EndIf;
		
		If DependencyString.FunctionalOption = Undefined Then
			Continue;
		EndIf;
		
		FOValue = GetFunctionalOption(DependencyString.FunctionalOption.Name);
		
		If Use = Undefined Then
			Use = FOValue;
		ElsIf DependencyString.DependenceByT Then
			Use = Use And FOValue;
		Else
			Use = Use Or FOValue;
		EndIf;
	EndDo;
	
	If Use = Undefined Then
		Return True;
	Else
		Return Use;
	EndIf;
	
EndFunction

// Generates a table of dependencies of routine tasks on functional options.
//
// Returns:
//  ValueTable:
//    * ScheduledJob - MetadataObjectScheduledJob -  routine task.
//    * FunctionalOption - MetadataObjectFunctionalOption -  functional option
//        that the scheduled task depends on.
//    * DependenceByT      - Boolean - 
//        
//        
//        
//        
//        
//    * EnableOnEnableFunctionalOption - Boolean
//                                              - Undefined - 
//        
//        
//        
//    * AvailableInSubordinateDIBNode - Boolean
//                                  - Undefined - 
//        
//        
//    * AvailableSaaS      - Boolean
//                                  - Undefined - 
//        
//        
//    * UseExternalResources   - Boolean -  True if the scheduled task works
//        with external resources (receiving mail, syncing data, etc.).
//        by default, it is False.
//
Function ScheduledJobsDependentOnFunctionalOptions() Export
	
	Dependencies = New ValueTable;
	Dependencies.Columns.Add("ScheduledJob");
	Dependencies.Columns.Add("FunctionalOption");
	Dependencies.Columns.Add("DependenceByT", New TypeDescription("Boolean"));
	Dependencies.Columns.Add("AvailableSaaS");
	Dependencies.Columns.Add("AvailableInSubordinateDIBNode");
	Dependencies.Columns.Add("EnableOnEnableFunctionalOption");
	Dependencies.Columns.Add("AvailableAtStandaloneWorkstation");
	Dependencies.Columns.Add("UseExternalResources",  New TypeDescription("Boolean"));
	Dependencies.Columns.Add("IsParameterized",  New TypeDescription("Boolean"));
	
	SSLSubsystemsIntegration.OnDefineScheduledJobSettings(Dependencies);
	ScheduledJobsOverridable.OnDefineScheduledJobSettings(Dependencies);
	
	Dependencies.Sort("ScheduledJob");
	
	Return Dependencies;
	
EndFunction

// Sets the flag for using scheduled tasks in the information database
// , depending on the values of functional options.
//
// Parameters:
//  EnableJobs - Boolean -  if True, disabled scheduled tasks will be enabled
//                             when available by functional options. False by default.
//
Procedure SetScheduledJobsUsageByFunctionalOptions(EnableJobs = False) Export
	
	IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
	IsStandaloneWorkplace = Common.IsStandaloneWorkplace();
	
	DependentScheduledJobs = ScheduledJobsDependentOnFunctionalOptions();
	Jobs = DependentScheduledJobs.Copy(,"ScheduledJob");
	Jobs.GroupBy("ScheduledJob");
	
	For Each RowJob In Jobs Do
		
		Use                    = Undefined;
		DisableJob                 = True;
		DisableInSubordinateDIBNode     = False;
		DisableInStandaloneWorkplace = False;
		
		FoundRows = DependentScheduledJobs.FindRows(New Structure("ScheduledJob", RowJob.ScheduledJob));
		
		For Each DependencyString In FoundRows Do
			DisableInSubordinateDIBNode = (DependencyString.AvailableInSubordinateDIBNode = False) And IsSubordinateDIBNode;
			DisableInStandaloneWorkplace = (DependencyString.AvailableAtStandaloneWorkstation = False) And IsStandaloneWorkplace;
			If DisableInSubordinateDIBNode Or DisableInStandaloneWorkplace Then
				Use = False;
				Break;
			EndIf;
			
			If DependencyString.FunctionalOption = Undefined Then
				Continue;
			EndIf;
			
			FOValue = GetFunctionalOption(DependencyString.FunctionalOption.Name);
			
			If DependencyString.EnableOnEnableFunctionalOption = False Then
				If DisableJob Then
					DisableJob = Not FOValue;
				EndIf;
				FOValue = False;
			EndIf;
			
			If Use = Undefined Then
				Use = FOValue;
			ElsIf DependencyString.DependenceByT Then
				Use = Use And FOValue;
			Else
				Use = Use Or FOValue;
			EndIf;
		EndDo;
		
		If Use = Undefined
			Or (Use And Not EnableJobs) // 
			Or (Not Use And Not DisableJob) Then
			Continue;
		EndIf;
		
		JobsList = ScheduledJobsServer.FindJobs(New Structure("Metadata", RowJob.ScheduledJob));
		For Each ScheduledJob In JobsList Do
			JobParameters = New Structure("Use", Use);
			ScheduledJobsServer.ChangeJob(ScheduledJob, JobParameters);
		EndDo;
		
	EndDo;
	
EndProcedure

// Returns a table of properties for background tasks.
//  For the structure of the table, see the function empty tabletableproperties of background Tasks().
// 
// Parameters:
//  Filter        - Structure - :
//                 
//                  
//
// Returns:
//   See NewBackgroundJobsProperties
//
Function BackgroundJobsProperties(Filter = Undefined) Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	Table = NewBackgroundJobsProperties();
	
	If ValueIsFilled(Filter) And Filter.Property("GetLastScheduledJobBackgroundJob") Then
		Filter.Delete("GetLastScheduledJobBackgroundJob");
		GetLast = True;
	Else
		GetLast = False;
	EndIf;
	
	ScheduledJob = Undefined;
	
	// 
	If ValueIsFilled(Filter) And Filter.Property("ScheduledJobID") Then
		If Filter.ScheduledJobID <> "" Then
			ScheduledJob = ScheduledJobs.FindByUUID(
				New UUID(Filter.ScheduledJobID));
			
			AllBackgroundJobs       = New Array;
			StartedAutomatically = New Array;
			CurrentFilter      = New Structure("Key", Filter.ScheduledJobID);
			StartedManually = BackgroundJobs.GetBackgroundJobs(CurrentFilter);
			
			If ScheduledJob <> Undefined Then
				LastBackgroundJob = ScheduledJob.LastJob;
				CurrentFilter            = New Structure("ScheduledJob", ScheduledJob);
				StartedAutomatically = BackgroundJobs.GetBackgroundJobs(CurrentFilter);
			EndIf;
			
			CommonClientServer.SupplementArray(AllBackgroundJobs, StartedManually);
			CommonClientServer.SupplementArray(AllBackgroundJobs, StartedAutomatically);
			
			If GetLast Then
				LastBackgroundJob = ScheduledJobsServer.LastBackgroundJobInArray(AllBackgroundJobs);
				
				If LastBackgroundJob <> Undefined Then
					BackgroundJobArray = New Array;
					BackgroundJobArray.Add(LastBackgroundJob);
					AddBackgroundJobProperties(BackgroundJobArray, Table);
				EndIf;
				Return Table;
			EndIf;
			AddBackgroundJobProperties(AllBackgroundJobs, Table);
		Else
			BackgroundJobArray = New Array;
			AllScheduledJobIDs = New Map;
			For Each CurrentJob In ScheduledJobs.GetScheduledJobs() Do
				AllScheduledJobIDs.Insert(
					String(CurrentJob.UUID), True);
			EndDo;
			AllBackgroundJobs = BackgroundJobs.GetBackgroundJobs();
			For Each CurrentJob In AllBackgroundJobs Do
				If CurrentJob.ScheduledJob = Undefined
				   And AllScheduledJobIDs[CurrentJob.Key] = Undefined Then
				
					BackgroundJobArray.Add(CurrentJob);
				EndIf;
			EndDo;
			AddBackgroundJobProperties(BackgroundJobArray, Table);
		EndIf;
	Else
		If Not ValueIsFilled(Filter) Then
			BackgroundJobArray = BackgroundJobs.GetBackgroundJobs();
		Else
			If Filter.Property("Id") Then
				Filter.Insert("UUID", New UUID(Filter.Id));
				Filter.Delete("Id");
			EndIf;
			BackgroundJobArray = BackgroundJobs.GetBackgroundJobs(Filter);
			If Filter.Property("UUID") Then
				Filter.Insert("Id", String(Filter.UUID));
				Filter.Delete("UUID");
			EndIf;
		EndIf;
		AddBackgroundJobProperties(BackgroundJobArray, Table);
	EndIf;
	
	If ValueIsFilled(Filter) And Filter.Property("ScheduledJobID") Then
		ScheduledJobsForProcessing = New Array;
		If Filter.ScheduledJobID <> "" Then
			If ScheduledJob = Undefined Then
				ScheduledJob = ScheduledJobs.FindByUUID(
					New UUID(Filter.ScheduledJobID));
			EndIf;
			If ScheduledJob <> Undefined Then
				ScheduledJobsForProcessing.Add(ScheduledJob);
			EndIf;
		EndIf;
	Else
		ScheduledJobsForProcessing = ScheduledJobs.GetScheduledJobs();
	EndIf;
	
	Table.Sort("Begin Desc, End Desc");
	
	// 
	If ValueIsFilled(Filter) Then
		Begin    = Undefined;
		End     = Undefined;
		State = Undefined;
		If Filter.Property("Begin") Then
			Begin = ?(ValueIsFilled(Filter.Begin), Filter.Begin, Undefined);
			Filter.Delete("Begin");
		EndIf;
		If Filter.Property("End") Then
			End = ?(ValueIsFilled(Filter.End), Filter.End, Undefined);
			Filter.Delete("End");
		EndIf;
		If Filter.Property("State") Then
			If TypeOf(Filter.State) = Type("Array") Then
				State = Filter.State;
				Filter.Delete("State");
			EndIf;
		EndIf;
		
		If Filter.Count() <> 0 Then
			Rows = Table.FindRows(Filter);
		Else
			Rows = Table;
		EndIf;
		// 
		ItemNumber = Rows.Count() - 1;
		While ItemNumber >= 0 Do
			If Begin    <> Undefined And Begin > Rows[ItemNumber].Begin
				Or End     <> Undefined And End  < ?(ValueIsFilled(Rows[ItemNumber].End), Rows[ItemNumber].End, CurrentSessionDate())
				Or State <> Undefined And State.Find(Rows[ItemNumber].State) = Undefined Then
				Rows.Delete(ItemNumber);
			EndIf;
			ItemNumber = ItemNumber - 1;
		EndDo;
		// 
		If TypeOf(Rows) = Type("Array") Then
			LineNumber = Table.Count() - 1;
			While LineNumber >= 0 Do
				If Rows.Find(Table[LineNumber]) = Undefined Then
					Table.Delete(Table[LineNumber]);
				EndIf;
				LineNumber = LineNumber - 1;
			EndDo;
		EndIf;
	EndIf;
	
	Return Table;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// The procedure enables / disables routine tasks created in the is
// when the functional option is changed.
//
// Parameters:
//  Source - ConstantValueManager -  constant for storing the FO value.
//  Cancel    - Boolean -  failure to write a constant.
//
Procedure EnableScheduledJobOnChangeFunctionalOption(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	ChangeScheduledJobsUsageByFunctionalOptions(Source, Source.Value);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See ExportImportDataOverridable.AfterImportData.
Procedure AfterImportData(Container) Export
	
	ExternalResourcesOperationsLock.AfterImportData(Container);
	
EndProcedure

// See SaaSOperationsOverridable.OnFillIIBParametersTable.
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleSaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "MaxActiveBackgroundJobExecutionTime");
		ModuleSaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "MaxActiveBackgroundJobCount");
	EndIf;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "2.3.3.12";
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "ExternalResourcesOperationsLock.UpdateExternalResourceAccessLockParameters";
	
EndProcedure

// See DataExchangeOverridable.OnSetUpSubordinateDIBNode.
Procedure OnSetUpSubordinateDIBNode() Export
	
	SetScheduledJobsUsageByFunctionalOptions();
	
EndProcedure

#EndRegion

#Region Private

Function SettingValue(SettingName) Export
	
	Settings = DefaultSettings();
	ScheduledJobsOverridable.OnDefineSettings(Settings);
	
	Return Settings[SettingName];
	
EndFunction

// Contains the default settings.
//
// Returns:
//  Structure:
//    * UnlockCommandPlacement - String -  determines the location of the command to remove
//                                                     the lock on working with external resources.
//
Function DefaultSettings()
	
	SubsystemSettings = New Structure;
	SubsystemSettings.Insert("UnlockCommandPlacement",
		NStr("en = 'You can release the lock later in <b>Administration > Support and service</b>.';"));
	
	Return SubsystemSettings;
	
EndFunction

// Throws an exception if the user does not have administrative rights.
Procedure RaiseIfNoAdministrationRights() Export
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		If Not Users.IsFullUser() Then
			Raise NStr("en = 'Access violation.';");
		EndIf;
	Else
		If Not PrivilegedMode() Then
			VerifyAccessRights("Administration", Metadata);
		EndIf;
	EndIf;
	
EndProcedure


// Parameters:
//  Parameters - Structure:
//     * Table - ValueTable:
//          ** Id - String
//          ** Predefined - Boolean
//          ** Key - String
//          ** Description - String
//          ** Use - Boolean
//          ** Schedule - String
//          ** RestartIntervalOnFailure - Number
//          ** RestartCountOnFailure - String
//          ** LastBackgroundJobUUID - String
//          ** ExecutionState - String
//          ** EndDate - String
//          ** UserName - String
//          ** JobName - String
//          ** Parameterized - Boolean
//          ** StartDate - String
//  StorageAddress - String
//
Procedure GenerateScheduledJobsTable(Parameters, StorageAddress) Export
	
	ScheduledJobID = Parameters.ScheduledJobID;
	Table                           = Parameters.Table;
	DisabledJobs                = Parameters.DisabledJobs;
	
	// 
	CurrentJobs = ScheduledJobs.GetScheduledJobs();
	DisabledJobs.Clear();
	
	ScheduledJobsParameters = ScheduledJobsDependentOnFunctionalOptions();
	FilterParameters        = New Structure;
	ParameterizedJobs = New Array;
	FilterParameters.Insert("IsParameterized", True);
	SearchResult = ScheduledJobsParameters.FindRows(FilterParameters);
	For Each ResultString1 In SearchResult Do
		ParameterizedJobs.Add(ResultString1.ScheduledJob);
	EndDo;
	
	SubsystemSaaSOperations = Metadata.Subsystems.StandardSubsystems.Subsystems.Find("SaaSOperations");
	For Each MetadataObject In Metadata.ScheduledJobs Do
		If Not ScheduledJobAvailableByFunctionalOptions(MetadataObject, ScheduledJobsParameters) Then
			DisabledJobs.Add(MetadataObject.Name);
			Continue;
		EndIf;
		
		If Not Common.DataSeparationEnabled()
			And SubsystemSaaSOperations <> Undefined Then
			
			JobParameters = ScheduledJobsParameters.Find(MetadataObject, "ScheduledJob");
			
			If JobParameters <> Undefined
				And Common.IsStandaloneWorkplace()
				And JobParameters.AvailableAtStandaloneWorkstation = True Then
				Continue;
			EndIf;
			
			If SubsystemSaaSOperations.Content.Contains(MetadataObject) Then
				DisabledJobs.Add(MetadataObject.Name);
				Continue;
			EndIf;
			
			For Each Subsystem In SubsystemSaaSOperations.Subsystems Do
				If Subsystem.Content.Contains(MetadataObject) Then
					DisabledJobs.Add(MetadataObject.Name);
					Continue;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	If ScheduledJobID = Undefined Then
		
		IndexOf = 0;
		For Each Job In CurrentJobs Do
			
			Id = String(Job.UUID);
			
			If IndexOf >= Table.Count() Or Table[IndexOf].Id <> Id Then
				
				// 
				ToUpdate = Table.Insert(IndexOf);
				
				// 
				ToUpdate.Id = Id;
			Else
				ToUpdate = Table[IndexOf];
			EndIf;
			
			If ParameterizedJobs.Find(Job.Metadata) <> Undefined Then
				ToUpdate.Parameterized = True;
			EndIf;
			
			SetScheduledJobProperties(ToUpdate, Job);
			IndexOf = IndexOf + 1;
		EndDo;
	
		// 
		While IndexOf < Table.Count() Do
			Table.Delete(IndexOf);
		EndDo;
		Table.Sort("Description");
	Else
		Job = ScheduledJobs.FindByUUID(
			New UUID(ScheduledJobID));
		
		Rows = Table.FindRows(
			New Structure("Id", ScheduledJobID));
		
		If Job <> Undefined
		   And Rows.Count() > 0 Then
			
			RowJob = Rows[0];
			If ParameterizedJobs.Find(Job.Metadata) <> Undefined Then
				RowJob.Parameterized = True;
			EndIf;
			SetScheduledJobProperties(RowJob, Job);
		EndIf;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Table", Table);
	Result.Insert("DisabledJobs", DisabledJobs);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Procedure SetScheduledJobProperties(Receiver, JobSource)
	
	FillPropertyValues(Receiver, JobSource);
	
	// 
	Receiver.Description = ScheduledJobPresentation(JobSource);
	
	// 
	LastBackgroundJobProperties = LastBackgroundJobScheduledJobExecutionProperties(JobSource);
	
	Receiver.JobName = JobSource.Metadata.Name;
	If LastBackgroundJobProperties = Undefined Then
		Receiver.StartDate          = TextUndefined();
		Receiver.EndDate       = TextUndefined();
		Receiver.ExecutionState = TextUndefined();
	Else
		Receiver.StartDate          = ?(ValueIsFilled(LastBackgroundJobProperties.Begin),
		                               LastBackgroundJobProperties.Begin,
		                               "<>");
		Receiver.EndDate       = ?(ValueIsFilled(LastBackgroundJobProperties.End),
		                               LastBackgroundJobProperties.End,
		                               "<>");
		Receiver.ExecutionState = LastBackgroundJobProperties.State;
	EndIf;
		
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// It is intended for" manual " immediate execution of the routine task procedure
// either in the client session (in the file is), or in the background task on the server (in the server is).
// It is used in any connection mode.
// Manual start mode does not affect the scheduled task execution on the emergency
// and main schedules, because the reference to the scheduled task is not specified for the background task.
// The background Task type does not allow setting such a link, so
// the same rule applies for file mode.
// 
// Parameters:
//  Job             - ScheduledJob
//                      - String - 
//
// Returns:
//  Structure:
//    * StartedAt -   Undefined
//                    -   Date - 
//                        
//                        
//    * BackgroundJobIdentifier - String -  returns the ID of the running background task for the server is.
//
Function ExecuteScheduledJobManually(Val Job) Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	ExecutionParameters = ScheduledJobExecutionParameters();
	ExecutionParameters.ProcedureAlreadyExecuting = False;
	Job = ScheduledJobsServer.GetScheduledJob(Job);
	
	ExecutionParameters.Started1 = False;
	LastBackgroundJobProperties = LastBackgroundJobScheduledJobExecutionProperties(Job);
	
	If LastBackgroundJobProperties <> Undefined
	   And LastBackgroundJobProperties.State = BackgroundJobState.Active Then
		
		ExecutionParameters.StartedAt  = LastBackgroundJobProperties.Begin;
		If ValueIsFilled(LastBackgroundJobProperties.Description) Then
			ExecutionParameters.BackgroundJobPresentation = LastBackgroundJobProperties.Description;
		Else
			ExecutionParameters.BackgroundJobPresentation = ScheduledJobPresentation(Job);
		EndIf;
	Else
		BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Manual start: %1';"), ScheduledJobPresentation(Job));
		// 
		BackgroundJob = ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(Job.Metadata.MethodName, Job.Parameters, String(Job.UUID), BackgroundJobDescription);
		ExecutionParameters.BackgroundJobIdentifier = String(BackgroundJob.UUID);
		ExecutionParameters.StartedAt = BackgroundJobs.FindByUUID(BackgroundJob.UUID).Begin;
		ExecutionParameters.Started1 = True;
	EndIf;
	
	ExecutionParameters.ProcedureAlreadyExecuting = Not ExecutionParameters.Started1;
	Return ExecutionParameters;
	
EndFunction

Function ScheduledJobExecutionParameters() 
	
	Result = New Structure;
	Result.Insert("StartedAt");
	Result.Insert("BackgroundJobIdentifier");
	Result.Insert("BackgroundJobPresentation");
	Result.Insert("ProcedureAlreadyExecuting");
	Result.Insert("Started1");
	Return Result;
	
EndFunction

// Returns a view of the routine task,
// this is in order of excluding blank details:
// Name, Metadata.Synonym, Metadata. Name.
//
// Parameters:
//  Job      - ScheduledJob
//               - String - 
//
// Returns:
//  String
//
Function ScheduledJobPresentation(Val Job) Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	If TypeOf(Job) = Type("ScheduledJob") Then
		ScheduledJob = Job;
	Else
		ScheduledJob = ScheduledJobs.FindByUUID(New UUID(Job));
	EndIf;
	
	If ScheduledJob <> Undefined Then
		If ScheduledJob.Predefined Then
			Presentation = ScheduledJob.Metadata.Synonym;
		Else
			Presentation = ScheduledJob.Description;
			
			If IsBlankString(ScheduledJob.Description) Then
				Presentation = ScheduledJob.Metadata.Synonym;
			EndIf;
		EndIf;
		If IsBlankString(Presentation) Then
			Presentation = ScheduledJob.Metadata.Name;
		EndIf
	Else
		Presentation = TextUndefined();
	EndIf;
	
	Return Presentation;
	
EndFunction

// Returns the text "<undefined>".
Function TextUndefined() Export
	
	Return NStr("en = '<not defined>';");
	
EndFunction

// Returns a multi-line String containing Messages and error Descriptioninformation,
// the last background task was found by the routine task ID
// , and there are messages/errors.
//
// Parameters:
//  Job      - ScheduledJob
//               - String - 
//                 
//
// Returns:
//  String
//
Function ScheduledJobMessagesAndErrorDescriptions(Val Job) Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);

	ScheduledJobID = ?(TypeOf(Job) = Type("ScheduledJob"), String(Job.UUID), Job);
	LastBackgroundJobProperties = LastBackgroundJobScheduledJobExecutionProperties(ScheduledJobID);
	Return ?(LastBackgroundJobProperties = Undefined,
	          "",
	          BackgroundJobMessagesAndErrorDescriptions(LastBackgroundJobProperties.Id));
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Cancels a background task if possible, namely, if it is running on the server and is active.
//
// Parameters:
//  Id  - 
// 
Procedure CancelBackgroundJob(Id) Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	NewUUID = New UUID(Id);
	Filter = New Structure;
	Filter.Insert("UUID", NewUUID);
	BackgroundJobArray = BackgroundJobs.GetBackgroundJobs(Filter);
	If BackgroundJobArray.Count() = 1 Then
		BackgroundJob = BackgroundJobArray[0];
	Else
		Raise NStr("en = 'The background job does not exist.';");
	EndIf;
	
	If BackgroundJob.State <> BackgroundJobState.Active Then
		Raise NStr("en = 'The job is not running. It cannot be canceled.';");
	EndIf;
	
	BackgroundJob.Cancel();
	
EndProcedure

// For internal use only.
//
Procedure FillBackgroundJobsPropertiesTableInBackground(Parameters, StorageAddress) Export
	
	PropertiesTable = BackgroundJobsProperties(Parameters.Filter);
	
	Result = New Structure;
	Result.Insert("PropertiesTable", PropertiesTable);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

// Returns the background Task properties based on a unique ID string.
//
// Parameters:
//  Id - String - 
//  PropertiesNames  - String -  if filled in, the structure with the specified properties is returned.
// 
// Returns:
//  ValueTableRow, Structure - 
//
Function GetBackgroundJobProperties(Id, PropertiesNames = "") Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	Filter = New Structure("Id", Id);
	BackgroundJobPropertyTable = BackgroundJobsProperties(Filter);
	
	If BackgroundJobPropertyTable.Count() > 0 Then
		If ValueIsFilled(PropertiesNames) Then
			Result = New Structure(PropertiesNames);
			FillPropertyValues(Result, BackgroundJobPropertyTable[0]);
		Else
			Result = BackgroundJobPropertyTable[0];
		EndIf;
	Else
		Result = Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the properties of the last background task that was executed when the scheduled task was executed, if any.
// The procedure works in both file-server and client-server modes.
//
// Parameters:
//  ScheduledJob - ScheduledJob
//                      - String - 
//
// Returns:
//  ValueTableRow:
//     * Id - String
//     * Description - String
//     * Key - String
//     * End - Date
//     * ScheduledJobID - String
//     * State - BackgroundJobState
//     * MethodName - String
//     * Placement - String
//     * ErrorDetailsDescription - String
//     * StartAttempt - Number
//     * UserMessages - Array
//     * SessionNumber - Number
//     * SessionStarted - Date
//
Function LastBackgroundJobScheduledJobExecutionProperties(ScheduledJob)
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	ScheduledJobID = ?(TypeOf(ScheduledJob) = Type("ScheduledJob"), String(ScheduledJob.UUID), ScheduledJob);
	Filter = New Structure;
	Filter.Insert("ScheduledJobID", ScheduledJobID);
	Filter.Insert("GetLastScheduledJobBackgroundJob");
	BackgroundJobPropertyTable = BackgroundJobsProperties(Filter);
	BackgroundJobPropertyTable.Sort("End Asc");
	
	If BackgroundJobPropertyTable.Count() = 0 Then
		BackgroundJobProperties = Undefined;
	ElsIf Not ValueIsFilled(BackgroundJobPropertyTable[0].End) Then
		BackgroundJobProperties = BackgroundJobPropertyTable[0];
	Else
		BackgroundJobProperties = BackgroundJobPropertyTable[BackgroundJobPropertyTable.Count()-1];
	EndIf;
	
	Return BackgroundJobProperties;
	
EndFunction

// Returns a multi-line String containing Messages and error Descriptioninformation,
// if the background task was found by ID and there are messages/errors.
//
// Parameters:
//  Task      - String-Unique identifier of the background Task by string.
//
// Returns:
//  String
//
Function BackgroundJobMessagesAndErrorDescriptions(Id, BackgroundJobProperties = Undefined) Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	If BackgroundJobProperties = Undefined Then
		BackgroundJobProperties = GetBackgroundJobProperties(Id);
	EndIf;
	
	String = "";
	If BackgroundJobProperties <> Undefined Then
		For Each Message In BackgroundJobProperties.UserMessages Do
			String = String + ?(String = "",
			                    "",
			                    "
			                    |
			                    |") + Message.Text;
		EndDo;
		If ValueIsFilled(BackgroundJobProperties.ErrorDetailsDescription) Then
			String = String + ?(String = "",
			                    BackgroundJobProperties.ErrorDetailsDescription,
			                    "
			                    |
			                    |" + BackgroundJobProperties.ErrorDetailsDescription);
		EndIf;
	EndIf;
	
	Return String;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Procedure ChangeScheduledJobsUsageByFunctionalOptions(Source, Val Use)
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	SourceType = TypeOf(Source);
	FOStorage = Metadata.FindByType(SourceType);
	FunctionalOption = Undefined;
	IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
	IsStandaloneWorkplace = Common.IsStandaloneWorkplace();
	
	DependentScheduledJobs = ScheduledJobsDependentOnFunctionalOptions();
	
	FOList = DependentScheduledJobs.Copy(,"FunctionalOption");
	FOList.GroupBy("FunctionalOption");
	
	For Each FOString In FOList Do
		
		If FOString.FunctionalOption = Undefined Then
			Continue;
		EndIf;
		
		If FOString.FunctionalOption.Location = FOStorage Then
			FunctionalOption = FOString.FunctionalOption; // MetadataObjectFunctionalOption
			Break;
		EndIf;
		
	EndDo;
	
	If FunctionalOption = Undefined
		Or GetFunctionalOption(FunctionalOption.Name) = Use Then
		Return;
	EndIf;
	
	Jobs = DependentScheduledJobs.Copy(New Structure("FunctionalOption", FunctionalOption) ,"ScheduledJob");
	Jobs.GroupBy("ScheduledJob");
	
	For Each RowJob In Jobs Do
		
		UsageByFO                = Undefined;
		DisableJob                 = True;
		DisableInSubordinateDIBNode     = False;
		DisableInStandaloneWorkplace = False;
		
		FoundRows = DependentScheduledJobs.FindRows(New Structure("ScheduledJob", RowJob.ScheduledJob));
		
		For Each DependencyString In FoundRows Do
			DisableInSubordinateDIBNode = (DependencyString.AvailableInSubordinateDIBNode = False) And IsSubordinateDIBNode;
			DisableInStandaloneWorkplace = (DependencyString.AvailableAtStandaloneWorkstation = False) And IsStandaloneWorkplace;
			If DisableInSubordinateDIBNode Or DisableInStandaloneWorkplace Then
				Break;
			EndIf;
			
			If DependencyString.FunctionalOption = Undefined Then
				Continue;
			EndIf;
			
			If DependencyString.FunctionalOption = FunctionalOption Then
				FOValue = Use;
			Else
				FOValue = GetFunctionalOption(DependencyString.FunctionalOption.Name);
			EndIf;
			
			If DependencyString.EnableOnEnableFunctionalOption = False Then
				If DisableJob Then
					DisableJob = Not FOValue;
				EndIf;
				FOValue = False;
			EndIf;
			
			If UsageByFO = Undefined Then
				UsageByFO = FOValue;
			ElsIf DependencyString.DependenceByT Then
				UsageByFO = UsageByFO And FOValue;
			Else
				UsageByFO = UsageByFO Or FOValue;
			EndIf;
		EndDo;
		
		If DisableInSubordinateDIBNode Or DisableInStandaloneWorkplace Then
			Use = False;
		Else
			If Use <> UsageByFO Then
				Continue;
			EndIf;
			
			If Not Use And Not DisableJob Then
				Continue;
			EndIf;
		EndIf;
		
		JobsList = ScheduledJobsServer.FindJobs(New Structure("Metadata", RowJob.ScheduledJob));
		For Each ScheduledJob In JobsList Do
			JobParameters = New Structure("Use", Use);
			ScheduledJobsServer.ChangeJob(ScheduledJob, JobParameters);
		EndDo;
		
	EndDo;
	
EndProcedure

// Returns a new table of background task properties.
//
// Returns:
//  ValueTable:
//     * Id - String
//     * Description - String
//     * Key - String
//     * End - Date
//     * ScheduledJobID - String
//     * State - BackgroundJobState
//     * MethodName - String
//     * Placement - String
//     * ErrorDetailsDescription - String
//     * StartAttempt - Number
//     * UserMessages - Array
//     * SessionNumber - Number
//     * SessionStarted - Date
//
Function NewBackgroundJobsProperties()
	
	NewTable = New ValueTable;
	NewTable.Columns.Add("Id",                     New TypeDescription("String"));
	NewTable.Columns.Add("Description",                      New TypeDescription("String"));
	NewTable.Columns.Add("Key",                              New TypeDescription("String"));
	NewTable.Columns.Add("Begin",                            New TypeDescription("Date"));
	NewTable.Columns.Add("End",                             New TypeDescription("Date"));
	NewTable.Columns.Add("ScheduledJobID", New TypeDescription("String"));
	NewTable.Columns.Add("State",                         New TypeDescription("BackgroundJobState"));
	NewTable.Columns.Add("MethodName",                         New TypeDescription("String"));
	NewTable.Columns.Add("Placement",                      New TypeDescription("String"));
	NewTable.Columns.Add("ErrorDetailsDescription",        New TypeDescription("String"));
	NewTable.Columns.Add("StartAttempt",                    New TypeDescription("Number"));
	NewTable.Columns.Add("UserMessages",             New TypeDescription("Array"));
	NewTable.Columns.Add("SessionNumber",                       New TypeDescription("Number"));
	NewTable.Columns.Add("SessionStarted",                      New TypeDescription("Date"));
	NewTable.Indexes.Add("Id, Begin");
	
	Return NewTable;
	
EndFunction

Procedure AddBackgroundJobProperties(Val BackgroundJobArray, Val BackgroundJobPropertyTable)
	
	IndexOf = BackgroundJobArray.Count() - 1;
	While IndexOf >= 0 Do
		BackgroundJob = BackgroundJobArray[IndexOf]; // BackgroundJob
		String = BackgroundJobPropertyTable.Add();
		FillPropertyValues(String, BackgroundJob);
		String.Id = BackgroundJob.UUID;
		ScheduledJob = BackgroundJob.ScheduledJob;
		
		If ScheduledJob = Undefined
		   And StringFunctionsClientServer.IsUUID(BackgroundJob.Key) Then
			
			ScheduledJob = ScheduledJobs.FindByUUID(New UUID(BackgroundJob.Key));
		EndIf;
		String.ScheduledJobID = ?(
			ScheduledJob = Undefined,
			"",
			ScheduledJob.UUID);
		
		String.ErrorDetailsDescription = ?(
			BackgroundJob.ErrorInfo = Undefined,
			"",
			ErrorProcessing.DetailErrorDescription(BackgroundJob.ErrorInfo));
		
		IndexOf = IndexOf - 1;
	EndDo;
	
EndProcedure

#EndRegion
