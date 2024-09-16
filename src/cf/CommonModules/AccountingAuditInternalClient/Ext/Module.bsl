///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// 
// 
//
// Parameters:
//   ReportForm          - ClientApplicationForm -  report form.
//   Item              - FormField        -  table document.
//   Area              - SpreadsheetDocumentRange -  selected value.
//   StandardProcessing - Boolean -  indicates whether standard event processing is being performed.
//
Procedure SpreadsheetDocumentSelectionHandler(ReportForm, Item, Area, StandardProcessing) Export
	
	If ReportForm.ReportSettings.FullName <> "Report.AccountingCheckResults" Then
		Return;
	EndIf;
		
	Details = Area.Details;
	If TypeOf(Details) = Type("Structure") Then
		
		StandardProcessing = False;
		If Details.Property("Purpose") Then
			If Details.Purpose = "FixIssues" Then
				ResolveIssue(ReportForm, Details);
			ElsIf Details.Purpose = "OpenListForm" Then
				OpenProblemList(ReportForm, Details);
			EndIf;
		EndIf;
		
	EndIf;
		
EndProcedure

// Opens a report form with a selection of problems that prevent the normal updating
// of the information base.
//
//  Parameters:
//     Form                - ClientApplicationForm -  the managed form of the problem object.
//     StandardProcessing - Boolean -  a sign of
//                            standard (system) event processing is passed to this parameter.
//
// Example:
//    The monitoring module accounts for the service client.Open a report on the problems of the update processing (this is an object, standard processing);
//
Procedure OpenIssuesReportFromUpdateProcessing(Form, StandardProcessing) Export
	
	StandardProcessing = False;
	OpenIssuesReport("SystemChecks");
	
EndProcedure

// See AccountingAuditClient.OpenIssuesReport.
Procedure OpenIssuesReport(ChecksKind, ExactMap = True) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("CheckKind", ChecksKind);
	FormParameters.Insert("ExactMap", ExactMap);
	
	OpenForm("Report.AccountingCheckResults.Form", FormParameters);
	
EndProcedure

// Opens the form of the list of the manual of the rules of Accounting.
//
Procedure OpenAccountingChecksList() Export
	OpenForm("Catalog.AccountingCheckRules.ListForm");
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If Not ClientParameters.Property("AccountingAudit") Then
		Return;
	EndIf;
	Properties = ClientParameters.AccountingAudit;
	
	If Not Properties.NotifyOfAccountingIssues1
	 Or Not ValueIsFilled(Properties.AccountingIssuesCount) Then
		Return;
	EndIf;
	
	ApplicationParameters.Insert("StandardSubsystems.AccountingAudit.IssuesCount",
		Properties.AccountingIssuesCount);
	
	AttachIdleHandler("NotifyOfAccountingIssues", 30, True);
	
EndProcedure

// See ReportsClientOverridable.DetailProcessing.
Procedure OnProcessDetails(ReportForm, Item, Details, StandardProcessing) Export
	
	If ReportForm.ReportSettings.FullName <> "Report.AccountingCheckResults" Then
		Return;
	EndIf;

	CurrentArea = ReportForm.ReportSpreadsheetDocument.CurrentArea;
	If TypeOf(CurrentArea) <> Type("SpreadsheetDocumentRange") 
		Or CurrentArea.AreaType <> SpreadsheetDocumentCellAreaType.Rectangle Then
		Return;
	EndIf;

	Result = AccountingAuditServerCall.SelectedCellDetails(ReportForm.ReportDetailsData, 
		ReportForm.ReportSpreadsheetDocument, CurrentArea.Details);
	If Result <> Undefined Then
		StandardProcessing = False;
		ShowValue(, Result.ObjectWithIssue);
	EndIf;
	
EndProcedure

