///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Starts interactive deletion of marked objects.
// 
// Parameters:
//   ObjectsToDelete - Array of AnyRef -  list of objects to delete.
//   DeletionParameters - See InteractiveDeletionParameters
// 		
//   Owner - ClientApplicationForm
//            - Undefined - 
// 							   
// 							   
//   OnCloseNotifyDescription - NotifyDescription - 
//								
//								:
//                              
//                              
//                              
//                              
//
Procedure StartMarkedObjectsDeletion(ObjectsToDelete, DeletionParameters = Undefined, Owner = Undefined,
	OnCloseNotifyDescription = Undefined) Export

	FormParameters = New Structure;
	FormParameters.Insert("ObjectsToDelete", ObjectsToDelete);
	FormParameters.Insert("DeletionMode", "Standard");
	If DeletionParameters <> Undefined Then
		FillPropertyValues(FormParameters, DeletionParameters);
	EndIf;
	
	ClosingNotification1 = New NotifyDescription("StartMarkedObjectsDeletionCompletion"
		, ThisObject, New Structure("ClosingNotification1", OnCloseNotifyDescription));
		
	OpenForm("DataProcessor.MarkedObjectsDeletion.Form", FormParameters, Owner, , , , ClosingNotification1,
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// Settings for interactive deletion.
// 
// Returns:
//   Structure:
//   * Mode - String -  :
//		 
//					  
//		
//		
//					   
//					  
//
Function InteractiveDeletionParameters() Export
	Parameters = New Structure;
	Parameters.Insert("Mode", "Standard");
	Return Parameters;
EndFunction

#Region FormsPublic

// Opens the Delete marked workspace.
//  
// Parameters:
//   Form - ClientApplicationForm
//   FormTable - FormTable
//                - FormDataStructure
//                - Undefined -  form table associated with a dynamic list
//
Procedure GoToMarkedForDeletionItems(Form, FormTable = Undefined) Export
	
	If FormTable <> Undefined Then
		CommonClientServer.CheckParameter("GoToMarkedForDeletionItems", "FormTable", FormTable, New TypeDescription("FormTable"));
		
		MetadataTypes = Form.MarkedObjectsDeletionParameters[FormTable.Name].MetadataTypes;
		OpeningParameters = New Structure();
		OpeningParameters.Insert("MetadataFilter", MetadataTypes);
	EndIf;
	
	OpenForm("DataProcessor.MarkedObjectsDeletion.Form.DefaultForm", OpeningParameters, Form);
EndProcedure

// Changes the visibility of those marked for deletion and saves the user's settings.
// 
// Parameters:
//   Form - ClientApplicationForm
//   FormTable - FormTable -  a form table associated with a dynamic list.
//   FormButton - FormButton -  the form button associated with the Show marked for deletion command.
//
Procedure ShowObjectsMarkedForDeletion(Form, FormTable, FormButton) Export
	CommonClientServer.CheckParameter("ShowObjectsMarkedForDeletion", "FormTable", FormTable, New TypeDescription("FormTable"));
	NewFilterValue = ChangeObjectsMarkedForDeletionFilter(Form, FormTable);
	FormButton.Check = Not NewFilterValue;
EndProcedure

// Opens a form for changing the schedule of a scheduled task.
// If the schedule is set, the scheduled task with the set schedule will be enabled. 
// 
// Not supported on the mobile platform.
// 
// Parameters:
//   ChangeNotification1 - NotifyDescription -  handler for changing the schedule of a scheduled task.
//
Procedure StartChangeJobSchedule(ChangeNotification1 = Undefined) Export
	ScheduledJobInfoDeletionOfMarkedObjects = MarkedObjectsDeletionInternalServerCall.ModeDeleteOnSchedule();
	Handler = New NotifyDescription("ScheduledJobsAfterChangeSchedule", ThisObject,
			New Structure("ChangeNotification1, OldSchedule", ChangeNotification1, ScheduledJobInfoDeletionOfMarkedObjects.Schedule));
	
	If ScheduledJobInfoDeletionOfMarkedObjects.DataSeparationEnabled Then
		Result = New Structure("Use,Schedule");
		FillPropertyValues(Result, ScheduledJobInfoDeletionOfMarkedObjects);
		ExecuteNotifyProcessing(Handler, ScheduledJobInfoDeletionOfMarkedObjects.Schedule);
	Else		
		ScheduledJobDetails = ScheduledJobInfoDeletionOfMarkedObjects.Schedule;
		Schedule = New JobSchedule;
		FillPropertyValues(Schedule, ScheduledJobDetails);
		Dialog = New ScheduledJobDialog(Schedule);
		Dialog.Show(Handler);
	EndIf;
EndProcedure

// Handler for the Change event for the checkbox that switches the automatic object deletion mode.
// 
// Parameters:
//   AutomaticallyDeleteMarkedObjects  - Boolean -  the new value of the checkbox that you want to process.
//   ChangeNotification1 - NotifyDescription -  if the value of auto-delete Placemarkedobjects = True, the procedure
//   											  will be called after the scheduled task schedule is selected.
//   											  If the value of debugautomatically delete marked Objects = False, the procedure will 
//   											  be called immediately. 
// 
// Example:
//	If The General Purpose Is A Client.Subsystems Exist ("Standard Subsystems.Deleting marked objects") Then
//		МодульУдалениеПомеченныхОбъектовклиент = Observationnelle.General Module ("Deleting Marked Objectsclient");
//		Module for removing marked client objects.When You Change The Placemark To Delete (Auto-Delete Marked Objects);
//	Conicelli;
//
Procedure OnChangeCheckBoxDeleteOnSchedule(AutomaticallyDeleteMarkedObjects, ChangeNotification1 = Undefined) Export
	CurrentScheduledJobParameters = MarkedObjectsDeletionInternalServerCall.ModeDeleteOnSchedule();
	Changes = New Structure("Schedule", CurrentScheduledJobParameters.Schedule);
	Changes.Insert("Use", AutomaticallyDeleteMarkedObjects);
	MarkedObjectsDeletionInternalServerCall.SetDeleteOnScheduleMode(Changes);

	If ChangeNotification1 <> Undefined Then
		ExecuteNotifyProcessing(ChangeNotification1, Changes);
	EndIf;
	
	// 
	Notify("ModeChangedAutomaticallyDeleteMarkedObjects");
EndProcedure

#EndRegion

// Event handler for the message Processing event for the form where you want to display the scheduled deletion check box.
//
// Parameters:
//   EventName - String -  name of the event that was received by the event handler on the form.
//   AutomaticallyDeleteMarkedObjects - Boolean -  the prop that the value will be placed in.
// 
// Example:
//	If The General Purpose Is A Client.Subsystems Exist ("Standard Subsystems.Deleting marked objects") Then
//		МодульУдалениеПомеченныхОбъектовклиент = Observationnelle.General Module ("Deleting Marked Objects")");
//		Module for removing marked client objects.ОбработкаОповещенияИзмененияФлажкаудалятьпорасписанию(
//			Masonite, 
//			Auto-delete marked objects);
//	Conicelli;
//
Procedure DeleteOnScheduleCheckBoxChangeNotificationProcessing(Val EventName,
		AutomaticallyDeleteMarkedObjects) Export

	If EventName = "ModeChangedAutomaticallyDeleteMarkedObjects" Then
		AutomaticallyDeleteMarkedObjects = MarkedObjectsDeletionInternalServerCall.DeleteOnScheduleCheckBoxValue();
	EndIf;

EndProcedure

#EndRegion

#Region Internal

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef -  links to the selected objects that the command is running on.
//   CommandParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure RunAttachableCommandShowObjectsMarkedForDeletion(Val ReferencesArrray,
		CommandParameters) Export
	NewFilterValue = ChangeObjectsMarkedForDeletionFilter(CommandParameters.Form, CommandParameters.Source);
	MarkedObjectsDeletionInternalServerCall.SaveViewSettingForItemsMarkedForDeletion(CommandParameters.Form.FormName, CommandParameters.Source.Name, NewFilterValue);
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(CommandParameters.Form, CommandParameters.Source);
	EndIf;
