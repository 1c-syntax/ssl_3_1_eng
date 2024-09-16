///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// 
// 
// 
//
// Parameters:
//  Filter - Structure - : 
//          
//             * UUID - UUID -  id of the scheduled task in local
//                                         operation mode or ID of the queue task link in the service model.
//                                       - String - 
//                                         
//                                       - CatalogRef.JobsQueue - 
//                                            
//                                       - ValueTableRow of See FindJobs
//             * Metadata              - MetadataObjectScheduledJob -  metadata of a routine task.
//                                       - String - 
//             * Use           - Boolean -  if True, the task is enabled.
//             * Key                    - String - 
//          :
//             * Description            - String -  name of the routine task.
//             * Predefined        - Boolean - 
//          :
//             * MethodName               - String -  name of the method (or alias) of the task queue handler.
//             * DataArea           - Number -  value of the task data area separator.
//             * JobState        - EnumRef.JobsStates -  status of the queue job.
//             * Template                  - CatalogRef.QueueJobTemplates -  the job template is only used
//                                            for the split of jobs in the queue.
//
// Returns:
//     Array of ScheduledJob - 
//     :
//        * Use                - Boolean -  if True, the task is enabled.
//        * Key                         - String -  application ID of the task.
//        * Parameters                    - Array -  parameters passed to the task handler.
//        * Schedule                   - JobSchedule -  the job schedule.
//        * UUID      - CatalogRef.JobsQueue - 
//                                            
//        * ScheduledStartTime - Date -  date and time of the scheduled task launch
//                                         (in the time zone of the data area).
//        * MethodName                    - String -  name of the method (or alias) of the task queue handler.
//        * DataArea                - Number -  value of the task data area separator.
//        * JobState             - EnumRef.JobsStates -  status of the queue job.
//        * Template                       - CatalogRef.QueueJobTemplates -  a job template,
//                                            is only used to split the jobs in the queue.
//        * ExclusiveExecution       - Boolean -  if this flag is set, the task will be executed 
//                                                  even if the session start lock is set in
//                                                  the data area. Also, if there are tasks with this flag in the area
//                                                  , they will be executed first.
//        * RestartIntervalOnFailure - Number -  the interval in seconds after which
//                                                          the task should be restarted if it crashes.
//        * RestartCountOnFailure - Number -  the number of repetitions when the task crashes.
//
Function FindJobs(Filter) Export
	
	RaiseIfNoAdministrationRights();
	
	FilterCopy = Common.CopyRecursive(Filter); // See FindJobs.Filter
	
	If Common.DataSeparationEnabled() Then
		
		If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
			
			If FilterCopy.Property("UUID") Then
				If Not FilterCopy.Property("Id") Then
					FilterCopy.Insert("Id", FilterCopy.UUID);
				EndIf;
				FilterCopy.Delete("UUID");
			EndIf;
			
			If Common.SeparatedDataUsageAvailable() Then
				// 
				ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
				// 
				DataArea = ModuleSaaSOperations.SessionSeparatorValue();
				FilterCopy.Insert("DataArea", DataArea);
			EndIf;
			
			ModuleJobsQueue  = Common.CommonModule("JobsQueue");
			
			If FilterCopy.Property("Metadata") Then
				If TypeOf(FilterCopy.Metadata) = Type("MetadataObject") Then
					MetadataScheduledJob = FilterCopy.Metadata;
				Else
					MetadataScheduledJob = Metadata.ScheduledJobs.Find(FilterCopy.Metadata);
				EndIf;
				FilterCopy.Delete("Metadata");
				FilterCopy.Delete("MethodName");
				FilterCopy.Delete("Template");
				If MetadataScheduledJob <> Undefined Then
					QueueJobTemplates = StandardSubsystemsCached.QueueJobTemplates();
					If QueueJobTemplates.Get(MetadataScheduledJob.Name) <> Undefined Then
						SetPrivilegedMode(True);
						Template = ModuleJobsQueue.TemplateByName_(MetadataScheduledJob.Name);
						SetPrivilegedMode(False);
						FilterCopy.Insert("Template", Template);
					Else
						FilterCopy.Insert("MethodName", MetadataScheduledJob.MethodName);
					EndIf;
				Else
					FilterCopy.Insert("MethodName", String(New UUID));
				EndIf;
			ElsIf FilterCopy.Property("Id") Then
				If TypeOf(FilterCopy.Id) = Type("String") Then
					FilterCopy.Id = New UUID(FilterCopy.Id);
				EndIf;
				If TypeOf(FilterCopy.Id) = Type("UUID") Then
					FilterCopy.Id = QueueJobLink(FilterCopy.Id, FilterCopy);
				ElsIf TypeOf(FilterCopy.Id) = Type("ValueTableRow") Then
					FilterCopy.Id = FilterCopy.Id.Id;
				EndIf;
			EndIf;
			
			Return UpdatedTaskList(ModuleJobsQueue.GetJobs(FilterCopy));
			
		EndIf;
	Else
		
		JobsList = ScheduledJobs.GetScheduledJobs(FilterCopy);
		
		Return JobsList;
		
	EndIf;
	
