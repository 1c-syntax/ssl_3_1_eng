///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

#Region InternalEventsHandlers

#Region StandardSubsystems

#Region Core

// See CommonOverridable.OnAddReferenceSearchExceptions.
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	RefSearchExclusions.Add(
		Metadata.InformationRegisters.UseSuppliedAdditionalReportsAndProcessorsInDataAreas.FullName());
	
EndProcedure

#EndRegion

#Region AdditionalReportsAndDataProcessors

// Called when determining whether the current user has the right to add an additional
// report or processing to the data area.
//
// Parameters:
//  AdditionalDataProcessor - 
//    
//  Result - Boolean -  this parameter is set to the permission flag in this procedure,
//  StandardProcessing - Boolean -  this parameter in this procedure sets the flag for performing
//    standard permission check processing.
//
Procedure OnCheckInsertRight(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
		
	If GetFunctionalOption("IndependentUsageOfAdditionalReportsAndDataProcessorsSaaS") Then
		Return;
	EndIf;
			
	StandardProcessing = False;
	If AdditionalDataProcessor = Undefined Then
		Result = False;
		Return;
	EndIf;
		
	If AdditionalDataProcessor.IsNew() Then
		DataProcessorRef1 = AdditionalDataProcessor.GetNewObjectRef();
	Else
		DataProcessorRef1 = AdditionalDataProcessor.Ref;
	EndIf;
	Result = IsSuppliedDataProcessor(DataProcessorRef1);
	
EndProcedure

// Called when checking whether an additional report can be loaded or processed from a file.
//
// Parameters:
//  AdditionalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors,
//  Result - Boolean -  this parameter in this procedure sets the flag for whether
//    an additional report can be loaded or processed from a file,
//  StandardProcessing - Boolean -  this parameter in this procedure sets the flag for performing
//    standard processing to check whether an additional report can be loaded or processed from a file.
//
Procedure OnCheckCanImportDataProcessorFromFile(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled() Then
		
		Result = (GetFunctionalOption("IndependentUsageOfAdditionalReportsAndDataProcessorsSaaS")) 
			And (Not IsSuppliedDataProcessor(AdditionalDataProcessor));
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

// Called when checking whether an additional report can be uploaded or processed to a file.
//
// Parameters:
//  AdditionalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors,
//  Result - Boolean -  this parameter in this procedure sets the flag for whether
//    an additional report can be uploaded or processed to a file,
//  StandardProcessing - Boolean -  this parameter in this procedure sets the flag for performing
//    standard processing to check whether an additional report can be uploaded or processed to a file.
//
Procedure OnCheckCanExportDataProcessorToFile(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled() Then
		
		Result = Not IsSuppliedDataProcessor(AdditionalDataProcessor);
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

// Fills in the types of publishing additional reports and processing that are not available for use
// in the current database model.
//
// Parameters:
//  NotAvailablePublicationKinds - Array of String
//
Procedure OnFillUnavailablePublicationKinds(Val NotAvailablePublicationKinds) Export
	
	If Common.DataSeparationEnabled() Then
		NotAvailablePublicationKinds.Add("DebugMode");
	EndIf;
	
EndProcedure

// The procedure must be called from the event before the directory is Written
//  Additional processing reports, checks the validity of changing the details
//  of elements in this directory for additional treatments received from
//  the catalog of additional treatments of the service Manager.
//
// Parameters:
//  Source - CatalogObject.AdditionalReportsAndDataProcessors
//  Cancel - Boolean -  flag for refusing to write a directory element.
//
Procedure BeforeWriteAdditionalDataProcessor(Source, Cancel) Export
	
	If Source.IsNew() Then
		Return;
	EndIf;
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	If ModuleSaaSOperations.SessionWithoutSeparators() Then
		Return;
	EndIf;
	
	If IsSuppliedDataProcessor(Source.Ref) Then
		
		AttributesToControl = AdditionalReportsAndDataProcessorsSaaSCached.AttributesToControl();
		PreviousValues1 = Common.ObjectAttributesValues(Source.Ref, AttributesToControl);
		
		For Each AttributeToControl In AttributesToControl Do
			
			SourceAttribute = Undefined;
			ResultingAttribute = Undefined;
			
			If TypeOf(Source[AttributeToControl]) = Type("ValueStorage") Then
				SourceAttribute = Source[AttributeToControl].Get();
			Else
				SourceAttribute = Source[AttributeToControl];
			EndIf;
			
			If TypeOf(PreviousValues1[AttributeToControl]) = Type("ValueStorage") Then
				ResultingAttribute = PreviousValues1[AttributeToControl].Get();
			Else
				ResultingAttribute = PreviousValues1[AttributeToControl];
			EndIf;
			
			If SourceAttribute <> ResultingAttribute Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Invalid attempt to change attribute value %1 for additional data processor %2
						|received from the additional data processor catalog of the Service manager.';"), 
					AttributeToControl, Source.Description);
				
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// The procedure must be called from the event Before deleting the directory
//  Additional reports and processing.
//
// Parameters:
//  Source - CatalogObject.AdditionalReportsAndDataProcessors
//  Cancel - Boolean -  flag for refusing to delete a directory element from the information database.
//
Procedure BeforeDeleteAdditionalDataProcessor(Source, Cancel) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	// 
	SuppliedDataProcessor = SuppliedDataProcessor(Source.Ref);
	If ValueIsFilled(SuppliedDataProcessor) Then
		
		// 
		RecordSet = InformationRegisters.UseSuppliedAdditionalReportsAndProcessorsInDataAreas.CreateRecordSet();
		RecordSet.Filter.SuppliedDataProcessor.Set(SuppliedDataProcessor);
		RecordSet.Write();
		
	EndIf;
		
EndProcedure

// 
//
Procedure OnGetRegistrationData(Object, RegistrationData, StandardProcessing) Export
	
	SetPrivilegedMode(True);
	If Not Object.IsNew() And Common.DataSeparationEnabled() Then
		SuppliedDataProcessor = SuppliedDataProcessor(Object.Ref);
		If ValueIsFilled(SuppliedDataProcessor) Then
			CommonClientServer.SupplementStructure(RegistrationData, 
				GetRegistrationData(SuppliedDataProcessor), True);
			StandardProcessing = False;
		EndIf;
	EndIf;
	
EndProcedure

// Called when external processing is enabled.
//
// Parameters:
//  Ref - CatalogRef.AdditionalReportsAndDataProcessors,
//  StandardProcessing - Boolean -  the flag need to perform the standard processing of the connection
//    external processing,
//  Result - String -  name of the connected external report or processing (if
//    the default Processing parameter was set to False in the handler).
//
Procedure OnAttachExternalDataProcessor(Val Ref, StandardProcessing, Result) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If TypeOf(Ref) <> Type("CatalogRef.AdditionalReportsAndDataProcessors")
		Or Ref = Catalogs.AdditionalReportsAndDataProcessors.EmptyRef() Then
		Raise NStr("en = 'A non-existing additional data processor connection requested.';");
	EndIf;
	
	CheckCanExecute(Ref);
	
	If Not IsSuppliedDataProcessor(Ref) 
		And GetFunctionalOption("IndependentUsageOfAdditionalReportsAndDataProcessorsSaaS") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	UseSecurityProfiles = False;
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
	EndIf;
	
	If UseSecurityProfiles Then

		ConnectionParameters = DataProcessorToUseAttachmentParameters(Ref);
		ModuleSafeModeManagerSaaS = Common.CommonModule("SafeModeManagerSaaS");
		SafeMode = ModuleSafeModeManagerSaaS.ExternalModuleExecutionMode(Ref);
		If SafeMode = Undefined Then
			SafeMode = True;
		EndIf;
		
	Else
		
		ConnectionParameters = DataProcessorToUseAttachmentParameters(Ref);
		SafeMode = ConnectionParameters.SafeMode;
		
		If SafeMode Then
			
			PermissionsRequest = New Query(
			"SELECT TOP 1
			|	AdditionalReportsAndPermissionProcessing.LineNumber,
			|	AdditionalReportsAndPermissionProcessing.PermissionKind
			|FROM
			|	Catalog.AdditionalReportsAndDataProcessors.Permissions AS AdditionalReportsAndPermissionProcessing
			|WHERE
			|	AdditionalReportsAndPermissionProcessing.Ref = &Ref");
			
			PermissionsRequest.SetParameter("Ref", Ref);
			HasPermissions1 = Not PermissionsRequest.Execute().IsEmpty();
			CompatibilityMode = Common.ObjectAttributeValue(Ref, "PermissionsCompatibilityMode");
			If CompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_2_2 And HasPermissions1 Then
				SafeMode = False;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Constants.UseSecurityProfilesForARDP.Get() And Not SafeMode Then
		SafeMode = String(ConnectionParameters.GUIDVersion);
	EndIf;
	
	// 
	// 
	// 
	AddressInTempStorage = PutToTempStorage(ConnectionParameters.DataProcessorStorage.Get());
	Manager = ?(IsReport(Ref), ExternalReports, ExternalDataProcessors);
	Result = Manager.Connect(AddressInTempStorage, ConnectionParameters.ObjectName, SafeMode, 
		Common.ProtectionWithoutWarningsDetails()); 
	// 
	// 
	// 
	
EndProcedure

// Called when creating an external processing object.
//
// Parameters:
//  Ref - CatalogRef.AdditionalReportsAndDataProcessors -  additional report or processing.
//  StandardProcessing - Boolean -  the flag need to perform the standard processing of the connection
//                                  external processing.
//  Result - ExternalDataProcessor
//            - ExternalReport - 
//              
//
Procedure OnCreateExternalDataProcessor(Val Ref, StandardProcessing, Result) Export
	
	StandardProcessing = True;
	DataProcessorName = Undefined;
	
	OnAttachExternalDataProcessor(Ref, StandardProcessing, DataProcessorName);
	
	If StandardProcessing Then
		Return;
	EndIf;
		
	If DataProcessorName = Undefined Then
		Raise NStr("en = 'Creation is requested for an object of a non-existing additional data processor.';");
	EndIf;
	
	CheckCanExecute(Ref);
	
	// 
	// 
	If IsReport(Ref) Then
		Result = ExternalReports.Create(DataProcessorName);
	Else
		Result = ExternalDataProcessors.Create(DataProcessorName);
	EndIf;
	// 
	// 
	
EndProcedure

// Called before recording changes to the routine task for additional reports and processes in the service model.
//
// Parameters:
//   Object - CatalogObject.AdditionalReportsAndDataProcessors -  the object of the report or additional processing.
//   Command - CatalogTabularSectionRow.AdditionalReportsAndDataProcessors.Commands -  command description.
//   Job - ScheduledJob
//           - ValueTableRow - 
//       See ScheduledJobsServer.Job.
//   Changes - Structure - 
//       
//       
//
Procedure BeforeUpdateJob(Object, Command, Job, Changes) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If Not Constants.AllowScheduledJobsExecutionSaaS.Get() Then
		Raise NStr("en = 'It is prohibited by the service administrator to periodically run additional data processor commands as jobs.';");
	EndIf;
	
	MinInterval = Constants.MinimalARADPScheduledJobIntervalSaaS.Get();
	SourceDate1 = CurrentSessionDate();
	DateToCheck = SourceDate1 + MinInterval - 1;
	
	If Job.Schedule.ExecutionRequired(DateToCheck, SourceDate1) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Schedule set for execution of commands of an additional report or a data processor as jobs must be maximum once in %1 seconds.';"), 
			MinInterval);
	EndIf;
		
EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "AdditionalReportsAndDataProcessorsSaaS.LockAdditionalReportsAndDataProcessorsForUpdate";
	Handler.SharedData = True;
	Handler.ExclusiveMode = False;
	
EndProcedure

#EndRegion

#Region SaaSOperations

// Checks whether the passed additional processing is an instance
// of the supplied additional processing.
//
// Parameters:
//   DataProcessorToUse - CatalogRef.AdditionalReportsAndDataProcessors -  additional processing.
//
// Returns:
//  Boolean
//
Function IsSuppliedDataProcessor(DataProcessorToUse) Export
	
	SuppliedDataProcessor = SuppliedDataProcessor(DataProcessorToUse);
	Return ValueIsFilled(SuppliedDataProcessor);
	
EndFunction

// 

// Installs the supplied additional processing in the current data area after receiving the supplied data
// and notifies the service Manager in case of failure.
//
// Parameters:
//  InstallationDetails - See InstallSuppliedDataProcessorToDataArea.InstallationDetails
//  QuickAccess       - See InstallSuppliedDataProcessorToDataArea.QuickAccess
//  Jobs             - See InstallSuppliedDataProcessorToDataArea.Jobs
//  Sections             - See InstallSuppliedDataProcessorToDataArea.Sections
//  CatalogsAndDocuments         - See InstallSuppliedDataProcessorToDataArea.CatalogsAndDocuments
//  AdditionalReportOptions - See InstallSuppliedDataProcessorToDataArea.AdditionalReportOptions
//  EmployeeResponsible       - See InstallSuppliedDataProcessorToDataArea.EmployeeResponsible
// 
Procedure InstallSuppliedDataProcessorOnGet(Val InstallationDetails, Val QuickAccess, Val Jobs, Val Sections, 
	Val CatalogsAndDocuments, Val CommandsPlacementSettings, Val AdditionalReportOptions, Val EmployeeResponsible) Export
	
	Try
		InstallSuppliedDataProcessorToDataArea(InstallationDetails, QuickAccess, 
			Jobs, Sections, CatalogsAndDocuments, CommandsPlacementSettings, AdditionalReportOptions, EmployeeResponsible);
	Except
		
		ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		SuppliedDataProcessor = Catalogs.SuppliedAdditionalReportsAndDataProcessors.GetRef(InstallationDetails.Id);
		ProcessErrorOfInstallingAdditionalDataProcessorToDataArea(
			SuppliedDataProcessor, InstallationDetails.Installation, ExceptionText);
			
	EndTry;
	
EndProcedure

// Installs the supplied additional processing in the current data area.
//
// Parameters:
//  InstallationDetails - Structure - :
//    * Id - UUID -  unique ID of the reference
//                      element of the reference list deliverableadditional reports and Processing.
//    * Presentation - String -  representation of the installation of the supplied additional
//      processing (will be used as the name of the reference element
//      Additional reports and processing).
//    * Installation - UUID -  unique ID of the installation
//      of the supplied additional processing (to be used as
//      the unique ID of the reference reference for additional processing Reports).
//  QuickAccess - ValueTable - 
//     :
//    * CommandID - String -  command ID.
//    * User - CatalogRef.Users -  user of the app.
//  Jobs - ValueTable - 
//      :
//    * Id - String -  command ID.
//    * ScheduledJobSchedule - ValueList:
//       ** Value - JobSchedule -  schedule.
//    * ScheduledJobUsage - Boolean -  indicates whether the command execution is enabled
//          as a routine task.
//  Sections - ValueTable - :
//    * Section - CatalogRef.MetadataObjectIDs
//  CatalogsAndDocuments - ValueTable:
//    * RelatedObject - CatalogRef.MetadataObjectIDs
//  AdditionalReportOptions - Array -  keys for additional report report options.
//  EmployeeResponsible - CatalogRef.Users
//
Procedure InstallSuppliedDataProcessorToDataArea(Val InstallationDetails, Val QuickAccess, Val Jobs, Val Sections, 
	Val CatalogsAndDocuments, Val CommandsPlacementSettings, Val AdditionalReportOptions, Val EmployeeResponsible) Export
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	WriteLogEvent(
		NStr("en = 'Built-in additional reports and data processors.Installation of the built-in data processor is initiated in the data area';",
		Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		,
		String(InstallationDetails.Id),
		String(InstallationDetails.Installation));
		
	BeginTransaction();
	Try
		SuppliedDataProcessor = Catalogs.SuppliedAdditionalReportsAndDataProcessors.GetRef(InstallationDetails.Id);
		SuppliedDataProcessorExists = Common.RefExists(SuppliedDataProcessor);
		
		Block = New DataLock;
		If SuppliedDataProcessorExists Then
			DataProcessorToUseRef = DataProcessorToUse(SuppliedDataProcessor, InstallationDetails.Installation);
			If ValueIsFilled(DataProcessorToUseRef) Then
				LockItem = Block.Add("Catalog.AdditionalReportsAndDataProcessors");
				LockItem.SetValue("Ref", DataProcessorToUseRef);
				LockItem = Block.Add("InformationRegister.UseSuppliedAdditionalReportsAndProcessorsInDataAreas");
				LockItem.SetValue("SuppliedDataProcessor", SuppliedDataProcessor);
			EndIf;
		EndIf;
		LockItem = Block.Add("InformationRegister.SuppliedAdditionalReportAndDataProcessorInstallationQueueInDataArea");
		LockItem.SetValue("SuppliedDataProcessor", SuppliedDataProcessor);
		Block.Lock();
			
		Set = InformationRegisters.SuppliedAdditionalReportAndDataProcessorInstallationQueueInDataArea.CreateRecordSet();
		Set.Filter.SuppliedDataProcessor.Set(SuppliedDataProcessor);
		Set.Write();
		
		If SuppliedDataProcessorExists Then
			RelevantCommands = Common.ObjectAttributeValue(SuppliedDataProcessor, "Commands").Unload();
			RelevantCommands.Columns.Add("ScheduledJobSchedule", New TypeDescription("ValueList"));
			RelevantCommands.Columns.Add("ScheduledJobUsage", New TypeDescription("Boolean"));
			RelevantCommands.Columns.Add("GUIDScheduledJob", New TypeDescription("UUID"));
			
			For Each RelevantCommand In RelevantCommands Do
				
				JobSetting = Jobs.Find(RelevantCommand.Id, "Id");
				If JobSetting <> Undefined Then
					FillPropertyValues(RelevantCommand, JobSetting, "ScheduledJobSchedule,ScheduledJobUsage");
				EndIf;
				
			EndDo;
			
			// 
			DataProcessorToUseRef = DataProcessorToUse(SuppliedDataProcessor, InstallationDetails.Installation);
			If ValueIsFilled(DataProcessorToUseRef) Then
				DataProcessorToUse = DataProcessorToUseRef.GetObject();
			Else
				DataProcessorToUse = Catalogs.AdditionalReportsAndDataProcessors.CreateItem();
			EndIf;
			
			FillSettingsOfDataProcessorToUse(DataProcessorToUse, SuppliedDataProcessor);
			If ValueIsFilled(Sections) And Sections.Count() > 0 Then
				DataProcessorToUse.Sections.Load(Sections);
			EndIf;
			
			If ValueIsFilled(CatalogsAndDocuments) And CatalogsAndDocuments.Count() > 0 Then
				DataProcessorToUse.Purpose.Load(CatalogsAndDocuments);
				DataProcessorToUse.UseForListForm = CommandsPlacementSettings.UseForListForm;
				DataProcessorToUse.UseForObjectForm = CommandsPlacementSettings.UseForObjectForm;
			EndIf;
			
			DataProcessorToUse.Description = InstallationDetails.Presentation;
			DataProcessorToUse.EmployeeResponsible = EmployeeResponsible;
			
			DataProcessorToUse.AdditionalProperties.Insert("QuickAccess", QuickAccess);
			DataProcessorToUse.AdditionalProperties.Insert("RelevantCommands", RelevantCommands);
			
			If DataProcessorToUse.IsNew() Then
				DataProcessorToUse.SetNewObjectRef(Catalogs.AdditionalReportsAndDataProcessors.GetRef(
					InstallationDetails.Installation));
			EndIf;
			
			// 
			RecordSet = InformationRegisters.UseSuppliedAdditionalReportsAndProcessorsInDataAreas.CreateRecordSet();
			RecordSet.Filter.SuppliedDataProcessor.Set(SuppliedDataProcessor);
			Record = RecordSet.Add();
			Record.SuppliedDataProcessor = SuppliedDataProcessor;
			If DataProcessorToUse.IsNew() Then
				Record.DataProcessorToUse = DataProcessorToUse.GetNewObjectRef();
			Else
				Record.DataProcessorToUse = DataProcessorToUse.Ref;
			EndIf;
			RecordSet.Write();
			
			DataProcessorToUse.Write();
			
			// 
			// 
			If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
				ModuleReportsOptions = Common.CommonModule("ReportsOptions");
				For Each AdditionalReportOption In AdditionalReportOptions Do
					OptionRef = ModuleReportsOptions.ReportVariant(DataProcessorToUse.Ref, AdditionalReportOption.Key);
					If OptionRef <> Undefined Then
						Variant = OptionRef.GetObject();
						Variant.Location.Clear();
						For Each PlacementItem In AdditionalReportOption.Location Do
							OptionPlacement = Variant.Location.Add();
							OptionPlacement.Use = True;
							OptionPlacement.Subsystem = PlacementItem.Section;
							OptionPlacement.Important = PlacementItem.Important;
							OptionPlacement.SeeAlso = PlacementItem.SeeAlso;
						EndDo;
						Variant.Write();
					EndIf;
				EndDo;
			EndIf;
			
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
			
			// 
			Message = ModuleMessagesSaaS.NewMessage(
				MessagesAdditionalReportsAndDataProcessorsControlInterface.AdditionalReportOrDataProcessorInstalledMessage());
			
			Message.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
			Message.Body.Extension = SuppliedDataProcessor.UUID();
			Message.Body.Installation = InstallationDetails.Installation;
			
			ModuleSaaSOperationsCTLCached = Common.CommonModule("SaaSOperationsCTLCached");
			ModuleMessagesSaaS.SendMessage(Message,
				ModuleSaaSOperationsCTLCached.ServiceManagerEndpoint(),  True);
			
			WriteLogEvent(NStr("en = 'Additional built-in reports and data processors.Installation to the data area';",
				Common.DefaultLanguageCode()),
				EventLogLevel.Information,
				,
				SuppliedDataProcessor,
				String(InstallationDetails.Installation));
				
		Else
			
			// 
			// 
			// 
			
			Context = New Structure;
			Context.Insert("QuickAccess", QuickAccess);
			Context.Insert("Jobs", Jobs);
			Context.Insert("Sections", Sections);
			Context.Insert("CatalogsAndDocuments", CatalogsAndDocuments);
			Context.Insert("CommandsPlacementSettings", CommandsPlacementSettings);
			Context.Insert("AdditionalReportOptions", AdditionalReportOptions);
			Context.Insert("EmployeeResponsible", EmployeeResponsible);
			Context.Insert("Presentation", InstallationDetails.Presentation);
			Context.Insert("Installation", InstallationDetails.Installation);
			
			Manager = InformationRegisters.SuppliedAdditionalReportAndDataProcessorInstallationQueueInDataArea.CreateRecordManager();
			Manager.SuppliedDataProcessor = SuppliedDataProcessor;
			Manager.InstallationParameters1 = New ValueStorage(Context);
			Manager.Write();
			
			WriteLogEvent(NStr("en = 'Additional built-in reports and data processors. Installation to the data area is deferred';",
				Common.DefaultLanguageCode()),
				EventLogLevel.Information,
				,
				String(InstallationDetails.Id),
				String(InstallationDetails.Installation));
			
		EndIf;
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	ModuleMessagesExchange = Common.CommonModule("MessagesExchange");
	ModuleMessagesExchange.DeliverMessages();

EndProcedure

// 

// Deletes the supplied additional processing from the current data area.
//
// Parameters:
//  SuppliedDataProcessor - CatalogRef.SuppliedAdditionalReportsAndDataProcessors,
//  IDOfDataProcessorToUse - UUID -  GUID of an existing
//    data area element in the additional reports and Processing reference list.
//
Procedure DeleteSuppliedDataProcessorFromDataArea(Val SuppliedDataProcessor, Val IDOfDataProcessorToUse) Export
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		Return;
	EndIf;
	
	ExceptionText = "";
	SetPrivilegedMode(True);
	BeginTransaction();
	Try
		
		DataProcessorToUse = Catalogs.AdditionalReportsAndDataProcessors.GetRef(
			IDOfDataProcessorToUse);
			
		Block = New DataLock;
		LockItem = Block.Add("Catalog.AdditionalReportsAndDataProcessors");
		LockItem.SetValue("Ref", DataProcessorToUse);
		LockItem = Block.Add("InformationRegister.UseSuppliedAdditionalReportsAndProcessorsInDataAreas");
		LockItem.SetValue("SuppliedDataProcessor", SuppliedDataProcessor);
		Block.Lock();
		
		// 
		RecordSet = InformationRegisters.UseSuppliedAdditionalReportsAndProcessorsInDataAreas.CreateRecordSet();
		RecordSet.Filter.SuppliedDataProcessor.Set(SuppliedDataProcessor);
		
		// 
		DataProcessorObject2 = DataProcessorToUse.GetObject();
		If DataProcessorObject2 <> Undefined Then
			DataProcessorObject2.Delete();
		EndIf;
		
		RecordSet.Write();
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
		
		// 
		Message = ModuleMessagesSaaS.NewMessage(
			MessagesAdditionalReportsAndDataProcessorsControlInterface.AdditionalReportOrDataProcessorDeletedMessage());
		
		Message.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		Message.Body.Extension = SuppliedDataProcessor.UUID();
		Message.Body.Installation = IDOfDataProcessorToUse;
		
		ModuleSaaSOperationsCTLCached = Common.CommonModule("SaaSOperationsCTLCached");
		
		ModuleMessagesSaaS.SendMessage(
			Message,
			ModuleSaaSOperationsCTLCached.ServiceManagerEndpoint());
		
		WriteLogEvent(NStr("en = 'Built-in additional reports and data processors.Delete from the data area';",
			Common.DefaultLanguageCode()),
			EventLogLevel.Information,
			,
			SuppliedDataProcessor,
			String(IDOfDataProcessorToUse));
		
		CommitTransaction();
	Except
		RollbackTransaction();
		ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
	EndTry;
			
	If Not IsBlankString(ExceptionText) Then
		
		WriteLogEvent(NStr("en = 'Built-in additional reports and data processors. An error occurred when deleting from the data area';",
			Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			,
			SuppliedDataProcessor,
			String(IDOfDataProcessorToUse) + Chars.LF + Chars.CR + ExceptionText);
			
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
		ModuleSaaSOperationsCTLCached = Common.CommonModule("SaaSOperationsCTLCached");
		
		// 
		Message = ModuleMessagesSaaS.NewMessage(
			MessagesAdditionalReportsAndDataProcessorsControlInterface.ErrorOfAdditionalReportOrDataProcessorDeletionMessage());
		
		Message.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		Message.Body.Extension = SuppliedDataProcessor.UUID();
		Message.Body.Installation = IDOfDataProcessorToUse;
		Message.Body.ErrorDescription = ExceptionText;
		
		ModuleMessagesSaaS.SendMessage(Message, ModuleSaaSOperationsCTLCached.ServiceManagerEndpoint());
	EndIf;	
	
EndProcedure

// Deletes the supplied additional processing from all data areas
//  of the current information database.
//
// Parameters:
//  SuppliedDataProcessor - CatalogRef.SuppliedAdditionalReportsAndDataProcessors
//
Procedure RevokeSuppliedAdditionalDataProcessor(Val SuppliedDataProcessor) Export
	
	If Not Common.SubsystemExists("CloudTechnology.JobsQueue") Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("Catalog.SuppliedAdditionalReportsAndDataProcessors");
		LockItem.SetValue("Ref", SuppliedDataProcessor);
		Block.Lock();
		
		Installations = InstallationsList(SuppliedDataProcessor);
		For Each Installation In Installations Do
			
			MethodParameters = New Array;
			MethodParameters.Add(SuppliedDataProcessor);
			MethodParameters.Add(Installation.DataProcessorToUse.UUID());
			
			JobParameters = New Structure;
			JobParameters.Insert("MethodName"    , "AdditionalReportsAndDataProcessorsSaaS.DeleteSuppliedDataProcessorFromDataArea");
			JobParameters.Insert("Parameters"    , MethodParameters);
			JobParameters.Insert("RestartCountOnFailure", 3);
			JobParameters.Insert("DataArea", Installation.DataArea);
			
			ModuleJobsQueue = Common.CommonModule("JobsQueue");
			ModuleJobsQueue.AddJob(JobParameters);
			
		EndDo;
		
		DataProcessorObject2 = SuppliedDataProcessor.GetObject();
		DataProcessorObject2.DataExchange.Load = True;
		DataProcessorObject2.Delete();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Performs error handling when additional processing is installed in the data area.
//
// Parameters:
//  SuppliedDataProcessor - CatalogRef.SuppliedAdditionalReportsAndDataProcessors,
//  InstallationID - UUID,
//  ExceptionText - String -  the exception text.
//
Procedure ProcessErrorOfInstallingAdditionalDataProcessorToDataArea(Val SuppliedDataProcessor, Val InstallationID, Val ExceptionText) Export
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		Return;
	EndIf;
	
	WriteLogEvent(NStr("en = 'Additional built-in reports and data processors. An error occurred during installation to the data area';",
		Common.DefaultLanguageCode()),
		EventLogLevel.Error,
		,
		SuppliedDataProcessor,
		String(InstallationID) + Chars.LF + Chars.CR + ExceptionText);
	
	BeginTransaction();		
	Try
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
		
		// 
		Message = ModuleMessagesSaaS.NewMessage(
			MessagesAdditionalReportsAndDataProcessorsControlInterface.ErrorOfAdditionalReportOrDataProcessorInstallationMessage());
			
		Message.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
		Message.Body.Extension = SuppliedDataProcessor.UUID();
		Message.Body.Installation = InstallationID;
		Message.Body.ErrorDescription = ExceptionText;
		
		ModuleSaaSOperationsCTLCached = Common.CommonModule("SaaSOperationsCTLCached");
		ModuleMessagesSaaS.SendMessage(
			Message,
			ModuleSaaSOperationsCTLCached.ServiceManagerEndpoint(),
			True);
	
		CommitTransaction();

	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	ModuleMessagesExchange = Common.CommonModule("MessagesExchange");
	ModuleMessagesExchange.DeliverMessages();
	
EndProcedure

// Returns connection parameters for the supplied additional processing.
//
// Parameters:
//  DataProcessorToUse - CatalogRef.AdditionalReportsAndDataProcessors
//
// Returns:
//   Structure:
//   * DataProcessorStorage - ValueStorage -  contains binary data of an additional report
//                                              or processing,
//   * SafeMode - Boolean -  flag for enabling processing in safe mode.
//
Function DataProcessorToUseAttachmentParameters(Val DataProcessorToUse) Export
	
	SetPrivilegedMode(True);
	
	SuppliedDataProcessor = SuppliedDataProcessor(DataProcessorToUse);
	If ValueIsFilled(SuppliedDataProcessor) Then
		
		Properties = "ObjectName, SafeMode, DataProcessorStorage, GUIDVersion";
		Result = New Structure(Properties);
		FillPropertyValues(Result, Common.ObjectAttributesValues(SuppliedDataProcessor, Properties));
		Return Result;
		
	EndIf;
	
EndFunction

// Generates a list of information security parameters.
//
// Parameters:
//   ParametersTable - ValueTable - 
//
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleSaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "AdditionalReportAndDataProcessorFolderUsageSaaS");
		ModuleSaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "UseSecurityProfilesForARDP");
		ModuleSaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "MinimalARADPScheduledJobIntervalSaaS");
		ModuleSaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "IndependentUsageOfAdditionalReportsAndDataProcessorsSaaS");
		ModuleSaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "AllowScheduledJobsExecutionSaaS");
		
		// 
		// 
		ParameterString = ModuleSaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "AllowScheduledJobsExecutionSaaS");
		ParameterString.Name = "AllowUseAdditionalReportsAndDataProcessorsByScheduledJobsInSaaSMode";
		ParameterString = ModuleSaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "MinimalARADPScheduledJobIntervalSaaS");
		ParameterString.Name = "AdditionalReportsAndDataProcessorsScheduledJobMinIntervalSaaS";
		ParameterString = ModuleSaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "UseSecurityProfilesForARDP");
		ParameterString.Name = "UseSecurityProfilesForARAndDP";
		
	EndIf;
	
