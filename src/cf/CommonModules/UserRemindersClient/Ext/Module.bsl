///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Starts a periodic check of the user's current reminders.
Procedure Enable() Export
	CheckCurrentReminders();
EndProcedure

// Disables periodic checking of the user's current reminders.
Procedure Disable() Export
	DetachIdleHandler("CheckCurrentReminders");
EndProcedure

// Creates a new reminder for the specified time.
//
// Parameters:
//  Text - String -  the reminder text;
//  Time - Date -  date and time of the reminder;
//  SubjectOf - AnyRef -  the subject of the reminder;
//  Id - String -  specifies the subject of the reminder, for example, "Birthday".
//
Procedure RemindInSpecifiedTime(Text, Time, SubjectOf = Undefined, Id = Undefined) Export
	
	Reminder = UserRemindersServerCall.AttachReminder(
		Text, Time, , SubjectOf, Id);
		
	ShowUserNotification(NStr("en = 'Reminder saved';"),,
		Reminder.LongDesc, PictureLib.Reminder,
		UserNotificationStatus.Information, Id);
		
	UpdateRecordInNotificationsCache(Reminder);
	ResetCurrentNotificationsCheckTimer();
	
EndProcedure

// Creates a new reminder for the time calculated relative to the time in the item.
//
// Parameters:
//  Text - String -  the reminder text;
//  Interval - Number -  time in seconds to be reminded of the date in the item's details;
//  SubjectOf - AnyRef -  the subject of the reminder;
//  AttributeName - String -  name of the item details for which the reminder period is set.
//
Procedure RemindTillSubjectTime(Text, Interval, SubjectOf, AttributeName) Export
	
	Reminder = UserRemindersServerCall.AttachReminderTillSubjectTime(
		Text, Interval, SubjectOf, AttributeName, False);
		
	UpdateRecordInNotificationsCache(Reminder);
	ResetCurrentNotificationsCheckTimer();
	
EndProcedure

// Creates a reminder with a custom time or schedule.
//
// Parameters:
//  Text - String -  the reminder text;
//  EventTime - Date -  date and time of the event to be reminded of;
//               - JobSchedule - 
//               - String - 
//  IntervalTillEvent - Number -  time in seconds to be reminded of the event time;
//  SubjectOf - AnyRef -  the subject of the reminder;
//  Id - String -  specifies the subject of the reminder, for example, "Birthday".
//
Procedure Remind(Text, EventTime, IntervalTillEvent = 0, SubjectOf = Undefined, Id = Undefined) Export
	
	Reminder = UserRemindersServerCall.AttachReminder(
		Text, EventTime, IntervalTillEvent, SubjectOf, Id);
		
	UpdateRecordInNotificationsCache(Reminder);
	ResetCurrentNotificationsCheckTimer();
	
EndProcedure

// Creates an annual reminder for the item date.
//
// Parameters:
//  Text - String -  the reminder text;
//  Interval - Number -  time in seconds to be reminded of the date in the item's details;
//  SubjectOf - AnyRef -  the subject of the reminder;
//  AttributeName - String -  name of the item details for which the reminder period is set.
//
Procedure RemindOfAnnualSubjectEvent(Text, Interval, SubjectOf, AttributeName) Export
	
	Reminder = UserRemindersServerCall.AttachReminderTillSubjectTime(
		Text, Interval, SubjectOf, AttributeName, True);
		
	UpdateRecordInNotificationsCache(Reminder);
	ResetCurrentNotificationsCheckTimer();
	
EndProcedure