EndFunction

// Returns a task from the queue or routine.
//
// Parameters:
//  Id - MetadataObject -  a scheduled task metadata object for searching
//                                     for a predefined scheduled task.
//                - String - 
//                           
//                           
//                - UUID - 
//                           
//                - ScheduledJob - 
//                           
//                - CatalogRef.JobsQueue - 
//                - ValueTableRow of See FindJobs
// 
// Returns:
//  ScheduledJob - 
//   See FindJobs
//  
//
Function Job(Val Id) Export
	
	RaiseIfNoAdministrationRights();
	
	Id = UpdatedTaskID(Id);
	ScheduledJob = Undefined;
	
	If Common.DataSeparationEnabled() Then
		
		If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
			Filter = ?(TypeOf(Id) = Type("MetadataObject"),
				New Structure("Metadata", Id),
				New Structure("UUID", Id));
			
			JobsList = FindJobs(Filter);
			For Each Job In JobsList Do
				ScheduledJob = Job;
				Break;
			EndDo;
		EndIf;
		
	Else
		
		If TypeOf(Id) = Type("MetadataObject") Then
			If Id.Predefined Then
				ScheduledJob = ScheduledJobs.FindPredefined(Id);
			Else
				JobsList = ScheduledJobs.GetScheduledJobs(New Structure("Metadata", Id));
				If JobsList.Count() > 0 Then
					ScheduledJob = JobsList[0];
				EndIf;
			EndIf; 
		Else
			ScheduledJob = ScheduledJobs.FindByUUID(Id);
		EndIf;
	EndIf;
	
	Return ScheduledJob;
	
EndFunction

// Adds a new task to the queue or routine.
// 
// Parameters: 
//  Parameters - Structure - :
//   * Use - Boolean -  True if the scheduled task should be performed automatically according to the schedule. 
//   * Metadata    - MetadataObjectScheduledJob -  be sure to specify. The metadata object 
//                              that will be used to create the routine task.
//   * Parameters     - Array -  parameters of the routine task. The number and composition of parameters must correspond 
//                              to the parameters of the routine task method.
//   * Key          - String -  application ID of the scheduled task.
//   * RestartIntervalOnFailure - Number -  the interval in seconds after which the task should be restarted 
//                              in case of an emergency.
//   * Schedule    - JobSchedule -  the job schedule.
//   * RestartCountOnFailure - Number -  the number of repetitions when the task crashes.
//
// Returns:
//  ScheduledJob - 
//   See FindJobs
// 
Function AddJob(Parameters) Export
	
	RaiseIfNoAdministrationRights();
	
	If Common.DataSeparationEnabled() Then
		
		If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
			
			JobParameters = Common.CopyRecursive(Parameters);
			
			If Common.SeparatedDataUsageAvailable() Then
				// 
				ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
				// 
				DataArea = ModuleSaaSOperations.SessionSeparatorValue();
				JobParameters.Insert("DataArea", DataArea);
			EndIf;
			
			JobMetadata = JobParameters.Metadata;
			MethodName = JobMetadata.MethodName;
			JobParameters.Insert("MethodName", MethodName);
			
			JobParameters.Delete("Metadata");
			JobParameters.Delete("Description");
			
			ModuleJobsQueue = Common.CommonModule("JobsQueue");
			Job = ModuleJobsQueue.AddJob(JobParameters);
			Filter = New Structure("Id", Job);
			JobsList = UpdatedTaskList(ModuleJobsQueue.GetJobs(Filter));
			For Each Job In JobsList Do
				Return Job;
			EndDo;
			
		EndIf;
		
	Else
		Job = AddARoutineTask(Parameters);
	EndIf;
	
	Return Job;
	
EndFunction

