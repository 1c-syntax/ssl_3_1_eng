///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	ClientParametersOnStart = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParametersOnStart.DisplayPermissionSetupAssistant Then
		
		If ClientParametersOnStart.CheckExternalResourceUsagePermissionsApplication Then
			
			AfterCheckApplicabilityOfPermissionsToUseExternalResources(
				ClientParametersOnStart.PermissionsToUseExternalResourcesApplicabilityCheck);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 
// 
//

// Runs the wizard for configuring permissions to use service resources.
//
// The result of the operation is the opening of the form
// Processing.Setting up the permission to use external resources.Form.Initialization of the resolution request, for which the
// procedure is set as a description of the closure notification
// After initialization of the request for permission to use the external resources.
//
// Parameters:
//  IDs - Array of UUID -  ids of requests for the use of external resources,
//                  for which the wizard is called.
//  OwnerForm - ClientApplicationForm
//                - Undefined - 
//  ClosingNotification1 - NotifyDescription, Undefined -  description of the notification that should be processed
//                        after the wizard is completed.
//  EnablingMode - Boolean -  flag that the wizard is called when enabling the use for
//                            the security profile information base.
//  DisablingMode - Boolean -  flag that the wizard is called when disabling usage for
//                             the security profile information base.
//  RecoveryMode - Boolean -  flag that the wizard is called to restore the settings of security profiles in
//                                 the server cluster (according to the current data of the information base).
//
Procedure StartInitializingRequestForPermissionsToUseExternalResources(
		Val IDs,
		Val OwnerForm,
		Val ClosingNotification1,
		Val EnablingMode = False,
		Val DisablingMode = False,
		Val RecoveryMode = False) Export
	
	If EnablingMode Or SafeModeManagerClient.DisplayPermissionSetupAssistant() Then
		
		State = RequestForPermissionsToUseExternalResourcesState();
		State.RequestsIDs = IDs;
		State.NotifyDescription = ClosingNotification1;
		State.OwnerForm = OwnerForm;
		State.EnablingMode = EnablingMode;
		State.DisablingMode = DisablingMode;
		State.RecoveryMode = RecoveryMode;
		
		FormParameters = New Structure();
		FormParameters.Insert("IDs", IDs);
		FormParameters.Insert("EnablingMode", State.EnablingMode);
		FormParameters.Insert("DisablingMode", State.DisablingMode);
		FormParameters.Insert("RecoveryMode", State.RecoveryMode);
		
		NotifyDescription = New NotifyDescription(
			"AfterInitializeRequestForPermissionsToUseExternalResources",
			ExternalResourcesPermissionsSetupClient,
			State);
		
		OpenForm(
			"DataProcessor.ExternalResourcesPermissionsSetup.Form.PermissionsRequestInitialization",
			FormParameters,
			OwnerForm,
			,
			,
			,
			NotifyDescription,
			FormWindowOpeningMode.LockWholeInterface);
		
	Else
		
		ExecuteNotifyProcessing(ClosingNotification1, DialogReturnCode.OK);
		
	EndIf;
	
EndProcedure

// Navigates to the Permission settings dialog in security profiles.
// The result of the operation is the opening of the form:
// Processing.Setting up the permission to use external resources.Form.Setting up the permission to use external resources, 
// for which the procedure is set as a description of the closure notification
// After setting up the permission to use the external resources or an emergency interruption of the wizard.
//
// Parameters:
//  Result - DialogReturnCode -  the result of the previous operation
//                                   in the apply external resource permissions wizard (the values used are OK and Cancel),
//  State - See RequestForPermissionsToUseExternalResourcesState
//
//
Procedure AfterInitializeRequestForPermissionsToUseExternalResources(Result, State) Export
	
	If TypeOf(Result) = Type("Structure") And Result.ReturnCode = DialogReturnCode.OK Then
		
		InitializationState = GetFromTempStorage(Result.StateStorageAddress);
		
		If InitializationState.PermissionApplicationRequired Then
			
			State.StorageAddress = InitializationState.StorageAddress;
			
			FormParameters = New Structure();
			FormParameters.Insert("StorageAddress", State.StorageAddress);
			FormParameters.Insert("RecoveryMode", State.RecoveryMode);
			FormParameters.Insert("CheckMode", State.CheckMode);
			
			NotifyDescription = New NotifyDescription(
				"AfterSetUpPermissionsToUseExternalResources",
				ExternalResourcesPermissionsSetupClient,
				State);
			
			OpenForm(
				"DataProcessor.ExternalResourcesPermissionsSetup.Form.ExternalResourcesPermissionsSetup",
				FormParameters,
				State.OwnerForm,
				,
				,
				,
				NotifyDescription,
				FormWindowOpeningMode.LockWholeInterface);
			
		Else
			
			// 
			// 
			CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(State.NotifyDescription);
			
		EndIf;
		
	Else
		
		ExternalResourcesPermissionsSetupServerCall.CancelApplyRequestsToUseExternalResources(
			State.RequestsIDs);
		CancelSetUpPermissionsToUseExternalResourcesAsynchronously(State.NotifyDescription);
		
	EndIf;
	
