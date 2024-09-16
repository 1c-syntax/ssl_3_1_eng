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
// 
//
//  Parameters: 
//   EventName          - String -  event name for the log;
//   LevelPresentation - String -  description of the event level, which will be used to determine the event level when recording on
//                                  the server;
//                                  For Example: "Error", "Warning".
//                                  Match the names of the log Level enumeration elements.
//   Comment         - String -  comment for a log event;
//   EventDate         - Date   -  the exact date when the event described in the message occurred. Will be added to the beginning
//                                  of the comment;
//   WriteEvents     - Boolean -  write all previously accumulated messages to the log (accessing the
//                                  server).
//
// Example:
//  Journalrecipient.Add a message to logregistration (event Logregistration (), "Warning",
//     NSTR ("ru = 'Unable to connect to the Internet to check for updates.'"));
//
Procedure AddMessageForEventLog(Val EventName, Val LevelPresentation = "Information", 
	Val Comment = "", Val EventDate = "", Val WriteEvents = False) Export
	
	ProcedureName = "EventLogClient.AddMessageForEventLog";
	CommonClientServer.CheckParameter(ProcedureName, "EventName", EventName, Type("String"));
	CommonClientServer.CheckParameter(ProcedureName, "LevelPresentation", LevelPresentation, Type("String"));
	CommonClientServer.CheckParameter(ProcedureName, "Comment", Comment, Type("String"));
	If EventDate <> "" Then
		CommonClientServer.CheckParameter(ProcedureName, "EventDate", EventDate, Type("Date"));
	EndIf;
	
	ParameterName = "StandardSubsystems.MessagesForEventLog";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New ValueList);
	EndIf;
	
	If TypeOf(EventDate) = Type("Date") Then
		EventDate = Format(EventDate, "DLF=DT");
	EndIf;
	
	MessageStructure = New Structure;
	MessageStructure.Insert("EventDate", EventDate);
	MessageStructure.Insert("EventName", EventName);
	MessageStructure.Insert("LevelPresentation", LevelPresentation);
	MessageStructure.Insert("Comment",
		CommonClientServer.ReplaceProhibitedXMLChars(Comment, " "));
	
	Messages = ApplicationParameters["StandardSubsystems.MessagesForEventLog"]; // ValueList
	Messages.Add(MessageStructure);
	
	If WriteEvents Then
		WriteEventsToEventLog();
	EndIf;
	
EndProcedure

// Opens the registration log form with the selection set.
//
// Parameters:
//  Filter - Structure:
//     * User              - String
//                                 - ValueList - 
//                                                    
//     * EventLogEvent - String
//                                 - Array - 
//     * StartDate                - Date           -  start of the interval of displayed events.
//     * EndDate             - Date           -  end of the interval of displayed events.
//     * Data                    - Arbitrary   -  any type of data.
//     * Session                     - ValueList -  list of selected sessions.
//     * Level                   - String
//                                 - Array - 
//                                            
//     * ApplicationName             - Array         -  an array of application identifiers.
//  Owner - ClientApplicationForm -  the form that opens the registration log.
//
Procedure OpenEventLog(Val Filter = Undefined, Owner = Undefined) Export
	
	OpenForm("DataProcessor.EventLog.Form", Filter, Owner);
	
EndProcedure