// Deletes a task from the queue or routine.
//
// Parameters:
//  Id - MetadataObject -  a routine task metadata object for searching
//                                     for an undefined routine task.
//                - String - 
//                           
//                           
//                - UUID - 
//                           
//                - ScheduledJob -  
//                  
//                - CatalogRef.JobsQueue - 
//                - ValueTableRow of See FindJobs
//
Procedure DeleteJob(Val Id) Export
	
	RaiseIfNoAdministrationRights();
	
	Id = UpdatedTaskID(Id);
	
	If Common.DataSeparationEnabled() Then
		If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
			If TypeOf(Id) = Type("ValueTableRow") Then
				JobsList = CommonClientServer.ValueInArray(Id);
			Else
				Filter = ?(TypeOf(Id) = Type("MetadataObject"),
					New Structure("MethodName", Id.MethodName),
					New Structure("UUID", Id));
				JobsList = FindJobs(Filter);
			EndIf;
			ModuleJobsQueue = Common.CommonModule("JobsQueue");
			For Each Job In JobsList Do
				ModuleJobsQueue.DeleteJob(Job.Id);
			EndDo;
		EndIf;
	Else
		DeleteScheduledJob(Id);
	EndIf;
	
EndProcedure

// Modifies a queue task or a routine one.
//
// In the service model (separation is enabled):
// - in case of a call in a transaction, an object lock is set for a task,
// - if the task is created based on a template or predefined,
// only the Use property can be specified in the Parameters parameter. In this case, the schedule
// cannot be changed, because it is stored centrally in an undivided task Template,
// it is not stored separately for each area.
// 
// Parameters: 
//  Id - MetadataObject - 
//                - String - 
//                           
//                           
//                - UUID - 
//                           
//                - ScheduledJob - 
//                - CatalogRef.JobsQueue - 
//                - ValueTableRow of See FindJobs
//
//  Parameters - Structure - :
//   * Use - Boolean -  True if the scheduled task should be performed automatically according to the schedule.
//   * Parameters     - Array -  parameters of the routine task. The number and composition of parameters must correspond
//                              to the parameters of the routine task method.
//   * Key          - String -  application ID of the scheduled task.
//   * RestartIntervalOnFailure - Number -  the interval in seconds after which the task should be restarted
//                              in case of an emergency.
//   * Schedule    - JobSchedule -  the job schedule.
//   * RestartCountOnFailure - Number -  the number of repetitions when the task crashes.
//   
Procedure ChangeJob(Val Id, Val Parameters) Export
	
	RaiseIfNoAdministrationRights();
	
	Id = UpdatedTaskID(Id);
	
	If Common.DataSeparationEnabled() Then
		If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
			JobParameters = Common.CopyRecursive(Parameters);
			JobParameters.Delete("Description");
			If JobParameters.Count() = 0 Then
				Return;
			EndIf;
			
			If TypeOf(Id) = Type("ValueTableRow") Then
				JobsList = CommonClientServer.ValueInArray(Id);
			Else
				Filter = ?(TypeOf(Id) = Type("MetadataObject"),
					New Structure("Metadata", Id),
					New Structure("UUID", Id));
				JobsList = FindJobs(Filter);
			EndIf;
			
			// 
			// 
			PredefinedJobParameters = New Structure;
			If JobParameters.Property("Use") Then
				PredefinedJobParameters.Insert("Use",
					JobParameters.Use);
			EndIf;
			
			ModuleJobsQueue = Common.CommonModule("JobsQueue");
			For Each Job In JobsList Do
				If Not ValueIsFilled(Job.Template) Then
					ModuleJobsQueue.ChangeJob(Job.Id, JobParameters);
				ElsIf ValueIsFilled(PredefinedJobParameters) Then
					ModuleJobsQueue.ChangeJob(Job.Id, PredefinedJobParameters);
				EndIf;
			EndDo;
		EndIf;
	Else
		ChangeScheduledJob(Id, Parameters);
	EndIf;
	
EndProcedure

// Returns the unique ID of a queued or scheduled task.
// The call requires administrative rights or install a privileged mode.
//
// Parameters:
//  Id - MetadataObject -  a scheduled task metadata object for searching
//                                     for a scheduled task.
//                - String - 
//                           
//                - UUID - 
//                           
//                - ScheduledJob -  routine task.
//
// Returns:
//  UUID - 
//                            
// 
Function UUID(Val Id) Export
	
	Return UniqueIdentifierOfTheTask(Id, True);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Returns the use of a scheduled task.
// Before calling, you must have the administration right or install the privileged mode.
//
// In the service model, it works with scheduled tasks of the platform, not with queue tasks,
// in the same way in both split and undivided modes.
//
// Parameters:
//  Id - MetadataObject -  a scheduled task metadata object for searching
//                  for a predefined scheduled task.
//                - UUID -  ID of the scheduled task.
//                - String - 
//                - ScheduledJob -  routine task.
//
// Returns:
//  Boolean - 
// 
Function ScheduledJobUsed(Val Id) Export
	
	RaiseIfNoAdministrationRights();
	
	Job = GetScheduledJob(Id);
	
	Return Job.Use;
	