EndProcedure

// Navigates to the dialog waiting for the security profile settings to be applied by the server cluster.
// The result of the operation is the opening of the form:
// Processing.Setting up the permission to use external resources.Form.Completion of a resolution request, for which
// the procedure is set as a description of the closure notification
// After the completion of the request for permission to use the external resources or an emergency interruption of the wizard.
//
// Parameters:
//  Result - DialogReturnCode -  the result of the previous operation
//                                   in the apply external resource permissions wizard (the values used are OK, Skip, and Cancel).
//                                   The Skip value is used if no changes have been
//                                   made to the security profile settings, but requests to use external resources
//                                   must be considered successful (for example, if the use
//                                   of all requested external resources has already been provided),
//  State - See RequestForPermissionsToUseExternalResourcesState
//
Procedure AfterSetUpPermissionsToUseExternalResources(Result, State) Export
	
	If Result = DialogReturnCode.OK Or Result = DialogReturnCode.Ignore Then
		
		PlanPermissionApplyingCheckAfterOwnerFormClose(
			State.OwnerForm,
			State.RequestsIDs);
		
		FormParameters = New Structure();
		FormParameters.Insert("StorageAddress", State.StorageAddress);
		FormParameters.Insert("RecoveryMode", State.RecoveryMode);
		
		If Result = DialogReturnCode.OK Then
			FormParameters.Insert("Duration", ChangeApplyingTimeout());
		Else
			FormParameters.Insert("Duration", 0);
		EndIf;
		
		NotifyDescription = New NotifyDescription(
			"AfterCompleteRequestForPermissionsToUseExternalResources",
			ExternalResourcesPermissionsSetupClient,
			State);
		
		OpenForm(
			"DataProcessor.ExternalResourcesPermissionsSetup.Form.PermissionsRequestEnd",
			FormParameters,
			ThisObject,
			,
			,
			,
			NotifyDescription,
			FormWindowOpeningMode.LockWholeInterface);
		
	Else
		
		ExternalResourcesPermissionsSetupServerCall.CancelApplyRequestsToUseExternalResources(
			State.RequestsIDs);
		CancelSetUpPermissionsToUseExternalResourcesAsynchronously(State.NotifyDescription);
		
	EndIf;
	
EndProcedure

// Completes the wizard for applying permissions to use external resources.
// The operation results in processing the notification description that was originally passed from the form that
// the wizard was opened for.
//
// Parameters:
//  Result - DialogReturnCode -  the result of the previous operation
//                                   in the apply external resource permissions wizard (the values used are OK and Cancel),
//  State - See RequestForPermissionsToUseExternalResourcesState.
//
Procedure AfterCompleteRequestForPermissionsToUseExternalResources(Result, State) Export
	
	If Result = DialogReturnCode.OK Then
		
		ShowUserNotification(NStr("en = 'Permission settings';"),,
			NStr("en = 'Security profile settings are changed in the server cluster.';"));
		
		CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(State.NotifyDescription);
		
	Else
		
		ExternalResourcesPermissionsSetupServerCall.CancelApplyRequestsToUseExternalResources(
			State.RequestsIDs);
		CancelSetUpPermissionsToUseExternalResourcesAsynchronously(State.NotifyDescription);
		
	EndIf;
	
EndProcedure

// Asynchronously (in relation to the code from which the wizard was called) processes the alert description
// that was originally passed from the form for which the wizard was opened, returning the OK return code.
//
// Parameters:
//  NotifyDescription - NotifyDescription -  which was passed from the calling code.
//
Procedure CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(Val NotifyDescription)
	
	ParameterName = "StandardSubsystems.NotificationOnApplyExternalResourceRequest";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	ApplicationParameters[ParameterName] = NotifyDescription;
	
	AttachIdleHandler("FinishExternalResourcePermissionSetup", 0.1, True);
	
