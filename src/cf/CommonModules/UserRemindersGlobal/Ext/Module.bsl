///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Opens the user's current reminders form.
//
Procedure CheckCurrentReminders() Export

	If Not CommonClient.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	// 
	TimeOfClosest = Undefined;
	NextCheckInterval = 60;
	
	If UserRemindersClient.GetCurrentNotifications(TimeOfClosest).Count() > 0 Then
		UserRemindersClient.OpenNotificationForm();
	ElsIf ValueIsFilled(TimeOfClosest) Then
		NextCheckInterval = Max(Min(TimeOfClosest - CommonClient.SessionDate(), NextCheckInterval), 1);
	EndIf;
	
	AttachIdleHandler("CheckCurrentReminders", NextCheckInterval, True);
	
EndProcedure

#EndRegion