// 
//
// Parameters:
//   Item - FormField - 
//   Form - ClientApplicationForm - 
//	
Procedure OnChangeReminderSettings(Item, Form) Export
	
	FieldNameReminderTimeInterval = UserRemindersClientServer.FieldNameReminderTimeInterval();
	
	If Item.Name = FieldNameReminderTimeInterval Then
		SettingsOfReminder = ReminderSettingsInForm(Form);
		If Form[Item.Name] = UserRemindersClientServer.EnumPresentationDoNotRemind() Then
			ToRemind = False;
		Else
			ReminderInterval = GetTimeIntervalFromString(Form[Item.Name]);
			If Form[Item.Name] <> UserRemindersClientServer.EnumPresentationOnOccurrence() Then
				Form[Item.Name] = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = '%1 before';"), TimePresentation(ReminderInterval, , ReminderInterval <> 0));
			EndIf;
			SettingsOfReminder.ReminderInterval = ReminderInterval;
			ToRemind = True;
		EndIf;
		Form[UserRemindersClientServer.FieldNameRemindAboutEvent()] = ToRemind;
	EndIf;
	
EndProcedure

// 
//
// Parameters:
//   Form - ClientApplicationForm - 
//   EventName  - String
//   Parameter    - See UserRemindersClientServer.ReminderDetails
//   Source    - ClientApplicationForm
//               - Arbitrary -  event source.
//	
Procedure NotificationProcessing(Form, EventName, Parameter, Source) Export
	
	If EventName = "Write_UserReminders" Then
		SettingsOfReminder = ReminderSettingsInForm(Form);

		If ValueIsFilled(Parameter) 
			And Parameter.Source = SettingsOfReminder.SubjectOf
			And Parameter.SourceAttributeName = SettingsOfReminder.NameOfAttributeWithEventDate Then
				
			FieldNameReminderTimeInterval = UserRemindersClientServer.FieldNameReminderTimeInterval();
			ReminderInterval = Parameter.ReminderInterval;
			If ReminderInterval > SettingsOfReminder.ReminderInterval Then
				SettingsOfReminder.ReminderInterval = ReminderInterval;
				Form[FieldNameReminderTimeInterval] = UserRemindersClientServer.ReminderTimePresentation(Parameter);
				Form[UserRemindersClientServer.FieldNameRemindAboutEvent()] = True;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// 
Procedure OpenSettings() Export
	OpenForm("InformationRegister.UserReminders.Form.Settings");
EndProcedure

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	If Not CommonClient.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ReminderSettings = StandardSubsystemsClient.ClientParametersOnStart().ReminderSettings;
	If ReminderSettings.UseReminders Then
		SettingsOnClient().CurrentRemindersList = ReminderSettings.CurrentRemindersList;
		AttachIdleHandler("CheckCurrentReminders", 60, True); // 
	EndIf;
	
EndProcedure

// See StandardSubsystemsClient.OnReceiptServerNotification.
Procedure OnReceiptServerNotification(NameOfAlert, Result) Export
	
	If NameOfAlert <> UserRemindersClientServer.ServerNotificationName() Then
		Return;
	EndIf;
	
	Result = Result; // See UserRemindersInternal.NewModifiedReminders
	
	For Each Reminder In Result.Trash Do
		DeleteRecordFromNotificationsCache(Reminder);
	EndDo;
	
	For Each Reminder In Result.Added1 Do
		UpdateRecordInNotificationsCache(Reminder);
	EndDo;
	
	ResetCurrentNotificationsCheckTimer();
	
EndProcedure

#EndRegion

#Region Private

// Returns:
//  Structure:
//   * CurrentRemindersList - See UserRemindersInternal.CurrentUserRemindersList
//
Function SettingsOnClient()
	
	ParameterName = "StandardSubsystems.UserReminders";
	Settings = ApplicationParameters[ParameterName];
	
	If Settings = Undefined Then
		Settings = New Structure;
		Settings.Insert("CurrentRemindersList", New Array);
		ApplicationParameters[ParameterName] = Settings;
	EndIf;
	
	Return Settings;
	
EndFunction

Procedure ResetCurrentNotificationsCheckTimer() Export
	DetachIdleHandler("CheckCurrentReminders");
	AttachIdleHandler("CheckCurrentReminders", 0.1, True);