EndProcedure

// Called before attempting to write the values of is parameters
// to constants of the same name.
//
// Parameters:
//   ParameterValues - Structure -  the values of the parameters which you want to install.
//   If the parameter value is set in this procedure
//   , the corresponding key Value pair must be removed from the structure.
//
Procedure OnSetIBParametersValues(Val ParameterValues) Export
	
	// 
	// 
	AllowScheduledJobsExecutionSaaS = Undefined;
	MinimalARADPScheduledJobIntervalSaaS = Undefined;
	UseSecurityProfilesForARDP = Undefined;
	
	If ParameterValues.Property("AllowUseAdditionalReportsAndDataProcessorsByScheduledJobsInSaaSMode",
		AllowScheduledJobsExecutionSaaS) Then
		
		ParameterValues.Insert("AllowScheduledJobsExecutionSaaS", AllowScheduledJobsExecutionSaaS);
		ParameterValues.Delete("AllowUseAdditionalReportsAndDataProcessorsByScheduledJobsInSaaSMode");
		
	EndIf;
	
	If ParameterValues.Property("AllowARDPExecutionForScheduledJobSaaS",
		AllowScheduledJobsExecutionSaaS) Then
		
		ParameterValues.Insert("AllowScheduledJobsExecutionSaaS", AllowScheduledJobsExecutionSaaS);
		ParameterValues.Delete("AllowARDPExecutionForScheduledJobSaaS");
		
	EndIf;
	
	If ParameterValues.Property("AdditionalReportsAndDataProcessorsScheduledJobMinIntervalSaaS",
		MinimalARADPScheduledJobIntervalSaaS) Then
		
		ParameterValues.Insert("MinimalARADPScheduledJobIntervalSaaS", MinimalARADPScheduledJobIntervalSaaS);
		ParameterValues.Delete("AdditionalReportsAndDataProcessorsScheduledJobMinIntervalSaaS");
		
	EndIf;
	
	If ParameterValues.Property("UseSecurityProfilesForARAndDP",
		UseSecurityProfilesForARDP) Then
		
		ParameterValues.Insert("UseSecurityProfilesForARDP", UseSecurityProfilesForARDP);
		ParameterValues.Delete("UseSecurityProfilesForARAndDP");
		
	EndIf;
	
