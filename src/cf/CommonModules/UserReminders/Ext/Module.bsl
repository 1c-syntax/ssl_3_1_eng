///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Creates a reminder with a custom time or schedule.
//
// Parameters:
//  Text - String -  the reminder text;
//  EventTime - Date -  date and time of the event to remind you of.
//               - JobSchedule - 
//               - String - 
//  IntervalTillEvent - Number -  time in seconds to be reminded of the event time;
//  SubjectOf - AnyRef -  the subject of the reminder;
//  Id - String -  specifies the subject of the reminder, for example, "Birthday".
//
Procedure SetReminder(Text, EventTime, IntervalTillEvent = 0, SubjectOf = Undefined, Id = Undefined) Export
	UserRemindersInternal.AttachArbitraryReminder(
		Text, EventTime, IntervalTillEvent, SubjectOf, Id);
EndProcedure

// Returns a list of reminders for the current user.
//
// Parameters:
//  SubjectOf - AnyRef
//          - Array - 
//  Id - String -  specifies the subject of the reminder, for example, "Birthday".
//
// Returns:
//    Array - 
//
Function FindReminders(Val SubjectOf = Undefined, Id = Undefined) Export
	
	QueryText =
	"SELECT
	|	*
	|FROM
	|	InformationRegister.UserReminders AS UserReminders
	|WHERE
	|	UserReminders.User = &User
	|	AND &IsFilterBySubject
	|	AND &FilterByID";
	
	IsFilterBySubject = "TRUE";
	If ValueIsFilled(SubjectOf) Then
		IsFilterBySubject = "UserReminders.Source IN(&SubjectOf)";
	EndIf;
	
	FilterByID = "TRUE";
	If ValueIsFilled(Id) Then
		FilterByID = "UserReminders.Id = &Id";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&IsFilterBySubject", IsFilterBySubject);
	QueryText = StrReplace(QueryText, "&FilterByID", FilterByID);
	
	Query = New Query(QueryText);
	Query.SetParameter("User", Users.CurrentUser());
	Query.SetParameter("SubjectOf", SubjectOf);
	Query.SetParameter("Id", Id);
	
	RemindersTable = Query.Execute().Unload();
	RemindersTable.Sort("ReminderTime");
	
	Return Common.ValueTableToArray(RemindersTable);
	
EndFunction

// Deletes the user's reminder.
//
// Parameters:
//  Reminder - Structure -  the element collection returned by the function Noitenomuseu().
//
Procedure DeleteReminder(Reminder) Export
	UserRemindersInternal.DisableReminder(Reminder, False);
EndProcedure

// Checks changes to the details of items that have a user subscription,
// and changes the reminder period if necessary.
//
// Parameters:
//  Subjects - Array -  items for which you need to update the reminder dates.
// 
Procedure UpdateRemindersForSubjects(Subjects) Export
	
	UserRemindersInternal.UpdateRemindersForSubjects(Subjects);
	
EndProcedure

// 
// 
// Returns:
//  Boolean - 
//
Function UsedUserReminders() Export
	
	Return GetFunctionalOption("UseUserReminders") 
		And AccessRight("Update", Metadata.InformationRegisters.UserReminders);
	
EndFunction

// 
//
// Parameters:
//  Form - ClientApplicationForm - 
//  PlacementParameters - See PlacementParameters
//
Procedure OnCreateAtServer(Form, PlacementParameters) Export
	
	UserRemindersInternal.OnCreateAtServer(Form, PlacementParameters);
	
EndProcedure

// 
// 
// Returns:
//  Structure:
//   * Group - FormGroup - 
//   * NameOfAttributeWithEventDate - String - 
//   * ReminderInterval - Number - 
//   * ShouldAddFlag - Boolean -  
//                                
//                                
//                                
//
Function PlacementParameters() Export
	
	Return UserRemindersInternal.PlacementParameters();
	
EndFunction

// 
//
// Parameters:
//  Form - ClientApplicationForm - 
//  CurrentObject       - CatalogObject
//                      - DocumentObject
//                      - ChartOfCharacteristicTypesObject
//                      - ChartOfAccountsObject
//                      - ChartOfCalculationTypesObject
//                      - BusinessProcessObject
//                      - TaskObject
//                      - ExchangePlanObject -  the subject of the reminder.
//
Procedure OnReadAtServer(Form, CurrentObject) Export
	
	UserRemindersInternal.OnReadAtServer(Form, CurrentObject);
	
EndProcedure

// 
//
// Parameters:
//   Form - ClientApplicationForm - 
//   Cancel - Boolean -  indicates that the recording was rejected.
//   CurrentObject  - CatalogObject
//                  - DocumentObject
//                  - ChartOfCharacteristicTypesObject
//                  - ChartOfAccountsObject
//                  - ChartOfCalculationTypesObject
//                  - BusinessProcessObject
//                  - TaskObject
//                  - ExchangePlanObject -  the subject of the reminder.
//   WriteParameters - Structure
//   ReminderText - String - 
//                               
//  
Procedure OnWriteAtServer(Form, Cancel, CurrentObject, WriteParameters, ReminderText = "") Export
	
	UserRemindersInternal.OnWriteAtServer(Form, Cancel, CurrentObject, WriteParameters, ReminderText);
	
EndProcedure

#EndRegion
