///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Sets the state of the original for a selected document. Is invoked via a subsystem of the "Plug-team."
//
//	Parameters:
//  Ref - DocumentRef -  link to the document.
//  Parameters -See AttachableCommands.CommandExecuteParameters.
//
Procedure Attachable_SetOriginalState(Ref, Parameters) Export
	
	List = Parameters.Source;
	If List.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("en = 'No document, for which the selected state can be set, is selected.';"));
		Return;
	EndIf;

	If Parameters.CommandDetails.Kind = "SettingStateOriginalReceived" Then
		StateName = PredefinedValue("Catalog.SourceDocumentsOriginalsStates.OriginalReceived");
	Else
		StateName = Parameters.CommandDetails.Presentation;
	EndIf;

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("List",List);

	If Parameters.CommandDetails.Id = "StatesSetup" Then
		OpenStatesSetupForm();
		Return;
	ElsIf Parameters.CommandDetails.Kind = "SettingStateOriginalReceived" And List.SelectedRows.Count() = 1 Then
		AdditionalParameters.Insert("StateName", StateName);
		SetOriginalStateCompletion(DialogReturnCode.Yes, AdditionalParameters);
		Return;
	EndIf;

	AdditionalParameters.Insert("StateName", StateName);
	
	If List.SelectedRows.Count() > 1 Then
		QueryText = NStr("en = 'The ""%StateName%"" original state will be set for documents selected in the list. Continue?';");
		QueryText = StrReplace(QueryText, "%StateName%", StateName);

		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes,NStr("en = 'Set';"));
		Buttons.Add(DialogReturnCode.No,NStr("en = 'Do not set';"));

		ShowQueryBox(New NotifyDescription("SetOriginalStateCompletion", ThisObject, AdditionalParameters), QueryText, Buttons);
	ElsIf SourceDocumentsOriginalsRecordingServerCall.IsAccountingObject(List.CurrentData.Ref) Then 
		SetOriginalStateCompletion(DialogReturnCode.Yes, AdditionalParameters);
	Else
		ShowMessageBox(, NStr("en = 'Records of originals are not kept for this document.';"));
	EndIf;
	
EndProcedure

// Sets the state of the original for a selected document. Called without connecting the "Pluggable commands" subsystem.
//
//	Parameters:
//  Command - String-  name of the form command to run.
//  Form - ClientApplicationForm -  form of a list or document.
//  List - FormTable -  list of the form where the state change will occur.
//
Procedure SetOriginalState(Command, Form, List) Export

	If List.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("en = 'No document, for which the selected state can be set, is selected';"));
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("List",List);
	
	If Command = "StatesSetup" Then
		OpenStatesSetupForm();
		Return;
	ElsIf Command = "SetOriginalReceived" And List.SelectedRows.Count()= 1 Then
		AdditionalParameters.Insert("StateName", PredefinedValue("Catalog.SourceDocumentsOriginalsStates.OriginalReceived"));
		SetOriginalStateCompletion(DialogReturnCode.Yes, AdditionalParameters);
		Return;
	EndIf;

	FoundState = Form.Items.Find(Command);

	If Not FoundState = Undefined Then
		StateName = FoundState.Title;
	ElsIf Command = "SetOriginalReceived" Then
		StateName = PredefinedValue("Catalog.SourceDocumentsOriginalsStates.OriginalReceived");
	EndIf;

	AdditionalParameters.Insert("StateName", StateName);
	
	If List.SelectedRows.Count() > 1 Then
		QueryText = NStr("en = 'The ""%StateName%"" original state will be set for documents selected in the list. Continue?';");
		QueryText = StrReplace(QueryText, "%StateName%", StateName);

		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("en = 'Set';"));
		Buttons.Add(DialogReturnCode.No, NStr("en = 'Do not set';"));

		ShowQueryBox(New NotifyDescription("SetOriginalStateCompletion", ThisObject, AdditionalParameters), 
			QueryText, Buttons);
	ElsIf SourceDocumentsOriginalsRecordingServerCall.IsAccountingObject(List.CurrentData.Ref) Then 
		SetOriginalStateCompletion(DialogReturnCode.Yes, AdditionalParameters);
	Else
		ShowMessageBox(, NStr("en = 'Records of originals are not kept for this document.';"));
	EndIf;
	
EndProcedure