EndProcedure

// Event handler for determining the handler's Pseudonyms.
//
// Fills in the matching of method names to their aliases for calling from the task queue
//
// Parameters:
//  NamesAndAliasesMap - Map of KeyAndValue:
//   The key is an alias of the method, for example, clear the data area
//   Value - the method name to call, for example Remoteupdateservice.Clear the data area
//    As a value, you can specify Undefined, in this case it is assumed that the name 
//    matches the alias.
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert("AdditionalReportsAndDataProcessorsSaaS.AppliedDataProcessorSettingsUpdate");
	// 
	NamesAndAliasesMap.Insert("AdditionalReportsAndDataProcessorsSaaS.InstallSuppliedDataProcessorToDataArea", 
		"AdditionalReportsAndDataProcessorsSaaS.InstallSuppliedDataProcessorOnGet");
	NamesAndAliasesMap.Insert("AdditionalReportsAndDataProcessorsSaaS.InstallSuppliedDataProcessorOnGet");
	NamesAndAliasesMap.Insert("AdditionalReportsAndDataProcessorsSaaS.DeleteSuppliedDataProcessorFromDataArea");
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.StartingAdditionalDataProcessors.MethodName);
	
EndProcedure

// Register handlers for delivered data
//
// When you receive a notification about the availability of new shared data, the procedure is called
// Available data from modules registered through getprocesserssuppliable Data.
// A descriptor, the xdto Descriptor Object, is passed to the procedure.
// 
// If the available Data sets the Load argument to True, 
// the data is loaded, and the handle and path to the data file are passed to the procedure 
// Process the new data. The file will be automatically deleted after the procedure is completed.
// If the file was not specified in the service Manager, the argument value is Undefined.
//
// Parameters: 
//   Handlers - See SuppliedDataOverridable.GetHandlersForSuppliedData.Handlers
//
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.DataKind = SuppliedDataKindID();
	Handler.HandlerCode = SuppliedDataKindID();
	Handler.Handler = AdditionalReportsAndDataProcessorsSaaS;
	