EndProcedure

Procedure OpenNotificationForm() Export
	
	// 
	// 
	ParameterName = "StandardSubsystems.NotificationForm";
	If ApplicationParameters[ParameterName] = Undefined Then
		NotificationFormName = "InformationRegister.UserReminders.Form.NotificationForm";
		ApplicationParameters.Insert(ParameterName, GetForm(NotificationFormName));
	EndIf;
	NotificationForm = ApplicationParameters[ParameterName];
	NotificationForm.Open();

EndProcedure

// Returns cached notifications for the current user, excluding non-triggered notifications from the result.
//
// Parameters:
//  TimeOfClosest - Date -  this parameter returns the time of the nearest future reminder. If
//                           the nearest reminder is outside the cache selection, it is returned Undefined.
//
// Returns: 
//   See UserRemindersInternal.CurrentUserRemindersList
//
Function GetCurrentNotifications(TimeOfClosest = Undefined) Export
	
	NotificationsTable = SettingsOnClient().CurrentRemindersList;
	Result = New Array;
	
	TimeOfClosest = Undefined;
	
	For Each Notification In NotificationsTable Do
		If Notification.ReminderTime <= CommonClient.SessionDate() Then
			Result.Add(Notification);
		Else                                                           
			If TimeOfClosest = Undefined Then
				TimeOfClosest = Notification.ReminderTime;
			Else
				TimeOfClosest = Min(TimeOfClosest, Notification.ReminderTime);
			EndIf;
		EndIf;
	EndDo;		
	
	Return Result;
	
EndFunction

// 
Procedure UpdateRecordInNotificationsCache(NotificationParameters) Export
	NotificationsCache = SettingsOnClient().CurrentRemindersList;
	Record = FindRecordInNotificationsCache(NotificationsCache, NotificationParameters);
	If Record <> Undefined Then
		FillPropertyValues(Record, NotificationParameters);
	Else
		NotificationsCache.Add(NotificationParameters);
	EndIf;
EndProcedure

// 
Procedure DeleteRecordFromNotificationsCache(NotificationParameters) Export
	NotificationsCache = SettingsOnClient().CurrentRemindersList;
	Record = FindRecordInNotificationsCache(NotificationsCache, NotificationParameters);
	If Record <> Undefined Then
		NotificationsCache.Delete(NotificationsCache.Find(Record));
	EndIf;
EndProcedure

// 
//
// Parameters:
//  NotificationsCache - See UserRemindersInternal.CurrentUserRemindersList
//  NotificationParameters - Structure:
//   * Source - DefinedType.ReminderSubject
//   * EventTime - Date
//
Function FindRecordInNotificationsCache(NotificationsCache, NotificationParameters)
	For Each Record In NotificationsCache Do
		If Record.Source = NotificationParameters.Source
		   And Record.EventTime = NotificationParameters.EventTime Then
			Return Record;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction

// Gets a time interval from a string and returns its text representation.
//
// Parameters:
//  TimeAsString - String -  text description of time, where numbers are written as digits
//							and units are written as a string.
//
// Returns:
//  String - 
//
Function FormatTime(TimeAsString) Export
	Return TimePresentation(GetTimeIntervalFromString(TimeAsString));
EndFunction

// See UserRemindersClientServer.TimePresentation
Function TimePresentation(Val Time, FullPresentation = True, OutputSeconds = True) Export
	
	Return UserRemindersClientServer.TimePresentation(Time, FullPresentation, OutputSeconds);
	
EndFunction

// See UserRemindersClientServer.TimeIntervalFromString
Function GetTimeIntervalFromString(Val StringWithTime) Export
	
	Return UserRemindersClientServer.TimeIntervalFromString(StringWithTime);
	
EndFunction

Function ReminderSettingsInForm(Form)
	
	Return UserRemindersClientServer.ReminderSettingsInForm(Form);
	
EndFunction

#EndRegion