// 
// 
//
Procedure WriteEventsToEventLog() Export
	
	ParameterName = "StandardSubsystems.MessagesForEventLog";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New ValueList);
	EndIf;
	
	Messages = ApplicationParameters["StandardSubsystems.MessagesForEventLog"]; // ValueList
	If ValueIsFilled(Messages) Then
		EventLogServerCall.WriteEventsToEventLog(Messages);
		ApplicationParameters.Insert(ParameterName, Messages);
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// Opens a form for viewing additional event data.
//
// Parameters:
//  CurrentData - ValueTableRow -  log line.
//
Procedure OpenDataForViewing(CurrentData) Export
	
	If CurrentData = Undefined Or CurrentData.Data = Undefined Then
		ShowMessageBox(, NStr("en = 'The event log record is not linked to data (see the Data column)';"));
		Return;
	EndIf;
	
	Try
		ShowValue(, CurrentData.Data);
	Except
		WarningText = NStr("en = 'The event log record is linked to data that cannot be displayed.
									|%1';");
		If CurrentData.Event = "_$Data$_.Delete" Then 
			// 
			WarningText =
					StringFunctionsClientServer.SubstituteParametersToString(WarningText, NStr("en = 'The data was deleted from the infobase';"));
		Else
			WarningText =
				StringFunctionsClientServer.SubstituteParametersToString(WarningText, NStr("en = 'Perhaps the data was deleted from the infobase';"));
		EndIf;
		ShowMessageBox(, WarningText);
	EndTry;
	
EndProcedure

// Opens the log processing event view form
// to display detailed data for the selected event.
//
// Parameters:
//  Data - FormDataCollectionItem of See DataProcessor.EventLog.Form.EventLog.Log
//
Procedure ViewCurrentEventInNewWindow(Data) Export
	
	If Data = Undefined Then
		Return;
	EndIf;
	
	FormOpenParameters = EventLogEventToStructure(Data);
	OpenForm("DataProcessor.EventLog.Form.Event", FormOpenParameters,, Data.EventKey);
	
EndProcedure

// Requests a period limit from the user 
// and includes it in the log selection.
//
// Parameters:
//  DateInterval - StandardPeriod -  selection date interval.
//  EventLogFilter - Structure
//  HandlerNotifications - NotifyDescription
//
Procedure SetPeriodForViewing(DateInterval, EventLogFilter, HandlerNotifications = Undefined) Export
	
	// 
	StartDate    = Undefined;
	EndDate = Undefined;
	EventLogFilter.Property("StartDate", StartDate);
	EventLogFilter.Property("EndDate", EndDate);
	StartDate    = ?(TypeOf(StartDate)    = Type("Date"), StartDate, '00010101000000');
	EndDate = ?(TypeOf(EndDate) = Type("Date"), EndDate, '00010101000000');
	
	If DateInterval.StartDate <> StartDate Then
		DateInterval.StartDate = StartDate;
	EndIf;
	
	If DateInterval.EndDate <> EndDate Then
		DateInterval.EndDate = EndDate;
	EndIf;
	
	// 
	Dialog = New StandardPeriodEditDialog;
	Dialog.Period = DateInterval;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("EventLogFilter", EventLogFilter);
	AdditionalParameters.Insert("DateInterval", DateInterval);
	AdditionalParameters.Insert("HandlerNotifications", HandlerNotifications);
	
	Notification = New NotifyDescription("SetPeriodForViewingCompletion", ThisObject, AdditionalParameters);
	Dialog.Show(Notification);
	
EndProcedure

// Processes the selection of an individual event in the event table.
//
// Parameters:
//  Parameters - Structure:
//     * CurrentData - ValueTableRow -  log line.
//     * Field - FormField -  field of the value table.
//     * DateInterval - StandardPeriod
//     * EventLogFilter - Filter -  selection of the registration log.
//     * NotificationHandlerForSettingDateInterval - NotifyDescription
//
Procedure EventsChoice(Parameters) Export
	
	If Parameters.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Parameters.Field.Name = "Data" Or Parameters.Field.Name = "DataPresentation" Then
		If TypeOf(Parameters.CurrentData.Data) <> Type("Undefined")
		   And TypeOf(Parameters.CurrentData.Data) <> Type("String")
		   And TypeOf(Parameters.CurrentData.Data) <> Type("Number")
		   And TypeOf(Parameters.CurrentData.Data) <> Type("Date")
		   And TypeOf(Parameters.CurrentData.Data) <> Type("Boolean")
		   And ValueIsFilled(Parameters.CurrentData.Data) Then
			
			OpenDataForViewing(Parameters.CurrentData);
			Return;
		EndIf;
	EndIf;
	
	If Parameters.Field.Name = "Date" Then
		SetPeriodForViewing(Parameters.DateInterval,
			Parameters.EventLogFilter,
			Parameters.NotificationHandlerForSettingDateInterval);
		Return;
	EndIf;
	
	ViewCurrentEventInNewWindow(Parameters.CurrentData);
	
EndProcedure

// Fills in the selection according to the value in the current event column.
//
// Parameters:
//  CurrentData - ValueTableRow
//  CurrentItemName - String - 
//  EventLogFilter - Structure
//  ExcludeColumns - Array
//
// Returns:
//  Boolean - 
//
Function SetFilterByValueInCurrentColumn(CurrentData, CurrentItemName,
			EventLogFilter, ExcludeColumns) Export
	
	If CurrentData = Undefined Then
		Return False;
	EndIf;
	
	If ExcludeColumns.Find(CurrentItemName) <> Undefined Then
		Return False;
	EndIf;
	
	FilterColumnName        = CurrentItemName;
	PresentationColumnName = CurrentItemName;
	
	If CurrentItemName = "MetadataPresentation" Then
		FilterColumnName = "Metadata";
		
	ElsIf CurrentItemName = "Metadata" Then
		PresentationColumnName = "MetadataPresentation";
		
	ElsIf CurrentItemName = "SessionDataSeparationPresentation"
	      Or CurrentItemName = "DataArea" Then
		
		FilterColumnName = "SessionDataSeparation";
		
	ElsIf CurrentItemName = "UserName" Then
		FilterColumnName = "User";
		
	ElsIf CurrentItemName = "ApplicationPresentation" Then
		FilterColumnName = "ApplicationName";
		
	ElsIf CurrentItemName = "EventPresentation" Then
		FilterColumnName = "Event";
	EndIf;
	
	FilterValue = CurrentData[FilterColumnName];
	Presentation  = CurrentData[PresentationColumnName];
	
	// 
	If TypeOf(FilterValue) = Type("String") And IsBlankString(FilterValue) Then
		// 
		If PresentationColumnName <> "UserName" Then 
			Return False;
		EndIf;
	EndIf;
	
	EventLogFilter.Delete(FilterColumnName);
	EventLogFilter.Delete(PresentationColumnName);
	
	If FilterColumnName = "Data"
	   And ValueIsFilled(CurrentData.DataAsStr) Then
		
		FilterValue = New ValueList;
		FilterValue.Add(CurrentData.DataAsStr, CurrentData.Data);
	EndIf;
	
	If FilterColumnName = "Metadata"
	 Or FilterColumnName = "Data"
	 Or FilterColumnName = "Comment"
	 Or FilterColumnName = "Transaction"
	 Or FilterColumnName = "DataPresentation" Then
		
		EventLogFilter.Insert(FilterColumnName, FilterValue);
	Else
		
		If FilterColumnName = "SessionDataSeparation" Then
			FilterList = FilterValue.Copy();
		ElsIf FilterColumnName = "User"
		        And FilterValue = String(CommonClientServer.BlankUUID()) Then
			Return False;
		Else
			FilterList = New ValueList;
			FilterList.Add(FilterValue, Presentation);
		EndIf;
		
		EventLogFilter.Insert(FilterColumnName, FilterList);
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region Private

// For internal use only.
// 
// Parameters:
//  Data - FormDataCollectionItem: See DataProcessor.EventLog.Form.EventLog.Log
// 
// Returns:
//  Structure
//
Function EventLogEventToStructure(Data)
	
	If TypeOf(Data) = Type("Structure") Then
		Return Data;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Date",                    Data.Date);
	FormParameters.Insert("UserName",         Data.UserName);
	FormParameters.Insert("User",            Data.User);
	FormParameters.Insert("ApplicationPresentation", Data.ApplicationPresentation);
	FormParameters.Insert("Computer",               Data.Computer);
	FormParameters.Insert("Event",                 Data.Event);
	FormParameters.Insert("EventPresentation",    Data.EventPresentation);
	FormParameters.Insert("Comment",             Data.Comment);
	FormParameters.Insert("MetadataPresentation", Data.MetadataPresentation);
	FormParameters.Insert("Data",                  Data.Data);
	FormParameters.Insert("DataPresentation",     Data.DataPresentation);
	FormParameters.Insert("Transaction",              Data.TransactionID);
	FormParameters.Insert("TransactionStatus",        Data.TransactionStatus);
	FormParameters.Insert("Session",                   Data.Session);
	FormParameters.Insert("ServerName",           Data.ServerName);
	FormParameters.Insert("PrimaryIPPort",          Data.Port);
	FormParameters.Insert("SyncPort",   Data.SyncPort);
	FormParameters.Insert("Level",                 Data.Level);
	FormParameters.Insert("EventKey",             Data.EventKey);
	
	If Data.Property("DataArea") Then
		FormParameters.Insert("DataArea", Data.DataArea);
	EndIf;
	If Data.Property("SessionDataSeparation") Then
		FormParameters.Insert("SessionDataSeparation", Data.SessionDataSeparation);
	EndIf;
	
	If ValueIsFilled(Data.DataAsStr) Then
		FormParameters.Insert("DataAsStr", Data.DataAsStr);
	EndIf;
	
	Return FormParameters;
EndFunction

// For internal use only.
// 
// Parameters:
//  Result - StandardPeriod
//            - Undefined
//  AdditionalParameters - Structure
//   
Procedure SetPeriodForViewingCompletion(Result, AdditionalParameters) Export
	
	EventLogFilter = AdditionalParameters.EventLogFilter;
	IntervalSet = False;
	
	If Result <> Undefined Then
		
		// 
		DateInterval = Result;
		If DateInterval.StartDate = '00010101000000' Then
			EventLogFilter.Delete("StartDate");
		Else
			EventLogFilter.Insert("StartDate", DateInterval.StartDate);
		EndIf;
		
		If DateInterval.EndDate = '00010101000000' Then
			EventLogFilter.Delete("EndDate");
		Else
			EventLogFilter.Insert("EndDate", DateInterval.EndDate);
		EndIf;
		IntervalSet = True;
		
	EndIf;
	
	If AdditionalParameters.HandlerNotifications <> Undefined Then
		ExecuteNotifyProcessing(AdditionalParameters.HandlerNotifications, IntervalSet);
	EndIf;
	
EndProcedure

#EndRegion
