///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlersForm

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	ClearAndClose = Parameters.ClearAndClose;
	Items.DialogCommandPanel.Visible = False;
	
	UpdateVisibilityAvailability(ThisObject, True);
	
	If ClearAndClose Then
		CleanWhatIsBeingRemoved = False;
		Items.WarningInscription.Title =
			NStr("en = 'The deferred update is <a href = %1>not completed</a>. We recommend that you complete the update and clear data before the configuration update.';");
		StandardSubsystemsServer.ResetWindowLocationAndSize(ThisObject);
		Items.GroupRemark.Visible = False;
		Items.ShouldProcessDataAreas.Visible = False;
		Items.CommandBarForm.Visible = False;
		If DeferredUpdateCompleted Then
			LongTermCleaningOperation = StartCleaningOnServer();
		Else
			LongTermUpdateOperation = StartUpdatingOnServer();
			Items.WarningGroup.Visible = False;
		EndIf;
	Else
		URL = "e1cib/app/DataProcessor.ApplicationUpdateResult.Form.ClearingOutdatedData";
		LongTermUpdateOperation = StartUpdatingOnServer();
		Items.OutdatedDataDataArea.Format = "NZ=0";
	EndIf;
	
	Items.WarningInscription.Title = StringFunctions.FormattedString(
		Items.WarningInscription.Title, "OpenUpdateResults");
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		UpdateProgressReport = ModuleInfobaseUpdateInternalSaaS.UpdateProgressReport();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ClearAndClose
	 Or Not DeferredUpdateCompleted Then
		Refresh(Undefined);
	Else
		Clear(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	CancelLongTermOperations();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "LoggedOffFromDataArea"
	 Or EventName = "LoggedOnToDataArea" Then
		
		AttachIdleHandler("OnChangeDataArea", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarningInscriptionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL <> "OpenUpdateResults" Then
		Return;
	EndIf;
	
	If SharedMode And ValueIsFilled(UpdateProgressReport) Then
		OpenForm(UpdateProgressReport);
	Else
		OpenForm("DataProcessor.ApplicationUpdateResult.Form");
	EndIf;
	
EndProcedure

&AtClient
Procedure ShouldProcessDataAreasOnChange(Item)
	
	OutdatedData.Clear();
	UpdateVisibilityAvailability(ThisObject, True);
	Refresh("");
	
EndProcedure

&AtClient
Procedure OutputQuantityOnChange(Item)
	
	If OutputQuantity Then
		OutdatedData.Clear();
	EndIf;
	
	UpdateVisibilityAvailability(ThisObject);
	Refresh("");
	
EndProcedure

&AtClient
Procedure CleanWhatIsBeingRemovedOnChange(Item)
	
	OutdatedData.Clear();
	Refresh("");
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ContinueWithoutClearing(Command)
	Close(True);
EndProcedure

&AtClient
Procedure CancelConfigurationUpdate(Command)
	Close(False);
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	Items.ShouldProcessDataAreas.Enabled = True;
	Items.OutputQuantity.Enabled = True;
	Items.CleanWhatIsBeingRemoved.Enabled = True;
	
	If Command <> Undefined Then
		LongTermUpdateOperation = StartUpdatingOnServer();
	EndIf;
	
	EstablishProgress(0);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.ExecutionProgressNotification =
		New NotifyDescription("UpdateWhenProgressIsReceived",
			ThisObject, LongTermUpdateOperation);
	
	CompletionNotification2 = New NotifyDescription("RefreshCompletion",
		ThisObject, LongTermUpdateOperation);
	
	TimeConsumingOperationsClient.WaitCompletion(LongTermUpdateOperation,
		CompletionNotification2, IdleParameters);
	
EndProcedure

&AtClient
Procedure Clear(Command)
	
	If DeferredUpdateCompleted Then
		ClearAfterConfirmation(New Structure("Value", "Continue"), Command);
		Return;
	EndIf;
	
	CompletionProcessing = New NotifyDescription(
		"ClearAfterConfirmation", ThisObject, Command);
	
	QueryText =
		NStr("en = 'The deferred update is not completed.
		           |The cleanup might delete data required to complete the update.
		           |
		           |Create a backup if you have not done it yet.';");
	
	Buttons = New ValueList;
	Buttons.Add("Continue", NStr("en = 'Continue';"));
	Buttons.Add("Cancel",     NStr("en = 'Cancel';"));
	
	AdditionalParameters = StandardSubsystemsClient.QuestionToUserParameters();
	AdditionalParameters.Title = NStr("en = 'Clear obsolete data';");
	AdditionalParameters.PromptDontAskAgain = False;
	AdditionalParameters.DefaultButton = "Cancel";
	
	StandardSubsystemsClient.ShowQuestionToUser(CompletionProcessing,
		QueryText, Buttons, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure CleaningPlan(Command)
	
	TextDocument = New TextDocument;
	TextDocument.SetText(CleaningPlanOnServer(CleanWhatIsBeingRemoved, ShouldProcessDataAreas));
	TextDocument.Show(NStr("en = 'Obsolete data cleanup plan';"));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OutdatedDataDataArea.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OutdatedData.DataArea");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = -1;
	
	Item.Appearance.SetParameterValue("Text", NStr("en = 'Shared data';"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateVisibilityAvailability(Form, UpdateResultOfDelayedUpdate = False)

	Items = Form.Items;
	
	If UpdateResultOfDelayedUpdate Then
		Form.DeferredUpdateCompleted = DeferredUpdateCompleted(Form.SharedMode);
	EndIf;
	Items.WarningGroup.Visible = Not Form.DeferredUpdateCompleted;
	
	Items.ShouldProcessDataAreas.Visible = Form.SharedMode;
	Items.OutdatedDataDataArea.Visible =
		Form.SharedMode And Form.ShouldProcessDataAreas;
	
	Items.OutdatedDataCount.Visible = Form.OutputQuantity;
	Items.OutdatedData.Header =
		    Items.OutdatedDataCount.Visible
		Or Items.OutdatedDataDataArea.Visible;
	
	Items.OutdatedData.HeaderHeight =
		?(Items.OutdatedDataCount.Visible, 2, 1);
	
	Items.FormClear.Enabled = Form.OutdatedData.Count() > 0;
	
EndProcedure

&AtServerNoContext
Function DeferredUpdateCompleted(SharedMode)
	
	SharedMode = Not Common.SeparatedDataUsageAvailable();
	
	Return InfobaseUpdateInternal.DeferredUpdateCompleted();
	
EndFunction

&AtClient
Procedure OnChangeDataArea()
	
	Refresh("");
	
EndProcedure

&AtServer
Procedure CancelLongTermOperations()
	
	If LongTermUpdateOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(
			LongTermUpdateOperation.JobID);
		LongTermUpdateOperation = Undefined;
	EndIf;
	
	If LongTermCleaningOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(
			LongTermCleaningOperation.JobID);
		LongTermCleaningOperation = Undefined;
	EndIf;
	
	If ValueIsFilled(AddressOfUpdateResult) Then
		DeleteFromTempStorage(AddressOfUpdateResult);
		AddressOfUpdateResult = "";
	EndIf;
	
	If ValueIsFilled(AddressOfCleanupResult) Then
		DeleteFromTempStorage(AddressOfCleanupResult);
		AddressOfCleanupResult = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure EstablishProgress(Percent)
	
	Items.LongTermOperationPercentage.Title = 
		Format(Percent, "NZ=0") + "%";
	
EndProcedure


&AtServer
Function StartUpdatingOnServer()
	
	UpdateVisibilityAvailability(ThisObject, True);
	
	OutdatedData.Clear();
	
	Items.Pages.CurrentPage = Items.TimeConsumingOperationPage;
	Items.LongTermOperationText.Title =
		NStr("en = 'Updating the obsolete data list...';");
	
	CancelLongTermOperations();
	
	AddressOfUpdateResult = PutToTempStorage(Undefined, UUID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Update the obsolete data list';");
	ExecutionParameters.ResultAddress = AddressOfUpdateResult;
	ExecutionParameters.RunInBackground = True; // 
	ExecutionParameters.WithDatabaseExtensions = True;
	
	JobParameters = New Structure;
	JobParameters.Insert("OutputQuantity", OutputQuantity);
	JobParameters.Insert("CleanWhatIsBeingRemoved", CleanWhatIsBeingRemoved);
	JobParameters.Insert("ShouldProcessDataAreas", ShouldProcessDataAreas);
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		"InfobaseUpdateInternal.CreateListOfOutdatedDataInBackground",
		JobParameters, ExecutionParameters);
		
	Return Result;
	
EndFunction

&AtClient
Procedure UpdateWhenProgressIsReceived(Result, AdditionalParameters) Export
	
	If AdditionalParameters <> LongTermUpdateOperation Then
		Return;
	EndIf;
	
	If Result.Progress <> Undefined Then
		EstablishProgress(Result.Progress.Percent);
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshCompletion(Result, AdditionalParameters) Export
	
	If AdditionalParameters <> LongTermUpdateOperation Then
		Return;
	EndIf;
	
	HasError = False;
	CompleteUpdateOnServer(Result, HasError);
	
	If Not ClearAndClose Then
		UpdateVisibilityAvailability(ThisObject);
		Return;
	EndIf;
	
	If HasError Or OutdatedData.Count() > 0 Then
		UpdateVisibilityAvailability(ThisObject);
		Items.Pages.Visible = False;
		Items.DialogCommandPanel.Visible = True;
		Items.CancelConfigurationUpdate.DefaultButton = True;
		Return;
	EndIf;
	
	Close(True);
	
EndProcedure

&AtServer
Procedure CompleteUpdateOnServer(Val Result, HasError)
	
	LongTermUpdateOperation = Undefined;
	Items.Pages.CurrentPage = Items.OutdatedDataPage;
	
	If ValueIsFilled(AddressOfUpdateResult) Then
		Data = GetFromTempStorage(AddressOfUpdateResult);
		DeleteFromTempStorage(AddressOfUpdateResult);
		AddressOfUpdateResult = "";
	Else
		Data = Undefined;
	EndIf;
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ErrorText = "";
	
	If Result.Status = "Error" Then
		ErrorText = Result.DetailErrorDescription;
	ElsIf TypeOf(Data) = Type("String") Then
		ErrorText = Data;
	ElsIf Data = Undefined Then
		ErrorText = NStr("en = 'The background job did not return a result';");
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		Items.Pages.CurrentPage = Items.ErrorPage;
		HasError = True;
		Return;
	EndIf;
	
	If Result.Status <> "Completed2" Then
		HasError = True;
		Return;
	EndIf;
	
	For Each String In Data Do
		FillPropertyValues(OutdatedData.Add(), String);
	EndDo;
	
EndProcedure


&AtClient
Procedure ClearAfterConfirmation(Response, Command) Export
	
	If Not ValueIsFilled(Response)
	 Or Response.Value <> "Continue" Then
		Return;
	EndIf;
	
	If Command <> Undefined Then
		LongTermCleaningOperation = StartCleaningOnServer();
	EndIf;
	
	EstablishProgress(0);
	
	Items.ShouldProcessDataAreas.Enabled = False;
	Items.OutputQuantity.Enabled = False;
	Items.CleanWhatIsBeingRemoved.Enabled = False;
	Items.FormClear.Enabled = False;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.ExecutionProgressNotification =
		New NotifyDescription("ClearWhenReceivingProgress",
			ThisObject, LongTermCleaningOperation);
	
	CompletionNotification2 = New NotifyDescription("ClearCompletion",
		ThisObject, LongTermCleaningOperation);
	
	TimeConsumingOperationsClient.WaitCompletion(LongTermCleaningOperation,
		CompletionNotification2, IdleParameters);
	
EndProcedure

&AtServer
Function StartCleaningOnServer()
	
	InfobaseUpdateInternal.CancelRoutineTaskClearingOutdatedData();
	
	Items.Pages.CurrentPage = Items.TimeConsumingOperationPage;
	Items.LongTermOperationText.Title =
		NStr("en = 'Clearing obsolete data...';");
	
	CancelLongTermOperations();
	
	AddressOfCleanupResult = PutToTempStorage(Undefined, UUID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Clear obsolete data';");
	ExecutionParameters.ResultAddress = AddressOfCleanupResult;
	ExecutionParameters.RunInBackground = True; // 
	ExecutionParameters.WithDatabaseExtensions = True;
	ExecutionParameters.BackgroundJobKey = InfobaseUpdateInternal.TaskKeyForClearingOutdatedData();
	
	If Common.DataSeparationEnabled() Then
		JobParameters = New Structure;
		JobParameters.Insert("CleanWhatIsBeingRemoved", CleanWhatIsBeingRemoved);
		JobParameters.Insert("ShouldProcessDataAreas", ShouldProcessDataAreas);
		
		Result = TimeConsumingOperations.ExecuteInBackground(
			"InfobaseUpdateInternal.ClearOutdatedDataInBackground",
			JobParameters, ExecutionParameters);
	Else
		ProcedureSettings = New Structure;
		ProcedureSettings.Insert("Context", New Structure("CleanWhatIsBeingRemoved", CleanWhatIsBeingRemoved));
		ProcedureSettings.Insert("NameOfMethodForGettingPortions",
			"InfobaseUpdateInternal.OutdatedDataWhenRequestingPortionsInBackground");
		
		Result = TimeConsumingOperations.ExecuteProcedureinMultipleThreads(
			"InfobaseUpdateInternal.OutdatedDataWhenClearingPortionInBackground",
			ExecutionParameters, ProcedureSettings);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure ClearWhenReceivingProgress(Result, AdditionalParameters) Export
	
	If AdditionalParameters <> LongTermCleaningOperation Then
		Return;
	EndIf;
	
	If Result.Progress <> Undefined Then
		EstablishProgress(Result.Progress.Percent);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearCompletion(Result, AdditionalParameters) Export
	
	If AdditionalParameters <> LongTermCleaningOperation Then
		Return;
	EndIf;
	
	HasError = False;
	CompleteCleanupOnServer(Result, HasError);
	
	If HasError Then
		Return;
	EndIf;
	
	If ClearAndClose Then
		Close(True);
	Else
		Refresh("");
	EndIf;
	
EndProcedure

&AtServer
Procedure CompleteCleanupOnServer(Val Result, HasError)
	
	LongTermCleaningOperation = Undefined;
	Items.Pages.CurrentPage = Items.OutdatedDataPage;
	
	If ValueIsFilled(AddressOfCleanupResult) Then
		Results = GetFromTempStorage(AddressOfCleanupResult);
		DeleteFromTempStorage(AddressOfCleanupResult);
		AddressOfCleanupResult = "";
	Else
		Results = Undefined;
	EndIf;
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		ErrorText = Result.DetailErrorDescription;
	Else
		ErrorText = InfobaseUpdateInternal.ErrorTextForClearingOutdatedData(Results);
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		Items.Pages.CurrentPage = Items.ErrorPage;
		HasError = True;
		Return;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CleaningPlanOnServer(CleanWhatIsBeingRemoved, ShouldProcessDataAreas)
	
	Return InfobaseUpdateInternal.PlanToCleanUpOutdatedData(
		CleanWhatIsBeingRemoved,, Not ShouldProcessDataAreas);
	
EndFunction

#EndRegion