EndProcedure

// Asynchronously (in relation to the code from which the wizard was called), it processes the notification description
// that was originally passed from the form for which the wizard was opened, returning the Cancel return code.
//
// Parameters:
//  NotifyDescription - NotifyDescription -  which was passed from the calling code.
//
Procedure CancelSetUpPermissionsToUseExternalResourcesAsynchronously(Val NotifyDescription)
	
	ParameterName = "StandardSubsystems.NotificationOnApplyExternalResourceRequest";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	ApplicationParameters[ParameterName] = NotifyDescription;
	
	AttachIdleHandler("CancelExternalResourcePermissionSetup", 0.1, True);
	
EndProcedure

// Synchronously (with respect to the code from which the wizard was called) processes the notification description
// that was originally passed from the form for which the wizard was opened.
//
// Parameters:
//  ReturnCode - DialogReturnCode
//
Procedure CompleteSetUpPermissionsToUseExternalResourcesSynchronously(Val ReturnCode) Export
	
	ClosingNotification1 = ApplicationParameters["StandardSubsystems.NotificationOnApplyExternalResourceRequest"];
	ApplicationParameters["StandardSubsystems.NotificationOnApplyExternalResourceRequest"] = Undefined;
	If ClosingNotification1 <> Undefined Then
		ExecuteNotifyProcessing(ClosingNotification1, ReturnCode);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 
// 
// 
//

// Starts the wizard in the mode of checking the completion of an operation in which
// permission requests for the use of external resources were previously applied.
//
// The result of this procedure is the launch of the wizard for configuring permissions to use
// external resources in the mode of checking the completion of an operation in which permissions
// to use external resources were previously applied (with the regular passage of all operations), after the completion of which
// the processing of the description of the alert, as which the procedure is set, will be called.
// After the verification of the application of the resolution after the closure of the owner's form.
//
// Parameters:
//  Result - Arbitrary -  the result of closing the form that opened the wizard for configuring permissions 
//                             to use external resources. It is not used in the procedure body. the parameter is required
//                             to assign the procedure as a description of the form closing notification.
//  State - See PermissionsApplicabilityCheckStateAfterCloseOwnerForm.
//
Procedure CheckPermissionsAppliedAfterOwnerFormClose(Result, State) Export
	
	OriginalOnCloseNotifyDescription = State.NotifyDescription;
	If OriginalOnCloseNotifyDescription <> Undefined Then
		ExecuteNotifyProcessing(OriginalOnCloseNotifyDescription, Result);
	EndIf;
	
	Validation = ExternalResourcesPermissionsSetupServerCall.CheckApplyPermissionsToUseExternalResources();
	AfterCheckApplicabilityOfPermissionsToUseExternalResources(Validation);
	
EndProcedure

// Handles checking the application of requests to use external resources.
//
// Parameters:
//  Validation - See ExternalResourcesPermissionsSetupServerCall.CheckApplyPermissionsToUseExternalResources.
//
Procedure AfterCheckApplicabilityOfPermissionsToUseExternalResources(Val Validation)
	
	If Not Validation.CheckResult Then
		
		ApplyingState = RequestForPermissionsToUseExternalResourcesState();
		
		ApplyingState.RequestsIDs = Validation.RequestsIDs;
		ApplyingState.StorageAddress = Validation.StateTemporaryStorageAddress;
		ApplyingState.CheckMode = True;
		
		Result = New Structure();
		Result.Insert("ReturnCode", DialogReturnCode.OK);
		Result.Insert("StateStorageAddress", Validation.StateTemporaryStorageAddress);
		
		AfterInitializeRequestForPermissionsToUseExternalResources(
			Result, ApplyingState);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 
// 
//

// Calls the wizard for configuring permissions to use external resources in the mode
// of enabling the use of security profiles for the information database.
//
// Parameters:
//  OwnerForm - ClientApplicationForm -  a form that should be blocked until permissions are applied,
//  ClosingNotification1 - NotifyDescription -  will be called when permissions are granted successfully.
//
Procedure StartEnablingSecurityProfilesUsage(OwnerForm, ClosingNotification1 = Undefined) Export
	
	StartInitializingRequestForPermissionsToUseExternalResources(
		New Array(), OwnerForm, ClosingNotification1, True, False, False);
	
EndProcedure

