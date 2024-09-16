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

// Returns object details that can be edited
// by processing group changes to details.
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export

	Result = New Array;
	Result.Add("Author");
	Result.Add("Importance");
	Result.Add("Performer");
	Result.Add("CheckExecution");
	Result.Add("Supervisor");
	Result.Add("TaskDueDate");
	Result.Add("VerificationDueDate");
	Return Result;

EndFunction

// End StandardSubsystems.BatchEditObjects

// 

// Get a structure with a description of the task completion form.
// Called when opening the task completion form.
//
// Parameters:
//   TaskRef                - TaskRef.PerformerTask - 
//   BusinessProcessRoutePoint - BusinessProcessRoutePointRef.Job - 
//
// Returns:
//   Structure:
//    * FormParameters - Structure:
//      ** Key - TaskRef.PerformerTask
//    * FormName - String - 
//
Function TaskExecutionForm(TaskRef, BusinessProcessRoutePoint) Export

	Result = New Structure;
	Result.Insert("FormParameters", New Structure("Key", TaskRef));

	FormName = ?(BusinessProcessRoutePoint = BusinessProcesses.Job.RoutePoints.Validate,
		Metadata.BusinessProcesses.Job.Forms.ActionCheck.FullName(),
		Metadata.BusinessProcesses.Job.Forms.ActionExecute.FullName());
	Result.Insert("FormName", FormName);

	Return Result;

EndFunction

// Called when a task is redirected.
//
// Parameters:
//   TaskRef  - TaskRef.PerformerTask -  the forwarded task.
//   NewTaskRef  - TaskRef.PerformerTask -  task for a new performer.
//
Procedure OnForwardTask(TaskRef, NewTaskRef) Export
	
	// 
	// 
	TaskInfo = Common.ObjectAttributesValues(TaskRef, 
		"Ref,BusinessProcess,ExecutionResult,CompletionDate,Performer");
	BusinessProcessObject = TaskInfo.BusinessProcess.GetObject();
	LockDataForEdit(BusinessProcessObject.Ref);
	BusinessProcessObject.ExecutionResult = ExecutionResultOnForward(TaskInfo)
		+ BusinessProcessObject.ExecutionResult;
	SetPrivilegedMode(True);
	BusinessProcessObject.Write();
	// 

EndProcedure

// Called when executing a task from the list form.
//
// Parameters:
//   TaskRef  - TaskRef.PerformerTask -  task.
//   BusinessProcessRef - BusinessProcessRef -  business the process by which the task of Segacasino.
//   BusinessProcessRoutePoint - BusinessProcessRoutePointRef -  route point.
//
Procedure DefaultCompletionHandler(TaskRef, BusinessProcessRef, BusinessProcessRoutePoint) Export

	IsRoutePointComplete = (BusinessProcessRoutePoint = BusinessProcesses.Job.RoutePoints.Execute);
	IsRoutePointCheck = (BusinessProcessRoutePoint = BusinessProcesses.Job.RoutePoints.Validate);
	If Not IsRoutePointComplete And Not IsRoutePointCheck Then
		Return;
	EndIf;
	
	// 
	BeginTransaction();
	Try
		BusinessProcessesAndTasksServer.LockBusinessProcesses(BusinessProcessRef);

		SetPrivilegedMode(True);
		JobObject = BusinessProcessRef.GetObject();
		LockDataForEdit(JobObject.Ref);

		If IsRoutePointComplete Then
			JobObject.Completed2 = True;
		ElsIf IsRoutePointCheck Then
			JobObject.Completed2 = True;
			JobObject.Accepted = True;
		EndIf;
		JobObject.Write(); // 

		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure	

// End StandardSubsystems.BusinessProcessesAndTasks

// 

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS Job
	|
	|LEFT JOIN InformationRegister.TaskPerformers AS TaskPerformers
	|ON
	|	TaskPerformers.PerformerRole = Job.Performer
	|	AND TaskPerformers.MainAddressingObject = Job.MainAddressingObject
	|	AND TaskPerformers.AdditionalAddressingObject = Job.AdditionalAddressingObject
	|
	|LEFT JOIN InformationRegister.TaskPerformers AS TaskSupervisors
	|ON
	|	TaskSupervisors.PerformerRole = Job.Supervisor
	|	AND TaskSupervisors.MainAddressingObject = Job.MainAddressingObjectSupervisor
	|	AND TaskSupervisors.AdditionalAddressingObject = Job.AdditionalAddressingObjectSupervisor
	|;
	|AllowRead
	|WHERE
	|	ValueAllowed(Author)
	|	OR ValueAllowed(Performer Not Catalog.PerformerRoles)
	|	OR ValueAllowed(TaskPerformers.Performer)
	|	OR ValueAllowed(Supervisor Not Catalog.PerformerRoles)
	|	OR ValueAllowed(TaskSupervisors.Performer)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Author)";

EndProcedure

// End StandardSubsystems.AccessManagement

// Standard subsystems.Pluggable commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export

EndProcedure

// To use in the procedure add a create command Based on other object Manager modules.
// Adds this object to the list of base creation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - 
//
Function AddGenerateCommand(GenerationCommands) Export

	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleGeneration = Common.CommonModule("GenerateFrom");
		Command = ModuleGeneration.AddGenerationCommand(GenerationCommands,
			Metadata.BusinessProcesses.Job);
		If Command <> Undefined Then
			Command.FunctionalOptions = "UseBusinessProcessesAndTasks";
		EndIf;
		Return Command;
	EndIf;

	Return Undefined;

EndFunction

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#EndIf

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

////////////////////////////////////////////////////////////////////////////////
// OtherItems

// Sets the state of the task form elements.
//
// Parameters:
//  Form - ClientApplicationForm:
//   * Items - FormAllItems:
//    ** SubjectOf - FormFieldExtensionForALabelField
// 
Procedure SetTaskFormItemsState(Form) Export

	If Form.Items.Find("ExecutionResult") <> Undefined 
		And Form.Items.Find("ExecutionHistory") <> Undefined Then
		Form.Items.ExecutionHistory.Picture = CommonClientServer.CommentPicture(
			Form.JobExecutionResult);
	EndIf;

	Form.Items.SubjectOf.Hyperlink = Form.Object.SubjectOf <> Undefined And Not Form.Object.SubjectOf.IsEmpty();
	Form.SubjectString = Common.SubjectString(Form.Object.SubjectOf);

EndProcedure

Function ExecutionResultOnForward(Val TaskInfo)

	StringFormat = "%1, %2 " + NStr("en = 'redirected the task';") + ":
																	   |%3
																	   |";

	Comment = TrimAll(TaskInfo.ExecutionResult);
	Comment = ?(IsBlankString(Comment), "", Comment + Chars.LF);
	Result = StringFunctionsClientServer.SubstituteParametersToString(StringFormat, TaskInfo.CompletionDate,
		TaskInfo.Performer, Comment);
	Return Result;

EndFunction

#EndRegion

#EndIf