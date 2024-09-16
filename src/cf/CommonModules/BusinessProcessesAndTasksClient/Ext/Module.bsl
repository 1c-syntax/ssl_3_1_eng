///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// 

// Marks the specified business processes as stopped.
//
// Parameters:
//  CommandParameter  - Array of DefinedType.BusinessProcess
//                   - DefinedType.BusinessProcess
//
Procedure Stop(Val CommandParameter) Export
	
	QueryText = "";
	TaskCount1 = 0;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		
		If CommandParameter.Count() = 0 Then
			ShowMessageBox(,NStr("en = 'No business process is selected.';"));
			Return;
		EndIf;
		
		If CommandParameter.Count() = 1 And TypeOf(CommandParameter[0]) = Type("DynamicListGroupRow") Then
			ShowMessageBox(,NStr("en = 'No business process is selected.';"));
			Return;
		EndIf;
		
		TaskCount1 = BusinessProcessesAndTasksServerCall.UncompletedBusinessProcessesTasksCount(CommandParameter);
		If CommandParameter.Count() = 1 Then
			If TaskCount1 > 0 Then
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Business process ""%1"" and all its unfinished tasks (%2) will be suspended. Continue?';"), 
					String(CommandParameter[0]), TaskCount1);
			Else
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Business process ""%1"" will be suspended. Continue?';"), 
					String(CommandParameter[0]));
			EndIf;
		Else
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Business processes (%1) and all their unfinished tasks (%2) will be suspended. Continue?';"), 
				CommandParameter.Count(), TaskCount1);
		EndIf;
		
	Else
		
		If TypeOf(CommandParameter) = Type("DynamicListGroupRow") Then
			ShowMessageBox(,NStr("en = 'No business process is selected';"));
			Return;
		EndIf;
		
		TaskCount1 = BusinessProcessesAndTasksServerCall.UncompletedBusinessProcessTasksCount(CommandParameter);
		If TaskCount1 > 0 Then
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Business process ""%1"" and all its unfinished tasks (%2) will be suspended. Continue?';"), 
				String(CommandParameter), TaskCount1);
		Else
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Business process ""%1"" will be suspended. Continue?';"), 
				String(CommandParameter));
		EndIf;
		
	EndIf;
	
	Notification = New NotifyDescription("StopCompletion", ThisObject, CommandParameter);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No, NStr("en = 'Suspend business process';"));
	
EndProcedure

// Marks the specified business process as stopped.
//  It is intended for calling a business process from a form.
//
// Parameters:
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForObjects - :
//   * Object - DefinedType.BusinessProcessObject -  business process. 
//
Procedure StopBusinessProcessFromObjectForm(Form) Export
	Form.Object.State = PredefinedValue("Enum.BusinessProcessStates.Suspended");
	ClearMessages();
	Form.Write();
	ShowUserNotification(
		NStr("en = 'The business process is suspended.';"),
		GetURL(Form.Object.Ref),
		String(Form.Object.Ref),
		PictureLib.DialogInformation);
	NotifyChanged(Form.Object.Ref);
	
EndProcedure

// Marks the specified business processes as active.
//
// Parameters:
//  CommandParameter - Array of DefinedType.BusinessProcess
//                  - DynamicListGroupRow
//                  - DefinedType.BusinessProcess - 
//
Procedure Activate(Val CommandParameter) Export
	
	QueryText = "";
	TaskCount1 = 0;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		
		If CommandParameter.Count() = 0 Then
			ShowMessageBox(,NStr("en = 'No business process is selected.';"));
			Return;
		EndIf;
		
		If CommandParameter.Count() = 1 And TypeOf(CommandParameter[0]) = Type("DynamicListGroupRow") Then
			ShowMessageBox(,NStr("en = 'No business process is selected.';"));
			Return;
		EndIf;
		
		TaskCount1 = BusinessProcessesAndTasksServerCall.UncompletedBusinessProcessesTasksCount(CommandParameter);
		If CommandParameter.Count() = 1 Then
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Business process ""%1"" and its tasks (%2) will be active. Continue?';"),
				String(CommandParameter[0]), TaskCount1);
		Else		
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Business processes (%1) and their tasks (%2) will be active. Continue?';"),
				CommandParameter.Count(), TaskCount1);
		EndIf;
		
	Else
		
		If TypeOf(CommandParameter) = Type("DynamicListGroupRow") Then
			ShowMessageBox(,NStr("en = 'No business process is selected.';"));
			Return;
		EndIf;
		
		TaskCount1 = BusinessProcessesAndTasksServerCall.UncompletedBusinessProcessTasksCount(CommandParameter);
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Business process ""%1"" and its tasks (%2) will be active. Continue?';"),
			String(CommandParameter), TaskCount1);
			
	EndIf;
	
	Notification = New NotifyDescription("ActivateCompletion", ThisObject, CommandParameter);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No, NStr("en = 'Suspend business process';"));
	