EndFunction

// Returns the schedule of the scheduled task.
// Before calling, you must have the administration right or install the privileged mode.
//
// In the service model, it works with scheduled tasks of the platform, not with queue tasks,
// in the same way in both split and undivided modes.
//
// Parameters:
//  Id - MetadataObject -  a scheduled task metadata object for searching
//                  for a predefined scheduled task.
//                - UUID -  ID of the scheduled task.
//                - String - 
//                - ScheduledJob -  routine task.
//
//  InStructure    - Boolean -  if True, then the schedule will be converted
//                  to a structure that can be passed to the client.
// 
// Returns:
//  JobSchedule, Structure - 
// 
Function JobSchedule(Val Id, Val InStructure = False) Export
	
	RaiseIfNoAdministrationRights();
	
	Job = GetScheduledJob(Id);
	
	If InStructure Then
		Return CommonClientServer.ScheduleToStructure(Job.Schedule);
	EndIf;
	
	Return Job.Schedule;
	
EndFunction

// Sets the use of a routine task.
// Before calling, you must have the administration right or install the privileged mode.
//
// In the service model, it works with scheduled tasks of the platform, not with queue tasks,
// in the same way in both split and undivided modes.
//
// Parameters:
//  Id - MetadataObject        -  a scheduled task metadata object for searching
//                                            for a predefined scheduled task.
//                - UUID -  ID of the scheduled task.
//                - String                  - 
//                - ScheduledJob     -  routine task.
//  Use - Boolean                  -  the usage value to set.
//
Procedure SetScheduledJobUsage(Val Id, Val Use) Export
	
	RaiseIfNoAdministrationRights();
	
	JobID = UniqueIdentifierOfTheTask(Id);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ProgramInterfaceCache");
	LockItem.SetValue("Id", String(JobID));
	
	BeginTransaction();
	Try
		Block.Lock();
		Job = GetScheduledJob(JobID);
		
		If Job.Use <> Use Then
			Job.Use = Use;
			Job.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Sets the schedule for a routine task.
// Before calling, you must have the administration right or install the privileged mode.
//
// In the service model, it works with scheduled tasks of the platform, not with queue tasks,
// in the same way in both split and undivided modes.
//
// Parameters:
//  Id - MetadataObject -  a scheduled task metadata object for searching
//                  for a predefined scheduled task.
//                - UUID -  ID of the scheduled task.
//                - String - 
//                - ScheduledJob -  routine task.
//
//  Schedule    - JobSchedule -  schedule.
//                - Structure - 
//                  
// 
Procedure SetJobSchedule(Val Id, Val Schedule) Export
	
	RaiseIfNoAdministrationRights();
	
	JobID = UniqueIdentifierOfTheTask(Id);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ProgramInterfaceCache");
	LockItem.SetValue("Id", String(JobID));
	
	BeginTransaction();
	Try
		Block.Lock();
		Job = GetScheduledJob(JobID);
		
		If TypeOf(Schedule) = Type("JobSchedule") Then
			Job.Schedule = Schedule;
		Else
			Job.Schedule = CommonClientServer.StructureToSchedule(Schedule);
		EndIf;
		
		Job.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns a routine task from the information base.