// Opens drop-down menus for selecting the original state on the list or document form.
//
//	Parameters:
//  Form - ClientApplicationForm:
//   * Object - FormDataStructure, DocumentObject - 
//  Source - FormTable - 
//                              
//
Procedure OpenStateSelectionMenu(Val Form, Val Source = Undefined) Export 
	
	If TypeOf(Source) = Undefined Then
		Source = Form.Items.Find("OriginalStateDecoration");
	EndIf;
	
	If TypeOf(Source) = Type("FormTable") Then
		
		RecordData = Source.CurrentData;
		UnpostedDocuments = CommonServerCall.CheckDocumentsPosting(
			CommonClientServer.ValueInArray(RecordData.Ref));
		If UnpostedDocuments.Count() = 1 Then
			ShowMessageBox(, NStr("en = 'To run the command, post the document first.';"));
			Return;
		EndIf;
		
		RecordsArray = CommonClientServer.ValueInArray(RecordData);
		NotifyDescription = New NotifyDescription("OpenStateSelectionMenuCompletion", ThisObject, RecordsArray);
		ClarifyByPrintForms = Form.OriginalStatesChoiceList.FindByValue("ClarifyByPrintForms");

		If RecordData.OverallState Or Not ValueIsFilled(RecordData.SourceDocumentOriginalState) Then
			If ClarifyByPrintForms = Undefined Then
				Form.OriginalStatesChoiceList.Add("ClarifyByPrintForms",
					NStr("en = 'Specify for print forms…';"),,
					PictureLib.SetSourceDocumentOriginalStateByPrintForms);
			EndIf;
		Else
			If ClarifyByPrintForms <> Undefined Then
				Form.OriginalStatesChoiceList.Delete(ClarifyByPrintForms);
			EndIf;
		EndIf;
		Form.ShowChooseFromMenu(NotifyDescription, Form.OriginalStatesChoiceList,
			Form.Items.SourceDocumentOriginalState);
	Else
		If Form.Object.Ref.IsEmpty() Then
			ShowMessageBox(,NStr("en = 'To run the command, post the document first.';"));
			Return;
		EndIf;
		UnpostedDocuments = CommonServerCall.CheckDocumentsPosting(
			CommonClientServer.ValueInArray(Form.Object.Ref));

		If UnpostedDocuments.Count() = 1 Then
			ShowMessageBox(,NStr("en = 'To run the command, post the document first.';"));
			Return;
		EndIf;

		AdditionalParameters = New Structure("Ref", Form.Object.Ref);
		NotifyDescription = New NotifyDescription("OpenStateSelectionMenuCompletion", ThisObject,
			AdditionalParameters);

		ClarifyByPrintForms = Form.OriginalStatesChoiceList.FindByValue("ClarifyByPrintForms");
		If ClarifyByPrintForms = Undefined Then
			Form.OriginalStatesChoiceList.Add("ClarifyByPrintForms",
				NStr("en = 'Specify for print forms…';"),,
				PictureLib.SetSourceDocumentOriginalStateByPrintForms);
		EndIf;

		Form.ShowChooseFromMenu(NotifyDescription, Form.OriginalStatesChoiceList, Source);
	EndIf;

EndProcedure

// Event notification handler for the "Accounting for originals of primary documents" subsystem for the document form.
//
//	Parameters:
//  EventName - String -  name of the event that occurred.
//  Form - ClientApplicationForm -  the form of the document.
//
Procedure NotificationHandlerDocumentForm(EventName, Form) Export           
		
	If EventName = "SourceDocumentOriginalStateChange" Then 
		GenerateCurrentOriginalStateLabel(Form);
	ElsIf EventName = "AddDeleteSourceDocumentOriginalState" Then			
		Form.RefreshDataRepresentation();	
	EndIf;
		
EndProcedure

// Event notification handler for the "Accounting for originals of primary documents" subsystem for the list form.
//
//	Parameters:
//  EventName - String -  name of the event that occurred.
//  Form - ClientApplicationForm -  form of list of documents.
//  List - FormTable -  the main list of the form.
//
Procedure NotificationHandlerListForm(EventName, Form, List) Export 
	
	If EventName = "AddDeleteSourceDocumentOriginalState" Then
		TheStructureOfTheSearch = New Structure;
 		TheStructureOfTheSearch.Insert("OriginalStatesChoiceList", Undefined);
 		FillPropertyValues(TheStructureOfTheSearch, Form);
 		If TheStructureOfTheSearch.OriginalStatesChoiceList<> Undefined Then
			Form.DetachIdleHandler("Attachable_UpdateOriginalStateCommands");
			Form.AttachIdleHandler("Attachable_UpdateOriginalStateCommands", 0.2, True);
			SourceDocumentsOriginalsRecordingServerCall.FillOriginalStatesChoiceList(Form.OriginalStatesChoiceList);
			Form.RefreshDataRepresentation();
		Else
			Return;
		EndIf;
	ElsIf EventName = "SourceDocumentOriginalStateChange" Then
		List.Refresh();
	EndIf;

EndProcedure

// The event handler for the "Selection" list.
//
//	Parameters:
//  FieldName - String -  name of the selected field.
//  Form - ClientApplicationForm -  form of list of documents.
//  List - FormTable -  the main list of the form.
//  StandardProcessing - Boolean -  True if the form uses standard handling of the "Select" event"
//
Procedure ListSelection(FieldName, Form, List, StandardProcessing) Export 
	
	If FieldName = "SourceDocumentOriginalState" Or FieldName = "StateOriginalReceived" Then
		StandardProcessing = False;
		If SourceDocumentsOriginalsRecordingServerCall.IsAccountingObject(List.CurrentData.Ref) Then
			If FieldName = "SourceDocumentOriginalState" Then
				OpenStateSelectionMenu(Form, List);
			ElsIf FieldName = "StateOriginalReceived" Then
				SetOriginalState("SetOriginalReceived", Form, List);
			EndIf;
		Else
			ShowMessageBox(, NStr("en = 'Records of originals are not kept for this document.';"));
		EndIf;
	EndIf;
	
EndProcedure

// The procedure processes actions for recording originals after scanning the document's barcode.
//
//	Parameters:
//  Barcode - String -  scanned barcode of the document.
//  EventName - String -  name of the form event.
//
Procedure ProcessBarcode(Barcode, EventName) Export
	
	If EventName = "ScanData" Then
		Status(NStr("en = 'Setting original state by barcode…';"));
		SourceDocumentsOriginalsRecordingServerCall.ProcessBarcode(Barcode[0]);
	EndIf;
	
EndProcedure

// The procedure shows the user a notification about changes in the States of the original document.
//
//	Parameters:
//  ProcessedItemsCount - Number -  the number of successfully processed documents.
//  DocumentRef - DocumentRef -  a link to a document for processing a click on a user notification 
//		in the case of a single state setting. Optional parameter.
//  StateName - String -  set state.
//
Procedure NotifyUserOfStatesSetting(ProcessedItemsCount, DocumentRef = Undefined, StateName = Undefined) Export

	If ProcessedItemsCount > 1 Then
		MessageText = NStr("en = 'The ""%StateName%"" original state is set for all documents selected in the list';");
		MessageText = StrReplace(MessageText, "%StateName%", StateName);
		
		TitleText = NStr("en = 'The ""%StateName%"" original state is set';");
		TitleText = StrReplace(TitleText, "%StateName%", StateName);

		ShowUserNotification(TitleText,, MessageText, PictureLib.DialogInformation,UserNotificationStatus.Important);
	Else
		NotifyDescription = New NotifyDescription("ProcessNotificationClick",ThisObject,DocumentRef);
		ShowUserNotification(NStr("en = 'Original state changed:';"),NotifyDescription,DocumentRef,PictureLib.DialogInformation,UserNotificationStatus.Important);
	EndIf;

EndProcedure

// Opens the list form of the reference list "Statesoriginalspervicedocuments".
Procedure OpenStatesSetupForm() Export
	
	OpenForm("Catalog.SourceDocumentsOriginalsStates.ListForm");

EndProcedure

// Called to write the States of the original printed forms to the register after printing the form.
//
//	Parameters:
//  PrintObjects - ValueList -  list of links to print objects.
//  PrintList - ValueList -  a list with the names of the models and views printed forms.
//  Written1 - Boolean -  indicates that the status of the document is recorded in the register.
//
Procedure WriteOriginalsStatesAfterPrint(PrintObjects, PrintList, Written1 = False) Export

	SourceDocumentsOriginalsRecordingServerCall.WriteOriginalsStatesAfterPrint(PrintObjects, PrintList, Written1);
	If PrintList.Count() = 0 Or Written1 = False Then
		Return;
	EndIf;
		
	Notify("SourceDocumentOriginalStateChange");
	
	If PrintObjects.Count() > 1 Then
		NotifyUserOfStatesSetting(PrintObjects.Count(),,PredefinedValue("Catalog.SourceDocumentsOriginalsStates.FormPrinted"));
	ElsIf PrintObjects.Count() = 1 Then
		NotifyUserOfStatesSetting(1,PrintObjects[0].Value,PredefinedValue("Catalog.SourceDocumentsOriginalsStates.FormPrinted"));
	EndIf;
	
EndProcedure

// Opens the form for specifying the States of printed document forms.
//
//	Parameters:
//  DocumentRef - DocumentRef -  link to the document for which you need to get the shared state record key.
//
Procedure OpenPrintFormsStatesChangeForm(DocumentRef) Export

	RegisterRecordKey = SourceDocumentsOriginalsRecordingServerCall.OverallStateRecordKey(DocumentRef);
	
	TransmittedParameters = New Structure;
	If RegisterRecordKey = Undefined Then
		TransmittedParameters.Insert("DocumentRef", DocumentRef);
	Else
		TransmittedParameters.Insert("Key", RegisterRecordKey);
	EndIf;
	OpenForm("InformationRegister.SourceDocumentsOriginalsStates.Form.SourceDocumentsOriginalsStatesChange",
		TransmittedParameters);

EndProcedure

// Called when opening the log of originals of primary documents in the case of connected equipment.
// Allows you to define your own process for connecting connected hardware to the log.
//	
//	Parameters:
//  Form - ClientApplicationForm -  the list form of the document.
//
Procedure OnConnectBarcodeScanner(Form) Export

	SourceDocumentsOriginalsRecordingClientOverridable.OnConnectBarcodeScanner(Form);

EndProcedure

#EndRegion

#Region Private

// Creates a label for displaying information about the current state on the document form.
//
//	Parameters:
//  Form - ClientApplicationForm:
//   * Object - FormDataStructure, DocumentObject - 
//
Procedure GenerateCurrentOriginalStateLabel(Form)
	
	OriginalStateDecoration = Form.Items.Find("OriginalStateDecoration");
	If OriginalStateDecoration = Undefined Then
		Return;
	EndIf;
		 
	If ValueIsFilled(Form.Object.Ref) Then
		CurrentOriginalState = SourceDocumentsOriginalsRecordingServerCall.OriginalStateInfoByRef(Form.Object.Ref);
		If CurrentOriginalState.Count() = 0 Then
			CurrentOriginalState=NStr("en = '<Original state is unknown>';");
			OriginalStateDecoration.TextColor = WebColors.Silver;
		Else
			CurrentOriginalState = CurrentOriginalState.SourceDocumentOriginalState;
			OriginalStateDecoration.TextColor = New Color;
		EndIf;
	Else
		OriginalStateDecoration.TextColor = WebColors.Silver;
	EndIf;

	OriginalStateDecoration.Title = CurrentOriginalState;
	
EndProcedure

// Handler for an alert called after the setoriginal State (...) procedure is completed.
Procedure SetOriginalStateCompletion(Response, AdditionalParameters) Export

	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	List = AdditionalParameters.List;
	StateName = AdditionalParameters.StateName;

	If List.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("en = 'No document, for which the selected state can be set, is selected.';"));
		Return;
	EndIf;

	WritingObjects = New Array; // 
	For Each ListLine In List.SelectedRows Do
		RowData = List.RowData(ListLine);
		Ref = CommonClientServer.StructureProperty(RowData, "Ref");
		If ValueIsFilled(Ref) Then
			WritingObjects.Add(RowData);
		EndIf;
	EndDo;
	
	IsChanged = SourceDocumentsOriginalsRecordingServerCall.SetNewOriginalState(WritingObjects, StateName);
	If IsChanged = "NotPosted" Then
		ShowMessageBox(, NStr("en = 'To set the original state, post the selected documents first.';"));
		Return;
	ElsIf IsChanged = "NotIsChanged" Then
		Return;
	EndIf;

	If WritingObjects.Count() = 1 Then 
		NotifyUserOfStatesSetting(1, WritingObjects[0].Ref);
	Else
		NotifyUserOfStatesSetting(WritingObjects.Count(),, StateName);
	EndIf; 
	Notify("SourceDocumentOriginalStateChange");

EndProcedure

// Handler for an alert called after the open state selection (...) procedure completes.
//	
//	Parameters:
//  SelectedStateFromList - String -  the user-selected state of the original.
//  AdditionalParameters - Structure - :
//                            * Ref - DocumentRef -  link to the document to set the original state.
//       	                - Array of DocumentRef:
//                            * Ref - DocumentRef -  link to the document to set the original state.
//
Procedure OpenStateSelectionMenuCompletion(SelectedStateFromList, AdditionalParameters) Export

	If SelectedStateFromList = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(AdditionalParameters) = Type("Array")Then
		Ref = CommonClientServer.StructureProperty(AdditionalParameters[0], "Ref");
		Value = AdditionalParameters;  
	Else
		Ref = AdditionalParameters.Ref;
		Value = Ref;
	EndIf;

	If SelectedStateFromList.Value = "ClarifyByPrintForms" Then
		OpenPrintFormsStatesChangeForm(Ref);
		Return;
	EndIf;
	
	IsChanged = SourceDocumentsOriginalsRecordingServerCall.SetNewOriginalState(Value, 
		SelectedStateFromList.Value);
	If IsChanged = "IsChanged" Then
		NotifyUserOfStatesSetting(1, Ref, SelectedStateFromList.Value);
		Notify("SourceDocumentOriginalStateChange");
	ElsIf IsChanged = "NotPosted" Then
		ShowMessageBox(, NStr("en = 'To set the original state, post the selected documents first.';"));
	EndIf;

EndProcedure

// Handler for an alert called after the notify Userinstallationstates (...) procedure is completed.
Procedure ProcessNotificationClick(AdditionalParameters) Export

	ShowValue(,AdditionalParameters);

EndProcedure

#EndRegion