EndProcedure

// Fills the passed array with General modules that are handlers
//  for the received message interfaces.
//
// Parameters:
//  HandlersArray - Array
//
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
	
	HandlersArray.Add(AdditionalReportsAndDataProcessorsManagementMessagesInterface);
	
EndProcedure

// Fills the passed array with General modules that are handlers for the interfaces
//  of the sent messages.
//
// Parameters:
//  HandlersArray - Array
//
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export
	
	HandlersArray.Add(MessagesAdditionalReportsAndDataProcessorsControlInterface);
	
EndProcedure

// Called when determining the version of the message interface supported by both the corresponding IB
//  and the current IB. This procedure is intended to implement mechanisms to support backward compatibility
//  with older versions of correspondent information systems.
//
// Parameters:
//  MessageInterface - String -  name of the program interface of the message that the version is defined for
//  ConnectionParameters - Structure -  parameters for connecting to an IB correspondent
//  RecipientPresentation1 - String -  representation of an information security correspondent
//  Result - String -  the designated version. The value of this parameter can be changed in this procedure.
//
Procedure OnDefineCorrespondentInterfaceVersion(Val MessageInterface, Val ConnectionParameters, Val RecipientPresentation1, Result) Export
	
	// 
	// 
	
	If Common.DataSeparationEnabled()
		And Result = Undefined
		And MessageInterface = "ApplicationExtensionsControl" Then
		
		InterfaceToCheck = "RemoteAdministrationControl";
		ModuleMessageInterfacesSaaS = Common.CommonModule("MessageInterfacesSaaS");
		RemoteAdministrationControlInterfaceVersion = ModuleMessageInterfacesSaaS.CorrespondentInterfaceVersion(
			InterfaceToCheck, ConnectionParameters, RecipientPresentation1);
		
		If CommonClientServer.CompareVersions(RemoteAdministrationControlInterfaceVersion, "1.0.2.4") >= 0 Then
			Result = "1.0.0.1";
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region CloudTechnology