EndProcedure

// Handler for the connected command.
//
// Parameters:
//   ReferencesArrray - Array of AnyRef -  links to the selected objects that the command is running on.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure RunAttachableCommandGoToObjectsMarkedForDeletion(ReferencesArrray, ExecutionParameters) Export
	GoToMarkedForDeletionItems(ExecutionParameters.Form, ExecutionParameters.Source);
EndProcedure

#EndRegion

#Region Private

Procedure StartMarkedObjectsDeletionCompletion(Val DeletionResult, AdditionalParameters) Export
	If DeletionResult = Undefined And Not AdditionalParameters.Property("ClosingResult") Then
		Return;
	EndIf;
		
	If DeletionResult = Undefined Then
		DeletionResult = AdditionalParameters.ClosingResult;
	EndIf;	
		
	If AdditionalParameters.ClosingNotification1 <> Undefined Then
		ExecuteNotifyProcessing(AdditionalParameters.ClosingNotification1, DeletionResult);
	EndIf;
EndProcedure

Procedure ScheduledJobsAfterChangeSchedule(Schedule, ExecutionParameters) Export
	If Schedule = Undefined Then
		Return;
	EndIf;	

	DeleteMarkedObjectsUsage = True;
	Changes = New Structure;
	Changes.Insert("Schedule", Schedule);
	Changes.Insert("Use", True);
	MarkedObjectsDeletionInternalServerCall.SetDeleteOnScheduleMode(Changes);
	
	Notify("ModeChangedAutomaticallyDeleteMarkedObjects");
	
	If ExecutionParameters.Property("ChangeNotification1") And ExecutionParameters.ChangeNotification1 <> Undefined Then
		ExecuteNotifyProcessing(ExecutionParameters.ChangeNotification1,
			New Structure("Use, Schedule", DeleteMarkedObjectsUsage, Schedule));
	EndIf;
EndProcedure

// Changes the visibility of those marked for deletion in the list
// 
// Parameters:
//   Form - ClientApplicationForm
//   FormTable - FormTable
// Returns:
//   Boolean - 
//
Function ChangeObjectsMarkedForDeletionFilter(Form, FormTable)
	
	Setting = Form.MarkedObjectsDeletionParameters[FormTable.Name];
	NewFilterValue = Not Setting.FilterValue;
	MarkedObjectsDeletionInternalClientServer.SetFilterByDeletionMark(Form[Setting.ListName], NewFilterValue);
	Setting.FilterValue = NewFilterValue;
	Setting.CheckMarkValue = Not NewFilterValue;
	MarkedObjectsDeletionInternalServerCall.SaveViewSettingForItemsMarkedForDeletion(Form.FormName, FormTable.Name, NewFilterValue);
	Return NewFilterValue;
	
EndFunction

#EndRegion

