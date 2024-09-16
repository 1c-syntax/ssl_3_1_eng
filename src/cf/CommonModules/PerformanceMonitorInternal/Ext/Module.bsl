///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Gets the N worst performance measurements for the period.
// 
// Parameters:
//  StartDate - Date -  start of the sampling period.
//  EndDate - Date -  end of the selection period.
//  TopApdexCount - Number -  the number of worst measurements, if no, then all measurements are returned.
//
Function GetAPDEXTop(StartDate, EndDate, AggregationPeriod, TopApdexCount) Export
	Return InformationRegisters.TimeMeasurements.GetAPDEXTop(StartDate, EndDate, AggregationPeriod, TopApdexCount);
EndFunction

// Gets the N worst performance measurements of the system for the period.
// 
// Parameters:
//  StartDate - Date -  start of the sampling period.
//  EndDate - Date -  end of the selection period.
//  TopApdexCount - Number -  the number of worst measurements, if no, then all measurements are returned.
//
Function GetTopTechnologicalAPDEX(StartDate, EndDate, AggregationPeriod, TopApdexCount) Export
	Return InformationRegisters.TimeMeasurementsTechnological.GetAPDEXTop(StartDate, EndDate, AggregationPeriod, TopApdexCount);
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "PerformanceMonitorInternal.InitialFilling1";
	
	Handler = Handlers.Add();
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	Handler.Version = "3.1.3.38";
	Handler.Procedure = "PerformanceMonitorInternal.SetConstantValues31338";
	
EndProcedure

// See CommonOverridable.OnAddSessionParameterSettingHandlers.
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	Handlers.Insert("TimeMeasurementComment", "PerformanceMonitorInternal.SessionParametersSetting");
	
EndProcedure

// See UsersOverridable.OnDefineRoleAssignment
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// 
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.PerformanceSetupAndMonitoring.Name);
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.PerformanceMonitorDataExport;
	Setting.FunctionalOption = Metadata.FunctionalOptions.RunPerformanceMeasurements;
	Setting.UseExternalResources = True;
	Setting.IsParameterized = True;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ClearTimeMeasurements;
	Setting.FunctionalOption = Metadata.FunctionalOptions.RunPerformanceMeasurements;
	Setting.UseExternalResources = True;
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	If SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = CommonModule("SaaSOperations");
		If ModuleSaaSOperations.DataSeparationEnabled() And ModuleSaaSOperations.SeparatedDataUsageAvailable() Then
			Return;
		EndIf;
	EndIf;
		
	DirectoriesForExport = PerformanceMonitorDataExportDirectories();
	If DirectoriesForExport = Undefined Then
		Return;
	EndIf;
	
	URIStructure = PerformanceMonitorClientServer.URIStructure(DirectoriesForExport.FTPExportDirectory);
	DirectoriesForExport.Insert("FTPExportDirectory", URIStructure.ServerName);
	If ValueIsFilled(URIStructure.Port) Then
		DirectoriesForExport.Insert("FTPExportDirectoryPort", URIStructure.Port);
	EndIf;
    
    CoreAvailable = SubsystemExists("StandardSubsystems.Core");
	SafeModeManagerAvailable = SubsystemExists("StandardSubsystems.SecurityProfiles");
	
	If CoreAvailable And SafeModeManagerAvailable Then
		ModuleSafeModeManager = CommonModule("SafeModeManager");
		ModuleCommon = CommonModule("Common");
		PermissionsRequests.Add(
			ModuleSafeModeManager.RequestToUseExternalResources(
				PermissionsToUseServerResources(DirectoriesForExport), 
				ModuleCommon.MetadataObjectID("Constant.RunPerformanceMeasurements")));
	EndIf;
			
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	ClientRunParameters = New Structure("RecordPeriod, RunPerformanceMeasurements");
	
	SetPrivilegedMode(True);
	ClientRunParameters.RecordPeriod = PerformanceMonitor.RecordPeriod();
	ClientRunParameters.RunPerformanceMeasurements = Constants.RunPerformanceMeasurements.Get();

	Parameters.Insert("PerformanceMonitor", New FixedStructure(ClientRunParameters));
	
	If ClientRunParameters.RunPerformanceMeasurements
	   And SessionParameters.TimeMeasurementComment <> Undefined Then
		Return; // 
	EndIf;
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	ModuleReportsOptions = CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.PerformanceMonitor);
EndProcedure