#Region ExportImportDataAreas

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.UseSuppliedAdditionalReportsAndProcessorsInDataAreas);
	Types.Add(Metadata.InformationRegisters.SuppliedAdditionalReportAndDataProcessorInstallationQueueInDataArea);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region ScheduledJobsHandlers

// The procedure is called as a routine task after receiving a new version of additional
//  processing from the catalog of additional reports and processes of the service Manager.
//
// Parameters:
//  Ref - CatalogRef.AdditionalReportsAndDataProcessors
//
Procedure AppliedDataProcessorSettingsUpdate(Val Ref) Export
	
	BeginTransaction();
	Try
		SuppliedDataProcessor = SuppliedDataProcessor(Ref);
		If Not ValueIsFilled(SuppliedDataProcessor) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Additional data processor with %1 ID is not built-in.';"),
				String(Ref.UUID()));
		EndIf;
			
		Block = New DataLock;
		LockItem = Block.Add("Catalog.SuppliedAdditionalReportsAndDataProcessors");
		LockItem.SetValue("Ref", SuppliedDataProcessor);
		LockItem.Mode = DataLockMode.Shared;
		LockItem = Block.Add("Catalog.AdditionalReportsAndDataProcessors");
		LockItem.SetValue("Ref", Ref);
		Block.Lock();
		
		DataProcessorToUse = Ref.GetObject();
		SetPrivilegedMode(True);
		FillSettingsOfDataProcessorToUse(DataProcessorToUse, SuppliedDataProcessor.GetObject());
		SetPrivilegedMode(False);
		DataProcessorToUse.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
EndProcedure

#EndRegion

#Region SuppliedData

// 

// Called when a notification of new data is received.
// In the body, check whether the application needs this data, 
// and if so, select the Upload checkbox.
// 
// Parameters:
//   Descriptor   - XDTODataObject - Descriptor.
//   ToImport    - Boolean -  returned.
//
Procedure NewDataAvailable(Val Descriptor, ToImport) Export
	
	If Descriptor.DataType = SuppliedDataKindID() Then
		
		SuppliedDataProcessorDetails = ParseSuppliedDataDescriptor(Descriptor);
		
		Read = New XMLReader();
		Read.SetString(SuppliedDataProcessorDetails.Compatibility);
		Read.MoveToContent();
		XDTOCompatibilityTable = XDTOFactory.ReadXML(Read, XDTOFactory.Type(Read.NamespaceURI, Read.Name));
		CompatibilityTable = ReadCompatibilityTable(XDTOCompatibilityTable);
		
		If CheckSuppliedDataProcessorCompatibility(CompatibilityTable) Then // 
			
			ToImport = True;
			
		Else
			
			ToImport = False;
			
			WriteLogEvent(
				NStr("en = 'Built-in additional reports and data processors.Built-in data processor import canceled';", 
				Common.DefaultLanguageCode()),
				EventLogLevel.Information,
				,
				,
				NStr("en = 'The built-in data processor is not compatible with this configuration';") + Chars.LF + Chars.CR + SuppliedDataProcessorDetails.Compatibility);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Called after calling available Data, allows you to parse the data.
