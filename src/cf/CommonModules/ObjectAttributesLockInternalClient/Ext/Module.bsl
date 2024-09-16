///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Procedure AllowObjectAttributeEditAfterWarning(ContinuationHandler) Export
	
	If ContinuationHandler <> Undefined Then
		ExecuteNotifyProcessing(ContinuationHandler, False);
	EndIf;
	
EndProcedure

Procedure AllowEditingObjectAttributesAfterFormClosed(Result, Parameters) Export
	
	UnlockedAttributes = Undefined;
	
	If Result = True Then
		UnlockedAttributes = Parameters.LockedAttributes;
	ElsIf TypeOf(Result) = Type("Array") Then
		UnlockedAttributes = Result;
	Else
		UnlockedAttributes = Undefined;
	EndIf;
	
	If UnlockedAttributes <> Undefined Then
		ObjectAttributesLockClient.SetAttributeEditEnabling(
			Parameters.Form, UnlockedAttributes);
		
		ObjectAttributesLockClient.SetFormItemEnabled(Parameters.Form);
	EndIf;
	
	Parameters.Form = Undefined;
	
	If Parameters.ContinuationHandler <> Undefined Then
		ContinuationHandler = Parameters.ContinuationHandler;
		Parameters.ContinuationHandler = Undefined;
		ExecuteNotifyProcessing(ContinuationHandler, Result);
	EndIf;
	
EndProcedure

Procedure CheckObjectReferenceAfterValidationConfirm(Response, Parameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		ExecuteNotifyProcessing(Parameters.ContinuationHandler, False);
		Return;
	EndIf;
		
	If Parameters.ReferencesArrray.Count() = 0 Then
		ExecuteNotifyProcessing(Parameters.ContinuationHandler, True);
		Return;
	EndIf;
	
	If CommonServerCall.RefsToObjectFound(Parameters.ReferencesArrray) Then
		
		If Parameters.ReferencesArrray.Count() = 1 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Элемент ""%1"" уже используется в других местах в приложении.
				           |Не рекомендуется разрешать редактирование из-за риска рассогласования данных.';"),
				Parameters.ReferencesArrray[0]);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Выбранные элементы (%1) уже используются в других местах в приложении.
				           |Не рекомендуется разрешать редактирование из-за риска рассогласования данных.';"),
				Parameters.ReferencesArrray.Count());
		EndIf;
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("en = 'Разрешить редактирование';"));
		Buttons.Add(DialogReturnCode.No, NStr("en = 'Отмена';"));
		ShowQueryBox(
			New NotifyDescription(
				"CheckObjectRefsAfterEditConfirmation", ThisObject, Parameters),
			MessageText, Buttons, , DialogReturnCode.No, Parameters.DialogTitle);
	Else
		If Parameters.ReferencesArrray.Count() = 1 Then
			ShowUserNotification(NStr("en = 'Редактирование реквизитов разрешено';"),
				GetURL(Parameters.ReferencesArrray[0]), Parameters.ReferencesArrray[0]);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Разрешено редактирование реквизитов объектов (%1)';"),
				Parameters.ReferencesArrray.Count());
			
			ShowUserNotification(NStr("en = 'Редактирование реквизитов разрешено';"),,
				MessageText);
		EndIf;
		ExecuteNotifyProcessing(Parameters.ContinuationHandler, True);
	EndIf;
	
EndProcedure

Procedure CheckObjectRefsAfterEditConfirmation(Response, Parameters) Export
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler, Response = DialogReturnCode.Yes);
	
EndProcedure

#EndRegion