// See CommonOverridable.OnReceiptRecurringClientDataOnServer
Procedure OnReceiptRecurringClientDataOnServer(Parameters, Results) Export
	
	MeasurementsToWrite = Parameters.Get("StandardSubsystems.PerformanceMonitor.MeasurementsToWrite");
	If MeasurementsToWrite = Undefined Then
		Return;
	EndIf;
	
	PerformanceMonitorServerCall.RecordKeyOperationsDuration(MeasurementsToWrite);
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(ParameterName, SpecifiedParameters) Export
	
	// 
	
	If ParameterName = "TimeMeasurementComment" Then
		SessionParameters.TimeMeasurementComment = GetTimeMeasurementComment();
		SpecifiedParameters.Add("TimeMeasurementComment");
		Return;
	EndIf;
EndProcedure

Procedure InitialFilling1() Export
	
	If SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = CommonModule("SaaSOperations");
		If ModuleSaaSOperations.DataSeparationEnabled() Then
			Return;
		EndIf;
	EndIf;
	
	Constants.MeasurementsCountInExportPackage.Set(1000);
	Constants.PerformanceMonitorRecordPeriod.Set(300);
	Constants.KeepMeasurementsPeriod.Set(100);
		
EndProcedure

// Fills in the session parameter "comment timestamp"
// when the program starts.
//
Function GetTimeMeasurementComment()
	
	TimeMeasurementComment = New Map;
	
	SystemInfo = New SystemInfo();
	AppVersion = SystemInfo.AppVersion;
		
	TimeMeasurementComment.Insert("Platform0", AppVersion);
	TimeMeasurementComment.Insert("Conf", Metadata.Synonym);
	TimeMeasurementComment.Insert("ConfVer", Metadata.Version);
	
	DataSeparation = InfoBaseUsers.CurrentUser().DataSeparation;
	DataSeparationValues = New Array;
	If DataSeparation.Count() <> 0 Then
		For Each CurSeparator In DataSeparation Do
			DataSeparationValues.Add(CurSeparator.Value);
		EndDo;
	Else
		DataSeparationValues.Add(0);
	EndIf;
	TimeMeasurementComment.Insert("Separation", DataSeparationValues);
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
	WriteJSON(JSONWriter, TimeMeasurementComment);
		
	Return JSONWriter.Close();
	
EndFunction

// For internal use only.
Function RequestToUseExternalResources(Directories) Export
	If SubsystemExists("StandardSubsystems.SecurityProfiles") 
		And SubsystemExists("StandardSubsystems.Core") Then
		ModuleSafeModeManager = CommonModule("SafeModeManager");
		ModuleCommon = CommonModule("Common");
		Return ModuleSafeModeManager.RequestToUseExternalResources(
					PermissionsToUseServerResources(Directories),
					ModuleCommon.MetadataObjectID("Constant.RunPerformanceMeasurements"));
	EndIf;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Finds and returns a routine task for exporting time measurements.
//
// Returns:
//  ScheduledJob - 
//
Function PerformanceMonitorDataExportScheduledJob() Export
	
	SetPrivilegedMode(True);
	Jobs = ScheduledJobs.GetScheduledJobs(
		New Structure("Metadata", "PerformanceMonitorDataExport"));
	If Jobs.Count() = 0 Then
		Job = ScheduledJobs.CreateScheduledJob(
			Metadata.ScheduledJobs.PerformanceMonitorDataExport);
		Job.Write();
		Return Job;
	Else
		Return Jobs[0];
	EndIf;
		
EndFunction

