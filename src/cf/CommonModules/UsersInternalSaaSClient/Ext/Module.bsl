///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Opens the form for entering the service user's password.
//
// Parameters:
//  ContinuationHandler      - NotifyDescription -  which should be processed after receiving the password.
//  OwnerForm             - ClientApplicationForm -  which asks for a password.
//  ServiceUserPassword - String -  the current password of the service user.
//
Procedure RequestPasswordForAuthenticationInService(ContinuationHandler, OwnerForm, ServiceUserPassword) Export
	
	Context = New Structure;
	Context.Insert("ContinuationHandler", ContinuationHandler);
	Context.Insert("OwnerForm", OwnerForm);
	Context.Insert("ServiceUserPassword", ServiceUserPassword);
	
	If ServiceUserPassword = Undefined Then
		Notification = New NotifyDescription("AfterAuthenticationPasswordRequestInService", ThisObject, Context);
		OpenForm("CommonForm.AuthenticationInService", , OwnerForm, , , , Notification);
	Else
		AfterAuthenticationPasswordRequestInService(ServiceUserPassword, Context)
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure AfterAuthenticationPasswordRequestInService(ServiceUserPassword, Context) Export
	
	Context.ServiceUserPassword = ServiceUserPassword;
	
	Notification = New NotifyDescription(
		"AfterAuthenticationPasswordRequestInServiceFollowUp", ThisObject, Context);
	
	StandardSubsystemsClient.StartNotificationProcessing(Notification);
	
EndProcedure

Procedure AfterAuthenticationPasswordRequestInServiceFollowUp(Result, Context) Export

	ErrorText = "";
	Try
		ExecuteNotifyProcessing(Context.ContinuationHandler, Context.ServiceUserPassword);
	Except
		ErrorInfo = ErrorInfo();
		UsersInternalSaaSServerCall.WriteTheErrorToTheLog(
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo) + Chars.LF
			+ NStr("en = 'Password may be incorrect. Retype the password.';");
	EndTry;
	
	If ValueIsFilled(ErrorText) Then
		Notification = New NotifyDescription("AfterRequestAuthenticationPasswordInServiceAndErrorWarning", ThisObject, Context);
		ShowMessageBox(Notification, ErrorText);
	EndIf;
	
EndProcedure

Procedure AfterRequestAuthenticationPasswordInServiceAndErrorWarning(Context) Export
	
	RequestPasswordForAuthenticationInService(Context.ContinuationHandler,
		Context.OwnerForm, Undefined);
	
EndProcedure

#EndRegion
