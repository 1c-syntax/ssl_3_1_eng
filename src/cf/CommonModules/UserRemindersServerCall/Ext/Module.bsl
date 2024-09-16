///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Creates a new reminder for the time calculated relative to the time in the item.
Function AttachReminderTillSubjectTime(Text, Interval, SubjectOf, AttributeName, RepeatAnnually = False) Export
	
	Return UserRemindersInternal.AttachReminderTillSubjectTime(
		Text, Interval, SubjectOf, AttributeName, RepeatAnnually);
	
EndFunction

Function AttachReminder(Text, EventTime, IntervalTillEvent = 0, SubjectOf = Undefined, Id = Undefined) Export
	
	Return UserRemindersInternal.AttachArbitraryReminder(
		Text, EventTime, IntervalTillEvent, SubjectOf, Id);
	
EndFunction

Function GetRecordKeyAndDisableReminder(ReminderParameters) Export
	RecordKey = InformationRegisters.UserReminders.CreateRecordKey(ReminderParameters);
	UserRemindersInternal.DisableReminder(ReminderParameters, True, True);
	Return RecordKey;
EndFunction

#EndRegion