// Parameters:
//   ReportForm - ClientApplicationForm:
//    * ReportSpreadsheetDocument - SpreadsheetDocument
//   Command - FormCommand
//   Result - Boolean
// 
Procedure OnProcessCommand(ReportForm, Command, Result) Export
	
	If ReportForm.ReportSettings.FullName <> "Report.AccountingCheckResults" Then
		Return;
	EndIf;

	UnsuccessfulActionText = NStr("en = 'Select a line with an object with issues.';");
	CurrentArea = ReportForm.ReportSpreadsheetDocument.CurrentArea;
	If TypeOf(CurrentArea) <> Type("SpreadsheetDocumentRange") 
		Or CurrentArea.AreaType <> SpreadsheetDocumentCellAreaType.Rectangle Then
		ShowMessageBox(, UnsuccessfulActionText);
		Return;
	EndIf;
	
	If Command.Name = "AccountingAuditObjectChangeHistory" Then
		Result = AccountingAuditServerCall.DataForObjectChangeHistory(ReportForm.ReportDetailsData, 
			ReportForm.ReportSpreadsheetDocument, CurrentArea.Details);
		If Result = Undefined Then
			ShowMessageBox(, UnsuccessfulActionText);
			Return;
		EndIf;

		If Result.ToVersion Then
			ModuleObjectsVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
			ModuleObjectsVersioningClient.ShowChangeHistory(Result.Ref, ReportForm);
		Else
			Events = New Array;
			Events.Add("_$Data$_.Delete");
			Events.Add("_$Data$_.New");
			Events.Add("_$Data$_.Update");
			Filter = New Structure;
			Filter.Insert("Data", Result.Ref);
			Filter.Insert("EventLogEvent", Events);
			Filter.Insert("StartDate", BegOfMonth(CurrentDate())); // 
			EventLogClient.OpenEventLog(Filter);
		EndIf;
	ElsIf Command.Name = "AccountingAuditIgnoreIssue" Then
		IssueIgnored = AccountingAuditServerCall.IgnoreIssue(ReportForm.ReportDetailsData, 
			ReportForm.ReportSpreadsheetDocument, CurrentArea.Details);
		If Not IssueIgnored Then
			ShowMessageBox(, UnsuccessfulActionText);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Opens a form for interactive user actions to solve the problem.
//
// Parameters:
//   Form       - ClientApplicationForm -  the form of the report of the results of the audit.
//   Details - Structure - :
//      * Purpose                     - String -  string identifier of the decryption destination.
//      * CheckID          - String -  string verification indicator.
//      * GoToCorrectionHandler - String -  the name of the export client procedure that handles 
//                                                   the problem correction or the full name of the form to open.
//      * CheckKind                    - CatalogRef.ChecksKinds -  a type of check
//                                         that further clarifies the scope of the problem correction.
//
Procedure ResolveIssue(Form, Details)
	
	PatchParameters = New Structure;
	PatchParameters.Insert("CheckID", Details.CheckID);
	PatchParameters.Insert("CheckKind",           Details.CheckKind);
	
	GoToCorrectionHandler = Details.GoToCorrectionHandler;
	If StrStartsWith(GoToCorrectionHandler, "CommonForm.") Or StrFind(GoToCorrectionHandler, ".Form") > 0 Then
		OpenForm(GoToCorrectionHandler, PatchParameters, Form);
	Else
		HandlerCorrections = StringFunctionsClientServer.SplitStringIntoSubstringsArray(GoToCorrectionHandler, ".");
		
		ModuleCorrectionHandler  = CommonClient.CommonModule(HandlerCorrections[0]);
		ProcedureName = HandlerCorrections[1];
		
		ExecuteNotifyProcessing(New NotifyDescription(ProcedureName, ModuleCorrectionHandler), PatchParameters);
	EndIf;
	
EndProcedure

// Opens the list form (in case of a register - with a problematic set of records).
//
// Parameters:
//   Form                          - ClientApplicationForm -  report form.
//   Details - Structure - 
//                 :
//      * Purpose         - String -  string identifier of the decryption destination.
//      * FullObjectName   - String -  full name of the metadata object.
//      * Filter              - Structure -  selection in the form of a list.
//
Procedure OpenProblemList(Form, Details)
	
	UserSettings = New DataCompositionUserSettings;
	CompositionFilter           = UserSettings.Items.Add(Type("DataCompositionFilter"));
	
	RegisterForm = GetForm(Details.FullObjectName + ".ListForm", , Form);
	
	For Each SetFilterItem1 In Details.Filter Do
		
		FilterElement                = CompositionFilter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue  = New DataCompositionField(SetFilterItem1.Key);
		FilterElement.RightValue = SetFilterItem1.Value;
		FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
		FilterElement.Use  = True;
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Field",          SetFilterItem1.Key);
		FilterParameters.Insert("Value",      SetFilterItem1.Value);
		FilterParameters.Insert("ComparisonType",  DataCompositionComparisonType.Equal);
		FilterParameters.Insert("Use", True);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ToUserSettings", True);
		AdditionalParameters.Insert("ReplaceCurrent",       True);
		
		AddFilter(RegisterForm.List.SettingsComposer, FilterParameters, AdditionalParameters);
		
	EndDo;
	
	RegisterForm.Open();
	
EndProcedure

// Adds a selection to the linker's selection collection or selection group
//
// Parameters:
//   StructureItem        - DataCompositionSettingsComposer
//                           - DataCompositionSettings - 
//   FilterParameters         - Structure - :
//     * Field                - String -  name of the field to add the selection to.
//     * Value            - Arbitrary -  CD selection value (default: Undefined).
//     * ComparisonType        - DataCompositionComparisonType -  type of CD comparisons (default: Undefined).
//     * Use       - Boolean -  indicates whether selection is used (default: True).
//   AdditionalParameters - Structure - :
//     * ToUserSettings - Boolean -  whether to add a CD to the user settings (by default: Lie).
//     * ReplaceCurrent       - Boolean -  indicates whether the existing selection by field is completely replaced (default: True).
//
// Returns:
//   DataCompositionFilterItem - 
//
Function AddFilter(StructureItem, FilterParameters, AdditionalParameters = Undefined)
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ToUserSettings", False);
		AdditionalParameters.Insert("ReplaceCurrent",       True);
	Else
		If Not AdditionalParameters.Property("ToUserSettings") Then
			AdditionalParameters.Insert("ToUserSettings", False);
		EndIf;
		If Not AdditionalParameters.Property("ReplaceCurrent") Then
			AdditionalParameters.Insert("ReplaceCurrent", True);
		EndIf;
	EndIf;
	
	If TypeOf(FilterParameters.Field) = Type("String") Then
		NewField = New DataCompositionField(FilterParameters.Field);
	Else
		NewField = FilterParameters.Field;
	EndIf;
	
	If TypeOf(StructureItem) = Type("DataCompositionSettingsComposer") Then
		Filter = StructureItem.Settings.Filter;
		
		If AdditionalParameters.ToUserSettings Then
			For Each SettingItem In StructureItem.UserSettings.Items Do
				If SettingItem.UserSettingID =
					StructureItem.Settings.Filter.UserSettingID Then
					Filter = SettingItem;
				EndIf;
			EndDo;
		EndIf;
	
	ElsIf TypeOf(StructureItem) = Type("DataCompositionSettings") Then
		Filter = StructureItem.Filter;
	Else
		Filter = StructureItem;
	EndIf;
	
	FilterElement = Undefined;
	If AdditionalParameters.ReplaceCurrent Then
		For Each Item In Filter.Items Do
	
			If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then
				Continue;
			EndIf;
	
			If Item.LeftValue = NewField Then
				FilterElement = Item;
			EndIf;
	
		EndDo;
	EndIf;
	
	If FilterElement = Undefined Then
		FilterElement = Filter.Items.Add(Type("DataCompositionFilterItem"));
	EndIf;
	FilterElement.Use  = FilterParameters.Use;
	FilterElement.LeftValue  = NewField;
	FilterElement.ComparisonType   = ?(FilterParameters.ComparisonType = Undefined, DataCompositionComparisonType.Equal,
		FilterParameters.ComparisonType);
	FilterElement.RightValue = FilterParameters.Value;
	
	Return FilterElement;
	
EndFunction

Procedure NotifyOfAccountingIssuesCases() Export
	
	IssuesCount = ApplicationParameters.Get(
		"StandardSubsystems.AccountingAudit.IssuesCount");
	
	If Not ValueIsFilled(IssuesCount) Then
		Return;
	EndIf;
	
	ShowUserNotification(
		NStr("en = 'Data integrity check';"),
		"e1cib/app/Report.AccountingCheckResults",
		NStr("en = 'Data integrity issues found';") + " (" + IssuesCount + ")",
		PictureLib.DialogExclamation);
	
EndProcedure



#EndRegion