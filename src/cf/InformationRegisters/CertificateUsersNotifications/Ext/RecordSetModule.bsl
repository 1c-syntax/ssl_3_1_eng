///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
#Region EventHandlers

Procedure OnWrite(Cancel, Replacing)

	If DataExchange.Load Then
		Return;
	EndIf;

	If Not AdditionalProperties.Property("ReminderID") Then
		Return;
	EndIf;

	If Not Common.SubsystemExists("StandardSubsystems.UserReminders") Then
		Return;
	EndIf;
	
	ModuleUserReminder = Common.CommonModule("UserReminders");
	If Not ModuleUserReminder.UsedUserReminders() Then
		Return;
	EndIf;
	
	ReminderID = AdditionalProperties.ReminderID;

	For Each Record In ThisObject Do
		
		Reminders = ModuleUserReminder.FindReminders(Record.Certificate, ReminderID);

		For Each Reminder In Reminders Do
			ModuleUserReminder.DeleteReminder(Reminder);
		EndDo;

		If Not Record.IsNotified Then
			If ReminderID = "AutomaticCertificateRenewalReminder" Then

				ReminderText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Time to reissue certificate ""%1""';"), Record.Certificate);
				ModuleUserReminder.SetReminder(
					ReminderText, "ValidBefore", 30 * 24 * 60 * 60, Record.Certificate, ReminderID);

			Else

				ReminderText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = '""%1"": Certificate is received';"), Record.Certificate);
				ModuleUserReminder.SetReminder(
					ReminderText, "DateCertificateReceived", 0, Record.Certificate, ReminderID);

			EndIf;
		EndIf;

	EndDo;

EndProcedure

#EndRegion
#Else
	Raise NStr("en = 'Invalid object call on the client.';");
#EndIf