//
// Parameters:
//   Descriptor   - XDTODataObject -  descriptor.
//   PathToFile   - String, Undefined -  full name of the extracted file. The file will be automatically deleted 
//                  after the procedure is completed. If the
//                  file was not specified in the service Manager, the argument value is Undefined.
//
Procedure ProcessNewData(Val Descriptor, Val PathToFile) Export
	
	If Descriptor.DataType = SuppliedDataKindID() Then
		ProcessSuppliedAdditionalReportsAndDataProcessors(Descriptor, PathToFile);
	EndIf;
	
EndProcedure

// Called when data processing is canceled in the event of a failure
//
Procedure DataProcessingCanceled(Val Descriptor) Export 
	
EndProcedure

// 

#EndRegion

#Region UpdateHandlers

// Blocks additional reports and processing in data areas for
// getting new versions from the service Manager.
//
Procedure LockAdditionalReportsAndDataProcessorsForUpdate() Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
		
	SetPrivilegedMode(True);
	
	QueryText =
	"SELECT
	|	SuppliedAdditionalReportsAndDataProcessors.Ref AS Ref
	|FROM
	|	Catalog.SuppliedAdditionalReportsAndDataProcessors AS SuppliedAdditionalReportsAndDataProcessors
	|WHERE
	|	NOT SuppliedAdditionalReportsAndDataProcessors.Ref IN
	|				(SELECT DISTINCT
	|					SuppliedAdditionalReportsAndProcessingCompatibility.Ref
	|				FROM
	|					Catalog.SuppliedAdditionalReportsAndDataProcessors.Compatibility AS SuppliedAdditionalReportsAndProcessingCompatibility
	|				WHERE
	|					SuppliedAdditionalReportsAndProcessingCompatibility.Version = &Version)
	|	AND SuppliedAdditionalReportsAndDataProcessors.ControlCompatibilityWithConfigurationVersions = TRUE";
	Query = New Query(QueryText);
	Query.SetParameter("Version", Metadata.Version);
	
	BeginTransaction();
	Try
		Block = New DataLock;
		Block.Add("Catalog.SuppliedAdditionalReportsAndDataProcessors");
		Block.Lock();
		
		DataProcessorsToLock = Query.Execute().Unload().UnloadColumn("Ref");
		For Each DataProcessorToLock In DataProcessorsToLock Do
			
			SuppliedDataProcessor = DataProcessorToLock.GetObject(); // CatalogObject.SuppliedAdditionalReportsAndDataProcessors -
			SuppliedDataProcessor.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.isDisabled;
			SuppliedDataProcessor.DisableReason = Enums.ReasonsForDisablingAdditionalReportsAndDataProcessorsSaaS.ConfigurationVersionUpdate;
			SuppliedDataProcessor.Write();
			
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Returns the supplied processing that corresponds to the processing used.
//
// Parameters:
//   DataProcessorToUse - CatalogRef.AdditionalReportsAndDataProcessors -  additional processing.
//
// Returns:
//  CatalogRef.SuppliedAdditionalReportsAndDataProcessors
//
Function SuppliedDataProcessor(DataProcessorToUse)
	
	If Not Common.SeparatedDataUsageAvailable() Then
		MessageText = NStr("en = 'You can use function %1 only in sessions with enabled data separation.';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
			"AdditionalReportsAndDataProcessorsSaaS.SuppliedDataProcessor");
		Raise MessageText;
	EndIf;
	
	QueryText = "SELECT TOP 1
	               |	Installations.SuppliedDataProcessor AS SuppliedDataProcessor
	               |FROM
	               |	InformationRegister.UseSuppliedAdditionalReportsAndProcessorsInDataAreas AS Installations
	               |WHERE
	               |	Installations.DataProcessorToUse = &DataProcessorToUse";
	Query = New Query(QueryText);
	Query.SetParameter("DataProcessorToUse", DataProcessorToUse);
	SetPrivilegedMode(True);
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	Return Selection.SuppliedDataProcessor;
	
EndFunction

// Returns the processing used that corresponds to the supplied processing for the current value of the data Area separator.
//
// Parameters:
//  SuppliedDataProcessor - CatalogRef.SuppliedAdditionalReportsAndDataProcessors -  supplied processing.
//
// Returns:
//  CatalogRef.AdditionalReportsAndDataProcessors
//
Function DataProcessorToUse(SuppliedDataProcessor, InstallationID = Undefined)
	
	If Not Common.SeparatedDataUsageAvailable() Then
		MessageText = NStr("en = 'You can use function %1 only in sessions with enabled data separation.';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
			"AdditionalReportsAndDataProcessorsSaaS.DataProcessorToUse");
		Raise MessageText;
	EndIf;
	
	QueryText = "SELECT
	               |	Installations.DataProcessorToUse AS DataProcessorToUse
	               |FROM
	               |	InformationRegister.UseSuppliedAdditionalReportsAndProcessorsInDataAreas AS Installations
	               |WHERE
	               |	Installations.SuppliedDataProcessor = &SuppliedDataProcessor";
	Query = New Query(QueryText);
	Query.SetParameter("SuppliedDataProcessor", SuppliedDataProcessor);
	SetPrivilegedMode(True);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		Return Selection.DataProcessorToUse;
	EndIf;
	
	If InstallationID = Undefined Then
		Return Undefined;	
	EndIf;
	
	DataProcessorToUse = Catalogs.AdditionalReportsAndDataProcessors.GetRef(
		New UUID(InstallationID));
			
	If Common.RefExists(DataProcessorToUse) Then
		Return DataProcessorToUse;
	Else
		Return Undefined;	
	EndIf;
	
EndFunction

// Returns a list of installations for the supplied additional processing in the data area.
//
// Parameters:
//  SuppliedDataProcessor - CatalogRef.SuppliedAdditionalReportsAndDataProcessors -  supplied processing.
//
// Returns:
//  ValueTable:
//    * DataArea - Number -  a number with a length of 7 characters, the number of the data area.
//    * DataProcessorToUse - CatalogRef.AdditionalReportsAndDataProcessors -  additional processing.
//
Function InstallationsList(Val SuppliedDataProcessor)
	
	QueryText =
		"SELECT
		|	Installations.DataAreaAuxiliaryData AS DataArea,
		|	Installations.DataProcessorToUse AS DataProcessorToUse
		|FROM
		|	InformationRegister.UseSuppliedAdditionalReportsAndProcessorsInDataAreas AS Installations
		|WHERE
		|	Installations.SuppliedDataProcessor = &SuppliedDataProcessor";
	Query = New Query(QueryText);
	Query.SetParameter("SuppliedDataProcessor", SuppliedDataProcessor);
	Return Query.Execute().Unload();
	
EndFunction

// Returns the installation queue for the supplied additional processing in the data area.
//
// Parameters:
//  SuppliedDataProcessor - CatalogRef.SuppliedAdditionalReportsAndDataProcessors -  supplied processing.
//
// Returns:
//  ValueTable:
//    * DataArea - Number -  a number with a length of 7 characters, the number of the data area.
//    * InstallationParameters - ValueStorage -  installation queue.
//
Function InstallationsQueue(Val SuppliedDataProcessor)
	
	QueryText =
		"SELECT
		|	Queue.DataAreaAuxiliaryData AS DataArea,
		|	Queue.InstallationParameters1 AS InstallationParameters1
		|FROM
		|	InformationRegister.SuppliedAdditionalReportAndDataProcessorInstallationQueueInDataArea AS Queue
		|WHERE
		|	Queue.SuppliedDataProcessor = &SuppliedDataProcessor";
	Query = New Query(QueryText);
	Query.SetParameter("SuppliedDataProcessor", SuppliedDataProcessor);
	Return Query.Execute().Unload();
	
EndFunction

#Region SuppliedData

// Returns the ID of the type of data to be delivered for additional reports
// and treatments.
//
// Returns:
//   String
//
Function SuppliedDataKindID()
	
	Return "ARandDP"; // 
	
EndFunction

Function SuppliedDataProcessorDetails()
	
	Return New Structure("Id, Version, Manifest, Compatibility");
	
EndFunction