EndProcedure

// Marks the specified business process as active.
// It is intended for calling a business process from a form.
//
// Parameters:
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForObjects - :
//   * Object - DefinedType.BusinessProcessObject -  business process.
//
Procedure ContinueBusinessProcessFromObjectForm(Form) Export
	
	Form.Object.State = PredefinedValue("Enum.BusinessProcessStates.Running");
	ClearMessages();
	Form.Write();
	ShowUserNotification(
		NStr("en = 'The business process is activated';"),
		GetURL(Form.Object.Ref),
		String(Form.Object.Ref),
		PictureLib.DialogInformation);
	NotifyChanged(Form.Object.Ref);
	
EndProcedure

// Marks the specified tasks as accepted for execution.
//
// Parameters:
//  TaskArray - Array of TaskRef.PerformerTask
//
Procedure AcceptTasksForExecution(Val TaskArray) Export
	
	BusinessProcessesAndTasksServerCall.AcceptTasksForExecution(TaskArray);
	If TaskArray.Count() = 0 Then
		ShowMessageBox(,NStr("en = 'Cannot run the command for the object.';"));
		Return;
	EndIf;
	
	TaskValueType = Undefined;
	For Each Task In TaskArray Do
		If TypeOf(Task) <> Type("DynamicListGroupRow") Then 
			TaskValueType = TypeOf(Task);
			Break;
		EndIf;
	EndDo;
	If TaskValueType <> Undefined Then
		NotifyChanged(TaskValueType);
	EndIf;
	
EndProcedure

// Marks the specified task as accepted for execution.
//
// Parameters:
//  Form               - ClientApplicationForm
//                      - ManagedFormExtensionForObjects - :
//   * Object - TaskObject -  task.
//  CurrentUser - CatalogRef.ExternalUsers
//                      - CatalogRef.Users - 
//                                                        
//
Procedure AcceptTaskForExecution(Form, CurrentUser) Export
	
	Form.Object.AcceptedForExecution = True;
	
	//  
	// 
	Form.Object.AcceptForExecutionDate = Date('00010101');
	If Not ValueIsFilled(Form.Object.Performer) Then
		Form.Object.Performer = CurrentUser;
	EndIf;
	
	ClearMessages();
	Form.Write();
	UpdateAcceptForExecutionCommandsAvailability(Form);
	NotifyChanged(Form.Object.Ref);
	
EndProcedure

// Marks the specified tasks as not accepted for execution.
//
// Parameters:
//  TaskArray - Array of TaskRef.PerformerTask
//
Procedure CancelAcceptTasksForExecution(Val TaskArray) Export
	
	BusinessProcessesAndTasksServerCall.CancelAcceptTasksForExecution(TaskArray);
	
	If TaskArray.Count() = 0 Then
		ShowMessageBox(, NStr("en = 'Cannot run the command for the object.';"));
		Return;
	EndIf;
	
	TaskValueType = Undefined;
	For Each Task In TaskArray Do
		If TypeOf(Task) <> Type("DynamicListGroupRow") Then 
			TaskValueType = TypeOf(Task);
			Break;
		EndIf;
	EndDo;
	
	If TaskValueType <> Undefined Then
		NotifyChanged(TaskValueType);
	EndIf;
	
EndProcedure

// Marks the specified task as not accepted for execution.
//
// Parameters:
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForObjects - :
//   * Object - TaskObject -  task.
//
Procedure CancelAcceptTaskForExecution(Form) Export
	
	Form.Object.AcceptedForExecution      = False;
	Form.Object.AcceptForExecutionDate = "00010101000000";
	If Not Form.Object.PerformerRole.IsEmpty() Then
		Form.Object.Performer = Undefined;
	EndIf;
	
	ClearMessages();
	Form.Write();
	UpdateAcceptForExecutionCommandsAvailability(Form);
	NotifyChanged(Form.Object.Ref);
	
EndProcedure

// Sets whether accept commands are available for execution.
//
// Parameters:
//  Form - ClientApplicationForm - :
//   * Items - FormAllItems - :
//     ** FormAcceptForExecution - TextBox -  command button on the form.
//     ** FormCancelAcceptForExecution - TextBox -  command button on the form. 
//
Procedure UpdateAcceptForExecutionCommandsAvailability(Form) Export
	
	If Form.Object.AcceptedForExecution = True Then
		Form.Items.FormAcceptForExecution.Enabled = False;
		
		If Form.Object.Executed Then
			Form.Items.FormCancelAcceptForExecution.Enabled = False;
		Else
			Form.Items.FormCancelAcceptForExecution.Enabled = True;
		EndIf;
		
	Else	
		Form.Items.FormAcceptForExecution.Enabled = True;
		Form.Items.FormCancelAcceptForExecution.Enabled = False;
	EndIf;
		
