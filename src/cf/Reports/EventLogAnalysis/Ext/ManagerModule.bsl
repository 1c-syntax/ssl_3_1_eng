///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// See ReportsOptionsOverridable.BeforeAddReportCommands.
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Return;
	EndIf;
	
	If Not AccessRight("View", Metadata.Reports.EventLogAnalysis)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	AddCommand = False;
	
	If Parameters.FormName = "Catalog.Users.Form.ListForm" Then
		
		Command = ReportsCommands.Add();
		Command.Presentation = NStr("en = 'Summary user activity';");
		Command.VariantKey = "UsersActivityAnalysis";
		Command.MultipleChoice = True;
		Command.Manager = "Report.EventLogAnalysis";
		Command.OnlyInAllActions = True;
		Command.Importance = "SeeAlso";
		
		If Users.IsDepartmentUsed() Then
			Command = ReportsCommands.Add();
			Command.Presentation = NStr("en = 'Department activity analysis';");
			Command.VariantKey = "DepartmentActivityAnalysis";
			Command.MultipleChoice = True;
			Command.Manager = "Report.EventLogAnalysis";
			Command.OnlyInAllActions = True;
			Command.Importance = "SeeAlso";
		EndIf;
		
		AddCommand = True;
		
	ElsIf Parameters.FormName = "Catalog.Users.Form.ItemForm" Then
		AddCommand = True;
	EndIf;
	
	If Not AddCommand Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.Presentation = NStr("en = 'User activity';");
	Command.VariantKey = "UserActivity";
	Command.MultipleChoice = False;
	Command.Manager = "Report.EventLogAnalysis";
	Command.OnlyInAllActions = True;
	Command.Importance = "SeeAlso";
	