Function ParseSuppliedDataDescriptor(Descriptor)
	
	SuppliedDataProcessorDetails = SuppliedDataProcessorDetails();
	
	For Each SuppliedDataCharacteristic In Descriptor.Properties.Property Do
		
		SuppliedDataProcessorDetails[SuppliedDataCharacteristic.Code] = SuppliedDataCharacteristic.Value;
		
	EndDo;
	
	Return SuppliedDataProcessorDetails;
	
EndFunction

// Monitoring compatibility with the current version of the database configuration
Function CheckSuppliedDataProcessorCompatibility(Val CompatibilityTable)
	
	For Each CompatibilityDeclaration In CompatibilityTable Do
		
		If IsBlankString(CompatibilityDeclaration.VersionNumber) Then
			
			If CompatibilityDeclaration.ConfigarationName = Metadata.Name Then
				Return True;
			EndIf;
			
		Else
			
			If CompatibilityDeclaration.ConfigarationName = Metadata.Name And CompatibilityDeclaration.VersionNumber = Metadata.Version Then
				Return True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

Procedure ProcessSuppliedAdditionalReportsAndDataProcessors(Descriptor, PathToFile)
	
	SetPrivilegedMode(True);
	
	// 
	SuppliedDataProcessorDetails = ParseSuppliedDataDescriptor(Descriptor);
	
	Read = New XMLReader();
	Read.SetString(SuppliedDataProcessorDetails.Manifest);
	Read.MoveToContent();
	AdditionalDataProcessorManifest = XDTOFactory.ReadXML(Read, XDTOFactory.Type(Read.NamespaceURI, Read.Name));
	
	Read = New XMLReader();
	Read.SetString(SuppliedDataProcessorDetails.Compatibility);
	Read.MoveToContent();
	XDTOCompatibilityTable = XDTOFactory.ReadXML(Read, XDTOFactory.Type(Read.NamespaceURI, Read.Name));
	CompatibilityTable = ReadCompatibilityTable(XDTOCompatibilityTable);
	
	WriteLogEvent(NStr("en = 'Built-in additional reports and data processors.Import built-in data processor';", 
		Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		,
		,
		NStr("en = 'Built-in data processor import initiated';") + Chars.LF + Chars.CR + SuppliedDataProcessorDetails.Manifest);
	
	BeginTransaction();
	Try
		// 
		SuppliedDataProcessorRef = Catalogs.SuppliedAdditionalReportsAndDataProcessors.GetRef(
			New UUID(SuppliedDataProcessorDetails.Id));
		If Common.RefExists(SuppliedDataProcessorRef) Then
			Block = New DataLock;
			LockItem = Block.Add("Catalog.SuppliedAdditionalReportsAndDataProcessors");
			LockItem.SetValue("Ref", SuppliedDataProcessorRef);
			Block.Lock();
			
			SuppliedDataProcessor = SuppliedDataProcessorRef.GetObject();
		Else
			SuppliedDataProcessor = Catalogs.SuppliedAdditionalReportsAndDataProcessors.CreateItem();
			SuppliedDataProcessor.SetNewObjectRef(SuppliedDataProcessorRef);
		EndIf;
		
		If ValueIsFilled(SuppliedDataProcessor.DisableReason) Then
			If SuppliedDataProcessor.DisableReason = Enums.ReasonsForDisablingAdditionalReportsAndDataProcessorsSaaS.ConfigurationVersionUpdate Then
				SuppliedDataProcessor.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used;
				SuppliedDataProcessor.DisableReason = Enums.ReasonsForDisablingAdditionalReportsAndDataProcessorsSaaS.EmptyRef();
			EndIf;
		Else
			SuppliedDataProcessor.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used;
		EndIf;
		
		If SuppliedDataProcessor.GUIDVersion = New UUID(SuppliedDataProcessorDetails.Version) Then
			RollbackTransaction();
			Return;
		EndIf;
			
		// 
		SuppliedDataProcessorReportsOptions = Undefined;
		AdditionalReportsAndDataProcessorsSaaSManifest.ReadManifest(
			AdditionalDataProcessorManifest, SuppliedDataProcessor, SuppliedDataProcessor,
			SuppliedDataProcessorReportsOptions);
		
		// 
		DataProcessorBinaryData = New BinaryData(PathToFile);
		SuppliedDataProcessor.DataProcessorStorage = New ValueStorage(
			DataProcessorBinaryData, New Deflation(9));
		
		// 
		SuppliedDataProcessor.ControlCompatibilityWithConfigurationVersions = True;
		SuppliedDataProcessor.Compatibility.Clear();
		For Each CompatibilityInformation In CompatibilityTable Do
			If CompatibilityInformation.ConfigarationName = Metadata.Name Then
				If IsBlankString(CompatibilityInformation.VersionNumber) Then
					SuppliedDataProcessor.ControlCompatibilityWithConfigurationVersions = False;
					Break;
				EndIf;
				TSRow = SuppliedDataProcessor.Compatibility.Add();
				TSRow.Version = CompatibilityInformation.VersionNumber;
			EndIf;
		EndDo;
		
		// 
		SuppliedDataProcessor.GUIDVersion = New UUID(SuppliedDataProcessorDetails.Version);
		SuppliedDataProcessor.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	WriteLogEvent(NStr("en = 'Built-in additional reports and data processors.Built-in data processor is imported';",
		Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		,
		SuppliedDataProcessor.Ref,
		NStr("en = 'Built-in data processor import is completed';") + Chars.LF + Chars.CR + SuppliedDataProcessorDetails.Manifest);
		
	If Not Common.SubsystemExists("CloudTechnology.JobsQueue") Then
		Return;
	EndIf;
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	// 
	DataProcessorsToUse = InstallationsList(SuppliedDataProcessor.Ref);
	For Each DataProcessorInstallation In DataProcessorsToUse Do
		
		MethodParameters = New Array;
		MethodParameters.Add(DataProcessorInstallation.DataProcessorToUse);
		
		JobParameters = New Structure;
		JobParameters.Insert("MethodName"    , "AdditionalReportsAndDataProcessorsSaaS.AppliedDataProcessorSettingsUpdate");
		JobParameters.Insert("Parameters"    , MethodParameters);
		JobParameters.Insert("RestartCountOnFailure", 3);
		JobParameters.Insert("DataArea", DataProcessorInstallation.DataArea);
		
		ModuleJobsQueue.AddJob(JobParameters);
		
		WriteLogEvent(NStr("en = 'Built-in additional reports and data processors.Update of the built-in data processor settings is scheduled';",
			Common.DefaultLanguageCode()),
			EventLogLevel.Information,
			,
			SuppliedDataProcessor.Ref,
			NStr("en = 'Data area:';") + DataProcessorInstallation.DataArea);
		
	EndDo;
	
	// 
	InstallationsQueue = InstallationsQueue(SuppliedDataProcessor.Ref);
	For Each QueueItem In InstallationsQueue Do
		
		Context = QueueItem.InstallationParameters1.Get();
		
		InstallationDetails = New Structure(
			"Id,Presentation,Installation",
			SuppliedDataProcessor.Ref.UUID(),
			Context.Presentation,
			Context.Installation);
		
		MethodParameters = New Array;
		MethodParameters.Add(InstallationDetails);
		MethodParameters.Add(Context.QuickAccess);
		MethodParameters.Add(Context.Jobs);
		MethodParameters.Add(Context.Sections);
		MethodParameters.Add(Context.CatalogsAndDocuments);
		MethodParameters.Add(Context.CommandsPlacementSettings);
		MethodParameters.Add(Context.AdditionalReportOptions);
		MethodParameters.Add(Context.EmployeeResponsible);
		
		JobParameters = New Structure;
		JobParameters.Insert("MethodName", "AdditionalReportsAndDataProcessorsSaaS.InstallSuppliedDataProcessorOnGet");
		JobParameters.Insert("Parameters", MethodParameters);
		JobParameters.Insert("RestartCountOnFailure", 1);
		JobParameters.Insert("DataArea", QueueItem.DataArea);
		ModuleJobsQueue.AddJob(JobParameters);
		
		WriteLogEvent(
			NStr("en = 'Additional built-in reports and data processors.Deferred installation of the built-in data processor to the data area is scheduled';",
			Common.DefaultLanguageCode()),
			EventLogLevel.Information,
			,
			SuppliedDataProcessor.Ref,
			NStr("en = 'Data area:';") + QueueItem.DataArea);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region AdditionalReportsAndDataProcessors

// Returns True if the passed reference to the additional reports and Processing reference list item
// is a report, not a processing.
//
Function IsReport(Val Ref)
	
	Kind = Common.ObjectAttributeValue(Ref, "Kind");
	Return (Kind = Enums.AdditionalReportsAndDataProcessorsKinds.Report) Or (Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport);
	
EndFunction

// The procedure performs a refillingof the reference list item additional Reportsprocessing for the reference list
// item supplied additional Reportsprocessing.
//
// Parameters:
//   DataProcessorToUse - CatalogObject.AdditionalReportsAndDataProcessors
//   SuppliedDataProcessor - CatalogObject.SuppliedAdditionalReportsAndDataProcessors
//
Procedure FillSettingsOfDataProcessorToUse(DataProcessorToUse, SuppliedDataProcessor)
	
	FillPropertyValues(DataProcessorToUse, SuppliedDataProcessor, , "DataProcessorStorage, Owner, Parent, UseForListForm, UseForObjectForm");
	
	CommandsOfDataProcessorToUse = DataProcessorToUse.Commands.Unload();
	SuppliedDataProcessorCommands = SuppliedDataProcessor.Commands.Unload();
	
	// 
	For Each SuppliedDataProcessorCommand In SuppliedDataProcessorCommands Do
		
		CommandOfDataProcessorToUse = CommandsOfDataProcessorToUse.Find(
			SuppliedDataProcessorCommand.Id, "Id");
		
		If CommandOfDataProcessorToUse = Undefined Then
			CommandOfDataProcessorToUse = CommandsOfDataProcessorToUse.Add();
		EndIf;
		
		FillPropertyValues(CommandOfDataProcessorToUse, SuppliedDataProcessorCommand,
			"Id,StartupOption,Presentation,ShouldShowUserNotification,Modifier,Hide");
		
	EndDo;
	
	// 
	// 
	CommandsToRemove = New Array();
	For Each CommandOfDataProcessorToUse In CommandsOfDataProcessorToUse Do
		
		SuppliedDataProcessorCommand = SuppliedDataProcessorCommands.Find(
			CommandOfDataProcessorToUse.Id, "Id");
		
		If SuppliedDataProcessorCommand = Undefined Then
			CommandsToRemove.Add(CommandOfDataProcessorToUse);
		EndIf;
		
	EndDo;
	
	For Each CommandToDelete In CommandsToRemove Do
		CommandsOfDataProcessorToUse.Delete(CommandToDelete);
	EndDo;
	
	DataProcessorToUse.Commands.Load(CommandsOfDataProcessorToUse);
	
	DataProcessorToUse.Permissions.Load(SuppliedDataProcessor.Permissions.Unload());
	
EndProcedure

// 
//
// Parameters:
//  SuppliedDataProcessor - CatalogRef.SuppliedAdditionalReportsAndDataProcessors
//
// Returns:
//   See AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo
//
Function GetRegistrationData(Val SuppliedDataProcessor)
	
	Result = New Structure("Kind, Description, Version, SafeMode, Information, SSLVersion, VariantsStorage");
	
	SetPrivilegedMode(True);
	DataProcessor = SuppliedDataProcessor.GetObject();
	FillPropertyValues(Result, DataProcessor);
	
	// Purpose
	Purpose = New Array;
	For Each AssignmentItem1 In DataProcessor.Purpose Do
		Purpose.Insert(AssignmentItem1.RelatedObject);
	EndDo;
	Result.Insert("Purpose", Purpose);
	
	// Commands
	Result.Insert("Commands", DataProcessor.Commands.Unload(
		, "Presentation, Id, Modifier, ShouldShowUserNotification, Use"));
	
	Return Result;
	
EndFunction

// Reads the compatibility table of the supplied additional processing with configurations
//  and their versions.
//
// Parameters:
//  CompatibilityTable - XDTODataObject -  Xdto object {http://www.1c.ru/1cFresh/ApplicationExtensions/Compatibility/1.0.0.1} CompatibilityList.
//
// Returns:
//  ValueTable:
//    ConfigarationName-String-configuration name,
//    VersionNumber-String - configuration version.
//
Function ReadCompatibilityTable(Val CompatibilityTable)
	
	Result = New ValueTable();
	Result.Columns.Add("ConfigarationName", New TypeDescription("String"));
	Result.Columns.Add("VersionNumber", New TypeDescription("String"));
	
	For Each CompatibilityObject In CompatibilityTable.CompatibilityObjects Do
		
		String = Result.Add();
		FillPropertyValues(String, CompatibilityObject);
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region AdditionalReportsAndDataProcessorsSpecificInSaaS

// This procedure is used to synchronize the values of constants that regulate
//  the use of additional reports and processes in the service model. The procedure
//  must be called whenever any of the constants that govern
//  the use of additional reports and treatments are changed.
//
// Parameters:
//  Constant - String -  name of the changed constant, as specified in the metadata,
//  Value - Boolean -  new value of the changed constant.
//
Procedure RegulatingConstantsValuesSynchronization(Val Constant, Val Value) Export
	
	UsageState = False;
	
	RegulatingConstants = AdditionalReportsAndDataProcessorsSaaSCached.RegulatingConstants();
	
	For Each RegulatingConstant In RegulatingConstants Do
		
		If RegulatingConstant = Constant Then
			ConstantValue = Value;
		Else
			ConstantValue = Constants[RegulatingConstant].Get();
		EndIf;
		
		If ConstantValue Then
			UsageState = True;
		EndIf;
		
	EndDo;
	
	Constants.UseAdditionalReportsAndDataProcessors.Set(UsageState);
	
EndProcedure

// Called when checking whether an additional report can be executed or processed.
//
Procedure CheckCanExecute(Ref)
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
		
	SetPrivilegedMode(True);
	If Not IsSuppliedDataProcessor(Ref) Then
		If Not GetFunctionalOption("IndependentUsageOfAdditionalReportsAndDataProcessorsSaaS") Then
			Raise NStr("en = 'This additional report or data processor cannot be used in SaaS.';");
		EndIf;
		Return;
	EndIf;
			
	CheckCanExecuteSuppliedDataProcessor(Ref);
	
EndProcedure

// This procedure is called to check whether additional processing code
//  can be executed in the information database.
//
Procedure CheckCanExecuteSuppliedDataProcessor(Val DataProcessorToUse)
	
	PublicationParametersOfDataProcessorToUse = Common.ObjectAttributesValues(DataProcessorToUse, "Publication, Version");
	If PublicationParametersOfDataProcessorToUse.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.isDisabled Then
		Raise NStr(
			"en = 'Usage of additional data processor is prohibited. Contact the user with administrative rights in the application.';");
	EndIf;
	
	LockReasonsDetails = AdditionalReportsAndDataProcessorsSaaSCached.ExtendedLockReasonsDetails();
	
	SetPrivilegedMode(True);
	SuppliedDataProcessor = SuppliedDataProcessor(DataProcessorToUse);
	If Not ValueIsFilled(SuppliedDataProcessor) Then
		Return;
	EndIf;
		
	PublicationParametersOfSuppliedDataProcessor = Common.ObjectAttributesValues(SuppliedDataProcessor, "Publication, DisableReason, Version");
	
	// 
	If PublicationParametersOfSuppliedDataProcessor.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.isDisabled Then
		Raise LockReasonsDetails[PublicationParametersOfSuppliedDataProcessor.DisableReason];
	EndIf;
	
	// 
	If PublicationParametersOfDataProcessorToUse.Version <> PublicationParametersOfSuppliedDataProcessor.Version Then
		Raise NStr(
			"en = 'Usage of additional data processor is temporarily unavailable. Try again in a few minutes. We apologize for the inconvenience.';");
	EndIf;
	
EndProcedure

#EndRegion

#Region ConditionalCallsHandlers

Procedure OnSerializeExternalResourceUsagePermissionsOwner(Val Owner, StandardProcessing, Result) Export
	
	If TypeOf(Owner) = Type("CatalogRef.AdditionalReportsAndDataProcessors")
		And Common.SubsystemExists("CloudTechnology.Core") Then
		
		StandardProcessing = False;
		
		Result = XDTOFactory.Create(XDTOFactory.Type("http://www.1c.ru/1cFresh/Application/Permissions/Management/1.0.0.1", "PermissionsOwnerExternalModule"));
		Result.Type = "ApplicationExtension";
		Result.UUID = Owner.UUID();
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