EndProcedure

// Opens a form for setting up a deferred start of the business process.
//
// Parameters:
//  BusinessProcess  - DefinedType.BusinessProcess
//  TaskDueDate - Date
//
Procedure SetUpDeferredStart(BusinessProcess, TaskDueDate) Export
	
	If BusinessProcess.IsEmpty() Then
		WarningText = 
			NStr("en = 'Cannot set up deferred start for an unsaved process.';");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
		
	FormParameters = New Structure;
	FormParameters.Insert("BusinessProcess", BusinessProcess);
	FormParameters.Insert("TaskDueDate", TaskDueDate);
	
	OpenForm(
		"InformationRegister.ProcessesToStart.Form.DeferredProcessStartSetup",
		FormParameters,,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Standard notification handler for task completion forms.
//  To call from the event handler of the message Processing form.
//
// Parameters:
//  Form      - ClientApplicationForm - :
//   * Object - TaskObject  - 
//  EventName - String       -  event name.
//  Parameter   - Arbitrary -  event parameter.
//  Source   - Arbitrary -  event source.
//
Procedure TaskFormNotificationProcessing(Form, EventName, Parameter, Source) Export
	
	If EventName = "Write_PerformerTask" 
		And Not Form.Modified 
		And (Source = Form.Object.Ref Or (TypeOf(Source) = Type("Array") 
		And Source.Find(Form.Object.Ref) <> Undefined)) Then
		If Parameter.Property("Forwarded") Then
			Form.Close();
		Else
			Form.Read();
		EndIf;
	EndIf;
	
EndProcedure

// Standard pre-start handler For adding tasks to lists.
//  To call from the event handler of the form table before starting the Add-on.
//
// Parameters:
//  Form        - ClientApplicationForm -  task form.
//  Item      - FormTable -  elements of the form table.
//  Cancel        - Boolean -  indicates that the object was not added. If this
//                          parameter is set to True in the body of the handler procedure, the object will not be added.
//  Copy  - Boolean -  defines the copy mode. If set to True, the string is copied. 
//  Parent     - Undefined
//               - CatalogRef
//               - ChartOfAccountsRef - 
//                                    
//  Group       - Boolean -  indicates whether to add a group. True - the group will be added. 
//
Procedure TaskListBeforeAddRow(Form, Item, Cancel, Copy, Parent, Group) Export
	
	If Copy Then
		Task = Item.CurrentRow;
		If Not ValueIsFilled(Task) Then
			Return;
		EndIf;
		FormParameters = New Structure("Basis", Task);
	EndIf;
	CreateJob(Form, FormParameters);
	Cancel = True;
	
EndProcedure

// Write and close the task completion form.
//
// Parameters:
//  Form  - ClientApplicationForm - :
//   * Object - TaskObject -  the task of the business process.
//  ExecuteTask  - Boolean -  the task is recorded in run mode.
//  NotificationParameters - Structure -  additional notification parameters.
//
// Returns:
//   Boolean   - 
//
Function WriteAndCloseExecute(Form, ExecuteTask = False, NotificationParameters = Undefined) Export
	
	ClearMessages();
	
	NewObject = Form.Object.Ref.IsEmpty();
	NotificationText1 = "";
	If NotificationParameters = Undefined Then
		NotificationParameters = New Structure;
	EndIf;
	If Not Form.InitialExecutionFlag And ExecuteTask Then
		If Not Form.Write(New Structure("ExecuteTask", True)) Then
			Return False;
		EndIf;
		NotificationText1 = NStr("en = 'The task is completed';");
	Else
		If Not Form.Write() Then
			Return False;
		EndIf;
		NotificationText1 = ?(NewObject, NStr("en = 'The task is created';"), NStr("en = 'The task is changed';"));
	EndIf;
	
	Notify("Write_PerformerTask", NotificationParameters, Form.Object.Ref);
	ShowUserNotification(NotificationText1,
		GetURL(Form.Object.Ref),
		String(Form.Object.Ref),
		PictureLib.DialogInformation);
	Form.Close();
	Return True;
	
EndFunction

// Open the form to enter a new task.
//
// Parameters:
//  OwnerForm  - ClientApplicationForm -  the form that should be the owner for the one being opened.
//  FormParameters - Structure -  parameters of the form to open.
//
Procedure CreateJob(Val OwnerForm = Undefined, Val FormParameters = Undefined) Export
	
	OpenForm("BusinessProcess.Job.ObjectForm", FormParameters, OwnerForm);
	
EndProcedure	

// Open a form to redirect one or more tasks to another performer.
//
// Parameters:
//  RedirectedTasks_SSLs - Array of TaskRef.PerformerTask
//  OwnerForm - ClientApplicationForm -  the form that should be the owner of
//                                               the task redirection form that is being opened.
//
Procedure ForwardTasks(RedirectedTasks_SSLs, OwnerForm) Export
	
	If RedirectedTasks_SSLs = Undefined Then
		ShowMessageBox(,NStr("en = 'Tasks are not selected.';"));
		Return;
	EndIf;
		
	TasksCanBeForwarded = BusinessProcessesAndTasksServerCall.ForwardTasks(
		RedirectedTasks_SSLs, Undefined, True);
	If Not TasksCanBeForwarded And RedirectedTasks_SSLs.Count() = 1 Then
		ShowMessageBox(,NStr("en = 'Cannot forward a task that is already completed or was sent to another user.';"));
		Return;
	EndIf;
		
	Notification = New NotifyDescription("ForwardTasksCompletion", ThisObject, RedirectedTasks_SSLs);
	OpenForm("Task.PerformerTask.Form.ForwardTasks",
		New Structure("Task,TaskCount,FormCaption", 
		RedirectedTasks_SSLs[0], RedirectedTasks_SSLs.Count(), 
		?(RedirectedTasks_SSLs.Count() > 1, NStr("en = 'Forward tasks';"), 
			NStr("en = 'Forward task';"))), 
		OwnerForm,,,,Notification);
		
EndProcedure

// Open a form with additional information about the issue.
//
// Parameters:
//  TaskRef - TaskRef.PerformerTask
// 
Procedure OpenAdditionalTaskInfo(Val TaskRef) Export
	
	OpenForm("Task.PerformerTask.Form.More", 
		New Structure("Key", TaskRef));
	
EndProcedure

#EndRegion

#Region Internal

Procedure OpenRolesAndTaskPerformersList() Export
	
	OpenForm("InformationRegister.TaskPerformers.Form.RolesAndTaskPerformers");
	
EndProcedure

// 
// 
// Parameters:
//  FormParameters - See PerformerRoleChoiceFormParameters
//  Owner - Undefined
//           - ClientApplicationForm - 
//
Procedure OpenPerformerRoleChoiceForm(FormParameters, Owner) Export

	OpenForm("CommonForm.SelectPerformerRole", FormParameters, Owner);

EndProcedure

// 
// 
// Parameters:
//  PerformerRole - CatalogRef.PerformerRoles -  
//  MainAddressingObject - Arbitrary - 
//  AdditionalAddressingObject - Arbitrary - 
// 
// Returns:
//  Structure:
//   * PerformerRole  - CatalogRef.PerformerRoles - 
//   * MainAddressingObject - Arbitrary - 
//   * AdditionalAddressingObject - Arbitrary - 
//   * SelectAddressingObject - Boolean - 
// 
Function PerformerRoleChoiceFormParameters(PerformerRole, MainAddressingObject = Undefined, 
		AdditionalAddressingObject = Undefined) Export

	FormParameters = New Structure;
	FormParameters.Insert("PerformerRole",               PerformerRole);
	FormParameters.Insert("MainAddressingObject",       MainAddressingObject);
	FormParameters.Insert("AdditionalAddressingObject", AdditionalAddressingObject);
	FormParameters.Insert("SelectAddressingObject",         False);
	
	Return FormParameters;

EndFunction

#EndRegion

#Region Private

Procedure OpenBusinessProcess(List) Export
	If TypeOf(List.CurrentRow) <> Type("TaskRef.PerformerTask") Then
		ShowMessageBox(,NStr("en = 'Cannot run the command for the object.';"));
		Return;
	EndIf;
	If List.CurrentData.BusinessProcess = Undefined Then
		ShowMessageBox(,NStr("en = 'Business process of the selected task is not specified.';"));
		Return;
	EndIf;
	ShowValue(, List.CurrentData.BusinessProcess);
EndProcedure

Procedure OpenTaskSubject(List) Export
	If TypeOf(List.CurrentRow) <> Type("TaskRef.PerformerTask") Then
		ShowMessageBox(,NStr("en = 'Cannot run the command for the object.';"));
		Return;
	EndIf;
	If List.CurrentData.SubjectOf = Undefined Then
		ShowMessageBox(,NStr("en = 'Subject of the selected task is not specified.';"));
		Return;
	EndIf;
	ShowValue(, List.CurrentData.SubjectOf);
EndProcedure

// Standard tag Deletion handler for business process lists.
// To call from the event handler of the mark-Delete list.
//
// Parameters:
//   List  - FormTable -  the control (table form) with a list of business processes.
//
Procedure BusinessProcessesListDeletionMark(List) Export
	
	SelectedRows = List.SelectedRows;
	If SelectedRows = Undefined Or SelectedRows.Count() <= 0 Then
		ShowMessageBox(,NStr("en = 'Cannot run the command for the object.';"));
		Return;
	EndIf;
	Notification = New NotifyDescription("BusinessProcessesListDeletionMarkCompletion", ThisObject, List);
	ShowQueryBox(Notification, NStr("en = 'Change deletion mark?';"), QuestionDialogMode.YesNo);
	
EndProcedure

// Opens the shape selection of the contractor.
//
// Parameters:
//   PerformerItem - FormField -  the element of the form in which the performer is selected, 
//      which will be specified as the owner of the performer selection form.
//   PerformerAttribute - CatalogRef.Users -  the previously selected value of the performer.
//      Used to set the current line in the artist selection form.
//   SimpleRolesOnly - Boolean -  if True, it indicates that 
//      only roles without addressing objects should be used for selection.
//   NoExternalRoles - Boolean -  if True, it indicates that
//      only roles that do not have the external Role attribute set should be used for selection.
//
Procedure SelectPerformer(PerformerItem, PerformerAttribute, SimpleRolesOnly = False, NoExternalRoles = False) Export 
	
	StandardProcessing = True;
	BusinessProcessesAndTasksClientOverridable.OnPerformerChoice(PerformerItem, PerformerAttribute, 
		SimpleRolesOnly, NoExternalRoles, StandardProcessing);
	If Not StandardProcessing Then
		Return;
	EndIf;
			
	FormParameters = New Structure("Performer, SimpleRolesOnly, NoExternalRoles", 
		PerformerAttribute, SimpleRolesOnly, NoExternalRoles);
	OpenForm("CommonForm.SelectBusinessProcessPerformer", FormParameters, PerformerItem);
	
EndProcedure	

Procedure StopCompletion(Val Result, Val CommandParameter) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		
		BusinessProcessesAndTasksServerCall.StopBusinessProcesses(CommandParameter);
		
	Else
		
		BusinessProcessesAndTasksServerCall.StopBusinessProcess(CommandParameter);
		
	EndIf;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		
		If CommandParameter.Count() <> 0 Then
			
			For Each Parameter In CommandParameter Do
				
				If TypeOf(Parameter) <> Type("DynamicListGroupRow") Then
					NotifyChanged(TypeOf(Parameter));
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	Else
		NotifyChanged(CommandParameter);
	EndIf;

EndProcedure

Procedure BusinessProcessesListDeletionMarkCompletion(Result, List) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	SelectedRows = List.SelectedRows;
	BusinessProcessRef = BusinessProcessesAndTasksServerCall.MarkBusinessProcessesForDeletion(SelectedRows);
	List.Refresh();
	ShowUserNotification(NStr("en = 'The deletion mark is changed.';"), 
		?(BusinessProcessRef <> Undefined, GetURL(BusinessProcessRef), ""),
		?(BusinessProcessRef <> Undefined, String(BusinessProcessRef), ""));
	
EndProcedure

Procedure ActivateCompletion(Val Result, Val CommandParameter) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
		
	If TypeOf(CommandParameter) = Type("Array") Then
		
		BusinessProcessesAndTasksServerCall.ActivateBusinessProcesses(CommandParameter);
		
	Else
		
		BusinessProcessesAndTasksServerCall.ActivateBusinessProcess(CommandParameter);
		
	EndIf;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		
		If CommandParameter.Count() <> 0 Then
			
			For Each Parameter In CommandParameter Do
				
				If TypeOf(Parameter) <> Type("DynamicListGroupRow") Then
					NotifyChanged(TypeOf(Parameter));
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	Else
		NotifyChanged(CommandParameter);
	EndIf;
	
EndProcedure

Procedure ForwardTasksCompletion(Val Result, Val TaskArray) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	ForwardedTaskArray = Undefined;
	TasksAreForwarded = BusinessProcessesAndTasksServerCall.ForwardTasks(
		TaskArray, Result, False, ForwardedTaskArray);
		
	Notify("Write_PerformerTask", New Structure("Forwarded", TasksAreForwarded), TaskArray);
	
EndProcedure

#EndRegion