//
// In the service model, it works with scheduled tasks of the platform, not with queue tasks,
// in the same way in both split and undivided modes.
//
// Parameters:
//  Id - MetadataObject -  a scheduled task metadata object for searching
//                  for a predefined scheduled task.
//                - UUID -  ID of the scheduled task.
//                - String - 
//                - ScheduledJob - 
//                  
// 
// Returns:
//  ScheduledJob - 
//
Function GetScheduledJob(Val Id) Export
	
	RaiseIfNoAdministrationRights();
	
	If TypeOf(Id) = Type("ScheduledJob") Then
		Id = Id.UUID;
	EndIf;
	
	If TypeOf(Id) = Type("String") Then
		Id = New UUID(Id);
	EndIf;
	
	If TypeOf(Id) = Type("MetadataObject") Then
		ScheduledJob = ScheduledJobs.FindPredefined(Id);
	Else
		ScheduledJob = ScheduledJobs.FindByUUID(Id);
	EndIf;
	
	If ScheduledJob = Undefined Then
		Raise( NStr("en = 'The scheduled job does not exist.
		                              |It might have been deleted by another user.';") );
	EndIf;
	
	Return ScheduledJob;
	
EndFunction

// 
// 
// 
// Parameters:
//  Job - ScheduledJob - 
//                                  
//          - String - 
//
// Returns:
//  Undefined
//  :
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
Function PropertiesOfLastJob(Val Job) Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	If TypeOf(Job) = Type("ScheduledJob") Then
		Job = Job.UUID;
	EndIf;
	
	If TypeOf(Job) = Type("String") Then
		Job = New UUID(Job);
	EndIf;
	
	ScheduledJob = ScheduledJobs.FindByUUID(Job);
	CurrentFilter = New Structure("MethodName", ScheduledJob.Metadata.MethodName);
	Result = BackgroundJobs.GetBackgroundJobs(CurrentFilter);
	If Result.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	BackgroundJobLast = LastBackgroundJobInArray(Result);
	
	BackgroundJobProperties = NewBackgroundJobsProperties();
	FillPropertyValues(BackgroundJobProperties, BackgroundJobLast);
	
	BackgroundJobProperties.Id = BackgroundJobLast.UUID;
	BackgroundJobProperties.ScheduledJobID = Job;
	Return BackgroundJobProperties;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Returns a flag indicating that work with external resources is blocked.
//
// Returns:
//   Boolean   - 
//
Function OperationsWithExternalResourcesLocked() Export
	
	If Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		ModuleWorkLockWithExternalResources = Common.CommonModule("ExternalResourcesOperationsLock");
		Return ModuleWorkLockWithExternalResources.OperationsWithExternalResourcesLocked();
	EndIf;
	
	Return False;
	
EndFunction

// Allows working with external resources.
//
Procedure UnlockOperationsWithExternalResources() Export
	
	If Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		ModuleWorkLockWithExternalResources = Common.CommonModule("ExternalResourcesOperationsLock");
		ModuleWorkLockWithExternalResources.AllowExternalResources();
	EndIf;
	
EndProcedure

// Prohibits working with external resources.
//
Procedure LockOperationsWithExternalResources() Export
	
	If Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		ModuleWorkLockWithExternalResources = Common.CommonModule("ExternalResourcesOperationsLock");
		ModuleWorkLockWithExternalResources.DenyExternalResources();
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// Sets the required values for the parameters of the routine task.
// In the service model
// , only the value of the Use property can be changed for a job created based on the job queue template.
//
// Parameters:
//  ScheduledJob - MetadataObjectScheduledJob -  the task whose properties
//                        you want to change.
//  ParametersToChange - Structure -  properties of the scheduled task that you want to change.
//                        The structure key is the parameter name, and the value is the value of the form parameter.
//  Filter               - See FindJobs.Filter.
//
Procedure SetScheduledJobParameters(ScheduledJob, ParametersToChange, Filter = Undefined) Export
	
	If Filter = Undefined Then
		Filter = New Structure;
	EndIf;
	Filter.Insert("Metadata", ScheduledJob);
	
	JobsList = FindJobs(Filter);
	If JobsList.Count() = 0 Then
		ParametersToChange.Insert("Metadata", ScheduledJob);
		AddJob(ParametersToChange);
	Else
		For Each Job In JobsList Do
			ChangeJob(Job, ParametersToChange);
		EndDo;
	EndIf;
EndProcedure

// Sets the use of a predefined routine task.
//
// Parameters:
//  MetadataJob - MetadataObject -  metadata of a predefined routine task.
//  Use     - Boolean -  True if the task needs to be enabled, otherwise False.
//
Procedure SetPredefinedScheduledJobUsage(MetadataJob, Use) Export
	
	If Common.DataSeparationEnabled() Then
		Filter     = New Structure;
		Filter.Insert("Metadata", MetadataJob);
		Parameters = New Structure;
		Parameters.Insert("Use", Use);
		Jobs = FindJobs(Filter);
		For Each Job In Jobs Do
			ChangeJob(Job, Parameters);
			Break;
		EndDo;
	Else
		JobID = UniqueIdentifierOfTheTask(MetadataJob);
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ProgramInterfaceCache");
		LockItem.SetValue("Id", String(JobID));
		
		BeginTransaction();
		Try
			Block.Lock();
			Job = ScheduledJobs.FindByUUID(JobID);
			
			If Job.Use <> Use Then
				Job.Use = Use;
				Job.Write();
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

// Cancels background tasks for a scheduled task
// and writes to the log.
//
Procedure CancelJobExecution(Val ScheduledJob, TextForLog) Export
	
	CurrentSession = GetCurrentInfoBaseSession().GetBackgroundJob();
	If CurrentSession = Undefined Then
		Return;
	EndIf;
	
	If ScheduledJob = Undefined Then
		For Each Job In Metadata.ScheduledJobs Do
			If Job.MethodName = CurrentSession.MethodName Then
				ScheduledJob = Job;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If ScheduledJob = Undefined Then
		Return;
	EndIf;
	
	EventName = NStr("en = 'Cancel background job';", Common.DefaultLanguageCode());
	
	WriteLogEvent(EventName,
		EventLogLevel.Warning,
		ScheduledJob,
		,
		TextForLog);
	
	CurrentSession.Cancel();
	CurrentSession.WaitForExecutionCompletion(1);
	
EndProcedure

Function ScheduledJobParameter(ScheduledJob, PropertyName, DefaultValue) Export
	
	JobParameters = New Structure;
	JobParameters.Insert("Metadata", ScheduledJob);
	
	SetPrivilegedMode(True);
	
	JobsList = FindJobs(JobParameters);
	For Each Job In JobsList Do
		Return Job[PropertyName];
	EndDo;
	
	Return DefaultValue;
	
EndFunction

// Sets an exclusive managed lock for recording routine tasks.
//  Technically, the lock is set on the Cache interface information register.
//
// Parameters:
//  Id - UUID -  ID of the scheduled task.
//                - MetadataObjectScheduledJob - 
//
Procedure BlockARoutineTask(Id) Export 
	
	If TypeOf(Id) = Type("MetadataObject") Then
		LockID = Id.Name;
	Else
		LockID = String(Id);
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ProgramInterfaceCache");
	LockItem.SetValue("Id", LockID);
	Block.Lock();
	
EndProcedure

// Adds a new routine task (excluding the queue of tasks of the service model).
// 
// Parameters: 
//  Parameters - Structure - :
//   * Use - Boolean -  True if the scheduled task should be performed automatically according to the schedule. 
//   * Metadata    - MetadataObjectScheduledJob -  be sure to specify. The metadata object 
//                              that will be used to create the routine task.
//   * Parameters     - Array -  parameters of the routine task. The number and composition of parameters must correspond 
//                              to the parameters of the routine task method.
//   * Key          - String -  application ID of the scheduled task.
//   * RestartIntervalOnFailure - Number -  the interval in seconds after which the task should be restarted 
//                              in case of an emergency.
//   * Schedule    - JobSchedule -  the job schedule.
//   * RestartCountOnFailure - Number -  the number of repetitions when the task crashes.
//
// Returns:
//  ScheduledJob
//
Function AddARoutineTask(Parameters) Export
	
	RaiseIfNoAdministrationRights();
	
	JobMetadata = Parameters.Metadata;
	Job = ScheduledJobs.CreateScheduledJob(JobMetadata);
	
	If Parameters.Property("Description") Then
		Job.Description = Parameters.Description;
	Else
		Job.Description = JobMetadata.Description;
	EndIf;
	
	If Parameters.Property("Use") Then
		Job.Use = Parameters.Use;
	Else
		Job.Use = JobMetadata.Use;
	EndIf;
	
	If Parameters.Property("Key") Then
		Job.Key = Parameters.Key;
	Else
		Job.Key = JobMetadata.Key;
	EndIf;
	
	If Parameters.Property("UserName") Then
		Job.UserName = Parameters.UserName;
	EndIf;
	
	If Parameters.Property("RestartIntervalOnFailure") Then
		Job.RestartIntervalOnFailure = Parameters.RestartIntervalOnFailure;
	Else
		Job.RestartIntervalOnFailure = JobMetadata.RestartIntervalOnFailure;
	EndIf;
	
	If Parameters.Property("RestartCountOnFailure") Then
		Job.RestartCountOnFailure = Parameters.RestartCountOnFailure;
	Else
		Job.RestartCountOnFailure = JobMetadata.RestartCountOnFailure;
	EndIf;
	
	If Parameters.Property("Parameters") Then
		Job.Parameters = Parameters.Parameters;
	EndIf;
	
	If Parameters.Property("Schedule") Then
		Job.Schedule = Parameters.Schedule;
	EndIf;
	
	Job.Write();
	
	Return Job;
	
EndFunction

// 
//
// Parameters:
//  Id - MetadataObject -  a routine task metadata object for searching
//                                     for an undefined routine task.
//                - String - 
//                           
//                - UUID -  ID of the scheduled task.
//                - ScheduledJob -  
//                  
//
Procedure DeleteScheduledJob(Val Id) Export
	
	RaiseIfNoAdministrationRights();
	
	Id = UpdatedTaskID(Id);
	
	JobsList = New Array; // Array of ScheduledJob
	
	If TypeOf(Id) = Type("MetadataObject") Then
		Filter = New Structure("Metadata, Predefined", Id, False);
		JobsList = ScheduledJobs.GetScheduledJobs(Filter);
	Else
		ScheduledJob = ScheduledJobs.FindByUUID(Id);
		If ScheduledJob <> Undefined Then
			JobsList.Add(ScheduledJob);
		EndIf;
	EndIf;
	
	For Each ScheduledJob In JobsList Do
		JobID = UniqueIdentifierOfTheTask(ScheduledJob);
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ProgramInterfaceCache");
		LockItem.SetValue("Id", String(JobID));
		
		BeginTransaction();
		Try
			Block.Lock();
			Job = ScheduledJobs.FindByUUID(JobID);
			If Job <> Undefined Then
				Job.Delete();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

// Changes the routine task (without taking into account the queue of tasks of the service model).
//
// Parameters: 
//  Id - MetadataObject -  a routine task metadata object for searching
//                                     for an undefined routine task.
//                - String - 
//                           
//                - UUID -  ID of the scheduled task.
//                - ScheduledJob -  routine task.
//
//  Parameters - Structure - :
//   * Use - Boolean -  True if the scheduled task should be performed automatically according to the schedule.
//   * Parameters     - Array -  parameters of the routine task. The number and composition of parameters must correspond
//                              to the parameters of the routine task method.
//   * Key          - String -  application ID of the scheduled task.
//   * RestartIntervalOnFailure - Number -  the interval in seconds after which the task should be restarted
//                              in case of an emergency.
//   * Schedule    - JobSchedule -  the job schedule.
//   * RestartCountOnFailure - Number -  the number of repetitions when the task crashes.
//   
Procedure ChangeScheduledJob(Val Id, Val Parameters) Export
	
	RaiseIfNoAdministrationRights();
	
	Id = UpdatedTaskID(Id);
	JobID = UniqueIdentifierOfTheTask(Id);
	
	If JobID = Undefined Then
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Scheduled job by the passed ID is not found.
				|
				|If the scheduled job is not predefined, first of all add
				|it to the list of jobs using method %1.';"),
			"ScheduledJobsServer.AddJob");
		
		Raise ExceptionText;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ProgramInterfaceCache");
	LockItem.SetValue("Id", String(JobID));
	
	BeginTransaction();
	Try
		Block.Lock();
		Job = ScheduledJobs.FindByUUID(JobID);
		If Job <> Undefined Then
			HasChanges = False;
			
			UpdateTheValueOfTheTaskProperty(Job, "Description", Parameters, HasChanges);
			UpdateTheValueOfTheTaskProperty(Job, "Use", Parameters, HasChanges);
			UpdateTheValueOfTheTaskProperty(Job, "Key", Parameters, HasChanges);
			UpdateTheValueOfTheTaskProperty(Job, "UserName", Parameters, HasChanges);
			UpdateTheValueOfTheTaskProperty(Job, "RestartIntervalOnFailure", Parameters, HasChanges);
			UpdateTheValueOfTheTaskProperty(Job, "RestartCountOnFailure", Parameters, HasChanges);
			UpdateTheValueOfTheTaskProperty(Job, "Parameters", Parameters, HasChanges);
			UpdateTheValueOfTheTaskProperty(Job, "Schedule", Parameters, HasChanges);
			
			If HasChanges Then
				Job.Write();
			EndIf;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Parameters:
//   BackgroundJobArray - Array of BackgroundJob
//   LastBackgroundJob - BackgroundJob
//                           - Undefined
// Returns:
//   Background Task, Undefined
//
Function LastBackgroundJobInArray(BackgroundJobArray, LastBackgroundJob = Undefined) Export
	
	For Each CurrentBackgroundJob In BackgroundJobArray Do
		If LastBackgroundJob = Undefined Then
			LastBackgroundJob = CurrentBackgroundJob;
			Continue;
		EndIf;
		If ValueIsFilled(LastBackgroundJob.End) Then
			If Not ValueIsFilled(CurrentBackgroundJob.End)
			 Or LastBackgroundJob.End < CurrentBackgroundJob.End Then
				LastBackgroundJob = CurrentBackgroundJob;
			EndIf;
		Else
			If Not ValueIsFilled(CurrentBackgroundJob.End)
			   And LastBackgroundJob.Begin < CurrentBackgroundJob.Begin Then
				LastBackgroundJob = CurrentBackgroundJob;
			EndIf;
		EndIf;
	EndDo;
	
	Return LastBackgroundJob;
	
EndFunction

#EndRegion

#Region Private

Function UpdatedTaskID(Val Id)
	
	If TypeOf(Id) = Type("ScheduledJob") Then
		Id = Id.UUID;
	EndIf;
	
	If TypeOf(Id) = Type("String") Then
		MetadataObject = Metadata.ScheduledJobs.Find(Id);
		If MetadataObject = Undefined Then
			Id = New UUID(Id);
		Else
			Id = MetadataObject;
		EndIf;
	EndIf;
	
	Return Id;
	
EndFunction

Function UniqueIdentifierOfTheTask(Val Id, InSplitModeTheQueueJobID = False)
	
	If TypeOf(Id) = Type("UUID") Then
		Return Id;
	EndIf;
	
	If TypeOf(Id) = Type("ScheduledJob") Then
		Return Id.UUID;
	EndIf;
	
	If TypeOf(Id) = Type("String") Then
		Return New UUID(Id);
	EndIf;
	
	If InSplitModeTheQueueJobID
	   And Common.DataSeparationEnabled() Then
		
		If TypeOf(Id) = Type("MetadataObject") Then
			JobParameters = New Structure("Metadata", Id);
			JobsList = FindJobs(JobParameters);
			If JobsList = Undefined Then
				Return Undefined;
			EndIf;
			
			For Each Job In JobsList Do
				Return Job.Id.UUID();
			EndDo;
		ElsIf TypeOf(Id) = Type("ValueTableRow") Then
			Return Id.Id.UUID();
		ElsIf Common.IsReference(TypeOf(Id)) Then
			Return Id.UUID();
		Else
			Return Undefined;
		EndIf;
	Else
		If TypeOf(Id) = Type("MetadataObject") And Id.Predefined Then
			Return ScheduledJobs.FindPredefined(Id).UUID;
		ElsIf TypeOf(Id) = Type("MetadataObject") And Not Id.Predefined Then
			JobsList = ScheduledJobs.GetScheduledJobs(New Structure("Metadata", Id));
			For Each ScheduledJob In JobsList Do
				Return ScheduledJob.UUID;
			EndDo; 
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

// For the procedure, change the Task.
Procedure UpdateTheValueOfTheTaskProperty(Job, PropertyName, JobParameters, HasChanges)
	
	If Not JobParameters.Property(PropertyName) Then
		Return;
	EndIf;
	
	If Job[PropertyName] = JobParameters[PropertyName]
	 Or TypeOf(Job[PropertyName]) = Type("JobSchedule")
	   And TypeOf(JobParameters[PropertyName]) = Type("JobSchedule")
	   And String(Job[PropertyName]) = String(JobParameters[PropertyName]) Then
		
		Return;
	EndIf;
	
	If TypeOf(Job[PropertyName]) = Type("JobSchedule") 
		And TypeOf(JobParameters[PropertyName]) = Type("Structure") Then
		FillPropertyValues(Job[PropertyName], JobParameters[PropertyName]);
	Else
		Job[PropertyName] = JobParameters[PropertyName];
	EndIf;
	
	HasChanges = True;
	
EndProcedure

// For the functions Find Task, Task, Add Task.
Function UpdatedTaskList(JobsList)
	
	// 
	ListCopy = JobsList.Copy();
	ListCopy.Columns.Add("UUID");
	For Each Job In ListCopy Do
		Job.UUID = Job.Id;
	EndDo;
	
	Return ListCopy;
	
EndFunction

// For the functions Find Task, Task, Delete Task, Change Task.
Function QueueJobLink(Id, JobParameters)
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	CatalogForJob = ModuleJobsQueue.CatalogJobsQueue();
	
	Return CatalogForJob.GetRef(Id);
	
EndFunction

// Throws an exception if the user does not have administrative rights.
Procedure RaiseIfNoAdministrationRights()
	
	CheckSystemAdministrationRights = True;
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		CheckSystemAdministrationRights = False;
	EndIf;
	
	If Not Users.IsFullUser(, CheckSystemAdministrationRights) Then
		Raise NStr("en = 'Access violation.';");
	EndIf;
	
EndProcedure

Function NewBackgroundJobsProperties()
	
	BackgroundJobsProperties = New Structure;
	BackgroundJobsProperties.Insert("Id");
	BackgroundJobsProperties.Insert("Key");
	BackgroundJobsProperties.Insert("Begin");
	BackgroundJobsProperties.Insert("End");
	BackgroundJobsProperties.Insert("ScheduledJobID");
	BackgroundJobsProperties.Insert("State");
	BackgroundJobsProperties.Insert("MethodName");
	BackgroundJobsProperties.Insert("Placement");
	BackgroundJobsProperties.Insert("StartAttempt");
	BackgroundJobsProperties.Insert("UserMessages");
	BackgroundJobsProperties.Insert("SessionNumber");
	BackgroundJobsProperties.Insert("SessionStarted");
	
	Return BackgroundJobsProperties;
	
EndFunction

#EndRegion