// Returns the directory of the export file with the measurement results.
//
// Parameters:
//  None
//
// Returns:
//    Structure:
//        "Performexportnftp" - Boolean flag for performing export to FTP
//        "Ftpcatalogexport" - String-FTP export directory
//        "performexportlocal Directory" - Boolean flag for performing export to the local directory
//        "Localcatalogexport" - String-local export directory.
//
Function PerformanceMonitorDataExportDirectories() Export
	
	Job = PerformanceMonitorDataExportScheduledJob();
	Directories = New Structure;
	If Job.Parameters.Count() > 0 Then
		Directories = Job.Parameters[0];
	EndIf;
	
	If TypeOf(Directories) <> Type("Structure") Or Directories.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	ReturnValue = New Structure;
	ReturnValue.Insert("DoExportToFTPDirectory");
	ReturnValue.Insert("FTPExportDirectory");
	ReturnValue.Insert("DoExportToLocalDirectory");
	ReturnValue.Insert("LocalExportDirectory");
	
	JobKeyToItems = New Structure;
	FTPItems = New Array;
	FTPItems.Add("DoExportToFTPDirectory");
	FTPItems.Add("FTPExportDirectory");
	
	LocalItems = New Array;
	LocalItems.Add("DoExportToLocalDirectory");
	LocalItems.Add("LocalExportDirectory");
	
	JobKeyToItems.Insert(PerformanceMonitorClientServer.FTPExportDirectoryJobKey(), FTPItems);
	JobKeyToItems.Insert(PerformanceMonitorClientServer.LocalExportDirectoryJobKey(), LocalItems);
	DoExport = False;
	For Each ItemsKeyName In JobKeyToItems Do
		KeyName = ItemsKeyName.Key;
		ItemsToEdit = ItemsKeyName.Value;
		ItemNumber = 0;
		For Each ItemName In ItemsToEdit Do
			Value = Directories[KeyName][ItemNumber];
			ReturnValue[ItemName] = Value;
			If ItemNumber = 0 Then 
				DoExport = DoExport Or Value;
			EndIf;
			ItemNumber = ItemNumber + 1;
		EndDo;
	EndDo;
	
	Return ReturnValue;
	
EndFunction

// Returns a reference to the "Overall performance" element
// . If there is a predefined "system-wide Performance" element, this element is returned.
// Otherwise, an empty link is returned.
//
// Parameters:
//  None
// Returns:
//  CatalogRef.KeyOperations
//
Function GetOverallSystemPerformanceItem() Export
	
	PredefinedKO = Metadata.Catalogs.KeyOperations.GetPredefinedNames();
	HasPredefinedItem = ?(PredefinedKO.Find("OverallSystemPerformance") <> Undefined, True, False);
	
	QueryText = 
	"SELECT TOP 1
	|	KeyOperations.Ref,
	|	2 AS Priority
	|FROM
	|	Catalog.KeyOperations AS KeyOperations
	|WHERE
	|	KeyOperations.Name = ""OverallSystemPerformance""
	|	AND NOT KeyOperations.DeletionMark
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	VALUE(Catalog.KeyOperations.EmptyRef),
	|	3
	|
	|ORDER BY
	|	Priority";
	
	If HasPredefinedItem Then
		QueryTextPredefinedItem = 
		"SELECT TOP 1
		|	KeyOperations.Ref,
		|	1 AS Priority
		|FROM
		|	Catalog.KeyOperations AS KeyOperations
		|WHERE
		|	KeyOperations.PredefinedDataName = ""OverallSystemPerformance""
		|	AND NOT KeyOperations.DeletionMark";
		QueryText = StrTemplate("%1 UNION ALL %2", QueryTextPredefinedItem, QueryText); 
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText; 
	Query.SetParameter("KeyOperations", PredefinedKO);
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	Selection.Next();
	
	Return Selection.Ref;
	
EndFunction