// Calls the wizard for configuring permissions to use external resources in the mode
// of disabling the use of security profiles for the information database.
//
// Parameters:
//  OwnerForm - ClientApplicationForm -  a form that should be blocked until permissions are applied,
//  ClosingNotification1 - NotifyDescription -  will be called when permissions are granted successfully.
//
Procedure StartDisablingSecurityProfilesUsage(OwnerForm, ClosingNotification1 = Undefined) Export
	
	StartInitializingRequestForPermissionsToUseExternalResources(
		New Array(), OwnerForm, ClosingNotification1, False, True, False);
	
EndProcedure

// Calls the wizard for configuring permissions to use external resources in the mode
// of restoring security profile settings in the server cluster based on the current
// state of the information database.
//
// Parameters:
//  OwnerForm - ClientApplicationForm -  a form that should be blocked until permissions are applied,
//  ClosingNotification1 - NotifyDescription -  will be called when permissions are granted successfully.
//
Procedure StartRestoringSecurityProfiles(OwnerForm, ClosingNotification1 = Undefined) Export
	
	StartInitializingRequestForPermissionsToUseExternalResources(
		New Array(), OwnerForm, ClosingNotification1, False, False, True);
	
EndProcedure

// Constructor of the structure that is used to store the status of the wizard
// for configuring permissions to use external resources.
//
// Returns: 
//   Structure - 
//
Function RequestForPermissionsToUseExternalResourcesState()
	
	Result = New Structure();
	
	// 
	Result.Insert("RequestsIDs", New Array());
	
	// 
	// 
	Result.Insert("NotifyDescription", Undefined);
	
	// 
	Result.Insert("StorageAddress", "");
	
	// 
	// 
	Result.Insert("OwnerForm");
	
	// 
	Result.Insert("EnablingMode", False);
	
	// 
	Result.Insert("DisablingMode", False);
	
	// 
	// 
	// 
	Result.Insert("RecoveryMode", False);
	
	// 
	// 
	// 
	Result.Insert("CheckMode", False);
	
	Return Result;
	
EndFunction

// Constructor of a structure that is used to store the status of checking the completion
// of an operation that used permission requests to use external resources.
//
// Returns: 
//   Structure - 
//
Function PermissionsApplicabilityCheckStateAfterCloseOwnerForm()
	
	Result = New Structure();
	
	// 
	Result.Insert("StorageAddress", Undefined);
	
	// 
	// 
	Result.Insert("NotifyDescription", Undefined);
	
	Return Result;
	
EndFunction

// Returns the duration of the wait for changes to the security profile settings
// in the server cluster to be applied.
//
// Returns:
//   Number - 
//
Function ChangeApplyingTimeout()
	
	Return 20; // 
	
EndFunction

// Schedules (by spoofing the value of the property of the form descriptiondisclosing) a call to the wizard
// to check that the operation is completed after closing the form from which the wizard was called.
//
// The result of this procedure is a procedure call.
// Checking the use of permissions after closing the owner form after closing the form that 
// opened the wizard for configuring permissions to use external resources.
//
// Parameters:
//  Form Owner - Client Application form, Indefinite - a form, after closing of which it is required to
//    check the completion of operations in which permission requests for the use
//    of external resources were previously applied.
//  RequestsIDs - Array of UUID -  ids of requests for permissions to
//    use external resources that were applied as part of the operation whose completion is being checked.
//
Procedure PlanPermissionApplyingCheckAfterOwnerFormClose(FormOwner, RequestsIDs)
	
	If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
		
		InitialNotifyDescription = FormOwner.OnCloseNotifyDescription;
		If InitialNotifyDescription <> Undefined Then
			
			If InitialNotifyDescription.Module = ExternalResourcesPermissionsSetupClient
					And InitialNotifyDescription.ProcedureName = "CheckPermissionsAppliedAfterOwnerFormClose" Then
				Return;
			EndIf;
			
		EndIf;
		
		State = PermissionsApplicabilityCheckStateAfterCloseOwnerForm();
		State.NotifyDescription = InitialNotifyDescription;
		
		PermissionsApplicabilityCheckNotifyDescription = New NotifyDescription(
			"CheckPermissionsAppliedAfterOwnerFormClose",
			ExternalResourcesPermissionsSetupClient,
			State);
		
		FormOwner.OnCloseNotifyDescription = PermissionsApplicabilityCheckNotifyDescription;
		
	EndIf;
	
EndProcedure

#EndRegion