EndProcedure

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ReportSettings.DefineFormSettings = True;
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	SubsystemForAdministration = Common.MetadataObjectByFullName(
		"Subsystem" + "." + "Administration");
	SubsystemForMonitoring = Common.MetadataObjectByFullName(
		"Subsystem" + "." + "Administration" + "." + "Subsystem" + "." + "UserMonitoring");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UsersActivityAnalysis");
	If SubsystemForMonitoring <> Undefined Then
		OptionSettings.Location.Insert(SubsystemForMonitoring, "");
	EndIf;
	OptionSettings.LongDesc =
		NStr("en = 'User activity (total load and affected objects).';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "DepartmentActivityAnalysis");
	OptionSettings.Enabled = Users.IsDepartmentUsed();
	If SubsystemForMonitoring <> Undefined Then
		OptionSettings.Location.Insert(SubsystemForMonitoring, "");
	EndIf;
	OptionSettings.LongDesc =
		NStr("en = 'Department activity (total load and affected objects).';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UserActivity");
	If SubsystemForMonitoring <> Undefined Then
		OptionSettings.Location.Insert(SubsystemForMonitoring, "");
	EndIf;
	OptionSettings.LongDesc =
		NStr("en = 'Objects affected by user activities (detailed).';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "EventLogMonitor");
	OptionSettings.SearchSettings.TemplatesNames = "EvengLogErrorReportTemplate";
	If SubsystemForAdministration <> Undefined Then
		OptionSettings.Location.Insert(SubsystemForAdministration, "");
	EndIf;
	OptionSettings.LongDesc = NStr("en = 'Critical events in the system event log.';");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ScheduledJobsDuration");
	OptionSettings.SearchSettings.TemplatesNames = "ScheduledJobsDuration, ScheduledJobsDetails";
	OptionSettings.Enabled = Not Common.DataSeparationEnabled();
	If SubsystemForAdministration <> Undefined Then
		OptionSettings.Location.Insert(SubsystemForAdministration, "");
	EndIf;
	OptionSettings.LongDesc = NStr("en = 'Job schedules.';");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Private

// The function gets information about user activity from the log
// for the transmitted period.
//
// Parameters:
//    ReportParameters - Structure:
//    * StartDate          - Date   -  the beginning of the period for which information will be collected.
//    * EndDate       - Date   -  the end of the period for which information will be collected.
//    * User        - String -  name of the user to use for analysis.
//                                     For the "user Activity" report option.
//    * UsersAndGroups - ValueList -  where the value is the group(s) of users and(or)
//                                     the user (s) to analyze.
//                                     For the "user activity Analysis" version of the report.
//    * ReportVariant       - String -  "User activity" or "user activity Analysis".
//    * OutputTasks      - Boolean -  get or not information about issues from the log.
//    * OutputCatalogs - Boolean -  get or not information about reference books from the registration log.
//    * OutputDocuments   - Boolean -  get or not document information from the registration log.
//    * OutputBusinessProcesses - Boolean -  get or not information about business processes from the log.
//
// Returns:
//  ValueTable - 
//     
//
Function EventLogData1(ReportParameters) Export
	
	// 
	StartDate = ReportParameters.StartDate;
	EndDate = ReportParameters.EndDate;
	User = ReportParameters.User;
	UsersAndGroups = ReportParameters.UsersAndGroups;
	Department = ReportParameters.Department;
	ReportVariant = ReportParameters.ReportVariant;
	
	If ReportVariant = "UserActivity" Then
		ShouldOutputUtilityUsers = True;
		OutputBusinessProcesses = ReportParameters.OutputBusinessProcesses;
		OutputTasks = ReportParameters.OutputTasks;
		OutputCatalogs = ReportParameters.OutputCatalogs;
		OutputDocuments = ReportParameters.OutputDocuments;
	Else
		ShouldOutputUtilityUsers = ReportParameters.ShouldOutputUtilityUsers;
		OutputCatalogs = True;
		OutputDocuments = True;
		OutputBusinessProcesses = False;
		OutputTasks = False;
	EndIf;
	
	// 
	RawData = New ValueTable();
	RawData.Columns.Add("Date", New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date)));
	RawData.Columns.Add("Week", New TypeDescription("String", , New StringQualifiers(10)));
	RawData.Columns.Add("User");
	RawData.Columns.Add("WorkHours", New TypeDescription("Number", New NumberQualifiers(15,4)));
	RawData.Columns.Add("StartsCount", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("DocumentsCreated", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("CatalogsCreated", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("DocumentsChanged", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("BusinessProcessesCreated",	New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("TasksCreated", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("BusinessProcessesChanged", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("TasksChanged", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("CatalogsChanged",	New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("Errors1", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("Warnings", New TypeDescription("Number", New NumberQualifiers(10)));
	RawData.Columns.Add("ObjectKind", New TypeDescription("String", , New StringQualifiers(50)));
	RawData.Columns.Add("CatalogDocumentObject");
	
	// 
	ConcurrentSessionsData = New ValueTable();
	ConcurrentSessionsData.Columns.Add("ConcurrentUsersDate",
		New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date)));
	ConcurrentSessionsData.Columns.Add("ConcurrentUsers",
		New TypeDescription("Number", New NumberQualifiers(10)));
	ConcurrentSessionsData.Columns.Add("ConcurrentUsersList");
	
	EventLogData = New ValueTable;
	
	Levels = New Array;
	Levels.Add(EventLogLevel.Information);
	
	Events = New Array;
	Events.Add("_$Session$_.Start"); //  
	Events.Add("_$Session$_.Finish"); //    
	Events.Add("_$Data$_.New"); // 
	Events.Add("_$Data$_.Update"); // 
	
	ApplicationName = New Array;
	ApplicationName.Add("1CV8C");
	ApplicationName.Add("WebClient");
	ApplicationName.Add("1CV8");
	ApplicationName.Add("BackgroundJob");
	
	UserFilter = New Array;
	
	// 
	If ReportVariant = "UserActivity" Then
		UserFilter.Add(UserForSelection(User));
	ElsIf ReportVariant = "DepartmentActivityAnalysis" Then
		FillUsersForAnalysisFromDepartment(UserFilter, Department);
	Else
		FillUsersForAnalysis(UserFilter, UsersAndGroups);
	EndIf;
	
	DatesInServerTimeZone = CommonClientServer.StructureProperty(ReportParameters, "DatesInServerTimeZone", False);
	If DatesInServerTimeZone Then
		ServerTimeOffset = 0;
	Else
		ServerTimeOffset = EventLog.ServerTimeOffset();
	EndIf;
	
	EventLogFilter = New Structure;
	EventLogFilter.Insert("StartDate", StartDate + ServerTimeOffset);
	EventLogFilter.Insert("EndDate", EndDate + ServerTimeOffset);
	EventLogFilter.Insert("ApplicationName", ApplicationName);
	EventLogFilter.Insert("Level", Levels);
	EventLogFilter.Insert("Event", Events);
	
	If UserFilter.Count() = 0 Then
		Return New Structure("UsersActivityAnalysis, ConcurrentSessionsData, ReportIsBlank", RawData, ConcurrentSessionsData, True);
	EndIf;
	
	If UserFilter.Find("AllUsers") = Undefined Then
		EventLogFilter.Insert("User", UserFilter);
	Else
		UserFilter = Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	UnloadEventLog(EventLogData, EventLogFilter);
	SetPrivilegedMode(False);
	
	ReportIsBlank = (EventLogData.Count() = 0);
	
	// 
	UsersIDsMap = UsersUUIDs(EventLogData,
		ShouldOutputUtilityUsers);
	
	CurrentSession        = Undefined;
	WorkHours         = 0;
	StartsCount  = 0;
	DocumentsCreated   = 0;
	CatalogsCreated = 0;
	DocumentsChanged  = 0;
	CatalogsChanged= 0;
	
	Sessions = New ValueTable;
	Sessions.Columns.Add("SessionNumber");
	Sessions.Columns.Add("StartingEvent");
	Sessions.Columns.Add("FinishingEvent");
	Sessions.Columns.Add("User");
	Sessions.Columns.Add("SessionFirstEventDate");
	Sessions.Columns.Add("SessionLastEventDate");
	Sessions.Indexes.Add("SessionNumber");
	
	// 
	For Each EventLogDataRow In EventLogData Do
		DocumentsCreated       = 0;
		CatalogsCreated     = 0;
		DocumentsChanged      = 0;
		CatalogsChanged    = 0;
		BusinessProcessesCreated  = 0;
		BusinessProcessesChanged = 0;
		TasksChanged           = 0;
		TasksCreated            = 0;
		
		EventLogDataRow.Date = EventLogDataRow.Date - ServerTimeOffset;
		
		If Not ValueIsFilled(EventLogDataRow.Session)
			Or Not ValueIsFilled(EventLogDataRow.Date) Then
			Continue;
		EndIf;
		
		UsernameRef = UsersIDsMap[EventLogDataRow.User];
		If UsernameRef = Undefined Then
			Continue;
		EndIf;
		
		// 
		Session = Sessions.Find(EventLogDataRow.Session, "SessionNumber");
		If EventLogDataRow.Event = "_$Session$_.Start" Then
			If Session <> Undefined Then
				Session.SessionNumber = Undefined;
			EndIf;
			Session = Sessions.Add();
			Session.SessionNumber   = EventLogDataRow.Session;
			Session.StartingEvent = EventLogDataRow;
			Session.User  = UsernameRef;
			
		ElsIf EventLogDataRow.Event = "_$Session$_.Finish" Then
			If Session = Undefined Then
				Session = Sessions.Add();
				Session.User = UsernameRef;
			EndIf;
			Session.SessionNumber = Undefined;
			Session.FinishingEvent = EventLogDataRow;
		Else
			If Session = Undefined Then
				Session = Sessions.Add();
				Session.User = UsernameRef;
				Session.SessionFirstEventDate = EventLogDataRow.Date
			EndIf;
			Session.SessionLastEventDate = EventLogDataRow.Date;
		EndIf;
		
		// 
		If EventLogDataRow.Event = "_$Data$_.New" Then
			
			If StrFind(EventLogDataRow.Metadata, "Document.") > 0 
				And OutputDocuments Then
				ObjectKind = EventLogDataRow.MetadataPresentation;
				CatalogDocumentObject = EventLogDataRow.Data;
				DocumentsCreated = DocumentsCreated + 1;
				SourceDataString = RawData.Add();
				SourceDataString.Date		  = EventLogDataRow.Date;
				SourceDataString.User = UsernameRef;
				SourceDataString.ObjectKind = ObjectKind;
				SourceDataString.DocumentsCreated = DocumentsCreated;
				SourceDataString.CatalogDocumentObject = CatalogDocumentObject;
				SourceDataString.Week 	  = WeekOfYearString(EventLogDataRow.Date); 
			EndIf;
			
			If StrFind(EventLogDataRow.Metadata, "Catalog.") > 0
				And OutputCatalogs Then
				ObjectKind = EventLogDataRow.MetadataPresentation;
				CatalogDocumentObject = EventLogDataRow.Data;
				CatalogsCreated = CatalogsCreated + 1;
				SourceDataString = RawData.Add();
				SourceDataString.Date		  = EventLogDataRow.Date;
				SourceDataString.User = UsernameRef;
				SourceDataString.ObjectKind = ObjectKind;
				SourceDataString.CatalogsCreated = CatalogsCreated;
				SourceDataString.CatalogDocumentObject = CatalogDocumentObject;
				SourceDataString.Week 	  = WeekOfYearString(EventLogDataRow.Date);
			EndIf;
			
		EndIf;
		
		// 
		If EventLogDataRow.Event = "_$Data$_.Update" Then
			
			If StrFind(EventLogDataRow.Metadata, "Document.") > 0
				And OutputDocuments Then
				ObjectKind = EventLogDataRow.MetadataPresentation;
				CatalogDocumentObject = EventLogDataRow.Data;
				DocumentsChanged = DocumentsChanged + 1;
				SourceDataString = RawData.Add();
				SourceDataString.Date		  = EventLogDataRow.Date;
				SourceDataString.User = UsernameRef;
				SourceDataString.DocumentsChanged = DocumentsChanged;  	
				SourceDataString.ObjectKind = ObjectKind;
				SourceDataString.CatalogDocumentObject = CatalogDocumentObject;
				SourceDataString.Week 	  = WeekOfYearString(EventLogDataRow.Date);
			EndIf;
			
			If StrFind(EventLogDataRow.Metadata, "Catalog.") > 0
				And OutputCatalogs Then
				ObjectKind = EventLogDataRow.MetadataPresentation;
				CatalogDocumentObject = EventLogDataRow.Data;
				CatalogsChanged = CatalogsChanged + 1;
				SourceDataString = RawData.Add();
				SourceDataString.Date		  = EventLogDataRow.Date;
				SourceDataString.User = UsernameRef;
				SourceDataString.CatalogsChanged = CatalogsChanged;
				SourceDataString.ObjectKind = ObjectKind;
				SourceDataString.CatalogDocumentObject = CatalogDocumentObject;
				SourceDataString.Week 	  = WeekOfYearString(EventLogDataRow.Date);
			EndIf;
			
		EndIf;
		
		// 
		If EventLogDataRow.Event = "_$Data$_.New" Then
			
			If StrFind(EventLogDataRow.Metadata, "BusinessProcess.") > 0 
				And OutputBusinessProcesses Then
				ObjectKind = EventLogDataRow.MetadataPresentation;
				CatalogDocumentObject = EventLogDataRow.Data;
				BusinessProcessesCreated = BusinessProcessesCreated + 1;
				SourceDataString = RawData.Add();
				SourceDataString.Date		  = EventLogDataRow.Date;
				SourceDataString.User = UsernameRef;
				SourceDataString.ObjectKind = ObjectKind;
				SourceDataString.BusinessProcessesCreated = BusinessProcessesCreated;
				SourceDataString.CatalogDocumentObject = CatalogDocumentObject;
				SourceDataString.Week 	  = WeekOfYearString(EventLogDataRow.Date); 
			EndIf;
			
			If StrFind(EventLogDataRow.Metadata, "Task.") > 0 
				And OutputTasks Then
				ObjectKind = EventLogDataRow.MetadataPresentation;
				CatalogDocumentObject = EventLogDataRow.Data;
				TasksCreated = TasksCreated + 1;
				SourceDataString = RawData.Add();
				SourceDataString.Date		  = EventLogDataRow.Date;
				SourceDataString.User = UsernameRef;
				SourceDataString.ObjectKind = ObjectKind;
				SourceDataString.TasksCreated = TasksCreated;
				SourceDataString.CatalogDocumentObject = CatalogDocumentObject;
				SourceDataString.Week 	  = WeekOfYearString(EventLogDataRow.Date);
			EndIf;
			
		EndIf;
		
		// 
		If EventLogDataRow.Event = "_$Data$_.Update" Then
			
			If StrFind(EventLogDataRow.Metadata, "BusinessProcess.") > 0
				And OutputBusinessProcesses Then
				ObjectKind = EventLogDataRow.MetadataPresentation;
				CatalogDocumentObject = EventLogDataRow.Data;
				BusinessProcessesChanged = BusinessProcessesChanged + 1;
				SourceDataString = RawData.Add();
				SourceDataString.Date		  = EventLogDataRow.Date;
				SourceDataString.User = UsernameRef;
				SourceDataString.ObjectKind = ObjectKind;
				SourceDataString.BusinessProcessesChanged = BusinessProcessesChanged;
				SourceDataString.CatalogDocumentObject = CatalogDocumentObject;
				SourceDataString.Week 	  = WeekOfYearString(EventLogDataRow.Date);
			EndIf;
			
			If StrFind(EventLogDataRow.Metadata, "Task.") > 0 
				And OutputTasks Then
				ObjectKind = EventLogDataRow.MetadataPresentation;
				CatalogDocumentObject = EventLogDataRow.Data;
				TasksChanged = TasksChanged + 1;
				SourceDataString = RawData.Add();
				SourceDataString.Date		  = EventLogDataRow.Date;
				SourceDataString.User = UsernameRef;
				SourceDataString.ObjectKind = ObjectKind;
				SourceDataString.TasksChanged = TasksChanged;
				SourceDataString.CatalogDocumentObject = CatalogDocumentObject;
				SourceDataString.Week 	  = WeekOfYearString(EventLogDataRow.Date);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// 
	For Each Session In Sessions Do
		If Session.StartingEvent <> Undefined Then
			Begin = Session.StartingEvent.Date;
		ElsIf ValueIsFilled(Session.SessionFirstEventDate) Then
			Begin = Session.SessionFirstEventDate;
		Else
			Begin = Session.FinishingEvent.Date;
		EndIf;
		If Session.FinishingEvent <> Undefined Then
			End = Session.FinishingEvent.Date;
		ElsIf ValueIsFilled(Session.SessionLastEventDate) Then
			End = Session.SessionLastEventDate;
		Else
			End = Begin;
		EndIf;
		StartsCount = 1;
		Continue_ = True;
		While Continue_ Do
			Date = Begin;
			If BegOfDay(Begin) < BegOfDay(End) Then
				Begin = BegOfDay(Begin) + 86400;
				WorkHours = (Begin - Date) / 3600;
			Else
				Continue_ = False;
				WorkHours = (End - Begin) / 3600;
			EndIf;
			SourceDataString = RawData.Add();
			SourceDataString.Date = Date;
			SourceDataString.Week = WeekOfYearString(Date);
			SourceDataString.User = Session.User;
			SourceDataString.StartsCount = StartsCount;
			SourceDataString.WorkHours = ?(WorkHours = 0, 0.0001, WorkHours);
			StartsCount = 0;
		EndDo;
	EndDo;
	
	If ReportVariant = "UsersActivityAnalysis" Then
	
		UsersArray 	= New Array;
		MaxUsersArray = New Array;
		ConcurrentUsers  = 0;
		Counter                 = 0;
		CurrentDate             = Undefined;
		
		For Each EventLogDataRow In EventLogData Do
			
			If Not ValueIsFilled(EventLogDataRow.Date) Then
				Continue;
			EndIf;
			
			UsernameRef = UsersIDsMap[EventLogDataRow.User];
			If UsernameRef = Undefined Then
				Continue;
			EndIf;
			
			ConcurrentUsersDate = BegOfDay(EventLogDataRow.Date);
			
			// 
			If CurrentDate <> ConcurrentUsersDate Then
				If ConcurrentUsers <> 0 Then
					GenerateConcurrentSessionsRow(ConcurrentSessionsData, MaxUsersArray, 
						ConcurrentUsers, CurrentDate);
				EndIf;
				ConcurrentUsers = 0;
				Counter    = 0;
				UsersArray.Clear();
				CurrentDate = ConcurrentUsersDate;
			EndIf;
			
			If EventLogDataRow.Event = "_$Session$_.Start" Then
				Counter = Counter + 1;
				UsersArray.Add(UsernameRef);
			ElsIf EventLogDataRow.Event = "_$Session$_.Finish" Then
				UserIndex = UsersArray.Find(UsernameRef);
				If Not UserIndex = Undefined Then 
					UsersArray.Delete(UserIndex);
					Counter = Counter - 1;
				EndIf;
			EndIf;
			
			// 
			Counter = Max(Counter, 0);
			If Counter > ConcurrentUsers Then
				MaxUsersArray = New Array;
				For Each Item In UsersArray Do
					MaxUsersArray.Add(Item);
				EndDo;
			EndIf;
			ConcurrentUsers = Max(ConcurrentUsers, Counter);
			
		EndDo;
		
		If ConcurrentUsers <> 0 Then
			GenerateConcurrentSessionsRow(ConcurrentSessionsData, MaxUsersArray, 
				ConcurrentUsers, CurrentDate);
		EndIf;
		
		// 
		EventLogData = Undefined;
		Errors1 					 = 0;
		Warnings			 = 0;
		EventLogData = EventLogErrorsInformation(StartDate,
			EndDate, ServerTimeOffset, UserFilter);
		
		ReportIsBlank =  ReportIsBlank Or (EventLogData.Count() = 0);
		
		For Each EventLogDataRow In EventLogData Do
			
			UsernameRef = UsersIDsMap[EventLogDataRow.User];
			If UsernameRef = Undefined Then
				Continue;
			EndIf;
			
			If EventLogDataRow.Level = EventLogLevel.Error Then
				Errors1 = Errors1 + 1;
				SourceDataString = RawData.Add();
				SourceDataString.Date = EventLogDataRow.Date;
				SourceDataString.Week 	  = WeekOfYearString(EventLogDataRow.Date);
				SourceDataString.User = UsernameRef;
				SourceDataString.Errors1 = Errors1;
			EndIf;
			
			If EventLogDataRow.Level = EventLogLevel.Warning Then
				Warnings = Warnings + 1;
				SourceDataString = RawData.Add();
				SourceDataString.Date = EventLogDataRow.Date;
				SourceDataString.Week 	  = WeekOfYearString(EventLogDataRow.Date);
				SourceDataString.User = UsernameRef;
				SourceDataString.Warnings = Warnings;
			EndIf;
			
			Errors1         = 0;
			Warnings = 0;
		EndDo;
		
	EndIf;
	
	Return New Structure("UsersActivityAnalysis, ConcurrentSessionsData, ReportIsBlank", RawData, ConcurrentSessionsData, ReportIsBlank);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Procedure FillUsersForAnalysis(UserFilter, FilterValue)
	
	If TypeOf(FilterValue) = Type("ValueList") Then
		UsersAndGroups = FilterValue.UnloadValues();
	Else
		UsersAndGroups = CommonClientServer.ValueInArray(FilterValue);
	EndIf;
	
	GroupToRetrieveUsers = New Array;
	AllUsersGroup = Users.AllUsersGroup();
	For Each UserOrGroup In UsersAndGroups Do
		If TypeOf(UserOrGroup) = Type("CatalogRef.Users") Then
			UserForSelection = UserForSelection(UserOrGroup);
			
			If UserForSelection <> Undefined Then
				UserFilter.Add(UserForSelection);
			EndIf;
		ElsIf UserOrGroup = AllUsersGroup Then
			UserFilter = New Array;
			UserFilter.Add("AllUsers");
			Return;
		ElsIf TypeOf(UserOrGroup) = Type("CatalogRef.UserGroups") Then
			GroupToRetrieveUsers.Add(UserOrGroup);
		EndIf;
	EndDo;
	
	If GroupToRetrieveUsers.Count() > 0 Then
		
		Query = New Query;
		Query.SetParameter("Group", GroupToRetrieveUsers);
		Query.Text = 
			"SELECT DISTINCT
			|	UserGroupCompositions.User AS User
			|FROM
			|	InformationRegister.UserGroupCompositions AS UserGroupCompositions
			|WHERE
			|	UserGroupCompositions.UsersGroup IN
			|			(SELECT
			|				UserGroups.Ref AS Ref
			|			FROM
			|				Catalog.UserGroups AS UserGroups
			|			WHERE
			|				UserGroups.Ref IN HIERARCHY (&Group))";
		Result = Query.Execute().Unload();
		
		For Each String In Result Do
			UserForSelection = UserForSelection(String.User);
			
			If UserForSelection <> Undefined Then
				UserFilter.Add(UserForSelection);
			EndIf;
		
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillUsersForAnalysisFromDepartment(UserFilter, FilterValue)
	
	If FilterValue = Undefined Then
		UserFilter.Add("AllUsers");
		Return;
	EndIf;
	
	If TypeOf(FilterValue) = Type("ValueList") Then
		SelectedDivisions = FilterValue.UnloadValues();
	Else
		SelectedDivisions = CommonClientServer.ValueInArray(FilterValue);
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Department", SelectedDivisions);
	Query.Text = 
	"SELECT DISTINCT
	|	Users.IBUserID AS IBUserID
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Department IN(&Department)";
	
	Selection = Query.Execute().Select();
	
	SetPrivilegedMode(True);
	
	While Selection.Next() Do
		IBUser = InfoBaseUsers.FindByUUID(
			Selection.IBUserID);
		
		If IBUser <> Undefined Then
			UserFilter.Add(IBUser.Name);
		EndIf;
	EndDo;
	
EndProcedure

Function UsersUUIDs(EventLogData, ShouldOutputUtilityUsers)
	
	UsersTable = EventLogData.Copy(, "User, UserName");
	UsersTable.Indexes.Add("User, UserName");
	UsersTable.GroupBy("User, UserName");
	
	UUIDMap = New Map;
	
	Filter = New Structure("User", CommonClientServer.BlankUUID());
	FoundRows = UsersTable.FindRows(Filter);
	For Each FoundRow In FoundRows Do
		If Not ValueIsFilled(FoundRow.UserName) And ShouldOutputUtilityUsers Then
			UUIDMap.Insert(FoundRows[0].User,
				Users.UnspecifiedUserRef());
		EndIf;
		UsersTable.Delete(FoundRows[0]);
	EndDo;
	
	IBUsersIDs = UsersTable.UnloadColumn("User");
	
	Query = New Query;
	Query.SetParameter("IBUsersIDs", IBUsersIDs);
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref,
	|	Users.IsInternal AS IsInternal,
	|	Users.IBUserID AS IBUserID
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.IBUserID IN(&IBUsersIDs)
	|
	|UNION ALL
	|
	|SELECT
	|	Users.Ref,
	|	FALSE,
	|	Users.IBUserID
	|FROM
	|	Catalog.ExternalUsers AS Users
	|WHERE
	|	Users.IBUserID IN(&IBUsersIDs)";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If Not Selection.IsInternal Or ShouldOutputUtilityUsers Then
			UUIDMap.Insert(Selection.IBUserID, Selection.Ref);
		EndIf;
		String = UsersTable.Find(Selection.IBUserID, "User");
		UsersTable.Delete(String);
	EndDo;
	
	If Not ShouldOutputUtilityUsers Then
		Return UUIDMap;
	EndIf;
	
	For Each String In UsersTable Do
		If ValueIsFilled(String.UserName) Then
			UUIDMap.Insert(String.User, String.UserName);
		Else
			UUIDMap.Insert(String.User, String(String.User));
		EndIf;
	EndDo;
	
	Return UUIDMap;
	
EndFunction

Function UserForSelection(UserRef) Export
	
	SetPrivilegedMode(True);
	
	IBUserID = Common.ObjectAttributeValue(UserRef,
		"IBUserID");
	
	If ValueIsFilled(IBUserID) Then
		Return EventLog.InfobaseUserForFilter(IBUserID);
	EndIf;
	
	If UserRef = Users.UnspecifiedUserRef() Then
		Return InfoBaseUsers.FindByName("");
	EndIf;
	
	Return Undefined;
	
EndFunction

Function WeekOfYearString(DateInYear)
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Week %1';"), WeekOfYear(DateInYear));
EndFunction

Procedure GenerateConcurrentSessionsRow(ConcurrentSessionsData, MaxUsersArray,
			ConcurrentUsers, CurrentDate)
	
	TemporaryArray = New Array;
	IndexOf = 0;
	For Each Item In MaxUsersArray Do
		TemporaryArray.Insert(IndexOf, Item);
		UserSessionsCounter = 0;
		
		For Each CurrentUser In TemporaryArray Do
			If CurrentUser = Item Then
				UserSessionsCounter = UserSessionsCounter + 1;
				UserAndNumber = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 (%2)';"),
					Item,
					UserSessionsCounter);
			EndIf;
		EndDo;
		
		TableRow = ConcurrentSessionsData.Add();
		TableRow.ConcurrentUsersDate = CurrentDate;
		TableRow.ConcurrentUsers = ConcurrentUsers;
		TableRow.ConcurrentUsersList = UserAndNumber;
		IndexOf = IndexOf + 1;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// This function generates a report on routine tasks.
//
// Parameters:
//   FillParameters - Structure - :
//     * StartDate    - Date -  the beginning of the period for which information will be collected.
//     * EndDate - Date -  the end of the period for which information will be collected.
//   Timestamp Size-Number - the minimum number of concurrent scheduled tasks to
//                                      display in the table.
//   Minimum duration of Scheduled Task sessions - Number - minimum duration of scheduled
//                                                                    task sessions in seconds.
//   Display Background tasks-Boolean - if true, the Gantt chart will display a row with the intervals
//                                       of the background task sessions.
//   Output Header-The type of the output text of the data components-is used to disable/enable the header.
//   Output Selection-The type of the output of the text of the data components-is used to disable / enable the display of the selection.
//   Hide Scheduled tasks-List of values - a list of scheduled tasks that should be excluded from the report.
//
Function GenerateScheduledJobsDurationReport(FillParameters) Export
	
	// 
	StartDate = FillParameters.StartDate;
	EndDate = FillParameters.EndDate;
	MinScheduledJobSessionDuration = 
		FillParameters.MinScheduledJobSessionDuration;
	TitleOutput = FillParameters.TitleOutput;
	FilterOutput = FillParameters.FilterOutput;
	
	Result = New Structure;
	Report = New SpreadsheetDocument;
	
	// 
	GetData = DataForScheduledJobsDurationsReport(FillParameters);
	ScheduledJobsSessionsTable = GetData.ScheduledJobsSessionsTable;
	ConcurrentSessionsData = GetData.TotalConcurrentScheduledJobs;
	StartsCount = GetData.StartsCount;
	ReportIsBlank        = GetData.ReportIsBlank;
	Template = GetTemplate("ScheduledJobsDuration");
	
	// 
	BackColors = New Array;
	BackColors.Add(WebColors.White);
	BackColors.Add(WebColors.LightYellow);
	BackColors.Add(WebColors.LemonChiffon);
	BackColors.Add(WebColors.NavajoWhite);
	
	// 
	If TitleOutput.Value = DataCompositionTextOutputType.Output
		And TitleOutput.Use
		Or Not TitleOutput.Use Then
		Report.Put(TemplateAreaDetails(Template, "ReportHeader1"));
	EndIf;
	
	If FilterOutput.Value = DataCompositionTextOutputType.Output
		And FilterOutput.Use
		Or Not FilterOutput.Use Then
		Area = TemplateAreaDetails(Template, "Filter");
		If MinScheduledJobSessionDuration > 0 Then
			IntervalsViewMode = NStr("en = 'Hide intervals with zero duration';");
		Else
			IntervalsViewMode = NStr("en = 'Show intervals with zero duration';");
		EndIf;
		Area.Parameters.StartDate = StartDate;
		Area.Parameters.EndDate = EndDate;
		Area.Parameters.IntervalsViewMode = IntervalsViewMode;
		Report.Put(Area);
	EndIf;
	
	If ValueIsFilled(ConcurrentSessionsData) Then
	
		Report.Put(TemplateAreaDetails(Template, "TableHeader"));
		
		// 
		CurrentSessionsCount = 0; 
		ColorIndex = 3;
		For Each ConcurrentSessionsRow In ConcurrentSessionsData Do
			Area = TemplateAreaDetails(Template, "Table");
			If CurrentSessionsCount <> 0 
				And CurrentSessionsCount <> ConcurrentSessionsRow.ConcurrentScheduledJobs
				And ColorIndex <> 0 Then
				ColorIndex = ColorIndex - 1;
			EndIf;
			If ConcurrentSessionsRow.ConcurrentScheduledJobs = 1 Then
				ColorIndex = 0;
			EndIf;
			Area.Parameters.Fill(ConcurrentSessionsRow);
			TableBackColor = BackColors.Get(ColorIndex);
			TableArea = Area.Areas.Table; // SpreadsheetDocumentRange
			TableArea.BackColor = TableBackColor;
			Report.Put(Area);
			CurrentSessionsCount = ConcurrentSessionsRow.ConcurrentScheduledJobs;
			ScheduledJobsArray = ConcurrentSessionsRow.ScheduledJobsList;
			ScheduledJobIndex = 0;
			Report.StartRowGroup(, False);
			For Each Item In ScheduledJobsArray Do
				If Not TypeOf(Item) = Type("Number")
					And Not TypeOf(Item) = Type("Date") Then
					Area = TemplateAreaDetails(Template, "ScheduledJobsList");
					Area.Parameters.ScheduledJobsList = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 (session %2)';"),
						Item,
						ScheduledJobsArray[ScheduledJobIndex+1]);
				ElsIf Not TypeOf(Item) = Type("Date")
					And Not TypeOf(Item) = Type("String") Then	
					Area.Parameters.JobDetails1 = New Array;
					Area.Parameters.JobDetails1.Add("ScheduledJobDetails1");
					Area.Parameters.JobDetails1.Add(Item);
					ScheduledJobName = ScheduledJobsArray.Get(ScheduledJobIndex-1);
					Area.Parameters.JobDetails1.Add(ScheduledJobName);
					Area.Parameters.JobDetails1.Add(StartDate);
					Area.Parameters.JobDetails1.Add(EndDate);
					Report.Put(Area);
				EndIf;
				ScheduledJobIndex = ScheduledJobIndex + 1;
			EndDo;
			Report.EndRowGroup();
		EndDo;
	EndIf;
	
	Report.Put(TemplateAreaDetails(Template, "IsBlankString"));
	
	// 
	Area = TemplateAreaDetails(Template, "Chart");
	GanttChart = Area.Drawings.GanttChart.Object; // GanttChart
	GanttChart.RefreshEnabled = False;  
	
	Series = GanttChart.Series.Add();

	CurrentEvent			 = Undefined;
	OverallScheduledJobsDuration = 0;
	Point					 = Undefined;
	StartsCountRow = Undefined;
	ScheduledJobStarts = 0;
	PointChangedFlag        = False;
	
	// 	
	For Each ScheduledJobsRow In ScheduledJobsSessionsTable Do
		ScheduledJobIntervalDuration =
			ScheduledJobsRow.JobEndDate - ScheduledJobsRow.JobStartDate;
		If ScheduledJobIntervalDuration >= MinScheduledJobSessionDuration Then
			If CurrentEvent <> ScheduledJobsRow.NameOfEvent Then
				If CurrentEvent <> Undefined
					And PointChangedFlag Then
					DetailsPoint = Point.Details; // Array
					DetailsPoint.Add(ScheduledJobStarts);
					DetailsPoint.Add(OverallScheduledJobsDuration);
					DetailsPoint.Add(StartDate);
					DetailsPoint.Add(EndDate);
					PointName = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 (%2 out of %3)';"),
						Point.Value,
						ScheduledJobStarts,
						String(StartsCountRow.Starts));
					Point.Value = PointName;
				EndIf;
				StartsCountRow = StartsCount.Find(
					ScheduledJobsRow.NameOfEvent, "NameOfEvent");
				// 
				If ScheduledJobsRow.EventMetadata <> "" Then 
					PointName = ScheduledJobsRow.NameOfEvent;
					Point = GanttChart.SetPoint(PointName);
					DetailsPoint  = New Array;
					IntervalStart	  = New Array;
					IntervalEnd	  = New Array;
					ScheduledJobSession = New Array;
					DetailsPoint.Add("DetailsPoint");
					DetailsPoint.Add(ScheduledJobsRow.EventMetadata);
					DetailsPoint.Add(ScheduledJobsRow.NameOfEvent);
					DetailsPoint.Add(StartsCountRow.Canceled);
					DetailsPoint.Add(StartsCountRow.ExecutionError);                                                             
					DetailsPoint.Add(IntervalStart);
					DetailsPoint.Add(IntervalEnd);
					DetailsPoint.Add(ScheduledJobSession);
					DetailsPoint.Add(MinScheduledJobSessionDuration);
					Point.Details = DetailsPoint;
					CurrentEvent = ScheduledJobsRow.NameOfEvent;
					OverallScheduledJobsDuration = 0;				
					ScheduledJobStarts = 0;
					Point.Picture = PictureLib.ScheduledJob;
				ElsIf Not ValueIsFilled(ScheduledJobsRow.EventMetadata) Then
					PointName = NStr("en = 'Background jobs';");
					Point = GanttChart.SetPoint(PointName);
					OverallScheduledJobsDuration = 0;
				EndIf;
			EndIf;
			Value = GanttChart.GetValue(Point, Series);
			Interval = Value.Add();
			Interval.Begin = ScheduledJobsRow.JobStartDate;
			Interval.End = ScheduledJobsRow.JobEndDate;
			Interval.Text = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 - %2';"),
				Format(Interval.Begin, "DLF=T"),
				Format(Interval.End, "DLF=T"));
			PointChangedFlag = False;
			// 
			If ScheduledJobsRow.EventMetadata <> "" Then
				IntervalStart.Add(ScheduledJobsRow.JobStartDate);
				IntervalEnd.Add(ScheduledJobsRow.JobEndDate);
				ScheduledJobSession.Add(ScheduledJobsRow.Session);
				OverallScheduledJobsDuration = ScheduledJobIntervalDuration + OverallScheduledJobsDuration;
				ScheduledJobStarts = ScheduledJobStarts + 1;
				PointChangedFlag = True;
			EndIf;
		EndIf;
	EndDo; 
	
	If ScheduledJobStarts <> 0
		And ValueIsFilled(Point.Details) Then
		// 
		DetailsPoint = Point.Details; // Array
		DetailsPoint.Add(ScheduledJobStarts);
		DetailsPoint.Add(OverallScheduledJobsDuration);
		DetailsPoint.Add(StartDate);
		DetailsPoint.Add(EndDate);	
		PointName = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 (%2 out of %3)';"),
			Point.Value,
			ScheduledJobStarts,
			String(StartsCountRow.Starts));
		Point.Value = PointName;
	EndIf;
		
	// 
	GanttChartColors(StartDate, GanttChart, ConcurrentSessionsData, BackColors);
	AnalysisPeriod = EndDate - StartDate;
	GanttChartTimescale(GanttChart, AnalysisPeriod);
	
	ColumnsCount = GanttChart.Points.Count();
	Area.Drawings.GanttChart.Height				 = 15 + 10 * ColumnsCount;
	Area.Drawings.GanttChart.Width 				 = 450;
	GanttChart.AutoDetectWholeInterval	 = False; 
	GanttChart.IntervalRepresentation   			 = GanttChartIntervalRepresentation.Flat;
	GanttChart.LegendArea.Placement       = ChartLegendPlacement.None;
	GanttChart.VerticalStretch 			 = GanttChartVerticalStretch.StretchRowsAndData;
	GanttChart.SetWholeInterval(StartDate, EndDate);
	GanttChart.RefreshEnabled = True;

	Report.Put(Area);
	
	Result.Insert("Report", Report);
	Result.Insert("ReportIsBlank", ReportIsBlank);
	Return Result;
EndFunction

// The function receives information on routine tasks from the registration log.
//
// Parameters:
//   FillParameters - Structure - :
//   * StartDate    - Date -  the beginning of the period for which information will be collected.
//   * EndDate - Date -  the end of the period for which information will be collected.
//   * ConcurrentSessionsSize	- Number -  the minimum number of concurrent scheduled
// 		tasks to display in the table.
//   * MinScheduledJobSessionDuration - Number -  minimum duration
// 		of scheduled task sessions in seconds.
//   * DisplayBackgroundJobs - Boolean -  if true, the Gantt chart will display a line with 
// 		the intervals of sessions of background tasks.
//   * HideScheduledJobs - ValueList -  a list of routine tasks that need to be excluded from the report.
//
// Return value
//   Assignment table - a table containing information on the work of routine tasks
//     from the registration log.
//
Function DataForScheduledJobsDurationsReport(FillParameters)
	
	StartDate = FillParameters.StartDate;
	EndDate = FillParameters.EndDate;
	ConcurrentSessionsSize = FillParameters.ConcurrentSessionsSize;
	DisplayBackgroundJobs = FillParameters.DisplayBackgroundJobs;
	MinScheduledJobSessionDuration =
		FillParameters.MinScheduledJobSessionDuration;
	HideScheduledJobs = FillParameters.HideScheduledJobs;
	ServerTimeOffset = FillParameters.ServerTimeOffset;
	
	EventLogData = New ValueTable;
	
	Levels = New Array;
	Levels.Add(EventLogLevel.Information);
	Levels.Add(EventLogLevel.Warning);
	Levels.Add(EventLogLevel.Error);
	
	ScheduledJobEvents = New Array;
	ScheduledJobEvents.Add("_$Job$_.Start");
	ScheduledJobEvents.Add("_$Job$_.Cancel");
	ScheduledJobEvents.Add("_$Job$_.Fail");
	ScheduledJobEvents.Add("_$Job$_.Succeed");
	ScheduledJobEvents.Add("_$Job$_.Finish");
	ScheduledJobEvents.Add("_$Job$_.Error");
	
	SetPrivilegedMode(True);
	LogFilter = New Structure;
	LogFilter.Insert("Level", Levels);
	LogFilter.Insert("StartDate", StartDate + ServerTimeOffset);
	LogFilter.Insert("EndDate", EndDate + ServerTimeOffset);
	LogFilter.Insert("Event", ScheduledJobEvents);
	
	UnloadEventLog(EventLogData, LogFilter);
	ReportIsBlank = (EventLogData.Count() = 0);
	
	If ServerTimeOffset <> 0 Then
		For Each TableRow In EventLogData Do
			TableRow.Date = TableRow.Date - ServerTimeOffset;
		EndDo;
	EndIf;
	
	// 
	AllScheduledJobsList = ScheduledJobsServer.FindJobs(New Structure);
	MetadataIDMap = New Map;
	MetadataNameMap = New Map;
	DescriptionIDMap = New Map;
	SetPrivilegedMode(False);
	
	For Each SchedJob In AllScheduledJobsList Do
		MetadataIDMap.Insert(SchedJob.Metadata, String(SchedJob.UUID));
		DescriptionIDMap.Insert(SchedJob.Description, String(SchedJob.UUID));
		If SchedJob.Description <> "" Then
			MetadataNameMap.Insert(SchedJob.Metadata, SchedJob.Description);
		Else
			MetadataNameMap.Insert(SchedJob.Metadata, SchedJob.Metadata.Synonym);
		EndIf;
	EndDo;
	
	// 
	ConcurrentSessionsParameters = New Structure;
	ConcurrentSessionsParameters.Insert("EventLogData", EventLogData);
	ConcurrentSessionsParameters.Insert("DescriptionIDMap", DescriptionIDMap);
	ConcurrentSessionsParameters.Insert("MetadataIDMap", MetadataIDMap);
	ConcurrentSessionsParameters.Insert("MetadataNameMap", MetadataNameMap);
	ConcurrentSessionsParameters.Insert("HideScheduledJobs", HideScheduledJobs);
	ConcurrentSessionsParameters.Insert("MinScheduledJobSessionDuration",
		MinScheduledJobSessionDuration);
	
	// 
	ConcurrentSessionsData = ConcurrentScheduledJobs(ConcurrentSessionsParameters);
	
	// 
	ConcurrentSessionsData.Sort("ConcurrentScheduledJobs Desc");
	
	TotalConcurrentScheduledJobsRow = Undefined;
	TotalConcurrentScheduledJobs = New ValueTable();
	TotalConcurrentScheduledJobs.Columns.Add("ConcurrentScheduledJobsDate", 
		New TypeDescription("String", , New StringQualifiers(50)));
	TotalConcurrentScheduledJobs.Columns.Add("ConcurrentScheduledJobs", 
		New TypeDescription("Number", New NumberQualifiers(10))); 
	TotalConcurrentScheduledJobs.Columns.Add("ScheduledJobsList");
	
	For Each ConcurrentSessionsRow In ConcurrentSessionsData Do
		If ConcurrentSessionsRow.ConcurrentScheduledJobs >= ConcurrentSessionsSize
			And ConcurrentSessionsRow.ConcurrentScheduledJobs >= 2 Then
			TotalConcurrentScheduledJobsRow = TotalConcurrentScheduledJobs.Add();
			TotalConcurrentScheduledJobsRow.ConcurrentScheduledJobsDate = 
				ConcurrentSessionsRow.ConcurrentScheduledJobsDate;
			TotalConcurrentScheduledJobsRow.ConcurrentScheduledJobs = 
				ConcurrentSessionsRow.ConcurrentScheduledJobs;
			TotalConcurrentScheduledJobsRow.ScheduledJobsList = 
				ConcurrentSessionsRow.ScheduledJobsList;
		EndIf;
	EndDo;
	
	EventLogData.Sort("Metadata, Data, Date, Session");
	
	// 
	ScheduledJobsSessionsParameters = New Structure;
	ScheduledJobsSessionsParameters.Insert("EventLogData", EventLogData);
	ScheduledJobsSessionsParameters.Insert("DescriptionIDMap", DescriptionIDMap);
	ScheduledJobsSessionsParameters.Insert("MetadataIDMap", MetadataIDMap);
	ScheduledJobsSessionsParameters.Insert("MetadataNameMap", MetadataNameMap);
	ScheduledJobsSessionsParameters.Insert("DisplayBackgroundJobs", DisplayBackgroundJobs);
	ScheduledJobsSessionsParameters.Insert("HideScheduledJobs", HideScheduledJobs);
	
	// 
	ScheduledJobsSessionsTable = 
		ScheduledJobsSessions(ScheduledJobsSessionsParameters).ScheduledJobsSessionsTable;
	StartsCount = ScheduledJobsSessions(ScheduledJobsSessionsParameters).StartsCount;
	
	Result = New Structure;
	Result.Insert("ScheduledJobsSessionsTable", ScheduledJobsSessionsTable);
	Result.Insert("TotalConcurrentScheduledJobs", TotalConcurrentScheduledJobs);
	Result.Insert("StartsCount", StartsCount);
	Result.Insert("ReportIsBlank", ReportIsBlank);
	
	Return Result;
EndFunction

Function ConcurrentScheduledJobs(ConcurrentSessionsParameters)
	
	EventLogData 			  = ConcurrentSessionsParameters.EventLogData;
	DescriptionIDMap = ConcurrentSessionsParameters.DescriptionIDMap;
	MetadataIDMap   = ConcurrentSessionsParameters.MetadataIDMap;
	MetadataNameMap 		  = ConcurrentSessionsParameters.MetadataNameMap;
	HideScheduledJobs 			  = ConcurrentSessionsParameters.HideScheduledJobs;
	MinScheduledJobSessionDuration = ConcurrentSessionsParameters.	
		MinScheduledJobSessionDuration;
										
	ConcurrentSessionsData = New ValueTable();
	
	ConcurrentSessionsData.Columns.Add("ConcurrentScheduledJobsDate",
										New TypeDescription("String", , New StringQualifiers(50)));
	ConcurrentSessionsData.Columns.Add("ConcurrentScheduledJobs",
										New TypeDescription("Number", New NumberQualifiers(10)));
	ConcurrentSessionsData.Columns.Add("ScheduledJobsList");
	
	ScheduledJobsArray = New Array;
	
	ConcurrentScheduledJobs	  = 0;
	Counter     				  = 0;
	CurrentDate 					  = Undefined;
	TableRow 				  = Undefined;
	MaxScheduledJobsArray = Undefined;
	
	For Each EventLogDataRow In EventLogData Do 
		If Not ValueIsFilled(EventLogDataRow.Date)
			Or Not ValueIsFilled(EventLogDataRow.Metadata) Then
			Continue;
		EndIf;
		
		NameAndUUID = ScheduledJobSessionNameAndUUID(
			EventLogDataRow, DescriptionIDMap,
			MetadataIDMap, MetadataNameMap);
			
		ScheduledJobName1 = NameAndUUID.SessionName;
		ScheduledJobUUID = 
			NameAndUUID.ScheduledJobUUID;
		
		If Not HideScheduledJobs = Undefined
			And Not TypeOf(HideScheduledJobs) = Type("String") Then
			ScheduledJobsFilter = HideScheduledJobs.FindByValue(
				ScheduledJobUUID);
			If Not ScheduledJobsFilter = Undefined Then
				Continue;
			EndIf;
		ElsIf Not HideScheduledJobs = Undefined
			And TypeOf(HideScheduledJobs) = Type("String") Then	
			If ScheduledJobUUID = HideScheduledJobs Then
				Continue;
			EndIf;
		EndIf;	
		
		ConcurrentScheduledJobsDate = BegOfHour(EventLogDataRow.Date);
		
		If CurrentDate <> ConcurrentScheduledJobsDate Then
			If TableRow <> Undefined Then
				TableRow.ConcurrentScheduledJobs = ConcurrentScheduledJobs;
				TableRow.ConcurrentScheduledJobsDate = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 - %2';"),
					Format(CurrentDate, "DLF=T"),
					Format(EndOfHour(CurrentDate), "DLF=T"));
				TableRow.ScheduledJobsList = MaxScheduledJobsArray;
			EndIf;
			TableRow = ConcurrentSessionsData.Add();
			ConcurrentScheduledJobs = 0;
			Counter    = 0;
			ScheduledJobsArray.Clear();
			CurrentDate = ConcurrentScheduledJobsDate;
		EndIf;
		
		If EventLogDataRow.Event = "_$Job$_.Start" Then
			Counter = Counter + 1;
			ScheduledJobsArray.Add(ScheduledJobName1);
			ScheduledJobsArray.Add(EventLogDataRow.Session);
			ScheduledJobsArray.Add(EventLogDataRow.Date);
		Else
			ScheduledJobIndex = ScheduledJobsArray.Find(ScheduledJobName1);
			If ScheduledJobIndex = Undefined Then 
				Continue;
			EndIf;
			
			If ValueIsFilled(MaxScheduledJobsArray) Then
				ArrayStringIndex = MaxScheduledJobsArray.Find(ScheduledJobName1);
				If ArrayStringIndex <> Undefined 
					And MaxScheduledJobsArray[ArrayStringIndex+1] = ScheduledJobsArray[ScheduledJobIndex+1]
					And EventLogDataRow.Date - MaxScheduledJobsArray[ArrayStringIndex+2] <
						MinScheduledJobSessionDuration Then
					MaxScheduledJobsArray.Delete(ArrayStringIndex);
					MaxScheduledJobsArray.Delete(ArrayStringIndex);
					MaxScheduledJobsArray.Delete(ArrayStringIndex);
					ConcurrentScheduledJobs = ConcurrentScheduledJobs - 1;
				EndIf;
			EndIf;    						
			ScheduledJobsArray.Delete(ScheduledJobIndex);
			ScheduledJobsArray.Delete(ScheduledJobIndex); // 
			ScheduledJobsArray.Delete(ScheduledJobIndex); // 
			Counter = Counter - 1;
		EndIf;
		
		Counter = Max(Counter, 0);
		If Counter > ConcurrentScheduledJobs Then
			MaxScheduledJobsArray = New Array;
			For Each Item In ScheduledJobsArray Do
				MaxScheduledJobsArray.Add(Item);
			EndDo;
		EndIf;
		ConcurrentScheduledJobs = Max(ConcurrentScheduledJobs, Counter);
	EndDo;
		
	If ConcurrentScheduledJobs <> 0 Then
		TableRow.ConcurrentScheduledJobs  = ConcurrentScheduledJobs;
		TableRow.ConcurrentScheduledJobsDate = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 - %2';"),
			Format(CurrentDate, "DLF=T"),
			Format(EndOfHour(CurrentDate), "DLF=T"));
		TableRow.ScheduledJobsList = MaxScheduledJobsArray;
	EndIf;
	
	Return ConcurrentSessionsData;
EndFunction

Function ScheduledJobsSessions(ScheduledJobsSessionsParameters)

	EventLogData = ScheduledJobsSessionsParameters.EventLogData;
	DescriptionIDMap = ScheduledJobsSessionsParameters.DescriptionIDMap;
	MetadataIDMap = ScheduledJobsSessionsParameters.MetadataIDMap;
	MetadataNameMap = ScheduledJobsSessionsParameters.MetadataNameMap;
	HideScheduledJobs = ScheduledJobsSessionsParameters.HideScheduledJobs;
	DisplayBackgroundJobs = ScheduledJobsSessionsParameters.DisplayBackgroundJobs;  
	
	ScheduledJobsSessionsTable = New ValueTable();
	ScheduledJobsSessionsTable.Columns.Add("JobStartDate",New TypeDescription("Date", , , New DateQualifiers(DateFractions.DateTime)));
	ScheduledJobsSessionsTable.Columns.Add("JobEndDate",New TypeDescription("Date", , , New DateQualifiers(DateFractions.DateTime)));
    ScheduledJobsSessionsTable.Columns.Add("NameOfEvent",New TypeDescription("String", , New StringQualifiers(100)));
	ScheduledJobsSessionsTable.Columns.Add("EventMetadata",New TypeDescription("String", , New StringQualifiers(100)));
	ScheduledJobsSessionsTable.Columns.Add("Session",New TypeDescription("Number", 	New NumberQualifiers(10)));
	
	StartsCount = New ValueTable();
	StartsCount.Columns.Add("NameOfEvent",New TypeDescription("String", , New StringQualifiers(100)));
	StartsCount.Columns.Add("Starts",New TypeDescription("Number", 	New NumberQualifiers(10)));
	StartsCount.Columns.Add("Canceled",New TypeDescription("Number", 	New NumberQualifiers(10)));
	StartsCount.Columns.Add("ExecutionError",New TypeDescription("Number", 	New NumberQualifiers(10))); 	
	
	ScheduledJobsRow = Undefined;
	NameOfEvent			  = Undefined;
	JobEndDate	  = Undefined;
	JobStartDate		  = Undefined;
	EventMetadata		  = Undefined;
	Starts				  = 0;
	CurrentEvent			  = Undefined;
	StartsCountRow  = Undefined;
	CurrentSession			  = 0;
	Canceled				  = 0;
	ExecutionError		  = 0;
	
	For Each EventLogDataRow In EventLogData Do
		If Not ValueIsFilled(EventLogDataRow.Metadata)
			And DisplayBackgroundJobs = False Then
			Continue;
		EndIf;
		
		NameAndUUID = ScheduledJobSessionNameAndUUID(
			EventLogDataRow, DescriptionIDMap,
			MetadataIDMap, MetadataNameMap);
			
		NameOfEvent = NameAndUUID.SessionName;
		ScheduledJobUUID = NameAndUUID.
														ScheduledJobUUID;

		If Not HideScheduledJobs = Undefined
			And Not TypeOf(HideScheduledJobs) = Type("String") Then
			ScheduledJobsFilter = HideScheduledJobs.FindByValue(
				ScheduledJobUUID);
			If Not ScheduledJobsFilter = Undefined Then
				Continue;
			EndIf;
		ElsIf Not HideScheduledJobs = Undefined
			And TypeOf(HideScheduledJobs) = Type("String") Then	
			If ScheduledJobUUID = HideScheduledJobs Then
				Continue;
			EndIf;
		EndIf;
	
		Session = EventLogDataRow.Session;
		If CurrentEvent = Undefined Then                             
			CurrentEvent = NameOfEvent;
			Starts = 0;
		ElsIf CurrentEvent <> NameOfEvent Then
			StartsCountRow = StartsCount.Add();
			StartsCountRow.NameOfEvent = CurrentEvent;
			StartsCountRow.Starts = Starts;
			StartsCountRow.Canceled = Canceled;
			StartsCountRow.ExecutionError = ExecutionError;
			Starts = 0; 
			Canceled = 0;
			ExecutionError = 0;
			CurrentEvent = NameOfEvent;
		EndIf;  
		
		If CurrentSession <> Session Then
			ScheduledJobsRow = ScheduledJobsSessionsTable.Add();
			JobStartDate = EventLogDataRow.Date;
			ScheduledJobsRow.JobStartDate = JobStartDate;    
		EndIf;
		
		If CurrentSession = Session Then
			JobEndDate = EventLogDataRow.Date;
			EventMetadata = EventLogDataRow.Metadata;
			ScheduledJobsRow.NameOfEvent = NameOfEvent;
			ScheduledJobsRow.EventMetadata = EventMetadata;
			ScheduledJobsRow.JobEndDate = JobEndDate;
			ScheduledJobsRow.Session = CurrentSession;
		EndIf;
		CurrentSession = Session;
		
		If EventLogDataRow.Event = "_$Job$_.Cancel" Then
			Canceled = Canceled + 1;
		ElsIf EventLogDataRow.Event = "_$Job$_.Fail" Then
			ExecutionError = ExecutionError + 1;
		ElsIf EventLogDataRow.Event = "_$Job$_.Start" Then
			Starts = Starts + 1
		EndIf;		
	EndDo;
	
	StartsCountRow = StartsCount.Add();
	StartsCountRow.NameOfEvent = CurrentEvent;
	StartsCountRow.Starts = Starts;
	StartsCountRow.Canceled = Canceled;
	StartsCountRow.ExecutionError = ExecutionError;
	
	ScheduledJobsSessionsTable.Sort("EventMetadata, NameOfEvent, JobStartDate");
	
	Return New Structure("ScheduledJobsSessionsTable, StartsCount",
					ScheduledJobsSessionsTable, StartsCount);
EndFunction

// Function for generating a report on the selected routine task.
// Parameters:
//   Details - 
//
Function ScheduledJobDetails1(Details) Export
	Result = New Structure;
	Report = New SpreadsheetDocument;
	JobsCanceled = 0;
	ExecutionError = 0;
	
	JobStartDate = Details.Get(5);
	JobEndDate = Details.Get(6);
	SessionsList = Details.Get(7);
	Template = GetTemplate("ScheduledJobsDetails");
	
	Area = TemplateAreaDetails(Template, "Title");
	StartDate = Details.Get(11);
	EndDate = Details.Get(12);
	Area.Parameters.StartDate = StartDate;
	Area.Parameters.EndDate = EndDate;
	If Details.Get(8) = 0 Then
		IntervalsViewMode = NStr("en = 'Show intervals with zero duration';");
	Else
		IntervalsViewMode = NStr("en = 'Hide intervals with zero duration';");
	EndIf;
	Area.Parameters.SessionViewMode = IntervalsViewMode;
	Report.Put(Area);
	
	Report.Put(Template.GetArea("IsBlankString"));
	
	Area = TemplateAreaDetails(Template, "Table");
	Area.Parameters.JobType = NStr("en = 'Scheduled';");
	Area.Parameters.NameOfEvent = Details.Get(2);
	Area.Parameters.Starts = Details.Get(9);
	JobsCanceled = Details.Get(3);
	ExecutionError = Details.Get(4);
	If JobsCanceled = 0 Then
		Area.Parameters.Canceled = "0";
	Else
		Area.Parameters.Canceled = JobsCanceled;
	EndIf;
	If ExecutionError = 0 Then 
		Area.Parameters.ExecutionError = "0";
	Else
		Area.Parameters.ExecutionError = ExecutionError;
	EndIf;
	OverallScheduledJobsDuration = Details.Get(10);
	OverallScheduledJobsDurationTotal = ScheduledJobDuration(OverallScheduledJobsDuration);
	Area.Parameters.OverallScheduledJobsDuration = OverallScheduledJobsDurationTotal;
	Report.Put(Area);
	
	Report.Put(Template.GetArea("IsBlankString")); 
	
	Report.Put(Template.GetArea("IntervalsTitle"));
		
	Report.Put(Template.GetArea("IsBlankString"));
	
	Report.Put(Template.GetArea("TableHeader"));
	
	// 
	ArraySize = JobStartDate.Count();
	IntervalNumber = 1; 	
    Report.StartRowGroup(, False);
	For IndexOf = 0 To ArraySize-1 Do
		Area = TemplateAreaDetails(Template, "IntervalsTable");
		StartOfRange = JobStartDate.Get(IndexOf);
		EndOfRange = JobEndDate.Get(IndexOf);
		SJDuration = ScheduledJobDuration(EndOfRange - StartOfRange);
		Area.Parameters.IntervalNumber = IntervalNumber;
		Area.Parameters.StartOfRange = Format(StartOfRange, "DLF=T");
		Area.Parameters.EndOfRange = Format(EndOfRange, "DLF=T");
		Area.Parameters.SJDuration = SJDuration;
		Area.Parameters.Session = SessionsList.Get(IndexOf);
		Area.Parameters.IntervalDetails1 = New Array;
		Area.Parameters.IntervalDetails1.Add(StartOfRange);
		Area.Parameters.IntervalDetails1.Add(EndOfRange);
		Area.Parameters.IntervalDetails1.Add(SessionsList.Get(IndexOf));
		Report.Put(Area);
		IntervalNumber = IntervalNumber + 1;
	EndDo;
	Report.EndRowGroup();
	
	Result.Insert("Report", Report);
	Return Result;
EndFunction

// Procedure for setting the color of the intervals and background of the Gantt chart.
//
// Parameters:
//   StartDate - 
//   GanttChart - GanttChart, Type -  Drawing table of the document.
//   ConcurrentSessionsData - ValueTable -  with data on the number
// 		of scheduled tasks that worked simultaneously during the day.
//   BackColors - 
//
Procedure GanttChartColors(StartDate, GanttChart, ConcurrentSessionsData, BackColors)
	// 
	CurrentSessionsCount = 0;
	ColorIndex = 3;
	For Each ConcurrentSessionsRow In ConcurrentSessionsData Do
		If ConcurrentSessionsRow.ConcurrentScheduledJobs = 1 Then
			Continue
		EndIf;
		DateString = Left(ConcurrentSessionsRow.ConcurrentScheduledJobsDate, 8);
		BackIntervalStartDate =  Date(Format(StartDate,"DLF=D") + " " + DateString);
		BackIntervalEndDate = EndOfHour(BackIntervalStartDate);
		GanttChartInterval = GanttChart.BackgroundIntervals.Add(BackIntervalStartDate, BackIntervalEndDate);
		If CurrentSessionsCount <> 0 
			And CurrentSessionsCount <> ConcurrentSessionsRow.ConcurrentScheduledJobs 
			And ColorIndex <> 0 Then
			ColorIndex = ColorIndex - 1;
		EndIf;
		BackColor = BackColors.Get(ColorIndex);
		GanttChartInterval.Color = BackColor;
		
		CurrentSessionsCount = ConcurrentSessionsRow.ConcurrentScheduledJobs;
	EndDo;
EndProcedure

// Procedure for generating the Gantt chart time scale.
//
// Parameters:
//   GanttChart - GanttChart, Type -  Drawing table of the document.
//
Procedure GanttChartTimescale(GanttChart, AnalysisPeriod)
	TimeScaleItems = GanttChart.PlotArea.TimeScale.Items;
	
	TheFirstControl = TimeScaleItems[0];
	For IndexOf = 1 To TimeScaleItems.Count()-1 Do
		TimeScaleItems.Delete(TimeScaleItems[1]);
	EndDo; 
		
	TheFirstControl.Unit = TimeScaleUnitType.Day;
	TheFirstControl.PointLines = New Line(ChartLineType.Solid, 1);
	TheFirstControl.DayFormat =  TimeScaleDayFormat.MonthDay;
	
	Item = TimeScaleItems.Add();
	Item.Unit = TimeScaleUnitType.Hour;
	Item.PointLines = New Line(ChartLineType.Dotted, 1);
	
	If AnalysisPeriod <= 3600 Then
		Item = TimeScaleItems.Add();
		Item.Unit = TimeScaleUnitType.Minute;
		Item.PointLines = New Line(ChartLineType.Dotted, 1);
	EndIf;
EndProcedure

Function ScheduledJobDuration(SJDuration)
	If SJDuration = 0 Then
		OverallScheduledJobsDuration = "0";
	ElsIf SJDuration <= 60 Then
		OverallScheduledJobsDuration = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 sec';"), SJDuration);
	ElsIf 60 < SJDuration <= 3600 Then
		DurationMinutes  = Format(SJDuration/60, "NFD=0");
		DurationSeconds = Format((Format(SJDuration/60, "NFD=2")
			- Int(SJDuration/60)) * 60, "NFD=0");
		OverallScheduledJobsDuration = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 min %2 sec';"), DurationMinutes, DurationSeconds);
	ElsIf SJDuration > 3600 Then
		DurationHours    = Format(SJDuration/60/60, "NFD=0");
		DurationMinutes  = (Format(SJDuration/60/60, "NFD=2") - Int(SJDuration/60/60))*60;
		DurationMinutes  = Format(DurationMinutes, "NFD=0");
		OverallScheduledJobsDuration = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = '%1 h %2 min';"), DurationHours, DurationMinutes);
	EndIf;
	
	Return OverallScheduledJobsDuration;
EndFunction

Function ScheduledJobMetadata(ScheduledJobData)
	If ScheduledJobData <> "" Then
		Return Metadata.ScheduledJobs.Find(
			StrReplace(ScheduledJobData, "ScheduledJob." , ""));
	EndIf;
EndFunction

Function ScheduledJobSessionNameAndUUID(EventLogDataRow,
			DescriptionIDMap, MetadataIDMap, MetadataNameMap)
	If Not EventLogDataRow.Data = "" Then
		ScheduledJobUUID = DescriptionIDMap[
														EventLogDataRow.Data];
		SessionName = EventLogDataRow.Data;
	Else 
		ScheduledJobUUID = MetadataIDMap[
			ScheduledJobMetadata(EventLogDataRow.Metadata)];
		SessionName = MetadataNameMap[ScheduledJobMetadata(
														EventLogDataRow.Metadata)];
	EndIf;
													
	Return New Structure("SessionName, ScheduledJobUUID",
								SessionName, ScheduledJobUUID)
EndFunction

// Parameters:
//  Template - SpreadsheetDocument
//  AreaName - String
//
// Returns:
//  SpreadsheetDocument:
//    * Parameters - SpreadsheetDocumentTemplateParameters:
//        ** StartDate - Date
//        ** EndDate - Date
//        ** IntervalsViewMode - String
//        ** ScheduledJobsList - String
//        ** JobDetails1 - Array of String
//                              - Date
//        ** IntervalDetails1 - Array of String
//
Function TemplateAreaDetails(Template, AreaName)
	
	Return Template.GetArea(AreaName);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// A function that generates a report on errors registered in the log.
//
// Parameters:
//   Dataregistration Log-Value table - an unloaded table from the log of registrations.
//
// The following columns must be present: Date, Username, Application View,
//                                          Event View, Comment, Level.
//
Function GenerateEventLogMonitorReport(StartDate, EndDate, ServerTimeOffset) Export
	
	Result = New Structure; 	
	Report = New SpreadsheetDocument; 	
	Template = GetTemplate("EvengLogErrorReportTemplate");
	EventLogData = EventLogErrorsInformation(StartDate, EndDate, ServerTimeOffset);
	EventLogRecordsCount = EventLogData.Count();
	
	ReportIsBlank = (EventLogRecordsCount = 0); // 
		
	///////////////////////////////////////////////////////////////////////////////
	// 
	//
	
	CollapseByComments = EventLogData.Copy();
	CollapseByComments.Columns.Add("TotalByComment");
	CollapseByComments.FillValues(1, "TotalByComment");
	CollapseByComments.GroupBy("Level, Comment, Event, EventPresentation", "TotalByComment");
	
	RowsArrayErrorLevel = CollapseByComments.FindRows(
									New Structure("Level", EventLogLevel.Error));
	
	RowsArrayWarningLevel = CollapseByComments.FindRows(
									New Structure("Level", EventLogLevel.Warning));
	
	CollapseErrors         = CollapseByComments.Copy(RowsArrayErrorLevel);
	CollapseErrors.Sort("TotalByComment Desc");
	CollapseWarnings = CollapseByComments.Copy(RowsArrayWarningLevel);
	CollapseWarnings.Sort("TotalByComment Desc");
	
	///////////////////////////////////////////////////////////////////////////////
	// 
	//
	
	Area = Template.GetArea("ReportHeader1");
	Area.Parameters.SelectionPeriodStart    = StartDate;
	Area.Parameters.SelectionPeriodEnd = EndDate;
	Area.Parameters.InfobasePresentation = InfobasePresentation();
	Report.Put(Area);
	
	TSCompositionResult = GenerateTabularSection(Template, EventLogData, CollapseErrors);
	
	Report.Put(Template.GetArea("IsBlankString"));
	Area = Template.GetArea("ErrorBlockTitle");
	Area.Parameters.ErrorsCount1 = String(TSCompositionResult.Total);
	Report.Put(Area);
	
	If TSCompositionResult.Total > 0 Then
		Report.Put(TSCompositionResult.TabularSection);
	EndIf;
	
	Result.Insert("TotalByErrors", TSCompositionResult.Total); 	
	TSCompositionResult = GenerateTabularSection(Template, EventLogData, CollapseWarnings);
	
	Report.Put(Template.GetArea("IsBlankString"));
	Area = Template.GetArea("WarningBlockTitle");
	Area.Parameters.WarningsCount = TSCompositionResult.Total;
	Report.Put(Area);
	
	If TSCompositionResult.Total > 0 Then
		Report.Put(TSCompositionResult.TabularSection);
	EndIf;
	
	Result.Insert("TotalByWarnings", TSCompositionResult.Total);	
	Report.ShowGrid = False; 	
	Result.Insert("Report", Report); 
	Result.Insert("ReportIsBlank", ReportIsBlank);
	Return Result;
	
EndFunction

// Get a view of the physical location of the information base for display to the administrator.
//
// Returns:
//   String - 
//
// Example:
// - 
// 
//
Function InfobasePresentation()
	
	DatabaseConnectionString = InfoBaseConnectionString();
	
	If Common.FileInfobase(DatabaseConnectionString) Then
		Return Mid(DatabaseConnectionString, 6, StrLen(DatabaseConnectionString) - 6);
	EndIf;
		
	// 
	SearchPosition = StrFind(Upper(DatabaseConnectionString), "SRVR=");
	If SearchPosition <> 1 Then
		Return Undefined;
	EndIf;
	
	SemicolonPosition = StrFind(DatabaseConnectionString, ";");
	StartPositionForCopying = 6 + 1;
	EndPositionForCopying = SemicolonPosition - 2; 
	
	ServerName = Mid(DatabaseConnectionString, StartPositionForCopying, EndPositionForCopying - StartPositionForCopying + 1);
	
	DatabaseConnectionString = Mid(DatabaseConnectionString, SemicolonPosition + 1);
	
	// 
	SearchPosition = StrFind(Upper(DatabaseConnectionString), "REF=");
	If SearchPosition <> 1 Then
		Return Undefined;
	EndIf;
	
	StartPositionForCopying = 6;
	SemicolonPosition = StrFind(DatabaseConnectionString, ";");
	EndPositionForCopying = SemicolonPosition - 2; 
	
	IBNameAtServer = Mid(DatabaseConnectionString, StartPositionForCopying, EndPositionForCopying - StartPositionForCopying + 1);
	PathToDatabase = ServerName + "/ " + IBNameAtServer;
	Return PathToDatabase;
	
EndFunction

// The function gets information about errors in the log for the passed period.
//
// Parameters:
//   StartDate    - Date - 
//   EndDate - Date - 
//
// 
//   :
//                    
//                    
//
Function EventLogErrorsInformation(StartDate, EndDate,
			ServerTimeOffset, UserFilter = Undefined)
	
	EventLogData = New ValueTable;
	
	LogLevels = New Array;
	LogLevels.Add(EventLogLevel.Error);
	LogLevels.Add(EventLogLevel.Warning);
	
	Filter = New Structure;
	Filter.Insert("Level", LogLevels);
	Filter.Insert("StartDate", StartDate + ServerTimeOffset);
	Filter.Insert("EndDate", EndDate + ServerTimeOffset);
	
	If UserFilter <> Undefined Then
		Filter.Insert("User", UserFilter);
	EndIf;
	
	SetPrivilegedMode(True);
	UnloadEventLog(EventLogData, Filter);
	SetPrivilegedMode(False);
	
	If ServerTimeOffset <> 0 Then
		For Each TableRow In EventLogData Do
			TableRow.Date = TableRow.Date - ServerTimeOffset;
		EndDo;
	EndIf;
	
	Return EventLogData;
	
EndFunction

// Adds the error table part to the report. Errors are displayed grouped
// according to the review.
//
// Parameters:
//   Template  - SpreadsheetDocument -  source of formatted areas that will
//                              be used when generating the report.
//   EventLogData   - ValueTable -  data on errors and warnings
//                              from the log "as is".
//   CollapsedData - ValueTable -  information collapsed by comments by their number.
//
Function GenerateTabularSection(Template, EventLogData, CollapsedData)
	
	Report = New SpreadsheetDocument;	
	Total = 0;
	
	If CollapsedData.Count() > 0 Then
		Report.Put(Template.GetArea("IsBlankString"));
		
		For Each Record In CollapsedData Do
			Total = Total + Record.TotalByComment;
			RowsArray = EventLogData.FindRows(
				New Structure("Level, Comment",
					EventLogLevel.Error,
					Record.Comment));
			
			Area = Template.GetArea("TabularSectionBodyHeader");
			Area.Parameters.Fill(Record);
			Report.Put(Area);
			
			Report.StartRowGroup(, False);
			For Each String In RowsArray Do
				Area = Template.GetArea("TabularSectionBodyDetails");
				Area.Parameters.Fill(String);
				Report.Put(Area);
			EndDo;
			Report.EndRowGroup();
			Report.Put(Template.GetArea("IsBlankString"));
		EndDo;
	EndIf;
	
	Result = New Structure("TabularSection, Total", Report, Total);
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf