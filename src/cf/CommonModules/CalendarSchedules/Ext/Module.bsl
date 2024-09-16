///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns the dates that are different from the specified date Datat on the number of days
// included in the specified schedule Graficart.
//
// Parameters:
//   WorkScheduleCalendar	- CatalogRef.Calendars
//	             	- CatalogRef.BusinessCalendars -  
//                    
//   DateFrom			- Date -  the date from which to calculate the number of days.
//   DaysArray		- Array of Number -  the number of days to increase the start date by.
//   CalculateNextDateFromPrevious	- Boolean -  whether to calculate the next date from the previous one or
//											           all dates are calculated from the passed date.
//   RaiseException1 - Boolean -  if True, throw an exception if the graph is empty.
//
// Returns:
//   Undefined, Array - 
//	                        
//
Function DatesByCalendar(Val WorkScheduleCalendar, Val DateFrom, Val DaysArray, Val CalculateNextDateFromPrevious = False, RaiseException1 = True) Export
	
	If Not ValueIsFilled(WorkScheduleCalendar) Then
		If RaiseException1 Then
			Raise NStr("en = 'Work schedule or business calendar is not specified.';");
		EndIf;
		Return Undefined;
	EndIf;
	
	If TypeOf(WorkScheduleCalendar) <> Type("CatalogRef.BusinessCalendars") Then
		If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
			ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
			Return ModuleWorkSchedules.DatesBySchedule(
				WorkScheduleCalendar, DateFrom, DaysArray, CalculateNextDateFromPrevious, RaiseException1);
		EndIf;
	EndIf;
	
	ShiftDays = DaysIncrement(DaysArray, CalculateNextDateFromPrevious);
	
	KindsOfDaysIncludedInCalculation = New Array();
	KindsOfDaysIncludedInCalculation.Add(Enums.BusinessCalendarDaysKinds.Work); 
	KindsOfDaysIncludedInCalculation.Add(Enums.BusinessCalendarDaysKinds.Preholiday);
	
	Query = New Query();
	Query.SetParameter("BusinessCalendar", WorkScheduleCalendar);
	Query.SetParameter("DateFrom", BegOfDay(DateFrom));
	Query.SetParameter("Days", ShiftDays.DaysIncrement.UnloadColumn("DaysCount"));
	Query.SetParameter("DaysKinds", KindsOfDaysIncludedInCalculation);
	Query.Text =
		"SELECT TOP 0
		|	CalendarSchedules.Date AS Date
		|FROM
		|	InformationRegister.BusinessCalendarData AS CalendarSchedules
		|WHERE
		|	CalendarSchedules.Date > &DateFrom
		|	AND CalendarSchedules.BusinessCalendar = &BusinessCalendar
		|	AND CalendarSchedules.DayKind IN(&DaysKinds)
		|
		|ORDER BY
		|	Date";

	// 
	QuerySchema = New QuerySchema();
	QuerySchema.SetQueryText(Query.Text);
	QuerySchema.QueryBatch[0].Operators[0].RetrievedRecordsCount = ShiftDays.Maximum;
	Query.Text = QuerySchema.GetQueryText();

	RequestedDays = New Map();
	For Each TableRow In ShiftDays.DaysIncrement Do
		RequestedDays.Insert(TableRow.DaysCount, False);
	EndDo;
	
	Selection = Query.Execute().Select();
	If Selection.Count() < ShiftDays.Maximum Then
		If RaiseException1 Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Business calendar ""%1"" is not filled in for the specified number of workdays after %2.';"), 
				WorkScheduleCalendar, 
				Format(DateFrom, "DLF=D"));
		Else
			Return Undefined;
		EndIf;
	EndIf;
	
	OfDays = 0;
	While Selection.Next() Do
		OfDays = OfDays + 1;
		If RequestedDays[OfDays] = False Then
			RequestedDays.Insert(OfDays, Selection.Date);
		EndIf;
	EndDo;
	
	DatesArray = New Array;
	For Each TableRow In ShiftDays.DaysIncrement Do
		Date = RequestedDays[TableRow.DaysCount];
		CommonClientServer.Validate(TypeOf(Date) = Type("Date") And ValueIsFilled(Date));
		DatesArray.Add(Date);
	EndDo;
	
	Return DatesArray;
	
EndFunction

// Returns a date that differs from the specified datestate By the number of days
// included in the specified schedule or work Schedule production calendar.
//
// Parameters:
//   WorkScheduleCalendar	- CatalogRef.Calendars
//	             	- CatalogRef.BusinessCalendars -  
//                    
//   DateFrom			- Date -  the date from which to calculate the number of days.
//   DaysCount	- Number -  the number of days to increase the start date by.
//   RaiseException1 - Boolean -  if True, throw an exception if the graph is empty.
//
// Returns:
//   Date, Undefined - 
//	                      
//
Function DateByCalendar(Val WorkScheduleCalendar, Val DateFrom, Val DaysCount, RaiseException1 = True) Export
	
	If Not ValueIsFilled(WorkScheduleCalendar) Then
		If RaiseException1 Then
			Raise NStr("en = 'Work schedule or business calendar is not specified.';");
		EndIf;
		Return Undefined;
	EndIf;
	
	DateFrom = BegOfDay(DateFrom);
	
	If DaysCount = 0 Then
		Return DateFrom;
	EndIf;
	
	DaysArray = New Array;
	DaysArray.Add(DaysCount);
	
	DatesArray = DatesByCalendar(WorkScheduleCalendar, DateFrom, DaysArray, , RaiseException1);
	
	Return ?(DatesArray <> Undefined, DatesArray[0], Undefined);
	
EndFunction

// Defines the number of days included in the schedule for the specified period.
//
// Parameters:
//   WorkScheduleCalendar	- CatalogRef.Calendars
//	             	- CatalogRef.BusinessCalendars -  
//                    
//   StartDate		- Date -  start date of the period.
//   EndDate	- Date -  end date of the period.
//   RaiseException1 - Boolean -  if True, throw an exception if the graph is empty.
//
// Returns:
//   Number		- 
//	              
//
Function DateDiffByCalendar(Val WorkScheduleCalendar, Val StartDate, Val EndDate, RaiseException1 = True) Export

	If Not ValueIsFilled(WorkScheduleCalendar) Then
		If RaiseException1 Then
			Raise NStr("en = 'Business calendar is not specified.';");
		EndIf;
		Return Undefined;
	EndIf;

	If TypeOf(WorkScheduleCalendar) <> Type("CatalogRef.BusinessCalendars") Then
		Result = Undefined;
		If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
			ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
			Result = ModuleWorkSchedules.DateDiffByCalendar(WorkScheduleCalendar, StartDate, EndDate, RaiseException1);
		EndIf;
		Return Result;
	EndIf;

	If EndDate < StartDate Then
		Vrem = StartDate;
		StartDate = EndDate;
		EndDate = Vrem;
	EndIf;
	
	//  
	// 
	Years = New Array();
	Year = Year(StartDate);
	While Year <= Year(EndDate) Do
		Years.Add(Year);
		Year = Year + 1;
	EndDo;
	
	Query = New Query();
	Query.SetParameter("Calendar", WorkScheduleCalendar);
	Query.SetParameter("Years", Years);
	Query.Text = 
		"SELECT DISTINCT
		|	CalendarData.Year AS Year
		|FROM
		|	InformationRegister.BusinessCalendarData AS CalendarData
		|WHERE
		|	CalendarData.BusinessCalendar = &Calendar
		|	AND CalendarData.Year IN(&Years)";
	If Query.Execute().Unload().Count() <> Years.Count() Then
		If RaiseException1 Then
			ErrorMessage = NStr("en = 'The ""%1"" work schedule is blank for period: %2.';");
			Raise StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, WorkScheduleCalendar, PeriodPresentation(StartDate, EndOfDay(EndDate)));
		Else
			Return Undefined;
		EndIf;
	EndIf;

	IncludedInSchedule = New Array();
	IncludedInSchedule.Add(Enums.BusinessCalendarDaysKinds.Work);
	IncludedInSchedule.Add(Enums.BusinessCalendarDaysKinds.Preholiday);
	
	Query = New Query();
	Query.SetParameter("Calendar", WorkScheduleCalendar);
	Query.SetParameter("Years", Years);
	Query.SetParameter("DaysKinds", IncludedInSchedule);
	Query.SetParameter("StartDate", StartDate);
	Query.SetParameter("EndDate", EndDate);
	Query.Text = 
		"SELECT
		|	COUNT(CalendarData.Date) AS OfDays
		|FROM
		|	InformationRegister.BusinessCalendarData AS CalendarData
		|WHERE
		|	CalendarData.BusinessCalendar = &Calendar
		|	AND CalendarData.Year IN(&Years)
		|	AND CalendarData.DayKind IN(&DaysKinds)
		|	AND CalendarData.Date BETWEEN &StartDate AND &EndDate";

	Return Query.Execute().Unload().UnloadColumn("OfDays")[0];

EndFunction

// Constructor of parameters for getting the nearest working dates on the calendar.
//  See NearestWorkDates.
//
// Parameters:
//  BusinessCalendar	 - CatalogRef.BusinessCalendars	 -
//  	if specified, the non-working periods will be filled in by default as an Array of descriptions
//  	obtained by the Non-Working Days period method.
// 
// Returns:
//  Structure:
//   * GetPrevious - Boolean - :
//       
//       
//       
//   * ConsiderNonWorkPeriods - Boolean - 
//       
//       
//       :
//   * NonWorkPeriods - Undefined - 
//       
//       
//       
//       :
//   * RaiseException1 - Boolean -  calling an exception if the schedule is not filled in
//       if True, throw an exception if the graph is empty.
//       if False, the dates that failed to determine the nearest date will simply be skipped.
//       The default value is True.
//   * ShouldGetDatesIfCalendarNotFilled - Boolean -  
//       
//
Function NearestWorkDatesReceivingParameters(BusinessCalendar = Undefined) Export
	
	Parameters = New Structure;
	Parameters.Insert("GetPrevious", False);
	Parameters.Insert("ConsiderNonWorkPeriods", True);
	Parameters.Insert("NonWorkPeriods", Undefined);
	Parameters.Insert("RaiseException1", True);
	Parameters.Insert("ShouldGetDatesIfCalendarNotFilled", False);
	
	If BusinessCalendar <> Undefined Then
		Parameters.NonWorkPeriods = NonWorkDaysPeriods(BusinessCalendar, New StandardPeriod());
	EndIf;
	
	Return Parameters;
	
EndFunction

// Defines the date of the nearest business day for each date.
//
// Parameters:
//  BusinessCalendar	 - CatalogRef.BusinessCalendars	 -  the calendar used for the calculation.
//  InitialDates				 - Array of Date -  dates that will be searched for the nearest ones.
//  ReceivingParameters			 - See NearestWorkDatesReceivingParameters.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - Date -  start date,
//   * Value - Date -  the working date closest to it (if the working date is passed, it is also returned).
//
Function NearestWorkDates(BusinessCalendar, InitialDates, ReceivingParameters = Undefined) Export
	
	If ReceivingParameters = Undefined Then
		ReceivingParameters = NearestWorkDatesReceivingParameters();
	EndIf;
	
	CommonClientServer.CheckParameter(
		"CalendarSchedules.NearestWorkDates", 
		"BusinessCalendar", 
		BusinessCalendar, 
		Type("CatalogRef.BusinessCalendars"));

	CommonClientServer.Validate(
		ValueIsFilled(BusinessCalendar), 
		NStr("en = 'The schedule or business calendar is not specified.';"), 
		"CalendarSchedules.NearestWorkDates");
	
	WorkdaysDates = New Map;
	
	Selection = SelectionOfNearestBusinessDates(BusinessCalendar, InitialDates, ReceivingParameters);
	If Not ValueIsFilled(Selection) Then
		Return WorkdaysDates;
	EndIf;
	
	DefaultCalendarData = Catalogs.BusinessCalendars.NewBusinessCalendarsData();
	
	While Selection.Next() Do
		
		If ValueIsFilled(Selection.NearestDate) Then
			NearestDate = Selection.NearestDate;
		ElsIf ReceivingParameters.ShouldGetDatesIfCalendarNotFilled Then
			NearestDate = NearestBusinessDateFromDefaultCalendar(Selection.Date, DefaultCalendarData,
				ReceivingParameters.GetPrevious);
		Else
			NearestDate = Undefined;
		EndIf;
		
		If ValueIsFilled(NearestDate) Then
			WorkdaysDates.Insert(Selection.Date, NearestDate);
		ElsIf ReceivingParameters.RaiseException1 Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot determine the workday nearest to %1. 
					 |The work schedule might be blank.';"), 
				Format(Selection.Date, "DLF=D"));
		EndIf;
		
	EndDo;
	
	Return WorkdaysDates;
	
EndFunction

// Creates work schedules for dates included in the specified schedules for the specified period.
// If the schedule for a pre-holiday day is not set, it is determined as if this day would be a working day.
// Keep in mind that this function must have a work Schedule subsystem.
//
// Parameters:
//  Schedules       - Array -  array of elements of the reference Link type.Calendars for which schedules are created.
//  StartDate    - Date   -  the start date of the period for which you want to generate.
//  EndDate - Date   -  end date of the period.
//
// Returns:
//   ValueTable:
//    * WorkScheduleCalendar    - CatalogRef.Calendars -  work schedule.
//    * ScheduleDate     - Date -  date in the work schedule work Schedule.
//    * BeginTime     - Date -  start time on the Datagraphics day.
//    * EndTime  - Date -  the end time of the work day Datagraphic.
//
Function WorkSchedulesForPeriod(Schedules, StartDate, EndDate) Export
	
	If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
		ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
		Return ModuleWorkSchedules.WorkSchedulesForPeriod(Schedules, StartDate, EndDate);
	EndIf;
	
	Raise NStr("en = 'The ""Work schedules"" subsystem is not found.';");
	
EndFunction

// Creates a temporary table in the work Schedule Manager with columns corresponding to the return value
// of the work schedule function Period.
// Keep in mind that this function requires a work Schedule subsystem.
//
// Parameters:
//  TempTablesManager - TempTablesManager -  the Manager where the temporary table will be created.
//  Schedules       - Array -  array of elements of the reference Link type.Calendars for which schedules are created.
//  StartDate    - Date   -  the start date of the period for which you want to generate.
//  EndDate - Date   -  end date of the period.
//
Procedure CreateTTWorkSchedulesForPeriod(TempTablesManager, Schedules, StartDate, EndDate) Export
	
	If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
		ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
		ModuleWorkSchedules.CreateTTWorkSchedulesForPeriod(TempTablesManager, Schedules, StartDate, EndDate);
		Return;
	EndIf;
	
	Raise NStr("en = 'The ""Work schedules"" subsystem is not found.';");
	
EndProcedure

// Fills in the details in the form if the only production calendar is used.
//
// Parameters:
//  Form         - ClientApplicationForm -  the form where you need to fill in the details.
//  AttributePath2 - String           -  data path, for example: "Object.Production calendar".
//  CRTR			  - String           -  individual taxpayer number (code of the reason for registration) for determining the region.
//
Procedure FillBusinessCalendarInForm(Form, AttributePath2, CRTR = Undefined) Export
	
	Calendar = Undefined;
	
	If Not GetFunctionalOption("UseMultipleBusinessCalendars") Then
		Calendar = SingleBusinessCalendar();
	Else
		Calendar = StateBusinessCalendar(CRTR);
	EndIf;
	
	If Calendar <> Undefined Then
		CommonClientServer.SetFormAttributeByPath(Form, AttributePath2, Calendar);
	EndIf;
	
EndProcedure

// Returns the main production calendar used in accounting.
//
// Returns:
//   CatalogRef.BusinessCalendars, Undefined -  
//                                                              
//
Function MainBusinessCalendar() Export
		
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return Undefined;
	EndIf;	
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	Return ModuleFillingInCalendarSchedules.MainBusinessCalendar();
	
EndFunction

// Prepares a description of special non-working periods established, for example, by law.
// These periods can be taken into account by schedules, redefining the filling according to the production calendar data.
// 
// Parameters:
//   BusinessCalendar - CatalogRef.BusinessCalendars -  the calendar that is the source.
//   PeriodFilter - StandardPeriod -  time interval within which to define non-working periods.
// Returns:
//   Array - :
//    * Number     - Number -  the sequence number of the period that can be used for identification.
//    * Period    - StandardPeriod -  non-working period.
//    * Basis - String -  a regulatory act that establishes a non-working period.
//    * Dates - Array of Date -  dates included in the non-working period.
//    * Presentation  - String -  custom view of the period.
//
Function NonWorkDaysPeriods(BusinessCalendar, PeriodFilter) Export

	TimeIntervals = New Array;
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return TimeIntervals;
	EndIf;
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	TimeIntervals = ModuleFillingInCalendarSchedules.NonWorkDaysPeriods(BusinessCalendar, PeriodFilter);
	
	DeletePeriodsThatDoNotMatchFilter(TimeIntervals, PeriodFilter);
	
	Return TimeIntervals;

EndFunction

#Region ForCallsFromOtherSubsystems

// 

// The event occurs when collecting information about classifiers and registering production calendars.
// 
// Parameters:
//   Classifiers - See ClassifiersOperationsOverridable.OnAddClassifiers.Classifiers
//
Procedure OnAddClassifiers(Classifiers) Export
	
	LongDesc = Undefined;
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		LongDesc = ModuleClassifiersOperations.ClassifierDetails();
	EndIf;
	If LongDesc = Undefined Then
		Return;
	EndIf;
	
	LongDesc.Id = ClassifierID();
	LongDesc.Description = NStr("en = 'Calendars';");
	LongDesc.AutoUpdate = True;
	LongDesc.SharedData = True;
	LongDesc.SharedDataProcessing = True;
	LongDesc.SaveFileToCache = True;
	
	Classifiers.Add(LongDesc);
	
EndProcedure

// See ClassifiersOperationsOverridable.OnImportClassifier.
Procedure OnImportClassifier(Id, Version, Address, Processed, AdditionalParameters) Export
	
	If Id <> ClassifierID() Then
		Return;
	EndIf;
	
	LoadBusinessCalendarsData(Version, Address, Processed, AdditionalParameters);
	
EndProcedure

// End OnlineUserSupport.ClassifiersOperations

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. 
//  
// 
// 
//
// Parameters:
//    Schedule	- CatalogRef.Calendars
//	        	- CatalogRef.BusinessCalendars -  
//                    
//    InitialDates 				- Array -  array of dates (date).
//    GetPrevious		- Boolean - :
//										 
//										
//    RaiseException1 - Boolean -  if True, throw an exception if the graph is empty.
//    IgnoreUnfilledSchedule - Boolean -  if True, a match will be returned in any case. 
//										Start dates that don't have values because the chart is empty will not be included.
//
// Returns:
//    - Map of KeyAndValue:
//      * Key - Date -  date from the passed array
//      * Value - Date -  the closest working date to it (if a working date is passed, it is also returned).
//							If the selected graph is not filled, and cause an exception = False, it returns Undefined
//    - Undefined
//
Function ClosestWorkdaysDates(Schedule, InitialDates, GetPrevious = False, RaiseException1 = True, 
	IgnoreUnfilledSchedule = False) Export
	
	If TypeOf(Schedule) <> Type("CatalogRef.BusinessCalendars") Then
		If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
			ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
			ReceivingParameters = ModuleWorkSchedules.NearestDatesByScheduleReceivingParameters();
			ReceivingParameters.GetPrevious = GetPrevious;
			ReceivingParameters.RaiseException1 = RaiseException1;
			ReceivingParameters.IgnoreUnfilledSchedule = IgnoreUnfilledSchedule;
			Return ModuleWorkSchedules.NearestDatesIncludedInSchedule(Schedule, InitialDates, ReceivingParameters);
		EndIf;
	EndIf;
	
	ReceivingParameters = NearestWorkDatesReceivingParameters();
	ReceivingParameters.GetPrevious = GetPrevious;
	ReceivingParameters.RaiseException1 = RaiseException1;
	Return NearestWorkDates(Schedule, InitialDates, ReceivingParameters);
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

//  
// 
// 
// 
// Parameters:
//  DaysArray - Array of Number - 
//  CalculateNextDateFromPrevious - Boolean - 
// 
// Returns:
//  Structure:
//   * DaysIncrement - ValueTable
//   * Maximum - Number
//
Function DaysIncrement(DaysArray, Val CalculateNextDateFromPrevious = False) Export

	Result = New Structure();
	Result.Insert("DaysIncrement", New ValueTable);
	Result.Insert("Maximum", 0);

	Result.DaysIncrement.Columns.Add("RowIndex", New TypeDescription("Number"));
	Result.DaysIncrement.Columns.Add("DaysCount", New TypeDescription("Number"));
	
	DaysCount = 0;
	LineNumber = 0;
	For Each DaysRow In DaysArray Do
		DaysCount = DaysCount + DaysRow;
		String = Result.DaysIncrement.Add();
		String.RowIndex = LineNumber;
		String.DaysCount = ?(CalculateNextDateFromPrevious, DaysCount, DaysRow);
		Result.Maximum = Max(Result.Maximum, String.DaysCount);
		LineNumber = LineNumber + 1;
	EndDo;
	
	Return Result;

EndFunction

// It is used for updating items related to the production calendar, 
// such as work Schedules.
//
// Parameters:
//  ChangesTable - ValueTable:
//    * BusinessCalendarCode - Number -  code of the production calendar whose data has changed,
//    * Year - Number -  the year for which you need to update the data.
//
Procedure DistributeBusinessCalendarsDataChanges(ChangesTable) Export
	
	CalendarSchedulesOverridable.OnUpdateBusinessCalendars(ChangesTable);
	
	If Common.DataSeparationEnabled() Then
		PlanUpdateOfDataDependentOnBusinessCalendars(ChangesTable);
		Return;
	EndIf;
	
	FillDataDependentOnBusinessCalendars(ChangesTable);
	
EndProcedure

// It is used for updating data areas related to the production calendar items, 
// such as work Schedules.
//
// Parameters:
//  ChangesTable - ValueTable:
//    * BusinessCalendarCode - Number -  code of the production calendar whose data has changed,
//    * Year - Number -  the year for which you need to update the data.
//
Procedure FillDataDependentOnBusinessCalendars(ChangesTable) Export
	
	If ChangesTable.Count() = 0 Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
		ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
		ModuleWorkSchedules.UpdateWorkSchedulesAccordingToBusinessCalendars(ChangesTable);
	EndIf;
	
	CalendarSchedulesOverridable.OnUpdateDataDependentOnBusinessCalendars(ChangesTable);
	
EndProcedure

// Defines the internal classifier ID for the classifier subsystem.
//
// Returns:
//  String - 
//
Function ClassifierID() Export
	Return "Calendars20";
EndFunction

// Specifies the version of calendar data embedded in the configuration.
//
// Returns:
//   Number -  version number.
//
Function CalendarsVersion() Export
	
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return 0;
	EndIf;
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	Return ModuleFillingInCalendarSchedules.CalendarsVersion();
	
EndFunction

// Determines the version of the classifier data uploaded to the IB.
//
// Returns:
//   Number - 
//
Function LoadedCalendarsVersion() Export
	
	LoadedCalendarsVersion = Undefined;
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		LoadedCalendarsVersion = ModuleClassifiersOperations.ClassifierVersion(ClassifierID());
	EndIf;
	
	If LoadedCalendarsVersion = Undefined Then
		LoadedCalendarsVersion = 0;
	EndIf;
	
	Return LoadedCalendarsVersion;
	
EndFunction

// Requests the file with the data classification and calendars. 
// Converts the resulting file to a structure with calendar tables and their data.
// If the classifier subsystem is missing or the classifier file could not be retrieved, an exception is thrown.
//
// Returns:
//  Structure:
//   * BusinessCalendars - Structure:
//     ** TableName - String          -  table name.
//     ** Data     - ValueTable - 
//   * BusinessCalendarsData - Structure:
//     ** TableName - String          -  table name.
//     ** Data     - ValueTable -  converted calendar data table from XML.
//   * NonWorkDaysPeriods - Structure:
//     ** TableName - String          -  table name.
//     ** Data     - ValueTable -  converted calendar data table from XML.
//
Function ClassifierData() Export
	
	ClassifierData      = New Structure;
	
	BusinessCalendars = New Structure;
	BusinessCalendars.Insert("TableName", "");
	BusinessCalendars.Insert("Data",     New ValueTable());
	
	BusinessCalendarsData = New Structure(New FixedStructure(BusinessCalendars));
	NonWorkDaysPeriods             = New Structure(New FixedStructure(BusinessCalendars));

	ClassifierData.Insert("BusinessCalendarsData", BusinessCalendarsData);	
	ClassifierData.Insert("BusinessCalendars",        BusinessCalendars);
	ClassifierData.Insert("NonWorkDaysPeriods",             NonWorkDaysPeriods);
	
	CalendarSchedulesLocalization.WhenReceivingClassifierData(ClassifierData);
	
	Return ClassifierData;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "CalendarSchedules.UpdateBusinessCalendars";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.66";
	Handler.Procedure = "CalendarSchedules.UpdateDependentBusinessCalendarsData";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.102";
	Handler.Procedure = "CalendarSchedules.UpdateMultipleBusinessCalendarsUsage";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.3.113";
	Handler.Procedure = "CalendarSchedules.ResetClassifierVersion";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.5.80";
	Handler.Procedure = "CalendarSchedules.FixTheDataOfDependentCalendars";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.Version = BusinessCalendarsUpdateVersion();
	Handler.Procedure = "CalendarSchedules.UpdateBusinessCalendars";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.Version = BusinessCalendarsDataUpdateVersion();
	Handler.Procedure = "CalendarSchedules.UpdateBusinessCalendarsData";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	
	AddHandlerOfDataDependentOnBusinessCalendars(Handlers);
	
EndProcedure

// See UsersOverridable.OnDefineRoleAssignment
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// 
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.AddEditCalendarSchedules.Name);
	
EndProcedure

// Parameters:
//   Types - See ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport.Types
//
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
	
	Types.Add(Metadata.Catalogs.BusinessCalendars);
	
EndProcedure

// See SaaSOperationsOverridable.OnEnableSeparationByDataAreas.
Procedure OnEnableSeparationByDataAreas() Export
	
	CalendarsTable = Catalogs.BusinessCalendars.DefaultBusinessCalendars();
	Catalogs.BusinessCalendars.UpdateBusinessCalendars(CalendarsTable);
	UpdateMultipleBusinessCalendarsUsage();
	
	BusinessCalendarsData = Catalogs.BusinessCalendars.DefaultBusinessCalendarsData();
	NonWorkDaysPeriods = Catalogs.BusinessCalendars.DefaultNonWorkDaysPeriods();
	FillBusinessCalendarsDataOnUpdate(BusinessCalendarsData, NonWorkDaysPeriods);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Updates data that is dependent on production calendars.
//
Procedure UpdateDataDependentOnBusinessCalendars(ParametersOfUpdate) Export
	
	If Not ParametersOfUpdate.Property("ChangesTable") Then
		ParametersOfUpdate.ProcessingCompleted = True;
		Return;
	EndIf;
	
	ChangesTable = ParametersOfUpdate.ChangesTable; // ValueTable
	ChangesTable.GroupBy("BusinessCalendarCode, Year");
	
	FillDataDependentOnBusinessCalendars(ChangesTable);
	
	ParametersOfUpdate.ProcessingCompleted = True;
	
EndProcedure

Function ThereAreChangeableObjectsDependentOnProductionCalendars() Export
	
	ObjectsToChange = New Array;
	FillObjectsToChangeDependentOnBusinessCalendars(ObjectsToChange);
	Return ObjectsToChange.Count() > 0;
	
EndFunction

#EndRegion

#Region Private

// Gets the only production calendar in the IB.
//
Function SingleBusinessCalendar()
	
	UsedCalendars = Catalogs.BusinessCalendars.BusinessCalendarsList();
	
	If UsedCalendars.Count() = 1 Then
		Return UsedCalendars[0];
	EndIf;
	
EndFunction

// Defines the regional production calendar for the checkpoint.
//
Function StateBusinessCalendar(CRTR)
	
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return Undefined;
	EndIf;	
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	Return ModuleFillingInCalendarSchedules.StateBusinessCalendar(CRTR);
	
EndFunction

Procedure LoadBusinessCalendarsData(Version, Address, Processed, AdditionalParameters)
	
	ClassifierData = ClassifierFileData(Address);
	
	// 
	CalendarsTable = ClassifierData["BusinessCalendars"].Data;
	Catalogs.BusinessCalendars.UpdateBusinessCalendars(CalendarsTable);
	
	// 
	XMLData1 = ClassifierData["BusinessCalendarsData"];
	DataTable = Catalogs.BusinessCalendars.BusinessCalendarsDataFromXML(XMLData1, CalendarsTable);
	ChangesTable = Catalogs.BusinessCalendars.UpdateBusinessCalendarsData(DataTable);
	
	XMLPeriods = ClassifierData["NonWorkDaysPeriods"];
	PeriodsTable = Catalogs.BusinessCalendars.NonWorkDaysPeriodsFromXML(XMLPeriods, CalendarsTable);
	CommonClientServer.SupplementTable(
		Catalogs.BusinessCalendars.UpdateNonWorkDaysPeriods(PeriodsTable), ChangesTable);
	
	ChangesTable.GroupBy("BusinessCalendarCode, Year");
	
	CalendarSchedulesOverridable.OnUpdateBusinessCalendars(ChangesTable);
	
	If Not Common.DataSeparationEnabled() Then
		FillDataDependentOnBusinessCalendars(ChangesTable);
	Else
		// 
		ParametersOfUpdate = New Structure("ChangesTable");
		ParametersOfUpdate.ChangesTable = ChangesTable;
		AdditionalParameters.Insert(ClassifierID(), ParametersOfUpdate);
	EndIf;
	
	Processed = True;
	
EndProcedure

Function ClassifierFileData(Address) Export
	
	ClassifierData = New Structure(
		"BusinessCalendars,
		|BusinessCalendarsData,
		|NonWorkDaysPeriods");
	
	PathToFile = GetTempFileName();
	BinaryData = GetFromTempStorage(Address); // BinaryData
	BinaryData.Write(PathToFile);
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToFile);
	XMLReader.MoveToContent();
	CheckItemStart(XMLReader, "CalendarSuppliedData");
	XMLReader.Read();
	CheckItemStart(XMLReader, "Calendars");
	
	ClassifierData.BusinessCalendars = Common.ReadXMLToTable(XMLReader);
	
	XMLReader.Read();
	CheckItemEnd(XMLReader, "Calendars");
	XMLReader.Read();
	CheckItemStart(XMLReader, "CalendarData");
	
	ClassifierData.BusinessCalendarsData = Common.ReadXMLToTable(XMLReader);
	
	XMLReader.Read();
	CheckItemEnd(XMLReader, "CalendarData");
	XMLReader.Read();
	CheckItemStart(XMLReader, "NonWorkingPeriods");

	ClassifierData.NonWorkDaysPeriods = Common.ReadXMLToTable(XMLReader);
	
	XMLReader.Close();
	DeleteFiles(PathToFile);
	
	Return ClassifierData;
	
EndFunction

Procedure CheckItemStart(Val XMLReader, Val Name)
	
	If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> Name Then
		EventName = NStr("en = 'Calendar schedules.Process classifier file';", Common.DefaultLanguageCode());
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid data file format. Start of ""%1"" element is expected.';"), 
			Name);
		WriteLogEvent(EventName, EventLogLevel.Error, , , MessageText);
		Raise MessageText;
	EndIf;
	
EndProcedure

Procedure CheckItemEnd(Val XMLReader, Val Name)
	
	If XMLReader.NodeType <> XMLNodeType.EndElement Or XMLReader.Name <> Name Then
		EventName = NStr("en = 'Calendar schedules.Process classifier file';", Common.DefaultLanguageCode());
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid data file format. End of the ""%1"" element is expected.';"), 
			Name);
		WriteLogEvent(EventName, EventLogLevel.Error, , , MessageText);
		Raise MessageText;
	EndIf;
	
EndProcedure

Function BusinessCalendarsUpdateVersion()
	
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return "1.0.0.1";
	EndIf;	
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	Return ModuleFillingInCalendarSchedules.BusinessCalendarsUpdateVersion();
	
EndFunction

Function BusinessCalendarsDataUpdateVersion()
	
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return "1.0.0.1";
	EndIf;
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	Return ModuleFillingInCalendarSchedules.BusinessCalendarsDataUpdateVersion();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Updates the production calendars directory from the same layout.
//
Procedure UpdateBusinessCalendars() Export
	
	If Common.IsStandaloneWorkplace() Then
		Return;
	EndIf;
	
	BuiltInCalendarsVersion = CalendarsVersion();
	If BuiltInCalendarsVersion <= LoadedCalendarsVersion() Then
		Return;
	EndIf;
	
	CalendarsTable = Catalogs.BusinessCalendars.BusinessCalendarsFromTemplate();
	Catalogs.BusinessCalendars.UpdateBusinessCalendars(CalendarsTable);
	UpdateMultipleBusinessCalendarsUsage();
	
	BusinessCalendarsData = Catalogs.BusinessCalendars.BusinessCalendarsDataFromTemplate();
	NonWorkDaysPeriods = Catalogs.BusinessCalendars.NonWorkDaysPeriodsFromTemplate();
	FillBusinessCalendarsDataOnUpdate(BusinessCalendarsData, NonWorkDaysPeriods);
	
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ModuleClassifiersOperations.SetClassifierVersion(ClassifierID(), BuiltInCalendarsVersion);
	EndIf;
	
EndProcedure

// Updates production calendar data from the layout.
//  Dnepropetrovshchina.
//
Procedure UpdateBusinessCalendarsData() Export
	
	If Common.IsStandaloneWorkplace() Then
		Return;
	EndIf;
	
	BuiltInCalendarsVersion = CalendarsVersion();
	If BuiltInCalendarsVersion <= LoadedCalendarsVersion() Then
		Return;
	EndIf;
	
	BusinessCalendarsData = Catalogs.BusinessCalendars.BusinessCalendarsDataFromTemplate();
	NonWorkDaysPeriods = Catalogs.BusinessCalendars.NonWorkDaysPeriodsFromTemplate();
	FillBusinessCalendarsDataOnUpdate(BusinessCalendarsData, NonWorkDaysPeriods);
	
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ModuleClassifiersOperations.SetClassifierVersion(ClassifierID(), BuiltInCalendarsVersion);
	EndIf;
	
EndProcedure

// Updates the data of dependent production calendars from the base ones.
//
Procedure UpdateDependentBusinessCalendarsData() Export
	
	If Common.IsStandaloneWorkplace() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Year", 2018);
	Query.Text = 
		"SELECT
		|	DependentCalendars.Ref AS Calendar,
		|	DependentCalendars.BasicCalendar AS BasicCalendar
		|INTO TTDependentCalendars
		|FROM
		|	Catalog.BusinessCalendars AS DependentCalendars
		|WHERE
		|	DependentCalendars.BasicCalendar <> VALUE(Catalog.BusinessCalendars.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	CalendarsData.BusinessCalendar AS BusinessCalendar,
		|	CalendarsData.Year AS Year
		|INTO TTCalendarYears
		|FROM
		|	InformationRegister.BusinessCalendarData AS CalendarsData
		|WHERE
		|	CalendarsData.Year >= &Year
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DependentCalendars.BasicCalendar AS BasicCalendar,
		|	DependentCalendars.BasicCalendar.Code AS BusinessCalendarCode,
		|	BasicCalendarData.Year AS Year
		|FROM
		|	TTDependentCalendars AS DependentCalendars
		|		INNER JOIN TTCalendarYears AS BasicCalendarData
		|		ON (BasicCalendarData.BusinessCalendar = DependentCalendars.BasicCalendar)
		|		LEFT JOIN TTCalendarYears AS DependentCalendarData
		|		ON (DependentCalendarData.BusinessCalendar = DependentCalendars.Calendar)
		|			AND (DependentCalendarData.Year = BasicCalendarData.Year)
		|WHERE
		|	DependentCalendarData.Year IS NULL";
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	ChangesTable = QueryResult.Unload();
	Catalogs.BusinessCalendars.UpdateDependentBusinessCalendarsData(ChangesTable);
	
	If Common.DataSeparationEnabled() Then
		PlanUpdateOfDataDependentOnBusinessCalendars(ChangesTable);
		Return;
	EndIf;
	
	HandlerParameters = InfobaseUpdateInternal.DeferredUpdateHandlerParameters(
		"CalendarSchedules.UpdateDataDependentOnBusinessCalendars");
	If HandlerParameters <> Undefined And HandlerParameters.Property("ChangesTable") Then
		CommonClientServer.SupplementTable(ChangesTable, HandlerParameters.ChangesTable);
	EndIf;
	
	HandlerParameters = New Structure("ChangesTable");
	HandlerParameters.ChangesTable = ChangesTable;
	InfobaseUpdateInternal.WriteDeferredUpdateHandlerParameters(
		"CalendarSchedules.UpdateDataDependentOnBusinessCalendars", HandlerParameters);
	
EndProcedure

Procedure FillBusinessCalendarDependentDataUpdateData(ParametersOfUpdate) Export
	
EndProcedure

Procedure FillObjectsToBlockDependentOnBusinessCalendars(Handler)
	
	ObjectsToLock = New Array;
	
	If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
		ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
		ModuleWorkSchedules.FillObjectsToBlockDependentOnBusinessCalendars(ObjectsToLock);
	EndIf;
	
	CalendarSchedulesOverridable.OnFillObjectsToBlockDependentOnBusinessCalendars(ObjectsToLock);
	
	Handler.ObjectsToLock = StrConcat(ObjectsToLock, ",");
	
EndProcedure

Procedure FillObjectsToChangeDependentOnBusinessCalendars(ObjectsToChange)
	
	If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
		ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
		ModuleWorkSchedules.FillObjectsToChangeDependentOnBusinessCalendars(ObjectsToChange);
	EndIf;
	
	CalendarSchedulesOverridable.OnFillObjectsToChangeDependentOnBusinessCalendars(ObjectsToChange);
	
EndProcedure

// The procedure performs an update of the data-dependent production of calendars, 
// on all data regions.
//
Procedure PlanUpdateOfDataDependentOnBusinessCalendars(Val UpdateConditions)
	
	CalendarSchedulesInternal.PlanUpdateOfDataDependentOnBusinessCalendars(UpdateConditions);
	
EndProcedure

Procedure FillBusinessCalendarsDataOnUpdate(DataTable, PeriodsTable)
	
	ChangesTable = Catalogs.BusinessCalendars.UpdateBusinessCalendarsData(DataTable);

	CommonClientServer.SupplementTable(
		Catalogs.BusinessCalendars.UpdateNonWorkDaysPeriods(PeriodsTable), ChangesTable);
	
	If Common.DataSeparationEnabled() Then
		PlanUpdateOfDataDependentOnBusinessCalendars(ChangesTable);
		Return;
	EndIf;

	HandlerParameters = InfobaseUpdateInternal.DeferredUpdateHandlerParameters(
		"CalendarSchedules.UpdateDataDependentOnBusinessCalendars");
	If HandlerParameters <> Undefined And HandlerParameters.Property("ChangesTable") Then
		CommonClientServer.SupplementTable(ChangesTable, HandlerParameters.ChangesTable);
	EndIf;
	
	HandlerParameters = New Structure("ChangesTable");
	HandlerParameters.ChangesTable = ChangesTable;
	InfobaseUpdateInternal.WriteDeferredUpdateHandlerParameters(
		"CalendarSchedules.UpdateDataDependentOnBusinessCalendars", HandlerParameters);
	
EndProcedure

// Sets the value of a constant that defines the use of multiple production calendars.
//
Procedure UpdateMultipleBusinessCalendarsUsage() Export
	
	If Common.IsStandaloneWorkplace() Then
		Return;
	EndIf;
	
	UseMultipleCalendars = Catalogs.BusinessCalendars.BusinessCalendarsList().Count() <> 1;
	If UseMultipleCalendars <> GetFunctionalOption("UseMultipleBusinessCalendars") Then
		Constants.UseMultipleBusinessCalendars.Set(UseMultipleCalendars);
	EndIf;
	
EndProcedure

Procedure AddHandlerOfDataDependentOnBusinessCalendars(Handlers)
	
	If Common.DataSeparationEnabled() Then
		// 
		Return;
	EndIf;
	
	ObjectsToChange = New Array;
	FillObjectsToChangeDependentOnBusinessCalendars(ObjectsToChange);
	If ObjectsToChange.Count() = 0 Then
		// 
		Return;
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = BusinessCalendarsDataUpdateVersion();
	Handler.Procedure = "CalendarSchedules.UpdateDataDependentOnBusinessCalendars";
	Handler.UpdateDataFillingProcedure = "CalendarSchedules.FillBusinessCalendarDependentDataUpdateData";
	Handler.ExecutionMode = "Deferred";
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	Handler.ObjectsToRead = "InformationRegister.BusinessCalendarData";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Id = New UUID("b1082291-b482-418f-82ab-3c96e93072cc");
	Handler.Comment = NStr("en = 'Updates work schedules and other data that depends on business calendars.';");
	Handler.ObjectsToChange = StrConcat(ObjectsToChange, ",");
	FillObjectsToBlockDependentOnBusinessCalendars(Handler);
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
		ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
		Priority = Handler.ExecutionPriorities.Add();
		Priority.Procedure = ModuleWorkSchedules.WorkSchedulesUpdateProcedureName();
		Priority.Order = "Before";
		Priority = Handler.ExecutionPriorities.Add();
		Priority.Procedure = ModuleWorkSchedules.ConsiderNonWorkDaysFlagSettingProcedureName();
		Priority.Order = "After";
	EndIf;
	
EndProcedure

Procedure DeletePeriodsThatDoNotMatchFilter(TimeIntervals, PeriodFilter)
	
	IndexOf = 0;
	While IndexOf < TimeIntervals.Count() Do
		PeriodDetails = TimeIntervals[IndexOf];
		If PeriodFilter.StartDate > PeriodDetails.Period.EndDate 
			Or (ValueIsFilled(PeriodFilter.EndDate) And PeriodFilter.EndDate < PeriodDetails.Period.StartDate) Then
			TimeIntervals.Delete(IndexOf);
		Else
			IndexOf = IndexOf + 1;
		EndIf; 
	EndDo;
	
EndProcedure

Function NonWorkDatesByNonWorkPeriod(NonWorkPeriods, BusinessCalendar)

	NonWorkDates = New Array;

	If TypeOf(NonWorkPeriods) = Type("Array") Then
		If NonWorkPeriods.Count() = 0 Then
			Return NonWorkDates;
		EndIf;
		If TypeOf(NonWorkPeriods[0]) = Type("Number") Then
			PeriodsDetails = NonWorkDaysPeriods(BusinessCalendar, New StandardPeriod());
			IndexOf = 0;
			While IndexOf < PeriodsDetails.Count() Do
				If NonWorkPeriods.Find(PeriodsDetails[IndexOf].Number) = Undefined Then
					PeriodsDetails.Delete(IndexOf);
				Else
					IndexOf = IndexOf + 1;
				EndIf; 
			EndDo;
		ElsIf TypeOf(NonWorkPeriods[0]) = Type("Structure") Then
			PeriodsDetails = NonWorkPeriods;
		Else
			CommonClientServer.Validate(False,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Invalid item value type in the %1 parameter:
					           |%2';"), "NonWorkPeriods", TypeOf(NonWorkPeriods[0])),
				"CalendarSchedules.NearestWorkDates");
		EndIf;
	EndIf;

	If NonWorkPeriods = Undefined Then
		PeriodsDetails = NonWorkDaysPeriods(BusinessCalendar, New StandardPeriod());
	EndIf;
	
	For Each Period In PeriodsDetails Do
		CommonClientServer.SupplementArray(NonWorkDates, Period.Dates);
	EndDo;
	
	Return NonWorkDates;
	
EndFunction

Procedure ResetClassifierVersion() Export
	
	If LoadedCalendarsVersion() = 0 Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ModuleClassifiersOperations.SetClassifierVersion(ClassifierID(), 1);
	EndIf;
	
EndProcedure

Procedure FixTheDataOfDependentCalendars() Export
	
	If Common.IsStandaloneWorkplace() Then
		Return;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("DependentCalendarsUpdateStartYear", 2018);
	Query.Text = 
		"SELECT DISTINCT
		|	DependentCalendars.Ref.Code AS CalendarCode1
		|FROM
		|	InformationRegister.BusinessCalendarData AS BaseCalendarData
		|		INNER JOIN Catalog.BusinessCalendars AS DependentCalendars
		|		ON (DependentCalendars.BasicCalendar = BaseCalendarData.BusinessCalendar)
		|			AND (BaseCalendarData.BusinessCalendar.BasicCalendar = VALUE(Catalog.BusinessCalendars.EmptyRef))
		|			AND (BaseCalendarData.Year >= &DependentCalendarsUpdateStartYear)
		|			AND (NOT TRUE IN
		|					(SELECT TOP 1
		|						TRUE
		|					FROM
		|						InformationRegister.BusinessCalendarData AS Data
		|					WHERE
		|						Data.BusinessCalendar = DependentCalendars.Ref
		|						AND Data.Year = BaseCalendarData.Year))";

	CalendarsCodes = Query.Execute().Unload().UnloadColumn("CalendarCode1");
	If CalendarsCodes.Count() = 0 Then
		Return;
	EndIf;

	BusinessCalendarsData = Catalogs.BusinessCalendars.DefaultBusinessCalendarsData(CalendarsCodes);
	NonWorkDaysPeriods = Catalogs.BusinessCalendars.DefaultNonWorkDaysPeriods();
	FillBusinessCalendarsDataOnUpdate(BusinessCalendarsData, NonWorkDaysPeriods);

EndProcedure

// Parameters:
//  See NearestWorkDates
// 
// Returns:
//  
//   
//   
//
Function SelectionOfNearestBusinessDates(BusinessCalendar, InitialDates, ReceivingParameters)
	
	QueryText = StartDatesQueryText(InitialDates);

	If IsBlankString(QueryText) Then
		Return Undefined;
	EndIf;

	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager;
	Query.Execute();
	
	QueryText = 
		"SELECT
		|	InitialDates.Date,
		|	MIN(CalendarDates.Date) AS NearestDate
		|FROM
		|	TTInitialDates AS InitialDates
		|		LEFT JOIN InformationRegister.BusinessCalendarData AS CalendarDates
		|		ON CalendarDates.Date >= InitialDates.Date
		|		AND CalendarDates.BusinessCalendar = &BusinessCalendar
		|		AND CalendarDates.DayKind IN (VALUE(Enum.BusinessCalendarDaysKinds.Work),
		|			VALUE(Enum.BusinessCalendarDaysKinds.Preholiday))
		|		AND CalendarDates.Date NOT IN (&NonWorkDates)
		|GROUP BY
		|	InitialDates.Date";
	
	If ReceivingParameters.GetPrevious Then
		QueryText = StrReplace(QueryText, "MIN(CalendarDates.Date)", "MAX(CalendarDates.Date)");
		QueryText = StrReplace(QueryText, "CalendarDates.Date >= InitialDates.Date",
			"CalendarDates.Date <= InitialDates.Date");
	EndIf;
	Query.Text = QueryText;
	Query.SetParameter("BusinessCalendar", BusinessCalendar);
	
	NonWorkDates = New Array;
	If ReceivingParameters.ConsiderNonWorkPeriods Then
		NonWorkDates = NonWorkDatesByNonWorkPeriod(ReceivingParameters.NonWorkPeriods, BusinessCalendar);
	EndIf;
	Query.SetParameter("NonWorkDates", NonWorkDates);
	
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

// Parameters:
//  InitialDates - Array of Date
// 
// Returns:
//  String
//
Function StartDatesQueryText(InitialDates)
	
	QueriesTexts = New Array;
	For Each InitialDate In InitialDates Do
		If Not ValueIsFilled(InitialDate) Then
			Continue;
		EndIf;
		QueryText = 
			"SELECT
			|	&InitialDate AS Date
			|INTO TTInitialDates";
		QueryText = StrReplace(
			QueryText, "&InitialDate", StrTemplate("DATETIME(%1)", Format(InitialDate, "DF=yyyy,MM,dd"))); // 
		If QueriesTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "INTO TTInitialDates", "");
		EndIf;
		QueriesTexts.Add(QueryText);
	EndDo;

	QueryText = StrConcat(QueriesTexts, Chars.LF + "UNION ALL" + Chars.LF);
	
	Return QueryText;
	
EndFunction

// 
// 
// 
// 
// Parameters:
//  InitialDate - Date
//  DefaultCalendarData - See Catalogs.BusinessCalendars.NewBusinessCalendarsData
//  GetPreviousOne - Boolean - :
//	  
//	 
// 
// Returns:
//  
//
Function NearestBusinessDateFromDefaultCalendar(InitialDate, DefaultCalendarData = Undefined,
	GetPreviousOne = False)
	
	If DefaultCalendarData = Undefined Then
		DefaultCalendarData = Catalogs.BusinessCalendars.NewBusinessCalendarsData();
	EndIf;
	
	Year = Year(InitialDate);
	If DefaultCalendarData.Find(Year, "Year") = Undefined Then
		SupplementDefaultCalendarData(DefaultCalendarData, Year, GetPreviousOne);
	EndIf;
	
	TableRow = DefaultCalendarData.Find(InitialDate, "Date");
	If TableRow = Undefined Then
		Return Undefined;
	EndIf;
	If TableRow.DayKind = Enums.BusinessCalendarDaysKinds.Work
		Or TableRow.DayKind = Enums.BusinessCalendarDaysKinds.Preholiday Then
		Return TableRow.Date;
	EndIf;
	
	IndexOf = DefaultCalendarData.IndexOf(TableRow);
	ValueToAdd = ?(GetPreviousOne, -1, 1);
	While True Do
		IndexOf = IndexOf + 1;
		If IndexOf >= DefaultCalendarData.Count() Then
			If IndexOf > 10000 Then
				Break;
			EndIf;
			Year = Year + ValueToAdd;
			SupplementDefaultCalendarData(DefaultCalendarData, Year, GetPreviousOne);
		EndIf;
		TableRow = DefaultCalendarData.Get(IndexOf);
		If TableRow.DayKind = Enums.BusinessCalendarDaysKinds.Work
			Or TableRow.DayKind = Enums.BusinessCalendarDaysKinds.Preholiday Then
			Return TableRow.Date;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Parameters:
//  DefaultCalendarData - See Catalogs.BusinessCalendars.NewBusinessCalendarsData
//  Year - Number
//  SortInDescendingOrder - Boolean
//
Procedure SupplementDefaultCalendarData(DefaultCalendarData, Year, SortInDescendingOrder)

	CommonClientServer.SupplementTable(
		Catalogs.BusinessCalendars.BusinessCalendarDefaultFillingResult("RF", Year),
		DefaultCalendarData);
		
	If SortInDescendingOrder Then
		DefaultCalendarData.Sort("Date Desc");
	Else
		DefaultCalendarData.Sort("Date Asc");
	EndIf;
	
EndProcedure

#EndRegion