Procedure SetConstantValues31338() Export
	
	If Constants.KeepMeasurementsPeriod.Get() = 3650 Then
		Constants.KeepMeasurementsPeriod.Set(100);
	EndIf;
				
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Generates an array of permissions for exporting measurement data.
//
// Parameters-Export Catalogs-Structure
//
// Returns:
//  Array
//
Function PermissionsToUseServerResources(Directories)
	
	Permissions = New Array;
	
	CoreAvailable = SubsystemExists("StandardSubsystems.Core");
	If CoreAvailable Then
		ModuleSafeModeManager = CommonModule("SafeModeManager");
		If Directories <> Undefined Then
			If Directories.Property("DoExportToLocalDirectory") And Directories.DoExportToLocalDirectory = True Then
				If Directories.Property("LocalExportDirectory") And ValueIsFilled(Directories.LocalExportDirectory) Then
					Item = ModuleSafeModeManager.PermissionToUseFileSystemDirectory(
						Directories.LocalExportDirectory,
						True,
						True,
						NStr("en = 'A network directory to import samples to.';"));
					Permissions.Add(Item);
				EndIf;
			EndIf;
			
			If Directories.Property("DoExportToFTPDirectory") And Directories.DoExportToFTPDirectory = True Then
				If Directories.Property("FTPExportDirectory") And ValueIsFilled(Directories.FTPExportDirectory) Then
					Item = ModuleSafeModeManager.PermissionToUseInternetResource(
						"FTP",
						Directories.FTPExportDirectory,
						?(Directories.Property("FTPExportDirectoryPort"), Directories.FTPExportDirectoryPort, Undefined),
						NStr("en = 'A FTP directory to import samples to.';"));
					Permissions.Add(Item);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	Return Permissions;
EndFunction

#Region CommonCopy

// Returns True if the "functional" subsystem exists in the configuration.
// It is intended for implementing an optional subsystem call (conditional call).
//
// The" functional "subsystem has the" Include in command interface " checkbox unchecked.
//
// Parameters:
//  FullSubsystemName - String -  the full name of the subsystem metadata object
//                        without the words " Subsystem."and case-sensitive.
//                        For example: "Standard subsystems.Variants of reports".
//
// Example:
//
//  If General Purpose.Subsystems Exist ("Standard Subsystems.Varietythat") Then
//  	Modellvariante = Observatsionnoe.Abdimomun (The"Varietythat");
//  	Modellvariante.<Method name> ();
//  ends If;
//
// Returns:
//  Boolean
//
Function SubsystemExists(FullSubsystemName) Export
	
	If CoreAvailable() Then
		ModuleCommon = CalculateInSafeMode("Common");
		Return ModuleCommon.SubsystemExists(FullSubsystemName);
	Else
		SubsystemsNames = PerformanceMonitorCached.SubsystemsNames();
		Return SubsystemsNames.Get(FullSubsystemName) <> Undefined;
	EndIf;
	
EndFunction

// Returns General parameters of the basic functionality.
//
// Returns: 
//  Structure:
//      * PersonalSettingsFormName            - String - 
//      * MinPlatformVersion1    - String - 
//                                                           
//      * MustExit               - Boolean -  the initial value is False.
//      * AskConfirmationOnExit - Boolean -  by default, True. If set to False, 
//                                                                  you will not
//                                                                  be prompted for confirmation when the program is shut down, unless you explicitly allow it in
//                                                                  the personal settings of the program.
//      * DisableMetadataObjectsIDs - Boolean -  disables filling in the object IDs of Metadata and extension object IDs directories
//              , as well as the procedure for uploading and loading in the rib nodes.
//              For partial embedding of individual library functions in the configuration without setting up support.
//      * DisabledSubsystems                     - Map of KeyAndValue -  allows you to virtually disable
//                                                                  subsystems for testing purposes.
//                                                                  If the subsystem is disabled, then the method is general purpose.Modestamente
//                                                                  will return False. According to the key-name of the disabled subsystem,
//                                                                  the value must be set to True.
//
Function CommonCoreParameters() Export
	
	CommonParameters = New Structure;
	CommonParameters.Insert("DisabledSubsystems", New Map);
	
	Return CommonParameters;
	
EndFunction

Function CoreAvailable()
	
	StandardSubsystemsAvailable = Metadata.Subsystems.Find("StandardSubsystems");
	
	If StandardSubsystemsAvailable = Undefined Then
		Return False;
	Else
		If StandardSubsystemsAvailable.Subsystems.Find("Core") = Undefined Then
			Return False;
		Else
			Return True;
		EndIf;
	EndIf;
	
EndFunction

// Generates and outputs a message that can be associated with a form control.
//
// Parameters:
//  MessageToUserText - String -  message text.
//  DataKey - AnyRef -  the object or key of the database record that this message refers to.
//  Field - String - 
//  DataPath - String -  data path (the path to the requisite shape).
//  Cancel - Boolean -  the output parameter is always set to True.
//
// Example:
//
//  1. to display a message in the field of the managed form associated with the object's details:
//  General Assignationclient.Inform the user(
//   NSTR ("ru = 'Error message.'"), ,
//   "Politikunterricht",
//   "Object");
//
//  Alternative use in the form of an object:
//  General purpose Client.Inform the user(
//   NSTR ("ru = 'Error message.'"), ,
//   "Object.Politikunterricht");
//
//  2. To display the message next to the managed form, associated with the requisite forms:
//  Observationnelle.Inform the user(
//   NSTR ("ru = 'Error message.'"), ,
//   "Markwesterby");
//
//  3. to display a message associated with an object in the information database:
//  General purpose Client.Inform the user(
//   NSTR ("ru = 'Error message.'"), Object Of The Information Base, "Responsible",, Refusal);
//
//  4. to display the message by reference to the object of the information database:
//  General purpose Client.Inform the user(
//   NSTR ("ru = 'Error message.'") The Link, ,,,, Failure);
//
//  Cases of incorrect use:
//   1. Passing the key Data and path Data parameters simultaneously.
//   2. Passing a different type of value in the key Data parameter.
//   3. Installation without field installation (and/or datapath).
//
Procedure MessageToUser( 
	Val MessageToUserText,
	Val DataKey = Undefined,
	Val Field = "",
	Val DataPath = "",
	Cancel = False) Export
	
	IsObject = False;
	
	If DataKey <> Undefined
		And XMLTypeOf(DataKey) <> Undefined Then
		
		ValueTypeAsString = XMLTypeOf(DataKey).TypeName;
		IsObject = StrFind(ValueTypeAsString, "Object.") > 0;
	EndIf;
	
	Message = New UserMessage;
	Message.Text = MessageToUserText;
	Message.Field = Field;
	
	If IsObject Then
		Message.SetData(DataKey);
	Else
		Message.DataKey = DataKey;
	EndIf;
	
	If Not IsBlankString(DataPath) Then
		Message.DataPath = DataPath;
	EndIf;
	
	Message.Message();
	
	Cancel = True;
	
EndProcedure

// Returns a reference to the shared module by name.
//
// Parameters:
//  Name          - String - :
//                 
//                 
//
// Returns:
//  CommonModule
//
Function CommonModule(Name) Export
	
	If CoreAvailable() Then
		ModuleCommon = CalculateInSafeMode("Common");
		Module = ModuleCommon.CommonModule(Name);
	Else
		If Metadata.CommonModules.Find(Name) <> Undefined Then
			Module = CalculateInSafeMode(Name);
		ElsIf StrOccurrenceCount(Name, ".") = 1 Then
			Return ServerManagerModule(Name);
		Else
			Module = Undefined;
		EndIf;
		
		If TypeOf(Module) <> Type("CommonModule") Then
			ExceptionMessage = NStr("en = 'Common module %1 is not found.';");
			Raise StrReplace(ExceptionMessage, "%1", Name);
		EndIf;
	EndIf;
	
	Return Module;
	
EndFunction

// Returns the backend module Manager by the name of the object.
Function ServerManagerModule(Name)
	ObjectFound = False;
	
	NameParts = StrSplit(Name, ".");
	If NameParts.Count() = 2 Then
		
		KindName = Upper(NameParts[0]);
		ObjectName = NameParts[1];
		
		If KindName = Upper(ConstantsTypeName()) Then
			If Metadata.Constants.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(InformationRegistersTypeName()) Then
			If Metadata.InformationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(AccumulationRegistersTypeName()) Then
			If Metadata.AccumulationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(AccountingRegistersTypeName()) Then
			If Metadata.AccountingRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(CalculationRegistersTypeName()) Then
			If Metadata.CalculationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(CatalogsTypeName()) Then
			If Metadata.Catalogs.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(DocumentsTypeName()) Then
			If Metadata.Documents.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(ReportsTypeName()) Then
			If Metadata.Reports.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(DataProcessorsTypeName()) Then
			If Metadata.DataProcessors.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(BusinessProcessesTypeName()) Then
			If Metadata.BusinessProcesses.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(DocumentJournalsTypeName()) Then
			If Metadata.DocumentJournals.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(TasksTypeName()) Then
			If Metadata.Tasks.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(ChartsOfAccountsTypeName()) Then
			If Metadata.ChartsOfAccounts.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(ExchangePlansTypeName()) Then
			If Metadata.ExchangePlans.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(ChartsOfCharacteristicTypesTypeName()) Then
			If Metadata.ChartsOfCharacteristicTypes.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper(ChartsOfCalculationTypesTypeName()) Then
			If Metadata.ChartsOfCalculationTypes.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not ObjectFound Then
		ExceptionMessage = NStr("en = 'Metadata object %1 not found.
			|It might be missing or it does not support getting the manager module.';");
		Raise StrReplace(ExceptionMessage, "%1", Name);
	EndIf;
	
	Module = CalculateInSafeMode(Name);
	
	Return Module;
EndFunction

// Returns a value for identifying the General "data Registers" type.
//
// Returns:
//  String
//
Function InformationRegistersTypeName()
	
	Return "InformationRegisters";
	
EndFunction

// Returns a value for identifying the General "accumulation Registers" type.
//
// Returns:
//  String
//
Function AccumulationRegistersTypeName()
	
	Return "AccumulationRegisters";
	
EndFunction

// Returns a value for identifying the General "accounting Registers" type.
//
// Returns:
//  String
//
Function AccountingRegistersTypeName()
	
	Return "AccountingRegisters";
	
EndFunction

// Returns a value for identifying the General "calculation Registers" type.
//
// Returns:
//  String
//
Function CalculationRegistersTypeName()
	
	Return "CalculationRegisters";
	
EndFunction

// Returns a value for identifying the General "Documents" type.
//
// Returns:
//  String
//
Function DocumentsTypeName()
	
	Return "Documents";
	
EndFunction

// Returns a value for identifying the General "Directories" type.
//
// Returns:
//  String
//
Function CatalogsTypeName()
	
	Return "Catalogs";
	
EndFunction

// Returns a value for identifying the General "Reports" type.
//
// Returns:
//  String
//
Function ReportsTypeName()
	
	Return "Reports";
	
EndFunction

// Returns a value for identifying the General "Processing" type.
//
// Returns:
//  String
//
Function DataProcessorsTypeName()
	
	Return "DataProcessors";
	
EndFunction

// Returns a value for identifying the General "exchange Plan" type.
//
// Returns:
//  String
//
Function ExchangePlansTypeName()
	
	Return "ExchangePlans";
	
EndFunction

// Returns the value for identifying the shared-type Plans "types of characteristics."
//
// Returns:
//  String
//
Function ChartsOfCharacteristicTypesTypeName()
	
	Return "ChartsOfCharacteristicTypes";
	
EndFunction

// Returns a value for identifying the General "Business processes" type.
//
// Returns:
//  String
//
Function BusinessProcessesTypeName()
	
	Return "BusinessProcesses";
	
EndFunction

// Returns a value for identifying the General "Task" type.
//
// Returns:
//  String
//
Function TasksTypeName()
	
	Return "Tasks";
	
EndFunction

// Returns the value for identifying the shared-type "chart of accounts".
//
// Returns:
//  String
//
Function ChartsOfAccountsTypeName()
	
	Return "ChartsOfAccounts";
	
EndFunction

// Returns a value for identifying the General type "calculation type Plans".
//
// Returns:
//  String
//
Function ChartsOfCalculationTypesTypeName()
	
	Return "ChartsOfCalculationTypes";
	
EndFunction

// Returns a value for identifying the General "Constant" type.
//
// Returns:
//  String
//
Function ConstantsTypeName()
	
	Return "Constants";
	
EndFunction

// Returns a value for identifying the General "document Logs" type.
//
// Returns:
//  String
//
Function DocumentJournalsTypeName()
	
	Return "DocumentJournals";
	
EndFunction

Function DefaultLanguageCode() Export
	If SubsystemExists("StandardSubsystems.Core") Then
		ModuleCommon = CommonModule("Common");
		Return ModuleCommon.DefaultLanguageCode();
	EndIf;	
	Return Metadata.DefaultLanguage.LanguageCode;
EndFunction

// Parameters:
//  CatalogManager - CatalogManager.KeyOperations
//  Ref - CatalogRef.KeyOperations
//
// Returns:
//  CatalogObject.KeyOperations
//
Function ServiceItem(CatalogManager, Ref = Undefined) Export
	
	If Ref = Undefined Then
		CatalogItem = CatalogManager.CreateItem();
	Else
		CatalogItem = Ref.GetObject();
		If CatalogItem = Undefined Then
			Return Undefined;
		EndIf;
	EndIf;
	
	CatalogItem.AdditionalProperties.Insert("DontControlObjectsToDelete");
	CatalogItem.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	CatalogItem.DataExchange.Recipients.AutoFill = False;
	CatalogItem.DataExchange.Load = True;
	
	Return CatalogItem;
	
EndFunction

// Parameters:
//  RegisterManager - InformationRegisterManager.TimeMeasurements
//                   - InformationRegisterManager.TimeMeasurementsTechnological
//
// Returns:
//  InformationRegisterRecordSet.TimeMeasurements
//  
//
Function ServiceRecordSet(RegisterManager) Export
	
	RecordSet = RegisterManager.CreateRecordSet();
	RecordSet.AdditionalProperties.Insert("DontControlObjectsToDelete");
	RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	RecordSet.DataExchange.Recipients.AutoFill = False;
	RecordSet.DataExchange.Load = True;
	
	Return RecordSet;
	
EndFunction

#EndRegion

#Region SafeModeCopy

// Evaluates the passed expression by first setting safe code execution mode
//  and safe data separation mode for all delimiters present in the configuration.
//  As a result, when evaluating the expression:
//   - attempts to set the privileged mode are ignored,
//   - all external ones are forbidden (in relation to the 1C platform:Enterprise) action (COM,
//       loading an external component, launch external applications and operating system commands,
//       access to the file system and Internet resources),
//   - do not disable the use of delimiters session
//   - do not change the values of the delimiters of a session (if the separation by the separator does not
//       is conditionally disabled)
//   - do not modify objects that control the condition of the conditional split.
//
// Parameters:
//  Expression - String -  the expression that you want to calculate. For Example, "Mymodule.MyFunction (Parameters)".
//  Parameters - Arbitrary -  the value of this parameter can be passed as the value
//    that is required for calculating the expression (in the text of the expression, this
//    value must be referred to as the name of the parameters variable).
//
// Returns: 
//   Arbitrary - 
//
Function CalculateInSafeMode(Val Expression, Val Parameters = Undefined)
	
	SetSafeMode(True);
	
	SeparatorArray = PerformanceMonitorCached.ConfigurationSeparators();
	
	For Each SeparatorName In SeparatorArray Do
		
		SetDataSeparationSafeMode(SeparatorName, True);
		
	EndDo;
	
	Return Eval(Expression);
	
EndFunction

#EndRegion

#EndRegion
